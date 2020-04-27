
/*
Image Synth was inspired by 3Blue1Brown's video
 https://www.youtube.com/watch?v=3s7h2MHQtxc&t=170s
 
 It implements a hilbert curve, aglorithm curtesy to Daniel Shiffman,
 to map out an image to an array.
 
 The array is used to map the amplitude of 
 oscillator banks with differing frequencies 
 to create an additive synthesizer from images.
 
 KEYS:
 
 --Testing
 p: Draw to test frequency mapping 
 rightClick-drag: draw the circles
 leftClick: clear testing image
 
 --Buffer
 g: Use grayscale
 c: Average the surrounding pixels as value
 q: Cycle through r,g,b if not using grayscale
 w: Don't use weight; WARNING IT'S VERY LOUD.
 */
import processing.video.*;
import ddf.minim.*;
import ddf.minim.ugens.*;
import themidibus.*; 

//Hilbert Curve
int order = 8;  //Order 8 for 256px x 256px image
int N = int(pow(2, order));
int total = N * N;

PVector[] path = new PVector[total];
int r[] = new int[total];
int g[] = new int[total];
int b[] = new int[total];


//Input
PGraphics tester;
boolean testing; //Using tester image to draw
boolean isGray;  //Grayscale or RGB
int rgbIndex; //Use r, g, or b; cycles through;
String[] rgbStrings= {"Red", "Green", "Blue"};
Movie mov;


//Minim Setup
MidiBus myBus;
Minim       minim;
AudioOutput out;


//Oscillator bank
int bsize=256;  //Buffer size which represents 256 frequency's amplitudes 
Oscil[] waves = new Oscil[bsize];   //Oscillator bank
float[] buffer = new float[bsize];    
float[] frequencies = new float[bsize];
float[]  weights = new float[bsize];
float[]  velocity = new float[bsize];
float[]  amplitude = new float[bsize];
float gain;    //Final audio gain

int type = 0; 
int lowerHz = 0, higherHz; 
boolean noWeights;
float saturation = 0;

//MIDI Optional
int[] equalizer = new int[8]; //I have eight nobs
int[] eqIndex = new int[8];


void setup() {
  size(1920, 1080, P2D);
  //noCursor();
  background(0);

  //Use tester to draw and debug the frequencies 
  tester = createGraphics(256, 256, P2D);
  tester.beginDraw();
  tester.background(0);
  tester.endDraw();

  //Creates the path the hilbert curve takes
  //path[i] returns x,y coord asd PVector
  for (int i = 0; i < total; i++) {
    path[i] = hilbert(i);
  }

  //Load movie to change to audio and play
  mov = new Movie(this, "test13.mp4");
  mov.loop();
  mov.volume(0);

  //Minim setup
  minim = new Minim(this);
  out = minim.getLineOut();

  for (int j=0; j<bsize; j++) {
    //Use this area to change how to map the frequencies. 

    waves[j] = new Oscil(27.50+27.50*j, 0, Waves.SINE);  //A0 as fundamental frequency. A1 will be 55, A2 will be 110 and on
    frequencies[j] = 27.50+27.50*j; //Store the frequencies into array 
    weights[j] = 1/(j*0.035+1); //Equation for weights; change according to what you want
    waves[j].patch(out);
    //ADSR... sort of
    velocity[j] = 0f;
    amplitude[j] = 0f;
  }

  //Midi setup, log mapping of frequencies
  float mult = log(bsize)/log(10);
  for (int j=0; j<eqIndex.length; j++) {
    eqIndex[j] = int(pow(j+3, mult));
  }
  myBus = new MidiBus(this, 0, "Java Sound Synthesizer");
  for (int i=0; i<equalizer.length; i++) {
    equalizer[i] = 0;
  }
}

void movieEvent(Movie m) {
  //Read video
  m.read();
}

