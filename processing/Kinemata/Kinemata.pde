import processing.opengl.*;
import controlP5.*;
import java.lang.RuntimeException;
import java.lang.ArrayIndexOutOfBoundsException;
import java.awt.Color;
import javax.swing.*; 



// null Overlay; when instantiated rendered on top
Overlay overlay;

// A single instance object (static, hello) through which 
// any instances can route calls to this main sketch code
// the delegator has a function to return this last caller
// and thus makes it possible to identify the caller from
// the code here in the main sketch function
// NOTE: This is to workaround the fact that you cannot 
// call this main sketch class because it extends
// PApplet under the hood, but doesn't provide a class for
// it to pass to other objects
Delegator delegator;

// wait for uiReady before processing any kind of UI events
// otherwise there will be ControlP5-mayhem
boolean uiReady = false;

// UI elements and helpers on the top level
// NOTE: Each Track() instance has it's own controls
ControlP5 cp5;
Textarea debugText;
int recordingMode = 0;
RadioButton radioMode;

//int lastClick = 0;
//int numClicks = 0;
//int doubleClickThreshold = 1000;

PImage logo;

// The UI and functionality of each device track, here only
// two, but in theory infinite
Track track1;
Track track2;



/**
 * The main processing entry point
 * Set everything up here
 */
void setup() {
  // setup the main UI and rendering
  size(1280, 600, OPENGL);
  setupUI();
  
  // setup tracks and method delegation (clumsy)
  delegator = new Delegator(this);
  
  track1 = new Track(this, delegator, 10, 150, "First device");
  track2 = new Track(this, delegator, 10, 400, "Second device");

  // set to single recording by default
  radioMode(0);

  // render this fast, independent of recording and bluetooth
  // transmission rate (which we set separately
  frameRate(60);

  // get the header image
  logo = loadImage("kinemata.png");

  uiReady = true;
}


/**
 * The main draw loop, running at 60FPS
 * Delegate drawing and updating of components here
 */
void draw() {
  // basic window refresh
  background(221);
  stroke(0);
  image(logo, 10, 10);

  //checkClicks();
  //executeDelayedCommand();

  // update each track in turn
  track1.draw();
  track2.draw();

  // if there is a overlay, render it
  if (overlay != null) {
    overlay.draw();
  }
}


/**
 * Catch all serial communication and parse what came in
 * Then separate the actions by checking against each Track's
 * connection if this is where it came from
 * Somewhat not ideal delegation here again through the main
 * Processing sketch, but that how it runs
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
        // THEN: further reduce by removing alphanumericals and "{}"
        // so the string that actually comes in is a list of floats, separated by
        // commas, ending with a semicolon, like this:
        // "13.7,3.9,45,3.7,3.9,5.6,6.5,17.6,4.0;"
        // NOTE: the order of the floats is analog to the order they are sent from
        // Arduino, and this is the order:
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

        // now that we shaped our comma list into a JSON string, parse it for
        // more convenient handling and access
        JSONObject obj = JSONObject.parse(combined.toString());

        // check which track the incoming serialEvent belongs to and 
        // forward the parsed data
        if (connection == track1.connection) {
          track1.process(obj);
        } else if (connection == track2.connection) {
          track2.process(obj);
        }
      } else {
        log("Error reading bluetooth: Received bluetooth string, but not a valid string (Number of commas not matching)");
      }
    }
  }
  catch (RuntimeException e) {
    log("Error reading bluetooth: " + e.getMessage());
  }
}


/**
 * UI listener called when the radio button for switching between
 * single track recording and two track recording is clicked
 */
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
  if (recordingMode == 0) {
    track1.startRecording();
    track2.startRecording();
  } else {
  // TODO split by mode
    
  }
}

void stopRecording() {
  log("Kinemata.stopRecording()");
  if (recordingMode == 0) {
    track1.stopRecording();
    track2.stopRecording();
  } else {
  // TODO split by mode
  
  }
}

void saveRecording() {
  log("Kinemata.saveRecording()");
  if (recordingMode == 0) {
    String filename = track1.getFilename();

    track1.saveData(filename + "-track-1");
    track2.saveData(filename + "-track-2");
  } else {
    // TODO save which
    
  }
}

void clearRecording() {
  log("Kinemata.clearRecording()");
  if (recordingMode == 0) {
    track1.clearRecording();
    track2.clearRecording();
  } else {
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
  // gather all ControlP5 instances into an ArrayList, so that Overlay can
  // controll (i.e. hide) them
  ArrayList<ControlP5> cp5s = new ArrayList<ControlP5>();
  cp5s.add(cp5);
  cp5s.add(track1.cp5);
  cp5s.add(track2.cp5);
  
  overlay = new Overlay(this, cp5s, "Connecting bluetooth to device " + delegator.getCaller().port);
  
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

  // buttons for switching from saving both recordings at once 
  // to saving each separately 
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

  // debug textarea in the UI
  debugText = cp5.addTextarea("txt")
    .setPosition(680, 10)
    .setSize(370, 130)
    .setFont(createFont("arial", 10))
    .setColor(0);
}


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


/* BELOW: older code temporarily not in use, functions atm not used */

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