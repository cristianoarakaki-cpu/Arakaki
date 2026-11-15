package br.com.arakaki.codigolivre;
import java.util.*;
/** Resposta extrativa: usa texto da fonte, sem aguardar geração pelo modelo. */
final class QuickWebAnswer {
 static String passage(String question,String text){
  Set<String> words=new HashSet<>();for(String w:WebQuery.normalized(question).split("[^a-z0-9]+"))if(w.length()>=4&&!Arrays.asList("como","qual","quais","para","sobre","seria","quando","onde","esse","essa","isso","voce").contains(w))words.add(w);
  int best=-1;String selected="";
  for(String sentence:text.split("(?<=[.!?])\\s+|\\n")){String n=WebQuery.normalized(sentence);int score=0;for(String w:words)if(n.contains(w))score++;if(score>best){best=score;selected=sentence;}}
  if(selected.isEmpty())selected=text;
  return selected.length()>700?selected.substring(0,700)+" [trecho abreviado]":selected;
 }
 static String answer(String question,PublicPage page){
  if(SearchRelevance.score(question,page.title+" "+page.text)<0)return null;
  return "RESPOSTA RÁPIDA DA INTERNET\n\nTrecho relevante da página lida, sem reformulação pela IA:\n\n“"+passage(question,page.text)+"”\n\nFonte: "+page.title+"\n"+page.url+"\n\nConfira o contexto na fonte. Este trecho pode não responder a todos os detalhes da pergunta. Desative ‘Resposta online rápida’ para pedir uma síntese mais detalhada ao modelo local.";
 }
 static boolean suitable(String task,String question,boolean hasAttachment){String q=WebQuery.normalized(question).trim();return !hasAttachment&&!task.equals("Criar programa")&&!task.equals("Corrigir código")&&!q.matches("^(crie|desenvolva|gere|programe)\\b.*");}
}
