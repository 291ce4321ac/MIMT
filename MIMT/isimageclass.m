function yeahitis = isimageclass(inpict,convention)
%  ISIMAGECLASS(INPICT,{CONVENTION})
%    Check if an array is of a standard image class.  
%
%    Optional argument CONVENTION is one of the two keys:
%     'ipt' (default) or 'mimt'
%    
%    Returns true for the following datatypes:
%      For IPT convention:
%      'uint8','uint16','int16','double','single','logical'
%      For MIMT convention:
%      'uint8','uint16','uint32','uint64',
%      'int8','int16','int32','int64',
%      'double','single','logical'
%
%    See notes in imcast() synopsis regarding 64b images.
%    The extent of support for 'uint64' and 'int64' within MIMT
%    is primarily for import/export when necessary.  Don't expect
%    to build full 64b workflows.  Due to internal conversions to 
%    float, there's simply no advantage over using 'double'.
%
%  See also: ismono, issolidcolor, isopaque

% yes, ~isempty(find(strcmp())) is faster than ismember()
% about 50x as fast in R2009b; about 2x-4x as fast in R2015b
% it's also very slightly faster than any(strcmp()) or summation in newer versions

if nargin == 1 || strcmpi(convention,'ipt')
	yeahitis = strismember(class(inpict),{'double','single','uint8','uint16','int16','logical'});
elseif strcmpi(convention,'mimt')
	yeahitis = strismember(class(inpict),{'double','single','uint8','uint16','uint32','uint64','int8','int16','int32','int64','logical'});
else
	error('ISIMAGECLASS: unknown convention %s',convention)
end
