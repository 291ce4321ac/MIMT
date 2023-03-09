function varargout = imrectify(rawvec,varargin)
%   IMRECTIFY(RAWVEC, {OPTIONS})
%      This is a tool for recovering an image when it is presented as a vector without knowledge 
%      of its original geometry.  This may occur when retrieving data from hardware or custom 
%      software which writes images in nonstandardized binary formats, often with no metadata.  
%      Imrectify considers all geometries possible with a given vector length, and attempts to 
%      simplify the process by sorting and winnowing candidate images based on their properties.  
%
%      Candidate images are sorted by their calculated estimate of quality (EOQ), which is a 
%      weighted mean of two image properties -- aspect ratio and edginess.  Edginess is the absolute
%      sum of the horizontal directional derivative estimate of the image.  That is, it is sensitive
%      to the presence of vertically-oriented discontinuities caused by image content misalignment.
%
%      In typical usage, the user will be presented with a GUI wherein the following options can be 
%      adjusted and previews of candidate images can be browsed for final selection.
%
%   RAWVEC is a vector of any standard image class
%   OPTIONS include the following keys and key-value pairs
%   'weight' specifies the weighting factor used in the calculation of EOQ (range [0 1]; default 0.6)
%      For WEIGHT = 0, the sorting is determined by aspect ratio.  For 1, edginess determines sorting.
%   'minar' specifies the minimum allowable normalized aspect ratio (range [0 1]; default 0.1)
%      This is the ratio of an image's short side to its long side.  The assumption is that most 
%      practical images are closer to a square than an extremely long narrow strip.
%   'cmode' specifies the assumed color arrangement (default 'mono')
%      'mono' assumes that the entire vector represents one page
%      'pixel' assumes that the vector represents three pages interleaved pixelwise RGBRGBRGB...
%      'page' assumes that the vector represents three pages concatenated pagewise RRR...GGG...BBB...
%      Both 'pixel' and 'page' require that the vector length be integer-divisible by 3
%   'autoselect' key specifies that no gui should be used.  The image with the highest EOQ will be
%      returned.  While blind, this is useful for processing a set of images with similar properties, 
%      and for which appropriate option values have been predetermined.
%   'invert' key optionally inverts the image displays when using the GUI.  This is only useful if 
%      you are running Matlab on an inverted display. 
%
%   NOTE: It is worth pointing out that nothing in imrectify is aware of the details of the source file.
%   It is up to the user to identify and strip extraneous (e.g. header) data when importing.  Details 
%   like bytes per sample and byte order need to be determined beforehand.  Imrectify is a simple tool 
%   that only solves a small part of the overall problem.  I thought about adding features to help with
%   the front-end tasks, but frankly, there's no end to the ways ad-hoc code can excrete data.
%      
%   Output class is the same as input class
%
%   Examples:
%   Try to read what is assumed to be a color image
%     outpict = imrectify(invec,'cmode','pixel');
%   Do the same thing, but avoid the GUI and just blindly pick the recommended result
%     outpict = imrectify(invec,'cmode','pixel','autoselect');
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imrectify.html

invert = false;
autoselect = false;
showgui = true; % if false, this dumps a table to console and prompts for a selection
minar = 0.1; % ar is folded to fit in [0 1]
wt = 0.6; % 0 (ar dominant) -- > 1 (edg dominant)
cmode = 'mono';
tablelen = 10;
cmodestrings = {'mono','pixel','page'};

% parse inputs
k = 1;
while k <= numel(varargin)
    switch lower(varargin{k})
		case 'invert'
			invert = true;
			k = k+1;
		case 'autoselect'
			autoselect = true;
			k = k+1;
		case 'showgui'
			if islogical(varargin{k+1})
				showgui = varargin{k+1};
				k = k+2;
			else
				showgui = true;
				k = k+1;
			end
		case 'minar'
			minar = min(max(varargin{k+1},0),1);
			k = k+2;
		case 'weight'
			wt = min(max(varargin{k+1},0),1);
			k = k+2;
		case 'cmode'
			if strismember(varargin{k+1},cmodestrings)
				cmode = varargin{k+1};
			else
				error('IMRECTIFY: unknown cmode option %s',thisarg)
			end
			k = k+2;
        otherwise
            error('IMRECTIFY: unknown input parameter name %s',varargin{k})
    end
