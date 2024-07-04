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

%% flattenbg demo
clc; clf; clear variables

% this isn't really a technically appropriate use-case, but it's at least a demonstration
A = imread('sources/tree.jpg');

B = flattenbg(A,200);

imshow2(B,'invert')

%% colordiff demo

A = [0.8 0.2 1];
B = [0.8 0.2 0.999];

colordiff(A,B,'lab','de76')
colordiff(A,B,'lab','de94')

%% solarize demo
clc; clf; clear variables

A = imread('sources/tree.jpg');

B = solarize(A);
C = solarize(A,'vee');
outpict = [B C];

imshow2(outpict,'invert')

%% 
clc; clf; clear variables

A = imread('sources/tree.jpg');

in = [0 0.10 0.70 0.94 1]; 
out = [0 0.10 0.90 0.08 0];
B = solarize(A,'in',in,'out',out);
C = solarize(A,'vee','interpmode','cubic');
outpict = [B C];

imshow2(outpict,'invert')

%% 
clc; clf; clear variables

A = linspace(0,1,100);

B = solarize(A);
C = solarize(A,'vee');

p(1) = plot(A,A); hold on
p(2) = plot(A,B);
p(3) = plot(A,C);
legend(p,{'input','''default''','''vee'''},'location','northwest')

%% imcurves demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');
A = imresize(A,0.5);

B = imcurves(A,[0 0.5 1],[0 1 0],'color');
C = imcurves(A,[0 0.5 1],[0 1 0],'hsl');
D = imcurves(A,[0 0.5 1],[0 1 0],'lchuv');
outpict = [B; C; D];

imshow2(outpict,'invert')

%% 
[x y] = meshgrid(linspace(0,1,100));
A = cat(3,x,x,x,y); % RGBA image

B = imcurves(A,[0 0.5 1],[0 1 0],'color');
C = imcurves(A,[0 0.5 1],[0 1 0],'all');
outpict = [B C];

imshow2(outpict,'invert')

%% ctflop demo

n = 10;
CThusl = [linspace(0,300,n).', ...
	     100*ones(n,1), 70*ones(n,1)];

CTrgb = ctflop(husl2rgb(ctflop(CThusl),'luvp'))
demopict = imresize(repmat(ctflop(CTrgb),[1 n]),10,'nearest');

imshow(demopict)

%% splitalpha demo
clc; clf; clear variables

[x y] = meshgrid(linspace(0,1,100));
A = cat(3,0.7*x,0.2*x,0.9*x,y); % RGBA image

[Acolor Aalpha] = splitalpha(A);

subplot(1,3,1)
imshow2(A,'invert')
subplot(1,3,2)
imshow2(Acolor,'invert')
subplot(1,3,3)
imshow2(Aalpha,'invert')

%% colorbalance demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');

K = [1 0 -1; 0 0 0; -1 0 1];
B = colorbalance(A,K);

imshow2(B,'invert')
%imwrite(B,'examples/colorbalanceex1.jpg')

%% imbcg demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');

B = imbcg(A,'b',0.6);
C = imbcg(A,'b',0.6,'gimpmode');
outpict = [B;C];

imshow2(outpict,'invert')
%imwrite(outpict,'examples/imbcgex1.jpg')

%% mixchannels demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');

K = [0.5 0.3 0.2; 0 0.3 0.7; 0.5 0 0.5];
outpict = mixchannels(A,K);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/mixchannelsex1.jpg')

%% gcolorize demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');

K = [300 50 0];
outpict = gcolorize(A,K);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/gcolorizeex1.jpg')

%% ghlstool demo
clc; clf; clear variables

A = imread('sources/blacklight2.jpg');

K = [60 50 0];
outpict = ghlstool(A,K);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/ghlstoolex1.jpg')

%% tonergb demo
clc; clf; clear variables

inpict = imread('peppers.png');

Tr = [00,00,00; 10,25,50; 00,00,00]/255; 
Tg = [00,00,00; -10,-25,-50; 00,00,00]/255;
Tb = [00,00,00; 00,00,00; 00,00,00]/255; 
Tsat = [0,0,128,255,255]/255;
outpict = tonergb(inpict,Tr,Tg,Tb,Tsat,'preserve');

imshow2(outpict,'invert')
%imwrite(outpict,'examples/tonergbex1.jpg')

%% tonecmyk demo
clc; clf; clear variables

inpict = imread('peppers.png');

% modern film
Tc = [00,20,00; 00,08,00; 00,00,00; 00,-23,00]/255;
Tm = [00,-13,00; 00,17,00; 00,00,00; -1,29,00]/255;
Ty = [00,00,00; 00,00,-12; 00,00,00; 19,68,18]/255;
Tk = [00,00,00; 00,00,00; 00,00,00; -5,55,-15 ]/255;
Tsat = [128,255,255,255,255]/255;
outpict = tonecmyk(inpict,Tc,Tm,Ty,Tk,Tsat,'preserve');

imshow2(outpict,'invert')
%imwrite(outpict,'examples/tonecmykex1.jpg')

%% tonepreset demo
clc; clf; clear variables

inpict = imread('peppers.png');

B = tonepreset(inpict,'warmvintage');
C = tonepreset(inpict,'fadedprint',1.5);
outpict = [B;C];

imshow2(outpict,'invert')
%imwrite(outpict,'examples/tonepresetex1.jpg')

%% unsharp demo
clc; clf; clear variables

inpict = imread('sources/vegetables.jpg');

outpict = unsharp(inpict,'sig',5,'amt',0.5);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/unsharpex1.jpg')

%% bwfilmemu demo
clc; clf; clear variables

inpict = imread('sources/vegetables.jpg');
inpict = imresize(inpict,0.4);

B = bwfilmemu(inpict,'Agfa 200X');
C = bwfilmemu(inpict,'Kodak Tmax 400');
D = bwfilmemu(inpict,'Generic BW');
outpict = [B;C;D];

imshow2(outpict,'invert')
%imwrite(outpict,'examples/bwfilmemuex1.jpg')

%% uwredcomp demo
clc; clf; clear variables

inpict = imread('sources/underwaterimg1.jpg');
inpict = imresize(inpict,0.4);

% demonstrate contrast behavior
op_minalpha = uwredcomp(inpict,'alpha',0);
op_default = uwredcomp(inpict); % default is alpha = 0.4
op_maxalpha = uwredcomp(inpict,'alpha',1);

outpict = [op_minalpha; op_default; op_maxalpha];

imshow2(outpict,'invert')
%imwrite(outpict,'examples/uwredcompex1.jpg')

%% joinalpha demo
clc; clf; clear variables

rgbpict = imread('sources/table.jpg');
alpha = lingrad(imsize(rgbpict,2),[0.5 0.5; 1 1],[255; 0],'linear');

rgbapict = joinalpha(rgbpict,alpha);

imshow2(rgbapict,'invert')
%imwrite(rgbapict(:,:,1:3),'examples/joinalphaex2.png','alpha',rgbapict(:,:,4))

%% gray2rgb demo
clc; clf; clear variables

% say you have an I/IA image
inpict = imread('sources/table.jpg');
inpict = mono(inpict,'y');
alpha = lingrad(imsize(inpict,2),[0.5 0.5; 1 1],[255; 0],'linear');
inpict = joinalpha(inpict,alpha);
[ncc_in nca_in] = chancount(inpict)

