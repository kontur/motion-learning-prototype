import processing.video.*;

Movie feedbackMovie;
boolean moviePlaying = false;


void playFeedback(String movieName) {
  if (moviePlaying == false) {    
    feedbackMovie = new Movie(this, movieName);
    feedbackMovie.play();
    moviePlaying = true;
  }
}


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


// Called every time a new frame is available to read
void movieEvent(Movie m) {
    m.read();
}