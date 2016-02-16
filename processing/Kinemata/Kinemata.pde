/*
Main entry point
 
 What this handles:
 - setting up window
 - adding and updating tracks
 */

import processing.opengl.*;
import controlP5.*;
import java.lang.RuntimeException;
import java.lang.ArrayIndexOutOfBoundsException;
import java.awt.Color;
import javax.swing.*; 


// null Overlay; when instantiated rendered on top
Overlay overlay;

// wait for uiReady before processing any kind of UI events
// otherwise there will be mayhem
boolean uiReady = false;


// UI elements and helpers on the top level
// note each Track() instance has it's own controls
ControlP5 cp5;
Textarea debugText;
int recordingMode = 0;
RadioButton radioMode;


//int lastClick = 0;
//int numClicks = 0;
//int doubleClickThreshold = 1000;

PImage logo;


Track track1;
Track track2;


void setup() {
  //size(winW, winH, OPENGL);
  size(1280, 600, OPENGL);
  setupUI();

  track1 = new Track(this, 10, 150, "Live movement");
  track2 = new Track(this, 10, 400, "track2ing movement");

  // set to single recording by default
  radioMode(0);

  frameRate(60);

  logo = loadImage("kinemata.png");

  uiReady = true;
}


void draw() {
  background(221);
  stroke(0);

  image(logo, 10, 10);

  //checkClicks();
  //executeDelayedCommand();

  track1.draw();
  track2.draw();

  if (overlay != null) {
    overlay.draw();
  }
}


/**
 * Catch all serial communication and parse what came in
 */
void serialEvent(Serial connection) {
  try {
    //read bluetooth when available
    while (connection.available() > 0) {
      String serialMessage = connection.readString();
      //log(serialMessage);

      // remove any beginning or ending whitespace and (the ending) semicolons
      serialMessage = serialMessage.replaceAll("^[\\s]*", "").replaceAll(";[\\s]*$", "");

      //log("serialMessage", serialMessage);

      // make sure we are actually getting a full string (i.e. with enough commas)
      if (serialMessage.replaceAll("[^,]", "").length() == 8) {

        // do some extra formatting to make the incoming string valid json;
        // the abbreviation from:
        // "{\"p\":13.7,\"r\":3.9,\"aX\":3.7,\"aY\":3.9,\"aZ\":5.6,\"gX\":6.5,\"gY\":17.6,\"gZ\":4.0};"
        // to:
        // "{p13.7,r3.9,aX3.7,aY3.9,aZ5.6,gX6.5,gY17.6,gZ4.0};"
        // reduces send intervals from ~80ms to ~55ms
        // the second string is a sample of what indeed incomming, so remodel it to json
        // further reduce by removing alphanumericals and "{}"

        String[] decodeString = {"p", "r", "v", "aX", "aY", "aZ", "gX", "gY", "gZ"};
        String[] parts = new String[8];
        parts = serialMessage.split(",");
        StringBuilder combined = new StringBuilder();
        combined.append("{");
        for (int i = 0; i < parts.length; i++) {
          combined.append(decodeString[i] + ":" + parts[i]);
          if (i < parts.length - 1) {
            combined.append(",");
          }
        }
        combined.append("}");

        JSONObject obj = JSONObject.parse(combined.toString());

        // check which track the incoming serialEvent belongs to and forward the parsed data
        if (connection == track1.connection) {
          track1.process(obj);
        } else if (connection == track2.connection) {
          track2.process(obj);
        }
      } else {
        log("Error reading bluetooth: Received bluetooth string with ; ending, but not looking like JSON");
      }
    }
  }
  catch (RuntimeException e) {
    log("Error reading bluetooth: " + e.getMessage());
  }
}


// old code for handling incoming physical button clicks via json

///** 
// * Handler for when JSON of a button click has been received
// */
//void onButtonDown() {
//  if (numClicks == 0 || millis() - lastClick < doubleClickThreshold) {
//    numClicks++;
//    lastClick = millis();
//  }
//}



///**
// * Helper to be called in each draw loop to check and detect clicks and double clicks
// */
//void checkClicks() {    
//  if (lastClick != 0 && millis() - lastClick  > doubleClickThreshold) {
//    log("--------");
//    log(numClicks + " detected");

