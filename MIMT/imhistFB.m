function [counts centers] = imhistFB(inpict,varargin)
%   [COUNTS BINCENTERS]=IMHISTFB(INPICT,{NBINS})
%   Calculates the histogram counts for an image.  If called with no output arguments, a stem plot 
%   will be generated for visualization.
%
%   This is a passthrough to the IPT function imhist(), with an internal fallback implementation 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded or otherwise different due to the methods used.  
%
%   INPICT is a single-channel image of any standard image class. 
%      While the IPT tools support indexed images, the fallback tools do not. 
%   NBINS optionally specifies how many histogram bins should be used
%      By default, non-logical images use 256 bins, while logical images use 2.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imhistFB.html
% See also: imhist, histc, histcounts

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	if nargout == 0
		imhist(inpict,varargin{:});
	else
		[counts centers] = imhist(inpict,varargin{:});
	end
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if islogical(inpict)
	N = 2;
else
	N = 256;
end

if numel(varargin) ~= 0
	if numel(varargin{1}) ~= 1
		error('IMHISTFB: fallback methods to not support indexed images')
	else
		N = round(varargin{1});
	end
end

% imhist gives bin locations based on their centers
% histc/histcounts gives bin locations based on their edges
range = getrangefromclass(inpict);
os = 0.5/(N-1);
breakpoints = (diff(range)*linspace(-os,1+os,N+1)+range(1))';
centers = (diff(range)*linspace(0,1,N)+range(1))';

if ifversion('<','R2014b')
	% prior to R2014b
	counts = histc(inpict(:),breakpoints);
	counts(end-1) = sum(counts((end-1):end))
	counts = counts(1:end-1);	
else
	% R2014b onward
	counts = histcounts(inpict,breakpoints);
	counts = counts';
end

if nargout == 0
	% imhist also adds a colorbar, but i'm lazy
	stem(centers,counts, 'Marker', 'none')
	set(gca,'xlim',range);
end

