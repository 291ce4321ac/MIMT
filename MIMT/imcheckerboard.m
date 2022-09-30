function outpict = imcheckerboard(varargin)
%   OUTPICT=IMCHECKERBOARD({SQUARESIZE},{BLOCKS},{OPTIONS})
%   Generate a symmetric checkerboard image in the fashion of the IPT tool
%   checkerboard(). The right hand half of the board is tinted.
%
%   SQUARESIZE optionally specifies the size of the individual squares in pixels.
%      May be a scalar or a 2-element vector. (default [10 10])
%   BLOCKS optionally specifies the number of 2x2 subtiles (default [4 4])
%   OPTIONS includes the key 'uniform'. When this key is included, the half-tinting
%      behavior is disabled.
%
%  Output class is double.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imcheckerboard.html
% See also: checkerboard, freecb, lingrad, radgrad

blocks = [4 4];
squaresize = [10 10];
uniform = false;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			switch k
				case 1
					squaresize = thisarg;
				case 2
					blocks = thisarg;					
			end
		elseif ischar(thisarg)
			thisarg = lower(thisarg);
			if strcmp(thisarg,'uniform');
				uniform = true;
			else			
				error('IMCHECKERBOARD: unrecognized key %s',thisarg)
			end
		else
			error('IMCHECKERBOARD: unrecognized option')
		end
	end
end

blocks = max(round(blocks),1);
squaresize = max(round(squaresize),1);
if numel(blocks) == 1;
	blocks = [1 1]*blocks;
end
if numel(squaresize) == 1;
	squaresize = [1 1]*squaresize;
end

sout = blocks.*squaresize*2;
outpict = ones(sout);

y = 1:sout(1);
x = 1:sout(2);
my = mod((y-1)/2,squaresize(1)) < (squaresize(1)/2-(1E-6));
mx = mod((x-1)/2,squaresize(2)) < (squaresize(2)/2-(1E-6));
outpict(my,:) = 0;
outpict(:,~mx) = 1-outpict(:,mx);

if ~uniform
	outpict(:,(sout(2)/2+1):end) = outpict(:,(sout(2)/2+1):end)*0.7;
end