void draw() {
  if(testing){
   gain=1.0; 
  }else{
     gain=map(mouseX, 0, width, 0, 0.6); //MouseX changes the gain  
  }
  background(0);

  if (testing) {
    tester.beginDraw();
    if (mousePressed) {
      if (mouseButton==LEFT) {
        tester.background(0);
      }
      if (mouseButton==RIGHT) {
        tester.stroke(0, 255, 0);
        tester.strokeWeight(2);
        tester.ellipse(map(mouseX, 0, width, 0, 255), map(mouseY, 0, height, 0, 255), 4, 4); //Draw circles
      }
    }
    tester.endDraw();
  }


  PImage testImage;
  if (testing) {
    image(tester, 420, 200+20, 512, 512);
    testImage = tester.copy();
  } else {
    image(mov, 420, 200+20, 512, 512);
    testImage = mov.copy();
  }
  noFill();
  stroke(0, 255, 0);
  strokeWeight(2);
  rect(420, 200+20, 512, 512);

  if (isGray) {
    testImage.filter(GRAY);
    testImage.filter(DILATE); //Optional, really.
  }





  //Fetch the rgb values of each pixel in following the hilbert path
  for (int j=0; j<total; j++) {
    color c = testImage.get(int(path[j].x), int(path[j].y)); //Probably slower than loadPixels() method...
    r[j] = (c >> 16) & 0xFF;  //Faster method for accessing rgb values
    g[j] = (c >> 8) & 0xFF;
    b[j] = c & 0xFF;
  }

  //Buffer stores the values used to map out as velocities->amplitude later
  //rgbToBuffer's type is used to switch between averaging or not
  if (rgbIndex==0) {
    buffer = rgbToBuffer(buffer, type, r);  //RED
  } else if ( rgbIndex==1) {
    buffer = rgbToBuffer(buffer, type, g);  //GREEN
  } else {
    buffer = rgbToBuffer(buffer, type, b);  //BLUE
  }


  //Play around with these values for your personal liking
  //Acts like an ADSR
  for (int j=0; j<bsize; j++) {
    velocity[j] = min(velocity[j]+buffer[j]*max(0.91*(bsize-j)/bsize, 0.001), 1/(j*0.01+1));
    amplitude[j] = velocity[j];
    velocity[j] =max(velocity[j]-velocity[j]*(0.45-0.3*weights[j]+0.07*(bsize-j)/bsize), 0.0001);

    //
    if (noWeights) {
      //VERY LOUD! WARNING
      waves[j].setAmplitude(buffer[j]*gain);
    } else {
      waves[j].setAmplitude(amplitude[j]*weights[j]*gain); //Higher pitch is usually louder, so adjust by weights
    }
  }


  // draw the waveform
  pushMatrix();
  translate(952, 624);
  fill(0);
  drawWaveForm();
  popMatrix();

  // draw unwrapped hilbert as 2d just to visualize long array
  pushMatrix();
  translate(952, 200+20);
  redrawHilbert(testImage);
  popMatrix();

  // draw the amplitude weights;
  pushMatrix();
  translate(952, 774);
  drawWeights();
  popMatrix();

  //Text Informatiom
  pushMatrix();
  translate(1228, 200+40);
  fill(0, 255, 0);
  textSize(20);

  String t = type==0 ? "No averaging" : "Averaging";
  text(t, 0, 0);

  translate(0, 25);
  t = str(bsize);
  text("Buffer size: "+bsize, 0, 0);

  translate(0, 25);
  String lower = str(frequencies[0]);
  text("Lowest Frequency: "+lower, 0, 0);

  translate(0, 25);
  String higher = str(frequencies[bsize-1]);
  text("Highest Frequency: "+higher, 0, 0);

  translate(0, 25);
  t = noWeights ? "No Weights" : "With Weights";
  text(t, 0, 0);


  translate(0, 25);
  t = isGray ? "Grayscale" : rgbStrings[rgbIndex];
  text("RGBValue: " + t, 0, 0);
  popMatrix();
  noFill();
}
void keyPressed() {
  if (key=='c') {
    if (type==0) {
      type=1;
    } else {
      type=0;
    }
  }
    if (key=='p') {
      testing=!testing;
    }
    if (key=='g') {
      isGray = !isGray;
    }
    if (key=='q') {
      rgbIndex++;
      if (rgbIndex>2)rgbIndex=0;
    }
  
  if (key=='w') {
    noWeights = !noWeights;
  }
}
void mousePressed() {
  println(mouseX, mouseY);
}
