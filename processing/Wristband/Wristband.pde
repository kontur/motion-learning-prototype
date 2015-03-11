/**
 * TODO:
 * recording motion changes
 * writing motion files
 *
 * file recording and playback fps
 */
import org.json.*;
import processing.serial.*;
import controlP5.*;

ControlP5 cp5;

boolean useBluetooth = false;

float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;

float rotationMin = 0;
float rotationMax = 360;

int winW = 800;
int winH = 600;


char[] inBuffer = new char[12];
int inBufferIndex = 0;
boolean isConnected = false;
int baudRate = 9600;
String initialCommand = "listening.";

Textarea debugText;
DropdownList bluetoothDeviceList;

Serial connection;

void setup() {
  size(winW, winH, P3D);

  cp5 = new ControlP5(this);


  // bluetooth connect UI
  cp5.addButton("connectBluetooth")
    .setPosition(450, 20)
      .setSize(100, 20);

  bluetoothDeviceList = cp5.addDropdownList("btDeviceList")
    .setPosition(250, 20)
      .setSize(150, 200);

  getBluetoothDeviceList(bluetoothDeviceList);        


  // manual rotation for cube visualisation
  cp5.addSlider("rotationX")
    .setPosition(50, 50)
      .setRange(rotationMin, rotationMax);

  cp5.addSlider("rotationY")
    .setPosition(50, 70)
      .setRange(rotationMin, rotationMax);

  cp5.addSlider("rotationZ")
    .setPosition(50, 90)
      .setRange(rotationMin, rotationMax);


  // file handling buttons
  cp5.addButton("loadFile")
    .setPosition(50, 300)
      .setSize(100, 20);

  cp5.addButton("recordFile")
    .setPosition(50, 330)
      .setSize(100, 20);

  cp5.addButton("saveFile")
    .setPosition(50, 360)
      .setSize(100, 20);


  // file I/O check textarea
  debugText = cp5.addTextarea("txt")
    .setPosition((winW - 400), 0)
      .setSize((winW - 400), winH)
        .setFont(createFont("arial", 10))
          .setColor(0)
            .setColorBackground(color(255, 100))
              .setColorBackground(color(255, 100));
}


void getBluetoothDeviceList(DropdownList list) { 
  //if (useBluetooth) {
  println("hello");
  String[] foo = Serial.list();
  println(foo);
  for (int i = 0; i < foo.length; i++) {
    String f = foo[i];
    println("foo ", f);
    bluetoothDeviceList.addItem(f, i);
  }
}


JSONArray recording = new JSONArray();
int recordingIndex = 0;
boolean record = false;

void draw() {
  background(255);
  stroke(0);  
  ColorCube c = new ColorCube(50.0, 10.0, 100.0, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255));
  c.setRotation(rotationX, rotationY, rotationZ);
  c.setPosition(winW / 2, winH / 2, 0);
  c.render();

  if (record) {
    JSONObject values = new JSONObject();
    values.setInt("id", recordingIndex);
    values.setFloat("rotation", random(360));
    values.setFloat("heading", random(360));
    recording.setJSONObject(recordingIndex, values);
    recordingIndex++;
    debugText.setText(debugText.getText() + recordingIndex + "\n");
  }
}


void serialEvent(Serial port) {
  String s = connection.readString();
  s = s.substring(0, s.length() - 1);
  println("str " + s);
  if (s.indexOf("{") > -1) {  
    JSON obj = JSON.parse(s);    
    cp5.getController("rotationX").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
    cp5.getController("rotationY").setValue(map(obj.getFloat("tilt"), -180, 180, 0, 360));
    cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -180, 180, 0, 360));
  }
}


void loadFile(int val) {
  selectInput("File", "fileSelected");
}


void recordFile(int val) {
  if (record) {
    println("finish recording");
    record = false;
  } else {
    print("start recording");
    recordingIndex = 0;
    recording = new JSONArray();
    debugText.setText("");
    record = true;
  }
}

void saveFile(int val) {
  println("saveFile " + val);
  selectOutput("File to save to:", "fileToSave");
}

void fileToSave(File selection) {
  println("save to " + selection);
  if (selection != null) {
    try {
      saveJSONArray(recording, selection.toString());
    } 
    catch (RuntimeException e) {
      println("fileToSave failed, " + e.getMessage());
    }
  }
}

void fileSelected(File selection) {
  if (selection != null) {
    try {
      JSONArray values = loadJSONArray(selection);
      println(values);
    } 
    catch (RuntimeException e) {
      println("loadFile failed, " + e.getMessage());
    }
  }
}

void connectBluetooth(int val) {
  println("connectBluetooth");
  println("selected: " + bluetoothDeviceList.getValue());
  /*
    
   try {
   println(Serial.list());
   // TODO make this selectable from list
   connection = new Serial(this, "/dev/tty.wristbandproto-SPP", 9600);
   char c = ';';
   println("limiter" + byte(c));
   connection.bufferUntil(byte(c));
   } 
   catch (RuntimeException e) {
   println("error: " + e.getMessage());
   noLoop();
   exit();
   }
   */
  //}
}

