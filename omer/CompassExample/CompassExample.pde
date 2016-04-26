import ketai.sensors.*;

KetaiSensor sensor;
float azimuth, pitch, roll;
String direction = "";

void setup()
{
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);
  textAlign(CENTER, CENTER);
  textSize(36);
}

void draw()
{
  background(0);
  showCompass();
}

void onOrientationEvent(float x, float y, float z)
{
  azimuth = x;
  pitch = y;
  roll = z;
}

void showCompass()
{
  int cx = width/2;
  int cy = height/2;
  float radius = 0.8 * cx;
  stroke(255);
  noFill();
  ellipse(cx, cy, radius*2, radius*2);

  pushMatrix();
  translate(cx, cy);
  rotate(radians(-azimuth));
  line(0, 0, 0, radius);
  ellipse(0, 0, 10, 10);
  popMatrix();
  // Display value (in degrees)
  fill(255);
  text(str(int(azimuth)), cx+7, cy+7);

}