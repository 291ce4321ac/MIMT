function gifwrite(varargin)
%   GIFWRITE(INARRAY, {DISPOSALMETHOD}, FILEPATH, {DELAY}, {WRITEMETHOD}, {LOOPCOUNT}, {DITHER})
%   GIFWRITE(INARRAY, MAP, {TRANSPARENTIDX}, {DISPOSALMETHOD}, FILEPATH, {DELAY}, {WRITEMETHOD}, {LOOPCOUNT})
%       Write image stack to an animated gif 
%       
%   INARRAY: 4-D image array
%       RGB/I or RGBA/IA arrays may be of any standard image class
%       indexed arrays should be of class 'uint8'
%       if alpha content is present, it will be reduced to a logical mask
%       
%       indexed images with transparency may be specified one of two ways
%           a color index can be reserved for transparent pixels
%           or the image array may have alpha content in a second channel
% 
%   MAP: color maps used with indexed image input only
%       maximum map dimensions for a multiframe gif should be [256 3 1 numframes]
%       if a multiframe image is supplied with a single-frame map, it will be expanded.
%       floating point maps with values >1 are assumed to have a white level of 255
%
%       indexed images with alpha must have at most 255 colors used
%       one color entry must be reserved for transparency specification in the gif
%
%   TRANSPARENTIDX: index/indices reserved for transparent pixels range:[1 256]
%       may be a single integer or an integer vector of length = numframes
%       NaN or zero elements are ignored.
%
%   DISPOSALMETHOD: string or cell array of strings (default 'donotspecify')
%       If frame disposal method needs to be specified, it may be specified by
%       using a cell array of keys or a single key with implicit expansion
%       Accepted methods: 'leaveinplace' 'restorebg' 'restoreprevious' 'donotspecify'
%
%   DELAY: frame delay in seconds (default 0.05)
%       may be a scalar or a vector of length = numframes
%
%   FILEPATH: full name and path of output animation
% 
%   WRITEMETHOD: animation method, 'native' or 'imagemagick' (default 'native')
%       'imagemagick' is for niche use, and is slower and does not support all inputs
%
%   LOOPCOUNT: optionally specifies how many times an animation should be played
%       (default Inf).  This has no effect when using 'imagemagick' option.
%
%   DITHER: optionally specifies how an RGB input should be quantized.  Valid keys 
%       are 'dither' (default) and 'nodither'.  This has no effect when using
%       the 'imagemagick' option.
% 
%   NOTE:
%       This is intended for simple, relatively nonoptimized images.
%       Specification of frame offset, background color, etc are not supported.
%      'imagemagick' option requires external tools and assumes a *nix environment.
%
%   EXAMPLES:
%       Write a simple RGB image stack 
%          gifwrite(rgbpict,'giftest.gif')
%       Read an animation with transparency and write it again with a different frame delay
%          [inpict map tcidx]=gifread('advtime.gif','indexed','tcidx','imagemagick');
%          gifwrite(inpict,map,tcidx,'restorebg','giftest.gif',0.10)
%       Write an RGB image stack using finite loopcount and no dithering
%          gifwrite(rgbpict,'giftest.gif','loopcount',4,'nodither')
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/gifwrite.html
% See also: gifread imread imwrite imfinfo
   

delay = 0.05;
method = 'native';
tcidx = NaN;
disposalmethod = 'donotspecify';
loopcount = Inf;
ditherstr = 'dither';

% this is all convoluted because i'm trying to not break compatibility with prior versions which used strictly ordered parameters
% this allows for extra keys or key-value pairs to be handled in the future
dispmethkeys = {'leaveinplace' 'restorebg' 'restoreprevious' 'donotspecify'};
validkeys = [{'native' 'imagemagick' 'loopcount' 'dither' 'nodither'} dispmethkeys];
vkindex = [];
for k = 1:nargin
	thisarg = varargin{k};
	if ischar(thisarg) || iscellstr(thisarg) %#ok<ISCLSTR>
		if all(ismember(lower(thisarg),validkeys))
			if all(ismember(lower(thisarg),dispmethkeys))
				disposalmethod = thisarg;
				vkindex = [vkindex k]; %#ok<*AGROW>
			elseif ismember(lower(thisarg),{'native' 'imagemagick'})
				method = thisarg;
				vkindex = [vkindex k];
			elseif ismember(lower(thisarg),{'dither' 'nodither'})
				ditherstr = thisarg;
				vkindex = [vkindex k];
			elseif strcmpi(thisarg,'loopcount')
				loopcount = varargin{k+1};
				vkindex = [vkindex k k+1];
			end
		end
	end
