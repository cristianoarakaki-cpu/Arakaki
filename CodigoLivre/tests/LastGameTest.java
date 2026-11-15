package br.com.arakaki.codigolivre;
import java.util.*;
import java.time.*;
import java.nio.charset.StandardCharsets;
public class LastGameTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 static byte[] b(String s){return s.getBytes(StandardCharsets.UTF_8);}
 static String finished(String id,String date){return "{\"id\":\""+id+"\",\"date\":\""+date+"\",\"status\":{\"type\":{\"state\":\"post\",\"completed\":true,\"name\":\"STATUS_FULL_TIME\"}},\"competitions\":[{\"timeValid\":true,\"competitors\":[{\"team\":{\"id\":\"819\",\"displayName\":\"Flamengo\"},\"score\":{\"displayValue\":\"2\"}},{\"team\":{\"id\":\"1\",\"displayName\":\"Adversário\"},\"score\":\"1\"}]}]}";}
 public static void main(String[]args)throws Exception{
  for(String q:new String[]{"último jogo do flamengo","Qual foi a última partida do Flamengo?","Flamengo jogou contra quem?","Qual o placar do Flamengo?"})check(WebQuery.kind(q)==WebQuery.Kind.FLAMENGO&&WebQuery.lastMatch(q),"Pergunta de jogo passado reconhecida: "+q);
  check(!WebQuery.lastMatch("próximo jogo do Flamengo")&&WebQuery.kind("próximo jogo do Flamengo")==WebQuery.Kind.FLAMENGO,"Próximo jogo continua separado");
  check(!WebQuery.lastMatch("resultado do próximo jogo Flamengo"),"Referência explícita a próximo não é confundida com passado");
  check(WebQuery.kind("último título do Flamengo")==WebQuery.Kind.SEARCH,"Pergunta sobre título não vira pergunta sobre jogo");
  String dictionary="Último ou ultimo tem acento? Dicio dúvidas de português. As duas palavras existem na língua portuguesa.";
  check(SearchRelevance.score("último jogo do flamengo",dictionary)<0,"Palavra último não torna dicionário relevante para Flamengo");
  PublicPage unrelated=new PublicPage("Último ou ultimo tem acento",dictionary,"https://www.dicio.com.br/ultimo-ou-ultimo/",false,Collections.emptyList());
  check(QuickWebAnswer.answer("último jogo do Flamengo",unrelated)==null,"Regressão da imagem: trecho do Dicio recusado");
  check(SearchRelevance.score("como criar programa Android","Criar um programa Android com Activity e Java")>=0,"Fonte realmente relacionada à programação aceita");
  check(SearchRelevance.score("como criar programa Android","Dicionário de português: a palavra criar e seus significados")<0,"Palavra genérica criar não substitui o assunto Android");
  Instant now=Instant.now();String older=finished("old",now.minusSeconds(172800).toString()),recent=finished("recent",now.minusSeconds(7200).toString());
  String future=OnlineResearchTest.event("future",now.plusSeconds(86400).toString(),"STATUS_SCHEDULED","819");
  var matches=OnlineResearch.parseMatches(b("{\"events\":["+future+","+older+","+recent+"]}"),"bra.1");
  var last=LiveFeeds.latest(matches,now);check(last!=null&&last.id.equals("recent")&&last.completed,"Último é o encerrado mais recente, não o próximo");
  check(LiveFeeds.earliest(matches,now).id.equals("future"),"Próximo ignora os encerrados");
  check(LiveFeeds.describe(last).contains("Flamengo 2 x 1 Adversário"),"Placar preserva nomes e ordem dos participantes");
  String live=recent.replace("\"post\"","\"in\"");check(OnlineResearch.parseMatches(b("{\"events\":["+live+"]}"),"bra.1").isEmpty(),"Jogo em andamento não é marcado como encerrado");
  String cancelled=recent.replace("STATUS_FULL_TIME","STATUS_CANCELED");check(OnlineResearch.parseMatches(b("{\"events\":["+cancelled+"]}"),"bra.1").isEmpty(),"Jogo cancelado não vira último resultado");
  String noScore=recent.replace("{\"displayValue\":\"2\"}","null");var missing=OnlineResearch.parseMatches(b("{\"events\":["+noScore+"]}"),"bra.1").get(0);check(LiveFeeds.describe(missing).contains("não informado"),"Placar ausente não é inventado");
  List<String> urls=Collections.synchronizedList(new ArrayList<>());
  var result=new OnlineResearch(url->{urls.add(url);return b("{\"events\":["+older+","+recent+","+future+"]}");},()->false).run("último jogo do flamengo",s->{});
  check(result.direct!=null&&result.direct.contains("Último jogo encerrado")&&result.direct.contains("2 x 1"),"Pergunta exata produz resposta esportiva direta");
  check(urls.stream().allMatch(u->u.contains("site.api.espn.com")&&u.contains("fixture=false")),"Não busca a palavra último no buscador genérico");
  var unknown=new OnlineResearch(url->b("{\"events\":["+future+"]}"),()->false).run("último jogo do Flamengo",s->{});check(unknown.direct.contains("Não consegui confirmar o último jogo")&&!unknown.direct.contains("Próximo jogo encontrado"),"Sem resultado encerrado, não responde com partida futura");
  String rss="<rss><channel><item><title>Último ou ultimo tem acento?</title><link>https://www.dicio.com.br/ultimo-ou-ultimo/</link><description>As palavras existem na língua portuguesa.</description></item></channel></rss>";
  var irrelevant=new OnlineResearch(url->url.contains("www.bing.com")?b(rss):b("<html><title>Dicionário</title><article>"+dictionary.repeat(3)+"</article></html>"),()->false).run("último jogo do Palmeiras",s->{});check(irrelevant.quick==null&&irrelevant.evidence.contains("descartada"),"Outra consulta esportiva também recusa página de dicionário");
  System.out.println(passed+" verificações de último jogo e relevância passaram com dados simulados.");
 }
}
