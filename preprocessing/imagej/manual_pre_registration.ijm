//*****************manual_pre_registration.ijm ********************************************
//
// To use this code, run the straightening pipeline 
//
// using various manual user inputs, this code will then chop the individual worm segments into smaller ones
// maximum z-projects the stack and the asks the user to manually track a single landmark
//
//
// It saves a registered max-z-projection and a file called x_position.txt in the chop_xx folders it also creates
// The x_position.txt can be used to then later re-construct the position of the cells along the AP axis
//
// HOW TO CONTINUE AFTER THIS:
// open the chop_xx stacks, parse through them to find frames that are still not well-aligned, write the indices in a file called frames2delete.txt, then run delete_invalid_frames.txt
// which will delete all frames, split colors again and save as image-sequence
//
//
//
//************************** all code by Wolfgang Keil, Institut Curie

experiment_folder = "/Users/wolfgang/Documents/GitHub/test_data/HML1019/";
worm_index = 1;
channels = newArray("mCherry", "GFP");
frame_range_file = "frame_range.txt";


redo_alignment = 1; // set this flag to 0 if you don't want to redo all the clicking, the script will use the previous alignment, will throw an error of the aligment doesn't exst or is incomplete 
redo_z_projection_selection = 1; // set this flag to 1 if you don't want to choose new z planes for the chops, otherwise it will look for a file containing the plane info


/////////////////////////////////////////////////////
// Parameters of the chopping
crop_size = 500; // crop size in x, nothing will be cropped off in y
pc_overlap = 20; //PERCENT overlap between the chops

frame_range = get_frame_range(experiment_folder);
//no_timepoints = get_number_of_timepoints(experiment_folder + "/raw_data/");
no_positions = get_number_of_positions(experiment_folder, worm_index);


// Open the first file in the frame range to get the dimensions of the data set
// We particularly need the no_slices variable to then convert the entire data set into a hyperstack

if(frame_range[0] < 10){
	file_name_trunk = "img_00000000" + frame_range[0] + "_";
}
else if(frame_range[0] >= 10 && frame_range[0] < 100){
	file_name_trunk = "img_0000000" + frame_range[0] + "_";
}
else if(frame_range[0] >= 100 && frame_range[0] < 1000){
	file_name_trunk = "img_000000" + frame_range[0] + "_";
}

open(experiment_folder + "worm_" + worm_index + "_straightened/Pos0/GFP/" + file_name_trunk + "GFP.tif");
getDimensions(tmp, tmp1, tmp2, no_slices, tmp4);
close("*");


