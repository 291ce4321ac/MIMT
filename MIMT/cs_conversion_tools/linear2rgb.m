function out = linear2rgb(inpict)
%   OUTPICT=LINEAR2RGB(INPICT)
%   Convert linear RGB to gamma-corrected sRGB
%
%   INPICT is an RGB image of a floating point class.
%   Output class is inherited from INPICT
%
%  See also: lin2rgb, rgb2linear

	mk = (inpict <= 0.0031306684425005883);
	out = 12.92*inpict.*mk + (real(1.055*inpict.^0.416666666666666667)-0.055).*(1-mk);
end
