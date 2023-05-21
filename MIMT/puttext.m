function outpict = puttext(BG,thistext,varargin)
%  OUTPICT = PUTTEXT(INPICT,TEXT,{OPTIONS})
%  A simple tool to insert text into an image using image composition.  
%  All text is monospaced and binarized (no antialiasing).
%  
%  INPICT is an image of any standard image class.  Multiframe images are not supported.
%  TEXT is a char vector containing text compatible with CP437
%  OPTIONS include the following key-value pairs
%    'font' specifies the font to be used (default 'ibm-iso-16x9')
%       See help textim() for the available fonts.
%    'fgcolor' is a tuple specifying the text foreground color. (default 1)
%       This tuple may be I/IA/RGB/RGBA, and is expected to be unit-scale.
%    'bgcolor' similarly specifies the text background color (default 0)
%    'gravity' specifies the location from which the text placement is referenced.
%       Supported 'c','n','w','s','e','nw','sw','se','ne' (default 'nw')
%    'offset' specifies an offset in the SE direction (pixels [y x], default [0 0])
%    'angle' specifies the rotation angle in degrees (default 0)
%       Given that the text is bitmapped, non-ortho rotations may be poorly legible.
%    'padding' specifies how much background padding should surround the text (default [1 1])
%    'scale' is a positive integer scalar specifying how much the text should be scaled up.
%       (default 1)
%
%  Output class is inherited from input.
%
%  See also: textim, replacepixels, imblend, imstacker


% defaults
fgalpha = 1;
bgalpha = 1;
fontname = 'ibm-iso-16x9';
offset = [0 0];
fgcolor = 1;
bgcolor = 0;
padsize = [1 1];
scale = 1;
gravity = 'nw';
angle = 0;

if nargin > 2
	for k = 1:2:numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'font'
				fontname = varargin{k+1};
			case 'offset'
				offset = varargin{k+1};
			case {'fgc','fgcolor'}
				fgcolor = varargin{k+1};
			case {'bgc','bgcolor'}
				bgcolor = varargin{k+1};
			case 'padsize'
				padsize = varargin{k+1};
			case 'scale'
				scale = varargin{k+1};
			case 'gravity'
				gravity = varargin{k+1};
			case 'angle'
				angle = varargin{k+1};
			otherwise
				error('PUTTEXT: unknown option %s',thisarg)
		end
	end
end

% split color parameters
[fcc fca] = chancount(ctflop(fgcolor));
[bcc bca] = chancount(ctflop(bgcolor));
if fca
	fgalpha = fgcolor(end);
	fgcolor = fgcolor(1:fcc);
end
if bca
	bgalpha = bgcolor(end);
	bgcolor = bgcolor(1:bcc);
end
[~,originalhasalpha] = chancount(BG);

% create text mask
tmask = textim(thistext,fontname);

% trim to symmetry and pad
tmask = crop2box(tmask);
tmask = padarrayFB(tmask,padsize,0,'both');

% scale
scale = max(round(scale),1);
if scale ~= 1
	tmask = imresizeFB(tmask,scale,'nearest');
end

% construct fg image to insert
FG = replacepixels(fgcolor,bgcolor,tmask);
FGa = interp1([0 1],[bgalpha fgalpha],tmask,'nearest');
FG = joinalpha(FG,FGa);

% rotate if needed
if angle ~= 0
	FG = imrotateFB(FG,angle,'nearest');
end

% stack the images
ST = imstacker({FG BG},'gravity',gravity,'offset',[offset; 0 0],'size','last');

% do all this to avoid full-frame composition
% this is about 40% faster than just collapsing ST with mergedown() directly
% this could probably be done with roifilter() too

% retrieve expanded/offset/cropped/padded FG
FGa = ST(:,:,end,1); % get transformed FGa
[~,yr,xr] = crop2box(FGa); % get roi location

% skip out early if text is entirely outside image area
if isempty(yr)
	outpict = BG; % nothing to add
	return; % just return the original image
end

% compose ROI
FGroi = ST(yr,xr,:,1); % get FG roi
BGroi = ST(yr,xr,:,2); % get BG roi
BGroi = replacepixels(FGroi,BGroi,1);

% insert ROI
outpict = ST(:,:,:,2);
outpict(yr,xr,:) = BGroi;

% get rid of extraneous alpha if the image didn't have alpha
if ~originalhasalpha
	outpict = splitalpha(outpict);
end

% prepare output
outpict = imcast(outpict,class(BG));


























