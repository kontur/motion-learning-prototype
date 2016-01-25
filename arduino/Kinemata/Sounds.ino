
StackArray <int> notes;
StackArray <int> durations;

/*
 * Helper function to play sound feedback via the on board buzzer
 */
void playSound(int what)
{

  // just a precaution: make sure the stacks are empty
  while (!notes.isEmpty()) {
    notes.pop();
  }

  while (!durations.isEmpty()) {
    durations.pop();
  }

  switch (what) {
    //case "recordingStart":
    case 0:
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_C6);
      durations.push(2);
      durations.push(4);
      durations.push(2);
      durations.push(4);
      durations.push(2);
      durations.push(4);
      durations.push(6);
      break;

    //case "recordingEnd":
    case 1:
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_C6);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      durations.push(2);
      durations.push(4);
      break;

    //case "feedbackPerfect":
    case 2:
      notes.push(NOTE_G4);
      notes.push(0);
      notes.push(NOTE_G4);
      notes.push(0);
      notes.push(NOTE_B4);
      notes.push(0);
      notes.push(NOTE_D5);
      durations.push(2);
      durations.push(1);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      durations.push(0);
      durations.push(6);
      break;

    //case "feedbackGood":
    case 3:
      notes.push(NOTE_G4);
      notes.push(0);
      notes.push(NOTE_G4);
      notes.push(0);
      notes.push(NOTE_B4);
      notes.push(0);
      notes.push(NOTE_A4);
      durations.push(2);
      durations.push(1);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      durations.push(0);
      durations.push(6);
      break;

    //case "feedbackFail":
    case 4:
      notes.push(NOTE_D5);
      notes.push(0);
      notes.push(NOTE_CS5);
      notes.push(0);
      notes.push(NOTE_C5);
      notes.push(0);
      notes.push(NOTE_B4);
      durations.push(2);
      durations.push(1);
      durations.push(2);
      durations.push(1);
      durations.push(2);
      durations.push(1);
      durations.push(6);
      break;
      
    // device startup
    case 5:
      notes.push(NOTE_C4);
      notes.push(0);
      notes.push(NOTE_E4);
      notes.push(0);
      notes.push(NOTE_G4);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      durations.push(0);
      durations.push(4);
      break;
      
    // button push
    case 6:
      notes.push(NOTE_C3);
      durations.push(1);
      break;
      
    // bluetooth connected
    case 7:
      notes.push(NOTE_C4);
      notes.push(0);
      notes.push(NOTE_G4);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      break;
      
    // bluetooth disconnected
    case 8:
      notes.push(NOTE_G4);
      notes.push(0);
      notes.push(NOTE_C4);
      durations.push(1);
      durations.push(0);
      durations.push(1);
      break;

    default:
      break;
  }
  
  // reverse the order of notes to be able to play them in order of definition by
  // then popping them off from the top of the stack
  StackArray <int> notesReversed;
  StackArray <int> durationsReversed;
  while (!notes.isEmpty()) {
    notesReversed.push(notes.pop());
    durationsReversed.push(durations.pop());
  }

  // play the sequence of sounds by popping the items of the stacks
  while (!notesReversed.isEmpty()) {
    int note = notesReversed.pop();
    int duration = durationsReversed.pop();

    if (note == 0) {
      delay(duration * 100);
    } else {
      tone(buzzerPin, note);
    }
    delay(duration * 100);
    noTone(11);
  }
}
