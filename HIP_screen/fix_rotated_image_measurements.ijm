directory=getDirectory("Choose Folder with Images");
filelist = getFileList(directory);
roiManager("reset");

for(i=0;i<filelist.length;i++){
	if(!endsWith(filelist[i],".JPG")) continue;
	open(directory+filelist[i]);
	orig=getTitle();
	dupname=substring(orig,0, lengthOf(orig)-4);
	run("Duplicate...", " ");
	rename("dup");
	waitForUser("Transform -> Rotate to fix image and click okay to continue.");
	makeRectangle(375, 336, 4104, 2730);
	waitForUser("Fix the rectangular ROI to go through outer colonies and click to continue");
	roiManager("add");
	roiManager("save", directory+dupname+"_corrected_roi.roi");
	roiManager("select", 0);

	//run plate analysis
	run("plate analysis jru v1", "#_of_spots=384 xy_ratio=1.50000 spot_radius=100 #_x_replicates=1 #_y_replicates=1 circ_background circ_background_stat=Avg show_rois output_2d_plot");
	selectWindow("dup");
	roiManager("show all without labels");
	run("Flatten");
	rename("flat");
	save(directory+dupname+"_flattened_circ_rois.jpg");
	close("flat");

	//close unwanted windows
	run("close all tables jru v1");
	close("dup");
	close(orig);
	selectWindow("2D Plate Intensities");

	//get measurements as list from plot window
	run("PlotWindow Extensions jru v1");
	Ext.plot2List();
	run("delete table column jru v1", "table1=[Plot Values] column_to_delete=X1 replace");
	run("add row numbers jru v1", "windows=[Plot Values] replace");
	run("add table column jru v1", "windows=[Plot Values] column_labels=Y1 column_name=row2 equation=Math.floor(row/24) replace");
	run("add table column jru v1", "windows=[Plot Values] column_labels=Y1 column_name=col equation=row%24 replace");
	run("edit column labels jru v1", "table1=[Plot Values] col1=density col2=sample col3=row col4=col");
	newname=dupname+"_avg_list.csv";
	print(newname);
	run("export table jru v1", "table1=[Plot Values] format=csv save=["+directory+newname+"]");
	run("close all tables jru v1");
	run("Close All");
	roiManager("reset");
}


	
	
