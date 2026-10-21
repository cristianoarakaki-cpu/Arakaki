package br.com.onda;

import java.util.*;
import java.util.regex.*;

/** Parses ordinary LRC, including repeated timestamps and global offsets. */
public final class Lrc {
    public static final class Line {
        public final long ms;
        public final String text;
        Line(long ms, String text) { this.ms = ms; this.text = text; }
    }
    public static List<Line> parse(String input) {
        ArrayList<Line> lines = new ArrayList<>();
        if (input == null) return lines;
        Matcher offsetMatcher = Pattern.compile("\\[offset:([+-]?\\d+)\\]", Pattern.CASE_INSENSITIVE).matcher(input);
        long offset = 0;
        if (offsetMatcher.find()) { try { offset = Long.parseLong(offsetMatcher.group(1)); } catch (NumberFormatException ignored) {} }
        Pattern stamp = Pattern.compile("\\[(\\d{1,4}):([0-5]\\d)(?:[.:](\\d{1,3}))?\\]");
        for (String raw : input.split("\\r?\\n")) {
            Matcher m = stamp.matcher(raw);
            ArrayList<Long> times = new ArrayList<>();
            int end = 0;
            while (m.find()) {
                String fraction = m.group(3);
                long frac = fraction == null ? 0 : Long.parseLong((fraction + "000").substring(0, 3));
                times.add(Long.parseLong(m.group(1)) * 60000 + Long.parseLong(m.group(2)) * 1000 + frac + offset);
                end = m.end();
            }
            String text = raw.substring(end).replaceAll("<\\d+:\\d+(?:\\.\\d+)?>", "").trim();
            for (long time : times) lines.add(new Line(Math.max(0, time), text));
        }
        lines.sort(Comparator.comparingLong(l -> l.ms));
        return lines;
    }
    public static int active(List<Line> lines, long ms) {
        int lo = 0, hi = lines.size() - 1, result = -1;
        while (lo <= hi) { int mid = (lo + hi) >>> 1; if (lines.get(mid).ms <= ms) { result = mid; lo = mid + 1; } else hi = mid - 1; }
        return result;
    }
}
