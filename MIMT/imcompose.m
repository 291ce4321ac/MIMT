function imcompose(varargin)
%   IMCOMPOSE(OPTIONS)
%       Opens a simple gui for interactive composition of images from a stack of image layers
%       much like common image manipulation applications e.g. GIMP.  This was originally
%       made to allow use of IMBLEND's features to recompose layer stacks exported from GIMP.
%
%       The user is able to import & export data from & to the workspace. The user may
%       generate simple layer content from scratch or modify existing layers using 
%       secondary ui tools.  Layers may be reordered, modified, and a wide range of 
%       blending methods are available via IMBLEND(). 
%
%       Provided are two display axes:
%          A primary axes showing the composed image
%          A preview axes showing the current layer
%       Clicking on the preview image swaps the two for better single-layer view
%
%       Primary axes view control follows the behavior of akZoom():
%          Zoom is controlled via mouse wheel
%          Left-click to zoom on a rectangular ROI
%          Middle-click to pan the view
%          Right-click to reset the view
%
%       Intended for use with RGB/RGBA images, though some support for 1 and 2-channel 
%       images exists.  
%
%       Layer import or generation may result in array expansion depending on incoming image. 
%           RGB/RGBA layer into RGB/RGBA stack: RGB/RGBA stack
%           I/IA layer into I/IA stack: I/IA stack
%           I/IA layer into RGB/RGBA stack: incoming layer is expanded
%           Grayscale RGB/RGBA layer into I/IA stack: incoming layer is flattened
%           Color RGB/RGBA layer into I/IA stack: stack is expanded
%       Similarly, importing layers with alpha content will result in array expansion if needed.
%
%       Optional keys include:
%           'invert' inverts image display for use on an inverted display
%           'single' or 'double' (default) sets the class of the working image arrays
%               using 'single' helps conserve memory, but does not necessarily improve speed
%
%       Output datatype matches the class of the working image (default 'double')
% 
%   Things that don't work (yet):
%       Can't support inputs or layers of mismatched H,W
%       Can't do much with directly editing alpha channels; no supplemental layer masking
%       Can't convert back to a 1-ch image after importing and deleting a RGB layer.
%       Can't import/export parameter arrays to save work in an editable fashion.
%       Doesn't support layers which are 4-D themselves (e.g. a stack of animations)
%       There is no undo. Let's pretend that's an artistic statement.
%       
%   Tested on R2009b and R2015b (in Linux).  If it doesn't work in a different environment
%   don't be too terribly surprised.  It's still a little half-baked at the moment anyway.
%
%   See also: IMBLEND, IMGENERATE, IMMODIFY.

% TO DO:
% should we also force RGB?
	
% merge down
% import from file/folder
% mask generation gui
% crop/scale
% image import needs to handle size mismatch	
% consider using incremental compositing when in auto mode for speed
% consider expansion for 5-D support? nah

% candidates for import/export
% imagelayers (is this needed when exporting?)
% preprocessed
% parameters:
%	blendmode
%	opacity
%	amount
%	modifier
% just use ICP

% imblend function transformation keys don't apply when mode is 'normal'
% this is part of an efficiency shortcut; fixing it would be a big mess.
% nearfga and farfga don't work correctly for similar reasons
% fixing this would be even worse, but can be worked around with "new from visible"
% it would be better to invest the effort in a complete rewrite with ICP object support 
% and a sane scalable gui definition



% implement singleton behavior
h = findall(0,'tag','IMCOMPOSE_GUI');
if ~isempty(h)
	% raise window if already open
	figure(h);
else
	wclass = 'double';
	invertdisplay = 0;
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'invert'
					invertdisplay = 1;
				case 'single'
					wclass = 'single';
				case 'double'
					wclass = 'double';
				otherwise
					error('IMCOMPOSE: unknown argument %s\n',thisarg)
			end
		else
			error('IMCOMPOSE: unknown numeric argument\n')
		end
	end
	
	% ui data initialization
	zoomextents = [];
	numframes = 0;
	s = [];
	hasalpha = 0;
	composed = [];
	imagelayers = [];
	preprocessed = [];
	opacity = [];
	hidden = [];
	disablealpha = [];
	amount = [];
	camount = [];
	blendmode = [];
	blendmodelabel = [];
	compmode = [];
	compmodelabel = [];
	layermodifier = [];
	layerinvert = [];
	layertranspose = [];
	layercomplement = [];
	layerverbose = [];
	
	solo = false;
	selectedlayer = 1;		% the currently selected layer in the listbox
	generatinglayer = 1;		% the layer on which imgenerate() is operating
	modifyinglayer = 1;		% the layer on which immodify() is operating
	notgeneratedyet = 0;		% this is set while imgenerate has been called, but has not yet invoked layer insertion
	autocompose = 1;
	% not including colorlchsr, layered near/far, transfer, permute
	blendmodestrings = {'normal','████████████', ...
		'soft light','soft light ps','soft light svg','soft light eb','soft light eb2','━━━━━━━━━━━━', ...
		'overlay','hard overlay','hard light','linear light','vivid light','easy light','flat light','soft flat light','softer flat light', ...
		'meanlight','soft mean light','star light','moon light','moon light 2','super light','pin light','fog lighten','fog darken','━━━━━━━━━━━━', ...
		'hard mix ps','hard mix ib','hard mix kr','━━━━━━━━━━━━', ...
		'glow','heat','reflect','freeze','helow','gleat','frect','reeze','━━━━━━━━━━━━', ...
		'penumbra a1','penumbra b1','penumbra a2','penumbra b2','penumbra a3','penumbra b3','━━━━━━━━━━━━', ...
		'scale add','scale mult','contrast','curves','████████████' ...
		'color dodge','color burn','poly dodge','poly burn','linear dodge','linear burn', ...
		'easy dodge','easy burn','gamma dodge','gamma burn','suau dodge','suau burn','maleki dodge','maleki burn','━━━━━━━━━━━━', ...
		'flat glow','flat shadow','mean glow','mean shadow','star glow','star shadow','moon glow','moon shadow','moon glow 2','moon shadow2','━━━━━━━━━━━━', ...
		'tint','shade','lighten eb','darken eb','████████████' ...
		'lighten rgb','darken rgb','lighten y','darken y','saturate','desaturate','near','far','replace bg','replace fg','preserve bg','preserve fg','━━━━━━━━━━━━', ...
		'multiply','screen','divide','addition','subtraction','difference','equivalence','exclusion','negation','extremity', ...
		'average','interpolate','hardint','geometric','harmonic','pnorm','grain extract','grain merge','gammalight','gammadark', ...
		'sqrtdiff','arctan','████████████' ...
		'mesh','hardmesh','bomb','bomb locked','hard bomb', ...
		'lcd','pelican','muffle','punch','grapes','ripe','████████████' ...
		'modulo','mod shift','mod divide','cont mod','cont mod shift','cont mod divide','████████████' ...
		'color hsl','color hsly','color hslyc', ...
		'color hsv','color hsvy','color hsvyc', ...
		'color hsi','color hsiy','color hsiyc', ...
		'color lchsr','color lchab','color hsyp','━━━━━━━━━━━━', ...
		'hue','saturation','value','luma','lumac','lightness','intensity','████████████' ...
		'recolor hsly hs','recolor hsly h','recolor hsly s', ...
		'recolor lch hs','recolor lch h','recolor lch s','████████████' ...
		'blurmap','blurmap ring','blurmap motion','blurmap glow1','blurmap glow2','blurmap cross','blurmap 3dot','blurmap 4dot','████████████'...
		'permute h>h','permute s>h','permute y>h','permute dh>h','permute ds>h','permute dy>h', ...
		'permute h>hs','permute s>hs','permute y>hs','permute dh>hs','permute ds>hs','permute dy>hs','████████████' ...
		'other mode'};
	nonscalablemodestrings = {'normal','hard overlay','soft light','soft light ps','soft light svg','soft light eb','multiply','screen','divide', ...
		'addition','subtraction','exclusion','grain extract','grain merge','hue','saturation', ...
		'color hsl','color hsly','color hslyc', ...
		'color hsv','color hsvy','color hsvyc', ...
		'color hsi','color hsiy','color hsiyc', ...
		'color lchsr','color lchab','color hsyp', ...
		'value','luma','lumac','lightness','intensity','arctan','tint','shade','lighten eb','darken eb','fog lighten','fog darken', ...
		};
	bseperatoridx = find(ismember(blendmodestrings,{'████████████','━━━━━━━━━━━━'}));
	bothermode = length(blendmodestrings);

	compmodestrings = {'gimp','████████████','translucent','dissolve','dissolve bn','dissolve zf','dissolve ord','lin dissolve','lin dissolve bn','lin dissolve zf', ...
			'lin dissolve ord','████████████','src over','src atop','src in','src out','dst over','dst atop','dst in','dst out','xor','████████████','other mode'};
	nonscalablecompmodestrings = {'gimp','translucent'};
	cseperatoridx = find(strcmp(compmodestrings,'════════'));
	cothermode = length(compmodestrings);	
	
	% prepare the figure elements
	handles = struct([]);
	figuresetup();
	toggleimagecontrols('off')
