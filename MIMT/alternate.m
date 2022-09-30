function outpict = alternate(dim,A,B,varargin)
%   OUTPICT=ALTERNATE(DIM,A,B,{C},{D},...,{WIDTH})
%   Combine multiple images by interleaving them along a given dimension,
%   alternating in the given order. Compared to interleave(), this tool
%   produces an image equal in size to the inputs.  Because of this, stripes
%   of data are skipped, and disassembling the combined image cannot recover
%   the complete source images.
%
%   A, B, C, etc are images or arrays of any class
%      Arrays must have the same size.
%   DIM specifies the dimension along which the arrays are to be combined
%   WIDTH specifies the stripe width (default 10)
%      This may be a scalar (with implicit expansion) or a vector specifying
%      the width of stripe applied to each input image.
%
%  Output class is inherited from image A
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/alternate.html
% See also: dealternate, interleave, deinterleave, eoline

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
			error('ALTERNATE: unrecognized option')
		end
	end
end

N = numel(imagepile);
width = max(round(width),1);
if numel(width) == 1 && N > 1
	width = repmat(width,[1 N]);
elseif numel(width) ~= N
	error('ALTERNATE: WIDTH must either be scalar or its length must match the number of input images')
end

dim = round(dim(1));

if dim > ndims(imagepile{1})
	error('ALTERNATE: images have fewer dimensions than that requested by DIM')
end

sa = imsize(imagepile{1},ndims(imagepile{1}));
inclass = class(imagepile{1});
for g = 1:N
	sb = imsize(imagepile{g},ndims(imagepile{1}));
	if any(sa ~= sb)
		error('ALTERNATE: input images need to be the same size')
	end
	imagepile{g} = imcast(imagepile{g},inclass);
end

outpict = zeros(sa,inclass);

% build subs list
idx = repmat({':'},[1 numel(sa)]);


os = [0 cumsum(width)];
x = 1:sa(dim);
for g = 1:N
	idx{dim} = mod((x'-1-os(g))/sum(width),1) < (width(g)/sum(width)-(1E-6));
	outpict(idx{:}) = imagepile{g}(idx{:});
end


