function outpict = picdynamics(inpict,G,linetime,rangemode,mode)
%   PICDYNAMICS(INPICT, {G}, {RANGEMODE}, {MODE})
%       performs LTI system response simulation on the rows of INPICT
%       used with imblend() to effect analog crt drive defect emulation
%
%   INPICT is a single-frame image of any standard image class.  
%   G is the LTI system to use for simulation.  
%       by default, a generic system is selected with frequency scaled to the
%       image width.  Any other ZPK or TF can be used in place of this default.
%       if a single number is specified for G, it is treated as a frequency and
%       used in the default ZPK system.
%   LINETIME specifies the time represented by the scanning of one row
%       default is 60
%   RANGEMODE specifies how the output of the simulation should be handled
%       'squeeze' scales the output to fit in standard data range (default)
%       'clip' clips the output instead of scaling
%       'none' returns the output as-is.  Note that integer-class inputs will
%              inherently cause clipping during output casting anyway.
%   MODE specifies what channels should be operated on (default 'rgb') 
%     This mode operates on any input depth
%       'rgb' (process each channel independently) 
%     These modes only operate on RGB inputs
%       'h' (processes H in HSV)
%       'v' (process V in HSV)
%       'y' (process Y in YPbPr)
%     These modes only operate on I/RGB inputs
%       'v only' (output is greyscale triple of processed V)
%       'y only' (output is greyscale triple of processed Y)
%       single-channel modes reduce execution time by about 60%
%
%   EXAMPLE:
%   dpict=picdynamics(inpict,5,60,'squeeze');
%   out=imblend(dpict,inpict,1,'scale add',1.5);
%
%   Output class is inherited from input
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/picdynamics.html

if nargin < 5
    mode = 'rgb';
end
if nargin < 4
    rangemode = 'squeeze';
end
if nargin < 3
    linetime = 60;
end
if nargin < 2
    f = size(inpict,2)/100;
    Z = -1;
    P = [-1-f*1i -1+f*1i -2]; 
    K = 100;
    G = zpk(Z,P,K);
end

if isnumeric(G)
    f = G;
    Z = -1;
    P = [-1-f*1i -1+f*1i -2]; 
    K = 100;
    G = zpk(Z,P,K);
end

% this script and the defaults were originally selected based on
% a uint8 data range.  that's why everything is scaled to 255 even
% though it's all in floating point

[satpic inclass] = imcast(inpict,'double');
s = imsize(satpic);
t = 0:s(1)*linetime/(s(1)*s(2)-1):s(1)*linetime;
G = ss(G);
satpic = reshape(permute(satpic,[2 1 3]),1,[],s(3));

mode = lower(mode);
% handle inappropriate mode selection
rgbonlymodes = {'luma', 'y','v','value','hue','h'};
irgbonlymodes = {'v only','value only','y only','luma only'};
mismatchrgb = s(3)~=3 && strismember(mode,rgbonlymodes);
mismatchirgb = s(3)~=1 && s(3)~=3 && strismember(mode,irgbonlymodes);
if mismatchrgb || mismatchirgb
	mode = 'rgb'; % this should work for non-rgb inputs
end


%do a LTI system response for each line
switch mode
	case 'rgb'
		for c = 1:s(3)
			u = satpic(1,:,c)'*255;
			satpic(1,:,c) = lsim(G,u,t)'/255;
		end

		outpict = fitrange(satpic,rangemode);
		
	case {'luma', 'y'}
		A = gettfm('ypbpr');
		ypppic = imappmat(satpic,A);
		u = ypppic(1,:,1)'*255;
		ypppic(1,:,1) = lsim(G,u,t)'/255;

		ypppic(:,:,1) = fitrange(ypppic(:,:,1),rangemode);
		outpict = imappmat(ypppic,inv(A));
    
	case {'v','value'}
		hsvpic = rgb2hsv(satpic);
		u = hsvpic(1,:,3)'*255;
		hsvpic(1,:,3) = lsim(G,u,t)'/255;

		hsvpic(:,:,3) = fitrange(hsvpic(:,:,3),rangemode);
		outpict = hsv2rgb(hsvpic);
    
	case {'hue','h'}
		hsvpic = rgb2hsv(satpic);
		u = hsvpic(1,:,1)'*255;
		hsvpic(1,:,1) = lsim(G,u,t)'/255;

		hsvpic(:,:,1) = fitrange(hsvpic(:,:,1),rangemode);
		outpict = hsv2rgb(hsvpic);
    
	case {'y only','luma only'}
		ypict = mono(satpic,'y');
		u = ypict(1,:)'*255;
		ypict(1,:) = lsim(G,u,t)'/255;

		ypict = fitrange(ypict,rangemode);
		outpict = repmat(ypict,[1 1 3]);

	case {'v only','value only'}
		vpict = mono(satpic,'v');
		u = vpict(1,:)'*255;
		vpict(1,:) = lsim(G,u,t)'/255;

		vpict = fitrange(vpict,rangemode);
		outpict = repmat(vpict,[1 1 3]);
		
	otherwise 
		error('PICDYNAMICS: unknown mode %s',mode)
		
end

outpict = permute(reshape(outpict,s(2),s(1),s(3)),[2 1 3]);
outpict = imcast(outpict,inclass);

end % END MAIN SCOPE

function out = fitrange(in,rangemode)
	% scale everything back to data range [0 1]
	switch lower(rangemode)
		case 'squeeze'
			out = zeros(size(in));
			for c = 1:size(in,3)
				out(:,:,c) = simnorm(in(:,:,c));
			end
		case 'clip'
			out = imclamp(in);
		case 'none'
			out = in;
		otherwise 
			error('PICDYNAMICS: uknown range mode %s',rangemode)
	end
end












