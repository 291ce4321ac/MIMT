function outpict = freecb(sout,varargin)
%   OUTPICT=FREECB(SIZE,{SQUARESIZE},{OPTIONS})
%   Generate a simple 2D checkerboard image of any size, without regard for symmetry
%   or alignment.  The tiling is aligned to the NW corner of the image.
%
%   SIZE is a 2-element vector specifying the output image size in pixels
%   SQUARESIZE optionally specifies the size of the individual squares (in pixels).
%      May be a scalar or a 2-element vector. (default [10 10])
%   BLOCKS optionally specifies the number of 2x2 subtiles (default [4 4])
%   OPTIONS currently only includes the key 'invert', which inverts the output image.
%      Generating an inverted image is faster than inverting afterwards.
%
%  Output class is double.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/freecb.html
% See also: checkerboard, imcheckerboard, lingrad, radgrad

squaresize = [10 10];
invert = false;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			squaresize = thisarg;
		elseif ischar(thisarg)
			if strcmp(thisarg,'invert')
				invert = true;
			else
				error('FREECB: unknown key %s',thisarg)
			end
		end
	end
end

sout = max(round(sout(1:2)),0);
squaresize = max(round(squaresize),1);
if numel(squaresize) == 1
	squaresize = [1 1]*squaresize;
end

xx = mod(0:(sout(2)-1),squaresize(2)*2) < squaresize(2);
yy = mod(0:(sout(1)-1),squaresize(1)*2) < squaresize(1);
if invert
	outpict = bsxfun(@xor,xx,1-yy');
else
	outpict = bsxfun(@xor,xx,yy');
end


