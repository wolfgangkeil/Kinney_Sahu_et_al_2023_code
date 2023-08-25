function m = mst_points(mCoords)
%function m = mst_points(mCoords)
%
% Find the MST of m points in the Euclidean space
%
% This porgram is part of the backbone detection method in the following
% paper.
%
% ** Reference: 
%
% Peng, H., Long, F., Liu, X., Kim, S., and Myers, E.W., "Straightening C. elegans images," 
% Bioinformatics, Vol. 24, No. 2, pp. 234-242, 2008.
% 
%
% Copyright: Hanchuan Peng
% All rights reserved.
%
% Last update: 2008-May-19
%

[M, ND] = size(mCoords);
d = zeros(M, M);
for i=1:M,
    for j=i+1:M,
        d(i,j) = sqrt(sum((mCoords(i,:) - mCoords(j,:)).^2, 2));
        d(j,i) = d(i,j);
    end;
end;

m = mst(d./max(d(:)));

