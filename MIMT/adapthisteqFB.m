function outpict = adapthisteqFB(inpict,varargin)
%   OUTPICT=ADAPTHISTEQFB(INPICT,{OPTIONS})
%   Adjust the contrast of an image using a contrast-limited adaptive histogram equalization (CLAHE) 
%   technique, such that it has a specified intensity distribution.  Instead of adjusting the entire 
%   image based on global properties (like histeq would), perform the operation by subdividing the 
%   image into tiles and then interpolating between those local properties to transform the image.
%
%   This is a passthrough to the IPT function adapthisteq(), with an internal fallback implementation 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is a single-channel image of any standard image class. 
%   OPTIONS includes the key-value pairs:
%     'numtiles' specifies the tiling that should be used (default [8 8]; minimum 2)
%         The more tiles are used, the better the function can respond to local properties.
%     'cliplimit' scales the contrast limiting behavior (default 0.01)
%         This is a scalar between [0 1].  Maximal contrast occurs at cliplimit=1.
%     'nbins' specifies the number of histogram bins (default 256)
%     'range' selects how the output image data should be scaled (default 'full')
%         'full' specifies that the output data should be scaled WRT the range implied by the output class.
%         'original' specifies that the output data should be scaled WRT the input image extrema.
%     'distribution' specifies the target output intensity distribution (default 'uniform')
%         Accepts 'uniform', 'rayleigh', or 'exponential'
%     'alpha' specifies the distribution parameter (default 0.4)
%         This is only useful when the selected distribution is either 'rayleigh' or 'exponential'.
%
%   See adapthisteq() documentation for more details.
%
%  Output image class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/clahe.html
% See also: adapthisteq, histeq, histeqFB, imlnc


% IF IPT IS INSTALLED
if hasipt()
	outpict = adapthisteq(inpict,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% this is all strongly based on adapthisteq(); forgive the similarity.  there were a few things i'd have liked 
% to have done my own way but i'm limited by the desire to make the behavior replicate the IPT implementation 
% because of how this function is intended to be used both with and without IPT.  i honestly thought someone 
% would've had a CLAHE implementation on the FEX already, but the ones i found were either clumsy wrappers for 
% adapthisteq() or they were undocumented buggy garbage.  hey, at least i document my buggy garbage. :D

% for default settings on a 900x650 DPFP test image, this takes about twice as long as adapthisteq() does, 
% with an RMS pixel difference of ~8E-17.  i caused some slight class-dependent differences due to when i normalized 
% and how i did the interpolation, but this is way more than close enough.  the peak memory usage is probably higher
% than adapthisteq(), since i normalize early and explicitly allocate the tile components during interpolation.

% defaults
rangestrings = {'full','original'};
range = 'full';
diststrings = {'uniform','rayleigh','exponential'};
dist = 'uniform';
numtiles = [8 8];
numbins = 256;
clim_norm = 0.01;
alpha = 0.4;

if numel(varargin) > 1
	k = 1;
	while k <= numel(varargin)
		thisarg = lower(varargin{k});
		switch thisarg
			case 'alpha'
				alpha = varargin{k+1};
				k = k+2;
			case {'numbins','nbins'}
				numbins = max(varargin{k+1},2);
				k = k+2;
			case 'cliplimit'
				clim_norm = min(max(varargin{k+1},0),1);
				k = k+2;
			case 'numtiles'
				if numel(varargin{k+1}) == 2
					numtiles = max(varargin{k+1},2);
				else
					error('ADAPTHISTEQFB: NUMTILES should be a 2-element vector [NTILESDOWN NTILESACROSS]')
				end
				k = k+2;
			case 'range'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,rangestrings)
					range = thisarg;
				else
					error('ADAPTHISTEQFB: unknown option for RANGE %s\n',thisarg)
				end
				k = k+2;
			case 'distribution'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,diststrings)
					dist = thisarg;
				else
					error('ADAPTHISTEQFB: unknown option for DISTRIBUTION %s\n',thisarg)
				end
				k = k+2;
		end
	end
end

s0 = imsize(inpict);
if s0(3) ~= 1
	error('ADAPTHISTEQFB: expected INPICT to be a single-channel intensity image. If IA/RGB/RGBA functionality is needed, use a loop.')
