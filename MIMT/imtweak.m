function outpict = imtweak(inpict,model,cparams,varargin)
%   IMTWEAK(INPICT,COLORMODEL,CPARAMS,{OPTIONS})
%       allows simplified manipulation of RGB images or triplets using a 
%       specified color model.  
%
%   INPICT is an RGB/RGBA/RGBAAA image of any numeric image class.  Alpha is unmodified.
%       Multiframe images are supported.
%       May also be a 3-element vector (color tuple) or a Mx3 color table.
%
%   COLORMODEL is one of the following 
%       'rgb' for operations on [R G B] in RGB
%       'hsv' for operations on [H S V] in HSV 
%       'hsi' for operations on [H S I] in HSI
%       'hsl' for operations on [H S L] in HSL (see also ghlstool())
%
%       'hsy'    for operations on [H S Y] in HSY using polar YPbPr
%       'huslok' for operations on [H S L] in HuSL using polar OKLAB
%       'huslab' for operations on [H S L] in HuSL using CIELCHab
%       'husluv' for operations on [H S L] in HuSL using CIELCHuv
%
%       'hsyp'    for operations on [H S Y] in HSYp using polar YPbPr
%       'huslpok' for operations on [H S L] in HuSLp using polar OKLAB
%       'huslpab' for operations on [H S L] in HuSLp using CIELCHab
%       'huslpuv' for operations on [H S L] in HuSLp using CIELCHuv
%
%       'ypbpr' for operations on [Y Pb Pr] in YPbPr
%       'lab'   for operations on [L A B] in CIELab
%       'luv'   for operations on [L U V] in CIELuv
%       'srlab' for operations on [L A B] in SRLAB2
%       'oklab' for operations on [L A B] in OKLAB
%
%       'ychbr' for operations on [Y C H] in polar YPbPr
%       'lchab' for operations on [L C H] in CIELCHab
%       'lchuv' for operations on [L C H] in CIELCHuv
%       'lchsr' for operations on [L C H] in polar SRLAB2
%       'lchok' for operations on [L C H] in polar OKLAB
%   
%       HuSL is an adaptation of various LCH models with normalized chroma. 
%           It is particularly useful for tasks such as avoiding out-of-gamut 
%           values when increasing saturation or when rotating hue at high saturation.
%       HSY method uses polar operations in a normalized luma-chroma model
%           this is conceptually similar to HuSL, but the simpler math makes it about 2-3x as fast.
%       HuSLp and HSYp variants are normalized and constrained to the maximum rotationally-symmetric    
%           subset of the projected RGB space. This means HuSLp/HSYp avoid distortion of the chroma 
%           space when normalizing, preserving the uniformity of the parent space. Unfortunately, this 
%           also means it can only render colors near the neutral axis (pastels). 
%           These methods are mostly useful for relative specification of uniform colors.
%           The four models vary in the degree to which they cover the underlying RGB space:
%           HSYp (59%), HuSLpok (58%), HuSLpuv (54%), and HuSLpab (51%)
%       LCH and YCH operations are clamped to the extent of sRGB by chroma truncation prior to conversion.
%           The same is done for rectangular operations in LAB, LUV, SRLAB, OKLAB, and YPbPr.
%           
%   CPARAMS specifies the amounts by which color channels are to be altered.  
%       There are two supported conventions for this input:
%
%       The legacy specification is a 1x3 vector.  Each element corresponds to one of the channels in 
%       the specified color model.  Scaling is proportional for all channels except hue.  In the case of 
%       hue, specifying 1.00 will rotate hue 360 degrees (normalized modular addition).  Assuming an HSL model, 
%       CPARAMS=[0 1 1] results in no change to INPICT.  CPARAMS=[0.33 0.5 0.5] results in a 120 degree 
%       hue rotation and a 50% decrease of saturation and lightness. For channels other than hue, 
%       specifying a negative value will invert the channel and then apply the specified scaling.
%   
%       The full specification is a 2x3 matrix of the form [k1 k2 k3; os1 os2 os3].  The output of a given channel 
%       is simply linear: OUT = k*IN + os;.  This allows a more straightforward manipulation of the non-hue channels.  
%       CPARAMS=[1 1 1; 0 0 0] results in no change to INPICT.  Assuming an HSL model, CPARAMS=[0 0.5 0.5; 0.33 0 0.25] 
%       results in a 120 degree hue rotation and a 50% decrease of saturation. Lightness is both scaled and offset, 
%       effecting a global contrast reduction while maintaining central gray values. The scale factor associated with 
%       hue channels is not used. 
%       
%   OPTIONS includes the following keys:
%       'absolute' specifies that the offset parameters in a full 2x3 CPARAMS specification are denormalized values.
%         By default, offsets are normalized with respect to the nominal range of the given channel, just as hue 
%         offset is normalized in the legacy convention.  An absolute specification allows direct manipulation, which 
%         may be useful in adjusting hue or shifting colors in opponent models.  Unfortunately, not all models share 
%         the same scale, so using this option requires an understanding of the scale of the color model in use.
%       'truncatelch' (default), 'truncatergb', and 'notruncate' specify the truncation behavior
%         used for LCH/YCH models.
%
%
%   CLASS SUPPORT:
%   Supports 'uint8', 'uint16', 'int16', 'single', and 'double'
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imtweak.html
% See also: immodify, ghlstool, colorbalance, imlnc, imbcg, imcurves



