
function A = load_original_frame_nikon(raw_data_folder,position,frame_index,channel)
%
% read the tiff files for the the experiment, uncropped stack consists
% of individual tiff-files
%
%
% raw_data_folder is a folder with name <<experiment_name>> / raw_data
%
%
%
%   Wolfgang Keil,Institut Curie 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    A = [];
    
   % Add a forward slash at the end
    if strcmpi(raw_data_folder(end), '/') == 0
        raw_data_folder = [raw_data_folder , '/'];
    end

    [no_timestamps, no_positions, no_slices, no_channels] = get_timelapse_dimensions_nikon(raw_data_folder);
    
    
    if ~isempty(no_timestamps)
        if no_timestamps < frame_index
            disp(['Cannot load frame ' num2str(frame_index) ' because only ' num2str(no_timestamps) ' frames recorded.']);
            return;
        end
        if channel > no_channels
            disp(['Cannot load channel ' num2str(channel) ' because only ' num2str(no_channels) ' frames recorded.']);
            return;
        end
        
        if position > no_positions
            disp(['Cannot load positions ' num2str(max(positions)) ' because only ' num2str(no_positions) ' frames recorded.']);
            return;
        end
        
        
%         %%%%%%%%%%%%%%%% Generate the substrings of the filename, depending
%         %%%%%%%%%%%%%%%% on size of the data set
%         %%%%%%%%%%%%%%%% Timestamp string is weird
%         if no_timestamps < 10
%             len_t_string = 3;
%         elseif no_timestamps >=10 && no_timestamps < 100
%             len_t_string = 3;
%         elseif no_timestamps >=100 && no_timestamps < 1000
%             len_t_string = 3;
%         else
%             len_t_string = 4;
%         end

        len_t_string = 3;% this is normally the case
        list_of_files = dir(raw_data_folder);
        for ii = 1:length(list_of_files)
            if(contains(list_of_files(ii).name, 'xy') || contains(list_of_files(ii).name, 'xy')) 
                len_t_string = -1 + regexp(list_of_files(ii).name, 'xy[0-9]')-regexp(list_of_files(ii).name, 't[0-9]');
                break;
            end
        end
        
        
        timestamp_string = num2str(frame_index);
        timestamp_string = ['t' repmat('0', [1 len_t_string-length(timestamp_string)]) timestamp_string];
        
        if no_positions < 10
            len_pos_string = 1;
        elseif no_positions >=10 && no_positions < 100
            len_pos_string = 2;
        elseif no_positions >=100 && no_positions < 1000
            len_pos_string = 3;
        else
            len_pos_string = 4;
        end
        
        pos_string = num2str(position);
        pos_string = ['xy' repmat('0', [1 len_pos_string-length(pos_string)]) pos_string];

        
        if no_channels < 10
            len_ch_string = 1;
        else
            len_ch_string = 2;
        end
        
        
        ch_string = num2str(channel);
        ch_string = ['c' repmat('0', [1 len_ch_string-length(ch_string)]) ch_string];


        %%%%%%%%%%%%%%% READ THE INDIVIDUAL TIFF FILES, combine them into a
        %%%%%%%%%%%%%%%  3D array
        for jj = 1:no_slices
            
            % This adds a zero to the name, depending on how many slices
            % were imaged and what the current slice index is
            ad_Zeros = '';            
            if no_slices > 9 && no_slices < 100
                if jj < 10
                    ad_Zeros = '0';
                end
            elseif no_slices > 99
                if jj < 10
                    ad_Zeros = '00';
                elseif jj > 9 && jj < 100
                    ad_Zeros = '0';
                end
            end
            slice_string = ['z' ad_Zeros num2str(jj)];
            
            % Final filename is generated here, with added zeros in the
            % time frames
            full_file_name = [timestamp_string pos_string slice_string ch_string '.tif'];

            % If the added zeros don't work, try without
%             if~exist([raw_data_folder '/' full_file_name], 'file')
%                 %full_file_name = [filename 'z'  num2str(jj) '_ch' num2str(channel) '.tif'];
%             end
            % Get all the data in the requested channe
            if exist([raw_data_folder '/' full_file_name], 'file')
                if(isempty(A))
                    A = loadtiff([raw_data_folder '/' full_file_name]);
                else
                    A(:,:,jj) = loadtiff([raw_data_folder '/' full_file_name]);
                end
            else
                % Try adding a zero to the position string, this is
                % sometimes necessary for the SB chips, because many
                % positions are imaged but a worm can only be present in
                % two of them
                len_pos_string = len_pos_string + 1;
                pos_string = num2str(position);
                pos_string = ['xy' repmat('0', [1 len_pos_string-length(pos_string)]) pos_string];

                full_file_name = [timestamp_string pos_string slice_string ch_string '.tif'];
                
                if exist([raw_data_folder '/' full_file_name], 'file')
                    if(isempty(A))
                        A = loadtiff([raw_data_folder '/' full_file_name]);
                    else
                        A(:,:,jj) = loadtiff([raw_data_folder '/' full_file_name]);
                    end
                else              
                    A = [];
                    return
                end
            end
        end

    else
        disp(['Could not load frame ' num2str(frame_index)]);
    end

end
