/**
* TODO:
* recording motion changes
* writing motion files
*
* file recording and playback fps
*/
import processing.serial.*;
import controlP5.*;
import java.lang.RuntimeException;

String defaultSerial = "/dev/tty.wristbandproto-SPP";

float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;

float rotationMin = 0;
float rotationMax = 360;


// TODO fullscreen?
int winW = 800;
int winH = 600;


// bluetooth connection
char[] inBuffer = new char[12];
int inBufferIndex = 0;
boolean isConnected = false;
boolean tryingToConnect = false;
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
CheckBox autoConnect;
boolean autoConnectActive = false;


// playback and recording
JSONArray recording = new JSONArray();
JSONArray recordingMatch = new JSONArray();
String recordingWhat = "";
int recordingIndex = 0;
boolean record = false;
boolean play = false;
int playbackIndex = 0;
JSONArray playback = new JSONArray();

int recordLimit = 100;
Grapher recordingGraph;
Grapher recordingMatchGraph;

float[] accel = new float[3];
float[] gyro = new float[3];
float[] mag = new float[3];


// graphing the readings
Grapher graph;
JSONObject config = JSONObject.parse("{ " + 
    "\"resolutionX\": 1.00, \"resolutionY\": 400.00, " +
    "\"rotationX\": { \"color\": " + color(255, 0, 0) + "}, " + 
    "\"rotationY\": { \"color\": " + color(0, 255, 0) + "}, " + 
    "\"rotationZ\": { \"color\": " + color(0, 0, 255) + "}, " +
    "\"accelX\": { \"color\": " + color(0, 125, 0) + "}, " +
    "\"accelY\": { \"color\": " + color(0, 125, 50) + "}, " +
    "\"accelZ\": { \"color\": " + color(0, 125, 125) + "} " 
    + "}");


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
        //cp5.getController("rotationY").setValue(rotationY);
        cp5.getController("rotationZ").setValue(rotationZ);

    } else if (modeSelected == 2) {

        println(playback.getJSONObject(playbackIndex));  
        JSONObject values = playback.getJSONObject(playbackIndex);
        cp5.getController("rotationX").setValue(values.getFloat("roll"));
        //cp5.getController("rotationY").setValue(values.getFloat("heading"));
        cp5.getController("rotationZ").setValue(values.getFloat("pitch"));

        playbackIndex++;
        if (playbackIndex > playback.size() - 1) {
            playbackIndex = 0;
        }

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
        values.setFloat("accelX", map(accel[0], -1, 1, 0, 300));
        values.setFloat("accelY", map(accel[1], -1, 1, 0, 300));
        values.setFloat("accelZ", map(accel[2], -1, 1, 0, 300));
        values.setFloat("gyroX", map(gyro[0], -360, 360, 0, 300));
        values.setFloat("gyroY", map(gyro[1], -360, 360, 0, 300));
        values.setFloat("gyroZ", map(gyro[2], -360, 360, 0, 300));

        if (recordingWhat == "pattern") {
            recording.setJSONObject(recordingIndex, values);
        } else if (recordingWhat == "match") {
            recordingMatch.setJSONObject(recordingIndex, values);
        }
        recordingIndex++;   
        debugText.setText(debugText.getText() + values + "\n");
        debugText.scroll(1);
        if (recordingIndex == recordLimit) {
            record = false;
            if (recordingWhat == "pattern") {
                recordingGraph = new Grapher(400, 400, 200, 100);
                recordingGraph.addDataArray(recording);
            } else if (recordingWhat == "match") {
                recordingMatchGraph = new Grapher(200, 400, 200, 100);
                recordingMatchGraph.addDataArray(recordingMatch);                
            }

            recordingWhat = "";
        }
    }

    JSONObject obj = new JSONObject();
    obj.setFloat("rotationX", rotationX);
    //obj.setFloat("rotationY", rotationY);
    obj.setFloat("rotationZ", rotationZ);
    // obj.setFloat("accelX", map(accel[0], -1, 1, 0, 300));
    // obj.setFloat("accelY", map(accel[1], -1, 1, 0, 300));
    // obj.setFloat("accelZ", map(accel[2], -1, 1, 0, 300));
    // obj.setFloat("gyroX", map(gyro[0], -360, 360, 0, 300));
    // obj.setFloat("gyroY", map(gyro[1], -360, 360, 0, 300));
    // obj.setFloat("gyroZ", map(gyro[2], -360, 360, 0, 300));
    // obj.setFloat("magX", map(mag[0], -1, 1, 0, 300));
    // obj.setFloat("magY", map(mag[1], -1, 1, 0, 300));
    // obj.setFloat("magZ", map(mag[2], -1, 1, 0, 300));

    graph.addData(obj);
    graph.plot();

    if (recordingGraph != null) {
        recordingGraph.plot();
    }

    if (recordingMatchGraph != null) {
        recordingMatchGraph.plot();
    }

    if (connection != null) {
        tryingToConnect = false;
    }

    if (connection == null && autoConnectActive == true && tryingToConnect == false) {
        println("AUTOCONNECT");
        connectBluetooth(1);
    }
}


