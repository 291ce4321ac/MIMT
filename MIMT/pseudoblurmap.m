function outpict = pseudoblurmap(map,inpict,varargin)
%  OUTPICT=PSEUDOBLURMAP(MAP,INPICT,{OPTIONS})
%    This tool applies a simple multipass opacity blended image blur; no actual
%    map analysis or segmentation is performed.  The focal distance corresponds
%    to MAP=0; maximum blur occurs at MAP=1.     
%
%  MAP and INPICT are I/IA/RGB/RGBA images of any standard image class.  
%
%  OPTIONS are key-value pairs including:
%    'kstyle' specifies the blur kernel style (default 'gaussian')
%       May be 'gaussian','glow1','glow2','disk','ring','motion','rect','3dot',
%       '4dot','bars','cross'.  See FKGEN for descriptions
%    'blursize' specifies the nominal size of blur kernel (default 40px)
%       May be a 2-element vector [height width]
%    'numblurs' specifies how many passes should be made (default 4)
%       More passes results in a smoother blur scaling at the cost of speed.
%    'rampgamma' specifies how the kernel size should be scaled over the map depth.
%       For the default value of 1, the kernel size scales linearly. Increasing 
%       this parameter brings more of the image in-focus, emphasizing the defocused 
%       areas.  The opposite is true when decreasing this parameter
%    'angle', 'thick', and 'interpolation' options from FKGEN are also supported
% 
%  Class of OUTPICT is inherited from INPICT.
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/pseudoblurmap.html
% See also: fkgen, imblend

kstyle = 'gaussian';
rampgamma = 1;
blursize = 40;
blurangle = 0;
thick = 0.2;
interpolation = 'bilinear';
numblurs = 4;


if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'blursize'
				if isnumeric(varargin{k+1})
					blursize = varargin{k+1};
				else
					error('PSEUDOBLURMAP: expected numeric value for BLURSIZE')
				end
				k = k+2;
			case 'angle'
				if isnumeric(varargin{k+1})
					blurangle = varargin{k+1};
				else
					error('PSEUDOBLURMAP: expected numeric value for BLURANGLE')
				end
				k = k+2;
			case 'numblurs'
				if isnumeric(varargin{k+1})
					numblurs = varargin{k+1};
				else
					error('PSEUDOBLURMAP: expected numeric value for NUMBLURS')
				end
				k = k+2;
			case 'rampgamma'
				if isnumeric(varargin{k+1})
					rampgamma = max(0,varargin{k+1});
				else
					error('PSEUDOBLURMAP: expected numeric value for RAMPGAMMA')
				end
				k = k+2;
			case 'thick'
				if isnumeric(varargin{k+1})
					thick = max(0,varargin{k+1});
				else
					error('PSEUDOBLURMAP: expected numeric value for THICK')
				end
				k = k+2;
			case 'interpolation'
				if ischar(varargin{k+1})
					interpolation = varargin{k+1};
				else
					error('PSEUDOBLURMAP: expected string for INTERPOLATION')
				end
				k = k+2;
			case 'kstyle'
				if ischar(varargin{k+1})
					kstyle = varargin{k+1};
				else
					error('PSEUDOBLURMAP: expected string for KSTYLE')
				end
				k = k+2;
			otherwise
				error('PSEUDOBLURMAP: unknown input parameter name %s',varargin{k})
		end
	end
end

map = imcast(map,'single');
[inpict inclass] = imcast(inpict,'double');

Rp = zeros([size(inpict,1) size(inpict,2) size(inpict,3) numblurs+1]);
Rp(:,:,:,end) = inpict;
bsramp = linspace(1,0,numblurs+1);

if rampgamma ~= 1
	bsramp = bsramp.^rampgamma;
end

for bf = 1:numblurs
	thisbs = ceil(bsramp(bf)*blursize);
	fk = fkgen(kstyle,thisbs,'angle',blurangle,'thick',thick,'interpolation',interpolation);	
	Rp(:,:,:,bf) = imfilterFB(inpict,fk);
end

outpict = imcast(zblend(Rp,1-map),inclass);

















