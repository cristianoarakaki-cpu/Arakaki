package br.com.onda;
import java.util.*;
/** Offline greetings: no network, model download or background work. */
final class MessageCards {
 static final class Card {final String title,text;final int style;Card(String title,String text,int style){this.title=title;this.text=text;this.style=style;}}
 static final String[] STYLES={"Céu estrelado","Amanhecer","Jardim","Aurora","Pôr do sol","Elegante"};
 static final List<Card> ALL=Collections.unmodifiableList(Arrays.asList(
  new Card("Boa noite","Que a sua noite seja tranquila, o descanso renove suas forças e o amanhã traga bons motivos para sorrir.",0),
  new Card("Boa noite com carinho","Descanse o coração. Que a paz abrace você e os bons sonhos iluminem a sua noite.",0),
  new Card("Boa noite e fé","Entregue suas preocupações a Deus e descanse. Que sua noite seja de paz e seu amanhã seja abençoado.",3),
  new Card("Bom dia","Que hoje não faltem paz, saúde e pequenos motivos para sorrir. Um lindo dia para você!",1),
  new Card("Bom dia com alegria","Um novo dia, uma nova chance de fazer o bem e cultivar a alegria. Receba meu carinho!",2),
  new Card("Bom dia abençoado","Que Deus ilumine seus passos, fortaleça sua fé e abençoe cada momento deste novo dia.",1),
  new Card("Boa tarde","Uma pausa para desejar uma tarde leve, cheia de paz e boas notícias para você.",4),
  new Card("Feliz aniversário","Que seu novo ciclo floresça com saúde, amor e realizações. Feliz aniversário!",2),
  new Card("Gratidão","Há beleza nas pequenas coisas. Que nunca nos faltem olhos para perceber e um coração para agradecer.",5),
  new Card("Amizade","Amizade é o carinho que atravessa a distância e encontra um jeito de estar perto. Obrigado por fazer parte da minha vida!",3),
  new Card("Amor","Que o amor esteja nos gestos simples, no cuidado de cada dia e na alegria de caminhar juntos.",4),
  new Card("Tenha fé","Um passo de cada vez. Mesmo nos dias difíceis, há esperança, recomeços e caminhos que ainda vão florescer.",3),
  new Card("Feliz domingo","Que seu domingo tenha descanso, bons encontros e tempo para o que faz bem ao coração.",1),
  new Card("Boa semana","Que esta semana traga saúde, coragem e oportunidades. Que cada dia tenha seu motivo de gratidão.",2),
  new Card("Melhoras","Receba meu carinho e meus desejos de recuperação. Que a saúde se fortaleça e logo venham dias mais leves.",2),
  new Card("Saudades","A distância pode separar os caminhos, mas não apaga o carinho. Hoje a saudade veio trazer meu abraço.",5)
 ));
 static List<Card> search(String query){String q=SearchText.normalize(query);ArrayList<Card> out=new ArrayList<>();for(Card c:ALL)if(q.isEmpty()||SearchText.normalize(c.title+" "+c.text).contains(q))out.add(c);return out;}
 static String voiceQuery(String phrase){return phrase==null?"":phrase.trim().replaceFirst("(?iu)^(?:onda[, ]+)?(?:pesquise|pesquisar|busque|buscar|procure|procurar)(?:\\s+(?:por|imagens?(?:\\s+de)?|mensagens?(?:\\s+de)?))*\\s+","").trim();}
}
