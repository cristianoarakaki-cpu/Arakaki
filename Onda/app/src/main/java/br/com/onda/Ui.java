package br.com.onda;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.*;
import android.graphics.drawable.*;
import android.text.TextUtils;
import android.view.*;
import android.widget.*;

/** Static native artwork and shared styling; no animation loop or image downloads. */
final class Ui {
    static final int BG=Color.rgb(8,12,23), SURFACE=Color.rgb(17,26,43), RAISED=Color.rgb(23,35,56);
    static final int BORDER=Color.rgb(39,55,79), TEXT=Color.rgb(242,246,255), MUTED=Color.rgb(153,173,199);
    static final int CYAN=Color.rgb(105,231,255), VIOLET=Color.rgb(171,151,255);
    static int dp(Context c,int n){return Math.round(n*c.getResources().getDisplayMetrics().density);}
    static GradientDrawable shape(Context c,int fill,int border,int radius){GradientDrawable d=new GradientDrawable();d.setColor(fill);d.setCornerRadius(dp(c,radius));if(border!=0)d.setStroke(dp(c,1),border);return d;}
    static GradientDrawable gradient(Context c,int first,int last,int radius){GradientDrawable d=new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{first,last});d.setCornerRadius(dp(c,radius));return d;}
    static RippleDrawable ripple(Context c,Drawable content,int radius){return new RippleDrawable(ColorStateList.valueOf(0x2269E7FF),content,shape(c,Color.WHITE,0,radius));}
    static void background(View v){v.setPadding(dp(v.getContext(),20),dp(v.getContext(),12),dp(v.getContext(),20),dp(v.getContext(),12));v.setBackground(gradient(v.getContext(),BG,Color.rgb(12,17,34),0));}
    static void card(View v,boolean active){Context c=v.getContext();v.setBackground(ripple(c,shape(c,active?Color.rgb(20,42,58):SURFACE,active?0x8869E7FF:BORDER,18),18));}
    static void playerCard(View v){Context c=v.getContext();GradientDrawable d=gradient(c,Color.rgb(21,38,55),Color.rgb(27,24,50),24);d.setStroke(dp(c,1),Color.rgb(53,77,101));v.setBackground(d);}
    static TextView text(Context c,String value,int size,int color){TextView t=new TextView(c);t.setText(value);t.setTextSize(size);t.setTextColor(color);t.setFontFeatureSettings("kern");t.setIncludeFontPadding(false);return t;}
    static void bold(TextView v){v.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));}
    static TextView eyebrow(Context c,String value){TextView t=text(c,value,10,CYAN);t.setLetterSpacing(.16f);bold(t);return t;}
    static Button button(Context c,String value,View.OnClickListener listener){Button b=new Button(c);b.setText(value);b.setTextSize(13);b.setTextColor(TEXT);b.setAllCaps(false);b.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));b.setMinWidth(0);b.setMinimumWidth(0);b.setMinHeight(dp(c,48));b.setMinimumHeight(dp(c,48));b.setPadding(dp(c,10),dp(c,6),dp(c,10),dp(c,6));b.setStateListAnimator(null);b.setBackground(ripple(c,shape(c,RAISED,BORDER,14),14));b.setOnClickListener(listener);return b;}
    static void ghost(Button b){Context c=b.getContext();b.setBackground(ripple(c,shape(c,Color.TRANSPARENT,0,14),14));b.setTextColor(MUTED);}
    static void primary(Button b){Context c=b.getContext();b.setTextColor(BG);b.setBackground(ripple(c,gradient(c,CYAN,Color.rgb(158,187,255),16),16));}
    static void chip(Button b,boolean selected){Context c=b.getContext();b.setTextColor(selected?CYAN:MUTED);b.setBackground(ripple(c,shape(c,selected?Color.rgb(22,48,63):SURFACE,selected?Color.rgb(61,107,123):BORDER,14),14));}
    static void input(EditText v){Context c=v.getContext();v.setTextColor(TEXT);v.setHintTextColor(MUTED);v.setTextSize(14);v.setPadding(dp(c,14),dp(c,12),dp(c,14),dp(c,12));v.setBackground(shape(c,SURFACE,BORDER,16));v.setSingleLine(true);v.setSelectAllOnFocus(false);}
    static void spinner(Spinner s){Context c=s.getContext();s.setBackground(ripple(c,shape(c,SURFACE,BORDER,14),14));s.setPopupBackgroundDrawable(shape(c,RAISED,BORDER,14));}
    static View art(Context c,int size,int seed){View v=new SignalArt(c,seed);v.setLayoutParams(new LinearLayout.LayoutParams(dp(c,size),dp(c,size)));v.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);return v;}
    static LinearLayout result(Context c,String title,String subtitle,int seed,View.OnClickListener action){
        LinearLayout row=new LinearLayout(c);row.setGravity(Gravity.CENTER_VERTICAL);row.setPadding(dp(c,12),dp(c,12),dp(c,12),dp(c,12));card(row,false);
        row.addView(art(c,44,seed));LinearLayout copy=new LinearLayout(c);copy.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams params=new LinearLayout.LayoutParams(0,-2,1);params.leftMargin=dp(c,12);row.addView(copy,params);
        TextView name=text(c,title,15,TEXT);bold(name);name.setMaxLines(1);name.setEllipsize(TextUtils.TruncateAt.END);copy.addView(name);
        if(subtitle!=null&&!subtitle.isEmpty()){TextView detail=text(c,subtitle,12,MUTED);detail.setMaxLines(2);detail.setEllipsize(TextUtils.TruncateAt.END);LinearLayout.LayoutParams detailParams=new LinearLayout.LayoutParams(-1,-2);detailParams.topMargin=dp(c,5);copy.addView(detail,detailParams);}
        TextView arrow=text(c,"›",25,MUTED);arrow.setPadding(dp(c,10),0,0,0);row.addView(arrow);
        LinearLayout.LayoutParams rowParams=new LinearLayout.LayoutParams(-1,-2);rowParams.bottomMargin=dp(c,8);row.setLayoutParams(rowParams);row.setOnClickListener(action);row.setFocusable(true);return row;
    }
    static Button transport(Context c,String kind,View.OnClickListener listener){TransportButton b=new TransportButton(c,kind);b.setText("play".equals(kind)?"▶":"");b.setTextColor("play".equals(kind)?BG:MUTED);b.setMinWidth(0);b.setMinimumWidth(0);b.setStateListAnimator(null);b.setPadding(0,0,0,0);b.setBackground("play".equals(kind)?ripple(c,gradient(c,CYAN,0xFF9BBBFF,28),28):ripple(c,shape(c,Color.TRANSPARENT,0,24),24));b.setOnClickListener(listener);return b;}
    static Button voiceButton(Context c,String description,View.OnClickListener listener){
        Button b=new Button(c){private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);@Override protected void onDraw(Canvas canvas){float u=dp(c,1),x=getWidth()/2f,y=getHeight()/2f;p.setColor(CYAN);p.setStrokeWidth(2*u);p.setStrokeCap(Paint.Cap.ROUND);p.setStyle(Paint.Style.FILL);canvas.drawRoundRect(x-4*u,y-10*u,x+4*u,y+3*u,4*u,4*u,p);p.setStyle(Paint.Style.STROKE);canvas.drawArc(x-8*u,y-8*u,x+8*u,y+8*u,0,180,false,p);canvas.drawLine(x,y+8*u,x,y+12*u,p);canvas.drawLine(x-4*u,y+12*u,x+4*u,y+12*u,p);}};
        b.setText("");b.setContentDescription(description);b.setMinWidth(0);b.setMinimumWidth(0);b.setStateListAnimator(null);b.setBackground(ripple(c,shape(c,RAISED,BORDER,16),16));b.setOnClickListener(listener);return b;
    }
    private static final class SignalArt extends View {
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final int seed;
        SignalArt(Context c,int seed){super(c);this.seed=seed;}
        @Override protected void onDraw(Canvas canvas){float w=getWidth(),h=getHeight();paint.setShader(new LinearGradient(0,0,w,h,new int[]{0xFF19364C,0xFF272145},null,Shader.TileMode.CLAMP));canvas.drawRoundRect(0,0,w,h,w*.24f,w*.24f,paint);paint.setShader(null);paint.setColor(0x334D91B1);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(Math.max(1,w*.017f));canvas.drawCircle(w*.5f,h*.5f,w*.36f,paint);paint.setStyle(Paint.Style.FILL);float[] bars={.18f,.38f,.60f,.36f,.20f};for(int i=0;i<5;i++){float bh=h*bars[i];paint.setColor(i<3?CYAN:VIOLET);canvas.drawRoundRect(w*(.27f+i*.10f),h*.5f-bh*.5f,w*(.315f+i*.10f),h*.5f+bh*.5f,w*.025f,w*.025f,paint);} }
    }
    private static final class TransportButton extends Button {
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final String kind;
        TransportButton(Context c,String kind){super(c);this.kind=kind;}
        @Override protected void onDraw(Canvas canvas){
            float cx=getWidth()/2f,cy=getHeight()/2f,u=dp(getContext(),1);paint.setColor(getCurrentTextColor());paint.setStrokeWidth(2*u);paint.setStrokeCap(Paint.Cap.ROUND);paint.setStrokeJoin(Paint.Join.ROUND);paint.setStyle(Paint.Style.FILL);
            if(kind.equals("play")){if(getText().toString().contains("❚")){canvas.drawRoundRect(cx-7*u,cy-9*u,cx-2*u,cy+9*u,u,u,paint);canvas.drawRoundRect(cx+2*u,cy-9*u,cx+7*u,cy+9*u,u,u,paint);}else{Path p=new Path();p.moveTo(cx-5*u,cy-10*u);p.lineTo(cx+10*u,cy);p.lineTo(cx-5*u,cy+10*u);p.close();canvas.drawPath(p,paint);}return;}
            if(kind.equals("previous")||kind.equals("next")){boolean next=kind.equals("next");float sign=next?1:-1;Path p=new Path();p.moveTo(cx-sign*7*u,cy-8*u);p.lineTo(cx+sign*5*u,cy);p.lineTo(cx-sign*7*u,cy+8*u);p.close();canvas.drawPath(p,paint);canvas.drawRoundRect(cx+sign*7*u-u,cy-8*u,cx+sign*7*u+u,cy+8*u,u,u,paint);return;}
            paint.setStyle(Paint.Style.STROKE);Path p=new Path();
            if(kind.equals("shuffle")){p.moveTo(cx-10*u,cy-6*u);p.cubicTo(cx-2*u,cy-6*u,cx+2*u,cy+6*u,cx+10*u,cy+6*u);p.moveTo(cx-10*u,cy+6*u);p.cubicTo(cx-2*u,cy+6*u,cx+2*u,cy-6*u,cx+10*u,cy-6*u);p.moveTo(cx+7*u,cy-9*u);p.lineTo(cx+10*u,cy-6*u);p.lineTo(cx+7*u,cy-3*u);p.moveTo(cx+7*u,cy+3*u);p.lineTo(cx+10*u,cy+6*u);p.lineTo(cx+7*u,cy+9*u);}
            else{p.moveTo(cx-9*u,cy);p.lineTo(cx-9*u,cy-3*u);p.quadTo(cx-9*u,cy-7*u,cx-5*u,cy-7*u);p.lineTo(cx+8*u,cy-7*u);p.moveTo(cx+5*u,cy-10*u);p.lineTo(cx+8*u,cy-7*u);p.lineTo(cx+5*u,cy-4*u);p.moveTo(cx+9*u,cy);p.lineTo(cx+9*u,cy+3*u);p.quadTo(cx+9*u,cy+7*u,cx+5*u,cy+7*u);p.lineTo(cx-8*u,cy+7*u);p.moveTo(cx-5*u,cy+4*u);p.lineTo(cx-8*u,cy+7*u);p.lineTo(cx-5*u,cy+10*u);}
            canvas.drawPath(p,paint);if(kind.equals("repeat")&&getText().toString().contains("1")){paint.setStyle(Paint.Style.FILL);paint.setTextSize(9*u);paint.setTextAlign(Paint.Align.CENTER);canvas.drawText("1",cx,cy+3*u,paint);}
        }
    }
}
