function outpict = rotateds(inpict,numframes,blurcycles,shiftcycles,maxblur,maxshift,shiftphase)
%   ROTATEDS(INPICT, NUMFRAMES, BLURCYCLES, SHIFTCYCLES, {MAXBLUR}, {MAXSHIFT}, {SHIFTPHASE})
%       cyclically shifts the rows and columns of each channel in INPICT while simultaneously 
%       performing cyclic spatial downsampling (pixelization).  This results in a big wobbly
%       rainbow mess of colors.
%   
%   INPICT is a single RGB image
%   NUMFRAMES is the number of frames in the output animation
%   BLURCYCLES is the number of times to cycle the blur operation per imageset
%   SHIFTCYCLES is the number of times to cycle shift operations per imageset
%   MAXBLUR is the largest superpixel size reached during the blur cycles (default 32)
%       set to 1 for no blur
%   MAXSHIFT is a scaling factor used to adjust the vector shifts  (default 0.1)
%       set to 0 for no shift
%   SHIFTPHASE is a vector specifying the phase offsets for the shift operations 
%       default is [0 2*pi/3 4*pi/3] corresponding to [R G B]
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/rotateds.html
% See also: driftds rectds


if ~exist('maxblur','var')
    maxblur = 32;
end
if ~exist('maxshift','var')
    maxshift = 0.1;
end
if ~exist('shiftphase','var')
    shiftphase = [0 2*pi/3 4*pi/3];
end

mode = 'rgb';
amount = 1 + maxblur/2 + maxblur/2*sin((1:1:numframes)*blurcycles*2*pi/numframes);
shamt = zeros([3 2]);

layers = zeros([size(inpict) numframes],'uint8');
for n = 1:1:numframes;
    amount = circshift(amount,[0 1]);
    amt = [amount(1) amount(4) amount(7)];
    layers(:,:,:,n) = blockify(inpict,amt,mode);
    
    % also shift channels by row value
    shamt(1,1) = maxshift*sin(shiftcycles*n*2*pi/length(amount) + shiftphase(1));
    shamt(2,1) = maxshift*sin(shiftcycles*n*2*pi/length(amount) + shiftphase(2));
    shamt(3,1) = maxshift*sin(shiftcycles*n*2*pi/length(amount) + shiftphase(3));
    shamt(:,2) = flipud(shamt(:,1)); % include y-shifts 120d out of phase
    layers(:,:,:,n) = lineshifter(layers(:,:,:,n),layers(:,:,:,n),shamt);
end

outpict = layers;

return











