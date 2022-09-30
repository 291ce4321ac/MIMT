function outpict = rgb2husl(inpict,varargin)
%   RGB2HUSL(INPICT,{MODE})
%       converts an RGB input image to HUSL (human-friendly HSL), which is an adaptation
%       of LCH with normalized chroma.  This is particularly useful for tasks such as
%       avoiding out-of-gamut values when rotating hue at high chroma.  
%
%       HuSLp variants are normalized and constrained to the maximum biconic subset of the projected RGB space.  
%       This means HuSLp avoids distortion of the chroma space when normalizing, preserving the uniformity 
%       of the parent space. Unfortunately, this also means it can only render colors near the neutral axis (pastels). 
%
%       HuSLn modes are variants of HuSLp, wherein S is still normalized WRT the maximal rotationally-symmetric subset
%       but specified chroma is constrained only by the extent of the projected RGB space.  In this mode, 100% S still refers
%       to the extent of HuSLp, but color points can be specified with S>100%, so long as they stay within the RGB cube.
%       This allows uniform access to the entire projected RGB space, unlike HuSLp; it also allows for data truncation
%       to occur before conversion, unlike most LCH methods or other HuSL/HuSLp implementations.
%
%       HuSLp and HuSLn methods are mostly useful for relative specification of uniform colors.
%
%   INPICT is an RGB image of any standard image class
%
%   MODE specifies the colorspace to normalize to the extent of sRGB
%       'luv' uses CIELCHuv (default)
%       'lab' uses CIELCHab
%       'oklab' uses OKLAB
%       'luvp' is the HuSLp variant of 'luv'
%       'labp' is the HuSLp variant of 'lab'
%       'oklabp' is the HuSLp variant of 'oklab'
%       'luvn' is the HuSLn variant of 'luv'
%       'labn' is the HuSLn variant of 'lab'
%       'oklabn' is the HuSLn variant of 'oklab'
%   Additionally specifying 'aligned' will align H to the red corner of the RGB cube
%
%   The above methods are based on lookup tables for speed on large images.  This isn't perfect, 
%   but if a direct method is desired, specify 'luvcalc' or 'labcalc'.  See MAXCHROMA() for details.
%
%   output is a HUSL image with channel ranges:
%       H \in [0 360)
%       S \in [0 100]
%       L \in [0 100]
%
%   See also: RGB2HSY, HSY2RGB, HUSL2RGB, RGB2LCH, LCH2RGB, MAXCHROMA, CSVIEW.

%   The LUV method is a fairly direct adaptation of the C and Lua implementations 
%   by Alexei Boronine et al:  http://www.husl-colors.org/

for k = 1:length(varargin);
    switch lower(varargin{k})
        case 'aligned'
            aligned = true;
        case {'labn','luvn','oklabn'}
            maxbounding = true;
            mode = varargin{k};
            mode = [mode(1:3) 'p'];
        case {'lab','labp','oklabp','luv','luvp','oklab','luvcalc','labcalc','oklabcalc'}
            mode = varargin{k};
        otherwise
            error('RGB2HUSL: unknown option %s',varargin{k})
    end
end

if ~exist('aligned','var')
    aligned = false;
end
if ~exist('maxbounding','var')
    maxbounding = false;
end
if ~exist('mode','var')
    mode = 'luv';
end
mode = mode(mode ~= ' ');

inpict = imcast(inpict,'double');
inpict = min(max(inpict,0),1);

% convert to polar LCHuv/LCHab
% COLORSPACE() won't work for LAB here because OOG values may be produced
% due to concavity near the yellow corner.  Local method avoids COLORSPACE's 
% handling of negative RGB values.
if any(strcmpi(mode,{'luv','luvcalc','luvp'}))
    lchpict = rgb2lch(inpict,'luv');
elseif any(strcmpi(mode,{'lab','labcalc','labp'}))
    lchpict = rgb2lch(inpict,'lab');
elseif any(strcmpi(mode,{'oklab','oklabcalc','oklabp'}))
    lchpict = rgb2lch(inpict,'oklab');
end

L = lchpict(:,:,1);
C = lchpict(:,:,2);
H = lchpict(:,:,3);

% locally normalize C for all L,H
switch lower(mode(mode ~= ' '))
    case 'luvcalc'
        Cnorm = maxchroma('luvcalc','l',L,'h',H);
    case 'luv'
        Cnorm = maxchroma('luv','l',L,'h',H);
    case 'luvp'
        Cnorm = maxchroma('luvp','l',L);
    case 'labcalc'
        Cnorm = maxchroma('labcalc','l',L,'h',H);
    case 'lab'
        Cnorm = maxchroma('lab','l',L,'h',H);
    case 'labp'
        Cnorm = maxchroma('labp','l',L);	
	case 'oklabcalc'
        Cnorm = maxchroma('oklabcalc','l',L,'h',H);
	case 'oklab'
        Cnorm = maxchroma('oklab','l',L,'h',H);
	case 'oklabp'
        Cnorm = maxchroma('oklabp','l',L);
end

% if specified, bound pastel modes to the maximal extent of RGB
if maxbounding
    switch lower(mode(mode ~= ' '))
        case 'labp'
            Climit = maxchroma('lab','l',L,'h',H);
        case 'luvp'
            Climit = maxchroma('luv','l',L,'h',H);
		case 'oklabp'
            Climit = maxchroma('oklab','l',L,'h',H);	
    end
    C = min(C./Cnorm*100,Climit./Cnorm*100);
else
    C = min(C./Cnorm*100,100);
end

outpict(:,:,1) = L;
outpict(:,:,2) = C;
if aligned
    if any(strcmpi(mode,{'luv','luvcalc','luvp'}))
        outpict(:,:,3) = mod(H-12.1667,360);
    elseif any(strcmpi(mode,{'lab','labcalc','labp'}))
        outpict(:,:,3) = mod(H-39.9972,360);
	elseif any(strcmpi(mode,{'oklab','oklabcalc','oklabp'}))
        outpict(:,:,3) = mod(H-29.2339,360);
    end
else
    outpict(:,:,3) = H;
end

outpict = flipd(outpict,3);

end







