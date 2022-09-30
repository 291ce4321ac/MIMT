function outpict = extractbg(inpictarg,varargin)
%   EXTRACTBG(INPICT, {OPTIONS})
%   EXTRACTBG(FILEPATH, {OPTIONS})
%       Extract background image estimate from a video or a multiframe image.
%       This tool uses simple luma or color distance thresholding, and was initially
%       based on the FEX submission 'Background Frame Extraction' by Alexander Farley.
%
%   INPICT is a 4D I/RGB image array of any standard image class
%       Alpha content will be ignored
%   FILEPATH is the path to a multiframe gif or a video file of any
%       format supported by VIDEOREADER.  Other multiframe image formats are
%       not directly supported (yet?).
%   OPTIONS are keys and key-value pairs:
%   'framestep' specifies the frame downsampling factor.  (default 1)
%        a value of N means that only every Nth frame will be processed
%   'comparisonmethod' specifies the method used to determine whether a pixel is similar to the 
%        current background estimate.  These options are ignored if the image has only one channel.
%        'luma' compares the luma only (default)
%        'distance' uses the euclidean distance between points in polar YPbPr
%   'tolerance' specifies how closely pixels should match the bg estimate (default [0.25 0.25 0.25])
%        The vector corresponds to the channels Y,C, and H. Luma comparisons only utilize the first
%        vector element, and can be used with scalar TOLERANCE.  If TOLERANCE is specified as a scalar 
%        for distance comparison, it will be expanded.
%   'iterations' specifies how many attempts should be made to refine the initial frame mean (default 5)
%   'tightening' is the factor by which TOLERANCE is multiplied each iteration (Range [0 1]; default 0.6)
%        Increasing TIGHTENING and ITERATIONS in tandem often helps clean up edges of dynamic areas.
%        In other words, don't try to converge too fast, or you might not converge to the intended color.
%   'fillmethod' specifies how to handle pixels for which there is no current bg estimate
%        These are more likely to occur if TOLERANCE or TIGHTENING are relatively small
%        especially if using an excessive number of ITERATIONS.
%        'inpaint' fills holes by estimating the pixel value from its neighbors (default)
%        'replaceinitial' fills holes with the initial bg estimate
%        'replacezero' fills holes with [0 0 0]
%   'allestimates' option will cause the output image to be a 4D array containing all bg estimates
%        Frame 1 of the output image is the initial dim 4 mean, and subsequent frames are refinements.
%        This is helpful in trying to optimize other parameters.
%   'initialestimate' allows the user to manually specify the initial background estimate.  
%        By default, the initial estimate is the image mean along dim 4.  The supplied image must match
%        the dimensions of the frames of INPICT.
%
%   Defaults are a compromise between accuracy and speed. If speed is no object, it is advisable to tailor
%   settings to produce better results.  These are examples of what worked for most of my test images.  
%   Your results will vary. Using 'allestimates' helps.
%
%     Test image convergence rate for TOL=0.25
%     Tightening  Iterations
%     0.5         3-4
%     0.6         5
%     0.8         9
%     0.9         13
%     0.95        18-20
%
%   Output class is the same as input class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/extractbg.html


% defaults
framestep = 1;				% frame downsampling factor
tightening = 0.6;				% threshold reduction factor applied each iteration
tol = [0.25 0.25 0.25];		% channel tolerance for color distance test
numiterations = 5;			% number of iterations to refine BG estimate
allestimates = false;
useextestimate = false;

fillmethodstrings = {'replacezero','replaceinitial','inpaint'};
fillmethod = 'inpaint';
comparisonmethodstrings = {'luma','distance'};
comparisonmethod = 'luma';

allbgest = [];
extestimate = [];

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
        case 'framestep'
            framestep = varargin{k+1};
			k = k+2;
		case 'allestimates'
			allestimates = true;
			k = k+1;
		case 'iterations'
            numiterations = varargin{k+1};
			k = k+2;
		case 'tolerance'
            tol = varargin{k+1};
			k = k+2;
		case 'tightening'
            tightening = varargin{k+1};
			k = k+2;
		case 'initialestimate'
			extestimate = imcast(varargin{k+1},'double');
			useextestimate = true;
			k = k+2;
		case 'fillmethod'
			thisarg = lower(varargin{k+1});
			if strismember(thisarg,fillmethodstrings)
				fillmethod = thisarg;
			else
				error('EXTRACTBG: unknown fill method %s\n',thisarg)
			end
			k = k+2;
		case 'comparisonmethod'
			thisarg = lower(varargin{k+1});
			if strismember(thisarg,comparisonmethodstrings)
				comparisonmethod = thisarg;
			else
				error('EXTRACTBG: unknown comparison method %s\n',thisarg)
			end
			k = k+2;
        otherwise
            error('EXTRACTBG: unknown input parameter name %s',varargin{k})
    end
end

% expand tol if manually underspecified
if strcmp(comparisonmethod,'distance') && numel(tol) ~= 3
	tol = [1 1 1]*tol(1);
end

if ischar(inpictarg)
	% inpict is a file path
	% treat inpictarg as a filename
	filename = inpictarg;
	fext = lower(filename((end-2):end));
	if strcmp(fext,'gif')
		% file is a gif (presumed to be multiframe)
		inpict = gifread(filename);
		[inpict inclass] = imcast(inpict,'double');
		bgest = processarray();
	else
		% assume the file is a video
		bgest = processincremental();
	end
else
	% inpict is an image array
	% treat inpictarg as an image
	[inpict inclass] = imcast(inpictarg,'double');
	bgest = processarray();
end

if allestimates
	outpict = imcast(allbgest,inclass);
