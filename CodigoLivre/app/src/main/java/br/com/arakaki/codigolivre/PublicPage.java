package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.jsoup.*;
import org.jsoup.nodes.*;
import org.json.*;

final class PublicPage {
    final String title,text,url;final boolean restricted;final List<LiveFeeds.Match> matches;
    PublicPage(String title,String text,String url,boolean restricted,List<LiveFeeds.Match> matches){this.title=title;this.text=text;this.url=url;this.restricted=restricted;this.matches=matches;}
    static PublicPage read(byte[] bytes,String url)throws Exception{
        WebSafety.url(url);String html=new String(bytes,StandardCharsets.UTF_8);if(html.startsWith("%PDF")||html.indexOf('\0')>=0)throw new IOException("Conteúdo não é uma página de texto suportada.");
        if(html.trim().matches("(?is)^(<\\?xml[^>]*>\\s*)?<(rss|feed)\\b.*"))throw new IOException("O link retornou um feed, não uma página de artigo.");
        Document doc=Jsoup.parse(new ByteArrayInputStream(bytes),null,url);String title=doc.title();String normalized=WebQuery.normalized(title);List<LiveFeeds.Match> matches=new ArrayList<>();
        boolean restricted=normalized.matches(".*(access denied|just a moment|captcha|sign in|acesso negado).*")||html.matches("(?s).*\"isAccessibleForFree\"\\s*:\\s*false.*");
        if(!restricted){
            for(Element script:doc.select("script")){
                String data=script.data().trim();try{
                    if(script.attr("type").contains("ld+json")||script.id().equals("__NEXT_DATA__"))walk(json(data),url,matches,0,new int[]{0});
                    else if(data.contains("__espnfitt__")){String object=objectAfter(data,"__espnfitt__");if(object!=null)walk(json(object),url,matches,0,new int[]{0});}
                }catch(Exception ignored){}
            }
            for(Element event:doc.select("[itemtype*=SportsEvent]")){
                Element start=event.selectFirst("[itemprop=startDate]"),home=event.selectFirst("[itemprop=homeTeam]"),away=event.selectFirst("[itemprop=awayTeam]");
                Element eventStatus=event.selectFirst("[itemprop=eventStatus]");String status=eventStatus==null?"":eventStatus.attr("content").toLowerCase(Locale.ROOT);
                if(start!=null&&home!=null&&away!=null&&!status.matches(".*(cancel|postpon|suspend).*")){try{String when=start.hasAttr("content")?start.attr("content"):start.attr("datetime");String names=home.text()+" x "+away.text();if(WebQuery.normalized(names).contains("flamengo"))matches.add(new LiveFeeds.Match("microdata",names,"Competição não informada na página",when,url,true));}catch(Exception ignored){}}
            }
        }
        doc.select("script,style,noscript,nav,header,footer,aside,form,[hidden],[aria-hidden=true]").remove();
        Element main=doc.selectFirst("article");if(main==null)main=doc.selectFirst("main");if(main==null)main=doc.body();
        String text=restricted?"Página com acesso restrito ou bloqueado; conteúdo não utilizado.":main==null?"":main.text().replaceAll("\\s+"," ").trim();
        if(text.length()>2400)text=text.substring(0,2400)+" [trecho abreviado]";
        return new PublicPage(title,text,url,restricted,matches);
    }
    static Object json(String source)throws Exception{
        int level=0;boolean quoted=false,escaped=false;
        for(int i=0;i<source.length();i++){char c=source.charAt(i);if(quoted){if(escaped)escaped=false;else if(c=='\\')escaped=true;else if(c=='"')quoted=false;}else if(c=='"')quoted=true;else if(c=='{'||c=='['){if(++level>64)throw new IOException("JSON estruturado profundo demais.");}else if(c=='}'||c==']')level--;}
        return new JSONTokener(source).nextValue();
    }
    static String objectAfter(String data,String marker){
        int at=data.indexOf(marker),start=data.indexOf('{',at+marker.length());if(at<0||start<0)return null;
        int depth=0;boolean quoted=false,escaped=false;
        for(int i=start;i<data.length();i++){char c=data.charAt(i);if(quoted){if(escaped)escaped=false;else if(c=='\\')escaped=true;else if(c=='"')quoted=false;}else if(c=='"')quoted=true;else if(c=='{')depth++;else if(c=='}'&&--depth==0)return data.substring(start,i+1);}return null;
    }
    static void walk(Object value,String url,List<LiveFeeds.Match> matches,int depth,int[] nodes)throws Exception{
        if(depth>30||++nodes[0]>50000||matches.size()>500)return;
        if(value instanceof JSONArray){JSONArray a=(JSONArray)value;for(int i=0;i<a.length();i++)walk(a.get(i),url,matches,depth+1,nodes);return;}
        if(!(value instanceof JSONObject))return;JSONObject o=(JSONObject)value;
        if(o.has("competitions")&&o.has("date")){
            for(LiveFeeds.Match m:OnlineResearch.parseMatches(("{\"events\":["+o+"]}").getBytes(StandardCharsets.UTF_8),""))matches.add(new LiveFeeds.Match(m.id,m.opponents,m.competition,m.when.toString(),url,m.timeValid));
        }
        if(o.optString("@type").contains("SportsEvent")){
            String status=o.optString("eventStatus").toLowerCase(Locale.ROOT),home=name(o.opt("homeTeam")),away=name(o.opt("awayTeam"));String title=o.optString("name");
            if(!status.matches(".*(cancel|postpon|suspend).*")&&WebQuery.normalized(home+" "+away+" "+title).contains("flamengo")&&!home.isEmpty()&&!away.isEmpty()){
                try{String competition=name(o.opt("superEvent"));matches.add(new LiveFeeds.Match(o.optString("identifier","jsonld"),home+" x "+away,competition.isEmpty()?"Competição não informada na página":competition,o.getString("startDate"),url,true));}catch(Exception ignored){}
            }
        }
        Iterator<String> keys=o.keys();while(keys.hasNext())walk(o.get(keys.next()),url,matches,depth+1,nodes);
    }
    static String name(Object value){return value instanceof JSONObject?((JSONObject)value).optString("name"):value instanceof String?(String)value:"";}
}
