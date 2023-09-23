function y = stretchcurve(x,k,n)
% OUTPICT = STRETCHCURVE(INPICT,K,{N})
% power-function based symmetric contrast adjustment tool
% this is used by imlnc(), etc
% 
% INPICT is a unit-scale float array
%   values must lie in the unit interval
% K is a scalar adjustment factor >=0
% N specifies the number of points to use for interpolation (default 1000)


% prior to ~R2015b, interp1() is significantly slower.
% i believe this change occurred in R2015a, based on RN
persistent isold
if isempty(isold)
	isold = ifversion('<','R2015a');
end

k = max(k,0);
if k == 1
	% bypass
	y = x;
	
elseif isold || numel(x)<1E4
	% direct calculation on small array
	y = sc0(x,k);

else
	% do LUT interpolation on larger arrays for speed
	% this requires R2015a+ in order to have a speed advantage
	if nargin==2
		n = 1000;
	end
	
	x = imclamp(x);
	xx = linspace(0,1,n);
	yy = sc0(xx,k);
	y = interp1(xx,yy,x,'linear');
	
end

end % END MAIN SCOPE


function R = sc0(I,k)
	c = 0.5;
	mk = abs(k) < 1;
	mc = c < 0.5;
	if ~xor(mk,mc)
		pp = k; kk = k*c/(1-c);
	else
		kk = k; pp = (1-c)*k/c;
	end

	hi = I > c; lo = ~hi;
	R = zeros(size(I));
	R(lo) = 0.5*((1/c)*I(lo)).^kk;
	R(hi) = 1-0.5*((1-I(hi))*(1/(1-c))).^pp;
end



