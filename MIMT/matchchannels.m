function [outpict outcolor] = matchchannels(inpict,incolor,varargin)
%   [OUTPICT OUTCOLOR]=MATCHCHANNELS(INPICT,INCOLOR,{KEYS})
%       Force correspondence between a color tuple and an image array.  This is
%       useful when a color needs to be specified for use in an image.  MATCHCHANNELS
%       performs expansion of the color tuple and/or the image as required for both
%       to share the same arrangement of color and alpha channels.
%
%   INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%       Multiframe images are supported.
%   INCOLOR is either a scalar or a vector specifying a color intended for use in INPICT
%		Color values are specified wrt the white value implied by the class of INPICT.
%       Vector may have 1, 2, 3, 4, or 6 elements (I, IA, RGB, RGBA, or RGBAAA).
%       Scalar or underspecified vector inputs will be expanded where appropriate.
%       Color and alpha portions of the vector will be expanded independently as needed.
%       Overspecified COLOR vectors will result in the image being expanded accordingly.
%       Default alpha is 100% (opaque)
%   KEYS currently include only 'normalized'
%       When 'normalized' is specified, COLOR is interpreted as having a white value of 1
%       instead of being dependent on the class of INPICT.  If specified, OUTCOLOR will 
%       adhere to the same format, and will accordingly be cast as 'double'.
%
%   Class of OUTPICT is inherited from INPICT.

% i kind of faked KVP support
if numel(varargin)==0
	normalized = false;
else
	normalized = true;
end

[ncc nca] = chancount(inpict);
inclass = class(inpict);
extrema = [0 1];
cr = imrescale(extrema,'double',inclass);
if normalized
	tclass = 'double';
else 
	tclass = inclass;
end
ctr = imrescale(extrema,'double',tclass);
incolor = cast(incolor,tclass);

if all(nca ~= [0 1 3])
	error('MATCHCHANNELS: Expected an image with 0, 1, or 3 alpha channels.  Image appears to have %d color channels and %d alpha channels.  Expected channel arrangements are I, IA, RGB, RGBA, or RGBAAA.  What is this?',ncc,nca);
end

[nccspec ncaspec] = chancount(reshape(incolor,[1 1 numel(incolor)]));
if all(ncaspec ~= [0 1 3])
	error('MATCHCHANNELS: Expected a color spec with 0, 1, or 3 alpha channels.  Image appears to have %d color channels and %d alpha channels.  Expected channel arrangements are I, IA, RGB, RGBA, or RGBAAA.  What is this?',nccspec,ncaspec);
end

if nccspec < ncc
	if nccspec == 1 
		% expand if spec color is a simple scalar (legacy compatibility)
		cc = incolor(1).*imones([1 ncc],tclass);
	else
		% otherwise, intent is ambiguous; barf an error
		error('MATCHCHANNELS: Image has more color channels than are specified in the COLOR vector');
	end
elseif nccspec > ncc
	if nccspec == 3 && ncc == 1 
		% expand image if color spec is RGB/RGBA and image is I/IA
		if nca == 0
			inpict = inpict(:,:,[1 1 1],:);
		else
			inpict = inpict(:,:,[1 1 1 (ncc+1):(ncc+nca)],:);
		end
		ncc = 3;
		cc = incolor(1:ncc);
	else
		% otherwise, intent is ambiguous; barf an error
		error('MATCHCHANNELS: Image has fewer color channels than are specified in the COLOR vector');
	end
else % when nccspec == ncc
	cc = incolor(1:ncc);
end
[ncc nca] = chancount(inpict);	

ca = [];
if ncaspec < nca
	% add alpha channel(s) to color
	if ncaspec == 0
		ca = ctr(2).*imones([1 nca],tclass);
	elseif ncaspec == 1
		ca = incolor(end).*imones([1 nca],tclass);
	end
elseif ncaspec > nca
	% add alpha channel(s) to image
	if nca == 0 % add alpha
		inpict = cat(3,inpict,cr(2).*imones([size(inpict,1) size(inpict,2) ncaspec size(inpict,4)],inclass));
	elseif nca == 1 % expand alpha
		inpict = cat(3,inpict(:,:,1:ncc,:),repmat(inpict(:,:,ncc+1,:),[1 1 nccspec]));
	end
	ca = incolor((nccspec+1):end);
else
	ca = incolor((nccspec+1):end);
end

outcolor = [cc ca];
outpict = inpict;

end


























