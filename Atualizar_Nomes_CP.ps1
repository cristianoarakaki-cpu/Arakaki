param([string]$Planilha='', [string]$Base='')
$ErrorActionPreference='Stop'

function Read-MapaNomesCP([string]$Path){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($Path)
    try{
        function ReadXmlCP($entry){
            if($null -eq $entry){throw 'Parte obrigatória ausente no Excel.'}
            $settings=New-Object Xml.XmlReaderSettings;$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
            $stream=$entry.Open();$reader=[Xml.XmlReader]::Create($stream,$settings)
            try{$xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($reader);return ,$xml}finally{$reader.Dispose();$stream.Dispose()}
        }
        $shared=New-Object 'System.Collections.Generic.List[string]'
        $entry=$zip.GetEntry('xl/sharedStrings.xml')
        if($entry){$ss=ReadXmlCP $entry;foreach($si in $ss.sst.si){[void]$shared.Add([string]$si.InnerText)}}
        $sheet=ReadXmlCP ($zip.GetEntry('xl/worksheets/sheet1.xml'))
        $headers=@{};$map=@{};$cpOwners=@{}
        foreach($row in $sheet.worksheet.sheetData.row){
            $values=@{}
            foreach($c in $row.c){
                $col=([string]$c.r -replace '[0-9]','')
                if($null -ne $c.f){throw "Fórmula encontrada na célula $($c.r). Use valores fixos na planilha."}
                $value=if([string]$c.t -eq 's'){$shared[[int]$c.v]}elseif([string]$c.t -eq 'inlineStr'){[string]$c.is.InnerText}else{[string]$c.v}
                $values[$col]=([string]$value).Trim()
            }
            if($headers.Count -eq 0){
                foreach($col in $values.Keys){$h=$values[$col].ToUpperInvariant();if($h -in @('CP','MATRICULA','MATRÍCULA','NOME')){$key=if($h -eq 'MATRÍCULA'){'MATRICULA'}else{$h};if($headers.ContainsKey($key)){throw "Cabeçalho duplicado: $key"};$headers[$key]=$col}}
                if($headers.Count -ne 3){throw 'A primeira linha deve conter CP, Matricula e Nome.'};continue
            }
            $mat=[string]$values[$headers['MATRICULA']];$cp=[string]$values[$headers['CP']];$nome=[string]$values[$headers['NOME']]
            if(-not $mat -and -not $cp -and -not $nome){continue}
            $ncp=0
            if($mat -notmatch '^\d+$' -or -not [int]::TryParse($cp,[ref]$ncp) -or $ncp -le 0 -or -not $nome){throw "Dados inválidos na linha $($row.r). Matrícula, CP numérico positivo e Nome são obrigatórios."}
            $cp=$ncp.ToString([Globalization.CultureInfo]::InvariantCulture)
            if($map.ContainsKey($mat)){throw "Matrícula duplicada na planilha: $mat. Nenhuma alteração aplicada."}
            if($cpOwners.ContainsKey($cp) -and $cpOwners[$cp] -ne $mat){throw "CP $cp associado a matrículas diferentes. Nenhuma alteração aplicada."}
            $map[$mat]=[pscustomobject]@{CP=$cp;Nome=$nome};$cpOwners[$cp]=$mat
        }
        if($map.Count -eq 0){throw 'Planilha sem servidores.'};return ,$map
    }finally{$zip.Dispose()}
}

function Get-EstadoSemNomeCP($Db){
    $state=[ordered]@{}
    foreach($p in $Db.PSObject.Properties){
        if($p.Name -in @('revisao_dados','ultima_gravacao_utc')){continue}
        $state[$p.Name]=if($p.Name -eq 'registros'){@($Db.registros | Select-Object * -ExcludeProperty nome,cp_relatorio)}else{$p.Value}
    }
    return ($state | ConvertTo-Json -Depth 100 -Compress)
}

