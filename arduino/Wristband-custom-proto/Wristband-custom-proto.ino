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
#include <SFE_LSM9DS0.h>

// PWM module driver for leds
#include <Adafruit_PWMServoDriver.h>

// defined shortcuts for notes with common musical names
#include "pitches.h"


// 9 DOF setup
#define LSM9DS0_XM  0x1D // Would be 0x1E if SDO_XM is LOW
#define LSM9DS0_G   0x6B // Would be 0x6A if SDO_G is LOW
LSM9DS0 dof(MODE_I2C, LSM9DS0_G, LSM9DS0_XM);
#define PRINT_CALCULATED
#define PRINT_SPEED 500 // ms between prints?


// PWM setup
Adafruit_PWMServoDriver pwmR = Adafruit_PWMServoDriver(0x40);
Adafruit_PWMServoDriver pwmL = Adafruit_PWMServoDriver(0x41);

const int baudrate = 9600;

// PINS
const int onBoardLedPin = 6;
const int vibrationPin = 5;
const int buzzerPin = 11;
const int buttonPin = 12;

// Bluetooth connection pins and serial
const int rx = 7;
const int tx = 8;
SoftwareSerial mySerial(rx, tx);

int data[2];
int serialIndex = 0;

// desired fps rate between loops
// NOTE that this is in reality MUCH lower, ~4 fps
float fps = 12;
float msPerFrame = 1000 / fps; // ~83
  
int lastR = 0;
int lastG = 100;
int lastB = 200;

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


unsigned long noteStart = 0;
unsigned long noteEnd = 0;
int noteDuration = 0;


unsigned long vibrationStart = 0;



// custom pcb led channels for pwm library access
// led numbers 1-3 are right, top to bottom
// led numbers 4-6 are left, top to bottom
const int led1R = 14;
const int led1G = 15;
const int led1B = 13;

const int led2R = 3;
const int led2G = 4;
const int led2B = 2;

const int led3R = 6;
const int led3G = 7;
const int led3B = 5;

const int led4R = 4;
const int led4G = 5;
const int led4B = 3;

const int led5R = 14;
const int led5G = 15;
const int led5B = 13;

const int led6R = 9;
const int led6G = 8;
const int led6B = 10;


String test = "";

float lastHue = 0;
float lastSaturation = 0;
float lastBrightness = 1;

int rgbColor[3];
int lastVibration = 0;
// factor by which to reduce vibration values in cases where the new value is lower than the previous
// this speeds up "shuting" down the vibration to feel more responsive
float vibrationDecay = 0.75; 

int note = 0;
int lastNote = 0;
int lastNoteStarted = 0;

float changeBuffer[10];

unsigned long lastVibrationStart = 0;
unsigned long now;
unsigned long lastFrame;

/*
RGBConverter col = RGBConverter();
*/


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
String json;

int button = 0;



void setup ()
{
  Serial.begin(115200);
  Serial.println("hello serial");
  mySerial.begin(baudrate);

  uint16_t status = dof.begin();
  Serial.print("LSM9DS0 WHO_AM_I's returned: 0x");
  Serial.println(status, HEX);
  Serial.println("Should be 0x49D4");
  Serial.println();

  // adafruit pwm driver
  pwmR.begin();
  pwmR.setPWMFreq(1600);  // This is the maximum PWM frequency
  pwmL.begin();
  pwmL.setPWMFreq(1600);

  // save I2C bitrate
  uint8_t twbrbackup = TWBR;
  // must be changed after calling Wire.begin() (inside pwm.begin())
  TWBR = 12; // upgrade to 400KHz!

  // turn off on-board led
  analogWrite(onBoardLedPin, LOW);

  setRGBs(0, 0, 0);

  delay(500);

}


unsigned long lastSensorRead = 0;

void loop () {
  Serial.println("---");

  now = millis();
  
  if (button == 0) {
    button = digitalRead(buttonPin);
    if (button == 1) {
      sendButtonDown();
      button = 0;
    }
  }
  
  
  // read bluetooth commands in
  readBluetooth();
  

  Serial.print("Actual framerate: ");
  float actualFps = 1000 / (now - lastFrame);
  Serial.println(actualFps);

  // compensate to achieve a delay between frames as close as possible to the actual desired framerate
  float delayUntilNextFrame = min(max(0, msPerFrame - ((now - lastFrame) - msPerFrame)), msPerFrame);
  Serial.print("Delay until next frame: ");
  Serial.println(delayUntilNextFrame);

  lastFrame = now;
  delay(delayUntilNextFrame);
  
  if (lastSensorRead == 0 || now - lastSensorRead > 500) {
    Serial.println("SENSORS**********************");
    readSensors();
    lastSensorRead = now;
  }
  
  if (vibrationStart != 0 && now - vibrationStart > 1000 / fps / 2) {
    Serial.println("VIBRATION STOP~~~~");
    analogWrite(vibrationPin, 0);
    vibrationStart = 0;
  }
}


