function ctout = colorpicker(varargin)
% COLORTABLE=COLORPICKER(IMAGE, {OPTIONS})
%    Opens an interactive GUI for selecting colors from an existing image
%
%    The current image view can be zoomed using the mouse wheel.  
%    Color points may be selected by simply clicking on the image.
%
%    Upon selection of a color, the user may choose to edit it manually
%    or add it to a color table and continue selecting more colors.  
%    If the colortable is empty upon exit, the output will be the current 
%    selection.
%
%    Local average sampling is supported.
%
%    For sake of simplicity, the current and stored color swatches
%    are shown without representation of any alpha content present.
%    Only the most recent color table entries are shown.
%
%    IMAGE is an I/IA/RGB/RGBA image of any standard image class
%		4D images are not supported
%    
%    Option keys include:
%    'singlepoint' restricts the output to only one color
%    'invert' will invert the displayed image and color swatches
%
%    Output class is 'double'
% 
% See also: cpicktool

% this is such a kludge

inputimage = [];
imagetoshow = [];
invert = 0;
spmode = false;
sampradius = 2;

thissample = [0 0 0];
ctout = [];
sct = 0;

numctswatches = 25; % how many color table entries to show

% these are used for mouse/key callbacks
modkey = 'normal';
onaxes = 0;
onimg = 0;

k = 1;
while k <= length(varargin);
	if isimageclass(varargin{k})
		inputimage = varargin{k};
		k = k+1;
	elseif ischar(varargin{k})
		switch lower(varargin{k})
			case 'invert'
				invert = 1;
				k = k+1;
			case 'singlepoint'
				spmode = true;
				k = k+1;
			otherwise
				error('COLORPICKER: unknown option %s',varargin{k})
		end
	end
end

if size(inputimage,4) > 1
	error('COLORPICKER: 4D images are not supported')
end

% if there's already a figure, just close it
% this shouldn't ever have to happen
h = findall(0,'tag','colorpickerfigure');
if ~isempty(h)
	close(h);
end

% build figure into which to place a new axes object
handles = struct([]);
figuresetup();
ha = handles.axes1;

if spmode
	set(handles.commitbutton,'visible','off')
	set(handles.ctblock(:),'visible','off')
end

sc = size(inputimage);
[ncc nca] = chancount(inputimage);
[xx yy] = meshgrid(1:sc(2),1:sc(1));
set(handles.thissamplebox,'string',mat2str(zeros([1 ncc+nca]),4))
prepimage();

fh = handles.colorpickerfigure;
guidata(fh,handles)
pause(0.5); % wait for the figure to finish, otherwise these don't always get set
set(fh,'windowbuttondownfcn',@onmouseclick) 
set(fh,'windowbuttonupfcn','') 
set(fh,'windowbuttonmotionfcn',{@onmousemotion,'bool selection'}) 


%% FULL FIGURE SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ccn = [1 0 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 2 1 0 0 0 0 0 0; ...
	 1 1 0 0 0 0 0 0; ...
	 0 0 1 1 1 1 1 0; ...
	 0 0 1 2 2 2 2 1];	

