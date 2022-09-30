function outpict = eoline(inpict,dim,rat,offset)
%   EOLINE(INPICT, DIM, RATIO, {OFFSET})
%       extracts every N/D lines from INPICT
%       can be used for generating grids and regular line fields
%
%   INPICT is a 2-D, 3-D or 4-D image array
%   DIM specifies the dimension along which to scan
%       1 returns rows
%       2 returns columns
%   RATIO is a 2-element vector specifying how many lines should be extracted
%       e.g. for [3 4] three of every four lines are extracted
%   OFFSET specifies a frame offset (default 0)
%
%   Accepts any standard image class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/eoline.html
% See also: eoframe

if nargin == 3
    offset = 0;
end

rat = round(rat);
offset = round(offset);
outpict = imzeros(size(inpict),class(inpict));
for f = 1:1:size(inpict,4);
    if dim == 1
        lines = 1:size(inpict,1);
        lines = lines.*ismember(mod(lines+offset,rat(2)),(1:rat(1)));
        outpict(lines(lines ~= 0),:,:,f) = inpict(lines(lines ~= 0),:,:,f);
    else
        lines = 1:size(inpict,2);
        lines = lines.*ismember(mod(lines+offset,rat(2)),(1:rat(1)));
        outpict(:,lines(lines ~= 0),:,f) = inpict(:,lines(lines ~= 0),:,f);
    end
end

return

