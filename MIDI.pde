import java.util.Map;
import themidibus.*; 

MidiBus midi; 
boolean printMidi = false;


HashMap<Integer, MidiParam> midiMap     = new HashMap<Integer, MidiParam>();
HashMap<MidiParam, Float>   paramVals   = new HashMap<MidiParam, Float>();

float p1, p2, p3 = 0f;
PVector[] paramRanges;



void initMidi()
{
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  midi = new MidiBus(this, "BCF2000", "BCF2000"); 

  // This initializes the MIDI CC numbers related to each parameter
  midiMap.put( 1, MidiParam.SEP );
  midiMap.put( 2, MidiParam.ALI );                                      // EDIT MIDI CCs HERE
  midiMap.put( 3, MidiParam.COH );

  // This initialises the ranges to map each parameter to
  paramRanges = new PVector[ MidiParam.values().length ];
  
  paramRanges[ MidiParam.SEP.ordinal() ] = new PVector( 0, 5 );
  paramRanges[ MidiParam.ALI.ordinal() ] = new PVector( 0, 5 );       // EDIT MIDI RANGES HERE
  paramRanges[ MidiParam.COH.ordinal() ] = new PVector( 0, 5 );
  
  // Initialise default values for parameters
  paramVals.put( MidiParam.SEP, 100f );
  paramVals.put( MidiParam.ALI, 150f );                              // EDIT DEFAULT VALUES HERE
  paramVals.put( MidiParam.COH, 200f );
  
}


void controllerChange(int channel, int number, int value) 
{
  if ( printMidi )
  {
    println();
    println("Controller Change:");
    println("--------");
    println("Channel:"+channel);
    println("Number:"+number);
    println("Value:"+value);
  }

  MidiParam midiParam = midiMap.get( number );
  if ( midiParam != null )
  {
    println( "Got control for " + midiParam + " : " + value );
    setParam( midiParam, value );
  } else
  {
    println("Unrecognised CC val,  " + number + " : " + value );
  }
}

void setParam( MidiParam paramName, int val )
{
  
  float mappedVal = getMappedParamVal( paramName, val );
  paramVals.put( paramName, mappedVal );
  
}

float getMappedParamVal( MidiParam pName, int midiVal )
{
  return map( midiVal, 0, 127, paramRanges[pName.ordinal()].x, paramRanges[pName.ordinal()].y );
}

float getMidiFloat( MidiParam pName )
{
  return paramVals.get( pName );
}

int getMidiInt( MidiParam pName )
{
  return paramVals.get( pName ).intValue();
}



/*
void noteOn(int channel, int pitch, int velocity) 
 {
 if( printMidi )
 {
 println();
 println("Note On:");
 println("--------");
 println("Channel:"+channel);
 println("Pitch:"+pitch);
 println("Velocity:"+velocity);
 }
 }
 
 void noteOff(int channel, int pitch, int velocity) 
 {
 if( printMidi )
 {
 println();
 println("Note Off:");
 println("--------");
 println("Channel:"+channel);
 println("Pitch:"+pitch);
 println("Velocity:"+velocity);
 }
 }
 */
