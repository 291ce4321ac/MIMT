function outpict = shuffle(inpict,tiles,varargin)
%   SHUFFLE(INPICT, TILES, {OPTIONS})
%       Subdivides the input image into tiles and shuffles
%       them in a random or specified permutation
%
%   INPICT is an I/IA/RGB/RGBA image of any standard image class
%       Multiframe images are supported
%   TILES is a 2-element vector specifying the number of tiles
%       [tilesdown tilesacross]
%   OPTIONS include the following
%       'independent' specifies that the color channels should be permuted
%           independently.  
%       'locked' specifies that all channels should be permuted simultaneously
%           preserving content colocation within each image tile. This is the
%           default behavior. 
%       The permutation can optionally be specified directly with an array.
%           By default, this array is randomly generated internally, but can
%           be specified if repeatability or specific behavior is required.
%           Elements are columnwise-ordered linear indices specifying the 
%           destination of tiles as they are to be moved in a grid of size=TILES.
%           If 'independent' is not set, PERMUTATIONS is a vector of length=
%           prod(TILES).  If 'independent' is set, PERMUTATIONS is of size
%           [size(INPICT,3) prod(TILES)].        
%
%   EXAMPLE:
%       outpict=shuffle(inpict,[30 30],900:-1:1);
%       (flips tile order)
%
%   Output class is inherited from input
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/shuffle.html
% See also: imtile, imdetile, imfold


lockchannels = true;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		if isnumeric(varargin{k})
			perms = varargin{k};
			k = k+1;
		else
			switch lower(varargin{k})
				case 'independent'
					lockchannels = false;
					k = k+1;
				case 'locked'
					lockchannels = true;
					k = k+1;
				otherwise
					error('SHUFFLE: unknown input parameter name %s',varargin{k})
			end
		end
	end
end


numchans = size(inpict,3);
numframes = size(inpict,4);
numtiles = prod(tiles);
if numchans == 1
	% for monochrome images, channel independence is available in locked mode
	lockchannels = true;
end

% if we're given a permutation array, check it
% otherwise generate as many permutations as we need
if exist('perms','var')
	expectedrows = lockchannels+~lockchannels*numchans;
    if any(size(perms) ~= [expectedrows numtiles])
        error('SHUFFLE: permutation array must be of size=[C prod(tiles)]\nwhere C is either 1 or size(inpict,3) depending on selected options\nExpected size: %s\nSpecified size: %s',mat2str([expectedrows numtiles]),mat2str(size(perms)))
    end
else
	if lockchannels
		perms = randperm(numtiles);
	else
		perms = [];
		for c = 1:numchans
			perms = cat(1,perms,randperm(numtiles));
		end
	end
end

% temporarily resize to closest multiple
s = size(inpict);
if numframes ~= 1
    inpict = fourdee(@maketileable,inpict,tiles,'scale');
else
    inpict = maketileable(inpict,tiles,'scale');
end

outpict = imzeros(size(inpict),class(inpict));
for f = 1:numframes
	thisframe = imdetile(inpict(:,:,:,f),tiles,'direction','col');
	if lockchannels
		thisframe = thisframe(:,:,:,perms);
	else
		for c = 1:numchans
			thisframe(:,:,c,:) = thisframe(:,:,c,perms(c,:));
		end
	end
	outpict(:,:,:,f) = imtile(thisframe,tiles,'direction','col');
end

% resize back to original dimensions
outpict = imresizeFB(outpict,s(1:2));

return




