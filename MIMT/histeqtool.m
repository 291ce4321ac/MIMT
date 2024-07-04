function [outpict T] = histeqtool(inpict,mode,varargin)
%  OUTPICT = HISTEQTOOL(INPICT,MODE,{TRUNCOPT},{EXTRAARGS})
%  [OUTPICT TF] = HISTEQTOOL(INPICT,MODE,{TRUNCOPT},{EXTRAARGS})
%    Simple wrapper tool for histeqFB() and adapthisteqFB() for simplified use
%    on both I and RGB images.  This makes it simpler to apply these tools to 
%    components of color images.
%  
%    These tools used to be part of imlnc()
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%    Multiframe images are supported.  Alpha content is passed unmodified.
%
%  MODE specifies how color images are handled:
%    Modes which use histeqFB():
%      'histeqrgb' operates on I/RGB channels independently
%      'histeqhsv' operates on V in HSV
%      'histeqhsl' operates on L in HSL
%      'histeqlchab' operates on L in CIE LCHab
%      'histeqh' operates on H in CIE LCHab
%      'histeqs' operates on S in HuSLab
%    Modes which use adapthisteqFB():
%      'ahisteqrgb' operates on I/RGB channels independently
%      'ahisteqhsv' operates on V in HSV
%      'ahisteqhsl' operates on L in HSL
%      'ahisteqlchab' operates on L in CIE LCHab
%      'ahisteqh' operates on H in CIE LCHab
%      'ahisteqs' operates on S in HuSLab
%    For I/IA inputs, requesting HSV/HSL/LCH modes is the same as requesting I/RGB mode.
%    Modes which operate on H/S alone conceptually require color information
%    and will leave the input unchanged if fed an I/IA image. Modes which operate on
%    H alone are blind to the distribution of H, and may produce discontinuities.
%
%  TRUNCOPT optionally specifies the truncation behavior used in LCH modes.  
%    Supported modes are 'notruncate','truncatergb','truncatelch','truncatelchcalc'.
%    Default is 'truncatelch'. See lch2rgb() for more information.
% 
%  EXTRAARGS are any extra arguments to be passed to histeqFB() or adapthisteqFB().
%    When using these, bear in mind that these MIMT tools differ slightly from their
%    IPT counterparts if IPT is not installed.  All data passed to these functions 
%    internally will be unit-scale float, regardless of the class of INPICT.
% 
%  TF is an optional output argument associated with histeq() modes.  When relevant, 
%    TF will be a FxC cell array containing numeric vectors, where F is the number of
%    frames in INPICT, and C is the number of channels being transformed (1 or 3). 
%    If requested for ahisteq modes, TF will be an empty cell.
%
%  Output class is inherited from input
%
%  See also: imlnc(), histeqFB(), adapthisteqFB()

modestrings = {'histeqrgb','histeqhsv','histeqhsl','histeqlchab','histeqh','histeqs',...
			'ahisteqrgb','ahisteqhsv','ahisteqhsl','ahisteqlchab','ahisteqh','ahisteqs'};
if ~strismember(mode,modestrings)
	error('HISTEQTOOL: unsupported mode %s',lower(mode))
end

% handle truncation option spec
truncmode = 'truncatelch'; % default
truncmodes = {'notruncate','truncatergb','truncatelch','truncatelchcalc'};
if ~isempty(varargin) && ischar(varargin{1}) && strismember(varargin{1},truncmodes)
	truncmode = varargin{1};
	varargin(1) = [];
end
		
% prepare image
[inpict inclass] = imcast(inpict,'double');
[inpict alpha] = splitalpha(inpict);
sz = imsize(inpict);

% single-channel inputs simplify based on implied intent
[sz(3),~] = chancount(inpict);
if sz(3) == 1 
	switch lower(mode)
		case {'histeqhsv','histeqhsl','histeqlchab'}
			% we weren't targeting color content anyway
			mode = 'histeqrgb';
		case {'ahisteqhsv','ahisteqhsl','ahisteqlchab'}
			% we weren't targeting color content anyway
			mode = 'ahisteqrgb';
		case {'histeqh','histeqs','ahisteqh','ahisteqs'}
			% if there's no color content, then there's nothing to be done.
			outpict = joinalpha(inpict,alpha);
			return
	end
