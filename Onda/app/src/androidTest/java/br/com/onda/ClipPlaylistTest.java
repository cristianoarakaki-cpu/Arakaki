package br.com.onda;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.media3.common.MediaItem;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;

import org.junit.Test;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

@UnstableApi
public class ClipPlaylistTest {
    @Test public void audioAdvancesToVideoAndStopsAtTheLastClip() throws Exception {
        android.app.Instrumentation instrumentation = getInstrumentation();
        Context context = instrumentation.getTargetContext();
        File audio = AudioTestFixtures.tone(context, 6000);
        File video = File.createTempFile("clip-video-", ".mp4", context.getCacheDir());
        ClipPlaylistActivity activity = null;
        try {
            try (InputStream source = instrumentation.getContext().getAssets().open("combined.mp4");
                 FileOutputStream output = new FileOutputStream(video)) {
                byte[] buffer = new byte[8192];
                int count;
                while ((count = source.read(buffer)) != -1) output.write(buffer, 0, count);
            }
            activity = (ClipPlaylistActivity) instrumentation.startActivitySync(new Intent(context, ClipPlaylistActivity.class)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            ClipPlaylistActivity screen = activity;
            List<MediaItem> items = Arrays.asList(ClipPlaylistActivity.item(Uri.fromFile(audio), 1000, 2000),
                    ClipPlaylistActivity.item(Uri.fromFile(video), 500, 2000));
            CountDownLatch ended = new CountDownLatch(1);
            AtomicLong audioLength = new AtomicLong(), videoLength = new AtomicLong();
            instrumentation.runOnMainSync(() -> {
                try {
                    Method play = ClipPlaylistActivity.class.getDeclaredMethod("play", List.class, int.class);
                    play.setAccessible(true);
                    play.invoke(screen, items, 0);
                    Field field = ClipPlaylistActivity.class.getDeclaredField("player");
                    field.setAccessible(true);
                    ExoPlayer player = (ExoPlayer) field.get(screen);
                    player.addListener(new Player.Listener() {
                        @Override public void onEvents(Player p, Player.Events events) {
                            if (p.getPlaybackState() == Player.STATE_READY) {
                                if (p.getCurrentMediaItemIndex() == 0) audioLength.set(p.getDuration());
                                else videoLength.set(p.getDuration());
                            }
                            if (p.getPlaybackState() == Player.STATE_ENDED) ended.countDown();
                        }
                    });
                } catch (ReflectiveOperationException error) { throw new AssertionError(error); }
            });
            assertTrue("Expected the playlist to finish", ended.await(15, TimeUnit.SECONDS));
            assertEquals(1000, audioLength.get());
            assertEquals(1500, videoLength.get());
        } finally {
            ClipPlaylistActivity screen = activity;
            if (screen != null) instrumentation.runOnMainSync(screen::finish);
            instrumentation.waitForIdleSync();
            audio.delete();
            video.delete();
        }
    }
}
