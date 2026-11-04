package br.com.onda;

import android.app.Activity;
import android.content.Intent;

/** Explicit screen requests only. Does not start playback, install updates or keep a microphone open. */
final class VoiceNavigation {
    static boolean phrase(Activity activity,String phrase){
        VoiceCommand custom=VoicePhrases.read(activity).find(phrase);
        return execute(activity,custom==null?VoiceCommand.parse(phrase):custom);
    }
    static boolean execute(Activity activity,VoiceCommand command){
        Class<? extends Activity> screen;
        switch(command.action){
            case OPEN_YOUTUBE:screen=YouTubeActivity.class;break;
            case OPEN_IMAGES:screen=ImageSearchActivity.class;break;
            case OPEN_UPDATES:screen=UpdateActivity.class;break;
            case OPEN_DOWNLOADS:screen=DownloadsActivity.class;break;
            case OPEN_RADIOS:screen=RadioActivity.class;break;
            case OPEN_VIDEOS:screen=VideoActivity.class;break;
            case OPEN_MUSIC:screen=MainActivity.class;break;
            case OPEN_PDF:screen=PdfActivity.class;break;
            case OPEN_SOUND:screen=SoundActivity.class;break;
            case OPEN_CONVERTER:screen=LocalConverterActivity.class;break;
            case OPEN_PLAYLISTS:screen=PlaylistsActivity.class;break;
            case OPEN_QUEUE:screen=QueueActivity.class;break;
            case OPEN_APPEARANCE:screen=AppearanceActivity.class;break;
            case OPEN_FILES:screen=OndaFilesActivity.class;break;
            case OPEN_CHAPTERS:screen=AudioChaptersActivity.class;break;
            case OPEN_VOICE_PHRASES:screen=VoicePhrasesActivity.class;break;
            default:return false;
        }
        if(activity.getClass()!=screen)activity.startActivity(new Intent(activity,screen)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP));
        return true;
    }
}
