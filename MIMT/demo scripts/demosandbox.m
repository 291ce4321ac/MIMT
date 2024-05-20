
% DEMOS USED IN WEB DOCUMENTATION
% most of these blocks are the same as what's in the html overview

% some of these may be configured for viewing on an inverted display
% if something looks inverted, just check the call to imshow() or imshow2()
% as i am likely the most common user of these files, i tend to leave them configured for my own use

% depending on your filesystem, your pwd and where you stick this script, 
% you may need to change the path strings used for input/output.

% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

return; % prevents the entire file from being run straight-through

%% colorpict demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

s = [200 300];
c = [255 128 0];
outpict = colorpict(s,c,'uint8');

imshow(outpict)
%imwrite(outpict,'examples/colorpictex1.jpg','jpeg','Quality',90);

s = [200 300];
c = [0 128 37];
outpict = colorpict(s,c,'uint8');

imshow(outpict)
%imwrite(outpict,'examples/colorpictex2.jpg','jpeg','Quality',90);

%% cropborder demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%inpict=imread('sources/probe.jpg');

%outpict=padarrayFB(inpict,[25 25],0);
%imshow2(outpict)
%imwrite(outpict,'examples/cropborderex1.jpg','jpeg','Quality',90);

inpict = imread('examples/cropborderex1.jpg');
outpict = cropborder(inpict,25);
imshow2(outpict)
%imwrite(outpict,'examples/cropborderex2.jpg','jpeg','Quality',90);

%%
% bear in mind that imread strips the alpha content when called like this
inpict = imread('examples/addborderex2.png');
outpict = cropborder(inpict,[NaN NaN]);
imshow2(outpict)
%imwrite(outpict,'examples/cropborderex3.jpg');

%%
inpict = imread('sources/probe.jpg');
outpict = cropborder(inpict,[NaN NaN NaN NaN],'automode','deltavar','threshold',0.001);
imshow2(outpict,'invert')
%imwrite(outpict,'examples/cropborderex3.jpg');

%% dilatemargins demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [300 500 3];
grad = lingrad(s,[0 0; 1 1],[0 128 255; 255 0 128]);
clouds = perlin(s);
inpict = imlnc(imblend(clouds,grad,1,'contrast'));

se = simnorm(fkgen('disk',5*2)) > 0.5;
outpict = dilatemargins(inpict,0.1,se,'independent');
%outpict=dilatemargins(inpict,0.01,se,'union');

imcompare('inpict','outpict','invert')
%imwrite(inpict,'examples/dilatemarginsex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/dilatemarginsex2.jpg','jpeg','Quality',90);

%% driftds demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear all;
projdir = '/data/homebak/cad_and_projects/imagepooper/';
inpict = imresizeFB(imread('sources/blacklight2.jpg'),0.5);

numframes = 8; 
direction = [1 1]; 
bluramount = [16 32]'; 
blurmode = 'rgb'; % rgb or hsv
disableagrad = 1; % true to disable gradient blending of drift layers

% offsets downsampling per color channel RGBxXY (nonfactoring offsets muddy non-sparse images)
    coloroffset = [0 0; 0 0; 0 0]; 
    %coloroffset=[-min(bluramount) min(bluramount); min(bluramount) -min(bluramount); 0 0]/4; 

% single bg picture or one per frame
    bgpict = inpict;

outpict = driftds(inpict,numframes,direction,bluramount,blurmode,disableagrad,coloroffset);

%gifwrite(outpict,'examples/driftdsex4.gif');
imshow(outpict(:,:,:,1))

%% eoline demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/goat.jpg');

outpict = eoline(inpict,1,[1 2]);

imshow(outpict)
%imwrite(outpict,'examples/eolineex1.jpg','jpeg','Quality',90);

%% findpixels demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/colorballs.jpg');

outpict = findpixels(inpict,[1 1 1]*10,'le');

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/findpixelsex1.jpg','jpeg','Quality',90);

%% fourdee demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = gifread('examples/driftdsex1.gif');

outpict = fourdee(@imresizeFB,inpict,0.4);

%gifwrite(outpict,'examples/fourdeeex1.gif');

%% imlnc demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clf; clearvars

inpict = imread('sources/std/lena.jpg');
inpict = imresize(inpict,0.5);

op1 = imlnc(inpict,'independent'); % shifts color balance
op2 = imlnc(inpict,'mean'); % default for RGB inputs
op3 = imlnc(inpict,'lchab'); % causes less saturation shift

outpict = [op1; op2; op3];
imshow(outpict)
%imwrite(outpict,'examples/imlncex1.jpg');

%% demo sgamma compared to power gamma
clc; clf; clearvars

CT = lines(7);

% a unit-scale test ramp
x = linspace(0,1,1E3);

g0 = 0.3; % all modes have the same parameter response

% normal gamma (strongest effect on shadows)
y1 = imlnc(x,'in',[0 1],'out',[0 1],'g',g0,'k',1);
y2 = imlnc(x,'in',[0 1],'out',[0 1],'g',1/g0,'k',1);
plot(x,[y1; y2],'--','color',CT(1,:)); hold on

% reverse gamma (strongest effect on highlights)
y1 = imlnc(x,'in',[0 1],'out',[0 1],'rg',g0,'k',1);
y2 = imlnc(x,'in',[0 1],'out',[0 1],'rg',1/g0,'k',1);
plot(x,[y1; y2],'--','color',CT(2,:))

% symmetric gamma
y1 = imlnc(x,'in',[0 1],'out',[0 1],'sg',g0,'k',1);
y2 = imlnc(x,'in',[0 1],'out',[0 1],'sg',1/g0,'k',1);
plot(x,[y1; y2],'-','color',CT(4,:))

unitaxes(gca)

%% demo sgamma when used for shifting k-curve in imlnc()
clc; clf; clearvars

CT = lines(7);

% a unit-scale test ramp
x = linspace(0,1,1E3);

g0 = 0.6;
k = 2;

% shifting with 'g'
y1 = imlnc(x,'in',[0 1],'out',[0 1],'g',g0,'k',k);
y2 = imlnc(x,'in',[0 1],'out',[0 1],'g',1/g0,'k',k);
plot(x,[y1; y2],'--','color',CT(1,:)); hold on

% shifting with 'sg'
y1 = imlnc(x,'in',[0 1],'out',[0 1],'sg',g0,'k',k);
y2 = imlnc(x,'in',[0 1],'out',[0 1],'sg',1/g0,'k',k);
plot(x,[y1; y2],'-','color',CT(2,:))

unitaxes(gca)

%% imblend demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bg = imread('sources/probe.jpg');
fg = randspots(size(bg),10,[50 150],[0.5 1],'circle');

outpict = imblend(fg,bg,1,'softlight',1);

imshow(outpict)
%imwrite(fg,'examples/imblendex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/imblendex2.jpg','jpeg','Quality',90);
%%
bg = imread('sources/probe.jpg');
fg = imread('sources/probegrad.jpg');

outpict = imblend(fg,bg,1,'colordodge',1);

imshow(outpict)
%imwrite(outpict,'examples/imblendex3.jpg','jpeg','Quality',90);
%%
bg = imread('sources/probe.jpg');
fg = imread('sources/probegrad.jpg');

outpict = imblend(fg,bg,0.5,'colordodge',1);

imshow(outpict)
%imwrite(outpict,'examples/imblendex4.jpg','jpeg','Quality',90);
%%
bg = imread('sources/probe.jpg');
fg = imread('sources/probegrad.jpg');

outpict = imblend(fg,bg,1,'colordodge',0.5);

imshow(outpict)
%imwrite(outpict,'examples/imblendex5.jpg','jpeg','Quality',90);
%%
bg = imread('sources/table.jpg');
fg = imfilterFB(bg,fkgen('glow2',50));

op1 = imblend(fg,bg,1,'flatglow',0.5);
op2 = imblend(fg,bg,1,'softerflatlight');
outpict = cat(1,op1,op2);


imshow2(outpict,'invert')
%imwrite(fg,'examples/imblendex18.jpg')
%imwrite(outpict,'examples/imblendex19.jpg')

%%
% compare glow hybrids (vividness, near-NRL vs distal response)
bg = imread('sources/table.jpg');
fg = imlnc(imfilterFB(bg,fkgen('glow2',50)),'mean','g',0.95,'k',1.5);

op1 = imblend(fg,bg,1,'flatglow');
op2 = imblend(fg,bg,1,'meanglow');
op3 = imblend(fg,bg,1,'starglow');
op4 = imblend(fg,bg,1,'moonglow');
op5 = imblend(fg,bg,1,'moonglow2');
outpict = cat(4,op1,op2,op3,op4,op5);
outpict = imtile(dotmask(outpict,bg,0.95),[NaN 1]);

imshow2(outpict,'invert')
%imwrite(fg,'examples/imblendex20.jpg')
%imwrite(outpict,'examples/imblendex21.jpg')

%%
% pinlight vs similar continuous modes
bg = imread('sources/table.jpg');
fg = imlnc(meanlines(bg,2));
%fg=imlnc(randlines(imsize(bg,2),2,'mode','walks','sparsity',0.9));

op1 = imblend(fg,bg,1,'pinlight');
op2 = imblend(fg,bg,1,'superlight',4);
op3 = imblend(fg,bg,1,'starlight',0.7);
op4 = imblend(fg,bg,1,'moonlight2',1);
outpict = cat(1,op1,op2,op3,op4);

imshow2(outpict,'invert')
%imwrite(fg,'examples/imblendex22.jpg')
%imwrite(outpict,'examples/imblendex23.jpg')

%% imrange demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

[mn mx] = imrange(inpict)

%% jpegger demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

outpict = jpegger(inpict,10);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/jpeggerex1.jpg','jpeg','Quality',90);
%%
sluramt = [2 0; 0 0; 0 2];

outpict = jpegger(inpict,10,sluramt);

paritymap = mod(outpict,16);
paritymap(paritymap ~= 1) = 0;
paritymap = paritymap*255;

imshow2(outpict,'invert','tools')
imshow(paritymap)
%imwrite(outpict,'examples/jpeggerex2.jpg','jpeg','Quality',90);
%imwrite(paritymap,'examples/jpeggerex3.jpg','jpeg','Quality',90);

%% jpegslur demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

sluramt = [10 0; 0 0; -10 0];
outpict = jpegslur(inpict,sluramt,0,10,'original');

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/jpegslurex1.jpg','jpeg','Quality',90);
%%
inpict = imread('sources/blacklight2.jpg');

sluramt = [10 0; 0 0; -10 0];
outpict = jpegslur(inpict,sluramt,3,10,'original');

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/jpegslurex2.jpg','jpeg','Quality',90);

%% lineshifter demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');
mask = lingrad(size(inpict),[0 0; 1 0],[1 1 1; 0 0 0]*255);

sluramt = [1 0; 0 0; -1 0]*0.3;
outpict = lineshifter(inpict,mask,sluramt);

imshow2(outpict,'invert','tools')
%imwrite(mask,'examples/lineshifterex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/lineshifterex2.jpg','jpeg','Quality',90);
%%
inpict = imread('sources/blacklight2.jpg');
m = eoline(colorpict(size(inpict),[1 1 1]*255,'uint8'),1,[10 25]);
mask = replacepixels([255 0 0],colorpict(size(inpict),[0 0 255],'uint8'),m);

sluramt = [1 0; 0 0; -1 0]*0.05;
outpict = lineshifter(inpict,mask,sluramt);

imshow2(outpict,'invert','tools')
%imwrite(mask,'examples/lineshifterex3.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/lineshifterex4.jpg','jpeg','Quality',90);

%% ease curves for gradient functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = linspace(0,1,100);
coint = 0.5*(1-cos(t*pi));
waves = (1-2*0.05)*t+0.05*(1-cos(t*pi*(2*10+1)));
ease = 6*t.^5-15*t.^4+10*t.^3;
cosine = 0.5*(1-cos(pi*t));
softease = (t+coint)/2;
softinv = 2*t-(t+coint)/2;
hardinv = 2*t-coint;
plot(t,waves,':k',t,ease,'b',t,cosine,'g',t,softease,'r',t,t,'c',t,softinv,'y',t,hardinv,'m');

legend('waves [0.05 10]','ease','cosine','softease','linear','softinvert','invert','location','southeast');
%% lingrad demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [400 100 3];
A = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'invert');
B = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'softinvert');
C = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'linear');
D = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'softease');
E = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'cosine');
F = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'ease');
G = lingrad(s,[0 0; 1 0],[0 0 0; 0 1 0]*255,'waves',[0.05 10]);
outpict = cat(2,A,B,C,D,E,F,G);

imshow(outpict)
%imwrite(outpict,'examples/lingradex1.jpg','jpeg','Quality',90);
%%
s = [400 600 3];
colors = [0 0 0; 0.095 0.058 0.494; 0.113 0.067 0.566; 0.514 0.055 0.305; ...
    0.921 0.066 0.042; 0.955 0.266 0.024; 0.999 0.541 0.004; ...
    0.967 0.741 0.114; 0.937 0.924 0.213; 0 0 0; 0 0 0]*255;
breaks = [0 0.056 0.367 0.601 0.752 0.791 0.869 0.897 0.936 0.937 1];

outpict = lingrad(s,[0 0; 1 0],colors,breaks);

