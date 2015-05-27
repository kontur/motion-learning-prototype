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
	.setPosition(guiCenter + 10, guiHeader)
	.setSize(100, 20);

	buttonCloseBluetooth = cp5.addButton("closeBluetooth")
	.setPosition(guiCenter + 10, guiHeader)
	.setSize(100, 20)
	.hide();

	bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
	.setPosition(guiCenter + 120, guiHeader + 20)
	.setSize(150, 200);

	getBluetoothDeviceList(bluetoothDeviceList);        


	// manual rotation for cube visualisation
	cp5.addSlider("rotationX")
	.setPosition(guiRight + 150, guiHeader)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(255, 0, 0));

	cp5.addSlider("rotationY")
	.setPosition(guiRight + 150, guiHeader + 20)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 255, 0));

	cp5.addSlider("rotationZ")
	.setPosition(guiRight + 150, guiHeader + 40)
	.setRange(rotationMin, rotationMax)
	.setColorCaptionLabel(color(0, 0, 255));


	// file I/O check textarea
	debugText = cp5.addTextarea("txt")
	.setPosition(guiLeft, guiBottom)
	.setSize((winW), (winH - guiBottom))
	.setFont(createFont("arial", 10))
	.setColor(0);
	//.setColorBackground(color(255, 100));


	// buttons for recording from the GUI instead of the device
	cp5.addButton("recordPattern")
	.setPosition(guiLeft, guiTop)
	.setSize(100, 20);

	cp5.addButton("clearPattern")
	.setPosition(guiLeft + 110, guiTop)
	.setSize(100, 20);


	cp5.addButton("recordMatch")
	.setPosition(guiLeft, guiMiddle)
	.setSize(100, 20);

	cp5.addButton("clearMatch")
	.setPosition(guiLeft + 110, guiMiddle)
	.setSize(100, 20);


	cp5.addButton("playback")
	.setPosition(guiLeft, guiHeader)
	.setSize(100, 20);



	cp5.addButton("pos")
	.setPosition(winW - 50, winH - 100)
	.setSize(40, 20);
	cp5.addButton("neu")
	.setPosition(winW - 50, winH - 70)
	.setSize(40, 20);
	cp5.addButton("neg")
	.setPosition(winW - 50, winH - 40)
	.setSize(40, 20);

}