param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'),[string]$Culture='pt-BR',[int]$Seed=1,[string]$RealData='',[string]$OutputDir='')
$ErrorActionPreference='Stop'
[Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($Culture)
$t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $a.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
$script:checks=0
function Check($name,$actual,$expected){if($actual -cne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;"PASS $name"}
function New-Employee($mat,$cp){
 [pscustomobject]@{matricula=$mat;nome='TESTE & <SEM DADOS REAIS>';cp_relatorio=$cp;ferias_bloqueadas=$false;opcao_aprovada=1;fr_opcao_aprovada=0;aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';observacoes="Observação & <texto> 'aspas'`nsegunda linha";opcao1=[pscustomobject]@{tipo='30 DIAS';inicio1='2027-01-01';fim1='2027-01-30';inicio2='';fim2='';fr_inicio='';fr_fim=''}}
}
# Simular explicitamente a ausencia de Count no PSCustomObject do Windows PowerShell 5.1.
$exportAst=$a.EndBlock.Statements | Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -eq 'Get-ExportacaoAceitasAccess'}
$blockAssignment=$exportAst.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$blocks'},$true)[0]
Check 'interval assignment keeps outer array expression' ($blockAssignment.Right.Extent.Text.Trim().StartsWith('@(')) $true
$sim=$exportAst.Extent.Text.Replace('function Get-ExportacaoAceitasAccess {','function Test-ExportacaoCount51 {').Replace('$blocks.Count','$(if($blocks -is [array]){$blocks.Count}else{$null})')
. ([scriptblock]::Create($sim))
$script:HistoricoFerias=@()
foreach($n in 1..3){
 $case=New-Employee '000001' '1323'
 if($n -gt 1){$case | Add-Member NoteProperty ("opcao$n") ($case.opcao1 | ConvertTo-Json | ConvertFrom-Json)}
 $case.opcao_aprovada=$n
 $case.("opcao$n").inicio1='2027-02-15';$case.("opcao$n").fim1='2027-03-16'
 $script:Records=@($case);$d=Test-ExportacaoCount51
 Check 'PS51 modeled single interval with accepted option' $d.Linhas.Count 1
 Check 'inclusive thirty days across February' $d.Linhas[0].Ferias_30_Final.ToString('yyyy-MM-dd') '2027-03-16'
}
$case.opcao3.fim1='2027-03-15';$d=Get-ExportacaoAceitasAccess
Check 'true invalid interval remains blocked' $d.Linhas.Count 0
Check 'invalid interval names approved option' ($d.Pendencias[0].Motivo -match 'opcao aceita 3') $true
Check 'invalid interval includes detected inclusive duration' ($d.Pendencias[0].Motivo -match '29 dias inclusivos') $true
$script:HistoricoFerias=@();$r=New-Employee '000001' '1323';$script:Records=@($r)
$d=Get-ExportacaoAceitasAccess
Check 'approved ordinary row' $d.Linhas.Count 1
Check 'exact table fields count' $d.Cabecalhos.Count 13
Check 'no autonumber field' ($d.Cabecalhos -contains 'ID_Ferias') $false
Check 'CP is server code' $d.Linhas[0].'Codigo do Servidor' 1323
Check 'schedule plus 2 days' $d.Linhas[0].'Agendar Após'.ToString('yyyy-MM-dd') '2026-01-02'
Check 'year zero preserved' $d.Linhas[0].Programacao_Ano 0
$r.opcao_aprovada=0;Check 'pending excluded' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.opcao_aprovada=1;$r.ferias_bloqueadas=$true;Check 'fixed even if approved excluded' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.ferias_bloqueadas=$false;$r.cp_relatorio='';$d=Get-ExportacaoAceitasAccess
Check 'missing CP blocks row' $d.Linhas.Count 0
Check 'missing CP audited' $d.Pendencias.Count 1
$r.cp_relatorio='1323';$other=New-Employee '000002' '001323';$script:Records=@($r,$other);$d=Get-ExportacaoAceitasAccess
Check 'normalized CP shared by different matriculas blocked' $d.Linhas.Count 0
Check 'both shared CP employees audited' $d.Pendencias.Count 2
$script:Records=@($r,$r);Check 'same employee identical rows deduplicated' (Get-ExportacaoAceitasAccess).Linhas.Count 1
$other=New-Employee '000001' '1323';$other.opcao1.inicio1='2027-02-01';$other.opcao1.fim1='2027-03-02';$script:Records=@($r,$other);$d=Get-ExportacaoAceitasAccess
Check 'same CP acquisition divergent dates blocks both' $d.Linhas.Count 0
Check 'divergent dates audit both' $d.Pendencias.Count 2
$script:Records=@($r);$r.opcao1.tipo='15+15 DIAS';$r.opcao1.fim1='2027-01-15';$r.opcao1.inicio2='2028-02-15';$r.opcao1.fim2='2028-02-29';$r.fr_opcao_aprovada=1;$r.opcao1.fr_inicio='2027-03-01';$r.opcao1.fr_fim='2027-03-20'
$d=Get-ExportacaoAceitasAccess
Check 'split and independent FR exported' $d.Linhas.Count 2
Check 'FR is true value minus one' @($d.Linhas | Where-Object Processo_20Dias -eq -1).Count 1
Check 'ordinary zero flag' @($d.Linhas | Where-Object Processo_20Dias -eq 0).Count 1
$before=$script:Records | ConvertTo-Json -Depth 20 -Compress
if(-not $OutputDir){$OutputDir=Join-Path ([IO.Path]::GetTempPath()) ('ferias-access-'+[guid]::NewGuid().ToString('N'));$remove=$true}else{$remove=$false}
[void][IO.Directory]::CreateDirectory($OutputDir)
try{
 $file=Join-Path $OutputDir 'teste.xml';Write-ArquivoImportacaoFeriasAccess $file $d
 $xml=[xml][IO.File]::ReadAllText($file)
 Check 'root contract version' $xml.FeriasDCE.versao '1'
 Check 'two rows serialized' $xml.FeriasDCE.Registros.Registro.Count 2
 foreach($row in $xml.FeriasDCE.Registros.Registro){
  Check 'thirteen XML fields' $row.Campo.Count 13
  Check 'null dates explicitly represented' @($row.Campo | Where-Object nulo -eq '1').Count $(if(@($row.Campo | Where-Object nome -eq 'Processo_20Dias')[0].InnerText -eq '-1'){4}else{2})
  Check 'observation roundtrip including quotes newline unicode' @($row.Campo | Where-Object nome -eq 'Observação')[0].InnerText $r.observacoes
 }
 Check 'XML has no DTD' ([IO.File]::ReadAllText($file) -match '<!DOCTYPE') $false
 Check 'no JSON mutation' ($script:Records | ConvertTo-Json -Depth 20 -Compress) $before
 Write-ExcelAceitasAccess (Join-Path $OutputDir 'teste.xlsx') $d
 Check 'old Excel export remains available' (Test-Path -LiteralPath (Join-Path $OutputDir 'teste.xlsx')) $true
 # Randomized export data exercises dates and CPs across locales.
 $random=[Random]::new($Seed)
 for($j=0;$j -lt 20;$j++){
  $emp=New-Employee ([string](1000+$j)) ([string](2000+$j));$start=[datetime]'2027-01-01';$start=$start.AddDays($random.Next(0,600))
  $emp.opcao1.inicio1=$start.ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture);$emp.opcao1.fim1=$start.AddDays(29).ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  $script:Records=@($emp);$d=Get-ExportacaoAceitasAccess;Write-ArquivoImportacaoFeriasAccess $file $d;$x=[xml][IO.File]::ReadAllText($file)
  Check 'random vacation dates remain ISO' @($x.FeriasDCE.Registros.Registro.Campo | Where-Object nome -eq 'Ferias_30_Inicio')[0].InnerText $emp.opcao1.inicio1
 }
 if($RealData){
  $hash=(Get-FileHash -LiteralPath $RealData -Algorithm SHA256).Hash
  $obj=Get-Content -LiteralPath $RealData -Raw -Encoding UTF8 | ConvertFrom-Json
  $script:Records=@($obj.registros);$script:HistoricoFerias=@($obj.historico_ferias)
  $prior=$obj|ConvertTo-Json -Depth 100 -Compress
  $d=Get-ExportacaoAceitasAccess
  $simulated=Test-ExportacaoCount51
  Check 'real data Count51 model matches normal valid rows' $simulated.Linhas.Count $d.Linhas.Count
  Check 'real data Count51 model matches normal pending rows' $simulated.Pendencias.Count $d.Pendencias.Count
  Write-ArquivoImportacaoFeriasAccess (Join-Path $OutputDir 'base-enviada.xml') $d
  Check 'source file unchanged on real data' (Get-FileHash -LiteralPath $RealData -Algorithm SHA256).Hash $hash
  Check 'real source objects unchanged' ($obj|ConvertTo-Json -Depth 100 -Compress) $prior
  foreach($row in $d.Linhas){Check 'real row CP positive int' ([int]$row.'Codigo do Servidor' -gt 0) $true}
 }
}finally{if($remove){Remove-Item -LiteralPath $OutputDir -Recurse -Force}}
"EXPORTACAO_COMPLETE assertions=$script:checks culture=$Culture seed=$Seed"