if nargin < 3
	error('IMTWEAK: not enough arguments')
end

% defaults
absmode = false;
truncopt = 'truncatelch';

if numel(varargin)>0
	kv = 1;
	while kv<=numel(varargin)
		thisarg = varargin{kv};
		switch lower(thisarg)
			case {'truncatelch','truncatergb','notruncate'}
				truncopt = thisarg;
				kv = kv+1;
			case 'absolute'
				absmode = true;
				kv = kv+1;
			otherwise
				error('IMTWEAK: unknown option %s',thisarg)
		end
	end
end
	
% prepare CPARAMS
legacy = true;
if numel(cparams)~=3
	if size(cparams,1)==2 && size(cparams,2)==3
		k = cparams(1,:);
		os = cparams(2,:);
		legacy = false;
	else
		error('IMTWEAK: CPARAMS must either be a 1x3 vector or a 2x3 matrix')
	end
end


% is the image argument a color or a picture?
if size(inpict,2) == 3 && numel(size(inpict)) < 3
    inpict = ctflop(inpict);
    iscolorelement = 1;
else
    iscolorelement = 0;
end

[inpict alph] = splitalpha(inpict);
[inpict inclass] = imcast(inpict,'double');

sz0 = size(inpict);
nframes = size(inpict,4);

if sz0(3)~=3
	error('IMTWEAK: INPICT must be an RGB/RGBA/RGBAAA image or a color tuple/table')
end


