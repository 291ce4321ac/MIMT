% EXTRA EXAMPLES 
% depending on your filesystem, your pwd and where you stick this script, 
% you may need to change the path strings used for input/output.

% some of these may be configured for viewing on an inverted display
% if something looks inverted, just check the call to imshow() or imshow2()
% as i am likely the most common user of these files, i tend to leave them configured for my own use

% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

%% rectds example with masking
clc; clearvars;
inpic = imread('sources/blacklight2.jpg', 'jpeg');

% parameters are specified at endpoints of loop
F = 8;
bsize = [F F*3/2; F F*3/2]; % block size x,y -- start/finish
Nblocks = [1 1]*1000; % number of blocks -- start/finish
grid = bsize*0;    % grid size x,y -- start/finish
Nframes = 20;
RGBlock = 1;           % perform spatial dithering on channels non-independently
opacity = 1;           % opacity of block layers (pertains to blendmode)
blendmode = 'normal';  % see 'help imblend'
blendamount = 1;       % amount parameter passed to blend function (used only for dodge/burn/permute)
maskblack = 1;         % black mask pixels are not blended in output composition
rim = 0;
outlines = 0;     

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

blockpic = rectds(inpic,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines);
blendpic = imblend(blockpic,inpic,opacity,blendmode,blendamount);

% demonstrates 4-D masking and pixel replacement
if maskblack == 1
    mask = multimask(blockpic,'eq',[0 0 0]);
    outpic = replacepixels(inpic,blockpic,mask); 
else 
    outpic = blendpic;
end
gifwrite(outpic,'rectds.gif');

return; % prevents the entire file from being run straight-through

%% perform rectds once on each layer of a gif
clc; clearvars;

inpic = gifread('sources/fluffball.gif');
inpic = inpic(:,:,1:3,:);

F = 10;
bsize = [1 1; 1 1]*F; % block size x,y -- start/finish
Nblocks = [1 1]*2000; % number of blocks -- start/finish
grid = bsize*1.2;    % grid size x,y -- start/finish
Nframes = 1;
RGBlock = 1;           % perform spatial dithering on channels non-independently
opacity = 1;           % opacity of block layers (pertains to blendmode)
blendmode = 'hardmixib';  % see 'help imblend'
blendamount = 0.5;       % amount parameter passed to blend function (used only for dodge/burn/permute)
maskblack = 0;         % black mask pixels are not blended in output composition
rim = F/5*1;
outlines = 0;   
mode = 'mean';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outpic = zeros(size(inpic),'uint8');
for f = 1:1:size(inpic,4);
    blockpic = rectds(inpic(:,:,:,f),bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines,mode);
    blendpic = imblend(blockpic,inpic(:,:,:,f),opacity,blendmode,blendamount);

    % demonstrates 4-D masking and pixel replacement
    if maskblack == 1
        mask = multimask(blockpic,'eq',[0 0 0]);
        outpic(:,:,:,f) = replacepixels(inpic(:,:,:,f),blockpic,mask); 
    else 
        outpic(:,:,:,f) = blendpic;
    end
end

gifwrite(outpic,'rectds.gif');

%% with addflow overlay
clc; clearvars;

projdir = ''; % put an explicit path here if you want
inpict = imread([projdir 'sources/goat.jpg'], 'jpeg');
outname = 'drift';

numframes = 8; % factor of most noticeable cycle size
direction = [-1 1]; % normally a unit vector [X Y]
bluramount = [16]'; % blur sequence along path (integer factors are best)
blurmode = 'rgb'; % rgb or hsv
disableagrad = 0; % true to disable gradient blending of drift layers
opacity = 1;  % opacity of downsampled drift layers (pertains to blendmode)
blendmode = 'normal'; % see 'help imblend'
blendamount = 0.5; % amount parameter passed to blend function (used only for dodge/burn/permute)
numoverlays = 3; % number of copies to overlay (0 for none)

% offsets downsampling per color channel RGBxXY (nonfactoring offsets muddy non-sparse images)
    %coloroffset=[0 0; 0 0; 0 0]; 
    coloroffset = [-min(bluramount) min(bluramount); min(bluramount) -min(bluramount); 0 0]/4; 

