param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))
$ErrorActionPreference='Stop';$t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $a.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
if(-not ('System.Windows.Forms.MessageBox' -as [type])){Add-Type @'
namespace System.Windows.Forms {public static class MessageBox {public static string LastMessage;public static object Show(params object[] args){LastMessage=args[0].ToString();return null;}}}
'@}
$checks=0
function Check($name,$ok){if(-not $ok){throw $name};$script:checks++;Write-Output "PASS $name"}
function Rec($id,$mat,$cp){$r=[pscustomobject]@{id=$id;matricula=$mat;nome='SERVIDOR TESTE';setor='SETOR';periodo='M';cp_relatorio=$cp;aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';opcao1=(New-EmptyOptionObject);opcao2=(New-EmptyOptionObject);opcao3=(New-EmptyOptionObject);opcao_aprovada=0;fr_opcao_aprovada=0;observacoes='OBSERVACAO'};[void](Initialize-RecordDefaults $r);return $r}
$script:Records=@((Rec 1 '00123' '123'),(Rec 2 '00123' '123'),(Rec 3 '00456' '456'))
$script:HistoricoFerias=@([pscustomobject]@{matricula='00123';cp_relatorio='99'})
$script:Config=[pscustomobject]@{setores=@('SETOR');periodos=@('M')}
foreach($bad in @('', ' ', '0','-1','1.5','1e3','abc','2147483648')){$blocked=$false;try{Resolve-CPServidorCadastro '00123' $bad|Out-Null}catch{$blocked=$true};Check "rejeita CP obrigatorio/invalido '$bad'" $blocked}
Check 'CP maximo do Access aceito' ((Resolve-CPServidorCadastro '00123' '2147483647') -eq '2147483647')
Check 'CP normalizado sem espacos e zeros redundantes' ((Resolve-CPServidorCadastro '00123' ' 000123 ') -eq '123')
$blocked=$false;try{Resolve-CPServidorCadastro '00123' '00456'|Out-Null}catch{$blocked=$true};Check 'CP de outra matricula bloqueado inclusive com zeros' $blocked
$script:HistoricoFerias+=@([pscustomobject]@{matricula='00456';cp_relatorio='777'})
Check 'CP antigo do historico nao bloqueia outro servidor quando cadastro ja corrigido' ((Resolve-CPServidorCadastro '00123' '777') -eq '777')
$script:Records[2].cp_relatorio='';$blocked=$false;try{Resolve-CPServidorCadastro '00123' '777'|Out-Null}catch{$blocked=$true}
Check 'CP historico protege servidor cujo cadastro esta sem CP' $blocked
$script:Records[2].cp_relatorio='456'

$before=$script:Records|Select-Object * -ExcludeProperty cp_relatorio|ConvertTo-Json -Depth 30 -Compress
Set-CPServidor '00123' '789'
Check 'CP propagado a todos os aquisitivos da matricula' (@($script:Records|Where-Object {$_.matricula -eq '00123' -and $_.cp_relatorio -eq '789'}).Count -eq 2)
Check 'outra matricula preservada' ($script:Records[2].cp_relatorio -eq '456')
Check 'demais campos e datas preservados' (($script:Records|Select-Object * -ExcludeProperty cp_relatorio|ConvertTo-Json -Depth 30 -Compress) -ceq $before)
Check 'CP antigo do historico nao prevalece sobre cadastro' (@(Get-CPsServidor '00123').Count -eq 1 -and @(Get-CPsServidor '00123')[0] -eq '789')
Check 'historico original preservado' ($script:HistoricoFerias[0].cp_relatorio -eq '99')
$script:Records[1].cp_relatorio='790';Check 'CPs divergentes nao escolhem o primeiro' (@(Get-CPsServidor '00123').Count -eq 2)
Set-CPServidor '00123' '789'
$new=New-RegistroFeriasManual '00123' 'Servidor' 'SETOR' 'M' '2026-01-01' '2026-12-31' $false
Check 'novo aquisitivo herda CP do servidor' ($new.cp_relatorio -eq '789' -and $new.matricula -ceq '00123')
$blocked=$false;try{New-RegistroFeriasManual 'NOVA' 'Servidor' 'SETOR' 'M'|Out-Null}catch{$blocked=$true};Check 'novo servidor sem CP nao e criado' $blocked
$new=New-RegistroFeriasManual 'NOVA' 'Servidor' 'SETOR' 'M' -cpServidor '987'
Check 'novo servidor aceita CP explicito' ($new.cp_relatorio -eq '987')
$count=$script:Records.Count;$res=Apply-ServidorCadastro 'LOTE' 'Servidor' 'SETOR' 'M'
Check 'lote sem CP nao insere registro' ($res.status -eq 'ERRO' -and $script:Records.Count -eq $count)
$res=Apply-ServidorCadastro 'LOTE' 'Servidor' 'SETOR' 'M' -cpServidor '987'
Check 'lote com CP insere cadastro preenchido' ($res.status -eq 'NOVO' -and $script:Records[-1].cp_relatorio -eq '987')
# Exercitar os dois caminhos reais de salvamento, com controles simulados e persistência isolada.
function Save-Database {$script:saves++}
function Refresh-SetorPeriodos {}
function Refresh-Grid {}
function Refresh-Dashboard {}
function Refresh-PlanejamentoSetor {}
function Refresh-PeriodosGrid {param($mat)}
function Load-Servidor {param($mat)}
function Load-Editor {param($id)}
function Get-ServidorRecords {param($mat) return @($script:Records|Where-Object {$_.matricula -ceq $mat})}
$script:txtMatricula=[pscustomobject]@{Text='00123'};$script:txtNome=[pscustomobject]@{Text='Servidor Teste'};$script:cmbSetor=[pscustomobject]@{Text='SETOR'};$script:cmbPeriodo=[pscustomobject]@{Text='M'};$script:txtCPServidor=[pscustomobject]@{Text=''};$script:saves=0
$snapshot=$script:Records|ConvertTo-Json -Depth 30 -Compress
Save-ServidorCadastro
Check 'Salvar cadastro vazio impede gravacao e mutacao' ($script:saves -eq 0 -and ($script:Records|ConvertTo-Json -Depth 30 -Compress) -ceq $snapshot)
$script:txtCPServidor.Text='321';Save-ServidorCadastro
Check 'Salvar cadastro grava CP nos dois aquisitivos' ($script:saves -eq 1 -and @($script:Records|Where-Object {$_.matricula -eq '00123' -and $_.cp_relatorio -eq '321'}).Count -eq 2)
$script:CurrentId=1;$script:chkFeriasBloqueadas=[pscustomobject]@{Checked=$false};$script:txtCPServidor.Text='';$snapshot=$script:Records|ConvertTo-Json -Depth 30 -Compress
Save-Editor
Check 'Salvar opcoes tambem exige CP sem mutacao' ($script:saves -eq 1 -and ($script:Records|ConvertTo-Json -Depth 30 -Compress) -ceq $snapshot)
$script:txtCPServidor.Text='322';$script:txtObs=[pscustomobject]@{Text='OBSERVACAO'};$script:txtJustificativaDecisao=$null
function Read-OptionFromControls {param($controls) return New-EmptyOptionObject}
Save-Editor
Check 'Salvar opcoes propaga CP ao cadastro da matricula' ($script:saves -eq 2 -and @($script:Records|Where-Object {$_.matricula -eq '00123' -and $_.cp_relatorio -eq '322'}).Count -eq 2)
function GridRow($mat,$cp){
 $cells=@{}
 foreach($pair in @(@('lmat',$mat),@('lcp',$cp),@('lnome','SERVIDOR'),@('lsetor','SETOR'),@('lperiodo','M'),@('lstatus',''),@('lmsg',''))){$cells[$pair[0]]=[pscustomobject]@{Value=$pair[1]}}
 return [pscustomobject]@{IsNewRow=$false;Cells=$cells;DefaultCellStyle=[pscustomobject]@{BackColor=$null}}
}
$script:gridLote=[pscustomobject]@{Rows=@((GridRow 'NOVO1' '555'),(GridRow 'NOVO2' '556'))}
Check 'lote completo com CPs distintos validado' (Validar-LoteServidores $true)
$script:gridLote.Rows[1].Cells['lcp'].Value='555'
Check 'lote com CP duplicado nao e processavel' (-not (Validar-LoteServidores $true))
$script:gridLote.Rows[1].Cells['lcp'].Value=''
Check 'lote com CP vazio nao e processavel' (-not (Validar-LoteServidores $true))
$script:gridLote.Rows[1].Cells['lcp'].Value='556';$script:gridLote.Rows[1].Cells['lmat'].Value='NOVO1'
Check 'lote com matricula repetida nao e processavel' (-not (Validar-LoteServidores $true))
Write-Output "CADASTRO_CP_COMPLETE assertions=$checks"
