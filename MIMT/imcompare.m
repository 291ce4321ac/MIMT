function imcompare(varargin)
%   IMCOMPARE({IMAGEA}, {IMAGEB}, {KEYS})
%       Opens a simple gui for interactive comparison of images. This is useful for 
%       comparison of image effects and debugging image conversion tools.
%       
%       Four viewing modes are available, with options accordingly.  Images can be 
%       swapped for simple A/B testing.
%          single image view
%          side-by-side view with synchronized view controls
%          difference mode
%          dot mask mode
%
%       In all modes, channel differences, error counts, and error means are presented.
%       Visibility of individual channels can be toggled as needed.
%       Indication of NaN or out-of-gamut pixels can be enabled.
%
%       Optionally, images can be included as arguments when launching the GUI.  
%       Using numeric inputs will load the images, but the text boxes will remain empty.
%           e.g. imcompare(ThisImage,ThatImage)
%       In order to populate the text boxes, the inputs must be in the form of strings.
%           e.g. imcompare('ThisImage','ThatImage')
%       Populating the text fields is useful if you want to tell your images apart!
%
%       The initial view mode can be specified at startup by including one of the keys
%       '1up', '2up', 'dot', or 'diff' in the command.  
%
%       Also accepts the key string 'invert', which inverts displayed images
%       This is only useful if you run Matlab on an inverted display.
%
%       Intended for use with RGB/RGBA images, though some support for 1 and 2-channel 
%       images exists.  Dimensions of both images must match. 
%
%       View control follows the behavior of akZoom():
%          Zoom is controlled via mouse wheel
%          Left-click to zoom on a rectangular ROI
%          Middle-click to pan the view
%          Right-click to reset the view
%       
%   Tested on R2009b and R2015b (in Linux).  If it doesn't work in a different environment
%   don't be too terribly surprised.  It's still a little half-baked at the moment anyway.
%
%   See also: IMCOMPOSE, IMGENERATE, IMMODIFY.


% implement singleton behavior
h = findall(0,'tag','IMCOMPARE_GUI');
if ~isempty(h)
	% raise window if already open
	%figure(h);
	
	% if there's already a figure, just close it
	% this is simpler than trying to use it
	close(h);
end

% ui data initialization
s = [];
imageA = [];
imageB = [];
composed = [];
composed2 = [];
padimg = [];
imagetoshow = [];
modestrings = {'1-up stacked','2-up concatenated','dot masking','differencing'};
modeshortstrings = {'1up','2up','dot','diff'};
thismode = 2;
layupmodestrings = {'automatic','horizontal','vertical'};
thislayupmode = 1;
diffmodestrings={'absolute value','A>B','A<B'};
thisdiffmode = 1;
stretchrange = 1;
dotfill = 0;
dotsize = 0.05;

shownan = 0;
showoog = 0;
togglestate = [1 1 1 1 1]; % IRGBA
invertdisplay = 0;

% prepare the figure elements
axespos = [];
axesposabs = [];
handles = struct([]);
figuresetup();
toggleimagecontrols('off')

h = handles.axes1;
set(h,'units','pixels')
axesposabs = get(h,'position');
set(h,'units','normalized')

parseinputs();


%% DO STARTUP STUFF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parseinputs()
	numimages = 0;
	
	for a = 1:1:length(varargin)
		if ischar(varargin{a})
			switch lower(varargin{a})
				case 'invert'
					invertdisplay = 1;
					set(handles.invertcheckbox,'value',invertdisplay)
					updatefig();
					%continue;
				case modeshortstrings
					thismode = find(strcmp(varargin{a},modeshortstrings));
					set(handles.viewmodemenu,'value',thismode)
					updatepanel();
					composeimage();
					updatefig('reset');
			end
		end
		
		if numimages == 0
			if ischar(varargin{a})
				set(handles.importvarboxA,'string',varargin{a})
				pause(0.2)
				importimage(handles.importvarboxA,[],'A');
			else
				pause(0.2)
				importimage(handles.importvarboxA,[],'Anumeric',varargin{a});
			end
			numimages = 1;
			
		elseif numimages == 1
			if ischar(varargin{a})
				set(handles.importvarboxB,'string',varargin{a})
				pause(0.2)
				importimage(handles.importvarboxB,[],'B');
			else
				pause(0.2)
				importimage(handles.importvarboxB,[],'Bnumeric',varargin{a});
			end
			numimages = 2;
		end
	end

