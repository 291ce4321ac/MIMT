function outpict = imecho(inpict,nechoes,varargin)
%   IMECHO(INPICT, NECHOES, {OPTIONS})
%       blends delayed frame copies with an image animation
%
%   INPICT is a multiframe I/IA/RGB/RGBA image of any standard image class
%   NECHOES is the number of image copies to be blended
%   OPTIONS include the following keys and key-value pairs:
%      'blendmode' is an image blend mode string (see IMBLEND())
%      'skip' specifies the spacing of image copies (default 1)
%      'offset' is a vector specifying frame offsets per channel
%      'diffmode' causes blend operations to occur on the difference of frames
%      'blocksmode' causes trailing frames to be spatially downsampled
%      'blurmode' causes trailing frames to be blurred
%      'blocksize' sets the base block scale used in 'blocksmode' (default 2)
%      'blursize' sets the base blur size used in 'blurmode' (default 20)
%   All options can be combined, but not all combinations will perform appropriately 
%   due to order of operations.  (e.g. combining blurmode and blocksmode)
%
%   Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imecho.html


diffmode = false;
blocksmode = false;
blurmode = false;
blocksize = 2;
blursize = 20;
offset = [0 0 0];
skip = 1;


if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'offset'
				thisarg = varargin{k+1};
				if numel(thisarg) == size(inpict,3)
					offset = thisarg;
				else
					error('IMECHO: expected OFFSET to be the same length as dim3 of INPICT')
				end
				k = k+2;
			case 'diffmode'
				diffmode = true;
				k = k+1;
			case 'blocksmode'
				blocksmode = true;
				k = k+1;
			case 'blurmode'
				blurmode = true;
				k = k+1;
			case 'blocksize'
				blocksize = varargin{k+1};
				k = k+2;
			case 'blursize'
				blursize = varargin{k+1};
				k = k+2;
			case 'skip'
				skip = varargin{k+1};
				k = k+2;
			case 'blendmode'
				thisarg = varargin{k+1};
				if ischar(thisarg)
					blendmode = thisarg;
				else
					error('IMECHO: expected BLENDMODE to be a character array')
				end
				k = k+2;
			otherwise
				error('IMECHO: unknown input parameter name %s',varargin{k})
		end
	end
end

skip = max(skip,1);
offset = round(offset);
nframes = size(inpict,4);
outpict = inpict;
fo = fliplr(mod(0:skip:skip*(nechoes-1),nframes));

for n = 1:nechoes
	if diffmode
		dpict = imblend(outpict,circshift(inpict, ...
			[0 0 0 fo(n)]),1,'difference');
	else
		dpict = circshift(inpict,[0 0 0 fo(n)]);
	end
	
	if blocksmode
		dpict = blockify(dpict,[1 1 1]*blocksize*(nechoes-n+1));
	end
	
	if blurmode
		dpict = imfilterFB(dpict,fkgen('gaussian',blursize*(nechoes-n+1)));
	end
	
	outpict = imblend(outpict,dpict,(1-1/nechoes),blendmode);
end

if sum(abs(offset)) > 0
    for c = 1:size(inpict,3)
        outpict(:,:,c,:) = circshift(outpict(:,:,c,:),[0 0 0 offset(c)]);
    end
end

end















