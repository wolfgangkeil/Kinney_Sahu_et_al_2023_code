function [turn_pos, t]=detect_sharp_turn(mCoord_out)
% function [turn_pos, t]=detect_sharp_turn(mCoord_out)
%
% Detect the sharp turn of a backbone series
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

N = length(mCoord_out);

turn_pos=[];
k=0;
for i=2:N-1,
    t(i-1) = (mCoord_out(i,:)-mCoord_out(i-1,:)) * (mCoord_out(i+1,:)-mCoord_out(i,:))'; %% this can of course be made faster, but just left here for clarity
    if t(i-1)<0,
        k=k+1;
        turn_pos(k)=i;
    end;
end;
