function outpict = imones(s,outclass)
%   IMONES(SIZE,{OUTCLASS})
%      This is a generalization of ones() which allows
%      the use of logical output class.  By allowing this,
%      IMONES can be used for all standard image classes
%      without constantly dealing with conditionals.
%      This functionality was later introduced in R2016a.
%
%   SIZE is a vector specifying the array size
%   OUTCLASS is a string specifying the output class.  
%      Supports all classes supported by ones(), with the 
%      addition of 'logical'.  Default class is 'double'.
%
%   See also: imzeros

if ~exist('outclass','var')
	outclass = 'double';
end

if strcmpi(outclass,'logical')
	outpict = true(s);
else
	outpict = ones(s,outclass);
end
