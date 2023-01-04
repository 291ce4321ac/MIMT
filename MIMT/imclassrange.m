function thisrange = imclassrange(classname)
%  RANGE = IMCLASSRANGE(CLASSNAME)
%  Get the nominal data range expected of a given image class
%
%  CLASSNAME is a string/char specifying the class in question
%    Supports: 'single','double','logical','uint8','int8','uint16','int16'
%              'uint32','int32','uint64','int64'
%
%  Output is a 1x2 vector of class 'double'
%
% See also: getrangefromclass

% this could be more thorough, but i don't care.
classname = lower(classname);
switch classname
	case {'single','double','logical'}
		thisrange = [0 1];
	case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
		thisrange = double([intmin(classname) intmax(classname)]);
	otherwise
		error('IMCLASSRANGE: %s is not an accepted class name',classname)
end

end