function outpict = jpegslur(inpict,sluramt,preshift,quality,source)
%   JPEGSLUR(INPICT, SLURAMOUNT, PRESHIFT, QUALITY, SOURCE)
%       exploits jpeg compression error to reduce the reversibility 
%       of a pixel shift operation.  Performs a vector shift on INPICT
%       based on the difference of vector averages of INPICT
%       and a compressed copy.  Performs row shifts first.
%    
%   INPICT is an RGB image
%   SLURAMT is a 3x2 array specifying scalings of channel shifts per axis
%       [Ry Rx; Gy Gx; By Bx]  
%       used with both PRESHIFT and primary error-scaled shift operations
%   PRESHIFT scaling factor used with SLURAMOUNT when INPICT is shifted 
%       prior to compression and differencing
%       PRESHIFT==0 results in a sparser error pattern 
%       for PRESHIFT>0, differencing occurs on a shifted image pair
%       this changes the localization and value-dependence of the errors
%   QUALITY is the quality of the jpeg differencing copy
%   SOURCE is the source for the returned image
%       'original' performs difference shift on INPICT (default)
%       'compressed' performs difference shift on compressed copy of INPICT
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
% Webdocs: http://mimtdocs.rf.gd/manual/html/jpegslur.html
% See also: jpegger

%   old method
%     wpict=lineshifter(inpict,inpict,sluramt,'normal');
%     wpict=jpegger(wpict,quality);
%     outpict=lineshifter(wpict,wpict,-sluramt,'reverse');

if nargin ~= 5;
    source = 'original';
end

s = size(inpict);

% all this unshifting business is to avoid an issue
% when PRESHIFT>0 and SLURAMT applies two shifts on one channel:
% shifts are not necessarily spatially correspondent to the original image
% meanshifter isn't either, but we're trying to keep the errors located.
% first part is identical to using JPEGGER(), but we need the intermediates
% i.e.  cpict=jpegger(inpict,quality,sluramt*preshift);

shpict = lineshifter(inpict,inpict,-sluramt*preshift,'reverse');
chpict = jpegger(shpict,quality);

% using INPICT for INLINES2 avoids having to half-unshift SHPICT
inlines1 = meanlines(shpict,2); % get skewed hq row offsets
inlines2 = meanlines(inpict,1); % get hq col offsets

% unscramble CHPICT based on vector means of shifted INPICT
cpict = lineshifter(chpict,inlines1,cat(2,sluramt(:,1)*preshift,[0;0;0]));
cpict = lineshifter(cpict,inlines2,cat(2,[0;0;0],sluramt(:,2)*preshift));

clines1 = meanlines(cpict,2);
clines2 = meanlines(cpict,1);
difflines1 = imcast(inlines1,'double')-imcast(clines1,'double');
difflines2 = imcast(inlines2,'double')-imcast(clines2,'double');  

outpict = uint8(zeros(s));
if strcmpi(source,'original');
    
    outpict = lineshifter(inpict,difflines1,cat(2,sluramt(:,1),[0;0;0]));
elseif strcmpi(source,'compressed');
    
    outpict = lineshifter(cpict,difflines1,cat(2,sluramt(:,1),[0;0;0]));
end

outpict = lineshifter(outpict,difflines2,cat(2,[0;0;0],sluramt(:,2)));

return







