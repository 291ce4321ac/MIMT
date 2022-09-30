function outpict = roiflip(inpict,mask,dim,varargin)
%   ROIFLIP(INPICT, MASK, DIM, {CONTINUITY})
%       returns a copy of the input image wherein all pixels
%       selected by the mask are flipped along a specified dimension.
%       
%   INPICT is an I/RGB image of any standard image class
%   MASK is an I/RGB logical array
%   DIM specifies the dimension along which the selected pixels are flipped
%   CONTINUITY specifies whether local continuity is preserved
%       'whole' specifies that all pixels selected by the mask line are flipped 
%           as a whole.  Local continuity is not preserved. 
%       'segment' specifies that pixels selected by each contiguous region are flipped
%           as independent groups.  Some local continuity is preserved (default)
%       Although CONTINUITY='segment' can help preserve continuity, it can only do so 
%       along the axis of the sample line. Shearing can still occur between lines. 
%       Results are usually pretty garbled unless mask regions are individually convex.
% 
%   Output class is inherited from input
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/roiflip.html
% See also: roishift


continuitystrings = {'whole','segment'};
continuity = 'segment';

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case continuitystrings
				continuity = lower(varargin{k});
				k = k+1;
			otherwise
				error('ROIFLIP: unknown input parameter name %s',varargin{k})
		end
	end
end

% check image/mask correspondence
s = size(inpict);
sm = size(mask);
if any(s(1:2) ~= sm(1:2))
	error('ROIFLIP: image size %s and mask size %s don''t match',mat2str(s(1:2)),mat2str(sm(1:2)))
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
        error('ROIFLIP: dim 3 of images must have size 1 or 3')
    end
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
                bline(mline) = flipd(bline(mline),2);
                outpict(m,:,c) = bline;
            end
        end
    else
        for c = 1:1:cbg;
            for n = 1:1:s(2);
                bline = inpict(:,n,c);
                mline = mask(:,n,c);
                bline(mline) = flipd(bline(mline),1);
                outpict(:,n,c) = bline;
            end
        end
    end
    
else
	% flip by segment
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
                        bline(starts(r):ends(r)) = flipd(bline(starts(r):ends(r)),2);
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
                        bline(starts(r):ends(r)) = flipd(bline(starts(r):ends(r)),1);
                    end

                end
                
                outpict(:,n,c) = bline;
            end
        end
    end

end

return

    

























