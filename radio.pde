/**
 * Radio
 * by scott - alcoholiday@gmail.com
 *  
 * simulate an oldtimey radio tuning into different channels
 *
 * For debugging, sketch will either just walk through frequency bands.
 * space-key will toggle "mouse input"
 *
 * In production, this takes "frequency" from some IO device (e.g. a dial)
 */

import ddf.minim.*;

Minim minim;

float minLinearVolume = 0.02;		// clamp less than this to zero
float inband=0.1;					// +- this value

float log10 (float x) {
  return (log(x) / log(10));
}

class Station {
    float chan;
    String fn;
    AudioPlayer audio;
    float lingain;
    float v;

    Station (float c, String file, float m) {
        chan=c;
        fn=file;
        lingain=m;
    }

    void open(){
        audio = minim.loadFile(fn, 2048);
        audio.loop();
        println(audio.getControls());
    }

    void close(){
        audio.close();
    }

    float tune(float f){
        float dist = min( abs(chan-f), inband );	// 0.0->1 when on-top of channel, inband->0

        v = 1.0 - (dist/inband);
        v = pow(v, 2);
        if(v<minLinearVolume) v=0.0;

        volume(v);
        return v;
    }

    void volume(float vol){
        v=vol;
        float db = 10*log10(v*lingain);
        audio.setGain(db);
        if(false){
            print(fn);
            print(" v: ");
            print(v);
            print(" gain: ");
            println(db);
        }
    }
}    

Station[] stations = {
    new Station(0.0, "static1.mp3", 0.7),
    new Station(0.1, "radio1.mp3", 1.0),
    new Station(0.5, "radio2.mp3", 1.0),
    new Station(0.8, "radio3.mp3", 1.0)
};

int WIDTH=512;
int HEIGHT=200;

void setup()
{
  size(512, 200, P2D);
  minim = new Minim(this);
  
  // load up our "stations" - and start playing them 
  for(int i=0; i<stations.length; i++){
      stations[i].open();
      stations[i].volume(0.0);
  }

}

void dial(float freq){
  // set volumes based on "tuner frequency" [0, 1]
  float maxTune=0.0;
  for(int i=1; i<stations.length; i++){
      maxTune = max(stations[i].tune(f),maxTune);
  }

  // set the static level inversly
  float sgain = pow((1.0-maxTune),4);
  if(sgain<minLinearVolume) sgain=0;	// at some point turn off the static
  stations[0].volume(sgain);
}

float f=0.0;		// current frequency
boolean mouseFlag=false;

void draw()
{
    
    f= (f+0.001) % 1.0;
    if(mouseFlag) f = (float) mouseX/(float) WIDTH;
    dial(f);
    
    // draw the volumes
    background(0);
    stroke(255);
    ellipse(f*WIDTH,10,10,10);
    
    for(int i=0; i<stations.length; i++){
        float lx = (stations[i].chan-inband) * WIDTH;	// left x of band
        float h = stations[i].v * HEIGHT;
        rect(lx, 20, inband*2.0*WIDTH, h);
        ellipse(stations[i].chan*WIDTH, 15, 5,5);
    }
}

void keyPressed() {
    if (key == 'm' || key == ' '){
        mouseFlag=!mouseFlag;
    }
}

void stop()
{
    // always close Minim audio classes when you are done with them
    for(int i=0; i<stations.length; i++) stations[i].close();
    minim.stop();
    super.stop();
}
