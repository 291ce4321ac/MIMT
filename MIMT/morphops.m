function outpict = morphops(inpict,se,mode)
%   OUTPICT=MORPHOPS(INPICT,SE,MODE)
%   Perform the selected morphological operation on an image.  
%
%   This is a passthrough to the IPT functions imdilate(), imerode(), imopen(), imclose(),  
%   imtophat(), and imbothat(), with internal fallback implementations to help remove 
%   the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported.
%      While fallback implementations are slower than the IPT tools, the processing of numeric 
%      images will be much slower than that of logical images due to the methods used.
%
%   SE is a 2D structuring element
%      While IPT tools support 3D structuring elements, the fallback methods do not.  
%      Fallback methods do support IPT strel objects, but idk how you'll have strel() without IPT.
%      If SE is a numeric array, it will be thresholded at 0.5.
%      Unless requirements are particular, a simple structuring element can be made in the 
%      absence of IPT by using existing MIMT tools (e.g. simnorm(fkgen('disk',10))>0.5)
%
%   MODE specifies the operation to perform
%      'dilate'   image dilation
%      'erode'    image erosion
%      'open'     dilate(erode(inpict,se))
%      'close'    erode(dilate(inpict,se))
%      'tophat'   top hat filter
%      'bothat'   bottom hat filter
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/morphops.html
% See also: imdilate, imerode, imopen, imclose, imtophat, imbothat, strel, fkgen, morphnhood

% sanitize se 
if isnumeric(se)
	se = se > 0.5;
end

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	
	switch mode
		case 'dilate'
			outpict = imdilate(inpict,se);
		case 'erode'
			outpict = imerode(inpict,se);
		case 'open'
			outpict = imopen(inpict,se);				
		case 'close'
			outpict = imclose(inpict,se);
		case 'tophat'
			outpict = imtophat(inpict,se);
		case 'bothat'
			outpict = imbothat(inpict,se);
		otherwise
			error('MORPHOPS: unknown mode name ''%s''',mode)
	end
	
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isa(se,'strel')
	se = se.getnhood();
end

if ~isimageclass(se) || ndims(se) > 2
	error('MORPHOPS: Expected SE to be either a 2D numeric or logical array or a strel object.  Fallback methods do not support 3D structuring elements.')
end

if islogical(inpict)
	% for logical inputs, these operations can be done by convolution
	% this is slow, but it's much faster than loops in m-code
	
	inclass = class(inpict);
	inpict = uint16(inpict);
	se = double(se);
	
	switch mode
		case 'dilate'
			outpict = min(max(imfilterFB(inpict,rot90(se,2)),0),1); % this strel rotation matches IPT tool behavior
		case 'erode'
			outpict = 1-min(max(imfilterFB(1-inpict,se),0),1);
		case 'open'
			% dilate(erode(inpict,se))
			outpict = min(max(imfilterFB(1-min(max(imfilterFB(1-inpict,se),0),1),rot90(se,2)),0),1);
		case 'close'
			% erode(dilate(inpict,se))
			outpict = 1-min(max(imfilterFB(1-min(max(imfilterFB(inpict,rot90(se,2)),0),1),se),0),1);
		case 'tophat'
			% inpict & ~open(inpict,se);
			outpict = inpict - min(max(imfilterFB(1-min(max(imfilterFB(1-inpict,se),0),1),rot90(se,2)),0),1);
		case 'bothat'
			% ~inpict & close(inpict,se);
			outpict = 1-min(max(imfilterFB(1-min(max(imfilterFB(inpict,rot90(se,2)),0),1),se),0),1) - inpict;
		otherwise
			error('MORPHOPS: unknown mode name ''%s''',mode)
	end
	
	outpict = imcast(outpict > 0.5,inclass);
	
else
	% the convolution approach doesn't work for non-logical data
	% naive approaches like this work, but they're ridiculously inefficient in m-code
	% most better ways i can think of require the adoption of toolbox dependencies
	% this is so slow that stacking overhead by recursion is insignificant
	
	inclass = class(inpict);
	s0 = imsize(inpict);
	
	switch mode
		case 'dilate'
			se = rot90(se,2); % match IPT tool behavior
			se = cast(se,inclass);
			sse = imsize(se,2);

			padsize = floor(sse/2);
			inpict = padarrayFB(inpict,padsize,'replicate','both');
			s = imsize(inpict);

			outpict = imzeros(s0,inclass);
			osm = sse(1)-1;
			osn = sse(2)-1;
			
			for f = 1:s(4)
				for c = 1:s(3)
					for n = 1:(s(2)-2*padsize(2))
						for m = 1:(s(1)-2*padsize(1))
							sample = inpict(m:(m+osm),n:(n+osn),c,f).*se;
							outpict(m,n,c,f) = max(sample(:));
						end
					end
				end
			end
		case 'erode'
			wv = imrescale(1,'double',inclass);
			inpict = wv-inpict;
			outpict = wv-morphops(inpict,rot90(se,2),'dilate');
		case 'open'
			outpict = morphops(morphops(inpict,se,'erode'),se,'dilate');
		case 'close'
			outpict = morphops(morphops(inpict,se,'dilate'),se,'erode');
		case 'tophat'
			outpict = inpict-morphops(inpict,se,'open');
		case 'bothat'
			outpict = morphops(inpict,se,'close')-inpict;
		otherwise
			error('MORPHOPS: unknown mode name ''%s''',mode)
	end
end









