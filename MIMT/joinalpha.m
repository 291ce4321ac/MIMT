function outpict = joinalpha(outpict,alpha)
%  OUTPICT = JOINALPHA(INPICT,ALPHA)
%  Concatenate color and alpha channels as split using splitalpha().
%  If the given image already has alpha content, mix it with the new alpha.
%
%  INPICT is an I/IA/RGB/RGBA/RGBAAA image of any standard image class
%  ALPHA is an I/RGB image of any standard image class
%    If INPICT is I/IA and ALPHA is RGB, ALPHA will be reduced to its luma.
%    Alternatively, INPICT or ALPHA may be specified as a color tuple instead  
%    of a full image.  If an argument is specified as a tuple, it must still be 
%    scaled correctly for its class.  If both are specified as tuples, the output 
%    is a single pixel.  All non-tuple image inputs must have the same geometry.
%    If both images are multiframe, their framecounts must match.
%
%  Output class is inherited from input
%
%  Example of using splitalpha()/joinalpha() to handle IA/RGBA images
%    [inpict alpha] = splitalpha(inpict);
%    outpict = blockify(inpict,[10 10]);
%    outpict = joinalpha(outpict,alpha);
% 
%  Webdocs: http://mimtdocs.rf.gd/manual/html/joinalpha.html
%  See also: splitalpha

if ~isempty(alpha)
	% expand tuple inputs as necessary
	opistuple = isvector(outpict) && any(numel(outpict) == [1 2 3 4 6]);
	alphistuple = isvector(alpha) && any(numel(alpha) == [1 3]);
	if opistuple && ~alphistuple
		outpict = repmat(reshape(outpict,1,1,[]),[imsize(alpha,2) 1]);
	elseif ~opistuple && alphistuple
		alpha = repmat(reshape(alpha,1,1,[]),[imsize(outpict,2) 1]);
	elseif opistuple && alphistuple
		outpict = reshape(outpict,1,1,[]);
		alpha = reshape(alpha,1,1,[]);
	end
	
	if ~all(imsize(outpict,2) == imsize(alpha,2))
		error('JOINALPHA: array geometries must match!')
	end
	
	[ncc nca] = chancount(outpict);
	[ncca,~] = chancount(alpha);
	if (ncc == 1) && (ncca == 3)
		alpha = mono(alpha,'y');
	elseif any(ncca == [2 4 6])
		error('JOINALPHA: expected ALPHA to be I/RGB, not IA/RGBA/RGBAAA')
	end

	
	if nca == 0
		% expand frames as needed
		nf = size(outpict,4);
		nfa = size(alpha,4);
		if nf~=nfa
			if nf>1 && nfa>1
				error('JOINALPHA: if both inputs are multiframe, their number of frames must match')
			elseif nfa==1 && nf>1
				alpha = repmat(alpha,[1 1 1 nf]);
			elseif nf==1 && nfa>1
				outpict = repmat(outpict,[1 1 1 nfa]);
			end
		end
	
		% just append new alpha
		alpha = imcast(alpha,class(outpict));
		outpict = cat(3,outpict,alpha);
	else
		% mix new alpha with existing alpha
		% bsxfun() should handle expansion where necessary
		[outpict oldalpha] = splitalpha(outpict);
		[oldalpha inclass] = imcast(oldalpha,'double');
		alpha = imcast(alpha,'double');
		alpha = bsxfun(@times,oldalpha,alpha);
		alpha = imcast(alpha,inclass);
		outpict = joinalpha(outpict,alpha);
	end
end
% if alpha is empty, do nothing


