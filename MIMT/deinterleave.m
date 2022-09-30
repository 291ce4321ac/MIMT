function varargout = deinterleave(inpict,dim,varargin)
%   [A B C ... ]=DEINTERLEAVE(INPICT,DIM,{WIDTH})
%   Disassemble an image created by interleaving two or more images.
%
%   INPICT is an image or array of any class
%      May have up to 4 dimensions, but size along DIM must be divisible by 
%      the number of images specified in the output argument list.
%   DIM specifies the dimension along which the array is to be divided
%   WIDTH specifies the stripe width (default 10)
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/deinterleave.html
% See also: interleave, alternate, dealternate, eoline

width = 10;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			width = thisarg(1);
		else
			error('DEINTERLEAVE: unrecognized option')
		end
	end
end

width = max(round(width(1)),1);

dim = round(dim(1));
% if ~any(dim==[1 2 3 4])
% 	error('DEINTERLEAVE: only dims 1-4 are supported')
% end

if dim > ndims(inpict)
	error('DEINTERLEAVE: image has fewer dimensions than that requested by DIM')
end

N = nargout;
s0 = size(inpict);
if mod(s0(dim),N) ~= 0
	error('DEINTERLEAVE: input image needs to be divisible by the number of specified outputs along DIM')
end

% build subs list
idx = repmat({':'},[1 ndims(inpict)]);

varargout = cell(N);
x = 1:s0(dim);
for g = 1:N
	idx{dim} = mod((x-1-(g-1)*width)/N,width) < (width/N-(1E-6));
	varargout{g} = inpict(idx{:});
end


