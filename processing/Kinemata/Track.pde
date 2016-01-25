/**
 * Class wrapper for a single track with recording, graphing and visualization capabilities
 */
 class Track {

 	ColorCube cube;
 	Grapher graph;
 	JSONObject graphConfig;
 	JSONArray recording;

 	int x;
 	int y;

 	boolean isRecording = false;
 	boolean hasRecording = false;

 	int recordingIndex = 0;
 	int playbackIndex = 0;

 	int recordingLimit = 0;

 	String label = "";


 	/**
 	 * @param int _x: Position offset on x axis
 	 * @param int _y: Position offset on y axis
 	 * @param String label: TODO Text label
 	 */
 	Track(int _x, int _y, String _label) {
 		x = _x;
 		y = _y;
 		label = _label;
		
		graphConfig = JSONObject.parse("{ " + 
		    "\"resolutionX\": 1.00, \"resolutionY\": 400.00, " +
		    "\"roll\": { \"color\": " + color(255, 0, 0) + "}, " + 
		    "\"pitch\": { \"color\": " + color(0, 0, 255) + "}, "
		    + "}");

		graph = new Grapher(0, 30, 390, 200);
		graph.setConfiguration(graphConfig);

		cube = new ColorCube(100.0, 50.0, 10.0, cubeGrey, cubeGrey, cubeGrey);
		cube.setPosition(500.0, 130.0, 50.0);
 	}


 	void draw() {
 		pushMatrix();
 		translate(x, y);

 		fill(225);

 		if (isRecording == true) {
			stroke(205, 50, 20);
 		} else { 		
 			stroke(190);
 		} 		
 		rect(guiCenter, 30, 200, 200);	

		fill(25);
		stroke(190);
 		rect(guiRight, 30, 200, 200);

 		graph.plot();
 		cube.render();

 		popMatrix();
 	}


 	void startRecording() {
 		if (isRecording == false) {
 			println("startRecording");
 			recordingIndex = 0;
 			isRecording = true;
 			hasRecording = false;
 			graph.clear();
 			recording = new JSONArray();
 		}
 	}


 	/**
 	 * Recording the current frame into the internal store for later use
 	 *
 	 * @param JSONObject values: Json object containing all the values except id that
 	 *		will get recorded
 	 * @return boolean: Indicating if a new frame was recorded or not
 	 */
 	boolean record (JSONObject values) {
 		if (isRecording == true && (recordingLimit == 0 || recordingIndex < recordingLimit)) {
 			//println("record", recordingIndex, values);
        	values.setInt("id", recordingIndex);
        	recording.setJSONObject(recordingIndex, values);
	        recordingIndex++;
	        return true;
	    } else {
	    	return false;
	    }
 	}


 	void stopRecording() {
 		println("stopRecording");
 		isRecording = false;
 		hasRecording = true;
 		graph.clear();

 		// after the recording add it to the graph, but filter to include only
 		// those values we are wanting to displayed, not all that we recorded
 		JSONArray graphData = new JSONArray();
 		for (int i = 0; i < recording.size(); i++) {
 			JSONObject record = recording.getJSONObject(i);
 			JSONObject data = new JSONObject();
 			data.setFloat("pitch", record.getFloat("pitch"));
 			data.setFloat("roll", record.getFloat("roll"));
			graphData.setJSONObject(i, data);
 		}
 		graph.addDataArray(graphData);
 	}


 	void playRecording() {
 		if (hasRecording == true) {
 			playbackIndex = 0;
 		}
 	}


 	void clearRecording() {
 		hasRecording = false;
 		recordingLimit = 0;
 		recording = null;
 		graph.clear();
 	}


 	JSONArray getRecording() {
 		if (recording == null || recording.size() <= 0) {
 			return null;
 		}
 		return recording;
 	}


 	void playbackAt(int f) {
 		if (recording == null || recording.size() < f) {
 			log("Track.playbackAt(), not enough frames (recording.size(): " + recording.size() + ")");
 			return;
 		}

 		try {
	 		JSONObject frame = recording.getJSONObject(f);
	 		//println("playbackAt", frame);
	 		updateCube(map(frame.getFloat("pitch"), -90, 90, 0, 360), map(frame.getFloat("roll"), -90, 90, 0, 360), frame.getInt("rgb"), cubeGrey, cubeGrey);
	 	} catch (RuntimeException e) {
	 		log("Track.playbackAt(" + f + ") of " + label + " encountered error: " + e.getMessage());
	 	}
 	}


 	void updateCube(float rotationX, float rotationZ, int cFront, int cSide, int cTop) {
        cube.setRotation(rotationX, 0.0, rotationZ);
        cube.applyColor(cFront, cSide, cTop);
 	}


 	void addToGraph(JSONObject data) {
 		JSONObject d = new JSONObject();
 		d.setFloat("pitch", data.getFloat("pitch"));
 		d.setFloat("roll", data.getFloat("roll"));
 		graph.addData(d);
 	}


 	/**
 	 * Helper for getting the length (in frames) of the recording
 	 */
 	int getRecordingSize() {
 		if (hasRecording == false || recording == null) {
 			return -1;
 		}
 		return recording.size();
 	}


 	/**
 	 * Helper to automatically stop recording after x frames
 	 */
 	void setRecordingLimit(int limit) {
 		if (limit >= 0) {
	 		recordingLimit = limit;
	 	} else {
	 		recordingLimit = 0;
	 	}
 	}
}