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

float rotationMin = -90;
float rotationMax = 90;


// TODO fullscreen?
int winW = 1024;
int winH = 768;

int guiLeft = 10;
int guiCenter = 400;
int guiRight = 610;

int guiHeader = 120;
int guiTop = 150;
int guiMiddle = 400;
int guiBottom = 640;


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
boolean record = false;
boolean play = false;

int playbackIndex = 0;

float[] accel = new float[3];
float[] gyro = new float[3];
float[] mag = new float[3];
float pitch = 0;
float roll = 0;
Color deviceRGB = new Color(200, 200, 200);

int cubeGrey = 125;

int lastClick = 0;
int numClicks = 0;
int doubleClickThreshold = 1000;

boolean finishedComparison = true;

PImage logo;


Track pattern;
Track match;


// helpers for triggering a delay bluetooth command with millis() instead of delay()
String delayedCommand = ""; // empty string or/and delayedCommandStart == 0 skip execution
int delayedCommandStart = 0;
int delayedCommandDelay = 0;



/**
 * automatically run in fullscreen mode
 */
boolean sketchFullScreen() {
  return true;
}


void setup() {
    size(winW, winH, OPENGL);
    setupUI();

    pattern = new Track(guiLeft, guiTop, "Live movement");
    match = new Track(guiLeft, guiMiddle, "Matching movement");

    frameRate(24);

    logo = loadImage("kinemata.png");
}


void draw() {
    background(221);
    stroke(0);   

    image(logo, 10, 10);

    checkClicks();

    executeDelayedCommand();

    // show spinny animation until connected
    if (mode == 0) {        
        idleAnimation();

        JSONObject data = new JSONObject();

        // as there is no sensor readings from bluetooth take the current
        // animation positions
        pitch = rotationZ;
        roll = rotationX;

        data.setFloat("pitch", pitch);
        data.setFloat("roll", roll);

        if (pattern.hasRecording == false) {
            pattern.updateCube(pitch, roll, deviceRGB.getRGB(), cubeGrey, cubeGrey);
            pattern.addToGraph(data);
        }

        if (match.hasRecording == false) {
            match.updateCube(pitch, roll, deviceRGB.getRGB(), cubeGrey, cubeGrey);
            match.addToGraph(data);
        }
    }

    // mode 1 is connecting
    else if (mode == 1) {
        log("Connecting...");
    }

    // mode 2 is bluetooth connected
    else if (mode == 2) {

        JSONObject data = new JSONObject();
        data.setFloat("roll", roll);
        data.setFloat("pitch", pitch);

        if (pattern.hasRecording == false || (record == true && recordingWhat == "pattern")) {
            pattern.addToGraph(data);
            pattern.updateCube(pitch, roll, deviceRGB.getRGB(), cubeGrey, cubeGrey);
        }

        if (match.hasRecording == false || (record == true && recordingWhat == "match")) {
            match.addToGraph(data);
            match.updateCube(pitch, roll, deviceRGB.getRGB(), cubeGrey, cubeGrey);
        }
    }

    // mode 3 is playback
    else if (mode == 3) {
        println("playbackIndex", playbackIndex);
        if (pattern.hasRecording == true) {
            pattern.playbackAt(playbackIndex);
        }
        if (match.hasRecording == true) {
            match.playbackAt(playbackIndex);
        }
        playbackIndex++;
        if (playbackIndex >= pattern.getRecordingSize() || (pattern.hasRecording == false && match.hasRecording == false)) {
            if (connection != null) {
                mode = 2;
            } else {
                mode = 0;
            }
            playbackIndex = 0;
        }
    }



    // handle recording separately
    // ***************************

    if (record && recordingWhat == "pattern") {
        JSONObject values = new JSONObject();
        values.setFloat("roll", roll);
        values.setFloat("pitch", pitch);
        values.setFloat("accelX", accel[0]);
        values.setFloat("accelY", accel[1]);
        values.setFloat("accelZ", accel[2]);
        values.setFloat("gyroX", gyro[0]);
        values.setFloat("gyroY", gyro[1]);
        values.setFloat("gyroZ", gyro[2]);
        values.setInt("rgb", deviceRGB.getRGB());

        pattern.record(values);
    }

    if (record && recordingWhat == "match") {
        JSONObject values = new JSONObject();
        values.setFloat("roll", roll);
        values.setFloat("pitch", pitch);
        values.setFloat("accelX", accel[0]);
        values.setFloat("accelY", accel[1]);
        values.setFloat("accelZ", accel[2]);
        values.setFloat("gyroX", gyro[0]);
        values.setFloat("gyroY", gyro[1]);
        values.setFloat("gyroZ", gyro[2]);
        values.setInt("rgb", deviceRGB.getRGB());
        
        // for all frames but the last, play the pattern at the same spot
        // as the match is recording at the momemnt
        if (match.record(values)) {
            pattern.playbackAt(match.recordingIndex - 1);

            /*
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
            */
            
        } else {
            stopRecording();
        }

    }

    /*
    if (record) {
        if (recordingWhat == "match") {
        }

        if (recordingWhat == "match" && recordingIndex >= recordingPattern.size()) {
            stopRecording();
        }
    }
    */

    if (connection != null) {
        tryingToConnect = false;
    }

    pattern.draw();
    match.draw();

    if (moviePlaying == true) {
        drawMovie();
    }
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
                    cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -90, 90, 0, 360));
                    cp5.getController("rotationX").setValue(map(obj.getFloat("roll"), -90, 90, 0, 360));
                    //cp5.getController("rotationY").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
                    
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
        match.clearRecording();
        
        sendBluetoothCommand("recordingStart");
        delay(2000);

        pattern.startRecording();
        playFeedback("processing.mov", (guiRight + 5), (guiTop + 20), true);
    } else {
        stopRecording();
        stopMovie();
    }
}