else
	outpict = imcast(bgest,inclass);
end


function thisbg = processincremental()
	% shouldn't need to worry about dealing with alpha here if supported video formats don't have any
	vob = VideoReader(filename); % A warning about being unable to read the number of frames is due to variable frame rate (normal)
	blankframe = imcast(vob.read(inf)*0,'double'); % last frame to capture geometry and make sure numframes is calculated 
	numframes = vob.NumberOfFrames;
	
	[cc ca] = chancount(blankframe);
	if cc == 1
		comparisonmethod = 'direct';
	end
	
	% get initial estimate
	if useextestimate
		if any(size(extestimate) ~= size(blankframe))
			error('EXTRACTBG: User-supplied initial estimate must match image frame dimensions')
		end
		initestimate = extestimate;
	else
		initestimate = blankframe;	
		for k = 1:framestep:numframes
		    initestimate = initestimate + imcast(read(vob, k),'double');
		end
		initestimate = initestimate*framestep/numframes;
	end
		
	if allestimates
		allbgest = repmat(initestimate,[1 1 1 numiterations+1]);
	end
	
	thisbg = initestimate;
	% refine estimate
	for k = 1:numiterations;
		PSD = logical(blankframe(:,:,1));
		prevbg = thisbg;
		thisbg = blankframe;
		
		if strcmp(comparisonmethod,'distance')
			ychbg = rgb2lch(prevbg,'ypbpr');
			ychbg(:,:,3) = ychbg(:,:,3)/360;
		end
				
		for f = 1:framestep:numframes
			[thisframe inclass] = imcast(read(vob, f),'double');
			
			% find pixels which are similar to current bg estimate
			switch comparisonmethod
				case 'direct'
					masksimilar = abs(thisframe-prevbg)/tol(1) <= 1;
				case 'luma'
					masksimilar = mono(abs(thisframe-prevbg),'y')/tol(1) <= 1;
				case 'distance'
					ychframe = rgb2lch(prevbg,'ypbpr');
					ychframe(:,:,3) = ychframe(:,:,3)/360;
					masksimilar = sum(bsxfun(@times,(ychbg-ychframe),permute(1./tol,[1 3 2])).^2,3) <= 1;
			end
				
			PSD = PSD + masksimilar;												% accumulate pixel sample density
			nonmoving = bsxfun(@times,thisframe,masksimilar);						% mask frame to isolate static content
			thisbg = thisbg + nonmoving;											% accumulate sum of masked frames
		end
		
		% calculate average of masked frames; by using PSD instead of frame count, masked regions do not skew average
		thisbg = bsxfun(@rdivide,thisbg,PSD);
		thisbg = fillholes(thisbg,PSD,initestimate);
	
		if allestimates
			allbgest(:,:,:,k+1) = thisbg;
		end
		
		tol = tol*tightening;
	end
end


function thisbg = processarray()
	[cc ca] = chancount(inpict);
	if ca == 1; inpict = inpict(:,:,1:(end-1),:); end
	if framestep > 1; inpict = eoframe(inpict,framestep); end
	
	if cc == 1
		comparisonmethod = 'direct';
	end
		
	if strcmp(comparisonmethod,'distance')
		ychpict = fourdee(@rgb2lch,inpict,'ypbpr');
		ychpict(:,:,3,:) = ychpict(:,:,3,:)/360;
	end

	% get initial estimate
	if useextestimate
		if any(size(extestimate) ~= size(inpict(:,:,:,1)))
			error('EXTRACTBG: User-supplied initial estimate must match image frame dimensions')
		end
		initestimate = extestimate;
	else
		initestimate = mean(inpict,4);	
	end
	
	if allestimates
		allbgest = repmat(initestimate,[1 1 1 numiterations+1]);
	end
	
	thisbg = initestimate;
	% refine estimate
	for k = 1:numiterations;
		prevbg = thisbg;
		
		% find pixels which are similar to current bg estimate
		switch comparisonmethod
			case 'direct'
				masksimilar = abs(bsxfun(@minus,inpict,prevbg))/tol(1) <= 1;
			case 'luma'
				masksimilar = mono(abs(bsxfun(@minus,inpict,prevbg)),'y')/tol(1) <= 1;
			case 'distance'
				ychbg = rgb2lch(prevbg,'ypbpr');
				ychbg(:,:,3) = ychbg(:,:,3)/360;
				masksimilar = sum(bsxfun(@times,bsxfun(@minus,ychbg,ychpict),permute(1./tol,[1 3 2])).^2,3) <= 1;
		end
		
		
		PSD = sum(masksimilar,4);														% accumulate pixel sample density
		nonmoving = bsxfun(@times,inpict,masksimilar);									% mask frame to isolate static content
		thisbg = sum(nonmoving,4);														% accumulate sum of masked frames
				
		% calculate average of masked frames; by using PSD instead of frame count, masked regions do not skew average
		thisbg = bsxfun(@rdivide,thisbg,PSD);
		thisbg = fillholes(thisbg,PSD,initestimate);
	
		if allestimates
			allbgest(:,:,:,k+1) = thisbg;
		end
		
		tol = tol*tightening;
	end
end


function filledbg = fillholes(holybg,PSD,avgpict)
	switch lower(fillmethod)
		case 'replacezero'
			filledbg = replacepixels([0 0 0],holybg,PSD == 0);
		case 'replaceinitial'
			filledbg = replacepixels(initestimate,holybg,PSD == 0);
		case 'inpaint'
			filledbg = thresholdinpaint(holybg,'rgb',PSD == 0);
		otherwise
			error('EXTRACTBG: unknown fill method %s',fillmethod)
	end
end

end




