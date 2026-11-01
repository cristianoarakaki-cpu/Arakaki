package br.com.onda;
import org.json.*;
import java.net.URI;
import java.util.*;
import java.util.regex.*;
/** Reads only the requested public item, never recommended posts or executable JavaScript. */
final class TiktokPage {
 static final int CANDIDATES=8;
 static final class Clip {final String title,video;final List<String> candidates;Clip(String title,String video){this(title,java.util.Collections.singletonList(video));}Clip(String title,List<String> urls){this.title=title;this.candidates=java.util.Collections.unmodifiableList(new ArrayList<>(urls));this.video=urls.get(0);}}
 static Clip parse(String html,String id)throws Exception{
  if(html==null||html.length()>8*1024*1024||id==null||!id.matches("[0-9]{10,24}"))throw new Exception("Página do vídeo inválida.");
  if(html.length()<65536&&html.contains("SlardarWAF")&&(html.contains("_wafchallengeid")||html.contains("waf-aiso")))throw new Exception("O TikTok exigiu verificação nesta consulta e não enviou os dados do vídeo. Abra o link no TikTok ou navegador; depois tente novamente. A liberação pode variar entre consultas.");
  for(String name:new String[]{"__UNIVERSAL_DATA_FOR_REHYDRATION__","SIGI_STATE","sigi-persisted-data"}){
   Matcher script=Pattern.compile("<script\\b[^>]*\\bid\\s*=\\s*['\"]"+name+"['\"][^>]*>(.*?)</script\\s*>",Pattern.CASE_INSENSITIVE|Pattern.DOTALL).matcher(html);
   while(script.find()){
    JSONObject root;try{root=new JSONObject(script.group(1));}catch(JSONException invalid){continue;}JSONObject item=null;
    if(name.equals("__UNIVERSAL_DATA_FOR_REHYDRATION__")){
     JSONObject scope=root.optJSONObject("__DEFAULT_SCOPE__"),detail=scope==null?null:scope.optJSONObject("webapp.video-detail");
     if(detail==null&&scope!=null){JSONObject reflow=scope.optJSONObject("webapp.reflow.video.detail");if(reflow!=null&&reflow.optInt("statusCode",0)!=0)throw new Exception("O TikTok retornou uma página de compartilhamento sem disponibilizar o vídeo nesta sessão. Tente o link completo do vídeo; o serviço pode exigir verificação ou limitar a consulta pública.");}
     if(detail!=null&&detail.optInt("statusCode",0)!=0)throw new Exception("O TikTok não disponibilizou este vídeo publicamente.");JSONObject info=detail==null?null:detail.optJSONObject("itemInfo");item=info==null?null:info.optJSONObject("itemStruct");
    }else{JSONObject module=root.optJSONObject("ItemModule");item=module==null?null:module.optJSONObject(id);}
    if(item==null)continue;if(!id.equals(item.optString("id")))throw new Exception("A página retornou outro vídeo.");if(item.optBoolean("privateItem")||item.optBoolean("isContentClassified")||item.optJSONObject("imagePost")!=null)throw new Exception("Este conteúdo é privado, restrito ou uma publicação de fotos. Use um vídeo público.");JSONObject video=item.optJSONObject("video");if(video==null)continue;
    List<LinkedHashSet<String>> groups=new ArrayList<>();
    for(Object source:new Object[]{video.opt("downloadAddr"),video.opt("playAddr"),video.opt("download")}){LinkedHashSet<String> urls=new LinkedHashSet<>();collect(source,urls);groups.add(urls);}
    LinkedHashSet<String> bitrateUrls=new LinkedHashSet<>();JSONArray rates=video.optJSONArray("bitrateInfo");if(rates!=null)for(int i=0;i<Math.min(20,rates.length());i++){JSONObject rate=rates.optJSONObject(i),play=rate==null?null:rate.optJSONObject("PlayAddr");if(play==null||play.optString("UrlKey").toLowerCase(Locale.ROOT).matches(".*(?:bytevc|hvc1|h265).*"))continue;collect(play,bitrateUrls);}groups.add(bitrateUrls);
    LinkedHashSet<String> urls=new LinkedHashSet<>();interleave(groups,urls,false);interleave(groups,urls,true);
    if(!urls.isEmpty()){String title=item.optString("desc","").trim();if(title.isEmpty())title="TikTok "+id;return new Clip(title.substring(0,Math.min(160,title.length())),new ArrayList<>(urls));}
   }
  }
  throw new Exception("O TikTok não expôs um arquivo de vídeo público nesta consulta. Pode exigir verificação, login, estar removido ou ter alterado a página. Tente mais tarde.");
 }
 /** Keep at least one URL from each source before spending the budget on mirrors. */
 private static void interleave(List<LinkedHashSet<String>> groups,LinkedHashSet<String> out,boolean official){List<Iterator<String>> cursors=new ArrayList<>();for(Set<String> group:groups)cursors.add(group.iterator());boolean more=true;while(more&&out.size()<CANDIDATES){more=false;for(Iterator<String> cursor:cursors){while(cursor.hasNext()){String url=cursor.next();if(MediaLinks.isTikTok(url)!=official)continue;more=true;out.add(url);break;}if(out.size()>=CANDIDATES)return;}}}
 static void collect(Object value,LinkedHashSet<String> urls){collect(value,urls,0);}
 private static void collect(Object value,LinkedHashSet<String> urls,int depth){if(urls.size()>=CANDIDATES||depth>5)return;if(value instanceof JSONArray){JSONArray array=(JSONArray)value;for(int i=0;i<Math.min(10,array.length())&&urls.size()<CANDIDATES;i++)collect(array.opt(i),urls,depth+1);return;}if(value instanceof JSONObject){JSONObject o=(JSONObject)value;for(String key:new String[]{"UrlList","urlList","urls","src","url"})collect(o.opt(key),urls,depth+1);return;}String url=address(value);if(!url.isEmpty())urls.add(url);}
 static String address(Object value){return address(value,0);}
 private static String address(Object value,int depth){if(depth>5)return "";if(value instanceof String){String text=(String)value;if(text.length()>16384)return "";try{URI uri=new URI(text);if(!MediaLinks.publicShape(uri)||(MediaLinks.tiktokHost(uri.getHost())&&!officialMedia(uri)))return "";return uri.toASCIIString();}catch(Exception e){return "";}}if(value instanceof JSONObject){JSONObject object=(JSONObject)value;for(String key:new String[]{"UrlList","urlList","urls","src","url"}){String result=address(object.opt(key),depth+1);if(!result.isEmpty())return result;}}if(value instanceof JSONArray){JSONArray list=(JSONArray)value;for(int i=0;i<Math.min(10,list.length());i++){String result=address(list.opt(i),depth+1);if(!result.isEmpty())return result;}}return "";}
 /** These are file redirect endpoints, not watch/login/share pages. Actual bytes are still verified. */
 private static boolean officialMedia(URI uri){String host=uri.getHost().toLowerCase(Locale.ROOT);if(!host.equals("www.tiktok.com")&&!host.equals("tiktok.com")&&!host.equals("m.tiktok.com"))return false;if(!uri.getPath().matches("/aweme/v1/play(?:wm)?/?"))return false;String query=uri.getRawQuery();if(query==null)return false;boolean found=false;for(String part:query.split("&")){String[] pair=part.split("=",2);if(pair[0].equals("video_id")){if(found||pair.length!=2||!pair[1].matches("[A-Za-z0-9_-]{6,256}"))return false;found=true;}}return found;}
}
