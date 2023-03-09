function immask(varargin)
%   IMMASK({INPICT} {KEYS})
%       Opens a simple gui for interactive creation of binary masks from image data.
%       
%       Currently, only the following methods are implemented:
%           Color selection by mouse click:
%              Supports local (magic wand) or global selection behavior
%              Supports parametric matching in various colorspaces
%              Matches either by euclidean distance or axial range
%              Shift-click to add to selection
%              Ctrl-click to subtract from selection
%              Shift+Ctrl-click for intersection with selection
%           Region selection:
%              Supports IPT regions (polygon, rectangle, freehand, ellipse)
%              Supports boolean operation
%
%       Selections can be modified:
%           Morphological operations with disk structuring element:
%              (open, close, dilate, erode)
%           Despeckle
%              Eliminates connected groups smaller than N pixels
%           Soften
%              Smooth edges by using a thresholded blur filter
%
%       Supports I/IA and RGB/RGBA images of any standard image class.
%       Output class is logical.
%
%       Optionally, an image can be included as an argument when launching the GUI.  
%       Using numeric inputs will load the images, but the text box will remain empty.
%           e.g. immask(ThisImage)
%       To populate the corresponding text box, the input must be in the form of a string.
%           e.g. immask('ThisImage')
%
%       Also accepts the key string 'invert', which inverts displayed images
%       This is only useful if you run Matlab on an inverted display.
%       
%   Tested on R2009b and R2015b (in Linux).  If it doesn't work in a different environment
%   don't be too terribly surprised.  It's still a [lot] half-baked at the moment anyway.
%
%   Doesn't require IP Toolbox to run, but dependent features will be disabled.
%
%   See also: IMCOMPOSE, IMGENERATE, IMMODIFY, IMCOMPARE.

% TO DO:
% akzoom throws errors if scrolling while clicked in R2015b
% probably has a button callback overwritten during selection (oh well)
% actual mouse users are probably less likely to do that
%
% what about macs ctrl/command modifiers? everything will probably break.
%
% implement small-component suppression for global color selection
% using histc is 150x faster for large images (quadratic gains vs original)
%
% other selection modes:
% antialiasing & nonbinary masking
% fix panel width


% implement singleton behavior
h = findall(0,'tag','IMMASK_GUI');
if ~isempty(h)
	% raise window if already open
	figure(h);
else
	% ui data initialization
	s = [];
	numchans = [];
	hasalpha = 0;
	imageA = [];
	maskA = [];
	undostack = [];
	undoindex = 1;
	
	csstrings = {'RGB','HSV','HSI','HSL','LCH (Polar YPbPr)','LCH (CIE LAB)','LCH (CIE LUV)','LCH (SRLAB2)','LCH (OKLAB)','YPbPr','LAB','LUV','SRLAB2','OKLAB'};
	axisnames = {'RGB','HSV','HSI','HSL','LCH','LCH','LCH','LCH','LCH','YBR','LAB','LUV','LAB','LAB'};
	
	imagetoshow = [];
	csimg = [];
	thiscs = 6;
	localcomponent = 1;
	volumestrings = {'ellipsoid','box'};
	thisvol = 1;
	csaxval = [1 1 1 1];
	defaxval = 0.1;
	mostrings = {'despeckle','soften','open','close','dilate','erode'};
	thismo = 2;
	serad = 1;
	minsegsize = 5;
	roibmstrings = {'replace','add','subtract','intersection'};
	thisroiboolmode = 1;
	roitypestrings = {'freehand','polygon','rectangle','ellipse'};
	thisroitype = 1;
	
	invertdisplay = 0;
	modkey = 'normal';
	onaxes = [0 0];
	onimg = [0 0];

	% prepare the figure elements
	handles = struct([]);
	figuresetup();
	toggleimagecontrols('off')
	hideIPTdependent();
	managemorphmenuvis();
	parseinputs();	
end

%% DO STARTUP STUFF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ccn = [1 0 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 1 1 0 0 0 0 0 0; ...
	 0 0 1 1 1 1 1 0; ...
	 0 0 1 2 2 2 2 1];	

ccp = [1 0 0 0 1 2 1 0; ...
	 2 1 0 1 1 2 1 1; ...
	 2 1 0 2 2 2 2 2; ...
	 2 1 0 1 1 2 1 1; ...
	 2 1 0 0 1 2 1 0; ...
	 1 1 0 0 0 0 0 0; ...
	 0 0 1 1 1 1 1 0; ...
	 0 0 1 2 2 2 2 1];			

ccm = [1 0 0 0 0 0 0 0; ...
	 2 1 0 1 1 1 1 1; ...
	 2 1 0 2 2 2 2 2; ...
	 2 1 0 1 1 1 1 1; ...
	 2 1 0 0 0 0 0 0; ...
	 1 1 0 0 0 0 0 0; ...
	 0 0 1 1 1 1 1 0; ...
	 0 0 1 2 2 2 2 1];		
 
cci = [1 0 0 1 1 1 1 1; ...
	 2 1 0 1 2 2 2 1; ...
	 2 1 0 1 2 1 2 1; ...
	 2 1 0 1 2 1 2 1; ...
	 2 1 0 1 2 1 2 1; ...
	 1 1 0 0 0 0 0 0; ...
	 0 0 1 1 1 1 1 0; ...
	 0 0 1 2 2 2 2 1];	

