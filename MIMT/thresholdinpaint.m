function rempict = thresholdinpaint(bg,mode,mask,fold,method)
%   THRESHOLDINPAINT(INPICT, MODE, MASK, {FOLD}, {METHOD})
%       use PDE inpainting to estimate deleted pixel values 
%
%   INPICT is a I/RGB image
%   MASK is a 2-D logical pixel mask
%   MODE specifies where image elements should be deleted
%       and re-estimated ('rgb', 'r', 'g', 'b', 'h', 's', 'v', 'y')
%
%   when FOLD=0, estimates outside uint8 range are truncated
%   when FOLD=1, estimates outside uint8 range are folded
%
%   see 'help inpaint_nans' for info on setting METHOD
%
%   CLASS SUPPORT:
%   Output class is inherited from INPICT
%   Accepts 'double','single','uint8','uint16','int16', and 'logical'
%
%   This file makes use of John D'Errico's INPAINT_NANS()
%   http://www.mathworks.com/matlabcentral/fileexchange/4551-inpaint-nans
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/thresholdinpaint.html

if nargin == 3
    fold = 0; method = 0;
elseif nargin == 4
    method = 0;
end

mask = logical(mask);
[rempict inclass] = imcast(bg,'double');

if size(rempict,3) == 1
	mode = 'rgb';
end

% this uses replacepixels() to actually match pixels by color triplet
switch lower(mode)
    case 'rgb'
        rempict = replacepixels([NaN NaN NaN],rempict,mask);
        % fill in holes by channel
        for c = 1:1:size(rempict,3)
            channel = rempict(:,:,c);
            channel = painter(channel,fold,method);
            rempict(:,:,c) = channel;
        end

    case 'r'
        channel = rempict(:,:,1);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,1) = channel;
        
    case 'g'
        channel = rempict(:,:,2);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,2) = channel;
        
    case 'b'
        channel = rempict(:,:,3);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,3) = channel;
        
    case 'h'
        rempict = rgb2hsv(rempict);
        channel = rempict(:,:,1);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,1) = channel;
        rempict = hsv2rgb(rempict);
        
    case 's'
        rempict = rgb2hsv(rempict);
        channel = rempict(:,:,2);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,2) = channel;
        rempict = hsv2rgb(rempict);
        
    case 'v'
        rempict = rgb2hsv(rempict);
        channel = rempict(:,:,3);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,3) = channel;
        rempict = hsv2rgb(rempict);
        
	case 'y'
		T = gettfm('ypbpr','601');
		rempict = imappmat(rempict,T);
        channel = rempict(:,:,1);
        channel(mask) = NaN;
        channel = painter(channel,fold,method);
        rempict(:,:,1) = channel;
		rempict = imappmat(rempict,inv(T));
        
    otherwise
        error('THRESHOLDINPAINT: unknown mode')
end

    rempict = imcast(rempict,inclass);
end

function channel = painter(channel,fold,method)
    channel = inpaint_nans(channel,method);
    if fold == 1
        channel = abs(channel);
        channel(channel > 2) = 2-mod(channel(channel > 2),2);
        channel(channel > 1) = 1-mod(channel(channel > 1),1);
    end
end








