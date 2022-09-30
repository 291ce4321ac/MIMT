function varargout = imstats(instack,varargin)
%   OUTARRAY=IMSTATS(INPICT,METRICS,{OPTIONS})
%   [OV1 OV2 ...]=IMSTATS(INPICT,METRICS,{OPTIONS})
%      Returns information about image colors.  This is mostly a convenience
%      tool to avoid dealing with reshaping arrays, avoiding NaNs, etc.  
%      
%   INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%      If INPICT is 4D, the calculations span the union of all frames.
%      If per-frame metrics are required, use FOURDEE();
%   METRICS specifies the information to be calculated:
%      'mean' returns the arithmetic means per channel
%      'median' returns the median (middle) values per channel
%      'mode' returns the mode (most common values) per channel
%      'std' returns the standard deviation per channel
%      'min' returns the channel minima
%      'max' returns the channel maxima
%      'modecolor' calculates the most common color.  This differs from 'mode' as 
%        the most frequent values in individual channels are not necessarily colocated. 
%        Consider an image which is 40% [1 0 0], 30% [1 1 1] and 30% [0 1 1].  
%        For this example, 'mode' returns [1 1 1], whereas 'modecolor' returns [1 0 0].  
%        The latter would be the intuitive answer.
%      'moderange' calculates a selected range of the most common colors in the image.  
%        Contrast this with 'modecolor' which calculates the singular most common color.
%        The range of colors and number of output tuples is specified by parameter 'nmost'.  
%        This mode supports only I/RGB images.
%      'modefuzzy' calculates the frequency-weighted mean of a selected range of the
%        most common colors in the image.  The range of colors is specified by parameter 
%        'nmost'.  This mode supports only I/RGB images.
%      The 'modecolor', 'modefuzzy', and 'moderange' options all do color quantization, 
%      and can therefore alter the color population to some degree.  Be wary of using 
%      the output of these modes for anything of technical importance.
%
%      'whitefrac' fraction of each channel which is maximized
%      'blackfrac' fraction of each channel which is minimized
%      'satfrac' fraction of each channel which is either maximized or minimized
%      'nanfrac' fraction of each channel which is NaN
%      'oogfrac' fraction of each channel which is out of gamut
%      'nancount' returns a count of NaN elements per channel
%      'oogcount' returns a count of OoG elements per channel
%      These latter four cases only produce meaningful information if INPICT
%      is a floating-point datatype. 
% 
%      'localcontrast' subdivides the image into tiles of a nominal size and then
%      calculates the average of local values for (max-min)/mean. For small tile 
%      sizes, this fixed-tiling method approximates a sliding-window method to 
%      within 0.5% for typical images, with the benefit of being much faster.
% 
%      'edginess' returns the average gradient magnitude estimated by processing the
%      image with a normalized Scharr edge-emphasizing filter
% 
%   OPTIONS include the keys and key-value pairs:
%      'nmost' specifies the colors selected by 'modefuzzy' and 'moderange'.  For 
%          example, the vector [2 8] selects the second through eigth most common colors.  
%          If specified as a scalar X, the range is expanded to [1 X]. (default [1 5])
%      'tilesize' sets the tile size used for the 'localcontrast' setting
%          may be a scalar or a 2-element vector (default 10)
%      'tolerance' sets the tolerance used for judging how closely values must match
%          0 or 1 for the extremity calculating modes (default 1E-6)
%      'normalized' inhibits the default rescaling of certain metrics to correspond
%          to the white value of INPICT when INPICT is an integer class.
%
%   Output is a series of row vectors, each of length equal to the number of 
%   channels in INPICT. Output class is of type 'double', though for metrics in the
%   first group (e.g. 'mean'), the output is scaled to match the data in INPICT.  
%   This is to prevent rounding and truncation for integer inputs.  For all cases 
%   except 'nancount', NaN values are ignored and do not contribute to the result. 
%
%   Examples:
%     Calculate several metrics and assign them to a single array:
%       thesestats=imstats(inpict,'min','mean','max');
%     Calculate several metrics and assign them to separate variables:
%       [mn av mx]=imstats(inpict,'min','mean','max');
%     Get per-frame info for a multiframe image using fourdee
%       [mn av mx]=fourdee(@imstats,instack,'min','mean','max')
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imstats.html
% See also: imrange

