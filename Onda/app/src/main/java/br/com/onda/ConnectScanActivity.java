package br.com.onda;
import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.hardware.Camera;
import android.os.*;
import android.view.*;
import android.widget.*;
import com.google.zxing.PlanarYUVLuminanceSource;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
/** Camera is opened only on this screen; frames are decoded locally and never saved. */
@SuppressWarnings("deprecation")
public class ConnectScanActivity extends Activity implements SurfaceHolder.Callback {
 private Camera camera;private SurfaceView preview;private TextView status;private boolean resumed,surface,done;private long last;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();private final AtomicBoolean decoding=new AtomicBoolean();
 @Override public void onCreate(Bundle state){super.onCreate(state);LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});root.addView(Ui.text(this,"Ler QR do Onda Conecta",22,Ui.TEXT));status=Ui.text(this,"Aponte a câmera para o QR exibido no outro celular. A câmera só funciona nesta tela.",14,Ui.CYAN);status.setPadding(0,Ui.dp(this,16),0,Ui.dp(this,16));root.addView(status);preview=new SurfaceView(this);preview.setContentDescription("Câmera para ler QR do Conecta");preview.getHolder().addCallback(this);root.addView(preview,new LinearLayout.LayoutParams(-1,0,1));root.addView(Ui.button(this,"Cancelar",v->finish()));setContentView(root);if(checkSelfPermission(Manifest.permission.CAMERA)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.CAMERA},75);}
 @Override protected void onResume(){super.onResume();resumed=true;open();}
 @Override protected void onPause(){resumed=false;release();super.onPause();}
 @Override protected void onDestroy(){done=true;release();worker.shutdownNow();super.onDestroy();}
 @Override public void onRequestPermissionsResult(int code,String[] p,int[] result){super.onRequestPermissionsResult(code,p,result);if(code==75){if(result.length>0&&result[0]==PackageManager.PERMISSION_GRANTED)open();else status.setText("Sem permissão da câmera. Volte e use Ler QR de uma imagem ou cole o código.");}}
 private void open(){if(!resumed||!surface||done||camera!=null||checkSelfPermission(Manifest.permission.CAMERA)!=PackageManager.PERMISSION_GRANTED)return;try{camera=Camera.open();Camera.Parameters params=camera.getParameters();Camera.Size chosen=null;for(Camera.Size size:params.getSupportedPreviewSizes())if(size.width<=1280&&size.height<=720&&(chosen==null||Math.abs(size.width-640)+Math.abs(size.height-480)<Math.abs(chosen.width-640)+Math.abs(chosen.height-480)))chosen=size;if(chosen!=null)params.setPreviewSize(chosen.width,chosen.height);if(params.getSupportedFocusModes().contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE))params.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);camera.setParameters(params);camera.setDisplayOrientation(90);camera.setPreviewDisplay(preview.getHolder());camera.setPreviewCallback((data,source)->{long now=SystemClock.elapsedRealtime();if(done||now-last<350||!decoding.compareAndSet(false,true))return;last=now;Camera.Size size=source.getParameters().getPreviewSize();byte[] frame=data.clone();worker.execute(()->{try{String value=ConnectQr.decode(new PlanarYUVLuminanceSource(frame,size.width,size.height,0,0,size.width,size.height,false));ConnectProtocol.Pair.parse(value);runOnUiThread(()->{if(!done&&resumed){done=true;setResult(RESULT_OK,new Intent().putExtra("code",value));finish();}});}catch(Exception ignored){}finally{decoding.set(false);}});});camera.startPreview();}catch(Exception e){release();status.setText("Câmera indisponível. Volte e use uma imagem do QR ou cole o código de conexão.");}}
 private void release(){if(camera!=null){try{camera.setPreviewCallback(null);camera.stopPreview();}catch(RuntimeException ignored){}camera.release();camera=null;}}
 @Override public void surfaceCreated(SurfaceHolder holder){surface=true;open();}
 @Override public void surfaceDestroyed(SurfaceHolder holder){surface=false;release();}
 @Override public void surfaceChanged(SurfaceHolder holder,int format,int width,int height){}
}
