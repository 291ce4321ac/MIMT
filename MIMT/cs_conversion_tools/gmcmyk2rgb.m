function RGB = gmcmyk2rgb(CMYK)
%  RGB = GMCMYK2RGB(CMYK)
%  Convert a CMYK image to RGB.
%  Note that this is in no way intended for print preparation.
%  No profiles are used.  This is a direct replication of the 
%  method used by GMIC cmyk2rgb -- specifically for the purpose
%  of replicating GMIC code that depended on that method.
%  For SWOP CMYK conversion, use IPT applycform() instead.
%
%  CMYK is an CMYK image of any standard image class
%    Multiframe images are supported.
%
%  Output class is inherited from input
%
%  See also: gmrgb2cmyk, applycform, makecform


[CMYK inclass] = imcast(CMYK,'double');

[CMY K] = splitalpha(CMYK); % misusing tools is fun
CMY = bsxfun(@plus,bsxfun(@times,CMY,1-K),K);

RGB = imclamp(1-CMY);
RGB = imcast(RGB,inclass);

