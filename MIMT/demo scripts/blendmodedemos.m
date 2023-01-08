% BLEND MODE DEMOS
% depending on your filesystem, your pwd and where you stick this script, 
% you may need to change the path strings used for input/output.

% some of these may be configured for viewing on an inverted display
% if something looks inverted, just check the call to imshow() or imshow2()

% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

return; % this is just here to prevent the file from being run in whole

%% old color blend modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

% foreground are saturated primary-secondary colors (and lower-sat copies)
sz = [200 100 3];
H = repmat(linspace(0,360,sz(2)),[sz(1) 3]);
S = reshape(repmat(ctflop([1 0.5 0.25]),sz(1:2)),sz(1),[]);
L = 0.5*ones(sz(1),sz(2)*3);
%S = ones(sz(1),sz(2)*3);
%L = reshape(repmat(ctflop([0.75 0.5 0.25]),sz(1:2)),sz(1),[]);

FG = hsl2rgb(cat(3,H,S,L));

% background is gray
Y = repmat(linspace(1,0,sz(1)).',[1 sz(2)*3]);

%imshow2(FG,'invert')

modenames = {'color hslyc','color hsvyc','color hsiyc', ...
	'color hsly','color hsvy','color hsiy', ...
	'color hsl','color hsv','color hsi', ...
	'color lchab','color lchsr','color hsyp'};

nframes = numel(modenames);
imstack = cell(nframes,1);
Yerror = zeros(nframes,1);
LSerror = zeros(nframes,1);
for f = 1:nframes
	imstack{f} = imblend(FG,Y,1,modenames{f});
	Yerror(f) = imerror(mono(imstack{f},'y'),Y);
	LSerror(f) = imerror(mono(imstack{f},'llch'),Y);
end
imstack = imstacker(imstack,'padding',0);
outpict = imtile(imstack,[4 3]);
%outpict = mono(outpict,'y');

imshow2(outpict,'invert')

% error in retaining [Y(BT601) L*]
[Yerror LSerror]

%% old color blend modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');

s = size(bg);
hx = 0:360/s(2):(360-360/s(2));
hy = 0:180/s(1):(180-180/s(1));
[Hx Hy] = meshgrid(hx,hy);
S = ones(size(Hx))*0.8;
Y = ones(size(Hx))*0.5;
fg1 = hsy2rgb(cat(3,mod(Hx+Hy,360),S,Y),'pastel');
%fg1=lingrad(s,[0 0; 1 0],[1 1 0; 1 0 0]*255);
fg2 = flipd(fg1,1);
mask = eoline(ones(s(1:2)),2,[20 40]);
fg = replacepixels(fg1,fg2,mask);


modenames = {'color hslyc','color hsvyc','color hsiyc', ...
	'color hsly','color hsvy','color hsiy', ...
	'color hsl','color hsv','color hsi', ...
	'color lchab','color lchsr','color hsyp'};

nframes = numel(modenames);
imstack = cell(nframes,1);
errstack = cell(nframes,1);
Yerror = zeros(nframes,1);
LSerror = zeros(nframes,1);
Y0 = double(mono(bg,'y'));
L0 = double(mono(bg,'llch'));
for f = 1:nframes
	imstack{f} = imblend(fg,bg,1,modenames{f});
	errstack{f} = uint8((abs(Y0-double(mono(imstack{f},'y')))+abs(L0-double(mono(imstack{f},'llch'))))/2);
	Yerror(f) = imerror(mono(imstack{f},'y'),uint8(Y0));
	LSerror(f) = imerror(mono(imstack{f},'llch'),uint8(L0));
end
outpict = imstacker(imstack,'dim',1,'padding',0);
errpict = imstacker(errstack,'dim',1,'padding',0);

limits = stretchlimFB(errpict);
error1 = repmat(imadjustFB(errpict,limits),[1 1 3]);
group1 = cat(2,outpict,error1);

% i'm going to just retile this clumsily because it's so long
group1 = imtile(imdetile(group1,[4 1]),[1 4]);

imshow2(group1,'invert')
%imwrite(fg,'examples/imblendex6.jpg','jpeg','Quality',90);
%imwrite(group1,'examples/imblendex7.jpg','jpeg','Quality',90);

% error in retaining [Y(BT601) L*]
[Yerror LSerror]

%% contrast & light modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');
bg = imresizeFB(bg,0.5);

s = size(bg);
fg1 = lingrad(s,[0 0; 1 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 0.8 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0.2 0],[0 0 0; 1 1 1]*255);
fg1 = imblend(sgrad,fg1,1,'transfer v_hsv>s_hsv');
fg = imblend(vgrad,fg1,1,'transfer v_hsv>v_hsv');

A = imblend(fg,bg,1,'softlight');
B = imblend(fg,bg,1,'overlay');
C = imblend(fg,bg,1,'easylight');
D = imblend(fg,bg,1,'flatlight');

E = imblend(fg,bg,1,'hardlight');
F = imblend(fg,bg,1,'vividlight');
G = imblend(fg,bg,1,'pinlight');
H = imblend(fg,bg,1,'hardmix');

L = cat(1,A,B,C,D);
R = cat(1,E,F,G,H);
group = cat(2,L,R);


imshow2(group,'invert','tools')

%% contrast modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');

s = size(bg);
fg1 = lingrad(s,[0 0; 1 1],([0 0 0; 1 1 1]+2)*255/4);
fg2 = flipd(fg1,1);
mask = eoline(ones(s(1:2)),2,[20 40]);
fg = replacepixels(fg1,fg2,mask);

A = imblend(fg,bg,1,'scale add');
B = imblend(fg,bg,1,'scale mult');
C = imblend(fg,bg,1,'contrast');

group = cat(1,A,B,C);

imshow2(group,'invert','tools')
%imwrite(fg,'examples/imblendex10.jpg','jpeg','Quality',90);
%imwrite(group,'examples/imblendex11.jpg','jpeg','Quality',90);

%% hue & saturation modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');

s = size(bg);
fg1 = lingrad(s,[0 0; 1 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 1 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0 0],[0 0 0; 1 1 1]*255);
fg1 = imblend(sgrad,fg1,1,'transfer v_hsv>s_hsv');
fg1 = imblend(vgrad,fg1,1,'transfer v_hsv>v_hsv');
fg2 = flipd(fg1,1);
mask = eoline(ones(s(1:2)),2,[20 40]);
fg = replacepixels(fg1,fg2,mask);

A = imblend(fg,bg,1,'transfer hhsv>hhsv');
B = imblend(fg,bg,1,'transfer hhsi>hhsi');
C = imblend(fg,bg,1,'transfer hlch>hlch');
D = imblend(fg,bg,1,'transfer hhusl>hhusl');

E = imblend(fg,bg,1,'transfer shsv>shsv');
F = imblend(fg,bg,1,'transfer shsi>shsi');
G = imblend(fg,bg,1,'transfer clch>clch');
H = imblend(fg,bg,1,'transfer shusl>shusl');

group1 = cat(1,cat(2,A,B),cat(2,C,D));
group2 = cat(1,cat(2,E,F),cat(2,G,H));

imshow2(group1,'invert','tools')
%imwrite(fg,'examples/imblendex12.jpg','jpeg','Quality',90);
%imwrite(group1,'examples/imblendex13.jpg','jpeg','Quality',90);
%imwrite(group2,'examples/imblendex14.jpg','jpeg','Quality',90);

%% lighten & darken modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');

s = size(bg);
fg1 = lingrad(s,[0 0; 1 1],[1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0]*255);
sgrad = lingrad(s,[0 0; 1 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0 0],[0 0 0; 1 1 1]*255);
fg1 = imblend(sgrad,fg1,1,'transfer v_hsv>s_hsv');
fg = imblend(vgrad,fg1,1,'transfer v_hsv>v_hsv');

A = imblend(fg,bg,1,'lighten rgb');
B = imblend(fg,bg,1,'lighten y');
C = imblend(fg,bg,1,'darken rgb');
D = imblend(fg,bg,1,'darken y');

group = cat(1,cat(2,A,B),cat(2,C,D));

imshow2(group,'invert','tools')
%imwrite(fg,'examples/imblendex15.jpg','jpeg','Quality',90);
%imwrite(group,'examples/imblendex16.jpg','jpeg','Quality',90);

%% dodge & burn modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

bg = imread('sources/table.jpg');
bg = imresizeFB(bg,0.5);

s = size(bg);
fg1 = lingrad(s,[0 0; 1 1],[0 0 0; 1 1 1]*255,'ease');
sgrad = lingrad(s,[0 0; 1 0],[0 0 0; 1 1 1]*255);
vgrad = lingrad(s,[1 0; 0 0],[0 0 0; 1 1 1]*255);
fg1 = imblend(sgrad,fg1,1,'transfer v_hsv>s_hsv');
fg = imblend(vgrad,fg1,1,'transfer v_hsv>v_hsv');

A = imblend(fg,bg,1,'colordodge');
B = imblend(fg,bg,1,'lineardodge');
C = imblend(fg,bg,1,'easydodge');
D = imblend(fg,bg,1,'colorburn');
E = imblend(fg,bg,1,'linearburn');
F = imblend(fg,bg,1,'easyburn');

group = cat(2,cat(1,A,B,C),cat(1,D,E,F));

imshow2(group,'invert','tools')

%% compositing demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; clf

[fg,~,fga] = imread('sources/bluebars.png');
[bg,~,bga] = imread('sources/redbars.png');
fg = cat(3,fg,fga);
bg = cat(3,bg,bga);

svgmult = imblend(fg,bg,1,'multiply',1,'srcover');
gimpmult = imblend(fg,bg,1,'multiply',1,'gimp');

group = cat(1,svgmult,gimpmult);

imshow2(group,'invert','tools')
%imwrite(group(:,:,1:3),'examples/imblendex17.png','alpha',group(:,:,4));