cursornorm = [fliplr(ccn) ccn];
cursorgrow = [fliplr(ccn) ccp; flipud(cursornorm)];
cursorshrink = [fliplr(ccn) ccm; flipud(cursornorm)];
cursorintersect = [fliplr(ccn) cci; flipud(cursornorm)];
cursornorm = [cursornorm; flipud(cursornorm)];
cursornorm(cursornorm == 0) = NaN;
cursorgrow(cursorgrow == 0) = NaN;
cursorshrink(cursorshrink == 0) = NaN;
cursorintersect(cursorintersect == 0) = NaN;

function parseinputs()
	numimages = 0;
	
	for a = 1:1:length(varargin)
		if ischar(varargin{a}) && strcmpi(varargin{a},'invert')
			invertdisplay = 1;
			set(handles.invertcheckbox,'value',invertdisplay)
			updatefig(1);
			updatefig(2);
			continue;
		end
		
		% these delays work around onresize() getting triggered when window spawns
		if numimages == 0
			if ischar(varargin{a})
				set(handles.importvarbox,'string',varargin{a})
				pause(0.2)
				importimage(handles.importvarbox,[],'A');
			else
				pause(0.2)
				importimage(handles.importvarbox,[],'Anumeric',varargin{a});
			end
			numimages = 1;
		end
	end

end

