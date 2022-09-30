function outpict = gcolorize(inpict,hslvec)
%  OUTPICT = GCOLORIZE(INPICT,HSLVEC)
%  Colorize an image in a manner replicating GIMP's 'Colorize' tool.
%  I'm only including this for sake of compatibility with some GIMP scripts.
%
%  INPICT is an I/IA/RGB/RGBA image of any standard image class.
%  HSLVEC is a three-term vector [H S L] specifying the color.
%    H is in the range [0 360]
%    S is in the range [0 100]
%    L is in the range [-100 100]
%
%  Output class is inherited from input.
%
%  See also: imtweak, imblend


% original code generates a luma LUT and then uses that to calculate Y
% it then generates a 1D HSL LUT (constant H and S, full L sweep)
% and then assigns output based on input Y as index into HSL LUT
% obviously i'm not going to do it that way, but this is equivalent.

hue = hslvec(1); % range [0 360]; default 180
saturation = hslvec(2); % range [0 100]; default 50
lightness = hslvec(3); % range [-100 100]; default 0

[inpict alpha] = splitalpha(inpict);
if size(inpict,3) == 1
	inpict = repmat(inpict,[1 1 3]);
end

% libgimp uses rec709 for GIMP_RGB_LUMINANCE_XXX constants
% and rec601 for GIMP_RGB_INTENSITY_XXX constants
Y = imappmat(inpict,gettfm('luma','rec709'),'double');

H = mod(hue,360)*ones(size(Y));
S = (saturation/100)*ones(size(Y));
if lightness > 0
	L = Y*(100-lightness)/100;
	L = L + (1 - (100-lightness)/100);
elseif lightness < 0
	L = Y*(lightness+100)/100;
else
	L = Y;
end

outpict = hsl2rgb(cat(3,H,S,L));
outpict = imcast(outpict,class(inpict));
outpict = joinalpha(outpict,alpha);

end




