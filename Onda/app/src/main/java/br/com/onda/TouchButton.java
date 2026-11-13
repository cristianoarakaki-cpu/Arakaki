package br.com.onda;
import android.content.Context;
import android.view.View;
import android.widget.Button;
/** Button metrics and click semantics stay native; only its drawing scale changes on press. */
// Onda uses platform Activities and a custom renderer, without an AppCompat theme.
@android.annotation.SuppressLint("AppCompatCustomView")
class TouchButton extends Button {
 private boolean motionActive;
 TouchButton(Context context){super(context);}
 @Override public void setPressed(boolean pressed){boolean changed=pressed!=isPressed();super.setPressed(pressed);if(!changed)return;if(!TouchMotion.allowed(this)){stopMotion();return;}animate().cancel();motionActive=true;float target=pressed?.97f:1f;animate().scaleX(target).scaleY(target).setDuration(pressed?TouchMotion.PRESS_MS:TouchMotion.RELEASE_MS).setInterpolator(new android.view.animation.DecelerateInterpolator()).withEndAction(()->motionActive=false).start();}
 final boolean motionRunning(){return motionActive;}
 final void stopMotion(){if(motionActive){animate().cancel();motionActive=false;}if(getScaleX()!=1f)setScaleX(1f);if(getScaleY()!=1f)setScaleY(1f);}
 @Override public void setEnabled(boolean enabled){super.setEnabled(enabled);if(!enabled)stopMotion();}
 @Override protected void onWindowVisibilityChanged(int visibility){super.onWindowVisibilityChanged(visibility);if(visibility!=View.VISIBLE)stopMotion();}
 @Override public void onWindowFocusChanged(boolean focus){super.onWindowFocusChanged(focus);if(!focus)stopMotion();}
 @Override protected void onDetachedFromWindow(){stopMotion();super.onDetachedFromWindow();}
}
