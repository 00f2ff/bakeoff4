import ketai.sensors.*;

KetaiSensor sensor;
float azimuth, pitch, roll, light;
String direction = "";
float rotationX, rotationY, rotationZ;
float accelX, accelY, accelZ;
float maxX = 9.8;
float minX = 9.8;


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

void onLightEvent(float v) //this just updates the light value
{
  light = v;
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
  text(str(int(light)), cx+7, cy+7);
  text("RotationX: " + str(int(azimuth)), cx+7, cy+10);
  text("RotationY: " + str(int(pitch)), cx+7, cy+50);
  text("RotationZ: " + str(int(roll)), cx+7, cy+90);
  text("accelX: " + str(int(accelX)) + " MINx: " + str(int(minX)) + " maxX: " + str(int(maxX)), cx+7, cy+130);
  text("accelY: " + str(int(accelY)), cx+7, cy+170);
  text("accelZ: " + str(int(accelZ)), cx+7, cy+210);
}

void onGyroscopeEvent(float x, float y, float z) {
  rotationX = x;
  rotationY = y;
  rotationZ = z;
}

void onAccelerometerEvent(float x, float y, float z) {
  accelX = x;
  accelY = y;
  accelZ = z;
  
  if (accelX > maxX) {
    maxX = accelX;
  }
  if (accelX < minX) {
    minX = accelX;
  }
}