imshow(outpict)
%imwrite(outpict,'examples/lingradex2.jpg','jpeg','Quality',90);
%% radgrad demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [300 300 3];
A = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'invert');
B = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'softinvert');
C = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'linear');
D = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'softease');
E = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'cosine');
F = radgrad(s,[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'ease');
G = radgrad(s.*[1 2 1],[1 1]*0.5,0.5,[0 1 0; 0 0 0]*255,'waves',[0.05 5]);
R1 = cat(2,A,B);
R2 = cat(2,C,D);
R3 = cat(2,E,F);
outpict = cat(1,R1,R2,R3,G);

imshow(outpict)
%imwrite(outpict,'examples/radgradex1.jpg','jpeg','Quality',90);
%%
s = [400 600 3];
colors = [0.000000 0.009040 0.166667; 0.089516 0.199522 0.3939395; ...
    0.179032 0.390004 0.621212; 0.179032 0.390004 0.621212; ...
    0.089516 0.6798505 0.7954545; 0.000000 0.969697 0.969697]*255;
breaks = [0.000000 0.580968 0.764608 0.764608 0.888147 1.000000];

outpict = radgrad(s,[0 0],1,flipud(colors),1-fliplr(breaks));

imshow(outpict)
%imwrite(outpict,'examples/radgradex2.jpg','jpeg','Quality',90);

%% meanlines demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

outpict = meanlines(inpict,2,'mean');

imshow(outpict)
%imwrite(outpict,'examples/meanlinesex1.jpg','jpeg','Quality',90);
%%
inpict = imread('sources/blacklight2.jpg');

outpict = meanlines(inpict,1,'max y');

imshow(outpict)
%imwrite(outpict,'examples/meanlinesex3.jpg','jpeg','Quality',90);
%% mono demo
inpict = imread('sources/blacklight2.jpg');

vpict = mono(inpict,'v');
lpict = mono(inpict,'l');
ipict = mono(inpict,'i');
ypict = mono(inpict,'y');

figure(1); imshow(vpict)
figure(2); imshow(lpict)
figure(3); imshow(ipict)
figure(4); imshow(ypict)
%imwrite(vpict,'examples/monoex1.jpg','jpeg','Quality',90);
%imwrite(lpict,'examples/monoex2.jpg','jpeg','Quality',90);
%imwrite(ipict,'examples/monoex3.jpg','jpeg','Quality',90);
%imwrite(ypict,'examples/monoex4.jpg','jpeg','Quality',90);
%% multimask demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/colorballs.jpg');

bounds = [0.85 0.33 0.05; 1 1 0.63]*255;
modes = {'ge','le'};
compare = 'and';

mask = multimask(inpict,modes,bounds,compare);

imshow2(mask,'invert','tools')
%imwrite(mask,'examples/multimaskex1.jpg','jpeg','Quality',90);
%%
s = [400 500];
%hgrad=double(lingrad(s,[0 0; 1 0],[0; 1]*255))/255;
%sgrad=double(lingrad(s,[0 0; 0 1],[0; 1]*255))/255;
%vgrad=ones(s);
%HS=hsv2rgb(cat(3,hgrad,sgrad,vgrad))*255;
R = lingrad(s,[0 0; 1 0],[0; 1]*255);
G = lingrad(s,[0 0; 0 1],[0; 1]*255);
B = ones(s)*255;

bounds = [0.85 0.33 0.05; 1 1 0.63]*255;
modes = {'ge','le'};
compare = 'and';

frames = 32;
inpict = zeros([s 3 frames],'uint8');
for f = 1:frames;
    %inpict(:,:,:,f)=uint8(HS*f/frames);
    inpict(:,:,:,f) = cat(3,R,G,uint8(B*f/frames));
end
mask = multimask(inpict,modes,bounds,compare);

%gifwrite(inpict,'examples/multimaskex2.gif',0.1);
%gifwrite(mask,'examples/multimaskex3.gif',0.1);
%% demonstrate parity sweep %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/bananas.jpg', 'jpeg');

modsize = 40; 
width = 1; 
quality = 30;

cpict = jpegger(inpict,quality);
paritypic = paritysweep(cpict,modsize,width);

%imwrite(cpict,'examples/paritysweepex1.jpg','jpeg','Quality',90);
%gifwrite(paritypic,'examples/paritysweepex2.gif',0.05);
%%
inpict = imread('sources/bananas.jpg', 'jpeg');

modsize = 40; 
width = 5; 
quality = 30;

cpict = jpegger(inpict,quality);
paritypic = paritysweep(cpict,modsize,width);

%imwrite(cpict,'examples/paritysweepex1.jpg','jpeg','Quality',90);
%gifwrite(paritypic,'examples/paritysweepex3.gif',0.05);
%% perlin demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [400 500 3];

outpict = perlin(s);

imshow(outpict)
%imwrite(outpict,'examples/perlinex1.jpg','jpeg','Quality',90);
%% 
s = [400 500 3];

outpict = perlin(s,'correl',0);

imshow(outpict)
%imwrite(outpict,'examples/perlinex2.jpg','jpeg','Quality',90);
%%
s = [400 1 3];

outpict = perlin(s,'correl',1);
outpict = repmat(outpict,[1 500 1]);

imshow2(outpict)
%imwrite(outpict,'examples/perlinex3.jpg','jpeg','Quality',90);

%% perlin3 demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [400 500 1];

outpict = perlin3(s,4,2);

imshow(outpict)
%imwrite(outpict,'examples/perlin3ex1.jpg','jpeg','Quality',90);
%% 
s = [400 500 1];

outpict = perlin3(s,7,2.2);

imshow(outpict)
%imwrite(outpict,'examples/perlin3ex2.jpg','jpeg','Quality',90);
%% 
s = [200 200 64];

outpict = perlin3(s);

imshow(outpict(:,:,1))
outpict = permute(outpict,[1 2 4 3]);
%gifwrite(outpict,'examples/perlin3ex3.gif');

%% permutechannels demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg', 'jpeg');
 
outpict = permutechannels(inpict,[1 3 2],'rgb');

imshow(outpict)
%imwrite(outpict,'examples/permutechannelsex1.jpg','jpeg','Quality',90);
%% 
inpict = imread('examples/jpeggerex1.jpg', 'jpeg');
 
outpict = permutechannels(inpict,[2 1 2],'hsv');
outpict = imtweak(outpict,'hsv',[1 1 -1]);

imshow(outpict)
%imwrite(outpict,'examples/permutechannelsex2.jpg','jpeg','Quality',90);
%% picdynamics demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/goat.jpg');

dpict = picdynamics(inpict,10,60,'squeeze','rgb');

sluramt = [1 0; 0 0; -1 0]*4;
slurpict = jpegslur(inpict,sluramt,1,10,'original');
outpict = imblend(dpict,slurpict,1,'contrast',1.5);
outpict = imblend(mono(meanlines(slurpict,2),'y'),outpict,1,'contrast',0.7);

imshow2(outpict,'invert','tools')
%imwrite(dpict,'examples/picdynamicsex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/picdynamicsex2.jpg','jpeg','Quality',90);
%% rangemask demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/colorballs.jpg');

chans = 'h';
range = [0.04 0.06]*255; % orange circle
%range=[0.57 0.59]*255;  % blue circle
%range=[0.89 0.91]*255; % pink circle
compmode = 'and';

mask = rangemask(inpict,chans,range,compmode);

imshow(mask)
%imwrite(mask,'examples/rangemaskex1.jpg','jpeg','Quality',90);
%%
s = [400 500];
R = lingrad(s,[0 0; 1 0],[0; 1]*255);
G = lingrad(s,[0 0; 0 1],[0; 1]*255);
B = ones(s)*255;

frames = 32;
inpict = zeros([s 3 frames],'uint8');
for f = 1:frames;
    inpict(:,:,:,f) = cat(3,R,G,uint8(B*f/frames));
end

compmode = 'and';
chans = 'h';
range = [0.04 0.06]*255; % use H only
hsvmask = rangemask(inpict,chans,range,compmode);

chans = 'rgb';
range = [0.85 1; 0.33 1; 0.05 0.63]*255; % use RGB
rgbmask = rangemask(inpict,chans,range,compmode);

mask = uint8(0.5*double(hsvmask)*255) ...
    +uint8(0.5*double(rgbmask)*255);

%gifwrite(mask,'examples/rangemaskex2.gif',0.1);
%% ismono demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colorpict = gifread('examples/driftdsex1.gif');
greypict = imtweak(inpict,'hsv',[1 0 1]);
redchannel = colorpict(:,:,1,:);

size_of_colorpict = size(colorpict)
is_colorpict_monochrome = ismono(colorpict)

size_of_greypict = size(greypict)
is_greypict_monochrome = ismono(greypict)

size_of_redchannel = size(redchannel)
is_red_channel_monochrome = ismono(redchannel)

imshow(greypict(:,:,:,1))
%gifwrite(greypict,'examples/ismonoex1.gif');
%gifwrite(redchannel,'examples/ismonoex2.gif');
%% glasstiles demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

tiles = [1 1]*40;
outpict = glasstiles(inpict,tiles,'coherent');
outpict = imblend(outpict,outpict,1,'softlight');

imshow(outpict)
%imwrite(outpict,'examples/glasstilesex1.jpg','jpeg','Quality',90);
%%
inpict = imread('sources/blacklight2.jpg');

tiles = [1 1]*40;
outpict = glasstiles(inpict,tiles,'random');
outpict = imblend(outpict,outpict,1,'softlight');

imshow(outpict)
%imwrite(outpict,'examples/glasstilesex2.jpg','jpeg','Quality',90);
%% randlines demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [600 200];
mode = 'normal';
A = repmat(randlines(s,2,'sparsity',0,'mode',mode,'mono'),[1 1 3]);
C = randlines(s,2,'sparsity',0,'mode',mode);
B = repmat(randlines(s,2,'sparsity',0.90,'mode',mode,'mono'),[1 1 3]);
D = randlines(s,2,'sparsity',0.90,'mode',mode);
outpict = cat(2,A,B,C,D);

imshow(outpict)
%imwrite(outpict,'examples/randlinesex1.jpg','jpeg','Quality',90);
%% 
s = [600 200];
mode = 'walks';
A = repmat(randlines(s,2,'sparsity',0,'mode',mode,'mono'),[1 1 3]);
B = repmat(randlines(s,2,'sparsity',0.95,'mode',mode,'mono'),[1 1 3]);
C = randlines(s,2,'sparsity',0,'mode',mode);
D = randlines(s,2,'sparsity',0.95,'mode',mode);
outpict = cat(2,A,B,C,D);

imshow(outpict)
%imwrite(outpict,'examples/randlinesex2.jpg','jpeg','Quality',90);
%% 
s = [600 200];
mode = 'walks';
A = repmat(imlnc(randlines(s,2,'sparsity',0,'mode',mode,'mono')),[1 1 3]);
B = repmat(imlnc(randlines(s,2,'sparsity',0.95,'mode',mode,'mono')),[1 1 3]);
C = imlnc(randlines(s,2,'sparsity',0,'mode',mode));
D = imlnc(randlines(s,2,'sparsity',0.95,'mode',mode));
outpict = cat(2,A,B,C,D);

imshow(outpict)
%imwrite(outpict,'examples/randlinesex3.jpg','jpeg','Quality',90);
%% 
s = [600 200];
mode = 'ramps';
A = repmat(randlines(s,2,'mono','mode',mode,'rate',3),[1 1 3]);
B = repmat(randlines(s,2,'mono','mode',mode,'rate',1),[1 1 3]);
C = randlines(s,2,'mode',mode,'rate',3);
D = randlines(s,2,'mode',mode,'rate',1);
outpict = cat(2,A,B,C,D);

imshow(outpict)
%imwrite(outpict,'examples/randlinesex4.jpg','jpeg','Quality',90);
%% randspots demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [500 300 3];
numspots = 20;
shape = 'circle';
bounds = [30 70];
opacity = [0.1 0.7];
A = randspots(s,numspots,bounds,opacity,shape);
B = randspots(s,numspots,bounds,opacity,shape,[0.2 0.8]);
outpict = cat(2,A,B);

imshow(outpict)
%imwrite(outpict,'examples/randspotsex1.jpg','jpeg','Quality',90);
%%
s = [500 300 3];
numspots = 20;
shape = 'square';
bounds = [30 70];
opacity = [0.1 0.7];
A = randspots(s,numspots,bounds,opacity,shape);
B = randspots(s,numspots,bounds,opacity,shape,[0.2 0.8]);
outpict = cat(2,A,B);

imshow(outpict)
%imwrite(outpict,'examples/randspotsex2.jpg','jpeg','Quality',90);
%%
s = [500 300 3];
numspots = 20;
shape = 'rectangle';
bounds = [30 70];
opacity = [0.1 0.7];
A = randspots(s,numspots,bounds,opacity,shape);
B = randspots(s,numspots,bounds,opacity,shape,[0.2 0.8]);
outpict = cat(2,A,B);

imshow(outpict)
%imwrite(outpict,'examples/randspotsex3.jpg','jpeg','Quality',90);
%% thresholdinpaint demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('examples/perlinex3.jpg', 'jpeg');

s = size(inpict);
gridratio = [30 50];
mask = eoline(ones(s(1:2)),2,gridratio);
mask = ~logical(eoline(mask,1,gridratio));

outpict = thresholdinpaint(inpict,'rgb',mask,0,0);
imshow(outpict)
%imwrite(mask,'examples/thresholdinpaintex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/thresholdinpaintex2.jpg','jpeg','Quality',90);
%%
inpict = imread('sources/goat.jpg');
se = simnorm(fkgen('disk',4));
mask = morphops(rangemask(inpict,'sv',[0 0.5; 0 0.5]*255),se,'open');
outpict = thresholdinpaint(inpict,'rgb',mask,0,0);
imshow(outpict)
%% roiflip demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is setup for the following
%imwrite(inpict,'examples/roidemostripes.jpg','jpeg','Quality',90);
%imwrite(mask,'examples/roimask2circ.jpg','jpeg','Quality',90);
%imwrite(mask,'examples/roimask3circ.jpg','jpeg','Quality',90);
%%
%mask=randspots(s,2,[100 400],[1 1],'circle');
mask = imread('examples/roimask2circ.jpg', 'jpeg');
mask = ~findpixels(mask,[1 1 1]*15,'le');
s = size(mask);
%inpict=imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

cont = roiflip(inpict,mask,2,'segment'); 
disc = roiflip(inpict,mask,2,'whole');

padbar = zeros([10 s(2) 3], 'uint8');
outpict = cat(1,cont,padbar,disc);
imshow(outpict)
%imwrite(outpict,'examples/roiflipex1.jpg','jpeg','Quality',90);
%%
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);
%inpict=imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

cont = roiflip(inpict,mask,2,'segment'); 
disc = roiflip(inpict,mask,2,'whole');

padbar = zeros([10 s(2) 3], 'uint8');
outpict = cat(1,cont,padbar,disc);
imshow(outpict)
%imwrite(outpict,'examples/roiflipex2.jpg','jpeg','Quality',90);
%% roishift demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);
%inpict=imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

amt = 40;
fill = 'circular';
cont = roishift(inpict,mask,2,amt,'segment',fill); 
disc = roishift(inpict,mask,2,amt,'whole',fill);

padbar = zeros([10 s(2) 3], 'uint8');
outpict = cat(1,cont,padbar,disc);
imshow(outpict)
%imwrite(outpict,'examples/roishiftex1.jpg','jpeg','Quality',90);
%% 
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);
%inpict=imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

amt = 40;
fill = 'replicate';
cont = roishift(inpict,mask,2,amt,'segment',fill); 
disc = roishift(inpict,mask,2,amt,'whole',fill);

padbar = zeros([10 s(2) 3], 'uint8');
outpict = cat(1,cont,padbar,disc);
imshow(outpict)
%imwrite(outpict,'examples/roishiftex2.jpg','jpeg','Quality',90);
%% 
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);
%inpict=imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

amt = 40;
fill = [0 0 0];
cont = roishift(inpict,mask,2,amt,'segment',fill); 
disc = roishift(inpict,mask,2,amt,'whole',fill);

padbar = zeros([10 s(2) 3], 'uint8');
outpict = cat(1,cont,padbar,disc);
imshow(outpict)
%imwrite(outpict,'examples/roishiftex3.jpg','jpeg','Quality',90);
%% straightshifter demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

amt = [1 0; 0 1; -1 0]*20;
outpict = straightshifter(inpict,amt);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/straightshifterex1.jpg','jpeg','Quality',90);
%% 
inpict = imread('sources/blacklight2.jpg');

srad = 30;
amt = [1 0; 0 1; -1 0]*srad;
outpict = padarrayFB(inpict,[1 1]*srad,'replicate');
outpict = straightshifter(outpict,amt);
outpict = cropborder(outpict,srad);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/straightshifterex2.jpg','jpeg','Quality',90);
%% shuffle demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');

tiles = [1 1]*5;
outpict = shuffle(inpict,tiles);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/shuffleex1.jpg','jpeg','Quality',90);
%% 
inpict = imread('sources/blacklight2.jpg');

tiles = [1 1]*5;
outpict = shuffle(inpict,tiles,'independent');

imshow(outpict)
%imwrite(outpict,'examples/shuffleex2.jpg','jpeg','Quality',90);
%% 
inpict = imread('sources/blacklight2.jpg');

