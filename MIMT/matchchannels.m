function [A B] = matchchannels(A,B,varargin)
%  [A B] = MATCHCHANNELS(A,B,{MODE})
%    Force correspondence between the channel arrangements of color tuples or images.  
%    One use may be when a color needs to be specified for use in an image.  MATCHCHANNELS
%    performs expansion or reduction as required for both inputs share the same arrangement 
%    of color and alpha channels.
%
%  A, B are I/IA/RGB/RGBA/RGBAAA images or tuples of any standard image class
%    In all cases, input values are expected to be scaled properly for their class.
%    Tuples must be specified as row vectors. Use ctflop() to process MxC color tables. 
%    For purposes involving correspondent multiframe images, a 1xCx1xF stack of tuples 
%    may be processed. 
%    Multiframe images are supported. Inputs do not need to share common page geometry 
%    or frame count. 
%  MODE optionally specifies how mismatched channel counts are resolved (default 'expand')
%    'expand' output depth is the union of the depths of A and B (legacy behavior)
%    'reduce' output depth is the intersection of the depths of A and B
%    'inherit' output depth is inherited from A
%    'i','ia','rgb','rgba','rgbaaa' output depth is independent of input depths
%
%  Color channels are expanded by replication and reduced by calculating BT601 luma.
%  Alpha channels are expanded by replication and reduced by calculating their mean.
%  In cases where existing alpha is removed, it is simply deleted without compositing.
%  In cases where new alpha is created, it is uniform and opaque.
%
%  Output class is inherited from corresponding inputs.
%
% See also: matchframes, chancount

% defaults
behaviorstr = {'expand','reduce','inherit','i','ia','rgb','rgba','rgbaaa'};
behavior = 'expand';

if numel(varargin) > 0
	thisarg = varargin{1};
	if ischar(thisarg) 
		if strismember(thisarg,behaviorstr)
			behavior = thisarg;
		else
			error('MATCHCHANNELS: unknown option %s',thisarg)
		end
	else
		error('MATCHCHANNELS: expected third argument to be an optional char/string')
	end
end

% check if tuple
% this expects a single-page row vector or a 4D array of single-page row vectors
% in this manner, an RGB color table may either be presented as Mx1x3 (an image stripe) or 1x3x1xM (a stack of tuples)
istupleA = size(A,1)==1 && size(A,3)==1 && ismember(size(A,2),[1 2 3 4 6]);
istupleB = size(B,1)==1 && size(B,3)==1 && ismember(size(B,2),[1 2 3 4 6]);
if istupleA; A = ctflop(A); end
if istupleB; B = ctflop(B); end

% get channel counts
[ncca ncaa] = chancount(A);	
[nccb ncab] = chancount(B);	

% calculate output channel counts
% due to behavior of chancount()/splitalpha(), this process will only create channel arrangements
switch behavior
	case 'expand' % output depth is the union of the depths of A and B (legacy behavior)
		nccout = max(ncca,nccb);
		ncaout = max(ncaa,ncab);
	case 'reduce' % output depth is the intersection of the depths of A and B
		nccout = min(ncca,nccb);
		ncaout = min(ncaa,ncab);
	case 'inherit' % output depth is inherited from A
		nccout = ncca;
		ncaout = ncaa;
	case 'i' % output depth is specified explicitly
		nccout = 1;
		ncaout = 0;
	case 'ia'
		nccout = 1;
		ncaout = 1;
	case 'rgb'
		nccout = 3;
		ncaout = 0;
	case 'rgba'
		nccout = 3;
		ncaout = 1;
	case 'rgbaaa'
		nccout = 3;
		ncaout = 3;
	otherwise
		error('MATCHCHANNELS: unknown output depth specification %s',behavior)
end

% process
A = processimage(A,ncca,ncaa,nccout,ncaout);
B = processimage(B,nccb,ncab,nccout,ncaout);

% unflop where necessary
if istupleA; A = ctflop(A); end
if istupleB; B = ctflop(B); end

end % END MAIN SCOPE

function out = processimage(in,nccin,ncain,nccout,ncaout)
	% take it apart
	[color alpha] = splitalpha(in);
	
	% deal with color
	if nccin < nccout % input is I, output is RGB
		color = repmat(color,[1 1 3 1]); % expand as necessary
	elseif nccin > nccout % input is RGB, output is I
		color = mono(color,'y'); % use luma for color reduction
	end
	
	% deal with alpha
	if ncaout == 0 % no output alpha
		alpha = []; % delete any alpha (no compositing on a default bg or somesuch BS)
	elseif ncain == 0 && ncaout > 0 % needs solid alpha
		alpha = ones([imsize(color,2) ncaout]); % this will be recast upon concatenation
	elseif ncain == 1 && ncaout == 3 % input is IA/RGBA, output is RGBAAA
		alpha = repmat(alpha,[1 1 3 1]); % expand as necessary
	elseif ncain == 3 && ncaout == 1 % input is RGBAAA, output is IA/RGBA
		alpha = mono(alpha,'i'); % use equal-weighted average for alpha reduction (not ideal)
	end
		
	% put it back together
	out = joinalpha(color,alpha);
end















