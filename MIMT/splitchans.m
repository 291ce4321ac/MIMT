function varargout = splitchans(inpict)
%  [CH1 CH2 CH3 ...] = SPLITCHANS(INPICT)
%    Split a multichannel image into its color channels.
%    This tool is effectively a direct replacement for IPT imsplit(), 
%    though splitchans() also allows underspecified and multiframe inputs.
%
%  INPICT is an image of any standard image class.  
%    Multiframe (4D) images are supported.
%  CH1, CH2, etc are the dim3 pages of INPICT
%  
%  If the number of output arguments exceeds the number of image channels
%  the excess outputs will be returned as empty without error.
%
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/splitchans.html
% See also: splitalpha, imsplit, chancount

nchans = size(inpict,3);
for c = 1:nargout
	if c <= nchans
		varargout{c} = inpict(:,:,c,:); %#ok<*AGROW>
	else
		varargout{c} = [];
	end
end
