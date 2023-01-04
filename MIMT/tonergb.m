function outpict = tonergb(inpict,Tr,Tg,Tb,Tsat,enforcement)
%  OUTPICT = TONERGB(INPICT,TR,TG,TB,TSAT,RANGETYPE)
%  Adjust image tone by adjusting RGB components relative to the
%  RGB and saturation distribution in an image.
%
%  This is based on Iain Fergusson's GMIC tools.
%  https://github.com/dtschump/gmic-community/blob/master/include/iain_fergusson.gmic
%
%  INPICT is an RGB of any standard image class.  
%  TR,TG,TB are lookup tables used for PWL interpolation.
%    Each of these is a 3x3 matrix nominally in the range [-1 1], but are 
%    not constrained.  Each matrix represents the amount by which the 
%    corresponding component should be adjusted.  Consider the example TR:
%      % Adjust red for pixels which contain
%      Tr = [0 0 0;  % [little some much] red
%            0 0 0;  % [little some much] green
%            0 0 0]; % [little some much] blue
%  TSAT is a 1x5 vector specifying how the influence of the above transformation
%    should be scaled with respect to the HSV saturation of the source image.
%    Values should nominally be in the range of [0 1], but are not constrained.
%  RANGETYPE optionally specifies how the output is handled. (default 'preserve')
%    'preserve' adjusts the output to preserve luminosity.
%    'clamp' truncates values to standard data range.
%    'normalize' scales values to standard data range.
%
%  Output class is inherited from input
%
%  See also: tonecmyk, tonepreset, colorbalance, imtweak, imcurves, imlnc

badsizes = [any(imsize(Tr,2)~=[3 3]), ...
			any(imsize(Tg,2)~=[3 3]), ...
			any(imsize(Tb,2)~=[3 3]), ...
			any(imsize(Tsat,2)~=[1 5])];
if any(badsizes)
	error('TONERGB: expected TR,TG,TB to be 3x3 and TSAT to be 1x5')
end

if nargin==5
	enforcement = 'preserve';
elseif nargin<5
	error('TONERGB: not enough arguments')
end

T = cat(3,Tr,Tg,Tb);
[inpict inclass] = imcast(inpict,'double');

% generate offset map from given breakpoints
ncc = 3;
x = [0 128 255]/255;
delta = zeros([imsize(inpict,2) ncc ncc]);
for cadj = 1:ncc
	for cin = 1:ncc
		delta(:,:,cadj,cin) = interp1(x,T(cin,:,cadj),inpict(:,:,cin),'linear','extrap');
	end
end
delta = sum(delta,4);

% get saturation correction
S = mono(inpict,'s');
x = [0 64 128 192 255]/255;
S = interp1(x,Tsat,S,'linear','extrap');

% apply corrected offset
delta = bsxfun(@times,S,delta);
outpict = inpict + delta;

% prepare output
switch lower(enforcement(enforcement~=' '))
	case 'preserve'
		Y0 = luminance(inpict);
		Y1 = luminance(outpict);
		outpict = imblend(Y1,outpict,1,'grainextract');
		outpict = imblend(Y0,outpict,1,'grainmerge');
	case 'clamp'
		outpict = imclamp(outpict);
	case 'normalize'
		outpict = simnorm(outpict);
	otherwise
		error('TONERGB: uknown value for RANGETYPE')
end

outpict = imcast(outpict,inclass);
end % END MAIN SCOPE

function R = luminance(A)
	% this is the approach used by GMIC
	A = rgb2linear(A);
	R = linear2rgb(imappmat(A,[0.22248840 0.71690369 0.06060791]));
end



