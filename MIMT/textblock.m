function outpict = textblock(intext,geometry,varargin)
%  OUTPICT=TEXTBLOCK(INTEXT,SIZE,{OPTIONS})
%     Generate an image containing a multi-row block of specified text rendered as 
%     fixed-width white characters on a black background.  This tool uses textim();
%     as such, the character set is IBM CP437.  See textim() for details.
%
%     Word hyphenation is provided by hyphenate() by Stephen Cobeldick
%     https://www.mathworks.com/matlabcentral/fileexchange/61882-hyphenate
%
%  INTEXT is a character/numeric vector
%  SIZE specifies the maximum output image size in pixels
%     This parameter is in the form of a 2-element vector of format [HEIGHT WIDTH].  
%     If specified as a scalar, the specified value is presumed to be the width.  
%     If the height is specified as NaN (or is omitted via scalar specification), 
%     the image height will be determined by the text content.  If the height is 
%     explicitly specified such that there is not enough room for the text with the
%     selected options, an error will be returned. 
%        Alternatively, SIZE can be specified in the form [height minwidth maxwidth].  
%     When this form is used, textblock() will search for the width which will yield
%     the maximum character density within the given constraints and specified options.
%     When using this optimization method, the image will be close-cropped to give 
%     the minimum image area. Other padding/spacing/geometry options will be ignored.
%  OPTIONS include the key-value pairs:
%     'font' is any of the font names supported by textim() (default: 'tti-native')
%         Sample sheets for all fonts are provided on the web documentation.
%         http://mimtdocs.rf.gd/manual/html/textim.html
%     'halign' specifies the text justification (default 'left')
%         accepts 'left', 'center', or 'right'
%     'valign' specifies the vertical alignment of the text block (default 'center')
%         accepts 'top', 'center', or 'bottom'
%         This is only used when explicit height is specified
%     'tightwidth' only applies when height is implicit (default false)
%         Since most compiled text blocks will be slightly narrower than the specified
%         width, they are padded to fit by default.  Asserting 'tightwidth' disables 
%         this minor padding, minimizing excess image width for the calculated text flow.
%     'floatwidth' controls part of the horizontal padding (default true)
%         If 'tightwidth' is not asserted, the generated text block must be padded out
%         to fit the image width.  If 'floatwidth' is disabled, the horizontal alignment 
%         of the block within the image follows 'halign'; otherwise, the block is centered
%         regardless of 'halign'.  
%     'enablehyph' enables word hyphenation (default true)
%         When enabled, this will allow the hyphenation of words across line breaks.  It
%         also allows words containing certain delimiters (e.g. hyphenated words/phrases)
%         to be split across lines. 
%     'minorphan' is a 2-element vector limiting how words are hyphenated (default [2 3])
%         This is the minimum length of the word parts allowed at the end of a line and
%         the beginning of the next line.  
%     'hardbreak' specifies that all lines should be their maximal length (default false)
%         When asserted, this will override all word-level considerations and simply end
%         each line on the last character that will fit within the image.  No hyphenation
%         is added.  The result is ugly and hard to read, but it is maximally compact.
%     'linespacing' specifies the relative spacing between lines (default 1)
%
%  Output is a 2D image of class 'double'
%  
% Webdocs: http://mimtdocs.rf.gd/manual/html/textblock.html
% See also: textim, cp437


