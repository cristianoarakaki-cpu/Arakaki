package br.com.onda;

import java.util.Arrays;

/** Device-independent settings; all gains are dB, BassBoost strength is percent. */
final class SoundProfile {
    static final int[] FREQUENCIES={60,230,910,3600,14000};
    static final String[] PRESETS={"Original","Voz","Sertanejo","Rock","Pop","Graves suaves"};
    private static final int[][] CURVES={{0,0,0,0,0},{-2,-1,2,3,1},{2,0,1,2,2},{4,2,-1,2,4},{-1,1,3,1,-1},{3,2,0,-1,-2}};
    private static final int[] BASS={0,0,15,20,10,30};
    final boolean enabled;final int bass;private final int[] gains;
    SoundProfile(boolean enabled,int[] gains,int bass){this.enabled=enabled;this.gains=new int[5];for(int i=0;i<5;i++)this.gains[i]=Math.max(-6,Math.min(6,gains!=null&&i<gains.length?gains[i]:0));this.bass=Math.max(0,Math.min(100,bass));}
    static SoundProfile preset(int index,boolean enabled){int i=Math.max(0,Math.min(PRESETS.length-1,index));return new SoundProfile(enabled,CURVES[i],BASS[i]);}
    int gain(int i){return gains[i];}
    SoundProfile enabled(boolean value){return new SoundProfile(value,gains,bass);}
    SoundProfile gain(int band,int value){int[] copy=gains.clone();copy[band]=value;return new SoundProfile(enabled,copy,bass);}
    SoundProfile bass(int value){return new SoundProfile(enabled,gains,value);}
    String presetName(){for(int i=0;i<CURVES.length;i++)if(bass==BASS[i]&&Arrays.equals(gains,CURVES[i]))return PRESETS[i];return "Personalizado";}
    int millibelsAt(double frequency){
        if(!Double.isFinite(frequency)||frequency<=FREQUENCIES[0])return gains[0]*100;
        for(int i=1;i<FREQUENCIES.length;i++)if(frequency<=FREQUENCIES[i]){double ratio=Math.log(frequency/FREQUENCIES[i-1])/Math.log((double)FREQUENCIES[i]/FREQUENCIES[i-1]);return (int)Math.round(100*(gains[i-1]+ratio*(gains[i]-gains[i-1])));}
        return gains[4]*100;
    }
    float headroom(boolean equalizer,boolean bassBoost){
        if(!enabled)return 1;double peak=0;if(equalizer)for(int gain:gains)peak=Math.max(peak,gain);if(bassBoost)peak+=6.0*bass/100;
        return (float)Math.pow(10,-peak/20);
    }
}
