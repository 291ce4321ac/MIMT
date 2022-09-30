function fk = fkgen(kstyle,varargin)
%  FKERN=FKGEN(TYPE,{SIZE},{OPTIONS})
%    Generate a filter kernel.  This is similar to FSPECIAL with additional 
%    options and support for atypical filter types of questionable utility.  
%
%  TYPE is one of the following:
%   -Blur filters:
%     'gaussian1' is a simple 1-D gaussian filter with relative sigma
%     'gaussian' is a simple 2-D gaussian filter with relative sigma
%          To emulate GIMP behavior, double the filter size
%     'techgauss1' is a flexible 1-D gaussian filter
%     'techgauss2' is a flexible 2-D gaussian filter
%          These gaussians support independent size and sigma per axis
%     'disk' is a flat elliptical filter with smooth edges
%     'rect' is a flat rectangular filter with hard edges
%     'motion' is a flat 1-D filter with 1px of easing at the ends
%     'glow1' is a 1-D sum of gaussians used to create a soft glow effect
%     'glow2' is a 2-D variant of glow1
%     'glowcross' is two smoothly intersecting instances of glow1
%     'glowstar' is like glowcross, but with intersection emphasis
%     'ring' is a flat ring filter with smooth edges
%     'bars' consists of two horizontal flat bars with eased ends
%     'cross' is a flat cross filter with eased points
%     '3dot' is a filter using three flat square dots in a triangular pattern
%     '4dot' is a filter using four flat square dots in a rectangular pattern
%
%   -Edge-emphasis filters:
%     'prewitt' is a Prewitt edge-emphasis filter
%     'sobel' is a Sobel edge-emphasis filter
%     'scharr' is a simple normalized Scharr edge-emphasis filter
%     'kayyali' is a Kayyali edge-emphasis filter
%     'roberts' is a Roberts edge-emphasis filter
%     These filters are scaled such that the output of a single filter pass 
%     (i.e. the directional derivative) is an image in the range [-1 1].
%     This saves the cost of normalizing the entire output and ensures consistency.
%
%   -Prenormalized edge filters:
%     'prewitt2' is a prenormalized Prewitt edge-emphasis filter
%     'sobel2' is a prenormalized Sobel edge-emphasis filter
%     'scharr2' is a prenormalized Scharr edge-emphasis filter
%     'kayyali2' is a prenormalized Kayyali edge-emphasis filter
%     'roberts2' is a prenormalized Roberts edge-emphasis filter
%     These filters are scaled such that the Euclidean norm of two orthogonal filter 
%     passes (i.e. the gradient magnitude) is a normalized image in the range [0 1].
%     This saves the cost of normalizing the entire output and ensures consistency.
%
%   -Other filters:
%     'laplacian' is a simple 3x3 laplacian, replicating the style used by fspecial()
%           This filter supports a single shape parameter ALPHA in the range [0 1]
%     'lapgauss' is a laplacian of gaussian filter
%           This filter supports independent size and sigma per axis
% 
%  SIZE specifies the nominal size of blur kernel
%    May be a 2-element vector [height width] for filters other than '3dot' and 
%    any 1-D filter.  Note that this geometry only describes the filter prior 
%    to any applied rotation.  This parameter does not affect edge filters.
%    
%  OPTIONS are key-value pairs including:
%    'angle' specifies the rotation angle for non-round filters (default 0)
%    'thick' specifies the thickness of linear filter elements (default 0.2)
%       This applies to 'ring','cross','bars', and '-dot' filters
%    'alpha' controls the shape for the 'laplacian' filter (default 1/3)
%    'sigma' controls the shape for 'techgauss' & 'lapgauss' filters (default [0.5 0.5])
%       If specified as a scalar, this parameter will be expanded as needed.
%    'interpolation' specifies the interpolation type used when rotating 
%       'nearest','bilinear' (default), and 'bicubic'  
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/fkgen.html
% See also: imfilterFB, fspecial, pseudoblurmap, edgemap


