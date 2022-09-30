function ct = makect(colorA,colorB,varargin)
%  COLORTABLE = MAKECT(COLORA,COLORB,{NUMCOLORS},{IDX})
%   Create a simple linear color table from two RGB tuples
%
%  COLORA, COLORB are 3-element vectors in any orientation
%     Values are expected to be scaled according to the numeric class.
%  NUMCOLORS specifies the length of the base color table (default 256)
%     Depending on the value of IDX, this may not be the length of
%     the output table.
%  IDX optionally specifies the index within the color table
%     This parameter allows the user to select a specific index or 
%     range of indices from within a color table of a given size.  
%     Non-integer indices are supported.  Indices specified outside 
%     the range 1:NUMCOLORS will result in extrapolation. By default, 
%     the entire color table is returned.  
%     
%  Output is an array of size Mx3, where M is determined by NUMCOLORS
%  and IDX.  Output class is inherited from COLORA. 
% 
%  EXAMPLES:
%   Generate 16-color color table:
%    ct = makect([1 0 0],[0 0 1],16);
%   Instead of returning the entire 16-row table, just get rows 3-5:
%    ct = makect([1 0 0],[0 0 1],16,3:5);
%
% See also: ccmap, ctpath


numcolors = 256;

if numel(varargin) >= 1
	numcolors = varargin{1};
end
if numel(varargin) >= 2
	n = varargin{2};
else
	n = 1:numcolors;
end


[colorA inclass] = imcast(reshape(colorA,1,[]),'double');
colorB = imcast(reshape(colorB,1,[]),'double');
ct = interp1([1/numcolors 1],[colorA; colorB],n/numcolors,'linear','extrap');
ct = imcast(ct,inclass);

end


