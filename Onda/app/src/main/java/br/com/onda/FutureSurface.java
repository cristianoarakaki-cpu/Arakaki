package br.com.onda;
import android.graphics.*;
import android.graphics.drawable.Drawable;
/** Static bevels; state changes only on touch. No elevation animation, blur or render loop. */
final class FutureSurface extends Drawable {
 private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final Path face=new Path();private final RectF rect=new RectF();
 private final AppearancePalette palette;private final int fill,edge;private final float radius;private Shader shader;private boolean pressed;private int opacity=255;
 FutureSurface(AppearancePalette palette,int fill,int edge,float radius){this.palette=palette;this.fill=fill;this.edge=edge;this.radius=radius;}
 @Override protected void onBoundsChange(Rect b){rect.set(b.left+1,b.top+1,b.right-1,b.bottom-3);face.reset();float r=Math.min(radius,Math.min(rect.width(),rect.height())/2);boolean angular=palette.variant==2||palette.variant==4||palette.variant==7||palette.variant==9;if(angular){float cut=Math.max(3,r);face.moveTo(rect.left+cut,rect.top);face.lineTo(rect.right-cut,rect.top);face.lineTo(rect.right,rect.top+cut);face.lineTo(rect.right,rect.bottom-cut);face.lineTo(rect.right-cut,rect.bottom);face.lineTo(rect.left+cut,rect.bottom);face.lineTo(rect.left,rect.bottom-cut);face.lineTo(rect.left,rect.top+cut);face.close();}else face.addRoundRect(rect,r,r,Path.Direction.CW);shader=new LinearGradient(rect.left,rect.top,rect.right,rect.bottom,new int[]{AppearancePalette.blend(fill,0xFFFFFFFF,.04f),fill,AppearancePalette.blend(fill,palette.bg,.36f)},new float[]{0,.42f,1},Shader.TileMode.CLAMP);}
 @Override public void draw(Canvas c){if(rect.isEmpty())return;c.save();paint.setAlpha(opacity);paint.setStyle(Paint.Style.FILL);paint.setShader(null);paint.setColor(palette.bg);c.translate(0,2);c.drawPath(face,paint);c.translate(0,pressed?-1:-2);paint.setShader(shader);c.drawPath(face,paint);paint.setShader(null);paint.setColor(edge);paint.setStrokeWidth(1.2f);paint.setStyle(Paint.Style.STROKE);c.drawPath(face,paint);c.save();c.clipPath(face);paint.setColor(AppearancePalette.blend(edge,0xFFFFFFFF,.28f));c.drawLine(rect.left+radius,rect.top+1,rect.right-radius,rect.top+1,paint);paint.setColor(AppearancePalette.blend(fill,palette.bg,.55f));c.drawLine(rect.left,rect.bottom-1,rect.right,rect.bottom-1,paint);c.restore();paint.setStyle(Paint.Style.FILL);c.restore();}
 @Override public boolean isStateful(){return true;}
 @Override protected boolean onStateChange(int[] state){boolean next=false;for(int s:state)if(s==android.R.attr.state_pressed)next=true;if(next==pressed)return false;pressed=next;invalidateSelf();return true;}
 @Override public void setAlpha(int alpha){opacity=alpha;invalidateSelf();}
 @Override public void setColorFilter(ColorFilter filter){paint.setColorFilter(filter);invalidateSelf();}
 @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
}
