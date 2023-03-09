function outpict = imsharpenFB(inpict,varargin)
%   OUTPICT=IMSHARPENFB(INPICT,{OPTIONS})
%   Sharpen an image by unsharp masking
%
%   This is a passthrough to the IPT function imsharpen(), with internal fallback implementations to 
%   help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an I/RGB image of any standard image class. Multiframe images are not supported.
%      If image is RGB, its luminance channel will be filtered alone.
%
%   OPTIONS includes the key-value pairs:
%     'radius' defines the width of the LPF gaussian, in turn defining the width of the ROI local
%         to edges.  (default 1)
%     'amount' specifies the strength of the sharpening effect.  (default 0.8)
%     'threshold' specifies the minimum normalized gradient magnitude (i.e. local contrast) required
%         for pixels to be considered within the edge ROI.  Scalar in range [0 1].  (default 1)
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imsharpenFB.html
% See also: imsharpen, imfilterFB, fkgen, edgemap


% IF IPT IS INSTALLED
if hasipt()
	outpict = imsharpen(inpict,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

radius = 1;
amount = 0.8;
thresh = 0;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		switch lower(varargin{k})
			case {'radius','rad'}
				radius = varargin{k+1};
				k = k+2;
			case {'amount','amt'}
				amount = varargin{k+1};
				k = k+2;
			case {'threshold','thresh'}
				thresh = varargin{k+1};
				k = k+2;
			otherwise
				error('IMSHARPENFB: unknown parameter name %s',varargin{k})
		end
	end
end

if size(inpict,4) > 1
	error('IMSHARPENFB: multiframe images are not supported')
end

radius = max(radius,1);
amount = max(amount,0);
thresh = max(thresh,0);

[inpict inclass] = imcast(inpict,'double');
[nc na] = chancount(inpict);
inpict = inpict(:,:,1:nc);
if nc == 3
	lchpict = rgb2lch(inpict,'lab');
	inpict = lchpict(:,:,1)/100;
end

fkr = ceil(2*radius);
fkw = 2*fkr+1; % odd width

fksharp = -fkgen('techgauss2',[1 1]*fkw,'sigma',radius);
fksharp(fkr+1,fkr+1) = fksharp(fkr+1,fkr+1)+1;

if thresh == 0
	% linear filtering
	fksharp = amount*fksharp;
	fksharp(fkr+1,fkr+1) = fksharp(fkr+1,fkr+1)+1;
	outpict = imfilterFB(inpict,fksharp,'replicate');
	
else
	% nonlinear thresholded filtering
	outpict = imfilterFB(inpict,fksharp,'replicate');
	
	% find edge roi
 	gmag = abs(outpict);
 	thresh = thresh*max(gmag(:));
 	outpict(gmag < thresh) = 0;
	
	% combine input and masked output
	outpict = inpict + amount*outpict;	
		
end

if nc == 3
	outpict = lch2rgb(cat(3,outpict*100,lchpict(:,:,2:3)),'lab');
end

outpict = imcast(outpict,inclass);










