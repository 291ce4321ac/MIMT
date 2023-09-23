function cdiff = colordiff(Argb,Brgb,varargin)
%  DE = COLORDIFF(A,B,{CSPACE},{DETYPE})
%    Calculate the Delta-E color difference between two images.
%
%  A and B may be RGB images, Mx3 color tables, or 1x3 color tuples of 
%    any standard image class.  Tables and tuples are expected to be 
%    properly-scaled for their class.
%    If both inputs are a common type (i.e. two images or two tables), 
%    then both must have the same size.  An image or table can be compared
%    against a tuple, but an image cannot be compared to a color table.
%
%  CSPACE optionally specifies the colorspace (default 'lab')
%    Keys include 'lab', 'srlab', 'oklab', 'luv', and 'ypbpr'.
%  DETYPE optionally specifies the calculation type (default 'de76')
%    'de76' calculates Delta E (1976) (simple Euclidean distance)
%    'de94' calculates Delta E (1994) (weighted distance in LCH)
%    For 'de94', image A is the reference image.
%
%  Note:
%    I'm including extra colorspace options for completeness.  I make no 
%    assertion that calculating DE76 with OKLAB adheres to any standard. 
%    It's up to you to decide whether there are advantages to those cases
%    (e.g. uniformity of SRLAB/OKLAB, or speed of YPbPr), and to make
%    comparisons only against similarly-calculated differences.  They are
%    not interchangeable.
%
%  Output is class 'double'
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/colordiff.html
%  See also: rgb2lch, lch2rgb, imerror, deltaE, imcolordiff

sza = imsize(Argb);
szb = imsize(Brgb);

% if the inputs are color tables/tuples, permute
isimage = [sza(3) szb(3)] == 3;
if ~isimage(1)
	if sza(2)==3
		Argb = ctflop(Argb);
	else
		error('COLORDIFF: A is not an RGB image, color table, or tuple')
	end
end
if ~isimage(2)
	if szb(2)==3
		Brgb = ctflop(Brgb);
	else
		error('COLORDIFF: B is not an RGB image, color table, or tuple')
	end
end

% check if inputs are compatible
% inputs are not valid if:
% both inputs are a common type, but don't have the same page geometry
% one input is an image, but the other is a color table
istable = ([sza(1) szb(1)] > 1) & ~isimage;
if any(isimage) && any(istable)
	error('COLORDIFF: inputs must have compatible size')
end
if (all(isimage) || all(istable)) && any(sza ~= szb)
	error('COLORDIFF: inputs must have the same size')
end


% defaults
cstypestr = {'lab','luv','srlab','oklab','ypbpr'};
cstype = 'lab';
detypestr = {'de76','de94'};
detype = 'de76';

% parse inputs
if numel(varargin)>0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			thisarg = lower(thisarg);
		else
			error('COLORDIFF: unsupported data type for option %d',k)
		end
		
		if strismember(thisarg,cstypestr)
			cstype = thisarg;
		elseif strismember(thisarg,detypestr)
			detype = thisarg;
		else
			error('COLORDIFF: unknown option %s',thisarg)
		end
	end
end


Alch = rgb2lch(Argb,cstype);
Blch = rgb2lch(Brgb,cstype);
Alab = lch2lab(Alch);
Blab = lch2lab(Blch);

switch detype
	case 'de76'
		% http://www.brucelindbloom.com/Eqn_DeltaE_CIE76.html
		[DL DA DB] = splitchans(bsxfun(@minus,Alab,Blab));
		cdiff = sqrt(DL.^2 + DA.^2 + DB.^2);
		
	case 'de94'
		% http://www.brucelindbloom.com/Eqn_DeltaE_CIE94.html
		% in this case, A is considered the reference image
		kl = 1;
		kc = 1;
		kh = 1;
		k1 = 0.045;
		k2 = 0.015;
		
		[DL DA DB] = splitchans(bsxfun(@minus,Alab,Blab));
		DC = Alch(:,:,2) - Blch(:,:,2);
		DHsq = DA.^2 + DB.^2 - DC.^2;
		
		sl = 1; 
		sc = 1 + k1*Alch(:,:,2);
		sh = 1 + k2*Alch(:,:,2);
		cdiff = sqrt((DL./(kl*sl)).^2 + (DC./(kc*sc)).^2 + DHsq./((kh*sh).^2));
end





