function outcolor = cpicktool(varargin)
%   CPICKTOOL({REFPOINT}, {OPTION})
%       opens a gui color picker capable of selection in various colorspaces.
%		default color models are RGB, HSL, HSYp, LCHab, and LCHok.
%
%   REFPOINT (optional) is an RGB triplet (3-element row vector [0 1])
%       when specified, the color picker will include markers indicating
%       the planes in which the reference color point resides
%   OPTION (optional) 
%       'allmodes' enables extra colorspaces.  Extra modes are: 
%         HSV, HSI, HSY, HuSL (LAB, OKLAB, LUV), HuSLp (LAB, OKLAB, LUV), 
%         and LCH (LUV & SRLAB2)
%       'invert' inverts the displayed colors
%	      this is only useful if using an inverted display
%
%   NOTE: when using HSI or LCH models, out-of-gamut points are rendered in black.
%       Picking an OOG point will result in chroma being truncated to locate
%		the nearest in-gamut point with the same L & H.
%
%   output is a RGB triplet formatted as a row vector of class double
%
%   See also: colorpicker


for k = 1:1:length(varargin);
    if isnumeric(varargin{k})
        refpoint = varargin{k};
    elseif ischar(varargin{k})
		switch lower(varargin{k})
			case 'invert'
				invert = 1;
			case 'allmodes'
				allmodes = 1;
		end
    end
end

if ~exist('refpoint','var') || numel(refpoint) ~= 3
	refpoint = NaN;
else
	if ~isnan(refpoint) 
		refpoint = max(min(refpoint,1),0);
	end
end
refpoint = ctflop(refpoint);


if ~exist('invert','var')
	invert = 0;
else
	invert = 1;
end

if ~exist('allmodes','var')
	allmodes = 0;
end

% ui data initialization
pts = 255;
p = 0:1/pts:1;
[xx yy] = meshgrid(p,p);
yy = flipud(yy);
zz = ones(size(yy));
x = 0; y = 0;
sx = 0; sy = 0;

if allmodes
	methodstrings = {'RGB','HSV','HSI','HSL','HSY','HuSL (LAB)','HuSL (LUV)','HuSL (OKLAB)','HSYp','HuSLp (LAB)','HuSLp (LUV)','HuSLp (OKLAB)','LCH (CIE LAB)','LCH (CIE LUV)','LCH (SRLAB2)','LCH (OKLAB)'};
	axisnames = {'RGB','HSV','HSI','HSL','HSY','HSL','HSL','HSL','HSY','HSL','HSL','HSL','LCH','LCH','LCH','LCH'};
	selectedspace = 4;
else
	methodstrings = {'RGB','HSL','HSYp','LCH (CIE LAB)','LCH (OKLAB)'};
	axisnames = {'RGB','HSL','HSY','LCH','LCH'};
	selectedspace = 2;
end

spacename = methodstrings{selectedspace};
samplergb = ctflop([0 0 0]); % the output rgb triplet
constrainedaxis = 1; % the constrained axis
gamutmsg = 'sample chroma is truncated';
lc = [1 1 1]; % reference marker color
la = 0.5; % reference marker alpha

handles = struct([]);
figuresetup();

% prepare the figure elements
radiohandles = [handles.radiobutton1 handles.radiobutton2 handles.radiobutton3];
set(handles.constrainedslider,'value',0.5);
set(radiohandles(constrainedaxis),'value',1);

colorspacemenu_CBF(handles.colorspacemenu,[]);

