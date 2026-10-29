package br.com.onda;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.content.res.ColorStateList;
import android.graphics.*;
import android.graphics.drawable.*;
import android.text.TextUtils;
import android.view.*;
import android.widget.*;

/** Static native artwork and shared styling; no animation loop or image downloads. */
final class Ui {
    static AppearancePalette palette=AppearancePalette.ALL[0];
    static int BG=palette.bg,SURFACE=palette.surface,RAISED=palette.raised,BORDER=palette.border,TEXT=AppearancePalette.TEXT,MUTED=AppearancePalette.MUTED,CYAN=palette.accent,VIOLET=palette.secondary;
    private interface Style {void apply(View view);}
    private static final java.util.WeakHashMap<View,Style> styles=new java.util.WeakHashMap<>();
    static void install(AppearancePalette p){palette=p;BG=p.bg;SURFACE=p.surface;RAISED=p.raised;BORDER=p.border;CYAN=p.accent;VIOLET=p.secondary;}
    private static void bind(View v,Style style){styles.put(v,style);style.apply(v);}
    static int resolve(int color){int alpha=color&0xFF000000,rgb=color&0xFFFFFF;for(AppearancePalette p:AppearancePalette.ALL){int[] from={p.bg,p.end,p.surface,p.raised,p.border,p.accent,p.secondary},to={BG,palette.end,SURFACE,RAISED,BORDER,CYAN,VIOLET};for(int i=0;i<from.length;i++)if(rgb==(from[i]&0xFFFFFF))return alpha|(to[i]&0xFFFFFF);}return color;}
    private static void recolor(Drawable drawable){if(drawable==null)return;drawable.mutate();if(drawable instanceof GradientDrawable){GradientDrawable g=(GradientDrawable)drawable;int[] colors=g.getColors();if(colors!=null){int[] copy=colors.clone();for(int i=0;i<copy.length;i++)copy[i]=resolve(copy[i]);g.setColors(copy);}else if(g.getColor()!=null)g.setColor(resolve(g.getColor().getDefaultColor()));}else if(drawable instanceof ColorDrawable)((ColorDrawable)drawable).setColor(resolve(((ColorDrawable)drawable).getColor()));if(drawable instanceof RippleDrawable)((RippleDrawable)drawable).setColor(ColorStateList.valueOf(0x22000000|(CYAN&0xFFFFFF)));if(drawable instanceof LayerDrawable){LayerDrawable layers=(LayerDrawable)drawable;for(int i=0;i<layers.getNumberOfLayers();i++)recolor(layers.getDrawable(i));}}
    static void restyle(View v){if(v instanceof TextView){TextView t=(TextView)v;t.setTextColor(resolve(t.getCurrentTextColor()));t.setHintTextColor(resolve(t.getCurrentHintTextColor()));}Style style=styles.get(v);if(style!=null)style.apply(v);else recolor(v.getBackground());if(v instanceof SeekBar){((SeekBar)v).setThumbTintList(ColorStateList.valueOf(CYAN));((SeekBar)v).setProgressTintList(ColorStateList.valueOf(CYAN));}else if(v instanceof ProgressBar){((ProgressBar)v).setProgressTintList(ColorStateList.valueOf(CYAN));((ProgressBar)v).setIndeterminateTintList(ColorStateList.valueOf(CYAN));}if(v instanceof ViewGroup){ViewGroup group=(ViewGroup)v;for(int i=0;i<group.getChildCount();i++)restyle(group.getChildAt(i));}v.invalidate();}
    private static int accentEnd(){return palette==AppearancePalette.ALL[0]?0xFF9EBBFF:VIOLET;}
    private static int selectedFill(){return palette==AppearancePalette.ALL[0]?0xFF16303F:AppearancePalette.blend(SURFACE,CYAN,.13f);}
    static int dp(Context c,int n){return Math.round(n*c.getResources().getDisplayMetrics().density);}
    static GradientDrawable shape(Context c,int fill,int border,int radius){GradientDrawable d=new GradientDrawable();d.setColor(fill);d.setCornerRadius(dp(c,Math.round(radius*palette.corners)));if(border!=0)d.setStroke(dp(c,1),border);return d;}
    static GradientDrawable gradient(Context c,int first,int last,int radius){GradientDrawable d=new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{first,last});d.setCornerRadius(dp(c,Math.round(radius*palette.corners)));return d;}
    static RippleDrawable ripple(Context c,Drawable content,int radius){return new RippleDrawable(ColorStateList.valueOf(0x22000000|(CYAN&0xFFFFFF)),content,shape(c,Color.WHITE,0,radius));}
    static void background(View v){v.setPadding(dp(v.getContext(),20),dp(v.getContext(),12),dp(v.getContext(),20),dp(v.getContext(),12));bind(v,w->w.setBackground(gradient(w.getContext(),BG,palette.end,0)));}
    static void card(View v,boolean active){bind(v,w->{Context c=w.getContext();w.setBackground(ripple(c,shape(c,active?(palette==AppearancePalette.ALL[0]?0xFF142A3A:selectedFill()):SURFACE,active?(0x88000000|(CYAN&0xFFFFFF)):BORDER,18),18));});}
    static void playerCard(View v){bind(v,w->{Context c=w.getContext();boolean original=palette==AppearancePalette.ALL[0];GradientDrawable d=gradient(c,original?0xFF152637:AppearancePalette.blend(SURFACE,CYAN,.09f),original?0xFF1B1832:AppearancePalette.blend(SURFACE,VIOLET,.09f),24);d.setStroke(dp(c,1),original?0xFF354D65:BORDER);w.setBackground(d);});}
    static TextView text(Context c,String value,int size,int color){TextView t=new TextView(c);t.setText(value);t.setTextSize(size);t.setTextColor(color);t.setFontFeatureSettings("kern");t.setIncludeFontPadding(false);return t;}
    static void bold(TextView v){v.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));}
    static TextView eyebrow(Context c,String value){TextView t=text(c,value,10,CYAN);t.setLetterSpacing(.16f);bold(t);return t;}
    static Button button(Context c,String value,View.OnClickListener listener){Button b=new Button(c);b.setText(value);b.setTextSize(13);b.setTextColor(TEXT);b.setAllCaps(false);b.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));b.setMinWidth(0);b.setMinimumWidth(0);b.setMinHeight(dp(c,48));b.setMinimumHeight(dp(c,48));b.setPadding(dp(c,10),dp(c,6),dp(c,10),dp(c,6));b.setStateListAnimator(null);bind(b,w->w.setBackground(ripple(w.getContext(),shape(w.getContext(),RAISED,BORDER,14),14)));b.setOnClickListener(listener);return b;}
    static void ghost(Button b){Context c=b.getContext();bind(b,w->w.setBackground(ripple(w.getContext(),shape(w.getContext(),Color.TRANSPARENT,0,14),14)));b.setTextColor(MUTED);}
    static void primary(Button b){Context c=b.getContext();b.setTextColor(BG);bind(b,w->w.setBackground(ripple(w.getContext(),gradient(w.getContext(),CYAN,accentEnd(),16),16)));}
    static void chip(Button b,boolean selected){Context c=b.getContext();b.setTextColor(selected?CYAN:MUTED);bind(b,w->w.setBackground(ripple(w.getContext(),shape(w.getContext(),selected?selectedFill():SURFACE,selected?(palette==AppearancePalette.ALL[0]?0xFF3D6B7B:AppearancePalette.blend(BORDER,CYAN,.35f)):BORDER,14),14)));}
    static void input(EditText v){Context c=v.getContext();v.setTextColor(TEXT);v.setHintTextColor(MUTED);v.setTextSize(14);v.setPadding(dp(c,14),dp(c,12),dp(c,14),dp(c,12));bind(v,w->w.setBackground(shape(w.getContext(),SURFACE,BORDER,16)));v.setSingleLine(true);v.setSelectAllOnFocus(false);}
    static void spinner(Spinner s){Context c=s.getContext();bind(s,w->{w.setBackground(ripple(w.getContext(),shape(w.getContext(),SURFACE,BORDER,14),14));((Spinner)w).setPopupBackgroundDrawable(shape(w.getContext(),RAISED,BORDER,14));});}
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
    static Button favoriteButton(Context c,View.OnClickListener listener){
        HeartButton b=new HeartButton(c);b.setText("");b.setTextColor(MUTED);b.setContentDescription("Adicionar aos favoritos");
        b.setMinWidth(0);b.setMinimumWidth(0);b.setMinHeight(dp(c,48));b.setMinimumHeight(dp(c,48));b.setPadding(0,0,0,0);b.setStateListAnimator(null);
        bind(b,w->w.setBackground(ripple(w.getContext(),shape(w.getContext(),RAISED,BORDER,16),16)));b.setOnClickListener(listener);return b;
    }
    static Button transport(Context c,String kind,View.OnClickListener listener){TransportButton b=new TransportButton(c,kind);b.setText("play".equals(kind)?"▶":"");b.setTextColor("play".equals(kind)?BG:MUTED);b.setMinWidth(0);b.setMinimumWidth(0);b.setStateListAnimator(null);b.setPadding(0,0,0,0);bind(b,w->{Context context=w.getContext();w.setBackground("play".equals(kind)?ripple(context,gradient(context,CYAN,palette==AppearancePalette.ALL[0]?0xFF9BBBFF:VIOLET,28),28):ripple(context,shape(context,Color.TRANSPARENT,0,24),24));});b.setOnClickListener(listener);return b;}
    static Button voiceButton(Context c,String description,View.OnClickListener listener){
        Button b=new Button(c){private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);@Override protected void onDraw(Canvas canvas){float u=dp(c,1),x=getWidth()/2f,y=getHeight()/2f;p.setColor(CYAN);p.setStrokeWidth(2*u);p.setStrokeCap(Paint.Cap.ROUND);p.setStyle(Paint.Style.FILL);canvas.drawRoundRect(x-4*u,y-10*u,x+4*u,y+3*u,4*u,4*u,p);p.setStyle(Paint.Style.STROKE);canvas.drawArc(x-8*u,y-8*u,x+8*u,y+8*u,0,180,false,p);canvas.drawLine(x,y+8*u,x,y+12*u,p);canvas.drawLine(x-4*u,y+12*u,x+4*u,y+12*u,p);}};
        b.setText("");b.setContentDescription(description);b.setMinWidth(0);b.setMinimumWidth(0);b.setStateListAnimator(null);bind(b,w->w.setBackground(ripple(w.getContext(),shape(w.getContext(),RAISED,BORDER,16),16)));b.setOnClickListener(listener);return b;
    }
    static void menu(Activity activity,View anchor,String[] labels,String[] descriptions,Runnable[] actions){
        if(activity.isFinishing()||activity.isDestroyed())return;
        // Small finite menus use a plain ScrollView so every action stays exposed
        // to accessibility, including on very short landscape windows.
        Rect frame=new Rect();activity.getWindow().getDecorView().getWindowVisibleDisplayFrame(frame);
        if(frame.isEmpty()){Point size=new Point();activity.getWindowManager().getDefaultDisplay().getSize(size);frame.set(0,0,size.x,size.y);}
        int width=Math.max(1,Math.min(dp(activity,480),frame.width()-dp(activity,16)));
        android.app.Dialog dialog=new android.app.Dialog(activity);dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        LinearLayout panel=new LinearLayout(activity);panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(activity,8),dp(activity,4),dp(activity,8),dp(activity,4));
        CharSequence description=anchor.getContentDescription();TextView title=text(activity,description==null?"Menu":description.toString(),16,CYAN);bold(title);
        title.setPadding(dp(activity,12),dp(activity,8),dp(activity,12),dp(activity,8));if(android.os.Build.VERSION.SDK_INT>=28)title.setAccessibilityHeading(true);
        panel.addView(title,new LinearLayout.LayoutParams(-1,-2));
        ScrollView scroll=new ScrollView(activity);scroll.setContentDescription("Opções do menu");scroll.setVerticalScrollBarEnabled(true);scroll.setScrollbarFadingEnabled(false);
        LinearLayout options=new LinearLayout(activity);options.setOrientation(LinearLayout.VERTICAL);scroll.addView(options,new ScrollView.LayoutParams(-1,-2));
        for(int i=0;i<labels.length;i++){
            final int index=i;TextView row=text(activity,labels[i],16,TEXT);row.setContentDescription(descriptions[i]);
            row.setMinHeight(dp(activity,48));row.setGravity(Gravity.CENTER_VERTICAL);row.setPadding(dp(activity,12),dp(activity,12),dp(activity,12),dp(activity,12));
            row.setBackground(ripple(activity,shape(activity,Color.TRANSPARENT,0,10),10));row.setFocusable(true);
            row.setOnClickListener(v->{dialog.dismiss();actions[index].run();});options.addView(row,new LinearLayout.LayoutParams(-1,-2));
        }
        panel.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        Button close=button(activity,"Fechar",v->dialog.dismiss());close.setId(android.R.id.button2);ghost(close);panel.addView(close,new LinearLayout.LayoutParams(-1,-2));
        int inner=Math.max(1,width-dp(activity,16));int desired=dp(activity,8);
        for(View part:new View[]{title,options,close}){part.measure(View.MeasureSpec.makeMeasureSpec(inner,View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec(0,View.MeasureSpec.UNSPECIFIED));desired+=part.getMeasuredHeight();}
        dialog.setContentView(panel);dialog.show();Window window=dialog.getWindow();if(window!=null){window.setBackgroundDrawable(shape(activity,SURFACE,BORDER,20));
            window.setLayout(width,Math.max(1,Math.min(desired,Math.min(dp(activity,600),frame.height()-dp(activity,16)))));
        }
    }
    static Button menuButton(Context context,String description,View.OnClickListener listener){Button b=button(context,"☰",listener);ghost(b);b.setTextSize(25);b.setContentDescription(description);return b;}
    @androidx.media3.common.util.UnstableApi
    static LinearLayout navigation(Activity activity,int current){
        LinearLayout bar=new LinearLayout(activity);bar.setGravity(Gravity.CENTER_VERTICAL);bar.setPadding(dp(activity,4),dp(activity,4),dp(activity,4),dp(activity,4));bar.setBackground(shape(activity,SURFACE,BORDER,18));
        String[] labels={"Músicas","Vídeos","Explorar"},descriptions={"Abrir biblioteca de músicas","Abrir biblioteca de vídeos","Buscar e ouvir online"};
        Class<?>[] targets={MainActivity.class,VideoActivity.class,OnlineActivity.class};
        for(int i=0;i<labels.length;i++){final int destination=i;Button b=button(activity,labels[i],v->{if(current==destination)return;activity.startActivity(new Intent(activity,targets[destination]).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP));if(!(activity instanceof MainActivity))activity.finish();});b.setTextSize(12);b.setContentDescription(descriptions[i]);b.setSelected(i==current);if(i==current)chip(b,true);else ghost(b);bar.addView(b,new LinearLayout.LayoutParams(0,dp(activity,48),1));}
        LinearLayout.LayoutParams params=new LinearLayout.LayoutParams(-1,dp(activity,56));params.topMargin=dp(activity,8);bar.setLayoutParams(params);return bar;
    }
    private static final class SignalArt extends View {
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final int seed;
        SignalArt(Context c,int seed){super(c);this.seed=seed;}
        @Override protected void onDraw(Canvas canvas){float w=getWidth(),h=getHeight();paint.setShader(new LinearGradient(0,0,w,h,new int[]{palette==AppearancePalette.ALL[0]?0xFF19364C:AppearancePalette.blend(SURFACE,CYAN,.15f),palette==AppearancePalette.ALL[0]?0xFF272145:AppearancePalette.blend(SURFACE,VIOLET,.18f)},null,Shader.TileMode.CLAMP));canvas.drawRoundRect(0,0,w,h,w*.24f,w*.24f,paint);paint.setShader(null);paint.setColor(0x33000000|(CYAN&0xFFFFFF));paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(Math.max(1,w*.017f));canvas.drawCircle(w*.5f,h*.5f,w*.36f,paint);paint.setStyle(Paint.Style.FILL);float[] bars={.18f,.38f,.60f,.36f,.20f};for(int i=0;i<5;i++){float bh=h*bars[i];paint.setColor(i<3?CYAN:VIOLET);canvas.drawRoundRect(w*(.27f+i*.10f),h*.5f-bh*.5f,w*(.315f+i*.10f),h*.5f+bh*.5f,w*.025f,w*.025f,paint);} }
    }
    /** Heart geometry uses dp, so Android font scaling cannot crop the icon. */
    private static final class HeartButton extends Button {
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);private final Path path=new Path();
        HeartButton(Context c){super(c);}
        @Override protected void onDraw(Canvas canvas){
            float u=Math.max(0,Math.min(dp(getContext(),32),Math.min(getWidth(),getHeight())-dp(getContext(),16)))/24f;
            if(u<=0)return;float x=getWidth()/2f-12*u,y=getHeight()/2f-12*u;
            path.reset();path.moveTo(x+12*u,y+21*u);
            path.cubicTo(x+9*u,y+18*u,x+3*u,y+14*u,x+3*u,y+8*u);
            path.cubicTo(x+3*u,y+2*u,x+9*u,y+1*u,x+12*u,y+6*u);
            path.cubicTo(x+15*u,y+1*u,x+21*u,y+2*u,x+21*u,y+8*u);
            path.cubicTo(x+21*u,y+14*u,x+15*u,y+18*u,x+12*u,y+21*u);path.close();
            paint.setColor(getCurrentTextColor());paint.setAlpha(isEnabled()?255:100);paint.setStrokeWidth(dp(getContext(),2));paint.setStrokeJoin(Paint.Join.ROUND);
            paint.setStyle(isSelected()?Paint.Style.FILL:Paint.Style.STROKE);canvas.drawPath(path,paint);
        }
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
