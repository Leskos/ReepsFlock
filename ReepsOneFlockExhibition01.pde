//-------------------------------------------------------------------------- //<>// //<>//
// IMPORT STATEMENTS
//--------------------------------------------------------------------------
import ddf.minim.*;
import ddf.minim.analysis.*;
import oscP5.*;
import netP5.*;

// OSX SPECIFIC
//import codeanticode.syphon.*;

// ZACH'S IP ADDRESS - 169.254.4.151

//169.254.163.26

//--------------------------------------------------------------------------
// VARIABLES
//--------------------------------------------------------------------------
Flock flock;            // Collection of boids

OscP5      oscP5;       // OSC communication
NetAddress SCAddress;   // OSC output address

Minim      minim;       // Minim audio library
AudioInput audioIn;     // Audio input
FFT        fft;         // Frequency analysis
BeatDetect beat;        // Beat detection

// OSX SPECIFIC
//SyphonServer server;    // Syphon Server



int   id;               // NOT USED
float transparency       = 10;
int   numZones           = 9;
int   sampleRate         = 44100;
int   bufferSize         = 512;
int   minBassThreshold   = 10;
int   minMidThreshold    = 2;
float   minTrebThreshold = 0.4;

// Colour fade
float a        = 1*PI/2;  // RENAME THIS
float pathB    = 125;     // RENAME THIS
float red      = 0;
float green    = 0;
float blue     = 0;

boolean printDebugInfo = true;


//  ---------------
//  KINECT VARIABLES



//--------------------------------------------------------------------------
// SETUP
//--------------------------------------------------------------------------
void setup() 
{

  // DISPLAY SETTINGS
  //size(960, 540, P3D);
  //size(displayWidth, displayHeight);
  
  frameRate(60);
  smooth();
  

  // FLOCK
  flock = new Flock();
  for (int i = 0; i < 400; i++) 
  {
    id = i;
    flock.addBoid( width/2, height/2 );
  }

  // OSC MESSAGING
  oscP5 = new OscP5( this, 12000 );
  SCAddress = new NetAddress( "127.0.0.1", 57120 ); 

  // MINIM
  minim   = new Minim( this );
  audioIn = minim.getLineIn( Minim.STEREO, bufferSize );
  fft     = new FFT( audioIn.bufferSize(), audioIn.sampleRate() );
  fft.logAverages( 86, 1 );  // first parameter specifies the size of the smallest octave to use (in Hz), second is how many bands to split each octave into results in 9 bands
  fft.window( FFT.HAMMING );
  numZones = fft.avgSize();  // avgSize() returns the number of averages currently being calculated


  setupKinect();
  
  // Create syhpon server to send frames out.
  // OSX SPECIFIC
  //server = new SyphonServer(this, "Processing Syphon");
}




//--------------------------------------------------------------------------
// DRAW
//--------------------------------------------------------------------------
void draw() 
{

  flock.clearTargets( );

  addTargetsFromOutlines();

  // BACKGROUND FADING
  pathB=50*sin(a);  // RENAME THIS
  a=a+0.03;         // RENAME THIS
  fill(red, green, blue, transparency);
  rect(-1, -1, width+1, height+1);

  // AUDIO REACTIVITY
  doAudioReactivity();
  
  
  drawKinect();

  // FLOCKING
  flock.run();
  
  // KEYBOARD CONTROLS
  keyboardControls();

  
  // SEND SYPHON OUT
  // OSX SPECIFIC
  //server.sendScreen();
}


void addTargetsFromOutlines()
{
   // FOR EACH BLOB
  for ( int blobNum = 0; blobNum < getNumBlobs (); blobNum++ )
  {
    // IF BLOB EXISTS 
    if ( blobExists( blobNum ) )
    {
      // GET TARGETS FROM IT
      FlockingTarget[] kinectTargets = getTargetsFromBlob( blobNum );
      
      // ADD THEM TO THE FLOCKING SIM
      for ( int i=0; i< kinectTargets.length; i++ )
      {
        flock.addTarget( kinectTargets[i] );
      }
    } 
    else
    {
      println("NO BLOBS");
    }
  }
}

