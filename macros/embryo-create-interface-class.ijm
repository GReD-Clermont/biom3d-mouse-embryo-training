name=getTitle();
rename("tmp");
//Split channel, works with label image
run("Split Channels");
selectImage("C3-tmp");
//Dilate and erode the label image, then subtract the original image
run("Morphological Filters (3D)", "operation=Closing element=Cube x-radius=5 y-radius=5 z-radius=5");
imageCalculator("Subtract stack", "C3-tmp-Closing","C3-tmp");
//Dilate the interface voxel and set them to 2
run("Morphological Filters (3D)", "operation=Dilation element=Cube x-radius=2 y-radius=2 z-radius=2");
setThreshold(1, 65535);
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark black");
run("Divide...", "value=255 stack");
run("Multiply...", "value=2 stack");
//Set the label to 1
selectWindow("C3-tmp");
setThreshold(1, 65535);
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark black");
run("Divide...", "value=255 stack");
//Merge both masks
imageCalculator("Max stack", "C3-tmp","C3-tmp-Closing-Dilation");
selectWindow("C3-tmp");
//Merge channels
run("16-bit");
run("Merge Channels...", "c1=C1-tmp c2=C2-tmp c3=C3-tmp create");
rename(name);
close("C3-*");