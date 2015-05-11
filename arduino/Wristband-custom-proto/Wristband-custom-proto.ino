// interfacing libraries
#include <SPI.h>
#include <SoftwareSerial.h>
#include <Wire.h>

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

const int rx = 7;
const int tx = 8;
SoftwareSerial mySerial(rx, tx);

const int onBoardLedPin = 6;
const int vibrationPin = 5;
const int buzzerPin = 11;

int data[2];
int serialIndex = 0;

int lastR = 0;
int lastG = 100;
int lastB = 200;

int lastRoll = 0;
int lastHeading = 0;
int lastPitch = 0;
int lastRotation = 0;

float easing = 0.5; // 0 - 1 as factor of "last frame reading" impact on new reading


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

  /*
  // adafruit pwm driver
  pwmR.begin();
  pwmR.setPWMFreq(1600);  // This is the maximum PWM frequency
  pwmL.begin();
  pwmL.setPWMFreq(1600);
  */
  
  // save I2C bitrate
  uint8_t twbrbackup = TWBR;
  // must be changed after calling Wire.begin() (inside pwm.begin())
  TWBR = 12; // upgrade to 400KHz!

  analogWrite(onBoardLedPin, LOW);
  
  setRGBs(0, 0, 0);
  
  delay(500);

}

String test = "";

float lastHue = 0;
float lastSaturation = 0;
float lastBrightness = 1;

int rgbColor[3];
int lastVibration = 0;

int note = 0;
int lastNote = 0;
int lastNoteStarted = 0;

/*
RGBConverter col = RGBConverter();
*/

void loop ()
{

  // reading bluetooth
  // =================

  /*
  // code for reading IN information from bluetooth
  // this will be used for "playback" mode
  // read in strings as one until the last ";", then split by colon ":"
  if (mySerial.available() > -1) {
    test = "";
    boolean rec = true;
    while (mySerial.available() && rec) {
      char b = mySerial.read();
      String s = String(b);
      if (s != ";") {
        test = test + s;
      }
      else {
        rec = false;
      }
    }
    // expected string something like:
    // roll:12.0,heading:180.29,pitch:123.00;
    String roll = test.substring(0, test.indexOf(":"));
    String heading = test.substring(test.indexOf(":") + 1, test.indexOf("pitch") - 2);
    String pitch = test.substring(test.lastIndexOf(":" + 1));

    Serial.println(roll + " " + heading + " " + pitch);
  }
  */

  /*
  lastHeading = heading;
  lastPitch = pitch;
  lastRoll = roll;
  */

  float accel[3];
  float gyro[3];
  float mag[3];

  float heading;
  float orientation[2];
  float pitch;
  float roll;


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
  
  
  String p = "{ heading: " + String(heading) +
             ", pitch: " + String(pitch) +
             ", roll: " + String(roll) +
             ", accelX: " + String(accel[0]) +
             ", accelY: " + String(accel[1]) +
             ", accelZ: " + String(accel[2]) +
             ", gyroX: " + String(gyro[0]) +
             ", gyroY: " + String(gyro[1]) +
             ", gyroZ: " + String(gyro[2]) +
             ", magX: " + String(mag[0]) +
             ", magY: " + String(mag[1]) +
             ", magZ: " + String(mag[2]) +
             ", rgb: \"" + 255 + "," + 255 + "," + 255 + "\""
             " };";

  // print to bluetooth connection and debug monitor
  mySerial.println(p);
  Serial.println(p);
  
  delay(1000/12);
}



// helper to control LED colors combined
// @params red, green, blue: 0-255
void setRGBs(int red, int green, int blue)
{
  setRGB(1, red, green, blue);
  setRGB(2, red, green, blue);
  setRGB(3, red, green, blue);
  setRGB(4, red, green, blue);
  setRGB(5, red, green, blue);
  setRGB(6, red, green, blue);
}


