param([string]$Source=(Join-Path $PSScriptRoot '../inicializador/FeriasDCE_Iniciar.cs'),[int]$Rodadas=20)
$ErrorActionPreference='Stop'
Add-Type -TypeDefinition ([IO.File]::ReadAllText($Source))
$checks=0
function Check($name,$actual,$expected){if($actual -cne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;"PASS $name"}
for($round=1;$round -le $Rodadas;$round++){
 $root=Join-Path ([IO.Path]::GetTempPath()) ('ferias-launch-'+[guid]::NewGuid().ToString('N'))
 try{
  $folder=Join-Path $root 'pasta com espaços'
  $p=[FeriasDCEIniciar]::BuildStartInfo($folder,'C:\Windows')
  Check 'no console creation' $p.CreateNoWindow $true
  Check 'shell disabled' $p.UseShellExecute $false
  Check 'hidden process window' ([string]$p.WindowStyle) 'Hidden'
  Check 'STA Windows PowerShell' ($p.Arguments -match '-STA -File ') $true
  Check 'execution policy not overridden' ($p.Arguments -notmatch '(?i)executionpolicy|bypass|unrestricted') $true
  Check 'direct PS1 launch without cmd or vbs' ($p.FileName.EndsWith('powershell.exe') -and $p.Arguments.EndsWith('FeriasDCE.ps1"')) $true
  Check 'stdout and stderr captured for diagnostics' ($p.RedirectStandardOutput -and $p.RedirectStandardError) $true
  Check 'working directory preserved' $p.WorkingDirectory $folder
  $unc='\\servidor\compartilhamento\Férias DCE'
  $u=[FeriasDCEIniciar]::BuildStartInfo($unc,'C:\Windows')
  Check 'UNC not passed through cmd' $u.WorkingDirectory $unc
  Check 'UNC quoted as one script argument' ($u.Arguments.Contains('"'+$unc) -and $u.Arguments.EndsWith('FeriasDCE.ps1"')) $true
  Check 'spaces quoted' ([FeriasDCEIniciar]::QuoteArgument('a b')) '"a b"'
  Check 'trailing slash safely escaped' ([FeriasDCEIniciar]::QuoteArgument('a\')) '"a\\"'
  Check 'quote safely escaped' ([FeriasDCEIniciar]::QuoteArgument('a"b')) '"a\"b"'
  [void][IO.Directory]::CreateDirectory($root)
  $blocked=Join-Path $root 'arquivo';[IO.File]::WriteAllText($blocked,'root indisponivel')
  $fallback=Join-Path $root 'fallback'
  $log=[FeriasDCEIniciar]::CreateLog($blocked,$fallback)
  Check 'log falls back when shared location unavailable' ([IO.Path]::GetDirectoryName($log)) $fallback
  [FeriasDCEIniciar]::WriteLog($log,'erro de teste')
  Check 'diagnostic text recorded' ([IO.File]::ReadAllText($log).Contains('erro de teste')) $true
  $log2=[FeriasDCEIniciar]::CreateLog($blocked,$fallback)
  Check 'each launch has unique log' ($log -ne $log2) $true
  Check 'no logging location remains supported' ($null -eq [FeriasDCEIniciar]::CreateLog($blocked,$blocked)) $true
  [FeriasDCEIniciar]::WriteLog($null,'erro sem log')
  Check 'native entrypoint STA' ([FeriasDCEIniciar].GetMethod('Main').GetCustomAttributes([STAThreadAttribute],$false).Count) 1
 }finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}
}
"INICIALIZADOR_COMPLETE rounds=$Rodadas assertions=$checks"