interpmethodstrings = {'nearest','bilinear','bicubic'};
interpmethod = 'bilinear';
blurangle = 0;
width = 0.2;
sigma = [0.5 0.5];
alpha = 1/3;

% used for 'glow' filters
% [peak background]
wght = [1.0 0.3];
sgma = [0.1 0.5];


if ~exist('kstyle','var')
	error('FKGEN: filter style not specified')
else
	kstyle = lower(kstyle);
end

norescalemode = strismember(kstyle,{'prewitt','sobel','scharr','kayyali','roberts','prewitt2','sobel2','scharr2','kayyali2','roberts2','lapgauss','laplacian'});
nosizemode = strismember(kstyle,{'prewitt','sobel','scharr','kayyali','roberts','prewitt2','sobel2','scharr2','kayyali2','roberts2','laplacian'});
	
if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		if k == 1 && isnumeric(varargin{k})
			blursize = varargin{k};
			k = k+1;
		else
			switch lower(varargin{k})
				case 'angle'
					if isnumeric(varargin{k+1})
						blurangle = varargin{k+1};
					else
						error('FKGEN: expected numeric value for BLURANGLE')
					end
					k = k+2;
				case 'alpha'
					if isnumeric(varargin{k+1})
						alpha = varargin{k+1};
					else
						error('FKGEN: expected numeric value for ALPHA')
					end
					k = k+2;
				case 'sigma'
					if isnumeric(varargin{k+1})
						sigma = varargin{k+1};
					else
						error('FKGEN: expected numeric value for SIGMA')
					end
					k = k+2;
				case 'thick'
					if isnumeric(varargin{k+1})
						width = varargin{k+1};
					else
						error('FKGEN: expected numeric value for WIDTH')
					end
					k = k+2;
				case 'interpolation'
					thisarg = lower(varargin{k+1});
					if strismember(thisarg,interpmethodstrings)
						interpmethod = thisarg;
					else
						error('FKGEN: unknown interpolation method %s\n',thisarg)
					end
					k = k+2;
				otherwise
					error('FKGEN: unknown input parameter name %s',varargin{k})
			end
		end
	end
end

if isscalar(sigma)
	sigma = [1 1]*sigma;
end

if ~nosizemode
	if ~exist('blursize','var')
		error('FKGEN: filter size not specified')
	else
		if ~isnumeric(blursize)
			error('FKGEN: expected numeric value for blursize')
		end
	end
	
	width = min(max(0,width),0.5); % this is not an effective safeguard
	blursize = max(round(blursize),1);

	% expand bs param as needed
	if numel(blursize) == 1
		thisbs = [1 1]*blursize;
	else
		thisbs = blursize;
	end
end


