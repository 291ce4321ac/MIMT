function varargout = colorquant(inpict,maxmapsize)
%   MAP=COLORQUANT(INPICT,{MAXMAPSIZE})
%   [IDXPICT MAP]=COLORQUANT(INPICT,{MAXMAPSIZE})
%      Color quantization using octree decomposition
%   
%   INPICT is an RGB image
%   MAXMAPSIZE specifies the maximum map size (default 256)
%      actual map may be shorter than this
%  
%   MAP will be of class 'double', scaled to a white value of 1
%   IDXPICT will be of class 'double', to avoid indexing issues
%      Matlab handles indices of intger and FP indexed images
%      differently by an offset of 1.  Shifting indices is necessary
%      if changing the image class!
%
%   This is all based directly on the example from Dan Bloomberg as 
%   provided on the Wikipedia page for 'octree'.  I'm more interested
%   in abusing dithering than figuring out the initial quantization algo.
%   
%   For general use, there really is no reason to not use rgb2ind() instead.
%   The results are better and faster than using COLORQUANT.
%
%   This example relies on the following FEX submission by Sven:
%   https://www.mathworks.com/matlabcentral/fileexchange/
%      40732-octree-partitioning-3d-points-into-spatial-subvolumes

if ~exist('maxmapsize','var')
	maxmapsize = 256;
end

inpict = imcast(inpict,'double');

% Extract pixels as RGB point triplets
pts = reshape(inpict,[],3);
% Create OcTree decomposition object using a target bin capacity
OT = OcTree(pts,'BinCapacity',ceil((size(pts,1) / maxmapsize) *7));
% Find which bins are "leaf nodes" on the octree object
leafs = find(~ismember(1:OT.BinCount, OT.BinParents) & ...
    ismember(1:OT.BinCount,OT.PointBins));
% Find the central RGB location of each leaf bin
map = mean(reshape(OT.BinBoundaries(leafs,:),[],3,2),3);

if nargout < 2
	 varargout{1} = map;
else
	% build indexed image
	outpict = zeros(size(inpict,1), size(inpict,2),'double');
	
	for i = 1:length(leafs)
		pxNos = find(OT.PointBins == leafs(i));
		outpict(pxNos) = i;
	end
	
	varargout{1} = outpict;
	varargout{2} = map;
end

% matlab handles indexed images differently depending on class
% uint images map an index of 0 to the first CT entry
% double images map an index of 1 to the first CT entry










