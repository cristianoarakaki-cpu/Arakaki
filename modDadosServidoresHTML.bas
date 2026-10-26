Attribute VB_Name = "modDadosServidoresHTML"
Option Compare Database
Option Explicit

Public Sub ExportarDadosServidoresHTML()
    On Error GoTo TrataErro
    Dim db As DAO.Database, rs As DAO.Recordset
    Dim filtro As String, filtroDesc As String, sql As String
    Dim entrada As String, ano As Long, mes As Long
    Dim dictSet As Object, dictCar As Object, dictHor As Object, dictCarHor As Object
    Dim grupo As Object, fluxo As Object, fso As Object
    Dim pasta As String, destino As String, setor As String, cargo As String, horario As String
    Dim i As Long, total As Long, detalhe As String, k As Variant, h As Variant

    filtro = " WHERE 1=1"
    If Not DS_PedirAno("Ano de Admissao (YYYY) ou deixe em branco:", "Filtro - Ano Admissao", entrada, ano) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND Year([Dados Funcionais].[Data Admissao])=" & CStr(ano)
        DS_Descricao filtroDesc, "Ano de Admissao = " & entrada
    End If
    If Not DS_PedirMesAno("Mes/Ano de Admissao (MM/YYYY) ou deixe em branco:", "Filtro - Mes/Ano Admissao", entrada, mes, ano) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND Month([Dados Funcionais].[Data Admissao])=" & CStr(mes) & " AND Year([Dados Funcionais].[Data Admissao])=" & CStr(ano)
        DS_Descricao filtroDesc, "Admissao em " & entrada
    End If
    If Not DS_PedirAno("Ano de Vencimento de Contrato (YYYY) ou deixe em branco:", "Filtro - Ano Venc Contrato", entrada, ano) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND Year([Dados Funcionais].[Data Venc Contrato])=" & CStr(ano)
        DS_Descricao filtroDesc, "Ano Venc Contrato = " & entrada
    End If
    If Not DS_PedirMesAno("Mes/Ano de Vencimento de Contrato (MM/YYYY) ou deixe em branco:", "Filtro - Mes/Ano Venc Contrato", entrada, mes, ano) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND Month([Dados Funcionais].[Data Venc Contrato])=" & CStr(mes) & " AND Year([Dados Funcionais].[Data Venc Contrato])=" & CStr(ano)
        DS_Descricao filtroDesc, "Venc Contrato em " & entrada
    End If
    If Not DS_PedirTexto("Setor (ou parte) ou deixe em branco:", "Filtro - Setor", entrada) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND Setores.Setor LIKE '*" & Replace$(entrada, "'", "''") & "*'"
        DS_Descricao filtroDesc, "Setor contem " & entrada
    End If
    If Not DS_PedirTexto("Cargo (ou parte) ou deixe em branco:", "Filtro - Cargo", entrada) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND [Dados Funcionais].Cargo LIKE '*" & Replace$(entrada, "'", "''") & "*'"
        DS_Descricao filtroDesc, "Cargo contem " & entrada
    End If
    If Not DS_PedirTexto("Tipo de Vinculo (Concurso, Contrato etc.) ou deixe em branco:", "Filtro - Tipo de Vinculo", entrada) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND [Dados Funcionais].[Tipo de Vinculo] LIKE '*" & Replace$(entrada, "'", "''") & "*'"
        DS_Descricao filtroDesc, "Vinculo contem " & entrada
    End If
    If Not DS_PedirTexto("Nome do Servidor (ou parte) ou deixe em branco:", "Filtro - Nome do Servidor", entrada) Then GoTo Limpeza
    If Len(entrada) > 0 Then
        filtro = filtro & " AND [Cadastro Pessoal].[Nome do Servidor] LIKE '*" & Replace$(entrada, "'", "''") & "*'"
        DS_Descricao filtroDesc, "Servidor contem " & entrada
    End If
    If Len(filtroDesc) = 0 Then filtroDesc = "Todos os registros"

    sql = "SELECT [Cadastro Pessoal].[Codigo do Servidor], [Cadastro Pessoal].[Nome do Servidor], "
    sql = sql & "[Dados Funcionais].Cargo, [Dados Funcionais].[Tipo de Vinculo], [Dados Funcionais].[Data Admissao], "
    sql = sql & "[Dados Funcionais].[Data Venc Contrato], Setores.Setor, Setores.[Horário de Trabalho], Setores.[Data Saida] "
    sql = sql & "FROM ([Cadastro Pessoal] INNER JOIN [Dados Funcionais] ON [Cadastro Pessoal].[Codigo do Servidor]=[Dados Funcionais].[Codigo do Servidor]) "
    sql = sql & "INNER JOIN Setores ON [Dados Funcionais].[Codigo do Servidor]=Setores.[Codigo do Servidor] "
    sql = sql & filtro & " AND Nz(Setores.Setor,'') NOT IN ('ENCERRAMENTO DE CONTRATO','EXONERACAO','APOSENTADORIA','REDISTRIBUIDO','CEDIDOS','VACANCIA','DESISTENCIA') "
    sql = sql & "ORDER BY Setores.Setor, [Cadastro Pessoal].[Nome do Servidor];"
    Set db = CurrentDb
    Set rs = db.OpenRecordset(sql, dbOpenSnapshot)
    If rs.EOF Then
        MsgBox "Nenhum registro encontrado.", vbInformation, "Dados dos servidores"
        GoTo Limpeza
    End If

    Set dictSet = DS_Dicionario()
    Set dictCar = DS_Dicionario()
    Set dictHor = DS_Dicionario()
    Set dictCarHor = DS_Dicionario()
    Set fso = CreateObject("Scripting.FileSystemObject")
    pasta = DS_PastaDestino(fso)
    destino = fso.BuildPath(pasta, "Dados_Servidores_" & Format$(Now, "yyyymmdd_hhnnss") & "_" & Replace$(fso.GetTempName, ".", "_") & ".html")
    Set fluxo = CreateObject("ADODB.Stream")
    fluxo.Type = 2
    fluxo.Charset = "utf-8"
    fluxo.Open
    fluxo.WriteText DS_InicioHTML(filtroDesc)
    fluxo.WriteText "<section id='detalhado' class='painel ativo'><h2>Detalhado</h2><div class='rolagem'><table><thead><tr>"
    For i = 0 To rs.Fields.Count - 1
        fluxo.WriteText "<th scope='col'>" & DS_Html(rs.Fields(i).Name) & "</th>"
    Next i
    fluxo.WriteText "</tr></thead><tbody>"
    Do Until rs.EOF
        total = total + 1
        fluxo.WriteText "<tr>"
        For i = 0 To rs.Fields.Count - 1
            fluxo.WriteText "<td>" & DS_Html(DS_ValorCampo(rs.Fields(i))) & "</td>"
        Next i
        fluxo.WriteText "</tr>" & vbCrLf
        setor = DS_Texto(rs.Fields("Setor").Value)
        cargo = DS_Texto(rs.Fields("Cargo").Value)
        horario = DS_Texto(rs.Fields("Horário de Trabalho").Value)
        DS_Contar dictSet, setor
        DS_Contar dictCar, cargo
        DS_Contar dictHor, horario
        If Len(Trim$(cargo)) > 0 And Len(Trim$(horario)) > 0 Then
            If Not dictCarHor.Exists(cargo) Then
                Set grupo = DS_Dicionario()
                dictCarHor.Add cargo, grupo
            End If
            Set grupo = dictCarHor(cargo)
            DS_Contar grupo, horario
        End If
        rs.MoveNext
    Loop
    fluxo.WriteText "</tbody></table></div><p class='total'>Total de registros: " & CStr(total) & "</p></section>"
    fluxo.WriteText "<section id='consolidado' class='painel'><h2>Consolidado</h2><p>Total de registros da consulta: " & CStr(total) & "</p><div class='resumos'>"
    DS_Resumo fluxo, "Resumo por Setor", "Setor", dictSet
    DS_Resumo fluxo, "Resumo por Cargo", "Cargo", dictCar
    DS_Resumo fluxo, "Resumo por Horário de Trabalho", "Horário de Trabalho", dictHor
    fluxo.WriteText "<article><h3>Resumo por Cargo e Horário de Trabalho</h3><table><thead><tr><th>Cargo</th><th>Horário de Trabalho</th><th>Total</th></tr></thead><tbody>"
    For Each k In dictCarHor.Keys
        Set grupo = dictCarHor(k)
        For Each h In grupo.Keys
            fluxo.WriteText "<tr><td>" & DS_Html(CStr(k)) & "</td><td>" & DS_Html(CStr(h)) & "</td><td class='numero'>" & CStr(grupo(h)) & "</td></tr>"
        Next h
    Next k
    If dictCarHor.Count = 0 Then fluxo.WriteText "<tr><td colspan='3'>Sem cargo e horario preenchidos para consolidar.</td></tr>"
    fluxo.WriteText "</tbody></table></article></div></section>"
    fluxo.WriteText DS_FimHTML()
    fluxo.SaveToFile destino, 1
    fluxo.Close
    Set fluxo = Nothing
    rs.Close
    Set rs = Nothing
    Set db = Nothing
    Application.FollowHyperlink Address:=destino, NewWindow:=True

