function outpict = lingrad(s,points,colors,varargin)
%   LINGRAD(SIZE, POINTS, COLORS, {METHOD}, {BREAKPOINTS}, {OUTCLASS}, {COLORTYPE})
%       returns an image of specified size containing
%       the multipoint linear gradient specified.
%       gradient type is linear interpolated rgb
%   
%   SIZE is a vector specifying output image size
%   POINTS is a 2x2 matrix specifying gradient endpoints
%       [y0 x0; y1 x1] (normalized coordinates)
%   COLORS is an array specifying the colors at the endpoints
%       e.g. [0; 255] or [255 0 0; 0 0 255] depending on SIZE(3)
%       The white value depends on OUTCLASS 
%           255 for 'uint8', 65535 for 'uint16', 1 for float classes
%   METHOD specified how colors are interpolated between points
%       this helps avoid the need for multipoint gradients
%       the first six methods are listed in order of decreasing endslope
%       'invert' is the approximate inverse of the cosine function
%       'softinvert' is the approximate inverse of the softease function
%       'linear' for linear interpolation (default)
%       'softease' is a blend between linear and cosine
%       'cosine' for cosine interpolation
%       'ease' is a polynomial ease curve
%       'waves' is linear interpolation with a superimposed sinusoid
%           when specified, an additional parameter vector 
%           [amplitude numcycles] may also be specified (default [0.05 10]). 
%           'waves' method only available for two-point gradients
%   BREAKPOINTS optionally specify the location of the breakpoints
%       in a gradient with more than two colors.  By default, 
%       all breakpoints are distributed evenly from 0 to 1. 
%       If specified, numel(breakpoints) must be the same as the number
%       of colors specified. First and last breakpoints are always 0 and 1.
%       ex: [0 0.18 0.77 1]
%   OUTCLASS specifies the output image class (default 'uint8')
%       Supports 'uint8', 'uint16', 'single', and 'double'
%   COLORTYPE optionally specifies the color linearity (default 'srgb')
%       Supported inputs are 'srgb' and 'linrgb'
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/lingrad.html
% See also: radgrad



method = 'linear';
wparams = [0.05 10];
outclass = 'uint8';
colortype = 'srgb';

for v = 1:length(varargin)
    if isnumeric(varargin{v}) && numel(varargin{v}) > 2
        breaks = varargin{v}; 
	elseif ischar(varargin{v})
		thiskey = lower(varargin{v});
		if strismember(thiskey,{'invert','softinvert','linear','softease','cosine','ease','waves'})
			method = thiskey;
		elseif strismember(thiskey,{'uint8','uint16','single','double'})
			outclass = thiskey;
		elseif strismember(thiskey,{'srgb','linrgb'})
			colortype = thiskey;
		else
			error('LINGRAD: uknown key ''%s''\n',thiskey)
		end
	elseif isnumeric(varargin{v}) && numel(varargin{v}) == 2
        wparams = varargin{v}; 
    end
end

if ~exist('breaks','var')
    breaks = 0:1/(size(colors,1)-1):1;
end


if numel(breaks) ~= size(colors,1)
    error('LINGRAD: mismatched number of colors and breakpoints');
end

% enforce correspondence between color table range and image class
switch outclass
	case 'uint8'
		[mn mx] = imrange(colors);
		if mx > 255 || mn < 0
			error('LINGRAD: numeric range of COLORS is inappropriate for image class ''uint8''');
		elseif mx <= 1
			disp('LINGRAD: numeric range of COLORS is [0 1] for image class ''uint8'', was this intended?');
		end
	case 'uint16'
		[mn mx] = imrange(colors);
		if mx > 65535 || mn < 0
			error('LINGRAD: numeric range of COLORS is inappropriate for image class ''uint16''');
		elseif mx <= 1
			disp('LINGRAD: numeric range of COLORS is [0 1] for image class ''uint16'', was this intended?');
		end
	case {'single','double'}
		[mn mx] = imrange(colors);
		if mx > 65535 || mn < 0
			error('LINGRAD: numeric range of COLORS is inappropriate for floating point image class');
		elseif mx > 1.5 && mx <= 255
			colors = colors./255;
			disp('LINGRAD: numeric range of COLORS assumed to be [0 255]');
		elseif mx > 1.5 && mx <= 65535
			colors = colors./65535;	
			disp('LINGRAD: numeric range of COLORS assumed to be [0 65535]');
		end
