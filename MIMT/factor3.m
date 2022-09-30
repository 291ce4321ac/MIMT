function allP = factor3(innum,varargin)
%  P = FACTOR3(N,{OPTIONS})
%   Find the factor triples of an integer. This is useful for finding 
%   the 3D geometries into which a given vector can be arranged,  
%   for instance, when devectorizing images of unknown geometry.
%
%  N is a scalar integer (not necessarily integer-class)
%  OPTIONS include the key-value pairs:
%   'maxpc' specifies the maximum number of pages (default N)
%   'minpc' specifies the maximum number of pages (default 1)
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
%  P is a Mx3 matrix, where M is the number of unique factor triples 
%   for the given number. The elements of each row are ordered such
%   that they describe array geometries [2Dpagegeometry pagecount].
%   The 'minar' and 'ordered' options only influence the page geometry.
%   P is sorted by pagecount. See factor2() for how page geometries 
%   are sorted.
%
%  EXAMPLES:
%  Get factors for a restricted range of aspect ratio and pagecount
%   P = factor3(60,'minar',0.5,'maxpc',5); 
%   P =
%      6    10     1
%     10     6     1
%      5     6     2
%      6     5     2
%      4     5     3
%      5     4     3
%      3     5     4
%      5     3     4
%      3     4     5
%      4     3     5
%  
%  Webdocs: http://mimtdocs.rf.gd/manual/html/factor3.html
%  See also: factor2, reshape, imrectify

maxpc = [];
minpc = [];

vai = {};
if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		switch lower(varargin{k})
			case 'maxpc'
				maxpc = varargin{k+1};
				k = k+2;
			case 'minpc'
				minpc = varargin{k+1};
				k = k+2;
			otherwise
				% other args get saved to pass to factor2()
				vai = [vai varargin(k:k+1)];
				k = k+2;
		end
	end
end

if ~isscalar(innum)
	error('FACTOR3: N must be scalar')
elseif mod(innum,1)~=0
	error('FACTOR3: N must be an integer')
end

% prime factors of innum
f = [1 factor(abs(innum))];

% build valid non-prime factor list
a = [];
for kk = 1:numel(f)
	a = [a; prod(nchoosek(f,kk),2)]; %#ok<*AGROW>
end

% sort and prune
a = unique(a,'sorted');
if ~isempty(maxpc)
	maxpc = min(max(maxpc,1),innum);
	a = a(a<=maxpc);
end
if ~isempty(minpc)
	minpc = min(max(minpc,1),innum);
	a = a(a>=minpc);
end

% build geometries
allP = [];
for k = 1:numel(a)
	P = factor2(innum/a(k),vai{:});
	P = [P a(k)*ones(size(P,1),1)];
	allP = [allP; P];
end






