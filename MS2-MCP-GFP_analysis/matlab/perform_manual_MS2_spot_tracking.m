function model  = perform_manual_MS2_spot_tracking(experiment_folder,...
                                    worm_index,position, chop,track_ID, slices, frames,z_scale)
 %
 % THIS FUNCTION SETS UP MANUAL TRACKING OF THE MS2 SPOTS
 % It checks whether previous tracking results exist and ask whether the user
 % wants to keep them
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import fiji.plugin.trackmate.* ; 
    import fiji.plugin.trackmate.io.* ; 
    import java.io.File;
    import fiji.plugin.trackmate.gui.displaysettings.*;   
    import fiji.plugin.trackmate.visualization.hyperstack.*
                                
    try 
                                

        model = {};
    % 
        logger = Logger.IJ_LOGGER; % we have to feed a logger to the reader

        trackID_string = num2str(track_ID);
        trackID_string = [repmat('0', [1 4-length(trackID_string)]) trackID_string];    

        chop_folder = [experiment_folder 'worm_' num2str(worm_index) ...
            '_straightened/Pos' num2str(position) '/chop_' num2str(chop)];

        TrackMateFile = [chop_folder '/pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string '.xml'];   
        TiffFile = [chop_folder '/pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string '.tif'];


        % Means the previous tracking results for this nucleus exist
        % Ask whether you want to use previous results or start again?
        if exist(TrackMateFile, 'file')
            answer = questdlg('Do you want to load previously tracked spots? Click ABORT if you don''t want to track anything.');
            switch answer
                case 'Yes'

                    ij.IJ.selectWindow('mCherry_stack');ij.IJ.run('Close');
                    ij.IJ.selectWindow('GFP_stack');ij.IJ.run('Close');
                    ij.IJ.selectWindow('Ilastik_stack');ij.IJ.run('Close');

                    f = msgbox(['Please load ' TrackMateFile ' to continue adding spots etc.']);

                case 'No'
                    % First merge the two colors
                    ij.IJ.run("Merge Channels...", "c2=GFP_stack c6=Ilastik_stack");
                    ij.IJ.run('Rename...',['title=pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string ]);
                    % Set the properties of the stack in FIJI, these scales are taken into
                    % account when running the spot detection and tracking
                    ij.IJ.run('Properties...', ['channels=2 slices=' num2str(slices)...
                        ' frames=' num2str(frames) ' pixel_width=1 pixel_height=1 voxel_depth=' ...
                        num2str(z_scale) ' frame=[1 frame]']);

                    ij.IJ.saveAs('Tiff', TiffFile);

                case 'Abort'
                    model = {};
                    return;
            end

        else
            % First merge the two colors
            ij.IJ.run("Merge Channels...", "c2=GFP_stack c6=Ilastik_stack");
            ij.IJ.run('Rename...',['title=pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string ]);
            ij.IJ.run('Properties...', ['channels=2 slices=' num2str(slices)...
                ' frames=' num2str(frames) ' pixel_width=1 pixel_height=1 voxel_depth=' ...
                num2str(z_scale) ' frame=[1 frame]']);

            ij.IJ.saveAs('Tiff', TiffFile);
            ij.IJ.selectWindow('mCherry_stack');ij.IJ.run('Close');
        end


        answer = questdlg('Click YES/NO when you finished the manual spot inputs. Click CANCEL if you didn''t track anything.');
        switch answer
            case 'Yes'
            case 'No'
                return;
            case 'Cancel'
                
                ij.IJ.selectWindow(['pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string '.tif' ]');ij.IJ.run('Close');
                model = {};
                return;
        end
        % Now let the user run the TrackMatePlugin and tell the program when
        % finished 


        if exist([chop_folder '/pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string '.xml'], 'file')        
            file = File([chop_folder '/pos_' num2str(position) '_chop_' num2str(chop) '_trackID_' trackID_string '.xml']);

            reader = TmXmlReader(file);

            if ~(reader.isReadingOk)
                disp('Cannot read the xml-file');
                model = {};
                return;
            else
                model = reader.getModel();      
                display(model.toString());        
            end            
        end
        

    catch
        close all force;       
    end
end