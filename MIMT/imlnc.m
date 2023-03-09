function outpict = imlnc(inpict,varargin)
%   IMLNC(INPICT, {MODE}, {OPTIONS})
%       Levels & Curves tool for I or RGB images. Designed as an 
%       extension of IMADJUST, HISTEQ, and ADJUSTHISTEQ with added features
%       to support automatic adjustment of multichannel images and the use of
%       non-RGB color channels. Also offers nonlinear contrast stretching.
%       For a GUI interface, see IMMODIFY
%
%   INPICT is a 3-D or 4-D RGB or RGBA image array
%       If passing a I/IA image array, some modes may be ignored:
%          'hsl', 'lchab' will be treated as 'independent'
%          'histeqlchab','ahisteqlchab' are treated as 'histeqrgb','ahisteqrgb'
%          modes which operate on hue or chroma conceptually require color information
%          and will throw an error if fed an I/IA image
%
%   MODE is one of the following:
%       IMADJUST MODES:
%       'independent' follows the behavior of imadjust(I,stretchlim(I))
%            In this mode, each channel has its levels stretched independently
%       'mean' (default) averages the levels returned from stretchlim(I)
%            This reduces skewing the color balance as 'independent' does.
%       'min' selects the levels with smallest influence (the outer extrema)
%       'max' selects the levels with the largest influence (the inner extrema)
%       'hsl' does levels stretching on L in HSL
%       'lchab' does levels stretching on L in CIE LCHab
%       'hue' stretches H in HuSLab
%       'chroma' stretches S in HuSLab based on C extrema in LCHab
%
%       HISTEQ MODES:
%       'histeqrgb' uses HISTEQ on channels indepentently
%       'histeqlchab' uses HISTEQ on L in CIE LCHab
%       'histeqh' uses HISTEQ on H in CIE LCHab
%       'histeqs' uses HISTEQ on S in HuSLab
%       'ahisteqrgb' uses ADAPTHISTEQ on channels indepentently
%       'ahisteqlchab' uses ADAPTHISTEQ on L in CIE LCHab
%       'ahisteqh' uses ADAPTHISTEQ on H in CIE LCHab
%       'ahisteqs' uses ADAPTHISTEQ on S in HuSLab
%
%   OPTIONS are specified as key-value pairs
%   imadjust modes accept the following:
%       'inrange' or 'in' specifies the input range [lo hi]
%            if inrange is unspecified or empty, it will be calculated automatically
%            as in IMADJUST(I), using the specified or default tolerance
%       'outrange' or 'out' specifies the output range [lo hi] (default [0 1])
%       'gamma' or 'g' specifies the gamma (default 1)
%       'contrast' or 'k' specifies the contrast amount (default 1)
%            When k>1, contrast is increased about the central gray value.
%            When k=1 and g=1, transfer curve is linear (default)
%       'tolerance' or 'tol' specifies the tolerance for autoadjusting (default 0.001)
%
%   histeq modes currently operate only using default parameters
%   Note that histeq modes inherit restrictions on minimum image dimensions
%
%   EXAMPLE:
%   % replicate behavior of imadjust(RGB,stretchlim(RGB))
%   outpict=imlnc(inpict,'independent','tol',0.01)
%   % auto-adjust limits and stretch contrast in L
%   outpict=imlnc(inpict,'lchab','k',1.1)
%   
%   CLASS SUPPORT:
%   Supports 'uint8', 'uint16', 'int16', 'single', and 'double'
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imlnc.html
% See also: IMLNCLITE, imbcg, imcurves, IMMODIFY, IMTWEAK, IMADJUSTFB, TONEMAP.

inrange = [];
outrange = [0 1];
k = 1;
g = 1;
tol = 0.001;
modestrings = {'independent','mean','min','max','hsl','lchab','histeqh','histeqs','ahisteqh','ahisteqs','hue','chroma','histeqrgb','ahisteqrgb'};
mode = 'average';

