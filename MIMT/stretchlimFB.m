function lim = stretchlimFB(inpict,tol)
%   stretchlimFB(inpict,{tol})
%      passthrough to stretchlim() with internal fallback
%      for systems without IPT installed.  
%
%   Not all features are available in the fallback implementation
%   IPT methods exploit precompiled private functions and are much faster
%      
%   INPICT is an intensity or RGB image
%   TOL is a scalar (default 0.01)

if ~exist('tol','var')
	tol = 0.01;
end

% IF IPT IS INSTALLED
if hasipt()
	lim = stretchlim(inpict,tol);
	return;
end

% IF IPT IS NOT INSTALLED
nbins = 255; % actual bin count is nbins+1
numchan = size(inpict,3);
A = imcast(inpict,'uint8');

% this method is not going to work well for large nbins
% so i'm only using 256 bins and staying with uint8
% this is so slow it's silly
lim = zeros([2 numchan]);
for c = 1:numchan
	Ac = reshape(A(:,:,c),1,[]);
	PD = sum(bsxfun(@eq,Ac,(0:nbins)'),2);
	cdf = cumsum(PD)/sum(PD);

	cl = find(cdf > tol, 1);
	ch = find(cdf >= (1-tol), 1);

	lim(:,c) = [cl ch]';
end
lim = ((lim-1)/(nbins));

end