function figuresetup()
	% the only way to have non-proportional elements in the UI is if a window-resize cbf exists
	% to rescale everything based on gcf geometry
	pw = 180; % side panel width (px)
	ph = 0.76; % main side panel height
	vph = 0.07; % view controls panel height
	vm = 0.02; % vertical margin
	hm = 0.01; % horizontal margin
	em = 0.01; % element margin
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','immask_gui',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'resizefcn',@onresize,...
	'Tag','IMMASK_GUI');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	axw = (1-pw-2*hm-2*em)/2;
	
	axes(...
	'Parent',h1,...
	'Position',[hm vm axw 1-2*vm],...
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
	'ZColor',get(0,'defaultaxesZColor'),...
	'Tag','axes1',...
	'Visible','on');

	axes(...
	'Parent',h1,...
	'Position',[hm+axw+em vm axw 1-2*vm],...
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
	'ZColor',get(0,'defaultaxesZColor'),...
	'Tag','axes2',...
	'Visible','on');


	% TOP PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	toppanel = uipanel(...
	'Parent',h1,...
	'Title',blanks(0),...
	'Tag','toppanel',...
	'Clipping','on',...
	'Position',[1-hm-pw ph+vph+vm+2*em pw 1-2*vm-2*em-vph-ph]);

	eh = 0.18;
	
	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em 0.55+eh 1-2*em eh],...
	'String','Import Image',...
	'Style','text',...
	'Tag','text7');

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em 0.55 1-2*em eh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','name of image in workspace to import',...
	'callback',{@importimage,'A'},...
	'Tag','importvarbox');

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em 0.1+eh 1-2*em eh],...
	'String','Export Mask',...
	'Style','text',...
	'Tag','text7');

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em 0.1 1-2*em eh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','name of exported mask',...
	'callback',{@exportimage},...
	'Tag','exportvarbox');

	% EDITOR PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h13 = uipanel(...
	'Parent',h1,...
	'Title','Edit Selection',...
	'Tag','editorpanel',...
	'Clipping','on',...
	'visible','off',...
	'Position',[1-hm-pw vm+vph+em pw ph]);
	
	dpl = uipanel(...
	'Parent',h1,...
	'Title','Empty Project',...
	'Tag','dummyeditorpanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm+vph+em pw ph]);

	uicontrol(...
	'Parent',dpl,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.0602409638554217 0.2 0.897590361445783 0.6],...
	'String','Import layers from the workspace to begin.',...
	'Style','text',...
	'Tag','dummylabel');

	scalefactor = 0.88;
	chm = 0.05;
	cvm = 0.01*scalefactor;
	lh = 0.03*scalefactor;
	bh = 0.04*scalefactor;

	p1 = [chm 1-cvm-2*bh 1-2*chm bh];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1+[0 0 0 bh],...
	'style','togglebutton',...
	'String','Start Color Selection',...
	'TooltipString','Select points from image',...
	'Tag','selectbutton',...
	'callback',{@selectpoints,'on'});

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',p1,...
	'String','Local Component Only',...
	'Style','checkbox',...
	'TooltipString',['<html>Changes which matched points are selected <br/>' ...
		'When enabled, this mimics ''magic wand'' behavior</html>'],...
	'value',localcomponent,...
	'Tag','localcomponentcheckbox',...
	'callback',{@setparam,'localcomponent'});

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',p1,...
	'String',volumestrings,...
	'Style','popupmenu',...
	'Value',thisvol,...
	'tooltipstring',['<html>Changes method used for matching color points <br/>' ...
		'''ellipsoid'' performs an axially-weighted euclidean distance match <br/>' ...
		'''box'' performs a simple range match and may be more useful for matching along a single axis</html>'],...
	'Tag','volmenu',...
	'callback',{@setparam,'thisvol'});
	
	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',p1,...
	'String',csstrings,...
	'Style','popupmenu',...
	'Value',thiscs,...
	'TooltipString',['<html>Select the color space to match within</html>'],...
	'Tag','csmenu',...
	'callback',{@setparam,'colorspace'});

	toltt = 'Adjust axial tolerance of selection';
	
	p1 = p1-[0 2*cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1,...
	'String','',...
	'Style','checkbox',...
	'TooltipString','<html>uncheck to ignore this axis</html>',...
	'value',1,...
	'Tag','csaxcheck',...
	'callback',{@disableaxis,1});
	p1 = p1-[0 bh 0 0];
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[p1(1:3) bh],...
	'Style','slider',...
	'Value',csaxval(1),...
	'tooltipstring',toltt,...
	'Tag','csaxvalslider',...
	'callback',{@setparam,'csaxval',1});

	p1 = p1-[0 2*cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1,...
	'String','',...
	'Style','checkbox',...
	'TooltipString','<html>uncheck to ignore this axis</html>',...
	'value',1,...
	'Tag','csaxcheck',...
	'callback',{@disableaxis,2});
	p1 = p1-[0 bh 0 0];
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[p1(1:3) bh],...
	'Style','slider',...
	'Value',csaxval(2),...
	'tooltipstring',toltt,...
	'Tag','csaxvalslider',...
	'callback',{@setparam,'csaxval',2});

	p1 = p1-[0 2*cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1,...
	'String','',...
	'Style','checkbox',...
	'TooltipString','<html>uncheck to ignore this axis</html>',...
	'value',1,...
	'Tag','csaxcheck',...
	'callback',{@disableaxis,3});
	p1 = p1-[0 bh 0 0];
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[p1(1:3) bh],...
	'Style','slider',...
	'Value',csaxval(3),...
	'tooltipstring',toltt,...
	'Tag','csaxvalslider',...
	'callback',{@setparam,'csaxval',3});

	p1 = p1-[0 2*cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1,...
	'String','',...
	'Style','checkbox',...
	'TooltipString','<html>uncheck to ignore this axis</html>',...
	'value',1,...
	'Tag','csaxcheck',...
	'callback',{@disableaxis,4});
	p1 = p1-[0 bh 0 0];
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[p1(1:3) bh],...
	'Style','slider',...
	'Value',csaxval(4),...
	'tooltipstring',toltt,...
	'Tag','csaxvalslider',...
	'callback',{@setparam,'csaxval',4});

	% ROIpoly test
	p1 = p1-[0 3*cvm+2*bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1+[0 0 0 bh],...
	'style','togglebutton',...
	'String','Start Manual Selection',...
	'TooltipString','Define a closed selection with the mouse',...
	'Tag','roipolybutton',...
	'callback',@beginpolyselection);

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',p1,...
	'String',roitypestrings,...
	'Style','popupmenu',...
	'Value',thisroitype,...
	'Tag','roitypemenu',...
	'callback',{@setparam,'roitype'});

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',p1,...
	'String',roibmstrings,...
	'Style','popupmenu',...
	'Value',thisroiboolmode,...
	'Tag','roiboolmenu',...
	'callback',{@setparam,'roiboolmode'});

	% morphological ops
	p1 = p1-[0 3*cvm+2*bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',p1+[0 0 0 bh],...
	'String','Apply Operation',...
	'TooltipString','Perform an enhancement operation on current selection',...
	'Tag','morphbutton',...
	'callback',@morphmask);

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',p1,...
	'String',mostrings,...
	'Style','popupmenu',...
	'TooltipString',['<html>Despeckle: eliminates connected groups or holes smaller than N pixels <br/>' ...
		'Soften: perform blur and thresholding to smooth edges <br/>',...
		'See IPT documentation for morphological operations</html>'],...
	'Value',thismo,...
	'Tag','momenu',...
	'callback',{@setparam,'morphop'});

	p1 = p1-[0 cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[0.522 p1(2) 0.355 bh],...
	'String',num2str(serad),...
	'Style','edit',...
	'TooltipString','structuring element radius (integer)',...
	'Tag','seradbox',...
	'callback',{@setparam,'serad'});
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[0.11 p1(2) 0.355 lh],...
	'String','Radius',...
	'Style','text',...
	'Tag','seradlabel');

	% INVERT/CLEAR
	p1 = p1-[0 3*cvm+bh 0 0];
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[chm p1(2) (1-2*chm)/2 bh],...
	'String','Invert',...
	'TooltipString','Invert the current selection',...
	'Tag','invertbutton',...
	'callback',{@modifymask,'invert'});
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[chm+(1-2*chm)/2 p1(2) (1-2*chm)/2 bh],...
	'String','Clear',...
	'TooltipString','Clear the current selection',...
	'Tag','invertbutton',...
	'callback',{@modifymask,'clear'});




	% VIEW CONTROLS PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	vcp = uipanel(...
	'Parent',h1,...
	'Title','',...
	'Tag','viewcontrolpanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm pw vph]);

	bh = 0.30; % button height
	cvm = 0.14;
	
	% undo/redo
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[chm 2*cvm+bh (1-2*chm)/2 bh],...
	'String','UNDO',...
	'TooltipString','undo the last change to the mask',...
	'Tag','undobutton',...
	'callback',{@undoredo,'undo'});
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[chm+(1-2*chm)/2 2*cvm+bh (1-2*chm)/2 bh],...
	'String','REDO',...
	'TooltipString','undo a reversion',...
	'Tag','redobutton',...
	'callback',{@undoredo,'redo'});

	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 cvm 0.8 bh],...
	'String','Invert Display',...
	'Style','checkbox',...
	'TooltipString','Use this if using Matlab on an inverted X display.',...
	'Tag','invertcheckbox',...
	'callback',{@viewcontrol,'invert'});




	% all child object handles in figure 
	handles = guihandles(h1);
	handles.csaxvalslider = fliplr(handles.csaxvalslider);
	handles.csaxcheck = fliplr(handles.csaxcheck);
