function maskstack = mlmask(inpict,numlevels)
%   OUTMASK=MLMASK(INPICT,NUMLEVELS)
%       Simple multilevel mask generation tool.  Resultant mask describes
%       the distribution of image content falling into equal-width bins 
%       from black to white.
%
%   INPICT is a single-frame I/RGB image of any standard image class
%   NUMLEVELS is a scalar specifying the number of mask levels to generate
%
%   Output mask is of class 'logical', contains NUMLEVELS frames, and
%   has the same number of channels as INPICT.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/mlmask.html
% See also: immask, findpixels, rangemask, multimask

if size(inpict,4) ~= 1
	error('MLMASK: INPICT must be a single-frame image')
end
inpict = imcast(inpict,'double');
[cc ~] = chancount(inpict);
inpict = inpict(:,:,1:cc);
s = size(inpict);

maskstack = zeros([s(1:2) size(inpict,3) numlevels]);
for f = 1:numlevels
	if f == 1
		maskstack(:,:,:,f) = (inpict <= f/numlevels);
		allmasked = maskstack(:,:,:,f);
	else
		maskstack(:,:,:,f) = (~allmasked & inpict <= f/numlevels);
		allmasked = allmasked | maskstack(:,:,:,f);
	end
end
maskstack = imcast(maskstack,'logical');


















