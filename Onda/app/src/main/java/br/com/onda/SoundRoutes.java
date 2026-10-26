package br.com.onda;

import android.content.Context;
import android.media.*;
import android.os.*;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.audio.*;

/** Observes the actual music AudioTrack. Never chooses a route or scans Bluetooth. */
@androidx.media3.common.util.UnstableApi
final class SoundRoutes {
    private final Handler main=new Handler(Looper.getMainLooper());
    private final Runnable changed;private final SpeechProcessor speech;private AudioTrack track;private boolean closed;
    private final AudioRouting.OnRoutingChangedListener listener=router->refresh();
    SoundRoutes(Runnable changed){this(changed,null);}
    SoundRoutes(Runnable changed,SpeechProcessor speech){this.changed=changed;this.speech=speech;}
    DefaultRenderersFactory renderers(Context context){return new DefaultRenderersFactory(context){
        @Override protected AudioSink buildAudioSink(Context c,boolean floats,boolean parameters){
            DefaultAudioSink.Builder builder=new DefaultAudioSink.Builder(c).setEnableFloatOutput(speech==null&&floats).setEnableAudioTrackPlaybackParams(parameters);if(speech!=null)builder.setAudioProcessors(new androidx.media3.common.audio.AudioProcessor[]{speech});return builder
                .setAudioTrackProvider((config,attributes,session)->{
                    AudioTrack created=DefaultAudioSink.AudioTrackProvider.DEFAULT.getAudioTrack(config,attributes,session);
                    main.post(()->attach(created));return created;
                }).build();
        }
    };}
    private void attach(AudioTrack value){if(closed)return;detach();track=value;
        try{track.addOnRoutingChangedListener(listener,main);}catch(RuntimeException ignored){}
        refresh();
    }
    void refresh(){if(closed)return;AudioDeviceInfo device=null;
        try{if(track!=null)device=track.getRoutedDevice();}catch(RuntimeException ignored){}
        if(SoundSettings.route(device==null?"":kind(device.getType())))changed.run();
    }
    static String kind(int type){switch(type){
        case AudioDeviceInfo.TYPE_BUILTIN_SPEAKER:case AudioDeviceInfo.TYPE_BUILTIN_EARPIECE:return "speaker";
        case AudioDeviceInfo.TYPE_WIRED_HEADSET:case AudioDeviceInfo.TYPE_WIRED_HEADPHONES:return "wired";
        case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP:case AudioDeviceInfo.TYPE_BLUETOOTH_SCO:case 26:case 27:case 30:return "bluetooth";
        case AudioDeviceInfo.TYPE_USB_HEADSET:case AudioDeviceInfo.TYPE_USB_DEVICE:case AudioDeviceInfo.TYPE_USB_ACCESSORY:return "usb";
        case AudioDeviceInfo.TYPE_HDMI:case AudioDeviceInfo.TYPE_HDMI_ARC:case 29:return "hdmi";
        default:return "other";
    }}
    private void detach(){if(track!=null)try{track.removeOnRoutingChangedListener(listener);}catch(RuntimeException ignored){}track=null;}
    void close(){closed=true;main.removeCallbacksAndMessages(null);detach();SoundSettings.route("");}
}
