
import java.awt.Frame;
import java.awt.BorderLayout;

ControlFrame addControlFrame(String theName, int theWidth, int theHeight) 
{
  Frame f = new Frame(theName);
  ControlFrame p = new ControlFrame(this, theWidth, theHeight);
  f.add(p);
  p.init();
  f.setTitle(theName);
  f.setSize(p.w, p.h);
  f.setLocation( 0, 0 );  // Set location of frame here
  f.setResizable(true);
  f.setVisible(true);
  return p;
}


void updateAudioSliders()
{ 
  if( frameCount > 5 )     // Workaround for null pointer error when ControlFrame's
  {                        // setup() function runs after main sketch's
    String controllerName;
    for( int i=0; i<numZones; i++ )
    {
      controllerName = "freq" + (i+1);
      cf.control().getController( controllerName ).setValue( audioFreqs[i] );
    }
    
    cf.control().getController( "Bass" ).setValue( bassLevel );
    cf.control().getController( "Mid" ).setValue( midLevel );
    cf.control().getController( "Treb" ).setValue( trebLevel );
  }
  
}


// the ControlFrame class extends PApplet, so we 
// are creating a new processing applet inside a
// new frame with a controlP5 object loaded
public class ControlFrame extends PApplet 
{
  ControlP5 cp5;
  Object parent;
  
  int w, h;
  int abc = 100;
  
  
  public void setup() 
  {
    size(w, h);
    frameRate(25);
    cp5 = new ControlP5(this);
    
    int uiX = 10;
    int uiY = 10;
    
    // ADD THE AUDIO FREQUENCY SLIDERS
    String sliderName;
    float freqMin = 0;
    float freqMax = 30;
    
    for( int i=0; i<numZones; i++ )
    {
      sliderName = "freq" + (i+1);
      
      cp5.addSlider( sliderName )
     .setPosition( uiX + (i*50),uiY )
     .setSize(20,100)
     .setRange( freqMin, freqMax )
     ;
    }
    
    uiY += 120;
    
    cp5.addSlider( "Bass" )
     .setPosition( uiX + 270 ,uiY )
     .setSize(30,100)
     .setRange( 0, 1 )
     ;
    
    cp5.addSlider( "Mid" )
     .setPosition( uiX + 330 ,uiY )
     .setSize(30,100)
     .setRange( 0, 1 )
     ;
     
    cp5.addSlider( "Treb" )
     .setPosition( uiX + 390 ,uiY )
     .setSize(30,100)
     .setRange( 0, 1 )
     ; 
    
    uiY +=5;
    
    cp5.addSlider( "masterGain" )
     .setPosition( uiX ,uiY )
     .setSize(200,20)
     .setRange( 0, 5 )
     .plugTo(parent, "audioGain")
     .setDefaultValue(1f)
     .setValue(1f)
    ;
    
    uiY += 25;
    
    cp5.addSlider( "bassGain" )
     .setPosition( uiX ,uiY )
     .setSize(200,20)
     .setRange( 0, 3 )
     .plugTo(parent, "bassGain")
     .setDefaultValue(1f)
     .setValue(1f)
    ;
    
    uiY += 25;
    
    cp5.addSlider( "midGain" )
     .setPosition( uiX ,uiY )
     .setSize(200,20)
     .setRange( 0, 3 )
     .plugTo(parent, "midGain")
     .setDefaultValue(1f)
     .setValue(1f)
    ;
    
    uiY += 25;
    
    cp5.addSlider( "trebGain" )
     .setPosition( uiX ,uiY )
     .setSize(200,20)
     .setRange( 0, 3 )
     .plugTo(parent, "trebGain")
     .setDefaultValue(1f)
     .setValue(1f)
    ;
    
    uiY += 30;
    
    cp5.addSlider( "Easing" )
     .setPosition( uiX ,uiY )
     .setSize(200,20)
     .setRange( 0.6, 0.01 )
     .plugTo(parent, "audioEaseDown")
     .setDefaultValue(0.1f)
     .setValue(0.1f)
    ;
  }

  public void draw() 
  {
      background(100);      
  }
  
  private ControlFrame() 
  {
  }

  public ControlFrame( Object theParent, int theWidth, int theHeight ) 
  {
    parent = theParent;
    w      = theWidth;
    h      = theHeight;
  }


  public ControlP5 control() 
  {
    return cp5;
  }
  
  

  
}