vk = 1;
while vk<=length(varargin)
    switch lower(varargin{vk})
		case modestrings
			mode = varargin{vk};
			vk = vk+1;
        case {'in','inrange'}
            inrange = reshape(varargin{vk+1},2,[]);
			vk = vk+2;
        case {'out','outrange'}
            outrange = reshape(varargin{vk+1},2,[]);
			vk = vk+2;
        case {'k','contrast'}
            k = varargin{vk+1};
			vk = vk+2;
        case {'g','gamma'}
            g = varargin{vk+1};
			vk = vk+2;
		case {'tol','tolerance'}
			tol = varargin{vk+1};
			vk = vk+2;
        otherwise
            error('IMLNC: unknown input parameter name %s',varargin{vk})
    end
end

numchans = size(inpict,3);
[inpict inclass] = imcast(inpict,'double');

if any(numchans == [2 4])
	alpha = inpict(:,:,end,:);
	inpict = inpict(:,:,end-1,:);
end
if any(numchans == [1 2]) 
	switch lower(mode)
		case {'hsl','lchab'}
			mode = 'independent';
		case 'histeqlchab'
			mode = 'histeqrgb';
		case 'ahisteqlchab'
			mode = 'ahisteqrgb';
		case {'histeqh','histeqs','ahisteqh','ahisteqs','hue','chroma'}
			error('IMLNC: the %s mode requires image to be RGB',lower(mode))
	end
end

lvvec = [0 1 outrange(1) outrange(2) g];

