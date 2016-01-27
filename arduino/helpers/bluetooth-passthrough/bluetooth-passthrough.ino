/*
  Example Bluetooth Serial Passthrough Sketch
 by: Jim Lindblom
 SparkFun Electronics
 date: February 26, 2013
 license: Public domain

 This example sketch converts an RN-42 bluetooth module to
 communicate at 9600 bps (from 115200), and passes any serial
 data between Serial Monitor and bluetooth module.
 */
#include <SoftwareSerial.h>  

int bluetoothTx = 7;  // TX-O pin of bluetooth mate, Arduino D2
int bluetoothRx = 8;  // RX-I pin of bluetooth mate, Arduino D3

SoftwareSerial bluetooth(bluetoothTx, bluetoothRx);

void setup()
{
  Serial.begin(9600);  // Begin the serial monitor at 9600bps

  bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
  bluetooth.print("$");  // Print three times individually
  bluetooth.print("$");
  bluetooth.print("$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  bluetooth.begin(9600);  // Start bluetooth serial at 9600
}

void loop()
{

    //bluetooth.print("{\"p\":13.7,\"r\":3.9,\"aX\":3.7,\"aY\":3.9,\"aZ\":5.6,\"gX\":6.5,\"gY\":17.6,\"gZ\":4.0};");
    bluetooth.print("{p13.7,r3.9,aX3.7,aY3.9,aZ5.6,gX6.5,gY17.6,gZ4.0};");
    
//  if(bluetooth.available())  // If the bluetooth sent any characters
//  {
//    // Send any characters the bluetooth prints to the serial monitor
//    Serial.print((char)bluetooth.read());
//  }
//  if(Serial.available())  // If stuff was typed in the serial monitor
//  {
//    // Send any characters the Serial monitor prints to the bluetooth
//    bluetooth.print((char)Serial.read());
//  }
//  bluetooth.print(millis());
//  // and loop forever and ever!
}

