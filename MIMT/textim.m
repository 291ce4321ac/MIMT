function outpict = textim(intext,face)
%   OUTPICT=TEXTIM(INTEXT,{FACE})
%      Generate an image containing a single row of specified text rendered as 
%      fixed-width white characters on a black background.  This is an expansion 
%      of text2im() by Tobias Kiessling, the primary changes being a color 
%      inversion and the addition of extra font faces.  Most additional fonts are 
%      derived from the remarkably comprehensive font pack by VileR:
%      http://int10h.org/oldschool-pc-fonts/
%
%      The character set replicates all 256 characters of the IBM CP437 code 
%      as shown below.  Keep that in mind if you're expecting unicode/ASCII 
%      behavior outside of the common alphanumeric subset.  
%
%       ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !"#$%&'()*+,-./0123456789:;<=>?
%      @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂
%      ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐
%      └┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ 
%
%      If sizes other than native are desired, just use imresize(). Obviously, 
%      integer-factor scaling with nearest-neighbor interpolation is preferred.
%      If desired, double-height fonts can safely be scaled by half vertically.
%      If multiline text is desired, use textblock() or use imstacker() to 
%      concatenate images.
%
%   INTEXT is a simple character or numeric vector.  
%   FACE specifies the font (default 'tti-double')
%      'tti-native' is the heavy sans font used by text2im.  (size [10 9])
%      'tti-double' is the upscaling actually used by text2im  (size [20 18])
%      'ibm-vga-8x8' is a heavy, compact semi-serif font (IBM PC BIOS font)
%      'ibm-vga-14x8' is a heavy semi-serif font 
%      'ibm-vga-16x8' is a heavy semi-serif font 
%      'ibm-vga-8x9' is a heavy, compact semi-serif font 
%      'ibm-vga-14x9' is a heavy semi-serif font 
%      'ibm-vga-16x9' is the ubiquitous DOS-era semi-serif font
%      'ibm-iso-16x8' is a thin sans font
%      'ibm-iso-16x9' is a thin sans font
%      'compaq-8x8' is a thin, compact serif font
%      'compaq-14x8' is a thin serif font
%      'compaq-16x8' is a thin serif font
%      'hp-100x-8x6' is a thin, compact sans font
%      'hp-100x-8x8' is a heavy, compact serif font
%      'hp-100x-11x10' is a heavy, compact serif font
%      'hp-100x-12x16' is a heavy, wide serif font
%      'ti-pro' is a thin, compact semi-serif font. (size [12 9])
%      'everex-me' is an ultra-compact sans font (size [8 5])
%      'cordata-ppc21' is a double-height, thin sans font (size [26 16])
%      'wyse-700a' is a double-height, heavy serif font (size [32 16])
%      'wyse-700b' is a double-height, lighter sans font (size [32 16])
%      'tinynum' is an ultra-compact numeric-only font (size [6 4])
%      'micronum' is an ultra-compact numeric-only font (size [5 4])
%      'bithex' is a 4-pixel encoded hexadecimal-only font (size [3 3])
%      'bithex-gapless' same as 'bithex', but without padding (size [2 2])
%   Sample sheets for all fonts are provided on the web documentation.
%
%   Numeric-only fonts include 0123456789ABCDEFabcdef+-:;.,[]
%   These fonts are too small to unambiguously span the entire charset.
%   For the alpha characters it supports, 'micronum' is case-insensitive.
%
%   Hexadecimal-only fonts include 0123456789ABCDEFabcdef and are case-insensitve.
%   
%   Output is an image of class 'double'
%
%   EXAMPLE:
%      show the entire character map
%      imshow2('imtile(imdetile(textim(char(0:255)),[1 8]),[8 1])','tools')
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/textim.html
% See also: cp437, textblock

