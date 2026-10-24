package br.com.onda;
import android.graphics.*;
import android.os.*;
import android.util.LruCache;
import android.widget.ImageView;
import java.io.*;
import java.lang.ref.WeakReference;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;

/** Visible thumbnails only: two workers, bounded queue/response/cache, disconnect on leaving the screen. */
final class PlaylistArtwork implements AutoCloseable {
 private final Runnable loaded;PlaylistArtwork(Runnable action){loaded=action;}
 private final Handler ui=new Handler(Looper.getMainLooper());private final ThreadPoolExecutor pool=new ThreadPoolExecutor(2,2,0,TimeUnit.MILLISECONDS,new ArrayBlockingQueue<>(24),new ThreadPoolExecutor.AbortPolicy());
 private final LruCache<String,Bitmap> cache=new LruCache<String,Bitmap>(8*1024*1024){@Override protected int sizeOf(String k,Bitmap b){return b.getAllocationByteCount();}};
 private final Set<HttpURLConnection> connections=ConcurrentHashMap.newKeySet();private final ConcurrentHashMap<String,Integer> pending=new ConcurrentHashMap<>();private volatile boolean active=true,closed;private volatile int generation;
 void load(String url,ImageView target){target.setTag(url);target.setImageDrawable(null);if(url.isEmpty()||closed)return;Bitmap b=cache.get(url);if(b!=null){target.setImageBitmap(b);return;}if(!active)return;int request=generation;if(pending.putIfAbsent(url,request)!=null)return;WeakReference<ImageView> ref=new WeakReference<>(target);
  try{pool.execute(()->{try{if(!active||closed||request!=generation)return;Bitmap bitmap=fetch(url);if(bitmap!=null&&active&&!closed&&request==generation){cache.put(url,bitmap);ui.post(()->{ImageView view=ref.get();if(active&&!closed&&request==generation){if(view!=null&&url.equals(view.getTag()))view.setImageBitmap(bitmap);loaded.run();}});}}catch(Exception ignored){}finally{pending.remove(url,request);}});}catch(RejectedExecutionException e){pending.remove(url,request);}
 }
 private Bitmap fetch(String url)throws IOException{if(PlaylistSelection.artwork(url).isEmpty())return null;HttpURLConnection c=(HttpURLConnection)new URL(url).openConnection();connections.add(c);try{c.setInstanceFollowRedirects(false);c.setConnectTimeout(5000);c.setReadTimeout(5000);if(c.getResponseCode()!=200||c.getContentLengthLong()>512*1024)return null;ByteArrayOutputStream out=new ByteArrayOutputStream();try(InputStream in=c.getInputStream()){byte[] bytes=new byte[8192];int n;while((n=in.read(bytes))!=-1){if(!active||closed||Thread.currentThread().isInterrupted())return null;if(out.size()+n>512*1024)return null;out.write(bytes,0,n);}}byte[] bytes=out.toByteArray();BitmapFactory.Options options=new BitmapFactory.Options();options.inJustDecodeBounds=true;BitmapFactory.decodeByteArray(bytes,0,bytes.length,options);if(options.outWidth<=0||options.outHeight<=0||options.outWidth>8192||options.outHeight>8192)return null;options.inSampleSize=1;while(options.outWidth/options.inSampleSize>480||options.outHeight/options.inSampleSize>270)options.inSampleSize*=2;options.inJustDecodeBounds=false;options.inPreferredConfig=Bitmap.Config.RGB_565;return BitmapFactory.decodeByteArray(bytes,0,bytes.length,options);}finally{connections.remove(c);c.disconnect();}}
 void pause(){active=false;generation++;for(HttpURLConnection c:connections)c.disconnect();pool.getQueue().clear();pending.clear();}
 void resume(){if(!closed)active=true;}
 @Override public void close(){closed=true;pause();pool.shutdownNow();cache.evictAll();}
}
