function outpict = imcontfdx(inpict,mask,varargin)
%   OUTPICT=IMCONTFDX(INPICT,MASK,{OPTIONS})
%       This is a continuized masked subvector transformation tool -- a continuized 
%       generalization of the primary variants of the FD style image mangling routines.
%
%       The pixels selected by a mask are subject to vector segment transformations
%       oriented with respect to user-defined angles.  When combined with the included
%       FDBLEND tool, the resultant transformed image stack is subject to cyclic color 
%       permutation and frame blending as the original scripts performed.  Unless your 
%       goal is to turn images into unrecognizable garbage, you will never need these 
%       tools.  These are both overcomplicated and computationally expensive tools with 
%       no intended technical use.
%
%       Typical approaches balance the object geometry weakly implied by strategic 
%       masking against the original image content which loses its trivial clarity 
%       with displacement.  In other words, if you want the output to be both 
%       recognizable and interesting, do it via the mask at least as much as the image.
%       
%   INPICT is a single-frame I/RGB image of any standard image class
%   MASK is typically a multiframe set of I/RGB logical masks
%       The height and width of INPICT and MASK must match.  If either the mask
%       or image has fewer channels than the other, it will be expanded.  Numeric
%       masks will be converted to logical with a 50% thresholding.
%       The number of frames in MASK define the number of frames in OUTPICT.
%   OPTIONS include the keys and key-value pairs:
%       'angle' is a vector of angles along which each subscript permutation should 
%         occur. The length of this vector corresponds to the number of mask frames.  
%         If scalar, this parameter will be expanded as necessary.  If this parameter
%         is not specified, random angles will be chosen.
%       'style' selects the transformation style.  Values are 1, 2 or 3.  (default 2)
%       'shamt' specifies the vector shift parameter used by style 2 and 3.  This is a 
%         3x2 array of the form [Rx Ry; Gx Gy; Bx By]. (default [1 1; 0 0; -1 -1]*2)
%       'filter' is either a 2D filter kernel (e.g. from fspecial() or fkgen())
%         or the key 'none' if no smoothing is desired.  The user-supplied filter
%         should have a unit sum (i.e. no Sobel filter).  Default is a 50px gaussian.
%       'interpolation' specifies the interpolation method.  Valid inputs are 
%         'nearest','linear', and 'cubic'.  (default 'linear')
%       'quiet' suppresses progress messages which are otherwise dumped to console.
%       
%   Output class is inherited from INPICT
%       
%   Example:
%       Auto-generate a 4-frame RGB mask and turn an image into colorful garbage
%       outpict=fdblend(imcontfdx(inpict,mlmask(inpict,4),'angle',[-60 30 -30 60], ...
%               'filter',fkgen('gaussian',20)));
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imcontfdx.html
% See also: fdblend, imcontmip, continuize, imcartpol, displace, imrectrotate


% fix matchchannels bug
% will styles 2,3 work without RGB inputs?


