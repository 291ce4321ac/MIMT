function CT = im2ct(inpict,varargin)
%  CT = IM2CT(INPICT,{OPTIONS});
%  Create a color table of specified length using the dominant colors of an image.  
%  This is a simple tool, and it should be expected that there are many configurations
%  of images and options which will yield completely garbage results.  Often what
%  people call the "dominant colors" are not at all representative of the dominant
%  fraction of the image, and there's no reason to expect that there is a monotonic
%  and visually pleasing trajectory between them.
%
%  See also:
%  https://www.mathworks.com/matlabcentral/answers/369534-how-to-order-colors#answer_973010
%
%  This tool has limited utility, but it was largely written as a performance improvement 
%  on the image colorization concept in this particular FEX submission:
%  https://www.mathworks.com/matlabcentral/fileexchange/33801-image-colorization
%  In that application, it would be used in conjunction with gray2pcolor().
%
%  INPICT is an RGB image of any standard image class.
%  OPTIONS include the following key-value pairs
%    'ncolors' specifies the output CT length (default 256)
%    'nbreaks' specifies the number of breakpoint colors to be obtained from the
%       given image (default 3). As nothing ensures that the trajectory is smooth or 
%       monotonic in chroma space, increasing this parameter beyond about 2-3 should 
%       be expected to produce unsatisfactory results (e.g. abrupt hue swings).
%    'fullrange' specifies that the terminal endpoints of the CT should be extended
%       to black and white (logical, default true). 
%    'minsat' specifies the minimum color saturation to be considered when selecting
%       breakpoints from the given image (range [0 1], default 0.1).  This caters to
%       the common tendency to focus on the colorful portions of an image when asked
%       to define its "dominant colors".
%    'uniform' specifies how the breakpoints should be distributed in L-space
%       (logical, default true).  When set, breakpoints are uniformly-distributed
%       on L.  When unset, the original L values are preserved.  If original L is 
%       preserved, there is the risk of steps appearing in the output CT, as there
%       may be breakpoints of disparate C,H which are immediately adjacent in L.
%    'cspace' specifies the interpolating color space (default 'lab').
%       See rgb2lch() for supported colorspace names.
%    'interp' specifies the method used for interpolating in chroma-space 
%       (default 'pchip'). See interp1() for supported method names.
%	
%  Output CT is NCOLORSx3 unit-scale double.
%
%  See also: gray2pcolor(), makect(), ctpath()

% default
ctlen0 = 3;
forcefullrange = true;
uniform = true;
ctlen = 256;
cspace = 'lab';
interp = 'pchip';
slimit = 0.1;

if numel(varargin)>1
	for k = 1:2:numel(varargin)
		switch lower(varargin{k})
			case 'ncolors'
				ctlen = round(varargin{k+1});
			case 'nbreaks'
				ctlen0 = round(varargin{k+1});
			case 'fullrange'
				forcefullrange = varargin{k+1};
			case 'uniform'
				uniform = varargin{k+1};
			case 'cspace'
				cspace = varargin{k+1};
			case 'interp'
				interp = varargin{k+1};
			case 'minsat'
				slimit = imclamp(varargin{k+1});
			otherwise
				error('IM2CT: unknown option %s',lower(varargin{k}))
		end
	end
end

if size(inpict,3) ~= 3
	error('IM2CT: image must be RGB')
end

% image cannot be int16 if fed to rgb2ind()
% uint8 will suffice for these purposes
inpict = imcast(inpict,'uint8');

% get rid of low-saturation pixels
if slimit > 0
	[~,C,~] = splitchans(rgb2lch(inpict,'ypbpr'));
	mk = C > slimit*0.5339;
	inpict = inpict(repmat(mk,[1 1 3]));
	inpict = reshape(inpict,[],1,3);
	if isempty(inpict)
		error('IM2CT: There are no pixels within the specified saturation range')
	end
end

fullctlen0 = ctlen0 + 2*forcefullrange; % expected full length of CT0 after expansion
requestctlen0 = ctlen0; % the map length requested from rgb2ind()
thisctlen0 = 0; % the current map length
while thisctlen0 < fullctlen0
	% cluster image data
	[~,CT0] = rgb2ind(inpict,requestctlen0);
	ranoutofcolors = size(CT0,1) < requestctlen0;

	% pad with black, white
	if forcefullrange
		CT0 = [0 0 0; 1 1 1; CT0]; %#ok<AGROW>
	end

	% convert to the specified opponent color space
	CT0 = ctflop(lch2lab(rgb2lch(ctflop(CT0),cspace)));
	if ~strcmpi(cspace,'ypbpr')
		CT0(:,1) = CT0(:,1)/100;
	end

	% check for unique L; this also checks for unique rows; sort by L
	[~,idx,~] = unique(CT0(:,1),'sorted');
	CT0 = CT0(idx,:);

	% break if we ran out of colors
	if ranoutofcolors
		quietwarning('IM2CT: Ran out of unique colors.  CT will have fewer breakpoints than requested.')
		break; 
	end
	
	% otherwise, keep trying to get enough unique colors
	thisctlen0 = size(CT0,1); 
	if thisctlen0 < fullctlen0
		requestctlen0 = requestctlen0 + 1;
	end
	%[fullctlen0 thisctlen0 requestctlen0]
end

% set up L
if uniform
	% distribute everything uniformly on L
	L0 = linspace(CT0(1,1),CT0(end,1),size(CT0,1));
	% constrain breakpoints to sRGB gamut
	CT0(:,1) = L0;
	if ~strcmpi(cspace,'ypbpr')
		CT0(:,1) = CT0(:,1)*100;
	end
	CT0 = ctflop(lch2rgb(lab2lch(ctflop(CT0)),cspace,'truncatelch'));
	CT0 = ctflop(lch2lab(rgb2lch(ctflop(CT0),cspace)));
	if ~strcmpi(cspace,'ypbpr')
		CT0(:,1) = CT0(:,1)/100;
	end
else
	% preserve original cluster distribution in L-space
	L0 = CT0(:,1);
end

% interpolate to form a linear-L CT
% using a (potentially) non-pwl trajectory in chroma space
CT0 = CT0(:,2:3);
Lf = linspace(L0(1),L0(end),ctlen);
CT = interp1(L0,CT0,Lf,interp);
CT = [Lf.' CT];

% convert back to RGB
if ~strcmpi(cspace,'ypbpr')
	CT(:,1) = CT(:,1)*100;
end
CT = ctflop(lch2rgb(lab2lch(ctflop(CT)),cspace,'truncatelch'));






