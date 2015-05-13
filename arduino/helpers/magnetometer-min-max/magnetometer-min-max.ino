#include <SPI.h>

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_LSM9DS0.h>


// Create LSM9DS0 board instance.
Adafruit_LSM9DS0     lsm(1000);  // Use I2C, ID #1000

float AccelMinX, AccelMaxX;
float AccelMinY, AccelMaxY;
float AccelMinZ, AccelMaxZ;

float MagMinX, MagMaxX;
float MagMinY, MagMaxY;
float MagMinZ, MagMaxZ;

long lastDisplayTime;

void setup(void) 
{
  Serial.begin(9600);
  Serial.println("LSM303 Calibration"); Serial.println("");
  
  lastDisplayTime = millis();
  
  
  lsm.begin();
  
  // 1.) Set the accelerometer range
  lsm.setupAccel(lsm.LSM9DS0_ACCELRANGE_2G);
  //lsm.setupAccel(lsm.LSM9DS0_ACCELRANGE_4G);
  //lsm.setupAccel(lsm.LSM9DS0_ACCELRANGE_6G);
  //lsm.setupAccel(lsm.LSM9DS0_ACCELRANGE_8G);
  //lsm.setupAccel(lsm.LSM9DS0_ACCELRANGE_16G);
  
  // 2.) Set the magnetometer sensitivity
  lsm.setupMag(lsm.LSM9DS0_MAGGAIN_2GAUSS);
  //lsm.setupMag(lsm.LSM9DS0_MAGGAIN_4GAUSS);
  //lsm.setupMag(lsm.LSM9DS0_MAGGAIN_8GAUSS);
  //lsm.setupMag(lsm.LSM9DS0_MAGGAIN_12GAUSS);

}

void loop(void) 
{
  lsm.read();
  
  if (lsm.accelData.x < AccelMinX) AccelMinX = lsm.accelData.x;
  if (lsm.accelData.x > AccelMaxX) AccelMaxX = lsm.accelData.x;
  
  if (lsm.accelData.y < AccelMinY) AccelMinY = lsm.accelData.y;
  if (lsm.accelData.y > AccelMaxY) AccelMaxY = lsm.accelData.y;

  if (lsm.accelData.z < AccelMinZ) AccelMinZ = lsm.accelData.z;
  if (lsm.accelData.z > AccelMaxZ) AccelMaxZ = lsm.accelData.z;

  if (lsm.magData.x < MagMinX) MagMinX = lsm.magData.x;
  if (lsm.magData.x > MagMaxX) MagMaxX = lsm.magData.x;
  
  if (lsm.magData.y < MagMinY) MagMinY = lsm.magData.y;
  if (lsm.magData.y > MagMaxY) MagMaxY = lsm.magData.y;

  if (lsm.magData.z < MagMinZ) MagMinZ = lsm.magData.z;
  if (lsm.magData.z > MagMaxZ) MagMaxZ = lsm.magData.z;

  if ((millis() - lastDisplayTime) > 1000)  // display once/second
  {
    Serial.print("Accel Minimums: "); Serial.print(AccelMinX); Serial.print("  ");Serial.print(AccelMinY); Serial.print("  "); Serial.print(AccelMinZ); Serial.println();
    Serial.print("Accel Maximums: "); Serial.print(AccelMaxX); Serial.print("  ");Serial.print(AccelMaxY); Serial.print("  "); Serial.print(AccelMaxZ); Serial.println();
    Serial.print("Mag Minimums: "); Serial.print(MagMinX); Serial.print("  ");Serial.print(MagMinY); Serial.print("  "); Serial.print(MagMinZ); Serial.println();
    Serial.print("Mag Maximums: "); Serial.print(MagMaxX); Serial.print("  ");Serial.print(MagMaxY); Serial.print("  "); Serial.print(MagMaxZ); Serial.println(); Serial.println();
    lastDisplayTime = millis();
  }
  
  /*
  
Accel Minimums: -32760.00  -32760.00  -32760.00

Accel Maximums: 32760.00  32760.00  32760.00

Mag Minimums: -7393.00  -5526.00  -5509.00

Mag Maximums: 5386.00  6429.00  6481.00

*/
  
}
