function csview(varargin)
%   CSVIEW()
%   CSVIEW(SPACE, {OPTIONS})
%       Visualize the projection of sRGB gamut within various color spaces.
%       Optionally visualize the trajectory of out-of-gamut points
%       as would occur if data range is clamped on conversion from SPACE to sRGB
%       If called with no arguments, a GUI tool is opened to allow interactive use.
%
%       This tool is intended both for instructional visualization, but it is also
%       useful for generating gamut projections for tasks such as showing the 
%       distribution of a set of color points.
%
%   SPACE is one of the following:
%       'hsv'         Smith (1974)
%       'hsl'         Joblove & Greenberg (1978)
%       'hsi'         Kender (1976)
%       'yuv'         PAL video
%       'yiq'         NTSC video
%       'ydbdr'       SECAM video
%       'ypbpr'       component analog video
%       'ycbcr'       component digital video
%       'xyz'         CIEXYZ
%       'lab'         CIELAB
%       'luv'         CIELUV
%       'srlab'       SRLAB2
%       'oklab'       OKLAB
%       'lchab'       polar CIELAB
%       'lchuv'       polar CIELUV
%       'lchsr'       polar SRLAB2
%       'lchok'       polar OKLAB
%       'hsy'         chroma-normalized polar YPbPr
%       'huslab'      chroma-normalized polar CIELAB
%       'husluv'      chroma-normalized polar CIELUV
%       'hsy cyl'     cylindrical projection of HSY
%       'huslab cyl'  cylindrical projection of HuSLab
%       'husluv cyl'  cylindrical projection of HuSLuv
%
%       The 'hsy','huslab','husluv' modes are all projected in their parent space, 
%       whereas the 'cyl' variants are projected as cylinders akin to HSV/HSL.
%
%   Optional parameters include the following keys and key-value pairs:
%   'ax' followed by an axes handle allows the specification of the target axes (default gca)
%   'view' followed by a 2-element vector [AZ EL] sets the initial view (default [-37.5 30])
%   'lineweight' optionally specifies the weight of the lines defining the edge of
%       the projected RGB cube.  (default 1)
%   'linemode' optionally specifies the type of edge lines used (default 'gray')
%       'color' uses an inverse-color line for high contrast
%       'black', 'gray', and 'white' use solid color lines
%       'none' uses no edge lines
%   'faceres' optionally specifies the mesh size used on the gamut faces (default 50)
%   'alpha' parameter specifies face alpha of the surf objects (default 1)
%   'invert' key inverts the colormap for operation on inverted X displays. 
%       e.g. csview('lab','invert');
%   'cplane' optionally specifies the method used to represent the chroma plane when a test
%       point trajectory is displayed (default 'mesh')
%       'patch' uses a transparent patch.  This looks best, but it's slow in softwaregl.
%       'mesh' uses a neutral mesh object.  This is simply faster.
%   'testpoint' parameter defines a color point in SPACE.
%       To be followed by a 3-element vector ordered and scaled WRT the axes and range of SPACE. 
%       i.e. TESTPOINT = [20 100 0] and SPACE = 'lch' implies a location of L=20, C=100, H=0.
%
%       If specified, a plane will be drawn at the original elevation as a visual aid.
%       A trajectory will be drawn to indicate the result of post-conversion clipping of RGB values.
%
%       Note that in HSY and HuSL modes, the chroma normalization allows simple clamping 
%       before RGB conversion. Oversaturation has minimal effect on H and Y/L.
%
%       Compare the following example pairs:
%         LCHab versus HuSLab
%           csview('lchab','testpoint',[80 60 12]);
%           csview('huslab','testpoint',[12 200 80]);
%         LCHuv versus HuSLuv
%           csview('lchuv','testpoint',[80 101 12]);
%           csview('husluv','testpoint',[12 200 80]);
%         YPbPr versus HSY
%           csview('ypbpr','testpoint',[0.8 -0.14 0.43]);
%           csview('hsy','testpoint',[0 3 0.8]);
%
%   The cylindrical renderings of HSV, HSL, HSY, and HuSL are a bit crispy around the edges.  
%   The surface wrapping renders odd in OpenGL, and using 'painters' is very slow (for me). 
%
%   HWB is not included, as most of the surface of HWB maps directly to the neutral axis.
%   Rendering that won't even make sense unless it's misrepresented by turning it inside-out.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/csview.html


% can anything be done to improve shitty cylinder rendering?
% rearranging faces would help, but it's nice to preserve the RGB edges
% painters works (see code), but it's slooooow


% configuration parameters
menustrings = {	'hsv','hsl','hsi', ...
				'yuv','yiq','ypbpr','ycbcr','ydbdr', ...
				'ciexyz','cieluv','cielab','srlab2','oklab', ...
				'cieluv lch','cielab lch','srlab2 lch','oklab lch', ...
				'hsy','huslab','husluv', ...
				'hsy cylinder','huslab cylinder','husluv cylinder'};
