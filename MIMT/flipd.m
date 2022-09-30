function out = flipd(varargin)
%  OUT=FLIPD(A,{DIM})
%   Flip an array.  This is a wrapper for flip() and flipdim() to provide a consistent 
%   syntax across versions with the speed benefit of flip() where it's available. 
% 
%   flip() is ~2-3x as fast as flipdim() for large arrays, but it's only available
%   post-R2013b.  Furthermore, flip() supports implicit dimension selection, but 
%   flipdim() does not.  flipd() allows the use of a single function without concern
%   for which features will be available.
%
%   A is an array
%   DIM specifies the dimension to flip along.  If unspecified, DIM is selected
%   as follows.  If A is a vector, it is flipped along its length.  If A is a 2D
%   array, it is flipped columnwise.  If A is ND, it is flipped along its first
%   non-singleton dimension. 
% 
%   Output class is inherited from A
%
% See also: flip, flipdim

% flip is 3x faster than flipdim for large 4D stacks, but it's new (R2013b)
% 10-15ms for version checking with verLessThan() makes this insignificant for small arrays
% but ifversion() is much faster

persistent isold
if isempty(isold)
	isold = ifversion('<','R2013b');
end

if isold
	if numel(varargin) == 1
		A = varargin{1};
		if isrow(A)
			dim = 2;
		elseif ndims == 2
			% if column vector or 2D array
			dim = 1;
		else
			% if ND array
			dim = find(size(A) > 1,1);
		end
		out = flipdim(A,dim); %#ok<*DFLIPDIM>
	else
		out = flipdim(varargin{:});
	end
else
	out = flip(varargin{:});
end

% ifversion() is fast enough to be beneficial even with smaller arrays
% syntax varies slightly between flip and flipdim
% flipdim requires dim; flip has defaults









