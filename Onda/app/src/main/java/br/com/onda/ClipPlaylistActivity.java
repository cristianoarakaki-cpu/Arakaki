package br.com.onda;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.VideoSize;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@UnstableApi
public final class ClipPlaylistActivity extends Activity {
    private static final String PREFS = "clip_playlists";
    private static final String KEY = "lists";
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private JSONArray playlists;
    private int selected, request;
    private ExoPlayer player;
    private TextView status;
    private Button select, transport;
    private ListView rows;
    private FrameLayout video;
    private TextureView texture;
    private VideoSize videoSize = VideoSize.UNKNOWN;

    private static JSONArray read(Context context) throws JSONException {
        return new JSONArray(context.getSharedPreferences(PREFS, MODE_PRIVATE).getString(KEY, "[]"));
    }

    private static void save(Context context, JSONArray lists) {
        context.getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY, lists.toString()).apply();
    }

    static void add(Activity context, MemoryStore.Hit hit) {
        Uri uri = Uri.parse(hit.source.uri);
        if (hit.page >= 0 || hit.start < 0 || hit.end <= hit.start ||
                !("content".equals(uri.getScheme()) || "file".equals(uri.getScheme()))) return;
        try {
            JSONArray lists = read(context);
            String[] options = new String[lists.length() + 1];
            options[0] = "Nova playlist";
            for (int i = 0; i < lists.length(); i++) options[i + 1] = lists.getJSONObject(i).getString("name");
            JSONObject clip = new JSONObject().put("uri", uri.toString()).put("stamp", hit.source.stamp)
                    .put("label", hit.text).put("start", hit.start).put("end", hit.end);
            new AlertDialog.Builder(context).setTitle("Adicionar trecho à playlist").setItems(options, (d, index) -> {
                if (index == 0) nameDialog(context, name -> {
                    try {
                        lists.put(new JSONObject().put("name", name).put("clips", new JSONArray().put(clip)));
                        save(context, lists);
                        added(context, lists.length() - 1);
                    } catch (JSONException error) { storageError(context); }
                });
                else {
                    lists.optJSONObject(index - 1).optJSONArray("clips").put(clip);
                    save(context, lists);
                    added(context, index - 1);
                }
            }).setNegativeButton("Cancelar", null).show();
        } catch (JSONException error) { storageError(context); }
    }

    private interface NameAction { void accept(String name); }

    private static void nameDialog(Activity context, NameAction action) {
        EditText input = new EditText(context);
        input.setHint("Nome da playlist");
        input.setSingleLine(true);
        input.setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(80)});
        AlertDialog dialog = new AlertDialog.Builder(context).setTitle("Nova playlist")
                .setView(input).setPositiveButton("Salvar", null).setNegativeButton("Cancelar", null).show();
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            String name = input.getText().toString().trim();
            if (name.isEmpty()) { input.setError("Digite um nome"); return; }
            dialog.dismiss();
            action.accept(name);
        });
    }

    private static void added(Activity context, int index) {
        context.startActivity(new android.content.Intent(context, ClipPlaylistActivity.class).putExtra("playlist", index));
    }

    private static void storageError(Context context) {
        android.widget.Toast.makeText(context, "Não foi possível ler as playlists.", android.widget.Toast.LENGTH_LONG).show();
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        try { playlists = read(this); }
        catch (JSONException error) { storageError(this); finish(); return; }
        selected = Math.max(0, Math.min(playlists.length() - 1,
                state == null ? getIntent().getIntExtra("playlist", 0) : state.getInt("playlist")));
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        Ui.background(root);
        root.setOnApplyWindowInsetsListener((v, insets) -> {
            root.setPadding(Ui.dp(this, 16), insets.getSystemWindowInsetTop(),
                    Ui.dp(this, 16), insets.getSystemWindowInsetBottom());
            return insets;
        });
        setContentView(root);
        LinearLayout header = new LinearLayout(this);
        Button back = Ui.button(this, "‹", v -> finish());
        back.setContentDescription("Voltar");
        header.addView(back, new LinearLayout.LayoutParams(Ui.dp(this, 48), -2));
        header.addView(Ui.text(this, "Playlists de trechos", 21, Ui.TEXT), new LinearLayout.LayoutParams(0, -2, 1));
        root.addView(header);
        select = Ui.button(this, "Escolher playlist", v -> choosePlaylist());
        root.addView(select);
        video = new FrameLayout(this);
        video.setBackgroundColor(android.graphics.Color.BLACK);
        texture = new TextureView(this);
        video.addView(texture, new FrameLayout.LayoutParams(-1, -1, Gravity.CENTER));
        video.addOnLayoutChangeListener((v,l,t,r,b,ol,ot,or,ob) -> fitVideo());
        video.setVisibility(View.GONE);
        root.addView(video, new LinearLayout.LayoutParams(-1, Ui.dp(this, 144)));
        status = Ui.text(this, "", 14, Ui.MUTED);
        root.addView(status);
        rows = new ListView(this);
        rows.setOnItemClickListener((parent, view, index, id) -> editClip(index));
        root.addView(rows, new LinearLayout.LayoutParams(-1, 0, 1));
        transport = Ui.button(this, "Tocar playlist", v -> toggle());
        Ui.primary(transport);
        root.addView(transport);
        render();
    }

    private JSONArray clips() {
        JSONObject list = playlists.optJSONObject(selected);
        return list == null ? new JSONArray() : list.optJSONArray("clips");
    }

    private void render() {
        JSONObject list = playlists.optJSONObject(selected);
        select.setText(list == null ? "Playlists" : list.optString("name") + " ▾");
        select.setEnabled(list != null);
        JSONArray clips = clips();
        List<String> labels = new ArrayList<>();
        for (int i = 0; i < clips.length(); i++) {
            JSONObject clip = clips.optJSONObject(i);
            labels.add(clip.optString("label") + "\n" + ChapterEdits.format(clip.optLong("start")) +
                    " → " + ChapterEdits.format(clip.optLong("end")));
        }
        rows.setAdapter(new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, labels) {
            @Override public View getView(int position, View recycled, ViewGroup parent) {
                TextView row = (TextView) super.getView(position, recycled, parent);
                row.setTextColor(Ui.TEXT);
                row.setPadding(Ui.dp(ClipPlaylistActivity.this, 8), Ui.dp(ClipPlaylistActivity.this, 8),
                        Ui.dp(ClipPlaylistActivity.this, 8), Ui.dp(ClipPlaylistActivity.this, 8));
                return row;
            }
        });
        transport.setEnabled(clips.length() > 0);
        status.setText(clips.length() == 0 ? "Adicione uma marcação de áudio ou vídeo pela Memória Multimídia."
                : clips.length() + (clips.length() == 1 ? " trecho" : " trechos"));
    }

    private void choosePlaylist() {
        String[] names = new String[playlists.length()];
        for (int i = 0; i < names.length; i++) names[i] = playlists.optJSONObject(i).optString("name");
        new AlertDialog.Builder(this).setTitle("Escolher playlist").setSingleChoiceItems(names, selected, (d, index) -> {
            stop();
            selected = index;
            render();
            d.dismiss();
        }).setNegativeButton("Cancelar", null).show();
    }

    private void editClip(int index) {
        JSONArray clips = clips();
        List<String> choices = new ArrayList<>();
        List<Integer> destinations = new ArrayList<>();
        choices.add("Tocar a partir daqui"); destinations.add(index);
        if (index > 0) { choices.add("Mover para cima"); destinations.add(index - 1); }
        if (index + 1 < clips.length()) { choices.add("Mover para baixo"); destinations.add(index + 1); }
        choices.add("Remover da playlist"); destinations.add(-1);
        new AlertDialog.Builder(this).setTitle("Trecho").setItems(choices.toArray(new String[0]), (d, option) -> {
            if (option == 0) { startPlayback(index); return; }
            stop();
            int destination = destinations.get(option);
            try {
                if (destination < 0) clips.remove(index);
                else {
                    Object replaced = clips.get(destination);
                    clips.put(destination, clips.get(index));
                    clips.put(index, replaced);
                }
                save(this, playlists);
                render();
            } catch (JSONException error) { storageError(this); }
        }).setNegativeButton("Cancelar", null).show();
    }

    private void toggle() {
        if (player == null) startPlayback(0);
        else if (player.getPlayWhenReady()) player.pause();
        else player.play();
    }

    private void startPlayback(int first) {
        stop();
        JSONArray clips = clips();
        List<JSONObject> snapshot = new ArrayList<>();
        for (int i = first; i < clips.length(); i++) snapshot.add(clips.optJSONObject(i));
        int token = request;
        status.setText("Conferindo os arquivos…");
        transport.setEnabled(false);
        worker.execute(() -> {
            List<MediaItem> items = new ArrayList<>();
            for (JSONObject clip : snapshot) {
                Uri uri = Uri.parse(clip.optString("uri"));
                try (android.content.res.AssetFileDescriptor input = getContentResolver().openAssetFileDescriptor(uri, "r")) {
                    if (input == null || !clip.optString("stamp").equals(AudioChapterStore.stamp(this, uri))) continue;
                    items.add(item(uri, clip.optLong("start"), clip.optLong("end")));
                } catch (java.io.IOException | RuntimeException inaccessible) {
                    // The file can have been removed since the marking was saved.
                }
            }
            runOnUiThread(() -> {
                if (request != token || isDestroyed()) return;
                transport.setEnabled(true);
                if (items.isEmpty()) { status.setText("Os arquivos mudaram ou perderam acesso."); return; }
                play(items, snapshot.size() - items.size());
            });
        });
    }

    static MediaItem item(Uri uri, long start, long end) {
        return new MediaItem.Builder().setUri(uri).setClippingConfiguration(
                new MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(end).build()).build();
    }

    private void play(List<MediaItem> items, int skipped) {
        player = new ExoPlayer.Builder(this).setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(), true)
                .setHandleAudioBecomingNoisy(true).build();
        player.setVideoTextureView(texture);
        player.addListener(new Player.Listener() {
            @Override public void onPlayWhenReadyChanged(boolean play, int reason) {
                transport.setText(play ? "Pausar" : "Continuar");
            }
            @Override public void onMediaItemTransition(MediaItem item, int reason) {
                if (player != null && item != null) status.setText("Trecho " + (player.getCurrentMediaItemIndex() + 1)
                        + " de " + items.size() + (skipped == 0 ? "" : " • indisponíveis: " + skipped));
            }
            @Override public void onTracksChanged(androidx.media3.common.Tracks tracks) {
                video.setVisibility(tracks.isTypeSelected(C.TRACK_TYPE_VIDEO) ? View.VISIBLE : View.GONE);
            }
            @Override public void onVideoSizeChanged(VideoSize size) {
                videoSize = size;
                fitVideo();
            }
            @Override public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_ENDED) {
                    ExoPlayer completed = player;
                    status.post(() -> {
                        if (player == completed && player != null && player.getPlaybackState() == Player.STATE_ENDED) {
                            stop();
                            status.setText("Playlist concluída.");
                        }
                    });
                }
            }
            @Override public void onPlayerError(PlaybackException error) {
                if (player != null && player.hasNextMediaItem()) {
                    player.seekToNextMediaItem();
                    player.prepare();
                } else {
                    stop();
                    status.setText("Não foi possível reproduzir o último trecho.");
                }
            }
        });
        player.setMediaItems(items);
        player.prepare();
        player.play();
    }

    private void fitVideo() {
        if (videoSize.width == 0 || video.getWidth() == 0 || video.getHeight() == 0) return;
        float aspect = videoSize.width * videoSize.pixelWidthHeightRatio / videoSize.height;
        int width = Math.min(video.getWidth(), Math.round(video.getHeight() * aspect));
        int height = Math.min(video.getHeight(), Math.round(video.getWidth() / aspect));
        ViewGroup.LayoutParams params = texture.getLayoutParams();
        if (params.width != width || params.height != height) {
            params.width = width;
            params.height = height;
            texture.setLayoutParams(params);
        }
    }

    private void stop() {
        request++;
        if (player != null) {
            ExoPlayer old = player;
            player = null;
            old.release();
        }
        if (video != null) video.setVisibility(View.GONE);
        if (transport != null) transport.setText("Tocar playlist");
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putInt("playlist", selected);
    }

    @Override protected void onStop() {
        stop();
        if (transport != null) render();
        super.onStop();
    }

    @Override protected void onDestroy() {
        worker.shutdownNow();
        super.onDestroy();
    }
}
