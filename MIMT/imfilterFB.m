function outpict = imfilterFB(inpict,fk,varargin)
%   OUTPICT=IMFILTERFB(INPICT,FK,{OPTIONS})
%   Filter an image using a specified filter kernel.
%
%   This is mostly a passthrough to the IPT function imfilter(), with an internal 
%   fallback implementation to help remove the dependency of MIMT tools on the 
%   Image Processing Toolbox. As with other fallback tools, performance without 
%   IPT may be limited or otherwise slightly different due to the methods used.
%
%   INPICT is an image array of any standard image class; 4D arrays are supported.
%      While imresize() supports indexed images, the fallback method does not.
%   FK is the filter kernel
%      While imfilter() supports 3-D filters, the fallback method currently only  
%      supports 1D or 2D filters.
%   OPTIONS may include any of the following:
%      SHAPE keys specify what part of the filtered image is returned (default 'same')
%         'full' return the entire filtered image (including padding)
%         'same' return only the central area corresponding to the original image
%      METHOD keys specify the type of operation (default 'corr')
%         'corr' specifies correlation
%         'conv' specifies convolution (filter is rotated by 180 degrees)
%      BOUNDARY specifies how the image should be padded prior to filtering
%         'replicate' replicates the adjacent edge vectors of INPICT
%         'symmetric' mirrors the image content local to the padding area
%         'circular' copies image content opposite the padding area
%         Alternatively, a numeric value may be used.  
%         Contrary to the IPT defaults, the default for imfilterFB is 'replicate' 
%         regardless of IPT availability.
%   
%  Examples:
%    Blur an image using a gaussian kernel and defaults
%       outpict=imfilterFB(inpict,fkgen('gaussian',10));
%    Instead of zero-padding, use a 50% gray padding; return full padded array
%       outpict=imfilterFB(inpict,fkgen('gaussian',10),0.5,'full');
%    Use non-constant padding instead
%       outpict=imfilterFB(inpict,fkgen('gaussian',10),'symmetric');
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imfilterFB.html
% See also: imfilter, conv2, fspecial, fkgen

% these defaults need to be available early for both IPT and non-IPT paths
padtypestrings = {'zeros','symmetric','replicate','circular'};
padtype = 'replicate';

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	padargidx = [];
	for k = 1:numel(varargin)
		if ischar(varargin{k}) && strismember(lower(varargin{k}),padtypestrings)
			padargidx = k;
		end
	end
	if ~isempty(padargidx)
		varargin{padargidx} = padtype;
	else
		varargin = [varargin {padtype}];
	end
	outpict = imfilter(inpict,fk,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

shapestrings = {'full','same'};
shape = 'same';
methodstrings = {'conv','corr'};
method = 'corr';
padval = 0;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		if isimageclass(varargin{k})
			padval = varargin{k};
		elseif ischar(varargin{k})
			switch lower(varargin{k})
				case methodstrings
					method = lower(varargin{k});
				case shapestrings
					shape = lower(varargin{k});
				case padtypestrings
					padtype = lower(varargin{k});
				otherwise
					error('IMFILTERFB: unrecognized argument %s',varargin{k})
			end
		end
		k = k+1;
	end
end

[inpict inclass] = imcast(inpict,'double');

if strcmp(method,'corr')
	fk = reshape(flipud(fk(:)),size(fk));
end

sfk = imsize(fk);
if strcmp(shape,'same')
	padsize = sfk(1:2)-floor((sfk(1:2)+1)/2);
	outsize = imsize(inpict,2);
else
	padsize = sfk(1:2)-1;
	outsize = imsize(inpict,2)+padsize;
end

if strcmp(padtype,'value')
	inpict = padarrayFB(inpict,padsize,padval,'both');
else
	inpict = padarrayFB(inpict,padsize,padtype,'both');
end

outpict = zeros([outsize size(inpict,3) size(inpict,4)],'double');
for f = 1:size(inpict,4)
	for c = 1:size(inpict,3)
		outpict(:,:,c,f) = cropborder(conv2(inpict(:,:,c,f),fk,shape),padsize);
	end
end
outpict = imcast(outpict,inclass);





