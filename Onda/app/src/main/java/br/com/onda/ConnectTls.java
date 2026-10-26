package br.com.onda;
import android.security.keystore.*;
import java.security.*;
import java.security.cert.*;
import java.math.BigInteger;
import java.util.Date;
import javax.net.ssl.*;
import javax.security.auth.x500.X500Principal;
final class ConnectTls {
 private static final String ALIAS="onda_conecta_tls_v1";
 static synchronized SSLContext server()throws Exception{
  KeyStore store=KeyStore.getInstance("AndroidKeyStore");store.load(null);if(!store.containsAlias(ALIAS)){KeyPairGenerator gen=KeyPairGenerator.getInstance("RSA","AndroidKeyStore");gen.initialize(new KeyGenParameterSpec.Builder(ALIAS,KeyProperties.PURPOSE_SIGN|KeyProperties.PURPOSE_VERIFY|KeyProperties.PURPOSE_DECRYPT|KeyProperties.PURPOSE_ENCRYPT).setKeySize(2048).setDigests(KeyProperties.DIGEST_SHA256,KeyProperties.DIGEST_SHA512).setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1,KeyProperties.SIGNATURE_PADDING_RSA_PSS).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1,KeyProperties.ENCRYPTION_PADDING_RSA_OAEP).setCertificateSubject(new X500Principal("CN=Onda Conecta")).setCertificateSerialNumber(BigInteger.ONE).setCertificateNotBefore(new Date(System.currentTimeMillis()-86400000)).setCertificateNotAfter(new Date(System.currentTimeMillis()+10L*365*86400000)).build());gen.generateKeyPair();}
  KeyManagerFactory keys=KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());keys.init(store,null);SSLContext context=SSLContext.getInstance("TLS");context.init(keys.getKeyManagers(),null,new SecureRandom());return context;
 }
 static String pin()throws Exception{KeyStore store=KeyStore.getInstance("AndroidKeyStore");store.load(null);return ConnectProtocol.hex(MessageDigest.getInstance("SHA-256").digest(store.getCertificate(ALIAS).getEncoded()));}
 static SSLContext client(String pin)throws Exception{SSLContext context=SSLContext.getInstance("TLS");context.init(null,new TrustManager[]{new X509TrustManager(){public X509Certificate[] getAcceptedIssuers(){return new X509Certificate[0];}public void checkClientTrusted(X509Certificate[] c,String a)throws CertificateException{throw new CertificateException();}public void checkServerTrusted(X509Certificate[] c,String a)throws CertificateException{try{if(c==null||c.length==0||!MessageDigest.isEqual(ConnectProtocol.hex(MessageDigest.getInstance("SHA-256").digest(c[0].getEncoded())).getBytes(java.nio.charset.StandardCharsets.US_ASCII),pin.getBytes(java.nio.charset.StandardCharsets.US_ASCII)))throw new CertificateException("O QR não corresponde a este aparelho.");}catch(GeneralSecurityException e){throw new CertificateException(e);}}}},new SecureRandom());return context;}
}
