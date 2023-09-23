function [outpict outtuple] = autowb(inpict,option)
%  OUTPICT = AUTOWB(INPICT,{GRAYVAL})
%  OUTPICT = AUTOWB(INPICT,{GRAYMASK})
%  [OUTPICT GRAYVALOUT] = AUTOWB(INPICT,...)
%    Simple automatic white balance for photos.  Uses a constrained gray world assumption.
%    Transformations are performed in LAB with chroma constraint so as to prevent local
%    value inversion of dark and saturated white regions as may happen in other methods.
%    
%    Results are often moderate.  No tool works perfectly across all situations, and 
%    I prefer the probability of undercorrecting to be higher than that of overcorrecting.
%
%  INPICT is an RGB image of any standard image class
%  GRAYVAL is an optional color tuple to be treated as a nominally neutral color.
%    A 1x2 tuple is interpreted as coordinates in AB.
%    A 1x3 tuple is interpreted as coordinates in sRGB.
%    RGB tuples must be properly scaled for their class.
%  GRAYMASK is an optional mask.  It will be used to define the image region which should be
%    presumed neutral. Mask inputs should have the same page geometry as INPICT, and only 
%    have a single channel.  If the mask is not binarized, it will be binarized at 50% gray.
%
%  Optional output argument GRAYVALOUT is the average neutral color used in calculations.  
%    This takes the form of a 1x2 AB tuple. These can be used in conjunction with GRAYVAL 
%    to balance one image based on another. 
%
%  OUTPICT class is inherited from INPICT.
%
% See also: imtweak, colorbalance, tonergb, tonecmyk, uwredcomp

% this is all very questionable, and i'm sure there are better ways to do this.
% i could probably just reimplement illumgray/illumwhite/chromadapt,
% but i had a hard time getting consistently acceptable results with the extreme casts i was using
% without requiring a lot of supervision or seeing issues like local inversions near white/black.
% maybe i've optimized this too much for the needs of an unrealistic task, but i don't care.
% i only made this to prove an unrelated point; otherwise, i don't have much need for an AWB tool.
% i should really break out the internal parameters, but let's not make things more complicated yet

% other parameters
truncationmode = 'truncatelch'; % changes how LCHab->RGB truncation is handled
omitsat = true; % exclude fully saturated white pixels
pctileL = 0.8; % used to find lightest fraction of pixels (e.g. for 0.8, select the top 20% of the lightness distribution)
pctileC = 0.8; % used to find least-colorful fraction of pixels (e.g. for 0.8, select the bottom 80% of the chroma distribution)
% i'd rather these percentiles be generous enough that the result 
% is more likely to be undercorrected than overcorrected

if size(inpict,3) ~= 3
	error('AUTOWB: expected INPICT to be RGB')
end

% Convert image to double precision
[inpict inclass] = imcast(inpict,'double');

if nargin < 2
	% Convert to LAB and get thresholds
	% these values split the distribution of L,C at their center
	% for 50%, you could use mean(), but this can otherwise be generalized
	[L C H] = splitchans(rgb2lch(inpict,'lab'));
	[L A B] = splitchans(lch2lab(cat(3,L,C,H)));
	Llimit = mean(stretchlimFB(L/100,pctileL+[-0.01 0.01]))*100;
	Climit = mean(stretchlimFB(C/134,pctileC+[-0.01 0.01]))*134;

	% create masks from L,C
	lmask = L > Llimit; % brightest portion of pixels
	cmask = C < Climit; % least colorful portion of pixels
	whiteregion = lmask & cmask;
	if omitsat
		whiteregion = whiteregion & (L < 99.9);
	end
	if nnz(whiteregion) == 0
		error('AUTOWB: calculated mask is empty!')
	end

	% Compute average channel values in selected region
	meanA = mean(A(whiteregion));
	meanB = mean(B(whiteregion));

	% Apply correction factors
	ll = getll(L);
	A = A - (meanA.*ll);
	B = B - (meanB.*ll);
	outpict = lch2rgb(lab2lch(cat(3,L,A,B)),'lab',truncationmode);	

	% prepare optional output
	outtuple = [meanA meanB];

elseif isimageclass(option)
	szi = imsize(inpict,3);
	szm = imsize(option,3);
	ismask = szm(3) == 1 && all(szi(1:2) == szm(1:2));
	istuple = all(szm == [1 3 1]) || all(szm == [1 2 1]);
	
	if ismask
		[L A B] = splitchans(lch2lab(rgb2lch(inpict,'lab')));
		option = imcast(option,'logical');
		
		% Compute average channel values in selected region
		meanA = mean(A(option));
		meanB = mean(B(option));

		% Apply correction factors
		ll = getll(L);
		A = A - (meanA.*ll);
		B = B - (meanB.*ll);
		outpict = lch2rgb(lab2lch(cat(3,L,A,B)),'lab',truncationmode);	
		
		% prepare optional output
		outtuple = [meanA meanB];
		
	elseif istuple
		[L A B] = splitchans(lch2lab(rgb2lch(inpict,'lab')));
		
		% get specified neutral point
		if numel(option) == 2
			% tuple is AB
			tuplelab = [0 option];
		else
			% tuple is RGB
			tuplelab = ctflop(lch2lab(rgb2lch(ctflop(option),'lab')));
		end
		
		% Apply correction factors
		ll = getll(L);
		A = A - (tuplelab(2).*ll);
		B = B - (tuplelab(3).*ll);
		outpict = lch2rgb(lab2lch(cat(3,L,A,B)),'lab',truncationmode);	
		
		% prepare optional output
		outtuple = tuplelab(2:3);
		
	else
		error('AUTOWB: second argument must either be a 1x3 tuple or a MxNx1 binary mask')
	end
else
	error('AUTOWB: second argument must either be a 1x3 tuple or a MxNx1 binary mask')
end

% Cast output
outpict = imcast(outpict,inclass);

end % END MAIN SCOPE

function ll = getll(L)
	% generate a map used to ease the correction as a function of brightness
	% this way the correction predominantly affects light regions
	% whereas dark regions are progressively less affected

	% curve parameters
	% these are both fairly aggressive
	%kpwl = 1.5;
	
	% these are unscaled, so if L is not normalized it's possible that
	% no region in the image is actually corrected fully.
	% i've seen at least a couple examples that do something similar to this PWL curve
	%ll = min(kpwl*L/100,1); % PWL
	%ll = imlnc(L/100,'in',[0 1],'g',g,'rg',rg); % smooth
	
	% instead of using a PWL curve as above, make it smooth
	% the given values of g,rg approximate the curve produced by the given value of kpwl
	rg = 0.4; % rg <= 1
	% for simplicity, pick corresponding g to linearize the bottom 80% of the curve
	fm = [0.139704 -7.50485 1.34709 -0.297084];
	g = fm(1)*exp(fm(2)*rg) + fm(3)*exp(fm(4)*rg);
	
	% these are scaled, so there will always be some L for which the 
	% correction is applied in full, regardless of whether the image is normalized
	%ll = min(kpwl*simnorm(L),1); % PWL
	ll = imlnc(L/100,'g',g,'rg',rg); % smooth
end













