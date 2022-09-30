function outpict = imcontmip(inpict,mask,varargin)
%   OUTPICT=IMCONTMIP(INPICT,MASK,{OPTIONS})
%       This is a continuized masked image permutation tool -- the simplest and most 
%       easily continuized derivative of the early FD style image mangling routines. 
% 
%       In the simplest form, the pixels selected by a mask are permuted via a scaled 
%       circular shift of linear indices.  As operations are iterative and reference 
%       frame orientation can be altered, the trajectory of image content can be non-
%       obvious.  Unless your goal is to turn images into unrecognizable garbage, you 
%       will never need this.  This is an overcomplicated and computationally expensive 
%       tool with no intended technical use.
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
%   OPTIONS include the keys and key-value pairs:
%       'angle' is a vector of angles along which each subscript permutation should 
%         occur. The length of this vector corresponds to the number of mask frames.  
%         If scalar, this parameter will be expanded as necessary.  If this parameter
%         is not specified, random angles will be chosen.
%       'params' specifies how much the subscripts selected by each mask should be
%         shifted.  This is a three-element vector [k p os] specifying a binomial 
%         of the form k*x^p + os, where x is proportional to the mask area. The
%         default is [1 1 0], though it should not be assumed to be optimal.
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
%       outpict=imcontmip(inpict,mlmask(inpict,4),'angle',[-60 30 -30 60], ...
%               'filter',fkgen('gaussian',20),'params',[1 0.8 0]);
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imcontmip.html
% See also: imcontfdx, continuize, imcartpol, displace, imrectrotate

% things to try:
% can this be continuized to use non-logical masks (linear blending? how?)
%   see linearized version in oldfiles for various approaches 
%   linearizing may be a convenient method to generate animations demonstrating permutation in action
%   maybe just use a scalar parameter instead of mapping ... wouldn't that just be the same as scaling paramvec?
% extend to original and modified FD transformations
% maybe make 'params' optionally per-frame

params = [1 1 0];
interpmethodstrings = {'nearest','linear','cubic'};
interpmethod = 'linear';
fs = fkgen('gaussian',50);
nofilter = false;
quiet = false;

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
		case 'filter'
			thisarg = varargin{k+1};
			if ischar(thisarg)
				if strcmpi(thisarg,'none')
					nofilter = true;
				else
					error('IMCONTMIP: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
				end
				k = k+2;
			elseif numel(thisarg) >= 2 && size(thisarg,3) == 1 && round(sum(thisarg(:))*100)/100 == 1
				fs = thisarg;
				k = k+2;
			else
				error('IMCONTMIP: user-supplied filter kernel should be the string ''none'' or a 2-D array with a unit sum')
			end
		case 'angle'
			theta = varargin{k+1};
			k = k+2;
		case 'params'
			params = varargin{k+1};
			if numel(params) ~= 3
				error('IMCONTMIP: parameter vector must contain 3 elements [k p os]')
			end
			k = k+2;
		case 'quiet'
			quiet = true;
			k = k+1;
		case 'interpolation'
			thisarg = varargin{k+1};
			if strismember(thisarg,interpmethodstrings)
				interpmethod = thisarg;
			else
				error('IMCONTMIP: unknown interpolation method %s\n',thisarg)
			end
			k = k+2;
        otherwise
            error('IMCONTMIP: unknown input parameter name %s',varargin{k})
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
	error('IMCONTMIP: image size %s and mask size %s don''t match',mat2str(s(1:2)),mat2str(sm(1:2)))
end

% generating subs, replicating/padding takes time before main perms loop
if ~quiet
	msg = 'preparing arrays';
	fprintf('%s\n',msg);
end

% check mask/angle correspondence
nframes = size(mask,4);
if ~exist('theta','var')
	theta = randrange([-180 180],[1 nframes]);
end
nangles = numel(theta);
if nangles ~= nframes
	if nangles == 1 && nframes > 1
		theta = repmat(theta,[1 nframes]);
	elseif nframes == 1 && nangles > 1
		mask = repmat(mask,[1 1 1 nangles]);
	else
		error('IMCONTMIP: angle vector contains %d elements and mask contains %d frames.  These must either be equal, or one of the two must be 1 to allow unambiguous expansion',nangles,nframes)
	end
end
nsteps = max(nframes,nangles);

[inpict inclass] = imcast(inpict,'double');
mask = imcast(mask,'logical');
	
% linear indices are oriented along dim1, not dim2
theta = 90-theta; 
% since operations are iterative, we actually need the angle differences
thetavec = [theta(1) diff(reshape(theta,1,[]))]; 
borderpad = 4;
sb = s+2*borderpad;
[x0 y0] = meshgrid(1:s(2),1:s(1));

[cc ~] = chancount(inpict);
[mcc ~] = chancount(mask);
if mcc == 3
	if cc == 1
		inpict = repmat(inpict,[1 1 3]);
	end
	xx = repmat(x0,[1 1 3]);
	yy = repmat(y0,[1 1 3]);
else 
	xx = x0;
	yy = y0;
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
mask = addborder(mask,[padh padw],0);

% permute maps 
for f = 1:nsteps
	if ~quiet
		if f == 1
			msg = sprintf('permuting frame %d of %d',f,nsteps);
			fprintf(msg);
		else
			remc = repmat(sprintf('\b'),[1 numel(msg)]);
			msg = sprintf('permuting frame %d of %d',f,nsteps);
			fprintf([remc msg]);
		end
	end
	xx = imrotateFB(xx,thetavec(f),rinterp,'crop');
	yy = imrotateFB(yy,thetavec(f),rinterp,'crop');
 	mask = imrotateFB(mask,thetavec(f),rinterp,'crop');
	
	for c = 1:mcc
		mind = find(mask(:,:,c,f) == 1);
		pind = circshift(mind,[round(params(1)*(numel(mind)*0.001).^params(2) + params(3)) 0]);

		temp = xx(:,:,c);
		temp(pind) = temp(mind);
		xx(:,:,c) = temp;

		temp = yy(:,:,c);
		temp(pind) = temp(mind);
		yy(:,:,c) = temp;
	end
end

% rectify image
rtheta = -mod(theta(end),360);
if rtheta ~= 0
	xx = imrotateFB(xx,rtheta,rinterp,'crop');
	yy = imrotateFB(yy,rtheta,rinterp,'crop');
end

% crop maps back to image size
xx = xx((padh+1):(end-padh),(padw+1):(end-padw),:);
yy = yy((padh+1):(end-padh),(padw+1):(end-padw),:);

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
outpict = inpict;
if mcc == 1
	for c = 1:size(inpict,3)
		outpict(:,:,c) = interp2(x0,y0,inpict(:,:,c),xb,yb,mapinterp);
	end
else
	for c = 1:size(inpict,3)
		outpict(:,:,c) = interp2(x0,y0,inpict(:,:,c),xb(:,:,c),yb(:,:,c),mapinterp);
	end
end
outpict = imcast(min(max(outpict,0),1),inclass);

end






























