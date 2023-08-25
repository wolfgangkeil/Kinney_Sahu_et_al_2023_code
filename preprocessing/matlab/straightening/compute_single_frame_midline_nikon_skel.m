function [auto_midline, img]= compute_single_frame_midline_nikon_skel...
        (experiment_folder, frame_index, trigger_stack, trigger_channel,Path2Ilastik, downsample, prior_midline)
%
% function auto_midline  = compute_single_frame_midline_nikon_skel(trigger_stack, K_factor)
% This code computes the midline of a worm image from the maximum-z projected MCP-GFP signal
% The signal is first enhanced with Ilastik, then filter with a Gaussian to
% avoid skeletonization artifacts
% Downsampling is not necessary to yield reliable results
% alignment is done with the midline of the preceeding frame (prior_midline) 
%
%
%
%
% all code by Wolfgang Keil, Institut Curie 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ilastik_root = Path2Ilastik;
    ilastik_project = ['../../ilastik/'    ...
       'classify_MCP_GFP_for_straightening/classify_MCP_GFP_for_straightening.ilp']; 
    ilastik_prob_threshold = 0.5;
    
    min_number_of_worm_pixels = 100;
  
    if nargin < 6
        downsample = 1;
        prior_midline = [];
    end
    
    if nargin < 7
        prior_midline = [];
    end
    
    %  addpath('../external_code/saveastiff_4.0/');

    % save a maximum z projection of the trigger stack in a temporary file,
    % use this file for the ilastik classification
    tmp = max(trigger_stack,[],3);
    filename = [experiment_folder trigger_channel '/tmp.tif'];    
    tmp_options.overwrite = true;
    saveastiff(uint16(tmp),filename,tmp_options);
    
    timestamp_string = num2str(frame_index);
    timestamp_string = [repmat('0', [1 9-length(timestamp_string)]) timestamp_string];
    
    if exist(filename, 'file')
        disp('Performing pixel classification  with Ilastik...');
        command = [ilastik_root '/Contents/ilastik-release/run_ilastik.sh' ' --headless --project='...
            ilastik_project ' ' filename];     
        [~,out] = system(command);
    else
        disp(['Maximum z projection of ' trigger_channel ' channel not available. Run ImageJ macro stitch_resave_zproject.ijm or resave_nikon_tif_series.ijm first.']);
        auto_midline = [];
        return;
    end
    
    
    img = loadtiff([experiment_folder trigger_channel '/tmp_Probabilities.tif']);
    img = real(img);% Two-channel images get loaded as complex numbers, real part is worm probabilities

    
    if downsample
        % downsample A along xy before computing midline 
        disp(['     Downsampling original frame for midline computation']);
        img = imresize(img,[ceil(size(img,1)/2), ceil(size(img,2)/2)]);
    end
    disp(['     Computing midline with 2D skeletonization ']);

     % Gaussian filtering to avoid midlines that are too curvy!
    if downsample
        img = imgaussfilt(double(img),10)>ilastik_prob_threshold;
    else
        img = imgaussfilt(double(img),20)>ilastik_prob_threshold;
    end
    
       
    % For safety, remove everything that is not in the largest connected
    % component
    tmp = zeros(size(img));
    
    CC = bwconncomp(img);

    if CC.NumObjects > 0
        % Delete everything but the largest connected component
        numOfPixels = cellfun(@numel,CC.PixelIdxList);
        [~,indexOfMax] = max(numOfPixels);
        %nucleus = zeros(size(Ilastik_stack,1),size(Ilastik_stack,2));
        tmp(CC.PixelIdxList{indexOfMax}) = 1;
        img = tmp;
        % Fill any holes in the larges connected component
        img = imfill(img,'holes');
    else
        disp('Something is odd with this Ilastik probability map. No worm in it.');
        auto_midline = [];
        return;
    end
    
    if downsample
        B = bwskel(img>0,'MinBranchLength',250);
    else
        B = bwskel(img>0,'MinBranchLength',500);
