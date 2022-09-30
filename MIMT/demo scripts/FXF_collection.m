% USING MIMT TO REPLICATE FX FOUNDRY SCRIPTS & OTHER GIMP STUFF

% This is more or less just a demonstration of equivalent methods in MIMT.
% That, and i think that it's more helpful to have these processes demonstrated
% in the open than it is to have a bunch of inflexible niche-use plugins.


% original FXF scripts can mostly be found at
% http://gimpfx-foundry.sourceforge.net/browse26/index_name.html
% GMIC tools can be found under
% https://github.com/dtschump/gmic-community/tree/master/include

% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

% some of these demos may be configured for viewing on an inverted display
% if something looks inverted, just check the call to imshow() or imshow2()
% as i am likely the most common user of these files, i tend to leave them configured for my own use

% depending on your filesystem, your pwd and where you stick this script, 
% you may need to change the path strings used for input/output.

return; % keeps the script from being run in whole

%% Value Invert
% from the Color menu
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% this is trivial in MIMT, and other models can be used
outpict = imtweak(inpict,'hsl',[0 1 -1]);

imshow2(outpict,'invert')

%% Lasm's Vivid Value Invert
% from the Color menu
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use an inverted copy in 'value' blend mode
outpict = imblend(iminv(inpict),inpict,1,'value');

imshow2(outpict,'invert')

%% Lasm's Color-only Invert
% from the Color menu
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% while the original script uses a similar trick with an inverted overlay
%outpict = imblend(iminv(inpict),inpict,1,'transfer h_hsl>h_hsl');
% you can just do this
outpict = imtweak(inpict,'hsl',[0.5 1 1]);

imshow2(outpict,'invert')

%% xMedia colorize
% Original FX Foundry script author: Alexander Melcher
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
fgcolor = [1 0 0]; % default [1 0 0]
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cpict = colorpict(imsize(inpict,3),fgcolor);
% the use of the 'colorhsl' blend is purely to replicate
% the behavior of the original script within GIMP.  
% in practice, better results can be obtained using the other 'color' blends.
outpict = imblend(cpict,inpict,1,'colorhsl');

imshow2(outpict,'invert')

%% GIMP colorize (from the 'color' menu)
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
hue = 180; % range [0 360]; default 180
saturation = 50; % range [0 100]; default 50
lightness = 0; % range [-100 100]; default 0
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% i went ahead and shoved it into a function
outpict = gcolorize(inpict,[hue saturation lightness]);

imshow2(outpict,'invert')

%% Cross-Processing effect
% Original FX Foundry script author: Alexia Death
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
overcastcolor = [0 1 0.7]; % default [0 1 0.7]
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

breakpoints = { [0 0 88 47 170 188 221 249 255 255]/255;
				[0 0 65 57 184 208 255 255]/255;
				[0 29 255 226]/255};

% adjust curves
outpict = zeros(size(inpict),class(inpict));
for c = 1:3
	bp = breakpoints{c};
	bpx = bp(1:2:end);
	bpy = bp(2:2:end);
	outpict(:,:,c) = imcurves(inpict(:,:,c),bpx,bpy);
end

% blend overlays
outpict = imblend(inpict,outpict,0.5,'overlay');
cpict = colorpict(imsize(inpict,3),overcastcolor);
outpict = imblend(cpict,outpict,0.1,'overlay');

imshow2(outpict,'invert')

%% Black & White Photo effect
% Original FX Foundry script author: Alexander Melcher
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
darken = 0.4; % range [0 1]; default 0.4
contrast = 0.4; % range [0 1]; default 0.4
mottle = 0.5; % range [0 1]; default 0.5
fixmottle = false; % true or false; default false (see notes)
defocus = false; % true or false; default false
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if defocus
	fk = fkgen('techgauss2',5,'sigma',0.75);
	inpict = imfilterFB(inpict,fk,'replicate');
end

