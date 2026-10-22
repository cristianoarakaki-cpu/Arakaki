param([string]$Source=(Join-Path $PSScriptRoot '../FeriasDCE.ps1'))
$ErrorActionPreference='Stop'
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$t,[ref]$e)
if($e.Count){throw ($e -join "`n")}
foreach($f in $ast.EndBlock.Statements){if($f -is [Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($f.Extent.Text))}}
$checks=0
function Check($name,$actual,$expected){if($actual -cne $expected){throw "$name expected=$expected actual=$actual"};$script:checks++;"PASS $name"}
function New-ReportFixture($id,$mat,$sector='CTI',$turno='MATUTINO'){
 [pscustomobject]@{id=$id;matricula=$mat;nome=('Servidor '+$mat);setor=$sector;periodo=$turno;aquisitivo_inicio='2025-01-01';aquisitivo_fim='2025-12-31';ferias_bloqueadas=$false;fixo_inicio='';fixo_fim='';fixos_adicionais=@();opcao_aprovada=2;fr_opcao_aprovada=0;opcao1=[pscustomobject]@{tipo='30 DIAS';inicio1='2027-01-01';fim1='2027-01-30';inicio2='';fim2='';fr_inicio='';fr_fim=''};opcao2=[pscustomobject]@{tipo='30 DIAS';inicio1='2027-03-01';fim1='2027-03-30';inicio2='';fim2='';fr_inicio='';fr_fim=''}}
}
$a=New-ReportFixture 1 'A';$b=New-ReportFixture 2 'B';$p=New-ReportFixture 3 'P';$p.opcao_aprovada=0
$script:Records=@($a,$b,$p);$before=$script:Records|ConvertTo-Json -Depth 20 -Compress
$c=Get-ConflitosConferenciaAceitas $script:Records 2027 3
Check 'two accepted employees conflict' $c.Count 2
Check 'same known shift critical' ($c['1'][0] -match '^CRITICO:') $true
Check 'conflict identifies counterpart matricula' ($c['1'][0] -match 'mat. B;') $true
Check 'pending employee excluded' $c.ContainsKey('3') $false
Check 'request month is not approval month' (Get-ConflitosConferenciaAceitas $script:Records 2027 1).Count 0
$b.periodo='NOTURNO';$c=Get-ConflitosConferenciaAceitas $script:Records 2027 3
Check 'different shifts attention' ($c['1'][0] -match '^ATENCAO:') $true
$b.periodo='';$c=Get-ConflitosConferenciaAceitas $script:Records 2027 3
Check 'unknown shift not critical' ($c['1'][0] -match '^ATENCAO:') $true
$b.setor='OUTRO';Check 'different sectors excluded' (Get-ConflitosConferenciaAceitas $script:Records 2027 3).Count 0
$b.setor='CTI';$b.matricula='A';Check 'same employee never self conflicts' (Get-ConflitosConferenciaAceitas $script:Records 2027 3).Count 0
$b.matricula='B';$b.periodo='MATUTINO';$b.opcao2.inicio1='2027-03-30';$b.opcao2.fim1='2027-04-28'
$c=Get-ConflitosConferenciaAceitas $script:Records 2027 3
Check 'inclusive last day overlap' ($c['1'][0] -match '30/03/2027 a 30/03/2027') $true
$b.opcao2.inicio1='2027-03-31';Check 'adjacent periods no overlap' (Get-ConflitosConferenciaAceitas $script:Records 2027 3).Count 0
$b.ferias_bloqueadas=$true;$b.fixo_inicio='2027-03-15';$b.fixo_fim='2027-03-29';$b.opcao_aprovada=0
Check 'fixed commitments included' (Get-ConflitosConferenciaAceitas $script:Records 2027 3).Count 2
$b.ferias_bloqueadas=$false;$b.fixo_inicio='';$b.fixo_fim='';$b.fr_opcao_aprovada=1;$b.opcao1.fr_inicio='2027-03-01';$b.opcao1.fr_fim='2027-03-20'
Check 'independently approved FR included' (Get-ConflitosConferenciaAceitas $script:Records 2027 3).Count 2
# Execute the real computation section of the report callback without WinForms.
$report=($ast.EndBlock.Statements | Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -eq 'Show-RelatorioConferenciaOpcoes'}).Extent.Text
$from=$report.IndexOf('    $refresh={');$to=$report.IndexOf('        $store.Shown=$dt',$from)
$body=$report.Substring($from,$to-$from);$body=$body.Substring($body.IndexOf('      try {')+11)
$compute=[scriptblock]::Create($body)
function Calculate($selection,$analysis,$records,$sectorName='Todos',$term=''){
 $store=[pscustomobject]@{Records=$records};$select=[pscustomobject]@{SelectedIndex=$selection}
 $modo=[pscustomobject]@{SelectedItem=$analysis;Enabled=$true};$year=[pscustomobject]@{SelectedItem=2027};$month=[pscustomobject]@{SelectedIndex=0}
 $modality=[pscustomobject]@{SelectedItem='Todas'};$search=[pscustomobject]@{Text=$term};$sector=[pscustomobject]@{SelectedItem=$sectorName};$period=[pscustomobject]@{SelectedItem='Todos'}
 $getChosen={@('Matricula','Servidor','Modalidade','Conflitos no setor')};$fields=@{Matricula='matricula';Servidor='nome';Modalidade='modalidade';'Conflitos no setor'='conflitos_setor'}
 $conflitosAceitasRelatorio=${function:Get-ConflitosConferenciaAceitas};$contagemAceitasRelatorio=${function:Get-ContagemInstitucionalAprovadaMes}
 $pesoInstitucionalRelatorio=${function:Get-PesoBlocoInstitucionalMes};$limiteInstitucionalRelatorio={param($mm) 10}
 $monthHit={param($s,$e,$y,$m) $i=Parse-Date $s;$f=Parse-Date $e;if($null -eq $i -or $null -eq $f -or $f -lt $i){return $false};$first=[datetime]::new($y,$m,1);return ($i -le $first.AddMonths(1).AddDays(-1) -and $f -ge $first)}
 $dateBR={param($s) Date-ToBR $s}
 . $compute
 return [pscustomobject]@{Monthly=$monthly;Detail=$dt;ModoEnabled=$modo.Enabled}
}
$a=New-ReportFixture 1 'A';$b=New-ReportFixture 2 'B' 'OUTRO';$p=New-ReportFixture 3 'P';$p.opcao_aprovada=0;$rows=@($a,$b,$p)
$d=Calculate 3 'Solicitacoes originais' $rows
Check 'accepted choice overrides requests analysis' $d.Detail.Rows.Count 2
Check 'accepted choice disables incompatible mode' $d.ModoEnabled $false
Check 'approved month count correct' $d.Monthly.Rows[2].Comuns '2'
Check 'request month excluded from accepted totals' $d.Monthly.Rows[0].Comuns '0'
Check 'approved global equivalents' $d.Monthly.Rows[2].Equivalentes '2'
Check 'approved balance excludes pending requests' $d.Monthly.Rows[2].Saldo '8'
$filtered=Calculate 3 'Pendencias' $rows 'CTI' 'Servidor A'
Check 'nominal filters apply to details' $filtered.Detail.Rows.Count 1
Check 'nominal filters cannot inflate institutional balance' $filtered.Monthly.Rows[2].Saldo '8'
$orig=Calculate 0 'Solicitacoes originais' $rows
Check 'original first option scenario preserved' $orig.Monthly.Rows[0].Comuns '3'
Check 'scenario selector keeps mode enabled' $orig.ModoEnabled $true
$approved=Calculate 0 'Programacao aprovada' $rows
Check 'existing approved analysis also uses approved balance' $approved.Monthly.Rows[2].Saldo '8'
$before=$rows|ConvertTo-Json -Depth 20 -Compress
$null=Calculate 3 'Solicitacoes originais' $rows
Check 'report never mutates vacation data' ($rows|ConvertTo-Json -Depth 20 -Compress) $before
$a=New-ReportFixture 1 'A';$b=New-ReportFixture 2 'B';$b.opcao_aprovada=0;$b.fr_opcao_aprovada=1;$b.opcao1.fr_inicio='2027-04-01';$b.opcao1.fr_fim='2027-04-20'
$d=Calculate 3 'Solicitacoes originais' @($a,$b)
Check 'common approval selects second option not requested first' $d.Monthly.Rows[2].Comuns '1'
Check 'FR approval selects independent first option' $d.Monthly.Rows[3].'FR 20 dias' '1'
Check 'FR accepted balance weighted correctly' $d.Monthly.Rows[3].Saldo '9'
$b.fr_opcao_aprovada=0;$b.ferias_bloqueadas=$true;$b.fixo_inicio='2027-03-01';$b.fixo_fim='2027-03-15'
$d=Calculate 3 'Programacao aprovada' @($a,$b)
Check 'fixed present in final planning counts' $d.Monthly.Rows[2].Fixas '1'
Check 'fixed 15 day weight included in balance' $d.Monthly.Rows[2].Saldo '8,5'
Check 'pending fixed month does not use option request' $d.Monthly.Rows[0].Fixas '0'
Check 'conflicts available in detail grid' ($d.Detail.Rows[0].'Conflitos no setor' -match 'CRITICO:') $true
$d=Calculate 3 'Programacao aprovada' @($a,$a)
Check 'duplicate acquisition cannot double institutional weight' $d.Monthly.Rows[2].Equivalentes '1'
$a.opcao2.inicio1='2026-12-20';$a.opcao2.fim1='2027-01-18';$b.fixo_inicio='2026-12-25';$b.fixo_fim='2027-01-08'
$c=Get-ConflitosConferenciaAceitas @($a,$b) 2027 1
Check 'conflict clipped to selected year and month' ($c['1'][0] -match '01/01/2027 a 08/01/2027') $true
Check 'no conflict outside selected month' (Get-ConflitosConferenciaAceitas @($a,$b) 2027 2).Count 0
$a=New-ReportFixture 1 'A';$b=New-ReportFixture 2 'B' 'CTI' 'NOTURNO';$third=New-ReportFixture 3 'C';$third.opcao2.inicio1='2027-03-15';$third.opcao2.fim1='2027-03-20'
$entries=@(Get-EntradasConferenciaSetor $false @($a,$b,$third))
$events=@(Get-EventosConflitoSetor $entries)
Check 'shared engine splits changed participants into intervals' $events.Count 3
Check 'shared engine initial interval attention' $events[0].Grau 'ATENCAO'
Check 'shared engine middle interval critical' $events[1].Grau 'CRITICO'
$c=Get-ConflitosConferenciaAceitas @($a,$b,$third) 2027 3
Check 'grid keeps report group severity for all participants' (($c['2'] -join '|') -match 'CRITICO: 15/03/2027 a 20/03/2027') $true
Check 'shared engine preserves same shift filter' @(Get-EventosConflitoSetor $entries 'POR_SETOR' $true).Count 1
Check 'shared engine preserves intersector exclusions' @(Get-EventosConflitoSetor $entries 'ENTRE_SETORES').Count 0
$third.setor='OUTRO';$entries=@(Get-EntradasConferenciaSetor $false @($a,$b,$third))
Check 'shared engine intersector overlaps preserved' @(Get-EventosConflitoSetor $entries 'ENTRE_SETORES').Count 1
$declaredNames=@([regex]::Matches($report,"@\('([^']+)','[^']+',\d+\)") | ForEach-Object {$_.Groups[1].Value})
$referencedNames=@([regex]::Matches($report,"\`$summary\.Columns\['([^']+)'\]") | ForEach-Object {$_.Groups[1].Value})
Check 'summary column reference audit covers new headers' ($referencedNames.Count -ge 3) $true
Check 'summary formatting references only declared column names' @($referencedNames | Where-Object {$_ -notin $declaredNames}).Count 0
"CONFERENCIA_ACEITAS_COMPLETE assertions=$checks"
