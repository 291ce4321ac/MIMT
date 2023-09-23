function y = impow(x,p,n)
% OUTPICT = IMPOW(INPICT,P,{N})
% simple gamma/power function replacement for use on unit-scale data.
% conditionally uses various methods to improve speed, including:
%   bypass for null parameter
%   fast path for sqrt(), integer powers
%   lookup table interpolation for large arrays
% this is used by imadjust(), imlnc(), etc
% 
% INPICT is a unit-scale float array
%   values must lie in the unit interval
% P is a scalar adjustment factor >=0
% N specifies the number of points to use for interpolation (default 1000)

% prior to ~R2015b, interp1() is significantly slower.
% i believe this change occurred in R2015a, based on RN
persistent isold
if isempty(isold)
	isold = ifversion('<','R2015a');
end

p = imclamp(p,[eps 1/eps]); % plz no explode

if p == 1
	% null parameter
	y = x;
	
elseif p == 0.5
	% sqrt is faster in any version
	y = sqrt(x);
	
elseif isold || mod(p,1) == 0 || numel(x)<1E4
	% this is faster for small arrays and integer powers
	y = x.^p;

else
	% do LUT interpolation on larger arrays for speed
	% this requires R2015a+ in order to have a speed advantage
	if nargin==2
		n = 1000;
	end
	
	x = imclamp(x);

	% making xx nonlinear instead of yy
	% gives the same shape, but gives
	% more resolution near steep parts of curve
	yy = linspace(0,1,n);
	xx = real(yy.^(1/p));
	
	% using pchip is nice, but causes problems in steep areas
	y = interp1(xx,yy,x,'linear');

end




















