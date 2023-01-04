function inpict = fmedfilt(inpict,wsz,tol)
%  OUTPICT = FMEDFILT(INPICT,{WSZ},{TOL})
%  Apply simple fixed-window median noise removal filter.  This is useful  
%  for removing impulse (salt & pepper) noise from an image.  
%
%  INPICT is an array of any standard image class.  Multipage images
%    are supported.  Multipage images are processed pagewise.
%  WSZ optionally specifies the window width (px, default [3 3])
%    May be specified as a 2-element vector or as a scalar with 
%    implicit expansion.  Values are rounded to the nearest odd integer.
%  TOL optionally specifies the tolerance used for identifying noise
%    By default, pixels which are within 0.5% of the class-dependent
%    black/white values are considered to be noise.  For example, when
%    TOL = 0.01, pixels outside [0.01 0.99] are considered noise.
%    
%  Output class is inherited from input
%
%  See also: amedfilt, nhfilter, medfilt2

if nargin<2
	wsz = [3 3];
end
if nargin<3
	tol = 0.005;
end

wsz = max(roundodd(wsz),3);
if isscalar(wsz)
	wsz = [1 1]*wsz;
end
rmax = floor(wsz/2);

inclass = class(inpict);
extrange = [0 1]+[1 -1]*tol;
extrange = imrescale(extrange,'double',inclass);

sz = imsize(inpict);

% pad and filter
inpict = padarrayFB(inpict,rmax,'symmetric','both');
medpict = nhfilter(inpict,'median',wsz);

% generate mask
mk = inpict<=extrange(1) | inpict>=extrange(2);

% apply mask
inpict(mk) = medpict(mk);

% crop output
inpict = inpict(rmax(1)+1:rmax(1)+sz(1),rmax(2)+1:rmax(2)+sz(2),:);

end

