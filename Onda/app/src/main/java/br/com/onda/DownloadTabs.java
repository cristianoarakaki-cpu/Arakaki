package br.com.onda;
import android.app.Activity;
import android.content.Intent;
import android.widget.*;
final class DownloadTabs {
 static void add(Activity activity,LinearLayout root,boolean youtube){LinearLayout tabs=new LinearLayout(activity);for(int i=0;i<2;i++){final boolean target=i==1;Button button=Ui.button(activity,target?"YouTube":"Links",v->{if(target==youtube)return;activity.startActivity(new Intent(activity,target?YouTubeActivity.class:DownloadsActivity.class).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT|Intent.FLAG_ACTIVITY_SINGLE_TOP));});button.setContentDescription(target?"Aba YouTube nos downloads":"Aba de links e formatos");button.setSelected(target==youtube);if(target==youtube)Ui.primary(button);else Ui.ghost(button);LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,-2,1);p.setMargins(Ui.dp(activity,2),Ui.dp(activity,6),Ui.dp(activity,2),Ui.dp(activity,6));tabs.addView(button,p);}root.addView(tabs,new LinearLayout.LayoutParams(-1,-2));}
}
