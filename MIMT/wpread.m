function outpict = wpread(fname)
% OUTPICT = WPREAD(FILENAME)
% Simple workaround utility to read WEBP files.  These tools 
% rely on the WEBP utilities cwebp and dwebp from Google.
%
% Images with transparency will be returned with attached alpha.
% 
% See also: wpwrite

% this should be located on the system's temp directory
tempname = fullfile(tempdir(),'wpwritetempfile.png');

% convert the WEBP to a temporary PNG
cmdstr = sprintf('dwebp "%s" -o "%s"',fname,tempname);
[status,res] = system(cmdstr);
% if that failed try one other thing
% i don't know if this will break on other systems
if status ~= 0 && isunix
	cmdprefix = 'unset LD_LIBRARY_PATH OSG_LD_LIBRARY_PATH; ';
	[status,res] = system([cmdprefix cmdstr]);
end
% if nothing worked, then nothing worked
if status ~= 0
	error('WPREAD: dwebp failed for some reason: %s',res)
end

% read the PNG
[inpict,map,alpha] = imread(tempname);
if ~isempty(map)
	% while lossless WEBP may be stored in an indexed-color form
	% dwebp should convert it to RGB whenever decoding it to PNG 
	% (or other formats as far as i know)
	error('WPREAD: Why does this WEBP have a color table?')
end
outpict = joinalpha(inpict,alpha);

% delete the tempfile
delete(tempname)
