Attribute VB_Name = "modProtocoloHTML"
Option Compare Database
Option Explicit

' Importar este modulo no Access. No evento Ao Clicar do botao:
'     GerarProtocoloHTML Me
' Se houver mais de uma grade compativel:
'     GerarProtocoloHTML Me, "NomeDoControleSubformulario"
Public Sub GerarProtocoloHTML(ByVal Tela As Access.Form, Optional ByVal NomeControleGrade As String = "", Optional ByVal TituloProtocolo As String = "PROTOCOLO_ESTAGIO PROBATORIO_ENFERMAGEM")
    On Error GoTo Falha
    Dim grade As Access.Form, rs As Object, candidatos As Collection
    Dim campoMat As String, campoNome As String, campoCargo As String
    Dim pasta As String, destino As String, fluxo As Object, fso As Object
    Dim total As Long, nome As String, inicio As String

    If Len(NomeControleGrade) > 0 Then
        Set grade = SubformularioCarregado(Tela.Controls(NomeControleGrade))
        If grade Is Nothing Then Err.Raise vbObjectError + 2104, , "O controle informado nao e um subformulario carregado."
    Else
        Set candidatos = New Collection
        BuscarGrades Tela, candidatos
        If candidatos.Count = 1 Then
            Set grade = candidatos(1)
        ElseIf candidatos.Count > 1 Then
            Err.Raise vbObjectError + 2101, , "Existe mais de uma grade com Matricula, Nome e Cargo. Informe o nome do controle de subformulario na chamada do botao."
        ElseIf TemCamposProtocolo(Tela) Then
            Set grade = Tela
        Else
            Err.Raise vbObjectError + 2102, , "Nao foi encontrada uma grade com os campos Matricula, Nome e Cargo. Confira os nomes dos campos na origem da grade."
        End If
    End If

    ' RecordsetClone conserva o conjunto filtrado e a ordem do formulario.
    ' A leitura nao move o registro selecionado e nao grava nada no banco.
    Set rs = grade.RecordsetClone
    campoMat = NomeCampo(rs, Array("Matricula", "Matrícula"))
    campoNome = NomeCampo(rs, Array("Nome", "Nome do Servidor", "NomeServidor", "Nome do servidor"))
    campoCargo = NomeCampo(rs, Array("Cargo"))
    If Len(campoMat) = 0 Or Len(campoNome) = 0 Or Len(campoCargo) = 0 Then
        Err.Raise vbObjectError + 2103, , "A origem da grade precisa fornecer Matricula, Nome e Cargo."
    End If
    If rs.BOF And rs.EOF Then
        MsgBox "Nao existem registros no filtro atual para gerar o protocolo.", vbInformation, "Protocolo"
        GoTo Encerrar
    End If

    Set fso = CreateObject("Scripting.FileSystemObject")
    pasta = fso.BuildPath(fso.GetSpecialFolder(2).Path, "SYSENF_DCE_Protocolos")
    If Not fso.FolderExists(pasta) Then fso.CreateFolder pasta
    destino = fso.BuildPath(pasta, "Protocolo_" & Format$(Now, "yyyymmdd_hhnnss") & "_" & Replace$(fso.GetTempName, ".", "_") & ".html")
    Set fluxo = CreateObject("ADODB.Stream")
    fluxo.Type = 2
    fluxo.Charset = "utf-8"
    fluxo.Open
    If Len(Trim$(TituloProtocolo)) = 0 Then TituloProtocolo = "PROTOCOLO_ESTAGIO PROBATORIO_ENFERMAGEM"
    fluxo.WriteText InicioHTML(TituloProtocolo)
    rs.MoveFirst
    Do Until rs.EOF
        total = total + 1
        nome = TextoCampo(rs.Fields(campoNome).Value)
        inicio = "<tr><td class='matricula'>" & HtmlE(TextoCampo(rs.Fields(campoMat).Value)) & "</td><td>" & HtmlE(nome) & "</td><td>" & HtmlE(TextoCampo(rs.Fields(campoCargo).Value)) & "</td><td class='semestre'>"
        fluxo.WriteText inicio & "<select aria-label='Semestre de " & HtmlE(nome) & "'><option value=''>Selecione</option><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select><span class='valor-impressao' aria-hidden='true'>-</span></td></tr>" & vbCrLf
        rs.MoveNext
    Loop
    fluxo.WriteText FimHTML(total)
    ' adSaveCreateNotExist: nunca sobrescreve um protocolo anterior.
    fluxo.SaveToFile destino, 1
    fluxo.Close
    Set fluxo = Nothing
    Application.FollowHyperlink Address:=destino, NewWindow:=True

