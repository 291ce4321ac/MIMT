function outpict = gbcam(inpict,cmode,upscale)
%  OUTPICT = GBCAM(INPICT,{CMODE},{SCALE})
%  Emulate the appearance of a photo taken with a Nintendo GameBoy camera.
%  
%  Images are centered, scaled, and cropped to fit the output frame. If you want 
%  your image located differently, prepare it accordingly.
%
%  You may find that many images could use contrast or gamma adjustment prior 
%  to being processed.  No attempt has been made to duplicate the thresholding 
%  coefficient matrix used by the original device.  This is just a novelty.
%
%  INPICT is a I/RGB image of any standard image class.  
%  CMODE specifies the colormap to be applied (default 'newschool')
%    'newschool' is a grayish tan-green, like a GBpocket screen.
%    'oldschool' is lime and olive green, like an original GB.
%    'gray' is a balance between 'brigray' and 'unigray', with muted extrema.
%    'brigray' is a commonly-used bright gray map with about 0.68 gamma.
%    'unigray' is a uniform (linear) gray map.
%    Alternatively, CMODE may be a user-supplied colormap.  If a custom
%    map is supplied, it must be a 4x3 unit-scale floating point array.
%  SCALE optionally specifies the output scaling (default 3)
%    Specify 1 for the native output size of [112 128]
%
%  Output class is uint8
%
%  See also: uniquant(), gray2pcolor()

% defaults
if nargin < 3; upscale = 3; end
if nargin < 2; cmode = 'newschool'; end

inpict = mono(inpict,'y');

sz = imsize(inpict,2);
szo = [112 128];

if ~isequal(sz,szo)
	% if image isn't already the right size, resize/crop it
	ari = sz(1)/sz(2); % get aspect ratios
	aro = szo(1)/szo(2);
	
	if ari>aro 
		% image is taller/narrower than output frame
		inpict = imresize(inpict,[NaN szo(2)]);
		offset = floor((size(inpict,1)-szo(1))/2);
		inpict = inpict(offset + (1:szo(1)),:);
	else
		% image is shorter/wider than output frame
		inpict = imresize(inpict,[szo(1) NaN]);
		offset = floor((size(inpict,2)-szo(2))/2);
		inpict = inpict(:,offset + (1:szo(2)));
	end
end

% get whatever colormap the user wants
if isnumeric(cmode)
	if size(cmode,2)~=3 || size(cmode,1)~=4
		error('GBCAM: expected CMODE to be a 4x3 color table')
	elseif min(cmode(:))<0 || max(cmode(:))>1
		error('GBCAM: expected CMODE to be in unit-scale floating point')
	else
		CT = cmode;
	end
elseif ischar(cmode)
	switch cmode
		case 'gray'
			% this is roughly gamma=0.8 applied to a linear sweep over [5 227]/255
			CT = [5 5 5; 95 95 95; 165 165 165; 227 227 227]/255;
		case 'brigray'
			% this is the most common map found in photos posted online
			% this is roughly gamma=0.68 applied to a linear sweep over [0 1]
			CT = [0 0 0; 128 128 128; 192 192 192; 255 255 255]/255;
		case 'unigray'
			% linear scale from [0 1]
			CT = [0 0 0; 85 85 85; 170 170 170; 255 255 255]/255;
		case 'newschool'
			% the GBpocket, etc had a (more or less) gray screen, but practical influences
			% (the color of surrounding illuminated surfaces) tend to skew the perceived tone
			% as much as anything else (e.g. the polarizer) does.
			CT = [46 52 32; 100 110 68; 178 190 129; 227 237 190]/255;
		case 'oldschool'
			% the old GB screens were an unsubtle green
			%CT = [0 59 61; 24 109 66; 47 160 72; 71 210 77]/255;
			CT = [0 59 61; 28 119 67; 53 172 73; 71 210 77]/255; % a bit brighter
		otherwise
			error('GBCAM: unknown CMODE option %s',cmode)
	end
else
	error('GBCAM: expected CMODE to either be a mode name or a Mx3 color table')
end

% this is the core operation
outpict = gray2pcolor(inpict,CT,imclassrange(class(inpict)),'orddither'); % quantize, apply CT
outpict = imresize(outpict,upscale,'nearest'); % resize if desired
outpict = imcast(outpict,'uint8'); % cast and rescale


















