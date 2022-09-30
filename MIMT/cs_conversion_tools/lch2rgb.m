function outpict = lch2rgb(inpict,varargin)
%   LCH2RGB(INPICT, {MODE}, {LIMIT}, {NOGC}, {WP})
%       Convert a LCH/YCH image to sRGB. LCH variant may be CIELUV, CIELAB, SRLAB2, or OKLAB
%       
%   INPICT is a single LCH image (of known type)
%   MODE is either 'luv' (default), 'lab', 'srlab', 'oklab', or 'YPbPr'
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
%   LCH inputs are expected to be of class 'double', with L in the range [0 100] and H in [0 360].  
%   YCH inputs for YPbPr mode have Y in the range [0 1] and H in the range [0 360]
%
%   This code formed as an interpretation of Pascal Getreuer's COLORSPACE() and other files.
%   Information on SRLAB2 can be found at http://www.magnetkern.de/srlab2.html or the paper
%   "Deficiencies of the CIE-L*a*b* color space and introduction of the SRLAB2 color model"
%   by Jan Behrens
%   Information on OKLAB can be found at https://bottosson.github.io/posts/oklab/
%
%   See also: RGB2HSY, HSY2RGB, RGB2HUSL, HUSL2RGB, RGB2LCH, MAXCHROMA, CSVIEW.

% doing chroma limiting while in LCH is the only practical way I can think of to handle OOG points
% when converting back to sRGB.  Using a wider gamut doesn't solve the fact that the projection 
% of a cube isn't rotationally symmetric.  LUV can be bound with simple line intersection calculations
% since the level curves of the RGB gamut are straight lines in LUV.
% The edges, level curves and meridians of the projection in LAB are not straight lines.  
% segregation of faces can't be done by angle alone either.  
% I'm left to offload the bisection task and use a LUT.


truncate = 'none';
mode = 'luv';
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
            error('LCH2RGB: unknown option %s',varargin{k})
    end
end

if strcmpi(mode,'ypbpr') && strcmpi(truncate,'truncatelchcalc')
	truncate = 'truncatelch';
end

H = inpict(:,:,3);
C = inpict(:,:,2);
L = inpict(:,:,1);

if strcmpi(truncate,'lch')
    Cnorm = maxchroma(lower(mode(mode ~= ' ')),'l',L,'h',H);
    C = min(max(C,0),Cnorm);
end
if strcmpi(truncate,'lchcalc')
    Cnorm = maxchroma([lower(mode(mode ~= ' ')) 'calc'],'l',L,'h',H);
    C = min(max(C,0),Cnorm);
end

% convert to LUV/LAB from LCH
Hrad = H*pi/180;
inpict(:,:,3) = sin(Hrad).*C; % V/B/Pr
inpict(:,:,2) = cos(Hrad).*C; % U/A/Pb

if strismember(mode,{'luv','lab','srlab'})
	switch thiswp
		case 'd65'
			WP = [0.950470 1 1.088830];
			% sRGB > XYZ (D65)
			Ainv = [3.240454162114103 -1.537138512797715 -0.49853140955601; ...   
				-0.96926603050518 1.876010845446694 0.041556017530349; ...
				0.055643430959114 -0.20402591351675 1.057225188223179];
		case 'd50'
			WP = [0.964220 1 0.825210];
			% sRGB > XYZ (D50)
			Ainv = [3.1338561 -1.6168667 -0.4906146; ...
				-0.9787684  1.9161415  0.0334540; ...
				0.0719453 -0.2289914  1.4052427];
	end
end

switch mode
	case 'luv'
		refd = dot([1 15 3],WP);
		refU = 4*WP(1)/refd;
		refV = 9*WP(2)/refd;

		U = inpict(:,:,2);
		V = inpict(:,:,3);

		fY = (L+16)/116;
		Y = invf(fY);

		mk = (L == 0);
		U = U./(13*L + 1E-6*mk) + refU;
		V = V./(13*L + 1E-6*mk) + refV;

		X = -(9*Y.*U)./((U-4).*V - U.*V);
		Z = (9*Y - (15*V.*Y) - (V.*X))./(3*V);
		
		outpict = xyz2rgb(X,Y,Z,Ainv);

		if ~nogc
			outpict = linear2rgb(outpict);
		end
		
	case 'lab'
		A = inpict(:,:,2);
		B = inpict(:,:,3);

		fY = (L+16)/116;
		fX = fY+A/500;
		fZ = fY-B/200;

		X = invf(fX);
		Y = invf(fY);
		Z = invf(fZ);

		X = X*WP(1);
		Z = Z*WP(3);
		
		outpict = xyz2rgb(X,Y,Z,Ainv);

		if ~nogc
			outpict = linear2rgb(outpict);
		end
		
	case 'srlab'
		Mcat02 = [0.7328, 0.4296, -0.1624;
				-0.7036, 1.6975, 0.0061; 
				0.0030, 0.0136, 0.9834];

		Mhpe = [0.38971 0.68898 -0.07868;
				-0.22981 1.18340 0.04641; 
				0 0 1];

		% equivalent to first coefficient matrix in ref implementation's SRLAB>RGB function    
		Msr2p = Mhpe/[0 100 0; 500/1.16 -500/1.16 0; 0 200/1.16 -200/1.16];

		% equivalent to second coefficient matrix in ref implementation's SRLAB>RGB function 
		% (after extracting XYZ conversion matrix)
		Msrp = inv(Mhpe*(Mcat02\diag(Mcat02*(1./WP'))*Mcat02));
		
		outpict = imappmat(inpict,Msr2p);
		outpict = invf(outpict);
		outpict = imappmat(outpict,Msrp);
		
		outpict = imappmat(outpict,Ainv);

		if ~nogc
			outpict = linear2rgb(outpict);
		end
				
	case 'oklab'
		Aok = [1 0.3963377774 0.2158037573;
			1 -0.1055613458 -0.0638541728;
			1 -0.0894841775 -1.2914855480];
		
		Alms = [4.0767416621 -3.3077115913 0.2309699292;
			-1.2684380046 2.6097574011 -0.3413193965;
			-0.0041960863 -0.7034186147 1.7076147010];
		
		outpict = imappmat(inpict,Aok/100);
		outpict = outpict.^3;
		outpict = imappmat(outpict,Alms);

		if ~nogc
			outpict = linear2rgb(outpict);
		end
		
	case 'ypbpr'
		Ai = gettfm('ypbpr_inv','601');
		outpict = imappmat(inpict,Ai);
end

% truncate rgb even if truncating lch
% this cleans up oog points in LAB/SRLAB undercuts
if ~strcmpi(truncate,'none')
    outpict = min(max(outpict,0),1);
end

end


function rgb = xyz2rgb(X,Y,Z,Ainv)
	% CIEXYZ to RGB
	xyz = cat(3,X,Y,Z);
	rgb = imappmat(xyz,Ainv);
end

function Y = invf(fY)
	ep = 216/24389;
	kp = 24389/27;
	Y = fY.^3;
	mk = (Y < ep);
	Y = (116*fY-16)/kp.*mk + Y.*(1-mk);
end


