function  varargout = batchloader(path,imgnums,basename)
%   BATCHLOADER(PATH, IMNUMBERS, BASENAME)
%   [RGB ALPHA]=BATCHLOADER(PATH, IMNUMBERS, BASENAME)
%       a convenience script for loading arbitrary subsets
%       of files from a sequence of individual image files
%       Assumes filenames formatted with a leading number sequence
%       e.g. 01_name.jpg 02_name.jpg etc
%
%   PATH is the appropriate path excluding the filename
%   IMGNUMS is a vector specifying the images to load from the set
%   BASENAME is the filename excluding the numeric prefix
%
%   The alternative [RGB ALPHA] syntax is only supported for filetypes
%   where IMREAD supports the similar syntax. (e.g. PNG files)
%   ALPHA is a MxNx1xF array for F images of MxN size so as to be
%   easily concatenated to form a 4-channel RGBA array if desired
%
%   BATCHLOADER is inflexible and cumbersome to use without it breaking. 
%   This tool is deprecated, but retained for compatibility with old scripts.
%   For general multifile image import, use MIMREAD and IMSTACKER instead.
%
%   See also: imread, mimread, imstacker

nout = max(nargout,1);

if nout == 1
    for n = 1:1:length(imgnums);
        outpict(:,:,:,n) = imread(fullfile(path,[sprintf('%02d',imgnums(n)) basename]));
    end
    varargout{1} = outpict;
elseif nout == 2
    for n = 1:1:length(imgnums);
        [outpict(:,:,:,n),~,alpha(:,:,1,n)] = imread(fullfile(path,[sprintf('%02d',imgnums(n)) basename]));
    end
    varargout{1} = outpict;
    varargout{2} = alpha;
end

return
