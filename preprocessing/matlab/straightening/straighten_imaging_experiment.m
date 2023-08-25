function straighten_imaging_experiment(experiment_folder, trigger_channel, channels2straighten,...
            channel_names, worm_positions, Path2Ilastik)
%
%
%   worm_positions is a cell array, e.g. {[1,2,3];[4,5]} will assign the
%   first three positions to worm 1 and positions 4,5 to worm 2
%
%
% all code by Wolfgang Keil, Institut Curie 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    overwrite_midlines = 1;
    AP_padd_size = 3500;
   
    
    if ~exist(experiment_folder, 'dir')
        disp('Experiment folder doesn''t exist. Doing nothing');
        return;
    end
            
    
    % Straightening with automated midline detection 
    for ii = 1:length(worm_positions)
        
        if exist([experiment_folder '/raw_data'], 'dir')

            disp(['Straightening ' num2str(length(worm_positions{ii})) ' positions of worm ' num2str(ii)])
            straighten_single_worm_dataset(experiment_folder, ii, trigger_channel, ...
                channels2straighten,channel_names, overwrite_midlines, AP_padd_size,worm_positions{ii},Path2Ilastik);
        end
    end        
end