/**
 * Helper for real-time graphing the data comming for the 9DoF sensor
 */

import java.util.Iterator;
import java.awt.Color;

class Grapher {

    JSONArray data = new JSONArray();
    float x = 0;
    float y = 0;
    float w = 200;
    float h = 100;
    int index = 0;

    float resolutionXDefault = 2;
    float position = 0;
    // resolutionY is more range, misleading terming to be fixed
    float resolutionYDefault = 400; // the max (and -min) extreme mapping on y

    JSONObject config;


    Grapher(float _x, float _y, float _w, float _h) {
        setPosition(_x, _y);
        setSize(_w, _h);
    }


    /**
     * helper to define drawing area size of the graph plot
     */
    void setSize(float _w, float _h) {
        w = _w;
        h = _h;
    }


    /**
     * helper to define the drawing position of the graph plot
     */
    void setPosition(float _x, float _y) {
        x = _x;
        y = _y;
    }


    void setConfiguration(JSONObject _config) {
        config = _config;
        if (config.hasKey("resolutionX") == false) {
            config.setFloat("resolutionX", resolutionXDefault);
        }
        if (config.hasKey("resolutionY") == false) {
            config.setFloat("resolutionY", resolutionYDefault);
        }
        //println("CONFIG \n" + config);
    }


    /**
     * add a new data set point
     */
    void addData(JSONObject dataObject) {
        // add to data
        data.append(dataObject);
        index++;
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
    * call in render loop or whenever to redraw the graph (on data change)
    */
    void plot() {

        // if at this point the configuration has not been provided, call
        // setConfiguration in order to initialize defaults
        if (config == null) {
            setConfiguration(new JSONObject());
        }

        fill(225);
        //noStroke();
        stroke(190);
        rect(x, y, w, h);

        float resX = config.getFloat("resolutionX");
        float resY = config.getFloat("resolutionY");

        // loop all data objects in range to be drawn
        // we get range by looking at resolutionX and width to determine how many fit
        // then take as many from the back of the data and plot them in

        // how many graph points should there be drawn along x
        int points = floor(w / resX);

        // counting from x to 0 (or as many data points as there are available in data)
        // in steps of 1
        int drawingStart = points > data.size() ? floor((points - data.size()) * resX) : 0;

        // data index to start drawing from
        int indexStart = points > data.size() ? 0 : data.size() - points;

        // get how many points there are to draw
        int pointsTotal = min(points, data.size());

        //println(pointsTotal);
        float lastY;

        for (int i = 0; i < pointsTotal; i++) {
            float point_x = i * resX;
            //println(point_x);
            JSONObject dataAtPoint = data.getJSONObject(indexStart + i);
            Iterator it = dataAtPoint.keyIterator();
            while (it.hasNext()) {
                Object k = it.next();
                try {
                    stroke(config.getJSONObject(k.toString()).getInt("color"));
                } catch (Exception e) {
                    stroke(125);
                }
                float _y = y + h / 2 - dataAtPoint.getFloat(k.toString()) / resY / 2 * 100;
                point(x + drawingStart + point_x, _y);
                //println("last y ", _y);

            }           
        }
    }


    /**
    * TODO export graph as image file
    */
    void export() {

    }

}
