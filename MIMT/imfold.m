function inpict = imfold(inpict,varargin)
% IMFOLD(INPICT,{SEQUENCE},{METHOD},{OPTIONS})
%    Generate an image stack as if repeatedly fan-folding an image.
%    Optionally unfold the stack back into a flat image.
%    
%    INPICT is an I/IA/RGB/RGBA image of any standard image class
%    SEQUENCE the intended fold sequence (cell array of strings)
%       The format for a single operation string is [N AXIS DIRECTION]
%         N is the number of folds to perform
%         AXIS along which the image is subdivided 'h' or 'v'
%         DIRECTION of the first fold 'u' or 'o' for under or over
%       EXAMPLE: {'3hu','2vo','1hu'}
%       (default {'1hu','1vu'})
%       Note that a single operation of N folds produces N+1 frames.
%    METHOD specify how image size should be adjusted when tiling
%       since an image dimension cannot be evenly subdivided by all integers
%       'grow' replicates edge vectors to fit
%       'trim' deletes edge vectors to fit 
%       'fit' selects best of either 'grow' or 'trim' behaviors (default)
%       'scale' simply scales the image to fit
%    OPTIONS include the following keys:
%        When using 'scale', the interpolation method can also be selected
%           'bicubic' (default), 'bilinear', or 'nearest' are supported
%        'unfold' will unfold an image (i.e. if INPICT is 4D)
%
%    The folding routine presumes the restriction that the upper left corner
%    of the working image will retain its position during any given fold.
%    This simplifies the notation greatly, though it restricts the available
%    representations of a single fold by a factor of two.  The folded image 
%    returned by IMFOLD is one of a family of folded images related by overall 
%    stack transformations. The fact that frame 1 retains its orientation should
%    reveal what degrees of freedom were discarded.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imfold.html
% See also: imtile, imdetile, maketileable

% the family of valid stacks for a rotationally-constrained 2-D fold sequence:
%	outpict
%	flip(flip(outpict,1),4)
%	flip(flip(outpict,2),4)
%	flip(flip(outpict,1),2) or rotate(outpict,180)

sequence = {'1hu','1vu'};
method = 'fit';
interpolant = 'bicubic';
unfold = false;

for a = 1:nargin-1
	if iscell(varargin{a})
		sequence = varargin{a};
	elseif ischar(varargin{a})
		key = lower(varargin{a});
		if strismember(key,{'fit','scale','grow','trim'})
			method = key;
		elseif strismember(key,{'bicubic','nearest','bilinear'})
			interpolant = key;
		elseif strcmp(key,'unfold')
			unfold = true;
		else
			error('IMFOLD: unknown key %s',key)
		end
	end
end
numops = numel(sequence);

% PARSE OP STRING ====================================================
Tvec = [];
Avec = [];
Dvec = [];
for op = 1:numops
	thisop = sequence{op};
	Tvec = [Tvec str2double(thisop(1:end-2))+1];

	ts = lower(thisop(end-1));
	switch ts
		case 'v'
			Avec = [Avec 1];
		case 'h'
			Avec = [Avec 2];
		otherwise
			error('IMFOLD: unknown axis %s in operation %s',ts,thisop)
	end

	ts = lower(thisop(end));
	if strismember(ts,{'u','o'})
		switch ts
			case 'u'
				Dvec = [Dvec 0];
			case 'o'
				Dvec = [Dvec 1];
		end
	else
		error('IMFOLD: unknown direction %s in operation %s',ts,thisop)
	end
end


% ADJUST DIMENSIONS & DETILE ====================================================
Ntiles = max(1,[prod(Tvec(Avec == 1)) prod(Tvec(Avec == 2))]);
if unfold
	numframes = size(inpict,4);
	if numframes ~= prod(Ntiles)
		error('IMFOLD: fold sequence requires %d frames; INPICT contains %d frames',prod(Ntiles),numframes)
	end
else
	inpict = imdetile(inpict,Ntiles,'fittype',method,'interpolation',interpolant,'direction','row');
	numframes = size(inpict,4);
end


% CALCULATE PERMUTATION & ORIENTATION ====================================================
frameindices = reshape(1:numframes,fliplr(Ntiles))';
flipcount = zeros(size(frameindices));
frameinfo = cat(3,frameindices,flipcount,flipcount);

for op = 1:numops
	dim = Avec(op);
	Nt = Tvec(op);

	% when folding under, first frame group near the origin is kept on top
	% when folding over, frame group order is reversed; flips are the same
	if Dvec(op) == 0
		groupindices = 1:1:Nt; % under
	else
		groupindices = Nt:-1:1; % over
	end
	
	% start building the new stack from the top down
	st = size(frameinfo,dim)/Nt; % a framegroup spans st frames along dimension dim
	lastframeperm = frameinfo; frameinfo = [];
	for framegroup = 1:Nt
		firstpx = 1+(groupindices(framegroup)-1)*st;
		pixrange = firstpx:firstpx+st-1;
		
		if dim == 1
			frameinfo = cat(4,frameinfo,generateperm(lastframeperm(pixrange,:,:,:)));
		else
			frameinfo = cat(4,frameinfo,generateperm(lastframeperm(:,pixrange,:,:)));
		end
	end
	%frameinfo(:,:,1,:)
end
frameperm = squeeze(frameinfo(:,:,1,:));
yflip = find(mod(squeeze(frameinfo(:,:,2,:)),2));
xflip = find(mod(squeeze(frameinfo(:,:,3,:)),2));


% TRANSFORM IMAGE ====================================================
% the order of perm/flip operations are reversed when unfolding
if ~unfold
	inpict = inpict(:,:,:,frameperm);
end

inpict(:,:,:,xflip) = flipd(inpict(:,:,:,xflip),2);
inpict(:,:,:,yflip) = flipd(inpict(:,:,:,yflip),1);

if unfold
	frameperm(frameperm) = 1:numframes; % reverse permutation
	inpict = inpict(:,:,:,frameperm);
	inpict = imtile(inpict,Ntiles,'direction','row');
end


% ====================================================
function out = generateperm(tile)
	if ~mod(groupindices(framegroup),2)
		% increment xflip/yflip counts
		tile(:,:,dim+1,:) = tile(:,:,dim+1,:)+1;
		% flip the entire permuation+flipcount tile
		out = flipd(tile,dim);
		out = flipd(out,4);
	else
		out = tile;
	end
end


end