tiles = [1 1]*10;
forward = 1:1:prod(tiles);
reverse = prod(tiles):-1:1;
perms = [reverse; forward; forward];
outpict = shuffle(inpict,tiles,'independent',perms);

imshow(outpict)
%imwrite(outpict,'examples/shuffleex3.jpg','jpeg','Quality',90);
%% demo replacepixels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bg = imread('sources/probe.jpg');

bg = imlnc(bg);
fg = imtweak(glasstiles(bg,[30 60]),'hsv',[-1/3 1 1]);
greymask = imread('sources/probegrad.jpg');
outpict = replacepixels(fg,bg,greymask);

imshow(outpict)
%imwrite(outpict,'examples/replacepixelsex1.jpg','jpeg','Quality',90);
%imwrite(fg,'examples/replacepixelsm1.jpg','jpeg','Quality',90);

%%
bg = imread('sources/probe.jpg');

bg = imlnc(bg);
fg = imtweak(glasstiles(bg,[30 60]),'hsv',[-1/3 1 1]);
s = size(bg);
greymask = imread('sources/probegrad.jpg');
greymask = greymask(:,:,1);
stopmask = zeros(s(1:2),'uint8');
colormask = cat(3,greymask,greymask,stopmask);

outpict = replacepixels(fg,bg,colormask);
imshow(outpict)
%imwrite(outpict,'examples/replacepixelsex2.jpg','jpeg','Quality',90);
%imwrite(colormask,'examples/replacepixelsm2.jpg','jpeg','Quality',90);
%% replacepixels demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);

fill = [0 255 0];
bg = imlnc(randlines(s,1,'sparsity',0.95,'mode','walks','rate',0.2));

outpict = replacepixels(fill,bg,mask);

imshow(outpict)
%imwrite(bg,'examples/replacepixelsex1.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/replacepixelsex2.jpg','jpeg','Quality',90);
%% 
mask = imread('examples/findpixelsex1.jpg');
mask = findpixels(mask,[1 1 1]*15,'le');
s = size(mask);

spot = zeros([s 3 3],'uint8');
spot(:,:,:,1) = radgrad([s 3],[59 211]./s,0.1,[105 74 42; 0 0 0],'cosine');
spot(:,:,:,2) = radgrad([s 3],[161 572]./s,0.1,[105 74 42; 0 0 0],'cosine');
spot(:,:,:,3) = radgrad([s 3],[243 820]./s,0.1,[105 74 42; 0 0 0],'cosine');
spots = sum(spot,4);

flines = imlnc(randlines(s,2,'sparsity',0.95,'mode','walks','rate',0.2));
fgrad = lingrad([s 3],[0 0; 1 1],[105 74 42; 0 0 0]*0.5,'cosine');
fgrad = imblend(spots,fgrad,1,'screen');
fg = imblend(fgrad,flines,1,'scaleadd',0.8);

blines = imlnc(randlines(s,2,'sparsity',0.95,'mode','walks','rate',0.2));
bgrad = lingrad([s 3],[1 1; 0 0],[155 92 219; 0 0 0],'softease');
bg = imblend(bgrad,blines,1,'scaleadd',1);

outpict = replacepixels(fg,bg,mask);

imshow(outpict)
%imwrite(fg,'examples/replacepixelsex3.jpg','jpeg','Quality',90);
%imwrite(bg,'examples/replacepixelsex4.jpg','jpeg','Quality',90);
%imwrite(outpict,'examples/replacepixelsex5.jpg','jpeg','Quality',90);
%% mergedown demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = gifread('sources/bouncingball.gif');
inpict = 255-inpict(:,:,1:3,:);

outpict = mergedown(inpict,0.5,'screen');

imshow2('outpict','invert','tools')
%gifwrite(inpict, 'examples/mergedownex1.gif')
%gifwrite(outpict, 'examples/mergedownex2.gif')
%% imecho demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = gifread('examples/mergedownex1.gif'); 
% idk why this dumb gif has an extra redundant end frame 
% i didn't make the original
inpict = inpict(:,:,:,1:end-1);

outpict = imecho(inpict,5,'blendmode','screen');

imshow2(outpict,'invert','tools')
%gifwrite(outpict, 'examples/imechoex1.gif')
%% 
inpict = gifread('examples/mergedownex1.gif');
inpict = inpict(:,:,:,1:end-1);

outpict = imecho(inpict,5,'blendmode','screen','skip',2);

imshow2(outpict,'invert','tools')
%gifwrite(outpict, 'examples/imechoex2.gif')
%% 
inpict = gifread('examples/mergedownex1.gif');
inpict = inpict(:,:,:,1:end-1);

outpict = imecho(inpict,0,'blendmode','screen','skip',1,'offset',[0 2 4]);

imshow2(outpict,'invert','tools')
%gifwrite(outpict, 'examples/imechoex3.gif')
%% 
inpict = gifread('examples/mergedownex1.gif');
inpict = inpict(:,:,:,1:end-1);

outpict = imecho(inpict,5,'blendmode','screen','skip',2,'offset',[0 0 0],'blocksmode');

imshow2(outpict,'invert','tools')
%gifwrite(outpict, 'examples/imechoex4.gif')
%% eoframe demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = gifread('examples/mergedownex1.gif');

outpict = eoframe(inpict,2);

%gifwrite(outpict, 'examples/eoframeex1.gif')
%%
inpict = gifread('examples/mergedownex1.gif');

outpict = eoframe(inpict,2,'expand');

%gifwrite(outpict, 'examples/eoframeex2.gif')
%% rectds demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear all;
inpict = imread('sources/probe.jpg', 'jpeg');

F = 16;
bsize = [F*3/2 F; F*3/2 F]; 
Nblocks = [1 1]*5000; 
grid = bsize*0;   
Nframes = 20;
RGBlock = 1; 
rim = 0;
outlines = 0;     

blockpict = rectds(inpict,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines);

%gifwrite(blockpict,'examples/rectdsex1.gif');
%% 
inpict = imread('sources/probe.jpg', 'jpeg');

F = 8;
bsize = [F F*5/2; F*5/2 F]; 
Nblocks = [0.5 2]*1000; 
grid = bsize*0;   
Nframes = 20;
RGBlock = 1; 
rim = 0;
outlines = 0;     

blockpict = rectds(inpict,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines);

%gifwrite(blockpict,'examples/rectdsex2.gif');
%%
inpict = imread('sources/probe.jpg', 'jpeg');

F = 10;
bsize = [F F; F F]; 
Nblocks = [1 1]*5000; 
grid = bsize*0;   
Nframes = 20;
RGBlock = 1; 
rim = F/5;
outlines = 1;     

blockpict = rectds(inpict,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines);

%gifwrite(blockpict,'examples/rectdsex3.gif');
%%
inpict = imread('sources/probe.jpg', 'jpeg');

F = 10;
bsize = [F F*3/2; F F*3/2]; 
Nblocks = [1 1]*1000; 
grid = bsize*1.2;   
Nframes = 20;
RGBlock = 0; 
rim = 0;
outlines = 0;     

blockpict = rectds(inpict,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines);

%gifwrite(blockpict,'examples/rectdsex4.gif');
%% im2ods demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; clc;
format compact;

inpict = imread('sources/blacklight2.jpg', 'jpeg');
outfile = 'outfile.ods';
pixelsize = 0.06;
imwidth = 160;

im2ods(inpict,outfile,pixelsize,imwidth);
%% rotateds demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [500 500 3];
rat = [2 80];
se = simnorm(fkgen('disk',60));

inpict = lingrad(s,[0 0; 0 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1]*255);
inpict = eoline(eoline(inpict,1,rat),2,rat);
inpict = morphops(inpict,se,'dilate');

numframes = 32;
blurcycles = 3; 
shiftcycles = 1; 
maxblur = 15;
maxshift = 0.1; 

outpict = rotateds(inpict,numframes,blurcycles,shiftcycles,maxblur,maxshift);

%gifwrite(outpict,'examples/rotatedsex1.gif');
%imwrite(inpict,'examples/rotatedspat.jpg','jpeg','Quality',90);
%% rgb2hsi demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [250 250 3];
inpict = lingrad(s,[0 0; 0 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 0.8 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0.2 0],[0 0 0; 1 1 1]*255);
inpict = imblend(sgrad,inpict,1,'transfer v_hsv>s_hsv');
inpict = imblend(vgrad,inpict,1,'transfer v_hsv>v_hsv');

hsipict = rgb2hsi(inpict);
Hhsi = hsipict(:,:,1)/360;
Shsi = hsipict(:,:,2);
Ihsi = hsipict(:,:,3);

hsvpict = rgb2hsv(inpict);
Hhsv = hsvpict(:,:,1);
Shsv = hsvpict(:,:,2);
Vhsv = hsvpict(:,:,3);

comparison = cat(2,cat(1,Hhsi,Shsi,Ihsi),cat(1,Hhsv,Shsv,Vhsv));
imshow(comparison)
%imwrite(inpict,'examples/rgb2hsiex1.jpg','jpeg','Quality',90);
%imwrite(comparison,'examples/rgb2hsiex2.jpg','jpeg','Quality',90);
%% hsi2rgb demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% continue from above
rgbpict = hsi2rgb(hsipict);
rgbpict = uint8(rgbpict*255);

imshow(rgbpict)

%% imtweak demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; clc;
format compact;
inpict = imread('sources/blacklight2.jpg');

cvec = [0 0.3 1];
hsvpict = imtweak(inpict,'hsv',cvec);
hsipict = imtweak(inpict,'hsi',cvec);
hslpict = imtweak(inpict,'hsl',cvec);
ypppict = imtweak(inpict,'ych',fliplr(cvec));
hsypict = imtweak(inpict,'hsy',cvec);
lchabpict = imtweak(inpict,'lchab',fliplr(cvec));
lchuvpict = imtweak(inpict,'lchuv',fliplr(cvec));
lchsrpict = imtweak(inpict,'lchsr',fliplr(cvec));
huslabpict = imtweak(inpict,'huslab',cvec);
husluvpict = imtweak(inpict,'husluv',cvec);

R1 = cat(2,hsvpict,hsipict,hslpict);
R2 = cat(2,ypppict,lchabpict,lchuvpict);
R3 = cat(2,hsypict,huslabpict,husluvpict);
comparison = cat(1,R1,R2,R3);

subplot(1,1,1);
set(gca,'position',[0.01 0.01 0.98 0.98]);

imshow(comparison)
%imwrite(comparison,'examples/imtweakex1.jpg','jpeg','Quality',90);
%% 
clear all; clc;
format compact;
inpict = imread('sources/blacklight2.jpg');

cvec = [0 3 1];
hsvpict = imtweak(inpict,'hsv',cvec);
hsipict = imtweak(inpict,'hsi',cvec);
hslpict = imtweak(inpict,'hsl',cvec);
ypppict = imtweak(inpict,'ych',fliplr(cvec));
hsypict = imtweak(inpict,'hsy',cvec);
lchabpict = imtweak(inpict,'lchab',fliplr(cvec));
lchuvpict = imtweak(inpict,'lchuv',fliplr(cvec));
huslabpict = imtweak(inpict,'huslab',cvec);
husluvpict = imtweak(inpict,'husluv',cvec);

R1 = cat(2,hsvpict,hsipict,hslpict);
R2 = cat(2,ypppict,lchabpict,lchuvpict);
R3 = cat(2,hsypict,huslabpict,husluvpict);
comparison = cat(1,R1,R2,R3);

subplot(1,1,1);
set(gca,'position',[0.01 0.01 0.98 0.98]);

imshow(comparison)
%imwrite(comparison,'examples/imtweakex2.jpg','jpeg','Quality',90);
%% 
clear all; clc;
format compact;
inpict = imread('sources/blacklight2.jpg');

cvec = [0.5 1 1];
hsvpict = imtweak(inpict,'hsv',cvec);
hsipict = imtweak(inpict,'hsi',cvec);
hslpict = imtweak(inpict,'hsl',cvec);
ypppict = imtweak(inpict,'ych',fliplr(cvec));
hsypict = imtweak(inpict,'hsy',cvec);
lchabpict = imtweak(inpict,'lchab',fliplr(cvec));
lchuvpict = imtweak(inpict,'lchuv',fliplr(cvec));
huslabpict = imtweak(inpict,'huslab',cvec);
husluvpict = imtweak(inpict,'husluv',cvec);

R1 = cat(2,hsvpict,hsipict,hslpict);
R2 = cat(2,ypppict,lchabpict,lchuvpict);
R3 = cat(2,hsypict,huslabpict,husluvpict);
comparison = cat(1,R1,R2,R3);

subplot(1,1,1);
set(gca,'position',[0.01 0.01 0.98 0.98]);

imshow(comparison)
%imwrite(comparison,'examples/imtweakex3.jpg','jpeg','Quality',90);
%% HuSLp HSYp tweak demo
clear all; clc;
format compact;
inpict = imread('sources/blacklight2.jpg');

cvec = [0.5 1 1];
A = imtweak(inpict,'huslab',cvec);
B = imtweak(inpict,'husluv',cvec);
C = imtweak(inpict,'hsy',cvec);
Ap = imtweak(inpict,'huslpab',cvec);
Bp = imtweak(inpict,'huslpuv',cvec);
Cp = imtweak(inpict,'hsyp',cvec);

R1 = cat(2,A,Ap);
R2 = cat(2,B,Bp);
R3 = cat(2,C,Cp);
comparison = cat(1,R1,R2,R3);

subplot(1,1,1);
set(gca,'position',[0.01 0.01 0.98 0.98]);

imshow(comparison)
%imwrite(comparison,'examples/imtweakex5.jpg','jpeg','Quality',90);
%% 
inpict = imread('sources/goat.jpg');

outpict = imtweak(inpict,'rgb',[1.1 1 -0.5]);

imshow(outpict)
%imwrite(outpict,'examples/imtweakex4.jpg','jpeg','Quality',90);
%% 
clear all; clc;
format compact;
inpict = imread('sources/blacklight2.jpg');

cvec = [1 1 1/5];
ab1 = imtweak(inpict,'lchab',cvec);
sr1 = imtweak(inpict,'lchsr',cvec);
cvec = [1 1 2/5];
ab2 = imtweak(inpict,'lchab',cvec);
sr2 = imtweak(inpict,'lchsr',cvec);
cvec = [1 1 3/5];
ab3 = imtweak(inpict,'lchab',cvec);
sr3 = imtweak(inpict,'lchsr',cvec);
cvec = [1 1 4/5];
ab4 = imtweak(inpict,'lchab',cvec);
sr4 = imtweak(inpict,'lchsr',cvec);

bg = cat(2,cat(1,ab1,ab2),cat(1,ab3,ab4));
dots = cat(2,cat(1,sr1,sr2),cat(1,sr3,sr4));

s = size(bg);
V = eoline(ones(s(1:2)),2,[20 40]);
H = eoline(ones(s(1:2)),1,[20 40]);
mask = morphops(xor(H,V),simnorm(fkgen('rect',[8 8])),'dilate');
comparison = replacepixels(bg,dots,mask);

imshow(comparison)
%imwrite(comparison,'examples/imtweakex8.jpg','jpeg','Quality',90);

%% imtweak with full spec
A = imread('sources/table.jpg');

