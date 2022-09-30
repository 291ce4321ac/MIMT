function varargout = fourdee(fhandle,varargin)
%   FOURDEE(FHANDLE, ARG1, ARG2...)
%       Generic tool for using single-frame image processing functions
%       on multiframe (4-D) image sets.  Only works if first argument 
%       for said function is a 4D array.  
%
%       As outputs are arranged along dim4, things will break if specified function 
%       natively generates 4D output.  While multiple output arguments are 
%       supported, all outputs must have the same size for each frame in order 
%       to be concatenated.
%
%   FHANDLE is a function handle (e.g. @imresize)
%   ARGS are the arguments to be passed to the function specified by FHANDLE
%
%   Example:
%     Resize a multiframe image:
%       outpict=fourdee(@imresize,inpict,[100 100]);
%     Demonstrate multiple output arguments:
%       [flags colors]=fourdee(@issolidcolor,inpict);
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/fourdee.html

numframes = size(varargin{1},4);

if ~isa(fhandle,'function_handle')
	error('FOURDEE: FHANDLE does not appear to be a valid function handle')
end

if nargout == 1
	% do it the faster way for simple cases
	for f = 1:1:numframes;
		thisframe = fhandle(varargin{1}(:,:,:,f),varargin{2:end});
		outpict(1:size(thisframe,1),1:size(thisframe,2),1:size(thisframe,3),f) = thisframe;
	end
	varargout{1} = outpict;
else
	% there is probably a better way to do this, but the syntax is confusing me
	theseoutargs = cell([1 nargout]);
	for f = 1:1:numframes;
		[theseoutargs{:}] = fhandle(varargin{1}(:,:,:,f),varargin{2:end});
		for a = 1:nargout
			varargout{a}(1:size(theseoutargs{a},1),1:size(theseoutargs{a},2),1:size(theseoutargs{a},3),f) = theseoutargs{a};
		end
	end
end


return





















