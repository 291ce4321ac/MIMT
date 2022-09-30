function outpic = rectds(inpic,bsize,grid,Nblocks,Nframes,RGBlock,rim,outlines,mode);
%   RECTDS(INPICT, BLOCKSIZE, GRID, NBLOCKS, NFRAMES, LOCKRGB, {RIM}, {OUTLINES}, {MODE})
%
%   INPICT is an RGB image array (uint8)
%   BLOCKSIZE is an array specifying block sizes in pixels at start and end
%       [x0 y0; xf yf]
%   NBLOCKS is a row vector specifying number of blocks at start and end
%   GRID is a 2-element vector specifying the grid upon which blocks will
%       land.  use [0 0] for no grid
%   NFRAMES is the number of animation frames
%   LOCKRGB forces all channels to be sampled in a spatially-coordinated
%       manner.  (takes 0 or 1)
%   RIM if >0, specifies that the blocks should be hollow and defines
%       their annular width in pixels (default 0)
%   OUTLINES draw a dark 1-px border around each block (0 or 1) (default 0)
%   MODE 'mean' 'min' or 'max' specifies sampling method (default mean)
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/rectds.html
% See also: driftds rotateds

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 9
    mode = 'mean';
end
if nargin < 8
    outlines = 0;
end
if nargin < 7
    rim = 0;
end
rim = round(rim);
    
sz = size(inpic);
bsize = flipud(bsize);
grid = flipud(grid);
bsvec = round([bsize(1,1) + (bsize(2,1)-bsize(1,1))*(0.5+0.5*cos(2*pi*(1:1:Nframes)/Nframes));...
        bsize(1,2) + (bsize(2,2)-bsize(1,2))*(0.5+0.5*cos(2*pi*(1:1:Nframes)/Nframes))]);
gsvec = round([grid(1,1) + (grid(2,1)-grid(1,1))*(0.5+0.5*cos(2*pi*(1:1:Nframes)/Nframes));...
        grid(1,2) + (grid(2,2)-grid(1,2))*(0.5+0.5*cos(2*pi*(1:1:Nframes)/Nframes))]);  
nbvec = round(Nblocks(2) + (Nblocks(1)-Nblocks(2))*(0.5+0.5*cos(2*pi*(1:1:Nframes)/Nframes)));
    
outpic = zeros([size(inpic) Nframes],'uint8');
for m = 1:1:Nframes;
    bs = fliplr(bsvec(:,m)');
    gs = fliplr(gsvec(:,m)');
    nb = nbvec(m);
    
    maskpic = zeros(sz);
    
    if RGBlock == 0
        for c = [1 2 3]; % select channels
            for n = 1:1:nb;
                if all(gs == [0 0])
                    rx = max(1,round((sz(2)-bs(2))*rand()));
                    ry = max(1,round((sz(1)-bs(1))*rand()));
                else
                    % use these to build grid quantizer
                    rx = min(max(1,round(((sz(2)-bs(2))*rand())/gs(2))*gs(2)),sz(2)-bs(2));
                    ry = min(max(1,round(((sz(1)-bs(1))*rand())/gs(1))*gs(1)),sz(1)-bs(1));
                end
                
                switch lower(mode)
                    case 'mean'
                        blockmean = mean(mean(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    case 'min'
                        blockmean = min(min(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    case 'max'
                        blockmean = max(max(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    otherwise
                        disp('RECTDS: not a valid mode')
                        return
                end
                
                if rim == 0;
                    % normal block
                    maskpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c) = blockmean;
                else  
                    % hollow block
                    maskpic(ry:(ry+rim),rx:(rx+bs(2)),c) = blockmean; %top edge
                    maskpic((ry+bs(1)-rim):(ry+bs(1)),rx:(rx+bs(2)),c) = blockmean; %bottom edge
                    maskpic(ry:(ry+bs(1)),rx:(rx+rim),c) = blockmean; %left edge
                    maskpic(ry:(ry+bs(1)),(rx+bs(2)-rim):(rx+bs(2)),c) = blockmean; %right edge
                end
                
                if outlines == 1 % not quite black borders (maskblack)
                    maskpic(ry,rx:(rx+bs(2)),c) = 1; %top edge
                    maskpic((ry+bs(1)),rx:(rx+bs(2)),c) = 1; %bottom edge
                    maskpic(ry:(ry+bs(1)),rx,c) = 1; %left edge
                    maskpic(ry:(ry+bs(1)),(rx+bs(2)),c) = 1; %right edge
                end
            end
        end
    else
        for n = 1:1:nb;
            if all(gs == [0 0])
                rx = max(1,round((sz(2)-bs(2))*rand()));
                ry = max(1,round((sz(1)-bs(1))*rand()));
            else
                % use these to build grid quantizer
                rx = min(max(1,round(((sz(2)-bs(2))*rand())/gs(2))*gs(2)),sz(2)-bs(2));
                ry = min(max(1,round(((sz(1)-bs(1))*rand())/gs(1))*gs(1)),sz(1)-bs(1));
            end
            
            for c = [1 2 3]; % select channels
                switch lower(mode)
                    case 'mean'
                        blockmean = mean(mean(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    case 'min'
                        blockmean = min(min(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    case 'max'
                        blockmean = max(max(inpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c)));
                    otherwise
                        disp('RECTDS: not a valid mode')
                        return
                end
                
                if rim == 0;
                    % normal block
                    maskpic(ry:(ry+bs(1)),rx:(rx+bs(2)),c) = blockmean;
                else  
                    % hollow block
                    maskpic(ry:(ry+rim),rx:(rx+bs(2)),c) = blockmean; %top edge
                    maskpic((ry+bs(1)-rim):(ry+bs(1)),rx:(rx+bs(2)),c) = blockmean; %bottom edge
                    maskpic(ry:(ry+bs(1)),rx:(rx+rim),c) = blockmean; %left edge
                    maskpic(ry:(ry+bs(1)),(rx+bs(2)-rim):(rx+bs(2)),c) = blockmean; %right edge
                end
                
                if outlines == 1 % not quite black borders (maskblack)
                    maskpic(ry,rx:(rx+bs(2)),c) = 1; %top edge
                    maskpic((ry+bs(1)),rx:(rx+bs(2)),c) = 1; %bottom edge
                    maskpic(ry:(ry+bs(1)),rx,c) = 1; %left edge
                    maskpic(ry:(ry+bs(1)),(rx+bs(2)),c) = 1; %right edge
                end
            end
        end
    end
    
    outpic(:,:,:,m) = uint8(maskpic);

    disp('write frame')
end















return