model = 'lchab';
B = imtweak(A,model,[0.5 1.5 0; 0.25 0 -0.2]);

imshow2(B,'invert')

%% imtweak with absolute and relative offset spec
A = imread('peppers.png');
A = imresize(A,0.5);

model = 'oklab';
Cr = imtweak(A,model,[1.1 0.5 1; -0.05 0.31 0.095]);
Ca = imtweak(A,model,[1.1 0.5 1; -5 10 3],'absolute');

% same relative offset gives similar output with a different model
% but using abs offsets requires rescaling
model = 'lab';
Dr = imtweak(A,model,[1.1 0.5 1; -0.05 0.31 0.095]);
Da = imtweak(A,model,[1.1 0.5 1; -5 42 13],'absolute');

imshow2([Cr Dr; Ca Da],'invert')

%% rgb2husl demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [250 250 3];
inpict = lingrad(s,[0 0; 0 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 0.8 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0.2 0],[0 0 0; 1 1 1]*255);
inpict = imblend(sgrad,inpict,1,'transfer v_hsv>s_hsv');
inpict = imblend(vgrad,inpict,1,'transfer v_hsv>v_hsv');

huslpict = rgb2husl(inpict,'luv');
Hhusl = huslpict(:,:,1)/360;
Shusl = huslpict(:,:,2)/100;
Ihusl = huslpict(:,:,3)/100;

hsvpict = rgb2hsv(inpict);
Hhsv = hsvpict(:,:,1);
Shsv = hsvpict(:,:,2);
Vhsv = hsvpict(:,:,3);

comparison = cat(2,cat(1,Hhusl,Shusl,Ihusl),cat(1,Hhsv,Shsv,Vhsv));
imshow(comparison)
%imwrite(inpict,'examples/rgb2huslex1.jpg','jpeg','Quality',90);
%imwrite(comparison,'examples/rgb2huslex2.jpg','jpeg','Quality',90);
%% husl2rgb demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% continue from above
rgbpict = husl2rgb(huslpict);
rgbpict = uint8(rgbpict*255);

imshow(rgbpict)
%% rgb2hsy demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [250 250 3];
inpict = lingrad(s,[0 0; 0 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 0.8 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0.2 0],[0 0 0; 1 1 1]*255);
inpict = imblend(sgrad,inpict,1,'transfer v_hsv>s_hsv');
inpict = imblend(vgrad,inpict,1,'transfer v_hsv>v_hsv');

hsypict = rgb2hsy(inpict);
Hhsy = hsypict(:,:,1)/360;
Shsy = hsypict(:,:,2);
Ihsy = hsypict(:,:,3);

hsvpict = rgb2hsv(inpict);
Hhsv = hsvpict(:,:,1);
Shsv = hsvpict(:,:,2);
Vhsv = hsvpict(:,:,3);

comparison = cat(2,cat(1,Hhsy,Shsy,Ihsy),cat(1,Hhsv,Shsv,Vhsv));
imshow(comparison)
%imwrite(comparison,'examples/rgb2hsyex1.jpg','jpeg','Quality',90);
%% hsy2rgb demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% continue from above
rgbpict = hsy2rgb(hsypict);
rgbpict = uint8(rgbpict*255);

imshow(rgbpict)
%% hsy gradient %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [250 250 3];
hgrad = im2double(lingrad(s(1:2),[0 0; 0 1],[0; 1]*255));
sgrad = im2double(lingrad(s(1:2),[0 0; 0.8 0],[0; 1]*255));
ygrad = im2double(lingrad(s(1:2),[1 0; 0.2 0],[0; 1]*255));

inpict = cat(3,hgrad*360,sgrad,ygrad);
inpict = hsy2rgb(inpict);

imshow(inpict)
%% addborder demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; clc;
inpict = imread('sources/probe.jpg');

outpict = addborder(inpict,25,[128 0 255]);

imshow(outpict)
%imwrite(outpict,'examples/cropborderex1.jpg','jpeg','Quality',90);

%%
clear all; clc;
inpict = imread('sources/probe.jpg');

%outpict = addborder(inpict,[10 25],[128 0 255 128]);
outpict = addborder(inpict,[10 25],[1 0.3 0.8 0.5],'normalized');

imshow2(outpict)
% imwrite(outpict(:,:,1:3),'examples/addborderex2.png','alpha',outpict(:,:,4));

%% displace demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inpict = imread('sources/blacklight2.jpg');
%inpict=mono(inpict,'y');
s = size(inpict);
x1 = lingrad(s,[0 0; 0 1],[0 0 0; 1 1 1]*255);
y1 = lingrad(s,[0 0; 1 0],[0 0 0; 1 1 1]*255);
midcolor = colorpict(s,[1 1 1]*128,'uint8');
blob = radgrad(s,[1 1]*0.5,0.4,[1 1 1; 1 1 1; 0 0 0]*255,'linear',[0 0.5 1]);
xmap = replacepixels(midcolor,x1,blob);
ymap = replacepixels(midcolor,y1,blob);

xmap = mono(xmap,'y');
ymap = mono(ymap,'y');

dpict = displace(inpict,[1 1]*100,'xmap',xmap,'ymap',ymap,'edgetype','wrap');
%dpict=displace(inpict,[1 1]*100,'xmap',xmap,'ymap',ymap,'edgetype',[0 1 0]);

imshow2(dpict,'invert')
%imwrite(xmap,'examples/displaceex1.jpg','jpeg','Quality',90);
%imwrite(ymap,'examples/displaceex2.jpg','jpeg','Quality',90);
%imwrite(dpict,'examples/displaceex3.jpg','jpeg','Quality',90);

%%
inpict = imread('sources/blacklight2.jpg');
s = size(inpict);
xmap = lingrad(s,[0 0; 0 1],[0 0 0; 1 1 1]*255,'waves',[0.7 10]);
ymap = lingrad(s,[0 0; 1 0],[0 0 0; 1 1 1]*255,'waves',[0.7 10]);

dpict = displace(inpict,[1 1]*100,'xmap',xmap,'ymap',ymap,'edgetype','replicate','interpolation','nearest');

imshow2(dpict,'invert')
%imwrite(xmap,'examples/displaceex4.jpg','jpeg','Quality',90);
%imwrite(ymap,'examples/displaceex5.jpg','jpeg','Quality',90);
%imwrite(dpict,'examples/displaceex6.jpg','jpeg','Quality',90);

%%
inpict = imread('sources/blacklight2.jpg');
s = size(inpict);

map = blockify(inpict,32);

dpict = displace(inpict,[32 0]*100,'xmap',map,'edgetype','wrap','mono');

imshow2(dpict,'invert')
%imwrite(dpict,'examples/displaceex1.jpg','jpeg','Quality',90);

%%
inpict = imread('sources/blacklight2.jpg');
s = size(inpict);

map = imzeros(s(1:2),'double');
for c = 1:5
	map = 1-((1-map).*(1-radgrad(s(1:2),rand([1 2]),0.1,[1; 0],'cosine','double')));
end

k = 50;
[dx dy] = gradient(map);

% pinch
dx = 1-(map.*dx*k+0.5);
dy = 1-(map.*dy*k+0.5);

dpict = displace(inpict,[1 1]*100,'xmap',dx,'ymap',dy,'edgetype','replicate','mono');

imshow2(dpict,'invert','tools')

%% tonemap demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%clear all; clc;
inpict = imread('sources/tree.jpg');

outpict = tonemap(inpict,'blursize',200,'bluropacity',0.9,'blendopacity',0.6);

imshow(cat(2,inpict,outpict))
%imwrite(outpict,'examples/tonemapex1.jpg','jpeg','Quality',90);
%% huslp tweak demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [400 650];
c0 = [255 128 128];
mode = 'huslab';
modep = 'huslpab';
steps = 48;

out = [];
for h = 0:1/steps:1;
    ch = colorpict(round(s./[2 steps]),imtweak(c0,mode,[h 1 1]),'uint8');
    chp = colorpict(round(s./[2 steps]),imtweak(c0,modep,[h 1 1]),'uint8');
    ch = cat(1,ch,chp);
    out = cat(2,out,ch);
end

imshow(out)
%imwrite(out,'examples/imtweakex5.jpg','jpeg','Quality',90);
%% 
s = [400 650];
c0 = [255 128 128];
mode = 'husluv';
modep = 'huslpuv';
steps = 48;

out = [];
for h = 0:1/steps:1;
    ch = colorpict(round(s./[2 steps]),imtweak(c0,mode,[h 1 1]),'uint8');
    chp = colorpict(round(s./[2 steps]),imtweak(c0,modep,[h 1 1]),'uint8');
    ch = cat(1,ch,chp);
    out = cat(2,out,ch);
end

imshow(out)
%imwrite(out,'examples/imtweakex6.jpg','jpeg','Quality',90);
%% 
s = [400 650];
c0 = [255 128 128];
mode = 'hsy';
modep = 'huslab';
steps = 48;

out = [];
for h = 0:1/steps:1;
    ch = colorpict(round(s./[2 steps]),imtweak(c0,mode,[h 1 1]),'uint8');
    chp = colorpict(round(s./[2 steps]),imtweak(c0,modep,[h 1 1]),'uint8');
    ch = cat(1,ch,chp);
    out = cat(2,out,ch);
end

imshow(out)
%% huslp volume demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cp = [0.10454,0.26934,0.50152,0.75165,1.0018,1.2519,1.502,1.7522,2.0023,2.2524,2.5026,2.7527, ...
    3.0028,3.253,3.5031,3.7532,4.0034,4.2535,4.5036,4.7538,5.0039,5.254,5.5042,5.7543,6.0044, ...
    6.2546,6.5047,6.7548,7.0049,7.2551,7.5052,7.7549,8.0033,8.2487,8.4903,8.7274,8.96,9.188, ...
    9.4116,9.6306,9.8445,10.053,10.253,10.444,10.624,10.793,10.952,11.101,11.239,11.366,11.483, ...
    11.59,11.688,11.779,11.867,11.955,12.042,12.129,12.217,12.304,12.391,12.478,12.566,12.653, ...
    12.74,12.828,12.915,13.002,13.09,13.177,13.264,13.351,13.439,13.526,13.613,13.701,13.788, ...
    13.875,13.963,14.05,14.137,14.224,14.312,14.399,14.486,14.574,14.661,14.748,14.836,14.923, ...
    15.01,15.097,15.185,15.272,15.359,15.447,15.534,15.621,15.708,15.796,15.883,15.97,16.058, ...
    16.145,16.232,16.32,16.407,16.494,16.581,16.669,16.756,16.843,16.931,17.018,17.105,17.193, ...
    17.28,17.367,17.454,17.542,17.629,17.716,17.804,17.891,17.978,18.066,18.153,18.24,18.327, ...
    18.415,18.502,18.589,18.677,18.764,18.851,18.938,19.026,19.113,19.2,19.288,19.375,19.462, ...
    19.55,19.637,19.724,19.811,19.899,19.986,20.073,20.161,20.248,20.335,20.423,20.51,20.597, ...
    20.684,20.772,20.859,20.946,21.034,21.121,21.208,21.296,21.383,21.47,21.557,21.645,21.732, ...
    21.819,21.907,21.994,22.081,22.168,22.256,22.343,22.43,22.518,22.605,22.692,22.78,22.867, ...
    22.954,23.041,23.129,23.216,23.303,23.391,23.478,23.565,23.653,23.74,23.827,23.914,24.002, ...
    24.089,24.176,24.264,24.351,24.438,24.526,24.613,24.7,24.787,24.875,24.962,25.049,25.137, ...
    25.224,25.311,25.398,25.486,25.573,25.66,25.748,25.835,25.922,26.01,26.097,26.184,26.271, ...
    26.359,26.446,26.533,26.621,26.708,26.795,26.883,26.97,27.057,27.144,27.232,27.319,27.406, ...
    27.494,27.581,27.668,27.755,27.843,27.93,28.017,28.105,28.192,28.279,28.367,28.454,28.541, ...
    28.628,28.716,28.803,28.89,28.978,29.065,29.152,29.24,29.327,29.414,29.501,29.589,29.676, ...
    29.763,29.851,29.938,30.025,30.113,30.2,30.287,30.374,30.462,30.549,30.636,30.724,30.811, ...
    30.898,30.985,31.073,31.16,31.247,31.335,31.422,31.509,31.597,31.684,31.771,31.858,31.946, ...
    32.033,32.12,32.208,32.295,32.382,32.47,32.557,32.644,32.731,32.819,32.906,32.993,33.081, ...
    33.168,33.255,33.343,33.43,33.517,33.604,33.692,33.779,33.866,33.954,34.041,34.128,34.215, ...
    34.303,34.39,34.477,34.565,34.652,34.739,34.827,34.914,35.001,35.088,35.176,35.263,35.35, ...
    35.438,35.525,35.612,35.7,35.787,35.874,35.961,36.049,36.136,36.223,36.311,36.398,36.485, ...
    36.573,36.66,36.747,36.834,36.922,37.009,37.096,37.184,37.271,37.358,37.445,37.533,37.62, ...
    37.707,37.795,37.882,37.969,38.057,38.144,38.231,38.318,38.406,38.493,38.58,38.668,38.755, ...
    38.842,38.93,39.017,39.104,39.191,39.279,39.366,39.453,39.541,39.628,39.715,39.803,39.89, ...
    39.977,40.064,40.152,40.031,39.722,39.413,39.105,38.796,38.488,38.18,37.872,37.564,37.256, ...
    36.948,36.641,36.333,36.004,35.646,35.289,34.933,34.579,34.226,33.873,33.522,33.172,32.824, ...
    32.476,32.129,31.784,31.439,31.096,30.753,30.412,30.071,29.732,29.394,29.057,28.721,28.386, ...
    28.052,27.719,27.387,27.056,26.726,26.397,26.069,25.742,25.416,25.092,24.768,24.445,24.123, ...
    23.802,23.483,23.164,22.846,22.529,22.213,21.898,21.584,21.271,20.959,20.647,20.337,20.028, ...
    19.72,19.413,19.106,18.801,18.496,18.193,17.89,17.588,17.287,16.987,16.688,16.39,16.092,15.796, ...
    15.501,15.206,14.912,14.619,14.328,14.036,13.746,13.457,13.168,12.881,12.594,12.308,12.023, ...
    11.739,11.455,11.173,10.891,10.61,10.33,10.051,9.7724,9.4947,9.2179,8.9418,8.6666,8.3922, ...
    8.1186,7.8458,7.5738,7.3026,7.0322,6.7626,6.4937,6.2257,5.9584,5.6918,5.426,5.1609,4.8967, ...
    4.6331,4.3703,4.1083,3.847,3.5865,3.3267,3.0676,2.8093,2.5517,2.2948,2.0386,1.7832,1.5284, ...
    1.2744,1.0211,0.76847,0.51656,0.28232,0.11342];

% create bicone surfaces
stp = 100;
l = 0:100/stp:100; h = 0:360/stp:360;
[L H] = meshgrid(l,h);

st = size(Cp)-1;
Lp = round(L/100*st(2))+1;
C = Cp(Lp);

X = C.*cos(H*pi/180);
Y = C.*sin(H*pi/180);

csview('huslab','invert',1,'alpha',0.5);
surf(X,Y,L,'facecolor',[1 1 1]*0.5)

