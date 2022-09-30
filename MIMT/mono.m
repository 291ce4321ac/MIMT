function outpict = mono(inpict,channel,weights)
%   MONO(INPICT,CHANNEL,{WEIGHTS})
%       Extracts a single channel from RGB images or triplets
%
%   INPICT is an RGB/RGBA image. Multiframe images are supported
%       If INPICT is I/IA, it will be expanded and processed as usual, 
%       though the results may be trivial.
%       INPICT may also be a single RGB color tuple or a color table
%       Color tuples are expected to be 1x3 row vectors (RGB)
%       Color tables are expected to be Mx3 (RGB)
%   CHANNEL is a string specifying the channel to extract
%       'r', 'g', 'b' corresponding to the channels of RGB
%       'h', 'hhsv', 's', 'shsv', 'v', 'vhsv' for HSV
%       'hhsl', 'shsl', 'l', 'lhsl' for HSL
%       'hhsi', 'shsi', 'i', 'ihsi' for HSI
%       'y' or 'y601' for BT470/601 luma
%       'y709 for BT709 luma
%       'l lch', 'c lch', 'h lch' correspond to LCH from CIELCHab 
%       'h husl', 's husl', 'l husl' correspond to HSL from HuSLuv
%       'wsrgb', 'wshsy', 'wslch' allow calculation of arbitrary weighted channel sums
%   WEIGHTS is a 3-element vector specifying the weights for weighted sum modes
%       vector will be automatically normalized if not already so
%       example: mono(inpict,'wsrgb',[299 587 114]) is the same as mono(inpict,'y') 
%       
%   CLASS SUPPORT:
%       Accepts images of any standard image class
%       Return type is inherited from INPICT
%
%   See also: gray2rgb


channel = lower(channel(channel ~= ' '));
if numel(channel) > 2 && strcmp(channel(1:2),'ws')
	if ~exist('weights','var')
		error('MONO: weighted sum modes require a vector specifying channel weights')
	else 
		if numel(weights) ~= 3
			error('MONO: WEIGHTS must be a 3-element row vector')
		end
		% force the weighting vector to be normalized
		weights = reshape(weights,[1 3])./sum(weights);
	end
end

[ncc nca] = chancount(inpict);
if nca == 1
	inalpha = inpict(:,:,end,:);
	inpict = inpict(:,:,1:ncc,:);
elseif nca > 1
	error('MONO: expected INPICT to be RGB/RGBA')
end

% if fed an I/IA image, expand it for sake of consistency
inpict = gray2rgb(inpict);

% is the image argument a color or a picture?
if size(inpict,2) == 3 && numel(size(inpict)) < 3
    inpict = ctflop(inpict);
	outsize = [size(inpict,1) 1 1 size(inpict,4)];
else
	outsize = [size(inpict,1) size(inpict,2) 1 size(inpict,4)];
end

% output type is inherited from input
inclass = class(inpict);
if ~isempty(find(strcmp(channel,{'r','g','b','v'}),1))
	trivialmode = true;
	outpict = imzeros(outsize,inclass);
else
	trivialmode = false;
	inpict = imcast(inpict,'double');
	outpict = imzeros(outsize,'double');
end


for f = 1:size(inpict,4)
	switch channel
		case 'r'
            wpict = inpict(:,:,1,f);
		case 'g'
            wpict = inpict(:,:,2,f);    
		case 'b'
            wpict = inpict(:,:,3,f);  
		case {'h','hhsv','hhsl'}
            wpict = inpict(:,:,:,f);
            R = wpict(:,:,1);
            G = wpict(:,:,2);
            B = wpict(:,:,3);
            M = max(wpict,[],3);
            D = M-min(wpict,[],3);
            D = D+(D == 0);
            H = zeros(size(R));

            rm = wpict(:,:,1) == M;
            gm = wpict(:,:,2) == M;
            bm = wpict(:,:,3) == M;
            %bm=~(rm | gm);
            H(rm) = (G(rm)-B(rm))./D(rm);
            H(gm) = 2+(B(gm)-R(gm))./D(gm);
            H(bm) = 4+(R(bm)-G(bm))./D(bm);

            H = H/6;
            ltz = H < 0;
            H(ltz) = H(ltz)+1;
            H(D == 0) = NaN;
            wpict = H;
		case {'s','shsv'}
            wpict = inpict(:,:,:,f);
            mx = max(wpict,[],3);
            mn = min(wpict,[],3);
			wpict = (mx-mn)./(mx+(mx == 0));
		case {'v','vhsv'}
            wpict = max(inpict(:,:,:,f),[],3);
		case 'shsl'
			wpict = inpict(:,:,:,f);
			mn = min(wpict,[],3);
			mx = max(wpict,[],3);
			L = (mn+mx)/2;

			D = mx-mn;
			K = min(L,1-L);
			m = (K == 0);
			wpict = D./(2*(K+m));
		case 'hhsi'
			wpict = rgb2hsi(inpict(:,:,:,f));
			wpict = wpict(:,:,1)/360;
		case 'shsi'
			wpict = rgb2hsi(inpict(:,:,:,f));
			wpict = wpict(:,:,2);
		case {'l','lhsl'}
            wpict = inpict(:,:,:,f);
            mx = max(wpict,[],3);
            mn = min(wpict,[],3);
            wpict = (mx+mn)/2;
		case {'i','ihsi'}
            wpict = inpict(:,:,:,f);
            wpict = mean(wpict,3);
		case {'y','y601'}
			factors = gettfm('y','601');
			wpict = imappmat(inpict(:,:,:,f),factors);
		case 'y709'
			factors = gettfm('y','709');
			wpict = imappmat(inpict(:,:,:,f),factors);
		case {'llch','lhusl'} % L is identical in both cases
			A = rgb2lch(inpict(:,:,:,f),'lab');
            wpict = A(:,:,1)/100;
		case 'clch'
			A = rgb2lch(inpict(:,:,:,f),'lab');
            wpict = A(:,:,2)/134.2;
		case 'hlch'
            A = rgb2lch(inpict(:,:,:,f),'lab');
            wpict = A(:,:,3)/360;
		case 'hhusl'
            A = rgb2husl(inpict(:,:,:,f));
            wpict = A(:,:,1)/360;
		case 'shusl'
            A = rgb2husl(inpict(:,:,:,f));
            wpict = A(:,:,2)/100;
		case 'wsrgb'
			factors = ctflop(weights);
			wpict = sum(bsxfun(@times,inpict(:,:,:,f),factors),3);
		case 'wshsy'
			A = rgb2hsy(inpict(:,:,:,f));
			factors = ctflop(weights.*1./[360 1 1]);
			wpict = sum(bsxfun(@times,A,factors),3);
		case 'wslch'
			A = rgb2lch(inpict(:,:,:,f),'lab');
			factors = ctflop(weights.*1./[360 100 100]);
			wpict = sum(bsxfun(@times,A,factors),3);
		otherwise
            disp('MONO: unsupported channel string')
            return
	end
	outpict(:,:,:,f) = wpict;
end

if ~trivialmode
	outpict = imcast(outpict,inclass);
end

if nca == 1
	outpict = cat(3,outpict,inalpha);
end

return





