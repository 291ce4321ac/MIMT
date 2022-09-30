function outpict = interleave(dim,A,B,varargin)
%   OUTPICT=INTERLEAVE(DIM,A,B,{C},{D},...,{WIDTH})
%   Combine multiple images by interleaving them along a given dimension,
%   alternating in the given order. The resulting image dimension is multiplied
%   by the number of images being combined.
%
%   A, B, C, etc are images or arrays of any class
%      Arrays must have the same size.
%   DIM specifies the dimension along which the arrays are to be combined
%   WIDTH specifies the stripe width (default 10)
%
%  Output class is inherited from image A
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/interleave.html
% See also: deinterleave, alternate, dealternate, eoline

width = 10;

imagepile = {A,B};
clear A B

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			if numel(thisarg) == 1
				width = thisarg(1);
			else
				imagepile = [imagepile thisarg];
			end
		else
			error('INTERLEAVE: unrecognized option')
		end
	end
end

width = max(round(width(1)),1);

dim = round(dim(1));

if dim > ndims(imagepile{1})
	error('INTERLEAVE: images have fewer dimensions than that requested by DIM')
end

N = numel(imagepile);
sa = imsize(imagepile{1},ndims(imagepile{1}));
inclass = class(imagepile{1});
for g = 1:N
	sb = imsize(imagepile{g},ndims(imagepile{1}));
	if any(sa ~= sb)
		error('INTERLEAVE: input images need to be the same size')
	end
	imagepile{g} = imcast(imagepile{g},inclass);
end

sout = sa;
sout(dim) = sout(dim)*N;
outpict = zeros(sout,inclass);

% build subs list
idx = repmat({':'},[1 ndims(imagepile{1})]);

x = 1:sout(dim);
for g = 1:N
	idx{dim} = mod((x-1-(g-1)*width)/N,width) < (width/N-(1E-6));
	outpict(idx{:}) = imagepile{g};
end


