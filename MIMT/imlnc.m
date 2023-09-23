function outpict = imlnc(inpict,varargin)
%  IMLNC(INPICT, {MODE}, {PARAMETERS})
%    Levels & Curves tool for I or RGB images. Designed as an extension 
%    of IMADJUST with added features to support automatic adjustment of 
%    multichannel images and the use of non-RGB color channels. 
%
%    For a GUI interface, see immodify().
%    Histogram EQ functionality has been removed for purposes of clarity.  
%    See histeqtool() for those features.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%    Multiframe images are supported.  Alpha content is passed unmodified.
%    Modes which operate on hue or chroma conceptually require color information
%    and will throw an error if fed an I/IA image. All modes except 'hue', and 
%    'chroma' will be treated as 'independent' if the input is I/IA.
%
%  MODE specifies how color images are handled:
%    'independent' follows the behavior of imadjust(I,stretchlim(I))
%       In this mode, each channel has its levels stretched independently
%    'mean' (default) averages the levels returned from stretchlim(I)
%       This reduces skewing the color balance as 'independent' does.
%    'min' selects the levels with smallest influence (the outer extrema)
%    'max' selects the levels with the largest influence (the inner extrema)
%    'hsl' does levels stretching on L in HSL
%    'lchab' does levels stretching on L in CIE LCHab
%    'hue' stretches H in HuSLab
%    'chroma' stretches S in HuSLab based on C extrema in LCHab
%
%  PARAMETERS are specified as key-value pairs
%    'inrange' or 'in' specifies the input range [lo hi]
%       If inrange is unspecified or empty, it will be calculated automatically
%       as in IMADJUST(I), using the specified or default tolerance
%    'outrange' or 'out' specifies the output range [lo hi] (default [0 1])
%    'gamma' or 'g' specifies the gamma (default 1)
%       When g>1, transfer curve is stretched downward, darkening the image by
%       reducing shadow contrast and increasing highlight contrast.
%    'sgamma' or 'sg' specifies a symmetric gamma curve (default 1)
%       Reduces extreme contrast near black for sg<1 when compared to 'g'.
%       Reduces extreme contrast near white for sg>1 when compared to 'rg'.
%       Also allows for symmetric shifts when combined with 'k'.  See help sgamma.
%       While a symmetric curve can be achieved with a combination of 'g' and 'rg',
%       'sg' is a convenience and is already scaled to match the parameter sensitivity 
%       customary of a simple power function like 'g' or 'rg'.
%    'rgamma' or 'rg' specifies a reversed gamma curve (default 1)
%       Where a normal gamma curve has strongest influence over dark regions,
%       this parameter has strongest influence over bright regions. A combination 
%       of 'g' and 'rg' can be used to bend the curve in various ways.
%    'contrast' or 'k' specifies the contrast amount (default 1)
%       When k>1, contrast is increased about the central gray value.
%       Similar to 'sg', this functionality can be obtained through a combination
%       of 'g' and 'rg', but a single-term contrast parameter is a convenience.
%    'tolerance' or 'tol' specifies the tolerance for autoadjusting (default 0.001)
%
%  Output class is inherited from input
% 
%  EXAMPLE:
%  % replicate behavior of imadjust(RGB,stretchlim(RGB))
%    outpict = imlnc(inpict,'independent','tol',0.01)
%  % auto-adjust limits and stretch contrast in L
%    outpict = imlnc(inpict,'lchab','k',1.1)
%  % do the same thing without altering input limits
%    outpict = imlnc(inpict,'lchab','in',[0 1],'k',1.1)
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imlnc.html
% See also: imlnclite, imbcg, imcurves, immodify, imtweak, imadjustFB

inrange = [];
outrange = [0 1];
k = 1;
g = 1;
sg = 1; 
rg = 1;
tol = 0.001;
modestrings = {'independent','mean','min','max','hsl','lchab','hue','chroma'};
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
            g = max(varargin{vk+1},0);
			vk = vk+2;
		case {'sg','sgamma'}
            sg = max(varargin{vk+1},0);
			vk = vk+2;
		case {'rg','rgamma'}
            rg = max(varargin{vk+1},eps);
			vk = vk+2;
		case {'tol','tolerance'}
			tol = max(varargin{vk+1},0);
			vk = vk+2;
        otherwise
            error('IMLNC: unknown input parameter name %s',varargin{vk})
    end
end

numchans = size(inpict,3);
[inpict inclass] = imcast(inpict,'double');
[inpict alpha] = splitalpha(inpict);

% single-channel inputs simplify
if any(numchans == [1 2]) 
	if strismember(lower(mode),{'hue','chroma'})
		error('IMLNC: the %s mode requires image to be RGB',lower(mode))
	else
		mode = 'independent';
	end
end

outpict = zeros(size(inpict));
for f = 1:size(inpict,4)
	protoimage = inpict(:,:,:,f);
	
	switch lower(mode)
		case 'independent'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			protoimage = corexform(protoimage,inrange,outrange,g,sg,rg,k);
			
		case {'mean','average'}
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			inrange = mean(inrange,2)';
			protoimage = corexform(protoimage,inrange,outrange,g,sg,rg,k);
			
		case 'min'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			inrange = [min(inrange(1,:)) max(inrange(2,:))];
			protoimage = corexform(protoimage,inrange,outrange,g,sg,rg,k);
			
		case 'max'
			if isempty(inrange)
				inrange = stretchlimFB(protoimage,tol);
			end
			inrange = [max(inrange(1,:)) min(inrange(2,:))];
			protoimage = corexform(protoimage,inrange,outrange,g,sg,rg,k);
			
		case 'hsl'
			inpictlch = rgb2hsl(protoimage);
			if isempty(inrange)
				inrange = stretchlimFB(inpictlch(:,:,3),tol);
			end
			adjustedL = corexform(inpictlch(:,:,3),inrange,outrange,g,sg,rg,k);
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedL);
			protoimage = hsl2rgb(protoimage);
			
		case 'lchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = inpictlch(:,:,1)/100;
			if isempty(inrange)
				inrange = stretchlimFB(adjustedL,tol);
			end
			adjustedL = corexform(adjustedL,inrange,outrange,g,sg,rg,k);
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
			adjustedH = corexform(adjustedH,inrange,outrange,g,sg,rg,k);
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
			adjustedH = corexform(adjustedH,inrange,outrange,g,sg,rg,k);
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
				limidx = find(adjustedC >= inrange(2),1);
				inrange = [0 adjustedS(limidx)];
			end
			
			if diff(inrange) == 0
				%this avoids issues if 3-ch gray images are passed (0 chroma)
				inrange(2) = inrange(2)+eps;  
			end
			
			adjustedS = corexform(adjustedS,inrange,outrange,g,sg,rg,k);
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');
			
		otherwise
			error('IMLNC: Unknown mode specified')
	end
		
	outpict(:,:,:,f) = protoimage;
end

outpict = joinalpha(outpict,alpha);
outpict = imcast(outpict,inclass);

end % END MAIN SCOPE

function out = corexform(in,inrange,outrange,g,sg,rg,k)
	out = imadjustFB(in,inrange,outrange,g);
	out = rgamma(out,rg); % reverse gamma
	out = sgamma(out,sg); % symmetric gamma
	out = stretchcurve(out,k);
end

function out = rgamma(in,rg)
	if rg == 1
		out = in;
	else
		out = 1-impow(1-in,1/rg);
	end
end













