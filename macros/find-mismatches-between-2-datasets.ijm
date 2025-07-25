// @File(label="Directory to use", style="directory") dir

var dir;
if (dir == 0) {
	dir=getDir("Choose a directory");
}
dir = dir + File.separator;

oridir = dir + "ori";
segdir = dir + "seg";

orilist = getFileList(oridir);
seglist = getFileList(segdir);

setBatchMode(true);

nori=lengthOf(orilist);
nseg=lengthOf(seglist);

if (nori>=nseg) {
	for (i = 0; i < nori; i++) {
		if (File.exists(segdir + File.separator + orilist[i])==0){
			print(orilist[i]);
		}
	}
}

if (nori<=nseg) {
	for (j = 0; j < nseg; j++) {
		if (File.exists(oridir + File.separator + seglist[j])==0){
			print(seglist[j]);
		}
	}
}

print("Done");
