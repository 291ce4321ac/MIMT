function thisrange = imclassrange(classname,outputtype)
%  RANGE = IMCLASSRANGE(CLASSNAME,{OUTPUTTYPE})
%  Get the nominal data range expected of a given image class
%
%  CLASSNAME is a string/char specifying the class in question
%    Supports: 'single','double','logical','uint8','int8','uint16','int16'
%              'uint32','int32','uint64','int64'
%  OUTPUTTYPE consists of the optional key 'native' 
%    When set, the output class matches CLASSNAME, otherwise the output
%    is of class 'double'.  
%
%  Note that the extents of 'uint64' and 'int64' cannot be exactly 
%  represented in double precision float.  Unless 'native' output
%  is used, the results will be off by one.  In a floating point workflow
%  at a similar scale, such a small error may be negligible compared to 
%  the prevailing rounding error which will likely be occurring, but 
%  you'll have to decide if that matters to you.
%
%  Output is a 1x2 vector
%
% See also: getrangefromclass

if nargin == 1
	native = false;
elseif strcmpi(outputtype,'native')
	native = true;
else 
	error('IMCLASSRANGE: unknown argument %s',outputtype)
end

% this could be more thorough, but i don't care.
classname = lower(classname);
switch classname
	case {'single','double','logical'}
		if native
			thisrange = cast([0 1],classname);
		else
			thisrange = [0 1];
		end
	case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
		if native
			thisrange = [intmin(classname) intmax(classname)];
		else
			thisrange = double([intmin(classname) intmax(classname)]);
		end
	otherwise
		error('IMCLASSRANGE: %s is not an accepted class name',classname)
end

end