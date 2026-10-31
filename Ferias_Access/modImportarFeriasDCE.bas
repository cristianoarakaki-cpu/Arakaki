Attribute VB_Name = "modImportarFeriasDCE"
Option Compare Database
Option Explicit

Public Sub ConferirFeriasDCE()
    F_Executar False
End Sub

Public Sub ImportarFeriasDCE()
    F_Executar True
End Sub

Private Sub F_Executar(ByVal Gravar As Boolean)
    On Error GoTo Falha
    Dim db As DAO.Database, ws As DAO.Workspace, td As DAO.TableDef
    Dim linhas As Collection, base As Object, incompletos As Object
    Dim dlg As Object, doc As Object, row As Object, d As Object, rs As DAO.Recordset
    Dim caminho As String, tabela As String, relatorio As String, lockPath As String
    Dim lockNum As Integer, transacao As Boolean, lockAberto As Boolean
    Dim novos As Long, inseridos As Long, pendencias As Long, limiteCP As Double, limiteAno As Long
    Dim resposta As String, ano As Long, alterarAno As Boolean, erro As String
    Dim limiteObs As Long, campo As Variant

    Set dlg = Application.FileDialog(3)
    dlg.Title = "Selecione o XML gerado pelo sistema de ferias"
    dlg.AllowMultiSelect = False
    dlg.Filters.Clear
    dlg.Filters.Add "Importacao de ferias", "*.xml"
    If dlg.Show <> -1 Then Exit Sub
    caminho = CStr(dlg.SelectedItems(1))
    Set db = CurrentDb
    tabela = F_Tabela(db)
    Set td = db.TableDefs(tabela)
    F_ValidarEstrutura td, limiteCP, limiteAno, limiteObs
    Set doc = F_LerXML(caminho)
    pendencias = doc.selectNodes("/FeriasDCE/Pendencias/Pendencia").Length
    Set linhas = F_Linhas(doc, limiteCP, limiteAno, limiteObs)
    F_RepeticoesArquivo linhas

    If Gravar And linhas.Count > 0 Then
        resposta = InputBox("Ano de programacao para os NOVOS registros (0000 para preencher depois)." & vbCrLf & "Em branco: mantem o XML. Cancelar: encerra.", "Importar ferias", "0000")
        If StrPtr(resposta) = 0 Then GoTo Encerrar
        resposta = Trim$(resposta)
        If Len(resposta) > 0 Then
            ano = F_Inteiro(resposta, 0, 9999)
            If ano > limiteAno Then Err.Raise vbObjectError + 2500, , "O ano excede o tipo numerico de Programacao_Ano."
            alterarAno = True
        End If
    End If
    F_LerBase db, tabela, base, incompletos
    F_Classificar linhas, base, incompletos
    For Each row In linhas
        row("Autorizado") = (row("Status") = "NOVO")
        If row("Autorizado") Then novos = novos + 1
    Next row
    relatorio = F_Relatorio(linhas, caminho, pendencias, "CONFERENCIA - nenhum dado gravado")
    F_AbrirRelatorio relatorio
    If Not Gravar Or novos = 0 Then
        MsgBox "Conferencia concluida. Novos elegiveis: " & novos & "." & vbCrLf & "Nenhum dado foi gravado. Consulte o relatorio." & vbCrLf & relatorio, vbInformation, "Ferias Access"
        GoTo Encerrar
    End If
    If MsgBox("O relatorio foi aberto para revisao." & vbCrLf & "Inserir somente os " & novos & " registros NOVOS e validos?" & vbCrLf & "Ja cadastrados, conflitos e invalidos nao serao inseridos. Registros existentes nao serao alterados." & vbCrLf & "Confirme tambem seu backup antes de prosseguir.", vbYesNo + vbQuestion + vbDefaultButton2, "Importar ferias") <> vbYes Then GoTo Encerrar

    ' Serializa importadores deste modulo no mesmo backend Access, inclusive em rede.
    lockPath = F_CaminhoBloqueio(db, td)
    lockNum = FreeFile
    On Error GoTo FalhaLock
    Open lockPath For Binary Access Read Write Lock Read Write As #lockNum
    lockAberto = True
    On Error GoTo Falha
    Set ws = DBEngine.Workspaces(0)
    ws.BeginTrans
    transacao = True
    ' Rele a tabela depois da confirmacao e do bloqueio para nao usar uma previa antiga.
    F_LerBase db, tabela, base, incompletos
    For Each row In linhas
        Select Case row("Status")
            Case "NOVO", "JA_EXISTE", "DIVERGENTE_BASE", "DUPLICATA_BASE"
                row("Status") = "CONFERIR"
                row("Motivo") = ""
        End Select
    Next row
    F_Classificar linhas, base, incompletos
    Set rs = db.OpenRecordset("SELECT " & F_ListaCampos() & " FROM [" & tabela & "]", dbOpenDynaset)
    For Each row In linhas
        If row("Status") = "NOVO" Then
            If row("Autorizado") Then
                Set d = row("Dados")
                If alterarAno Then d("Programacao_Ano") = ano
                rs.AddNew
                For Each campo In F_Campos()
                    If CStr(campo) = "Observação" And Len(F_Texto(d(campo))) = 0 Then
                        rs.Fields(campo).Value = Null
                    Else
                        rs.Fields(campo).Value = d(campo)
                    End If
                Next campo
                rs.Update
                row("Status") = "INSERIDO"
                row("Motivo") = "Novo registro inserido; ID_Ferias gerado pelo Access."
                inseridos = inseridos + 1
            Else
                row("Status") = "REVISAR"
                row("Motivo") = "A base mudou desde a previa; nova conferencia necessaria."
            End If
        End If
    Next row
    rs.Close
    Set rs = Nothing
    ws.CommitTrans dbForceOSFlush
    transacao = False
    Close #lockNum
    lockAberto = False
    ' O relatorio final e posterior ao commit; falhas nele nao desfazem um commit concluido.
    relatorio = F_Relatorio(linhas, caminho, pendencias, "IMPORTACAO CONCLUIDA - inseridos: " & inseridos)
    F_AbrirRelatorio relatorio
    MsgBox "Importacao concluida: " & inseridos & " registro(s) inserido(s)." & vbCrLf & "Os demais foram ignorados ou separados para revisao." & vbCrLf & relatorio, vbInformation, "Ferias Access"

