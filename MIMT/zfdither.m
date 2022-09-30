function out = zfdither(img)
%   ZFDITHER(INPICT)
%       Apply Zhou-Fang VC dither to an I/RGB image
%
%       The ZF algorithm is a modern variable-coefficient
%       error-diffusion dither based on the Ostromoukhov algo.
%       https://www.cs.unc.edu/~xffang/paper/siggraph03.pdf
%       Zhou-Fang dither implementation by Cris Luengo
%       http://www.crisluengo.net/index.php/archives/355
%
%   INPICT is a 2-D intensity image
%       if fed an RGB image, its luma channel will be extracted
%
%   Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/zfdither.html
% See also: dither, noisedither, orddither, arborddither, linedither

% thresholding and weights are expecting 0-255 range
% image height, width must be even

% if image is RGB, reduce to grayscale (luma)
if size(img,3) == 3
	img = mono(img,'y');
end

% convert to uint8-scale (0-255) floating point
% this is used simply because that's what the given coefficients are scaled to
img = double(imcast(img,'uint8'));

% image height,width need to be even; if not, pad them
padsize = mod(size(img),2);
if padsize(1); img = cat(1,img,img(end,:)); end
if padsize(2); img = cat(2,img,img(:,end)); end	

sz = size(img);

% for compactness, this is a short lookup table
% [ index, right, left-down, down ]
coef = [ 
  0,      13,      0,      5
  1, 1300249,      0, 499250
  2,  214114,    287,  99357
  3,  351854,      0, 199965
  4,  801100,      0, 490999
 10,  704075, 297466, 303694
 22,   46613,  31917,  21469
 32,   47482,  30617,  21900
 44,   43024,  42131,  14826
 64,   36411,  43219,  20369
 72,   38477,  53843,   7678
 77,   40503,  51547,   7948
 85,   35865,  34108,  30026
 95,   34117,  36899,  28983
102,   35464,  35049,  29485
107,   16477,  18810,  14712
112,   33360,  37954,  28685
127,   35269,  36066,  28664];

% expand the lookup table to cover the entire range of uint8
x = coef(:,1); % this is half the abcissa (indices 0-127)
y = coef(:,2:4); % these are the associated coefficients for each direction
y = bsxfun(@rdivide,y,sum(y,2)); % normalize coefficients
% interpolate 18-row LUT to 128-row LUT
coef = [interp1(x,y(:,1),0:127)',interp1(x,y(:,2),0:127)',interp1(x,y(:,3),0:127)'];
coef = [coef;flipud(coef)]; % make 128-row LUT into 256-row symmetric LUT

% for compactness, this is a short lookup table
strg = [
0,   0.00
44,  0.34
64,  0.50
85,  1.00
95,  0.17
102, 0.50
107, 0.70
112, 0.79
127, 1.00];
% interpolate 9-row LUT to 128-row LUT
strg = interp1(strg(:,1),strg(:,2),0:127)';
strg = [strg;flipud(strg)]; % make 128-row LUT into 256-row symmetric LUT

out = img;
% because of these loops incrementing by 2, image height and width must be even
for ii = 1:2:sz(1)
	for jj = 1:sz(2)
		old = out(ii,jj);
		new = 255*(old >= 128+(rand*128)*strg(img(ii,jj)+1));
		out(ii,jj) = new;
		err = new-old;
		weights = coef(img(ii,jj)+1,:); % +1 to account for MATLAB indexing into table
		
		if jj < sz(2)
			% right
			out(ii  ,jj+1) = out(ii  ,jj+1)-err*weights(1);
		end
		
		if ii < sz(1)
			% down
			out(ii+1,jj  ) = out(ii+1,jj  )-err*weights(3);
			if jj > 1
				% left-down
				out(ii+1,jj-1) = out(ii+1,jj-1)-err*weights(2);
			end
		end
	end
	
	ii = ii+1; % even rows go right to left
	for jj = sz(2):-1:1
		old = out(ii,jj);
		new = 255*(old >= 128+(rand*128)*strg(img(ii,jj)+1));
		out(ii,jj) = new;
		err = new-old;
		weights = coef(img(ii,jj)+1,:); % +1 to account for MATLAB indexing into table
	  
		if jj > 1
			% right
			out(ii  ,jj-1) = out(ii  ,jj-1)-err*weights(1);
		end
		 
		if ii < sz(1)
			% down
			out(ii+1,jj  ) = out(ii+1,jj  )-err*weights(3);
			if jj < sz(2)
				% left-down
				out(ii+1,jj+1) = out(ii+1,jj+1)-err*weights(2);
			end
		end
	end
end

% remove any padding that was added
out = logical(out(1:(end-padsize(1)),1:(end-padsize(2))));

end

