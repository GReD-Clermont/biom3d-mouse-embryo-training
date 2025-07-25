// @ImagePlus myimage
// @Integer(label="Lamin channel", value=1) lamin
// @Integer(label="DAPI channel", value=4) dapi
// @Integer(label="Dynamic", value=12) dynamic
// @Double(label="Gaussian size (um)", value=0.27, stepSize=0.05) gaussian
// @Double(label="Unsharp (pixels)", value=20.0, stepSize=0.05) unsharp
// @Double(label="Scale factor", value=0.5, stepSize=0.1) scale
// @Boolean(label="Background subtraction", value=false) background_subtraction

title = getTitle();
getVoxelSize(v_width, v_height, v_depth, unit);
getDimensions(width, height, channels, slices, frames);

setBatchMode("hide");

upscale_z = scale * v_depth / v_width;
voxel_volume = v_width * v_height * v_depth;
fsize_xy = scale * gaussian / v_width;
fsize_z = scale * gaussian / v_depth;

//run("Duplicate...", "duplicate title=[tmp-"+imageTitle+"] channels="+lamin);
run("Duplicate...", "duplicate title=tmp channels="+lamin);
run("Enhance Contrast...", "saturated=0.35 normalize process_all");
run("Cyan");
run("Scale...", "x=" + scale + " y=" + scale + " z=" + upscale_z + " interpolation=Bilinear average process create title=[tmp-" + title + "]");
close("tmp");
if(background_subtraction) {
    run("Duplicate...", "title=bg duplicate");
    run("Gaussian Blur 3D...", "x="+fsize_xy+" y="+fsize_xy+" z="+fsize_xy);
    imageCalculator("Subtract stack", "tmp-"+title, "bg");
    close("bg");
}
run("Gaussian Blur 3D...", "x=" + fsize_xy + " y=" + fsize_xy + " z=" + fsize_xy);
run("Extended Min & Max 3D", "operation=[Extended Minima] dynamic=" + dynamic + " connectivity=6");
rename("tmp-regmin");
run("Connected Components Labeling", "connectivity=26 type=float");
rename("tmp-regmin-labels");
run("Impose Min & Max 3D", "original=[tmp-" + title + "] marker=tmp-regmin operation=[Impose Minima] connectivity=6");
rename("tmp-imposedmin");
run("Marker-controlled Watershed", "input=tmp-imposedmin marker=tmp-regmin-labels mask=None calculate use");
rename("tmp-labels");
close("Log");
run("Remove Border Labels", "left right top bottom");
rename("tmp-labels2");
run("Scale...", "width=" + width + " height=" + height + " depth=" + slices + " interpolation=None process create");
run("Remap Labels");
rename("labels");
run("16-bit");
run("glasbey_on_dark");
close("tmp-*");
selectWindow(title);
run("Split Channels");
run("Merge Channels...", "c1=[C1-"+title+"] c2=[C2-"+title+"] c3=labels create");
setBatchMode("exit and display");