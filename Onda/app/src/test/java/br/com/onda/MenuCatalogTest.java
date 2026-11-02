package br.com.onda;
import org.junit.Test;import static org.junit.Assert.*;
public class MenuCatalogTest {
 @Test public void audioVisualAndOnlineActionsAreEasyToFind(){assertEquals(4,MenuCatalog.group("Estúdio de som"));assertEquals(4,MenuCatalog.group("Fones e Bluetooth"));assertEquals(5,MenuCatalog.group("Aparências"));assertEquals(2,MenuCatalog.group("IPTV"));assertEquals(2,MenuCatalog.group("Rádios online"));assertEquals(1,MenuCatalog.group("Playlists"));assertEquals(3,MenuCatalog.group("Repetir trecho A–B do vídeo"));assertEquals(6,MenuCatalog.group("Leitor de PDF"));}
 @Test public void searchIgnoresAccentsAndCombinesWithCategory(){assertTrue(MenuCatalog.matches("Estúdio de som","Estúdio de som","ESTUDIO",4));assertFalse(MenuCatalog.matches("Estúdio de som","Estúdio de som","estudio",2));assertTrue(MenuCatalog.matches("Meu espaço","Continuar e coleções","colecoes",0));assertFalse(MenuCatalog.matches("Meu espaço","Continuar e coleções","download",0));}
}