Encerrar:
    On Error Resume Next
    If transacao Then ws.Rollback
    If Not rs Is Nothing Then rs.Close
    If lockAberto Then Close #lockNum
    Set rs = Nothing
    Set td = Nothing
    Set db = Nothing
    Set ws = Nothing
    Set dlg = Nothing
    Set doc = Nothing
    Set linhas = Nothing
    Set base = Nothing
    Set incompletos = Nothing
    Exit Sub
FalhaLock:
    erro = "Nao foi possivel reservar a importacao. Outro usuario pode estar importando ou a pasta do banco nao permite criar o arquivo de controle." & vbCrLf & lockPath & vbCrLf & Err.Description
    MsgBox erro & vbCrLf & "Nenhum dado foi gravado por esta tentativa.", vbExclamation, "Ferias Access"
    Resume Encerrar
Falha:
    erro = Err.Description
    If transacao Then
        On Error Resume Next
        Err.Clear
        ws.Rollback
        If Err.Number = 0 Then
            transacao = False
            erro = erro & vbCrLf & "A transacao foi desfeita; nenhuma insercao desta tentativa foi mantida."
        Else
            erro = erro & vbCrLf & "Nao foi possivel confirmar o rollback. Confira a tabela e o backup antes de repetir a operacao."
        End If
        On Error GoTo 0
    ElseIf inseridos > 0 Then
        erro = erro & vbCrLf & "A importacao ja havia sido confirmada: " & inseridos & " insercao(oes). Nao repita por colagem manual; use nova conferencia."
    Else
        erro = erro & vbCrLf & "Nenhum dado foi gravado."
    End If
    MsgBox "Falha: " & erro, vbExclamation, "Ferias Access"
    GoTo Encerrar
End Sub