switch lower(model)
	case 'hsy'
		outpict = processhsy(inpict,cparams,'normal',1,1,360);

	case 'hsyp'
		outpict = processhsy(inpict,cparams,'native',1,1.891101,360);
		
	case 'husluv'
		outpict = processhusl(inpict,cparams,'luv',100,100,360);
		
	case 'huslab'
		outpict = processhusl(inpict,cparams,'lab',100,100,360);
		
	case 'huslok'
		outpict = processhusl(inpict,cparams,'oklab',100,100,360);
		
	case 'huslpuv'
		outpict = processhusl(inpict,cparams,'luvp',100,100,360);
		
	case 'huslpab'
		outpict = processhusl(inpict,cparams,'labp',100,100,360);
		
	case 'huslpok'
		outpict = processhusl(inpict,cparams,'oklabp',100,100,360);
		
	case {'ypp','ypbpr'}
		outpict = processlab(inpict,cparams,'ypbpr',1,0.53351,truncopt);

	case 'lab'
		outpict = processlab(inpict,cparams,'lab',100,134.2,truncopt);
		
	case 'luv'
		outpict = processlab(inpict,cparams,'luv',100,180,truncopt);
		
	case 'srlab'
		outpict = processlab(inpict,cparams,'srlab',100,103,truncopt);
		
	case 'oklab'
		outpict = processlab(inpict,cparams,'oklab',100,32.249,truncopt);
		
	case {'ych','lchbr','ychbr'}
		outpict = processlch(inpict,cparams,'ypbpr',1,0.53351,360,truncopt);
		
	case 'lchab'
		outpict = processlch(inpict,cparams,'lab',100,134.2,360,truncopt);
		
	case 'lchuv'
		outpict = processlch(inpict,cparams,'luv',100,180,360,truncopt);
		
	case 'lchsr'	
		outpict = processlch(inpict,cparams,'srlab',100,103,360,truncopt);
		
	case 'lchok'	
		outpict = processlch(inpict,cparams,'oklab',100,32.249,360,truncopt);
		
	case 'rgb'
		outpict = zeros(sz0);
		if legacy
			if abs(cparams(1)) ~= 1
				outpict(:,:,1,:) = imclamp(((cparams(1) < 0)+sign(cparams(1))*inpict(:,:,1,:))*abs(cparams(1)));
			end
			if abs(cparams(2)) ~= 1
				outpict(:,:,2,:) = imclamp(((cparams(2) < 0)+sign(cparams(2))*inpict(:,:,2,:))*abs(cparams(2)));
			end
			if abs(cparams(3)) ~= 1
				outpict(:,:,3,:) = imclamp(((cparams(3) < 0)+sign(cparams(3))*inpict(:,:,3,:))*abs(cparams(3)));
			end
		else
			outpict(:,:,1,:) = os(1) + inpict(:,:,1)*k(1);
			outpict(:,:,2,:) = os(2) + inpict(:,:,2)*k(2);
			outpict(:,:,3,:) = os(3) + inpict(:,:,3)*k(3);
			outpict = imclamp(outpict);
		end
		
	case 'hsl'
		hmax = 360;
		outpict = zeros(sz0);
		if legacy
			for f = 1:nframes %#ok<*FXUP>
				hslpict = rgb2hsl(inpict(:,:,:,f));
				hslpict(:,:,1) = mod(hslpict(:,:,1)+cparams(1)*hmax,hmax);
				hslpict(:,:,2) = imclamp(((cparams(2) < 0)+sign(cparams(2))*hslpict(:,:,2))*abs(cparams(2)));
				hslpict(:,:,3) = imclamp(((cparams(3) < 0)+sign(cparams(3))*hslpict(:,:,3))*abs(cparams(3)));
				outpict(:,:,:,f) = hsl2rgb(hslpict);
			end
		else
			if ~absmode
				os = os.*[360 1 1];
			end
			for f = 1:nframes
				hslpict = rgb2hsl(inpict(:,:,:,f));
				hslpict(:,:,1) = mod(hslpict(:,:,1)+os(1),hmax); % k(1) is unused
				hslpict(:,:,2) = imclamp(os(2) + hslpict(:,:,2)*k(2));
				hslpict(:,:,3) = imclamp(os(3) + hslpict(:,:,3)*k(3));
				outpict(:,:,:,f) = hsl2rgb(hslpict);
			end
		end
				
	case 'hsi'
		hmax = 360;
		outpict = zeros(sz0);
		if legacy
			for f = 1:nframes
				hsipict = rgb2hsi(inpict(:,:,:,f));
				hsipict(:,:,1) = mod(hsipict(:,:,1)+cparams(1)*hmax,hmax);
				hsipict(:,:,2) = imclamp(((cparams(2) < 0)+sign(cparams(2))*hsipict(:,:,2))*abs(cparams(2)));
				hsipict(:,:,3) = imclamp(((cparams(3) < 0)+sign(cparams(3))*hsipict(:,:,3))*abs(cparams(3)));
				outpict(:,:,:,f) = hsi2rgb(hsipict);
			end
		else
			if ~absmode
				os = os.*[360 1 1];
			end
			for f = 1:nframes
				hsipict = rgb2hsi(inpict(:,:,:,f));
				hsipict(:,:,1) = mod(hsipict(:,:,1)+os(1),hmax); % k(1) is unused
				hsipict(:,:,2) = imclamp(os(2) + hsipict(:,:,2)*k(2));
				hsipict(:,:,3) = imclamp(os(3) + hsipict(:,:,3)*k(3));
				outpict(:,:,:,f) = hsi2rgb(hsipict);
			end
		end
	
	case 'hsv'
		outpict = zeros(sz0);
		if legacy
			for f = 1:nframes
				hsvpict = rgb2hsv(inpict(:,:,:,f));
				hsvpict(:,:,1) = mod(hsvpict(:,:,1)+cparams(1),1);
				hsvpict(:,:,2) = imclamp(((cparams(2) < 0)+sign(cparams(2))*hsvpict(:,:,2))*abs(cparams(2)));
				hsvpict(:,:,3) = imclamp(((cparams(3) < 0)+sign(cparams(3))*hsvpict(:,:,3))*abs(cparams(3)));
				outpict(:,:,:,f) = hsv2rgb(hsvpict);
			end
		else
			% relative scaling for offsets in HSV is trivial due to the channel scaling convention used by RGB2HSV()
			for f = 1:nframes
				hsvpict = rgb2hsv(inpict(:,:,:,f));
				hsvpict(:,:,1) = mod(hsvpict(:,:,1)+os(1),1); % k(1) is unused
				hsvpict(:,:,2) = imclamp(os(2) + hsvpict(:,:,2)*k(2));
				hsvpict(:,:,3) = imclamp(os(3) + hsvpict(:,:,3)*k(3));
				outpict(:,:,:,f) = hsv2rgb(hsvpict);
			end
		end
		
	otherwise
		error('IMTWEAK: unknown color model %s',model)