end

function figuresetup()
	% the only way to have non-proportional elements in the UI is if a window-resize cbf exists
	% to rescale everything based on gcf geometry
	pw = 180; % side panel width (px)
	ph = 0.69; % main side panel height
	vph = 0.13; % view controls panel height
	vm = 0.02; % vertical margin
	hm = 0.01; % horizontal margin
	em = 0.01; % element margin
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','imcompare_gui',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'resizefcn',@onresize,...
	'Tag','IMCOMPARE_GUI');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	axespos = [hm vm 1-pw-2*hm-em 1-2*vm];
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
	'ZColor',get(0,'defaultaxesZColor'),...
	'Tag','axes1',...
	'Visible','on');

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
	'ZColor',get(0,'defaultaxesZColor'),...
	'Tag','axes2',...
	'Visible','off');

	% TOP PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	toppanel = uipanel(...
	'Parent',h1,...
	'Title',blanks(0),...
	'Tag','toppanel',...
	'Clipping','on',...
	'Position',[1-hm-pw ph+vph+vm+2*em pw 1-2*vm-2*em-vph-ph]);

	eh = 0.15;
	
	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em 0.62+eh 1-2*em eh],...
	'String','Import Image A',...
	'Style','text',...
	'Tag','text7');
	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em 0.62 1-2*em eh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','name of image in workspace to import',...
	'callback',{@importimage,'A'},...
	'Tag','importvarboxA');

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em 0.31+eh 1-2*em eh],...
	'String','Import Image B',...
	'Style','text',...
	'Tag','text7');
	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em 0.31 1-2*em eh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','name of image in workspace to import',...
	'callback',{@importimage,'B'},...
	'Tag','importvarboxB');

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[0.05 0.1 0.90 eh],...
	'String','Swap A/B',...
	'TooltipString','Swap images',...
	'Tag','swapbutton',...
	'callback',@swapimages);

	% EDITOR PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h13 = uipanel(...
	'Parent',h1,...
	'Title','Display Mode',...
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

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.05 0.95 0.9 0.04],...
	'String',modestrings,...
	'Style','popupmenu',...
	'Value',thismode,...
	'Tag','viewmodemenu',...
	'callback',{@setparam,'viewmode'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.05 0.90 0.9 0.04],...
	'String',layupmodestrings,...
	'Style','popupmenu',...
	'Value',thislayupmode,...
	'tooltipstring','<html>''horizontal'' concatenates A & B left to right<br/>''vertical'' concatenates A & B top to bottom<br/>''automatic'' will choose orientation which maximizes image area</html>',...
	'Tag','layupmodemenu',...
	'callback',{@setparam,'layupmode'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.05 0.90 0.9 0.04],...
	'String',diffmodestrings,...
	'Style','popupmenu',...
	'Value',thisdiffmode,...
	'Tag','diffmodemenu',...
	'callback',{@setparam,'diffmode'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.1 0.85 0.8 0.04],...
	'String','Stretch range',...
	'Style','checkbox',...
	'TooltipString','Stretch range of differenced image to make small values visible',...
	'value',stretchrange,...
	'Tag','stretchrangecheckbox',...
	'callback',{@setparam,'stretchrange'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[0.1 0.90 0.8 0.04],...
	'String','Dot Fill',...
	'Style','text',...
	'Tag','dotfilllabel');
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[0.05 0.88 0.9 0.03],...
	'min',-1,'max',1,...
	'Style','slider',...
	'Value',dotfill,...
	'Tag','dotfillslider',...
	'callback',{@setparam,'dotfill'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[0.1 0.83 0.8 0.04],...
	'String','Dot Size',...
	'Style','text',...
	'Tag','dotsizelabel');
	uicontrol(...   
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[0.05 0.81 0.9 0.03],...
	'Style','slider',...
	'Value',dotsize,...
	'Tag','dotsizeslider',...
	'callback',{@setparam,'dotsize'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 0.72 0.9 0.08],...
	'String','A is grid; B is dots',...
	'Style','text',...
	'Tag','dotslabel');


	stos = 0.025;
	sth = 0.02;
	btos = 0.02;
	bth = 0.03;
	
	blockbase = 0.01+(5*stos+btos)*4;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 bth],...
	'String','Range of A-B',...
	'Style','text',...
	'Tag','diffrangeheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffrange');

	blockbase = 0.01+(5*stos+btos)*3;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','RMS pixel difference',...
	'Style','text',...
	'Tag','RMSdiffheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','RMSdiff');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','RMSdiff');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','RMSdiff');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','RMSdiff');

	blockbase = 0.01+(5*stos+btos)*2;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','Count [A>B A<B]',...
	'Style','text',...
	'Tag','diffcountheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','diffcount');

	% NaN & OOG
	blockbase = 0.01+(5*stos+btos)*1;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','OoG Count [A B]',...
	'Style','text',...
	'Tag','oogheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','oogcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','oogcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','oogcount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','oogcount');

	blockbase = 0.01;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','NaN Count [A B]',...
	'Style','text',...
	'Tag','nancountheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','nancount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','nancount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','nancount');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','nancount');


	% VIEW CONTROLS PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	vcp = uipanel(...
	'Parent',h1,...
	'Title','View Controls',...
	'Tag','viewcontrolpanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm pw vph]);

	bh = 0.19; % button height
	tbh = 0.10; % toggle button base height
	evp = 0.09;
	
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 tbh+evp+3*bh 0.8 bh],...
	'String','Invert Display',...
	'Style','checkbox',...
	'TooltipString','Use this if using Matlab on an inverted X display.',...
	'Tag','invertcheckbox',...
	'callback',{@viewcontrol,'invert'});

	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 tbh+evp+2*bh 0.8 bh],...
	'String','NaN pixels',...
	'Style','checkbox',...
	'TooltipString','Display a binary representation of NaN pixel components',...
	'Tag','nancheckbox',...
	'callback',{@setparam,'shownan'});

	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 tbh+evp+bh 0.8 bh],...
	'String','OoG pixels',...
	'Style','checkbox',...
	'TooltipString','Represent pixel components which lie outside standard data ranges',...
	'Tag','oogcheckbox',...
	'callback',{@setparam,'showoog'});
	
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 tbh 0.2 bh],...
	'style','togglebutton',...
	'value',togglestate(2),...
	'String','R',...
	'TooltipString','toggle channels on/off',...
	'Tag','chtogbutton2',...
	'callback',{@setparam,'togglechannel'});
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1+0.2 tbh 0.2 bh],...
	'style','togglebutton',...
	'value',togglestate(3),...
	'String','G',...
	'TooltipString','toggle channels on/off',...
	'Tag','chtogbutton3',...
	'callback',{@setparam,'togglechannel'});
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1+0.4 tbh 0.2 bh],...
	'style','togglebutton',...
	'value',togglestate(4),...
	'String','B',...
	'TooltipString','toggle channels on/off',...
	'Tag','chtogbutton4',...
	'callback',{@setparam,'togglechannel'});
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1+0.6 tbh 0.2 bh],...
	'style','togglebutton',...
	'value',togglestate(5),...
	'String','A',...
	'TooltipString','toggle channels on/off',...
	'Tag','chtogbutton5',...
	'callback',{@setparam,'togglechannel'});
	uicontrol(...
	'Parent',vcp,...
	'Units','normalized',...
	'Position',[0.1 tbh 0.6 bh],...
	'style','togglebutton',...
	'value',togglestate(1),...
	'String','I',...
	'TooltipString','toggle channels on/off',...
	'Tag','chtogbutton1',...
	'callback',{@setparam,'togglechannel'});


	% all child object handles in figure 
	handles = guihandles(h1);
	% these get catted in reverse order, so flip to avoid confusion
	handles.diffrange = fliplr(handles.diffrange);
	handles.diffcount = fliplr(handles.diffcount);
	handles.RMSdiff = fliplr(handles.RMSdiff);
	handles.nancount = fliplr(handles.nancount);
	handles.oogcount = fliplr(handles.oogcount);
