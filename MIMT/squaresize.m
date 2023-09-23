function f = squaresize(x0,varargin)
%  GEOMETRY = SQUARESIZE(N,{OPTIONS})
%  Given a vector length N, find a 2D geometry which will allow 
%  the vector to be reshaped into an approximately-square 2D array,
%  provided it is allowed for the vector length to be trimmed/padded.
%  
%  This can be convenient if you want to reshape a vector of spatially 
%  uncorrelated values into a roughly-square image.  
%
%  N is a positive integer (scalar)
%  OPTIONS include the following key-value pairs
%    'minar' specifies the minimum allowable aspect ratio (default 0.9)
%       In this context, aspect ratio is min(GEOMETRY)/max(GEOMETRY);
%       consequentially, minar is in the range (0 1].
%    'fitmode' specifies how the factoring is resolved (default 'shrink')
%       Accepted values are 'shrink' and 'grow'.
%
%  GEOMETRY is a 2-element vector of integers.  For nonsquare outputs, 
%  the elements of GEOMETRY are sorted in ascending order.  Again, note 
%  that prod(geometry) will not be equal to N unless N is a square number.
%
%  Examples:
%   N = 1564653; % a vector length
%   f = factor2(N,'ordered',false) % note N doesn't have useful factors
%   >  f =
%   >        1     1564653
%   >        3      521551
%   sz = squaresize(N,'fitmode','shrink') % resolve by shrinking the vector
%   >  sz =
%   >     1232        1270
%   sz = squaresize(N,'fitmode','grow') % resolve by padding the vector
%   >  sz =
%   >     1233        1269
%
%  See also: factor2, factor3

% defaults
minar = 0.9;
fitmode = 'shrink';

if numel(varargin)>0
	for k = 1:2:numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'minar'
				minar = imclamp(varargin{k+1});
			case 'fitmode'
				fitmode = lower(varargin{k+1});
			otherwise
				error('SQUARESIZE: unknown option %s',thisarg)
		end
	end
end

if ~isscalar(x0) || mod(x0,1)~=0 || x0<1
	error('SQUARESIZE: N must be a positive scalar integer')
end

switch fitmode
	case 'shrink'
		ar = 0;
		x = x0 + 1;
		while ar < minar
			x = x - 1;
			if x == 1
				% this can really only happen for x0 < 4
				% such cases aren't really useful, but at least it won't explode
				quietwarning('failed to find a vector length that can meet AR constraint')
				break;
			end
			f = factor2(x,'ordered',false);
			ar = f(end,1)./f(end,2);
		end

	case 'grow'
		ar = 0;
		x = x0 - 1;
		while ar < minar
			x = x + 1;
			f = factor2(x,'ordered',false);
			ar = f(end,1)./f(end,2);
		end

	otherwise
		error('SQUARESIZE: unknown fitting method %s',fitmode)
end

f = f(end,:);






