% darken red, change green contrast
inpict(:,:,1) = imbcg(inpict(:,:,1),'b',-darken/2,'gimp');
inpict(:,:,2) = imbcg(inpict(:,:,2),'c',contrast,'gimp');

if mottle > 0
	if fixmottle
		% i'm pretty sure that the original script has a bug here
		% the user-specified parameter value is never used but as a flag
		% default-value noise is applied to the alpha channel and then discarded
		% the result is a uniform blurring of the blue channel with no mottling
		% i'm assuming that the following is closer to the intended result
		noisemap = mottle*(rand(imsize(inpict,2))-0.5); % yes, uniform noise
		B = imcast(imclamp(imcast(inpict(:,:,3),'double') + noisemap),'uint8');
	else
		% this is basically what the original does (no mottling, only blurring)
		B = inpict(:,:,3);
	end
	fk = fkgen('techgauss2',13,'sigma',2.5);
	inpict(:,:,3) = imfilterFB(B,fk,'replicate');
end

% desaturate
outpict = imcast(mono(inpict,'l'),'uint8');

imshow2(outpict,'invert')

%% Diffusion Filter effect
% Original FX Foundry script author: Antoine Tissier
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
levels = 1.5; % range [0.1 10]; default 1.5
radius = 15; % range [1 100]; default 15
intensity = 75; % range [0 100]; default 75
negative = false; % true or false; default false
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% the original script uses a mask for the top layer blending
% this could be simply done using the scalar opacity parameter in imblend()
% but using an editable mask is more flexible.
gray = abs(100-intensity)/100;
int_ol_mask = colorpict(imsize(inpict,2),gray);

int_overlay = inpict;
orig_overlay = inpict;
base_layer = inpict;

if negative
	olmode = 'multiply'; 
else
	% 'overlay' mode in GIMP is 'softlight' due to a bug
	olmode = 'softlight';
end

% blur base layer
if radius > 0
	fk = fkgen('techgauss2',2*ceil(radius)+1,'sigma',radius/5*1.84);
	base_layer = imfilterFB(base_layer,fk,'replicate');
end

