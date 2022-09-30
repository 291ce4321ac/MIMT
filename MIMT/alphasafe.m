function safepict = alphasafe(thispict,bsf)
%  SAFEPICT = ALPHASAFE(INPICT,{BSF})
%  Reduce an IA/RGBA/RGBAAA image to an I/RGB image by composing it with
%  a simple gray checkerboard background.  This is intended primarily
%  for the purposes of visualizing the image with tools (e.g. imshow())
%  which have no support for alpha content.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%  BSF optionally controls the blocksize of the checkerboard matting. 
%    The block size is the image diagonal (in pixels) divided by BSF.
%    Default value is 70.
%  
%  Output class is inherited from input
%
%  See also: splitalpha, joinalpha, imblend, freecb

sc = imsize(thispict);
[ncc nca] = chancount(thispict);
	
if nca ~= 0
	% has alpha, needs matting
	if nargin == 1
		bsf = 70;
	end
	
	% generate matting
	blocksize = sqrt(sum(sc(1:2).^2))/bsf;
	mat = 0.5*freecb(sc(1:2),blocksize) + 0.25; % make it gray
	mat = repmat(mat,[1 1 ncc]); % needed without imblend()
	
	% avoid imblend overhead by doing blend here
	% this really would look better in linear RGB, but that'd be expensive
	% and i doubt anyone does that for display in any other software
	[thispict inclass] = imcast(thispict,'double');
	[FG FGA] = splitalpha(thispict);
	safepict = bsxfun(@times,FGA,FG) + bsxfun(@times,(1-FGA),mat);
	safepict = imcast(safepict,inclass);
else
	safepict = thispict;
end
	
end