% regarding other FEX submissions doing the same thing:
% text2im by Tobias Kiessling is about the same speed as the smaller font cases, but the large font and black on white text are rarely useful (for me)
%    176 and 248 are transposed in the original table.  idk if this is a mistake or characteristic of something other than CP437
% text2im by H.J. Wisselink (Rik) offers other font faces, and is often faster, though only supports 128 chars and requires network connection
%    how this manages to be faster despite its complexity, overhead, and larger typical array sizes, i have no idea -- caching?
%    it seems this (~1.5x) speed advantage only exists in newer matlab versions, otherwise it's much slower (~5x-6x)
% text_to_image by Alec Jacobson is more flexible, but uses Imagemagick (external dependency), and is consequently about 1000x slower
%    this might be useful for generating the mat-files needed for textim(), but has issues presenting small bitmap fonts correctly
%    it seems non-trivial to get exact px/pt conversion, non-aa scaling, and zero-width padding from IM 

% compared to first version of this file, current version is significantly slower due to using mat-files instead of a single inline literal array
% using a consolidated literal array made it much faster than text2im, which uses loops and separate literals for each character
% having large literal arrays in the file slows down all cases due to parsing, so it only really works if there's only one font
% using mat-files is significantly faster (~2x) than using a simple image file (e.g. PBM)
% speed is governed by array size; smallest fonts are the fastest
% if max speed is needed again, a single-case version can be slapped together with an inline literal

% each font file contains a matrix of class 'logical' and named "charset"; its size is [charheight charwidth*256]
% all characters are simply horizontally concatenated in order
% to add a new font, simply add a new case to the switch structure
% specify the filename and character width accordingly

if ~exist('face','var')
	face = 'tti';
end

switch face
	case {'tti-double','tti'}
		charw = 18;
		S = load('tti-double.mat');
	case 'tti-native'
		charw = 9;
		S = load('tti.mat');
	case 'ti-pro'
		charw = 9;
		S = load('ti_pro.mat');
	case 'cordata-ppc21'
		charw = 16;
		S = load('cordata-ppc21.mat');
	case 'wyse-700a'
		charw = 16;
		S = load('wyse-700a.mat');
	case 'wyse-700b'
		charw = 16;
		S = load('wyse-700b.mat');
	case 'everex-me'
		charw = 5;
		S = load('everex-me.mat');
	case 'ibm-vga-8x8'
		charw = 8;
		S = load('ibm_bios.mat');
	case 'ibm-vga-14x8'
		charw = 8;
		S = load('ibm-vga-8x14.mat');
	case 'ibm-vga-16x8'
		charw = 8;
		S = load('ibm-vga-8x16.mat');
	case 'ibm-vga-8x9'
		charw = 9;
		S = load('ibm-vga-9x8.mat');
	case 'ibm-vga-14x9'
		charw = 9;
		S = load('ibm-vga-9x14.mat');
	case 'ibm-vga-16x9'
		charw = 9;
		S = load('ibm-vga-9x16.mat');
	case 'ibm-iso-16x8'
		charw = 8;
		S = load('ibm-iso-8x16.mat');
	case 'ibm-iso-16x9'
		charw = 9;
		S = load('ibm-iso-9x16.mat');
	case 'compaq-8x8'
		charw = 8;
		S = load('compaq_thin_8.mat');
	case 'compaq-14x8'
		charw = 8;
		S = load('compaq_thin_14.mat');
	case 'compaq-16x8'
		charw = 8;
		S = load('compaq_thin_16.mat');
	case 'hp-100x-8x6'
		charw = 6;
		S = load('hp_100x_6x8.mat');
	case 'hp-100x-8x8'
		charw = 8;
		S = load('hp_100x_8x8.mat');
	case 'hp-100x-11x10'
		charw = 10;
		S = load('hp_100x_10x11.mat');
	case 'hp-100x-12x16'
		charw = 16;
		S = load('hp_100x_16x12.mat');
	case 'tinynum'
		charw = 4;
		S = load('tinynum.mat');
	case 'micronum'
		charw = 4;
		S = load('micronum.mat');
	case 'bithex'
		charw = 3;
		S = load('bithex.mat');
	case 'bithex-gapless'
		charw = 2;
		S = load('bithex-gapless.mat');
	otherwise
		error('TEXTIM: unknown font face %s',face)
end


nc = numel(intext);
% generating a subscript vector is faster than looped assignment
osubs = zeros([1 charw*nc]);
for c = 1:nc
	ci = intext(c)+1;
	osubs((charw*(c-1)+1):(charw*c)) = (charw*(ci-1)+1):(charw*ci);
end
outpict = imcast(S.charset(:,osubs),'double');









