package br.com.onda;

import java.util.*;
import java.util.regex.*;

/** Deterministic commands; unrecognized phrases remain music searches. */
final class VoiceCommand {
    enum Action { SEARCH, PLAY_QUERY, PLAY_PLAYLIST, ADD_PLAYLIST, PLAY, PAUSE, NEXT, PREVIOUS, FAVORITES, FAVORITE_ADD, FAVORITE_REMOVE, SHUFFLE_ON, SHUFFLE_OFF, REPEAT_ONE, REPEAT_ALL, REPEAT_OFF, HELP, SLEEP, DJ_PERSONAL, DJ_TRAVEL, DJ_DOWNLOADS, DJ_VARIETY, DJ_ARTIST, DJ_UNIQUE, DJ_FAVORITES_UNIQUE, DJ_EXPLAIN, DJ_AVOID, SLEEP_TRACKS, INVALID }
    final Action action;final String query;final int minutes;
    private VoiceCommand(Action action,String query,int minutes){this.action=action;this.query=query;this.minutes=minutes;}
    static VoiceCommand of(Action action){return new VoiceCommand(action,"",0);}
    static String cleanPhrase(String phrase){
        String clean=phrase==null?"":phrase.trim();
        clean=clean.replaceFirst("(?iu)^onda[ ,:!]+", "").replaceFirst("(?iu)^por favor[, ]+", "").replaceFirst("(?iu)[, ]+por favor[.!?]*$", "").trim();
        return clean;
    }
    static VoiceCommand custom(Action action,String query,int minutes){
        if(action==null||action==Action.INVALID)throw new IllegalArgumentException("Escolha uma ação válida.");
        boolean search=action==Action.SEARCH||action==Action.PLAY_QUERY||action==Action.PLAY_PLAYLIST||action==Action.ADD_PLAYLIST;
        if(search&&(query.isEmpty()||query.length()>160))throw new IllegalArgumentException("Informe uma música ou artista de até 160 caracteres.");
        if(!search&&!query.isEmpty())throw new IllegalArgumentException("Essa ação não usa busca.");
        if(action==Action.SLEEP_TRACKS?(minutes<1||minutes>20):(minutes<0||minutes>120||(action!=Action.SLEEP&&minutes!=0)))throw new IllegalArgumentException("Use de 0 a 120 minutos; 0 cancela o temporizador.");
        return new VoiceCommand(action,query,minutes);
    }
    static VoiceCommand parse(String phrase){
        String clean=cleanPhrase(phrase);
        String q=SearchText.normalize(clean);
        // Explicit searches must not execute commands, even for titles such as Favoritas.
        if(q.matches("(?:busque|buscar|pesquise|pesquisar|procure|procurar) .+"))return new VoiceCommand(Action.SEARCH,SearchText.spokenQuery(clean),0);
        if(q.matches("(?:inicie|iniciar|ative|ativar|abra|abrir) (?:o )?(?:onda )?dj(?: pessoal)?|(?:monte|montar|crie|criar) (?:uma |minha )?sessao(?: personalizada)?"))return of(Action.DJ_PERSONAL);
        if(q.matches("(?:monte|montar|crie|criar|prepare|preparar) (?:a )?minha viagem|modo viagem"))return of(Action.DJ_TRAVEL);
        if(q.matches("(?:misture|misturar) (?:os )?meus downloads com (?:as )?musicas antigas|downloads e redescobertas"))return of(Action.DJ_DOWNLOADS);
        if(q.matches("(?:quero |coloque |traga )?mais variedade(?: nas proximas)?"))return of(Action.DJ_VARIETY);
        if(q.matches("(?:quero |toque |coloque )?mais (?:desse|deste|do mesmo) artista(?: nas proximas)?"))return of(Action.DJ_ARTIST);
        if(q.matches("(?:toque |tocar |reproduza |ouvir )?(?:as )?(?:minhas )?(?:musicas )?favoritas sem repetir (?:o )?artista"))return of(Action.DJ_FAVORITES_UNIQUE);
        if(q.matches("(?:nao repetir|nao repita|sem repetir|evite repetir|evitar repetir) (?:o )?artista(?: nas proximas)?"))return of(Action.DJ_UNIQUE);
        if(q.matches("(?:evite|evitar) (?:esta|essa) musica|nao (?:recomende|recomendar) (?:esta|essa) musica"))return of(Action.DJ_AVOID);
        if(q.matches("por que (?:esta|essa) musica|(?:explique|explicar) (?:esta|essa) (?:escolha|musica)"))return of(Action.DJ_EXPLAIN);
        if(q.matches("(?:pare|pause|parar|pausar) (?:(?:ao terminar|apos) (?:esta|essa|a) musica|no fim (?:da|desta|dessa) musica|depois (?:da|desta|dessa) musica)"))return new VoiceCommand(Action.SLEEP_TRACKS,"",1);
        Matcher tracks=Pattern.compile("^(?:pare|pause|parar|pausar) (?:apos|depois de) (\\d+|uma|duas|tres|cinco|dez) musicas?$").matcher(q);
        if(tracks.matches()){String n=tracks.group(1);Map<String,Integer> words=Map.of("uma",1,"duas",2,"tres",3,"cinco",5,"dez",10);int count;try{count=Integer.parseInt(n);}catch(NumberFormatException e){count=words.getOrDefault(n,0);}return count>=1&&count<=20?new VoiceCommand(Action.SLEEP_TRACKS,"",count):of(Action.INVALID);}
        Matcher add=Pattern.compile("(?iu)^(?:adicione|adicionar|inclua|incluir|salve|salvar|coloque|colocar)\\s+(?:(?:esta|essa|a)\\s+)?(?:m[úu]sica|faixa)\\s+(?:na|em|[àa])\\s+(?:(?:minha|a\\s+minha)\\s+)?(?:playlist|lista)\\s+(.+)$").matcher(clean);
        if(add.matches())return new VoiceCommand(Action.ADD_PLAYLIST,add.group(1).trim(),0);
        Matcher playlist=Pattern.compile("(?iu)^(?:toque|toca|tocar|reproduza|reproduzir|ouvir|coloque|colocar)\\s+(?:(?:a|minha|a\\s+minha)\\s+)?(?:playlist|lista)\\s+(.+)$").matcher(clean);
        if(playlist.matches())return new VoiceCommand(Action.PLAY_PLAYLIST,playlist.group(1).trim(),0);
        if(q.matches("ajuda|comandos|comandos de voz|o que posso falar"))return of(Action.HELP);
        if(q.matches("(?:favorite|favoritar)|(?:adicione|adicionar|salve|salvar) (?:esta |essa |a )?(?:musica )?(?:aos |nas |nos )?(?:favoritos|favoritas)"))return of(Action.FAVORITE_ADD);
        if(q.matches("(?:remova|remover|tire|tirar) (?:esta |essa |a )?(?:musica )?(?:dos favoritos|das favoritas)"))return of(Action.FAVORITE_REMOVE);
        if(q.matches("(?:ative|ativar|ligue|ligar) (?:o )?(?:modo )?aleatorio|embaralhe|embaralhar"))return of(Action.SHUFFLE_ON);
        if(q.matches("(?:desative|desativar|desligue|desligar) (?:o )?(?:modo )?aleatorio"))return of(Action.SHUFFLE_OFF);
        if(q.matches("(?:repita|repetir) (?:esta |essa |a )?musica"))return of(Action.REPEAT_ONE);
        if(q.matches("(?:repita|repetir) (?:todas|tudo|a fila)"))return of(Action.REPEAT_ALL);
        if(q.matches("(?:desative|desativar|desligue|desligar) (?:a )?repeticao|nao repetir"))return of(Action.REPEAT_OFF);
        if(q.matches("(?:cancelar|cancele|desativar|desative) (?:o )?temporizador"))return new VoiceCommand(Action.SLEEP,"",0);
        if(q.matches("(?:(?:toque|tocar|reproduza|reproduzir|ouvir|coloque|colocar) )?(?:as )?(?:minhas )?(?:musicas )?favoritas"))return of(Action.FAVORITES);
        if(q.matches("pause|pausa|pausar|pare|parar|pause a musica|pausar a musica|pare a musica|pausar reproducao"))return of(Action.PAUSE);
        if(q.matches("toque|tocar|reproduza|reproduzir|continue|continuar|retomar|retome|continue a musica|retome a musica|volte a tocar"))return of(Action.PLAY);
        if(q.matches("proxima|proxima musica|toque a proxima|passe para a proxima|pule|pular|avance|pule a musica"))return of(Action.NEXT);
        if(q.matches("anterior|musica anterior|toque a anterior|volte uma musica|voltar uma musica|volte a musica"))return of(Action.PREVIOUS);
        Matcher timer=Pattern.compile("^(?:pare|parar|pause|pausar|desligue|desligar) (?:em|daqui a) (.+)$").matcher(q);
        if(timer.matches()){
            String time=timer.group(1);int minutes=minutes(time);
            return minutes>=1&&minutes<=120?new VoiceCommand(Action.SLEEP,"",minutes):of(Action.INVALID);
        }
        Matcher play=Pattern.compile("(?iu)^(?:toque|tocar|reproduza|reproduzir|ouvir|coloque|colocar)\\s+(?:a\\s+m[úu]sica\\s+|m[úu]sica\\s+)?(.+)$").matcher(clean);
        if(play.matches())return new VoiceCommand(Action.PLAY_QUERY,play.group(1).trim(),0);
        return new VoiceCommand(Action.SEARCH,SearchText.spokenQuery(clean),0);
    }
    private static int minutes(String text){
        if(text.equals("meia hora"))return 30;
        Matcher m=Pattern.compile("^(.+?) (minutos?|horas?)$").matcher(text);if(!m.matches())return -1;
        String number=m.group(1);int value;
        try{value=Integer.parseInt(number);}catch(NumberFormatException e){
            Map<String,Integer> words=new HashMap<>();words.put("um",1);words.put("uma",1);words.put("dois",2);words.put("duas",2);words.put("cinco",5);words.put("dez",10);words.put("quinze",15);words.put("vinte",20);words.put("trinta",30);words.put("quarenta e cinco",45);words.put("sessenta",60);words.put("noventa",90);words.put("cento e vinte",120);value=words.getOrDefault(number,-1);
        }
        if(value<0||value>120)return -1;
        return m.group(2).startsWith("hora")?value*60:value;
    }
}
