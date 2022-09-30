function outpict = color2alpha(inpict,color)
%  OUTPICT=COLOR2ALPHA(INPICT,{COLOR})
%     Generate transparency from a specified color, adjusting the remaining
%     color content accordingly.  This is based on the corresponding GIMP 
%     plugin by Seth Burgess.
%
%  INPICT is a I/IA/RGB/RGBA image of any standard image class
%  COLOR is either a scalar or triplet, scaled to a white level of 1.
%     Scalar inputs will be expanded as necessary with RGB/RGBA images.
%     If omitted or empty, the image mode (most frequent color) will be used.
%     For multiframe images, this will be the mode of all frames.  For per-
%     frame mode calculation, use fourdee(@color2alpha,inpict).  
%  
%  Class of OUTPICT is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/color2alpha.html

% if comparing this to GIMP behavior, keep in mind that 'remove alpha channel' in GIMP
% actually fills transparent regions with the current BG color, making the result appear misleading
% just slam the alpha channel using levels/curves tool instead

[inpict inclass] = imcast(inpict,'double');

s = imsize(inpict);
[inpict inalpha] = splitalpha(inpict);
cc = s(3);
numframes = s(4);

if exist('color','var') && numel(color) > 0
	% check/expand color spec if given
	if numel(color) ~= cc
		if numel(color) == 1 && cc == 3
			color = [1 1 1]*color;
		else
			error('COLOR2ALPHA: Length of COLOR does not correspond to number of INPICT channels')
		end
	end
else
	% calculate image mode if no color spec given
	color = imstats(inpict,'modecolor');
end

outpict = zeros([s(1:2) cc+1 numframes]);
walpha = zeros([s(1:2) cc numframes]);

% calculate output alpha
for c = 1:cc
	if color(c) < 0.0001
		walpha(:,:,c,:) = inpict(:,:,c,:);
	else
		cdiff = abs(inpict(:,:,c,:)-color(c));
		mA = inpict(:,:,c,:) > color(c);
		mB = inpict(:,:,c,:) < color(c);
		walpha(:,:,c,:) = cdiff./(1-color(c)+eps) .* mA + cdiff./color(c) .* mB;
	end
end
outpict(:,:,end,:) = max(walpha,[],3);

% adjust color content
for c = 1:cc
	outpict(:,:,c,:) = (inpict(:,:,c,:)-color(c))./outpict(:,:,end,:) + color(c);
end

% incorporate original alpha if any
outpict = joinalpha(outpict,inalpha);

% prepare output
outpict = imclamp(outpict);
outpict = imcast(outpict,inclass);







