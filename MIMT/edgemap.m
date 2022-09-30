function outpict = edgemap(inpict,varargin)
%  OUTPICT=EDGEMAP(INPICT,{FILTERTYPE},{OPTIONS})
%    Filter an image to reveal edge information.  
%    Unlike the IPT tool edge(), no thresholding is performed.
%    
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class.  
%  FILTERTYPE is one of the following (default 'scharr')
%    'prewitt' is the gradient magnitude calculated with a prenormalized Prewitt filter
%    'sobel' is the gradient magnitude calculated with a prenormalized Sobel filter
%    'scharr' is the gradient magnitude calculated with a prenormalized Scharr filter
%    'kayyali' is the gradient magnitude calculated with a prenormalized Kayyali filter
%    'roberts' is the gradient magnitude calculated with a prenormalized Roberts filter
%    'laplacian' is an adjustable 3x3 discrete Laplacian filter
%    'lapgauss' is a variable-size Laplacian of Gaussian filter
%  OPTIONS include the following key-value pairs
%    'size' specifies filter size for 'lapgauss' (up to 2 elements; default [5 5])
%    'sigma' specifies filter shape for 'lapgauss' (up to 2 elements; default [0.5 0.5])
%    'alpha' specifies filter shape for 'laplacian' (scalar, [0 1]; default 1/3)
% 
%  Output image class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/edgemap.html
% See also: lcmap, imstats, fkgen, imfilterFB, edge, imgradient

ftypestrings = {'prewitt','sobel','scharr','kayyali','roberts','laplacian','lapgauss'};
filtertype = 'scharr';
fsize = 5;
fsigma = [0.5 0.5];
falpha = 1/3;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		thisarg = lower(varargin{k});
		switch thisarg
			case ftypestrings
				filtertype = thisarg;
				k = k+1;
			case 'size'
				fsize = varargin{k+1};
				k = k+2;
			case 'sigma'
				fsigma = varargin{k+1};
				k = k+2;
			case 'alpha'
				falpha = varargin{k+1};
				k = k+2;
			otherwise
				error('EDGEMAP: unknown option %s',thisarg)
		end
	end
end


if ~strismember(filtertype,{'laplacian','lapgauss'})
	filtertype = [filtertype '2'];
end

[inpict inclass] = imcast(inpict,'double');

% get rid of any nans
for c = 1:size(inpict,3)
	thischan = inpict(:,:,c);
	if any(isnan(thischan(:)))
		inpict(:,:,c) = inpaint_nans(thischan);
	end
end

% need to pad to get rid of edge artifacts
padsize = [1 1].*max(fsize,3);
inpict = padarrayFB(inpict,padsize,'both','symmetric');

fk = fkgen(filtertype,fsize,'sigma',fsigma,'alpha',falpha);
wp1 = imfilterFB(inpict,fk);
if strismember(filtertype,{'laplacian','lapgauss'})
	% these filters just get a single pass
	outpict = wp1;
else
	% these need two passes for gradient estimation
	if strismember(filtertype,{'kayyali','roberts'})
		wp2 = imfilterFB(inpict,flipud(fk));
	else
		wp2 = imfilterFB(inpict,fk');
	end
	outpict = sqrt(wp1.^2+wp2.^2);
end

outpict = imcast(cropborder(outpict,padsize),inclass);

end



