/**
* TODO:
* recording motion changes
* writing motion files
*
* file recording and playback fps
*/
import processing.serial.*;
import processing.opengl.*;

import controlP5.*;

import java.lang.RuntimeException;
import java.lang.ArrayIndexOutOfBoundsException;
import java.awt.Color;

import javax.swing.*; 

import toxi.geom.*;


//String defaultSerial = "/dev/tty.wristbandproto-SPP";
//String defaultSerial = "/dev/tty.RNBT-C094-RNI-SPP";
String defaultSerial = "/dev/cu.RNBT-BF5D-RNI-SPP";

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
int modeSelected = 0;
Button buttonConnectBluetooth;
Button buttonCloseBluetooth;


// playback and recording
JSONArray recording = new JSONArray();
JSONArray recordingMatch = new JSONArray();
String recordingWhat = "";
int recordingIndex = 0;
boolean record = false;
boolean play = false;
int playbackIndex = 0;
JSONArray playback = new JSONArray();

int recordLimit = 1000;
Grapher recordingGraph;
Grapher recordingMatchGraph;

float[] accel = new float[3];
float[] gyro = new float[3];
float[] mag = new float[3];
Color deviceRGB;

int lastClick = 0;
int numClicks = 0;
int doubleClickThreshold = 500;

boolean finishedComparison = true;

// graphing the readings
Grapher graph;

JSONObject config = JSONObject.parse("{ " + 
    "\"resolutionX\": 0.50, \"resolutionY\": 400.00, " +
    "\"rotationX\": { \"color\": " + color(255, 0, 0) + "}, " + 
    "\"rotationY\": { \"color\": " + color(0, 255, 0) + "}, " + 
    "\"rotationZ\": { \"color\": " + color(0, 0, 255) + "}, " +
    "\"accelX\": { \"color\": " + color(0, 125, 0) + "}, " +
    "\"accelY\": { \"color\": " + color(0, 125, 50) + "}, " +
    "\"accelZ\": { \"color\": " + color(0, 125, 125) + "} " 
    + "}");
    
JSONObject configPatterns = JSONObject.parse("{ " + 
    "\"resolutionX\": 1.00, \"resolutionY\": 400.00, " +
    "\"roll\": { \"color\": " + color(255, 0, 0) + "}, " + 
    "\"heading\": { \"color\": " + color(0, 255, 0) + "}, " + 
    "\"pitch\": { \"color\": " + color(0, 0, 255) + "}, " +
    "\"accelX\": { \"color\": " + color(0, 125, 0) + "}, " +
    "\"accelY\": { \"color\": " + color(0, 125, 50) + "}, " +
    "\"accelZ\": { \"color\": " + color(0, 125, 125) + "}, " +
    "\"gyroX\": { \"color\": " + color(0, 125, 0) + "}, " +
    "\"gyroY\": { \"color\": " + color(0, 125, 50) + "}, " +
    "\"gyroZ\": { \"color\": " + color(0, 125, 125) + "} " 
    + "}");