cursornorm = [fliplr(ccn) ccn];
cursornorm = [cursornorm; flipud(cursornorm)];
cursornorm(cursornorm == 0) = NaN;

	
function figuresetup()
	% the only way to have non-proportional elements in the UI is if a window-resize cbf exists
	% to rescale everything based on gcf geometry
	pw = 180; % side panel width (px)
	ph = 0.94; % main side panel height
	vm = 0.02; % vertical margin (within figure)
	hm = 0.01; % horizontal margin (within figure)
	evm = 0.01; % element vertical margin
	ehm = 0.02; % element horizontal margin
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','colorpicker',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'Tag','colorpickerfigure');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	axespos = [hm vm 1-pw-2*hm-evm 1-2*vm];
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


	% SIDE PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mainpanel = uipanel(...
	'Parent',h1,...
	'Title','Color Selection',...
	'Tag','sidepanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm+evm pw ph]);

	eh = 0.026; % element height
	tsp = 0.93; % table start point
	
	% sample radius
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','left',...
	'Position',[ehm tsp+0.01 0.65 eh],...
	'String','Sample Radius',...
	'Style','text',...
	'Tag','sampradiusboxlabel');
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[2*ehm+0.6 tsp+0.015 0.3 eh],...
	'String',sampradius,...
	'Style','edit',...
	'TooltipString','<html>radius of sample region (pixels)<br>set to 0 to disable averaging</html>',...
	'Tag','sampradiusbox',...
	'callback',@sampradiusboxCBF);
	
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[ehm tsp-evm-eh 1-2*ehm eh],...
	'String','Current Sample',...
	'Style','text',...
	'Tag','thissamplelabel');
	
	anpos = [2*ehm tsp-evm-2*eh 1-4*ehm eh];
	% uicontrol stacking order behavior is changed in R2014b
	% but annotations cannot be children of uipanel objects in earlier versions 
	% (at least not in R2009b)
	if verLessThan('matlab','8.4')
		% -- Code to run in MATLAB R2014a and earlier here --
		pnpos = get(mainpanel,'position');
		anpos(1:2) = pnpos(1:2)+anpos(1:2).*pnpos(3:4);
		anpos(3:4) = anpos(3:4).*pnpos(3:4);
		if invert
			sampleblock = annotation(h1,'rectangle',anpos,'FaceColor',1-thissample);
		else
			sampleblock = annotation(h1,'rectangle',anpos,'FaceColor',thissample);
		end
	else
		% -- Code to run in MATLAB R2014b and later here --
		if invert
			sampleblock = annotation(mainpanel,'rectangle',anpos,'FaceColor',1-thissample);
		else
			sampleblock = annotation(mainpanel,'rectangle',anpos,'FaceColor',thissample);
		end
	end
	
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[2*ehm tsp-2*evm-3*eh 1-4*ehm eh],...
	'String',mat2str(thissample),...
	'Style','edit',...
	'TooltipString','<html>color for the current sample point (normalized)</html>',...
	'callback',@sampleboxCBF,...
	'Tag','thissamplebox');

	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[4*ehm tsp-3*evm-5*eh 1-8*ehm eh],...
	'String','Add to Table',...
	'TooltipString','commit this color to the color table',...
	'Tag','commitbutton',...
	'callback',@commitbuttonCBF);

	% color table swatches
	for m = 1:numctswatches
		anpos = [2*ehm tsp-4*evm-(5+m)*eh 1-4*ehm eh];
		if verLessThan('matlab','8.4')
			% -- Code to run in MATLAB R2014a and earlier here --
			pnpos = get(mainpanel,'position');
			anpos(1:2) = pnpos(1:2)+anpos(1:2).*pnpos(3:4);
			anpos(3:4) = anpos(3:4).*pnpos(3:4);
			if invert
				ctblock(m) = annotation(h1,'rectangle',anpos,'FaceColor',1-thissample,'facealpha',0);
			else
				ctblock(m) = annotation(h1,'rectangle',anpos,'FaceColor',thissample,'facealpha',0);
			end
		else
			% -- Code to run in MATLAB R2014b and later here --
			if invert
				ctblock(m) = annotation(mainpanel,'rectangle',anpos,'FaceColor',1-thissample,'facealpha',0);
			else
				ctblock(m) = annotation(mainpanel,'rectangle',anpos,'FaceColor',thissample,'facealpha',0);
			end
		end
	end
	
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[4*ehm 2*eh 1-8*ehm eh],...
	'String','DONE',...
	'TooltipString','accept current color(s) and exit',...
	'Tag','donebutton',...
	'callback',@donebuttonCBF);

	% all child object handles in figure 
	handles = guihandles(h1);
	handles.ctblock = ctblock;
	handles.sampleblock = sampleblock;
	guidata(h1,handles);
end

%% GUI CBF & REDIRECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function donebuttonCBF(objh,~)
	if spmode
		ctout = thissample;
	else
		if numel(ctout) == 0 
			ctout = thissample;
		end
	end
	delete(handles.colorpickerfigure);
end

function sampleboxCBF(objh,~)
	boxdata = str2num(get(objh,'string'));
	if numel(boxdata) == (ncc+nca)
		thissample = boxdata;
	end		
	updatesampledisplay();
end

function sampradiusboxCBF(objh,~)
	sampradius = str2num(get(objh,'string'));
end

function commitbuttonCBF(objh,~)
	ctout = cat(1,ctout,thissample);
	sct = size(ctout,1);
	
	% update table in gui
	blocknum = 1;
	for m = sct:-1:1
		if ncc == 1
			thissafecolor = [1 1 1]*ctout(m,1);
		else
			thissafecolor = ctout(m,1:ncc);
		end
		
		set(handles.ctblock(blocknum),'facealpha',1)
		if invert
			set(handles.ctblock(blocknum),'facecolor',1-thissafecolor)
		else
			set(handles.ctblock(blocknum),'facecolor',thissafecolor)
		end
		blocknum = blocknum+1;
		if blocknum > numctswatches; break; end
	end	