end

%% VIEW CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function viewcontrol(hobj,event,whichop)
	% this used to do other things too
	if strcmp(whichop,'invert')
		invertdisplay = get(hobj,'value');
	end
	updatefig();
end

function k = safeimshow(imtoshow,h)
	if license('test', 'image_toolbox')
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
	composeimage();
	updatefig();
end

%% TOGGLE ELEMENT VISIBILITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleimagecontrols(state)
	if strcmp(state,'on'); notstate = 'off'; 
	elseif strcmp(state,'off'); notstate = 'on'; end

	set(handles.dummyeditorpanel,'visible',notstate)
	set(handles.editorpanel,'visible',state)
end

function updatetoggles()
	nchans = size(imageA,3);
	if any(nchans == [1 2])
		set(handles.chtogbutton1,'visible','on')
		set(handles.chtogbutton2,'visible','off')
		set(handles.chtogbutton3,'visible','off')
		set(handles.chtogbutton4,'visible','off')
	else
		set(handles.chtogbutton1,'visible','off')
		set(handles.chtogbutton2,'visible','on')
		set(handles.chtogbutton3,'visible','on')
		set(handles.chtogbutton4,'visible','on')
	end
	
	if any(nchans == [2 4])
		set(handles.chtogbutton5,'enable','on')
	else
		set(handles.chtogbutton5,'enable','off')
	end