// ADD BOIDS FROM RANDOM VERTICES 
void addBoidsFromOutlines( int numBoids )
{
   // FOR EACH BLOB
  for ( int blobNum = 0; blobNum < getNumBlobs (); blobNum++ )
  {
    // IF BLOB EXISTS 
    if ( blobExists( blobNum ) )
    {
      for ( int i=0; i< numBoids; i++ )
      {
        PVector outlinePoint = getPointOnBlobOutline( blobNum );
        flock.addBoid( (int)outlinePoint.x, (int)outlinePoint.y );
      }
    } 
    else
    {
      for ( int i=0; i< numBoids; i++ )
      {
        flock.addBoid(width/2,height/2);
      }      
    }
  }
}



//--------------------------------------------------------------------------
// AUDIO REACTIVITY
//--------------------------------------------------------------------------
void doAudioReactivity()
{
  // START OF FFT 

  fft.forward( audioIn.mix ); // perform forward FFT on ins mix buffer
  int highZone = numZones - 1;

  // FOR EACH FREQUENCY RANGE -  9 bands / zones / averages
  for (int i = 0; i < numZones; i++) 
  {     
    float average = fft.getAvg(i); // return the value of the requested average band, ie. returns averages[i]
    float avg = 0;
    int lowFreq;
    
    // If i = 0 then set lowFreq to 0
    if ( i == 0 ) 
    {
      lowFreq = 0;
    }
    // if i doesn't equal 0, then set lowFreq to the highest possible frequency divided by 
    else 
    {
      lowFreq = (int)((sampleRate/2) / (float)Math.pow(2, numZones - i)); // 0, 86, 172, 344, 689, 1378, 2756, 5512, 11025
    }

    int hiFreq = (int)((sampleRate/2) / (float)Math.pow(2, highZone - i)); // 86, 172, 344, 689, 1378, 2756, 5512, 11025, 22050

    // ***** ASK FOR THE INDEX OF lowFreq & hiFreq USING freqToIndex ***** //

    // freqToIndex returns the index of the frequency band that contains the requested frequency
    int lowBound = fft.freqToIndex(lowFreq);
    int hiBound  = fft.freqToIndex(hiFreq);

    for ( int j = lowBound; j <= hiBound; j++ )  // j is 0 - 256 
    { 
      float spectrum = fft.getBand(j); // return the amplitude of the requested frequency band, ie. returns spectrum[offset]
      avg += spectrum; // avg += spectrum[j];
    }

    avg /= (hiBound - lowBound + 1);
    average = avg; // averages[i] = avg;

    // END OF FFT
    

    // LINK BASS FREQUENCIES TO FLOCKING PARAMS
    if ( i==0 )
    {
      linkBassToBoids( average );
    } // end ( i==0 )
    
    // LINK MID FREQUENCIES 
    if ( (i <=5) && (i <=6)  )
    {
      linkMidToBoids (average);
    }
    
    // LINK TREB FREQUENCIES 
    if (i == 6 )
    {
      linkTrebToBoids (average);
    }
    
  } // end (int i = 0; i < numZones; i++)
}


void linkBassToBoids( float bassAvg )
{
  
  if ( bassAvg > minBassThreshold )
  {
    transparency = map( bassAvg, minBassThreshold, 40, 255, 50);  

    flock.cohesionWeight     = map( bassAvg, minBassThreshold, 40, 0, 15 );
    flock.separationWeight   = map( bassAvg, minBassThreshold, 40, 0, 15 );
    flock.accelerationWeight = 1;
    flock.velocityWeight     = 2;
    flock.alignmentWeight    = map( bassAvg, minBassThreshold, 40, 0, 2);
    
    red = map( bassAvg, minBassThreshold, 40, 0, 155);
    
    addBoidsFromOutlines( (int) bassAvg);
  } 
  else 
  {
    transparency = 150;

    flock.cohesionWeight     = 2.5;
    flock.separationWeight   = 0.3;
    flock.accelerationWeight = 2;
    flock.velocityWeight     = 0.95;
    
    flock.alignmentWeight    = 2.5;
    
    red = 0;

  } // end else
}

