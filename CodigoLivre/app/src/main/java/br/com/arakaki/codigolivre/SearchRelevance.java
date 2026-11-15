package br.com.arakaki.codigolivre;
import java.util.*;
/** Filtro conservador: coincidência de uma palavra temporal não confirma o assunto. */
final class SearchRelevance {
 static final Set<String> STOP=new HashSet<>(Arrays.asList("ultimo","ultima","ultimos","ultimas","proximo","proxima","proximos","proximas","hoje","ontem","amanha","agora","como","qual","quais","para","sobre","seria","quando","onde","esse","essa","isso","voce","pode","poderia","pesquise","pesquisa","buscar","busque","saber","noticias","informacao","informacoes","resultado"));
 static Set<String> words(String text){Set<String> words=new HashSet<>();for(String token:WebQuery.normalized(text).split("[^a-z0-9]+"))if(token.length()>=4&&!STOP.contains(token))words.add(token.endsWith("s")?token.substring(0,token.length()-1):token);return words;}
 static int score(String question,String text){Set<String> required=words(question),actual=words(text);if(required.isEmpty())return -1;
  for(String anchor:new String[]{"flamengo","corinthians","palmeiras","botafogo","fluminense","python","android","kotlin","javascript","powershell","access","excel","java","sql","vba"})if(WebQuery.normalized(question).matches("(?s).*\\b"+anchor+"\\b.*")&&!WebQuery.normalized(text).matches("(?s).*\\b"+anchor+"\\b.*"))return -1;
  int matches=0;for(String word:required)if(actual.contains(word))matches++;
  int minimum=required.size()==2?2:Math.max(1,(required.size()+1)/2);return matches>=minimum?100*matches/required.size():-1;
 }
}
