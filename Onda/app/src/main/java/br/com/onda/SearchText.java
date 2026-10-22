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
        String haystack = normalize(value), needle = catalogTerm(query);
        if (needle.isEmpty()) return true;
        for (String word : needle.split(" ")) if (!haystack.contains(word)) return false;
        return true;
    }
    public static String spokenQuery(String input){
        if(input==null)return "";
        return input.trim().replaceFirst("(?iu)^(?:busque|buscar|pesquise|pesquisar|procure|procurar)(?:\\s+por)?\\s+(?:(?:a\\s+)?m[úu]sica\\s+|(?:o\\s+)?artista\\s+)?", "").trim();
    }
    public static String catalogTerm(String input){
        return normalize(input).replaceAll("\\b(?:e|and)\\b", " ").trim().replaceAll("\\s+", " ");
    }
    public static int relevance(String input,String title,String artist){
        String needle=catalogTerm(input),name=catalogTerm(title),singer=catalogTerm(artist);
        if(needle.isEmpty())return 0;
        int score=singer.equals(needle)?2000:name.equals(needle)?800:0;
        boolean allArtist=true,allTitle=true;
        for(String word:needle.split(" ")){allArtist&=singer.contains(word);allTitle&=name.contains(word);}
        return score+(allArtist?1200:0)+(allTitle?200:0);
    }
    public static String archiveQuery(String input, int mode) {
        String clean = catalogTerm(input);
        StringBuilder q = new StringBuilder("collection:etree AND NOT access-restricted-item:true");
        if (clean.isEmpty()) return q + " AND identifier:__onda_no_results__";
        for (String word : clean.split(" ")) {
            if (mode == 1) q.append(" AND creator:\"").append(word).append("\"");
            else if (mode == 2) q.append(" AND (title:\"").append(word).append("\" OR description:\"").append(word).append("\")");
            else q.append(" AND (title:\"").append(word).append("\" OR creator:\"").append(word).append("\" OR description:\"").append(word).append("\")");
        }
        return q.toString();
    }
}
