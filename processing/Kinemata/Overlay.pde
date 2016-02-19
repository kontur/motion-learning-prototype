
import controlP5.*;

class Overlay {
  String message = "";
  PApplet parent;
  ArrayList<ControlP5> cps;
  int frameCreated = 0;
  int frameRendered = 0;
 
  Overlay (PApplet _parent, ArrayList<ControlP5> _cp, String _message) {
    message = _message;
    parent = _parent;
    cps = _cp;
    frameCreated = frameCount;
    this.draw();
  } 
  
  
  void draw() {
    println("overlay.draw()");
    for(ControlP5 cp5: cps){
      cp5.hide();
    }
    fill(0, 200);
    rect(0, 0, parent.width, parent.height);
    fill(255);
    textAlign(CENTER, CENTER);
    text(message, 300, 100, parent.width - 600, parent.height - 200);
    frameRendered = frameCount;
  }  
  
  void hide() {
    for(ControlP5 cp5: cps){
      cp5.show();
    }
  }
  
  boolean hasRendered() {
    return frameRendered > frameCreated + 10;
  }
  
}