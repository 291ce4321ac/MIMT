function outpict = morphnhood(inpict,varargin)
%   OUTPICT=MORPHNHOOD(INPICT,MODE,{NHOOD},NUMPASSES)
%   Perform the selected morphological neighborhood operation on an image.  
%
%   This is a passthrough to the IPT functions bwmorph(), bwperim(), and bwlookup(), with internal 
%   fallback implementations to help remove the dependency of MIMT tools on the Image Processing Toolbox. 
%   As with other fallback tools, performance without IPT may be degraded due to the methods used.  
%
%   INPICT is an image of any standard image class. Multichannel and multiframe images are supported.
%      Proper inputs should be logical; numeric images will be thresholded at 50% gray.
%
%   MODE specifies the operation to perform
%      'dilate'    fill pixels which possess >=1 8-neighbors and are themselves 0
%      'erode'     remove pixels which possess <8 8-neighbors and are themselves 1
%      'open'      remove small objects -- dilate(erode(inpict))
%      'close'     fill small holes -- erode(dilate(inpict))
%      'tophat'    return only the content removed by opening -- inpict & ~open(inpict) 
%      'bothat'    return only the regions filled by closing -- ~inpict & close(inpict)
%      'fill4'     fill isolated 0's which possess a populated 4-neighborhood (morphops() 'fill')
%      'fill8'     fill isolated 0's which possess a populated 8-neighborhood
%      'bridge'    fill pixels with at least 2 unconnected 8-neighbors
%      'diag'      fill diagonally-connected pixels, breaking 8-connectivity of background
%      'hbreak'    remove H-connected pixels
%      'prune'     remove endpoints from a skeleton; useful for removing open branches
%      'clean4'    remove isolated 1's which possess an empty 4-neighborhood
%      'clean8'    remove isolated 1's which possess an empty 8-neighborhood (morphops() 'clean')
%      'remove4'   remove isolated 1's which possess a full 4-neighborhood (morphops() 'remove')
%      'remove8'   remove isolated 1's which possess a full 8-neighborhood
%      'shrink'    reduce objects to points
%      'thin'      reduce objects to a skeletal line structure
%      'skel'      reduce objects to a skeletal line structure without breaking object connectivity
%      'endpoints' return only edge endpoints of a skeletonized image
%      'majority'  return only pixels which possess >=5 8-neighbors (self included)
%      'perim4'    return only pixels which possess <4 4-neighbors and are themselves 1
%      'perim8'    return only pixels which possess <8 8-neighbors and are themselves 1
%      'matches'   return only pixels which possess the specified neighborhood NHOOD
%      'hasones'   return pixels whose neighborhood includes at least the 1s found in NHOOD
%      'haszeros'  return pixels whose neighborhood includes at least the 0s found in NHOOD
% 
%      It should be noted that 'open', 'close', 'tophat', and 'bothat' don't exactly correspond
%      to the results from using imopen(), imtophat(), etc. with a 3x3 square strel.  
%      Those behaviors match that of morphops().  The behavior of morphnhood() matches bwmorph().
%
%      The input image and the results from modes 'matches', 'hasones', and 'haszeros' can be 
%      logically combined to yield a wide range of pattern matching behaviors.
%
%   NHOOD is a 3x3 array specifying a neighborhood or neighbor subpattern of interest
%      This is only used for the 'match', 'hasones', and 'haszeros' modes.
%
%   NUMPASSES optionally specifies how many times the filter should be applied (default 1)
%      The process will terminate early if the working image reaches a steady state. Modes such
%      as 'prune', 'shrink', 'thin', 'skel' are typically used with a large value for NUMPASSES.
%
%  Output class is logical
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/morphnhood.html
% See also: bwmorph, bwperim, bwlookup, makelut, applylut, morphops, hitmiss


% make fill4 and fill8

numpasses = 1;
nhood = true(3);

if numel(varargin) == 1
	mode = varargin{1};
elseif numel(varargin) == 2
	mode = varargin{1};
	if numel(varargin{2}) == 9
		nhood = varargin{2};
	else
		numpasses = varargin{2};
	end
elseif numel(varargin) == 3
	mode = varargin{1};
	nhood = varargin{2};
	numpasses = varargin{3};
else
	error('MORPHNHOOD: Too many or too few arguments')
end

if ~islogical(inpict)
	inpict = inpict > imrescale(0.5,'double',class(inpict));
end

if islogical(nhood)
	nhood = double(nhood);
end

if isinf(numpasses)
	numpasses = 1E12;
end