% expand color channels
outpict = gray2rgb(inpict);
[ncc_out nca_out] = chancount(outpict)

imshow2(outpict,'invert')
%imwrite(inpict(:,:,1),'examples/gray2rgbex1.png','alpha',inpict(:,:,2))
%imwrite(outpict(:,:,1:3),'examples/gray2rgbex2.png','alpha',outpict(:,:,4))

%% alphasafe demo
clc; clf; clear variables

% say you have an IA/RGBA image
inpict = imread('sources/table.jpg');
alpha = lingrad(imsize(inpict,2),[0.5 0.5; 1 1],[255; 0],'linear');
inpict = joinalpha(inpict,alpha);
[ncc_in nca_in] = chancount(inpict)

% add checkerboard padding to visualize alpha
outpict = alphasafe(inpict);
[ncc_out nca_out] = chancount(outpict)

imshow2(outpict,'invert')
%imwrite(outpict,'examples/alphasafeex1.png')

%% ctpath demo
clc; clf; clear variables

% get a CT
cmap = ccmap('pastel',32);

% display the trajectory in RGB
ctpath(cmap,'rgb','invert',50)

%% 
clc; clf; clear variables

% get a CT
cmap = ccmap('pastel',32);

% display the trajectory in HSYp
ctpath(cmap,'hsyp','invert',50)

%% ctshift demo
clc; clf; clear variables

% get a CT
cmap = ccmap('pastel',100);

instripe = repmat(ctflop(cmap),[1 25]);

A = ctshift(instripe,-0.6);
B = ctshift(instripe,-0.3);
C = ctshift(instripe,0.3);
D = ctshift(instripe,0.6);

imshow2([A B instripe C D],'invert')

%% rbdetile demo
clc; clf; clear variables

inpict = imread('sources/goat.jpg');

% extract 12 blocks using default size
tiles = rbdetile(inpict,12);
% add a border 
tiles = addborder(tiles,2);
% retile for viewing
outpict = imtile(tiles,[3 4]);

imshow2(outpict,'invert')

%%
% extract 12 blocks using a specified size
tiles = rbdetile(inpict,12,[120 100]);
% add a border 
tiles = addborder(tiles,2);
% retile for viewing
outpict = imtile(tiles,[3 4]);

imshow2(outpict,'invert')

%% ptile demo
clc; clf; clear variables

szo = [128 64]+1;
os = [0 0];

% these files are included
A = imread('sources/patterns/ospat/OldSchool_A6_013.png');
B = imread('sources/patterns/ospat/OldSchool_A6_089.png');

A = ptile(A,szo,os);
B = ptile(B,szo,os);

outpict = [A B];

imshow(iminv(outpict));

%% 
clc; clf; clear variables

szo = [300 150]+1;
os = [0 0];

% THESE FILES ARE NOT INCLUDED (GIMP pattern library)
A = imread('sources/patterns/gpat/ground1.png');
B = imread('sources/patterns/gpat/wood1.png');

A = ptile(A,szo,os);
B = ptile(B,szo,os);

outpict = [A B];

imshow(iminv(outpict));

%% impatsort/patbinchart demo
clc; clf; clear variables

% THESE FILES ARE NOT INCLUDED (Krita pattern library)
fpattern = 'sources/patterns/krpat/*.png';

[G ugl] = impatsort(fpattern);
swatchlist = patbinchart(G);

[G ugl] = impatsort(fpattern,'maxwidth',20);
swatchlistsm = patbinchart(G);

outpict = imstacker({swatchlist swatchlistsm},'dim',2,'padding',0);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/impatsortex1.png')

%% 
clc; clf; clear variables

% THESE FILES ARE NOT INCLUDED (a selection from GIMP/Krita libraries and others)
% a pile of path expressions from a file
fid = fopen('sources/patterns/collection_nongeometric.txt');
fpattern = textscan(fid,'%s');
fpattern = fpattern{:};
fclose(fid);

[G ugl] = impatsort(fpattern,'maxwidth',100,'maxcont',1);
swatchlist_hc = patbinchart(G);

[G ugl] = impatsort(fpattern,'maxwidth',100,'maxcont',0.6);
swatchlist_lc = patbinchart(G);

outpict = imstacker({swatchlist_hc swatchlist_lc},'dim',2,'padding',0);

imshow2(outpict,'invert')
%imwrite(outpict,'examples/impatsortex2.png')

%% impatmap demo (standard pattern lib with/without contours)
clc; clf; clear variables

% a simple test gradient
inpict = radgrad([800 500],[0 0],1,[0; 255]);

% these patterns are included
fpattern = 'sources/patterns/ospat/*.png';
[G ugl] = impatsort(fpattern);

OP1 = impatmap(inpict,G,ugl,'nlevels',12);
OP2 = impatmap(inpict,G,ugl,'nlevels',12,'addcontours',true);

imshow2([OP1 OP2],'invert')
%imwrite(OP1,'examples/impatmapex1.png')
%imwrite(OP2,'examples/impatmapex2.png')

%% mixed gray texture collection (with/without contrast restriction)
clc; clf; clear variables

% a simple test gradient
inpict = radgrad([800 500],[0 0],1,[0; 255]);

% THESE FILES ARE NOT INCLUDED (a selection from GIMP/Krita libraries and others)
% a pile of path expressions from a file
fid = fopen('sources/patterns/collection_nongeometric.txt');
fpattern = textscan(fid,'%s');
fpattern = fpattern{:};
fclose(fid);

[G ugl] = impatsort(fpattern);
OP1 = impatmap(inpict,G,ugl,'nlevels',12);

[G ugl] = impatsort(fpattern,'maxcont',0.6);
OP2 = impatmap(inpict,G,ugl,'nlevels',12);

imshow2([OP1 OP2],'invert')
%imwrite(OP1,'examples/impatmapex3.png')
%imwrite(OP2,'examples/impatmapex4.png')

%% demonstrate utility of pattern size restriction
clc; clf; clear variables

% a simple test gradient
inpict = radgrad([800 500],[0 0],1,[0; 255]);

% THESE FILES ARE NOT INCLUDED (Krita monochrome patterns)
fpattern = 'sources/patterns/krpat/*.png';

[G ugl] = impatsort(fpattern);
OP1 = impatmap(inpict,G,ugl,'nlevels',12);

[G ugl] = impatsort(fpattern,'maxwidth',20);
OP2 = impatmap(inpict,G,ugl,'nlevels',12);

imshow2([OP1 OP2],'invert')
%imwrite(OP1,'examples/impatmapex5.png')
%imwrite(OP2,'examples/impatmapex6.png')

%% impatmap demo (using fonts)
clc; clf; clear variables

% a simple test gradient
inpict = radgrad([800 500],[0 0],1,[0; 255]);

% these files are included, but the TOOLBOX/ prefix will not exist in your installation
% note that font file names do not necessarily match the naming in textim() synopsis!

% load fonts with a wildcard expression
fpattern = 'TOOLBOX/fonts/compaq*.mat';
[G ugl] = impatsort(fpattern);
OP1 = impatmap(inpict,G,ugl,'nlevels',12);

% load a mix of fonts and patterns
fpattern = {'TOOLBOX/fonts/everex-me.mat'; 'sources/patterns/ospat/*.png'};
[G ugl] = impatsort(fpattern);
OP2 = impatmap(inpict,G,ugl,'nlevels',12);

