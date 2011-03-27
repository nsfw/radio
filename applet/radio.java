import processing.core.*; 
import processing.xml.*; 

import ddf.minim.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class radio extends PApplet {

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



Minim minim;

float minLinearVolume = 0.02f;		// clamp less than this to zero
float inband=0.1f;					// +- this value

public float log10 (float x) {
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

    public void open(){
        audio = minim.loadFile(fn, 2048);
        audio.loop();
        println(audio.getControls());
    }

    public void close(){
        audio.close();
    }

    public float tune(float f){
        float dist = min( abs(chan-f), inband );	// 0.0->1 when on-top of channel, inband->0

        v = 1.0f - (dist/inband);
        v = pow(v, 2);
        if(v<minLinearVolume) v=0.0f;

        volume(v);
        return v;
    }

    public void volume(float vol){
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
    new Station(0.0f, "static1.mp3", 0.7f),
    new Station(0.1f, "radio1.mp3", 1.0f),
    new Station(0.5f, "radio2.mp3", 1.0f),
    new Station(0.8f, "radio3.mp3", 1.0f)
};

public void setup()
{
    size(512, 200, P2D);				// init display
    minim = new Minim(this);			// ini audio library
    
    // load up our "stations" - and start playing them muted
    for(int i=0; i<stations.length; i++){
        stations[i].open();
        stations[i].volume(0.0f);
    }
}

public void dial(float freq){
  // set volumes based on "tuner frequency" [0.0, 1.0]
  float maxTune=0.0f;
  for(int i=1; i<stations.length; i++){
      maxTune = max(stations[i].tune(f),maxTune);
  }

  // set the static level inversely
  float sgain = pow((1.0f-maxTune),4);
  if(sgain<minLinearVolume) sgain=0;	// at some point turn off the static
  stations[0].volume(sgain);
}

///////////////////////////////////////////////////////////////////////////////
// Graphics 
///////////////////////////////////////////////////////////////////////////////

float f=0.0f;		// current frequency
boolean mouseFlag=false;
int WIDTH=512;
int HEIGHT=200;

public void draw()
{
    
    f= (f+0.001f) % 1.0f;
    if(mouseFlag) f = (float) mouseX/(float) WIDTH;
    dial(f);
    
    // draw the volumes
    background(0);
    stroke(255);
    ellipse(f*WIDTH,10,10,10);
    
    for(int i=0; i<stations.length; i++){
        float lx = (stations[i].chan-inband) * WIDTH;	// left x of band
        float h = stations[i].v * HEIGHT;
        rect(lx, 20, inband*2.0f*WIDTH, h);
        ellipse(stations[i].chan*WIDTH, 15, 5,5);
    }
}

public void keyPressed() {
    if (key == 'm' || key == ' '){
        mouseFlag=!mouseFlag;
    }
}

public void stop()
{
    // always close Minim audio classes when you are done with them
    for(int i=0; i<stations.length; i++) stations[i].close();
    minim.stop();
    super.stop();
}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#c0c0c0", "radio" });
  }
}
