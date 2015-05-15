#include "pitches.h";

int buzzerPin = 11;

void setup() {
  Serial.begin(9600);
}

void loop() {
  Serial.println("---");

  // start up?

  // recording start (including get ready sound)
  // recording stop

  // bluetooth pairing success
  // bluetooth pairing close

  // match feedback sounds
  // perfect:
  // alright:
  // try again:

  /*
  // recording start
  int notes[] = {
    NOTE_C5,
    0,
    NOTE_C5,
    0,
    NOTE_C5,
    0,
    NOTE_C6
  };

  int durations[] = {
    2,
    4,
    2,
    4,
    2,
    4,
    6
  };
  */

  /*
  // recording end
  int notes[] = {
    NOTE_C5,
    0,
    NOTE_C5,
    0,
    NOTE_C6
  };

  int durations[] = {
    1,
    0,
    1,
    2,
    4
  };
  */
  
  /*
  // perfect
  int notes[] = {
    NOTE_G4,
    0,
    NOTE_G4,
    0,
    NOTE_B4,
    0,
    NOTE_D5
  };
  
  int durations[] = {
    2,
    1,
    1,
    0,
    1,
    0,
    6
  };
  */
  
  
  
  /*
  // try again
  int notes[] = {
    NOTE_D5,
    0,
    NOTE_CS5,
    0,
    NOTE_C5,
    0,
    NOTE_B4
  };
  int durations[] = {
    2,
    1,
    2,
    1,
    2,
    1,
    6
  };
  */

  
  /*
  // alright
  int notes[] = {
    NOTE_G4,
    0,
    NOTE_G4,
    0,
    NOTE_B4,
    0,
    NOTE_A4
  };
  int durations[] = {
    2,
    1,
    1,
    0,
    1,
    0,
    6
  };
  */
  

  int notes[] = {};
  int durations[] = {};

  boolean play = false;
  
  if (play) {
    for (int i = 0; i < 7; i++) {
      if (notes[i] == 0) {
        delay(durations[i] * 100);
      } else {
        tone(buzzerPin, notes[i]);
      }
      delay(durations[i] * 100);
      noTone(11);
    }
  }

  delay(5000);

}