imshow2([OP1 OP2],'invert')
%imwrite(OP1,'examples/impatmapex7.png')
%imwrite(OP2,'examples/impatmapex8.png')

%% roifilter demo
clc; clf; clear variables

inpict = imread('peppers.png');
mk = imread('sources/standardmods/pep/redpepmask.png');

% F is a gaussian filter size
F = 30;
op1 = roifilter(inpict,mk,F);

% F is a filter kernel
F = fkgen('glow2',10);
op2 = roifilter(inpict,mk,F);

% F is a function handle
F = @(x) medfilt2(x,[20 20]); % IPT medfilt2() can't process multichannel
op3 = roifilter(inpict,mk,F,'forcemono'); % so use 'forcemono' flag

outpict = [op1; op2; op3];

imshow2(outpict,'invert')
%imwrite(outpict,'examples/roifilterex1.jpg')

%% do something that roifilt2() can't do
% looping can't allow roifilt2() to perform tasks which require color information
% roifilt2() can't handle anything other than binary masks
% consequently, roifilt2() also can't do linear RGB compositing
clc; clf; clearvars

inpict = imread('peppers.png');
mk = imread('sources/standardmods/pep/redpepmask.png');

% mask is already antialiased, but soften it more so that it's obvious
mk = imgaussfilt(mk,10);

F = @(x) imtweak(x,'lchab',[1 1 -0.20]);

outpict = roifilter(inpict,mk,F,'linear');

imshow2(outpict,'invert')
%imwrite(mk,'examples/roifilterex2.jpg')
%imwrite(outpict,'examples/roifilterex3.jpg')

%% compare timing with FK
clc; clf; clearvars

inpict = imread('peppers.png');
mk = imread('sources/standardmods/redpepmask.png')>128; % binarized

F = fkgen('glow2',10);

tic 
A = roifilter(inpict,mk,F);
toc

tic
B = inpict;
for c = 1:size(inpict,3)
	B(:,:,c) = roifilt2(F,inpict(:,:,c),mk);
end
toc

%% compare timing with FH
clc; clf; clearvars

inpict = imread('peppers.png');
mk = imread('sources/standardmods/redpepmask.png')>128; % binarized

F = @(x) medfilt2(x,[20 20]);

tic 
A = roifilter(inpict,mk,F,'forcemono');
toc

tic
B = inpict;
for c = 1:size(inpict,3)
	B(:,:,c) = roifilt2(inpict(:,:,c),mk,F);
end
toc

%% compare timing with FK (multisegment mask)
% due to shape and position of blobs, using blobwise is faster
% even when not blobwise, roifilter() is still faster than roifilt2()
% since it can process the entire image segment without compounding overhead costs
clc; clf; clearvars

inpict = imread('sources/blacklight2.jpg');
mk = imread('sources/blacklight2mk.png')>128; % binarized

F = fkgen('glow2',30);

tic 
A1 = roifilter(inpict,mk,F);
toc

tic 
A2 = roifilter(inpict,mk,F,'blobwise');
toc

tic
B = inpict;
for c = 1:size(inpict,3)
	B(:,:,c) = roifilt2(F,inpict(:,:,c),mk);
end
toc

tic 
C = imfilterFB(inpict,F);
C = replacepixels(C,inpict,mk);
toc

imshow2(A1,'invert')

%% compare timing with FK (multisegment mask)
% this case shows two things
% neither tool is faster than processing the whole image, due to blob extents
% using blobwise processing is much slower, since processed area is larger than the entire image
clc; clf; clearvars

inpict = imread('peppers.png');
mk = imread('sources/standardmods/pepstripemk.png')>128; % binarized

F = fkgen('glow2',30);

tic 
A1 = roifilter(inpict,mk,F);
toc

tic 
A2 = roifilter(inpict,mk,F,'blobwise');
toc

tic
B = inpict;
for c = 1:size(inpict,3)
	B(:,:,c) = roifilt2(F,inpict(:,:,c),mk);
end
toc

tic 
C = imfilterFB(inpict,F);
C = replacepixels(C,inpict,mk);
toc

imshow2(A1,'invert')

%% pickblob() demo
clc; clf; clearvars

% reduce a test image to a small mask for testing
inmask = imread('sources/blobs/blobs.png');
inmask = rgb2gray(inmask)>128;
inmask = imresize(inmask,[280 280]);

% generate a bunch of random points
points = randrange([-10 300],30,2);

% show the point placement on the image
imshow(inmask); hold on
plot(points(:,1),points(:,2),'*','linewidth',2)

% get selected blob(s) and index lists
outmask = pickblob(inmask,points,'null');

imshow2(outmask,'invert','tools')

%% do the same thing, but use single-frame output and get info
% get selected blob(s) and index lists
[outmask Lidx Fidx] = pickblob(inmask,points,'union','null');
[points Lidx Fidx]

imshow2(outmask,'invert')

%% brline() demo
clc; clf; clearvars

% generate a bunch of random vertices that extend beyond the image area
outsize = [150 200];
vertices = [100 75] + 80*randn([30 2]);

% append a border around the image area
vertices = [vertices; 200 150; 200 1; 1 1; 1 150; 200 150];

% draw all the garbage
outpict = brline(outsize,vertices);

imshow2(outpict,'invert')

%% genknit() demo
clc; clf; clearvars

% composition parameters
bgcolor = [0 0 0 0]; % transparent black
rowcolors = ccmap(4);
nloops = 4; % number of loops per row

% generate a knit image with transparent background
outpict = genknit(bgcolor,rowcolors,nloops);

% add something to the background
bg = lingrad(imsize(outpict,2),[0 0; 1 1],[[0.6 0.3 1]*0.5; 1 0.6 0.3],'linear','double');
outpict = replacepixels(outpict,bg,1);

% display output
imshow2(outpict,'invert')

%% 
clc; clf; clearvars

% composition parameters
bgcolor = [0 0 0];
n = 10;
rowcolors = summer(n);
rowcolors = [rowcolors(randperm(n),:) 0.5+0.5*rand(n,1)];
nloops = n; % number of loops per row

outpict = genknit(bgcolor,rowcolors,nloops);
outpict = imresize(outpict,0.2); % doesn't need to be huge

% display output
imshow2(outpict,'invert')

%% matchframes() demo
clc; clf; clearvars

% two 1x1x1xF images
A = permute(1:10,[1 3 4 2]); % 10 frames
B = 1; % 1 frame

% make them match
[A B] = matchframes(A,B);

% illustrate how the shorter image is expanded
squeeze(A).'
squeeze(B).'

%% 
clc; clf; clearvars

% two 1x1x1xF images
A = permute(1:10,[1 3 4 2]); % 10 frames
B = permute([1 2 3],[1 3 4 2]); % 3 frames

% make them match
[A B] = matchframes(A,B,'forceblockwise');

% illustrate how the shorter image is expanded
squeeze(A).'
squeeze(B).'

%% 
clc; clf; clearvars

% two 1x1x1xF images
A = permute(1:10,[1 3 4 2]); % 10 frames
B = permute([1 2 3],[1 3 4 2]); % 3 frames

% make them match
[A B] = matchframes(A,B,'forceframewise');

% illustrate how the shorter image is expanded
squeeze(A).'
squeeze(B).'

%% imreadort() demo
% just display test images in sequence
clc; clf; clearvars

