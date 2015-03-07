// --------------------------------------
// i2c_scanner
//
// Version 1
//    This program (or code that looks like it)
//    can be found in many places.
//    For example on the Arduino.cc forum.
//    The original author is not know.
// Version 2, Juni 2012, Using Arduino 1.0.1
//     Adapted to be as simple as possible by Arduino.cc user Krodal
// Version 3, Feb 26  2013
//    V3 by louarnold
// Version 4, March 3, 2013, Using Arduino 1.0.3
//    by Arduino.cc user Krodal.
//    Changes by louarnold removed.
//    Scanning addresses changed from 0...127 to 1...119,
//    according to the i2c scanner by Nick Gammon
//    http://www.gammon.com.au/forum/?id=10896
// Version 5, March 28, 2013
//    As version 4, but address scans now to 127.
//    A sensor seems to use address 120.
// 
//
// This sketch tests the standard 7-bit addresses
// Devices with higher bit address might not be seen properly.
//

#include <Wire.h>


void setup()
{
  Wire.begin();

  Serial.begin(9600);
  Serial.println("\nI2C Scanner");
}


void loop()
{
  byte error, address;
  int nDevices;

  Serial.println("Scanning...");

  nDevices = 0;
  for(address = 1; address < 127; address++ ) 
  {
    // The i2c_scanner uses the return value of
    // the Write.endTransmisstion to see if
    // a device did acknowledge to the address.
    Wire.beginTransmission(address);
    /*
    error = Wire.endTransmission();
     byte, which indicates the status of the transmission:
     0: Successful send.
     1: Send buffer too large for the twi buffer. This should not happen, as the TWI buffer length set in twi.h is equivalent to the send buffer length set in Wire.h.
     2: Address was sent and a NACK received. This is an issue, and the master should send a STOP condition.
     3: Data was sent and a NACK received. This means the slave has no more to send. The master can send a STOP condition, or a repeated START.
     4: Another twi error took place (eg, the master lost bus arbitration).
     
     After every 8 data bits in one direction, an "acknowledge" bit is transmitted in the other direction.
     0 bit (ACK). 1 bit (NACK)
     */
    error = Wire.endTransmission();

    if (error == 0)
    {
      Serial.print("I2C device found at address 0x");
      if (address<16) 
        Serial.print("0");
      Serial.print(address,HEX);
      Serial.println("  !");

      nDevices++;
    }
    else if (error==4) 
    {
      Serial.print("Unknow error at address 0x");
      if (address<16) 
        Serial.print("0x");
      Serial.println(address,HEX);
    } 
    else {
//      Serial.print("0x");
//      Serial.print(address,HEX);
//      Serial.print(", error: ");
//      Serial.println(error);
    }   
  }
  if (nDevices == 0)
    Serial.println("No I2C devices found\n");
  else
    Serial.println("done\n");

  delay(5000);           // wait 5 seconds for next scan
}
