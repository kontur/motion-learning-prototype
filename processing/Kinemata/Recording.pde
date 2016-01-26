class Recording {

  JSONArray data = new JSONArray();
  int index = 0;
  int recordingLimit = -1;

  Recording() {
  }


  /**
   * add a new data set point
   */
  void addValue(JSONObject values) {
    //if (isRecording == true && (recordingLimit == 0 || index < recordingLimit)) {
    //println("record", index, values);
    values.setInt("id", index);
    data.setJSONObject(index, values);
    index++;
    return;
    //} else {
    //  return false;
    //}
  }


  /**
   * add a whole set of data points
   */
  void addValueArray(JSONArray dataArray) {
    // add all items to data
    for (int i = 0; i < dataArray.size(); i++) {
      data.append(dataArray.getJSONObject(i));
      index++;
    }
  }


  /**
   * clear the current graph values
   */
  void clear() {
    data = new JSONArray();
    index = 0;
  }


  /**
   * Helper for getting the length (in frames) of the recording
   */
  int getSize() {
    return data.size();
  }

  void reset() {
  }
  void getJson() {
  }
  void getCsv() {
  }

}