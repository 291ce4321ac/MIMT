function outpict = ibcomposite(outpict,FG,BG,FGA,BGA,FGhasalpha,BGhasalpha,compositionmode,blendmode,opacity,camount)
% this is the composition section of IMBLEND  
% this is not intended to work independently
% i only split this because editing a 3000+ line file is a pita

% prepare things
if ~strcmp(compositionmode,'gimp')
	if all([FGhasalpha BGhasalpha] == 1)
		if ~isempty(find(strcmp(compositionmode,{'srcover','srcatop','srcin','srcout','dstover', ...
			'dstatop','dstin','dstout','xor'}),1))
			% stretch alpha if desired
			if camount > 1 
				FGA = FGA == 1;
			elseif camount == 0
				FGA = FGA ~= 0;
			elseif camount < 1 
				FGA = FGA >= camount;
			end
		end
	else
		% there's not much point in using these modes this way, but just in case ...
		% some composite-only modes will generate nonopaque output when both inputs are opaque
		if (~isempty(find(strcmp(compositionmode,{'srcin','dstatop','dstin'}),1)) && opacity ~= 1) ...
			|| (~isempty(find(strcmp(compositionmode,{'dstout','xor'}),1)) && opacity ~= 0) ...
			|| strcmp(compositionmode,'srcout')
			% expand and force alpha mode
			if ~quiet
				disp('IMBLEND: using this mode and opacity with I/RGB inputs will produce IA/RGBA output')
			end
			FGhasalpha = 1;
			sFG = size(FG);
			FGA = ones([sFG(1:2) 1 size(FG,4)]);
			BGA = FGA;
		end		
	end
end

% start doing compositing
if any([FGhasalpha BGhasalpha] == 1)
	switch compositionmode
		case 'gimp'
			% this is configured to match legacy (ver<=2.8) GIMP behavior
			% don't ask me to justify the propriety of these methods
			% this was based on paint-funcs.c and gimp-composite-generic.c
			% and tweaked to match observed output
			if strcmp(blendmode,'normal')
				FGA = FGA*opacity;
				outA = BGA+(1-BGA).*FGA; % FGA when BGA = 0; 0 when both = 0
				ratio = FGA./(outA+eps);
				outpict = bsxfun(@times,outpict,ratio) + bsxfun(@times,BG,(1-ratio));
				% when outA=0, gimp sets outRGB=0
				% otherwise, this retains BG
				outpict(outA == 0) = 0;
				outpict = cat(3,outpict,outA);
			else
				FGA = min(FGA,BGA);  % < < why this?
				FGA = FGA*opacity;
				outA = BGA+(1-BGA).*FGA;
				ratio = FGA./(outA+eps);
				outpict = bsxfun(@times,outpict,ratio) + bsxfun(@times,BG,(1-ratio));
				% when BGA=0, gimp sets outRGB=0
				% otherwise this retains BG  
				outpict(BGA == 0) = 0;
				outpict = cat(3,outpict,BGA);
			end

		% Porter-Duff compositing
		% SVG 1.2 blend modes are essentially SRC-OVER, with the Ab term (i.e. Sa.*Da)
		% buried algebraically in the blend math.  e.g.
		%  MULTIPLY: Dca' = Sca × Dca + Sca × (1 - Da) + Dca × (1 - Sa)
		%				 = (Sc.*Dc).*Ab + Sc.*As + Dc.*Ad
		% if we're not using premultiplied alpha then we can just do that here for now
		% some modes can't be optimized, but this simplifies GIMP mode compatibility
		case 'srcover'
			if strcmp(blendmode,'normal')
				FGA = FGA*opacity;
				As = FGA;
				Ad = BGA.*(1-FGA);
				outpict = bsxfun(@times,As,FG) ...
					+ bsxfun(@times,Ad,BG);
				outA = As+Ad;
			else
				FGA = FGA*opacity;
				As = FGA.*(1-BGA);
				Ad = BGA.*(1-FGA);
				Ab = FGA.*BGA;
				outpict = bsxfun(@times,As,FG) ...
					+ bsxfun(@times,Ad,BG) ...
					+ bsxfun(@times,Ab,outpict);
				outA = As+Ad+Ab;
			end

		case 'srcatop'
			FGA = FGA*opacity;
			Ad = BGA.*(1-FGA);
			Ab = FGA.*BGA;
			outpict = bsxfun(@times,Ad,BG) ...
				+ bsxfun(@times,Ab,outpict);
			outA = BGA;

		case 'srcin'
			FGA = FGA*opacity;
			Ab = FGA.*BGA;
			outpict = bsxfun(@times,Ab,outpict);
			outA = Ab;

		case 'srcout'
			FGA = FGA*opacity;
			As = FGA.*(1-BGA);
			outpict = bsxfun(@times,As,FG);
			outA = As;

		case 'dstover'
			FGA = FGA*opacity;
			As = FGA.*(1-BGA);
			Ad = BGA;
			outpict = bsxfun(@times,As,FG) ...
				+ bsxfun(@times,Ad,BG);
			outA = As+Ad;

		case 'dstatop'
			FGA = FGA*opacity;
			As = FGA.*(1-BGA);
			Ab = FGA.*BGA;
			outpict = bsxfun(@times,As,FG) ...
				+ bsxfun(@times,Ab,BG);
			outA = FGA;

		case 'dstin'
			FGA = FGA*opacity;
			Ab = FGA.*BGA;
			outpict = bsxfun(@times,Ab,BG);
			outA = Ab;

		case 'dstout'
			FGA = FGA*opacity;
			Ad = BGA.*(1-FGA);
			outpict = bsxfun(@times,Ad,BG);
			outA = Ad;

		case 'xor'
			FGA = FGA*opacity;
			As = FGA.*(1-BGA);
			Ad = BGA.*(1-FGA);
			outpict = bsxfun(@times,As,FG) ...
				+ bsxfun(@times,Ad,BG);
			outA = As+Ad;	
				
		case 'translucent'
			% http://ssp.impulsetrain.com/translucency.html
			FGA = FGA*opacity;
			FGp = bsxfun(@times,FGA,outpict);
			BGp = bsxfun(@times,BGA,BG);
			outpict = FGp + bsxfun(@times,(1-FGA).^2,BGp) ./ (1-(FGp.*BGp)+eps);
			outA = FGA + ((1-FGA).^2.*BGA)./(1-FGA.*BGA+eps);
			
		case {'dissolve','dissolvebn','dissolvezf','dissolveord','lindissolve','lindissolvebn','lindissolvezf','lindissolveord'}
			switch compositionmode
				case 'dissolve'
					FGA = (rand(size(FGA))+eps <= FGA*camount)*opacity;
					% we could use noisedither(), but that would add a teeny bit more overhead 
					
				case 'dissolvebn'
					for f = 1:images
						FGA(:,:,:,f) = noisedither(FGA(:,:,:,f)*camount,'blue')*opacity;
					end
					
				case 'dissolvezf'
					for f = 1:images
						FGA(:,:,:,f) = zfdither(FGA(:,:,:,f)*camount)*opacity;
					end
					
				case 'dissolveord'
					for f = 1:images
						FGA(:,:,:,f) = orddither(FGA(:,:,:,f)*camount)*opacity;
					end
					
				case 'lindissolve'
					FGA = (rand(size(FGA))+eps <= camount).*FGA*opacity;
					% we could use noisedither(), but that would add a teeny bit more overhead 
					
				case 'lindissolvebn'
					for f = 1:images
						FGA(:,:,:,f) = noisedither(ones(sFG(1:2))*camount,'blue').*FGA(:,:,:,f)*opacity;
					end
					
				case 'lindissolvezf'
					for f = 1:images
						FGA(:,:,:,f) = zfdither(ones(sFG(1:2))*camount).*FGA(:,:,:,f)*opacity;
					end
					
				case 'lindissolveord'
					for f = 1:images
						FGA(:,:,:,f) = orddither(ones(sFG(1:2))*camount).*FGA(:,:,:,f)*opacity;
					end
			end
			
			As = FGA.*(1-BGA);
			Ad = BGA.*(1-FGA);
			Ab = FGA.*BGA;
			outpict = bsxfun(@times,As,FG) ...
				+ bsxfun(@times,Ad,BG) ...
				+ bsxfun(@times,Ab,outpict);
			outA = As+Ad+Ab;
			
		otherwise 
			% this shouldn't ever execute since keys are matched
			error('IMBLEND: unknown composition mode ''%s''',compositionmode);
			
	end
		
	if ~strcmp(compositionmode,'gimp')
		outpict = bsxfun(@rdivide,outpict,outA+eps);
		outpict = cat(3,outpict,outA);
	end
	
