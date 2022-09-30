function out = circmean(x,varargin)
%  CIRCMEAN(X,{DIM},{MODE})
%  Calculate mean of angles.  Useful for calculating mean color properties in
%  polar color models.
%
%  X is an array of angles in either degrees or radians.
%  DIM optionally specifies the dimension along which to operate (default 1)
%  MODE optionally specifies the angle units, either 'deg' or 'rad' (default 'deg')
%
% See also: mean

dim = 1;
degreemode = true;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch thisarg
				case {'deg','degrees'}
					degreemode = true;
				case {'rad','radians'}
					degreemode = false;
				otherwise
					error('CIRCMEAN: unknown mode ''%s''',thisarg)
			end
		elseif isnumeric(thisarg) && isscalar(thisarg)
			dim = round(thisarg);
		else
			error('CIRCMEAN: unknown argument')
		end
	end
end

if degreemode
	x = pi*x/180;
end

out = angle(sum(exp(1i*x),dim));

% this also works, but is slightly slower
% also, atan2d() causes version-dependency (R2012b)
%out = atan2(sum(sin(x),dim),sum(cos(x),dim));

out = mod(out,2*pi);

if degreemode
	out = 180*out/pi;
end



