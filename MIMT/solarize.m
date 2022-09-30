function outpict = solarize(inpict,varargin)
%  OUTPICT = SOLARIZE(INPICT,{OPTIONS})
%    Apply a solarization-like effect to an image.
%
%  INPICT is an image of any standard image class.  Multichannel and multiframe 
%    images are supported.
%  OPTIONS include the following keys and key-value pairs:
%    'default' explicitly specifies the use of the default transfer function curve.
%       The default curve is an asymmetric smooth curve based merely on preference:
%       in = [0 0.15 0.60 0.94 1]; 
%       out = [0 0.08 0.80 0.08 0];
%    'vee' specifies the use of a basic symmetric inverted-vee curve like many 
%       solarization filters use (e.g. GIMP).  This is normally a piecewise-linear
%       curve, unless the 'interpmode' option is set explicitly after this key is set.
%    'in' and 'out' can be used to optionally specify a custom curve
%       These keys are to be followed by a vector containing values between [0 1]
%       Obviously, both x and y vectors must be the same length.
%    'interpmode' optionally specifies the type of interpolation (default 'pchip')
%       Supported values are any method string supported by interp1() in your
%       currently installed version.
%
%  Output class is inherited from input
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/solarize.html
%  See also: imcurves, imlnc, tonemap


% default curve generation
lv = [0 0]; % [blacklevel whitelevel]
mp = [0.6 0.8]; % midpoint
% margin points creating tail curvature relative to endpoint, midpoint positions
mgl = [0.25 0.1]; % LH margin
mgr = [0.15 0.1]; % RH margin
xx = [0 mgl(1)*(mp(1)) mp(1) 1-mgr(1)*(1-mp(1)) 1];
yy = [lv(1) lv(1)+mgl(2)*(mp(2)-lv(1)) mp(2) lv(2)+mgr(2)*(mp(2)-lv(2)) lv(2)];

interpmode = 'pchip';

if numel(varargin)>0
	k = 1;
	while k <= numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'default'
				% NOP
				k = k+1;
			case 'vee'
				xx = [0 0.5 1];
				yy = [0 1 0];
				interpmode = 'linear';
				k = k+1;
			case 'in'
				xx = varargin{k+1};
				if ~isnumeric(xx)
					error('SOLARIZE: expected IN to be numeric')
				end
				k = k+2;
			case 'out'
				yy = varargin{k+1};
				if ~isnumeric(yy)
					error('SOLARIZE: expected OUT to be numeric')
				end
				k = k+2;
			case 'interpmode'
				interpmode = varargin{k+1};
				k = k+2;
			otherwise
				error('SOLARIZE: unknown option %s',thisarg)
		end
	end
end

if numel(xx) ~= numel(yy)
	error('SOLARIZE: IN and OUT vectors are not the same length')
end

outpict = imcurves(inpict,xx,yy,interpmode);


