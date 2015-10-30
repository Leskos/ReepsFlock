import controlP5.*;

// UI
private ControlP5 cp5main;
ControlFrame cf;

// Colour fading
float fadeR = 0;
float fadeG = 0;
float fadeB = 0;
float fadeA = 10;

boolean printDebugInfo = true;



//--------------------------------------------------------------------------
// SETUP
//--------------------------------------------------------------------------
void setup() 
{

  // SETUP DISPLAY
  size(1920, 1080);
  frameRate(60);
  smooth();
  
  // SETUP MIDI
  initMidi();

  // SETUP AUDIO ANALYSIS
  initAudioAnalysis( this );

  // SETUP UI
  cp5main = new ControlP5( this );
  cf = addControlFrame("Control Window", 480,315);

  // SETUP KINECT
  setupKinect();
}


boolean sketchFullScreen() // Set which monitor this uses in file->preferences->run sketch on display 
{
  return true;   
}


//--------------------------------------------------------------------------
// DRAW
//--------------------------------------------------------------------------
void draw() 
{
  // BACKGROUND FADING
  fill( fadeR, fadeG, fadeB, fadeA );
  noStroke();
  rect(-1, -1, width+1, height+1);

  // AUDIO REACTIVITY
  doAudioAnalysis();
  updateAudioSliders();
  
  // RENDERING
  drawKinect();  
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
