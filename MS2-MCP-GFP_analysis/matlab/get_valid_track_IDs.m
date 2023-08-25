%
% FUNCTION valid_tracks = get_valid_track_IDsget_valid_track_IDs(experiment_folder,worm_index, position, chop)
% This is a helper function that gets all nuclear track IDs for a chop of a
% position of an experiment
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%% all code by Wolfgang Keil, Institut Curie, 2021
function [valid_tracks, all_track_stats] = get_valid_track_IDs(experiment_folder,worm_index, position, chop)

    chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                num2str(position) '/chop_' num2str(chop)];
   
    filenames = dir(chop_folder);
    
    valid_tracks = [];
    
    for ii = 1:length(filenames)
        if ~isfolder([chop_folder '/' filenames(ii).name])
            if contains(filenames(ii).name, '.mat') && ... 
                contains(filenames(ii).name, 'track_') && ... 
                ~contains(filenames(ii).name, 'spots')
            
                ind = strfind(filenames(ii).name, 'track_');
                valid_tracks = [valid_tracks, round(str2double(filenames(ii).name(ind+6:ind+9)))];
                load([chop_folder '/' filenames(ii).name], 'track_stats');
                all_track_stats(length(valid_tracks)) = track_stats;
            end
        end
    end
    
    if ~exist('all_track_stats', 'var')
        all_track_stats = [];
    end
    
end