package br.com.onda;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
/** Selected golden roaring lion. One small shared decode, no network or animation scheduler. */
final class LionBrand {
 private static Bitmap cached;
 static synchronized Bitmap bitmap(Context context){if(cached==null){BitmapFactory.Options options=new BitmapFactory.Options();options.inScaled=false;options.inSampleSize=4;options.inPreferredConfig=Bitmap.Config.ARGB_8888;cached=BitmapFactory.decodeResource(context.getResources(),R.drawable.lion_gold,options);if(cached==null)throw new IllegalStateException("Ícone do leão indisponível");}return cached;}
 static Drawable drawable(Context context){BitmapDrawable drawable=new BitmapDrawable(context.getResources(),bitmap(context));drawable.setFilterBitmap(true);return drawable;}
}
