function thisrange = imclassrange(classname,outputtype)
%  RANGE = IMCLASSRANGE(CLASSNAME,{OUTPUTTYPE})
%  Get the nominal data range expected of a given image class.
%
%  CLASSNAME is a string/char specifying the class in question
%    Native classes are:
%      'single','double','logical','uint8','int8','uint16','int16'
%      'uint32','int32','uint64','int64'
%    For certain particular conveniences, non-native integer classes 
%      can be specified in a similar form; e.g. 'uint10','int24', etc.
%  OUTPUTTYPE consists of the optional key 'native' 
%    When set, the output class matches CLASSNAME, otherwise the output
%    is of class 'double'.  For non-native integer classes, requesting 
%    the 'native' option will select the smallest native class of the 
%    same type (i.e. signed or unsigned) which can contain the number.
%    An error will occur if 'native' output is requested for non-native
%    integer classes wider than 64 bits.
%
%  Note that the extents of 'uint64' and 'int64' (and similar wide non-native 
%  integer classes) cannot be exactly represented in double precision float.  
%  Unless 'native' output is used, the results will be off by one.  In a 
%  floating point workflow at a similar scale, such a small error may be 
%  negligible compared to the prevailing rounding error which will likely 
%  be occurring, but you'll have to decide if that matters to you.
%
%  Output is a 1x2 vector
%
% See also: getrangefromclass, imrescale, imcast

if nargin == 1
	native = false;
elseif strcmpi(outputtype,'native')
	native = true;
else 
	error('IMCLASSRANGE: unknown argument %s',outputtype)
end

unitscaletypes = {'single','double','logical'};
integertypes = {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'};

% this could be more thorough, but i don't care.
classname = lower(classname);
if strismember(classname,unitscaletypes)
	if native
		thisrange = cast([0 1],classname);
	else
		thisrange = [0 1];
	end
elseif strismember(classname,integertypes)
	if native
		thisrange = [intmin(classname) intmax(classname)];
	else
		thisrange = double([intmin(classname) intmax(classname)]);
	end
else % all the non-native possibilities (and potentially bogus inputs)
	[isvalid issigned bitwidth] = parseintclassname(classname);
	
	% this breaks in old versions before arithmetic worked on 64b data
	if isvalid
		if native
			containerwidth = findintcontainerwidth(bitwidth);
			if isempty(containerwidth)
				error('IMCLASSRANGE: There is no native integer class wide enough to contain this number')
			end
			containerclass = buildintclassname(issigned,containerwidth);

			x = cast(1,containerclass);
			% this will overflow if bitwidth and containerwidth are the same
			% but that shouldn't ever be the case if we're in this branch
			if issigned
				thisrange = [-bitshift(x,bitwidth-1) bitshift(x,bitwidth-1)-1];
			else
				thisrange = [0 bitshift(x,bitwidth)-1];
			end
		else
			if issigned
				thisrange = [-2^(bitwidth-1) 2^(bitwidth-1)-1];
			else
				thisrange = [0 2^bitwidth-1];
			end
		end
	else
		error('IMCLASSRANGE: %s is not an accepted class name',classname)
	end
end

end % END MAIN SCOPE


