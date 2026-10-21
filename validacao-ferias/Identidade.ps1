param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors -join "`n")}
foreach($f in $ast.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
function Assert($ok,$message){if(-not $ok){throw $message};Write-Output "PASS $message"}
function Write-DiagLog {}
$script:Records=@([pscustomobject]@{matricula='129457022';nome='DAIANE SOUZA ALENCAR ROMERO'})
function MakeRow($name,$mat='129457022'){
 [pscustomobject]@{matricula=$mat;nome=$name;linha=42;valido=$true;cargo='ENFERMEIRO';ano_referencia=2026;mes_referencia=12;aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';ferias_inicio='2026-12-01';ferias_fim='2026-12-15'}
}
$r=MakeRow 'Daiane Souza Alencar'
$p=@(Get-PreviewHistorico @($r))[0]
Assert ($p.preview_status -eq 'NOME DIVERGENTE') 'divergencia explicitamente identificada'
Assert ($p.nome_cadastro -eq 'DAIANE SOUZA ALENCAR ROMERO') 'nome real do cadastro disponivel'
Assert ($p.matricula_encontrada -eq '129457022') 'matricula encontrada visivel para conferencia'
Assert ($p.matricula_sistema -eq '') 'divergencia nao cria vinculo importavel'
Assert ($p.preview_detalhe.Contains('42') -and $p.preview_detalhe.Contains('ROMERO')) 'motivo inclui linha e nome divergente'
$p=@(Get-PreviewHistorico @((MakeRow 'Daiane Souza Alencar Romero')))[0]
Assert ($p.preview_status -eq 'IMPORTAR') 'mesmo nome com caixa diferente e aceito'
$p=@(Get-PreviewHistorico @((MakeRow 'Daiane Souza Alencar Romero' '999')))[0]
Assert ($p.preview_status -eq 'SEM VÍNCULO' -and -not $p.nome_cadastro) 'matricula ausente distinguida de nome divergente'
$script:LogDir=Join-Path ([IO.Path]::GetTempPath()) ('ferias-identidade-'+[guid]::NewGuid().ToString('N'))
try{
 $csv=Exportar-RejeitadosImportacao 'TESTE' @($r) @('IMPORTAR')
 $audit=Import-Csv -LiteralPath $csv -Delimiter ';'
 Assert ($audit.Nome_Cadastro -eq 'DAIANE SOUZA ALENCAR ROMERO' -and $audit.Linha_Planilha -eq '42') 'CSV inclui ambos os nomes e linha'
}finally{if(Test-Path $script:LogDir){Remove-Item -LiteralPath $script:LogDir -Recurse -Force}}
