function outpict = xwline(imagesize,X,Y)
%   XWLINE(SIZE,X,Y)
%      draw antialiased line segments for use in image composition
%      this is based on Sachin Abeywardana's Matlab implementation at
%      https://github.com/sachinruk/xiaolinwu
%   
%   SIZE is a 2-element vector describing the output image dimensions [h w]
%   X, Y are coordinate vectors
%      two-element vectors define a line segment
%      vectors longer than two elements define a polyline
%
%   Output is a single-channel intensity image of type 'double'
%
%   EXAMPLE:
%      potato=xwline([200 200],[50 150],[30 170]); imshow2(potato);
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/xwline.html

	if length(X) ~= length(Y)
		error('XWLINE: coordinate vectors of unequal length')
	end

	outpict = zeros(imagesize,'double');

	for seg = 1:(length(X)-1)

		x1 = X(seg); x2 = X(seg+1);
		y1 = Y(seg); y2 = Y(seg+1);
		dx = x2 - x1;
		dy = y2 - y1;

		%preallocate memory for x,y, and c
		x = zeros(floor(2*sqrt(dx^2+dy^2)),1);
		y = zeros(size(x));
		c = zeros(size(x));

		swapped = false;
		if abs(dx) < abs(dy)         
		  [x1 y1] = swap(x1, y1);
		  [x2 y2] = swap(x2, y2);
		  [dx dy] = swap(dx, dy);
		  swapped = true;
		end 
		if x2 < x1
		  [x1 x2] = swap (x1, x2);
		  [y1 y2] = swap (y1, y2);
		end 
		gradient = dy / dx;

		% handle first endpoint
		xend = round(x1);
		yend = y1 + gradient * (xend - x1);
		xgap = rfpart(x1 + 0.5);
		xpxl1 = xend;  % this will be used in the main loop
		ypxl1 = ipart(yend);
		x(1) = xpxl1; y(1) = ypxl1; c(1) = rfpart(yend) * xgap;
		x(2) = xpxl1; y(2) = ypxl1 + 1; c(2) = fpart(yend) * xgap;
		intery = yend + gradient; % first y-intersection for the main loop

		% handle second endpoint
		xend = round (x2);
		yend = y2 + gradient * (xend - x2);
		xgap = fpart(x2 + 0.5);
		xpxl2 = xend;  % this will be used in the main loop
		ypxl2 = ipart (yend);
		x(3) = xpxl2; y(3) = ypxl2; c(3) = rfpart (yend) * xgap;
		x(4) = xpxl2; y(4) = ypxl2 + 1; c(4) = fpart (yend) * xgap;

		% main loop
		k = 5;
		for i = (xpxl1 + 1):(xpxl2 - 1)
			x(k) = i;
			y(k) = ipart(intery);
			c(k) = rfpart(intery);
			k = k+1;
			x(k) = i; 
			y(k) = ipart(intery) + 1;
			c(k) = fpart(intery);
			intery = intery + gradient; 
			k = k+1;
		end
  
		if swapped         
		  [x y] = swap(x, y);
		end 
		
		%truncate the vectors to proper sizes
		x = imclamp(x(1:k-1),[1 imagesize(2)]);
		y = imclamp(y(1:k-1),[1 imagesize(1)]);
		c = c(1:k-1);  
		
		outpict(sub2ind(size(outpict),y,x)) = c;
	end
end



%integer part
function i = ipart(x)
	if x > 0
		i = floor(x);
	else
		i = ceil(x);
	end
end

function r = round(x) 
    r = ipart(x + 0.5);
end

%fractional part
function f = fpart(x) 
    f = x-ipart(x);
end

function rf = rfpart(x) 
    rf = 1 - fpart(x);
end
    
function [x y] = swap(x,y)
    a = x;
    x = y;
	y = a;
end

