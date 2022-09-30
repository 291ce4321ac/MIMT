function outpict = driftds(inpict,numframes,direction,bluramount,blurmode,disableagrad,coloroffset)
%   DRIFTDS(IMG,NUMFRAMES,DIRECTION,BLURAMOUNT,BLURMODE,DISABLEGRAD,COLOROFFSET)
%       returns an image sequence consisting of spatially downsampled
%       copies of the original image.  When animated, changing superpixel
%       boundaries create the illusion of linear motion.
%
%   NUMFRAMES is the number of image frames 
%   DIRECTION is a row vector specifying motion direction [H V]
%       can't accept 0 direction magnitude
%   BLURAMOUNT is a column vector specifying superpixel size
%       when DISABLEGRAD=1, all sizes are superimposed; otherwise,
%       vector relates a spatial sequence of sizes blended along DIRECTION.
%       neighboring values should be integer factors
%   BLURMODE specifies image mode used in offset and pixelization
%       accepts 'rgb' or 'hsv'
%   DISABLEGRAD 0 or 1 to disable gradient blending of drift layers
%   COLOROFFSET 3x2 matrix of pixel offsets per color channel RGB x XY 
%       nonfactoring offsets muddy non-sparse images
%
%   When running, DRIFTDS will echo the 3x2 channel offset matrix used
%   for calculating each frame during downsampling.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/driftds.html
% See also: rotateds rectds

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize shit
osize = [length(inpict(:,1,1)) length(inpict(1,:,1))];
wpict = uint8(zeros(osize(1),osize(2),3,numframes,length(bluramount)));

% create alpha gradient template
if disableagrad == 0 && length(bluramount) > 1;
    normdir = fliplr(direction)/norm(direction);
    L = round(dot(abs(normdir), osize));
    W = round(max(L,dot(fliplr(abs(normdir)), osize)));
    l = round(L/(length(bluramount)-1));
    
    % create double gradient band
    agradbase = repmat(interp1([-l 0 l],[0 1 0],-l:1:l),[W 1]);
    % add maximal padding for all m
    agradbase = [zeros(W,L-l) agradbase zeros(W,L-l)];
end

for m = 1:1:length(bluramount);
    % using bluramount to calc drift causes different drift rates
    % but helps ensures near-integer cycling in all regions
    amount = round(0:bluramount(m)/numframes:bluramount(m)-bluramount(m)/numframes);
    maxdisplacement = round(bluramount(m)*norm(direction));

    % update alpha gradient
    if disableagrad == 0 && length(bluramount) > 1;
        agrad = imcropFB(agradbase,[L-l*(m-1) 0 [W L]-[1 1]]);
        agrad = imrotateFB(agrad,180*atan(normdir(2)/normdir(1))/pi,'bilinear','crop');
        agrad = imcropFB(agrad,[fliplr(size(agrad)-osize)/2 fliplr(osize)-[1 1]]);
    end
    
    for n = 1:1:length(amount);
        % create variable-dim temporary image
        % wpict is a giant multidimensional array
        wtemp = inpict;

        % pad image
        wtemp = [repmat(wtemp(:,1,:),[1 maxdisplacement]), wtemp, ...
            repmat(wtemp(:,end,:),[1 maxdisplacement])];
        wtemp = [repmat(wtemp(1,:,:),[maxdisplacement 1]); wtemp; ...
            repmat(wtemp(end,:,:),[maxdisplacement 1])];

        % shift image and downsample
        shamt = round(repmat([-1 1].*repmat(amount(n),[1 2]).*direction,[3,1])+coloroffset);
        wtemp = straightshifter(wtemp,shamt);
        wtemp = blockify(wtemp,repmat(bluramount(m),[1 3]),blurmode);
        

        % shift back and crop
        wtemp = straightshifter(wtemp,-shamt); % consider extracting coloroffset here
        wtemp = imcropFB(wtemp,[maxdisplacement maxdisplacement fliplr(osize)-[1 1]]); 
        % cropping may cause dimension errors see 'help imcrop'
        
        % apply alpha gradient or simple average
        if disableagrad == 0 && length(bluramount) > 1;
            wtemp = uint8(repmat(agrad,[1 1 3]).*double(wtemp));
        elseif disableagrad == 1 && length(bluramount) > 1; 
            wtemp = uint8(double(wtemp)/length(bluramount));
        end

        wpict(:,:,:,n,m) = wtemp;
    end
    
    % blend drift layers together
    outpict = uint8(sum(wpict,5));
end

return
