end

function figuresetup()
	k = 0.015; % trade height between preview axes and top panel
	l = 0.015; % trade height between listbox and top panel
	m = 0.08; % increase to grow editor panel and shrink listbox
	pw = 180; % panel width in px
	fhm = 0.015;
	
	% FIGURE AND DUMMY OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h1 = figure(...
	'Units','normalized',...
	'MenuBar','none',...
	'Name','imcompose_gui',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'Tag','IMCOMPOSE_GUI');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0 0 0.1 0.1],...
	'String','beep',...
	'visible','off',...
	'Tag','generatordummy',...
	'callback',{@generatenew});

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0 0 0.1 0.1],...
	'String','beep',...
	'visible','off',...
	'Tag','modifierdummy',...
	'callback',@modifylayer);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	axes(...
	'Parent',h1,...
	'Position',[fhm 0.0202702702702703 1-pw-2*fhm-0.01 0.911],...
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
	'Tag','axes1',...
	'Visible','on');

	axes(...
	'Parent',h1,...
	'Position',[1-pw-fhm 0.0191441441441441 pw 0.2466-k],...
	'CameraPosition',[0.5 0.5 9.16025403784439],...
	'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
	'Color',get(0,'defaultaxesColor'),...
	'ColorOrder',get(0,'defaultaxesColorOrder'),...
	'LooseInset',[0.793265306122449 0.401975308641975 0.57969387755102 0.274074074074074],...
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
	'buttondownfcn',@ax2_CBF,...
	'Visible','on');


	% LISTBOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[1-pw-fhm 0.538288-k+m pw 0.4155405-l-m],...
	'String',{  'Layers' },...
	'Style','listbox',...
	'Value',1,...
	'Tag','layerlist',...
	'tooltipstring','<html>Click to select layer<br>Click preview image to toggle single-layer view</html>',...
	'callback',@layerlist_CBF);

	% TOP PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	toppanel = uipanel(...
	'Parent',h1,...
	'Title',blanks(0),...
	'Tag','toppanel',...
	'Clipping','on',...
	'Position',[1-pw-fhm 0.96-k-l pw 0.03+k+l]);
	
	% dummy top panel
	uipanel(...
	'Parent',h1,...
	'Title',blanks(0),...
	'Tag','dummytoppanel',...
	'Clipping','on',...
	'visible','off',...
	'Position',[1-pw-fhm 0.96-k-l pw 0.03+k+l]);

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'Position',[0.02 0.55 0.9 0.4],...
	'String','Invert Display',...
	'Style','checkbox',...
	'TooltipString','Use this if using Matlab on an inverted X display.',...
	'value',invertdisplay,...
	'Tag','invertcheckbox',...
	'callback',@invertcheckbox_CBF);

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.02 0.1 0.55 0.4],...
	'String','Compose',...
	'TooltipString','compose from modified layers',...
	'Tag','composebutton',...
	'callback',@composebutton_CBF);

	uicontrol(...
	'Parent',toppanel,...
	'Units','normalized',...
	'Position',[0.62 0.1 0.3 0.4],...
	'String','Auto',...
	'Style','checkbox',...
	'value',autocompose,...
	'TooltipString','automatically compose image and display preview after parameter adjustment',...
	'Tag','autocomposecheckbox',...
	'callback',@autocomposecheckbox_CBF);

	% EDITOR PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	h13 = uipanel(...
	'Parent',h1,...
	'Title','Edit Layer',...
	'Tag','editorpanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-pw-fhm 0.27702702-k pw 0.259009+m]);
	
	dpl = uipanel(...
	'Parent',h1,...
	'Title','Empty Project',...
	'Tag','dummyeditorpanel',...
	'Clipping','on',...
	'visible','off',...
	'Position',[1-pw-fhm 0.27702702-k pw 0.259009+m]);

	uicontrol(...
	'Parent',dpl,...
	'Units','normalized',...
	'FontSize',10,...
	'HorizontalAlignment','center',...
	'Position',[0.0602409638554217 0.2 0.897590361445783 0.6],...
	'String','Import layers from the workspace to begin a new composition.',...
	'Style','text',...
	'Tag','opacitysliderlabel');

	vertscale = 0.9/1.07;
	bh = 0.08*vertscale;
	lh = 0.05*vertscale;
	vp = 0.02*vertscale;
	hm = 0.06;
	vm = 0.03*vertscale;
	
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[hm vm+9*bh+7*vp+4*lh 1-2*hm bh],...
	'String',blanks(0),...
	'Style','popupmenu',...
	'Value',1,...
	'Tag','layermodemenu',...
	'TooltipString','select color blending mode',...
	'callback',@layermodemenu_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[hm vm+9*bh+7*vp+4*lh 1-2*hm bh],...
	'String','',...
	'Style','edit',...
	'TooltipString','manually enter blendmode',...
	'Value',1,...
	'Tag','layermodemanualbox',...
	'callback',@layermodemanualbox_CBF,...
	'visible','off');

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[hm vm+8*bh+6*vp+3*lh 1-2*hm bh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','scaling parameter AMOUNT for blendmode (see help IMBLEND)',...
	'Value',1,...
	'Tag','amountbox',...
	'callback',@amountbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[hm vm+9*bh+6*vp+3*lh 0.44 lh],...
	'String','Amount',...
	'Style','text',...
	'Tag','text3');

	cbw = 0.295;
	cbh = 0.7*bh;
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[hm vm+7*bh+6*vp+3*lh cbw cbh],...
	'String','INV',...
	'Style','checkbox',...
	'TooltipString','invert this blend operation',...
	'Tag','layerinvertcheckbox',...
	'callback',@layerinvertcheckbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[hm+cbw vm+7*bh+6*vp+3*lh cbw cbh],...
	'String','TRP',...
	'Style','checkbox',...
	'TooltipString','transpose this blend operation',...
	'Tag','layertransposecheckbox',...
	'callback',@layertransposecheckbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[hm+2*cbw vm+7*bh+6*vp+3*lh cbw cbh],...
	'String','CMP',...
	'Style','checkbox',...
	'TooltipString','complement this blend operation',...
	'Tag','layercomplementcheckbox',...
	'callback',@layercomplementcheckbox_CBF);

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[hm vm+6*bh+5*vp+3*lh 1-2*hm bh],...
	'String',blanks(0),...
	'Style','popupmenu',...
	'Value',1,...
	'Tag','compmodemenu',...
	'TooltipString','select alpha blending/compositing mode',...
	'callback',@compmodemenu_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[hm vm+6*bh+5*vp+3*lh 1-2*hm bh],...
	'String','',...
	'Style','edit',...
	'TooltipString','manually enter composition mode',...
	'Value',1,...
	'Tag','compmodemanualbox',...
	'callback',@compmodemanualbox_CBF,...
	'visible','off');

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[hm vm+5*bh+4*vp+2*lh 1-2*hm bh],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','thresholding parameter CAMOUNT for composition mode (see help IMBLEND)',...
	'Value',1,...
	'Tag','camountbox',...
	'callback',@camountbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[hm vm+6*bh+4*vp+2*lh 0.44 lh],...
	'String','Amount',...
	'Style','text',...
	'Tag','text3');

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[hm vm+4*bh+3*vp+lh 1-2*hm bh],...
	'String',{  'Slider' },...
	'Style','slider',...
	'Value',1,...
	'Tag','opacityslider',...
	'callback',@opacityslider_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','right',...
	'Position',[1-hm-0.187 vm+5*bh+3*vp+lh 0.187 lh],...
	'String','',...
	'Style','text',...
	'Tag','opacitylabel');
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[hm vm+5*bh+3*vp+lh 0.44 lh],...
	'String','Opacity',...
	'Style','text',...
	'Tag','opacitysliderlabel');


	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[hm vm+3*bh+2*vp 1-2*hm bh],...
	'String','',...
	'Style','edit',...
	'TooltipString','<html>Apply an arbitrary operation to modify this layer<br/>@layer selects all channels of this layer<br/>@layer(chans) processes only the specified channels<br/>e.g. imtweak(@layer(1:3),''lchab'',[1 1 0.25])<br/>These operate on a copy of the layer and can be<br/>undone unlike the ''modify layer'' method<br/>Clear field to revert changes.</html>',...
	'Tag','layermod',...
	'callback',@layermod_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[hm vm+4*bh+2*vp 0.5 lh],...
	'String','Modifier',...
	'Style','text',...
	'Tag','text4');


	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.343373493975904 vm+2*bh+vp 0.367469879518072 bh],...
	'String','Duplicate',...
	'TooltipString','duplicate this layer',...
	'Tag','layerduplicatebutton',...
	'callback',@layerduplicatebutton_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.343373493975904 vm+bh+vp 0.367469879518072 bh],...
	'String','Delete',...
	'TooltipString','delete this layer',...
	'Tag','deletelayerbutton',...
	'callback',@deletelayerbutton_CBF);

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.71084337349397 vm+2*bh+vp 0.246987951807229 bh],...
	'String','▲',...
	'TooltipString','move layer up',...
	'Tag','layerupbutton',...
	'callback',@layerupbutton_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'Position',[0.710843373493976 vm+bh+vp 0.246987951807229 bh],...
	'String','▼',...
	'TooltipString','move layer down',...
	'Tag','layerdownbutton',...
	'callback',@layerdownbutton_CBF);

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.0421686746987952 vm+2*bh+vp/2 0.295180722891566 bh],...
	'String','Hide',...
	'Style','checkbox',...
	'TooltipString','disable this layer',...
	'Tag','hidelayercheckbox',...
	'callback',@hidelayercheckbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.0421686746987952 vm+bh+vp/2 0.295180722891566 bh],...
	'String','No α',...
	'Style','checkbox',...
	'TooltipString','disable this layer''s alpha channel',...
	'Tag','disablealphacheckbox',...
	'callback',@disablealphacheckbox_CBF);
	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.0421686746987952 vm+vp/2 0.4 bh],...
	'String','Verbose',...
	'Style','checkbox',...
	'TooltipString',sprintf('enable verbose output\nused with ''bomb'' modes'),...
	'Tag','verbosecheckbox',...
	'callback',@verbosecheckbox_CBF);

	uicontrol(...
	'Parent',h13,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.45 vm 0.5 bh],...
	'String','Modify Layer',...
	'TooltipString','interactively modify this layer',...
	'Tag','modifylayerbutton',...
	'callback',@modifylayerbutton_CBF);

	% IMPORT/EXPORT CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[0.0150501672240803 0.943693693693694 0.134615384615385 0.0236486486486487],...
	'String',blanks(0),...
	'Style','edit',...
	'TooltipString','name of imageset in workspace to import',...
	'Tag','importvarbox');

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.157190635451505 0.942567567567568 0.0677257525083612 0.0236486486486487],...
	'String','Replace',...
	'TooltipString','replace the current image',...
	'Tag','replaceimage',...
	'callback',@replaceimage_CBF);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.157190635451505 0.967342342342342 0.0677257525083612 0.0236486486486487],...
	'String','Insert',...
	'TooltipString','insert this image above the current layer',...
	'Tag','insertimage',...
	'callback',@insertimage_CBF);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[0.0175585284280936 0.971846846846847 0.12876254180602 0.0146396396396397],...
	'String','Import from workspace',...
	'Style','text',...
	'Tag','text7');

	osh = 0.23;
	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'BackgroundColor',[1 1 1],...
	'HorizontalAlignment','left',...
	'Position',[0.0150501672240803+osh 0.943693693693694 0.134615384615385 0.0236486486486487],...
	'String','composedimage',...
	'Style','edit',...
	'TooltipString','name of exported image',...
	'Tag','exportvarbox',...
	'callback',@exportimage_CBF);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[0.157190635451505+osh 0.942567567567568 0.0677257525083612 0.0236486486486487],...
	'String','Export',...
	'TooltipString','export the current composition',...
	'Tag','exportimage',...
	'callback',@exportimage_CBF);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[0.0175585284280936+osh 0.971846846846847 0.12876254180602 0.0146396396396397],...
	'String','Export to workspace',...
	'Style','text',...
	'Tag','text8');
	
	% IMAGE GENERATION CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	bw = 0.084;
	bh = 0.024;
	basel = 0.943;
	
	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[1-pw-fhm-0.01-bw basel+bh bw bh],...
	'String','New From Visible',...
	'TooltipString','create a new layer from the composed image',...
	'Tag','newfromvis',...
	'callback',@newfromvis_CBF);

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'FontSize',8,...
	'Position',[1-pw-fhm-0.01-bw basel bw bh],...
	'String','Generate Layer',...
	'TooltipString','create a new layer from scratch',...
	'Tag','generatelayer',...
	'callback',@generatelayer_CBF);

	% IMAGE-LEVEL EDITING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[1-pw-fhm-2*0.01-2*bw basel bw/2 bh],...
	'String','↕',...
	'TooltipString','flip entire image up/down',...
	'Tag','imageflipudbutton',...
	'callback',{@imagetrans,'flipud'});

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[1-pw-fhm-2*0.01-1.5*bw basel bw/2 bh],...
	'String','↔',...
	'TooltipString','flip entire image left/right',...
	'Tag','imagefliplrbutton',...
	'callback',{@imagetrans,'fliplr'});

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[1-pw-fhm-2*0.01-2*bw basel+bh bw/2 bh],...
	'String','↺',...
	'TooltipString','rotate image CCW',...
	'Tag','imagerotccwbutton',...
	'callback',{@imagetrans,'rotccw'});

	uicontrol(...
	'Parent',h1,...
	'Units','normalized',...
	'Position',[1-pw-fhm-2*0.01-1.5*bw basel+bh bw/2 bh],...
	'String','↻',...
	'TooltipString','rotate image CW',...
	'Tag','imagerotcwbutton',...
	'callback',{@imagetrans,'rotcw'});



	% all child object handles in figure 
	handles = guihandles(h1);
