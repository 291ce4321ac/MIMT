function outpict = rgb2hwb(inpict)
%   RGB2HWB(INPICT)
%     Convert an RGB image to HWB (Hue, Whiteness, Blackness)
%     This is a variant of HSV proposed by Alvy Ray Smith (1996)
%     http://alvyray.com/Papers/CG/HWB_JGTv208.pdf
%
%   INPICT is an RGB image of any standard image class
%   
%   Return type is double, scaled as such:
%     H: [0 360)
%     W: [0 1]
%     B: [0 1]
%
% See also: hwb2rgb, rgb2hsv, rgb2hsl, rgb2hsi

[H S V] = splitchans(rgb2hsv(inpict));
W = (1-S).*V;
B = 1-V;
outpict = cat(3,H*360,W,B);

