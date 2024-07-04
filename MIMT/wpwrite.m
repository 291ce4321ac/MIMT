function wpwrite(inpict,fname,qual)
% WPWRITE(INPICT,FILENAME,{QUALITY})
% Simple workaround utility to write WEBP files from MATLAB.  
% These tools rely on the WEBP utilities cwebp and dwebp from Google.
%
% INPICT is a single-frame I/IA/RGB/RGBA image of any class
%   supported for PNG ('uint8','uint16','double','single','logical')
% QUALITY optionally specifies a lossy quality setting.  By default 
%   the compression is lossless.  Valid values are in the range [0 100].  
%   Using lossy mode also invokes the -jpeg_like flag as a convenience.
% 
% See also: wpread

if nargin < 3
	lossy = false;
else
	lossy = true;
end

% this should be located on the system's temp directory
tempname = fullfile(tempdir(),'wpwritetempfile.png');

% write the file as a temporary PNG
[~, nca] = chancount(inpict);
if nca == 0
	imwrite(inpict,tempname)
elseif nca == 1
	[inpict alpha] = splitalpha(inpict);
	imwrite(inpict,tempname,'alpha',alpha)
else
	error('WPWRITE: Image must be I/IA/RGB/RGBA')
end

% we should really be using the -exact flag, but it's not in all versions
if ~lossy
	% figure out what version of libwebp we're using
	[status,res] = system('cwebp -version');
	if status ~= 0
		error('WPWRITE: cwebp failed for some reason: %s',res)
	end
	tokenpile = regexp(res,'(\d+)\.(\d+)\.(\d+)\n$','tokens');
	vnum = str2double(tokenpile{:});

	% set the flag if the version is new enough
	if vnum(1) > 0 || vnum(2) >= 5
		extraflag = '-exact ';
	else
		extraflag = '';
	end
end

% convert the tempfile to a WEBP
if lossy
	cmdstr = sprintf('cwebp -jpeg_like -q %d "%s" -o "%s"',qual,tempname,fname);
else
	cmdstr = sprintf('cwebp -lossless %s"%s" -o "%s"',extraflag,tempname,fname);
end
[status,res] = system(cmdstr);
% if that failed try one other thing
% i don't know if this will break on other systems
if status ~= 0 && isunix
	cmdprefix = 'unset LD_LIBRARY_PATH OSG_LD_LIBRARY_PATH; ';
	[status,res] = system([cmdprefix cmdstr]);
end
% if nothing worked, then nothing worked
if status ~= 0
	error('WPWRITE: cwebp failed for some reason: %s',res)
end

% delete the tempfile
delete(tempname)