end


%% CBF REDIRECTION
function exportimage_CBF(objh,event)
	wsvariablename = get(handles.exportvarbox,'String');
	if isempty(wsvariablename); return; end
	
	assignin('base',wsvariablename,composed);
end

function newfromvis_CBF(objh,event)
	if numframes == 0; return; end
	newfromvisible();
end

function generatelayer_CBF(objh,event)
	if numframes == 0; return; end
	generatinglayer = selectedlayer;
	notgeneratedyet = 1;
	if invertdisplay
		imgenerate(s,'imcomposemode','invert');
	else
		imgenerate(s,'imcomposemode');
	end
end

function modifylayerbutton_CBF(objh,event)
	if numframes == 0; return; end
	modifyinglayer = selectedlayer;
	
	% all image channels including alpha are passed!
	if invertdisplay
		immodify(imagelayers(:,:,:,selectedlayer),'imcomposemode','invert');
	else
		immodify(imagelayers(:,:,:,selectedlayer),'imcomposemode');
	end
end

function insertimage_CBF(objh,event)
	insertimage();
end

function replaceimage_CBF(objh,event)
	replaceimage();
end

function viewcontrol(hobj,event,whichop)
	if strcmp(whichop,'stepback') && strcmp(vcmode,'stepback')
		whichop = 'zoom';
	end
	vcmode = whichop;
	updatefig('main');
