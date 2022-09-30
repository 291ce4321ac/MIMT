function cmapnew = ctshift(cmap0,stretchamt)
%  CMAPNEW = CTSHIFT(CMAP,AMOUNT)
%    Nonlinearly shift the content of a colormap toward one end or the other.
%    This may be useful if trying to tailor a map to provide good feature 
%    contrast when the distribution of data is significantly asymmetric.
%
%  CMAP is a Mx3 color table or column vector of any standard image class
%  AMOUNT adjusts the shift effect.  (scalar, range is [-1 1])
%    when AMOUNT = 0, no change
%    when AMOUNT < 0, stretch bottom of table upward
%    when AMOUNT > 0, stretch top of table downward
%
%  Output class is inherited from input.
%
%  See also: brighten, makect, ctflop, ctpath, imtweak

stretchamt = imclamp(stretchamt,[-1 1]);

[cmap0 inclass] = imcast(cmap0,'double');

% delinearize adjustment parameter to get gamma
% apply gamma adjustment to primary axis of the CT
% conditionally flip table so xnew is effectively point-symmetric about [0.5 0.5]
% this limits the slope of xnew and avoids overcompressing the table for g<1
n = size(cmap0,1);
x = linspace(0,1,n);
if stretchamt > 0
	g = 1 - min(1-eps,stretchamt);
	xnew = x.^(1/g);
	cmapnew = flipud(interp1(x,flipud(cmap0),xnew,'pchip'));
else
	g = 1/(1 + max(eps-1,stretchamt));
	xnew = x.^g;
	cmapnew = interp1(x,cmap0,xnew,'pchip');
end

cmapnew = imcast(cmapnew,inclass);

