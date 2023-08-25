function [spots, model] = calculate_MS2_traces_from_spot_tracks(IJM,experiment_folder, ...
                                        worm_index, curr_pos, curr_chop, track_ID)
%
%
%
% THIS function returns a spot structure containing the following elements
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
% it also returns the trackmate model that was generated during tracking of
% the spots

%%%%%%%%%%%%%%%%%%%all code by Wolfgang Keil, Institut Curie, 2022
%
%
    import fiji.plugin.trackmate.* ; 
    import fiji.plugin.trackmate.io.* ; 
    import java.io.File;
    import fiji.plugin.trackmate.gui.displaysettings.*;   
    import fiji.plugin.trackmate.visualization.hyperstack.*

    spots = {};
    
    no_slices = 15;
    xy_scale = 183.3333;% in nm
    z_scale = 500;% in n
        
    % Convert to pixel and set xy pixel size to 1
    z_scale = z_scale / xy_scale;
    xy_scale = 1;
    default_spot_radius = 2; % only used during extrapolation
    
    
    track_index = [];

    min_track_intensity = 100;
    min_track_length = 3;
    
    
    extrapolation_window = 20; % Has to be positive integer, 
                               % this parameter fixes the NUMBER OF FRAMES before the first tracked spot and the last tracked spot we want to 
                               % extrapolate the data, 
                               % If you choose zero, the intensity is only calculated for the spots that are tracked
                               % For values larger than zero lead to 
                               % 
    
    
    trackID_string = num2str(track_ID);
    trackID_string = [repmat('0', [1 4-length(trackID_string)]) trackID_string];    


            
    chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                num2str(curr_pos) '/chop_' num2str(curr_chop)];
            
    %%%% This is the trackmate model file for the spots in this nucleus
    trackmate_modelFile = [chop_folder '/pos_' num2str(curr_pos) '_chop_' num2str(curr_chop) '_trackID_' trackID_string '.xml'];
    
    if exist(trackmate_modelFile, 'file')        
        file = File(trackmate_modelFile);

        reader = TmXmlReader(file);

        if ~(reader.isReadingOk)
            disp('Cannot read the xml-file');
            model = {};
            return;
        else
            model = reader.getModel();      
            display(model.toString());        
        end   
    else
            model = {};
            return;        
    end
    
    
    % Find frames that are to be ignored, because tracking gone awry
    track_delete_filename = ['pos_' num2str(curr_pos) '_chop_' num2str(curr_chop) '_trackID_' trackID_string '_frames2delete.txt'];

    if exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                 num2str(curr_pos) '/chop_' num2str(curr_chop) '/' track_delete_filename], 'file')   
             
        disp(['      Reading frame2delete.txt file for track' trackID_string '...']);
        fid = fopen([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                 num2str(curr_pos) '/chop_' num2str(curr_chop) '/' track_delete_filename]);

        frames2ignore = fscanf(fid, '%d');
        fclose(fid);
    else
        frames2ignore = [];
    end
  


    if ~isempty(model)
        
        GFP_stack = load_GFP_stack(IJM,chop_folder, curr_chop,trackID_string,no_slices);   
        
        %%%% First create a mask file with the all the dot positions, this
        %%%% will be used to avoid including dots that are a too close in
        %%%% the background region
        
        fg_map = generate_foreground_map(GFP_stack, model,frames2ignore,z_scale,default_spot_radius);
          
        no_trackIDs = model.getTrackModel().trackIDs(true).size;
        if no_trackIDs > 0

            trackIDs = model.getTrackModel().trackIDs(true);
            trackID_iterator = trackIDs.iterator; 

            % loop over all tracks
            while(trackID_iterator.hasNext())
                id  = trackID_iterator.next();
                track = model.getTrackModel().trackSpots(java.lang.Integer(id));
                iterator = track.iterator();

                x=[];
                y=[];
                z=[];
                t=[];
                r=[];
                max_intensity = [];
                total_intensity = [];
                
                % loop over all spots in a track
                while(iterator.hasNext())
                    spot = iterator.next();
                    %sid  = spot.ID();
                    % Fetch spot features directly from spot, 
                    % NOTE: x and y coordinates are inverted compared to MATLAB
                    
                    if isempty(find(frames2ignore == (spot.getFeature('FRAME').doubleValue+1),1))
                        % , also get frames for later parsing
                        y = [y, spot.getFeature('POSITION_X').doubleValue+1];
                        x = [x, spot.getFeature('POSITION_Y').doubleValue+1];
                        z = [z, spot.getFeature('POSITION_Z').doubleValue/z_scale+1];
                        t = [t,spot.getFeature('FRAME').doubleValue+1];   
                        r = [r, spot.getFeature('RADIUS').doubleValue];
                    end

                end

                spot_intensity = [];
                for jj = 1:length(t)
                    % find spot intensity
                    spot_intensity = [spot_intensity, calculate_MS2_spot_intensity(squeeze(GFP_stack(:,:,:,t(jj))),x(jj),y(jj),z(jj),squeeze(fg_map(:,:,:,t(jj))),default_spot_radius)];
                end            

                % Count the number of time points in which the MCP-GFP spot of
                % this track was outside of the nucleus
                if length(t) > min_track_length
                    % Excludes tracks that are too dim (this threshold is
                    % actually very low!, most tracks will pass this)              
                    if max(spot_intensity) > min_track_intensity
                        % timepoints are unsorted that way, so need to sort and
                        % the store everything in the spots structure
                        [t,I] = sort(t);