% maybe do:
% update slider position when changing axis order


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function figuresetup()
	% FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','cpicktool',...
	'NumberTitle','off',...
	'outerPosition',[0.48671875 0.3251953125 0.471875 0.455078125],...
	'HandleVisibility','callback',...
	'closerequestfcn',@applybutton_CBF,...
	'Tag','CPICKTOOL_GUI');

	% MAIN PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mainpanel = uipanel(...
	'Parent',h1,...
	'Title',blanks(0),...
	'Tag','mainpanel',...
	'Clipping','on',...
	'Position',[0.0281456953642384 0.0536480686695279 0.932119205298013 0.90343347639485]);

	h2 = axes(...
	'Parent',mainpanel,...
	'Position',[0.037567084078712 0.0446650124069478 0.449016100178891 0.9],...
	'CameraPosition',[0.5 0.5 9.16025403784439],...
	'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
	'Color',get(0,'defaultaxesColor'),...
	'ColorOrder',get(0,'defaultaxesColorOrder'),...
	'LooseInset',[0.154399205561073 0.117262905162065 0.112830188679245 0.0799519807923169],...
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
	'ZColor',get(0,'defaultaxesZColor'),...
	'nextplot','replace',...
	'Tag','axes1',...
	'Visible','on',...
	'buttondownfcn',@axes1_BDF);

	h29 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[0.572450805+0.02 0.0471464019851117 0.3953488372-0.02 0.101736972704715],...
	'String','Apply',...
	'TooltipString','accept this color',...
	'Tag','applybutton',...
	'callback',@applybutton_CBF);

	h14 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Position',[0.590339892665474 0.85856-0.03 0.359570661896243 0.054590570719603],...
	'String',methodstrings,...
	'Style','popupmenu',...
	'Value',selectedspace,...
	'Tag','colorspacemenu',...
	'callback',@colorspacemenu_CBF);

	h15 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[0.502683363148479 0.0446650124069478 0.037567084078712 0.9],...
	'String',{  'Slider' },...
	'sliderstep',[1/256 1/16],...
	'Style','slider',...
	'Value',1,...
	'Tag','constrainedslider',...
	'callback',@constrainedslider_CBF);

	h17 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[0.590339892665474 0.9330-0.02 0.3 0.032258064516129],...
	'String','Select Color Model',...
	'Style','text',...
	'Tag','menulabel');

	h19 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[0.592128801431127 0.709677419354839 0.3 0.032258064516129],...
	'String','Constrained Axis',...
	'Style','text',...
	'Tag','radiolabel');

	h20 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'fontweight','bold',...
	'HorizontalAlignment','center',...
	'Position',[0.57+0.005+0.01 0.45 0.38 0.04],...
	'foregroundcolor',[0 0 0],...
	'String',gamutmsg,...
	'visible','off',...
	'Style','text',...
	'Tag','gamutwarning');

	% RADIO BUTTON GROUP
	h5 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Callback',@radio_CBF,...
	'Position',[0.592128801431127 0.642679900744417 0.143112701252236 0.0421836228287841],...
	'String',{''},...
	'Style','radiobutton',...
	'Tag','radiobutton1' );

	h7 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Callback',@radio_CBF,...
	'Position',[0.592128801431127 0.593052109181141 0.143112701252236 0.0421836228287841],...
	'String',{''},...
	'Style','radiobutton',...
	'Tag','radiobutton2');

	h8 = uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Callback',@radio_CBF,...
	'Position',[0.592128801431127 0.543424317617866 0.143112701252236 0.0421836228287841],...
	'String',{''},...
	'Style','radiobutton',...
	'Tag','radiobutton3');

	% uicontrol stacking order behavior is changed in R2014b
	% but annotations cannot be children of uipanel objects in earlier versions 
	% (at least not in R2009b)
	if ifversion('<','R2014b') %verLessThan('matlab','8.4')
		% -- Code to run in MATLAB R2014a and earlier here --
		pnpos = get(mainpanel,'position');
		anpos = [0.5742397137+0.02 0.193548387096774 0.385-0.02 0.250620347394541];
		anpos(1:2) = pnpos(1:2)+anpos(1:2).*pnpos(3:4);
		anpos(3:4) = anpos(3:4).*pnpos(3:4);
		sampleblock = annotation(h1,'rectangle',anpos,'FaceColor',[0 0 0]);
		if ~isnan(refpoint)
			anpos(4) = anpos(4)/2;
			%anpos(2)=anpos(2)+anpos(4);
			if invert
				refblock = annotation(h1,'rectangle',anpos,'FaceColor',1-refpoint);
			else
				refblock = annotation(h1,'rectangle',anpos,'FaceColor',refpoint);
			end
		end
		
		% this only calculates extent for initial window size
		spos = get(h15,'position');
		rpyrange = [pnpos(2)+spos(2)*pnpos(4) pnpos(2)+spos(4)*pnpos(2)+spos(4)*pnpos(4)];
		rpyrange = mean(rpyrange)+[-0.5 0.5]*diff(rpyrange)*0.82;
		refpointer = annotation(h1,'arrow',[1.001 1]*0.54,[1 1]*max(rpyrange));
	else
		% -- Code to run in MATLAB R2014b and later here --
		anpos = [0.5742397137+0.02 0.193548387096774 0.385-0.02 0.250620347394541];
		sampleblock = annotation(mainpanel,'rectangle',anpos,'FaceColor',[0 0 0]);
		if ~isnan(refpoint)
			anpos(4) = anpos(4)/2;
			%anpos(2)=anpos(2)+anpos(4);
			if invert
				refblock = annotation(mainpanel,'rectangle',anpos,'FaceColor',1-refpoint);
			else
				refblock = annotation(mainpanel,'rectangle',anpos,'FaceColor',refpoint);
			end
		end
		
		% this only calculates extent for initial window size
		spos = get(h15,'position');
		rpyrange = [spos(2) spos(2)+spos(4)];
		rpyrange = mean(rpyrange)+[-0.5 0.5]*diff(rpyrange)*0.82;
		refpointer = annotation(mainpanel,'arrow',[1.001 1]*0.54,[1 1]*max(rpyrange));
	end
	
	
	

	% all child object handles in figure 
	handles = guihandles(h1);
	handles.sampleblock = sampleblock;
	handles.refpointer = refpointer;
	handles.rpyrange = rpyrange;
	guidata(h1,handles);
