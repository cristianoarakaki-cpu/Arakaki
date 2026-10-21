package br.com.onda;

import java.text.Normalizer;
import java.util.Locale;

/** Search accepts accents, punctuation and words in any order. */
public final class SearchText {
    public static String normalize(CharSequence value) {
        if (value == null) return "";
        return Normalizer.normalize(value, Normalizer.Form.NFD).replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.ROOT).replaceAll("[^\\p{L}\\p{N}]+", " ").trim().replaceAll("\\s+", " ");
    }
    public static boolean matches(CharSequence value, String query) {
        String haystack = normalize(value), needle = normalize(query);
        if (needle.isEmpty()) return true;
        for (String word : needle.split(" ")) if (!haystack.contains(word)) return false;
        return true;
    }
    public static String archiveQuery(String input, int mode) {
        String clean = normalize(input);
        StringBuilder q = new StringBuilder("collection:etree AND mediatype:audio AND NOT access-restricted-item:true");
        if (clean.isEmpty()) return q + " AND identifier:__onda_no_results__";
        for (String word : clean.split(" ")) {
            if (mode == 1) q.append(" AND creator:\"").append(word).append("\"");
            else if (mode == 2) q.append(" AND (title:\"").append(word).append("\" OR description:\"").append(word).append("\")");
            else q.append(" AND (title:\"").append(word).append("\" OR creator:\"").append(word).append("\" OR description:\"").append(word).append("\")");
        }
        return q.toString();
    }
}
