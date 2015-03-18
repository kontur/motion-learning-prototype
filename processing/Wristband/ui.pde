
void setupUI() {

	int x = 10;
	int yTop = 10;

	cp5 = new ControlP5(this);

	// bluetooth connect UI
	cp5.addButton("connectBluetooth")
	.setPosition(x, 20)
	.setSize(100, 20);

	cp5.addButton("closeBluetooth")
	.setPosition(x, 50)
	.setSize(30, 20);

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

}