end

function colorspacemenu_CBF(objh,event)
	selectedspace = get(objh,'value');
	set(handles.radiobutton1,'string',axisnames{selectedspace}(1));
	set(handles.radiobutton2,'string',axisnames{selectedspace}(2));
	set(handles.radiobutton3,'string',axisnames{selectedspace}(3));
	updatepatch();
end

function radio_CBF(objh,event)
	set(radiohandles(radiohandles ~= objh),'value',0);
	constrainedaxis = find(objh == radiohandles);
	updatepatch();
	updatesample();
end

function constrainedslider_CBF(objh,event)
	updatepatch();
	updatesample();
end

function applybutton_CBF(objh,event)
	outcolor = ctflop(samplergb);
	delete(handles.CPICKTOOL_GUI);
end	

function axes1_BDF(objh,event)
	[sx sy] = ginput(1);
	sx = max(min((sx-1)/pts,1),0);
	sy = 1-max(min((sy-1)/pts,1),0);
	updatesample();
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function updatepatch()
	spacename = methodstrings{selectedspace};
	zee = get(handles.constrainedslider,'value');
	
	switch spacename
		case 'RGB'
			switch constrainedaxis
				case 1
					patch = cat(3,zz*zee,xx,yy);
				case 2
					patch = cat(3,xx,zz*zee,yy);
				case 3
					patch = cat(3,xx,yy,zz*zee);
			end
			
		case 'HSL'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,xx,yy);
				case 2
					patch = cat(3,360*yy,zz*zee,xx);
				case 3
					patch = cat(3,360*yy,xx,zz*zee);
			end
			patch = hsl2rgb(patch);
			
		case 'HSV'
			switch constrainedaxis
				case 1
					patch = cat(3,zz*zee,xx,yy);
				case 2
					patch = cat(3,yy,zz*zee,xx);
				case 3
					patch = cat(3,yy,xx,zz*zee);
			end
			patch = hsv2rgb(patch);
			
		case 'HSI'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,xx,yy);
				case 2
					patch = cat(3,360*yy,zz*zee,xx);
				case 3
					patch = cat(3,360*yy,xx,zz*zee);
			end
			patch = hsi2rgb(patch);
			m = (patch(:,:,1) > 1 | patch(:,:,2) > 1 | patch(:,:,3) > 1) | ...
				(patch(:,:,1) < 0 | patch(:,:,2) < 0 | patch(:,:,3) < 0);
			patch = replacepixels([0 0 0],patch,m);
			
		case 'HSY'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,xx,yy);
				case 2
					patch = cat(3,360*yy,zz*zee,xx);
				case 3
					patch = cat(3,360*yy,xx,zz*zee);
			end
			patch = hsy2rgb(patch,'normal');
			
		case 'HSYp'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,xx,yy);
				case 2
					patch = cat(3,360*yy,zz*zee,xx);
				case 3
					patch = cat(3,360*yy,xx,zz*zee);
			end
			patch = hsy2rgb(patch,'pastel');
			
		case 'HuSL (LAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'lab');
			
		case 'HuSL (OKLAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'oklab');
			
		case 'HuSL (LUV)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'luv');
			
		case 'HuSLp (LAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'labp');
			
		case 'HuSLp (OKLAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'oklabp');
			
		case 'HuSLp (LUV)'
			switch constrainedaxis
				case 1
					patch = cat(3,360*zz*zee,100*xx,100*yy);
				case 2
					patch = cat(3,360*yy,100*zz*zee,100*xx);
				case 3
					patch = cat(3,360*yy,100*xx,100*zz*zee);
			end
			patch = husl2rgb(patch,'luvp');
			
		case 'LCH (CIE LAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,100*zz*zee,134*xx,360*yy);
				case 2
					patch = cat(3,100*xx,134*zz*zee,360*yy);
				case 3
					patch = cat(3,100*yy,134*xx,360*zz*zee);
			end
			patch = lch2rgb(patch,'lab','notruncate');
			m = (patch(:,:,1) > 1 | patch(:,:,2) > 1 | patch(:,:,3) > 1) | ...
				(patch(:,:,1) < 0 | patch(:,:,2) < 0 | patch(:,:,3) < 0);
			patch = replacepixels([0 0 0],patch,m);
			
		case 'LCH (CIE LUV)'
			switch constrainedaxis
				case 1
					patch = cat(3,100*zz*zee,178*xx,360*yy);
				case 2
					patch = cat(3,100*xx,178*zz*zee,360*yy);
				case 3
					patch = cat(3,100*yy,178*xx,360*zz*zee);
			end
			patch = lch2rgb(patch,'luv','notruncate');
			m = (patch(:,:,1) > 1 | patch(:,:,2) > 1 | patch(:,:,3) > 1) | ...
				(patch(:,:,1) < 0 | patch(:,:,2) < 0 | patch(:,:,3) < 0);
			patch = replacepixels([0 0 0],patch,m);
						
		case 'LCH (SRLAB2)'
			switch constrainedaxis
				case 1
					patch = cat(3,100*zz*zee,103*xx,360*yy);
				case 2
					patch = cat(3,100*xx,103*zz*zee,360*yy);
				case 3
					patch = cat(3,100*yy,103*xx,360*zz*zee);
			end
			patch = lch2rgb(patch,'srlab','notruncate');
			m = (patch(:,:,1) > 1 | patch(:,:,2) > 1 | patch(:,:,3) > 1) | ...
				(patch(:,:,1) < 0 | patch(:,:,2) < 0 | patch(:,:,3) < 0);
			patch = replacepixels([0 0 0],patch,m);
			
		case 'LCH (OKLAB)'
			switch constrainedaxis
				case 1
					patch = cat(3,100*zz*zee,32.25*xx,360*yy);
				case 2
					patch = cat(3,100*xx,32.25*zz*zee,360*yy);
				case 3
					patch = cat(3,100*yy,32.25*xx,360*zz*zee);
			end
			patch = lch2rgb(patch,'oklab','notruncate');
			m = (patch(:,:,1) > 1 | patch(:,:,2) > 1 | patch(:,:,3) > 1) | ...
				(patch(:,:,1) < 0 | patch(:,:,2) < 0 | patch(:,:,3) < 0);
			patch = replacepixels([0 0 0],patch,m);
			
	end
	
	if invert
		patch = 1-patch;
	end
	
	h = imagesc(patch,'parent',handles.axes1);
	set(h,'buttondownfcn',@axes1_BDF)
	set(handles.axes1,'yticklabel',[],'xticklabel',[])
	
	drawreference();