font = 'tti-native';
halignstrings = {'left','center','right'};
halign = 'left';
valignstrings = {'top','center','bottom'};
valign = 'center';
tightwidth = false; % force minimal width
floatwidth = true; % use centered h-padding regardless of justification
enablehyph = true;
minorphan = [2 3]; % minimum size of a word fragment left at the end or beginning of a line
hardbreak = false; % ignore all delimiters and split at the maximum char count per line (this implies no hyphenation!)
linespacing = 1;
testmode = false;
optimized = false;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'testmode'
				testmode = true;
				k = k+1;
			case 'tightwidth'
				tightwidth = varargin{k+1};
				k = k+2;
			case 'floatwidth'
				floatwidth = varargin{k+1};
				k = k+2;
			case 'enablehyph'
				enablehyph = varargin{k+1};
				k = k+2;
			case 'minorphan'
				if numel(varargin{k+1}) == 2
					minorphan = round(varargin{k+1});
				else
					error('TEXTBLOCK: minorphan should be a 2-element vector')
				end
				k = k+2;
			case 'hardbreak'
				hardbreak = varargin{k+1};
				k = k+2;
			case 'linespacing'
				linespacing = varargin{k+1};
				k = k+2;
			case 'font'
				font = varargin{k+1};
				k = k+2;
			case 'halign'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,halignstrings)
					halign = thisarg;
				else
					error('TEXTBLOCK: unknown halign type %s\n',thisarg)
				end
				k = k+2;
			case 'valign'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,valignstrings)
					valign = thisarg;
				else
					error('TEXTBLOCK: unknown valign type %s\n',thisarg)
				end
				k = k+2;
			otherwise
				error('TEXTBLOCK: unknown input parameter name %s',varargin{k})
		end
	end
end


if numel(geometry) == 1
	geometry = [NaN geometry];
end
round(geometry);

% find maximal packing density for given parameters
csz = imsize(textim('0',font),2);
if numel(geometry) == 3
	geometry(2) = max(geometry(2),csz(2));
	w = geometry(3):-ceil(csz(2)/2):geometry(2);
	density = [];
	for n = 1:numel(w)
		testpict = textblock(intext,[geometry(1) w(n)],'font',font,'enablehyph',enablehyph, ...
			'tightwidth',tightwidth,'hardbreak',hardbreak,'floatwidth',floatwidth,'minorphan',minorphan, ...
			'valign',valign,'halign',halign,'linespacing',linespacing,'testmode');
		if numel(testpict) == 1 && isnan(testpict); break; end
		density(n) = testpict;
	end
	[maxdens idx] = max(density); % maximize character density
	geometry = [NaN w(idx)];
	optimized = true;
end

if hardbreak
	enablehyph = false;
end
enablewdel = true; % enable splitting on word delimiters 

wsp = [0 32 255]; % whitespace characters in CP437
wdel = double('-_,./:;'); % selected delimiters

maxchars = floor(geometry./csz);
numchars = numel(intext);
splittext = {};

if maxchars(2) == 0
	error('TEXTBLOCK: Image is narrower than the character width of the selected font. (%dpx < %dpx)',geometry(2),csz(2))
end

if hardbreak
	for l = 1:ceil(numchars/maxchars(2))
		splittext(l) = {intext((maxchars(2)*(l-1)+1):min(maxchars(2)*l,numchars))};
	end
