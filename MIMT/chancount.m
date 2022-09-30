function [ncchans nachans] = chancount(inpict)
%   COUNTVECTOR = CHANCOUNT(INPICT)
%   [NUM_COLOR_CHANS NUM_ALPHA_CHANS] = CHANCOUNT(INPICT)
%     simple convenience tool for fetching info about an image
%     assumes I/IA/RGB/RGBA/RGBAAA channel arrangements
%     assumes image dimensioning is [height width channels frames]
%       
%   INPICT an image array of any class
%
%   if only one output argument is specified, the output will be a 2-element vector
%
%  See also: framecount, imsize

numchans = size(inpict,3);
if ~ismember(numchans,[1 2 3 4 6])
	error('CHANCOUNT: expected image to be I/IA/RGB/RGBA/RGBAAA. What is this %d-channel image supposed to be?',numchans)
end
hasalpha = 1-mod(numchans,2);
ncchans = min(numchans-hasalpha,3);
nachans = numchans-ncchans;

if nargout < 2
  ncchans = [ncchans nachans];
end

end





