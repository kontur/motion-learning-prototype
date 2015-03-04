import controlP5.*;

ControlP5 cp5;

float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;

float rotationMin = 0;
float rotationMax = 360;

int winW = 800;
int winH = 600;


void setup() {
  size(winW, winH, P3D);
  
  cp5 = new ControlP5(this);
  
  cp5.addSlider("rotationX")
    .setPosition(50, 50)
    .setRange(rotationMin, rotationMax);
   
  cp5.addSlider("rotationY")
    .setPosition(50, 70)
    .setRange(rotationMin, rotationMax);
   
  cp5.addSlider("rotationZ")
    .setPosition(50, 90)
    .setRange(rotationMin, rotationMax); 
}


void draw() {
  background(255);
  stroke(0);
  
  pushMatrix();
  translate(winW / 2, winH / 2);
  rotateX(radians(rotationX));
  rotateY(radians(rotationY));
  rotateZ(radians(rotationZ));
  box(50, 10, 100);
  popMatrix();
}





