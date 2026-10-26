package br.com.onda;
import java.io.*;
import java.math.BigInteger;
import java.security.*;
import java.security.cert.*;
import java.text.SimpleDateFormat;
import java.util.*;
import javax.security.auth.x500.X500Principal;
/** Minimal standard DER certificate for a process-local TLS identity. No private key is written. */
final class ConnectCertificate {
 static final class Identity {final PrivateKey key;final X509Certificate certificate;Identity(PrivateKey key,X509Certificate certificate){this.key=key;this.certificate=certificate;}}
 static Identity create()throws Exception{
  KeyPairGenerator generator=KeyPairGenerator.getInstance("RSA");generator.initialize(2048,new SecureRandom());KeyPair pair=generator.generateKeyPair();
  byte[] algorithm=der(0x30,new byte[]{0x06,0x09,0x2a,(byte)0x86,0x48,(byte)0x86,(byte)0xf7,0x0d,0x01,0x01,0x0b,0x05,0x00});
  byte[] name=new X500Principal("CN=Onda Conecta").getEncoded();long now=System.currentTimeMillis();byte[] validity=der(0x30,join(time(new Date(now-86400000L)),time(new Date(now+365L*86400000))));
  byte[] serial=new BigInteger(120,new SecureRandom()).add(BigInteger.ONE).toByteArray();
  byte[] tbs=der(0x30,join(der(0xa0,der(0x02,new byte[]{2})),der(0x02,serial),algorithm,name,validity,name,pair.getPublic().getEncoded()));
  Signature signature=Signature.getInstance("SHA256withRSA");signature.initSign(pair.getPrivate());signature.update(tbs);byte[] certificate=der(0x30,join(tbs,algorithm,der(0x03,join(new byte[]{0},signature.sign()))));
  X509Certificate parsed=(X509Certificate)CertificateFactory.getInstance("X.509").generateCertificate(new ByteArrayInputStream(certificate));parsed.verify(pair.getPublic());return new Identity(pair.getPrivate(),parsed);
 }
 private static byte[] time(Date date){SimpleDateFormat format=new SimpleDateFormat("yyyyMMddHHmmss'Z'",Locale.ROOT);format.setTimeZone(TimeZone.getTimeZone("UTC"));return der(0x18,format.format(date).getBytes(java.nio.charset.StandardCharsets.US_ASCII));}
 private static byte[] join(byte[]... arrays){ByteArrayOutputStream result=new ByteArrayOutputStream();for(byte[] array:arrays)result.write(array,0,array.length);return result.toByteArray();}
 private static byte[] der(int tag,byte[] bytes){ByteArrayOutputStream out=new ByteArrayOutputStream();out.write(tag);if(bytes.length<128)out.write(bytes.length);else{int count=0,length=bytes.length;while(length>0){count++;length>>>=8;}out.write(0x80|count);for(int i=count-1;i>=0;i--)out.write((bytes.length>>>(i*8))&255);}out.write(bytes,0,bytes.length);return out.toByteArray();}
}