switch kstyle	
	case 'gaussian'
		% fspecial doesn't really support asymmetric gaussian filters
		% it just makes a cropped symmetric filter, which defeats the point of using a gaussian imo
		sigma = 0.3;
		szf = roundodd(thisbs,'ceil'); 
		x = linspace(-1,1,szf(2));
		y = linspace(-1,1,szf(1));
		[xx yy] = meshgrid(x,y);
		r = sqrt(xx.^2 + yy.^2);
		r(r > 1) = 1;
		fk = exp(-(r/(1.414*sigma)).^2); %fk = fk-min(fk(:));
		
	case 'gaussian1'
		sigma = 0.3;
		szf = roundodd(thisbs(1),'ceil');  
		x = linspace(-1,1,szf);
		fk = exp(-(x/(1.414*sigma)).^2);
		
	case 'techgauss2'
		R = floor(roundodd(thisbs,'ceil')/2);
		[xx yy] = meshgrid(-R(2):R(2),-R(1):R(1));
		fk = exp(-(xx.^2/(2*sigma(2)^2) + yy.^2/(2*sigma(1)^2)));
		
	case 'techgauss1'
		R = floor(roundodd(thisbs,'ceil')/2);
		x = -R(2):R(2);
		fk = exp(-(x/(1.414*sigma(1))).^2);
		
	case 'rect'
		fk = ones(thisbs);
		
	case 'disk'
		% fspecial doesn't support elliptical 'disk' filters
		szf = roundodd(thisbs,'ceil');  
		[xx yy] = meshgrid(1:szf(2),1:szf(1));
		fk = ((xx-ceil(szf(2)/2))/(szf(2)/2)).^2 + ((yy-ceil(szf(1)/2))/(szf(1)/2)).^2;
		fk(fk > 1) = 1;
		fk = min(1-sqrt(fk),2/mean(thisbs));
		
	case 'ring'
		szf = roundodd(thisbs,'ceil');  
		[xx yy] = meshgrid(1:szf(2),1:szf(1));
		fk = ((xx-ceil(szf(2)/2))/(szf(2)/2)).^2 + ((yy-ceil(szf(1)/2))/(szf(1)/2)).^2;
		fk = -(abs(1-sqrt(fk)-width)-width);
		fk(fk < 0) = 0;
		fk = min(fk,2/mean(thisbs));
		
	case 'motion'
		szf = roundodd(thisbs,'ceil'); 
		fk = ones([1 szf(1)]); fk(:,[1,end]) = 0.5;
				
	case 'glow1'
		szf = roundodd(thisbs(1),'ceil');  
		x = linspace(-1,1,szf);
		fk1 = wght(1)*exp(-(x/(1.414*sgma(1))).^2);
		fk2 = wght(2)*exp(-(x/(1.414*sgma(2))).^2);
		fk = fk1+fk2; fk = fk-min(fk(:));
		
	case 'glow2'
		szf = roundodd(thisbs,'ceil');  
		x = linspace(-1,1,szf(2));
		y = linspace(-1,1,szf(1));
		[xx yy] = meshgrid(x,y);
		r = sqrt(xx.^2 + yy.^2);
		r = r/max(r(:));
		r(r > 1) = 1;
		fk1 = wght(1)*exp(-(r/(1.414*sgma(1))).^2);
		fk2 = wght(2)*exp(-(r/(1.414*sgma(2))).^2);
		fk = fk1+fk2; fk = fk-min(fk(:));
		
	case 'glowcross'
		szf = roundodd(thisbs,'ceil');  
		x = linspace(-1,1,szf(2));
		y = linspace(-1,1,szf(1)).';
		fk1 = wght(1)*exp(-(x/(1.414*sgma(1))).^2);
		fk2 = wght(2)*exp(-(x/(1.414*sgma(2))).^2);
		fk3 = wght(1)*exp(-(y/(1.414*sgma(1))).^2);
		fk4 = wght(2)*exp(-(y/(1.414*sgma(2))).^2);
		fk = zeros(szf);
		% these can simply intersect with continuity
		% the same weights are used, so the peaks are the same height
		fk(ceil(szf(1)/2),:) = fk1 + fk2;
		fk(:,ceil(szf(2)/2)) = fk3 + fk4;
		fk = fk-min(fk(:));
		
	case 'glowstar'
		szf = roundodd(thisbs,'ceil');  
		x = linspace(-1,1,szf(2));
		y = linspace(-1,1,szf(1)).';
		fk1 = wght(1)*exp(-(x/(1.414*sgma(1))).^2);
		fk2 = wght(2)*exp(-(x/(1.414*sgma(2))).^2);
		fk3 = wght(1)*exp(-(y/(1.414*sgma(1))).^2);
		fk4 = wght(2)*exp(-(y/(1.414*sgma(2))).^2);
		fk = zeros(szf);
		% use weighted sum at intersection to emphasize center pixel and suppress tails
		fk(ceil(szf(1)/2),:) = fk1 + fk2;
		fk(:,ceil(szf(2)/2)) = 0.5*fk(:,ceil(szf(2)/2)) + fk3 + fk4;
		fk = fk-min(fk(:));
				
	case '3dot'
		thisbs = thisbs(1);
		w = max(1,round(mean(thisbs)*width));
		fk = zeros(round(thisbs*[0.866 1]));
		fk(end-w+1:end,[1:w end-w+1:end]) = 1; 
		os = round((size(fk,2)-w)/2); 
		fk(1:w,os+1:os+w) = 1;

	case '4dot'
		w = max(1,round(mean(thisbs)*width));
		fk = zeros(round(thisbs));
		fk([1:w end-w+1:end],[1:w end-w+1:end]) = 1;

	case 'bars'
		w = max(1,round(mean(thisbs)*width));
		fkb = ones([w thisbs(2)]); fkb(:,[1,end]) = 0.5;
		fk = zeros(thisbs);
		fk(1:w,:) = fkb;
		fk(end-w+1:end,:) = fkb;
	
	case 'cross'
		w = max(1,round(mean(thisbs)*width));
		fk = zeros(thisbs);
		os = round((size(fk,1)-w)/2);
		fkb = ones([w thisbs(2)]); fkb(:,[1,end]) = 0.5;
		fk(os+1:os+w,:) = fkb;
		os = round((size(fk,2)-w)/2);
		fkb = ones([thisbs(1) w]); fkb([1,end],:) = 0.5;
		fk(:,os+1:os+w) = fkb;
		
	% given that this is neither 1970, nor are we otherwise stuck doing integer-only math
	% i don't see why these shouldn't just be normalized to meet a common output range.
	% if you are relying on the over-ranging for implicit thresholding, just do it explicitly.
	case 'prewitt'
		fk = [1 1 1; 0 0 0; -1 -1 -1]/3;
		
	case 'sobel'
		fk = [1 2 1; 0 0 0; -1 -2 -1]/4;
		
	case 'scharr'
		fk = [47 162 47; 0 0 0; -47 -162 -47]/256;
				
	case 'kayyali'
		fk = [6 0 -6; 0 0 0; -6 0 6]/6;
		
	case 'roberts'
		fk = [1 0; 0 -1];
		
		
	% for a filter of the form fk=[a b a; 0 0 0; -a -b -a]
	% the normalizing factor is 1/sqrt(k), where k=4*a^2 + 4*a*b + 2*b^2
	
	% for a filter of the form fk=[a 0 -a; 0 0 0; -a 0 a]
	% k is half that given above (i.e. k=2*a^2)
	case 'prewitt2'
		nf = sqrt(10);
		fk = [1 1 1; 0 0 0; -1 -1 -1]/nf;
		
	case 'sobel2'
		nf = sqrt(20);
		fk = [1 2 1; 0 0 0; -1 -2 -1]/nf;
		
	case 'scharr2'
		nf = sqrt(91780);
		fk = [47 162 47; 0 0 0; -47 -162 -47]/nf;
				
	case 'kayyali2'
		nf = sqrt(72);
		fk = [6 0 -6; 0 0 0; -6 0 6]/nf;
		
	case 'roberts2'
		nf = sqrt(2);
		fk = [1 0; 0 -1]/nf;
		
	case 'laplacian'
		alpha = min(max(alpha,0),1);
		a = alpha;
		b = (1-alpha);
		c = -4;
		fk = [a b a; b c b; a b a]/(alpha+1);
		
	case 'lapgauss'
		R = floor(roundodd(thisbs,'ceil')/2);
		[xx yy] = meshgrid(-R(2):R(2),-R(1):R(1));
		fkg = exp(-(xx.^2/(2*sigma(2)^2) + yy.^2/(2*sigma(1)^2)));
		fk = (xx.^2 + yy.^2 - (sigma(2)^2 + sigma(1)^2))/(sigma(1)^2 * sigma(2)^2);
		fk = fk.*fkg/sum(fkg(:));
		fk = fk-sum(fk(:))/numel(fk);
				
	otherwise
		error('FKGEN: unknown kernel style %s\n',kstyle)
end

if ~(strismember(kstyle,{'gaussian','disk','ring','glow2','techgauss2','lapgauss'}) && thisbs(1) == thisbs(2))
	fk = imrotateFB(fk,blurangle,interpmethod);
end

if ~norescalemode
	if max(fk(:)) == 0
		fk = 1;
	else
		fk = fk/sum(fk(:));
	end
end
	

