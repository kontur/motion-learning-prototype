/*

States:
1) Program started, nothing connected
2) BT connected, showing live info
3) Recording pattern
4) Recording match

5) BT connecting
6) BT disconnected


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
int winW = 1024;
int winH = 768;

int guiLeft = 10;
int guiCenter = 400;
int guiRight = 700;

int guiHeader = 100;
int guiTop = 150;
int guiMiddle = 400;
int guiBottom = 600;


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
int mode = 0;
Button buttonConnectBluetooth;
Button buttonCloseBluetooth;


// playback and recording
String recordingWhat = "";
int recordingIndex = 0;
boolean record = false;
boolean play = false;

int recordLimit = 1000;

float[] accel = new float[3];
float[] gyro = new float[3];
float[] mag = new float[3];
float pitch = 0;
float roll = 0;
Color deviceRGB = new Color(100, 100, 100);

int lastClick = 0;
int numClicks = 0;
int doubleClickThreshold = 500;

boolean finishedComparison = true;


Track pattern;
Track match;


void setup() {
    size(winW, winH, OPENGL);
    setupUI();

    pattern = new Track(guiLeft, guiTop);
    match = new Track(guiLeft, guiMiddle);
}


void draw() {
    background(225);
    stroke(0);    

    checkClicks();

    // show spinny animation until connected
    if (mode == 0) {
        idleAnimation();

        JSONObject data = new JSONObject();
        data.setFloat("roll", rotationZ);
        data.setFloat("pitch", rotationX);

        if (pattern.hasRecording == false) {
            pattern.updateCube(rotationZ, rotationX, deviceRGB.getRGB());            
            pattern.graph.addData(data);
        }

        if (match.hasRecording == false) {
            match.updateCube(rotationZ, rotationX, deviceRGB.getRGB());
            match.graph.addData(data);
        }
    }

    // mode 1 is connecting
    else if (mode == 1) {
        log("Connecting...");
    }

    // mode 2 is bluetooth connected
    else if (mode == 2) {
        pattern.updateCube(roll, pitch, deviceRGB.getRGB());

        JSONObject data = new JSONObject();
        data.setFloat("roll", roll);
        data.setFloat("pitch", pitch);

        pattern.graph.addData(data);
    }


    if (record && recordingWhat == "pattern") {
        JSONObject values = new JSONObject();
        values.setFloat("roll", roll);
        //values.setFloat("heading", rotationY);
        values.setFloat("pitch", pitch);
        values.setFloat("accelX", map(accel[0], -1, 1, 0, 300));
        values.setFloat("accelY", map(accel[1], -1, 1, 0, 300));
        values.setFloat("accelZ", map(accel[2], -1, 1, 0, 300));
        values.setFloat("gyroX", map(gyro[0], -360, 360, 0, 300));
        values.setFloat("gyroY", map(gyro[1], -360, 360, 0, 300));
        values.setFloat("gyroZ", map(gyro[2], -360, 360, 0, 300));
        values.setInt("rgb", deviceRGB.getRGB());
        pattern.record(values);
    }

    if (record && recordingWhat == "match") {
        JSONObject values = new JSONObject();
        values.setFloat("roll", roll);
        //values.setFloat("heading", rotationY);
        values.setFloat("pitch", pitch);
        values.setFloat("accelX", map(accel[0], -1, 1, 0, 300));
        values.setFloat("accelY", map(accel[1], -1, 1, 0, 300));
        values.setFloat("accelZ", map(accel[2], -1, 1, 0, 300));
        values.setFloat("gyroX", map(gyro[0], -360, 360, 0, 300));
        values.setFloat("gyroY", map(gyro[1], -360, 360, 0, 300));
        values.setFloat("gyroZ", map(gyro[2], -360, 360, 0, 300));
        values.setInt("rgb", deviceRGB.getRGB());
        match.record(values);

        pattern.playbackAt(match.recordingIndex);
    }

        /*
    if (record) {

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

        if (recordingWhat == "match" && recordingIndex >= recordingPattern.size()) {
            stopRecording();
        }
    }
        */


    if (connection != null) {
        tryingToConnect = false;
    }

    if (moviePlaying == true) {
        drawMovie();
    }

    pattern.draw();
    match.draw();
}


/**
 * Catch all serial communication and parse what came in
 */