end

%% VIEW CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function viewcontrol(hobj,event,whichop)
	% this used to do other things too
	if strcmp(whichop,'invert')
		invertdisplay = get(hobj,'value');
	end
	updatefig(1);
	updatefig(2);
end

function k = safeimshow(imtoshow,h)
	if hasipt()
		% IF IPT IS INSTALLED
		k = imshow(imtoshow,'border','tight','parent',h);
	else
		% IPT NOT INSTALLED
		if size(imtoshow,3) == 1
			imtoshow = repmat(imtoshow,[1 1 3]);
		end
		k = image(imtoshow,'parent',h);
		axis(h,'off','tight','image')
	end
	
	% axes mode is 'replace' so that imshow-tight works correctly
	% this means we lose access to the parent by tag after the first 
	% image is placed and need to find it via the image object itself
	set(k,'tag','axes1')
	
	set(h,'units','pixels');
	axpos = get(h,'position');
	set(h,'units','normalized');
	
	axaspect = axpos(3)/axpos(4);
	ze = [get(h,'ylim'); get(h,'xlim')];
	zeaspect = abs(ze(2,1)-ze(2,2))/abs(ze(1,1)-ze(1,2));
	
	center = mean(ze,2);
	if zeaspect < axaspect 
		% if viewport is taller & skinnier than axes
		w = abs(ze(2,1)-ze(2,2))/zeaspect*axaspect;
		newlimit = [center(2)-(w/2) center(2)+(w/2)];
		set(h,'xlim',newlimit)
	else
		% if viewport is shorter & fatter than axes
		w = abs(ze(1,1)-ze(1,2))/axaspect*zeaspect;
		newlimit = [center(1)-(w/2) center(1)+(w/2)];
		set(h,'ylim',newlimit)
	end
end

function onresize(~,~)
	updatefig(1);
	updatefig(2);
end

%% TOGGLE ELEMENT VISIBILITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleimagecontrols(state)
	if strcmp(state,'on'); notstate = 'off'; 
	elseif strcmp(state,'off'); notstate = 'on'; end

	set(handles.dummyeditorpanel,'visible',notstate)
	set(handles.editorpanel,'visible',state)
end

function disableaxis(hobj,~,whichaxis)
	state = get(hobj,'value');
	if state; enable = 'on'; else enable = 'off'; end
	set(handles.csaxvalslider(whichaxis),'enable',enable)
end

function managemorphmenuvis()
	tm = mostrings{thismo};
	switch tm
		case 'despeckle'
			set(handles.seradbox,'tooltipstring','minimum size of connected groups (pixels)')
			set(handles.seradbox,'string',num2str(minsegsize))
			set(handles.seradbox,'callback',{@setparam,'minsegsize'})
			set(handles.seradlabel,'string','Min Size')
		case 'soften'
			set(handles.seradbox,'tooltipstring','blur kernel radius (pixels)')
			set(handles.seradbox,'string',num2str(serad))
			set(handles.seradbox,'callback',{@setparam,'serad'})
			set(handles.seradlabel,'string','Radius')
		otherwise
			set(handles.seradbox,'tooltipstring','structuring element radius (pixels)')
			set(handles.seradbox,'string',num2str(serad))
			set(handles.seradbox,'callback',{@setparam,'serad'})
			set(handles.seradlabel,'string','Radius')
	end
end

function hideIPTdependent()
	if ~hasipt()
		% IF IPT IS NOT INSTALLED
		disp('IMMASK: Image Processing Toolbox not found.  Some features are disabled.')
		set(handles.roiboolmenu,'visible','off')
		set(handles.roitypemenu,'visible','off')
		set(handles.roipolybutton,'visible','off')
	end
end

function updatecscontrols()
	csaxval = [1 1 1 1]*defaxval;
	
	if (numchans-hasalpha) == 1
		thiscs = 1;
	end
	
	for c = 1:numel(csaxval)
		set(handles.csaxcheck(c),'visible','on')
		set(handles.csaxvalslider(c),'visible','on')
		
		if c <= (numchans-hasalpha)
			set(handles.csaxcheck(c),'string',[' ' axisnames{thiscs}(c) ' Tolerance'])
			set(handles.csaxvalslider(c),'value',csaxval(c))
		elseif hasalpha && c == numchans
			set(handles.csaxcheck(c),'string',' Alpha Tolerance')
			set(handles.csaxvalslider(c),'value',csaxval(c))
			set(handles.csaxcheck(c),'value',0)
			set(handles.csaxvalslider(c),'enable','off')
		else
			set(handles.csaxcheck(c),'visible','off')
			set(handles.csaxvalslider(c),'visible','off')
		end
	end 
	
	if (numchans-hasalpha) == 1
		set(handles.csmenu,'visible','off')
		set(handles.volmenu,'visible','off')
		set(handles.csaxcheck(1),'string',' I Tolerance')
	else
		set(handles.csmenu,'visible','on')
		set(handles.volmenu,'visible','on')
	end

