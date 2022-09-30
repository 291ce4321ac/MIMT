function outpict = addborder(inpict,width,varargin)
%   ADDBORDER(INPICT, {WIDTH}, {COLOR}, {KEYS})
%   ADDBORDER(INPICT, {WIDTH}, {EDGETYPE})
%       Add a colored border to an image.  I find that the syntax and flexibility 
%       makes addborder far more convenient than PADARRAY. 
%
%   INPICT is an I/IA/RGB/RGBA/RGBAAA image; 4D images are supported
%   WIDTH specifies border width
%       values >= 1 are interpreted as a width in pixels
%       values < 1 are interpreted as a fraction of the image diagonal
%       default is 1.5% of image diagonal (0.015)
%       width can either be a scalar or a vector containing 2 or 4 elements
%       Scalar width specifies a uniform-width border (i.e. [top&bottom&left&right])
%       2-element width spec is [top&bottom left&right]
%       4-element width spec is [top bottom left right]
%   COLOR is either a scalar or a vector specifying the color of the border
%       color values are specified wrt the white value implied by the class of INPICT
%       vector may have 1, 2, 3, 4, or 6 elements (I, IA, RGB, RGBA, or RGBAAA)
%       scalar or underspecified vector inputs will be expanded where appropriate
%       color and alpha portions of the vector will be expanded independently as needed
%       overspecified COLOR vectors will result in the image being expanded accordingly
%       default color is black; default alpha is 100% (opaque)
%   KEYS currently include only 'normalized'
%       when 'normalized' is specified, COLOR is interpreted as having a white value of 1
%       instead of being dependent on the class of INPICT
%   EDGETYPE specifies an alternative to solid color padding
%       'replicate' replicates the edge vectors of the image
%       'reflect' mirrors the image about its edges (similar to 'symmetric' in padarray())
%       'circular' reflects the opposite image edge
%
%   CLASS SUPPORT: output type is inherited from input
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/addborder.html
% See also: padarrayFB, cropborder

normalized = false;
edgemodestrings = {'color','replicate','reflect','circular'};
edgemode = 'color';

[ncc nca] = chancount(inpict);
inclass = class(inpict);

% alpha should be 1 unless explicitly specified
cr = getrangefromclass(inpict);
color = cast([zeros([1 ncc]) cr(2)*ones([1 nca])],inclass);

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			color = thisarg;
		elseif ischar(thisarg)
			switch thisarg
				case 'normalized'
					normalized = true;
				case edgemodestrings
					edgemode = thisarg;
				otherwise
					error('ADDBORDER: unknown key %s',thisarg)
			end
		end
	end
end

[ncc nca] = chancount(inpict);
s = size(inpict);

if ~exist('width','var')
	width = 0.015;
end

width = abs(width);
if width < 1
	width = width*norm(s(1:2),2);
end

width = ceil(width);
switch numel(width)
	case 1
		width = [1 1 1 1]*width;
	case 2 
		width = [[1 1]*width(1) [1 1]*width(2)];
	case 4
		% nop
	otherwise
		error('ADDBORDER: WIDTH parameter must be either a scalar or a 2 or 4-element vector')
end


switch edgemode
	case 'color'
		if normalized
			[inpict color] = matchchannels(inpict,color,'normalized');
			color = imcast(color,inclass);
		else
			[inpict color] = matchchannels(inpict,color);
			color = cast(color,inclass);
		end

		oaw = [sum(width(1:2)) sum(width(3:4))];
		outpict = imones([s(1:2)+oaw size(inpict,3) size(inpict,4)],inclass);
		outpict = bsxfun(@times,outpict,ctflop(color));

		% describe image location with offsets
		picv = (width(1)+1):(width(1)+s(1));
		pich = (width(3)+1):(width(3)+s(2));
		outpict(picv,pich,:,:) = inpict;

	case 'replicate'
		mm = [ones([1 width(1)]) 1:s(1) ones([1 width(2)])*s(1)];
		outpict = inpict(mm,:,:,:,:);
		mm = [ones([1 width(3)]) 1:s(2) ones([1 width(4)])*s(2)];
		outpict = outpict(:,mm,:,:,:);
		
	case 'reflect'
		%mm=[width(1):-1:1 1:s(1) s(1):-1:(s(1)-width(2)+1)];
		subsbasis = [1:s(1) s(1):-1:1];
		mm = subsbasis(mod(-width(1):s(1)+width(2)-1,2*s(1)) + 1);
		outpict = inpict(mm,:,:,:,:);
		%mm=[width(3):-1:1 1:s(2) s(2):-1:(s(2)-width(4)+1)];
		subsbasis = [1:s(2) s(2):-1:1];
		mm = subsbasis(mod(-width(3):s(2)+width(4)-1,2*s(2)) + 1);
		outpict = outpict(:,mm,:,:,:);
		
	case 'circular'
		%mm=[(s(1)-width(2)+1):s(1) 1:s(1) 1:width(1)];
		subsbasis = 1:s(1);
		mm = subsbasis(mod(-width(1):s(1)+width(2)-1,s(1)) + 1);
		outpict = inpict(mm,:,:,:,:);
		%mm=[(s(2)-width(4)+1):s(2) 1:s(2) 1:width(3)];
		subsbasis = 1:s(2);
		mm = subsbasis(mod(-width(3):s(2)+width(4)-1,s(2)) + 1);
		outpict = outpict(:,mm,:,:,:);
		
end

end

