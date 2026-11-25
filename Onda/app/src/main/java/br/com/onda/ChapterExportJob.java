package br.com.onda;
import android.content.*;import android.net.Uri;import org.json.*;
/** Immutable user selection; quality and range cannot drift while a conversion is running. */
@androidx.media3.common.util.UnstableApi
final class ChapterExportJob {
 final String token,stamp,title,memoryTag;final Uri source,target;final long start,end,duration;final int bitrate,restorationProfile;
 ChapterExportJob(String token,Uri source,Uri target,String stamp,String title,long start,long end,long duration,int bitrate){this(token,source,target,stamp,title,start,end,duration,bitrate,"");}
 ChapterExportJob(String token,Uri source,Uri target,String stamp,String title,long start,long end,long duration,int bitrate,String memoryTag){this(token,source,target,stamp,title,start,end,duration,bitrate,memoryTag,0);}
 ChapterExportJob(String token,Uri source,Uri target,String stamp,String title,long start,long end,long duration,int bitrate,String memoryTag,int profile){this.restorationProfile=profile;this.memoryTag=memoryTag==null?"":memoryTag;this.token=token;this.source=source;this.target=target;this.stamp=stamp;this.title=title==null?"Faixa":title;this.start=start;this.end=end;this.duration=duration;this.bitrate=bitrate;}
 boolean valid(){return RestorationDsp.valid(restorationProfile)&&token!=null&&token.length()<=80&&source!=null&&("file".equals(source.getScheme())||"content".equals(source.getScheme()))&&target!=null&&"content".equals(target.getScheme())&&!source.equals(target)&&stamp!=null&&start>=0&&end>start&&end<=duration&&Mp3Quality.valid(bitrate)&&(memoryTag.isEmpty()||memoryTag.matches("[a-f0-9]{64}"));}
 boolean matches(Uri uri,String fingerprint,long from,long to){return source.equals(uri)&&stamp.equals(fingerprint)&&start==from&&end==to;}
 JSONObject json()throws JSONException{return new JSONObject().put("token",token).put("source",source.toString()).put("target",target.toString()).put("stamp",stamp).put("title",title).put("start",start).put("end",end).put("duration",duration).put("bitrate",bitrate).put("memory_tag",memoryTag).put("restoration_profile",restorationProfile);}
 static ChapterExportJob parse(String text)throws JSONException{JSONObject j=new JSONObject(text);ChapterExportJob job=new ChapterExportJob(j.getString("token"),Uri.parse(j.getString("source")),Uri.parse(j.getString("target")),j.getString("stamp"),j.getString("title"),j.getLong("start"),j.getLong("end"),j.getLong("duration"),j.getInt("bitrate"),j.optString("memory_tag",""),j.optInt("restoration_profile",0));if(!job.valid())throw new JSONException("Conversão inválida");return job;}
 Intent screen(Context c){return new Intent(c,ChapterExportActivity.class).putExtra("source",source.toString()).putExtra("stamp",stamp).putExtra("name",title).putExtra("start",start).putExtra("end",end).putExtra("duration",duration).putExtra("job_token",token).putExtra("memory_tag",memoryTag).putExtra("restoration_profile",restorationProfile);}
}
