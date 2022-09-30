classdef icparams
% ICPARAMS
% Class for image composition parameter (ICP) objects.  This is intended for eventual use 
% in IMCOMPOSE and MERGEDOWN to allow a standardized method of storing composition setups.
%
% This is all rather half-baked.  For sake of convenience in handling the referent image, the 
% ICP object does not contain the image array.  There is no internal mechanism to ensure 
% correspondence between the image and the ICP object or between the fields within the ICP object.
% Careless editing can break things.
%
% Parameter fields correspond to parameters for IMBLEND and IMCOMPOSE
%   IMBLEND parameters:
%      'opacity', 'blendmode', 'amount', 'compmode', 'camount' are specified per-frame
%      'keys' are specified once for the entire composition
%   IMCOMPOSE parameters:
%      'modifier' is a modifier command string (e.g. imtweak(@layer,''lchab'',[1 1 0.25]))
%      'flags' is a vector of numeric flags for visibility settings [hidden disablealpha]
% 
% METHODS:
%    Constructor:
%       obj=icparams(numframes)
%       generates an ICP object populated with default values
%       EX: 
%          >> exampleicp=icparams(3)
%          exampleicp = 
%            icparams with properties:
%              numframes: 3
%                opacity: {3x1 cell}
%              blendmode: {3x1 cell}
%                 amount: {3x1 cell}
%               compmode: {3x1 cell}
%                camount: {3x1 cell}
%                   keys: {}
%               modifier: {3x1 cell}
%				   flags: {3x1 cell}
%
%    Get params for frame or frame range:
%       paramarray=geticpframe(obj,whichframes)
%       PARAMARRAY is a cell array, where each row vector corresponds to a single frame
%       EX: 
%          >> exampleicp.geticpframe(2)
%          ans = 
%              [1]    'normal'    [1]    'gimp'    [1]    ''    [0 0]
%
%    Set params for frame or frame range:
%       obj=seticpframe(obj,whichframes,paramarray)
%       WHICHFRAMES may be a scalar or vector of frame indices
%       PARAMARRAY is a cell array, where each row vector corresponds to a single frame
%       PARAMARRAY may be underspecified on dim 2
%       EX: 
%          >> exampleicp=exampleicp.seticpframe(2,{0.5,'overlay',1.5}); 
%          >> exampleicp.geticpframe(2)
%          ans = 
%              [0.5000]    'overlay'    [1.5000]    'gimp'    [1]    ''    [0 0]
%
%    Set a parameter field for all frames:
%       obj=seticpfield(obj,whichfield,paramarray)
%       This can be done other ways, but using this method allows for expansion of underdefined inputs.
%       WHICHFIELD is one of the following field names:
%          'opacity','blendmode','amount','compmode','camount','keys','modifier','flags'
%       A fully-defined specification for PARAMARRAY is a cell array of length equal to numframes.
%       When underdefined, if PARAMARRAY is numeric or a string, it will be expanded to apply to all frames.
%       For appropriate numeric fields, PARAMARRAY may be specified as a 2-element cell array of scalar values.
%          This will be interpreted as a range, and will be expanded as a linear sequence.
%       EX: 
%          >> exampleicp=exampleicp.seticpfield('opacity',0.5); 
%          >> exampleicp.opacity
%          ans = 
%             [0.5000]
%             [0.5000]
%             [0.5000]
%          >> exampleicp=exampleicp.seticpfield('opacity',{0.1,1}); 
%          >> exampleicp.opacity
%          ans = 
%             [0.1000]
%             [0.5500]
%             [     1]
%          >> exampleicp=exampleicp.seticpfield('opacity',{0.75,0.3,1}); 
%          >> exampleicp.opacity
%          ans = 
%             [0.7500]
%             [0.3000]
%             [     1]
%
%    Insert new frames:
%       obj=inserticpframe(obj,whichframe,numnewframes)
%       obj=inserticpframe(obj,whichframe,paramarray)
%       Insert a single frame or a group of consecutive frames with either default or specified parameters
%       WHICHFRAME is the frame after which to insert the new frame (range: [0:numframes])
%       NUMNEWFRAMES is the number of consecutive default frames to insert
%       PARAMARRAY is a cell array, where each row vector corresponds to a single frame
%       PARAMARRAY may be underspecified on dim 2
%       EX: prepend two frames using an underdefined PARAMARRAY
%          >> exampleicp=exampleicp.inserticpframe(0,{0.5,'near',0.1; 0.75,'far',0.05});
%
%    Remove frames:
%       obj=removeicpframe(obj,whichframe)
%       WHICHFRAME is the frame(s) to remove (may be non-consecutive)
%       EX: remove first and third frames
%          >> exampleicp=exampleicp.removeicpframe([1 3]);
%
%    Check ICP consistency or ICP/image correspondence:
%       errorlist=verifyicp(obj)
%       errorlist=verifyicp(obj,expectednumframes)
%       EXPECTEDNUMFRAMES is the number of frames expected (e.g. based on the number of frames in an image)
%       if not specified, the ICP object is checked against its own framecount (obj.numframes)
%       This is all a consequence of the fact that nothing ensures correspondence between an image and its ICP object.
%       Also, careless direct editing of the ICP object can result in mismatched field lengths.
%       If all per-frame fields match the expected number of frames, an empty string will be returned.
%       If mismatches exist, a multiline table of the inconsistencies will be returned.
%       EX: intentionally break correspondence and then observe the test results:
%          >> exampleicp.blendmode=exampleicp.blendmode(1:2);
%          >> exampleicp.verifyicp
%          ans =
%          Expected 3 frames
%          The following fields have unexpected length:
%            blendmode   2
%
%  See also: imblend imcompose mergedown



