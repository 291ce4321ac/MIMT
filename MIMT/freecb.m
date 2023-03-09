function outpict = freecb(sout,varargin)
%   OUTPICT = FREECB(SIZE,{SQUARESIZE},{OFFSET},{OPTIONS})
%   Generate a simple 2D checkerboard image of any size, without constraints on symmetry
%   or size.  
%
%   SIZE is a 2-element vector specifying the output image size in pixels
%   SQUARESIZE optionally specifies the size of the individual squares (in pixels).
%      May be a scalar or a 2-element vector. (default [10 10]) ([y x])
%   OFFSET optionally specifies the tiling offset (default [0 0]) ([y x])
%      By default, tiling is aligned to the NW corner of the image.  Positive offsets
%      shift the tiling in a SE direction.
%   OPTIONS currently only includes the key 'invert', which inverts the output image.
%      Generating an inverted image is faster than inverting afterwards.
%
%  Output class is logical.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/freecb.html
% See also: checkerboard, imcheckerboard, lingrad, radgrad

squaresize = [10 10];
offset = [0 0];
invert = false;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			switch k
				case 1
					squaresize = thisarg;
				case 2
					offset = thisarg;					
			end
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

xx = offset(2):(sout(2) + offset(2) - 1);
yy = offset(1):(sout(1) + offset(1) - 1);
xx = mod(xx,squaresize(2)*2) < squaresize(2);
yy = mod(yy,squaresize(1)*2) < squaresize(1);

if invert
	outpict = bsxfun(@xor,xx,1-yy');
else
	outpict = bsxfun(@xor,xx,yy');
end


