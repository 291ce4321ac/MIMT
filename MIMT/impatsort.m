function [G ugl] = impatsort(fpathexpr,varargin)
%  [PATGROUPS LEVELS] = IMPATSORT(PATHEXPR,{OPTIONS})
%  [PATGROUPS LEVELS] = IMPATSORT(INSTACK,{OPTIONS})
%    Read a number of image files (ostensibly tileable patterns/textures)
%    and sort them into groups based on their average gray level. This is 
%    used as the first step in pattern-mapping a grayscale image.
%
%  FPATHEXPR is a char vector or a cell array of char vectors specifying
%    the path to a number of image or MIMT font files.  Wildcards (*) are supported.
%    Images are expected to be binary, grayscale, RGB, or indexed.  Multiframe 
%    images or images with alpha content are discarded. 
%    If expressions point to .mat files under the MIMT/fonts directory, then 
%    they will be imported according to the conventions for those specific files.
%    No other font files (e.g. .ttf) are supported. 
%  INSTACK allows the user to supply a 4D stack of images instead of a list of
%    path expressions.  The image stack may be of any standard image class.  
%    Images with alpha are discarded.
%  OPTIONS includes the following key-value pairs:
%    'addinv' expands the pattern set by including inverted copies. (default true)
%    'addbw' expands the pattern set by including solid B/W images. (default true) 
%       Both images are 10x10px.  One is black; one is white.
%    'maxwidth' limits the acceptable geometry of imported images (px, default 0)
%       Discarding large patterns is a simple way to avoid scenarios where
%       the regions being filled by the pattern are much smaller than the pattern
%       image itself.  In those scenarios, and with low-frequency pattern content, 
%       the mean gray level of the pattern is a poor predictor of the actual gray  
%       level of the filled region.  Set to 0 to disable.
%    'maxcont' limits the acceptable contrast of the imported images (default 1)
%       In this context, "contrast" is the extreme data range within an image, 
%       as represented on a unit scale. Reducing MAXCONT is useful when improved
%       gray level uniformity is desired from mixed pattern sets.
%    'tol' specifies the tolerance used when binning patterns (default 0.5)
%       The minimum absolute distance between any member of a given bin and the
%       associated gray level in LEVELS is TOL/N, where N is the total number of 
%       imported pattern images.  If set to 0, all members of each bin will have 
%       the exact same average gray level.
%    'verbose' if set to true, will enable the console output of certain info
%       pertaining to path expression parsing and file import. (default false)
%
%  Output arguments:
%  PATGROUPS is a cell array, where each cell contains a cell array of images.  
%    All images are reduced to grayscale and cast/scaled to uint8.
%  LEVELS is a numeric vector in the range [0 1], describing the gray levels
%    associated with each bin (the elements of PATGROUPS).
%
%  See also: impatmap, patbinchart, ptile


% defaults
includeinverse = true;
addbw = true;
maxwidth = 0;
maxcontrast = 1;
tol = 0.5;
verbose = false;

% get inputs
if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'addinv'
					includeinverse = varargin{k+1};
					k = k+2;
				case 'addbw'
					addbw = varargin{k+1};
					k = k+2;
				case 'maxwidth'
					maxwidth = varargin{k+1};
					k = k+2;
				case 'maxcont'
					maxcontrast = varargin{k+1};
					k = k+2;
				case 'tol'
					tol = varargin{k+1};
					k = k+2;
				case 'verbose'
					verbose = varargin{k+1};
					k = k+2;
				otherwise
					error('IMPATSORT: unknown key %s',thisarg)
			end
		else
			error('IMPATSORT: expected optional values to be prefaced by a parameter name')
		end
	end
end


maxcontrast = imclamp(maxcontrast);
maxwidth = max(maxwidth,0);
tol = max(tol,0);

