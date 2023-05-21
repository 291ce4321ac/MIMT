function outpict = gray2pcolor(varargin)
%  OUTPICT = GRAY2PCOLOR(INPICT,CT,{INRANGE},{MODE})
%  Convert a grayscale image to a pseudocolored RGB image by uniform 
%  quantization and colormapping.  This is comparable to displaying 
%  an image with imagesc(), except the output is an RGB image.
%  
%  INPICT is a grayscale image of any standard image class.  If given an RGB
%    image, it will be reduced to its luma.  Multiframe images are not supported.
%  CT is a Mx3 color table in unit-scale floating point.  
%  INRANGE optionally specifies the input range used during normalization
%    When unspecified, the image is normalized with respect to its extrema.
%  MODE optionally specifies how the data is quantized.  See uniquant() for more info.
%    'default' The behavior matches that of gray2ind(), where the end bins are 
%       centered on the input limits, effectively making them half-width for 
%       default INRANGE.
%    'cdscale' The behavior is similar to imagesc() or image() with CDataScaling 
%       set to 'scaled'.  In this case, all bins are equal-width.
%    'fsdither' Uses a Floyd-Steinberg dithering as would rgb2ind(). 
%    'zfdither' Uses a Zhou-Fang variable-coefficient error-diffusion dither. 
%    'orddither' Uses a Bayer ordered/patterned dither. 
%
%  Output class is 'double'
% 
%  See also: gray2rgb, uniquant, gray2ind, ind2rgb

inpict = varargin{1};
switch size(inpict,3)
	case 1
		% NOP
	case 3
		varargin{1} = mono(inpict,'y');
	otherwise
		error('GRAY2PCOLOR: INPICT must be I/RGB')
end

CT = varargin{2};
nlevels = size(CT,1);
if nlevels>65536
	error('GRAY2PCOLOR: Maximum map length is 65536')
end
varargin{2} = nlevels;

outpict = uniquant(varargin{:}); % uniform quant to map length
outpict = ind2rgb(outpict,CT); % apply colormap

end
