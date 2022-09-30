function outflag = isopaque(inpict,tol)
%  OUTFLAG=ISOPAQUE(INPICT,{TOLERANCE})
%     Determine whether an image is opaque.  Return is true if 
%     INPICT has no alpha channels or if the alpha channels are
%     all uniformly maximized within a given tolerance.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any class.  Multiframe
%     images are supported, but all frames are evaluated together.
%     For per-frame analysis, use fourdee(@isopaque,inpict) or
%     use a loop of some fashion.
%  TOLERANCE is the maximum allowable deviation of alpha values away
%     from the class-specific white value.  (normalized, default 0.004)
%
%  See also: ismono, issolidcolor, imrange


if ~exist('tol','var')
	tol = 0.004;
end

tol = imrescale(tol,'double',class(inpict));

outflag = true;
[cc ca] = chancount(inpict);
if ca == 0
	return;
else
	cr = getrangefromclass(inpict);
	for c = cc+(1:ca)
		chdiff = abs(double(inpict(:,:,c))-cr(2)) <= tol;
		if ~all(chdiff(:))
			outflag = false;
			return;
		end
	end
end







