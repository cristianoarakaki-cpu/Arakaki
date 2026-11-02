package br.com.onda;
import android.graphics.*;
import android.graphics.drawable.Drawable;
/** Ten native static emblems. Drawn at 100 logical units; no bitmaps or network assets. */
final class FutureArt extends Drawable {
 private final AppearancePalette palette;private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final Path path=new Path();private final FutureSurface tile;private final Shader light;private int opacity=255;
 FutureArt(AppearancePalette p){palette=p;tile=new FutureSurface(p,p.raised,p.border,22*p.corners);tile.setBounds(0,0,100,100);light=new LinearGradient(20,20,78,78,new int[]{0xFFFFFFFF,p.accent,p.secondary},new float[]{0,.3f,1},Shader.TileMode.CLAMP);}
 private void polygon(Canvas c,int points,float outer,float inner,float rotation){path.reset();for(int i=0;i<points;i++){double a=rotation+i*2*Math.PI/points;float r=i%2==1?inner:outer,x=50+(float)Math.cos(a)*r,y=49+(float)Math.sin(a)*r;if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}path.close();solid(c);}
 private void solid(Canvas c){paint.setStyle(Paint.Style.FILL);paint.setShader(null);paint.setColor(AppearancePalette.blend(palette.accent,palette.bg,.65f));c.save();c.translate(0,4);c.drawPath(path,paint);c.restore();paint.setShader(light);c.drawPath(path,paint);paint.setShader(null);paint.setStyle(Paint.Style.STROKE);paint.setColor(AppearancePalette.blend(palette.accent,0xFFFFFFFF,.45f));paint.setStrokeWidth(1.3f);c.drawPath(path,paint);paint.setStyle(Paint.Style.FILL);}
 @Override public void draw(Canvas c){Rect b=getBounds();if(b.isEmpty())return;c.save();c.translate(b.left,b.top);c.scale(b.width()/100f,b.height()/100f);tile.draw(c);paint.setAlpha(opacity);paint.setStrokeCap(Paint.Cap.ROUND);paint.setShader(light);paint.setStyle(Paint.Style.FILL);
  switch(palette.variant){
   case 1:c.drawCircle(50,48,27,paint);paint.setShader(null);paint.setColor(palette.raised);c.drawCircle(58,43,18,paint);break;
   case 2:polygon(c,6,30,30,-Math.PI/2);paint.setColor(palette.bg);paint.setStrokeWidth(2);c.drawLine(50,20,50,76,paint);c.drawLine(25,34,50,49,paint);c.drawLine(75,34,50,49,paint);break;
   case 3:polygon(c,3,31,31,-Math.PI/2);paint.setColor(palette.bg);paint.setStrokeWidth(2);c.drawLine(50,18,50,77,paint);c.drawLine(50,49,23,65,paint);break;
   case 4:polygon(c,4,31,25,-Math.PI/2);paint.setColor(palette.raised);path.reset();path.moveTo(50,24);path.lineTo(50,68);path.lineTo(30,49);path.close();c.drawPath(path,paint);break;
   case 5:path.reset();path.moveTo(50,20);path.lineTo(75,30);path.lineTo(72,57);path.quadTo(66,70,50,79);path.quadTo(34,70,28,57);path.lineTo(25,30);path.close();solid(c);paint.setColor(palette.raised);c.drawRoundRect(46,32,54,64,4,4,paint);break;
   case 6:polygon(c,6,29,29,0);paint.setColor(palette.raised);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(4);c.drawCircle(50,49,14,paint);break;
   case 7:polygon(c,10,31,14,-Math.PI/2);break;
   case 8:c.drawCircle(50,49,18,paint);paint.setShader(null);paint.setColor(palette.secondary);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(3);c.save();c.rotate(-28,50,49);c.drawOval(16,37,84,61,paint);c.restore();break;
   case 9:path.reset();path.moveTo(38,24);path.lineTo(63,18);path.lineTo(68,74);path.lineTo(38,80);path.close();solid(c);paint.setColor(palette.raised);c.drawRect(42,35,48,65,paint);break;
   default:paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(9);c.drawCircle(50,49,25,paint);paint.setShader(null);paint.setColor(palette.accent);c.drawCircle(50,49,13,paint);break;
  }
  paint.setShader(null);paint.setStyle(Paint.Style.FILL);paint.setColor(0x88FFFFFF);c.drawRoundRect(17,12,35,14,1,1,paint);c.restore();
 }
 @Override public void setAlpha(int a){opacity=a;tile.setAlpha(a);invalidateSelf();}
 @Override public void setColorFilter(ColorFilter f){paint.setColorFilter(f);tile.setColorFilter(f);invalidateSelf();}
 @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
}
