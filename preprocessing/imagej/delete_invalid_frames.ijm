//// MACRO delete_invalid_frames.ijm
////
experiment_folder = "/Users/wolfgang/Documents/GitHub/test_data/HML1019/";
//"/media/keil-workstation/Shubh_Data9/Imaging/210805_HML1019_L3/";//"/media/keil-workstation/Shubh_Data9/Imaging/210812_HML1065_L3/";
worm_index = 1;

no_slices = 51;
setBatchMode(true);
/////////////////////////////////////////////////////////////////

no_positions  = get_number_of_positions(experiment_folder + "/worm_" + worm_index + "_straightened/");

for(jj=0; jj< no_positions; jj++){
	pos_folder = experiment_folder + "/worm_1_straightened/" + "Pos" + jj + "/";
	
	no_chops  = get_number_of_chops(pos_folder);
	for(ii=0; ii< no_chops; ii++){
		chop_folder = pos_folder + "chop_" + ii + "/";

		if(File.exists(chop_folder + "chop_" + ii + ".tif")){
			open(chop_folder +  "chop_" + ii + ".tif");
			//OPEN frames2delete.txt and delete slices, if it doesn't exist, do nothing
			if(File.exists(chop_folder + "frames2delete.txt")){
				filestring=File.openAsString(chop_folder + "frames2delete.txt");
				columns=split(filestring," ");
				for(i=columns.length-1; i>-1; i--){					
					if (isNaN(parseInt(columns[i])) == 0){
						Stack.setFrame(parseInt(columns[i]));
						print("Deleting slice " + parseInt(columns[i]) + " in chop " + ii);
						run("Delete Slice", "delete=frame");
					}
				}				
			}
			run("Split Channels");
			selectWindow("C1-chop_" + ii + ".tif");
			saveAs("Tiff", pos_folder + "chop_" + ii + "/GFP_stackreg.tiff");
			close();
			selectWindow("C2-chop_" + ii + ".tif");
			saveAs("Tiff", pos_folder + "chop_" + ii + "/mCherry_stackreg.tiff");
			close();
		}				
		else{
			print("Cannot find file chop_" + ii + ".tif for position " + jj + ". Skipping this chop.");
		}
	}

}

///////////////////////////// TREAT THE 3D stacks  ////////////////////////////////////////

for(jj=0; jj< no_positions; jj++){
	pos_folder = experiment_folder + "/worm_1_straightened/" + "Pos" + jj + "/";
	
	no_chops  = get_number_of_chops(pos_folder);
	for(ii=0; ii< no_chops; ii++){
		chop_folder = pos_folder + "chop_" + ii + "/";

		if(File.exists(chop_folder + "chop_" + ii + "_GFP_stack_t_1" + ".tif") && File.exists(chop_folder + "chop_" + ii + "_mCherry_stack_t_1" + ".tif"))  
		
		{
			run("Image Sequence...", "open=" + chop_folder + "chop_" + ii + "_GFP_stack_t_1" + ".tif file=GFP_stack_t_ sort");			
			rename("GFP");
			getDimensions(width, height, channels, slices, frames);
			no_frames = slices/no_slices;

			run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + no_slices +  "  frames=" + no_frames + " display=Grayscale");			
			run("Image Sequence...", "open=" + chop_folder + "chop_" + ii + "_mCherry_stack_t_1" + ".tif file=(mCherry_stack_t_[0-9]+.tif) sort");			
			//run("Image Sequence...", "dir=" + chop_folder + " filter=(mCherry_stack_t_[0-9]+.tif) sort");
			rename("mCherry");
			run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + no_slices +  "  frames=" + no_frames + " display=Grayscale");			

			//OPEN frames2delete.txt and delete slices, if it doesn't exist, do nothing
			if(File.exists(chop_folder + "frames2delete.txt")){
				filestring=File.openAsString(chop_folder + "frames2delete.txt");
				columns=split(filestring," ");
				for(i=columns.length-1; i>-1; i--){					
					if (isNaN(parseInt(columns[i])) == 0){
						print("Deleting sllice " + parseInt(columns[i]) + " in chop " + ii);
						selectWindow("GFP");
						Stack.setFrame(parseInt(columns[i]));
						run("Delete Slice", "delete=frame");
						selectWindow("mCherry");
						Stack.setFrame(parseInt(columns[i]));
						run("Delete Slice", "delete=frame");
					}
				}
			}
			
		selectWindow("GFP");
		saveAs("Tiff", pos_folder + "chop_" + ii + "/GFP_stack_stackreg.tiff");
		close("GFP_stack_stackreg.tiff");
		
		selectWindow("mCherry");
		saveAs("Tiff", pos_folder + "chop_" + ii + "/mCherry_stack_stackreg.tiff");
		close("mCherry_stack_stackreg.tiff");
		}
		else{
			print("Cannot find file chop_" + ii + ".tif for position " + jj + ". Skipping this chop.");
		}
	}

}
print("All invalid frames deleted in all chops and all positions.");


///////////////////////// HELPER FUNCTIONS ///////////////////////////////
//////////////////////////////////////////////////////////////////////////
function get_number_of_positions(experiment_folder){

	no_positions = 0;
	while (File.isDirectory(experiment_folder + "Pos" + no_positions + "/")!= 0) {
		no_positions = no_positions + 1;
	}
	return no_positions;
}

//////////////////////////////////////////////////////////////////////////
function get_number_of_chops(pos_folder){

	no_chops = 0;
	while (File.isDirectory(pos_folder + "chop_" + no_chops + "/")!= 0) {
		no_chops = no_chops + 1;
	}
	return no_chops;
}