end

function arrangeaxes()
	tm = modestrings{thismode};
	if ~strcmp(tm,'2-up concatenated')
		% single axes mode
		set(get(handles.axes2,'children'),'visible','off')
		set(handles.axes1,'position',axespos)
	
	else
		% automatic/manual 2-axes mode
		tlm = layupmodestrings{thislayupmode};
		if strcmp(tlm,'automatic')
			h = getimax(handles.axes1);

			axsz = axesposabs([4 3]);

			axar = axsz(2)/axsz(1);
			imar = s(2)/s(1); imar2 = 2*imar; imar1 = imar/2;

			if axar >= imar1; 
				imarea1 = s(2)/s(1)/2; 
				axarea = axsz(2)/axsz(1)/2;
			else
				imarea1 = 2*s(1)/s(2); 
				axarea = 2*axsz(1)/axsz(2);
			end
			imarea1 = imarea1/axarea;

			if axar >= imar2; 
				imarea2 = 2*s(2)/s(1); 
				axarea = 2*axsz(2)/axsz(1);
			else
				imarea2 = s(1)/s(2)/2; 
				axarea = axsz(1)/axsz(2)/2;
			end
			imarea2 = imarea2/axarea;

			if imarea1 > imarea2
				tlm = 'vertical';
			else
				tlm = 'horizontal';
			end
		end

		switch tlm
			case 'horizontal'
				ap = axespos;
				set(handles.axes1,'position',[ap(1:2) ap(3)/2 ap(4)])
				set(handles.axes2,'position',[ap(1)+ap(3)/2 ap(2) ap(3)/2 ap(4)])
				set(get(handles.axes2,'children'),'visible','on')

			case 'vertical'
				ap = axespos;
				set(handles.axes1,'position',[ap(1) ap(2)+ap(4)/2 ap(3) ap(4)/2])
				set(handles.axes2,'position',[ap(1:2) ap(3) ap(4)/2])
				set(get(handles.axes2,'children'),'visible','on')

		end
		
		updatefig('reset')
	end
end

function updatepanel()
	tm = modestrings{thismode};
	switch tm
		case '1-up stacked'
			set(handles.layupmodemenu,'visible','off')
			set(handles.diffmodemenu,'visible','off')
			set(handles.stretchrangecheckbox,'visible','off')
			set(handles.dotfilllabel,'visible','off')
			set(handles.dotfillslider,'visible','off')
			set(handles.dotsizelabel,'visible','off')
			set(handles.dotsizeslider,'visible','off')
			set(handles.dotslabel,'visible','off')
			
		case '2-up concatenated'
			set(handles.layupmodemenu,'visible','on')
			set(handles.diffmodemenu,'visible','off')
			set(handles.stretchrangecheckbox,'visible','off')
			set(handles.dotfilllabel,'visible','off')
			set(handles.dotfillslider,'visible','off')
			set(handles.dotsizelabel,'visible','off')
			set(handles.dotsizeslider,'visible','off')
			set(handles.dotslabel,'visible','off')
			
		case 'dot masking'
			set(handles.layupmodemenu,'visible','off')
			set(handles.diffmodemenu,'visible','off')
			set(handles.stretchrangecheckbox,'visible','off')
			set(handles.dotfilllabel,'visible','on')
			set(handles.dotfillslider,'visible','on')
			set(handles.dotsizelabel,'visible','on')
			set(handles.dotsizeslider,'visible','on')
			set(handles.dotslabel,'visible','on')
			
		case 'differencing'
			set(handles.layupmodemenu,'visible','off')
			set(handles.diffmodemenu,'visible','on')
			set(handles.stretchrangecheckbox,'visible','on')
			set(handles.dotfilllabel,'visible','off')
			set(handles.dotfillslider,'visible','off')
			set(handles.dotsizelabel,'visible','off')
			set(handles.dotsizeslider,'visible','off')
			set(handles.dotslabel,'visible','off')
	end
