function outpict = unsharp(inpict,varargin)
%  OUTPICT = UNSHARP(INPICT,{OPTIONS})
%  Sharpen an image using unsharp masking.
%  
%  INPICT is an image of any standard image class.
%    Multipage and multiframe images are supported.
%  OPTIONS includes the key-value pairs:
%  'sigma' optionally specifies the size of the lowpass filter
%    (scalar, default 3)
%  'amount' optionally scales the weight  of the sharpening layer.
%    (scalar, default 0.5)
%  'thresh' optionally omits low-contrast regions of the sharpening
%    layer.  This helps reduce the tendency to amplify low-amplitude
%    noise in relatively smooth image regions.  This is a scalar
%    in the range [0 1]. (default 0)
%
%  Output class is inherited from input.
%
%  See also: fkgen, imfilterFB, imsharpen, edgemap

% defaults
sigma = 3;
amount = 0.5;
thresh = 0;

if nargin>1
	k = 1;
	while k <= numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case {'sig','sigma'}
				sigma = varargin{k+1};
				k = k+2;
			case {'amt','amount'}
				amount = varargin{k+1};
				k = k+2;
			case {'th','thresh','threshold'}
				thresh = varargin{k+1};
				k = k+2;
			otherwise
				error('UNSHARP: unknown key %s',thisarg)
		end
	end
end


[inpict inclass] = imcast(inpict,'double');

% i'm not sure why IPT imsharpen() does things in LAB
%inpict = rgb2lab(inpict);

% lowpass filter the source image
fk = fkgen('techgauss2',2*ceil(2*sigma)+1,'sigma',sigma);
gpict = imfilterFB(inpict,fk,'replicate');

% IPT imsharpen() scales thresh WRT max(gpict)
% GIMP doesn't do that, but the way it works, it can't.
dpict = inpict-gpict;
if thresh>0
	mask = abs(dpict) < thresh*max(dpict(:));
	dpict(mask) = 0;
end

% linear combination
outpict = inpict + amount*dpict;

% prepare output
%outpict = lab2rgb(outpict);
outpict = imcast(outpict,inclass);









