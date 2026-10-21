package br.com.onda;

import android.net.Uri;
import org.json.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

final class OnlineRepository {
    static final class Show {
        final String id, title, artist;
        Show(String id,String title,String artist){this.id=id;this.title=title;this.artist=artist;}
    }
    static final class Track {
        final String title, url;
        Track(String title,String url){this.title=title;this.url=url;}
    }
    private static JSONObject get(Uri uri) throws Exception {
        HttpURLConnection c=(HttpURLConnection)new URL(uri.toString()).openConnection();
        c.setConnectTimeout(12000);c.setReadTimeout(20000);
        c.setRequestProperty("User-Agent","Onda/0.4.0 (Android music player)");
        try {
            if(c.getResponseCode()!=200)throw new IOException("HTTP "+c.getResponseCode());
            try(InputStream in=c.getInputStream();ByteArrayOutputStream out=new ByteArrayOutputStream()){
                byte[] block=new byte[8192];int n;
                while((n=in.read(block))!=-1){if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();if(out.size()+n>8*1024*1024)throw new IOException("Resposta muito grande");out.write(block,0,n);}
                return new JSONObject(new String(out.toByteArray(),StandardCharsets.UTF_8));
            }
        }finally{c.disconnect();}
    }
    static final class Page {
        final List<Show> shows; final int total;
        Page(List<Show> shows,int total){this.shows=shows;this.total=total;}
    }
    static Page search(String input,int mode,int sort,int page) throws Exception {
        Uri.Builder builder=Uri.parse("https://archive.org/advancedsearch.php").buildUpon()
            .appendQueryParameter("q",SearchText.archiveQuery(input,mode)).appendQueryParameter("output","json")
            .appendQueryParameter("rows","20").appendQueryParameter("page",Integer.toString(Math.max(1,page)))
            .appendQueryParameter("fl[]","identifier,title,creator");
        if(sort==1)builder.appendQueryParameter("sort[]","downloads desc");
        else if(sort==2)builder.appendQueryParameter("sort[]","date desc");
        JSONObject response=get(builder.build()).getJSONObject("response");
        JSONArray docs=response.getJSONArray("docs");ArrayList<Show> result=new ArrayList<>();
        for(int i=0;i<docs.length();i++){JSONObject d=docs.getJSONObject(i);String id=d.optString("identifier");if(id.isEmpty())continue;Object creator=d.opt("creator");String artist=creator instanceof JSONArray?((JSONArray)creator).optString(0,"Artista desconhecido"):d.optString("creator","Artista desconhecido");result.add(new Show(id,d.optString("title",id),artist));}
        return new Page(result,response.optInt("numFound",result.size()));
    }
    static List<Track> tracks(Show show) throws Exception {
        JSONObject data=get(Uri.parse("https://archive.org").buildUpon().appendPath("metadata").appendPath(show.id).build());
        if(data.optBoolean("is_dark",false))return Collections.emptyList();
        JSONObject metadata=data.optJSONObject("metadata");
        if(metadata==null)return Collections.emptyList();
        Object collections=metadata.opt("collection");boolean live=collections instanceof JSONArray?has((JSONArray)collections,"etree"):"etree".equals(String.valueOf(collections));
        if(!live)return Collections.emptyList();
        JSONArray files=data.optJSONArray("files");ArrayList<Track> result=new ArrayList<>();
        if(files!=null)for(int i=0;i<files.length();i++){
            JSONObject f=files.getJSONObject(i);String name=f.optString("name");
            if(!name.toLowerCase(Locale.ROOT).endsWith(".mp3")||f.optString("private").equals("true"))continue;
            String url=Uri.parse("https://archive.org").buildUpon().appendPath("download").appendPath(show.id).appendPath(name).build().toString();
            result.add(new Track(f.optString("title",name.replaceFirst("(?i)\\.mp3$","")),url));
        }
        return result;
    }
    private static boolean has(JSONArray array,String expected){for(int i=0;i<array.length();i++)if(expected.equals(array.optString(i)))return true;return false;}
}
