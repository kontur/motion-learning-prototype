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
import java.lang.reflect.Method;

class Track {

  PApplet parent;

  ColorCube cube;
  Grapher graph;
  JSONObject graphConfig;  
  Recording recording;

  int x;
  int y;

  boolean isRecording = false;
  boolean tryToConnect = false;

  String label = "";

  /* sensor data tmp variables for last frame */
  float[] accel = new float[3];
  float[] gyro = new float[3];
  float[] mag = new float[3];
  float pitch = 0;
  float roll = 0;

  // slider values min max
  float rotationMin = -90.0;
  float rotationMax = 90.0;

  // don't change, as these are also the strings to access the respective values in grapher
  String[] sliders = { "pitch", "roll", "heading", "gyro_x", "gyro_y", "gyro_z", "accel_x", "accel_y", "accel_z" };
  ArrayList<String> checkboxes = new ArrayList<String>();


  /* UI */
  //positioning
  int guiX1 = 10; // + 200 + 10
  int guiX2 = 220; // + 200 + 10
  int guiX3 = 440; // + 200 + 10
  int guiX4 = 640; // + 400 + 10
  int guiX5 = 1060;
  int guiW = 200;
  int guiH = 200;

  //controls
  ControlP5 cp5;
  DropdownList bluetoothDeviceList;
  Button buttonConnectBluetooth;
  Button buttonCloseBluetooth;
  Button buttonRefreshBluetooth;
  Textlabel labelBluetooth;
  Button buttonClear;
  Button buttonRecord;
  Button buttonStopRecord;
  Button buttonSave;
  Textfield inputFilename;
  CheckBox checkboxGraph;
  Textlabel labelTime;


  int buttonInactive = color(200);

  /* Bluetooth connection */
  char[] inBuffer = new char[12];
  boolean isConnected = false;
  int baudRate = 9600;
  Serial connection;
  int lastTransmission = 0;  
  float transmissionSpeed = 0;



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

    recording = new Recording();

    graphConfig = JSONObject.parse("{ " + 
      "\"resolutionX\": 1.00, \"resolutionY\": 200.00, " +
      "\"roll\": { \"color\": " + color(255, 0, 0) + "}, " + 
      "\"pitch\": { \"color\": " + color(0, 0, 255) + "}, " +

      "\"gyro_x\": { \"color\": " + color(100, 250, 0) + "}, " +
      "\"gyro_y\": { \"color\": " + color(250, 250, 0) + "}, " +
      "\"gyro_z\": { \"color\": " + color(100, 0, 0) + "}, " +

      "\"accel_x\": { \"color\": " + color(255, 255, 0) + "}, " +
      "\"accel_y\": { \"color\": " + color(255, 0, 255) + "}, " +
      "\"accel_z\": { \"color\": " + color(255, 150, 0) + "}, "
      + "}");

    graph = new Grapher(guiX4, 0, guiW * 2, guiH);
    graph.setConfiguration(graphConfig);

    cube = new ColorCube(100.0, 50.0, 10.0, cubeGrey, cubeGrey, cubeGrey);
    cube.setPosition(350.0, 80.0, 50.0);