void setup() {
    size(winW, winH, OPENGL);
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

    if (lastClick != 0 && millis() - lastClick  > doubleClickThreshold) {
        println("--------");
        println(numClicks + " detected");

        switch (numClicks) {
            case 1:
                if (recording.size() == 0) {
                    println("start recording");
                    recordPattern(1);
                } else if (record) {
                    if (recordingWhat == "pattern") {
                        println("stop recording");
                        stopRecording();
                    } else if (recordingWhat == "match") {                        
                        println("stop recording match");
                        stopRecording();
                    }
                } else if (recording.size() != 0 && !record) {
                    println("start recording match");
                    recordMatch(1);
                }
                break;

            case 2:
                println("delete recording");
                recording = new JSONArray();
                recordingMatch = new JSONArray();
                break;

            default: 
                break;
        }
        numClicks = 0;
        lastClick = 0;
    }


    // show spinny animation until connected
    if (modeSelected == 0) {
        rotationX += 0.5;
        //rotationY += 1;
        rotationZ += 2;
        if (rotationX > 360) rotationX = 0;
        //if (rotationY > 360) rotationY = 0;
        if (rotationZ > 360) rotationZ = 0;
        cp5.getController("rotationX").setValue(rotationX);
        cp5.getController("rotationY").setValue(rotationY);
        cp5.getController("rotationZ").setValue(rotationZ);

    // mode 1 is connecting

    // mode 2 is connected
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

        log("recording " + recordingWhat + " at index " + recordingIndex);
        

        if (recordingIndex == recordLimit) {
            stopRecording();
        }

        if (recordingWhat == "match") {
            println("finishedComparison", finishedComparison);
            if (finishedComparison) {            
                try {
                    println("try to calc similarity");
                    log(similarity(1));
                } catch (RuntimeException e) {
                    log (e.getMessage());
                }
            } else {
                println("Similarity calculating still in progress, skip");
            }
            
        }

        if (recordingWhat == "match" && recordingIndex >= recording.size()) {
            stopRecording();
        }
    }

    JSONObject obj = new JSONObject();
    obj.setFloat("rotationX", rotationX);
    obj.setFloat("rotationY", rotationY);
    obj.setFloat("rotationZ", rotationZ);
    
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

    if (moviePlaying == true) {
        drawMovie();
    }
}


void serialEvent(Serial port) {

    try {   
        String s = connection.readString();
        s = s.substring(0, s.length() - 1);
        
        println("serialEvent: ", s);

        // if the serial string read contains a json opening { parse info from arduino
        if (s.indexOf("{") > -1) {
            JSONObject obj = JSONObject.parse(s);

                if (s.indexOf("buttonDown") > -1) {
                    obj.getInt("buttonDown");
                    println("BUTTON DOWN");
                    onButtonDown();
                } else {

                    cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
                    //cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
                    cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
                    
                    accel[0] = obj.getFloat("aX");
                    accel[1] = obj.getFloat("aY");
                    accel[2] = obj.getFloat("aZ");
                    gyro[0] = obj.getFloat("gX");
                    gyro[1] = obj.getFloat("gY");
                    gyro[2] = obj.getFloat("gZ");

                    //String rgb = obj.getString("rgb");
                    //String colorComponents[] = rgb.split(",");
                    //deviceRGB = new Color(int(colorComponents[0]), int(colorComponents[1]), int(colorComponents[2]));
                }
        }
    } catch (RuntimeException e) {
        log("Error reading bluetooth: " + e.getMessage());
    }
}


void onButtonDown() {
    if (numClicks == 0 || millis() - lastClick < doubleClickThreshold) {
        numClicks++;
        lastClick = millis();
    }
}


void recordPattern(int val) {
    recordSample(recording);
    recordingWhat = "pattern";
}

void recordMatch(int val) {
    recordSample(recordingMatch);
    recordingWhat = "match";
}


// helper
void recordSample(JSONArray data) {
    if (record) {
        log("Finish recording");
        sendBluetoothCommand("recordingEnd");
        record = false;
    } else {
        log("Start recording");     
        sendBluetoothCommand("recordingStart");
        recordingIndex = 0;
        data = new JSONArray();
        debugText.setText("");
        record = true;
    }
}

void stopRecording() {
    record = false;
    if (recordingWhat == "pattern") {
        recordingGraph = new Grapher(200, 400, 200, 100);
        recordingGraph.setConfiguration(configPatterns);
        recordingGraph.addDataArray(recording);
    } else if (recordingWhat == "match") {
        int missingFrames = recording.size() - recordingMatch.size();
        if (missingFrames > 0) {
            for (int i = recordingMatch.size(); i < recording.size(); i++) {

                JSONObject values = new JSONObject();
                values.setInt("id", i);
                values.setFloat("roll", 0);
                values.setFloat("heading", 0);
                values.setFloat("pitch", 0);
                values.setFloat("accelX", 0);
                values.setFloat("accelY", 0);
                values.setFloat("accelZ", 0);
                values.setFloat("gyroX", 0);
                values.setFloat("gyroY", 0);
                values.setFloat("gyroZ", 0);

                recordingMatch.setJSONObject(i, values);
            }
        }
        recordingMatchGraph = new Grapher(400, 400, 200, 100);
        recordingMatchGraph.setConfiguration(configPatterns);
        recordingMatchGraph.addDataArray(recordingMatch);   

        similarity(1);
    }

    recordingWhat = "";
}




