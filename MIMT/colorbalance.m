function outpict = colorbalance(inpict,K,preserve)
%  OUTPICT = COLORBALANCE(INPICT,K,{PRESERVE})
%  Shift the color balance of an image.  This is based on the legacy GIMP tools.
%
%  INPICT is an RGB/RGBA image of any standard image class.
%    Multiframe images are supported.
%  K is the parameter array.  This is a 3x3 matrix in the range [-1 1].
%    Each column corresponds to the image channels [R G B]
%    Each row corresponds to the ranges [shadows; midtones; highlights]
%  PRESERVE key optionally specifies output behavior (default 'preserve')
%    'preserve' adjusts the output to preserve the original lightness.
%    'nopreserve' returns the output as-is without any correction.  
%
%  Output class is inherited from input
%
%  See also: imtweak, imlnc, imcurves, imbcg, imadjustFB

if nargin == 1 
	error('COLORBALANCE: not enough arguments')
elseif nargin == 2
	preserve = true;
else
	switch lower(preserve)
		case 'preserve'
			preserve = true;
		case 'nopreserve'
			preserve = false;
		otherwise
			error('COLORBALANCE: unknown value for PRESERVE key')
	end
end

[inpict alpha] = splitalpha(inpict);
if size(inpict,3) ~= 3
	error('COLORBALANCE: expected image to be RGB or RGBA')
end

K = imclamp(K,[-1 1]);

[inpict inclass] = imcast(inpict,'double');
outpict = zeros(size(inpict));
for c = 1:3
	outpict(:,:,c,:) = remapchannel(inpict(:,:,c,:),K(1,c),K(2,c),K(3,c));
end

if preserve
	L = mono(inpict,'l');
	for f = 1:size(L,4)
		outhsl = rgb2hsl(outpict(:,:,:,f));
		outhsl(:,:,3) = L(:,:,:,f);
		outpict(:,:,:,f) = hsl2rgb(outhsl);
	end
end

outpict = imcast(outpict,inclass);
outpict = joinalpha(outpict,alpha);

end % END MAIN SCOPE



% based on
% app/base/color-balance.c and app/gegl/gimpoperationcolorbalance.c
function CH = remapchannel(CH,Ks,Km,Kh)
	a = 0.25;
	b = 0.333;
	scale = 0.7;

	Ks = Ks * imclamp((CH - b)/(-a) + 0.5)*scale;
	Km = Km * imclamp((CH - b)/a + 0.5) .* imclamp((CH + b - 1)/(-a) + 0.5)*scale;
	Kh = Kh * imclamp((CH + b - 1)/a + 0.5)*scale;

	CH = imclamp(CH + Ks + Km + Kh);
end


