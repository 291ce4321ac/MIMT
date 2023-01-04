function inpict = iminv(inpict)
%  OUT = IMINV(INPICT)
%   Return the inverse (complement) of an image. Make dark  
%   things light; make light things dark. This is functionally 
%   the same as IPT imcomplement().  I just hate long names.
%
%  INPICT is an image of any size or numeric/logical class.
%
% See also: imcomplement

% getrangefromclass() is an IPT dependency in legacy versions
% imclassrange() now exists, but eh.
if isnumeric(inpict)
	inclass = class(inpict);
	switch inclass(1)
		case {'u','i'}
			inpict = bitcmp(inpict); % this is faster anyway
		otherwise
			inpict = 1 - inpict;
	end
elseif islogical(inpict)
	inpict = ~inpict;
else
	error('IMINV: expected INPICT to be numeric or logical')
end

