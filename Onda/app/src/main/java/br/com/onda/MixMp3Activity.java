package br.com.onda;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.database.Cursor;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.system.Os;
import android.widget.*;

import androidx.media3.common.util.UnstableApi;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@UnstableApi
public final class MixMp3Activity extends Activity {
    private static final int PICK = 43, SAVE = 44;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final List<Track> tracks = new ArrayList<>();
    private volatile boolean cancelled;
    private boolean busy;
    private TextView status;
    private Button add, chapters, export;
    private Switch fade;
    private ListView list;
    private volatile File prepared;

    private static final class Track {
        final Uri uri;
        final String stamp, name;
        final long start, end;
        Track(Uri uri, String stamp, String name, long start, long end) {
            this.uri = uri; this.stamp = stamp; this.name = name; this.start = start; this.end = end;
        }
        long length() { return end - start; }
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        List<Track> initial = new ArrayList<>();
        String raw = getIntent().getStringExtra("clips");
        if (raw != null) try {
            JSONArray clips = new JSONArray(raw);
            for (int i = 0; i < clips.length(); i++) {
                JSONObject clip = clips.getJSONObject(i);
                initial.add(new Track(Uri.parse(clip.getString("uri")), clip.getString("stamp"),
                        clip.getString("label"), clip.getLong("start"), clip.getLong("end")));
            }
        } catch (org.json.JSONException invalid) { initial.clear(); }
        if (!getIntent().getBooleanExtra("choose_clips", false)) tracks.addAll(initial);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        Ui.background(root);
        root.setOnApplyWindowInsetsListener((view, insets) -> {
            root.setPadding(Ui.dp(this, 16), insets.getSystemWindowInsetTop(),
                    Ui.dp(this, 16), insets.getSystemWindowInsetBottom());
            return insets;
        });
        setContentView(root);
        root.addView(Ui.button(this, "‹ Voltar", view -> finish()));
        root.addView(Ui.text(this, "Montar MP3 único", 21, Ui.TEXT));
        add = Ui.button(this, "Adicionar músicas", view -> pick(false));
        chapters = Ui.button(this, "Escolher faixas de coletânea", view -> pick(true));
        root.addView(add);
        root.addView(chapters);
        status = Ui.text(this, "Selecione pelo menos duas faixas.", 14, Ui.MUTED);
        root.addView(status);
        list = new ListView(this);
        root.addView(list, new LinearLayout.LayoutParams(-1, 0, 1));
        list.setOnItemClickListener((parent, view, index, id) -> rearrange(index));
        fade = new Switch(this);
        fade.setText("Transição suave • até 3 segundos");
        fade.setTextColor(Ui.TEXT);
        fade.setMinHeight(Ui.dp(this, 48));
        root.addView(fade);
        export = Ui.button(this, "Gerar MP3 único", view -> {
            if (busy) {
                cancelled = true;
                status.setText("Cancelando…");
            } else generate();
        });
        Ui.primary(export);
        root.addView(export);
        render();
        if (getIntent().getBooleanExtra("choose_clips", false) && !initial.isEmpty()) chooseChapters(initial);
    }