% these images are not included due to size, but are from
% https://github.com/recurser/exif-orientation-examples/releases/tag/v2.0.1
for k = 1:8
	% read images
	fname = sprintf('sources/filetypetests/exif-orientation/Portrait_%d.jpg',k);
	A = imread(fname);
	B = imreadort(fname);
	
	% resize images they're not huge
	A = imresizeFB(A,0.2);
	B = imresizeFB(B,0.2);
	
	% pad images to be square so that the axes geometry stays constant
	A = imstacker({A},'padding',0,'size',[360 360],'outclass','uint8');
	B = imstacker({B},'padding',0,'size',[360 360],'outclass','uint8');
	
	% display images
	subplot(1,2,1); imshow(A); title('imread()')
	subplot(1,2,2); imshow(B); title('imreadort()')
	
	pause(0.1)
end

for k = 1:8
	% read images
	fname = sprintf('sources/filetypetests/exif-orientation/Landscape_%d.jpg',k);
	A = imread(fname);
	B = imreadort(fname);
	
	% resize images they're not huge
	A = imresizeFB(A,0.2);
	B = imresizeFB(B,0.2);
	
	% pad images to be square so that the axes geometry stays constant
	A = imstacker({A},'padding',0,'size',[360 360],'outclass','uint8');
	B = imstacker({B},'padding',0,'size',[360 360],'outclass','uint8');
	
	% display images
	subplot(1,2,1); imshow(A); title('imread()')
	subplot(1,2,2); imshow(B); title('imreadort()')
	
	pause(0.1)
end

%% show that all the images are transformed into the same orientation
clc; clf; clearvars

% these images are not included due to size, but are from
% https://github.com/recurser/exif-orientation-examples/releases/tag/v2.0.1
Cp = cell(8,1);
Cl = cell(8,1);
for k = 1:8
	% load portrait
	fname = sprintf('sources/filetypetests/exif-orientation/Portrait_%d.jpg',k);
	Cp{k} = imreadort(fname);
	% load landscape
	fname = sprintf('sources/filetypetests/exif-orientation/Landscape_%d.jpg',k);
	Cl{k} = imreadort(fname);
end

% stack and take the frame mean
% samples don't need to be huge, so just downscale
meanCp = mean(imresizeFB(imstacker(Cp,'padding',0),0.25),4);
meanCl = mean(imresizeFB(imstacker(Cl,'padding',0),0.25),4);

imshow2(meanCp,'invert')

%% compare to what imread() does by itself
clc; clf; clearvars

% these images are not included due to size, but are from
% https://github.com/recurser/exif-orientation-examples/releases/tag/v2.0.1
Cp = cell(8,1);
Cl = cell(8,1);
for k = 1:8
	% load portrait
	fname = sprintf('sources/filetypetests/exif-orientation/Portrait_%d.jpg',k);
	Cp{k} = imread(fname);
	% load landscape
	fname = sprintf('sources/filetypetests/exif-orientation/Landscape_%d.jpg',k);
	Cl{k} = imread(fname);
end

% stack and take the frame mean
% samples don't need to be huge, so just downscale
meanCp = mean(imresizeFB(imstacker(Cp,'padding',0),0.25),4);
meanCl = mean(imresizeFB(imstacker(Cl,'padding',0),0.25),4);

imshow2(meanCl,'invert')

%% amedfilt()/fmedfilt()
clc; clf; clearvars

% an image
inpict0 = imread('circuit.tif');
inpict0 = mono(inpict0,'y');

% with a crapload of noise
inpict = imnoiseFB(inpict0,'salt & pepper',0.6);

% filter the thing
op1 = amedfilt(inpict,5);
op2 = fmedfilt(inpict,11);

outpict = [op1; op2];
imshow2(outpict,'invert')

%% same thing, but noise doesn't extend exactly to [0 1]
clc; clf; clearvars

% an image
inpict0 = imread('circuit.tif');
inpict0 = mono(inpict0,'y');

% with a crapload of noise
inpict = imnoiseFB(inpict0,'salt & pepper',0.6);
mk = inpict~=inpict0;
inpict(mk) = imadjustFB(inpict(mk),[0 1],[0.01 0.99]);

% filter the thing
op1 = amedfilt(inpict,5); % unaffected
op2 = fmedfilt(inpict,11); % fails completely with tight tolerance
op3 = fmedfilt(inpict,11,0.015); % wider tolerance catches noise

outpict = [op1; op2; op3];
imshow2(outpict,'invert')

%% same thing, but image has been compressed
clc; clf; clearvars

% an image
inpict0 = imread('circuit.tif');
inpict0 = mono(inpict0,'y');

% with compressed noise
inpict = imnoiseFB(inpict0,'salt & pepper',0.1);
inpict = jpegger(inpict,70);

% filter the thing
op1 = amedfilt(inpict,5); % performs poorly
op2 = amedfilt(inpict,5,1); % better
op3 = fmedfilt(inpict,11,0.15); % requires wide tolerance; noisy

% what's better?
err1 = immse(op1,inpict0)
err2 = immse(op2,inpict0)
err3 = immse(op3,inpict0)

outpict = [op1; op2; op3];
imshow2(outpict,'invert')

%% imclassrange()
clc; clf; clearvars

r = imclassrange('double')
r = imclassrange('uint8')
r = imclassrange('int16')

%% native mode
clc; clf; clearvars

% intmax('uint64') can't be represented in double
rd = imclassrange('uint64');
fprintf('%.f\n',rd(2)) % this should be an odd integer
eps(rd(2)) % we are nowhere close to integer-resolution

% but it can in uint64
rn = imclassrange('uint64','native')

%% hex2uint()/uint2hex()
clc; clf; clearvars

% a cellchar containing equal-length tuples (RGB)
hexc = {'0x545880' '#0025FF'};

% convert to a uint8 numeric array
CT = hex2uint(hexc,1)

% convert to unit-scale double
% then convert to hex (6 bytes per tuple)
CT = imcast(CT,'double');
hexc = uint2hex(CT,'nbytes',2)

% convert to uint16 numeric array
% then convert to uint8 for comparison
CT = hex2uint(hexc,2)
CT = im2uint8(CT)

%% hex2uint()
clc; clf; clearvars

% some tuple/number in hex
hexc = '#5458800A'

% convert to a uint8 numeric array
CT = hex2uint(hexc) % default is 1 byte

% convert to a uint16 numeric array
CT = hex2uint(hexc,2)

% convert to a uint32 numeric array
CT = hex2uint(hexc,4)

%% uint2hex()
clc; clf; clearvars

% CT is unit-scale float
CT = [0.7 0.3 1; 0 0.5 1];

% for integer-class inputs
hexc = uint2hex(im2uint8(CT))
hexc = uint2hex(im2uint16(CT))

% for float-class inputs
hexc = uint2hex(CT) % default is 1 byte
hexc = uint2hex(CT,'nbytes',2)

% force cell output
hexc = uint2hex(CT,'celloutput')

% use different prefix
hexc = uint2hex(CT,'prefix','0x')

%% imcropzoom() demo
clc; clf; clearvars

inpict = imread('sources/blacklight2.jpg');
inpict = blockify(inpict,40,'rgb');

% pick a salient group of blocks (e.g. the green bottle)
% try to select those blocks exactly
[outpict rect] = imcropzoom(inpict);

imshow2(outpict)

%% crop2box demo
clc; clf; clearvars

mk = imread('sources/standardmods/pep/redpepmask.png');