%% 
% same thing in LUV
Cp = [0.0013529,0.15529,0.30922,0.46315,0.61709,0.77102,0.92496,1.0789,1.2328,1.3868,1.5407,1.6946, ...
    1.8486,2.0025,2.1564,2.3104,2.4643,2.6182,2.7722,2.9261,3.08,3.234,3.3879,3.5418,3.6958,3.8497, ...
    4.0036,4.1576,4.3115,4.4654,4.6194,4.7733,4.9272,5.0812,5.2351,5.389,5.543,5.6969,5.8508,6.0048, ...
    6.1587,6.3126,6.4666,6.6205,6.7744,6.9284,7.0823,7.2362,7.3902,7.5441,7.698,7.852,8.0059,8.1598, ...
    8.3138,8.4677,8.6216,8.7756,8.9295,9.0835,9.2374,9.3913,9.5453,9.6992,9.8531,10.007,10.161,10.315, ...
    10.469,10.623,10.777,10.931,11.085,11.239,11.392,11.546,11.7,11.854,12.008,12.162,12.316,12.47, ...
    12.624,12.778,12.932,13.086,13.24,13.394,13.548,13.701,13.855,14.009,14.163,14.317,14.471,14.625, ...
    14.779,14.933,15.087,15.241,15.395,15.549,15.703,15.857,16.01,16.164,16.318,16.472,16.626,16.78, ...
    16.934,17.088,17.242,17.396,17.55,17.704,17.858,18.012,18.166,18.319,18.473,18.627,18.781,18.935, ...
    19.089,19.243,19.397,19.551,19.705,19.859,20.013,20.167,20.321,20.475,20.628,20.782,20.936,21.09, ...
    21.244,21.398,21.552,21.706,21.86,22.014,22.168,22.322,22.476,22.63,22.784,22.937,23.091,23.245, ...
    23.399,23.553,23.707,23.861,24.015,24.169,24.323,24.477,24.631,24.785,24.939,25.093,25.247,25.4, ...
    25.554,25.708,25.862,26.016,26.17,26.324,26.478,26.632,26.786,26.94,27.094,27.248,27.402,27.556, ...
    27.709,27.863,28.017,28.171,28.325,28.479,28.633,28.787,28.941,29.095,29.249,29.403,29.557,29.711, ...
    29.865,30.018,30.172,30.326,30.48,30.634,30.788,30.942,31.096,31.25,31.404,31.558,31.712,31.866, ...
    32.02,32.174,32.327,32.481,32.635,32.789,32.943,33.097,33.251,33.405,33.559,33.713,33.867,34.021, ...
    34.175,34.329,34.483,34.636,34.79,34.944,35.098,35.252,35.406,35.56,35.714,35.868,36.022,36.176, ...
    36.33,36.484,36.638,36.792,36.945,37.099,37.253,37.407,37.561,37.715,37.869,38.023,38.177,38.331, ...
    38.485,38.639,38.793,38.947,39.101,39.254,39.408,39.562,39.716,39.87,40.024,40.178,40.332,40.486, ...
    40.64,40.794,40.948,41.102,41.256,41.41,41.563,41.717,41.871,42.025,42.179,42.333,42.487,42.641, ...
    42.795,42.949,43.103,43.257,43.411,43.565,43.719,43.873,44.026,44.18,44.334,44.488,44.642,44.796, ...
    44.95,45.104,45.258,45.412,45.566,45.72,45.874,46.028,46.182,46.335,46.489,46.643,46.797,46.951, ...
    47.105,47.259,47.413,47.567,47.721,47.875,48.029,48.183,48.337,48.491,48.644,48.798,48.952,49.106, ...
    49.26,49.414,49.568,49.722,49.876,50.03,50.184,50.338,50.492,50.646,50.8,50.953,51.107,51.261, ...
    51.415,51.569,51.723,51.877,52.031,52.185,52.339,52.493,52.647,52.801,52.955,53.109,53.262,53.416, ...
    53.57,53.724,53.878,54.032,54.186,54.34,54.494,54.648,54.802,54.956,55.11,55.264,55.418,55.571, ...
    55.725,55.879,56.033,56.187,56.341,56.495,56.649,56.803,56.957,57.111,57.265,57.419,57.573,57.727, ...
    57.88,58.034,58.188,58.342,58.496,58.65,58.804,58.958,59.112,59.266,59.42,59.574,59.728,59.882, ...
    59.583,58.99,58.4,57.811,57.224,56.639,56.055,55.474,54.895,54.318,53.744,53.171,52.6,52.03,51.463, ...
    50.897,50.334,49.773,49.213,48.656,48.1,47.546,46.994,46.444,45.896,45.349,44.805,44.263,43.722, ...
    43.183,42.646,42.111,41.577,41.045,40.516,39.988,39.462,38.937,38.415,37.894,37.375,36.857,36.341, ...
    35.827,35.315,34.805,34.296,33.789,33.284,32.78,32.278,31.778,31.279,30.782,30.286,29.792,29.3, ...
    28.81,28.321,27.834,27.348,26.864,26.381,25.9,25.421,24.943,24.466,23.992,23.518,23.047,22.576, ...
    22.108,21.641,21.175,20.711,20.248,19.787,19.327,18.868,18.411,17.956,17.502,17.049,16.598,16.148, ...
    15.7,15.252,14.807,14.363,13.92,13.478,13.038,12.599,12.161,11.725,11.29,10.857,10.424,9.9933,9.5637, ...
    9.1353,8.7083,8.2824,7.8579,7.4346,7.0125,6.5917,6.1721,5.7538,5.3366,4.9207,4.506,4.0926,3.6803, ...
    3.2692,2.8593,2.4505,2.043,1.6366,1.2313,0.82725,0.4243,0.022491];

% create bicone surfaces
stp = 100;
l = 0:100/stp:100; h = 0:360/stp:360;
[L H] = meshgrid(l,h);

st = size(Cp)-1;
Lp = round(L/100*st(2))+1;
C = Cp(Lp);

X = C.*cos(H*pi/180);
Y = C.*sin(H*pi/180);

csview('husluv','invert',1,'alpha',0.5);
surf(X,Y,L,'facecolor',[1 1 1]*0.5)

%% huslp stripe demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
steps = [40 20];

h = 0:360/steps(1):(360-360/steps(1));
y = 0:1/steps(2):(1-1/steps(2));
[H Y] = meshgrid(h,fliplr(y));
S = ones(size(Y));

hslrgb = hsl2rgb(cat(3,H,S,L));

h = 0:360/steps(1):(360-360/steps(1));
y = 0:100/steps(2):(100-100/steps(2));
[H Y] = meshgrid(h,fliplr(y));
S = ones(size(Y))*100;

rgb = husl2rgb(cat(3,H,S,Y),'lab');
rgbp = husl2rgb(cat(3,H,S,Y),'labp');
out = imresizeFB(cat(1,hslrgb,rgb,rgbp),[750 500],'nearest');

imshow(out);
%imwrite(out,'examples/rgb2huslex5.jpg','jpeg','Quality',90);

%% 
steps = [40 20];

h = 0:360/steps(1):(360-360/steps(1));
y = 0:1/steps(2):(1-1/steps(2));
[H Y] = meshgrid(h,fliplr(y));
S = ones(size(Y));

hslrgb = hsl2rgb(cat(3,H,S,Y));

h = 0:360/steps(1):(360-360/steps(1));
y = 0:100/steps(2):(100-100/steps(2));
[H Y] = meshgrid(h,fliplr(y));
S = ones(size(Y))*100;

rgb = husl2rgb(cat(3,H,S,Y),'luv');
rgbp = husl2rgb(cat(3,H,S,Y),'luvp');
out = imresizeFB(cat(1,hslrgb,rgb,rgbp),[750 500],'nearest');

imshow(out);
%imwrite(out,'examples/rgb2huslex6.jpg','jpeg','Quality',90);

%% hsyp stripe demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
steps = [40 20];

h = 0:360/steps(1):(360-360/steps(1));
y = 0:1/steps(2):(1-1/steps(2));
[H Y] = meshgrid(h,fliplr(y));
S = ones(size(Y));

hslrgb = hsl2rgb(cat(3,H,S,Y));
rgb = hsy2rgb(cat(3,H,S,Y),'normal');
rgbp = hsy2rgb(cat(3,H,S,Y),'pastel');
out = imresizeFB(cat(1,hslrgb,rgb,rgbp),[750 500],'nearest');

imshow(out);
%imwrite(out,'examples/rgb2hsyex2.jpg','jpeg','Quality',90);
%% hsyp volume demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lbreak = 0.50195313;
Cbreak = 0.28211668;
L = 0:0.01:1;
Cp = zeros(size(L));

mk = L < Lbreak;
Cp(mk) = Cbreak/Lbreak*L(mk);
Cp(~mk) = Cbreak-Cbreak/(1-Lbreak)*(L(~mk)-Lbreak);

stp = 100;
l = 0:1/stp:1; h = 0:360/stp:360;
[L H] = meshgrid(l,h);

st = size(Cp)-1;
Lp = round(L*st(2))+1;
C = Cp(Lp);

X = C.*cos(H*pi/180);
Y = C.*sin(H*pi/180);

csview('ypbpr','invert',1,'alpha',0.5);
surf(X,Y,L,'facecolor',[1 1 1])

%% LCH chroma compression due to repeat hue adjustment
bg = imread('sources/blacklight2.jpg');

st = 6;
lchset = bg;
huslset = bg;
yppset = bg;
hsyset = bg;
for k = 1:st
    lchrot = imtweak(lchset(:,:,:,k),'lchab',[1 1 1/st]);
    huslrot = imtweak(huslset(:,:,:,k),'huslab',[1/st, 1, 1]);
    ypprot = imtweak(yppset(:,:,:,k),'ych',[1 1 1/st]);
    hsyrot = imtweak(hsyset(:,:,:,k),'hsy',[1/st, 1, 1]);
    
    lchset = cat(4,lchset,lchrot);
    huslset = cat(4,huslset,huslrot);
    yppset = cat(4,yppset,ypprot);
    hsyset = cat(4,hsyset,hsyrot);
end

A = lchset(:,:,:,1);
B = huslset(:,:,:,1);
C = yppset(:,:,:,1);
D = hsyset(:,:,:,1);
s = size(bg);
for k = 2:st
    h = round(s(1)/(st-1));
    mvec = min(((k-2)*h+1):((k-2)*h+h),s(1));
    A = cat(1,A,lchset(mvec,:,:,k));
    B = cat(1,B,huslset(mvec,:,:,k));
    C = cat(1,C,yppset(mvec,:,:,k));
    D = cat(1,D,hsyset(mvec,:,:,k));
end
A = cat(1,A,lchset(:,:,:,end));
B = cat(1,B,huslset(:,:,:,end));
C = cat(1,C,yppset(:,:,:,end));
D = cat(1,D,hsyset(:,:,:,end));
out1 = cat(2,A,B);
out2 = cat(2,C,D);

imshow(out1)
%imwrite(out1,'examples/imtweakex6.jpg','jpeg','Quality',90);
%imwrite(out2,'examples/imtweakex7.jpg','jpeg','Quality',90);

%% maxchroma example %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
st = 2000;
h = [0 360];
l = 50;
mode = 'lab';

hh = h(1):(h(2)-h(1))/st:h(2);
ll = ones(size(hh))*l;
cc = maxchroma([mode 'calc'],'l',ll,'h',hh);

subplot(1,1,1);
set(gca,'position',[0.05 0.05 0.90 0.90]);

plot(hh,cc,'color',1-[0.5375 0.5554 0.9936],'linewidth',2);
set(gca,'xlim',h)
xlabel('hue')
ylabel('boundary chroma')

out = getframe(gcf);
out = out.cdata;
%imwrite(out,'examples/maxchromaex2.png','png');

%% 
clf
yellow = permute(rgb2lch(permute([1 1 0],[1 3 2]),'lab'),[1 3 2]);

st = 2000;
h = [100 106];
l = yellow(1);
mode = 'lab';

hh = h(1):(h(2)-h(1))/st:h(2);
ll = ones(size(hh))*l;
c = maxchroma(mode,'l',ll,'h',hh);
cc = maxchroma([mode 'calc'],'l',ll,'h',hh);

subplot(1,1,1);
set(gca,'position',[0.05 0.05 0.90 0.90]);

plot(hh,c,'color',1-[0.3615 0.7730 0.3347],'linewidth',2); hold on;
plot(hh,cc,'color',1-[0.5375 0.5554 0.9936],'linewidth',2);
plot(yellow(3),yellow(2),'marker','+','linewidth',2); 
A = getframe(gcf);

out = A.cdata;
%imwrite(out,'examples/maxchromaex3.png','png');

C = maxchroma('labcalc','l',yellow(1),'h',yellow(3))
err_at_apex = yellow(2)-C

%% same thing for SRLAB
yellow = permute(rgb2lch(permute([0 0 1],[1 3 2]),'srlab'),[1 3 2]);
C = maxchroma('srlabcalc','l',yellow(1),'h',yellow(3))
err_at_apex = yellow(2)-C

%% actual LAB gamut boundary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
st = [0.7 1]*2000;
c = [0 105];
h = [100 106];
l = 97.14;
hh = h(1):(h(2)-h(1))/st(2):h(2);
cc = c(1):(c(2)-c(1))/st(1):c(2);
[H C] = meshgrid(hh,cc);
L = ones(size(H))*l;

lch = cat(3,L,C,H);
rgb = lch2rgb(lch,'lab','nogc');
ingamut = ~(any(rgb < 0,3) | any(rgb > 1,3));
gamut = bsxfun(@times,rgb,ingamut);
gamut = flipd(gamut,1);

imshow(gamut)
%imwrite(gamut,'examples/maxchromaex4.png','png');

%% actual SRLAB gamut boundary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
st = [0.7 1]*2000;
c = [0 105];

% blue corner
h = [263 267]
l = 40.04;

hh = h(1):(h(2)-h(1))/st(2):h(2);
cc = c(1):(c(2)-c(1))/st(1):c(2);
[H C] = meshgrid(hh,cc);
L = ones(size(H))*l;

lch = cat(3,L,C,H);
rgb = lch2rgb(lch,'srlab','nogc');
ingamut = ~(any(rgb < 0,3) | any(rgb > 1,3));
gamutb = bsxfun(@times,rgb,ingamut);

% yellow corner
h = [109 113]
l = 97.63;

hh = h(1):(h(2)-h(1))/st(2):h(2);
cc = c(1):(c(2)-c(1))/st(1):c(2);
[H C] = meshgrid(hh,cc);
L = ones(size(H))*l;

lch = cat(3,L,C,H);
rgb = lch2rgb(lch,'srlab','nogc');
ingamut = ~(any(rgb < 0,3) | any(rgb > 1,3));
gamuty = bsxfun(@times,rgb,ingamut);

gamut = cat(1,flipd(gamutb,1),flipd(gamuty,1));

imshow(gamut)
%imwrite(gamut,'examples/maxchromaex5.png','png');

%% dithering methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

s = [200 500];
m = repmat(1:s(2),[s(1),1])/s(2);
md1 = orddither(m);
md2 = dither(m);
md3 = zfdither(m);

g = cat(1,m,md1,md2,md3);
%imwrite(g,'examples/ditherex.png','png');
imshow2(g,'invert','tools')

