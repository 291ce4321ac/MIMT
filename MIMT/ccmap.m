function cset = ccmap(varargin)
%  CMAP = CCMAP({MAPNAME},{STEPS})
%   Custom colormap generator for MIMT docs processing
%
%  MAPNAME is one of the following:
%    'pastel' is a soft yellow-magenta-teal CT used for imblend() contour maps
%    'nrl' is an asymmetric cyan-blue-black CT used for imblend() NRL maps
%    'hsyp' is a circular hue sweep in HSYP, used to make short 'ColorOrder' CTs
%    'pwrap' is a closed version of 'pastel'
% 
% See also: makect, ctpath

% imshow(repmat(ctflop(ccmap('pastel',64)),[1 64 1]))

mapnamestrings = {'pastel','nrl','hsyp','pwrap'};
mapname = 'pastel';
steps = 64;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			if strismember(thisarg,mapnamestrings)
				mapname = thisarg;
			else
				error('CCMAP: unknown map name ''%s''',thisarg)
			end
		elseif isnumeric(thisarg) && isscalar(thisarg)
			steps = thisarg;
		else
			error('CCMAP: expected either char or scalar numeric arguments.  what is this?')
		end
	end
end

switch mapname
	case 'nrl'
		eh = [0 180];
		H = linspace(eh(1),eh(2),steps);
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		% this has a breakpoint (PWL)
		bpy = [0 0.7 1];
		esy = [0.2 0.9 0.9];
		Y = [linspace(esy(1),esy(2),ceil(steps*(bpy(2)-bpy(1)))) linspace(esy(2),esy(3),floor(steps*(bpy(3)-bpy(2))))];
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
	case 'pastel'
		eh = [0 270];
		H = linspace(eh(1),eh(2),steps);
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		ey = [0.8 0.2];
		Y = linspace(ey(1),ey(2),steps);
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
	case 'hsyp'
		H = linspace(0,360,steps+1);
		K = ones(size(H));

		cset = permute(hsy2rgb(cat(3,H,K*1.2,K*0.6),'native'),[2 3 1]);
		cset = cset(1:end-1,:);
				
	case 'pwrap'
		st = [2/3 1/3];
		eh = [0 270 360];
		H = linspace(eh(1),eh(2),ceil(steps*st(1)));
		H = [H linspace(eh(2),eh(3),floor(steps*st(2)))];
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		ey = [0.8 0.2];
		Y = linspace(ey(1),ey(2),ceil(steps*st(1)));
		Y = [Y linspace(ey(2),ey(1),floor(steps*st(2)))];
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
end


