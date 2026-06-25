//from Hervé Alégot



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
	
	rename("mask nuc");
	
	//Do the measurments
	selectWindow("mask nuc");
	run("Analyze Regions 3D", "volume centroid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
	selectWindow("ori");
	run("Split Channels");
	run("Intensity Measurements 2D/3D", "input=C3-ori labels=[mask nuc] mean");
	Table.rename("C3-ori-intensity-measurements", "C3-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C2-ori labels=[mask nuc] mean");
	Table.rename("C2-ori-intensity-measurements", "C2-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C1-ori labels=[mask nuc] mean");
	Table.rename("C1-ori-intensity-measurements", "C1-in-nuclei");

	
	//Create a big table with all the results
	X=Table.getColumn("Centroid.X", "mask-morpho");
	Y=Table.getColumn("Centroid.Y", "mask-morpho");
	Z=Table.getColumn("Centroid.Z", "mask-morpho");
	vol=Table.getColumn("Volume", "mask-morpho");
	C2nuc=Table.getColumn("Mean","C2-in-nuclei");
	C1nuc=Table.getColumn("Mean","C1-in-nuclei");
	
	selectWindow("C3-in-nuclei");
	Table.renameColumn("Mean", "C3-in-nuclei", "C3-in-nuclei");
	Table.setColumn("C2-in-nuclei", C2nuc, "C3-in-nuclei");
	Table.setColumn("C1-in-nuclei", C1nuc, "C3-in-nuclei");

	Table.setColumn("X", X, "C3-in-nuclei");
	Table.setColumn("Y", Y, "C3-in-nuclei");
	Table.setColumn("Z", Z, "C3-in-nuclei");
	Table.setColumn("Volume", vol, "C3-in-nuclei");
	Table.rename("C3-in-nuclei", "Results");
	Table.update;
	
	// Clean up
	close("c2-in-nuclei"); close("c1-in-nuclei");
	close("mask-morpho"); close("mask nuc"); close("*ori*");
	
	//Count the number of cells above a given intensity for channel 2 and 3 and the percentage of total cell number
	C2 = Table.getColumn("C2-in-nuclei");
	C3 = Table.getColumn("C3-in-nuclei");
	nC2 = 0;
	nC3 = 0;
	for (i = 0; i < nResults; i++) {
		if (C2[i] > 10) {
			nC2 = nC2+1;
		}
		if (C3[i] > 20) {
			nC3 = nC3+1;
		}
	}
	
	Table.create("Numbers");
	Table.set("C2 number", 0, nC2);
	Table.set("C3 number", 0, nC3);
	Table.set("Total nuclei", 0, nResults);
	ratioC2 = nC2 / nResults * 100;
	ratioC3 = nC3 / nResults *100;
	Table.set("Ratio C2", 0, ratioC2);
	Table.set("Ratio C3", 0, ratioC3);
	
	
	setBatchMode("exit and display");
}