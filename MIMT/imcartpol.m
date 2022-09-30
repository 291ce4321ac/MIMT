function [outpict comstring] = imcartpol(inpict,varargin)
% OUTPICT = IMCARTPOL(INPICT, {OPTIONS})
% [OUTPICT COMSTRING] = IMCARTPOL(INPICT, {OPTIONS})
%    Rectangular-polar mapping nonsense for image mangling.  This is not intended for
%    any technical purpose requiring accuracy or reversibility.
%
% INPICT is an I/IA/RGB/RGBA image of any standard image class
%    4D images are supported
%
% OPTIONS include keys and key-value pairs:
%    CYCLES specifies how many times the image should be processed (default 1)
%
%    MODE specifies the type of transformation
%       'cart2pol' transforms the image such that its axes represent radial and angular position
%       'pol2cart' is the reverse of the above
%       'rinvert' radial inversion mapping; map image edges to the specified origin and vice-versa
%       'rando' randomly selects one of the above (also randomly sets SWAP)
%
%    OFFSET specifies the origin point about which to transform the image (default [0 0])
%       These coordinates are normalized with respect to the image height and width.
%       This can be specified explicitly as a 1x2 vector [yoffset xoffset]
%       Alternatively, an allowed range of offsets can be specified with a 2x2 array:
%          [minyoffset minxoffset; maxyoffset maxxoffset]
%          If specified as a range, a random value will be selected within specified limits.
%       OFFSET may also be specified in a symmetrical fashion, automatically invoking the CENTER flag
%          If a scalar, the origin will be placed within a rectangular region centered on the image.
%          If a 2x1 vector, the allowed region will be a rectangular annulus.
%          This is convenient to keep the origin from being placed in the image area.
%
%    CENTER shifts offset coordinates to start at the center of the image instead of the 
%       top left corner. This may be more convenient.
%
%       For example:
%          Select the bottom right corner (explicit):
%             [1 1] & CENTER=0 or [0.5 0.5] & CENTER=1
%          Select the center point of the image (explicit):
%             [0.5 0.5] & CENTER=0 or [0 0] & CENTER=1
%          Select the entire image area:
%             [0 0; 1 1] & CENTER=0 or [-1 -1; 1 1]*0.5 & CENTER=1 or [0; 0.5]
%          Select a surrounding region outside the image area:
%             [0.5; 1]
%
%    GAMMA controls how the radial coordinate space is shaped (default 1)
%       When ~=1, this will cause the radial distribution of pixels to be stretched inward 
%          or outward based on a simple power function.  
%       This may be specified explicitly as a scalar, or as a range by using a 1x2 vector.
%       When specified as a range, values will be randomly selected within the ranges:
%          [1/max(gamma) 1/min(gamma)] and [min(gamma) max(gamma)]
%          i.e. normal and inverse adjustments are equally likely
%
%    SWAP swaps the coordinate axes
%
%    FRAMEOFFSET specifies a circular shift of the image prior to transformation.  (default [0 0])
%       Format for this parameter is the same as the 1x2 and 2x2 formats used by OFFSET.
%       This specification is not influenced by the CENTER flag.
%
%    AMOUNT specifies the strength of the transformation. (default 1)
%       Values from 0-1 will interpolate between the calculated coordinate map and the original map.
%       May be specified as a scalar, or as a 1x2 vector for axial independence.
%       Supports negative and complex values.
%
%    INTERPOLATION specifies the interpolation mode (default 'cubic')
%       Supported: 'nearest', 'linear', 'cubic'
%
% A second output argument COMSTRING can optionally be specified.  COMSTRING is a script which will allow the user
% to replicate a particular (potentially randomly parameterized) operation.  This enables the use of small test images
% to refine desired behavior before operating on a larger copy or a multiframe array.
%
% Output class is the same as input class
%
% EXAMPLE:
%    Turn an image into garbage:
%       gpict=imcartpol(inpict,'offset',[0 0],'center','gamma',1.2,'cycles',3,'mode','rinvert');
%    Use a bunch of extra options to make it worse:
%       gpict=imcartpol(inpict,'offset',[0; 1],'gamma',[1 2],'amount',1.5,'cycles',3,'mode','rando','frameoffset',[0 0; 1 1]);
%    Give up and walk away from everything:
%       close all; exit
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imcartpol.html
% See also: displace


s = size(inpict);
[inpict inclass] = imcast(inpict,'double');
comstring = '';

interpmethodstrings = {'nearest','linear','cubic'};
interpmethod = 'cubic';
gamma = 1;
offset = [0 0];
frameoffset = [0 0];
center = 0;
radial = 0;
modestrings = {'cart2pol','pol2cart','rinvert'};
mode = 'rinvert';
swap = 0;
rando = 0;
cycles = 1;
amount = 1;


k = 1;
while k <= numel(varargin)
	thisarg = varargin{k};
	switch thisarg
		case 'gamma'
			gamma = varargin{k+1};
			k = k+2;
		case 'offset'
			offset = varargin{k+1};
			k = k+2;
		case 'frameoffset'
			if size(varargin{k+1},2) == 2
				frameoffset = varargin{k+1};
			else
				error('IMCARTPOL: FRAMEOFFSET only supports 1x2 or 2x2 offset formats')
			end
			k = k+2;
		case 'cycles'
			cycles = varargin{k+1};
			k = k+2;
		case 'amount'
			amount = varargin{k+1};
			k = k+2;
		case 'interpolation'
			thisarg = lower(varargin{k+1});
			if strismember(thisarg,interpmethodstrings)
				interpmethod = thisarg;
			else
				error('IMCARTPOL: unknown interpolation method %s\n',thisarg)
			end
			k = k+2;
		case 'mode'
			thisarg = lower(varargin{k+1});
			if strismember(thisarg,modestrings)
				mode = thisarg;
			elseif strcmpi(thisarg,'rando')
				rando = 1;
			else
				error('IMCARTPOL: unknown mode %s\n',thisarg)
			end
			k = k+2;	
		case 'center'
			center = 1;
			k = k+1;
		case 'swap'
			swap = 1;
			k = k+1;
	end
