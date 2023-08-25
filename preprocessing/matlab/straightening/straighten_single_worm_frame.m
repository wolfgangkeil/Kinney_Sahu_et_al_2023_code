%function straighten_single_auto_frame(experiment_folder, worm_index,...
%            frame_index, trigger_channel, channels2align,channel_names, overwrite, AP_padd_size, positions)
%
% ---------------------------------------------------------------------
% DESCRIPTION: 
%
%
% ---------------------------------------------------------------------
%
%
% INPUTS 
% experiment_folder ... folder name of the original experiment
% worm_index ... index of the worm to be straightened and aligned
% frame_index ... time frame of worm to be straightened
%
% trigger_channel ... a channel NUMBER! 
%
% channels2align ... other channel numbers that you want straightened, DO NOT INCLUDE THE TRIGGER CHANNEL HERE AGAIN!

% channel_names ... this tells how to translate nikons channel numbers into names
%                           e.g {'DICIII', 'GFP','mCherry'}
%

% AP_padd_size ... choose 3500 for instance if you want to keep the entire
% worm even in the 
%
%
%   Wolfgang Keil, Institut Curie 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function straighten_single_worm_frame(experiment_folder, worm_index,...
            frame_index, trigger_channel, channels2align,channel_names,overwrite,AP_padd_size,positions,Path2Ilastik)
    
    K_factor = 1;
    bit_depth = 16;
    
    new_DV_size = 150;
    new_z_size = 25;
    
    if bit_depth ==8
        baseline_subtraction = 90; % this value is subtracted from the images before saving them in 8 bit;
    else
        baseline_subtraction = 0;
    end
    

    % FLAGS, TO DETERMINE WHICH PART OF THE PIPELINE IS EXECUTED
    % IF SET TO ZERO, THE FILES ARE ASSUMED TO EXIST AND ARE LOADED
    % If THEY ARE NOT FOUND, COMPUTATION IS PERFORMED ANYWAYS
    %
    
    perform_midline_computation = 1;
    perform_straightening = 1;    

    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder = [experiment_folder '/'];
    end
 
    disp('-----------------------------------------------------------');
    
    disp(['Performing straightening and alignment for worm ' num2str(worm_index) ' frame ' num2str(frame_index) ' ...']);
    disp(['The following steps are being executed:']);
    
    task_index = 1;
    
    if perform_midline_computation
        disp([num2str(task_index) '. Automatic midline detection '])
        task_index = task_index + 1;
    end
    
    
    if perform_straightening
        disp([num2str(task_index) '. Straightening'])
        task_index = task_index + 1;
    end
    disp('-----------------------------------------------------------');

    % Generate the timestamp_string based on the frame index (used for naming files later)
    timestamp_string = num2str(frame_index);
    timestamp_string = [repmat('0', [1 9-length(timestamp_string)]) timestamp_string];
    
    
    % Set options for saving tiffs
    options.overwrite = true;
    
    % this is for the GPF, mCherry channel
       
    if ~exist( [experiment_folder 'worm_' num2str(worm_index) '_straightened/'], 'dir')
        mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/']);
        for ii = 0:(length(positions)-1)
            mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/']);
            mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/' channel_names{trigger_channel} '/']);
            for kk=1:length(channels2align)
                mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/' channel_names{channels2align(kk)} '/']);
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%% DO THIS FOR ALL POSITIONS IN THE STACK
    for ii = 0:(length(positions)-1)
        disp('##################################################');        
        disp(['Processing position ' num2str(ii)]);
        
         straightened_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/'];

        % load original trigger stack
        disp('Loading trigger stack to straighten...');
        
        trigger_stack = load_original_frame_nikon([experiment_folder 'raw_data/'],positions(ii+1), frame_index,trigger_channel);
        %trigger_stack = load_cropped_frame([experiment_folder 'worm_' num2str(worm_index) '/Pos' num2str(ii) '/'] ,frame_index,trigger_channel);

        if isempty(trigger_stack)
            warning('Could not find file for trigger stack. No midline finding or straightening can be done');        
            disp('Will not perform any further analysis steps.');
            disp('All done!');
            disp('-----------------------------------------------------------');
            return;
        end

        %%% Generate the midlines to a .mat file
        midline_file = [straightened_folder channel_names{trigger_channel} ...
            '/midlines_' num2str(frame_index) '_auto.mat'];

        if perform_midline_computation || ~exist(midline_file, 'file') || overwrite
            % Recompute the midline
            % Get prior midline to avoid AP-DV flip
            prior_midline = get_prior_midline(straightened_folder, channel_names{trigger_channel}, frame_index);
            
            disp('Computing midline')
            
            %auto_midline = compute_single_frame_midline_nikon_skel(trigger_stack, K_factor, 1);
            [auto_midline, img] = compute_single_frame_midline_nikon_skel([experiment_folder 'tmp/'],...
                                    frame_index, trigger_stack, channel_names{trigger_channel},Path2Ilastik, 0, prior_midline);

            %%% save the midlines to a .mat file
            midline_file = [straightened_folder channel_names{trigger_channel} ...
                '/midlines_' num2str(frame_index) '_auto.mat'];

            save(midline_file, 'auto_midline', 'img');

        else
            % load the midline
            tmp = load(midline_file, 'auto_midline', 'img');
            auto_midline = tmp.auto_midline;
