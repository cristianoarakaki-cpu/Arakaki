package br.com.arakaki.codigolivre;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;
import java.util.concurrent.CancellationException;
public class OnlineResearchTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 interface Task{void run()throws Exception;}
 static void rejects(Task task,String label)throws Exception{boolean failed=false;try{task.run();}catch(Exception e){failed=true;}check(failed,label);}
 static byte[] b(String s){return s.getBytes(StandardCharsets.UTF_8);}
 static String rss="<rss><channel><item><title>Manchete de teste &amp; fonte</title><link>https://example.org/noticia</link><pubDate>Sun, 15 Nov 2026 12:00:00 GMT</pubDate><source>Veículo de teste</source><description><![CDATA[<b>Trecho</b> de teste]]></description></item></channel></rss>";
 static String event(String id,String date,String state,String team){return "{\"id\":\""+id+"\",\"date\":\""+date+"\",\"status\":{\"type\":{\"state\":\"pre\",\"name\":\""+state+"\"}},\"competitions\":[{\"timeValid\":true,\"competitors\":[{\"team\":{\"id\":\""+team+"\",\"displayName\":\"Flamengo\"}},{\"team\":{\"id\":\"1\",\"displayName\":\"Adversário\"}}]}]}";}
 public static void main(String[]args)throws Exception{
  check(WebQuery.kind("Últimas notícias no Brasil e no mundo")==WebQuery.Kind.NEWS,"Notícias atuais detectadas");
  check(WebQuery.kind("Quando será o próximo jogo do Flamengo?")==WebQuery.Kind.FLAMENGO,"Próximo jogo detectado");
  check(WebQuery.kind("Como criar um app Android?")==WebQuery.Kind.SEARCH,"Programação usa pesquisa geral");
  check(WebQuery.kind("notícias do Flamengo")==WebQuery.Kind.NEWS,"Notícia do clube não é confundida com calendário");
  check(WebQuery.terms("Crie um app Android com lista de tarefas").equals("Crie um app Android com lista de tarefas"),"Pergunta natural vira termos de busca");
  check(WebQuery.terms("public class Test { String senha=\"segredo\"; }").startsWith("documentação programação")&&!WebQuery.terms("public class Test { String senha=\"segredo\"; }").contains("segredo"),"Código não é enviado como consulta literal");
  check(WebQuery.terms("def teste(x): return x".repeat(100)).startsWith("documentação programação"),"Pedido extenso gera termos genéricos");
  check(WebQuery.requiresFreshness("Qual a versão mais recente do Android?"),"Pergunta de informação atual reconhecida");
  rejects(()->WebQuery.allowed("http://news.google.com/rss"),"HTTP não seguro recusado");rejects(()->WebQuery.allowed("https://127.0.0.1/rss"),"Destino interno recusado");rejects(()->WebQuery.allowed("https://user@news.google.com/rss"),"Credencial em URL recusada");
  var items=LiveFeeds.rss(b(rss));check(items.size()==1&&items.get(0).title.contains("& fonte")&&items.get(0).source.equals("Veículo de teste"),"RSS preserva título e veículo");
  check(items.get(0).description.equals("Trecho de teste"),"HTML dos trechos vira texto");
  check(LiveFeeds.time(items.get(0).date).contains("09:00 Brasília"),"Horário RSS convertido para Brasília");
  rejects(()->LiveFeeds.rss(b("<!DOCTYPE rss [<!ENTITY x SYSTEM 'file:///etc/passwd'>]><rss/>")),"RSS com entidades recusado");
  check(LiveFeeds.rss(b(rss.replace("https://example.org/noticia","javascript:alert(1)"))).isEmpty(),"Link não HTTPS descartado");
  List<String> requested=new ArrayList<>();OnlineResearch mock=new OnlineResearch(url->{requested.add(url);return b(rss);},()->false);
  var news=mock.run("notícias no Brasil e no mundo",s->{});check(news.direct!=null&&news.found&&requested.stream().filter(u->u.contains("news.google.com")).count()==2&&requested.stream().anyMatch(u->u.contains("NATION"))&&requested.stream().anyMatch(u->u.contains("WORLD")),"Notícias consultam Brasil e Mundo sem geração local");
  check(news.direct.contains("Fonte")||news.direct.contains("Veículo:"),"Resposta direta mantém origem");
  var coding=mock.run("Como criar app Android com Java?",s->{});check(coding.direct==null&&coding.evidence.contains("Trecho de teste")&&requested.stream().anyMatch(u->u.contains("format=rss")),"Busca de programação fornece evidências para IA");
  var offline=new OnlineResearch(url->{throw new java.io.IOException("sem rede");},()->false).run("notícias hoje",s->{});check(!offline.found&&offline.direct.contains("Não foi possível obter fontes"),"Falha de rede não inventa notícia");
  rejects(()->new OnlineResearch(url->b(rss),()->true).run("notícias",s->{}),"Cancelamento antes da rede respeitado");
  Instant now=Instant.now();String soon=now.plusSeconds(3600).toString(),later=now.plusSeconds(86400).toString();
  String json="{\"events\":["+event("later",later,"STATUS_SCHEDULED","819")+","+event("soon",soon,"STATUS_SCHEDULED","819")+","+event("wrong",now.plusSeconds(10).toString(),"STATUS_SCHEDULED","999")+","+event("postponed",now.plusSeconds(1).toString(),"STATUS_POSTPONED","819")+"]}";
  var matches=OnlineResearch.parseMatches(b(json),"bra.1");check(matches.size()==2,"Calendário ignora outro time e partida adiada");
  var next=LiveFeeds.earliest(matches,now);check(next.id.equals("soon")&&next.competition.equals("Campeonato Brasileiro"),"Menor data futura e competição traduzida");
  check(LiveFeeds.earliest(matches,now.plusSeconds(999999))==null,"Jogos passados não são apresentados como próximos");
  check(LiveFeeds.describe(next).contains("Brasília")&&LiveFeeds.describe(next).contains("https://"),"Jogo inclui fuso e fonte");
  var fixture=new OnlineResearch(url->b(json),()->false).run("próximo jogo do Flamengo",s->{});check(fixture.direct.contains("Próximo jogo encontrado")&&fixture.direct.contains("Outras competições"),"Resposta de jogo informa limites das competições consultadas");
  var missing=new OnlineResearch(url->b("{\"events\":[]}"),()->false).run("quando o Flamengo joga",s->{});check(!missing.found&&missing.direct.contains("Não consegui confirmar"),"Calendário vazio não vira data inventada");
  check(!AndroidKit.PREPARE_COMMAND.contains("\\\"")&&AndroidKit.PREPARE_COMMAND.contains("\"$HOME/storage/downloads/"),"Comando do kit preserva aspas para caminhos com espaços");
  check(!WebQuery.shouldSearch("Analise este arquivo",true)&&WebQuery.shouldSearch("Como criar um app Android?",false),"Consulta genérica de anexo evita rede desnecessária");
  System.out.println(passed+" verificações online/kit passaram com fontes simuladas, sem rede externa.");
 }
}