Private Function F_Campos() As Variant
    F_Campos = Array("Codigo do Servidor", "Observação", "Periodo Aquisitivo_1", "Periodo Aquisitivo_2", "Agendar Após", "Ferias_30_Inicio", "Ferias_30_Final", "Ferias_Par_1QIn", "Ferias_Par_1QFin", "Ferias_Par_2QIn", "Ferias_Par_2QFin", "Programacao_Ano", "Processo_20Dias")
End Function

Private Function F_Dict() As Object
    Set F_Dict = CreateObject("Scripting.Dictionary")
    F_Dict.CompareMode = vbTextCompare
End Function

Private Function F_ListaCampos() As String
    Dim c As Variant, s As String
    For Each c In F_Campos()
        If Len(s) > 0 Then s = s & ","
        s = s & "[" & c & "]"
    Next c
    F_ListaCampos = s
End Function

Private Function F_Tabela(ByVal db As DAO.Database) As String
    Dim td As DAO.TableDef, quantidade As Long
    For Each td In db.TableDefs
        If StrComp(td.Name, "Ferias", vbTextCompare) = 0 Or StrComp(td.Name, "Férias", vbTextCompare) = 0 Then
            F_Tabela = td.Name
            quantidade = quantidade + 1
        End If
    Next td
    If quantidade <> 1 Then Err.Raise vbObjectError + 2501, , "Deve existir uma unica tabela chamada Ferias ou Férias. Confira o nome da tabela de destino."
End Function

Private Sub F_ValidarEstrutura(ByVal td As DAO.TableDef, ByRef LimiteCP As Double, ByRef LimiteAno As Long, ByRef LimiteObs As Long)
    Dim c As Variant, f As DAO.Field
    If (td.Attributes And dbAttachedODBC) <> 0 Then Err.Raise vbObjectError + 2502, , "Este importador e destinado a tabelas locais ou vinculadas a outro banco Access, nao ODBC."
    For Each c In F_Campos()
        Set f = td.Fields(CStr(c))
        Select Case CStr(c)
            Case "Codigo do Servidor", "Programacao_Ano"
                Select Case f.Type
                    Case dbByte: If CStr(c) = "Codigo do Servidor" Then LimiteCP = 255 Else LimiteAno = 255
                    Case dbInteger: If CStr(c) = "Codigo do Servidor" Then LimiteCP = 32767 Else LimiteAno = 32767
                    Case dbLong: If CStr(c) = "Codigo do Servidor" Then LimiteCP = 2147483647# Else LimiteAno = 2147483647
                    Case Else: Err.Raise vbObjectError + 2503, , "Tipo numerico inesperado em " & c
                End Select
            Case "Observação"
                If f.Type <> dbText Then Err.Raise vbObjectError + 2504, , "Observação deve ser Texto Curto."
                LimiteObs = f.Size
            Case "Processo_20Dias"
                If f.Type <> dbBoolean Then Err.Raise vbObjectError + 2505, , "Processo_20Dias deve ser Sim/Nao."
            Case Else
                If f.Type <> dbDate Then Err.Raise vbObjectError + 2506, , CStr(c) & " deve ser Data/Hora."
        End Select
    Next c
    Set f = td.Fields("ID_Ferias")
    If f.Type <> dbLong Or (f.Attributes And dbAutoIncrField) = 0 Then Err.Raise vbObjectError + 2507, , "ID_Ferias deve ser Numeracao Automatica."
End Sub

Private Function F_LerXML(ByVal Caminho As String) As Object
    Dim doc As Object, fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.GetFile(Caminho).Size > 33554432 Then Err.Raise vbObjectError + 2508, , "Arquivo excede o limite de 32 MB."
    Set doc = CreateObject("MSXML2.DOMDocument.6.0")
    doc.async = False
    doc.validateOnParse = False
    doc.resolveExternals = False
    doc.setProperty "ProhibitDTD", True
    If Not doc.Load(Caminho) Then Err.Raise vbObjectError + 2509, , "XML invalido: " & doc.parseError.reason
    If doc.selectNodes("/FeriasDCE[@versao='1']/Registros").Length <> 1 Then Err.Raise vbObjectError + 2510, , "Formato de importacao nao reconhecido. Gere o XML no menu do sistema de ferias."
    Set F_LerXML = doc