/**
 * Button handler for starting a recording
 */
void recordMatch(int val) {
    if (record == false) {
        // reset the comparison in progress flag
        finishedComparison = true;

        // record no longer than the pattern itself
        int limit = pattern.getRecordingSize();

        if (limit <= 0) {
            log("Record a pattern first");
            return;
        }

        recordingWhat = "match";
        record = true;
        
        sendBluetoothCommand("recordingStart");
        delay(2000);

        
        match.setRecordingLimit(limit);
        match.startRecording();
        playFeedback("processing.mov", (guiRight + 5), (guiMiddle + 20), true);
    } else {
        stopRecording();
        stopMovie();
    }
}


void stopRecording() {
    log("Stop recording");
    record = false;
    if (recordingWhat == "pattern") {
        pattern.stopRecording();
        sendBluetoothCommand("recordingEnd");
        delay(1000);
    } else if (recordingWhat == "match") {

        /*
        if (pattern.getRecordingSize() > match.getRecordingSize()) {
            log("Stop recording command ignored; recording match to be same length as pattern");
            return;
        }
        */

        match.stopRecording();
        sendBluetoothCommand("recordingEnd");
        delay(1000);

        float sim = similarity();
        if (sim < 0.5) {
            neg(1);
        } else if (sim >= 0.5 && sim < 0.8) {
            neu(1);
        } else {
            pos(1);
        }

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
float similarity() {
    finishedComparison = false;

    JSONArray recordingPattern = pattern.getRecording();
    JSONArray recordingMatch = match.getRecording();

    if (recordingPattern == null || recordingMatch == null) {
        log("Can't calculate similarity, missing pattern or match to test against");
        finishedComparison = true;
        throw new RuntimeException("Similarity calculation impossible, missing pattern or match data");
    }
    

    /*
    if (recordingPattern.size() != recordingMatch.size()) {
        log("Can't calculate similarity, non equal length pattern and match");
        throw new RuntimeException("Similarity calculation impossible, non equal pattern and match");
    }
    */
    

    println(recordingPattern.size(), recordingMatch.size());


    int commonLength = min(recordingPattern.size(), recordingMatch.size());
    println("common length", commonLength);

    if (commonLength < 10) {
        finishedComparison = true;
        return 0.0;
    }

    Similarity s = new Similarity();
    double [][] patternValues = new double[8][commonLength];
    double [][] matchValues = new double[8][commonLength];

    try {

        for (int i = 0; i < commonLength; i++) {
            println("I", i);

            JSONObject patternAtI = recordingPattern.getJSONObject(i);
            println("pattern", patternAtI);
            patternValues[0][i] = (double)patternAtI.getFloat("roll");
            patternValues[1][i] = (double)patternAtI.getFloat("pitch");
            patternValues[2][i] = (double)patternAtI.getFloat("accelX");
            patternValues[3][i] = (double)patternAtI.getFloat("accelY");
            patternValues[4][i] = (double)patternAtI.getFloat("accelZ");
            patternValues[5][i] = (double)patternAtI.getFloat("gyroX");
            patternValues[6][i] = (double)patternAtI.getFloat("gyroY");
            patternValues[7][i] = (double)patternAtI.getFloat("gyroZ");

            JSONObject matchAtI = recordingMatch.getJSONObject(i);
            println("match", matchAtI);
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
        finishedComparison = true;
        return 0.0;
    }

    float sim = s.compare(patternValues, matchValues);

    println("Calucalted similarity from 0 - 1: " + sim);
    log("Calucalted similarity from 0 - 1: " + sim);
    
    finishedComparison = true;

    return sim;
}


/**
 * Helper for drawing the animation of non connected devices
 */
void idleAnimation () {

    rotationX += random(-2.0, 2.0);// * (abs(rotationX) / 100 + 0.25);
    rotationZ += random(-2.0, 2.0);// * (abs(rotationZ) / 100 + 0.25);

    if (rotationX > 90) rotationX = -90;
    if (rotationX < -90) rotationX = 90;

    if (rotationZ > 90) rotationZ = -90;
    if (rotationZ < -90) rotationZ = 90;

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

        // if we're currently recording, stop the recording
        // don't care about single or double click at this point, because we just want
        // to stop the current recording process
        if (record == true) {
            stopRecording();
            return;
        }

        switch (numClicks) {
            case 1:
                log("Single physical click");
                recordMatch(1);
                break;

            case 2:
                log("Double physical click");
                recordPattern(1);
                break;

            default: 
                log("Several physical clicks " + numClicks);
                break;
        }
        numClicks = 0;
        lastClick = 0;
    }
}


/**
 * Click handler of the playback button
 */
void playback(int val) {
    mode = 3;
    playbackIndex = 0;
}


/**
 * Helper for clearning recordings
 */
void clearPattern(int val) {
    pattern.clearRecording();
}


/**
 * Helper for clearning recordings
 */
void clearMatch(int val) {
    match.clearRecording();
}


/**
 * Helpers for the three different outcomes that also double as button even
 * handlers for the three helper buttons in the demo
 */
void pos(int val) {
    registerDelayedCommand("feedbackPerfect", 2000);
    playFeedback("perfect.mov", (guiRight + 5), (guiTop + 20), false);
}


void neu(int val) {
    registerDelayedCommand("feedbackGood", 2000);
    playFeedback("good.mov", (guiRight + 5), (guiTop + 20), false);
}


void neg(int val) {
    registerDelayedCommand("feedbackFail", 2000);
    playFeedback("fail.mov", (guiRight + 5), (guiTop + 20), false);
}


/**
 * Helper to setup a command to be executed after a delay without halting the programm
 */
void registerDelayedCommand(String _command, int _delay) {
    delayedCommand = _command;
    delayedCommandDelay = _delay;
    delayedCommandStart = millis();
}


/**
 * Helper to check for and exectue a delay command if there is any
 */
void executeDelayedCommand() {
    // first check if there is any command set up to be sent
    if (delayedCommand != "" && delayedCommandStart != 0) {
        // then only send it if delay has elapsed
        if (millis() > delayedCommandStart + delayedCommandDelay) {
            sendBluetoothCommand(delayedCommand);
            delayedCommand = "";
            delayedCommandDelay = 0;
            delayedCommandStart = 0;
        }
    }
}


/**
 * Helper to log messages on screen
 */
void log(String msg) {
    msg = msg + "\n\n" + debugText.getText();
    debugText.setText(msg);
}

