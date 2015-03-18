import java.util.Vector;
import java.lang.RuntimeException;
import java.util.Arrays;

import javastat.multivariate.PCA;

class Similarity {

	Similarity() {
	}


	float compare(double[][] d1, double[][] d2) {

        // get the principal components of the multidimensional array of values (i.e. 9 dof x time)
        // for both sets of data to compare
		double[][] pcaA = getPCA(d1);
		println(pcaA.length, pcaA[0].length);

		double[][] pcaB = getPCA(d2);
		println(pcaB.length, pcaB[0].length);
		
		// create ArrayList multidimensional vectors and store as many principal components as found
		// from the two data sets both
		ArrayList<Float> vA = new ArrayList<Float>();
		ArrayList<Float> vB = new ArrayList<Float>();

		for (int i = 0; i < min(pcaA.length, pcaB.length); i++) {
			println("adding similarity principal component dimension " + i + " for comparison");
			vA.add(new Double(pcaA[i][0]).floatValue());
			vB.add(new Double(pcaB[i][0]).floatValue());
		}
		println("similarity between", vA, vB);

		float similarity = getCosineSimilarity(vA, vB);
		return similarity;
	}


	/**
	 * Cosine similarity implemented following explanations from:
	 * http://www.gettingcirrius.com/2010/12/calculating-similarity-part-1-cosine.html
	 *
	 * @return float similarity of multidimensional "vectors" a and b
	 */
	float getCosineSimilarity(ArrayList<Float> a, ArrayList<Float> b) {
		// Take the dot product of vectors A and B.
		// Calculate the magnitude of Vector A.
		// Calculate the magnitude of Vector B.
		// Multiple the magnitudes of A and B.
		// Divide the dot product of A and B by the product of the magnitudes of A and B.

		if (a.size() != b.size()) {
			throw new RuntimeException("Vector dimensions mismatch");
		}

		float dot = 0;
		float magnitudeA = 0;
		float magnitudeB = 0;
		for (int d = 0; d < a.size(); d++) {
			dot += a.get(d) * b.get(d);
			magnitudeA += (a.get(d) * a.get(d));
			magnitudeB += (b.get(d) * b.get(d));
		}

		magnitudeA = sqrt(magnitudeA);
		magnitudeB = sqrt(magnitudeB);
		float cosineSimilarity = dot / (magnitudeA * magnitudeB);
		
		return cosineSimilarity;
	}


	/**
	 * Wrapper for http://www2.thu.edu.tw/~wenwei/examples/javastat/PCA.htm
	 *
	 * @return double[][] multidimensional array of principal components
	 */
	double[][] getPCA(double values[][]) {
		// Non-null constructor 
		PCA pca = new PCA(0.95, "covariance", values); 
		double [] firstComponent = pca.principalComponents[0]; 
		for (double d : firstComponent) {
			println("Component", d);
		}
		// println("TEST1", firstComponent[0], firstComponent[1]);
		// println("TEST1", pca.principalComponents);

		return pca.principalComponents;
	}

}