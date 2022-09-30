function outpict = imbcg(inpict,varargin)
%  OUTPICT = IMBCG(INPICT,{OPTIONS})
%    Simple tool to adjust image brightness, contrast, and gamma.
%    This is less flexible than imcurves(), imlnc(), or imadjust()/imadjustFB(), 
%    but may be convenient for users who are accustomed to interpreting the
%    process of image adjustment in terms of a reduced number of parameters.
%
%  INPICT is an I/IA/RGB/RGBA image of any standard image class. Multiframe images 
%    are supported. Any attached alpha content will be unmodified.
%  OPTIONS includes the following keys and key-value pairs:
%    'b' optionally specifies a brightness value (scalar, default 0)
%       The range for this parameter is [-1 1].
%    'c' optionally specifies a contrast value (scalar, default 0)
%       The range for this parameter is [-1 1].
%    'g' optionally specifies a gamma value (scalar, default 1)
%       The range for this parameter is [0 Inf).
%    'gimpmode' key optionally selects an alternative means of calculating
%       the transformation.  This reduces clipping, but causes the 'brightness' 
%       parameter to have a direct influence over both global and local contrast.
%       Compared to the default mode, this reduced parameter separation may be undesired.
%       Compared to GIMP tool behavior, a slider value of 127 (the max swing) is 
%       equivalent to a 'b' value of 0.5.
%
%  Output class is inherited from input.
%
%  EXAMPLE:
%    Increase the brightness/contrast of an image:
%      outpict = imbcg(inpict,'b',0.1,'c',0.05);
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/imbcg.html
%  See also: imcurves, imlnc, imadjustFB, stretchlimFB


% defaults
brightness = 0;
contrast = 0;
gamma = 1;
gimpcompatibility = false;

if numel(varargin)>0
	k = 1;
	while k <= numel(varargin)
		thisarg = lower(varargin{k});
		switch thisarg
			case {'brightness','b'}
				brightness = varargin{k+1};
				k = k+2;
			case {'contrast','k','c'}
				contrast = varargin{k+1};
				k = k+2;
			case {'gamma','g'}
				gamma = varargin{k+1};
				k = k+2;
			case {'gimpmode','gimp'}
				gimpcompatibility = true;
				k = k+1;
			otherwise
				error('IMBCG: unknown key %s',thisarg)
		end
	end
end

% clamp parameter ranges
brightness = imclamp(brightness,[-1 1]);
contrast = imclamp(contrast,[-1 1]);
gamma = max(gamma,0);


[inpict inclass] = imcast(inpict,'double');

% split alpha if necessary
[inpict alph] = splitalpha(inpict);

if gimpcompatibility
	outpict = adjbcg_gimp(inpict,brightness,contrast,gamma);
else
	outpict = adjbcg(inpict,brightness,contrast,gamma);
end

% recombine alpha if split
outpict = joinalpha(outpict,alph);

outpict = imcast(outpict,inclass);

end % END MAIN SCOPE

% a basic three-term brightness/contrast/gamma scheme
function B = adjbcg(A,brightness,contrast,gamma)	
	if contrast ~= 0
		th = tan((contrast + 1)*pi/4);
		B = (A - 0.5)*th + 0.5;
	else
		B = A;
	end
	
	if brightness ~= 0
		B = B + brightness;
	end
	
	if gamma ~= 1
		B = imclamp(B).^gamma;
	else
		B = imclamp(B);
	end
end

% GIMP's brightness/contrast implementation (plus gamma)
% based on GIMP 2.8.10 app/gegl/gimpoperationbrightnesscontrast.c
% the GIMP tool actually has half the swing
function B = adjbcg_gimp(A,brightness,contrast,gamma)
	if brightness < 0
		B = A*(1+brightness);
	elseif brightness > 0
		B = A + (1-A)*brightness;
	else
		B = A;
	end
	
	if contrast ~= 0
		th = tan((contrast+1)*pi/4);
		B = (B - 0.5)*th + 0.5;
	end
	
	if gamma ~= 1
		B = imclamp(B).^gamma;
	else
		B = imclamp(B);
	end
end


