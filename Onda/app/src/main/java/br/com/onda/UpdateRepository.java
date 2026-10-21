package br.com.onda;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import org.json.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;

final class UpdateRepository {
    static final String RELEASES="https://api.github.com/repos/cristianoarakaki-cpu/Arakaki/releases?per_page=20";
    private static final String ASSETS="https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/";
    static final class Update {
        final int code; final String version,url,sha;
        Update(JSONObject data,String packageName) throws Exception {
            code=data.getInt("versionCode");version=data.getString("versionName");url=data.getString("apkUrl");sha=data.getString("sha256");
            if(code<=0||!packageName.equals(data.getString("packageName"))||!validAsset(url)||!sha.matches("[a-fA-F0-9]{64}"))throw new IOException("Atualização inválida");
        }
    }
    interface Progress { void changed(long bytes,long total); }
    static boolean validAsset(String url) { return url!=null&&url.startsWith(ASSETS)&&!url.contains("\\"); }
    private static HttpURLConnection connect(String url) throws Exception {
        HttpURLConnection c=(HttpURLConnection)new URL(url).openConnection();c.setConnectTimeout(10000);c.setReadTimeout(20000);
        c.setRequestProperty("User-Agent","Onda-Music-Android");c.setRequestProperty("Accept","application/json, application/octet-stream");
        if(c.getResponseCode()!=200){int code=c.getResponseCode();c.disconnect();throw new IOException(code==403||code==429?"Muitas consultas. Tente mais tarde.":"Servidor indisponível ("+code+")");}return c;
    }
    private static String text(String url) throws Exception {
        HttpURLConnection c=connect(url);
        try(InputStream in=c.getInputStream();ByteArrayOutputStream out=new ByteArrayOutputStream()){
            byte[] buf=new byte[4096];int n;
            while((n=in.read(buf))!=-1){if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();if(out.size()+n>1048576)throw new IOException("Resposta inválida");out.write(buf,0,n);}
            return new String(out.toByteArray(),StandardCharsets.UTF_8);
        }finally{c.disconnect();}
    }
    static Update latest(String packageName) throws Exception {
        JSONArray releases=new JSONArray(text(RELEASES));Update best=null;
        for(int i=0;i<releases.length();i++){
            JSONObject r=releases.getJSONObject(i);
            if(r.optBoolean("draft")||r.optBoolean("prerelease")||!r.optString("tag_name").startsWith("onda-v"))continue;
            JSONArray assets=r.optJSONArray("assets");if(assets==null)continue;
            for(int j=0;j<assets.length();j++){JSONObject a=assets.getJSONObject(j);if(!a.optString("name").equals("onda-update.json"))continue;String url=a.optString("browser_download_url");if(!validAsset(url))throw new IOException("Origem inválida");Update u=new Update(new JSONObject(text(url)),packageName);if(best==null||u.code>best.code)best=u;}
        }
        return best;
    }
    static File download(Context context,Update update,Progress progress) throws Exception {
        File directory=new File(context.getCacheDir(),"updates");if(!directory.isDirectory()&&!directory.mkdirs())throw new IOException("Não foi possível salvar o APK");
        File partial=new File(directory,"download.part"),apk=new File(directory,"onda-update.apk");
        HttpURLConnection c=connect(update.url);boolean complete=false;
        try{
            long length=c.getContentLengthLong();if(length>64*1024*1024)throw new IOException("APK muito grande");
            MessageDigest hash=MessageDigest.getInstance("SHA-256");long bytes=0,last=0;
            try(InputStream in=c.getInputStream();OutputStream out=new FileOutputStream(partial)){
                byte[] buffer=new byte[16384];int n;
                while((n=in.read(buffer))!=-1){if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();bytes+=n;if(bytes>64*1024*1024)throw new IOException("APK muito grande");out.write(buffer,0,n);hash.update(buffer,0,n);long now=System.currentTimeMillis();if(now-last>300){last=now;progress.changed(bytes,length);}}
            }
            StringBuilder actual=new StringBuilder();for(byte b:hash.digest())actual.append(String.format(java.util.Locale.ROOT,"%02x",b&255));
            if(!actual.toString().equalsIgnoreCase(update.sha))throw new IOException("Download incompleto ou alterado. Tente novamente.");
            verify(context,partial,update.code);
            if(apk.exists()&&!apk.delete())throw new IOException("Não foi possível substituir o download");
            if(!partial.renameTo(apk))throw new IOException("Não foi possível salvar a atualização");
            complete=true;return apk;
        }finally{c.disconnect();if(!complete)partial.delete();}
    }
    @SuppressWarnings("deprecation")
    static void verify(Context context,File file,int expectedVersion) throws Exception {
        PackageManager manager=context.getPackageManager();
        PackageInfo current=manager.getPackageInfo(context.getPackageName(),PackageManager.GET_SIGNATURES);
        PackageInfo candidate=manager.getPackageArchiveInfo(file.getAbsolutePath(),PackageManager.GET_SIGNATURES);
        if(candidate==null||!current.packageName.equals(candidate.packageName)||candidate.versionCode!=expectedVersion||candidate.versionCode<=current.versionCode)throw new IOException("O APK não é uma atualização compatível deste Onda");
        if(current.signatures==null||candidate.signatures==null||current.signatures.length!=1||candidate.signatures.length!=1||!Arrays.equals(current.signatures[0].toByteArray(),candidate.signatures[0].toByteArray()))throw new IOException("A assinatura da atualização é diferente. Seu app foi mantido.");
    }
}
