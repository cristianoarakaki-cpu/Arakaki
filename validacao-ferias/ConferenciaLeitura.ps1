param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))
$ErrorActionPreference='Stop'
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw 'Erro de sintaxe'}
$defs=@($ast.EndBlock.Statements | Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst]})
$report=$defs | Where-Object Name -eq 'Show-RelatorioConferenciaOpcoes'
$capture=$report.Body.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$readSnapshotForReport'},$true)[0].Extent.Text
$call=$report.Body.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$snapshot' -and $n.Right.Extent.Text -like '*$readSnapshotForReport*'},$true)[0].Extent.Text
if(-not $capture -or -not $call){throw 'Callback nao usa referencia capturada'}
$reader=($defs | Where-Object Name -eq 'Read-DatabaseSnapshotWithRetry').Extent.Text
$validator=($defs | Where-Object Name -eq 'Assert-DatabaseStructure').Extent.Text
$m=New-Module -ScriptBlock {param($reader,$validator,$capture,$call)
 . ([scriptblock]::Create($reader));. ([scriptblock]::Create($validator))
 function Write-DiagLog {param($Message,$Level,$ErrorRecord)}
 function New-TestReader($path){
  $dbPathForReport=$path
  . ([scriptblock]::Create($capture))
  $body=[scriptblock]::Create($call+';return $snapshot')
  return $body.GetNewClosure()
 }
 Export-ModuleMember -Function New-TestReader
} -ArgumentList $reader,$validator,$capture,$call
$path=Join-Path ([IO.Path]::GetTempPath()) ('conferencia-'+[guid]::NewGuid().ToString('N')+'.json')
try{
 [IO.File]::WriteAllText($path,'{"configuracoes":{},"registros":[],"historico_ferias":[]}')
 $before=[IO.File]::ReadAllText($path)
 $callback=& $m {param($p) New-TestReader $p} $path
 $snapshot=& $callback
 if($null -eq $snapshot.Db -or $snapshot.Db.registros.Count -ne 0){throw 'Leitura incorreta'}
 'PASS actual report callback reads valid database from closure'
 if([IO.File]::ReadAllText($path) -cne $before){throw 'Base alterada'}
 'PASS report read preserves database bytes'
 [IO.File]::WriteAllText($path,'INVALID JSON')
 $failed=$false
 try{& $callback | Out-Null}catch{if($_.Exception.Message -like '*not recognized*'){throw};$failed=$true}
 if(-not $failed){throw 'JSON invalido foi aceito'}
 'PASS invalid JSON handled without missing command error'
 if([IO.File]::ReadAllText($path) -cne 'INVALID JSON'){throw 'Base invalida alterada'}
 'PASS failed read preserves invalid database'
}finally{Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue;Remove-Module $m -ErrorAction SilentlyContinue}
