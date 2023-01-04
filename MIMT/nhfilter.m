function outpict = nhfilter(inpict,varargin)
%   OUTPICT=NHFILTER(INPICT,MODE,{BLOCKSIZE},{ORDER})
%   Perform the selected sliding-neighborhood filter operation on an image.  
%
%   This is a passthrough to various IPT functions, with internal fallback implementations to help 
%   remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  Not all modes have an 
%   IPT counterpart and are slow regardless of the availability of IPT.
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported.
%
%   MODE specifies the operation to perform
%      'median'       median filter
%      'mode'         mode filter
%      'std'          standard deviation
%      'stdn'         mean-normalized standard deviation
%      'range'        max-min
%      'localcont'    (max-min)/mean
%      'ratio'        min/max
%      'min'          local minimum (erosion)
%      'max'          local maximum (dilation)
%      'ordstat'      order statistic
%
%   BLOCKSIZE specifies the size of the rectangular neighborhood used for sampling (default [5 5])
%      May be specified as a vector or as a scalar with implicit expansion.
%      For 'std' and 'range', BLOCKSIZE will be rounded up to the nearest odd integer to be 
%      compatible with IPT stdfilt() and rangefilt().
%   ORDER optionally specifies the index used with the 'ordstat' mode. (default 1)
%      This is an integer in the range [1 prod(blocksize)].  For a 3x3 filter, setting ORDER 
%      to 1 is equivalent to a local minimum filter (erosion).  Likewise, using 9 is equivalent 
%      to a local maximum filter (dilation).  Using 5 is equivalent to a median filter. 
%      When ORDER is a vector, the frames of the output correspond to the specified indices.  
%      This allows for the simultaneous processing of multiple filters.  If ORDER is a vector, 
%      multiframe inputs are not supported.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/nhfilter.html
% See also: nlfilter, medfilt2, stdfilt, rangefilt, ordfilt2, modefilt, morphops

% ordstat FB would be ~100x faster using builtin _ordf; see ordstatWS.m
% actually, no.  that used to be IPT-only mex and has changed at least twice
% sometime between R2009b-R2015b and again between R2016a-R2019b (no documentation)
% can't really use it for FB

% defaults
ordidx = 1;
blocksize = [5 5];
allmodes = {'median','mode','std','stdn','range','ratio','localcont','ordstat','min','max'};
fpmodes = {'std','stdn','ratio','localcont'}; % inputs must be float
fbonly = {'stdn','ratio','mode','localcont'}; % these have no passthrough
% modefilt is R2020a+, so i can't test it even if i added it conditionally

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			switch k
				case 2
					if any(numel(thisarg) == [1 2])
						blocksize = thisarg;
					else
						error('NHFILTER: expected BLOCKSIZE to be a scalar or a 2-element vector')
					end
				case 3
					ordidx = thisarg(:);
			end
		elseif ischar(thisarg)
			if strismember(lower(thisarg),allmodes)
				mode = lower(thisarg);
			else
				error('NHFILTER: unrecognized mode %s',thisarg)
			end
		end
	end
end

if numel(blocksize) == 1
	blocksize = [1 1]*blocksize;
end

% these IPT tools require odd window geometry
% for sake of consistency, the fallback methods behave the same
if strismember(mode,{'std','range'})
	blocksize = roundodd(blocksize,'ceil');
end

% check ordstat index
badordidx = ordidx>prod(blocksize) | ordidx<1 | mod(ordidx,1)~=0;
if strcmp(mode,'ordstat') && any(badordidx)
	error('NHFILTER: ORDER must be an integer in the range [1 prod(blocksize)]')
end

% multiple ordstat index spec has special output size handling
s0 = imsize(inpict);
multiOS = strcmp(mode,'ordstat') && ~isscalar(ordidx);
if ~multiOS
	outpict = imzeros(s0,class(inpict));
elseif multiOS && s0(4)==1
	outpict = imzeros([s0(1:3) numel(ordidx)],class(inpict));
	mode = 'ordstatmulti'; % special case
else
	error('NHFILTER: multiframe inputs are not supported when ORDER is nonscalar')
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% IF IPT IS INSTALLED
if license('test', 'image_toolbox') && ~strismember(mode,fbonly)
	for f = 1:size(outpict,4) % this is necessary for ordstatmulti case
		for c = 1:s0(3)
			switch mode
				case 'median'
					outpict(:,:,c,f) = medfilt2(inpict(:,:,c,f),blocksize,'symmetric');
				case 'std'
					outpict(:,:,c,f) = stdfilt(inpict(:,:,c,f),ones(blocksize));				
				case 'range'
					outpict(:,:,c,f) = rangefilt(inpict(:,:,c,f),ones(blocksize));
				case 'min'
					outpict(:,:,c,f) = imerode(inpict(:,:,c,f),ones(blocksize));
				case 'max'
					outpict(:,:,c,f) = imdilate(inpict(:,:,c,f),ones(blocksize));
				case 'ordstat'
					% FB uses 'replicate' instead of 'symmetric', but ordfilt2() doesn't support that; close enough
					outpict(:,:,c,f) = ordfilt2(inpict(:,:,c,f),ordidx,ones(blocksize),'symmetric');
				case 'ordstatmulti'
					% f corresponds to elements of ordidx, not frames of inpict
					outpict(:,:,c,f) = ordfilt2(inpict(:,:,c,1),ordidx(f),ones(blocksize),'symmetric');
				otherwise
					error('NHFILTER: unknown mode name ''%s''',mode)
			end
		end
	end
	
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strismember(mode,fpmodes)
	[inpict inclass] = imcast(inpict,'double');
else
	inclass = class(inpict);
end

padsize = floor(blocksize/2);
inpict = padarrayFB(inpict,padsize,'replicate','both');
s = imsize(inpict);

osm = blocksize(1)-1;
osn = blocksize(2)-1;

% this looks like this could be simplified
% but putting function calls or conditionals inside the inner loops
% stacks up a ton of overhead, so it's faster to replicate code
% i really just shouldn't be doing this in m-code

for f = 1:s(4)
	for c = 1:s(3)
		switch mode
			case 'median'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = median(sample(:));
					end
				end
			case 'mode'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = mode(sample(:));
					end
				end
			case 'min'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = min(sample(:));
					end
				end
			case 'max'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = max(sample(:));
					end
				end
			case 'std'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = std(sample(:));
					end
				end
			case 'stdn'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = std(sample(:))/(mean(sample(:))+eps);
					end
				end
			case 'range'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = max(sample(:))-min(sample(:));
					end
				end
			case 'localcont'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = (max(sample(:))-min(sample(:)))/(mean(sample(:))+eps);
					end
				end
			case 'ratio'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						outpict(m,n,c,f) = min(sample(:))/(max(sample(:))+eps);
					end
				end
			case 'ordstat'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						sample = sort(sample(:));
						outpict(m,n,c,f) = sample(ordidx);
					end
				end
			case 'ordstatmulti'
				for n = 1:(s(2)-2*padsize(2))
					for m = 1:(s(1)-2*padsize(1))
						sample = inpict(m:(m+osm),n:(n+osn),c,f);
						sample = sort(sample(:));
						outpict(m,n,c,:) = sample(ordidx);
					end
				end
			otherwise
				error('NHFILTER: unknown mode name ''%s''',mode)
		end
	end
end

if isfloat(outpict)
	outpict = min(max(outpict,0),1);
end

if strismember(mode,fpmodes)
	outpict = imcast(outpict,inclass);
end