// 
for(jj=0; jj< no_positions; jj++){
	worm_folder_straightened = experiment_folder + "/worm_" + worm_index + "_straightened/" + "Pos" + jj + "/";

	for (kk = 0; kk < channels.length; kk++){
		print(channels.length);
		// Load the Cherry and GFP channel of the first frame
		run("Image Sequence...", "open=" + worm_folder_straightened + "/" + channels[kk] + "/" + file_name_trunk + channels[kk] + ".tif number=" + (frame_range[1]-frame_range[0])+1 + "  starting=1" + " file=img sort");
		run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + no_slices + " frames=" + (frame_range[1]-frame_range[0])+1 + " display=Grayscale");
		run("Enhance Contrast", "saturated=0.35");
		getDimensions(img_width, img_height, no_channels, slices, frames);
	}
	if(channels.length == 2){ // ,means we imaged GFP and mCherry only
		// Merge the channels

		run("Merge Channels...", "c2=GFP c6=mCherry create");
		run("Enhance Contrast", "saturated=0.05");
		Stack.setChannel(2);
		run("Enhance Contrast", "saturated=0.05");
		rename("Global stack");
	}
	else if (channels.length == 3){ // means we also imaged DIC
		// Merge the channels
		run("Merge Channels...", "c2=GFP c6=mCherry c4 =DIC create");
		run("Enhance Contrast", "saturated=0.05");
		Stack.setChannel(2);
		run("Enhance Contrast", "saturated=0.05");
		rename("Global stack");
	}


	// Input approximate start and end of the worm axis, worm will then be chopped along this axis within the defined x-range, chops are then tracked separately
	Dialog.createNonBlocking("Is AP alignment of this straightened position correct? (Anterior should be left)");
	Dialog.addMessage("AP alignment correct?");
	tmp = newArray("yes", "no");
	Dialog.addChoice("AP position correct:", tmp, tmp[0]);
	Dialog.show();
	isCorrectAP = Dialog.getChoice();

	if(isCorrectAP == "no"){
		run("Flip Horizontally", "stack");
	}


	// Input approximate start and end of the worm axis, worm will then be chopped along this axis within the defined x-range, chops are then tracked separately
	Dialog.createNonBlocking("Is DV alignment of this straightened position correct? (dorsal should be up)");
	Dialog.addMessage("DV alignment correct?");
	tmp = newArray("yes", "no");
	Dialog.addChoice("DV position correct", tmp, tmp[0]);
	Dialog.show();
	isCorrectDV = Dialog.getChoice();

	if(isCorrectDV == "no"){
		run("Flip Vertically", "stack");		
	}

	if(redo_alignment==1){
		// Input approximate start and end of the worm axis, worm will then be chopped along this axis within the defined x-range, chops are then tracked separately
		Dialog.createNonBlocking("Define x range along AP for this position:");
		Dialog.addMessage("Approximate x coordinated of anterior start and posterior end of worm");
		Dialog.addNumber("Anterior", 500);
		Dialog.addNumber("Posterior", 2700);
		Dialog.show();
		offset = Dialog.getNumber();
		end_x = Dialog.getNumber();	

		// Save the numbers to the AP_extent.txt file
		file=File.open(worm_folder_straightened + "/AP_extent.txt");
		print(file, offset + " " + end_x);
		File.close(file);		
	}
	else{
		if(File.exists(worm_folder_straightened + "/AP_extent.txt")){
			filestring=File.openAsString(worm_folder_straightened + "/AP_extent.txt");
			columns=split(filestring," ");
			offset = parseInt(columns[0]);
			end_x = parseInt(columns[1]);
		}			
		else{
			print("Cannot find file with name AP_extent.txt in folder for position " + jj + ". Aborting alignment of this position.");
			offset = 0;
			end_x = 0;
		}
	}

	print("Offset is " + offset);
	print("end_x " + end_x);

	if (end_x > 0) {

		no_chops = 0;	
	
		print(offset + no_chops*(100-pc_overlap)/100*crop_size + crop_size);
		while (( offset + no_chops*(100-pc_overlap)/100*crop_size + crop_size) < end_x + (100-pc_overlap)/100*crop_size) {
			//	print(offset + (no_chops+1)*crop_size);
			
			// Create directory to store the montage files in 
			if(File.isDirectory(worm_folder_straightened + "chop_" + no_chops + "/")!= 1){
				File.makeDirectory(worm_folder_straightened + "chop_" + no_chops + "/"); 
			}
			x_position = offset + no_chops*(100-pc_overlap)/100*crop_size;
	
			// Write the position of the chop into the folder (this way later we can retrieve the position of the chop after stitching the global images
			f = File.open(worm_folder_straightened + "chop_" + no_chops + "/" + "x_position.txt");
			print(f, x_position);		
			File.close(f);
	
			
			selectWindow("Global stack");	
			makeRectangle(x_position, 0, crop_size, img_height);
	
			
			run("Duplicate...", "title=chop" + no_chops + " duplicate"); // duplicates ALL TIME FRAMES
			Stack.setSlice(round(no_slices/2));
			run("Enhance Contrast", "saturated=0.35");
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");	
	
			rename("chop" + no_chops + "all");
	
	
			if(redo_z_projection_selection==1){
	
				// Go through the stack and have the user click on the same landmark over and over again, re-extract the slice from the global stack and inser into the chop
				Dialog.createNonBlocking("Define Max-z projection for this chop");
				Dialog.addMessage("Set boundaries of max-z projection which contain hypodermal cells");
				Dialog.addNumber("lower", 20);
				Dialog.addNumber("upper", 30);
				Dialog.show();
				lower_z = Dialog.getNumber();
				upper_z = Dialog.getNumber();
		
				// Save the numbers to the z_range.txt file
				file=File.open(worm_folder_straightened + "chop_" + no_chops + "/" + "z_range.txt");
				print(file, lower_z + " " + upper_z);
				File.close(file);		
			}
			else{
				// Reading previously stored z range info
				if(File.exists(worm_folder_straightened + "chop_" + no_chops + "/" + "z_range.txt")){
					filestring=File.openAsString(worm_folder_straightened + "chop_" + no_chops + "/" + "z_range.txt");
					columns=split(filestring," ");
					lower_z = parseInt(columns[0]);
					upper_z = parseInt(columns[1]);
				}
				else{
					// Go through the stack and have the user click on the same landmark over and over again, re-extract the slice from the global stack and inser into the chop
					Dialog.createNonBlocking("No z-range file found. Define z-range for this chop");
					Dialog.addMessage("Set z boundaries for this chop");
					Dialog.addNumber("lower", 20);
					Dialog.addNumber("upper", 30);
					Dialog.show();
					lower_z = Dialog.getNumber();
					upper_z = Dialog.getNumber();
			
					// Save the numbers to the z_range.txt file
					file=File.open(worm_folder_straightened + "chop_" + no_chops + "/" + "z_range.txt");
					print(file, lower_z + " " + upper_z);
					File.close(file);		
					
				}
			}
	
			run("Z Project...", "start=" + lower_z + " stop=" + upper_z + " projection=[Max Intensity] all");
			rename("chop" + no_chops);
			close("chop" + no_chops + "all");
			
			Stack.setSlice(round(no_slices/2));
			run("Enhance Contrast", "saturated=0.1");
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.1");	
	
	
			// Before starting the loop for clicking, save the first stack 
			selectWindow("Global stack");	
			makeRectangle(x_position, 0, crop_size, img_height);		
			run("Duplicate...", "duplicate frames=" + 1);
			saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_stack_t_1.tif");
			run("Split Channels");
			selectWindow("C1-" + "chop_" + no_chops + "_stack_t_1.tif");
			saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_GFP_stack_t_1.tif");
			close("chop_" + no_chops + "_GFP_stack_t_1.tif");
			selectWindow("C2-" + "chop_" + no_chops + "_stack_t_1.tif");
			saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_mCherry_stack_t_1.tif");
			close("chop_" + no_chops + "_mCherry_stack_t_1.tif");
				
			 
			for (i = 1; i <= (frame_range[1]-frame_range[0])+1; i++) {
				selectWindow("chop" + no_chops);
				Stack.setFrame(i);
	
				landmark_pos_filename = worm_folder_straightened + "chop_" + no_chops + "/" + "landmark_pos_frame_ " + i + ".txt";
	
				if (i==1){
					if (redo_alignment==1){
						waitForUser( "Pause","Click on landmark position in first frame. Then click on the same landmark in subsequent frames."); 
						a = get_landmark_position();  	
						x1 = a[0];
						y1 = a[1];
	
						// Write the position of the landmark into a file, this way we can re-align without re-clicking
						f = File.open(landmark_pos_filename);
						print(f, x1 + " " + y1);		
						File.close(f);
					}
					else{						
						if(File.exists(landmark_pos_filename)){
							filestring=File.openAsString(landmark_pos_filename);
							columns=split(filestring," ");
							x1 = parseInt(columns[0]);
							y1 = parseInt(columns[1]);
						}
						else{
							exit("Cannot find file " + landmark_pos_filename +  " for position " + jj ". Aborting alignment.");
						}						
					}
					print("---LANDMARK POSITION IN FIRST SLICE-------");
					print("x1 = " + x1);
					print("y1 = " + y1);
					wait(200);
	
				}
				else if(i<=(frame_range[1]-frame_range[0])){
	
					if (redo_alignment==1){
						a = get_landmark_position();  	
						x2 = a[0];
						y2 = a[1];
	
						// Write the position of the landmark into a file, this way we can re-align without re-clicking
						f = File.open(landmark_pos_filename);
						print(f, x2 + " " + y2);		
						File.close(f);
					}
					else{						
						if(File.exists(landmark_pos_filename)){
							filestring=File.openAsString(landmark_pos_filename);
							columns=split(filestring," ");
							x2 = parseInt(columns[0]);
							y2 = parseInt(columns[1]);
						}			
						else{
							exit("Cannot find file " + landmark_pos_filename +  " for position " + jj ". Aborting alignment.");
						}						
					}					
					print("---NEW LANDMARK POSITION-------");			
					print("x2 = " + x2);
					print("y2 = " + y2);
					wait(200);
			
					xconv = (x1 - x2);
					x_position = offset + no_chops*(100-pc_overlap)/100*crop_size - xconv;
					
					selectWindow("Global stack");	
					Stack.setFrame(i);				
					makeRectangle(x_position, 0, crop_size, img_height);
					//rename("tmp");
					run("Duplicate...", "duplicate frames=" + i);
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					run("Z Project...", "start=" + lower_z + " stop=" + upper_z + " projection=[Max Intensity]");			
					rename("Frame2Insert");

					// Select the dual channel image again, split colors and save individual channels
					selectWindow("chop_" + no_chops + "_stack_t_" + i + ".tif");
					run("Split Channels");
					selectWindow("C1-" + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_GFP_stack_t_" + i + ".tif");
					close("chop_" + no_chops + "_GFP_stack_t_" + i + ".tif");
					selectWindow("C2-" + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_mCherry_stack_t_" + i + ".tif");
					close("chop_" + no_chops + "_mCherry_stack_t_" + i + ".tif");
					//close("chop_" + no_chops + "_stack_t_" + i + ".tif");

					// Insert the registered z-projection into the z-projected stack called chop_x
					selectWindow("chop" + no_chops);
					run("Make Substack...", "frames="+1+"-"+(i-1));
					rename("Before");
					selectWindow("chop" + no_chops);
					run("Make Substack...", "frames="+(i+1)+"-"+frames);	
					rename("After");
					close("chop" + no_chops);
					run("Concatenate...", "  title=chop" + no_chops + " open image1=Before image2=Frame2Insert image3=After image4=[-- None --]");
				}
				else{ // Deal with the last frame
					
					if (redo_alignment==1){
						a = get_landmark_position();  	
						x2 = a[0];
						y2 = a[1];
	
						// Write the position of the landmark into a file, this way we can re-align without re-clicking
						f = File.open(landmark_pos_filename);
						print(f, x2 + " " + y2);		
						File.close(f);
					}
					else{						
						if(File.exists(landmark_pos_filename)){
							filestring=File.openAsString(landmark_pos_filename);
							columns=split(filestring," ");
							x2 = parseInt(columns[0]);
							y2 = parseInt(columns[1]);
						}			
						else{
							exit("Cannot find file " + landmark_pos_filename +  " for position " + jj ". Aborting alignment.");
						}						
					}					
					
					print("---NEW LANDMARK POSITION-------");			
					print("x2 = " + x2);
					print("y2 = " + y2);
					wait(200);
			
					xconv = (x1 - x2);
					x_position = offset + no_chops*(100-pc_overlap)/100*crop_size - xconv;
					
					selectWindow("Global stack");	
					makeRectangle(x_position, 0, crop_size, img_height);
					run("Duplicate...", "duplicate frames=" + i);
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					run("Z Project...", "start=" + lower_z + " stop=" + upper_z + " projection=[Max Intensity]");			
					rename("Frame2Insert");

					selectWindow("chop_" + no_chops + "_stack_t_" + i + ".tif");
					run("Split Channels");
					selectWindow("C1-" + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_GFP_stack_t_" + i + ".tif");
					close("chop_" + no_chops + "_GFP_stack_t_" + i + ".tif");
					selectWindow("C2-" + "chop_" + no_chops + "_stack_t_" + i + ".tif");
					saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + "_mCherry_stack_t_" + i + ".tif");
					close("chop_" + no_chops + "_mCherry_stack_t_" + i + ".tif");
					//close("chop_" + no_chops + "_stack_t_" + i + ".tif");
						
					// Insert the registered z-projection into the z-projected stack called chop_x
					selectWindow("chop" + no_chops);
					run("Make Substack...", "frames="+1+"-"+(i-1));
					rename("Before");
											
					close("chop" + no_chops);
					run("Concatenate...", "  title=chop" + no_chops + " open image1=Before image2=Frame2Insert image3=[-- None --] image4=[-- None --]");
				}	
			}
			saveAs("Tiff", worm_folder_straightened + "chop_" + no_chops + "/"  + "chop_" + no_chops + ".tif");
			close("chop_" + no_chops + ".tif");
			no_chops = no_chops + 1;		
		}
	}
	
	close("*");
}
///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


function get_frame_range(experiment_folder){
	frame_range=  newArray(1,2);
	
	//OPEN frames2delete.txt and delete slices, if it doesn't exist, do nothing
	if(File.exists(experiment_folder + "frame_range.txt")){
		filestring=File.openAsString(experiment_folder + "frame_range.txt");
		columns=split(filestring," ");
		for(i=0; i < columns.length; i++){					
			if (isNaN(parseInt(columns[i])) == 0){
				print("Frame range " + parseInt(columns[i]));
				frame_range[i] = parseInt(columns[i]);
			}
			else {
			 print("Something is wrong with the frame range file!!!");
			 frame_range[i] = NaN;
			}
		}				
	}
	else{
		frame_range[0] = 1;
		frame_range[1] = get_number_of_timepoints(experiment_folder + "/raw_data/");	
	}
	return frame_range;
}

function get_landmark_position(){
	shift=1;
	ctrl=2; 
	rightButton=4;
	alt=8;
	leftButton=16;
	insideROI = 32; // requires 1.42i or later

	
	x2=-1; y2=-1; z2=-1; flags2=-1;

	not_clicked = true;
	
	while (not_clicked) {
	  getCursorLoc(x, y, z, flags);
	  if (x!=x2 || y!=y2 || z!=z2 || flags!=flags2) {
	      if (flags&leftButton!=0) {
	      	a = newArray(2);
	      	a[0] = x;
	      	a[1] = y;
	      	not_clicked = false;
	      	}
	  }
	  wait(10);
	}
	return a;
}


function get_number_of_timepoints(folder){
	
	no_timepoints = 0;
	list = getFileList(folder);
	for (i=0; i<list.length; i++) {
	    if (endsWith(list[i], ".tif")){
	       	len_t_string = indexOf(list[i], "xy") - indexOf(list[i], "t") -1;	       	
	       	print(len_t_string);
	       	break;
		}
	 }

	tmp = "1";
	nozeros2add = len_t_string - lengthOf(tmp);
	for (i=0; i<nozeros2add; i++) {
			tmp = "0" + tmp;			
	}	
	
	filename = "t" + tmp +  "xy1z01c1.tif";	
	print(filename);
	
	while(File.exists(folder + "/" + filename)!= 0){
		no_timepoints = no_timepoints + 1;	
		t_string = toString(no_timepoints + 1);

		nozeros2add = len_t_string - lengthOf(t_string);

		for (i=0; i<nozeros2add; i++) {
			t_string = "0" + t_string;			
		}
		filename = "t" + t_string +  "xy1z01c1.tif";		
	}

	return no_timepoints;
}

function get_number_of_positions(experiment_folder, worm_index){

	no_positions = 0;
	while (File.isDirectory(experiment_folder + "/worm_" + worm_index + "_straightened/Pos" + no_positions + "/")!= 0) {
		no_positions = no_positions + 1;
	}
	return no_positions;
}