metricstrings = {'mean','median','mode','modecolor','modefuzzy','moderange','min','max','std','localcontrast','edginess','nancount','nanfrac','oogcount','oogfrac','whitefrac','blackfrac','satfrac'};
rescaledmetrics = {'mean','median','mode','modecolor','modefuzzy','moderange','min','max','std'};
normalized = false;
blocksize = 10;
tol = 1E-6;
nmost = [1 5];


[instack,inclass] = imcast(instack,'double');
[cc ca] = chancount(instack); 
nc = cc+ca;
numframes = size(instack,4);

% don't need to safeguard against NaN if input datatype can't contain any
fpinput = strismember(inclass,{'single','double'});

if nargout > numel(varargin)
	error('IMSTATS: output argument list length exceeds number of requested metrics')
elseif any(nargout == [0 1])
	varargout = {[]};
end

metriclist = {};
k = 1;
while k <= numel(varargin);
	key = varargin{k};
	if ischar(key)
		key = lower(key(key ~= ' '));
		if strismember(key,metricstrings)
			metriclist = cat(2,metriclist,key);
			k = k+1;
		else
			switch key
				case 'tilesize'
					if isnumeric(varargin{k+1})
						blocksize = varargin{k+1};
					else
						error('IMSTATS: expected numeric value for TILESIZE')
					end
					k = k+2;
				case 'tolerance'
					if isnumeric(varargin{k+1})
						tol = varargin{k+1};
					else
						error('IMSTATS: expected numeric value for TOLERANCE')
					end
					k = k+2;
				case 'nmost'
					if isnumeric(varargin{k+1})
						if isscalar(varargin{k+1})
							nmost = [1 round(varargin{k+1})];
						else
							nmost = round(varargin{k+1});
						end
					else
						error('IMSTATS: expected numeric value for NMOST')
					end
					k = k+2;
				case 'normalized'
					normalized = true;
					k = k+1;
				otherwise
					error('IMSTATS: unknown input parameter name %s',varargin{k})
			end			
		end
	else
		error('IMSTATS: keys are supposed to be strings.')
	end
	
end

