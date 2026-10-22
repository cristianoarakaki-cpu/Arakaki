param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))
$ErrorActionPreference='Stop';$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $ast.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
$checks=0
function Check($name,$ok){if(-not $ok){throw $name};$script:checks++;Write-Output "PASS $name"}
function New-AuditRow($mat,$cp){[pscustomobject]@{matricula=$mat;cp_relatorio=$cp;nome=$mat;setor='S';periodo='M';aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31'}}
$script:Records=@((New-AuditRow 'A' '111'),(New-AuditRow 'A' '000111'),(New-AuditRow 'B' ''),(New-AuditRow 'C' '0'),(New-AuditRow 'D' '444'),(New-AuditRow 'E' '444'),(New-AuditRow 'F' '222'),(New-AuditRow 'F' '223'),(New-AuditRow 'G' '333'),(New-AuditRow 'G' ''),(New-AuditRow 'H' 'xyz'),(New-AuditRow 'H' '444'),(New-AuditRow '001' '55'),(New-AuditRow '1' '66'),(New-AuditRow 'K' '2147483647'))
$script:HistoricoFerias=@([pscustomobject]@{matricula='B';cp_relatorio='999'})
$before=$script:Records|ConvertTo-Json -Depth 20 -Compress
$a=Get-ConferenciaCP
Check 'uma conferencia por matricula exata' ($a.Count -eq 11 -and $a.ContainsKey('001') -and $a.ContainsKey('1'))
Check 'CP equivalente com zeros numericos nao diverge' (-not $a.A.TemProblema -and $a.A.CP -eq '111')
Check 'ausencia detectada sem ocultar por CP do historico' ($a.B.Problemas -contains 'SEM CP')
Check 'zero invalido' ($a.C.Problemas -contains 'CP INVÁLIDO')
Check 'repeticao entre matriculas detectada em todos' (@('D','E','H'|Where-Object {$a[$_].Problemas -contains 'CP REPETIDO'}).Count -eq 3)
Check 'repeticao nao e apenas entre aquisitivos do mesmo servidor' (-not ($a.A.Problemas -contains 'CP REPETIDO'))
Check 'divergencia entre aquisitivos identificada' ($a.F.Problemas -contains 'CPs DIVERGENTES')
Check 'preenchimento parcial identificado' ($a.G.SemCP -eq 1 -and $a.G.Problemas -contains 'CP INCOMPLETO')
Check 'mais de um problema permanece filtravel' ($a.H.Problemas -contains 'CP INVÁLIDO' -and $a.H.Problemas -contains 'CP REPETIDO')
Check 'detalhes mostram outras matriculas do CP repetido' ($a.D.Detalhe.Contains('E') -and $a.D.Detalhe.Contains('H'))
Check 'limite inteiro longo aceito' (-not $a.K.TemProblema)
Check 'conferencia somente leitura' (($script:Records|ConvertTo-Json -Depth 20 -Compress) -ceq $before)
$caso=Get-ConferenciaCP @((New-AuditRow 'A' '111'),(New-AuditRow 'a' '111'))
Check 'case da matricula segue a identidade ja usada no sistema' ($caso.Count -eq 1 -and -not $caso.A.TemProblema)
foreach($bad in @('-1','1.5','2147483648')){$caso=Get-ConferenciaCP @((New-AuditRow 'X' $bad));Check "CP invalido diagnosticado '$bad'" ($caso.X.Problemas -contains 'CP INVÁLIDO')}

Check 'filtro todos inclui validos e problemas' ((Test-FiltroConferenciaCP $a.A 'TODOS') -and (Test-FiltroConferenciaCP $a.B 'TODOS'))
Check 'filtro problemas exclui cadastro correto' ((Test-FiltroConferenciaCP $a.B 'COM PROBLEMA') -and -not (Test-FiltroConferenciaCP $a.A 'COM PROBLEMA'))
Check 'filtro CP OK exclui problemas' ((Test-FiltroConferenciaCP $a.A 'CP OK') -and -not (Test-FiltroConferenciaCP $a.B 'CP OK'))
Check 'filtro sem CP distinto de parcial' ((Test-FiltroConferenciaCP $a.B 'SEM CP') -and -not (Test-FiltroConferenciaCP $a.G 'SEM CP'))
Check 'filtro incompleto distinto de ausente em todos' ((Test-FiltroConferenciaCP $a.G 'CP INCOMPLETO') -and -not (Test-FiltroConferenciaCP $a.B 'CP INCOMPLETO'))
Check 'filtros por categorias multiplas' ((Test-FiltroConferenciaCP $a.H 'CP REPETIDO') -and (Test-FiltroConferenciaCP $a.H 'CP INVÁLIDO'))
# Executar o Refresh-Grid real usando uma grade simulada, sem carregar WinForms.
Add-Type @'
using System;using System.Collections.Generic;
namespace TestFiltroCP {
 public class Style {public object BackColor{get;set;}public object ForeColor{get;set;}}
 public class Cell {public object Value{get;set;}public string ToolTipText{get;set;}public Style Style{get;}=new Style();}
 public class Row {public Dictionary<string,Cell> Cells{get;}=new Dictionary<string,Cell>();public Style DefaultCellStyle{get;}=new Style();public Row(){foreach(var k in new[]{"excluir","formulario","matricula","cp","nome","setor","periodo","situacao","qtdperiodos","qtdsol"})Cells[k]=new Cell();}}
 public class Rows:List<Row>{public int Add(){base.Add(new Row());return Count-1;}}
 public class Grid {public Rows Rows{get;}=new Rows();public void SuspendLayout(){}public void ResumeLayout(bool value){}}
}
'@
function Get-StatusExibicaoRegistro {param($r)return 'PENDENTE'}
function Test-RegistroTemSolicitacao {param($r)return $false}
function Test-RegistroTemJustificativa {param($r)return $false}
function Update-PendenciasButton {}
function Atualizar-ResumoMarcados {}
function Atualizar-BotaoExcluidos {}
function Write-DiagLog {param($message,$level)}
function Clear-Editor {$script:clears++}
$script:grid=New-Object TestFiltroCP.Grid
$script:txtBusca=[pscustomobject]@{Text=''}
$script:cmbFiltroPeriodo=[pscustomobject]@{SelectedItem='TODOS'};$script:cmbFiltroSituacao=[pscustomobject]@{SelectedItem='TODAS'}
$script:cmbFiltroGrupoAnalise=[pscustomobject]@{SelectedItem='TODOS'};$script:cmbFiltroChefia=[pscustomobject]@{SelectedItem='TODOS'};$script:cmbFiltroSolicitacao=[pscustomobject]@{SelectedItem='TODOS'};$script:cmbFiltroJustificativa=[pscustomobject]@{SelectedItem='TODOS'}
$script:cmbFiltroCP=[pscustomobject]@{SelectedItem='COM PROBLEMA'}
$script:FiltroSetoresSelecionados=@();$script:SomentePendencias=$false;$script:GridPesquisaGroups=$null
$script:GridPesquisaTotais=@{Fixos=0;Escolha=0;Vazios=0};$script:GridServidoresMarcados=@{};$script:FormServidoresMarcados=@{};$script:lblTotal=[pscustomobject]@{Text=''};$script:clears=0
Refresh-Grid
$exibidos=@($script:grid.Rows|ForEach-Object {$_.Cells['matricula'].Value}|Sort-Object)
Check 'grade real exibe somente os 7 servidores com problemas' (($exibidos -join ',') -eq 'B,C,D,E,F,G,H')
Check 'grade real exibe CP e detalhe completo' ($script:grid.Rows[0].Cells['cp'].ToolTipText.Length -gt 0)
Check 'resumo real informa total de problemas da base' ($script:lblTotal.Text.Contains('CP com problema (base): 7'))
$script:cmbFiltroCP.SelectedItem='CP OK';Refresh-Grid
Check 'grade real exibe apenas os quatro CPs corretos' ($script:grid.Rows.Count -eq 4)
$script:cmbFiltroCP.SelectedItem='TODOS';Refresh-Grid
Check 'todos restaura os 11 servidores' ($script:grid.Rows.Count -eq 11)
$script:Records=@((New-AuditRow 'A' '111'));$script:GridPesquisaGroups=$null;$script:cmbFiltroCP.SelectedItem='COM PROBLEMA';Refresh-Grid
Check 'filtro sem resultados limpa editor anterior' ($script:grid.Rows.Count -eq 0 -and $script:clears -gt 0)
$script:cmbFiltroCP.SelectedItem='TODOS';Refresh-Grid
Check 'filtro nao persiste alteracoes nos dados' ($script:Records[0].cp_relatorio -eq '111')
Write-Output "FILTRO_CP_COMPLETE assertions=$checks"
