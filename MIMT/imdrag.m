function outpict = imdrag(inpict,varargin)
%   IMDRAG(INPICT, ARGS)
%       Select random vector segments within an image and replicate them perpendicular 
%       to their length. Blend replicated data with the original image and repeat the process, 
%       creating a smearing effect depending on blend parameters.  Suited to relational
%       blend modes such as 'lightenrgb','darkenrgb','lighteny','darkeny','near', and 'far'.
%       Hybrid glow/shadow modes and other modes with a FG=BG NRL may also be useful.
%       Also consider 'normal' mode for simple overlays, or dithers via 'dissolve' compositions.
%       
%   INPICT is an image (I/IA or RGB/RGBA)
%   ARGUMENTS include:
%       'direction' specifies the direction which samples should be dragged
%           Values are 'north', 'south', 'east', 'west', 'random', and 'sequential'
%           Default is 'sequential'
%       'width' is the length of the sample vector (default [0.005 0.02])
%           May be specified as a scalar or a 2-element vector [lowerbound upperbound].
%           If specified as a noninteger <1, values are interpreted as % of image diagonal.
%           If specified as an integer >=1, values are interpreted as absolute size in pixels. 
%           Mixed vectors are accepted. (e.g. [0.01 50])
%       'distance' is the distance the sample vector is dragged (default [0.02 0.1])
%           May be specified as a scalar or a 2-element vector [lowerbound upperbound].
%           If specified as a noninteger <1, values are interpreted as % of image diagonal.
%           If specified as an integer >=1, values are interpreted as absolute size in pixels. 
%           Mixed vectors are accepted. (e.g. [0.01 50])
%       'nframes' is the number of iterations (default 12)
%       'ndrags' is the number of sampled regions per iteration (default 100)
%   The following arguments are simply passed to IMBLEND (see IMBLEND)
%       'blendmode' (default 'lightenrgb')
%       'opacity' (default 0.8)
%       'amount' (default 1)
%       'compmode' (default 'gimp')
%       'camount' (default 1)
%
%   EXAMPLES:
%       outpict=imdrag(inpict);
%
%       outpict=imdrag(inpict,'direction','south', ...
%	        'nframes',4, 'ndrags',100, ...
%	        'width',[10 50], 'distance',[50 200], ...
%	        'bmode','near','opacity',0.9,'amount',0.1);
%
%   CLASS SUPPORT:
%       inputs may be 'uint8','uint16','int16','single','double', or 'logical'
%       return class matches INPICT class 
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imdrag.html
% See also: IMBLEND

direction = 'sequential';
nframes = 12;
ndragsperframe = 100;
linerange = [0.005 0.02];
dragrange = [0.02 0.1];

bmode = 'lightenrgb'; 
opacity = 0.8;
amount = 1;
cmode = 'gimp';
camount = 1;

for k = 1:2:length(varargin);
    switch lower(varargin{k})
        case {'bmode','blendmode'}
            bmode = varargin{k+1};
        case 'opacity'
            opacity = varargin{k+1};
        case 'amount'
            amount = varargin{k+1};
		case {'cmode','compmode'}
			cmode = varargin{k+1};
		case 'camount'
			camount = varargin{k+1};
		case 'nframes' 
			nframes = round(varargin{k+1});
        case 'ndrags'
            ndragsperframe = round(varargin{k+1});
        case 'width'
            linerange = varargin{k+1};
			if length(linerange) == 1
				linerange = max([1 1]*linerange,0);
			end
        case 'distance'
            dragrange = varargin{k+1};
			if length(dragrange) == 1
				dragrange = max([1 1]*dragrange,0);
			end
		case 'direction'
            direction = varargin{k+1};
        otherwise
            error('IMDRAG: unknown input parameter name %s',varargin{k})
    end
end

dirs = {'north','south','east','west','n','s','e','w','rand','seq','random','sequential'};
if ~strismember(direction,dirs)
	error('IMDRAG: unknown value for DIRECTION')
end

try
	[inpict inclass] = imcast(inpict,'double');
catch b
	error('IMDRAG: Unsupported image class for INPICT')
