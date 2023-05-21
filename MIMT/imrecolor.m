function outpict = imrecolor(ref,inpict,varargin)
%   OUTPICT=IMRECOLOR(REFPICT,INPICT,{OPTIONS})
%      Use histogram matching to transfer color information from one image to another
%      without transferring any object content from the reference image, as would otherwise
%      occur with a simple 'color' type image blend.  This is accomplished by sorting the 
%      pixels into a specified number of bins by brightness and then performing histogram 
%      matching on the hue and chroma/saturation data within each of those bins. The result 
%      is a brightness-correlated color distribution match between the images.  In other words, 
%      the working image is unsubtly forced to inherit a color "theme" from the reference image.
%      
%   REFPICT, INPICT are RGB images of any standard image class.  Image height, width
%      do not need to match.
%   
%   OPTIONS include the key-value pairs:
%   'colormodel' specifies the color model to use.  Values include;
%      'hsly' for luma-corrected HSL (fast & good) (default)
%      'hsvy' for luma-corrected HSV (fast & good)
%      'hsl' for standard HSL (fast)
%      'hsv' for standard HSV (fast)
%      'hsy' or 'hsyp' for the corresponding HSY variant (fast)
%      'lch' for LCHuv (slow & good)
%      'husl' for HuSLuv (slowest, poor)
%      'rgby' for luma-corrected RGB (fastest, worst)
%   'channels' specifies the channels to match (default 'color')
%      'hs' selects hue and saturation/chroma channels ('color' is synonymous)
%      'h', 's', or 'c' will select only the corresponding channel.
%      In RGB mode, use 'r', 'g', or 'b' for selecting individual channels, 
%      or select all channels using 'rgb' or 'color'.
%      Not all channels are relevant to all color models, but an attempt is made
%      to assume intent.  (e.g. either 's' or 'c' will select chroma in LCH)
%   'ybins' specifies the number of luma/lightness bins (default 16)
%   'cbins' specifies the number of color bins (default 128)
%   'blursize' specifies the size of the color smoothing blur (default 10px)
%      By default, these modes incorporate a blur operation in order to reduce speckling 
%      with some image combinations. Setting blursize to 0px disables smoothing.
%
%   Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imrecolor.html

% hsly/hsvy modes are chroma-limited, like the imblend hslyc/hslyc color modes

% defaults
cmstrings = {'lch','husl','hsl','hsly','hsv','hsvy','rgb','rgby','hsy','hsyp'};
colormodel = 'hsly';
blursize = 10;
numybins = 16;
numcbins = 128;
chanstrings = {'color','hs','h','s','c','rgb','r','g','b'};
channels = chanstrings{1};

k = 1;
while k <= numel(varargin)
    switch lower(varargin{k})
        case 'colormodel'
            thisarg = lower(varargin{k+1});
			if strismember(thisarg,cmstrings)
				colormodel = thisarg;
			else
				error('IMRECOLOR: unknown color model %s\n',thisarg)
			end
			k = k+2;
		case 'blursize'
            blursize = varargin{k+1};
			k = k+2;
		case 'ybins'
			numybins = varargin{k+1};
			k = k+2;
		case 'cbins'
			numcbins = varargin{k+1};
			k = k+2;
		case 'channels'
			thisarg = lower(varargin{k+1});
			if strismember(thisarg,chanstrings)
				channels = thisarg;
			else
				error('IMRECOLOR: unknown channel string %s\n',thisarg)
			end
			k = k+2;
        otherwise
            error('IMRECOLOR: unknown input parameter name %s',varargin{k})
    end
end

% sanitize inputs
numybins = min(max(round(numybins),1),256);
numcbins = min(max(round(numcbins),1),256);

if blursize > 1
	fk = fkgen('gaussian',blursize);
end

ref = imcast(ref,'double');
[inpict, inclass] = imcast(inpict,'double');