void setRGBsL(int red, int green, int blue)
{
  setRGB(4, red, green, blue);
  setRGB(5, red, green, blue);
  setRGB(6, red, green, blue);  
}
void setRGBsR(int red, int green, int blue)
{
  setRGB(1, red, green, blue);
  setRGB(2, red, green, blue);
  setRGB(3, red, green, blue);  
}

// helper to control indivudual RGB LED colors
// @param led: 1-4
// @param red, green, blue: color components from 0-255
void setRGB (int led, int red, int green, int blue)
{
  int r;
  int g;
  int b;

  // convert rgb values to pwm cycle lengths
  red = map(red, 0, 255, 4096, 0);
  green = map(green, 0, 255, 4096, 0);
  blue = map(blue, 0, 255, 4096, 0);

  // store channels for each color
  switch (led) {
    case 1:
      r = led1R;
      g = led1G;
      b = led1B;
      break;

    case 2:
      r = led2R;
      g = led2G;
      b = led2B;
      break;

    case 3:
      r = led3R;
      g = led3G;
      b = led3B;
      break;

    case 4:
      r = led4R;
      g = led4G;
      b = led4B;
      break;

    case 5:
      r = led5R;
      g = led5G;
      b = led5B;
      break;

    case 6:
      r = led6R;
      g = led6G;
      b = led6B;
      break;
  }

  if (led <= 3) {
    pwmR.setPin(r, red);
    pwmR.setPin(g, green);
    pwmR.setPin(b, blue);
  } else { 
    pwmL.setPin(r, red);
    pwmL.setPin(g, green);
    pwmL.setPin(b, blue);
  }
}







// 9 DOF module helper functions
void getGyro(float *pdata)
{
  // To read from the gyroscope, you must first call the
  // readGyro() function. When this exits, it'll update the
  // gx, gy, and gz variables with the most current data.
  dof.readGyro();

  pdata[0] = dof.calcGyro(dof.gx);
  pdata[1] = dof.calcGyro(dof.gy);
  pdata[2] = dof.calcGyro(dof.gz);
}

void getAccel(float *pdata)
{
  // To read from the accelerometer, you must first call the
  // readAccel() function. When this exits, it'll update the
  // ax, ay, and az variables with the most current data.
  dof.readAccel();

  pdata[0] = dof.calcAccel(dof.ax);
  pdata[1] = dof.calcAccel(dof.ay);
  pdata[2] = dof.calcAccel(dof.az);
}

void getMag(float *pdata)
{
  // To read from the magnetometer, you must first call the
  // readMag() function. When this exits, it'll update the
  // mx, my, and mz variables with the most current data.
  dof.readMag();

  pdata[0] = dof.calcMag(dof.mx);
  pdata[1] = dof.calcMag(dof.my);
  pdata[2] = dof.calcMag(dof.mz);
}

// Here's a fun function to calculate your heading, using Earth's
// magnetic field.
// It only works if the sensor is flat (z-axis normal to Earth).
// Additionally, you may need to add or subtract a declination
// angle to get the heading normalized to your location.
// See: http://www.ngdc.noaa.gov/geomag/declination.shtml
float getHeading(float hx, float hy)
{
  float heading;

  if (hy > 0)
  {
    heading = 90 - (atan(hx / hy) * (180 / PI));
  }
  else if (hy < 0)
  {
    heading = - (atan(hx / hy) * (180 / PI));
  }
  else // hy = 0
  {
    if (hx < 0) heading = 180;
    else heading = 0;
  }

  //Serial.print("Heading: ");
  //Serial.println(heading, 2);

  // normalized for Helsinki, Finland
  // ?!?
  //heading = heading - 8;

  return heading;
}

// Another fun function that does calculations based on the
// acclerometer data. This function will print your LSM9DS0's
// orientation -- it's roll and pitch angles.
void getOrientation(float x, float y, float z, float *pdata)
{
  float pitch, roll;

  pitch = atan2(x, sqrt(y * y) + (z * z));
  roll = atan2(y, sqrt(x * x) + (z * z));
  pitch *= 180.0 / PI;
  roll *= 180.0 / PI;

  pdata[0] = pitch;
  pdata[1] = roll;
}










