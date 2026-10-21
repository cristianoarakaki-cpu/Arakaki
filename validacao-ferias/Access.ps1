param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'),[string]$Output='')
$ErrorActionPreference='Stop'
$t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $a.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
$checks=0
function Check($name,$actual,$expected){if($actual -cne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;Write-Output "PASS $name"}
function Row($mat,$cp,$tipo='30 DIAS'){
 [pscustomobject]@{matricula=$mat;nome='CONCEIÇÃO & SÁ';cp_relatorio=$cp;ferias_bloqueadas=$false;opcao_aprovada=1;fr_opcao_aprovada=0;aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';observacoes='';opcao1=[pscustomobject]@{tipo=$tipo;inicio1='2027-01-01';fim1='2027-01-30';inicio2='';fim2='';fr_inicio='';fr_fim=''}}
}
$script:HistoricoFerias=@();$r=Row 'A' '1323';$script:Records=@($r)
$d=Get-ExportacaoAceitasAccess
Check 'accepted ordinary row' $d.Linhas.Count 1
Check 'exact 13 Access columns without identity' $d.Cabecalhos.Count 13
Check 'CP not matricula' $d.Linhas[0].'Codigo do Servidor' 1323
Check 'schedule after plus 2' $d.Linhas[0].'Agendar Após'.ToString('yyyy-MM-dd') '2026-01-02'
Check 'year editable numeric zero' $d.Linhas[0].Programacao_Ano 0
Check 'ordinary not 20 days' $d.Linhas[0].Processo_20Dias 0
$r.opcao_aprovada=0;Check 'pending excluded' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.opcao_aprovada=1;$r.cp_relatorio='';$d=Get-ExportacaoAceitasAccess
Check 'missing CP not exported' $d.Linhas.Count 0
Check 'missing CP audited' $d.Pendencias.Count 1
$script:HistoricoFerias=@([pscustomobject]@{matricula='A';cp_relatorio='1323'})
Check 'CP from exact history matricula' (Get-ExportacaoAceitasAccess).Linhas.Count 1
$r.cp_relatorio='999';Check 'conflicting CP blocked' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.cp_relatorio='1323';$r.opcao1.tipo='15+15 DIAS';$r.opcao1.fim1='2027-01-15';$r.opcao1.inicio2='2028-01-01';$r.opcao1.fim2='2028-01-15'
$d=Get-ExportacaoAceitasAccess
Check 'split vacation one row across years' $d.Linhas.Count 1
Check 'first 15 day start' $d.Linhas[0].Ferias_Par_1QIn.ToString('yyyy-MM-dd') '2027-01-01'
Check 'second 15 day start' $d.Linhas[0].Ferias_Par_2QIn.ToString('yyyy-MM-dd') '2028-01-01'
Check 'split has empty 30 day field' ($null -eq $d.Linhas[0].Ferias_30_Inicio) $true
$r.fr_opcao_aprovada=1;$r.opcao1.fr_inicio='2027-03-01';$r.opcao1.fr_fim='2027-03-20';$d=Get-ExportacaoAceitasAccess
Check 'independent FR row' $d.Linhas.Count 2
$fr=@($d.Linhas | Where-Object {$_.Processo_20Dias -eq -1})[0]
Check 'FR true flag' $fr.Processo_20Dias -1
Check 'FR dates in single period fields' $fr.Ferias_30_Final.ToString('yyyy-MM-dd') '2027-03-20'
$r.opcao_aprovada=0;Check 'FR accepted alone' (Get-ExportacaoAceitasAccess).Linhas.Count 1
$r.fr_opcao_aprovada=0;$r.ferias_bloqueadas=$true;Check 'fixed without explicit approval excluded' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.opcao_aprovada=1;$r.fr_opcao_aprovada=1
$r.opcao1.fim2='2028-01-14';$d=Get-ExportacaoAceitasAccess
Check 'invalid common does not suppress accepted FR' $d.Linhas.Count 1
Check 'invalid split audited' $d.Pendencias.Count 1
$r.opcao1.fim2='2028-01-15';$r.observacoes=('x'*256);Check 'long observation not silently truncated' (Get-ExportacaoAceitasAccess).Linhas.Count 0
$r.observacoes='Texto =1+1 & <teste>';$d=Get-ExportacaoAceitasAccess
$script:Records=@($r,$r);Check 'identical accepted entries deduplicated' (Get-ExportacaoAceitasAccess).Linhas.Count 2
$other=Row 'A' '1323';$other.opcao1.inicio1='2027-04-01';$other.opcao1.fim1='2027-04-30';$script:Records=@($r,$other)
$d=Get-ExportacaoAceitasAccess
Check 'conflicting accepted common entries blocked' @($d.Linhas | Where-Object {$_.Processo_20Dias -eq 0}).Count 0
Check 'both conflicts audited' $d.Pendencias.Count 2
$script:Records=@($r);$d=Get-ExportacaoAceitasAccess
$missing=Row 'B' '';$script:Records+=@($missing);$d=Get-ExportacaoAceitasAccess
if(-not $Output){$Output=Join-Path ([IO.Path]::GetTempPath()) ('access-test-'+[guid]::NewGuid().ToString('N')+'.xlsx');$remove=$true}else{$remove=$false}
try{
 Write-ExcelAceitasAccess $Output $d
 $z=[IO.Compression.ZipFile]::OpenRead($Output)
 try{foreach($entry in $z.Entries){$reader=New-Object IO.StreamReader($entry.Open());try{[xml]$xml=$reader.ReadToEnd()}finally{$reader.Dispose()}};Check 'XLSX 3 sheet package complete' $z.Entries.Count 8}finally{$z.Dispose()}
}finally{if($remove -and (Test-Path $Output)){Remove-Item -LiteralPath $Output -Force}}
Write-Output "ACCESS_COMPLETE assertions=$checks"