switch colormodel
	case 'lch'
		M = rgb2lch(ref,'luv'); I = rgb2lch(inpict,'luv');
		switch channels
			case {'hs','color'}
				MH = M(:,:,3)/360; IH = I(:,:,3)/360;
				MC = M(:,:,2)/100; IC = I(:,:,2)/100; 
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,1),I(:,:,1),MH,IH,MC,IC);
				R = lch2rgb(cat(3,I(:,:,1),IC*100,IH*360),'luv','truncatelch');
			case 'h'
				MH = M(:,:,3)/360; IH = I(:,:,3)/360;
				IH = matchhistograms(numybins,numcbins,M(:,:,1),I(:,:,1),MH,IH);
				R = lch2rgb(cat(3,I(:,:,1),I(:,:,2),IH*360),'luv','truncatelch');
			case {'s','c'}
				MC = M(:,:,2)/100; IC = I(:,:,2)/100; 
				IC = matchhistograms(numybins,numcbins,M(:,:,1),I(:,:,1),MC,IC);
				R = lch2rgb(cat(3,I(:,:,1),IC*100,I(:,:,3)),'luv','truncatelch');
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for LCH mode',channels)
		end

	case 'husl'
		M = rgb2husl(ref); I = rgb2husl(inpict);
		switch channels
			case {'hs','color'}
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				MC = M(:,:,2)/100; IC = I(:,:,2)/100; 
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3),I(:,:,3),MH,IH,MC,IC);
				R = husl2rgb(cat(3,IH*360,IC*100,I(:,:,3)));
			case 'h'
				MH = M(:,:,3)/360; IH = I(:,:,3)/360;
				IH = matchhistograms(numybins,numcbins,M(:,:,3),I(:,:,3),MH,IH);
				R = husl2rgb(cat(3,IH*360,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				MC = M(:,:,2)/100; IC = I(:,:,2)/100; 
				IC = matchhistograms(numybins,numcbins,M(:,:,3),I(:,:,3),MC,IC);
				R = husl2rgb(cat(3,I(:,:,1),IC*100,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HuSL mode',channels)
		end
		
	case {'rgb','rgby'}
		M = ref; I = inpict;
		A = gettfm('ypbpr');
		Ai = gettfm('ypbpr_inv');
		My = imappmat(M,A(1,:,:));
		Iy = imappmat(I,A(1,:,:));
		switch channels
			case {'hs','color','rgb'}
				[R,G,B] = matchhistograms(numybins,numcbins,My,Iy,M(:,:,1),I(:,:,1),M(:,:,2),I(:,:,2),M(:,:,3),I(:,:,3));
				R = cat(3,R,G,B);
			case 'r'
				R = matchhistograms(numybins,numcbins,My,Iy,M(:,:,1),I(:,:,1));
				R = cat(3,R,I(:,:,2),I(:,:,3));
			case 'g'
				G = matchhistograms(numybins,numcbins,My,Iy,M(:,:,2),I(:,:,2));
				R = cat(3,I(:,:,1),G,I(:,:,3));
			case 'b'
				B = matchhistograms(numybins,numcbins,My,Iy,M(:,:,3),I(:,:,3));
				R = cat(3,I(:,:,1),I(:,:,2),B);
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for RGB+Y mode',channels)
		end		
		Rypp = cat(3,Iy,imappmat(R,A(2:3,:,:)));
		R = imappmat(Rypp,Ai);
		
	case 'hsy'
		M = rgb2hsy(ref); I = rgb2hsy(inpict);
		switch channels
			case {'hs','color'}
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsy2rgb(cat(3,IH*360,IC,I(:,:,3)));
			case 'h'
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsy2rgb(cat(3,IH*360,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsy2rgb(cat(3,I(:,:,1),IC,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSY mode',channels)
		end	
		
	case 'hsyp'
		M = rgb2hsy(ref,'pastel'); I = rgb2hsy(inpict,'pastel');
		switch channels
			case {'hs','color'}
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsy2rgb(cat(3,IH*360,IC,I(:,:,3)),'pastel');
			case 'h'
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsy2rgb(cat(3,IH*360,I(:,:,2),I(:,:,3)),'pastel');
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsy2rgb(cat(3,I(:,:,1),IC,I(:,:,3)),'pastel');
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSY mode',channels)
		end	
		
	case 'hsl'
		M = rgb2hsl(ref); I = rgb2hsl(inpict);
		switch channels
			case {'hs','color'}
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsl2rgb(cat(3,IH*360,IC,I(:,:,3)));
			case 'h'
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsl2rgb(cat(3,IH*360,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsl2rgb(cat(3,I(:,:,1),IC,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSL mode',channels)
		end	
		
	case 'hsly'
		M = rgb2hsl(ref); I = rgb2hsl(inpict);
		A = gettfm('ypbpr');
		Iy = imappmat(inpict,A(1,:,:));
		switch channels
			case {'hs','color'}
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsl2rgb(cat(3,IH*360,IC,I(:,:,3)));
			case 'h'
				MH = M(:,:,1)/360; IH = I(:,:,1)/360;
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsl2rgb(cat(3,IH*360,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsl2rgb(cat(3,I(:,:,1),IC,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSL+Y mode',channels)
		end	
		Rlchbr = rgb2lch(R,'ypbpr');
		Rlchbr(:,:,1) = Iy;
		R = lch2rgb(Rlchbr,'ypbpr','truncatelch');
	
	case 'hsv'
		M = rgb2hsv(ref); I = rgb2hsv(inpict);
		switch channels
			case {'hs','color'}
				MH = M(:,:,1); IH = I(:,:,1);
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsv2rgb(cat(3,IH,IC,I(:,:,3)));
			case 'h'
				MH = M(:,:,1); IH = I(:,:,1);
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsv2rgb(cat(3,IH,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsv2rgb(cat(3,I(:,:,1),IC,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSV mode',channels)
		end	
		
	case 'hsvy'
		M = rgb2hsv(ref); I = rgb2hsv(inpict);
		A = gettfm('ypbpr');
		Iy = imappmat(inpict,A(1,:,:));
		switch channels
			case {'hs','color'}
				MH = M(:,:,1); IH = I(:,:,1);
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				[IH,IC] = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH,M(:,:,2),I(:,:,2));
				R = hsv2rgb(cat(3,IH,IC,I(:,:,3)));
			case 'h'
				MH = M(:,:,1); IH = I(:,:,1);
				MH(isnan(MH)) = 0; IH(isnan(IH)) = 0;
				IH = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,MH,IH);
				R = hsv2rgb(cat(3,IH,I(:,:,2),I(:,:,3)));
			case {'s','c'}
				IC = matchhistograms(numybins,numcbins,M(:,:,3)*100,I(:,:,3)*100,M(:,:,2),I(:,:,2));
				R = hsv2rgb(cat(3,I(:,:,1),IC,I(:,:,3)));
			otherwise
				error('IMRECOLOR: unknown or unsupported channel substring %s for HSV+Y mode',channels)
		end	
		Rlchbr = rgb2lch(R,'ypbpr');
		Rlchbr(:,:,1) = Iy;
		R = lch2rgb(Rlchbr,'ypbpr','truncatelch');
		

	otherwise
		error('IMRECOLOR: unknown or unspecified color model')
end

if blursize > 1
	Rlch = rgb2lch(imfilterFB(R,fk),'luv');
	if strcmp(colormodel,'lch')
		Ilch = I;
	else
		Ilch = rgb2lch(inpict,'luv');
	end
	Ilch(:,:,2:3) = Rlch(:,:,2:3);
	R = lch2rgb(Ilch,'luv','truncatelch');
end
outpict = imcast(R,inclass);

end

% recolor matching %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = matchhistograms(numybins,histbins,ML,IL,MA,IA,MB,IB,MC,IC)
	skipthismatch = false;
	for ybin = 1:numybins
		binlims = [(ybin-1)/numybins ybin/numybins]*100;
		while 1
			if ybin == 1
				binmaskM = (ML >= binlims(1) & (ML <= binlims(2)));
				binmaskI = (IL >= binlims(1) & (IL <= binlims(2)));
			else
				binmaskM = (ML > binlims(1) & (ML <= binlims(2)));
				binmaskI = (IL > binlims(1) & (IL <= binlims(2)));
			end

			% if FG bin is empty, but BG bin is not, widen the bin until we can get a reference
			% if BG bin is empty, regardless of FG bin state, skip this histmatch entirely
			bincounts = [sum(sum(binmaskM)) sum(sum(binmaskI))];
			if bincounts(1) == 0 && bincounts(2) ~= 0
				binlims = binlims.*[0.98 1.02];
			elseif bincounts(2) == 0
				skipthismatch = true; 
				break;
			else
				break;
			end
		end
		if skipthismatch; skipthismatch = false; continue; end

		IA(binmaskI) = imhistmatch(IA(binmaskI),MA(binmaskM),histbins);
		if exist('IB','var')
			IB(binmaskI) = imhistmatch(IB(binmaskI),MB(binmaskM),histbins);
		end
		if exist('IC','var')
			IC(binmaskI) = imhistmatch(IC(binmaskI),MC(binmaskM),histbins);
		end
	end
	if exist('IC','var')
		varargout{1} = IA;
		varargout{2} = IB;
		varargout{3} = IC;
	elseif exist('IB','var')
		varargout{1} = IA;
		varargout{2} = IB;
	else
		varargout{1} = IA;
	end
end














