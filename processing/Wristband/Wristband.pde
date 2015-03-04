/**
* TODO:
* recording motion changes
* writing motion files
* file opening and parsing
* cube 3d colored per side
* bluetooth connection establishing
*/

import processing.serial.*;
import controlP5.*;

ControlP5 cp5;

float rotationX = 0;
float rotationY = 0;
float rotationZ = 0;

float rotationMin = 0;
float rotationMax = 360;

int winW = 800;
int winH = 600;

Serial connection;

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
    
    
  println(Serial.list());
  connection = new Serial(this, Serial.list()[0], 9600);
}


void draw() {
  background(255);
  stroke(0);
  
  /*
  pushMatrix();
  translate(winW / 2, winH / 2);
  rotateX(radians(rotationX));
  rotateY(radians(rotationY));
  rotateZ(radians(rotationZ));
  box(50, 10, 100);
  popMatrix();
  */
  
  ColorCube c = new ColorCube(50.0, 10.0, 100.0, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255));
  c.setRotation(rotationX, rotationY, rotationZ);
  c.setPosition(winW / 2, winH / 2, 0);
  c.render();
  
  while (connection.available() > 0) {
    int incoming = connection.read();
    println(incoming);
  }
  
  connection.write(65); // "A"
}



