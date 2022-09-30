function yeah = strismember(thing,setofthings)
%   YEAHITIS=STRISMEMBER(STRING,SETOFSTRINGS)
%   Returns true if the character vector STRING is a member of the 
%   cell array SETOFSTRINGS. This is generally faster than using 
%   ismember() -- about 2x as fast in recent versions, and up to 
%   50x as fast in older versions. Numeric inputs are not supported.
%    
% See also: ismember, strcmp

yeah = ~isempty(find(strcmp(thing,setofthings),1));
