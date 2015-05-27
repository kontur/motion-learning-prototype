/**
 * Helper for playing the videos
 *
 * Tried making this a class and passing in the PApplet for the new Movie(this...) call
 * but somehow the whole video only rendered only white any more... probably something
 * to do with graphics / alpha layering... so for now, just this ugly global solution
 */
import processing.video.*;


Movie feedbackMovie;
boolean moviePlaying = false;
boolean loopPlayback = false;

int x = 0;
int y = 0;


/**
 * Play a feedback movie of given file name
 * @param String movieName: full file name of the .mov video inside the /data folder
 * Note: This will also stop playing any movie currently playing
 */
void playFeedback(String movieName, int _x, int _y, boolean _loopPlayback) {
    log("playFeedback");
    feedbackMovie = new Movie(this, movieName);
    loopPlayback = _loopPlayback;
    x = _x;
    y = _y;

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
        pushMatrix();

        //translate(guiRight - 10, guiTop + 10);
        translate(x, y);

        // hardcoded size transformation for now, the files are 600x600
        scale(0.35);
        
        image(feedbackMovie, 0, 0, 600, 600);

        popMatrix();

        // stop playback only if not looping
        if (loopPlayback == false && feedbackMovie.time() >= feedbackMovie.duration()) {
            stopMovie();
        }
    }
}


void stopMovie() {
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