else
	dtext = double(intext);
	% build a list of all whitespace locations
	wspidx = [find(ismember(dtext,wsp)) numchars+1];
	
	% build a list of all internal word delimiters occurring within words
	delidx = find(ismember(dtext,wdel));
	a = intext(max(delidx-1,1)); b = intext(min(delidx+1,numchars));
	delidx = delidx(isstrprop(a,'alpha') & isstrprop(b,'alpha'));

	% incrementally disassemble the text into lines
	% this is a giant flaming mess.  i wouldn't be surprised if it exploded
	notdone = true;	l = 1;
	while notdone
		wbreak = max(wspidx(wspidx <= (maxchars(2)+1)));
		thislineisprefixed = false;
		if isempty(wbreak)
			% hyphenation routine can't pick up if it needs to hyphenate the first word on the line.
			% to avoid fixing that convoluted mess, try padding the arrays so it can be picked up
			intext = [' ' intext];
			wspidx = [1 wspidx+1];
			delidx = delidx+1;
			wbreak = 1;
			thislineisprefixed = true;
		end
		bp = find(wspidx == wbreak); % doing this by indexing is faster than using ismember

		% if we run into a contiguous block of whitespace split across lines
		% we want to find its extents and trim it out; this ignores mid-line ws blocks
		lcol = wbreak-1; keeplooking = true; tbp = bp;
		while keeplooking
			if tbp-1 < 1; break; end
			if wspidx(tbp-1) == lcol
				tbp = tbp-1; lcol = lcol-1;
			else
				keeplooking = false;
			end
		end
		fcol = wbreak+1; keeplooking = true; tbp = bp;
		while keeplooking
			if tbp+1 > numel(wspidx); break; end
			if wspidx(tbp+1) == fcol
				tbp = tbp+1; fcol = fcol+1;
			else
				keeplooking = false;
			end
		end

		okaytosplit = false;
		if enablehyph
			% see if there's anything to hyphenate
			if numel(intext) > maxchars(2);
				nextword = intext(fcol:(wspidx(tbp+1)-1));
				nonalpha = ~isstrprop(nextword,'alpha');
				
				% if this word has adjacent punctuation, we have to temporarily remove it for processing
				% isolated leading/trailing segments aren't used in the wdel path,
				% but we need to find the interior limits of nonalpha in order to test for that case entry anyway
				fna = []; lna = [];
				if any(nonalpha)
					dna = diff(nonalpha);
					fna = find(dna == -1,1,'first')+1;
					if any(dna(1:(fna-1)) == 1); fna = []; end
					lna = find(dna == 1,1,'last');
					if any(dna(lna:end) == -1); lna = []; end
				end
				
				leadchar = []; trailchar = [];
				if ~isempty(fna)
					leadchar = nextword(1:(fna-1));
					nextword = nextword(fna:end);
					nonalpha = nonalpha(fna:end);
				else
					fna = 1;
				end
				if ~isempty(lna)
					trailchar = nextword((lna+1-(fna-1)):end);
					nextword = nextword(1:(lna-(fna-1)));
					nonalpha = nonalpha(1:(lna-(fna-1)));
				end

				if any(nonalpha)
					% if the terminal word contains an internal delimiter (e.g. a hyphen), see if it can be split
					%fprintf('try to split ''%s'' since it contains internal non-alpha chars\n',nextword)
					if enablewdel
						mdelx = delidx(delidx > (fcol+minorphan(1)-1) & delidx < (wspidx(tbp+1)-minorphan(2)));
						if ~isempty(mdelx)
							mdelx = [fcol mdelx (wspidx(tbp+1)-1)];
							for bp = 1:(numel(mdelx)-1)
								wp1 = [' ' intext(mdelx(1):mdelx(end-bp))];
								wp2 = intext((mdelx(end-bp)+1):mdelx(end));
								%{wp1 wp2}
								if lcol+numel(wp1) <= maxchars(2)
									fcol = (wspidx(tbp+1)+1);
									okaytosplit = true; break;
								end
							end
						end
					end
				else		
					wordparts = hyphenate(nextword);
					sz = zeros([1 numel(wordparts)]); for s = 1:numel(wordparts); sz(s) = numel(wordparts{s}); end
					% this is a list of word part indices between which hyphenation can occur based on orphan size rules
					wbregion = find(cumsum(sz) >= minorphan(1) & fliplr(cumsum(fliplr(sz)) >= minorphan(2)));

					if numel(wbregion) < 2 
						%fprintf('can''t hyphenate ''%s'' due to length and orphan size rules\n',nextword)
					else
						for bp = (numel(wbregion)-1):-1:1
							wp1 = [' ' leadchar wordparts{1:wbregion(bp)} '-'];
							wp2 = [wordparts{(wbregion(bp+1)):end} trailchar];
							%{wp1 wp2}
							if lcol+numel(wp1) <= maxchars(2)
								fcol = (wspidx(tbp+1)+1);
								okaytosplit = true; break;
							end
						end
					end
				end
			end
		end
		
		if lcol == 0
			error(['TEXTBLOCK: Image is too narrow for the largest unsplittable word or word part.  Using hyphenation or ''hardbreak'' may help. ' ...
				'When using ''hardbreak'', minimum possible image width is equal to the character width of the selected font'])
		end
		
		% this method of trimming and restoring causes problems when line lengths are short
		splittext(l) = {intext(1:lcol)};
		intext = intext(fcol:end);
		wspidx = wspidx(wspidx >= fcol)-(fcol-1);
		delidx = delidx(delidx >= fcol)-(fcol-1);
		
		if okaytosplit
			splittext(l) = {[splittext{l} wp1]};
			intext = [wp2 ' ' intext];
			wspidx = [numel(wp2)+1 wspidx+numel(wp2)+1];
			delidx = delidx+numel(wp2)+1; % technically, there may be delimiters in wp2 that were pruned and not restored
		end
		
		if thislineisprefixed
			% correcting the prefix space after the fact means that the hyphenation routine is 
			% overconstrained by one character while calculating word fit. 
			% this is only an issue for extremely short lines less than 1 word long
			splittext(l) = {splittext{l}(2:end)};
		end
		
		if isempty(intext); notdone = false; end
		l = l+1;
	end
