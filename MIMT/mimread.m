function inbucket = mimread(pathexp,varargin)
% PICTARRAY = MIMREAD(PATHEXP,{OPTIONS})
% PICTARRAY = MIMREAD(PATHPREFIX,EXPRLIST,{OPTIONS})
%    Load an arbitrary selection of image files into a cell array for further processing.
%    Input files do not need to be of same filetype, geometry, or datatype;
%    they may also differ in the number of channels (including transparency).
%    Single-frame and multiframe images can be mixed.
%    MIMREAD and IMSTACKER essentially replace BATCHLOADER for general multifile image import.
%
% The path to a set of files may be specified one of two ways:
%    Using a single string expression:
%       PATHEXP is a single string identifying the files to import.  
%          Any syntax supported by Matlab's DIR function should work
%          e.g. 'imagefolder/catpictures/fluffy*.jpg'
%
%    Using a prefix + list arrangement
%       PATHPREFIX is a single string explicitly identifying the prefix to prepend to EXPRLIST
%       EXPRLIST is a cell array of strings identifying the files to import (wildcards supported)
%          e.g. 'imagefolder/catpictures', {'fluffy*.jpg', 'cute*.png', 'catyawn.gif'}
%
%    Any matched files which are not valid images will be ignored.  A warning will be dumped to
%    the console for the purposes of troubleshooting.
%
% OPTIONS are keys including:
%    VERBOSE will cause the list of file paths and other image information to be dumped to console.
%    QUIET will suppress any non-terminal warnings when invalid images are encountered.
%
% EXAMPLE:
%    Load a bunch of images;
%       pictarray=mimread('sources',{'ban*','*bars*','table*'},'verbose');
%    Use IMSTACKER to read and organize everything into a 4D stack:
%       pictstack=imstacker(pictarray,'gravity','nw','size','max','fit','rigid','interpolation',...
%                  'bicubic','outclass','uint8','padding',[0.2 0 0.5 0.8],'verbose');
%
% NOTES:
%    Supported formats include WEBP, and those supported by IMREAD
% 
%    Indexed image output is not supported.  Any indexed images encountered will be converted.
%
%    Multiframe import is supported for GIF, TIFF, and CUR/ICO files. Multiframe APNG and WEBP
%    are not supported.
%
%    GIF file import uses GIFREAD.  WEBP file import uses WPREAD.  See the help for these tools
%    for more info on their capabilites, limitations, and requirements.
%
%    JPG file import uses IMREADORT, so the image(s) should be returned properly oriented as 
%    dictated by their EXIF orientation information.  
% 
%    While MIMREAD supports CUR/ICO files, importing is limited by the abilities of IMREAD.  
%    Files containing any compressed (PNG) frames will be skipped.
%    Individual frames with geometry >256px will be skipped.
%
%    If using this tool to import imagesets exported by GIMP (via Export Layers), keep in mind that
%    the output images inherit the geometry of their respective layer, not the source image itself.  
%    This means that while IMSTACKER can easily merge the dissimilarly-sized files read by MIMREAD, 
%    the layer offsets will be gone.  Either make sure all layers match the image size before 
%    exporting (Layer to Image Size) or find some method to retain offset information.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/mimread.html
% See also: imstacker, batchloader, imread, gifread, imfinfo, imreadort, wpread


verbosity = 'normal';
pathsuffix = {};
imagepaths = {};

k = 1;
while k <= numel(varargin)
	thiskey = varargin{k};
	if iscell(thiskey)
		pathsuffix = thiskey;
		k = k+1;
	elseif ischar(thiskey)
		switch lower(thiskey)
			case 'verbose'
				verbosity = 'verbose';
				k = k+1;
			case 'quiet'
				verbosity = 'quiet';
				k = k+1;
			otherwise
				error('MIMREAD: unknown key %s',varargin{k})
		end
	else
		error('MIMREAD: invalid numeric argument')
	end
end



% PROCESS PATH EXPRESSION(S) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(pathsuffix)
	pathprefix = pathexp;
	pathexp = cell([numel(pathsuffix) 1]);
	for x = 1:numel(pathsuffix)
		pathexp(x) = {fullfile(pathprefix,pathsuffix{x})};
	end
else
	pathexp = {pathexp};
end

for x = 1:numel(pathexp)
	pathinfo = dir(pathexp{x});
	pathinfo = pathinfo(~cellfun('isempty', {pathinfo.date}));
	pathinfo = pathinfo(~[pathinfo.isdir]); % remove directories
	pathprefix = fileparts(pathexp{x});
	imagenames = {pathinfo.name}';
	for i = 1:numel(imagenames)
		imagepaths = cat(1,imagepaths,{fullfile(pathprefix,imagenames{i})});
	end
end

if strcmp(verbosity,'verbose')
	disp('MATCHING FILES:')
	fprintf('%s\n',imagepaths{:})
end



% READ FILES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numpicts = size(imagepaths,1);
inbucket = cell(numpicts,1);
sizetable = ones(numpicts,4);

% a multiframe GIF file is 1 "pict" (one file read/parse operation)
% a multiframe TIFF/CUR/ICO file is nframes picts (multiple read/parse ops due to potential unique geometry/depth/type)
nvp = 0; % num valid picts 
nvf = 0; % num valid files