%        B2 = bwmorph(skeleton(img)>35,'skel',Inf); // Alternative
%        skeletonization method, doesn''t work well either
    end
    
    
    % Organize the points into a contour
    ind = find(B>0);
    worm_ind = find(img>0);
    [XX,YY] = ind2sub(size(B),worm_ind);
    
    % Find the starting point of the contour
    distances = zeros(size(ind));
    % This finds the summed distances to all pixels within the worm
    for i = 1:length(ind)
        [xx, yy]= ind2sub(size(B), ind(i));% point on the contour
        dd = (XX-xx).^2 + (YY-yy).^2;
        distances(i) = sum(dd(:));
    end
    % The point with the maximum summed distances to all worm points is the
    % tail tip
    start_ind = find(distances == max(distances),1);
    [xx, yy]= ind2sub(size(B), ind);

    
    if length(ind) < min_number_of_worm_pixels
          % Abort this, there is almost no worm pixels in this frame
          auto_midline = [];       
    else
        [Xout,Yout]=points2contour(xx,yy,start_ind,'ccw');

        % After points2contour, points are aligned on a line, but starting
        % point can be in the middle of the contour, the following lines
        % rectify this
        X_outC = circshift(Xout,1);
        Y_outC = circshift(Yout,1);  
        dd = (X_outC-Xout).^2 + (Y_outC-Yout).^2;

        % This moves the line so that an endpoint is at the end
        Xout = circshift(Xout, 1- find(dd == max(dd)));
        Yout = circshift(Yout, 1- find(dd == max(dd)));  

        %%%%%%%%%%%%%%%%% EVALUATE THE MIDLINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Reduce the number of points in the midline so that it doesn't get
        % too rigged when straightening
        CS = cat(1,0,cumsum(sqrt(sum(diff([Xout',Yout'],[],1).^2,2))));     



        % Minimal length of a midline is 500 pixels
        min_midline_length = 500;
        if downsample
            min_midline_length = min_midline_length/2;
        end

        if CS(end) < min_midline_length
          % Abort this, this piece of the worm is too short to be reliably
          % skeletonized
          auto_midline = [];
        else
            
            % Make a point "roughly" every 20 pixel
            % smoothing by omitting points, otherwise curvature values are
            % weird
            gridspacing = 20;
            no_points = round(CS(end)/gridspacing);
            
            auto_midline = [Xout(round(linspace(1,length(Xout),no_points)))', ...
                Yout(round(linspace(1,length(Xout),no_points)))', ones(no_points,1)*size(trigger_stack,3)/2 ];

            k = LineCurvature2D([auto_midline(:,1),auto_midline(:,2)]);     

           
            % Find out if endpoints of midline are close to edge of matrix
            edge_threshold = 50; % pixels
            curvature_threshold = 0.012;

            if min([abs(auto_midline(1,1)-1),abs(auto_midline(1,1)-size(img,2))]) < edge_threshold || ...
                min([abs(auto_midline(1,2)-1),abs(auto_midline(1,2)-size(img,1))]) < edge_threshold

                ii = find(abs(k) > curvature_threshold, 1);
                if ~isempty(ii) && ii < 300/gridspacing %% Should not be more than 300 pixels into the midline
                   auto_midline = auto_midline(ii+1:end,:); 
                end

            end

            k = LineCurvature2D([auto_midline(:,1),auto_midline(:,2)]);
            if min([abs(auto_midline(end,1)-1),abs(auto_midline(end,1)-size(img,2))]) < edge_threshold || ...
                      min([abs(auto_midline(end,2)-1),abs(auto_midline(end,2)-size(img,1))]) < edge_threshold          
                ii = find(abs(k) > curvature_threshold, 1, 'last');
                if ~isempty(ii) && ii > (size(auto_midline,1)-300/gridspacing) %% Should not be more than 300 pixels  into the midline
                   auto_midline = auto_midline(1:ii-1,:); 
                end
            end


            if downsample
                % Upsample midline along xy
                auto_midline(:,1) = auto_midline(:,1)*2;
                auto_midline(:,2) = auto_midline(:,2)*2;
            end
            
            
            
            %%%%%%%%%%%%%%%% Match directionality of the midline with
            %%%%%%%%%%%%%%%% previous midline if existant
            if ~isempty(prior_midline)
                
                % Interpolate prior_midline to the size 
                stepLengths = sqrt(sum(diff(prior_midline,[],1).^2,2));
                stepLengths = [0; stepLengths]; % add the starting point
                cumulativeLen = cumsum(stepLengths);
                finalStepLocs = linspace(0,cumulativeLen(end), size(auto_midline,1));
                prior_midline = interp1(cumulativeLen, prior_midline, finalStepLocs, 'spline');            
                
                
                
                % Compute distance of midline to prior_midline and reversed
                dd1 = sum((auto_midline(:,1) - prior_midline(:,1)).^2 + (auto_midline(:,2) - prior_midline(:,2)).^2 + + (auto_midline(:,3) - prior_midline(:,3)).^2);
                dd2 = sum((auto_midline(end:-1:1,1) - prior_midline(:,1)).^2 + (auto_midline(end:-1:1,2) - prior_midline(:,2)).^2 + + (auto_midline(end:-1:1,3) - prior_midline(:,3)).^2);


                % if the distance to the reversed prior midline is larger
                % than the non reversed, invert
                if dd2 < dd1
                    auto_midline = auto_midline(end:-1:1,:);
                end
            end
            
%             figure(1);
%             hold on;
%             plot(auto_midline(:,1) ,auto_midline(:,2),'g' ); 
%             hold off;
            
            
            %%%% Now take equally spaced points on the midline, 100 pixel
            %%%% apart (these will the be interpolate by cubic spline in
            %%%% during the actualy straightening
            spacing = 100;
            CS = cat(1,0,cumsum(sqrt(sum(diff([auto_midline(:,1),auto_midline(:,2)],[],1).^2,2))));     
            no_points = round(CS(end)/spacing);

            auto_midline = [auto_midline((round(linspace(1,length(CS),no_points))),1), ...
                auto_midline((round(linspace(1,length(CS),no_points))),2), ones(no_points,1)*round(size(trigger_stack,3)/2) ];
            
        end

    end
end
