function process_nuclear_tracking(experiment_folder, worm_index, curr_pos, curr_chop, model, no_slices, z_scale)
%
% this function generates the individual track tifs for the nuclei, based
% on a TrackMateModel input in the variable model
%
% After that you need to manually track the MS2 dots with trackmate and then run 
% calculate_all_single_worm_MS2_traces(<<experiment_folders>>)    
% plot_MS2_traces_all_nuclei_single_worm(<<experiment_folders>>);   
% To actually see the MS2 traces of each worm
%%
%
%
%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2022

    options.overwrite = 1; % this is the saveastiff option        
    nucleus_crop_size_xy = 18; % cropped stacks for individual nuclei will be twice this width
    nucleus_crop_size_z = round(nucleus_crop_size_xy/z_scale); % cropped stacks for individual nuclei will be twice this width
    
    min_track_length = 0.5; %% only take nuclei that were present at least half the time during the experiment


    chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];
            
            

    % Check the the manual registration has actually been done for
    % this chop
    if exist([chop_folder 'chop_' num2str(curr_chop) '_stack_t_1.tif'],'file')      

         % Delete old track files, AND spot tracking files before creating new ones
        disp('Deleting old track .tif and .mat files...');
        filenames = dir(chop_folder);
        for ii = 1:length(filenames)
            if ~isfolder([chop_folder '/' filenames(ii).name])
                if contains(filenames(ii).name, '.tif') && ... 
                    contains(filenames(ii).name, 'track_') && ...
                        contains(filenames(ii).name, '_frame_')
                    delete([chop_folder '/' filenames(ii).name]);
                end
                % Also delete the mat files, they are going to be created again
                if contains(filenames(ii).name, '.mat') && ... 
                    contains(filenames(ii).name, 'track_')
                    delete([chop_folder '/' filenames(ii).name]);             
                end
                % Also delete the spot mat files, because, otherwise they won't
                % match the tracks (track indices change, if tracking is run
                % another time for some reason
                if contains(filenames(ii).name, '.mat') && ... 
                    contains(filenames(ii).name, 'spots_track_')
                    delete([chop_folder '/' filenames(ii).name]);             
                end
            end
        end



        %%%%%%%%%%%%%%%%% Load ilastik stack and mCherry and
        %%%%%%%%%%%%%%%%% GFP stacks into MATLAB
        Ilastik_stack = loadtiff([chop_folder 'mCherry_stack_stackreg_Probabilities.tiff']);
        no_frames = size(Ilastik_stack,3)/no_slices;
        Ilastik_stack = reshape(Ilastik_stack, [size(Ilastik_stack,1) size(Ilastik_stack,2) no_slices, no_frames]);                    

        min_track_length = no_frames * min_track_length;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

        % open the mCherry and GFP channel images
        % Load the GFP and mCherry channel
        disp('Loading registered GFP and mCherry stacks...')
        mCherry_stack = loadtiff([chop_folder 'mCherry_stack_stackreg.tiff']);
        mCherry_stack = reshape(mCherry_stack, [size(mCherry_stack,1) size(mCherry_stack,2), no_slices, no_frames]);                    
        GFP_stack = loadtiff([chop_folder 'GFP_stack_stackreg.tiff']);
        GFP_stack = reshape(GFP_stack, [size(GFP_stack,1) size(GFP_stack,2), no_slices no_frames]);                    


        % Swapping the indices of the Ilastik stack
        %Ilastik_stack = permute(Ilastik_stack, [2,1,3]);

        disp('Sizes');
        size(GFP_stack);
        size(mCherry_stack);
        size(Ilastik_stack);

        disp('Saving individual track .tif files for later spot tracking. This typically takes a while....');

        %%%% Now go over all the tracks, 
        fm = model.getFeatureModel();
        trackIDs = model.getTrackModel().trackIDs(true);

        % Get the chop time, we need this to translate the track
        % indices to chop indices
        chop_time = get_chop_timepoints(experiment_folder, worm_index, curr_pos, curr_chop);

        valid_track_IDs = [];

        trackID_iterator = trackIDs.iterator; 

        while(trackID_iterator.hasNext())
            id  = trackID_iterator.next();

            vt = fm.getTrackFeature(java.lang.Integer(id),'TRACK_DURATION');
            
            if double(vt) >= min_track_length

                posx = [];
                posy = [];
                posz = [];
                frames = [];

                track_string = num2str(id);
                track_string = [repmat('0', [1 4-length(track_string)]) track_string];

                disp(['     Processing track ' num2str(id) ' ... ']);
                track = model.getTrackModel().trackSpots(java.lang.Integer(id));
                iterator = track.iterator();
                counter = 0;

                disp(['         Track ' num2str(id) ' has a duration of ' num2str(string(vt))]);


                while(iterator.hasNext())
                    spot = iterator.next();
                    sid  = spot.ID();
                    % Fetch spot features directly from spot.
                    x = spot.getFeature('POSITION_X').doubleValue + 1;
                    y = spot.getFeature('POSITION_Y').doubleValue + 1;
                    z = spot.getFeature('POSITION_Z').doubleValue + 1;
                    t = spot.getFeature('FRAME').doubleValue;
 
                    posx = [posx, x];
                    posy = [posy, y];
                    posz = [posz, z/z_scale];
                    frames = [frames,t];

                    % now crop the image around the nucleus
                    centx = round(x);
                    centy = round(y);
                    centz = round(z/z_scale);

                    counter = counter + 1;

                    t_string = num2str(t);
                    t_string = [repmat('0', [1 4-length(t_string)]) t_string];

                    % Extrac the relevant Ilastik stack, crop it and resave		
                    cropped_slice = crop_nuclear_box(squeeze(Ilastik_stack(:,:,:,t+1)),...
                                        centx, centy,centz, nucleus_crop_size_xy,nucleus_crop_size_z);
                    saveastiff(uint16(cropped_slice), [chop_folder 'track_' track_string '_Ilastik_frame_3D' t_string '.tif'],options);

                    % Extrac the relevant mCherry stack, crop it and resave		
                    cropped_slice = crop_nuclear_box(squeeze(mCherry_stack(:,:,:,t+1)),...
                                        centx, centy,centz, nucleus_crop_size_xy,nucleus_crop_size_z);
                    saveastiff(uint16(cropped_slice), [chop_folder 'track_' track_string '_mCherry_frame_3D' t_string '.tif'],options);

                    % Extrac the relevant GFP stack, crop it and resave		
                    cropped_slice = crop_nuclear_box(squeeze(GFP_stack(:,:,:,t+1)),...
                                        centx, centy,centz, nucleus_crop_size_xy,nucleus_crop_size_z);
                    saveastiff(uint16(cropped_slice), [chop_folder 'track_' track_string '_GFP_frame_3D' t_string '.tif'],options);
                end

                track_stats.posx = posx;
                track_stats.posy = posy;
                track_stats.posz = posz;
                track_stats.frames = frames;

                valid_track_IDs = [valid_track_IDs, id];

                save([chop_folder '/track_' track_string '.mat'], 'track_stats');
                disp('        Done. ');
            end
        end

        disp('done.');
        ij.IJ.close('*');

    end
end




%%%%%%%%%%%%%%%%%%%%%%
function stack = crop_nuclear_box(stack,posx, posy,posz, crop_size_xy, crop_size_z)
    %cropped_slice = zeros(2*crop_size+1);
    
    lower_x = max((posx-crop_size_xy), 1);
    lower_y = max((posy-crop_size_xy), 1);
    lower_z = max((posz-crop_size_z), 1);
    
    upper_x = min((posx+crop_size_xy), size(stack,2));
    upper_y = min((posy+crop_size_xy), size(stack,1));
    upper_z = min((posz+crop_size_z), size(stack,3));

    try
     stack = stack(lower_y:upper_y, lower_x:upper_x, lower_z:upper_z);
    catch
        stack;
    end

    if size(stack,2) < 2*crop_size_xy+1
        pad_size_x = 2*crop_size_xy+1 - size(stack,2);
    else
        pad_size_x = 0;
    end
        
    if size(stack,1) < 2*crop_size_xy+1
        pad_size_y = 2*crop_size_xy+1 - size(stack,1);
    else
        pad_size_y = 0;
    end
    
    if size(stack,3) < 2*crop_size_z+1
        pad_size_z = 2*crop_size_z+1 - size(stack,3);
    else
        pad_size_z = 0;
    end
    
    
    stack = padarray(stack, [floor(pad_size_y/2), floor(pad_size_x/2),floor(pad_size_z/2)], 'pre');
    stack = padarray(stack, [ceil(pad_size_y/2), ceil(pad_size_x/2),ceil(pad_size_z/2)], 'post');
    
    
end

