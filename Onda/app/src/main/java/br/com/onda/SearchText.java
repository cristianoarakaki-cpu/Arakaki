package br.com.onda;

import java.text.Normalizer;
import java.util.Locale;

/** Search accepts accents, punctuation and words in any order. */
public final class SearchText {
    private static final java.util.regex.Pattern MARKS=java.util.regex.Pattern.compile("\\p{M}+"), SEPARATORS=java.util.regex.Pattern.compile("[^\\p{L}\\p{N}]+"), SPACES=java.util.regex.Pattern.compile("\\s+"), JOINERS=java.util.regex.Pattern.compile("\\b(?:e|and)\\b");
    public static final class Query {
        private final String[] words;private Query(String query){String text=catalogTerm(query);words=text.isEmpty()?new String[0]:text.split(" ");}
        public boolean isEmpty(){return words.length==0;}
        public boolean matches(CharSequence text){if(words.length==0)return true;String haystack=normalize(text);for(String word:words)if(!haystack.contains(word))return false;return true;}
    }
    public static Query prepare(String query){return new Query(query);}
    public static String normalize(CharSequence value) {
        if (value == null) return "";
        String text=MARKS.matcher(Normalizer.normalize(value,Normalizer.Form.NFD)).replaceAll("").toLowerCase(Locale.ROOT);return SPACES.matcher(SEPARATORS.matcher(text).replaceAll(" ").trim()).replaceAll(" ");
    }
    public static boolean matches(CharSequence value,String query){return prepare(query).matches(value);}
    public static String spokenQuery(String input){
        if(input==null)return "";
        return input.trim().replaceFirst("(?iu)^(?:busque|buscar|pesquise|pesquisar|procure|procurar)(?:\\s+por)?\\s+(?:(?:a\\s+)?m[úu]sica\\s+|(?:o\\s+)?artista\\s+)?", "").trim();
    }
    public static String catalogTerm(String input){
        return SPACES.matcher(JOINERS.matcher(normalize(input)).replaceAll(" ").trim()).replaceAll(" ");
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