End Function

Private Function F_Linhas(ByVal Doc As Object, ByVal LimiteCP As Double, ByVal LimiteAno As Long, ByVal LimiteObs As Long) As Collection
    Dim resultado As New Collection, n As Object, row As Object, numero As Long
    For Each n In Doc.selectNodes("/FeriasDCE/Registros/Registro")
        numero = numero + 1
        Set row = F_Linha(n, numero, LimiteCP, LimiteAno, LimiteObs)
        resultado.Add row
    Next n
    Set F_Linhas = resultado
End Function

Private Function F_Linha(ByVal No As Object, ByVal Numero As Long, ByVal LimiteCP As Double, ByVal LimiteAno As Long, ByVal LimiteObs As Long) As Object
    On Error GoTo Invalida
    Dim row As Object, d As Object, campos As Object, c As Variant, n As Object, nome As String, valor As String, nulo As String
    Set row = F_Dict()
    Set d = F_Dict()
    Set campos = F_Dict()
    row.Add "Linha", Numero
    row.Add "Dados", d
    row.Add "Status", "INVALIDO"
    row.Add "Motivo", ""
    row.Add "Chave", ""
    row.Add "Assinatura", ""
    row.Add "Autorizado", False
    For Each c In F_Campos()
        campos.Add CStr(c), True
    Next c
    For Each n In No.selectNodes("Campo")
        nome = CStr(n.getAttribute("nome"))
        If Not campos.Exists(nome) Then Err.Raise vbObjectError + 2511, , "Campo desconhecido: " & nome
        If d.Exists(nome) Then Err.Raise vbObjectError + 2512, , "Campo repetido: " & nome
        valor = n.Text
        nulo = F_Texto(n.getAttribute("nulo"))
        If nulo <> "" And nulo <> "1" Then Err.Raise vbObjectError + 2513, , "Indicador nulo invalido em " & nome
        If nulo = "1" And Len(valor) > 0 Then Err.Raise vbObjectError + 2514, , "Valor e nulo simultaneos em " & nome
        Select Case nome
            Case "Codigo do Servidor"
                If nulo = "1" Then Err.Raise vbObjectError + 2515, , "CP ausente."
                d.Add nome, F_Inteiro(valor, 1, LimiteCP)
            Case "Programacao_Ano"
                If nulo = "1" Then Err.Raise vbObjectError + 2516, , "Ano de programacao ausente."
                d.Add nome, F_Inteiro(valor, 0, 9999)
                If d(nome) > LimiteAno Then Err.Raise vbObjectError + 2517, , "Ano nao cabe no tipo do campo."
            Case "Processo_20Dias"
                If nulo = "1" Or (valor <> "0" And valor <> "-1") Then Err.Raise vbObjectError + 2518, , "Processo_20Dias deve ser 0 ou -1."
                d.Add nome, CBool(CLng(valor))
            Case "Observação"
                If Len(valor) > LimiteObs Then Err.Raise vbObjectError + 2519, , "Observacao excede o tamanho do campo; nao foi truncada."
                d.Add nome, valor
            Case Else
                If nulo = "1" Then d.Add nome, Null Else d.Add nome, F_DataISO(valor)
        End Select
    Next n
    If d.Count <> campos.Count Then Err.Raise vbObjectError + 2520, , "Registro sem os 13 campos obrigatorios."
    F_ValidarDatas d
    row("Chave") = F_Chave(d)
    row("Assinatura") = F_Assinatura(d)
    row("Status") = "CONFERIR"
    Set F_Linha = row
    Exit Function
Invalida:
    row("Motivo") = Err.Description
    Set F_Linha = row
End Function

Private Function F_Texto(ByVal Valor As Variant) As String
    If IsNull(Valor) Or IsEmpty(Valor) Then Exit Function
    F_Texto = CStr(Valor)
End Function