end

s = size(inpict);
% convert from normalized values if needed
if any(linerange < 1)
	linerange(linerange < 1) = round(linerange(linerange < 1)*sqrt(s(1)^2+s(2)^2));
end
if any(dragrange < 1)
	dragrange(dragrange < 1) = round(dragrange(dragrange < 1)*sqrt(s(1)^2+s(2)^2));
end

outpict = inpict;
% will this support IA/RGBA?
if mod(size(outpict,3),2) == 1
	outpict = cat(3,outpict,ones(s(1:2),'double'));
end
overlay = zeros([s(1:2) size(outpict,3)]);

dir = 0;
for f = 1:nframes
	switch direction
		case {'sequential','seq'}
			genoverlay(dirs{dir+1})
			dir = mod(dir+1,4);
		case {'north','south','east','west','n','s','e','w'}
			genoverlay(direction)
		case {'random','rand'}
			dir = round(rand()*3+1);
			genoverlay(dirs{dir})
	end
			
	outpict = imblend(overlay,outpict,opacity,bmode,amount,cmode,camount);
		
end

outpict = imcast(outpict,inclass);

% inelegant code replication, buuuuuuuut fewer conditionals in the short loops
	function genoverlay(grav)
		switch grav
			case {'north','n'}
				for d = 1:ndragsperframe
					hpos = round(s(2)*rand());
					vpos = round(s(1)*rand());
					hw = round(linerange(1)+(linerange(2)-linerange(1))*rand());
					vw = round(dragrange(1)+(dragrange(2)-dragrange(1))*rand());
					hpos = min(max(hpos-[hw 0],1),s(2));
					vpos = min(max(vpos-[vw 0],1),s(1));
					sample = repmat(outpict(vpos(2),hpos(1):hpos(2),:),[vpos(2)-vpos(1)+1 1 1]);
					overlay(vpos(1):vpos(2),hpos(1):hpos(2),1:size(sample,3)) = sample;
				end
				
			case {'south','s'}
				for d = 1:ndragsperframe
					hpos = round(s(2)*rand());
					vpos = round(s(1)*rand());
					hw = round(linerange(1)+(linerange(2)-linerange(1))*rand());
					vw = round(dragrange(1)+(dragrange(2)-dragrange(1))*rand());
					hpos = min(max([0 hw]+hpos,1),s(2));
					vpos = min(max([0 vw]+vpos,1),s(1));
					sample = repmat(outpict(vpos(1),hpos(1):hpos(2),:),[vpos(2)-vpos(1)+1 1 1]);
					overlay(vpos(1):vpos(2),hpos(1):hpos(2),1:size(sample,3)) = sample;
				end
				
			case {'east','e'}
				for d = 1:ndragsperframe
					hpos = round(s(2)*rand());
					vpos = round(s(1)*rand());
					hw = round(dragrange(1)+(dragrange(2)-dragrange(1))*rand());
					vw = round(linerange(1)+(linerange(2)-linerange(1))*rand());
					hpos = min(max([0 hw]+hpos,1),s(2));
					vpos = min(max([0 vw]+vpos,1),s(1));
					sample = repmat(outpict(vpos(1):vpos(2),hpos(1),:),[1 hpos(2)-hpos(1)+1 1]);
					overlay(vpos(1):vpos(2),hpos(1):hpos(2),1:size(sample,3)) = sample;
				end

			case {'west','w'}
				for d = 1:ndragsperframe
					hpos = round(s(2)*rand());
					vpos = round(s(1)*rand());
					hw = round(dragrange(1)+(dragrange(2)-dragrange(1))*rand());
					vw = round(linerange(1)+(linerange(2)-linerange(1))*rand());
					hpos = min(max(hpos-[hw 0],1),s(2));
					vpos = min(max(vpos-[vw 0],1),s(1));
					sample = repmat(outpict(vpos(1):vpos(2),hpos(2),:),[1 hpos(2)-hpos(1)+1 1]);
					overlay(vpos(1):vpos(2),hpos(1):hpos(2),1:size(sample,3)) = sample;
				end
		end
	end
end












