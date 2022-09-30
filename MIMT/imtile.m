function outpict = imtile(inpict,tiling,varargin)
%  OUTPICT=IMTILE(INPICT,TILING,{OPTIONS})
%     Take a 4D image stack and rearrange the individual frames
%     into a single-frame image using a rectangular tiling.  
%     
%     MIMT imtile() creates a name conflict with IPT imtile().  I created MIMT imtile()
%     in R2015b, where IPT imtile() does not exist. Since IPT imtile() essentially just extends 
%     the output behavior of montage(), I'm not inclined to ruin the symmetry of my naming
%     convention.  If a replication of montage() is what you want, I'll leave it up to you 
%     to manage the name conflict.
%
%  INPICT is a multiframe I/IA/RGB/RGBA/RGBAAA image of any class.
%  TILING is a 2-element vector specifying the tile arrangement.
%     i.e. [tiles down, tiles across] If INPICT has more frames than
%     required, the excess frames are discarded.
%     TILING may also be specified implicitly (e.g. [NaN 2] fits all frames into 
%     two columns).  If the specified number (implicit or explicit) of tiles 
%     exceeds the number of image frames, colored padding is added.
%  OPTIONS are the key-value pairs:
%     'direction' specifies the frame selection order
%       'col' selects frames column-wise
%       'row' selects frames row-wise (default)
%     'padcolor' specifies the padding color used when numframes is 
%       less than prod(tiling) (default 0). Color values are expected to be 
%       scaled wrt a white value of 1, regardless of image or color class.
%       Vector may have 1, 2, 3, 4, or 6 elements (I, IA, RGB, RGBA, or RGBAAA).
%       Scalar or underspecified vector inputs will be expanded where appropriate.
%       Color and alpha portions of the vector will be expanded independently as needed.
%       Overspecified COLOR vectors will result in the image being expanded accordingly.
%       Default alpha is 100% (opaque)
%
%  NOTE: when doing an operation where an image is detiled and then subsequently retiled, 
%  the resulting image will often not match the original geometry due to the need to make
%  it integer-divisible by the specified tiling (during detiling).  This can be fixed by
%  using maketileable() with the 'revertsize' option to pad/trim/scale the retiled image 
%  back to its original geometry. See the maketileable() synopsis for an example.
%
%  Class of OUTPICT is inherited from INPICT
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/imtile.html
% See also: imdetile, imstacker, imfold, maketileable

directionstrings = {'row','col'};
direction = 'row';
padcolor = 0;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'padcolor'
				if isimageclass(varargin{k+1})
					padcolor = varargin{k+1};
				else
					error('IMTILE: expected numeric/logical value for PADCOLOR')
				end
				k = k+2;
			case 'direction'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,directionstrings)
					direction = thisarg;
				else
					error('IMTILE: unknown direction type %s\n',thisarg)
				end
				k = k+2;
			otherwise
				error('IMTILE: unknown input parameter name %s',varargin{k})
		end
	end
end

if numel(tiling) ~= 2
	error('IMTILE: expected a 2-element vector for TILING parameter')
end

szin = size(inpict);
numframes = size(inpict,4);

% resolve implicit tiling spec
tnan = isnan(tiling);
if any(tnan)
	tiling(tnan) = ceil(numframes/tiling(~tnan));
end

% add padding frames if necessary
if prod(tiling) > numframes
	[inpict padcolor] = matchchannels(inpict,padcolor,'normalized');
	padcolor = imcast(padcolor,class(inpict));
	blankframe = colorpict(szin(1:2),padcolor,class(inpict));
	inpict = cat(4,inpict,repmat(blankframe,[1 1 1 prod(tiling)-numframes]));
	% don't bother updating numframes, it's not used after this
end

f = 1;
outpict = imzeros([size(inpict,1)*tiling(1) size(inpict,2)*tiling(2) size(inpict,3)],class(inpict));
if strcmp(direction,'row')
	for m = 1:tiling(1)
		for n = 1:tiling(2)
			outpict((1:szin(1))+((m-1)*szin(1)),(1:szin(2))+((n-1)*szin(2)),:) = inpict(:,:,:,f);
			f = f+1;
		end
	end
else
	for n = 1:tiling(2)
		for m = 1:tiling(1)
			outpict((1:szin(1))+((m-1)*szin(1)),(1:szin(2))+((n-1)*szin(2)),:) = inpict(:,:,:,f);
			f = f+1;
		end
	end
end


















