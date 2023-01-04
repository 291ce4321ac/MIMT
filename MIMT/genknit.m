function outpict = genknit(bgcolor,rowcolors,nloops,varargin)
%  OUTPICT = GENKNIT(BGCOLOR,FGCOLOR,NLOOPS,{OPTIONS})
%  A novelty function to generate images of interlocking (knit) curves.
%  This was originally written to answer a forum question and really doesn't have 
%  much purpose beyond demonstrating compositing of mutually-occluding objects.  
%  Curves are oriented horizontally.
%
%  BGCOLOR is a single I/IA/RGB/RGBA color tuple (unit-scale)
%  FGCOLOR is an I/IA/RGB/RGBA color table (unit-scale)
%    Each row of FGCOLOR specifies the color for a single curve in the image.
%  NLOOPS is a scalar integer specifying the number of loops in each curve.
%  OPTIONS inlcude the key-value pairs
%    'loopsontop' controls the direction of the weave (default false)
%    'looph' controls the nominal loop height (px, default 200)
%    'loopw' controls the nominal loop width (px, default 155)
%    'linew' controls the nominal line width (px, default 30)
%    'yoffset' allows adjustment of the spacing between curves (default 0)
%
%  Nominal mask parameters are subject to rounding and padding.  Maximum linew 
%  is a function of looph, loopw, yoffset, and the quarter-curve function parameters.
%  There's nothing stopping you from causing clipping if you adjust things.
%  
%  Output image geometry is poorly controlled.  You'll get whatever size results 
%  from the selected parameters. You can resize or crop it to a particular size.
%
%  Output class is 'double'
%  See also: ptile, randspots

% defaults
loopheight = 200; % nominal loop size
loopwidth = 155; % nominal loop size
strokew = 30; % nominal stroke width
yos = 0; % allows y-offset between rows
loopsontop = false; % controls layer order

% handle inputs
if numel(varargin)>0
	for k = 1:2:numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case 'looph'
				loopheight = varargin{k+1};
			case 'loopw'
				loopwidth = varargin{k+1};
			case 'linew'
				strokew = varargin{k+1};
			case 'loopsontop'
				loopsontop = varargin{k+1};
			case 'yoffset'
				yos = varargin{k+1};
			otherwise
				error('GENKNIT: unknown key name %s',thisarg)
		end
	end
end

% generate base single-loop mask
basemk = generatebasemk(loopheight,loopwidth,strokew);

% prepare masks and compose image
outpict = composeimg(basemk,nloops,strokew,bgcolor,rowcolors,loopsontop,yos);
	
end % END MAIN SCOPE


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outpict = composeimg(basemk,nloops,strokew,bgcolor,rowcolors,loopsontop,yos)
	% split single-loop mask into halves
	halfh = size(basemk,1)/2;
	tophalf = basemk(1:halfh,:);
	bothalf = basemk(halfh+1:end,:);

	% pad overlapped mask regions
	padh = roundeven(halfh + max(ceil(strokew/2) + yos,0)) - halfh; % pad, ensuring even height
	tophalfmid = padarrayFB(tophalf,[padh 0],0,'pre'); % loop tops
	bothalfmid = padarrayFB(bothalf,[padh 0],0,'post'); % loop bots
	
	% resplit to create quarter-row masks for compositing
	halfh = round(size(tophalfmid,1)/2);
	midtu = tophalfmid(1:halfh,:); % lower half of loop tops
	midtl = tophalfmid(halfh+1:end,:); % upper half of loop tops
	midbu = bothalfmid(1:halfh,:); % lower half of loop bots
	midbl = bothalfmid(halfh+1:end,:); % upper half of loop bots

	% create background templates
	BGend = colorpict(imsize(tophalf,2),bgcolor);
	BGmid = colorpict(imsize(midtu,2),bgcolor);
		
	% construct the output image chunks
	nsubimages = size(rowcolors,1)+1;
	C = cell(nsubimages,1);
	for k = 1:nsubimages
		if k == 1
			C{k} = replacepixels(rowcolors(1,:),BGend,tophalf);
		elseif k == nsubimages
			C{k} = replacepixels(rowcolors(end,:),BGend,bothalf);
		else
			if loopsontop
				Au = replacepixels(rowcolors(k-1,:),BGmid,midbu);
				Au = replacepixels(rowcolors(k,:),Au,midtu);
				Al = replacepixels(rowcolors(k,:),BGmid,midtl);
				Al = replacepixels(rowcolors(k-1,:),Al,midbl);
				C{k} = [Au; Al];
			else
				Au = replacepixels(rowcolors(k,:),BGmid,midtu);
				Au = replacepixels(rowcolors(k-1,:),Au,midbu);
				Al = replacepixels(rowcolors(k-1,:),BGmid,midbl);
				Al = replacepixels(rowcolors(k,:),Al,midtl);
				C{k} = [Au; Al];
			end
		end
	end
	outpict = vertcat(C{:});
	outpict = repmat(outpict,[1 nloops]);
end


function basemask = generatebasemk(rowheight,loopwidth,strokew)
	% parameters
	kaa = 3; % antialiasing upscale factor (i'm lazy)

	% the basic half-loop curve construction
	y = linspace(0,1,100); % start with quarter-curve
	x = (y.^(1/3) - 0.5*y) .* (1 + 0.7*(1 - (y + (1-y).^4)));
	x = [x fliplr(1-x)]; % half-curve expansion
	y = 1-[y y+1];

	% generate half-loop block mask
	rowheight = roundeven(rowheight*kaa,'ceil');
	vpad = ceil(kaa*strokew/2);
	blocksz = [rowheight+2*vpad round(kaa*loopwidth/2)];
	x = imrescale(x,imrange(x),[1 blocksz(2)]); % rescale to image coordinates
	y = imrescale(y,imrange(y),[1+vpad rowheight+vpad]);
	basemask = brline(blocksz,[x(:) y(:)]); % draw polyline

	% assemble the base row mask
	se = simnorm(fkgen('disk',2*vpad))>0.5;
	basemask = morphops(basemask,se,'dilate'); % dilate
	basemask = imresizeFB(double(basemask),1/kaa,'bilinear'); % downscale
	basemask = [basemask fliplr(basemask)]; % replicate
	
	% cast and rescale data for output
	basemask = imcast(basemask,'uint8');
end


