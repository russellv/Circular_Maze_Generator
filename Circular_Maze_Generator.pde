//  Circular_Maze_Generator
//
//  Re-creation of a circular maze generator.
//  Run this program in Processing and you may end up with something like this:
//  http://upload.wikimedia.org/wikipedia/commons/archive/4/4f/20111125045649%21CircleMaze.png
//
//  Created by Russell Vanderhout on from 2014-06-28 to 014-06-28.
//  Copyright (c) 2014 Russell Vanderhout. All rights reserved.
//****************************
//*********************************
//*************************************
//****************************************
//ONLY EDIT THESE PARAMETERS****************

//Canvas dimensions
int screenWidth=720;
int screenHeight=720;

//Position of the circle
float centerX=360;
float centerY=360;

//Properties of the maze
float ringWidth=10;
int ringCount=(int)(screenHeight/2/ringWidth);
int centerLineCount=6;

//******************************************
//****************************************
//*************************************
//*********************************
//****************************


CircularMaze myMaze;

//Keep track of last valid location with a stack
int location=0;
Stack locationStack=new Stack();
  
void setup(){
  size(screenWidth, screenHeight);
  frameRate(100000);
  noFill();
  
  myMaze=new CircularMaze(ringCount,centerLineCount);
  locationStack.Push(location);
}

void draw(){
  //Choose a random new path
  location=myMaze.OpenRandomNewAdjacent(location);
  
  //If there are none, back up with the stack
  while(location==-1){
    location=locationStack.Top();
    //If stack is empty, you must be finished
    if(location==-1){
      noLoop();
      println("Finished.");
      myMaze.DrawMaze(centerX, centerY, ringWidth);
      return;
    }
    locationStack.Pop();
    
    //Choose a random new path...repeat
    location=myMaze.OpenRandomNewAdjacent(location);
  }
  
  locationStack.Push(location);
  //println("Location: "+location); 
  
  background(255, 204, 0);
  //myMaze.DrawMaze(centerX, centerY, ringWidth);
}

//Stack class (Processing doesn't seem to have one)
class Stack{
  ArrayList<Integer> myStack=new ArrayList<Integer>();
  
  public void Push(int newTop){
    myStack.add(newTop);
  }
  
  //Return -1 if empty
  public int Top(){
    if(myStack.size()==0)return -1;
    return myStack.get(myStack.size()-1);
  }
  
  public void Pop(){
    if(myStack.size()!=0)myStack.remove(myStack.size()-1);
  }
}
  