Limpeza:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not fluxo Is Nothing Then fluxo.Close
    Set rs = Nothing
    Set db = Nothing
    Set fluxo = Nothing
    Set dictSet = Nothing
    Set dictCar = Nothing
    Set dictHor = Nothing
    Set dictCarHor = Nothing
    Set grupo = Nothing
    Set fso = Nothing
    Exit Sub
TrataErro:
    detalhe = "Erro " & CStr(Err.Number) & ": " & Err.Description
    If Len(destino) > 0 Then detalhe = detalhe & vbCrLf & vbCrLf & "Arquivo HTML: " & destino
    MsgBox detalhe, vbExclamation, "Dados dos servidores"
    Resume Limpeza
End Sub

Private Function DS_PedirTexto(ByVal Pergunta As String, ByVal Titulo As String, ByRef Resposta As String) As Boolean
    Resposta = InputBox(Pergunta & vbCrLf & "Em branco: sem este filtro. Cancelar: encerra a exportacao.", Titulo)
    If StrPtr(Resposta) = 0 Then Exit Function
    Resposta = Trim$(Resposta)
    DS_PedirTexto = True
End Function

Private Function DS_Digitos(ByVal Valor As String) As Boolean
    Dim i As Long, c As Long
    If Len(Valor) = 0 Then Exit Function
    For i = 1 To Len(Valor)
        c = AscW(Mid$(Valor, i, 1))
        If c < 48 Or c > 57 Then Exit Function
    Next i
    DS_Digitos = True