bigtable = { % create as one big array for sake of compactness, readability, ease of maintenance
% csnames						slidaxlabel		plotaxlabel		slidrange					plotrange
'hsv',' ',						'H','S','V',	'','','V',		[0 360; 0 1.5; 0 1]			[-1.5 1.5; -1.5 1.5; 0 1];
'hsl',' ',						'H','S','L',	'','','L',		[0 360; 0 1.5; 0 1]			[-1.5 1.5; -1.5 1.5; 0 1];
'hsi',' ',						'H','S','I',	'','','I',		[0 360; 0 1.5; 0 1]			[-1.5 1.5; -1.5 1.5; 0 1];
'yuv',' ',						'Y','U','V',	'U','V','Y',	[0 1; -1 1; -1 1]			[-1 1; -1 1; 0 1];
'yiq',' ',						'Y','I','Q',	'I','Q','Y',	[0 1; -1 1; -1 1]			[-1 1; -1 1; 0 1];
'ypbpr','ypp',					'Y','Pb','Pr',	'Pb','Pr','Y',	[0 1; -1 1; -1 1]			[-1 1; -1 1; 0 1];
'ycbcr','ycc',					'Y','Cb','Cr',	'Cb','Cr','Y',	[0 1; 0 1; 0 1]*255			[0 1; 0 1; 0 1]*255;
'ydbdr','ydd',					'Y','Db','Dr',	'Db','Dr','Y',	[0 1; -2 2; -2 2]			[-2 2; -2 2; 0 1];
'xyz','ciexyz',					'X','Y','Z',	'X','Z','Y',	[-1.5 1.5; 0 1; -1.5 1.5]	[-1.5 1.5; -1.5 1.5; 0 1];
'luv','cieluv',					'L','U','V',	'U','V','L',	[0 100; -200 200; -200 200]	[-200 200; -200 200; 0 100];
'lab','cielab',					'L','A','B',	'A','B','L',	[0 100; -200 200; -200 200]	[-200 200; -200 200; 0 100];
'srlab','srlab2',				'L','A','B',	'A','B','L',	[0 100; -200 200; -200 200]	[-200 200; -200 200; 0 100];
'oklab',' ',					'L','A','B',	'A','B','L',	[0 100; -50 50; -50 50]		[-50 50; -50 50; 0 100];
'lchuv','cieluvlch',			'L','C','H',	'U','V','L',	[0 100; 0 100; 0 360]		[-200 200; -200 200; 0 100];
'lchab','cielablch',			'L','C','H',	'A','B','L',	[0 100; 0 200; 0 360]		[-200 200; -200 200; 0 100];
'lchsr','srlab2lch',			'L','C','H',	'A','B','L',	[0 100; 0 200; 0 360]		[-200 200; -200 200; 0 100];
'lchok','oklablch',				'L','C','H',	'A','B','L',	[0 100; 0 100; 0 360]		[-50 50; -50 50; 0 100];
'hsy',' ',						'H','S','Y',	'Pb','Pr','Y',	[0 360; 0 2; 0 1]			[-1 1; -1 1; 0 1];
'huslab',' ',					'H','S','L',	'A','B','L',	[0 360; 0 200; 0 100]		[-200 200; -200 200; 0 100];
'husluv',' ',					'H','S','L',	'U','V','L',	[0 360; 0 200; 0 100]		[-200 200; -200 200; 0 100];
'hsycyl','hsycylinder',			'H','S','Y',	'','','Y',		[0 360; 0 1.5; 0 1]			[-1.5 1.5; -1.5 1.5; 0 1];
'huslabcyl','huslabcylinder',	'H','S','L',	'','','L',		[0 360; 0 200; 0 100]		[-200 200; -200 200; 0 100];
'husluvcyl','husluvcylinder',	'H','S','L',	'','','L',		[0 360; 0 200; 0 100]		[-200 200; -200 200; 0 100];
};

% each csnames row is a list of aliases, first name preferred
% padding the array with spaces is fine; since spaces are stripped, nothing can match the padding
csnames = bigtable(:,1:2);
slidaxlabels = bigtable(:,3:5);
plotaxlabels = bigtable(:,6:8);
slidrange = bigtable(:,9);
plotrange = bigtable(:,10);

linemodestr = {'color','black','gray','white','none'};
linespec = {[0 0 0],[0.5 0.5 0.5],[1 1 1]}; % this is just for 'black','gray','white' modes
cplanestr = {'mesh','patch'}; % 'patch' (looks nicer) or 'mesh' (faster)

% defaults & shared vars
selectedcs = 10;
showpoint = 0;
testpoint = [0 0 0];
origpoint = [0 0 0];
falpha = 1;
linemode = 3;
lineweight = 1;
faceres = 50;
invert = false;
selectedcp = 1;

spc = '';
xyz = [];
polar = false;
denormalized = '';
targetax = [];
targetvw = [-37.5 30];

% start doing things
if nargin == 0
	% build GUI figure
	handles = struct([]);
	figuresetup();
	togglechsliders();
	setparam(handles.csmenu,[],'selectedcs',[]);
else
	% run without GUI tools
	processinputs();
	csselection();
	draweverything();
end


