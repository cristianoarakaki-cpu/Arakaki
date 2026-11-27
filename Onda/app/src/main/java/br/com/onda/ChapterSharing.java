package br.com.onda;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import android.text.InputFilter;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import java.io.File;
import java.io.IOException;
import java.io.InterruptedIOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

final class ChapterSharing {
    private final Activity screen;
    private AlertDialog dialog;
    private AtomicBoolean cancellation;

    ChapterSharing(Activity screen) { this.screen = screen; }

    void choose(Uri source, String stamp, AudioChapterStore.Data data, int single) {
        if (single >= 0) {
            name(source, stamp, data, new int[]{single});
            return;
        }
        String[] labels = new String[data.chapters.size()];
        boolean[] checked = new boolean[labels.length];
        for (int i = 0; i < labels.length; i++) labels[i] = AudioChapterStore.label(data, i);
        dialog = new AlertDialog.Builder(screen).setTitle("Escolha as faixas")
                .setMultiChoiceItems(labels, checked, (d, i, on) -> {
                    checked[i] = on;
                    boolean any = false;
                    for (boolean selected : checked) any |= selected;
                    ((AlertDialog) d).getButton(AlertDialog.BUTTON_POSITIVE).setEnabled(any);
                }).setNegativeButton("Cancelar", null).setPositiveButton("Continuar", (d, button) -> {
                    int count = 0;
                    for (boolean on : checked) if (on) count++;
                    int[] indices = new int[count];
                    int next = 0;
                    for (int i = 0; i < checked.length; i++) if (checked[i]) indices[next++] = i;
                    if (count > 0) name(source, stamp, data, indices);
                }).show();
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setEnabled(false);
    }