%% lcdemu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/relaysmall.jpg');
mpict = lcdemu(inpict);

imshow2(mpict,'invert','tools')
%imwrite(mpict,'examples/lcdemuex1.png','png');

%%

inpict = imread('sources/relaysmall.jpg');
mpict = lcdemu(inpict,5);

imshow2(mpict,'invert')
%imwrite(mpict,'examples/lcdemuex2.png','png');

%% bicoloradapt %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/domeditor.png');
missing = 2;

naivepict = inpict;
naivepict(:,:,missing) = 0;

adaptedpict = bicoloradapt(inpict,missing);

imcompare('naivepict','adaptedpict','invert')

%imwrite(naivepict,'examples/bicoloradaptex1.png','png');
%imwrite(adaptedpict,'examples/bicoloradaptex2.png','png');

%% linedither %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/blacklight2.jpg');

% Use defaults:
op1 = linedither(inpict);

% Create solid line dither
op2 = linedither(inpict,'levels',16,'len',0,'ramp','none', ...
        'axis','h','radius',3,'noiseamt',0,'pattern','regular');
 
% Create odd mix of dot and solid line dithering: 
op3 = linedither(inpict,'levels',16,'len',1,'ramp','up', ...
        'axis','h','radius',3,'noiseamt',0,'pattern','regular');
 
% Same as above, but using default PATTERN: 
op4 = linedither(inpict,'levels',16,'len',1,'ramp','up', ...
        'axis','h','radius',3,'noiseamt',0,'pattern','irregular');

outpict = cat(1,op1,op2,op3,op4);
imshow2(outpict,'invert')

%imwrite(outpict,'examples/lineditherex1.png','png');

%% arborddither %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/blacklight2.jpg');

% Use defaults:
op1 = arborddither(inpict);

% 256-level monochrome dither using the flipped diagonal preset
op2 = arborddither(inpict,2,'mono','dzzi-flr');

% 64-level mono dither using an inverted vertical stripe preset
op3 = arborddither(inpict,2,'mono','h-tp-');

outpict = cat(1,op1,op2,op3);
imshow2(outpict,'invert')

%imwrite(outpict,'examples/arbordditherex1.png','png');

%% xwline %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

s = [200 350];
np = 10;

potato = xwline(s,rand([1 np])*(s(2)-1)+1,rand([1 np])*(s(1)-1)+1); 

imshow2(potato,'invert');
%imwrite(potato,'examples/xwlineex1.png','png');

%% imdrag %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/blacklight2.jpg');

% use defaults
op1 = imdrag(inpict);

% use a 'near' mode blend
op2 = imdrag(inpict,'direction','south', ...
        'nframes',4, 'ndrags',100, ...
        'width',[10 50], 'distance',[50 200], ...
        'bmode','near','opacity',0.9,'amount',0.1);
	
% use a 'lighten' blend
op3 = imdrag(inpict,'direction','south', ...
        'nframes',4, 'ndrags',100, ...
        'width',[10 50], 'distance',[50 200], ...
        'bmode','lighteny','opacity',0.9,'amount',1);

outpict = cat(1,op1,op2,op3);
imshow2(outpict,'invert');
%imwrite(outpict(:,:,1:3),'examples/imdragex1.png','png');

%% zblend %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = gifread('sources/facestack1.gif');

s = size(inpict);
mask = lingrad(s(1:3),[0 0; 1 1],[0,0,0; 1,1,1]*255,'linear');

wp = zblend(inpict,mask);

imshow2(wp,'invert');
%imwrite(mask,'examples/zblendex1.png')
%imwrite(wp,'examples/zblendex2.png')

%%
inpict = gifread('sources/facestack1.gif');

nf = 30;
s = size(inpict);
mask = zeros([s(1:3) nf],'uint8');
for f = 1:nf
	mask(:,:,:,f) = radgrad(s(1:3),[1 1]*(f-1)/(nf-1),1,[0,0,0; 1,1,1]*255,'cosine');
end

wp = zblend(inpict,mask);

gifwrite(mask,'examples/zblendex3.gif')
gifwrite(wp,'examples/zblendex4.gif');


%% erraccumulate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = im2double(imread('sources/relaysmall.jpg'));

outpict = erraccumulate(inpict,'scale','bilinear','cycles',40,'step',1);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/erraccumulateex1.png')

%% noisedither %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/probe.jpg');

op1 = noisedither(inpict,'white');
op2 = noisedither(inpict,'blue');

outpict = cat(1,op1,op2);
imshow2(outpict,'invert')

%imwrite(outpict,'examples/noiseditherex1.png');

%% imfold %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/relaysmall.jpg');

outpict = imfold(inpict,{'2hu','1vo'});

imshow2(outpict(:,:,:,1),'invert')

gifwrite(outpict,'examples/imfoldex1.gif',1);

%% imcartpol %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpict = imread('sources/relaysmall.jpg');

gpict = imcartpol(inpict,'offset',[0 0],'center','mode','rinvert');

imshow2(gpict,'invert')
%imwrite(gpict,'examples/imcartpolex1.png')

%%
inpict = imread('sources/relaysmall.jpg');

gpict = imcartpol(inpict,'offset',[0; 1],'gamma',[1 1.5],'amount',[1; i],'cycles',3,'mode','rando');

imshow2(gpict,'invert')
%imwrite(gpict,'examples/imcartpolex2.png')

%% mimread/imstacker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pathexp = 'sources';
pathsuffix = {'ban*','*bars*','table*'};
vb = 'verbose';

args = {'gravity','nw',...
	'size','max',...
	'fit','rigid',...
	'interpolation','bicubic',...
	'outclass','uint8',...
	'padding',[0.2 0 0.5 0.8],vb};

inpict = imstacker(mimread(pathexp,pathsuffix,vb),args{:});

imshow2('inpict','invert','tools')

catpict = imresizeFB(cat(1,inpict(:,:,:,1),inpict(:,:,:,2),inpict(:,:,:,3),inpict(:,:,:,4)),[1200 NaN]);
%imwrite(catpict(:,:,1:3),'examples/mimread-imstackerex1.png','alpha',catpict(:,:,4))

%% 

pathexp = 'sources';
pathsuffix = {'ban*','*bars*','table*'};
vb = 'verbose';

args = {'gravity','c',...
	'size','max',...
	'fit','inscribe',...
	'interpolation','bicubic',...
	'outclass','uint8',...
	'padding',[0.2 0 0.5 0.8],vb};

inpict = imstacker(mimread(pathexp,pathsuffix,vb),args{:});

imshow2('inpict','invert','tools')

catpict = imresizeFB(cat(1,inpict(:,:,:,1),inpict(:,:,:,2),inpict(:,:,:,3),inpict(:,:,:,4)),[1200 NaN]);
%imwrite(catpict(:,:,1:3),'examples/mimread-imstackerex2.png','alpha',catpict(:,:,4))

%% memsize

inpict = imread('sources/relaysmall.jpg');

memsize(inpict)
memsize(imcast(inpict,'double'))

%% imrectrotate

inpict = imread('sources/blacklight2.jpg');

dpict1 = imrectrotate(inpict,90);
dpict2 = imrectrotate(inpict,90,'proportional');

imshow2(cat(1,dpict1,dpict2),'invert','tools')

%imwrite(cat(1,dpict1,dpict2),'examples/imrectrotateex1.jpg')

%%

dpict1 = imrectrotate(inpict,30,'center',[0.5 0.1]);
dpict2 = imrectrotate(inpict,ones([1 20])*5,'center',rand([20 2]));

imshow2(cat(1,dpict1,dpict2),'invert','tools')

%imwrite(cat(1,dpict1,dpict2),'examples/imrectrotateex2.jpg')

%% imannrotate

inpict = imread('sources/blacklight2.jpg');

dpict1 = imannrotate(inpict,45);
dpict2 = imannrotate(inpict,45,'keepcenter');
dpict3 = imannrotate(inpict,45,'keepcenter','gamma',3);

imshow2(cat(1,dpict1,dpict2,dpict3),'invert','tools')

%imwrite(cat(1,dpict1,dpict2,dpict3),'examples/imannrotateex1.jpg')

%% extractbg

bgest = extractbg('sources/catbat.gif','iterations',13,'tightening',0.90);

imshow2(bgest,'invert','tools')

%imwrite(bgest,'examples/extractbgex1.jpg')

%% imrecolor

ref1 = imread('sources/goat.jpg');
ref2 = imread('sources/blacklight2.jpg');
inpict = imread('examples/imdestroyerex2.jpg');

out1 = imrecolor(ref1,inpict,'colormodel','hsly');
out2 = imrecolor(ref2,inpict,'colormodel','hsly');
outpict = cat(1,out1,out2);
imshow2(outpict,'invert','tools')

%imwrite(outpict,'examples/imrecolorex1.jpg')

%% pseudoblurmap demo
inpict = imread('sources/goat.jpg');
map = radgrad(size(inpict),[0.5 0.4],0.5,[0 0 0; 1 1 1]*255,'linear');

op1 = pseudoblurmap(map,inpict,'kstyle','gaussian','blursize',50,'numblurs',10);
op2 = pseudoblurmap(map,inpict,'kstyle','gaussian','blursize',50,'numblurs',10,'rampgamma',2);
outpict = cat(1,op1,op2);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/pseudoblurmapex1.jpg')

%% imtile demo
inpict = gifread('sources/facestack1.gif');

outpict = imtile(inpict,[4 7]);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/imtileex1.jpg','quality',97)

%% imdetile demo
inpict = imread('examples/imtileex1.jpg');

outpict = imdetile(inpict,[4 7],'prune','tol',500E-6);

imshow2(outpict,'invert','tools')
%gifwrite(outpict,'examples/imdetileex1.gif')

%% color2alpha demo
inpict = imread('sources/blacklight2.jpg');

outpict = color2alpha(inpict,[1 1 1]);

imshow2(outpict,'invert','tools')
%imwrite(outpict(:,:,1:3),'examples/color2alphaex1.png','alpha',outpict(:,:,4))

%% lcmap demo
inpict = imread('sources/table.jpg');

outpict = lcmap(inpict);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/lcmapex1.jpg')

%% edgemap demo
inpict = imread('sources/table.jpg');

outpict = edgemap(inpict);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/edgemapex1.jpg')

%% fkgen demo
fstack(1) = {fkgen('gaussian',[150 200],'angle',25)};
fstack(2) = {fkgen('glow2',[150 200],'angle',25)};
fstack(3) = {fkgen('disk',[150 200],'angle',25)};
fstack(4) = {fkgen('ring',[150 200],'angle',25)};
fstack(5) = {fkgen('bars',[200 200],'angle',15)};
fstack(6) = {fkgen('cross',[200 200])};
fstack(7) = {fkgen('3dot',[200 200])};
fstack(8) = {fkgen('4dot',[200 200])};

outpict = imtile(imstacker(fstack,'padding',0),[NaN 2]);
% rescale the image to make it visible
outpict = imlnc(outpict,'independent','tol',1E-6);

imshow2(outpict,'invert','tools')
% imwrite(outpict,'examples/fkgenex1.jpg')

%%
sz = [40 200];

% both kernels use the same sigma
% size offset of 1 used to make kernels have the same size
indata = fspecial('gaussian',sz+1,0.3*max(sz)/2); % THIS COMPARISON REQUIRES IPT
bb = fkgen('gaussian',sz);

outpict = cat(2,indata,bb);
% rescale the image to make it visible
outpict = imlnc(outpict,'independent','tol',1E-6);

imshow2(outpict,'invert','tools')
% imwrite(outpict,'examples/fkgenex2.jpg')

%%
inpict = imread('sources/table.jpg');

faa = imfilterFB(inpict,indata);
fbb = imfilterFB(inpict,bb);
outpict = cat(1,faa,fbb);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/fkgenex3.jpg')

%% maketileable demo
inpict = imread('sources/blacklight2.jpg');

tiling = [21 21];
rspict = maketileable(inpict,tiling);

size(inpict)./[tiling 1]
size(rspict)./[tiling 1]

%% continuize demo
inpict = imread('sources/blacklight2.jpg');

s = size(inpict);
mask = randspots(s(1:2),4,[100 300],[1 1],'circle');

dpict = roishift(inpict,mask,2,100,'whole');
cpict1 = continuize(@roishift,inpict,mask,2,100,'whole');
cpict2 = continuize('filter',fkgen('gaussian',100),@roishift,inpict,mask,2,100,'whole');
outpict = cat(1,dpict,cpict1,cpict2);

imshow2(outpict,'invert','tools')
% imwrite(outpict,'examples/continuizeex1.jpg')

%%
inpict = imread('sources/blacklight2.jpg');

dpict = imannrotate(inpict,45);
cpict1 = continuize(@imannrotate,inpict,45);
cpict2 = continuize('filter',fkgen('gaussian',100),@imannrotate,inpict,45);
outpict = cat(1,dpict,cpict1,cpict2);

imshow2(outpict,'invert','tools')
% imwrite(outpict,'examples/continuizeex2.jpg')

%% imrescale demo
colorextrema = uint8([0 1])

newextrema = imrescale(colorextrema,'double','int16')
class(newextrema)

%% colorpicker demo
inpict = imread('sources/blacklight2.jpg');

colortable = colorpicker(inpict,'invert')

%% matchchannels demo
inpict = imread('sources/blacklight2.jpg');
incolor = [0.5 1];

[outpict outcolor] = matchchannels(inpict,incolor);

chancount(inpict)
chancount(outpict)
outcolor

%% simnorm demo
indata = randn([100 100]);
instats = imstats(indata,'min','mean','max')'

aan = simnorm(indata);
aanstats = imstats(aan,'min','mean','max')'

bbn = simnorm(indata,'mean');
bbnstats = imstats(bbn,'min','mean','max')'

%% mlmask demo
inpict = imread('sources/blacklight2.jpg');
mask = mlmask(inpict,6);
maskimg = imtile(mask,[3 2]);
imshow2(maskimg,'invert','tools')

%imwrite(maskimg,'examples/mlmaskex1.jpg')

%% imcontmip demo
inpict = imread('sources/blacklight2.jpg');
op1 = imcontmip(inpict,mlmask(mono(inpict,'y'),2),'angle',[110 -120], ...
                'filter','none','params',[1 0.8 0]);
op2 = imcontmip(inpict,mlmask(mono(inpict,'y'),2),'angle',[110 -120], ...
                'filter',fkgen('glow2',40),'params',[1 0.8 0]);	
outpict = cat(1,op1,op2);
			
imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/imcontmipex1.jpg')

%% imcontfdx demo
inpict = imread('sources/blacklight2.jpg');
op1 = imcontfdx(inpict,mlmask(mono(inpict,'y'),4),'angle',[60 30 -30 -60], ...
                'filter','none');
op2 = fdblend(op1);	
outpict1 = imtile(op1,[4 1]);
outpict2 = imtile(op2,[4 1]);		

imshow2(outpict1,'invert','tools')
%imwrite(outpict1,'examples/imcontfdxex1.jpg')
%imwrite(outpict2,'examples/imcontfdxex2.jpg')
%% 
inpict = imread('sources/blacklight2.jpg');
op1 = imcontfdx(inpict,mlmask(mono(inpict,'y'),4),'angle',[60 30 -30 -60], ...
                'filter',fkgen('gaussian',40));
