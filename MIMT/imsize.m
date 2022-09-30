function outsize = imsize(inpict,varargin)
%   SIZE = IMSIZE(INPICT,{LENGTH})
%       This is just a simple wrapper for size().  This ensures
%       that the size vector is always a fixed length, allowing
%       simpler and safer comparison of image dimensionality.
%       It also allows the equivalent of size(mypicture,1:2), 
%       which would be a routine convenience if it worked.
%
%   INPICT is an array of any type
%   LENGTH specifies the length of the output vector (default 4)
%
%   EXAMPLES:
%    Test to see if two arrays are the same size:
%      sizesdiffer = any(imsize(A)~=imsize(B));
%    Just get the image height and width:
%      pagesz = imsize(A,2);
%
%  See also: chancount

veclen = 4;

if numel(varargin) > 0
	veclen = varargin{1};
end

s = size(inpict);
ns = numel(s);
if ns < veclen
	outsize = [s ones([1 veclen-ns])];
elseif ns > veclen
	outsize = s(1:veclen);
else
	outsize = s;
end






