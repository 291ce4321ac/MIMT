function outpict = dilatemargins(inpict,margins,se,varargin)
%   DILATEMARGINS(INPICT, MARGINS, SE, {OPTIONS})
%       Performs selective dilation & erosion on lightest and darkest pixels.
%
%   INPICT is an I/IA/RGB/RGBA image of any standard image class
%   MARGINS is a 1x2 vector specifying the width of black and white value margins
%       Values are on a normalized scale. 
%       e.g. [0 0] corresponds to threshold values of [0 1]
%            [0.05 0.10] corresponds to threshold values of [0.05 0.90]
%       May be specified as a scalar with implicit expansion.
%   SE is a structure element for dilation (see strel())
%   OPTIONS includes the following keys:
%     'invert' inverts the output behavior
%     'independent' performs masking on image channels independently (default)
%     'intersection' selects the intersection of channel masks
%     'union' selects the union of channel masks
% 
%   Output class is inherited from input
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/dilatemargins.html
% See also: morphops

mode = 'independent';
modestrings = {'independent','intersection','union'};
invert = false;
extrema = [0 1];

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'invert'
				invert = true;
				k = k+1;
			case modestrings
				mode = lower(varargin{k});
				k = k+1;
			otherwise
				error('DILATEMARGINS: unknown input parameter name %s',varargin{k})
		end
	end
end

if numel(margins) == 1; margins = [1 1]*margins; end
margins = imrescale(margins,'double',class(inpict));
extrema = imrescale(extrema,'double',class(inpict));

wmask = false(size(inpict));
bmask = false(size(inpict));
for c = 1:size(inpict,3);
	inchan = inpict(:,:,c);
	wmask(:,:,c) = inchan >= (extrema(2)-margins(2));
	bmask(:,:,c) = inchan <= (extrema(1)+margins(1));
end

switch mode
	case 'independent'
		wpict = zeros(size(inpict));
		bpict = zeros(size(inpict));
		for c = 1:size(inpict,3);
			wt = inpict(:,:,c);
			bt = wt;
			wt(~wmask(:,:,c)) = extrema(1);
			bt(~bmask(:,:,c)) = extrema(2);
			wpict(:,:,c) = morphops(wt,se,'dilate');
			bpict(:,:,c) = morphops(bt,se,'erode');
		end
	case 'intersection'
		wmask = all(wmask,3);
		bmask = all(bmask,3);
		ftup = ones([1 size(inpict,3)]);
		wpict = morphops(replacepixels(ftup*extrema(1),inpict,~wmask),se,'dilate');
		bpict = morphops(replacepixels(ftup*extrema(2),inpict,~bmask),se,'erode');
	case 'union'
		wmask = any(wmask,3);
		bmask = any(bmask,3);
		ftup = ones([1 size(inpict,3)]);
		wpict = morphops(replacepixels(ftup*extrema(1),inpict,~wmask),se,'dilate');
		bpict = morphops(replacepixels(ftup*extrema(2),inpict,~bmask),se,'erode');
end


if invert
    outpict = imblend(extrema(2)-wpict,inpict,1,'darken rgb');
    outpict = imblend(extrema(2)-bpict,outpict,1,'lighten rgb');
else
	outpict = imblend(wpict,inpict,1,'lighten rgb');
    outpict = imblend(bpict,outpict,1,'darken rgb');
end

return


