%% PROCESS INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processinputs()
	% fetch space name, sanitize, validate
	spc = lower(varargin{1});
	spc = spc(spc ~= ' ');
	[validcsname,idx] = ismember(spc,csnames);
	if ~validcsname
		error('CSVIEW: unknown colorspace name %s \n',spc)
	end
	selectedcs = mod(idx-1,size(csnames,1))+1;
	spc = csnames{selectedcs,1}; % convert to preferred name
	
	
	if numel(varargin)>1
		k = 2;
		while k <= numel(varargin)
			switch lower(varargin{k})
				case 'testpoint'
					testpoint = varargin{k+1};
					showpoint = true;
					k = k+2;
				case {'axes','ax','axis'}
					targetax = varargin{k+1};
					k = k+2;
				case 'view'
					targetvw = varargin{k+1};
					k = k+2;
				case 'invert'
					if numel(varargin)>k && (isnumeric(varargin{k+1}) || islogical(varargin{k+1}))
						invert = double(varargin{k+1});
						k = k+2;
					else
						invert = 1;
						k = k+1;
					end
				case 'alpha'
					falpha = varargin{k+1};
					k = k+2;
				case 'lineweight'
					lineweight = varargin{k+1};
					k = k+2;
				case 'linemode'
					[~,idx] = ismember(lower(varargin{k+1}),linemodestr);
					if ~isempty(idx)
						linemode = idx;
					else
						error('CSVIEW: unknown linemode %s',varargin{k+1})
					end
					k = k+2;
				case 'cplane'
					[~,idx] = ismember(lower(varargin{k+1}),cplanestr);
					if ~isempty(idx)
						selectedcp = idx;
					else
						error('CSVIEW: unknown chroma plane type %s',varargin{k+1})
					end
					k = k+2;
				case 'faceres'
					faceres = varargin{k+1};
					k = k+2;
				otherwise
					if ~isnumeric(varargin{k})
						error('CSVIEW: unknown input parameter name %s',varargin{k})
					end
			end
		end
	end
	
	if isempty(targetax)
		targetax = gca;
	end
end

%% MODE SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function csselection()

	% regular HSY, HuSL methods are visualized in their parent space
	% this is done by first converting them to said space
	% with the exception of point trajectories, the plotting is the same
	if strcmpi(spc,'hsy')
		denormalized = 'hsy';
		origpoint = testpoint;
		testpoint(2) = 1;
		limitpoint = torgb(ctflop(testpoint),spc);
		spc = 'ypbpr';
		limitpoint = fromrgb(limitpoint,spc);
		maxS = sqrt(limitpoint(2)^2+limitpoint(3)^2);
		testpoint(1) = testpoint(1)+108.6;
		PB = origpoint(2)*maxS*cos(testpoint(1)*pi/180);
		PR = origpoint(2)*maxS*sin(testpoint(1)*pi/180);
		Y = testpoint(3);
		testpoint = [Y PB PR];
	elseif strcmpi(spc,'huslab')
		denormalized = 'huslab';
		origpoint = testpoint;
		testpoint(2) = 100;
		limitpoint = torgb(ctflop(testpoint),spc);
		spc = 'lab';
		limitpoint = fromrgb(limitpoint,spc);
		maxS = sqrt(limitpoint(2)^2+limitpoint(3)^2);
		A = origpoint(2)*maxS*cos(testpoint(1)*pi/180)/100;
		B = origpoint(2)*maxS*sin(testpoint(1)*pi/180)/100;
		L = testpoint(3);
		testpoint = [L A B];
	elseif strcmpi(spc,'husluv')
		denormalized = 'husluv';
		origpoint = testpoint;
		testpoint(2) = 100;
		limitpoint = torgb(ctflop(testpoint),spc);
		spc = 'luv';
		limitpoint = fromrgb(limitpoint,spc);
		maxS = sqrt(limitpoint(2)^2+limitpoint(3)^2);
		U = origpoint(2)*maxS*cos(testpoint(1)*pi/180)/100;
		V = origpoint(2)*maxS*sin(testpoint(1)*pi/180)/100;
		L = testpoint(3);
		testpoint = [L U V];  
	end
	
	switch spc
		case {'hsv','hsl','hsi','hsycyl','huslabcyl','husluvcyl'}
			xyz = [1 2 3]; % map [H S V] axes to [TH R Z]
			polar = true;
		case {'lchab','lchsr','lchok','lchuv'}
			xyz = [3 2 1];
			polar = true;
		case {'ypbpr','ydbdr','yiq','yuv'}
			xyz = [2 3 1]; % map [Y Pb Pr] axes to [Z X Y]
			polar = false;
		case 'ycbcr'
			xyz = [2 3 1];
			polar = false;
		case 'xyz'
			xyz = [1 3 2]; % yes, it's actually [1 3 2]
			polar = false;
		case {'luv','lab','srlab','oklab'}
			xyz = [2 3 1];
			polar = false;
		otherwise
			% this shouldn't be possible since keys are matched
			error('CSVIEW: unsupported space type')
	end
end

