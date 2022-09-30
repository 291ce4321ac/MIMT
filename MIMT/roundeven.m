function outnum = roundeven(innum,varargin)
%   ROUNDEVEN(INNUM,{TYPE})
%   Round numbers toward even integers, in the direction specified.
%
%   INNUM is a real-valued numeric scalar or array
%   TYPE specifies the type of rounding (default 'round')
%   'round' is similar to the inbuilt function round() in that values are 
%       rounded to the nearest even integer.  Midpoint values (odd integers) 
%       are rounded away from zero
%   'ceil' or 'up' rounds toward +Inf
%   'floor' or 'down' rounds toward -Inf
%   'fix' or 'in' rounds toward zero
%   'fill' or 'out' rounds away from zero
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/roundeven.html
% See also: roundodd

if numel(varargin) > 0
	key = varargin{1};
else
	key = 'round';
end

switch lower(key)
	case 'round'
		outnum = round(innum/2)*2;
	case {'ceil','up'}
		outnum = ceil(innum/2)*2;
	case {'floor','down'}
		outnum = floor(innum/2)*2;
	case {'fix','in'}
		outnum = fix(innum/2)*2;
	case {'fill','out'}
		outnum = (ceil(abs(innum)/2)*2).*sign(innum);
	otherwise
		error('ROUNDEVEN: unknown key %s',key)
end


