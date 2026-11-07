package br.com.onda;
/** Finite touch feedback. No idle timers, repeat mode, services or permanent layers. */
final class TouchMotion {
 static final String KEY="touch_motion";
 static final long PRESS_MS=85,RELEASE_MS=130;
 static boolean allowed(boolean preference,boolean saving,boolean systemAnimations,boolean visible,boolean enabled){return preference&&!saving&&systemAnimations&&visible&&enabled;}
 static boolean allowed(android.view.View view){android.content.Context c=view.getContext();android.os.PowerManager power=(android.os.PowerManager)c.getSystemService(android.content.Context.POWER_SERVICE);return allowed(c.getSharedPreferences("appearance",0).getBoolean(KEY,true),power!=null&&power.isPowerSaveMode(),android.animation.ValueAnimator.areAnimatorsEnabled(),view.isAttachedToWindow()&&view.isShown()&&view.getWindowVisibility()==android.view.View.VISIBLE&&view.hasWindowFocus(),view.isEnabled());}
 static void stopTree(android.view.View view){if(view instanceof TouchButton)((TouchButton)view).stopMotion();if(view instanceof android.view.ViewGroup){android.view.ViewGroup g=(android.view.ViewGroup)view;for(int i=0;i<g.getChildCount();i++)stopTree(g.getChildAt(i));}}
}
