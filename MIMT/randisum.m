function out = randisum(rrange,s,sz,varargin)
%  A = RANDISUM(RANGE,S,OUTSIZE,{DISTRIBUTION},{VARIANCE})
%  Generate an array of random integers with a specified sum.
% 
%  RANGE is the range of allowed output values, [RMIN RMAX]
%     If specified as a scalar, it will be interpreted as RMIN, and RMAX will be NaN. 
%     When using 'uniform' or 'exponential' modes, only one limit can be specified. 
%       (e.g. RMIN can be scalar or specified as [RMIN NaN]; RMAX can be [NaN RMAX]).
%       NaN values are treated such that boundaries are symmetric about the mean.
%     When using 'skew' mode, finite 2-term RANGE is supported. NaN values are treated 
%       such that boundaries are symmetric about the mean.
%     When using 'gaussian' mode, infinite 2-term RANGE is supported. NaN values are 
%       interpreted as infinite.
%  S is the specified sum
%  OUTSIZE is a vector specifying the size of the output array
%  DISTRIBUTION optionally specifies the distribution (default 'uniform')
%     'uniform' produces numbers which follow a uniform distribution symmetric about 
%         the mean dictated by S and OUTSIZE, with either boundary specified by RANGE.
%         In order to maintain uniformity, this mode cannot support RANGE asymmetry.
%     'skew' is related to 'uniform'.  When RMIN, RMAX are symmetric about the mean, 
%         the results are uniformly distributed.  As the boundaries deviate slightly from
%         this symmetric condition, the distribution is tilted to maintain the mean.
%     'gaussian' produces numbers which approximate a truncated normal distribution.
%         If RANGE is [-Inf Inf], the distribution is not truncated.  When RMIN, RMAX
%         are not equidistant from the mean, the peak of the distribution moves away
%         from the mean and toward the proximal boundary.
%     'exponential' produces numbers which follow an exponential distribution.  
%         This distribution is heavily weighted toward the specified boundary, decreasing
%         asymptotically in the direction of the mean and beyond. 
%  SIGMA optionally specifies the distribution shape when using the mode.
%     If unspecified, the default is 30% of the mean.  
%
%  Note that the constraint of S and OUTSIZE dictates that the mean is the same in 
%  all cases.  Since the global minimum of a set cannot be greater than the mean, 
%  RMIN must be less than or equal to the mean.  Similar holds true for RMAX.
%
%  In 'gaussian' mode, there is a further limitation when RMIN, RMAX are not equidistant 
%  from the mean.  In order to preserve the output mean, the peak of the distribution 
%  (the mean of the parent gaussian) must also lie within RANGE.  The proximal boundary 
%  can be no closer to the mean than the peak. For example, if RMAX = Inf, then RMIN can 
%  be no greater than MEAN - 0.8*SIGMA, though the calculation for this limit is not 
%  generally so simple.  If an excessively proximal boundary is specified, it will be clamped 
%  and a warning dumped to console.
%
%  Similarly, in 'skew' mode, the ratio of the distances between the distal and proximal
%  boundaries and the mean cannot be greater than 2.  Geometrically speaking, this is the
%  point at which the distribution has tilted so far that it is zero at the distal boundary.
%  Excessive specifications of the distal boundary will be clamped and produce a warning.
%
%  For similar parameters, 'uniform' is generally fastest, followed by the other modes.  
%  It's worth noting that the speed of the various options depends heavily on OUTSIZE, SIGMA, 
%  and the distance between boundaries and the mean.  
%
%  Example:
%     Subdivide a vector into 10 randomly-sized blocks
%     x = 1:100;
%     blocksizes = randisum(5,numel(x),[1 10]);
%     xc = mat2cell(x,1,blocksizes);
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/randisum.html
% See also: rand, randi, randrange

% i make no claims that these are particularly efficient, robust, or statistically meaningful 
% ways to solve this problem.  like much of MIMT, this is a collection of expedient kludges. 
% my own tolerance for these flaws is potentially higher than yours.

dmode = 'uniform';
defsig = 0.3;
sig = NaN;

if numel(varargin) > 0
	for k = 1:numel(varargin)
		thisarg = varargin{k};
		if isnumeric(thisarg)
			sig = thisarg;
		elseif ischar(thisarg)
			if strismember(thisarg,{'exponential','uniform','gaussian','skew'})
				dmode = thisarg;
			else
				error('RANDISUM: unknown distribution option %s',thisarg)
			end
		end
	end
end

