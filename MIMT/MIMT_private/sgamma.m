function y = sgamma(x,g,n)
% OUTPICT = SGAMMA(INPICT,P,{N})
% Gamma adjustment function designed to be symmetric about y = 1-x (the unit antidiagonal).
% 
% The concept is similar to grabbing the center of the curve and dragging it
% diagonally, as one might do in GIMP, etc. Compared to a normal power function,
% this reduces the extreme contrast near zero for subunity gamma values.
% 
% Based on a superelliptic quarter-curve, and made for use on unit-scale data.
% this is used by imlnc(), etc
% 
% INPICT is a unit-scale float array
%   values must lie in the unit interval
% P is a scalar adjustment factor >=0
% N specifies the number of points to use for interpolation (default 1000)

% this creates the quarter-curve of a superellipse of order P<1
% centered on either end of the unit antidiagonal (i.e. [0 1] or [1 0])
% i.e. for both sg ~ 0.5 and sg ~ 2, the quarter-curve belongs to an astroid, not a circle
% this piecewise-inversion forces symmetry about the unit diagonal 
% and allows the applied effect to be reversible (within limits of precision)
%
% this is equivalent to a simple composition of power functions 
% adhering to the order of operations applied by imlnc().
% i.e. rgamma(pgamma(x,g),rg) where g < 1, g = rg,
% and both g,rg are closer to unity than sg
% (as an obvious consequence of their compounded influence),
% and P is closer to unity than sg
% (as dictated by the approximate area correction function in adjgamma()).

% prior to ~R2015b, interp1() is significantly slower.
% i believe this change occurred in R2015a, based on RN
persistent isold
if isempty(isold)
	isold = ifversion('<','R2015a');
end

g = imclamp(g,[eps 1/eps]); % plz no explode

if g == 1
	% null parameter
	y = x;
	
elseif isold || numel(x)<1E4
	% direct calculation on small array
	x = imclamp(x);
	if g < 1
		g = adjgamma(g);
		y = 1-(1-(x.^g)).^(1/g);
	else
		g = adjgamma(1/g);
		y = (1-(1-x).^g).^(1/g); % inverse
	end

else
	% do LUT interpolation on larger arrays for speed
	% this requires R2015a+ in order to have a speed advantage
	if nargin==2
		n = 1000;
	end
	
	% using pchip is nice, but causes problems in steep areas
	x = imclamp(x);
	xx = linspace(0,1,n);
	if g < 1
		g = adjgamma(g);
		yy = 1-(1-(xx.^g)).^(1/g);
	else
		g = adjgamma(1/g);
		yy = (1-(1-xx).^g).^(1/g); % inverse
	end
	y = interp1(xx,yy,x,'linear');

end

end % END MAIN SCOPE

function g = adjgamma(g)
	% this adjusts the parameter response
	% to be similar to that of a simple power function
	% total intensity delta should be comparable between pgamma,sgamma,rgamma
	g = 0.772419*g^0.644839 + 0.227266; % optimal over g = [0.1 10]
end


















