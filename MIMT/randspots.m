function outpict = randspots(s,numspots,spotbounds,spotopacity,shape,fill)
%   RANDSPOTS(SIZE, NUMSPOTS, SPOTBOUNDS, SPOTOPACITY, SHAPE, {FILL})
%       returns an image littered with spots of randomly selected
%       location, size, and opacity
%
%   SIZE is a vector specifying the output image size
%       may be 2-D, 3-D, or 4-D
%   NUMSPOTS specifies the number of spots to generate
%   SPOTBOUNDS is a 2-element vector specifying the range of sizes
%       which each spot may take in pixels [minsize maxsize]
%   SPOTOPACITY is a 2-element vector specifying the minimum and maximum
%       opacity allowed for each spot
%   SHAPE specifies the shape of the spots
%       'circle'
%       'rectangle'
%       'square'
%   FILL specifies to what degree the spots are filled
%       specified as a 2-element vector defining the range of desired fill
%       default is [1 1] for 100% fill
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/randspots.html
% See also: randlines perlin perlin3

if nargin == 5
	fill = [1 1];
end

filled = all(fill == 1);

spotbounds = round(spotbounds/2);
s = [s ones([1 4-numel(s)])];
outpict = zeros(s,'uint8');

switch lower(shape)
	case 'circle'
		for f = 1:1:s(4)
			wpict = zeros([s(1:2)+spotbounds(2)*2 s(3)],'uint8');
			for n = 1:1:numspots
				% it's actually faster to keep resizing the spot arrays
				% since the smaller avg size reduces assignment time in the end
				rspot = ceil(spotbounds(1)+rand()*(spotbounds(2)-spotbounds(1)));
				[rr cc] = meshgrid(1:rspot*2);
				if filled == true
					spotmap = sqrt((rr-rspot).^2+(cc-rspot).^2) <= rspot;
				else
					thisfill = fill(1)+rand()*(fill(2)-fill(1));
					spotmap = sqrt((rr-rspot).^2+(cc-rspot).^2) <= rspot ...
						& sqrt((rr-rspot).^2+(cc-rspot).^2) >= rspot*(1-thisfill);
				end
				spot = zeros(size(spotmap),'uint8');
				spot(spotmap) = 255;
				
				rxy = ceil(rand([1 numel(s)]).*s)+spotbounds(2);
				rangec = (rxy(1)-rspot):(rxy(1)+rspot-1);
				ranger = (rxy(2)-rspot):(rxy(2)+rspot-1);
				for c = 1:1:s(3)
					wpict(rangec,ranger,c) = wpict(rangec,ranger,c) ...
						+ spot*(spotopacity(1)+rand()*(spotopacity(2)-spotopacity(1)));
				end
			end
			outpict(:,:,:,f) = cropborder(wpict,spotbounds(2));
		end
	case 'square'
		for f = 1:1:s(4)
			wpict = zeros([s(1:2)+spotbounds(2)*2 s(3)],'uint8');
			for n = 1:1:numspots
				% it's actually faster to keep resizing the spot arrays
				% since the smaller avg size reduces assignment time in the end
				rspot = ceil(spotbounds(1)+rand()*(spotbounds(2)-spotbounds(1)));
				if filled == true
					spot = ones([2 2]*rspot,'uint8')*255;
				else
					spot = zeros([2 2]*rspot,'uint8');
					an = round(rspot*(fill(1)+rand()*(fill(2)-fill(1))));
					spot([1:an 2*rspot-an:2*rspot],:) = 255;
					spot(:,[1:an 2*rspot-an:2*rspot]) = 255;
				end
				
				rxy = ceil(rand([1 numel(s)]).*s)+spotbounds(2);
				rangec = (rxy(1)-rspot):(rxy(1)+rspot-1);
				ranger = (rxy(2)-rspot):(rxy(2)+rspot-1);
				for c = 1:1:s(3)
					wpict(rangec,ranger,c) = wpict(rangec,ranger,c) ...
						+ spot*(spotopacity(1)+rand()*(spotopacity(2)-spotopacity(1)));
				end
			end
			outpict(:,:,:,f) = cropborder(wpict,spotbounds(2));
		end
	case 'rectangle'
		for f = 1:1:s(4)
			wpict = zeros([s(1:2)+spotbounds(2)*2 s(3)],'uint8');
			for n = 1:1:numspots
				% it's actually faster to keep resizing the spot arrays
				% since the smaller avg size reduces assignment time in the end
				rspot = ceil(spotbounds(1)+rand([1 2])*(spotbounds(2)-spotbounds(1)));
				if filled == true
					spot = ones([2 2].*rspot,'uint8')*255;
				else
					spot = zeros([2 2].*rspot,'uint8');
					an = round(min(rspot)*(fill(1)+rand()*(fill(2)-fill(1))));
					spot([1:an 2*rspot(1)-an:2*rspot(1)],:) = 255;
					spot(:,[1:an 2*rspot(2)-an:2*rspot(2)]) = 255;
				end
				
				rxy = ceil(rand([1 numel(s)]).*s)+spotbounds(2);
				rangec = (rxy(1)-rspot(1)):(rxy(1)+rspot(1)-1);
				ranger = (rxy(2)-rspot(2)):(rxy(2)+rspot(2)-1);
				for c = 1:1:s(3)
					wpict(rangec,ranger,c) = wpict(rangec,ranger,c) ...
						+ spot*(spotopacity(1)+rand()*(spotopacity(2)-spotopacity(1)));
				end
			end
			outpict(:,:,:,f) = cropborder(wpict,spotbounds(2));
		end
	otherwise
		error('RANDSPOTS: unsupported shape');
end





















return

