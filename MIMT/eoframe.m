function outpict = eoframe(inpict,N,offset)
%   EOFRAME(INPICT, N, {OFFSET})
%       extracts every Nth frame from INPICT
%       alternatively, can be used for frame duplication
%
%   INPICT is a 4-D image array
%   N is an integer specifying the inverse of frame sampling density
%       e.g. for N==2, every other frame is returned (1 of 2 frames)
%   OFFSET specifies a frame offset (default 0)
%       if OFFSET=='expand', all frames will be replicated N times
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/eoframe.html
% See also: eoline

if nargin == 2
    offset = 0;
end

inclass = class(inpict);
s = size(inpict);
if strcmpi(offset,'expand');
    N = round(N);
    
    outpict = zeros([s(1:3) s(4)*N]);
    for f = 1:s(4);
        outpict(:,:,:,((f-1)*N+1):((f-1)*N+N)) = repmat(inpict(:,:,:,f),[1 1 1 N]);
    end
    
else
    N = round(N);
    offset = round(offset);

    framelist = 1:size(inpict,4);
    outpict = inpict(:,:,:,framelist(mod(framelist+offset,N) == 1));
end

outpict = cast(outpict,inclass);

return

