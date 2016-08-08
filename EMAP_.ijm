//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
// latest release date: 07/25/2016
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

/**
	All Epithelial Morphology Macros were developed by Nathan Hotaling

	Many of the images produced in this code were based off of those tools and principles developed in the BioVoxxel toolbox. 
	To give Jan Brocher credit for all the fantastic work, we include the following copyright notice and software disclaimer.

	Copyright (C) 2012-2016, Jan Brocher / BioVoxxel.

	THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ?AS IS? AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR 
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
	TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
	USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	
	
*/

requires("1.50a");
IJorFIJI = getVersion();


//Define Crop size of all images to be analyzed and define which segmentation algorithms to use
		Dialog.create("Cell Morphological Assessment Tool");
		Dialog.setInsets(0, 150, 0);
			Dialog.addMessage("Graphic Options");
				Col_labels1 = newArray("All", "Just Neighbors", "All But Neighbors", "None");
					Dialog.addChoice("Create Colored Images:", Col_labels1, "All");
				
		Col_labels2 = newArray("Thermal", "Green", "mpl-magma","phase", "Fire", "Jet", "Cyan Hot");
				Dialog.addChoice("Coloring:", Col_labels2, "thermal");
				
		Col_labels3 = newArray("Tif Stack","JPEG Montage", "PNG Montage", "Tif Separate Images","JPEG Separate Images", "PNG Separate Images");
			Dialog.addChoice("Image Format", Col_labels3, "Tif Stack");
				Dialog.addMessage("*Note: Image generation takes the majority of the processing time \n If Images are large Tif Stacks may fail");
				
		Dialog.setInsets(25, 103, 0);
		Dialog.addMessage("Cell Size Restrictions for Analysis");	
				Dialog.addString("Lower Cell Size (Pixels)", 100);
				Dialog.addString("Upper Cell Size (Pixels)", 11000);	
				
	Dialog.setInsets(25, 120, 0);
		Dialog.addMessage("Automated Unit Conversion");		
			radio_items = newArray("Yes", "No");
			Dialog.setInsets(0, 0, 0);
			Dialog.addRadioButtonGroup("Do you want to convert all output from pixels to real units?", radio_items, 1, 2, "Yes");
				Dialog.addNumber("Length of scale bar", 208, 0, 7, "Pixels");
				Dialog.addNumber("Length of scale bar", 100, 0 , 7, "Microns");	
		
		Dialog.show;
		
			graphic_choice = Dialog.getChoice();
			LUT_choice = Dialog.getChoice();
			graphic_format = Dialog.getChoice();	
			unit_conv = Dialog.getRadioButton();
			
			pore_lower = Dialog.getString();
			pore_upper = Dialog.getString();
			
			
			unit_pix = Dialog.getNumber();
			unit_real = Dialog.getNumber();

