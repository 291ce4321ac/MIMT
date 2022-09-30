function out = agm(a,g,varargin)
%   AM = AGM(X,Y,{OPTIONS})
%   Calculate the arithmetic-geometric mean (AGM) of the absolute values 
%   of two variables.  Optionally, calculate the weighted AGM
%   
%   X,Y are of any numeric class or size (must be the same size)
%   OPTIONS includes the key-value pairs:
%     'weight' is used to specify the relative weights of the inputs
%        This can either be specified as a scalar or as a 2-element vector.  
%        When scalar, 'weight' specifies the relative weight of the X term, 
%        and the weight of Y is the unit complement.
%        The default is to use uniform weighting.
%        If weighting vector is not sum-normalized, it will be.
%     'tol' is the tolerance used to determine that the result has 
%        converged sufficiently (default eps)
%
%   Output class is 'double'
% 
% See also: ghm, mean, geomean, harmmean, trimmean

% this tends to be a lot slower than ghm due to the convergence rate for inputs near zero
% look at the contour plots for 'average' vs the other metrics
% all those values near the axes need to slowly be swept to zero
% this could be helped with different exit conditions, but eeeh.

tol = eps;
weighted = false;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'weight'
				w = varargin{k+1};
				weighted = true;
				k = k+2;
			case 'tol'
				tol = varargin{k+1};
				k = k+2;
			otherwise
				error('AGM: unknown option %s',thisarg)
		end
	end
end

a = abs(double(a));
g = abs(double(g));

if ndims(a) ~= ndims(g) || all(size(a) ~= size(g))
	error('AGM: size of inputs must match')
end


% need to conditionally expand/normalize weight
if weighted && numel(w) == 1
	w = min(max(w,0),1);
	w = [w 1-w];
elseif weighted
	w = w/sum(w);
end

if weighted && w(1) == 0.5
	weighted = false;
end

% shortcut cases
if weighted && w(1) == 0 
	out = g;

elseif weighted && w(1) == 1
	out = a;

else
	while true
		a0 = a;

		if ~weighted 
			% use fast path when able
			a = (a0+g)/2;
			g = sqrt(a0.*g);
		else
			a = a0*w(1) + g*w(2);
			g = sqrt(a0.^(2*w(1)) .* g.^(2*w(2)));
		end

		if all(abs(a0-a) <= a*tol+eps) 
			break; 
		end 
	end
	out = (a+g)/2;
end




