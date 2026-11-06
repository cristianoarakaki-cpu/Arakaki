package br.com.onda;
import java.util.*;
import java.util.regex.*;
import org.json.*;
/** Exact public photo post. Photo and soundtrack are separate files, never a fabricated video. */
final class TiktokPhotos {
 static JSONObject item(String html,String id)throws Exception{
  if(html==null||html.length()>8*1024*1024||id==null||!id.matches("[0-9]{10,24}"))throw new Exception("Publicação de fotos inválida.");
  for(String name:new String[]{"__UNIVERSAL_DATA_FOR_REHYDRATION__","SIGI_STATE","sigi-persisted-data"}){
   Matcher script=Pattern.compile("<script\\b[^>]*\\bid\\s*=\\s*['\"]"+name+"['\"][^>]*>(.*?)</script\\s*>",Pattern.CASE_INSENSITIVE|Pattern.DOTALL).matcher(html);
   while(script.find()){
    JSONObject root;try{root=new JSONObject(script.group(1));}catch(JSONException invalid){continue;}JSONObject item=null;
    if(name.equals("__UNIVERSAL_DATA_FOR_REHYDRATION__")){JSONObject scope=root.optJSONObject("__DEFAULT_SCOPE__");if(scope!=null)for(String key:new String[]{"webapp.video-detail","webapp.reflow.video.detail"}){JSONObject detail=scope.optJSONObject(key);if(detail==null)continue;if(detail.optInt("statusCode",0)!=0)throw new Exception("O TikTok não disponibilizou esta publicação nesta consulta.");JSONObject info=detail.optJSONObject("itemInfo");item=info==null?null:info.optJSONObject("itemStruct");if(item!=null)break;}}
    else{JSONObject items=root.optJSONObject("ItemModule");item=items==null?null:items.optJSONObject(id);}
    if(item==null)continue;
    if(!id.equals(item.optString("id")))throw new Exception("A página retornou outra publicação.");
    if(item.optBoolean("privateItem")||item.optBoolean("isContentClassified"))throw new Exception("Esta publicação é privada ou restrita.");
    if(item.optJSONObject("imagePost")==null)throw new Exception("A publicação não contém fotos disponíveis.");return item;
   }
  }
  throw new Exception("O link é de uma publicação de fotos, mas o TikTok não disponibilizou as imagens nesta consulta. Pode exigir verificação.");
 }
 static YoutubeDownloads.Result inspect(PublicMediaHttp.Page page,PublicMediaSession session,MediaDownloads.PrefixReader reader)throws Exception{
  JSONObject post=item(page.text(),MediaLinks.photoId(page.url));String title=post.optString("desc","").trim();if(title.isEmpty())title="TikTok fotos "+post.optString("id");title=title.substring(0,Math.min(160,title.length()));
  JSONArray images=post.getJSONObject("imagePost").optJSONArray("images");List<YoutubeDownloads.Option> options=new ArrayList<>();String referer=MediaLinks.tiktok(page.url);long deadline=System.currentTimeMillis()+45000;
  if(images!=null)for(int index=0;index<images.length();index++){
   if(Thread.currentThread().isInterrupted())throw new java.io.InterruptedIOException("Consulta cancelada");
   if(System.currentTimeMillis()>deadline)throw new java.io.IOException("Tempo limite ao consultar as fotos. Tente novamente.");
   JSONObject image=images.optJSONObject(index);if(image==null)continue;LinkedHashSet<String> candidates=new LinkedHashSet<>();TiktokPage.collect(image.opt("imageURL"),candidates);
   for(String url:candidates)try{PublicMediaHttp.Page file=reader.read(url,referer);String format=imageExtension(file.bytes);if(format.isEmpty())continue;options.add(new YoutubeDownloads.Option("Foto "+(index+1)+" de "+images.length()+" • "+format.toUpperCase(Locale.ROOT)+" original",file.url,null,format,imageMime(format),true,referer,false,session.snapshot()));break;}catch(java.io.InterruptedIOException error){if(Thread.currentThread().isInterrupted())throw error;}catch(Exception unavailable){}
  }
  JSONObject music=post.optJSONObject("music");String audio=music==null?"":TiktokPage.address(music.opt("playUrl"));
  if(!audio.isEmpty())try{PublicMediaHttp.Page file=reader.read(audio,referer);String ext=PublicMediaHttp.mediaHeader(file.bytes,"mp3")?"mp3":PublicMediaHttp.mediaHeader(file.bytes,"aac")?"aac":PublicMediaHttp.mediaHeader(file.bytes,"m4a")?"m4a":"";if(!ext.isEmpty())options.add(new YoutubeDownloads.Option("Áudio da publicação • "+ext.toUpperCase(Locale.ROOT)+" original",file.url,null,ext,MediaDownloads.mime(ext),true,referer,false,session.snapshot()));}catch(java.io.InterruptedIOException error){if(Thread.currentThread().isInterrupted())throw error;}catch(Exception unavailable){}
  if(options.isEmpty())throw new Exception("Esta publicação contém fotos com música, não um vídeo MP4. Os arquivos não ficaram acessíveis nesta consulta.");
  return new YoutubeDownloads.Result(title+" • fotos e áudio separados",options);
 }
 static String imageExtension(byte[] b){if(b.length>=3&&(b[0]&255)==255&&(b[1]&255)==216&&(b[2]&255)==255)return "jpg";if(b.length>=8&&(b[0]&255)==137&&b[1]=='P'&&b[2]=='N'&&b[3]=='G'&&b[4]==13&&b[5]==10&&b[6]==26&&b[7]==10)return "png";if(b.length>=12&&b[0]=='R'&&b[1]=='I'&&b[2]=='F'&&b[3]=='F'&&b[8]=='W'&&b[9]=='E'&&b[10]=='B'&&b[11]=='P')return "webp";return "";}
 static String imageMime(String ext){return ext.equals("jpg")?"image/jpeg":"image/"+ext;}
}
