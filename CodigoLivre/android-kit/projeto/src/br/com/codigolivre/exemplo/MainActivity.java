package br.com.codigolivre.exemplo;
import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.widget.*;
public class MainActivity extends Activity {
 @Override public void onCreate(Bundle state){
  super.onCreate(state);
  LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);layout.setPadding(32,80,32,32);layout.setBackgroundColor(Color.rgb(16,24,39));
  TextView title=new TextView(this);title.setText("Meu primeiro aplicativo");title.setTextColor(Color.WHITE);title.setTextSize(25);layout.addView(title);
  Button button=new Button(this);button.setText("Testar aplicativo");layout.addView(button);button.setOnClickListener(v->Toast.makeText(this,"APK criado com sucesso!",Toast.LENGTH_LONG).show());setContentView(layout);
 }
}
