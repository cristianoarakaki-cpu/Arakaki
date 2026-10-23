package br.com.onda;

import android.app.*;
import android.content.*;
import android.os.Bundle;
import android.text.InputFilter;
import android.view.*;
import android.widget.*;

public class VoicePhrasesActivity extends Activity {
    private VoicePhraseBook book;private LinearLayout rows;private EditText spokenInput;
    private static final VoiceCommand.Action[] ACTIONS={VoiceCommand.Action.FAVORITES,VoiceCommand.Action.PLAY,VoiceCommand.Action.PAUSE,VoiceCommand.Action.NEXT,VoiceCommand.Action.PREVIOUS,VoiceCommand.Action.FAVORITE_ADD,VoiceCommand.Action.FAVORITE_REMOVE,VoiceCommand.Action.SHUFFLE_ON,VoiceCommand.Action.SHUFFLE_OFF,VoiceCommand.Action.REPEAT_ONE,VoiceCommand.Action.REPEAT_ALL,VoiceCommand.Action.REPEAT_OFF,VoiceCommand.Action.SEARCH,VoiceCommand.Action.PLAY_QUERY,VoiceCommand.Action.SLEEP,VoiceCommand.Action.HELP,VoiceCommand.Action.PLAY_PLAYLIST,VoiceCommand.Action.ADD_PLAYLIST};
    private static final String[] LABELS={"Tocar favoritas","Continuar reprodução","Pausar","Próxima faixa","Faixa anterior","Adicionar música às favoritas","Remover música das favoritas","Ativar aleatório","Desativar aleatório","Repetir música","Repetir fila","Desativar repetição","Buscar música ou artista","Buscar e tocar no celular","Temporizador","Mostrar ajuda","Tocar playlist","Adicionar música atual à playlist"};
    @Override public void onCreate(Bundle state){
        super.onCreate(state);book=VoicePhrases.read(this);
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);
        Button back=Ui.button(this,"‹",v->finish());back.setContentDescription("Voltar");Ui.ghost(back);header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));
        TextView title=Ui.text(this,"Minhas frases",24,Ui.TEXT);Ui.bold(title);header.addView(title,new LinearLayout.LayoutParams(0,-2,1));root.addView(header);
        TextView info=Ui.text(this,"Crie atalhos de voz para os controles do Onda. Diga a frase cadastrada para executar sua ação. Os comandos padrão continuam disponíveis. Tudo fica neste celular, sem cobrança.",14,Ui.MUTED);info.setPadding(0,Ui.dp(this,12),0,Ui.dp(this,16));root.addView(info);
        Button add=Ui.button(this,"Nova frase",v->edit(null));add.setContentDescription("Adicionar frase de voz");Ui.primary(add);root.addView(add,new LinearLayout.LayoutParams(-1,Ui.dp(this,48)));
        ScrollView scroll=new ScrollView(this);rows=new LinearLayout(this);rows.setOrientation(LinearLayout.VERTICAL);rows.setPadding(0,Ui.dp(this,16),0,0);scroll.addView(rows);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));render();
    }
    private int index(VoiceCommand.Action a){for(int i=0;i<ACTIONS.length;i++)if(ACTIONS[i]==a)return i;return 0;}
    private void render(){rows.removeAllViews();if(book.entries.isEmpty()){TextView empty=Ui.text(this,"Nenhuma frase ainda. Experimente cadastrar ‘hora de relaxar’ para tocar suas favoritas.",16,Ui.MUTED);rows.addView(empty);return;}
        for(VoicePhraseBook.Entry e:book.entries){String detail=LABELS[index(e.command.action)];if(!e.command.query.isEmpty())detail+=" • "+e.command.query;if(e.command.action==VoiceCommand.Action.SLEEP)detail+=e.command.minutes==0?" • cancelar":" • "+e.command.minutes+" min";
            LinearLayout row=Ui.result(this,e.phrase,detail,0,v->edit(e));row.setContentDescription("Editar frase: "+e.phrase);rows.addView(row);}
    }
    private EditText input(String hint,String description,int max){EditText field=new EditText(this);Ui.input(field);field.setHint(hint);field.setContentDescription(description);field.setFilters(new InputFilter[]{new InputFilter.LengthFilter(max)});return field;}
    private void edit(VoicePhraseBook.Entry entry){
        ScrollView scroll=new ScrollView(this);LinearLayout form=new LinearLayout(this);form.setOrientation(LinearLayout.VERTICAL);int pad=Ui.dp(this,18);form.setPadding(pad,pad,pad,pad);scroll.addView(form);
        form.addView(Ui.text(this,"Quando eu disser",14,Ui.MUTED));LinearLayout line=new LinearLayout(this);
        EditText phrase=input("Ex.: hora de relaxar","Frase personalizada",120);phrase.setInputType(android.text.InputType.TYPE_CLASS_TEXT|android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);line.addView(phrase,new LinearLayout.LayoutParams(0,-2,1));Button mic=Ui.voiceButton(this,"Ditar frase personalizada",v->{spokenInput=phrase;VoiceSearch.start(this,true);});line.addView(mic,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,52)));form.addView(line);
        TextView actionLabel=Ui.text(this,"Executar ação",14,Ui.MUTED);actionLabel.setPadding(0,pad,0,Ui.dp(this,8));form.addView(actionLabel);
        Spinner action=new Spinner(this);action.setContentDescription("Ação da frase");ArrayAdapter<String> adapter=new ArrayAdapter<>(this,android.R.layout.simple_spinner_item,LABELS);adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);action.setAdapter(adapter);Ui.spinner(action);form.addView(action,new LinearLayout.LayoutParams(-1,Ui.dp(this,52)));
        EditText query=input("Nome da música ou artista","Conteúdo da busca",160);form.addView(query);
        EditText minutes=input("Minutos: 1 a 120; 0 cancela","Minutos do temporizador",3);minutes.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);form.addView(minutes);
        TextView hint=Ui.text(this,"Maiúsculas, acentos e pontuação não alteram o atalho. Você também pode dizer ‘Onda’ antes ou ‘por favor’ depois. Em Explorar, buscas por nome pesquisam o catálogo online.",12,Ui.MUTED);hint.setPadding(0,pad,0,0);form.addView(hint);
        if(entry!=null){phrase.setText(entry.phrase);query.setText(entry.command.query);minutes.setText(String.valueOf(entry.command.minutes));action.setSelection(index(entry.command.action));}
        action.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener(){public void onNothingSelected(AdapterView<?> p){}public void onItemSelected(AdapterView<?> p,View v,int position,long id){VoiceCommand.Action a=ACTIONS[position];query.setHint((a==VoiceCommand.Action.PLAY_PLAYLIST||a==VoiceCommand.Action.ADD_PLAYLIST)?"Nome da playlist":"Nome da música ou artista");query.setVisibility(a==VoiceCommand.Action.SEARCH||a==VoiceCommand.Action.PLAY_QUERY||(a==VoiceCommand.Action.PLAY_PLAYLIST||a==VoiceCommand.Action.ADD_PLAYLIST)?View.VISIBLE:View.GONE);minutes.setVisibility(a==VoiceCommand.Action.SLEEP?View.VISIBLE:View.GONE);}});
        AlertDialog.Builder builder=new AlertDialog.Builder(this).setTitle(entry==null?"Nova frase":"Editar frase").setView(scroll).setPositiveButton("Salvar",null).setNegativeButton("Cancelar",null);
        if(entry!=null)builder.setNeutralButton("Excluir",(d,w)->new AlertDialog.Builder(this).setTitle("Excluir frase?").setMessage(entry.phrase).setPositiveButton("Excluir",(x,y)->{VoicePhraseBook changed=VoicePhrases.read(this);changed.remove(entry.id);persist(changed);}).setNegativeButton("Cancelar",null).show());
        AlertDialog dialog=builder.create();dialog.setOnDismissListener(d->{if(spokenInput==phrase)spokenInput=null;});dialog.setOnShowListener(d->dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v->{
            try{VoiceCommand.Action a=ACTIONS[action.getSelectedItemPosition()];String q=a==VoiceCommand.Action.SEARCH||a==VoiceCommand.Action.PLAY_QUERY||(a==VoiceCommand.Action.PLAY_PLAYLIST||a==VoiceCommand.Action.ADD_PLAYLIST)?query.getText().toString():"";int time=0;
                if(a==VoiceCommand.Action.SLEEP){try{time=Integer.parseInt(minutes.getText().toString());}catch(NumberFormatException e){minutes.setError("Informe de 0 a 120 minutos");return;}}
                VoicePhraseBook changed=VoicePhrases.read(this);changed.put(entry==null?null:entry.id,phrase.getText().toString(),a,q,time);
                if(persist(changed)){dialog.dismiss();Toast.makeText(this,"Frase salva",Toast.LENGTH_SHORT).show();}
            }catch(IllegalArgumentException e){Toast.makeText(this,e.getMessage(),Toast.LENGTH_LONG).show();}
        }));dialog.show();dialog.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
    }
    private boolean persist(VoicePhraseBook changed){if(!VoicePhrases.save(this,changed)){Toast.makeText(this,"Não foi possível salvar. Tente novamente.",Toast.LENGTH_LONG).show();return false;}book=changed;render();return true;}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==VoiceSearch.REQUEST&&spokenInput!=null){String value=VoiceSearch.result(result,data);if(!value.isEmpty())spokenInput.setText(value);}}
}
