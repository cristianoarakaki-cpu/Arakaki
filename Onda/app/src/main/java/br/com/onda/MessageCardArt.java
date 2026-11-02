package br.com.onda;
import android.graphics.*;import android.text.*;
/** Static Canvas artwork, rendered only for previews and explicit sharing. */
final class MessageCardArt {
 static Bitmap draw(String title,String message,int style,int width){int height=width*5/4;Bitmap bitmap=Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888);Canvas c=new Canvas(bitmap);c.scale(width/1080f,height/1350f);int[][] colors={{0xff071126,0xff294975},{0xfff6c990,0xffed816d},{0xff143f37,0xff528d69},{0xff172e48,0xff64558c},{0xff442347,0xffc56e69},{0xff171e2c,0xff485064}};int[] palette=colors[Math.floorMod(style,colors.length)];Paint p=new Paint(3);p.setShader(new LinearGradient(0,0,1080,1350,palette,null,Shader.TileMode.CLAMP));c.drawRect(0,0,1080,1350,p);p.setShader(null);
  p.setColor(0x20ffffff);c.drawCircle(1080,80,430,p);c.drawCircle(-80,1260,420,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(0x55ffffff);c.drawRoundRect(42,42,1038,1308,42,42,p);p.setStyle(Paint.Style.FILL);
  if(style==0||style==3){p.setColor(0xddfff1cb);c.drawCircle(825,220,76,p);p.setColor(palette[0]);c.drawCircle(850,196,69,p);p.setColor(0x99ffffff);for(int i=0;i<32;i++){float x=90+(i*173%900),y=90+(i*97%300);c.drawCircle(x,y,i%3==0?4:2,p);}}
  else if(style==1||style==4){p.setColor(0x88fff2be);c.drawCircle(810,238,102,p);p.setColor(0x33432643);Path hill=new Path();hill.moveTo(0,1160);hill.cubicTo(350,910,650,1190,1080,1010);hill.lineTo(1080,1350);hill.lineTo(0,1350);c.drawPath(hill,p);}
  else if(style==2){for(int i=0;i<3;i++){float x=140+i*370,y=1175+(i%2)*32;p.setColor(0x88eac693);for(int petal=0;petal<6;petal++){double a=petal*Math.PI/3;c.drawCircle(x+(float)Math.cos(a)*26,y+(float)Math.sin(a)*26,23,p);}p.setColor(0xffe9bf73);c.drawCircle(x,y,15,p);}}
  TextPaint text=new TextPaint(3);text.setColor(style==1?0xff46263b:Color.WHITE);text.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));text.setTextSize(72);StaticLayout heading=layout(title,text,870);int bodyTop=430+heading.getHeight()+34;TextPaint body=new TextPaint(3);body.setColor(style==1?0xff46263b:0xfff7f7f5);body.setTypeface(Typeface.create("sans-serif",Typeface.NORMAL));StaticLayout copy=null;for(int size=50;size>=26;size-=2){body.setTextSize(size);copy=layout(message,body,850);if(copy.getHeight()<=1120-bodyTop)break;}
  c.save();c.translate(105,430);heading.draw(c);c.restore();c.save();c.translate(115,bodyTop);copy.draw(c);c.restore();return bitmap;
 }
 private static StaticLayout layout(String s,TextPaint p,int width){return StaticLayout.Builder.obtain(s==null?"":s,0,s==null?0:s.length(),p,width).setAlignment(Layout.Alignment.ALIGN_CENTER).setIncludePad(false).setLineSpacing(10,1.05f).build();}
}
