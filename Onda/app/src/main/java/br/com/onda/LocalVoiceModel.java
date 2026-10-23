package br.com.onda;

import java.util.*;

/** Small TF-IDF nearest-example intent classifier, fitted once from Portuguese examples. */
final class LocalVoiceModel {
    private static final class Example {
        final VoiceCommand.Action action;final Map<String,Double> vector;
        Example(VoiceCommand.Action action,Map<String,Double> vector){this.action=action;this.vector=vector;}
    }
    private static final Set<String> STOP=new HashSet<>(Arrays.asList("a","o","as","os","de","da","do","das","dos","e","em","no","na","nos","nas","para","por","com","que","eu","me","um","uma","quero","pode","poderia","voce","favor","onda","essa","esta","esse","este","aquela","aquelas","aquele","aqueles"));
    private final List<Example> examples=new ArrayList<>();
    private final Map<String,Double> idf=new HashMap<>();
    private static final LocalVoiceModel INSTANCE=new LocalVoiceModel();
    private LocalVoiceModel(){
        Map<VoiceCommand.Action,String[]> training=new EnumMap<>(VoiceCommand.Action.class);
        training.put(VoiceCommand.Action.FAVORITES,new String[]{"coloca as musicas que eu mais gosto","toca as minhas preferidas","quero ouvir minhas favoritas","bota minhas musicas prediletas","reproduzir as que eu mais curto","escutar minha colecao de favoritas","ouvir minhas faixas preferidas","tocar as cancoes que salvei nos favoritos"});
        training.put(VoiceCommand.Action.PAUSE,new String[]{"para de tocar a musica","faz uma pausa na musica","interrompa a reproducao agora","pausa o som agora","quero parar de ouvir","silencie a musica agora"});
        training.put(VoiceCommand.Action.PLAY,new String[]{"volta a tocar a musica","continua de onde parou","retoma a reproducao da musica","quero continuar ouvindo","volte a reproduzir o som","pode continuar tocando"});
        training.put(VoiceCommand.Action.NEXT,new String[]{"passa para a proxima faixa","troca para a proxima musica","pula essa musica agora","nao gostei passa para outra","quero ouvir a proxima faixa","avanca uma musica"});
        training.put(VoiceCommand.Action.PREVIOUS,new String[]{"volta para a faixa anterior","volta para a musica de antes","toca a musica anterior","quero ouvir a faixa de antes","volte para a musica de antes","retorne uma faixa","voltar para a anterior"});
        training.put(VoiceCommand.Action.FAVORITE_ADD,new String[]{"guarda essa musica nos favoritos","salva essa faixa nas favoritas","adiciona essa cancao aos favoritos","quero favoritar essa musica","marca essa musica como favorita","coloca essa faixa nos meus favoritos"});
        training.put(VoiceCommand.Action.FAVORITE_REMOVE,new String[]{"tira essa musica das favoritas","tira essa faixa dos meus favoritos","apaga essa faixa dos favoritos","remove essa cancao dos meus favoritos","nao quero essa musica nas favoritas","deixa de favoritar essa musica","desmarca essa musica dos favoritos"});
        training.put(VoiceCommand.Action.SHUFFLE_ON,new String[]{"mistura a ordem das musicas","toca as faixas em ordem aleatoria","liga o modo aleatorio","embaralha minha fila de musicas","quero ouvir em ordem aleatoria","coloca no modo aleatorio"});
        training.put(VoiceCommand.Action.SHUFFLE_OFF,new String[]{"desliga o modo aleatorio","desativa a ordem aleatoria","pare de embaralhar as musicas","tira do modo aleatorio","nao quero ordem aleatoria","volta para a ordem normal"});
        training.put(VoiceCommand.Action.REPEAT_ONE,new String[]{"fica repetindo essa musica","toca essa faixa em loop","repete so essa musica","quero ouvir a mesma musica de novo","coloca essa musica para repetir","repetir apenas a faixa atual"});
        training.put(VoiceCommand.Action.REPEAT_ALL,new String[]{"repete a lista inteira","fica repetindo todas as musicas","toca a fila toda de novo","coloca todas as faixas em loop","repetir a fila completa","repete todas as faixas"});
        training.put(VoiceCommand.Action.REPEAT_OFF,new String[]{"desliga a repeticao das musicas","pare de repetir as faixas","nao quero que repita a musica","tira a musica do loop","desativa o modo de repeticao","nao repetir a fila"});
        int count=0;Map<String,Integer> frequency=new HashMap<>();
        for(String[] phrases:training.values())for(String phrase:phrases){count++;for(String word:tokens(phrase).keySet())frequency.merge(word,1,Integer::sum);}
        for(Map.Entry<String,Integer> entry:frequency.entrySet())idf.put(entry.getKey(),1+Math.log((count+1.0)/(entry.getValue()+1.0)));
        for(Map.Entry<VoiceCommand.Action,String[]> entry:training.entrySet())for(String phrase:entry.getValue())examples.add(new Example(entry.getKey(),vector(phrase)));
    }
    private static Map<String,Double> tokens(String phrase){
        Map<String,Double> result=new HashMap<>();for(String word:SearchText.normalize(phrase).split(" "))if(!word.isEmpty()&&!STOP.contains(word))result.merge(word,1.0,Double::sum);return result;
    }
    private Map<String,Double> vector(String phrase){
        Map<String,Double> values=tokens(phrase);double norm=0;
        for(Map.Entry<String,Double> e:values.entrySet()){double v=(1+Math.log(e.getValue()))*idf.getOrDefault(e.getKey(),6.0);e.setValue(v);norm+=v*v;}
        double length=Math.sqrt(norm);if(length>0)for(Map.Entry<String,Double> e:values.entrySet())e.setValue(e.getValue()/length);return values;
    }
    static VoiceCommand interpret(String phrase){
        VoiceCommand direct=VoiceCommand.parse(phrase);
        if(direct.action!=VoiceCommand.Action.SEARCH||!SearchText.spokenQuery(phrase).equals(phrase==null?"":phrase.trim()))return direct;
        if(SearchText.normalize(phrase).matches("(?:(?:onda|por favor) )*(?:busque|buscar|pesquise|pesquisar|procure|procurar) .*"))return direct;
        // Negation in a free phrase is ambiguous; never guess the opposite action.
        if(SearchText.normalize(phrase).matches(".*\\b(?:nao|nunca|nem)\\b.*"))return direct;
        Map<String,Double> query=INSTANCE.vector(phrase);if(query.size()<2)return direct;
        Map<VoiceCommand.Action,Double> scores=new EnumMap<>(VoiceCommand.Action.class);
        for(Example example:INSTANCE.examples){double score=0;for(Map.Entry<String,Double> e:query.entrySet())score+=e.getValue()*example.vector.getOrDefault(e.getKey(),0.0);scores.merge(example.action,score,Math::max);}
        VoiceCommand.Action best=VoiceCommand.Action.SEARCH;double first=0,second=0;
        for(Map.Entry<VoiceCommand.Action,Double> entry:scores.entrySet())if(entry.getValue()>first){second=first;first=entry.getValue();best=entry.getKey();}else second=Math.max(second,entry.getValue());
        return first>=.62&&first-second>=.10?VoiceCommand.of(best):direct;
    }
}