% this is neat, but it'd be nice to be able to specify a font directly
% or to process cells of images
% look for fonts/*.mat subexpr, extract from list
% import each matfile
% if remainder of list is nonempty, load images with mimread

if (isnumeric(fpathexpr) || islogical(fpathexpr)) && ndims(fpathexpr)==4
	% read images from 4D image stack
	patlib = squeeze(num2cell(fpathexpr,[1 2 3]));
else
	if ~ischar(fpathexpr) && ~iscellstr(fpathexpr) %#ok<ISCLSTR>
		error('IMPATSORT: expected first argument to be a char vector, a cellchar, or a 4D numeric/logical array')
	end
	if ischar(fpathexpr)
		fpathexpr = {fpathexpr};
	end

	% segregate font path expressions from everything else
	R = regexp(fpathexpr,'.*font.*\.mat','match');
	isfont = ~cellfun('isempty',R);
	ffpathexpr = fpathexpr(isfont);
	fpathexpr(isfont) = [];

	% process font path expressions to get list of font files
	fontpaths = [];
	for kfex = 1:numel(ffpathexpr)
		pathinfo = dir(ffpathexpr{kfex});
		pathinfo = pathinfo(~cellfun('isempty', {pathinfo.date}));
		pathinfo = pathinfo(~[pathinfo.isdir]); % remove directories
		pathprefix = fileparts(ffpathexpr{kfex});
		matchnames = {pathinfo.name}';
		for kf = 1:numel(matchnames)
			fontpaths = [fontpaths; {fullfile(pathprefix,matchnames{kf})}]; %#ok<*AGROW>
		end
	end

	if verbose
		disp('FONT FILE EXPRESSIONS:')
		fprintf('%s\n',ffpathexpr{:})
		disp('MATCHING FONT FILES:')
		fprintf('%s\n',fontpaths{:})
	end
	
	% import and detile specified font files
	patlib = [];
	for kf = 1:numel(fontpaths)
		S = load(fontpaths{kf});
		A = imdetile(S.charset,[1 256]);
		% convert to cell, append
		patlib = [patlib; squeeze(num2cell(A,[1 2 3]))];
	end
	
	% read remaining images from files, append
	if ~isempty(fpathexpr)
		% if trailing non-image files get fed to mimread without the intent to find image files
		% it will break with an error, even though preceding font files may have been the intended target
		% impatsort() will break with its own error if patlib is empty
		try
			if verbose
				disp('IMAGE PATH EXPRESSIONS:')
				fprintf('%s\n',fpathexpr{:})
			end
			patlib = [patlib; mimread('',fpathexpr)];
		catch
			if verbose
				disp('MIMREAD FOUND NO IMAGE FILES')
			end
		end
	end
end

% add black/white frames
if addbw
	patlib = [patlib; {zeros(10,'uint8')}];
	% if inversion is enabled, the white pattern will become redundant
	if ~includeinverse
		patlib = [patlib; {ones(10,'uint8')*255}];
	end
end

if isempty(patlib)
	error('IMPATSORT: no valid patterns found')
end

npats = numel(patlib);
patgl = zeros(npats,1);
discardthese = false(npats,1);
for f = 1:npats
	thisf = patlib{f};
	szf = imsize(thisf);
	
	% discard images with alpha
	% discard multiframe images
	discardthese(f) = szf(4)>1 || ~ismember(szf(3),[1 3]);	
	
	% discard large patterns
	if maxwidth>0
		discardthese(f) = discardthese(f) || any(szf(1:2)>maxwidth);
	end
	
	% discard images with high contrast
	% limiting contrast may be desirable when using grayscale textures
	if maxcontrast<1
		discardthese(f) = discardthese(f) || imcast(range(thisf(:)),'double')>maxcontrast;
	end
	
	if ~discardthese(f)
		% images must be grayscale
		thisf = mono(thisf,'y');
		% calculate outputs
		patgl(f) = mean(imcast(thisf(:),'double'));
		patlib{f} = imcast(thisf,'uint8');
	end
end

% discard invalid patterns
patlib(discardthese) = [];
patgl(discardthese) = [];
npats = numel(patlib); % recalc

% duplicate and invert if requested
if includeinverse
	patlib = [patlib; cellfun(@iminv,patlib,'uniform',false)];
	patgl = [patgl; 1-patgl];
end

% sort vectors
[patgl idx] = sort(patgl,'ascend');
patlib = patlib(idx);

% find unique gray levels
if tol == 0
	[ugl,~,ic] = unique(patgl);
else
	[ugl,~,ic] = uniquetol(patgl,tol/npats,'datascale',1);
end
nu = numel(ugl);

% split into groups sharing unique gray levels
G = cell(nu,1);
for uidx = 1:nu
	groupmembs = ic == uidx;
	G{uidx} = patlib(groupmembs);
end



