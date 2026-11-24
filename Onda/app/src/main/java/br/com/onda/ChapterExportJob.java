package br.com.onda;
import android.content.*;import android.net.Uri;import org.json.*;
/** Immutable user selection; quality and range cannot drift while a conversion is running. */
@androidx.media3.common.util.UnstableApi
final class ChapterExportJob {
 final String token,stamp,title;final Uri source,target;final long start,end,duration;final int bitrate;
 ChapterExportJob(String token,Uri source,Uri target,String stamp,String title,long start,long end,long duration,int bitrate){this.token=token;this.source=source;this.target=target;this.stamp=stamp;this.title=title==null?"Faixa":title;this.start=start;this.end=end;this.duration=duration;this.bitrate=bitrate;}
 boolean valid(){return token!=null&&token.length()<=80&&source!=null&&("file".equals(source.getScheme())||"content".equals(source.getScheme()))&&target!=null&&"content".equals(target.getScheme())&&!source.equals(target)&&stamp!=null&&start>=0&&end>start&&end<=duration&&Mp3Quality.valid(bitrate);}
 boolean matches(Uri uri,String fingerprint,long from,long to){return source.equals(uri)&&stamp.equals(fingerprint)&&start==from&&end==to;}
 JSONObject json()throws JSONException{return new JSONObject().put("token",token).put("source",source.toString()).put("target",target.toString()).put("stamp",stamp).put("title",title).put("start",start).put("end",end).put("duration",duration).put("bitrate",bitrate);}
 static ChapterExportJob parse(String text)throws JSONException{JSONObject j=new JSONObject(text);ChapterExportJob job=new ChapterExportJob(j.getString("token"),Uri.parse(j.getString("source")),Uri.parse(j.getString("target")),j.getString("stamp"),j.getString("title"),j.getLong("start"),j.getLong("end"),j.getLong("duration"),j.getInt("bitrate"));if(!job.valid())throw new JSONException("Conversão inválida");return job;}
 Intent screen(Context c){return new Intent(c,ChapterExportActivity.class).putExtra("source",source.toString()).putExtra("stamp",stamp).putExtra("name",title).putExtra("start",start).putExtra("end",end).putExtra("duration",duration).putExtra("job_token",token);}
}
