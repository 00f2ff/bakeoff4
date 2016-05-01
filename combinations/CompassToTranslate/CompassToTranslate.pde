import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float currentX = 0, currentY = 0, currentZ = 0;


private class Target
{
  int target = 0;
  int action = 0;
  //boolean selected = false;
}


private class Selection
{
  // Introduce variable here
  float azimuth = 0;

  // actions to take on new round
  void newRound() {
    return;
  }

  // Main selection drawing method called by draw()
  void drawSelection() {
    rectMode(CORNER);
    for (int i=0;i<4;i++)
    {
      if(targets.get(trialIndex).target==i)
         fill(0,255,0);
         else
         fill(180,180,180);
      rect((width/2) * (i % 2), (height/2) * (i / 2), width/2, height/2);
    }
    showCompass();
  }

  private void showCompass()
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


  // This method return if we're actually on targer
  boolean onTarget() {
    Target t = targets.get(trialIndex);
    return (hitTest()==t.target);
  }

  // This method return current selected index
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

  void onOrientationHandler(float x, float y, float z)
  {     
    testSelectionActionMet();
  }

}


private class Action
{
  //float rotationY;
  float accelX = 0;
  float accelY = 0;

  void drawAction() {
    // handle action instructions
    fill(255);
    textSize(32);
    if (targets.get(trialIndex).action==0)
      text("LEFT / RIGHT", width/2, 150);
    else
      text("UP / DOWN", width/2, 150);
  }

  // first action is move left or right
  boolean actionZero() {
    return accelX > 2;
  }

  // second action is move up or down
  boolean actionOne() {
    return accelY > 2;
  }

  void onAccelerometerHandler(float x, float y, float z) {
    accelX = x;
    accelY = y;
    // test if we met selection and action now
    testSelectionActionMet();
  }
}

Selection selection = new Selection();
Action action = new Action();


int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();
   
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setup() {
  size(1080,1920); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);

  rectMode(CENTER);
  textFont(createFont("Arial", 20));
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
  //System.out.println(light);
  
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

  /* 
    Area of change
   */
  selection.drawSelection();

  fill(255);//white
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);
 
  action.drawAction();
}

void testSelectionActionMet() {
  if (userDone)
  return;

  Target t = targets.get(trialIndex);

  if (selection.onTarget()) // Correct target hit
  {
    if ((action.actionZero() && t.action==0) || (action.actionOne() && t.action==1))
    {
      println("Right target, right action! " + selection.hitTest());
      trialIndex++; //next trial!
      selection.newRound();
    }
    else
    {
      println("right target, wrong action!");
    }

      
    //countDownTimerWait=30; //wait 0.5 sec before allowing next trial
  } 
  else
    println("Missed target! " + selection.hitTest()); //no recording errors this bakeoff.
}

void onLightEvent(float v)
{
  selection.onLightHandler(v);
}

void onOrientationEvent(float x, float y, float z)
{
  selection.onOrientationHandler(x, y, z);
}

void onAccelerometerEvent(float x, float y, float z)
{
  action.onAccelerometerHandler(x, y, z);
}