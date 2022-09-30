function out = arborddither(img,kfactor,cmode,indexarray)
%   ARBORDDITHER(INPICT, {KFACTOR}, {COLORMODE}, {INDEX})
%       Multilevel ordered dither with support for arbitrary index arrays
%       Available presets offer a range of simple dither patterns
%       As the purpose of this function is image degradation, preset
%       options are selected for their strong tendency to create artifacts.
%
%   INPICT is a 2-D intensity image or an RGB image
%   KFACTOR determines how the index array should be scaled (default 1)
%        the number of reproducible gray levels is numel(INDEX)^KFACTOR
%        assuming INDEX has no duplicate values
%   COLORMODE specifies what should happen if fed an RGB image
%        'mono' reduces the input by extracting its luma (default)
%        'color' returns a MxNx3 dithered image. This is a crude
%            8-level RGB image, and is not to be confused with a properly 
%            reduced palette RGB or indexed image with dithering
%   INDEX is the index matrix.  This can be numeric or selected from presets.
%        'h' is a 1x8 horizontal ramp
%        'hi' is an interleaved version of 'h'
%        'hzz' is a 4x4 horizontal zig-zag pattern
%        'hzzi' is an interleaved version of 'hzz' (default)
%        'dzz' is a 4x4 diagonal zig-zag pattern
%        'dzzi' is an interleaved version of 'dzz'
%        'cws' is a 4x4 clockwise inward spiral pattern
%
%        all of the above presets can be transformed with a suffix:
%        '-flr', '-fud' are horizontal and vertical flips
%        '-tp' performs a transpose
%        
%        appending an extra '-' to the end of the preset string will invert it
%
%   EXAMPLE: 
%        256-level monochrome dither using the flipped diagonal preset
%            ditherpict = arborddither(inpict,2,'mono','dzzi-flr');
%        64-level mono dither using an inverted vertical stripe preset
%            ditherpict = arborddither(inpict,2,'mono','h-tp-');
%
%   CLASS SUPPORT:
%       inputs may be 'uint8','uint16','int16','single','double', or 'logical'
%       output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/arborddither.html
% See also: dither, noisedither, orddither, zfdither, linedither



if ~exist('kfactor','var')
	kfactor = 1;
end

if ~exist('cmode','var')
	cmode = 'mono';
end

if ~exist('indexarray','var')
	indexarray = 'hzzi';
end

img = imcast(img,'double');
sz = size(img);
numchans = size(img,3);

if numchans == 3
	sz = sz(1:2);
	if strcmpi(cmode,'mono')
		img = mono(img,'y');
		numchans = 1;
	end
end

if isnumeric(indexarray)
	A0 = indexarray;
else
	[ia tfm] = strtok(lower(indexarray),'-');

	switch ia
		case 'hzz'
			A0 = [0 1 2 3; 7 6 5 4; 8 9 10 11; 15 14 13 12];	% horizontal zig-zag
		case 'hzzi'
			A0 = [0 1 2 3; 8 9 10 11; 7 6 5 4; 15 14 13 12];	% interleaved horizontal zig-zag
		case 'dzz'
			A0 = [0 1 3 6; 2 4 7 10; 5 8 11 13; 9 12 14 15];	% diagonal zig-zag
		case 'dzzi'
			A0 = [0 6 1 8; 7 2 9 12; 3 10 13 4; 11 14 5 15];	% interleaved diagonal zig-zag	
		case 'cws'
			A0 = [0 1 2 3; 11 12 13 4; 10 15 14 5; 9 8 7 6];	% cw spiral
		case 'h'
			A0 = [0 1 2 3 4 5 6 7];
		case 'hi'
			A0 = [0 4 1 5 2 6 3 7];	
	end
		
	
	if numel(tfm) > 1
		switch tfm(tfm ~= '-');
			case 'flr'
				A0 = fliplr(A0);
			case 'fud'
				A0 = fliplr(A0);
			case 'tp'
				A0 = A0';
		end
	end	
		
	if numel(tfm) >= 1	
		if tfm(end) == '-'
			A0 = max(max(A0))-A0;
		end
	end
end

A = A0;
asize = size(A0);

if kfactor == 1
	B = A;
else
	% i don't think this condition is appropriate
	while(max(size(A)) < (max(asize)^kfactor))
		B = zeros(size(A).*((size(A) > 1)+1));

		delta = length(A(:));
		for l = 0:delta-1
			[m,n] = find(A == l);
			B(asize(1)*m-asize(1)+1:asize(1)*m, ...
			  asize(2)*n-asize(2)+1:asize(2)*n) = A0*delta+l;
		end
		A = B;
	end
end

B = B/(max(max(B))+1);

n = size(B);
t = repmat(B,ceil(sz./n));
t = t(1:sz(1),1:sz(2));

out = false([sz numchans]);
for c = 1:numchans
	out(:,:,c) = (img(:,:,c) > t);
end

end