void readSensors ()
{  
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
  
  /*
  Serial.print("heading ");
  Serial.println(heading);
  Serial.print("pitch ");
  Serial.println(pitch);
  Serial.print("roll ");
  Serial.println(roll);
  */  

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

    /*
    Serial.print("maxAccel ");
    Serial.println(maxAccel[i]);

    Serial.print("maxGyro ");
    Serial.println(maxGyro[i]);

    Serial.print("maxMag ");
    Serial.println(maxMag[i]);
    */

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

  /*
  Serial.println("---");
  Serial.println(changeAccel[0]);
  Serial.println(changeAccel[1]);
  Serial.println(changeAccel[2]);
  Serial.println("---");
  Serial.println(changeGyro[0]);
  Serial.println(changeGyro[1]);
  Serial.println(changeGyro[2]);
  Serial.println("---");
  Serial.println(changeMag[0]);
  Serial.println(changeMag[1]);
  Serial.println(changeMag[2]);
  Serial.println("---");
  */

  /*
  Serial.println("Combined percentual acceleration change: ");
  Serial.println(combinedAccelerationChange);
  //Serial.println(absCombinedAccelerationChange);

  Serial.println("Combined percentual rotation change: ");
  Serial.println(combinedRotationChange);
  //Serial.println(absCombinedRotationChange);

  Serial.println("Combined percentual change: ");
  Serial.println(combinedChange);
  */

  // provide sensory feedback



  if (combinedChange > threshold) {
    
    /*
    // if lastVibrationStart has never occured yet
    if (lastVibrationStart <= 0) {
      lastVibrationStart = now;
    }

    int msSinceVibrationStart = now - lastVibrationStart;
    */
    int vibration = map(combinedChange, threshold, 100.0, 80, 255);

    /*
    if (vibration <= lastVibration + 15) {
      vibration *= vibrationDecay;
    }
    */
    
    /*
    Serial.print("vibration ");
    Serial.println(vibration);
    */
    
    analogWrite(vibrationPin, vibration);
    vibrationStart = now;
    /*
    lastVibrationStart = now;
    lastVibration = vibration;
    */
  } else {
    analogWrite(vibrationPin, 0);
    vibrationStart = 0;
  }

  /*
  for (int i = 0; i < 255; i = i + 10) {
    Serial.print("vibration ");
    Serial.println(i);
    analogWrite(vibrationPin, i);
    delay(500);
  }
  */  
  
  // leds
  
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
  /*
  Serial.print("hue: ");
  Serial.println(hue);
  */
  
  hue = round(hue * 6) / 6;
  /*
  Serial.print("hue rounded: ");
  Serial.println(hue);
  */
  
  H2R_HSBtoRGBfloat(hue, 1, 1, &rgbColor[0]);
  setRGBs(rgbColor[0], rgbColor[1], rgbColor[2]);
  /*
  Serial.print(rgbColor[0]);
  Serial.print(", ");
  Serial.print(rgbColor[1]);
  Serial.print(", ");
  Serial.println(rgbColor[2]);
  */


  String json = "{ \"heading\": " + String(heading) +
                ", \"pitch\": " + String(pitch) +
                ", \"roll\": " + String(roll) +
                ", \"aX\": " + String(accel[0]) +
                ", \"aY\": " + String(accel[1]) +
                ", \"aZ\": " + String(accel[2]) +
                ", \"gX\": " + String(gyro[0]) +
                ", \"gY\": " + String(gyro[1]) +
                ", \"gZ\": " + String(gyro[2]) +
//                ", mX: " + String(mag[0]) +
//                ", mY: " + String(mag[1]) +
//                ", mZ: " + String(mag[2]) +
                ", \"rgb\": \"" + 255 + "," + 255 + "," + 255 + "\"" +
                " };";

  // print to bluetooth connection and debug monitor
  mySerial.println(json);
  //Serial.println(json);

}

// relay button pressed status to client
void sendButtonDown() {
  String json = "{ buttonDown: 1 }";
  // print to bluetooth connection and debug monitor
  setRGBs(255, 0, 0);
  mySerial.println(json);
  Serial.println(json);
}


void readBluetooth() {
  
  // code for reading IN information from bluetooth
  // read in strings as one until the last ";", then split by colon ":"
  
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
    
    Serial.print("CommandString: ");
    Serial.println(bluetoothString);
    
    /*
    // expected string something like:
    // roll:12.0,heading:180.29,pitch:123.00;
    String roll = test.substring(0, test.indexOf(":"));
    String heading = test.substring(test.indexOf(":") + 1, test.indexOf("pitch") - 2);
    String pitch = test.substring(test.lastIndexOf(":" + 1));
    */
    
    String command = bluetoothString.substring(bluetoothString.indexOf(":") + 1, bluetoothString.indexOf(";") - 1);
    
    Serial.print("Command: ");
    Serial.println(command);
    
    int soundNumber = -1;
    
    if (command == "recordingStart") soundNumber = 0;
    if (command == "recordingEnd") soundNumber = 1;
    if (command == "recordingPerfect") soundNumber = 2;
    if (command == "recordingGood") soundNumber = 3;
    if (command == "recordingFail") soundNumber = 4;
    
    if (soundNumber != -1) {
      playSound(soundNumber);
    }
  } 
}