inpict = [];
thisip = [];
inpaintedpict = [];
imnotreshaped = true;
imnotinpainted = true;
imnotflattened = true;
for mk = 1:numel(metriclist)
	thismetric = metriclist{mk};
	thisoutvec = zeros([1 nc]);

	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if strcmp(thismetric,'modecolor')
		flattenimage();
		prepformc();

		% RGB2IND only supports RGB inputs, but it's built-in and much faster 
		% than using colorquant or other decomposition/quantization methods in m-code.
		% Using kmeans is even slower, and would introduce a stats toolbox dependency.
		% Just find ways to cram over/under-sized data through RGB2IND
		nbins = 1024;
		if cc == 1 && ca == 0
			thisoutvec = mode(thisip(:));
		elseif cc == 1 && ca == 1
			[idxpict map] = rgb2ind(thisip(:,:,[1 2 2]),nbins,'nodither');
			idxpict = uint16(idxpict)+1;
			thisoutvec = map(mode(idxpict(:)),:);
			thisoutvec = thisoutvec(1:2);
		elseif cc == 3 && ca == 0
			[idxpict map] = rgb2ind(thisip,nbins,'nodither');
			idxpict = uint16(idxpict)+1;
			thisoutvec = map(mode(idxpict(:)),:);
		elseif cc == 3 && ca == 1
			afactor = 10^ceil(log10(nbins));
			[idxrgb map] = rgb2ind(thisip(:,:,1:3),nbins,'nodither');
			[idxa amap] = rgb2ind(thisip(:,:,[4 4 4]),nbins,'nodither');
			idxboth = (afactor*double(idxa)+double(idxrgb));
			modeidxboth = mode(idxboth(:));
			modeidxrgb = mod(modeidxboth,afactor)+1;
			modeidxa = floor(modeidxboth/afactor)+1;
			thisoutvec = [map(modeidxrgb,:) amap(modeidxa,1)];
		elseif cc == 3 && ca == 3
			afactor = 10^ceil(log10(nbins));
			[idxrgb map] = rgb2ind(thisip(:,:,1:3),nbins,'nodither');
			[idxa amap] = rgb2ind(thisip(:,:,4:6),nbins,'nodither');
			idxboth = (afactor*double(idxa)+double(idxrgb));
			modeidxboth = mode(idxboth(:));
			modeidxrgb = mod(modeidxboth,afactor)+1;
			modeidxa = floor(modeidxboth/afactor)+1;
			thisoutvec = [map(modeidxrgb,:) amap(modeidxa,:)];
		else 
			error('IMSTATS: ''modecolor'' mode only supports I/IA/RGB/RGBA/RGBAAA images')
		end
		
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif strcmp(thismetric,'modefuzzy')
		flattenimage();
		prepformc();

		% this is basically the same idea as modecolor, but instead of picking the
		% most common color, we're picking the frequency-weighted mean of a selected 
		% range of the most common colors.  
		nbins = 1024;
		if cc == 1 && ca == 0
			% unique values sorted by freq
			inpict = imcast(thisip(:),'uint16')+1;
			[uval,~,~] = unique(inpict);
			freq = histc(inpict,uval);
			[freq,idx2] = sort(freq,'descend');
			uval = uval(idx2);
			% caclulate freq-weighted mean of most common colors
			freq = freq(nmost(1):nmost(2));
			thisoutvec = double(uval(nmost(1):nmost(2)));
			thisoutvec = sum(thisoutvec.*freq,1)/sum(freq);
			thisoutvec = imrescale(thisoutvec,'uint16','double');
		elseif cc == 3 && ca == 0
			[idxpict map] = rgb2ind(thisip,nbins,'nodither');
			idxpict = uint16(idxpict)+1;
			% unique values sorted by freq
			idxpict = idxpict(:);
			[uval,~,~] = unique(idxpict);
			freq = histc(idxpict,uval);
			[freq,idx2] = sort(freq,'descend');
			uval = uval(idx2);
			% caclulate freq-weighted mean of most common colors
			freq = freq(nmost(1):nmost(2));
			thisoutvec = map(uval(nmost(1):nmost(2)),:);
			thisoutvec = sum(bsxfun(@times,thisoutvec,freq),1)/sum(freq);
		else 
			error('IMSTATS: ''modefuzzy'' mode only supports I/RGB images')
		end
		
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif strcmp(thismetric,'moderange')
		flattenimage();
		prepformc();

		% this is basically the same idea as modecolor, but instead of picking the
		% most common color, we're picking a selected range of the most common colors.  
		nbins = 1024;
		if cc == 1 && ca == 0
			% unique values sorted by freq
			inpict = imcast(thisip(:),'uint16')+1;
			[uval,~,~] = unique(inpict);
			freq = histc(inpict,uval);
			[~,idx2] = sort(freq,'descend');
			uval = uval(idx2);
			thisoutvec = imcast(uval(nmost(1):nmost(2)),'double');
		elseif cc == 3 && ca == 0
			[idxpict map] = rgb2ind(thisip,nbins,'nodither');
			idxpict = uint16(idxpict)+1;
			% unique values sorted by freq
			idxpict = idxpict(:);
			[uval,~,~] = unique(idxpict);
			freq = histc(idxpict,uval);
			[~,idx2] = sort(freq,'descend');
			uval = uval(idx2);
			% caclulate freq-weighted mean of most common colors
			thisoutvec = map(uval(nmost(1):nmost(2)),:);
		else 
			error('IMSTATS: ''moderange'' mode only supports I/RGB images')
		end

	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif strismember(thismetric,{'localcontrast','edginess'})
		% can't flatten the image to handle multiframe inputs; just do it frame by frame and average
		for f = 1:numframes
			prepformapmodes();
			switch thismetric
				case 'localcontrast'
					% blockwise using imdetile
					s = size(inpaintedpict);
					ipstack = imdetile(inpaintedpict,round(s(1:2)./blocksize));
					thisoutvec(:,:,:,f) = permute(mean((max(max(ipstack))-min(min(ipstack)))./(mean(mean(ipstack))+eps),4),[1 3 2]);
				case 'edginess'
					% mean of normalized Scharr filtered image
					edgepict = edgemap(inpaintedpict);
					thisoutvec(:,:,:,f) = permute(mean(mean(edgepict,1),2),[1 3 2]);
			end
		end
		thisoutvec = mean(thisoutvec,4);

	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif strismember(thismetric,{'nancount','nanfrac'})
		flattenimage();
		if imnotreshaped
			stripepict = reshape(inpict,[size(inpict,1)*size(inpict,2) nc]);
			imnotreshaped = false;
		end
		switch thismetric
			case 'nancount'
				thisoutvec = sum(isnan(stripepict),1);
			case 'nanfrac'
				thisoutvec = sum(isnan(stripepict),1)/prod([size(inpict,1) size(inpict,2)]);
		end

	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	else
		flattenimage();
		if imnotreshaped
			stripepict = reshape(inpict,[size(inpict,1)*size(inpict,2) nc]);
			imnotreshaped = false;
		end
		% do this channel-wise so that nans can be isolated without breaking symmetry
		for c = 1:nc
			thisc = stripepict(:,c);
			if fpinput
				thisc = thisc(~isnan(thisc));
			end
			switch thismetric
				case 'mean'
					thisoutvec(c) = mean(thisc,1);
				case 'mode'
					thisoutvec(c) = mode(thisc,1);
				case 'median'
					thisoutvec(c) = median(thisc,1);
				case 'std'
					thisoutvec(c) = std(thisc,0,1);
				case 'min'
					thisoutvec(c) = min(thisc,[],1);
				case 'max'
					thisoutvec(c) = max(thisc,[],1);
				case 'oogcount'
					thisoutvec(c) = sum(thisc > 1 | thisc < 0);
				case 'oogfrac'
					thisoutvec(c) = sum(thisc > 1 | thisc < 0)/prod([size(inpict,1) size(inpict,2)]);
				case 'satfrac'
					thisoutvec(c) = sum(thisc >= (1-tol) | thisc <= tol)/prod([size(inpict,1) size(inpict,2)]);
				case 'whitefrac'
					thisoutvec(c) = sum(thisc >= (1-tol))/prod([size(inpict,1) size(inpict,2)]);
				case 'blackfrac'
					thisoutvec(c) = sum(thisc <= tol)/prod([size(inpict,1) size(inpict,2)]);
			end
		end
	end

	if ~normalized && strismember(thismetric,rescaledmetrics)
		thisoutvec = rescale(thisoutvec);
	end
	
	if any(nargout == [0 1])
		varargout(1) = {cat(1,varargout{1},thisoutvec)};
	else
		varargout(mk) = {thisoutvec};
	end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function flattenimage()
	if imnotflattened
		if numframes > 1
			inpict = imtile(instack,[numframes 1]);
		else 
			inpict = instack;
		end
	end
