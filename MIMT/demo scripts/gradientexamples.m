% gradient examples
% This file exploits CELL MODE operation and is meant to be run one section at a time.  
% Don't try running the whole file straight; it'll just clobber its own output.
% Pick a section to run, use ctrl-enter or click "Run Section" from the Editor toolbar

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
return;

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

%% replicate GIMP's "Skyline" gradient
s = [400 600 3];
colors = [0 0 0; 0.095 0.058 0.494; 0.113 0.067 0.566; 0.514 0.055 0.305; ...
    0.921 0.066 0.042; 0.955 0.266 0.024; 0.999 0.541 0.004; ...
    0.967 0.741 0.114; 0.937 0.924 0.213; 0 0 0; 0 0 0]*255;
breaks = [0 0.056 0.367 0.601 0.752 0.791 0.869 0.897 0.936 0.937 1];

outpict = lingrad(s,[0 0; 1 0],colors,breaks);

imshow(outpict)

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

%%  Replicate GIMP's "Deep Sea" gradient
s = [400 600 3];
colors = [0.000000 0.009040 0.166667; 0.089516 0.199522 0.3939395; ...
    0.179032 0.390004 0.621212; 0.179032 0.390004 0.621212; ...
    0.089516 0.6798505 0.7954545; 0.000000 0.969697 0.969697]*255;
breaks = [0.000000 0.580968 0.764608 0.764608 0.888147 1.000000];

outpict = radgrad(s,[0 0],1,flipud(colors),1-fliplr(breaks));

imshow(outpict)





