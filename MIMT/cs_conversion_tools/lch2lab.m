function lab = lch2lab(lch)
%  LAB = LCH2LAB(LCH)
%	 Perform a simple polar-rectangular conversion on color data.
%
%  LCH is a 3-channel image formatted with its lightness component first
%    and with its hue channel in degrees.
%
%  Output LAB is of the same scale as LCH.  The output does not have to 
%    be CIELAB.  It will be the rectangular expression of whatever the 
%    input was (e.g. LCHab -> LAB or LCHuv -> LUV).
%
% See also: lab2lch, rgb2lch, lch2rgb

[L C H] = splitchans(lch);
A = C.*cosd(H);
B = C.*sind(H);

lab = cat(3,L,A,B);


