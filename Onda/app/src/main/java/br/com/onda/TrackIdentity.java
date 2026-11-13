package br.com.onda;

/** Metadata only: never guesses a composer or claims acoustic recognition. */
final class TrackIdentity {
 final String title,artist,composer,album,source,station;
 TrackIdentity(String title,String artist,String composer,String album,String source,String station){this.title=clean(title);this.artist=clean(artist);this.composer=clean(composer);this.album=clean(album);this.source=source;this.station=clean(station);}
 static String clean(CharSequence value){if(value==null)return "";String s=value.toString().replaceAll("[\\p{Cc}\\p{Cf}]"," ").trim();if(s.equalsIgnoreCase("<unknown>")||s.equalsIgnoreCase("Artista desconhecido")||s.equalsIgnoreCase("Sem título")||s.equalsIgnoreCase("null"))return "";return s.substring(0,Math.min(s.length(),500));}
 static String choose(CharSequence current,CharSequence initial){String value=clean(current);return value.isEmpty()?clean(initial):value;}
 static TrackIdentity radio(String station,CharSequence title,CharSequence artist){String t=clean(title),a=clean(artist),name=clean(station);if(t.equalsIgnoreCase(name))t="";if(a.startsWith("Rádio online"))a="";if(a.isEmpty()&&!t.isEmpty()){int split=t.indexOf(" - ");if(split<0)split=t.indexOf(" – ");if(split<0)split=t.indexOf(" — ");if(split>0&&split+3<t.length()){a=t.substring(0,split).trim();t=t.substring(split+3).trim();}}return new TrackIdentity(t,a,"","","Dados enviados pela emissora",name);}
 String summary(){return title.isEmpty()?"A emissora não informou a música atual.":title+(artist.isEmpty()?"":" • "+artist);}
 String details(){return "Música: "+missing(title)+"\nArtista/intérprete: "+missing(artist)+"\nCompositor: "+missing(composer)+"\nÁlbum: "+missing(album)+(station.isEmpty()?"":"\nEmissora: "+station)+"\n\nOrigem: "+source+".\nAs informações podem estar incompletas ou incorretas na origem. Não é reconhecimento pelo som.";}
 private static String missing(String s){return s.isEmpty()?"Não informado":s;}
}
