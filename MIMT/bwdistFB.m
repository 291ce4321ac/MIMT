function varargout = bwdistFB(inpict)
%   DISTMAP=BWDISTFB(INPICT)
%   [DISTMAP NEIGHBORMAP]=BWDISTFB(INPICT)
%   Euclidean distance transform for binary images.  Optional output syntax also provides the nearest-
%   neighbor map (i.e. Voronoi diagram).
%
%   This is a passthrough to the IPT function bwdist(), with an external fallback implementation to help 
%   remove future dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   The tools provided for the fallback path are from the FEX submission by Ryan:
%   https://www.mathworks.com/matlabcentral/fileexchange/31581-generalized-distance-transform
%
%   INPICT is a 2D binary image.  Numeric images will be thresholded at 50% gray.
%   
%  Output class varies depending on the data range required by the image content.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/bwdistFB.html
% See also: bwdist, DT1

if ~islogical(inpict)
	inpict = imcast(inpict,'logical');
end

% if image has no useful information, return
% this forces consistent behavior between DT1 and bwdist
% the assumption is that distance is undefined when there are no points between which to measure
if max(inpict(:)) == 0
	if nargout == 1
		varargout{1} = NaN(size(inpict));
	elseif nargout == 2
		varargout{1} = NaN(size(inpict));
		varargout{2} = zeros(size(inpict));
	else
		error('BWDISTFB: Too many or too few arguments')
	end
	return;
end

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	if nargout == 1
		varargout{1} = bwdist(inpict);
	elseif nargout == 2
		[varargout{1} varargout{2}] = bwdist(inpict);
	else
		error('BWDISTFB: Too many or too few arguments')
	end
	
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rescale input to correspond to how bwdist is used
inpict = double(inpict);
inpict = (1-inpict)*1E10;

if nargout == 1
	% avoid calculating R if we don't need it
	D = zeros(size(inpict));
	for row = 1:size(inpict,1)
		[d r] = DT1(inpict(row,:));
		D(row,:) = d;
	end
	for col = 1:size(inpict,2)
		[d r] = DT1(D(:,col));
		D(:,col) = d;
	end
	varargout{1} = sqrt(D);
	
elseif nargout == 2
	D = zeros(size(inpict));
	R = zeros(size(inpict));
	for row = 1:size(inpict,1)
		[d r] = DT1(inpict(row,:));
		R(row,:) = r;
		D(row,:) = d;
	end
	for col = 1:size(inpict,2)
		[d r] = DT1(D(:,col));
		D(:,col) = d;
		R(:,col) = sub2ind(size(inpict),r,R(r,col));
	end
	varargout{1} = sqrt(D);
	varargout{2} = R;
	
else
	error('BWDISTFB: Too many or too few arguments')
end


end







