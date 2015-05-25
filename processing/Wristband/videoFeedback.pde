import processing.video.*;

Movie feedbackMovie;
boolean moviePlaying = false;


void playFeedback() {
  if (moviePlaying == false) {    
    feedbackMovie = new Movie(this, "amazing.mov");
    feedbackMovie.play();
    moviePlaying = true;
  }
}


void drawMovie() {
  if (moviePlaying) {
    pushMatrix();
    scale(0.5);
    image(feedbackMovie, 0, 0, 1920, 1080);
    popMatrix();
    if (feedbackMovie.time() >= feedbackMovie.duration()) {
      println("rewind");
      moviePlaying = false;
      feedbackMovie = null;
    }
  }
}


// Called every time a new frame is available to read
void movieEvent(Movie m) {
    m.read();
}