
import controlP5.*;

class Overlay {
  String message = "";
  PApplet parent;
  ArrayList<ControlP5> cps;
 
  Overlay (PApplet _parent, ArrayList<ControlP5> _cp, String _message) {
    println("new Overlay()");
    message = _message;
    parent = _parent;
    cps = _cp;
  } 
  
  
  void draw() {
    println("Overlay.draw()");
    for(ControlP5 cp5: cps){
      cp5.hide();
    }
    fill(0, 200);
    rect(0, 0, parent.width, parent.height);
    color(255);
    textAlign(CENTER);
    text(message, parent.width, parent.height);
  }  
  
  void hide() {
    println("Overlay.hide()");
    for(ControlP5 cp5: cps){
      cp5.show();
    }
  }
  
}