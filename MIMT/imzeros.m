function outpict = imzeros(s,outclass)
%   IMZEROS(SIZE,{OUTCLASS})
%      This is a generalization of zeros() which allows
%      the use of logical output class.  By allowing this,
%      IMZEROS can be used for all standard image classes
%      without constantly dealing with conditionals.
%
%   SIZE is a vector specifying the array size
%   OUTCLASS is a string specifying the output class.  
%      Supports all classes supported by zeros(), with the 
%      addition of 'logical'.  Default class is 'double'.
%
%   See also: imones

if ~exist('outclass','var')
	outclass = 'double';
end

if strcmpi(outclass,'logical')
	outpict = false(s);
else
	outpict = zeros(s,outclass);
end
