function out = randrange(range,varargin)
% RANDRANGE(RANGE, {ARGS})
%   this is just a wrapper for RAND to simplify the generation of 
%   random numbers within a numeric range
% 
% RANGE is a 2-element vector [min max]
% ARGS are the standard arguments for RAND
%
% EXAMPLE:
%   Generate a 1x4 array of random numbers within the range [minval maxval]
%     using rand:
%      x = minval + rand([1 4])*(maxval-minval)
%     using randrange:
%      x = randrange([minval maxval],[1 4])
%
% See also: rand, randisum

if numel(range) ~= 2
	error('RANDRANGE: RANGE parameter must be a 2-element vector')
end

out = range(1)+rand(varargin{:})*(range(2)-range(1));