Encerrar:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not fluxo Is Nothing Then fluxo.Close
    Set rs = Nothing
    Set fluxo = Nothing
    Set grade = Nothing
    Set candidatos = Nothing
    Set fso = Nothing
    Exit Sub
Falha:
    Dim detalhe As String
    detalhe = Err.Description
    If Len(destino) > 0 Then detalhe = detalhe & vbCrLf & vbCrLf & "Arquivo: " & destino
    MsgBox "Nao foi possivel gerar ou abrir o protocolo." & vbCrLf & vbCrLf & detalhe, vbExclamation, "Protocolo"
    Resume Encerrar
End Sub

Private Sub BuscarGrades(ByVal Tela As Access.Form, ByRef Resultado As Collection)
    Dim controle As Access.Control, filha As Access.Form
    For Each controle In Tela.Controls
        If controle.ControlType = acSubform Then
            Set filha = SubformularioCarregado(controle)
            If Not filha Is Nothing Then
                If TemCamposProtocolo(filha) Then Resultado.Add filha
                BuscarGrades filha, Resultado
            End If
        End If
    Next controle
End Sub

Private Function SubformularioCarregado(ByVal Controle As Object) As Access.Form
    On Error Resume Next
    Set SubformularioCarregado = Controle.Form
End Function

Private Function TemCamposProtocolo(ByVal Tela As Access.Form) As Boolean
    On Error GoTo Sair
    Dim rs As Object
    Set rs = Tela.RecordsetClone
    TemCamposProtocolo = Len(NomeCampo(rs, Array("Matricula", "Matrícula"))) > 0 _
        And Len(NomeCampo(rs, Array("Nome", "Nome do Servidor", "NomeServidor", "Nome do servidor"))) > 0 _
        And Len(NomeCampo(rs, Array("Cargo"))) > 0
Sair:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    Set rs = Nothing
End Function

Private Function NomeCampo(ByVal rs As Object, ByVal Alternativas As Variant) As String
    Dim item As Variant, campo As Object
    For Each item In Alternativas
        For Each campo In rs.Fields
            If StrComp(campo.Name, CStr(item), vbTextCompare) = 0 Then
                NomeCampo = campo.Name
                Exit Function
            End If
        Next campo
    Next item
End Function

Private Function TextoCampo(ByVal Valor As Variant) As String
    If IsNull(Valor) Or IsEmpty(Valor) Then
        TextoCampo = ""
    Else
        TextoCampo = CStr(Valor)
    End If
End Function