else % if neither FG or BG have alpha
	
	switch compositionmode
		% if no alpha is present, do regular opacity mixdown 
		% when Sa,Da==1, both GIMP and SRC-OVER methods collapse to this
		case {'gimp','srcover','srcatop'}
			if opacity ~= 1 % don't waste time if opaque
				outpict = opacity*outpict + BG*(1-opacity);
			end
			
		% VALID FOR 'srcin' ONLY WHEN OPACITY==1
		case 'srcin'
			% outpict=outpict; NOP

		% VALID FOR 'dstout' and 'xor' ONLY WHEN OPACITY==0
		% VALID FOR 'dstin' and 'dstatop' ONLY WHEN OPACITY==1
		case {'dstout','dstin','dstatop','xor','dstover'}
			outpict = BG;

		case 'translucent'
			if opacity ~= 1
				FGp = opacity*outpict;
				outpict = FGp + (1-opacity)^2*BG ./ (1-(FGp.*BG)+eps);
			end
			
		case {'dissolve','lindissolve'}
			if opacity ~= 1 || camount ~= 1
				m = (rand(size(outpict(:,:,1)))+eps <= camount)*opacity;
				outpict = bsxfun(@times,BG,1-m) + bsxfun(@times,outpict,m);
			end
			
		case {'dissolvebn','lindissolvebn'}
			if opacity ~= 1 || camount ~= 1
				m = noisedither(ones(size(outpict(:,:,1)))*camount,'blue')*opacity;
				outpict = bsxfun(@times,BG,1-m) + bsxfun(@times,outpict,m);
			end
		
		case {'dissolvezf','lindissolvezf'}
			if opacity ~= 1 || camount ~= 1
				m = zfdither(ones(size(outpict(:,:,1)))*camount)*opacity;
				outpict = bsxfun(@times,BG,1-m) + bsxfun(@times,outpict,m);
			end
			
		case {'dissolveord','lindissolveord'}
			if opacity ~= 1 || camount ~= 1
				m = orddither(ones(size(outpict(:,:,1)))*camount)*opacity;
				outpict = bsxfun(@times,BG,1-m) + bsxfun(@times,outpict,m);
			end
					
		otherwise 
			% this shouldn't ever execute since keys are matched
			error('IMBLEND: unknown composition mode ''%s''',compositionmode);
	end
end









