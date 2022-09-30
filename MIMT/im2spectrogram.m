function im2spectrogram(inpict,outpath,alteraspect,padbar,volume,blursize)
%   IM2SPECTROGRAM(INPICT, OUTPATH, {ALTERASPECT}, {PADBAR}, {VOLUME}, {BLURSIZE})
%       use inverse short-time Fourier transform to encode an image in audio spectra
%       Output is 44100 Hz 16-bit WAV
%
%   INPICT is a 2-D image.  If an RGB image is passed, its luma channel will be processed
%   OUTPATH is the path of the output .wav file
%   ALTERASPECT is a scaling parameter used to adjust the geometry of the image in the spectrogram.
%       This is necessary since scaling of spectrogram output in various viewers is pretty much arbitrary.
%       Pick something that works with whatever you use to view the audio output.  (default is 1)
%   PADBAR is used to add extra padding to the top (high-freq edge) of the image.  (default is 0)
%       Use this to keep image below mp3 cutoff if audio will be compressed (H=1+padwidth)
%   VOLUME specifies a gain for the output.  Clipping will occur beyond unity. (default is 1)
%   BLURSIZE optionally specifies the smoothing filter size (default 5)
%       Slight blurring helps reduce artifacts on sharp edges. Set to 0 for no blur.
%
% This function relies upon the STFT/ISTFT tools by Hristo Zhivomirov 
% http://www.mathworks.com/matlabcentral/fileexchange/45197-short-time-fourier-transformation--stft--with-matlab-implementation
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/im2spectrogram.html
% See also: text2spectrogram

if ~exist('blursize','var')
    blursize = 5; % radius, amount for gaussian kernel
end

if ~exist('volume','var')
    volume = 1;
end

if ~exist('alteraspect','var')
    alteraspect = 1;
end

if ~exist('padbar','var')
    padbar = 0;
end

% desaturate color images (choose method if desired)
if (ndims(inpict) == 3); 
    inpict = mono(inpict,'y');
end

inpict = flipud(inpict);      % flip image (low-f on bottom)
inpict = imadjustFB(inpict);    % set image contrast

magicnum = 660;       
inaspect = length(inpict(1,:))/length(inpict(:,1));
inpict = padarrayFB(inpict,[round(padbar*length(inpict(:,1))) 0],'post'); 
inpict = imresizeFB(inpict,magicnum*[1 alteraspect*inaspect/(1+padbar)]);

if (blursize > 0);
    h = fkgen('gaussian', blursize);
    inpict = imfilterFB(inpict,h);
end

nft = length(inpict(:,1))*2-2;
h = nft; 
samplefreq = 44100;
[x,~] = istft(inpict,h,nft,samplefreq);

xp = x/(max(abs(x))*1.0001)*volume;
if verLessThan('matlab','8')
	wavwrite(xp, samplefreq, 16, outpath);
else
	audiowrite(outpath, xp, samplefreq, 'bitspersample', 16);
end

return






