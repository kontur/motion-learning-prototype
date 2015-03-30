import java.util.Vector;
import java.lang.RuntimeException;
import java.util.Arrays;

import javastat.multivariate.PCA;

class Similarity {

	Similarity() {
	}


	float compare(double[][] d1, double[][] d2) {

		// for (int a = 0; a < d1.length; a++) {
		// 	for (int b = 0; b < d1[a].length; b++) {
		// 		println("a", a, "b", b, d1[a][b]);
		// 	}
		// }

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

		for (int i = 0; i < min(pcaA[0].length, pcaB[0].length); i++) {
			println("adding similarity principal component dimension " + i + " for comparison");
			try {
				float a = new Double(pcaA[0][i]).floatValue();
				float b = new Double(pcaB[0][i]).floatValue();
				if (a != 0.0 && b != 0.0) {
					vA.add(a);
					vB.add(b);	
				}
			} catch (RuntimeException e) {
				println(e);
			}
		}
		println("similarity between", vA, vB, vA.size(), vB.size());

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

		int dimensions = a.size();

		if (a.size() != b.size()) {
			throw new RuntimeException("Vector dimensions mismatch");
		}

		float dot = 0;
		float magnitudeA = 0;
		float magnitudeB = 0;
		for (int d = 0; d < dimensions; d++) {
			// println("a", a.get(d), "a2", (a.get(d) * a.get(d)), "b", b.get(d), "b2", (b.get(d) * b.get(d)));
			
			dot += a.get(d) * b.get(d);

			magnitudeA += pow(a.get(d), 2);
			magnitudeB += pow(b.get(d), 2);
			println("magnitudeA", magnitudeA, "magnitudeB", magnitudeB);
		}

		magnitudeA = sqrt(magnitudeA);
		magnitudeB = sqrt(magnitudeB);
		println("dot", dot, "magnitudeA", magnitudeA, "magnitudeB", magnitudeB);
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
		//println("principalComponents.length " + pca.principalComponents.length);
		for (double d : firstComponent) {
			println("Component", d);
		}
		return pca.principalComponents;
	}

}