function lch = lab2lch(lab)
%  LCH = LAB2LCH(LAB)
%	 Perform a simple rectangular-polar conversion on color data.
%
%  LAB is a 3-channel image formatted with its lightness component first
%    and with its chrominance information centered around zero.
%    This does not have to be CIELAB.  It can be LUV or YPbPr, etc.
%
%  Output LCH is of the same scale as LAB, with H in degrees.
%
% See also: lch2lab, rgb2lch, lch2rgb

[L A B] = splitchans(lab);
C = sqrt(A.^2 + B.^2);
Hrad = mod(atan2(B,A),2*pi);
H = Hrad*180/pi; % atan2d() is a version-dependency

lch = cat(3,L,C,H);