end


s = [s ones(3-numel(s))];
[X Y] = meshgrid(1:s(2),1:s(1));
p1 = points(1,:).*s(1:2);
p2 = points(2,:).*s(1:2);

switch lower(colortype)
	case 'srgb'
		colors = imrescale(colors,outclass,'double');
	case 'linrgb'
		colors = rgb2linear(imrescale(colors,outclass,'double'));
	otherwise
		error('LINGRAD: supported values for COLORTYPE are ''srgb'' and ''linrgb''')
end

% simplified methods are used for two-point case
% this makes everything faster in the most common use-case
if  size(colors,1) == 2
    dx = p2(2)-p1(2);
    dy = p2(1)-p1(1);
    c1 = dx*p1(2)+dy*p1(1);
    c2 = dx*p2(2)+dy*p2(1);
    
    C = dx*X+dy*Y;
    % normalize first
    C = (C-c1)/(c2-c1);
    C(C <= 0) = 0;
    C(C >= 1) = 1;
    
    switch lower(method)
        case 'invert'
            C = 2*C-0.5*(1-cos(C*pi));
        case 'softinvert'
            C = 2*C-(0.5*(1-cos(C*pi))+C)/2;
        case 'softease'
            C = (0.5*(1-cos(C*pi))+C)/2;
        case 'cosine'
            C = 0.5*(1-cos(C*pi));
        case 'ease'
            C = 6*C.^5-15*C.^4+10*C.^3;
        case 'waves'
            aw = wparams(1);
            nw = wparams(2);
            C = (1-2*aw)*C+aw*(1-cos(C*pi*(2*nw+1)));
    end
    
    outpict = zeros(s,'double');
    for c = 1:1:s(3)
        wpict = (colors(1,c)*(1-C) + colors(2,c)*C);
        outpict(:,:,c) = wpict;
    end
else
    dx = p2(2)-p1(2);
    dy = p2(1)-p1(1);

    cv = dx*p1(2)+dy*p1(1);
    cend = dx*p2(2)+dy*p2(1);
    for b = 2:1:numel(breaks)-1
        cv = [cv (cend-cv(1))*breaks(b)+cv(1)];
    end
    cv = [cv cend];
    
    C = dx*X+dy*Y;
    % normalize first
    C = (C-cv(1))/(cv(end)-cv(1));
    C(C <= 0) = 0;
    C(C >= 1) = 1;
    
    switch lower(method)
        case 'invert'
            C = 2*C-0.5*(1-cos(C*pi));
        case 'softinvert'
            C = 2*C-(0.5*(1-cos(C*pi))+C)/2;
        case 'softease'
            C = (0.5*(1-cos(C*pi))+C)/2;
        case 'cosine'
            C = 0.5*(1-cos(C*pi));
        case 'ease'
            C = 6*C.^5-15*C.^4+10*C.^3;
    end
    
    outpict = zeros(s,'double');
    for c = 1:1:s(3)
        wpict = zeros(s(1:2),'double');
        wpict(C <= 0) = colors(1,c); % breaks(1) == 0
        for b = 2:1:numel(breaks)
            % mask by breakpoints once normalized
            Cm = C > breaks(b-1) & C < breaks(b); 
            wpict(Cm) = (colors(b-1,c)*(breaks(b)-C(Cm))+colors(b,c)*(C(Cm)-breaks(b-1))) ...
                /(breaks(b)-breaks(b-1));
            wpict(C == breaks(b)) = colors(b,c);
        end
        wpict(C >= 1) = colors(end,c); % breaks(end) == 1
        outpict(:,:,c) = wpict;
    end
end

if strcmpi(colortype,'linrgb')
	outpict = linear2rgb(outpict);
end
outpict = imcast(outpict,outclass);

return

























