package br.com.onda;

import android.media.audiofx.*;
import android.os.Bundle;
import org.json.*;

/** Effects belong only to ExoPlayer's audio session, never the global output. */
final class SoundEffects {
    private Equalizer equalizer;private BassBoost bass;
    private int session;private boolean playing,eqAvailable,bassAvailable;
    private SoundProfile profile=SoundProfile.preset(0,false);
    void apply(SoundProfile settings,int id,boolean isPlaying){
        if(id!=session){release();session=id;}profile=settings;playing=isPlaying;
        if(!profile.enabled||session<=0){release();log();return;}
        if(equalizer==null)try{equalizer=new Equalizer(0,session);}catch(RuntimeException ignored){}
        if(bass==null)try{bass=new BassBoost(0,session);}catch(RuntimeException ignored){}
        eqAvailable=false;bassAvailable=false;
        if(equalizer!=null)try{
            eqAvailable=equalizer.hasControl()&&equalizer.getNumberOfBands()>0;
            if(eqAvailable){short[] range=equalizer.getBandLevelRange();for(short band=0;band<equalizer.getNumberOfBands();band++)equalizer.setBandLevel(band,(short)Math.max(range[0],Math.min(range[1],profile.millibelsAt(equalizer.getCenterFreq(band)/1000.0))));}
        }catch(RuntimeException e){eqAvailable=false;}
        if(bass!=null)try{bassAvailable=bass.hasControl()&&bass.getStrengthSupported();if(bassAvailable)bass.setStrength((short)(profile.bass*10));}catch(RuntimeException e){bassAvailable=false;}
        updateEnabled();log();
    }
    void playing(boolean value){if(playing==value)return;playing=value;updateEnabled();log();}
    private void updateEnabled(){
        if(equalizer!=null)try{if(equalizer.setEnabled(profile.enabled&&playing&&eqAvailable)!=AudioEffect.SUCCESS)eqAvailable=false;}catch(RuntimeException e){eqAvailable=false;}
        if(bass!=null)try{if(bass.setEnabled(profile.enabled&&playing&&bassAvailable&&profile.bass>0)!=AudioEffect.SUCCESS)bassAvailable=false;}catch(RuntimeException e){bassAvailable=false;}
    }
    float headroom(){return profile.headroom(eqAvailable,bassAvailable);}
    Bundle status(){
        Bundle b=new Bundle();b.putBoolean("enabled",profile.enabled);b.putInt("session",session);b.putBoolean("playing",playing);b.putBoolean("equalizer",eqAvailable);b.putBoolean("bass",bassAvailable);b.putFloat("headroom",headroom());
        b.putString("status",!profile.enabled?"disabled":session<=0?"waiting":eqAvailable&&bassAvailable?"ready":eqAvailable||bassAvailable?"partial":"unsupported");
        try{if(equalizer!=null&&eqAvailable){int count=equalizer.getNumberOfBands();int[] frequencies=new int[count],levels=new int[count];for(short i=0;i<count;i++){frequencies[i]=equalizer.getCenterFreq(i)/1000;levels[i]=equalizer.getBandLevel(i);}b.putIntArray("frequencies",frequencies);b.putIntArray("levels",levels);b.putBoolean("eq_enabled",equalizer.getEnabled());}
            if(bass!=null&&bassAvailable){b.putInt("bass_strength",bass.getRoundedStrength());b.putBoolean("bass_enabled",bass.getEnabled());}
        }catch(RuntimeException ignored){}
        return b;
    }
    private void log(){try{Bundle b=status();JSONObject o=new JSONObject();for(String key:b.keySet()){Object value=b.get(key);if(value instanceof int[])o.put(key,new JSONArray((int[])value));else o.put(key,value);}android.util.Log.d("OndaSound",o.toString());}catch(JSONException ignored){}}
    void release(){if(equalizer!=null){try{equalizer.release();}catch(RuntimeException ignored){}equalizer=null;}if(bass!=null){try{bass.release();}catch(RuntimeException ignored){}bass=null;}eqAvailable=false;bassAvailable=false;}
}