end

% preallocate T
switch lower(mode)
	case 'histeqrgb'
		T = cell(sz(4),sz(3));
	case {'histeqhsv','histeqhsl','histeqlchab','histeqh','histeqs'}
		T = cell(sz(4),1);
	otherwise
		T = {};
end

% do the things
outpict = zeros(sz);
for f = 1:sz(4)
	protoimage = inpict(:,:,:,f);
	
	switch lower(mode)
		% HISTEQ
		case 'histeqrgb'
			for c = 1:sz(3)
				[protoimage(:,:,c) T{f,c}] = histeqFB(protoimage(:,:,c),varargin{:});
			end
			
		case 'histeqhsv'
			inpicthsx = rgb2hsv(protoimage);
			[adjustedL T{f}] = histeqFB(inpicthsx(:,:,3),varargin{:});
			protoimage = cat(3,inpicthsx(:,:,1:2),adjustedL);
			protoimage = hsv2rgb(protoimage);
			
		case 'histeqhsl'
			inpicthsx = rgb2hsl(protoimage);
			[adjustedL T{f}] = histeqFB(inpicthsx(:,:,3),varargin{:});
			protoimage = cat(3,inpicthsx(:,:,1:2),adjustedL);
			protoimage = hsl2rgb(protoimage);
			
		case 'histeqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			[adjustedL T{f}] = histeqFB(inpictlch(:,:,1)/100,varargin{:});
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab',truncmode);
			
		case 'histeqh'
			inpictlch = rgb2lch(protoimage,'lab');
			[adjustedH T{f}] = histeqFB(inpictlch(:,:,3)/360,varargin{:});
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab',truncmode);
		
		case 'histeqs'
			inpicthusl = rgb2husl(protoimage,'lab');
			[adjustedS T{f}] = histeqFB(inpicthusl(:,:,2)/100,varargin{:});
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');
			
		% ADAPTHISTEQ
		case 'ahisteqrgb'
			for c = 1:sz(3)
				protoimage(:,:,c) = adapthisteqFB(protoimage(:,:,c),varargin{:});
			end
			
		case 'ahisteqhsv'
			inpicthsx = rgb2hsv(protoimage);
			adjustedL = adapthisteqFB(inpicthsx(:,:,3),varargin{:});
			protoimage = cat(3,inpicthsx(:,:,1:2),adjustedL);
			protoimage = hsv2rgb(protoimage);
			
		case 'ahisteqhsl'
			inpicthsx = rgb2hsl(protoimage);
			adjustedL = adapthisteqFB(inpicthsx(:,:,3),varargin{:});
			protoimage = cat(3,inpicthsx(:,:,1:2),adjustedL);
			protoimage = hsl2rgb(protoimage);
			
		case 'ahisteqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = adapthisteqFB(inpictlch(:,:,1)/100,varargin{:});
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab',truncmode);
			
		case 'ahisteqh'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedH = adapthisteqFB(inpictlch(:,:,3)/360,varargin{:});
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab',truncmode);
		
		case 'ahisteqs'
			inpicthusl = rgb2husl(protoimage,'lab');
			adjustedS = adapthisteqFB(inpicthusl(:,:,2)/100,varargin{:});
			protoimage = cat(3,inpicthusl(:,:,1),adjustedS*100,inpicthusl(:,:,3));
			protoimage = husl2rgb(protoimage,'lab');

		otherwise
			% this should never be reachable
			error('HISTEQTOOL: Unknown mode specified')
	end
		
	outpict(:,:,:,f) = protoimage;
end

% put it all back together
outpict = joinalpha(outpict,alpha);
outpict = imcast(outpict,inclass);

end % END MAIN SCOPE


















