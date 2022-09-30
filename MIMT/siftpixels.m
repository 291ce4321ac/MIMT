function outpict = siftpixels(A,varargin)
%  OUTPICT = SIFTPIXELS(INPICT,{GRAVITY})
%    Migrate non-NaN elements of an image in a specified direction.
%    Like sifting grains of sand, non-NaN image content is consolidated
%    and separated from NaN elements.  
%
%  INPICT is an image of floating-point class.  Multichannel and
%    multiframe images are supported.  
%  GRAVITY optionally specifies the direction to shift non-NaN pixels.
%    Modes include cardinal directions 'n','s','e','w' (default 's')
%    Mode 'v' will shift pixels vertically toward the horizontal centerline.
%    Mode 'h' will shift pixels horizontally toward the vertical centerline.
%    Mode 'c' will shift pixels radially toward the center of the image.
%    If any mode has a '-' appended, the sort direction will be reversed.
%    Alternatively, the user may supply a 2-element vector specifying the 
%    location of a center point in image coordinates [pixelsy pixelsx].  
%    The point must lie within the boundaries of the image.  If either element
%    is negative, the sifting direction will be reversed (away from the point).
%    Radial modes are quite slow, especially with large multichannel images.
%
%  Output class is 'double'
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/siftpixels.html
%  See also: imannrotate, thresholdinpaint

gravitystr = {'n','s','e','w','v','h','c'};
gravity = 's';
invert = false;

sz0 = imsize(A);

