import toxi.physics.*;
import toxi.physics.behaviors.*;
import toxi.physics.constraints.*;
import toxi.geom.*;
// import toxi.geom.mesh.*;
// import toxi.math.*;
// import toxi.volume.*;
// import toxi.physics2d.*;
// import toxi.physics2d.behaviors.*;
// import toxi.physics2d.constraints.*;

import processing.opengl.*;


int c;

VerletPhysics physics;
GravityBehavior gravity;
ParticleConstraint boundingSphere;
ConstantForceBehavior pull;

int numParticles = 500;

void setup() {
  size(600, 400, OPENGL);
  background(0);
  noStroke();
  initPhysics();

  ambientLight(216, 216, 216);
  directionalLight(255, 255, 255, 0, 1, 0);
  directionalLight(96, 96, 96, 1, 1, -1);
}


void draw() {
  background(255);

  pushMatrix();
  translate(width / 2, height * 0.5, 0);

  rotateX(50);
  rotateY(20);

  if (physics != null) {
    if (physics.particles.size() < numParticles) {
      generateParticle();
    } else {        
      physics.removeParticle(physics.particles.get(0));
    }
    
    Vec3D direction = pull.getForce();
    direction.jitter(0.05);
    
    pull.setForce(direction);
    println(direction);
    println(direction.magnitude());
    direction.limit(0.25);
  
    physics.update();
    drawParticles();
  }
  popMatrix();
}

void setColor(int _c) {
  c = _c;
}

void keyPressed() {
  println(key);
}

void initPhysics() {
  physics = new VerletPhysics();
  gravity = new GravityBehavior(new Vec3D(0, 0.1, 0));
  pull = new ConstantForceBehavior(new Vec3D(0.1, 0, 0.2));
  physics.addBehavior(gravity);
  physics.addBehavior(pull);
  boundingSphere = new SphereConstraint(new Sphere(new Vec3D(0, 0, 0), 100), SphereConstraint.INSIDE);
  
  for (int i = 0; i < numParticles; i++) {
    generateParticle();
  }
  
  physics.update();
}

void drawParticles() {
  for (VerletParticle p : physics.particles) {
    Vec3D position = p.getPreviousPosition();
    
    stroke(position.x, position.y, position.z);
    point(position.x, position.y, position.z);
  }
}

void generateParticle() {
  VerletParticle p = new VerletParticle(new Vec3D(0, 0, 0));
  p.addConstraint(boundingSphere);
  physics.addParticle(p);
}