%             
%             if ~isempty(auto_midline)
%                 % Plot the midline
%                 figure(ii+1)
%                 hold on;
%                 plot(auto_midline(:,2), auto_midline(:,1));
%             end
        end

        if perform_straightening
                        
            if isempty(auto_midline)
                %%% This happens, if the positions doesn't contain a worm, in this case, just fill a matrix with zeros                           
                straightened_trigger = zeros(2*new_DV_size+1,AP_padd_size,2*new_z_size);
                straightened_channels = zeros(2*new_DV_size+1,AP_padd_size,2*new_z_size,length(channels2align));
                disp('No worm found in this position ... ')    
                               
            else     
                
                % load other channels to straighten
                disp('Loading channels to straighten...');
                for kk=1:length(channels2align)

                    tmp = load_original_frame_nikon([experiment_folder 'raw_data/'],positions(ii+1),...
                                    frame_index,channels2align(kk));


    %                 tmp = load_cropped_frame([experiment_folder 'worm_' num2str(worm_index) '/Pos' num2str(ii) '/'], ...
    %                         frame_index,channel_names{channels2align{kk}});                

                    if ~isempty(tmp)
                        % store everything in one array
                        channel_images(:,:,:,kk) = tmp;
                    else
                        warning(['Cannot find data for channel '  num2str(channels2align(kk))  ')' ]);
                        warning('Cannot perform any calculation?');
                        return;
                    end        
                    %Return an error if sizes of trigger stack and channel images don't
                    %match
                    if sum(size(squeeze(channel_images(:,:,:,1))) == size(trigger_stack)) ~= 3
                        warning('Sizes of trigger stack and other channels do not match!');
                        warning('Cannot perform any calculation. Are the files misnamed??');
                        return;
                    end
                end
                disp('...done');


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [points_x, points_y] ...
                        = compute_straightening_interpolation_points(auto_midline, new_DV_size);

                [straightened_trigger, straightened_channels, sample_points_x,sample_points_y,sample_points_z]  = ...
                    interpolate_stacks_for_straightening(trigger_stack,channel_images,img, points_x, points_y,auto_midline, ...
                                    new_z_size, AP_padd_size);
                                
                
%                 saveastiff(uint16(sample_points_x),  [straightened_folder channel_names{trigger_channel} ...
%                     '/sample_points_x_' num2str(frame_index) '.tif'], options);
%                 
%                 saveastiff(uint16(sample_points_y),  [straightened_folder channel_names{trigger_channel} ...
%                     '/sample_points_y_' num2str(frame_index) '.tif'], options);
%                 
%                 saveastiff(uint16(sample_points_z),  [straightened_folder channel_names{trigger_channel} ...
%                     '/sample_points_z_' num2str(frame_index) '.tif'], options);
                
            end
            
            disp('Saving the straightened channels as tiff-files ... ')    
            save_tiff_frame(straightened_trigger-baseline_subtraction,experiment_folder, ii,'straightened','',...
                worm_index, frame_index,channel_names{trigger_channel},bit_depth, options,'clipped');

            % Save the other channels
            for kk=1:length(channels2align)
                save_tiff_frame(squeeze(straightened_channels(:,:,:,kk))- baseline_subtraction,experiment_folder, ii,'straightened','',worm_index,...
                        frame_index,channel_names{channels2align(kk)},bit_depth,options,'clipped');

            end           
            disp('...done');
            disp('---------------------------------------------------------')
        end
    end
end

function prior_midline = get_prior_midline(straightened_folder, trigger_channel, frame_index)

    ii = frame_index;
    prior_midline = [];
    
    while ii > 0
        ii = ii-1;
        %%% save the midlines to a .mat file
        prior_midline_file = [straightened_folder trigger_channel ...
            '/midlines_' num2str(ii) '_auto.mat'];

        if exist(prior_midline_file,'file')
            tmp = load(prior_midline_file, 'auto_midline', 'img');
            prior_midline = tmp.auto_midline;
            break;
        end
    end

end