Private Function F_Inteiro(ByVal Texto As String, ByVal Minimo As Double, ByVal Maximo As Double) As Long
    Dim i As Long, numero As Double, c As Long
    If Len(Texto) = 0 Or Len(Texto) > 10 Then Err.Raise vbObjectError + 2521, , "Numero inteiro ausente ou invalido."
    For i = 1 To Len(Texto)
        c = AscW(Mid$(Texto, i, 1))
        If c < 48 Or c > 57 Then Err.Raise vbObjectError + 2522, , "Numero deve conter apenas digitos."
    Next i
    numero = CDbl(Texto)
    If numero < Minimo Or numero > Maximo Then Err.Raise vbObjectError + 2523, , "Numero fora dos limites permitidos."
    F_Inteiro = CLng(numero)
End Function

Private Function F_DataISO(ByVal Texto As String) As Date
    Dim y As Long, m As Long, d As Long, valor As Date
    If Len(Texto) <> 10 Or Mid$(Texto, 5, 1) <> "-" Or Mid$(Texto, 8, 1) <> "-" Then Err.Raise vbObjectError + 2524, , "Data deve estar em YYYY-MM-DD."
    y = F_Inteiro(Left$(Texto, 4), 100, 9999)
    m = F_Inteiro(Mid$(Texto, 6, 2), 1, 12)
    d = F_Inteiro(Right$(Texto, 2), 1, 31)
    valor = DateSerial(y, m, d)
    If Format$(valor, "yyyy-mm-dd") <> Texto Then Err.Raise vbObjectError + 2525, , "Data inexistente no calendario."
    F_DataISO = valor
End Function

Private Sub F_ValidarDatas(ByVal d As Object)
    Dim c As Variant, quantidade As Long
    For Each c In Array("Periodo Aquisitivo_1", "Periodo Aquisitivo_2", "Agendar Após")
        If IsNull(d(c)) Then Err.Raise vbObjectError + 2526, , "Data obrigatoria ausente: " & c
    Next c
    If d("Periodo Aquisitivo_2") < d("Periodo Aquisitivo_1") Then Err.Raise vbObjectError + 2527, , "Aquisitivo invertido."
    If d("Agendar Após") <> DateAdd("d", 2, d("Periodo Aquisitivo_2")) Then Err.Raise vbObjectError + 2528, , "Agendar Apos deve ser fim do aquisitivo + 2 dias."
    If Not IsNull(d("Ferias_30_Inicio")) Or Not IsNull(d("Ferias_30_Final")) Then
        If IsNull(d("Ferias_30_Inicio")) Or IsNull(d("Ferias_30_Final")) Then Err.Raise vbObjectError + 2529, , "Intervalo unico incompleto."
        quantidade = 30
        If d("Processo_20Dias") Then quantidade = 20
        If DateDiff("d", d("Ferias_30_Inicio"), d("Ferias_30_Final")) <> quantidade - 1 Then Err.Raise vbObjectError + 2530, , "Intervalo unico deve ter " & quantidade & " dias."
        For Each c In Array("Ferias_Par_1QIn", "Ferias_Par_1QFin", "Ferias_Par_2QIn", "Ferias_Par_2QFin")
            If Not IsNull(d(c)) Then Err.Raise vbObjectError + 2531, , "Registro mistura intervalo unico e parcelas."
        Next c
    Else
        If d("Processo_20Dias") Then Err.Raise vbObjectError + 2532, , "FR aceita precisa de um intervalo de 20 dias."
        For Each c In Array("Ferias_Par_1QIn", "Ferias_Par_1QFin", "Ferias_Par_2QIn", "Ferias_Par_2QFin")
            If IsNull(d(c)) Then Err.Raise vbObjectError + 2533, , "Parcelas incompletas."
        Next c
        If DateDiff("d", d("Ferias_Par_1QIn"), d("Ferias_Par_1QFin")) <> 14 Or DateDiff("d", d("Ferias_Par_2QIn"), d("Ferias_Par_2QFin")) <> 14 Then Err.Raise vbObjectError + 2534, , "Cada parcela deve ter 15 dias."
        If d("Ferias_Par_1QIn") <= d("Ferias_Par_2QFin") And d("Ferias_Par_1QFin") >= d("Ferias_Par_2QIn") Then Err.Raise vbObjectError + 2535, , "Parcelas sobrepostas."
    End If