void serialEvent(Serial port) {
    String s = connection.readString();
    s = s.substring(0, s.length() - 1);
    
    // println("serialEvent: ", s);

    if (s.indexOf("{") > -1) {
    JSONObject obj = JSONObject.parse(s);
        cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
        //cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
        cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
        accel[0] = obj.getFloat("accelX");
        accel[1] = obj.getFloat("accelY");
        accel[2] = obj.getFloat("accelZ");
        gyro[0] = obj.getFloat("gyroX");
        gyro[1] = obj.getFloat("gyroY");
        gyro[2] = obj.getFloat("gyroZ");
        mag[0] = obj.getFloat("magX");
        mag[1] = obj.getFloat("magY");
        mag[2] = obj.getFloat("magZ");
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


void recordPattern(int val) {   // recordingIndex = 0;
    // recording = new JSONArray();
    // debugText.setText("");
    // record = true;
    recordSample(recording);
    recordingWhat = "pattern";
}

void recordMatch(int val) {
    recordSample(recordingMatch);
    recordingWhat = "match";
}

void recordSample(JSONArray data) {
    if (record) {
        println("finish recording");
        record = false;
    } else {
        print("start recording");     
        recordingIndex = 0;
        data = new JSONArray();
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
    bluetoothDeviceList.addItem("---", 0);
    for (int p = 0; p < ports.length; p++) {
        String port = ports[p];
        bluetoothDeviceList.addItem(port, p  + 1);
    }
}


// helper function to start a bluetooth connection based on the selected dropdown list item
void connectBluetooth(int val) {
    mode.activate(1);
    modeSelected = 1;
    String[] ports = Serial.list();
    buttonConnectBluetooth.hide();
    try {
        tryingToConnect = true;
        String port = defaultSerial;
        println(Serial.list());
        if (bluetoothDeviceList.getValue() != 0) {
            port = ports[int(bluetoothDeviceList.getValue()) - 1];
        }
        println("Attempting to open serial port: " + port);
        connection = new Serial(this, port, 9600);

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
        tryingToConnect = false;
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


void autoConnectCheckbox(float[] vals) {
    println("autoConnectCheckbox", vals);
    println(autoConnect.getArrayValue());
    if (autoConnect.getArrayValue()[0] == 1.00) {
        autoConnectActive = true;
    } else {
        autoConnectActive = false;
    }
}


/**
 * Button click handler to start calculating matches
 */
void similarity(int val) {

    if (recording == null || recordingMatch == null) {
        throw new RuntimeException("Similarity calculation missing information");
    }


    Similarity s = new Similarity();
    double [][] patternValues = new double[2][100];
    double [][] matchValues = new double[2][100];

    // TODO also check JSONArray lengths for equality
    for (int i = 0; i < recording.size(); i++) {
        JSONObject recordingAtI = recording.getJSONObject(i);
        patternValues[0][i] = (double)recordingAtI.getFloat("roll");
        patternValues[1][i] = (double)recordingAtI.getFloat("pitch");

        JSONObject matchAtI = recordingMatch.getJSONObject(i);
        matchValues[0][i] = (double)matchAtI.getFloat("roll");
        matchValues[1][i] = (double)matchAtI.getFloat("pitch");
    }

    float sim = s.compare(patternValues, matchValues);
    println(sim);
    debugText.setText("" + sim);

    /*
    double [][] testscores = { 
        {36, 62, 31, 76, 46, 12, 39, 30, 22, 9, 32, 40, 64, 
          36, 24, 50, 42, 2, 56, 59, 28, 19, 36, 54, 14}, 
        {58, 54, 42, 78, 56, 42, 46, 51, 32, 40, 49, 62, 75, 
         38, 46, 50, 42, 35, 53, 72, 50, 46, 56, 57, 35}, 
        {43, 50, 41, 69, 52, 38, 51, 54, 43, 47, 54, 51, 70, 
         58, 44, 54, 52, 32, 42, 70, 50, 49, 56, 59, 38}, 
        {36, 46, 40, 66, 56, 38, 54, 52, 28, 30, 37, 40, 66, 
         62, 55, 52, 38, 22, 40, 66, 42, 40, 54, 62, 29}, 
        {37, 52, 29, 81, 40, 28, 41, 32, 22, 24, 52, 49, 63, 
         62, 49, 51, 50, 16, 32, 62, 63, 30, 52, 58, 20}}; 
    double [][] testscores2 = { 
        {36, 62, 31, 76, 46, 12, 39, 30, 22, 9, 32, 40, 64, 
          36, 24, 50, 42, 2, 56, 59, 28, 19, 36, 54, 14}, 
        {43, 50, 41, 69, 52, 38, 51, 54, 43, 47, 54, 51, 70, 
         58, 44, 54, 52, 32, 42, 70, 50, 49, 56, 59, 38}, 
        {36, 46, 40, 66, 56, 38, 54, 52, 28, 30, 37, 40, 66, 
         62, 55, 52, 38, 22, 40, 66, 42, 40, 54, 62, 29},
        {97, 52, 29, 81, 40, 28, 41, 92, 22, 24, 52, 49, 69, 
         62, 49, 51, 50, 16, 32, 62, 63, 30, 52, 58, 20}, 
        {58, 54, 42, 78, 56, 42, 46, 51, 32, 40, 49, 62, 75, 
         38, 46, 50, 42, 35, 53, 72, 50, 46, 56, 57, 35}}; 
     */
}
