/**
 * Simple helper for making a cube with 3 different colored sides
 */
class ColorCube {
    float w, h, d;
    float x, y, z;
    float rotationX, rotationY, rotationZ;
    float rotationEasing = 0.75;
    color colorFront, colorSide, colorTop;

    ColorCube(float _w, float _h, float _d, color _colorFront, color _colorSide, color _colorTop) {
        w = _w;
        h = _h;
        d = _d;
        applyColor(_colorFront, _colorSide, _colorTop);
    }

    void setPosition(float _x, float _y, float _z) {
        x = _x;
        y = _y;
        z = _z;
    }

    void setRotation(float _rotationX, float _rotationY, float _rotationZ) {
        rotationX = rotationX * rotationEasing + (1 - _rotationX * rotationEasing);
        rotationY = rotationY * rotationEasing + (1 - _rotationY * rotationEasing);
        rotationZ = rotationZ * rotationEasing + (1 - _rotationZ * rotationEasing);
    }

    void render() {
        noStroke();
        pushMatrix();
        translate(x, y, z);
        rotateX(radians(rotationX));
        rotateZ(radians(rotationZ));
        rotateY(radians(rotationY));
        //box(w, d, h);

        float w2, d2, h2;
        w2 = w / 2;
        d2 = d / 2;
        h2 = h / 2;

        // w d h
        beginShape();
        fill(colorSide);
        vertex(w2, -d2, -h2);
        vertex(w2, d2, -h2);
        vertex(w2, d2, h2);
        vertex(w2, -d2, h2);
        endShape();
        beginShape();
        fill(colorSide);
        vertex(-w2, -d2, -h2);
        vertex(-w2, d2, -h2);
        vertex(-w2, d2, h2);
        vertex(-w2, -d2, h2);
        endShape();

        beginShape();
        fill(colorFront);
        vertex(-w2, d2, -h2);
        vertex(-w2, d2, h2);
        vertex(w2, d2, h2);
        vertex(w2, d2, -h2);
        endShape();
        beginShape();
        fill(colorFront);
        vertex(-w2, -d2, -h2);
        vertex(-w2, -d2, h2);
        vertex(w2, -d2, h2);
        vertex(w2, -d2, -h2);
        endShape();    

        beginShape();
        fill(colorTop);
        vertex(-w2, -d2, h2);
        vertex(-w2, d2, h2);
        vertex(w2, d2, h2);
        vertex(w2, -d2, h2);
        endShape();
        beginShape();
        fill(colorTop);
        vertex(-w2, -d2, -h2);
        vertex(-w2, d2, -h2);
        vertex(w2, d2, -h2);
        vertex(w2, -d2, -h2);
        endShape();   

        popMatrix();
    }

    void applyColor(color _colorFront, color _colorSide, color _colorTop) {
        colorFront = _colorFront;
        colorSide = _colorSide;
        colorTop = _colorTop;
    }
}

