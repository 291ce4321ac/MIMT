function outpict = hsy2rgb(inpict,mode)
%   HSY2RGB(INPICT, {MODE})
%       Extract an rgb image from a normalized polar adaptation of YPbPr
%       This is offered as an unconventional alternative to HuSL or
%       LCH for general image editing without causing large perceived
%       brightness distortions when changing hue/saturation
%
%       This actually uses YPbPr just for numeric convenience
%       Chroma is normalized and clamped in this method.
%
%       Normalization forces color points to stay within the RGB cube.
%       This prevents clipping when rotating H for points with high S.
%       Furthermore, it mimics HuSL behavior in that S is constrained.
%       One could debate whether this is desired behavior.
%
%       HSYp variant is normalized and constrained to the maximum biconic subset of the projected RGB space.  
%       This means HSYp avoids distortion of the chroma space when normalizing, preserving the uniformity 
%       of the parent space. Unfortunately, this also means it can only render colors near the neutral axis (pastels). 
%
%       HSYn variant is still normalized WRT the maximal rotationally-symmetric subset as in HSYp
%       but specified chroma is constrained only by the extent of the projected RGB space.  In this mode, 
%       100% S still refers to the extent of HSYp, but color points can be specified with S>100%, 
%       so long as they stay within the RGB cube. This allows uniform access to the entire projected RGB space, 
%       unlike HSYp; it also allows for data truncation to occur before conversion, unlike YPbPr methods.
%
%       HSYp and HSYn are mostly useful for relative specification of uniform colors.
%
%   MODE specifies the normalization and constraint behavior.  
%       'normal' normalizes to the extent of the projected RGB space (HSY) (default)
%       'pastel' normalizes to the maximal biconic subset of the projected RGB space (HSYp)
%       'native' normalizes as in 'pastel' mode, but constrains as in 'normal' mode (HSYn)
%
%   INPICT is of type double, in the range:
%       H \in [0 360)
%       S \in [0 1]
%       Y \in [0 1]
%   
%   Output is of type double, in the range [0 1]
%
%   See also: RGB2HSY, RGB2HUSL, HUSL2RGB, RGB2LCH, LCH2RGB, MAXCHROMA, CSVIEW.

% Since this method uses a LUT to normalize S, this dimension is quantized.


modestrings = {'normal','pastel','native','normalcalc','pastelcalc','nativecalc'};
uselut = true;

if ~exist('mode','var')
	mode = 'normal';
else
	mode = lower(mode);
end

if ~strismember(mode,modestrings)
	error('HSY2RGB: unknown mode %s\n',mode)
end

if strcmp(mode(end-3:end),'calc')
	uselut = false;
	mode = mode(1:end-4);
end
    
H = mod(inpict(:,:,1),360);
S = max(inpict(:,:,2),0);
Y = max(min(inpict(:,:,3),1),0);

C = zeros(size(S));

% align H with PbPr plane
% instead of cube corner
H = mod(H+108.6482,360);

% clamp and denormalize S
if strcmpi(mode,'normal')
	H(isnan(H)) = 0;
    S = min(S,1);
	if uselut
		Cmax = maxchroma('ypp','y',Y,'h',H);
	else
		Cmax = maxchroma('yppcalc','y',Y,'h',H);
	end
	C = S.*Cmax;
elseif strcmpi(mode,'pastel')
    S = min(S,1);
	Cpastel = maxchroma('yppp','y',Y);
	C = S.*Cpastel;
elseif strcmpi(mode,'native') 
    H(isnan(H)) = 0;
	if uselut
		Cmax = maxchroma('ypp','y',Y,'h',H);
	else
		Cmax = maxchroma('yppcalc','y',Y,'h',H);
	end
	Cpastel = maxchroma('yppp','y',Y);
    S = min(S,Cmax./Cpastel);
	C = S.*Cpastel;
end

yc(:,:,2) = C.*cosd(H); % B
yc(:,:,3) = C.*sind(H); % R
yc(:,:,1) = Y;

Ai = gettfm('ypbpr_inv');
outpict = imappmat(yc,Ai);

outpict = max(min(outpict,1),0);

end




