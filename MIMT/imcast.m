function [outpict inclass] = imcast(inpict,varargin)
%   OUTPICT = IMCAST(INPICT,OUTCLASS)
%   [OUTPICT INCLASS] = IMCAST(INPICT,OUTCLASS)
%   Scale and recast image data and return class of input.  MIMT imcast() is to IPT
%   im2uint8() and im2double(), what cast() is to uint8() and double().
%
%   This is a convenience not only because it parameterizes the class assignment, 
%   but it supports a broader range of classes and scales.  For implementing a class-
%   agnostic workflow, imcast() is more succinct and capable than the alternatives.
%
%   MIMT imcast() also improves portability and potential speed, using precompiled IPT 
%   tools when available.  If IPT is not installed, m-code conversions are used instead.
%
%   INPICT is an image or array of any supported class
%   OUTCLASS is a string specifying the output class
%     Supported classes for input/output are:
%     'uint8','uint16','uint32','uint64',
%     'int8','int16','int32','int64',
%     'double','single','logical'
%
%   Optional output argument INCLASS returns the class name of the original input.
%
%   TYPICAL USAGE EXAMPLE:
%   % convert unknown input to a known class
%      [workingcopy inclass] = imcast(inpict,'double');
%   % do a bunch of operations in floating point
%      workingcopy = someoperation(workingcopy);
%   % recast output to match original image class
%      outpict = imcast(workingcopy,inclass);
%
%   NOTES:
%   When casting an image as logical, the behavior is to threshold the image at 50% gray.  
%   Casting using logical() itself is rarely useful in image contexts, as its behavior 
%   presents a conceptual inconsistency. For float and unsigned integers, logical() 
%   implicitly selects "not exactly black", whereas for signed integer images, it selects 
%   "not exactly 50% gray".  The behavior is inconsistent, and neither case is likely
%   to split an intensity distribution in a useful manner.
% 
%   The simple thresholding performed by imcast() was chosen only in lieu of a magic 
%   universal automatic binarization routine.  If you want tailored image binarization, 
%   imcast() and logical() are the wrong tools.  If you instead have a nominally 
%   binarized numeric image (e.g. a degraded JPG of a binary mask), imcast() will easily 
%   reduce it to a logical mask regardless of its class.
%
%   Obviously, some conversions are lossy.  Converting from a wider integer class
%   to a narrower one will result in loss of information.  Converting from float 
%   classes to narrower integer classes will also be lossy.  Same goes for uint32/int32 
%   to 'single' and uint64/int64 to either float class.  
%
%   Keep this latter point in mind before you ever consider working in uint64/int64.  
%   Given that most tools do their internal operations in 'double', there is no real 
%   advantage to using 64b integer images. There are also numerous limitations on the
%   usability of 64b integer arrays, depending on the version.  The purpose of including 
%   64b support in imcast() is to handle import/export conversion when absolutely necessary, 
%   not for supporting general 64b workflows.  
%
%   Bear in mind that while imcast() supports many classes, only the following 
%   classes have any broad support beyond MIMT tools:
%     'uint8','uint16','int16','double','single','logical'
%
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   NONSTANDARD EXPLICIT SYNTAX:
%   [...] = IMCAST(INPICT,INCLASS,OUTCLASS)
%   An optional two-parameter format is available for certain atypical needs.  
%   When called with this explicit form, the class of INPICT is ignored, and the data
%   therein is handled as asserted by the user.  These explicit class assertions may 
%   either be a standard numeric class (those listed above), or they may be any hypothetical
%   non-native integer scale (e.g. 'uint4','uint10','int24', etc).  When a non-native
%   integer scale is specified for the output, the data will be scaled and clamped according to 
%   OUTCLASS, and the result will be cast as the smallest native class which can contain it.
% 
%   When used with the explicit syntax, the output argument INCLASS will match the user
%   assertion on the input, not the apparent class of INPICT.
%
%   For example:
%   % result will be [0 2039 4095], class 'uint16'
%     outpict = imcast([0 127 255],'uint8','uint12');
%   % result is [0 4095 4095]. although the input is >>15, output is constrained to uint12-scale
%     outpict = imcast([0 50 100],'uint4','uint12');
%   % result will be [0 0 1 1], class 'logical'
%     outpict = imcast([0 511 512 1023],'uint10','logical');
%
%   NOTES:
%   In explicit mode, setting INCLASS = OUTCLASS will not necessarily leave the input unchanged.   
%   Even in this short-circuit case, the input will still be returned cast and clamped as both 
%   scale assertions imply it should be, regardless of its apparent class.  
%
%   Explicit integer conversions may be performed in one of two ways.  Consider a uint16-uint8 
%   downscaling.  IPT im2uint8() would calculate Y = X/((2^16 - 1)/(2^8 - 1)) = round(X/257), 
%   whereas conventional bitshifting would be Y = X/2^(16-8) = fix(X/256).  With the applied  
%   rounding, this amounts to a symmetric difference in bin alignment at the interval ends.   
%   The result is that the default IPT style is a slightly better approximation of the ideal 
%   linear transformation between the implied interval endpoints.  See the webdocs demos.
% 
%   This is worth noting, as the default IPT-style behavior applies to all harmonic rescaling up 
%   to 64b, but non-harmonic rescalings only up to 48b.  Otherwise, the rescaling is done bitwise.  
%   For the curious, the bitwise method can be forced for any explicit conversion by passing a 
%   third key 'bitshift'.  
%
%   Explicit usage bypasses IPT passthrough and all optimizations made for speed. 
%   It should go without saying that this explicit usage is not recommended for general use.
%   Like the implicit-mode 64b support, the purpose is specialty import/export accomodation.
%   Don't go creating improperly-scaled images unless you know how to handle them -- because
%   most scale-dependent image processing tools won't know how.  
%
%   Most conversions have been tested back to R2009b, but some wide integer conversions 
%   will require R2012b or newer. 
%
%  See also: isimageclass, imclassrange, imrescale