%                         %%% Plot the calculcated trace, without extrapolation
%                         figure(10)
%                         plot(t,spot_intensity(I));
%                         xlabel('frame');
%                         ylabel('Intensity [UA]');


                        track_index = [track_index,id];

                        spots.trackindex{length(track_index)} = id;
                        spots.t{length(track_index)} = t; % is already sorted
                        spots.x{length(track_index)} = x(I); % is sorted here
                        spots.y{length(track_index)} = y(I); % is sorted here
                        spots.z{length(track_index)} = z(I); % is sorted here
                        spots.total_intensity{length(track_index)} = spot_intensity(I); % is sorted here
    % 
                    end
                end
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%% NOW EXTRAPOLATE THE TRACES         
    if ~isempty(spots)

        disp('Extrapolating traces....');
         %%% GO OVER ALL THE FRAMES THAT ARE ACTUALLY
         %%% PART OF THE NUCLEUS TRACK
         load([chop_folder '/track_' trackID_string '.mat'],'track_stats'); 
        % this loads a variable track_stats which contains the info about
        % nucleus position

        % Sort the frames of the nucleus first, this way the third dimension
        % of the GFP_stacks, Ilastik_stacks etc. corresponds to these times
        % this index correspongs 
        sorted_frames = sort(track_stats.frames) + 1;

        for jj = 1:length(spots.t) % loop over all the MCP-spot tracks

            min_t = min(sorted_frames(spots.t{jj}));
            max_t = max(sorted_frames(spots.t{jj}));
            tmp_spot_intensity = [];
            tt = [];

            for ii = 1:length(sorted_frames) %% THIS LOOP GOES OVER NUCLEUS TRACK FRAMES, IN TEMPORAL ORDER!! 

                img = squeeze(GFP_stack(:,:,:,ii)); % The saved track frames 
                fg = squeeze(fg_map(:,:,:,ii));
                % Calculate the intensity of the spot location, starting 10 frames before first detection                    
                if sorted_frames(ii) >= min_t-extrapolation_window && sorted_frames(ii) < min_t && ...
                    isempty(find(frames2ignore == ii,1))
                    
                    spot_posx = spots.x{jj}(1);
                    spot_posy = spots.y{jj}(1);
                    spot_posz = spots.z{jj}(1);
                    spot_intensity = calculate_MS2_spot_intensity(img,spot_posx,spot_posy,spot_posz,fg,default_spot_radius);

                    tmp_spot_intensity = [tmp_spot_intensity,spot_intensity];
                    tt = [tt, sorted_frames(ii)];      

                elseif sorted_frames(ii) >= min_t && sorted_frames(ii) <= max_t && ...
                        isempty(find(frames2ignore == ii,1))

                    if ismember(ii,spots.t{jj})
                        % this means we detected an MS2 spot at that frame
                        tmp_spot_intensity = [tmp_spot_intensity,spots.total_intensity{jj}(find(spots.t{jj} == ii,1))];
                        tt = [tt, sorted_frames(ii)];      
                    else
                        % this means we didn't detect the spot, then we
                        % take the position of the spots in last frame in
                        % which we detected the spot before this one and
                        % and find the spot intensity by Gaussian fit
                        iind = find(spots.t{jj}> sorted_frames(ii),1);

                        spot_posx = spots.x{jj}(iind);
                        spot_posy = spots.y{jj}(iind);
                        spot_posz = spots.z{jj}(iind);
                        spot_intensity = calculate_MS2_spot_intensity(img,spot_posx,spot_posy,spot_posz,fg,default_spot_radius);

                        tmp_spot_intensity = [tmp_spot_intensity,spot_intensity];
                        tt = [tt, sorted_frames(ii)];      

                    end

                elseif sorted_frames(ii) > max_t && sorted_frames(ii) < max_t+extrapolation_window && ...
                        isempty(find(frames2ignore == ii,1))

                    % Calculcate the intensity of the spot location, until 10 frames after last detection
                    % Define a region around the last recorded spot location and
                    % take the max intensity in this region for the last
                    % 10 frames
                    spot_posx = spots.x{jj}(end);
                    spot_posy = spots.y{jj}(end);
                    spot_posz = spots.z{jj}(end);
                    [spot_intensity ] = calculate_MS2_spot_intensity(img,spot_posx,spot_posy,spot_posz,fg,default_spot_radius);

                    tmp_spot_intensity = [tmp_spot_intensity,spot_intensity];
                    tt = [tt, sorted_frames(ii)];      
                end
            end

            % Remove the spot intensity NANs from x,y,z, t    
            % this is where the Gaussian fit didn't converge
            tt(isnan(tmp_spot_intensity)) = [];
            tmp_spot_intensity(isnan(tmp_spot_intensity)) = [];

            spots.fg{jj} = tmp_spot_intensity;
            spots.bg{jj} = zeros(size(tmp_spot_intensity)); % This is artificially assigning a background, so that we can use our old plotting routines
            spots.tt{jj} = tt;
        end

        disp('Done....');

    else
        pause(1);
        disp('No valid MCP tracks found for this nucleus. Cannot create intesity profiles over times.');
    end

    save([chop_folder '/spots_track_' trackID_string '.mat'], 'spots');