end
if s0(4) ~= 1
	error('ADAPTHISTEQFB: expected INPICT to be a single-frame intensity image. If multiframe functionality is needed, use a loop.')
end
s0 = s0(1:2);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prepare inputs

% it's expensive, but trying to deal with the interpolator (which has issues with int classes)
% and signed int classes (which will probably screw up the TF calcs)
% is going to be a pain unless we just normalize now instead of waiting to normalize inside the interpolation loop
[inpict inclass] = imcast(inpict,'double');

switch range
	case 'full'
		range = [0 1];
	case 'original'
		range = imrange(inpict);
end

% pad the image to make it integer-tileable with tiles of even size
% i'm just going to assume that the image isn't perfectly tileable to begin with
tilesize = roundeven(s0./numtiles,'ceil');
padsize = tilesize.*numtiles-s0;
padsize = [floor(padsize(1)/2) ceil(padsize(1)/2) floor(padsize(2)/2) ceil(padsize(2)/2)];
inpict = padarrayFB(inpict,padsize([1 3]),'symmetric','pre');
inpict = padarrayFB(inpict,padsize([2 4]),'symmetric','post');
s = imsize(inpict,2);

% this is how adadpthisteq() denormalizes the cliplimit
% clim_norm=1 results in AHE without contrast limiting (highest output contrast)
% clim_norm=clim_min results in maximal contrast limiting (lowest output contrast)
tilepxcount = prod(tilesize);
clim_min = ceil(tilepxcount/numbins);
clim = clim_min+round(clim_norm*(tilepxcount-clim_min));


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate regional input-output TFs

allTFs = cell(numtiles); 
for m = 1:numtiles(1)
	for n = 1:numtiles(2)
		% extract the ROI
		yrange = ((m-1)*tilesize(1)+1):(m*tilesize(1));
		xrange = ((n-1)*tilesize(2)+1):(n*tilesize(2));
		thistile = inpict(yrange,xrange);
		
		% calculate this tile's histogram
		hist = imhistFB(thistile,numbins);
		
		% clip & redistribute the histogram according to clim 
		cliphgram();
		
		% generate this regional TF according to specified distribution
		% shove it in a cell array
		allTFs{m,n} = buildTF();
		
	end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do inter-region input-output interpolation

outpict = zeros(s,'double');

% generate TF0 mapping from input data range [0 1] to histogram bin range [0 numbins-1]
% this is massively simplified since we already normalized the image and ensured numbins>1
TF0 = linspace(0,1,numbins);

