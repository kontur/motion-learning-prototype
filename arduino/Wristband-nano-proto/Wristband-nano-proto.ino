#include <SPI.h>

#include <SFE_LSM9DS0.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>


// called this way, it uses the default address 0x40
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();
// you can also call it with a different address you want
//Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x41);



const int baudrate = 9600;

const int rx = 8;
const int tx = 7;
SoftwareSerial mySerial(rx,tx);

int data[2];
int serialIndex = 0;


int pinLedR = 3;
int pinLedG = 5;
int pinLedB = 6;
//int pinBluetoothTx = 5;
//int pinBluetoothRx = 6;


int lastRotation = 0;

byte ledAddress = 0x40;
byte ledAddress2 = 0x70;

int lastR = 0;
int lastG = 100;
int lastB = 200;



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

void setup () 
{
  //Serial.begin(115200); // Start serial at 115200 bps

  //Serial.begin(baudrate);
  //Serial.println("listening.");
  mySerial.begin(baudrate);

  pinMode(pinLedR, OUTPUT);
  pinMode(pinLedG, OUTPUT);
  pinMode(pinLedB, OUTPUT);

  uint16_t status = dof.begin();
  /*
  Serial.print("LSM9DS0 WHO_AM_I's returned: 0x");
   Serial.println(status, HEX);
   Serial.println("Should be 0x49D4");
   Serial.println();
   */

  Serial.begin(9600);

  // adafruit pwm driver  
  pwm.begin();
  pwm.setPWMFreq(1600);  // This is the maximum PWM frequency

  // save I2C bitrate
  uint8_t twbrbackup = TWBR;
  // must be changed after calling Wire.begin() (inside pwm.begin())
  TWBR = 12; // upgrade to 400KHz!

}

void loop () 
{ 

  /*
  printGyro();  // Print "G: gx, gy, gz"
   printAccel(); // Print "A: ax, ay, az"
   printMag();   // Print "M: mx, my, mz"
   */

  float accel[3];

  dof.readGyro();
  dof.readAccel();
  dof.readMag();

  printAccel(&accel[0]);

  // Print the heading and orientation for fun!
  float heading = printHeading((float) dof.mx, (float) dof.my);
  float orientation[2];
  float pitch;
  float roll;

  printOrientation(
  dof.calcAccel(dof.ax), 
  dof.calcAccel(dof.ay), 
  dof.calcAccel(dof.az), 
  &orientation[0]
    );
  pitch = orientation[0];
  roll = orientation[1];

  /*
  Serial.println();
   
   Serial.println(heading);
   Serial.println(orientation[0]);
   Serial.println(orientation[1]);
   
   
   Serial.println();
   Serial.print("accel ");
   Serial.print(accel[0]);
   Serial.print(" ");
   Serial.print(accel[1]);
   Serial.print(" ");
   Serial.print(accel[2]);
   Serial.print(" ");
   */

  /*
  int r = map(pitch, -90, 90, 0, 255);
   int g = map(roll, -90, 90, 0, 255);
   int b = map(heading, -180, 180, 0, 255);
   */

  lastR = lastR + 5;
  if (lastR > 255) {
    lastR = 0;
  }
  lastG = lastG + 5;
  if (lastG > 255) {
    lastG = 0;
  }
  lastB = lastB + 5;
  if (lastB > 255) {
    lastB = 0;
  }


  int r = lastR;
  int g = lastG;
  int b = lastB;



  Serial.println(String(r) + "," + String(g) + "," + String(b));

  setRGB(r, g, b);

  mySerial.println("{ heading: " + String(heading) + 
    ", pitch: " + String(pitch) + 
    ", roll: " + String(roll) + " };");

  delay(1000/12);
}


// helper to controll the LED colors
void setRGB (int r, int g, int b) 
{
  pwm.setPWM(0, 0, map(r, 0, 255, 4096, 0));
  pwm.setPWM(1, 0, map(g, 0, 255, 4096, 0));
  pwm.setPWM(2, 0, map(b, 0, 255, 4096, 0));
}


// 9 DOF module helper functions
void printGyro()
{
  // To read from the gyroscope, you must first call the
  // readGyro() function. When this exits, it'll update the
  // gx, gy, and gz variables with the most current data.
  dof.readGyro();

}

void printAccel(float *pdata)
{
  // To read from the accelerometer, you must first call the
  // readAccel() function. When this exits, it'll update the
  // ax, ay, and az variables with the most current data.
  dof.readAccel();


  pdata[0] = dof.calcAccel(dof.ax);
  pdata[1] = dof.calcAccel(dof.ay);
  pdata[2] = dof.calcAccel(dof.az);
}

void printMag()
{
  // To read from the magnetometer, you must first call the
  // readMag() function. When this exits, it'll update the
  // mx, my, and mz variables with the most current data.
  dof.readMag();

}

// Here's a fun function to calculate your heading, using Earth's
// magnetic field.
// It only works if the sensor is flat (z-axis normal to Earth).
// Additionally, you may need to add or subtract a declination
// angle to get the heading normalized to your location.
// See: http://www.ngdc.noaa.gov/geomag/declination.shtml
float printHeading(float hx, float hy)
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
  heading = heading - 8;

  return heading;
}

// Another fun function that does calculations based on the
// acclerometer data. This function will print your LSM9DS0's
// orientation -- it's roll and pitch angles.
void printOrientation(float x, float y, float z, float *pdata)
{
  float pitch, roll;

  pitch = atan2(x, sqrt(y * y) + (z * z));
  roll = atan2(y, sqrt(x * x) + (z * z));
  pitch *= 180.0 / PI;
  roll *= 180.0 / PI;

  pdata[0] = pitch;
  pdata[1] = roll;
}





