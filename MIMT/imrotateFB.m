function outpict = imrotateFB(inpict,angle,varargin)
%   OUTPICT=IMROTATEFB(INPICT,ANGLE,{METHOD},{BOUNDARY})
%   Rotate an image array.
%
%   This is a passthrough to the IPT function imrotate(), with an internal 
%   fallback implementation to help remove the dependency of MIMT tools on the 
%   Image Processing Toolbox. As with other fallback tools, performance without 
%   IPT may be degraded or otherwise slightly different due to the methods used.
%
%   INPICT is an image array of any standard image class; 4D arrays are supported.
%   ANGLE specifies the rotation angle in degrees
%   METHOD specifies the type of interpolation (default 'bicubic')
%      'nearest' performs nearest-neighbor interpolation
%      'bilinear' performs bilinear interpolation
%      'bicubic' performs bicubic interpolation
%   BOUNDARY specifies how the output image geometry should be handled (default 'loose')
%      'loose' supplies the image geometry required to render the entire rotated image
%          this is typically larger than the original image geometry
%      'crop' supplies only the central content that lies within the original geometry
%          this typically results in image content being cropped
%   
%   Where no image data exists, the output image will be zero-padded.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imrotateFB.html
% See also: imrotate, imrectrotate

% IF IPT IS INSTALLED
% FB method is actually significantly faster for orthogonal rotations, so just use it instead
if false%license('test', 'image_toolbox') && mod(angle,90) ~= 0
	outpict = imrotate(inpict,angle,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

methodstrings = {'nearest','bilinear','bicubic'};
method = 'bicubic';
boundarystrings = {'loose','crop'};
boundary = 'loose';

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		switch lower(varargin{k})
			case methodstrings
				method = lower(varargin{k});
				k = k+1;
			case boundarystrings
				boundary = lower(varargin{k});
				k = k+1;
			otherwise
				error('IMROTATEFB: unrecognized argument %s',varargin{k})
		end
	end
end


testortho = mod(angle/90,4);
switch testortho
	case 0 % no rotation
		outpict = inpict;
		
	case {1 2 3} % any orthogonal rotation
		if ifversion('<','R2014a')
			s0 = imsize(inpict);
			if testortho == 2
				outpict = imzeros(s0,class(inpict));
			else
				outpict = imzeros(s0([2 1 3 4]),class(inpict));
			end
			for f = 1:s0(4)
				for c = 1:s0(3)
					outpict(:,:,c,f) = rot90(inpict(:,:,c,f),testortho);
				end
			end
		else
			outpict = rot90(inpict,testortho);
		end
		
	otherwise % any non-orthogonal rotation
		[inpict inclass] = imcast(inpict,'double');
		s0 = imsize(inpict);
		
		% tweaking padding seems to help match the exact behavior of IPT imrotate(), particularly for square images
		% i know they only use a fixed 2px padding, but it's probably a difference in the interpolators or the setup
		% matching these subtleties is probably pointless, considering that anybody using this can't compare it against IPT
		p = [-0.0205668 1.85101 0.058871];
 		padsize = round(polyval(p,mod(angle,90))*s0(1:2)/200);
		inpict = padarrayFB(inpict,padsize,0,'both');
		s = imsize(inpict,2);

		% calculate output image geometry
		switch boundary
			case 'loose'
				% this matches imrotate for most cases (~98% depending on size, aspect ratio)
				% every now and then it'll be off by one pixel
				% i'm not chasing that stupid rabbit
				% believe it or not, this is about 10x as fast as just taking the corner coordinates
				% and then rotating them to find the new extents.
				initialangle = atand(s0(1)/s0(2));
				appliedangle = mod(angle,90);
				quadrant = floor(angle/90+1);
				bbox = [sind(appliedangle+initialangle) cosd(appliedangle-initialangle)];
				if mod(quadrant,2) == 0
					bbox = fliplr(bbox);
				end
				os0 = ceil(sqrt(sum(s0.^2)).*bbox);

			case 'crop'
				os0 = s0(1:2);

		end
		
		
		% input coordinate space
 		x0 = linspace(-s(2)/2,s(2)/2,s(2));
 		y0 = linspace(-s(1)/2,s(1)/2,s(1));
		[X0 Y0] = meshgrid(x0,y0);
		
		% output coordinate space
		x = linspace(-os0(2)/2,os0(2)/2,os0(2));
		y = linspace(-os0(1)/2,os0(1)/2,os0(1));
		[XX YY] = meshgrid(x,y);
				
		% rotate subs
		RR = sqrt(XX.^2 + YY.^2);
		AA = atan2(YY,XX)+angle*pi/180;
		XX = RR.*cos(AA);
		YY = RR.*sin(AA);
		
		% interpolate
		outpict = imzeros([os0(1:2) s0(3:4)]);
		for f = 1:s0(4)
			for c = 1:s0(3)
				outpict(:,:,c,f) = interp2(X0,Y0,inpict(:,:,c,f),XX,YY,method,0);
			end
		end
		outpict = imcast(outpict,inclass);

end









