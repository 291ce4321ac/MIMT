function [A B] = matchframes(A,B,varargin)
%  [A B] = MATCHFRAMES(A,B,{EXPANSIONMODE})
%  Given two potentially multiframe images, expand single-frame inputs
%  as necessary when framecounts mismatch.
%
%  A,B are images of any class, geometry or channel arrangement.  
%    If framecounts differ, the shorter image will be expanded.  
%  EXPANSIONMODE optionally controls the expansion behavior in cases
%    where both images are multiframe.  (default 'default')
%    'default' will only allow expansion of single-frame images.
%       If both images are multiframe with differing framecounts, 
%       an error will result.
%    'forceblockwise' will replicate the shorter image as a whole, 
%       discarding any excess frames. (e.g. sequence repetition) 
%    'forceframewise' will replicate the shorter image framewise, 
%       discarding any excess frames. (e.g. sequence stretching)
%
%  Output classes are inherited from inputs.
%
% See also: matchchannels, framecount, chancount, imsize

expmode = 'default';
modestr = {'default','forceblockwise','forceframewise'};

if numel(varargin)>0
	thisarg = varargin{1};
	if strismember(lower(thisarg),modestr)
		expmode = lower(thisarg);
	else
		error('MATCHFRAMES: unsupported expansion mode %s',thisarg)
	end
end

nfa = framecount(A);
nfb = framecount(B);

if nfa ~= nfb
	if nfa > nfb
		B = expander(B,nfb,nfa);
	else
		A = expander(A,nfa,nfb);
	end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SM = expander(SM0,nfs,nfl)
	switch expmode
		case 'default'
			if ~any([nfa nfb] == 1)
				error('MATCHFRAMES: If framecounts mismatch, one image must be single-frame.')
			end
			SM = repmat(SM0,[1 1 1 nfl]);
		case 'forceblockwise'
			% i could use repmat(), but this avoids the potential cost of overallocation
			nblocks = ceil(nfl/nfs);
			f = reshape(repmat(1:nfs,[nblocks 1]).',[],1);
			SM = SM0(:,:,:,f(1:nfl));
		case 'forceframewise'
			% can't use repelem(); requires R2015a or newer
			nblocks = ceil(nfl/nfs);
			f = reshape(repmat(1:nfs,[nblocks 1]),[],1);
			SM = SM0(:,:,:,f(1:nfl));
	end
end

end % END MAIN SCOPE



