function outpict = imappmat(inpict,mat,varargin)
%   OUTPICT=IMAPPMAT(INPICT,MAT,{OUTOFFSET},{INOFFSET},{OUTCLASS})
%   Apply a color transformation matrix to an image, similar to IPT imapplymatrix().
%
%   INPICT is an image array of any standard image class; 4D images are not supported.
%   MAT is a matrix of size C0xCI where CI matches to the number of channels in INPICT
%       and CO defines the number of channels in OUTPICT.
%   INOFFSET is a vector with length CI.  If scalar, it will be expanded.
%   OUTOFFSET is a vector with length CO.  If scalar, it will be expanded.
%   OUTCLASS optionally specifies the output class.  By default, output class is inherited 
%       from INPICT.  Otherwise, any one of the standard image class names may be used.
%   
%   Consider an image INPICT composed of the channels Rin, Gin, and Bin
%   For MAT=[A B C; D E F; G H I], INOFFSET=[IOS1 IOS2 IOS3], OUTOFFSET=[OOS1 OOS2 OOS3]:  
%   OUTPICT(:,:,1) = A*(Rin + IOS1) + B*(Gin + IOS2) + C*(Bin + IOS3) + OOS1
%   OUTPICT(:,:,2) = D*(Rin + IOS1) + E*(Gin + IOS2) + F*(Bin + IOS3) + OOS2
%   OUTPICT(:,:,3) = G*(Rin + IOS1) + H*(Gin + IOS2) + I*(Bin + IOS3) + OOS3
%
%   By default, imappmat() expects MAT and OFFSET to be normalized regardless of input/output class.  
%   Explicit output class specification will result in an image correctly scaled to match the 
%   specified output class.  This is the behavior regardless of the presence of IPT.
%
%   This behavior differs significantly from that of IPT imapplymatrix.  The IPT tool always
%   expects OFFSET to be scaled to match the white value implied by the class of INPICT.  If
%   OUTCLASS is specified, then MAT must also be scaled to match the white value of INPICT.  
%   When OUTCLASS is specified, imapplymatrix will return an improperly-scaled image if OUTCLASS
%   does not match the input class, since it only casts the output without correctly scaling it.
%   If it is desired to adopt this loose approach to casting, use the optional key 'iptmode'.
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imappmat.html
% See also: imapplymatrix, imlincomb, gettfm


inclass = class(inpict);
s0 = imsize(inpict);
sm = imsize(mat,2);
inoffset = zeros([1 sm(2)]);
outoffset = zeros([1 sm(1)]);
outclass = [];
iptmode = false;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			if k == 1
				outoffset = thisarg;
			elseif k == 2
				inoffset = thisarg;
			end
		elseif ischar(thisarg)
			if strismember(thisarg,{'double','single','uint8','uint16','int16','logical'});
				outclass = thisarg;
			elseif strcmpi(thisarg,'iptmode')
				iptmode = true;
			end
		end			
	end
end

if isscalar(inoffset)
	outoffset = repmat(inoffset,[1 sm(2)]);
end
if isscalar(outoffset)
	outoffset = repmat(outoffset,[1 sm(1)]);
end

if isempty(outclass)
	outclass = inclass;
end
changeclass = ~strcmp(inclass,outclass);

if s0(3) ~= sm(2)
	error('IMAPPMAT: dim2 of MAT must match dim3 of INPICT')
end
if length(inoffset) ~= sm(2)
	error('IMAPPMAT: length of INOFFSET must match dim2 of MAT')
end
if length(outoffset) ~= sm(1)
	error('IMAPPMAT: length of OUTOFFSET must match dim1 of MAT')
end

if ~all(inoffset == 0)
	offset = reshape(inoffset,1,[])*mat.' + reshape(outoffset,1,[]);
else
	offset = outoffset;
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% IF IPT IS INSTALLED
if license('test', 'image_toolbox') && ifversion('>=','R2011b')
	if iptmode
		outpict = imapplymatrix(mat,inpict,offset,outclass);
	else
		if changeclass
			inpict = imcast(inpict,'double');
			outpict = imapplymatrix(mat,inpict,offset);
			outpict = imcast(outpict,outclass);
		else
			% even if class doesn't change, IAM still rescales OFFSET
			offset = imrescale(offset,inclass,'double');
			outpict = imapplymatrix(mat,inpict,offset);
		end
	end
	return;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iptmode
	inpict = double(inpict);
else
	inpict = imcast(inpict,'double');
end

% IPT tool uses mex helper, with about a 2:1 to 4:1 speed advantage depending on MAT size
% trying to avoid bsxfun and doing columnwise lincomb makes it 11:1
% using implicit expansion in R2016b+ isn't really any faster than bsxfun
mat = permute(mat,[1 3 2]);

outpict = zeros([s0(1:2) sm(1)]);
for c = 1:size(mat,1)
	outpict(:,:,c) = sum(bsxfun(@times,inpict,mat(c,:,:)),3) + offset(c);
end

if iptmode
	outpict = cast(outpict,outclass);
else
	outpict = imcast(outpict,outclass);
end