    private void name(Uri source, String stamp, AudioChapterStore.Data data, int[] indices) {
        LinearLayout fields = new LinearLayout(screen);
        fields.setOrientation(LinearLayout.VERTICAL);
        fields.setPadding(Ui.dp(screen, 16), 0, Ui.dp(screen, 16), 0);
        EditText[] inputs = new EditText[indices.length];
        for (int i = 0; i < indices.length; i++) {
            String label = AudioChapterStore.label(data, indices[i]);
            fields.addView(Ui.text(screen, label, 14, Ui.TEXT));
            EditText input = new EditText(screen);
            input.setSingleLine(true);
            input.setHint("Nome do MP3");
            input.setContentDescription("Nome do MP3 para " + label);
            input.setFilters(new InputFilter[]{new InputFilter.LengthFilter(80)});
            input.setText(label);
            fields.addView(input);
            inputs[i] = input;
        }
        ScrollView scroll = new ScrollView(screen);
        scroll.addView(fields);
        dialog = new AlertDialog.Builder(screen).setTitle("Nome dos arquivos MP3")
                .setView(scroll).setNegativeButton("Cancelar", null).setPositiveButton("Compartilhar", null).show();
        AlertDialog naming = dialog;
        naming.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            String[] names = new String[inputs.length];
            Set<String> used = new HashSet<>();
            for (int i = 0; i < inputs.length; i++) {
                String entered = inputs[i].getText().toString().trim().replaceFirst("(?i)\\.mp3$", "");
                if (entered.trim().isEmpty()) { inputs[i].setError("Digite um nome"); return; }
                String base = DownloadLinks.filename(entered);
                String candidate = base;
                int duplicate = 2;
                while (!used.add(candidate.toLowerCase(Locale.ROOT))) candidate = base + " (" + duplicate++ + ")";
                names[i] = candidate + ".mp3";
            }
            naming.dismiss();
            prepare(source, stamp, data, indices, names);
        });
    }

    private void prepare(Uri source, String stamp, AudioChapterStore.Data data, int[] indices, String[] names) {
        AtomicBoolean cancelled = new AtomicBoolean();
        cancellation = cancelled;
        AlertDialog progress = new AlertDialog.Builder(screen).setTitle("Preparar compartilhamento")
                .setMessage("Convertendo as faixas em MP3…")
                .setNegativeButton("Cancelar", (d, w) -> cancelled.set(true))
                .setOnCancelListener(d -> cancelled.set(true)).show();
        dialog = progress;
        int bitrate = Mp3Quality.get(screen);
        new Thread(() -> {
            File base = new File(screen.getCacheDir(), "shares");
            File folder = new File(base, "chapters-" + java.util.UUID.randomUUID());
            ArrayList<Uri> files = new ArrayList<>();
            try {
                File[] expired = base.listFiles(file -> file.isDirectory() && file.getName().startsWith("chapters-")
                        && System.currentTimeMillis() - file.lastModified() > 86400000L);
                if (expired != null) for (File old : expired) delete(old);
                if (!folder.mkdirs()) throw new IOException("Não foi possível criar os arquivos temporários.");
                verify(source, stamp);
                for (int i = 0; i < indices.length; i++) {
                    if (cancelled.get()) throw new InterruptedIOException();
                    int index = indices[i];
                    long start = data.chapters.get(index).start;
                    long end = index + 1 < data.chapters.size() ? data.chapters.get(index + 1).start : data.duration;
                    DownloadStorage.check(base, (end - start) * bitrate / 8 + 65536);
                    int step = i + 1;
                    screen.runOnUiThread(() -> {
                        if (progress.isShowing()) progress.setMessage("Preparando faixa " + step + " de " + indices.length);
                    });
                    File output = new File(folder, names[i]);
                    try (MediaInput.Direct media = MediaInput.open(screen, source)) {
                        if (media == null) throw new IOException("Arquivo original indisponível.");
                        ChapterMp3Exporter.convert(media, output, bitrate, start, end, new ChapterMp3Exporter.Control() {
                            public void check() throws IOException {
                                if (cancelled.get()) throw new InterruptedIOException();
                            }
                            public void progress(long at, long total) {}
                        });
                    }
                    files.add(FileProvider.getUriForFile(screen, screen.getPackageName() + ".share", output));
                }
                verify(source, stamp);
                screen.runOnUiThread(() -> {
                    progress.dismiss();
                    if (cancelled.get() || screen.isFinishing() || screen.isDestroyed()) {
                        delete(folder);
                        return;
                    }
                    try { screen.startActivity(Intent.createChooser(send(files), "Compartilhar faixas")); }
                    catch (RuntimeException error) { delete(folder); notifyError(error); }
                });
            } catch (IOException | RuntimeException error) {
                delete(folder);
                screen.runOnUiThread(() -> {
                    progress.dismiss();
                    if (!cancelled.get() && !screen.isFinishing() && !screen.isDestroyed()) notifyError(error);
                });
            }
        }, "onda-share-chapters").start();
    }

    private void verify(Uri source, String stamp) throws IOException {
        if (!stamp.equals(AudioChapterStore.stamp(screen, source)))
            throw new IOException("O arquivo original mudou. Confira as divisões novamente.");
    }

    static Intent send(ArrayList<Uri> files) {
        boolean multiple = files.size() > 1;
        Intent send = new Intent(multiple ? Intent.ACTION_SEND_MULTIPLE : Intent.ACTION_SEND);
        send.setType("audio/mpeg").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        if (multiple) send.putParcelableArrayListExtra(Intent.EXTRA_STREAM, files);
        else send.putExtra(Intent.EXTRA_STREAM, files.get(0));
        ClipData clips = ClipData.newRawUri("MP3 do Onda", files.get(0));
        for (int i = 1; i < files.size(); i++) clips.addItem(new ClipData.Item(files.get(i)));
        send.setClipData(clips);
        return send;
    }

    private void notifyError(Exception error) {
        Toast.makeText(screen, DownloadFailure.describe("Compartilhar faixas", error), Toast.LENGTH_LONG).show();
    }

    private static void delete(File folder) {
        File[] children = folder.listFiles();
        if (children != null) for (File file : children) file.delete();
        folder.delete();
    }

    void close() {
        if (cancellation != null) cancellation.set(true);
        if (dialog != null) dialog.dismiss();
    }
}
