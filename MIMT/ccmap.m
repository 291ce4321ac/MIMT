function cset = ccmap(varargin)
%  CMAP = CCMAP({MAPNAME},{STEPS})
%   Custom colormap/colortable generator originally for MIMT docs processing.
%   This has since turned into a collection of various useful maps.
%
%  MAPNAME is one of the following:
%    MIMT maps:
%    'pastel' is a soft yellow-magenta-teal CT used for imblend() contour maps (linear luma)
%    'pwrap' is a closed version of 'pastel' (asymmetric piecewise-linear luma)
%    'nrl' is an asymmetric cyan-blue-black CT used for imblend() NRL maps (PWL luma)
%    'tone' is a linear-luma sweep through black-purple-tan-white, like a pastel version of MPL 'magma'
%    'cat' is an interleaved hue sweep in HuSLpok with low-contrast alternating L (categorical)
%    'althi' is a hue sweep in HuSLpok with high-contrast alternating L (categorical)
%    'altlo' is a hue sweep in HuSLpok with low-contrast alternating L (categorical)
%    'hsyp' is a constant-luma hue sweep in HSYp (quasi-categorical)
% 
%    MATLAB compatibility maps:
%    'parula' is a clone of the R2017b version of 'parula', for use in prior versions
%    'parula14' is a clone of the R2014b-R2017a version of 'parula'
%    'turbo' is a clone of the turbo() map introduced in R2020b
%    'sky' is a clone of the sky() map introduced in R2023a
% 
%    MATLAB compatibility maps (categorical):
%    'oldgem' is the lines() map prior to R2014b (7 colors)
%    'gem' is the same as the R2014b lines() map (7 colors)
%    'gem12' same as 'gem', but with an extra 5 colors (12 colors)
%    'glow' (7 colors)
%    'glow12' (12 colors)
%    'sail' (5 colors)
%    'reef' (6 colors)
%    'meadow' (7 colors)
%    'dye' (7 colors)
%    'earth' (7 colors)
%    With the exception of 'oldgem', these were introduced in R2023b with the orderedcolors()
%    function, though the included maps reflect minor revisions present by R2024a.
%    As with lines() and other legacy categorical map generators, the map sequence
%    is simply repeated if STEPS is longer than the base map length.
%
%    Thermocamera maps:
%    'flir1' is a clone of the black-purple-yellow-white map used in some FLIR cameras
%    'flir2' is a clone of one of the rainbow maps used in some FLIR cameras
%    'dias1' is a clone of the rainbow map used by some DIAS cameras
%    'chauv1' is used by some Chauvin Arnoux Metrix cameras.  Similar to 'flir1'.
%
%  STEPS is the desired map length (default 64)
%    For the MATLAB categorical modes, the default map length is the base map length.
% 
% See also: makect, ctpath

mapnamestrings = {'pastel','nrl','hsyp','pwrap','tone','althi','altlo','cat', ...
					'parula','parula14','turbo','sky', ...
					'oldgem','gem','gem12','glow','glow12','sail','reef','meadow','dye','earth', ...
					'flir1','flir2','dias1','chauv1'};
mapname = 'pastel';
steps = 64;
usedefaultlength = true;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if ischar(thisarg)
			if strismember(thisarg,mapnamestrings)
				mapname = thisarg;
			else
				error('CCMAP: unknown map name ''%s''',thisarg)
			end
		elseif isnumeric(thisarg) && isscalar(thisarg)
			steps = thisarg;
			usedefaultlength = false;
		else
			error('CCMAP: expected either char or scalar numeric arguments.  what is this?')
		end
	end
end

