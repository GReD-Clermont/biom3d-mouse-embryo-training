// @File(label="Directory to use", style="directory") dir
// @Integer(label="Number of file samples", value=13) n_samples

var dir;
if (dir == 0) {
	dir=getDir("Choose a directory");
}

var n_samples;
if (n_samples == 0) {
	n_samples = 13;
}

dir = dir + File.separator;
oridir = dir + "original";
segdir = dir + "mask";
oritest = dir + "original_test";
segtest = dir + "segmentation_test";
File.makeDirectory(oritest);
File.makeDirectory(segtest);
filelist = getFileList(oridir);
setBatchMode(true);
nfile = lengthOf(filelist);
for (i = 0; i < n_samples; i++) {
	randfactor = round(random * nfile);
	open(oridir + File.separator + filelist[randfactor]);
	//Save the image as .tif in a folder called "original"
	name=File.nameWithoutExtension;
	saveAs(".tif", oritest + File.separator + name);
	close();
	File.delete(oridir + File.separator + filelist[randfactor]);

	open(segdir + File.separator + filelist[randfactor]);
	name=File.nameWithoutExtension;
	saveAs(".tif", segtest + File.separator + name);
	close();
	File.delete(segdir + File.separator + filelist[randfactor]);
}
print("Done");
wait(1000);
run("Close");