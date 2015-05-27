
// custom pcb led channels for pwm library access
// led numbers 1-3 are right, top to bottom
// led numbers 4-6 are left, top to bottom
const int led1R = 14;
const int led1G = 15;
const int led1B = 13;

const int led2R = 3;
const int led2G = 4;
const int led2B = 2;

const int led3R = 6;
const int led3G = 7;
const int led3B = 5;

const int led4R = 4;
const int led4G = 5;
const int led4B = 3;

const int led5R = 14;
const int led5G = 15;
const int led5B = 13;

const int led6R = 9;
const int led6G = 8;
const int led6B = 10;


// helper to control LED colors combined
// @params red, green, blue: 0-255
void setRGBs(int red, int green, int blue)
{
  setRGB(1, red, green, blue);
  setRGB(2, red, green, blue);
  setRGB(3, red, green, blue);
  setRGB(4, red, green, blue);
  setRGB(5, red, green, blue);
  setRGB(6, red, green, blue);
}


void setRGBsL(int red, int green, int blue)
{
  setRGB(4, red, green, blue);
  setRGB(5, red, green, blue);
  setRGB(6, red, green, blue);
}
void setRGBsR(int red, int green, int blue)
{
  setRGB(1, red, green, blue);
  setRGB(2, red, green, blue);
  setRGB(3, red, green, blue);
}

// helper to control indivudual RGB LED colors
// @param led: 1-4
// @param red, green, blue: color components from 0-255
void setRGB (int led, int red, int green, int blue)
{
  int r;
  int g;
  int b;

  // convert rgb values to pwm cycle lengths
  red = map(red, 0, 255, 4096, 0);
  green = map(green, 0, 255, 4096, 0);
  blue = map(blue, 0, 255, 4096, 0);

  // store channels for each color
  switch (led) {
    case 1:
      r = led1R;
      g = led1G;
      b = led1B;
      break;

    case 2:
      r = led2R;
      g = led2G;
      b = led2B;
      break;

    case 3:
      r = led3R;
      g = led3G;
      b = led3B;
      break;

    case 4:
      r = led4R;
      g = led4G;
      b = led4B;
      break;

    case 5:
      r = led5R;
      g = led5G;
      b = led5B;
      break;

    case 6:
      r = led6R;
      g = led6G;
      b = led6B;
      break;
  }

  if (led <= 3) {
    pwmR.setPin(r, red);
    pwmR.setPin(g, green);
    pwmR.setPin(b, blue);
  } else {
    pwmL.setPin(r, red);
    pwmL.setPin(g, green);
    pwmL.setPin(b, blue);
  }
}