iptmode = true;			
switch nargin
	case 2
		isexplicit = false;
		inclass = class(inpict);
		outclass = varargin{1};
	case 3
		isexplicit = true;
		inclass = varargin{1};
		outclass = varargin{2};
	case 4
		isexplicit = true;
		inclass = varargin{1};
		outclass = varargin{2};
		if strcmpi(varargin{3},'bitshift')
			iptmode = false;
		else
			error('IMCAST: unknown option %s',varargin{3})
		end
	otherwise
		error('IMCAST: incorrect number of arguments')
end

inclass = char(lower(inclass));
outclass = char(lower(outclass));

% don't use the generalized integer tools if nothing is actually integer-class
if isexplicit 
	nonintclasses = {'double','single','logical'};
	if strismember(inclass,nonintclasses) && strismember(outclass,nonintclasses)
		% to be consistent with other explicit modes
		if strcmp(inclass,'logical') % adopt the asserted class
			inpict = inpict >= 0.5; % logical
		else
			inpict = cast(inpict,inclass); % float
			inpict = imclamp(inpict); % clamp to unit-scale
		end
		% we've resolved the input class and scale assertion
		% at this point, the work can be done on the implicit path
		isexplicit = false;
	end
end

% don't passthrough if explicit
% that way imcast() can use an appropriate container class
% if the input and output are both the same non-native integer class.
% that way, all explicit usages are consistent, even in the apparently trivial case.
if strcmp(inclass,outclass) && ~isexplicit
	outpict = inpict;
	return
end

% IF IPT IS INSTALLED
% native m-code methods are slower than the IPT methods
% IPT methods use precompiled private conversion functions, so try to use that first
% im2double() has been moved out of IPT, but the other tools have not
validiptclasses = {'uint8','uint16','int16','double','single','logical'};
validinipt = strismember(inclass,validiptclasses);
validoutipt = strismember(outclass,validiptclasses(1:end-1)); % logical-out is handled MIMT-only

if hasipt() && validinipt && validoutipt && ~isexplicit
	switch outclass
		case 'uint8'
			outpict = im2uint8(inpict);
		case 'double'
			outpict = im2double(inpict);
		case 'single'
			outpict = im2single(inpict);
		case 'uint16'
			outpict = im2uint16(inpict);
		case 'int16'
			outpict = im2int16(inpict);	
	end
	return;
end

% IF IPT IS NOT INSTALLED OR IS NOT APPLICABLE
% i'm not sure how to make this much faster in m-code
validclasses = {'uint8','uint16','uint32','uint64', ...
				'int8','int16','int32','int64', ...
				'double','single','logical'};
isvalidmimt = false(1,2); % [in out]
isvalidmimt(1) = strismember(inclass,validclasses);
isvalidmimt(2) = strismember(outclass,validclasses);

