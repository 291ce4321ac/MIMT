function outpict = padarrayFB(inpict,padsize,varargin)
%   OUTPICT=PADARRAYFB(INPICT,PADSIZE,{OPTIONS})
%   Pad the edges of an array (ostensibly an image) with zeros or other content as 
%   specified by the available options.
%
%   This is a passthrough to the IPT function padarray(), with an internal 
%   fallback implementation to help remove the dependency of MIMT tools on the 
%   Image Processing Toolbox. As with other fallback tools, performance without 
%   IPT may be degraded.
%
%   INPICT is an image or other array
%   PADSIZE is a vector specifying the pad width, one element per axis
%
%   Optional arguments follow the syntaxes used by padarray():
%   PADARRAYFB(INPICT,PADSIZE,PADVAL)
%      PADVAL specifies the padding value to be used for the default padding method (default 0)
%         Unlike addborder(), padarray() and padarrayFB() only accept scalar padding values.
%   PADARRAYFB(INPICT,PADSIZE,PADVAL,DIRECTION)
%      DIRECTION specifies where to add the specified width padding (default 'both')
%         'pre' adds one pad to the beginning of each specified image axis
%         'post' adds one pad to the end of each specified image axis
%         'both' adds pads at both the beginning and end of each specified image axis
%   PADARRAYFB(INPICT,PADSIZE,METHOD,DIRECTION)
%      METHOD specifies alternate methods to fill the padding areas
%         'replicate' replicates the adjacent edge vectors of INPICT
%         'symmetric' mirrors the image content local to the padding area
%         'circular' copies image content opposite the padding area
%
%  Examples:
%    Add 5px solid gray padding to the left and right edges of an image
%      outpict=padarrayFB(inpict,[0 5],0.5,'both');
%    Add a 10px border around an image by mirroring the image edges
%      outpict=padarrayFB(inpict,[10 10],'symmetric','both');
%   
%  Output class is inherited from INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/padarrayFB.html
% See also: padarray, addborder

% IF IPT IS INSTALLED
if hasipt()
	outpict = padarray(inpict,padsize,varargin{:});
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

directionstrings = {'pre','post','both'};
direction = 'both';
methodstrings = {'zeros','symmetric','replicate','circular'};
method = 'value';
padval = 0;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin)
		if isimageclass(varargin{k},'mimt')
			padval = varargin{k};
		elseif ischar(varargin{k})
			switch lower(varargin{k})
				case methodstrings
					method = lower(varargin{k});
				case directionstrings
					direction = lower(varargin{k});
				otherwise
					error('PADARRAYFB: unrecognized argument %s',varargin{k})
			end
		end
		k = k+1;
	end
end

% padarray only supports scalar padval, so we're replicating that
if numel(padval) > 1
	error('PADARRAYFB: padval does not support vector (e.g. color tuple) assignments')
end

nd = ndims(inpict);
% padarray accepts scalar padsize, but treats the missing value as zero
if numel(padsize) < nd
	padsize = [padsize zeros([1 nd-numel(padsize)])];
end

inclass = class(inpict);
s = imsize(inpict,max(nd,numel(padsize)));
switch direction
	case 'both'
		rv = [1 1];
	case 'pre'
		rv = [1 0];
	case 'post'
		rv = [0 1];
end
padsize = kron(padsize,rv');

% shortcut
if all(padsize == 0)
	outpict = inpict;
	return;
end


% build subs list
idx = repmat({':'},[1 numel(s)]);
switch method
	case 'value'
		outpict = zeros(s+sum(padsize,1),inclass);
		outpict = outpict+imcast(padval,inclass);
		pd = find(sum(padsize,1) ~= 0);
		for k = 1:numel(pd)
			idx{pd(k)} = (1+padsize(1,pd(k))):(padsize(1,pd(k))+s(pd(k)));
		end
		outpict(idx{:}) = inpict;
		
	case 'replicate'
		pd = find(sum(padsize,1) ~= 0);
		for k = 1:numel(pd)
			idx{pd(k)} = [ones([1 padsize(1,pd(k))]) 1:s(pd(k)) ones([1 padsize(2,pd(k))])*s(pd(k))];
			outpict = inpict(idx{:});
		end
		
	case 'symmetric'
		pd = find(sum(padsize,1) ~= 0);
		for k = 1:numel(pd)
			%idx{pd(k)}=[padsize(1,pd(k)):-1:1 1:s(pd(k)) s(pd(k)):-1:(s(pd(k))-padsize(2,pd(k))+1)];
			subsbasis = [1:s(pd(k)) s(pd(k)):-1:1];
			idx{pd(k)} = subsbasis(mod(-padsize(1,pd(k)):s(pd(k))+padsize(2,pd(k))-1,2*s(pd(k))) + 1);
			outpict = inpict(idx{:});
		end

	case 'circular'
		pd = find(sum(padsize,1) ~= 0);
		for k = 1:numel(pd)
			%idx{pd(k)}=[(s(pd(k))-padsize(2,pd(k))+1):s(pd(k)) 1:s(pd(k)) 1:padsize(1,pd(k))];
			subsbasis = 1:s(pd(k));
			idx{pd(k)} = subsbasis(mod(-padsize(2,pd(k)):s(pd(k))+padsize(1,pd(k))-1,s(pd(k))) + 1);
			outpict = inpict(idx{:});
		end
				
end



