end

function opacityslider_CBF(objh,event)
	val = get(objh,'value');
	updateparams('opacity',val);
	set(handles.opacitylabel,'string',sprintf('%1.2f',val));
end

function layerlist_CBF(objh, event)
	selectedlayer = get(objh,'Value');
	updateeditor();
	updatefig('preview');
	if solo
		updatefig('main');
	end
end
	
function amountbox_CBF(objh,event)
	updateparams('amount',get(objh,'string'));
end

function camountbox_CBF(objh,event)
	updateparams('camount',get(objh,'string'));
end

function layermod_CBF(objh,event)
	updateparams('layermodifier',get(objh,'string'));
end

function layermodemenu_CBF(objh,event)
	selectedmode = get(objh,'value');
	if ~ismember(selectedmode,bseperatoridx)
		if selectedmode ~= bothermode
			updateparams('blendmode',selectedmode);
		else
			set(handles.layermodemenu,'visible','off')
			set(handles.layermodemanualbox,'visible','on')
		end
		
		if strismember(blendmodestrings{selectedmode},nonscalablemodestrings)
			set(handles.amountbox,'enable','off')
		else
			set(handles.amountbox,'enable','on')
		end
	end
end

function layermodemanualbox_CBF(objh,event)
	modestring = get(objh,'string');
	if ~isempty(modestring{1})
		updateparams('blendmode',modestring);
	else 
		updateparams('blendmode',1);
		set(handles.layermodemanualbox,'visible','off')
		set(handles.layermodemenu,'value',1)
		set(handles.layermodemenu,'visible','on')
	end
end

function compmodemenu_CBF(objh,event)
	selectedmode = get(objh,'value');
	if ~ismember(selectedmode,cseperatoridx)
		if selectedmode ~= cothermode
			updateparams('compmode',selectedmode);
		else
			set(handles.compmodemenu,'visible','off')
			set(handles.compmodemanualbox,'visible','on')
		end
		if strismember(compmodestrings{selectedmode},nonscalablecompmodestrings)
			set(handles.camountbox,'enable','off')
		else
			set(handles.camountbox,'enable','on')
		end
	end
end

function compmodemanualbox_CBF(objh,event)
	modestring = get(objh,'string');
	if ~isempty(modestring{1})
		updateparams('compmode',modestring);
	else 
		updateparams('compmode',1);
		set(handles.compmodemanualbox,'visible','off')
		set(handles.compmodemenu,'value',1)
		set(handles.compmodemenu,'visible','on')
	end
end

function deletelayerbutton_CBF(objh,event)
	layeraction('delete');
end

function layerduplicatebutton_CBF(objh,event)
	layeraction('duplicate');
end

function layerdownbutton_CBF(objh,event)
	layeraction('movedown');
end

function layerupbutton_CBF(objh,event)
	layeraction('moveup');
end

function hidelayercheckbox_CBF(objh,event)
	updateparams('hidden',get(objh,'value'));
end

function layerinvertcheckbox_CBF(objh,event)
	updateparams('layerinvert',get(objh,'value'));
end

function layertransposecheckbox_CBF(objh,event)
	updateparams('layertranspose',get(objh,'value'));
end

function layercomplementcheckbox_CBF(objh,event)
	updateparams('layercomplement',get(objh,'value'));
end

function verbosecheckbox_CBF(objh,event)
	updateparams('layerverbose',get(objh,'value'));
end

function disablealphacheckbox_CBF(objh,event)
	val = get(objh,'value');
	if val == 1
		processimage('alpha off',selectedlayer);
	else
		processimage('alpha on',selectedlayer);
	end
	updateparams('disablealpha',val);
end

function invertcheckbox_CBF(objh,event)
	invertdisplay = get(objh,'value');
	updatefig('main');
	updatefig('preview');
end

function autocomposecheckbox_CBF(objh,event)
	autocompose = get(objh,'value');
end

function composebutton_CBF(objh,event)
	composeimage();
	updatefig('main');
end

function ax2_CBF(objh,event)
	if solo
		solo = false;
	else
		solo = true;
	end
	updatefig('main');
	updatefig('preview');
end

%% VISIBILITY & VIEW CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleimagecontrols(state)
	switch state
		case 'on'
			set(handles.dummyeditorpanel,'visible','off')
			set(handles.dummytoppanel,'visible','off')
		case 'off'
			set(handles.dummyeditorpanel,'visible','on')
			set(handles.dummytoppanel,'visible','on')
	end
	set(handles.editorpanel,'visible',state)
	set(handles.toppanel,'visible',state)
	set(handles.newfromvis,'enable',state)
	set(handles.generatelayer,'enable',state)
	set(handles.imageflipudbutton,'enable',state)
	set(handles.imagefliplrbutton,'enable',state)
	set(handles.imagerotcwbutton,'enable',state)
	set(handles.imagerotccwbutton,'enable',state)
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

