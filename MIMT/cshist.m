function varargout = cshist(inpict,spc,varargin)
%  CSHIST(INPICT,CMODEL,{OPTIONS})
%  COUNTS = CSHIST(...)
%  [COUNTS BINCENTERS] = CSHIST(...)
%  [COUNTS BINCENTERS BINEDGES] = CSHIST(...)
%  [COUNTS BINCENTERS BINEDGES HAX] = CSHIST(...)
%  Plot the histogram of a color image in the specified color model.
%  This tool produces three histogram plots with colorbars.
%
%  INPICT is an RGB image of any standard image class. 
%    Any attached alpha will be discarded.  If inpict is multiframe, 
%    all frames will be evaluated as one.
%  CMODEL specifies the color space to use when plotting
%    'rgb', 'hsv', 'hsl', 'hsi', 'ycbcr', 
%    'ypbpr', 'luv', 'lab', 'srlab', 'oklab', 
%    'lchbr', 'lchuv', 'lchab', 'lchsr', 'lchok', 
%    'hsy', 'huslab', 'husluv', 'hsyp', 'huslpab', 'huslpuv'
%    When CMODEL is 'rgb', the image is processed in its native scale.
%    When CMODEL is 'ycbcr', the image is processed in uint8-scale.
%  OPTIONS includes the following keys and key-value pairs:
%    'style' specifies the type of histogram plot (default 'bar')
%       'stem' draws a stem plot, with one stem in the center of each bin.
%          This is the behavior of IPT imhist().
%       'bar' draws a dense bar plot, with each bar spanning its corresponding
%          histogram bin.  This is the behavior of histogram().
%       'patch' draws a color filled area plot.
%    'extents' specifies what range of values should be considered (default 'box')
%       'box' includes the same range as 'gamut', but may also extend into OOG regions
%          relevant to the model (e.g. the margins of YCbCr), or to otherwise center 
%          the neutral axis for opponent color models.
%       'gamut' considers a range which roughly encompasses the projected sRGB gamut.
%       'extrema' only considers the range of values present in the given image.
%    'yscale' specifies how the y-axis limits should be calculated (default 'tight')
%       'full' sets the y-axis limits such that all of the peaks are fully visible.
%       'tight' is less sensitive to the presence of large peaks, mimicking imhist().
%    'nbins' optionally specifies how many histogram bins should be used (default 256)
%    'binalignment' controls how the data is binned. (default 'center')  
%       'center' places the end bins such that they are centered on the ends of the  
%          interval implied by EXTENTS.  Only half of each end bin is in this interval.
%       'edge' places the end bins such that their outermost edges coincide with the  
%          ends of the interval.  This means that each bin covers an equal portion of 
%          the interval.
%    'oogfill' specifies the color used to mark the out-of-gamut regions.
%       This may either be a 1x3 unit-scale tuple (default [0.6 0.2 0.2]), or 'none'.
%    'invert' key optionally inverts the color gradient for use on inverted displays.
%    'target' may either be a figure handle, or a 3-element vector of axes handles.
%
%  Optional counts/centers/edges outputs are given as vectors stored in 3x1 cell arrays.
%  Optional output argument HAX is a 6x1 vector of axes handles.
%  The first three axes contain the histogram plots.  The latter three axes 
%  contain the color stripes and bear the channel labels.
%
%  See also: imhistFB(), imhist(), csview()

% hsyp/huslp modes tend to have unreadable S for typical images. 
% since almost all S is >1, the end bin is so full it messes up the scaling.
% it might be worth forcing into hsyn/husln, but that'll probably confuse most people.  
% maybe i'll change my mind about that.  not now though.

% i'm inclined to think i should have written this more like imhistFB(), 
% where the plotting routines can be inhibited or forced as needed.
% the truth is that i had started cshist() with a plot-only intention.
% it was mostly written by the time it became necessary to rewrite imhistFB().  
% i guess that's what happens without plans.