interpmethodstrings = {'nearest','linear','cubic'};
interpmethod = 'linear';
fs = fkgen('gaussian',50);
nofilter = false;
quiet = false;
shamt = [1 1; 0 0; -1 -1]*2;
stylevec = [1 2 3];
style = 2;

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
		case 'filter'
			thisarg = varargin{k+1};
			if ischar(thisarg)
				if strcmpi(thisarg,'none')
					nofilter = true;
				else
					error('IMCONTFDX: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
				end
				k = k+2;
			elseif numel(thisarg) >= 2 && size(thisarg,3) == 1 && round(sum(thisarg(:))*100)/100 == 1
				fs = thisarg;
				k = k+2;
			else
				error('IMCONTFDX: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
			end
		case 'shamt'
			thisarg = varargin{k+1};
			if all(size(thisarg) == [3 2])
				shamt = thisarg;
				k = k+2;
			else
				error('IMCONTFDX: user-supplied shift array should be of size [3 2]')
			end
		case 'style'
			thisarg = varargin{k+1};
			if any(thisarg == stylevec)
				style = thisarg;
				k = k+2;
			else
				error('IMCONTFDX: unknown value for style parameter')
			end
		case 'angle'
			thetavec = varargin{k+1};
			k = k+2;
		case 'quiet'
			quiet = true;
			k = k+1;
		case 'interpolation'
			thisarg = varargin{k+1};
			if strismember(thisarg,interpmethodstrings)
				interpmethod = thisarg;
			else
				error('IMCONTFDX: unknown interpolation method %s\n',thisarg)
			end
			k = k+2;
        otherwise
            error('IMCONTFDX: unknown input parameter name %s',varargin{k})
    end
end

switch interpmethod
	case 'nearest'
		rinterp = 'nearest';
		mapinterp = 'nearest';
	case 'linear'
		rinterp = 'bilinear';
		mapinterp = 'linear';
	case 'cubic'
		rinterp = 'bicubic';
		mapinterp = 'cubic';
end

% check image/mask correspondence
s = size(inpict);
sm = size(mask);
if any(s(1:2) ~= sm(1:2))
	error('IMCONTFDX: image size %s and mask size %s don''t match',mat2str(s(1:2)),mat2str(sm(1:2)))
end

% generating subs, replicating/padding takes time before main perms loop
if ~quiet
	msg = 'preparing arrays';
	fprintf('%s\n',msg);
end

% check mask/angle correspondence
nframes = size(mask,4);
if ~exist('thetavec','var')
	thetavec = randrange([-180 180],[1 nframes]);
end
nangles = numel(thetavec);
if nangles ~= nframes
	if nangles == 1 && nframes > 1
		thetavec = repmat(thetavec,[1 nframes]);
	elseif nframes == 1 && nangles > 1
		mask = repmat(mask,[1 1 1 nangles]);
	else
		error('IMCONTFDX: angle vector contains %d elements and mask contains %d frames.  These must either be equal, or one of the two must be 1 to allow unambiguous expansion',nangles,nframes)
	end
end
nsteps = max(nframes,nangles);

[inpict inclass] = imcast(inpict,'double');
mask = imcast(mask,'logical');
	
borderpad = 4;
sb = s+2*borderpad;
[x0 y0] = meshgrid(1:s(2),1:s(1));

[cc ~] = chancount(inpict);
[mcc ~] = chancount(mask);
if mcc == 3
	if cc == 1
		inpict = repmat(inpict,[1 1 3]);
	end
	xx = repmat(x0,[1 1 3 nsteps]);
	yy = repmat(y0,[1 1 3 nsteps]);
else
	xx = repmat(x0,[1 1 1 nsteps]);
	yy = repmat(y0,[1 1 1 nsteps]);	
end

% size of circumscribed box
% effective h of t/b edge + effective h of l/r edge
boxh = abs(sb(2)*sind(thetavec)) + abs(sb(1)*sind(thetavec+90));
boxw = abs(sb(2)*cosd(thetavec)) + abs(sb(1)*cosd(thetavec+90));

% find maximal box deltas; rotating with 'crop' flag 
% means this is also the edge delta for all frames
padh = ceil(max(max(boxh-sb(1)),0)/2);
padw = ceil(max(max(boxw-sb(2)),0)/2);

% pad mask & image maps
xx = addborder(xx,[padh padw],0);
yy = addborder(yy,[padh padw],0);
invmask = addborder(~mask,[padh padw],0);
mask = addborder(mask,[padh padw],0);

% permute maps 
for f = 1:nsteps
	if ~quiet
		if f == 1
			msg = sprintf('transforming frame %d of %d',f,nsteps);
			fprintf(msg);
		else
			remc = repmat(sprintf('\b'),[1 numel(msg)]);
			msg = sprintf('transforming frame %d of %d',f,nsteps);
			fprintf([remc msg]);
		end
	end
	thisxx = imrotateFB(xx(:,:,:,f),thetavec(f),rinterp,'crop');
	thisyy = imrotateFB(yy(:,:,:,f),thetavec(f),rinterp,'crop');
 	thismask = imrotateFB(mask(:,:,:,f),thetavec(f),rinterp,'crop');
	thisinvmask = imrotateFB(invmask(:,:,:,f),thetavec(f),rinterp,'crop');

	% do map transformations
	switch style
		case 1
			thisxx = roiflip(flipd(thisxx,2),thisinvmask,2,'segment');
			thisyy = roiflip(thisyy,thismask,1,'segment');
		case 2
			thisxx = roiflip(thisxx,thisinvmask,2,'segment');
			thisyy = roiflip(lineshifter(thisyy,thismask,shamt),thismask,1,'segment');
		case 3
			thisxx = roiflip(lineshifter(thisxx,thismask,shamt),thisinvmask,2,'segment');
			thisyy = roiflip(lineshifter(thisyy,thismask,shamt),thismask,1,'segment');
	end
	
	% rectify and store frame
	xx(:,:,:,f) = imrotateFB(thisxx,-thetavec(f),rinterp,'crop');
	yy(:,:,:,f) = imrotateFB(thisyy,-thetavec(f),rinterp,'crop');
end

% crop maps back to image size
xx = xx((padh+1):(end-padh),(padw+1):(end-padw),:,:);
yy = yy((padh+1):(end-padh),(padw+1):(end-padw),:,:);

% filter for smoothing
if ~quiet; fprintf('\nfiltering & interpolating\n'); end
if nofilter
	xb = xx;
	yb = yy;
else
	xb = imfilterFB(xx,fs,'replicate');
	yb = imfilterFB(yy,fs,'replicate');
end
xb = min(max(xb,1),s(2));
yb = min(max(yb,1),s(1));

% interpolate
sh = zeros([s(1:2) size(inpict,3) nsteps],'double');
for f = 1:nsteps
	if mcc == 1
		for c = 1:size(inpict,3)
			sh(:,:,c,f) = interp2(x0,y0,inpict(:,:,c),xb(:,:,:,f),yb(:,:,:,f),mapinterp);
		end
	else
		for c = 1:size(inpict,3)
			sh(:,:,c,f) = interp2(x0,y0,inpict(:,:,c),xb(:,:,c,f),yb(:,:,c,f),mapinterp);
		end
	end
end

outpict = imcast(min(max(sh,0),1),inclass);

end






























