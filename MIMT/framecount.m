function nf = framecount(inpict)
%  NUMFRAMES = FRAMECOUNT(INPICT)
%    Simple tool to get the number of frames from a 4D multiframe image.
%    Assumes image dimensioning is [height width channels frames]
%    The only reason this exists is to make the code descriptive.
%
%  INPICT is an image array of any class
%
%  See also: chancount

% yeah that's all it is
nf = size(inpict,4);