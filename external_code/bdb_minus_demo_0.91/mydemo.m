tic
% load bdb_minus_example1.mat
addpath('/Users/wolfgang/rockefeller/matlab/alignment/saveastiff_4.0/');
inimg = double(loadtiff('/Users/wolfgang/SD1546/18-Jul-2016_3_image_files/worm_1_cropped_decon/Pos0/img_000000004_GFP_decon.tif'));
  
[m_gray] = main_simple_BDB_minus_3D(inimg, 2);


[x_size,y_size,z_size] = size(inimg);
[X,Y,Z] = meshgrid(0:(y_size-1),0:(x_size-1), 0:(z_size-1));

% % %%%%% Interpolate the midline obtained
% m_gray = load('midline_2.mat');
% m_gray = m_gray.m_gray;

% get the cumulative distance between the individual points, leads to
% coordinate system on the line
CS = cat(1,0,cumsum(sqrt(sum(diff(m_gray,[],1).^2,2))));
% Interplotate the midline at equidistant points with one pixel spacing
dd = interp1(CS, m_gray, 0:1:CS(end),'PCHIP');

meshgrid_size = [100 50]; %% Actual matrix will be double the size of this
straightened_worm = zeros(2*meshgrid_size(1)+1,length(dd)-1, 2*meshgrid_size(2) + 1);

%%%%% Now go through the midline, find the normal plane, interpolate the 
for ii = 1:(length(dd)-1)
 
    % Get the sampling points of the plane (this is a mesh of two-dimensional array)
    [SI,TI] = meshgrid(-meshgrid_size(1):1:meshgrid_size(1),-meshgrid_size(2):1:meshgrid_size(2));

    [n,m] = size(SI);

    % Define the normal vector (this is just from one step to the next)
    n0 = dd(ii+1,:) - dd(ii,:);
    
    % Compute space orthogonal to the normal vector of the plane, that is
    % two vectors spanning the plane
    w = null(n0);
    v = w(:,1);
    w = w(:,2);

    % This will be the zero 
    origin = dd(ii,:);

    plane_points = repmat(reshape(v,[1,1,3]), [n, m,1]).*repmat(SI,[1,1,3]) + repmat(reshape(w,[1,1,3]), [n, m,1]).*repmat(TI,[1,1,3]);

    plane_points(:,:,1) = plane_points(:,:,1) + origin(1);
    plane_points(:,:,2) = plane_points(:,:,2) + origin(2);
    plane_points(:,:,3) = plane_points(:,:,3) + origin(3);

    % Interpolate in the plane
    Vq = interp3(X,Y,Z,inimg,plane_points(:,:,2),plane_points(:,:,1),plane_points(:,:,3), 'linear',0);
    
    straightened_worm(:,ii,:) = Vq';
    disp([num2str(ii/(length(dd)-1)*100) '% percent']);
    
end

hold off;

% Cut the boundaries
K_factor = 0.25;
mean_val = mean(straightened_worm(:));
std_val = std(straightened_worm(:));

[ind] = find(straightened_worm>(mean_val+K_factor*std_val));
[xind, yind, zind] = ind2sub(size(straightened_worm), ind);

% Take the indices off (middle index is untouched, this is the index along the worm axis)
straightened_worm = straightened_worm(max(min(xind)-2, 1) : min(max(xind)+2, size(straightened_worm,1)),...
    :, max(min(zind)-2,1) : min(max(zind)+2, size(straightened_worm,3)));

save('straightened_worm_2.mat', 'straightened_worm');
% Bitdepth
bitdepth = 16;
straightened_worm = (straightened_worm - min(straightened_worm(:))) * ((2^bitdepth-1) / (max(straightened_worm(:)) - min(straightened_worm(:))));

if exist('straightened_worm.tif', 'file')
    delete('straightened_worm.tif');
end
saveastiff(uint16(straightened_worm), 'straightened_worm.tif');


figure(1)
image(squeeze(max(straightened_worm,[],3))); 



toc;

    