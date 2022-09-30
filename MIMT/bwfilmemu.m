function outpict = bwfilmemu(inpict,film,varargin)
%  OUTPICT = BWFILMEMU(INPICT,FILMTYPE,{FILTER},{OPTIONS})
%  Roughly emulate the appearance of color scene as represented by one 
%  of various B&W film types. The result is a simple weighted sum of sRGB 
%  components.  Obviously, this shouldn't be taken as an accurate technical 
%  emulation of the physical film response or filter transmittance.  
%
%  This is based on the GIMP BW Film Emulation plugin by Serge Mankovski and 
%  Ari Pollak. This implementation was originally just intended to replicate 
%  the GIMP plugin for sake of demonstrating the adaptability of MIMT tools.  
%  It was pulled from the FXF_collection demo script due to its size. 
%
%  The 'auto-level' option in the original plugin is not replicated here, as the
%  plugin doesn't actually use it for anything.
%  
%  INPICT is an RGB image of any standard image class
%  FILMTYPE is one of the following:
%    'Agfa 200X' 
%    'Agfapan 25'
%    'Agfapan 100'
%    'Agfapan 400'
%    'Ilford Delta 100'
%    'Ilford Delta 400'
%    'Ilford Delta 400 Pro & 3200'
%    'Ilford FP4'
%    'Ilford HP5'
%    'Ilford Pan F'
%    'Ilford SFX'
%    'Ilford XP2 Super'
%    'Kodak Tmax 100'
%    'Kodak Tmax 400'
%    'Kodak Tri-X'
%    'Kodak HIE'
%    'Normal Contrast'
%    'High Contrast'
%    'Generic BW'
%    '50/50'
%  FILTER includes the following keys specifying the use of a color filter:
%    'none', 'yellow', 'orange', 'red', 'green', 'blue' (default 'none')
%  OPTIONS include the following keys:
%    'morecontrast' optionally applies a broad, weak unsharp mask filter
%    'lowergamma' optionally adjusts gamma slightly to darken the image
%    'saturate' optionally increases saturation prior to reduction.
%
%  Output class is inherited from input
%
%  See also: tonepreset, lcdemu

% i'm omitting the auto-level option, since it does nothing in the original code.  
% the flag is not actually used for anything, though there is some commented code that did.

% defaults
filter = 'none';
morecontrast = false; % true or false; default false
lowergamma = false; % true or false; default false
saturate = false; % true or false; default false

filmstr = {'agfa 200x','agfapan 25','agfapan 100','agfapan 400','ilford delta 100', ...
	'ilford delta 400','ilford delta 400 pro & 3200','ilford fp4','ilford hp5', ...
	'ilford pan f','ilford sfx','ilford xp2 super','kodak tmax 100','kodak tmax 400', ...
	'kodak tri-x','kodak hie','normal contrast','high contrast','generic bw','50/50'};

filterstr = {'none','yellow','orange','red','green','blue'};

if nargin<2
	error('BWFILMEMU: not enough arguments')
elseif nargin>2
	k = 1;
	while k <= numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case filterstr
				filter = thisarg;
				k = k+1;
			case 'saturate'
				saturate = true;
				k = k+1;
			case 'lowergamma'
				lowergamma = true;
				k = k+1;
			case 'morecontrast'
				morecontrast = true;
				k = k+1;
			otherwise
				error('BWFILMEMU: unknown key %s',thisarg)
		end
	end
end

film = lower(film);
if ~strismember(film,filmstr)
	error('BWFILMEMU: unknown film type %s',film)
end

% in the original script, all 9 channel weights are passed to the color mixer,
% but since the 'monochrome' flag is also set, only the first three are used.
% i don't know why the original author did that, and judging by the comments
% i don't think they were certain that the transformations were technically meaningful either.

% fwiw, the original 3x3 arrays can be formed from the given row vectors by circular shifting.
% obviously, an even-weighted reduction of the color image produced by such a transformation
% would have zero sensitivity to the original color balance.  i doubt that's what was intended.

switch film
	case 'agfa 200x'
		T = [0.18 0.41 0.41];
	case 'agfapan 25'
		T = [0.25 0.39 0.36];
	case 'agfapan 100'
		T = [0.21 0.40 0.39];
	case 'agfapan 400'
		T = [0.20 0.41 0.39];
	case 'ilford delta 100'
		T = [0.21 0.42 0.37];
	case 'ilford delta 400'
		T = [0.22 0.42 0.36];
	case 'ilford delta 400 pro & 3200'
		T = [0.31 0.36 0.33];
	case 'ilford fp4'
		T = [0.28 0.41 0.31];
	case 'ilford hp5'
		T = [0.23 0.37 0.40];
	case 'ilford pan f'
		T = [0.33 0.36 0.31];
	case 'ilford sfx'
		T = [0.36 0.31 0.33];
	case 'ilford xp2 super'
		T = [0.21 0.42 0.37];
	case 'kodak tmax 100'
		T = [0.24 0.37 0.39];
	case 'kodak tmax 400'
		T = [0.27 0.36 0.37];
	case 'kodak tri-x'
		T = [0.25 0.35 0.40];
	case 'kodak hie'
		T = [1.0 1.0 -1.0];
	case 'normal contrast'
		T = [0.43 0.33 0.30];
	case 'high contrast'
		T = [0.40 0.34 0.60];
	case 'generic bw'
		T = [0.24 0.68 0.08];
	case '50/50'
		T = [0.5 0.5 0.00];
end

% i fail to see how the application of a color filter can be 
% represented as a hue rotation instead of by spectral weighting
switch filter
	case 'none'
		twvec = [0 0 0];
	case 'yellow'
		twvec = [-5 0 33];
	case 'orange' 
		twvec = [-20 0 25];
	case 'red'
		twvec = [-41 0 25];
	case 'green'
		twvec = [90 0 33];
	case 'blue'
		twvec = [-145 0 25];
end

if size(inpict,3) ~= 3
	error('BWFILMEMU: expected INPICT to be an RGB image')
end

[outpict inclass] = imcast(inpict,'double');

if saturate
	outpict = mixchannels(outpict,[1.3 -0.15 -0.15; -0.15 1.3 -0.15; -0.15 -0.15 1.3]);
end

if lowergamma
	outpict = imadjustFB(outpict,[0 1],[0 1],1/0.9);
end

outpict = ghlstool(outpict,twvec);
outpict = imappmat(outpict,T);

if morecontrast
	outpict = unsharp(outpict,'sigma',30,'amt',0.25,'thresh',0.035);
end

outpict = imcast(outpict,inclass);