end

outpict = imcast(outpict,inclass);
outpict = joinalpha(outpict,alph);

if iscolorelement == 1
    outpict = ctflop(outpict);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% in order to avoid dealing with asymmetry in the range of A, B WRT zero
% legacy method doesn't support some of the silliness that the LCH methods do (i.e. chroma inversion)
function outpict = processlab(inpict,changevec,method,lmax,cmax,truncopt)
	outpict = zeros(sz0);
	if legacy
		for f = 1:nframes
			labpict = lch2lab(rgb2lch(inpict(:,:,:,f),method));
			labpict(:,:,1) = (lmax*(changevec(1) < 0)+sign(changevec(1))*labpict(:,:,1))*abs(changevec(1));
			labpict(:,:,2) = labpict(:,:,2)*changevec(2);
			labpict(:,:,3) = labpict(:,:,3)*changevec(3);
			outpict(:,:,:,f) = lch2rgb(lab2lch(labpict),method,truncopt);
		end
	else
		if ~absmode
			os = os.*[lmax cmax cmax];
		end
		for f = 1:nframes
			labpict = lch2lab(rgb2lch(inpict(:,:,:,f),method));
			labpict(:,:,1) = min(os(1) + labpict(:,:,1)*k(1),lmax);
			labpict(:,:,2) = os(2) + labpict(:,:,2)*k(2);
			labpict(:,:,3) = os(3) + labpict(:,:,3)*k(3);
			outpict(:,:,:,f) = lch2rgb(lab2lch(labpict),method,truncopt);
		end
	end
end

