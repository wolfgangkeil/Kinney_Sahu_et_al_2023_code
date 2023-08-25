function [mCoord_new_BW, final_dist, turn_pos,inimg] = main_simple_BDB_minus_3D(inimg, Kfactor, seed)
% function [mCoord_new_BW, final_dist, turn_pos,inimg] = main_simple_BDB_minus_3D(inimg, Kfactor, seed)
% 
% THIS IS A MODIFIED VERSION FROM THE ORIGINAL PENG CODE, SO THAT IT WORKS
% in 3D
%
% A simple program to demonstrate the BDB- algorithm developed for
% straightening worm images where the boundary/cuticle information is
% unavailable. (If available, the BDB+ method can be used).
%
% ** Parameters:
%
% inimg - a grayscale worm image (assuming background is black, i.e. with
% low intensity; and foreground is bright, i.e. with high-intensity)
%
% Kfactor - the threshold to remove background based on mean+Kfactor*std
% 
% ** Example: 
% 
% load bdb_minus_example1.mat
% [m_gray, m_bw] = main_simple_BDB_minus(inimg, 0);
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

% add path to graph library

    do_plotting = 0;  
    
    alpha = 1; % Image weight
    beta = 0.5; % Length weight
    gamma = 1; % Smoothness weight
    
    
    TH = 0.1; % convergence threshold
    KK = 100; % # of control points, can be defined adaptively

    if nargin<2
        Kfactor=1;
    end

    inimg = double(inimg);
    inimg = medfilt3(inimg, [5,5,5]);

    mean_val = mean(inimg(inimg>0));
    std_val = std(inimg(inimg>0));

    ind = find(inimg>mean_val+Kfactor*std_val);
    [xx, yy,zz]= ind2sub(size(inimg), ind);
    
    % Convert image to black and white, this way, the intensity doesn't
    % really matter
    inimg = double(inimg>mean_val+Kfactor*std_val);
    % do not use the result with sharp turns, - they may be produced via poor
    % random initialization
    
    %for ii = 1:size(inimg,3); figure(1); imshow(inimg(:,:,ii)); drawnow; pause(0.1); end;    
    
    if do_plotting
        figure(10)
        clf;
        set(gcf, 'Name', 'BW image result');
        imshow(max(inimg, [], 3));
    end
    if nargin > 3
        rng(seed);
    end
    
    turn_pos=-1;
    max_no_trials = 5;
    no_trials = 0;
    while (~isempty(turn_pos) && no_trials < max_no_trials)

        no_trials = no_trials + 1;
        
        % first random initializtion
        p=randperm(length(ind));

        mCoord_out = [xx(p(1:KK)) yy(p(1:KK)) zz(p(1:KK))];

        % then use MST diameter to determine initial coord of control points

        m = mst_points(mCoord_out);
        myord = img_mst_diameter(m);
        mCoord_out = mCoord_out(myord, :);
        
        
        %%%% Initialization with a drawn line
        %mCoord_out = input_initial_seed_manually(inimg,KK, mean_val, std_val, Kfactor);
        %mCoord = load('mCoord.mat');
        %mCoord_out = mCoord.mCoord;

        
        % BDB- update of the coordinates. Use 2D example here. Can be 3D or
        % higher-dim as well.
        [mCoord_new_BW, final_dist]  = point_bdb_minus([xx yy zz], inimg(ind), mCoord_out, TH, alpha, beta, gamma, inimg, Kfactor, do_plotting);
       % [mCoord_new_BW, final_dist]  = point_bdb_minus([xx yy zz], inimg(ind)/(2^bitdepth-1), mCoord_out, TH, alpha, beta, gamma, inimg, Kfactor, do_plotting);
        %mCoord_new_gray = point_bdb_minus([xx yy zz], ind, mCoord_out, TH, alpha, beta, gamma, inimg, Kfactor);

        % detect if there are sharp turns, - if yes, then redo.
        [turn_pos, ~]= detect_sharp_turn(mCoord_new_BW);

    end
    %title('Grayscale image result');

    %remove path to graph library
    if ~isdeployed
     %   rmpath graph
    end

    return;
    
end



function mCoord = input_initial_seed_manually(img0,no_points, mean_val, std_val, K_factor)

    [x,y] = meshgrid(1:size(img0,2), 1:size(img0,1));
    disp('Input grid manually...');
    figure(10)
    clf
    
    contour(x,y,max(img0,[],3),mean_val+K_factor*std_val);
    axis image;  
    grid on;
    
    
    hFH = impoly();

    if ~isempty(hFH) % in which case the user actually selected a ROI

        % get the cumulative distance between the individual points, leads to
        % coordinate system on the line
        CS = cat(1,0,cumsum(sqrt(sum(diff(hFH.getPosition(),[],1).^2,2))));
        % Interplotate the midline at equidistant points with one pixel spacing
        mCoord = interp1(CS, hFH.getPosition(), linspace(0,CS(end),no_points),'PCHIP');
        
        % BDB- update of the coordinates. Use 2D example here. Can be 3D or
        % higher-dim as well.
        delete(hFH);
        
        mCoord = mCoord(:,end:-1:1);
        hold on;
        plot(mCoord(:,2), mCoord(:,1));
        hold off;
        drawnow;

        mCoord(:,3) = size(img0,3)/2;
        
    end
    disp('...done');
    
    save('mCoord.mat','mCoord');
    
    pause(0.5);
    close(gcf);
end