%% REPLACE IMAGE ON IMPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function replaceimage()
	h = handles.axes1;
	if strcmpi(get(h,'type'),'image')
		h = get(h,'parent');
	end
	
	wsvariablename = get(handles.importvarbox,'String');
	if isempty(wsvariablename); return; end
	
	selectedlayer = 1;
	try
		imagelayers = imcast(evalin('base',wsvariablename),wclass);
	catch
		errorstr = 'Import error: You sure that image exists?';
		errordlg(errorstr,'Import Error','modal')
		return;
	end
	
	set(h,'xlim',[0 1],'ylim',[0 1]);
	
	preprocessed = imagelayers;
	numframes = size(imagelayers,4);
	hasalpha = 1-mod(size(imagelayers,3),2);
	s = [size(imagelayers,1) size(imagelayers,2)];
	opacity = ones([numframes 1]);
	hidden = zeros([numframes 1]);
	disablealpha = hidden;
	blendmode = ones([numframes 1]);
	blendmodelabel = repmat({{'normal'}},[numframes 1]); 
	compmode = ones([numframes 1]);
	compmodelabel = repmat({{'gimp'}},[numframes 1]); 
	% amount is always numeric, but not all values are scalar
	amount = repmat({1},[numframes 1]);
	camount = repmat({1},[numframes 1]);
	% layermodifier is an arbitrary command string
	layermodifier = repmat({{}},[numframes 1]); 
	layerinvert = zeros([numframes 1]);
	layertranspose = zeros([numframes 1]);
	layercomplement = zeros([numframes 1]);
	layerverbose = zeros([numframes 1]);
	
	set(handles.layermodemenu,'String',blendmodestrings);
	set(handles.compmodemenu,'String',compmodestrings);
	toggleimagecontrols('on')

	updatelayerlist(); 
	updateeditor();
	updatefig('preview');
	if autocompose
		composeimage();
		updatefig('main','reset');
	end
end

%% PROCESS IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processimage(target,whichlayer)
	% should process only when layermodifier{f} is changed
	switch target
		case 'modify'
			thismod = layermodifier{whichlayer}{1};
			if numel(thismod) == 0
				preprocessed(:,:,:,whichlayer) = imagelayers(:,:,:,whichlayer);
			else
				preprocessed(:,:,:,whichlayer) = imagelayers(:,:,:,whichlayer); % reset layer first
				if ~isempty(strfind(thismod,'@layer('))
					chanstart = strfind(thismod,'@layer(');
					chanend = strfind(thismod,')');
					chanend = chanend(chanend > chanstart);
					chanstring = thismod((chanstart+7):(chanend(1)-1));
					thismod = strrep(thismod,thismod(chanstart:chanend),['imagelayers(:,:,' chanstring ',whichlayer)']);
					thismodlayer = eval(thismod);
					% test the geometry and adjust if possible
					[thismodlayer validlayer] = testgeometry(thismodlayer,numel(eval(chanstring)));
					if validlayer
						preprocessed(:,:,str2num(chanstring),whichlayer) = thismodlayer;
					end
				else
					thismod = strrep(thismod,'@layer','imagelayers(:,:,:,whichlayer)');
					thismodlayer = eval(thismod);
					[thismodlayer validlayer] = testgeometry(thismodlayer,size(imagelayers,3));
					if validlayer
						preprocessed(:,:,:,whichlayer) = thismodlayer;
					end
				end
			end
			
		case 'alpha on'
			[cc ac] = chancount(imagelayers(:,:,:,whichlayer));
			if ac
				preprocessed(:,:,(cc+1),whichlayer) = imagelayers(:,:,(cc+1),whichlayer);
			end
		case 'alpha off'
			[cc ac] = chancount(imagelayers(:,:,:,whichlayer));
			if ac
				imclass = class(preprocessed);
				if strcmp(imclass,'uint8')
					preprocessed(:,:,(cc+1),whichlayer) = 255;
				elseif strismember(imclass,{'double','single','logical'})
					preprocessed(:,:,(cc+1),whichlayer) = 1;
				end
			end
	end
	
	updatefig('preview');
end

function [outlayer doesit] = testgeometry(thismodifiedlayer,expectednc)
	doesit = 1;
	% check height, width
	for c = 1:2
		if size(thismodifiedlayer,c) ~= size(imagelayers,c)
			doesit = 0;
			break
		end
	end
	
	% check channel count
	ena = mod(expectednc,2) == 0;
	enc = expectednc-ena;
	[nc na] = chancount(thismodifiedlayer);
	if (enc+ena) == (nc+na)
		outlayer = thismodifiedlayer;
	else
		% if base image is mono and an image with color data is received
		if enc == 1 && nc == 3
			outlayer = mono(thismodifiedlayer(:,:,1:nc),'y');
		% if base image is rgb and input is mono (1-channel mono)
		elseif enc == 3 && nc == 1
			outlayer = repmat(thismodifiedlayer(:,:,1:nc),[1 1 3]);
		elseif enc == nc
			outlayer = thismodifiedlayer(:,:,1:nc);
		else
			doesit = 0;
		end

		% what if base/new alpha mismatch?
		if ena == 1 && na == 0
			outlayer = cat(3,outlayer,ones(imsize(thismodifiedlayer,2)));
		elseif ena == 0 && na == 1
			% do nothing, stripping alpha
		elseif ena == 1 && na == 1
			outlayer = cat(3,outlayer,thismodifiedlayer(:,:,end));
		elseif ena ~= na
			doesit = 0;
		end
	end
	
	if ~doesit
		erstr1 = sprintf('IMCOMPOSE: Merging modified images of altered dimensions is not currently supported\n');
		erstr2 = sprintf('Modified layer: [%g %g %g] (height x width x channels)\n',size(thismodifiedlayer,1),size(thismodifiedlayer,2),size(thismodifiedlayer,3));
		erstr3 = sprintf('Unmodified layer: [%g %g %g] (height x width x channels)',s(1),s(2),size(imagelayers,3));
		errorstr = [erstr1 erstr2 erstr3];
		errordlg(errorstr,'Modify Error','modal')
		return;
	end
end

%% COMPOSE IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function composeimage()
	% find highest opaque layer and compose up from there
	% this avoids composing buried layers for no reason
	baselayer = numframes;
	for f = 1:1:numframes
		bmode = blendmodelabel{f}{1};
		cmode = compmodelabel{f}{1};
		
		isopaqueblend = (strcmp(bmode,'normal') && opacity(f) == 1 && ~hidden(f));
		solidalpha = ((hasalpha && (~any(any(imagelayers(:,:,end,f) ~= 1)) || disablealpha(f) == 1)) || ~hasalpha);
		isopaquecomp = strismember(cmode,{'gimp','srcover'});
			
