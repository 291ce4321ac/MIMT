function kimg = imshow2(varargin)
% IMSHOW2(IMAGE, {OPTIONS})
%    This is a convenience tool to serve as a replacement for IMSHOW.
%    This is intended primarily as a viewer, and not for use as a GUI 
%    image display component, as it occupies mouse and key event callbacks. 
%    This function does not require IP Toolbox
%
%    This tool has a number of different features
%       - Will automatically apply a checkerboard matting to images
%         with alpha (IA/RGBA/RGBAAA)
%       - Does not restrict channel arrangements based on numeric class.
%       - Makes use of full axes extents when zooming in on images
%       - Default behavior uses tight margins for space efficiency.
%       - Uses akZoom to provide convenient mouse panning and zooming.
%       - Can optionally invert the displayed image.  This is mostly
%         only useful if using an inverted display.
%       - When using 'tools' option, 4D image controls are available
%         and visibility of individual channels can be toggled as needed.
%         Indication of NaN or out-of-gamut pixels can be enabled.
%         Additional image information is displayed for convenience.
%
%    IMAGE may be numeric or a string:
%    Numeric inputs can be used with any mode, and will load the image as normal.
%        e.g. imshow2(ThisImage)
%    If using the 'tools' option with numeric inputs, the text box will remain empty.
%    In order to populate the text box, the input should be in the form of a string.
%        e.g. imshow2('ThisImage','tools')
%    Populating the text field is useful to keep track of what you're viewing.
%
%    If fed a 4D image, the first frame will be displayed.
%    If no image is specified, a demo image will be displayed.
%    
%    Option keys include:
%    'parent', followed by a handle can be used to specify a target axes
%    'loose' will use larger margins around the image (imshow behavior)
%    'invert' will invert the displayed image
%    'tools' will show additional view tools for convenient browsing
%    Specifying 'tools' option overrides 'parent' option.
%
%    KNOWN ISSUES:
%    Does not play nicely with the new axes view controls implemented in R2018a.
%    For that reason, axes toolbar is disabled in newer versions.
%    May barf harmless errors when a docked figure is resized.
% 
% See also: imshow, imcompare

inclass = '';
inputimagestring = '';
exportimagestring = 'is2snapshot';
inputimage = [];
imagetoshow = [];
invert = 0;
tight = 1;
tools = 0;
sc = [];
framenumber = 1;
numframes = 1;
shownan = 0;
showoog = 0;
togglestate = [1 1 1 1 1]; % IRGBA

k = 1;
while k <= length(varargin)
	if isimageclass(varargin{k},'mimt')
		inputimage = varargin{k};
		k = k+1;
	elseif ischar(varargin{k})
		switch lower(varargin{k})
			case 'invert'
				invert = 1;
				k = k+1;
			case 'tight'
				k = k+1;
			case 'loose'
				tight = 0;
				k = k+1;
			case 'tools'
				tools = 1;
				k = k+1;	
			case 'parent'
				ha = varargin{k+1};
				k = k+2;
			otherwise
				if k == 1
					inputimagestring = varargin{k};
					k = k+1;
				else
					error('IMSHOW2: unknown option %s',varargin{k})
				end
		end
	else
		error('IMSHOW2: unknown argument')
	end
end

if tools == 1
	% if there's already a figure, just close it
	% this is simpler than trying to use it
	h = findall(0,'tag','imshow2figure');
	if ~isempty(h)
		close(h);
	end
	
	% build figure into which to place a new axes object
	handles = struct([]);
	figuresetup();
	ha = handles.axes1;
end
	
if ~exist('ha','var')	
	% just find old axes or make a new one
	ha = gca; 
else 
	cla(ha);
end

