package br.com.onda;
import androidx.media3.common.*;
import java.util.*;
@androidx.media3.common.util.UnstableApi
final class LibraryOrder {
 static final String[] NAMES={"Título A–Z","Artista A–Z","Álbum A–Z","Menor duração","Maior duração","Mais recentes"};
 static String value(CharSequence s){return s==null?"":SearchText.normalize(s.toString());}
 static Comparator<MediaItem> comparator(int order){Comparator<MediaItem> title=Comparator.comparing((MediaItem m)->value(m.mediaMetadata.title)).thenComparing(m->m.mediaId);switch(order){case 1:return Comparator.comparing((MediaItem m)->value(m.mediaMetadata.artist)).thenComparing(title);case 2:return Comparator.comparing((MediaItem m)->value(m.mediaMetadata.albumTitle)).thenComparing(title);case 3:case 4:return Comparator.comparingLong((MediaItem m)->{long n=LibraryStore.number(m,"durationMs");return n<=0?Long.MAX_VALUE:order==4?-n:n;}).thenComparing(title);case 5:return Comparator.comparingLong((MediaItem m)->-LibraryStore.number(m,"added")).thenComparing(title);default:return title;}}
}
