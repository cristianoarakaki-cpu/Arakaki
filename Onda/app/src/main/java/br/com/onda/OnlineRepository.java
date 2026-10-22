package br.com.onda;

import android.net.Uri;
import org.json.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

final class OnlineRepository {
    static final int CATALOG=0,LIVE=1;
    static final class Show {
        final String id,title,artist,previewUrl,storeUrl,album;
        Show(String id,String title,String artist){this(id,title,artist,"","",title);}
        Show(String id,String title,String artist,String preview,String store,String album){this.id=id;this.title=title;this.artist=artist;previewUrl=preview;storeUrl=store;this.album=album;}
        boolean isPreview(){return !previewUrl.isEmpty();}
    }
    static final class Track {final String title,url;Track(String title,String url){this.title=title;this.url=url;}}
    static final class Page {
        final List<Show> shows;final int total;final boolean catalog,broadened;
        Page(List<Show> shows,int total,boolean catalog,boolean broadened){this.shows=shows;this.total=total;this.catalog=catalog;this.broadened=broadened;}
    }
    private static final class Cached {final List<Show> values;final long time=System.currentTimeMillis();Cached(List<Show> values){this.values=values;}}
    private static final LinkedHashMap<String,Cached> CACHE=new LinkedHashMap<>();
    private static JSONObject get(Uri uri) throws Exception {
        HttpURLConnection c=(HttpURLConnection)new URL(uri.toString()).openConnection();c.setConnectTimeout(12000);c.setReadTimeout(20000);c.setRequestProperty("User-Agent","Onda/0.7.0 (Android music discovery)");
        try{
            int code=c.getResponseCode();if(code!=200)throw new IOException(code==429?"Muitas consultas. Tente novamente em alguns instantes.":"O serviço respondeu com erro "+code+".");
            try(InputStream in=c.getInputStream();ByteArrayOutputStream out=new ByteArrayOutputStream()){
                byte[] block=new byte[8192];int n;while((n=in.read(block))!=-1){if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();if(out.size()+n>8*1024*1024)throw new IOException("Resposta muito grande");out.write(block,0,n);}
                JSONObject result=new JSONObject(new String(out.toByteArray(),StandardCharsets.UTF_8));
                if(result.has("error"))throw new IOException("O serviço não conseguiu processar a busca.");return result;
            }
        }finally{c.disconnect();}
    }
    static Page search(String input,int mode,int sort,int page,int source) throws Exception {
        if(source==CATALOG)return catalog(input,mode,page);
        Page found=live(input,mode,sort,page,false);
        if(found.total==0&&mode!=0)return live(input,0,sort,page,true);
        return found;
    }
    private static Page live(String input,int mode,int sort,int page,boolean broadened) throws Exception {
        Uri.Builder builder=Uri.parse("https://archive.org/advancedsearch.php").buildUpon().appendQueryParameter("q",SearchText.archiveQuery(input,mode)).appendQueryParameter("output","json").appendQueryParameter("rows","20").appendQueryParameter("page",Integer.toString(Math.max(1,page))).appendQueryParameter("fl[]","identifier,title,creator");
        if(sort==1)builder.appendQueryParameter("sort[]","downloads desc");else if(sort==2)builder.appendQueryParameter("sort[]","date desc");
        JSONObject root=get(builder.build()),response=root.optJSONObject("response");if(response==null)throw new IOException("O acervo retornou uma resposta incompleta. Tente novamente.");
        JSONArray docs=response.optJSONArray("docs");if(docs==null)throw new IOException("O acervo não retornou a lista de resultados.");ArrayList<Show> result=new ArrayList<>();
        for(int i=0;i<docs.length();i++){JSONObject d=docs.getJSONObject(i);String id=d.optString("identifier");if(!id.isEmpty())result.add(new Show(id,d.optString("title",id),human(d,"creator","Artista desconhecido")));}
        return new Page(result,response.optInt("numFound",result.size()),false,broadened);
    }
    private static Page catalog(String input,int mode,int page) throws Exception {
        String term=SearchText.catalogTerm(input),key=mode+":"+term;if(term.isEmpty())return new Page(Collections.emptyList(),0,true,false);List<Show> values=null;
        synchronized(CACHE){Cached cached=CACHE.get(key);if(cached!=null&&System.currentTimeMillis()-cached.time<300000)values=cached.values;}
        if(values==null){
            LinkedHashMap<String,Show> merged=new LinkedHashMap<>();Exception failure=null;
            String[] attributes=mode==1?new String[]{"artistTerm"}:mode==2?new String[]{"songTerm"}:new String[]{"artistTerm",""};
            for(String attribute:attributes){
                if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();
                Uri.Builder url=Uri.parse("https://itunes.apple.com/search").buildUpon().appendQueryParameter("term",term).appendQueryParameter("country","BR").appendQueryParameter("entity","song").appendQueryParameter("limit","100").appendQueryParameter("lang","pt_br");
                if(!attribute.isEmpty())url.appendQueryParameter("attribute",attribute);
                try{for(Show item:parseCatalog(get(url.build())))merged.putIfAbsent(item.id,item);}catch(InterruptedIOException e){throw e;}catch(Exception e){failure=e;}
            }
            if(merged.isEmpty()&&failure!=null)throw failure;
            ArrayList<Show> ranked=new ArrayList<>(merged.values());ranked.sort((a,b)->Integer.compare(SearchText.relevance(input,b.title,b.artist),SearchText.relevance(input,a.title,a.artist)));
            LinkedHashMap<String,Show> unique=new LinkedHashMap<>();for(Show item:ranked)unique.putIfAbsent(SearchText.normalize(item.artist)+"|"+SearchText.normalize(item.title),item);
            values=Collections.unmodifiableList(new ArrayList<>(unique.values()));
            synchronized(CACHE){if(CACHE.size()>=8)CACHE.remove(CACHE.keySet().iterator().next());CACHE.put(key,new Cached(values));}
        }
        int start=Math.min(values.size(),Math.max(0,page-1)*20),end=Math.min(values.size(),start+20);
        return new Page(new ArrayList<>(values.subList(start,end)),values.size(),true,false);
    }
    static List<Show> parseCatalog(JSONObject response) throws Exception {
        JSONArray rows=response.optJSONArray("results");if(rows==null)throw new IOException("O catálogo retornou uma resposta incompleta.");ArrayList<Show> values=new ArrayList<>();
        for(int i=0;i<rows.length();i++){
            JSONObject t=rows.getJSONObject(i);String preview=t.optString("previewUrl"),store=t.optString("trackViewUrl");
            if(!"song".equals(t.optString("kind"))||!allowedPreview(preview)||!allowedStore(store)||t.optLong("trackId",0)<=0)continue;
            values.add(new Show(Long.toString(t.getLong("trackId")),t.optString("trackName","Sem título"),t.optString("artistName","Artista desconhecido"),preview,store,t.optString("collectionName","Apple Music")));
        }
        return values;
    }
    static boolean allowedPreview(String url){try{URI u=new URI(url);String host=u.getHost();return "https".equals(u.getScheme())&&host!=null&&(host.endsWith(".itunes.apple.com")||host.endsWith(".mzstatic.com"));}catch(Exception e){return false;}}
    static boolean allowedStore(String url){try{URI u=new URI(url);return "https".equals(u.getScheme())&&("music.apple.com".equals(u.getHost())||"itunes.apple.com".equals(u.getHost()));}catch(Exception e){return false;}}
    static List<Track> tracks(Show show) throws Exception {
        JSONObject data=get(Uri.parse("https://archive.org").buildUpon().appendPath("metadata").appendPath(show.id).build());if(data.optBoolean("is_dark",false))return Collections.emptyList();JSONObject metadata=data.optJSONObject("metadata");if(metadata==null)return Collections.emptyList();
        Object collections=metadata.opt("collection");boolean live=collections instanceof JSONArray?has((JSONArray)collections,"etree"):"etree".equals(String.valueOf(collections));if(!live)return Collections.emptyList();
        JSONArray files=data.optJSONArray("files");ArrayList<Track> result=new ArrayList<>();
        if(files!=null)for(int i=0;i<files.length();i++){JSONObject f=files.getJSONObject(i);String name=f.optString("name");if(!name.toLowerCase(Locale.ROOT).endsWith(".mp3")||f.optString("private").equals("true"))continue;String url=Uri.parse("https://archive.org").buildUpon().appendPath("download").appendPath(show.id).appendPath(name).build().toString();result.add(new Track(f.optString("title",name.replaceFirst("(?i)\\.mp3$","")),url));}return result;
    }
    private static String human(JSONObject data,String field,String fallback){Object value=data.opt(field);return value instanceof JSONArray?((JSONArray)value).optString(0,fallback):value==null||value==JSONObject.NULL?fallback:String.valueOf(value);}
    private static boolean has(JSONArray array,String expected){for(int i=0;i<array.length();i++)if(expected.equals(array.optString(i)))return true;return false;}
}
