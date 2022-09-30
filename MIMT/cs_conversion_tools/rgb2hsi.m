function outpict = rgb2hsi(inpict)
%   RGB2HSI(INPICT)
%       performs an HSI conversion on an rgb image
%
%   INPICT is an rgb image of class uint8 or double
%   
%   Return type is double, scaled as such:
%       H: [0 360)
%       S: [0 1]
%       L: [0 1]
%
% See also: hsi2rgb, rgb2hsv, rgb2hsl, rgb2hsi, rgb2hwb

inpict = imcast(inpict,'double');

R = inpict(:,:,1);
G = inpict(:,:,2);
B = inpict(:,:,3);

a = 0.5*(2*R-G-B);
b = sqrt(3)/2*(G-B)+eps;
	
H = zeros(size(R));
S = zeros(size(R));
I = (R+G+B)/3;

mn = min(inpict,[],3);
nz = I ~= 0;

S(nz) = 1-mn(nz)./I(nz);
S(~nz) = 0;

H(nz) = atan2(b(nz),a(nz))*(180/pi);
H(H < 0) = H(H < 0)+360;
H(~nz) = 0;

outpict = cat(3,H,S,I);

return