end

function updatesample()
	spacename = methodstrings{selectedspace};
	zee = get(handles.constrainedslider,'value');
	warn = 0;
	
	switch spacename
		case 'RGB'
			switch constrainedaxis
				case 1
					samplergb = cat(3,zee,sx,sy);
				case 2
					samplergb = cat(3,sx,zee,sy);
				case 3
					samplergb = cat(3,sx,sy,zee);
			end
			
		case 'HSL'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,sx,sy);
				case 2
					samplergb = cat(3,360*sy,zee,sx);
				case 3
					samplergb = cat(3,360*sy,sx,zee);
			end
			samplergb = hsl2rgb(samplergb);
			
		case 'HSV'
			switch constrainedaxis
				case 1
					samplergb = cat(3,zee,sx,sy);
				case 2
					samplergb = cat(3,sy,zee,sx);
				case 3
					samplergb = cat(3,sy,sx,zee);
			end
			samplergb = hsv2rgb(samplergb);
			
		case 'HSI'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,sx,sy);
				case 2
					samplergb = cat(3,360*sy,zee,sx);
				case 3
					samplergb = cat(3,360*sy,sx,zee);
			end
			samplergb = hsi2rgb(samplergb);
			if any(samplergb > 1) || any(samplergb < 0)
				samplergb = imclamp(samplergb);
				warn = 1;
			end
			
		case 'HSY'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,sx,sy);
				case 2
					samplergb = cat(3,360*sy,zee,sx);
				case 3
					samplergb = cat(3,360*sy,sx,zee);
			end
			samplergb = hsy2rgb(samplergb,'normal');
			
		case 'HSYp'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,sx,sy);
				case 2
					samplergb = cat(3,360*sy,zee,sx);
				case 3
					samplergb = cat(3,360*sy,sx,zee);
			end
			samplergb = hsy2rgb(samplergb,'pastel');
			
		case 'HuSL (LAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'lab');
			
		case 'HuSL (OKLAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'oklab');
			
		case 'HuSL (LUV)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'luv');
			
		case 'HuSLp (LAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'labp');
			
		case 'HuSLp (OKLAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'oklabp');
			
		case 'HuSLp (LUV)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,360*zee,100*sx,100*sy);
				case 2
					samplergb = cat(3,360*sy,100*zee,100*sx);
				case 3
					samplergb = cat(3,360*sy,100*sx,100*zee);
			end
			samplergb = husl2rgb(samplergb,'luvp');
		
		case 'LCH (CIE LAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,100*zee,134*sx,360*sy);
				case 2
					samplergb = cat(3,100*sx,134*zee,360*sy);
				case 3
					samplergb = cat(3,100*sy,134*sx,360*zee);
			end
			testme = lch2rgb(samplergb,'lab','notruncate');
			if any(testme > 1) || any(testme < 0)
				samplergb = lch2rgb(samplergb,'lab','truncatelch');
				warn = 1;
			else
				samplergb = testme;
			end
			
		case 'LCH (CIE LUV)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,100*zee,178*sx,360*sy);
				case 2
					samplergb = cat(3,100*sx,178*zee,360*sy);
				case 3
					samplergb = cat(3,100*sy,178*sx,360*zee);
			end
			testme = lch2rgb(samplergb,'luv','notruncate');
			if any(testme > 1) || any(testme < 0)
				samplergb = lch2rgb(samplergb,'luv','truncatelch');
				warn = 1;
			else
				samplergb = testme;
			end
						
		case 'LCH (SRLAB2)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,100*zee,103*sx,360*sy);
				case 2
					samplergb = cat(3,100*sx,103*zee,360*sy);
				case 3
					samplergb = cat(3,100*sy,103*sx,360*zee);
			end
			testme = lch2rgb(samplergb,'srlab','notruncate');
			if any(testme > 1) || any(testme < 0)
				samplergb = lch2rgb(samplergb,'srlab','truncatelch');
				warn = 1;
			else
				samplergb = testme;
			end
			
		case 'LCH (OKLAB)'
			switch constrainedaxis
				case 1
					samplergb = cat(3,100*zee,32.25*sx,360*sy);
				case 2
					samplergb = cat(3,100*sx,32.25*zee,360*sy);
				case 3
					samplergb = cat(3,100*sy,32.25*sx,360*zee);
			end
			testme = lch2rgb(samplergb,'oklab','notruncate');
			if any(testme > 1) || any(testme < 0)
				samplergb = lch2rgb(samplergb,'oklab','truncatelch');
				warn = 1;
			else
				samplergb = testme;
			end
			
	end
	
	
	if invert
		swatch = 1-samplergb;
	else
		swatch = samplergb;
	end
	
	set(handles.sampleblock,'facecolor',swatch);
	
	if warn
		%set(handles.gamutwarning,'visible','on','foregroundcolor',1-swatch,'backgroundcolor',swatch)
		set(handles.gamutwarning,'visible','on')
	else
		set(handles.gamutwarning,'visible','off')
	end
