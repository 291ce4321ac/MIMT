function outpict = amedfilt(inpict,rmax,exos)
%  OUTPICT = AMEDFILT(INPICT,{RMAX},{EXOS})
%  Apply adaptive median noise removal filter.  This is useful for 
%  removing impulse (salt & pepper) noise from an image. 
%
%  INPICT is an array of any standard image class.  Multipage images
%    are supported.  Multipage images are processed pagewise.
%  RMAX optionally specifies the maximum window radius (px, default 5)
%    Maximum window size is (2*Rmax + 1)*[1 1] (always odd)
%  EXOS optionally specifies the local extreme order statistics. (default 0)
%    This is specified as a relative offset from 0 to 1.  Moderately increasing EXOS 
%    can help when images with impulse noise have been subject to lossy compression.
%    While compressed images can be handled using fmedfilt() with a wide tolerance
%    amedfilt() with nonzero EXOS tends to have better contrast retention.
%    
%  Output class is inherited from input
%
%  See also: fmedfilt, nhfilter, medfilt2

if nargin<2
	rmax = 5;
else
	rmax = max(round(rmax),1);
end

if nargin<3
	exos = 0;
else
	exos = imclamp(exos/2);
end


sz = imsize(inpict);

% symmetric should suffice
inpict = padarrayFB(inpict,[1 1]*rmax,'symmetric','both');

% assume most pixels will be copied
outpict = inpict;

for c = 1:sz(3)
	for m = rmax+1:rmax+sz(1)
		for n = rmax+1:rmax+sz(2)
			r = 1; % initial nhood radius (corresponds to a 3x3 nhood)
			while r <= rmax
				% get this neighborhood
				NH = inpict(m-r:m+r,n-r:n+r,c);

				% presort, vectorize, get local stats
				% this is faster than using min()/max()/median()
				NH = sort(NH(:));
				midx = ceil((2*r+1)^2/2);
				idxos = round(midx*exos); % convert relative to absolute offset
				lmin = NH(idxos+1); % local min (offset)
				lmax = NH(end-idxos); % local max (offset)
				lmed = NH(midx); % local median

				% increase the nhood radius until local median
				% becomes distinguishable from the local extrema
				% then break to pixel replacement routine
				if lmed>lmin && lmed<lmax
					break;
				else
					r = r+1;
				end
			end

			% if center pixel is not distinguishable from local extrema, replace it
			% otherwise keep the original center pixel
			% it may help to use some tolerance or a different order-statistic for this test
			% especially in cases where images have been subject to JPG compression
			if ~(inpict(m,n,c)>lmin && inpict(m,n,c)<lmax)
				outpict(m,n,c) = lmed;
			end
		end
	end
end

% crop output
outpict = outpict(rmax+1:rmax+sz(1),rmax+1:rmax+sz(2),:);

end












