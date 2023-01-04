function outpict = replacepixels(FG,BG,mask,varargin)
%  OUTPICT = REPLACEPIXELS(FG,BG,MASK,{LINEAR})
%    Simple image composition tool.  Loosely speaking, the output image will
%    be equal to BG in regions where MASK is dark, and equal to FG in regions 
%    where MASK is bright.  This tool can be used with either binarized or graduated
%    masks, or with a scalar opacity parameter in lieu of a full mask.
%
%  FG is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%    Alternatively, FG may be specified as a color tuple instead of a full image
%    If specified as a tuple, it must still be scaled correctly for its class.
%  BG is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%  MASK is an I/RGB image of any standard image class
%    Alternatively, MASK may be specified as a tuple instead of a full image
%    If specified as a tuple, it must still be scaled correctly for its class.
%  LINEAR is an optional key. When 'linear' is specified, composition is 
%    done in linear RGB instead of sRGB. This is slower, but usually the 
%    preferable way. This option has no effect when MASK is logical.
%
%  When inputs have differing numbers of color or alpha channels, 
%  the general behavior is to expand the output image accordingly.
%  If FG, BG, or MASK are multiframe, output will be multiframe.  
%  All multiframe inputs must have the same number of frames.
%
%  Output class is inherited from BG
%  NaN throughput is only possible if BG is of floating-point class.
%
%  See also: imblend, splitalpha, joinalpha


% default parameters:
linearmode = false;

% parse optional inputs
if nargin>3
	thisarg = varargin{1};
	switch lower(thisarg)
		case 'linear'
			linearmode = true;
		otherwise
			error('REPLACEPIXELS: unknown key %s',thisarg)
	end
end

% handle tuple-as-FG
fgistuple = false;
if isvector(FG) && any(numel(FG) == [1 2 3 4 6])
	FG = reshape(FG,1,1,[]);
	fgistuple = true;
end

% handle tuple-as-mask
mkistuple = false;
if isvector(mask) && any(numel(mask) == [1 3])
	mask = reshape(mask,1,1,[]);
	mkistuple = true;
end

% check size correspondence
szmk = imsize(mask);
szfg = imsize(FG);
szbg = imsize(BG);
if ~fgistuple && any(szfg(1:2) ~= szbg(1:2))
	error('REPLACEPIXELS: FG/BG geometry mismatch')
elseif ~mkistuple && any(szmk(1:2) ~= szbg(1:2))
	error('REPLACEPIXELS: mask/image geometry mismatch')
end

% check to make sure mask is I/RGB
if ~any(szmk(3) == [1 3])
	error('REPLACEPIXELS: MASK is expected to be I/RGB, instead it has %d channels',szmk(3))
end

% logical-comp path should only be taken for images without alpha
% it might be faster, but using logical masks with an RGBA workflow 
% shouldn't be something worth making complexity sacrifices
[~,ncaF] = chancount(FG);
[~,ncaB] = chancount(BG);
logmask = islogical(mask);
if logmask && ~mkistuple && ~any([ncaF ncaB])
	complogical();
else
	complinear();
end

function complogical()
	% this is for logcomp path
	outclass = class(BG);
	FG = imcast(FG,outclass);

	% assuming geometries are identical
	% assuming chancounts are either 1 or 3
	% assuming framecounts are either 1 or some consistent number
	outsize = max([szmk; szfg; szbg],[],1);
	
	% assignment by logical indexing with implicit expansion on dims 3 and 4
	outpict = zeros(outsize,outclass);
	for f = 1:outsize(4)
		fmk = min(f,szmk(4));
		ffg = min(f,szfg(4));
		fbg = min(f,szbg(4));
		
		for c = 1:outsize(3)
			cmk = min(c,szmk(3));
			cfg = min(c,szfg(3));
			cbg = min(c,szbg(3));
				
			% compose this channel
			thismk = mask(:,:,cmk,fmk);
			thisfg = FG(:,:,cfg,ffg);
			outchan = BG(:,:,cbg,fbg);
			if fgistuple
				outchan(thismk) = thisfg;
			else
				outchan(thismk) = thisfg(thismk);
			end
			
			% store result
			outpict(:,:,c,f) = outchan;
		end
	end
end

function complinear()
	% this is for lincomp path
	[BG outclass] = imcast(BG,'double');
	FG = imcast(FG,'double');
	mask = imcast(mask,'double');

	[BG BGA] = splitalpha(BG);
	[FG FGA] = splitalpha(FG);
	
	if linearmode
		FG = rgb2linear(FG);
		BG = rgb2linear(BG);
	end
	
	% let mask/alpha expand as necessary
	if isempty(FGA)
		FGA = mask;
	else
		FGA = bsxfun(@times,FGA,mask);
	end

	% Porter-Duff Src-Over composition
	As = FGA;
	if isempty(BGA)
		Ad = (1-FGA);
	else
		Ad = BGA.*(1-FGA);
	end
	outpict = bsxfun(@plus, bsxfun(@times,As,FG), bsxfun(@times,Ad,BG));
	
	% output does not have alpha unless BG has alpha
	if ~isempty(BGA)
		outalpha = As+Ad;
		outpict = bsxfun(@rdivide,outpict,outalpha+eps);
		outpict = joinalpha(outpict,outalpha);
	end
	
	% prepare output
	if linearmode
		outpict = linear2rgb(outpict);
	end
	outpict = imcast(outpict,outclass);
end

end % END MAIN SCOPE






