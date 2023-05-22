function outpict = jpegger(inpict,quality,sluramt)
%   JPEGGER(INPICT, QUALITY, {SLURAMT})
%       simply returns a copy of INPICT as subject to degradation 
%       by jpeg compression at QUALITY level
%       when a nonzero SLURAMT is specified, behavior changes
%       exploits a reversed pixel shift operation in order to cause
%       skewing of the parity maps in the degraded output image.  
%    
%   INPICT is an RGB image
%   QUALITY is the quality of the jpeg differencing copy
%   SLURAMT is a 3x2 array specifying scalings of channel shifts per axis
%       [Ry Rx; Gy Gx; By Bx] (optional) 
%
% jpegger() differs from jpegslur() in that the goal of the slur option is to
% skew only the parity map.  it is the original image vector means which
% are used to unshift the compressed image.  jpegslur() uses the difference
% of means to deliberately introduce shift errors.
%
% In other words, use of jpegger() with slur parameters is intended only to
% emphasize parity maps in heavily compressed output images, whereas
% jpegslur() would be used to skew the original quality image.
% 
% output class is uint8
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/jpegger.html
% See also: jpegslur

if nargin ~= 3
    sluramt = [0 0; 0 0; 0 0];
end

td = tempdir;

if max(max(sluramt)) == 0 && min(min(sluramt)) == 0;
    imwrite(inpict,[td 'jpegger.jpg'],'jpeg','Quality',quality);
    outpict = imread([td 'jpegger.jpg']);
    delete([td 'jpegger.jpg']);
    return
else
    shpict = lineshifter(inpict,inpict,-sluramt,'reverse');
    outpict = jpegger(shpict,quality);

    % using INPICT for second shift avoids having to half-unshift SHPICT
    if sum(sluramt(:,1)) ~= 0
       outpict = lineshifter(outpict,shpict,cat(2,sluramt(:,1),[0;0;0]));
    end
    if sum(sluramt(:,2)) ~= 0
       outpict = lineshifter(outpict,inpict,cat(2,[0;0;0],sluramt(:,2)));
    end
end
    
return

