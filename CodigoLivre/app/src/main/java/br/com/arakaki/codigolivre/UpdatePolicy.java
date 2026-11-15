package br.com.arakaki.codigolivre;
import java.net.URI;
import java.security.*;
import java.util.*;

/** Regras do atualizador, independentes de Android e da rede. */
final class UpdatePolicy {
    static final long MAX_APK=64L*1024*1024;
    static final String PACKAGE="br.com.arakaki.codigolivre";
    static final class Info {
        final long version,bytes;final String name,url,sha,notes;
        Info(long version,String name,String url,String sha,long bytes,String packageName,String notes){
            if(version<1||name.isEmpty()||name.length()>40||!PACKAGE.equals(packageName))throw new IllegalArgumentException("Metadados de atualização inválidos.");
            trusted(url);if(!sha.matches("[0-9a-fA-F]{64}")||bytes<1||bytes>MAX_APK)throw new IllegalArgumentException("Tamanho ou SHA256 inválido.");
            this.version=version;this.name=name;this.url=url;this.sha=sha.toLowerCase(Locale.ROOT);this.bytes=bytes;this.notes=notes.length()>1200?notes.substring(0,1200):notes;
        }
        boolean newerThan(long installed){return version>installed;}
    }
    static void trusted(String url){
        URI u=URI.create(url);String path=u.getPath();
        if(!"https".equals(u.getScheme())||!"raw.githubusercontent.com".equals(u.getHost())||u.getRawUserInfo()!=null||u.getPort()!=-1||u.getFragment()!=null||u.getQuery()!=null||path==null||!path.startsWith("/cristianoarakaki-cpu/Arakaki/")||Arrays.asList(path.split("/")).contains(".."))throw new IllegalArgumentException("Endereço de atualização não autorizado.");
    }
    static boolean validDigest(String expected,byte[] actual){return MessageDigest.isEqual(expected.toLowerCase(Locale.ROOT).getBytes(java.nio.charset.StandardCharsets.US_ASCII),hex(actual).getBytes(java.nio.charset.StandardCharsets.US_ASCII));}
    static String hex(byte[] bytes){StringBuilder s=new StringBuilder();for(byte b:bytes)s.append(String.format(Locale.ROOT,"%02x",b&255));return s.toString();}
    static boolean sameSigners(List<String> installed,List<String> downloaded){return !installed.isEmpty()&&new HashSet<>(installed).equals(new HashSet<>(downloaded));}
}
