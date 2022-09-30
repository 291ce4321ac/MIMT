function outpict = roishift(inpict,mask,dim,amt,varargin)
%   ROISHIFT(INPICT, MASK, DIM, AMOUNT, {CONTINUITY}, {FILL})
%       returns a copy of the input image wherein all pixels
%       selected by the mask are shifted along a specified dimension.
%       
%   INPICT is an I/RGB image of any standard image class
%   MASK is an I/RGB logical array
%   DIM specifies the dimension along which the selected pixels are shifted
%   AMOUNT is a scalar specifying the number of pixels to shift
%   CONTINUITY specifies whether local continuity is preserved
%       'whole' specifies that all pixels selected by the mask line are shifted 
%           as a whole.  Local continuity is not preserved. 
%       'segment' specifies that pixels selected by each contiguous region are shifted
%           as independent groups.  Some local continuity is preserved (default)
%       Although CONTINUITY='segment' can help preserve continuity, it can only do so 
%       along the axis of the sample line. Shearing can still occur between lines. 
%       Results are usually pretty garbled unless mask regions are individually convex.
%   FILL specifies how the trailing edge pixels are filled
%       if 'circular', the shift is circular (default)
%       if 'replicate', the trailing pixel value is replicated
%       if specified as a color value or RGB triplet, fill will be specified color
%           Colors should be specified wrt the white value implied by the class
%           of INPICT (e.g. [32 158 7] for 'uint8')
% 
%   Output class is inherited from input
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/roishift.html
% See also: roiflip


fillstrings = {'circular','replicate'};
fill = 'circular';
continuitystrings = {'whole','segment'};
continuity = 'segment';

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		if isnumeric(varargin{k})
			fill = varargin{k};
			k = k+1;
		elseif ischar(varargin{k})
			switch lower(varargin{k})
				case fillstrings
					fill = lower(varargin{k});
					k = k+1;
				case continuitystrings
					continuity = lower(varargin{k});
					k = k+1;
				otherwise
					error('ROISHIFT: unknown input parameter name %s',varargin{k})
			end
		end
	end
end

% check image/mask correspondence
s = size(inpict);
sm = size(mask);
if any(s(1:2) ~= sm(1:2))
	error('ROISHIFT: image size %s and mask size %s don''t match',mat2str(s(1:2)),mat2str(sm(1:2)))
end

cbg = size(inpict,3);
cm = size(mask,3);
if cbg ~= cm
    if cbg == 1 && cm == 3 % I image, RGB mask
        inpict = repmat(inpict,[1 1 3]); 
        s = size(inpict);
        cbg = size(inpict,3);
    elseif cm == 1 && cbg == 3 % RGB image, I mask
        mask = repmat(mask,[1 1 3]); 
    else
        error('ROISHIFT: dim 3 of images must have size 1 or 3')
    end
end

if isnumeric(fill) && numel(fill) ~= cbg
    error('ROISHIFT: RGB fill value must have same number of channels as INPICT')
elseif ~isnumeric(fill) && ~(strcmpi(fill,'replicate') || strcmpi(fill,'circular'))
    error('ROISHIFT: unknown fill type')
end

