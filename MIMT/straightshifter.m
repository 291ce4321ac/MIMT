function  inpict = straightshifter(inpict,amt)
%   STRAIGHTSHIFTER(INPICT, SHIFTAMOUNT)
%       shifts all rows and columns by the amount specified in AMOUNT
%       all shifts are circular
%
%   INPICT is an I/RGB image of any standard image class
%   SHIFTAMOUNT specifies the shift amounts (in pixels)
%       for RGB inputs, expressed as a 3x2 array [Rx Ry; Gx Gy; Bx By]
%       can also be expressed as a 1x2 vector with implicit expansion
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/straightshifter.html
    
	[cc ~] = chancount(inpict);
	inpict = inpict(:,:,1:cc);

	% expand/collapse amount parameter
	if size(amt,1) == 1 && cc == 3
		amt = repmat(amt,[cc 1]);
	elseif size(amt,1) == 3 && cc == 1
		amt = amt(1,:);
	end
	amt = round(amt);
	
	for c = 1:cc
		inpict(:,:,c) = circshift(inpict(:,:,c),amt(c,[2 1]));
	end
    
return

