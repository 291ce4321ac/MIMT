function containerwidth = findintcontainerwidth(bitwidth)
%  CONTAINERWIDTH = FINDINTCONTAINERWIDTH(BITWIDTH)
%  Simple utility to find the smallest native integer class 
%  which can contain a non-native integer numeric class.  
%
%  BITWIDTH is a strictly positive integer scalar
%
%  Output CONTAINERWIDTH is a scalar double.  For example:
%    For BITWIDTH = 8, CONTAINERWIDTH = 8
%    For BITWIDTH = 10, CONTAINERWIDTH = 16
%    For BITWIDTH = 24, CONTAINERWIDTH = 32
%    For BITWIDTH > 64, CONTAINERWIDTH = []
%    
%  See also: parseintclassname, buildintclassname

nanbw = isnan(bitwidth);

if ~isscalar(bitwidth) || (bitwidth < 1) || (~nanbw && logical(mod(bitwidth,1)))
	error('FINDINTCONTAINERWIDTH: Invalid bitwidth')
end

% pass NaN
if nanbw
	containerwidth = NaN;
else
	nativewidths = [8 16 32 64];
	containerwidth = nativewidths(find(bitwidth <= nativewidths,1));
end

end