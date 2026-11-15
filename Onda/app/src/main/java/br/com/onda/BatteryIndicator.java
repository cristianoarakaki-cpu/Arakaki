package br.com.onda;

import android.app.*;
import android.content.*;
import android.os.BatteryManager;
import android.util.TypedValue;
import android.view.Gravity;
import android.widget.*;
import androidx.core.content.ContextCompat;

/** Visible-screen only: system battery broadcasts, no timer, wake lock or service. */
final class BatteryIndicator {
    private final Activity activity;
    final TextView badge;
    private AlertDialog dialog;
    private TextView large, state;
    private int percent=-1, status=-1;
    private boolean listening;
    private final BroadcastReceiver receiver=new BroadcastReceiver(){
        @Override public void onReceive(Context context,Intent intent){accept(intent);}
    };
    BatteryIndicator(Activity activity){
        this.activity=activity;
        badge=Ui.text(activity,"—%",27,Ui.CYAN);
        Ui.bold(badge);badge.setSingleLine(true);badge.setTag("onda-battery");
        badge.setMinHeight(Ui.dp(activity,28));badge.setMaxLines(1);badge.setGravity(Gravity.CENTER_VERTICAL);
        badge.setOnClickListener(v->show());
        badge.setContentDescription("Bateria do celular. Toque para ampliar");
    }
    void start(){
        if(listening)return;
        Intent current=ContextCompat.registerReceiver(activity,receiver,new IntentFilter(Intent.ACTION_BATTERY_CHANGED),ContextCompat.RECEIVER_NOT_EXPORTED);
        listening=true;accept(current);
    }
    void stop(){
        if(listening){activity.unregisterReceiver(receiver);listening=false;}
        if(dialog!=null)dialog.dismiss();dialog=null;large=null;state=null;
    }
    boolean isListening(){return listening;}
    void accept(Intent intent){
        if(intent==null||!Intent.ACTION_BATTERY_CHANGED.equals(intent.getAction()))return;
        int level=intent.getIntExtra(BatteryManager.EXTRA_LEVEL,-1),scale=intent.getIntExtra(BatteryManager.EXTRA_SCALE,-1);
        int next=level>=0&&scale>0?(int)Math.min(100,Math.max(0,Math.round(level*100.0/scale))):-1;
        int nextStatus=intent.getIntExtra(BatteryManager.EXTRA_STATUS,BatteryManager.BATTERY_STATUS_UNKNOWN);
        if(next==percent&&nextStatus==status)return;
        percent=next;status=nextStatus;render();
    }
    private boolean charging(){return status==BatteryManager.BATTERY_STATUS_CHARGING;}
    private String value(){return percent<0?"—%":percent+"%";}
    private String description(){return status==BatteryManager.BATTERY_STATUS_FULL?"Carga completa":charging()?"Carregando":status==BatteryManager.BATTERY_STATUS_DISCHARGING||status==BatteryManager.BATTERY_STATUS_NOT_CHARGING?"Na bateria":"Estado da bateria indisponível";}
    private void render(){
        badge.setText(value());
        badge.setContentDescription("Bateria do celular: "+value()+". "+description()+". Toque para ampliar");
        if(large!=null)large.setText(value());if(state!=null)state.setText(description());
    }
    private void show(){
        if(dialog!=null&&dialog.isShowing())return;
        LinearLayout body=new LinearLayout(activity);body.setOrientation(LinearLayout.VERTICAL);body.setPadding(Ui.dp(activity,20),Ui.dp(activity,12),Ui.dp(activity,20),Ui.dp(activity,12));
        large=Ui.text(activity,value(),72,Ui.CYAN);Ui.bold(large);large.setGravity(Gravity.CENTER);large.setTag("onda-battery-large");large.setAutoSizeTextTypeUniformWithConfiguration(36,72,2,TypedValue.COMPLEX_UNIT_SP);
        body.addView(large,new LinearLayout.LayoutParams(-1,Ui.dp(activity,140)));
        state=Ui.text(activity,description(),18,Ui.TEXT);state.setGravity(Gravity.CENTER);body.addView(state,new LinearLayout.LayoutParams(-1,-2));
        dialog=new AlertDialog.Builder(activity).setTitle("Bateria do celular").setView(body).setPositiveButton("Fechar",null).create();
        dialog.setOnDismissListener(d->{dialog=null;large=null;state=null;});dialog.show();
    }
}