op2 = fdblend(op1);	
outpict1 = imtile(op1,[4 1]);
outpict2 = imtile(op2,[4 1]);		

imshow2(outpict1,'invert','tools')
%imwrite(outpict1,'examples/imcontfdxex3.jpg')
%imwrite(outpict2,'examples/imcontfdxex4.jpg')

%% fdblend demo
% see imcontfdx demo

%% dotmask demo
bg = imread('sources/table.jpg');
fg = imlnc(imfilterFB(bg,fkgen('glow2',50)),'average','k',1.5);

op = imblend(fg,bg,1,'flatglow');
outpict = dotmask(op,bg,0.9);

imshow2(outpict,'invert','tools')
%imwrite(op,'examples/dotmaskex1.jpg')
%imwrite(outpict,'examples/dotmaskex2.jpg')

%% imsize demo
inpict = imread('sources/blacklight2.jpg');

fullsize = imsize(inpict)
pagesize = imsize(inpict,2)

%% textim demo
intext = {'The conscious and intelligent manipulation of the organized';
       'habits and opinions of the masses is an important element in';
	   'democratic society.  Those who manipulate this unseen mechanism';
	   'of society constitute an invisible government which is the true';
	   'ruling power of our country.  -- Bernays, 1928'};

nl = numel(intext);
op = cell([1 nl]);
for n = 1:nl
	op{n} = textim(intext{n},'hp-100x-8x6');
end
op = imstacker(op,'gravity','w','padding',0,'dim',1);

imshow2(op,'invert','tools')

%imwrite(op,'examples/textimex1.jpg');

%%

padcolor = 0.2;
rsfactor = 2;
borderw = 5;
maxw = 288;

cmlist = {{'tti-native','tti-double'}; ...
	{'ibm-vga-8x8','ibm-vga-14x8','ibm-vga-16x8'}; ...
	{'ibm-vga-8x9','ibm-vga-14x9','ibm-vga-16x9'}; ...
	{'ibm-iso-16x8','ibm-iso-16x9'}; ...
	{'compaq-8x8','compaq-14x8','compaq-16x8'}; ...
	{'hp-100x-8x6','hp-100x-8x8','hp-100x-11x10','hp-100x-12x16'}; ...
	{'ti-pro','everex-me','cordata-ppc21','wyse-700a','wyse-700b'}; ...
	{'tinynum','micronum','bithex','bithex-gapless'}};

nl = numel(cmlist);
allexamples = cell(1:nl);
for l = 1:nl
	nc = numel(cmlist{l});
	acm1 = [];
	for c = 1:nc
		tacm = imtile(imdetile(textim(char(0:255),cmlist{l}{c}),[1 16]),[16 1]);
		bs = [[0.2 1.8]*borderw [1 1]*((maxw-size(tacm,2))/2+borderw)];
		labelbar = textim(cmlist{l}{c},'ibm-iso-16x9');
		labelbar = cat(2,labelbar,zeros([size(labelbar,1) maxw+2*borderw-size(labelbar,2)]));
		acm1 = cat(1,acm1,labelbar,addborder(tacm,bs,padcolor,'normalized'));
	end
	allexamples(l) = {imresizeFB(acm1,rsfactor,'nearest')};
	
	imwrite(allexamples{l},sprintf('examples/textimex%d.png',l+1));
end

%% drysize demo
inpict = imread('sources/blacklight2.jpg');

origsize = imsize(inpict,2)

outscale = 0.333;
estsize = drysize(origsize,outscale)
actsize = imsize(imresizeFB(inpict,outscale),2)

outscale = [700 NaN];
estsize = drysize(origsize,outscale)
actsize = imsize(imresizeFB(inpict,outscale),2)

%% textblock demo

% at 400px, these cases correctly hyphenate
% (production
% "anarchistic."
% balancing
% together.
% medium does not hyphenate as medi-um due to orphan rules
% go/ods), splits at artificial delimiter

intext = 'The phenomenon of money presupposes an economic order in which production is based on division of labor and in which private property consists not only in goods of the first order (consumption go/ods), but also in goods of higher orders (production goods). In such a society, there is no systematic centralized control of production, for this is inconceivable without centralized disposal over the means of production. Production is "anarchistic." What is to be produced, and how it is to be produced, is decided in the first place by the owners of the means of production, who produce, however, not only for their own needs, but also for the needs of others, and in their valuations take into account, not only the use-value that they themselves attach to their products, but also the use-value that these possess in the estimation of the other members of the community. The balancing of production and consumption takes place in the market, where the different producers meet to exchange goods and services by bargaining together. The function of money is to facilitate the business of the market by acting as a common medium of exchange.';
tsize = [NaN 400];

outpict = textblock(intext,tsize,'font','compaq-8x8');

imshow2(outpict,'invert','tools')

%imwrite(outpict,'examples/textblockex1.jpg');

%%
intext = 'The phenomenon of money presupposes an economic order in which production is based on division of labor and in which private property consists not only in goods of the first order (consumption go/ods), but also in goods of higher orders (production goods). In such a society, there is no systematic centralized control of production, for this is inconceivable without centralized disposal over the means of production. Production is "anarchistic." What is to be produced, and how it is to be produced, is decided in the first place by the owners of the means of production, who produce, however, not only for their own needs, but also for the needs of others, and in their valuations take into account, not only the use-value that they themselves attach to their products, but also the use-value that these possess in the estimation of the other members of the community. The balancing of production and consumption takes place in the market, where the different producers meet to exchange goods and services by bargaining together. The function of money is to facilitate the business of the market by acting as a common medium of exchange.';
tsize = [400 400];
outpict = textblock(intext,tsize,'font','compaq-8x8','halign','center','enablehyph',false,'linespacing',2);

imshow2(outpict,'invert','tools')

%imwrite(outpict,'examples/textblockex2.jpg');

%%
intext = 'The phenomenon of money presupposes an economic order in which production is based on division of labor and in which private property consists not only in goods of the first order (consumption go/ods), but also in goods of higher orders (production goods). In such a society, there is no systematic centralized control of production, for this is inconceivable without centralized disposal over the means of production. Production is "anarchistic." What is to be produced, and how it is to be produced, is decided in the first place by the owners of the means of production, who produce, however, not only for their own needs, but also for the needs of others, and in their valuations take into account, not only the use-value that they themselves attach to their products, but also the use-value that these possess in the estimation of the other members of the community. The balancing of production and consumption takes place in the market, where the different producers meet to exchange goods and services by bargaining together. The function of money is to facilitate the business of the market by acting as a common medium of exchange.';
tsize = [NaN 400];
outpict = textblock(intext,tsize,'font','compaq-8x8','hardbreak',true,'tightwidth',true);

imshow2(outpict,'invert','tools')

%imwrite(outpict,'examples/textblockex3.jpg');

%%
% observe packing efficiency is a quasi-periodic function of block width
% hyphenation and 'hardbreak' help improve density, especially for tall, narrow blocks
% of course, this all varies with the text at hand, so this might be pointless to know
% three-term geometry spec allows this to be optimized
intext = 'The phenomenon of money presupposes an economic order in which production is based on division of labor and in which private property consists not only in goods of the first order (consumption go/ods), but also in goods of higher orders (production goods). In such a society, there is no systematic centralized control of production, for this is inconceivable without centralized disposal over the means of production. Production is "anarchistic." What is to be produced, and how it is to be produced, is decided in the first place by the owners of the means of production, who produce, however, not only for their own needs, but also for the needs of others, and in their valuations take into account, not only the use-value that they themselves attach to their products, but also the use-value that these possess in the estimation of the other members of the community. The balancing of production and consumption takes place in the market, where the different producers meet to exchange goods and services by bargaining together. The function of money is to facilitate the business of the market by acting as a common medium of exchange.';

w = 150:4:1000;
area = zeros([3 numel(w)]);
for n = 1:numel(w)
	outpict = textblock(intext,[NaN w(n)],'font','compaq-8x8','enablehyph',false,'tightwidth',true);
	area(1,n) = numel(outpict);
	outpict = textblock(intext,[NaN w(n)],'font','compaq-8x8','enablehyph',true,'tightwidth',true);
	area(2,n) = numel(outpict);
	outpict = textblock(intext,[NaN w(n)],'font','compaq-8x8','hardbreak',true,'tightwidth',true);
	area(3,n) = numel(outpict);
end

density = numel(intext)./area;
plot(w,density(1,:),'k',w,density(2,:),'b',w,density(3,:),'m')
xlabel('block width')
ylabel('characters per pixel')

td = density(1,:);
[mean(td) std(td)/mean(td)] 
% mean   relstd
% 0.0146 0.0203 for no hyphenation
% 0.0149 0.0163 for hyphenation
% 0.0153 0.0167 for hardbreak
% iirc, these are for w=200:4:700;

%% roundeven

a = -4:0.5:4
br = roundeven(a);
bc = roundeven(a,'ceil');
bf = roundeven(a,'floor');

out = [a; br; bc; bf]

%% roundodd

a = -4:0.5:4;
br = roundodd(a);
bc = roundodd(a,'ceil');
bf = roundodd(a,'floor');

out = [a; br; bc; bf]

%% more rounding demos

x = (-4:0.25:4)';