end

%% UPDATE IMAGE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig(whichaxes,keystring)
	if ~exist('keystring','var'); keystring = ''; end
	
	if isempty(imageA)
		return;
	else
		if whichaxes == 1
			h = getimax(handles.axes1);
			imagetoshow = imageA;
		else
			h = getimax(handles.axes2);
			imagetoshow = maskA;
		end
	end

	imagetoshow = alphasafe(imagetoshow);
	
	if invertdisplay
		imagetoshow = 1-imcast(imagetoshow,'double');
	end
	
	% fetch viewport extents before clobbering them
	zoomextents = [get(h,'ylim'); get(h,'xlim')];	
	safeimshow(imagetoshow,h);
	
	if strcmp(keystring,'reset')
		% reset viewport to optimal fit
		h = [getimax(handles.axes1) getimax(handles.axes2)];
		akzoom(h) 
	elseif all(all(zoomextents ~= [0 1;0 1]))
		% restore last viewport
		set(h,'xlim',zoomextents(2,:),'ylim',zoomextents(1,:));
	end
	
end

function handle = getimax(h)
	if strcmpi(get(h,'type'),'image')
		handle = get(h,'parent');
	else 
		handle = h;
	end
end


%% IMPORT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function importimage(objh,~,whichimage,inputimage)
	% if color selection mode is active, terminate it
	if get(handles.selectbutton,'value')
		selectpoints([],[],'off');
	end
	
	switch whichimage
		case 'A'
			wsvariablename = get(objh,'String');
			if isempty(wsvariablename); return; end

			try
				thisimage = imcast(evalin('base',wsvariablename),'double');
			catch
				errstr = 'IMMASK: error evaluating expression for import image. Does it exist?';
				%disp(errstr)
				errordlg(errstr,'Import Error','modal')
				return;
			end

		case 'Anumeric'
			thisimage = imcast(inputimage,'double');
			
	end

	s = size(thisimage);
	numchans = size(thisimage,3);
	hasalpha = any(numchans == [2 4]);
		
	imageA = thisimage;
	maskA = zeros(s(1:2));
	updatecscontrols();
	setcsimg();
	
	undostack = maskA;
	undoindex = 1;
	set(handles.undobutton,'enable','off')
	set(handles.redobutton,'enable','off')
	
	h = getimax(handles.axes1);
	set(h,'xlim',[0 1],'ylim',[0 1]);
	
	% toggle panel visibility
	if isempty(imageA)
		toggleimagecontrols('off')
	else
		toggleimagecontrols('on')
		
	end
	
	updatefig(1,'reset');
	updatefig(2,'reset');
end	

%% EXPORT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function exportimage(~,~)
	wsvariablename = get(handles.exportvarbox,'String');
	if isempty(wsvariablename); return; end
	
	outmask = imcast(maskA,'logical'); % just in case
	assignin('base',wsvariablename,outmask);
end	
	
%% SET WORKING IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setcsimg()
	if isempty(imageA); return; end
	
	% unlike in rectangular models, H is continuous;
	% the maximum radius between two points is 180d, not 360d
	hk = 0.5; 
	
	% this should probably also have rectangular LAB, LUV, etc	
	spacename = csstrings{thiscs};
	switch spacename
		case 'RGB'
			csimg = imageA;
			
		case 'HSL'
			csimg = rgb2hsl(imageA(:,:,1:3));
			csimg(:,:,1) = csimg(:,:,1)/(360*hk);

		case 'HSV'
			csimg = rgb2hsv(imageA(:,:,1:3));
			csimg(:,:,1) = csimg(:,:,1)/hk;

		case 'HSI'
			csimg = rgb2hsi(imageA(:,:,1:3));
			csimg(:,:,1) = csimg(:,:,1)/(360*hk);
			
		case 'LCH (Polar YPbPr)'
			csimg = rgb2ypp(imageA(:,:,1:3));
			B = csimg(:,:,2); R = csimg(:,:,3);
			csimg(:,:,2) = sqrt(B.^2 + R.^2)/0.534;
			csimg(:,:,3) = mod(atan2(R,B),2*pi)/(2*pi*hk);

		case 'LCH (CIE LAB)'
			csimg = rgb2lch(imageA(:,:,1:3),'lab');
			csimg = bsxfun(@rdivide,csimg,permute([100 134 (360*hk)],[3 1 2]));

		case 'LCH (CIE LUV)'
			csimg = rgb2lch(imageA(:,:,1:3),'luv');
			csimg = bsxfun(@rdivide,csimg,permute([100 178 (360*hk)],[3 1 2]));

		case 'LCH (SRLAB2)'
			csimg = rgb2lch(imageA(:,:,1:3),'srlab');
			csimg = bsxfun(@rdivide,csimg,permute([100 103 (360*hk)],[3 1 2]));
			
		case 'LCH (OKLAB)'
			csimg = rgb2lch(imageA(:,:,1:3),'oklab');
			csimg = bsxfun(@rdivide,csimg,permute([100 32.249 (360*hk)],[3 1 2]));
			
		case 'YPbPr'
			csimg = rgb2ypp(imageA(:,:,1:3));
			
		case 'LAB'
			csimg = rgb2lch(imageA(:,:,1:3),'lab');
			C = csimg(:,:,2); H = csimg(:,:,3);
			csimg(:,:,1) = csimg(:,:,1)/100;
			csimg(:,:,2) = C.*cosd(H)/184.44;
			csimg(:,:,3) = C.*sind(H)/202.38;
			
		case 'LUV'
			csimg = rgb2lch(imageA(:,:,1:3),'luv');
			C = csimg(:,:,2); H = csimg(:,:,3);
			csimg(:,:,1) = csimg(:,:,1)/100;
			csimg(:,:,2) = C.*cosd(H)/258.18;
			csimg(:,:,3) = C.*sind(H)/241.50;

		case 'SRLAB2'
			csimg = rgb2lch(imageA(:,:,1:3),'srlab');
			C = csimg(:,:,2); H = csimg(:,:,3);
			csimg(:,:,1) = csimg(:,:,1)/100;
			csimg(:,:,2) = C.*cosd(H)/161.32;
			csimg(:,:,3) = C.*sind(H)/177.44;
			
		case 'OKLAB'
			csimg = rgb2lch(imageA(:,:,1:3),'oklab');
			C = csimg(:,:,2); H = csimg(:,:,3);
			csimg(:,:,1) = csimg(:,:,1)/100;
			csimg(:,:,2) = C.*cosd(H)/50.85;
			csimg(:,:,3) = C.*sind(H)/51.01;
			
	end
	
	% append any alpha if it were stripped for conversion
	if hasalpha && size(csimg,3) ~= numchans
		csimg = cat(3,csimg,imageA(:,:,end));
	end

