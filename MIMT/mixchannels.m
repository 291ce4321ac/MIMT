function outpict = mixchannels(inpict,A,normalize)
%  OUTPICT = MIXCHANNELS(INPICT,MAT,{NORMALIZE})
%  Mix the color channels of an image.  This is equivalent to 
%  the GIMP plugin of the same name.
%
%  INPICT is an RGB/RGBA image of any standard image class. 
%    Multiframe images are not supported.  Alpha content is preserved.
%  MAT is a 3x3 or 1x3 matrix describing the color transformation.
%    Each output channel is represented by one row, the elements
%    of which being the coefficients in the weighted sum of the
%    input channels.  If a 1x3 vector is used, the output is mono.
%  NORMALIZE is an optional key. When 'normalize' is used, 
%    the rows of MAT will be sum-normalized in an attempt to preserve
%    image intensity.
%
%  Output class is inherited from input.
%
%  See also: imappmat, colorbalance, tonergb, tonecmyk, imtweak

if nargin == 2
	normalize = false;
end

[inpict alpha] = splitalpha(inpict);

nc = size(inpict,3);
if nc~=3
	error('MIXCHANNELS: expected inpict to be an RGB/RGBA image')
end

sz = imsize(A,2);
if sz(2)~=3 || all(sz(1)~=[3 1])
	error('MIXCHANNELS: transformation matrix A must be 3x3 or 1x3')
end

if normalize
	s = sum(A,2);
	s(s==0) = 1; % keep things from exploding
	A = bsxfun(@rdivide,A,abs(s));
end

[inpict inclass] = imcast(inpict,'double');

outpict = imappmat(inpict,A);
outpict = imclamp(outpict);

outpict = imcast(outpict,inclass);
outpict = joinalpha(outpict,alpha);