bigtable = { % create as one big array for sake of compactness, readability, ease of maintenance
% csnames	plotaxlabel			boxrange						gamutrange					stripecenter
'rgb',		{'R','G','B'},		[0 1; 0 1; 0 1],				[0 1; 0 1; 0 1],			[NaN 0 0; 0 NaN 0; 0 0 NaN];

'hsv',		{'H','S','V'},		[0 360; 0 1; 0 1],				[0 360; 0 1; 0 1],			[NaN 1 1; 0 NaN 1; 0 0 NaN];
'hsl',		{'H','S','L'},		[0 360; 0 1; 0 1],				[0 360; 0 1; 0 1],			[NaN 1 0.5; 0 NaN 0.5; 0 0 NaN];
'hsi',		{'H','S','I'},		[0 360; 0 1; 0 1],				[0 360; 0 1; 0 1],			[NaN 1 0.5; 0 NaN 0.5; 0 0 NaN];

'ycbcr',	{'Y','Cb','Cr'},	[0 255; 0 255; 0 255],			[16 235; 16 240; 16 240],	[NaN 128 128; 128 NaN 128; 128 128 NaN];
'ypbpr',	{'Y','Pb','Pr'},	[0 1; -0.5 0.5; -0.5 0.5],		[0 1; -0.5 0.5; -0.5 0.5],	[NaN 0 0; 0.5 NaN 0; 0.5 0 NaN];	
'luv',		{'L','U','V'},		[0 100; -180 180; -180 180],	[0 100; -83 175; -135 108],	[NaN 0 0; 76 NaN 0; 76 0 NaN];
'lab',		{'L','A','B'},		[0 100; -110 110; -110 110],	[0 100; -87 99; -108 95],	[NaN 0 0; 74 NaN 0; 74 0 NaN];
'srlab',	{'L','A','B'},		[0 100; -100 100; -100 100],	[14 100; -72 90; -96 82],	[NaN 0 0; 78 NaN 0; 78 0 NaN];
'oklab',	{'L','A','B'},		[0 100; -35 35; -35 35],		[0 100; -24 28; -32 20],	[NaN 0 0; 75 NaN 0; 75 0 NaN];

'lchbr',	{'L','C','H'},		[0 1; 0 0.55; 0 360],			[0 1; 0 0.54; 0 360],		[NaN 0 0; 0.299 NaN 108.6; 0.5 0.28 NaN];	
'lchuv',	{'L','C','H'},		[0 100; 0 180; 0 360],			[0 100; 0 179; 0 360],		[NaN 0 0; 53 NaN 12; 76 75 NaN];
'lchab',	{'L','C','H'},		[0 100; 0 135; 0 360],			[0 100; 0 134; 0 360],		[NaN 0 0; 53 NaN 40; 74 60 NaN];
'lchsr',	{'L','C','H'},		[0 100; 0 105; 0 360],			[14 100; 0 103; 0 360],		[NaN 0 0; 60 NaN 41; 78 50 NaN];
'lchok',	{'L','C','H'},		[0 100; 0 35; 0 360],			[0 100; 0 32.3; 0 360],		[NaN 0 0; 63 NaN 23; 75 13 NaN];

'hsy',		{'H','S','Y'},		[0 360; 0 1; 0 1],				[0 360; 0 1; 0 1],			[NaN 1 0.5; 0 NaN 0.5; 0 0 NaN];
'huslab',	{'H','S','L'},		[0 360; 0 100; 0 100],			[0 360; 0 100; 0 100],		[NaN 100 74; 40 NaN 53; 0 0 NaN];
'husluv',	{'H','S','L'},		[0 360; 0 100; 0 100],			[0 360; 0 100; 0 100],		[NaN 100 76; 12 NaN 53; 0 0 NaN];
'hsyp',		{'H','S','Y'},		[0 360; 0 1; 0 1],				[0 360; 0 1; 0 1],			[NaN 1 0.5; 0 NaN 0.5; 0 0 NaN];
'huslpab',	{'H','S','L'},		[0 360; 0 100; 0 100],			[0 360; 0 100; 0 100],		[NaN 100 74; 40 NaN 53; 0 0 NaN];
'huslpuv',	{'H','S','L'},		[0 360; 0 100; 0 100],			[0 360; 0 100; 0 100],		[NaN 100 76; 12 NaN 53; 0 0 NaN];
};