end

function out = rgb2ypp(in)
	A = [0.299,0.587,0.114;-0.1687367,-0.331264,0.5;0.5,-0.418688,-0.081312];
	A = permute(A,[1 3 2]);
	out = zeros(size(in));
	out(:,:,1) = sum(bsxfun(@times,in,A(1,:,:)),3);
	out(:,:,2) = sum(bsxfun(@times,in,A(2,:,:)),3);
	out(:,:,3) = sum(bsxfun(@times,in,A(3,:,:)),3);
end

%% SET PARAMETER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setparam(objh,~,whichparam,idx)
	switch whichparam
		case 'colorspace'
			thiscs = get(objh,'value');
			updatecscontrols();
			setcsimg();
			
		case 'thisvol'
			thisvol = get(objh,'value');
			
		case 'morphop'
			thismo = get(objh,'value');
			managemorphmenuvis();
			
		case 'serad'
			serad = round(str2num(get(objh,'string')));
			
		case 'minsegsize'
			minsegsize = round(str2num(get(objh,'string')));
			
		case 'roiboolmode'
			thisroiboolmode = get(objh,'value');
		
		case 'roitype'
			thisroitype = get(objh,'value');	
			
		case 'localcomponent'
			localcomponent = get(objh,'value');

		case 'csaxval'
			csaxval(idx) = get(objh,'value');	
			
	end	

	updatefig(1);
	updatefig(2);
end

%% START/STOP COLOR SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function selectpoints(~,~,action)
	
	% Ideally, ideas from akzoom could be rewritten such that mousedown and mousemotion
	% callbacks are capable of handling both selection and view control operations
	% as it is, only one functionality can be available at a time
	% e.g. can't pan while in selection mode
	
	fh = handles.IMMASK_GUI;
	switch action
		case 'on'
			guidata(fh,handles)
			set(fh,'windowkeypressfcn',@onkeypress)
			set(fh,'windowkeyreleasefcn',@onkeyrelease)
			set(fh,'windowbuttondownfcn',@onmouseclick) 
			set(fh,'windowbuttonupfcn','') 
			set(fh,'windowbuttonmotionfcn',{@onmousemotion,'bool selection'}) 
			
			% manage togglebutton
			set(handles.selectbutton,'value',1) 
			set(handles.selectbutton,'string','ESC to Stop') 
			set(handles.selectbutton,'callback',{@selectpoints,'off'})
			
		case 'off'
			% windowkeyreleasefcn is handled after this (works better in R2015b)
			set(fh,'windowkeypressfcn','')
			set(fh,'windowbuttondownfcn','') 
			set(fh,'windowbuttonmotionfcn','')
			
			% manage togglebutton
			set(handles.selectbutton,'value',0) 
			set(handles.selectbutton,'string','Start Color Selection') 
			set(handles.selectbutton,'callback',{@selectpoints,'on'})
			
			updatefig(1,'reset');
			updatefig(2,'reset');
			
			% this is redundant
			set(fh,'Pointer','arrow')
	end
end

%% HANDLE KEY/MOUSE EVENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function onkeypress(~,~)
	%disp('keypress')
	handles = guidata(handles.IMMASK_GUI);
	thismod = get(handles.IMMASK_GUI,'currentmodifier');
	thismod = [thismod{:}];
	if isempty(thismod)
		modkey = get(handles.IMMASK_GUI,'currentkey');
	else
		modkey = thismod;
	end
	
	% bump this to update pointer style
	onmousemotion([],[],'bool selection')
end

function onkeyrelease(~,~)
	%disp('keyrelease')
	if strcmp(modkey,'escape')
		fh = handles.IMMASK_GUI;
		selectpoints([],[],'off') 
		set(fh,'windowkeyreleasefcn',@killwkrfcn)
		onmousemotion([],[],'bool selection') % order of events is important
		modkey = 'normal';
	else
		modkey = 'normal';
		onmousemotion([],[],'bool selection')
	end
