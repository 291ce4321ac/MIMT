function [outpict,varargout] = imreadort(fname)
%  OUTPICT = IMREADORT(FILENAME)
%  [OUTPICT MAP ALPHA] = IMREADORT(FILENAME)
%  Read an image from an image file and reorient it based on
%  available EXIF metadata.  If no orientation tag exists, 
%  image will be returned as-is.
%
%  While this tool is intended for use with JPG photographs, some
%  small effort has been made to allow it to be used as a general
%  imread() wrapper for reading most types of images.  This obviously
%  won't work well for many cases (e.g. multiframe GIF/TIF, etc).
%
%  I don't doubt that there are tag configurations which will 
%  foil this simple tool.  Provide me with examples.
% 
%  FILENAME is the full or relative path to an image file.
%
%  See also: imread, imfinfo, gifread, gifwrite

% read the image; don't care what it is
[outpict map alpha] = imread(fname);
S = imfinfo(fname);

% if image has no orientation tag, return image as-is
% if orientation tag is not numeric 1-8, return image as-is
% i have seen old images with 'horizontal' orientation regardless of geometry or 
% state of 'rotation' tag.  i'm ignoring non-numeric orientation tags until i have 
% a less ridiculous description of their intended use.

% using fliplr(), flipud(), and rot90() don't work for multichannel images prior to R2014a
if isfield(S,'Orientation')
	switch S.Orientation
		case 1
			% nothing to do
		case 2
			outpict = flipd(outpict,2);
		case 3
			outpict = imrotateFB(outpict,180); % or two flips
		case 4
			outpict = flipd(outpict,1);
		case 5
			outpict = imrotateFB(outpict,-90);
			outpict = flipd(outpict,2);
		case 6
			outpict = imrotateFB(outpict,-90);
		case 7
			outpict = imrotateFB(outpict,90);
			outpict = flipd(outpict,2);
		case 8
			outpict = imrotateFB(outpict,90);	
	end
end

if nargout >= 2
	varargout{1} = map;
end

if nargout == 3
	varargout{2} = alpha;
end

end % END MAIN SCOPE


% image is portrait if:
% if ORT is 1:4 and AR<1
% or ORT is 5:8 and AR>1

% image is landscape if:
% if ORT is 1:4 and AR>1
% or ORT is 5:8 and AR<1








