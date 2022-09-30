function outpict = tonepreset(inpict,tone,amount,presetenf)
%  OUTPICT = TONEPRESET(INPICT,TONE,{AMOUNT},{RANGETYPE})
%  Apply a selected tone adjustment preset to an image.
%
%  This is based on Iain Fergusson's GMIC tools.
%  https://github.com/dtschump/gmic-community/blob/master/include/iain_fergusson.gmic
%
%  INPICT is an RGB of any standard image class.  
%  TONE is one of the following:
%    'whiter whites'
%    'warm vintage'
%    'magenta-yellow'
%    'velvetia'
%    '70s magazine'
%    'faded print'
%    'expired 69'
%    'modern film'
%  AMOUNT optionally adjusts the influence of the effect. (scalar, default 1)
%  RANGETYPE optionally specifies how the output is handled (default 'clamp')
%    'clamp' truncates values to standard data range
%    'normalize' scales values to standard data range
%
%  Output class is inherited from input
%
%  See also: tonergb, tonecmyk, colorbalance, imtweak, imcurves, imlnc

% I spent _days_ trying to troubleshoot why these presets wouldn't match the original gimp-gmic tool
% It all boils down to a bug wherein to_colormode was being misused to expand a 1-ch S image
% to subsequently multiply it with a bipolar 4-ch CMYK image.  This results in K not being multiplied
% by S, as is implied by the function arguments.  Of course, that implication alone is all one has
% since GMIC appears to be a language tailored for people who loathe the idea that code should be
% commented or generally readable.

% While I implemented a workaround for that bug (or rather, a conditional re-implementation of it), 
% there are other only slightly-dissimilar cases where the multiplication will result in inexplicable 
% data truncation depending on the span of one of the arguments.  I am only somewhat certain that that 
% bug (or bug-shaped feature) doesn't also influence the accuracy of this specific re-implementation.  
% All i have discerned is that i cannot get consistent behavior between GMIC code run from GIMP 
% and the _same code_ run in GMIC directly. 

% I am absolutely and permanently done with GMIC, its unreadable opaqueness, and its maddeningly trivial 
% "documentation". Oh yeah, and its vast, ungreppable library of obfuscated letter-salad .gmic code.
% If I ever come back to GMIC, it'll be because i want a fresh reason to blow my brains out.

if nargin == 2
	amount = 1;
	presetenf = 'clamp';
elseif nargin == 3
	presetenf = 'clamp';
elseif nargin >= 3
	if ~strismember(lower(presetenf),{'clamp','normalize','norm'})
		error('TONEPRESET: unknown enforcement option %s',presetenf)
	end
else
	error('TONEPRESET: too few arguments')
end

[inpict inclass] = imcast(inpict,'double');

