// @String(label="List of channel to analyze", value=1, 2, 3) chanOI

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
	
	//Create a big table with all the results
	X=Table.getColumn("Centroid.X", "mask-morpho");
	Y=Table.getColumn("Centroid.Y", "mask-morpho");
	Z=Table.getColumn("Centroid.Z", "mask-morpho");
	vol=Table.getColumn("Volume", "mask-morpho");
	Table.create("Summary");
	Table.set("Image", 0, name, "Summary");
	run("Split Channels");
	chanOI=split(chanOI, ",");

	for (i = 0; i < chanOI.length; i++) {
		chan=parseFloat(chanOI[i]);
		channame="C"+chan+"-ori";
		
		run("Intensity Measurements 2D/3D", "input=&channame labels=[mask nuc] mean");
		Table.rename(channame+"-intensity-measurements", "nuclei");
		
		run("Intensity Measurements 2D/3D", "input=&channame labels=[mask cyto] mean");
		Table.rename(channame+"-intensity-measurements", "cyto");
		
		
		nuc=Table.getColumn("Mean","nuclei");
		cyto=Table.getColumn("Mean","cyto");
		
		Table.setColumn("C"+ chan+ "-in-nuclei", nuc, "Summary");
		Table.setColumn("C"+ chan+ "-in-cytoplasm", cyto, "Summary");
		Table.update;
	}
	Table.setColumn("X", X, "Summary");
	Table.setColumn("Y", Y, "Summary");
	Table.setColumn("Z", Z, "Summary");
	Table.setColumn("Volume", vol, "Summary");
	Table.update;
	
	// Clean up
	close("nuclei"); close("cyto");
	close("mask-morpho"); close("mask cyto"); close("mask nuc");
	
	//Add the mask as a new channel on the original image
	selectWindow("mask full");
	setMinAndMax(0, 255);
	run("8-bit");
	merge_string = "";
	for (i = 0; i < channels; i++) {
		merge_string += "c" + i + "=[C" + i + "-ori] ";
		}
	merge_string += "c" + channels + 1 + "-ori";
	run("Merge Channels...", merge_string);
	rename(substring(name, 0, lengthOf(name)-3)+"_mask");
	setBatchMode("exit and display");
}