package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;

public class SoundProfileTest {
 @Test public void settingsAreClampedAndDoNotShareMutableArrays(){int[] values={100,-100,2};SoundProfile p=new SoundProfile(true,values,999);values[0]=0;assertEquals(6,p.gain(0));assertEquals(-6,p.gain(1));assertEquals(2,p.gain(2));assertEquals(0,p.gain(4));assertEquals(100,p.bass);assertEquals(0,new SoundProfile(false,null,-10).bass);assertEquals(6,p.gain(0));assertEquals(-1,p.gain(0,-1).gain(0));}
 @Test public void curveUsesLogFrequencyAndExactAnchors(){SoundProfile p=new SoundProfile(true,new int[]{-6,6,0,3,-3},0);assertEquals(-600,p.millibelsAt(60));assertEquals(600,p.millibelsAt(230));assertEquals(0,p.millibelsAt(Math.sqrt(60*230)));assertEquals(-600,p.millibelsAt(1));assertEquals(-300,p.millibelsAt(30000));assertEquals(300,p.millibelsAt(3600));}
 @Test public void headroomOnlyCompensatesAvailableEffects(){SoundProfile p=SoundProfile.preset(3,true);assertEquals(1,p.headroom(false,false),.00001);assertEquals(Math.pow(10,-4.0/20),p.headroom(true,false),.00001);assertTrue(p.headroom(true,true)<p.headroom(true,false));assertEquals(1,p.enabled(false).headroom(true,true),.00001);for(int i=0;i<SoundProfile.PRESETS.length;i++){SoundProfile preset=SoundProfile.preset(i,true);assertTrue(preset.headroom(true,true)>0);assertTrue(preset.headroom(true,true)<=1);assertEquals(SoundProfile.PRESETS[i],preset.presetName());}}
 @Test public void editingAndResetKeepProfilesIndependent(){SoundProfile original=SoundProfile.preset(0,false);SoundProfile modified=original.enabled(true).gain(2,4).bass(50);assertFalse(original.enabled);assertEquals(0,original.gain(2));assertEquals("Personalizado",modified.presetName());SoundProfile reset=SoundProfile.preset(0,false);assertEquals(1,reset.headroom(true,true),.00001);}
}
