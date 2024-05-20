function  varargout = cropborder(inpict,varargin)
%   OUTPICT=CROPBORDER(INPICT, {WIDTH}, {OPTIONS})
%   [OUTPICT WIDTHUSED]=CROPBORDER(INPICT, {WIDTH}, {OPTIONS})
%       crops a border of WIDTH pixels from the edges of INPICT
%       this is much more convenient than using imcrop()
%
%   INPICT is an I/IA/RGB/RGBA/RGBAAA of any standard image class
%       4D images are supported
%   WIDTH can either be a scalar or a vector containing 2 or 4 elements (default NaN)
%       Scalar width removes a uniform-width annulus (i.e. [top&bottom&left&right])
%       2-element width spec is [top&bottom left&right]
%       4-element width spec is [top bottom left right]
%       If any elements of WIDTH are NaN, they will be determined automatically
%       based on AUTOMODE and THRESHOLD settings.
%   OPTIONS consist of the following key-value pairs:
%      'automode' specifies the method used for automatically determining WIDTH
%          Automatic modes start at the image perimeter and analyze image vectors
%          (rows, columns, annuli) until some transition is detected. 
%          'variance' looks for increase in the pixel variance between vectors (default)
%          'deltavar' looks for change in the pixel variance between vectors.
%          'deltamean' looks for a change in pixel mean between vectors.  
%          The default option is intended to only detect approximately solid-color
%          borders; the others may be useful for cropping border regions containing
%          relatively uniform patterns, gradients, noise, etc.
%      'threshold' specifies the limit used by AUTOMODE (default 0.01)
%          This might take some significant adjusting if using 'deltavar' or 'deltamean'
%      'channels' specifies which channels should be analyzed in AUTOMODE calculations
%          This may be a scalar or vector; default is to analyze all channels
%
%   Optional output argument WIDTHUSED is a 4-element vector specifying the actual border 
%      widths used for cropping.  This is useful when autocropping features are used.
%
%   It should be noted that this tool is primarily intended for removing borders.  It assumes
%   that the ROI covers the center of the image.  If the border extends to the image center
%   it will fail to find the border width(s).
%
%	EXAMPLES:
%       Automatically remove a constant-width solid border:
%         outpict=cropborder(inpict);
%       Automatically remove symmetric, but unequal solid borders (e.g. letterbox padding)
%         outpict=cropborder(inpict,[NaN NaN]);
%       Close-crop to an uncentered solid object overlaid on a particular uniform pattern:
%         outpict=cropborder(inpict,[NaN NaN NaN NaN],'automode','deltavar','threshold',0.015);
%       Close-crop to an uncentered object in an RGBA image, paying attention only to alpha content:
%         outpict=cropborder(inpict,[NaN NaN NaN NaN],'channels',4);
%       Crop 10px off left & right sides, and automatically crop top & bottom
%         outpict=cropborder(inpict,[NaN 10]);
%
%   Output class is inherited from INPICT   
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/cropborder.html
% See also: imcropFB, addborder


width = NaN; 
threshold = 0.01;
modestrings = {'variance','deltavar','deltamean'};
mode = 'variance';

channels = 1:size(inpict,3);

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		if isnumeric(varargin{k})
			width = varargin{k};
			k = k+1;
		else
			switch lower(varargin{k})
				case 'automode'
					thisarg = lower(varargin{k+1});
					if strismember(thisarg,modestrings)
						mode = thisarg;
					else
						error('CROPBORDER: unknown mode %s\n',thisarg)
					end
					k = k+2;
				case 'threshold'
					if isnumeric(varargin{k+1})
						threshold = varargin{k+1};
					else
						error('CROPBORDER: expected numeric value for THRESHOLD')
					end
					k = k+2;
				case 'channels'
					if isnumeric(varargin{k+1})
						channels = varargin{k+1};
					else
						error('CROPBORDER: expected numeric value for CHANNELS')
					end
					k = k+2;
				otherwise
					error('CROPBORDER: unknown input parameter name %s',varargin{k})
			end
		end
	end
end

% omitnan functionality introduced to var(), mean() in R2015a
isnew = ifversion('>=','R2015a');

if ~isimageclass(inpict,'mimt')
	error('CROPBORDER: INPICT is not of a standard image class')
end

if sum(numel(width) == [1 2 4]) == 0
	error('CROPBORDER: WIDTH must have 1, 2 or 4 elements')
end

s = imsize(inpict);