void serialEvent(Serial port) {
    try {   
        String serialMessage = connection.readString();
        serialMessage = serialMessage.substring(0, serialMessage.length() - 1);
        
        println("serialEvent: ", serialMessage);

        // if the serial string read contains a json opening { parse info from arduino
        if (serialMessage.indexOf("{") > -1) {
            JSONObject obj = JSONObject.parse(serialMessage);

                if (serialMessage.indexOf("buttonDown") > -1) {
                    obj.getInt("buttonDown");
                    println("BUTTON DOWN");
                    onButtonDown();
                } else {
                    cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
                    //cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
                    cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
                    
                    roll = obj.getFloat("roll");
                    pitch = obj.getFloat("pitch");

                    accel[0] = obj.getFloat("aX");
                    accel[1] = obj.getFloat("aY");
                    accel[2] = obj.getFloat("aZ");

                    gyro[0] = obj.getFloat("gX");
                    gyro[1] = obj.getFloat("gY");
                    gyro[2] = obj.getFloat("gZ");

                    String rgb = obj.getString("rgb");
                    String colorComponents[] = rgb.split(",");
                    deviceRGB = new Color(int(colorComponents[0]), int(colorComponents[1]), int(colorComponents[2]));
                }
        }
    } catch (RuntimeException e) {
        log("Error reading bluetooth: " + e.getMessage());
    }
}


/** 
 * Handler for when JSON of a button click has been received
 */
void onButtonDown() {
    if (numClicks == 0 || millis() - lastClick < doubleClickThreshold) {
        numClicks++;
        lastClick = millis();
    }
}


/**
 * Button handler for starting a recording
 */
 
void recordPattern(int val) {
    if (record == false) {
        recordingWhat = "pattern";
        record = true;
        pattern.startRecording();
    } else {
        stopRecording();
    }
}


/**
 * Button handler for starting a recording
 */

void recordMatch(int val) {
    if (record == false) {
        recordingWhat = "match";
        record = true;
        match.startRecording();
    } else {
        stopRecording();
    }
}


void stopRecording() {
    record = false;
    if (recordingWhat == "pattern") {
        pattern.stopRecording();
    } else if (recordingWhat == "match") {
        match.stopRecording();
        /*
        int missingFrames = recordingPattern.size() - recordingMatch.size();
        if (missingFrames > 0) {
            for (int i = recordingMatch.size(); i < recordingPattern.size(); i++) {

                JSONObject values = new JSONObject();
                values.setInt("id", i);
                values.setFloat("roll", 0);
                //values.setFloat("heading", 0);
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
        */
    }
    recordingWhat = "";
}


/**
 * Button click handler to start calculating matches
 */
float similarity(int val) {
    finishedComparison = false;
/*
    if (recordingPattern == null || recordingMatch == null || recordingPattern.size() == 0 || recordingMatch.size() == 0) {
        log("Can't calculate similarity, missing pattern or match to test against");
        throw new RuntimeException("Similarity calculation impossible, missing pattern or match data");
    }
    */

    /*
    if (recordingPattern.size() != recordingMatch.size()) {
        log("Can't calculate similarity, non equal length pattern and match");
        throw new RuntimeException("Similarity calculation impossible, non equal pattern and match");
    }
    */

/*
    println(recordingPattern.size(), recordingMatch.size());

    int commonLength = min(recordingPattern.size(), recordingMatch.size());
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

            JSONObject recordingAtI = recordingPattern.getJSONObject(i);
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
    */
    return 0.0;
}


/**
 * Helper for drawing the animation of non connected devices
 */
void idleAnimation () {    
    rotationX += 0.5;
    //rotationY += 1;
    rotationZ += 2;
    if (rotationX > 360) rotationX = 0;
    //if (rotationY > 360) rotationY = 0;
    if (rotationZ > 360) rotationZ = 0;
    cp5.getController("rotationX").setValue(rotationX);
    cp5.getController("rotationY").setValue(rotationY);
    cp5.getController("rotationZ").setValue(rotationZ);
}


/**
 * Helper to be called in each draw loop to check and detect clicks and double clicks
 */
void checkClicks() {    
    if (lastClick != 0 && millis() - lastClick  > doubleClickThreshold) {
        println("--------");
        println(numClicks + " detected");

/*
        switch (numClicks) {
            case 1:
                if (recordingPattern.size() == 0) {
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
                } else if (recordingPattern.size() != 0 && !record) {
                    println("start recording match");
                    recordMatch(1);
                }
                break;

            case 2:
                println("delete recording");
                recordingPattern = new JSONArray();
                recordingMatch = new JSONArray();
                break;

            default: 
                break;
        }
        */
        numClicks = 0;
        lastClick = 0;
    }
}


/**
 * Helper to log messages on screen
 */
void log(String msg) {
    msg = msg + "\n\n" + debugText.getText();
    debugText.setText(msg);
}