//    // if we're currently recording, stop the recording
//    // don't care about single or double click at this point, because we just want
//    // to stop the current recording process
//    if (record == true) {
//      return;
//    }

//    //switch (numClicks) {
//    //case 1:
//    //  log("Single physical click");
//    //  break;

//    //case 2:
//    //  log("Double physical click");
//    //  break;

//    //default: 
//    //  log("Several physical clicks " + numClicks);
//    //  break;
//    //}
//    numClicks = 0;
//    lastClick = 0;
//  }
//}


void radioMode(int mode) {
  if (mode == 0) {
    log("disable second track recording");
    track1.enableRecordingUI();
    track2.disableRecordingUI();
  } else {
    log("enable second track recording");
    track1.enableRecordingUI();
    track2.enableRecordingUI();
  }

  recordingMode = mode;
}


void startRecording() {
  log("Kinemata.startRecording()");
  track1.startRecording();
  track2.startRecording();

  // TODO split by mode
}

void stopRecording() {
  log("Kinemata.stopRecording()");
  track1.stopRecording();
  track2.stopRecording();

  // TODO split by mode
}

void saveRecording() {
  log("Kinemata.saveRecording()");
  if (recordingMode == 0) {
    String filename = track1.getFilename();

    track1.saveData(filename + "-track-1");
    track2.saveData(filename + "-track-2");
  } else {
    //log(caller);

    // TODO save which
  }
}

void clearRecording() {
  log("Kinemata.clearRecording()");
  if (recordingMode == 0) {
    track1.clearRecording();
    track2.clearRecording();
  } else {
    //log(caller);

    // TODO save which
  }
}


/**
 * Helper to log messages on screen
 */
void log(String msg) {
  msg = msg + "\n\n" + debugText.getText();
  debugText.setText(msg);
}


/**
 * Showing and hiding UI overlays that cover the whole app
 */
void showOverlayBluetooth() {
  ArrayList<ControlP5> cp5s = new ArrayList<ControlP5>();
  cp5s.add(cp5);
  cp5s.add(track1.cp5);
  cp5s.add(track2.cp5);
  overlay = new Overlay(this, cp5s, "Connecting bluetooth");
  // immediately draw the overlay, before anything can timeout (i.e. BT connect)
  overlay.draw();
  redraw();
}

void hideOverlay() {
  overlay.hide();
  overlay = null;
}


/**
 * setup the UI components
 */
void setupUI() {

  cp5 = new ControlP5(this);

  radioMode = cp5.addRadioButton("radioMode")
    .setPosition(1060, 70)
    .setSize(40, 20)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setItemsPerRow(1)
    .addItem("Single recording", 0)
    .addItem("Separate recordings", 1)
    .setNoneSelectedAllowed(false)
    .activate(0);


  // file I/O check textarea
  debugText = cp5.addTextarea("txt")
    .setPosition(680, 10)
    .setSize(370, 130)
    .setFont(createFont("arial", 10))
    .setColor(0);
  //.setColorBackground(color(255, 100));
}

// unused reverse communication to device

//void sendBluetoothCommand(String command) {
//  if (connection != null) {
//    try {
//      //connection.write("roll:" + rotationX + ",heading:" + rotationY + ",pitch:" + rotationZ + ";");
//      connection.write("command:" + command + ";");
//      log("Sent bluetooth command to device: " + command);
//    }
//    catch (RuntimeException e) {
//      log("Cannot send command to Arduino; exception: " + e.getMessage());
//    }
//  } else {
//    log("Cannot send command to Arduino; no Bluetooth connection");
//  }
//}


/**
 * Helper function for passing updates to the slider checkboxes to the respective track
 * 
 * controlP5 pushes events to functions of the main sketch with the same name as the
 * cp5 element; there seems to be no way of catching this with a listener in the
 * track where the checkboxes are created, so this is a workaround
 * where a checkbox change event from any track will trigger this, and this function
 * in turn will trigger every tracks routine to check and update their checkboxes
 *
 * Clumsy :/
 */
void checkboxGraph(float[] a) {
  track1.checkboxEvent();
  track2.checkboxEvent();
}