end



%==============================================================================================
function spot_intensity = calculate_MS2_spot_intensity(stack, x,y,z, fg_map, spot_radius)
%
%
%
% Extraction of the MS2 intensity requires computation of the local
% background and foreground
% If the signal was good enough, we'd do a fit Gaussian fit of the spot and
% take the offset parameter as background
% however, these values fluctuated way too much
% So, we use the Gaussian fit only to estimate the position of the Gaussian
% after z-projection, background and foreground are then calculated using a
% mask created from the spot radius. Everything inside the spot radius is
% foreground, outside is background
%
%
%

    crop_size = max(round(1.5*spot_radius),4); 
    crop_size_z = 2;% this should probably be adjusted
    zspotrange = 1; % Range within which max z projection should be performed (plus and minus zspotrange)
    
    lower_x = max((round(x)-crop_size), 1);
    lower_y = max((round(y)-crop_size), 1);
    lower_z = max((round(z)-crop_size_z), 1);
    
    upper_x = min((round(x)+crop_size), size(stack,2));
    upper_y = min((round(y)+crop_size), size(stack,1));
    upper_z = min((round(z)+crop_size_z), size(stack,3));
    
    %%%%%% FIRST INDEX IS Y, second index is X!!!
    tmp = stack(lower_y:upper_y, lower_x:upper_x, lower_z:upper_z);
    tmp_fg_map = fg_map(lower_y:upper_y, lower_x:upper_x, lower_z:upper_z);
    
    k= find(tmp == max(tmp(:)),1);
   
    [xx, yy] = meshgrid(1:size(tmp,2),1:size(tmp,1)); 

    xx = xx - (crop_size+1);
    yy = yy - (crop_size+1);

    % Creates a foreground and a background mask
    fg = (xx.^2 + yy.^2) <= spot_radius^2;
    bg = ((xx.^2 + yy.^2) > 1.5.^2*spot_radius^2) & ((xx.^2 + yy.^2) <= 2.5^2*spot_radius^2);
    ttmp = max(tmp,[],3);  
    ttmp_fg_map = max(tmp_fg_map,[],3);  
    
    %%% Background cant contain any of the foregrounds determined earlier,
    %%% so that it doesn't get too close to another dot
    bg(ttmp_fg_map>0) = 0;
    
    bg_value = sum(bg(:).*ttmp(:))/sum(bg(:));
    spot_intensity = sum(fg(:).*(ttmp(:) - bg_value));