end

h = [];
w = [];
ar = [];
edginess = [];
eoq = [];
idx = [];
testpict = [];
rawpict = [];
whichtoshow = 1:6;
selectedcandidate = 1;
candidatenumbers = 1;

pxpc = numel(rawvec)/3;
divby3 = rem(pxpc,1) == 0;
handles = struct([]);
axhandles = [];

if autoselect
	buildmetrics();
	varargout{1} = getimage(1);
elseif ~showgui
	buildmetrics();
	if ~isempty(h)
		displaytable();
		selectedim = input('Select a candidate image (#1-10): ');
		varargout{1} = getimage(selectedim);
	else
		varargout{1} = [];
	end
else
	buildmetrics();
	figuresetup();
	set(handles.imrectifyfigure,'closerequestfcn',@donebuttonCBF)
	if ~isempty(h)
		set(handles.candidatemenu,'string',candidatenumbers)
		showcandidates(whichtoshow);
	else
		set(handles.candidatemenu,'string',1)
	end
	waitfor(handles.imrectifyfigure);
end

% CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setparam(objh,~,param)
	switch param			
		case 'invert'
			invert = get(objh,'value');
		case 'minar'
			minar = get(objh,'value');
		case 'wt'
			wt = get(objh,'value');
		case 'cmode'
			cmode = cmodestrings{get(objh,'value')};
		case 'selectedcandidate'
			selectedcandidate = get(objh,'value');
	end
	buildmetrics();
	if ~strcmp(param,'selectedcandidate')
		showcandidates(1:6);
	end
end

function prevbuttonCBF(~,~)
	if whichtoshow(1) ~= 1
		whichtoshow = whichtoshow(1)-6:whichtoshow(1)-1;
	end
	showcandidates(whichtoshow)
end

function nextbuttonCBF(~,~)
	if whichtoshow(end) ~= numel(idx)
		whichtoshow = whichtoshow(end)+1:whichtoshow(end)+min(numel(idx)-whichtoshow(end),6);
	end
	showcandidates(whichtoshow)
end

function showcandidates(whichones)
	whichones(whichones > numel(h)) = [];
	whichones(whichones < 1) = [];
	for p = 1:6
		cla(axhandles(p))
		delete(axhandles(p).Title)
	end
	for p = 1:min(6,numel(whichones))
		if invert
			imshow2(getimage(whichones(p)),'parent',axhandles(p),'invert');
		else
			imshow2(getimage(whichones(p)),'parent',axhandles(p));
		end
		title(axhandles(p),sprintf('Estimate %d: [%d %d]\nEOQ: %d ED: %d AR:%d%%', ...
		whichones(p),h(idx(p)),w(idx(p)),round(eoq(idx(p))*1000),round(edginess(idx(p))*1E4),round(ar(idx(p))*100)),'fontsize',9)
	end
end

function donebuttonCBF(~,~)
	varargout{1} = getimage(selectedcandidate);
	delete(handles.imrectifyfigure);
end

% GET IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = getimage(p)
	out = reshape(rawpict,h(idx(p)),[],size(rawpict,3));
end

