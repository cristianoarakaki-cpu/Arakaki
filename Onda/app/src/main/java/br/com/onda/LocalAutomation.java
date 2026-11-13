package br.com.onda;
import java.util.*;
import java.util.regex.*;

/** Small, bounded local intent planner. No network, timers, model download or implicit fallback. */
final class LocalAutomation {
 static final int MAX_STEPS=6,MAX_INPUT=600;
 enum Destination { PLAYER, SCREEN, YOUTUBE, IMAGES }
 static final class Plan {
  final Destination destination;final List<VoiceCommand> commands;final String query,error;
  Plan(Destination destination,List<VoiceCommand> commands,String query,String error){this.destination=destination;this.commands=Collections.unmodifiableList(new ArrayList<>(commands));this.query=query;this.error=error;}
  boolean valid(){return error.isEmpty();}
  String summary(){if(!valid())return error;if(destination==Destination.YOUTUBE)return "Pesquisar no YouTube: "+query;if(destination==Destination.IMAGES)return "Pesquisar imagens na internet: "+query;StringBuilder out=new StringBuilder();for(int i=0;i<commands.size();i++){if(i>0)out.append('\n');out.append(i+1).append(". ").append(label(commands.get(i)));}return out.toString();}
 }
 private static Plan error(String text){return new Plan(Destination.PLAYER,Collections.emptyList(),"",text);}
 static Plan parse(String raw){String phrase=VoiceCommand.cleanPhrase(raw);if(phrase.isEmpty()||phrase.length()>MAX_INPUT)return error("Digite um pedido de até 600 caracteres.");
  Matcher youtube=Pattern.compile("(?iu)^(?:pesquise|pesquisar|busque|buscar|procure|procurar)\\s+(.+?)\\s+no\\s+(?:youtube|you tube)$").matcher(phrase);
  if(youtube.matches())return search(Destination.YOUTUBE,youtube.group(1),160);
  Matcher images=Pattern.compile("(?iu)^(?:(?:busque|buscar|pesquise|pesquisar|procure|procurar)\\s+)?(?:imagens|fotos|mensagens)\\s+(?:de|sobre|para)\\s+(.+)$").matcher(phrase);
  if(images.matches())return search(Destination.IMAGES,images.group(1),120);
  String[] parts=phrase.split("(?iu)\\s+(?:e depois|depois|em seguida|e ent[aã]o)\\s+|\\s*;\\s*|\\s+e\\s+(?=(?:ative|desative|pause|pare|repita|cancele|embaralhe)\\b)",-1);
  if(parts.length>MAX_STEPS)return error("Use no máximo seis ações por rotina.");List<VoiceCommand> commands=new ArrayList<>();
  for(String part:parts){if(part.trim().isEmpty())return error("Há uma etapa vazia. Confira o pedido antes de executar.");
   boolean shuffle=SearchText.normalize(part).matches(".* (?:em ordem aleatoria|no modo aleatorio|embaralhadas)$");if(shuffle)part=part.replaceFirst("(?iu)\\s+(?:em ordem aleat[oó]ria|no modo aleat[oó]rio|embaralhadas)$","");
   VoiceCommand command=LocalVoiceModel.interpret(part.trim());
   if(command.action.name().startsWith("OPEN_")){if(parts.length!=1||shuffle)return error("Abra uma tela por pedido. Para reprodução, combine os controles do tocador.");return new Plan(Destination.SCREEN,Collections.singletonList(command),"","");}
   if(!allowed(command.action))return error("Não entendi uma das etapas. Use reprodução, favoritas, aleatório, repetição, temporizador ou abrir uma tela.");
   if((command.action==VoiceCommand.Action.FAVORITES||command.action==VoiceCommand.Action.PLAY_QUERY)&&!commands.isEmpty())return error("A escolha das músicas deve ser a primeira etapa.");
   commands.add(command);if(shuffle)commands.add(VoiceCommand.of(VoiceCommand.Action.SHUFFLE_ON));
  }
  if(commands.size()>MAX_STEPS)return error("Use no máximo seis ações por rotina.");return new Plan(Destination.PLAYER,commands,"","");
 }
 private static Plan search(Destination destination,String text,int limit){String value=text.trim();if(value.isEmpty()||value.length()>limit||value.contains(";")||value.contains("\n"))return error("Informe uma busca única de até "+limit+" caracteres.");return new Plan(destination,Collections.emptyList(),value,"");}
 private static boolean allowed(VoiceCommand.Action a){switch(a){case PLAY:case PAUSE:case NEXT:case PREVIOUS:case FAVORITES:case PLAY_QUERY:case SHUFFLE_ON:case SHUFFLE_OFF:case REPEAT_ONE:case REPEAT_ALL:case REPEAT_OFF:case SLEEP:case SLEEP_TRACKS:return true;default:return false;}}
 static String label(VoiceCommand c){switch(c.action){case PLAY:return "Continuar reprodução";case PAUSE:return "Pausar reprodução";case NEXT:return "Próxima música";case PREVIOUS:return "Música anterior";case FAVORITES:return "Tocar favoritas do celular";case PLAY_QUERY:return "Tocar no celular: "+c.query;case SHUFFLE_ON:return "Ativar aleatório";case SHUFFLE_OFF:return "Desativar aleatório";case REPEAT_ONE:return "Repetir a faixa atual";case REPEAT_ALL:return "Repetir a fila";case REPEAT_OFF:return "Desativar repetição";case SLEEP:return c.minutes==0?"Cancelar temporizador":"Pausar em "+c.minutes+" minutos";case SLEEP_TRACKS:return "Pausar após "+c.minutes+" música(s)";default:return "Abrir: "+c.action.name().replace("OPEN_","").toLowerCase(Locale.ROOT).replace('_',' ');}}
}
