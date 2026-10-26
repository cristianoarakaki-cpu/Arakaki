package br.com.onda;
/** Only explicit workspace requests are intercepted; ordinary music commands keep their meaning. */
final class WorkspaceVoice {
 final String action,type,query;
 WorkspaceVoice(String action,String type,String query){this.action=action;this.type=type;this.query=query;}
 static WorkspaceVoice parse(String phrase){
  String s=SearchText.normalize(phrase).replaceFirst("^onda +","").replaceFirst(" +por favor$","");
  // Search is intentionally checked before commands embedded in a title.
  if(s.matches("^(busque|busca|pesquise|procure) no onda .+"))return new WorkspaceVoice("search","",s.replaceFirst("^(busque|busca|pesquise|procure) no onda +",""));
  if(s.matches("^(abra|abrir) (a |minha |a minha )?colecao .+"))return new WorkspaceVoice("collection","",s.replaceFirst("^(abra|abrir) (a |minha |a minha )?colecao +",""));
  if(s.matches("^(continue|retome|continuar|retomar) (o |a )?ultim[oa] (video|musica|audio|pdf|documento|conteudo)$")){
   String word=s.substring(s.lastIndexOf(' ')+1);return new WorkspaceVoice("resume",word.equals("video")?"video":word.equals("pdf")||word.equals("documento")?"pdf":word.equals("conteudo")?"":"audio","");
  }
  if(s.matches("^(abra|abrir) (o |a )?(pdf|video|audio|musica) .+")){
   String rest=s.replaceFirst("^(abra|abrir) (o |a )?","");int space=rest.indexOf(' ');String kind=rest.substring(0,space);return new WorkspaceVoice("search",kind.equals("musica")?"audio":kind,rest.substring(space+1));
  }
  return null;
 }
}
