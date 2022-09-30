function varargout = imcropFB(varargin)
%   OUTPICT=IMCROPFB(INPICT,RECT)
%   OUTPICT=IMCROPFB(X,Y,INPICT,RECT)
%   Crop an image array.
%
%   This is a passthrough to the IPT function imcrop(), with an internal 
%   fallback implementation to help remove the dependency of MIMT tools on the 
%   Image Processing Toolbox. As with other fallback tools, performance without 
%   IPT may be limited or otherwise slightly different due to the methods used.
%
%   To be specific, IPT imcrop() supports interactive selections and indexed images.
%   If IPT is available, those features will work in passthrough, but if IPT is 
%   unavailable, the fallback method supports neither and will return an error.
%
%   INPICT is an image array of any standard image class; 4D arrays are supported.
%   RECT specifies the ROI to extract, in the form [XMIN YMIN WIDTH HEIGHT]
%      The units of RECT are presumed to be in pixels unless the input coordinate
%      space is explicitly defined otherwise.  Fractional inputs are supported.
%   X, Y can be used to define the input coordinate space in something other than
%      array coordinates (pixels).  These are vectors of the form e.g. [xmin xmax].
%      Whereas IPT imcrop() supports a legacy method where these can be specified
%      as orthogonal mesh grids instead of limit vectors, the fallback method does not.
%   
%   Optionally, imcropFB supports the same output arguments that the IPT method does:
%   [OUTPICT RECT]=imcropFB(...)
%   [X Y OUTPICT RECT]=imcropFB(...)
%
%   As with IPT imcrop(), the exact geometry of the output image is often nonintuitive.
%   It is helpful to consider that fractional coordinates are supported.  As both corners
%   of the ROI rectangle can lie on arbitrary locations in the array coordinate grid, 
%   imcrop() is compelled to extract all pixels which have any fractional intersection
%   with RECT.  This often results in OUTPICT being one pixel larger than [HEIGHT WIDTH].
%   This could have been avoided by doing interpolation, but that's not how imcrop() does it.
%   If you would rather have something simple and predictable, consider using cropborder().
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imcropFB.html
% See also: imcrop, cropborder

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	varargout = cell([1 nargout]);
	[varargout{:}] = imcrop(varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

usecustomlimits = false;

switch numel(varargin)
	case 1
		% imcrop(I) 
		% imcrop(H)
		error('IMCROPFB: the fallback method does not support interactive selections')
	case 2
		% imcrop(I RECT) 
		% imcrop(I MAP)
		if numel(varargin{2}) == 4
			inpict = varargin{1};
			srect = reshape(varargin{2},[1 4]);
		else
			error('IMCROPFB: arguments presumed to be of the form imcrop(IX MAP). The fallback method does not support indexed images or interactive selections')
		end
		
	case 3
		% imcrop(I MAP RECT) 
		% imcrop(X Y I)
		if numel(varargin{3}) == 4
			error('IMCROPFB: arguments presumed to be of the form imcrop(IX MAP RECT). The fallback method does not support indexed images')
		else
			error('IMCROPFB: arguments presumed to be of the form imcrop(X Y I). The fallback method does not support interactive selection')
		end
		
	case 4
		% imcrop(X Y I RECT) 
		if numel(varargin{1}) ~= 2 || numel(varargin{2}) ~= 2
			error('IMCROPFB: the fallback method does not support the legacy syntax for defining the coordinate space using mesh grids')
		elseif numel(varargin{4}) == 4
			usecustomlimits = true;
			xlimits = varargin{1};
			ylimits = varargin{2};
			inpict = varargin{3};
			srect = reshape(varargin{4},[1 4]);
		else
			error('IMCROPFB: arguments presumed to be of the form imcrop(X Y Ix MAP). The fallback method does not support indexed images or interactive selections')
		end
		
	otherwise
		error('IMCROPFB: too many input arguments specified')
end

s0 = imsize(inpict,2);

% define input coordinate space
if ~usecustomlimits
	xlimits = [1 s0(2)];
	ylimits = [1 s0(1)];
end

xlimits = double(xlimits);
ylimits = double(ylimits);
srect = double(srect);

xscale = (s0(2)-1)/diff(xlimits);
yscale = (s0(1)-1)/diff(ylimits);

% calculate boundary box in image coordinates
rawoutsize = fliplr(srect(3:4)).*[yscale xscale];
nwcorner = (fliplr(srect(1:2))-[ylimits(1) xlimits(1)]).*[yscale xscale]+1;
box = [round(nwcorner); round(nwcorner+rawoutsize)]';

% extract ROI from image
if any(box(:,1)' > s0) || any(box(:,2) < 1)
	% imcrop() doesn't do any padding or interpolation
	% if we're outside the image region, there's nothing to show
	outpict = [];
else
	box(:,1) = max(box(:,1),1);
	box(:,2) = min(box(:,2),s0');
	outpict = inpict(box(1,1):box(1,2),box(2,1):box(2,2),:,:);
end

% assemble output
switch nargout
	case 1
		varargout{1} = outpict;
	case 2
		varargout{1} = outpict;
		varargout{2} = srect;
	case 4
		varargout{1} = xlimits;
		varargout{2} = ylimits;
		varargout{3} = outpict;
		varargout{4} = srect;
	otherwise
		error('IMCROPFB: too many output arguments specified')
end








