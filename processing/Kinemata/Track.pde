/**
 * Class wrapper for a single track with recording, graphing and visualization capabilities
 
 Track GUI has:
 - BT connection buttons
 - 3D mock animation
 - UI for showing and toggling read values
 - graph
 - record, filename and save & reset buttons
 
 Track can:
 - handle BT connection
 - save and reset recordings
 - save files
 
 */

import controlP5.*;
import processing.serial.*;

class Track {

  PApplet parent;

  ColorCube cube;
  Grapher graph;
  JSONObject graphConfig;  
  Recording recording;

  int x;
  int y;

  boolean isRecording = false;
  boolean hasRecording = false;

  String label = "";


  /* UI */
  //positioning
  int guiX1 = 10; // + 200 + 10
  int guiX2 = 220; // + 200 + 10
  int guiX3 = 430; // + 200 + 10
  int guiX4 = 640; // + 400 + 10
  int guiX5 = 1050;
  int guiW = 200;
  int guiH = 200;

  //controls
  ControlP5 cp5;
  DropdownList bluetoothDeviceList;
  Button buttonConnectBluetooth;
  Button buttonCloseBluetooth;
  Button buttonRefreshBluetooth;
  Button buttonClear;
  Button buttonRecord;
  Button buttonStopRecord;
  Button buttonSave;
  Textfield inputFilename;
  CheckBox checkboxGraph;

  int buttonInactive = color(200);

  /* Bluetooth connection */
  char[] inBuffer = new char[12];
  int inBufferIndex = 0;
  boolean isConnected = false;
  boolean tryingToConnect = false;
  int baudRate = 9600;
  Serial connection;


  /*
 	 * @param int _x: Position offset on x axis
   	 * @param int _y: Position offset on y axis
   	 * @param String label: TODO Text label
   	 */
  Track(PApplet window, int _x, int _y, String _label) {
    x = _x;
    y = _y;
    label = _label;
    parent = window;

    graphConfig = JSONObject.parse("{ " + 
      "\"resolutionX\": 1.00, \"resolutionY\": 400.00, " +
      "\"roll\": { \"color\": " + color(255, 0, 0) + "}, " + 
      "\"pitch\": { \"color\": " + color(0, 0, 255) + "}, "
      + "}");

    graph = new Grapher(guiX4, 0, guiW * 2, guiH);
    graph.setConfiguration(graphConfig);

    cube = new ColorCube(100.0, 50.0, 10.0, cubeGrey, cubeGrey, cubeGrey);
    cube.setPosition(200.0, 130.0, 50.0);

    createUI(window);

    lockButton(buttonConnectBluetooth);
    lockButton(buttonSave);
    lockButton(buttonClear);
    lockButton(buttonRecord);
  }


