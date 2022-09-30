function [minval maxval] = imrange(inpict)
%   [min max]=IMRANGE(INPICT)
%       returns the global min and max pixel values in INPICT
%       
%   INPICT can be a vector or array of any dimension or class

dims = length(size(inpict));
for n = 1:1:dims
    if n == 1
        minval = min(inpict);
        maxval = max(inpict);
    else
        minval = min(minval);
        maxval = max(maxval);
    end
end

minval = double(minval);
maxval = double(maxval);

if nargout < 2
  minval = cat(2,minval,maxval);
end

end

% simple linear methods are much slower in older matlab releases
% minval=min(inpict(:));
% maxval=max(inpict(:));


