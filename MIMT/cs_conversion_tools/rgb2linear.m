function out = rgb2linear(inpict)
%   OUTPICT=RGB2LINEAR(INPICT)
%   Convert gamma-corrected sRGB to linear RGB
%
%   INPICT is an RGB image of a floating point class.
%   Output class is inherited from INPICT
%
%  See also: rgb2lin, linear2rgb

	% for phi=64616051/5E6=12.9232102, K0=0.0392857, half-functions are slope and value-continuous at intersection (tangent)
	% for phi=12.92, K0=0.0404483, half-functions are only value-continuous (but this is per sRGB standard)
    mk = double(inpict <= 0.0404482362771076);
	out = inpict/12.92.*mk + real(((inpict+0.055)/1.055).^2.4).*(1-mk);
end

