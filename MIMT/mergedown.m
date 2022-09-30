function outpict = mergedown(inpict,varargin)
%   MERGEDOWN(INPICT, OPACITY, BLENDMODE, {...})
%   MERGEDOWN(INPICT, ICP)
%       performs image blending on dim 4 of a 4-D imageset
%       output is a single-frame image
%   
%   INPICT is a 4-D image set of any type supported by IMBLEND
%   Remaining arguments (OPACITY, BLENDMODE, etc) are any appropriate arguments
%   accepted by IMBLEND
%   ICP is an ICP object which corresponds to INPICT
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/mergedown.html   
% See also: imblend, imcompose, icparams

% this does not process modify field from ICP
% imcompose does odd shit with 'other' blendmode handling

nframes = size(inpict,4);
[cc ac] = chancount(inpict);
hasalpha = logical(ac);

ismultispec = false;
if strcmp(class(varargin{1}),'icparams') %#ok<STISA>
	ismultispec = true;
	thisicp = varargin{1};
	errlist = thisicp.verifyicp(nframes);
	if ~isempty(errlist)
		error('MERGEDOWN: ICP object does not match image length: \n\n%s',errlist)
	end
else
	if numel(varargin) < 2
		error('MERGEDOWN: Not enough input arguments.')
	end
end

if ismultispec
	% process multi-spec
	
	% find highest opaque layer and compose up from there
	% this avoids composing buried layers for no reason
	baselayer = nframes;
	for f = 1:1:nframes
		bmode = thisicp.blendmode{f}
		cmode = thisicp.compmode{f}
		hidden = thisicp.flags{f}(1);
		noalpha = thisicp.flags{f}(2);
		
		isopaqueblend = (strcmp(bmode,'normal') && thisicp.opacity{f} == 1 && ~hidden);
		solidalpha = ((hasalpha && (~any(any(imcast(inpict(:,:,end,f),'double') ~= 1)) || noalpha == 1)) || ~hasalpha);
		isopaquecomp = ismember(cmode,{'gimp','srcover'});
		
		if isopaqueblend && solidalpha && isopaquecomp
			baselayer = f;
			break;
		end
	end
	
	% how to adapt from imcompose? preprocess first? process inline?
	firstframe = true;
	for f = baselayer:-1:1
		if hidden(f) ~= 1 
			fg = preprocessed(:,:,:,f);
			if firstframe
				bg = fg;
				firstframe = false;
			else
				bg = imblend(fg,bg,opacity(f),thismode,amount{f},thiscmode,camount{f});
			end
		end
	end
	
	% original multispec method to be replaced or adapted
	outpict = inpict(:,:,:,nframes);
	for f = nframes-1:-1:1
		fullframeparams = thisicp.geticpframe(f);
		thisvargin = fullframeparams(1:5);
		flags = fullframeparams{7};
		
		if ~flags(1) % not hidden
			if flags(2) % strip alpha
				outpict = imblend(inpict(:,:,1:cc,f),outpict,thisvargin{:});
			else
				outpict = imblend(inpict(:,:,:,f),outpict,thisvargin{:});
			end
		end
	end
else 
	% process single-spec
	outpict = inpict(:,:,:,nframes);
	for f = nframes-1:-1:1
		outpict = imblend(inpict(:,:,:,f),outpict,varargin{:});
	end
end

end