if any(isnan(width))
	thisannulus = [];
	v = [];
	r = [];
	
	if numel(width) == 1
		getwidth('all');
	elseif numel(width) == 2
		for n = 1:numel(width)
			if isnan(width(n))
				switch n
					case 1
						getwidth('topbottom');
					case 2
						getwidth('leftright');
				end
			end
		end
	else % numel(width) == 4
		for n = 1:numel(width)
			if isnan(width(n))
				switch n
					case 1
						getwidth('top');
						%plot(v,'b'); hold on;
					case 2
						getwidth('bottom');
						%plot(v,'g');
					case 3
						getwidth('left');
						%plot(v,'m');
					case 4
						getwidth('right');
						%plot(v,'c');
				end
				%pause(0.5)
			end
		end
	end
	
end

	
switch numel(width)
	case 1
		width = [1 1 1 1]*width;
	case 2
		width = [[1 1]*width(1) [1 1]*width(2)];
end

outpict = inpict((width(1)+1):(s(1)-width(2)),(width(3)+1):(s(2)-width(4)),:,:);

if nargout == 1
	varargout = {outpict};
else
	varargout{1} = outpict;
	varargout{2} = width;
end



function getwidth(side)
	corners = [s(1) s(2)]+1;
	
	switch side
		case 'all'
			maxr = floor(min(s(1:2))/2);
			v = zeros([1 maxr]);
			width = 0;
			for r = 1:maxr %#ok<*FXUP>
				corners = corners-1;
				thisannulus = cat(1,inpict(r:corners(1),r,channels), ...
					permute(inpict(corners(1),r:corners(2),channels),[2 1 3]), ...
					inpict(corners(1):-1:r,corners(2),channels), ...
					permute(inpict(r,corners(2):-1:r,channels),[2 1 3]));
				if pastborder(); width = r-1; break; end
			end
		case 'topbottom'
			maxr = floor(s(1)/2);
			v = zeros([1 maxr]);
			width(1) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = cat(1,permute(inpict(corners(1),:,channels),[2 1 3]), ...
					permute(inpict(r,:,channels),[2 1 3]));
				if pastborder(); width(1) = r-1; break; end
			end
		case 'leftright'
			maxr = floor(s(2)/2);
			v = zeros([1 maxr]);
			width(2) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = cat(1,inpict(:,r,channels), ...
					inpict(:,corners(2),channels));
				if pastborder(); width(2) = r-1; break; end
			end
		case 'top'
			maxr = floor(s(1)/2);
			v = zeros([1 maxr]);
			width(1) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = permute(inpict(r,:,channels),[2 1 3]);
				if pastborder(); width(1) = r-1; break; end
			end
		case 'bottom'
			maxr = floor(s(1)/2);
			v = zeros([1 maxr]);
			width(2) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = permute(inpict(corners(1),:,channels),[2 1 3]);
				if pastborder(); width(2) = r-1; break; end
			end
		case 'left'
			maxr = floor(s(2)/2);
			v = zeros([1 maxr]);
			width(3) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = inpict(:,r,channels);
				if pastborder(); width(3) = r-1; break; end
			end
		case 'right'
			maxr = floor(s(2)/2);
			v = zeros([1 maxr]);
			width(4) = 0;
			for r = 1:maxr
				corners = corners-1;
				thisannulus = inpict(:,corners(2),channels);
				if pastborder(); width(4) = r-1; break; end
			end
	end
end


function ispast = pastborder()
	% 'omitnan' was introduced in R2015a, and is faster for large vectors
	if isnew
		switch mode
			case 'variance'
				v(r) = sum(var(imcast(thisannulus,'double'),'omitnan'),3);
				ispast = v(r) >= threshold;
			case 'deltavar'
				v(r) = sum(var(imcast(thisannulus,'double'),'omitnan'),3);
				ispast = abs(v(r)-v(max(r-1,1))) >= threshold;
			case 'deltamean'
				v(r) = mean(mean(imcast(thisannulus,'double'),1),3);
				ispast = abs(v(r)-v(max(r-1,1))) >= threshold;
		end
	else
		nonnanmask = any(any(~isnan(thisannulus),3),4);
		nonnanmask = repmat(nonnanmask,[1 1 s(3)]);
		thisvec = imcast(thisannulus(nonnanmask),'double');
		thisvec = reshape(thisvec,[],1,s(3));

		switch mode
			case 'variance'
				v(r) = sum(var(thisvec),3);
				ispast = v(r) >= threshold;
			case 'deltavar'
				v(r) = sum(var(thisvec),3);
				ispast = abs(v(r)-v(max(r-1,1))) >= threshold;
			case 'deltamean'
				v(r) = mean(mean(thisvec,1),3);
				ispast = abs(v(r)-v(max(r-1,1))) >= threshold;
		end
	end
end

end

