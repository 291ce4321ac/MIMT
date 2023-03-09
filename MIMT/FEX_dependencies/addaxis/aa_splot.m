function varargout = aa_splot(varargin)
%AA_SPLOT replaces plot command and automatically changes color
%
%  This function is a replacement for the plot command.  
%  It automatically changes the color with subsequent
%  uses of aa_splot.  
%  
%  Usage is exactly the same as for plot.  

np = get(gca,'nextplot');
oldplots = get(gca,'children');

cord = get(gca,'colororder');

if ~isempty(oldplots)
lastcolor = get(oldplots(1),'color');
if lastcolor == cord(1,:)
  set(gca,'colororder',cord(mod((0:6)+1,7)+1,:));
end
end

hold on;

h = plot(varargin{:});

for IND = 1:nargout
   varargout(IND) = {h}; %#ok<AGROW>
end

%if nargout > 0, varargout{:} = h; end;

set(gca,'colororder',cord(mod((0:6)+1,7)+1,:));
set(gca,'nextplot',np);
set(gca,'box','on');
