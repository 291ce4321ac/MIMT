function G = patbinchart(G,varargin)
%  OUTPICT = PATBINCHART(PATGROUPS,{OPTIONS})
%    Visualize the output of impatsort() by tiling all the patterns into a single
%    large image. The members of each bin are tiled horizontally. The bins are tiled 
%    vertically.  The patterns should range from dark on top to light on the bottom.
%    Patterns are represented in their original size, so the output image may be large.
%
%    This tool was made for troubleshooting impatsort(), but may be useful when trying 
%    to identify undesirable patterns (e.g. patterns with distracting geometric features
%    or sparse high-contrast features) which may skew the perceived gray level.
%
%  PATGROUPS is a nested cell array of pattern images as created by impatsort().
%  OPTIONS includes the key-value pairs:
%    'padcolor' specifies the color of the image padding ([0 1] scale; default [0.5 0 1])
%
%  Output image is class 'uint8'
%
%  See also: impatsort, impatmap, ptile


% defaults
padcolor = [0.5 0 1];

% get inputs
if numel(varargin)>0
	k = 1;
	while k<=numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			switch lower(thisarg)
				case 'padcolor'
					padcolor = varargin{k+1};
					k = k+2;
				otherwise
					error('PATBINCHART: unknown key %s',thisarg)
			end
		else
			error('PATBINCHART: expected optional values to be prefaced by a parameter name')
		end
	end
end


for binidx = 1:numel(G)
	G{binidx} = imstacker(G{binidx},'dim',2,'padding',padcolor);
end
G = imstacker(G,'dim',1,'padding',padcolor);
G = imcast(G,'uint8');

