function C = maxchroma(mode,varargin)
%   MAXCHROMA(MODEL,{CHANNELS})
%       returns the maximum chroma for color points to stay within sRGB gamut
%       can be used for chroma normalization (HuSL/HSY) or truncation prior to conversion
%
%   MODEL specifies the color model to use
%       'ypp' uses polar YPbPr
%       'luv' uses CIELCHuv
%       'lab' uses CIELCHab
%       'srlab' uses SRLAB2 
%       'oklab' uses OKLAB 
%       'yppp' uses the maximum biconic boundary in YPbPr (HSYp)
%       'luvp' uses the maximum biconic boundary in CIELCHuv (HuSLp)
%       'labp' uses the maximum biconic boundary in CIELCHab (HuSLp)
%       'oklabp' uses the maximum biconic boundary in OKLAB (HuSLp
%
%   The above methods are based on lookup tables for speed on large images.  This isn't 
%   perfect, but if a direct method is desired, specify one of the following:
%       'yppcalc'
%       'luvcalc'
%       'labcalc'
%       'srlabcalc'
%       'oklabcalc'
%   
%   The direct LUV and YPP methods use line intersection calculation for boundary finding similar to 
%   the reference implementation of HuSL.  
%
%   The direct LAB, SRLAB, and OKLAB methods use bisection and are much slower.  Due to the concavity of the 
%   gamut in these models, the boundary chroma is represented as the envelope of the actual chroma near 
%   the offending corners. 
%
%   CHANNELS parameters are specified as name-value pairs
%       for 'luvp', 'labp', and 'yppp', 'lightness' or 'luma' is required
%       for other modes, 'lightness' and 'hue' are required
%
%   For YPbPr modes, Y is in the range [0 1], H is in [0 360]
%   For other modes, L is in the range [0 100], H is in [0 360]
%
%   EXAMPLE:
%   Cnorm=maxchroma('luv','lightness',L,'hue',H);
%   Cnorm=maxchroma('ypp','luma',Y,'hue',H);
%
%   See also: RGB2HSY, HSY2RGB, RGB2HUSL, HUSL2RGB, RGB2LCH, LCH2RGB, CSVIEW.

%   The LUV method is a fairly direct adaptation of the C and Lua implementations 
%   by Alexei Boronine et al:  http://www.husl-colors.org/
%
%   The LAB method is a compromise.  Not all regions can be constrained to the extent of sRGB.  
%   Near the yellow corner, the concavity of the R==1 and G==1 faces causes them to occlude a radial 
%   cast from the neutral axis to the maximal boundary.  See file 'concavity_in_CIELAB.png'
%   In these narrow regions, OOG points can exist with normalized chroma <100%.  As the distance 
%   between these points and the face is small, any clipping error is minimal. SRLAB methods have similar
%   limitations due to undercuts on the blue and yellow corners.  LUV does not have this issue.

for k = 1:2:length(varargin);
    switch lower(varargin{k})
        case {'h','hue'}
            H = varargin{k+1};
        case {'l','lightness','y','luma'}
            L = varargin{k+1};
        otherwise
            error('BOUNDARYCHROMA: unknown option %s',varargin{k})
    end
end

if ~exist('mode','var')
    error('BOUNDARYCHROMA: no color model specified')
end
mode = mode(mode ~= ' ');

% locally normalize C for all L,H
switch lower(mode(mode ~= ' '))
	case 'oklabcalc'
		C = oklabboundcalc(L,H);
    case 'srlabcalc'
        C = srlabboundcalc(L,H);
    case 'luvcalc'
        C = luvboundcalc(L,H);
    case 'labcalc'
        C = labboundcalc(L,H);
	case 'oklab'
		C = oklabbound(L,H);
    case 'srlab'
        C = srlabbound(L,H);
    case 'luv'
        C = luvbound(L,H);
    case 'lab'
        C = labbound(L,H);
	case 'oklabp'
		C = oklabpbound(L);
    case 'labp'
        C = labpbound(L);
    case 'luvp'
        C = luvpbound(L);
    case {'ypp','hsy','ypbpr'}
        C = yppbound(L,H);
    case {'yppcalc','hsycalc','ypbprcalc'}
        C = yppboundcalc(L,H);
    case {'yppp','hsyp'}
        C = ypppbound(L);
end

end



function Cout = luvboundcalc(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % this function uses the method used by the other implementations
    % of HuSL in LUV
    Axyz = [3.240454162114103 -1.537138512797715 -0.49853140955601; ... 
        -0.96926603050518 1.876010845446694 0.041556017530349; ...
        0.055643430959114 -0.20402591351675 1.057225188223179];
    ka = 903.2962962962963;
    ep = 0.0088564516790356308;
    ref = [0 1];
    Cout = ones(size(L))*realmax;

    Hradians = H*pi/180;
    sinH = sin(Hradians);
    cosH = cos(Hradians);
    sub1 = (L+16).^3/1560896;
    mask = (sub1 > ep);
    sub2 = sub1;
    sub2(~mask) = L(~mask)/ka;
    
    for r = 1:3
        row = Axyz(r,:);
        a1 = row(1);
        a2 = row(2);
        a3 = row(3);
        top = (11120499*a1 + 11700000*a2 + 12739311*a3)*sub2;
        rbot = 9608480*a3 - 1921696*a2;
        lbot = 1441272*a3 - 4323816*a1;
        bot = (rbot.*sinH + lbot.*cosH).*sub2;
        
        for k = 1:2
            C = L.*(top - 11700000*ref(k))./(bot + 1921696*sinH*ref(k));
            mask = (C > 0 & C < Cout);
            Cout(mask) = C(mask);
        end
    end
    Cout = min(Cout,175.2);
	Cout(L == 0) = 0;
end

function Cout = labboundcalc(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % LUV approach won't be simple in LAB, since level curves and meridians are all nonlinear
    % furthermore, yellow corner is actually undercut and convergence at the edge is an issue
    broadroi = H > 85 & H < 114 & L > 85;
    pastcorner = (H-5) < L;
    ROI = (broadroi & ~pastcorner);
    
    % find boundary for entire area
    % then calculate logical combination of faces near ROI
    Cout = labsolver(L,H,1);    
    if any(ROI)
        Cbg = labsolver(L(ROI),H(ROI),2);
        Cr = labsolver(L(ROI),H(ROI),3);

        edge = (Cbg >= Cr);
        Croi = Cout(ROI);
        Croi(edge) = Cbg(edge);
        Cout(ROI) = Croi;
    end
end

function Cout = labsolver(L,H,mode)
    % adapted bisection solver for LAB
    
    % initial boundary generation for LAB
    Lc0 = [0 5 33 61 67 88 98 100];
    Cc0 = [30 60 135 115 95 119 97 15]+5;
    Lc = linspace(0,100);
    Cc = interp1(Lc0,Cc0,Lc);
    ind = L/100*(length(Lc)-1);
    Lp = round(ind)+1;
    
    s = size(H);
    C = Cc(Lp);
    C = reshape(C,s);
        
    % initial step sizes
    cstep = 10;
    stepsize = -ones(s)*cstep;
    
    limitdelta = 1E-7*prod(s);
    lastCsum = abs(sum(sum(C)));
    unmatched = true;
    out = true(s);
    first = true;
    while unmatched
        % CONVERSION MUST PASS OOG VALUES
        % bypass gamma correction for speed (results converge at the faces)
        rgb = lch2rgb(cat(3,L,C,H),'lab','nogc');

        % is point in-gamut?
        wasout = out;
        switch mode
            case 1
                out = (any(rgb < 0,3) | any(rgb > 1,3));
            case 2
                out = rgb(:,:,3) < 0 | rgb(:,:,2) > 1;
            case 3
                out = rgb(:,:,1) > 1 | C < cstep;
                if first
                    fout = out;
                    first = false;
                end
        end
        neg = C < 0;
        big = C > 140;
        out = out & ~neg;

        change = xor(wasout,out);
        stepsize(change) = -stepsize(change)/2;
        stepsize(big) = -abs(stepsize(big));
        stepsize(neg) = abs(stepsize(neg));

        C = C+stepsize;

        Csum = abs(sum(sum(C)));
        dC = abs(Csum-lastCsum);
        lastCsum = Csum;

        if dC < limitdelta 
            unmatched = false;
        end
    end
    Cout = max(C,0);
    
    if mode == 3
        Cout(fout) = 150;
    end
end

function Cout = srlabboundcalc(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % LUV approach won't be simple in SRLAB, since level curves and meridians are all nonlinear
    % furthermore, blue & yellow corners are undercut and convergence at the edge is an issue
    ROIb = H > 263 & H < 289 & L < 47 & L > 15;
    ROIy = H > 110.5 & H < 111.8 & L < 97.75 & L > 97.45;
    
    % find boundary for entire area
    % then calculate logical combination of faces near ROI
    Cout = srlabsolver(L,H,1);    
    if any(ROIb)
        Cbg = srlabsolver(L(ROIb),H(ROIb),2); % overhanging faces
        Cr = srlabsolver(L(ROIb),H(ROIb),3); % concave face
        
        % fix blue corner
        edge = (Cbg >= Cr);
        Croi = Cout(ROIb);
        Croi(edge) = Cbg(edge);
        Cout(ROIb) = Croi;
    end
    if any(ROIy)    
        Cbr = srlabsolver(L(ROIy),H(ROIy),4);
        Cg = srlabsolver(L(ROIy),H(ROIy),5);
        
        % fix yellow corner
        edge = (Cbr >= Cg);
        Croi = Cout(ROIy);
        Croi(edge) = Cbr(edge);
        Cout(ROIy) = Croi;
    end
end

function Cout = srlabsolver(L,H,mode)
    % adapted bisection solver for SRLAB
    
    % initial boundary generation for SRLAB
    Lc0 = [0 13 16 41 47 67 72 89 98 100];
	Cc0 = [0 0 39 97 89 103 81 101 88 0]+2;
    Lc = linspace(0,100);
    Cc = interp1(Lc0,Cc0,Lc);
    ind = L/100*(length(Lc)-1);
    Lp = round(ind)+1;
    
    s = size(H);
    C = Cc(Lp);
    C = reshape(C,s);
        
    % initial step sizes
    cstep = 10;
    stepsize = -ones(s)*cstep;
    
    limitdelta = 1E-7*prod(s);
    lastCsum = abs(sum(sum(C)));
    unmatched = true;
    out = true(s);
    first = true;
    while unmatched
        % CONVERSION MUST PASS OOG VALUES
        % bypass gamma correction for speed (results converge at the faces)
        rgb = lch2rgb(cat(3,L,C,H),'srlab','nogc');

        % is point in-gamut?
        wasout = out;
        switch mode
            case 1  % all nonspecial points
                out = (any(rgb < 0,3) | any(rgb > 1,3));
            case 2  % bg faces for blue corner in SRLAB
                out = rgb(:,:,2) < 0 | rgb(:,:,3) > 1;
            case 3  % r face for blue corner in SRLAB
                out = rgb(:,:,1) < 0 | C < cstep;
                if first
                    fout = out;
                    first = false;
                end
            case 4  % br faces for yellow corner in SRLAB
                out = rgb(:,:,3) < 0 | rgb(:,:,1) > 1;
            case 5  % g face for yellow corner in SRLAB
                out = rgb(:,:,2) > 1 | C < cstep;
                if first
                    fout = out;
                    first = false;
                end
        end
        neg = C < 0;
        big = C > 105;
        out = out & ~neg;

        change = xor(wasout,out);
        stepsize(change) = -stepsize(change)/2;
        stepsize(big) = -abs(stepsize(big));
        stepsize(neg) = abs(stepsize(neg));

        C = C+stepsize;

        Csum = abs(sum(sum(C)));
        dC = abs(Csum-lastCsum);
        lastCsum = Csum;

        if dC < limitdelta 
            unmatched = false;
        end
    end
    Cout = max(C,0);
    
    if any(mode == [3 5]) % need to check both cases
        Cout(fout) = 110;
    end
end

function Cout = oklabboundcalc(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % LUV approach won't be simple in OKLAB, since level curves and meridians are all nonlinear
    % furthermore, blue corner is actually undercut and convergence at the edge is an issue
    ROI = H > 264 & H < 264.23 & L < 47.3;
    
    % find boundary for entire area
    % then calculate logical combination of faces near ROI
    Cout = oklabsolver(L,H,1);    
    if any(ROI)
        Cbg = oklabsolver(L(ROI),H(ROI),2); % the overhanging faces
        Cr = oklabsolver(L(ROI),H(ROI),3); % the concave face

        edge = (Cbg >= Cr);
        Croi = Cout(ROI);
        Croi(edge) = Cbg(edge);
        Cout(ROI) = Croi;
    end
end

function Cout = oklabsolver(L,H,mode)
    % adapted bisection solver for OKLAB
    
    % initial boundary generation for OKLAB
	Lc0 = [0 45.31 70.11 75.38 86.51 96.67 100];
	Cc0 = [0 31.24 32.23 25.45 29.21 21.06 0]+2;
    Lc = linspace(0,100);
    Cc = interp1(Lc0,Cc0,Lc);
    ind = L/100*(length(Lc)-1);
    Lp = round(ind)+1;
    
    s = size(H);
    C = Cc(Lp);
    C = reshape(C,s);
        
    % initial step sizes
    cstep = 10;
    stepsize = -ones(s)*cstep;
    
    limitdelta = 1E-7*prod(s);
    lastCsum = abs(sum(sum(C)));
    unmatched = true;
    out = true(s);
    first = true;
    while unmatched
        % CONVERSION MUST PASS OOG VALUES
        % bypass gamma correction for speed (results converge at the faces)
        rgb = lch2rgb(cat(3,L,C,H),'oklab','nogc');

        % is point in-gamut?
        wasout = out;
        switch mode
            case 1
				% for general C outside ROI
                out = (any(rgb < 0,3) | any(rgb > 1,3));
            case 2
				% calculate Cbg
				% these are the adjacent faces
				% B>1 or G<0
                out = rgb(:,:,3) > 1 | rgb(:,:,2) < 0;
            case 3
				% calculate Cr
				% this is the concave face
				% R<0
                out = rgb(:,:,1) < 0 | C < cstep;
                if first
                    fout = out;
                    first = false;
                end
        end
        neg = C < 0;
        big = C > 35;
        out = out & ~neg;

        change = xor(wasout,out);
        stepsize(change) = -stepsize(change)/2;
        stepsize(big) = -abs(stepsize(big));
        stepsize(neg) = abs(stepsize(neg));

        C = C+stepsize;

        Csum = abs(sum(sum(C)));
        dC = abs(Csum-lastCsum);
        lastCsum = Csum;

        if dC < limitdelta 
            unmatched = false;
        end
    end
    Cout = max(C,0);
    
    if mode == 3
        Cout(fout) = 50; % this needs to be outside 'big'
    end
end

function Cout = oklabbound(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % this method just uses a giant LUT instead of calculating
    % it's not perfect, but it should be faster for large images
	% this LUT should match the assumptions made by the reference implementation
    % (sRGB, D65 white point)
	persistent CLIM
	if isempty(CLIM)
		LUT = load('OKLABLUT.mat');
		CLIM = LUT.CLIM;
	end
    
	% this table quantization is selected to improve LUT alignment with the yellow corner
    st = [542 593]; 
	l = linspace(0,100,st(1)); 
	h = linspace(0,360,st(2));
	Cout = interp2(l,h',CLIM,L,H,'linear');
end

function Cout = luvbound(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % this method just uses a giant LUT instead of calculating
    % it's not perfect, but it should be faster for large images
    % this LUT should match the assumptions made by COLORSPACE()
    % i.e. D65 wp, 2 deg observer
	persistent CLIM
	if isempty(CLIM)
		LUT = load('LUVLUT.mat');
		CLIM = LUT.CLIM;
	end
    
	st = 512;
	l = linspace(0,100,st); 
	h = linspace(0,360,st);
	Cout = interp2(l,h',CLIM,L,H,'linear');
end

function Cout = labbound(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % this method just uses a giant LUT instead of calculating
    % it's not perfect, but it should be faster for large images
    % and besides, i'm too lazy to do a proper algo for CIELAB.
    % this LUT should match the assumptions made by COLORSPACE()
    % i.e. D65 wp, 2 deg observer
	persistent CLIM
	if isempty(CLIM)
		LUT = load('LABLUT.mat');
		CLIM = LUT.CLIM;
	end
    
	% this table quantization is selected to improve LUT alignment with the yellow corner
    st = 512;
	l = linspace(0,100,st); 
	h = linspace(0,360,st);
	Cout = interp2(l,h',CLIM,L,H,'linear');
end

function Cout = srlabbound(L,H)
	L = min(max(L,0),100);
	H = mod(H,360);

    % this method just uses a giant LUT instead of calculating
    % it's not perfect, but it should be faster for large images
    % this LUT should match the assumptions made by the reference implementation
    % (sRGB, D65 white point)
	
	% use a regular gridded LUT to resolve most of the image
	persistent CLIM1 CLIM2 LL HH F
	if isempty(CLIM1)
		LUT = load('SRLABLUT.mat');
		CLIM1 = LUT.CLIM;
	end
    st = 512;
	l = linspace(0,100,st); 
	h = linspace(0,360,st);
	Cout = interp2(l,h',CLIM1,L,H,'linear');
	
	% scatteredInterpolant only exists in R2013a+
	if ifversion('<','R2013a') 
		% using a gridded LUT works poorly near corners due to the extreme slope
		% treat those areas different.  this two-pass method is still >10x faster than direct calc
		ROIy = H > 110.24 & H < 112.24 & L > 96.63 & L < 98.63;
		ROIb = H > 263 & H < 289 & L > 15 & L < 47;
		ROI = ROIy | ROIb;

		if any(ROI)
			if isempty(CLIM2)
				LUT = load('SRLABLUT2.mat');
				CLIM2 = LUT.CLIM;
				LL = LUT.LLIM;
				HH = LUT.HLIM;
				F = scatteredInterpolant(LL,HH,CLIM2,'linear');
			end

			Cout(ROI) = F(L(ROI),H(ROI));
		end
	end
end

function Cout = luvpbound(L)
	L = min(max(L,0),100);

    % this method just uses a giant LUT 
    CLIM = [0.0013529,0.15529,0.30922,0.46315,0.61709,0.77102,0.92496,1.0789,1.2328,1.3868,1.5407,1.6946, ...
        1.8486,2.0025,2.1564,2.3104,2.4643,2.6182,2.7722,2.9261,3.08,3.234,3.3879,3.5418,3.6958,3.8497, ...
        4.0036,4.1576,4.3115,4.4654,4.6194,4.7733,4.9272,5.0812,5.2351,5.389,5.543,5.6969,5.8508,6.0048, ...
        6.1587,6.3126,6.4666,6.6205,6.7744,6.9284,7.0823,7.2362,7.3902,7.5441,7.698,7.852,8.0059,8.1598, ...
        8.3138,8.4677,8.6216,8.7756,8.9295,9.0835,9.2374,9.3913,9.5453,9.6992,9.8531,10.007,10.161,10.315, ...
        10.469,10.623,10.777,10.931,11.085,11.239,11.392,11.546,11.7,11.854,12.008,12.162,12.316,12.47, ...
        12.624,12.778,12.932,13.086,13.24,13.394,13.548,13.701,13.855,14.009,14.163,14.317,14.471,14.625, ...
        14.779,14.933,15.087,15.241,15.395,15.549,15.703,15.857,16.01,16.164,16.318,16.472,16.626,16.78, ...
        16.934,17.088,17.242,17.396,17.55,17.704,17.858,18.012,18.166,18.319,18.473,18.627,18.781,18.935, ...
        19.089,19.243,19.397,19.551,19.705,19.859,20.013,20.167,20.321,20.475,20.628,20.782,20.936,21.09, ...
        21.244,21.398,21.552,21.706,21.86,22.014,22.168,22.322,22.476,22.63,22.784,22.937,23.091,23.245, ...
        23.399,23.553,23.707,23.861,24.015,24.169,24.323,24.477,24.631,24.785,24.939,25.093,25.247,25.4, ...
        25.554,25.708,25.862,26.016,26.17,26.324,26.478,26.632,26.786,26.94,27.094,27.248,27.402,27.556, ...
        27.709,27.863,28.017,28.171,28.325,28.479,28.633,28.787,28.941,29.095,29.249,29.403,29.557,29.711, ...
        29.865,30.018,30.172,30.326,30.48,30.634,30.788,30.942,31.096,31.25,31.404,31.558,31.712,31.866, ...
        32.02,32.174,32.327,32.481,32.635,32.789,32.943,33.097,33.251,33.405,33.559,33.713,33.867,34.021, ...
        34.175,34.329,34.483,34.636,34.79,34.944,35.098,35.252,35.406,35.56,35.714,35.868,36.022,36.176, ...
        36.33,36.484,36.638,36.792,36.945,37.099,37.253,37.407,37.561,37.715,37.869,38.023,38.177,38.331, ...
        38.485,38.639,38.793,38.947,39.101,39.254,39.408,39.562,39.716,39.87,40.024,40.178,40.332,40.486, ...
        40.64,40.794,40.948,41.102,41.256,41.41,41.563,41.717,41.871,42.025,42.179,42.333,42.487,42.641, ...
        42.795,42.949,43.103,43.257,43.411,43.565,43.719,43.873,44.026,44.18,44.334,44.488,44.642,44.796, ...
        44.95,45.104,45.258,45.412,45.566,45.72,45.874,46.028,46.182,46.335,46.489,46.643,46.797,46.951, ...
        47.105,47.259,47.413,47.567,47.721,47.875,48.029,48.183,48.337,48.491,48.644,48.798,48.952,49.106, ...
        49.26,49.414,49.568,49.722,49.876,50.03,50.184,50.338,50.492,50.646,50.8,50.953,51.107,51.261, ...
        51.415,51.569,51.723,51.877,52.031,52.185,52.339,52.493,52.647,52.801,52.955,53.109,53.262,53.416, ...
        53.57,53.724,53.878,54.032,54.186,54.34,54.494,54.648,54.802,54.956,55.11,55.264,55.418,55.571, ...
        55.725,55.879,56.033,56.187,56.341,56.495,56.649,56.803,56.957,57.111,57.265,57.419,57.573,57.727, ...
        57.88,58.034,58.188,58.342,58.496,58.65,58.804,58.958,59.112,59.266,59.42,59.574,59.728,59.882, ...
        59.583,58.99,58.4,57.811,57.224,56.639,56.055,55.474,54.895,54.318,53.744,53.171,52.6,52.03,51.463, ...
        50.897,50.334,49.773,49.213,48.656,48.1,47.546,46.994,46.444,45.896,45.349,44.805,44.263,43.722, ...
        43.183,42.646,42.111,41.577,41.045,40.516,39.988,39.462,38.937,38.415,37.894,37.375,36.857,36.341, ...
        35.827,35.315,34.805,34.296,33.789,33.284,32.78,32.278,31.778,31.279,30.782,30.286,29.792,29.3, ...
        28.81,28.321,27.834,27.348,26.864,26.381,25.9,25.421,24.943,24.466,23.992,23.518,23.047,22.576, ...
        22.108,21.641,21.175,20.711,20.248,19.787,19.327,18.868,18.411,17.956,17.502,17.049,16.598,16.148, ...
        15.7,15.252,14.807,14.363,13.92,13.478,13.038,12.599,12.161,11.725,11.29,10.857,10.424,9.9933,9.5637, ...
        9.1353,8.7083,8.2824,7.8579,7.4346,7.0125,6.5917,6.1721,5.7538,5.3366,4.9207,4.506,4.0926,3.6803, ...
        3.2692,2.8593,2.4505,2.043,1.6366,1.2313,0.82725,0.4243,0.022491];
    
	% this needs to match numel(CLIM)
	l = linspace(0,100,513); 
	Cout = interp1(l,CLIM,L);
end

function Cout = labpbound(L)
	L = min(max(L,0),100);

    % this method just uses a giant LUT 
    CLIM = [0.10454,0.26934,0.50152,0.75165,1.0018,1.2519,1.502,1.7522,2.0023,2.2524,2.5026,2.7527, ...
        3.0028,3.253,3.5031,3.7532,4.0034,4.2535,4.5036,4.7538,5.0039,5.254,5.5042,5.7543,6.0044, ...
        6.2546,6.5047,6.7548,7.0049,7.2551,7.5052,7.7549,8.0033,8.2487,8.4903,8.7274,8.96,9.188, ...
        9.4116,9.6306,9.8445,10.053,10.253,10.444,10.624,10.793,10.952,11.101,11.239,11.366,11.483, ...
        11.59,11.688,11.779,11.867,11.955,12.042,12.129,12.217,12.304,12.391,12.478,12.566,12.653, ...
        12.74,12.828,12.915,13.002,13.09,13.177,13.264,13.351,13.439,13.526,13.613,13.701,13.788, ...
        13.875,13.963,14.05,14.137,14.224,14.312,14.399,14.486,14.574,14.661,14.748,14.836,14.923, ...
        15.01,15.097,15.185,15.272,15.359,15.447,15.534,15.621,15.708,15.796,15.883,15.97,16.058, ...
        16.145,16.232,16.32,16.407,16.494,16.581,16.669,16.756,16.843,16.931,17.018,17.105,17.193, ...
        17.28,17.367,17.454,17.542,17.629,17.716,17.804,17.891,17.978,18.066,18.153,18.24,18.327, ...
        18.415,18.502,18.589,18.677,18.764,18.851,18.938,19.026,19.113,19.2,19.288,19.375,19.462, ...
        19.55,19.637,19.724,19.811,19.899,19.986,20.073,20.161,20.248,20.335,20.423,20.51,20.597, ...
        20.684,20.772,20.859,20.946,21.034,21.121,21.208,21.296,21.383,21.47,21.557,21.645,21.732, ...
        21.819,21.907,21.994,22.081,22.168,22.256,22.343,22.43,22.518,22.605,22.692,22.78,22.867, ...
        22.954,23.041,23.129,23.216,23.303,23.391,23.478,23.565,23.653,23.74,23.827,23.914,24.002, ...
        24.089,24.176,24.264,24.351,24.438,24.526,24.613,24.7,24.787,24.875,24.962,25.049,25.137, ...
        25.224,25.311,25.398,25.486,25.573,25.66,25.748,25.835,25.922,26.01,26.097,26.184,26.271, ...
        26.359,26.446,26.533,26.621,26.708,26.795,26.883,26.97,27.057,27.144,27.232,27.319,27.406, ...
        27.494,27.581,27.668,27.755,27.843,27.93,28.017,28.105,28.192,28.279,28.367,28.454,28.541, ...
        28.628,28.716,28.803,28.89,28.978,29.065,29.152,29.24,29.327,29.414,29.501,29.589,29.676, ...
        29.763,29.851,29.938,30.025,30.113,30.2,30.287,30.374,30.462,30.549,30.636,30.724,30.811, ...
        30.898,30.985,31.073,31.16,31.247,31.335,31.422,31.509,31.597,31.684,31.771,31.858,31.946, ...
        32.033,32.12,32.208,32.295,32.382,32.47,32.557,32.644,32.731,32.819,32.906,32.993,33.081, ...
        33.168,33.255,33.343,33.43,33.517,33.604,33.692,33.779,33.866,33.954,34.041,34.128,34.215, ...
        34.303,34.39,34.477,34.565,34.652,34.739,34.827,34.914,35.001,35.088,35.176,35.263,35.35, ...
        35.438,35.525,35.612,35.7,35.787,35.874,35.961,36.049,36.136,36.223,36.311,36.398,36.485, ...
        36.573,36.66,36.747,36.834,36.922,37.009,37.096,37.184,37.271,37.358,37.445,37.533,37.62, ...
        37.707,37.795,37.882,37.969,38.057,38.144,38.231,38.318,38.406,38.493,38.58,38.668,38.755, ...
        38.842,38.93,39.017,39.104,39.191,39.279,39.366,39.453,39.541,39.628,39.715,39.803,39.89, ...
        39.977,40.064,40.152,40.031,39.722,39.413,39.105,38.796,38.488,38.18,37.872,37.564,37.256, ...
        36.948,36.641,36.333,36.004,35.646,35.289,34.933,34.579,34.226,33.873,33.522,33.172,32.824, ...
        32.476,32.129,31.784,31.439,31.096,30.753,30.412,30.071,29.732,29.394,29.057,28.721,28.386, ...
        28.052,27.719,27.387,27.056,26.726,26.397,26.069,25.742,25.416,25.092,24.768,24.445,24.123, ...
        23.802,23.483,23.164,22.846,22.529,22.213,21.898,21.584,21.271,20.959,20.647,20.337,20.028, ...
        19.72,19.413,19.106,18.801,18.496,18.193,17.89,17.588,17.287,16.987,16.688,16.39,16.092,15.796, ...
        15.501,15.206,14.912,14.619,14.328,14.036,13.746,13.457,13.168,12.881,12.594,12.308,12.023, ...
        11.739,11.455,11.173,10.891,10.61,10.33,10.051,9.7724,9.4947,9.2179,8.9418,8.6666,8.3922, ...
        8.1186,7.8458,7.5738,7.3026,7.0322,6.7626,6.4937,6.2257,5.9584,5.6918,5.426,5.1609,4.8967, ...
        4.6331,4.3703,4.1083,3.847,3.5865,3.3267,3.0676,2.8093,2.5517,2.2948,2.0386,1.7832,1.5284, ...
        1.2744,1.0211,0.76847,0.51656,0.28232,0.11342];
    
	% this needs to match numel(CLIM)
	l = linspace(0,100,513); 
	Cout = interp1(l,CLIM,L);
end

function Cout = oklabpbound(L)
	L = min(max(L,0),100);

    % this method just uses a giant LUT 
    CLIM = [0.0001712 0.033359 0.066576 0.099763 0.13297 0.16617 0.19937 0.23256 0.26576 0.29898 0.33216 0.36537 ...
		0.39857 0.43176 0.46494 0.49819 0.53137 0.56457 0.59778 0.63097 0.66419 0.69737 0.73056 0.76378 0.79698 ...
		0.83018 0.86337 0.89659 0.92978 0.96299 0.99618 1.0294 1.0626 1.0958 1.129 1.1622 1.1954 1.2286 1.2618 ...
		1.295 1.3282 1.3614 1.3947 1.4278 1.461 1.4942 1.5274 1.5606 1.5938 1.627 1.6602 1.6934 1.7266 1.7598 ...
		1.793 1.8262 1.8594 1.8926 1.9258 1.959 1.9922 2.0254 2.0586 2.0918 2.125 2.1582 2.1914 2.2246 2.2578 ...
		2.291 2.3242 2.3574 2.3906 2.4238 2.457 2.4902 2.5234 2.5566 2.5898 2.623 2.6562 2.6894 2.7226 2.7558 ...
		2.789 2.8222 2.8554 2.8886 2.9218 2.955 2.9882 3.0214 3.0546 3.0878 3.121 3.1542 3.1874 3.2206 3.2538 ...
		3.287 3.3202 3.3534 3.3866 3.4198 3.453 3.4862 3.5194 3.5526 3.5858 3.6191 3.6522 3.6854 3.7186 3.7518 ...
		3.785 3.8182 3.8514 3.8846 3.9179 3.951 3.9842 4.0174 4.0506 4.0838 4.117 4.1502 4.1834 4.2167 4.2498 ...
		4.283 4.3163 4.3494 4.3827 4.4158 4.449 4.4822 4.5155 4.5487 4.5819 4.6151 4.6482 4.6815 4.7147 4.7478 ...
		4.7811 4.8143 4.8475 4.8807 4.9139 4.947 4.9803 5.0135 5.0466 5.0799 5.1131 5.1463 5.1795 5.2127 5.2458 ...
		5.2791 5.3123 5.3454 5.3787 5.412 5.4451 5.4783 5.5115 5.5447 5.5779 5.6111 5.6443 5.6775 5.7107 5.7439 ...
		5.7771 5.8103 5.8435 5.8767 5.9099 5.9431 5.9763 6.0095 6.0427 6.0759 6.1091 6.1423 6.1755 6.2087 6.2419 ...
		6.2751 6.3083 6.3415 6.3747 6.4079 6.4411 6.4743 6.5075 6.5407 6.5739 6.6071 6.6403 6.6735 6.7066 6.74 ...
		6.7731 6.8063 6.8395 6.8727 6.9059 6.9391 6.9723 7.0055 7.0387 7.0719 7.1051 7.1383 7.1715 7.2047 7.2379 ...
		7.271 7.3043 7.3375 7.3708 7.4039 7.4371 7.4703 7.5035 7.5367 7.5699 7.6031 7.6363 7.6695 7.7027 7.7359 ...
		7.7691 7.8023 7.8355 7.8687 7.9019 7.9352 7.9683 8.0015 8.0347 8.0679 8.1011 8.1343 8.1675 8.2007 8.2339 ...
		8.2671 8.3003 8.3335 8.3667 8.3999 8.4331 8.4663 8.4995 8.5327 8.5659 8.5991 8.6323 8.6655 8.6987 8.7319 ...
		8.7651 8.7983 8.8315 8.8647 8.8979 8.9312 8.9644 8.9975 9.0307 9.0639 9.0971 9.1304 9.1635 9.1968 9.2299 ...
		9.2632 9.2964 9.3295 9.3627 9.3959 9.4291 9.4623 9.4955 9.5288 9.562 9.5952 9.6283 9.6616 9.6947 9.728 ...
		9.7612 9.7944 9.8276 9.8608 9.894 9.9271 9.9603 9.9936 10.027 10.06 10.093 10.126 10.16 10.193 10.226 10.259 ...
		10.292 10.326 10.359 10.392 10.425 10.458 10.492 10.525 10.558 10.591 10.624 10.658 10.691 10.724 10.757 ...
		10.79 10.824 10.857 10.89 10.923 10.956 10.99 11.023 11.056 11.089 11.122 11.156 11.189 11.222 11.255 11.288 ...
		11.322 11.355 11.388 11.421 11.454 11.488 11.521 11.554 11.587 11.62 11.654 11.687 11.72 11.753 11.786 11.82 ...
		11.853 11.886 11.919 11.952 11.986 12.019 12.052 12.085 12.118 12.152 12.185 12.218 12.251 12.284 12.318 12.351 ...
		12.384 12.417 12.45 12.484 12.517 12.55 12.583 12.616 12.65 12.683 12.716 12.749 12.656 12.547 12.438 12.329 ...
		12.22 12.111 12.003 11.895 11.786 11.678 11.57 11.463 11.355 11.248 11.14 11.033 10.926 10.82 10.713 10.607 ...
		10.5 10.394 10.288 10.182 10.077 9.971 9.8656 9.7604 9.6554 9.5505 9.4458 9.3412 9.2367 9.1325 9.0283 8.9244 ...
		8.8206 8.7169 8.6134 8.5101 8.4069 8.3039 8.201 8.0983 7.9957 7.8933 7.7911 7.689 7.587 7.4852 7.3836 7.282 ...
		7.1808 7.0796 6.9786 6.8777 6.7769 6.6763 6.5759 6.4757 6.3756 6.2756 6.1758 6.0762 5.9766 5.8773 5.7781 5.679 ...
		5.5801 5.4814 5.3828 5.2843 5.186 5.0879 4.9899 4.892 4.7944 4.6968 4.5994 4.5021 4.405 4.3081 4.2113 4.1146 ...
		4.0181 3.9217 3.8255 3.7295 3.6335 3.5377 3.4421 3.3467 3.2513 3.1561 3.0611 2.9662 2.8714 2.7768 2.6824 2.588 ...
		2.4939 2.3998 2.3059 2.2122 2.1186 2.0251 1.9318 1.8386 1.7457 1.6527 1.56 1.4674 1.3749 1.2826 1.1904 1.0984 ...
		1.0065 0.91473 0.8231 0.73159 0.64028 0.54909 0.45808 0.3671 0.27631 0.18565 0.095186 0.0047775];
    
	% this needs to match numel(CLIM)
	l = linspace(0,100,513); 
	Cout = interp1(l,CLIM,L);
end

function Cout = yppboundcalc(Y,H)
	Y = min(max(Y,0),1);
	H = mod(H,360)*pi/180;
	
	% these angles and normals could be precalculated, but the cost is negligible
	% most of the time is spent in the masked intersection calculations
    A = gettfm('ypbpr');
    Axyz = circshift(A,-1);

    % color angles
    bl = mod(atan2(A(3,3),A(2,3)),2*pi);
    mg = mod(atan2(A(3,3)+A(3,1),A(2,3)+A(2,1)),2*pi);
    rd = mod(atan2(A(3,1),A(2,1)),2*pi);
    yl = mod(atan2(A(3,1)+A(3,2),A(2,1)+A(2,2)),2*pi);
    gr = mod(atan2(A(3,2),A(2,2)),2*pi);
    cy = mod(atan2(A(3,2)+A(3,3),A(2,2)+A(2,3)),2*pi);
    % black point is at [0 0 0]
    % white point is at [0 0 1]

    % magenta, yellow, cyan corner vectors
    vmg = Axyz(:,1)+Axyz(:,3)-[0 0 1]';
    vyl = Axyz(:,1)+Axyz(:,2)-[0 0 1]';
    vcy = Axyz(:,2)+Axyz(:,3)-[0 0 1]';

    % normals for lower, upper planes
    nr0 = cross(Axyz(:,2),Axyz(:,3));
    nb0 = cross(Axyz(:,1),Axyz(:,2));
    ng0 = cross(Axyz(:,3),Axyz(:,1));
    nr1 = cross(vmg,vyl);
    ng1 = cross(vyl,vcy);
    nb1 = cross(vcy,vmg);

    % find maximal boundaries for S(H,Y)
    a = cos(H);
    b = sin(H);
    kt = zeros(size(H)); kb = kt;
    % bottom planes G=0, B=0, R=0
    mask = H >= bl | H < rd;
    kb(mask) = -ng0(3)*Y(mask)./(ng0(1)*a(mask) + ng0(2)*b(mask));
    mask = H >= rd & H < gr;
    kb(mask) = -nb0(3)*Y(mask)./(nb0(1)*a(mask) + nb0(2)*b(mask));
    mask = H >= gr & H < bl;
    kb(mask) = -nr0(3)*Y(mask)./(nr0(1)*a(mask) + nr0(2)*b(mask));
    % top planes R=1, G=1, B=1
    mask = H >= mg & H < yl;
    kt(mask) = (nr1(3)-nr1(3)*Y(mask))./(nr1(1)*a(mask) + nr1(2)*b(mask));
    mask = H >= yl & H < cy;
    kt(mask) = (ng1(3)-ng1(3)*Y(mask))./(ng1(1)*a(mask) + ng1(2)*b(mask));
    mask = H >= cy | H < mg;
    kt(mask) = (nb1(3)-nb1(3)*Y(mask))./(nb1(1)*a(mask) + nb1(2)*b(mask));

    % find limiting radius from min parameter value
    k = min(kt,kb);
    Cout = sqrt((a.*k).^2 + (b.*k).^2);
end

function Cout = yppbound(Y,H)
	Y = min(max(Y,0),1);
	H = mod(H,360);
	
	CLIM = load('YPPLUT.mat');
	CLIM = CLIM.CLIM;
    
    st = 512;
	y = linspace(0,1,st); 
	h = linspace(0,360,st);
	[Y0 H0] = meshgrid(y,h);
	Cout = interp2(Y0,H0,CLIM,Y,H,'linear');
end

function Cout = ypppbound(Y)
	Y = min(max(Y,0),1);
	
    % calculate biconic boundary
    Ybreak = 0.50195313;
    Cbreak = 0.28211668;
    Cout = zeros(size(Y));

    mk = Y < Ybreak;
    Cout(mk) = Cbreak/Ybreak*Y(mk);
    Cout(~mk) = Cbreak-Cbreak/(1-Ybreak)*(Y(~mk)-Ybreak);
end




