function outpict = imnoiseFB(inpict,mode,varargin)
%   OUTPICT=IMNOISEFB(INPICT,TYPE,{PARAMETERS})
%   Add noise to an image. 
%
%   This is a passthrough to the IPT function imnoise(), with internal fallback implementations to 
%   help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported.
%
%   TYPE specifies the type of noise to be added, the relevant PARAMETERS varying with TYPE
%     IMNOISEFB(INPICT,'gaussian',{MEAN},{VARIANCE})
%        Additive gaussian noise of specified MEAN (default 0) and VARIANCE (default 0.01)  
%     IMNOISEFB(INPICT,'localvar',{VARMAP})
%        Zero-mean additive gaussian noise with variance specified by variance map VARMAP.  VARMAP is 
%        a numeric array of the same height and width as INPICT.  Where possible, an underspecified 
%        VARMAP will be expanded, allowing terse vector or page assignment.
%     IMNOISEFB(INPICT,'localvar',{INTENSITY},{VARIANCE})
%        Zero-mean additive gaussian noise with variance specified by a variance map derived from the 
%        image itself.  The vectors INTENSITY and VARIANCE describe how the intensities of INPICT should 
%        be translated into a variance map. These vectors must have the same length.
%     IMNOISEFB(INPICT,'speckle',{VARIANCE})
%        Adds intensity-scaled zero-mean uniform noise of specified VARIANCE (default 0.05)
%     IMNOISEFB(INPICT,'salt & pepper',{DENSITY})
%        randomly slam pixels to range extrema according to a DENSITY parameter (default 0.05)
%     IMNOISEFB(INPICT,'poisson')
%        Adds poisson noise based on the input image class and pixel values.  For integer classes, noise 
%        generated for a given pixel is derived from a poisson distribution with a mean equal to the 
%        original pixel value.  For floating point classes, the distribution is upscaled by 1E6 for 'single' 
%        and 1E12 for 'double.    
%     IMNOISEFB(INPICT,'spatial',{VARIANCE})
%        Displaces pixels by a random vector.  Displacement magnitude is zero-mean gaussian noise with 
%        VARIANCE specified per axis (or as scalar with implicit expansion) (default [1 1]).  This is similar
%        to GIMP's 'spread' plugin, and more remotely, the old 'pick' plugin.  Entire pixels are displaced.
%     IMNOISEFB(INPICT,'spatialind',{VARIANCE})
%        Identical to 'spatial', but all pages of the array are displaced with unique displacement maps.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imnoiseFB.html
% See also: imnoise, rand, randn, perlin, perlin3

% localvar won't passthrough due to map expansion feature
noniptmodes = {'localvar','spatial','spatialind'};

