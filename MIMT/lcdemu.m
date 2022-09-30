function outpict = lcdemu(inpict,vangle,screenprofile)
%   LCDEMU(INPICT,{ANGLE},{SCREENPROFILE})
%       Emulate the effect of using an old or low-quality TN-type LCD monitor
%       Both horizontal and vertical viewing angle influence is emulated
%       Image is assumed to be scaled to screen extents
%
%   INPICT is an image (I or RGB)
%   ANGLE is the nominal viewing angle ([vert horiz]) (default [0 0])
%       The default case assumes gaze is centered and orthogonal to screen.
%       Viewing angle varies over image area based on assumptions of screen geometry.
%       Increasing vertical angle emulates an upward gaze from a lower position
%       Decreasing vertical angle emulates a downward gaze from a higher position
%       Allowed range of vertical angle varies with the hardware model (see below)
%       Horizontal angle range is [-45 45].
%       Setting horizontal angle to NaN will disable emulation on that axis.
%   SCREENPROFILE selects a hardware profile.  Default is 'generic'.
%       'generic' is an initial model derived from comparative analysis [-14 14]
%       The following profiles were measured electronically
%       'acer' is an Acer 7736z laptop screen [-19 19]
%       'sceptre' is a Sceptre X9G-NagaV [-15 15]
%       'hannsg' is a Hanns-G HG281D [-13 13]
%
%   CLASS SUPPORT:
%       inputs may be 'uint8','uint16','int16','single','double', or 'logical'
%       return class matches INPICT class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/lcdemu.html
% See also: bicoloradapt


% Although this is a very crude modeling attempt, it should clearly demonstrate that
% viewing angle influence does not cause a gamma shift in the typical sense of the word
% as used with CRT monitors.  The error cannot be compensated by a simple power function; 
% furthermore, the effect cannot be compensated by any single monotonic 1-D function.
% To make matters worse, subpixel sharing and white/black point variation and inversion
% causes difficulty when trying to compare intensity maps to density maps!
% Dithered images may not be angle-invariant, and the relationship between the perceivved
% grey levels of an intensity map and a density map may not be angle-invariant.

% https://www.researchgate.net/publication/264050335_Limitations_of_visual_gamma_corrections_in_LCD_displays

% In short, shitty panels are fucking useless for graphics work.
% Given any comfortable combination of image/screen size and viewing distance, it is not possible
% to have all parts of an image represented uniformly.  
% The ability to simultaneously compare image regions by eye is lost.  

if ~exist('vangle','var')
	vangle = [0 0];
end

if ~exist('screenprofile','var')
	screenprofile = 'generic';
end

if numel(vangle) == 1
	vangle = [vangle 0];
end

% safeguard things so bsxfun doesn't explode
try
	[inpict inclass] = imcast(inpict,'double');
catch b
	error('LCDEMU: Unsupported image class for INPICT')
end

inpict = min(max(inpict,0),1);
s = size(inpict);

% profiles captured using an AMS TSL235R-LF sensor + arduino
% if you want a copy of the autoprofiler gui and uc code, ask me.
% these aren't expected to be perfect; i have no means of calibration
% these all use relative black/white points and assume gamma=2.2
% since values are normalized per min/max readings on each display
% this means that black level performance isn't emulated (backlight bleed)
% similarly, backlight nonuniformity is not emulated

% to anyone trying to do this by eye
% beware the limitations of density-opacity comparisons mentioned above
% trying to use a camera is usually going to be more trouble than it's worth
% considering your camera even has the manual controls required
% you can get decent side-by-side comparison of a simple gradient using a simple jig and a mirror
% while viewing the screen at an angle, use the jig such that the mirror provides an image as seen at 90deg to the screen
% it may be useful to use a very coarse, stepped gradient 
% so as to better define locations within the image
% and to better identify local changes to the slope of the panel's tf

screenprofile = lower(screenprofile);
load([screenprofile '.mat']); % this loads Yest_y
load('hamap.mat'); % this loads Yest_x
anglerange_h = [-45 45];

