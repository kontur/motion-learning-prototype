
public class Visualization extends PApplet {

  private int c;

  public void setup() {
    background(0);
    noStroke();
  }

  public void draw() {
    background(c);
    fill(255);
    ellipse(mouseX, mouseY, 10, 10);
  }

  public void setColor(int _c) {
    c = _c;
  }

  public void keyPressed() {
    println(key);
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
