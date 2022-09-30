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
while k <= numel(varargin);
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

s = size(inpict);
nchans = size(inpict,3);
[inpict inclass] = imcast(inpict,'double');

if (ismono(xmap) && ismono(ymap)) || nchans == 1
    monoflag = 1;
end



[X Y] = meshgrid(1:s(2),1:s(1));
if monoflag
	if size(xmap,3) == 3;
        xmap = mono(xmap,'y');
	end
	if size(ymap,3) == 3;
        ymap = mono(ymap,'y');
	end
   
    xmap = imcast(xmap,'double');
    ymap = imcast(ymap,'double');
        
    if amount(1) == 0
        fetchx = X;
    else
        A = amount(1)*(xmap-0.5)*2;
        fetchx = X+A;
    end

    if amount(2) == 0
        fetchy = Y;
    else
        A = amount(2)*(ymap-0.5)*2;
        fetchy = Y+A;
    end
    
    if strcmpi(edgetype,'replicate')
        fetchx = min(max(fetchx,1),s(2));
        fetchy = min(max(fetchy,1),s(1));
    elseif strcmpi(edgetype,'wrap')
        fetchx = max(mod(fetchx,s(2)),1);
        fetchy = max(mod(fetchy,s(1)),1);
    elseif isnumeric(edgetype)
        inpict = addborder(inpict,1,edgetype);
        fetchx = min(max(fetchx,0),s(2)+1)+1;
        fetchy = min(max(fetchy,0),s(1)+1)+1;
		fetchx = addborder(fetchx,1,1);
		fetchy = addborder(fetchy,1,1);
    else
        error('DISPLACE: unknown edge handling method')
    end

    outpict = inpict;
    for c = 1:nchans
		outpict(:,:,c) = interp2(X,Y,inpict(:,:,c),fetchx,fetchy,interpmethod);
    end
    
    if isnumeric(edgetype)
        outpict = cropborder(outpict,1);
    end
    
else
    outpict = inpict;
	for c = 1:3
        if size(xmap,3) == 3;
            xmapc = xmap(:,:,c);
        else
            xmapc = xmap;
        end
        if size(ymap,3) == 3;
            ymapc = ymap(:,:,c);
        else
            ymapc = ymap;
        end

        xmapc = imcast(xmapc,'double');
        ymapc = imcast(ymapc,'double');

        if amount(1) == 0
            fetchx = X;
        else
            A = amount(1)*(xmapc-0.5)*2;
            fetchx = X+A;
        end

        if amount(2) == 0
            fetchy = Y;
        else
            A = amount(2)*(ymapc-0.5)*2;
            fetchy = Y+A;
        end

        if strcmpi(edgetype,'replicate')
            fetchx = min(max(fetchx,1),s(2));
            fetchy = min(max(fetchy,1),s(1));
        elseif strcmpi(edgetype,'wrap')
            fetchx = max(mod(fetchx,s(2)),1);
            fetchy = max(mod(fetchy,s(1)),1);
        elseif isnumeric(edgetype)
            inpict = addborder(inpict,1,edgetype);
            fetchx = min(max(fetchx,0),s(2)+1)+1;
            fetchy = min(max(fetchy,0),s(1)+1)+1;
			fetchx = addborder(fetchx,1,1);
			fetchy = addborder(fetchy,1,1);
        else
            error('DISPLACE: unknown edge handling method')
        end

		channel = interp2(X,Y,inpict(:,:,c),fetchx,fetchy,interpmethod);

        if isnumeric(edgetype)
            outpict(:,:,c) = cropborder(channel,1);
        else 
            outpict(:,:,c) = channel;
        end
	end

end

outpict = imcast(outpict,inclass);
































