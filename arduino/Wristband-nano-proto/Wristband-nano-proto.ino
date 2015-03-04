#include <SPI.h>

#include <SFE_LSM9DS0.h>
#include <SoftwareSerial.h>
#include <Wire.h>


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
}



int last = 0;
int beat = 10;

void loop () 
{  
  
  // bluetooth test
  while (mySerial.available() > 0) {
    /*
    data[serialIndex] = mySerial.read();
    // '\n' is ASCII 10
    if (data[serialIndex] == '\n') {
      serialIndex = 0;
      if (data[0] == '?') {
        mySerial.println("listening.");
      }
      break;
    } else {
      mySerial.println("hello");
    }
    serialIndex = serialIndex + 1;*/
//    mySerial.println("hello");
  }
  mySerial.println("hello;");
  
  
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
  
  printOrientation(dof.calcAccel(dof.ax), dof.calcAccel(dof.ay), 
                   dof.calcAccel(dof.az), &orientation[0]);
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
  
//  Serial.print(map(accel[1] * 100, -100, 100, 40, 440));
  //tone(A0, map(accel[1] * 100, -100, 100, 40, 440), PRINT_SPEED / 2);//PRINT_SPEED / map(accel[0], -1, 1, 0.5, 2));
  //noTone(A0);
  
  //tone(A0, 330, PRINT_SPEED / 2);
  //delay(PRINT_SPEED / 2);
  //tone(A0, 440, PRINT_SPEED / 2);

  setRGB(
    map(orientation[0], -90, 90, 0, 255),
    map(orientation[1], -90, 90, 0, 255),
    0
  );
  
  
  float filter = 0.25;
  
  last = filter * last + (1 - filter) * orientation[0];
  
  Serial.println(orientation[0]);
  Serial.println(last);
  Serial.println(orientation[0] - last);
  
  // -90 - 90 [180]
  // 310 - 490
  int duration = map(abs(orientation[0] - last), 0, 20, 2, PRINT_SPEED);
  //tone(A0, 440, duration);
  //delay(duration);
  
  //tone(A0, last, PRINT_SPEED);
  last = last + 1;
  
  //setRGB(random(255), random(255), random(255));
  
  //delay(PRINT_SPEED);
//  delay(PRINT_SPEED);
  mySerial.println("{ heading: " + String(heading) + 
    ", pitch: " + String(orientation[0]) + 
    ", tilt: " + String(orientation[1]) + "};");
    
  delay(1000/12);
}




void setRGB (int r, int g, int b) 
{
  /*
  Serial.println("setRGB ");
  Serial.print(r);
  Serial.print(" ");
  Serial.print(g);
  Serial.print(" ");
  Serial.print(b);
  */
  analogWrite(pinLedR, r);
  analogWrite(pinLedG, g);
  analogWrite(pinLedB, b);
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

