package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class ConnectCertificateTest {
 @Test public void standardCertificateHasValidSignatureAndMatchingKey()throws Exception{ConnectCertificate.Identity identity=ConnectCertificate.create();identity.certificate.checkValidity();identity.certificate.verify(identity.certificate.getPublicKey());java.security.Signature signature=java.security.Signature.getInstance("SHA256withRSA");byte[] challenge="Onda TLS".getBytes(java.nio.charset.StandardCharsets.UTF_8);signature.initSign(identity.key);signature.update(challenge);byte[] proof=signature.sign();signature.initVerify(identity.certificate.getPublicKey());signature.update(challenge);assertTrue(signature.verify(proof));assertEquals(2048,((java.security.interfaces.RSAPublicKey)identity.certificate.getPublicKey()).getModulus().bitLength());}
 @Test public void newIdentitiesHaveDifferentFingerprints()throws Exception{ConnectCertificate.Identity first=ConnectCertificate.create(),second=ConnectCertificate.create();assertFalse(java.util.Arrays.equals(java.security.MessageDigest.getInstance("SHA-256").digest(first.certificate.getEncoded()),java.security.MessageDigest.getInstance("SHA-256").digest(second.certificate.getEncoded())));}
}
