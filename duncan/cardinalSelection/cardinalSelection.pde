import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float light = 0;
float currentX = 0, currentY = 0, currentZ = 0;



private class Target
{
  int target = 0;
  int action = 0;
  boolean selected = false;
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
  if (targets.get(trialIndex).target==index && targets.get(index).selected) fill(0,255,0);
  else if (targets.get(trialIndex).target==index) fill(0,0,255);
  else if (targets.get(index).selected) fill(0,255,255); 
  else fill(180,180,180);
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
  rectMode(CENTER);
  // Draw targets (mapping to index is: 0 --> left, 1 --> right, 2 --> top, 3 --> bottom)
  // draw left target
  determineFill(0);
  rect(50, 500, 100, 300);
  // draw right target
  determineFill(1);
  rect(175, 500, 100, 300);
  // draw top target
  determineFill(2);
  rect(width/2, height/4, 300, 100);
  // draw bottom target
  determineFill(3);
  rect(width/2, height/4 + 125, 300, 100);

  // respond to light sensor (remove this)
  if (light>20)
    fill(180,0,0);
  else
    fill(255,0,0);
  // draw cursor at mouse
  //ellipse(cursorX,cursorY,50,50);
 
  fill(255);//white
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);
  
  //// handle action instructions
  //if (targets.get(trialIndex).action==0){}
  //  //text("UP", width/2, 150);
  //else{}
  //   //text("DOWN", width/2, 150);
}
  
/*
Accelerometers provide a velocity, but don't indicate in what direction something went
Need to use Kalman Filter or thresholded double integration to find position.
*/

private class Move
{
  float value;
  String axis; 
  
  //public void Move(float value, String axis)
  //{
  //  this.value = value;
  //  this.axis = axis;
  //}
}

ArrayList<Move> moves = new ArrayList<Move>();

void addMove(float value, String axis)
{
  Move move = new Move();
  move.value = value;
  move.axis = axis;
  moves.add(move);
}

void deselectTargets()
{
  // remove all selected states
  for (int i = 0; i < 4; i++) targets.get(i).selected = false;
}

/* 
Looks at the moves thus far and determines which target is selected
This version just looks at the two previous moves
(mapping to index is: 0 --> left, 1 --> right, 2 --> top, 3 --> bottom)
*/
void determineSelected()
{
  if (moves.size() == 1)
  {
    // select right
    if (moves.get(0).axis.equals("x")) targets.get(1).selected = true;
    // select bottom
    else targets.get(3).selected = true;
  }
  else
  {
    Move current = moves.get(moves.size()-1);
    Move previous = moves.get(moves.size()-2);
    // last two moves in same direction
    if (current.axis.equals(previous.axis))
    {
      // if left selected, movement selects right
      if (current.axis.equals("x") && targets.get(0).selected)
      {
        deselectTargets();
        targets.get(1).selected = true;
      }
      // if right selected, movement selects left
      else if (current.axis.equals("x") && targets.get(1).selected)
      {
        deselectTargets();
        targets.get(0).selected = true;
      }
      // if top selected, movement selects bottom
      if (current.axis.equals("y") && targets.get(2).selected)
      {
        deselectTargets();
        targets.get(3).selected = true;
      }
      // if bottom selected, movement selects top
      else if (current.axis.equals("y") && targets.get(3).selected)
      {
        deselectTargets();
        targets.get(2).selected = true;
      }
    }
    else // (reset)
    {
      // select right
      if (current.axis.equals("x")) 
      {
        deselectTargets();
        targets.get(1).selected = true;
      }
      // select bottom
      else 
      {
        deselectTargets();
        targets.get(3).selected = true;
      }
    }
  }
}

void onAccelerometerEvent(float x, float y, float z)
{
    if (moves.size() == 0)
    {
      if (y > 1)
      {
        System.out.println("y "+y); 
        addMove(y, "y");
        determineSelected(); // allow diagonal movement?
      }
      else if (x > 1)
      {
        System.out.println("x "+x); 
        addMove(y, "y");
        determineSelected();
      }
    }
    else
    {
      // need a lot of error checking because accelerometer events get triggered multiple times with the same value
      // y-axis case
      //* need to account for empty arraylist
      if (y > 1 && (!moves.get(moves.size()-1).axis.equals("y") || moves.get(moves.size()-1).value != y))
      {
        System.out.println(moves.size());
        System.out.println("y "+y); 
        addMove(y, "y");
        determineSelected(); // allow diagonal movement?
      }
      else if (x > 1 && (!moves.get(moves.size()-1).axis.equals("x") || moves.get(moves.size()-1).value != x))
      {
        System.out.println("x "+x); 
        addMove(x, "x");
        determineSelected();
      }
    }
    
    
    
    
  //}
  
  if (userDone)
    return;
    
  // remove this
  if (light>20) //only update cursor, if light is low
  {
    cursorX = 300+x*40; //cented to window and scaled
    cursorY = 300-y*40; //cented to window and scaled
  }
  
  Target t = targets.get(trialIndex);
  
  
  // remove this
  if (light<=20 && abs(z-9.8)>4 && countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      println(z-9.8);
      if (((z-9.8)>4 && t.action==0) || ((z-9.8)<-4 && t.action==1))
      {
        println("Right target, right z direction! " + hitTest());
        trialIndex++; //next trial!
        currentX = 0;
        currentY = 0;
        currentZ = 0;
        moves.clear();
        deselectTargets();
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
   for (int i=0;i<4;i++)
      if (dist(300,i*150+100,cursorX,cursorY)<100)
        return i;
 
    return -1;
}

  
void onLightEvent(float v) //this just updates the light value
{
  light = v;
}