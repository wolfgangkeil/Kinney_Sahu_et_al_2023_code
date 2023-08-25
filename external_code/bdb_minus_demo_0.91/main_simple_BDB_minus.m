function [mCoord_new_BW, turn_pos] = main_simple_BDB_minus(inimg, Kfactor, seed)
% function [mCoord_new_BW, turn_pos] = main_simple_BDB_minus(inimg, Kfactor, seed)
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

    %%% Set the parameters for midline finding, see Peng et al. 
    % Peng, H., Long, F., Liu, X., Kim, S., and Myers, E.W., "Straightening C. elegans images," 
    % Bioinformatics, Vol. 24, No. 2, pp. 234-242, 2008.
    
    alpha = 1; % Image weight
    beta = 0.3; % Length weight
    gamma = 0.5; % Smoothness weight
    
    
    addpath graph

    TH = 0.1; % convergence threshold
    KK = 30; % # of control points, can be defined adaptively

    if nargin<2,
        Kfactor=1;
    end;

    if nargin > 2
        rng(seed);
    end


    inimg = double(inimg);

    mean_val = mean(inimg(inimg>0));
    std_val = std(inimg(inimg>0));

    ind = find(inimg>mean_val+Kfactor*std_val);
    [xx, yy]= ind2sub(size(inimg), ind);
    % Turn image into BW image
    inimg = double(inimg>mean_val+Kfactor*std_val);
    
    % compute for the grayscale image, - the result is good when the spatial distribution of intensity is not skewed

    % do not use the result with sharp turns, - they may be produced via poor
    % random initialization
    figure(2);
    set(gcf, 'Name', 'Grayscale image result');
    turn_pos=-1;
    max_no_trials = 5;
    no_trials = 0;
    while (~isempty(turn_pos) && no_trials < max_no_trials)

        no_trials = no_trials + 1;
        % first random initializtion

        p=randperm(length(ind));
        mCoord_out = [xx(p(1:KK)) yy(p(1:KK))];

        % then use MST diameter to determine initial coord of control points

        m = mst_points(mCoord_out);
        myord = img_mst_diameter(m);
        mCoord_out = mCoord_out(myord, :);
        
        %mCoord_out = input_initial_seed_manually(inimg,KK, mean_val, std_val, Kfactor);
        

        mCoord_new_BW = point_bdb_minus([xx yy], inimg(ind)/max(inimg(ind)), mCoord_out, TH, alpha,beta, gamma, inimg,Kfactor,1);

        % detect if there are sharp turns, - if yes, then redo.

        [turn_pos, tt]=detect_sharp_turn(mCoord_new_BW);
        if ~isempty(turn_pos)
            disp('Sharp turn detected. Trying again...');
        end

    end
    if isempty(turn_pos)
        % Found a midline withour sharp turns
        title('BW image result');
        % interpolate it with cubic splines
        spcv = cscvn( mCoord_new_BW');
        mCoord_new_BW = fnval(spcv, linspace(0,spcv.breaks(end), 2000));        
        mCoord_new_BW = mCoord_new_BW'; % Transpose
        
    end

%     % also compute the binarized image, - this is useful for graylevel skewed
%     % images
% 
%     figure('Name', 'BW - binarized image');
%     turn_pos=-1;
%     while (~isempty(turn_pos)), 
% 
%         % first random initializtion
% 
%         p=randperm(length(ind));
%         mCoord_out = [xx(p(1:KK)) yy(p(1:KK))];
% 
%         % then use MST diameter to determine initial coord of control points
% 
%         m = mst_points(mCoord_out);
%         myord = img_mst_diameter(m);
%         mCoord_out = mCoord_out(myord, :);
% 
%         % BDB- update of the coordinates. Use 2D example here. Can be 3D or
%         % higher-dim as well.
% 
%         mCoord_new_bw = point_bdb_minus([xx yy], inimg(ind)/max(inimg(ind)), mCoord_out, TH, alpha, beta, gamma, inimg, Kfactor);
% 
%         % detect if there are sharp turns, - if yes, then redo.
% 
%         [turn_pos, tt]=detect_sharp_turn(mCoord_new_bw);
% 
%     end;
%     title('BW - binarized image result');
% 
%     %remove path to graph library
%     rmpath graph
% 
%     return;


end

function mCoord = input_initial_seed_manually(img0,no_points, mean_val, std_val, K_factor)

    [x,y] = meshgrid(1:size(img0,2), 1:size(img0,1));
    disp('Plotting data...');
    figure(1)
    clf
    
    contour(x,y,img0,mean_val+K_factor*std_val);
    axis image;  
    disp('...done');
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

        
    end

end