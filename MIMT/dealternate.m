function varargout = dealternate(inpict,dim,varargin)
%   [A B C ... ]=DEALTERNATE(INPICT,DIM,{WIDTH})
%   Disassemble an image created by interleaving two or more images using
%   alternate(). 
%
%   INPICT is an image or array of any class
%   DIM specifies the dimension along which the array is to be divided
%   WIDTH specifies the stripe width (default 10)
%      This may be a scalar (with implicit expansion) or a vector specifying
%      the width of stripe applied to each input image.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/dealternate.html
% See also: alternate, interleave, deinterleave, eoline

width = 10;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			width = thisarg(1);
		else
			error('DEALTERNATE: unrecognized option')
		end
	end
end

N = nargout;
width = max(round(width),1);
if numel(width) == 1 && N > 1
	width = repmat(width,[1 N]);
elseif numel(width) ~= N
	error('DEALTERNATE: WIDTH must either be scalar or its length must match the number of input images')
end

dim = round(dim(1));

if dim > ndims(inpict)
	error('DEINTERLEAVE: image has fewer dimensions than that requested by DIM')
end

% build subs list
idx = repmat({':'},[1 ndims(inpict)]);

s0 = size(inpict);
os = [0 cumsum(width)];
varargout = cell(N);
x = 1:s0(dim);
for g = 1:N
	idx{dim} = mod((x'-1-os(g))/sum(width),1) < (width(g)/sum(width)-(1E-6));
	varargout{g} = inpict(idx{:});
end


