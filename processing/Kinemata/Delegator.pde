class Delegator {
  
  PApplet main;
  Track caller;
  
  Delegator(PApplet _main) {
    main = _main;
  }
  
  public void call(String method, Track _caller) {
    caller = _caller;
    main.method(method);
  }
  
  public Track getCaller() {
    Track _caller = caller;
    caller = null;
    return _caller;    
  }
}