s = round(s);
n = prod(sz);
mn = s/n; % this is common to all modes and cannot change

isgauss = strcmp(dmode,'gaussian');
isskew = strcmp(dmode,'skew');
if numel(rrange) == 1
	rmin = rrange(1);
	rmax = NaN;
elseif numel(rrange) >= 2
	rmax = rrange(2);
	rmin = rrange(1);
end
rmin = round(rmin);
rmax = round(rmax);

if ~isgauss && isinf(rmin)
	error('RANDISUM: RMIN can only be infinite in ''gaussian'' mode')
end

if ~isgauss && ~isskew && ~(isnan(rmin) || isnan(rmax))
	error('RANDISUM: ''uniform'' and ''exponential'' modes only support the specification of one boundary.')
end

if (rmin >= mn || rmax <= mn)
	% shortcut for trivial case
	out = ones(sz)*mn;
	if rmin > mn
		warning('RANDISUM: RMIN cannot be greater than the mean dictated by S and OUTSIZE.  Using this limiting value instead. RMIN <= %d/%d = %d',s,n,mn)
	end
	if rmax < mn
		warning('RANDISUM: RMAX cannot be less than the mean dictated by S and OUTSIZE.  Using this limiting value instead. RMAX >= %d/%d = %d',s,n,mn)
	end
	return;
end
		
switch dmode
	case 'uniform'
		% strict uniformity requires that boundaries are equidistant from the mean
		if isnan(rmin)
			rmin = 2*mn - rmax;
		elseif isnan(rmax)
			rmax = 2*mn - rmin;
		end
		a = getsample(n);
		adjustsum(); 
		
	case 'skew'
		% consider this to be a sloppy version of 'uniform' that will compromise uniformity if you ask it to (asymmetric boundaries)
		% i didn't want to use this as a generalized replacement for 'uniform'.  i figured that 'uniform' should stay strictly flat.
		% i don't doubt that the quantile functions could be simplified further.  this was good enough.
		if isnan(rmin)
			rmin = 2*mn - rmax;
		elseif isnan(rmax)
			rmax = 2*mn - rmin;
		end
		
		uh = rmax-mn;
		lh = mn-rmin;
		if lh < uh
			% proximal boundary is rmin; distribution is tilted down toward rmax
			if uh > 2*lh
				warning('RANDISUM: Distal boundary too far from mean.  Above MEAN + 2*(MEAN-RMIN), no results exist. Clamping RMAX at %d',3*mn-2*rmin)
				rmax = 3*mn-2*rmin;
			end
			A = @(x) sqrt(n*((8*mn^2 - 12*mn*rmin - 4*rmax*mn + 4*rmin^2 + 4*rmax*rmin)*x + n*mn^2 - 2*n*mn*rmax + n*rmax^2));
			invCDF = @(x) (2*(rmax^2 + rmax*rmin - mn*rmax + 2*rmin^2 - 3*mn*rmin))/(2*rmax - 4*mn + 2*rmin) ...
				- (n*rmax^2 + 2*n*rmin^2 + A(x)*(rmax - rmin) - mn*n*rmax - 3*mn*n*rmin + n*rmax*rmin)/(2*(n*rmax - 2*mn*n + n*rmin));
		elseif lh > uh
			% proximal boundary is rmax; distribution is tilted down toward rmin
			if lh > 2*uh
				warning('RANDISUM: Distal boundary too far from mean.  Below MEAN - 2*(RMAX-MEAN), no results exist. Clamping RMIN at %d',3*mn-2*rmax)
				rmax = 3*mn-2*rmax;
			end
			A = @(x) sqrt(n*((8*mn^2 - 12*mn*rmax - 4*rmin*mn + 4*rmax^2 + 4*rmin*rmax)*x + n*mn^2 - 2*n*mn*rmin + n*rmin^2));
			invCDF = @(x) - 2*mn - (8*mn^2*n + 2*n*rmax^2 + n*rmin^2 + A(x)*(rmax - rmin) ...
				- 7*mn*n*rmax - 5*mn*n*rmin + n*rmax*rmin)/(2*(n*rmax - 2*mn*n + n*rmin));
		else	
			% boundaries are symmetric; distribution is uniform
			% no special considerations
		end
		a = getsample(n);
		adjustsum(); 
		
	case 'exponential'
		% this is much faster (~100x) for larger sets (~1E6) than the elegant diff(sort(rand())) method found elsewhere
		% it uses much less memory, allowing the generation of larger arrays without blockwise operation
		if ~isnan(rmin)
			% proximal boundary is rmin; distribution decreaseas toward Inf
			lb = 1/(mn-rmin);
			invCDF = @(x) abs(-log(1-x)/lb)+rmin;
		else
			% proximal boundary is rmax; distribution decreases toward -Inf
			lb = 1/(rmax-mn);
			invCDF = @(x) -abs(-log(1-x)/lb)+rmax;
		end
		a = getsample(n);
		adjustsum(); 
					
	case 'gaussian'
		% general 1-sided or 2-sided truncated gaussian
		if isnan(sig)
			sig = defsig*mn;
		end
		
		if isnan(rmin); rmin = -Inf; end
		if isnan(rmax); rmax = Inf;	end

		lh = mn-rmin; % width of lower half
		uh = rmax-mn; % width of upper half
		
		CDF = @(x) 0.5*(1+erf(x/sqrt(2)));
		PDF = @(x) exp(-0.5*x^2)/sqrt(2*pi);
				
		if lh > uh
			% proximal boundary is rmax
			F0 = @(mu0) mu0 - mn - sig ...
				*(1/sqrt(2*pi)-PDF((rmin-mu0)/sig)) ...
				/(0.5-CDF((rmin-mu0)/sig));
			rmlim = ceil(fzero(F0,[mn mn+2*sig]))+1;

			if rmax < rmlim
				warning('RANDISUM: Proximal boundary too close to mean. The minimum allowable RMAX for the given parameters is %d.  Using this limiting value instead. See note in help synopsis.',rmlim)
				rmax = rmlim;
			end

			% back-calculate to find approximate mu0 (mean of parent gaussian)
			mu0est = fzero(@fmu0,[mn rmlim]);
		elseif lh < uh
			% proximal boundary is rmin
			F0 = @(mu0) mu0 - mn - sig ...
				*(PDF((rmax-mu0)/sig)-1/sqrt(2*pi)) ...
				/(CDF((rmax-mu0)/sig)-0.5);
			rmlim = floor(fzero(F0,[mn-2*sig mn]))-1;
			
			if rmin > rmlim
				warning('RANDISUM: Proximal boundary too close to mean. The maximum allowable RMIN for the given parameters is %d.  Using this limiting value instead. See note in help synopsis.',rmlim)
				rmin = rmlim;
			end

			% back-calculate to find approximate mu0 (mean of parent gaussian)
			mu0est = fzero(@fmu0,[rmlim mn]);
		else
			% distribution is symmetric
			mu0est = mn;
		end
		
		a = getsample(n);	
		adjustsum();
		
