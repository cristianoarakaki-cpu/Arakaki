param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'),[string]$Output='')
$ErrorActionPreference='Stop'
$t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $a.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
$checks=0
function Check($name,$actual,$expected){if($actual -cne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;Write-Output "PASS $name"}
$script:Records=@(
 [pscustomobject]@{matricula='00123';nome='Conceição de Sá';opcao_aprovada=0},
 [pscustomobject]@{matricula='00123';nome='CONCEIÇÃO DE SÁ';opcao_aprovada=1},
 [pscustomobject]@{matricula='123';nome='Outro servidor';opcao_aprovada=0},
 [pscustomobject]@{matricula='12345678901234567890';nome='=NOME & <TESTE>';opcao_aprovada=0},
 [pscustomobject]@{matricula='77';nome='ANA'},[pscustomobject]@{matricula='77';nome='MARIA'},
 [pscustomobject]@{matricula='88';nome=''},[pscustomobject]@{matricula='';nome='SEM MATRÍCULA'}
)
$before=$script:Records|ConvertTo-Json -Depth 8 -Compress
$d=Get-ExportacaoListaServidores
Check 'all registered employees irrespective of approval' $d.Linhas.Count 5
Check 'two columns only' ($d.Cabecalhos -join '|') 'Matrícula|Nome'
Check 'duplicate acquisition periods merged by exact matricula' @($d.Linhas|Where-Object {$_.'Matrícula' -ceq '00123'}).Count 1
Check 'leading zeros retained separately from 123' @($d.Linhas|Where-Object {$_.'Matrícula' -ceq '123'}).Count 1
Check 'accent retained and case differences not conflicts' @($d.Pendencias|Where-Object {$_.Matricula -eq '00123'}).Count 0
Check 'names available for same matricula without choosing one' ($d.Linhas|Where-Object {$_.'Matrícula' -eq '77'}).Nome 'ANA / MARIA'
Check 'missing name missing matricula and divergent names audited' $d.Pendencias.Count 3
Check 'long matricula retained as string' (($d.Linhas|Where-Object {$_.'Matrícula' -eq '12345678901234567890'}).'Matrícula' -is [string]) $true
Check 'original database records unchanged' ($script:Records|ConvertTo-Json -Depth 8 -Compress) $before
if(-not $Output){$Output=Join-Path ([IO.Path]::GetTempPath()) ('lista-servidores-'+[guid]::NewGuid().ToString('N')+'.xlsx');$remove=$true}else{$remove=$false}
try{
 Write-ExcelAceitasAccess -Path $Output -Dados $d -NomeAbaPrincipal 'Servidores' -InstrucoesPersonalizadas @('Lista para conferência de matrícula e CP.') -CabecalhosPendencias @('Matricula','Nome','Motivo')
 $z=[IO.Compression.ZipFile]::OpenRead($Output)
 try{
  function ReadPart($name){$reader=New-Object IO.StreamReader($z.GetEntry($name).Open());try{return $reader.ReadToEnd()}finally{$reader.Dispose()}}
  [xml]$wb=ReadPart 'xl/workbook.xml';Check 'workbook sheet is Servidores' $wb.workbook.sheets.sheet[0].name 'Servidores'
  [xml]$sheet=ReadPart 'xl/worksheets/sheet1.xml'
  $cell=@($sheet.worksheet.sheetData.row.c | Where-Object {$_.is.t.InnerText -eq '00123' -or [string]$_.is.t -eq '00123'})
  Check 'matricula is literal text in actual XLSX' $cell[0].t 'inlineStr'
  [xml]$tips=ReadPart 'xl/worksheets/sheet3.xml';Check 'custom instructions replace Access copy advice' ($tips.DocumentElement.InnerText.Contains('Colar_Access')) $false
 }finally{$z.Dispose()}
}finally{if($remove -and (Test-Path $Output)){Remove-Item -LiteralPath $Output -Force}}
$script:Records=@();Check 'empty database no invented rows' (Get-ExportacaoListaServidores).Linhas.Count 0
Write-Output "LISTA_COMPLETE assertions=$checks"
