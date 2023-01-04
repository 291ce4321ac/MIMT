function outpict = impatmap(inpict,G,ugl,varargin)
%  OUTPICT = IMPATMAP(INPICT,PATGROUPS,LEVELS,{OPTIONS})
%    Using a sorted collection of grayscale (ostensibly tileable) patterns, 
%    approximate a multilevel grayscale representation of another image.
%    This is the tool used to apply the output from impatsort().
%
%  INPICT is an I/RGB image of any standard image class.  If IA/RGBA images are 
%    passed, alpha content will be stripped without composition.  Multiframe
%    images are not supported.
%  OPTIONS includes the following key-value pairs:
%    'nlevels' specifies the number of gray levels (default 8)
%    'stretchcont' specifies how much to stretch the image range (0-1; default 0.5)
%    'addcontours' specifies that contour-esque lines should be drawn between
%      adjacent gray level regions.  (default false)
%    'contourgl' specifies the gray color of the contour lines (0-1; default 0)
%    'pickrandom' specifies how patterns are chosen from the groups in PATGROUPS
%      If true, a random member of the desired group will be chosen to represent
%      the corresponding gray level in the output image.  If false, the first 
%      member of the group will be chosen instead.
%
%  OUTPICT is a grayscale image of class uint8. 
%
%  See also: impatsort, patbinchart, ptile


% defaults
stretchcont = 0.5;
centerbins = true; % when false, extrema bins are half-width
addcontours = false;
contourgl = 0;
pickrandom = true;
nlevels = 8;
% nobody should need to adjust centerbins

% get inputs
if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'stretchcont'
					stretchcont = varargin{k+1};
					k = k+2;
				case 'centerbins'
					centerbins = varargin{k+1};
					k = k+2;
				case 'addcontours'
					addcontours = varargin{k+1};
					k = k+2;
				case 'contourgl'
					contourgl = varargin{k+1};
					k = k+2;
				case 'pickrandom'
					pickrandom = varargin{k+1};
					k = k+2;
				case 'nlevels'
					nlevels = varargin{k+1};
					k = k+2;
				otherwise
					error('IMPATMAP: unknown key %s',thisarg)
			end
		else
			error('IMPATMAP: expected optional values to be prefaced by a parameter name')
		end
	end
end

% check inputs
if size(inpict,4)~=1
	error('IMPATMAP: multiframe INPICT is not supported')
end
if numel(G)~=numel(ugl)
	error('IMPATMAP: PATGROUPS and LEVELS must be the same length')
end
if numel(ugl)==0
	error('IMPATMAP: PATGROUPS and LEVELS must not be empty')
end
nlevels = max(nlevels,1);
contourgl = imclamp(contourgl);
stretchcont = imclamp(stretchcont);

% preparing input image
inpict = splitalpha(inpict);
inpict = mono(inpict,'y');

% setup input range
xrange = stretchcont*[0 1] + (1-stretchcont)*stretchlimFB(inpict,0.005).';
if centerbins
	% center gl for each inpict bin
	hl = abs(diff(imrange(xrange)))/(2*nlevels);
	x = linspace(xrange(1)+hl,xrange(2)-hl,nlevels);
else
	x = linspace(xrange(1),xrange(2),nlevels);
end

% scale image and generate mask set
inpict = imadjustFB(inpict);
mk = mlmask(inpict,nlevels);

% preallocate
sz = imsize(inpict,2);
if contourgl == 0
	outpict = zeros(sz,'uint8');
else
	outpict = (contourgl*255)*ones(sz,'uint8');
end

% start process
for ml = 1:nlevels
	% find GL bin idx
	[~,binidx] = min(abs(ugl-x(ml)));
	% find num of pats available in this GL bin
	binpop = numel(G{binidx});
	
	% pick idx within bin
	if pickrandom
		binmembidx = randi([1 binpop],1,1);
	else
		binmembidx = 1;
	end
	
	% get pattern
	thispat = G{binidx}{binmembidx};
	% process pattern
	thispat = ptile(thispat,sz);
	
	% composite this segment
	thismask = mk(:,:,:,ml);
	if addcontours
		thismask = morphops(thismask,ones(2),'erode');
	end
	outpict(thismask) = thispat(thismask);
end



