class Grapher {

	JSONArray data = new JSONArray();
	float x = 0;
	float y = 0;
	float w = 200;
	float h = 100;
	int index = 0;

	float resolution = 1;
	float position = 0;
	float scaleY = 400; // the max (and -min) extreme mapping on y


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
		fill(255);
		stroke(0);
		rect(x, y, w, h);

		// loop all data objects in range to be drawn
		// we get range by looking at resolution and width to determine how many fit
		// then take as many from the back of the data and plot them in

		int points = floor(w / resolution);

		// counting from x to 0 (or as many data points as there are available in data)
		// in steps of 1

		int drawingStart = points > data.size() ? points - data.size() : 0;
		int indexStart = points > data.size() ? 0 : data.size() - points;

		// 0 - 400 for 100 values draws 100 from 300 - 400
		// 0 - 400 for 500 values draws 400 from 0 - 400 starting with 100
		for (int i = 0; i < min(points, data.size()); i++) {
			// point x is w - i (* resolution?)
			float point_x = i * resolution;
			
			JSONObject dataAtPoint = data.getJSONObject(indexStart + i);

			point(x + drawingStart + point_x, y + h / 2 + dataAtPoint.getFloat("rotationX") / scaleY / 2 * 100);
		}

	}


	/**
	* TODO export graph as image file
	*/
	void export() {

	}

}
