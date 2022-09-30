function outpict = perlin(outsize,varargin)
%   PERLIN(SIZE, {OPTIONS})
%       Generates pseudo-perlin noise fields or volumes. Compared to PERLIN3, 
%       behavior is nonrepeatable, but the execution is much faster.  Instead 
%       of generating a perlin noise volume to create a multichannel image, 
%       PERLIN generates a moving weighted sum of 2-D noise sets.  A potential 
%       benefit of this compromise to avoid the expense of volumetric interpolation 
%       is that page correlation is uniquely controllable as a parameter. 
%   
%   SIZE is a 2 or 3-element vector defining the size of the output image
%       Dim 3 is not limited to the sizes expected for typical image channel formats
%   OPTIONS includes the following key-value pairs:
%       'correl' specifies the page or channel correlation factor (default 1)
%           This is a proxy for the correlation coefficient between pages (image
%           channels).  For 0, pages are uncorrelated.  For the default value, 
%           page correlation is approximately 93%, more closely approximating the 
%           appearance of 3-D noise.  Values above 1 further increase correlation.
%           In the context of an RGB image, CORREL=0 yields a garish rainbow cloud.  
%           As CORREL increases beyond 1, the image approaches grayscale.
%       'interpolation' specifies the interpolation used in scaling noise components
%           supports the methods used by interp2() (default 'spline')
%       'outclass' specifies the output image class (default 'double')
%           supports all standard image class names
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/perlin.html 
% See also: perlin3


correl = 1; 
outclassstrings = {'double','single','uint8','uint16','int16','logical'};
outclass = 'double';
interpmethodstrings = {'nearest','linear','cubic','spline'};
interpmethod = 'spline';

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'correl'
				if isnumeric(varargin{k+1})
					correl = varargin{k+1};
				else
					error('PERLIN: expected numeric value for CORREL')
				end
				k = k+2;
			case 'outclass'
				thisarg = lower(varargin{k+1});
				if ismember(thisarg,outclassstrings)
					outclass = thisarg;
				else
					error('PERLIN: unknown output class %s\n',thisarg)
				end
				k = k+2;
			case 'interpolation'
				thisarg = lower(varargin{k+1});
				if ismember(thisarg,interpmethodstrings)
					interpmethod = thisarg;
				else
					error('PERLIN: unknown interpolation method %s\n',thisarg)
				end
				k = k+2;
			otherwise
				error('PERLIN: unknown input parameter name %s',varargin{k})
		end
	end
end

pagesize = outsize(1:2);
s = max(pagesize,2);

if numel(outsize) == 3
    numchan = outsize(3);
else
    numchan = 1;
end

outpict = zeros([pagesize numchan]); 
for c = 1:numchan;
    wpict = zeros(s);
    w = max(s);
    k = 0;
    while w > 3
        k = k+1;
        d = interp2(randn(ceil(s/(2^(k-1))+1)), k-1, interpmethod);
        wpict = wpict + k*d(1:s(1),1:s(2));
        w = w-ceil(w/2 - 1);
    end

    if sum(pagesize > 1) == 1
        wpict = wpict(1:pagesize(1),1:pagesize(2));
    end
    
    outpict(:,:,c) = wpict;
end

if numchan > 1 && correl ~= 0
	% this is an attempt to counteract the natural scale-dependence of correlation in these sums
	% for volumes, this may be undesired, but for RGB images and typical use, it's probably for the best
	dv = log10(1E6/prod(pagesize))/(correl*300);
	for c = 2:numchan
		outpict(:,:,c-1) = simnorm(outpict(:,:,c-1),'mean')-0.5;
		outpict(:,:,c) = outpict(:,:,c-1)+outpict(:,:,c)*dv;
	end
	outpict(:,:,c) = simnorm(outpict(:,:,c),'mean')-0.5;
	outpict = outpict+0.5;
else
	for c = 1:numchan
		outpict(:,:,c) = simnorm(outpict(:,:,c),'mean');
	end
end

outpict = imcast(outpict,outclass);

end

