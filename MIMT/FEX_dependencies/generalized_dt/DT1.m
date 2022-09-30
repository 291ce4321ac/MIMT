function [D R] = DT1(f)
% One-dimensional generalized distance transform
%
% Input: f - the sampled function
%
% Output: D - distance transform
%         R - power diagram
%
% Based on the paper:
% P. Felzenszwalb, D. Huttenlocher
% Distance Transforms of Sampled Functions
% Cornell Computing and Information Science Technical Report TR2004-1963, September 2004
% DOI: 10.4086/toc.2012.v008a019

n = numel(f);
D = zeros(n,1);
R = zeros(n,1);

k = 1; % Index of the rightmost parabola in the lower envelope
v = ones(n,1); % Locations of the parabolas in the lower envelope
z = ones(n,1); % Locations of boundaries between parabolas
z(1) = -inf;
z(2) = inf;

for q = 2:n
	% location of intersection between two parabolas
    s = ((f(q) + q^2) - (f(v(k)) + v(k)^2))/(2*q - 2*v(k));
    while s <= z(k)
        k = k - 1;
        s = ((f(q) + q^2) - (f(v(k)) + v(k)^2))/(2*q - 2*v(k));
    end
    k = k + 1;
    v(k) = q;
    z(k) = s;
    z(k+1) = inf;
end
k = 1;
for q = 1:n
    while z(k+1) < q
        k = k+1;
    end
    D(q) = (q-v(k))^2 + f(v(k));
    R(q) = v(k);
end