end

%% COMPOSE IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function composeimage()
	if isempty(imageA) || isempty(imageB); return; end
	
	if shownan && ~showoog
		A = isnan(imageA);
		B = isnan(imageB);
	end
	if showoog && ~shownan
		A = (imageA < 0 | imageA > 1);
		B = (imageB < 0 | imageB > 1);
	end
	if showoog && shownan
		A = isnan(imageA) | (imageA < 0 | imageA > 1);
		B = isnan(imageB) | (imageB < 0 | imageB > 1);
	end
	if ~shownan && ~showoog
		A = imageA;
		B = imageB;
	end
	
	nchans = size(imageA,3);
	switch nchans
		case 1
			A = A*togglestate(1);
			B = B*togglestate(1);
		case 2
			A = bsxfun(@times,A,permute(togglestate([1 5]),[3 1 2]));
			B = bsxfun(@times,B,permute(togglestate([1 5]),[3 1 2]));
			if togglestate(5) == 0
				A(:,:,2) = 1;
				B(:,:,2) = 1;
			end
		case 3
			A = bsxfun(@times,A,permute(togglestate([2 3 4]),[3 1 2]));
			B = bsxfun(@times,B,permute(togglestate([2 3 4]),[3 1 2]));
		case 4
			A = bsxfun(@times,A,permute(togglestate([2 3 4 5]),[3 1 2]));
			B = bsxfun(@times,B,permute(togglestate([2 3 4 5]),[3 1 2]));
			if togglestate(5) == 0
				A(:,:,4) = 1;
				B(:,:,4) = 1;
			end
	end
			
	tm = modestrings{thismode};
	switch tm
		case '1-up stacked'
			composed = A;
			
		case '2-up concatenated'
			composed = A;
			composed2 = B;
			
		case 'dot masking'
			cellsize = dotsize*max(s);
			if dotfill < 0
				barwidth = (cellsize*sqrt(-dotfill)+cellsize)/2;
			else
				barwidth = -(cellsize*sqrt(dotfill)-cellsize)/2;
			end
			[xx yy] = meshgrid(1:s(2),1:s(1));
			mask = or(mod(xx,cellsize) < barwidth,mod(yy,cellsize) < barwidth);
			composed = replacepixels(A,B,mask);
			
		case 'differencing'
			tdm = diffmodestrings{thisdiffmode};
			switch tdm
				case 'absolute value'
					composed = abs(A-B);
				case 'A>B'
					composed = max(0,A-B);
				case 'A<B'
					composed = max(0,B-A);
			end
			
			if stretchrange
				for c = 1:size(imageA,3)
					% using stretchlim with TOL=0 is inconsistent when max(image)<1E-6
					% stretchlim/imadjust cannot compress range
					
					% this will both stretch and compress
					%diffrange=imrange(composed(:,:,c));
					
					% this will only stretch range
					diffrange = min(max(imrange(composed(:,:,c)),0),1);
					if diff(diffrange) ~= 0
						composed(:,:,c) = (composed(:,:,c)-diffrange(1))./(diffrange(2)-diffrange(1));
					end
				end
			end
			
			if togglestate(5) == 0 && any(nchans == [2 4])
				composed(:,:,end) = 1;
			end
	end
	
	% if only alpha is selected, display it as an intensity image
	if (all(togglestate([1 5]) == [0 1]) && nchans == 2) ...
	 || (all(togglestate([2 3 4 5]) == [0 0 0 1]) && nchans == 4)
		composed = composed(:,:,end);
		composed2 = composed2(:,:,end);
	end
	
	arrangeaxes()
