package br.com.onda;
import android.app.Activity;
import android.content.Intent;
import android.widget.*;
@androidx.media3.common.util.UnstableApi
final class DownloadTabs {
 static void add(Activity activity,LinearLayout root,boolean youtube){add(activity,root,youtube?1:0);}
 static void add(Activity activity,LinearLayout root,int selected){LinearLayout tabs=new LinearLayout(activity);String[] labels={"Links","YouTube","Sites"},descriptions={"Aba de links e formatos","Aba YouTube nos downloads","Abrir TikTok e outras plataformas"};Class<?>[] pages={DownloadsActivity.class,YouTubeActivity.class,PlatformBrowserActivity.class};for(int i=0;i<pages.length;i++){final int target=i;Button button=Ui.button(activity,labels[i],v->{if(target==selected)return;activity.startActivity(new Intent(activity,pages[target]).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT|Intent.FLAG_ACTIVITY_SINGLE_TOP));});button.setContentDescription(descriptions[i]);button.setSelected(target==selected);if(target==selected)Ui.primary(button);else Ui.ghost(button);LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,-2,1);p.setMargins(Ui.dp(activity,2),Ui.dp(activity,6),Ui.dp(activity,2),Ui.dp(activity,6));tabs.addView(button,p);}root.addView(tabs,new LinearLayout.LayoutParams(-1,-2));}
}
