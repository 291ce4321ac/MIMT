function CT = hex2uint(hexc,nbytes)
%  UINTCT = HEX2UINT(HEXCT,{NBYTES})
%  Convert a hexadecimal representation to a numeric array of integers.
%  This is primarily useful for converting RGB tuples.
%
%  HEXCT is a color table represented as one or more tuples in hexadecimal.  
%    This may be a char vector, or a char matrix with one tuple per row. 
%    This may also be a cellchar with one tuple per element.
%    The following prefixes may be present: '0x','#'
%    This input is insensitive to case and spacing.
%  NBYTES optionally specifies the number of bytes per value (default 1)
%    The rows of HEXCT must contain an integer number of NBYTES-wide words.
%  
%  Output class is the smallest unsigned integer class capable of
%    representing a NBYTES-wide integer (e.g. uint8 when NBYTES = 1)
%
%  See also: uint2hex

% defaults
if nargin<2
	nbytes = 1;
end

% strrep() will work if cellchar but not if char matrix
% for sake of consistency, just do everything in cellchar
if ~iscell(hexc)
	hexc = num2cell(hexc,2);
elseif iscell(hexc)
	hexc = hexc(:);
end

% strip any prefixes
hexc = strrep(hexc,'0X',''); % just in case
hexc = strrep(hexc,'0x','');
hexc = strrep(hexc,'#','');

% need to check cellchar size compatibility
sz = cell2mat(cellfun(@(x) imsize(x,2),hexc,'uniform',false));
if nnz(diff(sz,1,1)) ~= 0
	error('HEX2RGB: cell contents are not uniform-length')
end

% convert back to char matrix
hexc = cell2mat(hexc);
ncolors = size(hexc,1);

if mod(size(hexc,2)/(2*nbytes),1)
	error('HEX2RGB: rows do not contain an integer number of %d-byte words',nbytes)
end

% this is way faster than trying to use hex2dec() for short tables
ftex = sprintf('%%%dx',2*nbytes);
CT = reshape(sscanf(hexc.',ftex),[],ncolors).';

switch nbytes
	case 1
		CT = uint8(CT);
	case 2
		CT = uint16(CT);
	case {3 4}
		CT = uint32(CT);
	case {5 6 7 8}
		CT = uint64(CT);
end


