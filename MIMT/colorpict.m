function outpict = colorpict(imsize,cvec,outclass)
%   COLORPICT(IMSIZE,CVEC,{OUTCLASS})
%       returns an image of size IMSIZE with a solid color fill
%      
%   IMSIZE is the image size in pixels (2-D, HxW)
%   CVEC is a tuple defining the color and alpha content of the image
%      Basic sanity enforcement expects I/IA/RGB/RGBA/RGBAAA formats.
%      Values should be specified with respect to the white value
%      implied by the class of CVEC, or by OUTCLASS, if specified.  
%   OUTCLASS explicitly specifies the class of the output image.  
%      Supports all standard image class names.
% 
%   Output class is inherited from CVEC unless explicitly specified.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/colorpict.html

if ~exist('outclass','var')
	outclass = class(cvec);
end

outpict = imones([imsize(1) imsize(2) numel(cvec)],outclass);
% bsxfun doesn't work for integers/logical class; just loop it
for c = 1:numel(cvec)
	outpict(:,:,c) = cvec(c);
end