% built-in functions
y = [x round(x) floor(x) ceil(x) fix(x)];
fprintf('%5.2f %2d  %2d %2d %2d\n',y')

% roundeven
y = [x roundeven(x,'round') roundeven(x,'floor') roundeven(x,'ceil') roundeven(x,'in') roundeven(x,'out')];
fprintf('%5.2f %2d  %2d %2d  %2d %2d\n',y')

% roundodd
y = [x roundodd(x,'round') roundodd(x,'floor') roundodd(x,'ceil') roundodd(x,'in') roundodd(x,'out')];
fprintf('%5.2f %2d  %2d %2d  %2d %2d\n',y')

%% morphnhood demo
lutstack = zeros([3 3 1 512]);
for k = 1:512
	a = reshape(fliplr(dec2bin(k-1,9) == '1'),3,3);
	lutstack(:,:,:,k) = a;
end
inpict = imtile(lutstack,[16 32]); % this represents all possible inputs

outpict = morphnhood(inpict,'bridge',1);

inpict = imresizeFB(inpict,6,'nearest');
outpict = imresizeFB(outpict,6,'nearest');

outpict = cat(3,inpict,inpict,outpict);

imshow2('outpict','invert','tools')
%imwrite(inpict,'examples/morphnhoodex1.gif')
%imwrite(outpict,'examples/morphnhoodex2.png')

%%
lutstack = zeros([3 3 1 512]);
for k = 1:512
	a = reshape(fliplr(dec2bin(k-1,9) == '1'),3,3);
	lutstack(:,:,:,k) = a;
end
inpict = imtile(lutstack,[16 32]); % this represents all possible inputs

se5 = [0 1 0; 1 1 1; 0 1 0];

outpict = morphnhood(inpict,'matches',se5,1);

inpict = imresizeFB(inpict,6,'nearest');
outpict = imresizeFB(outpict,6,'nearest');

imcompare('inpict','outpict','invert')
%imwrite(outpict,'examples/morphnhoodex3.gif')

%% despeckle demo
inpict = imread('sources/table.jpg');
inpict = mono(inpict,'y') > 0.3*255;

ms = 100;
opopen = despeckle(inpict,ms,'open');
opclose = despeckle(inpict,ms,'close');

outpict = double(cat(3,opopen,opclose,inpict));

imshow2('outpict','invert','tools')
%imwrite(inpict,'examples/despeckleex1.gif')
%imwrite(outpict,'examples/despeckleex2.png')

%% bwdistFB demo

inpict = imread('sources/colorballs.jpg');
inpict = mono(inpict,'y') > 0.1*255;
inpict = morphnhood(inpict,'perim4');

[D R] = bwdistFB(inpict);
[imrange(D); imrange(R)]

outpict = cat(1,simnorm(double(D)),simnorm(double(R)));
imshow2('outpict','invert','tools')

%imwrite(inpict,'examples/bwdistFBex1.gif')
%imwrite(outpict,'examples/bwdistFBex2.jpg')

%% interleave/deinterleave demo

A = imread('sources/table.jpg');
B = imtweak(A,'hsy',[0.25 1 1]);
C = imtweak(A,'hsy',[0.50 1 1]);

D = interleave(1,A,B,C,30);
imshow2('D','invert','tools')

[AA BB CC] = deinterleave(D,1,30);

% original images are recovered
imerror(A,AA) % = 0
imerror(B,BB) % = 0
imerror(C,CC) % = 0

%imwrite(D,'examples/interleaveex1.jpg')
%imwrite(AA,'examples/interleaveex2.jpg')
%imwrite(BB,'examples/interleaveex3.jpg')
%imwrite(CC,'examples/interleaveex4.jpg')

%% alternate/dealternate demo

A = imread('sources/table.jpg');
B = imtweak(A,'hsy',[0.25 1 1]);
C = imtweak(A,'hsy',[0.50 1 1]);

D = alternate(1,A,B,C,30);
imshow2('D','invert','tools')

[AA BB CC] = dealternate(D,1,30);

%imwrite(D,'examples/alternateex1.jpg')
%imwrite(AA,'examples/dealternateex1.jpg')
%imwrite(BB,'examples/dealternateex2.jpg')
%imwrite(CC,'examples/dealternateex3.jpg')

%% imcheckerboard demo

% default
A = imcheckerboard();

% asymmetric tiles
B = imcheckerboard([20 10]);

% different number of blocks and no tint
C = imcheckerboard([20 10],[10 10],'uniform');

%imwrite(A,'examples/imcheckerboardex1.jpg')
%imwrite(B,'examples/imcheckerboardex2.jpg')
%imwrite(C,'examples/imcheckerboardex3.jpg')

%% freecb demo

A = freecb([200 300],[35 54]);

imshow2('A','invert','tools')

%imwrite(A,'examples/freecbex1.jpg')

%% nhfilter demo

inpict = imread('sources/blacklight2.jpg');

A = nhfilter(inpict,'stdn');
B = nhfilter(inpict,'localcont');
out = cat(1,A,B);

imshow2('out','invert','tools')
%imwrite(out,'examples/nhfilterex1.jpg')

%% 
% calculate local min/median/max simultaneously
inpict = imread('peppers.png');

OS = nhfilter(inpict,'ordstat',5,[1 13 25]);
out = imtile(OS,[3 1]);

imshow2(out,'invert')
%imwrite(out,'examples/nhfilterex2.jpg')

%% imnoiseFB demo

inpict = imread('sources/colorballs.jpg');

A = imnoiseFB(inpict,'gaussian');
B = imnoiseFB(inpict,'salt & pepper');
C = imnoiseFB(inpict,'spatial',[5 20]);
out = cat(1,A,B,C);

imshow2('out','invert','tools')
%imwrite(out,'examples/imnoiseFBex1.jpg')

%% imrectify demo (test vector generation)
% for the sake of not duplicating data in the toolbox archive, i didn't include any
% sample raw image files.  instead, let's just generate some vectors from existing sources

cmode = 'pixel';

% build test image
inpict = imread('sources/blacklight2.jpg');
switch cmode
	case 'mono'
		rawpict = reshape(rgb2gray(inpict),[],1); 
	case 'pixel'
		rawpict = zeros(numel(inpict),1,class(inpict));
		for c = 1:3
			rawpict(c:3:end) = reshape(inpict(:,:,c),[],1);
		end
	case 'page'
		rawpict = reshape(inpict,[],1);
end

% open the gui, using default options
recoveredpict = imrectify(rawpict);

%% 
% instead of using the gui, just grab the image with the highest EOQ
recoveredpict = imrectify(rawpict,'cmode','pixel','autoselect');

%% 
% use an undocumented console-only mode.  
% this will print a table of information about the 10 best candidates
% and then prompt the user to select one
recoveredpict = imrectify(rawpict,'cmode','pixel','showgui',false);

%% 
% use the console-only mode to show the recovery of a seemingly difficult image
inpict = rand(512,512); % start with just random data
rawpict = reshape(inpict,[],1); % reshape to a vector

% the intended result should be at the top of the table
recoveredpict = imrectify(rawpict,'showgui',false);

%% jellyroll demo
% show the basics with a small matrix
aa = reshape(1:20,4,5)

bb = jellyroll(aa,'direction','in','rotation','ccw','tailpos','nw')
cc = jellyroll(aa,'direction','out','rotation','ccw','tailpos','nw')
dd = jellyroll(aa,'direction','in','rotation','cw','tailpos','nw')
ee = jellyroll(aa,'direction','in','rotation','ccw','tailpos','sw')
ff = jellyroll(aa,'direction','in','rotation','ccw','tailpos','nw','alternate')

%% 
% actually roll an image
inpict = imread('sources/blacklight2.jpg');

outpict = jellyroll(inpict);

imshow2(outpict,'invert','tools')
%imwrite(outpict,'examples/jellyrollex1.jpg')

%% 
% make some garbage
inpict = imread('sources/table.jpg');

inpict = imfilter(inpict,fkgen('ring',10));

a = jellyroll(inpict);
b = jellyroll(inpict,'tailpos','sw');
out = imblend(a,b,1,'softlight');
out = jellyroll(out,'tailpos','ne','reverse');

c = imfilterFB(out,fkgen('gaussian',100));
out = imblend(c,out,1,'starglow');

imshow2(out,'invert','tools')
%imwrite(out,'examples/jellyrollex2.jpg')

%% 
% do a blockwise jellyroll
% note the way that the 'alternate' key helps preserve apparent continuity
inpict = imread('sources/blacklight2.jpg');

tiling = [30 30];

s = imsize(inpict,2);
inpict = maketileable(inpict,tiling);
bs = imsize(inpict,2)./tiling;
C = mat2cell(inpict,bs(1)*ones(tiling(1),1),bs(2)*ones(tiling(2),1),size(inpict,3));
out = maketileable(cell2mat(jellyroll(C,'alternate')),tiling,'revertsize',s);

imshow2(out,'invert','tools')
%imwrite(out,'examples/jellyrollex3*.jpg')

%% randisum demo
clc; clf; clearvars

s = 2E7;
sz = [100 1000];
rmin = [100 NaN];
sig = 60;
dmode = 'exponential';

a = randisum(rmin,s,sz,dmode,sig); 

[sum(a(:)) imrange(a) round(mean(a(:)))]
histogram(a,'binmethod','integers')

%% agm/ghm demo
clc; clf; clearvars

a = 12;
b = 34;

amean = mean([a b])
agmean = agm(a,b)
gmean = geomean([a b])
ghmean = ghm(a,b)
hmean = harmmean([a b])

%% gettfm/imappmat demos
clc; clf; clear variables

inpict = imread('sources/table.jpg');
inpict = im2double(inpict);

% Simply extract luma
y = imappmat(inpict,gettfm('luma','rec709'));
imshow2(y,'invert')

% Do a full RGB -> YUV -> RGB conversion cycle
yuv = imappmat(inpict,gettfm('yuv'));
rgb = imappmat(yuv,gettfm('yuv_inv'));

imerror(inpict,rgb)

%% Do full RGB -> YCbCr -> RGB conversion using 'ycbcr'
clc; clf; clear variables

% In this case, both inpict and rgbpict are floating-point, scaled [0 1]
inpict = imread('sources/table.jpg');
inpict = im2double(inpict);
[A os] = gettfm('ycbcr');

% using MIMT imappmat
ycc1 = imappmat(inpict,A,os,'uint8','iptmode');
rgb1 = imappmat(ycc1,inv(A),0,-os,'double','iptmode');

% using IPT imapplymatrix
ycc2 = imapplymatrix(A,inpict,os,'uint8');
os2 = reshape(-os,1,[])*inv(A).'; % input offset reflected to output
rgb2 = imapplymatrix(inv(A),ycc2,os2,'double');

% using columnwise lincomb
s = size(inpict);
ycc3 = uint8(reshape(reshape(inpict,[],3)*A.' + os.',s));
rgb3 = reshape((reshape(double(ycc3),[],3) - os.')/A.',s);

imerror(inpict,rgb1)
imerror(inpict,rgb2)
imerror(inpict,rgb3)

%% Do full RGB -> YCbCr -> RGB conversion using 'ycbcr8'
clc; clf; clear variables

% In this case, both inpict and rgbpict are uint8, scaled [0 255]
inpict = imread('sources/table.jpg');
[A os] = gettfm('ycbcr8');

% using MIMT imappmat
ycc1 = imappmat(inpict,A,os,'uint8','iptmode');
rgb1 = imappmat(ycc1,inv(A),0,-os,'uint8','iptmode');

% using IPT imapplymatrix
ycc2 = imapplymatrix(A,inpict,os,'uint8');
os2 = reshape(-os,1,[])*inv(A).'; % input offset reflected to output
rgb2 = imapplymatrix(inv(A),ycc2,os2,'uint8');

% using columnwise lincomb
s = size(inpict);
ycc3 = uint8(reshape(reshape(double(inpict),[],3)*A.' + os.',s));
rgb3 = uint8(reshape((reshape(double(ycc3),[],3) - os.')/A.',s));

imerror(inpict,rgb1)
imerror(inpict,rgb2)
imerror(inpict,rgb3)

%% losslessly invertible ycocg modes
clc; clf; clear variables

inpict = im2uint8(permute([0 0 0; hsv(6); 1 1 1],[1 3 2]));

% Do a full RGB -> YCoCg -> RGB conversion cycle
ycc = imappmat(inpict,gettfm('ycocg'),'double','iptmode');
rgb = imappmat(ycc,gettfm('ycocg_inv'),class(inpict),'iptmode');

imerror(inpict,rgb) % lossless

% Do a full RGB -> YCoCg-R -> RGB conversion cycle
ycc = imappmat(inpict,gettfm('ycocgr'),'double','iptmode');
rgb = imappmat(ycc,gettfm('ycocgr_inv'),class(inpict),'iptmode');

imerror(inpict,rgb) % lossless

%% do the same thing, but scale output for integer-valued YCC images
clc; clf; clear variables

inpict = im2uint8(permute([0 0 0; hsv(6); 1 1 1],[1 3 2]));

% Do a full RGB -> YCoCg -> RGB conversion cycle
A = gettfm('ycocg').*[4;2;4];
ycc = imappmat(inpict,A,'double','iptmode');
rgb = imappmat(ycc,inv(A),class(inpict),'iptmode');

imstats(ycc,'min','max')
imerror(inpict,rgb) % lossless
nnz(mod(ycc,1)) % no fractional values, can be cast integer-class

% Do a full RGB -> YCoCg-R -> RGB conversion cycle
A = gettfm('ycocgr').*[4;1;2];
ycc = imappmat(inpict,A,'double','iptmode');
rgb = imappmat(ycc,inv(A),class(inpict),'iptmode');

imstats(ycc,'min','max')
imerror(inpict,rgb) % lossless
nnz(mod(ycc,1)) % no fractional values, can be cast integer-class

% the point of YCoCg-R is kind of moot here, 
% since it's not like there are practical ways to work with (e.g.) 10-bit images in MATLAB

%% circmean demo
clc; clf; clear variables

A = [0:15 355:359]

Am = circmean(A,2,'deg')

%% ccmap demo
clc; clf; clear variables

y = rand(100,6)+(1:6);
plot(y,'linewidth',2)
set(gca,'colororder',ccmap('hsyp',6))
set(gca,'color','k')
ylim([0.5 7.5])

%%
clc; clf; clear variables

names = {'pastel','pwrap','nrl','tone','parula','parula14','turbo','flir1','flir2','dias1'};

m = 64;
n = 256;
A = repmat(1:n,m,1);

nf = numel(names);
outpict = zeros(m,n,3,nf);
for f = 1:nf
	outpict(:,:,:,f) = ind2rgb(A,ccmap(names{f},n));
end
outpict = imtile(outpict,[nf 1]);

imshow2(outpict,'invert')

%%
clc; clf; clear variables

names = {'cat','althi','altlo'};

n = 16;
A = imresize(1:n,[64 floor(256/n)*n],'nearest');

nf = numel(names);
outpict = zeros([imsize(A,2),3,nf]);
for f = 1:nf
	outpict(:,:,:,f) = ind2rgb(A,ccmap(names{f},n));
end
outpict = imtile(outpict,[nf 1]);

imshow2(outpict,'invert')

%% makect demo
clc; clf; clear variables

a = [1 0.2 0.8];
b = [0.3 0.6 0.7];

CT = makect(a,b,16);

A = repmat(1:200,100,1);
imagesc(A)
colormap(gca,CT)

%% splitchans demo
clc; clf; clear variables

inpict = imread('sources/blacklight2.jpg');
inpict = imresizeFB(inpict,0.5);

[R G B] = splitchans(inpict);
out = [R;G;B];

imshow2(out,'invert')
%imwrite(out,'splitchansex1.jpg');

%% imgeofilt demo
clc; clf; clear variables

inpict = imread('sources/tree.jpg');
inpict = imresizeFB(inpict,0.5);
inpict = inpict(:,144:end,:);

fk = fkgen('disk',5);
A = imgeofilt(inpict,fk);
B = imfilterFB(inpict,fk);
out = [inpict A B];

imshow2(out,'invert')
%imwrite(out,'imgeofiltex1.jpg');

%% factor2/factor3 demo
clc; clf; clear variables

npix = 65505;
% get all factor pairs
P = factor2(npix)
% get only factor pairs of unique NAR
P = factor2(npix,'ordered',false)
% exclude pairs with NAR less than 1:100
P = factor2(npix,'ordered',false,'minar',0.01)

%%
npix = 38115;
% get all factor triples
P = factor3(npix)
% get all factor triples with no more than 3 pages
% and with a relatively square page geometry
P = factor3(npix,'minar',0.5,'maxpc',3)
% only get those with unique NAR
P = factor3(npix,'ordered',false,'minar',0.5,'maxpc',3)

%% HWB tools demo
clc; clf; clear variables

inpict = imread('sources/blacklight2.jpg');

hwbpict = rgb2hwb(inpict);
[H W B] = splitchans(hwbpict);
outpict = cat(1,H/360,W,B);

imshow(outpict)

%% legacy mode
clc; clf; clear variables

s = [10 10];
h = 270;
H = repmat(h,s);
[B W] = meshgrid(linspace(0,1,s(2)),linspace(0,1,s(1)));
W = flipud(W);

rgbpict = hwb2rgb(cat(3,H,W,B),'legacy');
rgbpict = imresize(rgbpict,20,'nearest');

imshow(rgbpict)
%imwrite(rgbpict,'examples/rgb2hwbex2.jpg')

%% css mode
clc; clf; clear variables

s = [10 10];
h = 270;
H = repmat(h,s);
[B W] = meshgrid(linspace(0,1,s(2)),linspace(0,1,s(1)));
W = flipud(W);

rgbpict = hwb2rgb(cat(3,H,W,B),'css');
rgbpict = imresize(rgbpict,20,'nearest');

imshow(rgbpict)
%imwrite(rgbpict,'examples/rgb2hwbex3.jpg')

%% show distribution of valid RGB inputs within HWB
% Transforming RGB to HWB places all points within the cone bounded by (W+B)=1.  
% From the perspective of the forward transformation, all points beyond this boundary are not so much
% out-of-gamut as they are simply invalid.  There are no RGB colors which would map there (saturation < 0).
% From the perspective of the reverse transformation, they're all naturally mapped to the neutral axis.
% In other words, the majority of the volume within the axes extents of HWB is a bunch of nonsense colors 
% that map to unintuitive locations on the neutral axis -- locations which depend entirely on the implementation.
% Note that all neutral colors map to a single hue in the forward transformation (as expected).  
% The only reason this looks weird is because it's basically inside-out HSV.  
% The neutral axis is now a diagonal vector on the surface of a cone.  How convenient.

% [hh ss vv] = ndgrid(linspace(0,1,15));
% bigrgb = hsv2rgb(cat(3,hh(:),ss(:),vv(:)));
% [rr gg bb] = imsplit(bigrgb);

[rr gg bb] = ndgrid(linspace(0,1,256));
bigrgb = cat(3,rr(:),gg(:),bb(:));

[H W B] = splitchans(rgb2hwb(bigrgb));
[X Y] = pol2cart(H*pi/180,W);

scatter3(X,Y,B,30,[rr(:),gg(:),bb(:)],'filled');
axis equal

%% siftpixels demo
clc; clf; clear variables

% get a basic test image
A = imread('sources/blacklight2.jpg');
A = imresize(A,[300 NaN]);
A = imcast(A,'double');

% delete some pixels
sz0 = size(A);
alph = radgrad(sz0(1:2),[0.5 0.5],0.5,[255;0],'cosine','uint8') + 100;
mk = logical(noisedither(alph,'blue'));
for c = 1:3
	Ac = A(:,:,c);
	Ac(~mk) = NaN;
	A(:,:,c) = Ac;
end

C1 = siftpixels(A,'n');
C2 = siftpixels(A,'s');
C3 = siftpixels(A,'e');
C4 = siftpixels(A,'w');
C5 = siftpixels(A,'h');
C6 = siftpixels(A,'v');
C7 = siftpixels(A,'c');
C = [C1; C2; C3; C4; C5; C6; C7];

imshow2(C,'invert')

%% channel-independent operation, explicit gravity
clc; clf; clear variables

% get a basic test image
A = imread('sources/blacklight2.jpg');
A = imresize(A,[300 NaN]);
A = imcast(A,'double');

% delete some pixels (different locations per channel)
sz0 = size(A);
cn = [140 110];
alph = radgrad(sz0(1:2),cn./sz0(1:2),0.25,[255;150],'linear','uint8') + 50;
for c = 1:3
	mk = logical(noisedither(alph,'blue'));
	Ac = A(:,:,c);
	Ac(~mk) = NaN;
	A(:,:,c) = Ac;
end

C = siftpixels(A,cn);

imshow2(C,'invert')

%% same, but inverted
clc; clf; clear variables

% get a basic test image
A = imread('sources/blacklight2.jpg');
A = imresize(A,[300 NaN]);
A = imcast(A,'double');

% delete some pixels (different locations per channel)
sz0 = size(A);
cn = [140 110];
alph = radgrad(sz0(1:2),cn./sz0(1:2),0.25,[255;150],'linear','uint8') + 50;
for c = 1:3
	mk = logical(noisedither(alph,'blue'));
	Ac = A(:,:,c);
	Ac(~mk) = NaN;
	A(:,:,c) = Ac;
end

C = siftpixels(A,-cn);

imshow2(C,'invert')

%% THIS FILE IS GETTING TOO LONG
%% SEE DEMOSANDBOX2.M FOR MORE
