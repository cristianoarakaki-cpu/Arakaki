#requires -Version 5.1
[CmdletBinding()]
param([string]$Destino=(Join-Path $PSScriptRoot 'INICIAR_FERIAS_DCE.exe'))
$ErrorActionPreference='Stop'
$compilador=Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(-not (Test-Path -LiteralPath $compilador)){$compilador=Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe'}
if(-not (Test-Path -LiteralPath $compilador)){throw 'Compilador C# do .NET Framework não encontrado.'}
$temporario=Join-Path ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Destino))) ('iniciar-'+[guid]::NewGuid().ToString('N')+'.exe')
try{
 & $compilador /nologo /target:winexe /platform:anycpu /optimize+ "/out:$temporario" (Join-Path $PSScriptRoot 'FeriasDCE_Iniciar.cs')
 if($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temporario)){throw 'Falha ao compilar o inicializador.'}
 Move-Item -LiteralPath $temporario -Destination $Destino -Force
 Write-Output "Inicializador gráfico gerado: $Destino"
}finally{if(Test-Path -LiteralPath $temporario){Remove-Item -LiteralPath $temporario -Force}}
