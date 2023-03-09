function outpict = bwareafiltFB(inpict,varargin)
%   OUTPICT=BWAREAFILTFB(INPICT,SIZERANGE,{CONN})
%   OUTPICT=BWAREAFILTFB(INPICT,NUMGROUPS,{WHICHGROUPS},{CONN})
%   Extract selected groups from a binary image based on group size.  
%
%   INPICT is a 2D binary image.
%     Numeric inputs will be thresholded at 50% gray.
%   SIZERANGE is a 2-element vector specifying the size of connected groups to 
%      extract (number of pixels)
%   NUMGROUPS alternatively specifies the desired number of groups
%   WHICHGROUPS specifies the size extreme to target (default 'largest')
%     'largest'  selects the NUMGROUPS largest groups
%     'smallest' selects the NUMGROUPS smallest groups
%     if a tie occurs, a warning will be printed to console
%   CONN optionally specifies the connectivity used (default 8)
%     This supports either 4 or 8-connectivity.
%
%  Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/bwareafiltFB.html
% See also: bwareafilt, bwareaopen, despeckle


if ~islogical(inpict)
	inpict = imcast(inpict,'logical');
end

% IF IPT IS INSTALLED
if hasipt()
	outpict = bwareafiltFB(varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

connspec = 8;
range = [];
numgroups = [];
modestrings = {'largest','smallest'};
mode = 'largest';

% parse & strip any key strings
charargs = cellfun(@ischar,varargin);
if any(charargs)
	mode = lower(varargin{find(charargs,1)});
	if ~strismember(mode,modestrings)
		error('BWAREAFILTFB: unexpected string for MODE')
	end
	varargin = varargin(~charargs);
end

if numel(varargin) == 0
	error('BWAREAFILTFB: Too few input arguments')
elseif numel(varargin) == 1
	thisarg = varargin{1};
	if numel(thisarg) == 2
		range = thisarg;
	else
		numgroups = thisarg;
	end
elseif numel(varargin) == 2
	thisarg = varargin{1};
	if numel(thisarg) == 2
		range = thisarg;
	else
		numgroups = thisarg;
	end
	connspec = varargin{2};
else
	error('BWAREAFILTFB: Too many input arguments')
end

if ~any(connspec == [4 8])
	error('BWAREAFILTFB: Connectivity specification must be either 4 or 8')
end

% if image has no active pixels, return
if max(inpict(:)) == 0;
	outpict = inpict;
	return;
end

if ~isempty(range)
	% select objects whose area lies within RANGE
	[objects count] = bwlabelFB(inpict,connspec);
	[~,v] = find(objects);
	
	objectsizes = histc(v,1:count);
	segList = unique(v);
	segList = segList(objectsizes >= range(1) & objectsizes <= range(2));

	LUT = zeros(1,count+1);
	LUT(segList+1) = 1;
	outpict = LUT(objects+1);
	
else 
	% select objects whose area lies within RANGE
	[objects count] = bwlabelFB(inpict,connspec);
	[~,v] = find(objects);
	
	objectsizes = histc(v,1:count);
	[objectsizes idx] = sort(objectsizes);
	segList = unique(v);
	segList = segList(idx); % reorder the list to match objectsizes sorting

	if strcmp(mode,'largest')
		segList = segList((end-numgroups+1):end);
		% IPT tool barfs warnings, so i might as well
		if objectsizes(end-numgroups) == objectsizes(end-numgroups+1)
			quietwarning('BWAREAFILTFB: ties occurred for nth place during selection')
		end
	else
		segList = segList(1:numgroups);
		if objectsizes(numgroups) == objectsizes(numgroups+1)
			quietwarning('BWAREAFILTFB: ties occurred for nth place during selection')
		end
	end
	
	LUT = zeros(1,count+1);
	LUT(segList+1) = 1;
	outpict = LUT(objects+1);
	
end

	