mask = imcast(mask,'logical');
outpict = imzeros(s,class(inpict));
if strcmp(continuity,'whole')
    % flip entire line
    if dim == 2
        for c = 1:1:cbg;
            for m = 1:1:s(1);
                bline = inpict(m,:,c);
                mline = mask(m,:,c);
                bsroi = circshift(bline(mline),[0 amt]);
                if numel(bsroi) > 0
                    mr = numel(bsroi);
                    if strcmpi(fill,'replicate')
                        if amt > 0
                            bsroi(1:min(amt,mr)) = bsroi(mod(amt,mr)+1);
                        else
                            bsroi(max(end-(amt-1),1):end) = bsroi(mod(end-amt,mr));
                        end
                    elseif isnumeric(fill)
                        if amt > 0
                            bsroi(1:min(amt,mr)) = fill(c);
                        else
                            bsroi(max(end-(amt-1),1):end) = fill(c);
                        end
                    end

                    bline(mline) = bsroi;
                end
                outpict(m,:,c) = bline;
            end
        end
	else
		% flip by segment
        for c = 1:1:cbg;
            for n = 1:1:s(2);
                bline = inpict(:,n,c);
                mline = mask(:,n,c);
                bsroi = circshift(bline(mline),[amt 0]);
                if numel(bsroi) > 0
                    mr = numel(bsroi);
                    if strcmpi(fill,'replicate')
                        if amt > 0
                            bsroi(1:min(amt,mr)) = bsroi(mod(amt,mr)+1);
                        else
                            bsroi(max(end-(amt-1),1):end) = bsroi(mod(end-amt,mr));
                        end
                    elseif isnumeric(fill)
                        if amt > 0
                            bsroi(1:min(amt,mr)) = fill(c);
                        else
                            bsroi(max(end-(amt-1),1):end) = fill(c);
                        end
                    end

                    bline(mline) = bsroi;
                end
                outpict(:,n,c) = bline;
            end
        end
    end
    
else
    if dim == 2
        for c = 1:1:cbg;
            for m = 1:1:s(1);
                bline = inpict(m,:,c);
                mline = mask(m,:,c);

                if any(mline)
                    marks = diff([0 mline]);
                    starts = (1:length(mline)).*(marks == 1);
                    ends = ((1:length(mline))-1).*(marks == -1);
                    starts = starts(starts ~= 0);
                    ends = ends(ends ~= 0);
                    
                    % close ROI if still open at end of line
                    if numel(starts) > numel(ends)
                        ends = [ends  length(mline)];
                    end

                    for r = 1:length(starts);
                        bsroi = circshift(bline(starts(r):ends(r)),[0 amt]);
                        if numel(bsroi) > 0
                            mr = numel(bsroi);
                            if strcmpi(fill,'replicate')
                                if amt > 0
                                    bsroi(1:min(amt,mr)) = bsroi(mod(amt,mr)+1);
                                else
                                    bsroi(max(end-(amt-1),1):end) = bsroi(mod(end-amt,mr));
                                end
                            elseif isnumeric(fill)
                                if amt > 0
                                    bsroi(1:min(amt,mr)) = fill(c);
                                else
                                    bsroi(max(end-(amt-1),1):end) = fill(c);
                                end
                            end

                            bline(starts(r):ends(r)) = bsroi;
                        end
                    end

                end

                outpict(m,:,c) = bline;
            end
        end
    else
        for c = 1:1:cbg;
            for n = 1:1:s(2);
                bline = inpict(:,n,c);
                mline = mask(:,n,c);
                
                if any(mline)
                    marks = diff([0; mline]);
                    starts = (1:length(mline)).*(marks == 1)';
                    ends = ((1:length(mline))-1).*(marks == -1)';
                    starts = starts(starts ~= 0);
                    ends = ends(ends ~= 0);

                    % close ROI if still open at end of line
                    if numel(starts) > numel(ends)
                        ends = [ends  length(mline)];
                    end
                    
                    for r = 1:length(starts);
                        bsroi = circshift(bline(starts(r):ends(r)),[amt 0]);
                        if numel(bsroi) > 0
                            mr = numel(bsroi);
                            if strcmpi(fill,'replicate')
                                if amt > 0
                                    bsroi(1:min(amt,mr)) = bsroi(mod(amt,mr)+1);
                                else
                                    bsroi(max(end-(amt-1),1):end) = bsroi(mod(end-amt,mr));
                                end
                            elseif isnumeric(fill)
                                if amt > 0
                                    bsroi(1:min(amt,mr)) = fill(c);
                                else
                                    bsroi(max(end-(amt-1),1):end) = fill(c);
                                end
                            end

                            bline(starts(r):ends(r)) = bsroi;
                        end
                    end

                end
                
                outpict(:,n,c) = bline;
            end
        end
    end

end

return

    

























