function outpict = erraccumulate(inpict,varargin)
%   ERRACCUMULATE(INPICT,OPTYPE,{OPTYE},{METHOD},{KEYS})
%      Repeatedly perform selected processes on float and integer copies of an image
%      then extract and stretch the difference. This is a lazy and overcomplicated way 
%      to turn images into complete garbage.  Don't expect this to have practical uses.
%
%   INPICT is an I/RGB image (though 'hue' modes only support RGB)
%
%   OPTYPE is the type of operation to perform (default 'scale')
%      'scale' performs image scaling using imresize
%      'rotate' performs image rotation using imrotate
%      'hue1' performs hue rotation using imtweak
%      'hue2' performs hue rotation in polar YPbPr and has more means of accumulating error
%      Multiple operations can be specified if OPTYPE is a cell array of strings
%      The length of OPTYPE determines the maximum length of other inputs
%
%   METHOD specifies how the operation is configured 
%      For 'scale', 'bilinear','bicubic','lanczos2','lanczos3' are valid (default 'bilinear')
%      For 'rotate', 'bilinear','bicubic' are valid (default 'bilinear')
%      For 'hue1', 'hsi','hsy' are valid (default 'hsi')
%      For 'hue2', 'clamp','noclamp' are valid (default 'clamp')
%      If an invalid METHOD is specified for a given OPTYPE, the default will be used.
%      If OPTYPE has multiple entries, METHOD may be a cell array of equal length.
%         if METHOD is a single string, it will be expanded as necessary.
%
%   KEYS and key-value pairs include:
%      CYCLES is the number of cycles each operation in OPTYPE should be performed (default 50)
%         If CYCLES and OPTYPE are of unequal length, CYCLES will be expanded as necessary.
%      STEP is the perturbation amount per cycle (default 5)
%         Dim 1 of STEP corresponds to the length of OPTYPE (with implicit expansion)
%         Dim 2 of STEP may be up to 2 elements wide
%         For 'scale', this is in pixels
%            'step',10     will scale both height & width by 10px
%            'step',[5 3]  will scale height & width independently
%         For other operations, this is in degrees
%            'step',2      will rotate 2 degrees
%            'step',[2 3]  will rotate 2 degrees (extra elements are ignored)
%      QUIET will inhibit pass and cycle counters which are otherwise dumped to the console
%
%   EXAMPLES:
%      Use defaults:
%         garbage = erraccumulate(inpict);
%      Do rotations and then scaling, allowing default interpolation and expansion of CYCLES:
%         garbage = erraccumulate(inpict,{'rotate','scale'},'cycles',20,'step',[0.05 0; 2 4]);
%      Do hue rotation and scaling, with full specification:
%         garbage = erraccumulate(inpict,{'hue1','scale'},{'hsy','bicubic'},'cycles',[20 40],'step',[2 0; 2 4]);
%
%   NOTES:
%      In general, it's better to use many small perturbations than few large ones
%      for 'scale', <10px is a good start
%      for 'rotate', use very small angles (typically <<1 degree)
%      for 'hue2', 'noclamp' reduces total error, but can lend some continuity to the error map
%
%   CLASS SUPPORT:
%      INPICT may be of any standard image class
%      Output class is 'double'
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/erraccumulate.html
% See also: imresize imrotate imtweak


tftypestrings = {'scale','rotate','hue1','hue2'};
tftype = tftypestrings(1);
methodtypestrings = {'bilinear','bicubic','lanczos2','lanczos3','hsy','hsi','clamp','noclamp'};
methodtype = methodtypestrings(1);
quiet = 0;

passes = 1;
cycles = 50; 
st = 5;

a = 1;
while a <= length(varargin)
	thisarg = varargin{a};
	if iscell(thisarg)
		if all(ismember(thisarg,tftypestrings))
			tftype = thisarg;
			passes = numel(tftype);
		elseif all(ismember(thisarg,methodtypestrings))
			if numel(thisarg) == passes
				methodtype = thisarg;
			else
				methodtype = thisarg(1);
			end
		end
		a = a+1;
	else
		switch lower(thisarg)
			case tftypestrings
				tftype = {thisarg};
				a = a+1;
			case methodtypestrings
				methodtype = {thisarg};
				a = a+1;
			case 'cycles'
				cycles = varargin{a+1};
				a = a+2;
			case 'step'
				st = varargin{a+1};
				a = a+2;
			case 'quiet'
				quiet = 1;
				a = a+1;
			otherwise
				error('ERRACCUMULATE: unknown key %s',thisarg)
		end	
	end
end