[outmask extents] = crop2box(mk);

imshow2(outmask,'invert')
extents

%% apply the same cropping to another image
clc; clf; clearvars

inpict = imread('peppers.png');
mk = imread('sources/standardmods/pep/redpepmask.png');

[outmask rows cols] = crop2box(mk);

outpict = inpict(rows,cols,:);

imshow2(outpict,'invert')

%% puttext demo
clc; clf; clearvars

inpict = imread('peppers.png');
thistext = sprintf('Frame %04d',123);

CT = ccmap('cat',13).^0.5;

params = {thistext,'bgc',[0 0]};
outpict = puttext(inpict,params{:},'fgc',CT(1,:),'offset',[0 30],'angle',0);
outpict = puttext(outpict,params{:},'fgc',CT(2,:),'offset',[20 20],'angle',-45);
outpict = puttext(outpict,params{:},'fgc',CT(3,:),'offset',[30 0],'angle',-90);

params = {thistext,'gravity','se','bgc',[0 1]};
outpict = puttext(outpict,params{:},'fgc',CT(4,:),'offset',-[0 30],'angle',0);
outpict = puttext(outpict,params{:},'fgc',CT(5,:),'offset',-[20 20],'angle',-45);
outpict = puttext(outpict,params{:},'fgc',CT(6,:),'offset',-[30 0],'angle',-90);

outpict = puttext(outpict,thistext,'gravity','w','fgc',[0 1],'bgc',CT(7,:));
outpict = puttext(outpict,thistext,'gravity','e','fgc',[0 1],'bgc',CT(8,:));
outpict = puttext(outpict,thistext,'gravity','n','fgc',[0 1],'bgc',CT(9,:));
outpict = puttext(outpict,thistext,'gravity','s','fgc',[0 1],'bgc',CT(10,:));
outpict = puttext(outpict,thistext,'gravity','ne','bgc',[0 1],'fgc',CT(11,:));
outpict = puttext(outpict,thistext,'gravity','sw','bgc',[0 1],'fgc',CT(12,:));

nt = 8;
h = 32;
map = 'hsyp';
CTf = ccmap(map,nt)+0.2;
CTb = flipud(ccmap(map,nt)-0.1);
params = {thistext,'gravity','c','font','DSM36'};
for k = 1:nt
	yos = h*(1-nt)/2 + (k-1)*h;
	outpict = puttext(outpict,params{:},'bgc',[CTb(k,:) 0.7],'fgc',CTf(k,:),'offset',[yos 0]);
end

imshow2(outpict,'invert')

%% 
clc; clf; clearvars

inpict = imread('peppers.png');
thistext = sprintf('Frame %04d',123);

params = {'gravity','c','bgc',[0 0.2]};
outpict = inpict;
for k = 1:50
	thistext = char(randi(double('az'),1,10));
	thisfgc = rand(1,3);
	os = randi([-200 200],1,2);
	th = 90*randi([0 4],1,1);
	outpict = puttext(outpict,thistext,params{:}, ...
		'fgc',thisfgc,'offset',os,'angle',th);
end

imshow2(outpict,'invert')

%% uniquant demo
clc; clf; clearvars

nlevels = 4;
A = lingrad([50 200],[0 0; 0 1],[0; 255]);
B = uniquant(A,nlevels,'default');
C = uniquant(A,nlevels,'cdscale');
D = uniquant(A,nlevels,'fsdither');
E = uniquant(A,nlevels,'zfdither');
F = uniquant(A,nlevels,'orddither');

% these are index arrays, so rescale them for viewing
outpict = double([B;C;D;E;F])/(nlevels-1);
outpict = imresizeFB(outpict,2,'nearest'); % resize for web-view
imshow2(outpict,'invert')

%% normalize to different limits
clc; clf; clearvars

A = imread('sources/bananas.jpg');
A = mono(A,'y');
A = imadjustFB(A,[0 1],[0 0.5]); % data only spans [0 113]

nlevels = 16;
mode = 'default';
B = uniquant(A,nlevels,mode); % normalize WRT data extrema [0 113]
C = uniquant(A,nlevels,[0 255],mode); % normalize WRT [0 255]

% these are index arrays, so rescale them for viewing
outpict = double([B;C])/(nlevels-1);
imshow2(outpict,'invert')

%% gray2pcolor demo
clc; clf; clearvars

CT = ccmap('tone',8);
A = lingrad([50 200],[0 0; 0 1],[0; 255]);
B = gray2pcolor(A,CT,'default');
C = gray2pcolor(A,CT,'cdscale');
D = gray2pcolor(A,CT,'fsdither');
E = gray2pcolor(A,CT,'zfdither');
F = gray2pcolor(A,CT,'orddither');

outpict = [B;C;D;E;F];
outpict = imresizeFB(outpict,2,'nearest'); % resize for web-view
imshow2(outpict,'invert')

%% 
clc; clf; clearvars

% demonstrate display emulation
CT = gray(32);
A = lingrad([50 200],[0 0; 0 1],[0; 255]);
B = gray2pcolor(A,CT,'cdscale');
C = gray2pcolor(A,CT,'cdscale_display');

outpict = imblend(B,C,1,'difference');
outpict = imresizeFB(outpict,2,'nearest'); % resize for web-view
outpict = simnorm(outpict); % stretch contrast to reveal semiperiodic error
imshow2(outpict,'invert')

%% gbcam demo
clc; clf; clearvars

inpictrgb = imread('sources/table.jpg');
inpict = mono(inpictrgb,'y');
inpict = imlnc(inpict,'k',1.2);

scale = 2;
A = gbcam(inpict,'newschool',scale);
B = gbcam(inpict,'oldschool',scale);
C = gbcam(inpict,'emugreen',scale);
D = gbcam(inpict,'gray',scale);
E = gbcam(inpict,'brigray',scale);
F = gbcam(inpict,'unigray',scale);

outpict = [A D; B E; C F];
imshow2(outpict,'invert')

%% im2ct demo
clc; clf; clearvars

ref = imread('sources/blacklight2.jpg');

% a simple full-range sweep with few breakpoints
CT1 = im2ct(ref,'ncolors',256,'nbreaks',4,'uniform',true, ... 
			'cspace','ypbpr','fullrange',true,'minsat',0.2);
% with native L/Y, slope will be variable, leading to banding
CT2 = im2ct(ref,'ncolors',256,'nbreaks',4,'uniform',false, ...
			'cspace','ypbpr','fullrange',true,'minsat',0.2);
% use LAB instead
CT3 = im2ct(ref,'ncolors',256,'nbreaks',4,'uniform',true, ...
			'cspace','lab','fullrange',true,'minsat',0.2);
% too many breakpoints to appear smooth
CT4 = im2ct(ref,'ncolors',256,'nbreaks',8,'uniform',true, ...
			'cspace','lab','fullrange',true,'minsat',0.2);
% don't sweep all the way to black/white
CT5 = im2ct(ref,'ncolors',256,'nbreaks',4,'uniform',true, ...
			'cspace','lab','fullrange',false,'minsat',0.2);
% specify a different number of output colors
CT6 = im2ct(ref,'ncolors',16,'nbreaks',4,'uniform',true, ...
			'cspace','lab','fullrange',true,'minsat',0.2);

