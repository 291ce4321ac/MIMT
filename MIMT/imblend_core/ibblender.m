function [R FGA BGA] = ibblender(M,I,modestring,amount,quiet,verbose,rec,FGA,BGA)
% this is the blending section of IMBLEND  
% this is not intended to work independently
% i only split this because editing a 3000+ line file is a pita

switch modestring

	% CONTRAST MODES
	case 'overlay'
		% for amount==1, this is a standard 'overlay' mode
		% otherwise, it's a brute-force attempt to approximate an iterative 'overlay' 
		% it's probably still faster than the horrible giant polynomial alternative
		% results for amt=1 equal standard 'overlay'
		% results for amt=2 approximate twice-recursed 'overlay', and so on ...
		amount = max(amount,0);
		if amount == 1
			hi = I > 0.5; 
			R = (1-2*(1-I).*(1-M)).*hi + (2*M.*I).*~hi;
		else
			% LUT 0 corresponds to amt=0
			a0 = [0 1 2 3 4];
			LUT = fetchLUT('overlay');
			mesh = permute(interp1(a0',permute(LUT,[3 1 2]),amount,'linear','extrap'),[2 3 1]);
			R = meshblend(M,I,mesh,'bilinear');
		end

	case 'hardlight'
		% this is the transpose of 'overlay' and follows the same concept
		amount = max(amount,0);
		if amount == 1
			hi = M > 0.5; 
			R = (1-2*(1-M).*(1-I)).*hi + (2*I.*M).*~hi;
		else
			% LUT 0 corresponds to amt=0
			a0 = [0 1 2 3 4];
			LUT = fetchLUT('overlay');
			mesh = permute(interp1(a0',permute(LUT,[3 1 2]),amount,'linear','extrap'),[2 3 1]);
			R = meshblend(I,M,mesh,'bilinear');
		end

	case {'softlight','pegtoplight'}
		% algebraically identical to GIMP for both legacy and GEGL methods
		% this is the same as ImageMagick's 'pegtop light' variant
		% same as legacy GIMP 'overlay' due to bug
		R = I.^2 + 2*M.*I.*(1-I);			  

	case 'softlightsvg'
		% https://dev.w3.org/SVG/modules/compositing/master/
		m1 = M <= 0.50;
		m2 = I <= 0.25;
		m3 = ~m1 & m2;
		m4 = ~m1 & ~m2;

		R = (I - (1-2*M).*I.*(1-I)).*m1 ...
			+ (I + (2*M-1).*(4*I.*(4*I + 1).*(I-1) + 7*I)).*m3 ...
			+ (I + (2*M-1).*(sqrt(I) - I)).*m4;

	case 'softlightps' % krita's version of ps softlight; equiv to formulae for ps afaict
		I = max(I,0);
		hi = M > 0.5; 
		R = (I+(2*M-1).*(sqrt(I)-I)).*hi ...
			+ (I-(1-2*M).*I.*(1-I)).*~hi;

	case {'softlighthu','softlighteb'}
		I = max(I,0);
		% i'm not sure which version was originally given at illusions.hu. the domain was parked
		% https://yahvuu.files.wordpress.com/2009/09/table-contrast-2100b.png
		% this version is ~2x faster; gradient angle is only weakly dependent on FG
		% still has continuity advantage over PS/SVG methods; still has better symmetry than pegtop method
		R = I.^(M.^2 - 2.5*M + 2);  

	case 'softlighteb2'
		% https://en.wikipedia.org/wiki/Blend_modes#Soft_Light
		% this is probably the most correct version; gradient angle is independent of FG
		% this version (and the parametric variant) act strictly as gamma adjustment functions symmetric about FG=0.5
		amount = max(amount,0);
		I = max(I,0);
		% R=I.^(2.^(1-2*M)); % formula from reference
		R = I.^(2.^(amount*(1-2*M))); % my own parametric version				

	case 'flatlight' 
		% this is a thing made from parametric softdodge & softburn
		amount = max(amount,0);
		hi = M >= I;
		pm1 = ((M+I*amount) < 1);
		pm2 = ((M*amount+I) < 1);

		pmu1 = pm1 & hi;
		pmd1 = ~pm1 & hi;
		pmu2 = pm2 & ~hi;
		pmd2 = ~pm2 & ~hi;

		R = (0.5*amount*I./(eps+1-M)).*pmu1 ...
			+ (1-0.5*(1-M)./(eps+I*amount)).*pmd1 ...
			+ (0.5*amount*M./(eps+1-I)).*pmu2 ...
			+ (1-0.5*(1-I)./(eps+M*amount)).*pmd2;

	case 'softflatlight' 
		% this is similar to 'flatlight'
		% trades neutral response at FG=0.5 for softer curve along FG=BG diagonal
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		hi = M <= I;
		if amount == 1
			R = (2*atan(M./(1-I))/pi).*hi + (1-2*atan((1-M)./I)/pi).*(1-hi);
		else
			R = ((2*atan(M./(1-I))/pi).*hi + (1-2*atan((1-M)./I)/pi).*(1-hi)).^(1/amount);
		end

	case 'softerflatlight' 
		% this is similar to 'flatlight'
		% trades neutral response at FG=0.5 for strictly linear curve along FG=BG diagonal
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		hi = M <= I;
		if amount == 1
			R = (1-((1-I)./(1+M-I))).*hi + (I./(1-M+I)).*(1-hi);
		else
			R = ((1-((1-I)./(1+M-I))).*hi + (I./(1-M+I)).*(1-hi)).^(1/amount);
		end

	case 'meanlight' % piecewise combination of softdodge/burn; 
		% flat overlay effect roughly like 'flatlight', but with averaging effect at fg extrema
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		hi = M+I > 1;
		if amount == 1
			R = (1-0.5*(1-I)./(M+eps)).*hi + (0.5*I./(eps+1-M)).*(1-hi);
		else
			R = ((1-0.5*(1-I)./(M+eps)).*hi + (0.5*I./(eps+1-M)).*(1-hi)).^(1/amount);
		end

	case 'softmeanlight' 
		% this is similar to 'meanlight'
		% trades neutral response at FG=0.5 for strictly linear curve along FG=BG diagonal
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		hi = M+I > 1;
		if amount == 1
			R = (1-((1-I)./(1+M-I+eps))).*hi + (I./(1-M+I+eps)).*(1-hi);
		else
			R = ((1-((1-I)./(1+M-I+eps))).*hi + (I./(1-M+I+eps)).*(1-hi)).^(1/amount);
		end

	case 'linearlight'
		% this is essentially a combination of 'lineardodge' and 'linearburn'
		amount = imclamp(amount);
		R = M*(amount+1)+I*amount-amount;

	case 'vividlight'
		% this is useful if a combined version of 'color dodge/burn' are desired
		% this parametric method is actually faster than standard method
		amount = max(amount,0);
		R = zeros(size(I));
		for c = 1:1:size(M,3)
			lo = -min(M(:,:,c)-0.5,0)*amount*2;
			hi = 1-max(M(:,:,c)-0.5,0)*amount*2;
			R(:,:,c) = (I(:,:,c)-lo)./max(hi-lo,0);
		end			

	case 'easylight'
		% this is a kludged combination of easydodge/easyburn for sake of completeness
		% loses a lot of utility for non-default parameter values
		amount = 1/max(eps,amount);
		I = imclamp(I);
		hi = M >= (1-0.5/amount);
		R = I.^((1-M)*2*amount).*hi + (1-(1-I).^(M*(1/(eps+amount-0.5))*amount)).*(1-hi);

	case 'pinlight'	% highlights are lighten-only, shadows are darken-only
		amount = imclamp(amount,[0 2]);
		roiw = amount/2;				
		hi = M > I;
		R = (max(I,(1/roiw)*(M-(1-roiw)))).*hi ...
			+ (min(I,(1/roiw)*M)).*~hi;

	case 'superlight' % use piecewise-pnorm to create a superelliptic contrast mode
		amount = max(1,amount);
		if amount ~= 1
			M = imclamp(M);
			I = imclamp(I);
			lo = M < 0.5;
		end
		if amount == 1
			R = 2*M+I-1;
		elseif amount == 2 
			% sqrt(x) is much faster than x.^0.5
			R = (1-sqrt((1-I).^2 + (1-2*M).^2)).*lo ...
				+ sqrt(I.^2 + (2*M-1).^2).*~lo;
		else
			R = (1-((1-I).^amount + (1-2*M).^amount).^(1/amount)).*lo ...
				+ ((I.^amount + (2*M-1).^amount).^(1/amount)).*~lo;
		end

	% HARD CONTRAST MODES
	case {'hardmix','hardmixps'}
		% speed-optimized variant of ps method
		amount = imclamp(amount,[0 2]);
		R = (M+I) >= (2-amount);

	case 'hardmixkr' % krita method
		hi = I > 0.5;
		if amount == 1
			% there really is no good way to parameterize this with colordodge/burn
			% the math gets ugly, and the results look terrible in various ways for non-default parameters
			R = (I./(1-M)).*hi + (1-(1-I)./M).*(1-hi); % original colordodge/burn only method 
		else
			% lineardodge/burn method parameterizes easily, looks good, is very similar for default parameter, but kr method is precedent
			% this is a nonlinear blend between default case colordodge/burn method and boundary cases using lineardodge/burn
			% this is complicated & slow, but it works and looks better than colordodge/burn only methods; this doesn't simplify significantly.
			bgamma = 0.2;
			klb = abs(amount-1)^bgamma;
			kcb = 1-abs(1-amount)^bgamma;
			amount = imclamp(amount,[0 2]);
			amount = 1.5-0.5*amount;
			M = max(M,eps);
			R = ((M+I-(amount-1)).*hi + (M+I-1+(amount-1)).*(1-hi))*klb + ((I./(1-M)).*hi + (1-(1-I)./M).*(1-hi))*kcb;
		end

	case 'hardmixib' % linearizing variant of ps method
		% this method blends over [0 2], from 'grainmerge' to 'meanlight'
		amount = imclamp(amount,[0 2]);
		hi = M+I > 1;
		M = max(M,eps);
		if amount <= 1
			amount = 1.5-0.5*amount;
			R = (M+I-(amount-1)).*hi + (M+I-1+(amount-1)).*(1-hi); % lineardodge/burn method
		else
			amount = amount-1;
			R = (1-0.5*amount*(1-I)./M).*hi + (0.5*amount*I./(1-M)).*(1-hi); % softdodge/burn method
		end

	case 'hardint'
		R = round(0.5*amount*(2-cos(M*pi)-cos(I*pi)))/(2*amount);


	% DODGES/BURNS	
	case 'colordodge'
		amount = imclamp(amount,[0 10]);
		if amount <= 1
			R = I./(1-M*amount);
		else
			n = M > 1/amount;
			R = n + I./(1-M*amount).*(1-n);
		end
	case 'colorburn'
		amount = imclamp(amount,[0 10]);
		if amount <= 1
			R = 1-(1-I)./(M*amount+(1-amount));
		else
			s = M < (1-1/amount);
			R = (1-(1-I)./(M*amount+(1-amount))).*(1-s);
		end

	case 'polydodge'
		% a FG offset is used here just as with the quadratics to avoid hitting the vertical corner
		% this avoids making horrible contrast overstretching artifacts when FG~1, BG~0, and amt is small
		M = M*0.995; 
		amount = max(amount,0);
		R = I./(1-M).^amount;
	case 'polyburn'
		M = M*0.995+0.005;
		amount = max(amount,0);
		R = 1-(1-I)./(M).^amount;

	case 'lineardodge' % addition
		amount = imclamp(amount);
		R = M*amount+I;
	case {'linearburn','inversesubtract'}
		amount = imclamp(amount);
		R = M*amount+I-1*amount;

	% these original formulae had a parameter scaling factor of 1.2, this offset the NRL to 1/6 and 5/6
	% generally, NRL are [1-amount amount]
	% krita reduced the offset by multiplying the scaling factor by 13/15 (SF of 1.04 instead of 1.2)
	% this means the NRL for krita versions are 0.038 and 0.962
	% to replicate the original behavior, use amount=5/6
	% to replicate krita behavior, use amount=75/78
	case 'easydodge'
		amount = 1/max(eps,amount);
		I = max(I,0);
		R = I.^((1-M)*amount);
	case 'easyburn' 
		amount = 1/max(eps,amount);
		I = min(I,1);
		R = 1-(1-I).^(M*amount);

	case {'gammaillumination','gammabright','gammadodge'}
		amount = max(eps,amount);
		M = min(M,1-eps);
		R = 1-max(1-I,0).^(amount./(1-M));
	case 'gammaburn'
		amount = max(eps,amount);
		M = max(M,eps);
		R = max(I,0).^(amount./M);

	case 'suaudodge'
		% these are more or less the unidirectional variants of 'softlighteb2'
		% can't call them 'softdodge/burn' due to conflict with ill-fitting precedents, so i'm just calling them 'soft' in catalan
		amount = max(amount,0);
		I = max(I,0);
		R = I.^(2.^(amount*(-M)));
	case 'suauburn'
		amount = max(amount,0);
		I = max(I,0);
		R = I.^(2.^(amount*(1-M)));

	case {'flatdodge','flatglow'}
		% this is a unidirectional variant of 'softerflatlight'; a hybrid between a dodge/burn and a relational mode
		% here we have a standard FG=0 neutral response like a dodge, but also a FG=BG NRL
		M = imclamp(M);
		I = imclamp(I);
		se = M <= I;
		amount = imclamp(amount,[0 2]);
		if amount == 1
			R = I.*se + (I./(1-M+I)).*(1-se);
		elseif amount == 0
			R = I;
		elseif amount == 2
			se = M <= I;
			R = I.*se + M.*(1-se);
		else
			a = amount;
			if a < 1
				% untuck nw corner to shift top half from SD3 to BG
				Rnw = (sqrt(a^2*M.^2 + (-2*a*I - 2*a).*M + I.^2 + (4*a-2)*I + 1) + a*M - I - 1)/(2*a-2);
				R = I.*se + Rnw.*(1-se);
			else
				% untuck nw corner to shift top half from SD3 to FG
				Rnw = (sqrt(M.^2 + ((2*a-4)*I + 2*a-4).*M + (a^2-4*a+4)*I.^2 + (4*a-2*a^2)*I + a^2-4*a+4) + M + (a-2)*I + a-2)/(2*a-2);
				R = I.*se + Rnw.*(1-se);
			end
		end

	case {'flatburn','flatshadow'}
		M = imclamp(M);
		I = imclamp(I);
		se = M <= I;
		amount = imclamp(amount,[0 2]);
		if amount == 1
			R = (1-((1-I)./(1+M-I))).*se + I.*(1-se);
		elseif amount == 0
			R = I;
		elseif amount == 2
			se = M <= I;
			R = M.*se + I.*(1-se);
		else
			a = amount;
			if a < 1
				% untuck se corner to shift bottom half from SB3 to BG
				Rse = -(sqrt(a^2*M.^2 + (-2*a*I - 2*a^2+4*a).*M + I.^2 - 2*a*I + a^2) - a*M + I - a)/(2*a-2);
				R = Rse.*se + I.*(1-se);
			else
				% untuck se corner to shift bottom half from SB3 to FG
				Rse = -(sqrt(M.^2 + ((2*a-4)*I - 4*a+6).*M + (a^2-4*a+4)*I.^2 + (2*a-4)*I + 1) - M + (2-a)*I - 1)/(2*a-2);
				R = Rse.*se + I.*(1-se);
			end
		end


	case {'meandodge','meanglow'}
		% similar to the flat hybrid dodge/burn modes
		% this just linearly sweeps NW half from BG to mean to FG for A=[0 1 2] (i.e. weighted arithmetic mean)
		M = imclamp(M);
		I = imclamp(I);
		se = M <= I;
		a = imclamp(amount,[0 2])/2;
		if amount == 0
			R = I;
		elseif amount == 2
			se = M <= I;
			R = I.*se + M.*(1-se);
		else
			Rnw = a*M + (1-a)*I;
			R = I.*se + Rnw.*(1-se);
		end

	case {'meanburn','meanshadow'}
		M = imclamp(M);
		I = imclamp(I);
		se = M <= I;
		a = imclamp(amount,[0 2])/2;
		if amount == 0
			R = I;
		elseif amount == 2
			se = M <= I;
			R = M.*se + I.*(1-se);
		else
			Rse = 1-(a*(1-M) + (1-a)*(1-I));
			R = Rse.*se + I.*(1-se);
		end

	case 'moonlight2'
		% this is just a lazy PW composite of moondodge/burn
		% swings from BG to FG over [0 2]
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			R = M;
		else
			ym = 0.2*amount; 
			se = M <= I;
			Io = I;
			M = (1-M).*se + M.*(1-se);
			I = (1-I).*se + I.*(1-se);
			Xs = (1-ym*2)-(1-M);
			Rs = M-ym; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = (1-Rnw).*se + Rnw.*(1-se);
			% snap the parameter curve to R=BG, otherwise it's asymptotic
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + Io.*bf;
			end
		end

	case 'moonglow2'
		% this is similar to flat/mean dodge/burn in that it has FG=BG NRL
		% where FD has convex meridians and MD has linear meridians, moondodge has concave meridians tangential to R=BG
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			se = M <= I;
			R = I.*se + M.*(1-se);
		else
			ym = 0.2*amount; 
			Xs = (1-ym*2)-(1-M);
			Rs = M-ym; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			se = M <= I;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = I.*se + Rnw.*(1-se);
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + I.*bf;
			end
		end

	case 'moonshadow2'
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			se = M <= I;
			R = M.*se + I.*(1-se);
		else
			Io = I; M = 1-M; I = 1-I; % the lazy way
			ym = 0.2*amount; 
			Xs = (1-ym*2)-(1-M);
			Rs = M-ym; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			se = M <= I;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = Io.*se + (1-Rnw).*(1-se);
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + Io.*bf;
			end
		end

	case 'moonlight'
		% this is just a lazy PW composite of moondodge/burn
		% swings from BG to FG over [0 2]
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			R = M;
		else
			ym = 0.2*amount; 
			se = M <= I;
			Io = I;
			M = (1-M).*se + M.*(1-se);
			I = (1-I).*se + I.*(1-se);
			Xs = (1-ym*sqrt(2))-(1-M);
			Rs = M-ym/2; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = (1-Rnw).*se + Rnw.*(1-se);
			% snap the parameter curve to R=BG, otherwise it's asymptotic
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + Io.*bf;
			end
		end

	case 'moonglow'
		% this is similar to flat/mean dodge/burn in that it has FG=BG NRL
		% where FD has convex meridians and MD has linear meridians, moondodge has concave meridians tangential to R=BG
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			se = M <= I;
			R = I.*se + M.*(1-se);
		else
			ym = 0.2*amount; 
			Xs = (1-ym*sqrt(2))-(1-M);
			Rs = M-ym/2; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			se = M <= I;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = I.*se + Rnw.*(1-se);
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + I.*bf;
			end
		end

	case 'moonshadow'
		M = imclamp(M);
		I = imclamp(I);
		amount = 2 - imclamp(amount,[0 2]);
		if amount > 1; amount = amount^4; end
		if amount == 16
			R = I;
		elseif amount == 0
			se = M <= I;
			R = M.*se + I.*(1-se);
		else
			Io = I; M = 1-M; I = 1-I; % the lazy way
			ym = 0.2*amount; 
			Xs = (1-ym*sqrt(2))-(1-M);
			Rs = M-ym/2; 
			Rt = (I-Xs).^2./(4*ym) + Rs;
			se = M <= I;
			bs = I <= Xs;
			Rnw = Rs.*bs + Rt.*(1-bs);
			R = Io.*se + (1-Rnw).*(1-se);
			if amount >= 8
				bf = (amount-8)/8;
				R = R.*(1-bf) + Io.*bf;
			end
		end

	% use weighted harmonic mean with asymptote snapping to sweep from BG to FG
	% 'starlight' is tangential to mean(FG,BG) local to the diagonal, similar to 'moonlight'
	case 'starlight'
		hi = M > I;
		M = imclamp(M);
		I = imclamp(I);
		if amount == 0
			R = I;
		elseif amount == 2
			R = M;
		else
			amount = imclamp(amount,[0 2]);
			Rnw = 1-2./((2-amount)./(1-I) + (amount)./(1-M));
			Rse = 2./((2-amount)./I + (amount)./M);
			R = Rnw.*hi + Rse.*~hi;
			if amount < 0.1
				bf = (0.1-amount)/0.1
				R = R.*(1-bf) + I.*bf;
			end
		end

	case 'starglow'
		hi = M > I;
		M = imclamp(M);
		I = imclamp(I);
		if amount == 0
			R = I;
		elseif amount == 2
			R = max(M,I);
		else
			amount = imclamp(amount,[0 2]);
			Rnw = 1-2./((2-amount)./(1-I) + (amount)./(1-M));
			R = Rnw.*hi + I.*~hi;
			if amount < 0.1
				bf = (0.1-amount)/0.1
				R = R.*(1-bf) + I.*bf;
			end
		end

	case 'starshadow'
		hi = M < I;
		M = imclamp(M);
		I = imclamp(I);
		if amount == 0
			R = I;
		elseif amount == 2
			R = min(M,I);
		else
			amount = imclamp(amount,[0 2]);
			Rnw = 2./((2-amount)./I + (amount)./M);
			R = Rnw.*hi + I.*~hi;
			if amount < 0.1
				bf = (0.1-amount)/0.1
				R = R.*(1-bf) + I.*bf;
			end
		end

	% SIMPLE MATH OPS	
	case 'lightenrgb'
		% use a hard pnorm as an ease mode
		% this avoids raising/lowering black/white points as old rgb ease method did
		% and avoids inversion like luma method does
		amount = imclamp(amount);
		if amount == 1
			R = max(I,M);
		else
			I = max(I,0);
			M = max(M,0);
			minp = 3; % minimum p-factor
			gamma = 7; % scale linearizing factor
			p = minp+150*amount.^gamma;
			R = (M.^p + I.^p).^(1/p);
		end

	case 'darkenrgb'
		amount = imclamp(amount);
		if amount == 1
			R = min(I,M);
		else
			I = max(I,0);
			M = max(M,0);
			minp = 3; % minimum p-factor
			gamma = 7; % scale linearizing factor
			p = minp+150*amount.^gamma;
			R = 1-((1-M).^p + (1-I).^p).^(1/p);		
		end

	case 'lighteny'
		% soft mode does a faux-linear opacity blend as a compromise
		amount = imclamp(amount);
		factors = ctflop(gettfm('luma',rec));
		My = sum(bsxfun(@times,M,factors),3);
		Iy = sum(bsxfun(@times,I,factors),3);
		if amount == 1
			mask = My > Iy;
			R = bsxfun(@times,M,mask) + bsxfun(@times,I,1-mask);
		else
			I = max(I,0);
			M = max(M,0);
			mask = ((1-Iy)+My-amount)/(2*(1-amount));
			mask = max(min(mask,1),0);

			p = 2.4;
			R = (bsxfun(@times,M.^(p),mask) + bsxfun(@times,I.^(p),1-mask)).^(1/p);
		end

	case 'darkeny'
		amount = imclamp(amount);
		factors = ctflop(gettfm('luma',rec));
		My = sum(bsxfun(@times,M,factors),3);
		Iy = sum(bsxfun(@times,I,factors),3);
		if amount == 1
			mask = My > Iy;
			R = bsxfun(@times,M,1-mask) + bsxfun(@times,I,mask);
		else
			I = max(I,0);
			M = max(M,0);
			mask = ((1-Iy)+My-amount)/(2*(1-amount));
			mask = max(min(mask,1),0);

			p = 2.4;
			R = (bsxfun(@times,M.^(1/p),1-mask) + bsxfun(@times,I.^(1/p),mask)).^(p);
		end


	% distance modes change alpha when in fga/bga mode
	% luma is weighted more to keep appearance good
	case {'near','nearbg','nearfg','nearfga','nearbga'}
		if size(M,3) == 3
			A = gettfm('ypbpr',rec);
			Mypp = imappmat(M,A);
			Iypp = imappmat(I,A);
			D = (25*(Mypp(:,:,1)-Iypp(:,:,1)).^2 + ...
				  (Mypp(:,:,2)-Iypp(:,:,2)).^2 + ...
				  (Mypp(:,:,3)-Iypp(:,:,3)).^2) <= (amount*5*1.27)^2;
		else
			D = abs(M-I) <= amount;
		end
		switch modestring
			case 'near'
				R = bsxfun(@times,I,1-D) + bsxfun(@times,M,D);
			case 'nearfg'
				R = zeros(size(M));
				R = bsxfun(@times,R,1-D) + bsxfun(@times,M,D);
			case 'nearbg'
				R = zeros(size(M));
				R = bsxfun(@times,R,1-D) + bsxfun(@times,I,D);
			case 'nearfga'
				R = M;
				BGA = BGA.*D;
			case 'nearbga'
				R = I;
				BGA = BGA.*D;
		end

	case {'far','farbg','farfg','farfga','farbga'}
		if size(M,3) == 3
			A = gettfm('ypbpr',rec);
			Mypp = imappmat(M,A);
			Iypp = imappmat(I,A);
			D = (25*(Mypp(:,:,1)-Iypp(:,:,1)).^2 + ...
				  (Mypp(:,:,2)-Iypp(:,:,2)).^2 + ...
				  (Mypp(:,:,3)-Iypp(:,:,3)).^2) > (amount*5*1.27)^2;
		else
			D = abs(M-I) > amount;
		end
		switch modestring
			case 'far'
				R = bsxfun(@times,I,1-D) + bsxfun(@times,M,D);
			case 'farfg'
				R = zeros(size(M));
				R = bsxfun(@times,R,1-D) + bsxfun(@times,M,D);
			case 'farbg'
				R = zeros(size(M));
				R = bsxfun(@times,R,1-D) + bsxfun(@times,I,D);
			case 'farfga'
				R = M;
				BGA = BGA.*D;
			case 'farbga'
				R = I;
				BGA = BGA.*D;
		end


	% original 'replacecolor' mode is 'replacebgcolor'
	% original 'excludecolor' mode is 'replacefgcolor'
	% the 'preserve' modes are just an expensive way to do a color assignment
	% since they are basically copying the parameter to the mask area if the mask tol is small

	% replace BG == color areas with FG
	case {'replacebg','replacecolor'}
		tolerance = 0.01;
		if mod(numel(amount),2) == 0
			tolerance = amount(end);
			amount = amount(1:(end-1));
		end
		if numel(amount) == 1 && size(I,3) == 3
			amount = [1 1 1]*max(min(amount,1),0);
		end
		if size(I,3) == 3
			mhi = all(bsxfun(@le,I,reshape(amount+tolerance,[1 1 3])),3);
			mlo = all(bsxfun(@ge,I,reshape(amount-tolerance,[1 1 3])),3);
			m = mhi & mlo;
			R = bsxfun(@times,I,1-m) + bsxfun(@times,M,m);
		else
			mhi = I <= (amount+tolerance);
			mlo = I >= (amount-tolerance);
			m = mhi & mlo;
			R = I.*(1-m) + M.*m;
		end
	% replace FG == color areas with BG
	case {'replacefg','excludecolor'}
		tolerance = 0.01;
		if mod(numel(amount),2) == 0
			tolerance = amount(end);
			amount = amount(1:(end-1));
		end
		if numel(amount) == 1 && size(I,3) == 3
			amount = [1 1 1]*max(min(amount,1),0);
		end
		if size(I,3) == 3
			mhi = all(bsxfun(@le,M,reshape(amount+tolerance,[1 1 3])),3);
			mlo = all(bsxfun(@ge,M,reshape(amount-tolerance,[1 1 3])),3);
			m = mhi & mlo;
			R = bsxfun(@times,M,1-m) + bsxfun(@times,I,m);
		else
			mhi = M <= (amount+tolerance);
			mlo = M >= (amount-tolerance);
			m = mhi & mlo;
			R = M.*(1-m) + I.*m;
		end


	% replace BG ~= color areas with FG
	case 'preservebg'
		tolerance = 0.01;
		if mod(numel(amount),2) == 0
			tolerance = amount(end);
			amount = amount(1:(end-1));
		end
		if numel(amount) == 1 && size(I,3) == 3
			amount = [1 1 1]*max(min(amount,1),0);
		end
		if size(I,3) == 3
			mhi = all(bsxfun(@le,I,reshape(amount+tolerance,[1 1 3])),3);
			mlo = all(bsxfun(@ge,I,reshape(amount-tolerance,[1 1 3])),3);
			m = ~(mhi & mlo);
			R = bsxfun(@times,I,1-m) + bsxfun(@times,M,m);
		else
			mhi = I <= (amount+tolerance);
			mlo = I >= (amount-tolerance);
			m = ~(mhi & mlo);
			R = I.*(1-m) + M.*m;
		end
	% replace FG ~= color areas with BG
	case 'preservefg'
		tolerance = 0.01;
		if mod(numel(amount),2) == 0
			tolerance = amount(end);
			amount = amount(1:(end-1));
		end
		if numel(amount) == 1 && size(I,3) == 3
			amount = [1 1 1]*max(min(amount,1),0);
		end
		if size(I,3) == 3
			mhi = all(bsxfun(@le,M,reshape(amount+tolerance,[1 1 3])),3);
			mlo = all(bsxfun(@ge,M,reshape(amount-tolerance,[1 1 3])),3);
			m = ~(mhi & mlo);
			R = bsxfun(@times,M,1-m) + bsxfun(@times,I,m);
		else
			mhi = M <= (amount+tolerance);
			mlo = M >= (amount-tolerance);
			m = ~(mhi & mlo);
			R = M.*(1-m) + I.*m;
		end


	case 'multiply'
		R = M.*I;

	case 'screen'
		R = 1-((1-M).*(1-I));

	case {'division','divide'}
		R = I./(M+eps);

	case {'addition','add'} % same as lineardodge
		R = M+I;

	case {'subtraction','subtract'}
		R = I-M;

	case 'difference'
		if amount == 1
			R = abs(M-I);
		else
			amount = max(min(amount,1),eps);
			R = abs(M-I)*(1/amount);
		end

	case {'equivalence','phoenix'}
		if amount == 1
			R = 1 - abs(I-M);
		else
			amount = max(min(amount,1),eps);
			R = 1-abs(M-I)*(1/amount);
		end

	case 'exclusion'
		R = M+I-2*M.*I;

	case 'negation'
		amount = imclamp(amount,[0 2]);
		R = 1-abs(amount-M-I);

	case 'extremity' % inverse of negation
		amount = imclamp(amount,[0 2]);
		R = abs(amount-M-I);

	case 'grainextract'
		R = I-M+0.5;

	case 'grainmerge'
		R = I+M-0.5;

	case 'interpolate' 
		amount = max(amount,1);
		if any(amount == [1 2 3])
			% short integer cases are faster to do directly
			R = (2-cos(M*pi)-cos(I*pi))./4;
			if amount > 1
				for iter = 2:amount
					R = (1-cos(pi*R))./2;
				end
			end
		else
			a0 = [1 2 3 4 6 8 12];
			LUT = fetchLUT('interpolate');
			mesh = permute(interp1(a0',permute(LUT,[3 1 2]),amount,'linear','extrap'),[2 3 1]);
			R = meshblend(M,I,mesh,'bilinear');
		end

	case 'pnorm' % default is sum, generally p-norm for p = (amount)
		amount = max(eps,amount);
		if amount ~= 1
			I = max(I,0);
			M = max(M,0);
		end
		if amount == 1
			R = M+I;	
		elseif amount == 2
			% sqrt(x) is 4-5x faster than x.^0.5 (seems to vary with version)
			R = sqrt(M.^amount + I.^amount);
		else
			R = (M.^amount + I.^amount).^(1/amount);
		end

	case {'average','allanon'}
		if amount == 1				
			R = (M+I)/2;
		else 
			amount = imclamp(amount,[0 2])/2;
			R = M*amount + I*(1-amount);
		end

	case 'geometric' % geometric mean
		if amount == 1				
			R = sqrt(max(M,0).*max(I,0));
		else 
			amount = imclamp(amount,[0 2]);
			R = sqrt(max(M,0).^(amount).*max(I,0).^(2-amount));
		end

	% krita's 'parallel' is actually the harmonic mean instead of the reciprocal of the sum of reciprocals
	case {'harmonic','parallel'} % practically equivalent to geometric
		if amount == 1				
			R = 2./(1./I+1./M);
		elseif amount == 0
			R = I;
		elseif amount == 2
			R = M;
		else					
			amount = imclamp(amount,[0 2]);
			R = 2./((2-amount)./I + (amount)./M);
		end

	% i don't know why i'm even including these
	case 'agm'
		amount = imclamp(amount,[0 2])/2;
		R = agm(M,I,'weight',amount,'tol',1E-4);

	case 'ghm'
		amount = imclamp(amount,[0 2])/2;
		R = ghm(M,I,'weight',amount,'tol',1E-4);

	% MESH MODES
	case {'lcd','pelican','muffle','punch','grapes','ripe'}
		Y = fetchLUT(modestring);
		if amount ~= 1; amount = imlnc(Y,'mean','k',max(amount,0)); else; amount = Y; end
		R = meshblend(M,I,amount,'bilinear');

	case 'mesh' % apply a user-supplied transfer function
		R = meshblend(M,I,amount,'bilinear');

	case 'hardmesh' % apply a user-supplied transfer function
		R = meshblend(M,I,amount,'nearest');

	case 'bomb' % apply a random transfer function (independent channels)
		amount = max(1,round(amount));
		if numel(amount) == 1
			cf = 0:1/amount:1;
			cb = cf;
		elseif numel(amount) == 2
			cf = 0:1/amount(1):1;
			cb = 0:1/amount(2):1;
		else
			if ~quiet
				disp('IMBLEND: AMOUNT parameter must be scalar or a 2-element vector for bomb modes.  Using amount(1) only.');
			end
		end
		tf = imadjustFB(rand([numel(cf) numel(cb) size(I,3)]));
		R = meshblend(M,I,tf,'bilinear');				
		if verbose 
			tfstring = 'cat(3,';
			for c = 1:size(tf,3)
				tfstring = [tfstring mat2str(tf(:,:,c),5)]; %#ok<AGROW>
				if c ~= 3; tfstring = [tfstring ',']; end %#ok<AGROW>
			end
			tfstring = [tfstring ');'];
			disp(['TF for ''bomb'' op:  ' tfstring])
		end

	case 'bomblocked' % apply a random transfer function (locked channels)
		amount = max(1,round(amount));
		if numel(amount) == 1
			cf = 0:1/amount:1;
			cb = cf;
		elseif numel(amount) == 2
			cf = 0:1/amount(1):1;
			cb = 0:1/amount(2):1;
		else
			if ~quiet
				disp('IMBLEND: AMOUNT parameter must be scalar or a 2-element vector for bomb modes.  Using amount(1) only.');
			end
		end
		tf = imadjustFB(rand([numel(cf) numel(cb)]));
		R = meshblend(M,I,tf,'bilinear');	
		if verbose 
			disp(['TF for ''bomblocked'' op:  ' mat2str(tf,5)])
		end				

	case 'hardbomb'
		amount = max(1,round(amount));
		if numel(amount) == 1
			cf = 0:1/amount:1;
			cb = cf;
		elseif numel(amount) == 2
			cf = 0:1/amount(1):1;
			cb = 0:1/amount(2):1;
		else
			if ~quiet
				disp('IMBLEND: AMOUNT parameter must be scalar or a 2-element vector for bomb modes.  Using amount(1) only.');
			end
		end
		tf = imadjustFB(rand([numel(cf) numel(cb) size(I,3)]));
		R = meshblend(M,I,tf,'nearest');	
		if verbose 
			tfstring = 'cat(3,';
			for c = 1:size(tf,3)
				tfstring = [tfstring mat2str(tf(:,:,c),5)]; %#ok<AGROW>
				if c ~= 3; tfstring = [tfstring ',']; end %#ok<AGROW>
			end
			tfstring = [tfstring ');']; 
			disp(['TF for ''hardbomb'' op:  ' tfstring])
		end

	% COMPONENT MODES
	case 'hue' % constrained LCHab operation
		Mlch = rgb2lch(M,'lab');
		Rlch = rgb2lch(I,'lab');
		Rlch(:,:,3) = Mlch(:,:,3);
		R = lch2rgb(Rlch,'lab','truncatelch');

	case 'saturation' % constrained LCHab operation
		Mlch = rgb2lch(M,'lab');
		Rlch = rgb2lch(I,'lab');
		Rlch(:,:,2) = Mlch(:,:,2);
		R = lch2rgb(Rlch,'lab','truncatelch');

	% these are thresholding methods
	case 'saturate'
		amount = max(amount,0);
		Mlch = rgb2lch(M,'luv');
		Rlch = rgb2lch(I,'luv');
		Rlch(:,:,2) = max(Rlch(:,:,2),Mlch(:,:,2)*amount);
		R = lch2rgb(Rlch,'luv','truncatelch');

	case 'desaturate'
		amount = max(amount,0);
		Mlch = rgb2lch(M,'luv');
		Rlch = rgb2lch(I,'luv');
		Rlch(:,:,2) = min(Rlch(:,:,2),Mlch(:,:,2)*amount);
		R = lch2rgb(Rlch,'luv','truncatelch');

	case 'mostsat'
		Mlch = rgb2lch(M,'luv');
		Ilch = rgb2lch(I,'luv');
		mask = Mlch(:,:,2) > Ilch(:,:,2);
		R = bsxfun(@times,M,mask) + bsxfun(@times,I,1-mask);
	case 'leastsat'
		Mlch = rgb2lch(M,'luv');
		Ilch = rgb2lch(I,'luv');
		mask = Mlch(:,:,2) < Ilch(:,:,2);
		R = bsxfun(@times,M,mask) + bsxfun(@times,I,1-mask);
		
	% swap HS in HSx; preserve initial Y
	% here, truncation occurs in RGB
	case {'color' 'colorhsly' 'colorhsvy' 'colorhsiy'}
		A = gettfm('ypbpr',rec);
		Ai = gettfm('ypbpr_inv',rec);
		Y = imappmat(I,A(1,:,:));
		
		switch modestring
			case {'color','colorhsly'}
				R = blendcolorhsl(M,I);
			case 'colorhsvy'
				R = blendcolorhsv(M,I);
			case 'colorhsiy'
				R = blendcolorhsi(M,I);
		end

		Rpbpr = imappmat(R,A(2:3,:,:));
		R = imappmat(cat(3,Y,Rpbpr),Ai);
		
	% swap HS in HSx; preserve initial Y (chroma-limited transform)
	% here, truncation occurs on chroma in LCHbr (polar YPbPr)
	case {'colorhslyc' 'colorhsvyc' 'colorhsiyc'}
		A = gettfm('ypbpr',rec);
		Y = imappmat(I,A(1,:,:));
		
		switch modestring
			case 'colorhslyc'
				R = blendcolorhsl(M,I);
			case 'colorhsvyc'
				R = blendcolorhsv(M,I);
			case 'colorhsiyc'
				R = blendcolorhsi(M,I);
		end

		Rlchbr = rgb2lch(R,'ypbpr');
		Rlchbr(:,:,1) = Y;
		R = lch2rgb(Rlchbr,'ypbpr','truncatelch');

	case 'colorhsyp' % swap H & S in HSYp
		Mhsy = rgb2hsy(M,'pastel');
		Rhsy = rgb2hsy(I,'pastel');
		Rhsy(:,:,1:2) = Mhsy(:,:,1:2);
		R = hsy2rgb(Rhsy,'pastel');

	case 'colorlchab' % bounded LCHab operation
		Mlch = rgb2lch(M,'lab');
		Rlch = rgb2lch(I,'lab');
		Rlch(:,:,2:3) = Mlch(:,:,2:3);
		R = lch2rgb(Rlch,'lab','truncatelch');

	case 'colorlchsr' % bounded SRLAB2 operation
		Mlch = rgb2lch(M,'srlab');
		Rlch = rgb2lch(I,'srlab');
		Rlch(:,:,2:3) = Mlch(:,:,2:3);
		R = lch2rgb(Rlch,'srlab','truncatelch');

	case 'colorhsl' % swap H & S in HSL
		R = blendcolorhsl(M,I);
		
	case 'colorhsv' % swap H & S in HSV
		R = blendcolorhsv(M,I);
		
	case 'colorhsi' % swap H & S in HSI
		R = blendcolorhsi(M,I);

	case 'value'
		Mhsv = rgb2hsv(M);
		Rhsv = rgb2hsv(I);
		Rhsv(:,:,3) = Mhsv(:,:,3);
		R = hsv2rgb(Rhsv); 

	case {'luma', 'luma1', 'luma2'} % swaps fg bg luma
		A = gettfm('ypbpr',rec);
		Ai = gettfm('ypbpr_inv',rec);

		My = imappmat(M,A(1,:,:));
		Ipbpr = imappmat(I,A(2:3,:,:));
		R = imappmat(cat(3,My,Ipbpr),Ai);
		
	case 'lumac' % swaps fg bg luma with chroma truncation
		A = gettfm('ypbpr',rec);
		Y = imappmat(M,A(1,:,:));
		Rlchbr = rgb2lch(I,'ypbpr');
		Rlchbr(:,:,1) = Y;
		R = lch2rgb(Rlchbr,'ypbpr','truncatelch');

	case 'lightness' % swaps fg bg lightness
		Mhsl = rgb2hsl(M);
		Rhsl = rgb2hsl(I);
		Rhsl(:,:,3) = Mhsl(:,:,3);
		R = hsl2rgb(Rhsl);

	case 'intensity' % swaps fg bg intensity 
		Mhsi = rgb2hsi(M);
		Rhsi = rgb2hsi(I);
		Rhsi(:,:,3) = Mhsi(:,:,3);
		R = hsi2rgb(Rhsi);



	% SCALE ADD treats FG as an additive gain map with a null point at its mean
	case 'scaleadd'
		% RGB independent limits
		%Mstretch=imadjustFB(M,stretchlimFB(M));
		% RGB average limits
		Mstretch = imadjustFB(M,mean(stretchlimFB(M,0.001),2)',[0; 1],1);
		sf = amount(1);
		if numel(amount) > 1
			centercolor = amount(2:end);
			if size(M,3) > numel(centercolor)
				centercolor = repmat(centercolor(1),[1 size(M,3)]);
			end
		else
			centercolor = mean(mean(Mstretch,1),2);
		end
		R = zeros(size(I));
		for c = 1:1:size(M,3)
			R(:,:,c) = I(:,:,c)+(Mstretch(:,:,c)-centercolor(c))*sf;
		end

	% SCALE MULT treats FG as a gain map with a null point at its mean
	case 'scalemult'
		% RGB independent limits
		%Mstretch=imadjustFB(M,stretchlimFB(M));				
		% RGB average limits
		Mstretch = imadjustFB(M,mean(stretchlimFB(M,0.001),2)',[0; 1],1);
		amount = max(amount,0);
		sf = amount(1);
		if numel(amount) > 1
			centercolor = amount(2:end);
			if size(M,3) > numel(centercolor)
				centercolor = repmat(centercolor(1),[1 size(M,3)]);
			end
		else
			centercolor = mean(mean(Mstretch,1),2);
		end
		R = zeros(size(I));
		for c = 1:1:size(M,3)
			R(:,:,c) = I(:,:,c).*(Mstretch(:,:,c)./(centercolor(c)+eps))*sf;
		end

	% CONTRAST uses a stretched copy of FG to map [IN_LO and IN_HI] for stretching BG contrast
	%   treats FG as a gain map with a null point at its mean
	case 'contrast'
		% RGB independent limits
		%Mstretch=imadjustFB(M,stretchlimFB(M));
		% RGB average limits
		Mstretch = imadjustFB(M,mean(stretchlimFB(M,0.001),2)',[0; 1],1);
		amount = max(amount,0);
		sf = amount(1);
		if numel(amount) > 1
			centercolor = amount(2:end);
			if size(M,3) > numel(centercolor)
				centercolor = repmat(centercolor(1),[1 size(M,3)]);
			end
		else
			centercolor = mean(mean(Mstretch,1),2);
		end
		R = zeros(size(I));
		for c = 1:1:size(M,3)
			lo = -min(Mstretch(:,:,c)-centercolor(c),0)*sf;
			hi = 1-max(Mstretch(:,:,c)-centercolor(c),0)*sf;
			R(:,:,c) = (I(:,:,c)-lo)./max(hi-lo,0);
		end

	% this implements direct contrast mapping
	case 'curves'
		I = imclamp(I);
		ko = amount(1);
		switch numel(amount)
			case 1
				os = 0; c = 0.5;
			case 2
				os = amount(2); c = 0.5;
			otherwise
				os = amount(2); c = max(min(amount(3),1),0);
		end

		k = ko*M+os;
		mk = abs(ko+os) < 1;
		mc = c < 0.5;
		if ~xor(mk,mc)
			pp = k; kk = k*c/(1-c);
		else
			kk = k; pp = (1-c)*k/c;
		end

		hi = I > c;
		R = (1-0.5*((1-I)*(1/(1-c))).^pp).*hi ...
			+ (0.5*((1/c)*I).^kk).*~hi;

	% SOFT/PENUMBRA MODES
	% modes based on Gruschel's 'softdodge' and 'softburn'
	% i really can't come up with a good use for these, but they're the root of many derived modes
	case {'softdodge', 'penumbraa','penumbraa1'}
		amount = max(0,amount);
		pm = (M+I*amount) < 1;
		R = (0.5*amount*I./(eps+1-M)).*pm ...
			+ (1-0.5*(1-M)./(I*amount+eps)).*~pm;

	case {'softburn', 'penumbrab','penumbrab1'}
		amount = max(0,amount);
		pm = (M/amount+I) < 1;
		R = (0.5*M./((eps+1-I)*amount)).*pm ...
			+ (1-0.5*amount*(1-I)./(M+eps)).*~pm;

	% basically do the same thing using atan()
	case {'softdodge2', 'penumbrac','penumbraa2'}
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		R = (2*atan(I./(1-M))./pi).^(1/amount);

	case {'softburn2', 'penumbrad','penumbrab2'}
		M = imclamp(M);
		I = imclamp(I);
		R = (2*atan(M./(1-I))./pi).^(amount);

	% this is my attempt to make the modes useful by giving them a complete NRL
	case {'softdodge3','penumbraa3'}
		amount = max(amount,eps);
		M = imclamp(M);
		I = imclamp(I);
		R = (I./(1-M+I)).^(1/amount);

	case {'softburn3','penumbrab3'}
		M = imclamp(M);
		I = imclamp(I);
		R = (M./(1-I+M)).^(amount);

	% QUADRATIC MODES
	% i guess they aren't really quadratic when you change 'amount'
	% reflect(amount)=1-heat(-(amount+1))
	% freeze(amount)=1-glow(-(amount+1))
	% frect(amount)=1-gleat(-(amount+1))
	% reeze(amount)=1-helow(-(amount+1))
	case 'reflect'
		I = I*0.995;
		if amount == 1 % faster for trivial case
			R = min(1,(M.^2./(1-I+eps)));
		else
			M = imclamp(M);
			I = imclamp(I);
			R = min(1,(M.^(amount+1)./(1-I+eps).^(amount)));
		end

	case 'glow'
		M = M*0.995;
		if amount == 1 % faster for trivial case
			R = min(1,(I.^2./(1-M+eps)));
		else
			M = imclamp(M);
			I = imclamp(I);
			R = min(1,(I.^(amount+1)./(1-M+eps).^amount));
		end

	case 'freeze'
		I = 0.005+I*0.995;
		if amount == 1 % faster for trivial case
			R = 1-min(1,((1-M).*(1-M)./I+eps));
		else
			M = imclamp(M);
			I = imclamp(I);
			R = 1-min(1,((1-M).^(amount+1)./(I+eps).^amount));
		end

	case 'heat'
		M = 0.005+M*0.995;
		if amount == 1 % faster for trivial case
			R = 1-min(1,((1-I).*(1-I)./M+eps));
		else
			M = imclamp(M);
			I = imclamp(I);
			M = max(M,0);
			R = 1-min(1,((1-I).^(amount+1)./(M+eps).^amount));
		end

	% complementary quadratic modes
	case 'frect' % same as 'helow' with layers swapped
		hi = M >= 1-I;
		I = min(1,I+0.0001);
		if amount == 1
			R = (1-min(1,((1-M).*(1-M)./I))).*hi ...
				+ (min(1,(M.^2./(1-I)))).*~hi;
		else
			M = imclamp(M);
			I = imclamp(I);
			R = (1-min(1,((1-M).^(amount+1)./I.^amount))).*hi ...
				+ (min(1,(M.^(amount+1)./(1-I).^(amount)))).*~hi;
		end

	case 'reeze' % same as 'gleat' with layers swapped
		hi = M >= 1-I;
		I = 0.005+I*0.99;
		if amount == 1
			R = (min(1,(M.^2./(1-I)))).*hi ...
				+ (1-min(1,((1-M).*(1-M)./I))).*~hi;
		else
			M = imclamp(M);
			I = imclamp(I);
			R = (min(1,(M.^(amount+1)./(1-I).^(amount)))).*hi ...
				+ (1-min(1,((1-M).^(amount+1)./I.^amount))).*~hi;
		end

	case 'gleat' % compare to 'vividlight'
		hi = M > 1-I;
		M = 0.005+M*0.99;
		if amount == 1
			R = (min(1,(I.*I./(1-M)))).*hi ...
				+ (1-min(1,((1-I).*(1-I)./M))).*~hi;
		else
			M = imclamp(M);
			I = imclamp(I);
			R = (min(1,(I.^(amount+1)./(1-M).^amount))).*hi ...
				+ (1-min(1,((1-I).^(amount+1)./M.^amount))).*~hi;
		end

	case 'helow' % compare to 'overlay' and 'softlight' for amt = 0.4-0.6
		hi = M > 1-I;
		M = min(1,M+0.0001);
		if amount == 1
			R = (1-min(1,((1-I).*(1-I)./M))).*hi ...
				+ (min(1,(I.*I./(1-M)))).*~hi;
		else
			M = imclamp(M);
			I = imclamp(I);
			R = (1-min(1,((1-I).^(amount+1)./M.^amount))).*hi ...
				+ (min(1,(I.^(amount+1)./(1-M).^amount))).*~hi;
		end


	% MATH OPS FROM KRITA
	case 'gammalight'
		amount = max(eps,amount);
		R = max(I,0).^(amount*M);

	case 'gammadark'
		amount = max(eps,amount);
		R = max(I,0).^(1./(amount*M));					

	case {'sqrtdiff','additivesubtractive'}
		if amount == 1
			R = abs(sqrt(I)-sqrt(M));
		elseif amount == 0
			R = abs(I-M);
		else
			if amount > 0
				a = 1/(min(amount,1)+1);
			else
				a = 1-max(amount,-1);
			end
			R = abs(I.^a - M.^a);
		end

	case 'arctan'
		R = 2*atan(I./M)./pi;

	% this is basically a dodge/burn pair; equivalent to 'screen'/'multiply' for amt=0.5; equivalent to 'bright'/'dark' for amt=0
	% i made the param curve quadratic just to make the points of equivalence conveniently spaced
	% i have no idea what the original intent of these modes was, but the algebraic similarity to 'bright'/'dark' is curious
	case {'light','malekidodge'}
		M = max(M,0);
		if amount == 1
			R = I.*(1-M)+sqrt(M);
		else
			a = imclamp(amount)-1;
			R = I.*(1-M)+M.^(a^2-0.5*a+0.5);
		end
	case {'shadow','malekiburn'}
		M = min(M,1);
		if amount == 1
			R = 1-((1-I).*M+sqrt(1-M));	
		else
			a = imclamp(amount)-1;
			R = 1-((1-I).*M+(1-M).^(a^2-0.5*a+0.5));
		end

	% these are the krita implementation of 'light' and 'shadow', though they're transposed WRT my sources.  idk who is correct.
	% 'light' & 'shadow' and 'bright' & 'dark' share similar forms; i'm inclined to believe my sources
	% 'light' and 'shadow' have neutral FG colors; 'tint' and 'shade' do not
	case 'tint'
		I = max(I,0);
		R = M.*(1-I)+sqrt(I);
	case 'shade'
		I = min(I,1);
		R = (1-((1-M).*I+sqrt(1-I)));	

	% the original formulae for these modes were complicated, maybe to avoid issues in integer math?
	% 'bright' is equivalent to an opacity blend using FG as its own opacity map, i.e. R = M.*M + I.*(1-M);
	% that may be the raison d'etre for this otherwise baffling mode, and the 'fog' naming becomes apropos
	case {'bright','foglighten'}
		R = M.*M-M.*I+I;
	case {'dark','fogdarken'}
		R = M.*I+M-M.*M;			

	% i'm inclined to think these formulae may be wrong.  I only really have one reference and idk the intended usage.
	% the transposes seem to have better general utility, though neither are very good at much.  
	% base-2 log is curious.  was this originally int math?  it probably was.  that might explain 'bright'/'dark' being overcomplicated
	case {'lighteneb', 'dodgelogarithmic'}
		R = 1-log2(1+(1-I)./(8*M));
	case {'darkeneb', 'burnlogarithmic'}
		R = log2(1+I./(8*(1-M)));

	case 'bleach' % these are inverted linear dodge/burn 
		R = (1-I)+(1-M)-1;
	case 'stain' 
		R = 2-I-M;

	case 'hardoverlay' % https://phabricator.kde.org/T6037
		hi = M > 0.5;
		R = I./(2-2*M).*hi + 2*M.*I.*~hi;


	% modulo modes from krita
	% super-long names need to be avoided for sake of menu and table widths
	case {'modulo','mod'}
		R = mod(I*amount,M);

	case {'moduloshift','modshift'}
		R = mod(amount*(M+I),1);

	case {'divisivemodulo','moddivide'}	
		R = mod(amount*I./(M+eps),1);

	case {'modulocontinuous','contmod','cmod'}
		I = I*amount;
		m = mod(ceil(I./(M+eps)),2) ~= 0;
		Rp = mod(I./(M+eps),1);
		R = M.*(Rp.*m + (1-Rp).*(1-m));

	case {'moduloshiftcontinuous','contmodshift','cmodshift'}
		m = (mod(ceil(amount*(I+M)),2) ~= 0) | (I == 0);
		Rp = mod(amount*(M+I),1);
		R = Rp.*m + (1-Rp).*(1-m);

	case {'divisivemodulocontinuous','contmoddivide','cmoddivide'}	
		I = I*amount;
		m = mod(ceil(I./(M+eps)),2) ~= 0;
		Rp = mod(I./(M+eps),1);
		R = Rp.*m + (1-Rp).*(1-m);			

	otherwise
		% PARAMETRIC COMPONENT MODES & OTHER SPECIAL CASES
		if numel(modestring) >= 7 && strcmp(modestring(1:7),'recolor')
			rcmode = 'unknown';
			com = modestring(8:end);
			if ~isempty(strfind(com,'hsly')); rcmode = 'hsly'; com = strrep(com,'hsly',''); end %#ok<*STREMP>
			if ~isempty(strfind(com,'lch')); rcmode = 'lch'; com = strrep(com,'lch',''); end
			if isempty(com); com = 'hs'; end % default if unspecified

			numybins = imclamp(round(16*amount(1)),[1 256]);
			if numel(amount) == 2
				blursize = amount(2);
			else
				blursize = 10;
			end

			switch rcmode
				case 'hsly'
					switch com
						case 'hs'
							R = imrecolor(M,I,'colormodel','hsly','channels','hs','blursize',blursize,'ybins',numybins);
						case 'h'
							R = imrecolor(M,I,'colormodel','hsly','channels','h','blursize',blursize,'ybins',numybins);
						case 's'
							R = imrecolor(M,I,'colormodel','hsly','channels','s','blursize',blursize,'ybins',numybins);
						otherwise
							error('IMBLEND: unknown channel substring %s for ''recolor'' blend mode.  Valid channel specs are ''hs'',''h'', or ''s''.',com)
					end

				case 'lch'
					switch com
						case 'hs'
							R = imrecolor(M,I,'colormodel','lch','channels','hs','blursize',blursize,'ybins',numybins);
						case 'h'
							R = imrecolor(M,I,'colormodel','lch','channels','h','blursize',blursize,'ybins',numybins);
						case 's'
							R = imrecolor(M,I,'colormodel','lch','channels','s','blursize',blursize,'ybins',numybins);
						otherwise
							error('IMBLEND: unknown channel substring %s for ''recolor'' blend mode.  Valid channel specs are ''hs'',''h'', or ''s''.',com)
					end

				otherwise
					error('IMBLEND: unknown or unspecified color model for ''recolor'' blend mode.  Valid models are ''lch'' and ''hsly''')
			end

		elseif numel(modestring) >= 7 && strcmp(modestring(1:7),'blurmap')
			if numel(modestring) > 7
				kstylestrings = {'gaussian','glow1','glow2','disk','ring','motion','rect','3dot','4dot','bars','cross'};
				kstyle = modestring(8:end); 
				if ~ismember(kstyle,kstylestrings)
					error('IMBLEND: unknown kernel style %s for blurmap mode\n',kstyle)
				end
			else
				kstyle = 'gaussian'; 
			end

			if amount(1) ~= 1; blursize = max(amount(1),1); else; blursize = 20; end
			if numel(amount) > 1; rampgamma = amount(2); else; rampgamma = 1; end
			if numel(amount) > 2; blurangle = amount(3); else; blurangle = 0; end
			R = pseudoblurmap(M,I,'kstyle',kstyle,'blursize',blursize,'rampgamma',rampgamma,'angle',blurangle);

		elseif numel(modestring) >= 11 && strcmp(modestring(1:8),'transfer')
			% CHANNEL TRANSFER
			com = modestring(9:end);
			com = com(com ~= '_');
			[inchan outchan] = strtok(com,'>');
			outchan = outchan(outchan~='>');
			R = I;

			switch inchan
				case 'r'
					pass = M(:,:,1);
				case 'g'
					pass = M(:,:,2);
				case 'b'
					pass = M(:,:,3); 
				case 'a'
					if any([FGhasalpha BGhasalpha] == 1)
						pass = FGA;
					else
						error('IMBLEND: inputs have no alpha to transfer')
					end
				case 'hhsl'
					Mhsl = rgb2hsl(M);
					pass = Mhsl(:,:,1)/360;
				case 'shsl'
					Mhsl = rgb2hsl(M);
					pass = Mhsl(:,:,2);
				case 'lhsl'
					Mhsl = rgb2hsl(M);
					pass = Mhsl(:,:,3);
				case 'hhsi'
					Mhsi = rgb2hsi(M);
					pass = Mhsi(:,:,1)/360;
				case 'shsi'
					Mhsi = rgb2hsi(M);
					pass = Mhsi(:,:,2);
				case {'ihsi','i'}
					Mhsi = rgb2hsi(M);
					pass = Mhsi(:,:,3);						
				case 'hhsv'
					Mhsv = rgb2hsv(M);
					pass = Mhsv(:,:,1);
				case 'shsv'
					Mhsv = rgb2hsv(M);
					pass = Mhsv(:,:,2);
				case {'vhsv','v'}
					Mhsv = rgb2hsv(M);
					pass = Mhsv(:,:,3);
				case {'llch','l'}
					Mlch = rgb2lch(M,'lab');
					pass = Mlch(:,:,1)/100;
				case {'clch','c'}
					Mlch = rgb2lch(M,'lab');
					pass = Mlch(:,:,2)/134.2;
				case 'hlch'
					Mlch = rgb2lch(M,'lab');
					pass = Mlch(:,:,3)/360;
				case 'hhusl'
					Mhusl = rgb2husl(M);
					pass = Mhusl(:,:,1)/360;
				case 'shusl'
					Mhusl = rgb2husl(M);
					pass = Mhusl(:,:,2)/100;
				case 'lhusl'
					Mhusl = rgb2husl(M);
					pass = Mhusl(:,:,3)/100;
				case {'y','yhsy','yhsyp'}
					factors = ctflop(gettfm('luma',rec));
					pass = sum(bsxfun(@times,M,factors),3);
				case {'hhsy','hhsyp'}
					Mhsy = rgb2hsy(M);
					pass = Mhsy(:,:,1)/360;
				case 'shsy'
					Mhsy = rgb2hsy(M);
					pass = Mhsy(:,:,2);
				case 'shsyp'
					Mhsy = rgb2hsy(M,'pastel');
					pass = Mhsy(:,:,2);
				otherwise
					error('IMBLEND: unknown INCHAN parameter ''%s'' for TRANSFER mode',inchan);
			end  

			switch outchan
				case 'r'
					R(:,:,1) = pass;
				case 'g'
					R(:,:,2) = pass;
				case 'b'
					R(:,:,3) = pass; 
				case 'a'
					FGA = pass;
				case 'hhsl'
					Rhsl = rgb2hsl(R);
					Rhsl(:,:,1) = pass*360;
					R = hsl2rgb(Rhsl);
				case 'shsl'
					Rhsl = rgb2hsl(R);
					Rhsl(:,:,2) = pass;
					R = hsl2rgb(Rhsl);
				case 'lhsl'
					Rhsl = rgb2hsl(R);
					Rhsl(:,:,3) = pass;
					R = hsl2rgb(Rhsl);
				case 'hhsi'
					Rhsi = rgb2hsi(R);
					Rhsi(:,:,1) = pass*360;
					R = hsi2rgb(Rhsi);
				case 'shsi'
					Rhsi = rgb2hsi(R);
					Rhsi(:,:,2) = pass;
					R = hsi2rgb(Rhsi);
				case {'ihsi','i'}
					Rhsi = rgb2hsi(R);
					Rhsi(:,:,3) = pass;
					R = hsi2rgb(Rhsi);
				case 'hhsv'
					Rhsv = rgb2hsv(R);
					Rhsv(:,:,1) = pass;
					R = hsv2rgb(Rhsv);
				case 'shsv'
					Rhsv = rgb2hsv(R);
					Rhsv(:,:,2) = pass;
					R = hsv2rgb(Rhsv);
				case {'vhsv','v'}
					Rhsv = rgb2hsv(R);
					Rhsv(:,:,3) = pass;
					R = hsv2rgb(Rhsv);
				case {'llch','l'}
					Rlch = rgb2lch(R,'lab');
					Rlch(:,:,1) = pass*100;
					R = lch2rgb(Rlch,'lab','truncatelch');
				case {'clch','c'}
					Rlch = rgb2lch(R,'lab');
					Rlch(:,:,2) = pass*134.2;
					R = lch2rgb(Rlch,'lab','truncatelch');
				case 'hlch'
					Rlch = rgb2lch(R,'lab');
					Rlch(:,:,3) = pass*360;
					R = lch2rgb(Rlch,'lab','truncatelch');
				case 'hhusl'
					Rhusl = rgb2husl(R);
					Rhusl(:,:,1) = pass*360;
					R = husl2rgb(Rhusl);
				case 'shusl'
					Rhusl = rgb2husl(R);
					Rhusl(:,:,2) = pass*100;
					R = husl2rgb(Rhusl);
				case 'lhusl'
					Rhusl = rgb2husl(R);
					Rhusl(:,:,3) = pass*100;
					R = husl2rgb(Rhusl);
				case {'y','yhsy','yhsyp'}
					Rhsy = rgb2hsy(R);
					Rhsy(:,:,3) = pass;
					R = hsy2rgb(Rhsy);
				case {'hhsy','hhsyp'}
					Rhsy = rgb2hsy(R);
					Rhsy(:,:,1) = pass*360;
					R = hsy2rgb(Rhsy);   
				case 'shsy'
					Rhsy = rgb2hsy(R);
					Rhsy(:,:,2) = pass;
					R = hsy2rgb(Rhsy); 
				case 'shsyp'
					Rhsy = rgb2hsy(R,'pastel');
					Rhsy(:,:,2) = pass;
					R = hsy2rgb(Rhsy,'pastel'); 
				otherwise
					error('IMBLEND: unknown OUTCHAN parameter ''%s'' for TRANSFER mode',outchan);
			end 

		elseif numel(modestring) >= 10 && strcmp(modestring(1:7),'permute')
			% HUE/COLOR PERMUTATION
			com = modestring(8:end);
			[inchan outchan] = strtok(com,'>');
			outchan = outchan(outchan~='>');

			Rhusl = rgb2husl(I);
			Rhusl(:,:,1) = Rhusl(:,:,1)/360;
			Rhusl(:,:,2) = Rhusl(:,:,2)/100;
			Rhusl(:,:,3) = Rhusl(:,:,3)/100;

			switch inchan
				case 'h'
					Mhusl = rgb2husl(M);
					pass = Mhusl(:,:,1)/360;
				case 'dh'
					Mhusl = rgb2husl(M);
					pass = Rhusl(:,:,1)-Mhusl(:,:,1)/360;
				case 's'
					Mhusl = rgb2husl(M);
					pass = Mhusl(:,:,2)/100;
				case 'ds'
					Mhusl = rgb2husl(M);
					pass = Rhusl(:,:,2)-Mhusl(:,:,2)/100;
				case 'y'
					factors = ctflop(gettfm('luma',rec));
					pass = sum(bsxfun(@times,M,factors),3);
				case 'dy'
					factors = ctflop(gettfm('luma',rec));
					Ym = sum(bsxfun(@times,M,factors),3);
					Yi = sum(bsxfun(@times,I,factors),3);
					pass = Yi-Ym;
				otherwise
					error('IMBLEND: unknown INCHAN parameter ''%s'' for PERMUTE mode',inchan);
			end  

			switch outchan
				case 'h'
					Rhusl(:,:,1) = mod(Rhusl(:,:,1)+pass*amount,1)*360;
					Rhusl(:,:,2) = Rhusl(:,:,2)*100;
					Rhusl(:,:,3) = Rhusl(:,:,3)*100;
					R = husl2rgb(Rhusl);
				case 'hs'
					if any(inchan == 'y')
						Mhusl = rgb2husl(M);
						Mhusl(:,:,1) = Mhusl(:,:,1)/360;
						Mhusl(:,:,2) = Mhusl(:,:,2)/100;
					end
					amt = imclamp(abs(amount)); % needed since S-blending has limited range
					Rhusl(:,:,1) = mod(Rhusl(:,:,1)+pass*amount,1)*360;
					Rhusl(:,:,2) = amt*Mhusl(:,:,2)+(1-amt)*Rhusl(:,:,2);
					Rhusl(:,:,2) = Rhusl(:,:,2)*100;
					Rhusl(:,:,3) = Rhusl(:,:,3)*100;
					R = husl2rgb(Rhusl);
				otherwise
					error('IMBLEND: unknown OUTCHAN parameter ''%s'' for PERMUTE mode',outchan);
			end 

		else
			error('IMBLEND: unknown blend mode ''%s''',modestring);
		end

end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Rout = meshblend(A,B,thisamount,interpolation)
	thisamount = max(0,min(1,thisamount));
	if any(imsize(thisamount,2) == 1)
		if ~quiet
			disp('IMBLEND: AMOUNT parameter must be at least 2x2 for mesh modes.  Default is eye(4)');
		end
		thisamount = eye(4);
	end
	meshh = size(thisamount,1);
	meshw = size(thisamount,2);
	% amount=flipud(amount); % flip this if you can't stand the array orientation convention
	[bg fg] = meshgrid(0:1/(meshw-1):1,0:1/(meshh-1):1);
	Rout = zeros(size(B));
	if size(B,3) == 3 && size(thisamount,3) == 3
		for ch = 1:size(B,3)
			Rout(:,:,ch) = interp2(bg,fg,thisamount(:,:,ch),B(:,:,ch),A(:,:,ch),interpolation);
		end
	else
		for ch = 1:size(B,3)
			Rout(:,:,ch) = interp2(bg,fg,thisamount(:,:,1),B(:,:,ch),A(:,:,ch),interpolation);
		end
	end
end

function R = blendcolorhsl(M,I)
	Mhsl = rgb2hsl(M);
	Rhsl = rgb2hsl(I);
	Rhsl(:,:,1:2) = Mhsl(:,:,1:2);
	R = hsl2rgb(Rhsl);
end

function R = blendcolorhsv(M,I)
	Mhsv = rgb2hsv(M);
	Rhsv = rgb2hsv(I);
	Rhsv(:,:,1:2) = Mhsv(:,:,1:2);
	R = hsv2rgb(Rhsv);
end

function R = blendcolorhsi(M,I)
	Mhsi = rgb2hsi(M);
	Rhsi = rgb2hsi(I);
	Rhsi(:,:,1:2) = Mhsi(:,:,1:2);
	R = hsi2rgb(Rhsi);
end
		

end % END MAIN SCOPE
