end

numlines = numel(splittext);
if ~testmode && ~optimized && linespacing > 1;
	vp = round((linespacing-1)*csz(1));
	estheight = numlines*csz(1)+vp*numlines-1;
end
if ~isnan(maxchars(1)) && (numlines > maxchars(1) || estheight > geometry(1))
	if testmode
		% this is used as a signal to the parent instance when running in testmode
		outpict = NaN; return;
	else
		error('TEXTBLOCK: Couldn''t fit the text into the specified geometry.  Consider using implicit geometry if output image height is not constrained by requirements.')
	end
end

% convert text to image rows
outpict = cell([1 numlines]);
for n = 1:numlines
	outpict{n} = textim(splittext{n},font);
	
	% add padding to effect line spacing functionality
	if ~testmode && ~optimized && linespacing > 1;
		if vp > 0 && n > 1
			outpict{n} = addborder(outpict{n},[vp 0 0 0],0);
		end
	end
end

% assemble into a single image with _no_ padding
hgravstrings = {'w','c','e'};
hgrav = hgravstrings{strcmp(halign,halignstrings)};
outpict = imstacker(outpict,'gravity',hgrav,'padding',0,'dim',1);

% if we're trying to minimize width, trim off any residual padding
% this happens because search routine stepsize is 1/2 char width
% or because glyph widths may be narrower than nominal character width
if testmode || optimized || tightwidth
	vsample = sum(outpict,1);
	lpad = cumsum(vsample) > 0; tpad = cumsum(fliplr(vsample)) > 0; 
	trimmask = lpad & fliplr(tpad);
	outpict = outpict(:,find(trimmask));
end

% calculate density with current character count
% this is not necessarily the same as numchars!	
if testmode	
	sz = []; for s = 1:numel(splittext); sz(s) = numel(splittext{s}); end
	outpict = sum(sz)./numel(outpict);
	return;
end

% optimization mode ignores padding options
if optimized; return; end

% add padding where needed
if ~isnan(maxchars(1)) && size(outpict,1) < geometry(1)
	% add h,v padding to suit explicit geometry spec
	vgravstrings = {'n','c','s'};
	vgrav = vgravstrings{strcmp(valign,valignstrings)};
	if floatwidth
		grav = vgrav;
	else
		grav = [vgrav hgrav]; grav = grav(double(grav) ~= double('c'));
		if isempty(grav); grav = 'c'; end
	end
	outpict = imstacker({outpict},'gravity',grav,'padding',0,'dim',4,'size',geometry);
elseif ~tightwidth && size(outpict,2) < geometry(2)
	% add horizontal padding to suit non-tight width spec
	if floatwidth; grav = 'c'; else grav = hgrav; end
	outpict = imstacker({outpict},'gravity',grav,'padding',0,'dim',4,'size',[size(outpict,1) geometry(2)]);
end




