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
import saito.objloader.*;

OBJModel model ;


int c;

VerletPhysics physics;
GravityBehavior gravity;
ParticleConstraint boundingSphere;
ConstantForceBehavior pull;
AttractionBehavior attractor;

int numParticles = 5000;
int sphereConstraintRadius = 200;

ArrayList<Vec3D> pos = new ArrayList<Vec3D>();
int spawnPos = 0;

void setup() {
  size(600, 400, OPENGL);
  background(0);
  noStroke();

  int gridSize = 50;
  int gridStep = 5;

  for (int stepX = 0; stepX < gridSize; stepX += gridStep) {
    for (int stepY = 0; stepY < gridSize; stepY += gridStep) {
      pos.add(new Vec3D(stepX, stepY, 0));
    }
  }

  initPhysics();

  ambientLight(216, 216, 216);
  directionalLight(255, 255, 255, 0, 1, 0);
  directionalLight(96, 96, 96, 1, 1, -1);



  model = new OBJModel(this, "dma.obj", "absolute", TRIANGLES);
  model.enableDebug();
  model.scale(10);
  model.translateToCenter();
}


void draw() {
  background(255);

  pushMatrix();
  translate(width / 2, height * 0.5, 0);

  float horizontal = (float)mouseX / width - 0.5;
  float vertical = (float)mouseY / height - 0.5;

  if (physics != null) {
    if (physics.particles.size() < numParticles) {
      generateParticle(pos.size());
    } else {
      while (physics.particles.size () >= numParticles) {
        physics.removeParticle(physics.particles.get(0));
      }
    }

    /*
    Vec3D direction = pull.getForce();
     direction.jitter(0.05);
     pull.setForce(direction);
     direction.limit(0.25);
     */

    println(horizontal, vertical);

    Vec3D direction = new Vec3D(horizontal, vertical, 0);
    direction.scale(5);
    pull.setForce(direction);

    physics.update();
    drawParticles();
  }
  popMatrix();

  pushMatrix();
  translate(width / 2, height * 0.5, 0);
  stroke(0);
  rotateY(horizontal * -1);
  rotateX(vertical);
  rotateZ(0);
  model.draw();
  
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
  attractor = new AttractionBehavior(new Vec3D(), 300, 0.25); 
  physics.addBehavior(gravity);
  physics.addBehavior(pull);
  physics.addBehavior(attractor);
  boundingSphere = new SphereConstraint(new Sphere(new Vec3D(0, 0, 0), sphereConstraintRadius), SphereConstraint.INSIDE);

  for (int i = 0; i < numParticles; i++) {
    generateParticle();
  }

  physics.update();
}

void drawParticles() {
  for (int i = 0; i < physics.particles.size (); i++) {
    VerletParticle p = physics.particles.get(i);
    Vec3D position = p.getPreviousPosition();

    float ageFactor = 1 - i / numParticles;
    ageFactor *= 3;

    stroke(position.x * ageFactor, position.y * ageFactor, position.z * ageFactor);

    point(position.x, position.y, position.z);
  }
}

void generateParticle(int... num) {
  int numParticles = num.length > 0 ? num[0] : 1;
  for (int i = 0; i < numParticles; i++) {  
    VerletParticle p = new VerletParticle(pos.get(spawnPos));

    p.addConstraint(boundingSphere);
    physics.addParticle(p);
    spawnPos = spawnPos == pos.size() - 1 ? 0 : spawnPos + 1;
  }
}

