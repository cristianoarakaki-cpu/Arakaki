package br.com.onda;
import java.io.*;
/** Disk capacity, not an arbitrary media quota. Keep a small reserve for Android. */
final class DownloadStorage {
 static final long RESERVE=32L*1024*1024;
 static boolean fits(long usable,long remaining){return usable>=RESERVE&&remaining>=0&&remaining<=usable-RESERVE;}
 static void check(File directory,long remaining)throws IOException{if(!fits(directory.getUsableSpace(),remaining))throw new IOException("Espaço livre insuficiente no armazenamento temporário do Onda. Libere espaço ou escolha um arquivo menor; arquivos grandes podem exigir espaço para a fonte e a conversão.");}
}