// Asks for a directory where Tif files are stored that you wish to analyze
	dir1 = getDirectory("Choose Source Directory ");
		list = getFileList(dir1);
		setBatchMode(true);
		
	T1 = getTime();	
	


	for (i=0; i<list.length; i++) {
		showProgress(i+1, list.length);
		filename = dir1 + list[i];
	if (endsWith(filename, "tif")) {
		open(filename);
		

// Save Converted B&W image into a new folder called Processed
	myDir = dir1+"Segmented Images"+File.separator;

	File.makeDirectory(myDir);
		if (!File.exists(myDir))
			exit("Unable to create directory");
		
// Save Analysis of Particles to a csv file in this directory
	myDir1 = dir1+"Analysis"+File.separator;

	File.makeDirectory(myDir1);
		if (!File.exists(myDir1))
			exit("Unable to create directory");

if(list.length>1){
// Saves Numbered Binary Outlines to Subdirectory labeled Counted Borders
	myDir2 = dir1+"Combined Files"+File.separator;

	File.makeDirectory(myDir2);
		if (!File.exists(myDir2))
			exit("Unable to create directory");		
	}
// Saves Colored Images to Subdirectory labeled Counted Borders
	myDir3 = dir1+"Color Coded"+File.separator;

	File.makeDirectory(myDir3);
		if (!File.exists(myDir3))
			exit("Unable to create directory");					
			
// Sets Scale of picture to pixels 
	run("Set Scale...", "distance=0  known=0 pixel=1 unit= pixels");
	
// Creates custom file names for use later
		var name0=getTitle;
			name0a = replace(name0,"_outlines.tif","");
		var name1=name0+"_Counted";
			name1= replace(name1,".tif","");
		var name2=name0+"_Data";
			name2= replace(name2,".tif","");
		var name3=name0+"_Outlines";
			name3= replace(name3,".tif","");
		name4 = name0 + "_Neighbors";
			name4= replace(name4,".tif","");
		name5= name0 + "_Neighbors";
			name5= replace(name5,".tif","");
		name6= name0 + "_Neighbor Legend";
			name6= replace(name6,".tif","");
		name7= name0 + "_Visualized";
			name7= replace(name7,".tif","");
		name8= name0 + "_Metrics Legend";
			name8= replace(name8,".tif","");			
		
// Creates custom file paths for use later
		path0 = myDir+name0;
		path1 = myDir3+name1;
		path2 = myDir1+name2;
		path3 = myDir+name3;
		path4 = myDir3+name4;
		path5 = myDir1+name5;
		path6 = myDir3+name6;
		path7 = myDir3+name7;
		path8 = myDir3+name8;
		
if(isOpen("Log")==1) { selectWindow("Log"); run("Close"); }		

//Creates some variables for use in the code below.		
		lower = 0;
		upper = 0;	
		size = pore_lower + "-" + pore_upper;
//		size = "0-Infinity";
		wid=getWidth();
		hig=getHeight();
		vscale= 30;
		wscale= 5;
		totalw= floor(wid/wscale);
		totalh= floor(hig/vscale);
		totalht= totalh*1.5;
		color= "black" ;
		method= "Particle Neighborhood";
		hoodRadius= 5;
		watershed= false;
		circularity= "0.00-1.00";
		excludeEdges= true;
		calibrationbar= true;
		createPlot= true;
		
// Saves B&W cell outlines for analysis		
	run("Find Edges");	
	//run("Threshold...");
	setThreshold(lower, upper);
		setOption("BlackBackground", false);
		run("Convert to Mask");
/**		
			run("Voronoi");	
		//run("Threshold...");
			setThreshold(lower+1, upper+255);
				setOption("BlackBackground", true);
				run("Convert to Mask");

*/				
					saveAs("Tiff", path3);
					close();
				
//*****************************************************************************************************************************************************************************************************************		
// Create a neighbor analysis and color map 
				
	
//Opens files of interest and parses them into new variable values	
	open(path3+".tif");
		
		name0 = getTitle;
			name0= replace(name0,"_Data.tif","");
		
		original=getTitle();
		type=is("binary");
		if(type==false) { exit("works only with 8-bit binary images"); }
			getDimensions(width, height, channels, slices, frames);
			run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
				if(isOpen("Log")==1) { selectWindow("Log"); print("\\Clear"); }
	print("Finding Neighbors for " + name0);
	
//Setup
	selectWindow(original);
		run("Select None");
	
		run("Invert");
		edges="exclude";
	
//prepare original image for analysis
	if(unit_conv == "Yes") {
		run("Set Scale...", "distance=unit_pix known=unit_real unit=microns");
		}
	
		run("Analyze Particles...", "size="+size+" pixel circularity="+circularity+" show=Masks "+edges+" clear");
		run("Invert LUT");
		rename(original+"-1");
		original=getTitle();
	
	run("Duplicate...", "title=[NbHood_"+original+"]");
		neighborhood=getTitle();
		selectWindow(neighborhood);
		run("Set Measurements...", "  centroid redirect=None decimal=3");
	if(unit_conv == "Yes") {
		run("Set Scale...", "distance=unit_pix known=unit_real unit=microns");
		}
		run("Analyze Particles...", "size="+size+" pixel circularity=0.00-1.00 show=Nothing clear record");
	
		
//define variables
		initialParticles=nResults;
		X=newArray(nResults);
		Y=newArray(nResults);
		neighborArray=newArray(nResults);
		neighbors=0;
		mostNeighbors=0;
		
		
//retveive particle coordinates
	run("Set Scale...", "distance=0  known=0 pixel=1 unit= pixels");
		for(l=0; l<initialParticles; l++) {
			X[l]=getResult("XStart", l);
			Y[l]=getResult("YStart", l);
			toUnscaled(X[l], Y[l]);
		}
		
		
//prepare selector image
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Set Measurements...", " centroid redirect=None decimal=3");
		run("Wand Tool...", "mode=Legacy tolerance=0");
		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
			
		
//create selector neighborhood
		for(hood=0; hood<initialParticles; hood++) {
			selectWindow(neighborhood);
				run("Select None");
				run("Duplicate...", "title=[Selector_"+original+"]");
					selector=getTitle();
					doWand(X[hood], Y[hood]);
			run("Enlarge...", "enlarge="+hoodRadius);
				run("Fill");
				run("Select None");
					doWand(X[hood], Y[hood]);
					selectWindow(neighborhood);
				run("Restore Selection");
			run("Analyze Particles...", "size="+size+" pixel circularity=0.00-1.00 show=Nothing clear record");
				neighbors = nResults-1;
				neighborArray[hood]=neighbors;
			
			if(neighbors>mostNeighbors) {
				mostNeighbors=neighbors;	
			}
			close(selector);
			
		}

	if(mostNeighbors==0) {
		exit("no neighbors detected\ndid you choose the correct particle color?");
	}
	
	
//Color coded original features
	
if(graphic_choice == "All" || graphic_choice == "Just Neighbors") {	
	selectWindow(original);
		run("Duplicate...", "title=[P-NbHood_"+hoodRadius+"_"+original+"]");
	particles=getTitle();

	selectWindow(particles);
	
	for(mark=0; mark<initialParticles; mark++) {
		markValue=neighborArray[mark];
		setForegroundColor(markValue, markValue, markValue);
		floodFill(X[mark],Y[mark], "8-connected");
	}
	
	run("Select None");		
	run("glasbey");
	close(original);
	}
	
//create distribution plot and neighbor files
		neighborList = newArray(mostNeighbors+1);
		Array.fill(neighborList, 0);
		for(num=0; num<initialParticles; num++) {
			nextNeighbor = neighborArray[num];
			if(nextNeighbor>0) {
				neighborList[nextNeighbor] = neighborList[nextNeighbor] + 1;
				}
		}

//		Plot.create("Distribution: " + particles, "neighbors", "count", neighborList);
//		Plot.addText("particles (total) = " + initialParticles, 0.01, 0.1);
//		setBatchMode("show");
		
		l3 = neighborList.length;
		Neighcat = Array.getSequence(l3);
		NeighCount = neighborList;
			run("Clear Results");
			
			for (ki=0; ki<l3; ki++) {
				setResult("Neighbors", ki, Neighcat[ki]);
				setResult(name0a, ki, NeighCount[ki]);
			}
			
			saveAs("Results", path5+".csv");
			run("Clear Results");
			
if(graphic_choice == "All" || graphic_choice == "Just Neighbors") {		
//Calibration Bar
		totalw_new = totalw-1;
		stepsize=floor(totalw/mostNeighbors);
		newImage("Calibration_"+original, "8-bit Black", totalw_new, totalh, 1);

			step=0;
		for(c=0; c<=mostNeighbors; c++) {
			makeRectangle(step, 0, totalw/mostNeighbors, totalh);
			setForegroundColor(c+1, c+1, c+1);
			run("Fill");
			step=step+stepsize;
			}
		run("Select None");
		run("glasbey");
		run("RGB Color");
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Canvas Size...", "width=totalw_new height=totalht position=Top-Center");
				setJustification("left");
				setFont("SansSerif", 0.7573*totalh*0.5-0.1783, "Bold");
			setJustification("center");
				for(il=1; il<=mostNeighbors; il++) {	
					drawString(il, totalw/mostNeighbors*(il-1)+totalw/mostNeighbors/2, totalht-1);
				}
//				saveAs("Tiff",path6);


		run("Select All");
			w2 = getWidth();
			h2 = getHeight();
			run("Copy");
			setPasteMode("Copy");
				selectWindow(particles);
					run("RGB Color");
					run("Select None");
					makeRectangle(1, 1, w2, h2); 
				run("Paste");	
				run("Select None");
				saveAs("Tiff",path4);
				run("Close All");		
		}
	
//*********************************************************************************************************************************************************************************************


//Create Color Maps for All Cell Shape Descriptors
	open(path3+".tif");
	setBatchMode(true);
	getDimensions(width, height, channels, slices, frames);
		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
		
		original=getTitle();
		color = "black";
		watershed = false;
		excludeEdges= true;
		includeHoles = false;
		calibrationbar = true;
		distributionPlot = true;
		LUT = LUT_choice;
		total_pixels = getWidth()*getHeight();

		if(graphic_choice == "All" || graphic_choice == "Just Neighbors") {	
			selectWindow(original);
				run("Select None");
					run("Invert");
			}  else {
					selectWindow(original);
					run("Select None");
				}

				edges = "exclude";
				holes = "";	
				
	if(unit_conv == "Yes") {
		run("Set Scale...", "distance=unit_pix known=unit_real unit=microns");
		}
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction redirect = None decimal = 3");

	run("Analyze Particles...", "size=size pixel circularity=0.00-1.00 show = Masks "+edges+" clear "+holes+" record");


		run("Invert LUT");
			rename("Input");
			input = getTitle();
				run("Duplicate...", "title = ShapeDescr_"+original);
					result = getTitle();
		
				allParticles = nResults;
					X = newArray(nResults);
					Y = newArray(nResults);
					Area = newArray(allParticles);
					Peri = newArray(allParticles);
					AoP = newArray(allParticles);
					ElipMaj = newArray(allParticles);
					ElipMin = newArray(allParticles);
					AR = newArray(allParticles);
					Angle = newArray(allParticles);
					Feret = newArray(allParticles);
					MinFeret = newArray(allParticles);
					FeretAR = newArray(allParticles);
					FeretAngle = newArray(allParticles);
					Circ = newArray(allParticles);
					Solidity = newArray(allParticles);
					Compactness = newArray(allParticles);
					Extent = newArray(allParticles);
					

					biggestArea = 0;
					biggestPeri = 0;
					biggestAoP = 0;
					biggestElipMaj = 0;
					biggestElipMin = 0;
					biggestAR = 0;
					biggestAngle = 0;
					biggestFeret = 0;
					biggestMinFeret = 0;
					biggestFeretAR = 0;
					biggestFeretAngle = 0;
					biggestCirc = 0;
					biggestSolidity = 0;
					biggestCompactness = 0;
					biggestExtent = 0;
					
					smallestArea = total_pixels;
					smallestPeri = total_pixels;
					smallestAoP = total_pixels;
					smallestElipMaj = total_pixels;
					smallestElipMin = total_pixels;
					smallestAR = total_pixels;
					smallestAngle = total_pixels;
					smallestFeret = total_pixels;
					smallestMinFeret = total_pixels;
					smallestFeretAR = total_pixels;
					smallestFeretAngle = total_pixels;
					smallestCirc = total_pixels;
					smallestSolidity = total_pixels;
					smallestCompactness = total_pixels;
					smallestExtent = total_pixels;


//read in positional information
	for(ni = 0; ni<allParticles; ni++) {
		X[ni] = getResult("X", ni);
		Y[ni] = getResult("Y", ni);
		toUnscaled(X[ni], Y[ni]); 

//read in shape descriptors 
		Area[ni] = getResult("Area", ni);
		Peri[ni] = getResult("Perim.", ni);
		AoP[ni] = (getResult("Area", ni)/getResult("Perim.", ni));
			setResult("Area/Perim.", ni, AoP[ni]);
		ElipMaj[ni] = getResult("Major", ni);
		ElipMin[ni] = getResult("Minor", ni);
		AR[ni] = getResult("AR", ni);
		Angle[ni] = getResult("Angle", ni);
		Feret[ni] = getResult("Feret", ni);
		MinFeret[ni] = getResult("MinFeret", ni);
		FeretAR[ni] = (getResult("Feret", ni)/getResult("MinFeret", ni));
			setResult("Feret's AR", ni, FeretAR[ni]);
		FeretAngle[ni] = getResult("FeretAngle", ni);
		Circ[ni] = getResult("Circ.", ni);
		Solidity[ni] = getResult("Solidity", ni);
		Compactness[ni] = (sqrt((4/PI)*getResult("Area", ni))/getResult("Major", ni));
			setResult("Compactness", ni, Compactness[ni]);
		Extent[ni] = (getResult("Area", ni)/((getResult("Width", ni))*(getResult("Height", ni))));
			setResult("Extent", ni, Extent[ni]);
				saveAs("Results", path2+".csv");

				
		if(ni>0) {
			if(Area[ni]>biggestArea) { biggestArea = Area[ni]; }
			if(Peri[ni]>biggestPeri) { biggestPeri = Peri[ni]; }
			if(AoP[ni]>biggestAoP) { biggestAoP = AoP[ni]; }
			if(ElipMaj[ni]>biggestElipMaj) { biggestElipMaj = ElipMaj[ni]; }
			if(ElipMin[ni]>biggestElipMin) { biggestElipMin = ElipMin[ni]; }
			if(AR[ni]>biggestAR) { biggestAR = AR[ni]; }
			if(Angle[ni]>biggestAngle) { biggestAngle = Angle[ni]; }
			if(Feret[ni]>biggestFeret) { biggestFeret = Feret[ni]; }
			if(MinFeret[ni]>biggestMinFeret) { biggestMinFeret = MinFeret[ni]; }
			if(FeretAR[ni]>biggestFeretAR) { biggestFeretAR = FeretAR[ni]; }
			if(FeretAngle[ni]>biggestFeretAngle) { biggestFeretAngle = FeretAngle[ni]; }
			if(Circ[ni]>biggestCirc) { biggestCirc = Circ[ni]; }
			if(Solidity[ni]>biggestSolidity) { biggestSolidity = Solidity[ni]; }
			if(Compactness[ni]>biggestCompactness) { biggestCompactness = Compactness[ni]; }
			if(Extent[ni]>biggestExtent) { biggestExtent = Extent[ni]; }
			
		}
		
		
		if(ni>0) {
			if(Area[ni]<smallestArea) { smallestArea = Area[ni]; }
			if(Peri[ni]<smallestPeri) { smallestPeri = Peri[ni]; }
			if(AoP[ni]<smallestAoP) { smallestAoP = AoP[ni]; }
			if(ElipMaj[ni]<smallestElipMaj) { smallestElipMaj = ElipMaj[ni]; }
			if(ElipMin[ni]<smallestElipMin) { smallestElipMin = ElipMin[ni]; }
			if(AR[ni]<smallestAR) { smallestAR = AR[ni]; }
			if(Angle[ni]<smallestAngle) { smallestAngle = Angle[ni]; }
			if(Feret[ni]<smallestFeret) { smallestFeret = Feret[ni]; }
			if(MinFeret[ni]<smallestMinFeret) { smallestMinFeret = MinFeret[ni]; }
			if(FeretAR[ni]<smallestFeretAR) { smallestFeretAR = FeretAR[ni]; }
			if(FeretAngle[ni]<smallestFeretAngle) { smallestFeretAngle = FeretAngle[ni]; }
			if(Circ[ni]<smallestCirc) { smallestCirc = Circ[ni]; }
			if(Solidity[ni]<smallestSolidity) { smallestSolidity = Solidity[ni]; }
			if(Compactness[ni]<smallestCompactness) { smallestCompactness = Compactness[ni]; }
			if(Extent[ni]<smallestExtent) { smallestExtent = Extent[ni]; }
			
		}
		
	
	
	}
	
		biggest_Name = newArray("Area", "Perimeter", "Area/Perimeter","Ellipse Major Axis","Ellipse Minor Axis","Ellipse Aspect Ratio", "Ellipse Major Axis Angle","Max. Feret Diameter","Min. Feret Diameter","Feret Aspect Ratio",  "Max Feret Diam. Angle", "Circularity", "biggestSolidity", "Compactness", "Extent");
		biggestValue = newArray(biggestArea,biggestPeri, biggestAoP, biggestElipMaj,biggestElipMin,biggestAR,biggestAngle,biggestFeret,biggestMinFeret,biggestFeretAR,biggestFeretAngle,biggestCirc,biggestSolidity,biggestCompactness,biggestExtent);
		smallestValue = newArray(smallestArea,smallestPeri, smallestAoP, smallestElipMaj,smallestElipMin,smallestAR,smallestAngle,smallestFeret,smallestMinFeret,smallestFeretAR,smallestFeretAngle,smallestCirc,smallestSolidity,smallestCompactness,smallestExtent);

	midValue = newArray(biggestValue.length);
	for(ie=0; ie<biggestValue.length; ie++){
		midValue[ie] = biggestValue[ie]/2;
		biggestValue[ie] = d2s(biggestValue[ie],2);
		midValue[ie] = d2s(midValue[ie],2);
	}

//	biggest_Array = Array.show("Biggest Metrics",biggest_Name,biggestValue);
	

	
//*******************************************************************
	
if(graphic_choice == "All" || graphic_choice == "All But Neighbors") {
	setPasteMode("Copy");
	selectWindow(result);
	setBatchMode("hide");
		for(nS = 1; nS<17; nS++) {
			run("Add Slice"); 
		}
		run("Select None");
		
//run voronoi on particles
	selectWindow(input);
		run("Invert");
		run("Voronoi");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
			run("Convert to Mask");
	
		run("Misc...", "divide=Infinity hide run");

	//color code shape descriptor maps
	shapeDescriptors=newArray("Area", "Perim.", "AoP", "Major", "Minor", "AR", "Angle", "Feret", "MinFeret", "FeretAR", "FeretAngle", "Circ.", "AR", "Solidity", "Compactness", "Extent");
	mapNames = newArray("Counted Cells", "Neighbors","Area", "Perimeter", "Area/Perimeter","Ellipse Major Axis", "Ellipse Minor Axis", "Ellipse Aspect Ratio", "Ellipse Angle", "Feret Major", "Feret Minor", "Feret Aspect Ratio", "Feret Angle", "Circularity", "Solidity", "Compactness", "Extent");

	for(m=0; m<15; m++) {
		selectWindow(input);
		run("Duplicate...", "title=["+mapNames[m]+"]");
		map=getTitle();
		selectWindow(map);
		for(yi=0; yi<allParticles; yi++) {
			doWand(X[yi],Y[yi]);
			if(shapeDescriptors[m]=="Area") {
				value=round(255/biggestArea*Area[yi]);
			}
			if(shapeDescriptors[m]=="Perim.") {
				value=round(255/biggestPeri*Peri[yi]);
			}
			if(shapeDescriptors[m]=="AoP") {
				value=round(255/biggestAoP*AoP[yi]);
			}
			if(shapeDescriptors[m]=="Major") {
				value=round(255/biggestElipMaj*ElipMaj[yi]);
			}
			if(shapeDescriptors[m]=="Minor") {
				value=round(255/biggestElipMin*ElipMin[yi]);
			}				
			if(shapeDescriptors[m]=="AR") {
				value=round(255/biggestAR*AR[yi]);
			}		
			if(shapeDescriptors[m]=="Angle") {
				value=round(255/biggestAngle*Angle[yi]);
			}			
			if(shapeDescriptors[m]=="Feret") {
				value=round(255/biggestFeret*Feret[yi]);
			}
			if(shapeDescriptors[m]=="MinFeret") {
				value=round(255/biggestMinFeret*MinFeret[yi]);
			}
			if(shapeDescriptors[m]=="FeretAR") {
				value=round(255/biggestFeretAR*FeretAR[yi]);
			}			
			if(shapeDescriptors[m]=="FeretAngle") {
				value=round(255/biggestFeretAngle*FeretAngle[yi]);
			}
			if(shapeDescriptors[m]=="Circ.") {
				value=round(255/biggestCirc*Circ[yi]);
			}
			if(shapeDescriptors[m]=="Solidity") {
				value=round(255/biggestSolidity*Solidity[yi]);
			}
			if(shapeDescriptors[m]=="Compactness") {
				value=round(255/biggestCompactness*Compactness[yi]);
			}
			if(shapeDescriptors[m]=="Extent") {
				value=round(255/biggestExtent*Extent[yi]);
			}
			setForegroundColor(value, value, value);
			run("Fill");
			setBatchMode("hide");
		}
		showProgress(((m+1)*yi)/(allParticles*10));
			run("Select All");
				run("Copy");
			selectWindow(result);
				setSlice(m+3);
					run("Paste");
			run("Select None");
		close(map);
	}
	
	
	selectWindow(result);
		currentID = getImageID();
		setSlice(1);
			run("Select All");
			run("Invert");
			run("Copy");
	setPasteMode("Transparent-white");
	selectWindow(result);
		for(mask=1; mask<=17; mask++) {
			setSlice(mask);
				run("Paste");
					if(mask>=0) {
						setMetadata("Label", mapNames[mask-1]);
					}
		}
		close(input);
	
		setSlice(1);
		run("Select None");	
			run(LUT);
			run("Select None");	
				run("RGB Color");
			
//Create a calibration bar and paste it onto each image after labeling
		for(mask=3; mask<=17; mask++) {
			setSlice(mask);		
				wid=getWidth();
				hig=getHeight();
				vscale= 30;
				wscale= 5;
				totalw= floor(wid/wscale);
				totalh= floor(hig/vscale);
				totalht= totalh*1.5;

			newImage("Calibration Bar", "8-bit Ramp", totalw, totalh, 1);
				
					step=0;
				run("Select None");
				run(LUT);
					run("RGB Color");
						setForegroundColor(255, 255, 255);
						setBackgroundColor(0, 0, 0);
			run("Canvas Size...", "width=totalw height=totalht position=Top-Center");
				setJustification("left");
				setFont("SansSerif", 0.7573*totalh*0.5-0.1783, "Bold");

			drawString(0, 2, totalht-1);
				setJustification("center");
			drawString(midValue[mask-3], totalw/2, totalht-1);
				setJustification("right");
			drawString(biggestValue[mask-3], totalw, totalht-1);
			run("Select All");
				w3 = getWidth();
				h3 = getHeight();
				run("Copy");
					setPasteMode("Copy");
				selectWindow(result);
			makeRectangle(0, 0, w3, h3); 
			run("Paste");
					}			

// Creates an image of all cell outlines that is numbered
		open(path3+".tif");
		run("Invert");

		run("Set Measurements...", "  redirect=None decimal=3");
				call("ij.plugin.filter.ParticleAnalyzer.setFontSize", 24); 
			run("Analyze Particles...", "size="+size+" pixelf show=Outlines exclude clear");
			
				run("Select All");
				run("Copy");
				setPasteMode("Copy");
			selectWindow(result);	
				setSlice(1);
				run("Paste");

		if(graphic_choice == "All" || graphic_choice == "Just Neighbors") {			
			open(path4+".tif");
				run("Select All");
				run("Copy");
				setPasteMode("Copy");
			selectWindow(result);	
				setSlice(2);
				run("Paste");
			}	
				run("Select None");
					saveAs("Tiff",path7);
						run("Clear Results");
					File.delete(path4+".tif");
					File.delete(path1+".tif");
			run("Close All");

	}
print("\\Clear");


	}
	}
	
	
	

