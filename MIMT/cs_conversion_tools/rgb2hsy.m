function outpict = rgb2hsy(inpict,mode)
%   RGB2HSY(INPICT, {MODE})
%       Convert an rgb image to a normalized polar adaptation of YPbPr
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
%       'normal' normalizes and constrains to the extent of the projected RGB space (HSY) (default)
%       'pastel' normalizes and constrains to the maximal biconic subset of the projected RGB space (HSYp)
%       'native' normalizes as in 'pastel' mode, but constrains as in 'normal' mode (HSYn)
%
%   Output is of type double, in the range:
%       H \in [0 360)
%       S \in [0 1]
%       Y \in [0 1]
%
%   See also: HSY2RGB, RGB2HUSL, HUSL2RGB, RGB2LCH, LCH2RGB, MAXCHROMA, CSVIEW.

% Since this method uses a LUT to normalize S, this dimension is quantized.

modestrings = {'normal','pastel','native','normalcalc','pastelcalc','nativecalc'};
uselut = true;

if ~exist('mode','var')
	mode = 'normal';
else
	mode = lower(mode);
end

if ~strismember(mode,modestrings)
	error('RGB2HSY: unknown mode %s\n',mode)
end

if strcmp(mode(end-3:end),'calc')
	uselut = false;
	mode = mode(1:end-4);
end

pict = imcast(inpict,'double');
A = gettfm('ypbpr');
yc = imappmat(pict,A);

H = mod(atan2(yc(:,:,3),yc(:,:,2))*180/pi,360); % color angle
C = sqrt(yc(:,:,3).^2+yc(:,:,2).^2); % color magnitude
Y = yc(:,:,1);

S = zeros(size(C));

% normalize and clamp S
if strcmpi(mode,'normal')
	if uselut
		Cmax = maxchroma('ypp','y',Y,'h',H);
	else
		Cmax = maxchroma('yppcalc','y',Y,'h',H);
	end
	S = C./Cmax;
	S = min(S,1);
elseif strcmpi(mode,'pastel')
	Cpastel = maxchroma('yppp','y',Y);
	S = C./Cpastel;
	S = min(S,1);
elseif strcmpi(mode,'native') 
	if uselut
		Cmax = maxchroma('ypp','y',Y,'h',H);
	else
		Cmax = maxchroma('yppcalc','y',Y,'h',H);
	end
	Cpastel = maxchroma('yppp','y',Y);
	S = C./Cpastel;
	S = min(S,Cmax./Cpastel);
end

% align output H with cube corner
% instead of PbPr plane
H = mod(H-108.6482,360); 

outpict = cat(3,H,S,Y);

end









