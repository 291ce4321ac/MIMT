function inpict = roifilter(inpict,mk,F,varargin)
%  OUTPICT = ROIFILTER(INPICT,MASK,F,{OPTIONS})
%    Restrict the application of a filter or other function to a region specified 
%    by a mask.  This is similar to IPT roifilt2(), but more flexible, useful, and 
%    often faster.  The basic concept is to extract and process a rectangular image 
%    region local to each blob in the mask instead of processing the image in whole. 
%
%    Filtering by ROI is not always faster than processing the entire image and
%    then compositing the filtered and source images in whole.  In cases where the 
%    total area of the rectangular image segment(s) is much smaller than the total 
%    image area, there may be some speed advantage to using roifilter().  
%
%    While roifilter() and roifilt2() are similar, they are not interchangeable. IPT 
%    roifilt2() cannot utilize anything except binary masks.  It also cannot handle 
%    anything other than a 2D image.  While the typical suggestion is to process an 
%    (e.g. RGB) image by using an external loop, the inability to pass the entire image 
%    segment to the filter routine often negates any speed advantage roifilt2() might 
%    have.  This restriction also means that roifilt2() cannot make use of any function 
%    handles which themselves require color information.
%
%  INPICT is an image of any standard image class.  Multichannel and multiframe 
%    images are supported. 
%  MASK is a 2D mask of any standard image class.  The mask may be binary
%    (hard-edged) or linear (graduated/antialiased).
%  F specifies the type of operation to perform.
%    If specified as a numeric scalar, a 2D gaussian filter of width F is applied.
%    If specified as a matrix, F is treated as a filter kernel and applied.
%    If specified as a function handle, F is applied.
%  OPTIONS include the following keys:
%    'blobwise' changes how a mask with multiple blobs should be processed.
%      By default, all image segments defined by the mask blobs are processed at once.  
%      This is the behavior of roifilt2().
%      When set, the individual image segments are processed independently.  If the 
%      mask has only a few sparsely-placed blobs, this can reduce the amount of data 
%      that gets processed.  
%      The number, size, and shape of the mask blobs will influence which option
%      is more efficient.  If there is only one blob, the default will be faster.
%    'forcemono' allows the use of function handles which themselves cannot handle
%      multichannel/multiframe content.  This processes the image segments one channel
%      at a time, but without the cost of redundant segmentation and overhead as one 
%      would have with roifilt2() and an external loop.
%    'linear' key specifies that segments should be composited using linear RGB
%      instead of sRGB.  This option has no effect when the mask is binarized, though 
%      the cost of linear conversion will only be automatically avoided if the binarized  
%      mask is actually of class 'logical'.
%
%  Output class is inherited from INPICT
%
%  See also: roifilt2, imfilterFB, fkgen, replacepixels

% default not blobwise?
% blobwise is probably not generally best 
% - has extra overhead for labeling
% - has limited window of advantage
% - can easily make things worse (potential overunity area ratio)


% defaults
blobwise = false;
forcemono = false;
linmode = false;

if numel(varargin) > 0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'blobwise'
					blobwise = true;
					k = k+1;
				case 'forcemono'
					forcemono = true;
					k = k+1;
				case 'linear'
					linmode = true;
					k = k+1;
				otherwise
					error('ROIFILTER: unknown key %s',thisarg)
			end
		else
			error('ROIFILTER: expected optional arguments to be presented as key-value pairs')
		end
	end
end

% declare shared vars
rows = [];
cols = [];


% discern syntax type
if isnumeric(F) 
	if isscalar(F)
		fis = 'sigma';
	elseif ndims(F)==2 %#ok<*ISMAT>
		fis = 'fk';
	end
elseif isa(F,'function_handle')
	fis = 'fhandle';
else
	error('ROIFILTER: F is supposed to be a scalar, a 2-D filter kernel, or a function handle.  What is this?')
end

if ndims(mk)~=2
	error('ROIFILTER: expected mask to be a 2D array')
end


% process everything
if blobwise
	% bwconncomp() is a tiny bit faster, but it's IPT-only
	% i don't think it's fast enough to make up for checks
	% maybe only if the image is large enough
	
	if ~hasipt()
		[L nblobs] = bwlabelFB(logical(mk));
		% loop is skipped if no blobs are found
		for kb = 1:nblobs
			% get block extents
			blockmk = L == kb;
			cols = any(blockmk,1);
			rows = any(blockmk,2);

			processblock();
		end
	else
		CC = bwconncomp(logical(mk));
		% loop is skipped if no blobs are found
		for kb = 1:CC.NumObjects
			% get block extents
			blockmk = false(size(mk));
			blockmk(CC.PixelIdxList{kb}) = true;
			cols = any(blockmk,1);
			rows = any(blockmk,2);

			processblock();
		end
	end
else
	% get block extents
	blockmk = logical(mk);
	cols = any(blockmk,1);
	rows = any(blockmk,2);
	cr = [find(cols,1,'first') find(cols,1,'last')];
	rr = [find(rows,1,'first') find(rows,1,'last')];
	% process is skipped if mask is empty
	if ~isempty(cr) && ~isempty(rr)
		cols(cr(1):cr(2)) = true;
		rows(rr(1):rr(2)) = true;

		processblock();
	end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processblock()
	% extract image and mask blocks
	imblock = inpict(rows,cols,:,:);
	mkblock = mk(rows,cols);

	% apply F
	switch fis
		case 'sigma'
			fk = fkgen('gaussian',F);
			imblockf = imfilterFB(imblock,fk);
		case 'fk'
			imblockf = imfilterFB(imblock,F);
		case 'fhandle'
			if forcemono
				imblockf = imblock;
				for f = 1:size(inpict,4)
					for c = 1:size(inpict,3)
						imblockf(:,:,c,f) = F(imblock(:,:,c,f));
					end
				end
			else
				imblockf = F(imblock);
			end
		otherwise
			% this should never happen, since keys are matched
	end

	% composite this block, insert into image
	if linmode
		imblockf = replacepixels(imblockf,imblock,mkblock,'linear');
	else
		imblockf = replacepixels(imblockf,imblock,mkblock);
	end
	inpict(rows,cols,:,:) = imblockf;
end

end % END MAIN SCOPE