function Update-BaseNomesCP([string]$Excel,[string]$DbFile){
    $map=Read-MapaNomesCP $Excel
    $DbFile=[IO.Path]::GetFullPath($DbFile);$dir=Split-Path -Parent $DbFile
    $lockPath=Join-Path $dir 'ferias_2027.lock';$lock=$null;$temp=''
    try{
        $lock=[IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $raw=[IO.File]::ReadAllText($DbFile,[Text.Encoding]::UTF8);$db=$raw | ConvertFrom-Json
        if($null -eq $db.PSObject.Properties['registros'] -or @($db.registros).Count -eq 0){throw 'Base sem registros válidos.'}
        $preservado=Get-EstadoSemNomeCP $db
        $faltantes=@($db.registros | Where-Object {-not $map.ContainsKey(([string]$_.matricula).Trim())})
        if($faltantes.Count){throw "$($faltantes.Count) registro(s) sem matrícula correspondente na planilha. Nenhuma alteração aplicada."}
        $audit=New-Object 'System.Collections.Generic.List[object]';$mats=@{};$nomes=0;$cps=0
        foreach($r in $db.registros){
            $mat=([string]$r.matricula).Trim();$item=$map[$mat];$mats[$mat]=$true
            $nomeMudou=([string]$r.nome -cne $item.Nome);$cpMudou=([string]$r.cp_relatorio -cne $item.CP)
            if($nomeMudou){$nomes++};if($cpMudou){$cps++}
            [void]$audit.Add([pscustomobject][ordered]@{id=$r.id;matricula=$mat;nome_anterior=[string]$r.nome;nome_correto=$item.Nome;cp_anterior=[string]$r.cp_relatorio;cp_correto=$item.CP;nome_alterado=$nomeMudou;cp_alterado=$cpMudou})
            $r.nome=$item.Nome;$r | Add-Member NoteProperty cp_relatorio ([string]$item.CP) -Force
        }
        if($preservado -cne (Get-EstadoSemNomeCP $db)){throw 'Validação de preservação falhou. Nenhuma alteração aplicada.'}
        if($nomes -eq 0 -and $cps -eq 0){return [pscustomobject]@{servidores=$mats.Count;registros=@($db.registros).Count;nomes_corrigidos=0;cps_atualizados=0;backup='';relatorio='';situacao='Base já atualizada; nenhuma nova gravação'}}
        $stamp=(Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)
        $backupDir=Join-Path (Split-Path -Parent $dir) 'Backups'
        [void][IO.Directory]::CreateDirectory($backupDir)
        $backup=Join-Path $backupDir ("ANTES_NOMES_CP_${stamp}.json");$report=Join-Path $backupDir ("RELATORIO_NOMES_CP_${stamp}.csv")
        [IO.File]::Copy($DbFile,$backup,$false)
        if([IO.File]::ReadAllText($backup,[Text.Encoding]::UTF8) -cne $raw){throw 'Backup não confere com a base original.'}
        $audit.ToArray() | Export-Csv -LiteralPath $report -Delimiter ';' -Encoding UTF8 -NoTypeInformation
        $db | Add-Member NoteProperty revisao_dados ([long]$db.revisao_dados+1) -Force
        $db | Add-Member NoteProperty ultima_gravacao_utc ([DateTime]::UtcNow.ToString('o')) -Force
        $temp=$DbFile+'.nomescp.'+[guid]::NewGuid().ToString('N')+'.tmp'
        [IO.File]::WriteAllText($temp,($db | ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($true))
        $verify=[IO.File]::ReadAllText($temp,[Text.Encoding]::UTF8) | ConvertFrom-Json
        if((Get-EstadoSemNomeCP $verify) -cne $preservado){throw 'Validação do arquivo temporário falhou.'}
        foreach($r in $verify.registros){$item=$map[([string]$r.matricula).Trim()];if([string]$r.nome -cne $item.Nome -or [string]$r.cp_relatorio -cne $item.CP){throw 'Nome ou CP não confere no arquivo temporário.'}}
        if([IO.File]::ReadAllText($DbFile,[Text.Encoding]::UTF8) -cne $raw){throw 'A base mudou durante a atualização. Operação cancelada.'}
        try{[IO.File]::Replace($temp,$DbFile,$null)}catch{
            # Alternativa de renomeação para compartilhamentos SMB que não suportam Replace.
            if(-not [IO.File]::Exists($temp) -or -not [IO.File]::Exists($DbFile)){throw}
            if([IO.File]::ReadAllText($DbFile,[Text.Encoding]::UTF8) -cne $raw){throw 'Base alterada externamente; renomeação cancelada.'}
            $old=$DbFile+'.anterior.'+[guid]::NewGuid().ToString('N')
            [IO.File]::Move($DbFile,$old)
            try{[IO.File]::Move($temp,$DbFile)}catch{[IO.File]::Move($old,$DbFile);throw}
            try{[IO.File]::Delete($old)}catch{Write-Warning "Cópia anterior mantida em $old"}
        }
        $temp=''
        return [pscustomobject]@{servidores=$mats.Count;registros=@($db.registros).Count;nomes_corrigidos=$nomes;cps_atualizados=$cps;backup=$backup;relatorio=$report;situacao='Atualização concluída'}
    }finally{if($temp -and [IO.File]::Exists($temp)){[IO.File]::Delete($temp)};if($null -ne $lock){$lock.Dispose()}}
}

$visual=(-not $Planilha -or -not $Base)
try{
    if($visual){
        Add-Type -AssemblyName System.Windows.Forms
        [Windows.Forms.MessageBox]::Show('Feche o sistema de férias em todos os computadores antes de continuar. Selecione a planilha CP/Matricula/Nome e depois Dados\ferias_2027.json. Será criado backup automático.','Atualizar nomes e CPs')|Out-Null
        $dlg=New-Object Windows.Forms.OpenFileDialog
        try{
            $dlg.Title='Selecione a planilha com CP, Matricula e Nome corretos';$dlg.Filter='Excel (*.xlsx)|*.xlsx'
            if($dlg.ShowDialog() -ne 'OK'){return};$Planilha=$dlg.FileName
            $dlg.Title='Selecione Dados\ferias_2027.json do sistema';$dlg.Filter='Base de férias (ferias_2027.json)|ferias_2027.json';$dlg.FileName='ferias_2027.json'
            if($dlg.ShowDialog() -ne 'OK'){return};$Base=$dlg.FileName
        }finally{$dlg.Dispose()}
    }
    $result=Update-BaseNomesCP $Planilha $Base
    if($visual){[Windows.Forms.MessageBox]::Show("$($result.situacao)`nServidores: $($result.servidores)`nPeríodos: $($result.registros)`nNomes corrigidos: $($result.nomes_corrigidos)`nCPs atualizados: $($result.cps_atualizados)`n`nBackup: $($result.backup)`nRelatório: $($result.relatorio)",'Atualizar nomes e CPs')|Out-Null}else{$result | ConvertTo-Json}
}catch{
    if($visual){[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Atualização cancelada')|Out-Null}else{Write-Error $_};exit 1
}
