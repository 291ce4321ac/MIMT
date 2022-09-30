function outpict = rgb2lch(rgb,varargin)
%   RGB2LCH(INPICT, {MODE}, {LIMIT}, {NOGC}, {WP})
%       Convert an sRGB image to the cylindrical mappings of CIELUV, CIELAB, SRLAB2, OKLAB, or YPbPr
%       
%   INPICT is a single RGB image of any standard image class
%   MODE is either 'luv' (default), 'lab', 'srlab', 'oklab', or 'ypbpr'
%   LIMIT options include:
%       'notruncate' performs no data truncation (default)
%       'truncatergb' limits color points to RGB data ranges when in RGB
%       'truncatelch' limits color points to RGB data ranges when in LCH 
%       'truncatelchcalc' is the same as 'truncatelch', but uses direct calculations instead of a LUT
%           (see maxchroma() documentation for details)
%   NOGC option can be used to disable gamma correction of the output
%       this is primarily intended to be used to speed up the calculations involved
%       in checking whether points are in-gamut.  (about 30% faster)
%   WP optionally allows the selection of the white point
%       'D65' (default) 
%       'D50' uses an adapted (Bradford) sRGB-XYZ matrix
%       D50 method is not compatible with 'truncatelch' or 'oklab' options
%
%   NOGC and WP options do not apply in YPbPr mode
%
%   LCH output is of class 'double', with L in the range [0 100] and H in the range of [0 360]
%   YCH output from YPbPr mode has Y in the range [0 1] and H in the range [0 360]
%
%   This code formed as an interpretation of Pascal Getreuer's COLORSPACE() and other files.
%   Information on SRLAB2 can be found at http://www.magnetkern.de/srlab2.html or the paper
%   "Deficiencies of the CIE-L*a*b* color space and introduction of the SRLAB2 color model"
%   by Jan Behrens
%   Information on OKLAB can be found at https://bottosson.github.io/posts/oklab/
%
%   See also: RGB2HSY, HSY2RGB, RGB2HUSL, HUSL2RGB, LCH2RGB, MAXCHROMA, CSVIEW.

% fastest to slowest: luv>oklab>lab>srlab

mode = 'luv';
truncate = 'none';
nogc = false;
thiswp = 'd65';

for k = 1:length(varargin)
    switch lower(varargin{k})
        case 'notruncate'
            truncate = 'none';
        case 'truncatergb'
            truncate = 'rgb';
        case 'truncatelch'
            truncate = 'lch'; 
        case 'truncatelchcalc'
            truncate = 'lchcalc';
        case {'lab','luv','srlab','ypbpr','oklab'}
            mode = varargin{k};
        case 'nogc'
            nogc = true;
        case 'd65'
            thiswp = 'd65';
        case 'd50'
            thiswp = 'd50';    
        otherwise
            error('RGB2LCH: unknown option %s',varargin{k})
    end
end

if strcmpi(mode,'ypbpr') && strcmpi(truncate,'lchcalc')
	truncate = 'lch';
end

rgb = imcast(rgb,'double');

if strcmpi(truncate,'rgb')
	rgb = min(max(rgb,0),1);
end

if strismember(mode,{'luv','lab','srlab'})
	switch thiswp
		case 'd65'
			% sRGB > XYZ (D65)
			A = [0.412456439089691 0.357576077643907 0.180437483266397; ...
				0.212672851405621 0.715152155287816 0.072174993306558; ...
				0.019333895582328 0.119192025881300 0.950304078536368];
			WP = [0.950470 1 1.088830];
		case 'd50'
			% sRGB > XYZ (D50)
			A = [0.4360747  0.3850649  0.1430804; ...
				0.2225045  0.7168786  0.0606169; ...
				0.0139322  0.0971045  0.7141733];
			WP = [0.964220 1 0.825210];
	end
end

