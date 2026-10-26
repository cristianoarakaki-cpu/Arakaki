package br.com.onda;
import java.security.*;
import java.security.cert.*;
import javax.net.ssl.*;
import java.net.Socket;
/** Process-local software key avoids opaque-key TLS inconsistencies on older Android releases. */
final class ConnectTls {
 private static ConnectCertificate.Identity identity;
 private static synchronized ConnectCertificate.Identity identity()throws Exception{if(identity==null)identity=ConnectCertificate.create();return identity;}
 static SSLContext server()throws Exception{
  ConnectCertificate.Identity value=identity();String alias="onda-local";PrivateKey key=value.key;X509Certificate certificate=value.certificate;
  X509ExtendedKeyManager manager=new X509ExtendedKeyManager(){
   private String match(String type){return "RSA".equals(type)?alias:null;}
   public String[] getClientAliases(String type,java.security.Principal[] issuers){return null;}
   public String chooseClientAlias(String[] type,java.security.Principal[] issuers,Socket socket){return null;}
   public String[] getServerAliases(String type,java.security.Principal[] issuers){return match(type)==null?null:new String[]{alias};}
   public String chooseServerAlias(String type,java.security.Principal[] issuers,Socket socket){return match(type);}
   public String chooseEngineServerAlias(String type,java.security.Principal[] issuers,SSLEngine engine){return match(type);}
   public X509Certificate[] getCertificateChain(String requested){return alias.equals(requested)?new X509Certificate[]{certificate}:null;}
   public PrivateKey getPrivateKey(String requested){return alias.equals(requested)?key:null;}
  };
  SSLContext context=SSLContext.getInstance("TLSv1.2");context.init(new KeyManager[]{manager},null,new SecureRandom());return context;
 }
 static String pin()throws Exception{return ConnectProtocol.hex(MessageDigest.getInstance("SHA-256").digest(identity().certificate.getEncoded()));}
 static SSLContext client(String pin)throws Exception{SSLContext context=SSLContext.getInstance("TLSv1.2");context.init(null,new TrustManager[]{new X509TrustManager(){public X509Certificate[] getAcceptedIssuers(){return new X509Certificate[0];}public void checkClientTrusted(X509Certificate[] c,String a)throws CertificateException{throw new CertificateException();}public void checkServerTrusted(X509Certificate[] c,String a)throws CertificateException{try{if(c==null||c.length==0||!MessageDigest.isEqual(ConnectProtocol.hex(MessageDigest.getInstance("SHA-256").digest(c[0].getEncoded())).getBytes(java.nio.charset.StandardCharsets.US_ASCII),pin.getBytes(java.nio.charset.StandardCharsets.US_ASCII)))throw new CertificateException("O QR não corresponde a este aparelho.");}catch(GeneralSecurityException e){throw new CertificateException(e);}}}},new SecureRandom());return context;}
}
