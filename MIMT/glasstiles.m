function outpict = glasstiles(inpict,tiles,permutation)
%   GLASSTILES(INPICT, TILES, {PERMUTATIONS})
%       using SHUFFLE(), create a glass tiles/lens effect
%
%   INPICT is an I/RGB image of any standard image class
%   TILES is a 2-element vector specifying the number of tiles
%       [tilesdown tilesacross]
%   PERMUTATIONS is a string or vector specifying the desired tile permutation
%       There are three options for this parameter:
%       'coherent' reverses tile order (default)
%       'random' uses a random tile permutation
%       May also be specified directly as a vector of dimension [1 prod(tiles)]
%       Elements are linear indices specifying the destination of tiles as they 
%       are to be moved in a grid of size=TILES.
%
%   Output class is inherited from input
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/glasstiles.html
% See also: shuffle

if exist('permutation','var')
    if strcmpi(permutation,'coherent')
        perms = prod(tiles):-1:1;
    elseif strcmpi(permutation,'random')
        perms = randperm(prod(tiles));
    elseif isnumeric(permutation)
        if numel(permutation) == prod(tiles)
            perms = permutation;
        else
            error('GLASSTILES: size of permutation array does not match prod(tiles)')
        end
    end
else
    permutation = 'coherent';
    perms = prod(tiles):-1:1;
end

% this is how arbitrary permutations are reversed
if strcmpi(permutation,'coherent')
    unmap = perms;
else
    unmap = 1:prod(tiles);
    unmap(perms) = unmap; 
end

s = size(inpict);
tsize = round(s(1:2)./tiles);
if norm(tsize) > 200
    %this is to help speed things up and avoid giant blur kernel
    disp('GLASSTILES: Tile size is large; this may take a while...')
    resized = 1;
    inpict = imresizeFB(inpict,s(1:2)*0.5);
    tsize = round(s(1:2)./tiles);  
else
    resized = 0;
end
h = fkgen('disk',ceil(norm(tsize)/2)*2);

% pad, permute, blur, un-permute, crop
outpict = shuffle(inpict,tiles,'locked',perms);
outpict = padarrayFB(outpict,tsize,'replicate');
outpict = imfilterFB(outpict,h);
outpict = cropborder(outpict,tsize);
outpict = shuffle(outpict,tiles,'locked',unmap);

if resized == 1;
    outpict = imresizeFB(outpict,s(1:2));
end

return





