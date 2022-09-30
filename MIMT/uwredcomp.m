function RGBnew = uwredcomp(RGB,varargin)
%  OUTPICT = UWREDCOMP(INPICT,{OPTIONS})
%    Adjust underwater photographs to compensate for wavelength-dependent light 
%    attenuation and contrast loss due to diffusion effects.
%
%    Roughly based on:
%    Underwater image enhancement based on red channel weighted compensation and 
%    gamma correction model, 2018, Xiang, et al; DOI: 10.29026/oea.2018.180024
%
%    The image is color-compensated by reconstructing the red channel as a 
%    linear combination of all channel information.  The reconstructed red channel
%    is optionally filtered for noise-reduction purposes using an edge-preserving 
%    smoothing filter.  
%   
%    The resulting RGB image is subject to both global (linear+gamma) and local (CLAHE) 
%    contrast enhancement.  The output image is a weighted combination of both.
%
%  INPICT is an RGB image of any standard image class
%  OPTIONS include the key-value pairs:
%    'alpha' optionally specifies the contrast enhancement weighting (default 0.4)
%       As alpha approaches 0, the result is dominated by the CLAHE enhancement.  
%       The results will be flatter, with a relatively uniform local contrast.
%       As alpha approaches 1, the result is dominated by the linear/gamma method.
%       Highlights and shadows will be emphasiszed at the expense of local contrast
%       within bright and dark regions.
%    'gamma' adjusts the gamma used in the global contrast enhancement path (default 1)
%    'kthresh' adjusts the thresholds used when selecting the input levels in the 
%       global contrast enhancement path (default 0.01) See stretchlimFB() documentation.
%    'smoothing' controls noise reduction in the reconstructed red channel (default 0)
%       Typical values may be around 0.0001 to 0.01.  Using this option requires IPT.
%    
%  Output class is inherited from input.


% the description of the filtering process is ambiguous at best
% i'm going to ignore it and just offer an attempt to smooth Rnew
% based on G edges.  i doubt any of this is fruitful without quality sources.

% the assumption is that due to attenuation, R has lower SNR than G or B. 
% yet every single test image i've seen has been so utterly mutilated by JPG 
% compression that smoothing R alone has negligible impact on the visual 
% quality of the output.  

% the massive contrast boost and chroma shifts are the perfect scenario
% to accentuate the damage done in compression -- across _all_ channels.
% moreover, the artifacts are much larger than any random sensor noise,
% so expecting to "fix" them and preserve content is ridiculous.

% this introduces an IPT and version dependency (R2014a+)
% alternatively, this might be a case to use locallapfilt() (R2016b+)



% filter parameters
smoothing = 0;

% output adjustment parameters
kclip = 0.01;
gammaadj = 1;
alpha = 0.4;

if nargin>1
	k = 1;
	while k <= numel(varargin)
		thisarg = lower(varargin{k});
		switch thisarg
			case 'smoothing'
				smoothing = varargin{k+1};
				k = k+2;
			case 'kthresh'
				kclip = varargin{k+1};
				k = k+2;
			case 'gamma'
				gammaadj = varargin{k+1};
				k = k+2;
			case 'alpha'
				alpha = varargin{k+1};
				k = k+2;
			otherwise
				error('UWREDCOMP: unknown option %s',thisarg)
		end
	end
end

if smoothing ~= 0 && (ifversion('<','R2014a') || ~license('test','image_toolbox'))
	error('UWREDCOMP: smoothing option requires imguidedfilter() from IPT (R2014a or newer)');
end

if size(RGB,3)~=3
	error('UWREDCOMP: expected INPICT to be RGB')
end

[RGB inclass] = imcast(RGB,'double');

% b(lam_ref) is unneeded, since it cancels anyway
lam = [620 540 450]; % nanometers
blam = (-0.00113*lam + 1.62517);

% B_lam is top 0.1% of each channel
Blam = ctflop(quantile(RGB,1-0.001,[1 2]));

% attenuation coefficient ratios
cgcr = (blam(2)*Blam(1))/(blam(1)*Blam(2));
cbcr = (blam(3)*Blam(1))/(blam(1)*Blam(3));

% weights
wrgb = [1 cgcr cbcr]/(1 + cgcr + cbcr);

% construct new image
Rnew = imappmat(RGB,wrgb);
if smoothing > 0
	Rnew = imguidedfilter(Rnew,RGB(:,:,2),'degree',smoothing);
end
RGBnew = RGB;
RGBnew(:,:,1) = Rnew;

% adjust contrast/gamma
inlim = stretchlimFB(RGBnew,kclip);
RGBcont = imadjustFB(RGBnew,inlim,[0 1],gammaadj);
RGBahq = zeros(size(RGBnew));
for c = 1:3
	RGBahq(:,:,c) = adapthisteqFB(RGBnew(:,:,c),'distribution','rayleigh');
end

% lincomb of contrast/gamma adjustment & CLAHE adjustment
RGBnew = RGBcont*alpha + RGBahq*(1-alpha);
RGBnew = imcast(RGBnew,inclass);





