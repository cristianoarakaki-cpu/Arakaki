package br.com.arakaki.codigolivre;
import java.nio.charset.StandardCharsets;
import java.net.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
public class PublicPageTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 interface Task {void run()throws Exception;}
 static void rejects(Task t,String label)throws Exception{boolean caught=false;try{t.run();}catch(Exception e){caught=true;}check(caught,label);}
 static byte[] b(String s){return s.getBytes(StandardCharsets.UTF_8);}
 static String url="https://www.espn.com.br/futebol/time/calendario/_/id/819/flamengo";
 static String sports(){return "<html><head><title>Calendário de teste</title><script type='application/ld+json'>{\"@type\":\"SportsEvent\",\"startDate\":\"2099-11-20T20:30-03:00\",\"homeTeam\":{\"name\":\"Flamengo\"},\"awayTeam\":{\"name\":\"Adversário de teste\"},\"superEvent\":{\"name\":\"Copa de teste\"}}</script></head><body><main>Flamengo e adversário de teste no calendário público. "+"Informação visível de teste. ".repeat(10)+"</main></body></html>";}
 public static void main(String[]args)throws Exception{
  rejects(()->Instant.parse("2099-11-20T23:30Z"),"Regressão: parser antigo recusa ISO sem segundos");
  check(LiveFeeds.instant("2099-11-20T23:30Z").equals(Instant.parse("2099-11-20T23:30:00Z")),"Parser novo aceita hora/minuto UTC");
  check(LiveFeeds.instant("2099-11-20T20:30-03:00").equals(Instant.parse("2099-11-20T23:30:00Z")),"Offset sem segundos convertido corretamente");
  rejects(()->LiveFeeds.instant("2099-11-20T20:30"),"Não presume fuso ausente");
  String event=OnlineResearchTest.event("e","2099-11-20T23:30Z","STATUS_SCHEDULED","819");
  check(OnlineResearch.parseMatches(b("{\"events\":["+event+"]}"),"bra.1").size()==1,"Evento com data sem segundos não é mais descartado");
  rejects(()->OnlineResearch.parseMatches(b("{\"error\":\"invalid\"}"),"bra.1"),"Resposta não reconhecida não conta como calendário válido");
  for(String ip:new String[]{"127.0.0.1","10.1.2.3","172.16.0.1","192.168.1.1","169.254.169.254","100.64.1.1","::1","fc00::1","fe80::1","64:ff9b::a00:1","2002:7f00:1::1"})check(!WebSafety.publicAddress(InetAddress.getByName(ip)),"Destino privado/reservado recusado: "+ip);
  check(WebSafety.publicAddress(InetAddress.getByName("93.184.216.34"))&&WebSafety.publicAddress(InetAddress.getByName("2001:4860:4860::8888")),"Endereços públicos IPv4/IPv6 permitidos");
  rejects(()->WebSafety.url("https://localhost/a"),"localhost recusado");rejects(()->WebSafety.url("https://192.168.1.1/a"),"URL de rede privada recusada");rejects(()->WebSafety.url("http://example.org/a"),"HTTP sem TLS recusado");rejects(()->WebSafety.url("https://user:pass@example.org/a"),"Credenciais em link recusadas");rejects(()->WebSafety.url("https://example.org:8443/a"),"Porta arbitrária recusada");
  check(WebSafety.publicAddress(InetAddress.getByName("64:ff9b::5db8:d822")),"NAT64 com destino público permitido em redes móveis IPv6");
  WebSafety.url("https://developer.android.com/guide");check(true,"Página pública de programação aceita");
  var page=PublicPage.read(b(sports()),url);check(page.matches.size()==1&&page.matches.get(0).opponents.contains("Adversário")&&page.matches.get(0).competition.equals("Copa de teste"),"Lê evento estruturado da página HTML");
  check(!page.text.contains("SportsEvent")&&page.text.contains("Informação visível"),"Script não vira texto da página");
  var paid=PublicPage.read(b(sports().replace("\"@type\":","\"isAccessibleForFree\":false,\"@type\":")),url);check(paid.restricted&&paid.matches.isEmpty(),"Conteúdo marcado como restrito não é extraído");
  var canceled=PublicPage.read(b(sports().replace("\"startDate\":","\"eventStatus\":\"https://schema.org/EventCancelled\",\"startDate\":")),url);check(canceled.matches.isEmpty(),"Evento cancelado no HTML ignorado");
  String html="<html><head><title>Documento</title></head><body><nav>MENU OCULTO</nav><article>"+"Conteúdo principal verificado. ".repeat(200)+"</article><script>SEGREDO JAVASCRIPT</script></body></html>";
  var article=PublicPage.read(b(html),"https://example.org/article");check(article.text.length()<2500&&article.text.contains("trecho abreviado")&&!article.text.contains("MENU OCULTO")&&!article.text.contains("JAVASCRIPT"),"Extrai texto principal e limita trecho sem executar scripts");
  rejects(()->PublicPage.json("[".repeat(100)+"0"+"]".repeat(100)),"JSON muito profundo recusado antes do parser");
  rejects(()->PublicPage.read(b("<?xml version='1.0'?><rss><channel/></rss>"),url),"Feed não é contado como artigo lido");
  String state="{\"events\":["+event+"]}";String js="window['__espnfitt__']="+state+"; more();";
  check(PublicPage.objectAfter(js,"__espnfitt__").equals(state),"Extrai estado JSON do calendário sem executar JavaScript");
  var espn=PublicPage.read(b("<html><script>"+js+"</script><body>Calendário</body></html>"),url);check(espn.matches.size()>=1,"Lê eventos do estado embutido ESPN");
  var fallback=new OnlineResearch(target->target.contains("site.api.espn.com")?b("{\"events\":[]}"):b(sports()),()->false).run("próximo jogo Flamengo",s->{});
  check(fallback.direct!=null&&fallback.direct.contains("Adversário de teste")&&fallback.direct.contains("20/11/2099"),"Quando a API não tem jogos, a página fornece resposta direta com data");
  var textual=new OnlineResearch(target->target.contains("site.api.espn.com")?b("{\"events\":[]}"):b(html),()->false).run("próximo jogo Flamengo",s->{});check(textual.direct==null&&textual.found&&textual.evidence.contains("Página de calendário efetivamente lida"),"Sem evento estruturado, envia conteúdo lido à IA, não só link");
  String rss=OnlineResearchTest.rss;var general=new OnlineResearch(target->target.contains("www.bing.com")?b(rss):b(html),()->false).run("Como criar app Android",s->{});check(general.evidence.contains("CONTEÚDO DA PÁGINA LIDA")&&general.evidence.contains("Conteúdo principal verificado"),"Consulta geral abre resultado e fornece conteúdo à resposta");
  AtomicInteger attempts=new AtomicInteger();String many=rss.replace("</channel>",rss.substring(rss.indexOf("<item>"),rss.indexOf("</item>")+7).repeat(4)+"</channel>");
  var failedPages=new OnlineResearch(target->{if(target.contains("www.bing.com"))return b(many);attempts.incrementAndGet();throw new java.io.IOException("HTTP 403");},()->false).run("Pesquise documentação Java",s->{});check(attempts.get()==2&&failedPages.evidence.contains("HTTP 403"),"Limita tentativas de páginas indisponíveis e mostra erro sem burlar acesso");
  check(QuickWebAnswer.passage("qual próximo jogo Flamengo", "Introdução genérica. O próximo jogo do Flamengo ocorre em data de teste. Outro assunto.").contains("próximo jogo do Flamengo"),"Resposta rápida seleciona passagem relevante sem gerar fatos");
  check(QuickWebAnswer.suitable("Conversar / assuntos gerais","próximo jogo",false)&&!QuickWebAnswer.suitable("Criar programa","crie app",false)&&!QuickWebAnswer.suitable("Analisar código","analise",true),"Resposta extrativa não substitui geração de programa nem análise de anexo");
  check(general.quick!=null&&general.quick.contains("sem reformulação"),"Consulta geral pode responder sem aguardar modelo local");
  long began=System.nanoTime();var timeoutResult=new OnlineResearch(target->{Thread.sleep(10000);return b(rss);},()->false,150).run("notícias hoje",s->{});long elapsed=java.util.concurrent.TimeUnit.NANOSECONDS.toMillis(System.nanoTime()-began);check(!timeoutResult.found&&elapsed<2500,"Orçamento global encerra coleta mesmo com fonte travada");
  java.util.concurrent.CountDownLatch pair=new java.util.concurrent.CountDownLatch(2);AtomicInteger active=new AtomicInteger(),maximum=new AtomicInteger();String two=rss.replace("</channel>",rss.substring(rss.indexOf("<item>"),rss.indexOf("</item>")+7).replace("/noticia","/segunda")+"</channel>");
  new OnlineResearch(target->{if(target.contains("www.bing.com"))return b(two);int n=active.incrementAndGet();maximum.accumulateAndGet(n,Math::max);pair.countDown();pair.await(1,java.util.concurrent.TimeUnit.SECONDS);active.decrementAndGet();return b(html);},()->false).run("Pesquisa geral",s->{});check(maximum.get()==2,"Duas páginas são coletadas em paralelo");
  System.out.println(passed+" verificações de páginas/calendário passaram com dados simulados.");
 }
}
