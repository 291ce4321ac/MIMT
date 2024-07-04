function [CT cidx] = intervalct(zb,CT0,nmax)
%  [CT CIDX] = INTERVALCT(BREAKS,CT0,{NMAX})
%  Attempt to generate a minimal-length interval colortable.
%
%  Not all breakpoint lists can be exactly quantized.  Within the 
%  constraint of allowed table length, if an exact solution can be
%  found, it will be returned.  Otherwise, a solution is chosen 
%  which minimizes the MAE between the specified and resulting 
%  breakpoint locations.
%
%  BREAKS is a row vector which defines the locations where each
%    color interval ends. 
%  CT0 defines the interval colors as a Mx3 color table.  
%    CT0 must contain at least numel(BREAKS)-1 RGB tuples.
%  NMAX optionally specifies the maximum generated CT length. 
%    (default 256)
%  
%  CT is the expanded color table
%  CIDX is an array containing the indices of the first and last 
%    entry in each CT block.
%
% see also: makect

% requires R2015a for repelem()
% other version dependencies have been removed
% tested in R2015b

if nargin < 3
	nmax = 256; % default
end

% setup
mn = min(zb(:));
mx = max(zb(:));
zn = (zb - mn)/(mx-mn);
dz = diff(zn);
nival = numel(dz);
N = (nival:nmax).';

% calculate error
xnt = cumsum(bsxfun(@rdivide,round(N*[0 dz]),N),2);
err = sum(abs(bsxfun(@minus,zn,xnt)),2)/nival;

% check for approximately-exact solutions before minimizing
idx = find(err <= 1E-12,1);
if isempty(idx)
	[~,idx] = min(err);
end

% prepare results
k = round(N(idx)*dz); % number of elements per block
cidx1 = cumsum(k); % last index in each block
cidx = [1 cidx1(1:end-1)+1; cidx1].'; % index ranges	
CT = CT0(repelem(1:numel(zb)-1,k),:); % expanded colormap (R2015b)

end % END MAIN SCOPE
