function sureis = ismono(inpict,tol)
%   ISMONO(INPICT,{TOL})
%       Returns a logical value, true when INPICT is an I/IA logical or
%       numeric array, or when INPICT is an RGB/RGBA image and all three color 
%       channels are identical to within a given tolerance. 4-D arrays of 
%       mono images return true only if all frames are mono images. 
%       
%       Legacy IP Toolbox functions ISGRAY() and ISIND() provide similar functionality
%       but will return false for any multi-channel or multi-frame array.  
%
%       ISMONO() does not discriminate between grey or indexed images
%       or assume value ranges by class. ISMONO() will return true for a single-channel
%       uint8 grey image (0-255) temporarily cast as double, whereas ISGRAY()/ISIND() 
%       will assume that it is an indexed image.
%   
%   INPICT is a 1, 2, 3, or 4 channel image array of any logical or numeric class.
%   TOL is the tolerance used for checking RGB/RGBA images. (default 1E-12)
%       This is the maximum allowable mean pixel difference.
%       Using an excessively tight tolerance will tend to cause false negatives 
%       due to rounding error in desaturated images.
%
%   See also: issolidcolor, isopaque, imrange

if ~exist('tol','var')
	tol = 1E-12;
end
tol = imrescale(tol,'double',class(inpict));

[nc ~] = chancount(inpict);

if nc == 1
	sureis = true;
else
	wpict = inpict(:,:,1:nc,:);
	
	% method similar to ISGRAY(); 
	% test small area for possible early return
	maxpatch = [100 100];
	testpatch = min([size(wpict,1) size(wpict,2)],maxpatch);
	diffpart = abs(diff(double(wpict(1:testpatch(1),1:testpatch(2),:,:)),1,3));
	apd1 = mean(diffpart(:));
	if apd1 > tol
		sureis = false;
	else
		diffall = abs(diff(double(wpict),1,3));
		apd = mean(diffall(:));
		if apd > tol
			sureis = false;
		else
			sureis = true;
		end
	end
end


return


