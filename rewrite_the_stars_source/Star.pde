class Star {
  public int x, y, sx, sy;
  public boolean onBody = false;
  public color col = color(255,255,255, 255);
  public int radius = 0;
  public boolean flag = true;
  public boolean catched = false;
  public boolean hand; // left is true

  public Star(int x, int y, color col, int alpha) {
    this.x = x;
    this.y = y;
    this.sx = x;
    this.sy = y;
    this.col = color(red(col), green(col), blue(col), alpha);
  }
  
  public void setRadius(int r){
    this.radius = r;
  }
  
  public void updateColorAlpha(color c){
    this.col = c;
  }

  public void reset() {
    x = sx;
    y = sy;
    onBody = false;
  }
}
