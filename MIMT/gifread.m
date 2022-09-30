function varargout = gifread(filepath,varargin)
%   GIFREAD(FILEPATH, {OPTIONS})
%       reads all frames of an animated gif into a 4-D image array
%
%       DUE TO BUGS IN MATLAB, MULTIFRAME GIFS CANNOT BE CORRECTLY READ IN R2018b OR NEWER
%
%       As of R2018b, changes to the imread support file readgif.m cause imread to 
%       destructively alter the content of multiframe gifs which have unique local color 
%       tables.  This bug breaks gifread unless the 'imagemagick' option can be used.  
%       My efforts to file a bug report on this issue appear to have either been completely 
%       misunderstood or ignored, as it was closed without being listed or patched. 
%       An unreasonably detailed description of the problem can be found here:
%       https://www.mathworks.com/matlabcentral/answers/654298-nonsensical-imread-behavior-with-multiframe-gifs-in-r2019 
%       A simple test script is included here:
%       https://www.mathworks.com/matlabcentral/answers/893347-is-there-a-bug-in-imread-or-imfinfo-with-multiframe-gifs-in-r2021a-b
%       If you are using one of these versions, read the links, test it and file a bug report!
%       
%   FILEPATH: full path and filename
%   OPTIONS are keys and key-value pairs as follows:
%       'native' or 'imagemagick' specify the file read method (default 'native')
%           'imagemagick' method is a workaround for bug 813126 present in
%           R14SP3-2012a versions.  Bug consists of an OBOE in reading LCT data.
%           A patch does exist for these versions:
%           https://www.mathworks.com/support/bugreports/813126
%       'rgb' specifies an RGB/RGBA output image (default)
%           when RGB output is specified, any transparency is appended as an alpha channel
%           keys 'tcidx' and 'alpha' are ignored
%       'indexed' specifies an indexed output image of type 'uint8'
%           when indexed output is specified, transparency can be handled one of two ways (default 'tcidx')
%           'tcidx' produces an extra vector containing the transparent color indices for each frame
%           'alpha' appends a second channel to the indexed image
%       'framerange' followed by a vector of frames allows the user to specify which frames should be read
%           default behavior is to read all frames
%       'coalesce' Specifies whether to coalesce the image sequence prior to
%           importing.  Used when loading optimized gifs. Requires imagemagick.
%       'double','single','uint8','uint16','int16' specify the output class for RGB images
%       
%   The default output type is an RGB image of class 'uint8'
%   For indexed outputs, MAP is a 4-D array of class 'double' with standard [0 1] range
%       uint8 indexed images have index range of [0 255], necessarily contrary to Matlab array indexing convention
%       TCIDX is of class 'double' and uses Matlab [1 256] indexing convention
%       When no transparent content is specified for a given frame, TCIDX will have NaN value.
%
%   NOTE: 
%      IMREAD() handles 'RestoreBG' disposal methods differently than most web browsers and image viewers.
%      It will fill transparent areas with the frame's defined 'BackgroundColor' instead of preserving them.
%      Using the 'imagemagick' option will usually solve this issue if you expect to retain transparent regions.
%      'imagemagick' option requires external tools and assumes a *nix environment.
% 
%   EXAMPLES:
%       Read a multiframe gif into an RGB array
%           inpict=gifread('sources/catbat.gif');
%       Do the same thing, but only extract specific frames
%           inpict=gifread('sources/catbat.gif','framerange',[2 4 5]);
%       Read a multiframe gif into an indexed array with a map
%           [inpict map]=gifread('sources/catbat.gif','indexed');
%       Read an animation with transparency and write it again with a different frame delay
%          [inpict map tcidx]=gifread('advtime.gif','indexed','tcidx','imagemagick');
%          gifwrite(inpict,map,tcidx,'restorebg','giftest.gif',0.10)
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/gifread.html
% See also: gifwrite imread imwrite imfinfo


coalesce = 0;
method = 'native';
outclass = 'uint8';
indexed = 0;
alphamode = 'alpha';
hasalpha = 0;
allframes = 1;
framerange = [];

k = 1;
while k <= nargin-1
	key = lower(varargin{k});
	switch key
		case {'double','single','uint8','uint16','int16'}
			outclass = key;
			k = k+1;
		case {'native','imagemagick'}
			method = key;
			k = k+1;
		case 'coalesce'
			coalesce = 1;
			k = k+1;
		case 'indexed'
			indexed = 1;
			alphamode = 'tcidx';
			k = k+1;
		case 'rgb' % dummy case
			indexed = 0;
			k = k+1;
		case 'tcidx'
			alphamode = 'tcidx';
			indexed = 1;
			k = k+1;
		case 'alpha'
			alphamode = 'alpha';
			k = k+1;
		case 'framerange'
			if isnumeric(varargin{k+1})
				allframes = 0;
				framerange = varargin{k+1};
			else
				error('GIFREAD: FRAMERANGE must be numeric')
			end
			k = k+2;
		otherwise
			error('GIFREAD: Ignoring unknown key ''%s''\n',key)
	end