End Sub

Private Function F_Dia(ByVal Valor As Variant) As String
    F_Dia = "-"
    If Not IsNull(Valor) Then F_Dia = Format$(CDate(Valor), "yyyy-mm-dd")
End Function

Private Function F_Chave(ByVal d As Object) As String
    F_Chave = CStr(d("Codigo do Servidor")) & "|" & F_Dia(d("Periodo Aquisitivo_1")) & "|" & F_Dia(d("Periodo Aquisitivo_2"))
End Function

Private Function F_Assinatura(ByVal d As Object) As String
    Dim p1 As String, p2 As String, t As String
    p1 = F_Dia(d("Ferias_Par_1QIn")) & "/" & F_Dia(d("Ferias_Par_1QFin"))
    p2 = F_Dia(d("Ferias_Par_2QIn")) & "/" & F_Dia(d("Ferias_Par_2QFin"))
    If StrComp(p1, p2, vbBinaryCompare) > 0 Then t = p1: p1 = p2: p2 = t
    F_Assinatura = F_Dia(d("Ferias_30_Inicio")) & "/" & F_Dia(d("Ferias_30_Final")) & "|" & p1 & "|" & p2
End Function

Private Sub F_RepeticoesArquivo(ByVal Linhas As Collection)
    Dim grupos As Object, row As Object, grupo As Collection, chave As String, k As Variant
    Dim assinatura As String, diferentes As Boolean, i As Long
    Set grupos = F_Dict()
    For Each row In Linhas
        If row("Status") = "CONFERIR" Then
            chave = row("Chave") & "|" & CStr(CLng(row("Dados")("Processo_20Dias")))
            If Not grupos.Exists(chave) Then
                Set grupo = New Collection
                grupos.Add chave, grupo
            End If
            Set grupo = grupos(chave)
            grupo.Add row
        End If
    Next row
    For Each k In grupos.Keys
        Set grupo = grupos(k)
        assinatura = grupo(1)("Assinatura")
        diferentes = False
        For Each row In grupo
            If row("Assinatura") <> assinatura Then diferentes = True
        Next row
        For i = 1 To grupo.Count
            Set row = grupo(i)
            If diferentes Then
                row("Status") = "DIVERGENTE_ARQUIVO"
                row("Motivo") = "CP/aquisitivo/modalidade com datas diferentes no mesmo arquivo; nenhuma versao sera inserida."
            ElseIf i > 1 Then
                row("Status") = "REPETIDO_ARQUIVO"
                row("Motivo") = "Repeticao da mesma programacao no XML; nao gera nova linha."
            End If
        Next i
    Next k
End Sub

Private Sub F_LerBase(ByVal db As DAO.Database, ByVal Tabela As String, ByRef Indice As Object, ByRef Incompletos As Object)
    On Error GoTo Falha
    Dim rs As DAO.Recordset, d As Object, c As Variant, grupo As Collection, chave As String
    Set Indice = F_Dict()
    Set Incompletos = F_Dict()
    Set rs = db.OpenRecordset("SELECT " & F_ListaCampos() & " FROM [" & Tabela & "]", dbOpenSnapshot)
    Do Until rs.EOF
        Set d = F_Dict()
        For Each c In F_Campos()
            d.Add CStr(c), rs.Fields(c).Value
        Next c
        If Not IsNull(d("Codigo do Servidor")) Then
            If IsNull(d("Periodo Aquisitivo_1")) Or IsNull(d("Periodo Aquisitivo_2")) Then
                Incompletos(CStr(d("Codigo do Servidor"))) = True
            Else
                chave = F_Chave(d)
                If Not Indice.Exists(chave) Then
                    Set grupo = New Collection
                    Indice.Add chave, grupo
                End If
                Set grupo = Indice(chave)
                grupo.Add d
            End If
        End If
        rs.MoveNext
    Loop
    rs.Close
    Exit Sub
Falha:
    Dim numero As Long, descricao As String
    numero = Err.Number: descricao = Err.Description
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    On Error GoTo 0
    Err.Raise numero, , descricao
End Sub

