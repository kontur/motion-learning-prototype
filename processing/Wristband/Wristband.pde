/**
* TODO:
* recording motion changes
* writing motion files
*
* file recording and playback fps
*/
import processing.serial.*;
import controlP5.*;

float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;


// TODO fullscreen?
int winW = 800;
int winH = 600;


// bluetooth connection
char[] inBuffer = new char[12];
int inBufferIndex = 0;
boolean isConnected = false;
int baudRate = 9600;
Serial connection;


// UI elements and helpers
ControlP5 cp5;
Textarea debugText;
DropdownList bluetoothDeviceList;
RadioButton mode;
int modeSelected = 0;
Button buttonConnectBluetooth;
Button buttonCloseBluetooth;


// playback and recording
JSONArray recording = new JSONArray();
int recordingIndex = 0;
boolean record = false;
boolean play = false;
int playbackIndex = 0;
JSONArray playback = new JSONArray();


// graphing the readings
Grapher graph;
JSONObject config = JSONObject.parse("{ \"rotationX\": { \"color\": " + color(255, 0, 0) + 
  "} , \"rotationY\": { \"color\": " + color(0, 255, 0) + 
  "}, \"rotationZ\": { \"color\": " + color(0, 0, 255) + "}}");


void setup() {
    size(winW, winH, P3D);
    setupUI();
    graph.setConfiguration(config);
}


void draw() {
    background(225);
    stroke(0);  
    ColorCube c = new ColorCube(100.0, 50.0, 10.0, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255));
    c.setRotation(rotationX, rotationY, rotationZ);
    c.setPosition(winW / 2, winH / 2, 0);
    c.render();

    // show spinny animation until connected
    if (modeSelected == 0) {
        rotationX += 0.5;
        rotationY += 1;
        rotationZ += 2;
        if (rotationX > 360) rotationX = 0;
        if (rotationY > 360) rotationY = 0;
        if (rotationZ > 360) rotationZ = 0;
        cp5.getController("rotationX").setValue(rotationX);
        cp5.getController("rotationY").setValue(rotationY);
        cp5.getController("rotationZ").setValue(rotationZ);

    } else if (modeSelected == 2) {

        println(playback.getJSONObject(playbackIndex));  
        JSONObject values = playback.getJSONObject(playbackIndex);
        cp5.getController("rotationX").setValue(values.getFloat("roll"));
        cp5.getController("rotationY").setValue(values.getFloat("heading"));
        cp5.getController("rotationZ").setValue(values.getFloat("pitch"));

        playbackIndex++;
        if (playbackIndex > playback.size() - 1) {
            playbackIndex = 0;
        }

        //if (play) {
        if (connection != null) {
        try {
            connection.write("roll:" + rotationX + ",heading:" + rotationY + ",pitch:" + rotationZ + ";");
        }
        catch (RuntimeException e) {
            println("play: exception " + e.getMessage());
        }
    }

    // TODO send this info back to arduino
    }

    if (record) {
        JSONObject values = new JSONObject();
        values.setInt("id", recordingIndex);
        values.setFloat("roll", rotationX);
        values.setFloat("heading", rotationY);
        values.setFloat("pitch", rotationZ);
        recording.setJSONObject(recordingIndex, values);
        recordingIndex++;
        debugText.setText(debugText.getText() + values + "\n");
        debugText.scroll(1);
    }

    JSONObject obj = new JSONObject();
    obj.setFloat("rotationX", rotationX);
    obj.setFloat("rotationY", rotationY);
    obj.setFloat("rotationZ", rotationZ);
    graph.addData(obj);
    graph.plot();
}


void serialEvent(Serial port) {
    String s = connection.readString();
    s = s.substring(0, s.length() - 1);
    println(s);
    if (s.indexOf("{") > -1) {  
    JSONObject obj = JSONObject.parse(s);
        cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
        cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
        cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
    }
}


void modeRadioButton(int a) {
    modeSelected = a;
}


void loadFile(int val) {
    selectInput("File", "fileSelected");
}


void fileSelected(File selection) {
    if (selection != null) {
        try {
            JSONArray values = loadJSONArray(selection);
            playback = values;
            playbackIndex = 0;
            mode.activate(2);
            modeSelected = 2;
        } 
        catch (RuntimeException e) {
           println("loadFile failed, " + e.getMessage());
        }
    }
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


// helper to dump a list of available serial ports into the passed in DropdownList
void getBluetoothDeviceList(DropdownList list) {
    String[] ports = Serial.list();
    for (int p = 0; p < ports.length; p++) {
        String port = ports[p];
        bluetoothDeviceList.addItem(port, p);
    }
}


// helper function to start a bluetooth connection based on the selected dropdown list item
void connectBluetooth(int val) {
    mode.activate(1);
    modeSelected = 1;
    String[] ports = Serial.list();
    buttonConnectBluetooth.hide();
    try {
        println(Serial.list());
        println("Attempting to open serial port: " + ports[int(bluetoothDeviceList.getValue())]);
        connection = new Serial(this, ports[int(bluetoothDeviceList.getValue())], 9600);

        // set a character that limits transactions and initiates reading the buffer
        char c = ';';
        connection.bufferUntil(byte(c));
        buttonConnectBluetooth.hide();
        buttonCloseBluetooth.show();
    } 
    catch (RuntimeException e) {
        println("error: " + e.getMessage());
        buttonConnectBluetooth.show();
        buttonCloseBluetooth.hide();
    }
}


// helper function to close the bluetooth connection
void closeBluetooth(int val) {
    mode.activate(0);
    modeSelected = 0;
    try {
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

