/*
Audio spectrum analyzer for android devices
12 may 2013
David Sanz Kirbis

This is a remix of a lot of code and info.

Basically adapted some of the minim analysis code to use the FFT with
android audio recorder.
https://github.com/ddf/Minim/tree/master/src/ddf/minim/analysis

More info:

setting up android & processing:
http://wiki.processing.org/w/Android
http://developer.android.com/sdk/index.html#ExistingIDE
http://developer.android.com/sdk/installing/index.html

http://forum.processing.org/topic/microphone-on-android

android specific
http://stackoverflow.com/questions/5774104/android-audio-fft-to-retrieve-specific-frequency-magnitude-using-audiorecord
http://www.androidcookbook.info/android-media/visualizing-frequencies.html

fft generic:
http://stackoverflow.com/questions/4633203/extracting-precise-frequencies-from-fft-bins-using-phase-change-between-frames
http://www.dsprelated.com/showmessage/18389/1.php
dsp.stackexchange.com/questions/2121/i-need-advice-about-how-to-make-an-audio-frequency-analyzer
https://en.wikipedia.org/wiki/Log-log_plot
            
*/

import java.util.ArrayList;
import android.media.AudioRecord;
import android.media.AudioFormat;
import android.media.MediaRecorder;


int       RECORDER_SAMPLERATE = 44100;
int       MAX_FREQ = RECORDER_SAMPLERATE/2;
final int RECORDER_CHANNELS = AudioFormat.CHANNEL_IN_MONO;
final int RECORDER_AUDIO_ENCODING = AudioFormat.ENCODING_PCM_16BIT;
final int PEAK_THRESH = 20;

short[]     buffer           = null;
int         bufferReadResult = 0;
AudioRecord audioRecord      = null;
boolean     aRecStarted      = false;
int         bufferSize       = 2048;
int         minBufferSize    = 0;
float       volume           = 0;
FFT         fft              = null;
float[]     fftRealArray     = null;
int         mainFreq         = 0;

float       drawScaleH       = 4.5; // TODO: calculate the drawing scales
float       drawScaleW       = 1.0; // TODO: calculate the drawing scales
int         drawStepW        = 2;   // display only every Nth freq value
float       maxFreqToDraw    = 2500; // max frequency to represent graphically
int         drawBaseLine     = 0;

