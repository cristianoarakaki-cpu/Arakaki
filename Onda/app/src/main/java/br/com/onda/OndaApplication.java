package br.com.onda;
import android.app.*;
import android.os.Bundle;
import java.util.*;
/** Repaint existing views; choosing an interface never recreates players or activities. */
public class OndaApplication extends Application implements Application.ActivityLifecycleCallbacks {
 private final WeakHashMap<Activity,String> activities=new WeakHashMap<>();
 @Override public void onCreate(){super.onCreate();Ui.install(AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original")));registerActivityLifecycleCallbacks(this);}
 void refreshAll(){for(Activity a:new ArrayList<>(activities.keySet()))if(a!=null&&!a.isDestroyed())refresh(a);}
 private void refresh(Activity a){AppearancePalette p=AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original"));if(Ui.palette!=p)Ui.install(p);AppearanceStyles.window(a,p);Ui.restyle(a.getWindow().getDecorView());activities.put(a,p.id);}
 @Override public void onActivityCreated(Activity a,Bundle state){refresh(a);}
 @Override public void onActivityResumed(Activity a){String id=AppearancePalette.find(getSharedPreferences("appearance",0).getString("theme","original")).id;if(!id.equals(activities.get(a))||!Ui.palette.id.equals(id))refresh(a);}
 @Override public void onActivityDestroyed(Activity a){activities.remove(a);}
 @Override public void onActivityStarted(Activity a){}@Override public void onActivityPaused(Activity a){}@Override public void onActivityStopped(Activity a){}@Override public void onActivitySaveInstanceState(Activity a,Bundle state){}
}