%% CORE FIGURE CONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function draweverything()
	surfoptions = {'edgealpha',0,'facealpha',falpha, ...
	           'ambientstrength',0.4,'facecolor','flat'};
		   
	bk = ctflop([0 0 0]);
	wh = ctflop([1 1 1]);
	mg = ctflop([1 0 1]);
	rd = ctflop([1 0 0]);
	yl = ctflop([1 1 0]);
	gr = ctflop([0 1 0]);
	cy = ctflop([0 1 1]);
	bl = ctflop([0 0 1]);

	faceres = faceres([1 1]);
	
	% this improves cylinder rendering, but it's super slow
	%targetax.Parent.Renderer = 'Painters';

	f = faceresize(cat(1,cat(2,bk,rd),cat(2,gr,yl)),faceres); 
	fv = drawface(f,surfoptions);
	hold(targetax,'on');
	axis(targetax,'vis3d');
	drawedges(fv,f);

	f = faceresize(cat(1,cat(2,bk,gr),cat(2,bl,cy)),faceres); 
	fv = drawface(f,surfoptions);
	drawedges(fv,f);

	f = faceresize(cat(1,cat(2,bk,bl),cat(2,rd,mg)),faceres); 
	drawface(f,surfoptions);

	f = faceresize(cat(1,cat(2,wh,mg),cat(2,yl,rd)),faceres); 
	fv = drawface(f,surfoptions);
	drawedges(fv,f);

	f = faceresize(cat(1,cat(2,wh,yl),cat(2,cy,gr)),faceres); 
	drawface(f,surfoptions);

	f = faceresize(cat(1,cat(2,wh,cy),cat(2,mg,bl)),faceres); 
	fv = drawface(f,surfoptions);
	drawedges(fv,f);

	lv = [0 0 -0.1; 0 0 1.1]*plotrange{selectedcs}(3,2);
	line(targetax,lv(:,1),lv(:,2),lv(:,3),'color','b','linewidth',lineweight)
	line(targetax,lv(:,1),lv(:,2),lv(:,3),'color','y','linestyle','--','linewidth',lineweight)

	if showpoint
		addtrajectoryplot()
	end

	set(targetax,'projection','perspective','view',targetvw);
	daspect(targetax,[1,1,1])
	%if invert == 0
		%camlight(targetax) % lighting doesn't work if inverted
		% using lighting ruins color representation, but it helps reveal curvature
		% idk how useful this is
	%end
	grid(targetax,'on')
	hold(targetax,'off')
	rotate3d(targetax,'on')
	
	xlim(targetax,plotrange{selectedcs}(1,:))
	ylim(targetax,plotrange{selectedcs}(2,:))
	zlim(targetax,plotrange{selectedcs}(3,:))
	
	xlabel(targetax,plotaxlabels{selectedcs,1})
	ylabel(targetax,plotaxlabels{selectedcs,2})
	zlabel(targetax,plotaxlabels{selectedcs,3})
end

function face = faceresize(fkern,subdivs)
	face = imresizeFB(fkern,subdivs,'bilinear'); 	
	face = imclamp(face);
end

