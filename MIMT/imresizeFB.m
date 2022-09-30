function outpict = imresizeFB(inpict,scale0,varargin)
%   OUTPICT=IMRESIZEFB(INPICT,SCALE,{METHOD},{OPTIONS})
%   Resize an image array.
%
%   This is a passthrough to the IPT function imresize(), with an internal 
%   fallback implementation to help remove the dependency of MIMT tools on the 
%   Image Processing Toolbox. As with other fallback tools, performance without 
%   IPT may be degraded or otherwise slightly different due to the methods used.
%
%   INPICT is an image array of any standard image class; 4D arrays are supported.
%      While imresize() supports indexed images, the fallback method does not.
%   SCALE specifies how the image should be resized
%      If scalar, this is treated as a scaling factor applied to both axes.
%      When specified as a 2-element vector, the units are presumed to be in pixels.
%      If one element is NaN, that size will be calculated to maintain aspect ratio.
%   METHOD specifies the type of interpolation (default 'bicubic')
%      Where imresize() supports many kernels and custom options, the fallback 
%      method only supports the three basic options:
%      'nearest' performs nearest-neighbor interpolation
%      'bilinear' performs bilinear interpolation
%      'bicubic' performs bicubic interpolation
%   OPTIONS includes any key-value pairs supported.  Whereas imresize() supports 
%      various parameters, the fallback method only supports 'antialiasing'.  
%      The 'antialiasing' key (followed by a logical value) controls the use of 
%      an antialiasing filter during downscaling operations. The default value is true.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imresizeFB.html
% See also: imresize, drysize

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	outpict = imresize(inpict,scale0,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

doaa = true;
methodstrings = {'nearest','bilinear','bicubic'};
method = 'bicubic';

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case methodstrings
				method = lower(varargin{k});
				k = k+1;
			case 'antialiasing'
				doaa = logical(varargin{k+1});
				k = k+2;
			otherwise
				error('IMRESIZEFB: unrecognized argument %s',varargin{k})
		end
	end
end

[inpict inclass] = imcast(inpict,'double');

% outsize is a 2-element vector in pixels
% scale is a 2-element scaling factor
% scale0 may be either format, but that's resolved by drysize()
s0 = imsize(inpict);
os0 = drysize(s0(1:2),scale0);
scale = os0./s0(1:2);

padsize = [4 4];
inpict = padarrayFB(inpict,padsize,'symmetric','both');
s = imsize(inpict);

downscaling = scale < 1;
if doaa
	% need to do aa filtering for downscaling cases
	% this probably isn't the best way to do this, but eeeeh.
	if all(downscaling)
		% use 2D gaussian
		sigma = 1/(min(scale)*pi);
		szf = roundodd(sigma*5*min(scale)./scale,'ceil');
		[xx yy] = meshgrid(1:szf(2),1:szf(1));
		r = sqrt(((xx-ceil(szf(2)/2))/(szf(2)/2)).^2 + ((yy-ceil(szf(1)/2))/(szf(1)/2)).^2);
		r(r > 1) = 1;
		fk = exp(-(r/(1.414*sigma)).^2);
		fk = fk/sum(sum(fk));
		inpict = imfilterFB(inpict,fk);
	elseif any(downscaling)
		% use 1D gaussian
		sigma = 1/(min(scale)*pi);
		szf = sum(roundodd(sigma*5*min(scale)./scale,'ceil').*downscaling);
		r = linspace(-1,1,szf);
		fk = exp(-(r/(1.414*sigma)).^2);
		if downscaling(1)
			fk = fk';
		end
		fk = fk/sum(sum(fk));
		inpict = imfilterFB(inpict,fk);
	end
end

% input coordinate space
% this offset eqn adjusts the output to mimic that of IPT imresize()
p = [0.343341 -0.518427 0.177996];
kos = p(1) + p(2)*(1./scale) + p(3)*(s0(1:2)./s(1:2));
x0 = linspace(1+kos(2),s(2)-kos(2),s(2));
y0 = linspace(1+kos(1),s(1)-kos(1),s(1));
[X0 Y0] = meshgrid(x0,y0);

% output coordinate space
x = linspace(1,s0(2),os0(2))+padsize(2);
y = linspace(1,s0(1),os0(1))+padsize(1);
[XX YY] = meshgrid(x,y);

% interpolate
outpict = imzeros([os0 s(3:4)]);
for f = 1:s(4)
	for c = 1:s(3)
		outpict(:,:,c,f) = interp2(X0,Y0,inpict(:,:,c,f),XX,YY,method);
	end
end
outpict = imcast(outpict,inclass);