% loop through all the tiles
% keep in mind that we're offsetting by 1/2 a tile so that the previously calculated 
% TFs are of peak relevance at the (current) tile edges (as opposed to the centers)
% this makes interpolating between TFs more sensible
thistilesize = [0 0];
nwcorner = [1 1];
for km = 1:(numtiles(1)+1)
	if km == 1 || km == (numtiles(1)+1)
		% first & last row are half-width
		thistilesize(1) = tilesize(1)/2;
	else % all other rows are full-width
		thistilesize(1) = tilesize(1);
	end
	TFyrange = min(max([km-1 km],1),numtiles(1));
	
	nwcorner(2) = 1;
	for kn = 1:(numtiles(2)+1)
		if kn == 1 || kn == (numtiles(1)+1)
			% first & last col are half-width
			thistilesize(2) = tilesize(2)/2;
		else % all other cols are full-width
			thistilesize(2) = tilesize(2);
		end
		TFxrange = min(max([kn-1 kn],1),numtiles(2));
		
		% fetch neighbor TFs
		TFnw = allTFs{TFyrange(1),TFxrange(1)};
		TFne = allTFs{TFyrange(1),TFxrange(2)};
		TFsw = allTFs{TFyrange(2),TFxrange(1)};
		TFse = allTFs{TFyrange(2),TFxrange(2)};
		
		% get subs for addressing the tile
		tileyrange = nwcorner(1)+(1:thistilesize(1))-1;
		tilexrange = nwcorner(2)+(1:thistilesize(2))-1;
				
		% apply TF0 in place of grayxformmex() interpolator
		% the comments in adapthisteq() makes it sound like this is linear interpolation; these parts aren't.
		thistile = min(max(inpict(tileyrange,tilexrange),0),1);
		thistile = interp1(linspace(0,1,numel(TF0)),TF0,thistile,'nearest');
		
		% similarly, calculate contributing components by interpolating using neighbor TFs
		outnw = interp1(linspace(0,1,numel(TFnw)),TFnw,thistile,'nearest');
		outne = interp1(linspace(0,1,numel(TFne)),TFne,thistile,'nearest');
		outsw = interp1(linspace(0,1,numel(TFsw)),TFsw,thistile,'nearest');
		outse = interp1(linspace(0,1,numel(TFse)),TFse,thistile,'nearest');
		
		% calculate weighting arrays to perform the bilinear interpolation between output components
		RW = repmat((0:thistilesize(1)-1)',[1 thistilesize(2)]);
		CW = repmat(0:thistilesize(2)-1,[thistilesize(1) 1]);
		RRW = repmat((thistilesize(1):-1:1)',[1 thistilesize(2)]);
		CRW = repmat(thistilesize(2):-1:1,[thistilesize(1) 1]);
		Wnw = RRW.*CRW;
		Wne = RRW.*CW;
		Wsw = RW.*CRW;
		Wse = RW.*CW;

		% output tile is the weighted mean of components
		outpict(tileyrange,tilexrange) = (Wnw.*outnw + Wne.*outne + Wsw.*outsw + Wse.*outse)/prod(thistilesize);
		
		% shift nw corner;  it's easier to do this cumulatively, since tile sizes vary
		nwcorner(2) = nwcorner(2)+thistilesize(2);
	end
	nwcorner(1) = nwcorner(1)+thistilesize(1);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up the output and we're done

outpict = cropborder(outpict,padsize);
outpict = imcast(outpict,inclass);







% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cliphgram()
	excesspxcount = sum(max(hist-clim,0)); % find #px beyond clip limit
	bindelta = floor(excesspxcount/numbins); % average delta for uniform redistribution
	binceil = clim-bindelta; % there needs to be a margin to allow for the delta
	
	% this is how adapthisteq() does the redistribution of pixel counts beyond clim
	% first, we shove as many bindelta sized chunks of the excesspxcount as we can into the bins
	% but of course, we didn't take into account how many bins were clipped when we calculated bindelta
	% we can't add to those, so we'll still have excesspxcount left over after this first pass
	for p = 1:numbins
		if hist(p) > clim
			hist(p) = clim;
		elseif hist(p) > binceil
			excesspxcount = excesspxcount-clim+hist(p);
			hist(p) = clim;
		else
			excesspxcount = excesspxcount-bindelta;
			hist(p) = hist(p)+bindelta;
		end
	end
	
	% so in order to get rid of the rest, we do this convoluted mess
	% i don't know why bindelta can't just be calculated correctly in the first place
	% e.g. simply precalculate all bin deltas presuming clim and some fixed margin equal to the presumed average delta
	% but i want to replicate the exact behavior of adapthisteq() for sake of consistency regardless of IPT availability
	% and this variable stepping scheme would be hard to replicate that way.
	p = 1;
	while excesspxcount > 0
		step = max(floor(numbins/excesspxcount),1);
		for q = p:step:numbins
			if hist(q) < clim
				% add a px to this bin if there's room
				hist(q) = hist(q)+1; 
				excesspxcount = excesspxcount-1;
				if excesspxcount == 0
					break;
				end
			end
		end
		
		p = p+1; % increment
		p = mod(p-1,numbins)+1; % wrap around
	end
	
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function TF = buildTF()
	histcsum = cumsum(hist);
	spread = abs(diff(range));
	
	switch dist
		case 'uniform'
			TF = min(range(1)+histcsum*spread/tilepxcount,range(2));
			
		case 'rayleigh'
			% see adapthisteq() for more info
			h = 2*alpha^2;
			v = (1-exp(-1/h))*histcsum/tilepxcount;
			v(v >= 1) = 1-eps;
			TF = min(range(1)+sqrt(-h*log(1-v))*spread,range(2));
			
		case 'exponential'
			% see adapthisteq() for more info
			v = (1-exp(-alpha))*histcsum/tilepxcount;
			v(v >= 1) = 1-eps;
			TF = min(range(1)+(-1/alpha*log(1-v))*spread,range(2));
			
	end
	
	TF = TF/range(2); % normalize for use with interpolator
	
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end