outpict = zeros(size(inpict));
for f = 1:size(inpict,4)
	protoimage = inpict(:,:,:,f);
	
	switch lower(mode)
		case 'independent'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			protoimage = imadjustFB(protoimage,inrange,[lvvec(3);lvvec(4)],lvvec(5));
			protoimage = stretchcurve(protoimage,k);
			
		case {'mean','average'}
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			lvvec(1:2) = mean(inrange,2)';
			protoimage = imadjustFB(protoimage,[lvvec(1);lvvec(2)],[lvvec(3);lvvec(4)],lvvec(5));
			protoimage = stretchcurve(protoimage,k);
			
		case 'min'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			lvvec(1:2) = [min(inrange(1,:)) max(inrange(2,:))];
			protoimage = imadjustFB(protoimage,[lvvec(1);lvvec(2)],[lvvec(3);lvvec(4)],lvvec(5));
			protoimage = stretchcurve(protoimage,k);
			
		case 'max'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			lvvec(1:2) = [max(inrange(1,:)) min(inrange(2,:))];
			protoimage = imadjustFB(protoimage,[lvvec(1);lvvec(2)],[lvvec(3);lvvec(4)],lvvec(5));
			protoimage = stretchcurve(protoimage,k);
			
		case 'hsl'
			inpictlch = rgb2hsl(protoimage);
			if isempty(inrange)
				inrange = stretchlimFB(inpictlch(:,:,3),tol);
			end
			adjustedL = imadjustFB(inpictlch(:,:,3),inrange,[lvvec(3);lvvec(4)],lvvec(5));
			adjustedL = stretchcurve(adjustedL,k);
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedL);
			protoimage = hsl2rgb(protoimage);
			
		case 'lchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = inpictlch(:,:,1)/100;
			if isempty(inrange)
				inrange = stretchlimFB(adjustedL,tol);
			end
			adjustedL = imadjustFB(adjustedL,inrange,[lvvec(3);lvvec(4)],lvvec(5));
			adjustedL = stretchcurve(adjustedL,k);
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'hue'
			% stretch/compress hue in HuSLab
			% not really useful but in abstract imagery
			% hue really needs to be rotated before doing this 
			% to avoid splitting hues
			% generally, histeqh or ahisteqh tend to do a better job
			% of increasing hue range without a lot of fiddling
			inpicthusl = rgb2husl(protoimage,'lab');
			adjustedH = inpicthusl(:,:,1)/360;
			if isempty(inrange)
				inrange = stretchlimFB(adjustedH,tol);
			end
			adjustedH = imadjustFB(adjustedH,inrange,[lvvec(3);lvvec(4)],lvvec(5));
			adjustedH = stretchcurve(adjustedH,k);
			protoimage = cat(3,adjustedH*360,inpicthusl(:,:,2:3));
			protoimage = husl2rgb(protoimage,'lab');
			
		case 'huelch'
			% stretch/compress hue in LCHab
			% not really useful but in abstract imagery
			% hue really needs to be rotated before doing this 
			% to avoid splitting hues
			% generally, histeqh or ahisteqh tend to do a better job
			% of increasing hue range without a lot of fiddling
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedH = inpictlch(:,:,3)/360;
			if isempty(inrange)
				inrange = stretchlimFB(adjustedH,tol);
			end
			adjustedH = imadjustFB(adjustedH,inrange,[lvvec(3);lvvec(4)],lvvec(5));
			adjustedH = stretchcurve(adjustedH,k);
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'chroma' 
			% locates maximal chroma in LAB, stretches relative saturation in HuSL
			% if inrange is specified, only operate in HuSL
			inpicthusl = rgb2husl(protoimage,'lab');
			adjustedS = inpicthusl(:,:,2)/100;
			
			if isempty(inrange)
				inpictlch = rgb2lch(protoimage,'lab');
				adjustedC = inpictlch(:,:,2)/100;
				inrange = stretchlimFB(adjustedC,tol);
				lvvec(1:2) = inrange;
				limidx = find(adjustedC >= lvvec(2),1);
				lvvec(1:2) = [0 adjustedS(limidx)];
			else
				lvvec(1:2) = inrange;
			end
			
			lvvec(2) = lvvec(2)+eps;  %this avoids issues if 3-ch gray images are passed (0 chroma)
			adjustedS = imadjustFB(adjustedS,[lvvec(1);lvvec(2)],[lvvec(3);lvvec(4)],lvvec(5));
			adjustedS = stretchcurve(adjustedS,k);
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');
			
		case 'ahisteqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = adapthisteq(inpictlch(:,:,1)/100);
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'ahisteqrgb'
			for c = 1:size(protoimage,3)
				protoimage(:,:,c) = adapthisteq(protoimage(:,:,c));
			end
			
		case 'histeqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = histeq(inpictlch(:,:,1)/100);
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'histeqrgb'
			for c = 1:size(protoimage,3)
				protoimage(:,:,c) = histeq(protoimage(:,:,c));
			end
			
		case 'histeqh'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedH = histeq(inpictlch(:,:,3)/360);
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
		
		case 'histeqs'
			inpicthusl = rgb2husl(protoimage,'lab');
			adjustedS = histeq(inpicthusl(:,:,2)/100);
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');
			
		case 'ahisteqh'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedH = adapthisteq(inpictlch(:,:,3)/360);
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
		
		case 'ahisteqs'
			inpicthusl = rgb2husl(protoimage,'lab');
			adjustedS = adapthisteq(inpicthusl(:,:,2)/100);
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');

		otherwise
			error('IMLNC: Unknown mode specified')
	end
		
	outpict(:,:,:,f) = protoimage;
end

if any(numchans == [2 4])
	outpict = cat(3,outpict,alpha);
end

outpict = imcast(outpict,inclass);

end

function R = stretchcurve(I,k)
	if k == 1
		R = I;
		return;
	end

	c = 0.5;
	mk = abs(k) < 1;
	mc = c < 0.5;
	if ~xor(mk,mc)
		pp = k; kk = k*c/(1-c);
	else
		kk = k; pp = (1-c)*k/c;
	end

	hi = I > c; lo = ~hi;
	R = zeros(size(I));
	R(lo) = 0.5*((1/c)*I(lo)).^kk;
	R(hi) = 1-0.5*((1-I(hi))*(1/(1-c))).^pp;
end

