if size(st,1) ~= passes
	st = repmat(st(1,:),[passes 1]);
end

if numel(cycles) ~= passes
	cycles = repmat(cycles(1),[1 passes]);
end

if numel(methodtype) ~= passes
	methodtype = repmat(methodtype(1),[1 passes]);
end


s = [size(inpict,1) size(inpict,2)];
dblpict = imcast(inpict,'double');
intpict = imcast(inpict,'uint8');

for p = 1:passes
	if ~quiet; fprintf('Pass %d: %s x%d\n',p,tftype{p},cycles(p)); end
	
	if strcmp(tftype{p},'scale') 
		if ~ismember(methodtype{p},{'bicubic','bilinear','lanczos2','lanczos3'})
			thismethod = 'bilinear';
		else
			thismethod = methodtype{p};
		end
		
		thisst = ceil(st(p,:));
		if size(thisst,2) == 1
			thisst = repmat(st(p),[1 2]);
		end
		
		wblen = 0;
		for c = 1:cycles(p)
			if ~quiet
				strc = sprintf('Cycle %d\n',c);
				remc = repmat(sprintf('\b'),[1 wblen]);
				fprintf([remc strc]);
				wblen = numel(strc);
			end
			
			% scale cycle
			sw = size(dblpict);
			scalevec = [sw(1)+thisst(1) sw(2)+thisst(2)];
			dblpict = imresizeFB(dblpict,scalevec,thismethod);
			intpict = imresizeFB(intpict,scalevec,thismethod);
		end
		
		% remove cumulative scaling
		dblpict = imresizeFB(dblpict,s,thismethod);
		intpict = imresizeFB(intpict,s,thismethod);
		
		
	elseif strcmp(tftype{p},'rotate')
		if ~ismember(methodtype{p},{'bicubic','bilinear'})
			thismethod = 'bicubic';
		else
			thismethod = methodtype{p};
		end
		
		% image should be padded first to allow cropping per-cycle
		% this won't necessarily be the correct pad width if we pass a maxima
		% find first displacement of maximal padding, select correct padding
		displacement = sum(st(p,1).*cycles(p));
		if s(1) <= s(2)
			wdp = 90-atand(s(1)/s(2)); 
		else
			wdp = atand(s(1)/s(2)); 
		end
		
		if abs(displacement) >= wdp
			borderwidth = (sqrt(s(1)^2 + s(2)^2) - min(s(1:2)))/2;
		else
			borderwidth = abs(ceil(max(s(1:2))*sind(displacement)));
		end
		dblpict = addborder(dblpict,borderwidth,[0 0 0]);
		intpict = addborder(intpict,borderwidth,[0 0 0]);
		
		wblen = 0;
		for c = 1:cycles(p)
			if ~quiet
				strc = sprintf('Cycle %d\n',c);
				remc = repmat(sprintf('\b'),[1 wblen]);
				fprintf([remc strc]);
				wblen = numel(strc);
			end
			
			% rotate cycle
			dblpict = imrotateFB(dblpict,st(p,1),thismethod,'crop');
			intpict = imrotateFB(intpict,st(p,1),thismethod,'crop');
		end
		
		% remove cumulative rotation
		dblpict = imrotateFB(dblpict,-displacement,thismethod,'crop');
		intpict = imrotateFB(intpict,-displacement,thismethod,'crop');
		% crop back to size
		dblpict = cropborder(dblpict,borderwidth);
		intpict = cropborder(intpict,borderwidth);
		
		
	elseif strcmp(tftype{p},'hue1')
		if ~ismember(methodtype{p},{'hsi','hsy'})
			thismethod = 'hsi';
		else
			thismethod = methodtype{p};
		end
		
		wblen = 0;
		for c = 1:cycles(p)
			if ~quiet
				strc = sprintf('Cycle %d\n',c);
				remc = repmat(sprintf('\b'),[1 wblen]);
				fprintf([remc strc]);
				wblen = numel(strc);
			end
			
			% hue rotate cycle
			dblpict = imtweak(dblpict,thismethod,[st(p,1)/360 1 1]);
			intpict = imtweak(intpict,thismethod,[st(p,1)/360 1 1]);
		end
		
		% remove cumulative hue rotation
		displacement = mod(sum(st(p,1).*cycles(p)),360);
		dblpict = imtweak(dblpict,thismethod,[-displacement/360 1 1]);
		intpict = imtweak(intpict,thismethod,[-displacement/360 1 1]);
		
		
	elseif strcmp(tftype{p},'hue2')
		if ~ismember(methodtype{p},{'clamp','noclamp'})
			thismethod = 'clamp';
		else
			thismethod = methodtype{p};
		end
		
		% do hue rotation in YPbPr, allowing clipping in RGB to cause chroma distortion
		wblen = 0;
		for c = 1:cycles(p)
			if ~quiet
				strc = sprintf('Cycle %d\n',c);
				remc = repmat(sprintf('\b'),[1 wblen]);
				fprintf([remc strc]);
				wblen = numel(strc);
			end
			
			% hue rotate cycle	
			dblpict = rgb2ychpp(dblpict);
			dblpict(:,:,3) = mod(dblpict(:,:,3)+st(p,1),360);
			dblpict = ychpp2rgb(dblpict);
			
			intpict = rgb2ychpp(intpict);
			intpict(:,:,3) = mod(intpict(:,:,3)+st(p,1),360);
			intpict = ychpp2rgb(intpict);
			
			if strcmp(thismethod,'clamp')
				dblpict = min(max(dblpict,0),1);
				intpict = min(max(intpict,0),255);
			end
		end
		
		% remove cumulative hue rotation
		displacement = mod(sum(st(p,1).*cycles(p)),360);
		dblpict = rgb2ychpp(dblpict);
		dblpict(:,:,3) = mod(dblpict(:,:,3)-displacement,360);
		dblpict = ychpp2rgb(dblpict);

		intpict = rgb2ychpp(intpict);
		intpict(:,:,3) = mod(intpict(:,:,3)-displacement,360);
		intpict = ychpp2rgb(intpict);
		
		dblpict = min(max(dblpict,0),1);
		intpict = min(max(intpict,0),255);
	end

	% clear last cyclecounter display
	% if ~quiet; fprintf(repmat(sprintf('\b'),[1 wblen])); end
