// interfacing libraries
#include <SPI.h>
#include <SoftwareSerial.h>
#include <Wire.h>

// math helpers
#include <math.h>

// variable size arrays with push and pop
#include <StackArray.h>

// convenient RGB HSL
#include <HSBColor.h>

// 9DoF driver
#include <SparkFunLSM9DS1.h>

// defined shortcuts for notes with common musical names
//#include "pitches.h"

// 9 DOF setup
LSM9DS1 dof;
#define LSM9DS1_M	0x1E // Would be 0x1C if SDO_M is LOW
#define LSM9DS1_AG	0x6B // Would be 0x6A if SDO_AG is LOW
#define PRINT_CALCULATED
#define PRINT_SPEED 50 // ms between prints?

// Earth's magnetic field varies by location. Add or subtract
// a declination to get a more accurate heading. Calculate
// your's here:
// http://www.ngdc.noaa.gov/geomag-web/#declination
#define DECLINATION 8.38 // E  ± 0° 26'  changing by  0° 9' E per year
//-8.58 // Declination (degrees) in Boulder, CO.


const int baudrate = 9600;

// PINS
const int vibrationPin = 5;
const int buzzerPin = 11;
const int buttonPin = 12;

const int redPin = 9;
const int greenPin = 6;
const int bluePin = 3;

// Bluetooth connection pins and serial
const int rx = 7;
const int tx = 8;
SoftwareSerial mySerial(rx, tx);

// tracking button pressed stated
int button = 0;
int lastButton = 0;


// variables for saving the previous frame's readings
int lastRoll = 0;
int lastHeading = 0;
int lastPitch = 0;
int lastRotation = 0;

// arrays holding the last sensor readings per axis
float lastAccel[3];
float lastGyro[3];
float lastMag[3];

// arrays holding the percentual change of sensor readings between loops
float changeAccel[3] = { 0, 0, 0 };
float changeGyro[3] = { 0, 0, 0 };
float changeMag[3] = { 0, 0, 0 };

// absolute upper peaks for each sensor value
// gets dynamically increased when new peaks are reached
// NOTE: these values are conservative estimates and intentionally low enough to dynamically
// get increased on use; this also means the device needs some "wild movement" calibration
// after startup
float maxAccel[3] = { 1, 1, 1 };
float maxGyro[3] = { 200, 200, 200 };
float maxMag[3] = { 0.25, 0.25, 0.25 };

float easing = 0.75; // 0 - 1 as factor of "last frame reading" impact on new reading


// rgb color array
int rgbColor[3];

int shades = 12;

unsigned long now;
unsigned long lastNow;
unsigned long lastButtonUp = 0;
unsigned long vibrationStart = 0;
unsigned long lastSensorRead = 0;

int framesSinceSensorRead = 0;

// in loop variables
// declared outside the loop and reused to save initialization every loop

// arrays holding the sensor readings
float accel[3];
float gyro[3];
float mag[3];

// variables holding the "calculated" IMU values (note, orientation is a helper to get pitch and roll)
float heading;
float orientation[2];
float pitch;
float roll;

// various combined changes in acceleration and rotation
float combinedAccelerationChange;
float absCombinedAccelerationChange;
float combinedRotationChange;
float absCombinedRotationChange;
float combinedChange;

float threshold = 2.5;

int vibration = 0;