end

function killwkrfcn(~,~)
	fh = handles.IMMASK_GUI;
	set(fh,'Pointer','arrow')
	set(fh,'windowkeyreleasefcn','')
end

function onmouseclick(~,~)
	%disp('mouseclick')
	h = fetchthisaxes('axes');
	if isempty(h); return; end
	
	% click type and location
	but = get(handles.IMMASK_GUI,'selectiontype');
	cp = get(h,'currentpoint');
	x = round(cp(1,1)); y = round(cp(1,2));

	if isempty(modkey) || ~strismember(modkey,{'normal','shift','control','shiftcontrol'}); 
		modkey = 'normal'; 
	end
	
	% is the pixel within the displayed region?
	validpoint = any(onimg);
	
	% is the click event something expected?
	validclick = (strcmp(modkey,'normal') && strcmp(but,'normal')) ...
		|| (strcmp(modkey,'shiftcontrol') && strcmp(but,'normal')) ...
		|| (strcmp(modkey,'shift') && strcmp(but,'extend')) ...
		|| (strcmp(modkey,'control') && strcmp(but,'alt'));

	if validclick && validpoint
		matchelliptic(x,y);
	end
end

function onmousemotion(~,~,uimode)
	fh = handles.IMMASK_GUI;
	
	h1 = getimax(handles.axes1);
	h2 = getimax(handles.axes2);

	posfig = getpixelposition(fh); % figure position
	posax1 = getpixelposition(h1); % axes1 position
	posax2 = getpixelposition(h2); % axes2 position
	pos = get(0,'PointerLocation'); % cursor position in screen coordinates
	
	onaxes(1) = pos(1) > (posax1(1)+posfig(1)) && pos(1) < (posax1(1)+posax1(3)+posfig(1)) ...
		 && pos(2) > (posax1(2)+posfig(2)) && pos(2) < (posax1(2)+posax1(4)+posfig(2));
	
	onaxes(2) = pos(1) > (posax2(1)+posfig(1)) && pos(1) < (posax2(1)+posax2(3)+posfig(1)) ...
		 && pos(2) > (posax2(2)+posfig(2)) && pos(2) < (posax2(2)+posax2(4)+posfig(2));
	 
	% is the pixel within the displayed region? 
	if onaxes(1)
		onimg(2) = 0;
		cp = get(h1,'currentpoint');
		x = ceil(cp(1,1)); y = round(cp(1,2));
		onimg(1) = x > 0 && y > 0 && x <= s(2) && y <= s(1);
	elseif onaxes(2)
		onimg(1) = 0;
		cp = get(h2,'currentpoint');
		x = ceil(cp(1,1)); y = round(cp(1,2));
		onimg(2) = x > 0 && y > 0 && x <= s(2) && y <= s(1);
	end
	
	if any(onimg)
		setpointertype(uimode);
	else
		set(fh,'Pointer','arrow')
	end
end

function setpointertype(uimode)
	fh = handles.IMMASK_GUI;
	switch uimode
		case 'bool selection'
			switch modkey
				case 'shift'
					set(fh,'pointershapecdata',cursorgrow)
					set(fh,'pointershapehotspot',[8 8])
					set(fh,'Pointer','custom')
				case 'control'
					set(fh,'pointershapecdata',cursorshrink)
					set(fh,'pointershapehotspot',[8 8])
					set(fh,'Pointer','custom')
				case 'shiftcontrol'
					set(fh,'pointershapecdata',cursorintersect)
					set(fh,'pointershapehotspot',[8 8])
					set(fh,'Pointer','custom')	
				case 'escape'
					set(fh,'Pointer','arrow')
				otherwise
					set(fh,'pointershapecdata',cursornorm)
					set(fh,'pointershapehotspot',[8 8])
					set(fh,'Pointer','custom')
			end
			
		case 'object selection'
			set(fh,'Pointer','hand')
			
	end
end

function h = fetchthisaxes(testwhichobj)
	switch testwhichobj
		case 'axes'
			if onaxes(1)
				h = getimax(handles.axes1);
			elseif onaxes(2)
				h = getimax(handles.axes2);
			else
				h = [];
			end
		case 'img'
			if onimg(1)
				h = getimax(handles.axes1);
			elseif onimg(2)
				h = getimax(handles.axes2);
			else
				h = [];
			end
	end
end

%% GENERATE SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matchelliptic(x,y)
	tol = csaxval;
	x = max(min(round(x),s(2)),1);
	y = max(min(round(y),s(1)),1);
	pxl = csimg(y,x,:);

	switch volumestrings{thisvol}
		case 'ellipsoid'
			% do an elliptical range match within the selected space	
			% for higher powers, this will approximate the 'box' method
			thismask = zeros(s(1:2));
			for c = 1:size(imageA,3)
				enabled = get(handles.csaxcheck(c),'value');
				
				if enabled
					thismask = thismask + ((csimg(:,:,c)-pxl(c))/tol(c)).^2;
				end
			end
			thismask = (thismask <= 1);
			
			% just an idea that doesn't really work well
			%ta=0.1;
			%thismask=min(max((ta+2-2*thismask)/(2*ta),0),1);
	
		case 'box'
			% do a rectangular range match within the selected space	
			thismask = ones(s(1:2));
			for c = 1:size(imageA,3)
				enabled = get(handles.csaxcheck(c),'value');
				
				if enabled
					thismask = thismask & (abs(csimg(:,:,c)-pxl(c)) <= tol(c));
				end
			end
	end
	
	% conditionally restrict only to local group
	if localcomponent
		thismask = localsegment(x,y,thismask);
	end
	
	switch modkey
		case 'normal'
			maskA = thismask;
		case 'shift'
			maskA = maskA | thismask;
		case 'control'
			maskA = maskA & ~thismask;
		case 'shiftcontrol'
			maskA = maskA & thismask;
	end
	pushundo();	
	
	updatefig(2);
