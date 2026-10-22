package br.com.onda;

public final class SearchTextTest {
    private static void check(boolean ok){if(!ok)throw new AssertionError();}
    public static void main(String[] args){
        check(SearchText.matches("João — Coração de Papel", "coracao JOAO"));
        check(SearchText.matches("Gilberto Gil", "gil"));
        check(SearchText.matches("Beyoncé", "beyonce"));
        check(!SearchText.matches("Ana Carolina", "ana maria"));
        check(SearchText.matches(null, ""));
        check(!SearchText.matches(null, "artista"));
        check(SearchText.normalize("  ÁGUA...  VIVA!! ").equals("agua viva"));
        String artist=SearchText.archiveQuery("Grateful Dead",1);
        check(!artist.contains("mediatype:audio"));
        check(artist.contains("creator:\"grateful\"")&&!artist.contains("description:"));
        String song=SearchText.archiveQuery("Coração",2);
        check(song.contains("description:\"coracao\"")&&!song.contains("creator:"));
        check(SearchText.archiveQuery("x\" OR collection:other",0).startsWith("collection:etree AND"));
        check(!SearchText.archiveQuery("x\" OR collection:other",0).contains("collection:other"));
        check(SearchText.archiveQuery("?!",0).contains("__onda_no_results__"));
        check(SearchText.catalogTerm("Chitãozinho e Xororó").equals("chitaozinho xororo"));
        check(SearchText.matches("Chitãozinho & Xororó", "Chitaozinho e xororo"));
        check(SearchText.spokenQuery("Buscar por Chitãozinho e Xororó").equals("Chitãozinho e Xororó"));
        check(SearchText.spokenQuery("pesquise a música Evidências").equals("Evidências"));
        check(SearchText.spokenQuery("Buscar").equals("Buscar"));
        check(SearchText.spokenQuery(null).isEmpty());
        check(SearchText.relevance("Chitaozinho e xororo","Evidências","Chitãozinho & Xororó") > SearchText.relevance("Chitaozinho e xororo","Chitãozinho e Xororó","Tonico & Tinoco"));
        System.out.println("Search: accents, word order, partial names, multiple terms, null metadata, field modes and query escaping passed.");
    }
}
