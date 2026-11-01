package br.com.onda;
import android.app.*;
import android.os.Bundle;
import java.util.*;
/** Repaint existing views; choosing an interface never recreates players or activities. */
public class OndaApplication extends Application implements Application.ActivityLifecycleCallbacks {
 private final WeakHashMap<Activity,String> activities=new WeakHashMap<>();
 private final Set<Activity> started=Collections.newSetFromMap(new WeakHashMap<>());private volatile boolean foreground,interactive;
 static boolean userVisible(android.content.Context c){android.content.Context app=c.getApplicationContext();return app instanceof OndaApplication&&((OndaApplication)app).foreground&&((OndaApplication)app).interactive;}
 @Override public void onCreate(){super.onCreate();Ui.install(AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original")));registerActivityLifecycleCallbacks(this);android.os.PowerManager power=(android.os.PowerManager)getSystemService(POWER_SERVICE);interactive=power!=null&&power.isInteractive();android.content.IntentFilter screen=new android.content.IntentFilter();screen.addAction(android.content.Intent.ACTION_SCREEN_ON);screen.addAction(android.content.Intent.ACTION_SCREEN_OFF);androidx.core.content.ContextCompat.registerReceiver(this,new android.content.BroadcastReceiver(){public void onReceive(android.content.Context c,android.content.Intent i){interactive=android.content.Intent.ACTION_SCREEN_ON.equals(i.getAction());}},screen,androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED);}
 void refreshAll(){for(Activity a:new ArrayList<>(activities.keySet()))if(a!=null&&!a.isDestroyed())refresh(a);}
 private void refresh(Activity a){AppearancePalette p=AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original"));if(Ui.palette!=p)Ui.install(p);AppearanceStyles.window(a,p);Ui.restyle(a.getWindow().getDecorView());activities.put(a,p.id);}
 @Override public void onActivityCreated(Activity a,Bundle state){refresh(a);}
 @Override public void onActivityResumed(Activity a){String id=AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original")).id;if(!id.equals(activities.get(a))||!Ui.palette.id.equals(id))refresh(a);}
 @Override public void onActivityDestroyed(Activity a){activities.remove(a);started.remove(a);foreground=!started.isEmpty();}
 @Override public void onActivityStarted(Activity a){started.add(a);foreground=true;}@Override public void onActivityPaused(Activity a){}@Override public void onActivityStopped(Activity a){started.remove(a);foreground=!started.isEmpty();}@Override public void onActivitySaveInstanceState(Activity a,Bundle state){}
}
