function outpict = imcurves(inpict,varargin)
%  OUTPICT = IMCURVES(INPICT,{IN},{OUT},{INTERPMODE},{CHANNELS})
%    Adjust the intensity distribution of an image using an arbitrary curve.
%    This is generally more flexible than imlnc().
%
%  INPICT is an image of any standard image class.  Multichannel and multiframe 
%    images are supported.
%  IN and OUT are used to specify the shape of the transfer function curve.
%    These are equal-length vectors in the range [0 1].  If unspecified, a 
%       default null curve is used.
%  INTERPMODE optionally specifies the type of interpolation (default 'pchip')
%       Supported values are any method string supported by interp1() in your
%       currently installed version.
%  CHANNELS optionally specifies the color channels (default 'color')
%    'all' applies the specified curve to all image channels as presented
%    'color' applies the specified curve to only I/RGB channels, ignoring alpha
%    'hsl' applies the specified curve to L in HSL
%    'lchuv' applies the specified curve to L in LCHuv
%
%  Output class is inherited from input
%
%  Webdocs: http://mimtdocs.rf.gd/manual/html/imcurves.html
%  See also: imlnc, imbcg, imadjustFB, tonemap

xx = [0 1];
yy = [0 1];
intmodestr = {'linear','nearest','next','previous','spline','pchip','cubic','v5cubic','makima'};
interpmode = 'pchip';
modelstr = {'all','color','hsl','lchuv'};
model = 'color';

if numel(varargin)>0
	for k = 1:numel(varargin)
		switch k
			case 1
				xx = varargin{k};
			case 2
				yy = varargin{k};
			otherwise
				thisarg = varargin{k};
				switch lower(thisarg)
					case intmodestr
						interpmode = thisarg;
					case modelstr
						model = thisarg;
					otherwise
						error('IMCURVES: unknown key %s',thisarg)
				end
		end
	end
end

if numel(xx) ~= numel(yy)
	error('IMCURVES: IN and OUT vectors are not the same length')
end

% can't do transforms unless there's color content
[nc na] = chancount(inpict);
if nc~=3 && strismember(model,{'hsl','lchuv'})
	model = 'color';
end

[inpict inclass] = imcast(inpict,'double');
% split alpha if necessary
if na~=0 && ~strcmp(model,'all')
	[inpict alph] = splitalpha(inpict);
else 
	alph = [];
end

switch model
	case {'all','color'}
		outpict = interp1(xx,yy,inpict,interpmode);
	case 'hsl'
		outpict = zeros(size(inpict));
		for f = 1:size(inpict,4)
			thisframe = rgb2hsl(inpict(:,:,:,f));
			thisframe(:,:,3) = interp1(xx,yy,thisframe(:,:,3),interpmode);
			outpict(:,:,:,f) = hsl2rgb(thisframe);
		end
	case 'lchuv'
		outpict = zeros(size(inpict));
		for f = 1:size(inpict,4)
			thisframe = rgb2lch(inpict(:,:,:,f),'luv');
			thisframe(:,:,1) = interp1(xx,yy,thisframe(:,:,1)/100,interpmode)*100;
			outpict(:,:,:,f) = lch2rgb(thisframe,'luv','truncatelch');
		end
end

% recombine alpha if split
outpict = joinalpha(outpict,alph);
outpict = imcast(outpict,inclass);


