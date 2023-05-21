function varargout = imcropzoom(varargin)
%  IMCROPZOOM({INPICT},{WIDTH})
%  OUTPICT = IMCROPZOOM({INPICT},{WIDTH})
%  [OUTPICT RECT] = IMCROPZOOM({INPICT},{WIDTH})
%  Interactively use IPT imcrop() to crop an image.  This is a simplified utility 
%  that aims to improve the practical usability of imcrop() within the cumbersome
%  view controls that are available.  
%
%  When executed, the image will be presented in a figure and the user will be 
%  prompted to manually select the approximate ROI.  After a selection is made,
%  the view will automatically be zoomed in on the ROI handles, allowing them
%  to be accurately placed without the need to tediously swap back and forth 
%  between figure/axes view controls for every single click. After two opposite
%  box handles are adjusted, the user is given the option to re-check the handles.
%
%  This tool is not integrated into imcropFB(), as it's just an inelegant workaround
%  and it does not mimic the behavior of imcrop().  While it does strictly depend on IPT,
%  I'm motivated to keep it independent of MIMT or akzoom() so that it can be shared easily.
%
%  INPICT is an I/RGB image, properly scaled for its class. 
%  WIDTH optionally specifies the view width when zooming in on the ROI handles.
%    (scalar, pixels, default 50)
% 
%  If no input arguments are given, the CData of the image displayed in the current
%  axes is used.  If the current axes contains no image object, an error results.
%
%  If no output arguments are given, the RECT parameter is dumped to console, 
%  formatted such that it can be conveniently pasted into a script.
%
% See also: imcrop(), imcropFB()


% defaults
w = 50;

switch nargin
	case 0
		% if there's an axes open with an image object
		hi = findobj('parent',gca,'type','image');
		if isempty(hi)
			error('IMCROPZOOM: Current axes has no image object')
		end
		% get its CData and discard everything else
		% since the axes padding is probably the horrible default
		inpict = hi.CData;
	case 1
		inpict = varargin{1};
	otherwise
		inpict = varargin{1};
		w = varargin{2};
end

hw = floor(w(1)/2);

% display the image without extraneous padding, ticks, titles, etc
% so that we have the most working area
clf
wstruct = warning('off','Images:imshow:magnificationMustBeFitForDockedFigure'); % imo this should be left off, but w/e
hi = imshow(inpict,'border','tight');
warning(wstruct.state,'Images:imshow:magnificationMustBeFitForDockedFigure');
hax = get(hi,'parent');
hfg = get(hax,'parent');

% depending on the figure state or window management tools, MATLAB will persistently
% throw the figure window into the background, which is just another trivial nuisance.
% raising figures using figure() is not reliable, as raised figures will often only stay raised momentarily
% adding delays only reduces the behavior, but cannot reasonably prevent it.
% this temporarily forces the window into alwaysontop state via Java
% this will eventually break in newer versions.
WinOnTop(hfg,true);

% get the rough ROI
fprintf('Roughly select the box region.  This can be refined later.\n')
ROI = iptui.imcropRect(gca,[],hi);
rect = ROI.calculateClipRect();


% refine the ROI
while true
	xlim(hax,rect(1)+[-1 1]*hw)
	ylim(hax,rect(2)+[-1 1]*hw)
	drawnow
	input('Adjust the NW corner of the box. Hit ENTER when done. ','s');
	
	xlim(hax,rect(1)+rect(3)+[-1 1]*hw)
	ylim(hax,rect(2)+rect(4)+[-1 1]*hw)
	drawnow
	ip = input('Adjust the SE corner of the box. Hit ENTER when done or type ''c'' to double-check. ','s');
	
	if isempty(ip) || (lower(ip(1)) ~= 'c')
		break;
	end
end

WinOnTop(hfg,false);

% crop the image
rect = ROI.calculateClipRect();
outpict = imcrop(inpict,rect);

% prepare outputs
switch nargout
	case 0
		% there's never any point in dumping outpict to console
		% if no outputs are requested, 
		% simply dump the rect param in a format that can be pasted into a script
		fprintf('%s\n',mat2str(rect));
	case 1 
		varargout{1} = outpict;
	otherwise
		varargout{1} = outpict;
		varargout{2} = rect;
end

