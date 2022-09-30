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
mk = imread('sources/standardmods/redpepmask.png');

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
mk = imread('sources/standardmods/redpepmask.png');

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












































































