end
% reshape varargin to remove non-legacy keys
varargin = varargin(~ismember(1:nargin,vkindex));
narginmod = numel(varargin);

% process legacy inputs
if isnumeric(varargin{2})
	indexed = 1;
	inarray = varargin{1};
	inmap = varargin{2};
	if isnumeric(varargin{3})
		tcidx = varargin{3};
		filepath = varargin{4};
		if narginmod > 4; delay = varargin{5}; end
	else
		filepath = varargin{3};
		if narginmod > 3; delay = varargin{4}; end
	end
else
	indexed = 0;
	inarray = varargin{1};
	filepath = varargin{2};
	if narginmod > 2; delay = varargin{3}; end
end

if islogical(inarray)
	inarray = imcast(inarray,'uint8');
end

% gif89a supports the assignment of a specific color as a 1-b transparency mask per frame
% use 'transparentcolor' and reference the index in MAP
% if alpha is present, quantize to 256-1 levels to reserve maximal index for alpha

% types of images with transparency:
%	A: rgb, defined by alpha channel
%	B: indexed, defined by alpha channel
%	C: indexed, defined by transparencyidx

% to create each file frame
%	A: quantize to at most 255 levels
%       find table length
%		pad color table with extra entry
%       set all transparent pixels in frame to transparencyidx=maplength+1
%		write image, color table and transparencyidx for each frame
%   B: pad color table with extra entry
%       find table length
%		set all transparent pixels in frame to transparencyidx=maplength+1
%		write image, color table and transparencyidx for each frame
%	C: write image, color table and transparencyidx for each frame

numframes = size(inarray,4);

hasalpha = any(size(inarray,3) == [2 4]);
hastc = ~any(isnan(tcidx));

% expand delay as necessary
if numel(delay) == 1 
	delay = delay*ones(numframes);
elseif numel(delay) ~= numframes
		error('GIFWRITE: length of DELAY must be 1 or must match number of image frames')
end

% expand disposalmethod as necessary
if ischar(disposalmethod)
	if numframes > 1
		dmstr = disposalmethod;
		disposalmethod = cell(1,numframes);
		disposalmethod(:) = {dmstr};
	else
		disposalmethod = {disposalmethod};
	end
end

if numel(disposalmethod) ~= numframes
	error('GIFWRITE: length of DISPOSALMETHOD must be 1 or must match number of image frames')
end

if hasalpha && hastc
	error('GIFWRITE: specify transparent content via the colortable or a second image channel, not both')
end

% if alpha is present, isolate it
if hasalpha
	alphamap = imcast(inarray(:,:,end,:),'logical');
	inarray = inarray(:,:,1:end-1,:);
end

% if transparent color is specified, make sure its dimensions are sane
if hastc 	
	if numel(tcidx) == 1 && numframes > 1
		tcidx = repmat(tcidx,[1 numframes]);
	elseif numel(tcidx) ~= numframes
		error('GIFWRITE: length of TRANPARENCYIDX must be 1 or must match number of image frames')
	end
end

if indexed
	if size(inmap,1) > 256
		error('GIFWRITE: gif files don''t support color tables longer than 256 entries')
	end
	
	if numframes > 1
		nummapframes = size(inmap,4);
		if nummapframes == 1 
			inmap = repmat(inmap,[1 1 1 numframes]);
		elseif nummapframes ~= numframes
			error('GIFWRITE: number of map frames must be 1 or must match number of image frames')
		end
	end
	
	[~, mx] = imrange(inmap);
	if isfloat(inmap) && mx >= 2 % this threshold allows for minor supramaximal white level caused by unclamped casting or conversion
		inmap = inmap/255;
	elseif isinteger(inmap)
		inmap = imcast(inmap,'double');
	end
		
	