end

function GFP_stack = load_GFP_stack(IJM,chop_folder, curr_chop,track_string,no_slices)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Loading mCherry 3D-stack for this track');
    ij.IJ.run('Image Sequence...',...
        ['open=' chop_folder  '/mCherry_stack_stackreg.tif file=track_' track_string '_GFP sort']);

    IJM.getDatasetAs('GFP_stack');
    % If ImageJ is started outside in a function, the IJM, and MIJ
    % structures are only defined in the workspace, in this case, we
    % need to grab the stacks from there
    if ~exist('GFP_stack', 'var')
        GFP_stack = evalin('base', 'GFP_stack');            
    end


    [~, ~, n_frames] = size(GFP_stack);
    frames = n_frames/no_slices;
    GFP_stack = reshape(GFP_stack, [size(GFP_stack,1),size(GFP_stack,2), no_slices, frames ]);

    %%% Close the imageJ window
    ij.IJ.selectWindow(['chop_' num2str(curr_chop)]);
    ij.IJ.run('Close');


end

function fg_map = generate_foreground_map(GFP_stack, model,frames2ignore,z_scale, spot_avoid_radius)

    fg_map = zeros(size(GFP_stack));

    
    [XX,YY,ZZ] = meshgrid(1:size(GFP_stack,2),1:size(GFP_stack,1),1:size(GFP_stack,3));
    
    no_trackIDs = model.getTrackModel().trackIDs(true).size;
    if no_trackIDs > 0

        trackIDs = model.getTrackModel().trackIDs(true);
        trackID_iterator = trackIDs.iterator; 

        % loop over all tracks
        while(trackID_iterator.hasNext())
            id  = trackID_iterator.next();
            track = model.getTrackModel().trackSpots(java.lang.Integer(id));
            iterator = track.iterator();

            x=[];
            y=[];
            z=[];
            t=[];
            
            % loop over all spots in a track
            while(iterator.hasNext())
                spot = iterator.next();
                %sid  = spot.ID();
                % Fetch spot features directly from spot, 
                % NOTE: x and y coordinates are inverted compared to MATLAB

                if isempty(find(frames2ignore == (spot.getFeature('FRAME').doubleValue+1),1))
                    % , also get frames for later parsing
                    y = [y, spot.getFeature('POSITION_X').doubleValue+1];
                    x = [x, spot.getFeature('POSITION_Y').doubleValue+1];
                    z = [z, spot.getFeature('POSITION_Z').doubleValue/z_scale+1];
                    t = [t,spot.getFeature('FRAME').doubleValue+1];   
                end
            end
            %%%%% Creates an array with ones wherever spots are
            for jj = 1:length(t)
                
                tmp  = zeros(size(XX));
                tmp((XX-x(jj)).^2 + (YY-y(jj)).^2 + (ZZ-z(jj)).^2<=(1.5*spot_avoid_radius).^2)  = 1;
                fg_map(:,:,:,t(jj)) = fg_map(:,:,:,t(jj)) + tmp;
            end            
            
            
        end
    end
end