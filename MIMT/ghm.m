function out = ghm(g,h,varargin)
%   GH = GHM(X,Y,{OPTIONS})
%   Calculate the geometric-harmonic mean (GHM) of the absolute values 
%   of two variables.  Optionally, calculate the weighted GHM
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
% See also: agm, mean, geomean, harmmean, trimmean

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
				error('GHM: unknown option %s',thisarg)
		end
	end
end

g = abs(double(g));
h = abs(double(h));

if ndims(h) ~= ndims(g) || all(size(h) ~= size(g))
	error('GHM: size of inputs must match')
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
	out = h;

elseif weighted && w(1) == 1
	out = g;

else
	while true
		g0 = g;

		if ~weighted 
			% use fast path when able
			g = sqrt(g0.*h);
			h = 2./(1./g0 + 1./h);
		else
			g = sqrt(g0.^(2*w(1)) .* h.^(2*w(2)));
			h = 1./(w(1)./g0 + w(2)./h);
		end

		if all(abs(g0-g) <= g*tol+eps) 
			break; 
		end 
	end
	out = (g+h)/2;
end







