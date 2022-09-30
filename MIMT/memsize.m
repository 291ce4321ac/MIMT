function varargout = memsize(invar,varargin)
% MEMSIZE(THING,{UNITS})
%    convenience tool to calculate the memory footprint of an array or other variable
%
%    THING can be a variable of any class
%    UNITS specifies the output units (case-insensitive, default 'MB')
%       'B','KB','MB','GB','KiB','MiB','GiB' are valid
%
%    If called with no output arguments, a formatted result will be printed to console
%    If an output argument is provided, a scalar numeric result will be returned

units = 'mb';
validunames = {'b','kb','mb','gb','kib','mib','gib'};

for k = 1:numel(varargin)
	thisarg = varargin{k};
	if ischar(thisarg)
		switch lower(thisarg)
			case validunames
				units = thisarg;
			otherwise
				error('MEMSIZE: unknown argument %s\n',thisarg)
		end
	else
		error('MEMSIZE: unknown numeric argument\n')
	end
end

switch lower(units)
	case 'b'
		denom = 1;
		uname = 'B';
	case 'kb'
		denom = 1E3;
		uname = 'KB';
	case 'mb'
		denom = 1E6;
		uname = 'MB';
	case 'gb'
		denom = 1E9;
		uname = 'GB';
	case 'kib'
		denom = 1024;
		uname = 'KiB';
	case 'mib'
		denom = 1024^2;
		uname = 'MiB';
	case 'gib'
		denom = 1024^3;
		uname = 'GiB';
	otherwise
		% this should never be reached
		error('MEMSIZE: unknown unit name %s\n',units)
end

S = whos('invar');
sz = S.bytes/denom;

if nargout == 1
	varargout = {sz};
else
	fprintf('%1.3f %s\n',sz,uname)
end







