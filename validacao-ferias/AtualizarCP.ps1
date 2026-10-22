param([string]$Updater=(Join-Path $PSScriptRoot '../Atualizar_Nomes_CP.ps1'))
$ErrorActionPreference='Stop'
foreach($source in @($Updater,(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))){
 $t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$t,[ref]$e)
 if($e.Count){throw ($e -join "`n")}
 foreach($f in $a.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
}
$checks=0
function Check($name,$ok){if(-not $ok){throw $name};$script:checks++;Write-Output "PASS $name"}
$root=Join-Path ([IO.Path]::GetTempPath()) ('test-cp-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory((Join-Path $root 'Dados'))
$dbPath=Join-Path $root 'Dados/ferias_2027.json';$xlsx=Join-Path $root 'cadastro.xlsx'
$db=[ordered]@{versao='teste';revisao_dados=10;ultima_gravacao_utc='2026-01-01T00:00:00Z';configuracoes=@{limite=3};registros=@([ordered]@{id=1;matricula='00123';nome='Antigo';cp_relatorio='';aquisitivo_inicio='2025-01-01';opcao1=@{inicio1='2027-01-01';fim1='2027-01-30'};opcao_aprovada=1;fr_opcao_aprovada=0;observacoes='PRESERVAR'},[ordered]@{id=2;matricula='00123';nome='Antigo 2';cp_relatorio='99';opcao2=@{inicio1='2028-01-01'};opcao_aprovada=2});historico_ferias=@(@{matricula='00123';nome='NOME HISTÓRICO';inicio='2024-01-01'})}
$raw=$db|ConvertTo-Json -Depth 30
function SaveFixture($rows){Write-ExcelAceitasAccess -Path $xlsx -Dados ([pscustomobject]@{Cabecalhos=@('CP','Matricula','Nome');Linhas=@($rows);Pendencias=@()})}
try{
 [IO.File]::WriteAllText($dbPath,$raw,[Text.UTF8Encoding]::new($true))
 SaveFixture @([pscustomobject]@{CP=123;Matricula='00123';Nome='Conceição de Sá'})
 $map=Read-MapaNomesCP $xlsx
 Check 'zeros iniciais na chave exata' ($map.ContainsKey('00123') -and -not $map.ContainsKey('123'))
 $r=Update-BaseNomesCP $xlsx $dbPath
 $updated=Get-Content -LiteralPath $dbPath -Raw -Encoding UTF8|ConvertFrom-Json
 Check 'todos os aquisitivos atualizados' ($r.registros -eq 2 -and $r.servidores -eq 1)
 Check 'nomes corrigidos em todos' ($r.nomes_corrigidos -eq 2)
 Check 'CPs corrigidos em todos' ($r.cps_atualizados -eq 2)
 Check 'nome autorizado preserva acentos e caixa da fonte' (@($updated.registros|Where-Object {$_.nome -cne 'Conceição de Sá'}).Count -eq 0)
 Check 'CP salvo como string' ($updated.registros[0].cp_relatorio -is [string] -and $updated.registros[0].cp_relatorio -eq '123')
 Check 'decisoes e datas preservadas' ($updated.registros[0].opcao_aprovada -eq 1 -and $updated.registros[1].opcao_aprovada -eq 2 -and $updated.registros[0].opcao1.inicio1 -eq '2027-01-01')
 Check 'observacoes preservadas' ($updated.registros[0].observacoes -eq 'PRESERVAR')
 Check 'historico preservado integralmente' ($updated.historico_ferias[0].nome -ceq 'NOME HISTÓRICO')
 Check 'configuracoes preservadas' ($updated.configuracoes.limite -eq 3)
 Check 'revisao incrementada uma vez' ($updated.revisao_dados -eq 11)
 Check 'backup exato criado antes' ([IO.File]::ReadAllText($r.backup,[Text.Encoding]::UTF8) -ceq $raw)
 Check 'relatorio de cada registro' (@(Import-Csv -LiteralPath $r.relatorio -Delimiter ';').Count -eq 2)
 $first=[IO.File]::ReadAllText($dbPath);$again=Update-BaseNomesCP $xlsx $dbPath
 Check 'reexecucao idempotente sem gravar' ([IO.File]::ReadAllText($dbPath) -ceq $first -and $again.backup -eq '')
 foreach($case in @('matricula ausente','matricula duplicada','CP duplicado','nome vazio','CP invalido')){
  $rows=switch($case){
   'matricula ausente' {@([pscustomobject]@{CP=123;Matricula='123';Nome='Nome'})}
   'matricula duplicada' {@([pscustomobject]@{CP=123;Matricula='00123';Nome='Nome'},[pscustomobject]@{CP=123;Matricula='00123';Nome='Nome'})}
   'CP duplicado' {@([pscustomobject]@{CP=123;Matricula='00123';Nome='Nome'},[pscustomobject]@{CP=123;Matricula='00456';Nome='Nome'})}
   'nome vazio' {@([pscustomobject]@{CP=123;Matricula='00123';Nome=''})}
   'CP invalido' {@([pscustomobject]@{CP=-1;Matricula='00123';Nome='Nome'})}
  }
  SaveFixture $rows;$blocked=$false
  try{Update-BaseNomesCP $xlsx $dbPath|Out-Null}catch{$blocked=$true}
  Check "bloqueia $case sem alteracao parcial" ($blocked -and [IO.File]::ReadAllText($dbPath) -ceq $first)
 }
 SaveFixture @([pscustomobject]@{CP=123;Matricula='00123';Nome='Outro nome'})
 $lock=[IO.File]::Open((Join-Path $root 'Dados/ferias_2027.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{$blocked=$false;try{Update-BaseNomesCP $xlsx $dbPath|Out-Null}catch{$blocked=$true};Check 'gravação concorrente bloqueada' ($blocked -and [IO.File]::ReadAllText($dbPath) -ceq $first)}finally{$lock.Dispose()}
 Write-Output "UPDATER_COMPLETE assertions=$checks"
}finally{Remove-Item -LiteralPath $root -Recurse -Force}
