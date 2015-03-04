/**
* TODO:
* recording motion changes
* writing motion files
* file opening and parsing
* cube 3d colored per side
* bluetooth connection establishing
*/
import org.json.*;
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


char[] inBuffer = new char[12];
int inBufferIndex = 0;
boolean isConnected = false;
int baudRate = 9600;
String initialCommand = "listening.";

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
    
  try {
    println(Serial.list());
    connection = new Serial(this, "/dev/tty.wristbandproto-SPP", 9600);
    char c = ';';
    println("limiter" + byte(c));
    connection.bufferUntil(byte(c));
  } catch (RuntimeException e) {
    println("error: " + e.getMessage());
    noLoop();
    exit();
  }
  
}


void draw() {
  background(255);
  stroke(0);  
  ColorCube c = new ColorCube(50.0, 10.0, 100.0, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255));
  c.setRotation(rotationX, rotationY, rotationZ);
  c.setPosition(winW / 2, winH / 2, 0);
  c.render();
}


void serialEvent(Serial port) {
  String s = connection.readString();
  s = s.substring(0, s.length() - 1);
  println("str " + s);
  if (s.indexOf("{") > -1) {  
    JSON obj = JSON.parse(s);    
    cp5.getController("rotationX").setValue(map(obj.getFloat("heading"), -180, 180, 0, 360));
    cp5.getController("rotationY").setValue(map(obj.getFloat("tilt"), -180, 180, 0, 360));
    cp5.getController("rotationZ").setValue(map(obj.getFloat("pitch"), -180, 180, 0, 360));
  }
}