%% DRAW THINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function addtrajectoryplot()
	if strcmpi(denormalized,'hsy')
		RGBpoint = torgb(ctflop(origpoint),'hsy');
	elseif strcmpi(denormalized,'huslab')
		RGBpoint = torgb(ctflop(origpoint),'huslab');
	elseif strcmpi(denormalized,'husluv')
		RGBpoint = torgb(ctflop(origpoint),'husluv');
	else
		RGBpoint = torgb(ctflop(testpoint),spc);
	end
	RGBpoint = imclamp(RGBpoint);

	CSPpoint = ctflop(fromrgb(RGBpoint,spc));
	if polar
		A = CSPpoint(xyz(2)).*cos(CSPpoint(xyz(1))*pi/180);
		B = CSPpoint(xyz(2)).*sin(CSPpoint(xyz(1))*pi/180); 
		CSPpoint(xyz(1)) = A; CSPpoint(xyz(2)) = B;
	end
	CSPpoint = CSPpoint(xyz);

	if polar
		lv = [testpoint(xyz(2))*cos(testpoint(xyz(1))*pi/180) ...
			testpoint(xyz(2))*sin(testpoint(xyz(1))*pi/180) testpoint(xyz(3))]; 
	else
		lv = testpoint(xyz);
	end
	
	% shift so that projection follows neutral axis
	if strcmpi(spc,'ycbcr')
		lv = [lv; CSPpoint; 128 128 testpoint(xyz(3))];
	else
		lv = [lv; CSPpoint; 0 0 testpoint(xyz(3))];
	end

	line(targetax,lv([1 2],1),lv([1 2],2),lv([1 2],3),'color','b','linewidth',lineweight)
	line(targetax,lv([1 2],1),lv([1 2],2),lv([1 2],3),'color','y','linestyle','--','linewidth',lineweight)
	line(targetax,lv([1 3],1),lv([1 3],2),lv([1 3],3),'color','k','linestyle',':','linewidth',lineweight)
	plot3(targetax,lv(1,1),lv(1,2),lv(1,3),'b','marker','*','markersize',10,'linewidth',lineweight);
	plot3(targetax,lv(2,1),lv(2,2),lv(2,3),'y','marker','o','markersize',10,'linewidth',lineweight);

	XL = plotrange{selectedcs}(1,:);
	YL = plotrange{selectedcs}(2,:);
	switch cplanestr{selectedcp}
		case 'patch'
			% this looks better
			k = patch(targetax,[XL(2) XL(2), XL(1) XL(1)],[YL(1) YL(2) YL(2) YL(1)], [1 1 1 1],'facealpha',0.4);
			set(k,'zdata', [1 1 1 1]*testpoint(xyz(3))); % for some reason, it refuses to work directly as above (2009b)
		case 'mesh'
			% but this is faster, esp if stuck with softwaregl
			N = 15;
			hm = mesh(linspace(XL(1),XL(2),N),linspace(YL(1),YL(2),N).',repmat(testpoint(xyz(3)),N,N));
			hm.FaceAlpha = 0;
			hm.EdgeColor = [0.5 0.5 0.5];
	end
end

function fv = drawface(f,surfoptions)
	% f is the RGB image for this face
	% fv is the projected (e.g. LAB) image for this face (i.e. the coordinates)
    fv = fromrgb(f,spc);
	if polar
		A = fv(:,:,xyz(2)).*cos(fv(:,:,xyz(1))*pi/180);
		B = fv(:,:,xyz(2)).*sin(fv(:,:,xyz(1))*pi/180);
		fv(:,:,xyz(1)) = A;
		fv(:,:,xyz(2)) = B;
	end
	if invert; f = 1-f; end

	% this would look nicer with subtle edge alpha
	% but it ruins refresh rate and makes plot manipulation laggy
    surf(targetax,fv(:,:,xyz(1)),fv(:,:,xyz(2)),fv(:,:,xyz(3)),f,surfoptions{:}); 
end

function drawedges(fv,f)
	switch linemodestr{linemode}
		case 'color'
			% get border coordinates
			fvb{1} = repmat(fv(1,:,:),[2 1 1]);
			fvb{2} = repmat(fv(end,:,:),[2 1 1]);
			fvb{3} = repmat(fv(:,1,:),[1 2 1]);
			fvb{4} = repmat(fv(:,end,:),[1 2 1]);
			
			% border color 
			fb{1} = repmat(f(1,:,:),[2 1 1]); 
			fb{2} = repmat(f(end,:,:),[2 1 1]);
			fb{3} = repmat(f(:,1,:),[1 2 1]);
			fb{4} = repmat(f(:,end,:),[1 2 1]);
			
			for k = 1:4
				if invert
					drawcolorline(fvb{k},fb{k});
				else
					drawcolorline(fvb{k},1-fb{k});
				end
			end
		case {'black','gray','white'}
			tls = linespec{linemode-1};
			if invert; tls = 1-tls; end
			
			% get border coordinates
			fvb{1} = fv(1,:,:);
			fvb{2} = fv(end,:,:);
			fvb{3} = fv(:,1,:);
			fvb{4} = fv(:,end,:);
			
			for k = 1:4
				plot3(targetax,fvb{k}(:,:,xyz(1)),fvb{k}(:,:,xyz(2)),fvb{k}(:,:,xyz(3)), ...
					'color',tls,'linewidth',lineweight)
			end
		case 'none'
			% NOP
	end
end

function drawcolorline(fvb,fb)
    surf(targetax,fvb(:,:,xyz(1)),fvb(:,:,xyz(2)),fvb(:,:,xyz(3)),fb, ...
		'facecol','no','edgecol','interp','linewidth',lineweight);
end


%% CONVERT THINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = fromrgb(f,spc)
    switch spc
        case 'hsi'
            out = rgb2hsi(f);
		case 'hsl'
            out = rgb2hsl(f);
			H = out(:,:,1);
			H(isnan(H)) = 0;
			out(:,:,1) = H;
		case 'hsv'
			out = rgb2hsv(f);
			out(:,:,1) = out(:,:,1)*360;
        case {'hsy','hsycyl'}
            out = rgb2hsy(f);
			% this fixes the apparent distortion caused in the cylindrical projection
			% due to the forced mapping of undefined S at the neutral corners
			S = out(:,:,2);
			mk = abs(out(:,:,3))<0.001 | abs(out(:,:,3)-1)<0.001;
			S(mk) = 0;
			out(:,:,2) = S;
        case {'huslab','huslabcyl'}
            out = rgb2husl(f,'lab');
			% this fixes the apparent distortion caused in the cylindrical projection
			% due to the forced mapping of undefined S at the neutral corners
			S = out(:,:,2);
			mk = abs(out(:,:,3))<0.001 | abs(out(:,:,3)-100)<0.001;
			S(mk) = 0;
			out(:,:,2) = S;
        case {'husluv','husluvcyl'}
            out = rgb2husl(f,'luv'); 
			% this fixes the apparent distortion caused in the cylindrical projection
			% due to the forced mapping of undefined S at the neutral corners
			S = out(:,:,2);
			mk = abs(out(:,:,3))<0.001 | abs(out(:,:,3)-100)<0.001;
			S(mk) = 0;
			out(:,:,2) = S;
        case 'lchab'
            out = rgb2lch(f,'lab');
        case 'lchuv'
            out = rgb2lch(f,'luv');
        case 'srlab'
            out = rgb2lch(f,'srlab');   
            Hrad = out(:,:,3)*pi/180;
            out(:,:,3) = sin(Hrad).*out(:,:,2); % B
            out(:,:,2) = cos(Hrad).*out(:,:,2); % A
        case 'lchsr'
            out = rgb2lch(f,'srlab');  
		case 'oklab'
            out = rgb2lch(f,'oklab');   
            Hrad = out(:,:,3)*pi/180;
            out(:,:,3) = sin(Hrad).*out(:,:,2); % B
            out(:,:,2) = cos(Hrad).*out(:,:,2); % A
		case 'lab'
            out = rgb2lch(f,'lab');   
            Hrad = out(:,:,3)*pi/180;
            out(:,:,3) = sin(Hrad).*out(:,:,2); % B
            out(:,:,2) = cos(Hrad).*out(:,:,2); % A
		case 'luv'
            out = rgb2lch(f,'luv');   
            Hrad = out(:,:,3)*pi/180;
            out(:,:,3) = sin(Hrad).*out(:,:,2); % B
            out(:,:,2) = cos(Hrad).*out(:,:,2); % A
        case 'lchok'
            out = rgb2lch(f,'oklab');  
		case 'ycbcr'
			[A os] = gettfm('ycbcr');
			out = imappmat(f,A,os,'double','iptmode');
		case {'ypbpr','ydbdr','yuv','yiq'}
			out = imappmat(f,gettfm(spc));
		case 'xyz'
			A = [0.412456439089691 0.357576077643907 0.180437483266397; ...
				0.212672851405621 0.715152155287816 0.072174993306558; ...
				0.019333895582328 0.119192025881300 0.950304078536368];
			out = imappmat(rgb2linear(f),A);
		otherwise
			% this shouldn't ever happen
			error('CSVIEW: unknown colorspace %s',spc)
    end
end

function out = torgb(f,spc)
    switch lower(spc(spc ~= ' '))
        case 'hsi'
            out = hsi2rgb(f);
		case 'hsl'
            out = hsl2rgb(f);
		case 'hsv'
			f(:,:,1) = f(:,:,1)/360;
            out = hsv2rgb(f);
        case {'hsy','hsycyl'}
            out = hsy2rgb(f);
        case {'huslab','huslabcyl'}
            out = husl2rgb(f,'lab');
        case {'husluv','husluvcyl'}
            out = husl2rgb(f,'luv');
        case 'lchab'
            out = lch2rgb(f,'lab');
        case 'lchuv'
            out = lch2rgb(f,'luv');
        case 'lchsr'
            out = lch2rgb(f,'srlab');
        case 'srlab'
            L = f(:,:,1);
            Hrad = mod(atan2(f(:,:,3),f(:,:,2)),2*pi);
            H = Hrad*180/pi;
            C = sqrt(f(:,:,2).^2 + f(:,:,3).^2);
            out = lch2rgb(cat(3,L,C,H),'srlab');
		case 'lchok'
            out = lch2rgb(f,'oklab');
        case 'oklab'
            L = f(:,:,1);
            Hrad = mod(atan2(f(:,:,3),f(:,:,2)),2*pi);
            H = Hrad*180/pi;
            C = sqrt(f(:,:,2).^2 + f(:,:,3).^2);
            out = lch2rgb(cat(3,L,C,H),'oklab');
		case 'lab'
            L = f(:,:,1);
            Hrad = mod(atan2(f(:,:,3),f(:,:,2)),2*pi);
            H = Hrad*180/pi;
            C = sqrt(f(:,:,2).^2 + f(:,:,3).^2);
            out = lch2rgb(cat(3,L,C,H),'lab');
		case 'luv'
            L = f(:,:,1);
            Hrad = mod(atan2(f(:,:,3),f(:,:,2)),2*pi);
            H = Hrad*180/pi;
            C = sqrt(f(:,:,2).^2 + f(:,:,3).^2);
            out = lch2rgb(cat(3,L,C,H),'luv');
		case 'ycbcr'
			[A os] = gettfm('ycbcr');
			out = imappmat(f,inv(A),0,-os,'double','iptmode');
		case {'ypbpr','ydbdr','yuv','yiq'}
			out = imappmat(f,gettfm([spc '_inv']));
		case 'xyz'
			Ainv = [3.240454162114103 -1.537138512797715 -0.49853140955601; ...   
				-0.96926603050518 1.876010845446694 0.041556017530349; ...
				0.055643430959114 -0.20402591351675 1.057225188223179];
			out = linear2rgb(imappmat(f,Ainv));
        otherwise
            % this shouldn't ever happen
			error('CSVIEW: unknown colorspace %s',spc)
    end
end

%% FULL FIGURE SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figuresetup()
	% if there's already a figure, just close it
	% this shouldn't ever have to happen
	h = findall(0,'tag','csview');
	if ~isempty(h)
		close(h);
	end
	
	% the only way to have non-proportional elements in the UI is if a window-resize cbf exists
	% to rescale everything based on gcf geometry
	pw = 200; % side panel width (px)
	ph = 0.94; % main side panel height
	vm = 0.02; % vertical margin (within figure)
	hm = 0.01; % horizontal margin (within figure)
	evm = 0.01; % element vertical margin
	ehm = 0.05; % element horizontal margin
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','csview',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'Tag','csview');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	axespos = [2*hm 2*vm 1-pw-4*hm-evm 1-4*vm];
	axes(...
	'Parent',h1,...
	'Position',axespos,...
	'CameraPosition',[0.5 0.5 9.16025403784439],...
	'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
	'Color',get(0,'defaultaxesColor'),...
	'ColorOrder',get(0,'defaultaxesColorOrder'),...
	'XColor',get(0,'defaultaxesXColor'),...
	'XTick',0,...
	'XTickLabel',{  blanks(0) },...
	'XTickLabelMode','manual',...
	'XTickMode','manual',...
	'YColor',get(0,'defaultaxesYColor'),...
	'YTick',0,...
	'YTickLabel',{  blanks(0) },...
	'YTickLabelMode','manual',...
	'YTickMode','manual',...
	'view',targetvw, ...
	'ZColor',get(0,'defaultaxesZColor'),...
	'Tag','axes1',...
	'Visible','on');


	% SIDE PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mainpanel = uipanel(...
	'Parent',h1,...
	'Title','View Control',...
	'Tag','sidepanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm+evm pw ph]);

	eh = 0.026; % element height
	tsp = 0.93; % table start point
	
	sliderparams = {'Parent',mainpanel,...
					'Units','normalized',...
					'BackgroundColor',[0.9 0.9 0.9],...
					'Style','slider',...
					'tooltipstring','adjust test point location'};
	
	menuparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'Style','popupmenu'};
				
	textparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'FontSize',10,...
					'HorizontalAlignment','left',...
					'Style','text'};
				
	sllimparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'FontSize',8,...
					'HorizontalAlignment','left',...
					'Style','text'};
				
	sulimparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'FontSize',8,...
					'HorizontalAlignment','right',...
					'Style','text'};
				
	cboxparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'FontSize',10,...
					'Style','checkbox'};
				
	editparams = {	'Parent',mainpanel,...
					'Units','normalized',...
					'fontsize',8,...
					'BackgroundColor',[1 1 1],...
					'HorizontalAlignment','left',...
					'Style','edit'};
				
	Pmenu = repmat([ehm 0 1-2*ehm eh],[2 1]);
	Pmenu(:,2) = tsp - (0:1)*(evm+eh) - [0.5*eh 0];
			
	% CS menu
	uicontrol(textparams{:},...
	'Position',Pmenu(1,:),...
	'String','Color Space',...
	'Tag','popmenulabel');
	uicontrol(menuparams{:}, ...	
	'Position',Pmenu(2,:),...
	'String',menustrings,...
	'Value',selectedcs,...
	'Tag','csmenu',...
	'tooltipstring','Select the color model',...
	'callback',{@setparam,'selectedcs'});


	Ppoint = [ehm Pmenu(2,2)-(evm+eh)-2*evm 1-2*ehm eh];
	
	% point trajectory checkbox
	uicontrol(cboxparams{:},...
	'Position',Ppoint,...
	'String','Show point trajectory',...
	'value',showpoint,...
	'Tag','pointcheckbox',...
	'tooltipstring','show the trajectory of an OOG point', ...
	'callback',{@setparam,'pointenable'});


	% god what a mess
	Pslid = repmat([ehm 0 1-2*ehm eh],[9 1]);
	Pslid(:,2) = Ppoint(2) - [1 1 2 3 3 4 5 5 6]*(evm+eh) - repmat([0.25*eh 0 0],[1 3]);
	Pslid(:,2) = Pslid(:,2) - kron([1 2 3],[1 1 1]*2*evm)'; % space out blocks
	Pslid(2:3:9,3) = 0.3*Pslid(2:3:9,3); % hscale edit box
	Pslid(2:3:9,1) = Pslid(2:3:9,1) + (1/0.3 - 1)*Pslid(2:3:9,3); % hshift edit box
	Psllim = Pslid(3:3:9,:);
	Psllim(:,2) = Psllim(:,2)-eh;
	Psllim(:,3) = 0.5*Psllim(:,3);
	Psulim = Psllim;
	Psulim(:,1) = Psulim(:,1)+Psulim(:,3);

	% slider 1
	uicontrol(textparams{:},...
	'Position',Pslid(1,:),...
	'String','slider1',...
	'Tag','sliderlabel');
	uicontrol(editparams{:},...
	'Position',Pslid(2,:),...
	'String',testpoint(1),...
	'Tag','chvalbox',...
	'callback',{@setparam,'channelval',1});
	uicontrol(sliderparams{:},...	
	'Position',Pslid(3,:),...
	'Value',testpoint(1),...
	'Tag','chslider',...
	'callback',{@setparam,'channelslider',1});
	uicontrol(sllimparams{:},...
	'Position',Psllim(1,:),...
	'String','ll',...
	'Tag','sliderllim');
	uicontrol(sulimparams{:},...
	'Position',Psulim(1,:),...
	'String','ul',...
	'Tag','sliderulim');
	
	% slider 2
	uicontrol(textparams{:},...
	'Position',Pslid(4,:),...
	'String','slider2',...
	'Tag','sliderlabel');
	uicontrol(editparams{:},...
	'Position',Pslid(5,:),...
	'String',testpoint(2),...
	'Tag','chvalbox',...
	'callback',{@setparam,'channelval',2});
	uicontrol(sliderparams{:},...	
	'Position',Pslid(6,:),...
	'Value',testpoint(2),...
	'Tag','chslider',...
	'callback',{@setparam,'channelslider',2});
	uicontrol(sllimparams{:},...
	'Position',Psllim(2,:),...
	'String','ll',...
	'Tag','sliderllim');
	uicontrol(sulimparams{:},...
	'Position',Psulim(2,:),...
	'String','ul',...
	'Tag','sliderulim');
	
	% slider 3
	uicontrol(textparams{:},...
	'Position',Pslid(7,:),...
	'String','slider3',...
	'Tag','sliderlabel');
	uicontrol(editparams{:},...
	'Position',Pslid(8,:),...
	'String',testpoint(3),...
	'Tag','chvalbox',...
	'callback',{@setparam,'channelval',3});
	uicontrol(sliderparams{:},...	
	'Position',Pslid(9,:),...
	'Value',testpoint(3),...
	'Tag','chslider',...
	'callback',{@setparam,'channelslider',3});
	uicontrol(sllimparams{:},...
	'Position',Psllim(3,:),...
	'String','ll',...
	'Tag','sliderllim');
	uicontrol(sulimparams{:},...
	'Position',Psulim(3,:),...
	'String','ul',...
	'Tag','sliderulim');
	

	Pmenu = repmat([ehm 0 1-2*ehm eh],[2 1]);
	Pmenu(:,2) = Psulim(3,2)-(evm+eh) - (0:1)*(evm+eh) - [0.5*eh 0];
			
	% chroma plane menu
	uicontrol(textparams{:},...
	'Position',Pmenu(1,:),...
	'String','Chroma Plane Style',...
	'Tag','cpmenulabel');
	uicontrol(menuparams{:}, ...	
	'Position',Pmenu(2,:),...
	'String',cplanestr,...
	'Value',selectedcp,...
	'Tag','cpmenu',...
	'tooltipstring','Change the style of the plane from which the point is projected',...
	'callback',{@setparam,'selectedcp'});



	% start positioning from the bottom up

	Pinvcb = [ehm 0.03 1-2*ehm eh];
	% invert checkbox
	uicontrol(cboxparams{:},...
	'Position',Pinvcb,...
	'String','Invert Display',...
	'value',invert,...
	'Tag','invertcheckbox',...
	'tooltipstring','invert the display colors', ...
	'callback',{@setparam,'invert'});


	Plm = repmat([ehm Pinvcb(2)+evm 1-2*ehm eh],[2 1]);
	Plm(:,2) = Plm(:,2) + [1; 2].*(evm+eh) - [0; 0.25*eh];
	
	% linestyle menu
	uicontrol(textparams{:},...
	'Position',Plm(2,:),...
	'String','Edge Style',...
	'Tag','lmmenulabel');
	uicontrol(menuparams{:}, ...	
	'Position',Plm(1,:),...
	'String',linemodestr,...
	'Value',linemode,...
	'Tag','lmmenu',...
	'tooltipstring','specify edge line type',...
	'callback',{@setparam,'linemode'});


	Pslid = repmat([ehm Plm(2,2)+2*evm 1-2*ehm eh],[3 1]);
	Pslid(:,2) = Pslid(:,2) + [2;2;1]*(evm+eh) - [0.25*eh; 0; 0];
	Pslid(2,3) = 0.25*Pslid(2,3); % hscale edit box
	Pslid(2,1) = Pslid(2,1) + 3*Pslid(2,3); % hshift edit box

	% alpha slider
	uicontrol(textparams{:},...
	'Position',Pslid(1,:),...
	'String','Face Alpha',...
	'Tag','alphasliderlabel');
	uicontrol(editparams{:},...
	'Position',Pslid(2,:),...
	'String',falpha,...
	'Tag','falphabox',...
	'callback',{@setparam,'falphaval',4});
	uicontrol(sliderparams{:},...	
	'Position',Pslid(3,:),...
	'Value',falpha,...
	'Tag','alphaslider',...
	'callback',{@setparam,'falphaslider',4});
	
	
	% all child object handles in figure 
	handles = guihandles(h1);
	% these get catted in reverse order, so flip to avoid confusion
	handles.chslider = fliplr(handles.chslider);
	handles.chvalbox = fliplr(handles.chvalbox);
	handles.sliderlabel = fliplr(handles.sliderlabel);
	handles.sliderllim = fliplr(handles.sliderllim);
	handles.sliderulim = fliplr(handles.sliderulim);