    private void pick(boolean collection) {
        try {
            startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("audio/*").putExtra(Intent.EXTRA_ALLOW_MULTIPLE, !collection)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION),
                    collection ? PICK + 10 : PICK);
        } catch (android.content.ActivityNotFoundException error) {
            status.setText("O seletor de arquivos está indisponível.");
        }
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (result != RESULT_OK || data == null) {
            if (request == SAVE) discardPrepared();
            return;
        }
        if (request == SAVE) {
            if (data.getData() != null) copy(data.getData());
            else discardPrepared();
            return;
        }
        if (request != PICK && request != PICK + 10) return;
        List<Uri> inputs = new ArrayList<>();
        if (data.getClipData() != null) {
            for (int i = 0; i < data.getClipData().getItemCount(); i++) {
                Uri uri = data.getClipData().getItemAt(i).getUri();
                if (uri != null) inputs.add(uri);
            }
        } else if (data.getData() != null) inputs.add(data.getData());
        setBusy(true, "Lendo as faixas…");
        worker.execute(() -> readInputs(inputs, request == PICK + 10));
    }

    private void readInputs(List<Uri> inputs, boolean collection) {
        List<Track> found = new ArrayList<>();
        for (Uri uri : inputs) {
            if (cancelled) break;
            try {
                String stamp = AudioChapterStore.stamp(this, uri);
                long duration = duration(uri);
                if (duration <= 0) continue;
                if (collection) {
                    AudioChapterStore.Data divisions = AudioChapterStore.load(this, uri, stamp, duration);
                    if (divisions != null) for (int i = 0; i < divisions.chapters.size(); i++) {
                        long end = i + 1 < divisions.chapters.size() ? divisions.chapters.get(i + 1).start : duration;
                        long start = divisions.chapters.get(i).start;
                        if (end > start) found.add(new Track(uri, stamp, AudioChapterStore.label(divisions, i), start, end));
                    }
                } else found.add(new Track(uri, stamp, displayName(uri), 0, duration));
            } catch (IOException | RuntimeException ignored) {
                // An unreadable selection does not discard the other files.
            }
        }
        runOnUiThread(() -> {
            if (isDestroyed() || isFinishing()) return;
            setBusy(false, cancelled ? "Seleção cancelada." : collection && found.isEmpty()
                    ? "Escolha uma coletânea já analisada em Faixas da coletânea."
                    : found.size() + " faixas disponíveis" + (!collection && found.size() < inputs.size() ? " • alguns arquivos não puderam ser lidos" : ""));
            if (cancelled) return;
            if (collection && !found.isEmpty()) chooseChapters(found);
            else { tracks.addAll(found); render(); }
        });
    }

    private long duration(Uri uri) throws IOException {
        MediaExtractor extractor = new MediaExtractor();
        try (MediaInput.Direct source = MediaInput.open(this, uri)) {
            if (source == null) throw new IOException("Arquivo indisponível.");
            source.bind(extractor);
            MediaFormat format = extractor.getTrackFormat(AudioTracks.select(extractor));
            return format.getLong(MediaFormat.KEY_DURATION) / 1000;
        } finally { extractor.release(); }
    }

    private String displayName(Uri uri) {
        try (Cursor cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst() && !cursor.isNull(0)) return cursor.getString(0);
        } catch (RuntimeException ignored) {}
        return "Música";
    }

    private void chooseChapters(List<Track> available) {
        boolean[] checked = new boolean[available.size()];
        String[] labels = new String[available.size()];
        for (int i = 0; i < labels.length; i++) labels[i] = available.get(i).name;
        new AlertDialog.Builder(this).setTitle("Marque as faixas")
                .setMultiChoiceItems(labels, checked, (dialog, index, selected) -> checked[index] = selected)
                .setPositiveButton("Adicionar", (dialog, button) -> {
                    for (int i = 0; i < checked.length; i++) if (checked[i]) tracks.add(available.get(i));
                    render();
                }).setNegativeButton("Cancelar", null).show();
    }

    private void rearrange(int index) {
        if (busy) return;
        List<String> actions = new ArrayList<>();
        List<Integer> positions = new ArrayList<>();
        if (index > 0) { actions.add("Mover para cima"); positions.add(index - 1); }
        if (index + 1 < tracks.size()) { actions.add("Mover para baixo"); positions.add(index + 1); }
        actions.add("Remover"); positions.add(-1);
        new AlertDialog.Builder(this).setTitle(tracks.get(index).name)
                .setItems(actions.toArray(new String[0]), (dialog, choice) -> {
                    int position = positions.get(choice);
                    if (position < 0) tracks.remove(index);
                    else Collections.swap(tracks, index, position);
                    render();
                }).setNegativeButton("Cancelar", null).show();
    }

    private void render() {
        List<String> labels = new ArrayList<>();
        for (Track track : tracks) labels.add(track.name + "\n" + ChapterEdits.format(track.length()));
        list.setAdapter(new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, labels) {
            @Override public android.view.View getView(int position, android.view.View recycled, android.view.ViewGroup parent) {
                TextView text = (TextView) super.getView(position, recycled, parent);
                text.setTextColor(Ui.TEXT);
                return text;
            }
        });
        updateButtons();
    }

    private void setBusy(boolean active, String message) {
        busy = active;
        if (active) cancelled = false;
        status.setText(message);
        updateButtons();
    }

    private void updateButtons() {
        add.setEnabled(!busy);
        chapters.setEnabled(!busy);
        fade.setEnabled(!busy);
        export.setEnabled(busy || tracks.size() >= 2);
        export.setText(busy ? "Cancelar" : "Gerar MP3 único");
    }

    private void check() throws InterruptedIOException {
        if (cancelled || Thread.currentThread().isInterrupted()) throw new InterruptedIOException("Operação cancelada.");
    }

    private void generate() {
        discardPrepared();
        List<Track> selection = new ArrayList<>(tracks);
        boolean transition = fade.isChecked();
        int bitrate = Mp3Quality.get(this);
        setBusy(true, "Preparando conversão…");
        worker.execute(() -> {
            File temporary = null;
            try {
                temporary = File.createTempFile("onda-mix-", ".mp3", getCacheDir());
                try (OutputStream output = new BufferedOutputStream(new FileOutputStream(temporary));
                     Mp3Converter.Encoder encoder = new Mp3Converter.Encoder(output, MixMp3.RATE, 2, bitrate)) {
                    MixMp3 mix = new MixMp3((buffer, frames) -> { check(); encoder.write(buffer, frames); });
                    for (int i = 0; i < selection.size(); i++) {
                        check();
                        Track track = selection.get(i);
                        String progress = "Convertendo faixa " + (i + 1) + " de " + selection.size();
                        runOnUiThread(() -> { if (!cancelled && !isDestroyed()) status.setText(progress); });
                        if (!track.stamp.equals(AudioChapterStore.stamp(this, track.uri)))
                            throw new IOException("O arquivo mudou: " + track.name);
                        int overlap = transition && i + 1 < selection.size()
                                ? MixMp3.overlap(track.length(), selection.get(i + 1).length()) : 0;
                        mix.begin(overlap);
                        int[] sampleRate = {0};
                        try (MediaInput.Direct input = MediaInput.open(this, track.uri)) {
                            if (input == null) throw new IOException("Arquivo indisponível: " + track.name);
                            ChapterMp3Exporter.pcm(input, track.start, track.end, new ChapterMp3Exporter.Control() {
                                @Override public void check() throws IOException { MixMp3Activity.this.check(); }
                                @Override public void progress(long at, long total) {}
                            }, (samples, count, rate, channels) -> {
                                sampleRate[0] = rate;
                                mix.pcm(samples, count, rate, channels);
                            });
                        }
                        if (!track.stamp.equals(AudioChapterStore.stamp(this, track.uri)))
                            throw new IOException("O arquivo mudou: " + track.name);
                        mix.end(sampleRate[0]);
                    }
                    mix.finish();
                    encoder.finish();
                }
                check();
                File complete = temporary;
                temporary = null;
                runOnUiThread(() -> {
                    if (cancelled || isDestroyed() || isFinishing()) {
                        complete.delete();
                        if (!isDestroyed() && !isFinishing()) setBusy(false, "Conversão cancelada.");
                        return;
                    }
                    prepared = complete;
                    setBusy(false, "Escolha onde salvar a coletânea.");
                    try {
                        startActivityForResult(new Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                                .setType("audio/mpeg").putExtra(Intent.EXTRA_TITLE, "Coletânea do Onda.mp3"), SAVE);
                    } catch (android.content.ActivityNotFoundException error) {
                        discardPrepared();
                        status.setText("O seletor de arquivos está indisponível.");
                    }
                });
            } catch (IOException | RuntimeException error) { report(error); }
            finally { if (temporary != null) temporary.delete(); }
        });
    }

    private void copy(Uri target) {
        File source = prepared;
        prepared = null;
        if (source == null) { status.setText("Gere novamente o MP3 antes de salvar."); return; }
        setBusy(true, "Salvando MP3…");
        worker.execute(() -> {
            try (android.os.ParcelFileDescriptor file = getContentResolver().openFileDescriptor(target, "rw")) {
                if (file == null || Os.fstat(file.getFileDescriptor()).st_size != 0)
                    throw new IOException("Escolha um arquivo novo e vazio.");
                try (InputStream input = new BufferedInputStream(new FileInputStream(source));
                     OutputStream output = new android.os.ParcelFileDescriptor.AutoCloseOutputStream(
                             android.os.ParcelFileDescriptor.dup(file.getFileDescriptor()))) {
                    byte[] bytes = new byte[65536];
                    int n;
                    while ((n = input.read(bytes)) != -1) { check(); output.write(bytes, 0, n); }
                    output.flush();
                    check();
                } catch (IOException | RuntimeException error) {
                    Os.ftruncate(file.getFileDescriptor(), 0);
                    throw error;
                }
                runOnUiThread(() -> { if (!isDestroyed()) setBusy(false, "MP3 salvo."); });
            } catch (Exception error) { report(error); }
            finally { source.delete(); }
        });
    }

    private void report(Exception error) {
        runOnUiThread(() -> {
            if (!isDestroyed() && !isFinishing())
                setBusy(false, cancelled ? "Operação cancelada." : DownloadFailure.describe("Montar MP3", error));
        });
    }

    private void discardPrepared() {
        if (prepared != null) { prepared.delete(); prepared = null; }
    }

    @Override protected void onDestroy() {
        cancelled = true;
        discardPrepared();
        worker.shutdown();
        super.onDestroy();
    }
}