end

% convert to radial mode
if size(offset,2) == 1	
	radial = 1;
	center = 1;
end


if size(amount,2) == 1
	amount = repmat(amount,[1 2]);
end

outpict = imzeros(size(inpict),class(inpict));
[xx0 yy0] = meshgrid(1:s(2),1:s(1));
for cy = 1:cycles
	
	% random behavior
	if rando
		mode = modestrings{round(randrange([1 numel(modestrings)]))};
		swap = round(rand());
	end
	
	% set offset (normalized coordinates)
	if radial
		if size(offset,1) == 2
			if round(rand())
				constrainedax = randrange([-max(offset) -min(offset)]);
			else
				constrainedax = randrange([min(offset) max(offset)]);
			end
			
			if round(rand())
				thisoffset = [randrange([-1 1]*max(offset)) constrainedax];
			else
				thisoffset = [constrainedax randrange([-1 1]*max(offset))];
			end
		else
			thisoffset = [randrange([-1 1]*offset) randrange([-1 1]*offset)];
		end
	else
		if size(offset,1) == 2
			thisoffset = [randrange(offset(:,1)') randrange(offset(:,2)')];
		else
			thisoffset = offset;
		end
	end

	if center
		thisoffset = thisoffset+0.5;
	end	
	
	% set gamma
	if numel(gamma) == 2
		thisgamma = randrange(gamma);
		if round(rand())
			thisgamma = 1/thisgamma;
		end
	else
		thisgamma = gamma;
	end
	
	% set frame offset (normalized coordinates)
	if size(frameoffset,1) == 2
		thisfoffset = [randrange(frameoffset(:,1)') randrange(frameoffset(:,2)')];
	else
		thisfoffset = frameoffset;
	end
	
	% set amount
	if size(amount,1) == 2
		thisamount = [randrange(amount(:,1)') randrange(amount(:,2)')];
	else
		thisamount = amount;
	end

	
	% transform frames
	for f = 1:size(inpict,4)
		xx = round(xx0-thisoffset(2)*s(2));
		yy = round(yy0-thisoffset(1)*s(1));

		switch mode
			case 'cart2pol'
				rr = sqrt(xx.^2 + yy.^2);
				tt = atan2(yy,xx);

				[mn mx] = imrange(rr);
				rr = ((rr/mx).^thisgamma)*mx;

				if swap
					newxx = rr;
					newyy = tt;
				else
					newxx = tt;
					newyy = rr;
				end

			case 'pol2cart'
				if swap
					tt = xx/s(2);
					rr = yy/s(1);
				else
					rr = xx/s(2);
					tt = yy/s(1);
				end

				[mn mx] = imrange(rr);
				rr = ((rr/mx).^thisgamma)*mx;

				newxx = rr.*cos(tt*2*pi);
				newyy = rr.*sin(tt*2*pi);
				
			case 'rinvert'
				rr = sqrt(xx.^2 + yy.^2);
				tt = atan2(yy,xx);
				
				% naive flipping
				[mn mx] = imrange(rr);
				newrr = mx-rr+mn;

				% easerr
				newrr = newrr/mx;
				newrr = newrr.^thisgamma;
				newrr = newrr*mx;

				if swap
					newxx = newrr.*sin(tt);
					newyy = newrr.*cos(tt);
				else
					newxx = newrr.*cos(tt);
					newyy = newrr.*sin(tt);
				end
		end

		dxx = simnorm(newxx)*s(2);
		dyy = simnorm(newyy)*s(1);
				
		dxx = dxx*thisamount(2) + xx0*(1-thisamount(2));
		dyy = dyy*thisamount(1) + yy0*(1-thisamount(1));
	
		dxx = abs(min(max(dxx,1),s(2)));
		dyy = abs(min(max(dyy,1),s(1)));
		
		for c = 1:size(inpict,3)
			if sum(frameoffset) == 0
				outpict(:,:,c,f) = interp2(xx0,yy0,inpict(:,:,c,f),dxx,dyy,interpmethod);
			else
				chan = circshift(inpict(:,:,c,f),round(thisfoffset.*s(1:2)));
				chan = interp2(xx0,yy0,chan,dxx,dyy,interpmethod);
				outpict(:,:,c,f) = chan;
			end
		end
	end
	
	inpict = outpict;
	
	% thisoffset already incorporates 'center' flag, don't ever need it
	if cy == 1; tps1 = 'inpict'; else tps1 = 'wpict'; end
	if swap; tps2 = ',''swap'''; else tps2 = ''; end
	tcs1 = sprintf('wpict = imcartpol(%s,''offset'',%s,''gamma'',%s,''frameoffset'',%s,''cycles'',%s,''amount'',%s,''interpolation'',''%s'',''mode'',''%s''%s); \n',...
		          tps1,mat2str(thisoffset),mat2str(thisgamma),mat2str(thisfoffset),num2str(cycles),mat2str(thisamount),interpmethod,mode,tps2);
	comstring = [comstring tcs1];
end

outpict = imcast(inpict,inclass);

end

