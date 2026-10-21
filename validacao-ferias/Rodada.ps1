param([int]$Seed=1,[string]$Culture='pt-BR',[string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'),[string]$RealData='')
$ErrorActionPreference='Stop'
[Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($Culture)
[Threading.Thread]::CurrentThread.CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo($Culture)
Write-Output "ROUND seed=$Seed culture=$Culture"
. (Join-Path $PSScriptRoot 'Base.ps1') -Source $Source -RealData $RealData
# Exercitar as próprias chamadas de avaliação da tela, com o contexto original disponível.
$script:Config=[pscustomobject]@{setores=@('SETOR TESTE');periodos=@('M');max_simultaneos=3;total_enfermeiros_planejamento=6;meses_restritos=@();limites_especiais_mensais=@{};grupo_analise_setores=@();grupo_chefia_setores=@();grupo_chefia_servidores=@();grupos_chefia=@();limites_setor_periodo=@();limites_grupo_chefia_periodo=@();historico_3_anos_importado=$false}
$r=New-TestRecord 101 'CENTRAL'
$r.opcao1.inicio1='2027-07-21';$r.opcao1.fim1='2027-08-19'
$r.opcao1.fr_inicio='2027-07-01';$r.opcao1.fr_fim='2027-07-20';$r.fr_opcao_aprovada=1
$script:Records=@($r);$n=1;$op=Get-OpcaoSomenteComum $r.opcao1
$cloneComum=($r|ConvertTo-Json -Depth 15|ConvertFrom-Json)
foreach($k in 1..3){$cloneComum."opcao$k".fr_inicio='';$cloneComum."opcao$k".fr_fim=''}
$commonCall=$ast.FindAll({param($x)$x -is [Management.Automation.Language.AssignmentStatementAst] -and $x.Left.Extent.Text -eq '$aval' -and $x.Right.Extent.Text -like 'Get-AvaliacaoOpcaoRegistro *'},$true)|Select-Object -First 1
if(-not $commonCall){throw 'Chamada real de aprovação comum não localizada.'}
$av=& ([scriptblock]::Create($commonCall.Right.Extent.Text))
Check 'common approval callback retains confirmed FR in evaluation' $av.alertas_institucionais 2
# Para FR na mesma opção aprovada, o contexto comum precisa continuar disponível.
$r.opcao1.inicio1='2027-06-16';$r.opcao1.fim1='2027-07-15';$r.opcao1.fr_inicio='2027-07-16';$r.opcao1.fr_fim='2027-08-04';$r.opcao_aprovada=1;$r.fr_opcao_aprovada=0
$other=New-TestRecord 102 'OUTRO';$other.opcao1.inicio1='2027-06-16';$other.opcao1.fim1='2027-07-15';$other.opcao_aprovada=1
$script:Records=@($r,$other)
$script:Config.limites_setor_periodo=@([pscustomobject]@{setor='SETOR TESTE';periodo='M';limite=1})
$somenteFR=New-EmptyOptionObject;$somenteFR.tipo='FR 20 DIAS';$somenteFR.fr_inicio=$r.opcao1.fr_inicio;$somenteFR.fr_fim=$r.opcao1.fr_fim
$cloneFR=($r|ConvertTo-Json -Depth 15|ConvertFrom-Json);$cloneFR.opcao1=$somenteFR
$frCall=$ast.FindAll({param($x)$x -is [Management.Automation.Language.AssignmentStatementAst] -and $x.Left.Extent.Text -eq '$avaliacaoFR' -and $x.Right.Extent.Text -like 'Get-AvaliacaoOpcaoRegistro *'},$true)|Select-Object -First 1
if(-not $frCall){throw 'Chamada real de aprovação FR não localizada.'}
$av=& ([scriptblock]::Create($frCall.Right.Extent.Text))
Check 'FR approval callback retains common approved in same option' ($av.criticos -ge 1) $true
# Cenários variados com oráculo por enumeração de dias, independente do algoritmo sob teste.
$rng=[Random]::new($Seed)
for($case=1;$case -le 40;$case++){
 $year=$rng.Next(2024,2030);$month=$rng.Next(1,13)
 $start=[datetime]::new($year,$month,1)
 $rows=@();$expected=[Collections.Generic.HashSet[int]]::new()
 for($j=0;$j -lt $rng.Next(1,7);$j++){
  $ini=$start.AddDays($rng.Next(-15,25));$fim=$ini.AddDays($rng.Next(0,31))
  $rows+=[pscustomobject]@{matricula='FUZZ';inicio=$ini.ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture);fim=$fim.ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture);ano=$ini.Year;mes=$ini.Month;dias=($fim-$ini).Days+1;aquisitivo_inicio='2023-01-01';aquisitivo_fim='2023-12-31'}
  for($d=$ini;$d -le $fim;$d=$d.AddDays(1)){if($d.Year -eq $year -and $d.Month -eq $month){[void]$expected.Add($d.Day)}}
 }
 Check "random $case unique-day oracle" (Get-HistoricoDiasUnicosMes $rows $year $month) $expected.Count
 Check "random $case threshold oracle" (Test-HistoricoMesContaDesempate $rows $year $month) ($expected.Count -ge 15)
 $reversed=@($rows);[array]::Reverse($reversed)
 Check "random $case input order invariant" (Get-HistoricoDiasUnicosMes $reversed $year $month) $expected.Count
 $opIni=$start.AddDays($rng.Next(0,28));$duration=@(15,20,30)[$rng.Next(0,3)];$opFim=$opIni.AddDays($duration-1)
 $byMonth=@{}
 for($d=$opIni;$d -le $opFim;$d=$d.AddDays(1)){
  $key=($d.Year*100)+$d.Month
  if(-not $byMonth.ContainsKey($key)){$byMonth[$key]=0};$byMonth[$key]++
 }
 $best=$byMonth.Keys|Sort-Object @{Expression={$byMonth[$_]};Descending=$true},@{Expression={[int]$_}}|Select-Object -First 1
 foreach($key in $byMonth.Keys){
  $yy=[int][math]::Floor($key/100);$mm=[int]($key%100)
  $weight=if($duration -eq 30){if($byMonth[$key] -ge 15){1.0}else{0.0}}elseif($key -eq $best){if($duration -eq 15){0.5}else{1.0}}else{0.0}
  Check "random $case weight oracle $key" (Get-PesoBlocoInstitucionalMes $opIni $opFim $yy $mm) $weight
 }
}
Write-Output "ROUND_COMPLETE seed=$Seed culture=$Culture assertions=$checks"
