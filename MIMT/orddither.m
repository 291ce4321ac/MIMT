function out = orddither(img,ksize,cmode)
%   ORDDITHER(INPICT, {KSIZE}, {COLORMODE})
%     multilevel ordered dither inspired by Cris Luengo's blog posts
%     http://www.crisluengo.net/index.php/archives/355
%     and by work from others
%
%   INPICT is a 2-D intensity image
%   KSIZE is the size of the Bayer coefficient matrix (default 16)
%     The number of reproducible gray levels is KSIZE^2
%     KSIZE will be rounded up to the nearest power of 2.
%   COLORMODE specifies what should happen if fed an RGB image
%     'mono' reduces the input by extracting its luma (default)
%     'color' returns a MxNx3 dithered image. This is a crude
%        8-level RGB image, and is not to be confused with a properly 
%        reduced palette RGB or indexed image with dithering
%
%   Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/orddither.html
% See also: dither, noisedither, zfdither, arborddither, linedither

% define defaults
if ~exist('ksize','var')
	ksize = 16;
end

if ~exist('cmode','var')
	cmode = 'mono';
end

% convert to unit-scale double
img = imcast(img,'double');
sz = size(img);
numchans = size(img,3);

% if image is RGB, reduce to grayscale unless color mode is specified explicitly
if numchans == 3
	sz = sz(1:2);
	if strcmpi(cmode,'mono')
		img = mono(img,'y');
		numchans = 1;
	end
end

% generate the Bayer coefficient matrix
ksize = 2^ceil(log2(ksize)); % round up to the nearest power of 2
A = [0 2; 3 1]; % the core pattern
B = A; % this assignment is only used when ksize <= 2

% iteratively build the coefficient matrix
while(size(A,1) < ksize)
	B = zeros(size(A,1)*2, size(A,2)*2);
	
	delta = length(A(:));
	for l = 0:delta-1
		[m,n] = find(A == l);
		B(2*m-1:2*m,2*n-1:2*n) = [0 2; 3 1]*delta+l;
	end
	A = B;
end
B = B/ksize^2; % normalize the coefficient matrix

% create mask by tiling the coefficient matrix 
% so that it covers the same area as the image
n = size(B);
t = repmat(B,ceil(sz./n));
t = t(1:sz(1),1:sz(2));

% binarize image by comparing gray levels to tiled mask
out = false([sz numchans]);
for c = 1:numchans
	out(:,:,c) = (img(:,:,c) > t);
end

end