% defaults
binalignstr = {'center','edge'};
binalignment = 'edge';
stylestr = {'bar','stem','patch'};
style = 'bar';
extstr = {'extrema','gamut','box'};
extents = 'box';
yscalestr = {'full','tight'};
yscale = 'tight'; 
invert = false;
nhistbins = 256;
oogfill = [0.6 0.2 0.2];
showoog = true;
target = [];

% process inputs
if nargin>1
	k = 1; 
	while k <= numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'binalignment'
					nextarg = lower(varargin{k+1});
					if strismember(nextarg,binalignstr)
						binalignment = nextarg;
					else
						error('CSHIST: unsupported option for BINALIGNMENT parameter')
					end
					k = k + 2;
				case 'style'
					nextarg = lower(varargin{k+1});
					if strismember(nextarg,stylestr)
						style = nextarg;
					else
						error('CSHIST: unsupported option for STYLE parameter')
					end
					k = k + 2;
				case 'extents'
					nextarg = lower(varargin{k+1});
					if strismember(nextarg,extstr)
						extents = nextarg;
					else
						error('CSHIST: unsupported option for EXTENTS parameter')
					end
					k = k + 2;
				case 'yscale'
					nextarg = lower(varargin{k+1});
					if strismember(nextarg,yscalestr)
						yscale = nextarg;
					else
						error('CSHIST: unsupported option for YSCALE parameter')
					end
					k = k + 2;
				case 'nbins'
					nextarg = varargin{k+1};
					if isnumeric(nextarg) && isscalar(nextarg)
						nhistbins = round(nextarg);
					else
						error('CSHIST: unsupported value for NBINS parameter')
					end
					k = k + 2;
				case 'oogfill'
					nextarg = varargin{k+1};
					if isnumeric(nextarg)
						if ~isfloat(nextarg) || numel(nextarg)~=3 || any(nextarg<0) || any(nextarg>1)
							error('CSHIST: numeric inputs to the OOGFILL parameter must be unit-scale float triples')
						else
							oogfill = reshape(nextarg,1,3);
						end
					elseif ischar(nextarg) && strcmpi(nextarg,'none')
						showoog = false;
					else
						error('CSHIST: unsupported value for OOGFILL parameter')
					end
					k = k + 2;
				case 'target'
					target = varargin{k+1};
					k = k + 2;
				case 'invert'
					invert = true;
					k = k + 1;
				otherwise
					error('CSHIST: unknown option %s',thisarg)
			end
		else
			error('CSHIST: unknown non-string argument')
		end
	end
end

% check target
if ifversion('<','R2013a')
	hax = zeros(6,1);
else
	hax = gobjects(6,1);
end
if isempty(target)
	hfig = gcf;
	for c = 1:3
		hax(c) = subplot(3,1,c,'parent',hfig);
	end
else
	try
		targettype = get(target,'type');
	catch
		error('CSHIST: invalid target figure/axes')
	end

	if numel(target) == 1 && all(strcmpi(targettype,'figure'))
		hfig = target;
		for c = 1:3
			hax(c) = subplot(3,1,c,'parent',hfig);
		end
	elseif numel(target) == 3 && all(strcmpi(targettype,'axes'))
		hax(1:3) = target(1:3);
	else
		error('CSHIST: invalid target figure/axes')
	end
end

% fetch space name, sanitize, validate
spc = lower(spc);
spc = spc(spc ~= ' ');
csnames = bigtable(:,1);
[validcsname,selectedcs] = ismember(spc,csnames);
if ~validcsname
	error('CSHIST: unknown colorspace name %s \n',spc)
end

