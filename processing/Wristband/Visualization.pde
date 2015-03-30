import toxi.physics.*;
import toxi.physics.behaviors.*;
// import toxi.physics.constraints.*;
import toxi.geom.*;
// import toxi.geom.mesh.*;
// import toxi.math.*;
// import toxi.volume.*;


// import toxi.physics2d.*;
// import toxi.physics2d.behaviors.*;
// import toxi.physics2d.constraints.*;



public class Visualization extends PApplet {

  private int c;

  private VerletPhysics physics;
  GravityBehavior gravity;

  public void setup() {
    background(0);
    noStroke();
  }

  public void draw() {
    background(255);
    physics.update();
  }

  public void setColor(int _c) {
    c = _c;
  }

  public void keyPressed() {
    println(key);
  }

  private void initPhysics() {
    physics = new VerletPhysics();
    gravity = new GravityBehavior(new Vec3D(0, 1, 0));
    physics.addBehavior(gravity);

    for (int i = 0; i < 10; i++) {
      VerletParticle p = new VerletParticle(new Vec3D(10, 10, 10));
      physics.addParticle(p);
    }
    physics.update();
  }

}


/**
 * The Frame wrapper that holdes the visualization applet
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