function outpict = processlch(inpict,changevec,method,lmax,cmax,hmax,truncopt)
	outpict = zeros(sz0);
	if legacy
		for f = 1:nframes
			lchpict = rgb2lch(inpict(:,:,:,f),method);
			lchpict(:,:,3) = mod(lchpict(:,:,3)+changevec(3)*hmax,hmax);
			lchpict(:,:,2) = (cmax*(changevec(2) < 0)+sign(changevec(2))*lchpict(:,:,2))*abs(changevec(2));
			lchpict(:,:,1) = (lmax*(changevec(1) < 0)+sign(changevec(1))*lchpict(:,:,1))*abs(changevec(1));
			outpict(:,:,:,f) = lch2rgb(lchpict,method,truncopt);
		end
	else
		if ~absmode
			os = os.*[lmax cmax hmax];
		end
		for f = 1:nframes
			lchpict = rgb2lch(inpict(:,:,:,f),method);
			lchpict(:,:,3) = mod(lchpict(:,:,3)+os(3),hmax); % k(3) is unused
			lchpict(:,:,2) = os(2) + lchpict(:,:,2)*k(2);
			lchpict(:,:,1) = os(1) + lchpict(:,:,1)*k(1);
			outpict(:,:,:,f) = lch2rgb(lchpict,method,truncopt);
		end
	end
end

function outpict = processhusl(inpict,changevec,method,lmax,smax,hmax)
	outpict = zeros(sz0);
	if legacy
		for f = 1:nframes
			huslpict = rgb2husl(inpict(:,:,:,f),method);
			huslpict(:,:,1) = mod(huslpict(:,:,1)+changevec(1)*hmax,hmax);
			huslpict(:,:,2) = (smax*(changevec(2) < 0)+sign(changevec(2))*huslpict(:,:,2))*abs(changevec(2));
			huslpict(:,:,3) = (lmax*(changevec(3) < 0)+sign(changevec(3))*huslpict(:,:,3))*abs(changevec(3));
			outpict(:,:,:,f) = husl2rgb(huslpict,method);
		end
	else
		if ~absmode
			os = os.*[hmax smax lmax];
		end
		for f = 1:nframes
			huslpict = rgb2husl(inpict(:,:,:,f),method);
			huslpict(:,:,1) = mod(huslpict(:,:,1)+os(1),hmax); % k(1) is unused
			huslpict(:,:,2) = os(2) + huslpict(:,:,2)*k(2);
			huslpict(:,:,3) = os(3) + huslpict(:,:,3)*k(3);
			outpict(:,:,:,f) = husl2rgb(huslpict,method);
		end
	end
end

function outpict = processhsy(inpict,changevec,method,lmax,smax,hmax)
	outpict = zeros(sz0);
	if legacy	
		for f = 1:nframes
			hsypict = rgb2hsy(inpict(:,:,:,f),method);
			hsypict(:,:,1) = mod(hsypict(:,:,1)+changevec(1)*hmax,hmax);
			hsypict(:,:,2) = (smax*(changevec(2) < 0)+sign(changevec(2))*hsypict(:,:,2))*abs(changevec(2));
			hsypict(:,:,3) = (lmax*(changevec(3) < 0)+sign(changevec(3))*hsypict(:,:,3))*abs(changevec(3));
			outpict(:,:,:,f) = hsy2rgb(hsypict,method);
		end
	else
		if ~absmode
			os = os.*[hmax smax lmax];
		end
		for f = 1:nframes
			hsypict = rgb2hsy(inpict(:,:,:,f),method);
			hsypict(:,:,1) = mod(hsypict(:,:,1)+os(1),hmax); % k(1) is unused
			hsypict(:,:,2) = os(2) + hsypict(:,:,2)*k(2);
			hsypict(:,:,3) = os(3) + hsypict(:,:,3)*k(3);
			outpict(:,:,:,f) = hsy2rgb(hsypict,method);
		end
	end
end

end % END OF MAIN SCOPE




