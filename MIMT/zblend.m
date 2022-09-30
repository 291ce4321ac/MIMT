function outpict = zblend(inframes,mask)
%   ZBLEND(INFRAMES,MASK)
%       use a mask to blend between multiple images in a 4-D array    
%
%   INFRAMES is a 4-D image array (I/IA or RGB/RGBA)
%   MASK is an image representing depth in the image stack
%       can be a single image (I or RGB)
%       can also be defined as a 4-D image array
%       dim 4 of output image matches dim 4 of MASK
%       single-channel masks will be expanded if necessary
%
%   CLASS SUPPORT:
%       inputs may be 'uint8','uint16','int16','single','double', or 'logical'
%       return class matches INFRAMES class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/zblend.html

ifchans = size(inframes,3);
mmchans = size(mask,3);

if ifchans > 1 && mmchans == 1
	mask = repmat(mask,[1 1 ifchans]);
elseif ifchans ~= mmchans
	error('ZBLEND: When MASK is multichannel, number of channels in MASK must match that of INFRAMES')
end

% safeguard things so bsxfun doesn't explode
try
	[inframes inclass] = imcast(inframes,'double');
catch b
	error('ZBLEND: Unsupported image class for INFRAMES')
end
try
	[mask inclass] = imcast(mask,'double');
catch b
	error('ZBLEND: Unsupported image class for MASK')
end

s = size(inframes);
sm = size(mask);
ninframes = size(inframes,4);
noutframes = size(mask,4);
outpict = zeros([s(1:2), size(inframes,3), noutframes],'double');

for fo = 1:noutframes
	thisoutframe = zeros([s(1:2), size(inframes,3)],'double');
	tofmask = mask(:,:,:,fo);
	m = false([sm(1:2), size(mask,3)]);
	msum = m;
	lt = 0; % lower threshold for this depth in mask
	
	for f = 1:ninframes-1
		ut = (f/(ninframes-1)); % upper threshold for this depth in mask
		m = (tofmask <= ut) & ~msum;
		msum = msum | m;
		fg = inframes(:,:,:,f+1);
		bg = inframes(:,:,:,f);
		thismask = (tofmask(m)-lt)/(ut-lt); 
		lt = ut; % increment thresholds
		
		thisoutframe(m) = bsxfun(@times,fg(m),thismask) + bsxfun(@times,bg(m),(1-thismask));
	end
	outpict(:,:,:,fo) = thisoutframe;
end

outpict = imcast(outpict,inclass);

end












