package br.com.onda;
import java.util.*;
/** Bounded conversational context. Generated text never becomes an executable app action. */
final class LocalAiPrompt {
 static final class Turn{final String user,answer;Turn(String u,String a){user=u;answer=a;}}
 static String clean(String text){return (text==null?"":text).replace("<|","< |").replace("|>","| >");}
 static String build(String request,List<Turn> history,boolean card){String system=card?"Escreva uma mensagem original em português brasileiro para um cartão sobre o tema pedido. Até 60 palavras. Apenas a mensagem, sem título, sem explicação, sem HTML.":"Você é Onda IA, um assistente local. Responda de forma breve em português brasileiro. Você não acessa internet nem executa ações e não recebe imagens. Se não souber, diga que não sabe. Não invente informações atuais.";StringBuilder p=new StringBuilder("<|im_start|>system\n").append(system).append("<|im_end|>\n");if(!card)for(int i=Math.max(0,history.size()-2);i<history.size();i++){Turn t=history.get(i);p.append("<|im_start|>user\n").append(clean(shorten(t.user,500))).append("<|im_end|>\n<|im_start|>assistant\n").append(clean(shorten(t.answer,600))).append("<|im_end|>\n");}return p.append("<|im_start|>user\n").append(clean(shorten(request,600))).append("<|im_end|>\n<|im_start|>assistant\n").toString();}
 private static String shorten(String text,int max){return text.length()<=max?text:text.substring(0,max);}
}