end

out = reshape(a,sz);

%histogram(a,'binmethod','integers')


% NESTED FUNCTIONS .....................................................

% this isn't a great way to do this, but it's better than what it was.
function adjustsum()
	a = shiftdistr(a); 
	if ~isinf(rmin) || ~isinf(rmax)
		while min(a(:)) < rmin || max(a(:)) > rmax % this could use loidx as an exit condition
			loidx = a < rmin | a > rmax;
			newnums = getsample(sum(loidx));

			repidx = newnums < rmin | newnums > rmax;
			nlo = sum(repidx);
			while nlo > 0
				replacements = getsample(nlo);
				newnums(repidx) = replacements;
				repidx = newnums < rmin | newnums > rmax;
				nlo = sum(repidx);
			end
			a(loidx) = newnums;

			a = shiftdistr(a); 
		end
	end
end


function x = shiftdistr(x)
	addthis = s-sum(x);
	while addthis ~= 0
		addhere = randi(n,abs(addthis),1); % list of candidate indices
		x(addhere) = x(addhere) + sign(addthis);
		addthis = s-sum(x);
	end
end


function out = getsample(numsamples)
	switch dmode
		case 'uniform'
			out = randi([ceil(rmin) floor(rmax)],numsamples,1);
		case 'gaussian'
			out = round(sig*randn(numsamples,1)+mu0est);
		case 'skew'
			if lh == uh
				out = randi([ceil(rmin) floor(rmax)],numsamples,1); 
			else
				out = round(invCDF(rand(numsamples,1)*n));
			end
		case 'exponential'
			out = round(invCDF(rand(numsamples,1)));
	end
end

function out = fmu0(mu0)
	% used for finding mu0est
	out = mu0 -mn - sig ...
		*(PDF((rmax-mu0)/sig)-PDF((rmin-mu0)/sig)) ...
		/(CDF((rmax-mu0)/sig)-CDF((rmin-mu0)/sig));
end


end % end main function scope





















