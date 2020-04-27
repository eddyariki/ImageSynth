void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  //MIDI input for knobs, tuned for my AKAI LPD8
  equalizer[number-1] = value;
  int startIndex = number==1 ? 0:eqIndex[number-2];
  
  for(int i=startIndex;i<eqIndex[number-1];i++){
      weights[i] = map(float(value),0,127,0,1.0);
  }
}
