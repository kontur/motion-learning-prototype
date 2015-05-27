#include <HSBColor.h>
#include <SPI.h>
#include <Wire.h>

// driver for the led pwm module
#include <Adafruit_PWMServoDriver.h>

/*
  Melody
 
 Plays a melody 
 
 circuit:
 * 8-ohm speaker on digital pin 8
 
 created 21 Jan 2010
 modified 30 Aug 2011
 by Tom Igoe 

This example code is in the public domain.
 
 http://arduino.cc/en/Tutorial/Tone
 
 */
 #include "pitches.h"

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

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
const int led3B = 6;

const int led4R = 4;
const int led4G = 5;
const int led4B = 3;
int lastR = 0;
int lastG = 100;
int lastB = 200;

// notes in the melody:
int melody[] = {
  NOTE_C4, NOTE_D4, NOTE_E4, NOTE_F4, NOTE_F4, NOTE_E4, NOTE_D4, NOTE_C4};
//int melody[] = {
  //40000, 20000,NOTE_G3, NOTE_A3, NOTE_G3,0, NOTE_DS8, NOTE_B0};

// note durations: 4 = quarter note, 8 = eighth note, etc.:
int noteDurations[] = {
  4, 8, 8, 12, 12, 8, 4, 2 
};

int vibrations[] = {
  0, 90, 125, 255, 255, 125, 90, 0
};

void setup() {
  
  
  
  
  
//  noTone(11);
}

void loop() {
  // no need to repeat the melody.
  
  
  // iterate over the notes of the melody:
  for (int thisNote = 0; thisNote < 8; thisNote++) {

    // to calculate the note duration, take one second 
    // divided by the note type.
    //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
    int noteDuration = 1000/noteDurations[thisNote];
    tone(11, melody[thisNote],noteDuration);

    setRGBs(255 - vibrations[thisNote], 0, vibrations[thisNote]);

    // to distinguish the notes, set a minimum time between them.
    // the note's duration + 30% seems to work well:
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes / 3);
    
    analogWrite(5, vibrations[thisNote]);
    
    delay(pauseBetweenNotes / 3 * 2);
    analogWrite(5, 0);
    
    // stop the tone playing:
    noTone(11);
  }
  setRGBs(0, 0, 0);
  delay(500);
  
  setRGBs(255, 0, 0);
  delay(50);
  setRGBs(0, 0, 0);
  delay(50);
  setRGBs(255, 0, 0);
  delay(50);
  setRGBs(0, 0, 0);
  delay(50);
  setRGBs(255, 0, 0);
  delay(50);
  setRGBs(0, 0, 0);
  delay(200000);
  
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

