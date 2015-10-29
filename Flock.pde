// The Flock (a list of Boid objects)
class Flock 
{
  ArrayList<Boid> boids; // An ArrayList for all the boids
  
  ArrayList<FlockingTarget> targets;


  int minBoids = 0;
  int maxBoids = 50;
  int distThresh = 300;
  
  float separationWeight;
  float alignmentWeight;
  float cohesionWeight;
  
  float separationDistance = 100;
  float alignmentDistance  = 150;
  float cohesionDistance   = 200;
  
  float accelerationWeight;
  float velocityWeight;

  int boidNumber = 0;


  Flock() 
  {
    boids   = new ArrayList<Boid>(); // Initialize the ArrayList
    targets = new ArrayList<FlockingTarget>();
  }

  void run() 
  {
    //separationWeight = getMidiFloat( MidiParam.SEP );
    //alignmentWeight  = getMidiFloat( MidiParam.ALI );
    //cohesionWeight   = getMidiFloat( MidiParam.COH );
    
    synchronized(boids)
    {
      for (Boid b : boids) 
      {
        b.run();  // Passing the entire list of boids to each boid individually
        
        drawLinesToTargets( b );
      }
    }
  }
  
  void drawLinesToTargets( Boid b )
  {
    
    int sWeight = 1;
    int sColour = 255;
    int sAlpha  = 100;
    
    strokeWeight( sWeight );
    stroke( sColour, sAlpha );
    for( FlockingTarget t : targets )
    {
      float d = dist(b.location.x, b.location.y, t.targetPos.x, t.targetPos.y); 
      if( d < distThresh )
      {
        stroke( sColour, map( d, 0, distThresh, 255, 0 ) );
        line( b.location.x, b.location.y, t.targetPos.x, t.targetPos.y );
      }
    }
  }

  void addBoid( int x, int y ) 
  {
    synchronized(boids) 
    {
      if( boids.size() < maxBoids )
      {
        Boid b = new Boid( this, x, y, boidNumber );
        boidNumber ++;
        boids.add(b);
        
        if( boids.size() == maxBoids )
        {
          removeBoids( 1 );
        }
        
      }
    }
  }
  
  void removeBoids( int numBoids ) 
  {
    synchronized(boids) 
    {
      for( int i=0; i < numBoids; i++ )
      {
        if( boids.size() > minBoids )
        {
          boids.remove( 0 );
        }
        else
        {
          break;
        }
      }
    }
  }
  
  
  void clearTargets()
  {
    targets.clear();
  }
  
  void addTarget( FlockingTarget targetToAdd )
  {
    targets.add( targetToAdd );
  }
  
}
