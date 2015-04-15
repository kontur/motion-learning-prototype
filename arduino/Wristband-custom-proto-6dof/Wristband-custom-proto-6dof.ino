#include <HSBColor.h>
#include <SPI.h>
#include <SFE_LSM9DS0.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <FreeSixIMU.h>
#include <FIMU_ADXL345.h>
#include <FIMU_ITG3200.h>


// called this way, it uses the default address 0x40
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);
// you can also call it with a different address you want
//Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x41);

const int baudrate = 9600;

const int rx = 7;
const int tx = 8;
SoftwareSerial mySerial(rx, tx);

const int onBoardLedPin = 6;

int data[2];
int serialIndex = 0;

int lastRotation = 0;

int lastR = 0;
int lastG = 100;
int lastB = 200;

int lastRoll = 0;
int lastHeading = 0;
int lastPitch = 0;

float easing = 0.5; // 0 - 1 as factor of "last frame reading" impact on new reading


float angles[3]; // yaw pitch roll

// Set the FreeSixIMU object
FreeSixIMU dof = FreeSixIMU();


/*
///////////////////////
// Example I2C Setup //
///////////////////////
// Comment out this section if you're using SPI
// SDO_XM and SDO_G are both grounded, so our addresses are:
#define LSM9DS0_XM  0x1D // Would be 0x1E if SDO_XM is LOW
#define LSM9DS0_G   0x6B // Would be 0x6A if SDO_G is LOW
// Create an instance of the LSM9DS0 library called `dof` the
// parameters for this constructor are:
// [SPI or I2C Mode declaration],[gyro I2C address],[xm I2C add.]
LSM9DS0 dof(MODE_I2C, LSM9DS0_G, LSM9DS0_XM);

// Do you want to print calculated values or raw ADC ticks read
// from the sensor? Comment out ONE of the two #defines below
// to pick:
#define PRINT_CALCULATED
//#define PRINT_RAW

#define PRINT_SPEED 500 // 500 ms between prints
*/


// custom pcb led channels for pwm library access
// led numbers with USB connector facing toward you, left top is 1, then clockwise
// note that with 4 leds a 3 channels not all 16 pwm channels are used
const int led1R = 14;
const int led1G = 15;
const int led1B = 13;

const int led2R = 10;
const int led2G = 11;
const int led2B = 9;

const int led3R = 7;
const int led3G = 8;
const int led3B = 9;

const int led4R = 4;
const int led4G = 5;
const int led4B = 3;


void setup ()
{
  Serial.begin(9600);
  Serial.println("hello serial");
  mySerial.begin(baudrate);

  Wire.begin();

  delay(5);
  dof.init(); //begin the IMU
  delay(5);

  /*
    uint16_t status = dof.begin();
    Serial.print("LSM9DS0 WHO_AM_I's returned: 0x");
    Serial.println(status, HEX);
    Serial.println("Should be 0x49D4");
    Serial.println();
  */


  // adafruit pwm driver
  pwm.begin();
  pwm.setPWMFreq(1600);  // This is the maximum PWM frequency
  // save I2C bitrate
  uint8_t twbrbackup = TWBR;
  // must be changed after calling Wire.begin() (inside pwm.begin())
  TWBR = 12; // upgrade to 400KHz!

  analogWrite(onBoardLedPin, LOW);

}

String test = "";

float lastHue = 0.25;
float lastSaturation = 0.75;
float lastBrightness = 1;

int rgbColor[3];

/*
RGBConverter col = RGBConverter();
*/

void loop ()
{
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


  // calculate new readings from sensor and ease them from last values
  dof.getYawPitchRoll(angles);

  float headingReading = angles[0];
  float pitchReading = angles[1];
  float rollReading = angles[2];

  float heading = lastHeading * easing + (1 - easing) * headingReading;
  //float pitch = lastPitch * easing + (1 - easing) * orientation[0];
  //float roll = lastRoll * easing + (1 - easing) * orientation[1];

  // these will range from -45 to 45
  float pitch = lastPitch * easing + (1 - easing) * pitchReading;
  float roll = lastRoll * easing + (1 - easing) * rollReading;

  String p = "{ heading: " + String(heading) +
             ", pitch: " + String(pitch) +
             ", roll: " + String(roll) + " };";

  // print to bluetooth connection and debug monitor
  mySerial.println(p);
  //Serial.println(p);

  /*
  // rgb color tests
  setRGB(1, random(255), random(255), random(255));
  setRGB(2, random(255), random(255), random(255));
  setRGB(3, random(255), random(255), random(255));
  setRGB(4, random(255), random(255), random(255));
  */

  lastHue = lastHue + 0.05;
  if (lastHue > 1) {
    lastHue = 0;
  }

  lastBrightness = lastBrightness + 0.1;
  if (lastBrightness > 255) {
    lastBrightness = 0;
  }


  H2R_HSBtoRGBfloat(lastHue, lastSaturation, lastBrightness, &rgbColor[0]);
  setRGB(1, rgbColor[0], rgbColor[1], rgbColor[2]);
  setRGB(3, rgbColor[0], rgbColor[1], rgbColor[2]);  
  setRGB(2, 0, 0, 0);
  setRGB(4, 0, 0, 0);
  Serial.println(rgbColor[0]);
  Serial.println(rgbColor[1]);
  Serial.println(rgbColor[2]);


  // interval at which to send and receive from bluetooth, 12fps
  delay(1000 / 12);
  //delay(2000);
}



// helper to control LED colors combined
// @params red, green, blue: 0-255
void setRGBs(int red, int green, int blue)
{
  setRGB(1, red, green, blue);
  setRGB(2, red, green, blue);
  setRGB(3, red, green, blue);
  setRGB(4, red, green, blue);
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

  Serial.println("setRGB " +  led);

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
  }

  pwm.setPin(r, red);
  pwm.setPin(g, green);
  pwm.setPin(b, blue);
}











