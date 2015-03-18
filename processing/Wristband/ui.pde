/**
 * helper file for UI related stuff
 */


/**
 * setup the UI components
 */
void setupUI() {

	int x = 10;
	int yTop = 10;

	cp5 = new ControlP5(this);

	// bluetooth connect UI
	buttonConnectBluetooth = cp5.addButton("connectBluetooth")
	.setPosition(x, 20)
	.setSize(100, 20);

	buttonCloseBluetooth = cp5.addButton("closeBluetooth")
	.setPosition(x, 20)
	.setSize(100, 20)
	.hide();

	bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
	.setPosition(170, 30)
	.setSize(150, 200);

	getBluetoothDeviceList(bluetoothDeviceList);        


	mode = cp5.addRadioButton("modeRadioButton")
	.setPosition(x, 250)
	.setSize(10, 10)
	.setColorForeground(color(120))
	.setColorActive(color(255))
	.setColorLabel(color(0))
	.setItemsPerRow(3)
	.setSpacingColumn(30)
	.addItem("loop", 0)
	.addItem("live", 1)
	.addItem("file", 2)
	;
	mode.activate(0);
	modeSelected = 0;


	// manual rotation for cube visualisation
	cp5.addSlider("rotationX")
	.setPosition(x, 470)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(255, 0, 0));

	cp5.addSlider("rotationY")
	.setPosition(x, 490)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 255, 0));

	cp5.addSlider("rotationZ")
	.setPosition(x, 510)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 0, 255));

	graph = new Grapher(250, 450, 300, 100);


	// file handling buttons
	cp5.addButton("loadFile")
	.setPosition(x, 300)
	.setSize(100, 20);

	cp5.addButton("recordFile")
	.setPosition(x, 330)
	.setSize(100, 20);

	cp5.addButton("saveFile")
	.setPosition(x, 360)
	.setSize(100, 20);


	// file I/O check textarea
	debugText = cp5.addTextarea("txt")
	.setPosition((winW - 200), 0)
	.setSize((winW - 200), winH)
	.setFont(createFont("arial", 10))
	.setColor(0)
	.setColorBackground(color(255, 100))
	.setColorBackground(color(255, 100));

	cp5.addButton("similarity")
	.setPosition(500, 20);

}

void similarity(int val) {

    Similarity s = new Similarity();
    double [][] testscores = { 
        {36, 62, 31, 76, 46, 12, 39, 30, 22, 9, 32, 40, 64, 
          36, 24, 50, 42, 2, 56, 59, 28, 19, 36, 54, 14}, 
        {58, 54, 42, 78, 56, 42, 46, 51, 32, 40, 49, 62, 75, 
         38, 46, 50, 42, 35, 53, 72, 50, 46, 56, 57, 35}, 
        {43, 50, 41, 69, 52, 38, 51, 54, 43, 47, 54, 51, 70, 
         58, 44, 54, 52, 32, 42, 70, 50, 49, 56, 59, 38}, 
        {36, 46, 40, 66, 56, 38, 54, 52, 28, 30, 37, 40, 66, 
         62, 55, 52, 38, 22, 40, 66, 42, 40, 54, 62, 29}, 
        {37, 52, 29, 81, 40, 28, 41, 32, 22, 24, 52, 49, 63, 
         62, 49, 51, 50, 16, 32, 62, 63, 30, 52, 58, 20}}; 
    double [][] testscores2 = { 
        {36, 62, 31, 76, 46, 12, 39, 30, 22, 9, 32, 40, 64, 
          36, 24, 50, 42, 2, 56, 59, 28, 19, 36, 54, 14}, 
        {43, 50, 41, 69, 52, 38, 51, 54, 43, 47, 54, 51, 70, 
         58, 44, 54, 52, 32, 42, 70, 50, 49, 56, 59, 38}, 
        {36, 46, 40, 66, 56, 38, 54, 52, 28, 30, 37, 40, 66, 
         62, 55, 52, 38, 22, 40, 66, 42, 40, 54, 62, 29},
        {97, 52, 29, 81, 40, 28, 41, 92, 22, 24, 52, 49, 69, 
         62, 49, 51, 50, 16, 32, 62, 63, 30, 52, 58, 20}, 
        {58, 54, 42, 78, 56, 42, 46, 51, 32, 40, 49, 62, 75, 
         38, 46, 50, 42, 35, 53, 72, 50, 46, 56, 57, 35}}; 
    println(s.compare(testscores, testscores2));
}