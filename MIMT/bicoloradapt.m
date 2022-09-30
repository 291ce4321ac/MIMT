function outpict = bicoloradapt(inpict,missingch)
% BICOLORADAPT(INPICT, MISSINGCHANNEL)
%   Emulates the effect of long-term use of a crt monitor with
%   a missing cathode amplifier, where sensory adaptation tends to
%   relate the secondary color as a new white point.  Also includes
%   background glow from the presence of a floating cathode.
%
%   INPICT is an RGB image of any standard image class
%   MISSINGCHANNEL is the channel which is missing (1, 2, or 3)
%   can also accept strings 'r', 'g', or 'b'
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/bicoloradapt.html
% See also: lcdemu

% consider this as a questionable heuristic based on observation
% comparing the failed crt to a dumpster lcd with absurdly bad gamma
% using a light-on-dark color scheme and operating in a dark environment
% this is based on my own eyes and a particular circuit failure
% i have no reason to expect this is universal!
% assume this work has no productive technical use

% since the glow is spatially related to the physical screen extents
% it doesn't really make much sense to apply this to an image that's not of appropriate geometry
% and i guess it'd really have to be 4:3

if size(inpict,3) ~= 3
	error('BICOLORADAPT: input image must have 3 channels (RGB)')
end

% output type is inherited from input
try
	[inpict inclass] = imcast(inpict,'double');
catch b
	error('BICOLORADAPT: unsupported image class')
end

if isstr(missingch)
	switch lower(missingch)
		case 'r'
			missingch = 1;
		case 'g'
			missingch = 2;
		case 'b'
			missingch = 3;
		otherwise
			error('BICOLORADAPT: invalid string input for MISSINGCHANNEL')
	end
end
if ~ismember(missingch,[1 2 3])
	error('BICOLORADAPT: invalid numeric input for MISSINGCHANNEL')
end

chs = [1 2 3];
remainingchs = chs(chs ~= missingch);
s = size(inpict);

% amount of missing color perceived via adaptation 
switch missingch
	case 1
		adaptation = 0.4; 
	case 2
		adaptation = 0.5;
	case 3
		adaptation = 0.3;
end

glowamt = 0.08;
adaptation = adaptation - glowamt;

% get rid of input and adapt for hue
outpict = inpict;
outpict(:,:,missingch) = adaptation*((outpict(:,:,remainingchs(1)) + outpict(:,:,remainingchs(2)))/2);

% correct for effective brightness
cpictin = inpict;
cpictin(:,:,missingch) = 0;
cpictin = rgb2lch(cpictin);

cpictout = rgb2lch(outpict);
cpictout(:,:,3) = cpictin(:,:,3);
outpict = lch2rgb(cpictout);

% glow following horizontal retrace 
py = [1 1 0.8 0.6 0.5 0.4]*glowamt;
px = [0 0.2 0.24 0.3 0.35 1];
gprofile = interp1(px*s(2),py,1:s(2));
hglow = repmat(gprofile,[s(1) 1 1]);
outpict(:,:,missingch) = hglow+outpict(:,:,missingch);

% glow during vertical retrace
nl = 15;	% number of rows
rt = 0.8; % duty cycle of forward sweep
fint = 0.075; % intensity of forward sweep
x = [1 s(2)];
yf = [rt*s(1)/nl 1];
yr = [s(1)/nl rt*s(1)/nl];
vglow = zeros(s(1:2));
for l = 1:nl
	vglow = vglow+fint*xwline(s(1:2),x,round(yf+(l-1)*s(1)/nl));
	vglow = vglow+(fint*(1-rt)/rt)*xwline(s(1:2),fliplr(x),round(yr+(l-1)*s(1)/nl));
end

%imshow2(vglow,'invert')
outpict(:,:,missingch) = vglow+outpict(:,:,missingch);

outpict = imcast(outpict,inclass);