end

% difference, imlnc, resize
outpict = abs(dblpict-imcast(intpict,'double'));
outpict = imlnc(outpict,'independent');


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	% to support integer inputs correctly, these can't use bsxfun and need special treatment
	function out = rgb2ychpp(M)
		A = [0.299,0.587,0.114;-0.1687367,-0.331264,0.5;0.5,-0.418688,-0.081312];
		A = permute(A,[1 3 2]);
		
		My = M(:,:,1)*A(1,:,1) + M(:,:,2)*A(1,:,2) + M(:,:,3)*A(1,:,3);
		Mpb = M(:,:,1)*A(2,:,1) + M(:,:,2)*A(2,:,2) + M(:,:,3)*A(2,:,3);
		Mpr = M(:,:,1)*A(3,:,1) + M(:,:,2)*A(3,:,2) + M(:,:,3)*A(3,:,3);

		% convert to lch
		out(:,:,1) = My;				
		if isfloat(M)
			out(:,:,2) = sqrt(Mpr.^2+Mpb.^2);
			out(:,:,3) = mod(atan2(Mpr,Mpb),2*pi)/(2*pi);
		else
			out(:,:,2) = uint8(sqrt(double(Mpr.^2+Mpb.^2)));
			out(:,:,3) = mod(uint8(atan2(double(Mpr),double(Mpb))),2*pi)/(2*pi);
		end
	end

	function out = ychpp2rgb(R)
		Ai = [1,0,1.402; 1,-0.3441,-0.7141; 1,1.772,0];
		Ai = permute(Ai,[1 3 2]);
		
		Y = R(:,:,1);
		C = R(:,:,2);
		H = R(:,:,3)*2*pi; % rescale H

		% clamp at max chroma
		%Cnorm=maxchroma('ypp','luma',Y,'hue',H);
		%C=min(C,Cnorm);
		% we actually want clipping

		Rw(:,:,1) = Y;
		if isfloat(R)
			Rw(:,:,2) = C.*cos(H); % B
			Rw(:,:,3) = C.*sin(H); % R
		else
			Rw(:,:,2) = C.*uint8(cos(double(H))); % B
			Rw(:,:,3) = C.*uint8(sin(double(H))); % R
		end
		
		out(:,:,1) = Rw(:,:,1)*Ai(1,:,1) + Rw(:,:,2)*Ai(1,:,2) + Rw(:,:,3)*Ai(1,:,3);
		out(:,:,2) = Rw(:,:,1)*Ai(2,:,1) + Rw(:,:,2)*Ai(2,:,2) + Rw(:,:,3)*Ai(2,:,3);
		out(:,:,3) = Rw(:,:,1)*Ai(3,:,1) + Rw(:,:,2)*Ai(3,:,2) + Rw(:,:,3)*Ai(3,:,3);
	end


end