Private Function HtmlE(ByVal Valor As String) As String
    Valor = Replace$(Valor, "&", "&amp;")
    Valor = Replace$(Valor, "<", "&lt;")
    Valor = Replace$(Valor, ">", "&gt;")
    Valor = Replace$(Valor, """", "&quot;")
    Valor = Replace$(Valor, "'", "&#39;")
    HtmlE = Valor
End Function

Private Function InicioHTML(ByVal TituloProtocolo As String) As String
    Dim s As String
    s = "<!doctype html><html lang='pt-BR'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>" & HtmlE(TituloProtocolo) & "</title><style>"
    s = s & "*{box-sizing:border-box}body{font:14px Arial,sans-serif;color:#172c3d;background:#edf1f5;margin:0}.barra{flex-wrap:wrap;padding:14px 24px;background:#173c59;color:white;display:flex;gap:12px;align-items:center}.barra button{padding:9px 14px;border:0;border-radius:4px;cursor:pointer;background:white;color:#173c59}.folha{max-width:1100px;margin:24px auto;background:white;padding:28px}h1{font-size:23px;margin:0 0 8px}.meta{font-size:12px;color:#526575;margin:0 0 18px}"
    s = s & "table{border-collapse:collapse;width:100%;table-layout:fixed}th,td{border:1px solid #aab6bf;padding:9px;text-align:left;overflow-wrap:anywhere}th{background:#e8eff5}th:nth-child(1){width:16%}th:nth-child(2){width:36%}th:nth-child(3){width:34%}th:nth-child(4){width:14%}.matricula{font-variant-numeric:tabular-nums}.semestre{text-align:center}select{font:inherit;padding:5px;width:100%;max-width:125px}.valor-impressao{display:none}.total{font-size:12px;margin-top:14px}thead{display:table-header-group}tr{break-inside:avoid}"
    s = s & ".titulo-config{display:flex;align-items:center;gap:8px;flex:1 1 420px}.titulo-config input{font:inherit;padding:7px;border:1px solid #c8d0d8;border-radius:4px;min-width:180px;flex:1}h1{overflow-wrap:anywhere}.recebido{border:2px solid #536575;padding:16px 20px;margin:30px 0 0 auto;max-width:560px;break-inside:avoid;page-break-inside:avoid;color:#172c3d}.recebido strong{display:block;text-align:center;letter-spacing:2px;margin-bottom:16px}.recebido p{margin:12px 0}.recebido .assinatura{display:flex;align-items:baseline;gap:8px}.recebido .linha{border-bottom:1px solid currentColor;flex:1;min-width:90px}"
    s = s & "@page{size:A4 portrait;margin:12mm}@media print{body{background:white;color:black}.barra{display:none}.folha{max-width:none;margin:0;padding:0}select{display:none}.valor-impressao{display:inline}th,td{padding:6px;font-size:11px}th{background:#eee;print-color-adjust:exact}}"
    s = s & "</style></head><body><div class='barra'><button type='button' id='imprimir'>Imprimir / Salvar PDF</button><label class='titulo-config' for='titulo-config'>Titulo:<input id='titulo-config' type='text' value='" & HtmlE(TituloProtocolo) & "'></label><span>Escolha o semestre de cada servidor. As escolhas nao alteram o banco do Access.</span></div><main class='folha'><h1 id='titulo-protocolo'>" & HtmlE(TituloProtocolo) & "</h1><p class='meta'>Registros do filtro atual | Gerado em " & Format$(Now, "dd/mm/yyyy hh:nn") & "</p><table><thead><tr><th>Matricula</th><th>Nome do Servidor</th><th>Cargo</th><th>Semestre</th></tr></thead><tbody>"
    InicioHTML = s
End Function

Private Function FimHTML(ByVal Total As Long) As String
    Dim s As String
    s = "</tbody></table><p class='total'>Total de registros: " & CStr(Total) & "</p><footer class='recebido' aria-label='Carimbo de recebido'><strong>RECEBIDO</strong><p>Data ____/_____/<span id='ano-recebido'>" & CStr(Year(Date)) & "</span></p><p class='assinatura'>Recebido por: <span class='linha' aria-label='Espaco para nome e assinatura'>&nbsp;</span></p></footer></main><script>"
    s = s & "var tituloInicial=document.getElementById('titulo-protocolo').textContent;function atualizarTitulo(){var t=document.getElementById('titulo-config').value.trim()||tituloInicial;document.getElementById('titulo-protocolo').textContent=t;document.title=t;}document.getElementById('titulo-config').addEventListener('input',atualizarTitulo);"
    s = s & "function atualizar(){atualizarTitulo();document.getElementById('ano-recebido').textContent=new Date().getFullYear();document.querySelectorAll('td.semestre').forEach(function(td){td.querySelector('.valor-impressao').textContent=td.querySelector('select').value||'-';});}"
    s = s & "document.addEventListener('change',atualizar);window.addEventListener('beforeprint',atualizar);window.addEventListener('pageshow',atualizar);document.getElementById('imprimir').addEventListener('click',function(){atualizar();window.print();});atualizar();"
    FimHTML = s & "</script></body></html>"
End Function
