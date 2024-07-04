function outpict = combonnintconv(inpict,inclass,outclass,issi,isso,wsi,wso,iptmode)
% This is a utility used by imcast() for conversions involving 64b and non-native integer classes.
%
% there are three possibilities:
% 1: if we're working with narrow enough data, we can use float arithmetic (2^k + 1 scaling)
% 2: if we're too wide, then:
%   2a: if the scaling is harmonic, use integer arithmetic (also 2^k + 1)
%   2b: if the scaling is non-harmonic, use crude bitshifting (2^k scaling)
% see the synopsis for an explanation of what gets used
% see the webdocs for a demonstration on the significance
%
% if any substantial incentive for further development of nonharmonic wide int conversions is demonstrated, 
% the bitshifting fallback might get replaced with some bespoke nightmare 128b abomination or a collage of conditional 
% workarounds in some blind attempt to winnow optimal performance out of the hypothetical request for the absurd.
% otherwise i'll rest knowing that nobody actually needs these stupid delusions of ultrahigh precision image processing in silly bitwidths.  
%
% i'd love for TMW to build a proper parametric imcast(), even just the native implicit part --
% but we can't exactly expect them to also build a time machine, now can we?
% so long as i'm obligated to care about cross-version compatibility,
% MIMT imcast() will always need to exist to plaster over the eval-bait that is im2uintx().

	% let's just make sure crap gets clamped
	% and make sure we're in the presumed container class
	% this prepares us for the short-circuit output
	% and it prevents out-of-range inputs from causing overflows on integer-path
	if any(inclass(1) == 'ui')
		workingclass = buildintclassname(issi,findintcontainerwidth(wsi));
	else
		workingclass = inclass;
	end
	inpict = cast(inpict,workingclass);
	ir = imclassrange(inclass,'native');
	inpict = imclamp(inpict,ir);

	% the short-circuit case still needs to be
	% returned in the expected container class
	if strcmp(inclass,outclass)
		outpict = inpict;
		return;
	end


	if iptmode && all([wsi wso] <= 48)
		% just do what can be done in DPFP
		outpict = arithmeticconv(inpict,inclass,outclass,isso,wso);
	else
		% otherwise, use integer arithmetic or bitshifting as needed
		outpict = intconv(inpict,inclass,outclass,issi,isso,wsi,wso,iptmode);
	end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is used for narrow IPT-style conversions when requested
function outpict = arithmeticconv(inpict,inclass,outclass,isso,wso)
	% get derived parameters
	if ~isnan(wso) % for native/non-native integer outputs
		cwo = findintcontainerwidth(wso);
		coutclass = buildintclassname(isso,cwo);
	else % for float outputs
		coutclass = outclass;
	end
	
	ir = imclassrange(inclass);
	or = imclassrange(outclass);
	scalefactor = diff(or)/diff(ir);
	switch outclass(1)
		case {'d','s','u','l'} % unsigned output
			outpict = (double(inpict) - ir(1))*scalefactor;
		case 'i' % signed output
			outpict = round((double(inpict) - ir(1))*scalefactor) + or(1);
	end
	
	if strcmp(outclass,'logical')
		outpict = outpict >= 0.5;
	else
		outpict = imclamp(outpict,or); % don't let data spill out into the container class
		outpict = cast(outpict,coutclass);
	end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% front-end for the integer conversions
function outpict = intconv(inpict,inclass,outclass,issi,isso,wsi,wso,iptmode)
	convtype = [inclass(1) outclass(1)];
	cwi = findintcontainerwidth(wsi);
	cwo = findintcontainerwidth(wso);
	
	switch convtype
		case {'uu','ii','ui','iu'}
			outpict = nnintcast(inpict,inclass,outclass,issi,isso,wsi,wso,cwi,cwo,iptmode);

		case {'ud','us','id','is'}
			% in order to maintain rounding symmetry, signed integer data
			% must be shifted prior to normalization or rounding
			if convtype(1) == 'i'
				inclass0 = inclass;
				inclass = ['u' inclass];
				inpict = nnintcast(inpict,inclass0,inclass,true,false,wsi,wsi,cwi,cwi,iptmode);
			end
			inrange = imclassrange(inclass);
			outpict = cast(inpict,outclass)/inrange(2);
			
		case {'du','su','di','si'}
			% same story here.  do all arithmetic conversions on one side of zero
			if convtype(2) == 'i'
				outclass0 = outclass;
				outclass = ['u' outclass];
			end
			outrange = imclassrange(outclass);
			containerclasso = buildintclassname(false,cwo);
			outpict = cast(double(inpict)*outrange(2),containerclasso);
			if convtype(2) == 'i'
				outpict = nnintcast(outpict,outclass,outclass0,false,true,wso,wso,cwo,cwo,iptmode);
			end
			
		case {'lu' 'li'}
			% naive arithmetic gets problematic for big int, so avoid it
			outrange = imclassrange(outclass,'native');
			outpict = repmat(outrange(1),size(inpict));
			outpict(inpict) = outrange(2);
			
		case 'ul'
			outpict = logical(bitget(inpict,wsi));
		
		case 'il'
			outpict = ~bitget(inpict,wsi);
			
	end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% integer-only conversions