//********************************************************************************************************************************************************************************************************************************	

// Analysis for combining Cell Morphological Features
		list2 = getFileList(myDir1);
		
		
			setBatchMode(true);
		for (ij=0; ij<list2.length; ij++) {
			showProgress(ij+1, list2.length);
			filedir1 = myDir1 + list2[ij];
			filename1 = list2[ij];
			

// Creates a log with only files that end with the extension of interest
			if (endsWith(filedir1, "_Data.csv")) {
				print(filename1);
				}
				}
				selectWindow("Log");
					saveAs("Text", myDir1+"pore_files.txt");
				print("\\Clear");

//Opens file that contains the names of the files of interest
		filestring1=File.openAsString(myDir1+"pore_files.txt"); 
			radrows=split(filestring1, "\n"); 
				l2 = radrows.length;
			
			if(radrows.length > 1) { 
//Creates a list of each of the files of interest
			for(ij=0; ij < l2; ij++) {
				filename2 = radrows[ij];
				filedir2 = myDir1 + filename2;
			

//Opens files of interest and parses them into new variable values	
			open(filedir2);
				n = nResults;
				poreval = newArray(n);
				poreX = newArray(n);
				poreY = newArray(n);
				poreperim = newArray(n);
				porewidth = newArray(n);
				poreheight = newArray(n);
				poremaj = newArray(n);
				poremin = newArray(n);
				poreAR = newArray(n);
				poreangle = newArray(n);
				porecirc = newArray(n);
				poreferet = newArray(n);
				poreferetx = newArray(n);
				poreferety = newArray(n);
				poreferetA = newArray(n);
				poreminfer = newArray(n);
				poresolid = newArray(n);
				porecompact = newArray(n);
				poreextent = newArray(n);
				porenamenew = newArray(n);
				for (ik=0; ik<n; ik++) {
					poreval[ik] = getResult("Area", ik);
					poreX[ik] = getResult("X", ik);
					poreY[ik] = getResult("Y", ik);
					poreperim[ik] = getResult("Perim.", ik);
					porewidth[ik] = getResult("Width", ik);
					poreheight[ik] = getResult("Height", ik);
					poremaj[ik] = getResult("Major", ik);
					poremin[ik] = getResult("Minor", ik);
					poreAR[ik] = getResult("AR", ik);
					poreangle[ik] = getResult("Angle", ik);
					porecirc[ik] = getResult("Circ.", ik);
					poreferet[ik] = getResult("Feret", ik);
					poreferetx[ik] = getResult("FeretX", ik);
					poreferety[ik] = getResult("FeretY", ik);
					poreferetA[ik] = getResult("FeretAngle", ik);
					poreminfer[ik] = getResult("MinFeret", ik);
					poresolid[ik] = getResult("Solidity", ik);
					porecompact[ik] = getResult("Compactness", ik);
					poreextent[ik] = getResult("Extent", ik);
					porenamenew[ik] = filename2; 
				}
				run("Clear Results");

// Sets up initial results storage file for each set of values of interest			
		if(ij==0){
			for (il=0; il<n; il++) {
				setResult("Cell Area", il, poreval[il]);
				setResult("Cell Perimeter", il, poreperim[il]);
				setResult("Area/Perimeter", il, poreval[il]/poreperim[il]);
				setResult("Major Cell Axis", il, poremaj[il]);
				setResult("Minor Cell Axis", il, poremin[il]);
				setResult("Aspect Ratio", il, poreAR[il]);
				setResult("Angle of Major Axis", il, poreangle[il]);
				setResult("Ferets Max Diameter", il, poreferet[il]);
				setResult("Ferets Min Diameter", il, poreminfer[il]);
				setResult("Ferets Aspect Ratio", il, poreferet[il]/poreminfer[il]);
				setResult("Angle of F.Max Diam.", il, poreferetA[il]);
				setResult("Cell Bounding Box Width", il, porewidth[il]);
				setResult("Cell Bounding Box Height", il, poreheight[il]);
				setResult("Cell Centroid X Coord. (Pixel)", il, poreX[il]);
				setResult("Cell Centroid Y Coord. (Pixel)", il, poreY[il]);
				setResult("Cell Circularity", il, porecirc[il]);
				setResult("Cell Solidity", il, poresolid[il]);
				setResult("Cell Compactness", il, porecompact[il]);
				setResult("Cell Extent", il, poreextent[il]);			
				setResult("File Name", il, porenamenew[il]);
			} 
		
			selectWindow("Results");
			IJ.renameResults("temp.csv");
				saveAs("Results", myDir1+"temp.csv");
			run("Close");
				print("\\Clear");
		}

// Adds current values of interest to saved storage file		
		if(ij>0 && ij < l2-1){
			selectWindow("Results");
				run("Close");
	
		open(myDir1 + "temp.csv");
			old_len = nResults;
			old_porearea = newArray(old_len);
			old_poreperim = newArray(old_len);
			old_poremaj = newArray(old_len);
			old_poremin = newArray(old_len);
			old_poreAR = newArray(old_len);
			old_poreangle = newArray(old_len);
			old_poreferet = newArray(old_len);
			old_poreminfer = newArray(old_len);
			old_poreferetA = newArray(old_len);
			old_porewidth = newArray(old_len);
			old_poreheight = newArray(old_len);
			old_poreX = newArray(old_len);
			old_poreY = newArray(old_len);
			old_porecirc = newArray(old_len);
			old_poresolid = newArray(old_len);
			old_porecomp = newArray(old_len);
			old_poreextent = newArray(old_len);
			oldporename = newArray(old_len);

			for (im=0; im<old_len; im++) {
				old_porearea[im] = getResult("Cell Area", im);
				old_poreperim[im] = getResult("Cell Perimeter", im);
				old_poremaj[im] = getResult("Major Cell Axis", im);
				old_poremin[im] = getResult("Minor Cell Axis", im);
				old_poreAR[im] = getResult("Aspect Ratio", im);
				old_poreangle[im] = getResult("Angle of Major Axis", im);
				old_poreferet[im] = getResult("Ferets Max Diameter", im);
				old_poreminfer[im] = getResult("Ferets Min Diameter", im);
				old_poreferetA[im] = getResult("Angle of F.Max Diam.", im);
				old_porewidth[im] = getResult("Cell Bounding Box Width", im);
				old_poreheight[im] = getResult("Cell Bounding Box Height", im);
				old_poreX[im] = getResult("Cell Centroid X Coord. (Pixel)", im);
				old_poreY[im] = getResult("Cell Centroid Y Coord. (Pixel)", im);
				old_porecirc[im] = getResult("Cell Circularity", im);
				old_poresolid[im] = getResult("Cell Solidity", im);
				old_porecomp[im] = getResult("Cell Compactness", im);
				old_poreextent[im] = getResult("Cell Extent", im);				
				oldporename[im] = getResultString("File Name", im);			
			}
			
//Concatenates old data and new data together
		newpore_area = Array.concat(old_porearea, poreval);
		newpore_perim = Array.concat(old_poreperim, poreperim);
		newpore_maj = Array.concat(old_poremaj, poremaj);
		newpore_min = Array.concat(old_poremin, poremin);
		newpore_AR = Array.concat(old_poreAR, poreAR);
		newpore_angle = Array.concat(old_poreangle, poreangle);
		newpore_feret = Array.concat(old_poreferet, poreferet);
		newpore_minfer = Array.concat(old_poreminfer, poreminfer);
		newpore_feretA = Array.concat(old_poreferetA, poreferetA);
		newpore_width = Array.concat(old_porewidth, porewidth);
		newpore_height = Array.concat(old_poreheight, poreheight);
		newpore_X = Array.concat(old_poreX, poreX);
		newpore_Y = Array.concat(old_poreY, poreY);
		newpore_circ = Array.concat(old_porecirc, porecirc);
		newpore_solid = Array.concat(old_poresolid, poresolid);
		newpore_comp = Array.concat(old_porecomp, porecompact);
		newpore_extent = Array.concat(old_poreextent, poreextent);
		newporename = Array.concat(oldporename, porenamenew);

			n= newpore_area.length;
			run("Clear Results");
			
			for (il=0; il<n; il++) {
				setResult("Cell Area", il, newpore_area[il]);
				setResult("Cell Perimeter", il, newpore_perim[il]);
				setResult("Major Cell Axis", il, newpore_maj[il]);
				setResult("Minor Cell Axis", il, newpore_min[il]);
				setResult("Aspect Ratio", il, newpore_AR[il]);
				setResult("Angle of Major Axis", il, newpore_angle[il]);
				setResult("Ferets Max Diameter", il, newpore_feret[il]);
				setResult("Ferets Min Diameter", il, newpore_minfer[il]);
				setResult("Angle of F.Max Diam.", il, newpore_feretA[il]);
				setResult("Cell Bounding Box Width", il, newpore_width[il]);
				setResult("Cell Bounding Box Height", il, newpore_height[il]);
				setResult("Cell Centroid X Coord. (Pixel)", il, newpore_X[il]);
				setResult("Cell Centroid Y Coord. (Pixel)", il, newpore_Y[il]);
				setResult("Cell Circularity", il, newpore_circ[il]);
				setResult("Cell Solidity", il, newpore_solid[il]);
				setResult("Cell Compactness", il, newpore_comp[il]);
				setResult("Cell Extent", il, newpore_extent[il]);				
				setResult("File Name", il, newporename[il]);
			} 
			
				selectWindow("Results");
					IJ.renameResults("temp.csv");
						saveAs("Results", myDir1+"temp.csv");
					run("Close");
				print("\\Clear");
		}

// Adds current values of interest to saved storage file		
		if(ij == l2-1){
			selectWindow("Results");
				run("Close");
		
		open(myDir1 + "temp.csv");
			old_len = nResults;
			old_porearea = newArray(old_len);
			old_poreperim = newArray(old_len);
			old_poremaj = newArray(old_len);
			old_poremin = newArray(old_len);
			old_poreAR = newArray(old_len);
			old_poreangle = newArray(old_len);
			old_poreferet = newArray(old_len);
			old_poreminfer = newArray(old_len);
			old_poreferetA = newArray(old_len);
			old_porewidth = newArray(old_len);
			old_poreheight = newArray(old_len);
			old_poreX = newArray(old_len);
			old_poreY = newArray(old_len);
			old_porecirc = newArray(old_len);
			old_poresolid = newArray(old_len);
			old_porecomp = newArray(old_len);
			old_poreextent = newArray(old_len);			
			oldporename = newArray(old_len);

			for (im=0; im<old_len; im++) {
				old_porearea[im] = getResult("Cell Area", im);
				old_poreperim[im] = getResult("Cell Perimeter", im);
				old_poremaj[im] = getResult("Major Cell Axis", im);
				old_poremin[im] = getResult("Minor Cell Axis", im);
				old_poreAR[im] = getResult("Aspect Ratio", im);
				old_poreangle[im] = getResult("Angle of Major Axis", im);
				old_poreferet[im] = getResult("Ferets Max Diameter", im);
				old_poreminfer[im] = getResult("Ferets Min Diameter", im);
				old_poreferetA[im] = getResult("Angle of F.Max Diam.", im);
				old_porewidth[im] = getResult("Cell Bounding Box Width", im);
				old_poreheight[im] = getResult("Cell Bounding Box Height", im);
				old_poreX[im] = getResult("Cell Centroid X Coord. (Pixel)", im);
				old_poreY[im] = getResult("Cell Centroid Y Coord. (Pixel)", im);
				old_porecirc[im] = getResult("Cell Circularity", im);
				old_poresolid[im] = getResult("Cell Solidity", im);
				old_porecomp[im] = getResult("Cell Compactness", im);
				old_poreextent[im] = getResult("Cell Extent", im);					
				oldporename[im] = getResultString("File Name", im);	
			}
			
		newpore_area = Array.concat(old_porearea, poreval);
		newpore_perim = Array.concat(old_poreperim, poreperim);
		newpore_maj = Array.concat(old_poremaj, poremaj);
		newpore_min = Array.concat(old_poremin, poremin);
		newpore_AR = Array.concat(old_poreAR, poreAR);
		newpore_angle = Array.concat(old_poreangle, poreangle);
		newpore_feret = Array.concat(old_poreferet, poreferet);
		newpore_minfer = Array.concat(old_poreminfer, poreminfer);
		newpore_feretA = Array.concat(old_poreferetA, poreferetA);
		newpore_width = Array.concat(old_porewidth, porewidth);
		newpore_height = Array.concat(old_poreheight, poreheight);
		newpore_X = Array.concat(old_poreX, poreX);
		newpore_Y = Array.concat(old_poreY, poreY);
		newpore_circ = Array.concat(old_porecirc, porecirc);
		newpore_solid = Array.concat(old_poresolid, poresolid);
		newpore_comp = Array.concat(old_porecomp, porecompact);
		newpore_extent = Array.concat(old_poreextent, poreextent);		
		newporename = Array.concat(oldporename, porenamenew);
			
			n= newpore_area.length;
			run("Clear Results");
			
			
			for (il=0; il<n; il++) {
				setResult("Cell_Area", il, newpore_area[il]);
				setResult("Cell_Perimeter", il, newpore_perim[il]);
				setResult("Area_Perimeter", il, newpore_area[il]/newpore_perim[il]);
				setResult("Major_Cell_Axis", il, newpore_maj[il]);
				setResult("Minor_Cell_Axis", il, newpore_min[il]);
				setResult("Aspect_Ratio", il, newpore_AR[il]);
				setResult("Angle_of_Major_Axis", il, newpore_angle[il]);
				setResult("Ferets_Max_Diameter", il, newpore_feret[il]);
				setResult("Ferets_Min_Diameter", il, newpore_minfer[il]);
				setResult("Ferets_Aspect_Ratio", il, newpore_feret[il]/newpore_minfer[il]);
				setResult("Angle_of_Fer_Max_Diam", il, newpore_feretA[il]);
				setResult("Cell_Box_Width", il, newpore_width[il]);
				setResult("Cell_Box_Height", il, newpore_height[il]);
				setResult("Cell_Centroid_XCoord", il, newpore_X[il]);
				setResult("Cell_Centroid_YCoord", il, newpore_Y[il]);
				setResult("Cell_Circularity", il, newpore_circ[il]);
				setResult("Cell_Solidity", il, newpore_solid[il]);
				setResult("Cell_Compactness", il, newpore_comp[il]);
				setResult("Cell_Extent", il, newpore_extent[il]);					
				setResult("File_Name", il, newporename[il]);
			} 
				
				selectWindow("Results");
				run("Summarize");
					IJ.renameResults("All Pore Area Values.csv");
						saveAs("Results", myDir2+"All Cell Metric Values.csv");
				run("Close");
				File.delete(myDir1+"temp.csv");
				File.delete(myDir1+"pore_files.txt");
				print("\\Clear");
			}
			
		}
		
	}	
			
