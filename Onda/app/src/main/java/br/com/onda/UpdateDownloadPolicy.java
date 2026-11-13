package br.com.onda;
import java.io.IOException;
/** APK delivery only; media download sizes are unaffected. */
final class UpdateDownloadPolicy {
 static final long MAX_BYTES=256L*1024*1024;
 static void checkSize(long size)throws IOException{if(size>MAX_BYTES)throw new IOException("O APK excede o tamanho aceito pelo atualizador. Use o link oficial de instalação.");}
 static void checkSpace(long length,long available)throws IOException{checkSize(length);if(length>0&&available>0&&available-length<16L*1024*1024)throw new IOException("Espaço insuficiente para baixar a atualização. Libere armazenamento e tente novamente.");}
}
