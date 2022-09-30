function [outpict TF] = histeqFB(inpict,varargin)
%   OUTPICT=HISTEQFB(INPICT,{NBINS})
%   OUTPICT=HISTEQFB(INPICT,{HGRAM})
%   [OUTPICT TF]=HISTEQFB( ... )
%   Adjust the contrast of an image such that its intensity distribution conforms to that described
%   by a given histogram.  If no histogram is given explicitly, a flat (uniform) histogram of either
%   a default or user-specified number of bins is used.
% 
%   Optionally, the 1D transfer function TF mapping the input image to the output image can be returned.
%
%   This is a passthrough to the IPT function histeq(), with an internal fallback implementation 
%   to help remove the dependency of MIMT tools on the Image Processing Toolbox. As with other fallback 
%   tools, performance without IPT may be degraded or otherwise different due to the methods used.  
%
%   INPICT is a single-channel image of any standard image class. 
%      While the IPT tools support indexed images, the fallback tools do not. 
%   NBINS optionally specifies how many bins should be used for flat histograms (default 64)
%   HGRAM optionally specifies the target output distribution explicitly
%
%  Output image class is inherited from INPICT
%  TF class is double
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/histeqFB.html
% See also: histeq, imhist, imhistFB, imlnc

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	[outpict TF] = histeq(inpict,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nin = 256;

if numel(varargin) == 0
	% HISTEQFB(I)
	nout = 64;
	hgram = ones([1 nout])*numel(inpict)/nout;
else
	if size(varargin{1},2) == 3
		% HISTEQFB(IX,MAP)
		% HISTEQFB(IX,MAP,HGRAM)
		error('HISTEQFB: fallback methods to not support indexed images')
	elseif numel(varargin{1}) == 1
		% HISTEQFB(I,NBINS)
		nout = round(varargin{1});
		hgram = ones([1 nout])*numel(inpict)/nout;
	else
		% HISTEQFB(I,HGRAM)
		hgram = round(varargin{1});
		hgram = hgram*numel(inpict)/sum(hgram); % normalize wrt sum
		nout = numel(hgram);
		if ~isvector(hgram)
			error('HISTEQFB: HGRAM is supposed to be a vector')
		end
	end
end

% get input histogram
hgramin = imhistFB(inpict,nin)';

% calculate cumulative hgram sums
incsum = cumsum(hgramin); 
outcsum = cumsum(hgram*numel(inpict)/sum(hgram));

% generate TF mapping inpict to outpict
numin = numel(inpict);
tol = ones([nout 1])*min([hgramin(1:nin-1) 0; 0 hgramin(2:nin)])/2;
err = (outcsum(:)*ones([1 nin])-ones([nout 1])*incsum(:)')+tol;
orv = find(err < -numin*sqrt(eps)); % idk why sqrt(eps).  that's what histeq uses
if ~isempty(orv)
   err(orv) = numin*ones(size(orv));
end
[~,idx] = min(err);
TF = (idx-1)/(nout-1);

% this replicates the functionality of grayxformmex
% see https://github.com/ashwathpro/robotics/blob/master/mobRobo/matlab/imui/imui/private/grayxform.c
[inpict inclass] = imcast(inpict,'double');
inpict = min(max(inpict,0),1);
outpict = interp1(linspace(0,1,numel(TF)),TF,inpict,'nearest');
outpict = imcast(outpict,inclass);




