function outpict = flattenbg(inpict,sg)
%  OUTPICT = FLATTENBG(INPICT,SIGMA)
%    Flatten low-frequency nonuniformities of an image using a 
%    traditional blur and divide technique, similar to that used
%    by IPT imflatfield().
%   
%  INPICT is an image of any standard image class
%  SIGMA describes the blur filter shape parameter.  This may be
%    specified as a scalar or as a 2-element vector.  The filter
%    size is automatically calculated as 2*ceil(3*SIGMA-0.5)+1.
%
%  Output class is inherited from input.
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/flattenbg.html
%  See also: imflatfield, morphops, fkgen, imfilterFB

fk = fkgen('techgauss2',[1 1]*2*ceil(3*sg-0.5)+1,'sigma',sg);
[inpict inclass] = imcast(inpict,'double');
blurred = imfilterFB(inpict,fk,'replicate');
bmn = mean(blurred(~isnan(blurred)));

outpict = bmn*inpict./blurred;
outpict = imcast(outpict,inclass);





