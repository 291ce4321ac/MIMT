function outpict = randlines(size,dim,varargin)
%   RANDLINES(SIZE, DIM, {OPTIONS})
%       generates image fields of random lines of various type
%
%   SIZE is a 2-element vector specifying the output image dimensions 
%   DIM specifies the line orientation
%      1 produces vertical stripes
%      2 produces horizontal stripes
%   OPTIONS include the keys and key-value pairs:
%      'mode' specifies the style of output (default is 'normal')
%          'normal' sets each line to a random value from 0-255
%          'walks' does a random walk when setting line values
%          'ramps' creates some goofy ramps of random length
%      'sparsity' increases threshold before displacement occurs (0 to 1)
%          this parameter has no effect in 'ramps' mode
%      'rate' is optionally used with'walk' and 'ramp' modes to scale the rate
%          at which the trend progresses.  A large rate will result in either
%          a clipped walk or short ramps.  Value is normalized WRT internal default.
%      'mono' specifies that the output image should be a single-channel image
%      'outclass' specifies the class of the output image (default 'double')
%          accepts any standard image class name
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/randlines.html
% See also: randspots, perlin, perlin3
	
rate = 1; 
sparsity = 0;
linemodestrings = {'normal','walks','ramps'};
linemode = 'normal';
outclassstrings = {'double','single','uint8','uint16','int16','logical'};
outclass = 'double';
mono = false;

if numel(varargin) > 0
	k = 1;
	while k <= numel(varargin);
		switch lower(varargin{k})
			case 'sparsity'
				if isnumeric(varargin{k+1})
					sparsity = varargin{k+1};
				else
					error('RANDLINES: expected numeric value for SPARSITY')
				end
				k = k+2;
			case 'rate'
				if isnumeric(varargin{k+1})
					rate = varargin{k+1};
				else
					error('RANDLINES: expected numeric value for RATE')
				end
				k = k+2;
			case 'mono'
				mono = true; 
				k = k+1;
			case 'mode'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,linemodestrings)
					linemode = thisarg;
				else
					error('RANDLINES: unknown line mode %s\n',thisarg)
				end
				k = k+2;
			case 'outclass'
				thisarg = lower(varargin{k+1});
				if strismember(thisarg,outclassstrings)
					outclass = thisarg;
				else
					error('RANDLINES: unknown output class %s\n',thisarg)
				end
				k = k+2;
			otherwise
				error('RANDLINES: unknown input parameter name %s',varargin{k})
		end
	end
end


s = size(1:2);
if strcmpi(linemode,'normal')
    if ~mono
        if dim == 2
            outpict = repmat(rand([s(1) 1 3]),[1 s(2) 1]);
        elseif dim == 1
            outpict = repmat(rand([1 s(2) 3]),[s(1) 1 1]);
        end    
    else
        if dim == 2
            outpict = repmat(rand([s(1) 1 1]),[1 s(2) 1]);
        elseif dim == 1
            outpict = repmat(rand([1 s(2) 1]),[s(1) 1 1]);
        end   
    end

    if sparsity ~= 0;
        outpict = max(outpict-sparsity,0)./(1-sparsity);
    end
    
    
elseif strcmpi(linemode,'walks')
    if nargin < 6
        rate = 1;
    end
    rate = rate*0.05;
    
	if dim == 1
		if ~mono
			stripe = rand([1 s(2) 3])-0.5;
		else
			stripe = rand([1 s(2) 1])-0.5;
		end
		stripe(abs(stripe) <= sparsity/2) = 0;
        stripe = cumsum(stripe*rate)+0.5;
        outpict = repmat(stripe,[s(1) 1 1]);
	elseif dim == 2
		if ~mono
			stripe = rand([s(1) 1 3])-0.5;
		else
			stripe = rand([s(1) 1 1])-0.5;
		end
		stripe(abs(stripe) <= sparsity/2) = 0;
        stripe = cumsum(stripe*rate)+0.5;
        outpict = repmat(stripe,[1 s(2) 1]);
	end
    
elseif strcmpi(linemode,'ramps')
    % this code could probably be compacted or faster, but wtfe
    % this is really garbage from an old ad-hoc script
    rate = rate*0.01;
	
    minlength = 1;
    if mono
        if dim == 2
            outpict = zeros(s(1:2))';
        elseif dim == 1
            outpict = zeros(s(1:2));
        end
        
        for n = 1:prod(s(1:2));
            k = rand(); % this was originally set outside the loop
            if n == 1, m = 1; else m = n-1; end

            %if outpict(m)>=(minlength+rand()*(1-minlength))
            if outpict(m) >= randrange([minlength 1]);
                continue;
            elseif k >= 0.95
                outpict(n) = outpict(m)+5*rate;
            elseif k >= 0.8
                outpict(n) = outpict(m)+3*rate;
            else
                outpict(n) = outpict(m)+1*rate; 
            end

		end
        
		if dim == 2
            outpict = outpict';
		end
    else
        outpict = zeros(s);
        for c = 1:3;
            outpict(:,:,c) = randlines(s,dim,'sparsity',sparsity,'mono','mode','ramps','rate',rate/0.01);
        end
    end
end

outpict = imcast(outpict,outclass);

return


















