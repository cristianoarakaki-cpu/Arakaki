param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'),[string]$RealData='')
$ErrorActionPreference='Stop'
$source=[IO.Path]::GetFullPath($Source)
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
Write-Output "SYNTAX errors: $($errors.Count)"
if($errors.Count){$errors | ForEach-Object {Write-Output $_};exit 1}
foreach($f in $ast.EndBlock.Statements){
 if($f -is [Management.Automation.Language.FunctionDefinitionAst]){ . ([scriptblock]::Create($f.Extent.Text)) }
}
function Write-DiagLog {param($Message,$Level,$ErrorRecord)}
$script:HistoricoMinDiasMesDesempate=15
$script:PerfDateCache=@{}
$checks=0
function Check($name,$actual,$expected){
 if($actual -ne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;Write-Output "PASS $name = $actual"
}
function New-HistoryFixture($ini,$fim,$aq='2023-01-01'){
 [pscustomobject]@{matricula='TESTE';nome='Servidor Teste';inicio=$ini;fim=$fim;ano=2024;mes=1;dias=15;aquisitivo_inicio=$aq;aquisitivo_fim='2023-12-31'}
}
Check '14 days below threshold' (Test-HistoricoMesContaDesempate @((New-HistoryFixture '2024-01-01' '2024-01-14')) 2024 1) $false
Check '15 days threshold' (Test-HistoricoMesContaDesempate @((New-HistoryFixture '2024-01-01' '2024-01-15')) 2024 1) $true
Check 'overlap unique days' (Get-HistoricoDiasUnicosMes @((New-HistoryFixture '2024-01-01' '2024-01-10'),(New-HistoryFixture '2024-01-05' '2024-01-14')) 2024 1) 14
Check 'split periods unique sum' (Get-HistoricoDiasUnicosMes @((New-HistoryFixture '2024-01-01' '2024-01-07'),(New-HistoryFixture '2024-01-20' '2024-01-27')) 2024 1) 15
Check 'year crossover January days' (Get-HistoricoDiasUnicosMes @((New-HistoryFixture '2023-12-20' '2024-01-18')) 2024 1) 18
$script:HistoricoFerias=@((New-HistoryFixture '2024-01-01' '2024-01-15'))
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-01-01' '2024-01-15'))
Check 'reimport exact period preserves count' @($m.itens).Count 1
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-01-10' '2024-01-24'))
Check 'same aquisitive overlapping rejected' $m.divergencias 1
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-01-10' '2024-01-24' '2022-01-01'))
Check 'different aquisitive overlap rejected' $m.adicionados 0
Check 'different aquisitive conflict audited' $m.divergencias 1
$script:Config=[pscustomobject]@{historico_3_anos_importado=$true}
Rebuild-HistoricoIndex
$i=Get-HistoricoDesempateInfo ([pscustomobject]@{matricula='TESTE'}) 2 2027
Check 'OBSERVATION partial coverage accepted as available' $i.disponivel $true
Check 'partial coverage explicitly labeled' $i.prioridade 'PARCIAL — ALTA'
Check 'OBSERVATION coverage only 1 year' $i.cobertura 1
Check 'missing year shown as unknown' (Get-HistoricoResumoAno $script:HistoricoFerias 2025 2) 'SEM REGISTRO'
$script:Records=@([pscustomobject]@{matricula='TESTE';nome='Servidor Teste'})
$rows=@()
foreach($aq in @('2022-01-01','2023-01-01')){
 $rows += [pscustomobject]@{valido=$true;cargo='ENFERMEIRO';matricula='TESTE';nome='Servidor Teste';ano_referencia=2024;mes_referencia=1;ferias_inicio='2024-01-01';ferias_fim='2024-01-15';aquisitivo_inicio=$aq;aquisitivo_fim='2023-12-31'}
}
$preview=@(Get-PreviewHistorico $rows)
Check 'preview preserves aquisitive divergences' $preview.Count 2
Check 'both conflicting preview rows require review' @($preview|Where-Object {$_.preview_status -eq 'CONFERIR'}).Count 2
foreach($color in @('indexed43','indexed6','FFFFFF00','FFFFF2CC')){
 $r=@(Read-RelatorioFeriasAmarelo (Join-Path $PSScriptRoot "fixtures/$color.xlsx"))
 Check "yellow fixture returns row $color" $r.Count 1
 Check "yellow recognized $color" $r[0].valido $true
}
# Um conflito entre duas linhas novas não escolhe arbitrariamente a primeira.
$script:HistoricoFerias=@()
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-01-01' '2024-01-15'),(New-HistoryFixture '2024-01-10' '2024-01-24'))
Check 'new conflicting batch accepts neither row' $m.adicionados 0
Check 'new conflicting batch reports both rows' $m.divergencias 2
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-01-15' '2024-01-01'))
Check 'invalid historical dates not inserted' $m.adicionados 0
Check 'invalid historical dates audited' $m.invalidos 1
$script:HistoricoFerias=@((New-HistoryFixture '2024-01-01' '2024-01-15'))
$m=Merge-HistoricoFeriasIncremental @((New-HistoryFixture '2024-02-01' '2024-02-15'))
Check 'nonoverlapping historical period inserted' $m.adicionados 1
Check 'incremental import preserves old period' $m.preservados 1
$future=[pscustomobject]@{valido=$true;cargo='ENFERMEIRO';matricula='TESTE';nome='Servidor Teste';ano_referencia=2027;mes_referencia=1;ferias_inicio='2027-01-01';ferias_fim='2027-01-15';aquisitivo_inicio='2026-01-01';aquisitivo_fim='2026-12-31'}
$preview=@(Get-PreviewHistorico @($future))
Check 'history 2027 appears in preview' $preview.Count 1
Check 'history 2027 is importable' $preview[0].preview_status 'IMPORTAR'
$script:HistoricoFerias=@((New-HistoryFixture '2027-01-01' '2027-01-15'))
Check 'consultation years follow actual dates' ((@(Get-HistoricoAnosConsulta)) -join ',') '2027'
$script:Config=[pscustomobject]@{historico_3_anos_importado=$true}
Rebuild-HistoricoIndex
$futureInfo=Get-HistoricoDesempateInfo ([pscustomobject]@{matricula='TESTE'}) 1 2028
Check '2028 comparison includes 2027 history' $futureInfo.ocorrencias 1
$script:HistoricoFerias=@()
$script:cmbPlanejAno=[pscustomobject]@{SelectedItem='2028'}
Check 'empty history default window follows 2028' ((@(Get-HistoricoAnosConsulta)) -join ',') '2025,2026,2027'

function New-TestRecord([int]$id,[string]$mat){
 $r=[pscustomobject]@{id=$id;matricula=$mat;nome='Servidor sintetico';setor='SETOR TESTE';periodo='M';aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';opcao_aprovada=0;fr_opcao_aprovada=0;ferias_bloqueadas=$false}
 [void](Initialize-RecordDefaults $r)
 $r.opcao1=[pscustomobject]@{tipo='30 DIAS';inicio1='2027-01-01';fim1='2027-01-30';inicio2='';fim2='';fr_inicio='';fr_fim=''}
 return $r
}
$script:Config=[pscustomobject]@{setores=@('SETOR TESTE');periodos=@('M');max_simultaneos=3;total_enfermeiros_planejamento=120;meses_restritos=@();limites_especiais_mensais=@{};grupo_analise_setores=@();grupo_chefia_setores=@();grupo_chefia_servidores=@();grupos_chefia=@();limites_setor_periodo=@();limites_grupo_chefia_periodo=@();historico_3_anos_importado=$false}
$r1=New-TestRecord 1 'A';$r2=New-TestRecord 2 'B';$r2.opcao_aprovada=1
$script:Records=@($r1,$r2)
Check 'pending options do not occupy confirmed total' (Get-ContagemInstitucionalAprovadaMes 2027 1) 1
Check 'projection includes pending and confirmed' (Get-ContagemInstitucionalMes 2027 1) 2
$legacy=New-TestRecord 3 'A';$legacy.ferias_bloqueadas=$true;$legacy.opcao_aprovada=1
$script:Records=@($r1,$legacy)
$overlap=Get-ConflitoEntreAquisitivosAprovados $r1 @(Get-BlocosComunsOpcao $r1 1)
Check 'old blocked option included in overlap protection' ([bool]$overlap) $true
$legacy.ferias_bloqueadas=$false;$legacy.opcao_aprovada=0
Check 'unapproved other option not treated as fixed' ([bool](Get-ConflitoEntreAquisitivosAprovados $r1 @(Get-BlocosComunsOpcao $r1 1))) $false
$legacy.ferias_bloqueadas=$true;$legacy.fixo_inicio='2027-01-01';$legacy.fixo_fim='2027-01-15'
Check 'imported fixed period included in overlap protection' ([bool](Get-ConflitoEntreAquisitivosAprovados $r1 @(Get-BlocosComunsOpcao $r1 1))) $true
$op=New-EmptyOptionObject;$op.tipo='30 DIAS';$op.inicio1='2025-12-31';$op.fim1='2026-01-29'
Check 'vacation cannot begin on aquisitive end' ([bool](Validate-Option $op 'Teste' '2025-12-31')) $true
$op.inicio1='2026-01-01';$op.fim1='2026-01-30'
Check 'vacation can begin day after aquisitive end' ([bool](Validate-Option $op 'Teste' '2025-12-31')) $false
Check '15 day monthly weight' (Get-PesoBlocoInstitucionalMes ([datetime]'2027-01-25') ([datetime]'2027-02-08') 2027 2) 0.5
Check '15 day weight does not double across month' (Get-PesoBlocoInstitucionalMes ([datetime]'2027-01-25') ([datetime]'2027-02-08') 2027 1) 0
Check '30 days January half counts' (Get-PesoBlocoInstitucionalMes ([datetime]'2027-01-17') ([datetime]'2027-02-15') 2027 1) 1
Check '30 days February half counts' (Get-PesoBlocoInstitucionalMes ([datetime]'2027-01-17') ([datetime]'2027-02-15') 2027 2) 1
# Simular aprovação comum não remove FR independente já confirmada.
$r=New-TestRecord 4 'SIM'
$r.opcao1=[pscustomobject]@{tipo='15+15 DIAS';inicio1='2027-07-21';fim1='2027-08-04';inicio2='2027-10-01';fim2='2027-10-15';fr_inicio='';fr_fim=''}
$r.opcao2=New-EmptyOptionObject;$r.opcao2.tipo='FR 20 DIAS';$r.opcao2.fr_inicio='2027-07-01';$r.opcao2.fr_fim='2027-07-20';$r.fr_opcao_aprovada=2
$script:Records=@($r)
$sim=Get-OpcaoSimulacaoRegistro $r (Get-OpcaoSomenteComum $r.opcao1)
Check 'common simulation keeps confirmed FR' $sim.fr_inicio '2027-07-01'
Check 'simulation preserves monthly confirmed weight' (Get-ContagemInstitucionalMesSimulada $r (Get-OpcaoSomenteComum $r.opcao1) 2027 7) 1
$r.opcao_aprovada=1
$frOnly=New-EmptyOptionObject;$frOnly.tipo='FR 20 DIAS';$frOnly.fr_inicio='2027-09-01';$frOnly.fr_fim='2027-09-20'
$sim=Get-OpcaoSimulacaoRegistro $r $frOnly
Check 'FR simulation keeps approved common' $sim.inicio1 '2027-07-21'
Check 'FR simulation applies candidate FR' $sim.fr_inicio '2027-09-01'
# Desempate: cobertura parcial equivalente é utilizável; cobertura diferente não favorece ausência de dados.
$script:Records=@();$script:HistoricoFerias=@();$script:Config.historico_3_anos_importado=$true
$r=New-TestRecord 5 'TESTE'
$r.opcao2=[pscustomobject]@{tipo='30 DIAS';inicio1='2027-03-01';fim1='2027-03-30';inicio2='';fim2='';fr_inicio='';fr_fim=''}
$script:HistoricoFerias=@((New-HistoryFixture '2024-01-01' '2024-01-30'))
Rebuild-HistoricoIndex
$sug=Get-SugestaoOpcaoRegistro $r
Check 'equal partial coverage remains comparable' $sug.historico_comparavel $true
Check 'known occurrence breaks comparable tie' $sug.opcao 2
$r.opcao1.inicio1='2028-01-01';$r.opcao1.fim1='2028-01-30'
$sug=Get-SugestaoOpcaoRegistro $r
Check 'different coverage disables history tiebreak' $sug.historico_comparavel $false
Check 'different coverage preserves option preference' $sug.opcao 1

# Persistência em pasta descartável com dados fictícios. Nunca usa Dados de produção.
if(-not ('System.Windows.Forms.MessageBox' -as [type])){
 Add-Type @'
namespace System.Windows.Forms {
 public enum MessageBoxButtons {OK,YesNo}
 public enum MessageBoxIcon {Error,Warning,Information,Question}
 public enum DialogResult {OK,Yes,No,Cancel}
 public static class MessageBox {public static string LastMessage;public static DialogResult Show(params object[] args){LastMessage=args.Length>0?args[0].ToString():"";return DialogResult.OK;}}
}
'@
}
function Refresh-AllAfterMaintenance {}
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('ferias-regressao-'+[guid]::NewGuid().ToString('N'))
$script:DataDir=Join-Path $testRoot 'Dados';$script:BackupDir=Join-Path $testRoot 'Backups';$script:LogDir=Join-Path $testRoot 'Logs'
$script:DbFile=Join-Path $script:DataDir 'ferias_2027.json';$script:DbLockFile=Join-Path $script:DataDir 'ferias_2027.lock';$script:SeedFile=Join-Path $testRoot 'seed-inexistente.json'
[void](New-Item -ItemType Directory -Path $script:DataDir -Force)
$db=[pscustomobject]@{revisao_dados=1;ano_planejamento=2027;configuracoes=$script:Config;registros=@((New-TestRecord 1 'SINTETICO'));historico_ferias=@()}
[IO.File]::WriteAllText($script:DbFile,($db|ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($true))
Load-Database
$script:UiLazyLoaded=@{Historico=$true;Painel=$true;Planejamento=$true}
$lk=Acquire-DatabaseLock 300
try{
 $blocked=$false;try{$second=Acquire-DatabaseLock 250;$second.Dispose()}catch{$blocked=$true}
 Check 'exclusive database lock blocks second opener' $blocked $true
}finally{$lk.Dispose()}
Check 'save disposable copy' (Save-Database) $true
Check 'save increments revision' (Get-DiskDbState).Revision 2
Check 'save invalidates history view metadata' $script:UiLazyLoaded.Historico $false
$oldHash=(Get-DiskDbState).Hash
$bad=Join-Path $script:DataDir 'invalid.json';[IO.File]::WriteAllText($bad,'{"bad":')
$rejected=$false;try{Commit-DatabaseTempFile $bad $script:DbFile|Out-Null}catch{$rejected=$true}
Check 'invalid temporary JSON rejected' $rejected $true
Check 'invalid commit leaves database unchanged' ((Get-DiskDbState).Hash -eq $oldHash) $true
# Conflito entre clientes: a revisão externa prevalece e a memória é recarregada.
$external=Get-Content $script:DbFile -Raw|ConvertFrom-Json
$external.revisao_dados=3;$external.registros[0].nome='Nome externo sintetico'
[IO.File]::WriteAllText($script:DbFile,($external|ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($true))
$externalHash=(Get-DiskDbState).Hash
$script:Records[0].nome='Alteracao local sintetica'
$conflict=$false;try{Save-Database|Out-Null}catch{$conflict=$_.Exception.Message -like 'CONFLITO_SALVAMENTO_TRATADO:*'}
Check 'stale client save rejected' $conflict $true
Check 'stale client does not overwrite external changes' ((Get-DiskDbState).Hash -eq $externalHash) $true
Check 'memory reloaded after conflict' $script:Records[0].nome 'Nome externo sintetico'
Check 'conflicting unsaved work gets rescue snapshot' @(Get-ChildItem $script:BackupDir -Filter 'CONFLITO_*.json').Count 1
# A restauração da base inteira também respeita revisão/hash e usa uma revisão nova.
$restore=Join-Path $testRoot 'restaurar.json'
[IO.File]::WriteAllText($restore,($db|ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($true))
Check 'restore disposable base' (Restore-DatabaseSafely $restore 'ANTES_TESTE_RESTAURACAO' 'Teste') $true
Check 'restore uses new revision rather than old backup revision' (Get-DiskDbState).Revision 4
# Validação opcional, somente leitura, da base real selecionada pelo analista.
if($RealData){
 $real=Get-Content -LiteralPath $RealData -Raw|ConvertFrom-Json
 Assert-DatabaseStructure $real
 $script:Config=$real.configuracoes;$script:Records=@($real.registros)
 foreach($r in $script:Records){[void](Initialize-RecordDefaults $r)}
 Check 'real database approved decisions pass semantic validation' @(Get-PendenciasSemanticasBase $script:Records).Count 0
}
Write-Output "Synthetic persistence artifacts: $testRoot"
# Recuperação seletiva prepara um merge sem alterar lançamentos/configuração em memória.
$script:Records=@((New-TestRecord 1 'TESTE'));$script:HistoricoFerias=@()
$beforeRecords=$script:Records|ConvertTo-Json -Depth 15 -Compress
$beforeConfig=$script:Config|ConvertTo-Json -Depth 15 -Compress
$histDb=[pscustomobject]@{configuracoes=[pscustomobject]@{};registros=@();historico_ferias=@((New-HistoryFixture '2024-01-01' '2024-01-15'),([pscustomobject]@{matricula='EXCLUIDO';inicio='2024-01-01';fim='2024-01-15'}))}
$plan=Get-PlanoRecuperacaoHistorico $histDb
Check 'selective recovery includes linked historical record' $plan.merge.adicionados 1
Check 'selective recovery skips removed employee' $plan.sem_vinculo 1
Check 'selective recovery plan preserves current records' (($script:Records|ConvertTo-Json -Depth 15 -Compress) -eq $beforeRecords) $true
Check 'selective recovery plan preserves configuration' (($script:Config|ConvertTo-Json -Depth 15 -Compress) -eq $beforeConfig) $true
Check 'selective recovery plan does not apply itself' $script:HistoricoFerias.Count 0
# Relatório nominal inclui compromissos bloqueados antigos e escapa dados para JavaScript.
$reportRec=New-TestRecord 1 'REL';$reportRec.ferias_bloqueadas=$true;$reportRec.opcao_aprovada=1
$reportRec.nome='Sintetico </script><script>teste</script>'
$script:Records=@($reportRec)
$script:GeneratedReport=''
function Start-Process {param([string]$FilePath) $script:GeneratedReport=$FilePath}
# Os blocos extraídos não têm caminho de script; apenas redirecionar saída de arquivo para a pasta de teste.
$script:ReportTestRoot=$testRoot
$reportDefinition=(Get-Command Show-RelatorioAceitesEnfermagem).Definition.Replace('$PSScriptRoot','$script:ReportTestRoot')
Set-Item function:Show-RelatorioAceitesEnfermagem ([scriptblock]::Create($reportDefinition))
Show-RelatorioAceitesEnfermagem
if(-not $script:GeneratedReport){throw [System.Windows.Forms.MessageBox]::LastMessage}
Check 'nominal report generated' ([bool]$script:GeneratedReport) $true
$html=[IO.File]::ReadAllText($script:GeneratedReport)
Check 'nominal report contains legacy blocked employee' ($html -match '"matricula":"REL"') $true
Check 'nominal report escapes injected closing script' ($html -notmatch 'Sintetico </script>') $true
# Worker real de leitura deve reproduzir o cálculo síncrono para todos os meses.
$script:PlanejGrupoSelecionado='TODOS';$script:PlanejSetoresSelecionados=@();$script:PlanejPeriodosSelecionados=@()
$script:cmbPlanejChefia=[pscustomobject]@{SelectedItem='TODOS'}
$filtro=[pscustomobject]@{Ano=2027;Mes=0;Situacao='TODAS AS LINHAS';Busca='';Sobreposicao=$false;Grupo='TODOS';Chefia='TODOS';Setores=@();Periodos=@()}
$syncModel=Get-PlanejamentoViewModel $filtro
$snapshot=[pscustomobject]@{Config=$script:Config;Registros=@($script:Records);Filtro=$filtro;Hash='teste';Culture='pt-BR';UICulture='pt-BR'}
$job=New-PlanejamentoComputation -Json ($snapshot|ConvertTo-Json -Depth 20 -Compress)
try{
 if(-not $job.Handle.AsyncWaitHandle.WaitOne(60000)){throw 'Worker não concluiu em 60 segundos.'}
 $out=$job.PowerShell.EndInvoke($job.Handle)
 if($job.PowerShell.Streams.Error.Count){throw ($job.PowerShell.Streams.Error|Out-String)}
 Check 'worker returns one result' $out.Count 1
 foreach($mm in 1..12){Check "worker monthly total parity $mm" $out[0].Meses[$mm].qtd $syncModel.Meses[$mm].qtd}
 Check 'worker preserves source record properties' ($script:Records[0].PSObject.Properties.Name -notcontains '__PlanejIndiceInternoR3') $true
}finally{$job.PowerShell.Dispose();$job.Runspace.Dispose()}
# Filtros de ano/setor/período incorporam metadados existentes apenas no histórico.
function New-FakeCombo($selected='TODOS'){
 [pscustomobject]@{SelectedItem=$selected;SelectedIndex=0;Items=[Collections.ArrayList]::new()}
}
$script:cmbHistAno=New-FakeCombo '2027';$script:cmbHistSetor=New-FakeCombo;$script:cmbHistPeriodo=New-FakeCombo
$script:HistoricoFerias=@([pscustomobject]@{matricula='H';inicio='2027-01-01';fim='2027-01-15';ano=2027;mes=1;setor_origem='SETOR HISTORICO';periodo_origem='N'})
Refresh-HistoricoFiltrosListas
Check 'year filter includes imported 2027' $script:cmbHistAno.Items.Contains('2027') $true
Check 'sector filter includes history-only metadata' $script:cmbHistSetor.Items.Contains('SETOR HISTORICO') $true
Check 'period filter includes history-only metadata' $script:cmbHistPeriodo.Items.Contains('N') $true
# Sincronização interativa não oferece sobrescrita das datas de um compromisso bloqueado.
Load-Database
$script:Records[0].ferias_bloqueadas=$true;$script:Records[0].opcao_aprovada=1
$script:Config.planilha_base=Join-Path $testRoot 'planilha-teste.xlsx'
[IO.File]::WriteAllText($script:Config.planilha_base,'placeholder; leitura simulada pelo teste')
Save-Database|Out-Null
$script:SyncIncoming=($script:Records[0]|ConvertTo-Json -Depth 15|ConvertFrom-Json)
$script:SyncIncoming.opcao1.inicio1='2027-02-01';$script:SyncIncoming.opcao1.fim1='2027-03-02'
$script:SyncIncoming|Add-Member NoteProperty layout_planilha 'LEGADO' -Force
function Read-XlsmBase {param($path) return $script:SyncIncoming}
$script:OptionOverwritePrompts=0
function Show-SyncDivergenciasDialog {param($divergencias) $script:OptionOverwritePrompts++;return 'APLICAR'}
function Refresh-SetorPeriodos {}
function Refresh-CadastrosLists {}
function Refresh-Grid {}
function Refresh-Dashboard {}
function Refresh-PlanejamentoSetor {}
function Refresh-ConfigInfo {}
function Refresh-ImportacaoStatus {}
Sync-FromBase $false
Check 'sync preserves blocked vacation dates' $script:Records[0].opcao1.inicio1 '2027-01-01'
Check 'sync does not offer overwrite for blocked dates' $script:OptionOverwritePrompts 0
Check 'sync preserves blocked status' $script:Records[0].ferias_bloqueadas $true
# Dados reais: plano de recuperação somente leitura e paridade do worker em 237 registros.
if($RealData){
 $real=Get-Content -LiteralPath $RealData -Raw|ConvertFrom-Json
 $script:Config=$real.configuracoes;$script:Records=@($real.registros);$script:HistoricoFerias=@($real.historico_ferias)
 foreach($r in $script:Records){[void](Initialize-RecordDefaults $r)}
 $backupPath=Join-Path (Split-Path (Split-Path $RealData -Parent) -Parent) 'Backups/ANTES_RESET_HISTORICO_20261021_100540_474.json'
 if(Test-Path -LiteralPath $backupPath){
  $backup=Get-Content -LiteralPath $backupPath -Raw|ConvertFrom-Json
  $beforeRecords=$script:Records|ConvertTo-Json -Depth 15 -Compress
  $plan=Get-PlanoRecuperacaoHistorico $backup
  Check 'actual pre-reset history fully recoverable in plan' $plan.merge.adicionados 413
  Check 'actual recovery plan has no overlaps' $plan.merge.divergencias 0
  Check 'actual recovery plan does not alter 237 current records' (($script:Records|ConvertTo-Json -Depth 15 -Compress) -eq $beforeRecords) $true
  Check 'actual recovery plan does not apply history without confirmation' $script:HistoricoFerias.Count 0
 }
}
# Leitura usa o calendário configurado no Excel, sem deslocamento silencioso de 1.462 dias.
# Restaurar o leitor original após o teste de sincronização com leitura simulada.
$readerAst=$ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -eq 'Read-XlsmBase'}|Select-Object -First 1
. ([scriptblock]::Create($readerAst.Extent.Text))
foreach($mode in @(1900,1904)){
 $parsed=@(Read-XlsmBase (Join-Path $PSScriptRoot "fixtures/base-$mode.xlsx"))
 Check "Excel $mode row read" $parsed.Count 1
 Check "Excel $mode aquisitive start" $parsed[0].aquisitivo_inicio '2026-01-01'
 Check "Excel $mode aquisitive end" $parsed[0].aquisitivo_fim '2026-12-31'
 Check "Excel $mode vacation start" $parsed[0].opcao1.inicio1 '2027-01-01'
 Check "Excel $mode vacation end" $parsed[0].opcao1.fim1 '2027-01-30'
}
$badRow=[pscustomobject]@{valido=$false;erro='Nenhuma célula amarela encontrada em K/L/M';matricula='TESTE';nome='Servidor teste';ano_referencia=2027}
$badPreview=@(Get-PreviewHistorico @($badRow))
Check 'history preview retains unreadable row for audit' $badPreview.Count 1
Check 'unreadable row cannot be imported' $badPreview[0].preview_status 'ERRO DE LEITURA'
$badPreview=@(Get-PreviewFixas2027 @($badRow))
Check 'fixed preview retains unreadable row for audit' $badPreview.Count 1
if($RealData){
 $syncModel=Get-PlanejamentoViewModel $filtro
 $snapshot=[pscustomobject]@{Config=$script:Config;Registros=@($script:Records);Filtro=$filtro;Hash='actual-readonly-test';Culture='pt-BR';UICulture='pt-BR'}
 $job=New-PlanejamentoComputation -Json ($snapshot|ConvertTo-Json -Depth 20 -Compress)
 try{
  if(-not $job.Handle.AsyncWaitHandle.WaitOne(60000)){throw 'Worker com base real não concluiu em 60 segundos.'}
  $out=$job.PowerShell.EndInvoke($job.Handle)
  if($job.PowerShell.Streams.Error.Count){throw ($job.PowerShell.Streams.Error|Out-String)}
  Check 'actual database worker returns one result' $out.Count 1
  foreach($mm in 1..12){Check "actual database worker monthly parity $mm" $out[0].Meses[$mm].qtd $syncModel.Meses[$mm].qtd}
 }
 finally{$job.PowerShell.Dispose();$job.Runspace.Dispose()}
}
$fixedCandidate=[pscustomobject]@{tipo='FÉRIAS FIXAS';blocos_fixos=@([pscustomobject]@{inicio=[datetime]'2027-01-01';fim=[datetime]'2027-01-15'},[pscustomobject]@{inicio=[datetime]'2027-03-01';fim=[datetime]'2027-03-15'})}
Check 'fixed simulation preserves additional blocks' @(Get-OptionBlocksObjeto (Get-OpcaoSimulacaoRegistro (New-TestRecord 1 'FIX') $fixedCandidate)).Count 2
[xml]$fgDoc='<fgColor rgb="FFFFFF00" tint="-1"/>'
Check 'black tinted yellow is not a yellow marker' (Test-CorAmarelaRelatorio $fgDoc.DocumentElement $null $null) $false
Write-Output "COMPLETE: $checks assertions passed."