switch screenprofile
	case 'generic'
		% this was a generic initial approximation
		% developed via comparative analysis by eye
		anglerange_v = [-25 25];	% range of angles represented by vertical axis of tfmap
		inclangle_v = 22;			% included angle of image (vertical)
		aspectratio = 16/9;
		sensitivityh = 1.5;		% this factor crudely scales the horiz va sensitivity
		
	case 'acer'
		% ACER 7736z (ca 2009)
		% 17" 16:9 display at about 20"
		anglerange_v = [-30 30];	% range of angles represented by vertical axis of tfmap
		inclangle_v = 22;			% included angle of image (vertical)
		aspectratio = 16/9;
		sensitivityh = 1.2;		% this factor crudely scales the horiz va sensitivity
		
	case 'sceptre'
		% SCEPTRE X9G-NagaV (ca 2005)
		% 19" 4:3 display at about 22"
		% brightness at 30%
		anglerange_v = [-30 30];	% range of angles represented by vertical axis of tfmap
		inclangle_v = 30;			% included angle of image (vertical)
		aspectratio = 4/3;
		sensitivityh = 1.2;		% this factor crudely scales the horiz va sensitivity

	case 'hannsg'
		% HANNS G HG281D (ca 2007)
		% 28" 16:10 display at about 24"
		anglerange_v = [-30 30];	% range of angles represented by vertical axis of tfmap
		inclangle_v = 34;			% included angle of image (vertical)
		aspectratio = 16/10;
		sensitivityh = 1;		% this factor crudely scales the horiz va sensitivity

end

% create angle map for given image and varange
% this will be used much like a second layer in mesh blending
x = linspace(0,1,s(2));
y = linspace(0,1,s(1));
[xpos ypos] = meshgrid(x,y);

% VERTICAL SETUP
tfmapy = imresizeFB(Yest_y,[1 1]*256,'bilinear');
% viewing angle can be adjusted further
inanglerange_v = [-1 1]*(diff(anglerange_v)-inclangle_v)/2;
deg2tfy = size(tfmapy,1)/(anglerange_v(2)-anglerange_v(1));		% convert degrees to approx row in tfmap

% select proper subset of tfmap to create specific tf for given angles
va = min(max(-vangle(1),inanglerange_v(1)),inanglerange_v(2));
tfyrange = deg2tfy*(va+[-1 1]*inclangle_v/2)+size(tfmapy,1)/2;
tfyrange = min(max(round(tfyrange),1),size(tfmapy,1));
tfy = tfmapy(tfyrange(1):tfyrange(2),:);

% create grid for v interplation
% xx represents image value
% yy represents position in projected image space
x = linspace(0,1,size(tfy,2));
y = linspace(0,1,size(tfy,1));
[xxv yyv] = meshgrid(x,y);


% HORIZONTAL SETUP
if ~isnan(vangle(2))
	inclangle_h = 2*atand(aspectratio*tand(inclangle_v/2))*sensitivityh;
	tfmapx = Yest_x;
	% viewing angle can be adjusted further
	inanglerange_h = [-1 1]*(diff(anglerange_h)-inclangle_h)/2;
	deg2tfx = size(tfmapx,1)/(anglerange_h(2)-anglerange_h(1));		% convert degrees to approx row in tfmap

	% select proper subset of tfmap to create specific tf for given angles
	ha = min(max(vangle(2)*sensitivityh,inanglerange_h(1)),inanglerange_h(2));
	tfxrange = deg2tfx*(ha+[-1 1]*inclangle_h/2)+size(tfmapx,1)/2;
	tfxrange = min(max(round(tfxrange),1),size(tfmapx,2));
	tfx = tfmapx(tfxrange(1):tfxrange(2),:,:);

	% create grid for h interplation
	% xx represents image value
	% yy represents position in projected image space
	x = linspace(0,1,size(tfx,2));
	y = linspace(0,1,size(tfx,1));
	[xxh yyh] = meshgrid(x,y);
end

%imshow2(tfx,'invert','tools')

outpict = zeros(size(inpict));
for c = 1:size(inpict,3)
	% do interpolation for va emulation
	outpict(:,:,c) = interp2(xxv,yyv,tfy,inpict(:,:,c),ypos,'bilinear');
	
	if ~isnan(vangle(2))
		% do interpolation for ha emulation
		outpict = min(max(outpict,0),1);
		outpict(:,:,c) = interp2(xxh,yyh,tfx(:,:,c),outpict(:,:,c),xpos,'bilinear');
	end
end

outpict = min(max(outpict,0),1);
outpict = imcast(outpict,inclass);

end