if numel(varargin)>0
	thisarg = varargin{1};
	if ischar(thisarg)
		if ~isempty(strfind(thisarg,'-')) %#ok<STREMP>
			invert = true;
			thisarg = strrep(thisarg,'-','');
		end
		if strismember(lower(thisarg),gravitystr)
			gravity = lower(thisarg);
		else
			error('SIFTPIXELS: unknown gravity %s',thisarg)
		end
	elseif isnumeric(thisarg) && numel(thisarg) == 2
		if any(thisarg<0)
			invert = true;
		end
		gravity = 't';
		cen = abs(thisarg);
		if any(cen(:)<1 | cen(:)>sz0(1:2)')
			error('SIFTPIXELS: specified gravity center is outside of image geometry')
		end
	end
end

% if there are no nan pixels, there's nothing to do.
if ~strismember(class(A),{'double','single'}) || nnz(isnan(A)) == 0
	outpict = A;
	return;
end
	
outpict = zeros(sz0);
for f = 1:sz0(4)
	thisframe = A(:,:,:,f);
	if ~invert
		switch gravity
			case 'n'
				outpict(:,:,:,f) = sift_n(thisframe);
			case 's'
				outpict(:,:,:,f) = sift_s(thisframe);
			case 'e'
				outpict(:,:,:,f) = sift_e(thisframe);
			case 'w'
				outpict(:,:,:,f) = sift_w(A);
			case 'v'
				sp = floor(sz0(1)/2);
				C1 = sift_s(thisframe(1:sp,:,:));
				C2 = sift_n(thisframe(sp+1:end,:,:));
				outpict(:,:,:,f) = [C1; C2];
			case 'h'
				sp = floor(sz0(2)/2);
				C1 = sift_e(thisframe(:,1:sp,:));
				C2 = sift_w(thisframe(:,sp+1:end,:));
				outpict(:,:,:,f) = [C1 C2];
			case 'c'
				cen = round(sz0(1:2)/2);
				outpict(:,:,:,f) = sift_toward(thisframe,cen);
			case 't'
				outpict(:,:,:,f) = sift_toward(thisframe,cen);
			otherwise
				% this should never happen since keys are matched
				error('SIFTPIXELS: unknown gravity %s',gravity)
		end
	else
		switch gravity
			case 'n'
				outpict(:,:,:,f) = sift_s(thisframe);
			case 's'
				outpict(:,:,:,f) = sift_n(thisframe);
			case 'e'
				outpict(:,:,:,f) = sift_w(thisframe);
			case 'w'
				outpict(:,:,:,f) = sift_e(A);
			case 'v'
				sp = floor(sz0(1)/2);
				C1 = sift_n(thisframe(1:sp,:,:));
				C2 = sift_s(thisframe(sp+1:end,:,:));
				outpict(:,:,:,f) = [C1; C2];
			case 'h'
				sp = floor(sz0(2)/2);
				C1 = sift_w(thisframe(:,1:sp,:));
				C2 = sift_e(thisframe(:,sp+1:end,:));
				outpict(:,:,:,f) = [C1 C2];
			case 'c'
				cen = round(sz0(1:2)/2);
				outpict(:,:,:,f) = sift_away(thisframe,cen);
			case 't'
				outpict(:,:,:,f) = sift_away(thisframe,cen);
			otherwise
				% this should never happen since keys are matched
				error('SIFTPIXELS: unknown gravity %s',gravity)
		end
	end
end

end % END MAIN SCOPE



function C = sift_n(A) % NORTH
	sz = size(A);
	C = NaN(sz);
	for c = 1:sz(3)
		for col = 1:sz(2)
			thisvec = A(:,col,c);
			thisvec = thisvec(~isnan(thisvec));
			C(1:numel(thisvec),col,c) = thisvec; % N
		end
	end
end

function C = sift_s(A) % SOUTH
	sz = size(A);
	C = NaN(sz);
	for c = 1:sz(3)
		for col = 1:sz(2)
			thisvec = A(:,col,c);
			thisvec = thisvec(~isnan(thisvec));
			C(end-numel(thisvec)+1:end,col,c) = thisvec; % S
		end
	end
end

function C = sift_e(A) % EAST
	sz = size(A);
	C = NaN(sz);
	for c = 1:sz(3)
		for row = 1:sz(1)
			thisvec = A(row,:,c);
			thisvec = thisvec(~isnan(thisvec));
			C(row,end-numel(thisvec)+1:end,c) = thisvec; % E
		end
	end
end

function C = sift_w(A) % WEST
	sz = size(A);
	C = NaN(sz);
	for c = 1:sz(3)
		for row = 1:sz(1)
			thisvec = A(row,:,c);
			thisvec = thisvec(~isnan(thisvec));
			C(row,1:numel(thisvec),c) = thisvec; % W
		end
	end
end

function A = sift_toward(A,cen0) % sift toward a given point
	sz = size(A);
	for d = 1:4
		cen = rotatecenter(cen0,d,sz);
		for c = 1:sz(3)
			thispage = A(:,:,c);
			for v = 1:sz(1)
				linemask = plainline(sz(1:2),[v 1],cen);
				sampvec = thispage(linemask); % sample A along that line
				outvec = NaN(size(sampvec)); % allocate
				sampvec = sampvec(~isnan(sampvec)); % only get good pixels
				outvec(end-numel(sampvec)+1:end) = sampvec; % sift vector
				thispage(linemask) = outvec; % replace 
			end
			A(:,:,c) = thispage;
		end
		A = rot90(A);
		sz = size(A);
	end
end

function A = sift_away(A,cen0) % sift away from a given point
	sz = size(A);
	for d = 1:4
		cen = rotatecenter(cen0,d,sz);
		for c = 1:sz(3)
			thispage = A(:,:,c);
			for v = 1:sz(1)
				linemask = plainline(sz(1:2),[v 1],cen);
				sampvec = thispage(linemask); % sample A along that line
				outvec = NaN(size(sampvec)); % allocate
				sampvec = sampvec(~isnan(sampvec)); % only get good pixels
				outvec(1:numel(sampvec)) = sampvec; % sift vector
				thispage(linemask) = outvec; % replace 
			end
			A(:,:,c) = thispage;
		end
		A = rot90(A);
		sz = size(A);
	end
end

function newcen = rotatecenter(cen,d,sz)
	switch d
		case 1
			newcen = cen;
		case 2
			newcen = [sz(1)-cen(2)+1 cen(1)];
		case 3
			newcen = [sz(1)-cen(1)+1 sz(2)-cen(2)+1];
		case 4
			newcen = [cen(2) sz(2)-cen(1)+1];
	end
end

function mk = plainline(sz,pt0,pt1)
	% can plot steep lines okay
	mk = false(sz);
	for n = 0:(1/round(sqrt((pt1(2)-pt0(2))^2+(pt1(1)-pt0(1))^2))):1
		xn = round(pt0(2) +(pt1(2) - pt0(2))*n);
		yn = round(pt0(1) +(pt1(1) - pt0(1))*n);
		mk(yn,xn,:) = true;
	end
end








