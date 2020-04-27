float[] rgbToBuffer(float[] bufferArray, int type, int[] hilbertarray) {
  saturation = 0;
  if (type==0) {
    //downscaling without averaging
    //Skips pixels and disregards pixels in between
    int step = total/bsize;
    for (int k=0; k<bsize; k++) {
      bufferArray[k] = hilbertarray[k*step];  //scaling k up to map the 256x256 pixels and normalizing
      bufferArray[k]/=255;
      saturation +=bufferArray[k];
    }
    
    
  } else if (type == 1) {
    //divide up 1d rgb array to bsize and get average and apply as the amplitude
    //an 256x256 image will be divided up to bisze amounts (eg. image/256)
    int step = total/bsize;
    
    for (int k=0; k<bsize; k++) {
      float average = 0;
      for(int j=0; j<step; j++){
        average+=hilbertarray[k*step+j];   //summing up values
      }
      average/=step;     //dividing by step = average
      bufferArray[k] =average/255; //setting buffer as normalized value <0.2 ? 0.000:average/255
      //saturation +=0.0001f+bufferArray[k]*weights[k];  //Can be used to adjust gain depending on overall saturation 
      
    }
  }
  return bufferArray;
}
