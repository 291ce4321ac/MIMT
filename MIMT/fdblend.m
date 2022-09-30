function outpict = fdblend(inpict,varargin)
%   OUTPICT=FDBLEND(INPICT,{OPTIONS})
%       This is the permutation/blending routine used by the original FD style
%       image mangling routines.  This is intended to be used in conjunction with
%       IMCONTFDX, though it can otherwise be used on any 4D image stack.  The 
%       routine consists of cyclic interframe color permutation followed by cyclic 
%       frame blending.  The result is a stack of colorful garbage. Like the other 
%       related tools, this is an overcomplicated and computationally expensive 
%       tool with no intended techical use.
%
%   INPICT is a 4D I/RGB image of any standard image class, though this tool has
%       no practical utility for single-channel images, as color permutation would
%       be meaningless without color data.
%   OPTIONS are the keys and key-value pairs:
%       'quiet' suppresses progress messages which are otherwise dumped to console.
%
%   Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/fdblend.html
% See also: imcontfdx, imcontmip

quiet = false;

k = 1;
while k <= numel(varargin);
    switch lower(varargin{k})
		case 'quiet'
			quiet = true;
			k = k+1;
        otherwise
            error('FDBLEND: unknown input parameter name %s',varargin{k})
    end
end

[inpict inclass] = imcast(inpict,'double');
numframes = size(inpict,4);

outpict = zeros(size(inpict),'double');
for n = 1:numframes	
	C = zeros(size(inpict),'double');
	for mf = 1:numframes
		if ~quiet
			if n == 1 && mf == 1
				msg = sprintf('blending frame %d of %d: permutation cycle %d of %d',n,numframes,mf,numframes);
				fprintf(msg);
			else
				remc = repmat(sprintf('\b'),[1 numel(msg)]);
				msg = sprintf('blending frame %d of %d: permutation cycle %d of %d',n,numframes,mf,numframes);
				fprintf([remc msg]);
			end
		end
		
		c1 = inpict(:,:,:,1);
		for f = 2:numframes
			c1 = imblend(inpict(:,:,:,f),c1,1,'permute dy>h',1/(numframes-1));
		end
		C(:,:,:,mf) = c1;
		if mf ~= numframes
			inpict = inpict(:,:,:,circshift(1:numframes,[0 1]));
		end
	end

	if ~quiet
		remc = repmat(sprintf('\b'),[1 numel(msg)]);
		msg = sprintf('blending frame %d of %d: contrast blending',n,numframes);
		fprintf([remc msg]);
	end
	
	c2 = C(:,:,:,1);
	for f = 2:numframes
		c2 = imblend(C(:,:,:,f),c2,1/(numframes-1),'easyburn',1);
		%c2=imblend(C(:,:,:,f),c2,1,'near',0.1);
	end
	outpict(:,:,:,n) = c2;
end
fprintf('\n')

outpict = imcast(outpict,inclass);














