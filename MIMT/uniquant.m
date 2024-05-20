function outpict = uniquant(inpict,nlevels,varargin)
%  OUTPICT = UNIQUANT(INPICT,NLEVELS,{INRANGE},{MODE})
%  Convert an array (e.g. a grayscale image) to an indexed image 
%  by simple uniform quantization.
%
%  INPICT is a numeric array
%    For 'default' and 'cdscale' modes, INPICT can have any dimensionality. 
%    For dither modes, INPICT must be 2D.
%  NLEVELS is a positive scalar between 1 and 65536
%  INRANGE optionally specifies the input range used during normalization
%    When unspecified, the image is normalized with respect to its extrema.
%  MODE optionally specifies how the data is quantized.  
%    'default' The behavior matches that of gray2ind(), where the end bins are 
%       centered on the input limits, effectively making them half-width for 
%       default INRANGE.
%    'cdscale' The behavior is similar to imagesc() or image() with CDataScaling 
%       set to 'scaled'.  The end bins are adjacent to the input limits, and 
%       all bins are equal-width.
%    'fsdither' Uses a Floyd-Steinberg dithering as would rgb2ind(). 
%    'zfdither' Uses a Zhou-Fang variable-coefficient error-diffusion dither. 
%    'orddither' Uses a Bayer ordered/patterned dither. 
%    The bin widths used in dither modes are comparable to those in the default.
%
%  Output class is either 'uint8' or 'uint16', depending on NLEVELS
%
%  Examples:
%    % demonstrate the mode behaviors
%    inpict = 1:12;
%    outpict = uniquant(inpict,4,'default'));
%    >> [0 0 1 1 1 1 2 2 2 2 3 3]
% 
%    outpict = uniquant(inpict,4,'cdscale'));
%    >> [0 0 0 1 1 1 2 2 2 3 3 3]
%      
%
%  See also: gray2ind, ind2rgb

% defaults
inrange = imrange(inpict);
quantmodes = {'default','cdscale','cds','fsdither','zfdither','orddither'};
thisquantmode = 'default';

if numel(varargin)>=1
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case quantmodes
					thisquantmode = thisarg;
				otherwise
					error('UNIQUANT: unknown scaling option %s',thisarg)
			end
		else
			inrange = double(thisarg);
		end
	end
end

if numel(inrange) ~= 2
	error('UNIQUANT: INRANGE must be a 2-element vector')
end

if ismember(thisquantmode,{'fsdither','zfdither','orddither'}) && ndims(inpict)>2 %#ok<ISMAT>
	error('UNIQUANT: INPICT must be 2D for dither modes')
end

% output class needs only be wide enough for the index range
nlevels = imclamp(nlevels,[1 65536]);
if nlevels <= 256
	outclass = 'uint8';
elseif nlevels <= 65536
	outclass = 'uint16';
end
	
outpict = (double(inpict) - inrange(1))./(inrange(2) - inrange(1)); % normalize
outpict = imclamp(outpict); % truncate
switch thisquantmode
	case 'default'
		outpict = outpict*(nlevels-1); % rescale
	case {'cdscale' 'cds'}
		outpict = (outpict*nlevels - 0.5)*(1-eps); % rescale
	case 'fsdither'
		dummymap = gray(nlevels);
		outpict = rgb2ind(gray2rgb(outpict),dummymap,'dither');
	case 'zfdither'
		gr0 = outpict*(nlevels-1);
		higray = ceil(gr0); % each region in the density map
		logray = floor(gr0); % may be one of two gray levels
		D = mod(gr0,1); % grayscale density map
		D = zfdither(D); % dither it
		outpict = logray; % compose the output
		outpict(D) = higray(D);
	case 'orddither'
		gr0 = outpict*(nlevels-1);
		higray = ceil(gr0); % each region in the density map
		logray = floor(gr0); % may be one of two gray levels
		D = mod(gr0,1); % grayscale density map
		D = orddither(D,16); % dither it
		outpict = logray; % compose the output
		outpict(D) = higray(D);
end
imclamp(outpict,[0 nlevels-1]); % this shouldn't be necessary, but just in case
outpict = cast(outpict,outclass); % round and cast

end

