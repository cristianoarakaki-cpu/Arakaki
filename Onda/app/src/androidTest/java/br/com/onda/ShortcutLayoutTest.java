package br.com.onda;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.os.ParcelFileDescriptor;
import android.text.Layout;
import android.view.*;
import android.view.accessibility.AccessibilityNodeInfo;
import android.widget.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;
import org.json.*;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

/** Real header layout and menu regression for the reported Atalho / s split. */
@androidx.media3.common.util.UnstableApi
public class ShortcutLayoutTest {
    private final Instrumentation ins=getInstrumentation();
    private final Context context=ins.getTargetContext();
    private MainActivity screen;
    private interface Check { boolean ready() throws Exception; }
    private void waitFor(Check check)throws Exception{for(int n=0;n<160;n++){boolean[] done={false};ins.runOnMainSync(()->{try{done[0]=check.ready();}catch(Exception e){throw new RuntimeException(e);}});if(done[0])return;Thread.sleep(50);}fail("Shortcut header or menu did not become ready");}
    private String shell(String command)throws Exception{try(InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(ins.getUiAutomation().executeShellCommand(command));ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] buffer=new byte[4096];int n;while((n=in.read(buffer))!=-1)out.write(buffer,0,n);return out.toString("UTF-8").trim();}}
    private String override(String current,String name){Matcher m=Pattern.compile("Override "+name+": ([^\\r\\n]+)").matcher(current);return m.find()?m.group(1).trim():"reset";}
    private TextView find(View view,String value,boolean description){if(view instanceof TextView&&value.equals(String.valueOf(description?view.getContentDescription():((TextView)view).getText())))return (TextView)view;if(view instanceof ViewGroup){ViewGroup group=(ViewGroup)view;for(int i=0;i<group.getChildCount();i++){TextView found=find(group.getChildAt(i),value,description);if(found!=null)return found;}}return null;}
    private JSONObject measure(TextView view)throws Exception{JSONObject out=new JSONObject();if(view==null)return out.put("missing",true);Layout layout=view.getLayout();Rect visible=new Rect(),frame=new Rect();view.getGlobalVisibleRect(visible);screen.getWindow().getDecorView().getWindowVisibleDisplayFrame(frame);int width=view.getWidth()-view.getCompoundPaddingLeft()-view.getCompoundPaddingRight();return out.put("text",view.getText()).put("lines",layout==null?0:layout.getLineCount()).put("ellipsis",layout==null||layout.getLineCount()==0?-1:layout.getEllipsisCount(0)).put("lineWidth",layout==null||layout.getLineCount()==0?0:layout.getLineWidth(0)).put("availableWidth",width).put("fullyVisible",visible.width()>=view.getWidth()-2&&visible.height()>=view.getHeight()-2&&frame.contains(visible)).put("touchHeight",view.getHeight());}
    private boolean readable(JSONObject label)throws Exception{return !label.optBoolean("missing")&&label.getInt("lines")==1&&label.getInt("ellipsis")==0&&label.getDouble("lineWidth")<=label.getInt("availableWidth")+2&&label.getBoolean("fullyVisible");}
    private boolean menuHas(String text){AccessibilityNodeInfo root=ins.getUiAutomation().getRootInActiveWindow();if(root==null)return false;for(AccessibilityNodeInfo node:root.findAccessibilityNodeInfosByText(text))if(text.equals(String.valueOf(node.getText())))return true;return false;}
    private boolean clickMenu(String text){AccessibilityNodeInfo root=ins.getUiAutomation().getRootInActiveWindow();if(root==null)return false;for(AccessibilityNodeInfo node:root.findAccessibilityNodeInfosByText(text))if(text.equals(String.valueOf(node.getText()))&&node.isClickable())return node.performAction(AccessibilityNodeInfo.ACTION_CLICK);return false;}
    private void captureHeader(TextView shortcut)throws Exception{Bitmap all=ins.getUiAutomation().takeScreenshot();assertNotNull(all);Rect bounds=new Rect();((View)shortcut.getParent()).getGlobalVisibleRect(bounds);Bitmap crop=Bitmap.createBitmap(all,bounds.left,bounds.top,bounds.width(),bounds.height());try(OutputStream out=new FileOutputStream(new File(context.getFilesDir(),"shortcuts-header.png"))){crop.compress(Bitmap.CompressFormat.PNG,100,out);}finally{crop.recycle();all.recycle();}}
    @Test public void shortcutAndBrandStayWholeAndMenuOpensWithLargeFontsAndThemes()throws Exception{
        assertTrue("Emulator required",shell("getprop ro.kernel.qemu").equals("1")||shell("getprop ro.boot.qemu").equals("1"));
        String oldFont=shell("settings get system font_scale"),oldSize=override(shell("wm size"),"size"),oldDensity=override(shell("wm density"),"density");
        SharedPreferences appearance=context.getSharedPreferences("appearance",0),prefs=context.getSharedPreferences(QuickAccess.PREF,0);String oldTheme=appearance.getString("theme",null);Set<String> oldChoices=prefs.contains(QuickAccess.KEY)?new HashSet<>(prefs.getStringSet(QuickAccess.KEY,Collections.emptySet())):null;
        JSONArray cases=new JSONArray(),problems=new JSONArray();prefs.edit().remove(QuickAccess.KEY).commit();
        try{for(float font:new float[]{1.3f,1.6f})for(int width:new int[]{320,411})for(String theme:new String[]{"original","spectrum"}){
            shell("wm density 420");shell("wm size "+(width==320?"840x1680":"1080x2240"));shell("settings put system font_scale "+font);appearance.edit().putString("theme",theme).commit();Thread.sleep(700);
            screen=(MainActivity)ins.startActivitySync(new Intent(context,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->screen.hasWindowFocus()&&Math.abs(screen.getResources().getConfiguration().fontScale-font)<.02f&&screen.getResources().getConfiguration().screenWidthDp==width&&find(screen.getWindow().getDecorView(),"Atalhos e ajuda rápida",true)!=null);ins.waitForIdleSync();Thread.sleep(120);
            TextView[] button={null};JSONObject entry=new JSONObject().put("widthDp",width).put("fontScale",font).put("theme",theme);
            ins.runOnMainSync(()->{try{View root=screen.getWindow().getDecorView();button[0]=find(root,"Atalhos e ajuda rápida",true);JSONObject shortcut=measure(button[0]),brand=measure(find(root,"onda",false)),menu=measure(find(root,"Menu da biblioteca",true));entry.put("shortcut",shortcut).put("brand",brand).put("menuVisible",menu.optBoolean("fullyVisible"));if(!readable(shortcut))problems.put("Atalhos word broken or clipped: "+entry);if(!readable(brand))problems.put("Brand broken or clipped: "+entry);if(!menu.optBoolean("fullyVisible"))problems.put("Library menu is not fully visible: "+entry);assertTrue(button[0].getHeight()>=Ui.dp(context,48));}catch(Exception e){throw new RuntimeException(e);}});
            if(font==1.6f&&width==411&&theme.equals("spectrum"))captureHeader(button[0]);
            ins.runOnMainSync(()->button[0].performClick());boolean opened=false;for(int n=0;n<100;n++){if(menuHas("Ajuda rápida")&&menuHas("Escolher atalhos")){opened=true;break;}Thread.sleep(50);}entry.put("menuOpened",opened);if(!opened)problems.put("Shortcut menu did not open: "+entry);cases.put(entry);assertTrue("Shortcut menu close action unavailable",clickMenu("Fechar"));waitFor(()->screen.hasWindowFocus());ins.runOnMainSync(screen::finish);ins.waitForIdleSync();screen=null;
        }}finally{
            if(screen!=null)ins.runOnMainSync(screen::finish);ins.waitForIdleSync();
            SharedPreferences.Editor theme=appearance.edit();if(oldTheme==null)theme.remove("theme");else theme.putString("theme",oldTheme);theme.commit();SharedPreferences.Editor restore=prefs.edit();if(oldChoices==null)restore.remove(QuickAccess.KEY);else restore.putStringSet(QuickAccess.KEY,oldChoices);restore.commit();ins.runOnMainSync(()->Ui.install(AppearancePalette.find(oldTheme)));
            shell("wm size "+oldSize);shell("wm density "+oldDensity);shell(oldFont.equals("null")?"settings delete system font_scale":"settings put system font_scale "+oldFont);Thread.sleep(300);
            try(OutputStream out=new FileOutputStream(new File(context.getFilesDir(),"shortcuts-layout.json"))){out.write(new JSONObject().put("scope","Shortcut and brand header").put("cases",cases).put("problems",problems).toString(2).getBytes("UTF-8"));}
        }
        assertEquals("All font, width and theme cases must run",8,cases.length());assertEquals(problems.toString(),0,problems.length());
    }
}
