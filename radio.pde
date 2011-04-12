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

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

// GLOBAL CONTROLS
float f=0.0;			// current frequency [0..1]
float voldial=0.0;		// "volume" dial [0..1]
float vol=1.0;			// master volume 

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

        volume(v*vol);		// include "master volume"
        return v;
    }

    void volume(float v){
	// work w/ Volume control or Master Gain control

	float db = 10*log10(v*lingain);

	if(audio.hasControl(Controller.GAIN)){
	    // Master Gain
	    audio.setGain(db);
	} else {
	    // On laptop Volume is both 0-0xffff and "feels log"
	    audio.setVolume(constrain(0xffff+((db/12.0)*0xffff), 0, 0xffff));
	}

        if(false){
	    print(db);
	    print(" / ");
	    println(audio.getVolume());
        }
    }
}    

Station[] stations = {
    new Station(0.0, "static1.mp3", 1.0),
    new Station(0.1, "normalized1.mp3", 1.0),
    new Station(0.5, "normalized2.mp3", 1.0),
    new Station(0.8, "normalized3.mp3", 1.0)
    // new Station(0.1, "radio1.mp3", 1.0),
    // new Station(0.5, "radio2.mp3", 1.0),
    // new Station(0.8, "radio3.mp3", 1.0)
};

int dialPin=0;
int volPin=1;
int LEDPin=18;

void setup()
{
    size(512, 200, P2D);				// init display for debug
    minim = new Minim(this);			// ini audio library

    // talk to arduino in our "radio"
    arduino = new Arduino(this, Arduino.list()[0],57600);

    // make dial light flicker
    arduino.pinMode(LEDPin, Arduino.OUTPUT);
    arduino.digitalWrite(LEDPin, Arduino.HIGH);
    
    // load up our "stations" - and start playing them muted
    for(int i=0; i<stations.length; i++){
        stations[i].open();
        stations[i].volume(0.0);
	stations[i].audio.printControls();
    }
}

void dial(float freq){
  // set volumes based on "tuner frequency" [0.0, 1.0]
  float maxTune=0.0;
  for(int i=1; i<stations.length; i++){
      maxTune = max(stations[i].tune(f),maxTune);
  }

  // set the static level inversely
  float sgain = pow((1.0-maxTune),4);
  if(sgain<minLinearVolume) sgain=0;	// at some point turn off the static
  stations[0].volume(sgain * vol);
}

///////////////////////////////////////////////////////////////////////////////
// Graphics 
///////////////////////////////////////////////////////////////////////////////
int WIDTH=512;
int HEIGHT=200;


boolean mouseFlag=false;
boolean testing=false;
float flicker=0.5;
int flickerRate=0;

void draw()
{
    if(testing){
        f= (f+0.001) % 1.0;
        if(mouseFlag) f = (float) mouseX/(float) WIDTH;
    } else {
        // read dials from radio
        // Tuning dial goes from 0-685
        float nf=constrain(arduino.analogRead(0)/685.0, 0.0, 1.0);
        f += ((nf-f) * 0.1);	// lowpass sensor

        voldial=map(1023-arduino.analogRead(1), 0, 1020, 0.4, 1.0);
        vol=constrain(voldial, 0.4, 1.0);

        // and "flicker the dial LED for effect"
        if((flickerRate++%4)==0){
            arduino.digitalWrite(LEDPin,
                                 (noise(flickerRate) >=0.2)?Arduino.HIGH:Arduino.LOW);
        }
    }

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
