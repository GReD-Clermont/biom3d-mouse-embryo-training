//Create a mask from 3D ROIs, it needs a specific naming of ROIs to work
n=roiManager("count");
if (n>0) {
	name=getTitle();
	getVoxelSize(voxw, voxh, voxd, voxunit);
	setBatchMode(true);
	
	run("Duplicate...", "duplicate");
	rename("ori");
	run("Properties...", "origin=0,0,0");
	
	getDimensions(width, height, channels, slices, frames);
	namewoext=substring(name,0,name.length-4);
	namemask=namewoext+"_mask";
	newImage(namemask, "16-bit black", width, height, slices);
	setVoxelSize(voxw, voxh, voxd, voxunit);
	for (j=0; j<n; j++) {
		selectWindow(namemask);
		roiManager("Select", j);
		if(Roi.size > 0) {
			if(Roi.getType != "point") {
				//roi_index = Roi.getProperty("ROI");
				roiname = Roi.getName;
				idx = indexOf(roiname, "#");
				idxpar = indexOf(roiname, "(");
				cellnb=parseFloat(substring(roiname, idx+1, idxpar));
				run("Set...", "value=&cellnb slice");
			}
		}
	}
	
	// Export point coordinates
	run("Set Measurements...", "median redirect=None decimal=3");
	for (j=0; j<n; j++) {
		roiManager("Select", j);
		if(Roi.size > 0) {
			if(Roi.getType == "point") {
				roi_index = Roi.getProperty("ROI");
				roiManager("measure");
			}
		}
	}
	if(Table.size > 0) {
		Table.rename(Table.title, "PE");
	}
	
	rename(name + "_mask");
	
	setThreshold(1, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "background=Dark black");
	
	setBatchMode(false);
}