% single bg picture or one per frame
    bgpict = inpict;
    %bgpict=batchloader([projdir 'drift/'],1:1:numframes,'drift.jpg');
    %bgpict=batchloader([projdir 'drift/cachebatch/'],1:1:numframes,'poop.jpg');
    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wpict = driftds(inpict,numframes,direction,bluramount,blurmode,disableagrad,coloroffset);
out = imblend(wpict,bgpict,opacity,blendmode,blendamount);

% implements a muli-addflow overlay
if numoverlays > 0
    k = numoverlays;
    blendmode = 'overlay';    
    opacity = 1/k;
    for n = 1:1:k
        bluramount = bluramount*2;
        wpict = driftds(inpict,numframes,direction,bluramount,blurmode,disableagrad,coloroffset);
        out = imblend(wpict,out,opacity,blendmode,blendamount);
    end
end

gifwrite(out,[projdir outname '.gif']);

imshow(out(:,:,:,1))

%% vector rescan emulation
% deonstrate VECTORSCAN()
% While this is normally a slow kludge, this evolves to be a complete disaster in R2012b and newer!  
% You have been warned.
clearvars; clc; clf
format compact;

projdir = ''; % put an explicit path here if you want
%inpict=imread([projdir 'sources/probe.jpg']);
inpict = gifread([projdir 'sources/fluffball.gif']);
inpict = inpict(:,:,1:3,:);

numlines = 48;    % number of scan lines
scanamp = 0.17/4;  % maximum signal amplitude (relative to image height)
srad = 4;     % radius used for input smoothing

delay = 0.100; % delay for gif animation

% adjust this particular image as desired
%inpict=fourdee(@imresizeFB,inpict,0.33);
%inpict=repmat(inpict,[1 1 1 3]);
% end adjustment

tic
wpict = vectorscan(inpict,numlines,scanamp,'srad',srad);
toc

if size(wpict,4) == 1
    imwrite(wpict,[projdir 'scanner.jpg'],'jpeg','Quality',90);
else
    gifwrite(wpict,[projdir 'scanner.gif'],delay);
end 

imshow(wpict(:,:,:,1))

%% simplified automatic spectrogram obfuscation
% encode an image into audio spectra
clearvars; clc; clf
format compact;

projdir = ''; % put an explicit path here if you want
inpict = imread([projdir 'sources/blacklight2.jpg'], 'jpeg');
outpath = [projdir 'soundpicture.wav']; 

% typical image adjustments
invert = 0;           % invert if 1
flip = 0;             % flip horizontal if 1

blurrad = 5;          % gaussian blur radius (approx 2-5)
alteraspect = 0.80;   % correct for viewer distortion
padbar = 0.08;        % relative height of top padding (H = 1+padwidth)
volume = 1;           % adjust signal volume (will clip beyond unity)
% add blur to reduce bright edge artifacts
% use padbar to keep image below mp3 cutoff (0 for none)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% invert where requested
if (invert == 1); inpict = 255-inpict; end

% flip where requested
if (flip == 1); inpict = fliplr(inpict); end

im2spectrogram(inpict,outpath,alteraspect,padbar,volume,blurrad);

%% create text marquee for spectrogram
% produces a simple marquee at the given frequency location
% use appropriate tools to mix this into other audio
clearvars; clc; clf
format compact;

projdir = ''; % put an explicit path here if you want
outpath = [projdir 'soundpicture.wav']; 

instring = 'Tell me about the loneliness of good, He-Man. Is it equal to the loneliness of evil? ';

% typical image adjustments
alteraspect = 0.80;   % correct for viewer distortion
textheight = 0.06;    % relative height of text
textlocation = 0.86; % frequency center of text
volume = 0.1;         % adjust signal volume (will clip beyond unity)

blurrad = 5;          % gaussian blur radius (approx 2-5)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

text2spectrogram(instring,outpath,textheight,textlocation,alteraspect,volume,blurrad);

%% demo randspots, gradients, and eoline
clearvars; clc; clf
format compact

s = [800 1000 3];
numspots = 100;
spotbounds = [25 100];
spotopacity = [0.2 0.9];
shape = 'rectangle';
fill = [0.2 0.8];