switch lower(tone(all(tone~='''- '.',1)))
	case 'whiterwhites'
		% whiter whites
		Tr = [00,10,00; 00,00,00; 00,00,00]; 
		Tg = [00,00,00; 00,10,00; 00,00,00];
		Tb = [00,20,00; 00,20,00; 00,00,00]; 
		Tsat = [255,0,0,0,0];
		enforcement = 'preserve';
		processrgb();
		
	case 'warmvintage'
		% warm vintage
		Tc = [00,00,00; 00,00,00; -8,-20,00; 00,00,-49];
		Tm = [00,00,00; 00,00,00; 00,-25,00; 00,17,0];
		Ty = [00,00,00; 00,00,00; 35,-25,17; 8,26,31];
		Tk = [00,00,00; 00,17,00; -9,-31,29; 00,00,-9];
		Tsat = [188,255,181,133,72]; % effect strength versus S level [0 255]
		enforcement = 'clampcmyk'; % 'preserve','clamp cmyk/rgb','normalize cmyk/rgb'
		processcmyk();
				
	case 'magentayellow'
		% magenta-yellow
		Tc = [00,-38,00; 00,00,00; 00,00,00; 00,00,00];
		Tm = [00,00,00; 00,00,00; 00,00,00; -164,88,255];
		Ty = [00,00,00; 00,00,00; 00,00,00; 65,33,-15];
		Tk = [00,00,00; 00,00,00; 00,00,00; 00,00,-25];
		Tsat = [128,92,62,45,38]; % effect strength versus S level [0 255]
		enforcement = 'clampcmyk'; % 'preserve','clamp cmyk/rgb','normalize cmyk/rgb'
		processcmyk();
		
	case 'velvetia'
		%velvetia
		Tc = [-25,50,00; 25,00,00; 25,00,00; 00,00,00];
		Tm = [25,25,00; -50,00,00; 25,00,00; 00,00,00];
		Ty = [25,00,00; 25,00,00; -50,00,00; 00,00,00];
		Tk = [00,00,00; 00,00,00; 00,00,00; 00,00,00];
		Tsat = [36,178,255,169,94];
		enforcement = 'clamprgb';
		processcmyk();
		
	case '70smagazine'
		% 70s magazine
		Tc = [25,-50,00; -25,00,00; -25,00,00; 00,00,00];
		Tm = [-25,-25,00; 50,00,00; -25,00,00; 00,00,00];
		Ty = [-25,00,00; -25,00,00; 50,00,00; 00,00,00];
		Tk = [00,00,00; 00,00,00; 00,00,00; 00,00,00];
		Tsat = [17,120,240,255,255];
		enforcement = 'normalizergb';
		processcmyk();
		
	case 'fadedprint'
		% faded print
		Tc = [00,00,00; 00,00,00; 00,00,00; 00,00,-60];
		Tm = [00,00,00; 00,00,00; 00,00,00; -22,40,161];
		Ty = [00,00,00; 00,00,00; 00,00,28; 33,33,16];
		Tk = [00,00,00; 00,00,00; 00,00,00; 77,-8,-80];
		Tsat = [255,255,255,255,255]; % effect strength versus S level [0 255]
		enforcement = 'preserve'; % 'preserve','clamp cmyk/rgb','normalize cmyk/rgb'
		processcmyk();
		
	case 'expired69'
		% expired 69
		Tc = [00,00,00; 00,00,00; 00,00,00; 00,00,00];
		Tm = [00,00,00; 00,00,00; 00,00,00; 07,-20,-33];
		Ty = [00,00,00; 00,00,00; 00,00,00; 48,-65,-77];
		Tk = [00,00,00; 00,00,00; 00,00,00; 45,45,00];
		Tsat = [255,255,255,255,255]; % effect strength versus S level [0 255]
		enforcement = 'preserve'; % 'preserve','clamp cmyk/rgb','normalize cmyk/rgb'
		processcmyk();
		
	case 'modernfilm'
		% modern film
		Tc = [00,20,00; 00,08,00; 00,00,00; 00,-23,00];
		Tm = [00,-13,00; 00,17,00; 00,00,00; -1,29,00];
		Ty = [00,00,00; 00,00,-12; 00,00,00; 19,68,18];
		Tk = [00,00,00; 00,00,00; 00,00,00; -5,55,-15 ];
		Tsat = [128,255,255,255,255];
		enforcement = 'preserve';
		processcmyk();

	otherwise
		error('TONEPRESET: unknown tone name %s',tone)
end		

outpict = (inpict-outpict)*(-amount);
outpict = inpict + outpict;

switch lower(presetenf)
	case 'clamp'
		outpict = imclamp(outpict);
	case {'normalize','norm'}
		outpict = simnorm(outpict);
end

outpict = imcast(outpict,inclass);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processcmyk()
	Tc = Tc/255;
	Tm = Tm/255;
	Ty = Ty/255;
	Tk = Tk/255;
	Tsat = Tsat/255;
	outpict = tonecmyk(inpict,Tc,Tm,Ty,Tk,Tsat,enforcement,'presetmode');
end

function processrgb()
	Tr = Tr/255;
	Tg = Tg/255;
	Tb = Tb/255;
	Tsat = Tsat/255;
	outpict = tonergb(inpict,Tr,Tg,Tb,Tsat,enforcement);
end

end % END MAIN SCOPE




