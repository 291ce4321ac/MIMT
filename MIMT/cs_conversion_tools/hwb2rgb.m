function outpict = hwb2rgb(inpict,varargin)
%   HWB2RGB(INPICT,{MODE})
%     Convert a HWB (Hue, Whiteness, Blackness) image to RGB
%     This is a variant of HSV proposed by Alvy Ray Smith (1996)
%     http://alvyray.com/Papers/CG/HWB_JGTv208.pdf
%
%   INPICT is an HWB image of any standard image class
%     The expected data range is:
%     H: [0 360)
%     W: [0 1]
%     B: [0 1]
%
%   The user may optionally specify a compatibility mode (default 'legacy')
%     'legacy' behaves as specified in the 1996 paper.  All HWB inputs beyond
%       the W+B>1 diagonal (i.e. colors outside the HWB cone) are clamped.  
%       The result is that the output becomes invariant WRT W.
%     'css' behaves as described in CSS4 documentation.  For W and B beyond  
%       the W+B>1 diagonal, W and B are normalized such that their sum is 1.
%
%   Output is class double
%
% See also: rgb2hwb, rgb2hsv, rgb2hsl, rgb2hsi

cssmode = false;
if numel(varargin)>0
	switch lower(varargin{1})
		case 'legacy'
			cssmode = false;
		case 'css'
			cssmode = true;
		otherwise
			error('HWB2RGB: unknown mode %s',varargin{1})
	end
end

[H W B] = splitchans(inpict);

if cssmode
	% this normalization is as described in CSS color module 4
	% this isn't part of the original 1996 spec
	swb = W+B;
	nmk = (swb)>1;
	W(nmk) = W(nmk)./swb(nmk);
	B(nmk) = B(nmk)./swb(nmk);
end

S = max(1-W./(1-B),0);
V = 1-B;

outpict = cat(3,H/360,S,V);
outpict = hsv2rgb(outpict);