% this does this manually in case tools==0
if isempty(inputimage) && isempty(inputimagestring)
	inputimagestring = ['imread(''',which('gantrycrane.png'),''')'];
	inputimage = eval(inputimagestring);
elseif isempty(inputimage) && ~isempty(inputimagestring)
	try
		inputimage = evalin('base',inputimagestring);
	catch
		errstr = sprintf('IMSHOW2: Invalid image ''%s''\n',inputimagestring);
		if tools
			errordlg(errstr,'Import Error','modal')
		else
			disp(errstr)
		end
	end
end

prepimage();

if nargout == 1
	kimg = k;
end




%% FULL FIGURE SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figuresetup()
	% the only way to have non-proportional elements in the UI is if a window-resize cbf exists
	% to rescale everything based on gcf geometry
	pw = 180; % side panel width (px)
	ph = 0.82; % main side panel height
	vm = 0.02; % vertical margin
	hm = 0.01; % horizontal margin
	em = 0.01; % element margin
	vph = 0.13; % view panel height
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','imshow2',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'Tag','imshow2figure');

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


	% EDITOR PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h13 = uipanel(...
	'Parent',h1,...
	'Title','Image Control',...
	'Tag','editorpanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm+vph+em pw ph]);

	eh = 0.03;
	tsp = 0.93;
	
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em tsp 1-2*em eh],...
	'String','Source Image',...
	'Style','text',...
	'Tag','imagelabel');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em tsp-eh 1-2*em eh],...
	'String',inputimagestring,...
	'Style','edit',...
	'TooltipString','<html>image to be imported from workspace<br>or expression to generate an image to display</html>',...
	'callback',{@setparam,'imagetoshow'},...
	'Tag','imagebox');

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em tsp-em-2*eh 1-2*em eh],...
	'String','Select Frame',...
	'Style','text',...
	'Tag','steplabel');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em+(1-2*em)*0.36 tsp-em-3*eh (1-2*em)*0.3 eh],...
	'String',num2str(framenumber),...
	'Style','edit',...
	'TooltipString','frame number',...
	'callback',{@setparam,'framenumber'},...
	'Tag','fnbox');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[em+(1-2*em)*0.36*2 tsp-em-3*eh (1-2*em)*0.3 eh],...
	'String','+',...
	'TooltipString','next frame',...
	'Tag','incframebutton',...
	'callback',{@setparam,'incframenumber'});
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[em tsp-em-3*eh (1-2*em)*0.3 eh],...
	'String','-',...
	'TooltipString','prev frame',...
	'Tag','decframebutton',...
	'callback',{@setparam,'decframenumber'});

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[em tsp-5*eh 1-2*em eh],...
	'String','Export to WS',...
	'Style','text',...
	'Tag','exportlabel');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[em tsp-6*eh 1-2*em eh],...
	'String',exportimagestring,...
	'Style','edit',...
	'TooltipString','<html>variable name for image exported to workspace<br>view controls (except invert) apply to saved image</html>',...
	'callback',@exportimage,...
	'Tag','exportvarbox');


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
	'value',invert,...
	'Tag','invertcheckbox',...
	'callback',{@setparam,'invert'});

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

	stos = 0.025;
	sth = 0.02;
	btos = 0.02;
	bth = 0.03;

	blockbase = 0.01+(5*stos+btos)*3+(2*stos+btos);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+1*stos 0.9 sth],...
	'String','Image Class',...
	'Style','text',...
	'Tag','sizeheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String',inclass,...
	'Style','text',...
	'Tag','classtext');
	
	blockbase = 0.01+(5*stos+btos)*3;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+1*stos 0.9 sth],...
	'String','Image Size',...
	'Style','text',...
	'Tag','sizeheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','sizetext');

	blockbase = 0.01+(5*stos+btos)*2;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','Data Range',...
	'Style','text',...
	'Tag','chanrangeheader');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+3*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','chanrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+2*stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','chanrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+stos 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','chanrange');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase 0.9 sth],...
	'String','[numbers]',...
	'Style','text',...
	'Tag','chanrange');

	% NaN & OOG
	blockbase = 0.01+(5*stos+btos)*1;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'fontweight','bold',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.05 blockbase+4*stos 0.9 sth],...
	'String','OoG Count',...
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
	'String','NaN Count',...
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


	% all child object handles in figure 
	handles = guihandles(h1);
	guidata(h1,handles);
	% these get catted in reverse order, so flip to avoid confusion
	handles.chanrange = fliplr(handles.chanrange);
	handles.nancount = fliplr(handles.nancount);
	handles.oogcount = fliplr(handles.oogcount);
end

%% EXPORT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function exportimage(objh,~)
	exportimagestring = get(handles.exportvarbox,'String');
	if isempty(exportimagestring); return; end
	
	% should this save the visible image or the base image?
	
	% doing visible-only would ruin transparent or multiframe images
	% but doing visible-only would allow capture of NaN/OoG maps
	% the alternative is to re-generate the entire image without alphizing
	
	outpict = imcast(inputimage,'double');
	for f = 1:numframes
		outpict(:,:,:,f) = preponeframe(outpict(:,:,:,f));
	end
	
	assignin('base',exportimagestring,outpict);
end

%% VIEW CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function k = safeimshow(imtoshow,h)
	% imshow does a bit better job of picking initial window geometry than image does
	% i'm going to be lazy and not bother making a perfect clone of that behavior
	% just use it if it's installed
	
	imshowinbase = ifversion('>=','R2014b');
	hasIPT = hasipt();
	
	if imshowinbase || hasIPT
		% IF IPT IS INSTALLED
		d1 = warning('query','images:initSize:adjustingMag');
		d2 = warning('query','images:imshow:magnificationMustBeFitForDockedFigure');
		warning('off','images:initSize:adjustingMag');
		warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
		if tight
			k = imshow(imtoshow,'border','tight','parent',h);
		else
			k = imshow(imtoshow,'parent',h);
		end
		warning(d1.state,'images:initSize:adjustingMag');
		warning(d2.state,'images:imshow:magnificationMustBeFitForDockedFigure');
	else
		% IPT NOT INSTALLED
		if size(imtoshow,3) == 1
			imtoshow = repmat(imtoshow,[1 1 3]);
		end
		
		k = image(imtoshow,'parent',h);
		
		if tight
			axis(h,'off','tight','image')
			set(h,'position',[0 0 1 1])
		else
			axis(h,'off','image')
			set(h,'position',[0.075 0.075 0.85 0.85])
		end
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
	updatefig();
end

function updatetoggles()
	if tools == 1
		nchans = size(imagetoshow,3);
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
end

%% UPDATE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig()
	k = safeimshow(imagetoshow,ha);
	akzoom(ha) 
	
	% view controls in the R2018a axes toolbar break akzoom
	% just disable the dumb thing
	persistent hasaxtb
	if isempty(hasaxtb)
		hasaxtb = ifversion('>=','R2018a');
	end
	if hasaxtb
		tb = axtoolbar(ha);
		tb.Visible = 'off';
	end
	
	if tools == 1
		hf = handles.imshow2figure;
	else 
		hf = get(ha,'Parent');
	end
	
	set(hf,'resizefcn',@onresize)
end

%% UPDATE RANGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateranges()
	if isempty(imagetoshow) || tools == 0; return; end
	
	set(handles.classtext,'string',inclass)
	set(handles.sizetext,'string',mat2str(size(inputimage)))
		
	for c = 1:size(imagetoshow,3)
		chanrange = imcast(imrange(imagetoshow(:,:,c)),inclass);
		nancount = sum(sum(isnan(imagetoshow(:,:,c))));
		oog = sum(sum(imagetoshow(:,:,c) < 0)) + sum(sum(imagetoshow(:,:,c) > 1));

		set(handles.chanrange(c),'visible','on')
		set(handles.chanrange(c),'string',mat2str(chanrange,6))
		
		set(handles.nancount(c),'visible','on')
		set(handles.nancount(c),'string',mat2str(nancount))
		
		set(handles.oogcount(c),'visible','on')
		set(handles.oogcount(c),'string',mat2str(oog))
	end
	
	for c = (size(imagetoshow,3)+1):4
		set(handles.chanrange(c),'visible','off')
		set(handles.nancount(c),'visible','off')
		set(handles.oogcount(c),'visible','off')
	end
end

%% SET PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setparam(objh,~,whichparam)
	switch whichparam
		case 'imagetoshow'
			inputimagestring = get(objh,'string');
			
			if isempty(inputimagestring)
				inputimagestring = ['imread(''',which('gantrycrane.png'),''')'];
				set(handles.imagebox,'string',inputimagestring)
				inputimage = eval(inputimagestring);
			else
				try
					inputimage = evalin('base',inputimagestring);
				catch
					errstr = sprintf('IMSHOW2: Invalid image ''%s''\n',inputimagestring);
					errordlg(errstr,'Import Error','modal')
				end
			end
			
			framenumber = 1;
			set(handles.fnbox,'string',num2str(framenumber))
			
		case 'framenumber'
			fn = str2double(get(objh,'string'));
			framenumber = min(max(fn,1),numframes);
			set(handles.fnbox,'string',num2str(framenumber))
			
		case 'incframenumber'
			framenumber = min(framenumber+1,numframes);
			set(handles.fnbox,'string',num2str(framenumber))
			
		case 'decframenumber'
			framenumber = max(framenumber-1,1);
			set(handles.fnbox,'string',num2str(framenumber))
			
		case 'invert'
			invert = get(objh,'value');
			
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
	prepimage()
end

%% PREP IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function prepimage()
	imagetoshow = inputimage(:,:,:,framenumber);
	sc = size(imagetoshow);

	numframes = size(inputimage,4);
	if tools == 1
		if numframes > 1
			set(handles.fnbox,'enable','on')
			if framenumber ~= numframes
				set(handles.incframebutton,'enable','on')
			else
				set(handles.incframebutton,'enable','off')
			end
			if framenumber ~= 1
				set(handles.decframebutton,'enable','on')
			else
				set(handles.decframebutton,'enable','off')
			end
		else
			set(handles.fnbox,'enable','off')
			set(handles.incframebutton,'enable','off')
			set(handles.decframebutton,'enable','off')
		end
	end
	
	
	[imagetoshow inclass] = imcast(imagetoshow,'double');
	imagetoshow = preponeframe(imagetoshow);
	
	updatetoggles();
	updateranges();
	
	imagetoshow = alphasafe(imagetoshow);
	
	if invert
		imagetoshow = 1-imagetoshow;
	end
	
	updatefig();
end

% process frame for view controls
% no alphasafe, no invert
function inframe = preponeframe(inframe)
	if shownan && ~showoog
		inframe = isnan(inframe);
	end
	if showoog && ~shownan
		inframe = (inframe < 0 | inframe > 1);
	end
	if showoog && shownan
		inframe = isnan(inframe) | (inframe < 0 | inframe > 1);
	end
	
	nchans = size(inframe,3);
	switch nchans
		case 1
			inframe = inframe*togglestate(1);
		case 2
			inframe = bsxfun(@times,inframe,permute(togglestate([1 5]),[3 1 2]));
			if togglestate(5) == 0
				inframe(:,:,2) = 1;
			end
		case 3
			inframe = bsxfun(@times,inframe,permute(togglestate([2 3 4]),[3 1 2]));
		case 4
			inframe = bsxfun(@times,inframe,permute(togglestate([2 3 4 5]),[3 1 2]));
			if togglestate(5) == 0
				inframe(:,:,4) = 1;
			end
	end
end
	

end