Private Sub F_Classificar(ByVal Linhas As Collection, ByVal Indice As Object, ByVal Incompletos As Object)
    Dim row As Object, d As Object, existente As Object, iguais As Long, conflito As Boolean
    For Each row In Linhas
        If row("Status") = "CONFERIR" Then
            Set d = row("Dados")
            iguais = 0: conflito = False
            If Incompletos.Exists(CStr(d("Codigo do Servidor"))) Then
                conflito = True
                row("Motivo") = "A base tem aquisitivo incompleto para este CP. Confira antes de acrescentar."
            ElseIf Indice.Exists(row("Chave")) Then
                For Each existente In Indice(row("Chave"))
                    If IsNull(existente("Processo_20Dias")) Then
                        conflito = True
                    ElseIf CBool(existente("Processo_20Dias")) = CBool(d("Processo_20Dias")) Then
                        If F_Assinatura(existente) = row("Assinatura") Then iguais = iguais + 1 Else conflito = True
                    ElseIf F_Assinatura(existente) = row("Assinatura") Then
                        conflito = True
                    End If
                Next existente
            End If
            If conflito Then
                row("Status") = "DIVERGENTE_BASE"
                If Len(row("Motivo")) = 0 Then row("Motivo") = "Ja existe CP/aquisitivo/modalidade com outra programacao ou marcador de 20 dias divergente; nenhum dado sera sobrescrito."
            ElseIf iguais > 1 Then
                row("Status") = "DUPLICATA_BASE"
                row("Motivo") = "A tabela ja tem mais de uma copia destas ferias. Nao foi adicionada outra; corrija as existentes separadamente."
            ElseIf iguais = 1 Then
                row("Status") = "JA_EXISTE"
                row("Motivo") = "Ferias ja cadastradas. Ano, observacao e Agendar Apos existentes foram preservados."
            Else
                row("Status") = "NOVO"
                row("Motivo") = "Elegivel para insercao apos confirmacao."
            End If
        End If
    Next row
End Sub

Private Function F_CaminhoBloqueio(ByVal db As DAO.Database, ByVal td As DAO.TableDef) As String
    Dim caminho As String, parte As Variant, item As String, fso As Object
    caminho = db.Name
    If Len(td.Connect) > 0 Then
        caminho = ""
        For Each parte In Split(td.Connect, ";")
            item = CStr(parte)
            If UCase$(Left$(item, 9)) = "DATABASE=" Then caminho = Mid$(item, 10)
        Next parte
        If Len(caminho) = 0 Then Err.Raise vbObjectError + 2536, , "Nao foi possivel localizar o backend Access para coordenar a importacao."
    End If
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FileExists(caminho) Then Err.Raise vbObjectError + 2537, , "Arquivo do banco nao encontrado para o controle de importacao."
    ' O arquivo vazio permanece no local. Apenas o bloqueio aberto indica importacao ativa.
    F_CaminhoBloqueio = caminho & ".ferias-importacao.lock"
End Function