end

%% UPDATE IMAGE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig(keystring)
	if ~exist('keystring','var'); keystring = ''; end
	
	tm = modestrings{thismode};
	if isempty(imageA)
		return;
	else
		h = getimax(handles.axes1);
		if ~isempty(imageA) && isempty(imageB)
			imagetoshow = imageA;
		else
			imagetoshow = composed;
		end
		udfig(h,keystring);
		
		if strcmp(tm,'2-up concatenated')
			h = getimax(handles.axes2);
			if ~isempty(imageA) && isempty(imageB)
				imagetoshow = padimg;
				%arrangeaxes()
			else
				imagetoshow = composed2;
			end
			udfig(h,keystring);
		end
	end
	
end

function udfig(h,keystring)
	imagetoshow = alphize(imagetoshow);
	
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

%% ALPHIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function safepict = alphize(thispict)
	if mod(size(thispict,3),2) == 0
		% has alpha, needs matting
		mat = padimg(:,:,1);
		safepict = imblend(thispict,mat,1,'normal');
		safepict = safepict(:,:,1:end-1);
	else
		safepict = thispict;
	end
end

%% IMPORT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function importimage(objh,~,whichimage,inputimage)
	switch whichimage
		case 'A'
			wsvariablename = get(objh,'String');
			if isempty(wsvariablename); return; end

			try
				thisimage = imcast(evalin('base',wsvariablename),'double');
			catch
				errstr = 'IMCOMPARE: error evaluating expression for image A. Does it exist?';
				%disp(errstr)
				errordlg(errstr,'Import Error','modal')
				return;
			end
			ns = size(thisimage);
			
			% just load in new image, check and clear B if it doesn't match
			if numel(ns) ~= numel(s) || any(ns ~= s)
				imageB = [];
				set(handles.importvarboxB,'string','')
			end

			s = ns; 
			imageA = thisimage;
			generatepadimg();
			arrangeaxes()

			h = handles.axes1;
			if strcmpi(get(h,'type'),'image')
				h = get(h,'parent');
			end
			set(h,'xlim',[0 1],'ylim',[0 1]);
			
		case 'B'
			wsvariablename = get(objh,'String');
			if isempty(wsvariablename); return; end

			try
				thisimage = imcast(evalin('base',wsvariablename),'double');
			catch
				errstr = 'IMCOMPARE: error evaluating expression for image B. Does it exist?';
				%disp(errstr)
				errordlg(errstr,'Import Error','modal')
				return;
			end
			ns = size(thisimage);
			
			if numel(ns) ~= numel(s) || any(ns ~= s)
				errstr1 = sprintf('IMCOMPARE: Comparing images of different size is not currently supported\n');
				errstr2 = sprintf('Image in slot A defines the dimensions required of image in slot B\n');
				errstr3 = sprintf('Image A: %s\nImage B: %s\n',mat2str(s),mat2str(ns));
				errstr = [errstr1 errstr2 errstr3];
				%disp(errstr)
				errordlg(errstr,'Import Error','modal')
				return;
			else
				imageB = thisimage;
			end
			
		case 'Anumeric'
			thisimage = imcast(inputimage,'double');
			s = size(thisimage);

			imageA = thisimage;
			generatepadimg();
			arrangeaxes()

			h = handles.axes1;
			if strcmpi(get(h,'type'),'image')
				h = get(h,'parent');
			end
			set(h,'xlim',[0 1],'ylim',[0 1]);
			
		case 'Bnumeric'
			thisimage = imcast(inputimage,'double');
			ns = size(thisimage);
			
			if numel(ns) ~= numel(s) || any(ns ~= s)
				errstr1 = sprintf('IMCOMPARE: Comparing images of different size is not currently supported\n');
				errstr2 = sprintf('Image in slot A defines the dimensions required of image in slot B\n');
				errstr = [errstr1 errstr2];
				%disp(errstr)
				errordlg(errstr,'Import Error','modal')
				return;
			else
				imageB = thisimage;
			end
	end
	
	% toggle panel visibility
	if isempty(imageA) || isempty(imageB)
		toggleimagecontrols('off')
	else
		toggleimagecontrols('on')
		updatepanel();
	end
	
	composeimage();
	updatefig('reset');
	updateranges();
	updatetoggles();
