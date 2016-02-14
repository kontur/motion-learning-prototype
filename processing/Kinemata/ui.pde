/**
 * helper file for UI related stuff
 */


/**
 * setup the UI components
 */
void setupUI() {

  cp5 = new ControlP5(this);

  radioMode = cp5.addRadioButton("radioMode")
    .setPosition(1060, 100)
    .setSize(40, 20)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setItemsPerRow(1)
    .addItem("Single recording", 0)
    .addItem("Separate recordings", 1)
    .setNoneSelectedAllowed(false)
    .activate(0);


  // file I/O check textarea
  debugText = cp5.addTextarea("txt")
    .setPosition(guiLeft, guiBottom)
    .setSize(200, 200)
    .setFont(createFont("arial", 10))
    .setColor(0);
  //.setColorBackground(color(255, 100));

}