% IF IPT IS INSTALLED
if hasipt() && ~strismember(mode,noniptmodes)
	outpict = imnoise(inpict,mode,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gaumean = 0;
gauvar = 0.01;
snpdensity = 0.05;
specklevar = 0.05;
spatialvar = [1 1];
modestrings = {'gaussian','saltpepper','snp','salt & pepper','speckle','poisson','localvar','spatial','spatialind'};
numlvp = 0;

mode = lower(mode);
if ~strismember(mode,modestrings)
	error('IMNOISEFB: unknown noise type %s',mode)
end

if strismember(mode,{'saltpepper','snp','salt & pepper'})
	mode = 'saltpepper';
end

if numel(varargin) > 0
	for k = 1:numel(varargin)
		switch k
			case 1
				switch mode
					case 'gaussian'
						gaumean = varargin{k};
					case 'localvar'
						lvparam1 = varargin{k};
						numlvp = 1;
					case 'saltpepper'
						snpdensity = varargin{k};
					case 'speckle'
						specklevar = varargin{k};
					case {'spatial','spatialind'}
						spatialvar = varargin{k};
					case 'poisson'
						error('IMNOISEFB: too many arguments for noisetype %s',mode)
				end
			case 2
				switch mode
					case 'gaussian'
						gauvar = varargin{k};
					case 'localvar'
						lvparam2 = varargin{k};
						numlvp = 2;
					case {'spatial','spatialind'}
						error('IMNOISEFB: too many arguments for noisetype %s',mode)
					case 'saltpepper'
						error('IMNOISEFB: too many arguments for noisetype %s',mode)
					case 'speckle'
						error('IMNOISEFB: too many arguments for noisetype %s',mode)
				end
			otherwise
				error('IMNOISEFB: too many arguments for noisetype %s',mode)
		end
	end
end

s0 = imsize(inpict);

if strcmp(mode,'localvar')
	if numlvp == 1
		if ~any(imsize(lvparam1,2) == s0(1:2))
			error('IMNOISEFB: variance map supplied for ''localvar'' mode must match either image height or width')
		end
		if size(lvparam1,1) == 1 && s0(1) > 1
			% expand dim 1
			lvparam1 = repmat(lvparam1,[s0(1) 1 1 1]);
		end
		if size(lvparam1,2) == 1 && s0(2) > 1
			% expand dim 2
			lvparam1 = repmat(lvparam1,[1 s0(2) 1 1]);
		end
		if size(lvparam1,3) == 1 && s0(3) > 1
			% expand dim 3
			lvparam1 = repmat(lvparam1,[1 1 s0(3) 1]);
		end
		if size(lvparam1,4) == 1 && s0(4) > 1
			% expand dim 4
			lvparam1 = repmat(lvparam1,[1 1 1 s0(4)]);
		end
	else
		if length(lvparam1) ~= length(lvparam2)
			error('IMNOISEFB: variance mapping vectors provided for the ''localvar'' mode must have the same length')
		end
	end
end

if strismember(mode,{'spatial','spatialind'})
	if numel(spatialvar) == 1
		spatialvar = [1 1]*spatialvar;
	end
end

	
[inpict inclass] = imcast(inpict,'double');
inpict = min(max(inpict,0),1);

switch mode
	case 'gaussian'
		outpict = inpict + gaumean + sqrt(gauvar)*randn(s0);
		
	case 'saltpepper'
		noisemap = rand(s0);
		outpict = inpict;
		mk1 = noisemap < (snpdensity/2);
		outpict(mk1) = 0;
		outpict(~mk1 & (noisemap < snpdensity)) = 1;
		
	case 'speckle'
		noisemap = rand(s0)-0.5;
		outpict = inpict + sqrt(12*specklevar)*noisemap.*inpict;
		
	case 'localvar'
		if numlvp == 1
			% use an explicit variance map
			noisemap = randn(s0);
			outpict = inpict + sqrt(lvparam1).*noisemap;
		else
			% use vectors to describe variance as a function of intensity
			[mn mx] = imrange(lvparam1);
			varmap = min(max(inpict,mn),mx);
			varmap = interp1(lvparam1,lvparam2,varmap); % would reshaping be that much faster?
			outpict = inpict + sqrt(varmap).*randn(s0);
		end
		
	case 'poisson'
		% denormalize input
		% i really don't know why these particular scalings were chosen for the FP classes, but this needs to mimic IPT during FB.
		switch inclass
			case 'uint8'
				inpict = round(inpict(:)*255);
			case 'uint16'
				inpict = round(inpict(:)*65535);
			case 'single'
				inpict = inpict(:)*1E6;
			case 'double'
				inpict = inpict(:)*1E12;
			otherwise
				% poisson mode doesn't accept signed int inputs
				error('IMNOISEFB: poisson noise mode only supports unsigned integer and floating-point inputs')
		end
		
		% this is pretty much exactly how imnoise does it.
		% for more info, see algimnoise.m
		outpict = zeros(s0);
		selection1 = find(inpict < 50);
		if ~isempty(selection1)
			npx = size(selection1);
			g = exp(-inpict(selection1));
			t = ones(npx);
			em = -t;
			selection2 = (1:npx)';
			while ~isempty(selection2)
				em(selection2) = em(selection2)+1;
				t(selection2) = t(selection2).*rand(size(selection2));
				selection2 = selection2(t(selection2) > g(selection2));
			end
			outpict(selection1) = em;
		end
		
		selection1 = find(inpict >= 50);
		if ~isempty(selection1)
			outpict(selection1) = round(inpict(selection1) + sqrt(inpict(selection1)).*randn(size(selection1)));
		end	
		outpict = reshape(outpict,s0);
				
		% renormalize output
		switch inclass
			case 'uint8'
				outpict = outpict/255;
			case 'uint16'
				outpict = outpict/65535;
			case 'single'
				outpict = outpict/1E6;
			case 'double'
				outpict = outpict/1E12;
		end
		
	case 'spatial'
		% actually doing 2D interpolation might be overkill for a novelty mode, but eeeh.
		padsize = ceil(10*spatialvar);
		inpict = padarrayFB(inpict,padsize,'symmetric','both');
		
		[x0 y0] = meshgrid((1-padsize(2)):(s0(2)+padsize(2)),(1-padsize(1)):(s0(1)+padsize(1)));
		[xx yy] = meshgrid(1:s0(2),1:s0(1));
		
		dispmag = randn(s0(1:2));
		dispang = 2*pi*rand(s0(1:2));
		dx = spatialvar(2)*dispmag.*cos(dispang);
		dy = spatialvar(1)*dispmag.*sin(dispang);
		xx = xx+dx;
		yy = yy+dy;
		
		outpict = zeros(s0);
		for f = 1:s0(4)
			for c = 1:s0(3)
				outpict(:,:,c,f) = interp2(x0,y0,inpict(:,:,c,f),xx,yy);
			end
		end
		
	case 'spatialind'
		padsize = ceil(10*spatialvar);
		inpict = padarrayFB(inpict,padsize,'symmetric','both');
		
		[x0 y0] = meshgrid((1-padsize(2)):(s0(2)+padsize(2)),(1-padsize(1)):(s0(1)+padsize(1)));
		[xx yy] = meshgrid(1:s0(2),1:s0(1));
		
		outpict = zeros(s0);
		for f = 1:s0(4)
			for c = 1:s0(3)
				dispmag = randn(s0(1:2));
				dispang = 2*pi*rand(s0(1:2));
				dx = spatialvar(2)*dispmag.*cos(dispang);
				dy = spatialvar(1)*dispmag.*sin(dispang);
				txx = xx+dx;
				tyy = yy+dy;
		
				outpict(:,:,c,f) = interp2(x0,y0,inpict(:,:,c,f),txx,tyy);
			end
		end
		
end

outpict = imcast(min(max(outpict,0),1),inclass);


















