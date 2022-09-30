function map = perlin3(s,depth,f0,fn)
%   PERLIN3(OUTSIZE,POWER,F0,FN)
%       general function to generate 3-D perlin noise maps
%       this lazy pointwise method is much slower than PERLIN() 
%       but the results are repeatable and can support OUTSIZE(3)>3
%       output is double, scaled [0 1]
%
%   OUTSIZE is a 3-element vector specifying the size of the output array
%   POWER, F0, FN are parameters specifying the frequency factors
%       used in scaling the sampling mesh.
%   factors are scaled from FN/F0 to FN/(F0^POWER)
%   default values are 7, 1.8, and 1
% 
% Webdocs: http://mimtdocs.rf.gd/manual/html/perlin3.html
% See also: perlin

if ~exist('depth','var')
    depth = 7;
end
if ~exist('f0','var')
    f0 = 1.8;
end
if ~exist('fn','var')
    fn = 1;
end

map = zeros(s);
thismap = map;
   
for l = 1:depth;
    for m = 1:s(1);
        for n = 1:s(2);
            for o = 1:s(3);
                thismap(m,n,o) = noisepoint(fn*n/(f0^l),fn*m/(f0^l),fn*o/(f0^l));
            end
        end
    end
    map = map+thismap*f0^l;
end

[mn mx] = imrange(map);
map = (map-mn)/(mx-mn);

end




function out = noisepoint(x,y,z)
%   NOISEPOINT(X,Y,Z)
%       a direct implementation of Ken Perlin's 'Improved Noise' algorithm
%       http://mrl.nyu.edu/~perlin/noise/
%   
%   Inputs are voxel locations within an integer sampling mesh

perms = [151 160 137 91 90 15 131 13 201 95 96 53 194 233 7 225 140 36 103 30 ...
    69 142 8 99 37 240 21 10 23 190 6 148 247 120 234 75 0 26 197 62 94 252 ...
    219 203 117 35 11 32 57 177 33 88 237 149 56 87 174 20 125 136 171 168 ...
    68 175 74 165 71 134 139 48 27 166 77 146 158 231 83 111 229 122 60 211 ...
    133 230 220 105 92 41 55 46 245 40 244 102 143 54 65 25 63 161 1 216 ...
    80 73 209 76 132 187 208 89 18 169 200 196 135 130 116 188 159 86 164 ...
    100 109 198 173 186 3 64 52 217 226 250 124 123 5 202 38 147 118 126 ...
    255 82 85 212 207 206 59 227 47 16 58 17 182 189 28 42 223 183 170 213 ...
    119 248 152 2 44 154 163 70 221 153 101 155 167 43 172 9 129 22 39 ...
    253 19 98 108 110 79 113 224 232 178 185 112 104 218 246 97 228 251 34 ...
    242 193 238 210 144 12 191 179 162 241 81 51 145 235 249 14 239 107 ...
    49 192 214 31 181 199 106 157 184 84 204 176 115 121 50 45 127 4 150 254 ...
    138 236 205 93 222 114 67 29 24 72 243 141 128 195 78 66 215 61 156 180];

p = [perms perms];

X = mod(floor(x),255);
Y = mod(floor(y),255);
Z = mod(floor(z),255);

x = x-floor(x);
y = y-floor(y);
z = z-floor(z);

u = fade(x);
v = fade(y);
w = fade(z);

A = p(X+1)+Y; AA = p(A+1)+Z; AB = p(A+2)+Z;
B = p(X+2)+Y; BA = p(B+1)+Z; BB = p(B+2)+Z;

out = lerp(w, lerp(v, lerp(u, grad(p(AA+1), x  , y  , z   ), ...
                            grad(p(BA+1), x-1, y  , z   )), ... 
                    lerp(u, grad(p(AB+1), x  , y-1, z   ), ...
                            grad(p(BB+1), x-1, y-1, z   ))), ...
            lerp(v, lerp(u, grad(p(AA+2), x  , y  , z-1 ), ...
                            grad(p(BA+2), x-1, y  , z-1 )), ...
                    lerp(u, grad(p(AB+2), x  , y-1, z-1 ), ...
                            grad(p(BB+2), x-1, y-1, z-1 ))));
end

function out = lerp(t,a,b)
    out = a+t*(b-a);
end
    
function out = fade(t)
    out = t^3*(t*(t*6-15)+10);
end

function out = grad(hash,x,y,z)
    h = mod(hash,16);
    if h < 8
        u = x; 
    else
        u = y;
    end
    
    if h < 4
        v = y; 
    elseif (h == 12 || h == 14) 
        v = x;
    else
        v = z;
    end
    
    if mod(h,2) == 0 
        out = u;
    else
        out = -u;
    end
    
    if mod(h,4) == 0 
        out = out+v;
    else
        out = out-v;
    end
end








