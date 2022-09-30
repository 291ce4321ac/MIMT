function outpict = imgeofilt(inpict,fk)
%  OUTPICT = IMGEOFILT(INPICT,FK)
%    Apply a local geometric mean filter to an image.  
%
%  INPICT is an image of any standard image class. 
%    Multichannel and multiframe images are supported.
%  FK is a standard sum-normalized 2D filter kernel
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imgeofilt.html
% See also: imfilterFB, nhfilter, medfilt2, stdfilt, rangefilt

[inpict inclass] = imcast(inpict,'double');

inpict = inpict + eps; % avoid getting values stuck at -Inf
outpict = exp(imfilterFB(log(inpict),fk,'replicate'));

outpict = imcast(outpict,inclass);