function [labels labelcount] = bwlabelFB(varargin)
%   LABELS=BWLABELFB(INPICT,{CONN})
%   [LABELS LABELCOUNT]=BWLABELFB(INPICT,{CONN})
%   Connected group labeling for binary images.  Labels a binary image based on 
%   user-specified connectivity. 
%
%   This is a passthrough to the IPT function bwlabel(), with an external fallback implementation 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   The tools provided for the fallback path are from the Geometry Processing Toolbox by Alec Jacobson 
%   https://www.mathworks.com/matlabcentral/fileexchange/49692-gptoolbox
%
%   INPICT is a 2D binary image
%   CONN optionally specifies the connectivity used (default 8)
%     This supports either 4 or 8-connectivity.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/bwlabelFB.html
% See also: bwlabel, gp_bwlabel

connspec = 8;

if numel(varargin) == 1
	inpict = varargin{1};
elseif numel(varargin) == 2
	inpict = varargin{1};
	connspec = varargin{2};
else
	error('BWLABELFB: Too many input arguments')
end

if ~any(connspec == [4 8])
	error('BWLABELFB: Connectivity specification must be either 4 or 8')
end

if ~islogical(inpict)
	error('BWLABELFB: Expected INPICT to be a logical image')
end

% if image has no active pixels, return
if max(inpict(:)) == 0
	labels = zeros(size(inpict));
	labelcount = 0;
	return;
end

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	[labels labelcount] = bwlabel(inpict,connspec);
else
	[labels labelcount] = gp_bwlabel(inpict,connspec);
end