elseif size(inarray,3) == 1 
	% expand single-channel non-indexed (I/IA) images
    inarray = repmat(inarray,[1 1 3 1]);
end

% at this point, 
% if A or B, alpha is isolated
% if B or C, color table has been expanded
% if C, transparencyidx has been expanded
% disposalmethod has been expanded

if strcmpi(method,'native')
    disp('creating animation')
	tcidxthisframe = 0;
	
	if indexed
		% INDEXED INPUTS
		for f = 1:numframes
			tfhastc = 0;
			imind = uint8(inarray(:,:,:,f));
			cm = inmap(:,:,:,f);

			% CASE B
			if hasalpha && any(any(alphamap(:,:,:,f) == 0)) % this frame has transparent content
				tfhastc = 1;
				numcolorsthisframe = size(cm,1);
				
				if numcolorsthisframe > 255
					error('GIFWRITE: maps for indexed image frames with alpha must have at most 255 entries')
				end
				
				% append dummy row to color table & set tcidx
				tcidxthisframe = numcolorsthisframe;
				cm = cat(1,cm,[0 0 0]);
				
				% set transparent pixels to tcidx (0 = transparent)
				imind(~alphamap(:,:,:,f)) = tcidxthisframe;
			end
			
			% CASE C
			if hastc
				tcidxthisframe = tcidx(f)-1; % image is cast as uint8
				if tcidxthisframe ~= 0 || ~isnan(tcxidxthisframe)
					tfhastc = 1;
				end
			end
			
			[~, mx] = imrange(imind);
			if mx > size(cm,1)
				error('GIFWRITE: range of indices in frame %f exceeds the length of the corresponding color map',n)
			end
			
			writeaframe();
		end
	else
		% RGB INPUTS
		for f = 1:numframes		
			if hasalpha
				tfhastc = 1;
				[imind,cm] = rgb2ind(inarray(:,:,:,f),255,ditherstr);
				numcolorsthisframe = size(cm,1);
				
				% append dummy row to color table & set tcidx
				tcidxthisframe = numcolorsthisframe;
				cm = cat(1,cm,[0 0 0]);
				
				% set transparent pixels to tcidx (0 = transparent)
				imind(~alphamap(:,:,:,f)) = tcidxthisframe;
			else
				tfhastc = 0;
				[imind,cm] = rgb2ind(inarray(:,:,:,f),256,ditherstr);
			end
			
			writeaframe();
		end
	end
else
	% USE EXTERNAL METHOD
    disp('creating frames')    
    for f = 1:numframes
        imwrite(inarray(:,:,:,f),sprintf('/dev/shm/%03dgifwritetemp.png',f),'png');
    end
    
    disp('creating animation')
    system(sprintf('convert -delay %d -loop 0 /dev/shm/*gifwritetemp.png "%s"',delay*100,filepath));
    
    disp('cleaning up')    
    system('rm /dev/shm/*gifwritetemp.png');
end


function writeaframe()
	if tfhastc
		if f == 1
			imwrite(imind,cm,filepath,'gif','DelayTime',delay(f),'Loopcount',loopcount,'TransparentColor',tcidxthisframe,'DisposalMethod',disposalmethod{f});
		else
			imwrite(imind,cm,filepath,'gif','DelayTime',delay(f),'WriteMode','append','TransparentColor',tcidxthisframe,'DisposalMethod',disposalmethod{f});
		end
	else
		if f == 1
			imwrite(imind,cm,filepath,'gif','DelayTime',delay(f),'Loopcount',loopcount,'DisposalMethod',disposalmethod{f});
		else
			imwrite(imind,cm,filepath,'gif','DelayTime',delay(f),'WriteMode','append','DisposalMethod',disposalmethod{f});
		end

	end
end

end



