% is all this shit necessary? 
% why not just use a numframesx5 cell array?
% this approach allows a default constructor and use of keys
% and the use of named fields is more descriptive than the implicit structure of a large cell array
% if a numframesx5 cell array is desired, it can simply be extracted using geticpframes

% i still don't like the way i'm approaching this
% setter/getter access is going to be slower
% it's well-revealed, but cumbersome and multiple access methods are confusing
% what if i want to do something like obj.seticp(framenumber,fieldname,value);
% what if i want to access all params for a given frame?
% what if i want to access the entirety of a single param field?
% perhaps support different arg structures:
% obj.seticp(frame,fieldname,value);			<- generic base function to call others
% obj.seticp(frames,fieldname,paramcellvec);	<- this is a bad idea
% obj.seticp(frames,paramcellarray);			<- corresponds to seticpframe
% obj.seticp(fieldname,paramcellarray);			<- corresponds to seticpfield

% but that first use case is trivial! why not just access directly for single parameter assignments?
% obj.fieldname(frame)={value};

% should i give a shit about all these access methods?
% if everything is accessed via getter/setter functs
% why can't the data be stored in a single cell array for speed?
% what about storing modifier strings? visibility? noalpha?
% opacity doesn't need to be a cell array
% amount does; camount doesn't, but it might in the future.
% imcompose uses cell for everything but opacity.  
% it actually stores modes by index, complicating import of literal mode field data

% what dimension should fields be arranged along?
% how should get/set cell array inputs be handled? swapping orientation is confusing
% it's convenient to handle frame paramvecs as rows
% it might be best to arrange fields as column vecs

% should we even bother with expansion of range inputs? they're simple to use otherwise, and the extra case is confusing

% similar variable names are used differently in different functions.  this is retarded and confusing

