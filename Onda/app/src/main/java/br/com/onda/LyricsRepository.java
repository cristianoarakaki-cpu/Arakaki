package br.com.onda;

import android.content.Context;
import android.net.Uri;
import org.json.JSONObject;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;

/** Only song metadata is sent to LRCLIB, never the audio file. */
final class LyricsRepository {
    static final class Result {
        final String synced, plain;
        final boolean instrumental;
        Result(JSONObject json) {
            synced = json.isNull("syncedLyrics") ? "" : json.optString("syncedLyrics", "");
            plain = json.isNull("plainLyrics") ? "" : json.optString("plainLyrics", "");
            instrumental = json.optBoolean("instrumental", false);
        }
    }
    static Result fetch(Context context, String title, String artist, long duration) throws Exception {
        String key = title + "\n" + artist + "\n" + duration;
        StringBuilder hash = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(key.getBytes(StandardCharsets.UTF_8))) hash.append(String.format(java.util.Locale.ROOT, "%02x", b & 255));
        File directory = new File(context.getCacheDir(), "lyrics");
        File cached = new File(directory, hash + ".json");
        if (cached.isFile()) {
            try { return new Result(new JSONObject(new String(Files.readAllBytes(cached.toPath()), StandardCharsets.UTF_8))); }
            catch (Exception ignored) { cached.delete(); }
        }
        Uri.Builder uri = Uri.parse("https://lrclib.net/api/get").buildUpon().appendQueryParameter("track_name", title).appendQueryParameter("artist_name", artist);
        if (duration > 0) uri.appendQueryParameter("duration", Long.toString(Math.round(duration / 1000.0)));
        HttpURLConnection conn = (HttpURLConnection) new URL(uri.build().toString()).openConnection();
        conn.setConnectTimeout(10000); conn.setReadTimeout(15000);
        conn.setRequestProperty("User-Agent", "Onda/0.2.0 (https://github.com/cristianoarakaki-cpu/Arakaki)");
        conn.setRequestProperty("Accept", "application/json");
        try {
            int code = conn.getResponseCode();
            if (code == 404) return null;
            if (code != 200) throw new IOException("HTTP " + code);
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (InputStream in = conn.getInputStream()) {
                byte[] block = new byte[4096]; int count;
                while ((count = in.read(block)) != -1) {
                    if (Thread.currentThread().isInterrupted()) throw new InterruptedIOException();
                    if (bytes.size() + count > 1048576) throw new IOException("Resposta muito grande");
                    bytes.write(block, 0, count);
                }
            }
            byte[] raw = bytes.toByteArray();
            Result result = new Result(new JSONObject(new String(raw, StandardCharsets.UTF_8)));
            if (result.instrumental || !result.synced.isEmpty() || !result.plain.isEmpty()) {
                try {
                    if (directory.isDirectory() || directory.mkdirs()) {
                        File[] old = directory.listFiles();
                        if (old != null && old.length >= 100) { java.util.Arrays.sort(old, java.util.Comparator.comparingLong(File::lastModified)); old[0].delete(); }
                        Files.write(cached.toPath(), raw);
                    }
                } catch (IOException ignored) { /* A cache failure must not hide downloaded lyrics. */ }
            }
            return result;
        } finally { conn.disconnect(); }
    }
}
