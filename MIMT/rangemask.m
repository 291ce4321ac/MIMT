function mask = rangemask(inpict,channel,range,compmode)
%   RANGEMASK(INPICT, CHANNELS, RANGE, {COMPMODE})
%       returns a 2-D logical map of all pixels in INPICT specified via
%       a set of channel value ranges.  This is similar in purpose to 
%       MULTIMASK() or FINDPIXELS(), but it is much simpler to use
%       and can be more selective with fewer tests.
%
%   INPICT is an rgb image or 4-D array (assumed to be uint8)
%   CHANNELS is a string specifying which channel to test
%       multiple channels can be specified by concatenation
%       or as a cell array.  EX: 'rgb' or {'r','g','b'}
%       accepts 'r', 'g', 'b', 'h', 's', 'v', or 'y'
%   RANGE is an array wherein each row vector specifies a value range 
%       corresponding to each element of CHANNELS.  
%       each vector is treated as a closed interval [minval maxval]
%       White value is assumed to be 255 based on class(inpict)
%   COMPMODE specifies how matches should be logically compared
%       'not' is valid only if a single boundary is specified, otherwise
%       'and', 'or', 'xor', 'nand', 'nor', 'xnor' are available (default AND)
%
%   EX:
%       rangemask(inpict,'rgb',[0.25 0.75; 0.25 0.75; 0.25 0.75]*255,'not');
%       selects the exterior of the RGB color space to a depth of 0.25
%
%       rangemask(inpict,'hs',[0.89 0.91; 0.50 0.95]*255);
%       selects pink areas

if nargin == 3
    compmode = 'and';
end

if size(inpict,3) == 1
    inpict = repmat(inpict,[1 1 3]);
end

if numel(channel) ~= size(range,1)
    error('RANGEMASK: number of channels must match number of range vectors');
end

if iscell(channel)
    channel = [channel{:}];
end

if strcmpi(compmode,'not') && length(channel) > 1
    error('RANGEMASK: use ''nand'' instead of ''not'' for the union of negated matches')
end

if strcmpi(compmode,'not') || strcmpi(compmode,'nor') || ...
        strcmpi(compmode,'nand') || strcmpi(compmode,'xnor')
    negated = 1;
else
    negated = 0;
end

s = size(inpict);
numframes = size(inpict,4);
mask = false([s(1:2) 1 numframes]);
for t = 1:length(channel)
    thismask = false([s(1:2) 1 numframes]);
    thischannel = channel(t);
    thisrange = range(t,:);
    
    tidyname = lower(thischannel(thischannel ~= ' '));
    
    for f = 1:numframes;
        thisframe = inpict(:,:,:,f);
        switch tidyname
            case 'r'
                chan = thisframe(:,:,1);
            case 'g'
                chan = thisframe(:,:,2);
            case 'b'
                chan = thisframe(:,:,3);
            case {'h','s','v','y'}
                chan = mono(thisframe,tidyname);
            otherwise
                error('RANGEMASK: unknown channel name %s',tidyname);
        end

        thismask(:,:,:,f) = (chan >= thisrange(1)) & (chan <= thisrange(2));
    end
    
    if t == 1
        mask = thismask;
    else
        switch lower(compmode)
            case {'and','nand'}
                mask = thismask & mask;
            case {'or','nor'}
                mask = thismask | mask;
            case {'xor','xnor'}
                mask = xor(thismask, mask);
            otherwise 
				error('RANGEMASK: unknown compmode %s',compmode)
        end
    end
end

if negated == 1;
    mask = ~mask;
end

return










