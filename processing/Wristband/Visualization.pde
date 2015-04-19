import toxi.physics.*;
import toxi.physics.behaviors.*;
import toxi.physics.constraints.*;
import toxi.geom.*;

import processing.opengl.*;

import saito.objloader.*;

import java.awt.Color;



public class Visualization extends PApplet {

  private Color c;
  private Vec3D direction;

  private VerletPhysics physics;
  private GravityBehavior gravity;

  private OBJModel model;

  private ParticleConstraint boundingSphere;
  private ConstantForceBehavior pull;
  private AttractionBehavior attractor;

  private int numParticles = 5000;
  private int sphereConstraintRadius = 200;
  private ArrayList<Vec3D> pos = new ArrayList<Vec3D>();
  private int spawnPos = 0;

  public void setup() {
    size(width, height, OPENGL);
    background(0);
    noStroke();

    int gridSize = 50;
    int gridStep = 5;

    direction = new Vec3D(0, 0, 0);

    for (int stepX = 0; stepX < gridSize; stepX += gridStep) {
      for (int stepY = 0; stepY < gridSize; stepY += gridStep) {
        pos.add(new Vec3D(stepX, 0, stepY));
      }
    }

    initPhysics();

    ambientLight(216, 216, 216);
    directionalLight(255, 255, 255, 0, 1, 0);
    directionalLight(96, 96, 96, 1, 1, -1);


    // model = new OBJModel(this, "dma.obj", "absolute", TRIANGLES);
    // model.enableDebug();
    // model.scale(10);
    // model.translateToCenter();
  }


  public void draw() {
    background(15);

    pushMatrix();
    translate(width / 2, height * 0.5, 0);

    // float horizontal = (float)mouseX / width - 0.5;
    // float vertical = (float)mouseY / height - 0.5;

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

      //println(horizontal, vertical);

      // = new Vec3D(horizontal, vertical, 0);
      //direction.scale(5);
      pull.setForce(direction);

      physics.update();
      drawParticles();
    }
    popMatrix();

    // pushMatrix();
    // translate(width / 2, height * 0.5, 0);
    // stroke(0);    
    // rotateY(horizontal * -1);
    // rotateX(vertical);
    // rotateZ(0);
    // model.draw();    
    // popMatrix();
  }

  public void setColor(Color _c) {
    c = _c;
  }

  public void setDirection(Vec3D d) {
    direction = d;
  }

  public void keyPressed() {
    println(key);
  }

  public void initPhysics() {
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

  public void drawParticles() {
    for (int i = 0; i < physics.particles.size (); i++) {
      VerletParticle p = physics.particles.get(i);
      Vec3D position = p.getPreviousPosition();

      float ageFactor = 1 - i / numParticles;
      ageFactor *= 3;

      stroke(c.getRed() * ageFactor, c.getGreen() * ageFactor, c.getBlue() * ageFactor);

      point(position.x, position.y, position.z);
    }
  }

  public void generateParticle(int... num) {
    int numParticles = num.length > 0 ? num[0] : 1;
    for (int i = 0; i < numParticles; i++) {  
      VerletParticle p = new VerletParticle(pos.get(spawnPos));

      p.addConstraint(boundingSphere);
      physics.addParticle(p);
      spawnPos = spawnPos == pos.size() - 1 ? 0 : spawnPos + 1;
    }
  }

}


/**
 * The Frame wrapper that holds the visualization applet
 * The getVisualization() function returns the actual applet for manipulation form the main applet
 */
public class VisualizationFrame extends JFrame {
  
  private Visualization applet; // for calling functions of that applet

  public VisualizationFrame(int width, int height) {
    setBounds(100, 100, width, height);

    applet = new Visualization();
    add(applet);
    applet.init();
    show();
  }

  public Visualization getVisualization() {
    return applet;
  }
}
