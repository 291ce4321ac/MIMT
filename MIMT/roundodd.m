function outnum = roundodd(innum,varargin)
%   ROUNDODD(INNUM,{TYPE})
%   Round numbers to odd integers, in the direction specified.
%
%   INNUM is a real-valued numeric scalar or array
%   TYPE specifies the type of rounding (default 'round')
%   'round' is similar to the inbuilt function round() in that values are 
%       rounded to the nearest odd integer.  Midpoint values (even integers) 
%       are rounded away from zero, except zero itself, which is rounded up.
%   'ceil' or 'up' rounds toward +Inf
%   'floor' or 'down' rounds toward -Inf
%   'fix' or 'in' rounds toward zero (actually toward -1, since 0 is not odd)
%   'fill' or 'out' rounds away from zero
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/roundodd.html
% See also: roundeven

if numel(varargin) > 0
	key = varargin{1};
else
	key = 'round';
end

switch lower(key)
	case 'round'
		outnum = round((innum+1)/2)*2-1;
	case {'ceil','up'}
		outnum = ceil((innum-1)/2)*2+1;
	case {'floor','down'}
		outnum = floor((innum+1)/2)*2-1;
	case {'fix','in'}
		outnum = fix((innum+1)/2)*2-1;
	case {'fill','out'}
		outnum = (ceil((abs(innum)+1)/2)*2-1).*sign(innum);
	otherwise
		error('ROUNDODD: unknown key %s',key)
end


