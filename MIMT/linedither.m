function mpict = linedither(inpict,varargin)
%   LINEDITHER(INPICT, {OPTIONS})
%       Quirky multilevel dither consisting of variable density line segments
%       As the purpose of this function is image degradation, accuracy is moot.
%
%   INPICT is a 2-D intensity image.  RGB images will be converted to grayscale.
%   Optional parameters may be specified via key-value pairs:
%       'levels' specifies the number of gray levels (default 16)
%       'length' is the maximum line length (default 8)
%           specifying 0 will allow arbitrarily long lines
%       'ramp' specifies variable line length behavior (default 'down')
%           'up' causes light regions to have longer lines than dark regions
%           'down' causes dark regions to have longer lines than light regions
%           'none' uses fixed maximum line length
%       'axis' specifies the axis in which lines are drawn
%           accepts 'horizontal' (default) or 'vertical'
%       'smoothrad' specifies the filter radius used for filtering masks (default 10)
%       'noiseamt' is used to inject noise into the level masking operations (default 0)
%       'pattern' specifies how lines should be arranged when LENGTH is set to 0
%           'regular' produces a regular pattern
%           'irregular' uses a randomized pattern (default)
%           this may also occur when LENGTH is not explicitly set to 0, depending on RAMP and LEVELS
%
%   CLASS SUPPORT:
%       inputs may be 'uint8','uint16','int16','single','double', or 'logical'
%       output class is logical
%
%   EXAMPLES:
%       Use defaults:
%       outpict=linedither(inpict);
% 
%       Create solid line dither
%       outpict=linedither(inpict,'levels',16,'len',0,'ramp','none', ...
%           'axis','h','radius',3,'noiseamt',0,'pattern','regular');
%
%       Create odd mix of dot and solid line dithering: 
%       outpict=linedither(inpict,'levels',16,'len',1,'ramp','up', ...
%           'axis','h','radius',3,'noiseamt',0,'pattern','regular');
%
%       Same as above, but using default PATTERN: 
%       outpict=linedither(inpict,'levels',16,'len',1,'ramp','up', ...
%           'axis','h','radius',3,'noiseamt',0,'pattern','irregular');
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/linedither.html
% See also: dither, noisedither, orddither, arborddither, zfdither

levels = 16;
len = 8;
ramp = 'down';
honly = 1;
vonly = 0;
smoothrad = 10;
randamt = 0;
regular = 0;

for k = 1:2:length(varargin)
    switch lower(varargin{k})
        case 'levels'
            levels = varargin{k+1};
        case {'len','length'}
            len = varargin{k+1};
        case 'ramp'
			ramp = varargin{k+1};
			if ~strismember(ramp,{'up','down','none'})
					error('LINEDITHER: unknown ramp direction %s',varargin{k+1})
			end
		case 'axis'
			waxis = varargin{k+1};
			switch lower(waxis)
				case {'horizontal','h'}
					honly = 1;
					vonly = 0;
				case {'vertical','v'}
					honly = 0;
					vonly = 1;
				otherwise
					error('LINEDITHER: unknown axis %s',varargin{k+1})
			end
		case {'smoothradius','radius'}
			smoothrad = varargin{k+1};
		case 'noiseamt'
			randamt = varargin{k+1};
		case 'pattern'
			wpattern = varargin{k+1};
			switch lower(wpattern)
				case 'regular'
					regular = 1;
				case {'irregular','random'}
					regular = 0;
				otherwise
					error('LINEDITHER: unknown pattern %s',varargin{k+1})
			end
        otherwise
            error('LINEDITHER: unknown input parameter name %s',varargin{k})
    end
end

inpict = imcast(inpict,'double');
if size(inpict,3) == 3
	gpict = mono(inpict,'y');
% 	mpict = false(size(inpict));
% 	for c = 1:3
% 		mpict(:,:,c) = linedither(inpict(:,:,c),varargin{:});
% 	end
% 	return;	
else
	gpict = inpict;
end
gpict = round(gpict*levels)/levels;
s = size(gpict);

m = zeros(size(gpict));
mpict = m;
for gl = 1:levels
	switch ramp
		case 'down'
			k = round(len*((1-gl/levels)+1/levels));
		case 'up'
			k = round(len*gl/levels);
		case 'none'
			k = len;
	end
	mr = (ones(s)*(1-randamt)+randamt*rand(s))*((gl-1)/(levels-1));
	if (mod(gl,2) || honly) && ~vonly
		if k == 0
			if regular
				mh = orddither(imresizeFB(mr,[s(1) 10]));
			else
				mh = zfdither(imresizeFB(mr,[s(1) 10]));
			end
			mh = imresizeFB(mh(:,5),s);
		else
			mh = imresizeFB(zfdither(imresizeFB(mr,[s(1) s(2)/k])),s,'nearest');
		end
	else
		if k == 0
			if regular
				mh = orddither(imresizeFB(mr,[10 s(2)]));
			else
				mh = zfdither(imresizeFB(mr,[10 s(2)]));
			end
			mh = imresizeFB(mh(5,:),s);
		else
			mh = imresizeFB(zfdither(imresizeFB(mr,[s(1)/k s(2)])),s,'nearest');
		end
	end
	
	m = logical((gpict >= (gl/levels)));
	
	if smoothrad > 0
		st = simnorm(fkgen('disk',smoothrad*2));
		m = morphops(m,st,'open');
	end
	
	mpict(m) = mh(m);
end

mpict = logical(mpict);

end

