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
  int selectedIndex = 0;
  float light = 500;
  float lastLight = 500;

  // actions to take on new round
  void newRound() {
    selectedIndex = 0;
  }

  // Main selection drawing method called by draw()
  void drawSelection() {
    rectMode(CENTER);
    for (int i = 0; i < 4; i++)
    {
      determineFill(i);
      rect(width/2, height/4 + 300*i, 700, 250);
    }
  }

  private void determineFill(int index)
  {
    if (onTarget()) fill(0,255,0);
    else if (targets.get(trialIndex).target==index) fill(0,0,255);
    else if (index == selectedIndex) fill(0,255,255); 
    else fill(180,180,180);
  }

  // This method return if we're actually on targer
  boolean onTarget() {
    return (targets.get(trialIndex).target == selectedIndex);
  }

  // This method return current selected index
  int hitTest() 
  {
     return selectedIndex;
  } 

  // Handlers for sensor events
  void onLightHandler(float v)
  {
    lastLight = light;
    light = v;
    if (light <= 10) {
      if (lastLight <= 10) // user still covering light
        return;
      else 
        selectedIndex = (selectedIndex + 1) % 4;
    }
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
      //println("Right target, right action! " + selection.hitTest());
      if (trialIndex + 1 == targets.size())
      {
        finishTime = millis();
        userDone = true;
      }
      else
      {
        trialIndex++; //next trial!
      }
      selection.newRound();
    }
    // else
    // {
    //   println("right target, wrong action!");
    // }

      
    //countDownTimerWait=30; //wait 0.5 sec before allowing next trial
  } 
  // else
  //   println("Missed target! " + selection.hitTest()); //no recording errors this bakeoff.
}

void onLightEvent(float v)
{
  selection.onLightHandler(v);
}

void onAccelerometerEvent(float x, float y, float z)
{
  action.onAccelerometerHandler(x, y, z);
}