/**
 * Button click handler to start calculating matches
 */
float similarity(int val) {
    finishedComparison = false;

    if (recording == null || recordingMatch == null || recording.size() == 0 || recordingMatch.size() == 0) {
        log("Can't calculate similarity, missing pattern or match to test against");
        throw new RuntimeException("Similarity calculation impossible, missing pattern or match data");
    }

    /*
    if (recording.size() != recordingMatch.size()) {
        log("Can't calculate similarity, non equal length pattern and match");
        throw new RuntimeException("Similarity calculation impossible, non equal pattern and match");
    }
    */

    println(recording.size(), recordingMatch.size());

    int commonLength = min(recording.size(), recordingMatch.size());
    println(commonLength);

    if (commonLength < 20) {
        finishedComparison = true;
        return 0.0;
    }

    Similarity s = new Similarity();
    double [][] patternValues = new double[8][commonLength];
    double [][] matchValues = new double[8][commonLength];

    try {

        for (int i = 0; i < commonLength; i++) {

            JSONObject recordingAtI = recording.getJSONObject(i);
            patternValues[0][i] = (double)recordingAtI.getFloat("roll");
            patternValues[1][i] = (double)recordingAtI.getFloat("pitch");
            patternValues[2][i] = (double)recordingAtI.getFloat("accelX");
            patternValues[3][i] = (double)recordingAtI.getFloat("accelY");
            patternValues[4][i] = (double)recordingAtI.getFloat("accelZ");
            patternValues[5][i] = (double)recordingAtI.getFloat("gyroX");
            patternValues[6][i] = (double)recordingAtI.getFloat("gyroY");
            patternValues[7][i] = (double)recordingAtI.getFloat("gyroZ");

            JSONObject matchAtI = recordingMatch.getJSONObject(i);
            matchValues[0][i] = (double)matchAtI.getFloat("roll");
            matchValues[1][i] = (double)matchAtI.getFloat("pitch");
            matchValues[2][i] = (double)matchAtI.getFloat("accelX");
            matchValues[3][i] = (double)matchAtI.getFloat("accelY");
            matchValues[4][i] = (double)matchAtI.getFloat("accelZ");
            matchValues[5][i] = (double)matchAtI.getFloat("gyroX");
            matchValues[6][i] = (double)matchAtI.getFloat("gyroY");
            matchValues[7][i] = (double)matchAtI.getFloat("gyroZ");
        }
    } catch (ArrayIndexOutOfBoundsException e) {
        log(e.getMessage());
        log("Exiting similarity()");
        connection.stop();
        return 0.0;
    }

    float sim = s.compare(patternValues, matchValues);

    println("Calucalted similarity from 0 - 1: " + sim);
    log("Calucalted similarity from 0 - 1: " + sim);
    
    finishedComparison = true;

    if (sim < 0.5) {        
        sendBluetoothCommand("feedbackFail");
    } else if (sim >= 0.5 && sim < 0.8) {
        sendBluetoothCommand("feedbackGood");
    } else {
        sendBluetoothCommand("feedbackPerfect");
    }

    return sim;
}



void log(String msg) {
    msg = msg + "\n" + debugText.getText();
    debugText.setText(msg);
}




// testing video 
void mousePressed() {
    println("pressed");
    //playFeedback();
    //sendBluetoothCommand("recordStart");
}
