import processing.video.*;

class VideoWrapper {

    Movie feedbackMovie;
    boolean moviePlaying = false;
    boolean loopPlayback = false;
    PApplet applet;

    int x = 0;
    int y = 0;


    VideoWrapper (int _x, int _y, PApplet _applet) {
        x = _x;
        y = _y;
        applet = _applet;
    }


    /**
     * Play a feedback movie of given file name
     * @param String movieName: full file name of the .mov video inside the /data folder
     * Note: This will also stop playing any movie currently playing
     */
    void playFeedback(String movieName, boolean _loopPlayback) {
        log("playFeedback");
        feedbackMovie = new Movie(applet, movieName);
        loopPlayback = _loopPlayback;

        if (loopPlayback == true) {
            log("loop movie");
            feedbackMovie.loop();
        } else {
            log("play movie");
            feedbackMovie.play();
        }
        moviePlaying = true;
    }


    /**
     * Helper function to actually draw the current movie frame to the sketch
     */
    void drawMovie() {
        if (moviePlaying) {
            log("drawMovie");
            pushMatrix();

            //translate(guiRight - 10, guiTop + 10);
            //translate(x, y);

            // hardcoded size transformation for now, the files are 600x600
            scale(0.35);
            noFill();
            noStroke();

            fill(0);
            stroke(0);

            image(feedbackMovie, 0, 0, 600, 600);

            popMatrix();

            // stop playback only if not looping
            if (loopPlayback == false && feedbackMovie.time() >= feedbackMovie.duration()) {
                clearMovie();
            }
        }
    }


    void clearMovie() {
        moviePlaying = false;
        feedbackMovie = null;
    }


    /**
     * Called every time a new frame is available to read
     * This essentially updates what image(movie,...) will draw
     */
    void movieEvent(Movie m) {
        m.read();
    }

}