function [outpict T] = histeqtool(inpict,mode,varargin)
%  OUTPICT = HISTEQTOOL(INPICT,MODE,{EXTRAARGS})
%  [OUTPICT TF] = HISTEQTOOL(INPICT,MODE,{EXTRAARGS})
%    Simple wrapper tool for histeqFB() and adapthisteqFB() for simplified use
%    on both I and RGB images.  This makes it simpler to apply these tools to 
%    components of color images.
%  
%    These tools used to be part of imlnc()
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%    Multiframe images are supported.  Alpha content is passed unmodified.
%    Modes which operate on hue or saturation conceptually require color information
%    and will throw an error if fed an I/IA image. 
%
%  MODE specifies how color images are handled:
%    Modes which use histeqFB():
%      'histeqrgb' operates on I/RGB channels independently
%      'histeqlchab' operates on L in CIE LCHab
%      'histeqh' operates on H in CIE LCHab
%      'histeqs' operates on S in HuSLab
%    Modes which use adapthisteqFB():
%      'ahisteqrgb' operates on I/RGB channels independently
%      'ahisteqlchab' operates on L in CIE LCHab
%      'ahisteqh' operates on H in CIE LCHab
%      'ahisteqs' operates on S in HuSLab
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

modestrings = {'histeqrgb','histeqlchab','histeqh','histeqs',...
			'ahisteqlchab','ahisteqh','ahisteqs','ahisteqrgb'};
if ~strismember(mode,modestrings)
	error('HISTEQTOOL: unsupported mode %s',lower(mode))
end
		
% prepare image
[inpict inclass] = imcast(inpict,'double');
[inpict alpha] = splitalpha(inpict);
sz = imsize(inpict);

% single-channel inputs simplify
if sz(3) == 1 
	switch lower(mode)
		case 'histeqlchab'
			mode = 'histeqrgb';
		case 'ahisteqlchab'
			mode = 'ahisteqrgb';
		case {'histeqh','histeqs','ahisteqh','ahisteqs'}
			error('HISTEQTOOL: the %s mode requires image to be RGB',lower(mode))
	end
end

% preallocate T
switch lower(mode)
	case 'histeqrgb'
		T = cell(sz(4),sz(3));
	case {'histeqlchab','histeqh','histeqs'}
		T = cell(sz(4),1);
	otherwise
		T = {};
end

outpict = zeros(sz);
for f = 1:sz(4)
	protoimage = inpict(:,:,:,f);
	
	switch lower(mode)
		% HISTEQ
		case 'histeqrgb'
			for c = 1:sz(3)
				[protoimage(:,:,c) T{f,c}] = histeqFB(protoimage(:,:,c),varargin{:});
			end
			
		case 'histeqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			[adjustedL T{f}] = histeqFB(inpictlch(:,:,1)/100,varargin{:});
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'histeqh'
			inpictlch = rgb2lch(protoimage,'lab');
			[adjustedH T{f}] = histeqFB(inpictlch(:,:,3)/360,varargin{:});
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
		
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
			
		case 'ahisteqlchab'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedL = adapthisteqFB(inpictlch(:,:,1)/100,varargin{:});
			protoimage = cat(3,adjustedL*100,inpictlch(:,:,2:3));
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
			
		case 'ahisteqh'
			inpictlch = rgb2lch(protoimage,'lab');
			adjustedH = adapthisteqFB(inpictlch(:,:,3)/360,varargin{:});
			protoimage = cat(3,inpictlch(:,:,1:2),adjustedH*360);
			protoimage = lch2rgb(protoimage,'lab','truncatelch');
		
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

outpict = joinalpha(outpict,alpha);
outpict = imcast(outpict,inclass);

end % END MAIN SCOPE


















