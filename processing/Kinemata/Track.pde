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
  Track that;

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
  float vibration = 0;

  // slider values min max
  float sliderMin = -90;
  float sliderMax = 90;

  // don't change, as these are also the strings to access the respective values in grapher
  String[] sliders = { "pitch", "roll", "heading", "vibration", "gyro_x", "gyro_y", "gyro_z", "accel_x", "accel_y", "accel_z" };
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
  Textlabel bluetoothFPS;
  Button buttonClear;
  Button buttonRecord;
  Button buttonStopRecord;
  Button buttonSave;
  Textfield inputFilename;
  CheckBox checkboxGraph;
  Textlabel labelTime;


  // images for non custom buttons
  PImage refreshImage = loadImage("data/refresh.png");
  PImage refreshImageHover = loadImage("data/refresh_hover.png");

  PImage recordImage = loadImage("data/record.png");
  PImage recordImageHover = loadImage("data/record_hover.png");
  PImage recordImageDisabled = loadImage("data/record_disabled.png");

  PImage recordStopImage = loadImage("data/stop.png");
  PImage recordStopImageHover = loadImage("data/stop_hover.png");


  int buttonInactive = color(200);

  /* Bluetooth connection */
  char[] inBuffer = new char[12];
  boolean isConnected = false;
  int baudRate = 9600;
  Serial connection;
  int lastTransmission = 0;  
  float transmissionSpeed = 0;
  String port = "";


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
    that = this;

    recording = new Recording();

    graphConfig = JSONObject.parse("{ " + 
      "\"resolutionX\": 1.00, \"resolutionY\": 200.00, " +
      "\"roll\": { \"color\": " + color(255, 0, 0) + "}, " + 
      "\"pitch\": { \"color\": " + color(0, 0, 255) + "}, " +
      "\"vibration\": { \"color\": " + color(255, 255, 100) + "}, " +

      "\"gyro_x\": { \"color\": " + color(100, 250, 0) + "}, " +
      "\"gyro_y\": { \"color\": " + color(250, 250, 0) + "}, " +
      "\"gyro_z\": { \"color\": " + color(100, 0, 0) + "}, " +

      "\"accel_x\": { \"color\": " + color(255, 255, 0) + "}, " +
      "\"accel_y\": { \"color\": " + color(255, 0, 255) + "}, " +
      "\"accel_z\": { \"color\": " + color(255, 150, 0) + "}, "
      + "}");

    graph = new Grapher(guiX4, 0, guiW * 2, guiH);
    graph.setConfiguration(graphConfig);

    cube = new ColorCube(100.0, 50.0, 10.0, color(255, 100, 100), color(100, 255, 100), color(100, 100, 255));
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
      labelTime.setText("" + (float)recording.getDuration() / 1000 + " s");
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
      d.setFloat("vibration", vibration);

      d.setFloat("gyro_x", gyro[0]);
      d.setFloat("gyro_y", gyro[1]);
      d.setFloat("gyro_z", gyro[2]);

      d.setFloat("accel_x", accel[0]);
      d.setFloat("accel_y", accel[1]);
      d.setFloat("accel_z", accel[2]);

      // update the graph with current data only when
      // - we're recording
      // - we've recorded and not cleared / saved the data yet
      if (isRecording || (!isRecording && recording.getSize() == 0)) {
        graph.addData(d);
        graph.showGraphsFor(checkboxes);
      }

      if (isRecording) {
        recording.addData(d);
      } else {
        // there is a bluetooth connection and we are 
        // not currently recording: check if the record button 
        // should be disabled or active
        
        if (inputFilename.getText().length() > 0 && recording.getSize() == 0) {
          enableRecordButton();
        } else {
          disableRecordButton();
        }
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
          showOverlayBluetooth(that);
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
          bluetoothFPS.setText("");
          isConnected = false;
          connection.stop();
          connection = null;
          setButtonsDisconnected();
          clearRecording();
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

    bluetoothFPS = cp5.addTextlabel("bluetoothFPS")
      .setPosition(0, 180)
      .setSize(140, 20)
      .setGroup(uiBluetooth)
      .setText("");

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
      Slider s = cp5.addSlider(item)
        .setPosition(0, i * 15)
        .setSize(150, 10)
        .setGroup(uiSliders);

      if (item != "vibration") {
        s.setRange(sliderMin, sliderMax);
      } else {
        s.setRange(0, 255);
      }
      checkboxGraph.addItem(item + "Checkbox", i).toggle(i).hideLabels();
      checkboxes.add(sliders[i]);
    }


    //recording and saving buttons
    controlP5.Group uiFile = cp5.addGroup("uiFile")
      .hideBar()
      .setPosition(guiX5, y);

    buttonRecord = cp5.addButton("recordButton")
      .setPosition(0, 0)
      .setSize(50, 50)
      .setImages(recordImage, recordImageHover, recordImageDisabled, recordImageDisabled)
      .setGroup(uiFile)
      .addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_RELEASE) {
          mainStartRecording(that);
        }
      }
    }
    );

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
          mainStopRecording(that);
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
          mainSaveRecording(that);
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
          mainClearRecording(that);
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
    // unfortunately the callback from the textfield is very crude
    // and does not fire when text changes?!
    // so we can't react to text input directly like this:    
    //.addCallback(new CallbackListener() {
    //public void controlEvent(CallbackEvent theEvent) {
    //  //println(theEvent.getAction());
    //  //println("textfield filename", inputFilename.getText());
    //}
    //}
    //);

    labelTime = cp5.addTextlabel("labelTime")
      .setPosition(0, 60)
      .setGroup(uiFile)
      .hide();
  }



  void process(JSONObject obj) {
    int transmissionElapsed = millis() - lastTransmission;
    float factor = 0.75;

    if (transmissionSpeed == 0) {
      transmissionSpeed = transmissionElapsed;
    } else {
      transmissionSpeed = transmissionSpeed * factor + transmissionElapsed * (1 - factor);
    }
    bluetoothFPS.setText("Connection: "  + (round(transmissionSpeed / 10) * 100) + " fps / " + (round(transmissionSpeed)) + " ms)");

    lastTransmission = millis();


    roll = obj.getFloat("r");
    pitch = obj.getFloat("p");
    vibration = obj.getFloat("v");

    accel[0] = obj.getFloat("aX");
    accel[1] = obj.getFloat("aY");
    accel[2] = obj.getFloat("aZ");

    gyro[0] = obj.getFloat("gX");
    gyro[1] = obj.getFloat("gY");
    gyro[2] = obj.getFloat("gZ");

    cp5.getController("roll").setValue(roll);
    cp5.getController("pitch").setValue(pitch);
    cp5.getController("vibration").setValue(vibration);

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
    port = "";

    if (bluetoothDeviceList.getValue() != 0) {
      port = ports[int(bluetoothDeviceList.getValue()) - 1];
    }
    log("Attempting to open serial port: " + port);

    try {
      connection = new Serial(parent, port, 9600);

      // set a character that limits transactions and initiates reading the buffer
      // this prevents premature reads, when the frame loop of processing runs
      // faster than the string is fully transmitted
      char c = ';';
      connection.bufferUntil(byte(c));
      isConnected = true;
      setButtonsConnected();

      labelBluetooth.setText("Connected to " + port);
      hideOverlay();

      log("Bluetooth connected to " + port);

      lastTransmission = millis();
    } 
    catch (RuntimeException e) {
      log("Error opening serial port " + port + ": \n" + e.getMessage());
      hideOverlay();
    }
  }


  void updateCube(float rotationX, float rotationZ, int cFront, int cSide, int cTop) {
    cube.setRotation(rotationX, 0.0, rotationZ);
    cube.applyColor(cFront, cSide, cTop);
  }



  /**
   * UI HELPERS 
   */

  // TODO maybe separate these to ui helpers
  void lockButton(Button button) {
    if (!button.isLock()) {
      button.lock().setColorBackground(buttonInactive);
    }
  }

  void unlockButton(Button button) {
    if (button.isLock()) {
      button.unlock().setColorBackground(controlP5.ControlP5Constants.THEME_CP5BLUE.getBackground());
    }
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
    lockButton(buttonSave);
    lockButton(buttonClear);
    lockButton(buttonRecord);
    buttonRecord.setImage(recordImageDisabled);

    inputFilename.setText("");
  }

  void enableRecordingUI() {
    showButton(buttonSave);
    showButton(buttonClear);
    showButton(buttonRecord);
    inputFilename.unlock();
    inputFilename.show();

    disableRecordButton();

    if (isConnected) {
      setButtonsConnected();
    } else {
      setButtonsDisconnected();
    }

    lockButton(buttonClear);
    if (recording.getSize() > 0) {
      unlockButton(buttonSave);
      lockButton(buttonRecord);
    } else {
      lockButton(buttonSave);
    }
  }

  void disableRecordingUI() {
    hideButton(buttonSave);
    hideButton(buttonClear);
    hideButton(buttonRecord);
    inputFilename.lock();
    inputFilename.hide();
    disableRecordButton();
  }

  void enableRecordButton() {
    buttonRecord.setImages(recordImage, recordImageHover, recordImage, recordImage);
    unlockButton(buttonRecord);
    buttonRecord.bringToFront();
  }
  void disableRecordButton() {
    buttonRecord.setImages(recordImageDisabled, recordImageDisabled, recordImageDisabled, recordImageDisabled);
    lockButton(buttonRecord);
  }


  /**
   * RECORDING HELPERS
   */

  void startRecording() {
    if (isConnected) {
      recording.clear();
      isRecording = true;

      showButton(buttonStopRecord);
      unlockButton(buttonStopRecord);
      hideButton(buttonRecord);
    }
  }

  boolean stopRecording() {
    if (isRecording) {
      log("Recorded " + recording.getSize() + " frames (" + framesToSeconds(recording.getSize()) + " seconds)");
      isRecording = false;
      if (recording.getSize() > 0) {
        unlockButton(buttonSave);
        unlockButton(buttonClear);
        buttonSave.setColorBackground(color(200, 50, 20));
      }

      showButton(buttonRecord);
      lockButton(buttonRecord);
      hideButton(buttonStopRecord);

      return true;
    } else {
      isRecording = false;
      return false;
    }
  }

  void clearRecording() {
    labelTime.hide();
    recording.clear();
    lockButton(buttonSave);
    lockButton(buttonClear);
    enableRecordButton();
    inputFilename.unlock();
  }


  boolean saveData(String filename) {
    String[] headers = {
      "id", 

      "roll", 
      "pitch", 
      "vibration", 

      "accel_x", 
      "accel_y", 
      "accel_z", 

      "gyro_x", 
      "gyro_y", 
      "gyro_z"
    };

    //buttonSave.setColorBackground(controlP5.ControlP5Constants.THEME_CP5BLUE.getBackground());
    //enableRecordButton();
    return recording.saveData(filename, headers);
  }

  void checkboxEvent() {
    float[] a = checkboxGraph.getArrayValue();
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


  // helper to dump a list of available serial ports into the passed in DropdownList
  void getBluetoothDeviceList(DropdownList list) {
    log("Listing available bluetooth devices");
    String[] ports = Serial.list();
    list.clear();  
    list.addItem("---", 0);
    for (int p = 0; p < ports.length; p++) {
      String port = ports[p];
      // filter out "tty" ports
      // filter out ports with "usb"
      if (port.indexOf("tty") == -1 && port.indexOf("usb") == -1) {
        // add whatever port found to the dropdown
        list.addItem(port, p  + 1);
      }
    }
  }
}