end

%% GUI CBF & REDIRECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setparam(objh,~,param,idx)
	switch param	
		case 'selectedcs'
			selectedcs = get(objh,'value');
			resetsliders();
			
		case 'selectedcp'
			selectedcp = get(objh,'value');
			
		case 'linemode'
			linemode = get(objh,'value');
			
		case 'invert'
			invert = get(objh,'value');
			
		case 'pointenable'
			showpoint = get(objh,'value');
			togglechsliders()
			
		case 'channelval'
			testpoint(idx) = str2double(get(objh,'string'));
			updatesliders(idx)
			
		case 'channelslider'
			testpoint(idx) = get(objh,'value');
			updatesliders(idx)
			
		case 'falphaval'
			falpha = str2double(get(objh,'string'));
			falpha = imclamp(falpha);
			updatesliders(idx)
			
		case 'falphaslider'
			falpha = get(objh,'value');
			updatesliders(idx)
			
		otherwise
			error('this should never happen')
	end
	
	updateview()
end
		
function updateview()
	if showpoint
		csview(menustrings{selectedcs},'ax',handles.axes1,'alpha',falpha,'lineweight',lineweight, ...
			'cplane',cplanestr{selectedcp},'linemode',linemodestr(linemode), ...
			'testpoint',testpoint,'invert',invert,'view',handles.axes1.View)
	else
		csview(menustrings{selectedcs},'ax',handles.axes1,'alpha',falpha,'lineweight',lineweight, ...
				'linemode',linemodestr(linemode),'invert',invert,'view',handles.axes1.View)
	end