float[][] ranges = {{0.24174846499999997, 1.063049581}, {0.390721092, 0.9247542900000001}, {0.294938952, 0.779380456}, {2.166810642, 4.07838142}, {3.8541056169999997, 8.569917033}, {2.7061508020000002, 7.440803970000001}, {1.5496060569999999, 4.470211479}, {2.101616828, 5.600769922}, {1.624575417, 5.274459007}, {1.3305809870000003, 3.687635793}, {1.5020647550000001, 3.4416042090000003}, {0.8545213969999998, 2.997771107}, {1.0729991950000002, 3.748736813}, {1.074112174, 3.751576236}, {0.729432705, 3.8459083310000004}, {0.906284525, 3.471614419}, {0.3817169520000001, 2.140345442}, {0.0627763280000001, 1.7484653}, {0.07159353700000004, 1.558064973}, {0.048856031999999994, 1.087802502}, {0.15349148900000004, 0.840934605}, {0.20992993199999999, 0.834232312}, {0.10104818700000001, 0.606452813}, {-0.010099004000000023, 0.6038301580000001}, {-0.00782770300000002, 0.501928307}, {0.033175747000000005, 0.343232479}, {0.095835008, 0.508143498}, {0.137175339, 0.704705879}, {0.161799721, 0.7194958549999999}, {0.13027112100000002, 0.543594849}, {0.10488041499999998, 0.47016165099999996}, {0.11118144500000002, 0.437732931}, {0.12983730000000002, 0.521696752}, {0.15643287, 0.737807826}, {0.133531461, 0.520536853}, {0.088469269, 0.276715767}, {0.083397235, 0.272678251}, {0.10550569200000001, 0.27497413800000003}, {0.075388963, 0.286495415}, {0.07587763000000002, 0.296312146}, {0.05734545500000002, 0.323476623}, {0.07651144200000001, 0.30801394000000004}, {0.08874458399999999, 0.58508055}, {0.08700958700000003, 0.502133301}, {0.061161218, 0.24471169399999998}, {0.059100880999999994, 0.226518043}, {0.05721564400000001, 0.193323986}, {0.038360021999999994, 0.16692335}, {0.031540281, 0.124479689}, {0.021548282000000002, 0.13009661}, {0.020415281, 0.127602575}, {0.026013767, 0.094386833}, {0.032642182, 0.126386136}, {0.015141422999999994, 0.125496621}, {0.018360071, 0.087882145}, {0.012285457000000007, 0.08166179900000001}, {0.014896157, 0.07305693099999999}, {0.02072778, 0.090596246}, {0.022137351, 0.112770757}, {0.022798872999999997, 0.099021467}, {0.020845436000000002, 0.09541176400000001}, {0.023684749999999997, 0.10699977399999999}, {0.025039328999999992, 0.12329631299999999}, {0.023642191, 0.10451707299999999}, {0.010991813999999996, 0.088847378}, {0.020422506, 0.091624928}, {0.024032057000000003, 0.095615741}, {0.017640206999999998, 0.086637893}, {0.017148260999999998, 0.069850411}, {0.010372994, 0.061595272000000006}, {0.017901838, 0.05605597}, {0.018760825000000002, 0.06988551300000001}, {0.016282567999999997, 0.059399594}, {0.016956461000000003, 0.059778975}, {0.016354618, 0.071458752}, {0.016722273000000003, 0.080574583}, {0.018818795, 0.091147769}, {0.023639479, 0.083723405}, {0.015030934000000003, 0.06332602000000001}, {0.011680536999999998, 0.074692325}, {0.018437603999999996, 0.095617852}, {0.024051972000000005, 0.090794998}, {0.018369351, 0.06855159699999999}, {0.017321278, 0.072378868}, {0.014269432000000006, 0.081549324}, {0.010021623, 0.087482847}, {0.017875444000000004, 0.087140226}, {0.014828809999999998, 0.072781082}, {0.017961516000000004, 0.055541052}, {0.017236691, 0.057433575}, {0.01873725, 0.061815858}, {0.011299124, 0.060867206}, {0.010492247, 0.053738721}, {0.014307159, 0.056316459}, {0.02221752, 0.06824988}, {0.016321743000000003, 0.061957253000000004}, {0.012421468, 0.03936822}, {0.011562158999999999, 0.039356880999999996}, {0.009582384000000003, 0.05396271800000001}, {0.019206896999999997, 0.059990299}, {0.019137072, 0.057502234}, {0.011399765, 0.049182787}, {0.010428970000000003, 0.056816808}, {0.013390327, 0.06940238700000001}, {0.019100775999999996, 0.071976352}, {0.016844832, 0.066692884}, {0.014153990000000002, 0.048670519999999995}, {0.012440073999999995, 0.051283654}, {0.013788032999999998, 0.07263766699999999}, {0.018804273, 0.079577279}, {0.016793897, 0.059248000999999995}, {0.014848297000000002, 0.041886093}, {0.00963487, 0.049055554}, {0.012999528, 0.054800334000000006}, {0.008793744000000003, 0.054303218}, {0.012302908000000001, 0.057032074}, {0.013297602000000002, 0.063030794}, {0.016856587000000003, 0.051834775}, {0.014966110999999997, 0.049652889}, {0.008101610999999998, 0.059722199000000004}, {0.015214668, 0.063798988}, {0.017131686, 0.060984558}, {0.020207647999999998, 0.05769742}, {0.02325745, 0.0558772}, {0.014250788, 0.050732872}, {0.009268358999999997, 0.058318241}, {0.012923751000000004, 0.071329279}, {0.013386465, 0.073403093}, {0.013038922000000001, 0.065787352}, {0.011423257999999999, 0.051100612}, {0.011655074000000001, 0.043571434}, {0.01022048, 0.045765650000000005}, {0.010475822, 0.05010832}, {0.005774524999999999, 0.051273705}, {0.007925949999999998, 0.042586968}, {0.00852603, 0.03470117}, {0.0072298959999999995, 0.035199778}, {0.008193948, 0.032943636}, {0.008477103000000001, 0.028488915000000004}, {0.006965973000000002, 0.029757137000000003}, {0.007333270999999999, 0.033548288999999995}, {0.009990785, 0.030878588999999998}, {0.009704445999999999, 0.03828148}, {0.011500133999999999, 0.038054608000000004}, {0.00963346, 0.030692004}, {0.007100506000000001, 0.027116184}, {0.006236374000000001, 0.024116824000000002}, {0.004887826, 0.024385308}, {0.008620274999999998, 0.027167783}, {0.0072042189999999996, 0.028650687}, {0.005017808999999998, 0.030516321}, {0.005108085, 0.027888053000000003}, {0.007633055, 0.028453435}, {0.007779552, 0.026793935999999997}, {0.007485779000000001, 0.025204291}, {0.007606228999999999, 0.025759630999999998}, {0.007013057999999999, 0.029842022}, {0.005996883999999999, 0.034608994}, {0.007595856, 0.028764650000000003}, {0.009459741, 0.029734929}, {0.010548942, 0.036249542}, {0.00749171, 0.034539446}, {0.006371453999999999, 0.025095052}, {0.004397295000000001, 0.030076881}, {0.003222102000000001, 0.029739194}, {0.007224721999999998, 0.02718794}, {0.006351753999999999, 0.035076605999999996}, {0.008714521999999999, 0.041328722}, {0.011299376, 0.042000044}, {0.010622873000000001, 0.049000429}, {0.010331186, 0.04481309}, {0.010803874000000002, 0.036378426000000005}, {0.008185030999999999, 0.026737727}, {0.008071118999999998, 0.023274845}, {0.006930048000000001, 0.029316004}, {0.005993891999999999, 0.027981387999999996}, {0.0039005079999999987, 0.025927172}, {0.003651072, 0.027028499999999997}, {0.0034001429999999996, 0.022098108999999998}, {0.005087916, 0.023130974}, {0.006243549999999999, 0.027500827999999998}, {0.006120535, 0.027991567}, {0.004602559999999999, 0.026724288}, {0.006292408999999999, 0.029967597}, {0.005663534, 0.030753306}, {0.004151953999999999, 0.032535054}, {0.003996138, 0.033947387999999995}, {0.0069998130000000006, 0.033175753}, {0.008441237999999998, 0.025974506}, {0.007123345000000001, 0.025824714999999998}, {0.004202557999999999, 0.027739032}, {0.004959950000000001, 0.02735003}, {0.005375072999999999, 0.027017185}, {0.0062728820000000005, 0.028800684}, {0.005606378, 0.025483012}, {0.005521574, 0.022217295999999997}, {0.004932998000000001, 0.02245867}, {0.006091035999999999, 0.023229109999999997}, {0.006994849000000001, 0.020844187}, {0.0068838120000000004, 0.021613096000000002}, {0.0058715619999999994, 0.020951064}, {0.005815502, 0.01853898}, {0.004020912, 0.020097114}, {0.0052885580000000005, 0.021320053999999998}, {0.006506459000000001, 0.020610819000000002}, {0.005988988999999999, 0.020865447}, {0.005352407, 0.021464731}, {0.006990596, 0.023005593999999997}, {0.006719335, 0.022570111}, {0.004618148000000001, 0.019234170000000002}, {0.003876639000000001, 0.020396259}, {0.005277883000000001, 0.022477523}, {0.006334287000000001, 0.024472713}, {0.005010409, 0.025559413}, {0.004024327999999999, 0.027246213999999998}, {0.005119249000000001, 0.025558137}, {0.005224416, 0.019026936}, {0.005023629, 0.014997325}, {0.005477264, 0.016534046}, {0.00419998, 0.0147772}, {0.0037752870000000004, 0.014956233000000001}, {0.005478416999999999, 0.018486677}, {0.006139415, 0.018147177}, {0.005554166, 0.018461516}, {0.0057639399999999995, 0.017890696}, {0.006544276000000001, 0.020381436}, {0.005404293999999999, 0.024033119999999998}, {0.006206872, 0.020348784}, {0.004107728, 0.020072491999999997}, {0.005546110999999999, 0.020756831}, {0.006133228, 0.017420848}, {0.004821012, 0.016448604000000002}, {0.005969894999999999, 0.016237187}, {0.005614411, 0.017154505}, {0.006312898, 0.01457971}, {0.003923068, 0.017858932}, {0.004589113000000001, 0.019631891}, {0.0061633750000000005, 0.020515329}, {0.006590218, 0.019997941999999998}, {0.006393141, 0.019849106999999998}, {0.0034468039999999995, 0.019234177999999998}, {0.005315823999999999, 0.018312836}, {0.007024631, 0.017638529}, {0.006044028, 0.017694958}, {0.005640704999999999, 0.019790617}, {0.005564337999999999, 0.019151398}, {0.004263318, 0.017918405999999998}, {0.005702392, 0.018272234}, {0.006792432000000001, 0.019154502}, {0.004298135, 0.020620277}, {0.004222785999999999, 0.020911414}, {0.0046156850000000004, 0.019215567}, {0.004935481, 0.018721435}, {0.004938188999999999, 0.020393873}, {0.004969758, 0.020172604}, {0.005583359, 0.016821121}, {0.005131168, 0.018286768000000002}, {0.004974402, 0.016804348}, {0.004797001999999999, 0.016312652}, {0.006215531000000001, 0.016037155}, {0.006076730000000001, 0.016309136000000002}, {0.0047370039999999995, 0.01793572}, {0.005711953, 0.017993663}, {0.0029059359999999996, 0.02267036}, {0.004297525999999999, 0.0243285}, {0.005360462000000002, 0.021397845999999998}, {0.004595899, 0.018132943}, {0.0035709120000000007, 0.016781532000000002}, {0.003953465000000001, 0.016569663000000002}, {0.004959165, 0.018563689}, {0.005473231, 0.018255763}, {0.004898770000000001, 0.017639232}, {0.005422575000000001, 0.017330031000000003}, {0.004292375, 0.017516583}, {0.004086572, 0.016824994}, {0.005169217999999999, 0.017300456}, {0.004538596, 0.018445326}, {0.005482638, 0.016779082}, {0.004810811, 0.017066184999999998}, {0.0041362510000000005, 0.018244659}, {0.004528284999999999, 0.017457221}, {0.006219299000000001, 0.018248441}, {0.0064569399999999996, 0.019139862}, {0.003371113000000001, 0.018666051}, {0.0040140259999999995, 0.017301999999999998}, {0.003643696, 0.017467966}, {0.005802918000000001, 0.019398788}, {0.004921525, 0.019880615}, {0.003073226, 0.019306172000000003}, {0.004248466000000001, 0.019770858000000002}, {0.0036308210000000002, 0.019161099}, {0.0029603200000000007, 0.02099537}, {0.004454783, 0.022850971}, {0.006053645999999999, 0.022088588}, {0.004619598000000001, 0.020574072}, {0.004375828, 0.017813456}, {0.002547786, 0.01963452}, {0.006022846000000001, 0.019016432}, {0.004552724, 0.019285172}, {0.005284204999999999, 0.018519169}, {0.006334708999999999, 0.019393018999999997}, {0.005726323, 0.020016461}, {0.003989205, 0.017619233}, {0.005199773, 0.017035717}, {0.004606703, 0.017370811}, {0.005648738, 0.019628382}, {0.0056178370000000005, 0.021933199}, {0.005675283, 0.019335571}, {0.004321692999999999, 0.018069675}, {0.005461298, 0.019120642}, {0.005517401, 0.022044301000000002}, {0.006034566, 0.022336208000000003}, {0.00528727, 0.023491996}, {0.006551748999999999, 0.023655129}, {0.0062048350000000006, 0.020896816999999998}, {0.0057171900000000005, 0.022724604}, {0.005386546000000001, 0.023765106}, {0.0062215180000000005, 0.02441261}, {0.008126182999999999, 0.023618665}, {0.007493377000000001, 0.026332041}, {0.0057998830000000005, 0.026502255000000002}, {7.105400000000095e-05, 0.025315396}, {-0.0011877449999999996, 0.015495276999999998}, {-0.000580737999999999, 0.022052738000000002}};
//float[][] data = new float[100][512];
int dataIndex = 0;

