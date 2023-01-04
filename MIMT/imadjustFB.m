function outpict = imadjustFB(inpict,inrange,outrange,gamma)
%   outpict=imadjustFB(inpict,{inrange},{outrange},{gamma})
%      passthrough to imadjust() with internal fallback
%      for systems without IPT installed.  
%
%   Not all features are available in the fallback implementation
%   IPT methods exploit precompiled private functions and are much faster
%      
%   imadjustFB(inpict) is equivalent to imadjust(inpict,stretchlim(inpict))
%
%   inrange is either a 2-element vector (default [0 1])
%       or a 2x3 matrix where each column specifies channel limits for RGB
%   outrange is a 2-element vector (default [0 1])
%   gamma is a scalar (default 1)
%   
%   specifying inrange or outrange as [] will select default values
%
%   fallback method does not work for indexed images
%
%  See also: stretchlimFB, imlnc, imlnclite, imcurves, imbcg, immodify

automode = nargin == 1;

if ~exist('inrange','var');	inrange = [0 1]; end
if ~exist('outrange','var'); outrange = [0 1]; end	
if ~exist('gamma','var'); gamma = 1; end	

if isempty(inrange); inrange = [0 1]; end
if isempty(outrange); outrange = [0 1]; end

inrange = imclamp(inrange);
outrange = imclamp(outrange);

% IF IPT IS INSTALLED
if license('test', 'image_toolbox')
	if automode
		inrange = stretchlim(inpict);
	end
	
	outpict = imadjust(inpict,inrange,outrange,gamma);
	return;
end

% IF IPT IS NOT INSTALLED
if automode
	inrange = stretchlimFB(inpict);
elseif size(inpict,3) == 3 && size(inrange,2) == 1
	inrange = repmat(reshape(inrange,2,1),[1 3]);
end
inrange = max(min(inrange),1,0);
	
[inpict inclass] = imcast(inpict,'double');
outpict = zeros(size(inpict));
for c = 1:size(inpict,3)
	outpict(:,:,c) = ((inpict(:,:,c)-inrange(1,c))./(inrange(2,c)-inrange(1,c))).^gamma;
	outpict(:,:,c) = outpict(:,:,c).*(outrange(2)-outrange(1))+outrange(1);
end
outpict = max(min(real(outpict),1),0);

outpict = imcast(outpict,inclass);

end % END MAIN SCOPE
	

	
	
	
	
	
	
	
	
	
