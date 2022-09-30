function out = ctflop(in)
%  OUT = CTFLOP(IN)
%    Simple function to permute between a Mx3 color table and 
%    a Mx1x3 image.  This allows tools which only support images
%    to conveniently handle color tables.  
%
%    This is an involution; applying this function to a Mx1x3 
%    image will result in a Mx3 color table.  Only one tool is
%    needed to do both permutations.
%    
%  IN is either a Mx3 color table or a Mx1x3 image of any class.
%  OUT is correspondingly either Mx1x3 or Mx3.
%
%  Output class is inherited from input.
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/ctflop.html
%  See also: permute 

% yeah, that's all it does.
out = permute(in,[1 3 2]);

end