% this needs a method to verify vector lengths against either internal or external framecount

	properties
		numframes
		% imblend params
		opacity
		blendmode
		amount
		compmode
		camount
		keys
		% imcompose params
		modifier
		flags
	end

	methods
		function obj = icparams(numframes)
			if ~exist('numframes','var')
				numframes = 1;
			end
			obj.numframes = numframes;
			obj.opacity = repmat({1},[numframes 1]);
			obj.blendmode = repmat({'normal'},[numframes 1]);
			obj.amount = repmat({1},[numframes 1]);
			obj.compmode = repmat({'gimp'},[numframes 1]);
			obj.camount = repmat({1},[numframes 1]);
			obj.keys = {};
			obj.modifier = repmat({''},[numframes 1]);
			obj.flags = repmat({[0 0]},[numframes 1]);
		end
		
		function paramvec = geticpframe(obj,whichframes)
			% get parameter vec as cell array
			% each row vector corresponds to a single frame
			nf = numel(whichframes);
			paramvec = cell([nf 7]);
			paramvec(:,1) = obj.opacity(whichframes);
			paramvec(:,2) = obj.blendmode(whichframes);
			paramvec(:,3) = obj.amount(whichframes);
			paramvec(:,4) = obj.compmode(whichframes);
			paramvec(:,5) = obj.camount(whichframes);
			paramvec(:,6) = obj.modifier(whichframes);
			paramvec(:,7) = obj.flags(whichframes);
		end
		
		function obj = seticpframe(obj,whichframes,paramvec)
			% set parameter vec as cell array
			% each row vector corresponds to a single frame
			% accepts partial specification
			if any(whichframes > obj.numframes)
				% call frame inserter
				obj = inserticpframe(obj.numframes,max(whichframes)-obj.numframes);
			end
			
			nf = numel(whichframes);
			for fidx = 1:nf
				f = whichframes(fidx);
				pveclen = size(paramvec,2);
				obj.opacity(f) = paramvec(fidx,1);
				if pveclen >= 2, obj.blendmode(f) = paramvec(fidx,2); end
				if pveclen >= 3, obj.amount(f) = paramvec(fidx,3); end
				if pveclen >= 4, obj.compmode(f) = paramvec(fidx,4); end
				if pveclen >= 5, obj.camount(f) = paramvec(fidx,5); end
				if pveclen >= 6, obj.modifier(f) = paramvec(fidx,6); end
				if pveclen >= 7, obj.flags(f) = paramvec(fidx,7); end
			end
		end

		function obj = seticpfield(obj,whichfield,paramvec)
			validfieldstrings = {'opacity','blendmode','amount','compmode','camount','keys','modifier','flags'};
			whichfield = lower(whichfield);
			if ~ismember(whichfield,validfieldstrings)
				error('SETICPFIELD: unknown field name %s',whichfield);
			end
			
			if strcmp(whichfield,'keys')
				% setter for keys
				validkeystrings = {'rec601' 'rec709' 'hsy' 'ypbpr' 'quiet' 'verbose'};
				if ischar(paramvec)
					if ismember(paramvec,validkeystrings)
						paramvec = {paramvec};
					else
						error('SETICPFIELD: invalid values specified for ''keys'' field \nvalid keys are: ''rec601'' ''rec709'' ''hsy'' ''ypbpr'' ''quiet'' ''verbose''')
					end
				elseif iscell(paramvec)
					if ~all(ismember(paramvec,validkeystrings))
						error('SETICPFIELD: invalid values specified for ''keys'' field \nvalid keys are: ''rec601'' ''rec709'' ''hsy'' ''ypbpr'' ''quiet'' ''verbose''')
					end
				end
			else
				if iscell(paramvec)
					if numel(paramvec) == obj.numframes
						% explicit multi-spec
						paramvec = reshape(paramvec,obj.numframes,1);
					elseif numel(paramvec) == 2 && ismember(whichfield,{'opacity','amount','camount'})
						% multi-spec by range expansion (numeric fields only)
						paramvec = num2cell(linspace(paramvec{1},paramvec{2},obj.numframes)');
					else
						error('SETICPFIELD: length of parameter array does not match number of image frames')
					end
				else
					% single-spec
					paramvec = repmat({paramvec},[obj.numframes 1]);
				end
			end
			
			switch whichfield
				case 'opacity'
					obj.opacity = paramvec;
				case 'blendmode'
					obj.blendmode = paramvec;	
				case 'amount'
					obj.amount = paramvec;
				case 'compmode'
					obj.compmode = paramvec;
				case 'camount'
					obj.camount = paramvec;
				case 'keys'
					obj.keys = paramvec;
				case 'modifier'
					obj.modifier = paramvec;	
				case 'flags'
					obj.flags = paramvec;	
			end
		end
		
		% this is kind of redundant and confusing (deleteable)
% 		function obj=seticp(obj,varargin)
% 			% obj.seticp(frame,fieldname,value,fieldname,value);	<- generic base function to call others
% 			% obj.seticp(frames,paramcellarray);					<- corresponds to seticpframe
% 			% obj.seticp(fieldname,paramcellarray);					<- corresponds to seticpfield
% 			
% 			if isnumeric(varargin{1}) && iscell(varargin{2})
% 				% if setting by frames only
% 				obj=seticpframe(obj,varargin{:});
% 			elseif ischar(varargin{1})
% 				% if setting by fieldonly
% 				obj=seticpfield(obj,varargin{:});
% 			else
% 				% if setting individual fields for a single frame
% 			end
% 		end
		
		function obj = inserticpframe(obj,whichframe,numnewframes)
			% insert frames after whichframe (0:numframes)
			% numnewframes may be underdefined parameter cell array for population
			if ~exist('numnewframes','var')
				numnewframes = 1;
			end
			
			if iscell(numnewframes)
				thisparamvec = repmat({1,'normal',1,'gimp',1,'',[0 0]},[size(numnewframes,1) 1]);
				thisparamvec(:,1:size(numnewframes,2)) = numnewframes;
				numnewframes = size(numnewframes,1);
			else
				thisparamvec = repmat({1,'normal',1,'gimp',1,'',[0 0]},[numnewframes 1]);
			end
			
			obj.numframes = obj.numframes+numnewframes;
			if whichframe == 0				
				obj.opacity = [thisparamvec(:,1); obj.opacity((whichframe+1):end)];
				obj.blendmode = [thisparamvec(:,2); obj.blendmode((whichframe+1):end)];
				obj.amount = [thisparamvec(:,3); obj.amount((whichframe+1):end)];
				obj.compmode = [thisparamvec(:,4); obj.compmode((whichframe+1):end)];
				obj.camount = [thisparamvec(:,5); obj.camount((whichframe+1):end)];
				obj.modifier = [thisparamvec(:,6); obj.modifier((whichframe+1):end)];
				obj.flags = [thisparamvec(:,7); obj.flags((whichframe+1):end)];
			else
				obj.opacity = [obj.opacity((1:whichframe)); thisparamvec(:,1); obj.opacity((whichframe+1):end)];
				obj.blendmode = [obj.blendmode((1:whichframe)); thisparamvec(:,2); obj.blendmode((whichframe+1):end)];
				obj.amount = [obj.amount((1:whichframe)); thisparamvec(:,3); obj.amount((whichframe+1):end)];
				obj.compmode = [obj.compmode((1:whichframe)); thisparamvec(:,4); obj.compmode((whichframe+1):end)];
				obj.camount = [obj.camount((1:whichframe)); thisparamvec(:,5); obj.camount((whichframe+1):end)];
				obj.modifier = [obj.modifier((1:whichframe)); thisparamvec(:,6); obj.modifier((whichframe+1):end)];
				obj.flags = [obj.flags((1:whichframe)); thisparamvec(:,7); obj.flags((whichframe+1):end)];
			end
		end
		
		function obj = removeicpframe(obj,whichframe)
			% remove frame(s)
			% may remove non-consecutive frames
			whichframe = whichframe(ismember(whichframe,1:obj.numframes));
			nf = numel(whichframe);
			
			allframes = 1:obj.numframes;
			keptframes = allframes(~ismember(allframes,whichframe))
			
			obj.opacity = obj.opacity(keptframes);
			obj.blendmode = obj.blendmode(keptframes);
			obj.amount = obj.amount(keptframes);
			obj.compmode = obj.compmode(keptframes);
			obj.camount = obj.camount(keptframes);
			obj.modifier = obj.modifier(keptframes);
			obj.flags = obj.flags(keptframes);
					
			obj.numframes = obj.numframes-nf;
		end
		
		function errlist = verifyicp(obj,expectednf)
			if ~exist('expectednf','var')
				expectednf = obj.numframes;
			end
			
			errlist = '';
			if numel(obj.opacity) ~= expectednf
				errlist = [errlist sprintf('  opacity\t%d\n',numel(obj.opacity))];
			end
			if numel(obj.blendmode) ~= expectednf
				errlist = [errlist sprintf('  blendmode\t%d\n',numel(obj.blendmode))];
			end
			if numel(obj.amount) ~= expectednf
				errlist = [errlist sprintf('  amount\t%d\n',numel(obj.amount))];
			end
			if numel(obj.compmode) ~= expectednf
				errlist = [errlist sprintf('  compmode\t%d\n',numel(obj.compmode))];
			end
			if numel(obj.camount) ~= expectednf
				errlist = [errlist sprintf('  camount\t%d\n',numel(obj.camount))];
			end
			if numel(obj.modifier) ~= expectednf
				errlist = [errlist sprintf('  modifier\t%d\n',numel(obj.modifier))];
			end
			if numel(obj.flags) ~= expectednf
				errlist = [errlist sprintf('  flags\t\t%d\n',numel(obj.flags))];
			end
			if ~isempty(errlist)
				errlist = [sprintf('Expected %d frames\nThe following fields have unexpected length:\n',expectednf) errlist];
			end
		end
	end





end