for p = 1:numpicts
	% declare some assumed values
	thispict = [];
	thisalpha = [];
	thismap = []; 
	pictisvalid = 1; % assume pict is valid
	
	thisfile = imagepaths{p};	
	switch lower(thisfile(end-3:end))
		case '.gif'
			handlegif();
		case {'.tif','tiff','.cur','.ico'}
			handletiff();
		case {'.jpg','jpeg'}
			handlejpg();
		case 'webp'
			handlewebp();
		otherwise
			handleother();
	end
end

% need to truncate arrays and adjust numpicts after loop
if nvp == 0
	error('MIMREAD: no valid image files found')
elseif nvp ~= numpicts
	numpicts = nvp;
	inbucket = inbucket(1:nvp);
	sizetable = sizetable(1:nvp,:);
end

if strcmp(verbosity,'verbose')
	fprintf('\nNUMBER OF VALID FILES: %d\n',nvf)
	fprintf('\nINPUT SIZE TABLE:\n')
	sizetable
	fprintf('\nNUMBER OF VALID IMAGES: %d\n',numpicts)
end



% SUPPORT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function handlegif()
		try
			thispict = gifread(thisfile,'imagemagick');
		catch
			try
				thispict = gifread(thisfile);
			catch
				pictisvalid = 0;
				if ~strcmp(verbosity,'quiet')
					fprintf('MIMREAD: %s does not appear to be a valid image\n',imagepaths{p})
				end
			end
		end
		
		if pictisvalid
			% GIFREAD already handled this
			thisalpha = [];
			thismap = []; 
			
			nvp = nvp+1;
			nvf = nvf+1;
			addtobucket();
		end
	end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function handletiff()
		% for multiframe TIFF/CUR/ICO files, each frame needs a seperate call to IMREAD
		% geometry/depth/chans may vary between frames
		try
			tinfo = imfinfo(thisfile);
		catch
			pictisvalid = 0;
			if ~strcmp(verbosity,'quiet')
				fprintf('MIMREAD: %s does not appear to be a valid image\n',imagepaths{p})
			end
		end
		
		if pictisvalid
			nvf = nvf+1;
			ntf = numel(tinfo); % number of image frames
			for f = 1:ntf
				badframe = 0;
				if ismember(lower(thisfile(end-3:end)),{'.cur','.ico'}) 
					if tinfo(f).Height == 0 || tinfo(f).Width == 0
						if ~strcmp(verbosity,'quiet')
							fprintf('MIMREAD: Frame %d of %s has zero size.\n',f,thisfile)
							fprintf('   This is likely because it exceeds 256px in at least one dimension.\n')
							fprintf('   IMREAD only supports legacy CUR/ICO format specs.\n')
						end
						badframe = 1;
					end
				end
				
				if ~badframe
					[thispict thismap thisalpha] = imread(thisfile,f);
					nvp = nvp+1;
					addtobucket();
				end
			end
		end
	end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function handlejpg()
		try
			[thispict thismap thisalpha] = imreadort(thisfile);
		catch
			pictisvalid = 0;
			if ~strcmp(verbosity,'quiet')
				fprintf('MIMREAD: %s does not appear to be a valid image\n',imagepaths{p})
			end
		end
		
		if pictisvalid
			nvp = nvp+1;
			nvf = nvf+1;
			addtobucket();
		end
	end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function handlewebp()
		try
			thispict = wpread(thisfile);
		catch
			pictisvalid = 0;
			if ~strcmp(verbosity,'quiet')
				fprintf('MIMREAD: %s does not appear to be a valid image\n',imagepaths{p})
			end
		end
		
		
		
		if pictisvalid
			% WPREAD already handled this
			thisalpha = [];
			thismap = []; 
			
			nvp = nvp+1;
			nvf = nvf+1;
			addtobucket();
		end
	end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function handleother()
		try
			[thispict thismap thisalpha] = imread(thisfile);
		catch
			pictisvalid = 0;
			if ~strcmp(verbosity,'quiet')
				fprintf('MIMREAD: %s does not appear to be a valid image\n',imagepaths{p})
			end
		end
		
		if pictisvalid
			nvp = nvp+1;
			nvf = nvf+1;
			addtobucket();
		end
	end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function addtobucket()
		% convert image from indexed and assemble alpha if valid
		if ~isempty(thismap)
			thispict = ind2rgb(thispict,thismap);
		end

		% check alpha validity if present (PNG, CUR/ICO)
		if ~isempty(thisalpha)
			alphaclass = class(thisalpha);
			pictclass = class(thispict);
			
			% don't bother if alpha is 100%
			acrange = imclassrange(alphaclass);
			[mn mx] = imrange(thisalpha);
			if ~(mx == mn && mx == acrange(2))
				thispict = cat(3,thispict,imcast(thisalpha,pictclass));
			end	
		end

		% this is now a RGB/RGBA image
		inbucket(nvp) = {thispict};
	
		sizetable(nvp,:) = [size(inbucket{nvp},1) size(inbucket{nvp},2) size(inbucket{nvp},3) size(inbucket{nvp},4)];
	end

end % END MAIN SCOPE






