% prepare the image
inpict = splitalpha(inpict); % strip any alpha
szi = imsize(inpict);
if szi(3)~=3
	error('CSHIST: expected INPICT to be an RGB image')
end
% this allows us to process entire 4D arrays
inpict = reshape(permute(inpict,[1 2 4 3]),[],1,3);

% convert the image to the target space
% keep original data scale for RGB case
inclass = class(inpict);
if ~strcmp(spc,'rgb')
	inpict = imcast(inpict,'double');
	inpict = fromrgb(inpict,spc);
end

% get associated params
plotaxlabels = bigtable{selectedcs,2};
gamutrange = bigtable{selectedcs,4};
switch extents
	case 'extrema'
		plotrange = imstats(inpict,'min','max').';
	case 'gamut'
		plotrange = bigtable{selectedcs,4};
	case 'box'
		plotrange = bigtable{selectedcs,3};
end

% construct the color tables
basectpts = 256;
ctcenter = bigtable{selectedcs,5};
CT = cell(3,1);
for c = 1:3
	% construct the full table over the gamut range
	xgamut0 = gamutrange(c,:); % the gamut extents on this axis
	xgamutf = linspace(xgamut0(1),xgamut0(2),basectpts); % position relative to gamut extents
	CT0 = repmat(ctcenter(c,:),[2 1]); % assemble the ends of the CT
	CT0(:,c) = xgamut0;
	thisct = interp1(xgamut0,CT0,xgamutf,'linear','extrap'); % interpolate over the gamut
	
	% convert to unit-scale RGB
	thisct = imclamp(ctflop(torgb(ctflop(thisct),spc)));
	
	% interpolate/extrapolate to fit the selected extents and number of bins
	xplotf = linspace(plotrange(c,1),plotrange(c,2),nhistbins);
	thisct = interp1(xgamutf,thisct,xplotf,'linear','extrap');
	
	% fill OOG rows with the padding color
	if showoog
		isoog = (xplotf<xgamut0(1)) | (xplotf>xgamut0(2));
		thisct(isoog,:) = repmat(oogfill,[nnz(isoog) 1]);
	end
	
	CT{c} = imclamp(thisct);
end

% rescale extents to match data scale
if strcmp(spc,'rgb')
	plotrange = imrescale(plotrange,'double',inclass);
end

% generate the histogram plots
allcounts = cell(3,1);
allcenters = cell(3,1);
alledges = cell(3,1);
for c = 1:3
    % create histogram plot for this channel
	imhistargs = {'style',style, ...
			'yscale',yscale, ...
			'binalignment',binalignment, ...
			'range',plotrange(c,:), ...
			'colortable',CT{c}, ...
			'parent',hax(c), ...
			'forceplot'};
	if invert
		[allcounts{c} allcenters{c} alledges{c} ht] = imhistFB(inpict(:,:,c),nhistbins,imhistargs{:},'invert');
	else
		[allcounts{c} allcenters{c} alledges{c} ht] = imhistFB(inpict(:,:,c),nhistbins,imhistargs{:});
	end
	
	% need to place the label on the stripe axes, not the plot axes
	hax(3+c) = ht(2); % this is the stripe axes
	xlabel(hax(3+c),plotaxlabels{c})
end

% the handle array is ordered:
% [top plot axes
%  middle plot axes
%  bottom plot axes
%  top stripe axes
%  middle stripe axes
%  bottom stripe axes]

% prepare outputs
switch nargout
	case 0
		% NOP
	case 1
		varargout{1} = allcounts;
	case 2
		varargout{1} = allcounts;
		varargout{2} = allcenters;
	case 3
		varargout{1} = allcounts;
		varargout{2} = allcenters;
		varargout{3} = alledges;
	case 4
		varargout{1} = allcounts;
		varargout{2} = allcenters;
		varargout{3} = alledges;
		varargout{4} = hax;
end

end % END MAIN SCOPE