switch mode
	case 'luv'
		if ~nogc
			rgb = rgb2linear(rgb);
		end
		
		[X Y Z] = rgb2xyz(rgb,A);

		% CIEXYZ to CIELUV
		refd = dot([1 15 3],WP);
		refU = 4*WP(1)/refd;
		refV = 9*WP(2)/refd;

		D = X + 15*Y + 3*Z;
		mk = (D == 0);
		U = 4*X./(D+mk);
		V = 9*Y./(D+mk);

		L = 116*f(Y)-16;
		U = 13*L.*(U-refU);
		V = 13*L.*(V-refV);

		outpict = cat(3,L,U,V);

	case 'lab'
		if ~nogc
			rgb = rgb2linear(rgb);
		end

		[X Y Z] = rgb2xyz(rgb,A);

		% CIEXYZ to CIELAB    
		X = X/WP(1);
		Z = Z/WP(3);

		fX = f(X);
		fY = f(Y);
		fZ = f(Z);

		L = 116*fY-16;
		A = 500*(fX-fY);
		B = 200*(fY-fZ);

		outpict = cat(3,L,A,B);
		
	case 'srlab'
		if ~nogc
			rgb = rgb2linear(rgb);
		end

		xyz = imappmat(rgb,A);

		% CIEXYZ to SRLAB2
		Mcat02 = [0.7328, 0.4296, -0.1624;
				-0.7036, 1.6975, 0.0061; 
				0.0030, 0.0136, 0.9834];

		Mhpe = [0.38971 0.68898 -0.07868;
				-0.22981 1.18340 0.04641; 
				0 0 1];

		% equivalent to first coefficient matrix in ref implementation's RGB>SRLAB function 
		% (after extracting XYZ conversion matrix)
		Msr = Mhpe*(Mcat02\diag(Mcat02*(1./WP'))*Mcat02);

		% equivalent to second coefficient matrix in ref implementation's RGB>SRLAB function
		Msr2 = [0 100 0; 500/1.16 -500/1.16 0; 0 200/1.16 -200/1.16]/Mhpe;

		% XYZ to X'Y'Z'
		xyzp = imappmat(xyz,Msr);
		xyzp = f(xyzp);
		outpict = imappmat(xyzp,Msr2);
		
	case 'oklab'
		if ~nogc
			rgb = rgb2linear(rgb);
		end
		
		% combined rgb>xyz>lms for d65 WP
		Alms = [0.4122214708 0.5363325363 0.0514459929;
			0.2119034982 0.6806995451 0.1073969566;
			0.0883024619 0.2817188376 0.6299787005];

		Aok = [0.2104542553 0.7936177850 -0.0040720468;
			1.9779984951 -2.4285922050 0.4505937099;
			0.0259040371 0.7827717662 -0.8086757660];

		outpict = imappmat(rgb,Alms);
		outpict = real(outpict.^(1/3));
		outpict = imappmat(outpict,Aok*100);
		
	case 'ypbpr'
		% this is actually Y, but it has to be used in the same places as L
		A = gettfm('ypbpr','601');
		outpict = imappmat(rgb,A);
end

% convert to polar LCHuv/LCHab
Hrad = mod(atan2(outpict(:,:,3),outpict(:,:,2)),2*pi);
H = Hrad*180/pi;
C = sqrt(outpict(:,:,2).^2 + outpict(:,:,3).^2);

if strcmpi(truncate,'lch')
	Cnorm = maxchroma(lower(mode(mode ~= ' ')),'l',L,'h',H);
    C = min(max(C,0),Cnorm);
end
if strcmpi(truncate,'lchcalc')
	Cnorm = maxchroma([lower(mode(mode ~= ' ')) 'calc'],'l',L,'h',H);
    C = min(max(C,0),Cnorm);
end

outpict(:,:,2) = C;
outpict(:,:,3) = H;

end

function [X Y Z] = rgb2xyz(rgb,A)
	% RGB to CIEXYZ
	xyz = imappmat(rgb,A);
	X = xyz(:,:,1);
	Y = xyz(:,:,2);
	Z = xyz(:,:,3);
end

function fY = f(Y)
    ep = 216/24389;
    kp = 24389/27;
    mk = (Y < ep);
	fY = ((kp*Y+16)/116).*mk + real(Y.^(1/3)).*(1-mk);
end



