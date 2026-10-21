#requires -version 5.1
#requires -PSEdition Desktop
# Otimizacao CORR-R6: caches puros limitados e eventos/cache da Central corrigidos.
# Patch SMB: File.Replace com alternativa de renomeacao, sem sobrescrita direta.
# Férias DCE V1.0.136-R3 — otimização seletiva de retorno às abas; decisões e formulários preservados.
# Base V1.0.45 preservada, com validação também na sincronização da planilha de lançamentos.
$script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:DataDir = Join-Path $script:AppRoot "Dados"
$script:BackupDir = Join-Path $script:AppRoot "Backups"
$script:LogDir = Join-Path $script:AppRoot "Logs"
$script:DbFile = Join-Path $script:DataDir "ferias_2027.json"
$script:SeedFile = Join-Path $script:DataDir "ferias_2027_seed.json"
$script:LogFile = Join-Path $script:LogDir ("FeriasDCE_{0}.log" -f (Get-Date -Format "yyyyMMdd"))
$script:StartupPhase = "BOOT"
$script:IconFile = Join-Path $script:AppRoot "FeriasDCE.ico"
$script:AppIcon = $null
$script:DbLockFile = Join-Path $script:DataDir "ferias_2027.lock"
$script:LoadedRevision = [long]0
$script:LoadedDbHash = ""
$script:InstanceMutex = $null
$script:InstanceMutexOwned = $false

function Write-DiagLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG","INFO","WARN","ERROR","FATAL")][string]$Level="INFO",
        [object]$ErrorRecord=$null
    )
    try {
        if(-not (Test-Path -LiteralPath $script:LogDir)){ New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null }
        $stamp=Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $linha="[$stamp] [$Level] [FASE=$script:StartupPhase] $Message"
        [IO.File]::AppendAllText($script:LogFile,$linha+[Environment]::NewLine,[Text.UTF8Encoding]::new($true))
        if($null -ne $ErrorRecord){
            $extra=@()
            try { $extra += "Tipo: $($ErrorRecord.Exception.GetType().FullName)" } catch {}
            try { $extra += "Mensagem: $($ErrorRecord.Exception.Message)" } catch {}
            try { if($ErrorRecord.FullyQualifiedErrorId){ $extra += "ErrorId: $($ErrorRecord.FullyQualifiedErrorId)" } } catch {}
            try { if($ErrorRecord.InvocationInfo -and $ErrorRecord.InvocationInfo.PositionMessage){ $extra += "Local: $($ErrorRecord.InvocationInfo.PositionMessage)" } } catch {}
            try { if($ErrorRecord.ScriptStackTrace){ $extra += "Pilha: $($ErrorRecord.ScriptStackTrace)" } } catch {}
            foreach($e in $extra){ [IO.File]::AppendAllText($script:LogFile,"    $e"+[Environment]::NewLine,[Text.UTF8Encoding]::new($true)) }
        }
    } catch {
        # O logger nunca deve impedir a abertura do sistema.
    }
}

Write-DiagLog "INÍCIO do FeriasDCE.ps1 V1.0.136-R3 HIST-R3 | PowerShell $($PSVersionTable.PSVersion) | PID=$PID"
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-DiagLog "Assemblies WinForms/Drawing carregadas."
} catch {
    Write-DiagLog "Falha ao carregar Windows Forms." "FATAL" $_
    throw
}

# Captura exceções de eventos WinForms que, em modo oculto, poderiam ficar invisíveis.
try {
    [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
    $script:ThreadExceptionHandler=[System.Threading.ThreadExceptionEventHandler]{
        param($sender,$e)
        try {
            $msg=if($null -ne $e -and $null -ne $e.Exception){$e.Exception.Message}else{"Erro desconhecido em evento da interface."}
            if($msg -like "CONFLITO_SALVAMENTO_TRATADO:*"){
                Write-DiagLog ("Conflito de gravação já tratado pelo Save-Database: "+$msg) "WARN"
                return
            }
            Write-DiagLog ("Exceção não tratada em evento WinForms: "+$msg) "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Ocorreu um erro na interface.`n`n$msg`n`nO detalhe foi gravado em:`n$script:LogFile","Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        } catch {}
    }
    [System.Windows.Forms.Application]::add_ThreadException($script:ThreadExceptionHandler)
} catch { Write-DiagLog "Não foi possível instalar o handler global de eventos WinForms." "WARN" $_ }

# Evita duas instâncias no mesmo computador/sessão. Para PCs diferentes, Save-Database
# também usa lock de arquivo + revisão/hash, protegendo a base compartilhada.
try {
    $script:InstanceMutex=New-Object System.Threading.Mutex($false,'Local\HRMS.DCE.PlanejamentoFerias')
    try { $script:InstanceMutexOwned=$script:InstanceMutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $script:InstanceMutexOwned=$true }
    if(-not $script:InstanceMutexOwned){
        [System.Windows.Forms.MessageBox]::Show("O Planejamento de Férias DCE já está aberto neste computador.`n`nUse a instância que já está em execução.","Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        Write-DiagLog "Segunda instância bloqueada pelo mutex local." "WARN"
        exit
    }
} catch { Write-DiagLog "Mutex local indisponível; a proteção de concorrência do banco continuará ativa." "WARN" $_ }

function Initialize-AppBranding {
    try {
        $script:AppId="HRMS.DCE.PlanejamentoFerias"
        $script:LauncherFile=Join-Path $script:AppRoot "FeriasDCE_Launcher.ps1"
        $script:PowerShellExe=Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        # Reabertura visivel, respeitando a politica de execucao configurada no computador.
        $script:RelaunchCommand=('"{0}" -NoProfile -STA -File "{1}"' -f $script:PowerShellExe,$script:LauncherFile)
        $script:RelaunchIconResource=$script:IconFile+",0"

        if(Test-Path -LiteralPath $script:IconFile){
            # Mantém instâncias separadas para o ícone grande e pequeno. Windows 11
            # usa tamanhos diferentes na moldura e na barra de tarefas.
            $script:AppIcon=New-Object System.Drawing.Icon($script:IconFile)
            $script:AppIconLarge=New-Object System.Drawing.Icon($script:IconFile,32,32)
            $script:AppIconSmall=New-Object System.Drawing.Icon($script:IconFile,16,16)
        }
        if(-not ("FeriasDCE.TaskbarIdentityV3" -as [type])){
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace FeriasDCE {
    public static class TaskbarIdentityV3 {
        [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
        public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    }

    [StructLayout(LayoutKind.Sequential, Pack=4)]
    public struct PROPERTYKEY {
        public Guid fmtid;
        public uint pid;
        public PROPERTYKEY(Guid f, uint p) { fmtid=f; pid=p; }
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct PROPVARIANT {
        [FieldOffset(0)] public ushort vt;
        [FieldOffset(8)] public IntPtr pointerValue;
        public static PROPVARIANT FromString(string value) {
            PROPVARIANT pv=new PROPVARIANT();
            pv.vt=31; // VT_LPWSTR
            pv.pointerValue=Marshal.StringToCoTaskMemUni(value ?? String.Empty);
            return pv;
        }
        [DllImport("ole32.dll")]
        private static extern int PropVariantClear(ref PROPVARIANT pvar);
        public void Clear() { PropVariantClear(ref this); }
    }

    [ComImport]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore {
        [PreserveSig] int GetCount(out uint cProps);
        [PreserveSig] int GetAt(uint iProp, out PROPERTYKEY pkey);
        [PreserveSig] int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        [PreserveSig] int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        [PreserveSig] int Commit();
    }

    public static class WindowAppIdentity {
        [DllImport("shell32.dll")]
        private static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid iid, out IPropertyStore store);
        private static readonly Guid AppModelFmt = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3");

        private static void SetString(IPropertyStore store, uint pid, string value) {
            PROPERTYKEY key=new PROPERTYKEY(AppModelFmt,pid);
            PROPVARIANT pv=PROPVARIANT.FromString(value);
            try { store.SetValue(ref key, ref pv); }
            finally { pv.Clear(); }
        }

        public static int Apply(IntPtr hwnd, string appId, string relaunchCommand, string displayName, string iconResource) {
            if(hwnd==IntPtr.Zero) return -1;
            Guid iid=typeof(IPropertyStore).GUID;
            IPropertyStore store=null;
            int hr=SHGetPropertyStoreForWindow(hwnd, ref iid, out store);
            if(hr<0 || store==null) return hr;
            try {
                // Propriedades de relançamento primeiro; AppUserModelID por último para
                // obrigar a barra de tarefas a atualizar a identidade desta janela.
                SetString(store,2,relaunchCommand);       // RelaunchCommand
                SetString(store,3,iconResource);          // RelaunchIconResource
                SetString(store,4,displayName);           // RelaunchDisplayNameResource
                SetString(store,5,appId);                 // AppUserModel.ID
                return store.Commit();
            } finally {
                if(store!=null && Marshal.IsComObject(store)) Marshal.ReleaseComObject(store);
            }
        }
    }
}
"@ -ErrorAction Stop
        }
        [void][FeriasDCE.TaskbarIdentityV3]::SetCurrentProcessExplicitAppUserModelID($script:AppId)
        Write-DiagLog "Identidade visual própria do Férias DCE V3 carregada."
    } catch {
        Write-DiagLog "Não foi possível aplicar toda a identidade visual; o sistema continuará normalmente." "WARN" $_
    }
}

function Set-AppWindowIdentity($frm){
    if($null -eq $frm -or $frm.Handle -eq [IntPtr]::Zero){ return }
    try {
        if($null -ne $script:AppIconLarge){
            [void][FeriasDCE.TaskbarIdentityV3]::SendMessage($frm.Handle,0x0080,[IntPtr]1,$script:AppIconLarge.Handle)
        }
        if($null -ne $script:AppIconSmall){
            [void][FeriasDCE.TaskbarIdentityV3]::SendMessage($frm.Handle,0x0080,[IntPtr]0,$script:AppIconSmall.Handle)
        }
        [void][FeriasDCE.WindowAppIdentity]::Apply(
            $frm.Handle,
            $script:AppId,
            $script:RelaunchCommand,
            "Planejamento de Férias DCE",
            $script:RelaunchIconResource
        )
    } catch {
        Write-DiagLog "Falha ao aplicar identidade explícita na janela/taskbar." "WARN" $_
    }
}

function Apply-AppBranding($frm){
    if($null -eq $frm){ return }
    try {
        $frm.ShowInTaskbar=$true
        if($null -ne $script:AppIconLarge){
            $frm.Icon=$script:AppIconLarge
            $frm.ShowIcon=$true
        } elseif($null -ne $script:AppIcon){
            $frm.Icon=$script:AppIcon
            $frm.ShowIcon=$true
        }
        $frm.add_HandleCreated({ param($sender,$e) Set-AppWindowIdentity $sender })
        # Windows 11 pode recriar/atualizar o botão depois de a janela aparecer.
        # Reaplica nesse momento para não cair no ícone genérico do powershell.exe.
        $frm.add_Shown({ param($sender,$e) Set-AppWindowIdentity $sender })
    } catch { Write-DiagLog "Falha ao aplicar ícone em uma janela." "WARN" $_ }
}

Initialize-AppBranding

function Ensure-Folders {
    foreach($dir in @($script:DataDir,$script:BackupDir,$script:LogDir)){
        if(-not (Test-Path -LiteralPath $dir)){ [void][IO.Directory]::CreateDirectory($dir) }
    }
    if(-not (Test-Path -LiteralPath $script:DbFile)){
        if(-not (Test-Path -LiteralPath $script:SeedFile)){ throw "Arquivo inicial não encontrado: $script:SeedFile" }
        [void](Assert-ValidJsonFile $script:SeedFile "Base inicial")
        $seedTmp="$script:DbFile.seed.$PID.$([guid]::NewGuid().ToString('N'))"
        try {
            [IO.File]::Copy($script:SeedFile,$seedTmp,$false)
            [void](Assert-ValidJsonFile $seedTmp "Copia da base inicial")
            try { [IO.File]::Move($seedTmp,$script:DbFile) }
            catch {
                if(-not (Test-Path -LiteralPath $script:DbFile)){throw}
                # Outra instancia inicializou a base primeiro; nao a sobrescrever.
                [void](Assert-ValidJsonFile $script:DbFile "Base inicializada por outra instancia")
            }
        } finally {
            if(Test-Path -LiteralPath $seedTmp){Remove-Item -LiteralPath $seedTmp -Force -ErrorAction SilentlyContinue}
        }
    }
}

function New-EmptyOptionObject {
    return [pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2="";fr_inicio="";fr_fim=""}
}

function Initialize-RecordDefaults($r){
    if($null -eq $r){ return $null }
    foreach($n in 1..3){
        $p="opcao$n"
        if($null -eq $r.PSObject.Properties[$p] -or $null -eq $r.$p){
            $r | Add-Member -NotePropertyName $p -NotePropertyValue (New-EmptyOptionObject) -Force
        }
        foreach($campoFR in @('fr_inicio','fr_fim')){
            if($null -eq $r.$p.PSObject.Properties[$campoFR]){
                $r.$p | Add-Member -NotePropertyName $campoFR -NotePropertyValue '' -Force
            }
        }
    }
    $defaults=[ordered]@{
        opcao_aprovada=0; fr_opcao_aprovada=0; observacoes=""; justificativa_decisao=""; origem_linha_excel=0; cadastro_base=$false
        ferias_bloqueadas=$false; origem_planejamento="ATUAL"; bloqueio_motivo=""; cp_relatorio=""
        fixo_inicio=""; fixo_fim=""; fixo_tipo_relatorio=""; fixo_coluna_origem=""; fixo_importado_em=""; fixo_arquivo_origem=""
        registro_criado_por_importacao_fixa=$false; pre_import_estado_salvo=$false; pre_import_ferias_bloqueadas=$false
        pre_import_origem_planejamento=""; pre_import_bloqueio_motivo=""; pre_import_opcao_aprovada=0
        pre_import_fixo_inicio=""; pre_import_fixo_fim=""; pre_import_fixo_tipo_relatorio=""; pre_import_fixo_coluna_origem=""
        pre_import_fixo_importado_em=""; pre_import_fixo_arquivo_origem=""
        pre_import_fixo_ajustado=$false; pre_import_fixo_inicio_original=""; pre_import_fixo_fim_original=""
        pre_import_fixo_ajustado_em=""; pre_import_fixo_motivo_ajuste=""; pre_import_fixo_observacao_ajuste=""; pre_import_fixo_ajustado_por=""
        fixo_ajustado=$false; fixo_inicio_original=""; fixo_fim_original=""; fixo_ajustado_em=""; fixo_motivo_ajuste=""
        fixo_observacao_ajuste=""; fixo_ajustado_por=""
    }
    foreach($kv in $defaults.GetEnumerator()){
        if($null -eq $r.PSObject.Properties[$kv.Key]){ $r | Add-Member -NotePropertyName $kv.Key -NotePropertyValue $kv.Value -Force }
    }
    return $r
}

function Get-TextSha256([string]$value){
    if($null -eq $value){ $value="" }
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        $bytes=[Text.Encoding]::UTF8.GetBytes($value)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function Assert-DatabaseStructure($db){
    if($null -eq $db -or $db -isnot [pscustomobject]){ throw "A base deve ser um objeto JSON." }
    if($null -eq $db.configuracoes -or $db.configuracoes -isnot [pscustomobject]){
        throw "A base deve conter o objeto configuracoes."
    }
    if($null -eq $db.PSObject.Properties['registros'] -or $db.registros -isnot [array]){
        throw "A base deve conter a lista registros (inclusive quando vazia)."
    }
    if($null -ne $db.PSObject.Properties['historico_ferias'] -and $db.historico_ferias -isnot [array]){
        throw "historico_ferias deve ser uma lista."
    }
    $ids=@{}
    foreach($r in $db.registros){
        if($null -eq $r -or $r -isnot [pscustomobject]){throw "Registro invalido na base."}
        $id=0
        if(-not [int]::TryParse([string]$r.id,[ref]$id) -or $id -le 0){throw "Registro com ID invalido."}
        if($ids.ContainsKey($id)){throw "ID de registro duplicado: $id"}
        $ids[$id]=$true
        foreach($campo in @('opcao_aprovada','fr_opcao_aprovada')){
            if($null -ne $r.PSObject.Properties[$campo]){
                $n=0
                if(-not [int]::TryParse([string]$r.$campo,[ref]$n) -or $n -lt 0 -or $n -gt 3){throw "Decisao invalida no registro $id : $campo"}
            }
        }
    }
}

function Get-PendenciasSemanticasBase($Registros){
    foreach($r in @($Registros)){
        if($null -eq $r){continue}
        $motivos=@()
        if([string]::IsNullOrWhiteSpace([string]$r.matricula)){$motivos+='Matricula ausente'}
        if(Test-RegistroFeriasBloqueadas $r){
            if(-not (Test-RegistroFixoImportado $r)){$motivos+='Fixa bloqueada sem intervalo valido'}
        }else{
            # Ler as decisoes gravadas diretamente: helpers podem descartar escolhas vazias.
            if([int]$r.opcao_aprovada -gt 0){
                $op=$r.('opcao'+[int]$r.opcao_aprovada)
                if($null -eq $op -or [string]::IsNullOrWhiteSpace([string]$op.tipo)){$motivos+='Decisao comum sem opcao preenchida'}
                else{$erro=Validate-Option $op 'Opcao aprovada' ([string]$r.aquisitivo_fim);if($erro){$motivos+=$erro}}
            }
            if([int]$r.fr_opcao_aprovada -gt 0){
                $op=$r.('opcao'+[int]$r.fr_opcao_aprovada)
                $i=Parse-Date ([string]$op.fr_inicio);$f=Parse-Date ([string]$op.fr_fim)
                if($null -eq $i -or $null -eq $f -or ($f-$i).Days -ne 19){$motivos+='Decisao FR sem intervalo de 20 dias valido'}
            }
        }
        foreach($motivo in $motivos){[pscustomobject]@{Id=[int]$r.id;Motivo=[string]$motivo}}
    }
}

function Assert-ValidJsonFile([string]$path,[string]$context="arquivo JSON"){
    if([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)){
        throw "$context não foi localizado: $path"
    }
    $item=Get-Item -LiteralPath $path -ErrorAction Stop
    if($item.Length -le 0){ throw "$context foi criado com tamanho zero: $path" }
    try {
        $raw=Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop
        $obj=$raw | ConvertFrom-Json -ErrorAction Stop
        Assert-DatabaseStructure $obj
    } catch {
        throw "$context contém JSON inválido: $($_.Exception.Message)"
    }
    return $item
}

function Acquire-DatabaseLock([int]$timeoutMs=6000){
    Ensure-Folders
    $sw=[Diagnostics.Stopwatch]::StartNew()
    while($sw.ElapsedMilliseconds -lt $timeoutMs){
        try {
            return [IO.File]::Open($script:DbLockFile,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        } catch [System.UnauthorizedAccessException] {
            throw "Não foi possível criar/acessar o arquivo de bloqueio da base. Verifique permissão de gravação na pasta Dados/rede. Arquivo: $script:DbLockFile"
        } catch [System.Security.SecurityException] {
            throw "O Windows bloqueou o acesso ao arquivo de bloqueio da base por regra de segurança. Arquivo: $script:DbLockFile"
        } catch [IO.IOException] {
            Start-Sleep -Milliseconds 120
        }
    }
    throw "A base de férias está sendo gravada por outra instância. Aguarde alguns segundos e tente novamente."
}

function Get-DiskDbState {
    if(-not (Test-Path -LiteralPath $script:DbFile)){ return [pscustomobject]@{Revision=[long]0;Hash="";Raw=""} }
    $raw=Get-Content -LiteralPath $script:DbFile -Raw -Encoding UTF8 -ErrorAction Stop
    $rev=[long]0
    try {
        $obj=$raw | ConvertFrom-Json -ErrorAction Stop
        Assert-DatabaseStructure $obj
        if($null -ne $obj.PSObject.Properties['revisao_dados']){ $rev=[long]$obj.revisao_dados }
    } catch { throw "A base existente não pôde ser validada antes da gravação: $($_.Exception.Message)" }
    return [pscustomobject]@{Revision=$rev;Hash=(Get-TextSha256 $raw);Raw=$raw}
}

function Invoke-RoutineBackupRetention([int]$keep=50,[int]$keepDailyDays=30){
    try {
        # O timestamp está no nome. Copy-Item pode preservar LastWriteTime do arquivo de origem,
        # portanto a ordenação por Nome é a fonte confiável para retenção cronológica.
        $rotina=@(Get-ChildItem -LiteralPath $script:BackupDir -Filter 'ferias_2027_20*.json' -File -ErrorAction Stop | Sort-Object Name -Descending)
        if($rotina.Count -le $keep){ return }

        $manter=@{}
        foreach($f in @($rotina | Select-Object -First $keep)){ $manter[$f.FullName]=$true }

        # Além dos mais recentes, preserva um backup por dia para até 30 dias distintos.
        $dias=0
        $vistos=@{}
        foreach($f in $rotina){
            if($f.Name -match '^ferias_2027_(\d{8})_'){
                $dia=$Matches[1]
                if(-not $vistos.ContainsKey($dia)){
                    $vistos[$dia]=$true
                    if($dias -lt $keepDailyDays){ $manter[$f.FullName]=$true; $dias++ }
                }
            }
        }

        foreach($f in $rotina){
            if(-not $manter.ContainsKey($f.FullName)){
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            }
        }
    } catch { Write-DiagLog "Falha na retenção de backups rotineiros; backups ANTES_*/MANUAL/UNDO/CONFLITO não são afetados." "WARN" $_ }
}

function Read-DatabaseSnapshotWithRetry([string]$Path,[int]$Attempts=3,[int]$DelayMs=150){
    if([string]::IsNullOrWhiteSpace($Path)){ throw "Caminho da base não informado." }
    $lastError=$null
    for($i=1;$i -le $Attempts;$i++){
        try {
            $raw=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
            if([string]::IsNullOrWhiteSpace($raw)){ throw "A base está vazia." }
            $db=$raw | ConvertFrom-Json -ErrorAction Stop
            Assert-DatabaseStructure $db
            return [pscustomobject]@{Raw=$raw;Db=$db}
        } catch {
            $lastError=$_
            if($i -lt $Attempts){
                Write-DiagLog ("Leitura da base falhou na tentativa $i/$Attempts; nova tentativa em ${DelayMs}ms. Motivo: "+$_.Exception.Message) "WARN"
                Start-Sleep -Milliseconds $DelayMs
            }
        }
    }
    throw $lastError
}

function Load-Database {
    $script:ServidoresIndice=$null
    $script:StartupPhase="LOAD_DATABASE"
    Write-DiagLog "Iniciando leitura da base: $script:DbFile"
    Ensure-Folders
    try {
        $snapshot=Read-DatabaseSnapshotWithRetry $script:DbFile 3 150
        $raw=[string]$snapshot.Raw
        $db=$snapshot.Db
        $script:LoadedRevision=if($null -ne $db.PSObject.Properties["revisao_dados"]){[long]$db.revisao_dados}else{[long]0}
        $script:LoadedDbHash=Get-TextSha256 $raw
        $script:Config = $db.configuracoes
        $script:Records = @($db.registros)
        $script:GridPesquisaGroups=$null; $script:GridPesquisaTotais=$null
        if($null -ne $db.PSObject.Properties["historico_ferias"]){
            $script:HistoricoFerias = @($db.historico_ferias)
        } else {
            $script:HistoricoFerias = @()
        }
        if($null -eq $script:Config.periodos){ $script:Config | Add-Member -NotePropertyName periodos -NotePropertyValue @("M","V","N","D","OUTRO") -Force }
        if($null -eq $script:Config.setores){ $script:Config | Add-Member -NotePropertyName setores -NotePropertyValue @() -Force }
        if($null -eq $script:Config.max_simultaneos){ $script:Config | Add-Member -NotePropertyName max_simultaneos -NotePropertyValue 3 -Force }
        if($null -eq $script:Config.planilha_base){ $script:Config | Add-Member -NotePropertyName planilha_base -NotePropertyValue "" -Force }
        if($null -eq $script:Config.sincronizar_ao_abrir){ $script:Config | Add-Member -NotePropertyName sincronizar_ao_abrir -NotePropertyValue $false -Force }
        if($null -eq $script:Config.ultimo_backup_lote){ $script:Config | Add-Member -NotePropertyName ultimo_backup_lote -NotePropertyValue "" -Force }
        if($null -eq $script:Config.ultimo_manifesto_lote){ $script:Config | Add-Member -NotePropertyName ultimo_manifesto_lote -NotePropertyValue "" -Force }
        if($null -eq $script:Config.limites_setor_periodo){ $script:Config | Add-Member -NotePropertyName limites_setor_periodo -NotePropertyValue @() -Force }
        if($null -eq $script:Config.total_enfermeiros_planejamento){ $script:Config | Add-Member -NotePropertyName total_enfermeiros_planejamento -NotePropertyValue 0 -Force }
        if($null -eq $script:Config.percentual_meses_restritos){ $script:Config | Add-Member -NotePropertyName percentual_meses_restritos -NotePropertyValue 10 -Force }
        if($null -eq $script:Config.meses_restritos){ $script:Config | Add-Member -NotePropertyName meses_restritos -NotePropertyValue @(1) -Force }
        if($null -eq $script:Config.limites_especiais_mensais){ $script:Config | Add-Member -NotePropertyName limites_especiais_mensais -NotePropertyValue @{} -Force }
        if($null -eq $script:Config.planilha_historico_ferias){ $script:Config | Add-Member -NotePropertyName planilha_historico_ferias -NotePropertyValue "" -Force }
        if($null -eq $script:Config.historico_3_anos_importado){ $script:Config | Add-Member -NotePropertyName historico_3_anos_importado -NotePropertyValue $false -Force }
        if($null -eq $script:Config.planilha_ferias_fixas_2027){ $script:Config | Add-Member -NotePropertyName planilha_ferias_fixas_2027 -NotePropertyValue "" -Force }
        if($null -eq $script:Config.ferias_fixas_2027_importadas){ $script:Config | Add-Member -NotePropertyName ferias_fixas_2027_importadas -NotePropertyValue $false -Force }
        if($null -eq $script:Config.ultima_importacao_fixas){ $script:Config | Add-Member -NotePropertyName ultima_importacao_fixas -NotePropertyValue "" -Force }
        if($null -eq $script:Config.ultima_importacao_historico){ $script:Config | Add-Member -NotePropertyName ultima_importacao_historico -NotePropertyValue "" -Force }
        if($null -eq $script:Config.grupo_analise_setores){ $script:Config | Add-Member -NotePropertyName grupo_analise_setores -NotePropertyValue @() -Force }
        if($null -eq $script:Config.grupo_chefia_setores){ $script:Config | Add-Member -NotePropertyName grupo_chefia_setores -NotePropertyValue @() -Force }
        if($null -eq $script:Config.grupo_chefia_servidores){ $script:Config | Add-Member -NotePropertyName grupo_chefia_servidores -NotePropertyValue @() -Force }
        if($null -eq $script:Config.importacao_lancamentos_anulados){ $script:Config | Add-Member -NotePropertyName importacao_lancamentos_anulados -NotePropertyValue @() -Force }
        if($null -eq $script:Config.servidores_excluidos){ $script:Config | Add-Member -NotePropertyName servidores_excluidos -NotePropertyValue @() -Force }
        if($null -eq $script:Config.grupos_chefia){ $script:Config | Add-Member -NotePropertyName grupos_chefia -NotePropertyValue @() -Force }
        if($null -eq $script:Config.limites_grupo_chefia_periodo){ $script:Config | Add-Member -NotePropertyName limites_grupo_chefia_periodo -NotePropertyValue @() -Force }
        if($null -eq $script:Config.feriados_recorrentes){ $script:Config | Add-Member -NotePropertyName feriados_recorrentes -NotePropertyValue @() -Force }
        if($null -eq $script:Config.feriados_especificos){ $script:Config | Add-Member -NotePropertyName feriados_especificos -NotePropertyValue @() -Force }

        # Migração segura centralizada: todo registro, antigo ou novo, recebe a mesma estrutura.
        foreach($r in $script:Records){ [void](Initialize-RecordDefaults $r) }

        $script:PendenciasSemanticas=@(Get-PendenciasSemanticasBase $script:Records)
        foreach($pendencia in $script:PendenciasSemanticas){Write-DiagLog "Conferencia semantica ID=$($pendencia.Id): $($pendencia.Motivo)" 'WARN'}
        # V1.0.58: mantém classificação EXPLÍCITA por setor e vínculo opcional individual de chefia.
        # A inferência pelo nome é usada somente na migração inicial; depois o cadastro passa a ser a fonte de verdade.
        $setoresConhecidos=@()
        $setoresConhecidos += @($script:Config.setores)
        $setoresConhecidos += @($script:Records | ForEach-Object { ([string]$_.setor).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        foreach($s in @($setoresConhecidos | Sort-Object -Unique)){
            $ja=@($script:Config.grupo_analise_setores | Where-Object { [string]$_.setor -eq [string]$s }).Count -gt 0
            if(-not $ja){
                $u=([string]$s).Trim().ToUpperInvariant()
                $g="ASSISTENCIAL"
                if($u -match 'DIRETORIA.*ENFERMAGEM'){ $g="DIRETORIA DE ENFERMAGEM" }
                elseif($u -match 'GER[ÊE]NCIA.*ENFERMAGEM'){ $g="GERÊNCIA DE ENFERMAGEM" }
                $script:Config.grupo_analise_setores=@(@($script:Config.grupo_analise_setores)+[pscustomobject]@{setor=[string]$s;grupo=$g})
            }
        }

        # V1.0.40: cadastro mestre de Grupos de Chefia.
        # Migra automaticamente nomes que já existiam nos vínculos/limites.
        $chefiasMigracao=@()
        $chefiasMigracao += @($script:Config.grupos_chefia)
        $chefiasMigracao += @($script:Config.grupo_chefia_setores | ForEach-Object { ([string]$_.grupo).Trim() })
        $chefiasMigracao += @($script:Config.grupo_chefia_servidores | ForEach-Object { ([string]$_.grupo).Trim() })
        $chefiasMigracao += @($script:Config.limites_grupo_chefia_periodo | ForEach-Object { ([string]$_.grupo).Trim() })
        $script:Config.grupos_chefia=@($chefiasMigracao | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)

        # Qualquer recarga da base invalida os caches de cálculo.
        $script:PlanejOverlapCache=@{}
        $script:PlanejChefiaOverlapCache=@{}
        $script:PlanejTooltipCache=@{}
        $script:PlanejCellIndex=@{}
        $script:PlanejCellIndexBuilt=@{}
        $script:InstitutionalResumoCacheKey=""
        if(Get-Command Rebuild-HistoricoIndex -ErrorAction SilentlyContinue){ Rebuild-HistoricoIndex }

        if($null -ne $script:UiLazyLoaded){$script:UiLazyLoaded.Historico=$false;$script:UiLazyLoaded.Painel=$false;$script:UiLazyLoaded.Planejamento=$false}
        $script:PlanejRefreshDirty=$true
        Write-DiagLog "Base carregada: $(@($script:Records).Count) registro(s), $(@($script:HistoricoFerias).Count) histórico(s)."

    } catch {
        Write-DiagLog "Falha ao abrir a base de dados." "FATAL" $_
        [System.Windows.Forms.MessageBox]::Show("Falha ao abrir a base de dados.`n$($_.Exception.Message)`n`nLog: $script:LogFile","Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        throw
    }
}

function Save-ConflictSnapshot([long]$DiskRevision=0){
    try {
        Ensure-Folders
        $stamp=Get-Date -Format "yyyyMMdd_HHmmss_fff"
        $dest=Join-Path $script:BackupDir ("CONFLITO_${stamp}.json")
        foreach($r in @($script:Records)){ [void](Initialize-RecordDefaults $r) }
        $snap=[ordered]@{
            versao="1.0.70"
            tipo="RESGATE_CONFLITO_CONCORRENCIA"
            criado_em=(Get-Date).ToString("o")
            revisao_carregada=[long]$script:LoadedRevision
            revisao_encontrada_no_disco=[long]$DiskRevision
            configuracoes=$script:Config
            registros=@($script:Records)
            historico_ferias=@($script:HistoricoFerias)
        }
        $json=$snap | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($dest,$json,[Text.UTF8Encoding]::new($true))
        if(-not (Test-Path -LiteralPath $dest) -or (Get-Item -LiteralPath $dest).Length -le 0){ throw "Arquivo de resgate não foi criado corretamente." }
        Write-DiagLog "Snapshot de conflito criado: $dest" "WARN"
        return $dest
    } catch {
        Write-DiagLog "Não foi possível criar o snapshot das alterações em memória durante conflito." "ERROR" $_
        return ""
    }
}


function Save-MemoryRescueSnapshot([string]$Prefixo="ERRO_SALVAMENTO",[string]$Tipo="RESGATE_ERRO_SALVAMENTO",[long]$DiskRevision=0){
    try {
        Ensure-Folders
        $stamp=Get-Date -Format "yyyyMMdd_HHmmss_fff"
        $dest=Join-Path $script:BackupDir ("${Prefixo}_${stamp}.json")
        foreach($r in @($script:Records)){ [void](Initialize-RecordDefaults $r) }
        $snap=[ordered]@{
            versao="1.0.70"
            tipo=$Tipo
            criado_em=(Get-Date).ToString("o")
            revisao_carregada=[long]$script:LoadedRevision
            revisao_encontrada_no_disco=[long]$DiskRevision
            configuracoes=$script:Config
            registros=@($script:Records)
            historico_ferias=@($script:HistoricoFerias)
        }
        $json=$snap | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($dest,$json,[Text.UTF8Encoding]::new($true))
        [void](Assert-ValidJsonFile $dest "Arquivo de resgate")
        Write-DiagLog "Snapshot de resgate criado: $dest" "WARN"
        return $dest
    } catch {
        Write-DiagLog "Não foi possível criar snapshot de resgate das alterações em memória." "ERROR" $_
        return ""
    }
}

function Copy-DatabaseFileInPlace([string]$SourcePath,[string]$DestinationPath,[int]$Attempts=6,[int]$DelayMs=180){
    throw "Sobrescrita nao atomica desativada. Use Commit-DatabaseTempFile com temporario na pasta da base."
}

function Invoke-DatabaseFileReplace([string]$Source,[string]$Destination,[string]$Backup){
    [IO.File]::Replace($Source,$Destination,$Backup)
}

function Invoke-DatabaseAtomicRename([string]$Source,[string]$Destination,[string]$ExpectedOldHash){
    if($env:OS -ne 'Windows_NT'){throw 'A alternativa de renomeacao atomica exige Windows.'}
    # O rename troca a identidade do arquivo. Nao alterar silenciosamente proprietario/grupo/DACL.
    $sections=[Security.AccessControl.AccessControlSections]::Owner -bor [Security.AccessControl.AccessControlSections]::Group -bor [Security.AccessControl.AccessControlSections]::Access
    $srcAcl=Get-Acl -LiteralPath $Source -ErrorAction Stop
    $dstAcl=Get-Acl -LiteralPath $Destination -ErrorAction Stop
    $srcSecurity=$srcAcl.GetSecurityDescriptorSddlForm($sections)
    $dstSecurity=$dstAcl.GetSecurityDescriptorSddlForm($sections)
    if($srcSecurity -ne $dstSecurity){
        throw 'Renomeacao alternativa cancelada: proprietario, grupo ou permissoes do temporario diferem da base. Nao foram modificadas permissoes.'
    }
    $sensitive=[IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::Hidden -bor [IO.FileAttributes]::System -bor [IO.FileAttributes]::Encrypted -bor [IO.FileAttributes]::Compressed
    $srcAttributes=[IO.File]::GetAttributes($Source)
    $dstAttributes=[IO.File]::GetAttributes($Destination)
    if(($dstAttributes -band [IO.FileAttributes]::ReadOnly) -ne 0){throw 'A base esta marcada como somente leitura; nao sera alterada.'}
    if(($srcAttributes -band $sensitive) -ne ($dstAttributes -band $sensitive)){
        throw 'Renomeacao alternativa cancelada: atributos protegidos/compressao/criptografia diferem entre temporario e base.'
    }
    if((Get-TextSha256 ([IO.File]::ReadAllText($Destination,[Text.Encoding]::UTF8))) -ne $ExpectedOldHash){
        throw 'A base mudou durante a preparacao da renomeacao. Gravacao cancelada para preservar alteracoes externas.'
    }
    if(-not ('FeriasDCE.AtomicFileNative' -as [type])){
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace FeriasDCE {
    public static class AtomicFileNative {
        [DllImport("kernel32.dll", EntryPoint="MoveFileExW", CharSet=CharSet.Unicode, SetLastError=true, ExactSpelling=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MoveFileEx(string existingName, string newName, uint flags);
    }
}
"@ -ErrorAction Stop
    }
    if((Get-TextSha256 ([IO.File]::ReadAllText($Destination,[Text.Encoding]::UTF8))) -ne $ExpectedOldHash){
        throw 'A base mudou antes da renomeacao. Gravacao cancelada.'
    }
    # REPLACE_EXISTING | WRITE_THROUGH. Sem COPY_ALLOWED e sem apagar primeiro o destino.
    if(-not [FeriasDCE.AtomicFileNative]::MoveFileEx($Source,$Destination,9)){
        $code=[Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw [ComponentModel.Win32Exception]::new($code,('A rede/Windows recusou a renomeacao com substituicao (codigo '+$code+').'))
    }
}

function Invoke-DatabaseCompatibleReplace([string]$Source,[string]$Destination,[string]$Backup){
    # Chamado sob o lock da base. Captura o estado ANTES de File.Replace para detectar falhas parciais.
    $oldHash=Get-TextSha256 ([IO.File]::ReadAllText($Destination,[Text.Encoding]::UTF8))
    $newHash=Get-TextSha256 ([IO.File]::ReadAllText($Source,[Text.Encoding]::UTF8))
    try {
        Invoke-DatabaseFileReplace $Source $Destination $Backup
        Write-DiagLog 'Substituicao concluida por File.Replace.' 'INFO'
        return
    } catch {
        $replaceError=$_
        $baseError=$_.Exception.GetBaseException()
        $nativeCode=$baseError.HResult -band 0xffff
        if($baseError -isnot [UnauthorizedAccessException] -and $nativeCode -notin @(1,5,50)){
            throw
        }
        # Nao continuar se Replace moveu algum arquivo parcialmente ou houve alteracao externa.
        if(-not [IO.File]::Exists($Source) -or -not [IO.File]::Exists($Destination)){throw $replaceError}
        if((Get-TextSha256 ([IO.File]::ReadAllText($Destination,[Text.Encoding]::UTF8))) -ne $oldHash){throw $replaceError}
        if((Get-TextSha256 ([IO.File]::ReadAllText($Source,[Text.Encoding]::UTF8))) -ne $newHash){throw $replaceError}
        $safetyBackup=$Backup
        if([string]::IsNullOrWhiteSpace($safetyBackup)){
            $safetyBackup=$Destination+'.antes_rollback.'+[guid]::NewGuid().ToString('N')
        }
        if(-not [IO.File]::Exists($safetyBackup)){
            [IO.File]::Copy($Destination,$safetyBackup,$false)
        }
        if((Get-TextSha256 ([IO.File]::ReadAllText($safetyBackup,[Text.Encoding]::UTF8))) -ne $oldHash){
            throw 'Backup anterior diverge da base. Renomeacao alternativa cancelada.'
        }
        Write-DiagLog ('File.Replace recusado (codigo '+$nativeCode+'). Tentando renomeacao com substituicao, sem copia sobre a base. Backup: '+$safetyBackup) 'WARN'
        Invoke-DatabaseAtomicRename $Source $Destination $oldHash
        Write-DiagLog 'Substituicao concluida por renomeacao Windows (MoveFileEx), mantendo validacao posterior e lock.' 'INFO'
    }
}

function Commit-DatabaseTempFile([string]$TempPath,[string]$DestinationPath,[string]$RollbackPath=""){
    if([string]::IsNullOrWhiteSpace($TempPath) -or -not (Test-Path -LiteralPath $TempPath)){
        throw "Arquivo temporario de gravacao nao encontrado: $TempPath"
    }
    if([string]::IsNullOrWhiteSpace($DestinationPath)){ throw "Caminho da base nao informado." }
    $tempFull=[IO.Path]::GetFullPath($TempPath)
    $destFull=[IO.Path]::GetFullPath($DestinationPath)
    if($tempFull -eq $destFull){ throw "Origem temporaria e destino devem ser diferentes." }
    if([IO.Path]::GetDirectoryName($tempFull) -ne [IO.Path]::GetDirectoryName($destFull)){
        throw "A gravacao atomica exige temporario e base na mesma pasta."
    }
    [void](Assert-ValidJsonFile $tempFull "Arquivo temporario")
    $expectedHash=Get-TextSha256 ([IO.File]::ReadAllText($tempFull,[Text.Encoding]::UTF8))
    $replaceBackup="$destFull.replacebak.$PID.$([guid]::NewGuid().ToString('N'))"
    $committed=$false
    try {
        if(Test-Path -LiteralPath $destFull){
            # Se ACL/SMB negar rename/delete, falha sem truncar a base ativa.
            for($attempt=1;$attempt -le 6;$attempt++){
                try {
                    Invoke-DatabaseCompatibleReplace $tempFull $destFull $replaceBackup
                    break
                } catch [IO.IOException] {
                    if($attempt -ge 6 -or -not (Test-Path -LiteralPath $tempFull)){throw}
                    Start-Sleep -Milliseconds 150
                }
            }
        } else {
            [IO.File]::Move($tempFull,$destFull)
        }
        $committed=$true
        [void](Assert-ValidJsonFile $destFull "Base apos gravacao atomica")
        $actualHash=Get-TextSha256 ([IO.File]::ReadAllText($destFull,[Text.Encoding]::UTF8))
        if($actualHash -ne $expectedHash){ throw "Conteudo gravado diverge do temporario validado." }
    } catch {
        $originalError=$_
        Write-DiagLog "Falha na gravacao atomica. Nao sera usada sobrescrita parcial da base." "ERROR" $_
        if($committed -and (Test-Path -LiteralPath $replaceBackup)){
            try {
                [void](Assert-ValidJsonFile $replaceBackup "Backup de rollback")
                Invoke-DatabaseCompatibleReplace $replaceBackup $destFull $null
            } catch { Write-DiagLog "Rollback atomico falhou; backup preservado em $replaceBackup" "FATAL" $_ }
        }
        throw "Gravacao nao concluida: a substituicao normal ou alternativa foi recusada ou nao pode ser validada. Nao foi usada sobrescrita direta. Verifique o log, acesso da rede e a base antes de repetir. Detalhe: $($originalError.Exception.Message)"
    }
    # Limpeza e posterior ao commit; falha de limpeza nao desfaz gravacao bem-sucedida.
    if(Test-Path -LiteralPath $replaceBackup){
        try { Remove-Item -LiteralPath $replaceBackup -Force -ErrorAction Stop }
        catch { Write-DiagLog "Backup temporario preservado apos commit: $replaceBackup" "WARN" $_ }
    }
    return $true
}

function Save-Database {
    $script:ServidoresIndice=$null
    $lockStream=$null
    $tmp=$null
    $bk=""
    try {
        Write-DiagLog "Salvando base operacional com proteção de concorrência."
        $lockStream=Acquire-DatabaseLock 6000
        $disk=Get-DiskDbState

        # Proteção entre PCs/instâncias: se o arquivo mudou desde o Load/último Save,
        # não sobrescreve silenciosamente o trabalho de outra pessoa.
        if($script:LoadedDbHash -and $disk.Hash -and $disk.Hash -ne $script:LoadedDbHash){
            $resgate=Save-ConflictSnapshot ([long]$disk.Revision)
            $msg="A base foi alterada por outra instância/usuário desde que esta tela foi carregada. Para evitar perda de dados, esta gravação foi CANCELADA."
            if($resgate){
                $msg += "`n`nSuas alterações atuais foram preservadas em:`n$resgate"
            } else {
                $msg += "`n`nATENÇÃO: não foi possível criar o arquivo de resgate das alterações em memória. Consulte o log técnico."
            }
            $msg += "`n`nFeche e abra novamente o sistema para carregar a versão mais recente antes de repetir a alteração."
            Write-DiagLog $msg "ERROR"
            [System.Windows.Forms.MessageBox]::Show($msg,"Conflito de gravação — Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            throw "CONFLITO_SALVAMENTO_TRATADO: gravação cancelada por alteração externa da base."
        }

        $script:PlanejOverlapCache=@{}
        $script:PlanejChefiaOverlapCache=@{}
        $script:PlanejTooltipCache=@{}
        $script:PlanejCellIndex=@{}
        $script:PlanejCellIndexBuilt=@{}
        $script:InstitutionalResumoCacheKey=""

        if(Test-Path -LiteralPath $script:DbFile){
            $stamp=Get-Date -Format "yyyyMMdd_HHmmss_fff"
            $bk=Join-Path $script:BackupDir "ferias_2027_$stamp.json"
            Copy-Item -LiteralPath $script:DbFile -Destination $bk -Force -ErrorAction Stop
            [void](Assert-ValidJsonFile $bk "Backup rotineiro")
        }

        foreach($r in @($script:Records)){ [void](Initialize-RecordDefaults $r) }
        $newRevision=[long]$disk.Revision+1
        $db = [ordered]@{
            versao = "1.0.70"
            revisao_dados = $newRevision
            ultima_gravacao_utc = [DateTime]::UtcNow.ToString("o")
            ano_planejamento = 2027
            configuracoes = $script:Config
            registros = @($script:Records)
            historico_ferias = @($script:HistoricoFerias)
        }
        $tmp = "$script:DbFile.tmp.$PID.$([guid]::NewGuid().ToString('N'))"
        $json = $db | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($tmp,$json,[System.Text.UTF8Encoding]::new($true))

        # Valida o arquivo temporário antes de tocar na base operacional.
        [void](Assert-ValidJsonFile $tmp "Arquivo temporário de gravação")

        [void](Commit-DatabaseTempFile $tmp $script:DbFile $bk)
        $tmp=$null

        # Confirma que a base final pode ser relida e corresponde à revisão recém-gravada.
        $final=Get-DiskDbState
        if([long]$final.Revision -ne $newRevision){ throw "A validação pós-gravação encontrou revisão inesperada na base." }
        $script:GridPesquisaGroups=$null; $script:GridPesquisaTotais=$null
        $script:LoadedRevision=[long]$final.Revision
        $script:LoadedDbHash=[string]$final.Hash

        Invoke-RoutineBackupRetention 50 30
        if($null -ne $script:UiLazyLoaded){$script:UiLazyLoaded.Historico=$false;$script:UiLazyLoaded.Painel=$false;$script:UiLazyLoaded.Planejamento=$false}
        $script:PlanejRefreshDirty=$true
        Write-DiagLog "Base salva com sucesso. Revisão=$newRevision"
        return $true
    } catch {
        $msgErro=[string]$_.Exception.Message
        if($msgErro -like 'CONFLITO_SALVAMENTO_TRATADO:*'){
            Write-DiagLog "Conflito de gravação já tratado; nenhuma segunda caixa será exibida." "WARN"
        } else {
            $revDisco=0
            try { if($null -ne $disk){ $revDisco=[long]$disk.Revision } } catch {}
            $resgateFalha=Save-MemoryRescueSnapshot "ERRO_SALVAMENTO" "RESGATE_ERRO_SALVAMENTO" $revDisco
            Write-DiagLog "Falha ao salvar a base de dados." "ERROR" $_
            $extra=if($resgateFalha){"`n`nAs alterações em memória foram preservadas em:`n$resgateFalha"}else{""}
            [System.Windows.Forms.MessageBox]::Show("Não foi possível salvar os dados.`n$($msgErro)`n`nA memória do sistema será recarregada a partir da base gravada para não exibir alterações que não foram persistidas.$extra`n`nLog: $script:LogFile","Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }

        # V1.0.53: nunca deixa a interface continuar trabalhando com uma cópia em memória
        # diferente do que efetivamente existe no disco depois de uma falha/conflito.
        try {
            Load-Database
            if(Get-Command Refresh-AllAfterMaintenance -ErrorAction SilentlyContinue){
                try { Refresh-AllAfterMaintenance } catch { Write-DiagLog "Falha ao atualizar a interface após rollback de memória." "WARN" $_ }
            }
        } catch { Write-DiagLog "Não foi possível recarregar a base após falha de gravação." "ERROR" $_ }
        throw
    } finally {
        if($tmp -and (Test-Path -LiteralPath $tmp)){
            try { Remove-Item -LiteralPath $tmp -Force -ErrorAction Stop }
            catch { Write-DiagLog "Não foi possível remover arquivo temporário órfão: $tmp" "WARN" $_ }
        }
        if($null -ne $lockStream){ try{$lockStream.Dispose()}catch{} }
    }
}

function Parse-Date([string]$s){
    if([string]::IsNullOrWhiteSpace($s)){ return $null }
    if($null -eq $script:PerfDateCache){$script:PerfDateCache=@{}}
    if($script:PerfDateCache.ContainsKey($s)){return $script:PerfDateCache[$s]}
    $d=[datetime]::MinValue
    $result=$null
    if([datetime]::TryParseExact($s,"yyyy-MM-dd",[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)){$result=$d.Date}
    if($script:PerfDateCache.Count -ge 8192){$script:PerfDateCache.Clear()}
    $script:PerfDateCache[$s]=$result
    return $result
}

function Date-ToStore($d){ if($null -eq $d){ return "" }; return ([datetime]$d).ToString("yyyy-MM-dd") }
function Date-ToBR([string]$s){ $d=Parse-Date $s; if($null -eq $d){ return "" }; return $d.ToString("dd/MM/yyyy") }

function Get-NomeDiaSemana([datetime]$data){
    switch($data.DayOfWeek){
        'Sunday' { return 'domingo' }
        'Monday' { return 'segunda-feira' }
        'Tuesday' { return 'terça-feira' }
        'Wednesday' { return 'quarta-feira' }
        'Thursday' { return 'quinta-feira' }
        'Friday' { return 'sexta-feira' }
        'Saturday' { return 'sábado' }
        default { return '' }
    }
}

function Get-ClassificacaoDia([datetime]$data){
    $d=$data.Date
    $feriado=$null
    foreach($f in @($script:Config.feriados_especificos)){
        if($null -eq $f){ continue }
        if($null -ne $f.PSObject.Properties['ativo'] -and -not [bool]$f.ativo){ continue }
        $fd=Parse-Date ([string]$f.data)
        if($null -ne $fd -and $fd.Date -eq $d){ $feriado=$f; break }
    }
    if($null -eq $feriado){
        foreach($f in @($script:Config.feriados_recorrentes)){
            if($null -eq $f){ continue }
            if($null -ne $f.PSObject.Properties['ativo'] -and -not [bool]$f.ativo){ continue }
            if([int]$f.dia -eq $d.Day -and [int]$f.mes -eq $d.Month){ $feriado=$f; break }
        }
    }
    $diaSemana=Get-NomeDiaSemana $d
    if($null -ne $feriado){
        $desc=([string]$feriado.descricao).Trim(); if(-not $desc){ $desc='Feriado cadastrado' }
        $abr=([string]$feriado.abrangencia).Trim()
        $suf=if($abr){" — $abr"}else{''}
        return [pscustomobject]@{codigo='FERIADO';texto="FERIADO — $desc$suf";descricao=$desc;abrangencia=$abr;dia_semana=$diaSemana;cor=[Drawing.Color]::DarkRed}
    }
    if($d.DayOfWeek -eq [DayOfWeek]::Saturday -or $d.DayOfWeek -eq [DayOfWeek]::Sunday){
        return [pscustomobject]@{codigo='FS';texto="FS — $diaSemana";descricao='';abrangencia='';dia_semana=$diaSemana;cor=[Drawing.Color]::DarkOrange}
    }
    return [pscustomobject]@{codigo='DIA ÚTIL';texto="DIA ÚTIL — $diaSemana";descricao='';abrangencia='';dia_semana=$diaSemana;cor=[Drawing.Color]::DarkGreen}
}

function Get-ClassificacaoDataStore([string]$dataStore){
    $d=Parse-Date $dataStore
    if($null -eq $d){ return $null }
    return Get-ClassificacaoDia $d
}

function Update-OptionDayInfo($o){
    if($null -eq $o){ return }
    foreach($par in @(@('I1','Day1'),@('I2','Day2'))){
        $dp=$o.($par[0]); $lbl=$o.($par[1])
        if($null -eq $dp -or $null -eq $lbl){ continue }
        if(-not $dp.Checked){ $lbl.Text=''; $lbl.ForeColor=[Drawing.Color]::DimGray; continue }
        $info=Get-ClassificacaoDia ([datetime]$dp.Value)
        if($null -ne $info){
            $lbl.Text=[string]$info.codigo; $lbl.ForeColor=$info.cor; $lbl.Tag=[string]$info.texto
            if($null -ne $o.PSObject.Properties['Tip'] -and $null -ne $o.Tip){ try { $o.Tip.SetToolTip($lbl,[string]$info.texto) } catch {} }
        }
    }
}

function New-FeriadoId { return [guid]::NewGuid().ToString('N') }

function Refresh-FeriadosLists {
    try {
        if($null -ne $script:gridFeriadosRec){
            $script:gridFeriadosRec.Rows.Clear()
            foreach($f in @($script:Config.feriados_recorrentes | Sort-Object mes,dia,descricao)){
                $i=$script:gridFeriadosRec.Rows.Add(); $r=$script:gridFeriadosRec.Rows[$i]
                $r.Cells['frId'].Value=[string]$f.id
                $r.Cells['frData'].Value=('{0:00}/{1:00}' -f [int]$f.dia,[int]$f.mes)
                $r.Cells['frDesc'].Value=[string]$f.descricao
                $r.Cells['frAbr'].Value=[string]$f.abrangencia
                $r.Cells['frAtivo'].Value=if($null -eq $f.PSObject.Properties['ativo']){'SIM'}elseif([bool]$f.ativo){'SIM'}else{'NÃO'}
            }
        }
        if($null -ne $script:gridFeriadosEsp){
            $script:gridFeriadosEsp.Rows.Clear()
            foreach($f in @($script:Config.feriados_especificos | Sort-Object data,descricao)){
                $i=$script:gridFeriadosEsp.Rows.Add(); $r=$script:gridFeriadosEsp.Rows[$i]
                $r.Cells['feId'].Value=[string]$f.id
                $r.Cells['feData'].Value=Date-ToBR ([string]$f.data)
                $r.Cells['feDesc'].Value=[string]$f.descricao
                $r.Cells['feAbr'].Value=[string]$f.abrangencia
                $r.Cells['feAtivo'].Value=if($null -eq $f.PSObject.Properties['ativo']){'SIM'}elseif([bool]$f.ativo){'SIM'}else{'NÃO'}
            }
        }
        foreach($o in @($script:Opt1,$script:Opt2,$script:Opt3)){ if($null -ne $o){ Update-OptionDayInfo $o } }
    } catch { Write-DiagLog 'Falha ao atualizar cadastro de feriados.' 'WARN' $_ }
}

function Get-AnoEtapaRemanescente($r){
    if($null -eq $r){ return 2026 }
    $d=Parse-Date ([string]$r.fixo_inicio)
    if($null -eq $d){
        foreach($b in (Get-OptionBlocksPlanejamento $r)){ if($null -ne $b.inicio){ $d=[datetime]$b.inicio; break } }
    }
    if($null -ne $d){ return ([int]$d.Year - 1) }
    return 2026
}

function Get-RotuloEtapaFixa($r){
    # Uma quinzena unica importada nao comprova que seja a 2a etapa.
    # Respeitar a informacao oficial do RH, sem exigir parcela anterior.
    if($null -eq $r){ return "FÉRIAS FIXAS" }
    $ini=Parse-Date ([string]$r.fixo_inicio)
    $fim=Parse-Date ([string]$r.fixo_fim)
    if($null -ne $ini -and $null -ne $fim -and $fim -ge $ini){
        $dias=($fim-$ini).Days+1
        if($dias -eq 15){ return "QUINZENA ÚNICA — FÉRIAS FIXAS (0,5)" }
        if($dias -eq 20){ return "FÉRIAS FIXAS 20 DIAS (1,0)" }
        if($dias -eq 30){ return "FÉRIAS FIXAS 30 DIAS (1,0)" }
        return "FÉRIAS FIXAS — $dias DIAS (CONFERIR DURAÇÃO)"
    }
    return "FÉRIAS FIXAS — PERÍODO A CONFERIR"
}

function New-Button([string]$Text,[int]$X,[int]$Y,[int]$W=110,[int]$H=34){
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$Text; $b.Location=New-Object Drawing.Point($X,$Y); $b.Size=New-Object Drawing.Size($W,$H)
    $b.FlatStyle="Flat"; $b.BackColor=[Drawing.Color]::FromArgb(235,241,248)
    $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(183,200,218)
    $b.FlatAppearance.BorderSize=1
    $b.UseVisualStyleBackColor=$false
    $b.Cursor=[Windows.Forms.Cursors]::Hand
    $b.Font=New-Object Drawing.Font("Segoe UI",9)
    return $b
}
function New-Label([string]$Text,[int]$X,[int]$Y,[int]$W=120,[int]$H=22){
    $l=New-Object System.Windows.Forms.Label
    $l.Text=$Text; $l.Location=New-Object Drawing.Point($X,$Y); $l.Size=New-Object Drawing.Size($W,$H)
    $l.AutoEllipsis=$true
    $l.UseMnemonic=$false
    return $l
}
function New-TextBox([int]$X,[int]$Y,[int]$W=180){
    $t=New-Object System.Windows.Forms.TextBox
    $t.Location=New-Object Drawing.Point($X,$Y); $t.Size=New-Object Drawing.Size($W,26)
    $t.BorderStyle=[Windows.Forms.BorderStyle]::FixedSingle
    $t.Font=New-Object Drawing.Font("Segoe UI",9)
    return $t
}
function New-Combo([int]$X,[int]$Y,[int]$W=150,[bool]$Editable=$false){
    $c=New-Object System.Windows.Forms.ComboBox
    $c.Location=New-Object Drawing.Point($X,$Y); $c.Size=New-Object Drawing.Size($W,26)
    $c.DropDownStyle= if($Editable){"DropDown"}else{"DropDownList"}
    $c.FlatStyle=[Windows.Forms.FlatStyle]::Flat
    $c.Font=New-Object Drawing.Font("Segoe UI",9)
    $c.IntegralHeight=$false
    $c.DropDownHeight=280
    return $c
}
function New-DatePicker([int]$X,[int]$Y,[int]$W=120){
    $d=New-Object System.Windows.Forms.DateTimePicker
    $d.Location=New-Object Drawing.Point($X,$Y); $d.Size=New-Object Drawing.Size($W,26)
    $d.Format="Custom"; $d.CustomFormat=" "; $d.ShowCheckBox=$true; $d.Checked=$false
    $d.add_ValueChanged(({ if($d.Checked){ $d.CustomFormat="dd/MM/yyyy" } else { $d.CustomFormat=" " } }).GetNewClosure())
    return $d
}

function Enable-GridSmooth($grid){
    if($null -eq $grid){ return }
    try {
        $prop=$grid.GetType().GetProperty("DoubleBuffered",[Reflection.BindingFlags]"Instance,NonPublic")
        if($null -ne $prop){ $prop.SetValue($grid,$true,$null) }
    } catch {
        # Recurso apenas visual; falha não interfere na aplicação.
    }
}


function Apply-ProfessionalGridStyle($g){
    if($null -eq $g){return}
    try {
        $g.BackgroundColor=[Drawing.Color]::White
        $g.BorderStyle=[Windows.Forms.BorderStyle]::FixedSingle
        $g.GridColor=[Drawing.Color]::FromArgb(223,231,239)
        $g.EnableHeadersVisualStyles=$false
        $g.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(229,237,247)
        $g.ColumnHeadersDefaultCellStyle.ForeColor=[Drawing.Color]::FromArgb(36,53,71)
        $g.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
        $g.ColumnHeadersDefaultCellStyle.WrapMode=[Windows.Forms.DataGridViewTriState]::False
        $g.DefaultCellStyle.SelectionBackColor=[Drawing.Color]::FromArgb(30,105,183)
        $g.DefaultCellStyle.SelectionForeColor=[Drawing.Color]::White
        $g.DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",9)
        $g.RowTemplate.Height=[Math]::Max(26,[int]$g.RowTemplate.Height)
        $g.ShowCellToolTips=$true
        Enable-GridSmooth $g
    } catch { Write-DiagLog ("Estilo de grade não aplicado: "+$_.Exception.Message) "DEBUG" }
}

function Get-PeriodoCategoria([string]$p){
    $u=([string]$p).Trim().ToUpperInvariant()
    switch -Regex ($u){
        '^(M|MATUTINO)$' { return "M" }
        '^(V|VESPERTINO)$' { return "V" }
        '^(N|NOTURNO)$' { return "N" }
        '^(D|DIURNO)$' { return "D" }
        default { return "OUTRO" }
    }
}


# ============================================================
# MOTOR CENTRAL DE REGRAS DE PLANEJAMENTO - V1.0.90
# Regras consolidadas:
# 1) Férias já programadas em programação anterior são compromissos fixos.
# 2) Opções já aceitas na programação atual também são compromissos.
# 3) Registros ainda sem decisão entram na análise pela 1ª opção.
# 4) Limite institucional = TOTAL de enfermeiros / 12, em ferias equivalentes.
# 5) Fixas importadas: periodo unico ja definido pelo RH, sem alternativas de escolha.
# 6) Cada 15 dias = 0,5; 20 dias = 1; 30 dias = 1.
# 7) Setor, turno, chefia e meses criticos: informativos, sem bloqueio automatico.
# 8) Historico: referencia auxiliar, sem exigir quinzena antiga de fixa confirmada.
# ============================================================

function Test-RegistroFeriasBloqueadas($r){
    if($null -eq $r){ return $false }
    try { return [bool]$r.ferias_bloqueadas } catch { return $false }
}

function Test-RegistroFixoImportado($r){
    if($null -eq $r -or -not (Test-RegistroFeriasBloqueadas $r)){ return $false }
    $i=Parse-Date ([string]$r.fixo_inicio)
    $f=Parse-Date ([string]$r.fixo_fim)
    return ($null -ne $i -and $null -ne $f -and $f -ge $i)
}

function Get-FixasAdicionais($r){
    if($null -eq $r -or $null -eq $r.PSObject.Properties['fixos_adicionais']){ return @() }
    return @($r.fixos_adicionais | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.inicio) })
}

function Test-FixaMesmoIntervalo($r,[string]$inicio,[string]$fim){
    if(([string]$r.fixo_inicio -eq $inicio) -and ([string]$r.fixo_fim -eq $fim)){ return $true }
    foreach($f in @(Get-FixasAdicionais $r)){
        if(([string]$f.inicio -eq $inicio) -and ([string]$f.fim -eq $fim)){ return $true }
    }
    return $false
}

function Test-FixaSobreposta($r,[string]$inicio,[string]$fim){
    $ni=Parse-Date $inicio; $nf=Parse-Date $fim
    if($null -eq $ni -or $null -eq $nf -or $nf -lt $ni){ return $true }
    $itens=@([pscustomobject]@{inicio=[string]$r.fixo_inicio;fim=[string]$r.fixo_fim})+@(Get-FixasAdicionais $r)
    foreach($f in $itens){
        $i=Parse-Date ([string]$f.inicio); $e=Parse-Date ([string]$f.fim)
        if($null -ne $i -and $null -ne $e -and $ni -le $e -and $nf -ge $i){ return $true }
    }
    return $false
}

function Test-FixaLimiteAutomatico($r,[string]$inicio,[string]$fim){
    # V1.0.114: ignorar o par de datas vazio de um aquisitivo sem fixa.
    # Conservar o bloqueio para registros incompletos ou malformados.
    $itens=New-Object System.Collections.ArrayList
    $primInicio=[string]$r.fixo_inicio
    $primFim=[string]$r.fixo_fim
    if(-not [string]::IsNullOrWhiteSpace($primInicio) -or -not [string]::IsNullOrWhiteSpace($primFim)){
        if([string]::IsNullOrWhiteSpace($primInicio) -or [string]::IsNullOrWhiteSpace($primFim)){ return $false }
        [void]$itens.Add([pscustomobject]@{inicio=$primInicio;fim=$primFim})
    }
    foreach($f in @(Get-FixasAdicionais $r)){
        [void]$itens.Add([pscustomobject]@{inicio=[string]$f.inicio;fim=[string]$f.fim})
    }
    [void]$itens.Add([pscustomobject]@{inicio=$inicio;fim=$fim})
    $total=0
    foreach($f in $itens){
        $i=Parse-Date ([string]$f.inicio); $e=Parse-Date ([string]$f.fim)
        if($null -eq $i -or $null -eq $e -or $e -lt $i){ return $false }
        $dias=($e-$i).Days+1
        if($dias -notin @(15,30)){ return $false }
        $total+=$dias
    }
    # Regras gerais: ate 30 dias por aquisitivo, em uma ou duas parcelas.
    # Regimes especiais devem passar por rotina administrativa especifica.
    return ($total -le 30 -and $itens.Count -le 2)
}


# V1.0.135-R2 - duas autorizacoes independentes do mesmo aquisitivo.
function Get-NumeroFRConfirmada($r){
    if($null -eq $r){return 0}
    $n=0; try{$n=[int]$r.fr_opcao_aprovada}catch{$n=0}
    if($n -ge 1 -and $n -le 3){return $n}; return 0
}
function Get-NumeroComumConfirmada($r){
    $n=0; try{$n=[int]$r.opcao_aprovada}catch{$n=0}
    if($n -ge 1 -and $n -le 3){return $n}; return 0
}
function Get-BlocosComunsOpcao($r,[int]$n){
    if($n -lt 1 -or $n -gt 3){return @()}
    return @(Get-OptionBlocks $r $n | Where-Object { [string]$_.tipo -ne '20 DIAS' })
}
function Get-BlocoFROpcao($r,[int]$n){
    if($n -lt 1 -or $n -gt 3){return @()}
    $o=$r.("opcao$n"); if($null -eq $o){return @()}
    $a=Parse-Date ([string]$o.fr_inicio);$b=Parse-Date ([string]$o.fr_fim)
    if($null -eq $a -or $null -eq $b -or ($b-$a).Days -ne 19){return @()}
    return @([pscustomobject]@{tipo='20 DIAS';inicio=$a;fim=$b;bloco=3})
}
function Test-ConflitoComumFR($r,[int]$nComum,[int]$nFR){
    if($nComum -le 0 -or $nFR -le 0){return $false}
    foreach($c in @(Get-BlocosComunsOpcao $r $nComum)){
        foreach($f in @(Get-BlocoFROpcao $r $nFR)){
            if(Test-Overlap $c.inicio $c.fim $f.inicio $f.fim){return $true}
        }
    }; return $false
}
# Auditoria preventiva: nao permitir que uma nova aprovacao cruze periodos
# FIXOS ou APROVADOS de outro aquisitivo da mesma matricula.
# Nao muda dados existentes; a auditoria externa aponta conflitos antigos.
function Get-ConflitoEntreAquisitivosAprovados($registro,$blocosCandidatos){
    $mat=([string]$registro.matricula).Trim()
    foreach($outro in @($script:Records)){
        if($null -eq $outro -or [int]$outro.id -eq [int]$registro.id){continue}
        if(([string]$outro.matricula).Trim() -ne $mat){continue}
        $existentes=@(Get-BlocosConfirmadosRegistro $outro)
        foreach($bloco in @($blocosCandidatos)){
            if($null -eq $bloco -or $null -eq $bloco.inicio -or $null -eq $bloco.fim){continue}
            foreach($existente in @($existentes)){
                if($null -eq $existente -or $null -eq $existente.inicio -or $null -eq $existente.fim){continue}
                if((Test-Overlap ([datetime]$bloco.inicio) ([datetime]$bloco.fim) ([datetime]$existente.inicio) ([datetime]$existente.fim))){
                    return "Conflito com outro periodo aquisitivo de $([string]$outro.nome): $(([datetime]$existente.inicio).ToString('dd/MM/yyyy')) a $(([datetime]$existente.fim).ToString('dd/MM/yyyy'))."
                }
            }
        }
    }
    return ''
}

function Get-MesesBlocosAno($blocos,[int]$ano){
    $result=New-Object 'System.Collections.Generic.HashSet[int]'
    foreach($b in @($blocos)){
        if($null -eq $b -or $null -eq $b.inicio -or $null -eq $b.fim){continue}
        $cursor=[datetime]::new($b.inicio.Year,$b.inicio.Month,1)
        $ultimo=[datetime]::new($b.fim.Year,$b.fim.Month,1)
        while($cursor -le $ultimo){if($cursor.Year -eq $ano){[void]$result.Add($cursor.Month)};$cursor=$cursor.AddMonths(1)}
    }
    return @($result | Sort-Object)
}
function Get-OpcaoSomenteComum($op){
    if($null -eq $op -or [string]$op.tipo -in @('20 DIAS','FR 20 DIAS')){return (New-EmptyOptionObject)}
    return [pscustomobject]@{tipo=if([string]$op.tipo -eq '20 DIAS'){''}else{[string]$op.tipo};inicio1=[string]$op.inicio1;fim1=[string]$op.fim1;inicio2=[string]$op.inicio2;fim2=[string]$op.fim2;fr_inicio='';fr_fim=''}
}

function Get-PeriodoFixoResumo($r){
    if(-not (Test-RegistroFixoImportado $r)){ return "" }
    $faixas=@("$(Date-ToBR ([string]$r.fixo_inicio)) a $(Date-ToBR ([string]$r.fixo_fim))")
    foreach($f in @(Get-FixasAdicionais $r)){
        $faixas += "$(Date-ToBR ([string]$f.inicio)) a $(Date-ToBR ([string]$f.fim))"
    }
    return ($faixas -join ' / ')
}

function Get-PeriodoProtegidoResumo($r){
    if($null -eq $r -or -not (Test-RegistroFeriasBloqueadas $r)){ return "" }
    if(Test-RegistroFixoImportado $r){ return Get-PeriodoFixoResumo $r }
    $faixas=@()
    foreach($b in @(Get-OptionBlocksPlanejamento $r)){
        if($null -eq $b){ continue }
        try {
            $ini=([datetime]$b.inicio).ToString('dd/MM/yyyy')
            $fim=([datetime]$b.fim).ToString('dd/MM/yyyy')
            $txt="$ini a $fim"
            if($faixas -notcontains $txt){ $faixas += $txt }
        } catch {}
    }
    if($faixas.Count -gt 0){ return ($faixas -join ' / ') }
    return "DATA FIXA NÃO DISPONÍVEL"
}

function Get-NumeroOpcaoPlanejamento($r){
    if($null -eq $r){ return 0 }
    $ap=0
    try { $ap=[int]$r.opcao_aprovada } catch { $ap=0 }
    if($ap -ge 1 -and $ap -le 3){ return $ap }
    return 1
}

function Get-OpcaoPlanejamento($r){
    if(Test-RegistroFixoImportado $r){
        $ad=@(Get-FixasAdicionais $r)
        return [pscustomobject]@{blocos_fixos=@(Get-OptionBlocksPlanejamento $r);tipo='FÉRIAS FIXAS';inicio1=[string]$r.fixo_inicio;fim1=[string]$r.fixo_fim;inicio2=if($ad.Count -gt 0){[string]$ad[0].inicio}else{''};fim2=if($ad.Count -gt 0){[string]$ad[0].fim}else{''};fr_inicio='';fr_fim=''}
    }
    $nc=Get-NumeroComumConfirmada $r
    if($nc -eq 0){$nc=1} # Projeção enquanto pendente.
    $nf=Get-NumeroFRConfirmada $r
    if($nf -eq 0){$nf=1} # Projeção enquanto pendente.
    $base=Get-OpcaoSomenteComum $r.("opcao$nc")
    $opFR=$r.("opcao$nf")
    if($null -ne $opFR){$base.fr_inicio=[string]$opFR.fr_inicio;$base.fr_fim=[string]$opFR.fr_fim}
    return $base
}

function Get-OptionBlocksPlanejamento($r){
    if(Test-RegistroFixoImportado $r){
        $i=Parse-Date ([string]$r.fixo_inicio)
        $f=Parse-Date ([string]$r.fixo_fim)
        $blocos=@()
        if($null -ne $i -and $null -ne $f){
            $blocos += [pscustomobject]@{tipo="FÉRIAS FIXAS";inicio=$i;fim=$f;bloco=1}
        }
        foreach($ad in @(Get-FixasAdicionais $r)){
            $ai=Parse-Date ([string]$ad.inicio); $af=Parse-Date ([string]$ad.fim)
            if($null -ne $ai -and $null -ne $af -and $af -ge $ai){
                $blocos += [pscustomobject]@{tipo="FÉRIAS FIXAS";inicio=$ai;fim=$af;bloco=($blocos.Count+1)}
            }
        }
        return @($blocos)
    }
    $n=Get-NumeroComumConfirmada $r
    if($n -eq 0){$n=1} # Projecao conservadora enquanto comum estiver pendente.
    $frN=Get-NumeroFRConfirmada $r
    if($frN -eq 0){$frN=1} # Projecao enquanto FR estiver pendente.
    $result=@(Get-BlocosComunsOpcao $r $n) + @(Get-BlocoFROpcao $r $frN)
    return @($result)
}

function Get-BlocosConfirmadosRegistro($r){
    if(Test-RegistroFeriasBloqueadas $r){return @(Get-OptionBlocksPlanejamento $r)}
    $nc=Get-NumeroComumConfirmada $r
    $nf=Get-NumeroFRConfirmada $r
    $blocos=@()
    if($nc -gt 0){$blocos+=@(Get-BlocosComunsOpcao $r $nc)}
    if($nf -gt 0){$blocos+=@(Get-BlocoFROpcao $r $nf)}
    return @($blocos)
}

function Get-MesesPlanejamentoRegistro($r,[int]$ano){
    $meses=New-Object 'System.Collections.Generic.HashSet[int]'
    foreach($b in (Get-OptionBlocksPlanejamento $r)){
        $cursor=[datetime]::new($b.inicio.Year,$b.inicio.Month,1)
        $ultimo=[datetime]::new($b.fim.Year,$b.fim.Month,1)
        while($cursor -le $ultimo){
            if($cursor.Year -eq $ano){ [void]$meses.Add($cursor.Month) }
            $cursor=$cursor.AddMonths(1)
        }
    }
    return @($meses | Sort-Object)
}

function Get-MesesSolicitacoesRegistro($r,[int]$ano){
    $blocos=@()
    if($null -eq $r){return @()}
    if(Test-RegistroFeriasBloqueadas $r){return @(Get-MesesPlanejamentoRegistro $r $ano)}
    $com=Get-NumeroComumConfirmada $r
    $fr=Get-NumeroFRConfirmada $r
    if($com -gt 0){$blocos+=@(Get-BlocosComunsOpcao $r $com)}
    else {foreach($n in 1..3){$blocos+=@(Get-BlocosComunsOpcao $r $n)}}
    if($fr -gt 0){$blocos+=@(Get-BlocoFROpcao $r $fr)}
    else {foreach($n in 1..3){$blocos+=@(Get-BlocoFROpcao $r $n)}}
    return @(Get-MesesBlocosAno $blocos $ano)
}

function Get-StatusPlanejamentoRegistro($r){
    if(Test-RegistroFeriasBloqueadas $r){return 'FIXA'}
    $temComum=$false;$temFR=$false
    foreach($n in 1..3){if((@(Get-BlocosComunsOpcao $r $n)).Count -gt 0){$temComum=$true};if((@(Get-BlocoFROpcao $r $n)).Count -gt 0){$temFR=$true}}
    $okComum=(-not $temComum) -or (Get-NumeroComumConfirmada $r) -gt 0
    $okFR=(-not $temFR) -or (Get-NumeroFRConfirmada $r) -gt 0
    if(($temComum -or $temFR) -and $okComum -and $okFR){return 'ACEITA'}
    return 'PENDENTE'
}
function Get-StatusExibicaoRegistro($r){
    if(Test-RegistroFeriasBloqueadas $r){
        try{if([bool]$r.fixo_ajustado){return 'FIXA AJUSTADA'}}catch{}
        if(Test-RegistroFixoImportado $r){return 'FIXA IMPORTADA'}
        return 'FIXA MANUAL'
    }
    return (Get-StatusPlanejamentoRegistro $r)
}

function Get-CorStatusRegistro($r){
    $s=Get-StatusExibicaoRegistro $r
    switch($s){
        "FIXA AJUSTADA" { return [Drawing.Color]::FromArgb(177,214,255) }
        "FIXA IMPORTADA" { return [Drawing.Color]::FromArgb(211,232,255) }
        "FIXA MANUAL" { return [Drawing.Color]::FromArgb(221,235,247) }
        "ACEITA" { return [Drawing.Color]::FromArgb(226,239,218) }
        default { return [Drawing.Color]::White }
    }
}

function Get-DescricaoBasePlanejamento($r){
    $status=Get-StatusPlanejamentoRegistro $r
    if($status -eq "FIXA"){
        if(Test-RegistroFixoImportado $r){
            if([bool]$r.fixo_ajustado){ return "Férias fixa AJUSTADA: $(Get-PeriodoFixoResumo $r) | Motivo: $([string]$r.fixo_motivo_ajuste)" }
            return "Férias fixa importada: $(Get-PeriodoFixoResumo $r)"
        }
        $n=Get-NumeroOpcaoPlanejamento $r
        return "Férias já programadas / bloqueadas - ${n}ª opção"
    }
    $n=Get-NumeroOpcaoPlanejamento $r
    if($status -eq "ACEITA"){ return "Opção aceita atual - ${n}ª opção" }
    return "Pendente - 1ª opção usada na análise"
}

function Get-NomeMesExtenso([int]$mes){
    $nomes=@("Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")
    if($mes -ge 1 -and $mes -le 12){ return $nomes[$mes-1] }
    return "Mês $mes"
}

function Format-NumeroBR([double]$valor){
    return [string]::Format([Globalization.CultureInfo]::GetCultureInfo("pt-BR"),"{0:0.00}",$valor)
}


# V1.0.90 — índice e interpretação temporal do histórico.
# Regra administrativa de desempate: um mês só é considerado UTILIZADO quando o
# servidor totaliza pelo menos 15 dias efetivos de férias dentro daquele mês-calendário.
# Parcelas/períodos distintos no mesmo mês são somados por DIAS ÚNICOS, evitando
# contagem duplicada em eventual sobreposição. O campo antigo .mes permanece apenas
# como referência de origem/fallback quando as datas históricas não estiverem válidas.
$script:HistoricoMinDiasMesDesempate=15
$script:HistoricoIndexPorMatricula=@{}
$script:HistoricoIndexPorMatAno=@{}
$script:HistoricoIndexPorMatAnoMes=@{}
$script:HistoricoAnosComDados=@{}

function Get-HistoricoMesesAtingidos($h){
    $out=New-Object 'System.Collections.Generic.List[object]'
    $ini=Parse-Date ([string]$h.inicio)
    $fim=Parse-Date ([string]$h.fim)
    if($null -ne $ini -and $null -ne $fim -and $fim.Date -ge $ini.Date){
        $cur=[datetime]::new($ini.Year,$ini.Month,1)
        $last=[datetime]::new($fim.Year,$fim.Month,1)
        while($cur -le $last){
            [void]$out.Add([pscustomobject]@{ano=[int]$cur.Year;mes=[int]$cur.Month})
            $cur=$cur.AddMonths(1)
        }
    } else {
        $a=0; $m=0
        try { $a=[int]$h.ano } catch { $a=0 }
        try { $m=[int]$h.mes } catch { $m=0 }
        if($a -gt 0 -and $m -ge 1 -and $m -le 12){ [void]$out.Add([pscustomobject]@{ano=$a;mes=$m}) }
    }
    # PowerShell 5.1 pode lançar "Os tipos de argumento não correspondem" ao
    # envolver Generic.List[object] diretamente com @(...). ToArray() é compatível.
    return $out.ToArray()
}

function Test-HistoricoAtingeAnoMes($h,[int]$ano,[int]$mes){
    foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
        if([int]$ym.ano -eq $ano -and [int]$ym.mes -eq $mes){ return $true }
    }
    return $false
}

function Test-HistoricoAtingeAno($h,[int]$ano){
    foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
        if([int]$ym.ano -eq $ano){ return $true }
    }
    return $false
}

function Test-HistoricoAtingeMes($h,[int]$mes){
    foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
        if([int]$ym.mes -eq $mes){ return $true }
    }
    return $false
}

function Get-HistoricoMesesTexto($h){
    $nomes=@()
    foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
        $nomes += "$(Get-NomeMesExtenso ([int]$ym.mes))/$([int]$ym.ano)"
    }
    if($nomes.Count -eq 0){ return "Não informado" }
    return (@($nomes | Select-Object -Unique) -join " / ")
}

function Get-HistoricoDiasNoMesRegistro($h,[int]$ano,[int]$mes){
    if($ano -le 0 -or $mes -lt 1 -or $mes -gt 12){ return 0 }
    $ini=Parse-Date ([string]$h.inicio)
    $fim=Parse-Date ([string]$h.fim)
    if($null -ne $ini -and $null -ne $fim -and $fim.Date -ge $ini.Date){
        $mesIni=[datetime]::new($ano,$mes,1)
        $mesFim=$mesIni.AddMonths(1).AddDays(-1)
        $a=$ini.Date; if($a -lt $mesIni.Date){ $a=$mesIni.Date }
        $b=$fim.Date; if($b -gt $mesFim.Date){ $b=$mesFim.Date }
        if($b -ge $a){ return [int](($b-$a).TotalDays+1) }
        return 0
    }

    # Fallback conservador para bases antigas sem datas completas.
    $aRef=0; $mRef=0; $dias=0
    try { $aRef=[int]$h.ano } catch { $aRef=0 }
    try { $mRef=[int]$h.mes } catch { $mRef=0 }
    try { $dias=[int]$h.dias } catch { $dias=0 }
    if($aRef -eq $ano -and $mRef -eq $mes -and $dias -gt 0){
        return [math]::Min($dias,[datetime]::DaysInMonth($ano,$mes))
    }
    return 0
}

function Get-HistoricoDiasUnicosMes([array]$rows,[int]$ano,[int]$mes){
    if($ano -le 0 -or $mes -lt 1 -or $mes -gt 12){ return 0 }
    $diasUnicos=New-Object 'System.Collections.Generic.HashSet[string]'
    $fallback=0
    $mesIni=[datetime]::new($ano,$mes,1)
    $mesFim=$mesIni.AddMonths(1).AddDays(-1)

    foreach($h in @($rows)){
        if($null -eq $h){ continue }
        $ini=Parse-Date ([string]$h.inicio)
        $fim=Parse-Date ([string]$h.fim)
        if($null -ne $ini -and $null -ne $fim -and $fim.Date -ge $ini.Date){
            $a=$ini.Date; if($a -lt $mesIni.Date){ $a=$mesIni.Date }
            $b=$fim.Date; if($b -gt $mesFim.Date){ $b=$mesFim.Date }
            if($b -ge $a){
                $d=$a
                while($d -le $b){
                    [void]$diasUnicos.Add($d.ToString('yyyy-MM-dd'))
                    $d=$d.AddDays(1)
                }
            }
        } else {
            $aRef=0; $mRef=0; $dias=0
            try { $aRef=[int]$h.ano } catch { $aRef=0 }
            try { $mRef=[int]$h.mes } catch { $mRef=0 }
            try { $dias=[int]$h.dias } catch { $dias=0 }
            if($aRef -eq $ano -and $mRef -eq $mes -and $dias -gt 0){ $fallback += $dias }
        }
    }

    $total=$diasUnicos.Count+$fallback
    return [math]::Min($total,[datetime]::DaysInMonth($ano,$mes))
}

function Test-HistoricoMesContaDesempate([array]$rows,[int]$ano,[int]$mes){
    return ((Get-HistoricoDiasUnicosMes $rows $ano $mes) -ge [int]$script:HistoricoMinDiasMesDesempate)
}

function Add-HistoricoIndexItem([hashtable]$index,[string]$key,$item){
    if([string]::IsNullOrWhiteSpace($key)){ return }
    if($index.ContainsKey($key)){ $index[$key]=@($index[$key])+@($item) }
    else { $index[$key]=@($item) }
}

function Rebuild-HistoricoIndex {
    $script:HistoricoIndexPorMatricula=@{}
    $script:HistoricoIndexPorMatAno=@{}
    $script:HistoricoIndexPorMatAnoMes=@{}
    $script:HistoricoAnosComDados=@{}
    foreach($h in @($script:HistoricoFerias)){
        $mat=([string]$h.matricula).Trim()
        if([string]::IsNullOrWhiteSpace($mat)){ continue }
        Add-HistoricoIndexItem $script:HistoricoIndexPorMatricula $mat $h
        $anosVistos=@{}
        foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
            $y=[int]$ym.ano; $m=[int]$ym.mes
            $script:HistoricoAnosComDados[[string]$y]=$true
            Add-HistoricoIndexItem $script:HistoricoIndexPorMatAnoMes "$mat|$y|$m" $h
            if(-not $anosVistos.ContainsKey([string]$y)){
                Add-HistoricoIndexItem $script:HistoricoIndexPorMatAno "$mat|$y" $h
                $anosVistos[[string]$y]=$true
            }
        }
    }
}

function Get-HistoricoIndexItems([hashtable]$index,[string]$key){
    if($null -ne $index -and $index.ContainsKey($key)){ return @($index[$key]) }
    return @()
}

function Test-CargoEnfermeiroHistorico([string]$cargo){
    $u=(Convert-ToUpperSemAcento $cargo).Trim()
    if([string]::IsNullOrWhiteSpace($u)){ return $false }
    if($u -match '^ENFERMEIR[OA](?:$|[\s\-_/(.].*)'){ return $true }
    if($u -match '^ENF(?:$|[\s\-_/(.].*)'){ return $true }
    return $false
}


function Get-HistoricoAnosConsulta {
    $anos=@($script:HistoricoFerias | ForEach-Object {
        foreach($ym in @(Get-HistoricoMesesAtingidos $_)){ [int]$ym.ano }
    } | Sort-Object -Unique)
    if($anos.Count -gt 0){ return $anos }
    # Sem dados, a janela inicial acompanha o ano de planejamento selecionado.
    $ano=2027
    if($null -ne $script:cmbPlanejAno -and $null -ne $script:cmbPlanejAno.SelectedItem){
        $n=0; if([int]::TryParse([string]$script:cmbPlanejAno.SelectedItem,[ref]$n) -and $n -ge 1903 -and $n -le 9999){$ano=$n}
    }
    return @(($ano-3)..($ano-1))
}

function Get-HistoricoRegistroErro($h){
    if($null -eq $h -or [string]::IsNullOrWhiteSpace([string]$h.matricula)){return 'Matrícula ausente.'}
    $ini=Parse-Date ([string]$h.inicio);$fim=Parse-Date ([string]$h.fim)
    if($null -eq $ini -or $null -eq $fim -or $fim -lt $ini){return 'Datas de férias inválidas ou invertidas.'}
    if($ini.Year -lt 1900 -or $fim.Year -gt 9998){return 'Ano de férias fora do intervalo suportado (1900 a 9998).'}
    $ai=([string]$h.aquisitivo_inicio).Trim();$af=([string]$h.aquisitivo_fim).Trim()
    if($ai -or $af){
        $a=Parse-Date $ai;$b=Parse-Date $af
        if($null -eq $a -or $null -eq $b -or $b -lt $a){return 'Período aquisitivo incompleto, inválido ou invertido.'}
    }
    return ''
}

function Get-HistoricoConflito($a,$b){
    if(([string]$a.matricula).Trim() -ne ([string]$b.matricula).Trim()){return ''}
    if((Get-HistoricoChave $a) -eq (Get-HistoricoChave $b)){return ''}
    $ia=Parse-Date ([string]$a.inicio);$fa=Parse-Date ([string]$a.fim)
    $ib=Parse-Date ([string]$b.inicio);$fb=Parse-Date ([string]$b.fim)
    if($null -eq $ia -or $null -eq $fa -or $null -eq $ib -or $null -eq $fb){return ''}
    if($ia -le $fb -and $fa -ge $ib){return 'Períodos sobrepostos do mesmo servidor; conferir datas e aquisitivos. Nada foi substituído.'}
    return ''
}

function Test-CorAmarelaRelatorio($fg,$styles,$theme){
    if($null -eq $fg){return $false}
    $rgb=([string]$fg.rgb).ToUpperInvariant()
    $indexed=-1
    if([int]::TryParse([string]$fg.indexed,[ref]$indexed)){
        # Paleta personalizada prevalece sobre a paleta padrão OOXML.
        $palette=@($styles.styleSheet.colors.indexedColors.rgbColor)
        if($indexed -ge 0 -and $indexed -lt $palette.Count -and $null -ne $palette[$indexed]){$rgb=([string]$palette[$indexed].rgb).ToUpperInvariant()}
        elseif($indexed -in @(6,43)){$rgb=if($indexed -eq 6){'FFFFFF00'}else{'FFFFFF99'}}
    }
    $themeIndex=-1
    if(-not $rgb -and [int]::TryParse([string]$fg.theme,[ref]$themeIndex) -and $null -ne $theme){
        $scheme=@($theme.theme.themeElements.clrScheme.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})
        # OOXML: índices lt1/dk1/lt2/dk2, enquanto o XML declara dk1/lt1/dk2/lt2.
        $order=@(1,0,3,2,4,5,6,7,8,9,10,11)
        if($themeIndex -ge 0 -and $themeIndex -lt $order.Count -and $order[$themeIndex] -lt $scheme.Count){
            $color=$scheme[$order[$themeIndex]].FirstChild
            if($null -ne $color){$rgb=[string]$color.val;if($color.LocalName -eq 'sysClr'){$rgb=[string]$color.lastClr}}
        }
    }
    $rgb=($rgb -replace '^#','').ToUpperInvariant()
    if($rgb.Length -eq 8){$rgb=$rgb.Substring(2)}
    # Não tratar um tema amarelo escurecido até preto/branqueado como marcação amarela.
    # Tons de tema com tint exigem resolução de luminância; não inferir pela cor base.
    $tint=0.0
    if(-not [string]::IsNullOrWhiteSpace([string]$fg.tint)){
        if(-not [double]::TryParse([string]$fg.tint,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$tint) -or $tint -ne 0){return $false}
    }
    # Normalização RGB/ARGB: somente amarelos explicitamente suportados, sem inferir por proximidade.
    return ($rgb -match '^(FFFF00|FFC000|FFF2CC|FFFF99|FFFFCC)$')
}

function Get-HistoricoChave($h){
    $mat=([string]$h.matricula).Trim()
    $ini=([string]$h.inicio).Trim()
    $fim=([string]$h.fim).Trim()
    $aqi=([string]$h.aquisitivo_inicio).Trim()
    $aqf=([string]$h.aquisitivo_fim).Trim()
    if([string]::IsNullOrWhiteSpace($mat)){ return "" }
    return "$mat|$ini|$fim|$aqi|$aqf"
}

function Merge-HistoricoFeriasIncremental([array]$incoming){
    $resultado=New-Object 'System.Collections.Generic.List[object]'
    $auditoria=New-Object 'System.Collections.Generic.List[object]'
    $map=@{};$duplicadosExistentes=0
    foreach($h in @($script:HistoricoFerias)){
        [void]$resultado.Add($h);$k=Get-HistoricoChave $h
        if($k){if($map.ContainsKey($k)){$duplicadosExistentes++}else{$map[$k]=$h}}
    }
    $adicionados=0;$jaExistentes=0;$divergencias=0;$invalidos=0
    foreach($n in @($incoming)){
        $k=Get-HistoricoChave $n;$erro=Get-HistoricoRegistroErro $n
        $acao='IGNORADO_INVALIDO';$detalhe=$erro;$anterior='';$recebido=([string]$n.inicio)+' a '+([string]$n.fim)
        if($erro){$invalidos++}
        elseif($k -and $map.ContainsKey($k)){
            $jaExistentes++;$acao='JA_EXISTENTE_PRESERVADO'
            $detalhe='Período e aquisitivo idênticos; nenhuma alteração realizada.'
            $anterior=([string]$map[$k].inicio)+' a '+([string]$map[$k].fim)
        }else{
            $conflito=''
            foreach($ant in @($resultado.ToArray())+@($incoming)){
                $conflito=Get-HistoricoConflito $n $ant
                if($conflito){$anterior=([string]$ant.inicio)+' a '+([string]$ant.fim);break}
            }
            if($conflito){
                $divergencias++;$acao='CONFERIR_SOBREPOSICAO';$detalhe=$conflito
            }else{
                $n|Add-Member -NotePropertyName importado_em -NotePropertyValue (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Force
                [void]$resultado.Add($n);$map[$k]=$n;$adicionados++
                $acao='NOVO_INCLUIDO';$detalhe='Novo período histórico, sem alteração dos registros anteriores.'
            }
        }
        [void]$auditoria.Add([pscustomobject]@{
            acao=$acao;matricula=[string]$n.matricula;nome=[string]$n.nome
            aquisitivo_inicio=[string]$n.aquisitivo_inicio;aquisitivo_fim=[string]$n.aquisitivo_fim
            periodo_anterior=$anterior;periodo_recebido=$recebido;inicio_recebido=[string]$n.inicio;fim_recebido=[string]$n.fim
            arquivo_origem=[string]$n.arquivo_origem;linha_origem=[string]$n.linha_origem;detalhe=$detalhe
        })
    }
    return [pscustomobject]@{
        itens=$resultado.ToArray();auditoria=$auditoria.ToArray();adicionados=$adicionados;ja_existentes=$jaExistentes
        alterados=0;divergencias=$divergencias;invalidos=$invalidos;preservados=([int]$resultado.Count-$adicionados)
        duplicados_preexistentes_preservados=$duplicadosExistentes
    }
}

function Exportar-AuditoriaHistoricoIncremental([array]$rows){
    $dir=Join-Path $PSScriptRoot 'Logs\Conferencia_Importacoes'
    if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
    $file=Join-Path $dir ('Auditoria_Historico_'+(Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'.csv')
    $colunas=@('acao','matricula','nome','aquisitivo_inicio','aquisitivo_fim','periodo_anterior','periodo_recebido','inicio_recebido','fim_recebido','arquivo_origem','linha_origem','detalhe')
    @($rows) | Select-Object -Property $colunas | Export-Csv -LiteralPath $file -NoTypeInformation -Delimiter ';' -Encoding UTF8 -ErrorAction Stop
    return $file
}

function Get-HistoricoDesempateInfo($r,[int]$mes,[int]$ano){
    if($ano -lt 1903 -or $ano -gt 9999 -or $mes -lt 1 -or $mes -gt 12){throw 'Ano ou mês inválido para consulta histórica.'}
    $mat=([string]$r.matricula).Trim()
    $nomeMes=Get-NomeMesExtenso $mes
    $minDias=[int]$script:HistoricoMinDiasMesDesempate
    if([string]::IsNullOrWhiteSpace($mat) -or -not [bool]$script:Config.historico_3_anos_importado -or @($script:HistoricoFerias).Count -eq 0){
        return [pscustomobject]@{
            disponivel=$false; ocorrencias=0; cobertura=0; prioridade="SEM HISTÓRICO"; penalidade=0
            detalhe="Histórico dos últimos 3 anos ainda não importado para comparação."
            anos=@()
        }
    }
    if($null -eq $script:HistoricoIndexPorMatricula -or $script:HistoricoIndexPorMatricula.Count -eq 0){ Rebuild-HistoricoIndex }

    $anos=@(($ano-3)..($ano-1))
    $ocorrencias=0
    $cobertura=0
    $det=New-Object 'System.Collections.Generic.List[string]'
    $anosInfo=@()
    foreach($y in $anos){
        $existeAno=$script:HistoricoAnosComDados.ContainsKey([string]$y)
        if(-not $existeAno){
            $txt="${y}: histórico desse ano não foi importado"
            [void]$det.Add($txt)
            $anosInfo += [pscustomobject]@{ano=$y;tem_dados=$false;tem_servidor=$false;teve_mes=$false;dias_mes=0;periodos=@();texto=$txt}
            continue
        }
        $anoRows=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatAno "$mat|$y")
        if($anoRows.Count -eq 0){
            $txt="${y}: servidor sem registro no histórico desse ano"
            [void]$det.Add($txt)
            $anosInfo += [pscustomobject]@{ano=$y;tem_dados=$true;tem_servidor=$false;teve_mes=$false;dias_mes=0;periodos=@();texto=$txt}
            continue
        }
        $cobertura++
        $mesRows=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatAnoMes "$mat|$y|$mes")
        $diasMes=Get-HistoricoDiasUnicosMes $mesRows $y $mes
        if($diasMes -ge $minDias){
            # Uma ou várias parcelas no mesmo mês/ano contam uma única vez; dias sobrepostos contam uma vez.
            $ocorrencias++
            $periodos=@($mesRows | ForEach-Object {
                $ii=Date-ToBR ([string]$_.inicio); $ff=Date-ToBR ([string]$_.fim)
                if($ii -and $ff){"$ii a $ff"}else{"período não informado"}
            } | Sort-Object -Unique)
            $txt="${y}: TEVE férias em $nomeMes ($diasMes dia(s) no mês)" + $(if($periodos.Count -gt 0){" ("+($periodos -join ', ')+")"}else{""})
            [void]$det.Add($txt)
            $anosInfo += [pscustomobject]@{ano=$y;tem_dados=$true;tem_servidor=$true;teve_mes=$true;dias_mes=$diasMes;periodos=$periodos;texto=$txt}
        } else {
            $txt=if($diasMes -gt 0){"${y}: NÃO conta como férias em $nomeMes para desempate — $diasMes dia(s), abaixo do mínimo de $minDias"}else{"${y}: Sem férias registradas em $nomeMes (ausência de registro não comprova não utilização)"}
            [void]$det.Add($txt)
            $anosInfo += [pscustomobject]@{ano=$y;tem_dados=$true;tem_servidor=$true;teve_mes=$false;dias_mes=$diasMes;periodos=@();texto=$txt}
        }
    }

    if($cobertura -eq 0){
        return [pscustomobject]@{
            disponivel=$false; ocorrencias=0; cobertura=0; prioridade="SEM COBERTURA"; penalidade=0
            detalhe=($det -join " | "); anos=@($anosInfo)
        }
    }

    $prioridade=if($ocorrencias -eq 0){"ALTA"}elseif($ocorrencias -eq 1){"MÉDIA"}else{"BAIXA"}
    return [pscustomobject]@{
        disponivel=$true
        ocorrencias=$ocorrencias
        cobertura=$cobertura
        prioridade=$(if($cobertura -lt 3){"PARCIAL — $prioridade"}else{$prioridade})
        cobertura_completa=($cobertura -eq 3)
        penalidade=$ocorrencias
        detalhe=("Prioridade histórica: $(if($cobertura -lt 3){'PARCIAL — '}else{''})$prioridade | $ocorrencias ano(s) com pelo menos $minDias dias de férias em $nomeMes, considerando $cobertura ano(s) com dados. Períodos distintos no mesmo mês são somados por dias únicos. " + ($det -join " | "))
        anos=@($anosInfo)
    }
}

# ===== CENTRAL DE HISTÓRICO DE FÉRIAS — V1.0.90 =====
# Usa exclusivamente os registros já importados em $script:HistoricoFerias.
# Não altera decisões, férias fixas ou lançamentos atuais; é uma visão de consulta
# para apoiar o critério de desempate.

$script:HistoricoComparacaoSelecionados=@{}
$script:CarregandoHistoricoUI=$false

function Get-HistoricoFiltroMesNumero {
    if($null -eq $script:cmbHistMes -or $script:cmbHistMes.SelectedIndex -le 0){ return 0 }
    # Índice 1 = janeiro ... índice 12 = dezembro.
    return [int]$script:cmbHistMes.SelectedIndex
}

function Get-HistoricoServidorMeta([string]$matricula){
    $mat=([string]$matricula).Trim()
    $recs=@($script:Records | Where-Object { ([string]$_.matricula).Trim() -eq $mat })
    $cad=$recs | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or
        -not [string]::IsNullOrWhiteSpace([string]$_.periodo)
    } | Select-Object -First 1
    if($null -eq $cad){ $cad=$recs | Select-Object -First 1 }

    $hist=@($script:HistoricoFerias | Where-Object { ([string]$_.matricula).Trim() -eq $mat })
    $h=$hist | Sort-Object ano,mes,inicio -Descending | Select-Object -First 1

    $nome=""
    $setor=""
    $periodo=""
    if($null -ne $cad){
        $nome=([string]$cad.nome).Trim()
        $setor=([string]$cad.setor).Trim()
        $periodo=([string]$cad.periodo).Trim()
    }
    if([string]::IsNullOrWhiteSpace($nome) -and $null -ne $h){ $nome=([string]$h.nome).Trim() }
    if([string]::IsNullOrWhiteSpace($setor) -and $null -ne $h){ $setor=([string]$h.setor_origem).Trim() }
    if([string]::IsNullOrWhiteSpace($periodo) -and $null -ne $h){ $periodo=([string]$h.periodo_origem).Trim() }

    return [pscustomobject]@{
        matricula=$mat
        nome=$nome
        setor=$setor
        periodo=$periodo
    }
}

function Get-HistoricoRegistrosFiltrados([string]$matricula=""){
    if(-not [string]::IsNullOrWhiteSpace($matricula)){
        $mat=([string]$matricula).Trim()
        if($null -eq $script:HistoricoIndexPorMatricula -or $script:HistoricoIndexPorMatricula.Count -eq 0){ Rebuild-HistoricoIndex }
        $rows=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatricula $mat)
    } else {
        $rows=@($script:HistoricoFerias)
    }

    $ano=0
    if($null -ne $script:cmbHistAno -and $null -ne $script:cmbHistAno.SelectedItem){
        $a=[string]$script:cmbHistAno.SelectedItem
        if($a -match '^\d{4}$'){ $ano=[int]$a }
    }
    $mes=Get-HistoricoFiltroMesNumero

    if($ano -gt 0 -and $mes -gt 0){
        $rows=@($rows | Where-Object { Test-HistoricoAtingeAnoMes $_ $ano $mes })
    } elseif($ano -gt 0){
        $rows=@($rows | Where-Object { Test-HistoricoAtingeAno $_ $ano })
    } elseif($mes -gt 0){
        $rows=@($rows | Where-Object { Test-HistoricoAtingeMes $_ $mes })
    }

    return @($rows | Sort-Object inicio -Descending)
}
function Refresh-HistoricoFiltrosListas {
    if($null -eq $script:cmbHistSetor -or $null -eq $script:cmbHistPeriodo){ return }

    $anoSel=if($script:cmbHistAno.SelectedItem){[string]$script:cmbHistAno.SelectedItem}else{"TODOS"}
    $setSel=if($script:cmbHistSetor.SelectedItem){[string]$script:cmbHistSetor.SelectedItem}else{"TODOS"}
    $perSel=if($script:cmbHistPeriodo.SelectedItem){[string]$script:cmbHistPeriodo.SelectedItem}else{"TODOS"}

    $script:CarregandoHistoricoUI=$true
    try {
        $script:cmbHistAno.Items.Clear()
        [void]$script:cmbHistAno.Items.Add('TODOS')
        foreach($yy in @(Get-HistoricoAnosConsulta)){[void]$script:cmbHistAno.Items.Add([string]$yy)}
        $idx=$script:cmbHistAno.Items.IndexOf($anoSel)
        $script:cmbHistAno.SelectedIndex=if($idx -ge 0){$idx}else{0}
        $script:cmbHistSetor.Items.Clear()
        [void]$script:cmbHistSetor.Items.Add("TODOS")
        $setores=@(@($script:Records)+@($script:HistoricoFerias | ForEach-Object {[pscustomobject]@{setor=[string]$_.setor_origem}}) | ForEach-Object { ([string]$_.setor).Trim() } | Where-Object { $_ } | Sort-Object -Unique)
        foreach($s in $setores){ [void]$script:cmbHistSetor.Items.Add($s) }
        $idx=$script:cmbHistSetor.Items.IndexOf($setSel)
        $script:cmbHistSetor.SelectedIndex=if($idx -ge 0){$idx}else{0}

        $script:cmbHistPeriodo.Items.Clear()
        [void]$script:cmbHistPeriodo.Items.Add("TODOS")
        $periodos=@(@($script:Records)+@($script:HistoricoFerias | ForEach-Object {[pscustomobject]@{periodo=[string]$_.periodo_origem}}) | ForEach-Object { ([string]$_.periodo).Trim().ToUpperInvariant() } | Where-Object { $_ } | Sort-Object -Unique)
        foreach($p in $periodos){ [void]$script:cmbHistPeriodo.Items.Add($p) }
        $idx=$script:cmbHistPeriodo.Items.IndexOf($perSel)
        $script:cmbHistPeriodo.SelectedIndex=if($idx -ge 0){$idx}else{0}
    } finally {
        $script:CarregandoHistoricoUI=$false
    }
}


function Refresh-HistoricoResumoVisual([string]$matricula=""){
    $anosConsulta=@(Get-HistoricoAnosConsulta)
    $mat=([string]$matricula).Trim()

    # Limpa os cartões/matriz quando ainda não há servidor selecionado.
    if([string]::IsNullOrWhiteSpace($mat)){
        if($null -ne $script:lblHistCardRegistrosValor){ $script:lblHistCardRegistrosValor.Text="0" }
        if($null -ne $script:lblHistCardMeses15Valor){ $script:lblHistCardMeses15Valor.Text="0" }
        if($null -ne $script:lblHistCardMesAlvoTitulo){ $script:lblHistCardMesAlvoTitulo.Text="MÊS-ALVO" }
        if($null -ne $script:lblHistCardMesAlvoValor){ $script:lblHistCardMesAlvoValor.Text="Selecione um servidor" }
        if($null -ne $script:lblHistCardUltimasValor){ $script:lblHistCardUltimasValor.Text="—" }
        if($null -ne $script:gridHistResumoMeses){ $script:gridHistResumoMeses.Rows.Clear() }
        return
    }

    if($null -eq $script:HistoricoIndexPorMatricula -or $script:HistoricoIndexPorMatricula.Count -eq 0){ Rebuild-HistoricoIndex }
    $all=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatricula $mat)
    $minDias=[int]$script:HistoricoMinDiasMesDesempate

    if($null -ne $script:lblHistCardRegistrosValor){ $script:lblHistCardRegistrosValor.Text=[string]$all.Count }

    # Conta mês/ano que realmente atingiu o critério de 15 dias.
    $qMeses15=0
    foreach($yy in $anosConsulta){
        for($mm=1;$mm -le 12;$mm++){
            $cand=@($all | Where-Object { Test-HistoricoAtingeAnoMes $_ $yy $mm })
            $dias=Get-HistoricoDiasUnicosMes $cand $yy $mm
            if($dias -ge $minDias){ $qMeses15++ }
        }
    }
    if($null -ne $script:lblHistCardMeses15Valor){ $script:lblHistCardMeses15Valor.Text=[string]$qMeses15 }

    # Últimas férias registradas.
    $ultima=$all | Sort-Object inicio -Descending | Select-Object -First 1
    if($null -ne $script:lblHistCardUltimasValor){
        if($null -ne $ultima){
            $ui=Date-ToBR ([string]$ultima.inicio); $uf=Date-ToBR ([string]$ultima.fim)
            $script:lblHistCardUltimasValor.Text=if($ui -and $uf){"$ui a $uf"}elseif($ui){$ui}else{"Registrado"}
        } else { $script:lblHistCardUltimasValor.Text="—" }
    }

    # Cartão específico para o mês escolhido no filtro.
    $mesAlvo=Get-HistoricoFiltroMesNumero
    if($null -ne $script:lblHistCardMesAlvoTitulo -and $null -ne $script:lblHistCardMesAlvoValor){
        if($mesAlvo -gt 0){
            $nomeMes=(Get-NomeMesExtenso $mesAlvo).ToUpperInvariant()
            $script:lblHistCardMesAlvoTitulo.Text="ÚLTIMA VEZ EM $nomeMes"
            $achou=$false
            foreach($yy in @($anosConsulta | Sort-Object -Descending)){
                $cand=@($all | Where-Object { Test-HistoricoAtingeAnoMes $_ $yy $mesAlvo })
                $dias=Get-HistoricoDiasUnicosMes $cand $yy $mesAlvo
                if($dias -ge $minDias){
                    $script:lblHistCardMesAlvoValor.Text="$yy  •  $dias dias"
                    $achou=$true
                    break
                }
            }
            if(-not $achou){ $script:lblHistCardMesAlvoValor.Text="Sem uso registrado (15+d)" }
        } else {
            $script:lblHistCardMesAlvoTitulo.Text="MÊS-ALVO"
            $script:lblHistCardMesAlvoValor.Text="Selecione um mês"
        }
    }

    # Matriz dos anos importados x 12 meses.
    if($null -ne $script:gridHistResumoMeses){
        $script:gridHistResumoMeses.Rows.Clear()
        foreach($yy in @($anosConsulta | Sort-Object -Descending)){
            $idx=$script:gridHistResumoMeses.Rows.Add()
            $rr=$script:gridHistResumoMeses.Rows[$idx]
            $rr.Cells["hrAno"].Value=$yy
            $qual=0
            for($mm=1;$mm -le 12;$mm++){
                $nomeCol="hrM$mm"
                $cand=@($all | Where-Object { Test-HistoricoAtingeAnoMes $_ $yy $mm })
                $dias=Get-HistoricoDiasUnicosMes $cand $yy $mm
                $cell=$rr.Cells[$nomeCol]
                $anoRows=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatAno "$mat|$yy")
                $cell.ToolTipText=if($anoRows.Count -eq 0){'Sem registros desse ano para o servidor.'}else{'Somente dados registrados; ausência no mês não comprova não utilização.'}
                $cell.Style.Alignment=[Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
                if($dias -ge $minDias){
                    $qual++
                    $cell.Value="${dias}d ✓"
                    $cell.Style.BackColor=[Drawing.Color]::FromArgb(206,239,214)
                    $cell.Style.ForeColor=[Drawing.Color]::FromArgb(18,108,55)
                    $cell.Style.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
                } elseif($dias -gt 0){
                    $cell.Value="${dias}d"
                    $cell.Style.BackColor=[Drawing.Color]::FromArgb(255,243,205)
                    $cell.Style.ForeColor=[Drawing.Color]::FromArgb(128,88,0)
                } else {
                    $cell.Value=if($anoRows.Count -eq 0){"?"}else{"—"}
                    $cell.Style.BackColor=[Drawing.Color]::FromArgb(244,246,248)
                    $cell.Style.ForeColor=[Drawing.Color]::Gray
                }
            }
            $rr.Cells["hrQtd"].Value=$qual
            $rr.Cells["hrQtd"].Style.Alignment=[Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
            if($qual -gt 0){
                $rr.Cells["hrQtd"].Style.BackColor=[Drawing.Color]::FromArgb(231,244,255)
                $rr.Cells["hrQtd"].Style.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
            }
        }
        try { if($script:gridHistResumoMeses.Rows.Count -gt 0){ $script:gridHistResumoMeses.ClearSelection() } } catch {}
    }
}

function Refresh-HistoricoDetalheServidor([string]$matricula=""){
    if($null -eq $script:gridHistDetalhes){ return }

    $mat=([string]$matricula).Trim()
    if([string]::IsNullOrWhiteSpace($mat) -and $null -ne $script:gridHistServidores -and $script:gridHistServidores.SelectedRows.Count -gt 0){
        $mat=([string]$script:gridHistServidores.SelectedRows[0].Cells["hsMat"].Value).Trim()
    }

    $script:gridHistDetalhes.Rows.Clear()
    Refresh-HistoricoResumoVisual $mat
    if([string]::IsNullOrWhiteSpace($mat)){
        if($null -ne $script:lblHistServidorDetalhe){ $script:lblHistServidorDetalhe.Text="Selecione um servidor à esquerda para consultar o histórico." }
        return
    }

    $meta=Get-HistoricoServidorMeta $mat
    $rows=Get-HistoricoRegistrosFiltrados $mat
    if($null -ne $script:lblHistServidorDetalhe){
        $filtroAno=if($script:cmbHistAno.SelectedItem){[string]$script:cmbHistAno.SelectedItem}else{"TODOS"}
        $mes=Get-HistoricoFiltroMesNumero
        $filtroMes=if($mes -gt 0){Get-NomeMesExtenso $mes}else{"Todos os meses"}
        $script:lblHistServidorDetalhe.Text="$($meta.nome)  |  Matrícula: $mat  |  Setor atual: $(if($meta.setor){$meta.setor}else{'NÃO INFORMADO'})  |  Período: $(if($meta.periodo){$meta.periodo}else{'NÃO INFORMADO'})`r`nFiltro exibido: Ano $filtroAno | $filtroMes | $($rows.Count) registro(s)"
    }

    foreach($h in $rows){
        $i=$script:gridHistDetalhes.Rows.Add()
        $rr=$script:gridHistDetalhes.Rows[$i]
        $rr.Cells["hdAno"].Value=[int]$h.ano
        $rr.Cells["hdMes"].Value=Get-HistoricoMesesTexto $h
        $aqI=Date-ToBR ([string]$h.aquisitivo_inicio); $aqF=Date-ToBR ([string]$h.aquisitivo_fim)
        $rr.Cells["hdAq"].Value=if($aqI -and $aqF){"$aqI a $aqF"}else{"Não informado"}
        $rr.Cells["hdIni"].Value=Date-ToBR ([string]$h.inicio)
        $rr.Cells["hdFim"].Value=Date-ToBR ([string]$h.fim)
        $rr.Cells["hdDias"].Value=if([int]$h.dias -gt 0){[int]$h.dias}else{""}
        $rr.Cells["hdTipo"].Value=if([int]$h.dias -eq 15){"15 DIAS / PARCELA"}elseif([int]$h.dias -gt 0){"$([int]$h.dias) DIAS"}else{"PERÍODO"}
        $rr.Cells["hdSetor"].Value=[string]$h.setor_origem
        $rr.Cells["hdPer"].Value=[string]$h.periodo_origem
        $rr.Cells["hdOrigem"].Value=[string]$h.arquivo_origem
        $rr.Height=27
        $rr.Visible=$true
    }

    # V1.0.90: força uma apresentação determinística da grade. Em algumas combinações
    # de DPI/tema o WinForms reaproveitava altura/estado visual de linhas e parecia
    # exibir menos registros do que o contador indicava.
    try {
        $script:gridHistDetalhes.AutoSizeRowsMode=[Windows.Forms.DataGridViewAutoSizeRowsMode]::None
        foreach($gr in $script:gridHistDetalhes.Rows){ $gr.Height=27; $gr.Visible=$true }
        if($script:gridHistDetalhes.Rows.Count -gt 0){
            $script:gridHistDetalhes.FirstDisplayedScrollingRowIndex=0
        }
        if($script:gridHistDetalhes.Rows.Count -ne @($rows).Count){
            Write-DiagLog ("Histórico UI: divergência entre registros filtrados ($(@($rows).Count)) e linhas da grade ($($script:gridHistDetalhes.Rows.Count)).") "WARN"
        }
    } catch { Write-DiagLog ("Histórico UI: ajuste final de linhas ignorado: "+$_.Exception.Message) "WARN" }
}

function Refresh-HistoricoServidoresUI {
    if($null -eq $script:gridHistServidores){ return }

    $q=if($null -ne $script:txtHistBusca){(Convert-ToUpperSemAcento $script:txtHistBusca.Text.Trim())}else{""}
    $setor=if($null -ne $script:cmbHistSetor -and $script:cmbHistSetor.SelectedItem){[string]$script:cmbHistSetor.SelectedItem}else{"TODOS"}
    $periodo=if($null -ne $script:cmbHistPeriodo -and $script:cmbHistPeriodo.SelectedItem){[string]$script:cmbHistPeriodo.SelectedItem}else{"TODOS"}

    $matAtual=""
    if($script:gridHistServidores.SelectedRows.Count -gt 0){
        $matAtual=([string]$script:gridHistServidores.SelectedRows[0].Cells["hsMat"].Value).Trim()
    }

    $script:CarregandoHistoricoUI=$true
    try {
        $script:gridHistServidores.Rows.Clear()

        $mats=@($script:HistoricoFerias | ForEach-Object { ([string]$_.matricula).Trim() } | Where-Object {$_} | Sort-Object -Unique)
        $itens=@()
        foreach($mat in $mats){
            $meta=Get-HistoricoServidorMeta $mat
            if($q){
                $hay=Convert-ToUpperSemAcento ("$($meta.matricula) $($meta.nome) $($meta.setor) $($meta.periodo)")
                if($hay -notlike "*$q*"){ continue }
            }
            if($setor -ne "TODOS" -and [string]$meta.setor -ne $setor){ continue }
            if($periodo -ne "TODOS" -and ([string]$meta.periodo).ToUpperInvariant() -ne $periodo.ToUpperInvariant()){ continue }

            $itens += $meta
        }

        foreach($meta in @($itens | Sort-Object nome,matricula)){
            $mat=[string]$meta.matricula
            $i=$script:gridHistServidores.Rows.Add()
            $rr=$script:gridHistServidores.Rows[$i]
            $rr.Cells["hsSel"].Value=$script:HistoricoComparacaoSelecionados.ContainsKey($mat)
            $rr.Cells["hsMat"].Value=$mat
            $rr.Cells["hsNome"].Value=[string]$meta.nome
            $rr.Cells["hsSetor"].Value=[string]$meta.setor
            $rr.Cells["hsPer"].Value=[string]$meta.periodo
            $rr.Cells["hsQtd"].Value=@($script:HistoricoFerias | Where-Object { ([string]$_.matricula).Trim() -eq $mat }).Count
        }

        $selecionou=$false
        if($matAtual){
            foreach($row in $script:gridHistServidores.Rows){
                if(([string]$row.Cells["hsMat"].Value).Trim() -eq $matAtual){
                    $row.Selected=$true
                    if($row.Cells["hsNome"].Visible){ $script:gridHistServidores.CurrentCell=$row.Cells["hsNome"] }
                    $selecionou=$true
                    break
                }
            }
        }
        if(-not $selecionou -and $script:gridHistServidores.Rows.Count -gt 0){
            $script:gridHistServidores.Rows[0].Selected=$true
            $script:gridHistServidores.CurrentCell=$script:gridHistServidores.Rows[0].Cells["hsNome"]
        }
    } finally {
        $script:CarregandoHistoricoUI=$false
    }

    if($null -ne $script:lblHistStatus){
        $total=@($script:HistoricoFerias).Count
        $srv=@($script:HistoricoFerias | Select-Object -ExpandProperty matricula -Unique).Count
        $vis=$script:gridHistServidores.Rows.Count
        $marc=$script:HistoricoComparacaoSelecionados.Keys.Count
        if($total -eq 0){
            $script:lblHistStatus.Text="Histórico ainda não importado. Importe em Configurações > Importações."
            $script:lblHistStatus.ForeColor=[Drawing.Color]::DarkGoldenrod
        } else {
            $script:lblHistStatus.Text="$total registro(s) históricos | $srv servidor(es) no histórico | $vis servidor(es) exibido(s) | $marc selecionado(s) para comparação"
            $script:lblHistStatus.ForeColor=[Drawing.Color]::FromArgb(45,65,85)
        }
    }

    Refresh-HistoricoDetalheServidor
}

function Get-HistoricoResumoAno([array]$rows,[int]$ano,[int]$mesAlvo){
    $r=@($rows | Where-Object { Test-HistoricoAtingeAno $_ $ano })
    if($r.Count -eq 0){ return "SEM REGISTRO" }

    if($mesAlvo -le 0){
        $periodos=@($r | ForEach-Object { Get-HistoricoChave $_ } | Where-Object {$_} | Sort-Object -Unique)
        return "$($periodos.Count) período(s)"
    }

    $mesRows=@($r | Where-Object { Test-HistoricoAtingeAnoMes $_ $ano $mesAlvo })
    $diasMes=Get-HistoricoDiasUnicosMes $mesRows $ano $mesAlvo
    $minDias=[int]$script:HistoricoMinDiasMesDesempate
    if($diasMes -lt $minDias){
        if($diasMes -gt 0){ return "NÃO — ${diasMes}d (<${minDias}d)" }
        return "NÃO"
    }

    $periodos=@($mesRows | ForEach-Object {
        $ii=Date-ToBR ([string]$_.inicio)
        $ff=Date-ToBR ([string]$_.fim)
        if($ii -and $ff){"$ii a $ff"}elseif($ii){$ii}else{"Registrado"}
    } | Sort-Object -Unique)

    if($periodos.Count -eq 1){ return "SIM — ${diasMes}d — $($periodos[0])" }
    return "SIM — ${diasMes}d — "+($periodos -join "; ")
}

function Refresh-HistoricoComparacaoUI {
    if($null -eq $script:gridHistComparacao -or $null -eq $script:gridHistLinhaTempo){ return }

    $script:gridHistComparacao.Rows.Clear()
    $script:gridHistLinhaTempo.Rows.Clear()

    $anosConsulta=@(Get-HistoricoAnosConsulta)
    foreach($col in @($script:gridHistComparacao.Columns | Where-Object {$_.Name -match '^hcAno[0-9]+$'})){
        $script:gridHistComparacao.Columns.Remove($col)
    }
    $pos=4
    foreach($yy in $anosConsulta){
        $col=New-Object Windows.Forms.DataGridViewTextBoxColumn
        $col.Name="hcAno$yy";$col.HeaderText=[string]$yy;$col.Width=165;$col.ReadOnly=$true
        [void]$script:gridHistComparacao.Columns.Add($col);$col.DisplayIndex=$pos;$pos++
    }
    $mats=@($script:HistoricoComparacaoSelecionados.Keys | Sort-Object)
    if($mats.Count -eq 0){
        if($null -ne $script:lblHistCompResumo){
            $script:lblHistCompResumo.Text="Marque dois ou mais servidores à esquerda e clique em COMPARAR SELECIONADOS. Também é possível comparar apenas um servidor."
        }
        return
    }

    $mesAlvo=Get-HistoricoFiltroMesNumero
    $mesRotulo=if($mesAlvo -gt 0){Get-NomeMesExtenso $mesAlvo}else{"TODOS OS MESES"}

    foreach($mat in $mats){
        $meta=Get-HistoricoServidorMeta $mat
        if($null -eq $script:HistoricoIndexPorMatricula -or $script:HistoricoIndexPorMatricula.Count -eq 0){ Rebuild-HistoricoIndex }
        $all=@(Get-HistoricoIndexItems $script:HistoricoIndexPorMatricula ([string]$mat).Trim())
        $rowsMes=if($mesAlvo -gt 0){@($all | Where-Object { Test-HistoricoAtingeMes $_ $mesAlvo })}else{@($all)}

        # Conta somente mês/ano com pelo menos 15 dias efetivos de férias.
        # Se houver mais de uma parcela no mesmo mês, os dias únicos são somados.
        $chaves=@{}
        $rowsMesQualificados=New-Object 'System.Collections.Generic.List[object]'
        $candidatos=@{}
        foreach($h in $rowsMes){
            foreach($ym in @(Get-HistoricoMesesAtingidos $h)){
                if($mesAlvo -gt 0 -and [int]$ym.mes -ne $mesAlvo){ continue }
                $candidatos["$([int]$ym.ano)|$([int]$ym.mes)"]=$true
            }
        }
        foreach($k in @($candidatos.Keys)){
            $p=$k.Split('|'); if($p.Count -ne 2){ continue }
            $yy=[int]$p[0]; $mm=[int]$p[1]
            $candRows=@($all | Where-Object { Test-HistoricoAtingeAnoMes $_ $yy $mm })
            if((Get-HistoricoDiasUnicosMes $candRows $yy $mm) -ge [int]$script:HistoricoMinDiasMesDesempate){
                $chaves[$k]=$true
                foreach($cr in $candRows){ [void]$rowsMesQualificados.Add($cr) }
            }
        }
        $ocorrencias=$chaves.Keys.Count

        $ultima=$all | Sort-Object inicio -Descending | Select-Object -First 1
        $ultimaMes=if($mesAlvo -gt 0){$rowsMesQualificados.ToArray() | Sort-Object inicio -Descending | Select-Object -First 1}else{$ultima}

        $i=$script:gridHistComparacao.Rows.Add()
        $rr=$script:gridHistComparacao.Rows[$i]
        $rr.Cells["hcMat"].Value=$mat
        $rr.Cells["hcNome"].Value=[string]$meta.nome
        $rr.Cells["hcSetor"].Value=[string]$meta.setor
        $rr.Cells["hcPer"].Value=[string]$meta.periodo
        foreach($yy in $anosConsulta){$rr.Cells["hcAno$yy"].Value=Get-HistoricoResumoAno $all $yy $mesAlvo}
        $rr.Cells["hcOc"].Value=$ocorrencias
        $rr.Cells["hcUltMes"].Value=if($null -ne $ultimaMes){Date-ToBR ([string]$ultimaMes.inicio)}else{"—"}
        $rr.Cells["hcUlt"].Value=if($null -ne $ultima){"$(Date-ToBR ([string]$ultima.inicio)) a $(Date-ToBR ([string]$ultima.fim))"}else{"—"}

        # Leitura visual imediata: verde = mês utilizado (15+ dias), amarelo = houve férias
        # mas não atingiu 15 dias, cinza = sem utilização naquele mês-alvo.
        foreach($cn in @($anosConsulta | ForEach-Object {"hcAno$_"})){
            $v=[string]$rr.Cells[$cn].Value
            $rr.Cells[$cn].Style.Alignment=[Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
            if($v -like "SIM*"){
                $rr.Cells[$cn].Style.BackColor=[Drawing.Color]::FromArgb(206,239,214)
                $rr.Cells[$cn].Style.ForeColor=[Drawing.Color]::FromArgb(18,108,55)
                $rr.Cells[$cn].Style.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
            } elseif($v -like "NÃO — *d*"){
                $rr.Cells[$cn].Style.BackColor=[Drawing.Color]::FromArgb(255,243,205)
                $rr.Cells[$cn].Style.ForeColor=[Drawing.Color]::FromArgb(128,88,0)
            } else {
                $rr.Cells[$cn].Style.BackColor=[Drawing.Color]::FromArgb(244,246,248)
                $rr.Cells[$cn].Style.ForeColor=[Drawing.Color]::DimGray
            }
        }
    }

    # Linha do tempo respeita os filtros Ano/Mês da faixa superior.
    foreach($mat in $mats){
        $meta=Get-HistoricoServidorMeta $mat
        foreach($h in (Get-HistoricoRegistrosFiltrados $mat)){
            $i=$script:gridHistLinhaTempo.Rows.Add()
            $rr=$script:gridHistLinhaTempo.Rows[$i]
            $rr.Cells["htNome"].Value=[string]$meta.nome
            $rr.Cells["htMat"].Value=[string]$mat
            $rr.Cells["htAno"].Value=[int]$h.ano
            $rr.Cells["htMes"].Value=Get-HistoricoMesesTexto $h
            $rr.Cells["htIni"].Value=Date-ToBR ([string]$h.inicio)
            $rr.Cells["htFim"].Value=Date-ToBR ([string]$h.fim)
            $rr.Cells["htDias"].Value=if([int]$h.dias -gt 0){[int]$h.dias}else{""}
            $rr.Cells["htSetor"].Value=[string]$h.setor_origem
            $rr.Cells["htPer"].Value=[string]$h.periodo_origem
        }
    }

    if($null -ne $script:lblHistCompResumo){
        $script:lblHistCompResumo.Text="COMPARAÇÃO HISTÓRICA — $($mats.Count) servidor(es) selecionado(s) | Mês-alvo: $mesRotulo.`r`nOs anos exibidos consideram o mês como utilizado somente quando o servidor totaliza pelo menos 15 dias efetivos de férias naquele mês. Parcelas no mesmo mês são somadas por dias únicos. 'Ocorrências' conta mês/ano que atingiu esse mínimo e é apenas apoio ao desempate; não substitui as regras operacionais do planejamento."
    }
}

function Refresh-HistoricoFeriasUI {
    if($null -eq $script:gridHistServidores){ return }
    Refresh-HistoricoFiltrosListas
    Refresh-HistoricoServidoresUI
    Refresh-HistoricoComparacaoUI
}
# ===== FIM CENTRAL DE HISTÓRICO =====

function Get-GrupoAnaliseRegistro($r){
    if($null -eq $r){ return "ASSISTENCIAL" }
    return Get-GrupoAnaliseSetor ([string]$r.setor)
}

function Refresh-PoliticaMensalInfo {
    if($null -eq $script:lblCalculoMensal){ return }
    $total=[int]$numTotalEnf.Value
    $pct=[int]$numPctRestrito.Value
    if($total -le 0){
        $script:lblCalculoMensal.Text="Informe o TOTAL GERAL de enfermeiros: Assistencial + Gerência de Enfermagem + Diretoria de Enfermagem."
        return
    }
    $base=[double]$total/12.0
    $script:lblCalculoMensal.Text="Limite NORMAL: $total ÷ 12 = $($base.ToString('0.00')) férias equivalentes por mês. Meses marcados podem ter limites especiais configurados abaixo."
}

function Refresh-ConfigInfo {
    if($null -eq $script:lblConfigInfo){ return }
    $periodos=@($script:Records | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -or
        -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)
    }).Count
    $servidores=@($script:Records | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.matricula)
    } | Select-Object -ExpandProperty matricula -Unique).Count
    $pend=@($script:Records | Group-Object matricula | Where-Object {
        $cad=$_.Group | Select-Object -First 1
        [string]::IsNullOrWhiteSpace([string]$cad.setor) -or
        [string]::IsNullOrWhiteSpace([string]$cad.periodo)
    }).Count
    $fixas=@($script:Records | Where-Object { Test-RegistroFeriasBloqueadas $_ }).Count
    $chefias=0
    try { $chefias=@(Get-GruposChefiaNomes).Count } catch { $chefias=0 }
    $hist=if([bool]$script:Config.historico_3_anos_importado){"Histórico 3 anos: importado"}else{"Histórico 3 anos: aguardando planilha"}
    $script:PendenciasSemanticas=@(Get-PendenciasSemanticasBase $script:Records)
    $script:lblConfigInfo.Text="Conferencia de dados: $($script:PendenciasSemanticas.Count) pendencia(s) | Base atual: $servidores servidor(es) | $periodos período(s) aquisitivo(s) | $fixas férias fixa(s) | $chefias Grupo(s) de Chefia | $pend cadastro(s) pendente(s) | $hist."
}


function Show-ChefiasPassoAPasso {
    $msg=@"
PASSO A PASSO — SETORES E CHEFIAS

O sistema possui DUAS classificações diferentes:

• GRUPO DE ANÁLISE = Assistencial, Gerência de Enfermagem ou Diretoria de Enfermagem.
• GRUPO DE CHEFIA = reúne setores diferentes que têm a MESMA chefia.

EXEMPLO:
Grupo de Chefia: MATERNO-INFANTIL
Setores marcados: Maternidade + Centro Obstétrico

COMO CADASTRAR:
1. Na aba Cadastros > Setores e Chefias, confirme se os setores já existem.
2. Em '2. Grupos de Chefia', digite um nome para a chefia e clique ADICIONAR.
3. Clique no nome da chefia criada.
4. Em '3. Vínculos desta chefia > Setores da Chefia', marque TODOS os setores que pertencem a ela.
5. Clique SALVAR VÍNCULOS.
6. Se houver exceções, abra 'Servidores da Chefia' e marque SOMENTE os servidores que precisam de vínculo individual.
7. Clique CONFIGURAR LIMITES para informar o limite do Grupo de Chefia por período.

IMPORTANTE:
• Um setor pertence a apenas um Grupo de Chefia.
• Um servidor pode ter um vínculo individual de chefia; quando existir, ele prevalece sobre a chefia herdada do setor.
• O servidor nunca é contado duas vezes.
• Setores sem vínculo continuam sendo analisados normalmente pelo limite individual.
• O Grupo de Chefia soma os servidores efetivamente vinculados no mesmo mês + período.
"@
    [Windows.Forms.MessageBox]::Show($msg,"Como cadastrar Setores e Chefias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Refresh-ChefiasCadastroUI {
    if($null -eq $script:lstChefias){ return }

    $selecionada=""
    if($null -ne $script:lstChefias.SelectedItem){ $selecionada=[string]$script:lstChefias.SelectedItem }

    $script:CarregandoChefiasUI=$true
    try {
        $script:lstChefias.Items.Clear()
        foreach($g in (Get-GruposChefiaNomes)){ [void]$script:lstChefias.Items.Add($g) }

        if($selecionada){
            $idx=$script:lstChefias.Items.IndexOf($selecionada)
            if($idx -ge 0){ $script:lstChefias.SelectedIndex=$idx }
        }
        if($script:lstChefias.SelectedIndex -lt 0 -and $script:lstChefias.Items.Count -gt 0){
            $script:lstChefias.SelectedIndex=0
        }
    } finally {
        $script:CarregandoChefiasUI=$false
    }
    Load-SetoresChefiaSelecionada
}

function Refresh-ServidoresChefiaUI {
    if($null -eq $script:gridServidoresChefia){ return }
    $grupo=""
    if($null -ne $script:lstChefias -and $null -ne $script:lstChefias.SelectedItem){ $grupo=[string]$script:lstChefias.SelectedItem }
    $q=if($null -ne $script:txtBuscaServidorChefia){$script:txtBuscaServidorChefia.Text.Trim().ToUpperInvariant()}else{""}

    $script:gridServidoresChefia.Rows.Clear()
    $groups=@($script:Records | Group-Object matricula | Sort-Object {($_.Group | Select-Object -First 1).nome})
    foreach($gg in $groups){
        $recs=@($gg.Group)
        $cad=$recs | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } | Select-Object -First 1
        if($null -eq $cad){ $cad=$recs | Select-Object -First 1 }
        if($null -eq $cad){ continue }

        $mat=([string]$cad.matricula).Trim()
        $nome=([string]$cad.nome).Trim()
        $setor=([string]$cad.setor).Trim()
        $direta=Get-GrupoChefiaServidor $mat
        $porSetor=if($setor){Get-GrupoChefiaSetor $setor}else{""}
        $origem=if($direta){
            if($direta -eq $grupo){"INDIVIDUAL — ESTA CHEFIA"}else{"INDIVIDUAL — $direta"}
        } elseif($porSetor){
            if($porSetor -eq $grupo){"HERDADO DO SETOR"}else{"SETOR — $porSetor"}
        } else {
            "SEM CHEFIA"
        }

        if($q){
            $hay=("$mat $nome $setor $origem").ToUpperInvariant()
            if($hay -notlike "*$q*"){ continue }
        }

        $i=$script:gridServidoresChefia.Rows.Add()
        $row=$script:gridServidoresChefia.Rows[$i]
        $row.Cells["vinc"].Value=($direta -eq $grupo -and $grupo)
        $row.Cells["mat"].Value=$mat
        $row.Cells["nome"].Value=$nome
        $row.Cells["setor"].Value=$setor
        $row.Cells["origem"].Value=$origem
        if($origem -eq "HERDADO DO SETOR"){
            $row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(242,246,251)
        } elseif($direta -and $direta -ne $grupo){
            $row.DefaultCellStyle.ForeColor=[Drawing.Color]::DimGray
        }
    }
}

function Load-SetoresChefiaSelecionada {
    if($null -eq $script:chkSetoresChefia){ return }

    $grupo=""
    if($null -ne $script:lstChefias -and $null -ne $script:lstChefias.SelectedItem){
        $grupo=[string]$script:lstChefias.SelectedItem
    }

    $script:CarregandoChefiasUI=$true
    try {
        $script:chkSetoresChefia.Items.Clear()
        foreach($s in @($script:Config.setores | Sort-Object -Unique)){
            $idx=$script:chkSetoresChefia.Items.Add($s)
            if($grupo -and (Get-GrupoChefiaSetor $s) -eq $grupo){
                $script:chkSetoresChefia.SetItemChecked($idx,$true)
            }
        }
    } finally {
        $script:CarregandoChefiasUI=$false
    }

    Refresh-ServidoresChefiaUI

    if($null -ne $script:lblChefiaSelecionadaInfo){
        if($grupo){
            $qtdSet=@($script:Config.grupo_chefia_setores | Where-Object { ([string]$_.grupo).Trim() -eq $grupo }).Count
            $qtdInd=@($script:Config.grupo_chefia_servidores | Where-Object { ([string]$_.grupo).Trim() -eq $grupo }).Count
            $efetivos=New-Object 'System.Collections.Generic.HashSet[string]'
            foreach($r in $script:Records){
                if((Get-GrupoChefiaEfetivaRegistro $r) -eq $grupo){ [void]$efetivos.Add([string]$r.matricula) }
            }
            $script:lblChefiaSelecionadaInfo.Text="Editando vínculos da chefia: $grupo   |   Setores: $qtdSet   |   Individuais: $qtdInd   |   Servidores efetivos: $($efetivos.Count)"
        } else {
            $script:lblChefiaSelecionadaInfo.Text="Crie ou selecione um Grupo de Chefia para vincular setores e/ou servidores."
        }
    }
}

function Save-VinculosChefiaSelecionada {
    if($null -eq $script:lstChefias -or $null -eq $script:lstChefias.SelectedItem){
        [Windows.Forms.MessageBox]::Show("Selecione primeiro um Grupo de Chefia.","Setores e Chefias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }

    $grupo=[string]$script:lstChefias.SelectedItem
    $marcados=@()
    foreach($item in $script:chkSetoresChefia.CheckedItems){ $marcados += [string]$item }

    $transferencias=@()
    foreach($s in $marcados){
        $atual=Get-GrupoChefiaSetor $s
        if($atual -and $atual -ne $grupo){
            $transferencias += "${s}: $atual → $grupo"
        }
    }
    if($transferencias.Count -gt 0){
        $texto="Os setores abaixo já pertencem a outra chefia e serão transferidos:`n`n"+($transferencias -join "`n")+"`n`nContinuar?"
        $resp=[Windows.Forms.MessageBox]::Show($texto,"Confirmar transferência",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
        if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
    }

    foreach($s in @($script:Config.setores)){
        $atual=Get-GrupoChefiaSetor $s
        if($marcados -contains [string]$s){
            Set-GrupoChefiaSetor $s $grupo
        } elseif($atual -eq $grupo){
            Set-GrupoChefiaSetor $s ""
        }
    }

    Save-Database
    Refresh-ChefiasCadastroUI
    Refresh-PlanejChefiasFiltro
    Refresh-PlanejamentoSetor
    Refresh-ConfigInfo

    [Windows.Forms.MessageBox]::Show(
        "Vínculos salvos.`n`nGrupo de Chefia: $grupo`nSetores vinculados: $($marcados.Count)",
        "Setores e Chefias",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Save-VinculosServidoresChefiaSelecionada {
    if($null -eq $script:lstChefias -or $null -eq $script:lstChefias.SelectedItem){
        [Windows.Forms.MessageBox]::Show("Selecione primeiro um Grupo de Chefia.","Servidores da Chefia",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    if($null -eq $script:gridServidoresChefia){ return }
    try { $script:gridServidoresChefia.EndEdit() } catch {}

    $grupo=[string]$script:lstChefias.SelectedItem
    $transferencias=@()
    foreach($row in $script:gridServidoresChefia.Rows){
        if($row.IsNewRow){ continue }
        $mat=([string]$row.Cells["mat"].Value).Trim()
        if(-not $mat){ continue }
        $marcado=$false
        try { $marcado=[bool]$row.Cells["vinc"].Value } catch { $marcado=$false }
        if($marcado){
            $atual=Get-GrupoChefiaServidor $mat
            if($atual -and $atual -ne $grupo){
                $nome=[string]$row.Cells["nome"].Value
                $transferencias += "$nome [$mat]: $atual → $grupo"
            }
        }
    }

    if($transferencias.Count -gt 0){
        $msg="Os servidores abaixo já têm vínculo individual com outra chefia e serão transferidos:`n`n"+($transferencias -join "`n")+"`n`nContinuar?"
        $resp=[Windows.Forms.MessageBox]::Show($msg,"Confirmar transferência individual",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
        if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
    }

    $alterados=0
    foreach($row in $script:gridServidoresChefia.Rows){
        if($row.IsNewRow){ continue }
        $mat=([string]$row.Cells["mat"].Value).Trim()
        if(-not $mat){ continue }
        $marcado=$false
        try { $marcado=[bool]$row.Cells["vinc"].Value } catch { $marcado=$false }
        $atual=Get-GrupoChefiaServidor $mat

        if($marcado){
            if($atual -ne $grupo){
                Set-GrupoChefiaServidor $mat $grupo
                $alterados++
            }
        } elseif($atual -eq $grupo){
            Set-GrupoChefiaServidor $mat ""
            $alterados++
        }
    }

    if($alterados -gt 0){
        Save-Database
        $script:PlanejChefiaOverlapCache=@{}
        Refresh-ChefiasCadastroUI
        Refresh-PlanejChefiasFiltro
        Refresh-PlanejamentoSetor
        Refresh-Grid
        Refresh-ConfigInfo
    } else {
        Refresh-ServidoresChefiaUI
    }

    [Windows.Forms.MessageBox]::Show(
        "Vínculos individuais processados.`n`nGrupo de Chefia: $grupo`nAlterações: $alterados`n`nRegra: vínculo individual tem prioridade sobre a chefia herdada do setor. Um servidor nunca é contado duas vezes.",
        "Servidores da Chefia",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Refresh-CadastrosLists {
    if($null -ne $script:lstSetores){
        $script:lstSetores.Items.Clear()
        foreach($x in @($script:Config.setores | Sort-Object -Unique)){ [void]$script:lstSetores.Items.Add($x) }
    }
    if($null -ne $script:lstPeriodos){
        $script:lstPeriodos.Items.Clear()
        foreach($x in @($script:Config.periodos | Sort-Object -Unique)){ [void]$script:lstPeriodos.Items.Add($x) }
    }
    try {
        Refresh-ChefiasCadastroUI
        Refresh-PlanejChefiasFiltro
    } catch { Write-DiagLog "Falha ao atualizar listas de Chefias/Cadastros." "WARN" $_ }
}

function Refresh-SetorPeriodos {
    $knownSetores=@()
    $knownSetores += @($script:Config.setores)
    $knownSetores += @($script:Records | ForEach-Object {$_.setor} | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $knownSetores=@($knownSetores | Sort-Object -Unique)
    $script:cmbSetor.Items.Clear()
    foreach($s in $knownSetores){ [void]$script:cmbSetor.Items.Add($s) }
    $script:cmbDashSetor.Items.Clear(); [void]$script:cmbDashSetor.Items.Add("TODOS")
    foreach($s in $knownSetores){ [void]$script:cmbDashSetor.Items.Add($s) }
    if($script:cmbDashSetor.Items.Count -gt 0){ $script:cmbDashSetor.SelectedIndex=0 }

    $periodos=@()
    $periodos += @($script:Config.periodos)
    $periodos += @($script:Records | ForEach-Object {$_.periodo} | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $periodos=@($periodos | Sort-Object -Unique)
    $script:Config.periodos=@($periodos)
    $script:cmbPeriodo.Items.Clear()
    foreach($p in $periodos){ [void]$script:cmbPeriodo.Items.Add($p) }
    $script:cmbFiltroPeriodo.Items.Clear(); [void]$script:cmbFiltroPeriodo.Items.Add("TODOS")
    $script:cmbDashPeriodo.Items.Clear(); [void]$script:cmbDashPeriodo.Items.Add("TODOS")
    foreach($p in $periodos){ [void]$script:cmbFiltroPeriodo.Items.Add($p); [void]$script:cmbDashPeriodo.Items.Add($p) }

    if($null -ne $script:cmbPlanejPeriodo){
        $script:cmbPlanejPeriodo.Items.Clear()
        [void]$script:cmbPlanejPeriodo.Items.Add("TODOS")
        foreach($p in $periodos){ [void]$script:cmbPlanejPeriodo.Items.Add($p) }
        $script:cmbPlanejPeriodo.SelectedIndex=0
    }

    $script:cmbFiltroPeriodo.SelectedIndex=0; $script:cmbDashPeriodo.SelectedIndex=0
}

function Get-NextId {
    if($script:Records.Count -eq 0){ return 1 }
    return ([int](($script:Records | Measure-Object -Property id -Maximum).Maximum) + 1)
}

function Set-DatePicker($picker,[string]$store){
    $d=Parse-Date $store
    if($null -eq $d){ $picker.Checked=$false; $picker.CustomFormat=" " } else { $picker.Value=$d; $picker.Checked=$true; $picker.CustomFormat="dd/MM/yyyy" }
}
function Get-DatePickerStore($picker){
    if(-not $picker.Checked){ return "" }
    return $picker.Value.ToString("yyyy-MM-dd")
}

function Get-OptionUIBaseType([string]$ui){
    if($ui -eq 'FR 20 DIAS'){return '20 DIAS'}
    if($ui -eq '20 DIAS - REVISAR'){return '20 DIAS'}
    if($ui -like '30 DIAS + FR*'){return '30 DIAS'}
    if($ui -like '15+15 DIAS + FR*'){return '15+15 DIAS'}
    return $ui
}
function Configure-OptionControls($o){
    $ui=[string]$o.Tipo.SelectedItem
    $base=Get-OptionUIBaseType $ui
    $split=($base -eq '15+15 DIAS')
    $o.I2.Enabled=$split; $o.F2.Enabled=$split
    # V118: NUNCA desmarcar datas existentes automaticamente ao trocar o tipo.
    # A validacao bloqueia datas incompativeis no momento de salvar.
    $comb=($ui -like '* + FR 20 DIAS')
    if($null -ne $o.FRI){$o.FRI.Visible=$comb;$o.FRF.Visible=$comb;$o.FRL1.Visible=$comb;$o.FRL2.Visible=$comb}
    if($null -ne $o.FRSummary){$o.FRSummary.Visible=$false}
}
function Auto-End($o,[int]$block){
    $tipo=Get-OptionUIBaseType ([string]$o.Tipo.SelectedItem)
    if($block -eq 1){
        if(-not $o.I1.Checked){ return }
        if($tipo -eq '30 DIAS'){ $o.F1.Value=$o.I1.Value.AddDays(29); $o.F1.Checked=$true }
        elseif($tipo -eq '20 DIAS'){ $o.F1.Value=$o.I1.Value.AddDays(19); $o.F1.Checked=$true }
        elseif($tipo -eq '15+15 DIAS'){ $o.F1.Value=$o.I1.Value.AddDays(14); $o.F1.Checked=$true }
    } else {
        if($tipo -eq '15+15 DIAS' -and $o.I2.Checked){ $o.F2.Value=$o.I2.Value.AddDays(14); $o.F2.Checked=$true }
    }
}
function Read-OptionFromControls($o){
    $ui=[string]$o.Tipo.SelectedItem
    $comb=($ui -like '* + FR 20 DIAS')
    $frI='';$frF=''
    if($comb){$frI=Get-DatePickerStore $o.FRI;$frF=Get-DatePickerStore $o.FRF}
    # FR escolhida explicitamente na interface usa os mesmos campos da FR combinada.
    # Nao converte automaticamente registros legados tipo=20 DIAS.
    if($ui -eq 'FR 20 DIAS'){
        $fr=New-EmptyOptionObject
        $fr.tipo='FR 20 DIAS'
        $fr.fr_inicio=Get-DatePickerStore $o.I1
        $fr.fr_fim=Get-DatePickerStore $o.F1
        $fr.inicio2=Get-DatePickerStore $o.I2
        $fr.fim2=Get-DatePickerStore $o.F2
        return $fr
    }
    return [pscustomobject]@{
        tipo=(Get-OptionUIBaseType $ui)
        inicio1=Get-DatePickerStore $o.I1
        fim1=Get-DatePickerStore $o.F1
        inicio2=Get-DatePickerStore $o.I2
        fim2=Get-DatePickerStore $o.F2
        fr_inicio=$frI
        fr_fim=$frF
    }
}
function Update-OptionFRVisual($o){
    if($null -eq $o){return}
    $temFR=($o.FRInicio -and $o.FRFim)
    if($null -ne $o.FRSummary){
        $o.FRSummary.Text=if($temFR){'FR 20 dias: '+(Date-ToBR ([string]$o.FRInicio))+' a '+(Date-ToBR ([string]$o.FRFim))}else{'FR 20 dias: nao cadastrada'}
    }
    if($null -ne $o.FRTab){
        $titulo=([string]$o.FRTab.Text) -replace ' \+ FR$', ''
        $o.FRTab.Text=if($temFR){$titulo+' + FR'}else{$titulo}
    }
}
function Set-OptionControls($o,$op){
    $o.Loading=$true
    try {
        $o.FRInicio=if($null -eq $op){''}else{[string]$op.fr_inicio}
        $o.FRFim=if($null -eq $op){''}else{[string]$op.fr_fim}
        $base=if($null -eq $op){''}else{[string]$op.tipo}
        $ui=$base
        if($base -eq '20 DIAS'){$ui='20 DIAS - REVISAR'}
        elseif(($base -eq '30 DIAS' -or $base -eq '15+15 DIAS') -and ($o.FRInicio -or $o.FRFim)){$ui=$base+' + FR 20 DIAS'}
        $idx=$o.Tipo.Items.IndexOf($ui);if($idx -lt 0){$idx=0}
        $o.Tipo.SelectedIndex=$idx
        $o.LastType=[string]$o.Tipo.SelectedItem
        Set-DatePicker $o.I1 $(if($null -eq $op){''}else{[string]$op.inicio1})
        Set-DatePicker $o.F1 $(if($null -eq $op){''}else{[string]$op.fim1})
        Set-DatePicker $o.I2 $(if($null -eq $op){''}else{[string]$op.inicio2})
        Set-DatePicker $o.F2 $(if($null -eq $op){''}else{[string]$op.fim2})
        Set-DatePicker $o.FRI $o.FRInicio
        Set-DatePicker $o.FRF $o.FRFim
        if($base -eq 'FR 20 DIAS'){
            Set-DatePicker $o.I1 ([string]$op.fr_inicio)
            Set-DatePicker $o.F1 ([string]$op.fr_fim)
        }
        Configure-OptionControls $o
        Update-OptionFRVisual $o
        Update-OptionDayInfo $o
    } finally {$o.Loading=$false}
}
function Validate-Option($op,[string]$label,[string]$aquisitivoFim=""){
    $frI=[string]$op.fr_inicio; $frF=[string]$op.fr_fim
    if([string]$op.tipo -ne '15+15 DIAS' -and ([string]$op.inicio2 -or [string]$op.fim2)){
        return "${label}: existem datas da segunda quinzena. Volte para 15+15 ou limpe as datas conscientemente antes de salvar."
    }
    if(($frI -or $frF) -and [string]$op.tipo -eq '20 DIAS'){
        return "${label}: FR duplicada. Selecione FR 20 DIAS isolada ou uma modalidade combinada de férias comuns + FR."
    }
    if($frI -or $frF){
        $sfr=Parse-Date $frI; $efr=Parse-Date $frF
        if($null -eq $sfr -or $null -eq $efr -or ($efr-$sfr).Days -ne 19){ return "${label}: FR deve conter exatamente 20 dias com início e fim." }
        $aqFr=Parse-Date $aquisitivoFim
        if($null -ne $aqFr -and $sfr -le $aqFr){return "${label}: FR começa antes do fim do período aquisitivo."}
        $pc1=Parse-Date ([string]$op.inicio1);$pc2=Parse-Date ([string]$op.fim1)
        $pc3=Parse-Date ([string]$op.inicio2);$pc4=Parse-Date ([string]$op.fim2)
        if(($null -ne $pc1 -and $null -ne $pc2 -and (Test-Overlap $sfr $efr $pc1 $pc2)) -or
           ($null -ne $pc3 -and $null -ne $pc4 -and (Test-Overlap $sfr $efr $pc3 $pc4))){
            return "${label}: FR e férias comuns do mesmo servidor não podem se sobrepor."
        }
    }
    $temDatas=(-not [string]::IsNullOrWhiteSpace([string]$op.inicio1) -or
              -not [string]::IsNullOrWhiteSpace([string]$op.fim1) -or
              -not [string]::IsNullOrWhiteSpace([string]$op.inicio2) -or
              -not [string]::IsNullOrWhiteSpace([string]$op.fim2))
    if([string]::IsNullOrWhiteSpace([string]$op.tipo)){
        if($temDatas){ return "${label}: existem datas preenchidas, mas o Tipo não foi informado." }
        if($frI -and $frF){return "${label}: selecione a modalidade combinada de férias comuns + FR ou FR 20 DIAS isolada."}
        return $null
    }
    if([string]$op.tipo -eq 'FR 20 DIAS'){
        if($temDatas){ return "${label}: FR isolada deve usar somente as datas FR." }
        if(-not $frI -or -not $frF){ return "${label}: informe inicio e termino da FR de 20 dias." }
        return $null
    }
    if([string]$op.tipo -notin @('30 DIAS','20 DIAS','15+15 DIAS')){
        return "${label}: modalidade de ferias desconhecida."
    }
    $s1=Parse-Date $op.inicio1; $e1=Parse-Date $op.fim1
    if($null -eq $s1 -or $null -eq $e1){ return "${label}: informe início e término." }
    if($e1 -lt $s1){ return "${label}: término anterior ao início." }
    $aqFim=Parse-Date $aquisitivoFim
    if($null -ne $aqFim -and $s1 -le $aqFim){
        $primeiraValida=$aqFim.AddDays(1).ToString("dd/MM/yyyy")
        return "${label}: início inválido. O período aquisitivo termina em $($aqFim.ToString('dd/MM/yyyy')); as férias devem iniciar SOMENTE depois do vencimento. Primeira data válida: $primeiraValida."
    }
    $horizonteInicio=[datetime]::new(2027,1,1)
    $horizonteFim=[datetime]::new(2028,12,31)
    if($e1 -lt $horizonteInicio -or $s1 -gt $horizonteFim){
        if($null -eq $script:AvisosHorizonteRegistrados){ $script:AvisosHorizonteRegistrados=@{} }
        $warnKey="P1|$($s1.ToString('yyyy-MM-dd'))|$($e1.ToString('yyyy-MM-dd'))"
        if(-not $script:AvisosHorizonteRegistrados.ContainsKey($warnKey)){
            $script:AvisosHorizonteRegistrados[$warnKey]=$true
            Write-DiagLog ("Período fora do horizonte principal 2027/2028 ($($s1.ToString('dd/MM/yyyy')) a $($e1.ToString('dd/MM/yyyy'))). Permitido por compatibilidade; aviso registrado uma única vez nesta sessão.") "WARN"
        }
    }
    $expected=0
    if($op.tipo -eq "30 DIAS"){ $expected=30 }
    elseif($op.tipo -eq "20 DIAS"){ $expected=20 }
    elseif($op.tipo -eq "15+15 DIAS"){ $expected=15 }
    if($expected -gt 0 -and (($e1-$s1).Days+1) -ne $expected){ return "${label}: o primeiro período deve ter $expected dias." }
    if($op.tipo -eq "15+15 DIAS"){
        $s2=Parse-Date $op.inicio2; $e2=Parse-Date $op.fim2
        if($null -eq $s2 -or $null -eq $e2){ return "${label}: informe também o 2º período de 15 dias." }
        if($e2 -lt $s2){ return "${label}: 2º término anterior ao início." }
        if($null -ne $aqFim -and $s2 -le $aqFim){
            $primeiraValida=$aqFim.AddDays(1).ToString("dd/MM/yyyy")
            return "${label}: 2º início inválido. O período aquisitivo termina em $($aqFim.ToString('dd/MM/yyyy')); qualquer parcela de férias deve iniciar SOMENTE depois do vencimento. Primeira data válida: $primeiraValida."
        }
        if($e2 -lt $horizonteInicio -or $s2 -gt $horizonteFim){
            if($null -eq $script:AvisosHorizonteRegistrados){ $script:AvisosHorizonteRegistrados=@{} }
            $warnKey="P2|$($s2.ToString('yyyy-MM-dd'))|$($e2.ToString('yyyy-MM-dd'))"
            if(-not $script:AvisosHorizonteRegistrados.ContainsKey($warnKey)){
                $script:AvisosHorizonteRegistrados[$warnKey]=$true
                Write-DiagLog ("2º período fora do horizonte principal 2027/2028 ($($s2.ToString('dd/MM/yyyy')) a $($e2.ToString('dd/MM/yyyy'))). Permitido por compatibilidade; aviso registrado uma única vez nesta sessão.") "WARN"
            }
        }
        if((($e2-$s2).Days+1) -ne 15){ return "${label}: o segundo período deve ter 15 dias." }
        if($s2 -le $e1){ return "${label}: o 2º período de 15 dias deve começar depois do término do 1º período." }
    }
    return $null
}

function Get-OptionBlocks($rec,[int]$n){
    $op=$rec.("opcao$n")
    $out=@()
    if($null -eq $op -or [string]::IsNullOrWhiteSpace([string]$op.tipo)){ return @() }
    $s1=Parse-Date ([string]$op.inicio1); $e1=Parse-Date ([string]$op.fim1)
    if($null -ne $s1 -and $null -ne $e1){ $out += [pscustomobject]@{tipo=([string]$op.tipo -replace " \+ FR 20 DIAS$", ""); inicio=$s1; fim=$e1; bloco=1} }
    if(([string]$op.tipo) -match "^15\+15 DIAS"){
        $s2=Parse-Date ([string]$op.inicio2); $e2=Parse-Date ([string]$op.fim2)
        if($null -ne $s2 -and $null -ne $e2){ $out += [pscustomobject]@{tipo=([string]$op.tipo -replace " \+ FR 20 DIAS$", ""); inicio=$s2; fim=$e2; bloco=2} }
    }
    $fi=Parse-Date ([string]$op.fr_inicio);$ff=Parse-Date ([string]$op.fr_fim)
    if($null -ne $fi -and $null -ne $ff -and ($ff-$fi).Days -eq 19){
        $out += [pscustomobject]@{tipo='20 DIAS';inicio=$fi;fim=$ff;bloco=3}
    }
    return @($out)
}
function Test-Overlap($s1,$e1,$s2,$e2){ return ($s1 -le $e2 -and $e1 -ge $s2) }


function Get-NodeText($node){
    if($null -eq $node){ return "" }
    if($node -is [string]){ return [string]$node }
    try {
        $p=$node.PSObject.Properties["InnerText"]
        if($null -ne $p){ return [string]$node.InnerText }
    } catch {}
    return [string]$node
}

function Convert-ExcelSerialToDateString($v,[bool]$Date1904=$false){
    if($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)){ return "" }
    $n=0.0
    if([double]::TryParse([string]$v,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$n)){
        try { return ([datetime]::FromOADate($n+$(if($Date1904){1462}else{0}))).ToString("yyyy-MM-dd") } catch { return "" }
    }
    return ""
}

function Get-ExcelDate1904($zip){
    $entry=$zip.Entries|Where-Object {$_.FullName -eq 'xl/workbook.xml'}|Select-Object -First 1
    if(-not $entry){return $false}
    $workbook=Read-ZipXmlSafe $entry
    return (([string]$workbook.workbook.workbookPr.date1904).ToLowerInvariant() -in @('1','true'))
}

function Read-XlsmBase([string]$path){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if(-not (Test-Path -LiteralPath $path)){ throw "Planilha não encontrada: $path" }

    # Cópia temporária com FileShare ReadWrite: permite leitura mesmo se o Excel estiver aberto.
    $tmp=New-ReadableTempCopy $path
    $zip=$null
    try {
        $zip=[System.IO.Compression.ZipFile]::OpenRead($tmp)
        $date1904=Get-ExcelDate1904 $zip
        $shared=@()
        $entry=$zip.Entries | Where-Object {$_.FullName -eq "xl/sharedStrings.xml"} | Select-Object -First 1
        if($entry){
            $x=Read-ZipXmlSafe $entry
            foreach($si in $x.sst.si){
                $txt=""
                if($null -ne $si){ $txt=(Get-NodeText $si) }
                $shared += $txt
            }
        }

        $sheet=$zip.Entries | Where-Object {$_.FullName -eq "xl/worksheets/sheet1.xml"} | Select-Object -First 1
        if(-not $sheet){ throw "A aba principal (sheet1.xml) não foi localizada." }
        $sx=Read-ZipXmlSafe $sheet

        function ColIndex([string]$letters){
            $n=0
            foreach($ch in $letters.ToCharArray()){ $n=$n*26 + ([int][char]$ch - 64) }
            return $n-1
        }

        # A nova planilha usa até AE (31 colunas). Mantemos folga para futuras colunas.
        $maxCols=40
        $rows=@{}
        foreach($row in $sx.worksheet.sheetData.row){
            $rnum=[int]$row.r
            $arr=New-Object object[] $maxCols
            foreach($c in $row.c){
                $ref=[string]$c.r
                $m=[regex]::Match($ref,'([A-Z]+)(\d+)')
                if(-not $m.Success){ continue }
                $ci=ColIndex $m.Groups[1].Value
                if($ci -lt 0 -or $ci -ge $maxCols){ continue }
                $val=""
                if([string]$c.t -eq "s"){
                    $idx=0; try { $idx=if($null -ne $c.v){[int](Get-NodeText $c.v)}else{-1} } catch { $idx=-1 }
                    if($idx -ge 0 -and $idx -lt $shared.Count){ $val=$shared[$idx] }
                } elseif([string]$c.t -eq "inlineStr"){
                    $val=if($null -ne $c.is){(Get-NodeText $c.is)}else{""}
                } else {
                    $val=if($null -ne $c.v){(Get-NodeText $c.v)}else{""}
                }
                $arr[$ci]=$val
            }
            $rows[$rnum]=$arr
        }

        # Detecta o layout automaticamente pelos cabeçalhos das primeiras linhas.
        # NOVO: A Matrícula | B Nome | C Setor | D Grupo de Chefia | E Grupo de Análise |
        #       F/G Período Aquisitivo | H:AE 1ª/2ª/3ª opções.
        # ANTIGO: A Matrícula | B Nome | C/D Período Aquisitivo | E:AB opções.
        $headerText=""
        foreach($hr in 1..5){
            if($rows.ContainsKey($hr)){
                foreach($hv in @($rows[$hr])){
                    if(-not [string]::IsNullOrWhiteSpace([string]$hv)){ $headerText += " "+([string]$hv).Trim() }
                }
            }
        }
        $headerKey=Convert-ToUpperSemAcento $headerText
        $layoutNovo=($headerKey -match '\bSETOR\b' -and $headerKey -match 'GRUPO\s+DE\s+CHEFIA' -and $headerKey -match 'GRUPO\s+DE\s+ANALISE')
        Write-DiagLog ("Planilha base: layout detectado = "+$(if($layoutNovo){"NOVO (Setor/Chefia/Grupo de Análise)"}else{"LEGADO"}))

        function OptFrom($vals,[int]$offset){
            $o=[ordered]@{tipo="";inicio1="";fim1="";inicio2="";fim2="";fr_inicio="";fr_fim=""}
            if($vals[$offset] -or $vals[$offset+1]){
                $o.tipo="30 DIAS"
                $o.inicio1=Convert-ExcelValueToDateString $vals[$offset] -Date1904 $date1904
                $o.fim1=Convert-ExcelValueToDateString $vals[$offset+1] -Date1904 $date1904
            } elseif($vals[$offset+2] -or $vals[$offset+3] -or $vals[$offset+4] -or $vals[$offset+5]){
                $o.tipo="15+15 DIAS"
                $o.inicio1=Convert-ExcelValueToDateString $vals[$offset+2] -Date1904 $date1904
                $o.fim1=Convert-ExcelValueToDateString $vals[$offset+3] -Date1904 $date1904
                $o.inicio2=Convert-ExcelValueToDateString $vals[$offset+4] -Date1904 $date1904
                $o.fim2=Convert-ExcelValueToDateString $vals[$offset+5] -Date1904 $date1904
            }
            if($vals[$offset+6] -or $vals[$offset+7]){
                if([string]::IsNullOrWhiteSpace([string]$o.tipo)){
                    # Compatibilidade com planilhas que possuem somente 20 dias.
                    $o.tipo='20 DIAS'
                    $o.inicio1=Convert-ExcelValueToDateString $vals[$offset+6] -Date1904 $date1904
                    $o.fim1=Convert-ExcelValueToDateString $vals[$offset+7] -Date1904 $date1904
                } else {
                    # FR coexiste com as férias comuns; não sobrescreve 30 ou 15+15.
                    $o.fr_inicio=Convert-ExcelValueToDateString $vals[$offset+6] -Date1904 $date1904
                    $o.fr_fim=Convert-ExcelValueToDateString $vals[$offset+7] -Date1904 $date1904
                }
            }
            return [pscustomobject]$o
        }

        $out=@()
        foreach($rnum in ($rows.Keys | Sort-Object)){
            if([int]$rnum -lt 6){ continue }
            $v=$rows[$rnum]
            if(-not $v[0] -and -not $v[1]){ continue }

            if($layoutNovo){
                $out += [pscustomobject]@{
                    matricula=[string]$v[0]
                    nome=([string]$v[1]).Trim()
                    setor=([string]$v[2]).Trim()
                    grupo_chefia=([string]$v[3]).Trim()
                    grupo_analise=([string]$v[4]).Trim()
                    aquisitivo_inicio=Convert-ExcelValueToDateString $v[5] -Date1904 $date1904
                    aquisitivo_fim=Convert-ExcelValueToDateString $v[6] -Date1904 $date1904
                    opcao1=OptFrom $v 7
                    opcao2=OptFrom $v 15
                    opcao3=OptFrom $v 23
                    origem_linha_excel=[int]$rnum
                    layout_planilha="NOVO"
                }
            } else {
                $out += [pscustomobject]@{
                    matricula=[string]$v[0]
                    nome=([string]$v[1]).Trim()
                    setor=""
                    grupo_chefia=""
                    grupo_analise=""
                    aquisitivo_inicio=Convert-ExcelValueToDateString $v[2] -Date1904 $date1904
                    aquisitivo_fim=Convert-ExcelValueToDateString $v[3] -Date1904 $date1904
                    opcao1=OptFrom $v 4
                    opcao2=OptFrom $v 12
                    opcao3=OptFrom $v 20
                    origem_linha_excel=[int]$rnum
                    layout_planilha="LEGADO"
                }
            }
        }
        return @($out)
    } finally {
        if($null -ne $zip){ $zip.Dispose() }
        if($tmp -and (Test-Path -LiteralPath $tmp)){ Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
}

# ============================================================
# IMPORTAÇÕES SEGURAS — RELATÓRIOS COM CÉLULA AMARELA
# ============================================================

function New-ReadableTempCopy([string]$path){
    if(-not (Test-Path -LiteralPath $path)){ throw "Arquivo não encontrado: $path" }
    $ext=[IO.Path]::GetExtension($path)
    $tmp=Join-Path ([IO.Path]::GetTempPath()) ("FeriasDCE_"+[guid]::NewGuid().ToString("N")+$ext)
    $src=$null; $dst=$null
    try {
        $src=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        $dst=[IO.File]::Open($tmp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $src.CopyTo($dst)
    } finally {
        if($null -ne $dst){ $dst.Dispose() }
        if($null -ne $src){ $src.Dispose() }
    }
    return $tmp
}

function Read-ZipXmlSafe($entry){
    if($null -eq $entry){ return $null }
    $stream=$null; $reader=$null
    try {
        $settings=New-Object System.Xml.XmlReaderSettings
        $settings.DtdProcessing=[System.Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver=$null
        $stream=$entry.Open()
        $reader=[System.Xml.XmlReader]::Create($stream,$settings)
        $doc=New-Object System.Xml.XmlDocument
        $doc.XmlResolver=$null
        $doc.Load($reader)
        return $doc
    } finally {
        if($null -ne $reader){ $reader.Dispose() }
        if($null -ne $stream){ $stream.Dispose() }
    }
}

function Convert-ExcelValueToDateString($v,[bool]$Date1904=$false){
    if($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)){ return "" }
    $serial=Convert-ExcelSerialToDateString $v -Date1904 $Date1904
    if($serial){ return $serial }
    $s=([string]$v).Trim()
    $d=[datetime]::MinValue
    foreach($fmt in @("dd/MM/yyyy","d/M/yyyy","yyyy-MM-dd")){
        if([datetime]::TryParseExact($s,$fmt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)){
            return $d.ToString("yyyy-MM-dd")
        }
    }
    return ""
}

function Parse-PeriodoTextoRelatorio([string]$texto){
    # Parser deliberadamente independente da cultura do Windows/PowerShell 5.1.
    # A planilha usa textos como "11/01/2027 a 30/01/2027".
    $s=([string]$texto).Trim()
    if(-not $s){ return $null }
    $m=[regex]::Match($s,'(?i)(\d{1,2})/(\d{1,2})/(\d{4})\s*(?:a|até|-)\s*(\d{1,2})/(\d{1,2})/(\d{4})')
    if(-not $m.Success){ return $null }

    try {
        $d1=[datetime]::new([int]$m.Groups[3].Value,[int]$m.Groups[2].Value,[int]$m.Groups[1].Value)
        $d2=[datetime]::new([int]$m.Groups[6].Value,[int]$m.Groups[5].Value,[int]$m.Groups[4].Value)
    } catch {
        return $null
    }

    if($d2.Date -lt $d1.Date){ return $null }
    $dias=[int](($d2.Date-$d1.Date).TotalDays+1)
    $tipo=if($dias -eq 30){"30 DIAS"}elseif($dias -eq 20){"20 DIAS"}elseif($dias -eq 15){"15 DIAS"}else{"$dias DIAS"}
    return [pscustomobject]@{
        inicio=$d1.Date.ToString("yyyy-MM-dd")
        fim=$d2.Date.ToString("yyyy-MM-dd")
        dias=$dias
        tipo=$tipo
    }
}

function Read-RelatorioFeriasAmarelo([string]$path){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $tmp=New-ReadableTempCopy $path
    $zip=$null
    try {
        $zip=[System.IO.Compression.ZipFile]::OpenRead($tmp)
        $date1904=Get-ExcelDate1904 $zip
        $shared=@()
        $ssEntry=$zip.Entries | Where-Object {$_.FullName -eq "xl/sharedStrings.xml"} | Select-Object -First 1
        if($ssEntry){
            $ss=Read-ZipXmlSafe $ssEntry
            foreach($si in $ss.sst.si){ $shared += (Get-NodeText $si) }
        }

        $stylesEntry=$zip.Entries | Where-Object {$_.FullName -eq "xl/styles.xml"} | Select-Object -First 1
        if(-not $stylesEntry){ throw "Arquivo styles.xml não localizado na planilha." }
        $styles=Read-ZipXmlSafe $stylesEntry
        $fills=@($styles.styleSheet.fills.fill)
        $xfs=@($styles.styleSheet.cellXfs.xf)
        $theme=$null
        $themeEntry=$zip.Entries | Where-Object {$_.FullName -eq 'xl/theme/theme1.xml'} | Select-Object -First 1
        if($themeEntry){$theme=Read-ZipXmlSafe $themeEntry}
        $yellowStyles=New-Object 'System.Collections.Generic.HashSet[int]'
        for($i=0;$i -lt $xfs.Count;$i++){
            $fillId=0
            try { $fillId=[int]$xfs[$i].fillId } catch { $fillId=0 }
            if($fillId -lt 0 -or $fillId -ge $fills.Count){ continue }
            $pf=$fills[$fillId].patternFill
            if($null -eq $pf -or [string]$pf.patternType -ne "solid"){ continue }
            $fg=$pf.fgColor
            if(Test-CorAmarelaRelatorio $fg $styles $theme){
                [void]$yellowStyles.Add($i)
            }
        }

        $sheetEntry=$zip.Entries | Where-Object {$_.FullName -eq "xl/worksheets/sheet1.xml"} | Select-Object -First 1
        if(-not $sheetEntry){ throw "A aba principal (sheet1.xml) não foi localizada." }
        $sx=Read-ZipXmlSafe $sheetEntry

        function Get-ColIndexRel([string]$letters){
            $n=0
            foreach($ch in $letters.ToUpperInvariant().ToCharArray()){ $n=$n*26 + ([int][char]$ch - 64) }
            return $n-1
        }

        $mesAtual=0; $anoAtual=0
        $saida=@()
        foreach($row in $sx.worksheet.sheetData.row){
            $arr=New-Object object[] 13
            $sty=New-Object int[] 13
            foreach($c in $row.c){
                $ref=[string]$c.r
                $m=[regex]::Match($ref,'([A-Z]+)(\d+)')
                if(-not $m.Success){ continue }
                $ci=Get-ColIndexRel $m.Groups[1].Value
                if($ci -lt 0 -or $ci -ge 13){ continue }
                $val=""
                if([string]$c.t -eq "s"){
                    $idx=0; try { $idx=if($null -ne $c.v){[int](Get-NodeText $c.v)}else{-1} } catch { $idx=-1 }
                    if($idx -ge 0 -and $idx -lt $shared.Count){ $val=$shared[$idx] }
                } elseif([string]$c.t -eq "inlineStr"){
                    $val=if($null -ne $c.is){(Get-NodeText $c.is)}else{""}
                } else {
                    $val=if($null -ne $c.v){(Get-NodeText $c.v)}else{""}
                }
                $arr[$ci]=$val
                try { $sty[$ci]=[int]$c.s } catch { $sty[$ci]=0 }
            }

            $a=([string]$arr[0]).Trim()
            $aNorm=Convert-ToUpperSemAcento $a
            $mh=[regex]::Match($aNorm,'^(JANEIRO|FEVEREIRO|MARCO|ABRIL|MAIO|JUNHO|JULHO|AGOSTO|SETEMBRO|OUTUBRO|NOVEMBRO|DEZEMBRO)/(\d{4})')
            if($mh.Success){
                $map=@{JANEIRO=1;FEVEREIRO=2;MARCO=3;ABRIL=4;MAIO=5;JUNHO=6;JULHO=7;AGOSTO=8;SETEMBRO=9;OUTUBRO=10;NOVEMBRO=11;DEZEMBRO=12}
                $mesAtual=[int]$map[$mh.Groups[1].Value]
                $anoAtual=[int]$mh.Groups[2].Value
                continue
            }
            if($aNorm -in @( "CP", "MATRICULA", "MATRÍCULA" ) -or [string]::IsNullOrWhiteSpace($a) -or [string]::IsNullOrWhiteSpace([string]$arr[2])){ continue }

            $candidatas=@()
            foreach($ci in 10..12){
                if(-not [string]::IsNullOrWhiteSpace([string]$arr[$ci]) -and $yellowStyles.Contains([int]$sty[$ci])){ $candidatas += $ci }
            }
            $erro=""; $coluna=""; $periodo=$null
            if($candidatas.Count -ne 1){
                $erro=if($candidatas.Count -eq 0){"Nenhuma célula amarela encontrada em K/L/M"}else{"Mais de uma célula amarela encontrada em K/L/M"}
            } else {
                $ci=[int]$candidatas[0]
                $coluna=@("K","L","M")[$ci-10]
                $periodo=Parse-PeriodoTextoRelatorio ([string]$arr[$ci])
                if($null -eq $periodo){ $erro="Data da célula amarela inválida: $([string]$arr[$ci])" }
            }

            $saida += [pscustomobject]@{
                linha=[int]$row.r
                matricula=([string]$arr[0]).Trim()
                cp=([string]$arr[1]).Trim()
                nome=([string]$arr[2]).Trim()
                cargo=([string]$arr[3]).Trim()
                vinculo=([string]$arr[4]).Trim()
                setor=([string]$arr[5]).Trim()
                periodo_trabalho=([string]$arr[6]).Trim()
                horario=([string]$arr[7]).Trim()
                aquisitivo_inicio=Convert-ExcelValueToDateString $arr[8] -Date1904 $date1904
                aquisitivo_fim=Convert-ExcelValueToDateString $arr[9] -Date1904 $date1904
                mes_referencia=$mesAtual
                ano_referencia=$anoAtual
                coluna_amarela=$coluna
                periodo_texto=if($null -ne $periodo){"$(Date-ToBR $periodo.inicio) a $(Date-ToBR $periodo.fim)"}else{""}
                ferias_inicio=if($null -ne $periodo){$periodo.inicio}else{""}
                ferias_fim=if($null -ne $periodo){$periodo.fim}else{""}
                ferias_dias=if($null -ne $periodo){$periodo.dias}else{0}
                ferias_tipo=if($null -ne $periodo){$periodo.tipo}else{""}
                valido=[string]::IsNullOrWhiteSpace($erro)
                erro=$erro
            }
        }
        return @($saida)
    } finally {
        if($null -ne $zip){ $zip.Dispose() }
        if($tmp -and (Test-Path -LiteralPath $tmp)){ Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
}

function New-MapaIdentidadeSistema {
    $byMat=@{}
    $byName=@{}
    foreach($r in @($script:Records)){
        $mat=([string]$r.matricula).Trim()
        if(-not $mat){ continue }
        if(-not $byMat.ContainsKey($mat)){ $byMat[$mat]=$true }

        $nomeNorm=Convert-ToUpperSemAcento ([string]$r.nome)
        if($nomeNorm){
            if(-not $byName.ContainsKey($nomeNorm)){ $byName[$nomeNorm]=@() }
            if(@($byName[$nomeNorm]) -notcontains $mat){
                $byName[$nomeNorm]=@(@($byName[$nomeNorm])+$mat)
            }
        }
    }
    return [pscustomobject]@{ByMat=$byMat;ByName=$byName}
}

function Resolve-IdentidadeRelatorio($r,$mapa){
    $mat=([string]$r.matricula).Trim()
    $nomesCadastro=@($script:Records | Where-Object {([string]$_.matricula).Trim() -eq $mat -and $mat} | ForEach-Object {([string]$_.nome).Trim()} | Where-Object {$_} | Sort-Object -Unique)
    $r | Add-Member NoteProperty nome_cadastro ($nomesCadastro -join ' / ') -Force
    $r | Add-Member NoteProperty matricula_encontrada $(if($mat -and $mapa.ByMat.ContainsKey($mat)){$mat}else{''}) -Force
    if(-not $mat){ return [pscustomobject]@{status="NÃO LOCALIZADO";matricula="";metodo="matrícula ausente"} }
    if(-not $mapa.ByMat.ContainsKey($mat)){
        return [pscustomobject]@{status="NÃO LOCALIZADO";matricula="";metodo="matrícula não cadastrada; nenhum vínculo por nome será feito"}
    }
    $nomeNorm=Convert-ToUpperSemAcento ([string]$r.nome)
    $nomes=@($script:Records | Where-Object {([string]$_.matricula).Trim() -eq $mat} | ForEach-Object {Convert-ToUpperSemAcento ([string]$_.nome)} | Where-Object {$_} | Sort-Object -Unique)
    if($nomeNorm -and $nomes.Count -gt 0 -and $nomes -notcontains $nomeNorm){
        return [pscustomobject]@{status="CONFLITO";matricula="";metodo="matrícula encontrada mas nome divergente. Planilha (linha $($r.linha)): '$([string]$r.nome)'; cadastro: '$($r.nome_cadastro)'. Confira o cadastro em Lançamentos e a linha da planilha; nenhuma troca de nome ou vínculo será feita automaticamente"}
    }
    return [pscustomobject]@{status="OK";matricula=$mat;metodo="MATRÍCULA exata"}
}

function Get-PreviewFixas2027($rows){
    $seen=@{}
    $out=@()
    $mapa=New-MapaIdentidadeSistema

    foreach($r in @($rows)){
        $status=""; $det=""; $matSistema=""
        $ident=Resolve-IdentidadeRelatorio $r $mapa
        if(-not [bool]$r.valido){
            $status="ERRO"; $det=[string]$r.erro
        } elseif((Convert-ToUpperSemAcento ([string]$r.cargo)) -ne "ENFERMEIRO"){
            $status="IGNORAR"; $det="Cargo diferente de Enfermeiro"
        } elseif([int]$r.ano_referencia -ne 2027){
            $status="IGNORAR"; $det="Registro fora de 2027"
        } else {
            $key="$([string]$r.matricula)|$([string]$r.nome)|$([string]$r.aquisitivo_inicio)|$([string]$r.aquisitivo_fim)|$([string]$r.ferias_inicio)|$([string]$r.ferias_fim)"
            if($seen.ContainsKey($key)){
                $status="DUPLICADO"; $det="Registro repetido na planilha"
            } else {
                $seen[$key]=$true
                if($ident.status -ne "OK"){
                    $status=if($ident.status -eq "CONFLITO"){"NOME DIVERGENTE"}elseif($ident.status -eq "AMBÍGUO"){"AMBÍGUO"}else{"CONFERIR"}
                    $det="Matrícula do relatório: $([string]$r.matricula). Servidor não pôde ser vinculado automaticamente: $($ident.metodo). Não será importado até haver vínculo seguro."
                } else {
                    $matSistema=[string]$ident.matricula
                    $matches=@($script:Records | Where-Object {
                        [string]$_.matricula -eq $matSistema -and
                        [string]$_.aquisitivo_inicio -eq [string]$r.aquisitivo_inicio -and
                        [string]$_.aquisitivo_fim -eq [string]$r.aquisitivo_fim
                    })

                    if($matches.Count -gt 1){
                        $status="AMBÍGUO"; $det="Mais de um período aquisitivo igual localizado para a matrícula $matSistema"
                    } elseif($matches.Count -eq 1){
                        $m=$matches[0]
                        if((Test-RegistroFixoImportado $m) -and (Test-FixaMesmoIntervalo $m ([string]$r.ferias_inicio) ([string]$r.ferias_fim))){
                            $status="JÁ IMPORTADA"; $det="Período fixo já registrado (inclusive parcelas adicionais); nenhuma duplicação será feita."
                        } elseif((Test-RegistroFixoImportado $m) -and [bool]$m.fixo_ajustado){
                            $status="AJUSTADA"
                            $det="FIXA AJUSTADA manualmente no sistema — a reimportação NÃO sobrescreverá as datas. Sistema: $(Date-ToBR ([string]$m.fixo_inicio)) a $(Date-ToBR ([string]$m.fixo_fim)) | Planilha: $(Date-ToBR ([string]$r.ferias_inicio)) a $(Date-ToBR ([string]$r.ferias_fim))."
                        } elseif((Test-RegistroFixoImportado $m) -and (Test-FixaSobreposta $m ([string]$r.ferias_inicio) ([string]$r.ferias_fim))){
                            $status="CONFERIR"; $det="Datas sobrepostas a férias fixas existentes: não é seguro acrescentar ou substituir automaticamente."
                        } elseif(Test-RegistroFixoImportado $m){
                            if(Test-FixaLimiteAutomatico $m ([string]$r.ferias_inicio) ([string]$r.ferias_fim)){
                                $status="ACRESCENTAR"; $det="Nova quinzena fixa no mesmo aquisitivo: será acrescentada sem substituir a anterior."
                            } else {
                                $status="CONFERIR"; $det="Períodos distintos incompatíveis com parcelamento comum de 30 dias. Confirmar se é correção ou férias radiológicas (30+20)."
                            }
                        } else {
                            $status="ATUALIZAR"
                            $det="Vínculo por $($ident.metodo) | Matrícula sistema: $matSistema | período aquisitivo localizado; opções atuais serão preservadas"
                            $setPlan=([string]$r.setor).Trim(); $setSis=([string]$m.setor).Trim()
                            $perPlan=([string]$r.periodo_trabalho).Trim().ToUpperInvariant(); $perSis=([string]$m.periodo).Trim().ToUpperInvariant()
                            $div=@()
                            if($setPlan -and $setSis -and $setPlan -ne $setSis){ $div += "Setor planilha='$setPlan' / sistema='$setSis'" }
                            if($perPlan -and $perSis -and $perPlan -ne $perSis){ $div += "Período planilha='$perPlan' / sistema='$perSis'" }
                            if($div.Count -gt 0){ $det += ". CONFERIR: " + ($div -join "; ") + ". O cadastro atual do sistema será preservado." }
                        }
                    } else {
                        $status="CRIAR"
                        $det="Vínculo por $($ident.metodo) | Matrícula sistema: $matSistema | o período aquisitivo antigo não existe na base atual; será criado somente como compromisso fixo, sem alterar os demais períodos do servidor."
                    }
                }
            }
        }

        $r | Add-Member -NotePropertyName matricula_sistema -NotePropertyValue $matSistema -Force
        $r | Add-Member -NotePropertyName preview_status -NotePropertyValue $status -Force
        $r | Add-Member -NotePropertyName preview_detalhe -NotePropertyValue $det -Force
        $out += $r
    }
    return @($out)
}

function Get-PreviewHistorico($rows){
    $seen=@{}; $out=@()
    $mapa=New-MapaIdentidadeSistema

    foreach($r in @($rows)){
        $ident=Resolve-IdentidadeRelatorio $r $mapa
        if(-not [bool]$r.valido){
            $r|Add-Member NoteProperty matricula_sistema '' -Force
            $r|Add-Member NoteProperty preview_status 'ERRO DE LEITURA' -Force
            $r|Add-Member NoteProperty preview_detalhe ([string]$r.erro) -Force
            $out+=$r
            continue
        }
        if(-not (Test-CargoEnfermeiroHistorico ([string]$r.cargo))){ continue }
        if([int]$r.ano_referencia -lt 1900 -or [int]$r.ano_referencia -gt 9998){ continue }
        if([int]$r.mes_referencia -lt 1 -or [int]$r.mes_referencia -gt 12){ continue }

        $matSistema=if($ident.status -eq "OK"){[string]$ident.matricula}else{""}
        $keyBase=if($matSistema){$matSistema}else{"MATRICULA:$([string]$r.matricula)|NOME:$(Convert-ToUpperSemAcento ([string]$r.nome))"}
        $key="$keyBase|$([int]$r.ano_referencia)|$([int]$r.mes_referencia)|$([string]$r.ferias_inicio)|$([string]$r.ferias_fim)|$([string]$r.aquisitivo_inicio)|$([string]$r.aquisitivo_fim)"
        if($seen.ContainsKey($key)){ continue }
        $seen[$key]=$true

        $status=if($ident.status -eq "OK"){"IMPORTAR"}elseif($ident.status -eq "CONFLITO"){"NOME DIVERGENTE"}elseif($ident.status -eq "AMBÍGUO"){"AMBÍGUO"}else{"SEM VÍNCULO"}
        $det=if($ident.status -eq "OK"){
            "Histórico confirmado pela célula amarela | vínculo por $($ident.metodo) | Matrícula sistema: $matSistema"
        } else {
            "Histórico lido, mas não vinculado ao cadastro atual: $($ident.metodo). Matrícula planilha: $([string]$r.matricula); CP planilha: $([string]$r.cp)"
        }

        $r | Add-Member -NotePropertyName matricula_sistema -NotePropertyValue $matSistema -Force
        $r | Add-Member -NotePropertyName preview_status -NotePropertyValue $status -Force
        $r | Add-Member -NotePropertyName preview_detalhe -NotePropertyValue $det -Force
        $out += $r
    }
    # Conflitos internos são exibidos integralmente na prévia, sem escolher a primeira linha.
    foreach($r in $out){
        if([string]$r.preview_status -ne 'IMPORTAR'){continue}
        $hr=[pscustomobject]@{matricula=[string]$r.matricula_sistema;inicio=[string]$r.ferias_inicio;fim=[string]$r.ferias_fim;aquisitivo_inicio=[string]$r.aquisitivo_inicio;aquisitivo_fim=[string]$r.aquisitivo_fim}
        $erro=Get-HistoricoRegistroErro $hr
        if(-not $erro){
            foreach($other in $out){
                if([string]$other.preview_status -notin @('IMPORTAR','CONFERIR')){continue}
                $ho=[pscustomobject]@{matricula=[string]$other.matricula_sistema;inicio=[string]$other.ferias_inicio;fim=[string]$other.ferias_fim;aquisitivo_inicio=[string]$other.aquisitivo_inicio;aquisitivo_fim=[string]$other.aquisitivo_fim}
                $erro=Get-HistoricoConflito $hr $ho
                if($erro){break}
            }
        }
        if($erro){$r.preview_status='CONFERIR';$r.preview_detalhe=$erro}
    }
    return @($out)
}

function Show-PreviewImportacao([string]$titulo,$rows,[string]$resumo){
    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text=$titulo
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(1180,690)
    $dlg.MinimumSize=New-Object Drawing.Size(1000,620)
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $top=New-Object Windows.Forms.Panel
    $top.Dock="Top"; $top.Height=112; $top.BackColor=[Drawing.Color]::FromArgb(238,246,255)
    $dlg.Controls.Add($top)
    $lt=New-Object Windows.Forms.Label
    $lt.Text=$titulo; $lt.Location=New-Object Drawing.Point(14,10); $lt.Size=New-Object Drawing.Size(1100,24)
    $lt.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold); $top.Controls.Add($lt)
    $lr=New-Object Windows.Forms.Label
    $lr.Text=$resumo; $lr.Location=New-Object Drawing.Point(14,39); $lr.Size=New-Object Drawing.Size(1120,64)
    $lr.ForeColor=[Drawing.Color]::FromArgb(45,65,85); $top.Controls.Add($lr)

    $bottom=New-Object Windows.Forms.Panel
    $bottom.Dock="Bottom"; $bottom.Height=62; $bottom.BackColor=[Drawing.Color]::FromArgb(247,247,247)
    $dlg.Controls.Add($bottom)
    $btnOK=New-Button "IMPORTAR VÁLIDOS" 760 13 175 36
    $btnOK.BackColor=[Drawing.Color]::FromArgb(205,235,205); $bottom.Controls.Add($btnOK)
    $btnCancel=New-Button "Cancelar" 950 13 150 36; $bottom.Controls.Add($btnCancel)
    $nota=New-Object Windows.Forms.Label
    $nota.Text="A planilha original não será alterada. Um backup da base será criado antes da importação."
    $nota.Location=New-Object Drawing.Point(14,20); $nota.Size=New-Object Drawing.Size(720,28); $bottom.Controls.Add($nota)

    $g=New-Object Windows.Forms.DataGridView
    $g.Dock="Fill"; $g.ReadOnly=$true; $g.AllowUserToAddRows=$false; $g.AllowUserToDeleteRows=$false
    $g.RowHeadersVisible=$false; $g.SelectionMode="FullRowSelect"; $g.AutoSizeColumnsMode="Fill"; $g.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(
        @("st","Status"),@("mat","Matrícula planilha"),@("cp","CP planilha"),@("mats","Matrícula sistema"),@("nome","Nome"),@("setor","Setor"),@("per","Período"),
        @("aq","Período aquisitivo"),@("ref","Mês referência"),@("ferias","Férias destacadas"),@("det","Observação")
    )){ [void]$g.Columns.Add($c[0],$c[1]) }
    [void]$g.Columns.Add('nomecad','Nome no cadastro')
    [void]$g.Columns.Add('linha','Linha da planilha')
    $g.Columns['mats'].Visible=$false
    $g.Columns['nome'].HeaderText='Nome na planilha'
    $g.Columns['mat'].HeaderText='Matrícula'
    $g.AutoSizeColumnsMode='None'
    foreach($c in $g.Columns){$c.Width=150; $c.SortMode='Automatic'}
    $g.Columns['st'].Width=165; $g.Columns['mat'].Width=110
    $g.Columns['nome'].Width=270; $g.Columns['nomecad'].Width=270
    $g.Columns['linha'].Width=95; $g.Columns['det'].Width=500
    $order=@('st','mat','nome','nomecad','linha','cp','setor','per','aq','ref','ferias','det','mats')
    for($j=0;$j -lt $order.Count;$j++){$g.Columns[$order[$j]].DisplayIndex=$j}
    $g.MultiSelect=$false; $g.ShowCellToolTips=$true
    $details=New-Object Windows.Forms.TextBox
    $details.Dock='Bottom'; $details.Height=125; $details.Multiline=$true
    $details.ReadOnly=$true; $details.ScrollBars='Vertical'; $details.BackColor=[Drawing.Color]::White
    $details.Text='Selecione um registro para ver os nomes completos, a origem e o motivo.'
    $dlg.Controls.Add($details)
    $onlyConflicts=New-Object Windows.Forms.CheckBox
    $onlyConflicts.Text='Mostrar somente nomes divergentes'; $onlyConflicts.AutoSize=$true
    $onlyConflicts.Location=New-Object Drawing.Point(14,106); $top.Controls.Add($onlyConflicts)
    $top.Height=136
    foreach($r in @($rows)){
        $i=$g.Rows.Add(); $rr=$g.Rows[$i]
        $rr.Tag=$r
        $rr.Cells['nomecad'].Value=[string]$r.nome_cadastro
        $rr.Cells['linha'].Value=[string]$r.linha
        $rr.Cells["st"].Value=[string]$r.preview_status
        $rr.Cells["mat"].Value=[string]$r.matricula
        $rr.Cells["cp"].Value=[string]$r.cp
        $rr.Cells["mats"].Value=if($null -ne $r.PSObject.Properties["matricula_sistema"]){[string]$r.matricula_sistema}else{""}
        $rr.Cells["nome"].Value=[string]$r.nome
        $rr.Cells["setor"].Value=[string]$r.setor
        $rr.Cells["per"].Value=[string]$r.periodo_trabalho
        $rr.Cells["aq"].Value="$(Date-ToBR ([string]$r.aquisitivo_inicio)) a $(Date-ToBR ([string]$r.aquisitivo_fim))"
        $rr.Cells["ref"].Value=if([int]$r.mes_referencia -gt 0){("{0:00}/{1}" -f [int]$r.mes_referencia,[int]$r.ano_referencia)}else{""}
        $rr.Cells["ferias"].Value=[string]$r.periodo_texto
        $rr.Cells["det"].Value=[string]$r.preview_detalhe
        switch([string]$r.preview_status){
            "NOME DIVERGENTE" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose }
            "ERRO DE LEITURA" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose }
            "ERRO" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose }
            "AMBÍGUO" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose }
            "CONFERIR" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,244,204) }
            "SEM VÍNCULO" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,244,204) }
            "DUPLICADO" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::Gainsboro }
            "IGNORAR" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::Gainsboro }
            "JÁ IMPORTADA" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::AliceBlue }
            "AJUSTADA" { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::LightBlue }
            default { $rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(239,249,239) }
        }
    }
    $g.add_SelectionChanged({
        if($null -eq $g.CurrentRow){$details.Text='Nenhum registro selecionado.';return}
        $selected=$g.CurrentRow.Tag
        if($null -eq $selected){return}
        $cad=if([string]$selected.nome_cadastro){[string]$selected.nome_cadastro}else{'(nenhum nome cadastrado para esta matrícula)'}
        $details.Text="Status: $($selected.preview_status) | Matrícula na planilha: $($selected.matricula) | Matrícula encontrada: $($selected.matricula_encontrada) | Linha da planilha: $($selected.linha)`r`nNome na planilha: $($selected.nome)`r`nNome no cadastro: $cad`r`nMotivo: $($selected.preview_detalhe)"
    })
    $onlyConflicts.add_CheckedChanged({
        $g.CurrentCell=$null
        foreach($gridRow in $g.Rows){$gridRow.Visible=(-not $onlyConflicts.Checked -or [string]$gridRow.Tag.preview_status -eq 'NOME DIVERGENTE')}
        $first=@($g.Rows | Where-Object {$_.Visible} | Select-Object -First 1)
        if($first.Count){$g.CurrentCell=$first[0].Cells['st']}else{$details.Text='Nenhuma divergência de nome encontrada.'}
    })
    $btnOK.Anchor='Top,Right'; $btnCancel.Anchor='Top,Right'
    $lr.Anchor='Top,Left,Right'
    $nota.Width=700
    $dlg.Controls.Add($g); $g.BringToFront()
    $btnOK.add_Click({ $dlg.DialogResult=[Windows.Forms.DialogResult]::OK; $dlg.Close() })
    $btnCancel.add_Click({ $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel; $dlg.Close() })
    return ($dlg.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK)
}

function Backup-AntesAcao([string]$prefixo){
    Ensure-Folders
    Write-DiagLog "Criando backup de segurança: $prefixo"
    if(-not (Test-Path -LiteralPath $script:DbFile)){ throw "Backup obrigatório cancelado: base operacional não encontrada." }
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $dest=Join-Path $script:BackupDir ("${prefixo}_${stamp}.json")
    try {
        Copy-Item -LiteralPath $script:DbFile -Destination $dest -Force -ErrorAction Stop
        [void](Assert-ValidJsonFile $dest "Backup obrigatório")
        Write-DiagLog "Backup criado e validado: $dest"
        return $dest
    } catch {
        Write-DiagLog "BACKUP OBRIGATÓRIO FALHOU: $prefixo" "FATAL" $_
        [System.Windows.Forms.MessageBox]::Show("A operação foi CANCELADA porque o backup obrigatório não pôde ser criado.`n`n$($_.Exception.Message)`n`nNenhum reset/importação destrutiva deve continuar.","Segurança — Férias DCE",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        throw
    }
}


function Restore-DatabaseSafely([string]$SourcePath,[string]$BackupReason,[string]$OperationName){
    if([string]::IsNullOrWhiteSpace($SourcePath)){ throw "Arquivo de restauração não informado." }
    [void](Assert-ValidJsonFile $SourcePath "Arquivo de restauração")

    $lockStream=$null
    $tmp=$null
    $restoreRollback=""
    try {
        $lockStream=Acquire-DatabaseLock 8000
        $disk=Get-DiskDbState

        if($script:LoadedDbHash -and $disk.Hash -and $disk.Hash -ne $script:LoadedDbHash){
            $resgate=Save-ConflictSnapshot ([long]$disk.Revision)
            $msg="A base foi alterada por outra instância/usuário. A restauração foi CANCELADA para não apagar trabalho recente."
            if($resgate){ $msg += "`n`nSeu estado em memória foi preservado em:`n$resgate" }
            [Windows.Forms.MessageBox]::Show($msg,"Conflito antes da restauração",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            throw "CONFLITO_RESTAURACAO_TRATADO: base alterada externamente."
        }

        $restoreRollback=Backup-AntesAcao $BackupReason

        $sourceRaw=Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 -ErrorAction Stop
        $obj=$sourceRaw | ConvertFrom-Json -ErrorAction Stop
        $newRevision=[long]$disk.Revision+1
        $obj | Add-Member -NotePropertyName versao -NotePropertyValue "1.0.70" -Force
        $obj | Add-Member -NotePropertyName revisao_dados -NotePropertyValue $newRevision -Force
        $obj | Add-Member -NotePropertyName ultima_gravacao_utc -NotePropertyValue ([DateTime]::UtcNow.ToString("o")) -Force

        $tmp="$script:DbFile.restore.$PID.$([guid]::NewGuid().ToString('N'))"
        $json=$obj | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($tmp,$json,[Text.UTF8Encoding]::new($true))
        [void](Assert-ValidJsonFile $tmp "Arquivo temporário de restauração")

        [void](Commit-DatabaseTempFile $tmp $script:DbFile $restoreRollback)
        $tmp=$null

        $final=Get-DiskDbState
        if([long]$final.Revision -ne $newRevision){ throw "A restauração terminou com revisão inesperada na base." }
        Load-Database
        Write-DiagLog "$OperationName concluída com proteção de concorrência. Revisão=$newRevision"
        return $true
    } catch {
        if(([string]$_.Exception.Message) -notlike 'CONFLITO_RESTAURACAO_TRATADO:*'){
            Write-DiagLog "Falha durante restauração segura: $OperationName" "ERROR" $_
        }
        throw
    } finally {
        if($tmp -and (Test-Path -LiteralPath $tmp)){ try{Remove-Item -LiteralPath $tmp -Force -ErrorAction Stop}catch{} }
        if($null -ne $lockStream){ try{$lockStream.Dispose()}catch{} }
    }
}

function Exportar-RejeitadosImportacao([string]$origem,$rows,[string[]]$statusImportaveis){
    # Auditoria local e independente: NÃO integra o banco de planejamento.
    $rejeitados=@($rows | Where-Object { $statusImportaveis -notcontains [string]$_.preview_status })
    if($rejeitados.Count -eq 0){ return "" }
    if(-not (Test-Path -LiteralPath $script:LogDir)){
        [void](New-Item -ItemType Directory -Path $script:LogDir -Force -ErrorAction Stop)
    }
    $dir=Join-Path $script:LogDir 'Conferencia_Importacoes'
    if(-not (Test-Path -LiteralPath $dir)){
        [void](New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop)
    }
    $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    $dest=Join-Path $dir ("NAO_IMPORTADOS_{0}_{1}.csv" -f $origem,$stamp)
    $dados=@($rejeitados | ForEach-Object {
        [pscustomobject][ordered]@{
            Status=[string]$_.preview_status
            Motivo=[string]$_.preview_detalhe
            Matricula_Planilha=[string]$_.matricula
            CP_Planilha=[string]$_.cp
            Matricula_Sistema=[string]$_.matricula_sistema
            Nome=[string]$_.nome
            Nome_Cadastro=[string]$_.nome_cadastro
            Matricula_Encontrada=[string]$_.matricula_encontrada
            Cargo=[string]$_.cargo
            Setor=[string]$_.setor
            Periodo_Aquisitivo_Inicio=[string]$_.aquisitivo_inicio
            Periodo_Aquisitivo_Fim=[string]$_.aquisitivo_fim
            Ferias_Inicio=[string]$_.ferias_inicio
            Ferias_Fim=[string]$_.ferias_fim
            Linha_Planilha=[string]$_.linha
        }
    })
    $dados | Export-Csv -LiteralPath $dest -NoTypeInformation -Delimiter ';' -Encoding UTF8 -ErrorAction Stop
    Write-DiagLog ("Relatório de importação {0}: {1} registro(s) não importado(s) em {2}" -f $origem,$rejeitados.Count,$dest)
    return $dest
}

function Save-EstadoAntesImportacaoFixa($r){
    if([bool]$r.pre_import_estado_salvo){return}
    # Importacao antiga sem snapshot nao pode ser confundida com estado manual anterior.
    if([string]$r.origem_planejamento -eq 'PROGRAMACAO_ANTERIOR_IMPORTADA' -or [string]$r.fixo_importado_em){return}
    foreach($campo in @('ferias_bloqueadas','origem_planejamento','bloqueio_motivo','opcao_aprovada','fr_opcao_aprovada','fixo_inicio','fixo_fim','fixo_tipo_relatorio','fixo_coluna_origem','fixo_importado_em','fixo_arquivo_origem','fixo_ajustado','fixo_inicio_original','fixo_fim_original','fixo_ajustado_em','fixo_motivo_ajuste','fixo_observacao_ajuste','fixo_ajustado_por')){
        $r | Add-Member -NotePropertyName ('pre_import_'+$campo) -NotePropertyValue $r.$campo -Force
    }
    $copia=@(Get-FixasAdicionais $r | ForEach-Object {$_ | Select-Object *})
    $r | Add-Member NoteProperty pre_import_fixos_adicionais $copia -Force
    $r.pre_import_estado_salvo=$true
}

function Importar-FeriasFixas2027 {
    $path=[string]$script:Config.planilha_ferias_fixas_2027
    Write-DiagLog "Solicitada importação de férias fixas 2027: $path"
    if([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)){
        [Windows.Forms.MessageBox]::Show("Selecione primeiro a planilha 'Férias já OK para 2027'.","Férias fixas 2027",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    try {
        $raw=Read-RelatorioFeriasAmarelo $path
        $rows=Get-PreviewFixas2027 $raw
        $validos=@($rows | Where-Object { [string]$_.preview_status -in @("ATUALIZAR","CRIAR","ACRESCENTAR") })
        $ja=@($rows | Where-Object { [string]$_.preview_status -eq "JÁ IMPORTADA" }).Count
        $erros=@($rows | Where-Object { [string]$_.preview_status -in @("ERRO","AMBÍGUO","CONFERIR") }).Count
        $ajustadas=@($rows | Where-Object { [string]$_.preview_status -eq "AJUSTADA" }).Count
        $resumo="Encontrados: $($rows.Count) | prontos para importar: $($validos.Count) | já importados: $ja | fixas ajustadas preservadas: $ajustadas | exigem conferência: $erros. O relatório usa MATRÍCULA como chave exata, com conferência de nome. Células amarelas K/L/M."
        $arquivoRejeitados=""
        try { $arquivoRejeitados=Exportar-RejeitadosImportacao 'FIXAS' $rows @('ATUALIZAR','CRIAR','ACRESCENTAR') }
        catch {
            Write-DiagLog "Não foi possível gravar o relatório de conferência das férias fixas." "ERROR" $_
            [Windows.Forms.MessageBox]::Show("A prévia pode ser consultada, mas o relatório de não importados NÃO foi salvo. Verifique as permissões da pasta Logs. Detalhe: $($_.Exception.Message)","Auditoria de importação",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
        }
        if($arquivoRejeitados){ $resumo += " Registro(s) não importado(s): relatório salvo em Logs\Conferencia_Importacoes." }
        if(-not (Show-PreviewImportacao "Prévia — Férias fixas de 2027" $rows $resumo)){ return }
        if($validos.Count -eq 0){
            [Windows.Forms.MessageBox]::Show("Não há novos registros válidos para importar.","Férias fixas 2027") | Out-Null
            return
        }

        [void](Backup-AntesAcao "ANTES_IMPORTAR_FIXAS_2027")
        $atualizados=0; $criados=0
        foreach($x in $validos){
            $matSistema=([string]$x.matricula_sistema).Trim()
            if(-not $matSistema){ continue }
            if(@($script:Records | Where-Object { ([string]$_.matricula).Trim() -eq $matSistema }).Count -eq 0){
                Write-DiagLog "FIXAS: matrícula sem cadastro atual na execução; ignorado Matrícula=$([string]$x.matricula)" "WARN"
                continue
            }

            $matches=@($script:Records | Where-Object {
                [string]$_.matricula -eq $matSistema -and
                [string]$_.aquisitivo_inicio -eq [string]$x.aquisitivo_inicio -and
                [string]$_.aquisitivo_fim -eq [string]$x.aquisitivo_fim
            })
            if($matches.Count -gt 1){ continue }

            $r=$null
            if($matches.Count -eq 1){
                $r=$matches[0]
                # Revalidar no momento da gravação: duas quinzenas podem constar
                # no mesmo arquivo, e a prévia foi calculada antes da primeira.
                if(Test-RegistroFixoImportado $r){
                    if(Test-FixaMesmoIntervalo $r ([string]$x.ferias_inicio) ([string]$x.ferias_fim)){ continue }
                    if([bool]$r.fixo_ajustado -or (Test-FixaSobreposta $r ([string]$x.ferias_inicio) ([string]$x.ferias_fim)) -or -not (Test-FixaLimiteAutomatico $r ([string]$x.ferias_inicio) ([string]$x.ferias_fim))){
                        Write-DiagLog "FIXAS: intervalo divergente/sobreposto preservado para conferência, matrícula=$matSistema" 'WARN'
                        continue
                    }
                    $x.preview_status='ACRESCENTAR'
                }
                if([string]$x.preview_status -eq 'ACRESCENTAR'){
                    # Segunda/terceira parcela fixa, nunca sobrescrever a primeira.
                    if(-not (Test-RegistroFixoImportado $r) -or (Test-FixaMesmoIntervalo $r ([string]$x.ferias_inicio) ([string]$x.ferias_fim)) -or (Test-FixaSobreposta $r ([string]$x.ferias_inicio) ([string]$x.ferias_fim))){ continue }
                    Save-EstadoAntesImportacaoFixa $r
                    $adicionais=@(Get-FixasAdicionais $r)
                    $adicionais += [pscustomobject]@{
                        inicio=[string]$x.ferias_inicio; fim=[string]$x.ferias_fim
                        tipo=[string]$x.ferias_tipo; coluna=[string]$x.coluna_amarela
                        arquivo=[IO.Path]::GetFileName($path); importado_em=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    }
                    $r | Add-Member -NotePropertyName fixos_adicionais -NotePropertyValue @($adicionais) -Force
                    $r.origem_planejamento='PROGRAMACAO_ANTERIOR_IMPORTADA'
                    $r.fixo_importado_em=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    $atualizados++
                    continue
                }
                Save-EstadoAntesImportacaoFixa $r
                $atualizados++
                # Reversibilidade real: se este registro já era fixo/manual antes da importação,
                # o estado anterior é preservado e poderá ser restaurado pelo reset das importações.
                # Estado anterior capturado antes de qualquer alteracao acima.
            } else {
                # O relatório usa matrícula como chave. CP é apenas informação adicional.
                # Quando o período antigo não existe, criamos o compromisso sob a
                # matrícula já resolvida pelo nome/identidade do servidor.
                $cadSistema=@($script:Records | Where-Object { [string]$_.matricula -eq $matSistema }) |
                    Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } |
                    Select-Object -First 1

                $nomeNovo=if($null -ne $cadSistema -and -not [string]::IsNullOrWhiteSpace([string]$cadSistema.nome)){[string]$cadSistema.nome}else{[string]$x.nome}
                $setor=if($null -ne $cadSistema -and -not [string]::IsNullOrWhiteSpace([string]$cadSistema.setor)){([string]$cadSistema.setor).Trim()}else{([string]$x.setor).Trim()}
                $per=if($null -ne $cadSistema -and -not [string]::IsNullOrWhiteSpace([string]$cadSistema.periodo)){([string]$cadSistema.periodo).Trim().ToUpperInvariant()}else{([string]$x.periodo_trabalho).Trim().ToUpperInvariant()}

                $r=[pscustomobject]@{
                    id=Get-NextId; matricula=$matSistema; nome=$nomeNovo; setor=$setor; periodo=$per
                    cp_relatorio=[string]$x.cp
                    aquisitivo_inicio=[string]$x.aquisitivo_inicio; aquisitivo_fim=[string]$x.aquisitivo_fim
                    opcao1=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
                    opcao2=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
                    opcao3=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
                    opcao_aprovada=0; fr_opcao_aprovada=0; observacoes=""; origem_linha_excel=0; cadastro_base=$false
                    ferias_bloqueadas=$true; origem_planejamento="PROGRAMACAO_ANTERIOR_IMPORTADA"; bloqueio_motivo="Importado da planilha de férias já definidas para 2027"
                    fixo_inicio=[string]$x.ferias_inicio; fixo_fim=[string]$x.ferias_fim; fixo_tipo_relatorio=[string]$x.ferias_tipo
                    fixo_coluna_origem=[string]$x.coluna_amarela; fixo_importado_em=(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    fixo_arquivo_origem=[IO.Path]::GetFileName($path); registro_criado_por_importacao_fixa=$true
                    pre_import_estado_salvo=$false; pre_import_ferias_bloqueadas=$false; pre_import_origem_planejamento=""; pre_import_bloqueio_motivo=""
                    pre_import_opcao_aprovada=0; pre_import_fixo_inicio=""; pre_import_fixo_fim=""; pre_import_fixo_tipo_relatorio=""
                    pre_import_fixo_coluna_origem=""; pre_import_fixo_importado_em=""; pre_import_fixo_arquivo_origem=""
                    justificativa_decisao=""; fixo_ajustado=$false; fixo_inicio_original=""; fixo_fim_original=""
                    fixo_ajustado_em=""; fixo_motivo_ajuste=""; fixo_observacao_ajuste=""; fixo_ajustado_por=""
                }
                [void](Initialize-RecordDefaults $r)
                $script:Records += $r; $criados++
            }

            # CP é atributo complementar da planilha de fixas, NUNCA substituto da matrícula.
            # Para registros antigos, apenas corrige um CP igual à matrícula caso a planilha traga CP distinto.
            $cpEntrada=([string]$x.cp).Trim()
            if($null -eq $r.PSObject.Properties["cp_relatorio"]){
                $r | Add-Member -NotePropertyName cp_relatorio -NotePropertyValue $cpEntrada -Force
            } elseif($cpEntrada -and ([string]::IsNullOrWhiteSpace([string]$r.cp_relatorio) -or ([string]$r.cp_relatorio).Trim() -eq ([string]$r.matricula).Trim())) {
                $r.cp_relatorio=$cpEntrada
            }

            if([string]::IsNullOrWhiteSpace([string]$r.nome)){ $r.nome=[string]$x.nome }
            if([string]::IsNullOrWhiteSpace([string]$r.setor)){ $r.setor=([string]$x.setor).Trim() }
            if([string]::IsNullOrWhiteSpace([string]$r.periodo)){ $r.periodo=([string]$x.periodo_trabalho).Trim().ToUpperInvariant() }
            $r.ferias_bloqueadas=$true
            $r.origem_planejamento="PROGRAMACAO_ANTERIOR_IMPORTADA"
            $r.bloqueio_motivo="Importado da planilha de férias já definidas para 2027"
            $r.fixo_inicio=[string]$x.ferias_inicio; $r.fixo_fim=[string]$x.ferias_fim; $r.fixo_tipo_relatorio=[string]$x.ferias_tipo
            $r.fixo_coluna_origem=[string]$x.coluna_amarela; $r.fixo_importado_em=(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            $r.fixo_arquivo_origem=[IO.Path]::GetFileName($path)
            if($null -eq $r.PSObject.Properties["registro_criado_por_importacao_fixa"]){ $r | Add-Member -NotePropertyName registro_criado_por_importacao_fixa -NotePropertyValue $false -Force }
            if($null -eq $r.PSObject.Properties["justificativa_decisao"]){ $r | Add-Member -NotePropertyName justificativa_decisao -NotePropertyValue "" -Force }
            if($null -eq $r.PSObject.Properties["fixo_ajustado"]){ $r | Add-Member -NotePropertyName fixo_ajustado -NotePropertyValue $false -Force }
            foreach($prop in @("fixo_inicio_original","fixo_fim_original","fixo_ajustado_em","fixo_motivo_ajuste","fixo_observacao_ajuste","fixo_ajustado_por")){ if($null -eq $r.PSObject.Properties[$prop]){ $r | Add-Member -NotePropertyName $prop -NotePropertyValue "" -Force } }

            $s=([string]$r.setor).Trim(); $pe=([string]$r.periodo).Trim()
            if($s -and @($script:Config.setores) -notcontains $s){
                $script:Config.setores=@(@($script:Config.setores)+$s | Sort-Object -Unique)
                $gNovo="ASSISTENCIAL"
                $sn=Convert-ToUpperSemAcento $s
                if($sn -match 'DIRETORIA.*ENFERMAGEM'){ $gNovo="DIRETORIA DE ENFERMAGEM" }
                elseif($sn -match 'GERENCIA.*ENFERMAGEM'){ $gNovo="GERÊNCIA DE ENFERMAGEM" }
                Set-GrupoAnaliseSetor $s $gNovo
            }
            if($pe -and @($script:Config.periodos) -notcontains $pe){ $script:Config.periodos=@(@($script:Config.periodos)+$pe | Sort-Object -Unique) }
        }
        $script:Config.ferias_fixas_2027_importadas=$true
        $script:Config.ultima_importacao_fixas=(Get-Date -Format "dd/MM/yyyy HH:mm")
        $recPend=Reconciliar-PendenciasImportacao15x15
        Save-Database
        Refresh-SetorPeriodos; Refresh-CadastrosLists; Refresh-Grid; Refresh-Dashboard; Refresh-PlanejamentoSetor; Refresh-ConfigInfo; Refresh-ImportacaoStatus
        [Windows.Forms.MessageBox]::Show("Importação concluída com segurança.`n`nAtualizados: $atualizados`nCriados como compromisso fixo: $criados`nJá existentes preservados: $ja`n`nAs férias fixas agora ocupam capacidade e permanecem protegidas. Ajustes excepcionais podem ser feitos pela Central de decisão, com backup, confirmação e justificativa.","Férias fixas 2027",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        Write-DiagLog "Falha ao importar férias fixas 2027." "ERROR" $_
        try { Load-Database } catch { Write-DiagLog "Falha adicional ao recarregar a base após erro na importação de fixas." "ERROR" $_ }
        [Windows.Forms.MessageBox]::Show("Falha ao importar as férias fixas.`nNenhuma gravação parcial foi mantida em disco.`n`n$($_.Exception.Message)`n`nLog: $script:LogFile","Férias fixas 2027",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}


function Get-PlanoRecuperacaoHistorico($db){
    Assert-DatabaseStructure $db
    if($null -eq $db.PSObject.Properties['historico_ferias']){throw 'Este backup não contém histórico de férias.'}
    $mats=@{}
    foreach($r in @($script:Records)){$mat=([string]$r.matricula).Trim();if($mat){$mats[$mat]=$true}}
    $vinculados=@();$semVinculo=0
    foreach($h in @($db.historico_ferias)){
        $mat=([string]$h.matricula).Trim()
        if($mats.ContainsKey($mat)){$vinculados+=$h}else{$semVinculo++}
    }
    return [pscustomobject]@{merge=(Merge-HistoricoFeriasIncremental $vinculados);sem_vinculo=$semVinculo;lidos=@($db.historico_ferias).Count}
}

function Recuperar-HistoricoBackup {
    $dlg=New-Object Windows.Forms.OpenFileDialog
    $dlg.Title='Recuperar SOMENTE o histórico de férias de um backup'
    $dlg.Filter='Backup JSON (*.json)|*.json';$dlg.InitialDirectory=$script:BackupDir
    try{if($dlg.ShowDialog($form) -ne [Windows.Forms.DialogResult]::OK){return};$path=$dlg.FileName}finally{$dlg.Dispose()}
    try{
        $backup=Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $plano=Get-PlanoRecuperacaoHistorico $backup;$merge=$plano.merge
        $resumo="Recuperar somente o HISTÓRICO deste backup?`n$([IO.Path]::GetFileName($path))`n`nNovos períodos: $($merge.adicionados)`nJá existentes: $($merge.ja_existentes)`nSobreposições não incluídas: $($merge.divergencias)`nInválidos não incluídos: $($merge.invalidos)`nSem matrícula no cadastro atual: $($plano.sem_vinculo)`n`nLançamentos, aprovações, férias fixas e cadastros atuais serão preservados. Um backup será criado antes."
        if($merge.adicionados -eq 0){[Windows.Forms.MessageBox]::Show($resumo+"`n`nNenhum período novo pode ser recuperado automaticamente.",'Histórico')|Out-Null;return}
        if([Windows.Forms.MessageBox]::Show($resumo,'Recuperação seletiva do histórico',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question) -ne [Windows.Forms.DialogResult]::Yes){return}
        [void](Backup-AntesAcao 'ANTES_RECUPERAR_HISTORICO')
        $script:HistoricoFerias=@($merge.itens);Rebuild-HistoricoIndex
        $script:Config.historico_3_anos_importado=(@($script:HistoricoFerias).Count -gt 0)
        $script:Config.ultima_importacao_historico=Get-Date -Format 'dd/MM/yyyy HH:mm'
        Save-Database|Out-Null
        Refresh-ImportacaoStatus;Refresh-HistoricoFeriasUI
        $aviso=''
        try{$auditoria=Exportar-AuditoriaHistoricoIncremental $merge.auditoria}catch{$aviso="`nNão foi possível gravar o CSV de auditoria; consulte o log.";Write-DiagLog 'Recuperação salva, mas CSV de auditoria não foi gravado.' 'WARN' $_}
        Write-DiagLog "Recuperação seletiva de histórico concluída: $($merge.adicionados) novo(s) período(s)." 'INFO'
        [Windows.Forms.MessageBox]::Show("Histórico recuperado: $($merge.adicionados) período(s). Os demais dados atuais foram preservados.$aviso",'Histórico')|Out-Null
    }catch{
        $falha=$_
        try{Load-Database;Refresh-HistoricoFeriasUI}catch{Write-DiagLog 'Falha ao recarregar após erro na recuperação histórica.' 'ERROR' $_}
        Write-DiagLog 'Falha na recuperação seletiva do histórico.' 'ERROR' $falha
        [Windows.Forms.MessageBox]::Show("Recuperação não confirmada: $($falha.Exception.Message)",'Histórico',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)|Out-Null
    }
}

function Importar-HistoricoFerias {
    $path=[string]$script:Config.planilha_historico_ferias
    Write-DiagLog "Solicitada importação do histórico de férias: $path"
    if([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)){
        [Windows.Forms.MessageBox]::Show("Selecione primeiro a planilha de histórico de férias.","Histórico de férias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    try {
        Write-DiagLog "Histórico: etapa 1/6 — lendo planilha e células amarelas."
        $raw=Read-RelatorioFeriasAmarelo $path
        Write-DiagLog ("Histórico: leitura concluída — {0} linha(s) retornada(s)." -f @($raw).Count)
        $totalLidos=@($raw).Count
        $errosLeitura=@($raw | Where-Object { -not [bool]$_.valido }).Count
        $ignCargo=@($raw | Where-Object { [bool]$_.valido -and -not (Test-CargoEnfermeiroHistorico ([string]$_.cargo)) }).Count
        $candidatos=@($raw | Where-Object {
            [bool]$_.valido -and
            (Test-CargoEnfermeiroHistorico ([string]$_.cargo)) -and
            [int]$_.ano_referencia -ge 1900 -and [int]$_.ano_referencia -le 9998 -and
            [int]$_.mes_referencia -ge 1 -and [int]$_.mes_referencia -le 12
        })
        Write-DiagLog "Histórico: etapa 2/6 — vinculando matrícula exata e conferindo nome e montando prévia."
        $rows=Get-PreviewHistorico $raw
        $importaveis=@($rows | Where-Object { [string]$_.preview_status -eq "IMPORTAR" })
        $semVinculo=@($rows | Where-Object { [string]$_.preview_status -in @("SEM VÍNCULO","AMBÍGUO","NOME DIVERGENTE") }).Count
        $duplicadosDescartados=[math]::Max(0,($candidatos.Count-@($rows | Where-Object {[bool]$_.valido}).Count))
        $porAno=(@($importaveis | Group-Object ano_referencia | Sort-Object Name | ForEach-Object {"$($_.Name)=$($_.Count)"}) -join ', ')
        $serv=@($importaveis | Select-Object -ExpandProperty matricula_sistema -Unique).Count
        $resumo="Lidos: $totalLidos | histórico vinculado e importável: $($importaveis.Count) | servidores vinculados: $serv | sem vínculo automático: $semVinculo | outros cargos ignorados: $ignCargo | duplicidades descartadas: $duplicadosDescartados | erros de leitura: $errosLeitura. Por ano: $porAno. O relatório usa MATRÍCULA como chave exata e confere o nome; CP é informação complementar opcional. A importação é incremental: dados anteriores são preservados. Para desempate, o mês só conta como utilizado quando totaliza pelo menos 15 dias efetivos de férias dentro dele; parcelas no mesmo mês são somadas por dias únicos. Ausência em um ano = 'sem registro'."
        $arquivoRejeitados=""
        try { $arquivoRejeitados=Exportar-RejeitadosImportacao 'HISTORICO' $rows @('IMPORTAR') }
        catch {
            Write-DiagLog "Não foi possível gravar o relatório de conferência do histórico." "ERROR" $_
            [Windows.Forms.MessageBox]::Show("A prévia pode ser consultada, mas o relatório de não importados NÃO foi salvo. Verifique as permissões da pasta Logs. Detalhe: $($_.Exception.Message)","Auditoria de importação",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
        }
        if($arquivoRejeitados){ $resumo += " Registro(s) não importado(s): relatório salvo em Logs\Conferencia_Importacoes." }
        if(-not (Show-PreviewImportacao "Prévia — Histórico de férias" $rows $resumo)){ return }
        if($importaveis.Count -eq 0){
            [Windows.Forms.MessageBox]::Show("Nenhum histórico pôde ser vinculado com segurança aos servidores atuais.","Histórico de férias") | Out-Null
            return
        }

        Write-DiagLog "Histórico: etapa 3/6 — prévia confirmada; criando backup."
        [void](Backup-AntesAcao "ANTES_IMPORTAR_HISTORICO")
        $novo=@()
        foreach($x in $importaveis){
            $matSistema=([string]$x.matricula_sistema).Trim()
            if(-not $matSistema -or @($script:Records | Where-Object { ([string]$_.matricula).Trim() -eq $matSistema }).Count -eq 0){
                Write-DiagLog "HISTÓRICO: registro não vinculado a servidor atual ignorado; Matrícula=$([string]$x.matricula)" "WARN"
                continue
            }
            $novo += [pscustomobject]@{
                matricula=[string]$x.matricula_sistema; cp_relatorio=[string]$x.cp; nome=[string]$x.nome; ano=[int]$x.ano_referencia; mes=[int]$x.mes_referencia
                inicio=[string]$x.ferias_inicio; fim=[string]$x.ferias_fim; dias=[int]$x.ferias_dias
                setor_origem=[string]$x.setor; periodo_origem=[string]$x.periodo_trabalho
                aquisitivo_inicio=[string]$x.aquisitivo_inicio; aquisitivo_fim=[string]$x.aquisitivo_fim
                linha_origem=[int]$x.linha; arquivo_origem=[IO.Path]::GetFileName($path)
            }
        }
        Write-DiagLog ("Histórico: etapa 4/6 — mesclando {0} registro(s) de forma incremental." -f @($novo).Count)
        $merge=Merge-HistoricoFeriasIncremental $novo
        # $merge.itens já é Object[]; não envolver Generic.List em @() no PowerShell 5.1.
        $script:HistoricoFerias=@($merge.itens)
        Write-DiagLog ("Histórico: merge concluído — novos {0}, já existentes preservados {1}, alterações de existentes ZERO, total {2}." -f $merge.adicionados,$merge.ja_existentes,@($script:HistoricoFerias).Count)
        Rebuild-HistoricoIndex
        $script:Config.historico_3_anos_importado=(@($script:HistoricoFerias).Count -gt 0)
        $script:Config.ultima_importacao_historico=(Get-Date -Format "dd/MM/yyyy HH:mm")
        Write-DiagLog "Histórico: etapa 5/6 — reconciliando pendências 15+15 e salvando base."
        $recPend=Reconciliar-PendenciasImportacao15x15
        Save-Database
        Write-DiagLog "Histórico: etapa 6/6 — atualizando telas após gravação."
        Refresh-PlanejamentoSetor; Refresh-ConfigInfo; Refresh-ImportacaoStatus; Refresh-HistoricoFeriasUI
        $arquivoAuditoria=''
        $avisoAuditoria=''
        try {
            $arquivoAuditoria=Exportar-AuditoriaHistoricoIncremental $merge.auditoria
            Write-DiagLog "Auditoria do histórico gravada: $arquivoAuditoria"
        } catch {
            $avisoAuditoria="`nATENÇÃO: não foi possível salvar o CSV de auditoria. Consulte o log."
            Write-DiagLog "Falha ao exportar auditoria do histórico importado." "ERROR" $_
        }
        $msgAuditoria=if($arquivoAuditoria){ "`nAuditoria por registro: $arquivoAuditoria" } else { $avisoAuditoria }
        [Windows.Forms.MessageBox]::Show("Histórico importado de forma INCREMENTAL.`n`nLidos/vinculados nesta importação: $($novo.Count)`nNovos períodos incluídos: $($merge.adicionados)`nPeríodos idênticos já existentes (preservados): $($merge.ja_existentes)`nRegistros existentes alterados: 0`nSobreposições para conferência (não importadas): $($merge.divergencias)`nRegistros inválidos (não importados): $($merge.invalidos)`nHistóricos anteriores preservados: $($merge.preservados)`nDuplicatas pré-existentes mantidas: $($merge.duplicados_preexistentes_preservados)`nTotal acumulado no sistema: $(@($script:HistoricoFerias).Count)`nServidores no arquivo atual: $serv`n$msgAuditoria`n`nReimportar uma planilha parcial NÃO apaga anos anteriores. Para desempate, o mês conta quando totaliza pelo menos 15 dias efetivos; parcelas no mesmo mês somam dias únicos.","Histórico de férias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        Write-DiagLog "Falha ao importar histórico de férias." "ERROR" $_
        try { Load-Database } catch { Write-DiagLog "Falha adicional ao recarregar a base após erro na importação do histórico." "ERROR" $_ }
        [Windows.Forms.MessageBox]::Show("Falha ao importar o histórico.`n$($_.Exception.Message)`n`nLog: $script:LogFile","Histórico de férias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

function Refresh-ImportacaoStatus {
    if($null -ne $script:lblFixasStatus){
        $q=@($script:Records | Where-Object { Test-RegistroFixoImportado $_ }).Count
        $ult=[string]$script:Config.ultima_importacao_fixas
        $script:lblFixasStatus.Text=if($q -gt 0){"$q férias fixa(s) importada(s). Última importação: $ult"}else{"Nenhuma férias fixa importada."}
    }
    if($null -ne $script:lblHistoricoImportStatus){
        $q=@($script:HistoricoFerias).Count
        $srv=@($script:HistoricoFerias | Select-Object -ExpandProperty matricula -Unique).Count
        $ult=[string]$script:Config.ultima_importacao_historico
        $script:lblHistoricoImportStatus.Text=if($q -gt 0){"$q registro(s) históricos | $srv servidor(es). Última importação: $ult"}else{"Histórico ainda não importado."}
    }
    if($null -ne $script:lblAnuladosStatus){
        $todos=@($script:Config.importacao_lancamentos_anulados)
        $anul=@($todos | Where-Object { [string]$_.status -eq "ANULADO" }).Count
        $pend=@($todos | Where-Object { [string]$_.status -eq "PENDENTE" }).Count
        $rev=@($todos | Where-Object { [string]$_.status -eq "REVISAR" }).Count
        $conf=@($todos | Where-Object { [string]$_.status -eq "CONFIRMADO" }).Count
        $corr=@($todos | Where-Object { [string]$_.status -eq "CORRIGIDO" }).Count
        $script:lblAnuladosStatus.Text="Anulados: $anul   |   Pendentes 15 dias: $pend   |   Revisar: $rev   |   Confirmados: $conf   |   Corrigidos: $corr   |   Histórico: $($todos.Count)"
    }
}

function Confirmar-ResetDuplo([string]$titulo,[string]$descricao,[bool]$digitado=$false){
    $a=[Windows.Forms.MessageBox]::Show($descricao+"`n`nUm BACKUP obrigatório será criado antes da alteração.`nOs backups existentes não serão apagados.`n`nDeseja continuar?",$titulo,[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
    if($a -ne [Windows.Forms.DialogResult]::Yes){ return $false }
    if(-not $digitado){
        $b=[Windows.Forms.MessageBox]::Show("SEGUNDA CONFIRMAÇÃO`n`nConfirma a operação?",$titulo,[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
        return ($b -eq [Windows.Forms.DialogResult]::Yes)
    }

    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Confirmação de segurança — $titulo"; $dlg.StartPosition="CenterParent"; $dlg.Size=New-Object Drawing.Size(560,245); $dlg.FormBorderStyle="FixedDialog"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $lbl=New-Object Windows.Forms.Label; $lbl.Location=New-Object Drawing.Point(18,18); $lbl.Size=New-Object Drawing.Size(510,75)
    $lbl.Text="Operação: $titulo.`r`nDigite exatamente RESETAR no campo abaixo para liberar o botão de confirmação."; $dlg.Controls.Add($lbl)
    $txt=New-TextBox 18 100 505; $dlg.Controls.Add($txt)
    $ok=New-Button "Confirmar operação" 245 145 185 38; $ok.Enabled=$false; $ok.BackColor=[Drawing.Color]::MistyRose; $dlg.Controls.Add($ok)
    $cancel=New-Button "Cancelar" 440 145 85 38; $dlg.Controls.Add($cancel)
    $txt.add_TextChanged({ $ok.Enabled=($txt.Text.Trim().ToUpperInvariant() -eq "RESETAR") })
    $ok.add_Click({ $dlg.DialogResult=[Windows.Forms.DialogResult]::OK; $dlg.Close() })
    $cancel.add_Click({ $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel; $dlg.Close() })
    return ($dlg.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK)
}

function Refresh-AllAfterMaintenance {
    Refresh-SetorPeriodos; Refresh-CadastrosLists; Update-SetoresFiltroResumo; Refresh-Grid; Clear-Editor; Refresh-Dashboard; Refresh-PlanejamentoSetor; Refresh-PoliticaMensalInfo; Refresh-ConfigInfo; Refresh-ImportacaoStatus; Refresh-HistoricoFeriasUI
    if($null -ne $script:txtPlanilhaBase){ $script:txtPlanilhaBase.Text=[string]$script:Config.planilha_base }
    if($null -ne $script:txtFixasPath){ $script:txtFixasPath.Text=[string]$script:Config.planilha_ferias_fixas_2027 }
    if($null -ne $script:txtHistoricoPath){ $script:txtHistoricoPath.Text=[string]$script:Config.planilha_historico_ferias }
    if($null -ne $numTotalEnf){
        $v=[int]$script:Config.total_enfermeiros_planejamento; if($v -lt [int]$numTotalEnf.Minimum){$v=[int]$numTotalEnf.Minimum}; if($v -gt [int]$numTotalEnf.Maximum){$v=[int]$numTotalEnf.Maximum}; $numTotalEnf.Value=[decimal]$v
    }
    if($null -ne $numPctRestrito){
        $v=[int]$script:Config.percentual_meses_restritos; if($v -lt 1){$v=1}; if($v -gt 100){$v=100}; $numPctRestrito.Value=[decimal]$v
    }
    if($null -ne $script:chkMesRestrito){ for($i=0;$i -lt $script:chkMesRestrito.Count;$i++){ $script:chkMesRestrito[$i].Checked=(@($script:Config.meses_restritos) -contains ($i+1)) } }
    if($null -ne $script:numLimiteEspecialMes){
        for($i=0;$i -lt $script:numLimiteEspecialMes.Count;$i++){
            $v=0; $lim=$script:Config.limites_especiais_mensais; $ch=[string]($i+1)
            try { if($lim -is [System.Collections.IDictionary]){ $v=[decimal]$lim[$ch] } elseif($null -ne $lim -and $null -ne $lim.PSObject.Properties[$ch]){ $v=[decimal]$lim.PSObject.Properties[$ch].Value } } catch {$v=0}
            if($v -lt 0 -or $v -gt 5000){$v=0}; $script:numLimiteEspecialMes[$i].Value=$v
        }
    }
}

function Reset-DecisoesAtuais {
    $desc="Serão apagadas as aprovações comuns e FR da programação atual.`n`nSERÁ PRESERVADO: 1ª/2ª/3ª opções informadas, cadastros, setores, grupos, chefias, limites, férias fixas importadas e histórico."
    if(-not (Confirmar-ResetDuplo "Resetar decisões atuais" $desc $false)){ return }
    [void](Backup-AntesAcao "ANTES_RESET_DECISOES")
    $q=0
    foreach($r in $script:Records){
        if(-not (Test-RegistroFeriasBloqueadas $r)){
            if([int]$r.opcao_aprovada -gt 0 -or [int]$r.fr_opcao_aprovada -gt 0){ $q++ }
            $r.opcao_aprovada=0
            $r.fr_opcao_aprovada=0
            $r.justificativa_decisao=""
        }
    }
    Save-Database; Refresh-AllAfterMaintenance
    [Windows.Forms.MessageBox]::Show("Reset concluído.`n$q decisão(ões) atual(is) foram removidas.`nFérias fixas e histórico foram preservados.","Reset concluído") | Out-Null
}

function Reset-FixasImportadas {
    $desc="Serão removidas SOMENTE as férias fixas provenientes da importação da planilha 'Férias já OK para 2027'.`n`nFérias marcadas manualmente como fixas, solicitações atuais, cadastros, chefias, limites e histórico serão preservados."
    if(-not (Confirmar-ResetDuplo "Remover férias fixas importadas" $desc $false)){ return }
    [void](Backup-AntesAcao "ANTES_RESET_FIXAS")
    $removerIds=@(); $limpas=0
    foreach($r in @($script:Records)){
        $importada=(Test-RegistroFixoImportado $r) -and (([string]$r.origem_planejamento -eq "PROGRAMACAO_ANTERIOR_IMPORTADA") -or -not [string]::IsNullOrWhiteSpace([string]$r.fixo_importado_em))
        if(-not $importada){ continue }
        if([bool]$r.registro_criado_por_importacao_fixa){
            $removerIds += [int]$r.id
        } else {
            if([bool]$r.pre_import_estado_salvo){
                $anteriores=@()
                if($null -ne $r.PSObject.Properties['pre_import_fixos_adicionais']){$anteriores=@($r.pre_import_fixos_adicionais)}
                else {
                    # Versoes antigas: remover somente adicionais identificados como importados.
                    $anteriores=@(Get-FixasAdicionais $r | Where-Object {-not [string]$_.importado_em -and -not [string]$_.arquivo})
                    Write-DiagLog "Reset ID=$($r.id): snapshot antigo sem parcelas; preservados adicionais sem origem de importacao." 'WARN'
                }
                $r | Add-Member NoteProperty fixos_adicionais $anteriores -Force
                if($null -ne $r.PSObject.Properties['pre_import_fr_opcao_aprovada']){$r.fr_opcao_aprovada=[int]$r.pre_import_fr_opcao_aprovada}
                $r.ferias_bloqueadas=[bool]$r.pre_import_ferias_bloqueadas
                $r.origem_planejamento=[string]$r.pre_import_origem_planejamento
                $r.bloqueio_motivo=[string]$r.pre_import_bloqueio_motivo
                $r.opcao_aprovada=[int]$r.pre_import_opcao_aprovada
                $r.fixo_inicio=[string]$r.pre_import_fixo_inicio
                $r.fixo_fim=[string]$r.pre_import_fixo_fim
                $r.fixo_tipo_relatorio=[string]$r.pre_import_fixo_tipo_relatorio
                $r.fixo_coluna_origem=[string]$r.pre_import_fixo_coluna_origem
                $r.fixo_importado_em=[string]$r.pre_import_fixo_importado_em
                $r.fixo_arquivo_origem=[string]$r.pre_import_fixo_arquivo_origem
                $r.fixo_ajustado=[bool]$r.pre_import_fixo_ajustado
                $r.fixo_inicio_original=[string]$r.pre_import_fixo_inicio_original
                $r.fixo_fim_original=[string]$r.pre_import_fixo_fim_original
                $r.fixo_ajustado_em=[string]$r.pre_import_fixo_ajustado_em
                $r.fixo_motivo_ajuste=[string]$r.pre_import_fixo_motivo_ajuste
                $r.fixo_observacao_ajuste=[string]$r.pre_import_fixo_observacao_ajuste
                $r.fixo_ajustado_por=[string]$r.pre_import_fixo_ajustado_por
            } else {
                $r | Add-Member NoteProperty fixos_adicionais @() -Force
                # Compatibilidade defensiva com importações feitas por versões anteriores à V1.0.40.
                $r.ferias_bloqueadas=$false; $r.origem_planejamento="ATUAL"; $r.bloqueio_motivo=""
                $r.fixo_inicio=""; $r.fixo_fim=""; $r.fixo_tipo_relatorio=""; $r.fixo_coluna_origem=""; $r.fixo_importado_em=""; $r.fixo_arquivo_origem=""
                $r.fixo_ajustado=$false; $r.fixo_inicio_original=""; $r.fixo_fim_original=""; $r.fixo_ajustado_em=""; $r.fixo_motivo_ajuste=""; $r.fixo_observacao_ajuste=""; $r.fixo_ajustado_por=""
                Write-DiagLog "Reset de fixa importada sem estado prévio disponível para registro ID=$([int]$r.id)." "WARN"
            }
            $r | Add-Member NoteProperty pre_import_fixos_adicionais @() -Force
            $r | Add-Member NoteProperty pre_import_fr_opcao_aprovada 0 -Force
            $r.pre_import_estado_salvo=$false
            $r.pre_import_ferias_bloqueadas=$false; $r.pre_import_origem_planejamento=""; $r.pre_import_bloqueio_motivo=""; $r.pre_import_opcao_aprovada=0
            $r.pre_import_fixo_inicio=""; $r.pre_import_fixo_fim=""; $r.pre_import_fixo_tipo_relatorio=""; $r.pre_import_fixo_coluna_origem=""; $r.pre_import_fixo_importado_em=""; $r.pre_import_fixo_arquivo_origem=""
            $r.pre_import_fixo_ajustado=$false; $r.pre_import_fixo_inicio_original=""; $r.pre_import_fixo_fim_original=""; $r.pre_import_fixo_ajustado_em=""; $r.pre_import_fixo_motivo_ajuste=""; $r.pre_import_fixo_observacao_ajuste=""; $r.pre_import_fixo_ajustado_por=""
            # IMPORTANTE: os campos fixo_ajustado_* acima já foram restaurados do estado anterior quando existiam.
            # Não os zera aqui, pois isso apagaria o histórico de uma fixa manualmente ajustada antes da importação.
            $limpas++
        }
    }
    if($removerIds.Count -gt 0){ $script:Records=@($script:Records | Where-Object { $removerIds -notcontains [int]$_.id }) }
    $script:Config.ferias_fixas_2027_importadas=$false; $script:Config.ultima_importacao_fixas=""
    Save-Database; Refresh-AllAfterMaintenance
    [Windows.Forms.MessageBox]::Show("Férias fixas importadas removidas.`nRegistros exclusivos removidos: $($removerIds.Count)`nRegistros existentes desbloqueados: $limpas","Reset concluído") | Out-Null
}

function Reset-HistoricoImportado {
    $desc="Será apagado SOMENTE o histórico importado de TODOS os anos usado como critério de desempate.`n`nNenhum lançamento atual, férias fixa, cadastro, grupo, chefia ou limite será alterado."
    if(-not (Confirmar-ResetDuplo "Limpar histórico importado" $desc $true)){ return }
    [void](Backup-AntesAcao "ANTES_RESET_HISTORICO")
    $q=@($script:HistoricoFerias).Count; $script:HistoricoFerias=@(); Rebuild-HistoricoIndex; $script:Config.historico_3_anos_importado=$false; $script:Config.ultima_importacao_historico=""
    Save-Database; Refresh-AllAfterMaintenance
    [Windows.Forms.MessageBox]::Show("Histórico removido: $q registro(s).","Reset concluído") | Out-Null
}

function Reset-PlanejamentoAtual {
    $desc="Será ZERADO o planejamento atual sem apagar os cadastros-base.`n`nSERÁ APAGADO:`n• 1ª, 2ª e 3ª opções de férias`n• opção aceita / decisão`n• justificativa da decisão`n• férias fixas importadas, manuais e ajustadas`n• histórico importado usado no desempate`n`nSERÁ PRESERVADO:`n• servidores e matrículas`n• setor e período de trabalho`n• períodos aquisitivos`n• observações gerais do período aquisitivo`n• setores, períodos, grupos de análise, grupos de chefia e limites`n• política mensal e backups existentes."
    if(-not (Confirmar-ResetDuplo "ZERAR PLANEJAMENTO ATUAL" $desc $false)){ return }
    [void](Backup-AntesAcao "ANTES_RESET_PLANEJAMENTO")

    $vazio={ New-EmptyOptionObject }
    foreach($r in @($script:Records)){
        $r | Add-Member NoteProperty fixos_adicionais @() -Force
        $r | Add-Member NoteProperty pre_import_fixos_adicionais @() -Force
        $r | Add-Member NoteProperty pre_import_fr_opcao_aprovada 0 -Force
        $r.opcao1=& $vazio; $r.opcao2=& $vazio; $r.opcao3=& $vazio
        $r.opcao_aprovada=0
        $r.fr_opcao_aprovada=0
        $r.justificativa_decisao=""
        $r.ferias_bloqueadas=$false; $r.origem_planejamento="ATUAL"; $r.bloqueio_motivo=""
        $r.fixo_inicio=""; $r.fixo_fim=""; $r.fixo_tipo_relatorio=""; $r.fixo_coluna_origem=""; $r.fixo_importado_em=""; $r.fixo_arquivo_origem=""
        $r.registro_criado_por_importacao_fixa=$false
        $r.pre_import_estado_salvo=$false; $r.pre_import_ferias_bloqueadas=$false; $r.pre_import_origem_planejamento=""; $r.pre_import_bloqueio_motivo=""; $r.pre_import_opcao_aprovada=0
        $r.pre_import_fixo_inicio=""; $r.pre_import_fixo_fim=""; $r.pre_import_fixo_tipo_relatorio=""; $r.pre_import_fixo_coluna_origem=""; $r.pre_import_fixo_importado_em=""; $r.pre_import_fixo_arquivo_origem=""
        $r.pre_import_fixo_ajustado=$false; $r.pre_import_fixo_inicio_original=""; $r.pre_import_fixo_fim_original=""; $r.pre_import_fixo_ajustado_em=""; $r.pre_import_fixo_motivo_ajuste=""; $r.pre_import_fixo_observacao_ajuste=""; $r.pre_import_fixo_ajustado_por=""
        $r.fixo_ajustado=$false; $r.fixo_inicio_original=""; $r.fixo_fim_original=""; $r.fixo_ajustado_em=""; $r.fixo_motivo_ajuste=""; $r.fixo_observacao_ajuste=""; $r.fixo_ajustado_por=""
    }
    $script:HistoricoFerias=@()
    if(Get-Command Rebuild-HistoricoIndex -ErrorAction SilentlyContinue){ Rebuild-HistoricoIndex }
    $script:Config.ferias_fixas_2027_importadas=$false
    $script:Config.ultima_importacao_fixas=""
    $script:Config.historico_3_anos_importado=$false
    $script:Config.ultima_importacao_historico=""
    $script:Config.ultimo_backup_lote=""
    $script:Config.ultimo_manifesto_lote=""
    $script:Config.servidores_excluidos=@()

    Save-Database
    Refresh-AllAfterMaintenance
    [Windows.Forms.MessageBox]::Show("Planejamento zerado com sucesso.`n`nServidores e períodos aquisitivos foram preservados.`nOpções, decisões, férias fixas e histórico foram removidos.`n`nOs backups anteriores permanecem disponíveis.","Planejamento zerado",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Restaurar-BaseInicialSeed {
    $desc="A base operacional será substituída pelo arquivo inicial (seed).`n`nUse esta opção quando quiser VOLTAR À BASE ORIGINAL distribuída com o sistema. Os servidores/períodos que já existem no seed voltarão a aparecer.`n`nA pasta Backups NÃO será apagada."
    if(-not (Confirmar-ResetDuplo "RESTAURAR BASE INICIAL (SEED)" $desc $false)){ return }
    if(-not (Test-Path -LiteralPath $script:SeedFile)){
        [Windows.Forms.MessageBox]::Show("Restauração cancelada: arquivo inicial não encontrado:`n$script:SeedFile","Base inicial",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }
    try {
        [void](Restore-DatabaseSafely $script:SeedFile "ANTES_RESET_BASE_INICIAL" "Restauração da base inicial")
        Refresh-AllAfterMaintenance
        [Windows.Forms.MessageBox]::Show("Base inicial restaurada com proteção de concorrência.`n`nIMPORTANTE: os servidores/períodos que fazem parte do arquivo seed voltam a aparecer. Isso é diferente do RESET TOTAL REAL.`n`nBackups anteriores preservados.","Base inicial restaurada",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        if(([string]$_.Exception.Message) -notlike 'CONFLITO_RESTAURACAO_TRATADO:*'){
            [Windows.Forms.MessageBox]::Show("Não foi possível restaurar a base inicial.`n$($_.Exception.Message)","Base inicial",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    }
}

function Reset-TotalSistema {
    $desc="RESET TOTAL REAL — BASE OPERACIONAL VAZIA.`n`nSERÁ APAGADO da base ativa:`n• TODOS os servidores`n• TODOS os períodos aquisitivos`n• opções e decisões`n• férias fixas`n• histórico importado`n• inconsistências e ocorrências antigas de importação`n• vínculos operacionais dos lançamentos`n`nSERÁ PRESERVADO:`n• estrutura/configurações do sistema (setores, períodos de trabalho, grupos, chefias, limites e política mensal)`n• TODOS os arquivos da pasta Backups.`n`nA sincronização automática será DESATIVADA e os caminhos das planilhas serão limpos para impedir repovoamento automático após o reset."
    if(-not (Confirmar-ResetDuplo "RESET TOTAL REAL — BASE VAZIA" $desc $true)){ return }
    [void](Backup-AntesAcao "ANTES_RESET_TOTAL_REAL")

    $script:Records=@()
    $script:HistoricoFerias=@()
    if(Get-Command Rebuild-HistoricoIndex -ErrorAction SilentlyContinue){ Rebuild-HistoricoIndex }

    # Remove apenas estado operacional/importações; mantém cadastros estruturais e regras.
    $script:Config.sincronizar_ao_abrir=$false
    $script:Config.planilha_base=""
    $script:Config.planilha_ferias_fixas_2027=""
    $script:Config.planilha_historico_ferias=""
    $script:Config.ferias_fixas_2027_importadas=$false
    $script:Config.historico_3_anos_importado=$false
    $script:Config.ultima_importacao_fixas=""
    $script:Config.ultima_importacao_historico=""
    $script:Config.ultimo_backup_lote=""
    $script:Config.ultimo_manifesto_lote=""
    # V1.0.100: o reset total também limpa a central de inconsistências.
    # A limpeza é persistida na base ativa no mesmo Save-Database do reset.
    $script:Config.importacao_lancamentos_anulados=@()

    Save-Database
    Refresh-AllAfterMaintenance
    [Windows.Forms.MessageBox]::Show("RESET TOTAL REAL concluído.`n`nA base operacional está vazia:`n• 0 servidores`n• 0 períodos aquisitivos`n• 0 registros históricos`n• 0 inconsistências antigas de importação`n`nSetores, grupos, chefias, limites e política mensal foram preservados.`nTodos os backups anteriores continuam disponíveis.","Reset total real",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Restaurar-UltimoPreReset {
    # O timestamp confiável está no nome, pois Copy-Item pode preservar LastWriteTime da origem.
    $b=Get-ChildItem -LiteralPath $script:BackupDir -Filter "ANTES_RESET_*.json" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '_(\d{8})_(\d{6})_(\d{3})\.json$' -and
        $null -ne $(try {[datetime]::ParseExact(($Matches[1]+$Matches[2]+$Matches[3]),'yyyyMMddHHmmssfff',[Globalization.CultureInfo]::InvariantCulture)}catch {$null}) } |
        Sort-Object @{Expression={if($_.Name -match '_(\d{8})_(\d{6})_(\d{3})\.json$'){[datetime]::ParseExact(($Matches[1]+$Matches[2]+$Matches[3]),'yyyyMMddHHmmssfff',[Globalization.CultureInfo]::InvariantCulture)}};Descending=$true},Name | Select-Object -First 1
    if($null -eq $b){ [Windows.Forms.MessageBox]::Show("Nenhum backup pré-reset foi encontrado.","Restaurar backup") | Out-Null; return }
    $quando=$b.Name
    if($b.Name -match '_(\d{8})_(\d{6})_(\d{3})\.json$'){
        try { $quando=[datetime]::ParseExact(($Matches[1]+$Matches[2]+$Matches[3]),'yyyyMMddHHmmssfff',[Globalization.CultureInfo]::InvariantCulture).ToString('dd/MM/yyyy HH:mm:ss.fff') } catch {}
    }
    $desc="Será restaurado o backup:`n$($b.Name)`nCriado em: $quando`n`nA restauração usa o mesmo lock/revisão da gravação normal e será cancelada se outro usuário tiver alterado a base."
    if(-not (Confirmar-ResetDuplo "Restaurar último backup pré-reset" $desc $false)){ return }
    try {
        [void](Restore-DatabaseSafely $b.FullName "ANTES_RESTAURAR_PRE_RESET" "Restauração de backup pré-reset")
        Refresh-AllAfterMaintenance
        [Windows.Forms.MessageBox]::Show("Backup restaurado com sucesso e proteção de concorrência.","Restaurar backup") | Out-Null
    } catch {
        if(([string]$_.Exception.Message) -notlike 'CONFLITO_RESTAURACAO_TRATADO:*'){
            [Windows.Forms.MessageBox]::Show("Não foi possível restaurar o backup.`n$($_.Exception.Message)","Restaurar backup",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    }
}

function Show-SyncDivergenciasDialog($divergencias){
    $lista=@($divergencias)
    if($lista.Count -eq 0){ return "PRESERVAR" }
    $script:SyncDivergAction="CANCELAR"
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="Conferência de alterações encontradas na planilha base"
    $dlg.StartPosition="CenterParent"; $dlg.Size=New-Object Drawing.Size(1180,620); $dlg.MinimumSize=New-Object Drawing.Size(1000,520)
    $top=New-Object Windows.Forms.Panel; $top.Dock="Top"; $top.Height=78; $top.BackColor=[Drawing.Color]::FromArgb(245,248,252); $dlg.Controls.Add($top)
    $t=New-Object Windows.Forms.Label; $t.Location=New-Object Drawing.Point(15,10); $t.Size=New-Object Drawing.Size(1130,24); $t.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold); $t.Text="$($lista.Count) registro(s) já existentes possuem opções diferentes na planilha."; $top.Controls.Add($t)
    $d=New-Object Windows.Forms.Label; $d.Location=New-Object Drawing.Point(15,38); $d.Size=New-Object Drawing.Size(1130,34); $d.Text="Nada será alterado sem sua autorização. Compare o que está NO SISTEMA com o que veio NA PLANILHA e escolha uma das ações abaixo."; $top.Controls.Add($d)
    $bottom=New-Object Windows.Forms.Panel; $bottom.Dock="Bottom"; $bottom.Height=66; $dlg.Controls.Add($bottom)
    $b1=New-Button "MANTER O QUE ESTÁ NO SISTEMA" 350 14 235 36; $b2=New-Button "APLICAR OPÇÕES DA PLANILHA" 595 14 225 36; $b2.BackColor=[Drawing.Color]::FromArgb(255,244,204); $b3=New-Button "Cancelar sincronização" 830 14 180 36
    $bottom.Controls.Add($b1);$bottom.Controls.Add($b2);$bottom.Controls.Add($b3)
    $g=New-Object Windows.Forms.DataGridView; $g.Dock="Fill"; $g.ReadOnly=$true; $g.AllowUserToAddRows=$false; $g.RowHeadersVisible=$false; $g.AutoSizeColumnsMode="Fill"; $g.SelectionMode="FullRowSelect"; $g.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(@("mat","Matrícula"),@("nome","Nome"),@("aq","Período aquisitivo"),@("sis","NO SISTEMA"),@("xls","NA PLANILHA"))){[void]$g.Columns.Add($c[0],$c[1])}
    $g.Columns["mat"].FillWeight=12;$g.Columns["nome"].FillWeight=22;$g.Columns["aq"].FillWeight=18;$g.Columns["sis"].FillWeight=24;$g.Columns["xls"].FillWeight=24
    foreach($x in $lista){$i=$g.Rows.Add();$rr=$g.Rows[$i];$rr.Cells["mat"].Value=$x.matricula;$rr.Cells["nome"].Value=$x.nome;$rr.Cells["aq"].Value=$x.aquisitivo;$rr.Cells["sis"].Value=$x.sistema;$rr.Cells["xls"].Value=$x.planilha}
    $dlg.Controls.Add($g);$g.BringToFront()
    $b1.add_Click({$script:SyncDivergAction="PRESERVAR";$dlg.Close()})
    $b2.add_Click({$resp=[Windows.Forms.MessageBox]::Show("Aplicar as opções da planilha nos $($lista.Count) registro(s) divergentes?`n`nSe algum registro divergente já tiver opção aceita, a decisão voltará para NÃO DEFINIDA para nova conferência; a decisão anterior ficará registrada nas observações.","Confirmar atualização",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning);if($resp -eq [Windows.Forms.DialogResult]::Yes){$script:SyncDivergAction="APLICAR";$dlg.Close()}})
    $b3.add_Click({$script:SyncDivergAction="CANCELAR";$dlg.Close()})
    [void]$dlg.ShowDialog($form)
    return [string]$script:SyncDivergAction
}


function Get-ImportTextKey([string]$texto){
    if([string]::IsNullOrWhiteSpace($texto)){ return "" }
    $s=Convert-ToUpperSemAcento $texto
    $s=[regex]::Replace($s,'\s+',' ').Trim()
    return $s
}

function Resolve-GrupoAnaliseImport([string]$texto){
    $raw=([string]$texto).Trim()
    if(-not $raw){
        return [pscustomobject]@{vazio=$true;valido=$true;canonico="";original=""}
    }

    $k=Get-ImportTextKey $raw
    $k=[regex]::Replace($k,'^GRUPO\s+','').Trim()
    switch($k){
        "ASSISTENCIAL" {
            return [pscustomobject]@{vazio=$false;valido=$true;canonico="ASSISTENCIAL";original=$raw}
        }
        "GERENCIA DE ENFERMAGEM" {
            return [pscustomobject]@{vazio=$false;valido=$true;canonico="GERÊNCIA DE ENFERMAGEM";original=$raw}
        }
        "DIRETORIA DE ENFERMAGEM" {
            return [pscustomobject]@{vazio=$false;valido=$true;canonico="DIRETORIA DE ENFERMAGEM";original=$raw}
        }
        default {
            return [pscustomobject]@{vazio=$false;valido=$false;canonico="";original=$raw}
        }
    }
}

function Get-CanonicalSetorName([string]$setor){
    $raw=([string]$setor).Trim()
    if(-not $raw){ return "" }
    $key=Get-ImportTextKey $raw
    foreach($s in @($script:Config.setores)){
        if((Get-ImportTextKey ([string]$s)) -eq $key){ return ([string]$s).Trim() }
    }
    return $raw
}

function Get-CanonicalGrupoChefiaName([string]$grupo){
    $raw=([string]$grupo).Trim()
    if(-not $raw){ return "" }
    $key=Get-ImportTextKey $raw
    foreach($g in @(Get-GruposChefiaNomes)){
        if((Get-ImportTextKey ([string]$g)) -eq $key){ return ([string]$g).Trim() }
    }
    return $raw
}

function Get-ExplicitGrupoAnaliseSetor([string]$setor){
    $key=Get-ImportTextKey $setor
    if(-not $key){ return "" }
    foreach($x in @($script:Config.grupo_analise_setores)){
        if((Get-ImportTextKey ([string]$x.setor)) -eq $key){
            return ([string]$x.grupo).Trim()
        }
    }
    return ""
}

function Get-ImportCadastroPlan([array]$incoming){
    $porSetor=@{}
    $linhasSemSetor=@()

    foreach($x in @($incoming)){
        $setor=([string]$x.setor).Trim()
        if(-not $setor){
            $linhasSemSetor += [pscustomobject]@{
                linha=[int]$x.origem_linha_excel
                matricula=[string]$x.matricula
                nome=[string]$x.nome
            }
            continue
        }

        $key=Get-ImportTextKey $setor
        if(-not $porSetor.ContainsKey($key)){
            $porSetor[$key]=[pscustomobject]@{
                setor=$setor
                linhas=@()
                chefias=@{}
                grupos=@{}
                grupos_invalidos=@()
            }
        }
        $e=$porSetor[$key]
        $e.linhas=@($e.linhas)+[int]$x.origem_linha_excel

        $chef=([string]$x.grupo_chefia).Trim()
        if($chef){
            $ck=Get-ImportTextKey $chef
            if(-not $e.chefias.ContainsKey($ck)){ $e.chefias[$ck]=$chef }
        }

        $ga=Resolve-GrupoAnaliseImport ([string]$x.grupo_analise)
        if(-not $ga.vazio){
            if($ga.valido){
                $gk=[string]$ga.canonico
                if(-not $e.grupos.ContainsKey($gk)){ $e.grupos[$gk]=$gk }
            } else {
                $e.grupos_invalidos=@($e.grupos_invalidos)+[pscustomobject]@{
                    linha=[int]$x.origem_linha_excel
                    valor=[string]$ga.original
                }
            }
        }
    }

    $mapeamentos=@()
    $conflitos=@()
    $pendencias=@()

    foreach($key in @($porSetor.Keys | Sort-Object)){
        $e=$porSetor[$key]
        $chefias=@($e.chefias.Values)
        $grupos=@($e.grupos.Values)

        $bloqueiaChefia=$false
        $bloqueiaGrupo=$false
        $chefia=""
        $grupo=""

        if($chefias.Count -gt 1){
            $bloqueiaChefia=$true
            $conflitos += [pscustomobject]@{
                tipo="GRUPO DE CHEFIA"
                setor=[string]$e.setor
                detalhe=("A planilha informa mais de uma chefia para o mesmo setor: "+($chefias -join " | "))
                linhas=(@($e.linhas | Sort-Object -Unique) -join ", ")
            }
        } elseif($chefias.Count -eq 1){
            $chefia=[string]$chefias[0]
        } else {
            $pendencias += "Setor '$($e.setor)': Grupo de Chefia não informado."
        }

        if(@($e.grupos_invalidos).Count -gt 0){
            $bloqueiaGrupo=$true
            $det=@($e.grupos_invalidos | ForEach-Object {"linha $($_.linha): '$($_.valor)'"})
            $conflitos += [pscustomobject]@{
                tipo="GRUPO DE ANÁLISE"
                setor=[string]$e.setor
                detalhe=("Valor não reconhecido. Use ASSISTENCIAL, GERÊNCIA DE ENFERMAGEM ou DIRETORIA DE ENFERMAGEM. Encontrado: "+($det -join " | "))
                linhas=(@($e.linhas | Sort-Object -Unique) -join ", ")
            }
        } elseif($grupos.Count -gt 1){
            $bloqueiaGrupo=$true
            $conflitos += [pscustomobject]@{
                tipo="GRUPO DE ANÁLISE"
                setor=[string]$e.setor
                detalhe=("A planilha informa mais de um Grupo de Análise para o mesmo setor: "+($grupos -join " | "))
                linhas=(@($e.linhas | Sort-Object -Unique) -join ", ")
            }
        } elseif($grupos.Count -eq 1){
            $grupo=[string]$grupos[0]
        } else {
            $pendencias += "Setor '$($e.setor)': Grupo de Análise não informado; o cadastro atual será preservado."
        }

        $mapeamentos += [pscustomobject]@{
            setor=[string]$e.setor
            grupo_chefia=$chefia
            grupo_analise=$grupo
            bloqueia_chefia=[bool]$bloqueiaChefia
            bloqueia_grupo=[bool]$bloqueiaGrupo
        }
    }

    return [pscustomobject]@{
        mapeamentos=@($mapeamentos)
        conflitos=@($conflitos)
        pendencias=@($pendencias)
        linhas_sem_setor=@($linhasSemSetor)
    }
}

function Show-ImportCadastroProblems($plano,[bool]$silent){
    if($null -eq $plano){ return }
    $conflitos=@($plano.conflitos)
    $semSetor=@($plano.linhas_sem_setor)
    $pendencias=@($plano.pendencias)
    if($conflitos.Count -eq 0 -and $semSetor.Count -eq 0 -and $pendencias.Count -eq 0){ return }

    if($silent){
        Write-DiagLog ("Sincronização automática encontrou pendências de cadastro: conflitos=$($conflitos.Count), sem_setor=$($semSetor.Count), pendencias=$($pendencias.Count). Nenhuma associação conflitante foi aplicada silenciosamente.") "WARN"
        foreach($c in @($conflitos | Select-Object -First 10)){
            Write-DiagLog ("Conflito importação | tipo=$($c.tipo) | setor=$($c.setor) | $($c.detalhe) | linhas=$($c.linhas)") "WARN"
        }
        foreach($x in @($semSetor | Select-Object -First 10)){
            Write-DiagLog ("Pendência importação | linha=$($x.linha) | matrícula=$($x.matricula) | nome=$($x.nome) | SETOR NÃO INFORMADO") "WARN"
        }
        foreach($p in @($pendencias | Select-Object -First 10)){ Write-DiagLog ("Pendência importação | $p") "WARN" }
        return
    }

    $linhas=@()
    if($conflitos.Count -gt 0){
        $linhas += "CONFLITOS DE CADASTRO — as associações conflitantes NÃO serão aplicadas:"
        foreach($c in @($conflitos | Select-Object -First 15)){
            $linhas += "• $($c.tipo) | Setor: $($c.setor) | $($c.detalhe)"
        }
        if($conflitos.Count -gt 15){ $linhas += "... e mais $($conflitos.Count-15) conflito(s)." }
    }

    if($pendencias.Count -gt 0){
        if($linhas.Count -gt 0){ $linhas += "" }
        $linhas += "PENDÊNCIAS DE CADASTRO — o sistema preservará o que já estiver cadastrado:"
        foreach($p in @($pendencias | Select-Object -First 15)){ $linhas += "• $p" }
        if($pendencias.Count -gt 15){ $linhas += "... e mais $($pendencias.Count-15) pendência(s)." }
    }

    if($semSetor.Count -gt 0){
        if($linhas.Count -gt 0){ $linhas += "" }
        $linhas += "LINHAS SEM SETOR — período/opções podem ser importados, mas o vínculo de setor ficará pendente:"
        foreach($x in @($semSetor | Select-Object -First 10)){
            $linhas += "• Linha $($x.linha) | $($x.nome) | Matrícula $($x.matricula)"
        }
        if($semSetor.Count -gt 10){ $linhas += "... e mais $($semSetor.Count-10) linha(s)." }
    }

    [Windows.Forms.MessageBox]::Show(
        ($linhas -join "`r`n"),
        "Conferência — Setor / Chefia / Grupo de Análise",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

function Show-CadastroMappingDivergenciasDialog([array]$lista){
    if(@($lista).Count -eq 0){ return "MANTER" }

    $linhas=@()
    foreach($d in @($lista | Select-Object -First 18)){
        $alvo=if([string]$d.tipo -eq "SETOR DO SERVIDOR"){"$($d.nome) | Matrícula $($d.matricula)"}else{"Setor: $($d.setor)"}
        $linhas += "• $($d.tipo) | $alvo`r`n  Sistema: $($d.sistema)`r`n  Planilha: $($d.planilha)"
    }
    if(@($lista).Count -gt 18){ $linhas += "... e mais $(@($lista).Count-18) divergência(s)." }

    $msg="Foram encontradas $(@($lista).Count) divergência(s) entre os cadastros atuais e a nova planilha.`r`n`r`n"
    $msg += ($linhas -join "`r`n")
    $msg += "`r`n`r`nSIM = aplicar os dados da PLANILHA em todas as divergências acima."
    $msg += "`r`nNÃO = manter os cadastros atuais do SISTEMA."
    $msg += "`r`nCANCELAR = cancelar toda a sincronização sem gravar alterações."

    $resp=[Windows.Forms.MessageBox]::Show(
        $msg,
        "Conferência dos cadastros importados",
        [Windows.Forms.MessageBoxButtons]::YesNoCancel,
        [Windows.Forms.MessageBoxIcon]::Warning
    )
    if($resp -eq [Windows.Forms.DialogResult]::Yes){ return "APLICAR" }
    if($resp -eq [Windows.Forms.DialogResult]::No){ return "MANTER" }
    return "CANCELAR"
}

function Get-ImportOptionValidationDetails($item){
    $det=@()
    if($null -eq $item){ return @($det) }
    $aqFim=[string]$item.aquisitivo_fim
    $aqFimDt=Parse-Date $aqFim

    foreach($p in @(@(1,'1ª opção'),@(2,'2ª opção'),@(3,'3ª opção'))){
        $n=[int]$p[0]
        $rot=[string]$p[1]
        $op=$item.("opcao$n")
        if($null -eq $op -or [string]::IsNullOrWhiteSpace([string]$op.tipo)){ continue }

        $tipo=([string]$op.tipo).Trim().ToUpperInvariant()
        $s1=Parse-Date ([string]$op.inicio1)
        $e1=Parse-Date ([string]$op.fim1)
        $s2=Parse-Date ([string]$op.inicio2)
        $e2=Parse-Date ([string]$op.fim2)

        $segundoTotalmenteVazio=([string]::IsNullOrWhiteSpace([string]$op.inicio2) -and [string]::IsNullOrWhiteSpace([string]$op.fim2))
        $segundoParcial=([string]::IsNullOrWhiteSpace([string]$op.inicio2) -xor [string]::IsNullOrWhiteSpace([string]$op.fim2))

        if($tipo -eq '15+15 DIAS' -and $segundoTotalmenteVazio){
            $erroHard=$null
            if($null -eq $s1 -or $null -eq $e1){ $erroHard="${rot}: informe início e término do período de 15 dias." }
            elseif($e1 -lt $s1){ $erroHard="${rot}: término anterior ao início." }
            elseif($null -ne $aqFimDt -and $s1 -le $aqFimDt){
                $primeiraValida=$aqFimDt.AddDays(1).ToString("dd/MM/yyyy")
                $erroHard="${rot}: início inválido. O período aquisitivo termina em $($aqFimDt.ToString('dd/MM/yyyy')); as férias devem iniciar SOMENTE depois do vencimento. Primeira data válida: $primeiraValida."
            }
            elseif((($e1-$s1).Days+1) -ne 15){ $erroHard="${rot}: o período informado deve ter 15 dias." }

            $dados=@("Tipo: $([string]$op.tipo)")
            if($s1){$dados+="inicio1=$($s1.ToString('dd/MM/yyyy'))"}
            if($e1){$dados+="fim1=$($e1.ToString('dd/MM/yyyy'))"}

            if($erroHard){
                $cat=if($erroHard -match 'início inválido' -and $erroHard -match 'período aquisitivo'){"INÍCIO ANTES/IGUAL AO FIM DO AQUISITIVO"}else{"OPÇÃO INVÁLIDA"}
                $det += [pscustomobject]@{
                    opcao=$n; rotulo=$rot; erro=$erroHard; categoria=$cat
                    dados_opcao=($dados -join ' | '); severidade="ANULADO"; acao="CORRIGIR NA PLANILHA"
                    inicio1=[string]$op.inicio1; fim1=[string]$op.fim1; inicio2=[string]$op.inicio2; fim2=[string]$op.fim2
                }
            } else {
                # Novas escolhas: término do aquisitivo no mesmo ano do início da opção
                # não é prova de quinzena remanescente; exigir ambas as etapas.
                # Aquisição anterior: manter em conferência até verificar fixas/histórico.
                $mesmoAno=($null -ne $aqFimDt -and $null -ne $s1 -and $aqFimDt.Year -eq $s1.Year)
                if($mesmoAno){
                    $msg="${rot}: PROGRAMAÇÃO INCOMPLETA. Foi informada apenas uma quinzena de 15 dias (início $($s1.ToString('dd/MM/yyyy'))) para período aquisitivo encerrado em $($aqFimDt.ToString('dd/MM/yyyy')). Informe a segunda quinzena de 15 dias na MESMA opção da planilha. Se houver uma parcela anterior confirmada do mesmo período aquisitivo, confira-a com o RH antes de corrigir."
                    $categoria="FALTA SEGUNDA QUINZENA 15 DIAS"
                    $severidade="ANULADO"
                    $acao="PREENCHER 2ª QUINZENA NA PLANILHA / CONFERIR RH"
                } else {
                    $msg="${rot}: somente uma quinzena de 15 dias foi informada. O período aquisitivo pode corresponder a programação anterior, mas isso não está comprovado. Conferir Férias Fixas/Histórico pelo mesmo servidor e período aquisitivo; se não houver comprovação, preencher a outra quinzena na planilha."
                    $categoria="POSSÍVEL PARCELA REMANESCENTE 15 DIAS"
                    $severidade="PENDENTE"
                    $acao="CONFERIR FÉRIAS FIXAS / HISTÓRICO"
                }
                $det += [pscustomobject]@{
                    opcao=$n; rotulo=$rot; erro=$msg; categoria=$categoria
                    dados_opcao=($dados -join ' | '); severidade=$severidade; acao=$acao
                    inicio1=[string]$op.inicio1; fim1=[string]$op.fim1; inicio2=""; fim2=""
                }
            }
            continue
        }

        if($tipo -eq '15+15 DIAS' -and $segundoParcial){
            $msg="${rot}: o 2º período de 15 dias está parcialmente preenchido; informe início e término ou deixe ambos em branco para conferência como possível parcela remanescente."
            $det += [pscustomobject]@{
                opcao=$n; rotulo=$rot; erro=$msg; categoria="2º PERÍODO 15+15 PARCIAL"
                dados_opcao="Tipo: $([string]$op.tipo) | inicio1=$(Date-ToBR ([string]$op.inicio1)) | fim1=$(Date-ToBR ([string]$op.fim1)) | inicio2=$(Date-ToBR ([string]$op.inicio2)) | fim2=$(Date-ToBR ([string]$op.fim2))"
                severidade="ANULADO"; acao="COMPLETAR OU REMOVER 2º PERÍODO"
                inicio1=[string]$op.inicio1; fim1=[string]$op.fim1; inicio2=[string]$op.inicio2; fim2=[string]$op.fim2
            }
            continue
        }

        $e=Validate-Option $op $rot $aqFim
        if($e){
            $categoria=if(([string]$e) -match 'início inválido' -and ([string]$e) -match 'período aquisitivo'){
                "INÍCIO ANTES/IGUAL AO FIM DO AQUISITIVO"
            } elseif(([string]$e) -match '2º período de 15 dias' -or ([string]$e) -match '15 dias'){
                "OPÇÃO 15+15 INVÁLIDA"
            } else {
                "OPÇÃO INVÁLIDA"
            }
            $dados=@()
            if($op.PSObject.Properties['tipo']){ $dados += "Tipo: $([string]$op.tipo)" }
            foreach($prop in @('inicio1','fim1','inicio2','fim2')){
                if($op.PSObject.Properties[$prop]){
                    $v=[string]$op.$prop
                    if($v){ $dados += "$prop=$(Date-ToBR $v)" }
                }
            }
            $det += [pscustomobject]@{
                opcao=$n; rotulo=$rot; erro=[string]$e; categoria=$categoria
                dados_opcao=($dados -join ' | '); severidade="ANULADO"; acao="CORRIGIR NA PLANILHA"
                inicio1=[string]$op.inicio1; fim1=[string]$op.fim1; inicio2=[string]$op.inicio2; fim2=[string]$op.fim2
            }
        }
    }
    return @($det)
}

function Get-ImportOptionValidationErrors($item){
    return @(Get-ImportOptionValidationDetails $item | Where-Object { [string]$_.severidade -eq "ANULADO" } | ForEach-Object { [string]$_.erro })
}

function Get-ChaveAuditoriaImportacao($item,[int]$opcao){
    if($null -eq $item){ return "" }
    return "$(([string]$item.matricula).Trim())|$(([string]$item.aquisitivo_inicio).Trim())|$(([string]$item.aquisitivo_fim).Trim())|$opcao"
}

function Update-HistoricoLancamentosAnulados([array]$incoming,[array]$invalidos,[array]$pendencias,[string]$arquivo){
    if($null -eq $script:Config.importacao_lancamentos_anulados){
        $script:Config | Add-Member -NotePropertyName importacao_lancamentos_anulados -NotePropertyValue @() -Force
    }

    $agora=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $nomeArquivo=if($arquivo){[IO.Path]::GetFileName($arquivo)}else{""}
    $mutou=$false
    $atuais=@{}
    $linhasAtuais=@{}

    foreach($ix in @($incoming)){
        $chBase="$(([string]$ix.matricula).Trim())|$(([string]$ix.aquisitivo_inicio).Trim())|$(([string]$ix.aquisitivo_fim).Trim())"
        $linhasAtuais[$chBase]=$true
    }

    foreach($x in @($invalidos)){
        foreach($d in @($x.detalhes)){
            if([string]$d.severidade -ne "ANULADO"){ continue }
            $key="$(([string]$x.matricula).Trim())|$(([string]$x.aquisitivo_inicio).Trim())|$(([string]$x.aquisitivo_fim).Trim())|$([int]$d.opcao)"
            $atuais[$key]=$true
            # A mesma escolha ja confirmada nao deve originar outra ocorrencia.
            # Se os dados foram alterados, guarda-se a confirmacao historica e registra-se nova ocorrencia.
            $jaConfirmado=@($script:Config.importacao_lancamentos_anulados | Where-Object {
                [string]$_.chave -eq $key -and [string]$_.status -eq 'CONFIRMADO' -and
                [string]$_.inicio1 -eq [string]$d.inicio1 -and [string]$_.fim1 -eq [string]$d.fim1 -and
                [string]$_.inicio2 -eq [string]$d.inicio2 -and [string]$_.fim2 -eq [string]$d.fim2 -and
                [string]$_.dados_opcao -eq [string]$d.dados_opcao
            } | Select-Object -First 1)
            if($jaConfirmado.Count -gt 0){
                $jaConfirmado[0].ultima_ocorrencia=$agora
                $mutou=$true
                continue
            }
            $existente=$script:Config.importacao_lancamentos_anulados | Where-Object { [string]$_.chave -eq $key -and [string]$_.status -in @("ANULADO","PENDENTE","REVISAR") } | Select-Object -First 1
            if($null -eq $existente){
                $script:Config.importacao_lancamentos_anulados += [pscustomobject]@{
                    id=[guid]::NewGuid().ToString('N'); chave=$key; status="ANULADO"; linha=[int]$x.linha
                    matricula=[string]$x.matricula; nome=[string]$x.nome; aquisitivo_inicio=[string]$x.aquisitivo_inicio
                    aquisitivo_fim=[string]$x.aquisitivo_fim; opcao=[int]$d.opcao; dados_opcao=[string]$d.dados_opcao
                    categoria=[string]$d.categoria; motivo=[string]$d.erro; acao=[string]$d.acao
                    inicio1=[string]$d.inicio1; fim1=[string]$d.fim1; inicio2=[string]$d.inicio2; fim2=[string]$d.fim2
                    arquivo_origem=$nomeArquivo; primeira_ocorrencia=$agora; ultima_ocorrencia=$agora; corrigido_em=""; resolucao=""
                }
            } else {
                $existente.status="ANULADO"; $existente.linha=[int]$x.linha; $existente.nome=[string]$x.nome
                $existente.dados_opcao=[string]$d.dados_opcao; $existente.categoria=[string]$d.categoria
                $existente.motivo=[string]$d.erro; $existente.ultima_ocorrencia=$agora
                foreach($pr in @("acao","inicio1","fim1","inicio2","fim2")){
                    $val=[string]$d.$pr
                    if($null -eq $existente.PSObject.Properties[$pr]){ $existente | Add-Member -NotePropertyName $pr -NotePropertyValue $val -Force } else { $existente.$pr=$val }
                }
                if($nomeArquivo){$existente.arquivo_origem=$nomeArquivo}
            }
            $mutou=$true
        }
    }

    foreach($x in @($pendencias)){
        foreach($d in @($x.detalhes)){
            if([string]$d.severidade -ne "PENDENTE"){ continue }
            $key="$(([string]$x.matricula).Trim())|$(([string]$x.aquisitivo_inicio).Trim())|$(([string]$x.aquisitivo_fim).Trim())|$([int]$d.opcao)"
            $atuais[$key]=$true
            # A mesma escolha ja confirmada nao deve originar outra ocorrencia.
            # Se os dados foram alterados, guarda-se a confirmacao historica e registra-se nova ocorrencia.
            $jaConfirmado=@($script:Config.importacao_lancamentos_anulados | Where-Object {
                [string]$_.chave -eq $key -and [string]$_.status -eq 'CONFIRMADO' -and
                [string]$_.inicio1 -eq [string]$d.inicio1 -and [string]$_.fim1 -eq [string]$d.fim1 -and
                [string]$_.inicio2 -eq [string]$d.inicio2 -and [string]$_.fim2 -eq [string]$d.fim2 -and
                [string]$_.dados_opcao -eq [string]$d.dados_opcao
            } | Select-Object -First 1)
            if($jaConfirmado.Count -gt 0){
                $jaConfirmado[0].ultima_ocorrencia=$agora
                $mutou=$true
                continue
            }
            $existente=$script:Config.importacao_lancamentos_anulados | Where-Object { [string]$_.chave -eq $key -and [string]$_.status -in @("PENDENTE","REVISAR","ANULADO") } | Select-Object -First 1
            if($null -eq $existente){
                $script:Config.importacao_lancamentos_anulados += [pscustomobject]@{
                    id=[guid]::NewGuid().ToString('N'); chave=$key; status="PENDENTE"; linha=[int]$x.linha
                    matricula=[string]$x.matricula; nome=[string]$x.nome; aquisitivo_inicio=[string]$x.aquisitivo_inicio
                    aquisitivo_fim=[string]$x.aquisitivo_fim; opcao=[int]$d.opcao; dados_opcao=[string]$d.dados_opcao
                    categoria=[string]$d.categoria; motivo=[string]$d.erro; acao=[string]$d.acao
                    inicio1=[string]$d.inicio1; fim1=[string]$d.fim1; inicio2=[string]$d.inicio2; fim2=[string]$d.fim2
                    arquivo_origem=$nomeArquivo; primeira_ocorrencia=$agora; ultima_ocorrencia=$agora; corrigido_em=""; resolucao=""
                }
            } else {
                $existente.status="PENDENTE"; $existente.linha=[int]$x.linha; $existente.nome=[string]$x.nome
                $existente.dados_opcao=[string]$d.dados_opcao; $existente.categoria=[string]$d.categoria
                $existente.motivo=[string]$d.erro; $existente.ultima_ocorrencia=$agora
                foreach($pr in @("acao","inicio1","fim1","inicio2","fim2")){
                    $val=[string]$d.$pr
                    if($null -eq $existente.PSObject.Properties[$pr]){ $existente | Add-Member -NotePropertyName $pr -NotePropertyValue $val -Force } else { $existente.$pr=$val }
                }
                if($nomeArquivo){$existente.arquivo_origem=$nomeArquivo}
            }
            $mutou=$true
        }
    }

    foreach($h in @($script:Config.importacao_lancamentos_anulados)){
        if([string]$h.status -notin @("ANULADO","PENDENTE","REVISAR")){ continue }
        if($nomeArquivo -and [string]$h.arquivo_origem -and [string]$h.arquivo_origem -ne $nomeArquivo){ continue }
        $base="$(([string]$h.matricula).Trim())|$(([string]$h.aquisitivo_inicio).Trim())|$(([string]$h.aquisitivo_fim).Trim())"
        if($linhasAtuais.ContainsKey($base) -and -not $atuais.ContainsKey([string]$h.chave)){
            $h.status="CORRIGIDO"; $h.corrigido_em=$agora
            $h.resolucao="Corrigido ou retirado na planilha e confirmado em nova sincronização."
            $mutou=$true
        }
    }
    return $mutou
}

function Reconciliar-PendenciasImportacao15x15 {
    # A planilha oficial de FERIAS FIXAS e a referencia definitiva para intervalo
    # ja confirmado. A coincidencia precisa envolver matricula, aquisitivo e datas.
    # Esta conciliacao so trata a ausencia da 2a quinzena; nunca convalida
    # erros de datas, aquisitivo vencido, duracao ou outras inconsistencias.
    if($null -eq $script:Config.importacao_lancamentos_anulados){ return [pscustomobject]@{confirmados=0;revisar=0} }
    $confirmados=0; $revisar=0; $agora=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    foreach($h in @($script:Config.importacao_lancamentos_anulados)){
        $categoria=([string]$h.categoria).Trim()
        $isolada=($categoria -eq "POSSÍVEL PARCELA REMANESCENTE 15 DIAS" -or $categoria -eq "FALTA SEGUNDA QUINZENA 15 DIAS")
        if(-not $isolada){ continue }
        if([string]$h.status -notin @("PENDENTE","REVISAR","ANULADO","CONFIRMADO")){ continue }
        $ini=Parse-Date ([string]$h.inicio1); $fim=Parse-Date ([string]$h.fim1)
        if($null -eq $ini -or $null -eq $fim -or $fim -lt $ini -or (($fim-$ini).Days+1) -ne 15){ continue }
        $aqIni=Parse-Date ([string]$h.aquisitivo_inicio)
        $aqFim=Parse-Date ([string]$h.aquisitivo_fim)
        if($null -eq $aqIni -or $null -eq $aqFim -or $ini -le $aqFim){ continue }

        # Somente registros expressamente identificados como FIXOS IMPORTADOS.
        # Nao basta existir outro registro do mesmo servidor ou ano.
        $fixa=@($script:Records | Where-Object {
            $rec=$_
            ([string]$rec.matricula).Trim() -eq ([string]$h.matricula).Trim() -and
            (Test-RegistroFixoImportado $rec) -and
            -not [string]::IsNullOrWhiteSpace([string]$rec.fixo_arquivo_origem) -and
            ($null -ne (Parse-Date ([string]$rec.aquisitivo_inicio))) -and
            ($null -ne (Parse-Date ([string]$rec.aquisitivo_fim))) -and
            (Parse-Date ([string]$rec.aquisitivo_inicio)).Date -eq $aqIni.Date -and
            (Parse-Date ([string]$rec.aquisitivo_fim)).Date -eq $aqFim.Date
        } | Where-Object {
            $fi=Parse-Date ([string]$_.fixo_inicio); $ff=Parse-Date ([string]$_.fixo_fim)
            $null -ne $fi -and $null -ne $ff -and $fi.Date -eq $ini.Date -and $ff.Date -eq $fim.Date
        } | Select-Object -First 1)

        if($fixa.Count -gt 0){
            if([string]$h.status -ne "CONFIRMADO"){$confirmados++}
            $h.status="CONFIRMADO"
            if(-not [string]$h.corrigido_em){$h.corrigido_em=$agora}
            $h.resolucao="CONFIRMADO PELO RH - FERIAS FIXAS. Matricula, periodo aquisitivo e datas da quinzena coincidem exatamente com a planilha oficial importada ($([string]$fixa[0].fixo_arquivo_origem)). O compromisso FIXO ja esta contabilizado; nao lancar novamente esta mesma quinzena como escolha."
            continue
        }

        # Se uma fixa deixou de existir, a confirmacao anterior nao e prova atual.
        if([string]$h.status -eq "CONFIRMADO" -and ([string]$h.resolucao -match '^CONFIRMADO PELO RH - FERIAS FIXAS')){
            if($categoria -eq "FALTA SEGUNDA QUINZENA 15 DIAS"){$h.status="ANULADO"}else{$h.status="REVISAR"}
            $h.corrigido_em=""
            $h.resolucao="A confirmacao anterior nao foi encontrada nas FERIAS FIXAS atuais. Revisar manualmente a correspondencia antes de aprovar."
        }

        # Registro de escolha no mesmo ano, sem fixa correspondente: falta quinzena.
        if($categoria -eq "FALTA SEGUNDA QUINZENA 15 DIAS"){ continue }

        # Historico e evidencia auxiliar apenas para parcelas de periodo anterior.
        $hist=@($script:HistoricoFerias | Where-Object {
            ([string]$_.matricula).Trim() -eq ([string]$h.matricula).Trim() -and
            [string]$_.aquisitivo_inicio -eq [string]$h.aquisitivo_inicio -and
            [string]$_.aquisitivo_fim -eq [string]$h.aquisitivo_fim -and [int]$_.dias -eq 15
        } | Where-Object {
            $hf=Parse-Date ([string]$_.fim)
            $null -ne $hf -and $hf.Date -lt $ini.Date
        } | Select-Object -First 1)
        if($hist.Count -gt 0){
            if([string]$h.status -ne "CONFIRMADO"){$confirmados++}
            $h.status="CONFIRMADO"
            if(-not [string]$h.corrigido_em){$h.corrigido_em=$agora}
            $h.resolucao="Parcela remanescente comprovada pelo HISTORICO: etapa anterior de 15 dias do mesmo servidor e periodo aquisitivo. Conferir antes da aprovacao definitiva."
            continue
        }
        if([bool]$script:Config.ferias_fixas_2027_importadas -and [bool]$script:Config.historico_3_anos_importado){
            if([string]$h.status -ne "REVISAR"){$h.status="REVISAR";$revisar++}
            $h.resolucao="Fixas e historico importados, sem coincidencia suficiente para confirmar. Requer conferencia manual."
        }
    }
    return [pscustomobject]@{confirmados=$confirmados;revisar=$revisar}
}

function Abrir-HistoricoLancamentosAnulados {
    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Central de inconsistências / pendências da importação"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(1220,700)
    $dlg.MinimumSize=New-Object Drawing.Size(980,560)
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)
    $dlg.AutoScaleMode=[Windows.Forms.AutoScaleMode]::Dpi

    $top=New-Object Windows.Forms.Panel
    $top.Dock="Top"; $top.Height=138
    $dlg.Controls.Add($top)

    $top.Controls.Add((New-Label "Pesquisar por matrícula, nome ou motivo" 12 8 280 20))
    $txt=New-TextBox 12 30 340; $top.Controls.Add($txt)
    $top.Controls.Add((New-Label "Situação" 370 8 90 20))
    $cmb=New-Combo 370 30 150
    @("ATIVAS","TODOS / HISTÓRICO","ANULADO","PENDENTE","REVISAR","CONFIRMADO","CORRIGIDO") | ForEach-Object {[void]$cmb.Items.Add($_)}
    $cmb.SelectedIndex=0; $top.Controls.Add($cmb)

    $top.Controls.Add((New-Label "Setor" 12 77 100 20))
    $cmbSetor=New-Combo 12 98 250
    [void]$cmbSetor.Items.Add("TODOS")
    $cmbSetor.SelectedIndex=0
    $top.Controls.Add($cmbSetor)
    $top.Controls.Add((New-Label "Chefia responsável" 277 77 155 20))
    $cmbChefia=New-Combo 277 98 250
    [void]$cmbChefia.Items.Add("TODAS")
    $cmbChefia.SelectedIndex=0
    $top.Controls.Add($cmbChefia)
    $top.Controls.Add((New-Label "Tipo de inconsistência" 542 77 190 20))
    $cmbTipo=New-Combo 542 98 245
    [void]$cmbTipo.Items.Add("TODOS")
    $cmbTipo.SelectedIndex=0
    $top.Controls.Add($cmbTipo)

    $lblResumo=New-Object Windows.Forms.Label
    $lblResumo.Location=New-Object Drawing.Point(545,30)
    $lblResumo.Size=New-Object Drawing.Size(640,30)
    $lblResumo.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $top.Controls.Add($lblResumo)

    $g=New-Object Windows.Forms.DataGridView
    $g.Dock="Fill"; $g.ReadOnly=$true; $g.AllowUserToAddRows=$false; $g.AllowUserToDeleteRows=$false
    $g.RowHeadersVisible=$false; $g.SelectionMode="FullRowSelect"; $g.MultiSelect=$false
    $g.AutoSizeColumnsMode="Fill"; $g.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(
        @("sit","Situação"),@("data","Última ocorrência"),@("linha","Linha"),@("mat","Matrícula"),
        @("nome","Nome"),@("setor","Setor"),@("chefia","Chefia responsável"),@("aq","Período aquisitivo"),@("op","Opção"),@("cat","Tipo de inconsistência"),@("dados","Dados informados"),
        @("motivo","Motivo / análise"),@("arquivo","Arquivo"),@("corr","Corrigido em")
    )){ [void]$g.Columns.Add($c[0],$c[1]) }
    $g.Columns["sit"].FillWeight=10; $g.Columns["data"].FillWeight=14; $g.Columns["linha"].FillWeight=6
    $g.Columns["mat"].FillWeight=10; $g.Columns["nome"].FillWeight=20; $g.Columns["aq"].FillWeight=17
    $g.Columns["op"].FillWeight=7; $g.Columns["cat"].FillWeight=22; $g.Columns["dados"].FillWeight=24; $g.Columns["motivo"].FillWeight=38
    $g.Columns["arquivo"].FillWeight=18; $g.Columns["corr"].FillWeight=14
    $g.Columns["setor"].FillWeight=17; $g.Columns["chefia"].FillWeight=24
    $g.AutoSizeColumnsMode=[Windows.Forms.DataGridViewAutoSizeColumnsMode]::None
    foreach($col in $g.Columns){ $col.Width=115 }
    $g.Columns["nome"].Width=185; $g.Columns["setor"].Width=160; $g.Columns["chefia"].Width=215
    $g.Columns["motivo"].Width=320; $g.Columns["dados"].Width=270; $g.Columns["cat"].Width=180
    $g.Columns["aq"].Width=190; $g.Columns["mat"].Width=100; $g.Columns["linha"].Width=60
    $g.Columns["op"].Width=65; $g.Columns["sit"].Width=95
    $dlg.Controls.Add($g); $g.BringToFront()

    $bottom=New-Object Windows.Forms.Panel
    $bottom.Dock="Bottom"; $bottom.Height=62
    $dlg.Controls.Add($bottom); $bottom.BringToFront()
    $btnCsv=New-Button "Exportar Excel (CSV)" 12 12 180 34
    $bottom.Controls.Add($btnCsv)
    $btnHtml=New-Button "Relatório por setor (HTML/PDF)" 205 12 235 34
    $bottom.Controls.Add($btnHtml)
    $btnFechar=New-Button "Fechar" 1060 12 120 32
    $btnFechar.Anchor="Top,Right"; $bottom.Controls.Add($btnFechar)

    # V1.0.58: GetNewClosure() cria um novo escopo de script. Portanto, não usar
    # $script:Config dentro da closure, pois ele apontaria para o módulo interno
    # da closure e a grade pareceria vazia mesmo com histórico gravado.
    # Captura-se explicitamente a coleção real antes de criar os eventos.
    $historicoAnuladosRef=@($script:Config.importacao_lancamentos_anulados)
    # Usar cadastro existente, nunca dados de setor/chefia vindos da planilha de inconsistências.
    $cadastroPorMat=@{}
    foreach($rec in @($script:Records)){
        $mat=([string]$rec.matricula).Trim()
        if(-not $mat){ continue }
        $setorRec=([string]$rec.setor).Trim()
        $chefiaRec=([string](Get-GrupoChefiaEfetivaRegistro $rec)).Trim()
        if(-not $cadastroPorMat.ContainsKey($mat)){
            $cadastroPorMat[$mat]=[pscustomobject]@{Setor=$setorRec;Chefia=$chefiaRec}
        } elseif(-not $cadastroPorMat[$mat].Setor -and $setorRec){
            $cadastroPorMat[$mat]=[pscustomobject]@{Setor=$setorRec;Chefia=$chefiaRec}
        }
    }
    $localizarVinculo={
        param($h)
        $mat=([string]$h.matricula).Trim()
        if($cadastroPorMat.ContainsKey($mat)){
            $c=$cadastroPorMat[$mat]
            $s=if($c.Setor){[string]$c.Setor}else{'SETOR NÃO INFORMADO'}
            $ch=if($c.Chefia){[string]$c.Chefia}else{'CHEFIA NÃO VINCULADA'}
            return [pscustomobject]@{Setor=$s;Chefia=$ch}
        }
        return [pscustomobject]@{Setor='NÃO CADASTRADO';Chefia='NÃO CADASTRADO'}
    }.GetNewClosure()
    # Coleção derivada somente para a apresentação e a exportação, sem gravar na base.
    $registrosExibidos=New-Object System.Collections.ArrayList
    foreach($h in $historicoAnuladosRef){
        $c=&$localizarVinculo $h
        if(-not $cmbSetor.Items.Contains($c.Setor)){[void]$cmbSetor.Items.Add($c.Setor)}
        if(-not $cmbChefia.Items.Contains($c.Chefia)){[void]$cmbChefia.Items.Add($c.Chefia)}
        $tipo=if($h.categoria){[string]$h.categoria}else{'OPÇÃO INVÁLIDA'}
        if(-not $cmbTipo.Items.Contains($tipo)){[void]$cmbTipo.Items.Add($tipo)}
    }

    # V1.0.58: formatador LOCAL e independente de funções globais.
    # A janela usa GetNewClosure(); por isso Date-ToBR/Parse-Date não devem ser
    # chamados de dentro da closure, pois podem não existir naquele escopo.
    $formatarDataBR={
        param([string]$valor)
        if([string]::IsNullOrWhiteSpace($valor)){ return "" }
        $dt=[datetime]::MinValue
        $cult=[Globalization.CultureInfo]::InvariantCulture
        if([datetime]::TryParseExact($valor.Trim(),@("yyyy-MM-dd","dd/MM/yyyy","yyyy-MM-ddTHH:mm:ss"),$cult,[Globalization.DateTimeStyles]::None,[ref]$dt)){
            return $dt.ToString("dd/MM/yyyy")
        }
        if([datetime]::TryParse($valor,[Globalization.CultureInfo]::CurrentCulture,[Globalization.DateTimeStyles]::None,[ref]$dt)){
            return $dt.ToString("dd/MM/yyyy")
        }
        return $valor
    }.GetNewClosure()

    $refresh={
        $g.Rows.Clear()
        $q=$txt.Text.Trim().ToUpperInvariant()
        $sit=if($cmb.SelectedItem){[string]$cmb.SelectedItem}else{"TODOS"}
        $setorFiltro=[string]$cmbSetor.SelectedItem
        $chefiaFiltro=[string]$cmbChefia.SelectedItem
        $tipoFiltro=[string]$cmbTipo.SelectedItem
        $registrosExibidos.Clear()
        # Consolidacao apenas da visualizacao: a base e a trilha de auditoria permanecem intactas.
        # Mesmo servidor, aquisitivo, opcao, datas e status = uma linha operacional.
        $todos=@($historicoAnuladosRef | Sort-Object ultima_ocorrencia -Descending | Group-Object -Property {
            "$([string]$_.chave)|$([string]$_.inicio1)|$([string]$_.fim1)|$([string]$_.inicio2)|$([string]$_.fim2)|$([string]$_.status)"
        } | ForEach-Object { $_.Group | Select-Object -First 1 })
        $anulados=0; $pendentes=0; $revisar=0; $confirmados=0; $corrigidos=0; $exib=0
        foreach($h in @($todos | Sort-Object ultima_ocorrencia -Descending)){
            switch([string]$h.status){
                "ANULADO"{$anulados++}
                "PENDENTE"{$pendentes++}
                "REVISAR"{$revisar++}
                "CONFIRMADO"{$confirmados++}
                "CORRIGIDO"{$corrigidos++}
            }
            if($sit -eq "ATIVAS" -and [string]$h.status -notin @("PENDENTE","REVISAR")){continue}
            if($sit -notin @("ATIVAS","TODOS / HISTÓRICO") -and [string]$h.status -ne $sit){ continue }
            $vinculo=&$localizarVinculo $h
            $tipoAtual=if($h.categoria){[string]$h.categoria}else{'OPÇÃO INVÁLIDA'}
            if($setorFiltro -and $setorFiltro -ne 'TODOS' -and $vinculo.Setor -ne $setorFiltro){continue}
            if($chefiaFiltro -and $chefiaFiltro -ne 'TODAS' -and $vinculo.Chefia -ne $chefiaFiltro){continue}
            if($tipoFiltro -and $tipoFiltro -ne 'TODOS' -and $tipoAtual -ne $tipoFiltro){continue}
            $hay=("$([string]$h.matricula) $([string]$h.nome) $([string]$h.categoria) $([string]$h.motivo) $([string]$h.arquivo_origem)").ToUpperInvariant()
            if($q -and $hay -notlike "*$q*"){ continue }
            $ai=&$formatarDataBR ([string]$h.aquisitivo_inicio); $af=&$formatarDataBR ([string]$h.aquisitivo_fim)
            $aq=if($ai -and $af){"$ai a $af"}else{"Não informado"}
            $i=$g.Rows.Add()
            $r=$g.Rows[$i]
            # Mantem referencia ao registro completo para o diagnostico em duplo clique.
            $r.Tag=$h
            $r.Cells["sit"].Value=[string]$h.status
            $r.Cells["data"].Value=[string]$h.ultima_ocorrencia
            $r.Cells["linha"].Value=[int]$h.linha
            $r.Cells["mat"].Value=[string]$h.matricula
            $r.Cells["nome"].Value=[string]$h.nome
            $r.Cells["setor"].Value=$vinculo.Setor
            $r.Cells["chefia"].Value=$vinculo.Chefia
            $r.Cells["aq"].Value=$aq
            $r.Cells["op"].Value="$([int]$h.opcao)ª"
            $r.Cells["cat"].Value=if($null -ne $h.PSObject.Properties['categoria']){[string]$h.categoria}else{"OPÇÃO INVÁLIDA"}
            $r.Cells["dados"].Value=[string]$h.dados_opcao
            $r.Cells["motivo"].Value=[string]$h.motivo
            $r.Cells["arquivo"].Value=[string]$h.arquivo_origem
            $r.Cells["corr"].Value=[string]$h.corrigido_em
            switch([string]$h.status){
                "ANULADO" { $r.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose; $r.DefaultCellStyle.ForeColor=[Drawing.Color]::DarkRed }
                "PENDENTE" { $r.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,248,220); $r.DefaultCellStyle.ForeColor=[Drawing.Color]::DarkGoldenrod }
                "REVISAR" { $r.DefaultCellStyle.BackColor=[Drawing.Color]::PeachPuff; $r.DefaultCellStyle.ForeColor=[Drawing.Color]::DarkOrange }
                default { $r.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218); $r.DefaultCellStyle.ForeColor=[Drawing.Color]::DarkGreen }
            }
            $r.Cells["motivo"].ToolTipText=[string]$h.motivo
            $r.Cells["dados"].ToolTipText=[string]$h.dados_opcao
            [void]$registrosExibidos.Add([pscustomobject]@{
                Situacao=[string]$h.status;Setor=$vinculo.Setor;Chefia=$vinculo.Chefia;
                Matricula=[string]$h.matricula;Nome=[string]$h.nome;PeriodoAquisitivo=$aq;
                Opcao="$([int]$h.opcao)ª";Tipo=$tipoAtual;Motivo=[string]$h.motivo;
                Dados=[string]$h.dados_opcao;Linha=[int]$h.linha;Arquivo=[string]$h.arquivo_origem;
                Chave=[string]$h.chave;Id=[string]$h.id;PrimeiraOcorrencia=[string]$h.primeira_ocorrencia;
                UltimaOcorrencia=[string]$h.ultima_ocorrencia;Resolucao=[string]$h.resolucao
            })
            $exib++
        }
        $ocorrenciasArquivadas=@($historicoAnuladosRef).Count-$todos.Count
        $lblResumo.Text="Anulados: $anulados | Pendentes: $pendentes | Revisar: $revisar | Confirmados: $confirmados | Corrigidos: $corrigidos | Exibidos: $exib | Repeticoes no historico: $ocorrenciasArquivadas"
    }.GetNewClosure()

    # V1.0.81 - Diagnostico detalhado, sem editar ou gravar dados.
    $abrirDetalhe={
        param($linha)
        if($null -eq $linha -or $null -eq $linha.Tag){return}
        $h=$linha.Tag
        $situacao=[string]$h.status
        $nome=[string]$h.nome
        $mat=[string]$h.matricula
        $linhaExcel=[string]$h.linha
        $op=if([int]$h.opcao -ge 1 -and [int]$h.opcao -le 3){"$([int]$h.opcao)ª opção"}else{"Não informada"}
        $ai=&$formatarDataBR ([string]$h.aquisitivo_inicio)
        $af=&$formatarDataBR ([string]$h.aquisitivo_fim)
        $categoria=[string]$h.categoria
        $motivo=[string]$h.motivo
        $dados=[string]$h.dados_opcao
        $resolucao=[string]$h.resolucao
        $arquivo=[string]$h.arquivo_origem
        $orientacao=switch -Regex ($categoria+' '+$motivo){
            'ANTES/IGUAL|anterior ou igual|in[ií]cio inv[aá]lido' { 'Confira a data inicial da opção: ela deve ser POSTERIOR ao término do período aquisitivo. Corrija a planilha original e importe novamente.'; break }
            '15\+15|PARCEL|quinzena|15 dias' { 'Confira se existem duas etapas de 15 dias para o mesmo período aquisitivo ou se há comprovação de etapa anterior em férias fixas/histórico. Não confirme sem evidência.'; break }
            default { 'Confira o motivo completo abaixo, corrija a origem dos dados e execute novamente a conferência da importação.' }
        }
        $detalhes=@(
            "SERVIDOR: $nome"
            "MATRÍCULA: $mat"
            "SITUAÇÃO: $situacao    |    LINHA EXCEL: $linhaExcel    |    $op"
            "PERÍODO AQUISITIVO: $ai a $af"
            ''
            'TIPO DE INCONSISTÊNCIA:'
            $categoria
            ''
            'MOTIVO COMPLETO:'
            $motivo
            ''
            'DADOS INFORMADOS NA PLANILHA:'
            $dados
            ''
            'ORIENTAÇÃO:'
            $orientacao
        )
        if(-not [string]::IsNullOrWhiteSpace($resolucao)){$detalhes+=@('','REGISTRO DE CONFERÊNCIA:',$resolucao)}
        $detalhes+=@('','ARQUIVO DE ORIGEM:',$arquivo)
        $janela=New-Object Windows.Forms.Form
        $janela.Text='Diagnóstico da inconsistência - Férias DCE'
        $janela.StartPosition='CenterParent'
        $janela.Size=New-Object Drawing.Size(780,560)
        $janela.MinimumSize=New-Object Drawing.Size(590,400)
        $janela.Font=New-Object Drawing.Font('Segoe UI',10)
        $area=New-Object Windows.Forms.TextBox
        $area.Dock='Fill'; $area.Multiline=$true; $area.ReadOnly=$true
        $area.ScrollBars='Vertical'; $area.WordWrap=$true
        $area.BackColor=[Drawing.Color]::White
        $area.Text=$detalhes -join "`r`n"
        $janela.Controls.Add($area)
        $rodape=New-Object Windows.Forms.Panel
        $rodape.Dock='Bottom'; $rodape.Height=52
        $janela.Controls.Add($rodape); $rodape.BringToFront()
        $fechar=New-Object Windows.Forms.Button
        $fechar.Text='Fechar'; $fechar.Size=New-Object Drawing.Size(110,32)
        $fechar.Location=New-Object Drawing.Point(640,10)
        $fechar.Anchor='Top,Right'
        $rodape.Controls.Add($fechar)
        $fechar.Add_Click({$janela.Close()})
        [void]$janela.ShowDialog($dlg)
        $janela.Dispose()
    }.GetNewClosure()
    $g.add_CellDoubleClick({
        param($sender,$e)
        if($e.RowIndex -ge 0 -and $e.RowIndex -lt $g.Rows.Count){
            & $abrirDetalhe $g.Rows[$e.RowIndex]
        }
    }.GetNewClosure())
    $g.add_KeyDown({
        param($sender,$e)
        if($e.KeyCode -eq [Windows.Forms.Keys]::Enter -and $g.CurrentRow){
            $e.Handled=$true; $e.SuppressKeyPress=$true
            & $abrirDetalhe $g.CurrentRow
        }
    }.GetNewClosure())
    $btnCsv.add_Click({
        if($registrosExibidos.Count -eq 0){[Windows.Forms.MessageBox]::Show('Não existem registros nos filtros atuais.','Férias DCE')|Out-Null;return}
        $dialogo=New-Object Windows.Forms.SaveFileDialog
        $dialogo.Filter='Planilha CSV (*.csv)|*.csv'
        $dialogo.FileName='Inconsistencias_Ferias_2027.csv'
        if($dialogo.ShowDialog($dlg) -ne [Windows.Forms.DialogResult]::OK){return}
        try{
            $registrosExibidos | Select-Object Situacao,Setor,Chefia,Matricula,Nome,PeriodoAquisitivo,Opcao,Tipo,Motivo,Dados,Linha,Arquivo,Chave,Id,PrimeiraOcorrencia,UltimaOcorrencia,Resolucao | Export-Csv -LiteralPath $dialogo.FileName -NoTypeInformation -Delimiter ';' -Encoding UTF8
            [Windows.Forms.MessageBox]::Show('Relatório exportado com sucesso.','Férias DCE')|Out-Null
        }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Falha ao exportar')|Out-Null}
    }.GetNewClosure())
    $btnHtml.add_Click({
        # Exportar TUDO o que a Central está mostrando, inclusive CONFIRMADO e CORRIGIDO.
        # Não restringir artificialmente a exportação a pendências.
        $itensRelatorio=@($registrosExibidos)
        if($itensRelatorio.Count -eq 0){
            $respVazio=[Windows.Forms.MessageBox]::Show('Não há registros nos filtros atuais. Deseja gerar o relatório HTML vazio, com os filtros disponíveis?','Férias DCE',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
            if($respVazio -ne [Windows.Forms.DialogResult]::Yes){return}
        }
        $dialogo=New-Object Windows.Forms.SaveFileDialog
        $dialogo.Filter='Relatório HTML (imprimir ou salvar em PDF)|*.html'
        $dialogo.FileName='Conferencia_Ferias_2027_por_Setor.html'
        if($dialogo.ShowDialog($dlg) -ne [Windows.Forms.DialogResult]::OK){return}
        try {
            $encode={param($v) [System.Net.WebUtility]::HtmlEncode([string]$v)}
            $sb=New-Object System.Text.StringBuilder
            [void]$sb.AppendLine(@'
<!doctype html>
<html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Conferência de Férias DCE</title>
<style>
:root{font-family:Segoe UI,Arial,sans-serif;color:#23384c;background:#f4f7fa}
body{margin:0;padding:24px;max-width:1600px;margin:auto}
header{border-bottom:3px solid #27537b;margin-bottom:16px;padding-bottom:14px}
h1{font-size:22px;margin:0 0 8px}p{line-height:1.4}h2{font-size:16px;background:#e6eff8;padding:10px 12px;border-radius:4px;margin:22px 0 0}
.filtros{display:flex;flex-wrap:wrap;align-items:end;gap:12px;padding:15px;background:#fff;border:1px solid #dae2e9;border-radius:7px;margin-bottom:12px}
.campo{display:flex;flex-direction:column;gap:5px}.campo label{font-weight:600;font-size:12px}
select,input{min-width:155px;padding:9px 10px;border:1px solid #aabac9;border-radius:4px;background:white;font:inherit}
input{min-width:260px}button{background:#27537b;color:white;padding:10px 15px;border:0;border-radius:4px;cursor:pointer;font:inherit}
button.secundario{background:#e7ecf2;color:#24415c}
.resumo{font-weight:600;margin:10px 0;color:#385d7d}
section.grupo{background:white;margin:16px 0;border:1px solid #d6dfe8;border-radius:5px;overflow:hidden}
table{border-collapse:collapse;width:100%;font-size:12px}th,td{border:1px solid #cfdae4;padding:8px;text-align:left;vertical-align:top;overflow-wrap:anywhere}
th{background:#f0f4f8}tbody tr:nth-child(even){background:#f9fbfd}
.rodape{margin-top:25px;font-size:12px;color:#526579}
@page{size:A4 landscape;margin:11mm}
@media print{body{padding:0;max-width:none;background:white}.filtros,.resumo{display:none!important}[hidden]{display:none!important}section.grupo{break-inside:avoid}tr{break-inside:avoid}h2{break-after:avoid}button{display:none} }
</style></head><body>
'@)
            [void]$sb.AppendLine('<header><h1>Diretoria de Enfermagem — Conferência da Programação de Férias 2027</h1><p>Relatório de auditoria com todos os registros selecionados na Central, incluindo confirmados, corrigidos e pendências. Emitido em '+(Get-Date -Format 'dd/MM/yyyy HH:mm')+'.</p></header>')
            [void]$sb.AppendLine(@'
<div class="filtros" id="filtros">
  <div class="campo"><label for="filChefia">Chefia</label><select id="filChefia"><option value="">Todas</option></select></div>
  <div class="campo"><label for="filSetor">Setor</label><select id="filSetor"><option value="">Todos</option></select></div>
  <div class="campo"><label for="filSituacao">Situação</label><select id="filSituacao"><option value="">Todas</option></select></div>
  <div class="campo"><label for="filBusca">Pesquisar servidor ou matrícula</label><input id="filBusca" placeholder="Digite nome ou matrícula"></div>
  <button class="secundario" type="button" id="limpar">Limpar filtros</button>
  <button type="button" onclick="window.print()">Imprimir / Salvar PDF</button>
</div><p class="resumo" id="resumo" aria-live="polite"></p>
'@)
            foreach($grupo in @($itensRelatorio | Group-Object Chefia,Setor | Sort-Object Name)){
                $primeiro=$grupo.Group[0]
                [void]$sb.AppendLine('<section class="grupo"><h2>Chefia: '+(& $encode $primeiro.Chefia)+' | Setor: '+(& $encode $primeiro.Setor)+'</h2>')
                [void]$sb.AppendLine('<table><thead><tr><th>Matrícula</th><th>Servidor</th><th>Aquisitivo</th><th>Opção</th><th>Situação</th><th>Motivo / análise</th><th>Resolução / confirmação</th><th>Última ocorrência</th></tr></thead><tbody>')
                foreach($item in $grupo.Group){
                    $attrs=' data-chefia="'+(& $encode $item.Chefia)+'" data-setor="'+(& $encode $item.Setor)+'" data-situacao="'+(& $encode $item.Situacao)+'"'
                    [void]$sb.AppendLine('<tr'+$attrs+'><td>'+(& $encode $item.Matricula)+'</td><td>'+(& $encode $item.Nome)+'</td><td>'+(& $encode $item.PeriodoAquisitivo)+'</td><td>'+(& $encode $item.Opcao)+'</td><td>'+(& $encode $item.Situacao)+'</td><td>'+(& $encode $item.Motivo)+'</td><td>'+(& $encode $item.Resolucao)+'</td><td>'+(& $encode $item.UltimaOcorrencia)+'</td></tr>')
                }
                [void]$sb.AppendLine('</tbody></table></section>')
            }
            [void]$sb.AppendLine(@'
<p class="rodape">Registros confirmados são mantidos para auditoria; os anulados, pendentes e em revisão podem exigir providências. Esta página não altera decisões ou dados do sistema.</p>
<script>
(() => {
 const rows=[...document.querySelectorAll('tbody tr')], sections=[...document.querySelectorAll('section.grupo')];
 const chefia=document.getElementById('filChefia'),setor=document.getElementById('filSetor'),situacao=document.getElementById('filSituacao'),busca=document.getElementById('filBusca');
 const norm=v=>(v||'').toLocaleLowerCase('pt-BR').normalize('NFD').replace(/[\u0300-\u036f]/g,'');
 function populate(el,key){const vals=[...new Set(rows.map(r=>r.dataset[key]).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'pt-BR'));for(const v of vals){const op=document.createElement('option');op.value=v;op.textContent=v;el.add(op);}}
 populate(chefia,'chefia');populate(setor,'setor');populate(situacao,'situacao');
 function update(){let count=0;for(const row of rows){const ok=(!chefia.value||row.dataset.chefia===chefia.value)&&(!setor.value||row.dataset.setor===setor.value)&&(!situacao.value||row.dataset.situacao===situacao.value)&&(!busca.value||norm(row.textContent).includes(norm(busca.value)));row.hidden=!ok;if(ok)count++;}
 for(const s of sections){s.hidden=![...s.querySelectorAll('tbody tr')].some(r=>!r.hidden);}
 document.getElementById('resumo').textContent=count+' registro(s) exibido(s) de '+rows.length+' no relatório. A impressão respeita estes filtros.';
 }
 for(const el of [chefia,setor,situacao])el.addEventListener('change',update);
 busca.addEventListener('input',update);
 document.getElementById('limpar').addEventListener('click',()=>{chefia.value='';setor.value='';situacao.value='';busca.value='';update();});
 update();
})();
</script></body></html>
'@)
            [IO.File]::WriteAllText($dialogo.FileName,$sb.ToString(),[Text.UTF8Encoding]::new($true))
            try{
                Start-Process -FilePath $dialogo.FileName -ErrorAction Stop
            }catch{
                $resposta=[Windows.Forms.MessageBox]::Show("Relatório salvo, mas não foi possível abrir automaticamente no navegador.`r`n`r`nDeseja tentar abrir agora?",'Férias DCE',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
                if($resposta -eq [Windows.Forms.DialogResult]::Yes){try{[Diagnostics.Process]::Start($dialogo.FileName)|Out-Null}catch{[Windows.Forms.MessageBox]::Show('Abra manualmente o arquivo: '+$dialogo.FileName,'Férias DCE')|Out-Null}}
            }
        }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Falha ao gerar relatório')|Out-Null}
    }.GetNewClosure())
    $cmbSetor.add_SelectedIndexChanged({&$refresh}.GetNewClosure())
    $cmbChefia.add_SelectedIndexChanged({&$refresh}.GetNewClosure())
    $cmbTipo.add_SelectedIndexChanged({&$refresh}.GetNewClosure())
    $txt.add_TextChanged({&$refresh}.GetNewClosure())
    $cmb.add_SelectedIndexChanged({&$refresh}.GetNewClosure())
    $btnFechar.add_Click({$dlg.Close()})
    &$refresh
    [void]$dlg.ShowDialog($form)
}

function Show-ImportInvalidOptions([array]$itens,[bool]$silent){
    if(@($itens).Count -eq 0){ return }
    $linhas=@()
    foreach($x in @($itens | Select-Object -First 20)){
        $linhas += "Linha $($x.linha) | $($x.nome) | Matrícula $($x.matricula) | Aquisitivo termina em $(Date-ToBR ([string]$x.aquisitivo_fim))"
        if($null -ne $x.PSObject.Properties['detalhes']){
            foreach($d in @($x.detalhes)){ $linhas += "   - $([string]$d.erro)" }
        } else {
            foreach($e in @($x.erros)){ $linhas += "   - $e" }
        }
    }
    if(@($itens).Count -gt 20){ $linhas += "... e mais $(@($itens).Count-20) registro(s)." }
    $msg="Foram encontradas $(@($itens).Count) linha(s) com opção de férias inválida em relação ao período aquisitivo.`r`n`r`nEssas linhas NÃO serão aplicadas. O ocorrido ficará registrado em Configurações > Importações > Lançamentos anulados. Corrija a planilha e sincronize novamente.`r`n`r`n"+($linhas -join "`r`n")
    Write-DiagLog ("Sincronização: $(@($itens).Count) registro(s) ignorados por opção anterior/igual ao fim do período aquisitivo.") "WARN"
    if(-not $silent){ [Windows.Forms.MessageBox]::Show($msg,'Conferência da planilha',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) | Out-Null }
}

# V1.0.90 - Cadastro assistido durante importacao da planilha de escolhas.
# A matricula e a chave; aprovacao individual ou em lote, nunca implicita.
function Confirmar-CadastroAusentesEscolhas($candidatos){
    $ret=@{ Aprovados=@{}; Cancelado=$true }
    $itens=@($candidatos)
    if($itens.Count -eq 0){ $ret.Cancelado=$false; return $ret }
    $jan=New-Object Windows.Forms.Form
    $jan.Text="Férias DCE - Conferência de matrículas ausentes"
    $jan.StartPosition="CenterParent"
    $jan.Size=New-Object Drawing.Size(1080,650)
    $jan.MinimumSize=New-Object Drawing.Size(820,500)
    $jan.Font=New-Object Drawing.Font("Segoe UI",9)
    $jan.BackColor=[Drawing.Color]::White
    $faixa=New-Object Windows.Forms.Label
    $faixa.Dock="Top"; $faixa.Height=78
    $faixa.Padding=New-Object Windows.Forms.Padding(12,10,10,6)
    $faixa.BackColor=[Drawing.Color]::FromArgb(238,244,251)
    $faixa.Text="MATRÍCULAS NÃO ENCONTRADAS NO CADASTRO`r`nMarque os servidores que deseja incluir. Confira matrícula e nome; preencha Setor e Período quando necessário. Desmarcados não serão importados."
    $jan.Controls.Add($faixa)
    $rodape=New-Object Windows.Forms.Panel
    $rodape.Dock="Bottom"; $rodape.Height=56
    $jan.Controls.Add($rodape)
    $grade=New-Object Windows.Forms.DataGridView
    $grade.Dock="Fill"; $grade.BackgroundColor=[Drawing.Color]::White
    $grade.AllowUserToAddRows=$false; $grade.AllowUserToDeleteRows=$false
    $grade.RowHeadersVisible=$false; $grade.SelectionMode="FullRowSelect"
    $grade.AutoSizeColumnsMode="Fill"; $grade.RowTemplate.Height=29
    $marcar=New-Object Windows.Forms.DataGridViewCheckBoxColumn
    $marcar.Name="incluir"; $marcar.HeaderText="Incluir"; $marcar.FillWeight=12
    [void]$grade.Columns.Add($marcar)
    foreach($c in @(@("matricula","Matrícula",23),@("nome","Nome",38),@("setor","Setor (opcional)",30),@("periodo","Período (opcional)",20))){
        $col=New-Object Windows.Forms.DataGridViewTextBoxColumn
        $col.Name=$c[0]; $col.HeaderText=$c[1]; $col.FillWeight=[single]$c[2]
        if($c[0] -in @("matricula","nome")){ $col.ReadOnly=$true }
        [void]$grade.Columns.Add($col)
    }
    foreach($x in $itens){
        $i=$grade.Rows.Add()
        $grade.Rows[$i].Cells["incluir"].Value=$false
        $grade.Rows[$i].Cells["matricula"].Value=[string]$x.matricula
        $grade.Rows[$i].Cells["nome"].Value=[string]$x.nome
        $grade.Rows[$i].Cells["setor"].Value=[string]$x.setor
        $grade.Rows[$i].Cells["periodo"].Value=""
    }
    $jan.Controls.Add($grade)
    $grade.BringToFront()
    $btnTodos=New-Object Windows.Forms.Button
    $btnTodos.Text="Marcar todos"; $btnTodos.Location=New-Object Drawing.Point(12,12); $btnTodos.Size=New-Object Drawing.Size(112,32)
    $btnTodos.Add_Click({ foreach($r in $grade.Rows){$r.Cells["incluir"].Value=$true} })
    $rodape.Controls.Add($btnTodos)
    $btnNenhum=New-Object Windows.Forms.Button
    $btnNenhum.Text="Desmarcar"; $btnNenhum.Location=New-Object Drawing.Point(135,12); $btnNenhum.Size=New-Object Drawing.Size(112,32)
    $btnNenhum.Add_Click({ foreach($r in $grade.Rows){$r.Cells["incluir"].Value=$false} })
    $rodape.Controls.Add($btnNenhum)
    $ok=New-Object Windows.Forms.Button
    $ok.Text="Confirmar selecionados"; $ok.Size=New-Object Drawing.Size(190,32)
    $ok.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right)
    $ok.Location=New-Object Drawing.Point(666,12)
    $ok.Add_Click({
        $grade.EndEdit()
        $aprov=@{}
        foreach($r in $grade.Rows){
            if([bool]$r.Cells["incluir"].Value){
                $mat=([string]$r.Cells["matricula"].Value).Trim()
                $nm=([string]$r.Cells["nome"].Value).Trim()
                if(-not $mat -or -not $nm){
                    [Windows.Forms.MessageBox]::Show("Há um servidor marcado sem matrícula ou nome.","Conferência") | Out-Null
                    return
                }
                $aprov[$mat]=[pscustomobject]@{setor=([string]$r.Cells["setor"].Value).Trim();periodo=([string]$r.Cells["periodo"].Value).Trim()}
            }
        }
        $ret.Aprovados=$aprov
        $ret.Cancelado=$false
        $jan.DialogResult=[Windows.Forms.DialogResult]::OK
        $jan.Close()
    })
    $rodape.Controls.Add($ok)
    $cancel=New-Object Windows.Forms.Button
    $cancel.Text="Cancelar importação"; $cancel.Size=New-Object Drawing.Size(175,32)
    $cancel.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right)
    $cancel.Location=New-Object Drawing.Point(870,12)
    $cancel.Add_Click({$jan.DialogResult=[Windows.Forms.DialogResult]::Cancel; $jan.Close()})
    $rodape.Controls.Add($cancel)
    $rodape.Add_Resize({ $ok.Left=[math]::Max(270,$rodape.ClientSize.Width-390); $cancel.Left=[math]::Max(470,$rodape.ClientSize.Width-188) })
    [void]$jan.ShowDialog()
    $jan.Dispose()
    return $ret
}

function Sync-FromBase([bool]$silent=$false){
    $path=[string]$script:Config.planilha_base
    if([string]::IsNullOrWhiteSpace($path)){
        if(-not $silent){ [Windows.Forms.MessageBox]::Show("Selecione primeiro a planilha base em Configurações.","Sincronização") | Out-Null }
        return
    }
    if(-not (Test-Path -LiteralPath $path)){
        if(-not $silent){ [Windows.Forms.MessageBox]::Show("A planilha base configurada não foi encontrada:`n$path","Sincronização",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) | Out-Null }
        return
    }

    try {
        $incoming=Read-XlsmBase $path
        $qtdExcluidosIgnorados=@($incoming | Where-Object { Test-ServidorExcluido ([string]$_.matricula) }).Count
        if($qtdExcluidosIgnorados -gt 0){
            $incoming=@($incoming | Where-Object { -not (Test-ServidorExcluido ([string]$_.matricula)) })
            Write-DiagLog "Sincronização: $qtdExcluidosIgnorados linha(s) ignoradas porque a matrícula está na lista de servidores excluídos." "INFO"
        }
        # Conferencia antes de qualquer gravacao: somente novos servidores exigem autorizacao.
        # Novos periodos aquisitivos de uma matricula existente nao sao novos servidores.
        $cadastrados=@{}
        foreach($cr in @($script:Records)){
            $mk=([string]$cr.matricula).Trim()
            if($mk){$cadastrados[$mk]=$true}
        }
        $faltantes=@($incoming | Where-Object { $mk=([string]$_.matricula).Trim(); $mk -and -not $cadastrados.ContainsKey($mk) } |
            Sort-Object matricula -Unique)
        if($faltantes.Count -gt 0){
            Write-DiagLog "Sincronização: $($faltantes.Count) matrícula(s) ausentes para conferência." "WARN"
            $decisao=$null
            if(-not $silent){ $decisao=Confirmar-CadastroAusentesEscolhas $faltantes }
            if($null -ne $decisao -and [bool]$decisao.Cancelado){
                Write-DiagLog "Importação cancelada pelo usuário durante a conferência de cadastros." "INFO"
                return
            }
            $aprovados=if($null -ne $decisao){$decisao.Aprovados}else{@{}}
            $ignorados=@($faltantes | Where-Object {-not $aprovados.ContainsKey(([string]$_.matricula).Trim())})
            if($ignorados.Count -gt 0){
                Write-DiagLog "Importação: $($ignorados.Count) servidor(es) não cadastrado(s) ignorado(s), sem gravar opções." "WARN"
                if(-not $silent){
                    $msg="Servidores não incluídos nesta importação:`r`n`r`n" + (($ignorados | Select-Object -First 20 | ForEach-Object { "$($_.matricula) - $($_.nome)" }) -join "`r`n")
                    [Windows.Forms.MessageBox]::Show($msg,"Conferência de cadastro",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
                }
            }
            $incoming=@($incoming | Where-Object { $mk=([string]$_.matricula).Trim(); $cadastrados.ContainsKey($mk) -or $aprovados.ContainsKey($mk) })
            foreach($x in $incoming){
                $mk=([string]$x.matricula).Trim()
                if($aprovados.ContainsKey($mk)){
                    $cad=$aprovados[$mk]
                    if([string]::IsNullOrWhiteSpace([string]$x.setor) -and $cad.setor){$x.setor=[string]$cad.setor}
                    $x | Add-Member -NotePropertyName 'periodo_cadastro' -NotePropertyValue ([string]$cad.periodo) -Force
                }
            }
        }
        $layoutNovo=(@($incoming | Where-Object {[string]$_.layout_planilha -eq "NOVO"}).Count -gt 0)

        # 1) Validação das opções contra o fim do período aquisitivo.
        # Nova escolha 15+15 incompleta no ano do aquisitivo = ANULADO.
        # Possível parcela de período anterior sem confirmação = PENDENTE.
        $invalidosImport=@(); $pendenciasImport=@(); $incomingValidos=@()
        foreach($ix in @($incoming)){
            $detalhes=@(Get-ImportOptionValidationDetails $ix)
            $hard=@($detalhes | Where-Object { [string]$_.severidade -eq "ANULADO" })
            $pend=@($detalhes | Where-Object { [string]$_.severidade -eq "PENDENTE" })
            if($hard.Count -gt 0){
                $invalidosImport += [pscustomobject]@{
                    linha=[int]$ix.origem_linha_excel; matricula=[string]$ix.matricula; nome=[string]$ix.nome
                    aquisitivo_inicio=[string]$ix.aquisitivo_inicio; aquisitivo_fim=[string]$ix.aquisitivo_fim
                    detalhes=@($hard); erros=@($hard | ForEach-Object { [string]$_.erro })
                }
            } else {
                $incomingValidos += $ix
                if($pend.Count -gt 0){
                    $pendenciasImport += [pscustomobject]@{
                        linha=[int]$ix.origem_linha_excel; matricula=[string]$ix.matricula; nome=[string]$ix.nome
                        aquisitivo_inicio=[string]$ix.aquisitivo_inicio; aquisitivo_fim=[string]$ix.aquisitivo_fim
                        detalhes=@($pend); erros=@($pend | ForEach-Object { [string]$_.erro })
                    }
                }
            }
        }
        $auditoriaImportMutou=Update-HistoricoLancamentosAnulados $incoming $invalidosImport $pendenciasImport $path
        if([bool]$script:Config.ferias_fixas_2027_importadas -or [bool]$script:Config.historico_3_anos_importado){ $recPendSync=Reconciliar-PendenciasImportacao15x15 }
        Show-ImportInvalidOptions $invalidosImport $silent
        if(@($pendenciasImport).Count -gt 0){
            Write-DiagLog ("Sincronização: $(@($pendenciasImport).Count) linha(s) mantidas como PENDENTE DE CONFERÊNCIA por possível parcela remanescente 15 dias.") "WARN"
            if(-not $silent){
                [Windows.Forms.MessageBox]::Show(
                    "Foram encontradas $(@($pendenciasImport).Count) linha(s) com apenas um período de 15 dias.`r`n`r`nElas NÃO foram anuladas, pois podem representar parcela remanescente de programação anterior. Permanecerão como PENDENTE DE CONFERÊNCIA até o cruzamento com Férias Fixas e/ou Histórico.`r`n`r`nA regra do período aquisitivo continua obrigatória: qualquer parcela iniciada em data menor ou igual ao fim do aquisitivo continua sendo anulada.",
                    "Conferência — possível parcela remanescente",
                    [Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
            }
        }

        # 2) No layout novo, Setor / Grupo de Chefia / Grupo de Análise são lidos
        #    como cadastros estruturais. Conflitos dentro da própria planilha
        #    bloqueiam somente a associação conflitante, nunca são resolvidos no escuro.
        $planoCad=$null
        if($layoutNovo){
            $planoCad=Get-ImportCadastroPlan $incomingValidos
            Show-ImportCadastroProblems $planoCad $silent
        }

        $novos=0
        $atualizados=0
        $iguais=0
        $divergenciasOpcoes=0
        $divergenciasDetalhe=@()
        $aplicouDivergencias=$false

        $setoresNovos=0
        $setoresPreenchidos=0
        $chefiasAplicadas=0
        $gruposAnaliseAplicados=0
        $cadastroMutou=$false
        $cadastroDivergencias=@()

        foreach($x in $incomingValidos){
            $baseCadastro=$script:Records | Where-Object {
                [string]$_.matricula -eq [string]$x.matricula -and
                [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -and
                [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)
            } | Select-Object -First 1

            $existing=$script:Records | Where-Object {
                [string]$_.matricula -eq [string]$x.matricula -and
                [string]$_.aquisitivo_inicio -eq [string]$x.aquisitivo_inicio -and
                [string]$_.aquisitivo_fim -eq [string]$x.aquisitivo_fim
            } | Select-Object -First 1

            $setorImportado=([string]$x.setor).Trim()

            if($null -eq $existing){
                $cadServidor=$script:Records | Where-Object {
                    [string]$_.matricula -eq [string]$x.matricula -and
                    (-not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo))
                } | Select-Object -First 1

                $setorCadastro=if($cadServidor -and -not [string]::IsNullOrWhiteSpace([string]$cadServidor.setor)){([string]$cadServidor.setor).Trim()}elseif($baseCadastro -and -not [string]::IsNullOrWhiteSpace([string]$baseCadastro.setor)){([string]$baseCadastro.setor).Trim()}else{""}
                $periodoHerdado=if($cadServidor -and -not [string]::IsNullOrWhiteSpace([string]$cadServidor.periodo)){[string]$cadServidor.periodo}elseif($baseCadastro){[string]$baseCadastro.periodo}else{""}
                if(-not $periodoHerdado -and $null -ne $x.PSObject.Properties['periodo_cadastro']){ $periodoHerdado=[string]$x.periodo_cadastro }
                $setorPlan=if($setorImportado){Get-CanonicalSetorName $setorImportado}else{""}
                $setorNovo=$setorCadastro
                $setorDivergente=$false

                if($setorPlan){
                    if($setorCadastro -and (Get-ImportTextKey $setorCadastro) -ne (Get-ImportTextKey $setorPlan)){
                        # Novo período para matrícula já cadastrada: preserva o setor atual até decisão explícita.
                        $setorNovo=$setorCadastro
                        $setorDivergente=$true
                    } else {
                        $setorNovo=$setorPlan
                    }
                }

                if($baseCadastro){
                    # Reaproveita o placeholder em vez de removê-lo, preservando ID e metadados já cadastrados.
                    $novoSync=$baseCadastro
                    [void](Initialize-RecordDefaults $novoSync)
                    $novoSync.matricula=[string]$x.matricula
                    $novoSync.nome=([string]$x.nome).Trim()
                    $novoSync.setor=$setorNovo
                    $novoSync.periodo=$periodoHerdado
                    $novoSync.aquisitivo_inicio=[string]$x.aquisitivo_inicio
                    $novoSync.aquisitivo_fim=[string]$x.aquisitivo_fim
                    $novoSync.opcao1=$x.opcao1
                    $novoSync.opcao2=$x.opcao2
                    $novoSync.opcao3=$x.opcao3
                    $novoSync.opcao_aprovada=0
                    $novoSync.origem_linha_excel=[int]$x.origem_linha_excel
                    $novoSync.cadastro_base=$false
                    $novoSync.ferias_bloqueadas=$false
                    $novoSync.origem_planejamento="ATUAL"
                    $novoSync.bloqueio_motivo=""
                } else {
                    $novoSync=[pscustomobject]@{
                        id=Get-NextId
                        matricula=[string]$x.matricula
                        nome=([string]$x.nome).Trim()
                        setor=$setorNovo
                        periodo=$periodoHerdado
                        aquisitivo_inicio=[string]$x.aquisitivo_inicio
                        aquisitivo_fim=[string]$x.aquisitivo_fim
                        opcao1=$x.opcao1
                        opcao2=$x.opcao2
                        opcao3=$x.opcao3
                        opcao_aprovada=0
                        observacoes=""
                        origem_linha_excel=[int]$x.origem_linha_excel
                        ferias_bloqueadas=$false
                        origem_planejamento="ATUAL"
                        bloqueio_motivo=""
                        cadastro_base=$false
                    }
                    [void](Initialize-RecordDefaults $novoSync)
                    $script:Records += $novoSync
                }

                if($setorDivergente){
                    $cadastroDivergencias += [pscustomobject]@{
                        tipo="SETOR DO SERVIDOR"
                        record_id=[int]$novoSync.id
                        matricula=[string]$novoSync.matricula
                        nome=[string]$novoSync.nome
                        setor=""
                        sistema=$setorCadastro
                        planilha=$setorPlan
                    }
                } elseif($setorPlan -and -not $setorCadastro){
                    $setoresPreenchidos++
                    $cadastroMutou=$true
                }
                $novos++
            } else {
                [void](Initialize-RecordDefaults $existing)

                # Setor vindo da nova planilha:
                # - preenche automaticamente quando o sistema está vazio;
                # - divergência nunca sobrescreve silenciosamente.
                if($setorImportado){
                    $setorAtual=([string]$existing.setor).Trim()
                    $setorPlan=Get-CanonicalSetorName $setorImportado
                    if(-not $setorAtual){
                        $existing.setor=$setorPlan
                        $setoresPreenchidos++
                        $cadastroMutou=$true
                    } elseif((Get-ImportTextKey $setorAtual) -ne (Get-ImportTextKey $setorPlan)){
                        $cadastroDivergencias += [pscustomobject]@{
                            tipo="SETOR DO SERVIDOR"
                            record_id=[int]$existing.id
                            matricula=[string]$existing.matricula
                            nome=[string]$existing.nome
                            setor=""
                            sistema=$setorAtual
                            planilha=$setorPlan
                        }
                    }
                }

                $before=(@($existing.opcao1,$existing.opcao2,$existing.opcao3) | ConvertTo-Json -Depth 5 -Compress)
                $after=(@($x.opcao1,$x.opcao2,$x.opcao3) | ConvertTo-Json -Depth 5 -Compress)

                if(([string]$existing.nome) -like "System.Xml.*" -and -not [string]::IsNullOrWhiteSpace(([string]$x.nome))){
                    $existing.nome=([string]$x.nome).Trim()
                }
                $nomeImportado=([string]$x.nome).Trim()
                $nomeInvalido=([string]::IsNullOrWhiteSpace($nomeImportado) -or $nomeImportado -like "System.Xml.*")
                $nomeMudou=(-not $nomeInvalido -and [string]$existing.nome -ne $nomeImportado)

                # Para registros que já existem no aplicativo, a planilha base
                # não sobrescreve 1ª/2ª/3ª opções sem conferência.
                if($before -ne $after -and (Test-RegistroFeriasBloqueadas $existing)){
                    Write-DiagLog "Sincronização: opções de período FIXO/BLOQUEADO preservadas; ID=$([int]$existing.id). Use o ajuste excepcional para alterar férias confirmadas." 'WARN'
                }
                if($before -ne $after -and -not (Test-RegistroFeriasBloqueadas $existing)){
                    $divergenciasOpcoes++
                    $aqIni=Date-ToBR ([string]$existing.aquisitivo_inicio)
                    $aqFim=Date-ToBR ([string]$existing.aquisitivo_fim)
                    $divergenciasDetalhe += [pscustomobject]@{
                        record_id=[int]$existing.id
                        matricula=[string]$existing.matricula
                        nome=[string]$existing.nome
                        aquisitivo="$aqIni a $aqFim"
                        sistema="1ª: $(Format-OptionSummary $existing.opcao1) | 2ª: $(Format-OptionSummary $existing.opcao2) | 3ª: $(Format-OptionSummary $existing.opcao3)"
                        planilha="1ª: $(Format-OptionSummary $x.opcao1) | 2ª: $(Format-OptionSummary $x.opcao2) | 3ª: $(Format-OptionSummary $x.opcao3)"
                        opcao1=$x.opcao1
                        opcao2=$x.opcao2
                        opcao3=$x.opcao3
                    }
                }

                if($nomeMudou){
                    foreach($sr in ($script:Records | Where-Object {[string]$_.matricula -eq [string]$x.matricula})){
                        if(-not $nomeInvalido){ $sr.nome=$nomeImportado }
                    }
                    $atualizados++
                } else {
                    $iguais++
                }
                $existing.origem_linha_excel=[int]$x.origem_linha_excel
            }
        }

        # 3) Monta/atualiza os cadastros estruturais a partir do Setor.
        if($layoutNovo -and $null -ne $planoCad){
            foreach($m in @($planoCad.mapeamentos)){
                $setorPlan=([string]$m.setor).Trim()
                if(-not $setorPlan){ continue }

                $setorCanon=Get-CanonicalSetorName $setorPlan
                $setorKey=Get-ImportTextKey $setorCanon
                $jaSetor=$false
                foreach($sCad in @($script:Config.setores)){
                    if((Get-ImportTextKey ([string]$sCad)) -eq $setorKey){ $jaSetor=$true; $setorCanon=([string]$sCad).Trim(); break }
                }
                if(-not $jaSetor){
                    $script:Config.setores=@(@($script:Config.setores)+$setorCanon | Sort-Object -Unique)
                    $setoresNovos++
                    $cadastroMutou=$true
                }

                if((-not [bool]$m.bloqueia_chefia) -and -not [string]::IsNullOrWhiteSpace([string]$m.grupo_chefia)){
                    $chefPlan=Get-CanonicalGrupoChefiaName ([string]$m.grupo_chefia)
                    $chefAtual=Get-GrupoChefiaSetor $setorCanon
                    if(-not $chefAtual){
                        [void](Add-GrupoChefiaNome $chefPlan)
                        Set-GrupoChefiaSetor $setorCanon $chefPlan
                        $chefiasAplicadas++
                        $cadastroMutou=$true
                    } elseif((Get-ImportTextKey $chefAtual) -ne (Get-ImportTextKey $chefPlan)){
                        $cadastroDivergencias += [pscustomobject]@{
                            tipo="GRUPO DE CHEFIA"
                            record_id=0
                            matricula=""
                            nome=""
                            setor=$setorCanon
                            sistema=$chefAtual
                            planilha=$chefPlan
                        }
                    }
                }

                if((-not [bool]$m.bloqueia_grupo) -and -not [string]::IsNullOrWhiteSpace([string]$m.grupo_analise)){
                    $grupoPlan=[string]$m.grupo_analise
                    $grupoAtual=Get-ExplicitGrupoAnaliseSetor $setorCanon
                    if(-not $grupoAtual){
                        Set-GrupoAnaliseSetor $setorCanon $grupoPlan
                        $gruposAnaliseAplicados++
                        $cadastroMutou=$true
                    } elseif((Get-ImportTextKey $grupoAtual) -ne (Get-ImportTextKey $grupoPlan)){
                        $cadastroDivergencias += [pscustomobject]@{
                            tipo="GRUPO DE ANÁLISE"
                            record_id=0
                            matricula=""
                            nome=""
                            setor=$setorCanon
                            sistema=$grupoAtual
                            planilha=$grupoPlan
                        }
                    }
                }
            }
        }

        # 4) Divergências de Setor/Chefia/Grupo de Análise contra o cadastro atual.
        if($cadastroDivergencias.Count -gt 0 -and -not $silent){
            $acaoCad=Show-CadastroMappingDivergenciasDialog $cadastroDivergencias
            if($acaoCad -eq "CANCELAR"){
                Load-Database
                if($script:lblSyncStatus){ $script:lblSyncStatus.Text="Sincronização cancelada pelo usuário; nenhuma alteração foi gravada." }
                return
            }
            if($acaoCad -eq "APLICAR"){
                foreach($d in @($cadastroDivergencias)){
                    switch([string]$d.tipo){
                        "SETOR DO SERVIDOR" {
                            $dest=$script:Records | Where-Object {[int]$_.id -eq [int]$d.record_id} | Select-Object -First 1
                            if($null -ne $dest){
                                $dest.setor=[string]$d.planilha
                                $setoresPreenchidos++
                                $cadastroMutou=$true
                            }
                        }
                        "GRUPO DE CHEFIA" {
                            $chef=Get-CanonicalGrupoChefiaName ([string]$d.planilha)
                            [void](Add-GrupoChefiaNome $chef)
                            Set-GrupoChefiaSetor ([string]$d.setor) $chef
                            $chefiasAplicadas++
                            $cadastroMutou=$true
                        }
                        "GRUPO DE ANÁLISE" {
                            Set-GrupoAnaliseSetor ([string]$d.setor) ([string]$d.planilha)
                            $gruposAnaliseAplicados++
                            $cadastroMutou=$true
                        }
                    }
                }
            }
        } elseif($cadastroDivergencias.Count -gt 0 -and $silent){
            Write-DiagLog "Sincronização automática: divergências de Setor/Chefia/Grupo de Análise foram PRESERVADAS para evitar sobrescrita silenciosa." "WARN"
        }

        # 5) Divergências nas opções de férias continuam com a conferência já existente.
        if($divergenciasDetalhe.Count -gt 0 -and -not $silent){
            $acao=Show-SyncDivergenciasDialog $divergenciasDetalhe
            if($acao -eq "CANCELAR"){
                Load-Database
                if($script:lblSyncStatus){$script:lblSyncStatus.Text="Sincronização cancelada pelo usuário; nenhuma alteração foi gravada."}
                return
            }
            if($acao -eq "APLICAR"){
                $aplicouDivergencias=$true
                foreach($d in $divergenciasDetalhe){
                    $dest=$script:Records|Where-Object {[int]$_.id -eq [int]$d.record_id}|Select-Object -First 1
                    if($null -ne $dest){
                        $aceitaAntes=[int]$dest.opcao_aprovada
                        $frAntes=Get-NumeroFRConfirmada $dest
                        $mudouFRAprovada=$false
                        if($frAntes -gt 0){
                            $antesFR=$dest.("opcao$frAntes")
                            $depoisFR=$d.("opcao$frAntes")
                            $mudouFRAprovada=(([string]$antesFR.fr_inicio -ne [string]$depoisFR.fr_inicio) -or ([string]$antesFR.fr_fim -ne [string]$depoisFR.fr_fim))
                        }
                        $dest.opcao1=$d.opcao1
                        $dest.opcao2=$d.opcao2
                        $dest.opcao3=$d.opcao3
                        if($mudouFRAprovada){
                            $dest.fr_opcao_aprovada=0
                            $notaFR="[Sincronização $(Get-Date -Format 'dd/MM/yyyy HH:mm')] FR anteriormente aprovada foi alterada na planilha; decisão FR redefinida para NÃO APROVADA."
                            $dest.observacoes=([string]$dest.observacoes).Trim()+"`r`n"+$notaFR
                        }
                        if($aceitaAntes -gt 0){
                            $nota="[Sincronização $(Get-Date -Format 'dd/MM/yyyy HH:mm')] Opções atualizadas conforme planilha; decisão anterior (${aceitaAntes}ª opção) foi redefinida para NÃO DEFINIDA para nova conferência."
                            $dest.opcao_aprovada=0
                            if([string]::IsNullOrWhiteSpace([string]$dest.observacoes)){
                                $dest.observacoes=$nota
                            } else {
                                $dest.observacoes=([string]$dest.observacoes).Trim()+"`r`n"+$nota
                            }
                        }
                    }
                }
            }
        }

        $temMudanca=($novos -gt 0 -or $atualizados -gt 0 -or $aplicouDivergencias -or $cadastroMutou -or $auditoriaImportMutou)
        if($temMudanca){
            [void](Backup-AntesAcao "ANTES_SINCRONIZAR")
            Save-Database
            Refresh-SetorPeriodos
            Refresh-CadastrosLists
            Refresh-Grid
            Refresh-Dashboard
            Refresh-PlanejamentoSetor
            Refresh-ConfigInfo
            Refresh-ImportacaoStatus
        } else {
            Write-DiagLog "Sincronização sem alterações persistentes; nenhum backup extra foi criado."
        }

        $qtdConflitosCad=if($null -ne $planoCad){@($planoCad.conflitos).Count}else{0}
        $qtdSemSetor=if($null -ne $planoCad){@($planoCad.linhas_sem_setor).Count}else{0}
        $qtdPendenciasCad=if($null -ne $planoCad){@($planoCad.pendencias).Count}else{0}
        $layoutTxt=if($layoutNovo){"NOVO"}else{"LEGADO"}

        if($script:lblSyncStatus){
            $script:lblSyncStatus.Text="Última sincronização: $(Get-Date -Format 'dd/MM/yyyy HH:mm') | Layout: $layoutTxt | Novos: $novos | Setores novos: $setoresNovos | Chefias: $chefiasAplicadas | Grupos análise: $gruposAnaliseAplicados | Inválidas: $(@($invalidosImport).Count) | Conflitos cadastro: $qtdConflitosCad | Pendências: $qtdPendenciasCad"
        }

        if(-not $silent){
            $msg="Sincronização concluída.`n`n"
            $msg += "Layout da planilha: $layoutTxt`n"
            $msg += "Novos períodos importados: $novos`n"
            $msg += "Nomes atualizados: $atualizados`n"
            if($layoutNovo){
                $msg += "Setores novos cadastrados: $setoresNovos`n"
                $msg += "Registros que receberam Setor: $setoresPreenchidos`n"
                $msg += "Grupos de Chefia aplicados/atualizados: $chefiasAplicadas`n"
                $msg += "Grupos de Análise aplicados/atualizados: $gruposAnaliseAplicados`n"
                $msg += "Conflitos internos de cadastro não aplicados: $qtdConflitosCad`n"
                $msg += "Pendências de Chefia/Grupo de Análise: $qtdPendenciasCad`n"
                $msg += "Linhas sem Setor: $qtdSemSetor`n"
            }
            $msg += "Opções divergentes encontradas e conferidas: $divergenciasOpcoes`n"
            $msg += "Opções inválidas ignoradas: $(@($invalidosImport).Count)`n"
            $msg += "Linhas de servidores excluídos ignoradas: $qtdExcluidosIgnorados`n`n"
            $msg += "A planilha nunca sobrescreve silenciosamente Setor, Grupo de Chefia, Grupo de Análise ou opções já divergentes no sistema."

            [Windows.Forms.MessageBox]::Show(
                $msg,
                "Férias DCE",
                [Windows.Forms.MessageBoxButtons]::OK,
                [Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
    } catch {
        try { Load-Database } catch { Write-DiagLog "Falha ao recarregar a base após erro de sincronização." "ERROR" $_ }
        if($script:lblSyncStatus){
            $script:lblSyncStatus.Text="Falha na sincronização: $($_.Exception.Message)"
            $script:lblSyncStatus.ForeColor=[Drawing.Color]::DarkRed
        }
        if(-not $silent){
            [Windows.Forms.MessageBox]::Show(
                "Erro ao sincronizar a planilha base.`n$($_.Exception.Message)",
                "Férias DCE",
                [Windows.Forms.MessageBoxButtons]::OK,
                [Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    }
}

function Get-ServidorRecords([string]$matricula){
    # V127: indice de leitura; nao altera a ordem nem o JSON.
    $rev=if($script:Database -and $script:Database.PSObject.Properties['revisao_dados']){[string]$script:Database.revisao_dados}else{''}
    $count=@($script:Records).Count
    if($null -eq $script:ServidoresIndice -or $script:ServidoresIndiceCount -ne $count -or $script:ServidoresIndiceRev -ne $rev){
        $indice=@{}
        foreach($reg in @($script:Records)){
            $key=[string]$reg.matricula
            if(-not $indice.ContainsKey($key)){$indice[$key]=[Collections.Generic.List[object]]::new()}
            $indice[$key].Add($reg)
        }
        foreach($key in @($indice.Keys)){ $indice[$key]=@($indice[$key] | Sort-Object aquisitivo_inicio) }
        $script:ServidoresIndice=$indice
        $script:ServidoresIndiceCount=$count
        $script:ServidoresIndiceRev=$rev
    }
    $matricula=[string]$matricula
    if($script:ServidoresIndice.ContainsKey($matricula)){return @($script:ServidoresIndice[$matricula])}
    return @()
}


function Apply-ServidorCadastro([string]$matricula,[string]$nome,[string]$setor,[string]$periodo){
    $matricula=$matricula.Trim()
    $nome=$nome.Trim()
    $setor=$setor.Trim()
    $periodo=$periodo.Trim().ToUpperInvariant()

    if([string]::IsNullOrWhiteSpace($matricula)){ return [pscustomobject]@{status="ERRO";mensagem="Matrícula vazia"} }
    if([string]::IsNullOrWhiteSpace($nome)){ return [pscustomobject]@{status="ERRO";mensagem="Nome vazio"} }
    if([string]::IsNullOrWhiteSpace($setor)){ return [pscustomobject]@{status="ERRO";mensagem="Setor vazio"} }
    if([string]::IsNullOrWhiteSpace($periodo)){ return [pscustomobject]@{status="ERRO";mensagem="Período vazio"} }

    $recs=@($script:Records | Where-Object {[string]$_.matricula -eq $matricula})
    if($recs.Count -gt 0){
        foreach($r in $recs){
            [void](Initialize-RecordDefaults $r)
            $r.nome=$nome
            $r.setor=$setor
            $r.periodo=$periodo
        }
        if(@($script:Config.setores) -notcontains $setor){
            $script:Config.setores=@(@($script:Config.setores)+$setor | Sort-Object -Unique)
            Set-GrupoAnaliseSetor $setor "ASSISTENCIAL"
        }
        if(@($script:Config.periodos) -notcontains $periodo){
            $script:Config.periodos=@(@($script:Config.periodos)+$periodo | Sort-Object -Unique)
        }
        return [pscustomobject]@{status="ATUALIZADO";mensagem="$($recs.Count) período(s) vinculados"}
    }

    # Cadastro-base sem período aquisitivo: será enriquecido depois pela sincronização.
    $novo=[pscustomobject]@{
        id=Get-NextId
        matricula=$matricula
        nome=$nome
        setor=$setor
        periodo=$periodo
        aquisitivo_inicio=""
        aquisitivo_fim=""
        opcao1=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
        opcao2=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
        opcao3=[pscustomobject]@{tipo="";inicio1="";fim1="";inicio2="";fim2=""}
        opcao_aprovada=0
        observacoes=""
        origem_linha_excel=0
        cadastro_base=$true
        ferias_bloqueadas=$false
        origem_planejamento="ATUAL"
        bloqueio_motivo=""
    }
    [void](Initialize-RecordDefaults $novo)
    $script:Records += $novo
    if(@($script:Config.setores) -notcontains $setor){
        $script:Config.setores=@(@($script:Config.setores)+$setor | Sort-Object -Unique)
        Set-GrupoAnaliseSetor $setor "ASSISTENCIAL"
    }
    if(@($script:Config.periodos) -notcontains $periodo){
        $script:Config.periodos=@(@($script:Config.periodos)+$periodo | Sort-Object -Unique)
    }
    return [pscustomobject]@{status="NOVO";mensagem="Cadastro-base criado"}
}


function New-RegistroFeriasManual([string]$matricula,[string]$nome,[string]$setor,[string]$periodo,[string]$aqIni="",[string]$aqFim="",[bool]$cadastroBase=$false){
    $novo=[pscustomobject]@{
        id=Get-NextId
        matricula=$matricula.Trim(); nome=$nome.Trim(); setor=$setor.Trim(); periodo=$periodo.Trim().ToUpperInvariant()
        aquisitivo_inicio=$aqIni; aquisitivo_fim=$aqFim
        opcao1=(New-EmptyOptionObject); opcao2=(New-EmptyOptionObject); opcao3=(New-EmptyOptionObject)
        opcao_aprovada=0; observacoes=""; justificativa_decisao=""
        origem_linha_excel=0; cadastro_base=$cadastroBase
        ferias_bloqueadas=$false; origem_planejamento="ATUAL"; bloqueio_motivo=""
    }
    [void](Initialize-RecordDefaults $novo)
    return $novo
}

function Adicionar-PeriodoManualServidor([string]$matricula){
    $recs=Get-ServidorRecords $matricula
    if($recs.Count -eq 0){ [Windows.Forms.MessageBox]::Show("Selecione primeiro um servidor.","Adicionar período") | Out-Null; return }
    $cad=$recs[0]
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="Adicionar período aquisitivo"; $dlg.Size=New-Object Drawing.Size(470,270); $dlg.StartPosition="CenterParent"; $dlg.FormBorderStyle="FixedDialog"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $dlg.Controls.Add((New-Label "Servidor" 20 18 80)); $lbl=New-Object Windows.Forms.Label; $lbl.Text="$($cad.nome) | Matrícula $matricula"; $lbl.Location=New-Object Drawing.Point(20,40); $lbl.Size=New-Object Drawing.Size(410,24); $lbl.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $dlg.Controls.Add($lbl)
    $dlg.Controls.Add((New-Label "Início do período aquisitivo" 20 82 180)); $di=New-Object Windows.Forms.DateTimePicker; $di.Location=New-Object Drawing.Point(20,106); $di.Size=New-Object Drawing.Size(190,26); $di.Format="Short"; $dlg.Controls.Add($di)
    $dlg.Controls.Add((New-Label "Fim do período aquisitivo" 235 82 180)); $df=New-Object Windows.Forms.DateTimePicker; $df.Location=New-Object Drawing.Point(235,106); $df.Size=New-Object Drawing.Size(190,26); $df.Format="Short"; $dlg.Controls.Add($df)
    $btnOk=New-Button "Adicionar período" 145 170 150 34; $btnCancel=New-Button "Cancelar" 305 170 120 34; $dlg.Controls.Add($btnOk); $dlg.Controls.Add($btnCancel)
    $btnCancel.add_Click({$dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel;$dlg.Close()})
    $btnOk.add_Click({
        $ini=$di.Value.Date; $fim=$df.Value.Date
        if($fim -lt $ini){[Windows.Forms.MessageBox]::Show("O fim do período aquisitivo não pode ser anterior ao início.","Validação")|Out-Null;return}
        $si=Date-ToStore $ini; $sf=Date-ToStore $fim
        if(@($script:Records|Where-Object{[string]$_.matricula -eq $matricula -and [string]$_.aquisitivo_inicio -eq $si -and [string]$_.aquisitivo_fim -eq $sf}).Count -gt 0){[Windows.Forms.MessageBox]::Show("Este período aquisitivo já está cadastrado para o servidor.","Validação")|Out-Null;return}
        $dlg.Tag=[pscustomobject]@{inicio=$si;fim=$sf};$dlg.DialogResult=[Windows.Forms.DialogResult]::OK;$dlg.Close()
    })
    if($dlg.ShowDialog($form) -ne [Windows.Forms.DialogResult]::OK){$dlg.Dispose();return}
    $dados=$dlg.Tag; $dlg.Dispose()
    try{
        [void](Backup-AntesAcao "ANTES_CADASTRO_MANUAL_PERIODO")
        $base=@($script:Records|Where-Object{[string]$_.matricula -eq $matricula -and [bool]$_.cadastro_base -and [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -and [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)})|Select-Object -First 1
        if($null -ne $base){$base.aquisitivo_inicio=[string]$dados.inicio;$base.aquisitivo_fim=[string]$dados.fim;$base.cadastro_base=$false;$novoId=[int]$base.id}
        else{$novo=New-RegistroFeriasManual ([string]$cad.matricula) ([string]$cad.nome) ([string]$cad.setor) ([string]$cad.periodo) ([string]$dados.inicio) ([string]$dados.fim) $false;$script:Records += $novo;$novoId=[int]$novo.id}
        Save-Database; Refresh-Grid; Load-Servidor $matricula
        foreach($row in $script:gridPeriodos.Rows){if([int]$row.Cells["pid"].Value -eq $novoId){$row.Selected=$true;Load-Editor $novoId;break}}
        [Windows.Forms.MessageBox]::Show("Período aquisitivo cadastrado com sucesso.","Férias DCE")|Out-Null
    }catch{Write-DiagLog "Falha no cadastro manual de período aquisitivo." "ERROR" $_;[Windows.Forms.MessageBox]::Show("Não foi possível cadastrar o período.`n$($_.Exception.Message)","Férias DCE")|Out-Null}
}


# V1.0.114 - Cadastro manual de compromissos fixos no periodo selecionado.
function Cadastrar-FeriasFixaManual {
    if([int]$script:CurrentId -le 0){ [Windows.Forms.MessageBox]::Show("Selecione primeiro um periodo aquisitivo na grade.","Novo período de férias fixas") | Out-Null; return }
    $id=[int]$script:CurrentId
    $r=$script:Records | Where-Object { [int]$_.id -eq $id } | Select-Object -First 1
    if($null -eq $r){ return }
    if(-not (Parse-Date ([string]$r.aquisitivo_fim))){ [Windows.Forms.MessageBox]::Show("Informe primeiro o período aquisitivo, usando Adicionar ou Corrigir período.","Novo período de férias fixas")|Out-Null;return }
    if([string]::IsNullOrWhiteSpace([string]$r.setor) -or [string]::IsNullOrWhiteSpace([string]$r.periodo)){
        [Windows.Forms.MessageBox]::Show("Complete o setor e o período de trabalho do servidor antes de incluir férias fixas.","Novo período de férias fixas")|Out-Null;return
    }
    # Uma fixa remanescente por aquisitivo: a outra quinzena pertence ao ano anterior.
    # Para corrigir uma fixa existente, utilize o fluxo protegido de alteração.
    if(Test-RegistroFixoImportado $r){
        [Windows.Forms.MessageBox]::Show("Este período aquisitivo já possui férias FIXAS. Não é permitido adicionar outra quinzena fixa ao mesmo aquisitivo. Use Corrigir período para ajustar o registro existente.","Novo período de férias fixas") | Out-Null
        return
    }
    if(-not (Test-RegistroFixoImportado $r)){
        foreach($n in 1..3){
            $op=$r.("opcao$n")
            if($null -ne $op -and -not [string]::IsNullOrWhiteSpace([string]$op.tipo)){
                [Windows.Forms.MessageBox]::Show("Este aquisitivo possui opções cadastradas. A inclusão manual de fixa foi bloqueada para não transformar opções em férias confirmadas. Revise o cadastro antes.","Novo período de férias fixas")|Out-Null
                return
            }
        }
    }
    if((Test-RegistroFeriasBloqueadas $r) -and -not (Test-RegistroFixoImportado $r)){
        [Windows.Forms.MessageBox]::Show("Este período já possui bloqueio manual. Regularize esse bloqueio antes de incluir férias fixa.","Novo período de férias fixas")|Out-Null;return
    }
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="Cadastrar férias fixa - $($r.nome)"; $dlg.Size=New-Object Drawing.Size(610,390)
    $dlg.StartPosition='CenterParent'; $dlg.FormBorderStyle='FixedDialog'; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $cab=New-Object Windows.Forms.Label; $cab.Location=New-Object Drawing.Point(18,16); $cab.Size=New-Object Drawing.Size(560,47)
    $cab.Text="$($r.nome) | Matrícula $($r.matricula)`r`nAquisitivo: $(Date-ToBR ([string]$r.aquisitivo_inicio)) a $(Date-ToBR ([string]$r.aquisitivo_fim))"; $dlg.Controls.Add($cab)
    $dlg.Controls.Add((New-Label "Início da férias fixa" 18 78 180))
    $di=New-Object Windows.Forms.DateTimePicker; $di.Location=New-Object Drawing.Point(18,102); $di.Width=255; $di.Format='Short'; $dlg.Controls.Add($di)
    $dlg.Controls.Add((New-Label "Fim da férias fixa" 310 78 180))
    $df=New-Object Windows.Forms.DateTimePicker; $df.Location=New-Object Drawing.Point(310,102); $df.Width=255; $df.Format='Short'; $dlg.Controls.Add($df)
    $dlg.Controls.Add((New-Label "Justificativa / origem da confirmação (obrigatória)" 18 150 490))
    $mot=New-Object Windows.Forms.TextBox; $mot.Location=New-Object Drawing.Point(18,176); $mot.Size=New-Object Drawing.Size(548,75)
    $mot.Multiline=$true; $mot.MaxLength=500; $dlg.Controls.Add($mot)
    $nota=New-Object Windows.Forms.Label; $nota.Location=New-Object Drawing.Point(18,258); $nota.Size=New-Object Drawing.Size(548,35)
    $nota.Text="Registre somente a quinzena remanescente (15 dias) de ano anterior."; $dlg.Controls.Add($nota)
    $salvar=New-Button 'Confirmar férias fixa' 276 300 175 34; $dlg.Controls.Add($salvar)
    $cancel=New-Button 'Cancelar' 464 300 100 34; $dlg.Controls.Add($cancel)
    $cancel.add_Click({$dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel;$dlg.Close()})
    $salvar.add_Click({
        $ini=$di.Value.Date; $fim=$df.Value.Date; $dias=($fim-$ini).Days+1
        if($dias -ne 15){[Windows.Forms.MessageBox]::Show("Para a quinzena fixa remanescente, informe exatamente 15 dias corridos. Não inclua a etapa do ano anterior.","Validação")|Out-Null;return}
        $aqFim=Parse-Date ([string]$r.aquisitivo_fim)
        if($ini -le $aqFim){[Windows.Forms.MessageBox]::Show("As férias devem começar após o término do período aquisitivo.","Validação")|Out-Null;return}
        if([string]::IsNullOrWhiteSpace($mot.Text)){[Windows.Forms.MessageBox]::Show("Informe a justificativa e a origem da confirmação.","Validação")|Out-Null;return}
        $i=Date-ToStore $ini; $f=Date-ToStore $fim
        if(Test-FixaSobreposta $r $i $f){[Windows.Forms.MessageBox]::Show("A data informada coincide com outra férias fixa desse aquisitivo.","Validação")|Out-Null;return}
        foreach($outro in @($script:Records | Where-Object { [int]$_.id -ne $id -and ([string]$_.matricula).Trim() -eq ([string]$r.matricula).Trim() })){
            if(Test-RegistroFixoImportado $outro){
                if(Test-FixaSobreposta $outro $i $f){[Windows.Forms.MessageBox]::Show("Há sobreposição com férias fixas de outro período aquisitivo da mesma matrícula.","Validação")|Out-Null;return}
            }
        }
        if(-not (Test-FixaLimiteAutomatico $r $i $f)){[Windows.Forms.MessageBox]::Show("O total de dias ou o número de parcelas fixas excede a regra automática. Faça conferência administrativa.","Validação")|Out-Null;return}
        $confirmar=[Windows.Forms.MessageBox]::Show("Registrar férias FIXAS de $($ini.ToString('dd/MM/yyyy')) a $($fim.ToString('dd/MM/yyyy')) ($dias dias)?`n`nO registro ficará fora das opções concorrentes.","Confirmar inclusão",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
        if($confirmar -ne [Windows.Forms.DialogResult]::Yes){return}
        $dlg.Tag=[pscustomobject]@{inicio=$i;fim=$f;motivo=$mot.Text.Trim();dias=$dias}
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK; $dlg.Close()
    })
    $resultado=$dlg.ShowDialog($form); $dados=$dlg.Tag; $dlg.Dispose()
    if($resultado -ne [Windows.Forms.DialogResult]::OK -or $null -eq $dados){return}
    try {
        if(-not (Backup-AntesAcao 'ANTES_INCLUIR_FERIAS_FIXA_MANUAL')){throw 'Backup obrigatório não confirmado. Inclusão cancelada.'}
        if(Test-RegistroFixoImportado $r){
            $adicionais=@(Get-FixasAdicionais $r)
            $adicionais += [pscustomobject]@{inicio=[string]$dados.inicio;fim=[string]$dados.fim;tipo="MANUAL";coluna="MANUAL";arquivo="CADASTRO_MANUAL";importado_em=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')}
            $r | Add-Member -NotePropertyName fixos_adicionais -NotePropertyValue @($adicionais) -Force
        } else {
            $r.fixo_inicio=[string]$dados.inicio; $r.fixo_fim=[string]$dados.fim
            $r.fixo_tipo_relatorio='MANUAL'; $r.fixo_coluna_origem='MANUAL'
            $r.fixo_importado_em=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; $r.fixo_arquivo_origem='CADASTRO_MANUAL'
            $r.ferias_bloqueadas=$true; $r.origem_planejamento='FIXA_MANUAL'; $r.bloqueio_motivo='Férias fixa confirmada manualmente'
            $r.opcao_aprovada=0
        }
        $r.fixo_observacao_ajuste=[string]$dados.motivo
        Save-Database
        Write-DiagLog "Fixa manual incluída ID=$id matricula=$($r.matricula) $($dados.inicio)..$($dados.fim) usuário=$env:USERNAME justificativa=$($dados.motivo)"
        $script:PlanejOverlapCache=@{}; $script:PlanejChefiaOverlapCache=@{}; $script:PlanejCellIndex=@{}; $script:PlanejCellIndexBuilt=@{}
        Refresh-Grid; Refresh-Dashboard; Load-Servidor ([string]$r.matricula); Load-Editor $id
        [Windows.Forms.MessageBox]::Show("Férias fixa incluída e salva com sucesso.","Sistema Férias DCE")|Out-Null
    } catch {
        Write-DiagLog "Erro na inclusão de fixa manual ID=$id" 'ERROR' $_
        try { Load-Database; Refresh-Grid; Refresh-Dashboard } catch {}
        [Windows.Forms.MessageBox]::Show("Inclusão não confirmada. Confira a base antes de tentar novamente.`n$($_.Exception.Message)","Erro de gravação")|Out-Null
    }
}

# V1.0.114 - Conversao individual e auditavel de periodo fixo em comum.
function Converter-FixaEmComum {
    if([int]$script:CurrentId -le 0){ [Windows.Forms.MessageBox]::Show("Selecione primeiro um período aquisitivo.","Converter fixa") | Out-Null; return }
    $id=[int]$script:CurrentId
    $r=$script:Records | Where-Object { [int]$_.id -eq $id } | Select-Object -First 1
    if($null -eq $r -or -not (Test-RegistroFixoImportado $r)){
        [Windows.Forms.MessageBox]::Show("O período selecionado não contém férias FIXAS com datas válidas.","Converter fixa") | Out-Null; return
    }
    if(@(Get-FixasAdicionais $r).Count -gt 0){
        [Windows.Forms.MessageBox]::Show("Este período tem parcelas fixas adicionais. Faça conferência administrativa antes da conversão para evitar perda de parcelas.","Conversão bloqueada") | Out-Null; return
    }
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text='Converter férias FIXAS em COMUNS'; $dlg.Size=New-Object Drawing.Size(610,365)
    $dlg.StartPosition='CenterParent'; $dlg.FormBorderStyle='FixedDialog'; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $cab=New-Object Windows.Forms.Label; $cab.Location=New-Object Drawing.Point(18,14); $cab.Size=New-Object Drawing.Size(565,66)
    $cab.Text="Servidor: $($r.nome) | Matrícula: $($r.matricula)`r`nAquisitivo: $(Date-ToBR ([string]$r.aquisitivo_inicio)) a $(Date-ToBR ([string]$r.aquisitivo_fim))`r`nFixa atual: $(Date-ToBR ([string]$r.fixo_inicio)) a $(Date-ToBR ([string]$r.fixo_fim))"
    $dlg.Controls.Add($cab)
    $aviso=New-Object Windows.Forms.Label; $aviso.Location=New-Object Drawing.Point(18,90); $aviso.Size=New-Object Drawing.Size(565,60)
    $aviso.Text='A confirmação remove SOMENTE o compromisso fixo deste aquisitivo. O cadastro permanece e as opções atuais serão zeradas para preencher 30 dias ou 15+15 novamente. A capacidade mensal será recalculada.'
    $dlg.Controls.Add($aviso)
    $dlg.Controls.Add((New-Label 'Motivo obrigatório da conversão' 18 160 460 22))
    $mot=New-Object Windows.Forms.TextBox; $mot.Location=New-Object Drawing.Point(18,185); $mot.Size=New-Object Drawing.Size(560,65); $mot.Multiline=$true; $mot.MaxLength=500; $dlg.Controls.Add($mot)
    $ok=New-Button 'Confirmar conversão' 255 267 175 36; $cancel=New-Button 'Cancelar' 445 267 130 36
    $dlg.Controls.Add($ok); $dlg.Controls.Add($cancel)
    $cancel.add_Click({$dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel;$dlg.Close()})
    $ok.add_Click({
        if([string]::IsNullOrWhiteSpace($mot.Text.Trim())){[Windows.Forms.MessageBox]::Show('Informe o motivo da conversão.','Validação')|Out-Null;return}
        $conf=[Windows.Forms.MessageBox]::Show("Converter SOMENTE o período selecionado de FIXA para COMUM?`r`n`r`nAs opções atuais serão limpas e deverão ser cadastradas novamente. Backup será criado antes da gravação.","Confirmar conversão",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
        if($conf -ne [Windows.Forms.DialogResult]::Yes){return}
        $dlg.Tag=$mot.Text.Trim();$dlg.DialogResult=[Windows.Forms.DialogResult]::OK;$dlg.Close()
    })
    $res=$dlg.ShowDialog($form); $motivo=[string]$dlg.Tag; $dlg.Dispose()
    if($res -ne [Windows.Forms.DialogResult]::OK){return}
    try {
        # O backup contém o estado original completo, inclusive datas e opções.
        $backup=Backup-AntesAcao 'ANTES_CONVERTER_FIXA_EM_COMUM'
        if(-not $backup){throw 'Backup obrigatório não criado. Operação cancelada.'}
        # Revalidar registro imediatamente antes de alterar memória.
        $r=$script:Records | Where-Object { [int]$_.id -eq $id } | Select-Object -First 1
        if($null -eq $r -or -not (Test-RegistroFixoImportado $r)){throw 'O registro deixou de ser fixo. Conversão cancelada.'}
        $antIni=[string]$r.fixo_inicio; $antFim=[string]$r.fixo_fim
        $r.ferias_bloqueadas=$false; $r.origem_planejamento='ATUAL'; $r.bloqueio_motivo=''
        foreach($chave in @('fixo_inicio','fixo_fim','fixo_tipo_relatorio','fixo_coluna_origem','fixo_importado_em','fixo_arquivo_origem','fixo_inicio_original','fixo_fim_original','fixo_ajustado_em','fixo_motivo_ajuste','fixo_observacao_ajuste','fixo_ajustado_por')){ $r.$chave='' }
        $r.fixo_ajustado=$false
        $r.opcao1=New-EmptyOptionObject; $r.opcao2=New-EmptyOptionObject; $r.opcao3=New-EmptyOptionObject
        $r.opcao_aprovada=0
        $r.justificativa_decisao="CONVERSÃO FIXA→COMUM ($(Get-Date -Format 'dd/MM/yyyy HH:mm')): $motivo | Fixa anterior: $(Date-ToBR $antIni) a $(Date-ToBR $antFim) | Usuário: $env:USERNAME"
        $r | Add-Member -NotePropertyName fixos_adicionais -NotePropertyValue @() -Force
        # Evitar restauração oculta da condição FIXA em futuras rotinas de importação.
        $r.pre_import_estado_salvo=$false
        $r.registro_criado_por_importacao_fixa=$false
        $resultado=Save-Database
        if($resultado -ne $true){throw 'Não foi possível confirmar o salvamento da conversão.'}
        Write-DiagLog "CONVERSÃO FIXA→COMUM ID=$id matrícula=$($r.matricula) anterior=$antIni..$antFim backup=$backup motivo=$motivo usuário=$env:USERNAME"
        Refresh-Grid; Refresh-Dashboard; Load-Servidor ([string]$r.matricula); Load-Editor $id
        [Windows.Forms.MessageBox]::Show('Conversão gravada com sucesso. Agora cadastre as opções de 30 dias ou 15+15 e salve-as.','Sistema Férias DCE') | Out-Null
    } catch {
        Write-DiagLog "Falha ao converter férias fixa ID=$id" 'ERROR' $_
        try { Load-Database; Refresh-Grid; Refresh-Dashboard; Load-Servidor ([string]$script:CurrentMatricula) } catch {}
        [Windows.Forms.MessageBox]::Show("Conversão não confirmada. Verifique o banco e o log.`n$($_.Exception.Message)",'Falha de conversão') | Out-Null
    }
}

# V1.0.101 - Correcao assistida dos periodos aquisitivos e acesso a ajuste protegido de fixas.
function Corrigir-PeriodoSelecionado {
    if([int]$script:CurrentId -le 0){
        [Windows.Forms.MessageBox]::Show("Selecione um periodo na grade antes de corrigir.","Corrigir periodo") | Out-Null
        return
    }
    $id=[int]$script:CurrentId
    $r=$script:Records | Where-Object { [int]$_.id -eq $id } | Select-Object -First 1
    if($null -eq $r){ [Windows.Forms.MessageBox]::Show("Registro nao encontrado.","Corrigir periodo") | Out-Null; return }

    if(Test-RegistroFixoImportado $r){
        $escolha=[Windows.Forms.MessageBox]::Show(
            "Este servidor possui ferias FIXAS importadas.`n`nSIM: corrigir as DATAS DAS FERIAS FIXAS (fluxo protegido).`nNAO: corrigir apenas o PERIODO AQUISITIVO.`nCANCELAR: nao alterar.",
            "Qual periodo deseja corrigir?",[Windows.Forms.MessageBoxButtons]::YesNoCancel,[Windows.Forms.MessageBoxIcon]::Question)
        if($escolha -eq [Windows.Forms.DialogResult]::Cancel){ return }
        if($escolha -eq [Windows.Forms.DialogResult]::Yes){
            if(Abrir-AjusteFeriasFixa $r $form){
                Refresh-Grid; Refresh-Dashboard; Load-Servidor ([string]$r.matricula)
                Load-Editor $id
            }
            return
        }
    }

    $antIni=[string]$r.aquisitivo_inicio; $antFim=[string]$r.aquisitivo_fim
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="Corrigir periodo aquisitivo"; $dlg.Size=New-Object Drawing.Size(555,365)
    $dlg.StartPosition="CenterParent"; $dlg.FormBorderStyle="FixedDialog"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $nome=New-Object Windows.Forms.Label; $nome.Text="$($r.nome) | Matricula $($r.matricula)"; $nome.Location=New-Object Drawing.Point(18,18); $nome.Size=New-Object Drawing.Size(510,38); $nome.AutoEllipsis=$true; $dlg.Controls.Add($nome)
    $dlg.Controls.Add((New-Label "Inicio do aquisitivo" 20 65 205))
    $ini=New-Object Windows.Forms.DateTimePicker; $ini.Format="Short"; $ini.Location=New-Object Drawing.Point(20,88); $ini.Width=230; $dlg.Controls.Add($ini)
    $dlg.Controls.Add((New-Label "Fim do aquisitivo" 280 65 205))
    $fim=New-Object Windows.Forms.DateTimePicker; $fim.Format="Short"; $fim.Location=New-Object Drawing.Point(280,88); $fim.Width=230; $dlg.Controls.Add($fim)
    $d1=Parse-Date $antIni; $d2=Parse-Date $antFim
    if($null -ne $d1){ $ini.Value=$d1 }
    if($null -ne $d2){ $fim.Value=$d2 }
    $info=New-Object Windows.Forms.Label; $info.Location=New-Object Drawing.Point(20,135); $info.Size=New-Object Drawing.Size(495,70)
    $info.Text="A alteracao nao apaga as opcoes nem as ferias fixas. O sistema verifica opcoes e fixas existentes, duplicidade e faz backup antes da gravacao."
    $dlg.Controls.Add($info)
    $dlg.Controls.Add((New-Label "Motivo da correcao (obrigatorio)" 20 215 290))
    $mot=New-Object Windows.Forms.TextBox; $mot.Location=New-Object Drawing.Point(20,240); $mot.Width=490; $mot.MaxLength=350; $dlg.Controls.Add($mot)
    $ok=New-Button "Confirmar correcao" 225 282 175 35; $cancel=New-Button "Cancelar" 412 282 100 35
    $dlg.Controls.Add($ok); $dlg.Controls.Add($cancel)
    $cancel.add_Click({ $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel; $dlg.Close() })
    $ok.add_Click({
        $novoIni=Date-ToStore $ini.Value.Date; $novoFim=Date-ToStore $fim.Value.Date
        if($fim.Value.Date -lt $ini.Value.Date){ [Windows.Forms.MessageBox]::Show("O fim nao pode ser anterior ao inicio.","Validacao") | Out-Null; return }
        if($novoIni -eq $antIni -and $novoFim -eq $antFim){ [Windows.Forms.MessageBox]::Show("Nenhuma data foi alterada.","Validacao") | Out-Null; return }
        if([string]::IsNullOrWhiteSpace($mot.Text)){ [Windows.Forms.MessageBox]::Show("Informe o motivo da correcao.","Validacao") | Out-Null; return }
        $dup=@($script:Records | Where-Object { [int]$_.id -ne $id -and [string]$_.matricula -eq [string]$r.matricula -and [string]$_.aquisitivo_inicio -eq $novoIni -and [string]$_.aquisitivo_fim -eq $novoFim })
        if($dup.Count -gt 0){ [Windows.Forms.MessageBox]::Show("Esse aquisitivo ja existe para a matricula.","Validacao") | Out-Null; return }
        foreach($num in 1..3){
            $op=$r.("opcao$num")
            if($null -ne $op -and -not [string]::IsNullOrWhiteSpace([string]$op.tipo)){
                $erro=Validate-Option $op "$num opcao" $novoFim
                if($erro){ [Windows.Forms.MessageBox]::Show("A correcao tornaria uma opcao existente invalida:`n$erro`n`nAjuste primeiro a opcao.","Validacao") | Out-Null; return }
            }
        }
        foreach($bloco in @(Get-OptionBlocksPlanejamento $r)){
            if((Test-RegistroFeriasBloqueadas $r) -and ([datetime]$bloco.inicio).Date -le $fim.Value.Date){
                [Windows.Forms.MessageBox]::Show("A correcao deixaria ferias fixas antes do termino do aquisitivo. Confira a fixa e o aquisitivo antes de continuar.","Validacao") | Out-Null
                return
            }
        }
        $conf=[Windows.Forms.MessageBox]::Show("Aquisitivo anterior: $(Date-ToBR $antIni) a $(Date-ToBR $antFim)`nNovo: $(Date-ToBR $novoIni) a $(Date-ToBR $novoFim)`n`nConfirmar correcao?","Confirmar",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
        if($conf -ne [Windows.Forms.DialogResult]::Yes){ return }
        $dlg.Tag=[pscustomobject]@{inicio=$novoIni;fim=$novoFim;motivo=$mot.Text.Trim()}
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK; $dlg.Close()
    })
    $res=$dlg.ShowDialog($form)
    $dados=$dlg.Tag
    $dlg.Dispose()
    if($res -ne [Windows.Forms.DialogResult]::OK -or $null -eq $dados){ return }
    try {
        [void](Backup-AntesAcao "ANTES_CORRIGIR_PERIODO_AQUISITIVO")
        $r.aquisitivo_inicio=[string]$dados.inicio
        $r.aquisitivo_fim=[string]$dados.fim
        Write-DiagLog "Correcao aquisitivo ID=$id matricula=$($r.matricula) antigo=$antIni..$antFim novo=$($dados.inicio)..$($dados.fim) usuario=$env:USERNAME motivo=$($dados.motivo)"
        Save-Database
        Refresh-Grid; Refresh-Dashboard; Load-Servidor ([string]$r.matricula)
        Load-Editor $id
        [Windows.Forms.MessageBox]::Show("Periodo aquisitivo corrigido e salvo.","Ferias DCE") | Out-Null
    } catch {
        # Reverte a alteracao em memoria para nao misturar estado nao salvo com a base.
        $r.aquisitivo_inicio=$antIni; $r.aquisitivo_fim=$antFim
        Write-DiagLog "Falha ao corrigir periodo aquisitivo ID=$id" "ERROR" $_
        [Windows.Forms.MessageBox]::Show("Falha na gravacao; alteracao nao confirmada.`n$($_.Exception.Message)","Ferias DCE") | Out-Null
    }
}

function Abrir-CadastroManualServidor {
    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="Novo servidor — cadastro manual"; $dlg.Size=New-Object Drawing.Size(650,470); $dlg.StartPosition="CenterParent"; $dlg.FormBorderStyle="FixedDialog"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
    $titulo=New-Object Windows.Forms.Label; $titulo.Text="CADASTRO MANUAL DE SERVIDOR"; $titulo.Location=New-Object Drawing.Point(20,15); $titulo.Size=New-Object Drawing.Size(400,28); $titulo.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold); $dlg.Controls.Add($titulo)
    $dlg.Controls.Add((New-Label "Matrícula" 20 60 100)); $tm=New-TextBox 20 82 180; $dlg.Controls.Add($tm)
    $dlg.Controls.Add((New-Label "Nome completo" 220 60 120)); $tn=New-TextBox 220 82 390; $dlg.Controls.Add($tn)
    $dlg.Controls.Add((New-Label "Setor" 20 126 100)); $cs=New-Combo 20 148 360 $true; foreach($x in @($script:Config.setores|Sort-Object)){[void]$cs.Items.Add($x)}; $dlg.Controls.Add($cs)
    $dlg.Controls.Add((New-Label "Período de trabalho" 400 126 150)); $cp=New-Combo 400 148 210; foreach($x in @($script:Config.periodos|Sort-Object)){[void]$cp.Items.Add($x)}; $dlg.Controls.Add($cp)
    $chk=New-Object Windows.Forms.CheckBox; $chk.Text="Cadastrar também o primeiro período aquisitivo agora"; $chk.Location=New-Object Drawing.Point(20,202); $chk.Size=New-Object Drawing.Size(380,26); $dlg.Controls.Add($chk)
    $dlg.Controls.Add((New-Label "Início aquisitivo" 20 242 120)); $di=New-Object Windows.Forms.DateTimePicker; $di.Location=New-Object Drawing.Point(20,264); $di.Size=New-Object Drawing.Size(190,26); $di.Format="Short"; $di.Enabled=$false; $dlg.Controls.Add($di)
    $dlg.Controls.Add((New-Label "Fim aquisitivo" 235 242 120)); $df=New-Object Windows.Forms.DateTimePicker; $df.Location=New-Object Drawing.Point(235,264); $df.Size=New-Object Drawing.Size(190,26); $df.Format="Short"; $df.Enabled=$false; $dlg.Controls.Add($df)
    $nota=New-Object Windows.Forms.Label; $nota.Text="Se não marcar o período aquisitivo, será criado apenas o cadastro-base do servidor. Depois você poderá usar 'Adicionar período' na própria tela de Lançamentos."; $nota.Location=New-Object Drawing.Point(20,305); $nota.Size=New-Object Drawing.Size(590,45); $nota.ForeColor=[Drawing.Color]::DimGray; $dlg.Controls.Add($nota)
    $chk.add_CheckedChanged({$di.Enabled=$chk.Checked;$df.Enabled=$chk.Checked})
    $btnOk=New-Button "CADASTRAR" 325 365 140 38; $btnOk.BackColor=[Drawing.Color]::FromArgb(205,235,205); $btnCancel=New-Button "Cancelar" 475 365 135 38; $dlg.Controls.Add($btnOk);$dlg.Controls.Add($btnCancel)
    $btnCancel.add_Click({$dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel;$dlg.Close()})
    $btnOk.add_Click({
        $mat=$tm.Text.Trim();$nome=$tn.Text.Trim();$setor=$cs.Text.Trim();$per=$cp.Text.Trim().ToUpperInvariant()
        if(-not $mat -or -not $nome -or -not $setor -or -not $per){[Windows.Forms.MessageBox]::Show("Preencha Matrícula, Nome, Setor e Período de trabalho.","Validação")|Out-Null;return}
        if(@($script:Records|Where-Object{[string]$_.matricula -eq $mat}).Count -gt 0){[Windows.Forms.MessageBox]::Show("Esta matrícula já existe no sistema. Selecione o servidor na lista para editar o cadastro ou adicionar um novo período aquisitivo.","Servidor já cadastrado")|Out-Null;return}
        $ai="";$af="";$base=$true
        if($chk.Checked){if($df.Value.Date -lt $di.Value.Date){[Windows.Forms.MessageBox]::Show("O fim do período aquisitivo não pode ser anterior ao início.","Validação")|Out-Null;return};$ai=Date-ToStore $di.Value.Date;$af=Date-ToStore $df.Value.Date;$base=$false}
        $dlg.Tag=[pscustomobject]@{mat=$mat;nome=$nome;setor=$setor;per=$per;ai=$ai;af=$af;base=$base};$dlg.DialogResult=[Windows.Forms.DialogResult]::OK;$dlg.Close()
    })
    if($dlg.ShowDialog($form) -ne [Windows.Forms.DialogResult]::OK){$dlg.Dispose();return}
    $d=$dlg.Tag;$dlg.Dispose()
    try{
        [void](Backup-AntesAcao "ANTES_CADASTRO_MANUAL_SERVIDOR")
        $novo=New-RegistroFeriasManual ([string]$d.mat) ([string]$d.nome) ([string]$d.setor) ([string]$d.per) ([string]$d.ai) ([string]$d.af) ([bool]$d.base);$script:Records += $novo
        if(Test-ServidorExcluido ([string]$d.mat)){ Remove-ServidorExcluido ([string]$d.mat) }
        if(@($script:Config.setores) -notcontains [string]$d.setor){$script:Config.setores=@(@($script:Config.setores)+[string]$d.setor|Sort-Object -Unique);Set-GrupoAnaliseSetor ([string]$d.setor) "ASSISTENCIAL"}
        if(@($script:Config.periodos) -notcontains [string]$d.per){$script:Config.periodos=@(@($script:Config.periodos)+[string]$d.per|Sort-Object -Unique)}
        Save-Database;Refresh-SetorPeriodos;Refresh-CadastrosLists
        # Facilita localizar o novo cadastro sem depender de importação em lote.
        $script:txtBusca.Text=[string]$d.mat;Refresh-Grid;Load-Servidor ([string]$d.mat)
        [Windows.Forms.MessageBox]::Show("Servidor cadastrado com sucesso.`n`nMatrícula: $($d.mat)`nNome: $($d.nome)","Férias DCE")|Out-Null
    }catch{Write-DiagLog "Falha no cadastro manual de servidor." "ERROR" $_;[Windows.Forms.MessageBox]::Show("Não foi possível cadastrar o servidor.`n$($_.Exception.Message)","Férias DCE")|Out-Null}
}

function Import-LoteFromClipboard {
    if(-not [Windows.Forms.Clipboard]::ContainsText()){
        [Windows.Forms.MessageBox]::Show("A área de transferência não contém texto.","Cadastro em lote") | Out-Null
        return
    }
    $txt=[Windows.Forms.Clipboard]::GetText()
    $lines=$txt -split "`r?`n"
    $script:gridLote.Rows.Clear()
    foreach($line in $lines){
        if([string]::IsNullOrWhiteSpace($line)){ continue }
        $parts=$line -split "`t"
        if($parts.Count -lt 4){ $parts=$line -split ";" }
        if($parts.Count -lt 4){ continue }
        $cab=Convert-ToUpperSemAcento ([string]$parts[0])
        if($cab -in @("MATRICULA","CP","CPF")){ continue }
        $idx=$script:gridLote.Rows.Add()
        $row=$script:gridLote.Rows[$idx]
        $row.Cells["lmat"].Value=$parts[0].Trim()
        $row.Cells["lnome"].Value=$parts[1].Trim()
        $row.Cells["lsetor"].Value=$parts[2].Trim()
        $row.Cells["lperiodo"].Value=$parts[3].Trim()
    }
}


function Validar-LoteServidores([bool]$silent=$false) {
    $erros=0; $validos=0
    foreach($row in $script:gridLote.Rows){
        if($row.IsNewRow){ continue }
        $mat=([string]$row.Cells["lmat"].Value).Trim()
        $nome=([string]$row.Cells["lnome"].Value).Trim()
        $setor=([string]$row.Cells["lsetor"].Value).Trim()
        $per=([string]$row.Cells["lperiodo"].Value).Trim()
        $msgs=@()
        if(-not $mat){ $msgs += "Matrícula vazia" }
        if(-not $nome){ $msgs += "Nome vazio" }
        if(-not $setor){ $msgs += "Setor vazio" }
        if(-not $per){ $msgs += "Período vazio" }
        if($msgs.Count -gt 0){
            $row.Cells["lstatus"].Value="ERRO"
            $row.Cells["lmsg"].Value=($msgs -join "; ")
            $row.DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose
            $erros++
        } else {
            $row.Cells["lstatus"].Value="OK"
            $row.Cells["lmsg"].Value="Pronto para processar"
            $row.DefaultCellStyle.BackColor=[Drawing.Color]::Honeydew
            $validos++
        }
    }
    if(-not $silent){
        [Windows.Forms.MessageBox]::Show("Validação concluída.`n`nLinhas válidas: $validos`nLinhas com erro: $erros","Cadastro em lote") | Out-Null
    }
    return ($erros -eq 0)
}

function Desfazer-UltimoLote {
    $manifestPath=[string]$script:Config.ultimo_manifesto_lote

    if([string]::IsNullOrWhiteSpace($manifestPath) -or -not (Test-Path -LiteralPath $manifestPath)){
        [Windows.Forms.MessageBox]::Show(
            "Não há um último lote com manifesto seguro disponível para desfazer.`n`nLotes criados em versões anteriores não serão restaurados automaticamente, porque isso poderia apagar alterações posteriores.",
            "Desfazer lote",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    try {
        $backupRoot=[IO.Path]::GetFullPath($script:BackupDir).TrimEnd('\') + '\'
        $manifestFull=[IO.Path]::GetFullPath($manifestPath)
        if(-not $manifestFull.StartsWith($backupRoot,[StringComparison]::OrdinalIgnoreCase)){
            throw "O manifesto de desfazer não está dentro da pasta oficial de Backups."
        }

        $manifest=(Get-Content -LiteralPath $manifestFull -Raw -Encoding UTF8 | ConvertFrom-Json)
        $mats=@($manifest.matriculas | ForEach-Object {[string]$_})
        if($mats.Count -eq 0){ throw "O manifesto não contém matrículas para restaurar." }

        $resp=[Windows.Forms.MessageBox]::Show(
            "Desfazer o último lote para $($mats.Count) matrícula(s)?`n`nSomente os servidores que participaram daquele lote serão restaurados.`nAlterações posteriores nessas mesmas matrículas serão perdidas.`nAs demais matrículas serão preservadas.`n`nUm backup do estado atual será criado antes.",
            "Desfazer último lote",
            [Windows.Forms.MessageBoxButtons]::YesNo,
            [Windows.Forms.MessageBoxIcon]::Warning
        )
        if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }

        [void](Backup-AntesAcao "ANTES_DESFAZER_LOTE")

        $matSet=New-Object 'System.Collections.Generic.HashSet[string]'
        foreach($m in $mats){ [void]$matSet.Add($m) }

        # Remove o estado atual somente das matrículas atingidas pelo lote.
        $script:Records=@($script:Records | Where-Object { -not $matSet.Contains([string]$_.matricula) })
        $script:GridPesquisaGroups=$null; $script:GridPesquisaTotais=$null

        # Recoloca os registros exatamente como estavam antes do lote.
        foreach($r in @($manifest.registros_antes)){ [void](Initialize-RecordDefaults $r); $script:Records += $r }

        # O manifesto é consumido uma única vez para impedir "voltar mais no tempo"
        # com um segundo clique acidental.
        $script:Config.ultimo_manifesto_lote=""
        $script:Config.ultimo_backup_lote=""

        Save-Database
        Refresh-SetorPeriodos
        Refresh-CadastrosLists
        Refresh-Grid
        Clear-Editor
        Refresh-Dashboard
        Refresh-PlanejamentoSetor
        Refresh-ConfigInfo

        [Windows.Forms.MessageBox]::Show(
            "Último lote desfeito com segurança.`n`nSomente as matrículas daquele lote foram restauradas.",
            "Férias DCE",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {
        try{Load-Database}catch{Write-DiagLog 'Falha ao recarregar a base após erro ao desfazer lote.' 'ERROR' $_}
        [Windows.Forms.MessageBox]::Show(
            "Não foi possível desfazer o lote.`n$($_.Exception.Message)",
            "Férias DCE",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

function Processar-LoteServidores {
    if($script:gridLote.Rows.Count -eq 0){
        [Windows.Forms.MessageBox]::Show("Não há linhas para processar.","Cadastro em lote") | Out-Null
        return
    }
    if(-not (Validar-LoteServidores $true)){ return }
    $resp=[Windows.Forms.MessageBox]::Show(
        "Confirma o processamento do lote?`n`nUm backup exclusivo será criado antes das alterações.",
        "Confirmar lote",
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Question
    )
    if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss_fff_fff"

    $dest=Backup-AntesAcao "ANTES_LOTE"
    $script:Config.ultimo_backup_lote=$dest

    # Manifesto seletivo: guarda apenas as matrículas que o lote tocará.
    $matsLote=@()
    foreach($row in $script:gridLote.Rows){
        if($row.IsNewRow){ continue }
        $m=([string]$row.Cells["lmat"].Value).Trim()
        if($m){ $matsLote += $m }
    }
    $matsLote=@($matsLote | Sort-Object -Unique)
    $matSet=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($m in $matsLote){ [void]$matSet.Add($m) }

    $regAntes=@($script:Records | Where-Object { $matSet.Contains([string]$_.matricula) })
    $manifest=[ordered]@{
        criado_em=(Get-Date).ToString("s")
        matriculas=@($matsLote)
        registros_antes=@($regAntes)
    }
    $manifestPath=Join-Path $script:BackupDir "UNDO_LOTE_$stamp.json"
    [IO.File]::WriteAllText(
        $manifestPath,
        ($manifest | ConvertTo-Json -Depth 10),
        [Text.UTF8Encoding]::new($true)
    )
    $script:Config.ultimo_manifesto_lote=$manifestPath

    $novos=0; $atualizados=0; $erros=0
    foreach($row in $script:gridLote.Rows){
        if($row.IsNewRow){ continue }
        $mat=[string]$row.Cells["lmat"].Value
        $nome=[string]$row.Cells["lnome"].Value
        $setor=[string]$row.Cells["lsetor"].Value
        $per=[string]$row.Cells["lperiodo"].Value
        $res=Apply-ServidorCadastro $mat $nome $setor $per
        $row.Cells["lstatus"].Value=$res.status
        $row.Cells["lmsg"].Value=$res.mensagem
        switch($res.status){
            "NOVO" {$novos++}
            "ATUALIZADO" {$atualizados++}
            default {$erros++}
        }
    }
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    Refresh-Grid
    Refresh-Dashboard
    Refresh-ConfigInfo
    [Windows.Forms.MessageBox]::Show(
        "Processamento concluído.`n`nNovos cadastros-base: $novos`nAtualizados: $atualizados`nErros: $erros",
        "Cadastro em lote"
    ) | Out-Null
}


$script:SomentePendencias=$false
$script:GridServidoresMarcados=@{}
$script:FiltroSetoresSelecionados=@()
$script:PlanejSetoresSelecionados=@()
$script:PlanejPeriodosSelecionados=@()
$script:PlanejGrupoSelecionado="TODOS"

function Refresh-FiltrosLancAvancados {
    if($null -ne $script:cmbFiltroGrupoAnalise){
        $old=if($script:cmbFiltroGrupoAnalise.SelectedItem){[string]$script:cmbFiltroGrupoAnalise.SelectedItem}else{"TODOS"}
        $script:cmbFiltroGrupoAnalise.Items.Clear()
        @("TODOS","ASSISTENCIAL","GERÊNCIA DE ENFERMAGEM","DIRETORIA DE ENFERMAGEM") | ForEach-Object {[void]$script:cmbFiltroGrupoAnalise.Items.Add($_)}
        $idx=$script:cmbFiltroGrupoAnalise.Items.IndexOf($old); if($idx -lt 0){$idx=0}; $script:cmbFiltroGrupoAnalise.SelectedIndex=$idx
    }
    if($null -ne $script:cmbFiltroChefia){
        $old=if($script:cmbFiltroChefia.SelectedItem){[string]$script:cmbFiltroChefia.SelectedItem}else{"TODOS"}
        $script:cmbFiltroChefia.Items.Clear(); [void]$script:cmbFiltroChefia.Items.Add("TODOS")
        foreach($g in (Get-GruposChefiaNomes)){ [void]$script:cmbFiltroChefia.Items.Add($g) }
        $idx=$script:cmbFiltroChefia.Items.IndexOf($old); if($idx -lt 0){$idx=0}; $script:cmbFiltroChefia.SelectedIndex=$idx
    }
}

function Test-RegistroTemSolicitacao($r){
    if(Test-RegistroFeriasBloqueadas $r){ return $true }
    return (-not [string]::IsNullOrWhiteSpace([string]$r.opcao1.tipo) -or -not [string]::IsNullOrWhiteSpace([string]$r.opcao2.tipo) -or -not [string]::IsNullOrWhiteSpace([string]$r.opcao3.tipo))
}

function Test-RegistroTemJustificativa($r){
    return (-not [string]::IsNullOrWhiteSpace([string]$r.justificativa_decisao) -or -not [string]::IsNullOrWhiteSpace([string]$r.fixo_observacao_ajuste))
}

function Update-PendenciasButton {
    if($null -eq $script:btnPendencias){ return }
    $pend=@($script:Records | Group-Object matricula | Where-Object {
        $recs=$_.Group
        $cad=$recs | Where-Object {
            -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or
            -not [string]::IsNullOrWhiteSpace([string]$_.periodo)
        } | Select-Object -First 1
        if(-not $cad){ $cad=$recs | Select-Object -First 1 }
        [string]::IsNullOrWhiteSpace([string]$cad.setor) -or
        [string]::IsNullOrWhiteSpace([string]$cad.periodo)
    }).Count

    if($script:SomentePendencias){
        $script:btnPendencias.Text="✓ Pendências ($pend)"
        $script:btnPendencias.BackColor=[Drawing.Color]::FromArgb(255,238,180)
    } else {
        $script:btnPendencias.Text="Pendências ($pend)"
        $script:btnPendencias.BackColor=[Drawing.Color]::FromArgb(235,241,248)
    }
}

function Update-SetoresFiltroResumo {
    if($null -eq $script:txtFiltroSetoresResumo){ return }
    if($script:FiltroSetoresSelecionados.Count -eq 0){
        $script:txtFiltroSetoresResumo.Text="TODOS OS SETORES"
    } elseif($script:FiltroSetoresSelecionados.Count -eq 1){
        $script:txtFiltroSetoresResumo.Text=$script:FiltroSetoresSelecionados[0]
    } else {
        $script:txtFiltroSetoresResumo.Text="$($script:FiltroSetoresSelecionados.Count) SETORES SELECIONADOS"
    }
}

function Selecionar-MultiplosSetores {
    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Selecionar setores para o filtro"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(480,600)
    $dlg.MinimizeBox=$false
    $dlg.MaximizeBox=$false
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $lbl=New-Object Windows.Forms.Label
    $lbl.Text="Marque um ou mais setores. Nenhum marcado = TODOS."
    $lbl.Location=New-Object Drawing.Point(15,15)
    $lbl.Size=New-Object Drawing.Size(420,24)
    $dlg.Controls.Add($lbl)

    $clb=New-Object Windows.Forms.CheckedListBox
    $clb.Location=New-Object Drawing.Point(15,45)
    $clb.Size=New-Object Drawing.Size(430,445)
    $clb.CheckOnClick=$true
    foreach($setor in @($script:Config.setores | Sort-Object -Unique)){
        $idx=$clb.Items.Add($setor)
        if($script:FiltroSetoresSelecionados -contains $setor){ $clb.SetItemChecked($idx,$true) }
    }
    $dlg.Controls.Add($clb)

    $btnTodos=New-Button "Limpar / Todos" 15 505 120 32
    $dlg.Controls.Add($btnTodos)
    $btnOK=New-Button "Aplicar filtro" 250 505 110 32
    $dlg.Controls.Add($btnOK)
    $btnCancelar=New-Button "Cancelar" 365 505 80 32
    $dlg.Controls.Add($btnCancelar)

    $btnTodos.add_Click({
        for($i=0;$i -lt $clb.Items.Count;$i++){ $clb.SetItemChecked($i,$false) }
    })
    $btnOK.add_Click({
        $sel=@()
        foreach($x in $clb.CheckedItems){ $sel += [string]$x }
        $script:FiltroSetoresSelecionados=@($sel)
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $btnCancelar.add_Click({
        $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })

    [void]$dlg.ShowDialog($form)
    Update-SetoresFiltroResumo
    Refresh-Grid
}

function Get-ServidorExcluidoEntry([string]$matricula){
    $mat=([string]$matricula).Trim()
    if(-not $mat -or $null -eq $script:Config){ return $null }
    return @($script:Config.servidores_excluidos | Where-Object { ([string]$_.matricula).Trim() -eq $mat }) | Select-Object -First 1
}

function Test-ServidorExcluido([string]$matricula){
    return ($null -ne (Get-ServidorExcluidoEntry $matricula))
}

function Add-ServidorExcluido([string]$matricula,[string]$nome,[string]$setor,[string]$periodo){
    $mat=([string]$matricula).Trim()
    if(-not $mat){ return }
    $rest=@($script:Config.servidores_excluidos | Where-Object { ([string]$_.matricula).Trim() -ne $mat })
    $rest += [pscustomobject]@{
        matricula=$mat
        nome=([string]$nome).Trim()
        setor=([string]$setor).Trim()
        periodo=([string]$periodo).Trim()
        excluido_em=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        motivo='EXCLUSAO_MANUAL_LANCAMENTOS'
    }
    $script:Config.servidores_excluidos=@($rest)
}

function Remove-ServidorExcluido([string]$matricula){
    $mat=([string]$matricula).Trim()
    if(-not $mat){ return }
    $script:Config.servidores_excluidos=@($script:Config.servidores_excluidos | Where-Object { ([string]$_.matricula).Trim() -ne $mat })
}

function Atualizar-BotaoExcluidos {
    if($null -ne $script:btnServidoresExcluidos){
        $script:btnServidoresExcluidos.Text="Excluídos ($(@($script:Config.servidores_excluidos).Count))"
    }
}

function Atualizar-ResumoMarcados {
    if($null -ne $script:btnExcluirServidoresMarcados){
        $n=@($script:GridServidoresMarcados.Keys | Where-Object { [bool]$script:GridServidoresMarcados[$_] }).Count
        $script:btnExcluirServidoresMarcados.Text=if($n -gt 0){"EXCLUIR MARCADOS ($n)"}else{"Excluir marcados"}
    }
}

function Abrir-ServidoresExcluidos {
    $dlg=New-Object Windows.Forms.Form
    $dlg.Text="Servidores excluídos — bloqueio de reimportação"
    $dlg.Size=New-Object Drawing.Size(900,560)
    $dlg.StartPosition="CenterParent"
    if($script:AppIcon){$dlg.Icon=$script:AppIcon}

    $lbl=New-Object Windows.Forms.Label
    $lbl.Dock="Top"; $lbl.Height=72; $lbl.Padding=New-Object Windows.Forms.Padding(12,10,12,5)
    $lbl.Text="Estes servidores foram excluídos manualmente e não voltarão pela sincronização da planilha-base. Para reativar uma matrícula, use 'Novo servidor' e cadastre a mesma matrícula; o bloqueio será retirado automaticamente. Backups anteriores continuam preservados."
    $lbl.BackColor=[Drawing.Color]::FromArgb(255,249,225)
    $dlg.Controls.Add($lbl)

    $grid=New-Object Windows.Forms.DataGridView
    $grid.Dock="Fill"; $grid.ReadOnly=$true; $grid.AllowUserToAddRows=$false; $grid.AllowUserToDeleteRows=$false
    $grid.RowHeadersVisible=$false; $grid.SelectionMode="FullRowSelect"; $grid.MultiSelect=$false
    $grid.AutoSizeColumnsMode="Fill"; $grid.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(@('exMat','Matrícula'),@('exNome','Nome'),@('exSetor','Setor'),@('exPer','Período'),@('exData','Excluído em'))){[void]$grid.Columns.Add($c[0],$c[1])}
    $grid.Columns['exMat'].FillWeight=15; $grid.Columns['exNome'].FillWeight=35; $grid.Columns['exSetor'].FillWeight=25; $grid.Columns['exPer'].FillWeight=12; $grid.Columns['exData'].FillWeight=18
    foreach($x in @($script:Config.servidores_excluidos | Sort-Object nome,matricula)){
        $i=$grid.Rows.Add(); $row=$grid.Rows[$i]
        $row.Cells['exMat'].Value=[string]$x.matricula; $row.Cells['exNome'].Value=[string]$x.nome
        $row.Cells['exSetor'].Value=[string]$x.setor; $row.Cells['exPer'].Value=[string]$x.periodo
        $dt=[string]$x.excluido_em
        try{if($dt){$dt=([datetime]::Parse($dt)).ToString('dd/MM/yyyy HH:mm')}}catch{}
        $row.Cells['exData'].Value=$dt
    }
    $dlg.Controls.Add($grid)

    $bottom=New-Object Windows.Forms.Panel; $bottom.Dock='Bottom'; $bottom.Height=55; $dlg.Controls.Add($bottom)
    $lblQtd=New-Object Windows.Forms.Label; $lblQtd.Text="$(@($script:Config.servidores_excluidos).Count) servidor(es) bloqueado(s) contra reimportação."; $lblQtd.Location=New-Object Drawing.Point(12,16); $lblQtd.Size=New-Object Drawing.Size(520,26); $bottom.Controls.Add($lblQtd)
    $btnFechar=New-Button "Fechar" 740 10 120 34; $btnFechar.DialogResult=[Windows.Forms.DialogResult]::OK; $bottom.Controls.Add($btnFechar)
    $dlg.AcceptButton=$btnFechar
    [void]$dlg.ShowDialog($form); $dlg.Dispose()
}

function Excluir-ServidoresMarcados {
    $mats=@($script:GridServidoresMarcados.Keys | Where-Object { [bool]$script:GridServidoresMarcados[$_] } | Sort-Object -Unique)
    if($mats.Count -eq 0){
        [Windows.Forms.MessageBox]::Show("Marque pelo menos um servidor na coluna 'Excluir'.`n`nUse 'Marcar visíveis' para selecionar todos os servidores que estão no filtro atual.",'Excluir servidores',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null
        return
    }

    $alvos=@()
    foreach($m in $mats){
        $recs=@($script:Records | Where-Object { ([string]$_.matricula).Trim() -eq ([string]$m).Trim() })
        if($recs.Count -eq 0){continue}
        $cad=$recs | Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo)} | Select-Object -First 1
        if(-not $cad){$cad=$recs|Select-Object -First 1}
        $alvos += [pscustomobject]@{matricula=[string]$m;nome=[string]$cad.nome;setor=[string]$cad.setor;periodo=[string]$cad.periodo;registros=$recs.Count}
    }
    if($alvos.Count -eq 0){return}

    $qReg=($alvos|Measure-Object registros -Sum).Sum
    $qHist=0
    foreach($hh in @($script:HistoricoFerias)){ if($mats -contains ([string]$hh.matricula).Trim()){ $qHist++ } }
    $qFix=0
    foreach($rr in @($script:Records)){ if(($mats -contains ([string]$rr.matricula).Trim()) -and (Test-RegistroFeriasBloqueadas $rr)){ $qFix++ } }
    $nomes=@($alvos | Select-Object -First 12 | ForEach-Object {"• $($_.matricula) — $($_.nome) — $($_.setor)"})
    if($alvos.Count -gt 12){$nomes += "... e mais $($alvos.Count-12) servidor(es)."}
    $msg="EXCLUSÃO DE SERVIDORES DO SISTEMA`n`nSerão excluídos: $($alvos.Count) servidor(es) | $qReg período(s)/registro(s) | $qHist histórico(s)."
    if($qFix -gt 0){$msg+="`nATENÇÃO: $qFix registro(s) possuem férias fixas/bloqueadas e também serão removidos."}
    $msg+="`n`n"+($nomes -join "`n")+"`n`nEssas matrículas entrarão na lista de EXCLUÍDOS e NÃO voltarão pela sincronização da planilha-base. Um backup será criado antes. Deseja continuar?"
    $a=[Windows.Forms.MessageBox]::Show($msg,'Confirmar exclusão de servidores',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
    if($a -ne [Windows.Forms.DialogResult]::Yes){return}
    $b=[Windows.Forms.MessageBox]::Show("SEGUNDA CONFIRMAÇÃO`n`nExcluir definitivamente os $($alvos.Count) servidor(es) selecionados da base ativa?`n`nOs backups existentes serão preservados.",'Segunda confirmação',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
    if($b -ne [Windows.Forms.DialogResult]::Yes){return}

    try{
        [void](Backup-AntesAcao 'ANTES_EXCLUIR_SERVIDORES')
        foreach($aSrv in $alvos){Add-ServidorExcluido ([string]$aSrv.matricula) ([string]$aSrv.nome) ([string]$aSrv.setor) ([string]$aSrv.periodo)}
        $script:Records=@($script:Records | Where-Object { $mats -notcontains ([string]$_.matricula).Trim() })
        $script:GridPesquisaGroups=$null; $script:GridPesquisaTotais=$null
        $script:HistoricoFerias=@($script:HistoricoFerias | Where-Object { $mats -notcontains ([string]$_.matricula).Trim() })
        $script:Config.grupo_chefia_servidores=@($script:Config.grupo_chefia_servidores | Where-Object { $mats -notcontains ([string]$_.matricula).Trim() })
        $script:Config.importacao_lancamentos_anulados=@($script:Config.importacao_lancamentos_anulados | Where-Object { $mats -notcontains ([string]$_.matricula).Trim() })
        foreach($m in $mats){ if($script:HistoricoComparacaoSelecionados.ContainsKey($m)){ $script:HistoricoComparacaoSelecionados.Remove($m) } }
        if(Get-Command Rebuild-HistoricoIndex -ErrorAction SilentlyContinue){Rebuild-HistoricoIndex}
        Save-Database
        Write-DiagLog "Exclusão múltipla concluída: $($alvos.Count) servidor(es), $qReg registro(s)/período(s), $qHist histórico(s). Matrículas protegidas contra reimportação automática." "INFO"
        $script:GridServidoresMarcados=@{}
        Clear-Editor
        Refresh-SetorPeriodos; Refresh-CadastrosLists; Refresh-Grid; Refresh-Dashboard; Refresh-PlanejamentoSetor; Refresh-ConfigInfo; Refresh-HistoricoFeriasUI; Atualizar-BotaoExcluidos; Atualizar-ResumoMarcados
        [Windows.Forms.MessageBox]::Show("Exclusão concluída com segurança.`n`nServidores removidos: $($alvos.Count)`nRegistros/períodos removidos: $qReg`nHistóricos removidos: $qHist`n`nAs matrículas foram bloqueadas contra reimportação automática.",'Férias DCE',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null
    }catch{
        try{Load-Database}catch{}
        [Windows.Forms.MessageBox]::Show("Não foi possível concluir a exclusão.`n$($_.Exception.Message)`n`nA base foi recarregada para preservar a consistência.",'Férias DCE',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)|Out-Null
    }
}

function Refresh-Grid {
    $swPerf=[Diagnostics.Stopwatch]::StartNew()
    $q=$script:txtBusca.Text.Trim().ToUpperInvariant()
    $periodo=[string]$script:cmbFiltroPeriodo.SelectedItem
    $sit=if($null -ne $script:cmbFiltroSituacao -and $script:cmbFiltroSituacao.SelectedItem){[string]$script:cmbFiltroSituacao.SelectedItem}else{"TODAS"}
    $grupo=if($null -ne $script:cmbFiltroGrupoAnalise -and $script:cmbFiltroGrupoAnalise.SelectedItem){[string]$script:cmbFiltroGrupoAnalise.SelectedItem}else{"TODOS"}
    $chefia=if($null -ne $script:cmbFiltroChefia -and $script:cmbFiltroChefia.SelectedItem){[string]$script:cmbFiltroChefia.SelectedItem}else{"TODOS"}
    $sol=if($null -ne $script:cmbFiltroSolicitacao -and $script:cmbFiltroSolicitacao.SelectedItem){[string]$script:cmbFiltroSolicitacao.SelectedItem}else{"TODOS"}
    $just=if($null -ne $script:cmbFiltroJustificativa -and $script:cmbFiltroJustificativa.SelectedItem){[string]$script:cmbFiltroJustificativa.SelectedItem}else{"TODOS"}
    # V1.0.135-R2: evita custo de agrupamento e ordenacao a cada tecla.
    # Cache invalidado em gravacao e carregamento; nao altera dados persistidos.
    $script:grid.SuspendLayout()
    try {
    $script:grid.Rows.Clear()
    if($null -eq $script:GridPesquisaGroups -or $script:GridPesquisaRecordCount -ne @($script:Records).Count){
        $script:GridPesquisaRecordCount=@($script:Records).Count
        $script:GridPesquisaGroups=@($script:Records | Group-Object matricula | Sort-Object {($_.Group | Select-Object -First 1).nome})
    }
    $groups=$script:GridPesquisaGroups
    foreach($g in $groups){
        $recs=@($g.Group | Sort-Object aquisitivo_inicio)
        $r=$recs | Select-Object -First 1
        $cad=$recs | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } | Select-Object -First 1
        if($cad){ $rCad=$cad } else { $rCad=$r }

        if($q){
            $hay=("$($r.matricula) $($r.nome) $($rCad.setor) $($rCad.periodo)").ToUpperInvariant()
            if($hay -notlike "*$q*"){ continue }
        }
        if($script:FiltroSetoresSelecionados.Count -gt 0 -and $script:FiltroSetoresSelecionados -notcontains [string]$rCad.setor){ continue }
        if($periodo -and $periodo -ne "TODOS" -and [string]$rCad.periodo -ne $periodo){ continue }
        if($script:SomentePendencias -and -not ([string]::IsNullOrWhiteSpace([string]$rCad.setor) -or [string]::IsNullOrWhiteSpace([string]$rCad.periodo))){ continue }

        if($grupo -ne "TODOS" -and (Get-GrupoAnaliseSetor ([string]$rCad.setor)) -ne $grupo){ continue }
        if($chefia -ne "TODOS" -and (Get-GrupoChefiaEfetivaRegistro $rCad) -ne $chefia){ continue }

        $statuses=@($recs | ForEach-Object { Get-StatusExibicaoRegistro $_ })
        if($sit -ne "TODAS"){
            $ok=$false
            switch($sit){
                "PENDENTES" { $ok=($statuses -contains "PENDENTE") }
                "ACEITAS" { $ok=($statuses -contains "ACEITA") }
                "FIXAS - TODAS" { $ok=(@($statuses | Where-Object { $_ -like "FIXA*" }).Count -gt 0) }
                "FIXAS IMPORTADAS" { $ok=($statuses -contains "FIXA IMPORTADA") }
                "FIXAS AJUSTADAS" { $ok=($statuses -contains "FIXA AJUSTADA") }
                "FIXAS MANUAIS" { $ok=($statuses -contains "FIXA MANUAL") }
                "SEM DECISÃO" { $ok=(@($recs | Where-Object { -not (Test-RegistroFeriasBloqueadas $_) -and [int]$_.opcao_aprovada -le 0 }).Count -gt 0) }
                default { $ok=$true }
            }
            if(-not $ok){ continue }
        }

        $temSol=(@($recs | Where-Object { Test-RegistroTemSolicitacao $_ }).Count -gt 0)
        if($sol -eq "COM SOLICITAÇÃO" -and -not $temSol){ continue }
        if($sol -eq "SEM SOLICITAÇÃO" -and $temSol){ continue }
        $temJust=(@($recs | Where-Object { Test-RegistroTemJustificativa $_ }).Count -gt 0)
        if($just -eq "COM JUSTIFICATIVA" -and -not $temJust){ continue }
        if($just -eq "SEM JUSTIFICATIVA" -and $temJust){ continue }

        $i=$script:grid.Rows.Add()
        $row=$script:grid.Rows[$i]
        $matRow=([string]$r.matricula).Trim()
        $row.Cells["excluir"].Value=($script:GridServidoresMarcados.ContainsKey($matRow) -and [bool]$script:GridServidoresMarcados[$matRow])
        $row.Cells["formulario"].Value=($script:FormServidoresMarcados.ContainsKey($matRow) -and [bool]$script:FormServidoresMarcados[$matRow])
        $row.Cells["matricula"].Value=$r.matricula
        $row.Cells["nome"].Value=$r.nome
        $row.Cells["setor"].Value=$rCad.setor
        $row.Cells["periodo"].Value=$rCad.periodo
        # Contagem visível: somente aquisitivos com datas completas; cadastro-base permanece selecionável.
        $qtdAquisitivos=@($recs | Where-Object {
            -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -and
            -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)
        }).Count
        $row.Cells["qtdperiodos"].Value=$qtdAquisitivos
        $qtdComOpcao=@($recs | Where-Object { Test-RegistroTemSolicitacao $_ }).Count
        $row.Cells["qtdsol"].Value=$qtdComOpcao

        $statusResumo="PENDENTE"
        if($sit -eq "PENDENTES" -and $statuses -contains "PENDENTE") {
            # A linha agrupada por matricula representa a pendencia filtrada,
            # nao uma fixa/aceita pertencente a outro aquisitivo.
            $statusResumo="PENDENTE"
        }
        elseif($statuses -contains "FIXA AJUSTADA"){$statusResumo="FIXA AJUSTADA"}
        elseif(@($statuses | Where-Object {$_ -like "FIXA*"}).Count -gt 0){$statusResumo="FIXA"}
        elseif($statuses -contains "ACEITA"){$statusResumo="ACEITA"}
        $row.Cells["situacao"].Value=$statusResumo

        if($statusResumo -eq "FIXA AJUSTADA"){$row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(177,214,255)}
        elseif($statusResumo -eq "FIXA"){$row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(211,232,255)}
        elseif($statusResumo -eq "ACEITA"){$row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218)}
        elseif([string]::IsNullOrWhiteSpace([string]$rCad.setor) -or [string]::IsNullOrWhiteSpace([string]$rCad.periodo)){$row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,249,220)}
    }
    if($null -eq $script:GridPesquisaTotais){
        $totalValidos=@($script:Records | Where-Object {
            -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -and
            -not [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)
        }).Count
        $totalVazios=@($script:Records | Where-Object {
            [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_inicio) -or
            [string]::IsNullOrWhiteSpace([string]$_.aquisitivo_fim)
        }).Count
        # V1.0.90: separar compromissos fixos dos periodos de escolha.
        # Contar as parcelas adicionais individualmente, sem duplicar os cadastros-base.
        $totalFixos=0
        $totalEscolha=0
        foreach($registroContagem in @($script:Records)) {
            if(Test-RegistroFixoImportado $registroContagem) { $totalFixos++ }
            foreach($parcelaFixa in @(Get-FixasAdicionais $registroContagem)) {
                $inicioParcela=Parse-Date ([string]$parcelaFixa.inicio)
                $fimParcela=Parse-Date ([string]$parcelaFixa.fim)
                if($null -ne $inicioParcela -and $null -ne $fimParcela -and $fimParcela -ge $inicioParcela) { $totalFixos++ }
            }
            if(-not (Test-RegistroFixoImportado $registroContagem) -and
               -not [string]::IsNullOrWhiteSpace([string]$registroContagem.aquisitivo_inicio) -and
               -not [string]::IsNullOrWhiteSpace([string]$registroContagem.aquisitivo_fim)) {
                $totalEscolha++
            }
        }
        $script:GridPesquisaTotais=@{Fixos=$totalFixos;Escolha=$totalEscolha;Vazios=$totalVazios}
    }
    $totalFixos=$script:GridPesquisaTotais.Fixos
    $totalEscolha=$script:GridPesquisaTotais.Escolha
    $totalVazios=$script:GridPesquisaTotais.Vazios
    $script:lblTotal.Text="Servidores exibidos: $($script:grid.Rows.Count) | Periodos fixos: $totalFixos | Aquisitivos de escolha: $totalEscolha | Cadastros sem datas: $totalVazios"
    Update-PendenciasButton
    Atualizar-ResumoMarcados
    Atualizar-BotaoExcluidos
    } finally { $script:grid.ResumeLayout($false) }
    $swPerf.Stop()
    if($swPerf.ElapsedMilliseconds -ge 250){ Write-DiagLog "PERF Refresh-Grid: $($swPerf.ElapsedMilliseconds) ms | linhas=$($script:grid.Rows.Count)" "WARN" }
}

# V1.0.114 - Exibicao conjunta, sem alterar dados persistidos.
function Get-OptionGridResumo($op){
    if($null -eq $op){return ''}
    $comum=([string]$op.tipo).Trim()
    $temFR=(-not [string]::IsNullOrWhiteSpace([string]$op.fr_inicio)) -and (-not [string]::IsNullOrWhiteSpace([string]$op.fr_fim))
    if($comum -eq 'FR 20 DIAS'){return 'FR 20 DIAS'}
    # Legado nao comprova modalidade radiologica; preservar para revisao explicita.
    if($comum -eq '20 DIAS' -and -not $temFR){return '20 DIAS - REVISAR'}
    if($temFR){if($comum){return "$comum + FR 20 DIAS"}else{return 'FR 20 DIAS'}}
    return $comum
}
function Get-OptionGridDetalhe($op){
    if($null -eq $op){return 'Nenhuma opcao informada.'}
    $partes=New-Object 'System.Collections.Generic.List[string]'
    if(-not [string]::IsNullOrWhiteSpace([string]$op.tipo) -and [string]$op.tipo -ne 'FR 20 DIAS'){
        $comum=[string]$op.tipo
        if($comum -eq '20 DIAS' -and -not ($op.fr_inicio -and $op.fr_fim)){$comum='20 DIAS - REVISAR'}
        if($op.inicio1 -and $op.fim1){$comum += ': '+(Date-ToBR ([string]$op.inicio1))+' a '+(Date-ToBR ([string]$op.fim1))}
        if($op.inicio2 -and $op.fim2){$comum += '; 2a etapa '+(Date-ToBR ([string]$op.inicio2))+' a '+(Date-ToBR ([string]$op.fim2))}
        [void]$partes.Add($comum)
    }
    if($op.fr_inicio -and $op.fr_fim){[void]$partes.Add('FR 20 DIAS: '+(Date-ToBR ([string]$op.fr_inicio))+' a '+(Date-ToBR ([string]$op.fr_fim)))}
    if($partes.Count -eq 0){return 'Nenhuma opcao informada.'}
    return ($partes -join ' | ')
}

function Refresh-PeriodosGrid([string]$matricula){
    $script:gridPeriodos.Rows.Clear()
    if([string]::IsNullOrWhiteSpace($matricula)){ return }
    foreach($r in (Get-ServidorRecords $matricula)){
        $i=$script:gridPeriodos.Rows.Add()
        $row=$script:gridPeriodos.Rows[$i]
        $row.Cells["pid"].Value=$r.id
        if([string]::IsNullOrWhiteSpace([string]$r.aquisitivo_inicio) -or [string]::IsNullOrWhiteSpace([string]$r.aquisitivo_fim)){
            $row.Cells["paquis"].Value="CADASTRO SEM PERÍODO AQUISITIVO"
            $row.Cells["paquis"].ToolTipText="Servidor cadastrado. As datas aquisitivas ainda não foram informadas; esta linha não equivale a férias solicitadas."
        } else {
            $row.Cells["paquis"].Value="$(Date-ToBR $r.aquisitivo_inicio) a $(Date-ToBR $r.aquisitivo_fim)"
        }
        $somenteFixaImportada=Test-RegistroFixoImportado $r
        foreach($n in 1..3){
            $op=$r.("opcao$n")
            $cell=$row.Cells["pop$n"]
            if($somenteFixaImportada){
                $cell.Value=''
                $cell.ToolTipText='Férias fixas importadas não participam das opções 1ª, 2ª e 3ª. Período: '+(Get-PeriodoFixoResumo $r)
            }else{
                $cell.Value=Get-OptionGridResumo $op
                $cell.ToolTipText=Get-OptionGridDetalhe $op
            }
        }
        $row.Cells["pdef"].Value=if(Test-RegistroFixoImportado $r){'FIXA'}else{
            $nc=Get-NumeroComumConfirmada $r;$nf=Get-NumeroFRConfirmada $r
            if($nc -gt 0 -and $nf -gt 0){"C$nc/FR$nf"}elseif($nc -gt 0){"C$nc"}elseif($nf -gt 0){"FR$nf"}else{''}
        }
        $statusBase=Get-StatusPlanejamentoRegistro $r
        $status=Get-StatusExibicaoRegistro $r
        $row.Cells["pstatus"].Value=$status
        if($statusBase -eq "FIXA"){
            $row.DefaultCellStyle.BackColor=(Get-CorStatusRegistro $r)
            if(Test-RegistroFixoImportado $r){
                $row.Cells["pstatus"].ToolTipText="Férias fixa importada: $(Get-PeriodoFixoResumo $r). Compromisso protegido contra alteração/exclusão comum."
                $row.Cells["pdef"].ToolTipText=$row.Cells["pstatus"].ToolTipText
            } else {
                $row.Cells["pstatus"].ToolTipText="Férias já programadas em programação anterior. Datas/opção protegidas contra alteração."
            }
        } elseif($status -eq "ACEITA"){
            $row.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218)
        }
    }
}

function Load-Servidor([string]$matricula){
    $recs=Get-ServidorRecords $matricula
    if($recs.Count -eq 0){ return }
    $cad=$recs | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.setor) -or -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } | Select-Object -First 1
    if(-not $cad){ $cad=$recs[0] }
    $script:CurrentMatricula=[string]$cad.matricula
    $script:txtMatricula.Text=[string]$cad.matricula
    $script:txtNome.Text=[string]$cad.nome
    $script:cmbSetor.Text=[string]$cad.setor
    $idx=$script:cmbPeriodo.Items.IndexOf([string]$cad.periodo)
    if($idx -lt 0 -and -not [string]::IsNullOrWhiteSpace([string]$cad.periodo)){
        [void]$script:cmbPeriodo.Items.Add([string]$cad.periodo)
        $idx=$script:cmbPeriodo.Items.IndexOf([string]$cad.periodo)
    }
    if($idx -ge 0){$script:cmbPeriodo.SelectedIndex=$idx}else{$script:cmbPeriodo.SelectedIndex=-1}
    $script:lblEdit.Text="DADOS DO SERVIDOR"
    Refresh-PeriodosGrid $matricula
    if($script:gridPeriodos.Rows.Count -gt 0){
        $linhaPreferida=0
        $filtroSituacaoAtual=if($script:cmbFiltroSituacao -and $script:cmbFiltroSituacao.SelectedItem){[string]$script:cmbFiltroSituacao.SelectedItem}else{"TODAS"}
        if($filtroSituacaoAtual -eq "PENDENTES"){
            for($iPeriodo=0;$iPeriodo -lt $script:gridPeriodos.Rows.Count;$iPeriodo++){
                $idPeriodo=[int]$script:gridPeriodos.Rows[$iPeriodo].Cells["pid"].Value
                $registroPeriodo=$recs | Where-Object { [int]$_.id -eq $idPeriodo } | Select-Object -First 1
                if($null -ne $registroPeriodo -and (Get-StatusExibicaoRegistro $registroPeriodo) -eq "PENDENTE"){
                    $linhaPreferida=$iPeriodo
                    break
                }
            }
        }
        $script:gridPeriodos.ClearSelection()
        $script:gridPeriodos.Rows[$linhaPreferida].Selected=$true
        Load-Editor ([int]$script:gridPeriodos.Rows[$linhaPreferida].Cells["pid"].Value)
    }
}

function Set-OptionEditEnabled($o,[bool]$enabled){
    if($null -eq $o){ return }
    $o.Tipo.Enabled=$enabled
    $o.I1.Enabled=$enabled
    $o.F1.Enabled=$enabled
    $o.I2.Enabled=$enabled
    $o.F2.Enabled=$enabled
    if($enabled){ Configure-OptionControls $o }
}

function Set-EditorBloqueioState {
    if($null -eq $script:chkFeriasBloqueadas){ return }

    $marcada=[bool]$script:chkFeriasBloqueadas.Checked
    $persistida=$false
    if([int]$script:CurrentId -gt 0){
        $rAtual=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
        if($null -ne $rAtual){ $persistida=Test-RegistroFeriasBloqueadas $rAtual }
    }

    # Se o usuário acabou de marcar uma férias atual como fixa, ele ainda precisa
    # conseguir salvar. A proteção total passa a valer depois da gravação.
    $protegida=($marcada -and $persistida)
    $fixaImportada=$false
    if([int]$script:CurrentId -gt 0){
        $rAtual=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
        if($null -ne $rAtual){ $fixaImportada=Test-RegistroFixoImportado $rAtual }
    }

    # Compromisso vindo da planilha de períodos já definidos não pode ser liberado pela tela comum.
    if($null -ne $script:chkFeriasBloqueadas){ $script:chkFeriasBloqueadas.Enabled=(-not $fixaImportada) }

    Set-OptionEditEnabled $script:Opt1 (-not $protegida)
    Set-OptionEditEnabled $script:Opt2 (-not $protegida)
    Set-OptionEditEnabled $script:Opt3 (-not $protegida)

    if($null -ne $script:cmbAprov){ $script:cmbAprov.Enabled=(-not $protegida) }
    if($null -ne $btnSalvar){ $btnSalvar.Enabled=(-not $protegida) }
    if($null -ne $btnExcluirPeriodo){ $btnExcluirPeriodo.Enabled=(-not $protegida) }

    if($null -ne $script:lblBloqueioInfo){
        if($protegida){
            if($fixaImportada){
                $rF=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
                $script:lblBloqueioInfo.Text="$(Get-RotuloEtapaFixa $rF)`r`nPeríodo fixo: $(Get-PeriodoFixoResumo $rF) | Origem: PROGRAMAÇÃO ANTERIOR`r`nCompromisso protegido. Ajuste excepcional disponível na Central de decisão, com backup e justificativa."
            } else {
                $script:lblBloqueioInfo.Text="BLOQUEADA: férias definidas em programação anterior. Datas e opção não podem ser alteradas."
            }
            $script:lblBloqueioInfo.ForeColor=[Drawing.Color]::FromArgb(31,78,121)
            $script:lblBloqueioInfo.BackColor=[Drawing.Color]::FromArgb(221,235,247)
        } elseif($marcada){
            $script:lblBloqueioInfo.Text="Será marcada como férias já programadas e ficará protegida após salvar."
            $script:lblBloqueioInfo.ForeColor=[Drawing.Color]::FromArgb(31,78,121)
            $script:lblBloqueioInfo.BackColor=[Drawing.Color]::FromArgb(235,243,250)
        } else {
            $script:lblBloqueioInfo.Text="Programação atual: opções podem ser analisadas e ajustadas."
            $script:lblBloqueioInfo.ForeColor=[Drawing.Color]::DimGray
            $script:lblBloqueioInfo.BackColor=[Drawing.Color]::Transparent
        }
    }
}

function Clear-PeriodEditor {
    $script:CurrentId=0
    $script:dtAqIni.Checked=$false; $script:dtAqIni.CustomFormat=" "
    $script:dtAqFim.Checked=$false; $script:dtAqFim.CustomFormat=" "
    Set-OptionControls $script:Opt1 $null; Set-OptionControls $script:Opt2 $null; Set-OptionControls $script:Opt3 $null
    $script:cmbAprov.SelectedIndex=0; $script:txtObs.Text=""; if($null -ne $script:txtJustificativaDecisao){$script:txtJustificativaDecisao.Clear()}
    if($null -ne $script:chkFeriasBloqueadas){
        $script:CarregandoBloqueio=$true
        $script:chkFeriasBloqueadas.Checked=$false
        $script:CarregandoBloqueio=$false
    }
    Set-EditorBloqueioState
    Refresh-PreviaImpacto
    $script:lblPeriodoSelecionado.Text="Selecione um período aquisitivo."
}


function Excluir-PeriodoSelecionado {
    if([int]$script:CurrentId -le 0){
        [Windows.Forms.MessageBox]::Show(
            "Selecione primeiro um período aquisitivo do servidor.",
            "Excluir período",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
    if($null -eq $r){
        [Windows.Forms.MessageBox]::Show("O período selecionado não foi localizado na base.","Excluir período") | Out-Null
        return
    }

    if(Test-RegistroFeriasBloqueadas $r){
        [Windows.Forms.MessageBox]::Show(
            "Este período está marcado como FÉRIAS JÁ PROGRAMADAS / BLOQUEADAS.`n`nEle interfere no planejamento dos demais servidores, mas não pode ser excluído pela operação comum. Para corrigir um cadastro excepcional, desbloqueie-o de forma explícita na tela de Lançamentos.",
            "Período protegido",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $periodo="$(Date-ToBR ([string]$r.aquisitivo_inicio)) a $(Date-ToBR ([string]$r.aquisitivo_fim))"
    if([string]::IsNullOrWhiteSpace([string]$r.aquisitivo_inicio) -and [string]::IsNullOrWhiteSpace([string]$r.aquisitivo_fim)){
        $periodo="CADASTRO-BASE SEM PERÍODO AQUISITIVO"
    }

    $msg="Você está prestes a excluir:`n`nServidor: $($r.nome)`nMatrícula: $($r.matricula)`nPeríodo: $periodo"
    if([int]$r.origem_linha_excel -gt 0){
        $msg += "`n`nATENÇÃO: este registro veio da planilha base. Se continuar existindo nela, poderá voltar na próxima sincronização."
    }

    $a=[Windows.Forms.MessageBox]::Show(
        $msg + "`n`nDeseja continuar?",
        "Confirmar exclusão",
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning
    )
    if($a -ne [Windows.Forms.DialogResult]::Yes){ return }

    $b=[Windows.Forms.MessageBox]::Show(
        "Confirma definitivamente a exclusão deste período aquisitivo?`n`nUm backup será criado antes da exclusão.",
        "Segunda confirmação",
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning
    )
    if($b -ne [Windows.Forms.DialogResult]::Yes){ return }

    try {
        [void](Backup-AntesAcao "ANTES_EXCLUIR_PERIODO")

        $mat=[string]$r.matricula
        $script:Records=@($script:Records | Where-Object {[int]$_.id -ne [int]$script:CurrentId})
        $script:GridPesquisaGroups=$null; $script:GridPesquisaTotais=$null
        Save-Database
        $script:CurrentId=0
        Refresh-SetorPeriodos
        Refresh-CadastrosLists
        Refresh-Grid
        Refresh-Dashboard
        Refresh-ConfigInfo

        # Recarrega o servidor se ainda houver outros períodos.
        if(@($script:Records | Where-Object {[string]$_.matricula -eq $mat}).Count -gt 0){
            Load-Servidor $mat
        } else {
            Clear-Editor
        }

        [Windows.Forms.MessageBox]::Show(
            "Período excluído com segurança.",
            "Férias DCE",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show(
            "Não foi possível excluir o período.`n$($_.Exception.Message)",
            "Férias DCE",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

function Clear-Editor {
    $script:CurrentId=0; $script:CurrentMatricula=""
    $script:txtMatricula.Text=""; $script:txtNome.Text=""; $script:cmbSetor.Text=""; $script:cmbPeriodo.SelectedIndex=-1; if($null -ne $script:txtJustificativaDecisao){$script:txtJustificativaDecisao.Clear()}
    if($script:gridPeriodos){$script:gridPeriodos.Rows.Clear()}
    Clear-PeriodEditor
    $script:lblEdit.Text="SELECIONE UM SERVIDOR"
}

function Load-Editor([int]$id){
    $r=$script:Records | Where-Object {[int]$_.id -eq $id} | Select-Object -First 1
    if($null -eq $r){ return }

    $anteriorSuppress=$script:SuppressReactiveRefresh
    $script:SuppressReactiveRefresh=$true
    try {
        $script:CurrentId=$id
        $script:CurrentMatricula=[string]$r.matricula
        $script:txtMatricula.Text=[string]$r.matricula; $script:txtNome.Text=[string]$r.nome
        # O periodo de trabalho pertence ao cadastro da matricula, nao ao aquisitivo selecionado.
        # DropDownList nao aceita texto livre: selecionar um item realmente existente.
        $cadAtual=@(Get-ServidorRecords ([string]$r.matricula) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } | Select-Object -First 1)
        $periodoAtual=if($cadAtual.Count -gt 0){([string]$cadAtual[0].periodo).Trim()}else{([string]$r.periodo).Trim()}
        if(-not [string]::IsNullOrWhiteSpace($periodoAtual)){
            $indicePeriodo=$script:cmbPeriodo.FindStringExact($periodoAtual)
            if($indicePeriodo -lt 0){[void]$script:cmbPeriodo.Items.Add($periodoAtual);$indicePeriodo=$script:cmbPeriodo.FindStringExact($periodoAtual)}
            if($indicePeriodo -ge 0){$script:cmbPeriodo.SelectedIndex=$indicePeriodo}
        }
        if([string]::IsNullOrWhiteSpace([string]$r.aquisitivo_inicio) -or [string]::IsNullOrWhiteSpace([string]$r.aquisitivo_fim)){
            $script:lblPeriodoSelecionado.Text="Cadastro sem período aquisitivo informado."
        } else {
            $script:lblPeriodoSelecionado.Text="Período selecionado: $(Date-ToBR $r.aquisitivo_inicio) a $(Date-ToBR $r.aquisitivo_fim)"
            if(Test-RegistroFixoImportado $r){
                $script:lblPeriodoSelecionado.Text += " | FIXA: $(Get-PeriodoFixoResumo $r)"
            }
        }
        Set-DatePicker $script:dtAqIni ([string]$r.aquisitivo_inicio); Set-DatePicker $script:dtAqFim ([string]$r.aquisitivo_fim)
        # Fixa importada tem período confirmado, nunca alternativas de escolha.
        # A limpeza abaixo é apenas visual: não modifica opções do JSON.
        if(Test-RegistroFixoImportado $r){
            $vazioFixa=New-EmptyOptionObject
            Set-OptionControls $script:Opt1 $vazioFixa
            Set-OptionControls $script:Opt2 $vazioFixa
            Set-OptionControls $script:Opt3 $vazioFixa
        }else{
            Set-OptionControls $script:Opt1 $r.opcao1
            Set-OptionControls $script:Opt2 $r.opcao2
            Set-OptionControls $script:Opt3 $r.opcao3
        }
        $ap=[int]$r.opcao_aprovada; if($ap -ge 0 -and $ap -le 3){$script:cmbAprov.SelectedIndex=$ap}else{$script:cmbAprov.SelectedIndex=0}
        $script:txtObs.Text=[string]$r.observacoes
        if($null -ne $script:txtJustificativaDecisao){ $script:txtJustificativaDecisao.Text=[string]$r.justificativa_decisao }

        $script:CarregandoBloqueio=$true
        $script:chkFeriasBloqueadas.Checked=(Test-RegistroFeriasBloqueadas $r)
        $script:CarregandoBloqueio=$false
        Set-EditorBloqueioState
    } finally {
        $script:SuppressReactiveRefresh=$anteriorSuppress
    }

    # V127: adiamento da prévia ate concluir o clique/repintura do editor.
    Request-PreviaImpacto
}

function Save-ServidorCadastro {
    $mat=$script:txtMatricula.Text.Trim()
    $nome=$script:txtNome.Text.Trim()
    $setor=$script:cmbSetor.Text.Trim()
    $per=[string]$script:cmbPeriodo.Text
    if(-not $mat -or -not $nome){ [Windows.Forms.MessageBox]::Show("Selecione um servidor.","Cadastro do servidor") | Out-Null; return }
    if(-not $setor -or -not $per){ [Windows.Forms.MessageBox]::Show("Informe Setor e Período do servidor.","Cadastro do servidor") | Out-Null; return }
    $recs=Get-ServidorRecords $mat
    if($recs.Count -eq 0){ [Windows.Forms.MessageBox]::Show("Servidor não localizado na base.","Cadastro do servidor") | Out-Null; return }
    foreach($r in $recs){
        $r.nome=$nome
        $r.setor=$setor
        $r.periodo=$per
    }
    if(@($script:Config.setores) -notcontains $setor){
        $script:Config.setores=@(@($script:Config.setores)+$setor | Sort-Object -Unique)
        Set-GrupoAnaliseSetor $setor "ASSISTENCIAL"
    }
    Save-Database
    Refresh-SetorPeriodos
    Refresh-Grid
    Refresh-Dashboard
    Load-Servidor $mat
    [Windows.Forms.MessageBox]::Show("Cadastro do servidor salvo para todos os seus períodos aquisitivos.","Férias DCE") | Out-Null
}

function Save-Editor {
    if($script:CurrentId -eq 0){
        [Windows.Forms.MessageBox]::Show("Selecione um período aquisitivo do servidor.","Validação") | Out-Null
        return
    }
    $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
    if($null -eq $r){ return }

    $bloqueadaAntes=Test-RegistroFeriasBloqueadas $r
    $bloqueadaAgora=[bool]$script:chkFeriasBloqueadas.Checked

    if($bloqueadaAntes -and $bloqueadaAgora){
        [Windows.Forms.MessageBox]::Show(
            "Este período está protegido como férias já programadas.`n`nPara corrigir excepcionalmente as datas/opção, desmarque primeiro o bloqueio. O sistema pedirá confirmação e criará backup antes de salvar a alteração.",
            "Período protegido",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $mat=$script:txtMatricula.Text.Trim(); $nome=$script:txtNome.Text.Trim()
    $setor=$script:cmbSetor.Text.Trim(); $per=[string]$script:cmbPeriodo.Text
    if(-not $setor -or -not $per){ [Windows.Forms.MessageBox]::Show("Cadastre primeiro o Setor e o Período do servidor.","Validação") | Out-Null; return }

    $op1=Read-OptionFromControls $script:Opt1; $op2=Read-OptionFromControls $script:Opt2; $op3=Read-OptionFromControls $script:Opt3
    foreach($x in @(@($op1,"1ª opção"),@($op2,"2ª opção"),@($op3,"3ª opção"))){
        $err=Validate-Option $x[0] $x[1] ([string]$r.aquisitivo_fim)
        if($err){ [Windows.Forms.MessageBox]::Show($err,"Validação") | Out-Null; return }
    }

    $aceita=[int]$r.opcao_aprovada
    if($aceita -gt 0){
        $opAtual=$r.("opcao$aceita")
        $opNovo=@($null,$op1,$op2,$op3)[$aceita]
        if(((Get-OpcaoSomenteComum $opAtual) | ConvertTo-Json -Depth 10 -Compress) -ne ((Get-OpcaoSomenteComum $opNovo) | ConvertTo-Json -Depth 10 -Compress)){
            [Windows.Forms.MessageBox]::Show("Há uma opção já aprovada. Para editar suas datas, desfaça a aprovação na Central antes de salvar.","Aprovação protegida")|Out-Null
            return
        }
        $opAceita=@($null,$op1,$op2,$op3)[$aceita]
        if($null -eq $opAceita -or [string]::IsNullOrWhiteSpace([string]$opAceita.tipo)){
            [Windows.Forms.MessageBox]::Show(
                "A opção marcada como aceita está vazia. Preencha a opção ou selecione 'Não definida'.",
                "Validação",
                [Windows.Forms.MessageBoxButtons]::OK,
                [Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
        $errAceita=Validate-Option $opAceita "$(Get-OpcaoAceitaTexto $aceita)" ([string]$r.aquisitivo_fim)
        if($errAceita){
            [Windows.Forms.MessageBox]::Show($errAceita,"Validação") | Out-Null
            return
        }
    }

    $nFRProtegido=Get-NumeroFRConfirmada $r
    if($nFRProtegido -gt 0){
        $frAntes=$r.("opcao$nFRProtegido")
        $frDepois=@($null,$op1,$op2,$op3)[$nFRProtegido]
        if(([string]$frAntes.fr_inicio -ne [string]$frDepois.fr_inicio) -or ([string]$frAntes.fr_fim -ne [string]$frDepois.fr_fim)){
            [Windows.Forms.MessageBox]::Show('A FR escolhida está aprovada. Desfaça primeiro a aprovação FR na Central.','FR protegida')|Out-Null;return
        }
    }
    if($bloqueadaAgora -and $aceita -le 0){
        [Windows.Forms.MessageBox]::Show(
            "Para marcar como 'Férias já programadas / bloqueadas', defina primeiro qual opção é a férias efetivamente escolhida.`n`nSelecione 1ª, 2ª ou 3ª em 'Opção aceita'.",
            "Bloqueio da programação anterior",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    # Mudança de estado protegido recebe backup específico antes de gravar.
    if($bloqueadaAntes -ne $bloqueadaAgora -and (Test-Path $script:DbFile)){
        try { [void](Backup-AntesAcao "ANTES_ALTERAR_BLOQUEIO_FERIAS") }
        catch { return }
    }

    # Cadastro do servidor é único e se propaga para todos os períodos aquisitivos.
    foreach($sr in (Get-ServidorRecords $mat)){
        $sr.nome=$nome; $sr.setor=$setor; $sr.periodo=$per
    }

    $r.opcao1=$op1; $r.opcao2=$op2; $r.opcao3=$op3
    $r.opcao_aprovada=$aceita
    $r.observacoes=$script:txtObs.Text.Trim()
    if($null -ne $script:txtJustificativaDecisao){ $r.justificativa_decisao=$script:txtJustificativaDecisao.Text.Trim() }
    $r.ferias_bloqueadas=$bloqueadaAgora
    if($bloqueadaAgora){
        $r.origem_planejamento="PROGRAMACAO_ANTERIOR"
        $r.bloqueio_motivo="Férias definidas em programação anterior"
    } else {
        $r.origem_planejamento="ATUAL"
        $r.bloqueio_motivo=""
    }

    if(@($script:Config.setores) -notcontains $setor){
        $script:Config.setores=@(@($script:Config.setores)+$setor | Sort-Object -Unique)
        Set-GrupoAnaliseSetor $setor "ASSISTENCIAL"
    }
    Save-Database
    Refresh-SetorPeriodos; Refresh-Grid; Refresh-Dashboard; Refresh-PlanejamentoSetor
    Refresh-PeriodosGrid $mat
    Load-Editor ([int]$r.id)

    if($bloqueadaAgora){
        [Windows.Forms.MessageBox]::Show(
            "Período salvo e protegido como FÉRIAS JÁ PROGRAMADAS.`n`nEle continuará ocupando vaga e interferindo no planejamento dos demais servidores.",
            "Férias DCE",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } else {
        [Windows.Forms.MessageBox]::Show("Opções deste período aquisitivo salvas com sucesso.","Férias DCE") | Out-Null
    }
}

function New-OptionGroup([string]$title,[int]$x,[int]$y){
    $g=New-Object Windows.Forms.GroupBox
    $g.Text=$title
    $g.Location=New-Object Drawing.Point($x,$y)
    $g.Size=New-Object Drawing.Size(385,230)
    $g.Controls.Add((New-Label 'Tipo' 12 18 80 18))
    $tipo=New-Combo 12 38 365
    foreach($txt in @('','30 DIAS','15+15 DIAS','FR 20 DIAS','30 DIAS + FR 20 DIAS','20 DIAS - REVISAR')){[void]$tipo.Items.Add($txt)}
    $tipo.SelectedIndex=0;$g.Controls.Add($tipo)
    $g.Controls.Add((New-Label 'Inicio 1' 12 70 80 18));$g.Controls.Add((New-Label 'Fim 1' 158 70 80 18))
    $i1=New-DatePicker 12 90 135;$f1=New-DatePicker 158 90 135
    $g.Controls.Add($i1);$g.Controls.Add($f1)
    $day1=New-Object Windows.Forms.Label;$day1.Location=New-Object Drawing.Point(296,92);$day1.Size=New-Object Drawing.Size(78,22);$day1.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold);$g.Controls.Add($day1)
    $g.Controls.Add((New-Label 'Inicio 2' 12 115 80 18));$g.Controls.Add((New-Label 'Fim 2' 158 115 80 18))
    $i2=New-DatePicker 12 135 135;$f2=New-DatePicker 158 135 135
    $g.Controls.Add($i2);$g.Controls.Add($f2)
    $day2=New-Object Windows.Forms.Label;$day2.Location=New-Object Drawing.Point(296,137);$day2.Size=New-Object Drawing.Size(78,22);$day2.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold);$g.Controls.Add($day2)
    $frl1=New-Label 'Inicio FR 20 dias' 12 164 140 18
    $frl2=New-Label 'Fim FR 20 dias' 158 164 140 18
    $fri=New-DatePicker 12 184 135;$frf=New-DatePicker 158 184 135
    foreach($control in @($frl1,$frl2,$fri,$frf)){$g.Controls.Add($control)}
    $tipDia=New-Object Windows.Forms.ToolTip
    $o=[pscustomobject]@{Group=$g;Tipo=$tipo;I1=$i1;F1=$f1;I2=$i2;F2=$f2;FRI=$fri;FRF=$frf;FRL1=$frl1;FRL2=$frl2;Day1=$day1;Day2=$day2;Tip=$tipDia;FRInicio='';FRFim='';FRSummary=$null;FRBtn=$null;FRTab=$null;Loading=$false;LastType=''}
    $fnConfigure=${function:Configure-OptionControls}
    $fnAutoEnd=${function:Auto-End}
    $fnUpdateDay=${function:Update-OptionDayInfo}
    $tipo.add_SelectedIndexChanged(({
        if(-not $o.Loading){
            $old=[string]$o.LastType;$new=[string]$tipo.SelectedItem
            if($old -ne $new -and $old){
                $hadFR=($o.FRI.Checked -or $o.FRF.Checked)
                $droppingFR=($old -like '* + FR 20 DIAS') -and ($new -notlike '* + FR 20 DIAS')
                if($hadFR -and $droppingFR){
                    $ans=[Windows.Forms.MessageBox]::Show('Esta opcao contem datas de FR. Alterar o tipo pode remover estas datas ao salvar. Deseja realmente continuar?','Alteracao de modalidade',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
                    if($ans -ne [Windows.Forms.DialogResult]::Yes){$o.Loading=$true;try{$tipo.SelectedItem=$old}finally{$o.Loading=$false};return}
                }
            }
        }
        $o.LastType=[string]$tipo.SelectedItem
        & $fnConfigure $o;& $fnUpdateDay $o
    }).GetNewClosure())
    $i1.add_ValueChanged(({if($i1.Checked){& $fnAutoEnd $o 1};& $fnUpdateDay $o}).GetNewClosure())
    $i2.add_ValueChanged(({if($i2.Checked){& $fnAutoEnd $o 2};& $fnUpdateDay $o}).GetNewClosure())
    $fri.add_ValueChanged(({if($fri.Checked){$frf.Value=$fri.Value.AddDays(19);$frf.Checked=$true}}).GetNewClosure())
    & $fnConfigure $o;& $fnUpdateDay $o
    return $o
}

function Count-BlocksForMonth($rec,[int]$n,[datetime]$ms,[datetime]$me,[string]$kind){
    $blocks=Get-OptionBlocks $rec $n
    $count=0
    foreach($b in $blocks){
        if(-not (Test-Overlap $b.inicio $b.fim $ms $me)){ continue }
        if($kind -eq "15 DIAS"){
            if($b.tipo -eq "15+15 DIAS"){ $count++ }
        } elseif($kind -eq 'FR 20 DIAS'){
            if($b.bloco -eq 3 -and $b.tipo -eq '20 DIAS'){ $count++ }
        } elseif($kind -eq '20 DIAS - REVISAR'){
            # Registro legado com 20 dias comuns sem fr_inicio/fr_fim: nao e FR confirmada.
            if($b.bloco -eq 1 -and $b.tipo -eq '20 DIAS'){ $count++ }
        } elseif($b.tipo -eq $kind -and $b.bloco -eq 1){ $count++ }
    }
    return $count
}

function Refresh-Dashboard {
    if($null -eq $script:cmbMes.SelectedItem){ return }
    $swPerf=[Diagnostics.Stopwatch]::StartNew()
    $month=$script:cmbMes.SelectedIndex+1
    $year=[int][string]$script:cmbAno.SelectedItem
    # .Date é obrigatório: Get-Date preserva a hora atual.
    # Sem isso, férias que terminam no dia 01 às 00:00 podem não ser
    # reconhecidas como pertencentes ao mês.
    $ms=(Get-Date -Year $year -Month $month -Day 1).Date
    $me=$ms.AddMonths(1).AddDays(-1).Date
    $setor=[string]$script:cmbDashSetor.SelectedItem
    $per=[string]$script:cmbDashPeriodo.SelectedItem

    $filtered=@($script:Records | Where-Object {
        ($setor -eq "TODOS" -or [string]$_.setor -eq $setor) -and
        ($per -eq "TODOS" -or [string]$_.periodo -eq $per)
    })
    $kinds=@("30 DIAS","FR 20 DIAS","20 DIAS - REVISAR","15 DIAS")
    $script:gridResumo.Rows.Clear()
    $grand=0
    foreach($kind in $kinds){
        $vals=@()
        foreach($n in 1..3){
            $c=0; foreach($r in $filtered){ $c += Count-BlocksForMonth $r $n $ms $me $kind }
            $vals += $c; $grand += $c
        }
        $idx=$script:gridResumo.Rows.Add()
        $rr=$script:gridResumo.Rows[$idx]
        $rr.Cells[0].Value=$kind; $rr.Cells[1].Value=$vals[0]; $rr.Cells[2].Value=$vals[1]; $rr.Cells[3].Value=$vals[2]; $rr.Cells[4].Value=($vals|Measure-Object -Sum).Sum
    }

    $unique=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($r in $filtered){
        foreach($n in 1..3){
            foreach($b in (Get-OptionBlocks $r $n)){ if(Test-Overlap $b.inicio $b.fim $ms $me){ [void]$unique.Add("$($r.matricula)") } }
        }
    }
    # As modalidades com 20 dias legados sao apenas pendencias de conferencia;
    # nao entram como FR confirmada no total demonstrativo.
    $pendencias20=0
    foreach($r in $filtered){foreach($n in 1..3){$pendencias20 += Count-BlocksForMonth $r $n $ms $me '20 DIAS - REVISAR'}}
    $grand -= $pendencias20
    $script:lblCardTotal.Text="$grand`nOCORRÊNCIAS"
    $script:lblCardServ.Text="$($unique.Count)`nSERVIDORES"
    $pend=@($script:Records | Group-Object matricula | Where-Object { $g=$_.Group; -not ($g | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.setor) -and -not [string]::IsNullOrWhiteSpace([string]$_.periodo) } | Select-Object -First 1) }).Count
    $script:lblCardPend.Text="$pend`nCADASTROS PENDENTES"

    $script:gridDia.Rows.Clear()
    $mode=[string]$script:cmbAnalise.SelectedItem
    for($day=$ms.Date; $day -le $me.Date; $day=$day.AddDays(1)){
        $counts=@{M=0;V=0;N=0;D=0;OUTRO=0;SP=0}
        $total=0
        foreach($r in $filtered){
            $n=0
            if($mode -eq "1ª OPÇÃO"){$n=1}elseif($mode -eq "2ª OPÇÃO"){$n=2}elseif($mode -eq "3ª OPÇÃO"){$n=3}elseif($mode -eq "OPÇÃO DEFINIDA"){$n=[int]$r.opcao_aprovada}
            $blocosDia=@()
            if($mode -eq 'OPÇÃO DEFINIDA'){$blocosDia=@(Get-BlocosConfirmadosRegistro $r)}
            elseif($n -ge 1 -and $n -le 3){$blocosDia=@(Get-OptionBlocks $r $n)}
            else{continue}
            $active=$false
            foreach($b in $blocosDia){ if($day -ge $b.inicio -and $day -le $b.fim){$active=$true;break} }
            if($active){
                $total++
                $rp=([string]$r.periodo).Trim()
                if([string]::IsNullOrWhiteSpace($rp)){
                    $counts["SP"]++
                } else {
                    $cat=Get-PeriodoCategoria $rp
                    if($cat -in @("M","V","N","D")){ $counts[$cat]++ } else { $counts["OUTRO"]++ }
                }
            }
        }
        $i=$script:gridDia.Rows.Add()
        $row=$script:gridDia.Rows[$i]
        $row.Cells["dia"].Value=$day.ToString("dd/MM")
        $row.Cells["m"].Value=$counts["M"]
        $row.Cells["v"].Value=$counts["V"]
        $row.Cells["n"].Value=$counts["N"]
        $row.Cells["d"].Value=$counts["D"]
        $row.Cells["outro"].Value=$counts["OUTRO"]
        $row.Cells["sp"].Value=$counts["SP"]
        $row.Cells["tot"].Value=$total
        $somaPeriodo=$counts["M"]+$counts["V"]+$counts["N"]+$counts["D"]+$counts["OUTRO"]+$counts["SP"]
        if($somaPeriodo -ne $total){
            $row.DefaultCellStyle.BackColor=[Drawing.Color]::LightSalmon
            $row.Cells["tot"].ToolTipText="Inconsistência interna: soma por período diferente do Total."
        }
    }
    $swPerf.Stop()
    if($swPerf.ElapsedMilliseconds -ge 250){ Write-DiagLog "PERF Refresh-Dashboard: $($swPerf.ElapsedMilliseconds) ms | mês=$month/$year" "WARN" }
}

function Export-DashboardCsv {
    $dlg=New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter="Arquivo CSV (*.csv)|*.csv"; $dlg.FileName="Resumo_Ferias_$($script:cmbAno.SelectedItem)_$($script:cmbMes.SelectedItem).csv"
    if($dlg.ShowDialog() -ne [Windows.Forms.DialogResult]::OK){ return }
    $lines=New-Object System.Collections.Generic.List[string]
    $lines.Add("TIPO;1_OPCAO;2_OPCAO;3_OPCAO;TOTAL")
    foreach($row in $script:gridResumo.Rows){
        if($row.IsNewRow){continue}
        $lines.Add("$($row.Cells[0].Value);$($row.Cells[1].Value);$($row.Cells[2].Value);$($row.Cells[3].Value);$($row.Cells[4].Value)")
    }
    $lines.Add("")
    $lines.Add("DIA;M;V;N;D;OUTRO;SEM_PERIODO;TOTAL")
    foreach($row in $script:gridDia.Rows){
        if($row.IsNewRow){continue}
        $lines.Add("$($row.Cells['dia'].Value);$($row.Cells['m'].Value);$($row.Cells['v'].Value);$($row.Cells['n'].Value);$($row.Cells['d'].Value);$($row.Cells['outro'].Value);$($row.Cells['sp'].Value);$($row.Cells['tot'].Value)")
    }
    [IO.File]::WriteAllLines($dlg.FileName,$lines,[Text.Encoding]::UTF8)
    [Windows.Forms.MessageBox]::Show("Arquivo exportado com sucesso.","Férias DCE") | Out-Null
}

$script:StartupPhase="START_LOAD"
Write-DiagLog "FASE 1/5 - chamando Load-Database."
Load-Database
Write-DiagLog "FASE 1/5 concluída."

$script:StartupPhase="BUILD_UI"
Write-DiagLog "FASE 2/5 - construindo interface principal."
$form=New-Object Windows.Forms.Form
Apply-AppBranding $form
$form.Text="Planejamento de Férias DCE 2027/2028 - V1.0.136-R3 | HIST-R3"
$form.Size=New-Object Drawing.Size(1320,700); $form.StartPosition="CenterScreen"; $form.MinimumSize=New-Object Drawing.Size(1180,650)
$form.WindowState=[Windows.Forms.FormWindowState]::Maximized
Write-DiagLog "V1.0.90: exclusão múltipla segura de servidores na grade de Lançamentos, lista persistente de excluídos para impedir reimportação automática e opção de liberar reimportação. Gravação UNC/SMB e histórico preservados."
$form.Font=New-Object Drawing.Font("Segoe UI",9)

$tabs=New-Object Windows.Forms.TabControl; $tabs.Dock="Fill"
$tabDash=New-Object Windows.Forms.TabPage; $tabDash.Text="Painel Mensal"
$tabLanc=New-Object Windows.Forms.TabPage; $tabLanc.Text="Lançamentos"; $tabLanc.AutoScroll=$true
$tabCfg=New-Object Windows.Forms.TabPage; $tabCfg.Text="Configurações"; $tabCfg.AutoScroll=$true
$tabSetores=New-Object Windows.Forms.TabPage; $tabSetores.Text="Cadastros"
$tabLote=New-Object Windows.Forms.TabPage; $tabLote.Text="Cadastro em Lote"
$tabPlanejSetor=New-Object Windows.Forms.TabPage; $tabPlanejSetor.Text="Planejamento por Setor"; $tabPlanejSetor.AutoScroll=$true
$tabHistorico=New-Object Windows.Forms.TabPage; $tabHistorico.Text="Histórico de Férias"
$tabFormularios=New-Object Windows.Forms.TabPage; $tabFormularios.Text="Formulários de Férias"; $tabFormularios.AutoScroll=$true
$tabs.TabPages.AddRange(@($tabDash,$tabLanc,$tabPlanejSetor,$tabHistorico,$tabFormularios,$tabSetores,$tabLote,$tabCfg)); $form.Controls.Add($tabs)
$script:tabsPrincipal=$tabs; $script:tabPlanejamentoPrincipal=$tabPlanejSetor; $script:PlanejRefreshDirty=$true

# --- HISTÓRICO DE FÉRIAS / COMPARAÇÃO ---
# V1.0.90: interface simplificada para decisão. A tela prioriza leitura rápida:
# servidor selecionado -> cartões -> mapa dos anos importados -> histórico detalhado.
# Verde = 15+ dias no mês; amarelo = 1 a 14 dias; cinza = sem registro no mês; ? = ano sem dados.
$histRoot=New-Object Windows.Forms.TableLayoutPanel
$histRoot.Dock="Fill"; $histRoot.ColumnCount=1; $histRoot.RowCount=2; $histRoot.Margin=New-Object Windows.Forms.Padding(0)
$histRoot.ColumnStyles.Clear(); $histRoot.RowStyles.Clear()
$csHistRoot=New-Object Windows.Forms.ColumnStyle; $csHistRoot.SizeType=[Windows.Forms.SizeType]::Percent; $csHistRoot.Width=100
[void]$histRoot.ColumnStyles.Add($csHistRoot)
$rsHistTop=New-Object Windows.Forms.RowStyle; $rsHistTop.SizeType=[Windows.Forms.SizeType]::Absolute; $rsHistTop.Height=105
$rsHistBody=New-Object Windows.Forms.RowStyle; $rsHistBody.SizeType=[Windows.Forms.SizeType]::Percent; $rsHistBody.Height=100
[void]$histRoot.RowStyles.Add($rsHistTop); [void]$histRoot.RowStyles.Add($rsHistBody)
$tabHistorico.Controls.Add($histRoot)

# Faixa superior de filtros.
$histTop=New-Object Windows.Forms.Panel
$histTop.Dock="Fill"; $histTop.BackColor=[Drawing.Color]::FromArgb(242,246,251)
$histRoot.Controls.Add($histTop,0,0)

$histTop.Controls.Add((New-Label "Pesquisar servidor (nome ou matrícula)" 15 7 245 20))
$script:txtHistBusca=New-TextBox 15 29 250
$histTop.Controls.Add($script:txtHistBusca)

$histTop.Controls.Add((New-Label "Ano histórico" 280 7 100 20))
$script:cmbHistAno=New-Combo 280 29 110
@("TODOS") | ForEach-Object { [void]$script:cmbHistAno.Items.Add($_) }
$script:cmbHistAno.SelectedIndex=0
$histTop.Controls.Add($script:cmbHistAno)

$histTop.Controls.Add((New-Label "Mês-alvo (desempate)" 405 7 160 20))
$script:cmbHistMes=New-Combo 405 29 150
[void]$script:cmbHistMes.Items.Add("TODOS")
@("Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro") | ForEach-Object { [void]$script:cmbHistMes.Items.Add($_) }
$script:cmbHistMes.SelectedIndex=0
$histTop.Controls.Add($script:cmbHistMes)

$histTop.Controls.Add((New-Label "Setor atual" 570 7 90 20))
$script:cmbHistSetor=New-Combo 570 29 220
[void]$script:cmbHistSetor.Items.Add("TODOS"); $script:cmbHistSetor.SelectedIndex=0
$histTop.Controls.Add($script:cmbHistSetor)

$histTop.Controls.Add((New-Label "Período atual" 805 7 100 20))
$script:cmbHistPeriodo=New-Combo 805 29 130
[void]$script:cmbHistPeriodo.Items.Add("TODOS"); $script:cmbHistPeriodo.SelectedIndex=0
$histTop.Controls.Add($script:cmbHistPeriodo)

$lblHistRegraTopo=New-Object Windows.Forms.Label
$lblHistRegraTopo.Location=New-Object Drawing.Point(955,7)
$lblHistRegraTopo.Size=New-Object Drawing.Size(345,48)
$lblHistRegraTopo.Text="REGRA DO DESEMPATE`r`nO mês conta somente com 15 DIAS OU MAIS de férias dentro dele."
$lblHistRegraTopo.BackColor=[Drawing.Color]::FromArgb(231,246,235)
$lblHistRegraTopo.ForeColor=[Drawing.Color]::FromArgb(31,103,60)
$lblHistRegraTopo.BorderStyle="FixedSingle"
$lblHistRegraTopo.Padding=New-Object Windows.Forms.Padding(8,4,6,2)
$lblHistRegraTopo.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$histTop.Controls.Add($lblHistRegraTopo)

$script:lblHistStatus=New-Object Windows.Forms.Label
$script:lblHistStatus.Location=New-Object Drawing.Point(15,68)
$script:lblHistStatus.Size=New-Object Drawing.Size(1280,25)
$script:lblHistStatus.Text="Histórico ainda não importado."
$script:lblHistStatus.ForeColor=[Drawing.Color]::FromArgb(45,65,85)
$script:lblHistStatus.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$histTop.Controls.Add($script:lblHistStatus)

# Corpo: servidores à esquerda, análise à direita.
$histSplit=New-Object Windows.Forms.SplitContainer
$histSplit.Dock="Fill"; $histSplit.Orientation=[Windows.Forms.Orientation]::Vertical; $histSplit.SplitterWidth=6
$histSplit.BorderStyle="FixedSingle"
$histRoot.Controls.Add($histSplit,0,1)
$histSplit.add_SizeChanged({
    try {
        if($histSplit.Width -gt 1050){
            $alvo=[int]([math]::Round($histSplit.Width*0.31))
            if($alvo -lt 420){$alvo=420}
            if($alvo -gt ($histSplit.Width-760)){$alvo=$histSplit.Width-760}
            if($alvo -gt 180 -and $alvo -lt ($histSplit.Width-180)){$histSplit.SplitterDistance=$alvo}
        }
    } catch { Write-DiagLog ("Ajuste visual SplitContainer Histórico ignorado: "+$_.Exception.Message) "WARN" }
})

# LADO ESQUERDO
$histLeftLayout=New-Object Windows.Forms.TableLayoutPanel
$histLeftLayout.Dock="Fill"; $histLeftLayout.ColumnCount=1; $histLeftLayout.RowCount=3; $histLeftLayout.Margin=New-Object Windows.Forms.Padding(0)
$cl=New-Object Windows.Forms.ColumnStyle; $cl.SizeType=[Windows.Forms.SizeType]::Percent; $cl.Width=100; [void]$histLeftLayout.ColumnStyles.Add($cl)
$rl0=New-Object Windows.Forms.RowStyle; $rl0.SizeType=[Windows.Forms.SizeType]::Absolute; $rl0.Height=38
$rl1=New-Object Windows.Forms.RowStyle; $rl1.SizeType=[Windows.Forms.SizeType]::Percent; $rl1.Height=100
$rl2=New-Object Windows.Forms.RowStyle; $rl2.SizeType=[Windows.Forms.SizeType]::Absolute; $rl2.Height=105
[void]$histLeftLayout.RowStyles.Add($rl0); [void]$histLeftLayout.RowStyles.Add($rl1); [void]$histLeftLayout.RowStyles.Add($rl2)
$histSplit.Panel1.Controls.Add($histLeftLayout)

$lblHistServidoresTitulo=New-Object Windows.Forms.Label
$lblHistServidoresTitulo.Dock="Fill"; $lblHistServidoresTitulo.Text="SERVIDORES COM HISTÓRICO — marque ✓ para comparar"
$lblHistServidoresTitulo.BackColor=[Drawing.Color]::FromArgb(42,103,171); $lblHistServidoresTitulo.ForeColor=[Drawing.Color]::White
$lblHistServidoresTitulo.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$lblHistServidoresTitulo.Padding=New-Object Windows.Forms.Padding(10,10,4,0)
$histLeftLayout.Controls.Add($lblHistServidoresTitulo,0,0)

$script:gridHistServidores=New-Object Windows.Forms.DataGridView
$script:gridHistServidores.Dock="Fill"; $script:gridHistServidores.BackgroundColor=[Drawing.Color]::White
$script:gridHistServidores.AllowUserToAddRows=$false; $script:gridHistServidores.AllowUserToDeleteRows=$false
$script:gridHistServidores.RowHeadersVisible=$false; $script:gridHistServidores.SelectionMode="FullRowSelect"
$script:gridHistServidores.MultiSelect=$false; $script:gridHistServidores.AutoSizeColumnsMode="None"
$script:gridHistServidores.ColumnHeadersVisible=$true; $script:gridHistServidores.ColumnHeadersHeight=30
$script:gridHistServidores.ColumnHeadersHeightSizeMode=[Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::DisableResizing
$script:gridHistServidores.RowTemplate.Height=27; $script:gridHistServidores.AutoSizeRowsMode=[Windows.Forms.DataGridViewAutoSizeRowsMode]::None
$script:gridHistServidores.EnableHeadersVisualStyles=$false
$script:gridHistServidores.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(230,238,248)
$script:gridHistServidores.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$script:gridHistServidores.AlternatingRowsDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(248,251,255)
Enable-GridSmooth $script:gridHistServidores
$colHsSel=New-Object Windows.Forms.DataGridViewCheckBoxColumn; $colHsSel.Name="hsSel"; $colHsSel.HeaderText="✓"; $colHsSel.Width=38
[void]$script:gridHistServidores.Columns.Add($colHsSel)
foreach($c in @(
    @("hsMat","Matrícula",92),@("hsNome","Servidor",190),@("hsSetor","Setor atual",150),@("hsPer","Per.",72),@("hsQtd","Hist.",52)
)){
    $col=New-Object Windows.Forms.DataGridViewTextBoxColumn
    $col.Name=$c[0]; $col.HeaderText=$c[1]; $col.Width=[int]$c[2]; $col.ReadOnly=$true
    [void]$script:gridHistServidores.Columns.Add($col)
}
$script:gridHistServidores.Columns["hsNome"].AutoSizeMode=[Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$script:gridHistServidores.Columns["hsNome"].MinimumWidth=145
$histLeftLayout.Controls.Add($script:gridHistServidores,0,1)

$histLeftBottom=New-Object Windows.Forms.Panel
$histLeftBottom.Dock="Fill"; $histLeftBottom.BackColor=[Drawing.Color]::FromArgb(248,250,252)
$histLeftLayout.Controls.Add($histLeftBottom,0,2)
$btnHistComparar=New-Button "COMPARAR SELECIONADOS" 10 10 185 34
$btnHistComparar.BackColor=[Drawing.Color]::FromArgb(213,232,255)
$histLeftBottom.Controls.Add($btnHistComparar)
$btnHistMarcarVisiveis=New-Button "Marcar visíveis" 205 10 120 34
$histLeftBottom.Controls.Add($btnHistMarcarVisiveis)
$btnHistLimparSelecao=New-Button "Limpar seleção" 10 54 150 32
$histLeftBottom.Controls.Add($btnHistLimparSelecao)
$lblHistDica=New-Object Windows.Forms.Label
$lblHistDica.Text="Selecione um servidor para visualizar. Para desempate, marque 2 ou mais e clique em COMPARAR."
$lblHistDica.Location=New-Object Drawing.Point(170,52); $lblHistDica.Size=New-Object Drawing.Size(305,46)
$lblHistDica.ForeColor=[Drawing.Color]::DimGray
$histLeftBottom.Controls.Add($lblHistDica)

# LADO DIREITO
$histRightTabs=New-Object Windows.Forms.TabControl
$histRightTabs.Dock="Fill"
$tabHistIndividual=New-Object Windows.Forms.TabPage; $tabHistIndividual.Text="Resumo do servidor"
$tabHistComparacao=New-Object Windows.Forms.TabPage; $tabHistComparacao.Text="Comparação dos selecionados"
$histRightTabs.TabPages.AddRange(@($tabHistIndividual,$tabHistComparacao))
$histSplit.Panel2.Controls.Add($histRightTabs)

# Resumo individual: cabeçalho + cartões + mapa visual + registros detalhados.
$histIndLayout=New-Object Windows.Forms.TableLayoutPanel
$histIndLayout.Dock="Fill"; $histIndLayout.ColumnCount=1; $histIndLayout.RowCount=4; $histIndLayout.Margin=New-Object Windows.Forms.Padding(0)
$ci=New-Object Windows.Forms.ColumnStyle; $ci.SizeType=[Windows.Forms.SizeType]::Percent; $ci.Width=100; [void]$histIndLayout.ColumnStyles.Add($ci)
foreach($hgt in @(58,96,165)){
    $rs=New-Object Windows.Forms.RowStyle; $rs.SizeType=[Windows.Forms.SizeType]::Absolute; $rs.Height=$hgt; [void]$histIndLayout.RowStyles.Add($rs)
}
$rsLast=New-Object Windows.Forms.RowStyle; $rsLast.SizeType=[Windows.Forms.SizeType]::Percent; $rsLast.Height=100; [void]$histIndLayout.RowStyles.Add($rsLast)
$tabHistIndividual.Controls.Add($histIndLayout)

$script:lblHistServidorDetalhe=New-Object Windows.Forms.Label
$script:lblHistServidorDetalhe.Dock="Fill"
$script:lblHistServidorDetalhe.Padding=New-Object Windows.Forms.Padding(12,8,10,4)
$script:lblHistServidorDetalhe.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$script:lblHistServidorDetalhe.Text="Selecione um servidor à esquerda para consultar o histórico."
$script:lblHistServidorDetalhe.BackColor=[Drawing.Color]::FromArgb(238,246,255)
$histIndLayout.Controls.Add($script:lblHistServidorDetalhe,0,0)

# Cartões visuais.
$histCards=New-Object Windows.Forms.TableLayoutPanel
$histCards.Dock="Fill"; $histCards.ColumnCount=4; $histCards.RowCount=1; $histCards.Padding=New-Object Windows.Forms.Padding(6,6,6,6); $histCards.Margin=New-Object Windows.Forms.Padding(0)
for($cc=0;$cc -lt 4;$cc++){ $cst=New-Object Windows.Forms.ColumnStyle; $cst.SizeType=[Windows.Forms.SizeType]::Percent; $cst.Width=25; [void]$histCards.ColumnStyles.Add($cst) }
$rst=New-Object Windows.Forms.RowStyle; $rst.SizeType=[Windows.Forms.SizeType]::Percent; $rst.Height=100; [void]$histCards.RowStyles.Add($rst)
$histIndLayout.Controls.Add($histCards,0,1)

function Add-HistoricoCard($parent,[int]$col,[string]$titulo,[Drawing.Color]$corFundo,[Drawing.Color]$corTexto){
    $p=New-Object Windows.Forms.Panel; $p.Dock="Fill"; $p.Margin=New-Object Windows.Forms.Padding(5); $p.BorderStyle="FixedSingle"; $p.BackColor=$corFundo
    $t=New-Object Windows.Forms.Label; $t.Dock="Top"; $t.Height=26; $t.Text=$titulo; $t.Padding=New-Object Windows.Forms.Padding(8,6,4,0); $t.ForeColor=$corTexto; $t.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
    $v=New-Object Windows.Forms.Label; $v.Dock="Fill"; $v.Text="—"; $v.TextAlign="MiddleLeft"; $v.Padding=New-Object Windows.Forms.Padding(10,0,6,2); $v.ForeColor=$corTexto; $v.Font=New-Object Drawing.Font("Segoe UI",13,[Drawing.FontStyle]::Bold)
    $p.Controls.Add($v); $p.Controls.Add($t); $parent.Controls.Add($p,$col,0)
    return [pscustomobject]@{Titulo=$t;Valor=$v}
}
$c1=Add-HistoricoCard $histCards 0 "REGISTROS NO HISTÓRICO" ([Drawing.Color]::FromArgb(235,245,255)) ([Drawing.Color]::FromArgb(35,91,153))
$script:lblHistCardRegistrosValor=$c1.Valor
$c2=Add-HistoricoCard $histCards 1 "MESES COM 15+ DIAS" ([Drawing.Color]::FromArgb(231,246,235)) ([Drawing.Color]::FromArgb(31,103,60))
$script:lblHistCardMeses15Valor=$c2.Valor
$c3=Add-HistoricoCard $histCards 2 "MÊS-ALVO" ([Drawing.Color]::FromArgb(255,247,224)) ([Drawing.Color]::FromArgb(142,95,0))
$script:lblHistCardMesAlvoTitulo=$c3.Titulo; $script:lblHistCardMesAlvoValor=$c3.Valor
$c4=Add-HistoricoCard $histCards 3 "ÚLTIMAS FÉRIAS" ([Drawing.Color]::FromArgb(244,238,255)) ([Drawing.Color]::FromArgb(97,55,153))
$script:lblHistCardUltimasValor=$c4.Valor

# Matriz dos anos importados x meses.
$histResumoPanel=New-Object Windows.Forms.TableLayoutPanel
$histResumoPanel.Dock="Fill"; $histResumoPanel.ColumnCount=1; $histResumoPanel.RowCount=2; $histResumoPanel.Margin=New-Object Windows.Forms.Padding(0)
$cr=New-Object Windows.Forms.ColumnStyle; $cr.SizeType=[Windows.Forms.SizeType]::Percent; $cr.Width=100; [void]$histResumoPanel.ColumnStyles.Add($cr)
$rra=New-Object Windows.Forms.RowStyle; $rra.SizeType=[Windows.Forms.SizeType]::Absolute; $rra.Height=31
$rrb=New-Object Windows.Forms.RowStyle; $rrb.SizeType=[Windows.Forms.SizeType]::Percent; $rrb.Height=100
[void]$histResumoPanel.RowStyles.Add($rra); [void]$histResumoPanel.RowStyles.Add($rrb)
$histIndLayout.Controls.Add($histResumoPanel,0,2)

$lblHistMapa=New-Object Windows.Forms.Label
$lblHistMapa.Dock="Fill"; $lblHistMapa.Text="MAPA RÁPIDO — verde = 15+ dias (CONTA)  |  amarelo = 1–14 dias (NÃO CONTA)  |  cinza = sem registro no mês; ? = ano sem dados"
$lblHistMapa.Padding=New-Object Windows.Forms.Padding(8,7,4,0); $lblHistMapa.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$lblHistMapa.ForeColor=[Drawing.Color]::FromArgb(55,70,85)
$histResumoPanel.Controls.Add($lblHistMapa,0,0)

$script:gridHistResumoMeses=New-Object Windows.Forms.DataGridView
$script:gridHistResumoMeses.Dock="Fill"; $script:gridHistResumoMeses.ReadOnly=$true; $script:gridHistResumoMeses.AllowUserToAddRows=$false; $script:gridHistResumoMeses.AllowUserToDeleteRows=$false
$script:gridHistResumoMeses.RowHeadersVisible=$false; $script:gridHistResumoMeses.SelectionMode="FullRowSelect"; $script:gridHistResumoMeses.MultiSelect=$false
$script:gridHistResumoMeses.AutoSizeColumnsMode="Fill"; $script:gridHistResumoMeses.BackgroundColor=[Drawing.Color]::White
$script:gridHistResumoMeses.ColumnHeadersHeight=26; $script:gridHistResumoMeses.RowTemplate.Height=29
$script:gridHistResumoMeses.EnableHeadersVisualStyles=$false; $script:gridHistResumoMeses.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(230,238,248)
$script:gridHistResumoMeses.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name="hrAno"; $col.HeaderText="Ano"; $col.FillWeight=52; $col.ReadOnly=$true; [void]$script:gridHistResumoMeses.Columns.Add($col)
$mesAbrev=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
for($mm=1;$mm -le 12;$mm++){ $col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name="hrM$mm"; $col.HeaderText=$mesAbrev[$mm-1]; $col.FillWeight=65; $col.ReadOnly=$true; [void]$script:gridHistResumoMeses.Columns.Add($col) }
$col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name="hrQtd"; $col.HeaderText="15+d"; $col.FillWeight=55; $col.ReadOnly=$true; [void]$script:gridHistResumoMeses.Columns.Add($col)
Enable-GridSmooth $script:gridHistResumoMeses
$histResumoPanel.Controls.Add($script:gridHistResumoMeses,0,1)

# Histórico detalhado.
$histDetalhePanel=New-Object Windows.Forms.TableLayoutPanel
$histDetalhePanel.Dock="Fill"; $histDetalhePanel.ColumnCount=1; $histDetalhePanel.RowCount=2; $histDetalhePanel.Margin=New-Object Windows.Forms.Padding(0)
$cd=New-Object Windows.Forms.ColumnStyle; $cd.SizeType=[Windows.Forms.SizeType]::Percent; $cd.Width=100; [void]$histDetalhePanel.ColumnStyles.Add($cd)
$rd1=New-Object Windows.Forms.RowStyle; $rd1.SizeType=[Windows.Forms.SizeType]::Absolute; $rd1.Height=30
$rd2=New-Object Windows.Forms.RowStyle; $rd2.SizeType=[Windows.Forms.SizeType]::Percent; $rd2.Height=100
[void]$histDetalhePanel.RowStyles.Add($rd1); [void]$histDetalhePanel.RowStyles.Add($rd2)
$histIndLayout.Controls.Add($histDetalhePanel,0,3)
$lblHistDetalheTitulo=New-Object Windows.Forms.Label; $lblHistDetalheTitulo.Dock="Fill"; $lblHistDetalheTitulo.Text="PERÍODOS DE FÉRIAS REGISTRADOS"; $lblHistDetalheTitulo.Padding=New-Object Windows.Forms.Padding(8,7,0,0); $lblHistDetalheTitulo.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$histDetalhePanel.Controls.Add($lblHistDetalheTitulo,0,0)

$script:gridHistDetalhes=New-Object Windows.Forms.DataGridView
$script:gridHistDetalhes.Dock="Fill"; $script:gridHistDetalhes.ReadOnly=$true
$script:gridHistDetalhes.AllowUserToAddRows=$false; $script:gridHistDetalhes.AllowUserToDeleteRows=$false
$script:gridHistDetalhes.RowHeadersVisible=$false; $script:gridHistDetalhes.SelectionMode="FullRowSelect"; $script:gridHistDetalhes.MultiSelect=$false
$script:gridHistDetalhes.AutoSizeColumnsMode="None"; $script:gridHistDetalhes.BackgroundColor=[Drawing.Color]::White
$script:gridHistDetalhes.ColumnHeadersVisible=$true; $script:gridHistDetalhes.ColumnHeadersHeight=30
$script:gridHistDetalhes.RowTemplate.Height=27; $script:gridHistDetalhes.AutoSizeRowsMode=[Windows.Forms.DataGridViewAutoSizeRowsMode]::None
$script:gridHistDetalhes.EnableHeadersVisualStyles=$false
$script:gridHistDetalhes.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(230,238,248)
$script:gridHistDetalhes.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$script:gridHistDetalhes.AlternatingRowsDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(248,251,255)
Enable-GridSmooth $script:gridHistDetalhes
foreach($c in @(
    @("hdAno","Ano",55),@("hdMes","Mês",110),@("hdIni","Início",88),@("hdFim","Fim",88),@("hdDias","Dias",52),@("hdTipo","Tipo",112),
    @("hdSetor","Setor na época",145),@("hdPer","Período",82),@("hdAq","Período aquisitivo",175),@("hdOrigem","Arquivo de origem",150)
)){
    $col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name=$c[0]; $col.HeaderText=$c[1]; $col.Width=[int]$c[2]; $col.ReadOnly=$true; [void]$script:gridHistDetalhes.Columns.Add($col)
}
$script:gridHistDetalhes.Columns["hdSetor"].AutoSizeMode=[Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$script:gridHistDetalhes.Columns["hdSetor"].MinimumWidth=120
$script:gridHistDetalhes.Columns["hdOrigem"].Visible=$false
$histDetalhePanel.Controls.Add($script:gridHistDetalhes,0,1)

# COMPARAÇÃO: mantém uma grade principal e uma linha do tempo de apoio.
$histCompLayout=New-Object Windows.Forms.TableLayoutPanel
$histCompLayout.Dock="Fill"; $histCompLayout.ColumnCount=1; $histCompLayout.RowCount=4; $histCompLayout.Margin=New-Object Windows.Forms.Padding(0)
$cc=New-Object Windows.Forms.ColumnStyle; $cc.SizeType=[Windows.Forms.SizeType]::Percent; $cc.Width=100; [void]$histCompLayout.ColumnStyles.Add($cc)
foreach($hgt in @(62,30)){ $rrs=New-Object Windows.Forms.RowStyle; $rrs.SizeType=[Windows.Forms.SizeType]::Absolute; $rrs.Height=$hgt; [void]$histCompLayout.RowStyles.Add($rrs) }
$rrs=New-Object Windows.Forms.RowStyle; $rrs.SizeType=[Windows.Forms.SizeType]::Percent; $rrs.Height=58; [void]$histCompLayout.RowStyles.Add($rrs)
$rrs=New-Object Windows.Forms.RowStyle; $rrs.SizeType=[Windows.Forms.SizeType]::Percent; $rrs.Height=42; [void]$histCompLayout.RowStyles.Add($rrs)
$tabHistComparacao.Controls.Add($histCompLayout)

$script:lblHistCompResumo=New-Object Windows.Forms.Label
$script:lblHistCompResumo.Dock="Fill"; $script:lblHistCompResumo.Padding=New-Object Windows.Forms.Padding(10,8,10,4)
$script:lblHistCompResumo.BackColor=[Drawing.Color]::FromArgb(238,246,255)
$script:lblHistCompResumo.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$script:lblHistCompResumo.Text="Marque servidores à esquerda para comparar."
$histCompLayout.Controls.Add($script:lblHistCompResumo,0,0)

$lblHistCompLegenda=New-Object Windows.Forms.Label
$lblHistCompLegenda.Dock="Fill"; $lblHistCompLegenda.Text="LEITURA RÁPIDA: VERDE = 15+ dias (mês utilizado) | AMARELO = 1–14 dias | CINZA = sem registro"
$lblHistCompLegenda.Padding=New-Object Windows.Forms.Padding(8,7,0,0); $lblHistCompLegenda.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$histCompLayout.Controls.Add($lblHistCompLegenda,0,1)

$script:gridHistComparacao=New-Object Windows.Forms.DataGridView
$script:gridHistComparacao.Dock="Fill"; $script:gridHistComparacao.ReadOnly=$true
$script:gridHistComparacao.AllowUserToAddRows=$false; $script:gridHistComparacao.AllowUserToDeleteRows=$false
$script:gridHistComparacao.RowHeadersVisible=$false; $script:gridHistComparacao.SelectionMode="FullRowSelect"
$script:gridHistComparacao.MultiSelect=$false; $script:gridHistComparacao.AutoSizeColumnsMode="None"; $script:gridHistComparacao.BackgroundColor=[Drawing.Color]::White
$script:gridHistComparacao.ColumnHeadersVisible=$true; $script:gridHistComparacao.ColumnHeadersHeight=31
$script:gridHistComparacao.RowTemplate.Height=28; $script:gridHistComparacao.AutoSizeRowsMode=[Windows.Forms.DataGridViewAutoSizeRowsMode]::None
$script:gridHistComparacao.EnableHeadersVisualStyles=$false
$script:gridHistComparacao.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(230,238,248)
$script:gridHistComparacao.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$script:gridHistComparacao.AlternatingRowsDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(248,251,255)
Enable-GridSmooth $script:gridHistComparacao
foreach($c in @(
    @("hcMat","Matrícula",90),@("hcNome","Servidor",190),@("hcSetor","Setor atual",135),@("hcPer","Per.",68),
    @("hcOc","Meses 15+d",85),
    @("hcUltMes","Última vez no mês",115),@("hcUlt","Últimas férias",160)
)){
    $col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name=$c[0]; $col.HeaderText=$c[1]; $col.Width=[int]$c[2]; $col.ReadOnly=$true; [void]$script:gridHistComparacao.Columns.Add($col)
}
$script:gridHistComparacao.Columns["hcNome"].AutoSizeMode=[Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$script:gridHistComparacao.Columns["hcNome"].MinimumWidth=160
$histCompLayout.Controls.Add($script:gridHistComparacao,0,2)

$script:gridHistLinhaTempo=New-Object Windows.Forms.DataGridView
$script:gridHistLinhaTempo.Dock="Fill"; $script:gridHistLinhaTempo.ReadOnly=$true
$script:gridHistLinhaTempo.AllowUserToAddRows=$false; $script:gridHistLinhaTempo.AllowUserToDeleteRows=$false
$script:gridHistLinhaTempo.RowHeadersVisible=$false; $script:gridHistLinhaTempo.SelectionMode="FullRowSelect"
$script:gridHistLinhaTempo.MultiSelect=$false; $script:gridHistLinhaTempo.AutoSizeColumnsMode="None"; $script:gridHistLinhaTempo.BackgroundColor=[Drawing.Color]::White
$script:gridHistLinhaTempo.ColumnHeadersVisible=$true; $script:gridHistLinhaTempo.ColumnHeadersHeight=27
$script:gridHistLinhaTempo.RowTemplate.Height=25; $script:gridHistLinhaTempo.EnableHeadersVisualStyles=$false
$script:gridHistLinhaTempo.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(240,244,249)
$script:gridHistLinhaTempo.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
Enable-GridSmooth $script:gridHistLinhaTempo
foreach($c in @(
    @("htNome","Servidor",185),@("htMat","Matrícula",90),@("htAno","Ano",55),@("htMes","Mês",110),
    @("htIni","Início",85),@("htFim","Fim",85),@("htDias","Dias",50),@("htSetor","Setor na época",145),@("htPer","Período",80)
)){
    $col=New-Object Windows.Forms.DataGridViewTextBoxColumn; $col.Name=$c[0]; $col.HeaderText=$c[1]; $col.Width=[int]$c[2]; $col.ReadOnly=$true; [void]$script:gridHistLinhaTempo.Columns.Add($col)
}
$histCompLayout.Controls.Add($script:gridHistLinhaTempo,0,3)

# --- PAINEL ---
$top=New-Object Windows.Forms.Panel; $top.Dock="Top"; $top.Height=62; $top.BackColor=[Drawing.Color]::FromArgb(242,246,251); $tabDash.Controls.Add($top)
$top.Controls.Add((New-Label "Ano" 15 10 50 20)); $script:cmbAno=New-Combo 15 32 85
@("2027","2028") | ForEach-Object {[void]$script:cmbAno.Items.Add($_)}; $script:cmbAno.SelectedIndex=0; $top.Controls.Add($script:cmbAno)
$top.Controls.Add((New-Label "Mês" 115 10 50 20)); $script:cmbMes=New-Combo 115 32 130
@("Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro") | ForEach-Object {[void]$script:cmbMes.Items.Add($_)}
$script:cmbMes.SelectedIndex=0; $top.Controls.Add($script:cmbMes)
$top.Controls.Add((New-Label "Setor" 260 10 70 20)); $script:cmbDashSetor=New-Combo 260 32 220; $top.Controls.Add($script:cmbDashSetor)
$top.Controls.Add((New-Label "Período" 495 10 80 20)); $script:cmbDashPeriodo=New-Combo 495 32 120; $top.Controls.Add($script:cmbDashPeriodo)
$top.Controls.Add((New-Label "Para simultaneidade" 630 10 140 20)); $script:cmbAnalise=New-Combo 630 32 155
@("1ª OPÇÃO","2ª OPÇÃO","3ª OPÇÃO","OPÇÃO DEFINIDA") | ForEach-Object {[void]$script:cmbAnalise.Items.Add($_)}; $script:cmbAnalise.SelectedIndex=0; $top.Controls.Add($script:cmbAnalise)
$btnAtual=New-Button "Atualizar" 800 29 100 30; $top.Controls.Add($btnAtual)
$btnCsv=New-Button "Exportar CSV" 910 29 115 30; $top.Controls.Add($btnCsv)

$cards=New-Object Windows.Forms.Panel; $cards.Dock="Top"; $cards.Height=105; $tabDash.Controls.Add($cards); $cards.BringToFront()
function Add-Card($parent,$x,$title){
    $p=New-Object Windows.Forms.Panel; $p.Location=New-Object Drawing.Point($x,12); $p.Size=New-Object Drawing.Size(210,80); $p.BorderStyle="FixedSingle"; $p.BackColor=[Drawing.Color]::White
    $l=New-Object Windows.Forms.Label; $l.Text=$title; $l.Dock="Fill"; $l.TextAlign="MiddleCenter"; $l.Font=New-Object Drawing.Font("Segoe UI",13,[Drawing.FontStyle]::Bold)
    $p.Controls.Add($l); $parent.Controls.Add($p); return $l
}
$script:lblCardTotal=Add-Card $cards 15 "0`nOCORRÊNCIAS"
$script:lblCardServ=Add-Card $cards 240 "0`nSERVIDORES"
$script:lblCardPend=Add-Card $cards 465 "0`nCADASTROS PENDENTES"

$dashTabs=New-Object Windows.Forms.TabControl
$dashTabs.Dock="Fill"
$tabResumoMes=New-Object Windows.Forms.TabPage
$tabResumoMes.Text="Resumo do mês"
$tabMapaDia=New-Object Windows.Forms.TabPage
$tabMapaDia.Text="Mapa diário"
$dashTabs.TabPages.AddRange(@($tabResumoMes,$tabMapaDia))
$tabDash.Controls.Add($dashTabs)
$dashTabs.BringToFront()

$lblResumoExp=New-Object Windows.Forms.Label
$lblResumoExp.Dock="Top"
$lblResumoExp.Height=48
$lblResumoExp.Text="RESUMO DO MÊS — mostra quantas solicitações de férias atingem o mês selecionado. Em 15+15, cada bloco de 15 dias é contado quando alcança o mês."
$lblResumoExp.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$lblResumoExp.Padding=New-Object Windows.Forms.Padding(10,12,10,0)
$tabResumoMes.Controls.Add($lblResumoExp)

$script:gridResumo=New-Object Windows.Forms.DataGridView
$script:gridResumo.Dock="Top"
$script:gridResumo.Height=180
$script:gridResumo.BackgroundColor=[Drawing.Color]::White
$script:gridResumo.AllowUserToAddRows=$false
$script:gridResumo.ReadOnly=$true
$script:gridResumo.AutoSizeColumnsMode="Fill"
$script:gridResumo.RowHeadersVisible=$false
@("Tipo","1ª opção","2ª opção","3ª opção","Total") | ForEach-Object { [void]$script:gridResumo.Columns.Add($_,$_) }
$tabResumoMes.Controls.Add($script:gridResumo)
$script:gridResumo.BringToFront()
$script:gridResumo.add_CellDoubleClick({
    param($sender,$e)
    if($e.RowIndex -lt 0){return}
    if([string]$script:gridResumo.Rows[$e.RowIndex].Cells[0].Value -ne '20 DIAS - REVISAR'){return}
    $mes=$script:cmbMes.SelectedIndex+1;$ano=[int][string]$script:cmbAno.SelectedItem
    $ini=[datetime]::new($ano,$mes,1);$fim=$ini.AddMonths(1).AddDays(-1)
    $lista=New-Object 'System.Collections.Generic.List[string]'
    foreach($r in $script:Records){
        foreach($n in 1..3){
            foreach($b in (Get-OptionBlocks $r $n)){
                if($b.bloco -eq 1 -and $b.tipo -eq '20 DIAS' -and (Test-Overlap $b.inicio $b.fim $ini $fim)){
                    [void]$lista.Add(([string]$r.nome+' | '+[string]$r.matricula+' | '+[string]$r.setor+' | '+$n+'a opcao | '+$b.inicio.ToString('dd/MM/yyyy')+' a '+$b.fim.ToString('dd/MM/yyyy')))
                }
            }
        }
    }
    $mensagem=if($lista.Count){$lista -join [Environment]::NewLine}else{'Nenhum lancamento legado encontrado neste mes.'}
    [Windows.Forms.MessageBox]::Show($mensagem,'FERIAS 20 DIAS - CONFERENCIA NOMINAL',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
})


$lblResumoLegenda=New-Object Windows.Forms.Label
$lblResumoLegenda.Location=New-Object Drawing.Point(15,240)
$lblResumoLegenda.Size=New-Object Drawing.Size(1100,120)
$lblResumoLegenda.Text="Como interpretar:`r`n• 1ª / 2ª / 3ª opção = preferência informada pelo servidor.`r`n• FR 20 DIAS = somente fr_inicio/fr_fim válidos; 20 DIAS - REVISAR = tipo antigo sem identificação FR.`r`n• Registros a revisar NAO entram no total; não são apagados nem aprovados automaticamente.`r`n• Duplo clique na linha REVISAR lista os registros nominais para conferência."
$tabResumoMes.Controls.Add($lblResumoLegenda)

$lblMapaExp=New-Object Windows.Forms.Label
$lblMapaExp.Dock="Top"
$lblMapaExp.Height=58
$lblMapaExp.Text="MAPA DIÁRIO — mostra quantos servidores estarão simultaneamente de férias em cada dia, conforme a opção escolhida no filtro 'Para simultaneidade'."
$lblMapaExp.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$lblMapaExp.Padding=New-Object Windows.Forms.Padding(10,12,10,0)
$tabMapaDia.Controls.Add($lblMapaExp)

$script:gridDia=New-Object Windows.Forms.DataGridView
$script:gridDia.Dock="Fill"
$script:gridDia.BackgroundColor=[Drawing.Color]::White
$script:gridDia.AllowUserToAddRows=$false
$script:gridDia.ReadOnly=$true
$script:gridDia.AutoSizeColumnsMode="Fill"
$script:gridDia.RowHeadersVisible=$false
foreach($c in @(
    @("dia","Dia"),
    @("m","Matutino"),
    @("v","Vespertino"),
    @("n","Noturno"),
    @("d","Diurno"),
    @("outro","Outro"),
    @("sp","Sem período"),
    @("tot","Total")
)){ [void]$script:gridDia.Columns.Add($c[0],$c[1]) }
$tabMapaDia.Controls.Add($script:gridDia)
$script:gridDia.BringToFront()

$lblMapaLegenda=New-Object Windows.Forms.Label
$lblMapaLegenda.Dock="Bottom"
$lblMapaLegenda.Height=42
$lblMapaLegenda.Text="Legenda: Total = servidores em férias naquele dia. Esta visão é apenas informativa; os alertas de sobrecarga são definidos no Planejamento por Setor (Setor + Período + Mês)."
$lblMapaLegenda.Padding=New-Object Windows.Forms.Padding(10,10,10,0)
$tabMapaDia.Controls.Add($lblMapaLegenda)

# --- LANÇAMENTOS ---
$mainSplit=New-Object Windows.Forms.SplitContainer
$mainSplit.Dock="Fill"
$mainSplit.Orientation="Vertical"
$mainSplit.SplitterWidth=5
$tabLanc.Controls.Add($mainSplit)
$mainSplit.BringToFront()
# V1.0.40: não define Panel1MinSize/Panel2MinSize durante a construção.
# Em WinForms o SplitContainer ainda pode estar com largura padrão pequena nessa fase,
# o que gera SetValueInvocationException antes da janela abrir. A divisão é aplicada
# somente quando o controle já possui largura real.
$mainSplit.add_SizeChanged({
    try {
        if($mainSplit.Width -gt 900){
            $alvo=[int]([math]::Round($mainSplit.Width*0.50))
            if($alvo -lt 520){$alvo=520}
            if($alvo -gt ($mainSplit.Width-520)){$alvo=$mainSplit.Width-520}
            if($alvo -gt 0 -and $alvo -lt $mainSplit.Width){$mainSplit.SplitterDistance=$alvo}
        }
    } catch { Write-DiagLog ("Ajuste visual SplitContainer Lançamentos ignorado: "+$_.Exception.Message) "WARN" }
})

$filter=New-Object Windows.Forms.Panel
$filter.Dock="Top"
$filter.Height=285
$filter.BackColor=[Drawing.Color]::FromArgb(247,249,252)
$mainSplit.Panel1.Controls.Add($filter)

$filter.Controls.Add((New-Label "Pesquisar servidor" 10 8 130 20))
$script:txtBusca=New-TextBox 10 28 190
$filter.Controls.Add($script:txtBusca)

$filter.Controls.Add((New-Label "Setores" 210 8 70 20))
$script:txtFiltroSetoresResumo=New-TextBox 210 28 180
$script:txtFiltroSetoresResumo.ReadOnly=$true
$script:txtFiltroSetoresResumo.Text="TODOS OS SETORES"
$filter.Controls.Add($script:txtFiltroSetoresResumo)
$script:btnFiltroSetores=New-Button "Selecionar..." 395 26 105 30
$filter.Controls.Add($script:btnFiltroSetores)

$filter.Controls.Add((New-Label "Período" 10 62 80 20))
$script:cmbFiltroPeriodo=New-Combo 10 82 125
$filter.Controls.Add($script:cmbFiltroPeriodo)
$filter.Controls.Add((New-Label "Situação" 145 62 80 20))
$script:cmbFiltroSituacao=New-Combo 145 82 175
@("TODAS","PENDENTES","ACEITAS","FIXAS - TODAS","FIXAS IMPORTADAS","FIXAS AJUSTADAS","FIXAS MANUAIS","SEM DECISÃO") | ForEach-Object {[void]$script:cmbFiltroSituacao.Items.Add($_)}
$script:cmbFiltroSituacao.SelectedIndex=0
$filter.Controls.Add($script:cmbFiltroSituacao)
$filter.Controls.Add((New-Label "Com solicitação" 330 62 115 20))
$script:cmbFiltroSolicitacao=New-Combo 330 82 170
@("TODOS","COM SOLICITAÇÃO","SEM SOLICITAÇÃO") | ForEach-Object {[void]$script:cmbFiltroSolicitacao.Items.Add($_)}
$script:cmbFiltroSolicitacao.SelectedIndex=0
$filter.Controls.Add($script:cmbFiltroSolicitacao)

$filter.Controls.Add((New-Label "Grupo de análise" 10 116 120 20))
$script:cmbFiltroGrupoAnalise=New-Combo 10 136 180
$filter.Controls.Add($script:cmbFiltroGrupoAnalise)
$filter.Controls.Add((New-Label "Grupo de Chefia" 200 116 120 20))
$script:cmbFiltroChefia=New-Combo 200 136 185
$filter.Controls.Add($script:cmbFiltroChefia)
$filter.Controls.Add((New-Label "Justificativa" 395 116 100 20))
$script:cmbFiltroJustificativa=New-Combo 395 136 175
@("TODOS","COM JUSTIFICATIVA","SEM JUSTIFICATIVA") | ForEach-Object {[void]$script:cmbFiltroJustificativa.Items.Add($_)}
$script:cmbFiltroJustificativa.SelectedIndex=0
$filter.Controls.Add($script:cmbFiltroJustificativa)

$script:btnPendencias=New-Button "Pendências cadastro" 10 174 145 30
$filter.Controls.Add($script:btnPendencias)
$btnLimparFiltros=New-Button "Limpar filtros" 165 174 115 30
$filter.Controls.Add($btnLimparFiltros)
$btnNovoServidor=New-Button "Novo servidor" 290 174 120 30
$btnNovoServidor.BackColor=[Drawing.Color]::FromArgb(220,237,255)
$filter.Controls.Add($btnNovoServidor)
$script:btnServidoresExcluidos=New-Button "Excluídos (0)" 420 174 135 30
$script:btnServidoresExcluidos.BackColor=[Drawing.Color]::FromArgb(245,245,245)
$filter.Controls.Add($script:btnServidoresExcluidos)

$btnMarcarVisiveis=New-Button "Marcar visíveis" 10 210 135 30
$filter.Controls.Add($btnMarcarVisiveis)
$btnAutorizacao=New-Button "Gerar autorização" 465 210 178 30
$btnAutorizacao.BackColor=[Drawing.Color]::FromArgb(216,238,224)
$filter.Controls.Add($btnAutorizacao)
$btnLimparMarcacao=New-Button "Limpar marcação" 155 210 135 30
$filter.Controls.Add($btnLimparMarcacao)
$script:btnExcluirServidoresMarcados=New-Button "Excluir marcados" 300 210 155 30
$script:btnExcluirServidoresMarcados.BackColor=[Drawing.Color]::FromArgb(255,225,225)
$script:btnExcluirServidoresMarcados.ForeColor=[Drawing.Color]::DarkRed
$filter.Controls.Add($script:btnExcluirServidoresMarcados)
$lblFiltroAjuda=New-Object Windows.Forms.Label
$lblFiltroAjuda.Text=""
$lblFiltroAjuda.Location=New-Object Drawing.Point(465,245)
$lblFiltroAjuda.Size=New-Object Drawing.Size(175,22)
$lblFiltroAjuda.ForeColor=[Drawing.Color]::DimGray
$filter.Controls.Add($lblFiltroAjuda)
# V151: marcacao de formularios independente da exclusao, limitada as linhas filtradas.
$btnMarcarFormVisiveis=New-Button "Marcar Form. visiveis" 10 245 166 29
$btnMarcarFormVisiveis.BackColor=[Drawing.Color]::FromArgb(216,238,224)
$filter.Controls.Add($btnMarcarFormVisiveis)
$btnLimparFormVisiveis=New-Button "Limpar Form. visiveis" 183 245 169 29
$filter.Controls.Add($btnLimparFormVisiveis)
$btnRelConferencia=New-Button "Relatorio de conferencia" 465 245 178 29
$btnRelConferencia.BackColor=[Drawing.Color]::FromArgb(227,238,250)
$filter.Controls.Add($btnRelConferencia)
$btnRelAceites=New-Button "Relatorio de aceites" 650 245 178 29
$btnRelAceites.BackColor=[Drawing.Color]::FromArgb(233,245,233)
$filter.Controls.Add($btnRelAceites)
$lblFiltroAjuda.Visible=$false


# === FORMULARIOS OFICIAIS - V1.0.90 ===
function Convert-HtmlSeguro([object]$v) { return [System.Net.WebUtility]::HtmlEncode([string]$v) }
function Formatar-DataFerias([object]$d) {
    if($null -eq $d -or -not ([string]$d).Trim()) { return '' }
    try { return ([datetime]$d).ToString('dd/MM/yyyy') } catch {
        try { return ([datetime]::Parse([string]$d, [Globalization.CultureInfo]::GetCultureInfo('pt-BR'))).ToString('dd/MM/yyyy') } catch { return '' }
    }
}
function Nova-LinhaFormularioFerias {
    param([string]$Mat='', [string]$Nome='', [string]$AqIni='', [string]$AqFim='', [string]$P30='', [string]$P2='', [bool]$Radio=$false)
    $t1=Convert-HtmlSeguro $Mat; $t2=Convert-HtmlSeguro $Nome
    $a=Convert-HtmlSeguro $AqIni; $b=Convert-HtmlSeguro $AqFim
    $c=Convert-HtmlSeguro $P30; $d=Convert-HtmlSeguro $P2
    return '<tr class="dados"><td class="mat">'+$t1+'</td><td class="nome">'+$t2+'</td><td class="aq">'+$a+'</td><td class="aq">'+$b+'</td><td class="trinta">'+$c+'</td><td class="parcela">'+$d+'</td><td class="asserv"></td></tr>'
}
function Montar-FormularioFeriasHTML {
    param([bool]$Radiologico, [string]$Linhas='', [string]$Setor='', [int]$Ano=2027, [bool]$Demonstracao=$false)
    $p2=if($Radiologico){'20 DIAS'}else{'FÉRIAS PARCELADAS'}
    $p1=if($Radiologico){'30 DIAS'}else{'FÉRIAS 30 DIAS'}
    if(-not $Linhas){ $Linhas=(Nova-LinhaFormularioFerias) }
    $set=Convert-HtmlSeguro (([string]$Setor).ToUpper())
    $marca=if($Demonstracao){'<div class="marca">PRÉVIA DEMONSTRATIVA — NÃO VÁLIDA PARA ASSINATURA</div>'}else{''}
    $html=@'
<!doctype html><html lang="pt-BR"><head><meta charset="UTF-8"><title>AUTORIZACAO_MODELOANO</title>
<style>
@page { size:A4 landscape; margin:9mm 10mm 8mm 10mm; }
* {box-sizing:border-box}body{font-family:Arial,Helvetica,sans-serif;color:#111;margin:0;background:#fff}
.pagina{width:100%;max-width:278mm;margin:0 auto}.hospital{text-align:center;font-size:18pt;font-weight:800;color:#c51010;margin:0 0 5px}
:root{--linha-borda:1.2px solid #111;--fonte-cabecalho:8.5pt;--fonte-grade:9pt;--peso-setor:700}
.tab{border-collapse:collapse;table-layout:fixed;width:100%;border:var(--linha-borda)}
.tab th,.tab td{border:var(--linha-borda);text-align:center;padding:3px 2px;overflow-wrap:anywhere}
.titulo{background:#47a5bf;font-size:20pt;font-weight:800;height:38px}
.setor{background:#47a5bf;font-size:13pt;font-weight:700;text-align:center!important;padding:3px 8px!important;height:30px;text-transform:uppercase}
.setor input{font-family:inherit;background:transparent;color:#000;font-weight:var(--peso-setor);border:0;border-bottom:1px dotted #246477;font-size:12pt;width:55%;max-width:72%;padding:1px 4px;text-align:center;outline-offset:2px;text-transform:uppercase}.setor .valor-setor-impressao{display:none;font-size:var(--fonte-cabecalho);color:#000;font-weight:var(--peso-setor);white-space:pre-wrap;overflow-wrap:anywhere;text-align:center;text-transform:uppercase}
.tab th{background:#bfe2eb;font-weight:700;font-size:8.5pt;height:31px;overflow-wrap:normal;word-break:normal} .tab th.mat-head{font-size:8pt;white-space:nowrap;letter-spacing:-.3px;padding:2px 0}
.tab th.p2{background:#dce5f0}.tab th.p1{background:#d7eef4}
.tab td{font-size:9pt;height:30px}.tab .trinta{background:#d7eef4}.tab .parcela{background:#dce5f0;white-space:pre-line;line-height:1.45}
.tab .mat{width:8%}.tab .nome{width:21%}.tab .aq{width:8%}.tab .trinta{width:17%}.tab .parcela{width:22%}.tab .asserv{width:16%}
.rodape{display:flex;justify-content:space-between;gap:16%;margin:0 5.5% 0 5.5%;height:92px;align-items:flex-start}
.assbox{width:42%;border:var(--linha-borda);position:relative;height:88px}
.assbox strong{font-size:10pt;display:block;text-align:center;border-bottom:var(--linha-borda);line-height:26px}
.data{text-align:center;margin-top:16px;font-size:9pt}.toolbar{margin:0 0 8px;text-align:right;font-size:11pt}
.toolbar button{font-size:11pt;padding:7px 12px;cursor:pointer}.marca{font-size:12pt;text-align:center;color:#b00000;border:2px dashed #b00000;font-weight:bold;margin:0 0 9px;padding:5px}
@media print{.toolbar{display:none}.marca{display:block}.setor input{display:none!important}.setor .valor-setor-impressao{display:inline!important}.setor{background:#bfe2eb!important;color:#000!important}.setor,.titulo,.tab th,.tab .trinta,.tab .parcela{print-color-adjust:exact;-webkit-print-color-adjust:exact}.pagina{max-width:none}}

/* V1.0.90 - fontes ajustáveis apenas no documento, sem alterar dados */
.tab thead tr:first-child .titulo{font-size:16pt}
.tab thead tr:nth-child(2) .setor{font-size:var(--fonte-cabecalho)}
.tab thead tr:last-child th:not(.mat-head){font-size:var(--fonte-cabecalho)}
.tab thead tr:last-child th.mat-head{font-size:clamp(7pt, var(--fonte-cabecalho), 12pt);white-space:nowrap}
.tab tbody td{font-size:var(--fonte-grade);overflow-wrap:anywhere;word-break:normal}
.setor input,.setor .valor-setor-impressao{font-family:Arial,Helvetica,sans-serif;font-size:var(--fonte-cabecalho);font-weight:var(--peso-setor);line-height:1.15;vertical-align:baseline}
.setor input{border:0;border-bottom:1px dotted #246477;background:transparent}
.painel-fontes{display:flex;justify-content:flex-end;align-items:center;gap:8px;flex-wrap:wrap;margin:0 0 8px;font:12px Arial,Helvetica,sans-serif}
.painel-fontes label{display:flex;gap:5px;align-items:center}
.painel-fontes input[type=number]{width:58px;padding:3px;font-size:12px}
.painel-fontes button{padding:5px 9px;cursor:pointer}
@media print{.painel-fontes{display:none!important}.setor input{display:none!important}.setor .valor-setor-impressao{display:inline!important;background:transparent!important;border:0!important;box-shadow:none!important;outline:0!important}}

</style></head><body>
<div class="painel-fontes" role="group" aria-label="Ajustar fonte do formulário">
<label>Cabeçalho <input id="fonte-cab" type="number" min="7" max="12" step="0.5" value="8.5" aria-label="Fonte do cabeçalho em pontos"> pt</label>
<label>Grade <input id="fonte-grade" type="number" min="8" max="14" step="0.5" value="9" aria-label="Fonte da grade em pontos"> pt</label>
<label>Ano nas datas <select id="ano-digitos" aria-label="Quantidade de dígitos do ano nas datas"><option value="2" selected>2 dígitos (27)</option><option value="4">4 dígitos (2027)</option></select></label>
<label><input id="setor-negrito" type="checkbox" checked> Nome do setor em negrito</label>
<button type="button" onclick="restaurarFontes()">Restaurar padrão</button>
</div>
<div class="pagina"><div class="toolbar">Setor pode ser editado abaixo antes de imprimir. <button type="button" onclick="window.print()">Imprimir / Salvar em PDF</button></div>
MARCA
<div class="hospital">HOSPITAL REGIONAL</div><table class="tab">
<colgroup><col style="width:8%"><col style="width:21%"><col style="width:8%"><col style="width:8%"><col style="width:17%"><col style="width:22%"><col style="width:16%"></colgroup>
<thead><tr><th class="titulo" colspan="7">PROGRAMAÇÃO DE FÉRIAS PARA O ANO MODELOANO</th></tr>
<tr><th class="setor" colspan="7"><span class="rotulo-setor">SETOR:</span> <input id="setor-editavel" aria-label="Setor ou linha assistencial" title="Altere livremente para nome do setor ou da linha" value="VALORSETOR" oninput="document.getElementById('setor-impressao').textContent=this.value.toUpperCase();window.atualizarTituloPDF()" /><span id="setor-impressao" class="valor-setor-impressao">VALORSETOR</span></th></tr>
<tr><th class="mat-head">MATRÍCULA</th><th>NOME</th><th colspan="2">PERÍODO AQUISITIVO</th><th class="p1">COLUNA30</th><th class="p2">COLUNAPARCELA</th><th>ASSINATURA DO SERVIDOR</th></tr></thead>
<tbody>LINHASFORMULARIO</tbody></table><div class="rodape"><div class="assbox"><strong>ASSINATURA DA DIRETORIA</strong></div><div class="assbox"><strong>ASSINATURA DA GERÊNCIA</strong></div></div>
<div class="data">DATAEMISSAO</div></div><script>
(function(){
  const cab=document.getElementById('fonte-cab');
  const grade=document.getElementById('fonte-grade');
  const setorNegrito=document.getElementById('setor-negrito');
  const anoDigitos=document.getElementById('ano-digitos');
  const campoSetor=document.getElementById('setor-editavel');
  window.atualizarTituloPDF=function(){
    const nome=(campoSetor.value||'SETOR_NAO_INFORMADO').normalize('NFD')
      .replace(/[\u0300-\u036f]/g,'').toUpperCase()
      .replace(/[^A-Z0-9]+/g,'_').replace(/^_+|_+$/g,'')||'SETOR_NAO_INFORMADO';
    document.title='AUTORIZACAO_'+nome+'_'+String(MODELOANO);
  };
  window.atualizarTituloPDF();
  window.addEventListener('beforeprint',window.atualizarTituloPDF);
  // Preserva as datas completas em memória: a apresentação com 2 dígitos
  // nunca altera os registros, tampouco afeta a próxima troca para 4 dígitos.
  const celulasDatas=Array.from(document.querySelectorAll('.tab tbody td.aq, .tab tbody td.trinta, .tab tbody td.parcela, .data'));
  const textosOriginais=celulasDatas.map(el=>el.textContent);
  function atualizarAnos(){
    const usarDois=anoDigitos.value==='2';
    celulasDatas.forEach((el,i)=>{
      const original=textosOriginais[i];
      el.textContent=usarDois?original.replace(/(\d{2}\/\d{2}\/)\d{2}(\d{2})(?!\d)/g,'$1$2'):original;
    });
  }
  anoDigitos.addEventListener('change',atualizarAnos);
  atualizarAnos();
  setorNegrito.addEventListener('change',()=>document.documentElement.style.setProperty('--peso-setor',setorNegrito.checked?'700':'400'));
  function aplicar(el,varCss,min,max,padrao){
    let n=Number(el.value);
    if(!Number.isFinite(n))n=padrao;
    n=Math.max(min,Math.min(max,Math.round(n*2)/2));
    el.value=String(n);
    document.documentElement.style.setProperty(varCss,n+'pt');
  }
  cab.addEventListener('input',()=>aplicar(cab,'--fonte-cabecalho',7,12,8.5));
  grade.addEventListener('input',()=>aplicar(grade,'--fonte-grade',8,14,9));
  window.restaurarFontes=function(){anoDigitos.value='2';atualizarAnos();cab.value='8.5';grade.value='9';setorNegrito.checked=true;document.documentElement.style.setProperty('--peso-setor','700');aplicar(cab,'--fonte-cabecalho',7,12,8.5);aplicar(grade,'--fonte-grade',8,14,9)};
})();
</script></body></html>
'@
    return $html.Replace('MODELOANO',[string]$Ano).Replace('MARCA',$marca).Replace('VALORSETOR',$set).Replace('COLUNA30',$p1).Replace('COLUNAPARCELA',$p2).Replace('LINHASFORMULARIO',$Linhas).Replace('DATAEMISSAO',(Get-Date -Format 'dd/MM/yyyy'))
}
function Abrir-HTMLFormularioFerias([string]$Html,[string]$Arquivo) {
    $dir=Join-Path $PSScriptRoot 'Autorizacoes'
    if(-not (Test-Path -LiteralPath $dir)){[void](New-Item -ItemType Directory -Path $dir -Force)}
    $dest=Join-Path $dir $Arquivo
    [IO.File]::WriteAllText($dest,$Html,(New-Object System.Text.UTF8Encoding($false)))
    Start-Process -FilePath $dest
}
function Get-MatriculaGradeLancamentos {
    # Nunca interpreta o checkbox 'Excluir' como selecao para formularios.
    if($null -eq $script:grid){return ''}
    try {
        if($script:grid.CurrentRow -ne $null -and $script:grid.CurrentRow.Index -ge 0){
            return ([string]$script:grid.CurrentRow.Cells['matricula'].Value).Trim()
        }
        if($script:grid.SelectedRows.Count -gt 0){
            return ([string]$script:grid.SelectedRows[0].Cells['matricula'].Value).Trim()
        }
    } catch {}
    return ''
}
function Gerar-AutorizacaoFeriasServidor {
    # V149: "Form." e independente de "Excluir"; somente os marcados em Form.
    # participam do lote. Sem marcacao, emitir para a linha ativa.
    try {
        if($script:grid.IsCurrentCellDirty){
            try{[void]$script:grid.CommitEdit([Windows.Forms.DataGridViewDataErrorContexts]::Commit)}catch{}
        }
        $mats=New-Object 'System.Collections.Generic.List[string]'
        foreach($linha in $script:grid.Rows){
            if($linha.IsNewRow){continue}
            $m=([string]$linha.Cells['matricula'].Value).Trim()
            if($m -and [bool]$linha.Cells['formulario'].Value -and -not $mats.Contains($m)){
                [void]$mats.Add($m)
            }
        }
        if($mats.Count -eq 0){
            $mat=Get-MatriculaGradeLancamentos
            if(-not $mat){$mat=([string]$script:CurrentMatricula).Trim()}
            if(-not $mat){
                [Windows.Forms.MessageBox]::Show('Selecione um servidor ou marque a coluna Form. para gerar em lote.','Formularios')|Out-Null
                return
            }
            [void]$mats.Add($mat)
        }
        $matSet=@{}
        foreach($m in $mats.ToArray()){$matSet[$m]=$true}
        $selecionados=@($script:Records | Where-Object {
            $matAtual=([string]$_.matricula).Trim()
            $matSet.ContainsKey($matAtual) -and
            -not (Test-RegistroFeriasBloqueadas $_) -and
            -not (Test-RegistroFixoImportado $_) -and
            -not ([string]$_.fixo_inicio).Trim() -and
            ((Get-NumeroComumConfirmada $_) -gt 0 -or (Get-NumeroFRConfirmada $_) -gt 0)
        })
        if($selecionados.Count -eq 0){
            [Windows.Forms.MessageBox]::Show('Nenhuma opcao aprovada encontrada nos servidores selecionados. Quinzenas fixas possuem formulario separado.','Formularios')|Out-Null
            return
        }

        # Ordem dos formularios: nome alfabetico; para mesmo nome, inicio e fim aquisitivos crescentes.
        # Ordena registros, nao altera as datas nem o estado salvo.
        $selecionados=@($selecionados | Sort-Object -Property @{Expression={ ([string]$_.nome).Trim() }}, @{Expression={ ([string]$_.aquisitivo_inicio).Trim() }}, @{Expression={ ([string]$_.aquisitivo_fim).Trim() }}, @{Expression={ ([string]$_.matricula).Trim() }})
        $grupos=@{}
        $avisos=New-Object 'System.Collections.Generic.List[string]'
        foreach($r in $selecionados){
            try {
                $nc=Get-NumeroComumConfirmada $r
                $nf=Get-NumeroFRConfirmada $r
                if(Test-ConflitoComumFR $r $nc $nf){throw 'Ferias comuns e FR aprovadas se sobrepoem.'}
                $p30='';$p20=''
                if($nc -gt 0){
                    $op=$r.("opcao$nc")
                    $tipo=([string]$op.tipo -replace ' \+ FR 20 DIAS$','')
                    $comuns=@(Get-BlocosComunsOpcao $r $nc | Sort-Object inicio)
                    if($tipo -eq '30 DIAS' -and $comuns.Count -eq 1){
                        $p30=$comuns[0].inicio.ToString('dd/MM/yyyy')+' a '+$comuns[0].fim.ToString('dd/MM/yyyy')
                    }elseif($tipo -eq '15+15 DIAS' -and $comuns.Count -eq 2){
                        if($nf -gt 0 -or @(@($r.opcao1,$r.opcao2,$r.opcao3) | Where-Object { $_.fr_inicio -and $_.fr_fim }).Count -gt 0){throw 'Servidor com FR nao pode parcelar 15+15.'}
                        $p20=($comuns | ForEach-Object { $_.inicio.ToString('dd/MM/yyyy')+' a '+$_.fim.ToString('dd/MM/yyyy') }) -join "`n"
                    }else{throw 'Opcao comum aprovada com tipo ou datas invalidas.'}
                }
                if($nf -gt 0){
                    $fr=@(Get-BlocoFROpcao $r $nf)
                    if($fr.Count -ne 1){throw 'FR aprovada incompleta.'}
                    $p20=$fr[0].inicio.ToString('dd/MM/yyyy')+' a '+$fr[0].fim.ToString('dd/MM/yyyy')
                }
                $setor=([string]$r.setor).Trim()
                if(-not $setor){$setor='SETOR NAO INFORMADO'}
                $tipoModelo=if($nf -gt 0){'FR'}else{'COMUM'}
                $chave=$setor+'|'+$tipoModelo
                if(-not $grupos.ContainsKey($chave)){
                    $grupos[$chave]=[pscustomobject]@{
                        Setor=$setor;Radiologico=($nf -gt 0)
                        Linhas=(New-Object 'System.Collections.Generic.List[string]')
                        Matriculas=(New-Object 'System.Collections.Generic.List[string]')
                    }
                }
                $grupos[$chave].Linhas.Add((Nova-LinhaFormularioFerias -Mat ([string]$r.matricula) -Nome ([string]$r.nome) -AqIni (Formatar-DataFerias $r.aquisitivo_inicio) -AqFim (Formatar-DataFerias $r.aquisitivo_fim) -P30 $p30 -P2 $p20))
                if(-not $grupos[$chave].Matriculas.Contains([string]$r.matricula)){
                    $grupos[$chave].Matriculas.Add([string]$r.matricula)
                }
            }catch{
                [void]$avisos.Add(([string]$r.nome)+': '+$_.Exception.Message)
            }
        }
        $quantidade=0
        foreach($chave in @($grupos.Keys | Sort-Object)){
            $grupo=$grupos[$chave]
            if($grupo.Linhas.Count -eq 0){continue}
            $linhas=[string]::Join([Environment]::NewLine,[string[]]$grupo.Linhas.ToArray())
            $html=Montar-FormularioFeriasHTML -Radiologico:([bool]$grupo.Radiologico) -Linhas $linhas -Setor ([string]$grupo.Setor) -Ano 2027
            $nomeSetor=([string]$grupo.Setor -replace '[^0-9A-Za-z]','_')
            if($nomeSetor.Length -gt 32){$nomeSetor=$nomeSetor.Substring(0,32)}
            $arquivo='AUTORIZACAO_'+$nomeSetor+'_'+$(if($grupo.Radiologico){'FR'}else{'COMUM'})+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,6)+'.html'
            Abrir-HTMLFormularioFerias $html $arquivo
            $quantidade += $grupo.Matriculas.Count
        }
        if($quantidade -eq 0){throw 'Nenhum formulario valido foi gerado.'}
        if($avisos.Count -gt 0){
            [Windows.Forms.MessageBox]::Show(
                "Foram emitidas $quantidade autorizacoes. Registros nao incluidos:`n"+([string]::Join("`n",[string[]]$avisos.ToArray())),
                'Conferencia de autorizacoes',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning
            )|Out-Null
        }
    }catch{
        [Windows.Forms.MessageBox]::Show(('Nao foi possivel gerar: '+$_.Exception.Message),'Formularios')|Out-Null
    }
}
# V1.0.114 - Formulário separado para a quinzena FIXA remanescente (15 dias).
# Não cria registros, não exige a quinzena do ano anterior e não altera as opções.
function Gerar-FormularioQuinzenaFixaServidor {
    try {
        $mat=Get-MatriculaGradeLancamentos
        if(-not $mat){$mat=([string]$script:CurrentMatricula).Trim()}
        if($mat -and $script:CurrentMatricula -ne $mat){Load-Servidor $mat}
        if(-not $mat){ [Windows.Forms.MessageBox]::Show('Selecione o servidor na aba Lançamentos e tente novamente.','Formulário de férias fixas') | Out-Null; return }
        $recs=@($script:Records | Where-Object { ([string]$_.matricula).Trim() -eq $mat -and (Test-RegistroFixoImportado $_) } |
            Sort-Object -Property @{Expression={ ([string]$_.nome).Trim() }}, @{Expression={ ([string]$_.aquisitivo_inicio).Trim() }}, @{Expression={ ([string]$_.aquisitivo_fim).Trim() }})
        if($recs.Count -eq 0){ [Windows.Forms.MessageBox]::Show('O servidor selecionado não possui férias fixas registradas.','Formulário de férias fixas') | Out-Null; return }
        $linhas=''; $quantidade=0; $naoQuinzenais=0; $setor=''
        foreach($r in $recs){
            if(-not $setor){ $setor=[string]$r.setor }
            $fixas=@([pscustomobject]@{inicio=[string]$r.fixo_inicio;fim=[string]$r.fixo_fim}) + @(Get-FixasAdicionais $r)
            $fixas=@($fixas | Sort-Object -Property @{Expression={ ([string]$_.inicio).Trim() }}, @{Expression={ ([string]$_.fim).Trim() }})
            foreach($f in $fixas){
                $ini=Parse-Date ([string]$f.inicio); $fim=Parse-Date ([string]$f.fim)
                if($null -eq $ini -or $null -eq $fim -or $fim -lt $ini){ $naoQuinzenais++; continue }
                if((($fim-$ini).Days+1) -ne 15){ $naoQuinzenais++; continue }
                $faixa=$ini.ToString('dd/MM/yy')+' a '+$fim.ToString('dd/MM/yy')
                $linhas += Nova-LinhaFormularioFerias -Mat $mat -Nome ([string]$r.nome) -AqIni (Formatar-DataFerias $r.aquisitivo_inicio) -AqFim (Formatar-DataFerias $r.aquisitivo_fim) -P2 $faixa
                $quantidade++
            }
        }
        if($quantidade -eq 0){ throw 'Não foi encontrada quinzena fixa válida de 15 dias. Confira os registros antes de imprimir.' }
        if($naoQuinzenais -gt 0){
            $resp=[Windows.Forms.MessageBox]::Show("Há $naoQuinzenais período(s) fixo(s) com datas inválidas ou duração diferente de 15 dias. Eles NÃO serão impressos.`n`nDeseja continuar apenas com as quinzenas válidas?",'Conferência de férias fixas',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
            if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
        }
        $html=Montar-FormularioFeriasHTML -Radiologico:$false -Linhas $linhas -Setor $setor -Ano 2027
        $html=$html.Replace('PROGRAMAÇÃO DE FÉRIAS PARA O ANO 2027','FÉRIAS FIXAS — QUINZENA REMANESCENTE — 2027')
        $html=$html.Replace('FÉRIAS 30 DIAS','OUTRA ETAPA (ANO ANTERIOR)')
        $html=$html.Replace('FÉRIAS PARCELADAS','QUINZENA FIXA (15 DIAS)')
        $html=$html.Replace('Setor pode ser editado abaixo antes de imprimir.','Somente a quinzena remanescente cadastrada. A etapa do ano anterior não é reproduzida. Setor editável.')
        Abrir-HTMLFormularioFerias $html ('FERIAS_FIXAS_15_DIAS_'+($mat -replace '[^0-9A-Za-z]','_')+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.html')
    }catch{ [Windows.Forms.MessageBox]::Show(('Não foi possível gerar o formulário: '+$_.Exception.Message),'Formulário de férias fixas') | Out-Null }
}
# V1.0.167 - emissão consolidada de TODOS os períodos fixos, independente da seleção.
# Operação somente leitura. Um HTML com páginas por setor, adequado para um único PDF.
function Gerar-TodasFeriasFixasHTML {
    try {
        $itens=New-Object 'System.Collections.Generic.List[object]'
        $avisos=New-Object 'System.Collections.Generic.List[string]'
        $chaves=@{}
        foreach($r in @($script:Records)) {
            $principal=([string]$r.fixo_inicio).Trim()
            $temAdicionais=(@(Get-FixasAdicionais $r).Count -gt 0)
            if(-not $principal -and -not $temAdicionais){continue}
            $periodos=New-Object 'System.Collections.Generic.List[object]'
            if($principal -or ([string]$r.fixo_fim).Trim()){
                [void]$periodos.Add([pscustomobject]@{inicio=$r.fixo_inicio;fim=$r.fixo_fim})
            }
            foreach($a in @(Get-FixasAdicionais $r)){[void]$periodos.Add($a)}
            foreach($p in $periodos){
                $inicio=Parse-Date ([string]$p.inicio)
                $fim=Parse-Date ([string]$p.fim)
                if($null -eq $inicio -or $null -eq $fim -or $fim -lt $inicio){
                    [void]$avisos.Add(('{0} ({1}): período fixo incompleto ou inválido.' -f $r.nome,$r.matricula));continue
                }
                $dias=($fim-$inicio).Days+1
                if($dias -notin @(15,20,30)){
                    [void]$avisos.Add(('{0} ({1}): período fixo com {2} dias; não incluído.' -f $r.nome,$r.matricula,$dias));continue
                }
                $mat=([string]$r.matricula).Trim()
                $aqi=([string]$r.aquisitivo_inicio).Trim()
                $aqf=([string]$r.aquisitivo_fim).Trim()
                $key=$mat+'|'+$aqi+'|'+$aqf+'|'+$inicio.ToString('yyyy-MM-dd')+'|'+$fim.ToString('yyyy-MM-dd')
                if($chaves.ContainsKey($key)){continue}
                $chaves[$key]=$true
                $setor=([string]$r.setor).Trim()
                if(-not $setor){$setor='SETOR NÃO INFORMADO'}
                [void]$itens.Add([pscustomobject]@{Setor=$setor;Nome=([string]$r.nome).Trim();Mat=$mat;AqInicio=$aqi;AqFim=$aqf;Inicio=$inicio;Fim=$fim;Dias=$dias})
            }
        }
        if($itens.Count -eq 0){
            [Windows.Forms.MessageBox]::Show('Nenhuma férias fixa válida de 15, 20 ou 30 dias encontrada.','Todas as férias fixas')|Out-Null
            return
        }
        if($avisos.Count -gt 0){
            $alerta=('Foram identificados {0} intervalo(s) inválido(s), que não serão impressos. Confira o JSON antes de usar o PDF oficial. Continuar?' -f $avisos.Count)
            $resp=[Windows.Forms.MessageBox]::Show($alerta,'Conferência das fixas',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
            if($resp -ne [Windows.Forms.DialogResult]::Yes){return}
        }
        $paginas=New-Object 'System.Collections.Generic.List[string]'
        foreach($grupo in @($itens | Group-Object Setor | Sort-Object Name)) {
            $linhas=New-Object 'System.Collections.Generic.List[string]'
            foreach($r in @($grupo.Group | Sort-Object -Property @{Expression={$_.Nome}},@{Expression={$_.AqInicio}},@{Expression={$_.Inicio}})) {
                $intervalo=$r.Inicio.ToString('dd/MM/yyyy')+' a '+$r.Fim.ToString('dd/MM/yyyy')
                $p30='';$p2=''
                if($r.Dias -eq 30){$p30=$intervalo}
                elseif($r.Dias -eq 20){$p30='FR 20 DIAS: '+$intervalo}
                else{$p2=$intervalo}
                [void]$linhas.Add((Nova-LinhaFormularioFerias -Mat $r.Mat -Nome $r.Nome -AqIni (Formatar-DataFerias $r.AqInicio) -AqFim (Formatar-DataFerias $r.AqFim) -P30 $p30 -P2 $p2))
            }
            $modelo=Montar-FormularioFeriasHTML -Radiologico:$false -Linhas ([string]::Join("`n",[string[]]$linhas.ToArray())) -Setor (([string]$grupo.Name).ToUpperInvariant()) -Ano 2027
            $m=[regex]::Match($modelo,'(?s)<div class="pagina">.*?</div><script>')
            if(-not $m.Success){throw 'Falha ao montar uma das páginas do formulário consolidado.'}
            $pagina=$m.Value.Substring(0,$m.Value.Length-'<script>'.Length)
            # IDs individualizados; alteração do setor numa página não interfere nas outras.
            $id=[string]$paginas.Count
            $pagina=$pagina.Replace('id="setor-editavel"',('id="setor-editavel-'+$id+'"'))
            $pagina=$pagina.Replace('id="setor-impressao"',('id="setor-impressao-'+$id+'"'))
            $pagina=$pagina.Replace("document.getElementById('setor-impressao').textContent=this.value.toUpperCase();window.atualizarTituloPDF()","this.nextElementSibling.textContent=this.value.toUpperCase()")
            $pagina=$pagina.Replace('PROGRAMAÇÃO DE FÉRIAS PARA O ANO 2027','FÉRIAS FIXAS — PROGRAMAÇÃO 2027')
            [void]$paginas.Add($pagina)
        }
        $base=Montar-FormularioFeriasHTML -Radiologico:$false -Setor 'TODOS OS SETORES' -Ano 2027
        $padrao='(?s)<div class="pagina">.*?</div><script>'
        $novasPaginas=[string]::Join("`n",[string[]]$paginas.ToArray())+'<script>'
        $html=[regex]::Replace($base,$padrao,[System.Text.RegularExpressions.MatchEvaluator]{param($m) $novasPaginas},1)
        # O HTML consolidado usa título próprio; os controles para fontes e impressão continuam ativos.
        $html=$html.Replace('<title>Programação de Férias — 2027</title>','<title>FERIAS_FIXAS_TODOS_SETORES_2027</title>')
        $html=$html.Replace('</style>','@media print {.pagina + .pagina {break-before:page;page-break-before:always}} .pagina + .pagina {margin-top:22px} </style>')
        $html=$html.Replace('  window.atualizarTituloPDF();',"  window.atualizarTituloPDF=function(){document.title='FERIAS_FIXAS_TODOS_SETORES_2027'};`n  window.atualizarTituloPDF();")
        $html=$html.Replace("  const campoSetor=document.getElementById('setor-editavel');","  const campoSetor={value:'TODOS_SETORES'};")
        Abrir-HTMLFormularioFerias $html ('FERIAS_FIXAS_TODOS_SETORES_2027_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.html')
        if($avisos.Count -gt 0){
            [Windows.Forms.MessageBox]::Show(('Formulário gerado com '+$itens.Count+' intervalos válidos. '+$avisos.Count+' intervalos inválidos foram excluídos e exigem conferência.'),'Conferência das fixas')|Out-Null
        }
    } catch {
        [Windows.Forms.MessageBox]::Show(('Falha na emissão consolidada de fixas: '+$_.Exception.Message),'Todas as férias fixas')|Out-Null
    }
}
# V1.0.168 - Relatorio de simultaneidade por setor (consulta, sem modificar JSON).
function Get-EntradasConferenciaSetor([bool]$IncluirPendentes) {
    $itens=New-Object 'System.Collections.Generic.List[object]'
    foreach($r in @($script:Records)) {
        if($null -eq $r){continue}
        $setor=([string]$r.setor).Trim(); if(-not $setor){$setor='SETOR NAO INFORMADO'}
        $mat=([string]$r.matricula).Trim(); $nome=([string]$r.nome).Trim(); if(-not $mat){$mat='REGISTRO:'+([string]$r.id)}
        $base=[pscustomobject]@{Setor=$setor;Matricula=$mat;Nome=$nome;Aquisitivo=([string]$r.aquisitivo_inicio)+' a '+([string]$r.aquisitivo_fim);Turno=(Normalizar-TurnoConferencia ([string]$r.periodo));RegistroId=([string]$r.id)}
        $blocos=New-Object 'System.Collections.Generic.List[object]'
        if(([string]$r.fixo_inicio).Trim() -or @(Get-FixasAdicionais $r).Count -gt 0){
            $fixas=@([pscustomobject]@{inicio=$r.fixo_inicio;fim=$r.fixo_fim})+@(Get-FixasAdicionais $r)
            foreach($f in $fixas){
                $ini=Parse-Date ([string]$f.inicio);$fim=Parse-Date ([string]$f.fim)
                if($null -ne $ini -and $null -ne $fim -and $fim -ge $ini){
                    $blocos.Add([pscustomobject]@{Inicio=$ini;Fim=$fim;Situacao='FIXA'})
                }
            }
        }
        # Uma aprovacao eventual nao pode desaparecer apenas porque o registro tambem contem fixa.
        # Entretanto, ferias fixas NAO criam opcoes pendentes adicionais.
        $possuiFixa=(([string]$r.fixo_inicio).Trim() -ne '' -or @(Get-FixasAdicionais $r).Count -gt 0 -or (Test-RegistroFixoImportado $r))
        if(-not (Test-RegistroFeriasBloqueadas $r)){
            $nc=Get-NumeroComumConfirmada $r; $nf=Get-NumeroFRConfirmada $r
            if($nc -gt 0){foreach($b in @(Get-BlocosComunsOpcao $r $nc)){
                $blocos.Add([pscustomobject]@{Inicio=$b.inicio;Fim=$b.fim;Situacao='ACEITA'})
            }}
            if($nf -gt 0){foreach($b in @(Get-BlocoFROpcao $r $nf)){
                $blocos.Add([pscustomobject]@{Inicio=$b.inicio;Fim=$b.fim;Situacao='FR ACEITA'})
            }}
            if($IncluirPendentes -and -not $possuiFixa -and $nc -eq 0){
                # Somente 1a opcao comum pendente, nunca 2a/3a automaticamente.
                foreach($b in @(Get-BlocosComunsOpcao $r 1)){
                    $blocos.Add([pscustomobject]@{Inicio=$b.inicio;Fim=$b.fim;Situacao='PENDENTE (1a opcao)'})
                }
            }
            if($IncluirPendentes -and -not $possuiFixa -and $nf -eq 0){
                foreach($b in @(Get-BlocoFROpcao $r 1)){
                    $blocos.Add([pscustomobject]@{Inicio=$b.inicio;Fim=$b.fim;Situacao='FR PENDENTE (1a opcao)'})
                }
            }
        }
        foreach($b in $blocos){
            if($null -eq $b.Inicio -or $null -eq $b.Fim -or $b.Fim -lt $b.Inicio){continue}
            $itens.Add([pscustomobject]@{Setor=$base.Setor;Matricula=$base.Matricula;Nome=$base.Nome;Aquisitivo=$base.Aquisitivo;Inicio=$b.Inicio;Fim=$b.Fim;Situacao=$b.Situacao;Turno=$base.Turno;RegistroId=$base.RegistroId})
        }
    }
    return $itens.ToArray()
}
# V1.0.170: conferencia de sobreposicoes simultaneas por turno.
# Segmenta a linha temporal em intervalos de participantes constantes; nunca conta
# um conjunto de 3/4 participantes apenas como pares isolados.
function Normalizar-TurnoConferencia([string]$Valor){
    $v=$Valor.Trim().ToUpperInvariant()
    switch -Regex ($v){
        '^(M|MATUTINO|MANHA|MANHÃ)$' {return 'MATUTINO'}
        '^(V|VESPERTINO|TARDE)$' {return 'VESPERTINO'}
        '^(N|NOTURNO|NOITE)$' {return 'NOTURNO'}
        '^(D|DIURNO)$' {return 'DIURNO'}
        default {return 'NAO INFORMADO'}
    }
}
function Criar-RelatorioConflitosSetores([string[]]$Setores,[bool]$IncluirPendentes,[string]$Modo='POR_SETOR',[bool]$ExigirMesmoTurno=$false){
    $enc={param($v) [System.Net.WebUtility]::HtmlEncode([string]$v)}
    $selecionados=@{};foreach($s in $Setores){$selecionados[[string]$s]=$true}
    # O turno pertence ao registro aquisitivo de origem, nunca ao primeiro cadastro da matricula.
    $itens=@(Get-EntradasConferenciaSetor $IncluirPendentes | Where-Object {$selecionados.ContainsKey([string]$_.Setor)} | ForEach-Object {
        [pscustomobject]@{Setor=[string]$_.Setor;Matricula=[string]$_.Matricula;Nome=[string]$_.Nome;Inicio=[datetime]$_.Inicio;Fim=[datetime]$_.Fim;Situacao=[string]$_.Situacao;Turno=[string]$_.Turno;RegistroId=[string]$_.RegistroId}
    })
    $grupos=@()
    if($Modo -eq 'ENTRE_SETORES'){$grupos=@([pscustomobject]@{Nome='ENTRE SETORES SELECIONADOS';Itens=@($itens)})}
    else {foreach($s in @($Setores | Sort-Object -Unique)){$grupos+= [pscustomobject]@{Nome=$s;Itens=@($itens | Where-Object {$_.Setor -eq $s})}}}
    $htmlPartes=New-Object System.Text.StringBuilder
    $totalCriticos=0;$totalAtencao=0;$totalPendentes=0;$totalEventos=0
    foreach($g in $grupos){
        $arr=@($g.Itens)
        [void]$htmlPartes.Append('<section class="setor"><h2>'+(& $enc $g.Nome)+'</h2>')
        if($arr.Count -lt 2){[void]$htmlPartes.Append('<p class="ok">Nenhuma coincidência identificada.</p></section>');continue}
        # Pontos de corte: inicio e dia seguinte ao termino (fim inclusivo).
        $pontos=New-Object 'System.Collections.Generic.List[datetime]'
        foreach($it in $arr){$pontos.Add($it.Inicio.Date);if($it.Fim.Date -lt [datetime]::MaxValue.Date){$pontos.Add($it.Fim.Date.AddDays(1))}}
        $cortes=@($pontos | Sort-Object -Unique)
        $eventos=New-Object 'System.Collections.Generic.List[object]'
        for($k=0;$k -lt $cortes.Count-1;$k++){
            $ini=[datetime]$cortes[$k];$fim=([datetime]$cortes[$k+1]).AddDays(-1)
            $ativos=@($arr | Where-Object {$_.Inicio.Date -le $ini -and $_.Fim.Date -ge $ini})
            # Unifica matriculas duplicadas na mesma faixa de tempo.
            $ativos=@($ativos | Sort-Object Matricula,@{Expression={if($_.Situacao -match 'PENDENTE'){1}else{0}}},Situacao | Group-Object Matricula | ForEach-Object {$_.Group | Select-Object -First 1})
            if($ativos.Count -lt 2){continue}
            if($Modo -eq 'ENTRE_SETORES'){
                if(@($ativos | Select-Object -ExpandProperty Setor -Unique).Count -lt 2){continue}
                # Mantem apenas participantes pertencentes a pelo menos uma relacao intersetorial.
                $matComPar=New-Object 'System.Collections.Generic.HashSet[string]'
                for($ia=0;$ia -lt $ativos.Count;$ia++){
                    for($ib=$ia+1;$ib -lt $ativos.Count;$ib++){
                        if($ativos[$ia].Setor -ne $ativos[$ib].Setor -and $ativos[$ia].Matricula -ne $ativos[$ib].Matricula){
                            [void]$matComPar.Add([string]$ativos[$ia].Matricula)
                            [void]$matComPar.Add([string]$ativos[$ib].Matricula)
                        }
                    }
                }
                $ativos=@($ativos | Where-Object {$matComPar.Contains([string]$_.Matricula)})
                if($ativos.Count -lt 2){continue}
            }
            # Filtro opcional: ao exigir o mesmo turno, participa apenas quem tem
            # par de MATRICULA diferente, com turno conhecido e igual.
            # Entre setores, o par deve tambem estar em setores diferentes.
            if($ExigirMesmoTurno){
                $matTurno=New-Object 'System.Collections.Generic.HashSet[string]'
                for($ia=0;$ia -lt $ativos.Count;$ia++){
                    for($ib=$ia+1;$ib -lt $ativos.Count;$ib++){
                        $a=$ativos[$ia];$b=$ativos[$ib]
                        if($a.Matricula -eq $b.Matricula){continue}
                        if($a.Turno -eq 'NAO INFORMADO' -or $b.Turno -eq 'NAO INFORMADO'){continue}
                        if($a.Turno -ne $b.Turno){continue}
                        if($Modo -eq 'ENTRE_SETORES' -and $a.Setor -eq $b.Setor){continue}
                        [void]$matTurno.Add([string]$a.Matricula)
                        [void]$matTurno.Add([string]$b.Matricula)
                    }
                }
                $ativos=@($ativos | Where-Object {$matTurno.Contains([string]$_.Matricula)})
                if($ativos.Count -lt 2){continue}
            }
            $turnosValidos=@($ativos | Where-Object {$_.Turno -ne 'NAO INFORMADO'} | Group-Object Turno | Where-Object {$_.Count -ge 2})
            $mesmoTurno=$false
            # Comparacao dentro do setor exige mesmo setor + mesmo turno.
            foreach($t in $turnosValidos){
                if($Modo -eq 'POR_SETOR'){$mesmoTurno=$true;break}
                # Entre setores: relevancia critica somente se turnos iguais EM SETORES DIFERENTES.
                if(@($t.Group | Select-Object -ExpandProperty Setor -Unique).Count -ge 2){$mesmoTurno=$true;break}
            }
            $pendente=(@($ativos | Where-Object {$_.Situacao -match 'PENDENTE'}).Count -gt 0)
            $grau=if($mesmoTurno){'CRITICO'}else{'ATENCAO'}
            $confirmacao=if($pendente){'ENVOLVE PENDENTE'}else{'CONFIRMADO'}
            # Cada trecho pertence a um conjunto IDENTICO de lancamentos, nao apenas matriculas.
            # Nao unir periodos distintos do mesmo servidor ou mudancas de turno/status.
            $assinaturas=@($ativos | ForEach-Object {
                @([string]$_.Matricula,[string]$_.RegistroId,[string]$_.Setor,[string]$_.Turno,[string]$_.Situacao,$_.Inicio.ToString('yyyyMMdd'),$_.Fim.ToString('yyyyMMdd')) -join [char]31
            } | Sort-Object)
            $chave=($assinaturas -join [char]30)+'|'+$grau+'|'+$confirmacao
            if($eventos.Count -gt 0 -and $eventos[$eventos.Count-1].Chave -eq $chave -and $eventos[$eventos.Count-1].Fim.AddDays(1) -eq $ini){
                $eventos[$eventos.Count-1].Fim=$fim
            }else{$eventos.Add([pscustomobject]@{Inicio=$ini;Fim=$fim;Chave=$chave;Participantes=$ativos;Grau=$grau;Confirmacao=$confirmacao})}
        }
        if($eventos.Count -eq 0){[void]$htmlPartes.Append('<p class="ok">Nenhuma coincidência identificada neste escopo.</p></section>');continue}
        [void]$htmlPartes.Append('<p class="section-caption">'+ $eventos.Count +' ocorrência(s) neste setor ou grupo. Cada linha reúne um intervalo de coincidência.</p>')
        [void]$htmlPartes.Append('<div class="table-wrap"><table><caption class="sr-only">Ocorrências de coincidência de férias: '+(& $enc $g.Nome)+'</caption><thead><tr><th scope="col">Classificação</th><th scope="col">Situação</th><th scope="col">Período coincidente</th><th scope="col">Dias</th><th scope="col">Servidores e férias programadas</th><th scope="col">Pessoas</th></tr></thead><tbody>')
        foreach($e in $eventos){
            $totalEventos++
            switch($e.Grau){'CRITICO'{$totalCriticos++}'ATENCAO'{$totalAtencao++}}
            if($e.Confirmacao -eq 'ENVOLVE PENDENTE'){$totalPendentes++}
            $classe=if($e.Grau -eq 'CRITICO'){'critico'}else{'atencao'}
            $nomes=New-Object System.Text.StringBuilder
            foreach($it in @($e.Participantes | Sort-Object Setor,Turno,Nome)){
                $nome=(& $enc $it.Nome);$matricula=(& $enc $it.Matricula)
                $setor=(& $enc $it.Setor);$turno=(& $enc $it.Turno);$situacao=(& $enc $it.Situacao)
                $iconeTurno=if($it.Turno -eq 'NOTURNO'){'moon'}elseif($it.Turno -in @('MATUTINO','VESPERTINO','DIURNO')){'sun'}else{'clock'}
                $datas=$it.Inicio.ToString('dd/MM/yyyy')+' a '+$it.Fim.ToString('dd/MM/yyyy')
                [void]$nomes.Append('<div class="pessoa"><div class="person-name"><svg class="icon" aria-hidden="true"><use href="#i-user"></use></svg>'+$nome+' <span class="matricula">Matrícula '+$matricula+'</span></div><div class="person-meta"><span>'+$setor+'</span><span class="turno"><svg class="icon" aria-hidden="true"><use href="#i-'+$iconeTurno+'"></use></svg>'+$turno+'</span><span>'+$situacao+'</span></div><div class="person-dates">Férias: '+$datas+'</div></div>')
            }
            $q=($e.Fim-$e.Inicio).Days+1
            $rotulo=if($e.Grau -eq 'CRITICO'){'Crítico'}else{'Atenção'}
            $motivo=if($e.Grau -eq 'CRITICO'){'Há coincidência de datas no mesmo turno conhecido.'}else{'Datas coincidentes com turnos diferentes ou não informados.'}
            $statusRotulo=if($e.Confirmacao -eq 'ENVOLVE PENDENTE'){'Envolve pendente'}else{'Confirmado'}
            $statusClasse=if($e.Confirmacao -eq 'ENVOLVE PENDENTE'){'pending'}else{'confirmed'}
            $iconeGravidade=if($e.Grau -eq 'CRITICO'){'critical'}else{'alert'}
            $iconeStatus=if($e.Confirmacao -eq 'ENVOLVE PENDENTE'){'clock'}else{'check'}
            $periodo=if($e.Inicio.Date -eq $e.Fim.Date){$e.Inicio.ToString('dd/MM/yyyy')}else{$e.Inicio.ToString('dd/MM/yyyy')+'<span class="date-separator">até</span>'+$e.Fim.ToString('dd/MM/yyyy')}
            [void]$htmlPartes.Append('<tr class="ocorrencia '+$classe+'" data-gravidade="'+$e.Grau+'" data-status="'+$e.Confirmacao+'"><td><span class="badge '+$classe+'"><svg class="icon" aria-hidden="true"><use href="#i-'+$iconeGravidade+'"></use></svg>'+$rotulo+'</span><p class="reason">'+$motivo+'</p></td><td><span class="badge '+$statusClasse+'"><svg class="icon" aria-hidden="true"><use href="#i-'+$iconeStatus+'"></use></svg>'+$statusRotulo+'</span></td><td class="periodo">'+$periodo+'</td><td class="number">'+$q+'</td><td>'+$nomes.ToString()+'</td><td class="number">'+$e.Participantes.Count+'</td></tr>')
        }
        [void]$htmlPartes.Append('</tbody></table></div></section>')
    }
    $modoTitulo=if($Modo -eq 'ENTRE_SETORES'){'Entre setores selecionados (somente pares de setores diferentes)'}else{'Dentro de cada setor selecionado'}
    $pendTitulo=if($IncluirPendentes){'SIM, apenas 1a opcao pendente'}else{'NAO'}
    $turnoTitulo=if($ExigirMesmoTurno){'SIM — mostrar somente coincidencias de datas no MESMO turno conhecido'}else{'NAO — mostrar TODAS as datas coincidentes, independentemente do turno'}
    $setoresTitulo=(& $enc (($Setores | Sort-Object) -join ', '))
    $html=@'
<!doctype html>
<html lang="pt-BR">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Conferência de férias — 2027/2028</title>
<style>
:root{--ink:#162b43;--muted:#52657a;--line:#d9e2ec;--blue:#174979;--red:#a92333;--amber:#805000}
.icon-sprite{position:absolute;width:0;height:0;overflow:hidden}.icon{width:18px;height:18px;display:inline-block;vertical-align:-3px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round;flex-shrink:0}.badge .icon{width:14px;height:14px;vertical-align:-2px;margin-right:4px}button .icon{margin-right:7px}.card .icon{width:22px;height:22px;vertical-align:-5px;margin-right:6px}.heading-icon{display:inline-flex;align-items:center;justify-content:center;border-radius:12px;background:#e6eef8;color:var(--blue);width:46px;height:46px;margin-right:12px;vertical-align:middle}.heading-icon .icon{width:26px;height:26px}.person-name>.icon{width:15px;height:15px;color:var(--muted);margin-right:5px}.turno .icon{width:14px;height:14px;margin-right:4px}.notice>.icon{margin-right:6px}*{box-sizing:border-box}body{margin:0;background:#f3f6fa;color:var(--ink);font:14px/1.5 "Segoe UI",Arial,sans-serif}
main{max-width:1480px;margin:auto;padding:32px 28px 48px}h1,h2,p{margin-top:0}h1{font-size:28px;line-height:1.2;margin-bottom:8px;letter-spacing:-.5px}h2{font-size:19px;margin-bottom:6px;color:var(--blue)}
header{display:flex;justify-content:space-between;align-items:flex-start;gap:24px;margin-bottom:24px}.eyebrow{font-size:12px;letter-spacing:1px;text-transform:uppercase;font-weight:700;color:var(--blue);margin-bottom:8px}.subtitle{color:var(--muted);margin-bottom:0}.emitido{font-size:12px;color:var(--muted);margin-top:10px}
button,input,select{font:inherit}button{border:1px solid var(--blue);background:var(--blue);color:white;border-radius:8px;padding:11px 18px;cursor:pointer;white-space:nowrap;font-weight:600}button.secondary{background:white;color:var(--blue);border-color:var(--line)}button:hover{filter:brightness(.94)}:focus-visible{outline:3px solid #598dd7;outline-offset:3px}
.escopo{background:white;border:1px solid var(--line);border-radius:12px;padding:18px 20px;margin-bottom:18px}.scope-grid{display:grid;grid-template-columns:1.5fr 1fr 1fr;gap:14px 24px}.field-label{display:block;font-size:12px;font-weight:600;color:var(--muted);margin-bottom:3px}.scope-turno{margin-top:14px;padding-top:12px;border-top:1px solid var(--line);font-size:13px}.notice{padding:12px 16px;border-left:4px solid #4d7ba4;background:#eaf1f9;color:#2e4c69;border-radius:0 8px 8px 0;margin-bottom:20px}
.resumo{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}.card{background:white;border:1px solid var(--line);border-radius:10px;padding:15px 18px;border-top:4px solid #5a7897}.card strong{display:block;font-size:30px;line-height:1.2;margin:5px 0}.card span{font-size:13px;color:var(--muted)}.card.critical{border-top-color:var(--red)}.card.critical strong{color:var(--red)}.card.warning{border-top-color:#d19625}.card.warning strong{color:var(--amber)}.card.pending{border-top-color:#6875bd}
.filters{display:flex;gap:12px;align-items:end;flex-wrap:wrap;margin-bottom:12px}.filters label{display:flex;flex-direction:column;gap:5px;font-size:12px;color:var(--muted);font-weight:600}.filters .search{flex:1;min-width:220px}input,select{border:1px solid #b9c8d7;border-radius:7px;padding:10px 12px;background:white;color:var(--ink);min-height:43px}input{width:100%}.filter-summary{font-size:13px;color:var(--muted);margin:0 0 18px}.filter-summary strong{color:var(--ink)}
.setor{background:white;border:1px solid var(--line);border-radius:12px;padding:20px;margin-bottom:20px}.section-caption{font-size:13px;color:var(--muted);margin-bottom:14px}.table-wrap{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:13px}caption{text-align:left}th{text-align:left;background:#edf3f9;color:#26496c;font-size:12px;padding:11px 12px;border-top:1px solid var(--line);border-bottom:1px solid var(--line)}td{padding:14px 12px;border-bottom:1px solid var(--line);vertical-align:top}tbody tr:last-child td{border-bottom:0}td:first-child{width:17%;border-left:4px solid #d19625}tr.critico td:first-child{border-left-color:var(--red)}td:nth-child(2){width:12%}td:nth-child(3){width:13%}.badge{display:inline-block;border-radius:5px;padding:4px 8px;font-size:12px;font-weight:700;white-space:nowrap}.badge.critico{background:#fbe6e9;color:#9c1e30}.badge.atencao{background:#fff0ca;color:#7a4d00}.badge.confirmed{background:#edf2f7;color:#405670}.badge.pending{background:#ececfc;color:#4c478c}.reason{font-size:12px;color:var(--muted);margin:9px 0 0;max-width:240px}.periodo{font-weight:600;white-space:nowrap;font-variant-numeric:tabular-nums}.date-separator{display:block;font-size:11px;color:var(--muted);font-weight:400;padding:2px 0}.number{font-weight:700;text-align:center;font-variant-numeric:tabular-nums}.pessoa{padding-bottom:12px;margin-bottom:12px;border-bottom:1px solid #e6ecf2}.pessoa:last-child{padding:0;margin:0;border:0}.person-name{font-weight:600}.matricula{font-weight:400;color:var(--muted);font-size:12px;display:block}.person-meta{display:flex;gap:5px 12px;flex-wrap:wrap;font-size:12px;color:var(--muted);margin:5px 0}.turno{font-weight:700;color:#345778}.person-dates{font-size:12px}.ok{color:#226342;background:#edf8f1;border-radius:7px;padding:12px;margin:12px 0 0}.empty{background:white;padding:24px;text-align:center;border:1px dashed #aabccd;border-radius:10px;color:var(--muted)}details{border-top:1px solid var(--line);padding-top:16px;color:var(--muted);font-size:13px}summary{cursor:pointer;font-weight:600;color:var(--blue)}details ul{padding-left:20px;max-width:1000px}footer{color:var(--muted);font-size:12px;margin-top:24px}.sr-only{position:absolute;width:1px;height:1px;padding:0;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}[hidden]{display:none!important}
@media(max-width:800px){main{padding:20px 14px}header{flex-direction:column;gap:14px}h1{font-size:24px}.scope-grid{grid-template-columns:1fr}.resumo{grid-template-columns:repeat(2,1fr)}.setor{padding:14px}table{min-width:880px}.filters label{flex:1;min-width:140px}}
@page{size:A4 landscape;margin:10mm}
@media print{body{background:white;font-size:10pt}main{max-width:none;padding:0}header{margin-bottom:12px}h1{font-size:21px}.toolbar,.filters,details{display:none!important}.scope-grid{grid-template-columns:1.5fr 1fr 1fr}.escopo,.setor{border-radius:0;padding:10px}.notice{font-size:9pt;margin-bottom:12px}.resumo{grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:12px}.card{padding:8px 12px}.card strong{font-size:22px}.setor{break-inside:auto}h2,.section-caption{break-after:avoid}thead{display:table-header-group}tr,.pessoa{break-inside:avoid}td{padding:9px 7px}.table-wrap{overflow:visible}table{min-width:0;font-size:9pt}.matricula,.person-meta,.person-dates,.reason{font-size:8pt}footer{font-size:8pt}*{-webkit-print-color-adjust:exact;print-color-adjust:exact}}
@media print{body{font-size:9pt;line-height:1.3}header{margin-bottom:8px;gap:12px}.eyebrow{font-size:9px;margin-bottom:3px}h1{font-size:18px;margin-bottom:3px}.heading-icon{width:28px;height:28px;margin-right:7px;border-radius:6px}.heading-icon .icon{width:19px;height:19px}.subtitle{font-size:10px}.emitido{font-size:9px;margin-top:3px}.escopo{padding:7px 10px;margin-bottom:8px;font-size:10px}.scope-grid{gap:4px 14px}.field-label{font-size:9px;margin-bottom:2px}.scope-turno{font-size:9px;margin-top:6px;padding-top:5px}.notice{padding:6px 10px;font-size:9px;margin-bottom:8px}.resumo{gap:8px;margin-bottom:8px}.card{padding:6px 10px}.card span{font-size:10px}.card>span:last-child{display:none}.card strong{font-size:20px;margin:3px 0 0}.card .icon{width:16px;height:16px;vertical-align:-3px}.filter-summary{font-size:9px;margin-bottom:8px}.setor{padding:8px 10px;margin-bottom:10px}h2{font-size:15px;margin-bottom:3px}.section-caption{font-size:9px;margin-bottom:6px}th{padding:7px;font-size:9px}td{padding:7px;font-size:9px}.reason,.matricula,.person-meta,.person-dates{font-size:9px}.badge{font-size:9px;padding:3px 5px}.badge .icon{width:11px;height:11px}.pessoa{padding-bottom:6px;margin-bottom:6px}.person-meta{margin:3px 0}footer{font-size:8px;margin-top:12px}}
</style></head>
<body><svg class="icon-sprite" aria-hidden="true" xmlns="http://www.w3.org/2000/svg"><defs><symbol id="i-calendar" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18M8 15h2M14 15h2"/></symbol><symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/><circle cx="9" cy="7" r="4"/></symbol><symbol id="i-user" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/></symbol><symbol id="i-alert" viewBox="0 0 24 24"><path d="M10.3 3.9 2 18.2A2 2 0 0 0 3.7 21h16.6a2 2 0 0 0 1.7-2.8L13.7 3.9a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/></symbol><symbol id="i-critical" viewBox="0 0 24 24"><path d="m8 2-6 6v8l6 6h8l6-6V8l-6-6Z"/><path d="M12 7v6M12 17h.01"/></symbol><symbol id="i-clock" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></symbol><symbol id="i-check" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></symbol><symbol id="i-print" viewBox="0 0 24 24"><path d="M6 9V3h12v6M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><path d="M6 14h12v8H6zM18 12h.01"/></symbol><symbol id="i-search" viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="7.5"/><path d="m16 16 5 5"/></symbol><symbol id="i-reset" viewBox="0 0 24 24"><path d="M3 10a9 9 0 1 1 2 8M3 4v6h6"/></symbol><symbol id="i-info" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/></symbol><symbol id="i-sun" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/></symbol><symbol id="i-moon" viewBox="0 0 24 24"><path d="M21 12.8A9 9 0 0 1 11.2 3 9 9 0 1 0 21 12.8Z"/></symbol><symbol id="i-list" viewBox="0 0 24 24"><path d="M9 6h12M9 12h12M9 18h12M3 6h.01M3 12h.01M3 18h.01"/></symbol></defs></svg><main>
<header><div><div class="eyebrow">Planejamento de férias · DCE</div><h1><span class="heading-icon"><svg class="icon" aria-hidden="true"><use href="#i-calendar"></use></svg></span>Conferência de coincidências de férias</h1><p class="subtitle">2027 / 2028 · Datas, turnos e servidores envolvidos</p><div class="emitido">Emitido em EMISSAO_AQUI</div></div><div class="toolbar"><button type="button" onclick="window.print()"><svg class="icon" aria-hidden="true"><use href="#i-print"></use></svg>Imprimir / Salvar em PDF</button></div></header>
<div class="escopo"><div class="scope-grid"><div><span class="field-label">Setores selecionados</span>SETORES_AQUI</div><div><span class="field-label">Comparação</span>MODO_AQUI</div><div><span class="field-label">Base da conferência</span>Férias fixas e aprovadas<br>Pendentes: PENDENTES_AQUI</div></div><div class="scope-turno"><strong>Mesmo turno obrigatório:</strong> TURNO_AQUI</div></div>
<div class="notice"><svg class="icon" aria-hidden="true"><use href="#i-info"></use></svg><strong>Como interpretar:</strong> datas coincidentes em turnos diferentes são um alerta para conferência. Uma coincidência não significa, por si só, erro de lançamento.</div>
<div class="resumo" aria-label="Totais do relatório completo"><div class="card critical"><span><svg class="icon" aria-hidden="true"><use href="#i-critical"></use></svg>Críticos · mesmo turno</span><strong>TOTAL_CRITICO</strong><span>Coincidências no mesmo turno conhecido</span></div><div class="card warning"><span><svg class="icon" aria-hidden="true"><use href="#i-alert"></use></svg>Atenção · revisar turnos</span><strong>TOTAL_ATENCAO</strong><span>Turnos diferentes ou não informados</span></div><div class="card pending"><span><svg class="icon" aria-hidden="true"><use href="#i-clock"></use></svg>Envolvendo pendentes</span><strong>TOTAL_PENDENTE</strong><span>Também incluídos nas classificações ao lado</span></div><div class="card"><span><svg class="icon" aria-hidden="true"><use href="#i-users"></use></svg>Total de ocorrências</span><strong>TOTAL_EVENTOS</strong><span>Intervalos com participantes constantes</span></div></div>
<div class="filters" role="search" aria-label="Filtrar ocorrências"><label class="search" for="busca"><span><svg class="icon" aria-hidden="true"><use href="#i-search"></use></svg> Buscar servidor, matrícula, setor ou turno</span><input id="busca" type="search" placeholder="Digite para filtrar as ocorrências…"></label><label for="gravidade">Classificação<select id="gravidade"><option value="">Todas</option><option value="CRITICO">Crítico</option><option value="ATENCAO">Atenção</option></select></label><label for="situacao">Situação<select id="situacao"><option value="">Todas</option><option value="CONFIRMADO">Confirmado</option><option value="ENVOLVE PENDENTE">Envolve pendente</option></select></label><button id="limpar" class="secondary" type="button"><svg class="icon" aria-hidden="true"><use href="#i-reset"></use></svg>Limpar filtros</button></div>
<p id="resultado-filtro" class="filter-summary" role="status" aria-live="polite">Exibindo todas as ocorrências. Os totais acima correspondem ao relatório completo.</p>
<div id="sem-resultados" class="empty" hidden>Nenhuma ocorrência corresponde aos filtros. Use “Limpar filtros” para voltar ao relatório completo.</div>
CONTEUDO_AQUI
<details><summary><svg class="icon" aria-hidden="true"><use href="#i-info"></use></svg> Critérios da conferência e legenda</summary><ul><li><strong>Crítico:</strong> datas sobrepostas no mesmo turno conhecido, respeitando o modo de comparação selecionado.</li><li><strong>Atenção:</strong> datas sobrepostas com turnos diferentes ou não informados.</li><li><strong>Envolve pendente:</strong> existe solicitação ainda não aprovada. A classificação Crítico/Atenção é mantida.</li><li>Diurno (D) não é presumido equivalente a Matutino ou Vespertino.</li><li>Cada ocorrência é um intervalo contínuo com o mesmo grupo de participantes. Um servidor pode participar de vários intervalos; as ocorrências não representam o total de pessoas distintas.</li></ul></details>
<footer>Férias DCE · Relatório de conferência 2027/2028 · A impressão respeita os filtros aplicados. Os totais dos cartões sempre representam o relatório completo.</footer>
</main>
<script>
(function(){
'use strict';
const rows=Array.from(document.querySelectorAll('tr.ocorrencia'));
const sections=Array.from(document.querySelectorAll('section.setor'));
const search=document.getElementById('busca'),severity=document.getElementById('gravidade'),status=document.getElementById('situacao');
const fold=v=>v.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('pt-BR');
const index=rows.map(row=>({row,text:fold(row.textContent)}));
function update(){
 const term=fold(search.value.trim());let shown=0;
 index.forEach(item=>{const row=item.row;const visible=(!term||item.text.includes(term))&&(!severity.value||row.dataset.gravidade===severity.value)&&(!status.value||row.dataset.status===status.value);row.hidden=!visible;if(visible)shown++;});
 const active=Boolean(term||severity.value||status.value);
 sections.forEach(section=>{const own=Array.from(section.querySelectorAll('tr.ocorrencia'));section.hidden=active&&!own.some(row=>!row.hidden);});
 document.getElementById('sem-resultados').hidden=!(active&&shown===0);
 let label='Exibindo '+shown+' de '+rows.length+' ocorrência(s). ';
 if(active){label+='Filtros: '+(search.value.trim()?'busca “'+search.value.trim()+'”; ':'')+(severity.value?severity.options[severity.selectedIndex].text+'; ':'')+(status.value?status.options[status.selectedIndex].text+'; ':'');}
 document.getElementById('resultado-filtro').textContent=label+'Os cartões mostram os totais do relatório completo.';
}
search.addEventListener('input',update);severity.addEventListener('change',update);status.addEventListener('change',update);
document.getElementById('limpar').addEventListener('click',()=>{search.value='';severity.value='';status.value='';update();search.focus();});
update();
})();
</script></body></html>

'@
    $html=$html.Replace('EMISSAO_AQUI',(Get-Date -Format 'dd/MM/yyyy HH:mm')).Replace('SETORES_AQUI',$setoresTitulo).Replace('MODO_AQUI',(& $enc $modoTitulo)).Replace('PENDENTES_AQUI',$pendTitulo).Replace('TURNO_AQUI',(& $enc $turnoTitulo))
    $html=$html.Replace('TOTAL_CRITICO',[string]$totalCriticos).Replace('TOTAL_ATENCAO',[string]$totalAtencao).Replace('TOTAL_PENDENTE',[string]$totalPendentes).Replace('TOTAL_EVENTOS',[string]$totalEventos).Replace('CONTEUDO_AQUI',$htmlPartes.ToString())
    $dir=Join-Path $PSScriptRoot 'Relatorios';if(-not(Test-Path -LiteralPath $dir)){[void](New-Item -ItemType Directory -Path $dir -Force)}
    $file=Join-Path $dir ('CONFLITOS_TURNOS_'+$(if($Modo -eq 'ENTRE_SETORES'){'ENTRE_SETORES'}else{'POR_SETOR'})+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.html')
    [IO.File]::WriteAllText($file,$html,(New-Object System.Text.UTF8Encoding($false)))
    Start-Process -FilePath $file
}
function Abrir-RelatorioConflitosSetores {
    try{
        $setores=@($script:Records | Where-Object {$null -ne $_} | ForEach-Object { $st=([string]$_.setor).Trim();if($st){$st}else{'SETOR NAO INFORMADO'} } | Sort-Object -Unique)
        $dlg=New-Object Windows.Forms.Form
        $dlg.Text='Relatorio de coincidencias de ferias — selecionar setores'
        $dlg.Size=New-Object Drawing.Size(550,685)
        $dlg.StartPosition='CenterParent'
        $dlg.FormBorderStyle='FixedDialog'; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false
        $lbl=New-Object Windows.Forms.Label;$lbl.Text='Marque um ou varios setores para comparar as liberacoes:';$lbl.Location=New-Object Drawing.Point(16,15);$lbl.Size=New-Object Drawing.Size(510,28);$dlg.Controls.Add($lbl)
        $cl=New-Object Windows.Forms.CheckedListBox;$cl.Location=New-Object Drawing.Point(16,48);$cl.Size=New-Object Drawing.Size(502,300);$cl.CheckOnClick=$true
        foreach($s in $setores){[void]$cl.Items.Add($s)};$dlg.Controls.Add($cl)

        $grpModo=New-Object Windows.Forms.GroupBox;$grpModo.Text='Modo de comparação';$grpModo.Location=New-Object Drawing.Point(16,360);$grpModo.Size=New-Object Drawing.Size(502,82);$dlg.Controls.Add($grpModo)
        $rbSetor=New-Object Windows.Forms.RadioButton;$rbSetor.Text='Dentro de cada setor selecionado';$rbSetor.Location=New-Object Drawing.Point(14,24);$rbSetor.Size=New-Object Drawing.Size(240,22);$rbSetor.Checked=$true;$grpModo.Controls.Add($rbSetor)
        $rbEntre=New-Object Windows.Forms.RadioButton;$rbEntre.Text='Entre todos os setores selecionados';$rbEntre.Location=New-Object Drawing.Point(14,49);$rbEntre.Size=New-Object Drawing.Size(260,22);$grpModo.Controls.Add($rbEntre)

        $chkTurno=New-Object Windows.Forms.CheckBox
        $chkTurno.Text='Filtrar apenas datas coincidentes no MESMO turno (M/V/N/D)'
        $chkTurno.Location=New-Object Drawing.Point(16,452);$chkTurno.Size=New-Object Drawing.Size(510,28)
        $chkTurno.Checked=$false;$dlg.Controls.Add($chkTurno)
        $check=New-Object Windows.Forms.CheckBox;$check.Text='Incluir solicitações PENDENTES (1ª opção) na análise';$check.Location=New-Object Drawing.Point(16,484);$check.Size=New-Object Drawing.Size(480,26);$check.Checked=$false;$dlg.Controls.Add($check)
        $all=New-Object Windows.Forms.Button;$all.Text='Marcar todos';$all.Location=New-Object Drawing.Point(16,560);$all.Size=New-Object Drawing.Size(120,31)
        $all.Add_Click({for($k=0;$k -lt $cl.Items.Count;$k++){$cl.SetItemChecked($k,$true)}}.GetNewClosure());$dlg.Controls.Add($all)
        $btn=New-Object Windows.Forms.Button;$btn.Text='Gerar relatorio';$btn.Location=New-Object Drawing.Point(295,560);$btn.Size=New-Object Drawing.Size(132,31);$btn.DialogResult=[Windows.Forms.DialogResult]::OK;$dlg.Controls.Add($btn)
        $cancel=New-Object Windows.Forms.Button;$cancel.Text='Cancelar';$cancel.Location=New-Object Drawing.Point(433,560);$cancel.Size=New-Object Drawing.Size(86,31);$cancel.DialogResult=[Windows.Forms.DialogResult]::Cancel;$dlg.Controls.Add($cancel)
        if($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
            $chosen=@($cl.CheckedItems | ForEach-Object {[string]$_})
            if($chosen.Count -eq 0){[Windows.Forms.MessageBox]::Show('Selecione pelo menos um setor.','Conferencia')|Out-Null;return}
            $modo=if($rbEntre.Checked){'ENTRE_SETORES'}else{'POR_SETOR'}
            if($modo -eq 'ENTRE_SETORES' -and $chosen.Count -lt 2){[Windows.Forms.MessageBox]::Show('Para comparar entre setores, selecione pelo menos dois setores.','Conferencia')|Out-Null;return}
            Criar-RelatorioConflitosSetores -Setores $chosen -IncluirPendentes ([bool]$check.Checked) -Modo $modo -ExigirMesmoTurno ([bool]$chkTurno.Checked)
        }
    }catch{[Windows.Forms.MessageBox]::Show(('Falha no relatorio: '+$_.Exception.Message),'Conferencia')|Out-Null}
}

$introForms=New-Object Windows.Forms.Label
$introForms.Text='FORMULÁRIOS — opções autorizadas e, separadamente, quinzena fixa remanescente (15 dias).'
$introForms.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$introForms.Location=New-Object Drawing.Point(22,22);$introForms.Size=New-Object Drawing.Size(1100,38);$tabFormularios.Controls.Add($introForms)
$avisoForms=New-Object Windows.Forms.Label
$avisoForms.Text='Para emitir férias fixas, selecione primeiro o servidor em Lançamentos e clique no botão abaixo. A quinzena do ano anterior não será exigida nem impressa.'
$avisoForms.Location=New-Object Drawing.Point(22,65);$avisoForms.Size=New-Object Drawing.Size(1100,50);$tabFormularios.Controls.Add($avisoForms)
$btnModeloComum=New-Button 'Prévia oficial: 30 dias / 15 + 15' 22 123 325 42;$tabFormularios.Controls.Add($btnModeloComum)
$btnModeloRadio=New-Button 'Prévia oficial: radiológicas FR 20 dias' 365 123 335 42;$tabFormularios.Controls.Add($btnModeloRadio)
$btnFormularioFixa=New-Button 'Gerar formulário: férias FIXAS (15 dias)' 715 123 345 42
$btnFormularioFixa.BackColor=[Drawing.Color]::FromArgb(216,238,224)
$tabFormularios.Controls.Add($btnFormularioFixa)
$btnRelConfSetores=New-Button 'Relatorio de conflitos — por setores' 22 260 410 40
$btnRelConfSetores.BackColor=[Drawing.Color]::FromArgb(245,228,210)
$tabFormularios.Controls.Add($btnRelConfSetores)
$btnRelConfSetores.Add_Click({ Abrir-RelatorioConflitosSetores })
$btnFormularioFixa.add_Click({ Gerar-FormularioQuinzenaFixaServidor })
$btnTodasFixas=New-Button 'Gerar TODAS as férias FIXAS — por setor' 22 175 420 38
$btnTodasFixas.BackColor=[Drawing.Color]::FromArgb(216,238,224)
$tabFormularios.Controls.Add($btnTodasFixas)
$btnTodasFixas.add_Click({ Gerar-TodasFeriasFixasHTML })
$lblInfoForms=New-Object Windows.Forms.Label
$lblInfoForms.Text='Impressão em A4 paisagem. Altere SETOR diretamente no HTML (ex.: Linha Cardiológica) e use Imprimir / Salvar em PDF.'
$lblInfoForms.Location=New-Object Drawing.Point(22,224);$lblInfoForms.Size=New-Object Drawing.Size(1080,70);$tabFormularios.Controls.Add($lblInfoForms)
function Abrir-ModeloAutorizacao([bool]$radiologico){
    $html=Montar-FormularioFeriasHTML -Radiologico:$radiologico -Ano 2027 -Setor 'Linha/Setor (edite aqui)' -Demonstracao $true
    $nome=if($radiologico){'PREVIA_MODELO_RADIOLOGICO.html'}else{'PREVIA_MODELO_COMUM.html'}
    Abrir-HTMLFormularioFerias $html $nome
}
$btnModeloComum.add_Click({try{Abrir-ModeloAutorizacao $false}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Prévia')|Out-Null}})
$btnModeloRadio.add_Click({try{Abrir-ModeloAutorizacao $true}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Prévia')|Out-Null}})

$script:grid=New-Object Windows.Forms.DataGridView; $script:grid.Dock="Fill"; $script:grid.Margin=New-Object Windows.Forms.Padding(0,6,0,0); $script:grid.AllowUserToAddRows=$false; $script:grid.AllowUserToDeleteRows=$false; $script:grid.ReadOnly=$false; $script:grid.SelectionMode="FullRowSelect"; $script:grid.MultiSelect=$false; $script:grid.AutoSizeColumnsMode="Fill"; $script:grid.RowHeadersVisible=$false; $script:grid.BackgroundColor=[Drawing.Color]::White
$colExcluir=New-Object Windows.Forms.DataGridViewCheckBoxColumn; $colExcluir.Name="excluir"; $colExcluir.HeaderText="Excluir"; $colExcluir.FalseValue=$false; $colExcluir.TrueValue=$true; $colExcluir.ReadOnly=$false; [void]$script:grid.Columns.Add($colExcluir)
$script:FormServidoresMarcados=@{}
$colFormulario=New-Object Windows.Forms.DataGridViewCheckBoxColumn
$colFormulario.Name="formulario";$colFormulario.HeaderText="Form."
$colFormulario.FalseValue=$false;$colFormulario.TrueValue=$true;$colFormulario.ReadOnly=$false
[void]$script:grid.Columns.Add($colFormulario)
foreach($c in @(@("matricula","Matrícula"),@("nome","Nome"),@("setor","Setor"),@("periodo","Período"),@("situacao","Situação"),@("qtdperiodos","Qtd."),@("qtdsol","Solic."))){ [void]$script:grid.Columns.Add($c[0],$c[1]); $script:grid.Columns[$c[0]].ReadOnly=$true }
$script:grid.Columns["excluir"].FillWeight=8
$script:grid.Columns["formulario"].FillWeight=9
$script:grid.Columns["matricula"].FillWeight=16
$script:grid.Columns["nome"].FillWeight=34
$script:grid.Columns["setor"].FillWeight=20
$script:grid.Columns["periodo"].FillWeight=14
$script:grid.Columns["situacao"].FillWeight=18
$script:grid.Columns["qtdperiodos"].FillWeight=8
$script:grid.Columns["qtdsol"].FillWeight=8
$mainSplit.Panel1.Controls.Add($script:grid); $script:grid.BringToFront()
$script:lblTotal=New-Object Windows.Forms.Label; $script:lblTotal.Dock="Bottom"; $script:lblTotal.Height=24; $mainSplit.Panel1.Controls.Add($script:lblTotal)

$editor=New-Object Windows.Forms.Panel
$editor.Dock="Fill"
$editor.AutoScroll=$true
$editor.AutoScrollMinSize=New-Object Drawing.Size(700,700)
$mainSplit.Panel2.Controls.Add($editor)

$script:lblEdit=New-Object Windows.Forms.Label
$script:lblEdit.Text="DADOS DO SERVIDOR"
$script:lblEdit.Location=New-Object Drawing.Point(15,8)
$script:lblEdit.Size=New-Object Drawing.Size(250,28)
$script:lblEdit.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold)
$editor.Controls.Add($script:lblEdit)

$btnSalvarCadastro=New-Button "Salvar cadastro" 430 7 120 32
$editor.Controls.Add($btnSalvarCadastro)
$btnSalvar=New-Button "Salvar opções" 560 7 120 32
$editor.Controls.Add($btnSalvar)

$editor.Controls.Add((New-Label "Matrícula" 15 52 90))
$script:txtMatricula=New-TextBox 15 72 125
$script:txtMatricula.ReadOnly=$true
$editor.Controls.Add($script:txtMatricula)

$editor.Controls.Add((New-Label "Nome" 150 52 80))
$script:txtNome=New-TextBox 150 72 530
$editor.Controls.Add($script:txtNome)

$editor.Controls.Add((New-Label "Setor do servidor" 15 108 120))
$script:cmbSetor=New-Combo 15 128 385 $true
$editor.Controls.Add($script:cmbSetor)

$editor.Controls.Add((New-Label "Período de trabalho" 415 108 135))
$script:cmbPeriodo=New-Combo 415 128 265
$editor.Controls.Add($script:cmbPeriodo)

$tipSetor=New-Object Windows.Forms.ToolTip
$tipSetor.SetToolTip($script:cmbSetor,"O Setor e o Período de trabalho pertencem ao servidor e valem para todos os períodos aquisitivos da matrícula.")

$lblPeriodos=New-Object Windows.Forms.Label
$lblPeriodos.Text="PERÍODOS AQUISITIVOS"
$lblPeriodos.Location=New-Object Drawing.Point(15,170)
$lblPeriodos.Size=New-Object Drawing.Size(235,24)
$lblPeriodos.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$editor.Controls.Add($lblPeriodos)
$tipAcoesPeriodo=New-Object Windows.Forms.ToolTip
$btnAdicionarPeriodo=New-Button "Adicionar" 255 162 79 32
$btnAdicionarPeriodo.BackColor=[Drawing.Color]::FromArgb(220,237,255)
$editor.Controls.Add($btnAdicionarPeriodo)
$tipAcoesPeriodo.SetToolTip($btnAdicionarPeriodo,"Adicionar período aquisitivo")
$btnCorrigirPeriodo=New-Button "Corrigir" 338 162 77 32
$btnCorrigirPeriodo.BackColor=[Drawing.Color]::FromArgb(227,241,230)
$editor.Controls.Add($btnCorrigirPeriodo)
$tipAcoesPeriodo.SetToolTip($btnCorrigirPeriodo,"Corrigir período aquisitivo ou férias fixa")
$btnNovaFixa=New-Button "Nova fixa" 419 162 80 32
$btnNovaFixa.BackColor=[Drawing.Color]::FromArgb(222,238,252)
$editor.Controls.Add($btnNovaFixa)
$tipAcoesPeriodo.SetToolTip($btnNovaFixa,"Cadastrar quinzena fixa remanescente")
$btnConverterFixa=New-Button "Converter" 503 162 86 32
$btnConverterFixa.BackColor=[Drawing.Color]::FromArgb(255,246,220)
$editor.Controls.Add($btnConverterFixa)
$tipAcoesPeriodo.SetToolTip($btnConverterFixa,"Converter férias FIXAS em COMUNS para novas opções")
$btnExcluirPeriodo=New-Button "Excluir" 593 162 87 32
$btnExcluirPeriodo.BackColor=[Drawing.Color]::FromArgb(255,235,235)
$editor.Controls.Add($btnExcluirPeriodo)
$tipAcoesPeriodo.SetToolTip($btnExcluirPeriodo,"Excluir período aquisitivo")

$script:gridPeriodos=New-Object Windows.Forms.DataGridView
$script:gridPeriodos.Location=New-Object Drawing.Point(15,196)
$script:gridPeriodos.Size=New-Object Drawing.Size(665,105)
$script:gridPeriodos.AllowUserToAddRows=$false
$script:gridPeriodos.AllowUserToDeleteRows=$false
$script:gridPeriodos.ReadOnly=$true
$script:gridPeriodos.SelectionMode="FullRowSelect"
$script:gridPeriodos.MultiSelect=$false
$script:gridPeriodos.RowHeadersVisible=$false
$script:gridPeriodos.AutoSizeColumnsMode="Fill"
$script:gridPeriodos.BackgroundColor=[Drawing.Color]::White
foreach($c in @(
    @("pid","ID"),
    @("paquis","Período aquisitivo"),
    @("pop1","1ª opção"),
    @("pop2","2ª opção"),
    @("pop3","3ª opção"),
    @("pdef","Def."),
    @("pstatus","Situação")
)){
    [void]$script:gridPeriodos.Columns.Add($c[0],$c[1])
}
$script:gridPeriodos.Columns["pid"].Visible=$false
$script:gridPeriodos.Columns["paquis"].FillWeight=30
$script:gridPeriodos.Columns["pop1"].FillWeight=13
$script:gridPeriodos.Columns["pop2"].FillWeight=13
$script:gridPeriodos.Columns["pop3"].FillWeight=13
$script:gridPeriodos.Columns["pdef"].FillWeight=8
$script:gridPeriodos.Columns["pstatus"].FillWeight=23
$script:gridPeriodos.Columns["pstatus"].MinimumWidth=120
$editor.Controls.Add($script:gridPeriodos)

$script:lblPeriodoSelecionado=New-Object Windows.Forms.Label
$script:lblPeriodoSelecionado.Text="Selecione um período aquisitivo."
$script:lblPeriodoSelecionado.Location=New-Object Drawing.Point(15,310)
$script:lblPeriodoSelecionado.Size=New-Object Drawing.Size(390,24)
$script:lblPeriodoSelecionado.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$editor.Controls.Add($script:lblPeriodoSelecionado)

$script:chkFeriasBloqueadas=New-Object Windows.Forms.CheckBox
$script:chkFeriasBloqueadas.Text="Férias já programadas / bloqueadas"
$script:chkFeriasBloqueadas.Location=New-Object Drawing.Point(220,328)
$script:chkFeriasBloqueadas.Size=New-Object Drawing.Size(240,26)
$script:chkFeriasBloqueadas.Checked=$false
$editor.Controls.Add($script:chkFeriasBloqueadas)

$editor.Controls.Add((New-Label "Opção aceita" 470 308 100))
$script:cmbAprov=New-Combo 470 328 210
@("Não definida","1ª opção","2ª opção","3ª opção") | ForEach-Object {[void]$script:cmbAprov.Items.Add($_)}
$script:cmbAprov.SelectedIndex=0
$script:cmbAprov.Enabled=$false
$editor.Controls.Add($script:cmbAprov)
$editor.Controls.Add((New-Label "Aprovação somente na Central" 470 354 220 18))

$script:lblBloqueioInfo=New-Object Windows.Forms.Label
$script:lblBloqueioInfo.Location=New-Object Drawing.Point(15,354)
$script:lblBloqueioInfo.Size=New-Object Drawing.Size(665,58)
$script:lblBloqueioInfo.Padding=New-Object Windows.Forms.Padding(6,4,6,4)
$script:lblBloqueioInfo.BorderStyle=[Windows.Forms.BorderStyle]::FixedSingle
$script:lblBloqueioInfo.Text="Programação atual: opções podem ser analisadas e ajustadas."
$editor.Controls.Add($script:lblBloqueioInfo)

$script:dtAqIni=New-DatePicker 15 328 95
$script:dtAqIni.Visible=$false
$editor.Controls.Add($script:dtAqIni)
$script:dtAqFim=New-DatePicker 115 328 95
$script:dtAqFim.Visible=$false
$editor.Controls.Add($script:dtAqFim)

$tabOpcoes=New-Object Windows.Forms.TabControl
$tabOpcoes.Location=New-Object Drawing.Point(15,420)
$tabOpcoes.Size=New-Object Drawing.Size(425,205)
$editor.Controls.Add($tabOpcoes)

$tabOp1=New-Object Windows.Forms.TabPage; $tabOp1.Text="1ª opção"
$tabOp2=New-Object Windows.Forms.TabPage; $tabOp2.Text="2ª opção"
$tabOp3=New-Object Windows.Forms.TabPage; $tabOp3.Text="3ª opção"
$tabOpcoes.TabPages.AddRange(@($tabOp1,$tabOp2,$tabOp3))

$script:Opt1=New-OptionGroup "1ª OPÇÃO" 8 5; $tabOp1.Controls.Add($script:Opt1.Group)
$script:Opt2=New-OptionGroup "2ª OPÇÃO" 8 5; $tabOp2.Controls.Add($script:Opt2.Group)
$script:Opt3=New-OptionGroup "3ª OPÇÃO" 8 5; $tabOp3.Controls.Add($script:Opt3.Group)
# V1.0.114 - FR visivel em cada aba, sem abrir a janela de edicao.
foreach($item in @(@($script:Opt1,$tabOp1),@($script:Opt2,$tabOp2),@($script:Opt3,$tabOp3))){
    $obj=$item[0];$pagina=$item[1]
    $pagina.AutoScroll=$true
    $pagina.AutoScrollMinSize=New-Object Drawing.Size(410,246)
    $lb=New-Object System.Windows.Forms.Label
    $lb.Location=New-Object Drawing.Point(9,174)
    $lb.Size=New-Object Drawing.Size(405,20)
    $lb.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold)
    $lb.ForeColor=[Drawing.Color]::FromArgb(39,85,138)
    $lb.Text='FR 20 dias: não cadastrada'
    $lb.Visible=$false
    $pagina.Controls.Add($lb)
    $obj.FRSummary=$lb
    $obj.FRTab=$pagina
}


$grpImpacto=New-Object Windows.Forms.GroupBox
$grpImpacto.Text="Prévia do impacto — opção em uso"
$grpImpacto.Location=New-Object Drawing.Point(450,420)
$grpImpacto.Size=New-Object Drawing.Size(230,205)
$editor.Controls.Add($grpImpacto)

$grpImpacto.Controls.Add((New-Label "Ano" 10 20 40 18))
$script:cmbImpactoAno=New-Combo 50 17 75
[void]$script:cmbImpactoAno.Items.Add("2027")
[void]$script:cmbImpactoAno.Items.Add("2028")
$script:cmbImpactoAno.SelectedIndex=0
$grpImpacto.Controls.Add($script:cmbImpactoAno)

$script:lblImpactoStatus=New-Object Windows.Forms.Label
$script:lblImpactoStatus.Location=New-Object Drawing.Point(10,45)
$script:lblImpactoStatus.Size=New-Object Drawing.Size(210,45)
$script:lblImpactoStatus.Text="Selecione um período."
$grpImpacto.Controls.Add($script:lblImpactoStatus)

$script:gridImpacto=New-Object Windows.Forms.DataGridView
$script:gridImpacto.Location=New-Object Drawing.Point(10,92)
$script:gridImpacto.Size=New-Object Drawing.Size(210,102)
$script:gridImpacto.ReadOnly=$true
$script:gridImpacto.AllowUserToAddRows=$false
$script:gridImpacto.RowHeadersVisible=$false
$script:gridImpacto.BackgroundColor=[Drawing.Color]::White
$script:gridImpacto.AutoSizeColumnsMode="Fill"
$script:gridImpacto.ColumnHeadersHeight=20
$script:gridImpacto.RowTemplate.Height=20
foreach($c in @(
    @("impMes","Mês"),
    @("impAtual","Atual"),
    @("impSim","Após"),
    @("impLimite","Lim."),
    @("impSituacao","Sit.")
)){ [void]$script:gridImpacto.Columns.Add($c[0],$c[1]) }
$script:gridImpacto.Columns["impMes"].FillWeight=22
$script:gridImpacto.Columns["impAtual"].FillWeight=18
$script:gridImpacto.Columns["impSim"].FillWeight=18
$script:gridImpacto.Columns["impLimite"].FillWeight=16
$script:gridImpacto.Columns["impSituacao"].FillWeight=26
$grpImpacto.Controls.Add($script:gridImpacto)

# V1.0.58: separar visualmente os dois campos textuais para evitar a impressão de duplicidade.
$lblObsGeral=New-Object Windows.Forms.Label
$lblObsGeral.Text="OBSERVAÇÕES GERAIS DO PERÍODO AQUISITIVO"
$lblObsGeral.Location=New-Object Drawing.Point(15,635)
$lblObsGeral.Size=New-Object Drawing.Size(420,22)
$lblObsGeral.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$editor.Controls.Add($lblObsGeral)

$lblObsGeralAjuda=New-Object Windows.Forms.Label
$lblObsGeralAjuda.Text="Informações administrativas ou permanentes deste período aquisitivo."
$lblObsGeralAjuda.Location=New-Object Drawing.Point(15,657)
$lblObsGeralAjuda.Size=New-Object Drawing.Size(600,20)
$lblObsGeralAjuda.ForeColor=[Drawing.Color]::DimGray
$editor.Controls.Add($lblObsGeralAjuda)

$script:txtObs=New-TextBox 15 679 665
$script:txtObs.Multiline=$true
$script:txtObs.Height=56
$script:txtObs.ScrollBars="Vertical"
$editor.Controls.Add($script:txtObs)

$lblJustDec=New-Object Windows.Forms.Label
$lblJustDec.Text="JUSTIFICATIVA DA DECISÃO DE FÉRIAS"
$lblJustDec.Location=New-Object Drawing.Point(15,750)
$lblJustDec.Size=New-Object Drawing.Size(420,22)
$lblJustDec.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$editor.Controls.Add($lblJustDec)

$lblJustDecAjuda=New-Object Windows.Forms.Label
$lblJustDecAjuda.Text="Motivo da escolha, alteração ou não escolha da opção de férias (opcional; obrigatória em conflito crítico)."
$lblJustDecAjuda.Location=New-Object Drawing.Point(15,772)
$lblJustDecAjuda.Size=New-Object Drawing.Size(665,20)
$lblJustDecAjuda.ForeColor=[Drawing.Color]::DimGray
$editor.Controls.Add($lblJustDecAjuda)

$script:txtJustificativaDecisao=New-Object Windows.Forms.TextBox
$script:txtJustificativaDecisao.Location=New-Object Drawing.Point(15,794)
$script:txtJustificativaDecisao.Size=New-Object Drawing.Size(665,64)
$script:txtJustificativaDecisao.Multiline=$true
$script:txtJustificativaDecisao.ScrollBars="Vertical"
$script:txtJustificativaDecisao.MaxLength=1000
$editor.Controls.Add($script:txtJustificativaDecisao)
$editor.AutoScrollMinSize=New-Object Drawing.Size(700,900)




function Get-MesesOpcaoObjeto($op,[int]$ano){
    if($null -eq $op){return @()}
    return @(Get-MesesBlocosAno (Get-OptionBlocksObjeto $op) $ano)
}

function Get-OptionBlocksObjeto($op){
    $blocks=@()
    if($null -eq $op){ return @() }
    if([string]$op.tipo -eq 'FÉRIAS FIXAS' -and $null -ne $op.PSObject.Properties['blocos_fixos']){
        return @($op.blocos_fixos)
    }

    $s1=Parse-Date ([string]$op.inicio1)
    $e1=Parse-Date ([string]$op.fim1)
    if($null -ne $s1 -and $null -ne $e1){
        $blocks += [pscustomobject]@{ inicio=$s1; fim=$e1 }
    }

    if(([string]$op.tipo) -match "^15\+15 DIAS"){
        $s2=Parse-Date ([string]$op.inicio2)
        $e2=Parse-Date ([string]$op.fim2)
        if($null -ne $s2 -and $null -ne $e2){
            $blocks += [pscustomobject]@{ inicio=$s2; fim=$e2 }
        }
    }

    $frI=Parse-Date ([string]$op.fr_inicio); $frF=Parse-Date ([string]$op.fr_fim)
    if($null -ne $frI -and $null -ne $frF -and ($frF-$frI).Days -eq 19){
        $blocks += [pscustomobject]@{inicio=$frI;fim=$frF;tipo='FR 20 DIAS'}
    }
    return @($blocks)
}


function Get-ContagemSetorPeriodoMes([string]$setor,[string]$periodo,[int]$ano,[int]$mes,[int]$excluirId=0,$opSimulada=$null,[string]$matriculaSimulada=""){
    $ids=New-Object 'System.Collections.Generic.HashSet[string]'

    foreach($r in $script:Records){
        if([int]$r.id -eq $excluirId){ continue }
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }

        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        $meses=Get-MesesPlanejamentoRegistro $r $ano
        if($meses -contains $mes){ [void]$ids.Add([string]$r.matricula) }
    }

    if($null -ne $opSimulada -and -not [string]::IsNullOrWhiteSpace($matriculaSimulada)){
        $mesesSim=Get-MesesOpcaoObjeto $opSimulada $ano
        if($mesesSim -contains $mes){ [void]$ids.Add($matriculaSimulada) }
    }

    return $ids.Count
}

function Refresh-PreviaImpacto {
    if($null -eq $script:gridImpacto){ return }
    $swPerf=[Diagnostics.Stopwatch]::StartNew()

    $setor=([string]$script:cmbSetor.Text).Trim()
    $periodo=([string]$script:cmbPeriodo.Text).Trim()
    if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

    $script:gridImpacto.Rows.Clear()

    if([string]::IsNullOrWhiteSpace($setor) -or [int]$script:CurrentId -le 0){
        $script:lblImpactoStatus.Text="Selecione um servidor, um período aquisitivo e informe Setor/Período."
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DimGray
        return
    }

    $ano=2027
    if($null -ne $script:cmbImpactoAno.SelectedItem){
        $ano=[int][string]$script:cmbImpactoAno.SelectedItem
    }

    $rAtual=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
    if($null -eq $rAtual){ return }

    $nPlanej=Get-NumeroOpcaoPlanejamento $rAtual
    $opSalva=Get-OpcaoPlanejamento $rAtual
    switch($nPlanej){
        2 { $opSim=Read-OptionFromControls $script:Opt2 }
        3 { $opSim=Read-OptionFromControls $script:Opt3 }
        default { $opSim=Read-OptionFromControls $script:Opt1 }
    }
    $rotuloPlanej=Get-DescricaoBasePlanejamento $rAtual
    $mat=[string]$rAtual.matricula
    $limite=Get-LimiteSetorPeriodo $setor $periodo
    $grupoChefia=Get-GrupoChefiaEfetivaRegistro $rAtual
    $limiteChefia=Get-LimiteGrupoChefiaPeriodo $grupoChefia $periodo
    $registroSim=[pscustomobject]@{id=[int]$rAtual.id;matricula=$mat;setor=$setor;periodo=$periodo}
    $mesNomes=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")

    $mesesSim=@(Get-MesesOpcaoObjeto $opSim $ano)
    $mesesSalvos=@(Get-MesesOpcaoObjeto $opSalva $ano)

    $acima=@()
    $noLimite=@()
    $acimaChefia=@()
    $noLimiteChefia=@()
    $alterados=@()

    for($m=1;$m -le 12;$m++){
        $baseInfo=Get-PlanejamentoOverlapInfoCached $setor $periodo $ano $m
        $atual=[int]$baseInfo.qtd_mes
        $precisaSimular=(($mesesSalvos -contains $m) -or ($mesesSim -contains $m))
        if($precisaSimular){
            $simulado=Get-ContagemSetorPeriodoMes $setor $periodo $ano $m ([int]$script:CurrentId) $opSim $mat
        } else {
            $simulado=$atual
        }

        $idx=$script:gridImpacto.Rows.Add()
        $row=$script:gridImpacto.Rows[$idx]
        $row.Cells["impMes"].Value=$mesNomes[$m-1]
        $row.Cells["impAtual"].Value=$atual
        $row.Cells["impSim"].Value=$simulado
        $row.Cells["impLimite"].Value=if($limite -gt 0){$limite}else{"—"}

        $mudou=($atual -ne $simulado)
        if($mudou){
            $alterados += $mesNomes[$m-1]
            $row.DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
        }

        if($limite -le 0){
            $row.Cells["impSituacao"].Value=if($mudou){"ALTERA"}else{"SEM LIMITE"}
            $row.Cells["impSituacao"].Style.BackColor=if($mudou){[Drawing.Color]::LightBlue}else{[Drawing.Color]::Gainsboro}
        } elseif($simulado -gt $limite){
            $row.Cells["impSituacao"].Value="ACIMA"
            $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::MistyRose
            $acima += $mesNomes[$m-1]
        } elseif($simulado -eq $limite -and $simulado -gt 0){
            $row.Cells["impSituacao"].Value="NO LIMITE"
            $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::FromArgb(255,244,204)
            $noLimite += $mesNomes[$m-1]
        } elseif($simulado -gt 0){
            $row.Cells["impSituacao"].Value=if($mudou){"ALTERA"}else{"OK"}
            $row.Cells["impSituacao"].Style.BackColor=if($mudou){[Drawing.Color]::LightBlue}else{[Drawing.Color]::FromArgb(226,239,218)}
        } else {
            $row.Cells["impSituacao"].Value=""
            $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::White
        }

        if($grupoChefia){
            $chefAtual=Get-GrupoChefiaOverlapInfoCached $grupoChefia $periodo $ano $m
            if($precisaSimular){
                $chefSim=Get-SimulacaoGrupoChefiaPeriodoMes $registroSim $opSim $ano $m
            } else {
                $chefSim=$chefAtual
            }
            $row.Cells["impSituacao"].ToolTipText="Grupo de Chefia: $grupoChefia`r`nAtual: $($chefAtual.qtd_mes) no mês | pico $($chefAtual.pico)`r`nApós: $($chefSim.qtd_mes) no mês | pico $($chefSim.pico)`r`nLimite do grupo/período: $(if($limiteChefia -gt 0){$limiteChefia}else{'não configurado'})"

            if($limiteChefia -gt 0){
                if($chefSim.pico -gt $limiteChefia){
                    $row.Cells["impSituacao"].Value="CHEFIA CRÍT."
                    $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::MistyRose
                    $acimaChefia += $mesNomes[$m-1]
                } elseif($chefSim.qtd_mes -gt $limiteChefia){
                    $row.Cells["impSituacao"].Value="CHEFIA >"
                    $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::PeachPuff
                    $acimaChefia += $mesNomes[$m-1]
                } elseif($chefSim.qtd_mes -eq $limiteChefia -and $chefSim.qtd_mes -gt 0){
                    if([string]::IsNullOrWhiteSpace([string]$row.Cells["impSituacao"].Value) -or [string]$row.Cells["impSituacao"].Value -eq "OK"){
                        $row.Cells["impSituacao"].Value="CHEFIA LIM."
                        $row.Cells["impSituacao"].Style.BackColor=[Drawing.Color]::FromArgb(255,244,204)
                    }
                    $noLimiteChefia += $mesNomes[$m-1]
                }
            }
        }

        $origens=@()
        if($mesesSalvos -contains $m){ $origens += "opção atualmente usada no planejamento deste servidor" }
        if($mesesSim -contains $m){ $origens += "opção em uso que está sendo simulada" }
        if($atual -gt 0 -and $mesesSalvos -notcontains $m){ $origens += "outros servidores do mesmo Setor/Período" }
        if($origens.Count -gt 0){
            $row.Cells["impMes"].ToolTipText=($origens -join "; ")
        }
    }

    if($acimaChefia.Count -gt 0){
        $script:lblImpactoStatus.Text="⚠ GRUPO DE CHEFIA ACIMA DO LIMITE: $(($acimaChefia | Select-Object -Unique) -join ', ')"
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkRed
    } elseif($acima.Count -gt 0){
        $script:lblImpactoStatus.Text="⚠ ACIMA DO LIMITE DO SETOR: $($acima -join ', ')"
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkRed
    } elseif($noLimiteChefia.Count -gt 0){
        $script:lblImpactoStatus.Text="Grupo de Chefia no limite em: $(($noLimiteChefia | Select-Object -Unique) -join ', ')"
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkGoldenrod
    } elseif($noLimite.Count -gt 0){
        $script:lblImpactoStatus.Text="Setor no limite em: $($noLimite -join ', ')"
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkGoldenrod
    } elseif($limite -le 0){
        if($alterados.Count -gt 0){
            $script:lblImpactoStatus.Text="$setor | $periodo | $rotuloPlanej — meses alterados: $($alterados -join ', '). Limite do setor ainda não configurado."
            $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkBlue
        } else {
            $script:lblImpactoStatus.Text="$setor | $periodo — nenhuma mudança na opção em uso para $ano. Limite do setor ainda não configurado."
            $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DimGray
        }
    } elseif($alterados.Count -gt 0){
        $script:lblImpactoStatus.Text="Meses alterados pela edição: $($alterados -join ', ')"
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkBlue
    } else {
        $script:lblImpactoStatus.Text="Sem alteração na opção em uso para $ano."
        $script:lblImpactoStatus.ForeColor=[Drawing.Color]::DarkGreen
    }

    $swPerf.Stop()
    if($swPerf.ElapsedMilliseconds -ge 250){ Write-DiagLog "PERF Refresh-PreviaImpacto: $($swPerf.ElapsedMilliseconds) ms | servidor=$mat | $setor/$periodo" "WARN" }
}

function Get-LimiteSetorPeriodo([string]$setor,[string]$periodo){
    foreach($x in @($script:Config.limites_setor_periodo)){
        if([string]$x.setor -eq $setor -and [string]$x.periodo -eq $periodo){
            return [int]$x.limite
        }
    }
    return 0
}

function Set-LimiteSetorPeriodo([string]$setor,[string]$periodo,[int]$limite){
    $nova=@()
    $achou=$false
    foreach($x in @($script:Config.limites_setor_periodo)){
        if([string]$x.setor -eq $setor -and [string]$x.periodo -eq $periodo){
            $achou=$true
            if($limite -gt 0){
                $nova += [pscustomobject]@{setor=$setor;periodo=$periodo;limite=$limite}
            }
        } else {
            $nova += $x
        }
    }
    if(-not $achou -and $limite -gt 0){
        $nova += [pscustomobject]@{setor=$setor;periodo=$periodo;limite=$limite}
    }
    $script:Config.limites_setor_periodo=@($nova)
}

function Abrir-ConfigLimitesSetorPeriodo {
    $combos=@{}
    foreach($r in $script:Records){
        $setor=([string]$r.setor).Trim()
        $per=([string]$r.periodo).Trim()
        if(-not $setor){ continue }
        if(-not $per){ $per="SEM PERÍODO" }
        $combos["$setor|||$per"]=[pscustomobject]@{setor=$setor;periodo=$per}
    }

    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Limites por Setor e Período"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(780,650)
    $dlg.MinimumSize=New-Object Drawing.Size(700,520)
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $lbl=New-Object Windows.Forms.Label
    $lbl.Text="Defina o máximo de servidores considerados na base consolidada de férias no mesmo mês para cada Setor + Período. Limite 0 = sem limite configurado."
    $lbl.Dock="Top"
    $lbl.Height=48
    $lbl.Padding=New-Object Windows.Forms.Padding(10,10,10,0)
    $dlg.Controls.Add($lbl)

    $g=New-Object Windows.Forms.DataGridView
    $g.Dock="Fill"
    $g.AllowUserToAddRows=$false
    $g.AllowUserToDeleteRows=$false
    $g.RowHeadersVisible=$false
    $g.AutoSizeColumnsMode="Fill"
    $g.BackgroundColor=[Drawing.Color]::White
    [void]$g.Columns.Add("cfgSetor","Setor")
    [void]$g.Columns.Add("cfgPeriodo","Período")
    [void]$g.Columns.Add("cfgLimite","Limite mensal")
    $g.Columns["cfgSetor"].ReadOnly=$true
    $g.Columns["cfgPeriodo"].ReadOnly=$true
    $g.Columns["cfgSetor"].FillWeight=45
    $g.Columns["cfgPeriodo"].FillWeight=30
    $g.Columns["cfgLimite"].FillWeight=20

    foreach($item in ($combos.Values | Sort-Object setor,periodo)){
        $i=$g.Rows.Add()
        $row=$g.Rows[$i]
        $row.Cells["cfgSetor"].Value=$item.setor
        $row.Cells["cfgPeriodo"].Value=$item.periodo
        $row.Cells["cfgLimite"].Value=(Get-LimiteSetorPeriodo $item.setor $item.periodo)
    }
    $dlg.Controls.Add($g)

    $bottom=New-Object Windows.Forms.Panel
    $bottom.Dock="Bottom"
    $bottom.Height=60
    $dlg.Controls.Add($bottom)

    $btnSalvar=New-Button "Salvar limites" 470 12 130 34
    $bottom.Controls.Add($btnSalvar)
    $btnCancelar=New-Button "Cancelar" 610 12 110 34
    $bottom.Controls.Add($btnCancelar)

    $btnSalvar.add_Click({
        foreach($row in $g.Rows){
            if($row.IsNewRow){ continue }
            $setor=[string]$row.Cells["cfgSetor"].Value
            $per=[string]$row.Cells["cfgPeriodo"].Value
            $limite=0
            [int]::TryParse([string]$row.Cells["cfgLimite"].Value,[ref]$limite) | Out-Null
            if($limite -lt 0){ $limite=0 }
            Set-LimiteSetorPeriodo $setor $per $limite
        }
        Save-Database
        Refresh-PlanejamentoSetor
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $btnCancelar.add_Click({
        $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })

    [void]$dlg.ShowDialog($form)
}

function Abrir-ConfigLimitesGrupoChefiaPeriodo {
    $grupos=@(Get-GruposChefiaNomes)
    if($grupos.Count -eq 0){
        [Windows.Forms.MessageBox]::Show(
            "Nenhum Grupo de Chefia está cadastrado.`n`nVá em Cadastros > Setores e Chefias e crie pelo menos uma chefia.",
            "Grupos de Chefia",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $periodos=@()
    $periodos += @($script:Config.periodos)
    $periodos += @($script:Records | ForEach-Object {
        $p=([string]$_.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($p)){"SEM PERÍODO"}else{$p}
    })
    $periodos=@($periodos | Where-Object { $_ } | Sort-Object -Unique)

    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Limites por Grupo de Chefia e Período"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(930,690)
    $dlg.MinimumSize=New-Object Drawing.Size(820,560)
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)
    $dlg.AutoScaleMode=[Windows.Forms.AutoScaleMode]::Dpi

    $layout=New-Object Windows.Forms.TableLayoutPanel
    $layout.Dock="Fill"
    $layout.ColumnCount=1
    $layout.RowCount=3
    [void]$layout.ColumnStyles.Add(([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent,100)))
    [void]$layout.RowStyles.Add(([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute,82)))
    [void]$layout.RowStyles.Add(([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent,100)))
    [void]$layout.RowStyles.Add(([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute,66)))
    $dlg.Controls.Add($layout)

    $top=New-Object Windows.Forms.Panel
    $top.Dock="Fill"
    $top.Padding=New-Object Windows.Forms.Padding(12,10,12,6)
    $lbl=New-Object Windows.Forms.Label
    $lbl.Dock="Fill"
    $lbl.Text="LIMITES POR CHEFIA E PERÍODO`r`nSetores e servidores vinculados à mesma chefia são somados por mês + período. Informe o limite de capacidade do conjunto. Limite 0 = somente informação, sem alerta."
    $lbl.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $lbl.AutoEllipsis=$true
    $top.Controls.Add($lbl)
    $layout.Controls.Add($top,0,0)

    $g=New-Object Windows.Forms.DataGridView
    $g.Dock="Fill"
    $g.AllowUserToAddRows=$false
    $g.AllowUserToDeleteRows=$false
    $g.RowHeadersVisible=$false
    $g.AutoSizeColumnsMode="Fill"
    $g.BackgroundColor=[Drawing.Color]::White
    $g.SelectionMode="FullRowSelect"
    $g.MultiSelect=$false
    $g.ColumnHeadersVisible=$true
    $g.ColumnHeadersHeightSizeMode=[Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
    $g.AutoSizeRowsMode=[Windows.Forms.DataGridViewAutoSizeRowsMode]::None
    [void]$g.Columns.Add("cfgChefia","Grupo de Chefia")
    [void]$g.Columns.Add("cfgPer","Período")
    [void]$g.Columns.Add("cfgLim","Limite do grupo")
    $g.Columns["cfgChefia"].ReadOnly=$true
    $g.Columns["cfgPer"].ReadOnly=$true
    $g.Columns["cfgChefia"].FillWeight=48
    $g.Columns["cfgPer"].FillWeight=30
    $g.Columns["cfgLim"].FillWeight=22

    foreach($grupo in $grupos){
        foreach($per in $periodos){
            $i=$g.Rows.Add()
            $row=$g.Rows[$i]
            $row.Cells["cfgChefia"].Value=$grupo
            $row.Cells["cfgPer"].Value=$per
            $row.Cells["cfgLim"].Value=(Get-LimiteGrupoChefiaPeriodo $grupo $per)
        }
    }
    $layout.Controls.Add($g,0,1)

    $bottom=New-Object Windows.Forms.Panel
    $bottom.Dock="Fill"
    $bottom.Padding=New-Object Windows.Forms.Padding(10)
    $layout.Controls.Add($bottom,0,2)

    $btnSalvar=New-Button "Salvar limites" 0 10 140 36
    $btnSalvar.Anchor="Top,Right"
    $bottom.Controls.Add($btnSalvar)
    $btnCancelar=New-Button "Cancelar" 0 10 120 36
    $btnCancelar.Anchor="Top,Right"
    $bottom.Controls.Add($btnCancelar)

    $reposicionarBotoes={
        $btnCancelar.Left=[math]::Max(10,$bottom.ClientSize.Width-$btnCancelar.Width-12)
        $btnSalvar.Left=[math]::Max(10,$btnCancelar.Left-$btnSalvar.Width-12)
    }.GetNewClosure()
    $bottom.add_Resize({&$reposicionarBotoes}.GetNewClosure())
    &$reposicionarBotoes

    $btnSalvar.add_Click({
        foreach($row in $g.Rows){
            if($row.IsNewRow){ continue }
            $grupo=[string]$row.Cells["cfgChefia"].Value
            $per=[string]$row.Cells["cfgPer"].Value
            $limite=0
            [int]::TryParse([string]$row.Cells["cfgLim"].Value,[ref]$limite) | Out-Null
            if($limite -lt 0){ $limite=0 }
            Set-LimiteGrupoChefiaPeriodo $grupo $per $limite
        }
        Save-Database
        Refresh-PlanejamentoSetor
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $btnCancelar.add_Click({
        $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })

    [void]$dlg.ShowDialog($form)
}

function Get-PrimeiraOpcaoMeses($rec,[int]$ano){
    $meses=New-Object 'System.Collections.Generic.HashSet[int]'
    foreach($b in (Get-OptionBlocks $rec 1)){
        $inicio=[datetime]$b.inicio
        $fim=[datetime]$b.fim
        $cursor=Get-Date -Year $inicio.Year -Month $inicio.Month -Day 1
        $ultimo=Get-Date -Year $fim.Year -Month $fim.Month -Day 1
        while($cursor -le $ultimo){
            if($cursor.Year -eq $ano){ [void]$meses.Add($cursor.Month) }
            $cursor=$cursor.AddMonths(1)
        }
    }
    return @($meses)
}


function Update-PlanejSetoresResumo {
    if($null -eq $script:txtPlanejSetoresResumo){ return }
    if($script:PlanejSetoresSelecionados.Count -eq 0){
        $script:txtPlanejSetoresResumo.Text="TODOS OS SETORES"
    } elseif($script:PlanejSetoresSelecionados.Count -eq 1){
        $script:txtPlanejSetoresResumo.Text=$script:PlanejSetoresSelecionados[0]
    } else {
        $script:txtPlanejSetoresResumo.Text="$($script:PlanejSetoresSelecionados.Count) SETORES SELECIONADOS"
    }
}

function Update-PlanejPeriodosResumo {
    if($null -eq $script:txtPlanejPeriodosResumo){ return }
    if($script:PlanejPeriodosSelecionados.Count -eq 0){
        $script:txtPlanejPeriodosResumo.Text="TODOS OS PERÍODOS"
    } elseif($script:PlanejPeriodosSelecionados.Count -eq 1){
        $script:txtPlanejPeriodosResumo.Text=$script:PlanejPeriodosSelecionados[0]
    } else {
        $script:txtPlanejPeriodosResumo.Text="$($script:PlanejPeriodosSelecionados.Count) PERÍODOS SELECIONADOS"
    }
}

function Selecionar-PlanejMultiplosSetores {
    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Planejamento por Setor - selecionar setores"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(480,600)
    $dlg.MinimizeBox=$false
    $dlg.MaximizeBox=$false
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $lbl=New-Object Windows.Forms.Label
    $lbl.Text="Marque um ou mais setores. Nenhum marcado = TODOS."
    $lbl.Location=New-Object Drawing.Point(15,15)
    $lbl.Size=New-Object Drawing.Size(420,24)
    $dlg.Controls.Add($lbl)

    $clb=New-Object Windows.Forms.CheckedListBox
    $clb.Location=New-Object Drawing.Point(15,45)
    $clb.Size=New-Object Drawing.Size(430,445)
    $clb.CheckOnClick=$true
    foreach($setor in @($script:Config.setores | Sort-Object -Unique)){
        $idx=$clb.Items.Add($setor)
        if($script:PlanejSetoresSelecionados -contains $setor){ $clb.SetItemChecked($idx,$true) }
    }
    $dlg.Controls.Add($clb)

    $btnTodos=New-Button "Limpar / Todos" 15 505 120 32
    $dlg.Controls.Add($btnTodos)
    $btnOK=New-Button "OK" 275 505 80 32
    $dlg.Controls.Add($btnOK)
    $btnCancelar=New-Button "Cancelar" 365 505 80 32
    $dlg.Controls.Add($btnCancelar)

    $btnTodos.add_Click({
        for($i=0;$i -lt $clb.Items.Count;$i++){ $clb.SetItemChecked($i,$false) }
    })
    $btnOK.add_Click({
        $sel=@()
        foreach($x in $clb.CheckedItems){ $sel += [string]$x }
        $script:PlanejSetoresSelecionados=@($sel)
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $btnCancelar.add_Click({
        $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })

    [void]$dlg.ShowDialog($form)
    Update-PlanejSetoresResumo
    Refresh-PlanejamentoSetor
}

function Selecionar-PlanejMultiplosPeriodos {
    $itens=@()
    if($null -ne $script:Config.periodos -and @($script:Config.periodos).Count -gt 0){
        $itens=@($script:Config.periodos | Sort-Object -Unique)
    } else {
        $itens=@($script:Records | ForEach-Object { ([string]$_.periodo).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    }

    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Planejamento por Setor - selecionar períodos"
    $dlg.StartPosition="CenterParent"
    $dlg.Size=New-Object Drawing.Size(420,500)
    $dlg.MinimizeBox=$false
    $dlg.MaximizeBox=$false
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $lbl=New-Object Windows.Forms.Label
    $lbl.Text="Marque um ou mais períodos. Nenhum marcado = TODOS."
    $lbl.Location=New-Object Drawing.Point(15,15)
    $lbl.Size=New-Object Drawing.Size(360,24)
    $dlg.Controls.Add($lbl)

    $clb=New-Object Windows.Forms.CheckedListBox
    $clb.Location=New-Object Drawing.Point(15,45)
    $clb.Size=New-Object Drawing.Size(370,335)
    $clb.CheckOnClick=$true
    foreach($per in $itens){
        $idx=$clb.Items.Add($per)
        if($script:PlanejPeriodosSelecionados -contains $per){ $clb.SetItemChecked($idx,$true) }
    }
    $dlg.Controls.Add($clb)

    $btnTodos=New-Button "Limpar / Todos" 15 395 120 32
    $dlg.Controls.Add($btnTodos)
    $btnOK=New-Button "OK" 215 395 80 32
    $dlg.Controls.Add($btnOK)
    $btnCancelar=New-Button "Cancelar" 305 395 80 32
    $dlg.Controls.Add($btnCancelar)

    $btnTodos.add_Click({
        for($i=0;$i -lt $clb.Items.Count;$i++){ $clb.SetItemChecked($i,$false) }
    })
    $btnOK.add_Click({
        $sel=@()
        foreach($x in $clb.CheckedItems){ $sel += [string]$x }
        $script:PlanejPeriodosSelecionados=@($sel)
        $dlg.DialogResult=[Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $btnCancelar.add_Click({
        $dlg.DialogResult=[Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })

    [void]$dlg.ShowDialog($form)
    Update-PlanejPeriodosResumo
    Refresh-PlanejamentoSetor
}


function Convert-ToUpperSemAcento([string]$texto){
    if([string]::IsNullOrWhiteSpace($texto)){ return "" }
    $normalizado=$texto.Normalize([Text.NormalizationForm]::FormD)
    $sb=New-Object Text.StringBuilder
    foreach($ch in $normalizado.ToCharArray()){
        $cat=[Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if($cat -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$sb.Append($ch) }
    }
    return $sb.ToString().Normalize([Text.NormalizationForm]::FormC).Trim().ToUpperInvariant()
}

function Get-SetorPlanejamentoChave([string]$setor){
    $s=([string]$setor).Trim()
    if([string]::IsNullOrWhiteSpace($s)){ return "PENDENTE DE SETOR" }
    return $s
}

function Test-SetorPlanejamentoPendente([string]$setor){
    return (([string]$setor).Trim() -eq "PENDENTE DE SETOR")
}

function Get-GrupoAnaliseSetor([string]$setor){
    $alvo=([string]$setor).Trim()
    if([string]::IsNullOrWhiteSpace($alvo) -or (Test-SetorPlanejamentoPendente $alvo)){ return "PENDENTE DE CLASSIFICAÇÃO" }
    foreach($x in @($script:Config.grupo_analise_setores)){
        if(([string]$x.setor).Trim() -eq $alvo){
            $g=([string]$x.grupo).Trim()
            if($g){ return $g }
        }
    }

    # Fallback defensivo para bases antigas que ainda não tenham a classificação explícita.
    $n=Convert-ToUpperSemAcento $alvo
    if($n -match 'DIRETORIA\s+DE\s+ENFERMAGEM'){ return "DIRETORIA DE ENFERMAGEM" }
    if($n -match 'GERENCIA\s+DE\s+ENFERMAGEM'){ return "GERÊNCIA DE ENFERMAGEM" }
    return "ASSISTENCIAL"
}

function Set-GrupoAnaliseSetor([string]$setor,[string]$grupo){
    $setor=([string]$setor).Trim()
    $grupo=([string]$grupo).Trim()
    if(-not $setor){ return }
    if(@("ASSISTENCIAL","GERÊNCIA DE ENFERMAGEM","DIRETORIA DE ENFERMAGEM") -notcontains $grupo){
        $grupo="ASSISTENCIAL"
    }

    $nova=@()
    $achou=$false
    foreach($x in @($script:Config.grupo_analise_setores)){
        if(([string]$x.setor).Trim() -eq $setor){
            if(-not $achou){ $nova += [pscustomobject]@{setor=$setor;grupo=$grupo}; $achou=$true }
        } else {
            $nova += $x
        }
    }
    if(-not $achou){ $nova += [pscustomobject]@{setor=$setor;grupo=$grupo} }
    $script:Config.grupo_analise_setores=@($nova)
}

function Get-GrupoChefiaSetor([string]$setor){
    $alvo=([string]$setor).Trim()
    foreach($x in @($script:Config.grupo_chefia_setores)){
        if(([string]$x.setor).Trim() -eq $alvo){
            return ([string]$x.grupo).Trim()
        }
    }
    return ""
}

function Set-GrupoChefiaSetor([string]$setor,[string]$grupo){
    $setor=([string]$setor).Trim()
    $grupo=([string]$grupo).Trim()
    if(-not $setor){ return }

    $nova=@()
    foreach($x in @($script:Config.grupo_chefia_setores)){
        if(([string]$x.setor).Trim() -ne $setor){ $nova += $x }
    }
    if($grupo){ $nova += [pscustomobject]@{setor=$setor;grupo=$grupo} }
    $script:Config.grupo_chefia_setores=@($nova)
}

function Get-GrupoChefiaServidor([string]$matricula){
    $matricula=([string]$matricula).Trim()
    if(-not $matricula){ return "" }
    foreach($x in @($script:Config.grupo_chefia_servidores)){
        if(([string]$x.matricula).Trim() -eq $matricula){
            return ([string]$x.grupo).Trim()
        }
    }
    return ""
}

function Set-GrupoChefiaServidor([string]$matricula,[string]$grupo){
    $matricula=([string]$matricula).Trim()
    $grupo=([string]$grupo).Trim()
    if(-not $matricula){ return }

    $nova=@()
    foreach($x in @($script:Config.grupo_chefia_servidores)){
        if(([string]$x.matricula).Trim() -ne $matricula){ $nova += $x }
    }
    if($grupo){ $nova += [pscustomobject]@{matricula=$matricula;grupo=$grupo} }
    $script:Config.grupo_chefia_servidores=@($nova)
}

function Get-GrupoChefiaEfetivaRegistro($registro){
    if($null -eq $registro){ return "" }
    $mat=([string]$registro.matricula).Trim()
    $direta=Get-GrupoChefiaServidor $mat
    if($direta){ return $direta }
    return Get-GrupoChefiaSetor ([string]$registro.setor)
}

function Get-OrigemGrupoChefiaRegistro($registro){
    if($null -eq $registro){ return "SEM CHEFIA" }
    $direta=Get-GrupoChefiaServidor ([string]$registro.matricula)
    if($direta){ return "INDIVIDUAL" }
    $porSetor=Get-GrupoChefiaSetor ([string]$registro.setor)
    if($porSetor){ return "HERDADA DO SETOR" }
    return "SEM CHEFIA"
}

function Get-GruposChefiaNomes {
    $nomes=@()
    $nomes += @($script:Config.grupos_chefia)
    $nomes += @($script:Config.grupo_chefia_setores | ForEach-Object { ([string]$_.grupo).Trim() })
    $nomes += @($script:Config.grupo_chefia_servidores | ForEach-Object { ([string]$_.grupo).Trim() })
    $nomes += @($script:Config.limites_grupo_chefia_periodo | ForEach-Object { ([string]$_.grupo).Trim() })
    return @($nomes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

function Add-GrupoChefiaNome([string]$nome){
    $nome=([string]$nome).Trim()
    if(-not $nome){ return $false }
    if(@(Get-GruposChefiaNomes) -contains $nome){ return $false }
    $script:Config.grupos_chefia=@(@($script:Config.grupos_chefia)+$nome | Sort-Object -Unique)
    return $true
}

function Rename-GrupoChefiaNome([string]$antigo,[string]$novo){
    $antigo=([string]$antigo).Trim()
    $novo=([string]$novo).Trim()
    if(-not $antigo -or -not $novo){ return $false }
    if($antigo -ne $novo -and @(Get-GruposChefiaNomes) -contains $novo){ return $false }

    $lista=@()
    foreach($g in @($script:Config.grupos_chefia)){
        if(([string]$g).Trim() -ne $antigo){ $lista += [string]$g }
    }
    $lista += $novo
    $script:Config.grupos_chefia=@($lista | Sort-Object -Unique)

    foreach($x in @($script:Config.grupo_chefia_setores)){
        if(([string]$x.grupo).Trim() -eq $antigo){ $x.grupo=$novo }
    }
    foreach($x in @($script:Config.grupo_chefia_servidores)){
        if(([string]$x.grupo).Trim() -eq $antigo){ $x.grupo=$novo }
    }
    foreach($x in @($script:Config.limites_grupo_chefia_periodo)){
        if(([string]$x.grupo).Trim() -eq $antigo){ $x.grupo=$novo }
    }
    return $true
}

function Remove-GrupoChefiaNome([string]$nome){
    $nome=([string]$nome).Trim()
    if(-not $nome){ return }
    $script:Config.grupos_chefia=@($script:Config.grupos_chefia | Where-Object { ([string]$_).Trim() -ne $nome })
    $script:Config.grupo_chefia_setores=@($script:Config.grupo_chefia_setores | Where-Object { ([string]$_.grupo).Trim() -ne $nome })
    $script:Config.grupo_chefia_servidores=@($script:Config.grupo_chefia_servidores | Where-Object { ([string]$_.grupo).Trim() -ne $nome })
    $script:Config.limites_grupo_chefia_periodo=@($script:Config.limites_grupo_chefia_periodo | Where-Object { ([string]$_.grupo).Trim() -ne $nome })
}

function Refresh-PlanejChefiasFiltro {
    if($null -eq $script:cmbPlanejChefia){ return }
    $anterior=if($null -ne $script:cmbPlanejChefia.SelectedItem){[string]$script:cmbPlanejChefia.SelectedItem}else{"TODOS"}
    $script:cmbPlanejChefia.Items.Clear()
    [void]$script:cmbPlanejChefia.Items.Add("TODOS")
    foreach($g in (Get-GruposChefiaNomes)){ [void]$script:cmbPlanejChefia.Items.Add($g) }
    $idx=$script:cmbPlanejChefia.Items.IndexOf($anterior)
    if($idx -lt 0){ $idx=0 }
    $script:cmbPlanejChefia.SelectedIndex=$idx
}

function Get-PlanejamentoSetorDados([int]$ano,[string]$periodoFiltro){
    $dados=@{}

    foreach($r in $script:Records){
        $setor=Get-SetorPlanejamentoChave ([string]$r.setor)
        $periodo=([string]$r.periodo).Trim()

        if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

        $setorPendente=Test-SetorPlanejamentoPendente $setor
        $grupo=if($setorPendente){"PENDENTE DE CLASSIFICAÇÃO"}else{Get-GrupoAnaliseSetor $setor}
        $grupoFiltro=if([string]::IsNullOrWhiteSpace([string]$script:PlanejGrupoSelecionado)){"TODOS"}else{[string]$script:PlanejGrupoSelecionado}
        $grupoChefia=Get-GrupoChefiaEfetivaRegistro $r
        $chefiaFiltro=if($null -ne $script:cmbPlanejChefia -and $null -ne $script:cmbPlanejChefia.SelectedItem){[string]$script:cmbPlanejChefia.SelectedItem}else{"TODOS"}
        $grupoChefiaLinha=if($chefiaFiltro -ne "TODOS"){$grupoChefia}elseif($setorPendente){""}else{Get-GrupoChefiaSetor $setor}

        if($grupoFiltro -ne "TODOS" -and $grupo -ne $grupoFiltro){ continue }
        if($chefiaFiltro -ne "TODOS" -and $grupoChefia -ne $chefiaFiltro){ continue }
        if(@($script:PlanejSetoresSelecionados).Count -gt 0 -and $script:PlanejSetoresSelecionados -notcontains $setor){ continue }
        if(@($script:PlanejPeriodosSelecionados).Count -gt 0 -and $script:PlanejPeriodosSelecionados -notcontains $periodo){ continue }
        if($periodoFiltro -and $periodoFiltro -ne "TODOS" -and $periodo -ne $periodoFiltro){ continue }

        $meses=Get-MesesPlanejamentoRegistro $r $ano
        $mesesSolic=Get-MesesSolicitacoesRegistro $r $ano
        if($meses.Count -eq 0 -and $mesesSolic.Count -eq 0){ continue }

        $chave="$setor|||$periodo"
        if(-not $dados.ContainsKey($chave)){
            $dados[$chave]=[ordered]@{
                grupo=$grupo
                grupo_chefia=$grupoChefiaLinha
                setor=$setor
                periodo=$periodo
                meses=@{}
                solicitacoes=@{}
            }
            foreach($m in 1..12){
                $dados[$chave].meses[$m]=New-Object 'System.Collections.Generic.HashSet[string]'
                $dados[$chave].solicitacoes[$m]=New-Object 'System.Collections.Generic.HashSet[string]'
            }
        }

        foreach($m in $meses){
            [void]$dados[$chave].meses[$m].Add([string]$r.matricula)
        }
        foreach($m in $mesesSolic){
            [void]$dados[$chave].solicitacoes[$m].Add([string]$r.matricula)
        }
    }
    return $dados
}

function Get-ContadoresPlanejamentoAtual([int]$ano){
    $fixas=0
    $aceitas=0
    $pendentes=0
    $registros=0

    foreach($r in $script:Records){
        $setor=Get-SetorPlanejamentoChave ([string]$r.setor)
        $periodo=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

        $setorPendente=Test-SetorPlanejamentoPendente $setor
        $grupo=if($setorPendente){"PENDENTE DE CLASSIFICAÇÃO"}else{Get-GrupoAnaliseSetor $setor}
        $grupoFiltro=if([string]::IsNullOrWhiteSpace([string]$script:PlanejGrupoSelecionado)){"TODOS"}else{[string]$script:PlanejGrupoSelecionado}
        $grupoChefia=Get-GrupoChefiaEfetivaRegistro $r
        $chefiaFiltro=if($null -ne $script:cmbPlanejChefia -and $null -ne $script:cmbPlanejChefia.SelectedItem){[string]$script:cmbPlanejChefia.SelectedItem}else{"TODOS"}
        if($grupoFiltro -ne "TODOS" -and $grupo -ne $grupoFiltro){ continue }
        if($chefiaFiltro -ne "TODOS" -and $grupoChefia -ne $chefiaFiltro){ continue }
        if(@($script:PlanejSetoresSelecionados).Count -gt 0 -and $script:PlanejSetoresSelecionados -notcontains $setor){ continue }
        if(@($script:PlanejPeriodosSelecionados).Count -gt 0 -and $script:PlanejPeriodosSelecionados -notcontains $periodo){ continue }

        $meses=Get-MesesSolicitacoesRegistro $r $ano
        if($meses.Count -eq 0){ continue }

        $registros++
        switch(Get-StatusPlanejamentoRegistro $r){
            "FIXA" { $fixas++ }
            "ACEITA" { $aceitas++ }
            default { $pendentes++ }
        }
    }

    return [pscustomobject]@{
        registros=$registros
        fixas=$fixas
        aceitas=$aceitas
        pendentes=$pendentes
    }
}

function Test-PlanejamentoCellTemFixa([string]$setor,[string]$periodo,[int]$ano,[int]$mes){
    foreach($r in $script:Records){
        if(-not (Test-RegistroFeriasBloqueadas $r)){ continue }
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }
        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }
        if((Get-MesesPlanejamentoRegistro $r $ano) -contains $mes){ return $true }
    }
    return $false
}

function Test-PlanejamentoLinhaTemBusca([string]$setor,[string]$periodo,[int]$ano,[int]$mesFoco,[string]$busca){
    if([string]::IsNullOrWhiteSpace($busca)){ return $true }
    $q=Convert-ToUpperSemAcento $busca

    foreach($r in $script:Records){
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }
        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        if($mesFoco -gt 0 -and -not ((Get-MesesSolicitacoesRegistro $r $ano) -contains $mesFoco)){ continue }

        $alvo=Convert-ToUpperSemAcento ("$([string]$r.nome) $([string]$r.matricula)")
        if($alvo.Contains($q)){ return $true }
    }
    return $false
}

function Get-EstadoLinhaPlanejamento($item,[int]$ano,[int]$mesFoco,[bool]$CalcularSobreposicao=$true){
    # Setor, periodo e chefia sao informativos: nao criam conflito de aprovacao.
    $fixa=$false
    foreach($r in $script:Records){
        if(-not (Test-RegistroFeriasBloqueadas $r)){ continue }
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $item.setor){ continue }
        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp='SEM PERÍODO' }
        if($rp -ne $item.periodo){ continue }
        if($mesFoco -le 0 -or ((Get-MesesPlanejamentoRegistro $r $ano) -contains $mesFoco)){ $fixa=$true;break }
    }
    $critico=$false
    $meses=if($mesFoco -gt 0){@($mesFoco)}else{@(1..12)}
    foreach($m in $meses){
        if($item.meses[$m].Count -gt 0 -and @($script:PlanejCriticoMeses) -contains $m){ $critico=$true;break }
    }
    $sobreposicao=$false;$semLimite=$false
    foreach($m in $meses){
        if($item.solicitacoes[$m].Count -gt 0 -and (Get-LimiteInstitucionalMes $m) -le 0){$semLimite=$true}
        if($CalcularSobreposicao -and $item.meses[$m].Count -gt 1){
            if((Get-PlanejamentoOverlapInfo $item.setor $item.periodo $ano $m).tem_sobreposicao){$sobreposicao=$true;break}
        }
    }
    return [pscustomobject]@{critico=$critico;alerta=$critico;sobreposicao=$sobreposicao;fixa=$fixa;sem_limite=$semLimite}
}

# V1.0.90: limite institucional com exceções mensais explícitas.
# Um mês marcado sem limite positivo NÃO cria redução implícita.
function Get-LimiteInstitucionalMes([int]$mes){
    $total=[int]$script:Config.total_enfermeiros_planejamento
    if($total -le 0){ return [double]0 }
    $base=[double]$total / 12.0
    if($mes -lt 1 -or $mes -gt 12){ return $base }
    if(@($script:Config.meses_restritos) -notcontains $mes){ return $base }
    $limites=$script:Config.limites_especiais_mensais
    if($null -eq $limites){ return $base }
    $valor=$null
    if($limites -is [System.Collections.IDictionary]){ $valor=$limites[[string]$mes] }
    elseif($null -ne $limites.PSObject.Properties[[string]$mes]){ $valor=$limites.PSObject.Properties[[string]$mes].Value }
    $limite=[double]0
    if($null -ne $valor -and [double]::TryParse(([string]$valor).Replace(',','.'),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$limite) -and $limite -gt 0){ return $limite }
    return $base
}

function Get-ChaveFeriasRegistro($r){
    $mat=([string]$r.matricula).Trim()
    $aqIni=([string]$r.aquisitivo_inicio).Trim()
    $aqFim=([string]$r.aquisitivo_fim).Trim()
    if($mat -or $aqIni -or $aqFim){ return "$mat|$aqIni|$aqFim" }
    return "ID:$([int]$r.id)"
}

# Retorna o peso no mes com base em cada bloco efetivo, nao nas alternativas.
# 30 dias e 20 dias = 1; cada etapa de 15 dias = 0,5.
# V1.1.04: criterio institucional de ocupacao por competencia.
# 30 dias: 1,00 em cada mes com pelo menos 15 dias reais de afastamento.
# 20 dias: 1,00 em um unico mes: se houver >=15 dias, nesse mes;
#          caso contrario, naquele com mais dias (empate: mes de inicio).
# 15 dias: 0,50 em um unico mes, com mais dias (empate: mes de inicio).
# Setor e chefia continuam usando sobreposicao efetiva de datas, sem filtro de 15 dias.
function Get-PesoBlocoInstitucionalMes([datetime]$ini,[datetime]$fim,[int]$ano,[int]$mes){
    if($fim -lt $ini -or $mes -lt 1 -or $mes -gt 12){ return [double]0 }
    $ini=$ini.Date; $fim=$fim.Date
    $dias=($fim-$ini).Days+1
    $inicioMes=[datetime]::new($ano,$mes,1)
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1)
    $iniIntersecao=if($ini -gt $inicioMes){$ini}else{$inicioMes}
    $fimIntersecao=if($fim -lt $fimMes){$fim}else{$fimMes}
    if($fimIntersecao -lt $iniIntersecao){ return [double]0 }
    $diasMes=($fimIntersecao-$iniIntersecao).Days+1
    if($dias -eq 30){
        if($diasMes -ge 15){ return [double]1.0 }
        return [double]0.0
    }
    if($dias -eq 15 -or $dias -eq 20){
        # Um unico mes de contabilizacao, evitando parcela desaparecida ou contada duas vezes.
        $cursor=[datetime]::new($ini.Year,$ini.Month,1)
        $final=[datetime]::new($fim.Year,$fim.Month,1)
        $melhorAno=$ini.Year; $melhorMes=$ini.Month; $melhorDias=-1
        while($cursor -le $final){
            $fimCursor=$cursor.AddMonths(1).AddDays(-1)
            $i=if($ini -gt $cursor){$ini}else{$cursor}
            $f=if($fim -lt $fimCursor){$fim}else{$fimCursor}
            $quant=if($f -ge $i){($f-$i).Days+1}else{0}
            if($quant -gt $melhorDias){ $melhorDias=$quant; $melhorAno=$cursor.Year; $melhorMes=$cursor.Month }
            $cursor=$cursor.AddMonths(1)
        }
        if($ano -eq $melhorAno -and $mes -eq $melhorMes){
            if($dias -eq 15){return [double]0.5}
            return [double]1.0
        }
        return [double]0
    }
    # Periodo legado atipico: conserva a contabilizacao por mes atingido,
    # sem inferir direito radiologico ou excluir registro importado.
    return [double]1.0
}
function Get-PesoOpcaoInstitucionalMes($opcao,[int]$ano,[int]$mes){
    if($null -eq $opcao){return [double]0}
    if($null -eq $script:PerfPesoOpcaoCache){$script:PerfPesoOpcaoCache=@{}}
    # Prefixos de tamanho tornam a chave inequivoca, inclusive com caracteres especiais.
    $cacheKey="$ano|$mes|"
    foreach($v in @([string]$opcao.tipo,[string]$opcao.inicio1,[string]$opcao.fim1,[string]$opcao.inicio2,[string]$opcao.fim2,[string]$opcao.fr_inicio,[string]$opcao.fr_fim)){
        $cacheKey += ([string]$v.Length)+':'+$v+';'
    }
    if($null -ne $opcao.PSObject.Properties['blocos_fixos']){
        $cacheKey += ($opcao.blocos_fixos | ConvertTo-Json -Depth 5 -Compress)
    }
    if($script:PerfPesoOpcaoCache.ContainsKey($cacheKey)){return [double]$script:PerfPesoOpcaoCache[$cacheKey]}
    $comum=[double]0;$radiologica=[double]0
    $blocos=@(Get-OptionBlocksObjeto $opcao)
    if([string]$opcao.tipo -eq '15+15 DIAS'){
        $q=@($blocos | Where-Object { (([datetime]$_.fim)-([datetime]$_.inicio)).Days -eq 14 })
        if($q.Count -ne 2){$blocos=@($blocos | Where-Object { (([datetime]$_.fim)-([datetime]$_.inicio)).Days -eq 19 })}
    }
    foreach($bl in $blocos){
        $valor=[double](Get-PesoBlocoInstitucionalMes ([datetime]$bl.inicio) ([datetime]$bl.fim) $ano $mes)
        if((([datetime]$bl.fim)-([datetime]$bl.inicio)).Days+1 -eq 20){$radiologica+=$valor}
        else{$comum+=$valor}
    }
    # Um profissional = no maximo 1 no mesmo mes, mesmo com modalidades distintas.
    $result=[double]([math]::Min(1.0,[math]::Max($comum,$radiologica)))
    if($script:PerfPesoOpcaoCache.Count -ge 32768){$script:PerfPesoOpcaoCache.Clear()}
    $script:PerfPesoOpcaoCache[$cacheKey]=$result
    return $result
}
function Get-ChaveTipoInstitucional($r,$opcao){
    # Uma chave por servidor e aquisitivo: não duplicar 30 e FR no mesmo mês.
    return [string](Get-ChaveFeriasRegistro $r)
}

# Para registros duplicados da mesma matricula/aquisitivo/classe, usa o maior
# peso mensal; ferias radiologicas de 20 dias sao independentes dos 30 dias.
# V1.0.153: comprometimento REAL (fixas e opcoes efetivamente aprovadas).
# Nao utiliza primeira opcao para qualquer modalidade ainda pendente.
# Usa a mesma chave e peso institucional da projeção, sem duplicar FR e comum.
function Get-OpcaoConfirmadaRegistro($r){
        $op=$null
        if(Test-RegistroFeriasBloqueadas $r){
            $op=Get-OpcaoPlanejamento $r
        }else{
            $nc=Get-NumeroComumConfirmada $r
            $nf=Get-NumeroFRConfirmada $r
            if($nc -le 0 -and $nf -le 0){return $null}
            if($nc -gt 0){$op=Get-OpcaoSomenteComum $r.("opcao$nc")}
            else{$op=New-EmptyOptionObject}
            if($nf -gt 0){
                $opFR=$r.("opcao$nf")
                if($null -ne $opFR){
                    $op.fr_inicio=[string]$opFR.fr_inicio
                    $op.fr_fim=[string]$opFR.fr_fim
                }
            }
        }
    return $op
}

function Get-ContagemInstitucionalAprovadaMes([int]$ano,[int]$mes){
    $porChave=@{}
    foreach($r in $script:Records){
        $op=Get-OpcaoConfirmadaRegistro $r
        if($null -eq $op){continue}
        $peso=[double](Get-PesoOpcaoInstitucionalMes $op $ano $mes)
        if($peso -le 0){continue}
        $chave=[string](Get-ChaveFeriasRegistro $r)
        if(-not $porChave.ContainsKey($chave) -or $peso -gt [double]$porChave[$chave]){
            $porChave[$chave]=$peso
        }
    }
    $total=[double]0
    foreach($v in $porChave.Values){$total += [double]$v}
    return $total
}

function Get-ContagemInstitucionalMes([int]$ano,[int]$mes){
    $porChave=@{}
    foreach($r in $script:Records){
        $op=Get-OpcaoPlanejamento $r
        $peso=[double](Get-PesoOpcaoInstitucionalMes $op $ano $mes)
        if($peso -le 0){ continue }
        $chave=Get-ChaveTipoInstitucional $r $op
        if(-not $porChave.ContainsKey($chave) -or $peso -gt [double]$porChave[$chave]){ $porChave[$chave]=$peso }
    }
    $total=[double]0
    foreach($peso in $porChave.Values){ $total += [double]$peso }
    return $total
}

function Get-NomesInstitucionalMes([int]$ano,[int]$mes){
    $itens=@{}

    foreach($r in $script:Records){
        $opAtual=Get-OpcaoPlanejamento $r
        if((Get-PesoOpcaoInstitucionalMes $opAtual $ano $mes) -gt 0){
            $chave=Get-ChaveTipoInstitucional $r $opAtual

            if(-not $itens.ContainsKey($chave)){
                $aqIni=Date-ToBR ([string]$r.aquisitivo_inicio)
                $aqFim=Date-ToBR ([string]$r.aquisitivo_fim)
                $aq=if($aqIni -and $aqFim){"$aqIni a $aqFim"}else{"Não informado"}
                $op=Get-OpcaoPlanejamento $r
                $n=Get-NumeroOpcaoPlanejamento $r

                $itens[$chave]=[pscustomobject]@{
                    nome=[string]$r.nome
                    matricula=[string]$r.matricula
                    setor=[string]$r.setor
                    periodo=[string]$r.periodo
                    grupo=(Get-GrupoAnaliseSetor ([string]$r.setor))
                    aquisitivo=$aq
                    tipo=if($null -ne $op){[string]$op.tipo}else{""}
                    opcao=$n
                    status=(Get-StatusPlanejamentoRegistro $r)
                    peso=(Get-PesoOpcaoInstitucionalMes $opAtual $ano $mes)
                }
            }
        }
    }

    return @($itens.Values | Sort-Object nome,aquisitivo)
}

# V1.1.04: composicao demonstrativa consistente com a mesma chave/peso da contagem institucional.
# Conta parcelas de 15 dias individualmente e preserva a origem de cada compromisso.
function Get-FaixaInstitucionalDetalhes([int]$ano,[int]$mes,[bool]$incluirNominal=$true){
    $itens=@{}
    foreach($r in $script:Records){
        $op=Get-OpcaoPlanejamento $r
        if($null -eq $op){ continue }
        $peso=[double](Get-PesoOpcaoInstitucionalMes $op $ano $mes)
        if($peso -le 0){ continue }
        $chave=Get-ChaveTipoInstitucional $r $op
        if($itens.ContainsKey($chave) -and [double]$itens[$chave].peso -ge $peso){ continue }
        $q15=0; $q20=0; $q30=0
        $iniMes=[datetime]::new($ano,$mes,1)
        $fimMes=$iniMes.AddMonths(1).AddDays(-1)
        $datas=@()
        foreach($b in @(Get-OptionBlocksObjeto $op)){
            $ini=[datetime]$b.inicio; $fim=[datetime]$b.fim
            $pesoBloco=[double](Get-PesoBlocoInstitucionalMes $ini $fim $ano $mes)
            if($pesoBloco -le 0){ continue }
            $dias=($fim-$ini).Days+1
            if($dias -eq 15){$q15++} elseif($dias -eq 20){$q20++} else {$q30++}
            $inicioEfetivo=if($ini -gt $iniMes){$ini}else{$iniMes}
            $fimEfetivo=if($fim -lt $fimMes){$fim}else{$fimMes}
            $diasNesteMes=($fimEfetivo-$inicioEfetivo).Days+1
            if($incluirNominal){ $datas+=($ini.ToString('dd/MM/yyyy')+' a '+$fim.ToString('dd/MM/yyyy')+' ('+$diasNesteMes+' dia(s) em '+(Get-NomeMesExtenso $mes)+')') }
        }
        $status='1ª opção pendente (projeção)'
        if(Test-RegistroFeriasBloqueadas $r){$status='FÉRIAS FIXAS'}
        elseif([int]$r.opcao_aprovada -ge 1 -and [int]$r.opcao_aprovada -le 3){$status='OPÇÃO APROVADA'}
        $itens[$chave]=[pscustomobject]@{ nome=[string]$r.nome; matricula=[string]$r.matricula; setor=[string]$r.setor;
            peso=$peso; q15=$q15; q20=$q20; q30=$q30; origem=$status; datas=($datas -join ' / ') }
    }
    $n15=0; $n20=0; $n30=0; $total=0.0; $fixas=0; $aprovadas=0; $pendentes=0
    foreach($it in $itens.Values){
        $n15 += $it.q15; $n20 += $it.q20; $n30 += $it.q30; $total += [double]$it.peso
        if($it.origem -eq 'FÉRIAS FIXAS'){$fixas++}
        elseif($it.origem -eq 'OPÇÃO APROVADA'){$aprovadas++}else{$pendentes++}
    }
    $lim=[double](Get-LimiteInstitucionalMes $mes)
    $saldo=[math]::Max(0.0,$lim-$total)
    $util=([math]::Floor(($saldo+0.000001)*2))/2.0
    $sit=if($lim -le 0){'LIMITE NÃO CONFIGURADO'}elseif($total -gt $lim+0.000001){'ACIMA DO LIMITE'}elseif($util -le 0){'SEM VAGA ÚTIL'}elseif($total -ge $lim*0.90){'ATENÇÃO'}else{'DISPONÍVEL'}
    $format={ param($v) ([double]$v).ToString('N2',[Globalization.CultureInfo]::GetCultureInfo('pt-BR')) }
    $linhas=New-Object 'System.Collections.Generic.List[string]'
    [void]$linhas.Add("$(Get-NomeMesExtenso $mes)/$ano  |  $sit")
    [void]$linhas.Add('')
    [void]$linhas.Add("Comprometimento projetado: $(& $format $total)  |  Limite institucional: $(& $format $lim)")
    [void]$linhas.Add("Saldo matemático: $(& $format ($lim-$total))  |  Saldo útil: $(& $format $util)")
    [void]$linhas.Add("Vagas equivalentes: $([math]::Floor($util)) integrais (30/20 dias) OU $([int]($util*2)) parcelas de 15 dias")
    [void]$linhas.Add('')
    [void]$linhas.Add("COMPOSIÇÃO: 30d: $n30   |   20d: $n20   |   15d: $n15")
    [void]$linhas.Add("ORIGEM: $fixas fixa(s)  |  $aprovadas aprovada(s)  |  $pendentes 1ª opção(ões) pendente(s)")
    [void]$linhas.Add('Obs.: a 1ª opção pendente é projeção, NÃO autorização. 30d: mínimo 15 dias/mês; 20d e 15d: mês com mais dias (empate: mês inicial).')
    [void]$linhas.Add('')
    if($incluirNominal){ [void]$linhas.Add('SERVIDORES / PERÍODOS CONSIDERADOS') }
    if($incluirNominal){
        foreach($it in @($itens.Values | Sort-Object origem,nome)){
            [void]$linhas.Add("• $($it.nome) | Matrícula $($it.matricula) | $($it.setor)")
            [void]$linhas.Add("  $($it.origem) | $($it.datas) | Equivalência no mês: $(& $format $it.peso)")
        }
    }
    $curto="$(Get-NomeMesExtenso $mes)/$ano — $sit`r`nComprometido: $(& $format $total)  |  Limite: $(& $format $lim)`r`nSaldo útil: $(& $format $util)  |  30d: $n30  •  20d: $n20  •  15d: $n15`r`nClique para ampliar e conferir os nomes."
    return [pscustomobject]@{ano=$ano;mes=$mes; total=$total; limite=$lim; saldo_util=$util; n15=$n15; n20=$n20; n30=$n30;
        situacao=$sit; tooltip=$curto; detalhamento=($linhas -join [Environment]::NewLine);
        resumo=("$( (Get-NomeMesExtenso $mes).Substring(0,3) ): $(& $format $total)/$(& $format $lim)`n30d:$n30  20d:$n20  15d:$n15") }
}

# Janela de consulta; nunca modifica registros ou aprovações.
function Show-DetalhesFaixaInstitucional([int]$ano,[int]$mes){
    $det=Get-FaixaInstitucionalDetalhes $ano $mes
    $jan=New-Object Windows.Forms.Form
    Apply-AppBranding $jan
    $jan.Text="Capacidade institucional — $(Get-NomeMesExtenso $mes)/$ano"
    $jan.Size=New-Object Drawing.Size(940,650)
    $jan.MinimumSize=New-Object Drawing.Size(620,430)
    $jan.StartPosition='CenterScreen'
    $jan.Font=New-Object Drawing.Font('Segoe UI',10)
    $bar=New-Object Windows.Forms.FlowLayoutPanel
    $bar.Dock='Top';$bar.Height=52
    $bar.Padding=New-Object Windows.Forms.Padding(10,9,0,4)
    $jan.Controls.Add($bar)
    $lbl=New-Object Windows.Forms.Label
    $lbl.Text="$(Get-NomeMesExtenso $mes)/$ano  •  $($det.situacao)"
    $lbl.Size=New-Object Drawing.Size(350,30)
    $lbl.Font=New-Object Drawing.Font('Segoe UI',13,[Drawing.FontStyle]::Bold)
    $bar.Controls.Add($lbl)
    $zoomMais=New-Button 'Aumentar fonte +' 0 0 135 30
    $zoomMenos=New-Button 'Diminuir fonte -' 0 0 135 30
    $bar.Controls.Add($zoomMais);$bar.Controls.Add($zoomMenos)
    $chips=New-Object Windows.Forms.FlowLayoutPanel
    $chips.Dock='Top'; $chips.Height=44
    $chips.Padding=New-Object Windows.Forms.Padding(12,5,0,5)
    $chips.BackColor=[Drawing.Color]::FromArgb(246,249,252)
    $jan.Controls.Add($chips)
    foreach($chip in @(
        @{txt="30 DIAS   $($det.n30)"; bg=[Drawing.Color]::FromArgb(216,240,223); fg=[Drawing.Color]::FromArgb(20,101,53)},
        @{txt="20 DIAS   $($det.n20)"; bg=[Drawing.Color]::FromArgb(216,232,253); fg=[Drawing.Color]::FromArgb(22,79,154)},
        @{txt="15 DIAS   $($det.n15)"; bg=[Drawing.Color]::FromArgb(255,239,189); fg=[Drawing.Color]::FromArgb(111,79,5)}
    )){
        $badge=New-Object Windows.Forms.Label
        $badge.Text=$chip.txt
        $badge.Size=New-Object Drawing.Size(190,28)
        $badge.TextAlign=[Drawing.ContentAlignment]::MiddleCenter
        $badge.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
        $badge.BackColor=$chip.bg; $badge.ForeColor=$chip.fg
        $badge.Margin=New-Object Windows.Forms.Padding(0,0,10,0)
        $chips.Controls.Add($badge)
    }
    $txt=New-Object Windows.Forms.TextBox
    $txt.Multiline=$true;$txt.ReadOnly=$true;$txt.WordWrap=$true;$txt.ScrollBars='Both'
    $txt.Dock='Fill';$txt.Font=New-Object Drawing.Font('Consolas',12)
    $txt.Text=$det.detalhamento
    $jan.Controls.Add($txt);$txt.SendToBack();$chips.BringToFront();$bar.BringToFront()
    $zoomMais.add_Click({ $tam=[math]::Min(22,$txt.Font.Size+1);$txt.Font=New-Object Drawing.Font('Consolas',$tam) })
    $zoomMenos.add_Click({ $tam=[math]::Max(9,$txt.Font.Size-1);$txt.Font=New-Object Drawing.Font('Consolas',$tam) })
    [void]$jan.ShowDialog()
}

function Get-PlanejamentoOverlapInfo([string]$setor,[string]$periodo,[int]$ano,[int]$mes){
    $inicioMes=(Get-Date -Year $ano -Month $mes -Day 1).Date
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1).Date

    $intervalos=@()
    $temFixa=$false
    foreach($r in $script:Records){
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }
        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        $registroTocaMes=$false
        foreach($b in (Get-OptionBlocksPlanejamento $r)){
            $bi=[datetime]$b.inicio
            $bf=[datetime]$b.fim
            if($bi -le $fimMes -and $bf -ge $inicioMes){
                $registroTocaMes=$true
                $intervalos += [pscustomobject]@{
                    matricula=[string]$r.matricula
                    nome=[string]$r.nome
                    inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                    fim=if($bf -gt $fimMes){$fimMes}else{$bf}
                }
            }
        }
        if($registroTocaMes -and (Test-RegistroFeriasBloqueadas $r)){ $temFixa=$true }
    }

    $matMes=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($iv in $intervalos){ [void]$matMes.Add([string]$iv.matricula) }

    $pico=0
    $diasPico=@()
    $diasSobrepostos=@()

    for($d=$inicioMes; $d -le $fimMes; $d=$d.AddDays(1)){
        $ativos=New-Object 'System.Collections.Generic.HashSet[string]'
        foreach($iv in $intervalos){
            if($iv.inicio -le $d -and $iv.fim -ge $d){
                [void]$ativos.Add([string]$iv.matricula)
            }
        }
        $q=$ativos.Count
        if($q -gt 1){ $diasSobrepostos += $d.ToString("dd/MM") }
        if($q -gt $pico){
            $pico=$q
            $diasPico=@($d.ToString("dd/MM"))
        } elseif($q -eq $pico -and $q -gt 0){
            $diasPico += $d.ToString("dd/MM")
        }
    }

    return [pscustomobject]@{
        qtd_mes=$matMes.Count
        pico=$pico
        tem_sobreposicao=($pico -gt 1)
        tem_fixa=$temFixa
        dias_sobrepostos=@($diasSobrepostos)
        dias_pico=@($diasPico)
    }
}

function Get-PlanejamentoOverlapInfoCached([string]$setor,[string]$periodo,[int]$ano,[int]$mes){
    if($null -eq $script:PlanejOverlapCache){ $script:PlanejOverlapCache=@{} }
    $key="$setor|||$periodo|||$ano|||$mes"
    if(-not $script:PlanejOverlapCache.ContainsKey($key)){
        $script:PlanejOverlapCache[$key]=Get-PlanejamentoOverlapInfo $setor $periodo $ano $mes
    }
    return $script:PlanejOverlapCache[$key]
}

function Get-LimiteGrupoChefiaPeriodo([string]$grupo,[string]$periodo){
    $grupo=([string]$grupo).Trim()
    $periodo=([string]$periodo).Trim()
    if(-not $grupo){ return 0 }
    foreach($x in @($script:Config.limites_grupo_chefia_periodo)){
        if(([string]$x.grupo).Trim() -eq $grupo -and ([string]$x.periodo).Trim() -eq $periodo){
            return [int]$x.limite
        }
    }
    return 0
}

function Set-LimiteGrupoChefiaPeriodo([string]$grupo,[string]$periodo,[int]$limite){
    $grupo=([string]$grupo).Trim()
    $periodo=([string]$periodo).Trim()
    if(-not $grupo -or -not $periodo){ return }

    $nova=@()
    $achou=$false
    foreach($x in @($script:Config.limites_grupo_chefia_periodo)){
        if(([string]$x.grupo).Trim() -eq $grupo -and ([string]$x.periodo).Trim() -eq $periodo){
            $achou=$true
            if($limite -gt 0){ $nova += [pscustomobject]@{grupo=$grupo;periodo=$periodo;limite=$limite} }
        } else {
            $nova += $x
        }
    }
    if(-not $achou -and $limite -gt 0){ $nova += [pscustomobject]@{grupo=$grupo;periodo=$periodo;limite=$limite} }
    $script:Config.limites_grupo_chefia_periodo=@($nova)
}

function Get-GrupoChefiaOverlapInfo([string]$grupo,[string]$periodo,[int]$ano,[int]$mes){
    $grupo=([string]$grupo).Trim()
    if(-not $grupo){
        return [pscustomobject]@{qtd_mes=0;pico=0;tem_sobreposicao=$false;dias_sobrepostos=@();dias_pico=@()}
    }

    $inicioMes=(Get-Date -Year $ano -Month $mes -Day 1).Date
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1).Date
    $intervalos=@()
    $matMes=New-Object 'System.Collections.Generic.HashSet[string]'

    foreach($r in $script:Records){
        if((Get-GrupoChefiaEfetivaRegistro $r) -ne $grupo){ continue }
        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        foreach($b in (Get-OptionBlocksPlanejamento $r)){
            $bi=([datetime]$b.inicio).Date
            $bf=([datetime]$b.fim).Date
            if($bi -le $fimMes -and $bf -ge $inicioMes){
                [void]$matMes.Add([string]$r.matricula)
                $intervalos += [pscustomobject]@{
                    matricula=[string]$r.matricula
                    inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                    fim=if($bf -gt $fimMes){$fimMes}else{$bf}
                }
            }
        }
    }

    $pico=0
    $diasPico=@()
    $diasSobrepostos=@()
    for($d=$inicioMes; $d -le $fimMes; $d=$d.AddDays(1)){
        $ativos=New-Object 'System.Collections.Generic.HashSet[string]'
        foreach($iv in $intervalos){
            if($iv.inicio -le $d -and $iv.fim -ge $d){ [void]$ativos.Add([string]$iv.matricula) }
        }
        if($ativos.Count -gt 1){ $diasSobrepostos += $d.ToString("dd/MM") }
        if($ativos.Count -gt $pico){
            $pico=$ativos.Count
            $diasPico=@($d.ToString("dd/MM"))
        } elseif($ativos.Count -eq $pico -and $pico -gt 0){
            $diasPico += $d.ToString("dd/MM")
        }
    }

    return [pscustomobject]@{
        qtd_mes=$matMes.Count
        pico=$pico
        tem_sobreposicao=($pico -gt 1)
        dias_sobrepostos=@($diasSobrepostos)
        dias_pico=@($diasPico)
    }
}

function Get-GrupoChefiaOverlapInfoCached([string]$grupo,[string]$periodo,[int]$ano,[int]$mes){
    if($null -eq $script:PlanejChefiaOverlapCache){ $script:PlanejChefiaOverlapCache=@{} }
    $key="$grupo|||$periodo|||$ano|||$mes"
    if(-not $script:PlanejChefiaOverlapCache.ContainsKey($key)){
        $script:PlanejChefiaOverlapCache[$key]=Get-GrupoChefiaOverlapInfo $grupo $periodo $ano $mes
    }
    return $script:PlanejChefiaOverlapCache[$key]
}


function Get-OpcaoSimulacaoRegistro($registro,$opcao){
    if($null -eq $registro -or $null -eq $opcao){return $opcao}
    if([string]$opcao.tipo -eq 'FÉRIAS FIXAS'){return $opcao}
    # Comum e FR têm decisões independentes. Simular uma não desfaz a outra.
    $atual=Get-OpcaoPlanejamento $registro
    $comum=Get-OpcaoSomenteComum $opcao
    $frI=[string]$opcao.fr_inicio;$frF=[string]$opcao.fr_fim
    $somenteFR=([string]::IsNullOrWhiteSpace([string]$comum.tipo) -and ($frI -or $frF))
    if($somenteFR){
        $comum=Get-OpcaoSomenteComum $atual
    }else{
        $nf=Get-NumeroFRConfirmada $registro
        if($nf -gt 0){
            $fr=$registro.("opcao$nf");$frI=[string]$fr.fr_inicio;$frF=[string]$fr.fr_fim
        }elseif(-not $frI -and -not $frF){
            $frI=[string]$atual.fr_inicio;$frF=[string]$atual.fr_fim
        }
    }
    $comum.fr_inicio=$frI;$comum.fr_fim=$frF
    return $comum
}

function Get-SimulacaoSetorPeriodoMes($registro,$opcao,[int]$ano,[int]$mes){
    $opcao=Get-OpcaoSimulacaoRegistro $registro $opcao
    $setor=([string]$registro.setor).Trim()
    $periodo=([string]$registro.periodo).Trim()
    if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

    $inicioMes=(Get-Date -Year $ano -Month $mes -Day 1).Date
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1).Date
    $intervalos=@()

    foreach($r in $script:Records){
        if([int]$r.id -eq [int]$registro.id){ continue }
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }

        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        foreach($bl in (Get-OptionBlocksPlanejamento $r)){
            $bi=([datetime]$bl.inicio).Date
            $bf=([datetime]$bl.fim).Date
            if($bi -le $fimMes -and $bf -ge $inicioMes){
                $intervalos += [pscustomobject]@{
                    matricula=[string]$r.matricula
                    inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                    fim=if($bf -gt $fimMes){$fimMes}else{$bf}
                }
            }
        }
    }

    foreach($bl in (Get-OptionBlocksObjeto $opcao)){
        $bi=[datetime]$bl.inicio
        $bf=[datetime]$bl.fim
        if($bi -le $fimMes -and $bf -ge $inicioMes){
            $intervalos += [pscustomobject]@{
                matricula=[string]$registro.matricula
                inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                fim=if($bf -gt $fimMes){$fimMes}else{$bf}
            }
        }
    }

    $matMes=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($iv in $intervalos){ [void]$matMes.Add([string]$iv.matricula) }

    $pico=0
    $diasPico=@()
    for($d=$inicioMes; $d -le $fimMes; $d=$d.AddDays(1)){
        $ativos=New-Object 'System.Collections.Generic.HashSet[string]'
        foreach($iv in $intervalos){
            if($iv.inicio -le $d -and $iv.fim -ge $d){
                [void]$ativos.Add([string]$iv.matricula)
            }
        }
        if($ativos.Count -gt $pico){
            $pico=$ativos.Count
            $diasPico=@($d.ToString("dd/MM"))
        } elseif($ativos.Count -eq $pico -and $pico -gt 0){
            $diasPico += $d.ToString("dd/MM")
        }
    }

    return [pscustomobject]@{
        qtd_mes=$matMes.Count
        pico=$pico
        dias_pico=@($diasPico)
    }
}

function Get-SimulacaoGrupoChefiaPeriodoMes($registro,$opcao,[int]$ano,[int]$mes){
    $opcao=Get-OpcaoSimulacaoRegistro $registro $opcao
    $grupo=Get-GrupoChefiaEfetivaRegistro $registro
    if([string]::IsNullOrWhiteSpace($grupo)){
        return [pscustomobject]@{qtd_mes=0;pico=0;dias_pico=@()}
    }

    $periodo=([string]$registro.periodo).Trim()
    if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

    $inicioMes=(Get-Date -Year $ano -Month $mes -Day 1).Date
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1).Date
    $intervalos=@()

    foreach($r in $script:Records){
        if([int]$r.id -eq [int]$registro.id){ continue }
        if((Get-GrupoChefiaEfetivaRegistro $r) -ne $grupo){ continue }

        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        foreach($bl in (Get-OptionBlocksPlanejamento $r)){
            $bi=([datetime]$bl.inicio).Date
            $bf=([datetime]$bl.fim).Date
            if($bi -le $fimMes -and $bf -ge $inicioMes){
                $intervalos += [pscustomobject]@{
                    matricula=[string]$r.matricula
                    inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                    fim=if($bf -gt $fimMes){$fimMes}else{$bf}
                }
            }
        }
    }

    foreach($bl in (Get-OptionBlocksObjeto $opcao)){
        $bi=([datetime]$bl.inicio).Date
        $bf=([datetime]$bl.fim).Date
        if($bi -le $fimMes -and $bf -ge $inicioMes){
            $intervalos += [pscustomobject]@{
                matricula=[string]$registro.matricula
                inicio=if($bi -lt $inicioMes){$inicioMes}else{$bi}
                fim=if($bf -gt $fimMes){$fimMes}else{$bf}
            }
        }
    }

    $matMes=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($iv in $intervalos){ [void]$matMes.Add([string]$iv.matricula) }

    $pico=0
    $diasPico=@()
    for($d=$inicioMes; $d -le $fimMes; $d=$d.AddDays(1)){
        $ativos=New-Object 'System.Collections.Generic.HashSet[string]'
        foreach($iv in $intervalos){
            if($iv.inicio -le $d -and $iv.fim -ge $d){ [void]$ativos.Add([string]$iv.matricula) }
        }
        if($ativos.Count -gt $pico){
            $pico=$ativos.Count
            $diasPico=@($d.ToString("dd/MM"))
        } elseif($ativos.Count -eq $pico -and $pico -gt 0){
            $diasPico += $d.ToString("dd/MM")
        }
    }

    return [pscustomobject]@{
        qtd_mes=$matMes.Count
        pico=$pico
        dias_pico=@($diasPico)
    }
}

function Get-ContagemInstitucionalMesSimulada($registro,$opcao,[int]$ano,[int]$mes){
    $opcao=Get-OpcaoSimulacaoRegistro $registro $opcao
    $porChave=@{}
    foreach($r in $script:Records){
        if([int]$r.id -eq [int]$registro.id){ continue }
        $op=Get-OpcaoPlanejamento $r
        $peso=[double](Get-PesoOpcaoInstitucionalMes $op $ano $mes)
        if($peso -le 0){ continue }
        $chave=Get-ChaveTipoInstitucional $r $op
        if(-not $porChave.ContainsKey($chave) -or $peso -gt [double]$porChave[$chave]){ $porChave[$chave]=$peso }
    }
    $pesoCandidato=[double](Get-PesoOpcaoInstitucionalMes $opcao $ano $mes)
    if($pesoCandidato -gt 0){
        $chave=Get-ChaveTipoInstitucional $registro $opcao
        if(-not $porChave.ContainsKey($chave) -or $pesoCandidato -gt [double]$porChave[$chave]){ $porChave[$chave]=$pesoCandidato }
    }
    $total=[double]0
    foreach($peso in $porChave.Values){ $total += [double]$peso }
    return $total
}

function Get-CompetenciasOpcao($opcao){
    $resultado=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($bl in (Get-OptionBlocksObjeto $opcao)){
        $cursor=[datetime]::new($bl.inicio.Year,$bl.inicio.Month,1)
        $ultimo=[datetime]::new($bl.fim.Year,$bl.fim.Month,1)
        while($cursor -le $ultimo){
            [void]$resultado.Add($cursor.ToString("yyyy-MM"))
            $cursor=$cursor.AddMonths(1)
        }
    }
    return @($resultado | Sort-Object)
}

function Get-AvaliacaoOpcaoRegistro($registro,[int]$numeroOpcao,$OpcaoSimulada=$null){
    $opcao=if($null -ne $OpcaoSimulada){$OpcaoSimulada}else{$registro."opcao$numeroOpcao"}
    $rotulo="${numeroOpcao}ª opção"

    if($null -eq $opcao -or [string]::IsNullOrWhiteSpace([string]$opcao.tipo)){
        return [pscustomobject]@{
            opcao=$numeroOpcao
            valida=$false
            nivel="NÃO INFORMADA"
            score=999999
            motivo="$rotulo não informada."
            historico="Histórico ainda não importado."
        }
    }

    $erro=Validate-Option $opcao $rotulo ([string]$registro.aquisitivo_fim)
    if($erro){
        return [pscustomobject]@{
            opcao=$numeroOpcao
            valida=$false
            nivel="INVÁLIDA"
            score=999999
            motivo=$erro
            historico="Histórico ainda não importado."
        }
    }

    $setor=([string]$registro.setor).Trim()
    $periodo=([string]$registro.periodo).Trim()
    if([string]::IsNullOrWhiteSpace($periodo)){ $periodo="SEM PERÍODO" }

    $limiteLocal=Get-LimiteSetorPeriodo $setor $periodo
    $grupoChefia=Get-GrupoChefiaEfetivaRegistro $registro
    $limiteChefia=Get-LimiteGrupoChefiaPeriodo $grupoChefia $periodo

    $criticos=0
    $alertasLocais=0
    $alertasInstitucionais=0
    $semLimiteLocal=$false
    $semLimiteChefia=$false
    $detalhes=New-Object 'System.Collections.Generic.List[string]'
    $historicoDetalhes=New-Object 'System.Collections.Generic.List[string]'
    $historicoItens=@()
    $historicoOcorrencias=0
    $historicoCobertura=0

    foreach($comp in (Get-CompetenciasOpcao $opcao)){
        $partes=$comp.Split("-")
        $ano=[int]$partes[0]
        $mes=[int]$partes[1]
        $mesRotulo="$(Get-NomeMesExtenso $mes)/$ano"

        # Limites locais e de chefia usam o pico simultaneo; o total mensal gera alerta.
        if($limiteLocal -gt 0){
            $simLocal=Get-SimulacaoSetorPeriodoMes $registro $opcao $ano $mes
            if([int]$simLocal.pico -gt $limiteLocal){
                $criticos++; [void]$detalhes.Add("${mesRotulo}: CONFLITO CRITICO no setor: pico $($simLocal.pico), limite $limiteLocal.")
            } elseif([int]$simLocal.qtd_mes -gt $limiteLocal){
                $alertasLocais++; [void]$detalhes.Add("${mesRotulo}: total mensal do setor acima do limite; confira a distribuicao diaria.")
            }
        } else { $semLimiteLocal=$true }
        if(-not [string]::IsNullOrWhiteSpace([string]$grupoChefia)){
            if($limiteChefia -gt 0){
                $simChefia=Get-SimulacaoGrupoChefiaPeriodoMes $registro $opcao $ano $mes
                if([int]$simChefia.pico -gt $limiteChefia){
                    $criticos++; [void]$detalhes.Add("${mesRotulo}: CONFLITO CRITICO na chefia: pico $($simChefia.pico), limite $limiteChefia.")
                } elseif([int]$simChefia.qtd_mes -gt $limiteChefia){
                    $alertasLocais++; [void]$detalhes.Add("${mesRotulo}: total mensal da chefia acima do limite; confira a distribuicao diaria.")
                }
            } else { $semLimiteChefia=$true }
        }

        # Limite institucional e criterio separado da simultaneidade local.
        $limInst=Get-LimiteInstitucionalMes $mes
        if($limInst -gt 0){
            $qInst=Get-ContagemInstitucionalMesSimulada $registro $opcao $ano $mes
            if($qInst -gt $limInst){
                $alertasInstitucionais++
                $limTxt=Format-NumeroBR $limInst
                $aprox=[math]::Max(1,[math]::Round($limInst,0,[System.MidpointRounding]::AwayFromZero))
                $totalGeral=[int]$script:Config.total_enfermeiros_planejamento
                $baseInst=if($totalGeral -gt 0){[double]$totalGeral/12.0}else{0}
                $baseTxt=Format-NumeroBR $baseInst
                [void]$detalhes.Add("${mesRotulo}: ALERTA INSTITUCIONAL — limite $limTxt férias equivalentes; com esta opção, total $qInst.")
            }
        }

        # Histórico é apenas desempate: nunca transforma uma opção operacionalmente adequada em crítica.
        $h=Get-HistoricoDesempateInfo $registro $mes $ano
        $historicoItens += [pscustomobject]@{
            competencia=$comp; mes=$mes; ano=$ano; mes_rotulo=$mesRotulo
            disponivel=[bool]$h.disponivel; ocorrencias=[int]$h.ocorrencias; cobertura=[int]$h.cobertura
            prioridade=[string]$h.prioridade; detalhe=[string]$h.detalhe; anos=@($h.anos)
        }
        if([bool]$h.disponivel){
            $historicoOcorrencias += [int]$h.ocorrencias
            $historicoCobertura += [int]$h.cobertura
            [void]$historicoDetalhes.Add("${mesRotulo}: $($h.detalhe)")
        }
    }

    $historico=if($historicoDetalhes.Count -gt 0){
        "Histórico de desempate: "+($historicoDetalhes -join "; ")
    } elseif([bool]$script:Config.historico_3_anos_importado){
        "Histórico de desempate: sem cobertura suficiente para este servidor/período."
    } else {
        "Histórico de desempate: ainda não importado."
    }

    # Ausência de limite é penalizada uma única vez por dimensão, nunca por mês tocado.
    $penalSemLimite=0
    if($semLimiteLocal){ $penalSemLimite++ }
    if($semLimiteChefia){ $penalSemLimite++ }

    # Ordem: conflito real > alerta local/chefia > alerta institucional > ausência de limite > histórico > preferência.
    # O histórico tem peso apenas de desempate, abaixo de todas as regras operacionais.
    $historicoPenalty=[math]::Min(90,[math]::Max(0,([int]$historicoOcorrencias*10)))
    # score mantido para exibicao; a ordenacao abaixo e lexicografica, sem pesos que se sobreponham.
    $score=($criticos*1000000)+($alertasLocais*100000)+($alertasInstitucionais*1000)+($penalSemLimite*100)+$historicoPenalty+($numeroOpcao-1)

    if($criticos -gt 0){
        $nivel="CRÍTICA"
    } elseif($alertasLocais -gt 0 -or $alertasInstitucionais -gt 0 -or $penalSemLimite -gt 0){
        $nivel="ATENÇÃO"
    } else {
        $nivel="ADEQUADA"
    }

    $motivo=if($detalhes.Count -gt 0){ $detalhes -join "; " }else{"Sem conflito operacional identificado nas regras atuais."}

    return [pscustomobject]@{
        opcao=$numeroOpcao
        valida=$true
        nivel=$nivel
        score=$score
        penal_sem_limite=$penalSemLimite
        historico_ocorrencias=$historicoOcorrencias
        motivo=$motivo
        historico=$historico
        historico_itens=@($historicoItens)
        criticos=$criticos
        alertas_locais=$alertasLocais
        alertas_institucionais=$alertasInstitucionais
        sem_limite_local=$semLimiteLocal
        sem_limite_chefia=$semLimiteChefia
    }
}

function Get-SugestaoOpcaoRegistro($registro){
    if($null -eq $registro){ return $null }

    if(Test-RegistroFeriasBloqueadas $registro){
        $n=Get-NumeroOpcaoPlanejamento $registro
        $descricao=if(Test-RegistroFixoImportado $registro){"Férias fixa importada: $(Get-PeriodoFixoResumo $registro)"}else{"Férias já definidas na ${n}ª opção"}
        return [pscustomobject]@{
            opcao=if(Test-RegistroFixoImportado $registro){0}else{$n}
            nivel="FIXA"
            motivo="$descricao. O sistema não sugere mudança; este período ocupa capacidade e interfere nas demais escolhas."
            historico="Não se aplica à alteração deste compromisso fixo."
        }
    }

    $avaliacoes=@()
    foreach($n in 1..3){
        $a=Get-AvaliacaoOpcaoRegistro $registro $n
        if($a.valida){ $avaliacoes += $a }
    }

    if($avaliacoes.Count -eq 0){
        return [pscustomobject]@{
            opcao=0
            nivel="SEM OPÇÃO"
            motivo="Nenhuma das três opções possui dados válidos para análise."
            historico="Histórico ainda não importado."
        }
    }

    # Historico desempata a viabilidade operacional antes da preferencia.
    $coberturas=@($avaliacoes | ForEach-Object {
        (@($_.historico_itens | ForEach-Object { $_.anos } | Where-Object {$_.tem_servidor} | ForEach-Object {[int]$_.ano} | Sort-Object -Unique) -join ',')
    } | Sort-Object -Unique)
    $comparavel=($coberturas.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace([string]$coberturas[0]))
    foreach($a in $avaliacoes){
        $a|Add-Member NoteProperty historico_comparavel $comparavel -Force
        if(-not $comparavel){$a.historico+=' Cobertura histórica insuficiente ou diferente entre opções; desempate histórico não aplicado.'}
    }
    $ordem=@('criticos','alertas_locais','alertas_institucionais','penal_sem_limite')
    if($comparavel){$ordem+='historico_ocorrencias'}
    $ordem+='opcao'
    $melhor=$avaliacoes | Sort-Object -Property $ordem | Select-Object -First 1
    return $melhor
}


function Refresh-LimiteInstitucionalResumo($Preparado=$null) {
    if($null -eq $Preparado){
        $script:InstitutionalResumoCacheKey=''
        Request-PlanejamentoRefresh
        return
    }
    if($null -eq $script:gridLimiteInstitucional){ return }
    if($null -eq $script:cmbPlanejAno.SelectedItem){ return }

    $ano=[int]$script:cmbPlanejAno.SelectedItem
    $cacheKeyInst="$ano|$(@($script:Records).Count)|$([int]$script:Config.total_enfermeiros_planejamento)|$([string]$script:LoadedDbHash)"
    if([string]$script:InstitutionalResumoCacheKey -eq $cacheKeyInst){ return }
    if($script:gridLimiteInstitucional.Rows.Count -eq 0){
        [void]$script:gridLimiteInstitucional.Rows.Add()
    }
    $row=$script:gridLimiteInstitucional.Rows[0]
    $mesNomes=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")

    for($m=1;$m -le 12;$m++){
        $qtd=$Preparado.Meses[$m].qtd
        $real=$Preparado.Meses[$m].real
        $pendenteProjecao=[math]::Max(0.0,($qtd-$real))
        $lim=$Preparado.Meses[$m].limite
        $saldoReal=$lim-$real
        $restrito=(@($script:Config.meses_restritos) -contains $m)
        $pct=[double]$script:Config.percentual_meses_restritos

        if($lim -gt 0){
            $txtLim=Format-NumeroBR $lim
            $detMes=$Preparado.Meses[$m].detalhes
            # Em vez de apresentar apenas a base de decisao, distinguir efetivo/projetado.
            $row.Cells["li$m"].Value="REAL: $(Format-NumeroBR $real) / $(Format-NumeroBR $lim)`r`nPEND: $(Format-NumeroBR $pendenteProjecao)  PROJ: $(Format-NumeroBR $qtd)`r`nSALDO: $(Format-NumeroBR $saldoReal)"
            $row.Cells["li$m"].Style.WrapMode=[Windows.Forms.DataGridViewTriState]::True
            $row.Cells["li$m"].Style.ForeColor=[Drawing.Color]::Black
            $row.Cells["li$m"].Style.Font=New-Object Drawing.Font("Segoe UI",8)
            if($qtd -gt $lim){
                $row.Cells["li$m"].Style.BackColor=[Drawing.Color]::MistyRose
            } elseif($qtd -ge ($lim * 0.90) -and $qtd -gt 0){
                $row.Cells["li$m"].Style.BackColor=[Drawing.Color]::FromArgb(255,244,204)
            } elseif($qtd -gt 0){
                $row.Cells["li$m"].Style.BackColor=[Drawing.Color]::FromArgb(226,239,218)
            } else {
                $row.Cells["li$m"].Style.BackColor=[Drawing.Color]::White
            }

            $row.Cells["li$m"].ToolTipText="COMPROMETIDO (fixas + aprovadas): $(Format-NumeroBR $real) equivalentes.`r`nPENDENTE NA PROJECAO (1a opcao): $(Format-NumeroBR $pendenteProjecao).`r`nPROJECAO TOTAL: $(Format-NumeroBR $qtd).`r`nSALDO REAL: $(Format-NumeroBR $saldoReal).`r`n`r`n"+[string]$detMes.tooltip
        } else {
            $row.Cells["li$m"].Value="REAL: $(Format-NumeroBR $real) / SEM LIMITE`r`nPEND: $(Format-NumeroBR $pendenteProjecao)  PROJ: $(Format-NumeroBR $qtd)"
            $row.Cells["li$m"].Style.BackColor=[Drawing.Color]::Gainsboro
            $row.Cells["li$m"].ToolTipText="Informe o total de enfermeiros em Configurações para calcular o limite mensal."
        }
    }

    $total=[int]$script:Config.total_enfermeiros_planejamento
    if($total -gt 0){
        $base=[double]$total/12.0
        $script:lblLimiteInstitucional.Text="Limite: $total enfermeiros ÷ 12 = $(Format-NumeroBR $base) equivalentes/mês | 30d=1, 20d=1, 15d=0,50. REAL = confirmado; PEND = projecao pendente; PROJ = base total. Passe o mouse."
    } else {
        $script:lblLimiteInstitucional.Text="Limite institucional não configurado. Informe em Configurações o TOTAL GERAL de enfermeiros dos três grupos."
    }
    $script:InstitutionalResumoCacheKey=$cacheKeyInst
}

function Get-PlanejamentoCellTooltip([string]$setor,[string]$periodo,[int]$ano,[int]$mes,[int]$limite,[int]$qtd){
    if($null -eq $script:PlanejTooltipCache){ $script:PlanejTooltipCache=@{} }
    $cacheKey="$setor|$periodo|$ano|$mes|$limite|$qtd"
    if($script:PlanejTooltipCache.ContainsKey($cacheKey)){ return [string]$script:PlanejTooltipCache[$cacheKey] }

    $porMatricula=@{}

    $inicioMes=(Get-Date -Year $ano -Month $mes -Day 1).Date
    $fimMes=$inicioMes.AddMonths(1).AddDays(-1).Date

    foreach($r in $script:Records){
        if((Get-SetorPlanejamentoChave ([string]$r.setor)) -ne $setor){ continue }

        $rp=([string]$r.periodo).Trim()
        if([string]::IsNullOrWhiteSpace($rp)){ $rp="SEM PERÍODO" }
        if($rp -ne $periodo){ continue }

        $faixas=@()
        foreach($b in (Get-OptionBlocksPlanejamento $r)){
            $bi=[datetime]$b.inicio
            $bf=[datetime]$b.fim
            if($bi -le $fimMes -and $bf -ge $inicioMes){
                $faixas += "$(Date-ToBR ($bi.ToString('yyyy-MM-dd'))) a $(Date-ToBR ($bf.ToString('yyyy-MM-dd')))"
            }
        }

        if($faixas.Count -gt 0){
            $mat=[string]$r.matricula
            $aqIni=Date-ToBR ([string]$r.aquisitivo_inicio)
            $aqFim=Date-ToBR ([string]$r.aquisitivo_fim)
            $aq=if($aqIni -and $aqFim){"$aqIni a $aqFim"}else{"Não informado"}
            $base=Get-DescricaoBasePlanejamento $r

            if(-not $porMatricula.ContainsKey($mat)){
                $porMatricula[$mat]=[pscustomobject]@{
                    nome=[string]$r.nome
                    matricula=$mat
                    chefia=(Get-GrupoChefiaEfetivaRegistro $r)
                    origem_chefia=(Get-OrigemGrupoChefiaRegistro $r)
                    aquisitivos=New-Object 'System.Collections.Generic.List[string]'
                    faixas=New-Object 'System.Collections.Generic.List[string]'
                    bases=New-Object 'System.Collections.Generic.List[string]'
                }
            }

            if(-not $porMatricula[$mat].aquisitivos.Contains($aq)){
                [void]$porMatricula[$mat].aquisitivos.Add($aq)
            }
            if(-not $porMatricula[$mat].bases.Contains($base)){
                [void]$porMatricula[$mat].bases.Add($base)
            }

            foreach($f in $faixas){
                if(-not $porMatricula[$mat].faixas.Contains($f)){
                    [void]$porMatricula[$mat].faixas.Add($f)
                }
            }
        }
    }

    $overlap=Get-PlanejamentoOverlapInfoCached $setor $periodo $ano $mes

    $linhas=New-Object 'System.Collections.Generic.List[string]'
    $grupo=Get-GrupoAnaliseSetor $setor
    $grupoChefia=Get-GrupoChefiaSetor $setor
    [void]$linhas.Add("$qtd servidor(es) no mês | $setor | $periodo")
    [void]$linhas.Add("Grupo de análise: $grupo")
    if($grupoChefia){ [void]$linhas.Add("Chefia padrão do setor: $grupoChefia") }
    [void]$linhas.Add("Base: opções aceitas/bloqueadas + 1ª opção das pendentes")
    [void]$linhas.Add("")

    foreach($x in ($porMatricula.Values | Sort-Object nome)){
        $datas=($x.faixas -join " / ")
        $aqs=($x.aquisitivos -join " / ")
        $bases=($x.bases -join " / ")
        [void]$linhas.Add("• $($x.nome) [$($x.matricula)]")
        [void]$linhas.Add("  Situação: $bases")
        if([string]$x.chefia){ [void]$linhas.Add("  Chefia efetiva: $([string]$x.chefia) ($([string]$x.origem_chefia))") }
        [void]$linhas.Add("  Período aquisitivo: $aqs")
        [void]$linhas.Add("  Férias consideradas: $datas")
    }

    [void]$linhas.Add("")
    [void]$linhas.Add("Pico simultâneo real: $($overlap.pico) servidor(es)")
    if($overlap.tem_sobreposicao){
        $dias=($overlap.dias_sobrepostos | Select-Object -First 12) -join ", "
        if($overlap.dias_sobrepostos.Count -gt 12){ $dias += "..." }
        [void]$linhas.Add("HÁ SOBREPOSIÇÃO REAL DE DATAS: $dias")
    } elseif($qtd -gt 1){
        [void]$linhas.Add("Há mais de uma férias no mês, mas as datas NÃO se sobrepõem.")
    }

    [void]$linhas.Add("")
    if($limite -gt 0){
        if($overlap.pico -gt $limite){
            $situacao="GRAVE: simultaneidade acima do limite"
        } elseif($qtd -gt $limite){
            $situacao="ATENÇÃO: quantidade mensal acima do limite, sem exceder simultaneidade"
        } elseif($qtd -eq $limite -and $qtd -gt 0){
            $situacao="NO LIMITE"
        } else {
            $situacao="ABAIXO DO LIMITE"
        }
        [void]$linhas.Add("Limite Setor/Período: $limite | $situacao")
    } else {
        [void]$linhas.Add("Limite Setor/Período: não configurado")
    }

    if($grupoChefia){
        $limChefia=Get-LimiteGrupoChefiaPeriodo $grupoChefia $periodo
        $infoChefia=Get-GrupoChefiaOverlapInfoCached $grupoChefia $periodo $ano $mes
        [void]$linhas.Add("")
        [void]$linhas.Add("Setores vinculados pela mesma chefia:")
        [void]$linhas.Add("Grupo: $grupoChefia | Total no mês/período: $($infoChefia.qtd_mes) | Pico simultâneo: $($infoChefia.pico)")
        if($limChefia -gt 0){
            if($infoChefia.pico -gt $limChefia){
                $sitChefia="GRAVE: simultaneidade do grupo acima do limite"
            } elseif($infoChefia.qtd_mes -gt $limChefia){
                $sitChefia="ATENÇÃO: total mensal do grupo acima do limite, sem exceder o pico"
            } elseif($infoChefia.qtd_mes -eq $limChefia -and $infoChefia.qtd_mes -gt 0){
                $sitChefia="NO LIMITE"
            } else {
                $sitChefia="ABAIXO DO LIMITE"
            }
            [void]$linhas.Add("Limite Grupo de Chefia/Período: $limChefia | $sitChefia")
        } else {
            [void]$linhas.Add("Limite Grupo de Chefia/Período: não configurado")
        }
    }

    $textoTooltip=($linhas -join "`r`n")
    $script:PlanejTooltipCache[$cacheKey]=$textoTooltip
    return $textoTooltip
}

function Get-PlanejamentoViewModel($Filtro){
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $ano=[int]$Filtro.Ano
    $dados=Get-PlanejamentoSetorDados $ano 'TODOS'
    $mensal=@{}
    $criticos=@()
    foreach($m in 1..12){
        $real=Get-ContagemInstitucionalAprovadaMes $ano $m
        $lim=Get-LimiteInstitucionalMes $m
        $det=Get-FaixaInstitucionalDetalhes $ano $m $false
        # Mesma chave e maior peso por aquisitivo: total ja calculado nos detalhes.
        $qtd=[double]$det.total
        $mensal[$m]=[pscustomobject]@{qtd=$qtd;real=$real;limite=$lim;detalhes=$det}
        if($lim -gt 0 -and $qtd -gt $lim){$criticos+=$m}
    }
    $script:PlanejCriticoMeses=@($criticos)
    $linhas=New-Object 'System.Collections.Generic.List[object]'
    foreach($item in @($dados.Values|Sort-Object setor,periodo)){
        if([int]$Filtro.Mes -gt 0 -and $item.solicitacoes[[int]$Filtro.Mes].Count -le 0){continue}
        if(-not (Test-PlanejamentoLinhaTemBusca $item.setor $item.periodo $ano ([int]$Filtro.Mes) ([string]$Filtro.Busca))){continue}
        $estado=$null
        if([string]$Filtro.Situacao -ne 'TODAS AS LINHAS' -or [bool]$Filtro.Sobreposicao){$estado=Get-EstadoLinhaPlanejamento $item $ano ([int]$Filtro.Mes) ([bool]$Filtro.Sobreposicao)}
        $incluir=$true
        switch([string]$Filtro.Situacao){
            'SOMENTE CRÍTICAS' {if(-not $estado.critico){$incluir=$false}}
            'COM ALERTA' {if(-not ($estado.critico -or $estado.alerta)){$incluir=$false}}
            'COM FÉRIAS FIXAS' {if(-not $estado.fixa){$incluir=$false}}
            'SEM LIMITE' {if(-not $estado.sem_limite){$incluir=$false}}
        }
        if(-not $incluir){continue}
        if([bool]$Filtro.Sobreposicao -and -not $estado.sobreposicao){continue}
        $linhas.Add($item)
    }
    $cont=Get-ContadoresPlanejamentoAtual $ano
    $sw.Stop()
    return [pscustomobject]@{Ano=$ano;Linhas=@($linhas.ToArray());Contadores=$cont;Meses=$mensal;Criticos=@($criticos);CalculoMs=$sw.ElapsedMilliseconds}
}

function Get-PlanejamentoSnapshot {
    $snapshotCrono=[Diagnostics.Stopwatch]::StartNew()
    $f=[ordered]@{
        Ano=[int]$script:cmbPlanejAno.SelectedItem
        Mes=if($null -ne $script:cmbPlanejMes){[int]$script:cmbPlanejMes.SelectedIndex}else{0}
        Situacao=if($null -ne $script:cmbPlanejSituacao.SelectedItem){[string]$script:cmbPlanejSituacao.SelectedItem}else{'TODAS AS LINHAS'}
        Busca=if($null -ne $script:txtPlanejBuscaServidor){$script:txtPlanejBuscaServidor.Text.Trim()}else{''}
        Sobreposicao=($null -ne $script:chkPlanejSobreposicao -and [bool]$script:chkPlanejSobreposicao.Checked)
        Grupo=[string]$script:PlanejGrupoSelecionado
        Chefia=if($null -ne $script:cmbPlanejChefia.SelectedItem){[string]$script:cmbPlanejChefia.SelectedItem}else{'TODOS'}
        Setores=@($script:PlanejSetoresSelecionados)
        Periodos=@($script:PlanejPeriodosSelecionados)
    }
    # A copia JSON ocorre na thread da UI; o worker nao recebe objetos/controles mutaveis dela.
    $json=([ordered]@{Config=$script:Config;Registros=@($script:Records);Filtro=$f;Hash=[string]$script:LoadedDbHash;Culture=[Globalization.CultureInfo]::CurrentCulture.Name;UICulture=[Globalization.CultureInfo]::CurrentUICulture.Name}|ConvertTo-Json -Depth 20 -Compress)
    $key=Get-TextSha256 $json
    $snapshotCrono.Stop()
    $script:PlanejUltimaCopiaMs=$snapshotCrono.ElapsedMilliseconds
    return [pscustomobject]@{Key=$key;Json=$json}
}

function New-PlanejamentoComputation {
    param([string]$Json,[System.Management.Automation.Runspaces.Runspace]$Runspace)
    $ps=[PowerShell]::Create()
    $ownRunspace=$false
    try {
        if($null -eq $Runspace){
            $initial=[Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $initial.LanguageMode=$ExecutionContext.SessionState.LanguageMode
            # Lista fechada de funcoes de consulta. Nao inclui Save, Load, Importacao, UI ou IO da base.
            foreach($name in @('Convert-ToUpperSemAcento','Get-BlocoFROpcao','Get-BlocosComunsOpcao','Get-ChaveFeriasRegistro','Get-ChaveTipoInstitucional','Get-ContadoresPlanejamentoAtual','Get-ContagemInstitucionalAprovadaMes','Get-ContagemInstitucionalMes','Get-EstadoLinhaPlanejamento','Get-FaixaInstitucionalDetalhes','Get-FixasAdicionais','Get-GrupoAnaliseSetor','Get-GrupoChefiaEfetivaRegistro','Get-GrupoChefiaServidor','Get-GrupoChefiaSetor','Get-LimiteInstitucionalMes','Get-MesesBlocosAno','Get-MesesPlanejamentoRegistro','Get-MesesSolicitacoesRegistro','Get-NomeMesExtenso','Get-NumeroComumConfirmada','Get-NumeroFRConfirmada','Get-OpcaoConfirmadaRegistro','Get-OpcaoPlanejamento','Get-OpcaoSomenteComum','Get-OptionBlocks','Get-OptionBlocksObjeto','Get-OptionBlocksPlanejamento','Get-PesoBlocoInstitucionalMes','Get-PesoOpcaoInstitucionalMes','Get-PlanejamentoOverlapInfo','Get-PlanejamentoSetorDados','Get-PlanejamentoViewModel','Get-SetorPlanejamentoChave','Get-StatusPlanejamentoRegistro','New-EmptyOptionObject','Parse-Date','Test-PlanejamentoLinhaTemBusca','Test-RegistroFeriasBloqueadas','Test-RegistroFixoImportado','Test-SetorPlanejamentoPendente')){
                $fn=Get-Command -Name $name -CommandType Function -ErrorAction Stop
                $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new($name,$fn.Definition))
            }
            # Consulta explicita compartilhada: nenhuma funcao e recortada por texto.
            $approved=(Get-Command Get-ContagemInstitucionalAprovadaMes -CommandType Function).Definition
            $helper='param($r) Get-OpcaoConfirmadaRegistro $r'
            $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new('Get-OpcaoRealPlanejamentoPrivada',$helper))
            $approved=$approved.Replace('Get-OpcaoConfirmadaRegistro $r','Get-OpcaoRealPlanejamentoPrivada $r')
            $initial.Commands.Remove('Get-ContagemInstitucionalAprovadaMes',$null)
            $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new('Get-ContagemInstitucionalAprovadaMes',$approved))
            # Memoizacao somente na copia imutavel do worker, reiniciada a cada pedido.
            # Indice privado da copia evita colisao entre matriculas/IDs ou periodos duplicados.
            foreach($memoName in @('Get-OpcaoRealPlanejamentoPrivada','Get-OpcaoPlanejamento','Get-OptionBlocksPlanejamento','Get-GrupoChefiaEfetivaRegistro')){
                $originalName='__PlanejOriginal_'+$memoName
                $definition=if($memoName -eq 'Get-OpcaoRealPlanejamentoPrivada'){$helper}else{(Get-Command -Name $memoName -CommandType Function -ErrorAction Stop).Definition}
                $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new($originalName,$definition))
                $parameter=if($memoName -eq 'Get-GrupoChefiaEfetivaRegistro'){'registro'}else{'r'}
                $wrapper=@'
param($__PARAM__)
$inputObject=$__PARAM__
if($null -eq $inputObject){return (& '__ORIGINAL__' $inputObject)}
$property=$inputObject.PSObject.Properties['__PlanejIndiceInternoR3']
if($null -eq $property){return (& '__ORIGINAL__' $inputObject)}
$key=[int]$property.Value
if(-not $script:PlanejMemo.ContainsKey('__NAME__')){$script:PlanejMemo['__NAME__']=@{}}
$table=$script:PlanejMemo['__NAME__']
if(-not $table.ContainsKey($key)){
    $table[$key]=[pscustomobject]@{Values=@(& '__ORIGINAL__' $inputObject)}
}
$entry=$table[$key]
return $entry.Values
'@
                $wrapper=$wrapper.Replace('__PARAM__',$parameter).Replace('__ORIGINAL__',$originalName).Replace('__NAME__',$memoName)
                $initial.Commands.Remove($memoName,$null)
                $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new($memoName,$wrapper))
            }
            $initial.Commands.Add([Management.Automation.Runspaces.SessionStateFunctionEntry]::new('Write-DiagLog','param($Message,$Level,$ErrorRecord)'))
            $Runspace=[RunspaceFactory]::CreateRunspace($initial)
            $Runspace.Open()
            $ownRunspace=$true
        }
        $ps.Runspace=$Runspace
        [void]$ps.AddScript({
            param($snapshotJson)
            $ErrorActionPreference='Stop'
            $snapshot=$snapshotJson|ConvertFrom-Json -ErrorAction Stop
            [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo([string]$snapshot.Culture)
            [Threading.Thread]::CurrentThread.CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo([string]$snapshot.UICulture)
            $script:Config=$snapshot.Config
            $script:Records=@($snapshot.Registros)
            $script:PlanejMemo=@{}
            $privateIndex=0
            foreach($record in $script:Records){
                $record|Add-Member NoteProperty __PlanejIndiceInternoR3 $privateIndex -Force
                $privateIndex++
            }
            $script:PlanejGrupoSelecionado=[string]$snapshot.Filtro.Grupo
            $script:PlanejSetoresSelecionados=@($snapshot.Filtro.Setores)
            $script:PlanejPeriodosSelecionados=@($snapshot.Filtro.Periodos)
            $script:cmbPlanejChefia=[pscustomobject]@{SelectedItem=[string]$snapshot.Filtro.Chefia}
            Get-PlanejamentoViewModel $snapshot.Filtro
        }.ToString()).AddArgument($Json)
        $handle=$ps.BeginInvoke()
        return [pscustomobject]@{PowerShell=$ps;Handle=$handle;Runspace=$Runspace}
    } catch {
        $ps.Dispose()
        if($ownRunspace -and $null -ne $Runspace){$Runspace.Dispose()}
        throw
    }
}

function Get-PlanejamentoInstitucionalPronto([int]$Ano){
    if($null -eq $script:PlanejAsync -or $null -eq $script:PlanejAsync.Ready){return $null}
    $ready=$script:PlanejAsync.Ready
    if([int]$ready.Model.Ano -ne $Ano){return $null}
    $current=Get-PlanejamentoSnapshot
    if($current.Key -ne $ready.Key){return $null}
    return $ready.Model
}

function Test-PlanejamentoVisivel {
    return ($null -ne $script:tabsPrincipal -and $null -ne $script:tabPlanejamentoPrincipal -and
            $script:tabsPrincipal.SelectedTab -eq $script:tabPlanejamentoPrincipal)
}

function Set-PlanejamentoUiCalculando {
    if(-not (Test-PlanejamentoVisivel)){return}
    $script:gridPlanejSetor.Enabled=$false
    $script:gridLimiteInstitucional.Enabled=$false
    $script:lblPlanejResumo.Text='Calculando o planejamento em segundo plano... A janela continua disponivel. Aguarde os dados atualizados.'
}

function Set-PlanejamentoUiFalha([string]$Mensagem){
    $script:InstitutionalResumoCacheKey=''
    $script:PlanejRefreshDirty=$true
    if($null -ne $script:PlanejAsync){$script:PlanejAsync.Ready=$null}
    if(-not (Test-PlanejamentoVisivel)){return}
    # Liberar controles sem permitir consultas baseadas nas linhas antigas.
    try {
        $script:gridPlanejSetor.Rows.Clear()
        foreach($row in $script:gridLimiteInstitucional.Rows){
            foreach($cell in $row.Cells){$cell.Value=$null;$cell.ToolTipText=''}
        }
    } finally {
        $script:gridPlanejSetor.Enabled=$true
        $script:gridLimiteInstitucional.Enabled=$true
        $script:lblPlanejResumo.Text=$Mensagem
    }
}

function Request-PlanejamentoComputation($Snapshot){
    if($null -eq $script:PlanejAsync){
        $timer=New-Object Windows.Forms.Timer
        $timer.Interval=60
        $timer.add_Tick({Receive-PlanejamentoComputation})
        $script:PlanejAsync=@{Timer=$timer;Job=$null;Pending=$null;Ready=$null;Wanted='';Closing=$false;Runspace=$null}
    }
    $state=$script:PlanejAsync
    if($state.Closing){return}
    $state.Wanted=$Snapshot.Key
    if($null -ne $state.Ready -and $state.Ready.Key -eq $Snapshot.Key){
        $state.Pending=$null
        if(Test-PlanejamentoVisivel){Refresh-PlanejamentoSetor $state.Ready.Model}else{$script:PlanejRefreshDirty=$true}
        return
    }
    if($null -ne $state.Job -and $state.Job.Key -eq $Snapshot.Key){$state.Pending=$null;Set-PlanejamentoUiCalculando;return}
    # Substitui pedidos intermediarios: somente o filtro mais recente sera executado em seguida.
    $state.Pending=$Snapshot
    $script:PlanejRefreshDirty=$true
    Set-PlanejamentoUiCalculando
    $state.Timer.Start()
    Start-PlanejamentoPending
}

function Start-PlanejamentoPending {
    $state=$script:PlanejAsync
    if($null -eq $state -or $state.Closing -or $null -ne $state.Job -or $null -eq $state.Pending){return}
    $pedido=$state.Pending;$state.Pending=$null
    try {
        $job=New-PlanejamentoComputation -Json $pedido.Json -Runspace $state.Runspace
        $job|Add-Member -NotePropertyName Key -NotePropertyValue $pedido.Key
        $state.Runspace=$job.Runspace
        $state.Job=$job
    } catch {
        Write-DiagLog 'CORR-R6: falha ao iniciar calculo de planejamento em segundo plano.' 'ERROR' $_
        Set-PlanejamentoUiFalha 'Nao foi possivel iniciar o calculo. Clique Atualizar analise; consulte o log se persistir.' 
        $state.Timer.Stop()
    }
}

function Receive-PlanejamentoComputation {
    $state=$script:PlanejAsync
    if($null -eq $state -or $state.Closing){return}
    if($null -eq $state.Job){Start-PlanejamentoPending;return}
    if(-not $state.Job.Handle.IsCompleted){return}
    $job=$state.Job;$state.Job=$null
    try {
        $output=$job.PowerShell.EndInvoke($job.Handle)
        if($output.Count -ne 1){throw 'O calculo do planejamento nao retornou um resultado unico.'}
        $model=$output[0]
        if($job.Key -eq $state.Wanted){
            # Revalidar a COPIA atual: Save/importacao/filtros podem ter mudado durante o calculo.
            $atual=Get-PlanejamentoSnapshot
            if($job.Key -eq $atual.Key){
                $state.Ready=[pscustomobject]@{Key=$job.Key;Model=$model}
                if($script:tabsPrincipal.SelectedTab -eq $script:tabPlanejamentoPrincipal){
                    Refresh-PlanejamentoSetor $model
                } else {$script:PlanejRefreshDirty=$true}
                Write-DiagLog "CORR-R6: calculo de planejamento=$($model.CalculoMs)ms | linhas=$(@($model.Linhas).Count) | thread=worker" 'INFO'
            } elseif($script:tabsPrincipal.SelectedTab -eq $script:tabPlanejamentoPrincipal){
                $state.Wanted=$atual.Key;$state.Pending=$atual
            } else {$script:PlanejRefreshDirty=$true}
        }
    } catch {
        Write-DiagLog 'CORR-R6: falha no calculo/aplicacao do planejamento; nenhum dado foi gravado pelo worker.' 'ERROR' $_
        # Uma falha de pedido antigo nao apaga um resultado/filtro mais recente.
        if($job.Key -eq $state.Wanted -and $null -eq $state.Pending){
            Set-PlanejamentoUiFalha 'Falha ao calcular o planejamento. Clique Atualizar analise ou consulte o log.'
        }
    } finally {$job.PowerShell.Dispose()}
    if($null -ne $state.Pending){Start-PlanejamentoPending}else{$state.Timer.Stop()}
}

# Prepara o primeiro resultado depois da carga/sincronizacao inicial.
# O timer apenas agenda; o calculo continua no worker de leitura existente.
function Start-PlanejamentoWarmup {
    if($script:PlanejWarmupClosed -or $script:PlanejBootSyncPending){return}
    if($null -eq $script:cmbPlanejAno -or $null -eq $script:cmbPlanejAno.SelectedItem){return}
    $state=$script:PlanejAsync
    # Nunca substitui um pedido que o usuario ja iniciou.
    if($null -ne $state -and ($state.Closing -or $null -ne $state.Job -or $null -ne $state.Pending)){return}
    try {
        $snapshot=Get-PlanejamentoSnapshot
        if($null -ne $state -and $null -ne $state.Ready -and $state.Ready.Key -eq $snapshot.Key){return}
        Write-DiagLog 'CORR-R6: preparando planejamento apos carga inicial, em segundo plano.' 'INFO'
        Request-PlanejamentoComputation $snapshot
    } catch {
        Write-DiagLog 'CORR-R6: preparo antecipado falhou; abertura da aba tentara normalmente.' 'WARN' $_
        $script:PlanejRefreshDirty=$true
    }
}

function Request-PlanejamentoWarmup {
    if($script:PlanejWarmupClosed -or $script:PlanejBootSyncPending){return}
    if($null -ne $script:PlanejWarmupTimer){return}
    $script:PlanejWarmupTimer=New-Object Windows.Forms.Timer
    $script:PlanejWarmupTimer.Interval=300
    $script:PlanejWarmupTimer.add_Tick({
        try {$script:PlanejWarmupTimer.Stop();$script:PlanejWarmupTimer.Dispose()}catch{}
        $script:PlanejWarmupTimer=$null
        Start-PlanejamentoWarmup
    })
    $script:PlanejWarmupTimer.Start()
}

function Stop-PlanejamentoComputation {
    $script:PlanejWarmupClosed=$true
    if($null -ne $script:PlanejWarmupTimer){
        try {$script:PlanejWarmupTimer.Stop();$script:PlanejWarmupTimer.Dispose()}catch{}
        $script:PlanejWarmupTimer=$null
    }
    if($null -eq $script:PlanejAsync){return}
    $state=$script:PlanejAsync;$state.Closing=$true;$state.Pending=$null
    try{$state.Timer.Stop();$state.Timer.Dispose()}catch{}
    if($null -ne $state.Job){
        try{$state.Job.PowerShell.Stop()}catch{}
        try{[void]$state.Job.PowerShell.EndInvoke($state.Job.Handle)}catch{}
        try{$state.Job.PowerShell.Dispose()}catch{}
    }
    if($null -ne $state.Runspace){try{$state.Runspace.Close();$state.Runspace.Dispose()}catch{}}
    $script:PlanejAsync=$null
}

function Refresh-PlanejamentoSetor($Preparado=$null) {
    if($null -eq $script:gridPlanejSetor){ return }
    if($null -eq $script:cmbPlanejAno.SelectedItem){ return }
    # Atualizacoes de abas ocultas ficam pendentes para a proxima visita.
    # Evita redesenhos e calculos caros apos salvar/importar quando o usuario esta em outra tela.
    if($null -ne $script:tabsPrincipal -and $null -ne $script:tabPlanejamentoPrincipal -and
       $script:tabsPrincipal.SelectedTab -ne $script:tabPlanejamentoPrincipal){
        $script:PlanejRefreshDirty=$true
        return
    }
    if($null -eq $Preparado){
        $snapshot=Get-PlanejamentoSnapshot
        if($script:PlanejUltimaCopiaMs -ge 150){Write-DiagLog "CORR-R6: copia de dados para calculo=$($script:PlanejUltimaCopiaMs)ms" 'INFO'}
        Request-PlanejamentoComputation $snapshot
        return
    }
    $script:PlanejRefreshDirty=$false
    $swPerf=[Diagnostics.Stopwatch]::StartNew()
    $script:gridPlanejSetor.SuspendLayout()
    try {

    # V1.0.53: a grade diferencia BASE DE DECISÃO (B) de SOLICITAÇÕES (S).
    # B = férias FIXAS + ACEITAS + 1ª opção dos pendentes (ocupação usada no motor atual).
    # S = todas as opções informadas dos pendentes, permitindo visualizar também pedidos de 2028
    #     sem tratá-los indevidamente como férias já comprometidas.
    if($null -eq $script:PlanejOverlapCache){ $script:PlanejOverlapCache=@{} }
    if($null -eq $script:PlanejChefiaOverlapCache){ $script:PlanejChefiaOverlapCache=@{} }
    if($null -eq $script:PlanejTooltipCache){ $script:PlanejTooltipCache=@{} }

    $ano=[int]$script:cmbPlanejAno.SelectedItem
    $periodoFiltro="TODOS"
    $mesFoco=0
    if($null -ne $script:cmbPlanejMes -and $script:cmbPlanejMes.SelectedIndex -gt 0){
        $mesFoco=[int]$script:cmbPlanejMes.SelectedIndex
    }
    $situacao=if($null -ne $script:cmbPlanejSituacao.SelectedItem){[string]$script:cmbPlanejSituacao.SelectedItem}else{"TODAS AS LINHAS"}
    $busca=if($null -ne $script:txtPlanejBuscaServidor){$script:txtPlanejBuscaServidor.Text.Trim()}else{""}
    $somenteSobreposicao=($null -ne $script:chkPlanejSobreposicao -and [bool]$script:chkPlanejSobreposicao.Checked)

    $script:gridPlanejSetor.Rows.Clear()

    foreach($m in 1..12){
        $script:gridPlanejSetor.Columns["ps$m"].HeaderCell.Style.BackColor=[Drawing.Color]::FromArgb(240,240,240)
    }
    if($mesFoco -gt 0){
        $script:gridPlanejSetor.Columns["ps$mesFoco"].HeaderCell.Style.BackColor=[Drawing.Color]::FromArgb(221,235,247)
    }

    # Calculo institucional por mes ocorre uma so vez por atualizacao da grade.
    $script:PlanejCriticoMeses=@($Preparado.Criticos)
    $mesCriticoIndice=@{}
    foreach($mesCritico in @($script:PlanejCriticoMeses)){ $mesCriticoIndice[[int]$mesCritico]=$true }
    $visiveis=0
    $itens=@($Preparado.Linhas)
    $rowBuffer=New-Object 'System.Collections.Generic.List[System.Windows.Forms.DataGridViewRow]'
    $columnIndexes=@{}
    foreach($column in $script:gridPlanejSetor.Columns){$columnIndexes[$column.Name]=$column.Index}

    foreach($item in $itens){
        $row=New-Object System.Windows.Forms.DataGridViewRow
        $row.Height=$script:gridPlanejSetor.RowTemplate.Height
        $row.CreateCells($script:gridPlanejSetor)
        $row.Cells[$columnIndexes["psSetor"]].Value=$item.setor
        $row.Cells[$columnIndexes["psPeriodo"]].Value=$item.periodo
        if(Test-SetorPlanejamentoPendente $item.setor){
            $row.Cells[$columnIndexes["psSetor"]].Style.BackColor=[Drawing.Color]::FromArgb(255,244,204)
            $row.Cells[$columnIndexes["psSetor"]].Style.ForeColor=[Drawing.Color]::DarkRed
            $row.Cells[$columnIndexes["psSetor"]].Style.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
            $row.Cells[$columnIndexes["psSetor"]].ToolTipText="Solicitação existente, mas o servidor ainda não tem Setor informado. Corrija em Lançamentos ou na planilha-base."
        }

        # Coluna historica de limite local apenas informativa, sem consulta pesada.
        $row.Cells[$columnIndexes["psLimite"]].Value="—"

        $totalBase=0
        $totalSolic=0
        foreach($m in 1..12){
            $qtd=$item.meses[$m].Count
            $qtdSolic=$item.solicitacoes[$m].Count
            $totalBase += $qtd
            $totalSolic += $qtdSolic

            if($qtdSolic -gt $qtd){
                $row.Cells[$columnIndexes["ps$m"]].Value="B:$qtd | S:$qtdSolic"
            } else {
                $row.Cells[$columnIndexes["ps$m"]].Value=$qtd
            }

            if($qtd -gt 0){
                # Regras atuais: somente o limite institucional e os limites especiais
                # definem alertas. Setor/periodo/chefia nao geram restricoes.
                if($mesCriticoIndice.ContainsKey([int]$m)){
                    $row.Cells[$columnIndexes["ps$m"]].Style.BackColor=[Drawing.Color]::MistyRose
                    $row.Cells[$columnIndexes["ps$m"]].ToolTipText="ATENCAO: limite institucional desse mes ultrapassado. Base nesta linha: $qtd; solicitacoes: $qtdSolic. Clique para consultar servidores."
                } else {
                    $row.Cells[$columnIndexes["ps$m"]].Style.BackColor=[Drawing.Color]::FromArgb(226,239,218)
                    $row.Cells[$columnIndexes["ps$m"]].ToolTipText="Base de decisao: $qtd servidor(es); solicitacoes: $qtdSolic. Fixas e aceitas ja comprometem a capacidade; alternativas nao. Clique para consultar."
                }
                if($qtdSolic -gt $qtd){
                    $row.Cells[$columnIndexes["ps$m"]].ToolTipText += "`r`nHa opcoes alternativas neste mes; nao representam vagas confirmadas."
                }
            } elseif($qtdSolic -gt 0) {
                # Há pedidos para o mês, mas apenas como opções alternativas.
                $row.Cells[$columnIndexes["ps$m"]].Style.BackColor=[Drawing.Color]::FromArgb(255,248,220)
                $row.Cells[$columnIndexes["ps$m"]].Style.ForeColor=[Drawing.Color]::FromArgb(156,101,0)
                $row.Cells[$columnIndexes["ps$m"]].ToolTipText="SOLICITAÇÕES: $qtdSolic servidor(es) têm pelo menos uma opção neste mês.`r`nNenhuma dessas alternativas integra a base de decisão atual. Clique para ver os servidores."
            } else {
                $row.Cells[$columnIndexes["ps$m"]].ToolTipText=""
            }
        }

        if($totalSolic -gt $totalBase){
            $row.Cells[$columnIndexes["psTotal"]].Value="B:$totalBase | S:$totalSolic"
        } else {
            $row.Cells[$columnIndexes["psTotal"]].Value=$totalBase
        }
        $rowBuffer.Add($row)
        $visiveis++
    }

    if($rowBuffer.Count -gt 0){$script:gridPlanejSetor.Rows.AddRange([System.Windows.Forms.DataGridViewRow[]]$rowBuffer.ToArray())}
    $cont=$Preparado.Contadores
    $foco=if($mesFoco -gt 0){" | Mês em foco: $([string]$script:cmbPlanejMes.SelectedItem)"}else{""}
    $chefiaTxt=if($null -ne $script:cmbPlanejChefia -and $null -ne $script:cmbPlanejChefia.SelectedItem){" | Chefia: $([string]$script:cmbPlanejChefia.SelectedItem)"}else{""}
    $script:lblPlanejResumo.Text="Grupo: $($script:PlanejGrupoSelecionado)$chefiaTxt | FIXAS: $($cont.fixas) | Aceitas: $($cont.aceitas) | Pendentes com solicitação no ano: $($cont.pendentes) | Linhas exibidas: $visiveis$foco | B=base de decisão / S=todas as solicitações"
    Refresh-LimiteInstitucionalResumo $Preparado
    $script:gridPlanejSetor.Enabled=$true
    $script:gridLimiteInstitucional.Enabled=$true
    $swPerf.Stop()
    if($swPerf.ElapsedMilliseconds -ge 250){ Write-DiagLog "PERF Refresh-PlanejamentoSetor: $($swPerf.ElapsedMilliseconds) ms | linhas=$visiveis | modo=renderizacao_CORR-R6" "WARN" }
    } finally {
        $script:gridPlanejSetor.ResumeLayout()
    }
}

function Format-OptionSummary($op){
    if($null -eq $op -or [string]::IsNullOrWhiteSpace([string]$op.tipo)){ return "Não informada" }

    $tipo=[string]$op.tipo
    if($tipo -eq 'FR 20 DIAS'){
        return 'FR 20 DIAS | '+(Date-ToBR ([string]$op.fr_inicio))+' a '+(Date-ToBR ([string]$op.fr_fim))
    }
    $i1=Date-ToBR ([string]$op.inicio1)
    $f1=Date-ToBR ([string]$op.fim1)
    $i2=Date-ToBR ([string]$op.inicio2)
    $f2=Date-ToBR ([string]$op.fim2)

    $c1=Get-ClassificacaoDataStore ([string]$op.inicio1)
    $c2=Get-ClassificacaoDataStore ([string]$op.inicio2)
    $t1=if($null -ne $c1){" [$([string]$c1.texto)]"}else{""}
    $t2=if($null -ne $c2){" [$([string]$c2.texto)]"}else{""}
    $frTexto=if([string]$op.fr_inicio -and [string]$op.fr_fim){' + FR 20 DIAS '+(Date-ToBR ([string]$op.fr_inicio))+' a '+(Date-ToBR ([string]$op.fr_fim))}else{''}
    if($tipo -eq "15+15 DIAS"){
        $p1=if($i1 -and $f1){"$i1$t1 a $f1"}else{"1º bloco incompleto"}
        $p2=if($i2 -and $f2){"$i2$t2 a $f2"}else{"2º bloco incompleto"}
        return "$tipo | $p1 | $p2$frTexto"
    }

    if($i1 -and $f1){ return "$tipo | $i1$t1 a $f1$frTexto" }
    return "$tipo | datas incompletas$frTexto"
}

function Get-OpcaoAceitaTexto([int]$n){
    switch($n){
        1 { return "1ª opção" }
        2 { return "2ª opção" }
        3 { return "3ª opção" }
        default { return "Não definida" }
    }
}

function Abrir-AjusteFeriasFixa($r,$owner){
    if($null -eq $r -or -not (Test-RegistroFeriasBloqueadas $r)){ return $false }
    if(-not (Test-RegistroFixoImportado $r)){
        [Windows.Forms.MessageBox]::Show(
            "Este bloqueio foi criado manualmente e não possui um período fixo importado separado.`n`nPara alterá-lo, use a aba Lançamentos e desbloqueie o período com a confirmação de segurança.",
            "Férias fixa manual",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return $false
    }

    $oldIni=Parse-Date ([string]$r.fixo_inicio); $oldFim=Parse-Date ([string]$r.fixo_fim)
    if($null -eq $oldIni -or $null -eq $oldFim){ return $false }

    $aviso="ATENÇÃO`n`nEste período está marcado como FÉRIAS FIXAS da programação anterior.`n`nAltere somente se houver confirmação de que o RH modificou as datas ou se for necessário corrigir informação comprovadamente incorreta.`n`nUm backup será criado e o motivo ficará registrado. Deseja continuar?"
    $resp=[Windows.Forms.MessageBox]::Show($aviso,"Alterar férias fixa",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
    if($resp -ne [Windows.Forms.DialogResult]::Yes){ return $false }

    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="Alterar período de férias fixa - $($r.nome)"
    $dlg.StartPosition="CenterParent"; $dlg.Size=New-Object Drawing.Size(690,470); $dlg.MinimumSize=New-Object Drawing.Size(690,470)
    $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false; $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $p=New-Object Windows.Forms.Panel; $p.Dock="Top"; $p.Height=82; $p.BackColor=[Drawing.Color]::FromArgb(220,237,255); $dlg.Controls.Add($p)
    $l=New-Object Windows.Forms.Label; $l.Location=New-Object Drawing.Point(15,12); $l.Size=New-Object Drawing.Size(640,56)
    $l.Text="FÉRIAS FIXAS - AJUSTE CONTROLADO`r`nPeríodo atual: $($oldIni.ToString('dd/MM/yyyy')) a $($oldFim.ToString('dd/MM/yyyy')) | Origem: $([string]$r.origem_planejamento)"
    $l.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $l.ForeColor=[Drawing.Color]::FromArgb(0,79,145); $p.Controls.Add($l)

    $dlg.Controls.Add((New-Label "Novo início" 20 105 100))
    $dtIni=New-DatePicker 20 128 180; Set-DatePicker $dtIni (Date-ToStore $oldIni); $dlg.Controls.Add($dtIni)
    $dlg.Controls.Add((New-Label "Novo fim" 220 105 100))
    $dtFim=New-DatePicker 220 128 180; Set-DatePicker $dtFim (Date-ToStore $oldFim); $dlg.Controls.Add($dtFim)
    $diasAntes=($oldFim-$oldIni).Days+1
    $lblDur=New-Object Windows.Forms.Label; $lblDur.Location=New-Object Drawing.Point(420,130); $lblDur.Size=New-Object Drawing.Size(220,24); $lblDur.Text="Duração atual: $diasAntes dia(s)"; $dlg.Controls.Add($lblDur)

    $dlg.Controls.Add((New-Label "Motivo da alteração (obrigatório)" 20 175 260))
    $cmbMot=New-Combo 20 198 360
    @("ALTERAÇÃO CONFIRMADA PELO RH","CORREÇÃO DE DATA IMPORTADA","INFORMAÇÃO RECEBIDA APÓS A PROGRAMAÇÃO","OUTRO") | ForEach-Object {[void]$cmbMot.Items.Add($_)}
    $cmbMot.SelectedIndex=-1; $dlg.Controls.Add($cmbMot)

    $dlg.Controls.Add((New-Label "Justificativa / observação (obrigatória)" 20 238 320))
    $txt=New-Object Windows.Forms.TextBox; $txt.Location=New-Object Drawing.Point(20,262); $txt.Size=New-Object Drawing.Size(635,95); $txt.Multiline=$true; $txt.ScrollBars="Vertical"; $txt.MaxLength=800; $dlg.Controls.Add($txt)

    $btnSalvar=New-Button "SALVAR AJUSTE" 400 380 150 36; $btnSalvar.BackColor=[Drawing.Color]::FromArgb(205,235,205); $dlg.Controls.Add($btnSalvar)
    $btnCancel=New-Button "Cancelar" 560 380 95 36; $dlg.Controls.Add($btnCancel)
    $estadoAjuste=[pscustomobject]@{Ok=$false}
    $btnCancel.add_Click({$dlg.Close()})
    $btnSalvar.add_Click({
        if(-not $dtIni.Checked -or -not $dtFim.Checked){ [Windows.Forms.MessageBox]::Show("Informe início e fim do novo período.","Validação") | Out-Null; return }
        $ni=$dtIni.Value.Date; $nf=$dtFim.Value.Date
        if($nf -lt $ni){ [Windows.Forms.MessageBox]::Show("A data final não pode ser anterior à inicial.","Validação") | Out-Null; return }
        if($cmbMot.SelectedIndex -lt 0){ [Windows.Forms.MessageBox]::Show("Selecione o motivo da alteração.","Validação") | Out-Null; return }
        if([string]::IsNullOrWhiteSpace($txt.Text)){ [Windows.Forms.MessageBox]::Show("Informe a justificativa/observação da alteração.","Validação") | Out-Null; return }
        $diasNovo=($nf-$ni).Days+1
        if($diasNovo -ne $diasAntes){
            $r2=[Windows.Forms.MessageBox]::Show("A duração mudará de $diasAntes para $diasNovo dia(s).`n`nConfirma que o RH também alterou a duração das férias?","Confirmar mudança de duração",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
            if($r2 -ne [Windows.Forms.DialogResult]::Yes){ return }
        }
        [void](Backup-AntesAcao "ANTES_AJUSTAR_FERIAS_FIXA")
        if([string]::IsNullOrWhiteSpace([string]$r.fixo_inicio_original)){ $r.fixo_inicio_original=[string]$r.fixo_inicio }
        if([string]::IsNullOrWhiteSpace([string]$r.fixo_fim_original)){ $r.fixo_fim_original=[string]$r.fixo_fim }
        $r.fixo_inicio=Date-ToStore $ni; $r.fixo_fim=Date-ToStore $nf
        $r.fixo_ajustado=$true; $r.fixo_ajustado_em=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $r.fixo_motivo_ajuste=[string]$cmbMot.SelectedItem; $r.fixo_observacao_ajuste=$txt.Text.Trim(); $r.fixo_ajustado_por=[string]$env:USERNAME
        $r.origem_planejamento="PROGRAMACAO_ANTERIOR_AJUSTADA"
        $r.bloqueio_motivo="Férias fixa ajustada manualmente após confirmação: $([string]$cmbMot.SelectedItem)"
        $r.justificativa_decisao=$txt.Text.Trim()
        try {
            Save-Database
        } catch {
            # Save-Database recarrega a base oficial quando a gravação falha.
            # Fechar este diálogo evita repetir a operação sobre um registro obsoleto.
            Write-DiagLog "Falha na gravação do ajuste de férias fixa ID=$($r.id)." "ERROR" $_
            [Windows.Forms.MessageBox]::Show("A correção da férias fixa NÃO foi confirmada. O sistema recarregou a base do disco. Abra novamente o registro antes de tentar outra alteração.","Ajuste não salvo",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            $dlg.Close()
            return
        }
        Write-DiagLog "Férias fixa ajustada | ID=$($r.id) | Matrícula=$($r.matricula) | $($oldIni.ToString('yyyy-MM-dd'))..$($oldFim.ToString('yyyy-MM-dd')) -> $($ni.ToString('yyyy-MM-dd'))..$($nf.ToString('yyyy-MM-dd')) | Motivo=$([string]$cmbMot.SelectedItem)"
        $script:PlanejOverlapCache=@{}; $script:PlanejChefiaOverlapCache=@{}; $script:PlanejCellIndex=@{}; $script:PlanejCellIndexBuilt=@{}
        $estadoAjuste.Ok=$true; $dlg.Close()
    })
    [void]$dlg.ShowDialog($owner)
    return $estadoAjuste.Ok
}

function Get-PlanejamentoCellIds([string]$setor,[string]$periodo,[int]$ano,[int]$mes){
    if($null -eq $script:PlanejCellIndex){ $script:PlanejCellIndex=@{} }
    if($null -eq $script:PlanejCellIndexBuilt){ $script:PlanejCellIndexBuilt=@{} }
    $anoKey=[string]$ano
    if(-not $script:PlanejCellIndexBuilt.ContainsKey($anoKey)){
        $sw=[Diagnostics.Stopwatch]::StartNew()
        foreach($r in $script:Records){
            $s=Get-SetorPlanejamentoChave ([string]$r.setor)
            $p=([string]$r.periodo).Trim(); if([string]::IsNullOrWhiteSpace($p)){ $p="SEM PERÍODO" }
            foreach($m in (Get-MesesSolicitacoesRegistro $r $ano)){
                $k="$ano|$s|$p|$m"
                if(-not $script:PlanejCellIndex.ContainsKey($k)){
                    $script:PlanejCellIndex[$k]=New-Object 'System.Collections.Generic.List[int]'
                }
                [void]$script:PlanejCellIndex[$k].Add([int]$r.id)
            }
        }
        $script:PlanejCellIndexBuilt[$anoKey]=$true
        $sw.Stop()
        if($sw.ElapsedMilliseconds -ge 150){ Write-DiagLog "PERF índice de células do planejamento: $($sw.ElapsedMilliseconds) ms | ano=$ano | chaves=$($script:PlanejCellIndex.Count)" "WARN" }
    }
    $key="$ano|$setor|$periodo|$mes"
    if($script:PlanejCellIndex.ContainsKey($key)){ return @($script:PlanejCellIndex[$key]) }
    return @()
}

function Mostrar-DetalhePlanejamento([string]$setor,[string]$periodoLinha,[int]$mes){
    if([string]::IsNullOrWhiteSpace($setor) -or $mes -lt 1 -or $mes -gt 12){ return }
    $ano=[int]$script:cmbPlanejAno.SelectedItem
    $itens=@()
    $idsCelula=@(Get-PlanejamentoCellIds $setor $periodoLinha $ano $mes)
    if($idsCelula.Count -gt 0){
        $idSet=New-Object 'System.Collections.Generic.HashSet[int]'
        foreach($id in $idsCelula){ [void]$idSet.Add([int]$id) }
        foreach($r in $script:Records){
            if(-not $idSet.Contains([int]$r.id)){ continue }
            $aqIni=Date-ToBR ([string]$r.aquisitivo_inicio); $aqFim=Date-ToBR ([string]$r.aquisitivo_fim)
            $itens += [pscustomobject]@{id=[int]$r.id;matricula=[string]$r.matricula;nome=[string]$r.nome;aquisitivo=if($aqIni -and $aqFim){"$aqIni a $aqFim"}else{"Sem período aquisitivo"};aceita=[int]$r.opcao_aprovada;status=(Get-StatusExibicaoRegistro $r);base=(Get-DescricaoBasePlanejamento $r)}
        }
    }
    $mesNome=@("Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")[$mes-1]

    $dlg=New-Object Windows.Forms.Form; Apply-AppBranding $dlg
    $dlg.Text="$setor - $periodoLinha - $mesNome/$ano - Central de decisão"
    # V1.0.53: a grade superior abre dimensionada conforme a quantidade de registros da célula.
    $alturaGrade=[int][math]::Min(300,[math]::Max(96,34+($itens.Count*25)))
    $alturaJanela=[int][math]::Min(900,[math]::Max(700,700+($alturaGrade-125)))
    $dlg.StartPosition="CenterParent"; $dlg.Size=New-Object Drawing.Size(1240,$alturaJanela); $dlg.MinimumSize=New-Object Drawing.Size(1240,640); $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $top=New-Object Windows.Forms.Panel; $top.Dock="Top"; $top.Height=70; $top.BackColor=[Drawing.Color]::FromArgb(245,248,252); $dlg.Controls.Add($top)
    $lbl=New-Object Windows.Forms.Label; $lbl.Text="$($itens.Count) período(s) aquisitivo(s) | $setor | $periodoLinha | $mesNome/$ano"; $lbl.Location=New-Object Drawing.Point(12,8); $lbl.Size=New-Object Drawing.Size(1210,24); $lbl.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold); $top.Controls.Add($lbl)
    $lblAjuda=New-Object Windows.Forms.Label; $lblAjuda.Text=if($itens.Count -gt 1){"ATENÇÃO: há $($itens.Count) registros nesta célula. Use a lista superior ou os botões Anterior/Próximo no rodapé para analisar todos."}else{"Selecione o servidor, revise as 3 opções e registre a decisão. Registros FIXOS ficam azuis; o botão 'Alterar período fixo' permite correção excepcional com backup e justificativa."}; $lblAjuda.Location=New-Object Drawing.Point(12,37); $lblAjuda.Size=New-Object Drawing.Size(1210,23); if($itens.Count -gt 1){$lblAjuda.ForeColor=[Drawing.Color]::DarkBlue;$lblAjuda.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)}; $top.Controls.Add($lblAjuda)

    $bottom=New-Object Windows.Forms.Panel; $bottom.Dock="Bottom"; $bottom.Height=62; $bottom.BackColor=[Drawing.Color]::FromArgb(247,247,247); $dlg.Controls.Add($bottom)
    $lblContagem=New-Object Windows.Forms.Label; $lblContagem.Location=New-Object Drawing.Point(12,20); $lblContagem.Size=New-Object Drawing.Size(300,28); $lblContagem.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $bottom.Controls.Add($lblContagem)
    $btnAnterior=New-Button "< Anterior" 315 13 105 36; $btnProximo=New-Button "Próximo >" 425 13 105 36; $bottom.Controls.Add($btnAnterior); $bottom.Controls.Add($btnProximo)
    $btnAnalisar=New-Button "Analisar alterações" 700 13 165 36
    $btnSalvarTudo=New-Button "SALVAR OPÇÕES E DECISÃO" 875 13 210 36; $btnSalvarTudo.BackColor=[Drawing.Color]::FromArgb(205,235,205)
    $btnFechar=New-Button "Fechar" 1095 13 120 36
    $btnAnalisar.Anchor=[Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right; $btnSalvarTudo.Anchor=[Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right; $btnFechar.Anchor=[Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
    $bottom.Controls.Add($btnAnalisar); $bottom.Controls.Add($btnSalvarTudo); $bottom.Controls.Add($btnFechar)

    $split=New-Object Windows.Forms.SplitContainer
    $split.Dock="Fill"
    $split.Orientation="Horizontal"
    $split.FixedPanel="Panel1"
    $split.SplitterWidth=5
    $split.Tag=$alturaGrade
    $dlg.Controls.Add($split)
    $split.BringToFront()
    $split.add_SizeChanged({
        try {
            if($split.Height -gt 320){
                $alvo=[int]$split.Tag
                if($alvo -gt ($split.Height-260)){$alvo=$split.Height-260}
                if($alvo -gt 70 -and $alvo -lt $split.Height){$split.SplitterDistance=$alvo}
            }
        } catch { Write-DiagLog ("Ajuste visual SplitContainer Central de Decisão ignorado: "+$_.Exception.Message) "WARN" }
    })
    $dlg.add_Shown({
        try {
            $alvo=[int]$split.Tag
            if($alvo -gt ($split.Height-260)){$alvo=$split.Height-260}
            if($alvo -gt 70 -and $alvo -lt $split.Height){$split.SplitterDistance=$alvo}
        } catch {}
    })
    $g=New-Object Windows.Forms.DataGridView; $g.Dock="Fill"; $g.ReadOnly=$true; $g.AllowUserToAddRows=$false; $g.AllowUserToDeleteRows=$false; $g.RowHeadersVisible=$false; $g.SelectionMode="FullRowSelect"; $g.MultiSelect=$false; $g.AutoSizeColumnsMode="Fill"; $g.BackgroundColor=[Drawing.Color]::White; $g.RowTemplate.Height=24; $g.ColumnHeadersHeight=26
    foreach($c in @(@("rid","ID"),@("mat","Matrícula"),@("nome","Nome"),@("aq","Período aquisitivo"),@("status","Situação"),@("aceita","Opção aceita"))){[void]$g.Columns.Add($c[0],$c[1])}
    $g.Columns["rid"].Visible=$false; $g.Columns["mat"].FillWeight=14; $g.Columns["nome"].FillWeight=34; $g.Columns["aq"].FillWeight=25; $g.Columns["status"].FillWeight=15; $g.Columns["aceita"].FillWeight=12
    foreach($item in ($itens | Sort-Object nome,aquisitivo)){
        $idx=$g.Rows.Add(); $rr=$g.Rows[$idx]; $rr.Cells["rid"].Value=$item.id; $rr.Cells["mat"].Value=$item.matricula; $rr.Cells["nome"].Value=$item.nome; $rr.Cells["aq"].Value=$item.aquisitivo; $rr.Cells["status"].Value=$item.status; $rr.Cells["aceita"].Value=Get-OpcaoAceitaTexto $item.aceita; $rr.Cells["status"].ToolTipText=$item.base
        if($item.status -eq "FIXA AJUSTADA"){$rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(177,214,255)} elseif($item.status -like "FIXA*"){$rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(211,232,255)} elseif($item.status -eq "ACEITA"){$rr.DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218)}
    }
    $split.Panel1.Controls.Add($g)

    $detail=New-Object Windows.Forms.Panel; $detail.Dock="Fill"; $detail.AutoScroll=$true; $detail.AutoScrollMinSize=New-Object Drawing.Size(1210,830); $split.Panel2.Controls.Add($detail)
    $lblSel=New-Object Windows.Forms.Label; $lblSel.Text="Selecione um servidor acima."; $lblSel.Location=New-Object Drawing.Point(12,6); $lblSel.Size=New-Object Drawing.Size(1195,24); $lblSel.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $detail.Controls.Add($lblSel)

    $grpFixo=New-Object Windows.Forms.GroupBox; $grpFixo.Text="2ª etapa remanescente / compromisso protegido"; $grpFixo.Location=New-Object Drawing.Point(12,34); $grpFixo.Size=New-Object Drawing.Size(1175,92); $grpFixo.BackColor=[Drawing.Color]::FromArgb(220,237,255); $grpFixo.Visible=$false; $detail.Controls.Add($grpFixo)
    $lblFixo=New-Object Windows.Forms.Label; $lblFixo.Location=New-Object Drawing.Point(15,25); $lblFixo.Size=New-Object Drawing.Size(870,52); $lblFixo.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $lblFixo.ForeColor=[Drawing.Color]::FromArgb(0,79,145); $grpFixo.Controls.Add($lblFixo)
    $btnAlterarFixo=New-Button "Alterar período fixo..." 930 31 220 36; $btnAlterarFixo.BackColor=[Drawing.Color]::FromArgb(207,229,255); $grpFixo.Controls.Add($btnAlterarFixo)

    $ed1=New-OptionGroup "1ª OPÇÃO - EDITAR" 12 34; $ed2=New-OptionGroup "2ª OPÇÃO - EDITAR" 407 34; $ed3=New-OptionGroup "3ª OPÇÃO - EDITAR" 802 34
    $resumosFR=@()
    foreach($ed in @($ed1,$ed2,$ed3)){
        $ed.Group.Size=New-Object Drawing.Size(382,235)
        $frLabel=New-Object Windows.Forms.Label
        $frLabel.Location=New-Object Drawing.Point(12,162)
        $frLabel.Size=New-Object Drawing.Size(360,23)
        $frLabel.ForeColor=[Drawing.Color]::FromArgb(0,80,150)
        $frLabel.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold)
        $frLabel.Text='FR 20 DIAS: não informada'
        $frLabel.Visible=$false
        $ed.Group.Controls.Add($frLabel)
        $resumosFR+=,$frLabel
        $detail.Controls.Add($ed.Group)
    }

    $lblAceita=New-Label "Opção aceita / definida" 12 207 165; $detail.Controls.Add($lblAceita)
    $cmbAceita=New-Combo 12 227 190; @("Não definida","1ª opção","2ª opção","3ª opção") | ForEach-Object {[void]$cmbAceita.Items.Add($_)}; $cmbAceita.SelectedIndex=0; $cmbAceita.Enabled=$false; $detail.Controls.Add($cmbAceita)
    $lblProtecao=New-Object Windows.Forms.Label; $lblProtecao.Location=New-Object Drawing.Point(220,225); $lblProtecao.Size=New-Object Drawing.Size(965,38); $detail.Controls.Add($lblProtecao)

    $lblJust=New-Label "Justificativa da decisão / motivo da escolha ou não escolha (opcional)" 12 268 520 22; $detail.Controls.Add($lblJust)
    $txtJust=New-Object Windows.Forms.TextBox; $txtJust.Location=New-Object Drawing.Point(12,292); $txtJust.Size=New-Object Drawing.Size(1170,62); $txtJust.Multiline=$true; $txtJust.ScrollBars="Vertical"; $txtJust.MaxLength=1000; $detail.Controls.Add($txtJust)

    $grpSug=New-Object Windows.Forms.GroupBox; $grpSug.Text="Análise / sugestão do sistema"; $grpSug.Location=New-Object Drawing.Point(12,362); $grpSug.Size=New-Object Drawing.Size(1170,285); $detail.Controls.Add($grpSug)
    $lblSugTitulo=New-Object Windows.Forms.Label; $lblSugTitulo.Location=New-Object Drawing.Point(12,22); $lblSugTitulo.Size=New-Object Drawing.Size(1140,28); $lblSugTitulo.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $grpSug.Controls.Add($lblSugTitulo)
    $lblSugResumo=New-Object Windows.Forms.Label; $lblSugResumo.Location=New-Object Drawing.Point(12,51); $lblSugResumo.Size=New-Object Drawing.Size(1140,58); $grpSug.Controls.Add($lblSugResumo)
    $txtSugDetalhe=New-Object Windows.Forms.TextBox; $txtSugDetalhe.Location=New-Object Drawing.Point(12,112); $txtSugDetalhe.Size=New-Object Drawing.Size(1140,158); $txtSugDetalhe.Multiline=$true; $txtSugDetalhe.ReadOnly=$true; $txtSugDetalhe.ScrollBars="Vertical"; $txtSugDetalhe.BackColor=[Drawing.Color]::White; $grpSug.Controls.Add($txtSugDetalhe)

    $script:DetalhePlanejamentoId=0; $script:DetalheCarregando=$false
    $reposicionar={ param([bool]$fixa)
        $yOpt=if($fixa){134}else{34}; foreach($ed in @($ed1,$ed2,$ed3)){ $ed.Group.Top=$yOpt }
        $yDec=$yOpt+244; $lblAceita.Top=$yDec; $cmbAceita.Top=$yDec+20; $lblProtecao.Top=$yDec+18
        $lblJust.Top=$yDec+61; $txtJust.Top=$yDec+85; $grpSug.Top=$yDec+155
    }
    $setEditavel={ param([bool]$habilitar)
        foreach($ed in @($ed1,$ed2,$ed3)){ $ed.Tipo.Enabled=$habilitar; $ed.I1.Enabled=$habilitar; $ed.F1.Enabled=$habilitar; if($habilitar){Configure-OptionControls $ed}else{$ed.I2.Enabled=$false;$ed.F2.Enabled=$false}; $ed.FRI.Enabled=$habilitar;$ed.FRF.Enabled=$habilitar }
        $cmbAceita.Enabled=$habilitar; $txtJust.ReadOnly=(-not $habilitar); $btnSalvarTudo.Enabled=$habilitar
    }
    $montarCloneComTela={ param($r) $clone=($r|ConvertTo-Json -Depth 10|ConvertFrom-Json); $clone.opcao1=Read-OptionFromControls $ed1; $clone.opcao2=Read-OptionFromControls $ed2; $clone.opcao3=Read-OptionFromControls $ed3; $clone.opcao_aprovada=[int]$cmbAceita.SelectedIndex; return $clone }
    $atualizarSugestao={ param([bool]$usarTela)
        if([int]$script:DetalhePlanejamentoId -le 0){return}
        $r=$script:Records|Where-Object {[int]$_.id -eq [int]$script:DetalhePlanejamentoId}|Select-Object -First 1
        if($null -eq $r){return}
        $alvo=if($usarTela -and -not(Test-RegistroFeriasBloqueadas $r)){&$montarCloneComTela $r}else{$r}
        if(Test-RegistroFeriasBloqueadas $alvo){
            $sug=Get-SugestaoOpcaoRegistro $alvo
            $lblSugTitulo.Text="COMPROMISSO FIXO — NÃO ENTRA NA ESCOLHA DAS OPÇÕES"
            $lblSugTitulo.ForeColor=[Drawing.Color]::FromArgb(0,79,145)
            $lblSugResumo.Text=$sug.motivo
            $txtSugDetalhe.Text="Este período já ocupa capacidade do setor, do Grupo de Chefia e do limite institucional. O histórico de desempate não altera este compromisso."
            return
        }
        $avaliacoes=@()
        foreach($n in 1..3){ $avaliacoes += Get-AvaliacaoOpcaoRegistro $alvo $n }
        $validas=@($avaliacoes | Where-Object {[bool]$_.valida})
        if($validas.Count -eq 0){
            $lblSugTitulo.Text="SEM OPÇÃO VÁLIDA PARA RECOMENDAR"; $lblSugTitulo.ForeColor=[Drawing.Color]::DarkRed
            $lblSugResumo.Text="Preencha ou corrija pelo menos uma das três opções."
            $txtSugDetalhe.Text=(@($avaliacoes | ForEach-Object {"$($_.opcao)ª opção: $($_.nivel) — $($_.motivo)"}) -join "`r`n")
            return
        }
        $melhor=$validas | Sort-Object criticos,alertas_locais,alertas_institucionais,penal_sem_limite,historico_ocorrencias,opcao | Select-Object -First 1
        $lblSugTitulo.Text="RECOMENDAÇÃO: $($melhor.opcao)ª OPÇÃO — $($melhor.nivel)"
        switch([string]$melhor.nivel){
            "ADEQUADA" {$lblSugTitulo.ForeColor=[Drawing.Color]::DarkGreen}
            "ATENÇÃO" {$lblSugTitulo.ForeColor=[Drawing.Color]::DarkOrange}
            default {$lblSugTitulo.ForeColor=[Drawing.Color]::DarkRed}
        }

        # Explica em linguagem simples por que a opção venceu.
        $empatadas=@($validas | Where-Object {
            [int]$_.criticos -eq [int]$melhor.criticos -and
            [int]$_.alertas_locais -eq [int]$melhor.alertas_locais -and
            [int]$_.alertas_institucionais -eq [int]$melhor.alertas_institucionais -and
            [bool]$_.sem_limite_local -eq [bool]$melhor.sem_limite_local -and
            [bool]$_.sem_limite_chefia -eq [bool]$melhor.sem_limite_chefia
        })
        if([string]$melhor.motivo -eq "Sem conflito operacional identificado nas regras atuais."){
            $lblSugResumo.Text="Por que esta opção: não há conflito operacional. O histórico dos anos anteriores é usado somente para desempatar opções equivalentes."
        } elseif($empatadas.Count -gt 1 -and $melhor.opcao -eq ($empatadas | Sort-Object opcao | Select-Object -First 1).opcao){
            $lblSugResumo.Text="Por que esta opção: existem alertas, mas outras opções têm situação operacional equivalente. O sistema preservou a maior preferência possível do servidor depois de considerar o histórico."
        } else {
            $lblSugResumo.Text="Por que esta opção: entre as três alternativas, esta recebeu a melhor classificação após Setor/Período, Grupo de Chefia, referência institucional e histórico. Veja abaixo o motivo de cada mês."
        }

        $linhas=New-Object 'System.Collections.Generic.List[string]'
        foreach($a in $avaliacoes){
            $op=$alvo.("opcao$($a.opcao)")
            [void]$linhas.Add("$($a.opcao)ª OPÇÃO — $($a.nivel)")
            [void]$linhas.Add("Férias solicitadas: $(Format-OptionSummary $op)")

            if([string]$a.motivo -eq "Sem conflito operacional identificado nas regras atuais."){
                [void]$linhas.Add("Operacional: sem conflito identificado nas regras atuais.")
            } else {
                foreach($mot in ([string]$a.motivo -split '; ')){
                    if(-not [string]::IsNullOrWhiteSpace($mot)){ [void]$linhas.Add("Operacional: $mot") }
                }
            }

            $itensHist=@($a.historico_itens)
            if($itensHist.Count -eq 0){
                [void]$linhas.Add("Histórico: não há histórico importado suficiente para avaliar esta opção.")
            } else {
                foreach($hi in $itensHist){
                    $nomeMes=Get-NomeMesExtenso ([int]$hi.mes)
                    [void]$linhas.Add("Histórico para $nomeMes/$([int]$hi.ano) — prioridade: $([string]$hi.prioridade)")
                    foreach($ai in @($hi.anos)){
                        [void]$linhas.Add("   • $([string]$ai.texto)")
                    }
                    if([bool]$hi.disponivel){
                        $expPrior=if([string]$hi.prioridade -eq "ALTA"){"favorece esta opção no desempate, pois não repetiu o mês nos anos com dados"}elseif([string]$hi.prioridade -eq "MÉDIA"){"prioridade intermediária: houve 1 repetição do mesmo mês"}else{"menor prioridade histórica: o mesmo mês já apareceu mais vezes"}
                        [void]$linhas.Add("   Resultado: $([int]$hi.ocorrencias) ocorrência(s) no mesmo mês em $([int]$hi.cobertura) ano(s) com dados → prioridade histórica $([string]$hi.prioridade) ($expPrior).")
                    } else {
                        [void]$linhas.Add("   Resultado: cobertura insuficiente; o histórico não pesa contra nem a favor desta opção.")
                    }
                }
            }
            [void]$linhas.Add("")
        }
        [void]$linhas.Add("COMO O SISTEMA DECIDE")
        [void]$linhas.Add("1. Evita conflito real de datas no Setor/Período e no Grupo de Chefia.")
        [void]$linhas.Add("2. Considera a referência institucional mensal como ALERTA, não como bloqueio.")
        [void]$linhas.Add("3. Usa o histórico dos anos anteriores somente como desempate.")
        [void]$linhas.Add("4. Se continuar equivalente, preserva a 1ª opção antes da 2ª e da 3ª.")
        $txtSugDetalhe.Text=$linhas -join "`r`n"
    }
    $timerSug=New-Object Windows.Forms.Timer
    $timerSug.Interval=120
    $timerSug.add_Tick({
        $timerSug.Stop()
        if([int]$script:DetalhePlanejamentoId -gt 0){
            try {
                &$atualizarSugestao $false
            } catch {
                Write-DiagLog "Falha ao calcular análise/sugestão na Central de decisão (ID=$([int]$script:DetalhePlanejamentoId))." "ERROR" $_
                $lblSugTitulo.Text="NÃO FOI POSSÍVEL CALCULAR A SUGESTÃO"
                $lblSugTitulo.ForeColor=[Drawing.Color]::DarkRed
                $lblSugResumo.Text="A janela continua disponível. O erro foi registrado no log técnico."
                $txtSugDetalhe.Text=$_.Exception.Message
            }
        }
    })
    $carregarSelecionado={
        if($script:DetalheCarregando -or $g.SelectedRows.Count -eq 0){return}; $script:DetalheCarregando=$true
        try{
            $id=[int]$g.SelectedRows[0].Cells["rid"].Value; $r=$script:Records|Where-Object {[int]$_.id -eq $id}|Select-Object -First 1; if($null -eq $r){return}
            $script:DetalhePlanejamentoId=$id; $status=Get-StatusExibicaoRegistro $r; $lblSel.Text="$($r.nome) | Matrícula $($r.matricula) | $status | Período aquisitivo: $(Date-ToBR ([string]$r.aquisitivo_inicio)) a $(Date-ToBR ([string]$r.aquisitivo_fim))"
            Set-OptionControls $ed1 $r.opcao1; Set-OptionControls $ed2 $r.opcao2; Set-OptionControls $ed3 $r.opcao3
            foreach($nFR in 1..3){
                $opFR=$r.("opcao$nFR")
                $frResumo='FR 20 DIAS: não informada'
                if($opFR.fr_inicio -and $opFR.fr_fim){$frResumo='FR 20 DIAS: '+(Date-ToBR ([string]$opFR.fr_inicio))+' a '+(Date-ToBR ([string]$opFR.fr_fim))}
                $resumosFR[$nFR-1].Text=$frResumo
            }
            $n=[int]$r.opcao_aprovada; if($n -lt 0 -or $n -gt 3){$n=0}; $cmbAceita.SelectedIndex=$n; $txtJust.Text=[string]$r.justificativa_decisao
            $fixa=Test-RegistroFeriasBloqueadas $r; $grpFixo.Visible=$fixa; &$reposicionar $fixa; &$setEditavel (-not $fixa)
            if($fixa){
                $periodoFixo=if(Test-RegistroFixoImportado $r){Get-PeriodoFixoResumo $r}else{(Get-DescricaoBasePlanejamento $r)}
                $origem=if([bool]$r.fixo_ajustado){"AJUSTADA em $([string]$r.fixo_ajustado_em) por $([string]$r.fixo_ajustado_por)"}else{"PROGRAMAÇÃO ANTERIOR"}
                $lblFixo.Text="$(Get-RotuloEtapaFixa $r) — $status`r`nPeríodo protegido: $periodoFixo | Origem: $origem"
                $btnAlterarFixo.Enabled=(Test-RegistroFixoImportado $r)
                $lblProtecao.Text="🔒 As opções permanecem protegidas. Para corrigir a data fixa use o botão azul acima; será exigida confirmação, motivo e justificativa."
                $lblProtecao.ForeColor=[Drawing.Color]::DarkBlue
                if(-not [string]::IsNullOrWhiteSpace([string]$r.fixo_observacao_ajuste)){ $txtJust.Text=[string]$r.fixo_observacao_ajuste }
            }else{ $lblProtecao.Text="Edite as opções aqui. Aprovação e desfazimento: somente na Central de Aprovação."; $lblProtecao.ForeColor=[Drawing.Color]::Black }
            $pos=if($g.SelectedRows.Count -gt 0){$g.SelectedRows[0].Index+1}else{0}
            $lblContagem.Text="Registro $pos de $($g.Rows.Count)  |  Total nesta célula: $($g.Rows.Count)"
            $btnAnterior.Enabled=($pos -gt 1); $btnProximo.Enabled=($pos -gt 0 -and $pos -lt $g.Rows.Count)
            $lblSugTitulo.Text="ANALISANDO..."; $lblSugTitulo.ForeColor=[Drawing.Color]::DimGray
            $lblSugResumo.Text="A janela já está pronta para uso; a análise será carregada em seguida."
            $txtSugDetalhe.Text=""
            $timerSug.Stop(); $timerSug.Start()
        }finally{$script:DetalheCarregando=$false}
    }
    $g.add_SelectionChanged($carregarSelecionado)
    $btnAnterior.add_Click({ if($g.CurrentRow -and $g.CurrentRow.Index -gt 0){ $i=$g.CurrentRow.Index-1; $g.ClearSelection(); $g.Rows[$i].Selected=$true; $g.CurrentCell=$g.Rows[$i].Cells["mat"] } })
    $btnProximo.add_Click({ if($g.CurrentRow -and $g.CurrentRow.Index -lt ($g.Rows.Count-1)){ $i=$g.CurrentRow.Index+1; $g.ClearSelection(); $g.Rows[$i].Selected=$true; $g.CurrentCell=$g.Rows[$i].Cells["mat"] } })
    $btnAlterarFixo.add_Click({
        if([int]$script:DetalhePlanejamentoId -le 0){return}; $r=$script:Records|Where-Object {[int]$_.id -eq [int]$script:DetalhePlanejamentoId}|Select-Object -First 1; if($null -eq $r){return}
        if(Abrir-AjusteFeriasFixa $r $dlg){ Refresh-Grid; Refresh-Dashboard; Refresh-PlanejamentoSetor; Refresh-PeriodosGrid ([string]$r.matricula); &$carregarSelecionado }
    })
    $btnAnalisar.add_Click({if([int]$script:DetalhePlanejamentoId -le 0){[Windows.Forms.MessageBox]::Show("Selecione primeiro um servidor.","Análise")|Out-Null;return};&$atualizarSugestao $true})
    $btnSalvarTudo.add_Click({
        if([int]$script:DetalhePlanejamentoId -le 0){[Windows.Forms.MessageBox]::Show("Selecione primeiro um servidor.","Salvar")|Out-Null;return}
        $r=$script:Records|Where-Object {[int]$_.id -eq [int]$script:DetalhePlanejamentoId}|Select-Object -First 1; if($null -eq $r){return}; if(Test-RegistroFeriasBloqueadas $r){[Windows.Forms.MessageBox]::Show("Este período é fixo. Para ajustar a data, use 'Alterar período fixo...'.","Compromisso fixo")|Out-Null;return}
        $op1=Read-OptionFromControls $ed1; $op2=Read-OptionFromControls $ed2; $op3=Read-OptionFromControls $ed3
        foreach($par in @(@($op1,"1ª opção"),@($op2,"2ª opção"),@($op3,"3ª opção"))){if(-not[string]::IsNullOrWhiteSpace([string]$par[0].tipo)){$erro=Validate-Option $par[0] $par[1] ([string]$r.aquisitivo_fim);if($erro){[Windows.Forms.MessageBox]::Show($erro,"Validação",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null;return}}}
        $nova=[int]$r.opcao_aprovada
        if($nova -gt 0){
            $opAtual=$r.("opcao$nova")
            $opNovo=@($null,$op1,$op2,$op3)[$nova]
            if(((Get-OpcaoSomenteComum $opAtual)|ConvertTo-Json -Depth 10 -Compress) -ne ((Get-OpcaoSomenteComum $opNovo)|ConvertTo-Json -Depth 10 -Compress)){
                [Windows.Forms.MessageBox]::Show("Desfaça primeiro a aprovação na Central antes de alterar a opção aprovada.","Aprovação protegida")|Out-Null
                return
            }
        }
        $frAtual=Get-NumeroFRConfirmada $r
        if($frAtual -gt 0){
            $antigoFR=$r.("opcao$frAtual");$novoFR=@($null,$op1,$op2,$op3)[$frAtual]
            if(([string]$antigoFR.fr_inicio -ne [string]$novoFR.fr_inicio) -or ([string]$antigoFR.fr_fim -ne [string]$novoFR.fr_fim)){
                [Windows.Forms.MessageBox]::Show('Desfaça a aprovação FR antes de alterar suas datas.','FR protegida')|Out-Null;return
            }
        }
        if($nova -gt 0){$opAceita=@($null,$op1,$op2,$op3)[$nova];if($null -eq $opAceita -or [string]::IsNullOrWhiteSpace([string]$opAceita.tipo)){[Windows.Forms.MessageBox]::Show("A opção escolhida como aceita está vazia.","Validação")|Out-Null;return}}
        $texto=Get-OpcaoAceitaTexto $nova; $resp=[Windows.Forms.MessageBox]::Show("Salvar as alterações das opções de $($r.nome)?`n`nA aprovação atual ($texto) será preservada. Para aprovar ou desfazer, utilize a Central de Aprovação.","Confirmar alterações",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question);if($resp -ne[Windows.Forms.DialogResult]::Yes){return}
        $r.opcao1=$op1;$r.opcao2=$op2;$r.opcao3=$op3;$r.opcao_aprovada=$nova;$r.justificativa_decisao=$txtJust.Text.Trim();Save-Database
        if($g.SelectedRows.Count -gt 0){$g.SelectedRows[0].Cells["aceita"].Value=$texto;$g.SelectedRows[0].Cells["status"].Value=Get-StatusExibicaoRegistro $r;$g.SelectedRows[0].DefaultCellStyle.BackColor=Get-CorStatusRegistro $r}
        Refresh-Grid;Refresh-Dashboard;Refresh-PlanejamentoSetor;&$atualizarSugestao $false;[Windows.Forms.MessageBox]::Show("Opções atualizadas. A aprovação existente foi preservada. Novas aprovações somente pela Central.","Férias DCE")|Out-Null
    })
    $btnFechar.add_Click({$dlg.Close()})
    if($g.Rows.Count -gt 0){$g.Rows[0].Selected=$true;&$carregarSelecionado}
    [void]$dlg.ShowDialog($form)
}


function Format-AvaliacaoCentral($registro,[int]$numeroOpcao,$avaliacao){
    if($null -eq $registro -or $null -eq $avaliacao){ return "Sem dados para análise." }

    $nivel=([string]$avaliacao.nivel).Trim()
    $op=$registro.("opcao$numeroOpcao")
    $setor=([string]$registro.setor).Trim()
    $periodo=([string]$registro.periodo).Trim(); if(-not $periodo){$periodo="SEM PERÍODO"}
    $chefia=Get-GrupoChefiaEfetivaRegistro $registro
    $grupo=if($setor){Get-GrupoAnaliseSetor $setor}else{"NÃO INFORMADO"}

    $recomendacao=switch($nivel){
        "CRÍTICA" { "NÃO APROVAR sem revisar o conflito. Se houver decisão excepcional, a justificativa é obrigatória." }
        "ATENÇÃO" {
            if([bool]$avaliacao.sem_limite_local -or [bool]$avaliacao.sem_limite_chefia){
                "REVISAR antes de decidir. Há limite de capacidade não configurado; cadastre-o para obter uma avaliação completa."
            } else {
                "REVISAR antes de aprovar. Há alerta de capacidade ou referência institucional."
            }
        }
        "ADEQUADA" { "FAVORÁVEL pelas regras atualmente cadastradas. Ainda assim, confira Setor, Chefia e histórico." }
        "INVÁLIDA" { "NÃO UTILIZAR. A opção contém erro de datas ou regra aquisitiva." }
        "NÃO INFORMADA" { "A opção não foi preenchida." }
        default { "Revisar os dados apresentados abaixo." }
    }

    $linhas=New-Object 'System.Collections.Generic.List[string]'
    [void]$linhas.Add("STATUS DA OPÇÃO: $nivel")
    [void]$linhas.Add("RECOMENDAÇÃO: $recomendacao")
    [void]$linhas.Add("")
    [void]$linhas.Add("OPÇÃO ANALISADA")
    [void]$linhas.Add("• ${numeroOpcao}ª opção: $(Format-OptionSummary $op)")
    [void]$linhas.Add("• Setor: $(if($setor){$setor}else{'NÃO INFORMADO'})")
    [void]$linhas.Add("• Período: $periodo")
    [void]$linhas.Add("• Grupo de análise: $grupo")
    [void]$linhas.Add("• Grupo de Chefia: $(if($chefia){$chefia}else{'SEM CHEFIA VINCULADA'})")
    [void]$linhas.Add("")
    [void]$linhas.Add("IMPACTO OPERACIONAL")
    if(-not [bool]$avaliacao.valida){
        [void]$linhas.Add("• $([string]$avaliacao.motivo)")
    } else {
        [void]$linhas.Add("• Conflitos críticos: $([int]$avaliacao.criticos)")
        [void]$linhas.Add("• Alertas Setor/Chefia: $([int]$avaliacao.alertas_locais)")
        [void]$linhas.Add("• Alertas institucionais: $([int]$avaliacao.alertas_institucionais)")
        [void]$linhas.Add("• Limite Setor/Período: $(if([bool]$avaliacao.sem_limite_local){'NÃO CONFIGURADO'}else{'configurado'})")
        [void]$linhas.Add("• Limite da Chefia: $(if([bool]$avaliacao.sem_limite_chefia){'NÃO CONFIGURADO'}elseif($chefia){'configurado'}else{'não se aplica / sem chefia'})")
        $motivos=@(([string]$avaliacao.motivo) -split ';\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if($motivos.Count -gt 0){
            [void]$linhas.Add("")
            [void]$linhas.Add("DETALHES POR COMPETÊNCIA")
            foreach($m in $motivos){ [void]$linhas.Add("• $m") }
        }
    }

    [void]$linhas.Add("")
    [void]$linhas.Add("HISTÓRICO PARA DESEMPATE")
    if($null -ne $avaliacao.PSObject.Properties['historico_itens'] -and @($avaliacao.historico_itens).Count -gt 0){
        foreach($h in @($avaliacao.historico_itens)){
            [void]$linhas.Add("• $([string]$h.mes_rotulo) — prioridade: $([string]$h.prioridade) | ocorrência(s): $([int]$h.ocorrencias) | ano(s) com dados: $([int]$h.cobertura)")
            foreach($a in @($h.anos)){
                if(-not [bool]$a.tem_dados){
                    [void]$linhas.Add("   [—] $([int]$a.ano): histórico desse ano não foi importado")
                } elseif(-not [bool]$a.tem_servidor){
                    [void]$linhas.Add("   [—] $([int]$a.ano): servidor sem registro no histórico")
                } elseif([bool]$a.teve_mes){
                    $periodosTxt=if(@($a.periodos).Count -gt 0){" — "+(@($a.periodos) -join ", ")}else{""}
                    [void]$linhas.Add("   [X] $([int]$a.ano): teve férias no mesmo mês$periodosTxt")
                } else {
                    [void]$linhas.Add("   [OK] $([int]$a.ano): NÃO teve férias no mesmo mês")
                }
            }
        }
    } else {
        [void]$linhas.Add("• $([string]$avaliacao.historico)")
    }

    [void]$linhas.Add("")
    [void]$linhas.Add("LEITURA RÁPIDA: CRÍTICA = conflito real | ATENÇÃO = revisar | ADEQUADA = favorável pelas regras atuais.")
    return ($linhas -join "`r`n")
}


# ==========================================================================================
# CENTRAL DE APROVAÇÃO POR SERVIDOR - V1.0.54
# Visão operacional servidor a servidor, sem substituir a grade consolidada por Setor.
# Usa o MESMO motor de regras já existente para Setor/Período, Grupo de Chefia e Institucional.
# ==========================================================================================
function Abrir-CentralAprovacaoServidor {
    $centralAberturaCrono=[Diagnostics.Stopwatch]::StartNew()
    $dlg=New-Object Windows.Forms.Form
    Apply-AppBranding $dlg
    $dlg.Text="CENTRAL ÚNICA DE APROVAÇÃO | Férias DCE — V1.1.04 | CORR-R6"
    $dlg.Size=New-Object Drawing.Size(1420,820)
    $dlg.MinimumSize=New-Object Drawing.Size(1220,700)
    $dlg.StartPosition="CenterParent"
    $dlg.WindowState=[Windows.Forms.FormWindowState]::Maximized
    $dlg.Font=New-Object Drawing.Font("Segoe UI",9)

    $top=New-Object Windows.Forms.Panel
    $top.Dock="Top"

    $top.Height=205
    $top.BackColor=[Drawing.Color]::FromArgb(242,246,251)
    $dlg.Controls.Add($top)

    $titulo=New-Object Windows.Forms.Label
    $titulo.Text="CENTRAL ÚNICA DE APROVAÇÃO — FÉRIAS DCE | V1.1.04"
    $titulo.Location=New-Object Drawing.Point(15,8)
    $titulo.Size=New-Object Drawing.Size(520,24)
    $titulo.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold)
    $top.Controls.Add($titulo)

    $top.Controls.Add((New-Label "Pesquisar" 15 37 80))
    $txtBusca=New-TextBox 15 57 215
    $top.Controls.Add($txtBusca)

    $top.Controls.Add((New-Label "Situação" 240 37 80))
    $cmbStatus=New-Combo 240 57 150
    @("PENDENTES","TODOS","ACEITAS","FIXAS") | ForEach-Object {[void]$cmbStatus.Items.Add($_)}
    $cmbStatus.SelectedIndex=0
    $top.Controls.Add($cmbStatus)

    $top.Controls.Add((New-Label "Ano das férias" 400 37 95))
    $cmbAno=New-Combo 400 57 85
    @("2027","2028") | ForEach-Object {[void]$cmbAno.Items.Add($_)}
    $cmbAno.SelectedIndex=0
    $top.Controls.Add($cmbAno)

    $top.Controls.Add((New-Label "Mês" 495 37 50))
    $cmbMes=New-Combo 495 57 130
    @("TODOS","Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro") | ForEach-Object {[void]$cmbMes.Items.Add($_)}
    $cmbMes.SelectedIndex=0
    $top.Controls.Add($cmbMes)

    $btnAtualizar=New-Button "Atualizar" 640 54 100 31
    $top.Controls.Add($btnAtualizar)

    $lblAjuda=New-Object Windows.Forms.Label

    $lblAjuda.Text="DECISÃO CENTRALIZADA: confira férias fixas, priorize a 1ª opção e compare GERAL, SETOR, CHEFIA e HISTÓRICO antes de aprovar."
    $lblAjuda.Location=New-Object Drawing.Point(755,46)
    $lblAjuda.Size=New-Object Drawing.Size(620,48)
    $lblAjuda.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $lblAjuda.ForeColor=[Drawing.Color]::FromArgb(80,80,80)
    $top.Controls.Add($lblAjuda)

    # V1.0.53 — filtros operacionais solicitados: Setor, Grupo de análise, Grupo de Chefia e Período.
    $top.Controls.Add((New-Label "Setor" 15 92 80))
    $cmbSetor=New-Combo 15 112 230
    [void]$cmbSetor.Items.Add("TODOS")
    foreach($s in @($script:Records | ForEach-Object { ([string]$_.setor).Trim() } | Where-Object { $_ } | Sort-Object -Unique)){
        [void]$cmbSetor.Items.Add($s)
    }
    $cmbSetor.SelectedIndex=0
    $top.Controls.Add($cmbSetor)

    $top.Controls.Add((New-Label "Grupo de análise" 260 92 125))
    $cmbGrupoAnalise=New-Combo 260 112 200
    @("TODOS","ASSISTENCIAL","GERÊNCIA DE ENFERMAGEM","DIRETORIA DE ENFERMAGEM") | ForEach-Object {[void]$cmbGrupoAnalise.Items.Add($_)}
    $cmbGrupoAnalise.SelectedIndex=0
    $top.Controls.Add($cmbGrupoAnalise)

    $top.Controls.Add((New-Label "Grupo de Chefia" 475 92 125))
    $cmbChefia=New-Combo 475 112 220
    [void]$cmbChefia.Items.Add("TODOS")
    [void]$cmbChefia.Items.Add("SEM CHEFIA")
    foreach($g in (Get-GruposChefiaNomes)){ [void]$cmbChefia.Items.Add($g) }
    $cmbChefia.SelectedIndex=0
    $top.Controls.Add($cmbChefia)

    $top.Controls.Add((New-Label "Período" 710 92 80))
    $cmbPeriodo=New-Combo 710 112 160
    [void]$cmbPeriodo.Items.Add("TODOS")
    [void]$cmbPeriodo.Items.Add("SEM PERÍODO")
    foreach($p in @($script:Records | ForEach-Object { ([string]$_.periodo).Trim() } | Where-Object { $_ } | Sort-Object -Unique)){
        [void]$cmbPeriodo.Items.Add($p)
    }
    $cmbPeriodo.SelectedIndex=0
    $top.Controls.Add($cmbPeriodo)

    $btnLimparFiltros=New-Button "Limpar filtros" 885 109 115 31
    $top.Controls.Add($btnLimparFiltros)

    # V1.0.158: atalho para o mesmo relatório de aceites, sem duplicar cálculos.
    $btnAceitesCentral=New-Button "Relatório de aceites" 1010 109 184 31
    $btnAceitesCentral.BackColor=[Drawing.Color]::FromArgb(219,239,224)
    $top.Controls.Add($btnAceitesCentral)
    $btnAceitesCentral.add_Click({ Show-RelatorioAceitesEnfermagem })

    $lblFiltroInfo=New-Object Windows.Forms.Label
    $lblFiltroInfo.Text="Ano 2028: consulte também períodos que alcançam o ano seguinte."
    $lblFiltroInfo.Location=New-Object Drawing.Point(1202,108)
    $lblFiltroInfo.Size=New-Object Drawing.Size(173,40)
    $lblFiltroInfo.ForeColor=[Drawing.Color]::FromArgb(24,82,145)
    $top.Controls.Add($lblFiltroInfo)

    $gridInst=New-Object Windows.Forms.DataGridView
    $gridInst.Location=New-Object Drawing.Point(15,151)
    $gridInst.Size=New-Object Drawing.Size(1360,64)
    $gridInst.Anchor=[Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right
    $gridInst.ReadOnly=$true
    $gridInst.AllowUserToAddRows=$false
    $gridInst.RowHeadersVisible=$false
    $gridInst.ColumnHeadersVisible=$false
    $gridInst.AutoSizeColumnsMode="Fill"
    $gridInst.BackgroundColor=[Drawing.Color]::White
    $gridInst.RowTemplate.Height=54
    $gridInst.DefaultCellStyle.WrapMode=[Windows.Forms.DataGridViewTriState]::True
    $gridInst.DefaultCellStyle.Font=New-Object Drawing.Font('Segoe UI',8)
    foreach($m in 1..12){ [void]$gridInst.Columns.Add("m$m",(Get-NomeMesExtenso $m).Substring(0,3)) }
    [void]$gridInst.Rows.Add()
    $top.Controls.Add($gridInst)
    $gridInst.add_CellClick({
        param($sender,$e)
        if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $e.ColumnIndex -lt 12){
            try { Show-DetalhesFaixaInstitucional ([int][string]$cmbAno.SelectedItem) ([int]$e.ColumnIndex+1) }
            catch { Write-DiagLog ('Detalhe mensal Central: '+$_.Exception.Message) 'ERROR' }
        }
    })

    $split=New-Object Windows.Forms.SplitContainer
    $split.Dock="Fill"
    $split.Orientation="Vertical"
    $split.SplitterWidth=6
    $dlg.Controls.Add($split)
    $split.BringToFront()
    $split.add_SizeChanged({
        try {
            if($split.Width -gt 1100){
                $alvo=[int]([math]::Round($split.Width*0.56))
                if($alvo -lt 650){$alvo=650}
                if($alvo -gt ($split.Width-520)){$alvo=$split.Width-520}
                if($alvo -gt 0 -and $alvo -lt $split.Width){$split.SplitterDistance=$alvo}
            }
        } catch { Write-DiagLog ("Ajuste visual Central por Servidor ignorado: "+$_.Exception.Message) "WARN" }
    })

    # -------------------- LADO ESQUERDO: grade por servidor --------------------
    $grid=New-Object Windows.Forms.DataGridView
    $grid.Dock="Fill"
    $grid.ReadOnly=$true
    $grid.AllowUserToAddRows=$false
    $grid.RowHeadersVisible=$false
    $grid.SelectionMode="FullRowSelect"
    $grid.MultiSelect=$false
    $grid.BackgroundColor=[Drawing.Color]::White
    $grid.AutoSizeColumnsMode="None"
    $grid.EnableHeadersVisualStyles=$false
    [void]$grid.Columns.Add("id","ID")
    [void]$grid.Columns.Add("nome","Servidor")
    [void]$grid.Columns.Add("setor","Setor")
    [void]$grid.Columns.Add("periodo","Per.")
    [void]$grid.Columns.Add("aquisitivo","Período aquisitivo")
    [void]$grid.Columns.Add("status","Situação")
    foreach($m in 1..12){ [void]$grid.Columns.Add("mes$m",(Get-NomeMesExtenso $m).Substring(0,3)) }
    $grid.Columns["id"].Visible=$false
    $grid.Columns["id"].Frozen=$true

    $grid.Columns["nome"].Width=210
    $grid.Columns["nome"].Frozen=$true

    $grid.Columns["setor"].Width=140

    $grid.Columns["periodo"].Width=62

    $grid.Columns["aquisitivo"].Width=180

    $grid.Columns["status"].Width=108

    foreach($m in 1..12){ $grid.Columns["mes$m"].Width=50 }
    $split.Panel1.Controls.Add($grid)

    $lblQtd=New-Object Windows.Forms.Label
    $lblQtd.Dock="Bottom"
    $lblQtd.Height=30
    $lblQtd.Padding=New-Object Windows.Forms.Padding(8,7,0,0)
    $lblQtd.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $split.Panel1.Controls.Add($lblQtd)

    # -------------------- LADO DIREITO: decisão + impactos --------------------
    $right=New-Object Windows.Forms.Panel
    $right.Dock="Fill"
    $right.AutoScroll=$true
    $split.Panel2.Controls.Add($right)

    $grpServidor=New-Object Windows.Forms.GroupBox
    $grpServidor.Text="01  |  SERVIDOR E DIREITO AQUISITIVO"
    $grpServidor.Location=New-Object Drawing.Point(8,8)

    $grpServidor.Size=New-Object Drawing.Size(560,132)
    $grpServidor.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $right.Controls.Add($grpServidor)

    $lblServidor=New-Object Windows.Forms.Label

    $lblServidor.Location=New-Object Drawing.Point(12,22)
    $lblServidor.Size=New-Object Drawing.Size(530,58)
    $lblServidor.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblServidor.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $grpServidor.Controls.Add($lblServidor)

    $btnHistoricoRapido=New-Button "Histórico do servidor" 12 86 165 28
    $btnHistoricoRapido.BackColor=[Drawing.Color]::FromArgb(233,242,252)
    $grpServidor.Controls.Add($btnHistoricoRapido)
    $btnHistoricoRapido.Enabled=$false

    $btnConcorrentesRapido=New-Button "Concorrentes do mês" 186 86 165 28
    $btnConcorrentesRapido.BackColor=[Drawing.Color]::FromArgb(242,242,242)
    $grpServidor.Controls.Add($btnConcorrentesRapido)
    $btnConcorrentesRapido.Enabled=$false

    $lblAcessoInfo=New-Object Windows.Forms.Label
    $lblAcessoInfo.Location=New-Object Drawing.Point(360,90)
    $lblAcessoInfo.Size=New-Object Drawing.Size(182,22)
    $lblAcessoInfo.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right)
    $lblAcessoInfo.Text="Acesso rápido para histórico e concorrência"
    $lblAcessoInfo.ForeColor=[Drawing.Color]::FromArgb(90,90,90)
    $grpServidor.Controls.Add($lblAcessoInfo)

    $grpOp=New-Object Windows.Forms.GroupBox
    $grpOp.Text="02  |  ESCOLHA E DECISÃO — local exclusivo de aprovação"

        $grpOp.Location=New-Object Drawing.Point(8,146)
        $grpOp.Size=New-Object Drawing.Size(560,386)
    $grpOp.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $right.Controls.Add($grpOp)

    $lblO1=New-Object Windows.Forms.Label

    $lblO1.Location=New-Object Drawing.Point(12,22); $lblO1.Size=New-Object Drawing.Size(530,48); $lblO1.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $grpOp.Controls.Add($lblO1)
    $lblO2=New-Object Windows.Forms.Label
    $lblO2.Location=New-Object Drawing.Point(12,74); $lblO2.Size=New-Object Drawing.Size(530,48); $lblO2.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $grpOp.Controls.Add($lblO2)
    $lblO3=New-Object Windows.Forms.Label
    $lblO3.Location=New-Object Drawing.Point(12,126); $lblO3.Size=New-Object Drawing.Size(530,48); $lblO3.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $grpOp.Controls.Add($lblO3)

    # Cartoes de opcoes: realce visual, mantendo os labels usados pela logica existente.
    foreach($item in @(@($lblO1,0),@($lblO2,1),@($lblO3,2))){
        $l=$item[0]
        $l.BorderStyle=[Windows.Forms.BorderStyle]::FixedSingle
        $l.Padding=New-Object Windows.Forms.Padding(8,5,5,2)
        $l.BackColor=[Drawing.Color]::FromArgb(246,249,253)
        $l.ForeColor=[Drawing.Color]::FromArgb(35,57,83)
        $l.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Regular)
    }


        $grpOp.Controls.Add((New-Label "Opção em análise" 12 180 150))
    $cmbOpcao=New-Combo 12 200 140
    @("1ª opção","2ª opção","3ª opção") | ForEach-Object {[void]$cmbOpcao.Items.Add($_)}
    $cmbOpcao.SelectedIndex=0
    $grpOp.Controls.Add($cmbOpcao)


    $btnAprovar=New-Button "APROVAR ESTA OPÇÃO" 165 198 175 33
    $btnAprovar.BackColor=[Drawing.Color]::FromArgb(226,239,218)
    $btnAprovar.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $grpOp.Controls.Add($btnAprovar)


    $btnAprovarProx=New-Button "APROVAR E PRÓXIMO" 350 198 180 33
    $btnAprovarProx.BackColor=[Drawing.Color]::FromArgb(214,232,252)
    $btnAprovarProx.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $grpOp.Controls.Add($btnAprovarProx)

    # V1.0.94: desfazer decisao sem excluir a opcao ou alterar as ferias fixas.
    $btnDesfazerAprovacao=New-Button "DESFAZER APROVAÇÃO" 165 236 210 29
    $btnDesfazerAprovacao.BackColor=[Drawing.Color]::FromArgb(255,235,205)
    $grpOp.Controls.Add($btnDesfazerAprovacao)

    $lblJust=New-Object Windows.Forms.Label
    $lblJust.Text="Justificativa (necessária quando houver remanejamento ou conflito)"

        $lblJust.Location=New-Object Drawing.Point(12,266)
    $lblJust.Size=New-Object Drawing.Size(530,18)
    $grpOp.Controls.Add($lblJust)
    $txtJust=New-Object Windows.Forms.TextBox
        $txtJust.Location=New-Object Drawing.Point(12,286)
    $txtJust.Size=New-Object Drawing.Size(518,24)
    $txtJust.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $grpOp.Controls.Add($txtJust)
    $grpOp.Controls.Add((New-Label 'FR radiológicas — aprovação independente' 12 316 290 20))
    $cmbFR=New-Combo 12 339 140
    @('Não aprovada','1ª FR','2ª FR','3ª FR') | ForEach-Object {[void]$cmbFR.Items.Add($_)}
    $cmbFR.SelectedIndex=0; $grpOp.Controls.Add($cmbFR)
    $btnAprovarFR=New-Button 'APROVAR FR 20 DIAS' 165 337 185 32
    $btnAprovarFR.BackColor=[Drawing.Color]::FromArgb(223,238,255);$grpOp.Controls.Add($btnAprovarFR)
    $btnDesfazerFR=New-Button 'DESFAZER FR' 360 337 170 32
    $btnDesfazerFR.BackColor=[Drawing.Color]::FromArgb(255,238,215);$grpOp.Controls.Add($btnDesfazerFR)
    $tt=New-Object Windows.Forms.ToolTip
    $tt.SetToolTip($txtJust,"Justificativa da decisão. Obrigatória se a opção tiver conflito CRÍTICO.")

    $tabsImpacto=New-Object Windows.Forms.TabControl

    $tabsImpacto.Location=New-Object Drawing.Point(8,733)
    $tabsImpacto.Size=New-Object Drawing.Size(560,248)
    # Altura calculada pelo painel; Anchor Bottom com localização fixa fazia a caixa sair da janela.
    $tabsImpacto.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $right.Controls.Add($tabsImpacto)

    $tabSetor=New-Object Windows.Forms.TabPage
    $tabSetor.Text="Setor / períodos"
    $tabChefia=New-Object Windows.Forms.TabPage
    $tabChefia.Text="Linha de chefia"
    $tabAnalise=New-Object Windows.Forms.TabPage
    $tabAnalise.Text="Diagnóstico"
    $tabHistCentral=New-Object Windows.Forms.TabPage
    $tabHistCentral.Text="Histórico / desempate"
    $tabsImpacto.TabPages.AddRange(@($tabSetor,$tabChefia,$tabAnalise,$tabHistCentral))

    $lblHistCentral=New-Object Windows.Forms.Label
    $lblHistCentral.Location=New-Object Drawing.Point(8,8)
    $lblHistCentral.Size=New-Object Drawing.Size(535,36)
    $lblHistCentral.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $lblHistCentral.Text="Selecione um servidor e uma opção para consultar o histórico do mês em análise."
    $tabHistCentral.Controls.Add($lblHistCentral)

    $txtHistCentral=New-Object Windows.Forms.TextBox
    $txtHistCentral.Location=New-Object Drawing.Point(8,48)
    $txtHistCentral.Size=New-Object Drawing.Size(535,156)
    $txtHistCentral.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Bottom -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $txtHistCentral.Multiline=$true
    $txtHistCentral.ReadOnly=$true
    $txtHistCentral.ScrollBars='Vertical'
    $txtHistCentral.WordWrap=$true
    $tabHistCentral.Controls.Add($txtHistCentral)

    # Painel anual sob demanda: evita recalcular os 12 meses a cada clique na grade.
    $tabAnual=New-Object Windows.Forms.TabPage
    $tabAnual.Text="Comparativo 12 meses"
    $tabsImpacto.TabPages.Add($tabAnual)
    $btnCompararAno=New-Button "Atualizar comparativo mensal" 8 8 245 30
    $tabAnual.Controls.Add($btnCompararAno)
    $lblCompInfo=New-Object Windows.Forms.Label
    $lblCompInfo.Location=New-Object Drawing.Point(265,12)
    $lblCompInfo.Size=New-Object Drawing.Size(280,25)
    $lblCompInfo.Text="Contagens equivalentes | setor e chefia: consulta"
    $tabAnual.Controls.Add($lblCompInfo)
    $gridComparativo=New-Object Windows.Forms.DataGridView
    $gridComparativo.Location=New-Object Drawing.Point(8,45)
    $gridComparativo.Size=New-Object Drawing.Size(535,172)
    $gridComparativo.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Bottom -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $gridComparativo.ReadOnly=$true
    $gridComparativo.AllowUserToAddRows=$false
    $gridComparativo.RowHeadersVisible=$false
    $gridComparativo.SelectionMode="FullRowSelect"
    $gridComparativo.AutoSizeColumnsMode="Fill"
    foreach($col in @(@("mes","Mês"),@("atual","Geral atual"),@("depois","Geral após"),@("limite","Limite"),@("setor","Setor após"),@("chefia","Chefia após"),@("situacao","Situação"))){[void]$gridComparativo.Columns.Add($col[0],$col[1])}
    Apply-ProfessionalGridStyle $gridComparativo
    $tabAnual.Controls.Add($gridComparativo)


    $panelComp=New-Object Windows.Forms.Panel
    $panelComp.Dock="Top"; $panelComp.Height=42
    $tabSetor.Controls.Add($panelComp)
    $panelComp.Controls.Add((New-Label "Competência analisada" 8 7 145))
    $cmbCompetencia=New-Combo 155 5 150
    $panelComp.Controls.Add($cmbCompetencia)

    $gridSetor=New-Object Windows.Forms.DataGridView
    $gridSetor.Dock="Fill"
    $gridSetor.ReadOnly=$true
    $gridSetor.AllowUserToAddRows=$false
    $gridSetor.RowHeadersVisible=$false
    $gridSetor.AutoSizeColumnsMode="Fill"
    $gridSetor.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(@("per","Período"),@("atual","Atual"),@("apos","Com opção"),@("lim","Limite"),@("pico","Pico"),@("sit","Situação"))){[void]$gridSetor.Columns.Add($c[0],$c[1])}
    $tabSetor.Controls.Add($gridSetor)
    $gridSetor.BringToFront()

    $panelCompChef=New-Object Windows.Forms.Panel
    $panelCompChef.Dock="Top"; $panelCompChef.Height=42
    $tabChefia.Controls.Add($panelCompChef)
    $lblChefiaNome=New-Object Windows.Forms.Label
    $lblChefiaNome.Location=New-Object Drawing.Point(8,9); $lblChefiaNome.Size=New-Object Drawing.Size(520,24)
    $lblChefiaNome.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $panelCompChef.Controls.Add($lblChefiaNome)

    $gridChefia=New-Object Windows.Forms.DataGridView
    $gridChefia.Dock="Fill"
    $gridChefia.ReadOnly=$true
    $gridChefia.AllowUserToAddRows=$false
    $gridChefia.RowHeadersVisible=$false
    $gridChefia.AutoSizeColumnsMode="Fill"
    $gridChefia.BackgroundColor=[Drawing.Color]::White
    foreach($c in @(@("setor","Setor vinculado"),@("per","Período"),@("atual","Atual"),@("apos","Com opção"),@("lim","Limite"),@("pico","Pico"),@("sit","Situação"))){[void]$gridChefia.Columns.Add($c[0],$c[1])}
    $tabChefia.Controls.Add($gridChefia)
    $gridChefia.BringToFront()

    # V1.0.53: layout em duas linhas evita o cabeçalho encobrir as primeiras linhas da análise.
    $layoutAnalise=New-Object Windows.Forms.TableLayoutPanel
    $layoutAnalise.Dock="Fill"
    $layoutAnalise.ColumnCount=1; $layoutAnalise.RowCount=2
    [void]$layoutAnalise.ColumnStyles.Add(([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent,100)))
    [void]$layoutAnalise.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,68)))
    [void]$layoutAnalise.RowStyles.Add(([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent,100)))
    $tabAnalise.Controls.Add($layoutAnalise)

    $lblAnaliseStatus=New-Object Windows.Forms.Label
    $lblAnaliseStatus.Dock="Fill"
    $lblAnaliseStatus.Padding=New-Object Windows.Forms.Padding(10,8,10,6)
    $lblAnaliseStatus.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
    $lblAnaliseStatus.Text="Selecione uma opção para análise."
    $lblAnaliseStatus.BackColor=[Drawing.Color]::Gainsboro
    $lblAnaliseStatus.TextAlign=[Drawing.ContentAlignment]::MiddleLeft
    $layoutAnalise.Controls.Add($lblAnaliseStatus,0,0)

    $txtAnalise=New-Object Windows.Forms.TextBox
    $txtAnalise.Dock="Fill"
    $txtAnalise.Multiline=$true
    $txtAnalise.ReadOnly=$true
    $txtAnalise.ScrollBars="Vertical"
    $txtAnalise.WordWrap=$true
    $txtAnalise.BackColor=[Drawing.Color]::White
    $txtAnalise.Font=New-Object Drawing.Font("Segoe UI",9)
    $layoutAnalise.Controls.Add($txtAnalise,0,1)

    $grpSimulacao=New-Object Windows.Forms.GroupBox
    $grpSimulacao.Text="03  |  SIMULAÇÃO E CAPACIDADE"
    $grpSimulacao.Location=New-Object Drawing.Point(8,540)
    $grpSimulacao.Size=New-Object Drawing.Size(560,180)
    $grpSimulacao.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $right.Controls.Add($grpSimulacao)

    $lblInstitucional=New-Object Windows.Forms.Label
    $lblInstitucional.Location=New-Object Drawing.Point(12,21)
    $lblInstitucional.Size=New-Object Drawing.Size(530,18)
    $lblInstitucional.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblInstitucional.Text="Selecione uma opção para simular o impacto na competência."
    $lblInstitucional.ForeColor=[Drawing.Color]::FromArgb(55,55,55)
    $lblInstitucional.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $grpSimulacao.Controls.Add($lblInstitucional)

    $lblLinhaGeral=New-Object Windows.Forms.Label
    $lblLinhaGeral.Location=New-Object Drawing.Point(12,44)
    $lblLinhaGeral.Size=New-Object Drawing.Size(530,52)
    $lblLinhaGeral.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblLinhaGeral.BorderStyle='FixedSingle'
    $lblLinhaGeral.Padding=New-Object Windows.Forms.Padding(8,4,8,4)
    $grpSimulacao.Controls.Add($lblLinhaGeral)

    $lblLinhaSetor=New-Object Windows.Forms.Label
    $lblLinhaSetor.Location=New-Object Drawing.Point(12,100)
    $lblLinhaSetor.Size=New-Object Drawing.Size(530,24)
    $lblLinhaSetor.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblLinhaSetor.BorderStyle='FixedSingle'
    $lblLinhaSetor.Padding=New-Object Windows.Forms.Padding(8,4,8,4)
    $grpSimulacao.Controls.Add($lblLinhaSetor)

    $lblLinhaChefia=New-Object Windows.Forms.Label
    $lblLinhaChefia.Location=New-Object Drawing.Point(12,127)
    $lblLinhaChefia.Size=New-Object Drawing.Size(530,24)
    $lblLinhaChefia.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblLinhaChefia.BorderStyle='FixedSingle'
    $lblLinhaChefia.Padding=New-Object Windows.Forms.Padding(8,4,8,4)
    $grpSimulacao.Controls.Add($lblLinhaChefia)

    $lblSimulacaoAjuda=New-Object Windows.Forms.Label
    $lblSimulacaoAjuda.Location=New-Object Drawing.Point(12,154)
    $lblSimulacaoAjuda.Size=New-Object Drawing.Size(530,16)
    $lblSimulacaoAjuda.Anchor=([Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left -bor [Windows.Forms.AnchorStyles]::Right)
    $lblSimulacaoAjuda.Text='Δ = acréscimo real no mês. Setor e chefia: indicadores de apoio. Histórico e concorrência disponíveis acima.'
    $lblSimulacaoAjuda.ForeColor=[Drawing.Color]::FromArgb(65,87,111)
    $lblSimulacaoAjuda.Font=New-Object Drawing.Font('Segoe UI',8)
    $grpSimulacao.Controls.Add($lblSimulacaoAjuda)

    # V1.0.90: adequar a aba inferior a altura efetiva, inclusive com DPI ampliado.
    # Se nao couber, o painel passa a rolar, sem esconder botoes ou cortar a grade.
    $ajustarCentralDireita={
        if($null -eq $right -or $right.IsDisposed){return}
        $largura=[math]::Max(380,$right.ClientSize.Width-24)
        foreach($controle in @($grpServidor,$grpOp,$grpSimulacao,$tabsImpacto)){
            if($null -ne $controle){ $controle.Width=$largura }
        }
        $hDisponivel=$right.ClientSize.Height-$tabsImpacto.Top-14
        if($hDisponivel -ge 175){
            $tabsImpacto.Height=$hDisponivel
            $right.AutoScrollMinSize=New-Object Drawing.Size(0,0)
        }else{
            $tabsImpacto.Height=220
            $right.AutoScrollMinSize=New-Object Drawing.Size(0,($tabsImpacto.Bottom+16))
        }
    }
    $right.add_SizeChanged({ &$ajustarCentralDireita })
    $dlg.add_Shown({
        &$ajustarCentralDireita
        $centralAberturaCrono.Stop()
        Write-DiagLog "CENTRAL CORR-R6: montagem=$($centralAberturaCrono.ElapsedMilliseconds)ms" 'INFO'
    })

    Apply-ProfessionalGridStyle $grid
    Apply-ProfessionalGridStyle $gridInst
    Apply-ProfessionalGridStyle $gridSetor
    Apply-ProfessionalGridStyle $gridChefia

    $centralUiState=@{SuppressEvents=$false; Stamp=""; FaixaKey=""; SuppressOptionEvent=$false; SuppressCompetenciaEvent=$false}
    $tmrCentralGrid=New-Object Windows.Forms.Timer
    $tmrCentralGrid.Interval=180
    $tmrCentralGrid.add_Tick({
        $tmrCentralGrid.Stop()
        if(-not $centralUiState.SuppressEvents){ &$refreshGrid }
    })
    $tmrCentralSelecao=New-Object Windows.Forms.Timer
    $tmrCentralSelecao.Interval=120
    $tmrCentralSelecao.add_Tick({
        $tmrCentralSelecao.Stop()
        if(-not $centralUiState.SuppressEvents){ &$carregarSelecionado }
    })
    $requestCentralGrid={
        if($centralUiState.SuppressEvents){ return }
        $tmrCentralGrid.Stop(); $tmrCentralGrid.Start()
    }
    $requestCentralSelecao={
        if($centralUiState.SuppressEvents){ return }
        $tmrCentralSelecao.Stop(); $tmrCentralSelecao.Start()
    }

    $setLinhaPainel={
        param($lbl,[string]$texto,[string]$situacao)
        if($null -eq $lbl){ return }
        $lbl.Text=$texto
        switch -Regex (([string]$situacao).ToUpperInvariant()){
            'CR[IÍ]TICO|ACIMA|ALERTA' { $lbl.BackColor=[Drawing.Color]::MistyRose; $lbl.ForeColor=[Drawing.Color]::DarkRed }
            'NO LIMITE|ATEN[CÇ][AÃ]O' { $lbl.BackColor=[Drawing.Color]::FromArgb(255,244,204); $lbl.ForeColor=[Drawing.Color]::FromArgb(120,76,0) }
            'OK' { $lbl.BackColor=[Drawing.Color]::FromArgb(226,239,218); $lbl.ForeColor=[Drawing.Color]::FromArgb(24,90,50) }
            'INFORMATIVO|SEM LIMITE|N[ÃA]O VINCULADA' { $lbl.BackColor=[Drawing.Color]::FromArgb(233,242,252); $lbl.ForeColor=[Drawing.Color]::FromArgb(26,73,118) }
            default { $lbl.BackColor=[Drawing.Color]::FromArgb(245,248,252); $lbl.ForeColor=[Drawing.Color]::FromArgb(45,45,45) }
        }
    }
    $resetPainelSimulacao={
        param([string]$titulo='Selecione uma opção para simular o impacto na competência.',[string]$nota='Δ = acréscimo real no mês. Setor e chefia: indicadores de apoio. Histórico e concorrência disponíveis acima.')
        $lblInstitucional.Text=$titulo
        &$setLinhaPainel $lblLinhaGeral 'GERAL: —' 'INFO'
        &$setLinhaPainel $lblLinhaSetor 'SETOR: —' 'INFO'
        &$setLinhaPainel $lblLinhaChefia 'CHEFIA: —' 'INFO'
        $lblSimulacaoAjuda.Text=$nota
    }
    $refreshHistoricoCentral={
        if($null -eq $txtHistCentral){ return }
        $txtHistCentral.Text=''
        $lblHistCentral.Text='Selecione um servidor e uma opção para consultar o histórico do mês em análise.'
        if([int]$script:CentralServidorCurrentId -le 0){ return }
        $r=@($script:Records | Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId} | Select-Object -First 1)
        if($r.Count -eq 0){ return }
        $r=$r[0]
        $ano=[int][string]$cmbAno.SelectedItem
        $n=[int]$cmbOpcao.SelectedIndex+1
        $op=$r."opcao$n"
        if($null -eq $op -or -not ([string]$op.tipo).Trim()){
            $lblHistCentral.Text='Histórico / desempate — opção sem datas para análise.'
            return
        }
        $meses=@(Get-MesesOpcaoObjeto $op $ano)
        if($meses.Count -eq 0){ $lblHistCentral.Text='Histórico / desempate — a opção não alcança o ano filtrado.'; return }
        $mesAlvo=[int]$meses[0]
        if($null -ne $cmbCompetencia.SelectedItem -and ([string]$cmbCompetencia.SelectedItem) -match '^(\d{4})-(\d{2})$'){
            $mesAlvo=[int]$Matches[2]
        }
        $info=Get-HistoricoDesempateInfo $r $mesAlvo $ano
        $nomeMes=Get-NomeMesExtenso $mesAlvo
        $lblHistCentral.Text="Histórico / desempate — $nomeMes/$ano"
        $linhas=New-Object 'System.Collections.Generic.List[string]'
        [void]$linhas.Add("Servidor: $($r.nome) | Matrícula: $($r.matricula)")
        [void]$linhas.Add("Setor: $([string]$r.setor) | Período: $([string]$r.periodo) | Chefia: $(if((Get-GrupoChefiaEfetivaRegistro $r)){Get-GrupoChefiaEfetivaRegistro $r}else{'não vinculada'})")
        [void]$linhas.Add("")
        if($info.disponivel){
            [void]$linhas.Add("Prioridade histórica: $($info.prioridade) | Ocorrências no mês-alvo: $($info.ocorrencias) | Cobertura: $($info.cobertura) ano(s)")
        } else {
            [void]$linhas.Add("Histórico: $($info.prioridade) | $($info.detalhe)")
        }
        foreach($a in @($info.anos)){
            [void]$linhas.Add("- $($a.texto)")
        }
        $histRows=@($script:HistoricoFerias | Where-Object { ([string]$_.matricula).Trim() -eq ([string]$r.matricula).Trim() } | Sort-Object inicio -Descending | Select-Object -First 8)
        if($histRows.Count -gt 0){
            [void]$linhas.Add('')
            [void]$linhas.Add('Últimos registros históricos importados:')
            foreach($h in $histRows){
                $ii=Date-ToBR ([string]$h.inicio); $ff=Date-ToBR ([string]$h.fim)
                $aqi=Date-ToBR ([string]$h.aquisitivo_inicio); $aqf=Date-ToBR ([string]$h.aquisitivo_fim)
                [void]$linhas.Add(("• {0}: {1} a {2} | {3} dia(s) | aquisitivo {4} a {5}" -f ([string]$h.ano),$ii,$ff,[int]$h.dias,$aqi,$aqf))
            }
        }
        $txtHistCentral.Text=($linhas -join [Environment]::NewLine)
    }
    $abrirHistoricoRapido={
        &$refreshHistoricoCentral
        $dlgH=New-Object Windows.Forms.Form
        Apply-AppBranding $dlgH
        $dlgH.Text='Histórico do servidor — Férias DCE'
        $dlgH.Size=New-Object Drawing.Size(860,620)
        $dlgH.StartPosition='CenterParent'
        $dlgH.Font=New-Object Drawing.Font('Segoe UI',9)
        $txt=New-Object Windows.Forms.TextBox
        $txt.Dock='Fill'; $txt.Multiline=$true; $txt.ReadOnly=$true; $txt.ScrollBars='Vertical'; $txt.WordWrap=$true
        $txt.Font=New-Object Drawing.Font('Consolas',10)
        $txt.Text=$txtHistCentral.Text
        $dlgH.Controls.Add($txt)
        [void]$dlgH.ShowDialog($dlg)
    }
    $abrirConcorrentesRapido={
        if([int]$script:CentralServidorCurrentId -le 0){ return }
        $registro=@($script:Records|Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId}|Select-Object -First 1)
        if($registro.Count -eq 0){ return }
        $r=$registro[0]
        $ano=[int][string]$cmbAno.SelectedItem
        $n=[int]$cmbOpcao.SelectedIndex+1
        $op=$r."opcao$n"
        $meses=@(Get-MesesOpcaoObjeto $op $ano)
        if($meses.Count -eq 0){ [Windows.Forms.MessageBox]::Show('A opção selecionada não possui mês válido no ano filtrado.','Férias DCE',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null; return }
        $mesAlvo=[int]$meses[0]
        if($null -ne $cmbCompetencia.SelectedItem -and ([string]$cmbCompetencia.SelectedItem) -match '^(\d{4})-(\d{2})$'){ $mesAlvo=[int]$Matches[2] }
        $dlgC=New-Object Windows.Forms.Form
        Apply-AppBranding $dlgC
        $dlgC.Text="Concorrentes do mês — $(Get-NomeMesExtenso $mesAlvo)/$ano"
        $dlgC.Size=New-Object Drawing.Size(980,620)
        $dlgC.StartPosition='CenterParent'
        $dlgC.Font=New-Object Drawing.Font('Segoe UI',9)
        $gridC=New-Object Windows.Forms.DataGridView
        $gridC.Dock='Fill'; $gridC.ReadOnly=$true; $gridC.AllowUserToAddRows=$false; $gridC.RowHeadersVisible=$false; $gridC.AutoSizeColumnsMode='Fill'; $gridC.SelectionMode='FullRowSelect'
        foreach($c in @(@('nome','Servidor'),@('setor','Setor'),@('periodo','Período'),@('chefia','Chefia'),@('situacao','Situação'),@('historico','Prioridade histórica'))){ [void]$gridC.Columns.Add($c[0],$c[1]) }
        Apply-ProfessionalGridStyle $gridC
        $dlgC.Controls.Add($gridC)
        foreach($row in @($grid.Rows)){
            try{ $idRow=[int]$row.Cells['id'].Value }catch{ continue }
            if($idRow -le 0 -or $idRow -eq [int]$r.id){ continue }
            $rr=@($script:Records | Where-Object {[int]$_.id -eq $idRow} | Select-Object -First 1)
            if($rr.Count -eq 0){ continue }
            $rr=$rr[0]
            $mesesReg=@(Get-MesesSolicitacoesRegistro $rr $ano)
            if($mesesReg -notcontains $mesAlvo){ continue }
            $info=Get-HistoricoDesempateInfo $rr $mesAlvo $ano
            [void]$gridC.Rows.Add([string]$rr.nome,[string]$rr.setor,[string]$rr.periodo,$(if((Get-GrupoChefiaEfetivaRegistro $rr)){Get-GrupoChefiaEfetivaRegistro $rr}else{'não vinculada'}),(Get-StatusExibicaoRegistro $rr),$info.prioridade)
        }
        [void]$dlgC.ShowDialog($dlg)
    }
    $script:CentralUltimoRenderId=0
    $script:CentralForcarRender=$false

    $script:CentralServidorCurrentId=0

    $getPeriodos={
        $p=@()
        $p += @($script:Config.periodos)
        $p += @($script:Records | ForEach-Object {
            $x=([string]$_.periodo).Trim()
            if([string]::IsNullOrWhiteSpace($x)){"SEM PERÍODO"}else{$x}
        })
        return @($p | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Sort-Object -Unique)
    }

    # V1.0.135-R2: Cache efemero da CENTRAL para filtros repetidos.
    # Dependencia: hash da base, numero de registros, ano e id.
    # Nunca serializar esse cache nem reutilizar apos gravacao.
    $centralUiState.Stamp=''
    $centralCacheAnoMes=@{}
    $centralCacheMarcas=@{}
    $centralUiState.FaixaKey=''
    $refreshInstitucional={
        $ano=[int][string]$cmbAno.SelectedItem
        # Filtros/seleção não modificam a faixa institucional. Evita 12 recálculos
        # em cada pesquisa; Save-Database altera LoadedDbHash após decisões.
        $keyFaixa="$ano|$([string]$script:LoadedDbHash)|$(@($script:Records).Count)|$([int]$script:Config.total_enfermeiros_planejamento)|$([string]($script:Config.meses_restritos -join ","))|$([string]($script:Config.limites_especiais_mensais | ConvertTo-Json -Compress))"
        if($centralUiState.FaixaKey -eq $keyFaixa){ return }
        $row=$gridInst.Rows[0]
        $institucionalPronto=Get-PlanejamentoInstitucionalPronto $ano
        for($m=1;$m -le 12;$m++){
            $det=if($null -ne $institucionalPronto){$institucionalPronto.Meses[$m].detalhes}else{Get-FaixaInstitucionalDetalhes $ano $m $false}
            # Valores distintos: aprovado (real) nao inclui primeira opcao pendente.
            # Projecao mantem o criterio de decisao usado pela Central.
            $real=if($null -ne $institucionalPronto){[double]$institucionalPronto.Meses[$m].real}else{[double](Get-ContagemInstitucionalAprovadaMes $ano $m)}
            $projecao=[double]$det.total
            $limite=[double]$det.limite
            $saldoReal=$limite-$real
            $formatReal=Format-NumeroBR $real
            $formatProj=Format-NumeroBR $projecao
            $formatLim=Format-NumeroBR $limite
            $formatSaldo=Format-NumeroBR $saldoReal
            $sigla=(Get-NomeMesExtenso $m).Substring(0,3)
            # V1.0.159: capacidade CONFIRMADA em destaque; pendencias somente no tooltip.
            $row.Cells["m$m"].Value="$sigla  LIM:$formatLim`r`nCONF:$formatReal  SAL:$formatSaldo"
            $pendente=[math]::Max(0.0,($projecao-$real))
            $formatPend=Format-NumeroBR $pendente
            $row.Cells["m$m"].ToolTipText="LIMITE institucional: $formatLim`r`nCONFIRMADO (fixas + aprovadas): $formatReal`r`nSALDO REAL (limite - confirmado): $formatSaldo`r`n`r`nINFORMACAO COMPLEMENTAR:`r`nPENDENCIAS PROJETADAS: $formatPend`r`nPROJECAO TOTAL: $formatProj`r`n`r`n$($det.tooltip)"
            $row.Cells["m$m"].Style.WrapMode=[Windows.Forms.DataGridViewTriState]::True
            # A cor representa a ocupacao confirmada, nao a solicitacao pendente.
            if($limite -le 0){$cor=[Drawing.Color]::White}
            elseif($real -gt $limite + 0.000001){$cor=[Drawing.Color]::MistyRose}
            elseif($real -ge $limite - 0.000001){$cor=[Drawing.Color]::FromArgb(255,244,204)}
            elseif($real -gt 0){$cor=[Drawing.Color]::FromArgb(226,239,218)}
            else{$cor=[Drawing.Color]::White}
            $row.Cells["m$m"].Style.BackColor=$cor
        }
        $centralUiState.FaixaKey=$keyFaixa
    }

    # V1.0.135-R2: prepara uma vez as 12 marcas mensais de cada registro.
    # Antes a grade reconstruia os mesmos blocos ate 12 vezes por registro.
    $getMesCellsFast={
        param($r,[int]$ano)
        $marks=New-Object 'string[]' 13
        if(Test-RegistroFeriasBloqueadas $r){
            foreach($m in @(Get-MesesPlanejamentoRegistro $r $ano)){
                $mi=[int]$m; if($mi -ge 1 -and $mi -le 12){$marks[$mi]='FIXA'}
            }
            return ,$marks
        }
        $parts=New-Object 'System.Collections.Generic.List[string][]' 13
        for($k=1;$k -le 12;$k++){$parts[$k]=New-Object 'System.Collections.Generic.List[string]'}
        $nc=Get-NumeroComumConfirmada $r
        $nf=Get-NumeroFRConfirmada $r
        foreach($n in 1..3){
            if($nc -eq 0 -or $n -eq $nc){
                $label='C'+$n+$(if($nc -eq $n){'✓'}else{''})
                foreach($m in @(Get-MesesBlocosAno (Get-BlocosComunsOpcao $r $n) $ano)){
                    $mi=[int]$m; if($mi -ge 1 -and $mi -le 12 -and -not $parts[$mi].Contains($label)){$parts[$mi].Add($label)}
                }
            }
            if($nf -eq 0 -or $n -eq $nf){
                $label='FR'+$n+$(if($nf -eq $n){'✓'}else{''})
                foreach($m in @(Get-MesesBlocosAno (Get-BlocoFROpcao $r $n) $ano)){
                    $mi=[int]$m; if($mi -ge 1 -and $mi -le 12 -and -not $parts[$mi].Contains($label)){$parts[$mi].Add($label)}
                }
            }
        }
        for($k=1;$k -le 12;$k++){$marks[$k]=[string]::Join('/', $parts[$k].ToArray())}
        return ,$marks
    }

    $refreshGrid={
        $centralGridCrono=[Diagnostics.Stopwatch]::StartNew()
        $idAntes=[int]$script:CentralServidorCurrentId
        # Invalida imediatamente depois de gravacao, sincronizacao ou troca da base.
        $stamp="$( [string]$script:LoadedDbHash )|$(@($script:Records).Count)|$([string]$script:Config.total_enfermeiros_planejamento)|$([Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($script:Records))"
        if($centralUiState.Stamp -ne $stamp){
            $centralCacheAnoMes.Clear()
            $centralCacheMarcas.Clear()
            $centralUiState.Stamp=$stamp
        }
        $centralUiState.SuppressEvents=$true
        $grid.SuspendLayout()
        try {
            $grid.Rows.Clear()
            $ano=[int][string]$cmbAno.SelectedItem
        $mesFoco=[int]$cmbMes.SelectedIndex
        $busca=([string]$txtBusca.Text).Trim().ToUpperInvariant()
        $statusFiltro=[string]$cmbStatus.SelectedItem
        $setorFiltro=if($null -ne $cmbSetor.SelectedItem){[string]$cmbSetor.SelectedItem}else{"TODOS"}
        $grupoFiltro=if($null -ne $cmbGrupoAnalise.SelectedItem){[string]$cmbGrupoAnalise.SelectedItem}else{"TODOS"}
        $chefiaFiltro=if($null -ne $cmbChefia.SelectedItem){[string]$cmbChefia.SelectedItem}else{"TODOS"}
        $periodoFiltro=if($null -ne $cmbPeriodo.SelectedItem){[string]$cmbPeriodo.SelectedItem}else{"TODOS"}

        $fonteFixa=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
        # Ordenacao cacheada entre pesquisas, invalidada pela assinatura da base.
        $fonteStamp="$($script:LoadedDbHash)|$(@($script:Records).Count)|$([Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($script:Records))"
        if($null -eq $script:CentralFonteOrdenada -or $script:CentralFonteStamp -ne $fonteStamp){
            $script:CentralFonteOrdenada=@($script:Records | Sort-Object nome,aquisitivo_inicio)
            $script:CentralFonteStamp=$fonteStamp
        }
        foreach($r in $script:CentralFonteOrdenada){
            $status=Get-StatusExibicaoRegistro $r
            if($statusFiltro -eq "PENDENTES" -and $status -ne "PENDENTE"){continue}
            if($statusFiltro -eq "ACEITAS" -and $status -ne "ACEITA"){continue}
            if($statusFiltro -eq "FIXAS" -and $status -notlike "FIXA*"){continue}

            $setorR=([string]$r.setor).Trim()
            $periodoR=([string]$r.periodo).Trim()
            if([string]::IsNullOrWhiteSpace($periodoR)){ $periodoR="SEM PERÍODO" }
            $grupoR=if($setorR){Get-GrupoAnaliseSetor $setorR}else{""}
            $chefiaR=Get-GrupoChefiaEfetivaRegistro $r

            if($setorFiltro -ne "TODOS" -and $setorR -ne $setorFiltro){ continue }
            if($grupoFiltro -ne "TODOS" -and $grupoR -ne $grupoFiltro){ continue }
            if($chefiaFiltro -eq "SEM CHEFIA"){
                if(-not [string]::IsNullOrWhiteSpace($chefiaR)){ continue }
            } elseif($chefiaFiltro -ne "TODOS" -and $chefiaR -ne $chefiaFiltro){
                continue
            }
            if($periodoFiltro -ne "TODOS" -and $periodoR -ne $periodoFiltro){ continue }

            if($busca){
                $hay=("$([string]$r.nome)|$([string]$r.matricula)|$setorR|$periodoR|$grupoR|$chefiaR").ToUpperInvariant()
                if($hay -notlike "*$busca*"){continue}
            }

            # Somente depois dos filtros baratos, avaliar as datas do ano/mes.
            $cacheKey="$ano|$([int]$r.id)"
            if(-not $centralCacheAnoMes.ContainsKey($cacheKey)){
                $centralCacheAnoMes[$cacheKey]=@(Get-MesesSolicitacoesRegistro $r $ano)
            }
            $mesesAno=@($centralCacheAnoMes[$cacheKey])
            if($mesesAno.Count -eq 0){continue}
            if($mesFoco -gt 0 -and $mesesAno -notcontains $mesFoco){continue}

            $idx=$grid.Rows.Add()
            $row=$grid.Rows[$idx]
            $row.Cells["id"].Value=[int]$r.id
            $row.Cells["nome"].Value=[string]$r.nome
            $row.Cells["setor"].Value=$setorR
            $row.Cells["periodo"].Value=$periodoR
            $ai=Date-ToBR ([string]$r.aquisitivo_inicio); $af=Date-ToBR ([string]$r.aquisitivo_fim)
            $row.Cells["aquisitivo"].Value=if($ai -and $af){"$ai a $af"}else{"Não informado"}
            $row.Cells["status"].Value=$status
            $row.DefaultCellStyle.BackColor=Get-CorStatusRegistro $r
            if(-not $centralCacheMarcas.ContainsKey($cacheKey)){
                $centralCacheMarcas[$cacheKey]=&$getMesCellsFast $r $ano
            }
            $marcasMes=$centralCacheMarcas[$cacheKey]
            for($m=1;$m -le 12;$m++){
                $v=[string]$marcasMes[$m]
                $row.Cells["mes$m"].Value=$v
                if($v -eq "FIXA"){
                    $row.Cells["mes$m"].Style.BackColor=[Drawing.Color]::FromArgb(211,232,255)
                    $row.Cells["mes$m"].Style.Font=$fonteFixa
                } elseif($v -like "*✓*"){
                    $row.Cells["mes$m"].Style.BackColor=[Drawing.Color]::FromArgb(226,239,218)
                } elseif($v){
                    $row.Cells["mes$m"].Style.BackColor=[Drawing.Color]::FromArgb(255,248,220)
                }
            }
        }
        $lblQtd.Text="Registros exibidos: $($grid.Rows.Count) | Ano: $ano | Setor: $setorFiltro | Grupo: $grupoFiltro | Chefia: $chefiaFiltro | Período: $periodoFiltro"
        &$refreshInstitucional

        # V1.0.53: sincroniza a seleção visual com o painel direito mesmo quando sobra apenas 1 registro.
        if($grid.Rows.Count -gt 0){
            $idxSel=0
            if($idAntes -gt 0){
                for($ix=0;$ix -lt $grid.Rows.Count;$ix++){
                    if([int]$grid.Rows[$ix].Cells["id"].Value -eq $idAntes){ $idxSel=$ix; break }
                }
            }
            $grid.ClearSelection()
            $grid.Rows[$idxSel].Selected=$true
            $grid.CurrentCell=$grid.Rows[$idxSel].Cells["nome"]
            # O carregamento do painel ocorre após liberar a suspensão de eventos.
            $script:CentralForcarRender=$true
        } else {
            $script:CentralServidorCurrentId=0
            $script:CentralUltimoRenderId=0
            $btnHistoricoRapido.Enabled=$false
            $btnConcorrentesRapido.Enabled=$false
            $lblServidor.Text="Nenhum servidor corresponde aos filtros atuais."
            $lblO1.Text=""; $lblO2.Text=""; $lblO3.Text=""; $txtJust.Text=""
            $gridSetor.Rows.Clear(); $gridChefia.Rows.Clear(); $cmbCompetencia.Items.Clear()
            $txtAnalise.Text=""; $lblAnaliseStatus.Text="SEM REGISTROS — ajuste os filtros."; $lblAnaliseStatus.BackColor=[Drawing.Color]::Gainsboro; &$resetPainelSimulacao
        }
        } finally {
            $grid.ResumeLayout()
            $centralUiState.SuppressEvents=$false
        }
        # Garantir o editor atualizado mesmo com um único registro na grade.
        if($grid.Rows.Count -gt 0){ &$requestCentralSelecao }
        $centralGridCrono.Stop()
        if($centralGridCrono.ElapsedMilliseconds -ge 300){
            Write-DiagLog "CENTRAL PERF: grade=$($centralGridCrono.ElapsedMilliseconds)ms | linhas=$($grid.Rows.Count) | ano=$ano" 'INFO'
        }
    }

    $refreshImpacto={
        $centralUiState.SuppressCompetenciaEvent=$true
        try {
        $gridSetor.Rows.Clear()
        $gridChefia.Rows.Clear()
        $txtAnalise.Text=""
        $txtAnalise.BackColor=[Drawing.Color]::White
        $txtAnalise.ForeColor=[Drawing.Color]::Black
        $lblAnaliseStatus.Text="Selecione uma opção para análise."
        $lblAnaliseStatus.BackColor=[Drawing.Color]::Gainsboro
        $lblAnaliseStatus.ForeColor=[Drawing.Color]::Black
        &$resetPainelSimulacao
        $cmbCompetencia.Items.Clear()

        if([int]$script:CentralServidorCurrentId -le 0){return}
        $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId} | Select-Object -First 1
        if($null -eq $r){return}

        $n=[int]$cmbOpcao.SelectedIndex+1
        $op=$r."opcao$n"

        if(Test-RegistroFeriasBloqueadas $r){
            $periodoProtegido=Get-PeriodoProtegidoResumo $r
            $origemFixa=if([bool]$r.fixo_ajustado){"AJUSTADA em $([string]$r.fixo_ajustado_em)"}elseif(Test-RegistroFixoImportado $r){"PROGRAMAÇÃO ANTERIOR IMPORTADA"}else{"PROGRAMAÇÃO ANTERIOR"}
            $lblO1.Text="FÉRIAS FIXAS — PERÍODO RESERVADO: $periodoProtegido"
            $lblO2.Text="Origem: $origemFixa"
            $lblO3.Text="Compromisso protegido: já ocupa capacidade no planejamento."
            $lblAnaliseStatus.Text="FÉRIAS FIXAS — COMPROMISSO JÁ RESERVADO`r`nNão é uma opção pendente de aprovação."
            $lblAnaliseStatus.BackColor=[Drawing.Color]::FromArgb(211,232,255); $lblAnaliseStatus.ForeColor=[Drawing.Color]::FromArgb(0,79,145)
            $txtAnalise.BackColor=[Drawing.Color]::AliceBlue; $txtAnalise.ForeColor=[Drawing.Color]::FromArgb(0,79,145)
            $txtAnalise.Text="PERÍODO FIXO RESERVADO`r`n• $periodoProtegido`r`n• Origem: $origemFixa`r`n• Setor: $(if(([string]$r.setor).Trim()){[string]$r.setor}else{'NÃO INFORMADO'})`r`n• Período de trabalho: $(if(([string]$r.periodo).Trim()){[string]$r.periodo}else{'SEM PERÍODO'})`r`n`r`nEste compromisso já ocupa capacidade e permanece protegido. Para corrigir uma data fixa, utilize o fluxo excepcional da Central de decisão, com backup e justificativa."
            &$resetPainelSimulacao "Período fixo já contabilizado e protegido." "Compromisso protegido: a capacidade já foi reservada para este período."; &$setLinhaPainel $lblLinhaGeral "GERAL: período fixo já contabilizado." "OK"; &$setLinhaPainel $lblLinhaSetor "SETOR: impacto já reservado para o período informado." "OK"; &$setLinhaPainel $lblLinhaChefia "CHEFIA: compromisso protegido, sem necessidade de nova aprovação." "INFORMATIVO"
            # Registro FIXO não precisa simular uma opção pendente; as datas protegidas já são exibidas acima.
            return
        }

        $lblO1.Text="1ª — $(Format-OptionSummary $r.opcao1)"
        $lblO2.Text="2ª — $(Format-OptionSummary $r.opcao2)"
        $lblO3.Text="3ª — $(Format-OptionSummary $r.opcao3)"

        $avaliacao=Get-AvaliacaoOpcaoRegistro $r $n
        $txtAnalise.Text=Format-AvaliacaoCentral $r $n $avaliacao
        switch([string]$avaliacao.nivel){
            "CRÍTICA" {
                $lblAnaliseStatus.Text="CRÍTICA — CONFLITO REAL`r`nNão aprovar sem revisar o conflito e justificar eventual exceção."
                $lblAnaliseStatus.BackColor=[Drawing.Color]::MistyRose; $lblAnaliseStatus.ForeColor=[Drawing.Color]::DarkRed
                $txtAnalise.BackColor=[Drawing.Color]::MistyRose; $txtAnalise.ForeColor=[Drawing.Color]::DarkRed
            }
            "ATENÇÃO" {
                $lblAnaliseStatus.Text="ATENÇÃO — REVISAR ANTES DE DECIDIR`r`nHá alerta de capacidade e/ou limite ainda não configurado."
                $lblAnaliseStatus.BackColor=[Drawing.Color]::FromArgb(255,244,204); $lblAnaliseStatus.ForeColor=[Drawing.Color]::FromArgb(120,76,0)
                $txtAnalise.BackColor=[Drawing.Color]::FromArgb(255,248,220); $txtAnalise.ForeColor=[Drawing.Color]::FromArgb(120,76,0)
            }
            "ADEQUADA" {
                $lblAnaliseStatus.Text="ADEQUADA — CENÁRIO FAVORÁVEL`r`nNenhum conflito operacional foi identificado pelas regras atuais."
                $lblAnaliseStatus.BackColor=[Drawing.Color]::FromArgb(226,239,218); $lblAnaliseStatus.ForeColor=[Drawing.Color]::DarkGreen
                $txtAnalise.BackColor=[Drawing.Color]::Honeydew; $txtAnalise.ForeColor=[Drawing.Color]::DarkGreen
            }
            default {
                $lblAnaliseStatus.Text="$([string]$avaliacao.nivel) — confira os dados abaixo."
                $lblAnaliseStatus.BackColor=[Drawing.Color]::Gainsboro; $lblAnaliseStatus.ForeColor=[Drawing.Color]::Black
                $txtAnalise.BackColor=[Drawing.Color]::White; $txtAnalise.ForeColor=[Drawing.Color]::Black
            }
        }

        if($null -eq $op -or [string]::IsNullOrWhiteSpace([string]$op.tipo)){
            &$resetPainelSimulacao "Opção não informada para este registro." "Preencha as datas da opção antes de decidir."; &$setLinhaPainel $lblLinhaGeral "GERAL: opção não informada." "ATENÇÃO"; &$setLinhaPainel $lblLinhaSetor "SETOR: sem simulação." "INFORMATIVO"; &$setLinhaPainel $lblLinhaChefia "CHEFIA: sem simulação." "INFORMATIVO"
            return
        }

        foreach($comp in (Get-CompetenciasOpcao $op)){ [void]$cmbCompetencia.Items.Add($comp) }
        if($cmbCompetencia.Items.Count -gt 0){$cmbCompetencia.SelectedIndex=0}else{return}
        } finally {$centralUiState.SuppressCompetenciaEvent=$false}
        if($cmbCompetencia.SelectedIndex -ge 0){&$refreshCompetencia}
    }

    $refreshCompetencia={
        $gridSetor.Rows.Clear()
        $gridChefia.Rows.Clear()
        if([int]$script:CentralServidorCurrentId -le 0 -or $null -eq $cmbCompetencia.SelectedItem){return}
        $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId} | Select-Object -First 1
        if($null -eq $r){return}
        $n=[int]$cmbOpcao.SelectedIndex+1
        $op=$r."opcao$n"
        if($null -eq $op){return}

        $parts=([string]$cmbCompetencia.SelectedItem).Split("-")
        if($parts.Count -lt 2){return}
        $ano=[int]$parts[0]; $mes=[int]$parts[1]
        $setor=([string]$r.setor).Trim()
        $perR=([string]$r.periodo).Trim(); if([string]::IsNullOrWhiteSpace($perR)){$perR="SEM PERÍODO"}
        $grupo=Get-GrupoChefiaEfetivaRegistro $r
        $origemGrupo=Get-OrigemGrupoChefiaRegistro $r
        $lblChefiaNome.Text=if($grupo){"Grupo de Chefia efetiva: $grupo ($origemGrupo)"}else{"Servidor sem Grupo de Chefia efetivo."}
        $periodos=&$getPeriodos

        $totAtualSetor=0; $totAposSetor=0
        foreach($per in $periodos){
            $base=Get-PlanejamentoOverlapInfoCached $setor $per $ano $mes
            $at=[int]$base.qtd_mes
            $apos=$at
            $pico=[int]$base.pico
            if($per -eq $perR){
                $sim=Get-SimulacaoSetorPeriodoMes $r $op $ano $mes
                $apos=[int]$sim.qtd_mes
                $pico=[int]$sim.pico
            }
            $lim=Get-LimiteSetorPeriodo $setor $per
            $sit=if($lim -le 0){"SEM LIMITE"}elseif($pico -gt $lim){"CRÍTICO"}elseif($apos -gt $lim){"ACIMA/MÊS"}elseif($apos -eq $lim -and $apos -gt 0){"NO LIMITE"}else{"OK"}
            $limTxt=if($lim -gt 0){$lim}else{"—"}
            $i=$gridSetor.Rows.Add($per,$at,$apos,$limTxt,$pico,$sit)
            if($sit -eq "CRÍTICO"){$gridSetor.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose}
            elseif($sit -like "ACIMA*"){$gridSetor.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::PeachPuff}
            elseif($sit -eq "NO LIMITE"){$gridSetor.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,244,204)}
            elseif($apos -gt 0){$gridSetor.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218)}
            $totAtualSetor += $at; $totAposSetor += $apos
        }
        [void]$gridSetor.Rows.Add("TOTAL SETOR",$totAtualSetor,$totAposSetor,"—","—","GERAL/MÊS")
        $gridSetor.Rows[$gridSetor.Rows.Count-1].DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)

        $totAtualChefia=0; $totAposChefia=0
        if($grupo){
            $setoresChefia=@($script:Config.grupo_chefia_setores | Where-Object {
                ([string]$_.grupo).Trim() -eq $grupo
            } | ForEach-Object { ([string]$_.setor).Trim() } | Where-Object { $_ })
            $setoresChefia += @($script:Records | Where-Object { (Get-GrupoChefiaEfetivaRegistro $_) -eq $grupo } | ForEach-Object { ([string]$_.setor).Trim() } | Where-Object { $_ })
            $setoresChefia=@($setoresChefia | Sort-Object -Unique)
            if($setoresChefia -notcontains $setor){ $setoresChefia=@($setoresChefia+$setor | Sort-Object -Unique) }

            foreach($setorV in $setoresChefia){
                foreach($per in $periodos){
                    $baseLocal=Get-PlanejamentoOverlapInfoCached $setorV $per $ano $mes
                    $atLocal=[int]$baseLocal.qtd_mes
                    $aposLocal=$atLocal
                    $picoLocal=[int]$baseLocal.pico
                    if($setorV -eq $setor -and $per -eq $perR){
                        $simLocal=Get-SimulacaoSetorPeriodoMes $r $op $ano $mes
                        $aposLocal=[int]$simLocal.qtd_mes
                        $picoLocal=[int]$simLocal.pico
                    }
                    if($atLocal -eq 0 -and $aposLocal -eq 0 -and -not ($setorV -eq $setor -and $per -eq $perR)){ continue }
                    $limLocal=Get-LimiteSetorPeriodo $setorV $per
                    $sitLocal=if($limLocal -le 0){"SEM LIMITE"}elseif($picoLocal -gt $limLocal){"CRÍTICO LOCAL"}elseif($aposLocal -gt $limLocal){"VER LOCAL"}elseif($aposLocal -eq $limLocal -and $aposLocal -gt 0){"NO LIMITE"}else{"OK"}
                    $limLocalTxt=if($limLocal -gt 0){$limLocal}else{"—"}
                    $i=$gridChefia.Rows.Add($setorV,$per,$atLocal,$aposLocal,$limLocalTxt,$picoLocal,$sitLocal)
                    if($setorV -eq $setor -and $per -eq $perR){ $gridChefia.Rows[$i].DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold) }
                }
            }

            # Linhas consolidadas do Grupo de Chefia por período: estas são as que obedecem
            # aos limites específicos configurados para o conjunto de setores interligados.
            foreach($per in $periodos){
                $baseGrupo=Get-GrupoChefiaOverlapInfoCached $grupo $per $ano $mes
                $at=[int]$baseGrupo.qtd_mes
                $apos=$at
                $pico=[int]$baseGrupo.pico
                if($per -eq $perR){
                    $simGrupo=Get-SimulacaoGrupoChefiaPeriodoMes $r $op $ano $mes
                    $apos=[int]$simGrupo.qtd_mes
                    $pico=[int]$simGrupo.pico
                }
                if($at -eq 0 -and $apos -eq 0){ continue }
                $lim=Get-LimiteGrupoChefiaPeriodo $grupo $per
                $sit=if($lim -le 0){"SEM LIMITE"}elseif($pico -gt $lim){"CRÍTICO"}elseif($apos -gt $lim){"ACIMA/MÊS"}elseif($apos -eq $lim -and $apos -gt 0){"NO LIMITE"}else{"OK"}
                $limTxt=if($lim -gt 0){$lim}else{"—"}
                $i=$gridChefia.Rows.Add("TOTAL GRUPO",$per,$at,$apos,$limTxt,$pico,$sit)
                $gridChefia.Rows[$i].DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
                if($sit -eq "CRÍTICO"){$gridChefia.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose}
                elseif($sit -like "ACIMA*"){$gridChefia.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::PeachPuff}
                elseif($sit -eq "NO LIMITE"){$gridChefia.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,244,204)}
                elseif($apos -gt 0){$gridChefia.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(226,239,218)}
                $totAtualChefia += $at; $totAposChefia += $apos
            }
            [void]$gridChefia.Rows.Add("TOTAL GERAL CHEFIA","TODOS",$totAtualChefia,$totAposChefia,"—","—","GERAL/MÊS")
            $gridChefia.Rows[$gridChefia.Rows.Count-1].DefaultCellStyle.Font=New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
        }

        $qAtual=Get-ContagemInstitucionalMes $ano $mes
        $qApos=Get-ContagemInstitucionalMesSimulada $r $op $ano $mes
        $limInst=Get-LimiteInstitucionalMes $mes
        $mesNome=Get-NomeMesExtenso $mes
        $txtLim=if($limInst -gt 0){Format-NumeroBR $limInst}else{"não configurado"}
        $sitGeral=if($limInst -le 0){"ATENÇÃO — limite institucional não configurado"}elseif($qApos -gt $limInst){"ALERTA — acima do limite institucional"}elseif($qApos -eq $limInst -and $qApos -gt 0){"NO LIMITE"}else{"OK"}

        $setorBase=Get-PlanejamentoOverlapInfoCached $setor $perR $ano $mes
        $setorSim=Get-SimulacaoSetorPeriodoMes $r $op $ano $mes
        $limSetor=Get-LimiteSetorPeriodo $setor $perR
        $limSetorTxt=if($limSetor -gt 0){[string]$limSetor}else{"sem limite"}
        $sitSetor=if($limSetor -le 0){"INFORMATIVO"}elseif([int]$setorSim.pico -gt $limSetor){"CRÍTICO"}elseif([int]$setorSim.qtd_mes -gt $limSetor){"ACIMA/MÊS"}elseif([int]$setorSim.qtd_mes -eq $limSetor -and [int]$setorSim.qtd_mes -gt 0){"NO LIMITE"}else{"OK"}
        $txtSetor="SETOR: $setor / $perR — atual $([int]$setorBase.qtd_mes), com opção $([int]$setorSim.qtd_mes), limite $limSetorTxt, situação $sitSetor"

        $txtChefia="CHEFIA: não vinculada"
        if($grupo){
            $baseGrupo=Get-GrupoChefiaOverlapInfoCached $grupo $perR $ano $mes
            $simGrupo=Get-SimulacaoGrupoChefiaPeriodoMes $r $op $ano $mes
            $limChefia=Get-LimiteGrupoChefiaPeriodo $grupo $perR
            $limChefiaTxt=if($limChefia -gt 0){[string]$limChefia}else{"sem limite"}
            $sitChefia=if($limChefia -le 0){"INFORMATIVO"}elseif([int]$simGrupo.pico -gt $limChefia){"CRÍTICO"}elseif([int]$simGrupo.qtd_mes -gt $limChefia){"ACIMA/MÊS"}elseif([int]$simGrupo.qtd_mes -eq $limChefia -and [int]$simGrupo.qtd_mes -gt 0){"NO LIMITE"}else{"OK"}
            $txtChefia="CHEFIA: $grupo / $perR — atual $([int]$baseGrupo.qtd_mes), com opção $([int]$simGrupo.qtd_mes), limite $limChefiaTxt, situação $sitChefia"
        }

        $delta=[math]::Round(([double]$qApos-[double]$qAtual),2)
        $sinal=if($delta -gt 0){'+'}else{''}
        # Apresentacao separada: compromisso real (fixas + aprovadas) vs projecao com pendentes.
        $confirmado=[double](Get-ContagemInstitucionalAprovadaMes $ano $mes)
        $pendenteProjetado=[math]::Max(0.0,([double]$qAtual-$confirmado))
        $saldoReal=[double]$limInst-$confirmado
        $saldoProjetado=[double]$limInst-[double]$qAtual
        $saldoSimulado=[double]$limInst-[double]$qApos
        $notaDelta=if([math]::Abs($delta) -lt 0.001){'Δ 0: a opção não aumenta a projeção neste mês; confira os períodos e aprovações.'}else{'Δ representa a alteração da projeção pela opção em análise.'}
        $lblInstitucional.Text="Competência simulada: $mesNome/$ano"
        $txtGeral="LIMITE: $txtLim  |  CONFIRMADO: $(Format-NumeroBR $confirmado)  |  SALDO REAL: $(Format-NumeroBR $saldoReal)" + "`r`n" +
                  "PEND. PROJETADAS: $(Format-NumeroBR $pendenteProjetado) | PROJEÇÃO: $(Format-NumeroBR $qAtual) | SALDO PROJETADO: $(Format-NumeroBR $saldoProjetado) | Δ: $sinal$(Format-NumeroBR $delta) | APÓS: $(Format-NumeroBR $saldoSimulado)"
        &$setLinhaPainel $lblLinhaGeral $txtGeral $sitGeral
        &$setLinhaPainel $lblLinhaSetor $txtSetor $sitSetor
        &$setLinhaPainel $lblLinhaChefia $txtChefia $(if($grupo){$sitChefia}else{'NÃO VINCULADA'})
        $lblSimulacaoAjuda.Text=$notaDelta
    }

    $carregarSelecionado={
        if($centralUiState.SuppressEvents){ return }
        if($grid.SelectedRows.Count -eq 0){return}
        $id=[int]$grid.SelectedRows[0].Cells["id"].Value
        if(-not $script:CentralForcarRender -and [int]$script:CentralUltimoRenderId -eq $id){ return }
        $gridComparativo.Rows.Clear()
        $lblCompInfo.Text="Clique em Atualizar para comparar os 12 meses"
        $r=$script:Records | Where-Object {[int]$_.id -eq $id} | Select-Object -First 1
        if($null -eq $r){return}
        $centralDetalheCrono=[Diagnostics.Stopwatch]::StartNew()
        try {
        $script:CentralForcarRender=$false
        $script:CentralUltimoRenderId=$id
        $script:CentralServidorCurrentId=$id
        $status=Get-StatusExibicaoRegistro $r
        $ai=Date-ToBR ([string]$r.aquisitivo_inicio); $af=Date-ToBR ([string]$r.aquisitivo_fim)
        $grupo=Get-GrupoChefiaEfetivaRegistro $r
        $fixaSel=Test-RegistroFeriasBloqueadas $r
        $linhaFixa=if($fixaSel){"`r`nPERÍODO FIXO RESERVADO: $(Get-PeriodoProtegidoResumo $r)"}else{""}
        $origemChefia=Get-OrigemGrupoChefiaRegistro $r
        $lblServidor.Text="$($r.nome) | Matrícula $($r.matricula) | $status`r`n$($r.setor) | $($r.periodo) | Aquisitivo: $ai a $af | Chefia: $(if($grupo){$grupo}else{'não vinculada'}) | Comum: $(Get-NumeroComumConfirmada $r) / FR: $(Get-NumeroFRConfirmada $r)$linhaFixa"
        $txtJust.Text=[string]$r.justificativa_decisao
        $nFRAtual=Get-NumeroFRConfirmada $r
        $cmbFR.SelectedIndex=$nFRAtual
        $bloqueioFR=Test-RegistroFeriasBloqueadas $r
        $cmbFR.Enabled=(-not $bloqueioFR)
        $btnAprovarFR.Enabled=(-not $bloqueioFR)
        $btnDesfazerFR.Enabled=(-not $bloqueioFR -and $nFRAtual -gt 0)
        $ap=0; try{$ap=[int]$r.opcao_aprovada}catch{$ap=0}
        $alvoOpcao=if($ap -ge 1 -and $ap -le 3){$ap-1}else{0}
        $centralUiState.SuppressOptionEvent=$true
        try{if($cmbOpcao.SelectedIndex -ne $alvoOpcao){$cmbOpcao.SelectedIndex=$alvoOpcao}}
        finally{$centralUiState.SuppressOptionEvent=$false}
        $bloq=Test-RegistroFeriasBloqueadas $r
        $btnAprovar.Enabled=(-not $bloq)
        $btnAprovarProx.Enabled=(-not $bloq)
        $btnDesfazerAprovacao.Enabled=(-not $bloq -and $ap -ge 1 -and $ap -le 3)
        $btnHistoricoRapido.Enabled=$true
        $btnConcorrentesRapido.Enabled=$true
        $cmbOpcao.Enabled=(-not $bloq)
        &$refreshImpacto
        &$refreshHistoricoCentral
        } finally {
            $centralDetalheCrono.Stop()
            if($centralDetalheCrono.ElapsedMilliseconds -ge 200){Write-DiagLog "CENTRAL CORR-R6: detalhes=$($centralDetalheCrono.ElapsedMilliseconds)ms | id=$id" 'INFO'}
        }
    }

    $aprovarAtual={
        param([bool]$irProximo)
        if([int]$script:CentralServidorCurrentId -le 0){return $false}
        $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId} | Select-Object -First 1
        if($null -eq $r){return $false}
        if(Test-RegistroFeriasBloqueadas $r){
            [Windows.Forms.MessageBox]::Show("Este registro é FIXO e permanece protegido. Use o fluxo excepcional da Central de decisão para alterar uma férias fixa.","Férias fixa",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null
            return $false
        }
        $n=[int]$cmbOpcao.SelectedIndex+1
        $op=Get-OpcaoSomenteComum $r.("opcao$n")
        if([string]::IsNullOrWhiteSpace([string]$op.tipo)){
            [Windows.Forms.MessageBox]::Show('Esta opcao nao possui ferias comuns. Para FR explicita, use Aprovar FR. Registros legados de 20 dias precisam de revisao.','Modalidade')|Out-Null
            return $false
        }
        $temDireitoFR=@(@($r.opcao1,$r.opcao2,$r.opcao3) | Where-Object { $_.fr_inicio -and $_.fr_fim }).Count -gt 0
        if($temDireitoFR -and ([string]$op.tipo -match '15\+15')){
            [Windows.Forms.MessageBox]::Show('Servidor com FR 20 dias deve tirar os 30 dias comuns sem parcelamento.','Regra FR')|Out-Null;return $false
        }
        if(Test-ConflitoComumFR $r $n (Get-NumeroFRConfirmada $r)){
            [Windows.Forms.MessageBox]::Show('Esta escolha comum se sobrepõe à FR já aprovada. Desfaça ou altere uma das decisões antes de aprovar.','Sobreposição',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
            return $false
        }
        $choqueAquisitivo=Get-ConflitoEntreAquisitivosAprovados $r @(Get-BlocosComunsOpcao $r $n)
        if($choqueAquisitivo){
            [Windows.Forms.MessageBox]::Show($choqueAquisitivo,'Sobreposição entre aquisitivos',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
            return $false
        }
        $erro=Validate-Option $op "${n}ª opção" ([string]$r.aquisitivo_fim)
        if($erro){
            [Windows.Forms.MessageBox]::Show($erro,"Opção inválida",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
            return $false
        }

        # Avaliar a candidata comum preservando o registro que contém a decisão FR.
        $aval=Get-AvaliacaoOpcaoRegistro $r $n -OpcaoSimulada $op
        $just=([string]$txtJust.Text).Trim()
        if([string]$aval.nivel -eq "CRÍTICA" -and [string]::IsNullOrWhiteSpace($just)){
            [Windows.Forms.MessageBox]::Show("Esta opção possui CONFLITO CRÍTICO pelas regras atuais.`n`nPara confirmar excepcionalmente, informe uma justificativa no campo abaixo das opções.","Justificativa obrigatória",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
            return $false
        }

        $msg="Confirmar a ${n}ª opção para:`n$($r.nome)`n`n$(Format-OptionSummary $op)`n`nClassificação atual: $([string]$aval.nivel)"
        if([string]$aval.nivel -eq "CRÍTICA"){
            $msg += "`n`nATENÇÃO: existe conflito crítico. A confirmação ficará registrada com a justificativa informada."
        } elseif([string]$aval.nivel -eq "ATENÇÃO"){
            $msg += "`n`nHá alertas operacionais/institucionais. Revise os quadros antes de confirmar."
        }
        $resp=[Windows.Forms.MessageBox]::Show($msg,"Confirmar férias",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
        if($resp -ne [Windows.Forms.DialogResult]::Yes){return $false}

        $anteriorComum=Get-NumeroComumConfirmada $r
        $r.opcao_aprovada=$n
        $r.justificativa_decisao=$just
        Write-DiagLog "APROVAÇÃO CENTRAL SERVIDOR: ID=$([int]$r.id) | Matrícula=$([string]$r.matricula) | Nome=$([string]$r.nome) | Opção=${n}ª | Nível=$([string]$aval.nivel)" "INFO"
        try {
            Save-Database | Out-Null
        } catch {
            $r.opcao_aprovada=$anteriorComum
            Write-DiagLog "Falha ao aprovar férias pela Central por Servidor." "ERROR" $_
            try { &$refreshGrid } catch {}
            return $false
        }

        # As abas ocultas sao invalidadas e atualizadas sob demanda pelo evento de troca.
        $script:UiLazyLoaded.Painel=$false
        $script:PlanejRefreshDirty=$true
        &$refreshGrid

        $proximoIndice=-1
        if($irProximo -and $grid.Rows.Count -gt 0){
            # Após o refresh, com filtro PENDENTES o registro aprovado sai da lista.
            if([string]$cmbStatus.SelectedItem -eq "PENDENTES"){
                $proximoIndice=0
            } else {
                for($i=0;$i -lt $grid.Rows.Count;$i++){
                    if([int]$grid.Rows[$i].Cells["id"].Value -eq [int]$r.id){$proximoIndice=[math]::Min($i+1,$grid.Rows.Count-1);break}
                }
            }
        }
        if($proximoIndice -ge 0 -and $grid.Rows.Count -gt 0){
            $grid.ClearSelection()
            $grid.Rows[$proximoIndice].Selected=$true
            $grid.CurrentCell=$grid.Rows[$proximoIndice].Cells["nome"]
            &$carregarSelecionado
        } else {
            $script:CentralServidorCurrentId=0
            $lblServidor.Text="Férias confirmadas. Selecione outro servidor."
            $gridSetor.Rows.Clear(); $gridChefia.Rows.Clear(); $txtAnalise.Text=""; $lblAnaliseStatus.Text="Selecione outro servidor para análise."; $lblAnaliseStatus.BackColor=[Drawing.Color]::Gainsboro; &$resetPainelSimulacao "Selecione um servidor para análise e aprovação."
        }
        return $true
    }


    $btnAprovarFR.add_Click({
        if([int]$script:CentralServidorCurrentId -le 0){return}
        $r=$script:Records|Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId}|Select-Object -First 1
        if($null -eq $r -or (Test-RegistroFeriasBloqueadas $r)){return}
        $n=[int]$cmbFR.SelectedIndex
        if($n -lt 1 -or $n -gt 3){[Windows.Forms.MessageBox]::Show('Selecione a 1ª, 2ª ou 3ª opção FR.','FR')|Out-Null;return}
        $op=$r.("opcao$n")
        $comumAprovada=Get-NumeroComumConfirmada $r
        if($comumAprovada -gt 0 -and ([string]$r.("opcao$comumAprovada").tipo -match '15\+15')){
            [Windows.Forms.MessageBox]::Show('FR não pode ser aprovada quando a escolha comum está parcelada em 15+15 dias.','Regra FR')|Out-Null;return
        }
        $a=Parse-Date ([string]$op.fr_inicio);$b=Parse-Date ([string]$op.fr_fim)
        if($null -eq $a -or $null -eq $b -or ($b-$a).Days -ne 19){[Windows.Forms.MessageBox]::Show('A FR selecionada deve possuir exatamente 20 dias e datas válidas.','FR')|Out-Null;return}
        $aq=Parse-Date ([string]$r.aquisitivo_fim)
        if($null -ne $aq -and $a -le $aq){[Windows.Forms.MessageBox]::Show('A FR começa antes ou no término do período aquisitivo.','FR')|Out-Null;return}
        if(Test-ConflitoComumFR $r (Get-NumeroComumConfirmada $r) $n){[Windows.Forms.MessageBox]::Show('FR e férias comuns aprovadas possuem sobreposição. Escolha datas distintas.','FR')|Out-Null;return}
        $choqueAquisitivo=Get-ConflitoEntreAquisitivosAprovados $r @(Get-BlocoFROpcao $r $n)
        if($choqueAquisitivo){[Windows.Forms.MessageBox]::Show($choqueAquisitivo,'Sobreposição entre aquisitivos')|Out-Null;return}
        $texto='Aprovar apenas a FR radiológica '+$n+'ª opção para '+[string]$r.nome+'?'+"`r`n"+$a.ToString('dd/MM/yyyy')+' a '+$b.ToString('dd/MM/yyyy')+"`r`nA decisão comum não será alterada."
        if([Windows.Forms.MessageBox]::Show($texto,'Confirmar FR',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question) -ne [Windows.Forms.DialogResult]::Yes){return}
        $somenteFR=New-EmptyOptionObject
        $somenteFR.tipo='FR 20 DIAS';$somenteFR.fr_inicio=[string]$op.fr_inicio;$somenteFR.fr_fim=[string]$op.fr_fim
        # A mesma opção pode conter a escolha comum já aprovada; não apagá-la na cópia.
        $avaliacaoFR=Get-AvaliacaoOpcaoRegistro $r $n -OpcaoSimulada $somenteFR
        $justFR=([string]$txtJust.Text).Trim()
        if(-not $avaliacaoFR.valida){[Windows.Forms.MessageBox]::Show([string]$avaliacaoFR.motivo,'FR invalida')|Out-Null;return}
        if([string]$avaliacaoFR.nivel -eq 'CRÍTICA' -and [string]::IsNullOrWhiteSpace($justFR)){
            [Windows.Forms.MessageBox]::Show('A FR excede a capacidade simultanea do setor/chefia. Informe justificativa para uma aprovacao excepcional.','Justificativa obrigatoria')|Out-Null;return
        }
        if([string]$avaliacaoFR.nivel -ne 'ADEQUADA'){
            if([Windows.Forms.MessageBox]::Show(([string]$avaliacaoFR.motivo+"`n`nConfirmar excepcionalmente a FR?"),'Alerta de capacidade FR',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning) -ne [Windows.Forms.DialogResult]::Yes){return}
        }
        $antes=Get-NumeroFRConfirmada $r
        $r.justificativa_decisao=$justFR
        $r.fr_opcao_aprovada=$n
        try{Save-Database|Out-Null}catch{$r.fr_opcao_aprovada=$antes;[Windows.Forms.MessageBox]::Show('Não foi possível salvar a decisão FR. O valor anterior foi restaurado em memória.','Erro')|Out-Null;return}
        Write-DiagLog "APROVACAO FR INDEPENDENTE | id=$([int]$r.id) | opcao=$n" 'INFO'
        $script:UiLazyLoaded.Painel=$false;$script:PlanejRefreshDirty=$true;&$refreshGrid
    })
    $btnDesfazerFR.add_Click({
        if([int]$script:CentralServidorCurrentId -le 0){return}
        $r=$script:Records|Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId}|Select-Object -First 1
        if($null -eq $r -or (Test-RegistroFeriasBloqueadas $r)){return}
        $antes=Get-NumeroFRConfirmada $r;if($antes -eq 0){return}
        if([Windows.Forms.MessageBox]::Show('Desfazer somente a aprovação FR deste servidor? As datas serão preservadas.','Desfazer FR',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question) -ne [Windows.Forms.DialogResult]::Yes){return}
        $r.fr_opcao_aprovada=0
        try{Save-Database|Out-Null}catch{$r.fr_opcao_aprovada=$antes;[Windows.Forms.MessageBox]::Show('Não foi possível desfazer a FR.','Erro')|Out-Null;return}
        $script:UiLazyLoaded.Painel=$false;$script:PlanejRefreshDirty=$true;&$refreshGrid
    })

    $btnDesfazerAprovacao.add_Click({
        if([int]$script:CentralServidorCurrentId -le 0){return}
        $r=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId} | Select-Object -First 1
        if($null -eq $r){return}
        if((Test-RegistroFeriasBloqueadas $r) -or (Test-RegistroFixoImportado $r)){
            [Windows.Forms.MessageBox]::Show("Férias fixas não podem ter a autorização desfeita por esta função.","Registro protegido")|Out-Null
            return
        }
        $anterior=[int]$r.opcao_aprovada
        if($anterior -lt 1 -or $anterior -gt 3){return}
        $pergunta="Desfazer a ${anterior}ª opção aprovada para $($r.nome)?`n`nAs opções e datas serão preservadas; o registro voltará a PENDENTE."
        if([Windows.Forms.MessageBox]::Show($pergunta,"Desfazer aprovação",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning) -ne [Windows.Forms.DialogResult]::Yes){return}
        $r.opcao_aprovada=0
        try {
            Save-Database | Out-Null
        } catch {
            $r.opcao_aprovada=$anterior
            Write-DiagLog "Falha ao desfazer aprovação ID=$([int]$r.id)" "ERROR" $_
            [Windows.Forms.MessageBox]::Show("Não foi possível gravar o cancelamento. A aprovação anterior foi mantida em memória. Verifique o log e a base antes de continuar.","Erro ao salvar",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)|Out-Null
            return
        }
        Write-DiagLog "DESFAZER APROVAÇÃO CENTRAL: ID=$([int]$r.id) | Matricula=$([string]$r.matricula) | OpcaoAnterior=$anterior | Decisao=pendente (opcoes preservadas)" "INFO"
        # As abas ocultas sao invalidadas e atualizadas sob demanda pelo evento de troca.
        $script:UiLazyLoaded.Painel=$false
        $script:PlanejRefreshDirty=$true
        &$refreshGrid
        [Windows.Forms.MessageBox]::Show("Aprovação desfeita. As opções foram preservadas e o registro voltou a PENDENTE.","Férias DCE",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null
    })

    $btnCompararAno.add_Click({
        $gridComparativo.Rows.Clear()
        if([int]$script:CentralServidorCurrentId -le 0){return}
        $registro=@($script:Records|Where-Object {[int]$_.id -eq [int]$script:CentralServidorCurrentId}|Select-Object -First 1)
        if($registro.Count -eq 0){return}
        $r=$registro[0]
        if(Test-RegistroFeriasBloqueadas $r){$lblCompInfo.Text="Férias fixas já comprometidas; sem simulação de escolha.";return}
        $numero=[int]$cmbOpcao.SelectedIndex+1
        $op=$r.("opcao$numero")
        if($null -eq $op -or -not ([string]$op.tipo).Trim()){$lblCompInfo.Text="Opção não preenchida.";return}
        $ano=[int][string]$cmbAno.SelectedItem
        $setor=([string]$r.setor).Trim()
        $periodo=([string]$r.periodo).Trim()
        if(-not $periodo){$periodo="SEM PERÍODO"}
        $grupo=Get-GrupoChefiaEfetivaRegistro $r
        $lblCompInfo.Text="Calculando 12 meses..."
        $gridComparativo.SuspendLayout()
        try {
            for($mes=1;$mes -le 12;$mes++){
                $q=Get-ContagemInstitucionalMes $ano $mes
                $sim=Get-ContagemInstitucionalMesSimulada $r $op $ano $mes
                $lim=Get-LimiteInstitucionalMes $mes
                # Setor e chefia sao numeros de profissionais simultaneos, nao ferias equivalentes.
                $setorInfo=Get-PlanejamentoOverlapInfoCached $setor $periodo $ano $mes
                $setorApos=[int]$setorInfo.qtd_mes
                $chefApos="—"
                if($grupo){$chefInfo=Get-GrupoChefiaOverlapInfoCached $grupo $periodo $ano $mes;$chefApos=[string][int]$chefInfo.qtd_mes}
                if((Get-MesesOpcaoObjeto $op $ano) -contains $mes){
                    $setorApos=[int](Get-SimulacaoSetorPeriodoMes $r $op $ano $mes).qtd_mes
                    if($grupo){$chefApos=[string][int](Get-SimulacaoGrupoChefiaPeriodoMes $r $op $ano $mes).qtd_mes}
                }
                $sit=if($lim -le 0){"SEM LIMITE"}elseif($sim -gt $lim){"ACIMA"}elseif($sim -eq $lim){"NO LIMITE"}else{"OK"}
                $i=$gridComparativo.Rows.Add((Get-NomeMesExtenso $mes),(Format-NumeroBR $q),(Format-NumeroBR $sim),(Format-NumeroBR $lim),$setorApos,$chefApos,$sit)
                if($sit -eq "ACIMA"){$gridComparativo.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::MistyRose}
                elseif($sit -eq "NO LIMITE"){$gridComparativo.Rows[$i].DefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(255,244,204)}
            }
            $lblCompInfo.Text="Setor e chefia: quantidade de pessoas no período"
        } catch { Write-DiagLog "Falha ao montar comparativo anual da Central." "ERROR" $_; $lblCompInfo.Text="Falha ao calcular; consulte o log." }
        finally {$gridComparativo.ResumeLayout()}
    })
    $grid.add_SelectionChanged({ &$requestCentralSelecao })
    $btnHistoricoRapido.add_Click({ &$abrirHistoricoRapido })
    $btnConcorrentesRapido.add_Click({ &$abrirConcorrentesRapido })
    $cmbOpcao.add_SelectedIndexChanged({ if($centralUiState.SuppressOptionEvent){return}; &$refreshImpacto; &$refreshHistoricoCentral; $script:CentralForcarRender=$false })
    $cmbCompetencia.add_SelectedIndexChanged({ if($centralUiState.SuppressCompetenciaEvent -or $cmbCompetencia.SelectedIndex -lt 0){return}; &$refreshCompetencia; &$refreshHistoricoCentral })
    $btnAprovar.add_Click({ [void](&$aprovarAtual $false) })
    $btnAprovarProx.add_Click({ [void](&$aprovarAtual $true) })

    $btnAtualizar.add_Click({ $centralUiState.FaixaKey=''; $centralUiState.Stamp=''; &$refreshGrid })
    $txtBusca.add_TextChanged({ &$requestCentralGrid })
    $cmbStatus.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbAno.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbMes.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbSetor.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbGrupoAnalise.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbChefia.add_SelectedIndexChanged({ &$requestCentralGrid })
    $cmbPeriodo.add_SelectedIndexChanged({ &$requestCentralGrid })
    $btnLimparFiltros.add_Click({
        $txtBusca.Clear()
        $cmbStatus.SelectedItem="PENDENTES"
        $cmbMes.SelectedIndex=0
        $cmbSetor.SelectedIndex=0
        $cmbGrupoAnalise.SelectedIndex=0
        $cmbChefia.SelectedIndex=0

        $cmbPeriodo.SelectedIndex=0
        &$requestCentralGrid
    })

    $dlg.add_FormClosed({
        try { $tmrCentralGrid.Stop(); $tmrCentralGrid.Dispose() } catch {}
        try { $tmrCentralSelecao.Stop(); $tmrCentralSelecao.Dispose() } catch {}
    })
    &$refreshGrid
    [void]$dlg.ShowDialog($form)
    # V1.0.90: a Central e janela modal. Atualizar editor apos fecha-la
    # (sem aguardar troca de aba, e sem regravar os dados da aprovacao).
    try {
        Refresh-Grid
        $matVolta=([string]$script:CurrentMatricula).Trim()
        if($matVolta){
            $idVolta=[int]$script:CurrentId
            Load-Servidor $matVolta
            if($idVolta -gt 0 -and @($script:Records | Where-Object { [int]$_.id -eq $idVolta }).Count -gt 0){
                Load-Editor $idVolta
                foreach($linhaVolta in $script:gridPeriodos.Rows){
                    if([int]$linhaVolta.Cells['pid'].Value -eq $idVolta){$linhaVolta.Selected=$true;break}
                }
            }
        }
    } catch { Write-DiagLog ('Sincronizacao apos Central: '+$_.Exception.Message) 'WARN' }
}


# --- PLANEJAMENTO POR SETOR ---
$panelPlanejTop=New-Object Windows.Forms.Panel
$panelPlanejTop.Dock="Top"
$panelPlanejTop.Height=302
$panelPlanejTop.BackColor=[Drawing.Color]::FromArgb(245,248,252)
$tabPlanejSetor.Controls.Add($panelPlanejTop)

$lblPlanejTitulo=New-Object Windows.Forms.Label
$lblPlanejTitulo.Text="PLANEJAMENTO DE FÉRIAS — BASE CONSOLIDADA DE DECISÃO"
$lblPlanejTitulo.Location=New-Object Drawing.Point(20,10)
$lblPlanejTitulo.Size=New-Object Drawing.Size(780,26)
$lblPlanejTitulo.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold)
$panelPlanejTop.Controls.Add($lblPlanejTitulo)

$panelPlanejTop.Controls.Add((New-Label "Ano" 20 47 50))
$script:cmbPlanejAno=New-Combo 20 68 95
[void]$script:cmbPlanejAno.Items.Add("2027")
[void]$script:cmbPlanejAno.Items.Add("2028")
$script:cmbPlanejAno.SelectedIndex=0
$panelPlanejTop.Controls.Add($script:cmbPlanejAno)

$lblPlanejPeriodoOculto=New-Label "Período de trabalho" 130 47 145
$lblPlanejPeriodoOculto.Visible=$false
$panelPlanejTop.Controls.Add($lblPlanejPeriodoOculto)
$script:cmbPlanejPeriodo=New-Combo 130 68 175
$script:cmbPlanejPeriodo.Visible=$false
$panelPlanejTop.Controls.Add($script:cmbPlanejPeriodo)

$panelPlanejTop.Controls.Add((New-Label "Grupo de análise" 130 47 120))
$script:cmbPlanejGrupo=New-Combo 130 68 205
@("TODOS","ASSISTENCIAL","GERÊNCIA DE ENFERMAGEM","DIRETORIA DE ENFERMAGEM") | ForEach-Object { [void]$script:cmbPlanejGrupo.Items.Add($_) }
$script:cmbPlanejGrupo.SelectedIndex=0
$panelPlanejTop.Controls.Add($script:cmbPlanejGrupo)

$panelPlanejTop.Controls.Add((New-Label "Setores" 350 47 80))
$script:txtPlanejSetoresResumo=New-TextBox 350 68 175
$script:txtPlanejSetoresResumo.ReadOnly=$true
$panelPlanejTop.Controls.Add($script:txtPlanejSetoresResumo)
$btnPlanejSetores=New-Button "Selecionar..." 530 65 100 32
$panelPlanejTop.Controls.Add($btnPlanejSetores)

$panelPlanejTop.Controls.Add((New-Label "Períodos" 635 47 80))
$script:txtPlanejPeriodosResumo=New-TextBox 635 68 155
$script:txtPlanejPeriodosResumo.ReadOnly=$true
$panelPlanejTop.Controls.Add($script:txtPlanejPeriodosResumo)
$btnPlanejPeriodos=New-Button "Selecionar..." 795 65 100 32
$panelPlanejTop.Controls.Add($btnPlanejPeriodos)

$btnAtualPlanej=New-Button "Atualizar análise" 900 65 120 32
$panelPlanejTop.Controls.Add($btnAtualPlanej)
$btnConfigLimites=New-Button "Limites setor" 1030 65 120 32
$panelPlanejTop.Controls.Add($btnConfigLimites)
$btnConfigChefias=New-Button "Limites chefia" 1160 65 130 32
$panelPlanejTop.Controls.Add($btnConfigChefias)
$btnCentralServidor=New-Button "Central por Servidor" 970 8 180 32
$btnCentralServidor.BackColor=[Drawing.Color]::FromArgb(214,232,252)
$btnCentralServidor.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$panelPlanejTop.Controls.Add($btnCentralServidor)
$btnAjudaPlanej=New-Button "Como usar" 1160 8 130 32
$panelPlanejTop.Controls.Add($btnAjudaPlanej)

$panelPlanejTop.Controls.Add((New-Label "Mês em foco" 20 105 90))
$script:cmbPlanejMes=New-Combo 20 125 125
@("TODOS","JAN","FEV","MAR","ABR","MAI","JUN","JUL","AGO","SET","OUT","NOV","DEZ") | ForEach-Object { [void]$script:cmbPlanejMes.Items.Add($_) }
$script:cmbPlanejMes.SelectedIndex=0
$panelPlanejTop.Controls.Add($script:cmbPlanejMes)

$panelPlanejTop.Controls.Add((New-Label "Exibir" 160 105 70))
$script:cmbPlanejSituacao=New-Combo 160 125 205
@("TODAS AS LINHAS","SOMENTE CRÍTICAS","COM ALERTA","COM FÉRIAS FIXAS","SEM LIMITE") | ForEach-Object { [void]$script:cmbPlanejSituacao.Items.Add($_) }
$script:cmbPlanejSituacao.SelectedIndex=0
$panelPlanejTop.Controls.Add($script:cmbPlanejSituacao)

$panelPlanejTop.Controls.Add((New-Label "Grupo de chefia" 385 105 120))
$script:cmbPlanejChefia=New-Combo 385 125 190
[void]$script:cmbPlanejChefia.Items.Add("TODOS")
$script:cmbPlanejChefia.SelectedIndex=0
$panelPlanejTop.Controls.Add($script:cmbPlanejChefia)

$script:chkPlanejSobreposicao=New-Object Windows.Forms.CheckBox
$script:chkPlanejSobreposicao.Text="Somente com sobreposição real"
$script:chkPlanejSobreposicao.Location=New-Object Drawing.Point(590,125)
$script:chkPlanejSobreposicao.Size=New-Object Drawing.Size(215,25)
$panelPlanejTop.Controls.Add($script:chkPlanejSobreposicao)

$panelPlanejTop.Controls.Add((New-Label "Pesquisar servidor / matrícula" 820 105 190))
$script:txtPlanejBuscaServidor=New-TextBox 820 125 235
$panelPlanejTop.Controls.Add($script:txtPlanejBuscaServidor)

$lblPlanejLegenda=New-Object Windows.Forms.Label
$lblPlanejLegenda.Text="FILTROS: Grupo de análise = quem compete entre si | Grupo de chefia = setores da mesma chefia.`r`nFaixa superior: REAL = fixas + aprovadas; PEND = projeção pendente; PROJ = real + projeção | B = BASE DE DECISÃO | S = SOLICITAÇÕES (todas as 1ª/2ª/3ª opções). Célula B:0 | S:2 = duas solicitações alternativas, ainda sem ocupar capacidade."
$lblPlanejLegenda.Location=New-Object Drawing.Point(20,155)
$lblPlanejLegenda.Size=New-Object Drawing.Size(1220,38)
$panelPlanejTop.Controls.Add($lblPlanejLegenda)
Update-PlanejSetoresResumo
Update-PlanejPeriodosResumo

$script:lblLimiteInstitucional=New-Object Windows.Forms.Label
$script:lblLimiteInstitucional.Location=New-Object Drawing.Point(20,195)
$script:lblLimiteInstitucional.Size=New-Object Drawing.Size(1220,24)
$script:lblLimiteInstitucional.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$panelPlanejTop.Controls.Add($script:lblLimiteInstitucional)

$script:gridLimiteInstitucional=New-Object Windows.Forms.DataGridView
$script:gridLimiteInstitucional.Location=New-Object Drawing.Point(20,220)
$script:gridLimiteInstitucional.Size=New-Object Drawing.Size(1220,72)
$script:gridLimiteInstitucional.ReadOnly=$true
$script:gridLimiteInstitucional.AllowUserToAddRows=$false
$script:gridLimiteInstitucional.RowHeadersVisible=$false
$script:gridLimiteInstitucional.ColumnHeadersHeight=22
$script:gridLimiteInstitucional.RowTemplate.Height=47
$script:gridLimiteInstitucional.AutoSizeColumnsMode="Fill"
$script:gridLimiteInstitucional.BackgroundColor=[Drawing.Color]::White
$mesInst=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
for($m=1;$m -le 12;$m++){ [void]$script:gridLimiteInstitucional.Columns.Add("li$m",$mesInst[$m-1]) }
[void]$script:gridLimiteInstitucional.Rows.Add()
$panelPlanejTop.Controls.Add($script:gridLimiteInstitucional)
$script:gridLimiteInstitucional.add_CellClick({
    param($sender,$e)
    if($script:PlanejRefreshDirty){return}
    if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $e.ColumnIndex -lt 12){
        try { Show-DetalhesFaixaInstitucional ([int]$script:cmbPlanejAno.SelectedItem) ([int]$e.ColumnIndex+1) }
        catch { Write-DiagLog ('Detalhe mensal Planejamento: '+$_.Exception.Message) 'ERROR' }
    }
})



$script:gridPlanejSetor=New-Object Windows.Forms.DataGridView
$script:gridPlanejSetor.Dock="Fill"
$script:gridPlanejSetor.ReadOnly=$true
$script:gridPlanejSetor.AllowUserToAddRows=$false
$script:gridPlanejSetor.RowHeadersVisible=$false
$script:gridPlanejSetor.SelectionMode="CellSelect"
$script:gridPlanejSetor.BackgroundColor=[Drawing.Color]::White
$script:gridPlanejSetor.EnableHeadersVisualStyles=$false
$script:gridPlanejSetor.AutoSizeColumnsMode="Fill"
[void]$script:gridPlanejSetor.Columns.Add("psSetor","Setor")
[void]$script:gridPlanejSetor.Columns.Add("psPeriodo","Período")
[void]$script:gridPlanejSetor.Columns.Add("psLimite","Limite")
$meses=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
for($m=1;$m -le 12;$m++){ [void]$script:gridPlanejSetor.Columns.Add("ps$m",$meses[$m-1]) }
[void]$script:gridPlanejSetor.Columns.Add("psTotal","Total")
$script:gridPlanejSetor.Columns["psSetor"].FillWeight=35
$script:gridPlanejSetor.Columns["psPeriodo"].FillWeight=18
$script:gridPlanejSetor.Columns["psLimite"].FillWeight=10
foreach($m in 1..12){ $script:gridPlanejSetor.Columns["ps$m"].FillWeight=8 }
$script:gridPlanejSetor.Columns["psTotal"].FillWeight=12
$tabPlanejSetor.Controls.Add($script:gridPlanejSetor)
$script:gridPlanejSetor.BringToFront()

$script:lblPlanejResumo=New-Object Windows.Forms.Label
$script:lblPlanejResumo.Dock="Bottom"
$script:lblPlanejResumo.Height=34
$script:lblPlanejResumo.Padding=New-Object Windows.Forms.Padding(10,8,0,0)
$script:lblPlanejResumo.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$tabPlanejSetor.Controls.Add($script:lblPlanejResumo)

# --- CADASTROS MESTRES — INTERFACE GUIADA V1.0.40 ---
$tabsCadastros=New-Object Windows.Forms.TabControl
$tabsCadastros.Dock="Fill"
$tabCadChefias=New-Object Windows.Forms.TabPage
$tabCadChefias.Text="Setores e Chefias"
$tabCadChefias.AutoScroll=$true
$tabCadPeriodos=New-Object Windows.Forms.TabPage
$tabCadPeriodos.Text="Períodos de trabalho"
$tabCadPeriodos.AutoScroll=$true
$tabCadFeriados=New-Object Windows.Forms.TabPage
$tabCadFeriados.Text="Feriados"
$tabCadFeriados.AutoScroll=$true
$tabsCadastros.TabPages.AddRange(@($tabCadChefias,$tabCadPeriodos,$tabCadFeriados))
$tabSetores.Controls.Add($tabsCadastros)

# Guia visual
$panelCadGuia=New-Object Windows.Forms.Panel
$panelCadGuia.Location=New-Object Drawing.Point(10,10)
$panelCadGuia.Size=New-Object Drawing.Size(1290,92)
$panelCadGuia.BackColor=[Drawing.Color]::FromArgb(236,245,255)
$panelCadGuia.BorderStyle="FixedSingle"
$tabCadChefias.Controls.Add($panelCadGuia)

$lblCadGuiaTitulo=New-Object Windows.Forms.Label
$lblCadGuiaTitulo.Text="PASSO A PASSO — COMO ORGANIZAR SETORES E SERVIDORES POR CHEFIA"
$lblCadGuiaTitulo.Location=New-Object Drawing.Point(14,10)
$lblCadGuiaTitulo.Size=New-Object Drawing.Size(850,24)
$lblCadGuiaTitulo.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$lblCadGuiaTitulo.ForeColor=[Drawing.Color]::FromArgb(24,82,145)
$panelCadGuia.Controls.Add($lblCadGuiaTitulo)

$lblCadGuia=New-Object Windows.Forms.Label
$lblCadGuia.Text="1  Confira os setores   →   2  Crie/selecione a Chefia   →   3  Vincule setores   →   4  Inclua exceções individuais de servidores   →   5  Configure os limites"
$lblCadGuia.Location=New-Object Drawing.Point(14,40)
$lblCadGuia.Size=New-Object Drawing.Size(1110,38)
$lblCadGuia.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$panelCadGuia.Controls.Add($lblCadGuia)

$btnAjudaChefias=New-Button "Ver passo a passo" 1130 27 140 38
$btnAjudaChefias.BackColor=[Drawing.Color]::FromArgb(214,232,252)
$panelCadGuia.Controls.Add($btnAjudaChefias)

# COLUNA 1 — Setores
$grpSetores=New-Object Windows.Forms.GroupBox
$grpSetores.Text="1. SETORES CADASTRADOS"
$grpSetores.Location=New-Object Drawing.Point(10,112)
$grpSetores.Size=New-Object Drawing.Size(395,540)
$tabCadChefias.Controls.Add($grpSetores)

$grpSetores.Controls.Add((New-Label "Nome do setor" 15 28 120))
$txtNovoSetor=New-TextBox 15 50 190
$grpSetores.Controls.Add($txtNovoSetor)
$btnAddSetor=New-Button "Adicionar" 215 48 80 30
$grpSetores.Controls.Add($btnAddSetor)
$btnEditSetor=New-Button "Renomear" 300 48 80 30
$grpSetores.Controls.Add($btnEditSetor)

$script:lstSetores=New-Object Windows.Forms.ListBox
$script:lstSetores.Location=New-Object Drawing.Point(15,88)
$script:lstSetores.Size=New-Object Drawing.Size(365,245)
$grpSetores.Controls.Add($script:lstSetores)

$lblGrupoAnaliseAjuda=New-Object Windows.Forms.Label
$lblGrupoAnaliseAjuda.Text="Grupo de análise do setor (NÃO é Grupo de Chefia)"
$lblGrupoAnaliseAjuda.Location=New-Object Drawing.Point(15,344)
$lblGrupoAnaliseAjuda.Size=New-Object Drawing.Size(340,22)
$lblGrupoAnaliseAjuda.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$grpSetores.Controls.Add($lblGrupoAnaliseAjuda)

$script:cmbSetorGrupoAnalise=New-Combo 15 368 250
@("ASSISTENCIAL","GERÊNCIA DE ENFERMAGEM","DIRETORIA DE ENFERMAGEM") | ForEach-Object { [void]$script:cmbSetorGrupoAnalise.Items.Add($_) }
$script:cmbSetorGrupoAnalise.SelectedIndex=0
$grpSetores.Controls.Add($script:cmbSetorGrupoAnalise)

$btnSalvarClassSetor=New-Button "Salvar grupo" 275 366 105 32
$grpSetores.Controls.Add($btnSalvarClassSetor)

$script:lblSetorChefiaAtual=New-Object Windows.Forms.Label
$script:lblSetorChefiaAtual.Location=New-Object Drawing.Point(15,408)
$script:lblSetorChefiaAtual.Size=New-Object Drawing.Size(365,38)
$script:lblSetorChefiaAtual.Text="Chefia padrão do setor: selecione um setor"
$script:lblSetorChefiaAtual.ForeColor=[Drawing.Color]::FromArgb(70,70,70)
$grpSetores.Controls.Add($script:lblSetorChefiaAtual)

$btnRemSetor=New-Button "Remover setor" 15 458 120 32
$grpSetores.Controls.Add($btnRemSetor)

$btnAbrirCadastroLoteSetor=New-Button "Adicionar vários..." 145 458 145 32
$grpSetores.Controls.Add($btnAbrirCadastroLoteSetor)

# Painel simples de lote dentro do mesmo grupo
$txtSetorLote=New-Object Windows.Forms.TextBox
$txtSetorLote.Location=New-Object Drawing.Point(15,500)
$txtSetorLote.Size=New-Object Drawing.Size(245,28)
$txtSetorLote.Visible=$false
$grpSetores.Controls.Add($txtSetorLote)
$btnAddSetoresLote=New-Button "Adicionar lista" 270 498 110 30
$btnAddSetoresLote.Visible=$false
$grpSetores.Controls.Add($btnAddSetoresLote)

# COLUNA 2 — Cadastro dos Grupos
$grpChefias=New-Object Windows.Forms.GroupBox
$grpChefias.Text="2. GRUPOS DE CHEFIA"
$grpChefias.Location=New-Object Drawing.Point(415,112)
$grpChefias.Size=New-Object Drawing.Size(365,540)
$tabCadChefias.Controls.Add($grpChefias)

$lblChefiaConceito=New-Object Windows.Forms.Label
$lblChefiaConceito.Text="Grupo de Chefia = nome usado para reunir setores que respondem à mesma chefia.`r`nEx.: MATERNO-INFANTIL."
$lblChefiaConceito.Location=New-Object Drawing.Point(15,28)
$lblChefiaConceito.Size=New-Object Drawing.Size(330,55)
$grpChefias.Controls.Add($lblChefiaConceito)

$grpChefias.Controls.Add((New-Label "Nome do Grupo de Chefia" 15 92 220))
$txtNovaChefia=New-TextBox 15 114 330
$grpChefias.Controls.Add($txtNovaChefia)

$btnAddChefia=New-Button "Adicionar" 15 150 100 32
$grpChefias.Controls.Add($btnAddChefia)
$btnRenChefia=New-Button "Renomear" 125 150 100 32
$grpChefias.Controls.Add($btnRenChefia)
$btnRemChefia=New-Button "Excluir" 235 150 110 32
$grpChefias.Controls.Add($btnRemChefia)

$script:lstChefias=New-Object Windows.Forms.ListBox
$script:lstChefias.Location=New-Object Drawing.Point(15,195)
$script:lstChefias.Size=New-Object Drawing.Size(330,225)
$grpChefias.Controls.Add($script:lstChefias)

$lblChefiaClique=New-Object Windows.Forms.Label
$lblChefiaClique.Text="Selecione uma chefia. À direita, vincule os setores e, se necessário, servidores individuais."
$lblChefiaClique.Location=New-Object Drawing.Point(15,430)
$lblChefiaClique.Size=New-Object Drawing.Size(330,48)
$lblChefiaClique.ForeColor=[Drawing.Color]::FromArgb(70,70,70)
$grpChefias.Controls.Add($lblChefiaClique)

$btnConfigChefiasCad=New-Button "Configurar limites por período" 15 485 210 36
$btnConfigChefiasCad.BackColor=[Drawing.Color]::FromArgb(229,241,229)
$grpChefias.Controls.Add($btnConfigChefiasCad)

# COLUNA 3 — Vínculos
$grpVinculosChefia=New-Object Windows.Forms.GroupBox
$grpVinculosChefia.Text="3. VÍNCULOS DESTA CHEFIA"
$grpVinculosChefia.Location=New-Object Drawing.Point(790,112)
$grpVinculosChefia.Size=New-Object Drawing.Size(510,540)
$tabCadChefias.Controls.Add($grpVinculosChefia)

$script:lblChefiaSelecionadaInfo=New-Object Windows.Forms.Label
$script:lblChefiaSelecionadaInfo.Location=New-Object Drawing.Point(15,26)
$script:lblChefiaSelecionadaInfo.Size=New-Object Drawing.Size(475,42)
$script:lblChefiaSelecionadaInfo.Text="Crie ou selecione um Grupo de Chefia."
$script:lblChefiaSelecionadaInfo.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$grpVinculosChefia.Controls.Add($script:lblChefiaSelecionadaInfo)

$tabsVinculosChefia=New-Object Windows.Forms.TabControl
$tabsVinculosChefia.Location=New-Object Drawing.Point(10,72)
$tabsVinculosChefia.Size=New-Object Drawing.Size(490,455)
$grpVinculosChefia.Controls.Add($tabsVinculosChefia)

$tabVincSetores=New-Object Windows.Forms.TabPage
$tabVincSetores.Text="Setores da Chefia"
$tabVincServidores=New-Object Windows.Forms.TabPage
$tabVincServidores.Text="Servidores da Chefia"
$tabsVinculosChefia.TabPages.AddRange(@($tabVincSetores,$tabVincServidores))

$lblVinculoAjuda=New-Object Windows.Forms.Label
$lblVinculoAjuda.Text="Marque TODOS os setores que respondem a esta chefia. Um setor só pode pertencer a um Grupo de Chefia."
$lblVinculoAjuda.Location=New-Object Drawing.Point(10,10)
$lblVinculoAjuda.Size=New-Object Drawing.Size(450,40)
$tabVincSetores.Controls.Add($lblVinculoAjuda)

$script:chkSetoresChefia=New-Object Windows.Forms.CheckedListBox
$script:chkSetoresChefia.Location=New-Object Drawing.Point(10,52)
$script:chkSetoresChefia.Size=New-Object Drawing.Size(450,260)
$script:chkSetoresChefia.CheckOnClick=$true
$tabVincSetores.Controls.Add($script:chkSetoresChefia)

$btnSalvarVinculosChefia=New-Button "SALVAR VÍNCULOS" 10 322 180 38
$btnSalvarVinculosChefia.BackColor=[Drawing.Color]::FromArgb(194,224,255)
$btnSalvarVinculosChefia.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$tabVincSetores.Controls.Add($btnSalvarVinculosChefia)

$btnDesmarcarChefia=New-Button "Desmarcar todos" 200 322 130 38
$tabVincSetores.Controls.Add($btnDesmarcarChefia)

$lblVinculoRegra=New-Object Windows.Forms.Label
$lblVinculoRegra.Text="O vínculo do SETOR é a regra padrão. Servidores sem exceção individual herdam automaticamente esta chefia."
$lblVinculoRegra.Location=New-Object Drawing.Point(10,370)
$lblVinculoRegra.Size=New-Object Drawing.Size(450,48)
$lblVinculoRegra.ForeColor=[Drawing.Color]::FromArgb(70,70,70)
$tabVincSetores.Controls.Add($lblVinculoRegra)

$lblServChefiaAjuda=New-Object Windows.Forms.Label
$lblServChefiaAjuda.Text="Use vínculo INDIVIDUAL somente para exceções. Ele tem prioridade sobre a chefia herdada do setor e nunca conta o servidor em dobro."
$lblServChefiaAjuda.Location=New-Object Drawing.Point(10,8)
$lblServChefiaAjuda.Size=New-Object Drawing.Size(450,40)
$tabVincServidores.Controls.Add($lblServChefiaAjuda)

$tabVincServidores.Controls.Add((New-Label "Pesquisar nome, matrícula ou setor" 10 50 250 20))
$script:txtBuscaServidorChefia=New-TextBox 10 70 450
$tabVincServidores.Controls.Add($script:txtBuscaServidorChefia)

$script:gridServidoresChefia=New-Object Windows.Forms.DataGridView
$script:gridServidoresChefia.Location=New-Object Drawing.Point(10,102)
$script:gridServidoresChefia.Size=New-Object Drawing.Size(450,235)
$script:gridServidoresChefia.AllowUserToAddRows=$false
$script:gridServidoresChefia.AllowUserToDeleteRows=$false
$script:gridServidoresChefia.RowHeadersVisible=$false
$script:gridServidoresChefia.AutoSizeColumnsMode="Fill"
$script:gridServidoresChefia.BackgroundColor=[Drawing.Color]::White
$script:gridServidoresChefia.SelectionMode="FullRowSelect"
$script:gridServidoresChefia.MultiSelect=$false

$colVinc=New-Object Windows.Forms.DataGridViewCheckBoxColumn
$colVinc.Name="vinc"; $colVinc.HeaderText="Individual"; $colVinc.FillWeight=13
[void]$script:gridServidoresChefia.Columns.Add($colVinc)
foreach($c in @(@("mat","Matrícula"),@("nome","Nome"),@("setor","Setor"),@("origem","Chefia atual / origem"))){
    [void]$script:gridServidoresChefia.Columns.Add($c[0],$c[1])
}
$script:gridServidoresChefia.Columns["mat"].ReadOnly=$true
$script:gridServidoresChefia.Columns["nome"].ReadOnly=$true
$script:gridServidoresChefia.Columns["setor"].ReadOnly=$true
$script:gridServidoresChefia.Columns["origem"].ReadOnly=$true
$script:gridServidoresChefia.Columns["mat"].FillWeight=17
$script:gridServidoresChefia.Columns["nome"].FillWeight=32
$script:gridServidoresChefia.Columns["setor"].FillWeight=24
$script:gridServidoresChefia.Columns["origem"].FillWeight=28
$tabVincServidores.Controls.Add($script:gridServidoresChefia)

$btnSalvarVinculosServidoresChefia=New-Button "SALVAR VÍNCULOS INDIVIDUAIS" 10 347 220 38
$btnSalvarVinculosServidoresChefia.BackColor=[Drawing.Color]::FromArgb(205,235,205)
$btnSalvarVinculosServidoresChefia.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$tabVincServidores.Controls.Add($btnSalvarVinculosServidoresChefia)

$btnLimparBuscaServidoresChefia=New-Button "Limpar pesquisa" 240 347 125 38
$tabVincServidores.Controls.Add($btnLimparBuscaServidoresChefia)

$lblServChefiaRegra=New-Object Windows.Forms.Label
$lblServChefiaRegra.Text="HERDADO DO SETOR = não precisa marcar. Marque apenas quem deve pertencer individualmente a esta chefia."
$lblServChefiaRegra.Location=New-Object Drawing.Point(10,392)
$lblServChefiaRegra.Size=New-Object Drawing.Size(450,34)
$lblServChefiaRegra.ForeColor=[Drawing.Color]::FromArgb(70,70,70)
$tabVincServidores.Controls.Add($lblServChefiaRegra)

# Aba Períodos
$panelPeriodoGuia=New-Object Windows.Forms.Panel
$panelPeriodoGuia.Location=New-Object Drawing.Point(20,20)
$panelPeriodoGuia.Size=New-Object Drawing.Size(900,70)
$panelPeriodoGuia.BackColor=[Drawing.Color]::FromArgb(245,248,252)
$panelPeriodoGuia.BorderStyle="FixedSingle"
$tabCadPeriodos.Controls.Add($panelPeriodoGuia)

$lblPeriodoGuia=New-Object Windows.Forms.Label
$lblPeriodoGuia.Text="PERÍODOS DE TRABALHO — pertencem ao servidor. Exemplos: MATUTINO, VESPERTINO, NOTURNO e DIURNO."
$lblPeriodoGuia.Location=New-Object Drawing.Point(15,14)
$lblPeriodoGuia.Size=New-Object Drawing.Size(850,42)
$lblPeriodoGuia.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$panelPeriodoGuia.Controls.Add($lblPeriodoGuia)

$grpPeriodos=New-Object Windows.Forms.GroupBox
$grpPeriodos.Text="Cadastro de períodos"
$grpPeriodos.Location=New-Object Drawing.Point(20,105)
$grpPeriodos.Size=New-Object Drawing.Size(650,520)
$tabCadPeriodos.Controls.Add($grpPeriodos)

$grpPeriodos.Controls.Add((New-Label "Nome / código do período" 15 28 180))
$txtNovoPeriodo=New-TextBox 15 50 320
$grpPeriodos.Controls.Add($txtNovoPeriodo)
$btnAddPeriodo=New-Button "Adicionar" 345 48 100 30
$grpPeriodos.Controls.Add($btnAddPeriodo)
$btnEditPeriodo=New-Button "Renomear" 455 48 100 30
$grpPeriodos.Controls.Add($btnEditPeriodo)

$script:lstPeriodos=New-Object Windows.Forms.ListBox
$script:lstPeriodos.Location=New-Object Drawing.Point(15,92)
$script:lstPeriodos.Size=New-Object Drawing.Size(610,320)
$grpPeriodos.Controls.Add($script:lstPeriodos)

$btnRemPeriodo=New-Button "Remover selecionado" 15 430 165 32
$grpPeriodos.Controls.Add($btnRemPeriodo)

$lblPeriodoInfo=New-Object Windows.Forms.Label
$lblPeriodoInfo.Location=New-Object Drawing.Point(195,430)
$lblPeriodoInfo.Size=New-Object Drawing.Size(420,60)
$lblPeriodoInfo.Text="No Painel, M/MATUTINO, V/VESPERTINO, N/NOTURNO e D/DIURNO são agrupados automaticamente."
$grpPeriodos.Controls.Add($lblPeriodoInfo)

# --- CADASTRO EM LOTE ---
$panelLoteTop=New-Object Windows.Forms.Panel
$panelLoteTop.Dock="Top"
$panelLoteTop.Height=145
$panelLoteTop.BackColor=[Drawing.Color]::FromArgb(245,248,252)
$tabLote.Controls.Add($panelLoteTop)

$lblLote=New-Object Windows.Forms.Label
$lblLote.Text="Cole do Excel quatro colunas: Matrícula | Nome | Setor | Período"
$lblLote.Location=New-Object Drawing.Point(20,14)
$lblLote.Size=New-Object Drawing.Size(760,24)
$lblLote.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$panelLoteTop.Controls.Add($lblLote)

$btnColarLote=New-Button "Colar do Excel" 20 50 135 34; $panelLoteTop.Controls.Add($btnColarLote)
$btnValidarLote=New-Button "Validar lote" 165 50 120 34; $panelLoteTop.Controls.Add($btnValidarLote)
$btnProcessarLote=New-Button "Processar lote" 295 50 130 34; $panelLoteTop.Controls.Add($btnProcessarLote)
$btnDesfazerLote=New-Button "Desfazer último lote" 435 50 165 34; $panelLoteTop.Controls.Add($btnDesfazerLote)
$btnLimparLote=New-Button "Limpar grade" 610 50 120 34; $panelLoteTop.Controls.Add($btnLimparLote)

$lblLoteInfo=New-Object Windows.Forms.Label
$lblLoteInfo.Text="Confira matrícula, nome, setor e período antes de processar. O sistema faz backup e permite desfazer o último lote. Setor e período são informativos no limite institucional."
$lblLoteInfo.Location=New-Object Drawing.Point(20,95)
$lblLoteInfo.Size=New-Object Drawing.Size(900,35)
$panelLoteTop.Controls.Add($lblLoteInfo)

$script:gridLote=New-Object Windows.Forms.DataGridView
$script:gridLote.Dock="Fill"
$script:gridLote.AllowUserToAddRows=$true
$script:gridLote.AllowUserToDeleteRows=$false
$script:gridLote.AutoSizeColumnsMode="Fill"
$script:gridLote.RowHeadersVisible=$false
$script:gridLote.BackgroundColor=[Drawing.Color]::White
foreach($c in @(
    @("lmat","Matrícula"),
    @("lnome","Nome"),
    @("lsetor","Setor"),
    @("lperiodo","Período"),
    @("lstatus","Status"),
    @("lmsg","Resultado")
)){
    [void]$script:gridLote.Columns.Add($c[0],$c[1])
}
$script:gridLote.Columns["lstatus"].ReadOnly=$true
$script:gridLote.Columns["lmsg"].ReadOnly=$true
$script:gridLote.Columns["lnome"].FillWeight=32
$script:gridLote.Columns["lsetor"].FillWeight=22
$script:gridLote.Columns["lmsg"].FillWeight=28
$tabLote.Controls.Add($script:gridLote)
$script:gridLote.BringToFront()

# Aba Feriados — fixos recorrentes e datas específicas/variáveis
$panelFerGuia=New-Object Windows.Forms.Panel
$panelFerGuia.Location=New-Object Drawing.Point(15,15); $panelFerGuia.Size=New-Object Drawing.Size(1240,76)
$panelFerGuia.BackColor=[Drawing.Color]::FromArgb(236,245,255); $panelFerGuia.BorderStyle='FixedSingle'; $tabCadFeriados.Controls.Add($panelFerGuia)
$lblFerGuia=New-Object Windows.Forms.Label
$lblFerGuia.Text="CALENDÁRIO DE FERIADOS — informação auxiliar sobre a data inicial. Não altera os pesos de férias nem cria limite mensal por setor ou turno. FS = sábado/domingo."
$lblFerGuia.Location=New-Object Drawing.Point(14,12); $lblFerGuia.Size=New-Object Drawing.Size(1190,48); $lblFerGuia.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold); $panelFerGuia.Controls.Add($lblFerGuia)

$grpFerRec=New-Object Windows.Forms.GroupBox; $grpFerRec.Text='Feriados recorrentes anuais'; $grpFerRec.Location=New-Object Drawing.Point(15,105); $grpFerRec.Size=New-Object Drawing.Size(610,560); $tabCadFeriados.Controls.Add($grpFerRec)
$grpFerRec.Controls.Add((New-Label 'Dia' 15 28 45)); $numFerDia=New-Object Windows.Forms.NumericUpDown; $numFerDia.Location=New-Object Drawing.Point(15,50); $numFerDia.Size=New-Object Drawing.Size(65,26); $numFerDia.Minimum=1; $numFerDia.Maximum=31; $numFerDia.Value=1; $grpFerRec.Controls.Add($numFerDia)
$grpFerRec.Controls.Add((New-Label 'Mês' 95 28 55)); $numFerMes=New-Object Windows.Forms.NumericUpDown; $numFerMes.Location=New-Object Drawing.Point(95,50); $numFerMes.Size=New-Object Drawing.Size(65,26); $numFerMes.Minimum=1; $numFerMes.Maximum=12; $numFerMes.Value=1; $grpFerRec.Controls.Add($numFerMes)
$grpFerRec.Controls.Add((New-Label 'Descrição' 175 28 90)); $txtFerRecDesc=New-TextBox 175 50 260; $grpFerRec.Controls.Add($txtFerRecDesc)
$grpFerRec.Controls.Add((New-Label 'Abrangência' 450 28 110)); $cmbFerRecAbr=New-Combo 450 50 140; @('Nacional','Estadual','Municipal','Institucional','Outro')|ForEach-Object{[void]$cmbFerRecAbr.Items.Add($_)}; $cmbFerRecAbr.SelectedIndex=0; $grpFerRec.Controls.Add($cmbFerRecAbr)
$chkFerRecAtivo=New-Object Windows.Forms.CheckBox; $chkFerRecAtivo.Text='Ativo'; $chkFerRecAtivo.Location=New-Object Drawing.Point(15,88); $chkFerRecAtivo.Size=New-Object Drawing.Size(80,24); $chkFerRecAtivo.Checked=$true; $grpFerRec.Controls.Add($chkFerRecAtivo)
$btnFerRecSalvar=New-Button 'Adicionar / atualizar' 110 84 165 32; $grpFerRec.Controls.Add($btnFerRecSalvar)
$btnFerRecNovo=New-Button 'Novo' 285 84 90 32; $grpFerRec.Controls.Add($btnFerRecNovo)
$btnFerRecExcluir=New-Button 'Excluir' 385 84 90 32; $grpFerRec.Controls.Add($btnFerRecExcluir)
$script:gridFeriadosRec=New-Object Windows.Forms.DataGridView; $script:gridFeriadosRec.Location=New-Object Drawing.Point(15,128); $script:gridFeriadosRec.Size=New-Object Drawing.Size(575,410); $script:gridFeriadosRec.ReadOnly=$true; $script:gridFeriadosRec.AllowUserToAddRows=$false; $script:gridFeriadosRec.AllowUserToDeleteRows=$false; $script:gridFeriadosRec.RowHeadersVisible=$false; $script:gridFeriadosRec.SelectionMode='FullRowSelect'; $script:gridFeriadosRec.MultiSelect=$false; $script:gridFeriadosRec.AutoSizeColumnsMode='Fill'; $script:gridFeriadosRec.BackgroundColor=[Drawing.Color]::White; $grpFerRec.Controls.Add($script:gridFeriadosRec)
foreach($c in @(@('frId','ID'),@('frData','Dia/Mês'),@('frDesc','Descrição'),@('frAbr','Abrangência'),@('frAtivo','Ativo'))){[void]$script:gridFeriadosRec.Columns.Add($c[0],$c[1])}; $script:gridFeriadosRec.Columns['frId'].Visible=$false; $script:gridFeriadosRec.Columns['frData'].FillWeight=17; $script:gridFeriadosRec.Columns['frDesc'].FillWeight=43; $script:gridFeriadosRec.Columns['frAbr'].FillWeight=25; $script:gridFeriadosRec.Columns['frAtivo'].FillWeight=15
$script:FerRecId=''

$grpFerEsp=New-Object Windows.Forms.GroupBox; $grpFerEsp.Text='Feriados específicos / variáveis'; $grpFerEsp.Location=New-Object Drawing.Point(640,105); $grpFerEsp.Size=New-Object Drawing.Size(615,560); $tabCadFeriados.Controls.Add($grpFerEsp)
$grpFerEsp.Controls.Add((New-Label 'Data' 15 28 60)); $dtFerEsp=New-Object Windows.Forms.DateTimePicker; $dtFerEsp.Location=New-Object Drawing.Point(15,50); $dtFerEsp.Size=New-Object Drawing.Size(130,26); $dtFerEsp.Format='Custom'; $dtFerEsp.CustomFormat='dd/MM/yyyy'; $grpFerEsp.Controls.Add($dtFerEsp)
$grpFerEsp.Controls.Add((New-Label 'Descrição' 160 28 90)); $txtFerEspDesc=New-TextBox 160 50 270; $grpFerEsp.Controls.Add($txtFerEspDesc)
$grpFerEsp.Controls.Add((New-Label 'Abrangência' 445 28 110)); $cmbFerEspAbr=New-Combo 445 50 150; @('Nacional','Estadual','Municipal','Institucional','Outro')|ForEach-Object{[void]$cmbFerEspAbr.Items.Add($_)}; $cmbFerEspAbr.SelectedIndex=0; $grpFerEsp.Controls.Add($cmbFerEspAbr)
$chkFerEspAtivo=New-Object Windows.Forms.CheckBox; $chkFerEspAtivo.Text='Ativo'; $chkFerEspAtivo.Location=New-Object Drawing.Point(15,88); $chkFerEspAtivo.Size=New-Object Drawing.Size(80,24); $chkFerEspAtivo.Checked=$true; $grpFerEsp.Controls.Add($chkFerEspAtivo)
$btnFerEspSalvar=New-Button 'Adicionar / atualizar' 110 84 165 32; $grpFerEsp.Controls.Add($btnFerEspSalvar)
$btnFerEspNovo=New-Button 'Novo' 285 84 90 32; $grpFerEsp.Controls.Add($btnFerEspNovo)
$btnFerEspExcluir=New-Button 'Excluir' 385 84 90 32; $grpFerEsp.Controls.Add($btnFerEspExcluir)
$script:gridFeriadosEsp=New-Object Windows.Forms.DataGridView; $script:gridFeriadosEsp.Location=New-Object Drawing.Point(15,128); $script:gridFeriadosEsp.Size=New-Object Drawing.Size(580,410); $script:gridFeriadosEsp.ReadOnly=$true; $script:gridFeriadosEsp.AllowUserToAddRows=$false; $script:gridFeriadosEsp.AllowUserToDeleteRows=$false; $script:gridFeriadosEsp.RowHeadersVisible=$false; $script:gridFeriadosEsp.SelectionMode='FullRowSelect'; $script:gridFeriadosEsp.MultiSelect=$false; $script:gridFeriadosEsp.AutoSizeColumnsMode='Fill'; $script:gridFeriadosEsp.BackgroundColor=[Drawing.Color]::White; $grpFerEsp.Controls.Add($script:gridFeriadosEsp)
foreach($c in @(@('feId','ID'),@('feData','Data'),@('feDesc','Descrição'),@('feAbr','Abrangência'),@('feAtivo','Ativo'))){[void]$script:gridFeriadosEsp.Columns.Add($c[0],$c[1])}; $script:gridFeriadosEsp.Columns['feId'].Visible=$false; $script:gridFeriadosEsp.Columns['feData'].FillWeight=20; $script:gridFeriadosEsp.Columns['feDesc'].FillWeight=40; $script:gridFeriadosEsp.Columns['feAbr'].FillWeight=25; $script:gridFeriadosEsp.Columns['feAtivo'].FillWeight=15
$script:FerEspId=''

# --- CONFIGURAÇÕES — ORGANIZADAS EM ABAS PARA EVITAR SOBREPOSIÇÃO ---
$tabCfg.AutoScroll=$false
$tabsCfg=New-Object Windows.Forms.TabControl
$tabsCfg.Dock="Fill"
$tabCfgGeral=New-Object Windows.Forms.TabPage; $tabCfgGeral.Text="Geral"
$tabCfgImport=New-Object Windows.Forms.TabPage; $tabCfgImport.Text="Importações"
$tabCfgPolitica=New-Object Windows.Forms.TabPage; $tabCfgPolitica.Text="Política mensal"
$tabCfgManut=New-Object Windows.Forms.TabPage; $tabCfgManut.Text="Manutenção / Reset"
foreach($p in @($tabCfgGeral,$tabCfgImport,$tabCfgPolitica,$tabCfgManut)){ $p.AutoScroll=$true }
$tabsCfg.TabPages.AddRange(@($tabCfgGeral,$tabCfgImport,$tabCfgPolitica,$tabCfgManut))
$tabCfg.Controls.Add($tabsCfg)

# CONFIG > GERAL
$panelCfgGeral=New-Object Windows.Forms.Panel
$panelCfgGeral.Location=New-Object Drawing.Point(15,15); $panelCfgGeral.Size=New-Object Drawing.Size(1240,64)
$panelCfgGeral.BackColor=[Drawing.Color]::FromArgb(236,245,255); $panelCfgGeral.BorderStyle="FixedSingle"
$tabCfgGeral.Controls.Add($panelCfgGeral)
$lblCfgGeral=New-Object Windows.Forms.Label
$lblCfgGeral.Text="CONFIGURAÇÕES GERAIS — operação local, cópias de segurança e importação de planilhas."
$lblCfgGeral.Location=New-Object Drawing.Point(14,12); $lblCfgGeral.Size=New-Object Drawing.Size(1180,36)
$lblCfgGeral.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $panelCfgGeral.Controls.Add($lblCfgGeral)

$grpBanco=New-Object Windows.Forms.GroupBox
$grpBanco.Text="Banco e backups"; $grpBanco.Location=New-Object Drawing.Point(15,92); $grpBanco.Size=New-Object Drawing.Size(1240,110)
$tabCfgGeral.Controls.Add($grpBanco)
$grpBanco.Controls.Add((New-Label "Base de dados atual" 15 25 150))
$txtPath=New-TextBox 15 47 970; $txtPath.Text=$script:DbFile; $txtPath.ReadOnly=$true; $grpBanco.Controls.Add($txtPath)
$btnBackup=New-Button "Criar backup agora" 1000 45 190 32; $grpBanco.Controls.Add($btnBackup)

$grpPlanilha=New-Object Windows.Forms.GroupBox
$grpPlanilha.Text="Planilha base de solicitações"; $grpPlanilha.Location=New-Object Drawing.Point(15,217); $grpPlanilha.Size=New-Object Drawing.Size(1240,185)
$tabCfgGeral.Controls.Add($grpPlanilha)
$grpPlanilha.Controls.Add((New-Label "Layout aceito: Matrícula | Nome | Setor | Grupo de Chefia | Grupo de Análise | Período Aquisitivo | 1ª/2ª/3ª opções" 15 25 930))
$script:txtPlanilhaBase=New-TextBox 15 48 970; $script:txtPlanilhaBase.Text=[string]$script:Config.planilha_base; $script:txtPlanilhaBase.ReadOnly=$true; $grpPlanilha.Controls.Add($script:txtPlanilhaBase)
$btnEscolherPlanilha=New-Button "Selecionar planilha" 1000 46 190 32; $grpPlanilha.Controls.Add($btnEscolherPlanilha)
$btnSincronizar=New-Button "Sincronizar agora" 15 92 160 34; $grpPlanilha.Controls.Add($btnSincronizar)
$chkAutoSync=New-Object Windows.Forms.CheckBox
$chkAutoSync.Text="Sincronizar automaticamente ao abrir o sistema"; $chkAutoSync.Location=New-Object Drawing.Point(195,98); $chkAutoSync.Size=New-Object Drawing.Size(360,26)
$chkAutoSync.Checked=[bool]$script:Config.sincronizar_ao_abrir; $grpPlanilha.Controls.Add($chkAutoSync)
$script:lblSyncStatus=New-Object Windows.Forms.Label
$script:lblSyncStatus.Location=New-Object Drawing.Point(15,137); $script:lblSyncStatus.Size=New-Object Drawing.Size(1175,30)
$script:lblSyncStatus.Text="Nenhuma sincronização realizada nesta sessão."; $grpPlanilha.Controls.Add($script:lblSyncStatus)

$grpStatus=New-Object Windows.Forms.GroupBox
$grpStatus.Text="Situação da base"; $grpStatus.Location=New-Object Drawing.Point(15,417); $grpStatus.Size=New-Object Drawing.Size(1240,165)
$tabCfgGeral.Controls.Add($grpStatus)
$script:lblConfigInfo=New-Object Windows.Forms.Label
$script:lblConfigInfo.Location=New-Object Drawing.Point(15,28); $script:lblConfigInfo.Size=New-Object Drawing.Size(1190,42)
$script:lblConfigInfo.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $grpStatus.Controls.Add($script:lblConfigInfo)
$lblCfgNota=New-Object Windows.Forms.Label
$lblCfgNota.Location=New-Object Drawing.Point(15,78); $lblCfgNota.Size=New-Object Drawing.Size(1190,70)
$lblCfgNota.Text="REGRAS ATIVAS: limite institucional = total GERAL de enfermeiros / 12. Férias de 30 ou 20 dias contam 1,0; cada quinzena de 15 dias conta 0,5 no mês. Férias fixas importadas já estão definidas pelo RH, ocupam capacidade e não participam das opções. Setor, turno e chefia são filtros de consulta, sem bloqueio próprio."
$grpStatus.Controls.Add($lblCfgNota)

# CONFIG > IMPORTAÇÕES
$panelImpGuia=New-Object Windows.Forms.Panel
$panelImpGuia.Location=New-Object Drawing.Point(15,15); $panelImpGuia.Size=New-Object Drawing.Size(1240,72)
$panelImpGuia.BackColor=[Drawing.Color]::FromArgb(236,245,255); $panelImpGuia.BorderStyle="FixedSingle"; $tabCfgImport.Controls.Add($panelImpGuia)
$lblImpGuia=New-Object Windows.Forms.Label
$lblImpGuia.Text="IMPORTAÇÕES SEGURAS — selecione o arquivo, clique em ANALISAR / IMPORTAR e confira a prévia antes de gravar. A planilha original nunca é alterada."
$lblImpGuia.Location=New-Object Drawing.Point(14,13); $lblImpGuia.Size=New-Object Drawing.Size(1190,44)
$lblImpGuia.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $panelImpGuia.Controls.Add($lblImpGuia)

$grpFixasImp=New-Object Windows.Forms.GroupBox
$grpFixasImp.Text="1. Férias já definidas para 2027 — COMPROMISSOS FIXOS"; $grpFixasImp.Location=New-Object Drawing.Point(15,102); $grpFixasImp.Size=New-Object Drawing.Size(1240,235)
$tabCfgImport.Controls.Add($grpFixasImp)
$lblFixasExp=New-Object Windows.Forms.Label
$lblFixasExp.Text="Importe PRIMEIRO as férias já confirmadas pelo RH. Cada período fixo possui uma escolha única, sem 1ª/2ª/3ª alternativas. Cruza matrícula e período aquisitivo; uma quinzena única de 15 dias vale 0,5, sem exigir a outra parcela."
$lblFixasExp.Location=New-Object Drawing.Point(15,28); $lblFixasExp.Size=New-Object Drawing.Size(1190,48); $grpFixasImp.Controls.Add($lblFixasExp)
$grpFixasImp.Controls.Add((New-Label "Arquivo selecionado" 15 82 180))
$script:txtFixasPath=New-TextBox 15 104 860; $script:txtFixasPath.Text=[string]$script:Config.planilha_ferias_fixas_2027; $script:txtFixasPath.ReadOnly=$true; $grpFixasImp.Controls.Add($script:txtFixasPath)
$btnSelecionarFixas=New-Button "Selecionar arquivo" 890 102 145 32; $grpFixasImp.Controls.Add($btnSelecionarFixas)
$btnImportarFixas=New-Button "ANALISAR / IMPORTAR" 1045 102 165 32; $btnImportarFixas.BackColor=[Drawing.Color]::FromArgb(205,235,205); $grpFixasImp.Controls.Add($btnImportarFixas)
$script:lblFixasStatus=New-Object Windows.Forms.Label
$script:lblFixasStatus.Location=New-Object Drawing.Point(15,150); $script:lblFixasStatus.Size=New-Object Drawing.Size(1190,28); $script:lblFixasStatus.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpFixasImp.Controls.Add($script:lblFixasStatus)
$lblFixasNota=New-Object Windows.Forms.Label
$lblFixasNota.Text="Antes de importar, uma tela de conferência mostra o que será ATUALIZADO, CRIADO, IGNORADO ou exigirá conferência. Backup obrigatório é criado antes da gravação."
$lblFixasNota.Location=New-Object Drawing.Point(15,184); $lblFixasNota.Size=New-Object Drawing.Size(1180,35); $grpFixasImp.Controls.Add($lblFixasNota)

$grpHistImp=New-Object Windows.Forms.GroupBox
$grpHistImp.Text="2. Histórico de férias — CRITÉRIO DE DESEMPATE"; $grpHistImp.Location=New-Object Drawing.Point(15,352); $grpHistImp.Size=New-Object Drawing.Size(1240,255)
$tabCfgImport.Controls.Add($grpHistImp)
$lblHistExp=New-Object Windows.Forms.Label
$lblHistExp.Text="Use a planilha histórica com células amarelas. São importados somente registros de Cargo = Enfermeiro. Ausência de um ano é tratada como SEM REGISTRO — nunca como prova de que o servidor não tirou férias."
$lblHistExp.Location=New-Object Drawing.Point(15,28); $lblHistExp.Size=New-Object Drawing.Size(1190,48); $grpHistImp.Controls.Add($lblHistExp)
$grpHistImp.Controls.Add((New-Label "Arquivo selecionado" 15 82 180))
$script:txtHistoricoPath=New-TextBox 15 104 860; $script:txtHistoricoPath.Text=[string]$script:Config.planilha_historico_ferias; $script:txtHistoricoPath.ReadOnly=$true; $grpHistImp.Controls.Add($script:txtHistoricoPath)
$btnSelecionarHistorico=New-Button "Selecionar arquivo" 890 102 145 32; $grpHistImp.Controls.Add($btnSelecionarHistorico)
$btnImportarHistorico=New-Button "ANALISAR / IMPORTAR" 1045 102 165 32; $btnImportarHistorico.BackColor=[Drawing.Color]::FromArgb(205,235,205); $grpHistImp.Controls.Add($btnImportarHistorico)
$script:lblHistoricoImportStatus=New-Object Windows.Forms.Label
$script:lblHistoricoImportStatus.Location=New-Object Drawing.Point(15,150); $script:lblHistoricoImportStatus.Size=New-Object Drawing.Size(1190,28); $script:lblHistoricoImportStatus.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpHistImp.Controls.Add($script:lblHistoricoImportStatus)
$lblHistNota=New-Object Windows.Forms.Label
$lblHistNota.Text="Histórico serve exclusivamente como apoio ao desempate entre solicitações equivalentes. Não cria limite por setor, período ou chefia e não invalida quinzena única já confirmada como férias fixa."
$lblHistNota.Location=New-Object Drawing.Point(15,184); $lblHistNota.Size=New-Object Drawing.Size(900,52); $grpHistImp.Controls.Add($lblHistNota)
$btnRecuperarHistorico=New-Button "Recuperar histórico de backup" 950 184 260 32
$grpHistImp.Controls.Add($btnRecuperarHistorico)
$btnRecuperarHistorico.add_Click({Recuperar-HistoricoBackup})

$grpAnuladosImp=New-Object Windows.Forms.GroupBox
$grpAnuladosImp.Text="3. Central de inconsistências / pendências da planilha-base"; $grpAnuladosImp.Location=New-Object Drawing.Point(15,622); $grpAnuladosImp.Size=New-Object Drawing.Size(1240,165)
$tabCfgImport.Controls.Add($grpAnuladosImp)
$lblAnuladosExp=New-Object Windows.Forms.Label
$lblAnuladosExp.Text="Novas escolhas: início deve ser posterior ao fim do período aquisitivo. Escolhas 15+15 incompletas exigem conferência. Férias FIXAS importadas com quinzena única NÃO exigem outra parcela. Não exclua históricos automaticamente."
$lblAnuladosExp.Location=New-Object Drawing.Point(15,28); $lblAnuladosExp.Size=New-Object Drawing.Size(970,55); $grpAnuladosImp.Controls.Add($lblAnuladosExp)
$btnVerAnulados=New-Button "VER INCONSISTÊNCIAS / PENDÊNCIAS" 1000 34 210 38
$btnVerAnulados.BackColor=[Drawing.Color]::FromArgb(255,244,204); $grpAnuladosImp.Controls.Add($btnVerAnulados)
$script:lblAnuladosStatus=New-Object Windows.Forms.Label
$script:lblAnuladosStatus.Location=New-Object Drawing.Point(15,100); $script:lblAnuladosStatus.Size=New-Object Drawing.Size(1180,32)
$script:lblAnuladosStatus.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpAnuladosImp.Controls.Add($script:lblAnuladosStatus)
$btnVerAnulados.add_Click({ Abrir-HistoricoLancamentosAnulados })

# CONFIG > POLÍTICA MENSAL
$grpPoliticaMensal=New-Object Windows.Forms.GroupBox
$grpPoliticaMensal.Text="Limites institucionais e meses de alta demanda"
$grpPoliticaMensal.Location=New-Object Drawing.Point(15,20); $grpPoliticaMensal.Size=New-Object Drawing.Size(1240,330)
$tabCfgPolitica.Controls.Add($grpPoliticaMensal)
$grpPoliticaMensal.Controls.Add((New-Label "Total GERAL de enfermeiros (Assistencial + Gerência + Diretoria)" 15 28 490))
$numTotalEnf=New-Object Windows.Forms.NumericUpDown
$numTotalEnf.Location=New-Object Drawing.Point(15,54); $numTotalEnf.Size=New-Object Drawing.Size(125,26); $numTotalEnf.Minimum=0; $numTotalEnf.Maximum=5000; $numTotalEnf.Value=[decimal][int]$script:Config.total_enfermeiros_planejamento; $grpPoliticaMensal.Controls.Add($numTotalEnf)
# Controle legado mantido invisível apenas para compatibilidade com as rotinas antigas.
$numPctRestrito=New-Object Windows.Forms.NumericUpDown
$numPctRestrito.Minimum=1; $numPctRestrito.Maximum=100; $numPctRestrito.Value=[decimal][math]::Max(1,[math]::Min(100,[int]$script:Config.percentual_meses_restritos))
$numPctRestrito.Visible=$false; $grpPoliticaMensal.Controls.Add($numPctRestrito)
$script:lblCalculoMensal=New-Object Windows.Forms.Label
$script:lblCalculoMensal.Location=New-Object Drawing.Point(155,53); $script:lblCalculoMensal.Size=New-Object Drawing.Size(1050,45); $script:lblCalculoMensal.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpPoliticaMensal.Controls.Add($script:lblCalculoMensal)
$grpPoliticaMensal.Controls.Add((New-Label "Selecione o mês e informe o limite especial em férias equivalentes. Desmarcado = limite normal." 15 110 1000))
$script:chkMesRestrito=@(); $script:numLimiteEspecialMes=@(); $nomesMesCfg=@("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
for($i=0;$i -lt 12;$i++){
    $m=$i+1; $col=$i % 6; $linha=[int][math]::Floor($i/6)
    $x=15+($col*200); $y=144+($linha*54)
    $chk=New-Object Windows.Forms.CheckBox; $chk.Text=$nomesMesCfg[$i]; $chk.Location=New-Object Drawing.Point($x,$y)
    $chk.Size=New-Object Drawing.Size(62,25); $chk.Checked=(@($script:Config.meses_restritos) -contains $m)
    $grpPoliticaMensal.Controls.Add($chk); $script:chkMesRestrito += $chk
    $num=New-Object Windows.Forms.NumericUpDown
    $num.Location=New-Object Drawing.Point(($x+67),$y); $num.Size=New-Object Drawing.Size(109,25)
    $num.DecimalPlaces=1; $num.Increment=[decimal]0.5; $num.Minimum=0; $num.Maximum=5000
    $valor=$null; $limites=$script:Config.limites_especiais_mensais
    if($limites -is [System.Collections.IDictionary]){ $valor=$limites[[string]$m] }
    elseif($null -ne $limites -and $null -ne $limites.PSObject.Properties[[string]$m]){ $valor=$limites.PSObject.Properties[[string]$m].Value }
    $n=[decimal]0; try { if($null -ne $valor){ $n=[decimal]([string]$valor) } } catch { $n=0 }
    if($n -lt 0 -or $n -gt 5000){$n=0}; $num.Value=$n; $num.Enabled=$chk.Checked
    $grpPoliticaMensal.Controls.Add($num); $script:numLimiteEspecialMes += $num
    $chk.Tag=$i
    $chk.add_CheckedChanged({ $ix=[int]$this.Tag; $script:numLimiteEspecialMes[$ix].Enabled=$this.Checked })
}
$btnSalvarPoliticaMensal=New-Button "SALVAR LIMITES" 15 269 195 38; $grpPoliticaMensal.Controls.Add($btnSalvarPoliticaMensal)
$lblPoliticaAviso=New-Object Windows.Forms.Label
$lblPoliticaAviso.Location=New-Object Drawing.Point(230,270); $lblPoliticaAviso.Size=New-Object Drawing.Size(955,48)
$lblPoliticaAviso.Text="Limite especial é um ALERTA de capacidade: não altera férias fixas, não remaneja sozinho e exige justificativa quando houver aprovação excepcional. Valor 0 significa usar o limite normal."
$grpPoliticaMensal.Controls.Add($lblPoliticaAviso)

$grpPoliticaResumo=New-Object Windows.Forms.GroupBox
$grpPoliticaResumo.Text="Como o sistema decide"; $grpPoliticaResumo.Location=New-Object Drawing.Point(15,365); $grpPoliticaResumo.Size=New-Object Drawing.Size(1240,230); $tabCfgPolitica.Controls.Add($grpPoliticaResumo)
$lblPoliticaResumo=New-Object Windows.Forms.Label
$lblPoliticaResumo.Location=New-Object Drawing.Point(18,30); $lblPoliticaResumo.Size=New-Object Drawing.Size(1180,175)
$lblPoliticaResumo.Text="ORDEM SIMPLIFICADA:`r`n1. Importe primeiro as férias fixas confirmadas pelo RH: uma data definida, sem alternativas.`r`n2. Some o comprometimento institucional: 30 dias = 1; 20 dias = 1; cada etapa de 15 dias = 0,5.`r`n3. Capacidade mensal = total de enfermeiros / 12, exceto meses com limite especial configurado; sem bloqueios por setor, turno ou chefia.`r`n4. Procure atender à primeira opção; só examine a 2ª/3ª quando houver excesso.`r`n5. Nova opção só é válida quando começa DEPOIS do fim do período aquisitivo.`r`n6. Quinzena única FIXA não exige informação da outra etapa anterior.`r`n7. Histórico apenas apoia o desempate; não define direito a férias radiológicas.`r`n8. Os 20 dias radiológicos seguem o preenchimento da planilha do RH, não o setor."
$grpPoliticaResumo.Controls.Add($lblPoliticaResumo)

# CONFIG > MANUTENÇÃO / RESET
# V1.0.53: mantém ZERAR PLANEJAMENTO, RESTAURAR SEED e RESET TOTAL REAL, com backup obrigatório validado.
$panelResetGuia=New-Object Windows.Forms.Panel
$panelResetGuia.Location=New-Object Drawing.Point(15,15); $panelResetGuia.Size=New-Object Drawing.Size(1240,82)
$panelResetGuia.BackColor=[Drawing.Color]::FromArgb(255,246,225); $panelResetGuia.BorderStyle="FixedSingle"; $tabCfgManut.Controls.Add($panelResetGuia)
$lblResetGuia=New-Object Windows.Forms.Label
$lblResetGuia.Text="MANUTENÇÃO SEGURA — todo reset cria backup obrigatório e pede DUAS confirmações. Backups existentes nunca são apagados. Leia o que cada botão remove antes de usar."
$lblResetGuia.Location=New-Object Drawing.Point(14,14); $lblResetGuia.Size=New-Object Drawing.Size(1190,50); $lblResetGuia.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $panelResetGuia.Controls.Add($lblResetGuia)

$grpReset=New-Object Windows.Forms.GroupBox
$grpReset.Text="Opções de reset — escolha exatamente o nível necessário"; $grpReset.Location=New-Object Drawing.Point(15,112); $grpReset.Size=New-Object Drawing.Size(1240,600); $tabCfgManut.Controls.Add($grpReset)
$btnResetDecisoes=New-Button "Resetar decisões atuais" 20 32 250 38; $grpReset.Controls.Add($btnResetDecisoes)
$l=New-Object Windows.Forms.Label; $l.Text="Remove somente as opções ACEITAS/decisões. Preserva 1ª/2ª/3ª opções, servidores, períodos aquisitivos, férias fixas e histórico."; $l.Location=New-Object Drawing.Point(290,32); $l.Size=New-Object Drawing.Size(900,42); $grpReset.Controls.Add($l)

$btnResetFixas=New-Button "Remover férias fixas importadas" 20 92 250 38; $grpReset.Controls.Add($btnResetFixas)
$l=New-Object Windows.Forms.Label; $l.Text="Remove somente as férias fixas vindas da planilha de 2027. Não remove férias fixas marcadas manualmente."; $l.Location=New-Object Drawing.Point(290,92); $l.Size=New-Object Drawing.Size(900,42); $grpReset.Controls.Add($l)

$btnResetHistorico=New-Button "Limpar histórico importado" 20 152 250 38; $grpReset.Controls.Add($btnResetHistorico)
$l=New-Object Windows.Forms.Label; $l.Text="Apaga somente o histórico usado no desempate. Lançamentos e cadastros atuais permanecem."; $l.Location=New-Object Drawing.Point(290,152); $l.Size=New-Object Drawing.Size(900,42); $grpReset.Controls.Add($l)

$btnZerarPlanejamento=New-Button "ZERAR PLANEJAMENTO ATUAL" 20 212 250 42; $btnZerarPlanejamento.BackColor=[Drawing.Color]::FromArgb(255,244,204); $btnZerarPlanejamento.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpReset.Controls.Add($btnZerarPlanejamento)
$l=New-Object Windows.Forms.Label; $l.Text="Mantém servidores, setor/período e períodos aquisitivos, mas limpa 1ª/2ª/3ª opções, decisões, férias fixas e histórico. Use para recomeçar o planejamento sem refazer cadastros."; $l.Location=New-Object Drawing.Point(290,208); $l.Size=New-Object Drawing.Size(900,52); $grpReset.Controls.Add($l)

$btnRestaurarSeed=New-Button "Restaurar base inicial (seed)" 20 282 250 38; $grpReset.Controls.Add($btnRestaurarSeed)
$l=New-Object Windows.Forms.Label; $l.Text="Volta exatamente para a base inicial distribuída com o sistema. ATENÇÃO: servidores/períodos existentes no seed voltarão a aparecer."; $l.Location=New-Object Drawing.Point(290,282); $l.Size=New-Object Drawing.Size(900,42); $grpReset.Controls.Add($l)

$btnRestaurarPreReset=New-Button "Restaurar último pré-reset" 20 342 250 38; $grpReset.Controls.Add($btnRestaurarPreReset)
$l=New-Object Windows.Forms.Label; $l.Text="Restaura o backup mais recente criado antes de um reset. Antes da restauração, a base atual também recebe backup."; $l.Location=New-Object Drawing.Point(290,342); $l.Size=New-Object Drawing.Size(900,42); $grpReset.Controls.Add($l)

$btnResetTotal=New-Button "RESET TOTAL REAL — BASE VAZIA" 20 415 250 46; $btnResetTotal.BackColor=[Drawing.Color]::MistyRose; $btnResetTotal.ForeColor=[Drawing.Color]::DarkRed; $btnResetTotal.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpReset.Controls.Add($btnResetTotal)
$l=New-Object Windows.Forms.Label; $l.Text="Apaga TODOS os servidores e períodos aquisitivos da base ativa. Preserva a estrutura: setores, períodos de trabalho, grupos, chefias, limites, política mensal e TODOS os backups. Exige digitar RESETAR."; $l.Location=New-Object Drawing.Point(290,408); $l.Size=New-Object Drawing.Size(900,62); $l.ForeColor=[Drawing.Color]::DarkRed; $grpReset.Controls.Add($l)

$l=New-Object Windows.Forms.Label; $l.Text="IMPORTANTE: 'Restaurar base inicial' e 'RESET TOTAL REAL' são operações diferentes. Para uma base realmente vazia, use RESET TOTAL REAL — BASE VAZIA."; $l.Location=New-Object Drawing.Point(20,500); $l.Size=New-Object Drawing.Size(1170,48); $l.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $grpReset.Controls.Add($l)


# ============================================================
# V1.0.40 - FILTROS LEVES / DEBOUNCE DE ATUALIZAÇÃO
# ============================================================
# WinForms dispara vários eventos em sequência ao trocar um filtro,
# digitar um texto ou carregar um servidor. Em vez de recalcular tudo
# em cada evento, aguardamos alguns milissegundos e executamos somente
# a última atualização solicitada.
$script:SuppressReactiveRefresh=$false

$script:tmrGridFilter=New-Object Windows.Forms.Timer
$script:tmrGridFilter.Interval=220
$script:tmrGridFilter.add_Tick({
    $script:tmrGridFilter.Stop()
    if(-not $script:SuppressReactiveRefresh){
        if($null -ne $script:tabsPrincipal -and $script:tabsPrincipal.SelectedTab -ne $tabLanc){
            $script:LancamentosFiltroPendente=$true
        }else{Refresh-Grid;$script:LancamentosFiltroPendente=$false}
    }
})

$script:tmrPlanejamento=New-Object Windows.Forms.Timer
$script:tmrPlanejamento.Interval=180
$script:tmrPlanejamento.add_Tick({
    $script:tmrPlanejamento.Stop()
    if(-not $script:SuppressReactiveRefresh){ Refresh-PlanejamentoSetor }
})

$script:tmrDashboard=New-Object Windows.Forms.Timer
$script:tmrDashboard.Interval=160
$script:tmrDashboard.add_Tick({
    $script:tmrDashboard.Stop()
    if(-not $script:SuppressReactiveRefresh){
        if($null -ne $script:tabsPrincipal -and $script:tabsPrincipal.SelectedTab -ne $tabDash){
            $script:UiLazyLoaded.Painel=$false
        }else{Refresh-Dashboard;$script:UiLazyLoaded.Painel=$true}
    }
})

$script:tmrPreviaImpacto=New-Object Windows.Forms.Timer
$script:tmrPreviaImpacto.Interval=360
$script:tmrPreviaImpacto.add_Tick({
    $script:tmrPreviaImpacto.Stop()
    if(-not $script:SuppressReactiveRefresh){
        if($null -ne $script:tabsPrincipal -and $script:tabsPrincipal.SelectedTab -ne $tabLanc){
            $script:PreviaImpactoPendente=$true
        }else{Refresh-PreviaImpacto;$script:PreviaImpactoPendente=$false}
    }
})

function Request-GridRefresh {
    if($script:SuppressReactiveRefresh){ return }
    $script:tmrGridFilter.Stop(); $script:tmrGridFilter.Start()
}
function Request-PlanejamentoRefresh {
    if($script:SuppressReactiveRefresh){ return }
    $script:tmrPlanejamento.Stop(); $script:tmrPlanejamento.Start()
}
function Request-DashboardRefresh {
    if($script:SuppressReactiveRefresh){ return }
    $script:tmrDashboard.Stop(); $script:tmrDashboard.Start()
}
function Request-PreviaImpacto {
    if($script:SuppressReactiveRefresh){ return }
    $script:tmrPreviaImpacto.Stop(); $script:tmrPreviaImpacto.Start()
}


# === V127: Relatorio dinamico de conferencia das 3 opcoes (somente leitura) ===

function Abrir-HTMLRelatorioFerias([string]$Html,[string]$Arquivo) {
    $dir=Join-Path $PSScriptRoot 'Relatorios'
    if(-not (Test-Path -LiteralPath $dir)){[void](New-Item -ItemType Directory -Path $dir -Force)}
    $dest=Join-Path $dir $Arquivo
    [IO.File]::WriteAllText($dest,$Html,(New-Object System.Text.UTF8Encoding($false)))
    Start-Process -FilePath $dest
}

function Show-RelatorioAceitesEnfermagem {
    # CORR-R6: equivalencia e consulta de aprovacoes compartilhadas com a Central.
    try {
        $culture=[Globalization.CultureInfo]::GetCultureInfo('pt-BR')
        $parseLocal={ param($str)
            $v=([string]$str).Trim()
            if(-not $v){return $null}
            $d=[datetime]::MinValue
            foreach($fmt in @('yyyy-MM-dd','dd/MM/yyyy','yyyy-MM-ddTHH:mm:ss','yyyy-MM-ddTHH:mm:ss.fff')){
                if([datetime]::TryParseExact($v,$fmt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)){return $d.Date}
            }
            return $null
        }.GetNewClosure()
        $fmt={param([double]$n) return $n.ToString('0.##',[Globalization.CultureInfo]::GetCultureInfo('pt-BR'))}.GetNewClosure()
        $totalEnf=[int]$script:Config.total_enfermeiros_planejamento
        $baseLim=if($totalEnf -gt 0){([double]$totalEnf/12.0)}else{0.0}
        # V154: capturar os 12 limites diretamente da configuracao ativa, fora
        # de qualquer GetNewClosure. Os meses restritos podem vir como strings
        # do JSON ou numeros. Nao alterar configuracoes nem o arquivo JSON.
        $mesesEspeciais=@{}
        foreach($mRestrito in @($script:Config.meses_restritos)){
            $numMes=0
            if([int]::TryParse(([string]$mRestrito).Trim(),[ref]$numMes) -and $numMes -ge 1 -and $numMes -le 12){$mesesEspeciais[$numMes]=$true}
        }
        $limitesCapturados=@{}
        $configEspecial=$script:Config.limites_especiais_mensais
        for($m=1;$m -le 12;$m++){
            $lm=[double]$baseLim
            if($mesesEspeciais.ContainsKey($m)){
                $valor=$null
                if($configEspecial -is [System.Collections.IDictionary]){
                    $valor=$configEspecial[[string]$m]
                    if($null -eq $valor){$valor=$configEspecial[$m]}
                }elseif($null -ne $configEspecial -and $null -ne $configEspecial.PSObject.Properties[[string]$m]){
                    $valor=$configEspecial.PSObject.Properties[[string]$m].Value
                }
                $parsed=[double]0
                if($null -ne $valor -and [double]::TryParse(([string]$valor).Replace(',','.'),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$parsed) -and $parsed -gt 0){$lm=$parsed}
            }
            $limitesCapturados[$m]=$lm
        }
        # Peso por competencia: 30 dias = 1 para meses com 15+ dias;
        # 20 e 15 dias = apenas um mes de maior intersecao, empate no primeiro.
        $peso={param([datetime]$ini,[datetime]$fim,[int]$ano,[int]$mes)
            if($fim -lt $ini){return [double]0}
            $dias=($fim-$ini).Days+1
            $first=[datetime]::new($ano,$mes,1);$last=$first.AddMonths(1).AddDays(-1)
            $a=if($ini -gt $first){$ini}else{$first};$z=if($fim -lt $last){$fim}else{$last}
            $overlap=if($z -ge $a){($z-$a).Days+1}else{0}
            if($overlap -eq 0){return [double]0}
            if($dias -ge 29){return [double]$(if($overlap -ge 15){1}else{0})}
            if($dias -ne 15 -and $dias -ne 20){return [double]0}
            $startMonth=[datetime]::new($ini.Year,$ini.Month,1)
            $best=$startMonth;$bestDays=-1
            $cur=$startMonth
            while($cur -le $fim){
                $lastCur=$cur.AddMonths(1).AddDays(-1)
                $ac=if($ini -gt $cur){$ini}else{$cur}
                $zc=if($fim -lt $lastCur){$fim}else{$lastCur}
                $dc=if($zc -ge $ac){($zc-$ac).Days+1}else{0}
                if($dc -gt $bestDays){$bestDays=$dc;$best=$cur}
                $cur=$cur.AddMonths(1)
            }
            if($best.Year -eq $ano -and $best.Month -eq $mes){return [double]$(if($dias -eq 15){0.5}else{1.0})}
            return [double]0
        }.GetNewClosure()
        # Cada bloco possui sua origem para distinguir a primeira e segunda etapa.
        $blocos=New-Object 'System.Collections.Generic.List[object]'
        foreach($r in @($script:Records)){
            if($null -eq $r){continue}
            $key=Get-ChaveFeriasRegistro $r
            foreach($bl in @(Get-BlocosConfirmadosRegistro $r)){
                $a=[datetime]$bl.inicio;$z=[datetime]$bl.fim
                if($z -lt $a){continue}
                $etapa=if(($z-$a).Days -eq 19){0}elseif($null -ne $bl.PSObject.Properties['bloco']){[int]$bl.bloco}else{1}
                [void]$blocos.Add([pscustomobject]@{Key=$key;Registro=[int]$r.id;RegistroFonte=$r;Inicio=$a;Fim=$z;Etapa=$etapa;Fixa=(Test-RegistroFeriasBloqueadas $r);Matricula=[string]$r.matricula;Nome=[string]$r.nome;Setor=[string]$r.setor})
            }
        }
        $rows=New-Object 'System.Collections.Generic.List[object]'
        $nominais=New-Object 'System.Collections.Generic.List[object]'
        $total30=0;$total15a=0;$total15b=0;$geral=0.0
        $months=@('jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez')
        foreach($year in @(2027,2028)){
            foreach($month in 1..12){
                $c30=0;$c15a=0;$c15b=0
                $seen=@{}
                foreach($b in $blocos.ToArray()){
                    $days=($b.Fim-$b.Inicio).Days+1
                    if($days -notin @(15,20,30)){continue}
                    $w=[double](& $peso $b.Inicio $b.Fim $year $month)
                    if($w -le 0){continue}
                    $blockKey=$b.Key+'|'+$b.Inicio.ToString('yyyyMMdd')+'|'+$b.Fim.ToString('yyyyMMdd')
                    if($seen.ContainsKey($blockKey)){continue}
                    $seen[$blockKey]=$true
                    $categoria='d30'
                    if($days -in @(20,30)){$c30++}
                    else {
                        # Somente neste relatorio: a quinzena e a metade do MES
                        # de competencia (1 a 15 ou 16 ao fim), nao a etapa 1/2
                        # do parcelamento do servidor. Em travessia de meses,
                        # usa apenas os dias dentro da competencia atribuida.
                        $mesIni=[datetime]::new($year,$month,1)
                        $mesFim=$mesIni.AddMonths(1).AddDays(-1)
                        $sobreIni=if($b.Inicio -gt $mesIni){$b.Inicio}else{$mesIni}
                        $sobreFim=if($b.Fim -lt $mesFim){$b.Fim}else{$mesFim}
                        $diasPrimeira=0; $diasSegunda=0
                        if($sobreIni -le $sobreFim){
                            $fimPrimeira=$mesIni.AddDays(14)
                            $fimA=if($sobreFim -lt $fimPrimeira){$sobreFim}else{$fimPrimeira}
                            if($fimA -ge $sobreIni){$diasPrimeira=($fimA-$sobreIni).Days+1}
                            $iniSegunda=$mesIni.AddDays(15)
                            $iniB=if($sobreIni -gt $iniSegunda){$sobreIni}else{$iniSegunda}
                            if($sobreFim -ge $iniB){$diasSegunda=($sobreFim-$iniB).Days+1}
                        }
                        if($diasPrimeira -gt $diasSegunda){$c15a++;$categoria='i15'}
                        elseif($diasSegunda -gt $diasPrimeira){$c15b++;$categoria='f15'}
                        elseif($sobreIni.Day -le 15){$c15a++;$categoria='i15'}
                        else{$c15b++;$categoria='f15'}
                    }
                    [void]$nominais.Add([pscustomobject]@{
                        chave=$b.Key
                        registro=[int]$b.Registro
                        mes=($months[$month-1]+'/'+[string]$year)
                        setor=([string]$b.Setor).Trim()
                        matricula=[string]$b.Matricula
                        nome=[string]$b.Nome
                        inicio=$b.Inicio.ToString('dd/MM/yyyy')
                        fim=$b.Fim.ToString('dd/MM/yyyy')
                        modalidade=$(if($days -eq 20){'FR 20 dias'}elseif($days -eq 30){'30 dias'}else{'15 dias'})
                        origem=$(if([bool]$b.Fixa){'Fixa'}else{'Aprovada'})
                        categoria=$categoria
                        peso=$w
                        peso_institucional=[double](Get-PesoOpcaoInstitucionalMes (Get-OpcaoConfirmadaRegistro $b.RegistroFonte) $year $month)
                    })
                }
                $eq=[double](Get-ContagemInstitucionalAprovadaMes $year $month)
                $limit=[double]$limitesCapturados[$month]
                $class=if($limit -le 0){'unconfigured'}elseif($eq -gt $limit + 0.00001){'over'}elseif([math]::Abs($eq-$limit) -lt 0.00001){'at'}else{'under'}
                [void]$rows.Add([pscustomobject]@{Month=$months[$month-1]+'/'+[string]$year;Days30=$c30;Start15=$c15a;End15=$c15b;Total=$eq;Limit=$limit;Class=$class})
                $total30+=$c30;$total15a+=$c15a;$total15b+=$c15b;$geral+=$eq
            }
        }
        # Alerta preventivo: nao representar meses especiais sem valor valido
        # como se a capacidade normal estivesse aprovada.
        $nominaisJson=ConvertTo-Json -InputObject @($nominais.ToArray()) -Depth 5 -Compress
        $nominaisJson=([string]$nominaisJson).Replace('<','\u003c').Replace('>','\u003e').Replace('&','\u0026')
        $sb=New-Object Text.StringBuilder
        [void]$sb.Append('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Relatório de aceites 2027–2028 | consulta nominal</title><style>@page{size:A4 portrait;margin:10mm}body{font:13px Arial;margin:18px;color:#182430}h1{font-size:22px;margin-bottom:6px}p{line-height:1.4}.cards{display:flex;gap:16px;margin:15px 0}.card{border:1px solid #9cabb6;padding:12px;border-radius:6px;min-width:180px}.card strong{font-size:23px;display:block;margin-top:6px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #a2adb4;padding:6px;text-align:center}th{background:#dce9f1}.under{background:#237a40;color:#fff;font-weight:bold}.at{background:#f0cc43;color:#111;font-weight:bold}.over{background:#bb2533;color:#fff;font-weight:bold}.unconfigured{background:#e3e8eb;color:#222}.total{background:#e9f2f8;font-weight:bold}.toolbar{text-align:right}.filtros{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin:10px 0}.filtros select{padding:6px;min-width:240px}.clicavel{cursor:pointer;text-decoration:underline;text-underline-offset:2px}.clicavel:hover{filter:brightness(.88)}#detalhes{margin-top:16px}#detalhes table{font-size:12px}#detalhes td{text-align:left}.hidden{display:none} @media print{.toolbar{display:none}thead{display:table-header-group}}</style></head><body>')
        [void]$sb.Append('<div class="toolbar"><button onclick="window.print()">Imprimir / Salvar em PDF</button></div><h1>Relatório de aceites — 2027 e 2028</h1>')
        [void]$sb.Append('<p>Férias fixas e opções efetivamente aprovadas. FR de 20 dias incluídas na coluna 30 DIAS. Quinzenas de 15 dias = 0,5 cada. Valores por competência institucional. As colunas de modalidades contam parcelas; o total mensal usa o maior peso entre comum e FR, limitado a 1 por servidor/aquisitivo, e pode diferir da soma dessas colunas.</p>')
        [void]$sb.Append('<div class="cards"><div class="card">TOTAL IDEAL MÊS<strong>'+(& $fmt $baseLim)+'</strong></div><div class="card">TOTAL ENFERMEIROS<strong>'+$totalEnf+'</strong></div></div>')
        [void]$sb.Append('<div class="filtros"><label for="filtro-setor">Setor:</label><select id="filtro-setor"><option value="">TODOS OS SETORES</option></select><button id="limpar" type="button">Limpar filtro</button><span id="contador"></span></div>')
        [void]$sb.Append('<p>Clique em qualquer quantidade para consultar os servidores e períodos correspondentes. O filtro por setor recalcula toda a tabela.</p>')
        [void]$sb.Append('<table id="resumo"><thead><tr><th>MÊS/ANO</th><th>30 DIAS<br>(inclui FR 20)</th><th>15 DIAS INÍCIO</th><th>15 DIAS TÉRMINO</th><th>TOTAL POR MÊS</th><th>LIMITE</th></tr></thead><tbody>')
        foreach($r in $rows.ToArray()){
            [void]$sb.Append('<tr><td>'+$r.Month+'</td><td>'+$r.Days30+'</td><td>'+$r.Start15+'</td><td>'+$r.End15+'</td><td class="'+$r.Class+'">'+(& $fmt $r.Total)+'</td><td>'+(& $fmt $r.Limit)+'</td></tr>')
        }
        [void]$sb.Append('<tr class="total"><td>TOTAL GERAL</td><td>'+$total30+'</td><td>'+$total15a+'</td><td>'+$total15b+'</td><td>'+(& $fmt $geral)+'</td><td>—</td></tr></tbody></table>')
        [void]$sb.Append('<p>Limites especiais configurados são aplicados a janeiro, julho, dezembro e a quaisquer outros meses marcados. Verde: abaixo do limite; amarelo: no limite; vermelho: acima do limite; cinza: limite não configurado.</p>')
        [void]$sb.Append('<section id="detalhes"><h2 id="titulo-detalhes">Detalhamento nominal — clique em um número acima</h2><div id="lista-detalhes"></div></section>')
        [void]$sb.Append('<script id="dados" type="application/json">'+$nominaisJson+'</script>')
        $js=@'
<script>
(function(){
  'use strict';
  const registros=JSON.parse(document.getElementById('dados').textContent);
  const listaMeses=Array.from(document.querySelectorAll('#resumo tbody tr:not(.total)')).map(tr=>({mes:tr.cells[0].textContent.trim(),limite:Number(tr.cells[5].textContent.trim().replace(',','.'))}));
  const select=document.getElementById('filtro-setor'),resumo=document.querySelector('#resumo tbody');
  const nomes=Array.from(new Set(registros.map(r=>r.setor||'SETOR NÃO INFORMADO'))).sort((a,b)=>a.localeCompare(b,'pt-BR'));
  nomes.forEach(s=>{const op=document.createElement('option');op.value=s;op.textContent=s;select.appendChild(op)});
  let atual=null;
  function filtrados(){return registros.filter(r=>!select.value||(r.setor||'SETOR NÃO INFORMADO')===select.value)}
  function number(x){return x.toLocaleString('pt-BR',{maximumFractionDigits:2})}
  function critico(total,lim){return lim<=0?'unconfigured':total>lim+0.00001?'over':Math.abs(total-lim)<0.00001?'at':'under'}
  function build(){
    const dados=filtrados();document.getElementById('contador').textContent=`${dados.length} ocorrências no período`;
    resumo.textContent='';let totals={d30:0,i15:0,f15:0,eq:0};
    listaMeses.forEach(m=>{
      const linha=dados.filter(r=>r.mes===m.mes);
      const d30=linha.filter(r=>r.categoria==='d30').length,i15=linha.filter(r=>r.categoria==='i15').length,f15=linha.filter(r=>r.categoria==='f15').length;
      const porAquisitivo=new Map();
      linha.forEach(r=>porAquisitivo.set(r.chave,Math.max(porAquisitivo.get(r.chave)||0,Number(r.peso_institucional))));
      const eq=Array.from(porAquisitivo.values()).reduce((sum,peso)=>sum+peso,0); totals.d30+=d30;totals.i15+=i15;totals.f15+=f15;totals.eq+=eq;
      const tr=document.createElement('tr');
      [m.mes,d30,i15,f15,number(eq),number(m.limite)].forEach((value,index)=>{
        const td=document.createElement('td');td.textContent=value;
        if(index===4)td.className=critico(eq,m.limite);
        if(index>=1&&index<=4){td.classList.add('clicavel');td.title='Clique para ver os servidores';td.addEventListener('click',()=>detalhar(m.mes,index))}
        tr.appendChild(td);
      });resumo.appendChild(tr);
    });
    const tr=document.createElement('tr');tr.className='total';
    ['TOTAL GERAL',totals.d30,totals.i15,totals.f15,number(totals.eq),'—'].forEach(v=>{const td=document.createElement('td');td.textContent=v;tr.appendChild(td)});
    resumo.appendChild(tr);
    if(atual)detalhar(atual.mes,atual.indice);
  }
  function detalhar(mes,indice){
    atual={mes,indice};
    const etiquetas={1:'30 DIAS (inclui FR 20)',2:'15 DIAS INÍCIO',3:'15 DIAS TÉRMINO',4:'TOTAL POR MÊS'};
    const categorias={1:'d30',2:'i15',3:'f15'};
    const dados=filtrados().filter(r=>r.mes===mes&&(indice===4||r.categoria===categorias[indice]));
    document.getElementById('titulo-detalhes').textContent=`${mes} — ${etiquetas[indice]} — ${dados.length} ocorrência(s)`;
    const destino=document.getElementById('lista-detalhes');destino.textContent='';
    if(!dados.length){destino.textContent='Nenhum registro para os filtros atuais.';return}
    const tbl=document.createElement('table'),thead=document.createElement('thead'),header=document.createElement('tr');
    ['Matrícula','Servidor','Setor','Início','Término','Modalidade','Origem','Equivalente'].forEach(h=>{const th=document.createElement('th');th.textContent=h;header.appendChild(th)});
    thead.appendChild(header);tbl.appendChild(thead);const tbody=document.createElement('tbody');
    dados.sort((a,b)=>(a.nome||'').localeCompare(b.nome||'','pt-BR')).forEach(r=>{
      const row=document.createElement('tr');[r.matricula,r.nome,r.setor,r.inicio,r.fim,r.modalidade,r.origem,number(r.peso)].forEach(v=>{const td=document.createElement('td');td.textContent=v;row.appendChild(td)});tbody.appendChild(row)
    });tbl.appendChild(tbody);destino.appendChild(tbl);
    document.getElementById('detalhes').scrollIntoView({behavior:'smooth',block:'start'});
  }
  select.addEventListener('change',build);
  document.getElementById('limpar').addEventListener('click',()=>{select.value='';build()});
  build();
})();
</script>
'@
        [void]$sb.Append($js)
        [void]$sb.Append('</body></html>')
        $dir=Join-Path $PSScriptRoot 'Relatorios'
        if(-not [IO.Directory]::Exists($dir)){[void][IO.Directory]::CreateDirectory($dir)}
        $output=Join-Path $dir ('RELATORIO_ACEITES_2027_2028_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.html')
        [IO.File]::WriteAllText($output,$sb.ToString(),(New-Object Text.UTF8Encoding($false)))
        Start-Process -FilePath $output
    }catch{
        [Windows.Forms.MessageBox]::Show(('Falha no relatório de aceites: '+$_.Exception.Message+' | Linha: '+$_.InvocationInfo.ScriptLineNumber),'Relatório de aceites')|Out-Null
    }
}

function Show-RelatorioConferenciaOpcoes {
    # V1.0.140 - janela organizada em dois blocos fixos (resumo acima + detalhes abaixo),
    # sem sobreposicao visual e com cabecalhos nativos sempre visiveis.
    $dialog=New-Object Windows.Forms.Form
    $dialog.Text='Conferencia de ferias | opcoes, meses e modalidades - V1.0.157'
    $dialog.Size=New-Object Drawing.Size(1365,910)
    $dialog.MinimumSize=New-Object Drawing.Size(1120,760)
    $dialog.StartPosition='CenterScreen'
    $dialog.Font=New-Object Drawing.Font('Segoe UI',9)

    # V139: Layout raiz com duas linhas exclusivas. Impede que o painel de filtros
    # cubra o inicio da grade, seus cabecalhos e os primeiros meses.
    $root=New-Object Windows.Forms.TableLayoutPanel
    $root.Dock='Fill';$root.ColumnCount=1;$root.RowCount=2
    $root.Margin=New-Object Windows.Forms.Padding(0)
    $root.Padding=New-Object Windows.Forms.Padding(0)
    [void]$root.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
    [void]$root.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,213)))
    [void]$root.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
    $dialog.Controls.Add($root)
    $top=New-Object Windows.Forms.Panel
    $top.Dock='Fill';$top.Margin=New-Object Windows.Forms.Padding(0)
    $root.Controls.Add($top,0,0)

    $lbl=New-Object Windows.Forms.Label;$lbl.Text='Opcao:';$lbl.SetBounds(12,11,55,23);$top.Controls.Add($lbl)
    $select=New-Object Windows.Forms.ComboBox
    $select.DropDownStyle='DropDownList';$select.SetBounds(68,9,150,27)
    [void]$select.Items.AddRange([object[]]@('1a opcao','2a opcao','3a opcao'))
    $select.SelectedIndex=0;$top.Controls.Add($select)

    $lblAno=New-Object Windows.Forms.Label;$lblAno.Text='Ano:';$lblAno.SetBounds(232,11,40,23);$top.Controls.Add($lblAno)
    $year=New-Object Windows.Forms.ComboBox
    $year.DropDownStyle='DropDownList';$year.SetBounds(274,9,80,27)
    [void]$year.Items.AddRange([object[]]@('2027','2028'));$year.SelectedIndex=0;$top.Controls.Add($year)

    $lblMes=New-Object Windows.Forms.Label;$lblMes.Text='Mes:';$lblMes.SetBounds(371,11,40,23);$top.Controls.Add($lblMes)
    $month=New-Object Windows.Forms.ComboBox
    $month.DropDownStyle='DropDownList';$month.SetBounds(412,9,112,27)
    [void]$month.Items.AddRange([object[]]@('Todos','Janeiro','Fevereiro','Marco','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'))
    $month.SelectedIndex=0;$top.Controls.Add($month)

    $lblModal=New-Object Windows.Forms.Label;$lblModal.Text='Modalidade:';$lblModal.SetBounds(543,11,83,23);$top.Controls.Add($lblModal)
    $modality=New-Object Windows.Forms.ComboBox
    $modality.DropDownStyle='DropDownList';$modality.SetBounds(625,9,130,27)
    [void]$modality.Items.AddRange([object[]]@('Todas','Comuns','30 dias','15+15','FR 20 dias','Fixas'))
    $modality.SelectedIndex=0;$top.Controls.Add($modality)

    $lblSearch=New-Object Windows.Forms.Label;$lblSearch.Text='Pesquisar:';$lblSearch.SetBounds(772,11,70,23);$top.Controls.Add($lblSearch)
    $search=New-Object Windows.Forms.TextBox;$search.SetBounds(844,9,260,26);$top.Controls.Add($search)

    $lblSetor=New-Object Windows.Forms.Label;$lblSetor.Text='Setor:';$lblSetor.SetBounds(12,45,52,24);$top.Controls.Add($lblSetor)
    $sector=New-Object Windows.Forms.ComboBox
    $sector.DropDownStyle='DropDownList';$sector.SetBounds(68,43,218,27)
    [void]$sector.Items.Add('Todos');$sector.SelectedIndex=0;$top.Controls.Add($sector)

    $lblPeriod=New-Object Windows.Forms.Label;$lblPeriod.Text='Periodo:';$lblPeriod.SetBounds(300,45,60,24);$top.Controls.Add($lblPeriod)
    $period=New-Object Windows.Forms.ComboBox
    $period.DropDownStyle='DropDownList';$period.SetBounds(362,43,155,27)
    [void]$period.Items.Add('Todos');$period.SelectedIndex=0;$top.Controls.Add($period)

    $btnRefresh=New-Object Windows.Forms.Button;$btnRefresh.Text='Atualizar registros';$btnRefresh.SetBounds(535,43,141,29);$top.Controls.Add($btnRefresh)
    $btnCsv=New-Object Windows.Forms.Button;$btnCsv.Text='Exportar CSV';$btnCsv.SetBounds(684,43,116,29);$top.Controls.Add($btnCsv)
    $btnPdf=New-Object Windows.Forms.Button;$btnPdf.Text='Visualizar / PDF';$btnPdf.SetBounds(807,43,140,29);$top.Controls.Add($btnPdf)
    $btnAll=New-Object Windows.Forms.Button;$btnAll.Text='Marcar colunas';$btnAll.SetBounds(954,43,128,29);$top.Controls.Add($btnAll)
    $btnNone=New-Object Windows.Forms.Button;$btnNone.Text='Limpar colunas';$btnNone.SetBounds(1090,43,126,29);$top.Controls.Add($btnNone)

    # Modo explicito: demanda original, compromissos aprovados ou opcoes pendentes.
    $lblModo=New-Object Windows.Forms.Label
    $lblModo.Text='Tipo de analise:';$lblModo.SetBounds(12,80,108,22);$top.Controls.Add($lblModo)
    $modo=New-Object Windows.Forms.ComboBox
    $modo.DropDownStyle='DropDownList';$modo.SetBounds(123,78,244,27)
    [void]$modo.Items.AddRange([object[]]@('Solicitacoes originais','Programacao aprovada','Pendencias'))
    $modo.SelectedIndex=1;$top.Controls.Add($modo)
    $lblFields=New-Object Windows.Forms.Label;$lblFields.Text='Colunas exibidas e exportadas (marque/desmarque):';$lblFields.SetBounds(12,110,450,19);$top.Controls.Add($lblFields)
    $checks=New-Object Windows.Forms.CheckedListBox
    $checks.CheckOnClick=$true;$checks.MultiColumn=$true;$checks.ColumnWidth=160
    $checks.SetBounds(12,131,1215,48);$checks.Anchor='Top,Left,Right';$top.Controls.Add($checks)

    $info=New-Object Windows.Forms.Label;$info.SetBounds(12,184,1305,22);$info.Anchor='Top,Left,Right';$info.Text='';$top.Controls.Add($info)

    $body=New-Object Windows.Forms.TableLayoutPanel
    $body.Dock='Fill';$body.Margin=New-Object Windows.Forms.Padding(0)
    $body.ColumnCount=1;$body.RowCount=2
    [void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle -ArgumentList @([Windows.Forms.SizeType]::Percent,100)))
    [void]$body.RowStyles.Add((New-Object Windows.Forms.RowStyle -ArgumentList @([Windows.Forms.SizeType]::Percent,55)))
    [void]$body.RowStyles.Add((New-Object Windows.Forms.RowStyle -ArgumentList @([Windows.Forms.SizeType]::Percent,45)))
    $root.Controls.Add($body,0,1)

    $summaryHost=New-Object Windows.Forms.TableLayoutPanel
    $summaryHost.Dock='Fill';$summaryHost.Margin=New-Object Windows.Forms.Padding(8,6,8,6)
    $summaryHost.ColumnCount=1;$summaryHost.RowCount=2
    [void]$summaryHost.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
    [void]$summaryHost.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,28)))
    [void]$summaryHost.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
    $body.Controls.Add($summaryHost,0,0)

    $tip=New-Object Windows.Forms.Label
    $tip.Text='RESUMO MENSAL (12 MESES): clique em qualquer numero para detalhar o mes; Fixas, Comuns e FR filtram por modalidade. Saldo: vermelho = acima; amarelo = limite; verde = disponivel.'
    $tip.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
    $tip.ForeColor=[Drawing.Color]::FromArgb(20,62,100)
    $tip.Dock='Top'
    $tip.Height=24
    $tip.Margin=New-Object Windows.Forms.Padding(0)
    $summaryHost.Controls.Add($tip,0,0)

    $summary=New-Object Windows.Forms.DataGridView
    $summary.Dock='Fill';$summary.ReadOnly=$true;$summary.AllowUserToAddRows=$false;$summary.AllowUserToDeleteRows=$false
    $summary.RowHeadersVisible=$false;$summary.AutoGenerateColumns=$false;$summary.AutoSizeColumnsMode='Fill'
    $summary.SelectionMode='FullRowSelect';$summary.MultiSelect=$false
    $summary.EnableHeadersVisualStyles=$false;$summary.BackgroundColor=[Drawing.Color]::White
    $summary.ColumnHeadersVisible=$true;$summary.ColumnHeadersHeightSizeMode='DisableResizing';$summary.ColumnHeadersHeight=34
    $summary.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
    $summary.ColumnHeadersDefaultCellStyle.Alignment='MiddleCenter'
    $summary.DefaultCellStyle.Alignment='MiddleCenter';$summary.DefaultCellStyle.Font=New-Object Drawing.Font('Segoe UI',10)
    $summary.RowTemplate.Height=28;$summary.AllowUserToResizeRows=$false
    $summary.AlternatingRowsDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(242,247,251)
    foreach($colDef in @(
        @('Mes','Mes',90),@('Fixas','Fixas',85),@('30 dias','30 dias',85),@('15+15','15+15',85),@('Comuns','Comuns',85),@('FR 20 dias','FR 20 dias',95),
        @('Total solicit.','Total',95),@('Servidores distintos','Serv. distintos',110),@('Equivalentes','Equivalentes',105),
        @('Limite','Limite',90),@('Saldo','Saldo',90)
    )){
        $c=New-Object Windows.Forms.DataGridViewTextBoxColumn
        $c.Name=$colDef[0];$c.DataPropertyName=$colDef[0];$c.HeaderText=$colDef[1];$c.Width=[int]$colDef[2];$c.ReadOnly=$true
        [void]$summary.Columns.Add($c)
    }
    $summary.Margin=New-Object Windows.Forms.Padding(0)
    $summaryHost.Controls.Add($summary,0,1)

    $detailHost=New-Object Windows.Forms.TableLayoutPanel
    $detailHost.Dock='Fill';$detailHost.Margin=New-Object Windows.Forms.Padding(8,0,8,8)
    $detailHost.ColumnCount=1;$detailHost.RowCount=2
    [void]$detailHost.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
    [void]$detailHost.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,26)))
    [void]$detailHost.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
    $body.Controls.Add($detailHost,0,1)

    $detailTitle=New-Object Windows.Forms.Label
    $detailTitle.Text='DETALHAMENTO NOMINAL'
    $detailTitle.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
    $detailTitle.ForeColor=[Drawing.Color]::FromArgb(20,62,100)
    $detailTitle.Dock='Top'
    $detailTitle.Height=22
    $detailTitle.Margin=New-Object Windows.Forms.Padding(0)
    $detailHost.Controls.Add($detailTitle,0,0)

    $grid=New-Object Windows.Forms.DataGridView
    $grid.Dock='Fill';$grid.ReadOnly=$true;$grid.AllowUserToAddRows=$false;$grid.AllowUserToDeleteRows=$false
    $grid.RowHeadersVisible=$false;$grid.AutoGenerateColumns=$false;$grid.AutoSizeColumnsMode='None'
    $grid.SelectionMode='FullRowSelect';$grid.MultiSelect=$false;$grid.EnableHeadersVisualStyles=$false
    $grid.ColumnHeadersVisible=$true;$grid.ColumnHeadersHeightSizeMode='DisableResizing';$grid.ColumnHeadersHeight=33
    $grid.ColumnHeadersDefaultCellStyle.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
    $grid.BackgroundColor=[Drawing.Color]::White;$grid.ClipboardCopyMode='EnableAlwaysIncludeHeaderText'
    $grid.AllowUserToResizeRows=$false;$grid.RowTemplate.Height=26
    $grid.Margin=New-Object Windows.Forms.Padding(0)
    $detailHost.Controls.Add($grid,0,1)

    $fields=[ordered]@{
        'Matricula'='matricula';'Servidor'='nome';'Setor'='setor';'Periodo trabalho'='periodo';
        'Aquisitivo inicio'='aquisitivo_inicio';'Aquisitivo fim'='aquisitivo_fim';
        'Modalidade'='modalidade';'Periodo no mes'='mes_periodo';'Tipo ferias comuns'='tipo';
        'Comum inicio 1'='inicio1';'Comum fim 1'='fim1';
        'Comum inicio 2'='inicio2';'Comum fim 2'='fim2';
        'Periodo FR 20'='fr_periodo';
        'Fixa inicio'='fixo_inicio';'Fixa fim'='fixo_fim';
        'Opcao comum aprovada'='opcao_aprovada';'Opcao FR aprovada'='fr_opcao_aprovada';
        'Situacao'='situacao';'Observacoes'='observacoes'
    }
    foreach($name in $fields.Keys){
        $ix=$checks.Items.Add($name)
        if(@('Matricula','Servidor','Setor','Periodo trabalho','Aquisitivo inicio','Aquisitivo fim','Modalidade','Periodo no mes','Tipo ferias comuns','Periodo FR 20') -contains $name){$checks.SetItemChecked($ix,$true)}
    }

    $store=[pscustomobject]@{Rows=@();Records=@();Shown=$null;Monthly=$null;Refreshing=$false}
    $dbPathForReport=[string]$script:DbFile
    $store.Records=@($script:Records)

    $getChosen={
        return @(for($i=0;$i -lt $checks.Items.Count;$i++){if($checks.GetItemChecked($i)){[string]$checks.Items[$i]}})
    }.GetNewClosure()

    $dateBR={param($val)
        $v=[string]$val
        if(-not $v){return ''}
        $d=[datetime]::MinValue
        if([datetime]::TryParseExact($v,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)){return $d.ToString('dd/MM/yyyy')}
        return $v
    }.GetNewClosure()

    $monthHit={param([string]$start,[string]$end,[int]$y,[int]$m)
        $d1=[datetime]::MinValue;$d2=[datetime]::MinValue
        if(-not [datetime]::TryParseExact($start,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d1)){return $false}
        if(-not [datetime]::TryParseExact($end,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d2)){return $false}
        if($d2 -lt $d1){return $false}
        $a=[datetime]::new($y,$m,1);$z=$a.AddMonths(1).AddDays(-1)
        return ($d1 -le $z -and $d2 -ge $a)
    }.GetNewClosure()

    $pesoInstitucionalRelatorio = (Get-Command -Name 'Get-PesoBlocoInstitucionalMes' -CommandType Function -ErrorAction Stop).ScriptBlock
    $limiteInstitucionalRelatorio = (Get-Command -Name 'Get-LimiteInstitucionalMes' -CommandType Function -ErrorAction Stop).ScriptBlock

    # V137: configurar colunas diretamente no mesmo evento, sem scriptblock aninhado.
    # DataGridView gera as colunas a partir do DataTable, com cabeçalhos nativos.
    $grid.AutoGenerateColumns=$true
    $columnWidths=@{}
    $grid.add_ColumnWidthChanged({param($sender,$e)
        if($null -ne $e.Column -and $e.Column.Name -and -not $store.Refreshing){$columnWidths[[string]$e.Column.Name]=[int]$e.Column.Width}
    }.GetNewClosure())

    $refresh={
      if($store.Refreshing){return};$store.Refreshing=$true
      $etapa='Iniciar filtros'
      try {
        $n=$select.SelectedIndex+1;$y=[int]$year.SelectedItem;$m=$month.SelectedIndex
        $choice=[string]$modality.SelectedItem;$term=$search.Text.Trim()
        $sect=[string]$sector.SelectedItem;$per=[string]$period.SelectedItem
        $chosen=@(& $getChosen)
        if($chosen.Count -eq 0){$info.Text='Marque ao menos uma coluna.';return}

        $etapa='Criar resumo mensal'
        $monthly=New-Object Data.DataTable
        foreach($h in @('Mes','Fixas','30 dias','15+15','Comuns','FR 20 dias','Total solicit.','Servidores distintos','Equivalentes','Limite','Saldo')){[void]$monthly.Columns.Add($h,[string])}
        $counts=@{};for($mm=1;$mm -le 12;$mm++){$counts[$mm]=@{C=@{};D30=@{};D15=@{};F=@{};X=@{};All=@{};Peso=@{}}}
        $items=New-Object Collections.Generic.List[object]

        $etapa='Percorrer registros e datas'
        foreach($r in $store.Records){
            if($null -eq $r){continue}
            if($sect -and $sect -ne 'Todos' -and [string]$r.setor -ne $sect){continue}
            if($per -and $per -ne 'Todos' -and [string]$r.periodo -ne $per){continue}
            if($term -and ([string]$r.nome -notlike "*$term*") -and ([string]$r.matricula -notlike "*$term*")){continue}
            $analysis=[string]$modo.SelectedItem
            $apC=[int]$r.opcao_aprovada
            $apF=[int]$r.fr_opcao_aprovada
            $modalities=New-Object Collections.Generic.List[object]
            # Cada modalidade usa sua escolha aprovada INDEPENDENTEMENTE.
            $nC=$n; $nF=$n
            if($analysis -eq 'Programacao aprovada'){
                $nC=$apC; $nF=$apF
            }
            if($analysis -eq 'Pendencias'){
                if($apC -gt 0){$nC=0}
                if($apF -gt 0){$nF=0}
            }
            if(-not [bool]$r.ferias_bloqueadas -and $nC -ge 1 -and $nC -le 3){
                $opC=$r.("opcao$nC")
                if($null -ne $opC -and [string]$opC.inicio1 -and [string]$opC.fim1 -and [string]$opC.tipo -ne '20 DIAS'){
                    $ranges=New-Object Collections.Generic.List[object]
                    [void]$ranges.Add([pscustomobject]@{S=[string]$opC.inicio1;E=[string]$opC.fim1})
                    if([string]$opC.inicio2 -and [string]$opC.fim2){[void]$ranges.Add([pscustomobject]@{S=[string]$opC.inicio2;E=[string]$opC.fim2})}
                    [void]$modalities.Add([pscustomobject]@{Kind='Comuns';Op=$opC;Numero=$nC;Ranges=$ranges.ToArray()})
                }
            }
            if(-not [bool]$r.ferias_bloqueadas -and $nF -ge 1 -and $nF -le 3){
                $opF=$r.("opcao$nF")
                if($null -ne $opF -and [string]$opF.fr_inicio -and [string]$opF.fr_fim){
                    [void]$modalities.Add([pscustomobject]@{Kind='FR 20 dias';Op=$opF;Numero=$nF;Ranges=@([pscustomobject]@{S=[string]$opF.fr_inicio;E=[string]$opF.fr_fim})})
                }
            }
            if($analysis -ne 'Pendencias' -and [bool]$r.ferias_bloqueadas -and [string]$r.fixo_inicio -and [string]$r.fixo_fim){
                $faixasFixas=@([pscustomobject]@{S=[string]$r.fixo_inicio;E=[string]$r.fixo_fim})
                foreach($adicional in @($r.fixos_adicionais)){
                    if($null -ne $adicional -and [string]$adicional.inicio -and [string]$adicional.fim){$faixasFixas += [pscustomobject]@{S=[string]$adicional.inicio;E=[string]$adicional.fim}}
                }
                [void]$modalities.Add([pscustomobject]@{Kind='Fixas';Op=$null;Numero=0;Ranges=$faixasFixas})
            }

            foreach($item in $modalities){
                $kind=[string]$item.Kind
                $op=$item.Op
                $hitMonths=New-Object Collections.Generic.List[int]
                for($mm=1;$mm -le 12;$mm++){
                    foreach($range in $item.Ranges){
                        if(& $monthHit ([string]$range.S) ([string]$range.E) $y $mm){$hitMonths.Add($mm);break}
                    }
                }
                if($hitMonths.Count -eq 0){continue}
                $id=[string]$r.id
                foreach($mm in $hitMonths){
                    if($kind -eq 'Comuns'){
                        $counts[$mm].C[$id]=$true
                        if([string]$op.tipo -match '15\s*\+\s*15'){$counts[$mm].D15[$id]=$true}
                        else{$counts[$mm].D30[$id]=$true}
                    }
                    elseif($kind -eq 'FR 20 dias'){$counts[$mm].F[$id]=$true}
                    else{$counts[$mm].X[$id]=$true}
                    $counts[$mm].All[[string]$r.matricula]=$true
                    $pesoItem=[double]0
                    foreach($range in $item.Ranges){
                        $ddI=[datetime]::MinValue;$ddF=[datetime]::MinValue
                        if([datetime]::TryParseExact([string]$range.S,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$ddI) -and [datetime]::TryParseExact([string]$range.E,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$ddF)){
                            $pesoItem += [double](& $pesoInstitucionalRelatorio $ddI $ddF $y $mm)
                        }
                    }
                    $chavePeso=([string]$r.matricula)+'|'+([string]$r.aquisitivo_inicio)+'|'+([string]$r.aquisitivo_fim)
                    if(-not $counts[$mm].Peso.ContainsKey($chavePeso)){$counts[$mm].Peso[$chavePeso]=@{Comum=[double]0;FR=[double]0}}
                    $campoPeso=if($kind -eq 'FR 20 dias'){'FR'}else{'Comum'}
                    $counts[$mm].Peso[$chavePeso][$campoPeso]=[math]::Max([double]$counts[$mm].Peso[$chavePeso][$campoPeso],$pesoItem)
                }
                if($choice -eq '30 dias' -and ($kind -ne 'Comuns' -or [string]$op.tipo -match '15\s*\+\s*15')){continue}
                elseif($choice -eq '15+15' -and ($kind -ne 'Comuns' -or [string]$op.tipo -notmatch '15\s*\+\s*15')){continue}
                elseif($choice -notin @('Todas','30 dias','15+15') -and $choice -ne $kind){continue}
                if($m -gt 0 -and -not $hitMonths.Contains($m)){continue}
                $items.Add([pscustomobject]@{R=$r;Op=$op;Kind=$kind;Numero=[int]$item.Numero;Ranges=$item.Ranges})
            }
        }

        $etapa='Calcular meses e limites'
        $names=@('Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez')
        for($mm=1;$mm -le 12;$mm++){
            $rr=$monthly.NewRow();$rr['Mes']=$names[$mm-1]
            $rr['Fixas']=[string]$counts[$mm].X.Count
            $rr['30 dias']=[string]$counts[$mm].D30.Count
            $rr['15+15']=[string]$counts[$mm].D15.Count
            $rr['Comuns']=[string]$counts[$mm].C.Count
            $rr['FR 20 dias']=[string]$counts[$mm].F.Count
            $rr['Total solicit.']=[string]($counts[$mm].X.Count+$counts[$mm].C.Count+$counts[$mm].F.Count)
            $rr['Servidores distintos']=[string]$counts[$mm].All.Count
            $equiv=[double]0; foreach($peso in $counts[$mm].Peso.Values){$equiv += [math]::Min([double]1.0,[math]::Max([double]$peso.Comum,[double]$peso.FR))}
            $limite=[double](& $limiteInstitucionalRelatorio $mm)
            $rr['Equivalentes']=$equiv.ToString('0.##',[Globalization.CultureInfo]::GetCultureInfo('pt-BR'))
            $rr['Limite']=$limite.ToString('0.##',[Globalization.CultureInfo]::GetCultureInfo('pt-BR'))
            $rr['Saldo']=($limite-$equiv).ToString('0.##',[Globalization.CultureInfo]::GetCultureInfo('pt-BR'))
            [void]$monthly.Rows.Add($rr)
        }

        $etapa='Montar detalhes nominais'
        $dt=New-Object Data.DataTable
        foreach($h in $chosen){[void]$dt.Columns.Add($h,[string])}
        foreach($item in $items.ToArray()){
            $r=$item.R;$op=$item.Op;$row=$dt.NewRow()
            $matchedRanges=@()
            if($item.Kind -eq 'Fixas'){
                $matchedRanges=@($item.Ranges | Where-Object {$m -eq 0 -or (& $monthHit ([string]$_.S) ([string]$_.E) $y $m)})
            } elseif($item.Kind -eq 'FR 20 dias') {
                $matchedRanges=,[pscustomobject]@{S=[string]$op.fr_inicio;E=[string]$op.fr_fim}
            } else {
                $tmp=New-Object Collections.Generic.List[object]
                if([string]$op.inicio1 -and [string]$op.fim1){$tmp.Add([pscustomobject]@{S=[string]$op.inicio1;E=[string]$op.fim1})}
                if([string]$op.inicio2 -and [string]$op.fim2){$tmp.Add([pscustomobject]@{S=[string]$op.inicio2;E=[string]$op.fim2})}
                # Nao usar @($tmp) nem a conversao dinamica de List[object]
                # dentro do evento GetNewClosure no Windows PowerShell 5.1.
                $validRanges=New-Object 'System.Collections.Generic.List[object]'
                foreach($rangePart in $tmp.ToArray()){
                    if($m -eq 0 -or (& $monthHit ([string]$rangePart.S) ([string]$rangePart.E) $y $m)){
                        [void]$validRanges.Add($rangePart)
                    }
                }
                $matchedRanges=$validRanges.ToArray()
            }
            foreach($h in $chosen){
                $f=[string]$fields[$h];$v=''
                switch($f){
                    'mes_periodo' {
                        $parts=@()
                        foreach($rg in $matchedRanges){
                            $parts+=('{0} a {1}' -f (& $dateBR ([string]$rg.S)),(& $dateBR ([string]$rg.E)))
                        }
                        $v=([string]::Join(' | ', [string[]]$parts))
                    }
                    'modalidade' { $v=[string]$item.Kind }
                    'situacao' {
                        if($item.Kind -eq 'Fixas'){$v='FIXA'}
                        elseif($item.Kind -eq 'FR 20 dias'){$v=if([int]$r.fr_opcao_aprovada -eq [int]$item.Numero){'FR ACEITA'}else{'FR PENDENTE'}}
                        else{$v=if([int]$r.opcao_aprovada -eq [int]$item.Numero){'ACEITA'}else{'PENDENTE'}}
                    }
                    'tipo' {
                        if($item.Kind -eq 'Comuns'){$v=[string]$op.tipo}
                    }
                    'inicio1' {
                        if($item.Kind -eq 'Comuns'){
                            if($m -gt 0){$v=if($matchedRanges.Count -ge 1){[string]$matchedRanges[0].S}else{''}} else {$v=[string]$op.inicio1}
                        }
                    }
                    'fim1' {
                        if($item.Kind -eq 'Comuns'){
                            if($m -gt 0){$v=if($matchedRanges.Count -ge 1){[string]$matchedRanges[0].E}else{''}} else {$v=[string]$op.fim1}
                        }
                    }
                    'inicio2' {
                        if($item.Kind -eq 'Comuns'){
                            if($m -gt 0){$v=if($matchedRanges.Count -ge 2){[string]$matchedRanges[1].S}else{''}} else {$v=[string]$op.inicio2}
                        }
                    }
                    'fim2' {
                        if($item.Kind -eq 'Comuns'){
                            if($m -gt 0){$v=if($matchedRanges.Count -ge 2){[string]$matchedRanges[1].E}else{''}} else {$v=[string]$op.fim2}
                        }
                    }
                    'fr_periodo' {
                        if($item.Kind -eq 'FR 20 dias'){
                            $v=((& $dateBR ([string]$op.fr_inicio))+' a '+(& $dateBR ([string]$op.fr_fim))).Trim()
                        }
                    }
                    'fixo_inicio' { if($item.Kind -eq 'Fixas'){$v=([string[]]@($matchedRanges | ForEach-Object {& $dateBR ([string]$_.S)})) -join ' | '} }
                    'fixo_fim' { if($item.Kind -eq 'Fixas'){$v=([string[]]@($matchedRanges | ForEach-Object {& $dateBR ([string]$_.E)})) -join ' | '} }
                    default { $v=[string]$r.$f }
                }
                if($f -match '^(aquisitivo_inicio|aquisitivo_fim|inicio1|fim1|inicio2|fim2|fixo_inicio|fixo_fim)$'){$v=& $dateBR $v}
                $row[$h]=$v
            }
            [void]$dt.Rows.Add($row)
        }

        $store.Shown=$dt;$store.Monthly=$monthly
        # Preserve o mes em foco e a rolagem. Nao retornar ao primeiro registro
        # sempre que filtros/colunas forem atualizados.
        $summaryTop=0;$summarySelected=-1;$summaryColumn=0;$summaryLeft=0
        $detailTop=0;$detailSelected=-1;$detailLeft=0
        try{$summaryTop=[int]$summary.FirstDisplayedScrollingRowIndex}catch{}
        try{$summarySelected=[int]$summary.CurrentCell.RowIndex;$summaryColumn=[int]$summary.CurrentCell.ColumnIndex}catch{}
        try{$summaryLeft=[int]$summary.HorizontalScrollingOffset}catch{}
        try{$detailTop=[int]$grid.FirstDisplayedScrollingRowIndex}catch{}
        try{$detailSelected=[int]$grid.CurrentCell.RowIndex}catch{}
        try{$detailLeft=[int]$grid.HorizontalScrollingOffset}catch{}
        $etapa='Vincular resumo mensal'
        $summary.DataSource=$null
        $summary.DataSource=$monthly
        $summary.ColumnHeadersVisible=$true
        $etapa='Vincular relacao nominal'
        foreach($c in $grid.Columns){if($c.Name){$columnWidths[[string]$c.Name]=[int]$c.Width}}
        $grid.DataSource=$null
        $grid.DataSource=$dt
        $grid.ColumnHeadersVisible=$true
        foreach($c in $grid.Columns){
            if($columnWidths.ContainsKey([string]$c.Name)){$c.Width=[int]$columnWidths[[string]$c.Name]}
            elseif($c.Name -eq 'Servidor'){$c.Width=250}
            elseif($c.Name -eq 'Setor'){$c.Width=175}
            elseif($c.Name -eq 'Periodo no mes'){$c.Width=210}
            else{$c.Width=125}
        }
        # Restaurar rolagem e celula selecionada depois do DataSource.
        # O filtro de mes determina qual linha mensal permanece destacada.
        try{
            $alvo=if($m -gt 0){$m-1}else{$summarySelected}
            if($alvo -ge 0 -and $alvo -lt $summary.Rows.Count -and $summary.Columns.Count -gt 0){
                $col=[Math]::Min([Math]::Max(0,$summaryColumn),$summary.Columns.Count-1)
                $summary.CurrentCell=$summary.Rows[$alvo].Cells[$col]
            }
            if($summaryTop -ge 0 -and $summaryTop -lt $summary.Rows.Count){$summary.FirstDisplayedScrollingRowIndex=$summaryTop}
            elseif($m -gt 0){$summary.FirstDisplayedScrollingRowIndex=$m-1}
            $summary.HorizontalScrollingOffset=[Math]::Max(0,$summaryLeft)
        }catch{}
        try{
            if($detailSelected -ge 0 -and $detailSelected -lt $grid.Rows.Count -and $grid.Columns.Count -gt 0){
                $grid.CurrentCell=$grid.Rows[$detailSelected].Cells[0]
            }
            if($detailTop -ge 0 -and $detailTop -lt $grid.Rows.Count){$grid.FirstDisplayedScrollingRowIndex=$detailTop}
            if($detailLeft -ge 0){$grid.HorizontalScrollingOffset=$detailLeft}
        }catch{}
        $info.Text="Resumo acima: demanda da opcao + fixas, nao apenas aprovadas | Registros: $($dt.Rows.Count) | Analise: $analysis | Opcao: $n | Ano: $y | Mes: $([string]$month.SelectedItem) | Solicitações: comum / FR / fixa (nao equivalentes institucionais)"
      } catch {
        $info.Text='Falha ('+$etapa+'): '+$_.Exception.Message
        [Windows.Forms.MessageBox]::Show('Etapa: '+$etapa+[Environment]::NewLine+($_.Exception.ToString() + [Environment]::NewLine + 'Linha: ' + [string]$_.InvocationInfo.ScriptLineNumber + ' | Instrucao: ' + [string]$_.InvocationInfo.Line),'Relatorio de conferencia')|Out-Null
      } finally { $store.Refreshing=$false }
    }.GetNewClosure()

    $loadRecords={
        try{
            $snapshot=Read-DatabaseSnapshotWithRetry $dbPathForReport 3 150
            $obj=$snapshot.Db
            $store.Records=@($obj.registros)
            $oldS=[string]$sector.SelectedItem;$oldP=[string]$period.SelectedItem
            $sectors=@($store.Records|ForEach-Object{[string]$_.setor}|Where-Object{$_}|Sort-Object -Unique)
            $periods=@($store.Records|ForEach-Object{[string]$_.periodo}|Where-Object{$_}|Sort-Object -Unique)
            $sector.Items.Clear();[void]$sector.Items.Add('Todos');foreach($s in $sectors){[void]$sector.Items.Add($s)}
            $period.Items.Clear();[void]$period.Items.Add('Todos');foreach($p in $periods){[void]$period.Items.Add($p)}
            $sector.SelectedIndex=if($sector.Items.Contains($oldS)){$sector.Items.IndexOf($oldS)}else{0}
            $period.SelectedIndex=if($period.Items.Contains($oldP)){$period.Items.IndexOf($oldP)}else{0}
            & $refresh
        } catch {
            [Windows.Forms.MessageBox]::Show('Nao foi possivel reler a base. Nenhum dado foi alterado: '+$_.Exception.Message,'Atualizar registros')|Out-Null
        }
    }.GetNewClosure()

    $checks.add_ItemCheck({
        $dialog.BeginInvoke([Action]{ & $refresh }) | Out-Null
    }.GetNewClosure())
    foreach($ctrl in @($select,$year,$month,$modality,$sector,$period,$modo)){$ctrl.add_SelectedIndexChanged($refresh)}
    $search.add_TextChanged($refresh)
    $btnRefresh.add_Click($loadRecords)
    $btnAll.add_Click({for($i=0;$i -lt $checks.Items.Count;$i++){$checks.SetItemChecked($i,$true)}}.GetNewClosure())
    $btnNone.add_Click({for($i=0;$i -lt $checks.Items.Count;$i++){$checks.SetItemChecked($i,$false)}}.GetNewClosure())
    # V141: clique simples em qualquer numero do resumo filtra a relacao nominal.
    # As colunas representam solicitacoes/servidores/equivalentes distintos;
    # 'Limite' e 'Saldo' mostram todos os compromissos do mes, nao registros ficticios.
    $summary.add_CellClick({param($sender,$e)
        if($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){return}
        try {
            $mesSigla=[string]$summary.Rows[$e.RowIndex].Cells['Mes'].Value
            $map=@{'Jan'='Janeiro';'Fev'='Fevereiro';'Mar'='Marco';'Abr'='Abril';'Mai'='Maio';'Jun'='Junho';'Jul'='Julho';'Ago'='Agosto';'Set'='Setembro';'Out'='Outubro';'Nov'='Novembro';'Dez'='Dezembro'}
            if(-not $map.ContainsKey($mesSigla)){return}
            $colName=[string]$summary.Columns[$e.ColumnIndex].Name
            $modal='Todas'
            switch($colName){
                'Fixas' {$modal='Fixas'}
                'Comuns' {$modal='Comuns'}
                '30 dias' {$modal='30 dias'}
                '15+15' {$modal='15+15'}
                'FR 20 dias' {$modal='FR 20 dias'}
            }
            # Aplicar ambos os filtros sem executar duas vezes todo o calculo.
            $store.Refreshing=$true
            try {
                if([string]$modality.SelectedItem -ne $modal){$modality.SelectedItem=$modal}
                if([string]$month.SelectedItem -ne $map[$mesSigla]){$month.SelectedItem=$map[$mesSigla]}
            } finally { $store.Refreshing=$false }
            & $refresh
            $grid.ClearSelection()
            $info.Text += (' | Detalhes: '+$mesSigla+' / '+$modal+' ('+[string]$store.Shown.Rows.Count+' ocorrencias)')
        }catch{
            [Windows.Forms.MessageBox]::Show('Falha ao filtrar celula: '+$_.Exception.Message,'Conferencia')|Out-Null
        }
    }.GetNewClosure())
    # V141: saldo colorido com valor e selecao legiveis; vermelho < 0,
    # amarelo = 0, verde > 0. Usa valor da DataTable em pt-BR.
    $summary.add_CellFormatting({param($sender,$e)
        if($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){return}
        if([string]$summary.Columns[$e.ColumnIndex].Name -ne 'Saldo'){return}
        try {
            $raw=[string]$summary.Rows[$e.RowIndex].Cells[$e.ColumnIndex].Value
            $saldo=[decimal]0
            if(-not [decimal]::TryParse($raw,[Globalization.NumberStyles]::Number,[Globalization.CultureInfo]::GetCultureInfo('pt-BR'),[ref]$saldo)){return}
            $cor=if($saldo -lt 0){[Drawing.Color]::FromArgb(184,32,42)}elseif($saldo -gt 0){[Drawing.Color]::FromArgb(31,125,65)}else{[Drawing.Color]::FromArgb(255,219,88)}
            $letra=if($saldo -eq 0){[Drawing.Color]::Black}else{[Drawing.Color]::White}
            $e.CellStyle.BackColor=$cor
            $e.CellStyle.ForeColor=$letra
            $e.CellStyle.SelectionBackColor=$cor
            $e.CellStyle.SelectionForeColor=$letra
            $e.CellStyle.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
        }catch{}
    }.GetNewClosure())

    $btnCsv.add_Click({
        if($null -eq $store.Shown){return}
        $save=New-Object Windows.Forms.SaveFileDialog;$save.Filter='CSV Excel (*.csv)|*.csv'
        $save.FileName='Conferencia_Ferias.csv'
        if($save.ShowDialog() -ne 'OK'){return}
        try{
            $lines=New-Object Collections.Generic.List[string]
            $lines.Add((@($store.Shown.Columns|ForEach-Object{'"'+([string]$_.ColumnName).Replace('"','""')+'"'}) -join ';'))
            foreach($rr in $store.Shown.Rows){$lines.Add((@($store.Shown.Columns|ForEach-Object{'"'+([string]$rr[$_.ColumnName]).Replace('"','""')+'"'}) -join ';'))}
            [IO.File]::WriteAllLines($save.FileName,$lines.ToArray(),(New-Object Text.UTF8Encoding($true)))
            [Windows.Forms.MessageBox]::Show('CSV exportado com as colunas visiveis.','Conferencia')|Out-Null
        } catch {[Windows.Forms.MessageBox]::Show($_.Exception.Message,'CSV')|Out-Null}
    }.GetNewClosure())

    $btnPdf.add_Click({
        if($null -eq $store.Shown -or $store.Shown.Columns.Count -eq 0){return}
        try{
            $sb=New-Object Text.StringBuilder
            [void]$sb.Append('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Conferencia de ferias</title><style>@page{size:landscape;margin:10mm}body{font:10px Arial;margin:12px}h2{margin:4px 0}table{border-collapse:collapse;width:100%;table-layout:auto}th,td{border:1px solid #777;padding:4px;vertical-align:top;overflow-wrap:anywhere}thead{display:table-header-group}th{background:#dcebf1}.toolbar{margin:10px 0}@media print{.toolbar{display:none}}</style></head><body>')
            [void]$sb.Append('<div class="toolbar"><button onclick="window.print()">Imprimir / Salvar em PDF</button> (No navegador, escolha a impressora Salvar como PDF.)</div>')
            [void]$sb.Append('<h2>Conferencia de ferias - '+([System.Net.WebUtility]::HtmlEncode([string]$modo.SelectedItem))+' - '+([System.Net.WebUtility]::HtmlEncode([string]$select.SelectedItem))+'</h2>')
            [void]$sb.Append('<p>Ano: '+([System.Net.WebUtility]::HtmlEncode([string]$year.SelectedItem))+' | Mes: '+([System.Net.WebUtility]::HtmlEncode([string]$month.SelectedItem))+' | Modalidade: '+([System.Net.WebUtility]::HtmlEncode([string]$modality.SelectedItem))+' | Registros: '+$store.Shown.Rows.Count+'</p>')
            [void]$sb.Append('<h3>Resumo mensal - Fixas / Comuns / FR / Total / Limite / Saldo</h3><table><thead><tr>')
            foreach($col in $store.Monthly.Columns){[void]$sb.Append('<th>'+[System.Net.WebUtility]::HtmlEncode([string]$col.ColumnName)+'</th>')}
            [void]$sb.Append('</tr></thead><tbody>')
            foreach($rr in $store.Monthly.Rows){[void]$sb.Append('<tr>');foreach($col in $store.Monthly.Columns){[void]$sb.Append('<td>'+[System.Net.WebUtility]::HtmlEncode([string]$rr[$col.ColumnName])+'</td>')};[void]$sb.Append('</tr>')}
            [void]$sb.Append('</tbody></table><h3>Conferencia nominal - colunas selecionadas</h3><table><thead><tr>')
            foreach($col in $store.Shown.Columns){[void]$sb.Append('<th>'+[System.Net.WebUtility]::HtmlEncode([string]$col.ColumnName)+'</th>')}
            [void]$sb.Append('</tr></thead><tbody>')
            foreach($rr in $store.Shown.Rows){[void]$sb.Append('<tr>');foreach($col in $store.Shown.Columns){[void]$sb.Append('<td>'+[System.Net.WebUtility]::HtmlEncode([string]$rr[$col.ColumnName])+'</td>')};[void]$sb.Append('</tr>')}
            [void]$sb.Append('</tbody></table></body></html>')
            $path=Join-Path ([IO.Path]::GetTempPath()) ('ConferenciaFerias_'+[guid]::NewGuid().ToString('N')+'.html')
            [IO.File]::WriteAllText($path,$sb.ToString(),(New-Object Text.UTF8Encoding($false)))
            Start-Process -FilePath $path
        }catch{[Windows.Forms.MessageBox]::Show($_.Exception.ToString(),'Previa PDF')|Out-Null}
    }.GetNewClosure())

    $dialog.add_Shown({ $root.PerformLayout(); $body.PerformLayout(); & $loadRecords }.GetNewClosure())
    [void]$dialog.ShowDialog();$dialog.Dispose()
}

# Eventos

$numTotalEnf.add_ValueChanged({ Refresh-PoliticaMensalInfo })
$numPctRestrito.add_ValueChanged({ Refresh-PoliticaMensalInfo })
$btnSalvarPoliticaMensal.add_Click({
    $novoTotal=[int]$numTotalEnf.Value
    $novoPercentual=[int]$numPctRestrito.Value
    $meses=@()
    for($i=0;$i -lt $script:chkMesRestrito.Count;$i++){
        if($script:chkMesRestrito[$i].Checked){ $meses += ($i+1) }
    }
    $limitesNovos=@{}
    for($i=0;$i -lt 12;$i++){
        if($script:chkMesRestrito[$i].Checked -and [decimal]$script:numLimiteEspecialMes[$i].Value -le 0){
            [Windows.Forms.MessageBox]::Show("Informe um limite especial maior que zero para $($nomesMesCfg[$i]). Ou desmarque o mês para utilizar o limite normal.","Limite não informado",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning)|Out-Null
            return
        }
        if([decimal]$script:numLimiteEspecialMes[$i].Value -gt 0){ $limitesNovos[[string]($i+1)]=[double]$script:numLimiteEspecialMes[$i].Value }
    }
    $script:Config.total_enfermeiros_planejamento=$novoTotal
    $script:Config.percentual_meses_restritos=$novoPercentual
    $script:Config.meses_restritos=@($meses)
    $script:Config | Add-Member -NotePropertyName limites_especiais_mensais -NotePropertyValue $limitesNovos -Force
    Save-Database
    $script:InstitutionalResumoCacheKey=""
    Refresh-PoliticaMensalInfo
    Refresh-LimiteInstitucionalResumo
    Request-DashboardRefresh
    Request-PlanejamentoRefresh
    [Windows.Forms.MessageBox]::Show(
        "Limites mensais salvos.`n`nOs meses especiais terão o limite informado para alertas. As férias fixas permanecem protegidas e aprovações excepcionais exigem justificativa.",
        "Férias DCE",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})


$script:gridFeriadosRec.add_SelectionChanged({
    if($script:gridFeriadosRec.SelectedRows.Count -eq 0){return}
    $row=$script:gridFeriadosRec.SelectedRows[0]; $id=[string]$row.Cells['frId'].Value
    $f=@($script:Config.feriados_recorrentes|Where-Object{[string]$_.id -eq $id}|Select-Object -First 1)
    if($f){$script:FerRecId=$id;$numFerDia.Value=[decimal][int]$f.dia;$numFerMes.Value=[decimal][int]$f.mes;$txtFerRecDesc.Text=[string]$f.descricao;$cmbFerRecAbr.Text=[string]$f.abrangencia;$chkFerRecAtivo.Checked=if($null -eq $f.PSObject.Properties['ativo']){$true}else{[bool]$f.ativo}}
})
$btnFerRecNovo.add_Click({$script:FerRecId='';$numFerDia.Value=1;$numFerMes.Value=1;$txtFerRecDesc.Clear();$cmbFerRecAbr.SelectedIndex=0;$chkFerRecAtivo.Checked=$true})
$btnFerRecSalvar.add_Click({
    $desc=$txtFerRecDesc.Text.Trim(); if(-not $desc){[Windows.Forms.MessageBox]::Show('Informe a descrição do feriado.','Feriados')|Out-Null;return}
    $dia=[int]$numFerDia.Value;$mes=[int]$numFerMes.Value; try{[void][datetime]::new(2028,$mes,$dia)}catch{[Windows.Forms.MessageBox]::Show('Dia/mês inválido.','Feriados')|Out-Null;return}
    $id=[string]$script:FerRecId; if(-not $id){$id=New-FeriadoId}
    $novo=[pscustomobject]@{id=$id;dia=$dia;mes=$mes;descricao=$desc;abrangencia=[string]$cmbFerRecAbr.Text;ativo=[bool]$chkFerRecAtivo.Checked}
    $script:Config.feriados_recorrentes=@(@($script:Config.feriados_recorrentes|Where-Object{[string]$_.id -ne $id})+$novo)
    Save-Database; Refresh-FeriadosLists; $script:FerRecId=$id
})
$btnFerRecExcluir.add_Click({if(-not $script:FerRecId){return};if([Windows.Forms.MessageBox]::Show('Excluir este feriado recorrente?','Feriados',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)-eq[Windows.Forms.DialogResult]::Yes){$script:Config.feriados_recorrentes=@($script:Config.feriados_recorrentes|Where-Object{[string]$_.id -ne [string]$script:FerRecId});Save-Database;$script:FerRecId='';Refresh-FeriadosLists}})

$script:gridFeriadosEsp.add_SelectionChanged({
    if($script:gridFeriadosEsp.SelectedRows.Count -eq 0){return}
    $row=$script:gridFeriadosEsp.SelectedRows[0];$id=[string]$row.Cells['feId'].Value
    $f=@($script:Config.feriados_especificos|Where-Object{[string]$_.id -eq $id}|Select-Object -First 1)
    if($f){$script:FerEspId=$id;$d=Parse-Date ([string]$f.data);if($null -ne $d){$dtFerEsp.Value=$d};$txtFerEspDesc.Text=[string]$f.descricao;$cmbFerEspAbr.Text=[string]$f.abrangencia;$chkFerEspAtivo.Checked=if($null -eq $f.PSObject.Properties['ativo']){$true}else{[bool]$f.ativo}}
})
$btnFerEspNovo.add_Click({$script:FerEspId='';$dtFerEsp.Value=(Get-Date).Date;$txtFerEspDesc.Clear();$cmbFerEspAbr.SelectedIndex=0;$chkFerEspAtivo.Checked=$true})
$btnFerEspSalvar.add_Click({
    $desc=$txtFerEspDesc.Text.Trim();if(-not $desc){[Windows.Forms.MessageBox]::Show('Informe a descrição do feriado.','Feriados')|Out-Null;return}
    $id=[string]$script:FerEspId;if(-not $id){$id=New-FeriadoId}
    $novo=[pscustomobject]@{id=$id;data=Date-ToStore $dtFerEsp.Value.Date;descricao=$desc;abrangencia=[string]$cmbFerEspAbr.Text;ativo=[bool]$chkFerEspAtivo.Checked}
    $script:Config.feriados_especificos=@(@($script:Config.feriados_especificos|Where-Object{[string]$_.id -ne $id})+$novo)
    Save-Database;Refresh-FeriadosLists;$script:FerEspId=$id
})
$btnFerEspExcluir.add_Click({if(-not $script:FerEspId){return};if([Windows.Forms.MessageBox]::Show('Excluir este feriado específico?','Feriados',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)-eq[Windows.Forms.DialogResult]::Yes){$script:Config.feriados_especificos=@($script:Config.feriados_especificos|Where-Object{[string]$_.id -ne [string]$script:FerEspId});Save-Database;$script:FerEspId='';Refresh-FeriadosLists}})

$script:chkFeriasBloqueadas.add_CheckedChanged({
    if([bool]$script:CarregandoBloqueio){
        Set-EditorBloqueioState
        return
    }

    if([int]$script:CurrentId -le 0){
        if($script:chkFeriasBloqueadas.Checked){
            $script:CarregandoBloqueio=$true
            $script:chkFeriasBloqueadas.Checked=$false
            $script:CarregandoBloqueio=$false
        }
        Set-EditorBloqueioState
        return
    }

    $rAtual=$script:Records | Where-Object {[int]$_.id -eq [int]$script:CurrentId} | Select-Object -First 1
    if($null -eq $rAtual){ return }

    # Férias fixas IMPORTADAS são imutáveis na operação comum. Remoção somente pela manutenção segura.
    if((Test-RegistroFixoImportado $rAtual) -and -not $script:chkFeriasBloqueadas.Checked){
        $script:CarregandoBloqueio=$true
        $script:chkFeriasBloqueadas.Checked=$true
        $script:CarregandoBloqueio=$false
        [Windows.Forms.MessageBox]::Show(
            "Este compromisso veio da planilha de férias já definidas para 2027 e não pode ser desbloqueado nesta tela.`n`nPara corrigir a importação, use Configurações > Manutenção / Reset > Remover férias fixas importadas.",
            "Férias fixa protegida",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        Set-EditorBloqueioState
        return
    }

    # Desbloqueio de compromisso antigo marcado manualmente é excepcional e exige confirmação explícita.
    if((Test-RegistroFeriasBloqueadas $rAtual) -and -not $script:chkFeriasBloqueadas.Checked){
        $resp=[Windows.Forms.MessageBox]::Show(
            "ATENÇÃO: este período foi protegido como férias já programadas em programação anterior.`n`nO desbloqueio deve ser usado somente para corrigir cadastro incorreto. Deseja realmente liberar a edição?",
            "Desbloquear férias programadas",
            [Windows.Forms.MessageBoxButtons]::YesNo,
            [Windows.Forms.MessageBoxIcon]::Warning
        )
        if($resp -ne [Windows.Forms.DialogResult]::Yes){
            $script:CarregandoBloqueio=$true
            $script:chkFeriasBloqueadas.Checked=$true
            $script:CarregandoBloqueio=$false
        }
    }

    Set-EditorBloqueioState
})

$script:txtBusca.add_TextChanged({ Request-GridRefresh })
$script:btnFiltroSetores.add_Click({ Selecionar-MultiplosSetores })
$script:btnPendencias.add_Click({
    $script:SomentePendencias=-not $script:SomentePendencias
    Refresh-Grid
})
$btnLimparFiltros.add_Click({
    $script:txtBusca.Clear()
    $script:FiltroSetoresSelecionados=@()
$script:PlanejSetoresSelecionados=@()
$script:PlanejPeriodosSelecionados=@()
    $script:SomentePendencias=$false
    if($script:cmbFiltroPeriodo.Items.Count -gt 0){ $script:cmbFiltroPeriodo.SelectedIndex=0 }
    if($script:cmbFiltroSituacao.Items.Count -gt 0){ $script:cmbFiltroSituacao.SelectedIndex=0 }
    if($script:cmbFiltroGrupoAnalise.Items.Count -gt 0){ $script:cmbFiltroGrupoAnalise.SelectedIndex=0 }
    if($script:cmbFiltroChefia.Items.Count -gt 0){ $script:cmbFiltroChefia.SelectedIndex=0 }
    if($script:cmbFiltroSolicitacao.Items.Count -gt 0){ $script:cmbFiltroSolicitacao.SelectedIndex=0 }
    if($script:cmbFiltroJustificativa.Items.Count -gt 0){ $script:cmbFiltroJustificativa.SelectedIndex=0 }
    Update-SetoresFiltroResumo
    Refresh-Grid
})

$script:cmbFiltroPeriodo.add_SelectedIndexChanged({ Request-GridRefresh })
$script:cmbFiltroSituacao.add_SelectedIndexChanged({ Request-GridRefresh })
$script:cmbFiltroGrupoAnalise.add_SelectedIndexChanged({ Request-GridRefresh })
$script:cmbFiltroChefia.add_SelectedIndexChanged({ Request-GridRefresh })
$script:cmbFiltroSolicitacao.add_SelectedIndexChanged({ Request-GridRefresh })
$script:cmbFiltroJustificativa.add_SelectedIndexChanged({ Request-GridRefresh })

$script:grid.add_KeyDown({
    param($sender,$e)
    if($e.KeyCode -eq [Windows.Forms.Keys]::Delete){
        $e.SuppressKeyPress=$true
        $e.Handled=$true
        [Windows.Forms.MessageBox]::Show(
            "Exclusão pelo teclado está bloqueada.`n`nPara excluir apenas um período, use 'Excluir período'. Para excluir servidores inteiros em lote, marque a coluna 'Excluir' e use 'Excluir marcados'.",
            "Exclusão protegida",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
})
$script:grid.add_UserDeletingRow({
    param($sender,$e)
    $e.Cancel=$true
})
$script:gridPeriodos.add_KeyDown({
    param($sender,$e)
    if($e.KeyCode -eq [Windows.Forms.Keys]::Delete){
        $e.SuppressKeyPress=$true
        $e.Handled=$true
        [Windows.Forms.MessageBox]::Show(
            "Exclusão pelo teclado está bloqueada.`nUse o botão 'Excluir período'.",
            "Exclusão protegida",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
})
$script:gridPeriodos.add_UserDeletingRow({
    param($sender,$e)
    $e.Cancel=$true
})
$script:grid.add_CurrentCellDirtyStateChanged({
    if($script:grid.IsCurrentCellDirty -and $script:grid.CurrentCell.OwningColumn.Name -in @('excluir','formulario')){ $script:grid.CommitEdit([Windows.Forms.DataGridViewDataErrorContexts]::Commit) }
})
$script:grid.add_CellValueChanged({ param($s,$e)
    if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $script:grid.Columns[$e.ColumnIndex].Name -eq 'excluir'){
        $mat=([string]$script:grid.Rows[$e.RowIndex].Cells['matricula'].Value).Trim()
        if($mat){ $script:GridServidoresMarcados[$mat]=[bool]$script:grid.Rows[$e.RowIndex].Cells['excluir'].Value; Atualizar-ResumoMarcados }
    }
    if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $script:grid.Columns[$e.ColumnIndex].Name -eq 'formulario'){
        $mat=([string]$script:grid.Rows[$e.RowIndex].Cells['matricula'].Value).Trim()
        if($mat){ $script:FormServidoresMarcados[$mat]=[bool]$script:grid.Rows[$e.RowIndex].Cells['formulario'].Value }
    }
})
# V1.0.90 — seleção imediata por mouse, inclusive com uma única linha.
# Não interfere na coluna de marcação de exclusão em lote.
$script:grid.add_CellMouseDown({
    param($sender,$e)
    if($e.Button -ne [Windows.Forms.MouseButtons]::Left -or $e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){ return }
    if($script:grid.Columns[$e.ColumnIndex].Name -eq 'excluir'){ return }
    try {
        $mat=([string]$script:grid.Rows[$e.RowIndex].Cells['matricula'].Value).Trim()
        if([string]::IsNullOrWhiteSpace($mat)){ return }
        $script:grid.CurrentCell=$script:grid.Rows[$e.RowIndex].Cells[$e.ColumnIndex]
        $script:grid.Rows[$e.RowIndex].Selected=$true
        if($script:CurrentMatricula -ne $mat){ Load-Servidor $mat }
    } catch { Write-DiagLog ("Seleção mouse servidor: "+$_.Exception.Message) "WARN" }
})
$script:gridPeriodos.add_CellMouseDown({
    param($sender,$e)
    if($e.Button -ne [Windows.Forms.MouseButtons]::Left -or $e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){ return }
    try {
        $id=[int]$script:gridPeriodos.Rows[$e.RowIndex].Cells['pid'].Value
        if($id -le 0){ return }
        $script:gridPeriodos.CurrentCell=$script:gridPeriodos.Rows[$e.RowIndex].Cells[$e.ColumnIndex]
        $script:gridPeriodos.Rows[$e.RowIndex].Selected=$true
        if([int]$script:CurrentId -ne $id){ Load-Editor $id }
    } catch { Write-DiagLog ("Seleção mouse período: "+$_.Exception.Message) "WARN" }
})
$script:grid.add_CellClick({ param($s,$e)
    if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0){
        $mat=([string]$script:grid.Rows[$e.RowIndex].Cells['matricula'].Value).Trim()
        if($mat -and $script:CurrentMatricula -ne $mat){Load-Servidor $mat}
    }
})
$script:grid.add_CellDoubleClick({ param($s,$e) if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $script:grid.Columns[$e.ColumnIndex].Name -ne 'excluir'){ $mat=[string]$script:grid.Rows[$e.RowIndex].Cells["matricula"].Value; if($script:CurrentMatricula -ne $mat){ Load-Servidor $mat } } })
$btnMarcarVisiveis.add_Click({
    foreach($row in $script:grid.Rows){ $mat=([string]$row.Cells['matricula'].Value).Trim(); if($mat){$script:GridServidoresMarcados[$mat]=$true; $row.Cells['excluir'].Value=$true} }
    Atualizar-ResumoMarcados
})
$btnLimparMarcacao.add_Click({
    $script:GridServidoresMarcados=@{}; foreach($row in $script:grid.Rows){$row.Cells['excluir'].Value=$false}; Atualizar-ResumoMarcados
})
# V151: apenas linhas presentes na grade filtrada; nenhuma acao sobre 'Excluir'.
$btnMarcarFormVisiveis.add_Click({
    $script:grid.SuspendLayout()
    try {
        foreach($row in $script:grid.Rows){
            if($row.IsNewRow -or -not $row.Visible){continue}
            $mat=([string]$row.Cells['matricula'].Value).Trim()
            if(-not $mat){continue}
            $script:FormServidoresMarcados[$mat]=$true
            $row.Cells['formulario'].Value=$true
        }
    }finally{$script:grid.ResumeLayout()}
})
$btnLimparFormVisiveis.add_Click({
    $script:grid.SuspendLayout()
    try {
        foreach($row in $script:grid.Rows){
            if($row.IsNewRow -or -not $row.Visible){continue}
            $mat=([string]$row.Cells['matricula'].Value).Trim()
            if(-not $mat){continue}
            [void]$script:FormServidoresMarcados.Remove($mat)
            $row.Cells['formulario'].Value=$false
        }
    }finally{$script:grid.ResumeLayout()}
})
$script:btnExcluirServidoresMarcados.add_Click({Excluir-ServidoresMarcados})
$script:btnServidoresExcluidos.add_Click({Abrir-ServidoresExcluidos})
$script:gridPeriodos.add_CellClick({ param($s,$e) if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0){ $periodoId=[int]$script:gridPeriodos.Rows[$e.RowIndex].Cells["pid"].Value; if($script:CurrentId -ne $periodoId){ Load-Editor $periodoId } } })
$btnNovoServidor.add_Click({Abrir-CadastroManualServidor})
$btnAdicionarPeriodo.add_Click({if([string]::IsNullOrWhiteSpace([string]$script:CurrentMatricula)){[Windows.Forms.MessageBox]::Show("Selecione primeiro um servidor.","Adicionar período")|Out-Null}else{Adicionar-PeriodoManualServidor ([string]$script:CurrentMatricula)}})
$btnSalvarCadastro.add_Click({Save-ServidorCadastro})
$btnAutorizacao.add_Click({Gerar-AutorizacaoFeriasServidor})
$btnRelConferencia.add_Click({Show-RelatorioConferenciaOpcoes})
$btnRelAceites.add_Click({Show-RelatorioAceitesEnfermagem})
$btnSalvar.add_Click({Save-Editor})
$btnCorrigirPeriodo.add_Click({ Corrigir-PeriodoSelecionado })
$btnNovaFixa.add_Click({ Cadastrar-FeriasFixaManual })
$btnConverterFixa.add_Click({ Converter-FixaEmComum })
$btnExcluirPeriodo.add_Click({ Excluir-PeriodoSelecionado })

$script:cmbImpactoAno.add_SelectedIndexChanged({ Request-PreviaImpacto })
$script:cmbSetor.add_TextChanged({ Request-PreviaImpacto })
$script:cmbPeriodo.add_SelectedIndexChanged({ Request-PreviaImpacto })
$script:Opt1.Tipo.add_SelectedIndexChanged({ Request-PreviaImpacto })
$script:Opt1.I1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt1.F1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt1.I2.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt1.F2.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt2.Tipo.add_SelectedIndexChanged({ Request-PreviaImpacto })
$script:Opt2.I1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt2.F1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt2.I2.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt2.F2.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt3.Tipo.add_SelectedIndexChanged({ Request-PreviaImpacto })
$script:Opt3.I1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt3.F1.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt3.I2.add_ValueChanged({ Request-PreviaImpacto })
$script:Opt3.F2.add_ValueChanged({ Request-PreviaImpacto })


$btnAddSetor.add_Click({
    $novo=$txtNovoSetor.Text.Trim()
    if(-not $novo){ return }
    if(@($script:Config.setores) -contains $novo){
        [Windows.Forms.MessageBox]::Show("Este setor já está cadastrado.","Cadastros") | Out-Null
        return
    }
    $script:Config.setores=@(@($script:Config.setores)+$novo | Sort-Object -Unique)
    Set-GrupoAnaliseSetor $novo "ASSISTENCIAL"
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    $txtNovoSetor.Clear()
})

$btnEditSetor.add_Click({
    if($null -eq $script:lstSetores.SelectedItem){ return }
    $antigo=[string]$script:lstSetores.SelectedItem
    $novo=$txtNovoSetor.Text.Trim()
    if(-not $novo){
        $txtNovoSetor.Text=$antigo
        $txtNovoSetor.Focus()
        return
    }
    if($novo -ne $antigo -and @($script:Config.setores) -contains $novo){
        [Windows.Forms.MessageBox]::Show("Já existe um setor com este nome.","Cadastros") | Out-Null
        return
    }
    $resp=[Windows.Forms.MessageBox]::Show("Renomear '$antigo' para '$novo'?`nTodos os servidores vinculados serão atualizados.","Renomear setor",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
    if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
    foreach($r in $script:Records){ if([string]$r.setor -eq $antigo){ $r.setor=$novo } }
    foreach($lim in @($script:Config.limites_setor_periodo)){
        if([string]$lim.setor -eq $antigo){ $lim.setor=$novo }
    }
    foreach($map in @($script:Config.grupo_analise_setores)){
        if([string]$map.setor -eq $antigo){ $map.setor=$novo }
    }
    foreach($map in @($script:Config.grupo_chefia_setores)){
        if([string]$map.setor -eq $antigo){ $map.setor=$novo }
    }
    $script:Config.setores=@($script:Config.setores | Where-Object {$_ -ne $antigo})
    $script:Config.setores=@(@($script:Config.setores)+$novo | Sort-Object -Unique)
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    Refresh-Grid
    Refresh-Dashboard
    $txtNovoSetor.Clear()
})

$btnSalvarClassSetor.add_Click({
    if($null -eq $script:lstSetores.SelectedItem){
        [Windows.Forms.MessageBox]::Show("Selecione um setor para definir o Grupo de análise.","Cadastros") | Out-Null
        return
    }
    $setor=[string]$script:lstSetores.SelectedItem
    $grupo=if($null -ne $script:cmbSetorGrupoAnalise.SelectedItem){[string]$script:cmbSetorGrupoAnalise.SelectedItem}else{"ASSISTENCIAL"}

    Set-GrupoAnaliseSetor $setor $grupo
    Save-Database
    Refresh-PlanejamentoSetor
    Refresh-ConfigInfo

    [Windows.Forms.MessageBox]::Show(
        "Grupo de análise salvo.`n`nSetor: $setor`nGrupo: $grupo`n`nObservação: o Grupo de Chefia é cadastrado no quadro 2 e os setores são marcados no quadro 3.",
        "Cadastros",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$btnConfigChefiasCad.add_Click({ Abrir-ConfigLimitesGrupoChefiaPeriodo })

$script:lstSetores.add_SelectedIndexChanged({
    if($null -ne $script:lstSetores.SelectedItem){
        $setor=[string]$script:lstSetores.SelectedItem
        $txtNovoSetor.Text=$setor

        $g=Get-GrupoAnaliseSetor $setor
        $idx=$script:cmbSetorGrupoAnalise.Items.IndexOf($g)
        if($idx -lt 0){ $idx=0 }
        $script:cmbSetorGrupoAnalise.SelectedIndex=$idx

        $chef=Get-GrupoChefiaSetor $setor
        if($chef){
            $script:lblSetorChefiaAtual.Text="Chefia padrão do setor: $chef"
        } else {
            $script:lblSetorChefiaAtual.Text="Chefia padrão do setor: NÃO VINCULADO"
        }
    }
})


$btnAjudaChefias.add_Click({ Show-ChefiasPassoAPasso })

$btnAbrirCadastroLoteSetor.add_Click({
    $txtSetorLote.Visible=-not $txtSetorLote.Visible
    $btnAddSetoresLote.Visible=$txtSetorLote.Visible
    if($txtSetorLote.Visible){
        $txtSetorLote.Multiline=$true
        $txtSetorLote.Height=70
        $txtSetorLote.Location=New-Object Drawing.Point(15,455)
        $btnAddSetoresLote.Location=New-Object Drawing.Point(270,455)
        $btnAbrirCadastroLoteSetor.Location=New-Object Drawing.Point(270,493)
        $btnRemSetor.Visible=$false
        $btnAbrirCadastroLoteSetor.Text="Fechar"
        $btnAbrirCadastroLoteSetor.Width=110
    } else {
        $txtSetorLote.Clear()
        $btnRemSetor.Visible=$true
        $btnAbrirCadastroLoteSetor.Location=New-Object Drawing.Point(145,458)
        $btnAbrirCadastroLoteSetor.Width=130
        $btnAbrirCadastroLoteSetor.Text="Adicionar vários..."
    }
})

$btnAddChefia.add_Click({
    $nome=$txtNovaChefia.Text.Trim()
    if(-not $nome){
        [Windows.Forms.MessageBox]::Show("Digite um nome para o Grupo de Chefia.`nEx.: MATERNO-INFANTIL","Grupos de Chefia") | Out-Null
        return
    }
    if(-not (Add-GrupoChefiaNome $nome)){
        [Windows.Forms.MessageBox]::Show("Já existe um Grupo de Chefia com esse nome.","Grupos de Chefia") | Out-Null
        return
    }
    Save-Database
    Refresh-ChefiasCadastroUI
    Refresh-PlanejChefiasFiltro
    $idx=$script:lstChefias.Items.IndexOf($nome)
    if($idx -ge 0){ $script:lstChefias.SelectedIndex=$idx }
    $txtNovaChefia.Clear()
})

$btnRenChefia.add_Click({
    if($null -eq $script:lstChefias.SelectedItem){
        [Windows.Forms.MessageBox]::Show("Selecione um Grupo de Chefia para renomear.","Grupos de Chefia") | Out-Null
        return
    }
    $antigo=[string]$script:lstChefias.SelectedItem
    $novo=$txtNovaChefia.Text.Trim()
    if(-not $novo){
        $txtNovaChefia.Text=$antigo
        $txtNovaChefia.Focus()
        return
    }
    if(-not (Rename-GrupoChefiaNome $antigo $novo)){
        [Windows.Forms.MessageBox]::Show("Não foi possível renomear. Verifique se já existe um grupo com o novo nome.","Grupos de Chefia") | Out-Null
        return
    }
    Save-Database
    Refresh-ChefiasCadastroUI
    Refresh-PlanejChefiasFiltro
    Refresh-PlanejamentoSetor
    $idx=$script:lstChefias.Items.IndexOf($novo)
    if($idx -ge 0){ $script:lstChefias.SelectedIndex=$idx }
    $txtNovaChefia.Clear()
})

$btnRemChefia.add_Click({
    if($null -eq $script:lstChefias.SelectedItem){ return }
    $nome=[string]$script:lstChefias.SelectedItem
    $setores=@($script:Config.grupo_chefia_setores | Where-Object { ([string]$_.grupo).Trim() -eq $nome } | ForEach-Object { [string]$_.setor })
    $servidores=@($script:Config.grupo_chefia_servidores | Where-Object { ([string]$_.grupo).Trim() -eq $nome })
    $msg="Excluir o Grupo de Chefia '$nome'?"
    if($setores.Count -gt 0){
        $msg += "`n`nSetores que ficarão SEM vínculo desta chefia:`n- "+($setores -join "`n- ")
    }
    if($servidores.Count -gt 0){
        $msg += "`n`nVínculos individuais de servidor que serão removidos: $($servidores.Count)"
    }
    $msg += "`n`nOs limites deste Grupo de Chefia também serão removidos."
    $resp=[Windows.Forms.MessageBox]::Show($msg,"Excluir Grupo de Chefia",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)
    if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }

    Remove-GrupoChefiaNome $nome
    Save-Database
    Refresh-ChefiasCadastroUI
    Refresh-PlanejChefiasFiltro
    Refresh-PlanejamentoSetor
    Refresh-ConfigInfo
})

$script:lstChefias.add_SelectedIndexChanged({
    if([bool]$script:CarregandoChefiasUI){ return }
    if($null -ne $script:lstChefias.SelectedItem){
        $txtNovaChefia.Text=[string]$script:lstChefias.SelectedItem
    }
    Load-SetoresChefiaSelecionada
})

$btnSalvarVinculosChefia.add_Click({ Save-VinculosChefiaSelecionada })
$btnSalvarVinculosServidoresChefia.add_Click({ Save-VinculosServidoresChefiaSelecionada })
$btnLimparBuscaServidoresChefia.add_Click({ $script:txtBuscaServidorChefia.Clear(); Refresh-ServidoresChefiaUI })
$script:txtBuscaServidorChefia.add_TextChanged({ Refresh-ServidoresChefiaUI })

$btnDesmarcarChefia.add_Click({
    for($i=0;$i -lt $script:chkSetoresChefia.Items.Count;$i++){
        $script:chkSetoresChefia.SetItemChecked($i,$false)
    }
})

$btnAddSetoresLote.add_Click({
    $novos=@()
    foreach($line in ($txtSetorLote.Text -split "`r?`n")){
        $nome=$line.Trim()
        if($nome -and @($script:Config.setores) -notcontains $nome){ $novos += $nome }
    }
    if($novos.Count -gt 0){
        $script:Config.setores=@(@($script:Config.setores)+$novos | Sort-Object -Unique)
        foreach($s in $novos){ Set-GrupoAnaliseSetor $s "ASSISTENCIAL" }
        Save-Database
        Refresh-SetorPeriodos
        Refresh-CadastrosLists
        $txtSetorLote.Clear()
        [Windows.Forms.MessageBox]::Show("$($novos.Count) setor(es) adicionado(s).","Cadastros") | Out-Null
    }
})

$btnRemSetor.add_Click({
    if($null -eq $script:lstSetores.SelectedItem){ return }
    $alvo=[string]$script:lstSetores.SelectedItem
    $usos=@($script:Records | Where-Object {[string]$_.setor -eq $alvo}).Count
    if($usos -gt 0){
        [Windows.Forms.MessageBox]::Show("Não é possível remover '$alvo'.`nEle está associado a $usos registro(s).`nRenomeie o setor ou altere primeiro os servidores vinculados.","Cadastros") | Out-Null
        return
    }
    $script:Config.setores=@($script:Config.setores | Where-Object {$_ -ne $alvo})
    $script:Config.grupo_analise_setores=@($script:Config.grupo_analise_setores | Where-Object {[string]$_.setor -ne $alvo})
    $script:Config.grupo_chefia_setores=@($script:Config.grupo_chefia_setores | Where-Object {[string]$_.setor -ne $alvo})
    $script:Config.limites_setor_periodo=@($script:Config.limites_setor_periodo | Where-Object {[string]$_.setor -ne $alvo})
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    $txtNovoSetor.Clear()
})

$btnAddPeriodo.add_Click({
    $novo=$txtNovoPeriodo.Text.Trim().ToUpperInvariant()
    if(-not $novo){ return }
    if(@($script:Config.periodos) -contains $novo){
        [Windows.Forms.MessageBox]::Show("Este período já está cadastrado.","Cadastros") | Out-Null
        return
    }
    $script:Config.periodos=@(@($script:Config.periodos)+$novo | Sort-Object -Unique)
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    $txtNovoPeriodo.Clear()
})

$btnEditPeriodo.add_Click({
    if($null -eq $script:lstPeriodos.SelectedItem){ return }
    $antigo=[string]$script:lstPeriodos.SelectedItem
    $novo=$txtNovoPeriodo.Text.Trim().ToUpperInvariant()
    if(-not $novo){
        $txtNovoPeriodo.Text=$antigo
        $txtNovoPeriodo.Focus()
        return
    }
    if($novo -ne $antigo -and @($script:Config.periodos) -contains $novo){
        [Windows.Forms.MessageBox]::Show("Já existe um período com este nome/código.","Cadastros") | Out-Null
        return
    }
    $resp=[Windows.Forms.MessageBox]::Show("Renomear período '$antigo' para '$novo'?`nTodos os servidores vinculados serão atualizados.","Renomear período",[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
    if($resp -ne [Windows.Forms.DialogResult]::Yes){ return }
    foreach($r in $script:Records){ if([string]$r.periodo -eq $antigo){ $r.periodo=$novo } }
    foreach($lim in @($script:Config.limites_setor_periodo)){
        if([string]$lim.periodo -eq $antigo){ $lim.periodo=$novo }
    }
    foreach($lim in @($script:Config.limites_grupo_chefia_periodo)){
        if([string]$lim.periodo -eq $antigo){ $lim.periodo=$novo }
    }
    $script:Config.periodos=@($script:Config.periodos | Where-Object {$_ -ne $antigo})
    $script:Config.periodos=@(@($script:Config.periodos)+$novo | Sort-Object -Unique)
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    Refresh-Grid
    Refresh-Dashboard
    $txtNovoPeriodo.Clear()
})

$script:lstPeriodos.add_SelectedIndexChanged({
    if($null -ne $script:lstPeriodos.SelectedItem){ $txtNovoPeriodo.Text=[string]$script:lstPeriodos.SelectedItem }
})

$btnRemPeriodo.add_Click({
    if($null -eq $script:lstPeriodos.SelectedItem){ return }
    $alvo=[string]$script:lstPeriodos.SelectedItem
    $usos=@($script:Records | Where-Object {[string]$_.periodo -eq $alvo}).Count
    if($usos -gt 0){
        [Windows.Forms.MessageBox]::Show("Não é possível remover '$alvo'.`nEle está associado a $usos registro(s).`nRenomeie o período ou altere primeiro os servidores vinculados.","Cadastros") | Out-Null
        return
    }
    $script:Config.periodos=@($script:Config.periodos | Where-Object {$_ -ne $alvo})
    $script:Config.limites_setor_periodo=@($script:Config.limites_setor_periodo | Where-Object {[string]$_.periodo -ne $alvo})
    $script:Config.limites_grupo_chefia_periodo=@($script:Config.limites_grupo_chefia_periodo | Where-Object {[string]$_.periodo -ne $alvo})
    Save-Database
    Refresh-SetorPeriodos
    Refresh-CadastrosLists
    $txtNovoPeriodo.Clear()
})


$btnAjudaPlanej.add_Click({
    $msg=@"
PASSO A PASSO — PLANEJAMENTO POR SETOR

1. Escolha o ANO e, se necessário, o GRUPO DE ANÁLISE.
2. Use 'Selecionar...' para escolher vários SETORES e PERÍODOS.
3. Se quiser analisar setores que têm a mesma chefia, escolha o GRUPO DE CHEFIA.
4. Clique ATUALIZAR ANÁLISE.
5. Leia as cores da grade:
   • Verde = abaixo do limite
   • Amarelo = no limite
   • Laranja = acima no mês, mas sem simultaneidade crítica
   • Vermelho = simultaneidade real acima do limite
   • Azul/negrito = existe férias FIXA
6. Dê duplo clique em um mês para ver os servidores e comparar as opções.

CADASTRO DE CHEFIAS:
Abra Cadastros > Setores e Chefias e siga os passos 1 a 5 exibidos na própria tela.
"@
    [Windows.Forms.MessageBox]::Show($msg,"Como usar o Planejamento",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})

$btnCentralServidor.add_Click({ Abrir-CentralAprovacaoServidor })
$btnAtualPlanej.add_Click({ Refresh-PlanejamentoSetor })
$btnConfigLimites.add_Click({ Abrir-ConfigLimitesSetorPeriodo })
$btnConfigChefias.add_Click({ Abrir-ConfigLimitesGrupoChefiaPeriodo })
$btnPlanejSetores.add_Click({ Selecionar-PlanejMultiplosSetores })
$btnPlanejPeriodos.add_Click({ Selecionar-PlanejMultiplosPeriodos })
$script:cmbPlanejGrupo.add_SelectedIndexChanged({ $script:PlanejGrupoSelecionado=[string]$script:cmbPlanejGrupo.SelectedItem; Request-PlanejamentoRefresh })
$script:cmbPlanejChefia.add_SelectedIndexChanged({ Request-PlanejamentoRefresh })
$script:cmbPlanejAno.add_SelectedIndexChanged({ Request-PlanejamentoRefresh })
$script:cmbPlanejPeriodo.add_SelectedIndexChanged({ Request-PlanejamentoRefresh })
$script:cmbPlanejMes.add_SelectedIndexChanged({ Request-PlanejamentoRefresh })
$script:cmbPlanejSituacao.add_SelectedIndexChanged({ Request-PlanejamentoRefresh })
$script:chkPlanejSobreposicao.add_CheckedChanged({ Request-PlanejamentoRefresh })
$script:txtPlanejBuscaServidor.add_TextChanged({ Request-PlanejamentoRefresh })
$script:gridPlanejSetor.add_CellDoubleClick({
    param($sender,$e)
    if($script:PlanejRefreshDirty){return}
    if($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 3 -or $e.ColumnIndex -gt 14){ return }
    $setor=[string]$script:gridPlanejSetor.Rows[$e.RowIndex].Cells["psSetor"].Value
    $periodoLinha=[string]$script:gridPlanejSetor.Rows[$e.RowIndex].Cells["psPeriodo"].Value
    $mes=$e.ColumnIndex-2
    Mostrar-DetalhePlanejamento $setor $periodoLinha $mes
})

# Histórico de férias — filtros, seleção e comparação.
$script:txtHistBusca.add_TextChanged({
    if(-not $script:CarregandoHistoricoUI){ Refresh-HistoricoServidoresUI }
})
$script:cmbHistAno.add_SelectedIndexChanged({
    if(-not $script:CarregandoHistoricoUI){
        Refresh-HistoricoDetalheServidor
        Refresh-HistoricoComparacaoUI
    }
})
$script:cmbHistMes.add_SelectedIndexChanged({
    if(-not $script:CarregandoHistoricoUI){
        Refresh-HistoricoDetalheServidor
        Refresh-HistoricoComparacaoUI
    }
})
$script:cmbHistSetor.add_SelectedIndexChanged({
    if(-not $script:CarregandoHistoricoUI){ Refresh-HistoricoServidoresUI }
})
$script:cmbHistPeriodo.add_SelectedIndexChanged({
    if(-not $script:CarregandoHistoricoUI){ Refresh-HistoricoServidoresUI }
})
$script:gridHistServidores.add_SelectionChanged({
    if(-not $script:CarregandoHistoricoUI){ Refresh-HistoricoDetalheServidor }
})
$script:gridHistServidores.add_CurrentCellDirtyStateChanged({
    if($script:gridHistServidores.IsCurrentCellDirty){
        $script:gridHistServidores.CommitEdit([Windows.Forms.DataGridViewDataErrorContexts]::Commit)
    }
})
$script:gridHistServidores.add_CellValueChanged({
    param($sender,$e)
    if($script:CarregandoHistoricoUI -or $e.RowIndex -lt 0){ return }
    if($script:gridHistServidores.Columns[$e.ColumnIndex].Name -ne "hsSel"){ return }

    $mat=([string]$script:gridHistServidores.Rows[$e.RowIndex].Cells["hsMat"].Value).Trim()
    if(-not $mat){ return }
    $marcado=$false
    try { $marcado=[bool]$script:gridHistServidores.Rows[$e.RowIndex].Cells["hsSel"].Value } catch {}
    if($marcado){ $script:HistoricoComparacaoSelecionados[$mat]=$true }
    else { [void]$script:HistoricoComparacaoSelecionados.Remove($mat) }

    if($null -ne $script:lblHistStatus){
        $script:lblHistStatus.Text="$(@($script:HistoricoFerias).Count) registro(s) históricos | $(@($script:HistoricoFerias | Select-Object -ExpandProperty matricula -Unique).Count) servidor(es) no histórico | $($script:gridHistServidores.Rows.Count) servidor(es) exibido(s) | $($script:HistoricoComparacaoSelecionados.Keys.Count) selecionado(s) para comparação"
    }
    Refresh-HistoricoComparacaoUI
})
$btnHistComparar.add_Click({
    if($script:HistoricoComparacaoSelecionados.Keys.Count -eq 0){
        [Windows.Forms.MessageBox]::Show("Marque pelo menos um servidor na coluna 'Comparar'.`n`nPara um desempate, marque dois ou mais servidores.","Histórico de Férias",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    Refresh-HistoricoComparacaoUI
    $histRightTabs.SelectedTab=$tabHistComparacao
})
$btnHistMarcarVisiveis.add_Click({
    $script:CarregandoHistoricoUI=$true
    try {
        foreach($row in $script:gridHistServidores.Rows){
            $mat=([string]$row.Cells["hsMat"].Value).Trim()
            if($mat){
                $script:HistoricoComparacaoSelecionados[$mat]=$true
                $row.Cells["hsSel"].Value=$true
            }
        }
    } finally { $script:CarregandoHistoricoUI=$false }
    Refresh-HistoricoServidoresUI
    Refresh-HistoricoComparacaoUI
})
$btnHistLimparSelecao.add_Click({
    $script:HistoricoComparacaoSelecionados=@{}
    Refresh-HistoricoServidoresUI
    Refresh-HistoricoComparacaoUI
})
$script:UiLazyLoaded=@{ Painel=$false; Planejamento=$false; Historico=$false }
# Revisao persistida: trocar abas sem salvar nao deve recalcular todos os controles.
# Uma gravação pela Central invalida o lançamento e exige atualização antes de editar.
$script:LancamentosRevisionVista=[long]$script:LoadedRevision
$tabs.add_SelectedIndexChanged({
    if($tabs.SelectedTab -eq $tabLanc){
        try {
            $revAtual=[long]$script:LoadedRevision
            if([long]$script:LancamentosRevisionVista -ne $revAtual -or $script:LancamentosFiltroPendente){
                $script:tmrGridFilter.Stop()
                $script:tmrPreviaImpacto.Stop()
                $matAtual=([string]$script:CurrentMatricula).Trim()
                $idAnterior=[int]$script:CurrentId
                $script:grid.SuspendLayout()
                $script:gridPeriodos.SuspendLayout()
                try {
                    Refresh-Grid
                    if($matAtual){
                        # Load-Servidor ja carrega a primeira aquisicao. Nao carregar novamente
                        # quando o periodo anteriormente selecionado e o primeiro da lista.
                        Load-Servidor $matAtual
                        if($idAnterior -gt 0 -and $script:CurrentId -ne $idAnterior){
                            $linhaAnterior=$null
                            foreach($linhaPer in $script:gridPeriodos.Rows){
                                if([int]$linhaPer.Cells['pid'].Value -eq $idAnterior){ $linhaAnterior=$linhaPer; break }
                            }
                            if($null -ne $linhaAnterior){
                                Load-Editor $idAnterior
                                $linhaAnterior.Selected=$true
                            }
                        }
                    }
                } finally {
                    $script:gridPeriodos.ResumeLayout($true)
                    $script:grid.ResumeLayout($true)
                }
                $script:LancamentosRevisionVista=$revAtual
                $script:LancamentosFiltroPendente=$false
            }
        } catch {
            # Nao marcar revisao sincronizada se falhar; a proxima visita tentara novamente.
            Write-DiagLog ('Falha ao sincronizar Lancamentos ao voltar da Central: '+$_.Exception.Message) 'WARN'
        }
        if($script:PreviaImpactoPendente){$script:PreviaImpactoPendente=$false;Request-PreviaImpacto}
    } elseif($tabs.SelectedTab -eq $tabHistorico){
        if(-not $script:UiLazyLoaded.Historico){ Refresh-HistoricoFeriasUI; $script:UiLazyLoaded.Historico=$true }
    } elseif($tabs.SelectedTab -eq $tabPlanejSetor){
        if(-not $script:UiLazyLoaded.Planejamento -or $script:PlanejRefreshDirty){
            Refresh-PlanejamentoSetor
            $script:UiLazyLoaded.Planejamento=$true
        }
    } elseif($tabs.SelectedTab -eq $tabDash){
        if(-not $script:UiLazyLoaded.Painel){ Refresh-Dashboard; $script:UiLazyLoaded.Painel=$true }
    }
})

$btnAtual.add_Click({Refresh-Dashboard})
$btnCsv.add_Click({Export-DashboardCsv})
$script:cmbAno.add_SelectedIndexChanged({ Request-DashboardRefresh })
$script:cmbMes.add_SelectedIndexChanged({ Request-DashboardRefresh })
$script:cmbDashSetor.add_SelectedIndexChanged({ Request-DashboardRefresh })
$script:lblCardPend.Cursor=[Windows.Forms.Cursors]::Hand
$script:lblCardPend.add_Click({
    $tabs.SelectedTab=$tabLanc
    $script:SomentePendencias=$true
    Refresh-Grid
})

$script:cmbDashPeriodo.add_SelectedIndexChanged({ Request-DashboardRefresh })
$script:cmbAnalise.add_SelectedIndexChanged({ Request-DashboardRefresh })
$btnEscolherPlanilha.add_Click({
    $dlg=New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter="Planilha Excel (*.xlsm;*.xlsx)|*.xlsm;*.xlsx"
    if(-not [string]::IsNullOrWhiteSpace([string]$script:Config.planilha_base)){
        try { $dlg.InitialDirectory=Split-Path -Parent ([string]$script:Config.planilha_base) } catch { Write-DiagLog "Não foi possível definir a pasta inicial da planilha-base." "DEBUG" $_ }
    }
    if($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
        $script:Config.planilha_base=$dlg.FileName
        $script:txtPlanilhaBase.Text=$dlg.FileName
        $script:Config.sincronizar_ao_abrir=[bool]$chkAutoSync.Checked
        Save-Database
    }
})
$btnSincronizar.add_Click({
    $script:Config.sincronizar_ao_abrir=[bool]$chkAutoSync.Checked
    Save-Database
    Sync-FromBase $false
})
$chkAutoSync.add_CheckedChanged({
    $script:Config.sincronizar_ao_abrir=[bool]$chkAutoSync.Checked
    Save-Database
})

# Importações — arquivos analisados sem alterar a planilha original.
$btnSelecionarFixas.add_Click({
    $dlg=New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter="Planilha Excel (*.xlsx;*.xlsm)|*.xlsx;*.xlsm"
    $dlg.Title="Selecionar planilha de férias já definidas para 2027"
    if(-not [string]::IsNullOrWhiteSpace([string]$script:Config.planilha_ferias_fixas_2027)){ try{$dlg.InitialDirectory=Split-Path -Parent ([string]$script:Config.planilha_ferias_fixas_2027)}catch{} }
    if($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
        $script:Config.planilha_ferias_fixas_2027=$dlg.FileName
        $script:txtFixasPath.Text=$dlg.FileName
        Save-Database
        Refresh-ImportacaoStatus
    }
})
$btnImportarFixas.add_Click({ Importar-FeriasFixas2027 })

$btnSelecionarHistorico.add_Click({
    $dlg=New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter="Planilha Excel (*.xlsx;*.xlsm)|*.xlsx;*.xlsm"
    $dlg.Title="Selecionar histórico de férias"
    if(-not [string]::IsNullOrWhiteSpace([string]$script:Config.planilha_historico_ferias)){ try{$dlg.InitialDirectory=Split-Path -Parent ([string]$script:Config.planilha_historico_ferias)}catch{} }
    if($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
        $script:Config.planilha_historico_ferias=$dlg.FileName
        $script:txtHistoricoPath.Text=$dlg.FileName
        Save-Database
        Refresh-ImportacaoStatus
    }
})
$btnImportarHistorico.add_Click({ Importar-HistoricoFerias })

$btnResetDecisoes.add_Click({ Reset-DecisoesAtuais })
$btnResetFixas.add_Click({ Reset-FixasImportadas })
$btnResetHistorico.add_Click({ Reset-HistoricoImportado })
$btnZerarPlanejamento.add_Click({ Reset-PlanejamentoAtual })
$btnRestaurarSeed.add_Click({ Restaurar-BaseInicialSeed })
$btnRestaurarPreReset.add_Click({ Restaurar-UltimoPreReset })
$btnResetTotal.add_Click({ Reset-TotalSistema })

$btnColarLote.add_Click({ Import-LoteFromClipboard })
$btnValidarLote.add_Click({ [void](Validar-LoteServidores) })
$btnProcessarLote.add_Click({ Processar-LoteServidores })
$btnDesfazerLote.add_Click({ Desfazer-UltimoLote })
$btnLimparLote.add_Click({ $script:gridLote.Rows.Clear() })

$btnBackup.add_Click({
    try {
        $dest=Backup-AntesAcao "MANUAL"
        [Windows.Forms.MessageBox]::Show("Backup criado e validado:`n$dest","Férias DCE") | Out-Null
    } catch { Write-DiagLog "Backup manual não concluído." "ERROR" $_ }
})


$script:StartupPhase="INITIAL_REFRESH"
Write-DiagLog "FASE 3/5 - atualizando controles e grades iniciais."
foreach($gr in @($script:grid,$script:gridPeriodos,$script:gridImpacto,$script:gridResumo,$script:gridDia,$script:gridPlanejSetor,$script:gridLote,$script:gridHistServidores,$script:gridHistDetalhes,$script:gridHistComparacao,$script:gridHistLinhaTempo)){
    Apply-ProfessionalGridStyle $gr
}

Refresh-SetorPeriodos
Refresh-CadastrosLists
Refresh-FeriadosLists
Refresh-PlanejChefiasFiltro
Refresh-FiltrosLancAvancados
Update-SetoresFiltroResumo
Refresh-Grid
Clear-Editor
Refresh-PoliticaMensalInfo
Refresh-ConfigInfo
Refresh-ImportacaoStatus
Write-DiagLog "FASE 3/5 concluída."
$script:StartupPhase="AUTO_SYNC"
Write-DiagLog "FASE 4/5 - sincronização automática será iniciada somente depois que a janela principal estiver visível."
$script:AutoSyncTimer=$null
$script:PlanejWarmupTimer=$null
$script:PlanejWarmupClosed=$false
$script:PlanejBootSyncPending=$false
$form.add_Shown({
    if(-not $script:UiLazyLoaded.Painel){
        $tmrBootPainel=New-Object Windows.Forms.Timer
        $tmrBootPainel.Interval=120
        $tmrBootPainel.add_Tick({
            param($sender,$eventArgs)
            try { $sender.Stop(); $sender.Dispose() } catch {}
            if(-not $script:UiLazyLoaded.Painel -and $tabs.SelectedTab -eq $tabDash){
                Refresh-Dashboard
                $script:UiLazyLoaded.Painel=$true
            }
        })
        $tmrBootPainel.Start()
    }
})
$form.add_Shown({
    if([bool]$script:Config.sincronizar_ao_abrir -and -not [string]::IsNullOrWhiteSpace([string]$script:Config.planilha_base)){
        if($null -ne $script:lblSyncStatus){ $script:lblSyncStatus.Text="Janela aberta. Sincronização automática será verificada em instantes..." }
        $script:PlanejBootSyncPending=$true
        $script:AutoSyncTimer=New-Object Windows.Forms.Timer
        $script:AutoSyncTimer.Interval=900
        $script:AutoSyncTimer.add_Tick({
            try { $script:AutoSyncTimer.Stop(); $script:AutoSyncTimer.Dispose() } catch {}
            $script:AutoSyncTimer=$null
            $script:StartupPhase="AUTO_SYNC_APOS_JANELA"
            Write-DiagLog "Executando sincronização automática após a exibição da janela principal."
            try { Sync-FromBase $true } finally {
                $script:StartupPhase="SHOW_DIALOG"
                $script:PlanejBootSyncPending=$false
                Request-PlanejamentoWarmup
            }
        })
        $script:AutoSyncTimer.Start()
    } else { Request-PlanejamentoWarmup }
})
$script:StartupPhase="SHOW_DIALOG"
Write-DiagLog "FASE 5/5 - exibindo janela principal."
$form.add_FormClosed({
    $script:PlanejWarmupClosed=$true
    if($null -ne $script:PlanejWarmupTimer){$script:PlanejWarmupTimer.Stop()}
    if($null -ne $script:PlanejAsync){
        $script:PlanejAsync.Closing=$true
        $script:PlanejAsync.Pending=$null
        $script:PlanejAsync.Timer.Stop()
    }
})
[void]$form.ShowDialog()
Stop-PlanejamentoComputation
$script:StartupPhase="CLOSED"
Write-DiagLog "Janela principal encerrada normalmente."
if($script:InstanceMutexOwned -and $null -ne $script:InstanceMutex){
    try { $script:InstanceMutex.ReleaseMutex() | Out-Null } catch {}
    try { $script:InstanceMutex.Dispose() } catch {}
    $script:InstanceMutexOwned=$false
}