end % END MAIN SCOPE



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wasOnTop = WinOnTop( figureHandle, isOnTop )
%WINONTOP allows to trigger figure's "Always On Top" state
%
%% INPUT ARGUMENTS:
%
% # figureHandle - Matlab's figure handle, scalar
% # isOnTop      - logical scalar or empty array
%
%
%% USAGE:
%
% * WinOnTop( hfigure, true );      - switch on  "always on top"
% * WinOnTop( hfigure, false );     - switch off "always on top"
% * WinOnTop( hfigure );            - equal to WinOnTop( hfigure,true);
% * WinOnTop();                     - equal to WinOnTop( gcf, true);
% * WasOnTop = WinOnTop(...);       - returns boolean value "if figure WAS on top"
% * isOnTop = WinOnTop(hfigure,[])  - get "if figure is on top" property
%
% For Matlab windows, created via `hf=uifigure()` use `uifigureOnTop()`, see: 
% https://www.mathworks.com/matlabcentral/fileexchange/73134-uifigureontop
%
%% LIMITATIONS:
%
% * java enabled
% * figure must be visible
% * figure's "WindowStyle" should be "normal"
% * figureHandle should not be casted to double, if using HG2 (R2014b+)
%
%
% Written by Igor
% i3v@mail.ru
%
% 2013.06.16 - Initial version
% 2013.06.27 - removed custom "ishandle_scalar" function call
% 2015.04.17 - adapted for changes in matlab graphics system (since R2014b)
% 2016.05.21 - another ishg2() checking mechanism 
% 2016.09.24 - fixed IsOnTop vs isOnTop bug
% 2019.10.27 - link for uifigureOnTop; connected to github; renamed to "demo_"

%% Parse Inputs
if ~exist('figureHandle','var'); figureHandle = gcf; end

% if figure is docked, none of this matters
if strcmpi(get(figureHandle,'WindowStyle'),'docked')
	return;
end

assert(...
          isscalar(  figureHandle ) &&...
          ishandle(  figureHandle ) &&...
          strcmp(get(figureHandle,'Type'),'figure'),...
          ...
          'WinOnTop:Bad_figureHandle_input',...
          '%s','Provided figureHandle input is not a figure handle'...
       );
assert(...
            strcmp('on',get(figureHandle,'Visible')),...
            'WinOnTop:FigInisible',...
            '%s','Figure Must be Visible'...
       );
assert(...
            strcmp('normal',get(figureHandle,'WindowStyle')),...
            'WinOnTop:FigWrongWindowStyle',...
            '%s','WindowStyle Must be Normal'...
       );
   
if ~exist('isOnTop','var'); isOnTop=true; end
assert(...
          islogical( isOnTop ) && ...
          isscalar(  isOnTop ) || ...
          isempty(   isOnTop ),  ...
          ...
          'WinOnTop:Bad_isOnTop_input',...
          '%s','Provided isOnTop input is neither boolean, nor empty'...
      );
  
  
%% Pre-checks
error(javachk('swing',mfilename)) % Swing components must be available.
  
  
%% Action
% Flush the Event Queue of Graphic Objects and Update the Figure Window.
drawnow expose
warnStruct=warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
jFrame = get(handle(figureHandle),'JavaFrame');
warning(warnStruct.state,'MATLAB:ui:javaframe:PropertyToBeRemoved');
drawnow
if ishg2(figureHandle)
    jFrame_fHGxClient = jFrame.fHG2Client;
else
    jFrame_fHGxClient = jFrame.fHG1Client;
end
wasOnTop = jFrame_fHGxClient.getWindow.isAlwaysOnTop;
if ~isempty(isOnTop)
    jFrame_fHGxClient.getWindow.setAlwaysOnTop(isOnTop);
end


end

function tf = ishg2(figureHandle)
% There's a detailed discussion, how to check "if using HG2" here:
% http://www.mathworks.com/matlabcentral/answers/136834-determine-if-using-hg2
% however, it looks like there's no perfect solution.
%
% This approach, suggested by Cris Luengo:
% http://www.mathworks.com/matlabcentral/answers/136834#answer_156739
% should work OK, assuming user is NOT passing a figure handle, casted to
% double, like this:
%
%   hf=figure();
%   WinOnTop(double(hf));
%
tf = isa(figureHandle,'matlab.ui.Figure');
end




