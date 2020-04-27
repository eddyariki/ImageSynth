void redrawHilbert(PImage image){
  //Draws the hil
  beginShape(POINTS);
  for (int k=0; k<255; k++) {
    for (int j=0; j<255; j++) {
      stroke(image.get(int(path[j+k*256].x), int(path[j+k*256].y)));
      vertex(j, k);
    }
  }
  
  endShape();
  stroke(0,255,0);
  noFill();
  rect(0,0,256,256);
}
