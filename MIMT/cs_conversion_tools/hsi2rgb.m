function outpict = hsi2rgb(inpict)
%   HSI2RGB(INPICT)
%       undoes an HSI conversion from (RGB2HSI)
%
%   INPICT is an image of class double wherein
%       H: [0 360)
%       S: [0 1]
%       L: [0 1]
%   
%   Return type is double, scaled [0 1]
%
% See also: rgb2hsv, rgb2hsl, rgb2hsi, rgb2hwb

% keep in mind that not all color points in the cylinder 
% specified by the extents listed above are still in the sRGB cube
% keep in mind that HSI is not a biconic model
% the isosurfaces of S (cone) and I (plane) intersect beyond the cube
% for large S and I

H = inpict(:,:,1);
S = inpict(:,:,2);
I = inpict(:,:,3);

H = H-360*floor(H/360);
	
% sector masks
a = H < 120;
b = H < 240 & ~a;
c = ~a & ~b;

R = zeros(size(H));
G = zeros(size(H));
B = zeros(size(H));

B(a) = I(a).*(1-S(a));
R(a) = I(a).*(1+S(a).*cos(H(a).*(pi/180))./cos((60-H(a))*(pi/180)));
G(a) = 3*I(a)-R(a)-B(a);

H(b) = H(b)-120;
R(b) = I(b).*(1-S(b));
G(b) = I(b).*(1+S(b).*cos(H(b).*(pi/180))./cos((60-H(b))*(pi/180)));
B(b) = 3*I(b)-R(b)-G(b);

H(c) = H(c)-240;
G(c) = I(c).*(1-S(c));
B(c) = I(c).*(1+S(c).*cos(H(c).*(pi/180))./cos((60-H(c))*(pi/180)));
R(c) = 3*I(c)-G(c)-B(c);

outpict = cat(3,R,G,B);

return
