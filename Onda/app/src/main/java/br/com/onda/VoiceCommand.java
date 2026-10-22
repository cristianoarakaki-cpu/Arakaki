package br.com.onda;

import java.util.*;
import java.util.regex.*;

/** Deterministic commands; unrecognized phrases remain music searches. */
final class VoiceCommand {
    enum Action { SEARCH, PLAY_QUERY, PLAY, PAUSE, NEXT, PREVIOUS, FAVORITES, SLEEP, INVALID }
    final Action action;final String query;final int minutes;
    private VoiceCommand(Action action,String query,int minutes){this.action=action;this.query=query;this.minutes=minutes;}
    static VoiceCommand of(Action action){return new VoiceCommand(action,"",0);}
    static VoiceCommand parse(String phrase){
        String q=SearchText.normalize(phrase);
        if(q.matches("(?:cancelar|cancele|desativar|desative) (?:o )?temporizador"))return new VoiceCommand(Action.SLEEP,"",0);
        if(q.matches("(?:toque|tocar|reproduza|reproduzir|ouvir)? ?(?:as )?(?:minhas )?favoritas"))return of(Action.FAVORITES);
        if(q.matches("pause|pausa|pausar|pare|parar|pause a musica|pausar a musica|pare a musica|pausar reproducao"))return of(Action.PAUSE);
        if(q.matches("toque|tocar|reproduza|reproduzir|continue|continuar|retomar|retome|continue a musica"))return of(Action.PLAY);
        if(q.matches("proxima|proxima musica|pule|pular|avance|pule a musica"))return of(Action.NEXT);
        if(q.matches("anterior|musica anterior|volte uma musica|voltar uma musica|volte a musica"))return of(Action.PREVIOUS);
        Matcher timer=Pattern.compile("^(?:pare|parar|pause|pausar|desligue|desligar) (?:em|daqui a) (.+)$").matcher(q);
        if(timer.matches()){
            String time=timer.group(1);int minutes=minutes(time);
            return minutes>=1&&minutes<=120?new VoiceCommand(Action.SLEEP,"",minutes):of(Action.INVALID);
        }
        Matcher play=Pattern.compile("(?iu)^(?:toque|tocar|reproduza|reproduzir|ouvir)\\s+(?:a\\s+m[úu]sica\\s+|m[úu]sica\\s+)?(.+)$").matcher(phrase==null?"":phrase.trim());
        if(play.matches())return new VoiceCommand(Action.PLAY_QUERY,play.group(1).trim(),0);
        return new VoiceCommand(Action.SEARCH,SearchText.spokenQuery(phrase),0);
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