    createUI(parent);
    setButtonsDisconnected();
  }


  void draw() {
    pushMatrix();
    translate(x, y);
    
    if (tryToConnect) {
      connectBluetooth();
    }
    
    // move cube background to colorcube class
    fill(225);
    if (isRecording == true) {
      stroke(205, 50, 20);
      graph.setRecording(color(205, 50, 20));
      labelTime.show();
      labelTime.setText("" + recording.getDuration());
    } else {
      stroke(190);
      graph.setNotRecording();
    }     
    rect(guiX2, 0, guiW, guiH);

    graph.plot();
    cube.render();

    popMatrix();

    if (isConnected) {
      JSONObject d = new JSONObject();
      d.setFloat("pitch", pitch);
      d.setFloat("roll", roll);

      d.setFloat("gyro_x", gyro[0]);
      d.setFloat("gyro_y", gyro[1]);
      d.setFloat("gyro_z", gyro[2]);

      d.setFloat("accel_x", accel[0]);
      d.setFloat("accel_y", accel[1]);
      d.setFloat("accel_z", accel[2]);

      graph.addData(d);

      graph.showGraphsFor(checkboxes);

      if (isRecording) {
        recording.addData(d);
      }
    }
  }


  void createUI(PApplet window) {

    cp5 = new ControlP5(window);

    // bluetooth connect UI
    controlP5.Group uiBluetooth = cp5.addGroup("uiBluetooth")
      .hideBar()
      .setPosition(guiX1, y);

    labelBluetooth = cp5.addTextlabel("labelBluetooth")
      .setPosition(0, 30)
      .setGroup(uiBluetooth)
      .hide();

    buttonConnectBluetooth = cp5.addButton("connectBluetooth")
      .setPosition(0, 30)
      .setSize(100, 20)
      .setGroup(uiBluetooth)
      .setLabel("Connect bluetooth")
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          parent.method("showOverlayBluetooth");
          println("now pausing before trying connect");
          delay(1000);
          println("now trying to connect");
          tryToConnect = true;
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

          isConnected = false;
          connection.stop();
          connection = null;
          setButtonsDisconnected();
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

    PImage refreshImage = loadImage("data/refresh.png");
    PImage refreshImageHover = loadImage("data/refresh_hover.png");
    buttonRefreshBluetooth = cp5.addButton("refreshBluetooth")
      .setPosition(180, 0)
      .setSize(20, 20)
      .setImages(refreshImage, refreshImageHover, refreshImage, refreshImage)
      .setGroup(uiBluetooth)
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
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

    for (int i = 0; i < sliders.length; i++) {
      String item = sliders[i];      
      cp5.addSlider(item)
        .setPosition(0, i * 15)
        .setSize(150, 10)
        .setRange(rotationMin, rotationMax)
        .setGroup(uiSliders);
      checkboxGraph.addItem(item + "Checkbox", i).toggle(i).hideLabels();
      checkboxes.add(sliders[i]);
    }


    //recording and saving buttons
    controlP5.Group uiFile = cp5.addGroup("uiFile")
      .hideBar()
      .setPosition(guiX5, y);

    PImage recordImage = loadImage("data/record.png");
    PImage recordImageHover = loadImage("data/record_hover.png");
    PImage recordImageDisabled = loadImage("data/record_disabled.png");
    buttonRecord = cp5.addButton("recordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .setImages(recordImage, recordImageHover, recordImageDisabled, recordImageDisabled)
      .setGroup(uiFile)
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          println("record!");
          parent.method("startRecording");
        }
      }
    }
    );

    PImage recordStopImage = loadImage("data/stop.png");
    PImage recordStopImageHover = loadImage("data/stop_hover.png");
    buttonStopRecord = cp5.addButton("stopRecordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .setImages(recordStopImage, recordStopImageHover, recordStopImage, recordStopImage)
      .hide()
      .setGroup(uiFile)
      .setLabel("Stop recording")
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          println("stop recording!");
          parent.method("stopRecording");
        }
      }
    }
    );


    buttonSave = cp5.addButton("saveButton")
      .setPosition(100, 60)
      .setSize(100, 20)
      .setGroup(uiFile)
      .setLabel("Save recording")
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          println("save!");
          parent.method("saveRecording");
        }
      }
    }
    );

    buttonClear = cp5.addButton("clearButton")
      .setPosition(120, 180)
      .setSize(80, 20)
      .setGroup(uiFile)
      .setColorBackground(color(155))
      .setLabel("Clear recording")
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          println("clear!");
          parent.method("clearRecording");
        }
      }
    }
    );

    inputFilename = cp5.addTextfield("input")
      .setPosition(60, 0)
      .setSize(140, 20)
      .setFocus(true)
      .setGroup(uiFile)
      .setLabel("File name:");

    labelTime = cp5.addTextlabel("labelTime")
      .setPosition(0, 60)
      .setGroup(uiFile)
      .hide();
  }



  void process(JSONObject obj) {
    //cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
    //cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
    //cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));

    // debugging bluetooth send intervals
    //println("Millis since last transmission: ", millis() - lastTransmission);    
    float factor = 0.9;
    transmissionSpeed = factor * transmissionSpeed + (1 - factor) * (millis() - lastTransmission);
    //println("Average transmission time: ", transmissionSpeed);    
    lastTransmission = millis();

    roll = obj.getFloat("r");
    pitch = obj.getFloat("p");

    accel[0] = obj.getFloat("aX");
    accel[1] = obj.getFloat("aY");
    accel[2] = obj.getFloat("aZ");

    gyro[0] = obj.getFloat("gX");
    gyro[1] = obj.getFloat("gY");
    gyro[2] = obj.getFloat("gZ");

    //          String rgb = obj.getString("rgb");
    //          String colorComponents[] = rgb.split(",");
    //deviceRGB = new Color(int(colorComponents[0]), int(colorComponents[1]), int(colorComponents[2]));

    cp5.getController("roll").setValue(roll);
    cp5.getController("pitch").setValue(pitch);

    cp5.getController("gyro_x").setValue(gyro[0]);
    cp5.getController("gyro_y").setValue(gyro[1]);
    cp5.getController("gyro_z").setValue(gyro[2]);

    cp5.getController("accel_x").setValue(accel[0]);
    cp5.getController("accel_y").setValue(accel[1]);
    cp5.getController("accel_z").setValue(accel[2]);

    cube.setRotation(roll, 0.0, pitch);
  }


  void connectBluetooth() {
    tryToConnect = false;
    
    String[] ports = Serial.list();
    //buttonConnectBluetooth.hide();
    String port = "";

    if (bluetoothDeviceList.getValue() != 0) {
      port = ports[int(bluetoothDeviceList.getValue()) - 1];
    }
    log("Attempting to open serial port: " + port);
    println(port);

    try {
      connection = new Serial(parent, port, 9600);

      // set a character that limits transactions and initiates reading the buffer
      // this prevents premature reads, when the frame loop of processing runs
      // faster than the string is fully transmitted
      char c = ';';
      connection.bufferUntil(byte(c));
      print("Bluetooth connected to " + port);
      isConnected = true;
      setButtonsConnected();

      labelBluetooth.setText("Connected to " + port);
      parent.method("hideOverlay");
    } 
    catch (RuntimeException e) {
      println("Error opening serial port " + port + ": \n" + e.getMessage());
      parent.method("hideOverlay");
    }
  }


  void updateCube(float rotationX, float rotationZ, int cFront, int cSide, int cTop) {
    cube.setRotation(rotationX, 0.0, rotationZ);
    cube.applyColor(cFront, cSide, cTop);
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


  void setButtonsConnected() {
    hideButton(buttonConnectBluetooth);
    hideButton(buttonRefreshBluetooth);
    bluetoothDeviceList.hide();
    labelBluetooth.show();

    showButton(buttonCloseBluetooth);
    lockButton(buttonSave);
    lockButton(buttonClear);
    unlockButton(buttonRecord);
  }

  void setButtonsDisconnected() {
    showButton(buttonConnectBluetooth);
    lockButton(buttonConnectBluetooth);
    showButton(buttonRefreshBluetooth);
    bluetoothDeviceList.show();
    labelBluetooth.hide();

    hideButton(buttonCloseBluetooth);
    unlockButton(buttonSave);
    unlockButton(buttonClear);
    lockButton(buttonRecord);
  }

  void enableRecordingUI() {
    showButton(buttonSave);
    showButton(buttonClear);
    showButton(buttonRecord);
    inputFilename.unlock();
    inputFilename.show();

    if (isConnected) {
      setButtonsConnected();
    } else {
      setButtonsDisconnected();
    }

    if (recording.getSize() > 0) {
      unlockButton(buttonSave);
      unlockButton(buttonClear);
    } else {
      lockButton(buttonSave);
      lockButton(buttonClear);
    }
  }

  void disableRecordingUI() {
    hideButton(buttonSave);
    hideButton(buttonClear);
    hideButton(buttonRecord);
    inputFilename.lock();
    inputFilename.hide();
  }


  void startRecording() {
    if (isConnected) {
      recording.clear();
      isRecording = true;

      showButton(buttonStopRecord);
      unlockButton(buttonStopRecord);
      hideButton(buttonRecord);
    }
  }

  void stopRecording() {
    println("recording size", recording.getSize());
    isRecording = false;
    if (recording.getSize() > 0) {
      unlockButton(buttonSave);
      unlockButton(buttonClear);
      buttonSave.setColorBackground(color(200, 50, 20));
    }

    showButton(buttonRecord);
    unlockButton(buttonRecord);
    hideButton(buttonStopRecord);
  }

  void clearRecording() {
    labelTime.hide();
    recording.clear();
    lockButton(buttonSave);
  }


  void saveData(String filename) {

    String[] headers = { 
      "roll", 
      "pitch", 

      "aX", 
      "aY", 
      "aZ", 

      "gX", 
      "gY", 
      "gZ"
    };

    recording.saveData(filename, headers);
    buttonSave.setColorBackground(controlP5.ControlP5Constants.THEME_CP5BLUE.getBackground());
  }

  void checkboxEvent() {
    float[] a = checkboxGraph.getArrayValue();        
    int col = 0;
    checkboxes = new ArrayList<String>();
    for (int i=0; i<a.length; i++) {
      int n = (int)a[i];
      if (n == 1) {
        checkboxes.add(sliders[i]);
      }
    }
  }


  String getFilename() {
    String filename = inputFilename.getText();
    return filename;
  }
}