End Function

Private Function DS_PedirAno(ByVal Pergunta As String, ByVal Titulo As String, ByRef Entrada As String, ByRef Ano As Long) As Boolean
    Do
        If Not DS_PedirTexto(Pergunta, Titulo, Entrada) Then Exit Function
        If Len(Entrada) = 0 Then DS_PedirAno = True: Exit Function
        If Len(Entrada) = 4 And DS_Digitos(Entrada) Then
            Ano = CLng(Entrada)
            If Ano >= 1000 And Ano <= 9999 Then DS_PedirAno = True: Exit Function
        End If
        MsgBox "Informe um ano com quatro digitos, como 2026.", vbInformation, Titulo
    Loop
End Function

Private Function DS_PedirMesAno(ByVal Pergunta As String, ByVal Titulo As String, ByRef Entrada As String, ByRef Mes As Long, ByRef Ano As Long) As Boolean
    Do
        If Not DS_PedirTexto(Pergunta, Titulo, Entrada) Then Exit Function
        If Len(Entrada) = 0 Then DS_PedirMesAno = True: Exit Function
        If Len(Entrada) = 7 And Mid$(Entrada, 3, 1) = "/" Then
            If DS_Digitos(Left$(Entrada, 2)) And DS_Digitos(Right$(Entrada, 4)) Then
                Mes = CLng(Left$(Entrada, 2)): Ano = CLng(Right$(Entrada, 4))
                If Mes >= 1 And Mes <= 12 And Ano >= 1000 And Ano <= 9999 Then DS_PedirMesAno = True: Exit Function
            End If
        End If
        MsgBox "Informe mes e ano no formato MM/YYYY, como 08/2026.", vbInformation, Titulo
    Loop
