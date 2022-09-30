function outgeometry = drysize(ingeometry,outscale)
%  OUTGEOMETRY=DRYSIZE(INGEOMETRY,OUTSCALE)
%     Calculate the output geometry resulting from the use of imresize().
%     This may be convenient when needing to precalculate array sizes resulting
%     from the subsequent use of imresize() with implicit resizing parameters.  
%     
%  INGEOMETRY is a 2-element vector specifying the input image geometry in pixels
%  OUTSCALE may either be a scaling factor (scalar) or a 2-element size vector
%     When specified as a vector, the units are presumed to be in pixels
%     If one element is NaN, that size will be calculated to maintain aspect ratio.
%
% See also: imsize imresizeFB

if numel(outscale) == 1
	outgeometry = outscale*ingeometry;
else
	if isnan(outscale(1))
		outgeometry = [outscale(2)*ingeometry(1)/ingeometry(2) outscale(2)];
	elseif isnan(outscale(2))
		outgeometry = [outscale(1) outscale(1)*ingeometry(2)/ingeometry(1)];
	else
		outgeometry = outscale(1:2);
	end
end
outgeometry = ceil(outgeometry);


