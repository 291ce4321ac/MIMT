function yeahitis = isimageclass(inpict)
%  ISIMAGECLASS(INPICT)
%     Check if an array is of a standard image class.  
%     Returns true for the following datatypes:
%     'double','single','uint8','uint16','int16','logical'
%
%  See also: ismono, issolidcolor, isopaque

% yes, ~isempty(find(strcmp())) is faster than ismember()
% about 50x as fast in R2009b; about 2x-4x as fast in R2015b
% it's also very slightly faster than any(strcmp()) or summation in newer versions
yeahitis = strismember(class(inpict),{'double','single','uint8','uint16','int16','logical'});
		
