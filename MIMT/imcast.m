function [outpict inclass] = imcast(inpict,outclass)
%   OUTPICT = IMCAST(INPICT,OUTCLASS)
%   [OUTPICT INCLASS] = IMCAST(INPICT,OUTCLASS)
%   Scale and recast image data and return class of input.  This is more 
%   succinct than using getrangefromclass() and im2double(), im2uint8(), etc.
%   
%   This is a convenience not only because it is succinct and parameterizes 
%   the class assignment, but it also increases portability and potential 
%   speed, using precompiled IPT tools when available.  If IPT is not installed, 
%   m-code conversions are used instead.
%
%   INPICT is an image or array of any supported class
%   OUTCLASS is a string specifying the output class
%     Supported classes are:
%     'uint8','uint16','uint32','uint64',
%     'int8','int16','int32','int64',
%     'double','single','logical'
%
%   Optional output argument INCLASS returns the class name of the original input.
%
%   NOTES:
%   When casting an image as logical, the behavior is to threshold the image at 50% gray.  
%   Casting using logical() itself is rarely useful in image contexts, as its behavior 
%   presents a conceptual inconsistency. For float and unsigned integers, logical() 
%   implicitly selects "not exactly black", whereas for signed integer images, it selects 
%   "not exactly 50% gray".  The behavior is inconsistent, and neither case is likely
%   to split an intensity distribution in a useful manner.
% 
%   The simple thresholding performed by imcast() was chosen only in lieu of a 
%   magic universal automatic binarization routine.  If you want tailored image 
%   binarization, imcast() and logical() are the wrong tools.  If you instead have a 
%   nominally binarized numeric image (e.g. a JPG of a binary mask), imcast() will 
%   easily reduce it to a logical mask regardless of its class.
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
%   classes have any broad support among MIMT and IPT image handling tools:
%     'uint8','uint16','int16','double','single','logical'
%   so don't be surprised if your new int32 image won't display as expected.
%   
%   Most conversions have been tested back to R2009b, but some wide signed-integer 
%   conversions will require R2012b or newer.  
%
%   TYPICAL USE:
%   % convert unknown input to a known class
%      [workingcopy inclass] = imcast(inpict,'double');
%   % do a bunch of operations in floating point
%      workingcopy = someoperation(workingcopy);
%   % recast output to match original image class
%      outpict = imcast(workingcopy,inclass);
%
%  See also: isimageclass, imclassrange, imrescale

inclass = class(inpict);
outclass = char(lower(outclass));

if strcmp(inclass,outclass)
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

if hasipt() && validinipt && validoutipt
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
validin = strismember(inclass,validclasses);
validout = strismember(outclass,validclasses);

if validin && validout
	% for most cases, this giant switch-case tree can be replaced with a succinct arithmetic conversion:
	%  ir = imclassrange(inclass);
	%  or = imclassrange(outclass);
	%  scalefactor = diff(or)/diff(ir);
	%  outpict = cast((double(inpict) - ir(1))*scalefactor + or(1),outclass);
	% 
	% or instead of a purely arithmetic approach, the task can be done using tools like typecast()/bitget()/bitset() 
	% and some replication and reshaping.  this would be the approach used for large integer class conversions anyway.
	%
	% while the arithmetic approach would satisfy all cases, it's never optimized for any.  
	% execution times are on average 2-2.5x as long compared to a giant switch with literal constants.
	% trying to break up the expression into conditionally-executed parts is often even slower,
	% possibly because the explicit allocation of intermediate results is defeating some internal
	% optimizations that can be obtained with a single inline expression.
	% likewise, the direct binary manipulation approach is more verbose, and tends to be even slower.
	%
	% these timings are based on a 850x1400x3 input, and an advantage remains until inputs are small (and measurement becomes questionable)
	% the relative advantage of the flat approach diminishes to near-unity in old versions (e.g. R2009b)
	%
	% so for sake of speed, this is implemented as a giant jumbled mess like it was before
	% some cases are handled using the arithmetic approach; others (wide integer conversions) use the slower
	% direct approach for sake of maintaining accuracy beyond what arithmetic in double float can provide.
	% even if the absolute difference is small, something like imcast() needs to be as invisible as possible

	% u/i/f/l > u/i/f conversions
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,8,64);
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,16,64);
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,16,64);
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
					outpict = int8(double(inpict)*255 - 128);
				case 'int16'
					outpict = int16(double(inpict)*65535 - 32768);
				case 'int32'
					outpict = int32(double(inpict)*4294967295 - 2147483648);
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,NaN,64);
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,32,64);
				case 'double'
					outpict = cast(inpict,outclass)/4294967295;
				case 'single'
					outpict = bigintconv(inpict,inclass,outclass,32,NaN);
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,8,64);
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
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,32,64);
				case 'double'
					outpict = (cast(inpict,outclass) + 2147483648)/4294967295;
				case 'single'
					outpict = bigintconv(inpict,inclass,outclass,32,NaN);
				case 'logical'
					outpict = inpict >= 0;
			end
			
		case {'uint64','int64'}
			switch outclass
				case {'uint8','int8'}
					outpict = bigintconv(inpict,inclass,outclass,64,8);
				case {'uint16','int16'}
					outpict = bigintconv(inpict,inclass,outclass,64,16);
				case {'uint32','int32'}
					outpict = bigintconv(inpict,inclass,outclass,64,32);
				case {'uint64','int64'}
					outpict = bigintconv(inpict,inclass,outclass,64,64);
				case {'double','single','logical'}
					outpict = bigintconv(inpict,inclass,outclass,64,NaN);
			end
			
	end
	
