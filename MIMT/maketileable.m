function inpict = maketileable(inpict,tiling,varargin)
% OUTPICT=MAKETILEABLE(INPICT,TILING,{METHOD},{INTERPOLATION},{REVERTSIZE})
%    Adjust the geometry of an image so that its height and width
%    are integer-divisible by given numbers.  If dimensions are already
%    integer-divisible, no adjustments are made.
%    
%    INPICT is an I/IA/RGB/RGBA image of any standard image class
%    TILING is a 2-element vector of integers by which the image geometry 
%       is to be made divisible
%    METHOD specifies how image size should be adjusted
%       'grow' replicates edge vectors to fit
%       'trim' deletes edge vectors to fit 
%       'fit' selects best of either 'grow' or 'trim' behaviors (default)
%       'scale' simply scales the image to the nearest fit
%           when using 'scale', the interpolation method can also be selected
%           'bicubic' (default), 'bilinear', and 'nearest' are supported
%    REVERTSIZE specifies the size of the original image. (2-element vector)
%       This option is used to undo the modification normally performed by
%       maketileable(). 
%
%   Output class is inherited from INPICT
%
%   Example:
%      Make an image tileable and then revert it after some operations:
%      A = maketileable(inpict,[3 4],'scale');
%      A = supercoolfunctionthatdoesthings(A);
%      B = maketileable(A,[3 4],'scale','revertsize',imsize(inpict,2));
%
%   See also: imtile, imdetile, imfold

methodstrings = {'fit','scale','grow','trim'};
method = 'fit';
interpolantstrings = {'bicubic','nearest','linear'};
interpolant = 'bicubic';
revert = false;
revertsize = [1 1];

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		switch lower(varargin{k})
			case methodstrings
				method = lower(varargin{k});
				k = k+1;
			case interpolantstrings
				interpolant = lower(varargin{k});
				k = k+1;
			case 'revertsize'
				revert = true;
				revertsize = varargin{k+1};
				k = k+2;
			otherwise
				error('MAKETILEABLE: unknown input parameter name %s',varargin{k})
		end
	end
end

if numel(tiling) ~= 2
	error('MAKETILEABLE: expected a 2-element vector for TILING parameter')
else
	Ntiles = round(tiling);
end

if numel(revertsize) < 2
	error('MAKETILEABLE: expected a 2-element vector for REVERTSIZE parameter')
else 
	revertsize = revertsize(1:2);
end

% if reverting, mod(s,Ntiles) should be [0 0], but it doesn't necessarily have to be

% ADJUST DIMENSIONS ====================================================
s = imsize(inpict,2);
if revert
	Pgrow = max(revertsize-s,0);
	Ptrim = max(s-revertsize,0);
	needsadjusted = any(Pgrow ~= 0) || any(Ptrim ~= 0);
else
	Pgrow = Ntiles-mod(s,Ntiles);
	Ptrim = Ntiles-Pgrow;
	needsadjusted = any(Pgrow ~= Ntiles);
end
%[s; Ntiles; Pgrow; Ptrim]

if needsadjusted
	if strismember(method,{'fit','grow','trim'})
		for dim = 1:2
			if revert
				growthisdim = Pgrow(dim) > 0;
			else
				growthisdim = Pgrow(dim) <= Ptrim(dim) || strcmp(method,'grow');
				growthisdim = growthisdim && ~strcmp(method,'trim');
			end
						
			if growthisdim
				% grow
				if dim == 1
					inpict = cat(dim,repmat(inpict(1,:,:),[floor(Pgrow(dim)/2) 1 1]),...
						inpict,repmat(inpict(end,:,:),[ceil(Pgrow(dim)/2) 1 1]));
				else
					inpict = cat(dim,repmat(inpict(:,1,:),[1 floor(Pgrow(dim)/2) 1]),...
						inpict,repmat(inpict(:,end,:),[1 ceil(Pgrow(dim)/2) 1]));
				end
			else
				% trim
				if dim == 1
					inpict = inpict(1+floor(Ptrim(dim)/2):end-ceil(Ptrim(dim)/2),:,:);
				else
					inpict = inpict(:,1+floor(Ptrim(dim)/2):end-ceil(Ptrim(dim)/2),:);
				end
			end
		end
	else % scale
		if revert
			Pd = Pgrow-Ptrim;
		else
			Pd = [0 0];
			for dim = 1:2 
				[~,idx] = min([Pgrow(dim) Ptrim(dim)]);
				if idx == 1; Pd(dim) = Pgrow(dim); else Pd(dim) = -Ptrim(dim); end
			end
		end
		inpict = imresizeFB(inpict,s+Pd,interpolant);
	end
end




































