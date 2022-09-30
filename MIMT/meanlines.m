function  outpict = meanlines(inpict,dim,mode)
%   MEANLINES(INPICT, DIM, {MODE})
%       Returns an image wherein all pixels in row or column vectors have 
%       the mean, max, or min values in corresponding vectors of INPICT.
%       Can be used for shading or shifting images.
%
%   INPICT is an I/RGB image of any standard image class
%       If alpha content is present, it will be preserved but otherwise ignored.
%   DIM is the dimension on which to sample
%       1 finds column means or extrema and produces vertical bands
%       2 finds row means or extrema and produces horizontal bands
%   MODE accepts 'mean', 'max', or 'min' (default 'mean')
%       also accepts 'max y' and 'min y' which select extrema based on luma
%       luma modes tend to make more visual sense since pixels are selected as a whole
%       rgb modes select extrema in a channel-independent fashion
%
%   Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/meanlines.html

   
if ~exist('mode','var')
    mode = 'mean';
end

mode = lower(mode(mode ~= ' '));

if ~any(dim == [1 2])
	error('MEANLINES: expected DIM to be either 1 or 2')
end

[inpict inclass] = imcast(inpict,'double');
s = size(inpict);
[nc na] = chancount(inpict);
if na ~= 0; inalpha = inpict(:,:,nc+na); end
inpict = inpict(:,:,1:nc);

% this avoids ever having to waste time on things that don't change the output
if nc == 1
	switch mode
		case 'maxy'
			mode = 'max';
		case 'miny'
			mode = 'min';
	end
end

outpict = zeros(s);
switch mode
    case'mean'
		outpict = mean(inpict,dim);
		if dim == 1
			outpict = repmat(outpict,[s(1) 1 1]);
		else
			outpict = repmat(outpict,[1 s(2) 1]);
		end
		
    case 'max'
		outpict = max(inpict,[],dim);
		if dim == 1
			outpict = repmat(outpict,[s(1) 1 1]);
		else
			outpict = repmat(outpict,[1 s(2) 1]);
		end
		
    case 'min'
        outpict = min(inpict,[],dim);
		if dim == 1
			outpict = repmat(outpict,[s(1) 1 1]);
		else
			outpict = repmat(outpict,[1 s(2) 1]);
		end
		
    case 'maxy'
        inluma = mono(inpict,'y');
		[~, idx] = max(inluma,[],dim);
		if dim == 2
			idx = sub2ind(s(1:2),1:s(1),idx');
			for c = 1:nc
				thischan = inpict(:,:,c);
				outpict(:,:,c) = repmat(thischan(idx)',[1 s(2)]);
			end
		else
			idx = sub2ind(s(1:2),idx,1:s(2));
			for c = 1:nc
				thischan = inpict(:,:,c);
				outpict(:,:,c) = repmat(thischan(idx),[s(1) 1]);
			end
		end
		
	case 'miny'
        inluma = mono(inpict,'y');
		[~, idx] = min(inluma,[],dim);
		if dim == 2
			idx = sub2ind(s(1:2),1:s(1),idx');
			for c = 1:nc
				thischan = inpict(:,:,c);
				outpict(:,:,c) = repmat(thischan(idx)',[1 s(2)]);
			end
		else
			idx = sub2ind(s(1:2),idx,1:s(2));
			for c = 1:nc
				thischan = inpict(:,:,c);
				outpict(:,:,c) = repmat(thischan(idx),[s(1) 1]);
			end
		end

    otherwise
        error('MEANLINES: invalid mode')
end

if na ~= 0;
	outpict = imcast(cat(3,outpict,inalpha),inclass);
else
	outpict = imcast(outpict,inclass);
end
    
return

