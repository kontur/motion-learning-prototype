
import java.util.Iterator;
import java.io.FileNotFoundException;

class Recording {

  JSONArray data = new JSONArray();
  int index = 0;
  int recordingLimit = -1;

  Recording() {
  }


  /**
   * add a new data set point
   */
  void addData(JSONObject values) {
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
  void addDataArray(JSONArray dataArray) {
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

  void saveData(String fileName, String[] headers) {
    println("Recording.saveData()", fileName);
    int dataLength = data.size();
    if (dataLength > 0) {
      PrintWriter file = createWriter("recordings/" + fileName + ".csv");
      
      for (int h = 0; h < headers.length; h++) {
        file.print(headers[h] + ",");        
      }
      file.println("");

      for (int i = 0; i < dataLength; i++) {
        JSONObject row = data.getJSONObject(i);
        writeRow(file, row);
      }
      file.flush();
      file.close();
    }
  }

  void writeRow(PrintWriter file, JSONObject row) {
    for (Object key : row.keys()) {
      //based on you key types
      String keyStr = (String)key;
      Float keyVal = row.getFloat(keyStr);
      file.print(keyVal + ",");
    }
    file.println("");
  }
}