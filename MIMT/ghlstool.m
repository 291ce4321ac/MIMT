function outpict = ghlstool(inpict,hls)
%  OUTPICT = GHLSTOOL(INPICT,HLS)
%  Adjust hue, lightness, saturation as in the GIMP Hue-Saturation tool.
%  This just exists strictly for replicating the GIMP tool behavior.
% 
%  INPICT is an RGB/RGBA image of any standard image class
%  HLS is a 3-element vector of the form [H L S]
%    H is in the range [-180 180] 
%    L is in the range [-100 100]
%    S is in the range [-100 100]
%    Null input is [0 0 0]
%
%  Output class is inherited from input.
%
%  See also: imtweak, imlnc, imbcg, imcurves

H = hls(1);
S = hls(3)/100 + 1;
kL = 1-abs(hls(2))/200;
bL = (1-kL)*(hls(2)>0);

[inpict alpha] = splitalpha(inpict);

if size(inpict,3) ~= 3
	error('GHLSTOOL: expected input to be a color image (RGB/RGBA/RGBAAA)')
end

hslpict = rgb2hsl(inpict);
hslpict(:,:,1) = mod(hslpict(:,:,1) + H,360);
hslpict(:,:,2) = imclamp(((S < 0) + sign(S)*hslpict(:,:,2))*abs(S));
hslpict(:,:,3) = imclamp(kL*hslpict(:,:,3) + bL);
outpict = hsl2rgb(hslpict);

outpict = imcast(outpict,class(inpict));
outpict = joinalpha(outpict,alpha);

