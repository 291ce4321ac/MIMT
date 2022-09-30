function outpict = hsl2rgb(inpict)
%   HSL2RGB(INPICT)
%       undoes an HSL conversion from (RGB2HSL)
%
%   INPICT is an image of class double wherein
%       H: [0 360)
%       S: [0 1]
%       L: [0 1]
%   
%   Return type is double, scaled [0 1]
%
% See also: rgb2hsv, rgb2hsl, rgb2hsi, rgb2hwb

% This is basically the same as Colorspace by Pascal Getreuer
% I only created these two files (rgb2hsl.m and hsl2rgb.m)
% to avoid the remaining dependency being a hassle for users

H = inpict(:,:,1);
S = inpict(:,:,2);
L = inpict(:,:,3);

s = size(L);
sl = prod(s);

D = S.*min(L,1-L);
Ld = L-D;
Lu = L+D;

H = H(:);
Ld = Ld(:);
Lu = Lu(:);

H = min(max(H(:),0),360)/60; %mod(H,360)/60;
F = H-round(H/2)*2;
M = cat(2, Ld, Ld+abs(F).*(Lu-Ld), Lu);
k = floor(H)+1;
j = [2 1 0; 1 2 0; 0 2 1; 0 1 2; 1 0 2; 2 0 1; 2 1 0]*sl;
outpict = reshape([M(j(k,1)+(1:sl).'), M(j(k,2)+(1:sl).'), M(j(k,3)+(1:sl).')],[s,3]);

end

