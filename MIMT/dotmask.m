function outpict = dotmask(dotpict,gridpict,dotfill,dotsize)
%   DOTMASK(DOTPICT, GRIDPICT, {FILL}, {DOTSIZE})
%       Combines two images using an adjustable mask in the form of a grid. 
%       The pattern of square dots or grid lines is often visually-distinct
%       enough against common image content, allowing direct comparison of 
%       two images without loss of color or local object context. 
%
%   DOTPICT, GRIDPICT are I/IA/RGB/RGBA images of any standard image class
%       Both images must be the same size
%   FILL specifies the cell fill ratio (range [0 1], default 0.5)
%   DOTSIZE specifies the size of the dots relative to the image (default 0.05)
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/dotmask.html
% See also: imcompare

s1 = imsize(dotpict);
s2 = imsize(gridpict);

if any(s1(1:3) ~= s2(1:3))
	error('DOTMASK: Input images must be the same size.')
end

if ~exist('dotfill','var')
	dotfill = 0.5;
end

if ~exist('dotsize','var')
	dotsize = 0.05;
end

s = size(gridpict);
dotsize = min(max(dotsize,0),1);
dotfill = min(max(dotfill,0),1);
cellsize = dotsize*max(s(1:2));
% this is linear, whereas imcompare uses an ease curve to make the slider less touchy
barwidth = cellsize*(1-dotfill);

[xx yy] = meshgrid(1:s(2),1:s(1));
mask = 1-or(mod(xx,cellsize) < barwidth,mod(yy,cellsize) < barwidth);
outpict = replacepixels(dotpict,gridpict,mask);