end

%% HANDLE KEY/MOUSE EVENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function onmouseclick(~,~)
	%disp('mouseclick')
	h = fetchthisaxes('axes');
	if isempty(h); return; end
	
	% click type and location
	but = get(handles.colorpickerfigure,'selectiontype');
	cp = get(h,'currentpoint');
	x = round(cp(1,1)); y = round(cp(1,2));

	if isempty(modkey) || ~ismember(modkey,{'normal','shift','control','shiftcontrol'}); 
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
		getsample(x,y);
	end
end

function onmousemotion(~,~,uimode)
	fh = handles.colorpickerfigure;
	
	h1 = getimax(handles.axes1);

	posfig = getpixelposition(fh); % figure position
	posax1 = getpixelposition(h1); % axes1 position
	pos = get(0,'PointerLocation'); % cursor position in screen coordinates
	
	onaxes = pos(1) > (posax1(1)+posfig(1)) && pos(1) < (posax1(1)+posax1(3)+posfig(1)) ...
		 && pos(2) > (posax1(2)+posfig(2)) && pos(2) < (posax1(2)+posax1(4)+posfig(2));

	 
	% is the pixel within the displayed region? 
	if onaxes
		cp = get(h1,'currentpoint');
		x = ceil(cp(1,1)); y = round(cp(1,2));
		onimg = x > 0 && y > 0 && x <= sc(2) && y <= sc(1);
	end
	
	if onimg
		set(fh,'pointershapecdata',cursornorm)
		set(fh,'pointershapehotspot',[8 8])
		set(fh,'Pointer','custom')
	else
		set(fh,'Pointer','arrow')
	end
end

function h = fetchthisaxes(testwhichobj)
	switch testwhichobj
		case 'axes'
			if onaxes
				h = getimax(handles.axes1);
			else
				h = [];
			end
		case 'img'
			if onimg
				h = getimax(handles.axes1);
			else
				h = [];
			end
	end
end

%% SAMPLE COLLECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function getsample(x,y)
	if sampradius <= 0
		thissample = ctflop(inputimage(y,x,:));
	else
		mask = ((xx-x).^2+(yy-y).^2) <= sampradius^2;
		samplesize = sum(mask(:));
		for c = 1:(ncc+nca)
			wpict = inputimage(:,:,c);
			thissample(c) = sum(wpict(mask))/samplesize;
		end
	end
	updatesampledisplay();
end

function updatesampledisplay()
	if ncc == 1
		thissafecolor = [1 1 1]*thissample(1);
	else
		thissafecolor = thissample(1:ncc);
	end

	if invert
		set(handles.sampleblock,'facecolor',1-thissafecolor)
	else
		set(handles.sampleblock,'facecolor',thissafecolor)
	end
	set(handles.thissamplebox,'string',mat2str(thissample,4))
end

%% VIEW CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function k = safeimshow(imtoshow,h)
	% imshow does a bit better job of picking initial window geometry than image does
	% i'm going to be lazy and not bother making a perfect clone of that behavior
	% just use it if it's installed
	
	if hasipt()
		% IF IPT IS INSTALLED
		warning('off','images:initSize:adjustingMag');
		k = imshow(imtoshow,'border','tight','parent',h);
		warning('on','images:initSize:adjustingMag');
	else
		% IPT NOT INSTALLED
		if size(imtoshow,3) == 1
			imtoshow = repmat(imtoshow,[1 1 3]);
		end
		
		k = image(imtoshow,'parent',h);
		
		axis(h,'off','tight','image')
		set(h,'position',[0 0 1 1])
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

%% UPDATE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig()
	k = safeimshow(imagetoshow,ha);
	akzoom(ha) 
	
	hf = handles.colorpickerfigure;
	
	set(hf,'resizefcn',@onresize)
end

function handle = getimax(h)
	if strcmpi(get(h,'type'),'image')
		handle = get(h,'parent');
	else 
		handle = h;
	end
end

%% PREP IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function prepimage()
	inputimage = imcast(inputimage,'double');
	imagetoshow = alphasafe(inputimage);
	
	if invert
		imagetoshow = 1-imagetoshow;
	end
	
	updatefig();
end

waitfor(handles.colorpickerfigure); 

end
