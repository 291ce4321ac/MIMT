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
%   When casting an image as logical, the behavior is to threshold
%   the image at 50% gray. This differs from the behavior of logical(inpict), 
%   which simply sets all nonzero pixels to 1 (i.e. outpict = inpict~=0).  
%   This behavior of logical() is rarely useful in image contexts, and it
%   presents a conceptual inconsistency. For float and unsigned integers, 
%   logical() implicitly selects "only perfectly black", whereas for signed 
%   integer images, it selects "only exactly 50% gray".  
%   The simple thresholding performed by imcast() was chosen only in lieu of a 
%   magic universal automatic binarization routine.  If you want tailored image 
%   binarization, imcast() and logical() are the wrong tools.    
%
%   Bear in mind that while imcast() supports many classes, only the following 
%   classes have any broad support among MIMT and IPT image handling tools:
%     'uint8','uint16','int16','double','single','logical'
%   so don't be surprised if your new int32 image won't display as expected.
%
%   INPICT is an image or array of any supported class
%   OUTCLASS is a string describing any supported class
%   
%   Supported classes are:
%     'uint8','uint16','uint32','int8','int16','int32',
%     'double','single','logical'
%
%   Optional output argument INCLASS returns the class of the original input.
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
outclass = lower(outclass);

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
	% this giant switch-case tree can be replaced with a succinct conversion:
	%  ir = imclassrange(inclass);
	%  or = imclassrange(outclass);
	%  scalefactor = diff(or)/diff(ir);
	%  outpict = cast((double(inpict) - ir(1))*scalefactor + or(1),outclass);
	%
	% while that would satisfy all cases, it's never optimized for any
	% execution times are on average 2-2.5x as long compared to a giant switch with precalculated constants
	% trying to break up the expression into conditionally-executed parts is often even slower
	% possibly because the explicit allocation of intermediate results is defeating some internal
	% optimizations that can be obtained with a single inline expression
	%
	% these timings are based on a 850x1400x3 input, and an advantage remains until inputs are small (and measurement becomes questionable)
	% the relative advantage of the verbose approach diminishes to near-unity in old versions (e.g. R2009b)
	%
	% so for sake of speed, this is implemented as a giant mess like it was before
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
				case {'double','single'}
					outpict = (cast(inpict,outclass) + 32768)/65535;
				case 'logical'
					outpict = inpict >= 0;
			end

		case {'double','single','logical'}
			inpict = double(inpict);
			switch outclass
				case 'uint8'
					outpict = uint8(inpict*255);
				case 'uint16'
					outpict = uint16(inpict*65535);
				case 'uint32'
					outpict = uint32(inpict*4294967295);
				case 'int8'
					outpict = int8(inpict*255 - 128);
				case 'int16'
					outpict = int16(inpict*65535 - 32768);
				case 'int32'
					outpict = int32(inpict*4294967295 - 2147483648);
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
				case {'double','single'}
					outpict = cast(inpict,outclass)/4294967295;
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
				case {'double','single'}
					outpict = (cast(inpict,outclass) + 2147483648)/4294967295;
				case 'logical'
					outpict = inpict >= 0;
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
