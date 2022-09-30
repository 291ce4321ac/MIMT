function R = imerror(A,B,varargin)
%  R=IMERROR(IMAGEA,IMAGEB,{SCALING},{TYPE})
%  Calculate the RMS or mean-square value of the difference of two arrays.
%
%  IMAGEA, IMAGEB are two arrays of the same size
%  SCALING optionally specifies how the inputs should be treated
%     'native' treats the inputs as-is.  This may be useful for general data,
%         but using this option with images of differing class results in nonsense.
%     'normalized' assumes the inputs are images, and normalizes them WRT their 
%         typical class-dependent white values.  This ensures the inputs are always
%         comparable, and it ensures that results are always scaled the same, 
%         regardless of the input classes. This is the default.
%  TYPE optionally specifies the error type (default 'rms')
%     'rms' calculates the RMS value of the difference
%     'mse' calculates the mean-square of the difference.  This is what immse() does.
%     'mae' calculates the mean absolute difference
%     'psnr' calculates the peak signal-noise ratio. When using the 'native option, 
%            the peak value is derived from the class of IMAGEA.
%
%  Output class is double
%
% See also: imcompare, dotmask, imstats, imrange, immse


sa = imsize(A);
sb = imsize(B);
if any(sa ~= sb)
	error('IMERROR: input images need to be the same size')
end

normalizestrings = {'native','normalized'};
normalize = 'normalized';
typestrings = {'rms','mse','mae','psnr'};
type = 'rms';

if numel(varargin) > 0
	for k = 1:numel(varargin)
		switch lower(varargin{k})
			case normalizestrings
				normalize = varargin{k};
			case typestrings
				type = varargin{k};
			otherwise
				error('IMERROR: unrecognized option %s',varargin{k})
		end
	end
end

if strcmp(type,'psnr')
	if strcmp(normalize,'normalized')
		wv = 1;
	else
		wv = imcast(1,class(A));
	end
end

switch normalize
	case 'normalized'
		err = imcast(A,'double')-imcast(B,'double');
	case 'native'
		err = double(A)-double(B);
end
	
switch type
	case 'rms'
		R = sqrt(mean(err(:).^2));
	case 'mse'
		R = mean(err(:).^2);
	case 'mae'
		R = mean(abs(err(:)));
	case 'psnr'
		R = 10*log10(wv^2/mean(err(:).^2));
end




