function unitaxes(hax)
% UNITAXES({AXESHANDLE})
% Simple convenience tool to set up an axes on the unit square.
%

	if nargin<1
		hax = gca;
	end

	hstate = get(hax,'nextplot');
	hold(hax,'on')
	
	gc = [1 1 1]*0.8;
	hp(1) = plot(hax,[0 1],[0 1],'-','color',gc);
	hp(2) = plot(hax,[0 1],[1 0],'-','color',gc);
	hp(3) = plot(hax,[0 0.5],[0.5 1],'-','color',gc);
	hp(4) = plot(hax,[0.5 1],[0 0.5],'-','color',gc);
	hp(5) = plot(hax,[0 0.5],[0.5 0],'-','color',gc);
	hp(6) = plot(hax,[0.5 1],[1 0.5],'-','color',gc);
	set(hp,'handlevisibility','off','hittest','off')
	
	drawnow
	uistack(hp,'bottom')
	xlim(hax,[0 1]); ylim(hax,[0 1])
	grid(hax,'on')
	axis(hax,'square')
	%xticks(hax,yticks(hax)); % version-dependent
	yt = get(hax,'ytick');
	set(hax,'xtick',yt);
	
	if strcmpi(hstate,'replace')
		hold(hax,'off')
	end
end
