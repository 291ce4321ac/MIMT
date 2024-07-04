function outpict = rbdetile(inpict,nblocks,varargin)
%  OUTPICT = RBDETILE(INPICT,NBLOCKS,{BLOCKSIZE})
%    Random blockwise detiling.  Extract a number of randomly-positioned
%    blocks of a specified geometry from an image.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%  NBLOCKS specifies how many blocks to extract (scalar)
%  BLOCKSIZE specifies the 2D geometry of the extracted blocks ([rows cols])
%    May be a 2-element vector or as a scalar with implicit expansion.  
%    If either element is <1, it will be treated as a fraction of the
%    image size along that dimension.  Default BLOCKSIZE is [0.1 0.1].
%
%  Output class is inherited from input.
%
%  See also: imdetile, imfold, imtile

% set defaults
sz = imsize(inpict,2);
bs = ceil(sz/10);

% get inputs
if nargin>2
	bs = varargin{1};
end

% check/expand inputs
nblocks = round(nblocks(1));
if numel(bs)>2
	error('RBDETILE: BLOCKSIZE is expected to be either a scalar or a 2-element vector.')
end
if isscalar(bs)
	bs = repmat(bs,[1 2]);
end
bs = reshape(bs,1,2);

% if bs<1, treat it as a fraction of the image geometry
isrelative = bs<1;
bsr = ceil(sz.*bs);
bs(isrelative) = bsr(isrelative);

% clamp
bs = max(min([round(bs); sz],[],1),1);

% get random offsets
xos = randi([0 sz(2)-bs(2)],nblocks,1);
yos = randi([0 sz(1)-bs(1)],nblocks,1);

% extract blocks
outpict = imzeros([bs size(inpict,3) nblocks],class(inpict));
for f = 1:nblocks
	outpict(:,:,:,f) = inpict(yos(f)+1:yos(f)+bs(1),xos(f)+1:xos(f)+bs(2),:);
end







