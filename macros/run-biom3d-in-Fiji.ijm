// @File (label="Select the python executable used for biom3d", style="file", value="C:\\Miniconda3\\envs\\b3d\\python") python
// @File (label="Select the directory model", style="directory", value="C:\\biom3d\\20240701-144924-mouse_embryo_nuclei_v3_fold0") model_dir
// @Integer(label="DAPI", value=3) dapi
// @Double(label="Scale factor", value=1.0, stepSize=0.1) scale

// Function to convert labels to ROIs
function labels_to_rois_4D(labelsId) {
	selectImage(labelsId);
	setBatchMode("hide");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(v_width, v_height, v_depth, unit);
	Stack.getStatistics(voxelCount, mean, min, n_cells, stdDev);
	for(i=0; i<n_cells; i++) {
		showProgress(i+1, n_cells);
		setThreshold(i+1, i+1);
		for(t=1; t<=frames; t++) {
			Stack.setFrame(t);
			for(z = 1; z <= slices; z++) {
				Stack.setSlice(z);
				run("Create Selection");
				if(Roi.size > 0) {
					Roi.setPosition(0, z, t);
					Roi.setProperty("ROI", i+1);
					Roi.setProperty("ROI_NAME", "Cell #" + i+1);
					Roi.setName("Cell #" + i+1 + " (z=" + z + ", t=" + t + ")");
					// Use ROI groups, but only up to 255
					if(n_cells < 256) Roi.setGroup(i+1);
					Overlay.addSelection();
				}
			}
		}
	}
	setBatchMode("exit and display");
}

// Function to delete files and log warnings
function delete_file(path) {
	if(!File.delete(path)) {
		IJ.log("File/folder not properly deleted: " + path);
	}
}

// Function to delete temp files
function clean_up(inDir, outDir, resDir) {
	deleted = true;
	inFiles = getFileList(inDir);
	for (i=0; i<inFiles.length; i++) {
		delete_file(inDir + inFiles[i]);
	}
	delete_file(inDir);
	resFiles = getFileList(resDir);
	for (i=0; i<resFiles.length; i++) {
		delete_file(resDir + resFiles[i]);
	}
	delete_file(resDir);
	delete_file(outDir);
}

// Get model name
model_name = File.getName(model_dir);

// Get image title and dimensions
title = getTitle();
img_id = getImageID();
getDimensions(width, height, channels, slices, frames);

// Create timestamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
timestamp = "" + year + "-" + month + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + "-" + msec;

// Create input/output directories in temp directory
tmp_dir = getDirectory("temp");
in_dir = tmp_dir + timestamp + "_in" + File.separator;
out_dir = tmp_dir + timestamp + "_out" + File.separator;

File.makeDirectory(in_dir);
if (!File.exists(in_dir)) {
	exit("Unable to create input directory.");
}

File.makeDirectory(out_dir);
if (!File.exists(out_dir)) {
	exit("Unable to create output directory.");
}

// Create image from DAPI channel if multiple channels
if(channels > 1) {
	run("Duplicate...", "duplicate title=[dapi-" + title + "] channels=" + dapi);
}

// Downscale or upscale
if(scale != 1) {
	getVoxelSize(v_width, v_height, v_depth, unit);
	scale_z = scale * v_depth / v_width;
	run("Scale...", "x=" + scale + " y=" + scale + " z=" + scale_z + " interpolation=Bilinear average process create title=[tmp-" + title + "]");
}

// Save image as TIF
fullname=in_dir+title;
print(fullname);
saveAs("tiff", fullname);
filename = getInfo("image.filename");

close();
close("dapi-" + title);

// Close image if it is a duplicate
current_id = getImageID();
if(current_id != img_id) {
	close();
	selectImage(img_id);
}

// Run Biom3D
cmd = "cmd /c start " + python + " -m biom3d.pred --log " + model_dir + " --dir_in " + in_dir + " --dir_out " + out_dir + " & timeout 5";
//res = exec(python + " -m biom3d.pred --log " + model_dir + " --dir_in " + in_dir + " --dir_out " + out_dir);
//res = exec(python, "-m", "biom3d.pred", "--log", model_dir, "--dir_in", in_dir, "--dir_out", out_dir);
res = exec(cmd);

// Open results
res_dir = out_dir + model_name + File.separator;
res_file = res_dir + filename;
if(!File.exists(res_file)) {
	print(res);
	clean_up(in_dir, out_dir, res_dir);
	exit("Output file (" + res_file + ") does not exist.");
}
open(res_file);

// Rescale results if needed
res_title = getTitle();
if(scale != 1) {
	run("Scale...", "width=" + width + " height=" + height + " depth=" + slices + " interpolation=None process create");
	close(res_title);
	rename(res_title);
}
res_id = getImageID();

// Compute labels
setThreshold(1, 1, "raw");
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark black");
run("Scale...", "width=" + width/2 + " height=" + height/2 + " depth=" + slices*2 + " interpolation=None process create");
run("Distance Transform Watershed 3D", "distances=[Borgefors (3,4,5)] output=[16 bits] normalize dynamic=1 connectivity=6");
run("3D Binary Close Labels", "radiusxy=15 radiusz=5 operation=Close");
run("Scale...", "width=" + width + " height=" + height + " depth=" + slices + " interpolation=None process create");
run("glasbey_on_dark");
rename("labels-" + title);
labels_id = getImageID();
selectImage(res_id);
close();
selectImage(labels_id);
labels_to_rois_4D(labels_id);
run("To ROI Manager");
selectImage(labels_id);
close();
selectImage(img_id);
roiManager("Show All");

// Clean up
clean_up(in_dir, out_dir, res_dir);

//print parameters
print("path to python : "+python);
print("path to model : "+ model_dir);
print("DAPI channel = "+dapi);
print("Scaling factor = "+scale);