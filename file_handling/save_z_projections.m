function save_z_projections(experiment_folder, worm_index,channel)
%
% DESCRIPTION
% This function saves low-resolution mean z projections of each frame in
% the frame range using a FIJI macro, these are used to detect the worm (ilastik classifier)
% and to calculate fluorescence values later (Matlab)
%
%
%
% INPUT PARAMETERS
% experiment folder ... string with folder name
% worm_index ... number between 1 and 10
% channel ... string with channel name ('GFP' etc.)
%
% OUTPUT PARAMETERS
% N/A
%
% see also: analyze_worm_fluorescence_ilastik.m
%
% coded by Wolfgang Keil, The Rockefeller University, 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~exist(experiment_folder, 'dir')
        disp('experiment_folder doesn''t exist');
        return;
    end

    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder = [experiment_folder '/'];
    end
    
    tmp_ind = strfind(experiment_folder, '/');
    folder_name = experiment_folder(tmp_ind(end-1)+1:tmp_ind(end)-1);
    
    % Create new directories, if they don't already 
    if ~exist([experiment_folder 'Pos0/GFP'], 'dir')
        mkdir([experiment_folder 'Pos0/GFP']);
    end

    % Create new directories, if they don't already 
    if ~exist([experiment_folder 'Pos0/mCherry'], 'dir')
        mkdir([experiment_folder 'Pos0/mCherry']);
    end
    
    % First execute the macro to stitch the very first frame, 
    % use the output to generate parameters for the other stitchings, which will then be used for all other frames
    
    
    if ismac
        fiji_exec = '/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx --headless -macro ';
        macro_file = '/Users/wolfgang/Curie/fiji/save_z_projections.ijm';
    else
        fiji_exec = '/home/keil-workstation/Desktop/Apps/Fiji --headless -macro ';
        macro_file = '/home/keil-workstation/Desktop/Wolfgang/fiji/save_z_projections.ijm';
    end
    

    worm_pos_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos0/'];
    
    
    disp(['Saving projections with Fiji for experiment ' experiment_folder '...']);
    disp(['worm  ' num2str(worm_index) '...']);
    
    if exist(worm_pos_folder, 'dir')
        frame_range_intervals = [1 110];
        %[frame_range_intervals] = get_frame_range(worm_pos_folder, worm_index);
        %[no_slices,~] = get_timelapse_dimensions_cropped_data(worm_pos_folder);
        
        % do it in pieces to cover the whole frame range
        for jj = 1:length(frame_range_intervals)/2
            t1 = frame_range_intervals(2*jj-1);
            t2 = frame_range_intervals(2*jj);
            
            % construct the fiji command
            command = [fiji_exec macro_file ' "experiment_folder=' ...
                experiment_folder ' worm_index=' num2str(worm_index) ...
                ' channel=' channel ' t1=' num2str(t1) ' t2=' num2str(t2) '"' ];
            
            % Execute the fiji command
            system(command);
        end

    else
       disp('The worm folder doesn''t exist. Wrong directory?');
    end
    
end