end

function drawreference()
	if any(isnan(refpoint))
		set(handles.refpointer,'visible','off')
	else
		spacename = methodstrings{selectedspace};
		switch spacename
			case 'RGB'
				switch constrainedaxis
					case 1
						x = refpoint(2);
						y = refpoint(3);
						z = refpoint(1);
					case 2
						x = refpoint(1);
						y = refpoint(3);
						z = refpoint(2);
					case 3
						x = refpoint(1);
						y = refpoint(2);
						z = refpoint(3);
				end

			case 'HSL'
				convrefpoint = rgb2hsl(refpoint);
				switch constrainedaxis
					case 1
						x = convrefpoint(2);
						y = convrefpoint(3);
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3);
						z = convrefpoint(2);
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2);
						z = convrefpoint(3);
				end

			case 'HSV'
				convrefpoint = rgb2hsv(refpoint);
				switch constrainedaxis
					case 1
						x = convrefpoint(2);
						y = convrefpoint(3);
						z = convrefpoint(1);
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1);
						end
						x = convrefpoint(3);
						z = convrefpoint(2);
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1);
						end
						x = convrefpoint(2);
						z = convrefpoint(3);
				end

			case 'HSI'
				convrefpoint = rgb2hsi(refpoint);
				switch constrainedaxis
					case 1
						x = convrefpoint(2);
						y = convrefpoint(3);
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3);
						z = convrefpoint(2);
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2);
						z = convrefpoint(3);
				end
				
			case 'HSY'
				convrefpoint = rgb2hsy(refpoint,'normal');
				switch constrainedaxis
					case 1
						x = convrefpoint(2);
						y = convrefpoint(3);
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3);
						z = convrefpoint(2);
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2);
						z = convrefpoint(3);
				end

			case 'HSYp'
				convrefpoint = rgb2hsy(refpoint,'pastel');
				switch constrainedaxis
					case 1
						x = convrefpoint(2);
						y = convrefpoint(3);
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3);
						z = convrefpoint(2);
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2);
						z = convrefpoint(3);
				end

			case 'HuSL (LAB)'
				convrefpoint = rgb2husl(refpoint,'lab');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end
				
			case 'HuSL (OKLAB)'
				convrefpoint = rgb2husl(refpoint,'oklab');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end

			case 'HuSL (LUV)'
				convrefpoint = rgb2husl(refpoint,'luv');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end

			case 'HuSLp (LAB)'
				convrefpoint = rgb2husl(refpoint,'labp');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end
				
			case 'HuSLp (OKLAB)'
				convrefpoint = rgb2husl(refpoint,'oklabp');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end

			case 'HuSLp (LUV)'
				convrefpoint = rgb2husl(refpoint,'luvp');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/100;
						y = convrefpoint(3)/100;
						z = convrefpoint(1)/360;
					case 2
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(3)/100;
						z = convrefpoint(2)/100;
					case 3
						if diff(diff(refpoint)) == 0
							y = 0;% ignore hue of neutral colors
						else
							y = convrefpoint(1)/360;
						end
						x = convrefpoint(2)/100;
						z = convrefpoint(3)/100;
				end
				
			case 'LCH (CIE LAB)'
				convrefpoint = rgb2lch(refpoint,'lab');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/134;
						y = convrefpoint(3)/360;
						z = convrefpoint(1)/100;
					case 2
						x = convrefpoint(1)/100;
						y = convrefpoint(3)/360;
						z = convrefpoint(2)/134;
					case 3
						y = convrefpoint(1)/100;
						x = convrefpoint(2)/134;
						z = convrefpoint(3)/360;
				end

			case 'LCH (CIE LUV)'
				convrefpoint = rgb2lch(refpoint,'luv');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/178;
						y = convrefpoint(3)/360;
						z = convrefpoint(1)/100;
					case 2
						x = convrefpoint(1)/100;
						y = convrefpoint(3)/360;
						z = convrefpoint(2)/178;
					case 3
						y = convrefpoint(1)/100;
						x = convrefpoint(2)/178;
						z = convrefpoint(3)/360;
				end

			case 'LCH (SRLAB2)'
				convrefpoint = rgb2lch(refpoint,'srlab');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/103;
						y = convrefpoint(3)/360;
						z = convrefpoint(1)/100;
					case 2
						x = convrefpoint(1)/100;
						y = convrefpoint(3)/360;
						z = convrefpoint(2)/103;
					case 3
						y = convrefpoint(1)/100;
						x = convrefpoint(2)/103;
						z = convrefpoint(3)/360;
				end
				
			case 'LCH (OKLAB)'
				convrefpoint = rgb2lch(refpoint,'oklab');
				switch constrainedaxis
					case 1
						x = convrefpoint(2)/32.25;
						y = convrefpoint(3)/360;
						z = convrefpoint(1)/100;
					case 2
						x = convrefpoint(1)/100;
						y = convrefpoint(3)/360;
						z = convrefpoint(2)/32.25;
					case 3
						y = convrefpoint(1)/100;
						x = convrefpoint(2)/32.25;
						z = convrefpoint(3)/360;
				end
		end
		
		h(1) = patch([0 1]*pts,(1-y)*[1 1]*pts,'k','parent',handles.axes1);
		h(2) = patch(x*[1 1]*pts,[0 1]*pts,'k','parent',handles.axes1);
		
		if invert
			lca = 1-lc;
		else
			lca = lc;
		end
		
		set(h,'edgecolor',lca,'edgealpha',la,'linestyle',':','parent',handles.axes1)
		if isnan(z)
			set(handles.refpointer,'visible','off')
		else
			set(handles.refpointer,'visible','on')
			set(handles.refpointer,'y',[1 1]*(handles.rpyrange(1)+diff(handles.rpyrange)*z))
		end
		set(handles.refpointer,'color',[1 1 1]*0.3)
	end
end



waitfor(handles.CPICKTOOL_GUI); 

% end main function block
end