switch mapname
	case 'oldgem'
		CT0 = [0 0 1; 0 0.5 0; 1 0 0; 0 0.75 0.75; 0.75 0 0.75; 0.75 0.75 0; 0.25 0.25 0.25];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'gem'
		CT0 = [0 0.447 0.741; 0.85 0.325 0.098; 0.929 0.694 0.125; 0.494 0.184 0.556; 0.466 0.674 0.188; 0.301 0.745 0.933; 0.635 0.078 0.184];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'gem12'
		CT0 = [0 0.447 0.741; 0.85 0.325 0.098; 0.929 0.694 0.125; 0.494 0.184 0.556; 0.466 0.674 0.188; 0.301 0.745 0.933; 0.635 0.078 0.184; 1 0.27 0.227; 0.396 0.509 0.992; 1 0.839 0.039; 0 0.639 0.639; 0.796 0.517 0.364];
		CT0([8 10],:) = CT0([10 8],:); % this changed in one of the late updates to 23b?
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'glow'
		CT0 = [0.149 0.549 0.866; 0.96 0.466 0.16; 1 0.909 0.392; 0.752 0.36 0.984; 0.286 0.858 0.25; 0.423 0.956 1; 0.949 0.403 0.772];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'glow12'
		CT0 = [0.149 0.549 0.866; 0.96 0.466 0.16; 1 0.909 0.392; 0.752 0.36 0.984; 0.286 0.858 0.25; 0.423 0.956 1; 0.949 0.403 0.772; 1 0.478 0.454; 0.49 0.662 1; 0.996 0.752 0.298; 0.121 0.811 0.745; 0.862 0.6 0.423];
		CT0([8 10],:) = CT0([10 8],:); % this changed in one of the late updates to 23b?
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'sail'
		CT0 = [0.062 0.258 0.501; 0.329 0.713 1; 1 0.27 0.227; 0.564 0.149 0.133; 0.066 0.443 0.745];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'reef'
		CT0 = [0.866 0.329 0; 0.329 0.713 1; 0.066 0.443 0.745; 0.996 0.564 0.262; 0.454 0.921 0.854; 0 0.639 0.639];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);	

	case 'meadow'
		CT0 = [0.007 0.345 0.054; 0.227 0.784 0.192; 1 0.839 0.039; 0.96 0.466 0.16; 0.752 0.298 0.043; 0.98 0.541 0.831; 0.49 0.662 1];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'dye'
		CT0 = [0.717 0.192 0.172; 0.231 0.666 0.196; 0.368 0.133 0.588; 0.066 0.443 0.745; 0.866 0.329 0; 0.007 0.47 0.501; 0.913 0.317 0.721];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
		
	case 'earth'
		CT0 = [0.062 0.258 0.501; 0.717 0.192 0.172; 0.611 0.466 0.125; 0.007 0.345 0.054; 0.862 0.6 0.423; 0.372 0.105 0.031; 1 0.819 0.619];
		if usedefaultlength, steps = size(CT0,1); end
		cset = CT0(mod(0:steps-1,size(CT0,1))+1,:);
				
	case 'chauv1'
		% very similar to flir1, but PWL in RGB
		% extracted map actually has a flat spot at the bottom
		% i'm assuming that's a defect in the routine that draws the colorbar
		% as extracted:
		%CT0 = [19 9 33; 19 9 41; 19 9 48; 19 9 60; 23 9 68; 25 9 71; 30 9 78; 34 9 82; 39 9 89; 44 9 95; 46 9 98; 53 9 107; 55 9 109; 60 9 116; 66 9 123; 69 9 128; 75 9 135; 77 9 138; 82 9 144; 87 9 151; 91 9 155; 96 9 162; 99 9 166; 104 9 171; 107 10 170; 109 10 169; 112 11 168; 114 12 167; 118 12 166; 121 13 165; 124 14 164; 127 14 163; 129 15 162; 132 15 161; 135 16 160; 137 17 160; 141 17 158; 142 18 158; 147 19 156; 150 19 155; 151 20 155; 155 20 154; 157 21 153; 160 22 152; 164 23 151; 165 23 150; 169 24 149; 171 24 148; 174 25 147; 176 27 145; 178 29 142; 180 32 139; 180 33 138; 182 37 134; 184 40 131; 185 42 128; 187 45 125; 188 46 123; 190 49 119; 192 53 116; 193 54 115; 195 57 111; 196 59 109; 198 62 106; 200 65 102; 201 67 100; 203 70 97; 204 71 95; 206 74 92; 208 77 88; 209 79 86; 211 82 83; 211 83 82; 214 87 77; 216 90 74; 216 91 72; 218 94 69; 219 96 67; 222 100 63; 222 101 62; 224 103 59; 226 107 55; 227 109 53; 229 112 49; 230 114 47; 232 116 44; 234 120 40; 235 121 39; 237 124 35; 238 126 34; 240 129 30; 242 132 27; 243 134 24; 245 137 21; 246 138 20; 248 141 16; 250 145 13; 251 146 11; 253 149 7; 253 150 6; 255 154 3; 255 157 3; 255 158 3; 255 160 3; 255 162 3; 255 165 3; 255 168 3; 255 169 3; 255 171 3; 255 173 3; 255 176 3; 255 178 3; 255 180 3; 255 183 3; 255 184 3; 255 186 3; 255 189 3; 255 191 3; 255 194 3; 255 195 3; 255 197 11; 255 199 19; 255 200 22; 255 202 32; 255 203 36; 255 204 43; 255 207 52; 255 208 57; 255 210 64; 255 210 68; 255 212 76; 255 214 84; 255 215 89; 255 217 96; 255 218 100; 255 221 111; 255 222 118; 255 223 121; 255 225 129; 255 226 134; 255 228 143; 255 230 151; 255 231 154; 255 233 161; 255 234 166; 255 236 175; 255 238 183; 255 239 188; 255 241 196; 255 242 199; 255 244 207; 255 245 214; 255 247 220; 255 249 229; 255 250 233; 255 251 240; 255 254 249]/255;
		%x0 = 1:157;
		
		% as transcribed:
		CT0 = [0.074004 0.035511 0.12833; 0.07392 0.035511 0.23386; 0.40764 0.035511 0.67066; 0.68575 0.096865 0.57595; 1 0.60382 0.011511; 1 0.76464 0.011293; 1 0.99254 0.97334];
		x0 = [1 6 38 80 165 195 256];
		xf = linspace(1,max(x0),steps);
		cset = interp1(x0,CT0,xf);
		
	case 'dias1'
		% similar to the FLIR maps, this was based on available example images, 
		% but the fitting was done in sRGB instead of LAB
		CT0 = [0.301 0 0.458; 0.282 0 0.467; 0.264 0 0.481; 0.246 0 0.499; 0.228 0 0.523; 0.21 0 0.549; 0.192 0 0.578; 0.174 0.000264 0.608; 
			0.142 0.0679 0.655; 0.112 0.136 0.72; 0.0867 0.196 0.782; 0.0646 0.232 0.815; 0.0443 0.268 0.844; 0.0253 0.303 0.872; 0.00711 0.339 0.898; 
			0 0.375 0.921; 0 0.41 0.942; 0 0.46 0.959; 0 0.527 0.966; 0 0.581 0.953; 0 0.629 0.925; 0 0.672 0.891; 0 0.712 0.846; 0 0.75 0.796; 
			0 0.787 0.738; 0 0.822 0.667; 0 0.837 0.577; 0 0.782 0.441; 0 0.738 0.206; 0 0.734 0.0101; 0 0.75 0; 0 0.767 0; 0.0148 0.784 0; 
			0.104 0.802 0; 0.209 0.82 0; 0.325 0.838 0; 0.44 0.856 0; 0.542 0.875 0; 0.628 0.894 0; 0.699 0.913 0; 0.757 0.934 0; 0.807 0.955 0; 
			0.85 0.978 0; 0.886 0.979 0; 0.918 0.901 0; 0.946 0.809 0; 0.97 0.707 0; 0.992 0.597 0; 1 0.482 0; 1 0.364 0; 1 0.284 0; 1 0.209 0; 
			1 0.135 0; 1 0.0601 0; 1 0 0.0309; 0.992 0 0.114; 0.977 0 0.189; 0.96 0.0841 0.289; 0.949 0.207 0.368; 0.94 0.29 0.421; 0.932 0.373 0.474; 
			0.925 0.456 0.527; 0.919 0.539 0.58; 0.914 0.622 0.633];
		x0 = 1:64;
		xf = linspace(1,64,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		
	case 'flir1'
		% using a handful of exported FLIR images, the colorbars were cropped and averaged off-axis
		% samples were interpolated onto a common basis, and then a spline manually fit to them in LAB
		CT0 = [0 0 0; 0.0193 0.0109 0.126; 0.0316 0.0185 0.211; 0.026 0.0219 0.292; 0.0393 0.0142 0.364; 0.0763 0.00685 0.423; 0.136 0.00135 0.464; 
			0.19 0 0.502; 0.239 0 0.536; 0.284 0.00163 0.567; 0.325 0.00612 0.594; 0.364 0.0107 0.617; 0.4 0.0134 0.634; 0.436 0.013 0.645; 
			0.474 0.00788 0.646; 0.513 0.00118 0.64; 0.55 0 0.631; 0.584 0 0.62; 0.616 0.00439 0.607; 0.645 0.0202 0.593; 0.673 0.0433 0.576; 
			0.7 0.0667 0.555; 0.727 0.0886 0.531; 0.752 0.11 0.505; 0.776 0.132 0.477; 0.799 0.155 0.448; 0.82 0.178 0.418; 0.84 0.203 0.387; 
			0.858 0.227 0.356; 0.875 0.253 0.325; 0.891 0.279 0.293; 0.905 0.305 0.262; 0.918 0.331 0.233; 0.93 0.358 0.202; 0.941 0.384 0.17; 
			0.951 0.411 0.138; 0.959 0.438 0.112; 0.965 0.465 0.091; 0.97 0.492 0.0752; 0.974 0.52 0.0637; 0.976 0.547 0.0536; 0.978 0.574 0.0437; 
			0.979 0.602 0.034; 0.979 0.628 0.0254; 0.978 0.655 0.0183; 0.978 0.681 0.0129; 0.976 0.707 0.00952; 0.975 0.732 0.00879; 0.973 0.757 0.0116; 
			0.972 0.782 0.0193; 0.971 0.806 0.0346; 0.971 0.829 0.0597; 0.972 0.851 0.0961; 0.974 0.872 0.141; 0.974 0.893 0.189; 0.974 0.913 0.242; 
			0.974 0.932 0.304; 0.975 0.949 0.377; 0.975 0.965 0.464; 0.97 0.98 0.566; 0.964 0.993 0.672; 0.958 1 0.78; 0.962 1 0.89; 1 1 1];
		x0 = 1:64;
		xf = linspace(1,64,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		
	case 'flir2'
		CT0 = [0.00886 0 0.132; 0.0217 0.00586 0.251; 0.0376 0.0428 0.309; 0.0557 0.077 0.355; 0.0518 0.114 0.399; 0.0401 0.149 0.442; 0.0285 0.182 0.485; 
			0.0191 0.213 0.529; 0.0119 0.241 0.574; 0.0135 0.268 0.62; 0.0415 0.292 0.664; 0.0737 0.315 0.705; 0.0898 0.338 0.742; 0.0888 0.362 0.774; 
			0.0754 0.386 0.8; 0.0505 0.41 0.817; 0.0339 0.434 0.82; 0.0334 0.458 0.807; 0.032 0.482 0.779; 0.0589 0.506 0.731; 0.114 0.53 0.659; 
			0.104 0.56 0.574; 0.0946 0.591 0.497; 0.183 0.619 0.398; 0.292 0.646 0.249; 0.357 0.673 0.161; 0.435 0.697 0.104; 0.517 0.719 0.0628; 
			0.589 0.741 0.0342; 0.65 0.761 0.0231; 0.704 0.78 0.0258; 0.751 0.794 0.0365; 0.793 0.802 0.0489; 0.828 0.804 0.0574; 0.856 0.799 0.0609; 
			0.88 0.788 0.0659; 0.901 0.773 0.0728; 0.918 0.752 0.0802; 0.931 0.724 0.0872; 0.94 0.689 0.0935; 0.943 0.647 0.1; 0.944 0.6 0.111; 
			0.945 0.549 0.13; 0.949 0.495 0.156; 0.945 0.427 0.174; 0.942 0.351 0.191; 0.942 0.271 0.209; 0.941 0.198 0.227; 0.937 0.142 0.245; 
			0.935 0.105 0.266; 0.933 0.099 0.288; 0.932 0.132 0.313; 0.932 0.184 0.341; 0.933 0.241 0.371; 0.936 0.302 0.402; 0.937 0.367 0.435; 
			0.939 0.435 0.469; 0.941 0.504 0.506; 0.945 0.575 0.547; 0.951 0.651 0.593; 0.959 0.73 0.649; 0.973 0.812 0.72; 0.993 0.898 0.817; 1 0.999 0.985];
		x0 = 1:64;
		xf = linspace(1,64,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		
	case 'tone'
		x0 = [0 0.3 0.5 0.7 1];
		CT0 = [240 1 0; 285 1 0.25; 330 0.8 0.5; 375 1 0.75; 420 1 1];
		xf = linspace(0,1,steps);
		cset = interp1(x0,CT0,xf,'linear');
		cset = ctflop(hsy2rgb(ctflop(cset),'pastel'));
		
	case 'sky'
		% the blue color is derived from the defaultaxescolororder 
		% i.e. lines(1) in newer versions
		% but defaultaxescolororder is different in older versions
		% so it's going to be a literal here for sake of compatibility
		CT0 = [0 0.4470 0.7410;
			0.9000 0.9447 0.9741];
		cset = makect(CT0(2,:),CT0(1,:),steps);
		
	case 'parula'
		x0 = [0 0.0549 0.09804 0.1333 0.2 0.2667 0.3333 0.4 0.4431 0.5059 0.6 0.6667 0.7333 0.7686 0.8 0.8235 0.8392 0.8667 0.9333 1];
		CT0 = [27.48 80.54 305.6; 34.53 93.25 304.2; 39.58 97.05 302.6; 43.28 95.58 300.7; 49.47 87.18 295.8; ...
			55.11 70.33 285.7; 60.26 51 269.2; 65.22 40.11 245.1; 67.58 37.37 222; 70.05 40.94 189.7; ...
			73.44 56.83 155; 75.11 65.86 131.5; 76.19 70.92 106.6; 76.88 71.98 95; 77.88 70.89 86.18; ...
			79.17 69.01 80.95; 80.56 70.57 80.12; 82.98 74.68 84.74; 88.78 83.44 97.38; 95.64 94.08 103.4];
		xf = linspace(0,1,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		cset = ctflop(lch2rgb(ctflop(cset),'lab'));
		
	case 'parula14'
		x0 = [0 0.06667 0.102 0.1333 0.2 0.2667 0.3333 0.4 0.4667 0.5333 0.5725 0.6 0.6392 0.702 0.8 0.8431 0.8667 0.9333 1];
		CT0 = [24.29 59.94 303; 35.05 73.32 297.7; 41.14 77.98 293.6; 45.34 73.65 289.3; 50.06 59.32 280.4; ...
			54.54 46.66 266.9; 60.35 38.9 246; 63.85 35.52 218.6; 66.41 38.14 190.5; 68.97 43.17 166; ...
			70.48 44.54 152.3; 71.45 44.44 142.7; 72.69 44.32 128.9; 74.54 46.94 107.6; 77.94 60.65 82.88; ...
			81 71.03 80.9; 82.88 75.07 84.49; 87.62 83.41 95.74; 95.57 94.69 103.4];
		xf = linspace(0,1,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		cset = ctflop(lch2rgb(ctflop(cset),'lab'));
		
	case 'turbo'
		x0 = [0 0.05263 0.1053 0.1579 0.2105 0.2632 0.3158 0.3684 0.4211 0.4737 0.5263 0.5789 0.6316 0.6842 0.7368 0.7895 0.8421 0.8947 0.9474 1];
		CT0 = [25.09 5.836 -5.595; 40.11 2.662 -13.97; 53.04 0.009816 -18.1; 62.28 -2.378 -18.62; 69.73 -5.948 -15.01; ...
			75.42 -10.28 -7.783; 80.8 -14.62 0.567; 84.52 -17.38 6.764; 87.5 -18.62 12.54; 89.87 -16.95 16.34; ...
			90.11 -13.49 17.33; 88.33 -7.709 16.85; 85.41 -1.445 15.85; 81.29 4.177 15.01; 74.53 9.892 14.11; ...
			67.46 14.21 13.13; 60.47 16.54 11.95; 53.92 16.71 10.73; 45.79 15.31 9.143; 36.68 12.87 7.167];
		xf = linspace(0,1,steps);
		cset = interp1(x0,CT0,xf,'pchip');
		cset = ctflop(lch2rgb(lab2lch(ctflop(cset)),'oklab'));
		
	case 'cat'
		lhw = 0.05;
		lcenter = 0.6;
		n = 4;
		H = linspace(0,360*(steps-1)/n,steps+1);
		H = H(1:end-1);
		H = mod(H,360);
		S = ones(size(H));
		L = zeros(size(H)) + (lcenter - lhw);
		L(1:2:end) = L(1:2:end) + 2*lhw;
		cset = permute(husl2rgb(cat(3,H,100*S,100*L),'oklab'),[2 3 1]);
		
	case {'althi','altlo'}
		if strcmpi(mapname,'althi')
			lhw = 0.09;
		else
			lhw = 0.04;
		end
		lcenter = 0.6;
		H = linspace(0,360,steps+1);
		S = ones(size(H));
		L = zeros(size(H)) + (lcenter - lhw);
		L(1:2:end) = L(1:2:end) + 2*lhw;
		cset = permute(husl2rgb(cat(3,H,100*S,100*L),'oklab'),[2 3 1]);
		cset = cset(1:end-1,:);
		
	case 'nrl'
		eh = [0 180];
		H = linspace(eh(1),eh(2),steps);
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		% this has a breakpoint (PWL)
		bpy = [0 0.7 1];
		esy = [0.2 0.9 0.9];
		Y = [linspace(esy(1),esy(2),ceil(steps*(bpy(2)-bpy(1)))) linspace(esy(2),esy(3),floor(steps*(bpy(3)-bpy(2))))];
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
	case 'pastel'
		eh = [0 270];
		H = linspace(eh(1),eh(2),steps);
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		ey = [0.8 0.2];
		Y = linspace(ey(1),ey(2),steps);
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
	case 'hsyp'
		H = linspace(0,360,steps+1);
		K = ones(size(H));

		cset = permute(hsy2rgb(cat(3,H,K*1.2,K*0.6),'native'),[2 3 1]);
		cset = cset(1:end-1,:);
				
	case 'pwrap'
		st = [2/3 1/3];
		eh = [0 270 360];
		H = linspace(eh(1),eh(2),ceil(steps*st(1)));
		H = [H linspace(eh(2),eh(3),floor(steps*st(2)))];
		es = [1.3 1.3];
		S = linspace(es(1),es(2),steps);
		ey = [0.8 0.2];
		Y = linspace(ey(1),ey(2),ceil(steps*st(1)));
		Y = [Y linspace(ey(2),ey(1),floor(steps*st(2)))];
		
		cset = 1-permute(hsy2rgb(cat(3,H,S,Y),'native'),[2 3 1]);
		
end


