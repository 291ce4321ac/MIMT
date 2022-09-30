function outpict = nhfilter(inpict,varargin)
%   OUTPICT=NHFILTER(INPICT,MODE,{BLOCKSIZE})
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
%
%   BLOCKSIZE specifies the size of the rectangular neighborhood used for sampling (default [5 5])
%      May be specified as a vector or as a scalar with implicit expansion.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/nhfilter.html
% See also: nlfilter, medfilt2, stdfilt, rangefilt, morphops


blocksize = [5 5];
fpmodes = {'std','stdn','ratio','localcont'};
fbonly = {'stdn','ratio','mode','localcont'};
% modefilt is R2020a+, so i can't test it even if i added it conditionally

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		thisarg = varargin{k};
		if isnumeric(thisarg)
			if any(numel(thisarg) == [1 2])
				blocksize = thisarg;
				k = k+1;
			else
				error('NHFILTER: expected BLOCKSIZE to be a scalar or a 2-element vector')
			end
		elseif ischar(thisarg)
			mode = lower(thisarg);
			k = k+1;
		end
	end
end

if numel(blocksize) == 1
	blocksize = [1 1]*blocksize;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% IF IPT IS INSTALLED
if license('test', 'image_toolbox') && ~strismember(mode,fbonly)
	
	s0 = imsize(inpict);
	outpict = zeros(s0,class(inpict));
	for f = 1:s0(4)
		for c = 1:s0(3)
			switch mode
				case 'median'
					outpict(:,:,c,f) = medfilt2(inpict(:,:,c,f),blocksize);
				case 'std'
					outpict(:,:,c,f) = stdfilt(inpict(:,:,c,f),ones(blocksize));				
				case 'range'
					outpict(:,:,c,f) = rangefilt(inpict(:,:,c,f),ones(blocksize));
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

s0 = imsize(inpict);
padsize = floor(blocksize/2);
inpict = padarrayFB(inpict,padsize,'replicate','both');
s = imsize(inpict);

outpict = imzeros(s0,class(inpict));
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







