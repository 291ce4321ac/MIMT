function outpict = tonecmyk(inpict,Tc,Tm,Ty,Tk,Tsat,enforcement,presetmode)
%  OUTPICT = TONECMYK(INPICT,TC,TM,TY,TK,TSAT,RANGETYPE,{PRESETMODE})
%  Adjust image tone by adjusting CMYK components relative to the
%  CMYK and saturation distribution in an image.
%
%  This is based on Iain Fergusson's GMIC tools.
%  https://github.com/dtschump/gmic-community/blob/master/include/iain_fergusson.gmic
%
%  INPICT is an RGB of any standard image class.  
%  TC,TM,TY,TK are lookup tables used for PWL interpolation.
%    Each of these is a 4x3 matrix nominally in the range [-1 1], but are 
%    not constrained.  Each matrix represents the amount by which the 
%    corresponding component should be adjusted.  Consider the example TC:
%      % Adjust cyan for pixels which contain
%      Tc = [0 0 0;  % [little some much] cyan
%            0 0 0;  % [little some much] magenta
%            0 0 0;  % [little some much] yellow
%            0 0 0]; % [little some much] black
%  TSAT is a 1x5 vector specifying how the influence of the above transformation
%    should be scaled with respect to the HSV saturation of the source image.
%    Values should nominally be in the range of [0 1], but are not constrained.
%  RANGETYPE optionally specifies how the output is handled. (default 'preserve')
%    'preserve' adjusts the output to preserve luminosity.
%    'clampcmyk' truncates values to standard data range prior to conversion.
%    'clamprgb' truncates values to standard data range after conversion.
%    'normalizecmyk' scales values to standard data range prior to conversion.
%    'normalizergb' scales values to standard data range after conversion.
%  PRESETMODE is an optional key that is only needed if you want to replicate
%    the exact behavior of the GMIC tool.  When 'presetmode' is specified, 
%    an attempt will be made to replicate (what I assume is) a bug that causes 
%    the K adjustment to be unaffected by the application of Tsat.  This bug 
%    does not affect tonergb().
%
%  Output class is inherited from input
%
%  See also: tonergb, tonepreset, colorbalance, imtweak, imcurves, imlnc

badsizes = [any(imsize(Tc,2)~=[4 3]), ...
			any(imsize(Tm,2)~=[4 3]), ...
			any(imsize(Ty,2)~=[4 3]), ...
			any(imsize(Tk,2)~=[4 3]), ...
			any(imsize(Tsat,2)~=[1 5])];
if any(badsizes)
	error('TONECMYK: expected TC,TM,TY,TK to be 4x3 and TSAT to be 1x5')
end

if nargin < 6
	error('TONECMYK: not enough arguments')
elseif nargin == 6
	enforcement = 'preserve';
	presetmode = false;
elseif nargin == 7
	presetmode = false;
elseif nargin == 8
	presetmode = strcmpi(presetmode,'presetmode');
end

T = cat(3,Tc,Tm,Ty,Tk);

[inpict inclass] = imcast(inpict,'double');
inpictrgb = inpict;
inpict = gmrgb2cmyk(inpict);

% generate offset map from given breakpoints
ncc = 4;
x = [0 128 255]/255;
delta = zeros([imsize(inpict,2) ncc ncc]);
for cadj = 1:ncc
	for cin = 1:ncc
		delta(:,:,cadj,cin) = interp1(x,T(cin,:,cadj),inpict(:,:,cin),'linear','extrap');
	end
end
delta = sum(delta,4);

% get saturation correction
S = mono(inpictrgb,'s');
x = [0 64 128 192 255]/255;
S = interp1(x,Tsat,S,'linear','extrap');

% apply corrected offset
if presetmode
	% this is necessary because the original CMYK tone tool
	% misuses compose_mult, which internally uses to_colormode
	% which expands 4ch images as if they are RGBA.  
	% this means that 1ch S is expanded x3 and given a flat 100% alpha channel
	% the consequence is that delta(:,:,4) is NOT SCALED
	% i'm going to call that a bug, but to replicate the behavior
	% of the presets, it's necessary to replicate the bug
	delta(:,:,1:3) = bsxfun(@times,S,delta(:,:,1:3));
else
	delta = bsxfun(@times,S,delta);
end
outpict = inpict + delta;

% prepare output
switch lower(enforcement(enforcement~=' '))
	case 'preserve'
		outpict = gmcmyk2rgb(outpict);
		Y0 = luminance(inpictrgb);
		Y1 = luminance(outpict);
		outpict = imblend(Y1,outpict,1,'grainextract');
		outpict = imblend(Y0,outpict,1,'grainmerge');
	case 'clampcmyk'
		outpict = imclamp(outpict);
		outpict = gmcmyk2rgb(outpict);
	case 'normalizecmyk'
		outpict = simnorm(outpict);
		outpict = gmcmyk2rgb(outpict);
	case 'clamprgb'
		outpict = gmcmyk2rgb(outpict);
		outpict = imclamp(outpict);
	case 'normalizergb'
		outpict = gmcmyk2rgb(outpict);
		outpict = simnorm(outpict);
	otherwise
		error('TONECMYK: uknown value for RANGETYPE')
end

outpict = imcast(outpict,inclass);
end % END MAIN SCOPE

function R = luminance(A)
	% this is the approach used by GMIC
	A = rgb2linear(A);
	R = linear2rgb(imappmat(A,[0.22248840 0.71690369 0.06060791]));
end