% BASE PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buildmetrics()
	% prepare the image
	if strismember(cmode,{'pixel','page'}) && ~divby3
		errstr = 'Length of input vector is not integer-divisible by 3.  This may mean the image is not RGB, or maybe it contains some header/footer information that''s throwing off the byte counts. Now would be a good time to look at the file with a text or hex editor';
		if ~showgui
			error(['IMRECTIFY: ' errstr])
		else
			errordlg(errstr,'Vector Size Error','modal')
			return;
		end
	end

	rawvec = rawvec(:);
	switch cmode
		case 'mono'
			rawpict = rawvec;
			testpict = rawvec;
		case 'pixel'
			rawpict = cat(3,rawvec(1:3:end),rawvec(2:3:end),rawvec(3:3:end));
			testpict = rgb2gray(rawpict);
		case 'page'
			rawpict = cat(3,rawvec(1:pxpc),rawvec(pxpc+1:pxpc*2),rawvec(2*pxpc+1:end));
			testpict = rgb2gray(rawpict);
	end


	% prime factors of vector length
	npix = numel(testpict);
	f = factor(npix); 

	% build valid height, width, AR vectors
	h = [];
	for kk = 1:numel(f)
		h = [h; prod(nchoosek(f,kk),2)]; %#ok<AGROW>
	end
	% get initial w,ar for rejection
	w = npix./h;
	ar = min(w,h)./max(w,h);
	% reject and recalculate
	h = h(ar >= minar);
	h = unique(h,'sorted');
	w = npix./h;
	ar = min(w,h)./max(w,h);

	% get edginess metric
	fk = rot90(fkgen('sobel'),-1);
	testpict = imcast(testpict,'double');
	edginess = zeros(size(h));
	for n = 1:numel(h)
		shpict = reshape(testpict,h(n),[]);
		shpict = abs(imfilterFB(shpict,fk));
		edginess(n) = mean(shpict(:));
	end
	edginess = simnorm(edginess);

	% get list of indices sorted by EOQ
	eoq = (1-edginess).^(2*wt) .* ar.^(2-2*wt); 
	[~,idx] = sort(eoq,'descend'); 

	candidatenumbers = num2cell(1:numel(idx));	
	
	if isempty(h)
		quietwarning('IMRECTIFY: No candidate geometries found within the given constraints')
	end
end

% TABLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displaytable()
	if ifversion('<','R2013b')
		error('IMRECTIFY: nogui mode requires the use of the table class, which was introduced in R2013b');
	end
	tidx = idx(1:min(tablelen,numel(idx)));
	t = table((1:min(tablelen,numel(idx)))',h(tidx),w(tidx),round(eoq(tidx)*1000),round(edginess(tidx)*1E4),ar(tidx));
	t.Properties.VariableNames = {'#','height','width','EOQ','edginess','aspect ratio'};
	disp(t)
end

% UI SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
	'Name','imrectify',...
	'NumberTitle','off',...
	'outerPosition',[0 0 1 1],...
	'HandleVisibility','callback',...
	'Tag','imrectifyfigure');

	ppf = getpixelposition(h1);
	pw = pw/ppf(3);

	% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	paxespos = [hm vm 1-pw-2*hm-evm 1-2*vm];
	axsz = paxespos(3:4)./[3 2]-[hm/2 vm];
	axespos1 = [paxespos(1:2)+[0 axsz(2)+vm] axsz.*[1 0.9]];
	axespos2 = [paxespos(1:2)+[axsz(1)+hm axsz(2)+vm] axsz.*[1 0.9]];
	axespos3 = [paxespos(1:2)+[2*(axsz(1)+hm) axsz(2)+vm] axsz.*[1 0.9]];
	axespos4 = [paxespos(1:2)+[0 0] axsz.*[1 0.9]];
	axespos5 = [paxespos(1:2)+[axsz(1)+hm 0] axsz.*[1 0.9]];
	axespos6 = [paxespos(1:2)+[2*(axsz(1)+hm) 0] axsz.*[1 0.9]];
	
	axparams = {'Parent',h1,...
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
	'Visible','off'};
	
	axes(axparams{:},'Position',axespos1,'Tag','axes1');
	axes(axparams{:},'Position',axespos2,'Tag','axes2');
	axes(axparams{:},'Position',axespos3,'Tag','axes3');
	axes(axparams{:},'Position',axespos4,'Tag','axes4');
	axes(axparams{:},'Position',axespos5,'Tag','axes5');
	axes(axparams{:},'Position',axespos6,'Tag','axes6');


	% SIDE PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mainpanel = uipanel(...
	'Parent',h1,...
	'Title','',...
	'Tag','sidepanel',...
	'Clipping','on',...
	'visible','on',...
	'Position',[1-hm-pw vm+evm pw ph]);

	eh = 0.026; % element height
	tsp = 0.93; % table start point
	bh = 0.07; % block height
	
	% colormode menu
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[2*ehm tsp 1-2*ehm eh],...
	'String','Color Mode',...
	'Style','text',...
	'Tag','cmodelabel');
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Position',[2*ehm tsp-2*evm 1-4*ehm eh],...
	'String',cmodestrings,...
	'Style','popupmenu',...
	'Value',find(strcmp(cmode,cmodestrings)),...
	'Tag','cmodemenu',...
	'TooltipString','<html>Select the presumed color arrangement<br>''mono'' assumes the entire vector is one page<br>''pixel'' assumes the vector contains 3 pages organized RGBRGBRGB...<br>''page'' assumes the vector contains 3 pages organized RRR...GGG...BBB...</html>',...
	'callback',{@setparam,'cmode'});
	
	% sort weight
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[2*ehm tsp-bh 1-2*ehm eh],...
	'String','Sort Weight  AR <-> EDGE',...
	'Style','text',...
	'Tag','weightlabel');
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[2*ehm tsp-bh-2*evm 1-4*ehm 0.9*eh],...
	'String','Slider',...
	'Style','slider',...
	'Value',wt,...
	'TooltipString','<html>the estimate of quality used for sorting candidate images is a weighted mean of <br>the complement of the aspect ratio and a measure of the edge features within</html>',...
	'Tag','weightslider',...
	'callback',{@setparam,'wt'});
		
	% minar
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[2*ehm tsp-2*bh 1-2*ehm eh],...
	'String','Minimum Aspect Ratio',...
	'Style','text',...
	'Tag','minarlabel');
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'BackgroundColor',[0.9 0.9 0.9],...
	'Position',[2*ehm tsp-2*bh-2*evm 1-4*ehm 0.9*eh],...
	'String','Slider',...
	'Style','slider',...
	'Value',minar,...
	'TooltipString','<html>reject candidates whose ratio between short and long sides <br>is less than this value ([0 1])</html>',...
	'Tag','minarslider',...
	'callback',{@setparam,'minar'});

	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[4*ehm tsp-4*bh 1-8*ehm eh],...
	'String','▲ PREV',...
	'TooltipString','prev page of previews',...
	'Tag','prevbutton',...
	'callback',@prevbuttonCBF);

	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[4*ehm tsp-4*bh-1.5*eh 1-8*ehm eh],...
	'String','▼ NEXT',...
	'TooltipString','next page of previews',...
	'Tag','nextbutton',...
	'callback',@nextbuttonCBF);


	% selection menu
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',8,...
	'HorizontalAlignment','left',...
	'Position',[2*ehm tsp-7*bh 1-2*ehm eh],...
	'String','Select an Image to Export',...
	'Style','text',...
	'Tag','candidatemenulabel');
	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Position',[2*ehm tsp-7*bh-2*evm 1-4*ehm eh],...
	'String',candidatenumbers,...
	'Style','popupmenu',...
	'Value',1,...
	'Tag','candidatemenu',...
	'TooltipString','Select which image to export',...
	'callback',{@setparam,'selectedcandidate'});

	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'FontSize',10,...
	'Position',[4*ehm tsp-7*bh-2*eh 1-8*ehm eh],...
	'String','DONE',...
	'TooltipString','accept current color(s) and exit',...
	'Tag','donebutton',...
	'callback',@donebuttonCBF);

	uicontrol(...
	'Parent',mainpanel,...
	'Units','normalized',...
	'Position',[4*ehm 0.5*eh 1-8*ehm eh],...
	'String','Invert Display',...
	'Style','checkbox',...
	'TooltipString','Use this if using Matlab on an inverted X display.',...
	'value',invert,...
	'Tag','invertcheckbox',...
	'callback',{@setparam,'invert'});

	% all child object handles in figure 
	handles = guihandles(h1);
	guidata(h1,handles);
	axhandles = [handles.axes1;
				handles.axes2;
				handles.axes3;
				handles.axes4;
				handles.axes5;
				handles.axes6];
end
   

end % end main function scope







