package br.com.onda;
import android.app.*;
import android.content.*;
import android.net.Uri;
import android.widget.TextView;
@androidx.media3.common.util.UnstableApi
final class VideoShareFlow {
 static AlertDialog show(Activity activity,String raw){String source=VideoShare.source(raw);if(source.isEmpty())return null;if(!VideoShare.canFile(source)){ShareMedia.share(activity,Uri.parse(source),"text/plain","Link do Onda");return null;}TextView help=Ui.text(activity,"O vídeo precisa estar salvo para compartilhar o arquivo. O Onda reutiliza um MP4 disponível ou permite escolher um formato para baixar. Depois, toque em Compartilhar vídeo pronto. A disponibilidade depende da plataforma.",14,Ui.MUTED);int pad=Ui.dp(activity,16);help.setPadding(pad,Ui.dp(activity,8),pad,Ui.dp(activity,8));AlertDialog dialog=new AlertDialog.Builder(activity).setTitle("Compartilhar vídeo").setView(help).setItems(new String[]{"Vídeo completo (MP4)","Somente o link"},(d,index)->{if(index==0)activity.startActivity(new Intent(activity,DownloadsActivity.class).putExtra(VideoShare.EXTRA,source).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT|Intent.FLAG_ACTIVITY_SINGLE_TOP));else ShareMedia.share(activity,Uri.parse(source),"text/plain","Link do vídeo");}).setNegativeButton("Cancelar",null).create();dialog.show();return dialog;}
}