void linkMidToBoids( float midAvg )
{    
  if ( midAvg > minMidThreshold )
  {
    flock.cohesionWeight     = 2.5;
    flock.alignmentWeight    = map( midAvg, minMidThreshold, 80, 0, -1000);
    
    //fill(255,255,255,random(1,255));
    //stroke(255,random(1,255));
    //ellipse(random(1,displayWidth),random(1,displayHeight),10,10);
  } 
  else 
  {
    flock.cohesionWeight     = 0.5;
    flock.alignmentWeight    = 0;
  } // end else
}

void linkTrebToBoids( float trebAvg )
{
  //println(trebAvg);
    
  if ( trebAvg > minTrebThreshold )
  {
    red = map( trebAvg, minTrebThreshold, 2, 0, 20);
    green = map( trebAvg, minTrebThreshold, 2, 0, 20);
    blue = map( trebAvg, minTrebThreshold, 2, 0, 20);
    flock.alignmentWeight    = map( trebAvg, minTrebThreshold, 2, 0, -2000);
  } 
  else 
  {
    red = 0;
    green = 0;
    blue = 0;
    flock.alignmentWeight    = 0;
  } // end else
}





//--------------------------------------------------------------------------
// KEYBOARD CONTROLS
//--------------------------------------------------------------------------

void keyboardControls()
{
  // KEYBOARD CONTROLS
  if (keyPressed) 
  {
    if (key == 'c' || key == 'C') 
    {
      println("C");
      flock.alignmentWeight = -1000;
    }
  }
}


//--------------------------------------------------------------------------
// OSC MESSAGING
//--------------------------------------------------------------------------
void oscEvent( OscMessage theOscMessage ) 
{


  // SEPARATION
  if (theOscMessage.checkAddrPattern( "/separationWeight" ) )
  {
    float sepWeight = theOscMessage.get( 0 ).floatValue();
    flock.separationWeight = sepWeight;
  }

  // ALIGNMENT
  if (theOscMessage.checkAddrPattern("/alignmentWeight"))
  {
    float aliWeight = theOscMessage.get( 0 ).floatValue();
    flock.alignmentWeight = aliWeight;
  }

  // COHESION
  if (theOscMessage.checkAddrPattern("/cohesionWeight"))
  {
    float cohWeight = theOscMessage.get( 0 ).floatValue();
    flock.cohesionWeight = cohWeight;
  }

  // TRANSPARENCY
  if (theOscMessage.checkAddrPattern( "/transMessage" ) )
  {
    float transMessage = theOscMessage.get( 0 ).floatValue();
    transparency = transMessage;
  }

  // ADD BOIDS
  if (theOscMessage.checkAddrPattern( "/newBoids" ) )
  {
    int randomX = (int)random( width );
    int randomY = (int)random( height );

    flock.addBoid( randomX, randomY );
    flock.addBoid( randomX, randomY );
    flock.addBoid( randomX, randomY );
    flock.addBoid( randomX, randomY );
    flock.addBoid( randomX, randomY );
  }
}


//--------------------------------------------------------------------------
// ADD BOIDS ON MOUSE CLICK
//--------------------------------------------------------------------------
void mouseDragged( MouseEvent event )
{
  println("MOUSE BUTTON : " + event.getButton() );

  if ( event.getButton() == 37 )
  {
    //flock.alignmentWeight = -1000;
    flock.addBoid( mouseX, mouseY );
  }
  if ( mouseButton == 39 )
  {
    flock.removeBoids( 1 );
  }
}

boolean sketchFullScreen() {
  return true;
}


//--------------------------------------------------------------------------
// DEBUG PRINT METHOD
//--------------------------------------------------------------------------
void debugPrint( String msg )
{
  if ( printDebugInfo )
  {
    print( "\n" + msg );
  }
}
