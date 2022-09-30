function varargout = gettfm(mat,varargin)
%  A = GETTFM(MODEL,{SPEC})
%  [A OFFSET] = GETTFM(MODEL,{SPEC})
%    Generate the color transformation matrix for conversion
%    between RGB and various luma-chroma models.  Transformation 
%    matrices are calculated from scratch and are not truncated.
%
%  MODEL specifies the luma-chroma model. Supported values are:
%    'ypbpr'        component analog video
%    'ycbcr'        component digital video
%    'ycbcr8'       same, but for uint8-scale inputs
%    'ycocg'        exactly invertible 
%    'ycocgr'       requires less bit depth for invertibility
%    'yuv'          PAL video
%    'yiq'          NTSC video
%    'ydbdr'        SECAM video
%    'y' or 'luma'  luma only
%    The inverse transformation matrix can be obtained by appending
%    '_inv' to the model name.
%  SPEC specifies the luma constants
%    'rec470' or '470' for ITU-R BT470
%    'rec601' or '601' for ITU-R BT601
%    'rec709' or '709' for ITU-R BT709
%    'rec2020' or '2020' for ITU-R BT2020
%    Due to inheritance, 470 and 601 constants are identical
%
%  Conversion to/from YCbCr requires both transformation and offset.
%  A second output argument may be used to get the offset vector.
%
%  Model 'ycbcr' will return a matrix scaled for multiplication with
%  unit-scale ([0 1]) data, whereas 'ycbcr8' will return a matrix
%  scaled for multiplication with uint8-scale ([0 255]) data.  
%  The result of either multiplication will be uint8-scale YCbCr.
%
%  YCoCg modes do not use default or user-specified luma constants.
%  The output of these modes does not provide any additional offset
%  or scaling information.  If you want your forward transformation
%  to result in an integer-valued YCC image (e.g. so that it can be
%  cast to an integer class without loss), see the webdocs.
%
% EXAMPLES:
%  Simply extract luma
%    ypict = imappmat(im2double(inpict),gettfm('luma','rec709'));
% 
%  Do full RGB -> YUV -> RGB conversion
%    yuvpict = imappmat(im2double(inpict),gettfm('yuv'));
%    rgbpict = imappmat(yuvpict,gettfm('yuv_inv'));
%
%  Do full RGB -> YCbCr -> RGB conversion using 'ycbcr'
%  In this case, both inpict and rgbpict are floating-point, scaled [0 1]
%    [A os] = gettfm('ycbcr');
%    yccpict = imappmat(inpict,A,os,'uint8','iptmode');
%    rgbpict = imappmat(yccpict,inv(A),0,-os,'double','iptmode');
%
%  Do the same using 'ycbcr8'
%  In this case, both inpict and rgbpict are uint8, scaled [0 255]
%    [A os] = gettfm('ycbcr8');
%    yccpict = imappmat(inpict,A,os,'uint8','iptmode');
%    rgbpict = imappmat(yccpict,inv(A),0,-os,'uint8','iptmode');
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/gettfm.html
% See also: imappmat, imapplymatrix, imlincomb

A = [];
rec = '601';
if numel(varargin)>0
	if ischar(varargin{1})
		rec = varargin{1};
	end
end

mat = regexprep(lower(mat),'[-_\s]','');
smat = numel(mat);
mat = regexprep(mat,'inv[a-z]*','');
invmat = numel(mat) ~= smat;

if strismember(mat,{'ycocg','ycocgr'})
	processycocg();
else
	processyxx();
end

% nargoutchk syntax changed at some unknown prior version. 
% since release notes are some sort of magical treasure which must be hidden away
% i have no way of knowing when to conditionally change it
% and legacy syntax support will be removed at some unknown future version anyway
% so why tf would i even use it at all?  
% this bs is what i get for daring a modicum of validation with the recommended tools
if nargout > 2
	error('Too many output arguments')
end

varargout{1} = A;
if nargout == 2
	if strismember(mat,{'ycbcr','ycbcr8'})
		os = [16; 128; 128]; % offset
		varargout{2} = os;
	else
		varargout{2} = [];
	end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processycocg()
	switch mat
		case 'ycocg'
			% if input is integer-valued
			% multiply A by [4; 2; 4] for integer-valued output
			A = [0.25 0.5 0.25; 0.5 0 -0.5; -0.25 0.5 -0.25];
		case 'ycocgr'
			% multiply by [4; 1; 2] for integer-valued output
			A = [0.25 0.5 0.25; 1 0 -1; -0.5 1 -0.5];
	end
	if invmat
		A = inv(A); % these actually invert exactly
	end
end

function processyxx()
	% get luma weights
	if ~isempty(regexp(rec,'(470|601)','start'))
		Ay = [0.299 0.587 0.114];
	elseif ~isempty(strfind(rec,'709')) %#ok<STREMP>
		Ay = [0.2126 0.7152 0.0722];
	elseif ~isempty(strfind(rec,'2020')) %#ok<STREMP>
		Ay = [0.2627 0.6780 0.0593];
	else
		error('GETTFM: unknown spec ''%s''',rec)
	end


	% short vector-only case
	if strismember(mat,{'luma','y'})
		A = Ay;
	else
		% get axis extents
		switch mat
			case {'ypbpr','ycbcr','ycbcr8'}
				crmx = 0.5;
				cbmx = 0.5;
			case {'yuv','yiq'}
				crmx = 0.436;
				cbmx = 0.615;
			case 'ydbdr'
				crmx = 1.333;
				cbmx = -1.333;
			otherwise
				error('GETTFM: unknown transform ''%s''',mat)
		end	

		Ab = crmx/(1-Ay(3))*([0 0 1]-Ay); % coefficients for U,Db,Pb,Cb
		Ar = cbmx/(1-Ay(1))*([1 0 0]-Ay); % coefficients for V,Dr,Pr,Cb

		if strcmpi(mat,'yiq')
			th = 33;
			Ai = -sind(th)*Ab + cosd(th)*Ar;
			Aq = cosd(th)*Ab + sind(th)*Ar;
			A = [Ay; Ai; Aq];
		else
			A = [Ay; Ab; Ar];
		end

		if strcmp(mat,'ycbcr')
			A = bsxfun(@times,A,[219; 224; 224]); % scaling for [0 1] inputs
		elseif strcmp(mat,'ycbcr8')
			A = bsxfun(@times,A,[219; 224; 224]/255); % scaling for [0 255] inputs
		end

		if invmat
			A = inv(A);
			A(abs(A-1)<1E-6) = 1;
			A(abs(A)<1E-6) = 0;
		end
	end
end



end % END MAIN SCOPE





