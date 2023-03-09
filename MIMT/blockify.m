function  outpict = blockify(inpict,amount,mode)
%   BLOCKIFY(INPICT, PIXELSIZE, {MODE})
%       does a simple spatial downsampling of the image (pixelation)
%       with support for independent axis and channel scaling
%   
%   INPICT is an I/RGB image of any standard image class
%       multiframe images are supported
%   PIXELSIZE specifies superpixel size and can be specified four ways:
%       specify as a scalar for square superpixels (common use)
%       specify as a 2-element vector for non-square superpixels ([height width])
%       specify as a 3-element vector for channel-independent square superpixels
%       specify as a 3x2 array for channel-independent non-square superpixels 
%       i.e. [Ry Rx; Gy Gx; By Bx] or [Hy Hx; Sy Sx; Vy Vx]
%   MODE is 'rgb', 'hsl', 'hsy', or 'hsv' (default is 'rgb')
%
%   Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/blockify.html

% this function includes fallback method to allow operation without IPT installed
% using this fallback will be slower
        
if ~exist('mode','var')
    mode = 'rgb';
end

if numel(amount) == 1
    amount = ones(3,2)*amount;
elseif numel(amount) == 2
    amount = repmat(reshape(amount,1,2),[3 1]);
elseif numel(amount) == 3
    amount = repmat(reshape(amount,3,1),[1 2]);
end

pictsize = size(inpict);
outpict = zeros(pictsize);
[inpict inclass] = imcast(inpict,'double');

switch mode
	case 'rgb'
		for f = 1:1:size(inpict,4)
			for c = 1:1:size(inpict,3)
				outpict(:,:,c,f) = resamplechan(inpict(:,:,c,f),amount(c,:));
			end
		end
	case 'hsl'
		for f = 1:1:size(inpict,4)
			hpict = rgb2hsl(inpict(:,:,:,f));

			% this is to avoid finding means of circular data
			htemp = rgb2hsl(resamplechan(inpict,amount(1,:)));
			hpict(:,:,1) = htemp(:,:,1);
			hpict(:,:,2) = resamplechan(hpict(:,:,2),amount(2,:));
			hpict(:,:,3) = resamplechan(hpict(:,:,3),amount(3,:));

			outpict(:,:,:,f) = hsl2rgb(hpict);
		end
	case 'hsv'
		for f = 1:1:size(inpict,4)
			hpict = rgb2hsv(inpict(:,:,:,f));

			% this is to avoid finding means of circular data
			htemp = rgb2hsv(resamplechan(inpict,amount(1,:)));
			hpict(:,:,1) = htemp(:,:,1);
			hpict(:,:,2) = resamplechan(hpict(:,:,2),amount(2,:));
			hpict(:,:,3) = resamplechan(hpict(:,:,3),amount(3,:));

			outpict(:,:,:,f) = hsv2rgb(hpict);
		end
	case 'hsy'
		for f = 1:1:size(inpict,4)
			hpict = rgb2hsy(inpict(:,:,:,f));

			% this is to avoid finding means of circular data
			htemp = rgb2hsy(resamplechan(inpict,amount(1,:)));
			hpict(:,:,1) = htemp(:,:,1);
			hpict(:,:,2) = resamplechan(hpict(:,:,2),amount(2,:));
			hpict(:,:,3) = resamplechan(hpict(:,:,3),amount(3,:));

			outpict(:,:,:,f) = hsy2rgb(hpict);
		end
	otherwise
		disp('BLOCKIFY: no valid mode')
end 

outpict = imcast(outpict,inclass);
    
function outchan = resamplechan(inchan,bs)
	% IF IPT IS INSTALLED
	if hasipt()
		ctemp = imresize(inchan,round(pictsize(1:2)./bs));
        outchan = imresize(ctemp,pictsize(1:2),'nearest');
	else 
		% blockwise averaging
		outchan = ones(size(inchan));
		bc = ceil(pictsize(1:2)./bs);
		for m = 1:bc(1)
			for n = 1:bc(2)
				brows = ((m-1)*bs(1)+1):min(m*bs(1),pictsize(1));
				bcols = ((n-1)*bs(2)+1):min(n*bs(2),pictsize(2));
				meanc = mean(mean(inchan(brows,bcols,:),1),2);
				outchan(brows,bcols,:) = bsxfun(@times,outchan(brows,bcols,:),meanc);
			end
		end
	end
	outchan = min(max(outchan,0),1);
end

end










