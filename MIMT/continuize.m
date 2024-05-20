function outpict = continuize(varargin)
%  OUTPICT=CONTINUIZE({OPTIONS},FHANDLE,INPICT,{FARGS})
%     Attempt to continuize or smooth potentially discontinuous image 
%     transformation processes by operating on subscript arrays and
%     performing interpolation. This can be used to alter the behavior
%     of image processing tools such as imannrotate or roiflip. 
%   
%     Similar effects can be achieved by operating on orthogonal unit 
%     gradients and then using them to transform the target image using 
%     DISPLACE. CONTINUIZE is typically more convenient and concise, 
%     but ultimately less flexible.
%
%     In cases where the specified function generates RGB output from 
%     a single-channel input, channel transformations are independent.
%
%  OPTIONS include the keys and key-value pairs:
%     'filter' is either a 2D filter kernel (e.g. from fspecial() or fkgen())
%         or the key 'none' if no smoothing is desired.  The user-supplied 
%         filter should have a unit sum (i.e. no Sobel filter).  Default is 
%         a 20px gaussian.
%     'amount' allows the user to adjust the severity of the applied 
%         transformation (default 1).  May be a scalar or an I/RGB map.
%         Amount does not force expansion of index maps.
%     'edgetype' specifies how subscripts should be handled if they
%         exceed the image geometry. Accepts 'clamp' (default) and 'wrap'.
%     'interpolation' specifies the final interpolation method
%         Accepts 'nearest', 'linear' (default), and 'cubic'
%     'forcergb' key is used to expand the subscript arrays in the case 
%         that FHANDLE can only accept RGB inputs.
%     'transpose' key is used in cases where the first two arguments to
%         FHANDLE are images.  In such a case, the calls are as follows:
%         When 'transpose' is unset: fhandle(map,farg1,farg2,farg3)
%         When 'transpose' is set:   fhandle(farg1,map,farg2,farg3)
%         For example, this may be necessary if FHANDLE expects a logical
%         mask in the first position and an image in the second.
%         If followed by a numeric argument, the user may specify which 
%         argument to transpose with the map. (default 1)
%     'xfaxis' specifies which axis to transform
%         Accepts 'x', 'y', or 'both' (default)
%
%  FHANDLE is a function handle (e.g. @roiflip) 
%     This function must accept an I/RGB image of class 'double' as its 
%     first argument. If only RGB images are supported, use 'forcergb' key.
%  INPICT is an I/RGB image of any standard image class
%  FARGS are other arguments passed to the function specified by FHANDLE
% 
%  Class of OUTPICT is inherited from INPICT
%
%  Examples:
%     continuize(@roishift,inpict,mask,2,100,0);
%     continuize('amount',gradientpict,@roishift,inpict,mask,1,100,0);
%     continuize('transpose',@imblend,inpict,modpict,0.1,'scaleadd',0.8);
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/continuize.html
% See also: displace

% this is all kind of inflexible; params can't vary btw xx and yy xforms

