#Motion learning
Prototype for wearable device enhancing motion based learning through sensory feedback.

The idea of this wearable device is to allow the wearer to rely on a multitude of additional sensory information when learning or repeating physical motion. This prototype is designed as a wrist-worn band that gives light, sound and vibration feedback.

Furthermore, the planned desktop interface allows users to record, compare and visualize their movement patterns.


##WIP
Codebase and physical design currently heavily WIP.


##Credits
Many parts of this project are based on open software or hardware. Arduino, Processing and Eagle have been used for the various aspects of the project. In more details:

* The led shield uses the [Adafruit PWM servo driver library](https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library)
* The Sparkfun IMU shields and their libraries [LSM9](https://github.com/sparkfun/LSM9DS0_Breakout) and [6DoF](https://github.com/sparkfun/IMU_Digital_Combo_Board)
* The project uses [this](http://bildr.org/2012/03/stable-orientation-digital-imu-6dof-arduino/) modification of [Varesano's FreeIMU](www.varesano.net/projects/hardware/FreeIMU) libraries for motion sensor reading
* [HSBColor](https://github.com/julioterra/HSB_Color) library for Arduino for color conversions
* [Toxiclibs](http://toxiclibs.org/) was used on the Processing visualization
* [controlP5](http://www.sojamo.de/libraries/controlP5/) was used in the Processing interface
* [Javastat](http://www2.thu.edu.tw/~wenwei/javastat/doc/) libraries were used for some portions in the software dealing with comparing motion patterns



###Authors
Johannes Neumeier, Jana Pejoska

###Acknowledgments
Project created in spring 2015 at Aalto Media Lab, in the course Prototyping Experience under guidance from Michihito Mizutani.
