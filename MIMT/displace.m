function outpict = displace(inpict,amount,varargin)
%   DISPLACE(INPICT, AMOUNT, {OPTIONS})
%       Apply pixel displacement map(s)
%
%   INPICT is an I/RGB image of any standard image class
%   AMOUNT is a 2-element vector specifying maximal displacements
%       for X and Y directions ([maxx maxy])
%   OPTIONS are keys and key-value pairs:
%   'xmap' indicates that the following is the displacement map for X
%   'ymap' indicates that the following is the displacement map for Y
%       Displacement maps may be 2-D or 3-D.
%       If any specified map is not monochrome, displacements will be
%       performed on channels independently.  (see mono() for details)
%       Use 'mono' option to override this behavior.
%   'edgetype' indicate that the following specifies how edges are handled
%       'wrap' wraps the image circularly (default)
%       'replicate' performs edge replication (similar to 'smear' in GIMP)
%       if a 3-element vector is given, it will be used as a color fill
%       the color assignment should correspond to the white value of INPICT
%   'mono' specifies that the displacements should occur equally on all channels
%       If any specified displacement map is RGB, it will be flattened
%       by extracting its luma.  This is the same behavior used in GIMP.
%   'interpolation' specifies the interpolation method (default 'cubic')
%       Supported: 'nearest', 'linear' or 'cubic'
%
%   Output class is the same as input class
%
%   EXAMPLE:
%   dpict=displace(inpict,[1 1]*100,'xmap',xm,'ymap',ym,'edgetype','wrap','mono');
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/displace.html
% See also: imcartpol

xmap = 0;
ymap = 0;
edgetype = 'wrap';
monoflag = 0;
interpmethodstrings = {'nearest','linear','cubic'};
interpmethod = 'cubic';

k = 1;
while k <= numel(varargin)
	switch lower(varargin{k})
		case 'xmap'
			xmap = varargin{k+1};
			k = k+2;
		case 'ymap'
			ymap = varargin{k+1};
			k = k+2;
		case 'mono'
			monoflag = 1;
			k = k+1;
		case 'edgetype'
			edgetype = varargin{k+1};
			k = k+2;
		case 'interpolation'
			thisarg = varargin{k+1};
			if strismember(thisarg,interpmethodstrings)
				interpmethod = thisarg;
			else
				error('DISPLACE: unknown interpolation method %s\n',thisarg)
			end
			k = k+2;
		otherwise
			error('DISPLACE: unknown input parameter name %s',varargin{k})
	end
end


if (~(size(xmap,1) == size(inpict,1) && size(xmap,2) == size(inpict,2)) && numel(xmap) ~= 1)
	error('DISPLACE: height and width of XMAP do not match those of INPICT')
end
if (~(size(ymap,1) == size(inpict,1) && size(ymap,2) == size(inpict,2)) && numel(ymap) ~= 1)
	error('DISPLACE: height and width of YMAP do not match those of INPICT')
end
if ~any(size(xmap,3) == [1 3])
	error('DISPLACE: expected xmap to be an I/RGB image')
end
if ~any(size(ymap,3) == [1 3])
	error('DISPLACE: expected ymap to be an I/RGB image')
end

s = size(inpict);
nchans = size(inpict,3);
[inpict inclass] = imcast(inpict,'double');

if (ismono(xmap) && ismono(ymap)) || nchans == 1
	monoflag = 1;
end


xmap = imcast(xmap,'double');
ymap = imcast(ymap,'double');
fetchx = [];
fetchy = []; 

if isnumeric(edgetype)
	[X Y] = meshgrid(0:s(2)+1,0:s(1)+1);
	inpict = addborder(inpict,1,edgetype);
	xmap = padarrayFB(xmap,[1 1],0,'both');
	ymap = padarrayFB(ymap,[1 1],0,'both');
	if nchans == 1
		inpict = gray2rgb(inpict);
		nchans = 3;
	end
else
	[X Y] = meshgrid(1:s(2),1:s(1));
end

if monoflag
	if size(xmap,3) == 3
		thisxmap = mono(xmap,'y');
	else
		thisxmap = xmap;
	end

	if size(ymap,3) == 3
		thisymap = mono(ymap,'y');
	else
		thisymap = ymap;
	end
	
	scalemaps();
	constrainfetchxy();
	
	outpict = inpict;
	for c = 1:nchans
		outpict(:,:,c) = interp2(X,Y,inpict(:,:,c),fetchx,fetchy,interpmethod);
	end
else
	outpict = inpict;
	for c = 1:nchans
		if size(xmap,3) == 3
			thisxmap = xmap(:,:,c);
		else
			thisxmap = xmap;
		end
	
		if size(ymap,3) == 3
			thisymap = ymap(:,:,c);
		else
			thisymap = ymap;
		end
		
		scalemaps();
		constrainfetchxy();
		
		outpict(:,:,c) = interp2(X,Y,inpict(:,:,c),fetchx,fetchy,interpmethod);
	end
end

if isnumeric(edgetype)
	outpict = cropborder(outpict,1);
end
outpict = imcast(outpict,inclass);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scalemaps()
	if amount(1) == 0 % shortcut case
		fetchx = X;
	else
		A = amount(1)*(thisxmap-0.5)*2;
		fetchx = X+A;
	end
	
	if amount(2) == 0 % shortcut case
		fetchy = Y;
	else
		A = amount(2)*(thisymap-0.5)*2;
		fetchy = Y+A;
	end
end

function constrainfetchxy()
	if strcmpi(edgetype,'replicate')
		fetchx = imclamp(fetchx,[1 s(2)]);
		fetchy = imclamp(fetchy,[1 s(1)]);
	elseif strcmpi(edgetype,'wrap')
		fetchx = max(mod(fetchx,s(2)),1);
		fetchy = max(mod(fetchy,s(1)),1);
	elseif isnumeric(edgetype)
		fetchx = imclamp(fetchx,[0 s(2)+1]);
		fetchy = imclamp(fetchy,[0 s(1)+1]);
	else
		error('DISPLACE: unknown edge handling method')
	end
end

end % END MAIN SCOPE




