//**********************************************************************************************************************************************************************************************
// Analysis for combining Neighbor Counts
		list3 = getFileList(myDir1);
		
		if(list3.length > 1) { 
			setBatchMode(true);
		
		for (ij=0; ij<list3.length; ij++) {
			showProgress(ij+1, list3.length);
			filedir4 = myDir1 + list3[ij];
			filename5 = list3[ij];
			

// Creates a log with only files that end with the extension of interest
			if (endsWith(filedir4, "_Neighbors.csv")) {
				print(filename5);
				}
				}
				selectWindow("Log");
					saveAs("Text", myDir1+"Neighbor_files.txt");
				print("\\Clear");


//Combination of Neighbor Files
//Opens file that contains the names of the files of interest
		filestring1=File.openAsString(myDir1+"Neighbor_files.txt"); 
			neighbor_rows=split(filestring1, "\n"); 
				l2 = neighbor_rows.length;
				namenew = newArray(l2);
			for(i=0; i<l2; i++) {
				namen = neighbor_rows[i];
				namenew[i] = replace(namen,"_Neighbors.csv","");
				namenew[i] = namenew[i]+".tif";
			}

	if(neighbor_rows.length > 1) { 
//Creates a list of each of the files of interest
			for(ij=0; ij < l2; ij++) {
				filename4 = neighbor_rows[ij];
				filedir3 = myDir1 + filename4;

//Opens files of interest and parses them into new variable values	
			open(filedir3);
			
				n = nResults;
				neighbor_val = newArray(n);
				neighbor_count = newArray(n);
					name99 = replace(filename4,"_Neighbors.csv","");
					name99 = name99+".tif";
				
				for (ik=0; ik<n; ik++) {
					neighbor_val[ik] = getResult("Neighbors", ik);
					neighbor_count[ik] = getResult(name99, ik);
				}
				
				run("Clear Results");
				
		if(ij==0){
			for (il=0; il<n; il++) {
				setResult("Neighbors", il, neighbor_val[il]);
				setResult(name99, il, neighbor_count[il]);
			} 
		
			selectWindow("Results");
			IJ.renameResults("temp.csv");
				saveAs("Results", myDir1+"temp.csv");
			run("Close");
				print("\\Clear");
			}
			
// Adds current values of interest to saved storage file		
		if(ij>0 && ij < l2-1){
			selectWindow("Results");
				run("Close");

		open(myDir1 + "temp.csv");
			
			for (im=0; im<n; im++) {
				setResult(name99, im, neighbor_count[im]);
			}
				selectWindow("Results");
					IJ.renameResults("temp.csv");
						saveAs("Results", myDir1+"temp.csv");
				run("Close");
		}
		
// Adds current values of interest to saved storage file		
		if(ij == l2-1){
			selectWindow("Results");
				run("Close");
			open(myDir1 + "temp.csv");	
				
			for (im=0; im<n; im++) {
				setResult(name99, im, neighbor_count[im]);
			}
				selectWindow("Results");
					IJ.renameResults("All Neighbor Values.csv");
						saveAs("Results", myDir2+"All_Neighbor_Values.csv");
				run("Close");
				File.delete(myDir1+"temp.csv");
				File.delete(myDir1+"Neighbor_files.txt");
				print("\\Clear");
			}

		}
		
		open(myDir2 + "All_Neighbor_Values.csv");
			final_n = nResults;
			
			for (j=0; j<final_n; j++) {
				c = 0; 
					for(i=0; i<l2; i++){
						d=c;
						c = getResult(namenew[i],j);
						c = d + c;
					} 
					setResult("Sum of Frequencies", j, c);
					setResult("Neighbors",j,j);
					}

				saveAs("Results", myDir2+"All_Neighbor_Values.csv");
					selectWindow("Results");
					run("Close");
				run("Close All");
		print("\\Clear");
	}	
	}
		if(neighbor_rows.length < 2 ) { 
			File.delete(myDir1+"Neighbor_files.txt");
			File.delete(myDir1+"pore_files.txt");
			if(list.length > 1) {
			File.delete(myDir2);
			}
			print("\\Clear");
			run("Close All");
			}
		
	T2 = getTime();
		TTime = (T2-T1)/1000;

print("All Images Analyzed Successfully in:",TTime," Seconds");
exit();



