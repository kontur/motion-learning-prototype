import processing.video.*;

Movie feedbackMovie;
boolean moviePlaying = false;


/**
 * Play a feedback movie of given file name
 * @param String movieName: full file name of the .mov video inside the /data folder
 * Note: This will also stop playing any movie currently playing
 */
void playFeedback(String movieName) {
  feedbackMovie = new Movie(this, movieName);
  feedbackMovie.play();
  moviePlaying = true;
}


/**
 * Helper function to actually draw the current movie frame to the sketch
 */
void drawMovie() {
  if (moviePlaying) {
    pushMatrix();
    translate(guiRight - 10, guiTop + 10);
    scale(0.4);
    image(feedbackMovie, 0, 0, 600, 600);
    popMatrix();

    if (feedbackMovie.time() >= feedbackMovie.duration()) {
      println("rewind");
      moviePlaying = false;
      feedbackMovie = null;
    }
  }
}


/**
 * Called every time a new frame is available to read
 * This essentially updates what image(movie,...) will draw
 */
void movieEvent(Movie m) {
    m.read();
}