interpmethodstrings = {'nearest','linear','cubic'};
interpmethod = 'linear';
edgehandlingstrings = {'wrap','clamp'};
edgehandling = 'clamp';
xfaxisstrings = {'x','y','both'};
xfaxis = 'both';
nofilter = false;
fs = fkgen('gaussian',20);
forcergb = false;
transpose = false;
xpidx = 1;
amount = 1;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		if ~isa(varargin{k},'function_handle')
			switch lower(varargin{k})
				case 'amount'
					if isnumeric(varargin{k+1})
						amount = varargin{k+1};
					else
						error('CONTINUIZE: expected numeric value for AMOUNT')
					end
					k = k+2;
				case 'forcergb'
					forcergb = true;
					k = k+1;
				case 'transpose'
					transpose = true;
					if isnumeric(varargin{k+1})
						xpidx = varargin{k+1};
						k = k+2;
					else
						k = k+1;
					end
				case 'filter'
					thisarg = varargin{k+1};
					if ischar(thisarg)
						if strcmpi(thisarg,'none')
							nofilter = true;
						else
							error('CONTINUIZE: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
						end
						k = k+2;
					elseif numel(thisarg) >= 2 && size(thisarg,3) == 1 && round(sum(thisarg(:))*100)/100 == 1
						fs = thisarg;
						k = k+2;
					else
						error('CONTINUIZE: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
					end
				case 'interpolation'
					thisarg = lower(varargin{k+1});
					if strismember(thisarg,interpmethodstrings)
						interpmethod = thisarg;
					else
						error('CONTINUIZE: unknown interpolation method %s\n',thisarg)
					end
					k = k+2;
				case 'edgetype'
					thisarg = lower(varargin{k+1});
					if strismember(thisarg,edgehandlingstrings)
						edgehandling = thisarg;
					else
						error('CONTINUIZE: unknown edge handling method %s\n',thisarg)
					end
					k = k+2;
				case 'xfaxis'
					thisarg = lower(varargin{k+1});
					if strismember(thisarg,xfaxisstrings)
						xfaxis = thisarg;
					else
						error('CONTINUIZE: unknown axis %s\n',thisarg)
					end
					k = k+2;
				otherwise
					error('CONTINUIZE: unknown input parameter name %s',varargin{k})
			end
		else
			% continuize itself takes only key-value pairs
			% if this is a function handle, it must be fhandle
			% the next expected argument is inpict
			% everything after that are arguments for the function specified by fhandle
			fhandle = varargin{k};
			% this will allow MIMT-supported classes to be fed to non-MIMT functions, which might break
			% this is a fundamental problem with the artificial class restrictions 
			% and arbitrary nonsense associations between class and page count made within IPT/MATLAB
			% and the fact that we don't know what conventions are being assumed by whatever the user calls  
			if isimageclass(varargin{k+1},'mimt')
				inpict = varargin{k+1};
			else
				error('CONTINUIZE: INPICT is not of a standard image class\n')
			end
			break;
		end
	end
end

if numel(amount) > 1 
	if size(amount,1) == size(inpict,1) && size(amount,1) == size(inpict,1)
		amount = imcast(amount,'double');
		scalaramt = false;
		ccamt = size(amount,3);
	else
		error('CONTINUIZE: AMOUNT is either a scalar or a map matching the height and width of INPICT\n')
	end
else
	scalaramt = true;
end

switch xfaxis
	case 'x'
		xfx = true;
		xfy = false;
	case 'y'
		xfx = false;
		xfy = true;
	case 'both'
		xfx = true;
		xfy = true;
end

% sort out which arguments to pass and where
fargs = (k+2):numel(varargin);
if transpose
	if xpidx > numel(fargs)
		error('CONTINUIZE: index provided for the ''transform'' option exceeds the length of the arguments available to FHANDLE')
	end
	xpidx = fargs(xpidx);
	fargs = fargs(fargs ~= xpidx);
end

[inpict inclass] = imcast(inpict,'double');
s = size(inpict);
[ccin ~] = chancount(inpict);
[x0 y0] = meshgrid(1:s(2),1:s(1));

% normalize
xx = x0./s(2);
yy = y0./s(1);

% transform subs arrays
if ~transpose
	if ~forcergb
		if xfx; xx = fhandle(xx,varargin{fargs}); end
		if xfy; yy = fhandle(yy,varargin{fargs}); end
	else
		if xfx; xx = fhandle(repmat(xx,[1 1 3]),varargin{fargs}); end
		if xfy; yy = fhandle(repmat(yy,[1 1 3]),varargin{fargs}); end
	end
else
	if ~forcergb
		if xfx; xx = fhandle(varargin{xpidx},xx,varargin{fargs}); end
		if xfy; yy = fhandle(varargin{xpidx},yy,varargin{fargs}); end
	else
		if xfx; xx = fhandle(varargin{xpidx},repmat(xx,[1 1 3]),varargin{fargs}); end
		if xfy; yy = fhandle(varargin{xpidx},repmat(yy,[1 1 3]),varargin{fargs}); end
	end
end

% deal with any possible alpha generation
[ccx ~] = chancount(xx);
[ccy ~] = chancount(yy);
xx = imcast(xx(:,:,1:ccx),'double');
yy = imcast(yy(:,:,1:ccy),'double');

% collapse RGB maps when unneeded
if ccx == 3 && ccin == 1; xx = mono(xx,'y'); ccx = 1; end
if ccy == 3 && ccin == 1; yy = mono(yy,'y'); ccy = 1; end

% smooth transformation
if ~nofilter
	if xfx; xx = imfilterFB(xx,fs,'replicate'); end
	if xfy; yy = imfilterFB(yy,fs,'replicate'); end
end

% denormalize
xx = xx*s(2);
yy = yy*s(1);

% apply amount adjustment
if ccx == 3 
	x0 = x0(:,:,[1 1 1]);
end
if ccy == 3 
	y0 = y0(:,:,[1 1 1]);
end
if scalaramt
	if xfx;	xx = x0+(xx-x0)*amount; end
	if xfy; yy = y0+(yy-y0)*amount; end
else
	% expand/colapse amount based on ccx/ccy
	if xfx
		if ccx == 3 && ccamt == 1
			amtx = amount(:,:,[1 1 1]);
		elseif ccx == 1 && ccamt == 3
			amtx = mean(amount,3);
		else
			amtx = amount;
		end
		xx = x0+(xx-x0).*amtx;
	end
	if xfy
		if ccy == 3 && ccamt == 1
			amty = amount(:,:,[1 1 1]);
		elseif ccy == 1 && ccamt == 3
			amty = mean(amount,3);
		else
			amty = amount;
		end
		yy = y0+(yy-y0).*amty;
	end
end

% deal with subs outside image region
switch edgehandling
	case 'wrap'
		if xfx; xx = mod(xx,s(2))+1; end
		if xfy; yy = mod(yy,s(1))+1; end
	case 'clamp'
		if xfx; xx = imclamp(xx,[1 s(2)]); end
		if xfy; yy = imclamp(yy,[1 s(1)]); end
end

% apply transformation to inpict
outpict = zeros([s(1:2),ccin]);
for c = 1:ccin
	if ccx == 1; thisxmap = xx; else; thisxmap = xx(:,:,c); end
	if ccy == 1; thisymap = yy; else; thisymap = yy(:,:,c); end
	outpict(:,:,c) = interp2(x0(:,:,1),y0(:,:,1),inpict(:,:,c),thisxmap,thisymap,interpmethod);
end
outpict = imcast(imclamp(outpict),inclass);
























