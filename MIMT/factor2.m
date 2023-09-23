function p = factor2(innum,varargin)
%  P = FACTOR2(N,{OPTIONS})
%   Find the factor pairs of an integer. This is useful for finding 
%   the 2D geometries into which a given vector can be arranged,  
%   for instance, when devectorizing images of unknown geometry.
%
%  N is a positive scalar integer (not necessarily integer-class)
%  OPTIONS include the key-value pairs:
%   'minar' specifies the minimum normalized aspect ratio (default 0)
%      The normalized aspect ratio of the 2-tuple f is min(f)/max(f).  
%      This allows all aspect ratios to be expressed within [0 1].
%      Specifying a value greater than 0 allows the exclusion of  
%      factor pairs which are further from square than desired.
%   'ordered' is followed by a logical value (default true)
%      This flag changes whether the order of factors is considered
%      when checking for uniqueness of the pairs.  In other words,  
%      unsetting ORDERED selects factor pairs of unique aspect ratio.
%
%  P is a Mx2 matrix, where M is the number of unique
%   factor pairs for the given number. 
%   When ORDERED, M will be even for all non-square integers.
%   When ORDERED is unset, M will be approximately halved.
%
%  EXAMPLES:
%  Get all factor pairs
%   p = factor2(12)
%   p =
%      1    12
%      2     6
%      3     4
%      4     3
%      6     2
%     12     1
% 
%  Only get the pairs with unique ratio
%   p = factor2(12,'ordered',false)
%   p =
%      1    12
%      2     6
%      3     4
%
%  Only get factor pairs with AR between 1:2 and 2:1
%   p = factor2(12,'minar',0.5)
%   p =
%      3     4
%      4     3
%  
%  Webdocs: http://mimtdocs.rf.gd/manual/html/factor2.html
%  See also: factor3, squaresize, reshape, imrectify

% i make no claims that this is the best way to do this
% it probably isn't, but it works.

ordered = 1;
minar = 0;
if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'ordered'
				ordered = varargin{k+1} ~= 0; % this implicitly works for logical inputs
				k = k+2;
			case 'minar'
				minar = varargin{k+1};
				k = k+2;
			otherwise
				error('FACTOR2: unknown key %s',thisarg)
		end
	end
end

if ~isscalar(innum)
	error('FACTOR2: N must be scalar')
elseif mod(innum,1)~=0
	error('FACTOR2: N must be an integer')
end

if minar<0 || minar>1
	error('FACTOR2: MINAR must be in the range [0 1]')
end

% prime factors of innum
innum = abs(innum);
f = [1 factor(innum)];

% build valid non-prime factor list
a = [];
for kk = 1:numel(f)
	a = [a; prod(nchoosek(f,kk),2)]; %#ok<*AGROW>
end

% sort
p = [a innum./a];
if ~ordered
	p = sort(p,2);
end
p = unique(p,'rows','sorted');

if minar>0
	if ordered
		pm = sort(p,2);
	else
		pm = p;
	end
	mask = (pm(:,1)./pm(:,2)) >= minar;
	
	p = p(mask,:);
end


