import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float light = 0;
float currentX = 0, currentY = 0, currentZ = 0;
float proximity = 0;
int selectedIndex = 0;



private class Target
{
  int target = 0;
  int action = 0;
  //boolean selected = false;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();
   
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setup() {
  size(480,800); //you can change this to be fullscreen
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

void determineFill(int index)
{
  if (targets.get(trialIndex).target==index && index == selectedIndex) fill(0,255,0);
  else if (targets.get(trialIndex).target==index) fill(0,0,255);
  else if (index == selectedIndex) fill(0,255,255); 
  else fill(180,180,180);
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
  rectMode(CENTER);
  for (int i = 0; i < 4; i++)
  {
    determineFill(i);
    rect(width/2, height/4 + 150*i, 300, 100);
  }
 
  fill(255);//white
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);
  
  //// handle action instructions
  //if (targets.get(trialIndex).action==0){}
  //  //text("UP", width/2, 150);
  //else{}
  //   //text("DOWN", width/2, 150);
}

int hitTest() 
{
   for (int i=0;i<4;i++)
      if (dist(300,i*150+100,cursorX,cursorY)<100)
        return i;
 
    return -1;
}

void onProximityEvent(float d, long a, int b)//: d distance from sensor (typically 0,1), a=timestamp(nanos), b=accuracy
{
  proximity = d;
  System.out.println(proximity+" accuracy: "+b);
  if (proximity == 5) selectedIndex = (selectedIndex + 1) % 4;
}