% adjust base layer gamma (note that GIMP 'value' adjustment isn't HSV)
base_layer = imbcg(base_layer,'g',1/levels);

% compose
outpict = imblend(orig_overlay,base_layer,1,olmode);
outpict = replacepixels(int_overlay,outpict,int_ol_mask);

imshow2(outpict,'invert')

%% Gothic Glow filter
% Original FX Foundry script author: Mark Lowry
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
blur_mult = 8; % range [1 100]; default 8
blur_screen = 0; % range [1 100]; default 0
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

multlayer = inpict;
if blur_mult > 0
	fk = fkgen('techgauss2',2*ceil(blur_mult)+1,'sigma',blur_mult/5*1.84);
	multlayer = imfilterFB(multlayer,fk,'replicate');
end

screenlayer = inpict;
if blur_screen > 0
	fk = fkgen('techgauss2',2*ceil(blur_screen)+1,'sigma',blur_screen/5*1.84);
	screenlayer = imfilterFB(screenlayer,fk,'replicate');
end

% the original script has an option to add layer masks on the mult/screen layers
% for subsequent editing.  Since this isn't really being done interactively here
% i'm just going to omit that step.  You can easily create masks and use replacepixels if desired.
% Alternatively, you can append the masks as alpha and just let imblend() take care of it.

outpict = imblend(multlayer,inpict,1,'multiply');
outpict = imblend(screenlayer,outpict,1,'screen');

imshow2(outpict,'invert')

%% Soft Focus filter
% Original FX Foundry script author: Iccii
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
blur_amt = 10; % range [1 100]; default 10
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FG = cat(3,inpict,mono(inpict,'y'));
if blur_amt > 0
	fk = fkgen('techgauss2',2*ceil(blur_amt)+1,'sigma',blur_amt/5*1.84);
	FG = imfilterFB(FG,fk,'replicate');
end

outpict = imblend(FG,inpict,0.8,'screen');
outpict = outpict(:,:,1:3);

imshow2(outpict,'invert')

%% Make Wonderful filter
% Original FX Foundry script author: Ingo Ruhnke, Paul Sherman
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
blur_amt = 35; % range [1 5600]; default 35
brightness = 0; % range [-1 1]; default 0
contrast = 0; % range [-1 1]; default 0
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if blur_amt > 0
	fk = fkgen('techgauss2',2*ceil(blur_amt)+1,'sigma',blur_amt/5*1.84);
	FG = imfilterFB(inpict,fk,'replicate');
end
FG = imbcg(FG,'b',brightness/2,'c',contrast);

outpict = imblend(FG,inpict,1,'lineardodge');
outpict = replacepixels(outpict,inpict,mono(FG,'y'));

imshow2(outpict,'invert')

%% LOMO effect (Bercovich)
% Original FX Foundry script author: Avi Bercovich 
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
fringeoffset = 4; % range [1 10]; default 4
boostfringe = true; % true or false; default true
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% adjust color balance and contrast
inpict = colorbalance(inpict,[0.3 0 0; 0 0 0; 0 0 0]);
inpict = imbcg(inpict,'c',0.24,'gimp');

% white center emphasis
% this might be better with something other than a linear ease curve
flare = radgrad(imsize(inpict,2),[0.5 0.5],0.5,[255; 0],'linear');
flare = cat(3,255*ones(imsize(inpict,2),'uint8'),flare);

% border vignetting
% this uses the image width to set the filter radius
% might be better to use the diagonal instead to avoid AR-dependence
fringe = cropborder(255*zeros(imsize(inpict,2),'uint8'),fringeoffset);
fringe = addborder(fringe,fringeoffset,255);
blur_amt = size(inpict,2)/10;
fk = fkgen('techgauss2',2*ceil(blur_amt)+1,'sigma',blur_amt/3.14);
fringe = imfilterFB(fringe,fk,'replicate');
fringe = cat(3,zeros(imsize(inpict,2),'uint8'),fringe);

% compose output
% 'overlay' mode in GIMP is 'softlight' due to a bug
outpict = imblend(flare,inpict,0.8,'softlight');
outpict = imblend(fringe,outpict,1,'softlight');
if boostfringe
	outpict = imblend(fringe,outpict,1,'softlight');
end
outpict = outpict(:,:,1:3); % strip alpha

imshow2(outpict,'invert')

%% LOMO effect (Death)
% Original FX Foundry script author: Alexia Death
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = ghlstool(inpict,[0 0 20]);
inpict = imbcg(inpict,'c',0.16);

% border vignetting
% this might be better with something other than a linear ease curve
vignette = radgrad(imsize(inpict,2),[0.5 0.5],0.375,[255; 0],'linear');

% compose output
% 'overlay' mode in GIMP is 'softlight' due to a bug
outpict = imblend(vignette,inpict,1,'softlight');

imshow2(outpict,'invert')

%% Midnight Sepia effect
% Original FX Foundry script author: Cprogrammer
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
hue = 45; % range [0 360]; default 45
saturation = 35; % range [-100 100]; default 35
lightness = 0; % range [-100 100]; default 0
opacity = 80; % range [0 100]; default 80
color = [125 65 55]; % range [0 255]; default [125 65 55]
desaturate = false; % true or false; default false
useHSV = true; % true or false; default true
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create colored overlay with increased contrast
if useHSV
	color = ctflop(rgb2hsv(ctflop(color/255))).*[360 100 100];
	baselayer = gcolorize(inpict,color);
else
	% this is not remotely comparable to the above process
	baselayer = ghlstool(inpict,[hue lightness saturation]);
end
baselayer = imbcg(baselayer,'c',0.16,'gimp');

% desaturate if requested
if desaturate
	baselayer = mono(baselayer,'l');
end

% blur the overlay
fk = fkgen('techgauss2',2*ceil(20)+1,'sigma',20/3.14);
baselayer = imfilterFB(baselayer,fk,'replicate');

% compose
% the original script also creates an extra 'screen' layer copy
% but it sets the opacity to 0.  i'm omitting that.
outpict = imblend(baselayer,inpict,1,'multiply');
outpict = imblend(outpict,outpict,opacity/100,'screen');

imshow2(outpict,'invert')

%% Simple Sepia Toning effect
% Original FX Foundry script author: Jakub Klawiter, Eric R. Jeschke
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
color = [162 138 101]; % range [0 255]; default [162 138 101]
desaturate = false; % true or false; default false
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if desaturate
	% the behavior of the gimp-desaturate plugin is to return L
	inpict = repmat(mono(inpict,'l'),[1 1 3]);
end

sepiamask = colorpict(imsize(inpict,3),color,'uint8');
outpict = imblend(sepiamask,inpict,1,'colorhsl');

% when pasting color content into a layer mask in GIMP
% the result is collapsed to rec709 luma
lmask = mono(inpict,'y709');
outpict = replacepixels(outpict,inpict,iminv(lmask));

imshow2(outpict,'invert')

%% Vintage Film effect
% Original FX Foundry script author: Alexia Death, fallout75
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

baselayer = ghlstool(inpict,[0 0 15]);
baselayer = imbcg(baselayer,'c',0.16,'gimp');

breakpoints = { [0 0 88 47 170 188 221 249 255 255]/255;
				[0 0 65 57 184 208 255 255]/255;
				[0 29 255 226]/255};

% adjust curves
for c = 1:3
	bp = breakpoints{c};
	bpx = bp(1:2:end);
	bpy = bp(2:2:end);
	baselayer(:,:,c) = imcurves(baselayer(:,:,c),bpx,bpy);
end

sepialayer = inpict;
sepialayer = gcolorize(sepialayer,[25 25 30]);
sepialayer = imbcg(sepialayer,'b',0.16,'c',0.24,'gimp');
outpict = imblend(sepialayer,baselayer,0.5,'normal');

magentalayer = colorpict(imsize(baselayer,3),[255 0 220],'uint8');
outpict = imblend(magentalayer,outpict,0.06,'screen');

imshow2(outpict,'invert')

%% Auto Contrast Correction
% Original FX Foundry script author: Mark Lowry, Alexia Death
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

huelayer = inpict;
valuelayer = imlnc(inpict,'independent','tol',0.006);

% this really isn't a great approach unless you're stuck in GIMP
outpict = imblend(valuelayer,inpict,1,'value');
outpict = imblend(huelayer,outpict,1,'transfer h_hsl>h_hsl');

imshow2(outpict,'invert')

%% Graduated Filter
% Original FX Foundry script author: Kevin Payne
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
color = [255 204 153]; % range [0 255]; default [255 204 153]
flipgradient = true; % true or false; default true
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% original script does not allow the user to orient the gradient, only flip it
gcol = [0; 255];
if flipgradient
	gcol = flipud(gcol);
end
gradpict = lingrad(imsize(inpict,2),[0 0; 1 0],gcol);

% this is a trivial use of the color mixer
% only the diagonal is populated, and no normalization is performed
% so it could be replaced with a simple multiply blend
overlay = mixchannels(inpict,diag(color/255));
outpict = replacepixels(overlay,inpict,gradpict);

imshow2(outpict,'invert')

%% Vivid Saturation
% Original FX Foundry script author: Olli Salonen, Alexia Death
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
amount = 10; % range [0 50]; default 10
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

a = amount/100;
A = [1+2*a -a -a; -a 1+2*a -a; -a -a 1+2*a];
outpict = mixchannels(inpict,A);
outpict = imcurves(outpict,[0 63 191 255]/255,[0 60 194 255]/255,'pchip');

imshow2(outpict,'invert')

%% Power Toning
% Original FX Foundry script author: Art Wade
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
color = [120 20 255]; % range [0 255]; default [0 0 0]
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% i really don't understand what the point of this filter is
% or why the default color is black
BG = colorpict(size(inpict),color,'uint8');
outpict = imblend(inpict,BG,1,'transfer s_hsv>s_hsv');
outpict = imblend(inpict,outpict,1,'value');

imshow2(outpict,'invert')

%% Landscape Painter
% Original FX Foundry script author: Mark Lowry
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
blur_amt = 15; % default 15
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% on one hand, it's kind of surprising how simple some of these scripts are
% on the other, i wouldn't want to write anything complicated in SIOD either.
fk = fkgen('techgauss2',2*ceil(blur_amt)+1,'sigma',blur_amt/3.14);
darkenlayer = imfilterFB(inpict,fk,'replicate');
outpict = imblend(darkenlayer,inpict,1,'darkenrgb');

imshow2(outpict,'invert')

%% Landscape Illustrator
% Original FX Foundry script author: Mark Lowry
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
blur_amt = 15; % default 15
sharpen = true; % true or false; default true
sharpenamt = 5; % range [0 10]; default 5
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sharpen
	% this is basically an inverted laplacian filter
	fk = [0 -0.2 -0.2 -0.2 0;
		-0.2 -0.5 -1 -0.5 -0.2;
		-0.2 -1 10 -1 -0.2;
		-0.2 -0.5 -1 -0.5 -0.2;
		 0 -0.2 -0.2 -0.2 0];
	fk(13) = 11-sharpenamt/5;
	fk = fk/sum(fk(:));
	
	inpict = imfilterFB(inpict,fk,'replicate');
end

fk = fkgen('techgauss2',2*ceil(blur_amt)+1,'sigma',blur_amt/3.14);
darkenlayer = imfilterFB(inpict,fk,'replicate');
outpict = imblend(darkenlayer,inpict,1,'darkenrgb');

imshow2(outpict,'invert')

%% Color Tint
% Original FX Foundry script author: elsamuko
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
color = [0 0 255]; % range [0 255]; default [0 0 255]
opacity = 100; % range [0 100]; default 100
saturation = 100; % range [0 100]; default 100
desaturate = true; % true or false; default false
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

templayer = colorpict(imsize(inpict,3),color,'uint8');
satpict = ghlstool(inpict,[0 0 saturation]);
tempmask = imappmat(satpict,color/255);

%tintlayer = replacepixels(templayer,inpict,tempmask); % screen mode with spec opacity
tintlayer = imblend(tempmask,templayer,1,'multiply');
tintmask = mono(satpict,'s'); % S in HSV

if desaturate
	% GIMP colors-desaturate:luminosity uses BT709 luma
	inpict = mono(inpict,'y709');
end

outpict = imblend(tintlayer,inpict,opacity/100,'screen');
outpict = replacepixels(outpict,inpict,tintmask);

imshow2(outpict,'invert')

%% B&W Film Simulation
% Original FX Foundry script author: Serge Mankovski, Ari Pollak
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
filmtype = 'Agfa 200X';
filter = 'none'; % default 'none'
optionkeys = {}; % any of: 'lowergamma','saturate','morecontrast'
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% i went ahead and crammed that giant mess into a function:
outpict = bwfilmemu(inpict,filmtype,filter,optionkeys{:});

imshow2(outpict,'invert')

%% Tone Presets
% Original GMIC script author: Iain Fergusson
clc; clf; clear variables

% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%
preset = 'warm vintage';
amount = 1; % range [0 2]; default 1
rangeenforcement = 'clamp'; % 'clamp' or 'normalize'; default 'clamp'
inpict = imread('peppers.png');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% i went ahead and crammed that horrible mess into a set of functions
% see tonergb, tonecmyk, tonepreset
outpict = tonepreset(inpict,preset,amount,rangeenforcement);

imshow2(outpict,'invert')


%% ignore me

bb = imread('2.png');
OP = dotmask(outpict,bb,0.8);
imshow2(OP,'invert')
































































