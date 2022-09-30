function [outflag color] = issolidcolor(inpict,tol)
%  OUTFLAG=ISSOLIDCOLOR(INPICT,{TOLERANCE})
%  [OUTFLAG COLOR]=ISSOLIDCOLOR(INPICT,{TOLERANCE})
%     Determine whether an image consists of a uniform color with
%     uniform alpha (when present). If the image is uniform,
%     optionally return its color tuple.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any class.  Multiframe
%     images are supported, but all frames are evaluated together.
%     For per-frame analysis, use fourdee(@issolidcolor,inpict) or
%     use a loop of some fashion.
%  TOLERANCE is the maximum allowable standard deviation within any 
%     given channel.  This is normalized wrt the data range of the 
%     given image class. The default (250E-6) is selected to avoid 
%     false negatives for images which have been subject to compression.
%
%  COLOR output class is inherited from INPICT.  If OUTFLAG is false
%     the value of COLOR is not to be considered valid.
%
%  See also: ismono, isopaque, imrange

if ~exist('tol','var')
	tol = 250E-6;
end

inclass = class(inpict);
tol = imrescale(tol,'double',inclass);

inpict = double(inpict);
nc = size(inpict,3);

outflag = true;
color = zeros([1 nc]);
for c = 1:nc
	thischan = inpict(:,:,c);
	if std(thischan(:)) <= tol
		color(c) = mean(thischan(:));
	else
		% if an empty vector is used here, it may end up 
		% breaking a routine which inserts those values into an array
		% also can't use NaN for integer classes
		% it should be understood that the value for 'color' is invalid
		% when outflag is false
		color = imzeros([1 nc],inclass);
		outflag = false;
		break;
	end
	color = cast(color,inclass);
end




