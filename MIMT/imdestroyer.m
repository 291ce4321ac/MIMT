function [outpict com] = imdestroyer(inpict,iterations,amt)
%   IMDESTROYER(INPICT, ITERATIONS,AMOUNT)
%       feeds INPICT through randomly selected image manipulation functions
%       selecting bounded random parameters each time, for ITERATIONS
%       number of times. 
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imdestroyer.html

amt = max(min(amt,1),0);
numfuncs = 9; % number of available functions

com = sprintf('amt=%g; \n',amt);
for n = 1:1:iterations;
    whichfunc = ceil(rand()*numfuncs);
    switch whichfunc
        case 1
            % random margin dilation
            whichop = ceil(rand()*3);
            switch whichop
                case 1
                    rv = rand();
					se = simnorm(fkgen('rect',[1 1]*ceil(15*rv)));					
                    com = [com sprintf('se=simnorm(fkgen(''rect'',[1 1]*ceil(15*%g))); \n',rv)];
                case 2
                    rv = rand();
					se = simnorm(fkgen('disk',ceil(15*rv)*2));
                    com = [com sprintf('se=simnorm(fkgen(''disk'',ceil(15*%g)*2)); \n',rv)];
                case 3
                    rv = rand(1,2);
					se = simnorm(fkgen('motion',ceil(15*rv(1)),'angle',ceil(90*rv(2))));
                    com = [com sprintf('se=simnorm(fkgen(''motion'',ceil(15*%g),''angle'',ceil(15*%g))); \n',rv(1),rv(2))];
			end
            rv = rand(1,3);
            field = dilatemargins(inpict,rv(1:2)*0.08,se);
            inpict = imblend(field,inpict,rv(3)*amt,'normal');
            com = [com sprintf('field=dilatemargins(inpict,[%g %g],se); \n',rv(1)*0.08,rv(2)*0.08)];
            com = [com sprintf('inpict=imblend(field,inpict,%g*amt,''normal''); \n',rv(3))];
            
        
        case 2
            % random jpeg degradation
            rv = rand();
            inpict = jpegger(inpict,50*(amt+rv*amt));
            com = [com sprintf('inpict=jpegger(inpict,50*(amt+%g*amt)); \n',rv)];
            % add other degradation methods
        
        
        case 3          % how to use AMT here?
            % do a random channel permutation
            % random int from [-3 3] excluding zero
            rv = rand(1,4);
            rchan = -3+(3+3).*rv(1:3);
            rchan = ceil(abs(rchan)).*sign(rchan);
            com = [com sprintf('rchan=-3+(3+3).*[%g %g %g]; \n',rv(1),rv(2),rv(3))];
            com = [com sprintf('rchan=ceil(abs(rchan)).*sign(rchan); \n')];
            
            whichop = ceil(rand()*2);
            switch whichop
                case 1
                    field = permutechannels(inpict,rchan,'rgb');
                    com = [com sprintf('field=permutechannels(inpict,rchan,''rgb''); \n')];
                case 2
                    field = permutechannels(inpict,rchan,'hsv');
                    com = [com sprintf('field=permutechannels(inpict,rchan,''hsv''); \n')];
            end
            inpict = imblend(field,inpict,rv(4)*amt,'normal');
            com = [com sprintf('inpict=imblend(field,inpict,%g*amt,''normal''); \n',rv(4))];
            
        case 4
            % blend with random color field
            whichop = ceil(rand()*7);
            switch whichop
                case 1
                    rv = rand();
                    direction = 1+round(rv(1));
                    com = [com sprintf('direction=1+round(%g); \n',rv(1))];
                    rv = rand(1,3);
                    rate = 0.2+(2-0.2).*rv(1);
                    com = [com sprintf('rate=0.2+(2-0.2).*%g; \n',rv(1))];
					if round(rv(3))
						field = imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','walks','rate',rate));
						com = [com sprintf('field=imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''walks'',''rate'',rate)); \n',rv(2))];
					else
						field = repmat(imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','walks','rate',rate,'mono')),[1 1 3]);
						com = [com sprintf('field=repmat(imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''walks'',''rate'',rate,''mono'')),[1 1 3]); \n',rv(2))];
					end
                case 2
                    rv = rand();
                    direction = 1+round(rv(1));
                    com = [com sprintf('direction=1+round(%g); \n',rv(1))];
                    rv = rand(1,3);
                    rate = 0.5+(2-0.5).*rv(1);
					com = [com sprintf('rate=0.2+(2-0.2).*%g; \n',rv(1))];
					if round(rv(3))
						field = imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','ramps','rate',rate));
						com = [com sprintf('field=imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''ramps'',''rate'',rate)); \n',rv(2))];
					else
						field = repmat(imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','ramps','rate',rate,'mono')),[1 1 3]);
						com = [com sprintf('field=repmat(imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''ramps'',''rate'',rate,''mono'')),[1 1 3]); \n',rv(2))];
					end
                case 3
                    rv = rand();
                    direction = 1+round(rv(1));
                    com = [com sprintf('direction=1+round(%g); \n',rv(1))];
                    rv = rand(1,2);
					if round(rv(2))
						field = imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','normal'));
						com = [com sprintf('field=imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''normal'')); \n',rv(2))];
					else
						field = repmat(imlnc(randlines(size(inpict),direction,'sparsity',rv(2),'mode','normal','mono')),[1 1 3]);
						com = [com sprintf('field=repmat(imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''normal'',''mono'')),[1 1 3]); \n',rv(2))];
					end
                case 4
                    corners = round(rand(2,2));
                    colors = rand(2,3)*255;
                    methods = {'invert' 'softinvert' 'linear' 'softease' 'cosine' 'ease' 'waves'};
                    method = char(methods(ceil(length(methods)*rand())));
                    field = lingrad(size(inpict),corners,colors,method);
                    com = [com sprintf('field=lingrad(size(inpict),[%g %g; %g %g],[%g %g %g; %g %g %g],''%s''); \n', ...
                        corners(1,1),corners(1,2),corners(2,1),corners(2,2),colors(1,1),colors(1,2),colors(1,3),colors(2,1),colors(2,2),colors(2,3),method)];
                case 5
                    center = rand(1,2);
                    radius = 1.414;
                    colors = rand(2,3)*255;
                    methods = {'invert' 'softinvert' 'linear' 'softease' 'cosine' 'ease' 'waves'};
                    method = char(methods(ceil(length(methods)*rand())));
                    field = radgrad(size(inpict),center,radius,colors,method); 
                    com = [com sprintf('field=radgrad(size(inpict),[%g %g],%g,[%g %g %g; %g %g %g],''%s''); \n', ...
                        center(1,1),center(1,2),radius,colors(1,1),colors(1,2),colors(1,3),colors(2,1),colors(2,2),colors(2,3),method)];
                case 6
                    color = rand(1,3)*255;
                    field = colorpict(size(inpict),color,'uint8');  
                    com = [com sprintf('field=colorpict(size(inpict),[%g %g %g],''uint8''); \n', ...
                        color(1,1),color(1,2),color(1,3))];
                case 7
                    field = perlin(size(inpict));  
                    com = [com sprintf('field=perlin(size(inpict)); \n')];
            end
            
            blendamount = rand()*amt;
            blendmodes = {'multiply' 'overlay' 'screen' 'addition' 'hue' 'color' 'luma' 'scale add' 'scale mult' ...
                'contrast' 'phoenix' 'reflect' 'glow' 'freeze' 'heat' 'softlight' 'hardlight' 'softdodge' 'softburn'};
            blendmode = char(blendmodes(ceil(length(blendmodes)*rand())));
            inpict = imblend(field,inpict,blendamount,blendmode);
            com = [com sprintf('inpict=imblend(field,inpict,%g,''%s''); \n',blendamount,blendmode)];
            
        case 5         
            % do a random blockify
            rv = rand(1,4);
            blsize = round(16+(64-16).*rv(1:3));
            com = [com sprintf('blsize=round(16+(64-16).*[%g %g %g]); \n',rv(1),rv(2),rv(3))];
            whichop = ceil(rand()*2);
            switch whichop
                case 1
                    field = blockify(inpict,blsize,'rgb');
                    com = [com sprintf('field=blockify(inpict,blsize,''rgb''); \n')];
                case 2
                    field = blockify(inpict,blsize,'hsv');
                    com = [com sprintf('field=blockify(inpict,blsize,''hsv''); \n')];
            end
            inpict = imblend(field,inpict,rv(4)*amt,'normal');
            com = [com sprintf('inpict=imblend(field,inpict,%g*amt,''normal''); \n',rv(4))];
            
        case 6
            % shift random color field
            whichop = ceil(rand()*3);
            switch whichop
                case 1
					rv = rand(1,3);
                    rate = 0.2+(2-0.2).*rv(1);
                    com = [com sprintf('rate=0.2+(2-0.2).*%g; \n',rv(1))];
					if round(rv(3))
						field = imlnc(randlines(size(inpict),2,'sparsity',rv(2),'mode','walks','rate',rate,'outclass','uint8'));
						com = [com sprintf('field=imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''walks'',''rate'',rate,''outclass'',''uint8'')); \n',rv(2))];
					else
						field = repmat(imlnc(randlines(size(inpict),2,'sparsity',rv(2),'mode','walks','rate',rate,'mono','outclass','uint8')),[1 1 3]);
						com = [com sprintf('field=repmat(imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''walks'',''rate'',rate,''mono'',''outclass'',''uint8'')),[1 1 3]); \n',rv(2))];
					end
                case 2
					rv = rand(1,2);
					if round(rv(2))
						field = imlnc(randlines(size(inpict),2,'sparsity',rv(2),'mode','normal','outclass','uint8'));
						com = [com sprintf('field=imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''normal'',''outclass'',''uint8'')); \n',rv(2))];
					else
						field = repmat(imlnc(randlines(size(inpict),2,'sparsity',rv(2),'mode','normal','mono','outclass','uint8')),[1 1 3]);
						com = [com sprintf('field=repmat(imlnc(randlines(size(inpict),direction,''sparsity'',%g,''mode'',''normal'',''mono'',''outclass'',''uint8'')),[1 1 3]); \n',rv(2))];
					end
                case 3
                    field = inpict;
                    com = [com sprintf('field=inpict; \n')];
            end
            
            rv = rand(3,2);
            %shamt=horzcat(-1+2*rand(3,1),zeros(3,1)); % horizontal only
            shamt = -1+2*rv;
            inpict = lineshifter(inpict,field,shamt*amt);
            com = [com sprintf('shamt=-1+2*[%g %g; %g %g; %g %g]; \n',rv(1,1),rv(1,2),rv(2,1),rv(2,2),rv(3,1),rv(3,2))];
            com = [com sprintf('inpict=lineshifter(inpict,field,shamt*amt); \n')];
         
        
        case 7   
            % do straight channel shifts
            rv = rand(3,2);
            shamt = fix(-10+20*rv);
            inpict = straightshifter(inpict,shamt*amt);
            com = [com sprintf('shamt=fix(-10+20*[%g %g; %g %g; %g %g]); \n',rv(1,1),rv(1,2),rv(2,1),rv(2,2),rv(3,1),rv(3,2))];
            com = [com sprintf('inpict=straightshifter(inpict,shamt*amt); \n')];
        
        
        case 8
            % do picdynamics thing
            rv = rand(1,2);
            w = size(inpict,2);
            f = w/400+(w/400-w/100)*rv(1);
            lt = 30+(60-30)*rv(2);
            com = [com sprintf('w=size(inpict,2); \n')];
            com = [com sprintf('f=w/400+(w/400-w/100)*%g; \n',rv(1))];
            com = [com sprintf('lt=30+(60-30)*%g; \n',rv(2))];
            
            whichop = ceil(rand()*3);
            switch whichop
                case 1
                    frame = picdynamics(inpict,f,lt,'squeeze','hue');
                    com = [com sprintf('frame=picdynamics(inpict,f,lt,''squeeze'',''hue''); \n')];
                case 2
                    frame = picdynamics(inpict,f,lt,'squeeze','value');
                    com = [com sprintf('frame=picdynamics(inpict,f,lt,''squeeze'',''value''); \n')];
                case 3
                    frame = picdynamics(inpict,f,lt,'squeeze','luma');
                    com = [com sprintf('frame=picdynamics(inpict,f,lt,''squeeze'',''luma''); \n')];
            end
            
            whichop = ceil(rand()*3);
            switch whichop
                case 1
                    inpict = imblend(frame,inpict,1,'scale add',1.5);
                    com = [com sprintf('inpict=imblend(frame,inpict,1,''scale add'',1.5); \n')];
                case 2
                    inpict = imblend(frame,inpict,1,'scale mult',1);
                    com = [com sprintf('inpict=imblend(frame,inpict,1,''scale mult'',1); \n')];
                case 3
                    inpict = imblend(frame,inpict,1,'contrast',1);
                    com = [com sprintf('inpict=imblend(frame,inpict,1,''contrast'',1); \n')];
            end
            
        case 9       
            % do glass tiles
            tiles = round(10+(100-10).*rand(1,2));
            field = glasstiles(inpict,tiles);
            com = [com sprintf('field=glasstiles(inpict,[%g %g]); \n',tiles(1),tiles(2))];
            
            blendamount = 0.5+0.5*rand()*amt;
            blendmodes = {'multiply' 'overlay' 'screen' 'addition' 'luma' 'scale add' 'scale mult' ...
                'contrast' 'phoenix' 'reflect' 'glow' 'freeze' 'heat' 'softlight' 'hardlight' 'softdodge' 'softburn'};
            blendmode = char(blendmodes(ceil(length(blendmodes)*rand())));
            inpict = imblend(field,inpict,blendamount,blendmode);
            com = [com sprintf('inpict=imblend(field,inpict,%g,''%s''); \n',blendamount,blendmode)];    
    end
end

outpict = inpict;

return































