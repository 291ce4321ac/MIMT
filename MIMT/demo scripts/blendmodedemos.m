% BLEND MODE DEMOS
% depending on your filesystem, your pwd and where you stick this script, 
% you may need to change the path strings used for input/output.

% some of these may be configured for viewing on an inverted display
% if something looks inverted, just check the call to imshow() or imshow2()

% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

%% color blend modes demo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%huemask=lingrad(s,[0 0; 0 1],[0 0 0; 1 1 1]*255);
%fg=imblend(huemask,fg,1,'permute y>h',0.5);

A = imblend(fg,bg,1,'color');
B = imblend(fg,bg,1,'color lchab');
C = imblend(fg,bg,1,'color lchsr');
D = imblend(fg,bg,1,'color hsyp');
E = imblend(fg,bg,1,'color hsl');

Y0 = double(mono(bg,'y'));
L0 = double(mono(bg,'llch'));
a = uint8((abs(Y0-double(mono(A,'y')))+abs(L0-double(mono(A,'llch'))))/2);
b = uint8((abs(Y0-double(mono(B,'y')))+abs(L0-double(mono(B,'llch'))))/2);
c = uint8((abs(Y0-double(mono(C,'y')))+abs(L0-double(mono(C,'llch'))))/2);
d = uint8((abs(Y0-double(mono(D,'y')))+abs(L0-double(mono(D,'llch'))))/2);
e = uint8((abs(Y0-double(mono(D,'y')))+abs(L0-double(mono(D,'llch'))))/2);

limits = stretchlimFB(cat(1,a,b,c,d,e));
error1 = repmat(imadjustFB(cat(1,a,b,c,d,e),limits),[1 1 3]);
color1 = cat(1,A,B,C,D,E);
group1 = cat(2,color1,error1);

imshow2(group1,'invert','tools')
%imwrite(fg,'examples/imblendex6.jpg','jpeg','Quality',90);
%imwrite(group1,'examples/imblendex7.jpg','jpeg','Quality',90);

sa = sum(sum(a))
sb = sum(sum(b))
sc = sum(sum(c))
sd = sum(sum(d))
se = sum(sum(e))

return;

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












