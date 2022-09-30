function outpict = imrectrotate(inpict,angle,varargin)
%   IMRECTROTATE(INPICT, ANGLE, {OPTIONS})
%       Rotate an image using pixel displacement to crudely maintain boundary geometry.
%       Characteristic creasing effects can be maximized with iterative application.
%       This is not intended for any technical purpose requiring accuracy or reversibility.
%
%   INPICT is an I/IA/RGB/RGBA image of any standard image class
%   ANGLE is the rotation angle in degrees
%      May be specified as a scalar or as a vector for iterative processing
%   OPTIONS are keys and key-value pairs:
%   'center' specifies the rotation center (default [0.5 0.5])
%      Location is WRT top left corner and is normalized WRT image dimensions.
%      Specifying locations near or outside the image boundary may result in baffling garbage.
%      May be specified as a 1x2 vector or as a Nx2 array for iterative processing
%   'gamma' controls how the radial coordinate space is shaped (default 1)
%      When ~=1, this will cause the radial distribution of pixels to be stretched inward 
%      or outward based on a simple power function. 
%      May be specified as a scalar or as a vector for iterative processing
%   'pwlgamma' is similar to 'gamma', but allows the specification of an arbitrary piecewise-linear
%      ease curve instead of a simple power function.  Specification is in the form of a row vector of
%      nominally normalized values (e.g. [0 1] is the default linear mapping; [0 0.0625 0.25 0.5625 1]
%      approximates a 'gamma' spec of 2).  Breakpoints are assumed to be uniformly spaced. 
%      For iterative processing, this parameter may be a matrix with the number of iterations implied
%      by the number of row vectors.
%   'proportional' key changes the distortion behavior
%      when specified, image edge lengths are treated as if equal
%      corner pixels remain in image corners for default center and angles divisible by 90
%      normally, edges of nonsquare images will wrap around corners in these cases
%   'interpolation' specifies the interpolation method (default 'cubic')
%      Supported: 'nearest', 'linear' or 'cubic'
%
%   If iterative processing is implicitly specified by multiple parameters (e.g. ANGLE and CENTER), 
%      they must specify the same number of iterations. 
%
%   Output class is the same as input class
%       
%   EXAMPLE:
%   a simple rotation about a center point
%      dpict=imrectrotate(inpict,30,'center',[0.5 0.1],'proportional');
%   make a complete mess
%      dpict=imrectrotate(inpict,ones([1 8])*5,'center',rand([8 2]));
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imrectrotate.html
% See also: imcartpol, imannrotate, displace

% proportional doesn't really work if uncentered
% edge-scaling is correct, but being off-center offsets the corners 
% is it practical to keep this option?


center = [0.5 0.5];
gamma = 1;
pwlgamma = [0 1];
usepwlgamma = false;
interpmethodstrings = {'nearest','linear','cubic','none'};
interpmethod = 'cubic';
proportional = false;
ca = [1 1 1 1];

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
        case 'center'
            center = varargin{k+1};
			k = k+2;
		case 'gamma'
            gamma = varargin{k+1};
			k = k+2;
		case 'pwlgamma'
			pwlgamma = varargin{k+1};
			k = k+2;
		case 'proportional'
			proportional = true;
			k = k+1;
		case 'interpolation'
			thisarg = varargin{k+1};
			if strismember(thisarg,interpmethodstrings)
				interpmethod = thisarg;
			else
				error('IMRECTROTATE: unknown interpolation method %s\n',thisarg)
			end
			k = k+2;
        otherwise
            error('IMRECTROTATE: unknown input parameter name %s',varargin{k})
    end
end

if strcmpi(interpmethod,'none')
	interpmethod = 'nearest';
end

switch lower(interpmethod)
	case 'nearest'
		resizeinterp = 'nearest';
	case 'linear'
		resizeinterp = 'bilinear';
	case 'cubic'
		resizeinterp = 'bicubic';
end

if size(pwlgamma,1) ~= 1 || size(pwlgamma,2) ~= 2
	usepwlgamma = true;
elseif any(pwlgamma ~= [0 1])
	usepwlgamma = true;
end

if proportional
	% this could be integrated into the main interpolation
	sorig = size(inpict);
	maxdim = max(sorig(1:2));
	inpict = imresizeFB(inpict,[1 1]*maxdim,resizeinterp);
end

angle = angle*pi/180;

s = size(inpict);
nchans = size(inpict,3);
[inpict inclass] = imcast(inpict,'double');

% denormalize center parameter
if numel(center) == 2
	center = reshape(center,[1 2]);
end
center = bsxfun(@times,center,s(1:2));