function out = fromrgb(f,spc)
	switch spc
		case 'rgb'
			out = f;
		case 'hsi'
			out = rgb2hsi(f);
		case 'hsl'
			out = rgb2hsl(f);
			H = out(:,:,1);
			H(isnan(H)) = 0;
			out(:,:,1) = H;
		case 'hsv'
			out = rgb2hsv(f);
			out(:,:,1) = out(:,:,1)*360;
		case {'hsy'}
			out = rgb2hsy(f);
		case {'hsyp'}
			out = rgb2hsy(f,'pastel');
		case {'huslab'}
			out = rgb2husl(f,'lab');
		case {'husluv'}
			out = rgb2husl(f,'luv');
		case {'huslpab'}
			out = rgb2husl(f,'labp');
		case {'huslpuv'}
			out = rgb2husl(f,'luvp');
		case 'lchbr'
			out = rgb2lch(f,'ypbpr');
		case 'lchab'
			out = rgb2lch(f,'lab');
		case 'lchuv'
			out = rgb2lch(f,'luv');
		case 'lchsr'
			out = rgb2lch(f,'srlab');
		case 'srlab'
			out = rgb2lch(f,'srlab');
			out = lch2lab(out);
		case 'lchok'
			out = rgb2lch(f,'oklab');
		case 'oklab'
			out = rgb2lch(f,'oklab');
			out = lch2lab(out);
		case 'lab'
			out = rgb2lch(f,'lab');
			out = lch2lab(out);
		case 'luv'
			out = rgb2lch(f,'luv');
			out = lch2lab(out);
		case {'ypbpr','ypp'}
			out = imappmat(f,gettfm(spc));
		case 'ycbcr'
			% this generates uint8-scale float ycbcr (i.e. misscaled)
			% the reason is to avoid aliasing artifacts when binning
			[A os] = gettfm('ycbcr');
			out = imappmat(f,A,os,'double','iptmode');
		otherwise
			% this shouldn't ever happen
			error('CSHIST: unknown colorspace %s',spc)
	end
end

function out = torgb(f,spc)
	truncopt = 'truncatergb';
	switch spc
		case 'rgb'
			out = f;
		case 'hsi'
			out = hsi2rgb(f);
		case 'hsl'
			out = hsl2rgb(f);
		case 'hsv'
			f(:,:,1) = f(:,:,1)/360;
			out = hsv2rgb(f);
		case {'hsy'}
			out = hsy2rgb(f);
		case {'hsyp'}
			out = hsy2rgb(f,'pastel');
		case {'huslab'}
			out = husl2rgb(f,'lab');
		case {'husluv'}
			out = husl2rgb(f,'luv');
		case {'huslpab'}
			out = husl2rgb(f,'labp');
		case {'huslpuv'}
			out = husl2rgb(f,'luvp');
		case 'lchbr'
			out = lch2rgb(f,'ypbpr',truncopt);
		case 'lchab'
			out = lch2rgb(f,'lab',truncopt);
		case 'lchuv'
			out = lch2rgb(f,'luv',truncopt);
		case 'lchsr'
			out = lch2rgb(f,'srlab',truncopt);
		case 'srlab'
			out = lab2lch(f);
			out = lch2rgb(out,'srlab',truncopt);
		case 'lchok'
			out = lch2rgb(f,'oklab',truncopt);
		case 'oklab'
			out = lab2lch(f);
			out = lch2rgb(out,'oklab',truncopt);
		case 'lab'
			out = lab2lch(f);
			out = lch2rgb(out,'lab',truncopt);
		case 'luv'
			out = lab2lch(f);
			out = lch2rgb(out,'luv',truncopt);
		case {'ypbpr','ypp'}
			out = imappmat(f,gettfm([spc '_inv']));
		case 'ycbcr'
			[A os] = gettfm('ycbcr');
			out = imappmat(f,inv(A),0,-os,'double','iptmode');
		otherwise
			% this shouldn't ever happen
			error('CSHIST: unknown colorspace %s',spc)
	end
end
