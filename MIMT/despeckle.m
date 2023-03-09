function outpict = despeckle(varargin)
%   OUTPICT=DESPECKLE(INPICT,MINSIZE,{MODE},{CONN})
%   Removal of small features in a binary image by connected group size.  Depending  
%   on the settings, this is equivalent to group-size-based image opening or closing.
%
%   INPICT is a binary image.  Multichannel and multiframe images are supported.
%     Numeric inputs will be thresholded at 50% gray.
%   MINSIZE is the smallest allowed size of connected groups (number of pixels)
%   MODE specifies the type of operation to perform (default 'both')
%     'open' performs image opening, removing groups of 1s smaller than MINSIZE
%     'close' performs image closing, filling groups of 0s smaller than MINSIZE
%     'both' performs both an opening and a closing
%   CONN optionally specifies the connectivity used (default 8)
%     This supports either 4 or 8-connectivity.
%
%  Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/despeckle.html
% See also: bwareaopen

connspec = 8;
modestrings = {'open','close','both'};
mode = 'both';

charargs = cellfun(@ischar,varargin);
if any(charargs)
	mode = lower(varargin{find(charargs,1)});
	if ~strismember(mode,modestrings)
		error('DESPECKLE: unexpected string for MODE')
	end
	varargin = varargin(~charargs);
end

if numel(varargin) == 1
	error('DESPECKLE: Too few input arguments')
elseif numel(varargin) == 2
	inpict = varargin{1};
	minsize = varargin{2};
elseif numel(varargin) == 3
	inpict = varargin{1};
	minsize = varargin{2};
	connspec = varargin{3};
else
	error('DESPECKLE: Too many input arguments')
end

if ~any(connspec == [4 8])
	error('DESPECKLE: Connectivity specification must be either 4 or 8')
end

if ~islogical(inpict)
	inpict = imcast(inpict,'logical');
end

% if image has no active pixels, return
if max(inpict(:)) == 0;
	outpict = inpict;
	return;
end

% IF IPT IS INSTALLED
if hasipt()
	outpict = false(size(inpict));
	for f = 1:size(inpict,4)
		for c = 1:size(inpict,3)
			switch mode
				case 'open'
					outpict(:,:,c,f) = bwareaopen(inpict(:,:,c,f),minsize,connspec);
				case 'close'
					outpict(:,:,c,f) = ~bwareaopen(~inpict(:,:,c,f),minsize,connspec);
				case 'both'
					outpict(:,:,c,f) = bwareaopen(inpict(:,:,c,f),minsize,connspec);
					outpict(:,:,c,f) = ~bwareaopen(~outpict(:,:,c,f),minsize,connspec);
			end
		end
	end
	
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outpict = false(size(inpict));
for f = 1:size(inpict,4)
	for c = 1:size(inpict,3)
		switch mode
			case 'open'
				outpict(:,:,c,f) = suppressbits(inpict(:,:,c,f));
			case 'close'
				outpict(:,:,c,f) = ~suppressbits(~inpict(:,:,c,f));
			case 'both'
				outpict(:,:,c,f) = suppressbits(inpict(:,:,c,f));
				outpict(:,:,c,f) = ~suppressbits(~outpict(:,:,c,f));
		end
	end
end
	
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outmask = suppressbits(inmask)
	[objects count] = bwlabelFB(inmask,connspec);
	[~,v] = find(objects);
	
	objectsizes = histc(v,1:count);
	segList = unique(v);
	segList = segList(objectsizes >= minsize);

	LUT = zeros(1,count+1);
	LUT(segList+1) = 1;
	outmask = LUT(objects+1);
end

end














