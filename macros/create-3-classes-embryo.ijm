setBatchMode(true);
getDimensions(width, height, channels, slices, frames);
name=getTitle();
run("Duplicate...", "duplicate");
setAutoThreshold("Default dark");
//run("Threshold...");
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark calculate black");
val=0;
i=1;
//run("Set Measurements...", "min stack display redirect=None decimal=3");
while (val==0) {
	setSlice(i);
	if (getValue("Max")==255) {
		val=1;
		run("Divide...", "value=255 slice");
	}
	i++;
}
for (i; i <= nSlices; i++) {
	setSlice(i);
	run("Create Selection");
	if (is("area")) {
		run("Enlarge...", "enlarge=-10");
		run("Divide...", "value=128 slice");
		run("Make Band...", "band=20");
		run("Set...", "value=3 slice");
	}
}
rename(name);
setBatchMode(false);