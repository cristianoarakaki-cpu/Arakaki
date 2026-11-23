package br.com.onda;
import android.util.JsonReader;import android.util.JsonToken;import java.io.*;import java.nio.charset.*;import org.json.*;
/** Bounded streaming JSON input: whitespace/unknown fields never require a copy of the whole file. */
final class BackupStream {
 static BackupData.Archive read(InputStream input)throws Exception{
  try(JsonReader reader=new JsonReader(new InputStreamReader(new LimitedInput(input),StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)))){
   JSONObject root=new JSONObject();reader.beginObject();while(reader.hasNext()){String name=reader.nextName();switch(name){
    case "format":root.put(name,text(reader,64));break;case "version":root.put(name,reader.nextInt());break;
    case "tracks":root.put(name,objects(reader,"track",BackupData.MAX_TRACKS));break;
    case "playlists":root.put(name,objects(reader,"playlist",100));break;
    case "favorites":root.put(name,strings(reader,BackupData.MAX_TRACKS,40));break;
    case "phrases":root.put(name,objects(reader,"phrase",100));break;
    default:reader.skipValue();
   }}reader.endObject();if(reader.peek()!=JsonToken.END_DOCUMENT)throw new IOException("Há conteúdo extra após o backup.");return BackupData.parse(root);
  }
 }
 private static JSONArray strings(JsonReader reader,int count,int length)throws Exception{JSONArray values=new JSONArray();reader.beginArray();while(reader.hasNext()){if(values.length()>=count)throw new IOException("O backup excede o limite de registros.");values.put(text(reader,length));}reader.endArray();return values;}
 private static JSONArray objects(JsonReader reader,String type,int maximum)throws Exception{JSONArray values=new JSONArray();reader.beginArray();while(reader.hasNext()){if(values.length()>=maximum)throw new IOException("O backup excede o limite de registros.");JSONObject value=new JSONObject();reader.beginObject();while(reader.hasNext()){String key=reader.nextName();if(type.equals("track")){switch(key){case "key":value.put(key,text(reader,40));break;case "title":case "artist":case "album":value.put(key,text(reader,512));break;case "duration":value.put(key,reader.nextLong());break;default:reader.skipValue();}}
   else if(type.equals("playlist")){switch(key){case "name":value.put(key,text(reader,60));break;case "songs":value.put(key,strings(reader,2000,40));break;default:reader.skipValue();}}
   else{switch(key){case "id":value.put(key,text(reader,80));break;case "phrase":value.put(key,text(reader,120));break;case "query":value.put(key,text(reader,160));break;case "action":value.put(key,text(reader,64));break;case "minutes":value.put(key,reader.nextInt());break;default:reader.skipValue();}}
  }reader.endObject();values.put(value);}reader.endArray();return values;}
 private static String text(JsonReader reader,int max)throws IOException{if(reader.peek()!=JsonToken.STRING)throw new IOException("Campo de texto inválido no backup.");String value=reader.nextString();if(value.length()>max)throw new IOException("Um campo de texto do backup excede o limite.");return value;}
 private static final class LimitedInput extends FilterInputStream{
  long count;LimitedInput(InputStream input){super(input);}private void checked(int n)throws IOException{if(Thread.currentThread().isInterrupted())throw new InterruptedIOException("Leitura cancelada.");if(n>0){count+=n;if(count>BackupData.MAX_BYTES)throw new IOException("O backup excede 64 MB de metadados.");}}
  @Override public int read()throws IOException{int n=in.read();checked(n<0?0:1);return n;}
  @Override public int read(byte[] buffer,int offset,int length)throws IOException{int n=in.read(buffer,offset,length);checked(n);return n;}
 }
}