% IF IPT IS INSTALLED
% using bwlookup to do custom cases is actually slower, and it wasn't introduced until R2012b anyway
% endpoints mode has a bug in older versions, so just use the FB version
if license('test', 'image_toolbox') && ~strismember(mode,{'matches','hasones','haszeros','fill8','clean4','remove8','endpoints','prune'})
	
	if strcmp(mode,'fill4'); mode = 'fill'; end
	if strcmp(mode,'clean8'); mode = 'clean'; end
	if strcmp(mode,'remove4'); mode = 'remove'; end
	
	outpict = false(size(inpict));
	for f = 1:size(inpict,4)
		for c = 1:size(inpict,3)
			switch mode
				case {'open','close','tophat','bothat','fill','bridge','clean','diag','hbreak','majority','remove','thin','shrink','skel'}
					outpict(:,:,c,f) = bwmorph(inpict,mode,numpasses);
					
				case 'perim4'
					outpict(:,:,c,f) = bwperim(inpict,4);
					
				case 'perim8'
					outpict(:,:,c,f) = bwperim(inpict,8);
					
				case 'dilate'
					thisresult = inpict;
					for n = 1:numpasses
						priorresult = thisresult;
						thisresult = imdilate(thisresult,ones(3));
						if numpasses > 1 % don't bother testing unless we're going to loop anyway
							changedpixels = thisresult ~= priorresult;
							if ~any(changedpixels(:)) % if nothing changed since last pass, don't bother continuing
								break;
							end
						end
					end
					outpict(:,:,c,f) = thisresult;
					
				case 'erode'
					thisresult = inpict;
					for n = 1:numpasses
						priorresult = thisresult;
						thisresult = imerode(thisresult,ones(3));
						if numpasses > 1 % don't bother testing unless we're going to loop anyway
							changedpixels = thisresult ~= priorresult;
							if ~any(changedpixels(:)) % if nothing changed since last pass, don't bother continuing
								break;
							end
						end
					end
					outpict(:,:,c,f) = thisresult;
							
				otherwise
					error('MORPHNHOOD: unknown mode name ''%s''',mode)
			end
		end
	end
	
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% need to convert to a numeric class, since imfilter doesn't handle logical
% uint16 is wide enough to handle the range, and reduces filtering time by about 40% over FP classes
inpict = uint16(inpict); 

% for binary images, these operations can be done by convolution
% this is relatively slow, but it's much faster than loops in m-code

% this works by filtering the image with a weighting array.
% the resultant integral unambiguously identifies the particular neighborhood surrounding each pixel.
% alternatively, we can filter by an index array to identify the presence of a particular subpattern of either 1s or 0s
% using simple masking and comparison, we can identify which pixels need to be altered.
% explicit matching using ismember() is costly, so some effort has been made to avoid the use of match lists

% index masking arrays
se9 = [1 1 1; 1 1 1; 1 1 1];
se8 = [1 1 1; 1 0 1; 1 1 1];
se4 = [0 1 0; 1 0 1; 0 1 0];

% index weighting array
seb = 2.^([1 4 7; 2 5 8; 3 6 9]-1);

