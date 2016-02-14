/*
Main entry point
 
 What this handles:
 - setting up window
 - adding and updating tracks
 */

import processing.serial.*;
import processing.opengl.*;

import controlP5.*;

import java.lang.RuntimeException;
import java.lang.ArrayIndexOutOfBoundsException;
import java.awt.Color;

import javax.swing.*; 

import toxi.geom.*;


float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;




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
RadioButton radioMode;



// playback and recording
String recordingWhat = "";
boolean record = false;
boolean play = false;
int recordingMode = 0; // 0 = single, 1 = separate

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


Track track1;
Track track2;


// helpers for triggering a delay bluetooth command with millis() instead of delay()
String delayedCommand = ""; // empty string or/and delayedCommandStart == 0 skip execution
int delayedCommandStart = 0;
int delayedCommandDelay = 0;


void setup() {
  //size(winW, winH, OPENGL);
  size(1280, 600, OPENGL);
  setupUI();

  track1 = new Track(this, guiLeft, guiTop, "Live movement");
  track2 = new Track(this, guiLeft, guiMiddle, "track2ing movement");

  // set to single recording by default
  radioMode(0);

  frameRate(60);

  logo = loadImage("kinemata.png");
}


void draw() {
  background(221);
  stroke(0);   

  image(logo, 10, 10);

  checkClicks();
  executeDelayedCommand();

  // handle recording separately
  // ***************************

  if (record && recordingWhat == "track1") {
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
  }

  if (record && recordingWhat == "track2") {
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
  }


  if (connection != null) {
    tryingToConnect = false;
  }

  track1.draw();
  track2.draw();
}


/**
 * Catch all serial communication and parse what came in
 */
void serialEvent(Serial connection) {
  try {
    //read bluetooth when available
    while (connection.available() > 0) {
      String serialMessage = connection.readString();
      //println(serialMessage);

      // remove any beginning or ending whitespace and semicolons
      serialMessage = serialMessage.replaceAll("^[\\s]*", "").replaceAll(";[\\s]*$", "");

      // do some extra formatting to make the incoming string valid json;
      // the abbreviation from:
      // "{\"p\":13.7,\"r\":3.9,\"aX\":3.7,\"aY\":3.9,\"aZ\":5.6,\"gX\":6.5,\"gY\":17.6,\"gZ\":4.0};"
      // to:
      // "{p13.7,r3.9,aX3.7,aY3.9,aZ5.6,gX6.5,gY17.6,gZ4.0};"
      // reduces send intervals from ~80ms to ~55ms
      // the second string is a sample of what indeed incomming, so remodel it to json
      serialMessage = serialMessage.replaceAll("([a-zA-Z]{1,2})", "\"$1\":");

      //println("serialMessage", serialMessage);

      // make sure we are actually getting a full json-ish string
      if (serialMessage.startsWith("{") && serialMessage.endsWith("}")) {
        JSONObject obj = JSONObject.parse(serialMessage);

        // check which track the incoming serialEvent belongs to and forward the parsed data
        if (connection == track1.connection) {
          track1.process(obj);
        } else if (connection == track2.connection) {
          track2.process(obj);
        }
      } else {
        println("Error reading bluetooth: Received bluetooth string with ; ending, but not looking like JSON");
      }
    }
  }
  catch (RuntimeException e) {
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
      return;
    }

    //switch (numClicks) {
    //case 1:
    //  log("Single physical click");
    //  break;

    //case 2:
    //  log("Double physical click");
    //  break;

    //default: 
    //  log("Several physical clicks " + numClicks);
    //  break;
    //}
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
 * Helpers for the three different outcomes that also double as button even
 * handlers for the three helper buttons in the demo
 */

void pos(int val) {
  registerDelayedCommand("feedbackPerfect", 2000);
  //playFeedback("perfect.mov", (guiRight + 5), (guiTop + 20), false);
}


void neu(int val) {
  registerDelayedCommand("feedbackGood", 2000);
  //playFeedback("good.mov", (guiRight + 5), (guiTop + 20), false);
}


void neg(int val) {
  registerDelayedCommand("feedbackFail", 2000);
  //playFeedback("fail.mov", (guiRight + 5), (guiTop + 20), false);
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


void radioMode(int mode) {
  if (mode == 0) {
    println("disable second track recording");
    track1.enableRecordingUI();
    track2.disableRecordingUI();
  } else {
    println("enable second track recording");
    track1.enableRecordingUI();
    track2.enableRecordingUI();
  }

  recordingMode = mode;
}


void startRecording() {
  println("Kinemata.startRecording()");
  track1.startRecording();
  track2.startRecording();
}

void stopRecording() {
  println("Kinemata.stopRecording()");
  track1.stopRecording();
  track2.stopRecording();
}

void saveRecording() {
  println("Kinemata.saveRecording()");
  if (mode == 0) {
    track1.saveData("track1");
    track2.saveData("track2");
  } else {
    //println(caller);
  }
}

void clearRecording() {
  println("Kinemata.clearRecording()");
  if (mode == 0) {
    track1.clearRecording();
    track2.clearRecording();
  } else {
    //println(caller);
  }
}


/**
 * Helper to log messages on screen
 */
void log(String msg) {
  msg = msg + "\n\n" + debugText.getText();
  debugText.setText(msg);
}


void controlEvent(ControlEvent theEvent) {
  track1.checkboxEvent();
}


//void checkboxGraph(float[] a) {
//  println("checkbox", a);

//  print("got an event from "+checkbox.getName()+"\t\n");
//    // checkbox uses arrayValue to store the state of 
//    // individual checkbox-items. usage:
//    println(checkbox.getArrayValue());
//    int col = 0;
//    for (int i=0;i<checkbox.getArrayValue().length;i++) {
//      int n = (int)checkbox.getArrayValue()[i];
//      print(n);
//      if(n==1) {
//        myColorBackground += checkbox.getItem(i).internalValue();
//      }
//    }
//  //println(checkboxGraph.getArrayValue());
//}