End Function

Private Sub DS_Descricao(ByRef Atual As String, ByVal Parte As String)
    If Len(Atual) > 0 Then Atual = Atual & "; "
    Atual = Atual & Parte
End Sub

Private Function DS_Dicionario() As Object
    Set DS_Dicionario = CreateObject("Scripting.Dictionary")
    DS_Dicionario.CompareMode = vbTextCompare
End Function

Private Sub DS_Contar(ByVal Dicionario As Object, ByVal Valor As String)
    If Len(Trim$(Valor)) = 0 Then Exit Sub
    If Dicionario.Exists(Valor) Then
        Dicionario(Valor) = CLng(Dicionario(Valor)) + 1
    Else
        Dicionario.Add Valor, 1&
    End If
End Sub

Private Function DS_Texto(ByVal Valor As Variant) As String
    If IsNull(Valor) Or IsEmpty(Valor) Then Exit Function
    DS_Texto = CStr(Valor)
End Function

Private Function DS_ValorCampo(ByVal Campo As DAO.Field) As String
    If IsNull(Campo.Value) Then Exit Function
    If Campo.Type = dbDate Then
        If TimeValue(CDate(Campo.Value)) = 0 Then
            DS_ValorCampo = Format$(Campo.Value, "dd/mm/yyyy")
        Else
            DS_ValorCampo = Format$(Campo.Value, "dd/mm/yyyy hh:nn:ss")
        End If
    Else
        DS_ValorCampo = DS_Texto(Campo.Value)
    End If
End Function

