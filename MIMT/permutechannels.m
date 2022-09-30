function outpict = permutechannels(inpict,order,mode)
%   PERMUTECHANNELS(INPICT, ORDER, MODE)
%       permutes the channels of an rgb image
%   
%   INPICT is an RGB image or 4-D array
%       can also be a triplet or colortable (see imtweak())
%       white value of INPICT must correspond to its class
%       e.g. the triplet [0 128 255] will be mishandled if of class 'double'
%   ORDER is a 3-element vector specifying the desired order of channels
%       channel assignments can be duplicated (i.e. [1 3 3])
%       if negative values are given, specified channel is inverted
%   MODE specifies what channels are permuted (default 'rgb')
%       accepts 'rgb', 'hsv', 'hsi', 'hsl', or 'hsy'
%
%   Output class matches that of the input
%   Supports standard image classes
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/permutechannels.html

if ~exist('mode','var')
	mode = 'rgb';
end

% is the image argument a color or a picture?
if size(inpict,2) == 3 && numel(size(inpict)) < 3
    inpict = permute(inpict,[3 1 2]);
    iscolorelement = 1;
else
    iscolorelement = 0;
end

[inpict inclass] = imcast(inpict,'double');

order = round(order);
if all(abs(order) > 3 | order == 0)
    disp('PERMUTECHANNELS: order specification out of range')
    return
end

outpict = zeros(size(inpict));
for f = 1:1:size(inpict,4);
	if strcmpi(mode,'rgb')
        wpict = inpict(:,:,:,f);
	elseif strcmpi(mode,'hsv')
        wpict = rgb2hsv(inpict(:,:,:,f));
	elseif strcmpi(mode,'hsi')
        wpict = rgb2hsi(inpict(:,:,:,f));
		wpict(:,:,1) = wpict(:,:,1)/360;
	elseif strcmpi(mode,'hsl')
        wpict = rgb2hsl(inpict(:,:,:,f));
		wpict(:,:,1) = wpict(:,:,1)/360;
	elseif strcmpi(mode,'hsy')
        wpict = rgb2hsy(inpict(:,:,:,f));
		wpict(:,:,1) = wpict(:,:,1)/360;
	else
        error('PERMUTECHANNELS: invalid mode specification')
	end
    
	rpict = wpict;	
    for c = 1:1:3;
        rpict(:,:,c) = (order(c) < 0)+sign(order(c))*wpict(:,:,abs(order(c)));
    end
    
    if strcmpi(mode,'rgb')
        outpict(:,:,:,f) = rpict;
    elseif strcmpi(mode,'hsv')
        outpict(:,:,:,f) = hsv2rgb(rpict);
	elseif strcmpi(mode,'hsi')
		rpict(:,:,1) = rpict(:,:,1)*360;
        outpict(:,:,:,f) = hsi2rgb(rpict);
	elseif strcmpi(mode,'hsl')
		rpict(:,:,1) = rpict(:,:,1)*360;
        outpict(:,:,:,f) = hsl2rgb(rpict);
	elseif strcmpi(mode,'hsy')
		rpict(:,:,1) = rpict(:,:,1)*360;
        outpict(:,:,:,f) = hsy2rgb(rpict);
    end
end

if iscolorelement == 1;
    outpict = permute(outpict,[2 3 1]);
end

outpict = imcast(outpict,inclass);

return
















