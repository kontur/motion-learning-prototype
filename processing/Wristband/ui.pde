/**
 * helper file for UI related stuff
 */


/**
 * setup the UI components
 */
void setupUI() {

	cp5 = new ControlP5(this);



	// bluetooth connect UI
	buttonConnectBluetooth = cp5.addButton("connectBluetooth")
	.setPosition(guiLeft, 20)
	.setSize(100, 20);

	buttonCloseBluetooth = cp5.addButton("closeBluetooth")
	.setPosition(guiLeft, 20)
	.setSize(100, 20)
	.hide();

	bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
	.setPosition(170, 30)
	.setSize(150, 200);

	getBluetoothDeviceList(bluetoothDeviceList);        


	// manual rotation for cube visualisation
	cp5.addSlider("rotationX")
	.setPosition(guiLeft, 470)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(255, 0, 0));

	cp5.addSlider("rotationY")
	.setPosition(guiLeft, 490)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 255, 0));

	cp5.addSlider("rotationZ")
	.setPosition(guiLeft, 510)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 0, 255));

	graph = new Grapher(guiLeft, guiTop + 150, 400, 100);


	// file I/O check textarea
	debugText = cp5.addTextarea("txt")
	.setPosition(guiLeft, guiBottom)
	.setSize((winW - 60), (winH - guiBottom))
	.setFont(createFont("arial", 10))
	.setColor(0);
	//.setColorBackground(color(255, 100));



	// helper for testing atm

	cp5.addButton("recordPattern")
	.setPosition(guiLeft, guiTop)
	.setSize(100, 20);

	cp5.addButton("recordMatch")
	.setPosition(guiLeft, guiCenter)
	.setSize(100, 20);

}