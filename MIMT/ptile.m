function outpict = ptile(inpict,szo,varargin)
%  OUTPICT = PTILE(INPICT,OUTSIZE,{OFFSET})
%    Create an image by repeating a smaller image to fill a specified geometry.
%    This can be used for generating images from tileable pattern/texture images.
%
%  INPICT is an image of any standard image class.  
%    multichannel and multiframe images are supported
%  OUTSIZE is a 2-element vector specifying the output page geometry
%  OFFSET optionally specifies the tiling offset in pixels ([y x]; default [0 0])
%    This offset can be used to shift a repeating pattern by a given amount.
%    Offsets in the range of (-1 1) are interpreted as being relative to the 
%    geometry of INPICT.  Mixed absolute/relative specification is supported.
%    
%  Output class is inherited from INPICT
% 
%  See also: imtile, colorpict

os = [0 0];
if nargin>2
	os = varargin{1};
end

szo = round(szo(1:2)); % only page geometry matters
szi = imsize(inpict,2);

% prepare offset
if isscalar(os)
	os = repmat(os,[1 2]);
end
isrelative = abs(os)<1;
osr = round(os.*szi);
os(isrelative) = osr(isrelative);
os = mod(round(os),szi);

% replicate the image
nreps = ceil(szo./szi)+1;
outpict = repmat(inpict,[nreps 1 1]);

% crop the image
yrange = 1+os(1):szo(1)+os(1);
xrange = 1+os(2):szo(2)+os(2);
outpict = outpict(yrange,xrange,:,:);




