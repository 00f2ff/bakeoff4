import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float azimuth = 0;
float currentZ = 0.0;
float light = 0;

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();
   
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setup() {
  size(800,1600); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);

  rectMode(CORNER);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);
  
  for (int i=0;i<trialCount;i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }
  
  Collections.shuffle(targets); // randomize the order of the button;
}

void draw() {

  background(80); //background is light grey
  noStroke(); //no stroke
  
  countDownTimerWait--;
  
  if (startTime == 0)
    startTime = millis();
  
  if (trialIndex==targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }
  
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount,1) + " sec per target", width/2, 150);
    return;
  }
  
  for (int i=0;i<4;i++)
  {
    if(targets.get(trialIndex).target==i)
       fill(0,255,0);
       else
       fill(180,180,180);
    rect((width/2) * (i % 2), (height/2) * (i / 2), width/2, height/2);
  }

  showCompass();

  fill(255);//white
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);
  
  if (targets.get(trialIndex).action==0)
    text("UP", width/2, 150);
  else
     text("DOWN", width/2, 150);
}

void showCompass()
{
  int cx = width/2;
  int cy = height/2;
  float radius = 0.8 * cx;
  stroke(255);
  noFill();
  ellipse(cx, cy, radius*2, radius*2);

  // draw pointer to red circle
  pushMatrix();
  translate(cx, cy);
  rotate(radians(-azimuth));
  line(0, 0, 0, radius);
  if (light>20)
    fill(180,0,0);
  else
    fill(255,0,0);
  ellipse(0,radius,50,50);
  popMatrix();

}  

void onAccelerometerEvent(float x, float y, float z)
{
  currentZ = z;
}

void onOrientationEvent(float x, float y, float z)
{
  if (userDone)
    return;
    
  if (light>20) //only update cursor, if light is low
  {
    azimuth = x; //cented to window and scaled
  }
  
  Target t = targets.get(trialIndex);
  
  if (light<=20 && abs(currentZ-9.8)>4 && countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      println(currentZ-9.8);
      if (((currentZ-9.8)>4 && t.action==0) || ((currentZ-9.8)<-4 && t.action==1))
      {
        println("Right target, right z direction! " + hitTest());
        trialIndex++; //next trial!
      }
      else
        println("right target, wrong z direction!");
        
      countDownTimerWait=30; //wait 0.5 sec before allowing next trial
    }
    else
      println("Missed target! " + hitTest()); //no recording errors this bakeoff.
  }
}

int hitTest() 
{
  //get center of red circle
  int centerX = width/2;
  int centerY = height/2;
  float radius = 0.8 * centerX;

  float tx = centerX + radius * sin(radians(azimuth));
  float ty = centerY + radius * cos(radians(-azimuth));

  println("tx: "+tx);
  println("ty: "+ty);

  // temporary hack until angles are figured out
  // 0 -> 2
  // 1 -> 0
  // 2 -> 3
  // 3 -> 1

  if (tx < centerX && ty < centerY)
    return 0;
  if (tx > centerX && ty < centerY)
    return 1;
  if (tx < centerX && ty > centerY)
    return 2;
  if (tx > centerX && ty > centerY)
    return 3;

  return -1;
}
  
void onLightEvent(float v) //this just updates the light value
{
  light = v;
}