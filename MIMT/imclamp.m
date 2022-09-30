function outpict = imclamp(inpict,varargin)
%  OUTPICT = IMCLAMP(INPICT,{LIMIT})
%    Clamp data values to stay within a closed interval. This is
%    more readable than min(max(myvariable,lim1),lim2), especially
%    in cases where the limits are already in vector form.
%
%  INPICT is any numeric array
%  LIMITS optionally specifies the interval extent (default [0 1])
%    This parameter is a 2-element vector with ascending values.
%
%  Output class is inherited from input.
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/imclamp.html
%  See also: simnorm, max, min, imrange

limits = [0 1];

if numel(varargin)>0
	limits = varargin{1};
	if numel(limits) ~= 2
		error('IMCLAMP: limit vector must have 2 elements')
	end
	if diff(limits)<=0
		error('IMCLAMP: lower limit must be less than upper limit')
	end
end

outpict = min(max(inpict,limits(1)),limits(2));

