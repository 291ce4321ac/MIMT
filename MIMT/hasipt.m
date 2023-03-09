function outflag = hasipt()
%  FLAG = HASIPT()
%  Check whether the current installation has Image Processing Toolbox installed.
%  State is persistent to reduce cost of repeated calls.
%  Output is a logical scalar.

% for testing purposes
enable = true;

persistent hasIPT
if isempty(hasIPT)
	hasIPT = license('test', 'image_toolbox');
end
	
if enable
	outflag = hasIPT;
else
	outflag = false;  %#ok<UNRCH>
	quietwarning('HASIPT(): license checking is disabled for testing!')
end
	