Private Function DS_Html(ByVal Valor As String) As String
    Valor = Replace$(Valor, "&", "&amp;")
    Valor = Replace$(Valor, "<", "&lt;")
    Valor = Replace$(Valor, ">", "&gt;")
    Valor = Replace$(Valor, """", "&quot;")
    Valor = Replace$(Valor, "'", "&#39;")
    DS_Html = Valor
End Function

Private Function DS_PastaDestino(ByVal FSO As Object) As String
    On Error GoTo Temporaria
    Dim shell As Object, pasta As String
    Set shell = CreateObject("WScript.Shell")
    pasta = CStr(shell.SpecialFolders("Desktop"))
    If Len(pasta) > 0 Then
        If FSO.FolderExists(pasta) Then DS_PastaDestino = pasta: Exit Function
    End If
Temporaria:
    DS_PastaDestino = FSO.GetSpecialFolder(2).Path
End Function

Private Sub DS_Resumo(ByVal Fluxo As Object, ByVal Titulo As String, ByVal Coluna As String, ByVal Dicionario As Object)
    Dim k As Variant
    Fluxo.WriteText "<article><h3>" & DS_Html(Titulo) & "</h3><table><thead><tr><th>" & DS_Html(Coluna) & "</th><th>Total</th></tr></thead><tbody>"
    For Each k In Dicionario.Keys
        Fluxo.WriteText "<tr><td>" & DS_Html(CStr(k)) & "</td><td class='numero'>" & CStr(Dicionario(k)) & "</td></tr>"
    Next k
    If Dicionario.Count = 0 Then Fluxo.WriteText "<tr><td colspan='2'>Sem valores preenchidos para consolidar.</td></tr>"
    Fluxo.WriteText "</tbody></table></article>"
End Sub

Private Function DS_InicioHTML(ByVal Filtro As String) As String
    Dim s As String
    s = "<!doctype html><html lang='pt-BR'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Dados dos Servidores</title><style>"
    s = s & "*{box-sizing:border-box}body{margin:0;font:14px Arial,sans-serif;color:#172c3d;background:#edf1f5}.barra{display:flex;flex-wrap:wrap;gap:8px;align-items:center;background:#173c59;color:white;padding:14px 20px}.barra button{padding:9px 13px;background:white;color:#173c59;border:1px solid #c6d2dc;border-radius:4px;cursor:pointer}.barra button[aria-pressed=true]{background:#cce3f3}.barra .aviso{font-size:12px}main{max-width:1500px;margin:20px auto;padding:24px;background:white}h1{margin:0 0 12px;font-size:24px}h2{font-size:20px}h3{font-size:16px}.filtro{padding:12px;background:#edf3f8;overflow-wrap:anywhere}.meta,.total{font-size:12px;color:#4a6072}"
    s = s & ".painel{display:none}.painel.ativo{display:block}.rolagem{overflow-x:auto}table{width:100%;border-collapse:collapse}th,td{border:1px solid #acbac5;text-align:left;padding:8px;vertical-align:top;overflow-wrap:anywhere}th{background:#e8eff5}tbody tr:nth-child(even){background:#f6f8fa}.numero{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}.resumos{display:grid;grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:20px}.resumos article{min-width:0}thead{display:table-header-group}tr,article{break-inside:avoid}"
    s = s & "@page{size:A4 landscape;margin:12mm}@media print{body{background:white;color:black}.barra{display:none}main{max-width:none;margin:0;padding:0}.rolagem{overflow:visible}th,td{font-size:10px;padding:5px}th{print-color-adjust:exact}.resumos{display:block}.resumos article{margin-bottom:18px;break-inside:auto}.imprimir-tudo .painel{display:block}.imprimir-tudo #consolidado{break-before:page}}"
    s = s & "</style></head><body><nav class='barra' aria-label='Relatorios'><button type='button' data-painel='detalhado' aria-pressed='true'>Detalhado</button><button type='button' data-painel='consolidado' aria-pressed='false'>Consolidado</button><button type='button' id='imprimir'>Imprimir / Salvar PDF</button><button type='button' id='imprimir-tudo'>Imprimir tudo</button><span class='aviso'>Consulta somente leitura. Os filtros estao descritos abaixo.</span></nav><main><h1>Dados dos Servidores</h1>"
    s = s & "<p class='meta'>Gerado em " & Format$(Now, "dd/mm/yyyy hh:nn") & "</p><p class='filtro'><strong>Filtro:</strong> " & DS_Html(Filtro) & "</p>"
    DS_InicioHTML = s
End Function

Private Function DS_FimHTML() As String
    Dim s As String
    s = "</main><script>document.querySelectorAll('[data-painel]').forEach(function(b){b.addEventListener('click',function(){document.querySelectorAll('.painel').forEach(function(p){p.classList.toggle('ativo',p.id===b.dataset.painel);});document.querySelectorAll('[data-painel]').forEach(function(x){x.setAttribute('aria-pressed',String(x===b));});});});"
    s = s & "document.getElementById('imprimir').addEventListener('click',function(){document.body.classList.remove('imprimir-tudo');window.print();});document.getElementById('imprimir-tudo').addEventListener('click',function(){document.body.classList.add('imprimir-tudo');window.print();});window.addEventListener('afterprint',function(){document.body.classList.remove('imprimir-tudo');});</script></body></html>"
    DS_FimHTML = s
End Function