end

function outmask = localsegment(x,y,inmask)
	% get object list
	objects = bwlabelFB(inmask,8); 
	% find which object poi belongs in
	selectedobj = objects(y,x);
	% select that object only
	outmask = (objects == selectedobj);
end

%% MODIFY SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function morphmask(~,~)
	whichop = mostrings{thismo};
	
	switch whichop
		case 'despeckle'
			maskA = despeckle(maskA,minsegsize,'both');
		case 'soften'
			fk = fkgen('gaussian',ceil(serad));
			maskA = imfilterFB(maskA,fk);
			maskA = imcast(maskA,'logical');
		case {'open','close','dilate','erode'}
			se = simnorm(fkgen('disk',serad*2));
			maskA = morphops(maskA,se,whichop);
	end
	
	pushundo();
	updatefig(2);
end

function modifymask(~,~,whichop)
	switch whichop
		case 'invert'
			maskA = 1-maskA;
		case 'clear'
			maskA = zeros(s(1:2));
	end
	
	pushundo();
	updatefig(2);
end	

%% ROI/RECT SELECTION MESS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function beginpolyselection(~,~)
	% this is going to mess with all the event callbacks
	% so it's going to end up with an inconsistent control scheme
	
	% if color selection mode is active, terminate it
	if get(handles.selectbutton,'value')
		selectpoints([],[],'off');
	end
	
	% disable view control mouse functionality to keep it from going nuts
	fh = handles.IMMASK_GUI;
	set(fh,'windowkeypressfcn','')
	set(fh,'windowkeyreleasefcn','')
	set(fh,'windowbuttondownfcn',@execpolyselection) 
	set(fh,'windowbuttonupfcn','') 
	set(fh,'windowbuttonmotionfcn',{@onmousemotion,'object selection'}) 
	
	% manage togglebutton
	set(handles.roipolybutton,'value',1) 
	set(handles.roipolybutton,'string','Select AXES') 
	set(handles.roipolybutton,'callback','')
	
end

function execpolyselection(~,~)
	% this waits for user to pick an axes to perform selection in
	fh = handles.IMMASK_GUI;
	h = fetchthisaxes('axes');
	set(fh,'windowbuttondownfcn','') 
	set(fh,'windowbuttonmotionfcn','') 
	set(fh,'Pointer','arrow')
	set(handles.roipolybutton,'string','ESC to Stop')
	if isempty(h)
		finishpolyselection();
		return;
	end
	
	thisselmode = roitypestrings{thisroitype};
	switch thisselmode
		case 'polygon'
			ph = impoly(h);
		case 'freehand'
			ph = imfreehand(h);
		case 'rectangle'
			ph = imrect(h);
		case 'ellipse'
			ph = imellipse(h);
	end
	
	if ~isempty(ph)
		thismask = createMask(ph);
	else 
		thismask = [];
	end
	
	if ~isempty(thismask)
		thisbm = roibmstrings{thisroiboolmode};
		switch thisbm
			case 'replace'
				maskA = thismask;
			case 'add'
				maskA = maskA | thismask;
			case 'subtract'
				maskA = maskA & ~thismask;
			case 'intersection'
				maskA = maskA & thismask;
		end
		pushundo();
	end
	
	finishpolyselection();
end

function finishpolyselection()
	set(handles.roipolybutton,'value',0) 
	set(handles.roipolybutton,'string','Start Manual Selection') 
	set(handles.roipolybutton,'callback',@beginpolyselection)
	updatefig(1,'reset');
	updatefig(2,'reset');
end	

%% MANAGE HISTORY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pushundo()
	% truncate stack to current position and push new entry
	undostack = cat(3,undostack(:,:,1:undoindex),maskA);
	undoindex = size(undostack,3);
	
	set(handles.undobutton,'enable','on')
	set(handles.redobutton,'enable','off')
end

function undoredo(~,~,whichop)
	numundos = size(undostack,3);
	
	nothingtodo = (undoindex == 1 && strcmp(whichop,'undo')) ...
			|| (undoindex == numundos && strcmp(whichop,'redo'));
	if nothingtodo; return; end
	
	switch whichop
		case 'undo'
			undoindex = max(1,undoindex-1);
		case 'redo'
			undoindex = min(numundos,undoindex+1);
	end
	maskA = undostack(:,:,undoindex);
	
	if undoindex == 1
		set(handles.undobutton,'enable','off')
	else
		set(handles.undobutton,'enable','on')
	end
	
	if undoindex == numundos
		set(handles.redobutton,'enable','off')
	else
		set(handles.redobutton,'enable','on')
	end
	
	updatefig(2);
end


% end main function block
end



