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
  int guiX3 = 430; // + 400 + 10
  int guiX4 = 840;
  int guiW = 200;
  int guiH = 200;

  //controls
  ControlP5 cp5;
  controlP5.Group uiBluetooth;
  DropdownList bluetoothDeviceList;
  Button buttonConnectBluetooth;
  Button buttonCloseBluetooth;


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

    graph = new Grapher(guiX3, 0, guiW * 2, guiH);
    graph.setConfiguration(graphConfig);

    cube = new ColorCube(100.0, 50.0, 10.0, cubeGrey, cubeGrey, cubeGrey);
    cube.setPosition(200.0, 130.0, 50.0);

    createUI(window);
  }


  void createUI(PApplet window) {

    cp5 = new ControlP5(window);
    // bluetooth connect UI
    controlP5.Group uiBluetooth = cp5.addGroup("uiBluetooth")
      .hideBar()
      .setPosition(guiX1, y);

    cp5.addButton("connectBluetooth")
      .setPosition(0, 0)
      .setSize(100, 20)
      .setGroup(uiBluetooth)
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction()==ControlP5.ACTION_RELEASED) {
          String[] ports = Serial.list();
          //buttonConnectBluetooth.hide();
          String port = "";      

          if (bluetoothDeviceList.getValue() != 0) {
            port = ports[int(bluetoothDeviceList.getValue()) - 1];
          }
          log("Attempting to open serial port: " + port);
          println(port);
          println(parent);

          try {
            tryingToConnect = true;
            connection = new Serial(parent, port, 9600);

            // set a character that limits transactions and initiates reading the buffer
            char c = ';';
            connection.bufferUntil(byte(c));
            //buttonConnectBluetooth.hide();
            //buttonCloseBluetooth.show();
            //mode = 2;
            //sendBluetoothCommand("bluetoothConnected");
            print("Bluetooth connected to " + port);
            isConnected = true;
          } 
          catch (RuntimeException e) {
            print("Error opening serial port " + port + ": \n" + e.getMessage());
            //buttonConnectBluetooth.show();
            //buttonCloseBluetooth.hide();
            //tryingToConnect = false;
            //mode = 0;
          }
        }
      }
    }
    );

    cp5.addButton("closeBluetooth")
      .setPosition(0, 0)
      .setSize(100, 20)
      .setGroup(uiBluetooth)
      .hide();

    bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
      .setPosition(0, 40)
      .setSize(200, 200)
      .setGroup(uiBluetooth);

    getBluetoothDeviceList(bluetoothDeviceList);        

    /*
    DropdownList bluetoothDeviceList;
     Button buttonConnectBluetooth;
     Button buttonCloseBluetooth;
     */

    //recording and saving buttons
    controlP5.Group uiFile = cp5.addGroup("uiFile")
      .hideBar()
      .setPosition(guiX4, y);

    cp5.addButton("recordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .setGroup(uiFile);

    cp5.addButton("stopRecordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .hide()
      .setGroup(uiFile);

    cp5.addButton("saveButton")
      .setPosition(0, 50)
      .setSize(200, 20)
      .setGroup(uiFile);

    cp5.addButton("clearButton")
      .setPosition(0, 100)
      .setSize(200, 20)
      .setGroup(uiFile);

    cp5.addTextfield("input")
      .setPosition(0, 150)
      .setSize(200, 20)
      //.setFont(font)
      .setFocus(true)
      .setColor(color(255, 0, 0))
      .setGroup(uiFile);
  }

  void connectBluetooth() {
    println("hello BT");
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
}