if all(isvalidmimt) && ~isexplicit
	% for most cases, this giant switch-case tree can be replaced with a succinct arithmetic conversion:
	%  ir = imclassrange(inclass);
	%  or = imclassrange(outclass);
	%  scalefactor = diff(or)/diff(ir);
	%  outpict = cast(round((double(inpict) - ir(1))*scalefactor) + or(1),outclass); % correct for int outputs
	%  outpict = cast((double(inpict) - ir(1))*scalefactor,outclass); % simplified for float/uint outputs
	%
	% the reason for the seemingly redundant round() call in the example above is the fact that round() 
	% (which is what cast() uses) rounds half-integers away from zero.  in order for uint/int outputs to both round 
	% similarly in the lower half of their domain, the rounding needs to happen before the data spans zero.  
	% this is consistent with the behavior of the IPT tools.
	% 
	% while the arithmetic approach would satisfy most cases succinctly, it's never optimized for any.  
	% execution times are on average 2-5x as long compared to a giant switch with literal constants.
	% trying to break up the expression into conditionally-executed parts is often even slower,
	%
	% these timings are based on a 850x1400x3 input, and an advantage remains until inputs are small (and measurement becomes questionable)
	% the relative advantage of the flat approach diminishes to near-unity in old versions (e.g. R2009b)
	%
	% so for sake of speed, this is implemented as a giant jumbled mess of magic numbers like it was before
	% some cases are handled using the arithmetic approach; others (wide integer conversions) use slower
	% integer arithmetic and direct bitwise operations for sake of maintaining accuracy beyond what arithmetic 
	% in double float can provide. even if the absolute difference is small, something like imcast() needs to 
	% be as invisible as possible.

	switch inclass
		case 'uint8'
			switch outclass
				case 'uint8'
					% bypassed case
				case 'uint16'
					outpict = uint16(inpict)*257;
				case 'uint32'
					outpict = uint32(inpict)*16843009;
				case 'int8'
					outpict = int8(double(inpict) - 128);
				case 'int16'
					outpict = int16(double(inpict)*257 - 32768);
				case 'int32'
					outpict = int32(double(inpict)*16843009 - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,8,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,8,64,true);
				case {'double','single'}
					outpict = cast(inpict,outclass)/255;
				case 'logical'
					outpict = inpict >= 128;
			end

		case 'uint16'
			switch outclass
				case 'uint8'
					outpict = uint8(inpict/257);
				case 'uint16'
					% bypassed case
				case 'uint32'
					outpict = uint32(inpict)*65537;
				case 'int8'
					outpict = int8(double(inpict)/257 - 128);
				case 'int16'
					outpict = int16(double(inpict) - 32768);
				case 'int32'
					outpict = int32(double(inpict)*65537 - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,16,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,16,64,true);
				case {'double','single'}
					outpict = cast(inpict,outclass)/65535;
				case 'logical'
					outpict = inpict >= 32768;
			end

		case 'int16'
			switch outclass
				case 'uint8'
					outpict = uint8((double(inpict) + 32768)/257);
				case 'uint16'
					outpict = uint16(double(inpict) + 32768);
				case 'uint32'
					outpict = uint32((double(inpict) + 32768)*65537);
				case 'int8'
					outpict = int8((double(inpict) + 32768)/257 - 128);
				case 'int16'
					% bypassed case
				case 'int32'
					outpict = int32((double(inpict) + 32768)*65537 - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,16,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,16,64,true);
				case {'double','single'}
					outpict = (cast(inpict,outclass) + 32768)/65535;
				case 'logical'
					outpict = inpict >= 0;
			end

		case {'double','single','logical'}
			switch outclass
				case 'uint8'
					outpict = uint8(double(inpict)*255);
				case 'uint16'
					outpict = uint16(double(inpict)*65535);
				case 'uint32'
					outpict = uint32(double(inpict)*4294967295);
				case 'int8'
					outpict = int8(round(double(inpict)*255) - 128);
				case 'int16'
					outpict = int16(round(double(inpict)*65535) - 32768);
				case 'int32'
					outpict = int32(round(double(inpict)*4294967295) - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,NaN,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,NaN,64,true);
				case {'double','single'}
					outpict = cast(inpict,outclass);
				case 'logical'
					outpict = inpict >= 0.5;
			end

		case 'uint32'
			switch outclass
				case 'uint8'
					outpict = uint8(inpict/16843009);
				case 'uint16'
					outpict = uint16(inpict/65537);
				case 'uint32'
					% bypassed case
				case 'int8'
					outpict = int8(double(inpict)/16843009 - 128);
				case 'int16'
					outpict = int16(double(inpict)/65537 - 32768);
				case 'int32'
					outpict = int32(double(inpict) - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,32,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,32,64,true);
				case 'double'
					outpict = double(inpict)/4294967295;
				case 'single'
					outpict = single(double(inpict)/4294967295);
				case 'logical'
					outpict = inpict >= 2147483648;
			end
			
		case 'int8'
			switch outclass
				case 'uint8'
					outpict = uint8(double(inpict) + 128);
				case 'uint16'
					outpict = uint16((double(inpict) + 128)*257);
				case 'uint32'
					outpict = uint32((double(inpict) + 128)*16843009);
				case 'int8'
					% bypassed case
				case 'int16'
					outpict = int16((double(inpict) + 128)*257 - 32768);
				case 'int32'
					outpict = int32((double(inpict) + 128)*16843009 - 2147483648);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,8,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,8,64,true);
				case {'double','single'}
					outpict = (cast(inpict,outclass) + 128)/255;
				case 'logical'
					outpict = inpict >= 0;
			end

		case 'int32'
			switch outclass
				case 'uint8'
					outpict = uint8((double(inpict) + 2147483648)/16843009);
				case 'uint16'
					outpict = uint16((double(inpict) + 2147483648)/65537);
				case 'uint32'
					outpict = uint32(double(inpict) + 2147483648);
				case 'int8'
					outpict = int8((double(inpict) + 2147483648)/16843009 - 128);
				case 'int16'
					outpict = int16((double(inpict) + 2147483648)/65537 - 32768);
				case 'int32'
					% bypassed case
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,32,64,true);
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,32,64,true);
				case 'double'
					outpict = (double(inpict) + 2147483648)/4294967295;
				case 'single'
					outpict = single((double(inpict) + 2147483648)/4294967295);
				case 'logical'
					outpict = inpict >= 0;
			end
			
		case 'uint64'
			switch outclass
				case 'uint8'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,64,8,true);
				case 'uint16'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,64,16,true);
				case 'uint32'
					outpict = combonnintconv(inpict,inclass,outclass,false,false,64,32,true);
				case 'int8'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,64,8,true);
				case 'int16'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,64,16,true);
				case 'int32'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,64,32,true);
				case 'uint64'
					% bypassed case
				case 'int64'
					outpict = combonnintconv(inpict,inclass,outclass,false,true,64,64,true);
				case {'double','single','logical'}
					outpict = combonnintconv(inpict,inclass,outclass,false,false,64,NaN,true);
			end
			
		case 'int64'
			switch outclass
				case 'uint8'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,64,8,true);
				case 'uint16'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,64,16,true);
				case 'uint32'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,64,32,true);
				case 'int8'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,64,8,true);
				case 'int16'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,64,16,true);
				case 'int32'
					outpict = combonnintconv(inpict,inclass,outclass,true,true,64,32,true);
				case 'uint64'
					outpict = combonnintconv(inpict,inclass,outclass,true,false,64,64,true);
				case 'int64'
					% bypassed case
				case {'double','single','logical'}
					outpict = combonnintconv(inpict,inclass,outclass,true,false,64,NaN,true);
			end
			
	end
	
elseif isexplicit
	% i'm not concerned with optimizing this branch for speed.
	% like everything, i'm sure this rat's nest could be simplified.

	% if a nonstandard class is explicitly specified, 
	% make sure it's a valid non-native integer spec	
	[isinti issi wsi] = parseintclassname(inclass);
	[isinto isso wso] = parseintclassname(outclass);
	isvalidmimt = isvalidmimt | [isinti isinto];
	
	% if a non-mimt specification was also not a non-native int spec
	if any(~isvalidmimt)
		badclassspec()
	end
		
	% just shove it through this big pile of garbage
	outpict = combonnintconv(inpict,inclass,outclass,issi,isso,wsi,wso,iptmode);
	
else
	badclassspec()
end

function badclassspec()
	% barfs an error if input/output class is invalid
	if all(~isvalidmimt)
		error('IMCAST: input class %s and output class %s are both unsupported',inclass,outclass)
	elseif ~isvalidmimt(1)
		error('IMCAST: unsupported class %s for input',inclass)
	else
		error('IMCAST: unsupported class %s for output',outclass)
	end
end

end % END MAIN SCOPE





























