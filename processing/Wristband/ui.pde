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

	graph = new Grapher(200, 500, 400, 100);


	// file I/O check textarea
	debugText = cp5.addTextarea("txt")
	.setPosition((winW - 200), 0)
	.setSize((winW - 200), winH)
	.setFont(createFont("arial", 10))
	.setColor(0)
	.setColorBackground(color(255, 100))
	.setColorBackground(color(255, 100));



	// helper for testing atm

	cp5.addButton("recordPattern")
	.setPosition(500, 300)
	.setSize(100, 20);

	cp5.addButton("recordMatch")
	.setPosition(500, 330)
	.setSize(100, 20);

}