function  inpict = lineshifter(inpict,mask,amt,order)
%   LINESHIFTER(INPICT, MASK, SHIFTAMOUNT, {ORDER});
%       returns a copy of the input image, with pixels circularly shifted
%       proportional to the row and column means of a specified mask
%
%   INPICT is an I/RGB image of any standard image class
%   MASK is an I/RGB image of any standard image class
%       MASK will be expanded/collapsed to match number of channels in INPICT
%   SHIFTAMOUNT scales the shift amounts described by MASK
%       for RGB inputs, expressed as a 3x2 array [Rx Ry; Gx Gy; Bx By]
%       can also be expressed as a 1x2 vector with implicit expansion
%   ORDER specifies which axis to shift first
%       'normal' shifts columnwise first (default)
%       'reverse' shifts row-wise first (used to undo shifts)
%       use 'reverse' and negate SHIFTAMOUNT to undo a 'normal' shift
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/lineshifter.html
    
if ~exist('order','var')
    order = 'normal';
end

s = size(inpict);
[cc ~] = chancount(inpict);
inpict = inpict(:,:,1:cc);

% expand/collapse amount parameter
if size(amt,1) == 1 && cc == 3
	amt = repmat(amt,[cc 1]);
elseif size(amt,1) == 3 && cc == 1
	amt = amt(1,:);
end

% expand/collapse mask image
[ccm ~] = chancount(mask);
mask = mask(:,:,1:ccm);
if cc == 1 && ccm == 3
	mask = mono(mask,'y');
elseif cc == 3 && ccm == 1
	mask = repmat(mask,[1 1 3]);
end

% it would make more sense to have the mask means scaled [0 1] and treat that as a proportion of image width/height
% but this stupid function was originally uint8-only, so let's just scale things to match the legacy behavior
if sum(abs(amt(:,1))) ~= 0
    rowmeans = mod(round(imrescale(mean(mask,2),class(mask),'uint8').*permute(repmat(amt(:,1)',[s(1) 1 1]),[1 3 2])),s(2));
end
if sum(abs(amt(:,2))) ~= 0
    colmeans = mod(round(imrescale(mean(mask,1),class(mask),'uint8').*permute(repmat(amt(:,2),[1 s(2) 1]),[3 2 1])),s(1));
end


% these loops look like a huge waste of time, but it's not as bad as it seems
% this is actually about 4x faster than methods using interp2
% and it's about 3x faster than direct indexing by channel (sub2ind is slow)
if strcmpi(order,'reverse')
    for c = 1:cc
        if amt(c,2) ~= 0
            for n = 1:s(2)
				inpict(:,n,c) = circshift(inpict(:,n,c),colmeans(1,n,c));
            end
        end
    end
end    

for c = 1:cc
    if amt(c,1) ~= 0
        for n = 1:s(1)
            inpict(n,:,c) = circshift(inpict(n,:,c),[0 rowmeans(n,1,c)]);
        end
    end
end

if strcmpi(order,'normal')
    for c = 1:cc
        if amt(c,2) ~= 0
            for n = 1:s(2)
				inpict(:,n,c) = circshift(inpict(:,n,c),colmeans(1,n,c));
            end
        end
    end
end




return












