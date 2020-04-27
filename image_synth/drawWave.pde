void drawWaveForm() {
  //Draws the frequencies
  fill(0);
  rect(0, 0, buffer.length*2, -130);
  fill(0,255,0);
  textSize(20);
  text("Frequencies", 5,-130+20);
  noFill();
  beginShape();
  noFill();
  stroke(0, 255, 0);
  for (int i = 0; i < buffer.length; i++)
  {
    curveVertex(i*2, -buffer[i]*100);
  }
  endShape();
  
}
