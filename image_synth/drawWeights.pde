void drawWeights(){
  //Draws the weights applied to the frequencies' amplitudes
  rect(0,0,buffer.length*2, -130);
  fill(0,255,0);
  textSize(20);
  text("Amplitude Weights", 5,-130+20);
  noFill();
  //translate(0,100);
  if(noWeights){
    
  }else{
    beginShape();
  for(int j=0; j<weights.length; j++){
    curveVertex(j*2, -weights[j]*100);
  }
  endShape();
  }
  
}