end

function prepformc()
	% need to remove entire pixels containing NaN
	if fpinput
		if nc == 1
			thisip = inpict;
			thisip = thisip(~isnan(thisip));
		else
			thisip = reshape(inpict,[size(inpict,1)*size(inpict,2) 1 nc]);
			% test to see if this is slower than replicating the union of nan lists to form a logical mask
			safelist = find(~sum(isnan(thisip),3));
			thisip = thisip(safelist,:,:);
		end
	else
		thisip = inpict;
	end
end

function prepformapmodes()
	% can't use reshaping/truncation to eliminate NaNs here, so just inpaint them
	if fpinput && imnotinpainted
		inpaintedpict = instack(:,:,:,f);
		for tc = 1:nc
			thischan = inpaintedpict(:,:,tc);
			if any(isnan(thischan(:)))
				inpaintedpict(:,:,tc) = inpaint_nans(thischan);
			end
		end
		if f == numframes; imnotinpainted = false; end
	elseif ~fpinput && imnotinpainted
		inpaintedpict = instack(:,:,:,f);
		if f == numframes; imnotinpainted = false; end
	end
end

function thisvec = rescale(thisvec)
	if strismember(inclass,{'uint8','uint16','int16'})
		thisvec = imrescale(thisvec,'double',inclass);
	end
end

end