% expand parameter arrays as necessary
if size(center,1) > 1
	if numel(angle) == 1
		angle = repmat(angle,[size(center,1) 1]);
	elseif numel(angle) ~= size(center,1)
		error('IMRECTROTATE: length of ANGLE vector does not correspond to dim 1 of CENTER')
	end
	if numel(gamma) == 1
		gamma = repmat(gamma,[size(center,1) 1]);
	elseif numel(gamma) ~= size(center,1)
		error('IMRECTROTATE: length of GAMMA vector does not correspond to dim 1 of CENTER')
	end
	if size(pwlgamma,1) == 1
		pwlgamma = repmat(pwlgamma,[size(center,1) 1]);
	elseif size(pwlgamma,1) ~= size(center,1)
		error('IMRECTROTATE: dim 1 of PWLGAMMA vector does not correspond to dim 1 of CENTER')
	end
else
	if numel(angle) > 1
		center = repmat(center,[numel(angle) 1]);
		if numel(gamma) == 1
			gamma = repmat(gamma,[numel(angle) 1]);
		elseif numel(gamma) ~= numel(angle)
			error('IMRECTROTATE: length of GAMMA vector does not correspond to length of ANGLE vector')
		end
		if size(pwlgamma,1) == 1
			pwlgamma = repmat(pwlgamma,[numel(angle) 1]);
		elseif size(pwlgamma,1) ~= numel(angle)
			error('IMRECTROTATE: dim 1 of PWLGAMMA vector does not correspond to length of ANGLE vector')
		end
	else
		if numel(gamma) > 1
			center = repmat(center,[numel(gamma) 1]);
			angle = repmat(angle,[numel(gamma) 1]);
			if size(pwlgamma,1) == 1
				pwlgamma = repmat(pwlgamma,[numel(gamma) 1]);
			elseif size(pwlgamma,1) ~= numel(gamma)
				error('IMRECTROTATE: dim 1 of PWLGAMMA vector does not correspond to length of GAMMA vector')
			end
		end
	end
end

% pwlgamma assumes uniform breakpoint spacing
% rescaling means that endpoints span [0 1] (or [1 0])

rmax = [];
outpict = inpict;
[xx0 yy0] = meshgrid(1:s(2),1:s(1));
for cycle = 1:numel(angle)
	thisangle = angle(cycle);
	thiscenter = center(cycle,:);
	thisgamma = gamma(cycle);
	thispwlgamma = pwlgamma(cycle,:);
	
	% critical angles
	ca(1) = atan2(s(1)-thiscenter(1),s(2)-thiscenter(2));
	ca(2) = pi-atan2(s(1)-thiscenter(1),thiscenter(2));
	ca(3) = pi+atan2(thiscenter(1),thiscenter(2));
	ca(4) = 2*pi-atan2(thiscenter(1),s(2)-thiscenter(2));
	ca = mod(ca,2*pi);
	
	xx = round(xx0-thiscenter(2));
	yy = round(yy0-thiscenter(1));

	rr = sqrt(xx.^2 + yy.^2);
	tt = mod(atan2(yy,xx),2*pi);
	
	% normalize and rotate
	findrmax();
	rr = rr./rmax;
	tt = mod(tt+thisangle,2*pi);
	findrmax();

	% stretch and denormalize
	if usepwlgamma
		rrange = imrange(rr);
		rr = interp1(linspace(rrange(1),rrange(2),numel(thispwlgamma)),thispwlgamma,rr);
	end
	if thisgamma ~= 1; rr = rr.^thisgamma; end
	rr = rr.*rmax;

	dxx = rr.*cos(tt);
	dyy = rr.*sin(tt);

	% remove offset and refit
	dxx = 1+simnorm(dxx)*(s(2)-1);
	dyy = 1+simnorm(dyy)*(s(1)-1);

	for c = 1:nchans
		outpict(:,:,c) = interp2(xx0,yy0,outpict(:,:,c),dxx,dyy,interpmethod);
	end	
end

if proportional
	outpict = imresizeFB(outpict,sorig(1:2),resizeinterp);
end

outpict = imcast(outpict,inclass);

function findrmax()
	thiseps = 1E-6;
	rmax = zeros(s(1:2));
	m1 = tt > ca(1); m2 = tt > ca(2); m3 = tt > ca(3); m4 = tt > ca(4);
	
	thismask = ~m1|m4; thistt = tt(thismask); 
	thistt(thistt == pi/2) = pi/2+thiseps; thistt(thistt == 3*pi/2) = 3*pi/2+thiseps; 
	rmax(thismask) = (s(2)-thiscenter(2))./cos(thistt);
	
	thismask = m1&~m2; thistt = tt(thismask); 
	thistt(thistt == 0) = thiseps; thistt(thistt == pi) = pi+thiseps; 
	rmax(thismask) = (s(1)-thiscenter(1))./sin(thistt);
	
	thismask = m2&~m3; thistt = tt(thismask); 
	thistt(thistt == pi/2) = pi/2+thiseps; thistt(thistt == 3*pi/2) = 3*pi/2+thiseps; 
	rmax(thismask) = -thiscenter(2)./cos(thistt);
	
	thismask = m3&~m4; thistt = tt(thismask); 
	thistt(thistt == 0) = thiseps; thistt(thistt == pi) = pi+thiseps; 
	rmax(thismask) = -thiscenter(1)./sin(thistt);
end

end































