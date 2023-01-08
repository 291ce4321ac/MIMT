function [outmask,varargout] = pickblob(inmask,points,varargin)
%   OUTMASK = PICKBLOB(INMASK,POINTS,{OPTIONS})
%   [OUTMASK LIDX FIDX] = PICKBLOB(...)
%   Given a binarized image and one or more sets of points in the image, 
%   return a mask describing the blobs which contain the points.
%   
%   INMASK is typically a 2D binarized image
%   POINTS is a Px2 list specifying P points in image coordinates (px, [x y]).
%     Points are subject to rounding.  
%   OPTIONS include the following keys and key-value pairs
%     The following keys optionally specify how the output should be presented 
%     when it contains multiple blobs.  (default 'multiframe')
%       'multiframe': the output is a MxNx1xF logical mask describing F blobs
%       'union': the output is collapsed to a single MxNx1 logical mask
%          containing all selected blobs.
%     The following keys specify what gets returned when no blobs are selected.  
%       'empty' specifies that if no blobs are found, the output is empty. (default)
%       'null' specifies that a blank single-frame logical mask should be returned.
%     'conn', followed by either 4 or 8 specifies the connectivity used
%       when labeling the input mask. (default 8)
%     'islabel' key specifies that the input is a label array (as from bwlabel())
%       This allows for the reuse of an externally prepared label array, avoiding
%       redundant internal labeling in repeated calls to pickblobs(). 
%       No effort is made to check that the input is a valid label array. 
%
%   Optional outputs include:
%     LIDX is a Px1 vector indicating the label to which each point belongs.
%     FIDX is a Px1 vector indicating the frame of OUTMASK which contains the blob
%       to which each point belongs. When 'union' is selected, all points which 
%       lie on a blob belong to frame 1, since all matched blobs are on frame 1.
%     Points which do not lie on a blob have 0 index.
% 
%   OUTMASK is class 'logical'.
%
% See also: bwselect, bwlabelFB

% defaults
conn = 8;
islabel = false;
emptymasktype = 'empty';
inbstrings = {'empty','null'};
masktype = 'multiframe';
mtstrings = {'multiframe','union'};

% parse inputs
if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		thisarg = lower(varargin{k});
		switch thisarg
			case mtstrings
				masktype = thisarg;
				k = k+1;
			case inbstrings
				emptymasktype = thisarg;
				k = k+1;
			case 'conn'
				conn = varargin{k+1};
				k = k+2;
			case 'islabel'
				islabel = true;
			otherwise
				error('PICKBLOBS: unknown key %s',thisarg)
		end
	end
end

sz = imsize(inmask);
if sz(3)>1
	error('PICKBLOB: Expected mask to have a single channel')
end
	
% clean up point list
npoints = size(points,1);
badpts = any(points<1,2) | points(:,2)>sz(1) | points(:,1)>sz(2);
points = round(points(~badpts,:));

% if there aren't any valid points, there's nothing to do
if isempty(points)
	noblobsfound(nargout);
	return;
end

% label image
if islabel
	L = inmask; % assume it's already a valid label array
else
	L = bwlabelFB(inmask,conn);
end

% get labels of selected blobs
idx = sub2ind(sz(1:2),points(:,2),points(:,1));
Lidxgood = L(idx);
selectedlabels = unique(Lidxgood);
selectedlabels = nonzeros(selectedlabels);

% there are no selected blobs, so no blob masks get returned
if isempty(selectedlabels)
	noblobsfound(nargout);
	return;
end

% find all blobs as a multiframe logical mask
outmask = bsxfun(@eq,L,permute(selectedlabels,[2 3 4 1]));

% collapse frames if requested
if strcmp(masktype,'union')
	outmask = any(outmask,4);
end

% prepare additional outputs
if nargout>1
	Lidx = zeros(npoints,1);
	Lidx(~badpts) = Lidxgood;
	varargout{1} = Lidx;
end
if nargout>2
	Fidx = zeros(npoints,1);
	if strcmp(masktype,'union')
		Fidx(~badpts) = Lidxgood ~= 0;
	else
		[~,Fidxgood] = ismember(Lidxgood,selectedlabels);
		Fidx(~badpts) = Fidxgood;
	end
	varargout{2} = Fidx;
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function noblobsfound(nargoutparent)
	switch emptymasktype
		case 'empty'
			outmask = false(0); 
		case 'null'
			outmask = false(sz); 
	end
	
	if nargoutparent>1
		Lidx = zeros(npoints,1);
		varargout{1} = Lidx;
	end
	if nargoutparent>2
		Fidx = zeros(npoints,1);
		varargout{2} = Fidx;
	end
end

end % END MAIN SCOPE