h = fkgen('disk',5);
bspots = imfilterFB(randspots(s,numspots/2,spotbounds,spotopacity,shape,fill),h);
spots = randspots(s,numspots/2,spotbounds,spotopacity,shape,fill);
spots = imblend(straightshifter(spots,ones(3,2)*5),spots,0.5,'lighten rgb');
spots = imblend(bspots,spots,0.5,'screen');

grad = lingrad(s,[0 0; 1 1],[255 255 0; 128 0 255]*0.8);
%grad=radgrad(s,[0 0],1,[255 128 0; 128 0 255]*0.9);
lines = imfilterFB(eoline(grad,1,[5 15]),h);
grad = imblend(lines,grad,0.1,'normal');

wpict = imblend(spots,grad,1,'overlay');
imshow(wpict);

%% do a thing with replacepixels and RGB pixel masking
clearvars; clc; clf
format compact;

projdir = ''; % add a path if you need to
bg = imread([projdir 'sources/probe.jpg'], 'jpeg');

s = size(bg);
spots = randspots(s,100,[50 100],[0 0.3],'rectangle');
fg = imlnc(randlines(size(bg),1,'sparsity',0.95,'mode','walks','rate',0.2));
fg = imblend(spots,fg,1,'permute dh>h',0.1);

mask = imlnc(randlines(size(bg),2,'sparsity',0.98,'mode','walks','rate',10));
mask = imblend(flipd(flipd(spots,2),1),mask,1,'overlay',1);
mask = imadjust(mask,[0.2 0.9]);

flipbg = replacepixels(circshift(bg,[0 25 0]),bg,imlnc(spots));
bg = imblend(bg,flipbg,1,'permute dy>h',0.5);

result = replacepixels(fg,bg,mask);
imshow(result)

%% broken fax machine (a com string from IMDESTROYER())
inpict = imread('sources/blacklight2.jpg');

blocksize = 0.2;
amt = 1; 
shamt = fix(-10+20*[0.905792 0.632359; 0.126987 0.0975404; 0.913376 0.278498]); 
inpict = straightshifter(inpict,shamt*amt); 
blsize = round(16+(64-16).*[0.957507 0.964889 0.157613]); 
field = blockify(inpict,blsize*blocksize,'hsv'); 
inpict = imblend(field,inpict,0.970593*amt,'normal'); 
direction = 1+round(0.80028); 
rate = 0.2+(2-0.2).*0.421761; 
field = imlnc(randlines(size(inpict),mod(direction,2)+1,'sparsity',0.915736,'mode','walks','rate',rate)); 
blendmodes = {'multiply' 'overlay' 'screen' 'addition' 'hue' 'color' 'scale add' 'scale mult'}; 
mode = char(blendmodes(ceil(length(blendmodes)*0.538601))); 
inpict = imblend(field,inpict,0.991704*amt,mode); 
shamt = fix(-10+20*[0.980455 0.0514361; 0.234783 0.756875; 0.528559 0.60198]); 
inpict = straightshifter(inpict,shamt*amt); 
shamt = fix(-10+20*[0.988277 0.000341462; 0.929484 0.540878; 0.409515 0.207731]); 
inpict = straightshifter(inpict,shamt*amt); 
inpict = jpegger(inpict,50*(amt+0.325806*amt)); 
se = strel('line',ceil(15*0.748509), ceil(90*0.543299)); 
field = dilatemargins(inpict,[0.0265 0.06353],se); 
inpict = imblend(field,inpict,0.552572*amt,'normal'); 
w = size(inpict,2); 
f = w/400+(w/400-w/100)*0.892833; 
lt = 30+(60-30)*0.356504; 
frame = picdynamics(inpict,f,lt,'squeeze','luma'); 
inpict = imblend(frame,inpict,1,'scale mult',1); 
rchan = -3+(3+3).*[0.622803 0.796625 0.745875]; 
rchan = ceil(abs(rchan)).*sign(rchan); 
field = permutechannels(inpict,rchan,'hsv'); 
inpict = imblend(field,inpict,0.125536*amt,'normal'); 

inpict = mono(inpict,'v');
imshow(inpict)

















