function [isvalid issigned bitwidth] = parseintclassname(intclassname)
%  [ISVALID ISSIGNED BITWIDTH] = PARSEINTCLASSNAME(NAME)
%  Simple utility to parse integer class names.  This can include any 
%  hypothetical non-native integer class.
% 
%  NAME is a character vector or scalar string describing an
%    integer numeric class.  Examples include 'uint8', 'int16',
%    'uint32', as well as any hypothetical non-native type
%    such as 'uint10', 'uint12', 'uint24', etc.
%
%  ISVALID, ISSIGNED are self-explanatory logical scalars.
%  BITWIDTH is a scalar integer of class 'double'.
%
%  If ISVALID is false, then ISSIGNED is also false, 
%    and BITWIDTH is NaN.
%
%  See also: buildintclassname

	intclassname = char(lower(intclassname));
	bitwidth = regexp(intclassname,'^u?int(\d+)$','tokens');
	isvalid = ~isempty(bitwidth);
	if isvalid
		bitwidth = str2double(bitwidth{:}{:});
		issigned = intclassname(1) == 'i';
	else
		bitwidth = NaN;
		issigned = false;
	end
end