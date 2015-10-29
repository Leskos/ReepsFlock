// The Boid class

class Boid 
{

  Flock   myFlock;

  PVector location;
  PVector velocity;
  PVector acceleration;

  float   r;
  float   maxforce;    // Maximum steering force
  float   maxspeed;    // Maximum speed

  float   a     = 1*PI/2;    // RENAME THIS
  float   pathB = 125;       // RENAME THIS

  float   B       = 20;      // RENAME THIS
  float   centerB = 135;     // RENAME THIS

  int     id;                // NOT USED?
  float   greyScale = 0;

  float   accelerationWeight = 1;
  float   velocityWeight     = 1;

  int numTrails   = 10;
  int trailIndex  = 0;
  float xTrails[] = new float[ numTrails ];
  float yTrails[] = new float[ numTrails ];


  //--------------------------------------------------------------------------
  Boid( Flock initFlock, float x, float y, int boidNum ) 
  {

    id = boidNum;
    myFlock = initFlock;

    acceleration = new PVector(0, 0);
    velocity     = PVector.random2D();
    location     = new PVector(x, y);

    r = randomGaussian();
    float sd = 3;
    float mean = 0.05;
    r = (r*sd)+mean;
    if (r<0)
    { 
      r = random(0.5, 2);
    }   

    maxspeed = random(2,5);
    maxforce = random(0.1,0.8);
    greyScale = map(r, 0, 10, 255, 155);

    //r = id*0.1;
  }


  //--------------------------------------------------------------------------
  void run() 
  {
    flock( myFlock.boids );
    update();
    //render();
  }


  //--------------------------------------------------------------------------
  void applyForce(PVector force) 
  {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }


  //--------------------------------------------------------------------------
  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) 
  {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    PVector tar = seekTargets();

    // Arbitrarily weight these forces
    sep.mult(myFlock.separationWeight);
    ali.mult(myFlock.alignmentWeight);
    coh.mult(myFlock.cohesionWeight);
    acceleration.mult(myFlock.accelerationWeight);

    // Add the force vectors to acceleration
    applyForce( sep );
    applyForce( ali );
    applyForce( coh );
    applyForce( tar );

  }


  //--------------------------------------------------------------------------
  // Method to update location
  void update() 
  {
    // Update position
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    location.add(velocity);

    // Reset acceleration to 0 each cycle
    acceleration.mult(0);

    /*
    OscMessage boidInfo = new OscMessage("/boid");
     boidInfo.add(location.x);
     boidInfo.add(location.y);
     boidInfo.add(id);
     boidInfo.add(velocity.mag());
     oscP5.send(boidInfo, SCAddress);
     */
     
    //checkBoundaryNonTorroidal();
    boundaryWraparound();
    //boundaryBounce();

    trailIndex = frameCount % numTrails;

    xTrails[ trailIndex ] = location.x;
    yTrails[ trailIndex ] = location.y;
  }



  //--------------------------------------------------------------------------
  // constrain movement to the page - we've drawn a little fence inside the canvas so you can see what's going on at the edges
  void boundaryBounce() 
  {
    
    if ( location.x > width-10 ) 
    {
      velocity.x = velocity.x * -10;
      location.x = width-10;
    }
    
    if ( location.x < 10 ) 
    {
      velocity.x = velocity.x * -10;
      location.x = 10;
    }
    

    if ( location.y > height-10 ) 
    {
      velocity.y = velocity.y * -10;
      location.y = height-10;
    }
    
    if ( location.y < 10 ) 
    {
      velocity.y = velocity.y * -10;
      location.y = 10;
    }
    
  }

  void boundaryWraparound() 
  {
    if ( location.x > width ) 
    {
      location.x = 0;
    }
    if ( location.x < 0 ) 
    {
      location.x = width;
    }

    if ( location.y > height ) 
    {
      location.y = 0;
    }

    if ( location.y < 0 ) 
    {
      location.y = height;
    }
  }



  PVector seekTarget( FlockingTarget targetToSeek )
  {
    PVector desired = PVector.sub( targetToSeek.targetPos, location );  // A vector pointing from the location to the target

    if ( Math.abs(desired.mag()) < targetToSeek.targetRadius )
    {
      // Scale to maximum speed
      desired.setMag(maxspeed);

      // Steering = Desired minus Velocity
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxforce);  // Limit to maximum steering force  

        steer.mult( targetToSeek.targetStrength );

      return steer;
    } else
    {
      return new PVector(0, 0, 0);
    }
  }

  void render() 
  {
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up

    pathB=centerB+B*sin(a);
    a=a+.03;


    noStroke();
    fill(greyScale, pathB);
    smooth();

    for ( int i=0; i<numTrails; i++ )
    {
      int index = (trailIndex+1 + i) % numTrails;

      pushMatrix();
      translate( xTrails[i] , yTrails[i]);
      rotate(theta);
      rect(0, r, -r*4, -r);
      popMatrix();
    }

  }


  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) 
  {
    //float desiredseparation = map(r, 0.1, 10, 50, 150);

    float desiredseparation = 50;

    PVector steer = new PVector(0, 0, 0);
    int count = 0;

    // For every boid in the system, check if it's too close
    for (Boid other : boids) 
    {
      float d = PVector.dist(location, other.location);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      //if ((d > 0) && ( d < myFlock.separationDistance )) 
      if ((d > 0) && ( d < desiredseparation)) 
      {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }


    /*
    OscMessage boidInfo = new OscMessage("\boid");
     boidInfo.add(avgDistance);
     oscP5.send(boidInfo, SCAddress);
     */

    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) 
  {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) 
    {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < myFlock.alignmentDistance )) 
      {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) 
    {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } else 
    {
      return new PVector(0, 0);
    }
  }



  // Cohesion
  // For the average location (i.e. center) of all nearby boids, calculate steering vector towards that location
  PVector cohesion (ArrayList<Boid> boids) 
  {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : boids) 
    {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < myFlock.cohesionDistance) ) 
      {
        sum.add(other.location); // Add location
        count++;
      }
    }
    if (count > 0) 
    {
      sum.div(count);
      return seek(sum);  // Steer towards the location
    } else 
    {
      return new PVector(0, 0);
    }
  }

  PVector seekTargets ( ) 
  {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;

    for ( int i=0; i< myFlock.targets.size (); i++ )
    {
      sum.add( seekTarget( myFlock.targets.get(i) ) );
      count += 1;
    }

    if ( count > 0 )
    {
      sum.div( count );
      return sum;
    } else
    {
      return sum;
    }
  }



  boolean sketchFullScreen() 
  {
    return true;
  }

  PVector seek( PVector target )
  {
    return seek( target, 1000000 );
  }


  //--------------------------------------------------------------------------
  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek( PVector target, float targetDistance ) 
  {
    PVector desired = PVector.sub(target, location);  // A vector pointing from the location to the target

    if ( Math.abs(desired.mag()) < targetDistance )
    {
      // Scale to maximum speed
      desired.setMag(maxspeed);

      // Steering = Desired minus Velocity
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxforce);  // Limit to maximum steering force  
      return steer;
    } else
    {
      return new PVector(0, 0, 0);
    }
  }
}