void setup () {
  Serial.begin(9600);
  Serial.println("hello serial");


  //mySerial.begin(baudrate);

  mySerial.begin(115200);  // The mySerial Mate defaults to 115200bps
  mySerial.print("$");  // Print three times individually
  mySerial.print("$");
  mySerial.print("$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  mySerial.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  mySerial.begin(9600);  // Start bluetooth serial at 9600


  // Before initializing the IMU, there are a few settings
  // we may need to adjust. Use the settings struct to set
  // the device's communication mode and addresses:
  dof.settings.device.commInterface = IMU_MODE_I2C;
  dof.settings.device.mAddress = LSM9DS1_M;
  dof.settings.device.agAddress = LSM9DS1_AG;
  // The above lines will only take effect AFTER calling
  // imu.begin(), which verifies communication with the IMU
  // and turns it on.
  if (!dof.begin())
  {
    Serial.println("Failed to communicate with LSM9DS1.");
    Serial.println("Double-check wiring.");
    Serial.println("Default settings in this sketch will " \
                   "work for an out of the box LSM9DS1 " \
                   "Breakout, but may need to be modified " \
                   "if the board jumpers are.");
    while (1)
      ;
  }

  setRGB(250, 120, 0);

  // startup sound
  //playSound(5);
}


void loop () {
//  Serial.println("---");

  now = millis();

  // register button click if there are any
  // make sure not to register button clicks to "eagerly" so that a single press of the button
  // won't be registered as a double click

  //  button = digitalRead(buttonPin);
  //  if (button == 1 && lastButton == 0) {
  //    sendButtonDown();
  //  }
  //  lastButton = button;


  // read bluetooth commands from processing in
  //  readBluetooth();


  /*
  Serial.print("Actual frame delay since last frame: ");
  float actualFps = now - lastFrame;
  Serial.println(actualFps);
  */

  readSensors();
  lastSensorRead = now;
  framesSinceSensorRead = 0;
  setVibration();
  setLeds();
  sendJson();

  // stop vibration again
  // this 250 is arbitrary
  if (vibrationStart != 0 && now - vibrationStart > 250) {
    analogWrite(vibrationPin, 0);
    vibrationStart = 0;
  }
}


void readSensors () {

  // debug timing
//  Serial.print("1 - before sensor calls: ");
//  Serial.println(millis() - now);
//  lastNow = millis();


  getAccel(&accel[0]);
  getGyro(&gyro[0]);
  getMag(&mag[0]);
  getHeading(dof.mx, dof.my);
  getOrientation(
    dof.calcAccel(dof.ax),
    dof.calcAccel(dof.ay),
    dof.calcAccel(dof.az),
    &orientation[0]
  );
  pitch = orientation[0];
  roll = orientation[1];

  // debug timing
//  Serial.print("2 - after sensor calls: ");
//  Serial.println(millis() - lastNow);
//  lastNow = millis();

  /*
  // ease the readings for pitch, roll and heading to make them more smooth
  heading = lastHeading * easing + (1 - heading * easing);
  pitch = lastPitch * easing + (1 - pitch * easing);
  roll = lastRoll * easing + (1 - roll * easing);
  */

  // store current values for next round to compare
  lastHeading = heading;
  lastPitch = pitch;
  lastRoll = roll;

  //  Serial.print("heading ");
  //  Serial.println(heading);
  //  Serial.print("pitch ");
  //  Serial.println(pitch);
  //  Serial.print("roll ");
  //  Serial.println(roll);

  for (int i = 0; i < 3; i++) {
    // ease the new values to contain a portion of the previous value, thus making them less
    // fluctuating at the cost of being slightly less responsive
    accel[i] = lastAccel[i] * easing + (1 - accel[i] * easing);
    gyro[i] = lastGyro[i] * easing + (1 - gyro[i] * easing);
    mag[i] = lastMag[i] * easing + (1 - mag[i] * easing);


    // dynamically readjust edge values for all three sensor readings if the current new reading goes
    // beyond the current edge value
    // note abs() doesn't properly work with floats, so there is slightly less elegant code doing abs()
    // checks and saves
    if (accel[i] > 0 && accel[i] > maxAccel[i] ||
        accel[i] < 0 && accel[i] < -maxAccel[i]) {
      maxAccel[i] = accel[i] > 0 ? accel[i] : -accel[i];
    }
    if (gyro[i] > 0 && gyro[i] > maxGyro[i] ||
        gyro[i] < 0 && gyro[i] < -maxGyro[i]) {
      maxGyro[i] = gyro[i] > 0 ? gyro[i] : -gyro[i];
    }
    if (mag[i] > 0 && mag[i] > maxMag[i] ||
        mag[i] < 0 && mag[i] < -maxMag[i]) {
      maxMag[i] = mag[i] > 0 ? mag[i] : -mag[i];
    }

    // calculate the percentual change of the values to last values in regards to the maximum range
    // for that value
    // note that this can go beyond 100%, as a) the max value can increase, and for example the gyro
    // can flip from -200 to 200 degrees... TODO fix this somehow better than by mere easing applied
    // above
    changeAccel[i] = (accel[i] - lastAccel[i]) / maxAccel[i] * 100;
    changeGyro[i] = (gyro[i] - lastGyro[i]) / maxGyro[i] * 100;
    changeMag[i] = (mag[i] - lastMag[i]) / maxMag[i] * 100;

    // store current readings for next loop comparison
    lastAccel[i] = accel[i];
    lastGyro[i] = gyro[i];
    lastMag[i] = mag[i];
  }


  combinedAccelerationChange = changeAccel[0] + changeAccel[1] + changeAccel[2];
  combinedRotationChange = changeGyro[0] + changeGyro[1] + changeGyro[2];

  absCombinedAccelerationChange = combinedAccelerationChange > 0 ? combinedAccelerationChange : -combinedAccelerationChange;
  absCombinedRotationChange = combinedRotationChange > 0 ? combinedRotationChange : -combinedRotationChange;

  combinedChange = absCombinedAccelerationChange + absCombinedRotationChange;

}

void setVibration() {
  // provide vibraiton feedback
  // **************************

  // debug timing
//  Serial.print("3 - before vibration: ");
//  Serial.println(millis() - lastNow);
//  lastNow = millis();


  if (combinedChange > threshold) {
    vibration = map(constrain(combinedChange, 0, 100.0), threshold, 100.0, 100, 254);

    /*
    Serial.print("vibration ");
    Serial.println(vibration);
    */

    analogWrite(vibrationPin, vibration);
    vibrationStart = now;
  } else {
    analogWrite(vibrationPin, 0);
    vibrationStart = 0;
  }

  // debug timing
//  Serial.print("4 - after vibration: ");
//  Serial.println(millis() - lastNow);
//  lastNow = millis();

}

void setLeds() {

  // leds
  // ****

  // roll: 90 is all up, -90 all down / or reverse if put on the other way around ;)
  // pitch: 90 all left, 90 all right / or reverse on other hand ;)

  // the more the roll is away from 0 (-90 / 90), the less pitch should account for
  // the more the roll is close to 0 the more pitch should account for
  float rollFactor = map(roll, -90.0, 90.0, 0, 200) - 100; // -1.00 - 1.00 (* 100)
  float pitchFactor = map(pitch, -90.0, 90.0, 0, 100); // 0.00 - 1.00 (* 100)

  rollFactor = rollFactor / 100;
  pitchFactor = pitchFactor / 100;

  rollFactor = rollFactor > 0 ? rollFactor : -rollFactor;

  /*
  Serial.println(rollFactor);
  Serial.println(pitchFactor);
  */

  float hue = pitchFactor * (1 - rollFactor) + rollFactor;

  // round to the same x shades
  hue = round(hue * shades) / shades;

  H2R_HSBtoRGBfloat(hue, 1, 1, &rgbColor[0]);
  setRGB(rgbColor[0], rgbColor[1], rgbColor[2]);
}

void setRGB(int red, int green, int blue) {
  //  analogWrite(redPin, map(red, 0, 255, 0, 100));
  //  analogWrite(greenPin, map(green, 0, 255, 0, 100));
  //  analogWrite(bluePin, map(blue, 0, 255, 0, 100));
  analogWrite(redPin, red);
  analogWrite(greenPin, green);
  analogWrite(bluePin, blue);
}


void sendJson() {

  // The values are decoded one after the other and follow this pattern,
  // ORDER IS CRUCIAL !!!
  
  // NOTE: pitch and roll are reverse to reflect updated hardware with different
  // sensor orientation, i.e. on processing side roll -> pitch & pitch -> roll
  String json = "" + String(roll) +
                "," + String(pitch) +
                "," + String(vibration) +
                "," + String(accel[0]) +
                "," + String(accel[1]) +
                "," + String(accel[2]) +
                "," + String(gyro[0]) +
                "," + String(gyro[1]) +
                "," + String(gyro[2]) +
                //", \"rgb\": \"" + rgbColor[0] + "," + rgbColor[1] + "," + rgbColor[2] + "\"" +
                ";";

  // print to bluetooth connection and debug monitor

  // debug timing
//  Serial.print("6 - before BT send: ");
//  Serial.println(millis() - lastNow);
//  lastNow = millis();

  // note that I made the observation that if the json wasn't printed to the Serial, it didn't
  // print it to mySerial either... reasons?
  //  Serial.println("json");
  //  Serial.println(json);
  mySerial.println(json);


//  Serial.print("7 - after BT send: ");
//  Serial.println(millis() - lastNow);
//  lastNow = millis();
//
//  Serial.print("8 - since start: ");
//  Serial.println(millis() - now);

}


// relay button pressed status to client
void sendButtonDown() {
  String json = "{ buttonDown: 1 };";
  // print to bluetooth connection and debug monitor
  setRGB(255, 0, 0);
  mySerial.println(json);
  Serial.println(json);
  //playSound(6);
}

/*
void readBluetooth() {

  // code for reading IN information from bluetooth
  // read in strings as one until the last ";", then split by colon ":"
  Serial.println(mySerial.available());

  if (mySerial.available() > -1) {
    String bluetoothString = "";
    boolean rec = true;
    while (mySerial.available() && rec) {
      char b = mySerial.read();
      String s = String(b);
      if (s != ";") {
        bluetoothString = bluetoothString + s;
      }
      else {
        rec = false;
      }
    }

    /*
    // expected string something like:
    // roll:12.0,heading:180.29,pitch:123.00;
    String roll = test.substring(0, test.indexOf(":"));
    String heading = test.substring(test.indexOf(":") + 1, test.indexOf("pitch") - 2);
    String pitch = test.substring(test.lastIndexOf(":" + 1));
    *

    String command = bluetoothString.substring(bluetoothString.indexOf(":") + 1, bluetoothString.indexOf(";") - 1);

    Serial.print("Command: ");
    Serial.println(command);

    int soundNumber = -1;

    if (command == "recordingStart") soundNumber = 0;
    if (command == "recordingEnd") soundNumber = 1;
    if (command == "feedbackPerfect") soundNumber = 2;
    if (command == "feedbackGood") soundNumber = 3;
    if (command == "feedbackFail") soundNumber = 4;

    if (command == "bluetoothConnected") soundNumber = 7;
    if (command == "bluetoothDisconnected") soundNumber = 8;

    if (soundNumber != -1) {
      playSound(soundNumber);
    }
  }
}
*/
