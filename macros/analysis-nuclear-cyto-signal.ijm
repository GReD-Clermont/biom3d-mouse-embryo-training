//Create a mask from 3D ROIs, it needs a specific naming of ROIs to work
n=roiManager("count");
if (n>0) {
	name=getTitle();
	setBatchMode(true);
	run("Duplicate...", "duplicate");
	rename("ori");
	getDimensions(width, height, channels, slices, frames);
	namewoext=substring(name,0,name.length-4);
	namemask=namewoext+"_mask";
	newImage(namemask, "16-bit black", width, height, slices);
	for (j=0; j<n; j++) {
		selectWindow(namemask);
		roiManager("Select", j);
		roiname=Roi.getName;
		idx=indexOf(roiname, "#");
		idxpar=indexOf(roiname, "(");
		cellnb=parseFloat(substring(roiname, idx+1, idxpar));
		run("Set...", "value=&cellnb slice");
		}

	// Expand the label to get an equivalent of cytoplasmic and nuclear signal
	rename("mask nuc");
	run("Label Morphological Filters", "operation=Dilation radius=10 from_any_label");
	rename("mask full");
	imageCalculator("Subtract create stack", "mask full","mask nuc");
	rename("mask cyto");
	
	//Do the measurments
	selectWindow("mask nuc");
	run("Analyze Regions 3D", "volume centroid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
	selectWindow("ori");
	run("Split Channels");
	run("Intensity Measurements 2D/3D", "input=C3-ori labels=[mask nuc] mean");
	Table.rename("C3-ori-intensity-measurements", "fish-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C1-ori labels=[mask nuc] mean");
	Table.rename("C1-ori-intensity-measurements", "DAPI-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C2-ori labels=[mask nuc] mean");
	Table.rename("C2-ori-intensity-measurements", "C2-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C4-ori labels=[mask nuc] mean");
	Table.rename("C4-ori-intensity-measurements", "C4-in-nuclei");
	run("Intensity Measurements 2D/3D", "input=C3-ori labels=[mask cyto] mean");
	Table.rename("C3-ori-intensity-measurements", "fish-in-cyto");
	run("Intensity Measurements 2D/3D", "input=C2-ori labels=[mask cyto] mean");
	Table.rename("C2-ori-intensity-measurements", "C2-in-cyto");
	run("Intensity Measurements 2D/3D", "input=C4-ori labels=[mask cyto] mean");
	Table.rename("C4-ori-intensity-measurements", "C4-in-cyto");
	
	//Create a big table with all the results
	X=Table.getColumn("Centroid.X", "mask-morpho");
	Y=Table.getColumn("Centroid.Y", "mask-morpho");
	Z=Table.getColumn("Centroid.Z", "mask-morpho");
	vol=Table.getColumn("Volume", "mask-morpho");
	C1nuc=Table.getColumn("Mean","DAPI-in-nuclei");
	C2nuc=Table.getColumn("Mean","C2-in-nuclei");
	C4nuc=Table.getColumn("Mean","C4-in-nuclei");
	C2cyto=Table.getColumn("Mean","C2-in-cyto");
	C4cyto=Table.getColumn("Mean","C4-in-cyto");
	fishcyto=Table.getColumn("Mean","fish-in-cyto");
	selectWindow("fish-in-nuclei");
	Table.renameColumn("Mean", "fish-in-nuclei", "fish-in-nuclei");
	Table.setColumn("DAPI-in-nuclei", C1nuc, "fish-in-nuclei");
	Table.setColumn("C2-in-nuclei", C2nuc, "fish-in-nuclei");
	Table.setColumn("C4-in-nuclei", C4nuc, "fish-in-nuclei");
	Table.setColumn("fish-in-cyto", fishcyto, "fish-in-nuclei");
	Table.setColumn("C2-in-cyto", C2cyto, "fish-in-nuclei");
	Table.setColumn("C4-in-cyto", C4cyto, "fish-in-nuclei");
	Table.setColumn("X", X, "fish-in-nuclei");
	Table.setColumn("Y", Y, "fish-in-nuclei");
	Table.setColumn("Z", Z, "fish-in-nuclei");
	Table.setColumn("Volume", vol, "fish-in-nuclei");
	Table.rename("fish-in-nuclei", "The Results");
	Table.update;
	
	// Clean up
	close("c1-in-nuclei"); close("c2-in-nuclei"); close("C4-in-nuclei"); close("fish-in-cyto"); close("C2-in-cyto"); close("C4-in-cyto");
	close("mask-morpho"); close("mask cyto"); close("mask nuc");
	
	//Add the mask as a new channel on the original image
	selectWindow("mask full");
	setMinAndMax(0, 255);
	run("8-bit");
	run("Merge Channels...", "c1=C1-ori c2=C2-ori c3=C3-ori c4=C4-ori c5=[mask full] create");
	rename(substring(name, 0, lengthOf(name)-3)+"_mask");
	setBatchMode("exit and display");
}