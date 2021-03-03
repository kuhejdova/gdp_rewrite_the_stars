import KinectPV2.*; //<>//

KinectPV2 kinect;

import processing.pdf.*;

boolean record;


String timestamp;

boolean contourBodyIndex = true;

int num_of_stars = 3001;
Star[] stars = new Star[num_of_stars];
Star[] staticStars = new Star[num_of_stars];

int counter = 0;
boolean clean = true;

Star brushStar;

color white = color(255, 255, 255);
color c1 = color(255, 255, 0);
color c2 = color(255, 170, 0);
color c3 = color(255, 70, 0);
color c4 = color(255, 0, 0);
color c5 = color(255, 200, 0);
color[] palette = {c1, c2, c3, c4, c5};

KJoint[] joints;

Star[] constellation = new Star[5];
PImage[] constellation_bs = new PImage[5];

PGraphics lineStars;
PImage blurredStar;


int counter_con = 0;

//-----------------------------------SETUP--------------------------------------------------------------------

void setup() {
  size(1024, 848, P3D);
  lineStars = createGraphics(1024, 848);
  kinect = new KinectPV2(this);

  kinect.enableBodyTrackImg(true);
  kinect.enableSkeletonColorMap(true); 

  timestamp = year() + "-" + minute() + "-" + millis();

  kinect.init();

  // load stars 0 constellation as position and constellation_bs as images of stars
  for (int i = 0; i < constellation.length; i++) {
    constellation[i] = new Star(int(random(30, 904)), int(random(30, 718)), c4, 255);
    constellation_bs[i] = loadImage("bs" + String.valueOf(i+1) +".png");
  }

  // generate random stars which defines body and background
  for (int i = 0; i < num_of_stars; i++) {
    if (i % 10 == 0) {
      stars[i] = new Star(int(random(512)), int(random(424)), palette[int(random(5))], int(random(180, 255)));
      staticStars[i] = new Star(int(random(512)), int(random(424)), palette[int(random(5))], int(random(255)));
    } else {
      stars[i] = new Star(int(random(512)), int(random(424)), white, int(random(180, 255)));
      staticStars[i] = new Star(int(random(512)), int(random(424)), white, int(random(255)));
    }
  }

  cleanupBrush();
}

//-------------------------------------------FUNCTIONS--------------------------------------------------------

class Pair {
  public int x, y;

