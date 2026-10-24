package br.com.onda;
import java.util.*;
public final class PersonalDjTest {
 static void check(boolean value,String message){if(!value)throw new AssertionError(message);}
 static DjPlanner.Song song(String id,String artist,boolean favorite,int completed){return new DjPlanner.Song(id,"Faixa "+id,artist,60000,0,0,favorite,completed);}
 public static void main(String[] args){
  List<DjPlanner.Song> library=new ArrayList<>();for(int i=0;i<20;i++)library.add(song(""+i,"Artista "+i%4,i%2==0,0));
  List<DjPlanner.Song> strict=DjPlanner.build(library,DjPlanner.Mode.PERSONAL,30,7,100000,Collections.singleton("0"),true,false,"");
  Set<String> artists=new HashSet<>();for(DjPlanner.Song s:strict){check(!s.id.equals("0"),"played file repeated");check(artists.add(s.artistKey()),"artist repeated");}check(strict.size()==4,"strict session should stop at available artists");
  List<DjPlanner.Song> favorites=DjPlanner.build(library,DjPlanner.Mode.FAVORITES,30,7,100000,Collections.emptySet(),true,false,"");for(DjPlanner.Song s:favorites)check(s.favorite,"nonfavorite selected");check(favorites.size()==2,"favorite artists duplicated");
  DjPlanner.Song download=new DjPlanner.Song("download:-15","Download","Download local",0,0,0,false);check(DjPlanner.build(Arrays.asList(download),DjPlanner.Mode.DOWNLOADS,30,1,1).size()==1,"unindexed download excluded");check(download.artistKey().isEmpty(),"download source treated as artist");
  DjPlanner.Song completed=song("100","A",false,3),fresh=song("101","B",false,0);check(DjPlanner.weight(completed,DjPlanner.Mode.PERSONAL,1)>DjPlanner.weight(fresh,DjPlanner.Mode.PERSONAL,1),"completion history ignored");check(DjPlanner.explain(completed,DjPlanner.Mode.PERSONAL,1).contains("3"),"completion explanation missing");
  Random random=new Random(17);int preferred=0;for(int i=0;i<1000;i++){List<DjPlanner.Song> result=DjPlanner.build(Arrays.asList(fresh,song("102","A",false,0)),DjPlanner.Mode.PERSONAL,1,random.nextLong(),1,Collections.emptySet(),false,false,"a");if(result.get(0).artist.equals("A"))preferred++;}check(preferred>800,"requested artist not prioritized");
  check(VoiceCommand.parse("evite esta música").action==VoiceCommand.Action.DJ_AVOID,"avoid voice command missing");
  String[] commands={"inicie o DJ Pessoal","monte minha viagem","mais variedade","mais desse artista","não repita artista","toque minhas favoritas sem repetir artista","misture meus downloads com músicas antigas","por que esta música?"};
  VoiceCommand.Action[] actions={VoiceCommand.Action.DJ_PERSONAL,VoiceCommand.Action.DJ_TRAVEL,VoiceCommand.Action.DJ_VARIETY,VoiceCommand.Action.DJ_ARTIST,VoiceCommand.Action.DJ_UNIQUE,VoiceCommand.Action.DJ_FAVORITES_UNIQUE,VoiceCommand.Action.DJ_DOWNLOADS,VoiceCommand.Action.DJ_EXPLAIN};
  for(int i=0;i<commands.length;i++)check(VoiceCommand.parse(commands[i]).action==actions[i],"voice request misinterpreted: "+commands[i]);check(VoiceCommand.parse("pesquise mais variedade").action==VoiceCommand.Action.SEARCH,"explicit search executed command");
  check(!ListeningMilestones.reachedEnd(1000,180000),"seek credited as full listen");check(ListeningMilestones.reachedEnd(170000,180000),"natural long listen not credited");check(!ListeningMilestones.reachedEnd(5000,0),"unknown duration credited");
  System.out.println("Personal DJ: strict artists, played exclusions, favorites, unindexed downloads, history, artist priority, 8 voice commands, explicit searches and natural-end milestones passed.");
 }
}
