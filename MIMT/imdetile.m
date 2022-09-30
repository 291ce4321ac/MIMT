function outpict = imdetile(inpict,tiling,varargin)
%  OUTPICT=IMDETILE(INPICT,TILING,{OPTIONS})
%     Take a single-frame image, subdivide it into tiles, and rearrange 
%     into a 4D image stack.  Conceptually, this is the reverse of an
%     image tiling process as would be performed with IMTILE.
%
%  INPICT is a single-frame I/IA/RGB/RGBA/RGBAAA image of any class.
%  TILING is a 2-element vector specifying the tile arrangement.
%     i.e. [tiles down, tiles across] If the image geometry is not integer-
%     divisible by the tiling, the image will be scaled such that it is.
%  OPTIONS are keys and key-value pairs:
%     'direction' specifies the frame selection order
%        'col' selects frames column-wise
%        'row' selects frames row-wise (default)
%     'fittype' specifies how the image geometry should be adjusted to 
%       make it integer-divisible by TILING
%       'grow' replicates edge vectors to fit
%       'trim' deletes edge vectors to fit 
%       'fit' selects best of either 'grow' or 'trim' behaviors (default)
%       'scale' simply scales the image to the nearest fit
%     'interpolation' specifies the interpolation used for 'scale' mode
%        accepts 'nearest', 'bilinear', or 'bicubic' (default) 
%     'prune' key will cause IMDETILE to attempt to remove padding frames
%        at the extremity of the output stack.  The implied assumption
%        is that one or more adjacent and matching solid-color frames are 
%        padding resulting from a mismatch between the tiling and the number 
%        of images (e.g. 10 images in a 4x3 tiling). When detiling, these 
%        residual padding frames are typically unneeded.
%     'tol' parameter is used when 'prune' is specified.  (default 250E-6)
%        see issolidcolor() for details.
%
%  Class of OUTPICT is inherited from INPICT
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/imdetile.html
% See also: imtile, imstacker, imfold, maketileable

interpmethodstrings = {'nearest','bilinear','bicubic'};
interpmethod = 'bicubic';
directionstrings = {'row','col'};
direction = 'row';
fittypestrings = {'fit','grow','trim','scale'};
fittype = 'fit';
prune = false;
tol = 250E-6;
ffmatch = 0.01; % frame-frame match limit

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'direction'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,directionstrings)
					direction = thisarg;
				else
					error('IMDETILE: unknown direction type %s\n',thisarg)
				end
				k = k+2;
			case 'fittype'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,fittypestrings)
					fittype = thisarg;
				else
					error('IMDETILE: unknown fit type %s\n',thisarg)
				end
				k = k+2;
			case 'interpolation'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,interpmethodstrings)
					interpmethod = thisarg;
				else
					error('IMDETILE: unknown interpolation method %s\n',thisarg)
				end
				k = k+2;
			case 'tol'
				thisarg = varargin{k+1};
				if isnumeric(thisarg)
					tol = thisarg;
				else
					error('IMDETILE: expected numeric value for TOL parameter\n')
				end
				k = k+2;
			case 'prune'
				prune = true;
				k = k+1;
			otherwise
				error('IMDETILE: unknown input parameter name %s',varargin{k})
		end
	end
end

if numel(tiling) ~= 2
	error('IMDETILE: expected a 2-element vector for TILING parameter')
end


% if image dimensions do not evenly divide by tiling, adjust
inpict = maketileable(inpict,tiling,fittype,interpmethod);
s = size(inpict); s = s(1:2);
numframes = prod(tiling);

f = 1;
sout = s./tiling;
outpict = imzeros([sout,size(inpict,3),numframes],class(inpict));
if strcmp(direction,'row')
	for m = 1:tiling(1)
		for n = 1:tiling(2)
			outpict(:,:,:,f) = inpict((1:sout(1))+((m-1)*sout(1)),(1:sout(2))+((n-1)*sout(2)),:);
			f = f+1;
		end
	end
else
	for n = 1:tiling(2)
		for m = 1:tiling(1)
			outpict(:,:,:,f) = inpict((1:sout(1))+((m-1)*sout(1)),(1:sout(2))+((n-1)*sout(2)),:);
			f = f+1;
		end
	end
end

if prune
	wv = imrescale(1,'double',class(inpict));
	numpadframes = 0;
	for f = numframes:-1:1
		[iscolor color] = issolidcolor(outpict(:,:,:,f),tol);
		
		if ~iscolor || (f ~= numframes && mean(abs(color-prevcolor)/wv) >= ffmatch)
			break;
		end
		
		prevcolor = color;
		numpadframes = numpadframes+1;
	end
	
	outpict = outpict(:,:,:,1:(numframes-numpadframes));
end