  public Pair(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

int normalize(int val, int max) {
  if (val >= max) {
    return max-1;
  }
  if (val < 0) {
    return 0;
  }
  return val;
}

Pair getRandomBlackPixel(PImage body, int coef) {
  int tx = int(random(512/coef))*coef;
  int ty = int(random(424/coef))*coef;
  int c = 0;
  while (c < 50 && body.pixels[tx + body.width*ty] != color(0, 0, 0)) {
    c++;
    tx = int(random(512/coef))*coef;
    ty = int(random(424/coef))*coef;
  }
  return new Pair(tx, ty);
}


boolean isNearHand(KJoint a, Star s) {
  float xh = (a.getX()-300)*0.7;
  float yh = a.getY()*0.7;
  float xs = s.x;
  float ys = s.y;

  float dist = sqrt(pow(xh - xs, 2) + pow(yh - ys, 2));
  
  return dist < 50;
}


//loads joints from the SkeletonColorMap
void getSkeletonJoints() {
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();

  //individual JOINTS
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    if (skeleton.isTracked()) {
      joints = skeleton.getJoints();
    }
  }
}

//reset the drawing canvas
void cleanupBrush() {
  // active star
  brushStar = constellation[0];
  blurredStar = constellation_bs[0];

  // PGraphic canvas for constellation drawing
  lineStars.beginDraw();
  lineStars.clear();
  lineStars.background(color(0, 0, 0), 0);
  lineStars.fill(255, 0, 0, 100);
  lineStars.stroke(255, 0, 0, 100);
  lineStars.image(blurredStar, brushStar.x-blurredStar.width/2, brushStar.y-blurredStar.height/2);
  lineStars.endDraw();
}

//-----------------------------------------DRAW-------------------------------------------------


void draw() {
  
  if (record) {
    // Note that #### will be replaced with the frame number. Fancy!
    beginRecord(PDF, "Eva_Kuhejdova_final_project-" + timestamp + "-####.pdf"); 
  }
  
  background(0);

  noFill();
  strokeWeight(3);

  getSkeletonJoints();

  ArrayList<PImage> bodies = kinect.getBodyTrackUser();
  boolean foundBody = bodies.size() > 0;
  PImage body = foundBody ? bodies.get(0) : createImage(512, 424, RGB);
  PImage dst = createImage(body.width, body.height, ARGB);

  dst.loadPixels();
  body.loadPixels();

  // changes the color of the body map to black and white for easier work, white on body, black background
  for (int i = 0; i < body.width*body.height; i++) {
    if (body.pixels[i] < 100) {
      body.pixels[i] = color(255, 255, 255);
    } else {
      body.pixels[i] = color(0, 0, 0);
    }
  }

  // create the star sticking effect
  if (foundBody) {
    clean = false;
    for (int i = 0; i < stars.length; i++) {
      if (stars[i].onBody) {
        Pair t = getRandomBlackPixel(body, 1);
        stars[i].x = t.x;
        stars[i].y = t.y;
      } else if (body.pixels[stars[i].x + body.width*stars[i].y] == color(0, 0, 0)) {
        stars[i].onBody = true;
      } else if ((int) random(2) == 1) {
        Pair t = getRandomBlackPixel(body, 5);
        int dx = t.x - stars[i].x;
        int dy = t.y - stars[i].y;
        stars[i].x += dx/10;
        stars[i].y += dy/10;
      }
      dst.pixels[stars[i].x + body.width*stars[i].y] = stars[i].col;
    }
  } else {
    // when there was body and disapeared - cleanup
    if (!clean) {
      clean = true;
      for (int i = 0; i < stars.length; i++) {
        stars[i].reset();
        brushStar.catched = false;
        counter_con = 0;
        for (int j = 0; j < constellation.length; j++) {
          constellation[j] = new Star(int(random(10, 1014)), int(random(10, 838)), color(255), 255);
        }
        cleanupBrush();
      }
    }
  }
  for (int i = 0; i < staticStars.length; i++) {
    dst.pixels[staticStars[i].x + body.width*staticStars[i].y] = staticStars[i].col;
  }
  for (int i = 0; i < staticStars.length; i++) {
    staticStars[i].col = color(red(staticStars[i].col), green(staticStars[i].col), blue(staticStars[i].col), (alpha(staticStars[i].col) == 255 ? 151 : alpha(staticStars[i].col) + 1));
  }

  dst.updatePixels();
  image(dst, 0, 0, 1023, 848);

  // if the body is present
  try {
    KJoint jl = joints[KinectPV2.JointType_HandLeft];
    KJoint jr = joints[KinectPV2.JointType_HandRight];
    
    if (counter_con < constellation_bs.length-1 && brushStar.catched && (brushStar.hand ? jl : jr).getState() == KinectPV2.HandState_Closed && isNearHand((brushStar.hand ? jl : jr), constellation[counter_con+1])) {
      boolean h = brushStar.hand;
      lineStars.beginDraw();
      for (int i = 0; i < 5; i++) {
        lineStars.image(blurredStar, brushStar.x-blurredStar.width/2, brushStar.y-blurredStar.height/2);
      }
      lineStars.endDraw();
      brushStar = constellation[counter_con+1];
      blurredStar = constellation_bs[counter_con+1];
      brushStar.catched = true;
      brushStar.hand = h;
      counter_con++;
    }

    if (brushStar.catched && ((brushStar.hand ? jl : jr).getState() == KinectPV2.HandState_Closed)) {
      counter = 0;
    }
   
    if (!brushStar.catched && ((jl.getState() == KinectPV2.HandState_Closed && isNearHand(jl, brushStar)) || (jr.getState() == KinectPV2.HandState_Closed && isNearHand(jr, brushStar)))) {
      if (counter_con == 0) {
        counter_con++;
      }
      brushStar.catched = true;

      brushStar.hand = sqrt(pow((jl.getX()-300)*0.7 - brushStar.x, 2) + pow(jl.getY()*0.7 - brushStar.y, 2)) < sqrt(pow((jr.getX()-300)*0.7 - brushStar.x, 2) + pow(jr.getY()*0.7 - brushStar.y, 2));
      counter = 0;
    } 
    if (brushStar.catched && (brushStar.hand && jl.getState() == KinectPV2.HandState_Open) || (!brushStar.hand && jr.getState() == KinectPV2.HandState_Open)) {
      counter++;
      // 15 frames gap, because of inaccuracy when reading hand state
      if (counter > 15) {
        counter = 0;
        brushStar.catched = false;
      }
    }

    // actual drawing
    if (brushStar.catched) {
      lineStars.beginDraw();
      
      // magic translation to show star in hand
      int x = (int) (((brushStar.hand ? jl : jr).getX()-300)*0.7);
      int y = (int) ((brushStar.hand ? jl : jr).getY()*0.7);
      brushStar.x = x;
      brushStar.y = y;
      lineStars.tint(255, 70);
      lineStars.image(blurredStar, x-blurredStar.width/4, y-blurredStar.height/4, blurredStar.width/2, blurredStar.height/2);

      lineStars.endDraw();
      image(blurredStar, brushStar.x-blurredStar.width/2, brushStar.y-blurredStar.height/2);
    } else {
      image(blurredStar, brushStar.x-blurredStar.width/2, brushStar.y-blurredStar.height/2);
    }
    if (counter_con > 0 && counter_con < constellation_bs.length-1) {
      Star helpBrushStar = constellation[counter_con+1];
      PImage helpBlurredStar = constellation_bs[counter_con+1];
      image(helpBlurredStar, helpBrushStar.x-helpBlurredStar.width/2, helpBrushStar.y-helpBlurredStar.height/2);
    }
  } 
  catch(Exception e) {
    image(blurredStar, brushStar.x-blurredStar.width/2, brushStar.y-blurredStar.height/2);
  }
  image(lineStars, 0, 0);

  scale(2.0);
  if (record) {
      endRecord();
    record = false;
    }
}


void keyPressed() {
  if (key == 's' || key == 'S') saveFrame("Eva_Kuhejdova_final_project-" + timestamp + "-####.png");
  if (key == 'r' || key == 'R') record = true;
}