end	

function generatepadimg()
	k = round(mean(s(1:2))/50);
	xx = mod(0:(s(2)-1),k*2) < k;
	yy = mod(0:(s(1)-1),k*2) < k;
	padimg = 0.5*bsxfun(@xor,xx,yy')+0.25;
	padimg = repmat(padimg,[1 1 size(imageA,3)]);
end
	
%% UPDATE RANGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateranges()
	if isempty(imageA) || isempty(imageB); return; end
	
	% should pixel counts be in percent?
	diffAB = imageA-imageB;
	Abigger = sum(sum(diffAB > 0,1),2);
	Asmaller = sum(sum(diffAB < 0,1),2);
	
	for c = 1:size(imageA,3)
		diffABc = imrange(diffAB(:,:,c));

		ABerr = diffAB(diffAB(:,:,c) ~= 0); 
		if isempty(ABerr); ABerr = 0; end

		RMSdiff = sqrt(sum(ABerr.^2)./numel(ABerr));
		
		nancount = [sum(sum(isnan(imageA(:,:,c)))) sum(sum(isnan(imageB(:,:,c))))];
		oogA = sum(sum(imageA(:,:,c) < 0)) + sum(sum(imageA(:,:,c) > 1));
		oogB = sum(sum(imageB(:,:,c) < 0)) + sum(sum(imageB(:,:,c) > 1));

		set(handles.diffrange(c),'visible','on')
		set(handles.diffrange(c),'string',sprintf('[%4.3E   %4.3E]',diffABc(1),diffABc(2)))

		set(handles.diffcount(c),'visible','on')
		set(handles.diffcount(c),'string',mat2str([Abigger(c) Asmaller(c)]))

		set(handles.RMSdiff(c),'visible','on')
		set(handles.RMSdiff(c),'string',num2str(RMSdiff))
		
		set(handles.nancount(c),'visible','on')
		set(handles.nancount(c),'string',mat2str(nancount))
		
		set(handles.oogcount(c),'visible','on')
		set(handles.oogcount(c),'string',mat2str([oogA oogB]))
	end
	
	for c = (size(imageA,3)+1):4
		set(handles.diffrange(c),'visible','off')
		set(handles.diffcount(c),'visible','off')
		set(handles.RMSdiff(c),'visible','off')
		set(handles.nancount(c),'visible','off')
		set(handles.oogcount(c),'visible','off')
	end
end

%% SET PARAMETER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setparam(objh,~,whichparam)
	figupdatestr = '';
	switch whichparam
		case 'viewmode'
			thismode = get(objh,'value');
			updatepanel();
			figupdatestr = 'reset';
			
		case 'layupmode'
			thislayupmode = get(objh,'value');
			
		case 'diffmode'
			thisdiffmode = get(objh,'value');
			
		case 'stretchrange'
			stretchrange = get(objh,'value');
			
		case 'dotfill'
			dotfill = get(objh,'value');
			
		case 'dotsize'
			dotsize = get(objh,'value');
			
		case 'shownan'
			shownan = get(objh,'value');	
		
		case 'showoog'
			showoog = get(objh,'value');	
			
		case 'togglechannel'
			togglestate = [...
				get(handles.chtogbutton1,'value'), ...
				get(handles.chtogbutton2,'value'), ...
				get(handles.chtogbutton3,'value'), ...
				get(handles.chtogbutton4,'value'), ...
				get(handles.chtogbutton5,'value')];
			
	end	
	
	composeimage();
	updatefig(figupdatestr);
end

%% SWAP IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function swapimages(~,~)
	tmp = imageA;
	imageA = imageB;
	imageB = tmp;
	
	tmp = get(handles.importvarboxA,'string');
	set(handles.importvarboxA,'string',get(handles.importvarboxB,'string'));
	set(handles.importvarboxB,'string',tmp);
	
	composeimage();
	updatefig();
	updateranges();
end






% end main function block

end


