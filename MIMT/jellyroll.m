function outpict = jellyroll(inpict,varargin)
%   JELLYROLL(INPICT, {OPTIONS})
%       Remap the columns of an image into a spiral with the same geometry as the source image.
%
%   INPICT is an I/IA/RGB/RGBA image of any standard image class
%   OPTIONS include the following keys and key-value pairs
%   'direction' specifies which (radial) direction the spiral progresses (default 'in')
%      Supported values are 'in' and 'out'.
%   'rotation' specifies which (angular) direction the spiral progresses (default 'ccw')
%      Rotation is with respect to the end specified by 'direction', not 'tailpos'.
%   'tailpos' specifies the outer corner on which the spiral starts/ends (default 'nw')
%      Supported values are 'nw', 'sw', 'se', and 'ne'.
%   'alternate' optionally changes the input column mapping behavior
%      Normally, the image data is read columnwise from top to bottom.  When 'alternate' is 
%      specified, the data is read columnwise with alternating direction.  This zig-zag 
%      path is intended to help preserve some degree of continuity in the vectorized image.
%   'reverse' can be used to undo a previous mapping.  So long as all the other options
%      are consistent with those which generated the working image, it should be unrolled.
%      
%   Output class is the same as input class
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/jellyroll.html
% See also: diagremap, imannrotate, continuize


alternate = false;
reverse = false;
direction = 'in';
rotation = 'ccw';
tailpos = 'nw';

k = 1;
while k <= numel(varargin)
    switch lower(varargin{k})
		case 'alternate'
			alternate = true;
			k = k+1;
		case 'reverse'
			reverse = true;
			k = k+1;
		case 'direction'
			if strismember(varargin{k+1},{'in','out'})
				direction = varargin{k+1};
			else
				error('JELLYROLL: unknown direction option %s',thisarg)
			end
			k = k+2;
		case 'rotation'
			if strismember(varargin{k+1},{'ccw','cw'})
				rotation = varargin{k+1};
			else
				error('JELLYROLL: unknown rotation option %s',thisarg)
			end
			k = k+2;
		case 'tailpos'
			if strismember(varargin{k+1},{'nw','sw','se','ne'})
				tailpos = varargin{k+1};
			else
				error('JELLYROLL: unknown tailpos option %s',thisarg)
			end
			k = k+2;
        otherwise
            error('JELLYROLL: unknown input parameter name %s',varargin{k})
    end
end

s = imsize(inpict);
npix = prod(s(1:2));
outpict = inpict;

swapax = (strcmp(direction,'out') && strcmp(rotation,'ccw')) || (strcmp(direction,'in') && strcmp(rotation,'cw'));

% generate asymmetric spiral page map
% this could be vastly simplified, but idc
if xor(strismember(tailpos,{'nw','se'}),swapax)
	map = zeros(s(1:2));
	secr = [s(1) s(2)]+1; % southeast corner
else
	map = zeros(fliplr(s(1:2)));
	secr = [s(2) s(1)]+1; % southeast corner
end
nwcr = 0; % northwest corner
ci = 0; % index counter
while true % run until we're out of indices
	nwcr = nwcr+1;
	secr = secr-1;

	% w side, moving south
	idxvec = nwcr:secr(1);
	repvec = ci+1:ci+numel(idxvec);  ci = repvec(end);
	map(idxvec,nwcr) = repvec;
	if ci >= npix; break; end
	
	% s side, moving east
	idxvec = nwcr+1:secr(2);
	repvec = ci+1:ci+numel(idxvec);  ci = repvec(end);
	map(secr(1),idxvec) = repvec;
	if ci >= npix; break; end
	
	% east side, moving north
	idxvec = secr(1)-1:-1:nwcr;
	repvec = ci+1:ci+numel(idxvec);  ci = repvec(end);
	map(idxvec,secr(2)) = repvec;
	if ci >= npix; break; end
	
	% n side, moving west
	idxvec = secr(2)-1:-1:nwcr+1;
	repvec = ci+1:ci+numel(idxvec);  ci = repvec(end);
	map(nwcr,idxvec) = repvec;
	if ci >= npix; break; end
end

if swapax
	map = rot90(flipud(map),-1);
end

switch tailpos
	case 'sw'
		map = rot90(map,1);
	case 'se'
		map = rot90(map,2);
	case 'ne'
		map = rot90(map,3);
end
smap = map(:);


% build stripe page map
lmap = reshape(1:npix,s(1),s(2));
if alternate
	lmap(:,2:2:end) = flipd(lmap(:,2:2:end),1);
end
lmap = lmap(:);

if strcmpi(direction,'out')
	lmap = flipd(lmap,1);
end


% transform the array
if ~reverse
	for c = 1:s(3)
		thispage = inpict(:,:,c);
		thispage = thispage(lmap);
		outpict(:,:,c) = reshape(thispage(smap),s(1),s(2));
	end
else
	smap(smap) = 1:npix;
	for c = 1:s(3)
		thispage = inpict(:,:,c);
		thispage = thispage(smap);
		outpict(:,:,c) = reshape(thispage(lmap),s(1),s(2));
	end
end


end % end main scope





