Private Function F_Html(ByVal Valor As Variant) As String
    Dim s As String
    s = F_Texto(Valor)
    s = Replace$(s, "&", "&amp;")
    s = Replace$(s, "<", "&lt;")
    s = Replace$(s, ">", "&gt;")
    s = Replace$(s, """", "&quot;")
    F_Html = Replace$(s, "'", "&#39;")
End Function

Private Function F_Relatorio(ByVal Linhas As Collection, ByVal Origem As String, ByVal Pendencias As Long, ByVal Titulo As String) As String
    On Error GoTo Falha
    Dim fso As Object, fluxo As Object, destino As String, row As Object, d As Object, contagem As Object, k As Variant
    Dim texto As String, c As Variant
    Set fso = CreateObject("Scripting.FileSystemObject")
    destino = fso.BuildPath(fso.GetSpecialFolder(2).Path, "CONFERENCIA_FERIAS_" & Replace$(fso.GetTempName, ".", "_") & ".html")
    Set fluxo = CreateObject("ADODB.Stream")
    fluxo.Type = 2: fluxo.Charset = "utf-8": fluxo.Open
    fluxo.WriteText "<!doctype html><html lang='pt-BR'><head><meta charset='utf-8'><title>Conferencia de ferias</title><style>body{font:13px Arial;margin:24px;color:#17324b}table{border-collapse:collapse;width:100%}th,td{border:1px solid #aab5c0;padding:7px;text-align:left;vertical-align:top;overflow-wrap:anywhere}th{background:#e8eff5}.NOVO{background:#eef7ff}.INSERIDO{background:#e3f5e7}.INVALIDO,.DIVERGENTE_BASE,.DIVERGENTE_ARQUIVO,.DUPLICATA_BASE{background:#fff0df}thead{display:table-header-group}tr{break-inside:avoid}@page{size:A4 landscape;margin:10mm}</style></head><body>"
    fluxo.WriteText "<h1>" & F_Html(Titulo) & "</h1><p>" & F_Html(Origem) & "</p><p>Gerado em " & Format$(Now, "dd/mm/yyyy hh:nn:ss") & "</p>"
    fluxo.WriteText "<p>Pendencias excluidas na origem: " & Pendencias & ". Consulte o cadastro/XML para trata-las; nao fazem parte da insercao.</p>"
    Set contagem = F_Dict()
    For Each row In Linhas
        k = CStr(row("Status"))
        If contagem.Exists(k) Then contagem(k) = contagem(k) + 1 Else contagem.Add k, 1
    Next row
    fluxo.WriteText "<ul>"
    For Each k In contagem.Keys
        fluxo.WriteText "<li>" & F_Html(k) & ": " & contagem(k) & "</li>"
    Next k
    fluxo.WriteText "</ul><table><thead><tr><th>Linha XML</th><th>Status</th><th>CP</th><th>Aquisitivo</th><th>Modalidade</th><th>Datas</th><th>Motivo</th></tr></thead><tbody>"
    For Each row In Linhas
        Set d = row("Dados")
        fluxo.WriteText "<tr class='" & F_Html(row("Status")) & "'><td>" & row("Linha") & "</td><td>" & F_Html(row("Status")) & "</td>"
        texto = "": If d.Exists("Codigo do Servidor") Then texto = F_Texto(d("Codigo do Servidor"))
        fluxo.WriteText "<td>" & F_Html(texto) & "</td>"
        texto = ""
        For Each c In Array("Periodo Aquisitivo_1", "Periodo Aquisitivo_2")
            If d.Exists(c) Then texto = texto & F_Dia(d(c)) & " "
        Next c
        fluxo.WriteText "<td>" & F_Html(texto) & "</td>"
        texto = "": If d.Exists("Processo_20Dias") Then If d("Processo_20Dias") Then texto = "FR 20 dias" Else texto = "Comum"
        fluxo.WriteText "<td>" & F_Html(texto) & "</td>"
        texto = ""
        For Each c In Array("Ferias_30_Inicio", "Ferias_30_Final", "Ferias_Par_1QIn", "Ferias_Par_1QFin", "Ferias_Par_2QIn", "Ferias_Par_2QFin")
            If d.Exists(c) Then texto = texto & F_Dia(d(c)) & " "
        Next c
        fluxo.WriteText "<td>" & F_Html(texto) & "</td><td>" & F_Html(row("Motivo")) & "</td></tr>"
    Next row
    fluxo.WriteText "</tbody></table><p>Este relatorio nao altera dados. Duplicatas ja existentes nao sao removidas automaticamente.</p></body></html>"
    fluxo.SaveToFile destino, 1
    fluxo.Close
    F_Relatorio = destino
    Exit Function
Falha:
    Dim numero As Long, descricao As String
    numero = Err.Number: descricao = Err.Description
    On Error Resume Next
    If Not fluxo Is Nothing Then fluxo.Close
    On Error GoTo 0
    Err.Raise numero, , descricao
End Function

Private Sub F_AbrirRelatorio(ByVal Caminho As String)
    On Error GoTo Falha
    Application.FollowHyperlink Address:=Caminho, NewWindow:=True
    Exit Sub
Falha:
    MsgBox "Relatorio salvo. Abra manualmente: " & Caminho, vbInformation, "Conferencia de ferias"
End Sub
