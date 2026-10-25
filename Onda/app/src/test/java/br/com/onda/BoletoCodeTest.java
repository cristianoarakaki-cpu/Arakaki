package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class BoletoCodeTest {
 static final String BANK="00190500954014481606906809350314337370000000100",BAR="00193373700000001000500940144816060680935031";
 @Test public void knownBankLineAndBarcodeRoundTrip(){BoletoCode c=BoletoCode.from("00190.50095 40144.816069 06809.350314 3 37370000000100");assertNotNull(c);assertEquals(BANK,c.line);assertEquals(BAR,c.barcode);assertEquals(BANK,BoletoCode.from(BAR).line);assertFalse(c.collection);}
 @Test public void collectionSupportsBothCheckDigitMethods(){String[][] cases={{"84660000001234512345678901234567890123456789","846600000018234512345674890123456786901234567898"},{"84860000001234512345678901234567890123456789","848600000015234512345675890123456785901234567894"}};for(String[] pair:cases){BoletoCode c=BoletoCode.from(pair[1]);assertNotNull(c);assertTrue(c.collection);assertEquals(pair[0],c.barcode);assertEquals(pair[1],BoletoCode.from(pair[0]).line);}}
 @Test public void badFieldAndGeneralDigitsNeverCopy(){for(int pos:new int[]{9,20,31,32}){char[] changed=BANK.toCharArray();changed[pos]=(char)('0'+(changed[pos]-'0'+1)%10);assertNull(BoletoCode.from(new String(changed)));}assertNull(BoletoCode.from("12345"));assertNull(BoletoCode.from(null));assertNull(BoletoCode.from("1".repeat(201)));}
 @Test public void formattedLinesAcrossParagraphsDeduplicateAndKeepDifferentCodes(){String text="Referência 12\n00190.50095 40144.816069\n06809.350314 3 37370000000100\nDuplicado "+BANK+"\nOutra conta: 846600000018 234512345674 890123456786 901234567898";assertEquals(2,BoletoCode.find(text).size());assertEquals(BANK,BoletoCode.find(text).get(1).line);assertTrue(BoletoCode.find("Apenas números 123456789 e 1234,56").isEmpty());}
}