end



if ~indexed
	alphamode = 'alpha';
end

if coalesce == 1
    system(sprintf('convert %s -layers coalesce /dev/shm/gifreadcoalescetemp.gif',filepath));
    filepath = '/dev/shm/gifreadcoalescetemp.gif';
end

infostruct = imfinfo(filepath);
if max(framerange) > numel(infostruct)
	error('GIFREAD: FRAMERANGE requests frame %d. Image only contains %d frames',max(framerange),numel(infostruct))
elseif min(framerange) < 1
	error('GIFREAD: FRAMERANGE requests frame %d. The minimal valid frame index is 1',min(framerange))
end


maxtablelength = 0;
if strcmpi(method,'native')
    % use imread() directly (requires patched imgifinfo.m)
	if allframes
		[outpict, ~] = imread(filepath, 'gif','Frames','all');
	else
		[outpict, ~] = imread(filepath, 'gif','Frames',framerange);
	end
    
	s = size(outpict);
    numframes = size(outpict,4);
	outmap = zeros([256 3 1 numframes],'double');
	tcidxvec = zeros([numframes 1],'double');
	
	% build 4-D map
    for f = 1:numframes
		if allframes
			try
				tcidxvec(f) = infostruct(1,f).TransparentColor;
			catch
				tcidxvec(f) = NaN;
			end
			thismap = infostruct(1,f).ColorTable;
		else
			try
				tcidxvec(f) = infostruct(1,framerange(f)).TransparentColor;
			catch
				tcidxvec(f) = NaN;
			end
			thismap = infostruct(1,framerange(f)).ColorTable;
		end
		
		outmap(1:size(thismap,1),:,:,f) = thismap; % LCT might not be full-length
		maxtablelength = max(size(thismap,1),maxtablelength);
    end
else
    % split the gif using imagemagick instead
    system(sprintf('convert %s /dev/shm/%%03d_gifreadtemp.gif',filepath));
	infostruct = imfinfo(filepath);
	
	%dummy read to get image size
    [image, ~] = imread('/dev/shm/000_gifreadtemp.gif', 'gif');
    s = size(image);
	
	if allframes
		[~,numframes] = system('ls -1 /dev/shm/*gifreadtemp.gif | wc -l');
		numframes = str2num(numframes);
		framelist = 1:numframes;
	else
		numframes = numel(framerange);
		framelist = framerange;
	end

    outpict = zeros([s(1:2) 1 numframes],'uint8');
	outmap = zeros([256 3 1 numframes],'double');
	tcidxvec = zeros([1 numframes],'double');

	% build 4-D map
    for fn = 1:numframes;
		f = framelist(fn);
		try
			tcidxvec(fn) = infostruct(1,f).TransparentColor;
		catch
			tcidxvec(fn) = NaN;
		end
		
        [thisframe thismap] = imread(sprintf('/dev/shm/%03d_gifreadtemp.gif',f-1), 'gif');
		outpict(:,:,:,fn) = thisframe;
		outmap(1:size(thismap,1),:,:,fn) = thismap;
		maxtablelength = max(size(thismap,1),maxtablelength);
    end

    %system('rm /dev/shm/*gifreadtemp.gif');
end


if coalesce == 1
    system(sprintf('rm %s',filepath));
end


if ~all(isnan(tcidxvec)); hasalpha = 1; end


% transparent content is defined (might not actually be used though)
if hasalpha && strcmp(alphamode,'alpha')
	% extract alpha map (indexed or rgb modes)
	alphamap = ones(size(outpict),outclass);
	for f = 1:numframes
		if ~isnan(tcidxvec(f))
			alphamap(:,:,:,f) = imcast(outpict(:,:,:,f) ~= (tcidxvec(f)-1),outclass);
		end
	end
end


% convert from indexed as necessary and cast for output
if indexed
	if strcmp(alphamode,'alpha')
		varargout{1} = cat(3,outpict,imcast(alphamap,'uint8'));
	else
		varargout{1} = outpict;
		varargout{3} = tcidxvec;
	end
	
	% truncate color table as needed
	if numframes == 1
		varargout{2} = outmap(1:maxtablelength,:,:);
	else
		varargout{2} = outmap(1:maxtablelength,:,:,:);
	end
else	
	rgboutpict = zeros([s(1:2) 3 numframes],outclass);
	for f = 1:numframes;
		rgboutpict(:,:,:,f) = imcast(ind2rgb(outpict(:,:,:,f),outmap(:,:,:,f)),outclass);
	end
	
	if hasalpha
		rgboutpict = cat(3,rgboutpict,alphamap);
	end
	
	varargout{1} = rgboutpict;
end



return






