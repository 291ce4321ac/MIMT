function varargout = crop2box(inmask)
%  OUTMASK = CROP2BOX(INMASK)
%  [OUTMASK EXTENTS] = CROP2BOX(INMASK)
%  [OUTMASK ROWS COLS] = CROP2BOX(INMASK)
%  Simple tool to crop a mask to its bounding box.
%
%  INMASK is a binarized image of any standard image class.  
%    Multichannel and multiframe images are supported, though cropping 
%    will be done to the union of channels/frames.
%    If the image is not binarized, its extents will be calculated by 
%    thresholding at black, though the cropped image will not itself
%    be binarized.
%  
%  OUTMASK is the cropped image
%  EXTENTS is a 2x2 matrix of integer subscripts into the original image.
%    It is of the form [startrow endrow; startcol endcol].  Contrast this
%    with the RECT output from imcrop() which does not directly correspond
%    to array subscripts.
%  ROWS and COLS are subscript vectors which span the intervals described
%    by EXTENTS.
%
%  Output class is inherited from input.
%
%  See also: cropborder

% binarize a copy if not already logical
if islogical(inmask)
	mask = inmask;
else
	% this handles int16 differently than logical() would
	% don't threshold at 0.5, otherwise soft masks will be clipped
	mask = imcast(inmask,'double')>0;
end

% collapse on trailing dims
mask = any(mask,3);
mask = any(mask,4);

% find ROI geometry
mkr = any(mask,2);
mkc = any(mask,1);
r1 = find(mkr,1,'first');
r2 = find(mkr,1,'last');
c1 = find(mkc,1,'first');
c2 = find(mkc,1,'last');

% crop original image to extents
outmask = inmask(r1:r2,c1:c2,:,:);

switch nargout
	case 1
		varargout{1} = outmask;
	case 2
		varargout{1} = outmask;
		varargout{2} = [r1 r2; c1 c2];
	case 3
		varargout{1} = outmask;
		varargout{2} = r1:r2;
		varargout{3} = c1:c2;
end








