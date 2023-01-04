function outpict = brline(outsize,vertices)
%   MASK = BRLINE(OUTSIZE,VERTICES)
%   A simple tool to draw a non-antialiased polyline as a logical image.
%   This is fairly crude Bresenham line tool, but I'm considering this as 
%   a placeholder.  I hope to someday replace xwline() and brline() both when 
%   I get around to writing a full set of tools for drawing 2D primitives.
%
%   OUTSIZE is a 2-element vector specifying the output geometry
%   VERTICES is a Mx2 list of vertex locations in image coordinates ([x y])
%      Vertices may lie outside the specified image geometry.
%
%   Output class is 'logical'
%
% See also: xwline

% prepare
vertices = round(vertices);
x = vertices(:,1);
y = vertices(:,2);
dx = diff(x);
dy = diff(y);

% preallocate
vx = imrange([x; 1; outsize(2)]);
vy = imrange([y; 1; outsize(1)]);
canvassz = [diff(vy) diff(vx)]+1;
outpict = false(canvassz);

% shift data as necessary
xsh = x - vx(1) + 1;
ysh = y - vy(1) + 1;

% draw each segment
for seg = 1:size(vertices,1)-1
	plotbrline(xsh(seg:seg+1),ysh(seg:seg+1));
end

% crop image out of canvas
yrange = (2-vy(1)):outsize(1)-vy(1)+1;
xrange = (2-vx(1)):outsize(2)-vx(1)+1;
outpict = outpict(yrange,xrange);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotbrline(xx,yy)
	% if the line is steep, transpose coordinates
	issteep = abs(dy(seg)) > abs(dx(seg));
	if issteep
		[yy xx] = deal(xx,yy);
	end
	
	% if distance on independent axis (x) is negative
	% swap point order
	swappoints = diff(xx) < 0;
	if swappoints
		xx = flipd(xx);
		yy = flipd(yy);
	end
	
	% these coordinates are not necessarily x,y coordinates
	% they may be transposed, but we're just calling the 
	% independent axis "x" from here on out
	dxx = diff(xx);
	dyy = diff(yy);
	yi = 1;
	if dyy < 0
		yi = -1;
		dyy = -dyy;
	end
	D = (2 * dyy) - dxx;
	yt = yy(1);

	for xt = xx(1):xx(2)
		% transpose back if necessary
		if issteep
			outpict(xt,yt) = true;
		else
			outpict(yt,xt) = true;
		end
		
		if D > 0
			yt = yt + yi;
			D = D + (2 * (dyy - dxx));
		else
			D = D + 2*dyy;
		end
	end
end

end % END MAIN SCOPE








