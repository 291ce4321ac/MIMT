function intclassname = buildintclassname(issigned,bitwidth)
%  INTCLASSNAME = BUILDINTCLASSNAME(ISSIGNED,BITWIDTH)
%  Construct a char vector which specifies an integer numeric class.
%  This can include any hypothetical non-native integer class.
%  
%  ISSIGNED is a logical scalar
%  BITWIDTH is a strictly positive integer scalar
%
%  Output INTCLASSNAME is a character vector of the form:
%    'uint8' for ISSIGNED = false, BITWIDTH = 8
%    'int16' for ISSIGNED = true, BITWIDTH = 16
%    'uint12' for ISSIGNED = false, BITWIDTH = 12
%
%  See also: parseintclassname()

if ~isscalar(bitwidth) || (bitwidth < 1) || logical(mod(bitwidth,1))
	error('BUILDINTCLASSNAME: Invalid bitwidth')
end

intclassname = sprintf('uint%d',bitwidth);
if issigned
	intclassname = intclassname(2:end);
end

end