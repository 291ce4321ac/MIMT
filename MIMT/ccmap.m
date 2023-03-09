function cset = ccmap(varargin)
%  CMAP = CCMAP({MAPNAME},{STEPS})
%   Custom colormap generator originally for MIMT docs processing
%
%  MAPNAME is one of the following:
%    'pastel' is a soft yellow-magenta-teal CT used for imblend() contour maps
%    'nrl' is an asymmetric cyan-blue-black CT used for imblend() NRL maps
%    'tone' is a linear-luma sweep through black-purple-tan-white, like a pastel version of MPL 'magma'
%    'hsyp' is a circular hue sweep in HSYp, used to make short 'ColorOrder' CTs (constant luma)
%    'pwrap' is a closed version of 'pastel'
%    'parula' is a clone of the R2017b version of 'parula', for use in prior versions
%    'parula14' is a clone of the R2014b-R2017a version of 'parula'
%    'turbo' is a clone of the turbo() map introduced in R2020b
%    'flir1' is a clone of the black-purple-yellow-white map used in some FLIR cameras
%    'flir2' is a clone of one of the rainbow maps used in some FLIR cameras
% 
% See also: makect, ctpath

% imshow(repmat(ctflop(ccmap('pastel',64)),[1 64 1]))

mapnamestrings = {'pastel','nrl','hsyp','pwrap','tone','parula','parula14','turbo','flir1','flir2'};
mapname = 'pastel';
steps = 64;

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
		else
			error('CCMAP: expected either char or scalar numeric arguments.  what is this?')
		end
	end
end

switch mapname
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


