package br.com.arakaki.codigolivre;
import java.text.Normalizer;
import java.net.URI;
import java.util.*;
final class WebQuery {
    enum Kind {NEWS,FLAMENGO,SEARCH}
    static String normalized(String s){return Normalizer.normalize(s,Normalizer.Form.NFD).replaceAll("\\p{M}","").toLowerCase(Locale.ROOT);}
    static Kind kind(String question){String q=normalized(question);if(q.contains("flamengo")&&q.matches("(?s).*\\b(jogos?|joga|jogou|jogara|partidas?|placar|resultado|venceu|ganhou|perdeu)\\b.*")&&!q.contains("noticia"))return Kind.FLAMENGO;return q.matches("(?s).*(noticia|manchete|noticiario).*")?Kind.NEWS:Kind.SEARCH;}
    static boolean lastMatch(String question){String q=normalized(question);if(q.matches("(?s).*\\b(proximo|proxima|amanha)\\b.*"))return false;return q.matches("(?s).*\\b(ultimo|ultima|anterior|passado|jogou|placar|resultado|venceu|ganhou|perdeu|terminou)\\b.*")||q.contains("mais recente");}
    static String terms(String question){
        String q=question.trim();String n=normalized(q);
        boolean code=q.length()>600||q.contains("```")||q.contains("{")||q.contains("}")||q.contains("=>")||n.matches("(?s).*(option explicit|public class|def \\w+\\(|select .+ from |private sub|function \\w+\\().*");
        if(code){List<String> languages=new ArrayList<>();for(String lang:new String[]{"Android","Kotlin","VBA","Access","PowerShell","Python","JavaScript","SQL","Excel","Java"})if(n.contains(lang.toLowerCase(Locale.ROOT)))languages.add(lang);return "documentação programação "+(languages.isEmpty()?"desenvolvimento de software":String.join(" ",languages));}
        q=q.replaceAll("\\s+"," ");return q.length()>240?q.substring(0,240):q;
    }
    static boolean requiresFreshness(String question){String q=normalized(question);return kind(question)!=Kind.SEARCH||q.matches("(?s).*(hoje|agora|atual|ultimo|ultima|proximo|preco|cotacao|tempo real|versao mais recente).*" );}
    static boolean shouldSearch(String question,boolean hasSource){String q=normalized(question);return !hasSource||kind(question)!=Kind.SEARCH||requiresFreshness(question)||q.length()>=80||q.matches("(?s).*(android|kotlin|versao|como |erro|documentacao|pesquis|busqu).*" );}
    static void allowed(String url){WebSafety.url(url);}
}