end

function togglechsliders()
	if showpoint
		for c = 1:3
			handles.chslider(c).Enable = 'on';
			handles.chvalbox(c).Enable = 'on';
			handles.sliderlabel(c).Enable = 'on';
			handles.sliderllim(c).Enable = 'on';
			handles.sliderulim(c).Enable = 'on';
		end
		handles.cpmenu.Enable = 'on';
		handles.cpmenulabel.Enable = 'on';
	else
		for c = 1:3
			handles.chslider(c).Enable = 'off';
			handles.chvalbox(c).Enable = 'off';
			handles.sliderlabel(c).Enable = 'off';
			handles.sliderllim(c).Enable = 'off';
			handles.sliderulim(c).Enable = 'off';
		end
		handles.cpmenu.Enable = 'off';
		handles.cpmenulabel.Enable = 'off';
	end
	
end

function updatesliders(idx)
	if idx < 4
		% clamp slider value
		slidv = imclamp(testpoint(idx),slidrange{selectedcs}(idx,:));
		handles.chslider(idx).Value = slidv;
		handles.chvalbox(idx).String = sprintf('%.2f',testpoint(idx));
	else
		handles.alphaslider.Value = falpha;
		handles.falphabox.String = sprintf('%.2f',falpha);
	end
end

function resetsliders()
	testpoint = [0 0 0];
	for c = 1:3
		handles.chslider(c).Min = slidrange{selectedcs}(c,1);
		handles.chslider(c).Max = slidrange{selectedcs}(c,2);
		handles.chslider(c).Value = 0;
		handles.chvalbox(c).String = '0';
		handles.sliderlabel(c).String = slidaxlabels{selectedcs,c};
		handles.sliderllim(c).String = sprintf('%.1f',slidrange{selectedcs}(c,1));
		handles.sliderulim(c).String = sprintf('%.1f',slidrange{selectedcs}(c,2));
	end
end



end % END MAIN SCOPE
