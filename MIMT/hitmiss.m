function outpict = hitmiss(inpict,varargin)
%   OUTPICT=HITMISS(INPICT,SE1,{SE2})
%   Apply a hit or miss filter to an image.  
%
%   This is a passthrough to the IPT function bwhitmiss(), with internal fallback implementations 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other 
%   fallback tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported.
%      Proper inputs should be logical; numeric images will be thresholded at 50% gray.
%   SE1, SE2 are 2D structuring elements
%      While IPT tools support 3D structuring elements and their own strel class, the fallback 
%      methods do not.  If SE1/2 is a numeric array, it will be thresholded at 0.5.
%      Unless requirements are particular, a simple structuring element can be made in the 
%      absence of IPT by using existing MIMT tools (e.g. simnorm(fkgen('disk',10))>0.5)
%      As an alternative to the use of two strels, this function also supports the interval syntax
%      supported by bwhitmiss().
%
%  Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/hitmiss.html
% See also: bwhitmiss, strel, fkgen, morphops, morphnhood

if numel(varargin) == 1
	se = varargin{1};
	se2 = se == -1;
	se = se == 1;
elseif numel(varargin) == 2
	se = varargin{1};
	se2 = varargin{2};
else
	error('HITMISS: Too many or too few arguments')
end


% sanitize se, se2
if isnumeric(se)
	se = se > 0.5;
end
if isnumeric(se2)
	se2 = se2 > 0.5;
end

if ~islogical(inpict)
	inpict = inpict > imrescale(0.5,'double',class(inpict));
end

% IF IPT IS INSTALLED
if hasipt()
	outpict = bwhitmiss(inpict,se,se2);
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isimageclass(se) || ndims(se) > 2
	error('HITMISS: Expected SE to be a 2D numeric or logical array.  Fallback methods do not support IPT strel objects or 3D structuring elements.')
end

if ~isimageclass(se2) || ndims(se2) > 2
	error('HITMISS: Expected SE2 to be a 2D numeric or logical array.  Fallback methods do not support IPT strel objects or 3D structuring elements.')
end

% for logical inputs, these operations can be done by convolution
% this is slow, but it's much faster than loops in m-code

% we just converted these to logical in order to make them hard
% now we have to convert them back to numeric in order for imfilter to use them
inpict = imcast(inpict,'double');
se = double(se);
se2 = double(se2);

% erode(inpict,se1) & ~dilate(inpict,rot180(se2));
outpict = 1-min(max(imfilterFB(1-inpict,se),0),1) - min(max(imfilterFB(inpict,se2),0),1);

outpict = imcast(outpict,'logical');