% build an output image
A = lingrad([50 200],[0 0; 0 1],[0; 255]);
B = gray2pcolor(A,CT1);
C = gray2pcolor(A,CT2);
D = gray2pcolor(A,CT3);
E = gray2pcolor(A,CT4);
F = gray2pcolor(A,CT5);
G = gray2pcolor(A,CT6);
outpict = [B;C;D;E;F;G];

imshow2(outpict,'invert')

%% use im2ct() for simple image recoloring
clc; clf; clearvars

ref = imread('sources/blacklight2.jpg');
inpict = imread('sources/table.jpg');

CT = im2ct(ref,'ncolors',256,'nbreaks',4,'uniform',true, ...
			'cspace','ypbpr','fullrange',true,'minsat',0.2);
outpict = gray2pcolor(inpict,CT,imclassrange(class(inpict)),'default');

% perhaps enforce Y if you want (if using 'lab' or 'fullrange',false)
%outpict = imblend(inpict,outpict,1,'lumac');

% display
subplot(8,1,1)
image(rot90(ctflop(1-CT)))
subplot(8,1,2:8)
imshow2(outpict,'invert')

%% histeqtool()
clc; clf; clearvars

inpict = imread('sources/table.jpg');

op1 = histeqtool(inpict,'ahisteqrgb','clip',0.008);
op2 = histeqtool(inpict,'ahisteqlchab','clip',0.008);

outpict = [op1; op2];
imshow2(outpict,'invert')

%% autowb()
clc; clf; clearvars

inpict = imread('sources/handcar_small.jpg');
outpict = autowb(inpict);

imshow2(outpict,'invert')

%%
clc; clf; clearvars

inpict = imread('sources/standardmods/hallway_small.jpg');

% use illumwhite()/chromadapt()
% overexposed regions tend to become unnaturally saturated
% causing an apparent brightness inversion
percentileToExclude = 10;
illuminant_wp1 = illumwhite(inpict,percentileToExclude);
op1 = chromadapt(inpict,illuminant_wp1,'colorspace','srgb','method','bradford');

% use autowb() with blind white region determination
% results are generally moderated, but saturated regions are not molested
op2 = autowb(inpict);

% use autowb() with an explicit mask
mask = imread('sources/standardmods/hallway_small_mask.png');
op3 = autowb(inpict,mask);

outpict = [op1; op2; op3];
%outpict = mono(outpict,'llch');
imshow2(outpict,'invert')

%% squaresize()
clc; clf; clearvars

V = rand(1,1564653); % a vector
N = numel(V); % the vector length
f = factor2(N,'ordered',false) % note N doesn't have useful factors
ar = f(:,1)./f(:,2) % obviously these are far from unity

sz = squaresize(N,'fitmode','shrink') % resolve by shrinking the vector
sq1 = V(1:prod(sz)); % trim and reshape
sq1 = reshape(sq1,sz);
ar = min(sz)/max(sz) % square enough

sz = squaresize(N,'fitmode','grow') % resolve by padding the vector
sq2 = padarray(V,[0 prod(sz)-N],0,'post'); % pad the vector
sq2 = reshape(sq2,sz);
ar = min(sz)/max(sz) % square enough

%% MIMT imhistFB() versus IPT imhist()'s binning misrepresentation
clc; clf; clearvars

inpict = rand(500);
n = 5;

% histogram bins are centered on [0 1], with a stem plotted
% in the center of each bin.
% the stripe segments are edge-aligned to [0 1], so the segments
% do not line up with the histogram bin locations,
% and the gray levels in the stripe don't correspond to 
% the centers of _either_ set of positions.
% the gray levels correspond to the upper edge of the stripe segment positions.
% floor(N/2) out of N stripe segments are colored with a gray level
% that's not even present in the corresponding histogram bin.
subplot(2,1,1)
imhist(inpict,n)

% the stripe segments are always aligned with the corresponding
% histogram bins, and the gray levels correspond to the center of 
% each histogram bin.
subplot(2,1,2)
imhistFB(inpict,n);

%% a little more emphasis on where imhist() aligns things wrong
ccc

% some inputs
inpict = rand(500);
n = 5;

% imhist can either give outputs or plot.  
% it can't do both, so we have to call it twice.
imhist(inpict,n); hold on
[counts centers] = imhist(inpict,n);

% find the axes since it won't give them to us
hax = findobj(get(gcf,'children'),'type','axes');

% figure out the bin edges from the centers, 
% since it won't give us edges either
dx = diff(centers(1:2));
xr = [centers(1)-dx/2 centers(end)+dx/2];
yr = ylim(hax(2));

