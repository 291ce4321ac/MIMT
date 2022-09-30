% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RECOVERING LOST 'BOMB' MODE TRANSFER FUNCTIONS

% So you used imblend() 'bomb' modes and found a random mesh that you really like
% but you weren't using the 'verbose' option, so now it's gone forever!

% Well don't worry (too much).  It can be back-calculated, but with limitations.
% Most images don't cover the function domain very completely, 
% so the result will only describe the function over a subset of its domain.

% This usually means that naive interpolation doesn't quite cut it.
% This routine starts out by estimating the mesh using scatteredInterpolant
% and then it tries to refine the mesh by crude parameter descent.
% It can take a while, but this isn't a task that should be commonplace.

% The initial and refined estimates will be printed to console in a usable form.
% The refined estimate will be used to generate an approximation of the original
% blended image.  Both will be presented using IMCOMPARE.

% We'll need the following things:

% add your input & output images here
BG = imcast(imread('sources/blacklight2.jpg'),'double');
FG = lingrad(size(BG),[0 0; 1 0],[1 1 1; 0 0 0],'linear',[0 1],'double');
R = imblend(FG,BG,0.8,'bomb',[2 4],'verbose'); % <-- R is being generated in this example, but your R should be a static image ...
%R = imcast(imread('myblendresult.jpg'),'double'); % <-- Like this, or from the workspace

% select parameters that were used to generate R from FG & BG
amount = [2 4];		% the value of AMOUNT used (default 1)
blendmode = 'bomb';	% 'bomb', 'bomblocked' or 'hardbomb'
opacity = 0.8;		% the opacity used (usually 1)

% we'll need to set up a few options for processing (these defaults should be fine)
s = [NaN 200];		% downscale the images to make processing faster
maxstep = 0.1;		% this sets the initial step size for refinement
stepfactor = 2;		% once the mesh becomes optimized for a given step, divide by this
tightenlimit = 1E5;	% the condition at which the search routine terminates (decrease for earlier termination)
est0only = false;		% set true to just get the initial unrefined estimate (fast, but probably not very good)

% 'bomblocked' will be handled as 'bomb', returning a 3-channel tf instead of a single-channel tf
% ideally, all 3 channels will be identical, but that's not typical. 
% if the image channels have different value distributions, each potentially not spanning the domain,
% then each channel of the estimated tf will consequently vary in accuracy -- just as happens with other modes.
% if the differences are significant, you can try to pick which channel is the best estimate
% otherwise, you can just use the 3-ch estimate or a dim3 average, etc

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
hardmode = strcmpi(blendmode,'hardbomb');
if hardmode; itp = 'nearest'; else itp = 'bilinear'; end
if opacity ~= 1
	Ro = (R+(opacity-1)*BG)/opacity;
else 
	Ro = R;
end
mBG = imresizeFB(double(BG),s,itp);
mFG = imresizeFB(double(FG),s,itp);
mR = imresizeFB(double(Ro),s,itp);

amount = max(1,round(amount));
if numel(amount) == 1
	cf = 0:1/amount:1;
	cb = cf;
elseif numel(amount) == 2
	cf = 0:1/amount(1):1;
	cb = 0:1/amount(2):1;
end

if strcmpi(blendmode,'bomblocked')
	blendmode = 'bomb'
end

nc = size(mR,3);
amtest = zeros([amount+1 nc]);
amtest0 = zeros([amount+1 nc]);

tic
for c = 1:nc
	rc = mR(:,:,c);
	fc = mFG(:,:,c);
	bc = mBG(:,:,c);
	x = linspace(0,1,amount(2)+1);
	y = linspace(0,1,amount(1)+1);
	[xq yq] = meshgrid(x,y);
	if hardmode
		FF = scatteredInterpolant(bc(:),fc(:),rc(:),'nearest');
	else
		FF = scatteredInterpolant(bc(:),fc(:),rc(:),'linear');
	end
	amtest0(:,:,c) = min(max(FF(xq,yq),0),1);

	wtf = min(max(amtest0(:,:,c),0),1);
	Re = imblend(mFG(:,:,c),mBG(:,:,c),1,'mesh',wtf);
	lasterr = sum(sum(abs(mR(:,:,c)-Re)));

	if ~est0only
		tighten = 1;
		nel = numel(wtf);
		while tighten < tightenlimit
			step = maxstep/tighten;
			changedthispass = false;
			for tfe = 1:nel
				thistf = wtf;
				thistf(tfe) = min(max(wtf(tfe)-step,0),1);
				if hardmode
					Re = imblend(mFG(:,:,c),mBG(:,:,c),1,'hardmesh',thistf);
				else
					Re = imblend(mFG(:,:,c),mBG(:,:,c),1,'mesh',thistf);
				end
				curerr = sum(sum(abs(mR(:,:,c)-Re)));
				if curerr < lasterr
					wtf = thistf;
					lasterr = curerr;
					fprintf('%g\n',lasterr)
					changedthispass = true;
				else
					thistf(tfe) = min(max(wtf(tfe)+step,0),1);
					if hardmode
						Re = imblend(mFG(:,:,c),mBG(:,:,c),1,'hardmesh',thistf);
					else
						Re = imblend(mFG(:,:,c),mBG(:,:,c),1,'mesh',thistf);
					end
					curerr = sum(sum(abs(mR(:,:,c)-Re)));
					if curerr < lasterr
						wtf = thistf;
						lasterr = curerr;
						fprintf('%g\n',lasterr)
						changedthispass = true;
					end
				end
			end
			if ~changedthispass
				tighten = tighten*stepfactor;
			end
		end
		amtest(:,:,c) = wtf;
	end
end
clc
toc

if est0only
	fprintf('initial: cat(3,%s,%s,%s)\n',mat2str(amtest0(:,:,1),3),mat2str(amtest0(:,:,2),3),mat2str(amtest0(:,:,3),3))
else
	disp('difference between initial and refined estimates')
	channames = {'R/I','G','B'};
	for c = 1:nc
		fprintf('%s:\t%s\n',channames{c},mat2str(abs(amtest(:,:,c)-amtest0(:,:,c)),3))
	end
	totalerror = sum(sum(sum(abs(amtest0-amtest))))
	
	fprintf('\ninitial: cat(3')
	for c = 1:nc
		fprintf(',%s',mat2str(amtest0(:,:,c),3))
	end
	fprintf(')\n')
	
	fprintf('refined: cat(3')
	for c = 1:nc
		fprintf(',%s',mat2str(amtest(:,:,c),3))
	end
	fprintf(')\n')
end

if hardmode
	imcompare('R','imblend(FG,BG,opacity,''hardmesh'',amtest)','invert')
else
	imcompare('R','imblend(FG,BG,opacity,''mesh'',amtest)','invert')
end







