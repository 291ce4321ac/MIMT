function outpict = gray2rgb(inpict)
%  OUTPICT = GRAY2RGB(INPICT)
%  Convert an image with a single color channel to one with 
%  three color channels by simple channel replication.
%  If given an RGB image, pass it without complaint or alteration.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class.
%
%  Output class is inherited from input
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/gray2rgb.html
%  See also: mono, gcolorize

[ncc,~] = chancount(inpict);
if ncc == 1
	[inpict alpha] = splitalpha(inpict);
	outpict = repmat(inpict,[1 1 3]);
	outpict = joinalpha(outpict,alpha);
elseif ncc == 3
	outpict = inpict;
else
	error('GRAY2RGB: INPICT is not an I/IA/RGB/RGBA/RGBAAA image.  What is it?')
end
