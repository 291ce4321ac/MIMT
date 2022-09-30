function inpict = imlnclite(inpict,varargin)
%   IMLNCLITE(INPICT, {OPTIONS})
%       Levels & Curves tool for images. This is a simplified version of IMLNC
%       for reduced memory requirements when operating on very large images. 
%       Required parameters can be determined using STRETCHLIMFB or IMMODIFY, 
%       using a smaller copy of the image if needed.
%
%   INPICT is an I/IA/RGB/RGBA image array.  4D images are not supported.
%
%   OPTIONS are specified as key-value pairs
%       'inrange' or 'in' specifies the input range [lo hi] (default [0 1])
%       'outrange' or 'out' specifies the output range [lo hi] (default [0 1])
%       'gamma' or 'g' specifies the gamma (default 1)
%       'contrast' or 'k' specifies the contrast amount (default 1)
%            When k>1, contrast is increased about the central gray value.
%            When k=1 and g=1, transfer curve is linear (default)
%       'chunksize' specifies the number of elements per chunk (default 25E6)
%            increasing chunk size increases peak memory requirements
%            excessively small chunk size will increase execution time
% 
%   Example test with a large (~1.5 GB) RGB test array:
%     giant=randi([0 255],[22400 22400 3],'uint8');
%     gargantuan=imlnclite(giant,'in',[0.1 0.9],'out',[0 1],'g',1.2,'k',2);
%   
%   CLASS SUPPORT:
%   Supports 'uint8', 'uint16', 'int16', 'single', and 'double'
%
%   See also: IMLNC, IMCOMPOSE, IMMODIFY, IMTWEAK, IMADJUSTFB, STRETCHLIMFB, TONEMAP.

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   MOD NOTES:
%
%   in order to be able to handle integer images without creating giant floating point temporary copies
%   this works by operating on small chunks of the image at a time
%   reducing the chunk size will shrink memory usage somewhat 
%
%   Example test with a large (~1.5 GB) RGB test array:
%     giant=ones([[1 1]*22400,3],'uint8')*128;
%     gargantuan=imlnclite(giant,'in',[0.1 0.9],'out',[0 1],'g',1.2,'k',2);
%
%   Observed execution time and peak memory usage for various chunk sizes:
%        5E3 elements: ~290s / 3.4GB   << chunk size is too small
%       25E6 elements:  ~70s / 3.7GB
%       50E6 elements:  ~70s / 4.1GB
%      100E6 elements:  ~70s / 4.9GB
%      200E6 elements:  ~70s / 5.5GB
%      400E6 elements: ~200s / 6.5GB   << this pushed me into swap usage

chunksize = 25E6; 
inrange = [0 1];
outrange = [0 1];
k = 1;
g = 1;

for vk = 1:2:length(varargin);
    switch lower(varargin{vk})
        case {'in','inrange'}
            inrange = reshape(varargin{vk+1},2,[]);
        case {'out','outrange'}
            outrange = reshape(varargin{vk+1},2,[]);
        case {'k','contrast'}
            k = varargin{vk+1};
        case {'g','gamma'}
            g = varargin{vk+1};
		case 'chunksize'
            chunksize = varargin{vk+1};
        otherwise
            error('IMLNCLITE: unknown input parameter name %s',varargin{vk})
    end
end

numchans = size(inpict,3);

if any(numchans == [2 4])
	alpha = inpict(:,:,end,:);
	inpict = inpict(:,:,end-1,:);
end

% try to minimize memory used for working image
if strcmp(class(inpict),'double')
	wclass = 'double';
else
	wclass = 'single';
end

% exponentiation doesn't work on integers neatly
% subdivide the image in some fashion, so as to minimize the size of the temporary FP working image
% this example works on chunks of a single channel at a time
imwidth = size(inpict,2);
chunkwidth = ceil(chunksize/imwidth); 

for ch = 1:size(inpict,3)
	for chunkidx = 1:chunkwidth:imwidth
		thischunk = chunkidx:min((chunkidx+chunkwidth),imwidth);
		wpict = inpict(:,thischunk,ch);
		[wpict inclass] = imcast(wpict,wclass);

		% CAN'T USE IMADJUSTFB just do this here to avoid the risk of using more memory in another scope
		wpict = ((wpict-inrange(1))./(inrange(2)-inrange(1)));
		wpict = max(min(wpict,1),0).^g;
		wpict = wpict.*(outrange(2)-outrange(1))+outrange(1);

		% DO CONTRAST 
		if k ~= 1
			c = 0.5;
			mk = abs(k) < 1;
			mc = c < 0.5;
			if ~xor(mk,mc)
				pp = k; kk = k*c/(1-c);
			else
				kk = k; pp = (1-c)*k/c;
			end

			% reuse mask instead of making two masks
			mask = wpict <= c; % < < lo
			wpict(mask) = 0.5*((1/c)*wpict(mask)).^kk;
			mask = wpict > c; % < < hi
			wpict(mask) = 1-0.5*((1-wpict(mask))*(1/(1-c))).^pp;
		end

		inpict(:,thischunk,ch) = imcast(wpict,inclass);
	end
end

if any(numchans == [2 4])
	inpict = cat(3,inpict,alpha);
end


end





































