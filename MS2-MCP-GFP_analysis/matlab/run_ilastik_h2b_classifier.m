function run_ilastik_h2b_classifier(experiment_folder, worm_index, Path2Ilastik)
% This function runs the ilastik nucleus classifier on the mCherry channel on all chops for all
% positions that it finds 
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2022
   
    
    ilastik_root = Path2Ilastik;
    ilastik_project = ['../../ilastik/'    ...
       'tracking_global_H2B_mCherry/tracking_global_H2B_mCherry.ilp']; 
    
    % flag to turn ON and OFF the 3D classifier
    no_slices = 51;
    
    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder = [experiment_folder '/'];
    end    
    
    disp(['Analyzing experiment ' experiment_folder ' worm ' num2str(worm_index) '...']);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Loops over all positions and chops
    curr_pos = 0;
    
    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos) '/'], 'dir')
        
        curr_chop = 0;
        
        while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')
                    
            disp(['Performing pixel classification for chop ' num2str(curr_chop) ' of position ' num2str(curr_pos) ' ...']);
            chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];
                    
            if exist([chop_folder 'mCherry_stackreg.tiff'], 'file')
                disp('Performing h2b pixel classification  with Ilastik...');
                command = [ilastik_root '/Contents/ilastik-release/run_ilastik.sh' ' --headless --project='...
                                ilastik_project ' ' chop_folder 'mCherry_stackreg.tiff'];           

                % Performing pixel classification of two-dimensional projection with ilastik
                % this also saves the probability map as tif file
                [~, out] = system(command);     
            else
                disp(['Cannot find file mCherry_stackreg.tiff for chop' num2str(curr_chop) ' of position ' num2str(curr_pos)]);
            end
            
            ij.IJ.close('*');
            if exist([chop_folder 'chop_' num2str(curr_chop) '_mCherry_stack_t_1.tif'],'file') ...
                                && exist([chop_folder 'mCherry_stackreg.tiff'],'file') 

                % This is just to get the number of frames in the
                % registered stack
                tmp = loadtiff([chop_folder 'mCherry_stack_stackreg.tiff']);
                no_frames = size(tmp, 3)/no_slices;


                tmp_dir = [experiment_folder '/tmp/'];
                % Delete all files named tmp_xx.tif or tmp_xx.tiff before execution
                filenames = dir(tmp_dir);
                for ii = 1:length(filenames)
                    if ~isfolder([tmp_dir filenames(ii).name])
                        if contains(filenames(ii).name, 'tmp_') && contains(filenames(ii).name, '.tif')
                            delete([tmp_dir filenames(ii).name]);
                        end
                    end
                end
                %pause(2); % leave a pause here making sure that all temporary files have been deleted

                try 
                    disp('Performing 3D H2B pixel classification  with Ilastik for all timepoints...');
                    % Open 4D stack in ImageJ
                    imp = ij.IJ.openImage([chop_folder 'mCherry_stack_stackreg.tiff']);
                    imp.show();
                    % Now split the 4D into frames, save them
                    for ii = 1:no_frames
                        ij.IJ.run('Duplicate...', ['title=tmp_' num2str(ii) '.tif duplicate frames=' num2str(ii)]);
                        ij.IJ.selectWindow(['tmp_' num2str(ii) '.tif']);
                        ij.IJ.saveAs(java.lang.String('tiff'), java.lang.String([tmp_dir 'tmp_' num2str(ii) '.tif']));
                        pause(1); % give some time to save file, not doing this leads to some weird error sometimes
                        % Classify the temporary file
                        command = [ilastik_root '/Contents/ilastik-release/run_ilastik.sh' ' --headless --project='...
                                        ilastik_project ' ' tmp_dir 'tmp_' num2str(ii) '.tif'];  

                        % Run 3D ilastik classification on a single timepoint        
                        [~,out]=system(command);

                        %%%% Close the temperature window containing the single
                        %%%% time frame
                        ij.IJ.selectWindow(['tmp_' num2str(ii) '.tif']);
                        ij.IJ.run('Close');  
                        ij.IJ.open(java.lang.String([tmp_dir 'tmp_' num2str(ii) '_Probabilities.tiff']));
                        ij.IJ.setMinAndMax(0,1);
                        ij.IJ.run('16-bit');
                        ij.IJ.saveAs(java.lang.String('tiff'), java.lang.String([tmp_dir 'tmp_' num2str(ii) '_Probabilities_16bit.tif']));
                        ij.IJ.selectWindow(['tmp_' num2str(ii) '_Probabilities_16bit.tif']);
                        ij.IJ.run('Close');                        
                    end
                    ij.IJ.selectWindow('mCherry_stack_stackreg.tiff');
                    ij.IJ.run('Close');      
                    pause(0.5); 
                catch
                    disp(['Error while classifying frame ' num2str(ii) ' chop ' num2str(curr_chop) ' of position ' num2str(curr_pos) ' .']);
                end


                %%%% After all is done, assemble the full Ilastik stack
                %%%% in ImageJ and save it as
                %%%% mCherry_stack_stackreg_Probabilities.tiff.
                ij.IJ.run('Image Sequence...', ['open=' tmp_dir 'tmp_1.tif file=_Probabilities_16bit.tif sort']);
                ij.IJ.run('Rename...','title=Ilastik_stack');
                ij.IJ.run('Stack to Hyperstack...', ['order=xyczt(default) channels=2 slices=' num2str(no_slices) ' frames=' num2str(no_frames) ' display=Color']);
                ij.IJ.run('Split Channels');
                ij.IJ.close('C2-Ilastik_stack');
                ij.IJ.selectWindow('C1-Ilastik_stack');
                ij.IJ.run('8-bit');
                ij.IJ.saveAs('tiff', [chop_folder 'mCherry_stack_stackreg_Probabilities.tiff']);
                ij.IJ.run('Close All'); 

                %%% Delete all temporary files and start a new chop
                % Delete all files named tmp_xx.tif or tmp_xx.tiff before execution
                filenames = dir(tmp_dir);
                for ii = 1:length(filenames)
                    if ~isfolder([tmp_dir filenames(ii).name])
                        if contains(filenames(ii).name, 'tmp_') && contains(filenames(ii).name, '.tif')
                            delete([tmp_dir filenames(ii).name]);
                        end
                    end
                end
                
                
                
            else
                disp(['Cannot find file chop_' num2str(curr_chop) 'mCherry_stack_t_1.tif for position ' num2str(curr_pos)]);
                disp('No nucleus tracking possible.');
            end                   
            curr_chop = curr_chop + 1;
        end
        
        curr_pos = curr_pos + 1;
    end
end