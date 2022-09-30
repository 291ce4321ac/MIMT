function outpict = paritysweep(bg,modsize,width)
%   PARITYSWEEP(INPICT, MODSIZE, WIDTH)
%       returns an imageset of length MODSIZE wherein each frame is a map
%       of all pixels where mod(pixel,modsize) matches a group of values 
%       of count WIDTH.  This sampling window is swept from 0 to MODSIZE 
%       circularly over the entire imageset. 
%       Use with JPEGGER() to emphasize compression artifacts.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/paritysweep.html
% See also: jpegger

s = size(bg);
paritymap = mod(bg,modsize);
outpict = zeros([s modsize],'uint8');
for f = 0:1:modsize-1;
    wpict = zeros(s,'uint8');
    wpict(paritymap >= f & paritymap < min(f+width,modsize)) = 255; %additive
    if f+width > modsize-1;
        wpict(paritymap >= 0 & paritymap < mod(f+width,modsize)) = 255; %additive
    end
    
    outpict(:,:,:,f+1) = wpict;
end

return
