% 		% this totally doesn't work with the way the compositing is done
% 		% we'd need to preprocess these sorts of layers in order to keep bg from being collapsed
% 		% some modes can generate alpha content even if bg is opaque
% 		opaqueblendoverride=0;
% 		if f>1
% 			fgbmode=blendmodelabel{f-1}; fgbmode=fgbmode{1}; fgbmode=fgbmode(fgbmode~=' ');
% 			opaqueblendoverride=strcmp(fgbmode,'nearfga') || strcmp(fgbmode,'farfga');
% 		end
% 		
% 		% still need to process base layer if function transforms are applied
% 		% if this is the actual bottom layer, we'd need to substitute a padding layer
% 		[f isopaqueblend solidalpha isopaquecomp ~opaqueblendoverride]
				
		if isopaqueblend && solidalpha && isopaquecomp
			baselayer = f;
			break;
		end
	end
	
	firstframe = true;
	for f = baselayer:-1:1;
		% ignoring hidden flag on baselayer is a workaround to avoid unexpected handling of non-opaque modes on bottom layer in non-alpha images
		% the choices are: 
		%   force image expansion (costly and not trivially reversible; composition shouldn't be something that causes structural changes to the source image)
		%   ignore hidden flag on base layer (do we ever really need to hide the only opaque layer?)
		%   ignore blendmode on layer above and use as if opaque (this is what gimp does when no alpha is present)
				
		if hidden(f) ~= 1 || (hidden(f) == 1 && f == baselayer) 
			fg = preprocessed(:,:,:,f);
			if firstframe
				bg = fg;
				firstframe = false;
			else
				if blendmode(f) == bothermode
					thismode = blendmodelabel{f}{1};
				else
					thismode = blendmodestrings{blendmode(f)};
				end
				if compmode(f) == cothermode
					thiscmode = compmodelabel{f}{1};
				else
					thiscmode = compmodestrings{compmode(f)};
				end
				
				xformkeys = {};
				if layerinvert(f)
					xformkeys = [xformkeys,'invert'];
				end
				if layertranspose(f)
					xformkeys = [xformkeys,'transpose'];
				end
				if layercomplement(f)
					xformkeys = [xformkeys,'complement'];
				end
				
				if layerverbose(f)
					fprintf('Layer %d ',f)
					bg = imblend(fg,bg,opacity(f),thismode,amount{f},thiscmode,camount{f},xformkeys{:},'verbose');
				else
					bg = imblend(fg,bg,opacity(f),thismode,amount{f},thiscmode,camount{f},xformkeys{:});
				end
			end
		end
	end

	% composed is the full image with or without alpha
	% keep it this way for exporting
	composed = bg;
end

%% UPDATE IMAGE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig(whichaxis,keystring)
	if ~exist('keystring','var'); keystring = ''; end
	
	switch whichaxis
		% show composition
		case 'main'
			if solo
				if isempty(preprocessed)
					imagetoshow = zeros([s 2]);
				else
					imagetoshow = preprocessed(:,:,:,selectedlayer);
				end
			else
				if isempty(composed)
					imagetoshow = zeros([s 2]);
				else
					imagetoshow = composed(:,:,:);
				end
			end
			
			h = handles.axes1;
			if strcmpi(get(h,'type'),'image')
				h = get(h,'parent');
			end
		% or just show current layer
		case 'preview'
			if ~solo
				if isempty(preprocessed)
					imagetoshow = zeros([s 2]);
				else
					imagetoshow = preprocessed(:,:,:,selectedlayer);
				end
			else
				if isempty(composed)
					imagetoshow = zeros([s 2]);
				else
					imagetoshow = composed(:,:,:);
				end
			end
			
			h = handles.axes2;
			if strcmpi(get(h,'type'),'image')
				h = get(h,'parent');
			end
	end
	
	% don't need to eat up memory for display
	imagetoshow = imcast(alphasafe(imagetoshow),'single');
	
	if invertdisplay
		imagetoshow = 1-imagetoshow;
	end

	switch whichaxis
		case 'main'
			% fetch viewport extents before clobbering them
			zoomextents = [get(h,'ylim'); get(h,'xlim')];	
			k = safeimshow(imagetoshow,h);

			if strcmp(keystring,'reset')
				% reset viewport to optimal fit
				akzoom(h) 
			elseif all(all(zoomextents ~= [0 1;0 1]))
				% restore last viewport
				set(h,'xlim',zoomextents(2,:),'ylim',zoomextents(1,:));
			end
			
			set(k,'tag','axes1')
			
		case 'preview'
			k = imshow(imagetoshow,'border','tight','parent',h);
			set(k,'tag','axes2')
			set(k,'buttondownfcn',@ax2_CBF)
	end
	% axes mode is 'replace' so that imshow-tight works correctly
	% this means we lose access to the parent by tag after the first 
	% image is placed and need to find it via the image object itself
end

%% UPDATE LAYER EDITOR PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateeditor()
	thisbm = blendmode(selectedlayer);
	if thisbm == bothermode
		set(handles.layermodemanualbox,'visible','on')
		set(handles.layermodemenu,'visible','off')
	else
		set(handles.layermodemanualbox,'visible','off')
		set(handles.layermodemenu,'visible','on')
	end
	
	thiscm = compmode(selectedlayer);
	if thiscm == cothermode
		set(handles.compmodemanualbox,'visible','on')
		set(handles.compmodemenu,'visible','off')
	else
		set(handles.compmodemanualbox,'visible','off')
		set(handles.compmodemenu,'visible','on')
	end
	
	if strismember(blendmodestrings{thisbm},nonscalablemodestrings)
		set(handles.amountbox,'enable','off')
	else
		set(handles.amountbox,'enable','on')
	end
	
	if strismember(compmodestrings{thiscm},nonscalablecompmodestrings)
		set(handles.camountbox,'enable','off')
	else
		set(handles.camountbox,'enable','on')
	end
	
	if ~hasalpha
		set(handles.disablealphacheckbox,'enable','off')
	else
		set(handles.disablealphacheckbox,'enable','on')
	end
	
	thisamt = amount{selectedlayer};
	set(handles.amountbox,'String',mat2str(thisamt));
	thiscamt = camount{selectedlayer};
	set(handles.camountbox,'String',mat2str(thiscamt));
	
 	set(handles.opacityslider,'Value',opacity(selectedlayer));
	set(handles.opacitylabel,'string',sprintf('%1.2f',opacity(selectedlayer)));
 	set(handles.hidelayercheckbox,'Value',hidden(selectedlayer));
 	set(handles.disablealphacheckbox,'Value',disablealpha(selectedlayer));
	set(handles.verbosecheckbox,'Value',layerverbose(selectedlayer));
	
	set(handles.layermodemenu,'Value',thisbm);
 	set(handles.layermodemanualbox,'String',blendmodelabel{selectedlayer});
	set(handles.compmodemenu,'Value',thiscm);
 	set(handles.compmodemanualbox,'String',compmodelabel{selectedlayer});
	
	set(handles.layermod,'String',layermodifier{selectedlayer});
end

%% UPDATE LISTBOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatelayerlist()
	listlabels = {};
	for f = 1:numframes
		thismode = blendmodelabel{f}{1};
		% these don't seem to work in my install of R2009b
		%if hidden(f); vismark = '▄'; else vismark = '▀'; end
		%if disablealpha(f); amark = '▄'; else amark = '▀'; end
		if hidden(f); vismark = '⚪'; else vismark = '⚫'; end
		if disablealpha(f); amark = '⚪'; else amark = '⚫'; end
		% ◻◼⚪⚫⬤◯
		
		switch round(opacity(f)*8)
			case 8
				opmark = '█';
			case 7
				opmark = '▇';
			case 6
				opmark = '▆';
			case 5
				opmark = '▅';	
			case 4
				opmark = '▄';	
			case 3
				opmark = '▃';	
			case 2
				opmark = '▂';
			case 1
				opmark = '▁';	
			case 0
				opmark = '▁';
		end
		listlabels = cat(2,listlabels,{sprintf('%s %s %s %02d %s',vismark,amark,opmark,f,thismode)});
		%listlabels=cat(2,listlabels,{sprintf('%s %s %02d %1.2f %s',vismark,opmark,f,opacity(f),thismode)});
	end
	
	set(handles.layerlist,'value',selectedlayer);
	set(handles.layerlist,'String',listlabels);
end

%% UPDATE PARAMETER ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateparams(fieldname,fieldvalue)
	switch fieldname
		case 'blendmode'
			if isnumeric(fieldvalue)
				blendmode(selectedlayer) = fieldvalue;
				blendmodelabel{selectedlayer} = blendmodestrings(fieldvalue);
			else
				if ~iscell(fieldvalue)
					fieldvalue = {fieldvalue};
				end
				blendmodelabel{selectedlayer} = fieldvalue;
				blendmode(selectedlayer) = bothermode;
			end
			updatelayerlist();
		case 'compmode'
			if isnumeric(fieldvalue)
				compmode(selectedlayer) = fieldvalue;
				compmodelabel{selectedlayer} = compmodestrings(fieldvalue);
			else
				if ~iscell(fieldvalue)
					fieldvalue = {fieldvalue};
				end
				compmodelabel{selectedlayer} = fieldvalue;
				compmode(selectedlayer) = cothermode;
			end
		case 'opacity'
			opacity(selectedlayer) = fieldvalue;
			updatelayerlist();
		case 'hidden'
			hidden(selectedlayer) = fieldvalue;
			updatelayerlist();
		case 'layerverbose'
			layerverbose(selectedlayer) = fieldvalue;
		case 'layerinvert'
			layerinvert(selectedlayer) = fieldvalue;
		case 'layertranspose'
			layertranspose(selectedlayer) = fieldvalue;
		case 'layercomplement'
			layercomplement(selectedlayer) = fieldvalue;
		case 'disablealpha'
			disablealpha(selectedlayer) = fieldvalue;
			updatelayerlist();
		case 'amount'
			amount{selectedlayer} = evalin('base',fieldvalue);
		case 'camount'
			camount{selectedlayer} = evalin('base',fieldvalue);
		case 'layermodifier'
			if ~iscell(fieldvalue)
				fieldvalue = {fieldvalue};
			end
			layermodifier{selectedlayer} = fieldvalue;
			processimage('modify',selectedlayer);
	end
	
	if autocompose
		composeimage();
		updatefig('main');
	end
end

%% LAYER ACTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function layeraction(action)
	switch action
		case 'delete'
			if numframes == 1	
				selectedlayer = 1;
				numframes = 0;
				hasalpha = 0;
				composed = [];
				imagelayers = [];
				preprocessed = [];
				opacity = [];
				hidden = [];
				disablealpha = [];
				layerverbose = [];
				amount = [];
				camount = [];
				blendmode = [];
				blendmodelabel = [];
				compmode = [];
				compmodelabel = [];
				layermodifier = [];
				
				layerinvert = [];
				layertranspose = [];
				layercomplement = [];
				
				toggleimagecontrols('off')
				set(handles.layerlist,'String','');
				updatefig('main','reset');
				updatefig('preview');			
				return;
			else
				sequence = [1:(selectedlayer-1) (selectedlayer+1):numframes];
				numframes = numframes-1;
				sequencelayers(sequence);
				selectedlayer = min(numframes,selectedlayer);
				
				updatelayerlist();
				updatefig('preview');
				updateeditor();
			end
		case 'moveup'
			if selectedlayer == 1; return; end
			sequence = [1:(selectedlayer-2) selectedlayer (selectedlayer-1) (selectedlayer+1):numframes];
			sequencelayers(sequence);
			selectedlayer = selectedlayer-1;
			updatelayerlist();
			
		case 'movedown'
			if selectedlayer == numframes; return; end
			sequence = [1:(selectedlayer-1) (selectedlayer+1) selectedlayer (selectedlayer+2):numframes];
			sequencelayers(sequence);
			selectedlayer = selectedlayer+1;
			updatelayerlist();
			
		case 'duplicate'
			sequence = [1:(selectedlayer-1) selectedlayer selectedlayer (selectedlayer+1):numframes];
			numframes = numframes+1;
			sequencelayers(sequence);
			updatelayerlist();	
			
	end
	
	if autocompose
		composeimage();
		updatefig('main');
	end
end

function sequencelayers(sequence)
	opacity = reshape(opacity(sequence),numframes,1);
	hidden = reshape(hidden(sequence),numframes,1);
	disablealpha = reshape(disablealpha(sequence),numframes,1);
	layerverbose = reshape(layerverbose(sequence),numframes,1);
	amount = reshape(amount(sequence),numframes,1);
	camount = reshape(camount(sequence),numframes,1);
	layermodifier = reshape(layermodifier(sequence),numframes,1);
	
	layerinvert = reshape(layerinvert(sequence),numframes,1);
	layertranspose = reshape(layertranspose(sequence),numframes,1);
	layercomplement = reshape(layercomplement(sequence),numframes,1);
	
	blendmode = reshape(blendmode(sequence),numframes,1);
	blendmodelabel = reshape(blendmodelabel(sequence),numframes,1);
	compmode = reshape(compmode(sequence),numframes,1);
	compmodelabel = reshape(compmodelabel(sequence),numframes,1);
	
	imagelayers = imagelayers(:,:,:,sequence);
	preprocessed = preprocessed(:,:,:,sequence);
end

%% NEW FROM VISIBLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newfromvisible()
	composeimage();
	
	insertlayers(composed);

	numframes = numframes+1;
	updatelayerlist();
	updatefig('preview');
	updateeditor();
	
	if autocompose
		updatefig('main');
	end
end

%% GENERATE RETURN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is used by imgenerate() externally via a hidden dummy uicontrol object
function generatenew(objh,event,layercontent)
	% check value of notgeneratedyet to see if layer should be inserted or replaced
	% will have to handle channel mismatch here

	% if base image is mono and an image with color data is received
	nnchans = size(layercontent,3);
	nnchans = nnchans-1+mod(nnchans,2);
	newismono = ismono(layercontent(:,:,1:nnchans));
	if size(imagelayers,3)-hasalpha == 1 && ~newismono
		ildata = repmat(imagelayers(:,:,1,:),[1 1 3]);
		ppdata = repmat(preprocessed(:,:,1,:),[1 1 3]);
		if hasalpha
			imagelayers = cat(3,ildata,imagelayers(:,:,2,:));
			preprocessed = cat(3,ppdata,preprocessed(:,:,2,:));
		else
			imagelayers = ildata;
			preprocessed = ppdata;
		end
		disp('expanded arrays to fit a color input')
	% if base image is mono and a 3-ch neutral image is received
	elseif size(imagelayers,3)-hasalpha == 1 && newismono
		if nnchans == 3
			layercontent = layercontent(:,:,1);
		end		
		disp('collapsed grey input to fit grey base image')
	end
	
	% create solid alpha channel if base image has alpha
	if hasalpha
		layercontent = cat(3,layercontent,ones(s));
	end
	
	if notgeneratedyet;
		insertlayers(layercontent);
		notgeneratedyet = 0;

		numframes = numframes+1;
		updatelayerlist();
		updateeditor();
	else
		replacelayer(generatinglayer,layercontent);		
	end
	
	updatefig('preview');
	
	if autocompose
		composeimage();
		updatefig('main');
	end
end

%% MODIFY RETURN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is used by immodify() externally via a hidden dummy uicontrol object
function modifylayer(objh,event,returneddata)
	replacelayer(modifyinglayer,returneddata);
	updatefig('preview');
	
	if autocompose
		composeimage();
		updatefig('main');
	end
end

%% INSERT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function insertimage()
	if isempty(imagelayers); replaceimage(); return; end

	wsvariablename = get(handles.importvarbox,'String');
	if isempty(wsvariablename); return; end

	% this needs to handle composition of dissimilar image sizes
	try
		thisimage = imcast(evalin('base',wsvariablename),wclass);
	catch
		errorstr = 'Import error: You sure that image exists?';
		errordlg(errorstr,'Import Error','modal')
		return;
	end
	thisnumframes = size(thisimage,4);
	
	if s ~= [size(thisimage,1) size(thisimage,2)]
		erstr1 = sprintf('IMCOMPOSE: Merging images of different H,V dimensions is not currently supported\n');
		erstr2 = sprintf('Input image: [%g %g] (height x width)\n',size(thisimage,1),size(thisimage,2));
		erstr3 = sprintf('Base image: [%g %g] (height x width)',s(1),s(2));
		errorstr = [erstr1 erstr2 erstr3];
		%disp(errorstr)
		errordlg(errorstr,'Import Error','modal')
		return;
	end
	
	% if base image is mono and an image with color data is received
	nnchans = size(thisimage,3);
	nnchans = nnchans-1+mod(nnchans,2);
	newhasalpha = (nnchans ~= size(thisimage,3));
	if size(imagelayers,3)-hasalpha == 1 && ~ismono(thisimage(:,:,1:nnchans))
		ildata = repmat(imagelayers(:,:,1,:),[1 1 3]);
		ppdata = repmat(preprocessed(:,:,1,:),[1 1 3]);
		if hasalpha
			imagelayers = cat(3,ildata,imagelayers(:,:,2,:));
			preprocessed = cat(3,ppdata,preprocessed(:,:,2,:));
		else
			imagelayers = ildata;
			preprocessed = ppdata;
		end
	% if base image is rgb and input is mono (1-channel mono)
	elseif size(imagelayers,3)-hasalpha == 3 && nnchans == 1
		if newhasalpha
			thisalpha = thisimage(:,:,end);
			thisimage = cat(3,repmat(thisimage(:,:,1:nnchans),[1 1 3]),thisalpha);
		else
			thisimage = repmat(thisimage(:,:,1:nnchans),[1 1 3]);
		end
	end
	
	% what if base/new alpha mismatch?
	if hasalpha && ~newhasalpha
		newa = ones([size(thisimage,1),size(thisimage,2)]);
		thisimage = cat(3,thisimage,newa);
	elseif ~hasalpha && newhasalpha
		newa = ones([s 1 size(imagelayers,4)]);
		imagelayers = cat(3,imagelayers,newa);
		preprocessed = cat(3,preprocessed,newa);
		hasalpha = 1;
	end
	
	insertlayers(thisimage);
	 
	numframes = numframes+thisnumframes;
	selectedlayer = selectedlayer+thisnumframes;
	updatelayerlist();
	
	if autocompose
		composeimage();
		updatefig('main','reset');
	end
end	
	
%% INSERT LAYERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function insertlayers(thisimage)	
	thisnumframes = size(thisimage,4);
		
	top = 1:(selectedlayer-1);
	bot = selectedlayer:numframes;
	
	opacity = [opacity(top); ones([thisnumframes 1]); opacity(bot)];
	hidden = [hidden(top); zeros([thisnumframes 1]); hidden(bot)];
	disablealpha = [disablealpha(top); zeros([thisnumframes 1]); disablealpha(bot)];
	layerverbose = [layerverbose(top); zeros([thisnumframes 1]); layerverbose(bot)];
	thisamount = repmat({1},[thisnumframes 1]);
	amount = {amount{top},thisamount{:},amount{bot}}';
	camount = {camount{top},thisamount{:},camount{bot}}';
	thislayermodifier = repmat({{}},[thisnumframes 1]); 
	layermodifier = {layermodifier{top},thislayermodifier{:},layermodifier{bot}}';
	
	layerinvert = [layerinvert(top); zeros([thisnumframes 1]); layerinvert(bot)];
	layertranspose = [layertranspose(top); zeros([thisnumframes 1]); layertranspose(bot)];
	layercomplement = [layercomplement(top); zeros([thisnumframes 1]); layercomplement(bot)];
	
	blendmode = [blendmode(top); ones([thisnumframes 1]); blendmode(bot)];
	thisblendmodelabel = repmat({{'normal'}},[thisnumframes 1]); 
	blendmodelabel = {blendmodelabel{top},thisblendmodelabel{:},blendmodelabel{bot}}';
	
	compmode = [compmode(top); ones([thisnumframes 1]); compmode(bot)];
	thiscompmodelabel = repmat({{'gimp'}},[thisnumframes 1]); 
	compmodelabel = {compmodelabel{top},thiscompmodelabel{:},compmodelabel{bot}}';

	imagelayers = cat(4,imagelayers(:,:,:,top),thisimage,imagelayers(:,:,:,bot));
	preprocessed = cat(4,preprocessed(:,:,:,top),thisimage,preprocessed(:,:,:,bot));
end

%% REPLACE LAYER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function replacelayer(whichlayer,thisimage)	
	% this will only replace the first numchan pages of the selected layer
	% this allows RGBA or RGB-only updating in an RGBA image array
	numchan = size(thisimage,3);
	imagelayers(:,:,1:numchan,whichlayer) = thisimage;
	preprocessed(:,:,1:numchan,whichlayer) = thisimage;

	if ~isempty(layermodifier{whichlayer})
		processimage('modify',whichlayer);
	end
end
	
%% IMAGE TRANSFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imagetrans(hobj,event,whichop)	
	% can't use rot90 because behavior changes at an unknown version
	% has multidimensional support in R2015b, but not in R2009b
	% flip is 3x faster than flipdim for large 4D stacks, but it's new (R2013b)
	% 10-15ms for version checking makes this insignificant for small single images
	% flipd() takes care of all that crap
	switch whichop
		case 'fliplr'
			composed = flipd(composed,2);
			imagelayers = flipd(imagelayers,2);
			preprocessed = flipd(preprocessed,2);
		case 'flipud'
			composed = flipd(composed,1);
			imagelayers = flipd(imagelayers,1);
			preprocessed = flipd(preprocessed,1);
		case 'rotccw'
			composed = flipd(permute(composed,[2 1 3 4]),1);
			imagelayers = flipd(permute(imagelayers,[2 1 3 4]),1);
			preprocessed = flipd(permute(preprocessed,[2 1 3 4]),1);
			s = fliplr(s);
		case 'rotcw'
			composed = flipd(permute(composed,[2 1 3 4]),2);
			imagelayers = flipd(permute(imagelayers,[2 1 3 4]),2);
			preprocessed = flipd(permute(preprocessed,[2 1 3 4]),2);
			s = fliplr(s);
	end	
	
	% if anything changes image geometry, we need to adjust viewport!
	if strismember(whichop,{'rotccw','rotcw'})
		h = handles.axes1;
		if strcmpi(get(h,'type'),'image')
			h = get(h,'parent');
		end
		
		% swap axes of zoomextents
		ze = [get(h,'xlim'); get(h,'ylim')];
		set(h,'xlim',ze(2,:),'ylim',ze(1,:));
		zoomextents = flipud(zoomextents);
	end
	
	updatefig('main')
	updatefig('preview')
end
	
	

% end main function block



end