% create two images: 
% top is a smooth sweep from black to white.
% bottom corresponds to the center of each histogram bin.
% the two images should periodically match at each bin center.
smoothramp = repmat(linspace(xr(1),xr(2),100),[1 1 3]);
binramp = repmat(centers.',[1 1 3]);
binramp = imresize(binramp,[1 size(smoothramp,2)],'nearest');

% concatenate the two stripe images
% clamp as necessary for legacy versions
compramp = min(max([binramp; smoothramp],0),1);

% put the composite image behind the stem plot
hi = image(xr,yr,compramp,'parent',hax(2));
uistack(hi,'bottom')

% find the stem plot and make it fat so it's easier to see
hst = findobj(hax(2),'type','stem');
set(hst,'linewidth',3)

% draw a solid gray circle above each stem, 
% such that the circle color is taken directly from the stem position
for k = 1:n
	hp = plot(hax(2),centers(k),yr(2)*0.67,'.');
	set(hp,'color',[1 1 1]*centers(k));
	set(hp,'markersize',60);
end

%% demonstrate plot styles
clc; clf; clearvars

inpict = imread('cameraman.tif');
n = 32;

subplot(3,1,1)
imhistFB(inpict,n,'style','stem'); % imhist()-style

subplot(3,1,2)
imhistFB(inpict,n,'style','bar');

subplot(3,1,3)
imhistFB(inpict,n,'style','patch');

%% demonstrate bin alignment
clc; clf; clearvars

inpict = rand(500);
n = 5;

subplot(2,1,1)
imhistFB(inpict,n,'style','bar','binalignment','center'); % imhist()-style

subplot(2,1,2)
imhistFB(inpict,n,'style','bar','binalignment','edge');

%% demonstrate yscale styles
clc; clf; clearvars

inpict = imread('cameraman.tif');
n = 256;

subplot(2,1,1)
imhistFB(inpict,n,'yscale','tight'); % imhist()-style

subplot(2,1,2)
imhistFB(inpict,n,'yscale','full');

%% imhistFB() was never meant to support indexed-color images,
% but it still can do a better job than imhist() can.
clc; clf; clearvars

% this is a uint8 indexed-color image with 11 colored 
% blobs on a black background (12 colors)
[Xuint CT] = imread('sources/blobs/indexedblobs.png');

% this is a float-class copy of the same image
% offset by one, as is convention.
Xfloat = double(Xuint)+1;

% EXAMPLE 1: imhist()
% due to a bug, imhist() does not actually handle 
% integer-class indexed images correctly, so it needs to be float.
% while colorbar and histogram bins were misaligned for scaled images,
% they will be aligned for no apparent reason if a colortable is provided.
% the end bins appear as half-width as expected.
subplot(4,2,1)
imhist(Xuint,CT) % uint-class (wrong colorbar)
subplot(4,2,2)
imhist(Xfloat,CT) % float-class

% EXAMPLE 2: imhistFB() with 'center' alignment
% use the 'colortable' parameter to display an integer-class indexed image
% obviously, the only thing you'd need to do for a properly-offset 
% float-class indexed image is to shift 'range' by 1
subplot(4,2,3)
nct = size(CT,1);
imhistFB(Xuint,nct,'colortable',CT,'range',[0 nct-1]) % uint-class
subplot(4,2,4)
imhistFB(Xfloat,nct,'colortable',CT,'range',[1 nct]) % float-class

% EXAMPLE 3: imhistFB() with 'edge' alignment
% do the same thing, but use 'edge' alignment so that
% the colorbar segments all appear with uniform width.
subplot(4,2,5)
imhistFB(Xuint,nct,'colortable',CT,'range',[0 nct]-0.5,'binalignment','edge') % uint-class
subplot(4,2,6)
imhistFB(Xfloat,nct,'colortable',CT,'range',[0 nct]+0.5,'binalignment','edge') % float-class

% EXAMPLE 4: imhistFB() with 'center' alignment and setting xlim
% example 3 could also have been done with the same inputs as example 2
% and subsequent manipulation of the x-limits of both axes.
% this is what would need to be done for IPT imhist(),
% though remember that imhist()'s axes don't have linked xticks.
subplot(4,2,7)
imhistFB(Xuint,nct,'colortable',CT,'range',[0 nct-1]) % uint-class
subplot(4,2,8)
imhistFB(Xfloat,nct,'colortable',CT,'range',[1 nct]) % float-class
hax = findobj(gcf,'type','axes');
set(hax(4),'xlim',[0 nct]-0.5) % uint
set(hax(2),'xlim',[0 nct]+0.5) % float

% make sure we're seeing all the integer-value ticks for this short CT
% note that here and in example 4, i'm only updating the histogram axes
% imhistFB() axes (both the stripe and histogram) are linked on 'xlim' and 'xtick'
set(hax(4:4:12),'xtick',0:nct-1) % for any example using uint
set(hax(2:4:12),'xtick',1:nct) % for any example using float

% the imhist() axes are only linked on 'xlim', but not 'xtick', 
% so we need to update both axes explicitly
set(hax(15:16),'xtick',0:nct-1) % for any example using uint
set(hax(13:14),'xtick',1:nct) % for any example using float

% set up some labels
title('uint-class','parent',hax(16))
title('float-class','parent',hax(14))
ylabel('Example 1','parent',hax(16),'fontweight','bold')
ylabel('Example 2','parent',hax(12),'fontweight','bold')
ylabel('Example 3','parent',hax(8),'fontweight','bold')
ylabel('Example 4','parent',hax(4),'fontweight','bold')

%% cshist() demo
clc; clf; clearvars

%inpict = rand(500,500,3);
inpict = imread('peppers.png');

spc = 'lab';
style = 'bar';
extents = 'box';
yscale = 'tight'; 
nbins = 256;

counts = cshist(inpict,spc,'style',style, ...
			'extents',extents, ...
			'yscale',yscale, ...
			'nbins',nbins);

%% imcast() demos
clc; clf; clearvars

% the inputs
outclass = 'single';
inpict = imread('sources/std/circuit.tif.png'); % any class

% the problem with IPT tools is that the output class parameter
% is embedded in the function name like some sort of eval-bait
% so you have to do dumb shit like this if you want flexibility.
% this also only supports the six classes supported in IPT.
switch outclass
	case 'uint8'
		outpict = im2uint8(inpict);
	case 'double'
		outpict = im2double(inpict);
	case 'single'
		outpict = im2single(inpict);
	case 'uint16'
		outpict = im2uint16(inpict);
	case 'int16'
		outpict = im2int16(inpict);	
	case 'logical'
		% this is the behavior convention asserted in imcast()
		outpict = im2double(inpict) >= 0.5;
end

% just do it with MIMT imcast().
% this supports any regular numeric class.
op0 = imcast(inpict,outclass);

% they're the same
isequal(outpict,op0)

%% the rebuttal
clc; clf; clearvars
% one rebuttal is that we really don't need parametric conversions
% for a class-agnostic workflow (e.g. implementing class inheritance) 
% if we simply do blind recasting to float and we work with improperly-
% scaled float data.  besides, everything would be so much simpler and 
% faster if we avoid rescaling, right?

% the input
inpict = imread('sources/std/circuit.tif.png'); % any class

% convert to float and do something in variable-scale float
workingcopy = double(inpict);
workingcopy = workingcopy*0.70 + 0.15; % notice why this is wrong?

% complete the process by returning to the original class
outpict = cast(workingcopy,class(inpict));

% see why that doesn't work?  obviously this just shifts the problem from 
% the periphery of the process to the entire internal core of the code.
% we're only addressing the class, but not the data scale.  our main working 
% image does not have a consistent scale, so we need to change all of those 
% operations to be scale-agnostic.  we're making the design _less_ modular.
%
% there's no justification for promoting that as a general solution to this 
% sort of problem.  instead of trying to make all our code dynamically adapt 
% to the variable scale, it would clearly make more sense to simply rescale 
% the float copy to a consistent scale. if that working scale is unit-scale, 
% then there's no point avoiding im2double(). either way, we'd still need to 
% dynamically rescale again on the way out.
% 
% in effect, that would be reimplementing the core of imcast()'s fallback code -- 
% but only for a single case, and we would be proposing to reinvent this 
% wheel repeatedly every time it's needed ... 

%% so just use rescale().  it's concise!
clc; clf; clearvars
% ... oh, but it shouldn't be that big a deal!  you could get the ranges 
% from getrangefromclass() and throw that in rescale() and it would work 
% and it would still be all concise on one line!
%
% _no it wouldn't_.  given the maddening ugliness of rescale()'s syntax,
% it couldn't generally be one-lined.  aside from mere ugliness, 
% the correct transformation (for signed integer outputs) cannot be 
% performed with a single call to rescale(). considering that complication
% alone, there's no point even involving rescale().  if we're just writing 
% the basic arithmetic every time, then this whole proposal is no convenience.
% see imcast()'s internal notes.

% consider trying to cast and scale from unit-scale float to int16:

% inputs
inpict = linspace(0,1,11); % a simple float input which will cause problems
outclass = 'int16';

% the reference
ipict0 = im2int16(inpict); 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% from float to int16 using MIMT
ipict1 = imcast(inpict,outclass); 

% test
immse(ipict0,ipict1) % they're identical

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do the same thing, but insisting that it can simply
% be done using rescale() and maybe getrangefromclass().
% this will be spuriously off for certain inputs
% if the output class is signed integer.
% getrangefromclass() doesn't take a named class
% but it does return a nice convenient tuple
or = getrangefromclass(ones(1,1,outclass));
% but rescale() can't even take tuples, and scale parameters
% are formatted inconsistently and ordered backwards for extra ugliness.
ipict2 = rescale(inpict,or(1),or(2),'inputmin',0,'inputmax',1); 
% oh yeah, we still have to do this part.
ipict2 = cast(ipict2,outclass);

% test
immse(ipict0,ipict2) % error for signed outputs

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the stupid bullshit that you'd need to do
% to stabilize that last 1LSB for signed output if you 
% absolutely insist on using rescale().
if outclass(1) == 'u' % assuming it's char
	or = getrangefromclass(ones(1,1,outclass));
	ipict3 = rescale(inpict,or(1),or(2),'inputmin',0,'inputmax',1);
elseif outclass(1) == 'i'
	or = getrangefromclass(ones(1,1,['u' outclass]));
	ipict3 = rescale(inpict,or(1),or(2),'inputmin',0,'inputmax',1);
	ipict3 = round(ipict3) - ceil(or(2)/2);
else
	% explode, i guess.
end
ipict3 = cast(ipict3,outclass);

% test
immse(ipict0,ipict3) % now they match

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the degeneralized arithmetic for float to integer
% it's inflexible and deoptimized, but we already know that.
% still, it's no less flexible than using rescale(), 
% and it's simpler, more portable, and it's significantly faster.
% ... but why would you rewrite it repeatedly every time?
or = getrangefromclass(ones(1,1,outclass));
ipict4 = cast(round(inpict*diff(or)) + or(1),outclass);

% test
immse(ipict0,ipict4) % now they match

% TL;DR:
% integer-scale float workflows is a solution for people who think that "class agnostic" 
% means "presume everything is uint8 and that operations are never scale-dependent".
% its typical form involves sprinkling magic 255 literals everywhere.
%
% the solution is to rescale when recasting.  the tool to do that is imcast(),
% not rescale().  i have my opinions about rescale(). they start with "ugh."

%% demonstrate class inheritance using imcast()
clc; clf; clearvars

% convert an image without presuming its initial class
inpict = imread('sources/std/circuit.tif.png'); % any class
[workingcopy inclass] = imcast(inpict,'double'); % a known class

% do a bunch of operations in unit-scale floating point
workingcopy = workingcopy*0.70 + 0.15;

% recast output to match original image class
outpict = imcast(workingcopy,inclass);

% inpict and outpict can be concatenated, 
% since they will always have the same class
imshow2([inpict outpict],'invert')

%% explicit mode demo
clc; clf; clearvars
% note in all cases that the actual class 
% of the input tuple ('double') is ignored

% outpict will be [-524288 524287], class 'int32'
A = imcast([0 1023],'uint10','int20')

% outpict will be [0 4095], class 'uint16'
B = imcast([0 255],'uint8','uint12')

% outpict is the same. although the input is >>15, 
% output is clamped to uint12-scale
C = imcast([0 100],'uint4','uint12')

% outpict will be [0 0 1 1], class 'logical'
D = imcast([0 511 512 1023],'uint10','logical')

%% explicit mode quant styles
clc; clf; clearvars
% Note that the significance of the difference between the two methods 
% corresponds to the relative contribution of 1LSB in the output scale.

% downshift to a narrow scale for clarity
x = uint16(0:1023);
inclass = 'uint10';
outclass = 'uint4';

% ideal linear transformation between interval endpoints
ir = imclassrange(inclass);
or = imclassrange(outclass);
y0 = double(x)/(ir(2)/or(2));

% the two available methods:
% default IPT-style rescaling
% Y = round(X/((2^bitsin - 1)/(2^bitsout - 1)))
y1 = imcast(x,inclass,outclass);

% used for 48bpp+ non-harmonic rescaling
% Y = fix(X/2^(bitsin - bitsout))
y2 = imcast(x,inclass,outclass,'bitshift');

% compare the error between the integer approximations 
% and an ideal linear transformation
subplot(2,1,1)
y = [y2;y1];
labels = {'bitshift','default/auto'};
plot(x,y); hold on; plot(x,y0)
xlim(ir)
legend('string',labels,'location','northwest')

% the IPT method has a more uniformly distributed error, 
% with a smaller peak magnitude
subplot(2,1,2)
plot(x,bsxfun(@minus,double(y0),double(y)))
xlim(ir)
legend('string',labels)

%% a two-step non-harmonic downconversion workaround
clc; clf; clearvars
% In the absurdly unlikely case of a non-harmonic downconversion from 48bpp+
% to something narrower than 48bpp, consider the following two-step approximation 
% of the IPT-style conversion.  
%
% This sort of approach may be favorable compared to using an intermediate
% float conversion if both input and output classes are significantly wide.
% In either case, we can expect some rounding/aliasing, but in the float
% case, those imperfections will be distributed asymmetrically.
%
% In lieu of a 128b-equivalent wide arithmetic implementation, this
% may suffice to bridge the gaps I left in imcast()'s capabilities.

% a non-harmonic downconversion above 48b
% downshift to a narrow scale for clarity
x = linspace(0,1,1E6); % we can't afford a full ramp anyway
inclass = 'uint56'; % who would actually do this??
outclass = 'uint5'; % whyyy?

% ideal linear transformation between interval endpoints
x = imcast(x,'double',inclass); % stretch our fake data
ir = imclassrange(inclass);
or = imclassrange(outclass);
y0 = double(x)/(ir(2)/or(2));

% the default mode is bypassed in this case
y1 = imcast(x,inclass,outclass); % bypasses to 'bitshift' mode
y2 = imcast(x,inclass,outclass,'bitshift'); % also 'bitshift' mode

% approximate the IPT-style conversion in a 2-step process
% 1: bitshift to something safely within float precision
% 2: do arithmetic downconversion from there
[~,issi,~] = parseintclassname(inclass);
tempclass = buildintclassname(issi,48);
y3 = imcast(x,inclass,tempclass); % non-harmonic bitwise downscale
y3 = imcast(y3,tempclass,outclass); % IPT-style arithmetic downscale

% the peak contrast error is reduced at the cost
% of some extra aliasing
y = [y2;y1;y3];
labels = {'bitshift','default/auto','two step'};
plot(x,bsxfun(@minus,double(y0),double(y)))
xlim(ir)
legend('string',labels)

%% intervalct() demo
clc; clf; clearvars
% see also:
% https://www.mathworks.com/matlabcentral/answers/1891415-change-the-range-of-your-sections-in-your-colormap#answer_1148215
% https://www.mathworks.com/matlabcentral/answers/826660-unequal-custom-non-evenly-spaced-colorbar-intervals#answer_1464616
% https://www.mathworks.com/matlabcentral/answers/2033754-how-to-change-the-scale-of-color-bar-to-discrete#comment_2929291

% fake unit-scale data
[X Y] = meshgrid(linspace(0,0.5,500));
Z = X + Y;

% arbitrarily-spaced breakpoints
lvl = [0 0.1 0.2 0.25 exp(-1) 0.4 0.5 2/3 1/sqrt(2) 0.82 1];

% interval/category colors
CT0 = ccmap('althi',numel(lvl)-1);

% generate expanded color table & info
nmax = 1000; % let this be long
[CT cidx] = intervalct(lvl,CT0,nmax);

% plot everything
contourf(X,Y,Z,lvl)

% add colorbar with matching ticks
colormap(CT);
cb = colorbar;
cb.Ticks = lvl;
caxis(imrange(lvl));

%% wpread()/wpwrite() demo
clc; clf; clearvars

% get an image in the workspace
[inpict,~,alpha] = imread('sources/bluebars.png');
inpict = joinalpha(inpict,alpha); % RGBA

% write the image to a lossless WEBP
fname = 'test.webp';
wpwrite(inpict,fname)

% read the image back from disk
recovered = wpread(fname);

% do they match?
isequal(inpict,recovered)

% show it
imshow2(recovered,'invert')

%% 
clc; clf; clearvars

%% 
clc; clf; clearvars

%% 
clc; clf; clearvars

%% 
clc; clf; clearvars

%% 
clc; clf; clearvars

%% 
clc; clf; clearvars
































































