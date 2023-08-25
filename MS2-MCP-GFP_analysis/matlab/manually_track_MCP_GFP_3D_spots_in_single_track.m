function model = manually_track_MCP_GFP_3D_spots_in_single_track(IJM,experiment_folder,...
                worm_index,position, chop,track_ID)
%
%
% this function is for manually tracking the spots for a 3D movie with a track of a single
% nucleus,
% After this, you have to run 
% [spots, model] = calculate_MS2_traces_from_spot_tracks(IJM,experiment_folder, worm_index, curr_pos, curr_chop, track_ID)
%
%to obtain a structure called spots in a file called
%
% experiment_folder/worm_<worm_index>_straightened/Pos<position>/chop_<chop>/spots_track_<track_ID>.mat
% which can then be plotted etc.
%
% NOTE : Re-running the code on an existing nucleus will erase all mat
% files
%
%
%
% the function returns a spot structure containing the following elements
%
% spots.t ... frames in which an MCP-GFP spot was tracked
% spots.x ... x position of tracked MCP-GFP spot 
% spots.y ... y position of tracked MCP-GFP spot 
% spots.z ... z position of tracked MCP-GFP spot 
%
% spots.tt ... frames in which the nucleus containing the MCP-GFP spot was
%               tracked and spot intensity could be assigned, based on extrapolations
%               etc., use this for plotting
%
% spots.fg ... foreground values during spots.tt
% spots.bg ... background values during spots.tt
%
%
%
%
% For a first automatic spot detection round in TRACKMATE, use the LOGDetector and try these parameters
% 
%     spot_radius = 3; %pixels
%     
%     % track features
%     linking_max_distance = 5;
%     gap_closing_distance = 5;
%     gap_closing_frame_distance = 3;
%     
%     % TrackMate threshold for spot quality
%     spot_quality_threshold = 15;
%     spot_intensity_threshold = 160;
%
% Then add/remove spots and save the trackmate file under 
% pos_<POSITION>_chop_<CHOP>_trackID_<TRACK_ID>.xml' in the right
% chop_folder
% These trackmate files will then be used to calculate MS2 intensities
% in the function calculate_MS2_traces_from_spot_tracks.m
% 
%
%
%%%%%%%%%%%%%%%%%%% all code by Wolfgang Keil, Institut Curie
%
 
    import fiji.plugin.trackmate.* ;         
            
    slices = 15; % This the number of z-slices in the stack (IMPORTANT, THIS COMES FROM THE TRACKING AND RESAVING),
    xy_scale = 183.3333;% in nm
    z_scale = 500;% in n
        
    % Convert to pixel and set xy pixel size to 1
    z_scale = z_scale / xy_scale;
    
    track_index = [];  

    ilastik_prob_threshold = 0.6;
    
    
    ise = evalin( 'base', 'exist(''GFP_stack'',''var'') == 1' );
    if ise
        evalin('base', 'clear(''GFP_stack'')');
    end
    ise = evalin( 'base', 'exist(''mCherry_stack'',''var'') == 1' );
    if ise
        evalin('base', 'clear(''mCherry_stack'')');
    end
    
    ise = evalin( 'base', 'exist(''Ilastik_stack'',''var'') == 1' );
    if ise
        evalin('base', 'clear(''Ilastik_stack'')');
    end
   
   
    track_string = num2str(track_ID);
    track_string = [repmat('0', [1 4-length(track_string)]) track_string];
    

    % Check again if track really exists
    chop_folder = [experiment_folder 'worm_' num2str(worm_index) ...
        '_straightened/Pos' num2str(position) '/chop_' num2str(chop)];
    tmp = dir(chop_folder);
    ismatch = ~cellfun(@isempty, regexp({tmp(:).name},['track_' track_string], 'match', 'once')); 
    
    %%% No track files found
    if sum(ismatch) == 0
        disp(['Cannot find any files for track ' track_string '. Aborting MCP-GFP spot tracking for this nucleus.']);
        spots = [];
        segmented_nucleus = [];
     return;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    disp('Loading mCherry 3D-stack for this track');
    ij.IJ.run('Image Sequence...',...
        ['open=' experiment_folder 'worm_' num2str(worm_index) ...
        '_straightened/Pos' num2str(position) '/chop_' num2str(chop) ...
        '/mCherry_stack_stackreg.tif file=track_' track_string '_mCherry sort']);
        
    IJM.getDatasetAs('mCherry_stack');
    % If ImageJ is started outside in a function, the IJM, and MIJ
    % structures are only defined in the workspace, in this case, we
    % need to grab the stacks from there
    if ~exist('mCherry_stack', 'var')
        mCherry_stack = evalin('base', 'mCherry_stack');            
    end
    
    
    [~, ~, n_frames] = size(mCherry_stack);
    frames = n_frames/slices;
    mCherry_stack = reshape(mCherry_stack, [size(mCherry_stack,1),size(mCherry_stack,2), slices, frames ]);
    
    % Create the 4D stack 
    ij.IJ.run('Stack to Hyperstack...',['order=xyczt(default) channels=1 slices=' num2str(slices) ' frames=' ...
        num2str(frames) ' display=Grayscale']);  
    ij.IJ.selectWindow(['chop_' num2str(chop)]);
    ij.IJ.run('Rename...', 'title=mCherry_stack');

    % Set the properties of the stack in FIJI, these scales are taken into
    % account when running the spot detection and tracking
    ij.IJ.run('Properties...', ['channels=1 slices=' num2str(slices)...
        ' frames=' num2str(frames) ' pixel_width=1 pixel_height=1 voxel_depth=' ...
        num2str(z_scale) ' frame=[1 frame]']);
    

    %%%%%%%%%%%%%%%%% Load the GFP track %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ij.IJ.run('Image Sequence...',...
        ['open=' experiment_folder 'worm_' num2str(worm_index) ...
        '_straightened/Pos' num2str(position) '/chop_' num2str(chop) ...
        '/mCherry_stack_stackreg.tif file=track_' track_string '_GFP sort']);

    IJM.getDatasetAs('GFP_stack');
    % If ImageJ is started outside in a function, the IJM, and MIJ
    % structures are only defined in the workspace, in this case, we
    % need to grab the stacks from there
    if ~exist('GFP_stack', 'var')
        GFP_stack = evalin('base', 'GFP_stack');            
    end
    GFP_stack = reshape(GFP_stack, [size(GFP_stack,1),size(GFP_stack,2), slices, frames ]);
    
    % Create the 4D stack (over all times, and save it in a temporary file such
    % as to analyze it with Ilastik)
    ij.IJ.run('Stack to Hyperstack...',['order=xyczt(default) channels=1 slices=' num2str(slices) ' frames=' ...
        num2str(frames) ' display=Grayscale']);  
    ij.IJ.selectWindow(['chop_' num2str(chop)]);
    ij.IJ.run('Rename...','title=GFP_stack');
    
    % Set the properties of the stack in FIJI, these scales are taken into
    % account when running the spot detection and tracking
    ij.IJ.run('Properties...', ['channels=1 slices=' num2str(slices)...
        ' frames=' num2str(frames) ' pixel_width=1 pixel_height=1 voxel_depth=' ...
        num2str(z_scale) ' frame=[1 frame]']);
    
    %%%%%%%%%%%%%%%%% Load the Ilastik track %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ij.IJ.run('Image Sequence...',...
        ['open=' experiment_folder 'worm_' num2str(worm_index) ...
        '_straightened/Pos' num2str(position) '/chop_' num2str(chop) ...
        '/mCherry_stack_stackreg.tif file=track_' track_string '_Ilastik sort']);

    IJM.getDatasetAs('Ilastik_stack');
    % If ImageJ is started outside in a function, the IJM, and MIJ
    % structures are only defined in the workspace, in this case, we
    % need to grab the stacks from there
    if ~exist('Ilastik_stack', 'var')
        Ilastik_stack = evalin('base', 'Ilastik_stack');            
    end
    Ilastik_stack = reshape(Ilastik_stack, [size(Ilastik_stack,1),size(Ilastik_stack,2), slices, frames ]);
    
    % Create the proper 4D stack
    ij.IJ.run('Stack to Hyperstack...',['order=xyczt(default) channels=1 slices=' num2str(slices) ' frames=' ...
        num2str(frames) ' display=Grayscale']);  
    ij.IJ.selectWindow(['chop_' num2str(chop)]);
    ij.IJ.run('Rename...','title=Ilastik_stack');
    
    % Set the properties of the stack in FIJI, these scales are taken into
    % account when running the spot detection and tracking
    ij.IJ.run('Properties...', ['channels=1 slices=' num2str(slices)...
        ' frames=' num2str(frames) ' pixel_width=1 pixel_height=1 voxel_depth=' ...
        num2str(z_scale) ' frame=[1 frame]']);
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % Re-organize Ilastik stack such that dimensions match with the mCherry
    % and GFP stacks, also only considered the nucleus classification
    segmented_nucleus = Ilastik_stack > ilastik_prob_threshold*(2^8);

    % structuring element for nucleus dilation
    se  = strel('disk',3,6);

    
    for jj  = 1:size(segmented_nucleus,4) % go over all timepoints
        tmp = squeeze(segmented_nucleus(:,:,:,jj));
        
        % Find the connected components
        CC = bwconncomp(tmp);
        Cent=regionprops(CC,'Centroid');        
        tmp2 = zeros(size(tmp));
        
        if CC.NumObjects > 0
            % Delete everything but the largest connected component in the
            % stack, unless center of mass is too far away from the XY
            % center
            numOfPixels = cellfun(@numel,CC.PixelIdxList);
            % Sort the number of pixel list
            [numOfPixels,I] = sort(numOfPixels, 'descend');
            
            % Go over all connected components and pick the one that's
            % sufficiently large and in the center (normally, this will be
            % an easy choice)
            for i = 1:length(numOfPixels)
                if ((Cent(I(i)).Centroid(1) - size(tmp,1)/2)^2 + (Cent(I(i)).Centroid(2) - size(tmp,2)/2)^2) < 100
                        tmp2(CC.PixelIdxList{I(i)}) = 1;
                        break;
                end
            end
                        

            % Fill 2D holes in the nucleus (typically from nucleolus) 
            for ii=1:size(tmp2,3)
                tmp = imfill(squeeze(tmp2(:,:,ii)),'holes');
                % Take convex hull, because nuclei are normally convex,
                % non-convex nuclei come from underclassification
                tmp = bwconvhull(tmp,'union');
                % Dilate the nucleus in xy (NOT Z)!! and assign to the array
                % segmented_nucleus
                tmp2(:,:,ii) = imdilate(tmp, se);
            end
            figure(10);
            set(gcf, 'Name', num2str(jj));
            imagesc(sum(tmp2,3));
            drawnow;
            pause(0.1);
            
            segmented_nucleus(:,:,:,jj) = tmp2;
        else
            disp('Something is odd with this Ilastik probability map. No nucleus in it.');            
        end
    end
    

    if isempty(find(segmented_nucleus > 0,1))
        disp('Something is odd with this Ilastik probability map. No nucleus in it.');
        spots = [];
        segmented_nucleus = [];
        return;
    end

     %%%%%%%%%%%%%%% RUN THE ACTUAL MANUAL TRACKING
    model = perform_manual_MS2_spot_tracking(experiment_folder,...
                                        worm_index,position, chop,track_ID,slices, frames,z_scale);
    %----------------
    % Display results
    %----------------

    
   % ij.IJ.run('Close All');
    
end


