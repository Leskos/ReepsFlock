import blobDetection.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
PImage cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;

float x = 100;   // x location of square
float y = 0;     // y location of square
float speed = 0;   // speed of square
float gravity = 0.1;  



void setupKinect()
{
  // initialize SimpleOpenNI object
  context = new SimpleOpenNI(this);
  if (context.isInit()==false) 
  {
    // if context.enableScene() returns false
    println("Kinect not connected!");
    exit();
    return;
  } 
  
  // don't mirror the image because it'll be a projection behind the performer
  context.setMirror(false);
  context.enableDepth();
  context.enableUser();  

  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage( 80, 60 ); 
  theBlobDetection = new BlobDetection( img.width, img.height );
  theBlobDetection.setPosDiscrimination( true );
  theBlobDetection.setThreshold( 0.2f ); // will detect bright areas whose luminosity > 0.2f;
}


void drawKinect()
{
  // KINECT
  context.update();
  // put the image into a PImage
  cam = context.userImage();
  cam.loadPixels();
  color black = color(0, 0, 0, 0);
  
  
  // filter out grey pixels (mixed in depth image)
  for (int i=0; i<cam.pixels.length; i++)
  { 
    color pix = cam.pixels[i];
    int blue = pix & 0xff;
    if (blue == ((pix >> 8) & 0xff) && blue == ((pix >> 16) & 0xff))
    {
      cam.pixels[i] = black;
    }
  }
  
  cam.updatePixels(); 

  //image(cam, 0, 0, width, height);
  img.copy(cam, 0, 0, cam.width, cam.height, 0, 0, img.width, img.height);
  fastblur(img, 2);
  theBlobDetection.computeBlobs(img.pixels);
  drawBlobsAndEdges(false, true);
  
}



int getNumBlobs()
{
  return theBlobDetection.getBlobNb ();
}

boolean blobExists( int blobIndex )
{
   Blob b = theBlobDetection.getBlob( blobIndex );
   return ( b!=null );
}


FlockingTarget[] getTargetsFromBlob( int blobIndex )
{
  // MUST BE AT LEAST 2, ANYTHING ELSE RETURNS EXTRA OUTLINE TARGETS
   int numTargetsToReturn = 30;
  
   Blob b = theBlobDetection.getBlob( blobIndex );
   
   FlockingTarget[] returnedTargets = new FlockingTarget[ numTargetsToReturn ];
   
   if( b!= null )
   {
      // GET CENTER OF BLOB
      float xCenter = b.xMin*width  + (( b.w*width  )/2);
      float yCenter = b.yMin*height + (( b.h*height )/2);
      
        // CREATE TARGET IN CENTER WITH MASSIVE RANGE AND SMALL POSITIVE ATTRACTION FORCE
      returnedTargets[0] = new FlockingTarget( new PVector(xCenter, yCenter), 20000, 2 );
      
      // FILL THE REST OF THE TARGETS ARRAY
      for( int i=1; i< returnedTargets.length; i++ )
      {        
        // CREATE TARGETS ON OUTLINE WITH SMALL RANGE AND POWERFUL NEGATIVE ATTRACTION FORCE
        returnedTargets[i] = new FlockingTarget( getPointOnBlobOutline( blobIndex ), 100, -50 );
      }
   }
   else
   {
     returnedTargets[0] = new FlockingTarget( new PVector( width/2, height/2), 0, 0 );
   }
   
   return returnedTargets;
}


PVector getPointOnBlobOutline( int blobIndex )
{  
   Blob b = theBlobDetection.getBlob( blobIndex );
   
   // INITIALISE THIS TO A POINT OFFSCREEN
   PVector outlinePoint = new PVector( width/2, width/2 );
   
   if( b!= null )
   {
      int randomEdge = (int)random( b.getEdgeNb() );
      EdgeVertex randomVertex = b.getEdgeVertexA( randomEdge );
      
      outlinePoint.x = randomVertex.x * width;
      outlinePoint.y = randomVertex.y * height;
   }
   else
   {
     outlinePoint = new PVector(width/2,height/2);
   }
   
   return outlinePoint;
}



// ==================================================
// drawBlobsAndEdges()
// ==================================================
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  
  // FOR EACH BLOB
  for (int n = 0; n<theBlobDetection.getBlobNb (); n++)
  {
    
    b = theBlobDetection.getBlob(n);
    
    // IF IT EXISTS
    if (b!=null)
    {
      // Edges
      if (drawEdges)
      {
        strokeWeight(3);
        stroke(255, 255, 255, 40);
        
        // FOR EACH EDGE
        for ( int m=0; m<b.getEdgeNb (); m++ )
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null)
            line(
            eA.x*width, eA.y*height, 
            eB.x*width, eB.y*height
              );
        }
      }
  
      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        
        rect(
        b.xMin*width, b.yMin*height, 
        b.w*width, b.h*height
          );
      }
    }
  }
}



// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img, int radius)
{
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0; i<256*div; i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0; y<h; y++) {
    rsum=gsum=bsum=0;
    for (i=-radius; i<=radius; i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0; x<w; x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0; x<w; x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius; i<=radius; i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0; y<h; y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}