void setup() {
  
  size(400, 600);
  drawBaseLine = 600-150;
  minBufferSize = AudioRecord.getMinBufferSize(RECORDER_SAMPLERATE,RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING);
  // if we are working with the android emulator, getMinBufferSize() does not work
  // and the only samplig rate we can use is 8000Hz
  if (minBufferSize == AudioRecord.ERROR_BAD_VALUE)  {
    RECORDER_SAMPLERATE = 8000; // forced by the android emulator
    MAX_FREQ = RECORDER_SAMPLERATE/2;
    bufferSize =  getHigherP2(RECORDER_SAMPLERATE);// buffer size must be power of 2!!!
    // the buffer size determines the analysis frequency at: RECORDER_SAMPLERATE/bufferSize
    // this might make trouble if there is not enough computation power to record and analyze
    // a frequency. In the other hand, if the buffer size is too small AudioRecord will not initialize
  } else bufferSize = minBufferSize;
  
  buffer = new short[bufferSize];
  // use the mic with Auto Gain Control turned off!
  //audioRecord = new AudioRecord( MediaRecorder.AudioSource.VOICE_RECOGNITION, RECORDER_SAMPLERATE,
                                 //RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
  //System.out.println(audioRecord.getState());
  //System.out.println(AudioRecord.STATE_INITIALIZED);
  audioRecord = new AudioRecord( MediaRecorder.AudioSource.MIC, RECORDER_SAMPLERATE,
                                RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
  if ((audioRecord != null) && (audioRecord.getState() == AudioRecord.STATE_INITIALIZED)) {
   try {
     // this throws an exception with some combinations
     // of RECORDER_SAMPLERATE and bufferSize 
     audioRecord.startRecording(); 
     aRecStarted = true;
   }
   catch (Exception e) {
     aRecStarted = false;
   }
    
   if (aRecStarted) {
       bufferReadResult = audioRecord.read(buffer, 0, bufferSize);
       // compute nearest higher power of two
      bufferReadResult = getHigherP2(bufferReadResult);
       fft = new FFT(bufferReadResult, RECORDER_SAMPLERATE);
       fftRealArray = new float[bufferReadResult]; 
       drawScaleW = drawScaleW*(float)400/(float)fft.freqToIndex(maxFreqToDraw);
   }
  }
  fill(0);
  noStroke();
}

void printList(float[] list)
{
  System.out.print("[");
  for (int i = 0; i < list.length; i++)
  {
    System.out.print(list[i]);
    if (i < list.length-1) System.out.print(", ");
    else System.out.print("]");
  }
}

boolean heardKnock()
{
  //int acceptable = 0;
  float[] data = new float[512];
  //float maxBand = 0; // for recording purposes
  for (int i = 0; i < 512; i++) {
    float band = fft.getBand(i);
    //if (band > maxBand) maxBand = band; // recording
    //data[dataIndex][i] = band;
    //data[i] = band;
    int rangeIndex;
    if (i < ranges.length) rangeIndex = i;
    else rangeIndex = ranges.length-1;
    //if (rangeIndex < 30) System.out.println("i: "+i+", band: "+band);
    // check whether band exceeds acceptable range
    //if (band >= ranges[rangeIndex][0] && band <= ranges[rangeIndex][1]) acceptable +=1;
    if (band < ranges[rangeIndex][0] || band > ranges[rangeIndex][1]){
      System.out.println("no");
      return false; 
    }
    //dataIndex += 1;
  }
  //printList(data);
  //System.out.println(maxBand);
  //if (maxBand > 5) printList(data);
  //if (dataIndex == 10) System.out.println(data);
  //System.out.println(acceptable);
  return true;
}

void draw() {
   background(128); fill(0); noStroke();
   if (aRecStarted) {
       bufferReadResult = audioRecord.read(buffer, 0, bufferSize);  
       
       // After we read the data from the AudioRecord object, we loop through
       // and translate it from short values to double values. We can't do this
       // directly by casting, as the values expected should be between -1.0 and 1.0
       // rather than the full range. Dividing the short by 32768.0 will do that,
       // as that value is the maximum value of short.
       volume = 0;
       for (int i = 0; i < bufferReadResult; i++) {
            fftRealArray[i] = (float) buffer[i] / Short.MAX_VALUE;// 32768.0;
            volume += Math.abs(fftRealArray[i]);
       }
       volume = (float)Math.log10(volume/bufferReadResult);
         
         // apply windowing
        for (int i = 0; i < bufferReadResult/2; ++i) {
          // Calculate & apply window symmetrically around center point
          // Hanning (raised cosine) window
          float winval = (float)(0.5+0.5*Math.cos(Math.PI*(float)i/(float)(bufferReadResult/2)));
          if (i > bufferReadResult/2)  winval = 0;
          fftRealArray[bufferReadResult/2 + i] *= winval;
          fftRealArray[bufferReadResult/2 - i] *= winval;
        }
        // zero out first point (not touched by odd-length window)
        fftRealArray[0] = 0;
        fft.forward(fftRealArray);
         
         //
        fill(255);
        stroke(100);
        pushMatrix();
        rotate(radians(90));
        translate(drawBaseLine-3, 0);
        textAlign(LEFT,CENTER);
        for (float freq = RECORDER_SAMPLERATE/2-1; freq > 0.0; freq -= 150.0) {
          int y = -(int)(fft.freqToIndex(freq)*drawScaleW); // which bin holds this frequency?
          line(-600,y,0,y); // add tick mark
          text(Math.round(freq)+" Hz", 10, y); // add text label
        }
        popMatrix();
        noStroke();
   
        float lastVal = 0;
        float val = 0;
        float maxVal = 0; // index of the bin with highest value
        int maxValIndex = 0; // index of the bin with highest value
        //boolean knocked = heardKnock();
        //heardKnock();
        if (heardKnock()) System.out.println("knock");
        for(int i = 0; i < fft.specSize()/2; i++)
        {
          val += fft.getBand(i);
          if (i % drawStepW == 0) {
               val /= drawStepW; // average volume value
               int prev_i = i-drawStepW;
              stroke(255);
              // draw the line for frequency band i, scaling it up a bit so we can see it
              line( prev_i*drawScaleW, drawBaseLine, prev_i*drawScaleW, drawBaseLine - lastVal*drawScaleH );
          
              if (val-lastVal > PEAK_THRESH) {
                  stroke(255,0,0);
                  fill(255,128,128);
                  ellipse(i*drawScaleW, drawBaseLine - val*drawScaleH, 20,20);
                  stroke(255);
                  fill(255);
                  if (val > maxVal) {
                    maxVal = val;
                    maxValIndex = i;
                  }
              } 
              line( prev_i*drawScaleW, drawBaseLine - lastVal*drawScaleH, i*drawScaleW, drawBaseLine - val*drawScaleH );
              lastVal = val;
              val = 0;  
           }
        }
        if (maxValIndex-drawStepW > 0) {
           fill(255,0,0);
           ellipse(maxValIndex*drawScaleW, drawBaseLine - maxVal*drawScaleH, 20,20);
           fill(0,0,255);
           text( " " + fft.indexToFreq(maxValIndex-drawStepW/2)+"Hz",
                 25+maxValIndex*drawScaleW, drawBaseLine - maxVal*drawScaleH);     
        }
        fill(255); 
        pushMatrix();
        translate(400/2,drawBaseLine);
        text("buffer readed: " + bufferReadResult, 20, 80);
        text("fft spec size: " + fft.specSize(), 20, 100);
        text("volume: " + volume, 20, 120);  
        popMatrix();
  }
  else {
    fill(255,0,0);
    text("AUDIO RECORD NOT INITIALIZED!!!", 100, height/2);
  }  
  fill(255); 
  pushMatrix();
  translate(0,drawBaseLine);
  text("sample rate: " + RECORDER_SAMPLERATE + " Hz", 20, 80);   
  text("displaying freq: 0 Hz  to  "+maxFreqToDraw+" Hz", 20, 100);   
  text("buffer size: " + bufferSize, 20, 120);   
  popMatrix();
}

void stop() {
  audioRecord.stop();
  audioRecord.release();
}

// compute nearest higher power of two
// see: graphics.stanford.edu/~seander/bithacks.html
int getHigherP2(int val)
{
  val--;
  val |= val >> 1;
  val |= val >> 2;
  val |= val >> 8;
  val |= val >> 16;
  val++;
  return(val);
}