import processing.serial.*;
import java.util.Iterator;
import java.io.FileNotFoundException;

class Recording {

  JSONArray data = new JSONArray();
  int index = 0;
  int recordingLimit = -1;
  int duration = -1;
  int recordingStart = -1;
  boolean saved = false;
  boolean consecutiveDuplicatesAsEmptyRows = true;

  Recording() {
  }


  /**
   * add a new data set point
   */
  boolean addData(JSONObject values) {
    boolean newData = true;
    
    if (recordingStart == -1) {
      recordingStart = millis();
      duration = 0;
    } else {
      duration = millis() - recordingStart;
    }

    values.setInt("id", index);

    // if the flag (default) has been set to record consecutive frames with same data
    // as empty frames, we need to do a bit checking now
    if (consecutiveDuplicatesAsEmptyRows && index > 0) {
      JSONObject lastData = new JSONObject();
      boolean same = true;
      
      // first, get a comparison frame with data, so
      // until we hit the first frame or a non-empty frame, go backwards
      for (int i = index - 1; i > 1; i--) {
        lastData = data.getJSONObject(i);
        if (lastData.keys().size() > 2) {
          break;
        }
      }

      // if we now have indeed found an immediate previous non-empty record, compare it
      // if none could be found, we infer that they are "same"
      // NOTE: There always is a first frame recorded, because of the index > 0 check above
      
      // check that the lastData has more than one key (i.e. it's not just "id", and everything
      // else is empty
      if (lastData.keys().size() > 1) {
        
        // iterate all keys, and compare each key from the previous and the current frame
        // if even just one key-value is different, we have a different frame and break from
        // this looping of keys
        for (Object key : lastData.keys()) {
          String keyStr = (String)key;
          float keyvalue = lastData.getFloat(keyStr);
          
          // obviously exclude the "id" key from this check, as they will always differ
          if (keyStr != "id" && (lastData.getFloat(keyStr) != values.getFloat(keyStr))) {
            same = false;
            break;
          }
        }

        // if the frames were indeed the same, just shove an empty JSONObject into the JSONArray
        if (same) {
          values = new JSONObject();
          values.setInt("id", index);
          newData = false;
        }
      }
    }

    data.setJSONObject(index, values);
    index++;
    
    // return if we recorded this data as a new frame or not
    return newData;
  }


  /**
   * add a whole set of data points
   * NOTE: no checks here for consecutiveDuplicatesAsEmptyRows
   */
  void addDataArray(JSONArray dataArray) {
    if (recordingStart == -1) {
      recordingStart = millis();
      duration = 0;
    } else {
      duration = millis() - recordingStart;
    }

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
    saved = false;
    duration = -1;
    recordingStart = -1;
  }


  /**
   * Helper for getting the length (in frames) of the recording
   */
  int getSize() {
    return data.size();
  }

  boolean saveData(String fileName, String[] headers) {
    try {
      int dataLength = data.size();
      if (dataLength > 0) {
        String datetime = "" + year() + "-" + month() + "-" + day() + "_" + hour() + "-" +
          minute() + "-" + second();
        PrintWriter file = createWriter("recordings/kinemata-" + datetime + "-" + fileName + ".csv");

        // start of by printing the headers into the first row so we know what data columns there are
        for (int h = 0; h < headers.length; h++) {
          file.print(headers[h] + ",");
        }
        file.println("");

        for (int i = 0; i < dataLength; i++) {
          JSONObject row = data.getJSONObject(i);
          writeRow(file, row, headers);
        }
        file.flush();
        file.close();
      }
      saved = true;
    } 
    catch (RuntimeException e) {
      log("Error trying to save: " + e.getMessage());
      return false;
    }

    return true;
  }

  void writeRow(PrintWriter file, JSONObject row, String[] headers) {
    //println("writeRow", row == null, row);

    for (int i = 0; i < headers.length; i++) {
      //println("hasKey?", row.hasKey(headers[i]));

      //println("null?", row.isNull(headers[i]));
      if (row.hasKey(headers[i]) && !row.isNull(headers[i])) {
        float keyVal = row.getFloat(headers[i]);
        file.print(keyVal + ",");
      } else {
        file.print(",");
      }
    }
    file.println("");
  }

  int getDuration() {
    return duration;
  }
}