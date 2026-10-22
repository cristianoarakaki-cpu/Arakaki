package br.com.onda;

import android.os.Handler;
import android.os.Looper;
import android.os.Bundle;
import android.app.PendingIntent;
import android.content.Intent;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.Player;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.MediaSession;
import androidx.media3.session.MediaSessionService;
import androidx.media3.session.SessionCommand;
import androidx.media3.session.SessionResult;
import androidx.media3.session.SessionError;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

@androidx.media3.common.util.UnstableApi
public class PlaybackService extends MediaSessionService {
    private ExoPlayer player;
    private MediaSession session;
    private final Handler timer = new Handler(Looper.getMainLooper());
    private final Runnable stop = () -> { if (player != null) player.pause(); };
    @Override public void onCreate() {
        super.onCreate();
        player = new ExoPlayer.Builder(this).build();
        player.setAudioAttributes(new AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(), true);
        player.setHandleAudioBecomingNoisy(true);
        player.setWakeMode(C.WAKE_MODE_LOCAL);
        player.addListener(new Player.Listener(){
            @Override public void onMediaItemTransition(MediaItem item,int reason){
                String scheme=item!=null&&item.localConfiguration!=null?item.localConfiguration.uri.getScheme():null;
                boolean online="https".equalsIgnoreCase(scheme)||"http".equalsIgnoreCase(scheme);
                player.setWakeMode(online?C.WAKE_MODE_NETWORK:C.WAKE_MODE_LOCAL);
            }
        });
        session = new MediaSession.Builder(this, player)
            .setSessionActivity(PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT))
            .setCallback(new MediaSession.Callback() {
            @Override public MediaSession.ConnectionResult onConnect(MediaSession s, MediaSession.ControllerInfo c) {
                return new MediaSession.ConnectionResult.AcceptedResultBuilder(s)
                    .setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(new SessionCommand("sleep", Bundle.EMPTY)).build()).build();
            }
            @Override public ListenableFuture<SessionResult> onCustomCommand(MediaSession s, MediaSession.ControllerInfo c, SessionCommand command, Bundle args) {
                if (!command.customAction.equals("sleep")) return Futures.immediateFuture(new SessionResult(SessionError.ERROR_NOT_SUPPORTED));
                timer.removeCallbacks(stop);
                int minutes = Math.max(0, Math.min(120, args.getInt("minutes", 0)));
                if (minutes > 0) timer.postDelayed(stop, minutes * 60000L);
                return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
            }
        }).build();
    }
    @Override public MediaSession onGetSession(MediaSession.ControllerInfo controllerInfo) { return session; }
    @Override public void onDestroy() {
        timer.removeCallbacksAndMessages(null);
        session.release(); player.release(); super.onDestroy();
    }
}
