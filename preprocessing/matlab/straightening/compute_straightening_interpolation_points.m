function [new_sample_points_x, new_sample_points_y] ...
        = compute_straightening_interpolation_points(midline,new_DV_size)
%
%
%   new_DV_size = matrix will be be double the size of this +1 in dorsal ventral 
%
%
%   Wolfgang Keil, Institut Curie 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% This happens, if the positions doesn't contain a worm, in this case, just fill a matrix with appropriate noise                           
    if isempty(midline)
        new_sample_points_x = [];
        new_sample_points_y = [];
    else
        
        avg_midline = midline(:,1:2,:);

        %%%%%%%%%%%%%%%%%%%% now setup the interpolation %%%%%%%%%%%%%%%%%%
        % 1. interpolate avg midline    
        % get the cumulative distance between the individual points, leads to
        % coordinate system on the line
        CS = cat(1,0,cumsum(sqrt(sum(diff(avg_midline,[],1).^2,2))));
        % Interplotate the midline at  points with 'roughly' one pixel spacing
        dd = interp1(CS, avg_midline, 0:1:CS(end),'spline');

        % Repeat procedure to achieve exactly one pixel spacing
        CS = cat(1,0,cumsum(sqrt(sum(diff(dd,[],1).^2,2))));
        % Interplotate the midline at  points with roughly one pixel spacing
        dd = interp1(CS, dd, 0:1:CS(end),'spline');
        
        
        
        % Generate line for the sampling points of the line orthogonal to the midline (this is a mesh of two-dimensional array)
        SI = -new_DV_size:1:new_DV_size;

        %%%%%%%%%%%% THIS IS THE INTERPOLATION OF the line THROUGH THE MIDLINE %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Go through the midline, find the normal line, interpolate the 
        n = length(SI);
        new_sample_points_x = zeros(n,length(dd)-1);
        new_sample_points_y = zeros(n,length(dd)-1);


        for jj = 1:(length(dd)-1)

            % Define the normal vector (this is just from one step to the next)
            n0 = dd(jj+1,:) - dd(jj,:);

            % Compute line orthogonal to the midline
            w = -[n0(2),-n0(1)];

            % This will be the center coordinate of the final matrix!  
            origin = dd(jj,:);

            % Sample the line with the nullspace vector, multiplied by the
            % SI coefficients
            line_points = repmat(w, [n, 1]).*repmat(SI',[1,2]);

            line_points(:,1) = line_points(:,1) + origin(1);
            line_points(:,2) = line_points(:,2) + origin(2);

            new_sample_points_x(:,jj) = line_points(:,1);
            new_sample_points_y(:,jj) = line_points(:,2);
        end
    end
end