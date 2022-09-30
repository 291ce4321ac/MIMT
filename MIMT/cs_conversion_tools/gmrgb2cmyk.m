function CMYK = gmrgb2cmyk(RGB)
%  CMYK = GMRGB2CMYK(RGB)
%  Convert an RGB image to CMYK.
%  Note that this is in no way intended for print preparation.
%  No profiles are used.  This is a direct replication of the 
%  method used by GMIC rgb2cmyk -- specifically for the purpose
%  of replicating GMIC code that depended on that method.
%  For SWOP CMYK conversion, use IPT applycform() instead.
%
%  RGB is an RGB image of any standard image class
%    Multiframe images are supported.
%
%  Output class is inherited from input
%
%  See also: gmcmyk2rgb, applycform, makecform


[RGB inclass] = imcast(RGB,'double');

CMY = imclamp(1-RGB);
K = min(CMY,[],3);

isblack = repmat(K>=1,[1 1 3]);
CMY = bsxfun(@rdivide,bsxfun(@minus,CMY,K),1-K);
CMY(isblack) = 0;

CMYK = imclamp(cat(3,CMY,K));
CMYK = imcast(CMYK,inclass);
