function out = ctflop(in)
%  OUT = CTFLOP(IN)
%    Simple function to permute between a Mx3 color table and 
%    a Mx1x3 image.  This allows tools which only support images
%    to conveniently handle color tables.  This can also be done
%    using permute(), but ctflop() provides a succinct and readable
%    way to express one of the most common permutations.
%
%    This is an involution; applying this function to a Mx1x3 
%    image will result in a Mx3 color table.  Only one tool is
%    needed to do both permutations.
%    
%  IN is typically a Mx3 color table or a Mx1x3 image of any class.
%  OUT is correspondingly either Mx1x3 or Mx3.
%
%  While those are the typical array sizes based on the expected use, 
%  ctflop() simply permutes dimensions 2 and 3.  The arrays don't 
%  actually need to have any particular size.
%
%  Though only dims 2 and 3 are affected, higher-dimensional arrays 
%  can be processed.  That should cover most image processing cases,
%  including multiframe image stacks.
%
%  Output class is inherited from input.
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/ctflop.html
%  See also: permute 

% yeah, that's all it does.
d = 1:ndims(in);
d(1:3) = [1 3 2];
out = permute(in,d);

end














