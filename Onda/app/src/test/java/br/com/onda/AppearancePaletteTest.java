package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class AppearancePaletteTest {
 @Test public void allInterfacesKeepReadableTextAndAccent(){java.util.Set<String> ids=new java.util.HashSet<>();assertEquals(5,AppearancePalette.ALL.length);for(AppearancePalette p:AppearancePalette.ALL){assertTrue(ids.add(p.id));for(int background:new int[]{p.bg,p.end,p.surface,p.raised,AppearancePalette.blend(p.surface,p.accent,.13f)}){assertTrue(p.name+" body contrast",AppearancePalette.contrast(AppearancePalette.TEXT,background)>=4.5);assertTrue(p.name+" secondary contrast",AppearancePalette.contrast(AppearancePalette.MUTED,background)>=4.5);}assertTrue(p.name+" accent",AppearancePalette.contrast(p.accent,p.surface)>=4.5);assertTrue(p.name+" primary button",AppearancePalette.contrast(p.bg,p.accent)>=4.5);}}
 @Test public void invalidOrMissingChoiceFallsBackToOriginal(){assertSame(AppearancePalette.ALL[0],AppearancePalette.find(null));assertSame(AppearancePalette.ALL[0],AppearancePalette.find("missing"));assertSame(AppearancePalette.ALL[1],AppearancePalette.find("nebula"));}
}
