function outpict = simnorm(inpict,constraint)
%   SIMNORM(INPICT,CONSTRAINT)
%   simply normalize data to fit within the unit interval [0 1]
%   
%   INPICT is an image or array of any shape or class
%   CONSTRAINT specifies the approach for rescaling data (default 'extrema')
%      'extrema' transforms the data such that the original extrema
%          correspond to the new extrema of [0 1]
%      'mean' transforms the data such that the mean is located at 0.5 
%          and the extrema lie within the interval [0 1]
%
%   Output class is double
%
%   See also: imrescale, imcast, imlnc


constraintstrings = {'extrema','mean'};
if ~exist('constraint','var')
	constraint = 'extrema';
else
	if ~strismember(constraint,constraintstrings)
		error('SIMNORM: expected CONSTRAINT to be either ''extrema'' or ''mean''');
	end
end

inpict = double(inpict);
switch constraint
	case 'extrema'
		% scale to extrema
		[mn mx] = imrange(inpict);
		outpict = (inpict - mn) ./ (mx-mn);
	case 'mean'
		% scale to mean and furthest extrema
		[mn av mx] = imstats(inpict,'min','mean','max');
		os = max(abs(av-mn),abs(av-mx));
		outpict = (inpict-av)/(2*os) + 0.5;
end

end
