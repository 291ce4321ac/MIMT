function hexc = uint2hex(CT,varargin)
%  HEXCT = UINT2HEX(UINTCT,{OPTIONS})
%  Convert a numeric array of integers to hexadecimal representation.
%  This is primarily useful for converting RGB tuples.
%
%  UINTCT is a color table represented as a numeric matrix of integers.  
%    Each row is considered as a color tuple (e.g. UINTCT is Mx3 for RGB)
%    Values should be properly-scaled to the class of UINTCT.
%  OPTIONS includes the following keys and key-value pairs:
%  'nbytes' optionally specifies the number of bytes per value (default 1)
%    When UINTCT is floating-point class, NBYTES is used to rescale the
%    values accordingly.  When UINTCT is integer-class, NBYTES is ignored
%    and output width is dictated by the input class.
%  'prefix' optionally specifies the prefix appended to each output tuple
%    (default '#')
%  'celloutput' key specifies that the output should be a cell array of
%    character vectors.  
%  
%  Output class is either a character array or a cell array of character
%    vectors, depending on 'celloutput' option.
%
%  See also: hex2uint

% finish synopsis
% clean up

% defaults
prefix = '#';
nbytes = 1;
celloutput = false;

if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'nbytes'
					nbytes = varargin{k+1};
					k = k+2;
				case 'prefix'
					prefix = varargin{k+1};
					k = k+2;
				case 'celloutput'
					celloutput = true;
					k = k+1;
				otherwise
					error('RGB2HEX: unknown key %s',thisarg)
			end
		end
	end
end

switch class(CT)
	case 'uint8'
		nbytes = 1;
	case 'uint16'
		nbytes = 2;
	case 'uint32'
		nbytes = 4;
	case 'uint64'
		nbytes = 8;
	case {'double','single'}
		wv = 256^nbytes-1;
		CT = round(CT*wv); % this is the behavior of im2uint8(), etc
	otherwise
		% unsupported class
end


ncolors = size(CT,1);
ftex = sprintf('%%0%dX',2*nbytes);
hexc = reshape(sprintf(ftex,CT.'),[],ncolors).';

if ~isempty(prefix)
	hexc = [repmat(prefix,[ncolors 1]) hexc];
end

if celloutput
	hexc = num2cell(hexc,2);
end

% if input is integer-scale, it must be integer-class (nbytes is implicit)
% FP inputs are considered unit-scale (nbytes can be user-spec)
