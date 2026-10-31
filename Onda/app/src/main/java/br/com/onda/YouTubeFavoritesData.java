package br.com.onda;
import java.net.*;
import java.util.*;
import org.json.*;

/** Local explicit bookmarks, with bounded data and no network access. */
final class YouTubeFavoritesData {
 static final int MAX=200,MAX_RAW=256000;
 static final class Item {final String url,title;final long added;Item(String u,String t,long a){url=u;title=t;added=a;}}
 final List<Item> items=new ArrayList<>();boolean writable=true;
 static Map<String,String> parameters(URI u)throws Exception{Map<String,String> map=new HashMap<>();String raw=u.getRawQuery();if(raw!=null)for(String pair:raw.split("&")){String[] p=pair.split("=",2);String key=URLDecoder.decode(p[0],"UTF-8"),value=p.length==1?"":URLDecoder.decode(p[1],"UTF-8");if((key.equals("v")||key.equals("list"))&&map.put(key,value)!=null)throw new Exception("Duplicate key");}return map;}
 static URI official(String raw)throws Exception{if(raw==null||raw.length()>4096)throw new Exception();URI u=new URI(raw);String h=u.getHost();if(!"https".equalsIgnoreCase(u.getScheme())||h==null||u.getUserInfo()!=null||u.getPort()!=-1||!Arrays.asList("youtube.com","www.youtube.com","m.youtube.com","music.youtube.com","youtu.be").contains(h.toLowerCase(Locale.ROOT)))throw new Exception();return u;}
 static String playlist(String raw){try{URI u=official(raw);if(!Arrays.asList("/playlist","/watch").contains(u.getPath()))return "";String id=parameters(u).get("list");return id!=null&&id.matches("[A-Za-z0-9_-]{10,100}")?"https://m.youtube.com/playlist?list="+id:"";}catch(Exception e){return "";}}
 static String canonical(String raw){try{URI u=official(raw);String path=u.getPath(),id=null;if(u.getHost().equalsIgnoreCase("youtu.be"))id=path.startsWith("/")?path.substring(1).replaceFirst("/$",""):null;else if("/playlist".equals(path))return playlist(raw);else if("/watch".equals(path))id=parameters(u).get("v");else if(path.matches("/(shorts|live|embed)/[A-Za-z0-9_-]{11}/?"))id=path.split("/")[2];return id!=null&&id.matches("[A-Za-z0-9_-]{11}")?"https://m.youtube.com/watch?v="+id:"";}catch(Exception e){return "";}}
 static String title(String text){if(text==null)return "";String clean=text.replaceAll("[\\p{Cntrl}]"," ").trim();return clean.length()>160?clean.substring(0,160):clean;}
 static YouTubeFavoritesData decode(String raw){YouTubeFavoritesData d=new YouTubeFavoritesData();if(raw==null||raw.isEmpty())return d;try{if(raw.length()>MAX_RAW)throw new Exception();JSONObject root=new JSONObject(raw);if(!Integer.valueOf(1).equals(root.opt("version")))throw new Exception();JSONArray a=root.getJSONArray("items");if(a.length()>MAX)throw new Exception();Set<String> seen=new HashSet<>();for(int i=0;i<a.length();i++){JSONObject o=a.getJSONObject(i);String url=canonical(o.getString("url")),name=title(o.getString("title"));if(url.isEmpty()||name.isEmpty()||!seen.add(url))throw new Exception();d.items.add(new Item(url,name,Math.max(0,o.getLong("added"))));}}catch(Exception e){d.writable=false;d.items.clear();}return d;}
 Item find(String raw){String url=canonical(raw);for(Item i:items)if(i.url.equals(url))return i;return null;}
 boolean save(String raw,String name,long now){String url=canonical(raw),clean=title(name);if(!writable||url.isEmpty()||clean.isEmpty())return false;Item old=find(url);if(old==null&&items.size()>=MAX)return false;if(old!=null){int index=items.indexOf(old);items.set(index,new Item(url,clean,old.added));}else items.add(0,new Item(url,clean,Math.max(0,now)));return true;}
 boolean remove(String raw){if(!writable)return false;String url=canonical(raw);return items.removeIf(i->i.url.equals(url));}
 String encode(){if(!writable)throw new IllegalStateException("Read-only favorites");JSONObject root=new JSONObject();JSONArray all=new JSONArray();try{root.put("version",1);for(Item i:items)all.put(new JSONObject().put("url",i.url).put("title",i.title).put("added",i.added));root.put("items",all);String raw=root.toString();if(raw.length()>MAX_RAW)throw new IllegalStateException("Favorites too large");return raw;}catch(JSONException e){throw new IllegalStateException(e);}}
}