else
	if ~validin
		error('IMCAST: unsupported class %s for input',inclass)
	else
		error('IMCAST: unsupported class %s for output',outclass)
	end
end

end % END MAIN SCOPE


% a lot of this can probably be simplified now that it's no longer used in a general fashion
% but i'm lazy.
function outpict = bigintconv(inpict,inclass,outclass,wsi,wso)
	convtype = [inclass(1) outclass(1)];
	wordscale = wso/wsi;
	switch convtype
		case 'uu'
			if wordscale < 1 % converting to a narrower class
				outpict = reshape(inpict,1,[]);
				outpict = typecast(outpict,outclass);
				outpict = outpict(1/wordscale:1/wordscale:end);
				outpict = reshape(outpict,size(inpict));
			elseif wordscale == 1 % converting to same width
				outpict = inpict;
			elseif wordscale > 1 % converting to a wider class
				outpict = reshape(inpict,1,[]);
				outpict = reshape(repmat(outpict,[wordscale 1]),1,[]);
				outpict = typecast(outpict,outclass);
				outpict = reshape(outpict,size(inpict));
			end
			
		case 'ii'
			if wordscale < 1 % converting to a narrower class
				outpict = reshape(inpict,1,[]);
				outpict = typecast(outpict,outclass);
				outpict = outpict(1/wordscale:1/wordscale:end);
				outpict = reshape(outpict,size(inpict));
			elseif wordscale == 1 % converting to same width
				outpict = inpict;
			elseif wordscale > 1 % converting to a wider class
				outpict = reshape(inpict,1,[]);
				res = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = reshape([repmat(res,[wordscale-1 1]); outpict],1,[]);
				outpict = typecast(outpict,outclass);
				outpict = reshape(outpict,size(inpict));
			end

		case 'ui'
			outpict = reshape(inpict,1,[]);
			if wordscale < 1 % converting to a narrower class
				outpict = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = typecast(outpict,outclass);
				outpict = outpict(1/wordscale:1/wordscale:end);
			elseif wordscale == 1 % converting to same width
				outpict = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = typecast(outpict,outclass);
			elseif wordscale > 1 % converting to a wider class
				outpict = reshape(repmat(outpict,[wordscale 1]),1,[]);
				outpict = typecast(outpict,outclass);
				outpict = bitset(outpict,wso,1-bitget(outpict,wso));
			end
			outpict = reshape(outpict,size(inpict));
			
		case 'iu'
			outpict = reshape(inpict,1,[]);
			if wordscale < 1 % converting to a narrower class
				outpict = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = typecast(outpict,outclass);
				outpict = outpict(1/wordscale:1/wordscale:end);
			elseif wordscale == 1 % converting to same width
				outpict = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = typecast(outpict,outclass);
			elseif wordscale > 1 % converting to a wider class
				outpict = bitset(outpict,wsi,1-bitget(outpict,wsi));
				outpict = reshape(repmat(outpict,[wordscale 1]),1,[]);
				outpict = typecast(outpict,outclass);
			end
			outpict = reshape(outpict,size(inpict));

		case {'ud' 'id' 'us' 'is'}
			% all 64b-double, 64b-single, and 32b-single conversions are lossy
			% reduce error by shifting int data into uint before conversion to float
			if inclass(1) == 'i'
				szi = size(inpict);
				inclass = ['u' inclass];
				inpict = bitset(inpict,wsi,1-bitget(inpict,wsi));
				inpict = reshape(inpict,1,[]);
				inpict = typecast(inpict,inclass);
				inpict = reshape(inpict,szi);
			end
			
			inrange = imclassrange(inclass);
			if convtype(1) == 'u'
				outpict = cast(inpict,outclass)/inrange(2);
			else
				outpict = (cast(inpict,outclass) - inrange(1))/diff(inrange);
			end
			
		case {'du' 'di' 'su' 'si'}
			% shifting also needs to be done here for the same reasons
			if convtype(1) == 'i'
				outclass = ['u' outclass];
				inpict = double(inpict);
			end
			
			outrange = imclassrange(outclass);
			if convtype(2) == 'u'
				outpict = cast(inpict*outrange(2),outclass);
			else
				outpict = cast((inpict*diff(outrange) + outrange(1)),outclass);
			end

			if convtype(1) == 'i'
				szi = size(inpict);
				outpict = bitset(outpict,wso,1-bitget(outpict,wso));
				outpict = reshape(outpict,1,[]);
				outpict = typecast(outpict,outclass(2:end));
				outpict = reshape(outpict,szi);
			end
			
		case {'lu' 'li'}
			% naive arithmetic gets problematic for 64b, so avoid it
			outrange = imclassrange(outclass,'native');
			outpict = repmat(outrange(1),size(inpict));
			outpict(inpict) = outrange(2);
			
		case 'ul'
			outpict = logical(bitget(inpict,wsi));
		
		case 'il'
			outpict = ~bitget(inpict,wsi);
			
	end
end
