for n = 1:numpasses
	priorresult = logical(inpict);
	switch mode
		case 'dilate'
			inpict = uint16(imfilterFB(inpict,se9) >= 1);
		case 'erode'
			inpict = uint16(imfilterFB(inpict,se9) == 9);
		case 'open'
			inpict = uint16(imfilterFB(uint16(imfilterFB(inpict,se9) == 9),se9) >= 1);
		case 'close'
			inpict = uint16(imfilterFB(uint16(imfilterFB(inpict,se9) >= 1),se9) == 9);
		case 'tophat'
			inpict = min(max(inpict - uint16(imfilterFB(uint16(imfilterFB(inpict,se9) == 9),se9) >= 1),0),1);
		case 'bothat'
			inpict = min(max(uint16(imfilterFB(uint16(imfilterFB(inpict,se9) >= 1),se9) == 9) - inpict,0),1);
		case {'fill','fill4'}
			inpict = inpict | uint16(imfilterFB(inpict,se4) == 4);
		case 'fill8'
			inpict = inpict | uint16(imfilterFB(inpict,se8) == 8);
		case 'bridge'
			keysums = [12 13 33 37 40 41 44 45 66 67 68 69 70 71 76 77 96 97 98 99 100 101 102 103 104 105 108 109 129 ...
				130 131 132 133 134 135 140 141 161 165 193 194 195 196 197 198 199 204 205 225 229 257 258 259 261 ...
				262 263 264 265 266 267 268 269 270 271 289 293 296 297 300 301 321 322 323 324 325 326 327 328 329 ...
				330 331 332 333 334 335 352 353 354 355 356 357 358 359 360 361 364 365 385 386 387 388 389 390 391 ...
				396 397 417 421 449 450 451 452 453 454 455 460 461 481 485];
			inpict = uint16(inpict | ismember(imfilterFB(inpict,seb),keysums));
		case 'diag'
			keysums = [10 14 34 35 42 43 46 74 78 98 99 106 107 110 136 137 138 139 140 141 142 143 160 161 162 163 164 ...
				165 166 167 168 169 170 171 172 173 174 175 202 206 224 225 226 227 228 229 230 231 232 233 234 235 ...
				236 237 238 239 266 270 290 291 298 299 302 330 334 354 355 362 363 366 392 393 394 395 396 397 398 ...
				399 418 419 424 425 426 427 428 429 430 431 458 462 482 483 490 491 494];
			inpict = uint16(inpict | ismember(imfilterFB(inpict,seb),keysums));
		case 'endpoints'
			% bwmorph.m > algbwmorph.m > lutendpoints.m returns a bad LUT for this mode.  entry 140 is incorrectly set true.
			% turns out this is a known bug (1292331) affecting R2012b-R2015b
			% this is based on bg connectivity, so avoiding the LUT is expensive.
			keysums = [16 17 18 19 20 22 23 24 25 27 31 48 52 54 55 63 80 88 89 91 95 127 144 208 216 217 219 223 255 ...
				272 304 308 310 311 319 383 400 432 436 438 439 447 464 472 473 475 479 496 500 502 503 504 505 507 508 509 510];
			inpict = uint16(ismember(imfilterFB(inpict,seb),keysums));
		case 'prune'
			keysums = [16 17 18 19 20 22 23 24 25 27 31 48 52 54 55 63 80 88 89 91 95 127 144 208 216 217 219 223 255 ...
				272 304 308 310 311 319 383 400 432 436 438 439 447 464 472 473 475 479 496 500 502 503 504 505 507 508 509 510];
			inpict = uint16(inpict & ~ismember(imfilterFB(inpict,seb),keysums));
		case 'thin'
			keysums = {[23 26 27 30 31 50 51 54 55 58 59 62 63 89 90 91 94 95 122 123 126 127 306 307 308 310 311 314 315 318 319 432 434 435 436 438 439], ...
				[27 89 91 152 153 155 176 180 184 185 188 216 217 219 240 244 248 249 252 308 408 409 411 432 436 440 441 444 464 472 473 475 496 500 504 505 508]};
			for p = 1:2
				inpict = uint16(inpict & ~ismember(imfilterFB(inpict,seb),keysums{p}));
			end
		case 'shrink'
			keysums = [17 18 19 20 22 23 24 25 26 27 30 31 48 50 51 52 54 55 58 59 62 63 80 88 89 90 91 94 95 122 123 126 ...
				127 144 152 153 154 155 158 159 176 178 179 180 182 183 184 185 188 189 208 216 217 218 219 222 223 240 ...
				242 243 244 246 247 248 249 252 253 272 304 306 307 308 310 311 314 315 318 319 378 379 382 383 400 408 ...
				409 410 411 414 415 432 434 435 436 438 439 440 441 444 445 464 472 473 474 475 478 479 496 498 499 500 502 503 504 505 508 509];
			sti = [1 2 1 2; 1 2 2 1];
			for p = 1:4
				tpict = uint16(inpict & ~ismember(imfilterFB(inpict,seb),keysums));
				inpict(sti(1,p):2:end,sti(2,p):2:end) = tpict(sti(1,p):2:end,sti(2,p):2:end);
			end
		case 'skel'
			keysums = {[89 91 217 219],[152 153 216 217 408 409 472 473],[23 31 55 63],[26 27 30 31 90 91 94 95], ...
				[464 472 496 504],[50 51 54 55 306 307 310 311],[308 310 436 438],[176 180 240 244 432 436 496 500]};
			for p = 1:8
				inpict = uint16(inpict & ~ismember(imfilterFB(inpict,seb),keysums{p}));
			end
		case 'majority'
			inpict = uint16(imfilterFB(inpict,se9) >= 5);
		case 'clean4'
			inpict = inpict & ~(imfilterFB(inpict,se4) == 0);
		case {'clean','clean8'}
			inpict = inpict & ~(imfilterFB(inpict,se8) == 0);
		case {'remove','remove4'}
			inpict = inpict & ~(imfilterFB(inpict,se4) == 4);
		case 'remove8'
			inpict = inpict & ~(imfilterFB(inpict,se8) == 8);
		case 'hbreak'
			keysums = [381 471];
			inpict = inpict & ~ismember(imfilterFB(inpict,seb),keysums);
		case 'perim4'
			inpict = inpict & imfilterFB(inpict,se4) < 4;
		case 'perim8'
			inpict = inpict & imfilterFB(inpict,se8) < 8;
		case 'matches'
			inpict = uint16(imfilterFB(inpict,seb) == sum(sum(seb.*nhood)));
		case 'hasones'
			inpict = uint16(imfilterFB(inpict,nhood) == sum(sum(nhood)));
		case 'haszeros'
			inpict = uint16(imfilterFB(inpict,1-nhood) == 0);
		otherwise
			error('MORPHNHOOD: unknown mode name ''%s''',mode)
	end
	
	if numpasses > 1 % don't bother testing unless we're going to loop anyway
		thisresult = logical(inpict);
		changedpixels = thisresult ~= priorresult;
		if ~any(changedpixels(:)) % if nothing changed since last pass, don't bother continuing
			break;
		end
	end
end

% normally, i'd use imcast, but that thresholds at 50% gray, which varies with class
% just want to make sure there aren't any false positives caused by rounding
outpict = inpict > 0.5;	



