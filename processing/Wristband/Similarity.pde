import java.util.Vector;
import java.lang.RuntimeException;
import java.util.Arrays;

import javastat.multivariate.PCA;

class Similarity {

	Similarity() {
	}


	float compare(double[][] d1, double[][] d2) {
		ArrayList<Float> v1 = new ArrayList<Float>();
		v1.add(1.00);
		v1.add(1.00);
		v1.add(1.00);
		ArrayList<Float> v2 = new ArrayList<Float>();
		v2.add(1.00);
		v2.add(2.12);
		v2.add(1.00);
		ArrayList<Float> v3 = new ArrayList<Float>();
		v3.add(1.00);
		v3.add(2.15);
		v3.add(1.10);
		
        // get the principal components of the multidimensional array of values (i.e. 9 dof x time)
		double[][] pcaA = getPCA(d1);
		println(pcaA.length, pcaA[0].length);

		double[][] pcaB = getPCA(d2);
		println(pcaB.length, pcaB[0].length);
		
		ArrayList<Float> vA = new ArrayList<Float>();
		ArrayList<Float> vB = new ArrayList<Float>();

		for (int i = 0; i < min(pcaA.length, pcaB.length); i++) {
			println("adding similarity principal component dimension " + i + " for comparison");
			vA.add(new Double(pcaA[i][0]).floatValue());
			vB.add(new Double(pcaB[i][0]).floatValue());
		}
		println("similarity between", vA, vB);
		println(getCosineSimilarity(vA, vB));
	

		return 0.00;
	}

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


	double[][] getPCA(double values[][]) {
		// Non-null constructor 
		PCA testclass1 = new PCA(0.95, "covariance", values); 
		double [] firstComponent = testclass1.principalComponents[0]; 
		for (double d : firstComponent) {
			println("Component", d);
		}
		// println("TEST1", firstComponent[0], firstComponent[1]);
		// println("TEST1", testclass1.principalComponents);

		return testclass1.principalComponents;
	}

}