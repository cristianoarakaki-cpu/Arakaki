package br.com.onda;
import java.util.*;
import org.junit.Test;
import static org.junit.Assert.*;
public class RadioDataTest {
 private RadioStation radio(String name,int kbps){return new RadioStation(name,name,"https://radio.example.org/"+name,"Brasil","AAC",kbps,false);}
 @Test public void estimatesPayloadWithoutClaimingZeroData(){assertEquals(14.4,RadioData.megabytesPerHour(32),.00001);assertEquals(28.8,RadioData.megabytesPerHour(64),.00001);assertEquals(57.6,RadioData.megabytesPerHour(128),.00001);assertEquals("Consumo não informado",RadioData.estimate(0));}
 @Test public void economyKeepsAllStationsAndRanksKnownLowRatesFirst(){RadioStation high=radio("high",128),unknown=radio("unknown",0),low=radio("low",32);List<RadioStation> source=Arrays.asList(high,unknown,low),sorted=RadioData.order(source,true);assertEquals(Arrays.asList(low,high,unknown),sorted);assertEquals(Arrays.asList(high,unknown,low),source);assertEquals(source,RadioData.order(source,false));}
}
