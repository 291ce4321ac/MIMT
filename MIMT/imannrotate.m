function outpict = imannrotate(inpict,angle,varargin)
%   IMANNROTATE(INPICT, ANGLE, {OPTIONS})
%       Rotate an image using simple annular shifting to crudely maintain boundary geometry.
%       This is not intended for any technical purpose requiring accuracy or reversibility.
%
%   INPICT is an I/IA/RGB/RGBA image of any standard image class
%   ANGLE is the rotation angle in degrees
%      Rotation is about the image center.
%   OPTIONS include the following keys and key-value pairs
%   'keepcenter' varies the shift amount (a proxy for rotation angle) proportional to the 
%      relative radius from the image center.  This helps reduce the discontinuity which otherwise
%      appears in the center when rotating nonsquare images.
%   'gamma' allows the radially-dependent behavior of the 'keepcenter' option to be nonlinear (default 1)
%      When =1, shift amount varies linearly from 0 at the image center to the amount defined
%          by ANGLE for pixels near the image border. 
%      When >1, a larger area of the image center becomes less affected by the rotation.
%      When <<1, the behavior approaches that when 'keepcenter' is unset. 
%   'pwlgamma' is similar to 'gamma', but allows the specification of an arbitrary piecewise-linear
%      ease curve instead of a simple power function.  Specification is in the form of a vector of
%      nominally normalized values (e.g. [0 1] is the default linear mapping; [0 0.0625 0.25 0.5625 1]
%      approximates a 'gamma' spec of 2).  Breakpoints are assumed to be uniformly spaced.
%
%   Output class is the same as input class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imannrotate.html
% See also: imrectrotate, imcartpol, displace

keepcenter = false;
gamma = 1;
pwlgamma = [0 1];
usepwlgamma = false;

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
		case 'keepcenter'
			keepcenter = true;
			k = k+1;
		case 'gamma'
            gamma = varargin{k+1};
			k = k+2;
		case 'pwlgamma'
			pwlgamma = varargin{k+1};
			k = k+2;
        otherwise
            error('IMANNROTATE: unknown input parameter name %s',varargin{k})
    end
end

pwlgamma = pwlgamma(1,:);
pwlgx = linspace(0,1,numel(pwlgamma));
if size(pwlgamma,2) ~= 2
	usepwlgamma = true;
elseif any(pwlgamma ~= [0 1])
	usepwlgamma = true;
end

% one would think this line-by-line method would be terribly slow, but it's not too bad.
% how could non-centered rotation work without interpolation?
%   find maximum inscribed symmetric rectangle?
%     how to handle remaining space? leave? wrap edges? discard & fill? discard & smear?
%   find minimum circumscribed symmetric rectangle?
%     wrap edges? discard & fill? discard & smear?

s = size(inpict);
outpict = inpict;

maxr = min(s(1:2))/2;
corners = [s(1) s(2)]+1;
for a = 1:floor(maxr)
	corners = corners-1;
	l = corners-a+1;
	
	thisannulus = cat(1,inpict(a:corners(1),a,:), ...
		permute(inpict(corners(1),a:corners(2),:),[2 1 3]), ...
		inpict(corners(1):-1:a,corners(2),:), ...
		permute(inpict(a,corners(2):-1:a,:),[2 1 3]));
	
	if keepcenter
		if usepwlgamma
			pganglescale = interp1(pwlgx,pwlgamma,(maxr-a)/(maxr-1));
			shamt = round(size(thisannulus,1) * angle/360 * pganglescale^gamma);
		else
			shamt = round(size(thisannulus,1) * angle/360 * ((maxr-a)/(maxr-1))^gamma);
		end
	else
		shamt = round(size(thisannulus,1) * angle/360);
	end
	
	thisannulus = circshift(thisannulus,[shamt 0 0]);
	
	outpict(a:corners(1),a,:) = thisannulus(1:l(1),1,:);
	outpict(corners(1),a:corners(2),:) = permute(thisannulus((l(1)+1):(l(1)+l(2)),1,:),[2 1 3]);
	outpict(corners(1):-1:a,corners(2),:) = thisannulus((l(1)+l(2)+1):(2*l(1)+l(2)),1,:);
	outpict(a,corners(2):-1:a,:) = permute(thisannulus((2*l(1)+l(2)+1):(2*l(1)+2*l(2)),1,:),[2 1 3]);
end

end
