  void createUI(PApplet window) {

    cp5 = new ControlP5(window);
    // bluetooth connect UI
    controlP5.Group uiBluetooth = cp5.addGroup("uiBluetooth")
      .hideBar()
      .setPosition(guiX1, y);

    buttonConnectBluetooth = cp5.addButton("connectBluetooth")
      .setPosition(0, 30)
      .setSize(100, 20)
      .setGroup(uiBluetooth)
      .setLabel("Connect bluetooth")
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASED) {
          String[] ports = Serial.list();
          //buttonConnectBluetooth.hide();
          String port = "";

          if (bluetoothDeviceList.getValue() != 0) {
            port = ports[int(bluetoothDeviceList.getValue()) - 1];
          }
          log("Attempting to open serial port: " + port);
          println(port);

          try {
            tryingToConnect = true;
            connection = new Serial(parent, port, 9600);

            // set a character that limits transactions and initiates reading the buffer
            char c = ';';
            connection.bufferUntil(byte(c));
            print("Bluetooth connected to " + port);
            isConnected = true;

            hideButton(buttonConnectBluetooth);
            hideButton(buttonRefreshBluetooth);
            bluetoothDeviceList.hide();

            showButton(buttonCloseBluetooth);
            lockButton(buttonSave);
            lockButton(buttonClear);
            unlockButton(buttonRecord);
          } 
          catch (RuntimeException e) {
            print("Error opening serial port " + port + ": \n" + e.getMessage());
            //buttonConnectBluetooth.show();
            //buttonCloseBluetooth.hide();
            //tryingToConnect = false;
          }
        }
      }
    }
    );

    buttonCloseBluetooth = cp5.addButton("closeBluetooth")
      .setPosition(0, 0)
      .setSize(100, 20)
      .setGroup(uiBluetooth)
      .hide()
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {

          // TODO cap bluetooth

          showButton(buttonConnectBluetooth);
          showButton(buttonRefreshBluetooth);
          bluetoothDeviceList.show();
          hideButton(buttonCloseBluetooth);
          unlockButton(buttonSave);
          unlockButton(buttonClear);
          lockButton(buttonRecord);
        }
      }
    }
    );

    bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
      .setPosition(0, 0)
      .setSize(170, 200)
      .setItemHeight(20)
      .setBarHeight(20) 
      .setLabel("Select bluetooth device")
      .setGroup(uiBluetooth)
      .close()
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        // set the connect button active only if something sensible is 
        // selected from the dropdown
        if (theEvent.getAction() == ControlP5.ACTION_BROADCAST) {
          if (bluetoothDeviceList.getValue() != 0) {
            unlockButton(buttonConnectBluetooth);
          } else {
            lockButton(buttonConnectBluetooth);
          }
        }
      }
    }
    );

    buttonRefreshBluetooth = cp5.addButton("refreshBluetooth")
      .setPosition(180, 0)
      .setSize(20, 20)
      .setGroup(uiBluetooth)
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASED) {
          getBluetoothDeviceList(bluetoothDeviceList);
        }
      }
    }
    );

    getBluetoothDeviceList(bluetoothDeviceList);


    // sliders showing the sensor values
    controlP5.Group uiSliders = cp5.addGroup("uiSliders")
      .hideBar()
      .setPosition(guiX3, y);

    checkboxGraph = cp5.addCheckBox("checkboxGraph")
      .setPosition(190, 0)
      .setSize(10, 100)
      .setItemsPerRow(1)
      .setSpacingColumn(0)
      .setSpacingRow(5)
      .setItemHeight(10) 
      .setItemWidth(10)
      .hideLabels()
      .setGroup(uiSliders);

    String[] sliders = { "pitch", "heading", "gyro X", "gyro y", "gyro z", "accel x", "accel y", "accel z" };  

    for (int i = 0; i < sliders.length; i++) {
      String item = sliders[i];      
      cp5.addSlider(item)
        .setPosition(0, i * 15)
        .setSize(150, 10)
        .setRange(rotationMin, rotationMax)
        .setGroup(uiSliders);
      checkboxGraph.addItem(item + "Checkbox", i).hideLabels();
    }



    //recording and saving buttons
    controlP5.Group uiFile = cp5.addGroup("uiFile")
      .hideBar()
      .setPosition(guiX5, y);

    buttonRecord = cp5.addButton("recordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .setGroup(uiFile);

    buttonStopRecord = cp5.addButton("stopRecordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .hide()
      .setGroup(uiFile);

    buttonSave = cp5.addButton("saveButton")
      .setPosition(60, 40)
      .setSize(140, 20)
      .setGroup(uiFile)
      .setLabel("Save recording");

    buttonClear = cp5.addButton("clearButton")
      .setPosition(120, 180)
      .setSize(80, 20)
      .setGroup(uiFile)
      .setColorBackground(color(155))
      .setLabel("Clear recording");

    inputFilename = cp5.addTextfield("input")
      .setPosition(60, 0)
      .setSize(140, 20)
      .setFocus(true)
      .setGroup(uiFile)
      .setLabel("File name:");
  }


  void draw() {
    pushMatrix();
    translate(x, y);

    // move cube background to colorcube class
    fill(225);
    if (isRecording == true) {
      stroke(205, 50, 20);
    } else { 		
      stroke(190);
    } 		
    rect(guiX2, 0, guiW, guiH);	

    graph.plot();
    cube.render();

    popMatrix();
    while (isConnected && connection.available() > 0) {
      //int inByte = connection.read();
      //println(inByte);

      String serialMessage = connection.readString();
      serialMessage = serialMessage.substring(0, serialMessage.length() - 1);
      println(serialMessage);
    }
  }



  void updateCube(float rotationX, float rotationZ, int cFront, int cSide, int cTop) {
    cube.setRotation(rotationX, 0.0, rotationZ);
    cube.applyColor(cFront, cSide, cTop);
  }


  void addToGraph(JSONObject data) {
    JSONObject d = new JSONObject();
    d.setFloat("pitch", data.getFloat("pitch"));
    d.setFloat("roll", data.getFloat("roll"));
    graph.addData(d);
  }


  // TODO maybe separate these to ui helpers
  void lockButton(Button button) {
    button.lock().setColorBackground(buttonInactive);
  }

  void unlockButton(Button button) {
    button.unlock().setColorBackground(controlP5.ControlP5Constants.THEME_CP5BLUE.getBackground());
  }

  void showButton(Button button) {
    unlockButton(button);
    button.show();
  }

  void hideButton(Button button) {
    lockButton(button);
    button.hide();
  }
}