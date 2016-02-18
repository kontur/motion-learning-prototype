
import controlP5.*;

class Overlay {
  String message = "";
  PApplet parent;
  ArrayList<ControlP5> cps;
 
  Overlay (PApplet _parent, ArrayList<ControlP5> _cp, String _message) {
    message = _message;
    parent = _parent;
    cps = _cp;
  } 
  
  
  void draw() {
    for(ControlP5 cp5: cps){
      cp5.hide();
    }
    fill(0, 200);
    rect(0, 0, parent.width, parent.height);
    fill(255);
    textAlign(CENTER, CENTER);
    text(message, 300, 100, parent.width - 600, parent.height - 200);
  }  
  
  void hide() {
    for(ControlP5 cp5: cps){
      cp5.show();
    }
  }
  
}