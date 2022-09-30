function [inpict hgram] = imhistmatchFB(inpict,ref,varargin)
%   OUTPICT=IMHISTMATCHFB(INPICT,REF,{NBINS})
%   [OUTPICT HGRAM]=IMHISTMATCHFB( ... )
%   Adjust the contrast of an image such that its intensity distribution conforms to that described
%   by a given histogram.  If no histogram is given explicitly, a flat (uniform) histogram of either
%   a default or user-specified number of bins is used.
% 
%   Optionally, the reference histogram HGRAM can be returned. HGRAM will contain one row for each
%   channel of REF.
%
%   This is a passthrough to the IPT function imhistmatch(), with an internal fallback implementation 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported
%   REF is the image whose color distribution INPICT should be adjusted to match
%   NBINS optionally specifies how many bins should be used (default 64)
%
%  Output image class is inherited from INPICT
%  HGRAM class is double
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imhistmatchFB.html
% See also: imhistmatch, histeq, histeqFB, imhist, imhistFB, imlnc, imrecolor

% IF IPT IS INSTALLED
% imhistmatch wasn't introduced until R2012b
if license('test', 'image_toolbox') && ifversion('>=','R2012b')
	[inpict hgram] = imhistmatch(inpict,ref,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if numel(varargin) == 0
	nout = 64;
else
	nout = varargin{1};
end

nc = size(ref,3);
% get reference histogram(s) per channel
hgram = zeros([nc nout]);
for c = 1:nc
	hgram(c,:) = imhistFB(ref(:,:,c),nout);
end

% apply the histogram(s) to inpict
for f = 1:size(inpict,4)
	for c = 1:size(inpict,3)
		inpict(:,:,c,f) = histeqFB(inpict(:,:,c,f),hgram(c,:));
	end
end