% this is a colossal mess.  maybe i'll clean it up someday.
function x = nnintcast(x0,~,~,issi,isso,wsi,wso,cwi,cwo,iptmode)

	% cast into an appropriate working class
	sz0 = size(x0);
	containergrows = cwo > cwi;
	upscale = wso > wsi;
	cww = max(cwo,cwi);
	workingclass = buildintclassname(issi,cww);
	x0 = cast(x0,workingclass);

	% shift everything from int-format to uint-format
	if issi
		% using typecast() requires vectorization yay!
		% do that on x0 so that it's also vectorized if we need to get its sign bits
		x0 = reshape(x0,1,[]);
		
		mk = bitcmp(bitshift(intmin(workingclass),wsi+1-cww)); % create mask excluding sign extension
		sbit = bitget(x0,wsi); % get the root sign bit
		x = bitand(bitset(x0,wsi,1-sbit),mk); % flip the sign bit and clear any sign extension
		
		% change working class type if necessary
		workingclass = buildintclassname(false,cww);
		x = typecast(x,workingclass);
	else 
		x = x0;
	end

	% rescale as uint
	x = rescalecore(x,workingclass,upscale,wsi,wso,cwo,iptmode);
	
	% restore to int-format if necessary
	if isso	
		if ~issi
			x = reshape(x,1,[]); % we weren't vectorized, so do it now
		end
		workingclass = buildintclassname(true,cww);
		x = typecast(x,workingclass);
		
		if ~issi
			% generating sign extension here is necessary even if output is native-width
			% otherwise we can't do u-i downscale across container boundaries
			% even if wso==cwo, the working class is wider, so we'd still to extend sign bits
			x = bitset(x,wso,1-bitget(x,wso)); % flip root sign bit
			db = cww-wso;
			if db ~= 0
				x = bitshift(bitshift(x,db),-db); % exploit bitshift to get the sign extension bits
			end
		else
			% we don't need to generate sign extension, since we already have all the old bits
			% for large arrays, this can save some time
			mk = bitshift(intmin(workingclass),wso-cww); % create mask covering new sign extension
			x = bitor(bitand(x,bitcmp(mk)),bitand(bitshift(x0,wso-wsi),mk)); % reuse shifted root+extended sign bits
		end
	end
	
	if issi || isso
		x = reshape(x,sz0); % devectorize
	end

	% if we haven't already adopted the final container class, do so now
	if ~containergrows
		x = cast(x,buildintclassname(isso,cwo));
	end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% everything here is uint-uint rescaling
%
% the proposal for generalized wide rescaling in IPT-mode (harmonic and non-harmonic)
% involves splitting data across 128b and doing some sort of multiply-then-divide 
% rescaling using bespoke bitwise shifters and adders that can act across the split word, 
% since nothing native will treat two 64b numbers as one 128b number.  
% ... or alternatively something else of similar ridiculousness.
%
% considering how absurdly small 1LSB is at this scale and how unlikely it is that
% someone will need such an oddball wide-int conversion, i can't imagine that it's 
% worth the effort. i'm probably the only person in the universe who cares about
% a 3 parts-per-quadrillion reduction in peak contrast error. 

function outpict = rescalecore(inpict,workingclass,upscale,wsi,wso,cwo,iptmode)
	% we'll need this
	ucout = buildintclassname(false,wso);
	or = cast(imclassrange(ucout,'native'),workingclass);
	
	if wsi~=wso % bypass for typechanges
		if iptmode && (mod(max(wsi,wso)/min(wsi,wso),1) == 0)
			% this is only correct for harmonic rescaling.
			% otherwise, don't use this
			ucin = buildintclassname(false,wsi);		
			ir = cast(imclassrange(ucin,'native'),workingclass);

			% scalefactor should be an integer >1
			if upscale
				sfi = diff(or)/diff(ir);
				outpict = (inpict - ir(1))*sfi;
			else
				sfi = diff(ir)/diff(or);
				outpict = (inpict - ir(1))/sfi;
			end
		else
			% for non-harmonic wide-int conversions, 
			% just use naive power-of-2 rescaling
			outpict = uurescale(inpict,wsi,wso);
		end
	else 
		outpict = inpict;
	end
	
	% don't let data spill out into the container class.
	% since input scale is asserted when explicit, we can't trust that an ostensibly native input is clamped.
	% this only needs to happen for NNI output, regardless of whether the input appears native.
	% this needs to happen now, while we're still in uint, otherwise the integer scaling factor
	% will create out-of-range data which can screw up the output type conversion
	if wso < cwo
		outpict = imclamp(outpict,or);
	end
end

function y = uurescale(x,wsi,wso)
	% rescale uint-uint by a simple power-of-2 shift
	% this isn't the same as we'd expect from other tools
	% e.g. consider feeding a uint16 array to im2uint8();
	% the output is x*255/65535; i.e. x/257
	% uurescale() would only do x/256
	y = bitshift(x,wso-wsi); % up or down shift
	for k = 2:ceil(wso/wsi)  % only used during up shifts
		y = bitor(y,bitshift(x,wso-k*wsi));
	end
end
