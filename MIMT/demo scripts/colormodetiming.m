clc; clf; clear variables

% requires R2016b or newer for local functions in scripts
% requires R2013b or newer for timeit()

% prepare inputs
bg = imread('peppers.png');
fg = fliplr(bg);

modenames = {'color hslyc','color hsvyc','color hsiyc', ...
	'color hsly','color hsvy','color hsiy', ...
	'color hsl','color hsv','color hsi', ...
	'color lchab','color lchsr','color hsyp'};
refidx = 4;

% time everything
nframes = numel(modenames);
extime = zeros(nframes,1);
for f = 1:nframes
	extime(f) = timeit(@() testA(fg,bg,modenames{f}));
end

% rearrange by color model?
if true
	idx = [1 4 7 2 5 8 3 6 9 10 11 12];
	modenames = modenames(idx);
	extime = extime(idx);
	refidx = 2;
end

% execution time & relative time (compared to legacy default)
[extime extime/extime(refidx)]

bar(extime/extime(refidx));
grid on
xticklabels(modenames)
set(gca,'xticklabelrotation',90)

% slow HSL
%     0.1995    1.4144
%     0.1411    1.0000
%     0.1158    0.8209

% fast HSL
%     0.1793    1.4970
%     0.1198    1.0000
%     0.0951    0.7939

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function testA(fg,bg,mn)
	butt = imblend(fg,bg,1,mn);
end



























