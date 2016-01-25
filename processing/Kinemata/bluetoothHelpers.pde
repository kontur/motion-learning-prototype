
// helper to dump a list of available serial ports into the passed in DropdownList
void getBluetoothDeviceList(DropdownList list) {
    String[] ports = Serial.list();
    bluetoothDeviceList.addItem("---", 0);
    for (int p = 0; p < ports.length; p++) {
        String port = ports[p];
        bluetoothDeviceList.addItem(port, p  + 1);
    }
}


// helper function to start a bluetooth connection based on the selected dropdown list item
void connectBluetooth(int val) {
    mode = 1;
    String[] ports = Serial.list();
    buttonConnectBluetooth.hide();
    String port = defaultSerial;
    
    println(Serial.list());

    if (bluetoothDeviceList.getValue() != 0) {
        port = ports[int(bluetoothDeviceList.getValue()) - 1];
    }
    log("Attempting to open serial port: " + port); 
    
    try {
        tryingToConnect = true;
        connection = new Serial(this, port, 9600);

        // set a character that limits transactions and initiates reading the buffer
        char c = ';';
        connection.bufferUntil(byte(c));
        buttonConnectBluetooth.hide();
        buttonCloseBluetooth.show();
        mode = 2;
        sendBluetoothCommand("bluetoothConnected");
        log("Bluetooth connected to " + port);
    } 
    catch (RuntimeException e) {
        log("Error opening serial port " + port + ": \n" + e.getMessage());
        buttonConnectBluetooth.show();
        buttonCloseBluetooth.hide();
        tryingToConnect = false;
        mode = 0;
    }
}


// helper function to close the bluetooth connection
void closeBluetooth(int val) {
    mode = 0;
    try {
        sendBluetoothCommand("bluetoothDisconnected");
        connection.stop();
        connection = null;
    }
    catch (RuntimeException e) {
        println("error: " + e.getMessage());
        // TODO UI feedback
    }
    buttonConnectBluetooth.show();
    buttonCloseBluetooth.hide();
}


void sendBluetoothCommand(String command) {
    if (connection != null) {
        try {
            //connection.write("roll:" + rotationX + ",heading:" + rotationY + ",pitch:" + rotationZ + ";");
            connection.write("command:" + command + ";");
            log("Sent bluetooth command to device: " + command);
        }
        catch (RuntimeException e) {
            log("Cannot send command to Arduino; exception: " + e.getMessage());
        }
    } else {
        log("Cannot send command to Arduino; no Bluetooth connection");
    }
}
