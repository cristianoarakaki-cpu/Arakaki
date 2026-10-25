package br.com.onda;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.*;
import android.view.View;
import android.widget.Button;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
public class HeartButtonTest {
 private Bitmap render(float font,boolean selected){Bitmap[] out=new Bitmap[1];getInstrumentation().runOnMainSync(()->{Context base=getInstrumentation().getTargetContext();Configuration config=new Configuration(base.getResources().getConfiguration());config.fontScale=font;Context c=base.createConfigurationContext(config);Button heart=Ui.favoriteButton(c,v->{});heart.setSelected(selected);heart.setTextColor(selected?Ui.CYAN:Ui.MUTED);int size=Ui.dp(c,48);heart.measure(View.MeasureSpec.makeMeasureSpec(size,View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec(size,View.MeasureSpec.EXACTLY));heart.layout(0,0,size,size);out[0]=Bitmap.createBitmap(size,size,Bitmap.Config.ARGB_8888);heart.draw(new Canvas(out[0]));});return out[0];}
 @Test public void outlineAndFilledHeartKeepTheirShapeAndClearMarginsAtLargeFont(){Context c=getInstrumentation().getTargetContext();for(boolean selected:new boolean[]{false,true}){Bitmap normal=render(1f,selected),large=render(2f,selected);try{assertTrue("Font size must not change the icon",normal.sameAs(large));int color=selected?Ui.CYAN:Ui.MUTED,minX=large.getWidth(),minY=large.getHeight(),maxX=-1,maxY=-1;for(int y=0;y<large.getHeight();y++)for(int x=0;x<large.getWidth();x++)if(large.getPixel(x,y)==color){minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}assertTrue("Heart did not render",maxX>minX&&maxY>minY);int margin=Ui.dp(c,8);assertTrue("Left/top edge clipped",minX>=margin&&minY>=margin);assertTrue("Right/bottom edge clipped",maxX<large.getWidth()-margin&&maxY<large.getHeight()-margin);}finally{normal.recycle();large.recycle();}}}
}
