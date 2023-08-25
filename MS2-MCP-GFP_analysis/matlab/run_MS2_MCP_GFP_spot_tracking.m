function run_MS2_MCP_GFP_spot_tracking()
%
%
%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2021


    experiment_folder = '/Users/wolfgang/Documents/GitHub/test_data/HML1019/';
    worm_index = 1;

    % Change according to the location of your Ilastik installation
    Path2Fiji = '/Applications/Fiji.app'; 

    %%% Adds various subfolders to the Matlab path
    Folder = cd;
    code_root_folder = fullfile(Folder, '../../');
    PATHS_TO_ADD = {[code_root_folder '/file_handling/'],...
                    [code_root_folder '/external_code/'], ...
                    [code_root_folder '/external_code/saveastiff_4.0/'], ...
                    [Path2Fiji '/scripts/']};


    % Add paths
    pathCell = regexp(path, pathsep, 'split');

    for jj = 1:length(PATHS_TO_ADD)
        if ispc  % Windows is not case-sensitive
            onPath = any(strcmpi(PATHS_TO_ADD{jj}, pathCell));
        else
            onPath = any(strcmp(PATHS_TO_ADD{jj}, pathCell));
        end
        if ~onPath
            addpath(PATHS_TO_ADD{jj});
        end
    end
    
    retrack_spots = 1;    
    verbose = 1;    
    
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
       % 
    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder = [experiment_folder '/'];
    end    
    
    disp(['Analyzing experiment ' experiment_folder ' worm ' num2str(worm_index) '...']);

    % Check if ImageJ IJM exists in workspace, otherwise, start ImageJ
    ise = evalin( 'base', 'exist(''IJM'',''var'') == 1' );
    if ~ise
        ImageJ;
    else
        ise2 = evalin( 'base', 'isempty(''IJM'')' );
        if ise2
            ImageJ;
        else
            ij.IJ.run('Close All'); % close all ImageJ windows
        end
    end
    if ~exist('IJM', 'var')
        IJM = evalin('base', 'IJM');            
    end
    
    
    import java.lang.Integer    
    
    %%%%%%%%% LOOPS OVER EACH POSITION AND CHOPS
    curr_pos = 1;
    
    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos)], 'dir')
        
        curr_chop = 0;
        
        %%%%% LOADING THE ORIGINAL STRAIGHTENED IMAGES TO ORIENT OURSELVES
        %%%%% NOTE THAT THES IMAGES ARE NOT AP-DV CORRECTED SO YOU MAY 
        %%%%% HAVE TO DO THIS MANUALLY
        disp('Loading mCherry_stack for position...')

        posfolder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/mCherry/'];
                    
                    
        first_frame = get_first_frame(experiment_folder);
        t_string = num2str(first_frame);
        t_string = [repmat('0', [1 9-length(t_string)]) t_string];
        

        firstframefilename = ['img_' t_string '_mCherry.tif'];
        % Get the ilastik_probability maps generate from the segmentation
        imp = ij.IJ.openImage([posfolder firstframefilename]);
        imp.show();
        
        
        posfolder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/GFP/'];
        firstframefilename = ['img_' t_string '_GFP.tif'];
        % Get the ilastik_probability maps generate from the segmentation
        imp2 = ij.IJ.openImage([posfolder firstframefilename]);
        imp2.show();
        ij.IJ.run('Merge Channels...', ['c2=img_' t_string '_GFP.tif c6=img_' t_string '_mCherry.tif create']);

       
        while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')
                    
            if verbose
                chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                            num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];
                mCherry_tile = double(loadtiff([chop_folder 'mCherry_stackreg.tiff']));
            end
            
            % Check the the manual registration has actually been done for
            % this chop
            if exist([chop_folder 'chop_' num2str(curr_chop) '_stack_t_1.tif'],'file')      
            
            
                [valid_track_IDs, all_track_stats] = get_valid_track_IDs(experiment_folder,worm_index, curr_pos, curr_chop);    

                if ~isempty(valid_track_IDs)
                    
                    chop_time = 1/framerate * get_chop_timepoints(experiment_folder, worm_index, curr_pos, curr_chop);

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if retrack_spots
                        % Start ImageJ again
                        disp('Starting tracking of MCP-GFP spots in individual nuclei');
                        for ii = 1:length(valid_track_IDs)

                            % Plot the track on top of the mCherry stack to visualize where we are and make it easier to determine the cell type 
                            if verbose
                                figure(1);
                                set(gcf, 'position', [000 600 800 400]);
                                clf;
                                imagesc(mCherry_tile(:,:,min(all_track_stats(ii).frames(:))+1));
                                colormap(gray);
                                caxis([90 130]);
                                hold on;

                                for jj = 1:length(valid_track_IDs)
                                    plot(all_track_stats(jj).posx(1),all_track_stats(jj).posy(1), 'oy');
                                end

                                scatter(all_track_stats(ii).posx,all_track_stats(ii).posy,20, all_track_stats(ii).frames,'r');
                                axis image;
                                hold off;
                                drawnow;
                            end

                            answer = questdlg(['Would you like a to analyze this nucleus (track) ' num2str(valid_track_IDs(ii)) '?'], ...
                                ['Nucleus triage position ' num2str(curr_pos) ' chop ' num2str(curr_chop)], ...
                                'Yes','No','Abort','No');
                            % Handle response
                            switch answer
                                case 'Yes'
                                    % Run the actual MS2 spot tracking in 3D 
                                    disp(['Tracking spots in nucleus track' num2str(valid_track_IDs(ii)) ]);

                                   manually_track_MCP_GFP_3D_spots_in_single_track(IJM,experiment_folder,...
                                                        worm_index,curr_pos, curr_chop,valid_track_IDs(ii));


                                case 'No'
                                    disp('Skipping this nucleus. Analyzing next nuclear track ... ');
                                case 'Abort'
                                    return;
                            end                    


                        end
                    end   
                else
                    disp(['WARNING: Cannot find any nuclear tracks for chop ' num2str(curr_chop) ' of position ' num2str(curr_pos)]);
                end
                
            end
            
            clear('mCherry_tile');
            close all;
            
            curr_chop = curr_chop + 1;
        end
        

        ij.IJ.selectWindow('Composite');
        ij.IJ.run('Close');
        
        curr_pos = curr_pos + 1;    
    end
    
    ij.IJ.close('*');   
    ij.IJ.exit;
  
end


function first_frame = get_first_frame(experiment_folder)

    %Find out whether there is a frame_range.txt file, otherwise find
    %midlines for the whole time series
    %range = get_frame_range([experiment_folder], worm_index);
    
    
    if exist([experiment_folder '/frame_range.txt'],'file')
        disp('Reading frame range file...');
        fid = fopen([experiment_folder '/frame_range.txt']);
        range = fscanf(fid, '%d');
        fclose(fid);
        
        first_frame = range(1);
    else
        first_frame = 1;
    end   
end