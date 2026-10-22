# Sistema de Escala DCE - V1.0.14.83-G1 PROFISSIONAL - FLUXO GUIADO / INICIALIZADOR UNIVERSAL - SQLite
# V1.0.14.83 - ROBUSTEZ SQL: padronizacao Sql-Int por escopo em IDs numericos interpolados nas rotinas revisadas.
# V1.0.14.81 - HOTFIX DASHBOARD: argumentos Color.FromArgb tipados corretamente ao aplicar o estilo padrao.
# - Mantida a interface Original/V79 como opcao de compatibilidade.
# - Quatro novos estilos visuais inspirados nos modelos aprovados: Moderna, Painel Lateral, Fluxo Guiado e Dashboard Profissional.
# - Dashboard Profissional e o novo padrao quando ainda nao existe preferencia salva.
# - Os estilos reaproveitam os mesmos controles e handlers; nenhuma regra de escala, ocorrencia, impressao ou banco foi removida.
# - Configuracoes > Geral / Interface > Estilo da aba Escala permite trocar e salvar o visual.
# - Cards, painel lateral e faixa guiada sao apenas informativos/atalhos e nao duplicam dados no banco.
# V1.0.14.79 - IMPRESSAO: cabecalho dos dias passa a exibir numero + dia da semana (DO/SE/TE/QA/QI/SX/SA).
# - Pre-visualizacao oficial, impressao/PDF e pre-visualizacao combinada usam o mesmo cabecalho em duas linhas.
# - Mantida a largura calculada das colunas de dias e a compatibilidade com meses de 28, 29, 30 e 31 dias.
# - O numero do dia passa a usar dois digitos (01..31), alinhado a grade da tela.
# V1.0.14.78 - INTERFACE: densidade da grade corrigida + largura configuravel das colunas de dias.
# - Densidade agora altera imediatamente TODAS as linhas ja carregadas, inclusive os cabecalhos de bloco da Escala.
# - Nova opcao Configuracoes > Geral / Interface > Largura das colunas de datas: Ajustar a tela, Compacta ou Padrao.
# - Em Ajustar a tela, D01..D31 sao recalculadas para tentar exibir o mes inteiro sem rolagem horizontal, preservando as colunas fixas.
# - Esta opcao afeta somente a tela; nao altera a pre-visualizacao nem a impressao.
# V1.0.14.77 - CONSOLIDACAO apos auditoria externa da V76 (todos os pontos conferidos contra o codigo antes de aplicar).
# - CORRIGIDO: Remove-SiglaSelecionada tinha um ROLLBACK vestigial no catch (Db-Exec abre e fecha uma conexao NOVA a
#   cada chamada; se a transacao de exclusao falhasse, a conexao ja fechava sozinha - a SQLite ja desfaz a transacao
#   ao fechar - e o ROLLBACK seguinte, numa conexao SEM transacao ativa, podia falhar e mascarar o erro real da
#   exclusao. Mesma classe de bug ja corrigida em 10 pontos na V1.0.14.28; este ponto foi adicionado depois e ficou
#   de fora daquela limpeza. Removido, sem substituir por outro rollback (desnecessario pelo motivo acima).
# - REDE DE SEGURANCA da coluna Nomes (JS, V1.0.14.73): se um nome nao couber MESMO depois de abreviado ao maximo
#   (nomes com muitas palavras + fonte grande/larga, ex.: Verdana 10pt), a pagina agora reduz aos poucos so a fonte
#   DAQUELA celula (nunca abaixo de 70% do tamanho configurado), como ultimo recurso, para nunca cortar o nome.
# - Tooltip do tamanho da fonte da grade corrigido: nao fala mais em coluna de dia fixa de 5,5mm (o calculo e
#   dinamico desde a V1.0.14.45, o texto do aviso tinha ficado desatualizado).
# - Migracao unica (silenciosa): remove a chave de configuracao morta impressao_abreviar_nomes_max_caracteres
#   (usada so na V1.0.14.72-V1.0.14.73; desde a V1.0.14.74 a abreviacao e por largura real, nao por caracteres).
# - LEIA-ME.txt/VERSAO.txt: historico V1.0.14.70-76 consolidado (antes pulava direto para o texto antigo da V69).
# - Nenhuma regra de escala ou impressao foi alterada.
# V1.0.14.76 - CORRIGE 2a FALHA introduzida na V1.0.14.74 (agora ao GERAR A PREVIA, nao mais na abertura):
#   'A variavel $script:HelveticaWidthTable nao pode ser recuperada porque ainda nao foi definida.'
# - Causa: com Set-StrictMode -Version 2.0 (ja usado no script todo), uma variavel $script:xxx PRECISA ser
#   atribuida no CORPO PRINCIPAL do script (nao so dentro de uma funcao) antes que qualquer funcao possa
#   testar '$null -eq $script:xxx' pela primeira vez - o mesmo padrao ja usado em $script:LastUndo e
#   $script:AdvancedEscalaControls. $script:HelveticaWidthTable so era atribuida DENTRO de Get-TextWidthMm,
#   na primeira chamada, o que quebra sob StrictMode.
# - Corrigido: $script:HelveticaWidthTable=$null adicionado ao corpo principal do script, junto dos demais
#   caches de mesmo padrao. Nenhuma outra mudanca.
# V1.0.14.75 - CORRIGE ERRO DE ABERTURA introduzido na V1.0.14.74: a tabela de larguras de caractere
#   (Get-TextWidthMm) usava uma hashtable @{} do PowerShell com letras maiusculas E minusculas juntas
#   ('A' e 'a', 'B' e 'b'...). O @{} do PowerShell compara texto SEM diferenciar maiuscula de minuscula,
#   entao ele via 'A' e 'a' como a MESMA chave repetida e recusava o script inteiro ja na abertura, com
#   'Nao sao permitidas chaves duplicadas nos literais de hash' - exatamente o erro que apareceu.
# - Corrigido usando Dictionary[string,double] (sensivel a maiusculas de verdade) no lugar do @{}.
# - Varredura em TODO o arquivo atras do mesmo padrao (chaves de texto que colidem por maiusc/minusc
#   dentro do mesmo literal @{}): nenhum outro caso encontrado.
# - Nenhuma regra de escala, impressao ou banco foi alterada; a logica de abreviacao de nomes da V74
#   (largura real por fonte/familia, tela=impressao) continua a mesma, so a forma de guardar a tabela mudou.
# V1.0.14.74 - CAUSA RAIZ do nome cortado na impressao (V72/V73): a tela usava .sheet { width:100%; max-width:1500px }
#   (mais larga que a folha real), entao a coluna Nomes ficava PROPORCIONALMENTE mais larga na TELA do que na folha
#   impressa de verdade (@media print ja usava width:100% da area real). O nome cabia na pre-visualizacao (tela) mas
#   nao na impressao real (folha), e a garantia em JS da V73 media a largura ERRADA (a da tela) antes de imprimir.
# - .sheet agora usa a MESMA largura (mm) na tela e na impressao: a pre-visualizacao passa a ser fiel a folha real.
# - Abreviacao de nomes (V72) trocou de 'contar caracteres' para ESTIMAR A LARGURA REAL do texto (tabela de larguras
#   Helvetica/Arial por caractere, com fator de ajuste para Verdana/Tahoma/Segoe UI/Calibri/Times/Consolas) - reage
#   ao tamanho de fonte configurado e nao depende mais de um numero de caracteres 'no chute'. O campo numerico da
#   V72 foi removido (nao fazia mais sentido; o limite agora vem sozinho da largura real da coluna e da fonte).
# - A garantia em JS da V73 continua, agora medindo a largura correta (tela = impressao).
# - Nenhuma outra regra de escala, banco ou layout foi alterada.
# V1.0.14.73 - REDE DE SEGURANCA para a coluna Nomes: a abreviacao da V72 e por contagem de caracteres (aproximada);
#   letras largas (W, M, O) podem nao caber mesmo dentro do limite configurado, e o nome quebrava para uma 2a linha
#   na impressao real (a altura da linha e fixa), ficando cortado.
# - .scale .name agora usa white-space:nowrap + overflow:hidden (nunca mais quebra para a linha de baixo).
# - Nova checagem no proprio navegador, ANTES de imprimir: mede a largura de cada nome com a fonte/impressora reais
#   (nao uma estimativa) e, se ainda nao couber numa linha, abrevia mais um nome do meio por vez ate caber - segue a
#   MESMA regra da V72 (primeiro nome e ultimo sobrenome nunca sao tocados). Roda sempre, mesmo com a abreviacao
#   desligada em Configuracoes: e uma garantia contra corte visual, nao a preferencia estetica da V72.
# - Nenhuma outra regra de escala, banco ou layout foi alterada.
# V1.0.14.72 - NOVO: abreviar automaticamente nomes muito compridos na impressao (coluna Nomes da escala).
# - Nova funcao Get-NomeAbreviadoImpressao: quando o nome impresso passa do limite configurado, os nomes DO MEIO viram
#   inicial+ponto (ex.: 'Fabiane Ortiz de Araujo de Lima' -> 'Fabiane O. de A. de Lima'), um de cada vez, ate caber.
#   Primeiro nome e ultimo sobrenome NUNCA sao abreviados; particulas (de/da/do/dos/das/e) nunca viram inicial.
# - Configuravel em Configuracoes > Impressao (checkbox liga/desliga + limite de caracteres); afeta so a coluna Nomes
#   da grade impressa. Assinaturas continuam sempre com o nome completo, sem abreviacao.
# - Padrao: ligado, limite 30 caracteres (a coluna Nomes tem 55mm; nomes mais curtos que o limite nao mudam em nada).
# - Nenhuma outra regra de escala, banco ou layout foi alterada.
# V1.0.14.71 - COMPLETA A CORRECAO DA V70 E ENDURECE PONTOS DA V68.
# - ComboBox vinculado (BindingSource) pode expor DataRowView em SelectedValue durante o DataBinding. A V70 corrigiu so o caminho
#   de abertura; agora TODAS as leituras que tinham catch{} na V67 usam Get-ComboSelectedInt: dialogo de Ocorrencia (setor/sub/servidor/tipo/mes/ano),
#   Lotacao em Lote (tipo do lote e tipo individual), Escala Vaga (mes) e Assistente de fluxo.
# - Cleanup-OldPreviewFiles: previa antiga travada por outro programa nao impede mais a previa nova (falha registrada no log, por arquivo).
# - Test-DatabasePathIsNetwork: PSDrive e CIM sao checagens independentes e, se nenhuma puder rodar, assume REDE (conservador) e registra.
# - Versao unificada (titulo da janela, rotulo, exportacao de configuracoes e cabecalho).
# - Nenhuma regra de escala, impressao ou banco foi alterada.
# V1.0.14.69 - ROBUSTEZ DE INFRAESTRUTURA SOBRE A V68.
# - Write-Log protegido contra falha secundaria: log normal -> TEMP -> Trace .NET.
# - Limpeza de handlers, mutex e DLL SQLite centralizada em Invoke-SafeRuntimeCleanup.
# - Erros de limpeza sao registrados sem mascarar a excecao/encerramento original.
# V1.0.14.68 - REMOCAO DOS 172 catch{} VAZIOS (pedido do usuario; cada try{...}catch{} sem tratamento foi desembrulhado).
# - Os comandos passam a rodar SEM a protecao silenciosa: com Set-StrictMode 2.0 e $ErrorActionPreference=Stop, qualquer erro neles
#   agora interrompe a acao e chega ao tratador global (janela de erro + Logs\Sistema_Escala.log).
# - Lista completa dos pontos alterados: RELATORIO_CATCH_REMOVIDOS_V68.txt. Nenhuma outra regra foi alterada.
# - Versao anterior sem esta mudanca: V1.0.14.67 (rollback = voltar o Aplicativo_Escala.ps1 anterior).
# V1.0.14.67 - ROBUSTEZ (sem mudanca funcional), apos auditoria externa da V66.
# - Save-ConfiguracoesUI: no tratamento de erro, a escolha pendente do combo de perfil tambem e limpa e o combo reavaliado.
# - Legenda com siglas de ocorrencia: comparacao normalizada (UPPER/TRIM), NOT EXISTS no lugar de NOT IN e uma linha por sigla.
# - Nenhuma regra de escala, impressao, layout ou banco foi alterada.
# V1.0.14.66 - LIMPEZA GERAL apos auditoria da V65.
# - Status de Configuracoes: todas as mensagens usam Set-ConfigStatus (a barra recalcula o layout; nada fica cortado).
# - Perfil de impressao: escolha pendente no combo nao e mais sobrescrita ao mexer nos controles antes de APLICAR PERFIL.
# - Perfis Oficial/Compacto/Conferencia agora tratam as 3 familias de fonte da mesma forma (aplicam e exigem Arial).
# - Legenda impressa inclui siglas de tipos de ocorrencia realmente usadas na folha e ausentes da tabela siglas (ex.: SA, SAAT, ASJR).
# - Removido codigo morto: Show-AddServidorEscalaDialog, Get-EscalaVagasTable, Remove-BackupsAntigos.
# - Menu de siglas rapidas: parametro $args renomeado para $ev (nao reutiliza variavel automatica).
# - Nenhuma regra de escala, banco ou layout foi alterada.
# V1.0.14.65 - CONSOLIDACAO V64: perfil de impressao automatico + schema alinhado.
# - O combo Perfil identifica automaticamente Oficial / Compacto / Conferencia / Personalizado.
# - Alterar manualmente um controle de impressao atualiza o Perfil para o estado correspondente.
# - impressao_legenda_pares e impressao_legenda_posicao agora sao carregados corretamente do banco.
# - Dados/schema.sql alinhado ao banco: faixa_cor_fundo e faixa_cor_fonte em tipos_ocorrencia.
# - Nenhuma alteracao estrutural e feita no banco operacional existente.
# V1.0.14.64 - CORRECAO: caixa "Legenda" da tela Escala acompanha o padrao salvo em Configuracoes > Impressao.
# - Antes a caixa era lida so na abertura do sistema e SEMPRE forcava a legenda na previa/impressao: se voce ligasse a legenda
#   em Configuracoes e salvasse com o sistema aberto, a previa continuava SEM legenda ate reiniciar.
# - Agora, ao salvar/restaurar/importar configuracoes com valor diferente de "Mostrar legenda das siglas", a caixa acompanha.
# - Marcar/desmarcar a caixa continua valendo so para aquela previa (uso pontual), sem alterar o padrao salvo.
# V1.0.14.63 - AJUSTE FINO: layout da aba Impressao + comparacao numerica na confirmacao de configuracoes.
# - Quadro de ajuda do Layout avancado da legenda: 490x92 -> 490x125 (texto nao e mais cortado); GroupBox 540x245 -> 540x270.
# - Texto "Cuidado: aumentar demais estas margens" limitado a 600 px (nao invade mais o GroupBox da legenda).
# - Formato das assinaturas deslocado 15 px para baixo, respeitando a nova altura do GroupBox.
# - Confirmacao de salvamento e importacao comparam valores numericos como numeros (7 = 7.0 = 7,0): sem falsas alteracoes.
# - Nenhuma regra de impressao, legenda, perfil ou banco foi alterada.
# V1.0.14.62 - AJUSTE VISUAL FINAL: descricao dos Perfis de impressao sem corte.
# - GroupBox de Perfis ampliado verticalmente.
# - Area de descricao aumentada para acomodar todo o texto em DPI 100/125%.
# - Texto reorganizado em blocos curtos, sem linhas em branco excessivas.
# - Nenhuma regra de perfil, impressao, legenda ou banco foi alterada.
# V1.0.14.61 - AJUSTE VISUAL: Perfis de impressao e Layout avancado da legenda.
# - Caixa Perfis de impressao ampliada, com descricao em area propria e sem texto cortado.
# - Layout avancado da legenda ampliado e reorganizado para evitar sobreposicoes em DPI 100/125%.
# - Texto da ordem da legenda limitado a coluna esquerda para nao invadir o painel lateral.
# - Formato das assinaturas deslocado para baixo, respeitando a nova altura do painel da legenda.
# V1.0.14.60 - CONFIGURACOES: perfis de impressao + legenda avancada + auditoria antes de salvar.
# - Perfis Oficial / Compacto / Conferencia preenchem a aba Impressao sem salvar automaticamente.
# - Legenda pode usar 1, 2 ou 3 pares SIGLA/SIGNIFICADO e ficar a direita ou esquerda.
# - Antes de salvar configuracoes, o sistema mostra um resumo das alteracoes reais e pede confirmacao.
# - Mantidas V59/V58: linhas institucionais, busca, importacao/exportacao e toolbar responsiva.
# V1.0.14.59 - CONSOLIDACAO: Restaurar Padrao + cabecalho institucional vazio.
# - Restaurar Padrao global restaura tambem as 4 linhas institucionais oficiais.
# - Se as 4 linhas estiverem vazias, o bloco institucional nao e emitido no HTML.
# - Status da Central de Configuracoes recalcula a toolbar ao mudar de tamanho.
# - Preserva V58: busca global, exportar/importar configuracoes e toolbar responsiva.
# V1.0.14.58 - CENTRAL DE CONFIGURACOES: busca + exportar/importar perfil.
# - Busca global localiza opcoes pelo texto e abre a aba correspondente.
# - Exporta configuracoes portateis para JSON, sem banco/cadastros/escalas.
# - Importacao mostra resumo das alteracoes e exige backup valido antes de aplicar.
# - Caminho adicional de backup nao e transportado entre computadores.
# - Toolbar calcula a altura real e suporta 1, 2 ou mais linhas conforme a largura.
# V1.0.14.57 - CABECALHO INSTITUCIONAL: modelo limpo, sem flags de visibilidade.
# - Linha 1..4 guarda exatamente o texto informado pelo usuario.
# - Vazio no campo = string vazia no banco = vazio na impressao.
# - Texto padrao existe apenas no seed inicial e em Restaurar Padrao/Aba.
# - Removidas as flags *_visivel da V56 e qualquer dependencia delas.
# V1.0.14.56 - CABECALHO: linha institucional vazia passa a ter estado explicito.
# - Cada Linha 1..4 possui flag *_visivel; vazio salvo = visivel 0.
# - A pre-visualizacao respeita a flag mesmo que exista texto padrao/antigo no banco ou cache.
# - Migracao automatica detecta linhas ja vazias da V55 e grava visivel 0 na primeira abertura.
# - Mantidas as correcoes de Qtd, Escala Vaga, legenda e toolbar responsiva.
# V1.0.14.55 - IMPRESSAO: linhas institucionais realmente opcionais + toolbar responsiva.
# - Linha institucional vazia permanece vazia; nao volta ao texto padrao na pre-visualizacao.
# - Linhas vazias do cabecalho sao removidas do HTML, sem deixar espaco em branco artificial.
# - Barra superior de Configuracoes calcula a largura real e força 2 linhas quando necessario.
# - Em janela larga a barra volta automaticamente para 1 linha, recuperando espaco vertical.
# V1.0.14.54 - CONSOLIDACAO DAS CONFIGURACOES Qtd / Restaurar aba.
# - Destaque por grupo funciona tambem no modo Sequencial unico.
# - Restaurar aba Impressao volta ao padrao oficial completo, inclusive legenda e linhas institucionais.
# - Migra configuracao antiga de funcoes exatas para grupos quando possivel.
# - Se destaque estiver ativo e nenhum grupo marcado, ENF e marcado imediatamente na tela.
# - Barra superior de Configuracoes pode quebrar em duas linhas em telas menores, sem cortar botoes.
# V1.0.14.53 - CONFIGURACOES: destaque Qtd por GRUPO + Escala Vaga + previa em tempo real.
# - Grupos seguem a mesma regra da contagem: ENF, TE/AE, Outros ou Sequencial.
# - Escala Vaga pode herdar a mesma cor do grupo funcional.
# - Configuracoes > Qtd / Contagem ganhou mini-preview em tempo real.
# - Novo botao RESTAURAR ABA ATUAL restaura apenas a secao selecionada, sem afetar as demais.
# V1.0.14.52 - CORRECAO DEFINITIVA DO DESTAQUE Qtd + ajuste visual de Configuracoes.
# - Causa raiz: Build-EscalaSheetHtml reutilizava $cfg para as cores de siglas (FS/FF/PT),
#   sobrescrevendo o objeto de configuracao da impressao apos renderizar o primeiro servidor.
# - Agora cores de siglas usam $sigCfg e nunca alteram $cfg da impressao.
# - Texto explicativo de Qtd / Contagem foi reduzido para nao entrar atras do GroupBox.
# V1.0.14.51 - CORRECAO: destaque da coluna Qtd aplicado a TODAS as linhas da Funcao configurada.
# - A V50 aplicava estilo inline por chamada; a V51 usa classe CSS deterministica com !important.
# - A comparacao usa a Funcao exibida na impressao e tambem a Funcao bruta como compatibilidade.
# - Padrao continua ENF; TE, AE, TE/CTR e demais so mudam se forem configurados.
# V1.0.14.50 - IMPRESSAO: cor configuravel na celula Qtd conforme Funcao.
# - Padrao: Funcao ENF recebe fundo cinza #D9D9D9 e fonte preta.
# - TE, AE, TE/CTR e demais funcoes permanecem sem alteracao, salvo configuracao.
# - Configuracoes > Qtd / Contagem permite ativar, escolher funcoes exatas, fundo e fonte.
# - Recurso afeta somente PRE-VISUALIZAR / IMPRESSAO; a grade da aba Escala nao muda.
# V1.0.14.49 - ESCALA: busca inteligente por Servidor, CP, Funcao e Coren.
# - Somente numeros: busca EXATA em CP ou Coren.
# - Texto: busca PARCIAL em Servidor, Funcao, CP e Coren.
# - Comparacao textual ignora maiusculas/minusculas e acentos.
# - Mantem blocos e vagas visiveis para preservar o contexto da escala.
# V1.0.14.48 - SIGLAS: exclusao segura de sigla personalizada.
# - Novo botao EXCLUIR SIGLA na aba Siglas.
# - Siglas estruturais do sistema sao protegidas.
# - Sigla em uso por escala_dias ou tipos_ocorrencia nao pode ser excluida.
# - Exclusao permitida somente apos backup obrigatorio e dupla confirmacao.
# - A sigla removida tambem e retirada de menu_siglas_rapidas, se estiver configurada.
# V1.0.14.47 - IMPRESSAO: margem fisica de seguranca em todas as paginas.
# - Piso de 7 mm em todos os lados; vale tambem para pagina 2, 3 e seguintes.
# - @page protege a area fisica; o espacamento de tela nao interfere na impressao.
# - Cabecalho de colunas repete em paginas seguintes; linhas/blocos evitam corte no meio.
# V1.0.14.46 - ABA ESCALA: duplo clique no Qtd/Servidor/CP/Funcao/Coren de uma linha de SERVIDOR abre o
#   cadastro do servidor (Show-ServidorDialog, as mesmas regras de CP/Coren do cadastro oficial). A grade so e
#   recarregada se algum dado do servidor mudou. Duplo clique nas colunas de DIA (lancamento), no cabecalho do
#   BLOCO e na linha de VAGA continua exatamente como antes.
# V1.0.14.45 - CORRECOES DA AUDITORIA DA V1.0.14.44:
# - PREVIA (caminho longo): volta a limitar o nome do setor a 40 caracteres e, se o caminho passar de 240,
#   grava em %TEMP%\Sistema_Escala_DCE\Previsualizacao. Mantem o nome unico com data/hora/milissegundos.
#   (a V44 tinha perdido essa protecao; com o setor "...DISPONIBILIZADOS" o caminho chegava a 265 caracteres).
#   A limpeza das 60 previas mais recentes tambem cobre a pasta do %TEMP%.
# - PREVIA COMBINADA: cancelar/fechar a escolha das unidades nao gera mais o erro "SetorId nao encontrada"
#   (@($null) virava array de 1 item).
# - PRE-FLIGHT: alem de integridade/FK, confere se os 9 gatilhos de integridade existem; ausencia impede abrir.
#   Falhas isoladas de passos de compatibilidade agora aparecem na tela de avisos de abertura (antes so no log).
# - FAIXA CONTINUA: o minimo de dias passa a contar o periodo INTEIRO da ocorrencia tambem na tela (igual a
#   impressao); antes a tela contava so os dias dentro do mes.
# - RESTAURAR PADRAO: mes/ano padrao passam a ser o mes/ano ATUAL (antes fixos em 8/2026).
# - LIMPEZA: removido Invoke-CriticalStartupStep (sem uso desde a V40).
# V1.0.14.44 - IMPRESSAO: ocultacao explicita e robusta do titulo da legenda.
# - Campo vazio grava impressao_titulo_legenda_visivel=0.
# - A pre-visualizacao respeita a flag e tambem o estado vazio da caixa de texto.
# - A pasta externa pode manter nome antigo; a versao real continua sendo a exibida no topo.
# V1.0.14.43 - PRE-VISUALIZACAO: evita pagina antiga do Chrome por nome de arquivo fixo.
# - Cada previa usa nome unico com data/hora/milissegundos.
# - Adiciona meta no-cache/no-store no HTML.
# - Mantem a correcao V42: titulo da legenda pode ficar realmente vazio.
# V1.0.14.42 - IMPRESSAO: titulo da legenda de siglas pode ficar realmente vazio.
# - Campo vazio e preservado ao salvar/reabrir Configuracoes.
# - A pre-visualizacao/impressao omite apenas o titulo; a tabela da legenda continua quando 'Legenda' estiver marcada.
# V1.0.14.41 - CORES INDIVIDUAIS DAS FAIXAS CONTINUAS:
# - Configuracoes > Ocorrencias passa a permitir Cor do Fundo e Cor da Fonte para cada tipo
#   marcado como faixa continua (FERIAS, ATESTADO, LICENCA MATERNIDADE e qualquer outro).
# - As cores da faixa sao independentes das cores da Sigla e aparecem tanto na aba Escala
#   (faixa visual mesclada) quanto na pre-visualizacao/impressao.
# - Tipos existentes recebem o padrao #EEEEEE / #000000, preservando o visual neutro atual
#   ate o usuario escolher cores diferentes.
# V1.0.14.40 - CONSOLIDACAO DE INTEGRIDADE:
# - PRE-FLIGHT REAL: SQLite/version, journal local/rede, compatibilidade e migracao critica rodam
#   antes da criacao da MainForm e antes de qualquer leitura de configuracao da interface.
# - ESCALA_VAGAS: migracao critica valida as 4 FKs, integrity_check e foreign_key_check; falha impede
#   a abertura em vez de ser apenas registrada no log. O banco do pacote ja sai fisicamente migrado.
# - ORDEM DOS BLOCOS: Sync-ScaleBlockOrder continua com retorno capturado (sem contaminar o pipeline),
#   mas agora uma falha real e tratada; a previa e bloqueada, Load-Escala avisa e mover bloco aborta.
# - BACKUP ADICIONAL: temporarios .db.tmp antigos sao limpos com seguranca antes de nova copia.
# V1.0.14.39 - HOTFIX PRE-VISUALIZAR: desde a V1.0.14.36 Sync-ScaleBlockOrder passou a devolver $true/$false.
# Chamada solta dentro de Build-EscalaSheetHtml, esse valor entrava na saida da funcao, que virava um array
# (True + resultado) e quebrava com "A propriedade 'SyncError' nao foi encontrada neste objeto" (PRE-VISUALIZAR
# simples e combinado). As 3 chamadas agora descartam o retorno com [void](...).
# V1.0.14.38 - REVISAO PARA APONTAMENTOS DA AUDITORIA EXTERNA:
# - BACKUP ADICIONAL: a copia agora vai para arquivo temporario (.tmp) e so recebe o nome final depois
#   de conferida por SHA256; se o tempo limite estourar, a thread abandonada apaga o temporario e nao
#   renomeia nem apaga nada. Nunca fica arquivo parcial com nome de backup valido.
# - INICIALIZACAO SEGURA: falha ao aplicar journal_mode=DELETE em banco de REDE, ou SQLite < 3.24,
#   agora interrompe a abertura (com aviso e sem backup de saida) em vez de seguir so com aviso.
# - DESFAZER EXCLUSAO DE DIAS: linhas CALENDARIO_* (FS/FF/PF automaticos) nao sao mais regravadas como
#   MANUAL; elas se regeneram sozinhas.
# - BANCO: migracao unica reconstroi escala_vagas com as FKs que o schema.sql ja previa (ocorrencia_id
#   CASCADE e escala_servidor_id_origem SET NULL), alinhando banco migrado e instalacao nova.
# - PACOTE: Escala.db entregue em journal DELETE, sem arquivos -wal/-shm.
# V1.0.14.37 - SINCRONIZACAO / GATILHOS / DEFINITIVA / BACKUP (correcoes da auditoria da V1.0.14.36):
# ITEM 1 - SYNC 08H: a assinatura do calendario agora inclui as linhas MANUAL/OCORRENCIA dos servidores 08h.
#    Apagar um lancamento manual ou excluir/encurtar uma ocorrencia que cobria sabado/domingo/feriado
#    volta a regenerar FS/FF/PF automaticamente na mesma carga (antes so apos reabrir o sistema).
# ITEM 2 - GATILHOS: bloqueio de dia MANUAL x ocorrencia vale somente para tipos que GERAM escala
#    (gera_escala=1 e sigla). Remanejo de Periodo/Setor e Disponibilizado nao bloqueiam mais.
#    A validacao da tela usa a mesma regra (Test-TipoOcorrenciaGeraEscala) e o menu rapido de siglas
#    pre-verifica ocorrencias direto na tabela, evitando abortar o lote inteiro com mensagem tecnica.
# ITEM 3 - OCORRENCIA DEFINITIVA: servidor retirado por definitiva nao aparece mais como disponivel na
#    Lotacao nem em + SERVIDOR; novo gatilho trg_escala_servidores_reativacao_definitiva impede
#    reativar a linha por upsert enquanto a vaga vinculada estiver ativa (excluir/editar a ocorrencia
#    continua reativando de forma controlada).
# ITEM 4 - ABA OCORRENCIAS: lista tambem as ocorrencias que afetam servidores hoje lotados no Setor/Sub_Setor
#    filtrado (a ocorrencia acompanha o servidor). Mensagem de edicao indica o setor atual do servidor.
# ITEM 6 - BACKUP: retencao so apaga arquivos com o padrao exato de backup do sistema; backup de seguranca do
#    ZERAR HISTORICO usa nome proprio (Seguranca_PRE-ZERAR_*) com retencao separada; a copia na pasta
#    adicional roda com tempo limite (nao trava o fechamento) e e validada por SHA256.
#
# V1.0.14.36 - INTEGRIDADE / DESEMPENHO / BACKUP / OCORRENCIA DEFINITIVA:
# ocorrencias definitivas passam a ter vinculo explicito com a Escala Vaga e com a linha
# original do servidor, permitindo editar/excluir com reversao consistente. Novos gatilhos
# protegem sobreposicao de ocorrencias e conflito com lancamentos MANUAIS dentro da mesma
# transacao. Backup passa a preferir VACUUM INTO e sempre valida a copia com integrity_check.
# Configuracoes usam cache em memoria e salvamento em lote atomico. Load-Escala evita
# regravar sincronizacoes quando a origem/resultado nao mudou. Jornada 08h deixa de ser
# detectada por texto: cada Horario possui marcador explicito para FS/FF/PF automaticos.
# Tambem foram reforcadas transacoes multi-etapa, indice de COREN normalizado por TRIM,
# migracoes de startup, retencao de backup, log e validacao da versao do SQLite.
# Ocorrencias passam a acompanhar o servidor entre setores/meses: setor_id fica como setor
# de registro/origem, mas sincronizacao, sobreposicao e conflito manual sao por servidor.
# Incluidos trava de instancia por banco, tratadores globais de erro, carga exata da DLL
# SQLite, mutex aplicado antes da interface e pasta adicional opcional de backup validado.
#
# V1.0.14.35 - ROBUSTEZ / REDE / REGRAS CENTRALIZADAS: o modo de journal do
# SQLite agora e escolhido conforme o local real do banco (DELETE em compartilhamento de
# rede/UNC ou unidade mapeada; WAL somente em disco local). A copia do mes anterior nao
# traz servidor desativado. FF/PF/FS passam por uma unica regra de data usada pelo menu
# rapido, editor do dia e Calendario. A Lotacao em Lote valida TODAS as ocorrencias antes
# de qualquer gravacao e salva servidores + ocorrencias na mesma transacao. Corrigidos
# horario_id NULL ao remover servidor e o UPSERT do editor do dia para nunca sobrescrever
# origem OCORRENCIA. Falhas de leitura de configuracao deixam de ser silenciosas no log.
#
# V1.0.14.34 - INTEGRIDADE / OCORRENCIAS / SINCRONIZACAO: corrige o DESFAZER
# de remocao de servidor sem depender de last_insert_rowid() em outra conexao;
# unifica a validacao de sobreposicao e conflito com lancamentos MANUAIS entre
# ocorrencia individual e ocorrencia em lote; e faz as sincronizacoes automaticas
# retornarem sucesso/falha. A pre-visualizacao e bloqueada com aviso explicito se
# alguma sincronizacao falhar, evitando gerar/imprimir escala silenciosamente desatualizada.
#
# V1.0.14.33 - BLOCOS DE HORARIO / VISIBILIDADE: ampliada a janela Configurar
# Blocos de Horario e as duas grades, com melhor distribuicao horizontal. As colunas
# Bloco e Cabecalho agora quebram linha e aumentam a altura automaticamente para exibir
# o texto completo. A aba Horarios recebeu o mesmo tratamento visual para nomes/cabecalhos
# longos, sem alterar cadastro, ordem, impressao ou regras dos blocos.
#
# V1.0.14.32 - IMPRESSAO / LOTACAO EM LOTE: no cabecalho impresso, unidades que sao
# Sub_Setor passam a exibir somente o nome do Sub_Setor no campo SETOR, evitando textos
# longos do tipo Setor Principal / Sub_Setor. No menu do bloco de horario foi removida
# a opcao de adicionar servidor individual, mantendo apenas a inclusao em lote. Na tela
# de Lotacao em Lote foi incluido EDITAR SERVIDOR para editar individualmente o servidor
# da linha atual (tambem por duplo clique), reaproveitando o formulario oficial de cadastro.
# Mantidas as correcoes de WinSQLite.Query, impressao combinada e demais regras anteriores.
#
# V1.0.14.30 - INTERFACE CONFIGURAVEL: em Configuracoes > Geral / Interface o
# usuario pode escolher quais abas operacionais ficam visiveis. Escala e
# Configuracoes permanecem sempre visiveis. Readaptados fica oculto por padrao,
# pois Coren dispensado e Motivo continuam disponiveis em Servidores > Editar.
# Ocultar uma aba nao apaga cadastro, tabela ou regra de negocio: e apenas uma
# preferencia visual persistida no SQLite. Incluido RESTAURAR ABAS PADRAO.
# V1.0.14.29 - CORRECAO DE RAIZ: Db-Query (WinSQLite.Query) reescrito com
# sqlite3_prepare_v2/sqlite3_step em vez de sqlite3_exec com callback por linha.
# As colunas do resultado agora vem dos metadados da consulta logo apos o
# PREPARE, antes do primeiro STEP - e nao mais apenas dentro do callback, que so
# era chamado quando havia ao menos uma linha. Isso corrigia toda consulta com
# filtro que retornasse ZERO linhas: a tabela ficava sem nenhuma coluna e
# qualquer combo ligado a ela quebrava ao tentar definir o DisplayMember (erro
# "Nao e possivel ligar ao novo membro de exibicao" / newDisplayMember), como
# ocorreu no passo de inicializacao "Combos de Setor".
# V1.0.14.28 - CORRECAO: removido o ROLLBACK vestigial (chamada Db-Exec separada, sem efeito real) que ainda restava em 10 pontos do codigo apos a padronizacao da V1.0.14.27; agora todo bloco transacional confia apenas no fechamento da conexao para desfazer a transacao incompleta, com o erro sempre registrado em log e exibido ao usuario.
# V1.0.14.25 - CORRECAO: Cadastro em Lote agora bloqueia CP repetido dentro do proprio lote antes de gravar.
# Mantida a melhoria da V1.0.14.24: duas colunas opcionais Dispensa_Coren e Motivo_Dispensa.
# de cada linha colada: Dispensa_Coren (S/SIM para nao exigir Coren, mesmo sendo
# ENF/TE/AE) e Motivo_Dispensa (texto livre, ex.: Readaptacao funcional). Quando
# Dispensa_Coren=S, a linha nao e mais bloqueada por falta de Coren e o servidor ja
# entra cadastrado com coren_dispensado=1 (aparece marcado na aba Readaptados). Sem
# essas colunas, o comportamento do lote continua exatamente como antes.
#
# V1.0.14.23 - NOVA ABA "Readaptados (sem Coren)": para servidores ENF/TE/AE que
# nao precisam mais apresentar Coren (ex.: readaptacao funcional). Nova coluna
# coren_dispensado (+ motivo_dispensa_coren) na tabela servidores. A aba lista
# todos os ENF/TE/AE ativos com um botao para marcar/desmarcar a dispensa e
# registrar o motivo. Quando marcado, a exigencia de Coren obrigatorio (regra
# da V1.0.14.21.18) deixa de bloquear o cadastro/edicao desse servidor, mesmo
# com o campo Coren em branco. O cadastro individual (Servidores > Editar)
# tambem ganhou o mesmo checkbox e campo de motivo. Nao afeta o marcador ***
# (que continua sendo "Coren nao se aplica" para cargos fora de ENF/TE/AE).
#
# V1.0.14.21.20 - HOTFIX DE SEGURANCA: ZERAR HISTORICO agora executa todos os DELETEs
# em uma unica conexao/transacao SQLite e aborta se o backup previo falhar. Schema de COREN
# alinhado ao marcador *** e identificacao visual/versionamento unificados.
# V1.0.14.21.19 - Backup automatico ao fechar o sistema com rotina de retencao
# (mantem so os N backups mais recentes). Novo botao ZERAR HISTORICO DE ESCALAS
# em Configuracoes: apaga escalas/lancamentos/vagas/ocorrencias e preserva o
# cadastro (servidores, setores, horarios, siglas, assinaturas, feriados,
# configuracoes). Exige digitar ZERAR e faz backup automatico antes de apagar.
#
# V1.0.14.21.18 - Coren passa a ser exigido apenas dos cargos ENF, TE e AE (cadastro
# individual e em lote). Coren somente com zeros (ex.: 00000) e rejeitado como invalido.
# Novo marcador *** para "Coren nao se aplica" (cargos que nao exigem), isento da
# unicidade. Registros legados com Coren 00000 (cargo ASH) corrigidos para ***.
#
# V1.0.14.21.17 - LOTACAO EM LOTE: inclui botao direto para salvar ajustes individuais e incluir os servidores na escala
# entre a janela principal e a janela OCORRENCIA POR SERVIDOR, evitando erro de matriz nula.
# Mantem tipo e periodo individual por servidor sem alterar a estrutura do banco.
# na ocorrencia opcional em lote. O periodo geral continua como padrao para quem nao tiver
# ajuste individual. A logica de inclusao na escala, conflitos e demais rotinas foi preservada.
# Windows PowerShell 5.x / Windows 10 ou 11 (x86, x64 e ARM64 conforme o processo).
# Banco SQLite local em Dados\Escala.db. O carregador procura primeiro uma DLL
# portatil em Recursos\SQLite\<arquitetura>\sqlite3.dll; se nao existir, no
# Windows 10/11 cria uma copia de runtime da winsqlite3.dll do proprio Windows.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)

$script:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:DbPath = Join-Path $script:Root 'Dados\Escala.db'
$script:BackupDir = Join-Path $script:Root 'Backup'
$script:LogDir = Join-Path $script:Root 'Logs'
$script:PreviewDir = Join-Path $script:Root 'Relatorios\Previsualizacao'

function Get-PreviewTempDir {
    return (Join-Path $env:TEMP 'Sistema_Escala_DCE\Previsualizacao')
}

function New-UniquePreviewPath {
    # V1.0.14.45 - nome unico (data/hora/ms) para o navegador nunca reaproveitar pagina antiga, E caminho
    # sempre dentro do limite MAX_PATH (260) do Windows: setor limitado a 40 caracteres; se ainda passar de
    # 240, grava em %TEMP%\Sistema_Escala_DCE\Previsualizacao (o HTML e autonomo: logos em base64).
    param([string]$Nome,[string]$Sufixo,[int]$Ano,[int]$Mes)
    $seguro=([string]$Nome -replace '[\\/:*?"<>|\x00-\x1F]','_')
    $seguro=(($seguro -replace '\s+',' ').Trim()).TrimEnd('.',' ')
    if($seguro.Length -gt 40){$seguro=$seguro.Substring(0,40).TrimEnd('.',' ','_')}
    if([string]::IsNullOrWhiteSpace($seguro)){$seguro='Setor'}
    $stamp=(Get-Date).ToString('yyyyMMdd_HHmmss_fff')
    $arq=('Escala_{0}_{1}-{2:00}_{3}_{4}.html' -f $seguro,$Ano,$Mes,$Sufixo,$stamp)
    $dir=[string]$script:PreviewDir
    if(($dir.Length + 1 + $arq.Length) -gt 240){
        $dir=Get-PreviewTempDir
        Write-Log ('Caminho da pasta Relatorios muito longo; previa gravada em: ' + $dir)
    }
    if(-not (Test-Path -LiteralPath $dir)){New-Item -ItemType Directory -Path $dir -Force | Out-Null}
    return (Join-Path $dir $arq)
}

function Cleanup-OldPreviewFiles {
    # Mantem as 60 previas mais recentes de cada pasta de previa (Relatorios e %TEMP%) e remove so excedentes.
    foreach($dir in @([string]$script:PreviewDir,(Get-PreviewTempDir))){
        if(-not (Test-Path -LiteralPath $dir)){continue}
        $files=@(Get-ChildItem -LiteralPath $dir -Filter 'Escala_*.html' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending)
        if($files.Count -le 60){continue}
        foreach($f in @($files | Select-Object -Skip 60)){
            try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop }
            catch { Write-Log ('Previa antiga nao removida (em uso?): ' + $f.FullName + ' - ' + $_.Exception.Message) }
        }
    }
}

$script:CurrentScaleId = 0
$script:SiglaCache = @{}
$script:PreviewLogoCache = $null
$script:ConfigReadErrorsLogged = @{}
$script:ConfigCache = @{}
$script:ConfigCacheLoaded = $false
$script:ConfigBatchActive = $false
$script:ConfigBatch = @{}
$script:SyncSignatureOcc = @{}
$script:SyncSignatureCal = @{}
$script:SqliteNativeHandle = [IntPtr]::Zero
$script:InstanceMutex = $null
$script:ThreadExceptionHandler = $null
$script:UnhandledExceptionHandler = $null

# V1.0.14.21.9 - CORRECAO DEFINITIVA DE ENTREGA/IMPRESSAO DO COMBINADO: removida a regra CSS
# page-break-before: always que ainda era gravada no HTML entre Setores/Sub_Setores.
# Agora o Chrome/Edge mantem as unidades na mesma pagina enquanto houver espaco.
#
# V1.0.14.21.5 - Corrigida a abrangencia das assinaturas no PRE-VISUALIZAR
# COMBINADO. O rodape agora considera as assinaturas de cada Setor/Sub_Setor
# efetivamente selecionado, mais as assinaturas herdadas do Setor Principal e
# as assinaturas GERAIS. Assim, uma assinatura cadastrada especificamente em
# 'DIRETORIA / GERENCIA' aparece no rodape combinado sem precisar muda-la para
# a Diretoria. O cabecalho continua priorizando a assinatura da unidade exata.
#
# V1.0.14.21.4 - PRE-VISUALIZAR COMBINADO agora abre uma selecao das unidades do
# Setor Principal. O usuario pode marcar/desmarcar o proprio Setor Principal (sem
# Sub_Setor) e cada Sub_Setor ativo com escala propria. Itens com escala criada no
# mes vem marcados por padrao. Corrigido o bug em que o combinado ignorava a escala
# do Setor Principal e considerava somente os Sub_Setores. Nenhuma regra da escala
# individual, impressao, assinaturas ou largura das colunas foi alterada.
#
# V1.0.14.21.3 - Revisao preventiva das janelas de cadastro/edicao. Os formularios
# modais passam a reservar explicitamente a area cliente para que os botoes de
# acao nao sejam cortados pela barra de titulo/bordas em diferentes DPI do Windows.
# Corrigido em especial Horarios: SALVAR/CANCELAR estavam sobrepostos pela caixa
# de previa do cabecalho. Agora ficam em uma linha propria abaixo da previa.
# Nenhuma regra de escala, impressao, banco ou largura das colunas foi alterada.
#
# V1.0.14.21.2 - Cabecalho da escala configuravel por assinatura. Cada assinatura pode
# informar um titulo opcional para o cabecalho (ex.: GERENTE TECNICA, DIRETORA DE
# ENFERMAGEM). Assinatura especifica do setor tem prioridade sobre a do setor pai
# e sobre a assinatura GERAL. Campo vazio preserva o comportamento anterior.
# V1.0.14.21.1 - HOTFIX: removido definitivamente o fallback oculto do titulo
# ASSINATURAS. O padrao interno agora e vazio; bancos antigos que ainda tenham o
# valor automatico ASSINATURAS sao migrados uma unica vez para vazio.
# V1.0.14.21 - Corrigido o titulo do bloco de assinaturas: valor vazio agora e
# respeitado na configuracao, na pre-visualizacao e na impressao, sem restaurar
# automaticamente a palavra ASSINATURAS e sem reservar linha vazia no rodape.
# V1.0.14.20 - Escala Vaga passa a ser exibida logo abaixo do ultimo servidor
# do mesmo cargo dentro de cada bloco, tanto na aba Escala quanto nas
# pre-visualizacoes/impressoes. Vagas de cargo sem servidor no bloco permanecem
# ao final para nunca ocultar registros.
#
# V1.0.14.19 - camada de compatibilidade SQLite.
# A aplicacao deixa de depender de um nome fixo de DLL no codigo. Ela aceita uma
# sqlite3.dll portatil por arquitetura e, no Windows 10/11, consegue preparar uma
# copia de runtime a partir da winsqlite3.dll nativa do proprio Windows.
$script:SqliteLoadMode = ''
$script:SqliteArch = ([string]$env:PROCESSOR_ARCHITECTURE).ToUpperInvariant()
if ([string]::IsNullOrWhiteSpace($script:SqliteArch)) {
    if ([IntPtr]::Size -eq 8) { $script:SqliteArch = 'AMD64' } else { $script:SqliteArch = 'X86' }
}
switch ($script:SqliteArch) {
    'AMD64' { $script:SqliteFolder = 'x64' }
    'X86'   { $script:SqliteFolder = 'x86' }
    'ARM64' { $script:SqliteFolder = 'arm64' }
    default {
        if ([IntPtr]::Size -eq 8) { $script:SqliteFolder = 'x64' } else { $script:SqliteFolder = 'x86' }
    }
}

$script:SqliteDllName = 'sqlite3.dll'
$script:SqliteResolvedDll = $null
$portableSqliteDir = Join-Path $script:Root ('Recursos\SQLite\' + $script:SqliteFolder)
$portableSqliteDll = Join-Path $portableSqliteDir 'sqlite3.dll'
$sqliteReady = $false

if (Test-Path -LiteralPath $portableSqliteDll) {
    $env:PATH = $portableSqliteDir + ';' + $env:PATH
    $script:SqliteResolvedDll = $portableSqliteDll
    $script:SqliteLoadMode = 'PORTATIL-' + $script:SqliteFolder
    $sqliteReady = $true
} else {
    # Usa TEMP local para nao exigir permissao de gravacao na pasta do sistema,
    # inclusive quando o aplicativo estiver em compartilhamento de rede.
    try {
        $systemSqlite = Join-Path $env:WINDIR 'System32\winsqlite3.dll'
        if (Test-Path -LiteralPath $systemSqlite) {
            # Usa uma pasta versionada. Assim uma segunda instancia/processo nao
            # precisa sobrescrever uma DLL que ja esteja carregada por outro processo.
            $sysItem=Get-Item -LiteralPath $systemSqlite
            $verToken=[string]$sysItem.VersionInfo.FileVersion
            if([string]::IsNullOrWhiteSpace($verToken)){$verToken=('{0}_{1}' -f $sysItem.Length,$sysItem.LastWriteTimeUtc.Ticks)}
            $verToken=($verToken -replace '[^0-9A-Za-z._-]','_')
            $runtimeDir = Join-Path $env:TEMP ('Sistema_Escala_DCE\SQLite\' + $script:SqliteFolder + '\' + $verToken)
            if (-not (Test-Path -LiteralPath $runtimeDir)) {
                New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
            }
            $runtimeDll = Join-Path $runtimeDir 'sqlite3.dll'
            if(-not (Test-Path -LiteralPath $runtimeDll)){
                Copy-Item -LiteralPath $systemSqlite -Destination $runtimeDll -ErrorAction Stop
            }
            $env:PATH = $runtimeDir + ';' + $env:PATH
            $script:SqliteResolvedDll = $runtimeDll
            $script:SqliteLoadMode = 'RUNTIME-WINDOWS-' + $script:SqliteFolder
            $sqliteReady = $true
        }
    } catch {
        $sqliteReady = $false
    }
}

if (-not $sqliteReady) {
    # Ultimo fallback para Windows 10/11: carrega diretamente a DLL de sistema.
    $script:SqliteDllName = 'winsqlite3.dll'
    $script:SqliteResolvedDll = Join-Path $env:WINDIR 'System32\winsqlite3.dll'
    $script:SqliteLoadMode = 'WINDOWS-DIRETO'
}

# Precarrega exatamente o arquivo escolhido por caminho completo. O DllImport
# continua pelo nome-base por compatibilidade, mas o loader do Windows reutiliza
# o modulo ja carregado, evitando capturar uma sqlite3.dll alheia pelo PATH.
try {
    if(-not ('EscalaDCE.NativeLoader' -as [type])){
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace EscalaDCE {
    public static class NativeLoader {
        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
        public static extern IntPtr LoadLibraryW(string lpFileName);
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool FreeLibrary(IntPtr hModule);
    }
}
'@ -ErrorAction Stop
    }
    if(-not [string]::IsNullOrWhiteSpace([string]$script:SqliteResolvedDll) -and (Test-Path -LiteralPath $script:SqliteResolvedDll)){
        $script:SqliteNativeHandle=[EscalaDCE.NativeLoader]::LoadLibraryW($script:SqliteResolvedDll)
        if($script:SqliteNativeHandle -eq [IntPtr]::Zero){throw ('LoadLibraryW falhou. Win32=' + [Runtime.InteropServices.Marshal]::GetLastWin32Error())}
    }
}catch{
    [System.Windows.Forms.MessageBox]::Show("Nao foi possivel carregar a DLL SQLite selecionada:`r`n$script:SqliteResolvedDll`r`n`r`n$($_.Exception.Message)", 'Sistema de Escala', 'OK', 'Error') | Out-Null
    exit
}

if (-not (Test-Path $script:DbPath)) {
    [System.Windows.Forms.MessageBox]::Show("Banco de dados nao encontrado:`r`n$script:DbPath", 'Sistema de Escala', 'OK', 'Error') | Out-Null
    exit
}

$nativeCode = @'
using System;
using System.Data;
using System.Runtime.InteropServices;
using System.Text;

public static class WinSQLite
{
    private const string DLL = "__SQLITE_DLL__";
    private const int SQLITE_OK = 0;
    private const int SQLITE_ROW = 100;
    private const int SQLITE_DONE = 101;
    private const int SQLITE_NULL = 5;

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int ExecCallback(IntPtr arg, int count, IntPtr values, IntPtr names);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
    private static extern int sqlite3_open16([MarshalAs(UnmanagedType.LPWStr)] string filename, out IntPtr db);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_close(IntPtr db);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_busy_timeout(IntPtr db, int ms);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_exec(IntPtr db, IntPtr sql, ExecCallback callback, IntPtr arg, out IntPtr errmsg);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr sqlite3_errmsg(IntPtr db);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern void sqlite3_free(IntPtr p);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_prepare_v2(IntPtr db, IntPtr sql, int nBytes, out IntPtr stmt, out IntPtr pzTail);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_step(IntPtr stmt);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_finalize(IntPtr stmt);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_column_count(IntPtr stmt);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr sqlite3_column_name(IntPtr stmt, int iCol);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr sqlite3_column_text(IntPtr stmt, int iCol);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_column_type(IntPtr stmt, int iCol);

    private static IntPtr ToUtf8(string text)
    {
        byte[] bytes = Encoding.UTF8.GetBytes((text ?? "") + "\0");
        IntPtr p = Marshal.AllocHGlobal(bytes.Length);
        Marshal.Copy(bytes, 0, p, bytes.Length);
        return p;
    }

    private static string FromUtf8(IntPtr p)
    {
        if (p == IntPtr.Zero) return null;
        int len = 0;
        while (Marshal.ReadByte(p, len) != 0) len++;
        byte[] bytes = new byte[len];
        Marshal.Copy(p, bytes, 0, len);
        return Encoding.UTF8.GetString(bytes);
    }

    private static IntPtr Open(string file)
    {
        IntPtr db;
        int rc = sqlite3_open16(file, out db);
        if (rc != SQLITE_OK)
        {
            string msg = db == IntPtr.Zero ? "Falha ao abrir o banco SQLite." : FromUtf8(sqlite3_errmsg(db));
            if (db != IntPtr.Zero) sqlite3_close(db);
            throw new Exception(msg);
        }
        sqlite3_busy_timeout(db, 8000);
        return db;
    }

    public static void Execute(string file, string sql)
    {
        IntPtr db = IntPtr.Zero;
        IntPtr pSql = IntPtr.Zero;
        IntPtr err = IntPtr.Zero;
        try
        {
            db = Open(file);
            pSql = ToUtf8("PRAGMA foreign_keys=ON;" + sql);
            int rc = sqlite3_exec(db, pSql, null, IntPtr.Zero, out err);
            if (rc != SQLITE_OK)
            {
                string msg = err != IntPtr.Zero ? FromUtf8(err) : FromUtf8(sqlite3_errmsg(db));
                throw new Exception(msg);
            }
        }
        finally
        {
            if (err != IntPtr.Zero) sqlite3_free(err);
            if (pSql != IntPtr.Zero) Marshal.FreeHGlobal(pSql);
            if (db != IntPtr.Zero) sqlite3_close(db);
        }
    }

    public static DataTable Query(string file, string sql)
    {
        // V1.0.14.28 - Reescrito com sqlite3_prepare_v2/sqlite3_step em vez do
        // antigo sqlite3_exec com callback por linha. Antes, as colunas do
        // DataTable so eram criadas DENTRO do callback, que so e chamado quando
        // existe ao menos uma linha retornada. Uma consulta com filtro que hoje
        // devolve ZERO linhas (ex.: nenhum Setor ativo apos alguma alteracao de
        // cadastro) resultava numa tabela sem nenhuma coluna, e qualquer combo
        // ligado a ela (Set-ComboDataSource) quebrava ao tentar definir o
        // DisplayMember, com o erro "Nao e possivel ligar ao novo membro de
        // exibicao" (newDisplayMember). Agora as colunas vem direto dos metadados
        // da consulta logo apos o PREPARE, antes mesmo do primeiro STEP, entao a
        // tabela sempre tem as colunas certas mesmo com zero linhas.
        DataTable table = new DataTable();
        IntPtr db = IntPtr.Zero;
        IntPtr pPragma = IntPtr.Zero;
        IntPtr errPragma = IntPtr.Zero;
        IntPtr pSql = IntPtr.Zero;
        IntPtr stmt = IntPtr.Zero;
        IntPtr pzTail = IntPtr.Zero;
        try
        {
            db = Open(file);

            // PRAGMA continua sendo aplicado por sqlite3_exec simples (nao
            // produz linhas, so precisa rodar antes da consulta preparada).
            pPragma = ToUtf8("PRAGMA foreign_keys=ON;");
            int rcPragma = sqlite3_exec(db, pPragma, null, IntPtr.Zero, out errPragma);
            if (rcPragma != SQLITE_OK)
            {
                string msgPragma = errPragma != IntPtr.Zero ? FromUtf8(errPragma) : FromUtf8(sqlite3_errmsg(db));
                throw new Exception(msgPragma);
            }

            byte[] sqlBytes = Encoding.UTF8.GetBytes(sql ?? "");
            pSql = Marshal.AllocHGlobal(sqlBytes.Length + 1);
            Marshal.Copy(sqlBytes, 0, pSql, sqlBytes.Length);
            Marshal.WriteByte(pSql, sqlBytes.Length, 0);

            int rc = sqlite3_prepare_v2(db, pSql, -1, out stmt, out pzTail);
            if (rc != SQLITE_OK || stmt == IntPtr.Zero)
            {
                string msg = FromUtf8(sqlite3_errmsg(db));
                throw new Exception(msg);
            }

            // Query executa exatamente UM statement. Antes, qualquer SQL apos
            // o primeiro era ignorado silenciosamente por sqlite3_prepare_v2.
            // Isso mascara erros de manutencao; agora um segundo statement gera
            // uma excecao clara e deve ser enviado por Execute/Db-Exec.
            string tail = FromUtf8(pzTail);
            if (!String.IsNullOrWhiteSpace(tail))
            {
                string rest = tail.Trim().Trim(';').Trim();
                if (!String.IsNullOrWhiteSpace(rest))
                    throw new Exception("Db-Query aceita apenas um statement SQL por chamada.");
            }

            int colCount = sqlite3_column_count(stmt);
            for (int i = 0; i < colCount; i++)
            {
                string n = FromUtf8(sqlite3_column_name(stmt, i)) ?? ("C" + i.ToString());
                string original = n;
                int suffix = 2;
                while (table.Columns.Contains(n)) { n = original + "_" + suffix.ToString(); suffix++; }
                table.Columns.Add(n, typeof(string));
            }

            while (true)
            {
                rc = sqlite3_step(stmt);
                if (rc == SQLITE_ROW)
                {
                    DataRow row = table.NewRow();
                    for (int i = 0; i < colCount; i++)
                    {
                        if (sqlite3_column_type(stmt, i) == SQLITE_NULL) row[i] = DBNull.Value;
                        else row[i] = FromUtf8(sqlite3_column_text(stmt, i));
                    }
                    table.Rows.Add(row);
                }
                else if (rc == SQLITE_DONE)
                {
                    break;
                }
                else
                {
                    string msg = FromUtf8(sqlite3_errmsg(db));
                    throw new Exception(msg);
                }
            }
            return table;
        }
        finally
        {
            if (errPragma != IntPtr.Zero) sqlite3_free(errPragma);
            if (pPragma != IntPtr.Zero) Marshal.FreeHGlobal(pPragma);
            if (stmt != IntPtr.Zero) sqlite3_finalize(stmt);
            if (pSql != IntPtr.Zero) Marshal.FreeHGlobal(pSql);
            if (db != IntPtr.Zero) sqlite3_close(db);
        }
    }
}
'@

# Usa no DllImport o caminho COMPLETO da DLL que ja foi escolhida e
# precarregada. Isso fecha a ultima brecha de resolucao por nome (PATH/System32):
# o P/Invoke passa a apontar para o mesmo arquivo validado acima.
$dllForPInvoke=$(if(-not [string]::IsNullOrWhiteSpace([string]$script:SqliteResolvedDll) -and (Test-Path -LiteralPath $script:SqliteResolvedDll)){$script:SqliteResolvedDll}else{$script:SqliteDllName})
$dllForPInvokeCSharp=([string]$dllForPInvoke).Replace('\','\\').Replace('"','\"')
$nativeCode = $nativeCode.Replace('__SQLITE_DLL__', $dllForPInvokeCSharp)

try {
    Add-Type -TypeDefinition $nativeCode -ReferencedAssemblies @('System.dll','System.Data.dll','System.Xml.dll') -ErrorAction Stop
} catch {
    [System.Windows.Forms.MessageBox]::Show("Nao foi possivel iniciar o mecanismo SQLite compativel.`r`n`r`n$($_.Exception.Message)`r`n`r`nModo: $script:SqliteLoadMode / $script:SqliteFolder", 'Sistema de Escala', 'OK', 'Error') | Out-Null
    exit
}

function Write-Log {
    param([string]$Text)

    # O logger NUNCA deve derrubar o tratamento do erro original.
    # Se o log principal estiver indisponivel (permissao, arquivo bloqueado,
    # pasta removida etc.), registra em um arquivo de emergencia no TEMP.
    # Como ultimo recurso, envia a mensagem ao Trace do .NET.
    $line = ('{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $Text)
    try {
        if (-not (Test-Path -LiteralPath $script:LogDir)) {
            New-Item -ItemType Directory -Path $script:LogDir -Force -ErrorAction Stop | Out-Null
        }
        $logPath=Join-Path $script:LogDir 'Sistema_Escala.log'

        # Rotacao simples: 5 arquivos de ate aproximadamente 5 MB. Evita que um
        # log antigo cresca indefinidamente em instalacoes de longa duracao.
        if((Test-Path -LiteralPath $logPath) -and (Get-Item -LiteralPath $logPath -ErrorAction Stop).Length -ge 5MB){
            for($i=4;$i -ge 1;$i--){
                $src=($logPath+'.'+$i);$dst=($logPath+'.'+($i+1))
                if(Test-Path -LiteralPath $src){Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop}
            }
            Move-Item -LiteralPath $logPath -Destination ($logPath+'.1') -Force -ErrorAction Stop
        }
        Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8 -ErrorAction Stop
        return
    } catch {
        $logError=$_.Exception.Message
        try {
            $fallback=Join-Path ([System.IO.Path]::GetTempPath()) 'Sistema_Escala_DCE_LOG_EMERGENCIA.log'
            $fallbackLine=('{0}  [FALHA NO LOG PRINCIPAL: {1}]' -f $line,$logError)
            [System.IO.File]::AppendAllText($fallback,($fallbackLine+[Environment]::NewLine),[System.Text.Encoding]::UTF8)
            return
        } catch {
            try { [System.Diagnostics.Trace]::WriteLine(('{0}  [FALHA TOTAL DE LOG]' -f $line)) } catch { $null=$_.Exception }
        }
    }
}

function Invoke-SafeRuntimeCleanup {
    # Limpeza de infraestrutura nao deve mascarar o erro que originou o encerramento.
    if($null -ne $script:ThreadExceptionHandler){
        try { [System.Windows.Forms.Application]::remove_ThreadException($script:ThreadExceptionHandler) }
        catch { Write-Log ('Falha ao remover tratador ThreadException: '+$_.Exception.Message) }
        $script:ThreadExceptionHandler=$null
    }
    if($null -ne $script:UnhandledExceptionHandler){
        try { [AppDomain]::CurrentDomain.remove_UnhandledException($script:UnhandledExceptionHandler) }
        catch { Write-Log ('Falha ao remover tratador UnhandledException: '+$_.Exception.Message) }
        $script:UnhandledExceptionHandler=$null
    }
    if($null -ne $script:InstanceMutex){
        try { $script:InstanceMutex.ReleaseMutex() }
        catch { Write-Log ('Falha ao liberar mutex da instancia: '+$_.Exception.Message) }
        try { $script:InstanceMutex.Dispose() }
        catch { Write-Log ('Falha ao descartar mutex da instancia: '+$_.Exception.Message) }
        $script:InstanceMutex=$null
    }
    if($script:SqliteNativeHandle -ne [IntPtr]::Zero){
        try { [void][EscalaDCE.NativeLoader]::FreeLibrary($script:SqliteNativeHandle) }
        catch { Write-Log ('Falha ao liberar biblioteca SQLite nativa: '+$_.Exception.Message) }
        $script:SqliteNativeHandle=[IntPtr]::Zero
    }
}

function Initialize-SingleInstanceGuard {
    try{
        $full=[System.IO.Path]::GetFullPath($script:DbPath).ToUpperInvariant()
        $sha=[System.Security.Cryptography.SHA256]::Create()
        try{$hash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($full)))).Replace('-','').Substring(0,24)}finally{$sha.Dispose()}
        $name='Local\SistemaEscalaDCE_'+$hash
        $created=$false
        $script:InstanceMutex=[System.Threading.Mutex]::new($true,$name,[ref]$created)
        if(-not $created){
            $script:InstanceMutex.Dispose()
            $script:InstanceMutex=$null
            [System.Windows.Forms.MessageBox]::Show('Este mesmo banco da Escala ja esta aberto em outra instancia neste computador. Feche a outra janela antes de abrir novamente.', 'Sistema de Escala', 'OK', 'Information') | Out-Null
            return $false
        }
        return $true
    }catch{
        Write-Log ('Nao foi possivel ativar a trava de instancia unica: '+$_.Exception.Message)
        return $true
    }
}

function Initialize-GlobalExceptionHandlers {
    try{
        $script:ThreadExceptionHandler=[System.Threading.ThreadExceptionEventHandler]{
            param($sender,$e)
            Write-Log ('ERRO NAO TRATADO (WinForms): '+$e.Exception.ToString())
            [System.Windows.Forms.MessageBox]::Show(('Ocorreu um erro inesperado na interface. O detalhe foi gravado em Logs\Sistema_Escala.log.'+"`r`n`r`n"+$e.Exception.Message),'Sistema de Escala','OK','Error')|Out-Null
        }
        [System.Windows.Forms.Application]::add_ThreadException($script:ThreadExceptionHandler)
        $script:UnhandledExceptionHandler=[System.UnhandledExceptionEventHandler]{
            param($sender,$e)
            Write-Log ('ERRO NAO TRATADO (AppDomain): '+[string]$e.ExceptionObject)
        }
        [AppDomain]::CurrentDomain.add_UnhandledException($script:UnhandledExceptionHandler)
    }catch{Write-Log ('Falha ao instalar tratadores globais de excecao: '+$_.Exception.Message)}
}

function Assert-SqliteVersion {
    $txt=[string](Db-Scalar 'SELECT sqlite_version();')
    if([string]::IsNullOrWhiteSpace($txt)){throw 'Nao foi possivel identificar a versao do SQLite.'}
    $ver=$null
    try{$ver=[version]$txt}catch{throw ('Versao SQLite invalida retornada pela DLL: '+$txt)}
    $min=[version]'3.24.0'
    Write-Log ('SQLite carregado: versao='+$txt+'; modo='+$script:SqliteLoadMode+'; arquivo='+[string]$script:SqliteResolvedDll)
    if($ver -lt $min){throw ('SQLite '+$txt+' e antigo demais. Esta versao do sistema exige SQLite 3.24.0 ou superior (UPSERT). Use uma sqlite3.dll portatil atual em Recursos\SQLite\'+$script:SqliteFolder+'.')}
    return $txt
}

# A trava entra ANTES de qualquer tela/carga de dados. Assim uma segunda
# instancia do mesmo banco nao chega a construir a interface nem executar
# consultas de inicializacao em paralelo com a primeira.
if(-not (Initialize-SingleInstanceGuard)){exit}
Initialize-GlobalExceptionHandlers

Write-Log ("Inicializacao: SQLite={0}; Arquitetura={1}; Processo={2} bits" -f $script:SqliteLoadMode,$script:SqliteFolder,([IntPtr]::Size * 8))

function Db-Query {
    param([string]$Sql)
    $t = [WinSQLite]::Query($script:DbPath, $Sql)
    Write-Output -NoEnumerate $t
}

function Db-Exec {
    param([string]$Sql)
    [WinSQLite]::Execute($script:DbPath, $Sql)
}

function Test-DatabasePathIsNetwork {
    # V1.0.14.35 - WAL nao deve ser usado quando o MESMO arquivo SQLite esta em
    # compartilhamento de rede. Detecta UNC e tambem unidade de rede mapeada.
    # V1.0.14.71 - Get-PSDrive e CIM sao checagens INDEPENDENTES (a falha de uma nao impede a outra).
    # Se nenhuma delas puder rodar, assume REDE (journal conservador) e registra no log.
    param([string]$Path=$script:DbPath)
    try { $full=[System.IO.Path]::GetFullPath($Path) }
    catch { Write-Log ('Caminho do banco invalido para classificacao local/rede: ' + $_.Exception.Message); return $true }
    if($full.StartsWith('\\')){return $true}
    $driveRoot=[System.IO.Path]::GetPathRoot($full)
    if($driveRoot -match '^([A-Za-z]):\\$'){
        $driveName=$matches[1]
        $psdOk=$false;$cimOk=$false
        try {
            $psd=Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction Stop
            $psdOk=$true
            if($null -ne $psd -and -not [string]::IsNullOrWhiteSpace([string]$psd.DisplayRoot) -and ([string]$psd.DisplayRoot).StartsWith('\\')){return $true}
        } catch { Write-Log ('Deteccao de unidade de rede (Get-PSDrive) falhou: ' + $_.Exception.Message) }
        try {
            $ld=Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}:'" -f $driveName) -ErrorAction Stop
            $cimOk=$true
            if($null -ne $ld -and [int]$ld.DriveType -eq 4){return $true}
        } catch { Write-Log ('Deteccao de unidade de rede (CIM) falhou: ' + $_.Exception.Message) }
        if((-not $psdOk) -and (-not $cimOk)){
            Write-Log 'Nao foi possivel classificar o caminho do banco como local/rede; assumindo REDE (journal conservador).'
            return $true
        }
    }
    return $false
}

function Initialize-DatabaseJournalMode {
    # journal_mode e persistente no arquivo. synchronous, ao contrario, e por
    # conexao; por isso nao e configurado aqui numa conexao descartavel.
    $emRede=[bool](Test-DatabasePathIsNetwork $script:DbPath)
    $desejado=$(if($emRede){'DELETE'}else{'WAL'})
    $obtido=[string](Db-Scalar ("PRAGMA journal_mode={0};" -f $desejado))
    if([string]::IsNullOrWhiteSpace($obtido)){throw 'SQLite nao retornou o journal_mode aplicado.'}
    $obtido=$obtido.Trim().ToUpperInvariant()
    if($obtido -ne $desejado){
        # V1.0.14.38 - em REDE, WAL e inseguro: a falha e critica (outro computador pode estar com o
        # arquivo aberto). Em disco local mantem o comportamento anterior (registra e segue).
        if($emRede){throw ("Banco em pasta de REDE e o SQLite nao aplicou journal_mode=DELETE (obtido={0}). Feche o sistema nos outros computadores que usam este banco e abra novamente." -f $obtido)}
        Write-Log ("AVISO: journal_mode esperado={0}; obtido={1}." -f $desejado,$obtido)
    }
    Write-Log ("Banco: caminho={0}; localizacao={1}; journal_mode={2}" -f $script:DbPath,$(if($emRede){'REDE'}else{'LOCAL'}),$obtido)
    return $obtido
}

function Ensure-Column {
    param([string]$Table,[string]$Column,[string]$Definition)
    $t=Db-Query ("PRAGMA table_info({0});" -f $Table)
    $found=$false
    foreach($r in $t.Rows){if([string]$r['name'] -eq $Column){$found=$true;break}}
    if(-not $found){Db-Exec ("ALTER TABLE {0} ADD COLUMN {1} {2};" -f $Table,$Column,$Definition)}
}


function Test-EscalaVagasForeignKeysComplete {
    try{
        $fkl=Db-Query 'PRAGMA foreign_key_list(escala_vagas);'
        $temEscala=$false;$temHorario=$false;$temOc=$false;$temOrigem=$false
        foreach($fr in $fkl.Rows){
            $tab=([string]$fr['table']).Trim().ToLowerInvariant()
            $from=([string]$fr['from']).Trim().ToLowerInvariant()
            $del=([string]$fr['on_delete']).Trim().ToUpperInvariant()
            if($from -eq 'escala_id' -and $tab -eq 'escalas' -and $del -eq 'CASCADE'){$temEscala=$true}
            elseif($from -eq 'horario_id' -and $tab -eq 'horarios'){$temHorario=$true}
            elseif($from -eq 'ocorrencia_id' -and $tab -eq 'ocorrencias' -and $del -eq 'CASCADE'){$temOc=$true}
            elseif($from -eq 'escala_servidor_id_origem' -and $tab -eq 'escala_servidores' -and $del -eq 'SET NULL'){$temOrigem=$true}
        }
        return ($temEscala -and $temHorario -and $temOc -and $temOrigem)
    }catch{
        Write-Log ('Falha ao validar FKs de escala_vagas: '+$_.Exception.Message)
        return $false
    }
}

function Ensure-EscalaVagasForeignKeysCritical {
    $existe=[int](Db-Scalar "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='escala_vagas';")
    if($existe -eq 0){
        Db-Exec @"
CREATE TABLE escala_vagas (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 escala_id INTEGER NOT NULL,
 horario_id INTEGER NOT NULL,
 descricao TEXT NOT NULL,
 funcao TEXT NOT NULL,
 data_inicial TEXT NOT NULL,
 data_final TEXT NOT NULL,
 ordem INTEGER NOT NULL DEFAULT 0,
 ativo INTEGER NOT NULL DEFAULT 1,
 criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ocorrencia_id INTEGER,
 escala_servidor_id_origem INTEGER,
 FOREIGN KEY(escala_id) REFERENCES escalas(id) ON DELETE CASCADE,
 FOREIGN KEY(horario_id) REFERENCES horarios(id),
 FOREIGN KEY(ocorrencia_id) REFERENCES ocorrencias(id) ON DELETE CASCADE,
 FOREIGN KEY(escala_servidor_id_origem) REFERENCES escala_servidores(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_escala_vagas_mes ON escala_vagas(escala_id,horario_id,ordem);
CREATE INDEX IF NOT EXISTS idx_escala_vagas_sync ON escala_vagas(escala_id,ativo,horario_id,ordem);
CREATE UNIQUE INDEX IF NOT EXISTS idx_escala_vagas_ocorrencia ON escala_vagas(ocorrencia_id) WHERE ocorrencia_id IS NOT NULL;
"@
    }else{
        Ensure-Column 'escala_vagas' 'ocorrencia_id' 'INTEGER'
        Ensure-Column 'escala_vagas' 'escala_servidor_id_origem' 'INTEGER'
        $orfObrig=[int](Db-Scalar @"
SELECT
 (SELECT COUNT(*) FROM escala_vagas v LEFT JOIN escalas e ON e.id=v.escala_id WHERE e.id IS NULL)
 +
 (SELECT COUNT(*) FROM escala_vagas v LEFT JOIN horarios h ON h.id=v.horario_id WHERE h.id IS NULL);
"@)
        if($orfObrig -gt 0){
            throw ("escala_vagas possui {0} referencia(s) obrigatoria(s) orfa(s) em escala_id/horario_id. A migracao foi interrompida para nao descartar dados." -f $orfObrig)
        }
        if(-not (Test-EscalaVagasForeignKeysComplete)){
            Db-Exec @"
BEGIN IMMEDIATE;
DROP TRIGGER IF EXISTS trg_escala_servidores_reativacao_definitiva;
UPDATE escala_vagas SET ocorrencia_id=NULL
 WHERE ocorrencia_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ocorrencias o WHERE o.id=escala_vagas.ocorrencia_id);
UPDATE escala_vagas SET escala_servidor_id_origem=NULL
 WHERE escala_servidor_id_origem IS NOT NULL AND NOT EXISTS(SELECT 1 FROM escala_servidores es WHERE es.id=escala_vagas.escala_servidor_id_origem);
CREATE TABLE escala_vagas_novo (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 escala_id INTEGER NOT NULL,
 horario_id INTEGER NOT NULL,
 descricao TEXT NOT NULL,
 funcao TEXT NOT NULL,
 data_inicial TEXT NOT NULL,
 data_final TEXT NOT NULL,
 ordem INTEGER NOT NULL DEFAULT 0,
 ativo INTEGER NOT NULL DEFAULT 1,
 criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ocorrencia_id INTEGER,
 escala_servidor_id_origem INTEGER,
 FOREIGN KEY(escala_id) REFERENCES escalas(id) ON DELETE CASCADE,
 FOREIGN KEY(horario_id) REFERENCES horarios(id),
 FOREIGN KEY(ocorrencia_id) REFERENCES ocorrencias(id) ON DELETE CASCADE,
 FOREIGN KEY(escala_servidor_id_origem) REFERENCES escala_servidores(id) ON DELETE SET NULL
);
INSERT INTO escala_vagas_novo(id,escala_id,horario_id,descricao,funcao,data_inicial,data_final,ordem,ativo,criado_em,ocorrencia_id,escala_servidor_id_origem)
SELECT id,escala_id,horario_id,descricao,funcao,data_inicial,data_final,ordem,ativo,criado_em,ocorrencia_id,escala_servidor_id_origem FROM escala_vagas;
DROP TABLE escala_vagas;
ALTER TABLE escala_vagas_novo RENAME TO escala_vagas;
CREATE INDEX IF NOT EXISTS idx_escala_vagas_mes ON escala_vagas(escala_id,horario_id,ordem);
CREATE INDEX IF NOT EXISTS idx_escala_vagas_sync ON escala_vagas(escala_id,ativo,horario_id,ordem);
CREATE UNIQUE INDEX IF NOT EXISTS idx_escala_vagas_ocorrencia ON escala_vagas(ocorrencia_id) WHERE ocorrencia_id IS NOT NULL;
CREATE TRIGGER trg_escala_servidores_reativacao_definitiva
BEFORE UPDATE OF ativo ON escala_servidores
WHEN NEW.ativo=1 AND OLD.ativo=0 AND EXISTS(
    SELECT 1 FROM escala_vagas v
    WHERE v.escala_servidor_id_origem=OLD.id AND v.ocorrencia_id IS NOT NULL AND v.ativo=1
)
BEGIN
    SELECT RAISE(ABORT,'Servidor retirado por ocorrencia definitiva. Edite ou exclua a ocorrencia para reativa-lo.');
END;
COMMIT;
"@
            Write-Log 'Migracao critica: escala_vagas reconstruida com as 4 FKs do schema oficial.'
        }
    }
    if(-not (Test-EscalaVagasForeignKeysComplete)){throw 'A tabela escala_vagas nao ficou com as 4 FKs obrigatorias apos a migracao.'}
    $ic=[string](Db-Scalar 'PRAGMA integrity_check;')
    if($ic.Trim().ToLowerInvariant() -ne 'ok'){throw ('PRAGMA integrity_check falhou apos migracao de escala_vagas: '+$ic)}
    $fkc=Db-Query 'PRAGMA foreign_key_check;'
    if($fkc.Rows.Count -gt 0){throw ("PRAGMA foreign_key_check encontrou {0} inconsistencia(s) apos a migracao de escala_vagas." -f $fkc.Rows.Count)}
    Db-Exec "CREATE TABLE IF NOT EXISTS meta(chave TEXT PRIMARY KEY, valor TEXT); INSERT OR REPLACE INTO meta(chave,valor) VALUES('escala_vagas_fk_v1440','1'); INSERT OR REPLACE INTO meta(chave,valor) VALUES('escala_vagas_fk_v1438','1');"
    return $true
}

$script:CompatFailures = New-Object System.Collections.ArrayList

function Invoke-CompatStep {
    # V1.0.14.26 - Cada passo de compatibilidade roda isolado em seu proprio
    # try/catch. Antes, toda a funcao Apply-CompatibilityFixes ficava dentro
    # de um unico try/catch externo: se um passo no meio (ex. um ALTER TABLE)
    # falhasse, todos os passos seguintes - inclusive a recriacao do gatilho
    # trg_escala_servidores_unico_mes - deixavam de rodar naquela sessao, sem
    # aviso claro (so um item generico na tela de erros de inicializacao).
    # Isolando passo a passo, uma falha pontual fica registrada no log e nao
    # cancela os demais passos independentes.
    param([string]$Nome,[scriptblock]$Acao)
    try {
        & $Acao
    } catch {
        Write-Log ("Falha no passo de compatibilidade '{0}': {1}" -f $Nome,$_.Exception.Message)
        [void]$script:CompatFailures.Add(("Compatibilidade do banco - {0}: {1}" -f $Nome,$_.Exception.Message))
    }
}

function Get-MissingIntegrityTriggers {
    # V1.0.14.45 - os 9 gatilhos que protegem a integridade da escala. Se algum passo de compatibilidade
    # falhar em silencio, o sistema nao pode abrir sem eles.
    $esperados=@('trg_escala_servidores_unico_mes','trg_escala_servidores_unico_mes_update','trg_ocorrencias_sobreposicao_insert','trg_ocorrencias_sobreposicao_update','trg_ocorrencias_manual_insert','trg_ocorrencias_manual_update','trg_escala_dias_manual_contra_ocorrencia_insert','trg_escala_dias_manual_contra_ocorrencia_update','trg_escala_servidores_reativacao_definitiva')
    $tb=Db-Query "SELECT name FROM sqlite_master WHERE type='trigger';"
    $existentes=@{}
    foreach($r in $tb.Rows){$existentes[[string]$r['name']]=$true}
    return @($esperados | Where-Object { -not $existentes.ContainsKey($_) })
}

function Apply-CompatibilityFixes {
    Invoke-CompatStep 'Tabela de controle de migracoes' {
        Db-Exec "CREATE TABLE IF NOT EXISTS meta (chave TEXT PRIMARY KEY, valor TEXT);"
    }

    Invoke-CompatStep 'Cores padrao de siglas' {
        # V1.0.14.36 - aplica o padrao oficial uma unica vez. Antes, o startup
        # sobrescrevia toda personalizacao de FF/FS/PF/PT em cada abertura.
        $fixCor=Db-Scalar "SELECT valor FROM meta WHERE chave='cores_siglas_padrao_v1436';"
        if([string]$fixCor -ne '1'){
            Db-Exec "BEGIN IMMEDIATE; UPDATE siglas SET cor_fundo='#F2F2F2', cor_fonte='#000000' WHERE sigla IN ('FF','FS','PF','PT'); INSERT OR REPLACE INTO meta(chave,valor) VALUES('cores_siglas_padrao_v1436','1'); COMMIT;"
        }
    }

    Invoke-CompatStep 'Ordem dos blocos de horario (coluna e tabela)' {
        # Compatibilidade com bancos das versoes anteriores: cria a ordem dos blocos de horario.
        $cols = Db-Query "PRAGMA table_info(horarios);"
        $temOrdem = $false
        foreach($c in $cols.Rows){ if([string]$c['name'] -eq 'ordem'){ $temOrdem = $true; break } }
        if(-not $temOrdem){
            Db-Exec "ALTER TABLE horarios ADD COLUMN ordem INTEGER NOT NULL DEFAULT 0;"
        }
        Db-Exec "UPDATE horarios SET ordem=id WHERE COALESCE(ordem,0)=0;"

        # V1.0.14.0 - ordem dos blocos pode ser diferente em cada escala mensal.
        # Mantem horarios.ordem apenas como ordem padrao/global do cadastro.
        Db-Exec @"
CREATE TABLE IF NOT EXISTS escala_blocos_ordem(
 escala_id INTEGER NOT NULL,
 horario_id INTEGER NOT NULL,
 ordem INTEGER NOT NULL DEFAULT 0,
 PRIMARY KEY(escala_id,horario_id),
 FOREIGN KEY(escala_id) REFERENCES escalas(id) ON DELETE CASCADE,
 FOREIGN KEY(horario_id) REFERENCES horarios(id)
);
"@
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_escala_blocos_ordem ON escala_blocos_ordem(escala_id,ordem,horario_id);"
    }

    Invoke-CompatStep 'Dispensa de Coren e estrutura Setor/Sub_Setor' {
        # V1.0.14.23 - dispensa de Coren por servidor (ex.: readaptacao funcional),
        # independente do cargo exigir Coren pela regra da V1.0.14.21.18.
        Ensure-Column 'servidores' 'coren_dispensado' 'INTEGER NOT NULL DEFAULT 0'
        Ensure-Column 'servidores' 'motivo_dispensa_coren' 'TEXT'

        # V1.0.13.4 - mesma estrutura Setor Principal -> Sub_Setor usada pelo Gerenciamento Geral.
        Ensure-Column 'setores' 'tipo_setor' "TEXT NOT NULL DEFAULT 'ASSISTENCIAL'"
        Ensure-Column 'setores' 'especial' 'INTEGER NOT NULL DEFAULT 0'
        Ensure-Column 'setores' 'setor_pai_id' 'INTEGER'
        Ensure-Column 'setores' 'sub_setor_origem_id' 'INTEGER'
        Ensure-Column 'setores' 'unidade_escala' 'INTEGER NOT NULL DEFAULT 0'
        Db-Exec @"
CREATE TABLE IF NOT EXISTS sub_setores(
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 setor_id INTEGER NOT NULL,
 nome TEXT NOT NULL,
 possui_escala INTEGER NOT NULL DEFAULT 1,
 ativo INTEGER NOT NULL DEFAULT 1,
 setor_escala_id INTEGER,
 UNIQUE(setor_id,nome),
 FOREIGN KEY(setor_id) REFERENCES setores(id)
);
"@
        $ssCols=Db-Query 'PRAGMA table_info(sub_setores);'
        $temSetorEscala=$false
        foreach($c in $ssCols.Rows){if([string]$c['name'] -eq 'setor_escala_id'){$temSetorEscala=$true;break}}
        if(-not $temSetorEscala){Db-Exec 'ALTER TABLE sub_setores ADD COLUMN setor_escala_id INTEGER;'}
        Ensure-Column 'sub_setores' 'leitos' 'INTEGER NOT NULL DEFAULT 0'
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_sub_setores_principal ON sub_setores(setor_id,ativo);"
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_setor_unidade_escala ON setores(unidade_escala,setor_pai_id,sub_setor_origem_id);"
    }

    Invoke-CompatStep 'Indice unico de Coren' {
        # V1.0.14.36 - a unicidade passa a usar TRIM(coren), igual as validacoes
        # da interface. Assim '12345' e ' 12345 ' nao podem coexistir.
        $corenDup = Db-Query "SELECT TRIM(coren) AS coren, COUNT(*) AS qtd FROM servidores WHERE coren IS NOT NULL AND TRIM(coren)<>'' AND TRIM(coren)<>'***' GROUP BY TRIM(coren) HAVING COUNT(*)>1;"
        if ($corenDup.Rows.Count -eq 0) {
            Db-Exec "BEGIN IMMEDIATE; DROP INDEX IF EXISTS idx_servidores_coren_unico; CREATE UNIQUE INDEX idx_servidores_coren_unico ON servidores(TRIM(coren)) WHERE coren IS NOT NULL AND TRIM(coren)<>'' AND TRIM(coren)<>'***'; COMMIT;"
        } else {
            $lista = ($corenDup.Rows | ForEach-Object { [string]$_['coren'] }) -join ', '
            Write-Log ("Coren duplicado encontrado, indice unico normalizado NAO criado ate corrigir: " + $lista)
        }
    }

    Invoke-CompatStep 'Calendario: diferenciar Feriado de Ponto Facultativo' {
        $fcols = Db-Query "PRAGMA table_info(feriados);"
        $temTipoFeriado = $false
        foreach($c in $fcols.Rows){ if([string]$c['name'] -eq 'tipo'){ $temTipoFeriado = $true; break } }
        if(-not $temTipoFeriado){
            Db-Exec "ALTER TABLE feriados ADD COLUMN tipo TEXT NOT NULL DEFAULT 'FERIADO';"
        }
        Db-Exec "UPDATE feriados SET tipo='FERIADO' WHERE COALESCE(TRIM(tipo),'')='';"
    }

    Invoke-CompatStep 'Remover configuracao obsoleta impressao_data' {
        # A linha de data foi retirada do modelo oficial de impressao.
        Db-Exec "DELETE FROM configuracoes WHERE chave='impressao_data';"
    }

    Invoke-CompatStep 'Remover configuracao obsoleta impressao_abreviar_nomes_max_caracteres' {
        # V1.0.14.77 - Usada so nas V1.0.14.72/73 (abreviar nomes por CONTAGEM de caracteres).
        # Desde a V1.0.14.74 a abreviacao usa a largura real do texto (fonte/coluna); esta chave
        # ficou sem nenhum efeito no codigo, mas continuava gravada no banco.
        Db-Exec "DELETE FROM configuracoes WHERE chave='impressao_abreviar_nomes_max_caracteres';"
    }

    Invoke-CompatStep 'Configuracoes gerais (tabela e padroes)' {
        # Configuracoes gerais: mantidas no SQLite para que o usuario possa ajustar sem alterar codigo.
        Db-Exec "CREATE TABLE IF NOT EXISTS configuracoes (chave TEXT PRIMARY KEY, valor TEXT NOT NULL);"
        Db-Exec "INSERT OR IGNORE INTO configuracoes(chave,valor) VALUES
            ('qtd_modo','ENF_TEAE'),
            ('qtd_reiniciar_bloco','1'),
            ('impressao_qtd_destaque_ativo','1'),
            ('impressao_qtd_destaque_funcoes','ENF'),
            ('impressao_qtd_destaque_grupos','ENF'),
            ('impressao_qtd_destaque_vaga','1'),
            ('impressao_qtd_destaque_fundo','#D9D9D9'),
            ('impressao_qtd_destaque_fonte','#000000'),
            ('calendario_destacar_fds','1'),
            ('calendario_destacar_feriados','1'),
            ('impressao_legenda','1'),
            ('legenda_todas_siglas','1'),
            ('impressao_assinaturas','1'),
            ('impressao_destacar_fds','1'),
            ('impressao_destacar_feriados','1'),
            ('mascara_dn_paridade','1'),
            ('mascara_mv_fds_paridade','1'),
            ('mv_pt_automatico','1'),
            ('08h_auto_ff_pf','1'),
            ('08h_auto_fs','1'),
            ('menu_siglas_rapidas','FC,FF,PT,C1,C2,C3,FS,PF'),
            ('abrir_mes_atual','1'),
            ('mes_padrao','8'),
            ('ano_padrao','2026'),
            ('criar_mes_copiar_anterior','PERGUNTAR'),
            ('interface_densidade','NORMAL'),
            ('interface_largura_dias','AJUSTAR'),
            ('interface_estilo_escala','DASHBOARD'),
            ('atestado_faixa_dias','4'),
            ('texto_faixa_ferias','FÉRIAS'),
            ('texto_faixa_atestado','ATESTADO'),
            ('impressao_legenda_fonte_pt','6'),
            ('impressao_legenda_sigla_mm','7'),
            ('impressao_assinatura_fonte_pt','7'),
            ('impressao_assinatura_fonte_familia','Arial'),
            ('impressao_cabecalho_fonte_pt','7'),
            ('impressao_cabecalho_fonte_familia','Arial'),
            ('impressao_inst_linha1','GOVERNO DO ESTADO DE MATO GROSSO DO SUL'),
            ('impressao_inst_linha2','SECRETARIA DE ESTADO DE SAUDE'),
            ('impressao_inst_linha3','FUNDACAO SERVICOS DE SAUDE DE MS'),
            ('impressao_inst_linha4','HOSPITAL REGIONAL DE MATO GROSSO DO SUL'),
            ('impressao_titulo_assinaturas',''),
            ('impressao_titulo_legenda','LEGENDA DAS SIGLAS'),
            ('impressao_titulo_legenda_visivel','1'),
            ('impressao_texto_chefia_padrao','CHEFIA DO SETOR'),
            ('impressao_margem_pagina_mm','7'),
            ('impressao_padding_folha_mm','5'),
            ('impressao_espaco_entre_setores_mm','6'),
            ('impressao_assinatura_linhas_separadas','1'),
            ('impressao_legenda_ordenar_por','DESCRICAO'),
            ('impressao_legenda_pares','2'),
            ('impressao_legenda_posicao','DIREITA'),
            ('impressao_fonte_familia','Arial'),
            ('impressao_grade_fonte_pt','5.7'),
            ('impressao_abreviar_nomes','1'),
            ('ordem_cargos','ENF,TE,AE'),
            ('backup_automatico_saida','1'),
            ('backup_max_arquivos','15'),
            ('backup_diretorio_adicional',''),
            ('interface_tab_servidores','1'),
            ('interface_tab_readaptados','0'),
            ('interface_tab_ocorrencias','1'),
            ('interface_tab_setores','1'),
            ('interface_tab_horarios','1'),
            ('interface_tab_siglas','1');"
    }



    Invoke-CompatStep 'Migrar destaque Qtd antigo para grupos V54' {
        $fix=Db-Scalar "SELECT valor FROM configuracoes WHERE chave='fix_qtd_grupos_v1454' LIMIT 1;"
        if([string]$fix -ne '1'){
            $antigo=[string](Db-Scalar "SELECT valor FROM configuracoes WHERE chave='impressao_qtd_destaque_funcoes' LIMIT 1;")
            $gruposAtuais=[string](Db-Scalar "SELECT valor FROM configuracoes WHERE chave='impressao_qtd_destaque_grupos' LIMIT 1;")

            # So tenta migrar quando ainda existe uma lista antiga util.
            # Se a V53 ja foi salva e a lista antiga foi simplificada, mantem os grupos atuais.
            if(-not [string]::IsNullOrWhiteSpace($antigo)){
                $map=New-Object System.Collections.ArrayList
                foreach($tok in @($antigo -split '[,;]')){
                    $f=([string]$tok).Trim().ToUpperInvariant()
                    if(-not $f){continue}
                    $grp=Get-QtdGrupoByMode $f 'ENF_TEAE'
                    if($grp -and $grp -ne 'SEQ' -and $grp -notin @($map)){[void]$map.Add($grp)}
                }
                if($map.Count -gt 0){
                    $novo=(@($map) -join ',')
                    # Se grupos ainda estao no default ENF, permite que a lista antiga amplie a migracao.
                    if([string]::IsNullOrWhiteSpace($gruposAtuais) -or $gruposAtuais.Trim().ToUpperInvariant() -eq 'ENF'){
                        Db-Exec ("UPDATE configuracoes SET valor={0} WHERE chave='impressao_qtd_destaque_grupos';" -f (Sql-Q $novo))
                    }
                }
            }

            Db-Exec "INSERT INTO configuracoes(chave,valor) VALUES ('fix_qtd_grupos_v1454','1') ON CONFLICT(chave) DO UPDATE SET valor='1';"
            Clear-ConfigCache
        }
    }


    Invoke-CompatStep 'Limpar residuos das linhas institucionais V56' {
        # V57 usa somente impressao_inst_linha1..4 como fonte de verdade.
        # Estas chaves eram tecnicas da V56 e deixam de existir.
        Db-Exec "DELETE FROM configuracoes WHERE chave IN (
            'impressao_inst_linha1_visivel',
            'impressao_inst_linha2_visivel',
            'impressao_inst_linha3_visivel',
            'impressao_inst_linha4_visivel',
            'fix_inst_linhas_visiveis_v1456'
        );"
        Clear-ConfigCache
    }

    Invoke-CompatStep 'Estado explicito do titulo da legenda de siglas' {
        # V1.0.14.44 - separa o texto do titulo da decisao de exibi-lo.
        # Isso evita qualquer fallback/cache/default antigo recriar visualmente
        # "LEGENDA DAS SIGLAS" quando o usuario deixou o campo vazio.
        $tituloLegAtual=Db-Scalar "SELECT valor FROM configuracoes WHERE chave='impressao_titulo_legenda' LIMIT 1;"
        $mostrarTituloLeg=$(if($null -eq $tituloLegAtual -or [string]::IsNullOrWhiteSpace([string]$tituloLegAtual)){'0'}else{'1'})
        Db-Exec ("INSERT INTO configuracoes(chave,valor) VALUES ('impressao_titulo_legenda_visivel',{0}) ON CONFLICT(chave) DO NOTHING;" -f (Sql-Q $mostrarTituloLeg))
        # Se a chave ja existia em uma versao de teste anterior, sincroniza-a com
        # o estado REAL do texto salvo no momento da migracao.
        Db-Exec ("UPDATE configuracoes SET valor={0} WHERE chave='impressao_titulo_legenda_visivel';" -f (Sql-Q $mostrarTituloLeg))
        Clear-ConfigCache
    }


    Invoke-CompatStep 'Margem fisica minima de seguranca da impressao' {
        # V1.0.14.47 - 7 mm e o piso de seguranca para reduzir cortes fisicos
        # em impressoras quando cabecalhos/rodapes do navegador estao desligados.
        Db-Exec "INSERT INTO configuracoes(chave,valor) VALUES ('impressao_margem_pagina_mm','7') ON CONFLICT(chave) DO NOTHING;"
        Db-Exec "UPDATE configuracoes SET valor='7' WHERE chave='impressao_margem_pagina_mm' AND CAST(REPLACE(COALESCE(valor,'0'),',','.') AS REAL) < 7;"
        Clear-ConfigCache
    }

    Invoke-CompatStep 'Migracao do titulo de assinaturas legado' {
        # V1.0.14.21.1 - migracao unica do titulo legado. Versoes antigas criavam
        # ASSINATURAS automaticamente quando a chave ainda nao existia ou vinha do
        # padrao original. Nesta versao, o titulo e opcional de verdade.
        $fixTituloAss = Db-Scalar "SELECT valor FROM configuracoes WHERE chave='fix_titulo_assinaturas_v14211';"
        if($null -eq $fixTituloAss -or [string]$fixTituloAss -ne '1'){
            Db-Exec "UPDATE configuracoes SET valor='' WHERE chave='impressao_titulo_assinaturas' AND UPPER(TRIM(valor))='ASSINATURAS';"
            Db-Exec "INSERT INTO configuracoes(chave,valor) VALUES ('fix_titulo_assinaturas_v14211','1') ON CONFLICT(chave) DO UPDATE SET valor='1';"
        }
    }

    Invoke-CompatStep 'Tabela escala_vagas e indices de desempenho' {
        # V1.0.12: Escala Vaga passa a ser um registro proprio da escala mensal.
        Db-Exec "CREATE TABLE IF NOT EXISTS escala_vagas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            escala_id INTEGER NOT NULL,
            horario_id INTEGER NOT NULL,
            descricao TEXT NOT NULL,
            funcao TEXT NOT NULL,
            data_inicial TEXT NOT NULL,
            data_final TEXT NOT NULL,
            ordem INTEGER NOT NULL DEFAULT 0,
            ativo INTEGER NOT NULL DEFAULT 1,
            criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(escala_id) REFERENCES escalas(id) ON DELETE CASCADE,
            FOREIGN KEY(horario_id) REFERENCES horarios(id)
        );"
        Ensure-Column 'escala_vagas' 'ocorrencia_id' 'INTEGER'
        Ensure-Column 'escala_vagas' 'escala_servidor_id_origem' 'INTEGER'
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_escala_vagas_mes ON escala_vagas(escala_id,horario_id,ordem);"
        Db-Exec "CREATE UNIQUE INDEX IF NOT EXISTS idx_escala_vagas_ocorrencia ON escala_vagas(ocorrencia_id) WHERE ocorrencia_id IS NOT NULL;"
        # Indices de desempenho para operacoes frequentes da escala.
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_ocorrencias_sync ON ocorrencias(setor_id,servidor_id,situacao,data_inicial,data_final);"
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_ocorrencias_servidor_sync ON ocorrencias(servidor_id,situacao,data_inicial,data_final);"
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_escala_servidores_sync ON escala_servidores(escala_id,ativo,servidor_id);"
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_escala_dias_sync ON escala_dias(escala_servidor_id,origem,data);"
        Db-Exec "CREATE INDEX IF NOT EXISTS idx_escala_vagas_sync ON escala_vagas(escala_id,ativo,horario_id,ordem);"
    }

    Invoke-CompatStep 'Normalizacao de datas armazenadas' {
        # Datas de escala sao datas de calendario, nao instantes com fuso horario.
        # Bancos antigos podem conter ISO com horario/Z; normalizamos para yyyy-MM-dd
        # para impedir que 30/08 vire 29/08 ao converter para o fuso local.
        # Cada tabela e normalizada em seu proprio try/catch: uma falha em uma
        # delas nao impede a normalizacao das demais.
        # So toca linhas realmente legadas com hora/offset. Valores yyyy-MM-dd
        # ja normalizados nao sao mais reescritos a cada abertura.
        try { Db-Exec "UPDATE ocorrencias SET data_inicial=substr(data_inicial,1,10) WHERE length(data_inicial)>10; UPDATE ocorrencias SET data_final=substr(data_final,1,10) WHERE length(data_final)>10;" } catch { Write-Log ('Falha ao normalizar datas de ocorrencias (migracao de formato): ' + $_.Exception.Message) }
        try { Db-Exec "UPDATE escala_vagas SET data_inicial=substr(data_inicial,1,10) WHERE length(data_inicial)>10; UPDATE escala_vagas SET data_final=substr(data_final,1,10) WHERE length(data_final)>10;" } catch { Write-Log ('Falha ao normalizar datas de escala_vagas (migracao de formato): ' + $_.Exception.Message) }
        try { Db-Exec "UPDATE escala_dias SET data=substr(data,1,10) WHERE length(data)>10;" } catch { Write-Log ('Falha ao normalizar datas de escala_dias (migracao de formato): ' + $_.Exception.Message) }
    }

    Invoke-CompatStep 'Limpeza de residuos vazios em escala_dias' {
        # Remove residuos manuais completamente vazios. Eles nao representam lancamento
        # e nao podem bloquear uma Ocorrencia oficial na mesma data.
        Db-Exec "DELETE FROM escala_dias WHERE origem<>'OCORRENCIA' AND COALESCE(sigla,'')='' AND COALESCE(texto,'')='';"
    }

    Invoke-CompatStep 'Desativar tipo Escala Vaga como ocorrencia' {
        # Evita que Escala Vaga seja confundida com uma ocorrencia de servidor.
        Db-Exec "UPDATE tipos_ocorrencia SET ativo=0, gera_escala=0 WHERE UPPER(nome)='ESCALA VAGA';"
    }


    Invoke-CompatStep 'Auditoria de Coren legado pendente' {
        # V1.0.14.27 - Nao inventa numero de COREN nem marca dispensa automaticamente.
        # Apenas registra no log os cadastros ativos de ENF/TE/AE que precisam ser
        # regularizados manualmente com o numero correto ou uma dispensa justificada.
        $pend=Db-Query "SELECT cp,nome,funcao FROM servidores WHERE ativo=1 AND UPPER(TRIM(COALESCE(funcao,''))) IN ('ENF','TE','AE') AND COALESCE(coren_dispensado,0)=0 AND (COALESCE(TRIM(coren),'')='' OR TRIM(coren)='***') ORDER BY nome;"
        if($pend.Rows.Count -gt 0){
            Write-Log ("ATENCAO: {0} servidor(es) ativo(s) de enfermagem com COREN pendente e sem dispensa justificada." -f $pend.Rows.Count)
            foreach($pr in $pend.Rows){Write-Log ("COREN PENDENTE: CP {0} | {1} | {2}" -f [string]$pr['cp'],[string]$pr['nome'],[string]$pr['funcao'])}
        }
    }

    Invoke-CompatStep 'Recriar gatilho de unicidade escala_servidores' {
        # V1.0.14.17 - Trava de seguranca no proprio banco: um servidor nao pode
        # ficar escalado em duas escalas (dois Setor/Sub_Setor) no mesmo mes.
        # A tela ja impede isso (lista de servidores filtrada + checagem antes
        # de gravar), mas esta trava garante a regra mesmo que algum caminho
        # futuro tente inserir direto no banco. Como todo INSERT nesta tabela
        # ja usa "OR IGNORE", uma linha que violar a regra e simplesmente
        # ignorada (nao trava a operacao inteira, por exemplo uma inclusao em
        # lote com varios servidores).
        # V1.0.14.26 - Este passo roda isolado de propósito: e o passo mais
        # critico da compatibilidade (a causa raiz de um bug silencioso ja
        # corrigido no passado) e nao pode deixar de rodar so porque outro
        # passo, sem relacao, falhou antes dele.
        # DROP + CREATE agora ocorre dentro da mesma transacao de schema: nao ha
        # janela observavel sem a protecao. Inclui tambem UPDATE, importante para
        # reativacao de servidor apos excluir uma ocorrencia definitiva.
        Db-Exec @"
BEGIN IMMEDIATE;
DROP TRIGGER IF EXISTS trg_escala_servidores_unico_mes;
DROP TRIGGER IF EXISTS trg_escala_servidores_unico_mes_update;
CREATE TRIGGER trg_escala_servidores_unico_mes
BEFORE INSERT ON escala_servidores
WHEN NEW.ativo=1 AND EXISTS(
    SELECT 1 FROM escala_servidores es
    JOIN escalas eNova ON eNova.id=NEW.escala_id
    JOIN escalas eExistente ON eExistente.id=es.escala_id
    JOIN setores setExistente ON setExistente.id=eExistente.setor_id
    WHERE es.servidor_id=NEW.servidor_id
      AND es.ativo=1
      AND setExistente.ativo=1
      AND es.escala_id<>NEW.escala_id
      AND eExistente.ano=eNova.ano
      AND eExistente.mes=eNova.mes
)
BEGIN
    SELECT RAISE(IGNORE);
END;
CREATE TRIGGER trg_escala_servidores_unico_mes_update
BEFORE UPDATE OF ativo,escala_id,servidor_id ON escala_servidores
WHEN NEW.ativo=1 AND EXISTS(
    SELECT 1 FROM escala_servidores es
    JOIN escalas eNova ON eNova.id=NEW.escala_id
    JOIN escalas eExistente ON eExistente.id=es.escala_id
    JOIN setores setExistente ON setExistente.id=eExistente.setor_id
    WHERE es.servidor_id=NEW.servidor_id
      AND es.ativo=1
      AND setExistente.ativo=1
      AND es.id<>OLD.id
      AND eExistente.ano=eNova.ano
      AND eExistente.mes=eNova.mes
)
BEGIN
    SELECT RAISE(ABORT,'Servidor ja esta lotado em outra escala neste mes.');
END;
COMMIT;
"@
    }

    Invoke-CompatStep 'Colunas de faixa continua de ocorrencia' {
        # V1.0.14.19 - Tipos de ocorrencia passam a poder ser exibidos como uma
        # faixa continua (ex.: FERIAS, ATESTADO) com texto e duracao minima
        # proprios, configuraveis por tipo em vez de fixos so para Ferias/Atestado.
        Ensure-Column 'tipos_ocorrencia' 'faixa_ativa' 'INTEGER NOT NULL DEFAULT 0'
        Ensure-Column 'tipos_ocorrencia' 'gera_vaga' 'INTEGER NOT NULL DEFAULT 0'
        Ensure-Column 'assinaturas' 'registro_extra' 'TEXT'
        Ensure-Column 'assinaturas' 'cabecalho_titulo' 'TEXT'
        Ensure-Column 'tipos_ocorrencia' 'faixa_texto' 'TEXT'
        Ensure-Column 'tipos_ocorrencia' 'faixa_dias_minimo' 'INTEGER NOT NULL DEFAULT 1'
        # V1.0.14.41 - cores proprias da faixa, independentes das cores da sigla.
        Ensure-Column 'tipos_ocorrencia' 'faixa_cor_fundo' "TEXT NOT NULL DEFAULT '#EEEEEE'"
        Ensure-Column 'tipos_ocorrencia' 'faixa_cor_fonte' "TEXT NOT NULL DEFAULT '#000000'"
        Db-Exec "UPDATE tipos_ocorrencia SET faixa_cor_fundo='#EEEEEE' WHERE COALESCE(TRIM(faixa_cor_fundo),'')=''; UPDATE tipos_ocorrencia SET faixa_cor_fonte='#000000' WHERE COALESCE(TRIM(faixa_cor_fonte),'')='';"
    }

    Invoke-CompatStep 'Migracao de faixas Ferias/Atestado' {
        # Migra o comportamento antigo (fixo p/ Ferias e Atestado, config global)
        # para dentro do proprio tipo. So roda uma vez (marca em "meta"), para
        # nao reativar a faixa se o usuario desativar de proposito depois.
        $jaMigrado = Db-Scalar "SELECT valor FROM meta WHERE chave='migracao_faixa_tipos_v1';"
        if (-not $jaMigrado) {
            $velhoAtDias = Get-ConfigInt 'atestado_faixa_dias' 4 1 31
            $velhoTxtFer = Get-ConfigValue 'texto_faixa_ferias' 'FÉRIAS'
            $velhoTxtAt = Get-ConfigValue 'texto_faixa_atestado' 'ATESTADO'
            Db-Exec ("UPDATE tipos_ocorrencia SET faixa_ativa=1,faixa_texto={0},faixa_dias_minimo=1 WHERE UPPER(COALESCE(sigla,''))='FER';" -f (Sql-Q $velhoTxtFer))
            Db-Exec ("UPDATE tipos_ocorrencia SET faixa_ativa=1,faixa_texto={0},faixa_dias_minimo={1} WHERE UPPER(COALESCE(sigla,''))='AT';" -f (Sql-Q $velhoTxtAt),$velhoAtDias)
            Db-Exec "INSERT OR REPLACE INTO meta(chave,valor) VALUES('migracao_faixa_tipos_v1','1');"
        }
    }

    Invoke-CompatStep 'Marcador explicito de jornada 08h' {
        Ensure-Column 'horarios' 'auto_calendario_08h' 'INTEGER NOT NULL DEFAULT 0'
        $mig08=Db-Scalar "SELECT valor FROM meta WHERE chave='migracao_horario_08h_explicito_v1';"
        if([string]$mig08 -ne '1'){
            Db-Exec "BEGIN IMMEDIATE; UPDATE horarios SET auto_calendario_08h=1 WHERE UPPER(COALESCE(nome,'') || ' ' || COALESCE(descricao,'')) LIKE '%08H%'; INSERT OR REPLACE INTO meta(chave,valor) VALUES('migracao_horario_08h_explicito_v1','1'); COMMIT;"
        }
    }

    Invoke-CompatStep 'Alinhar FKs de escala_vagas com o schema.sql' {
        [void](Ensure-EscalaVagasForeignKeysCritical)
    }

    Invoke-CompatStep 'Gatilhos de integridade das ocorrencias' {
        # Protecao no proprio SQLite contra duas ocorrencias ATIVAS sobrepostas e
        # contra ocorrencia oficial sobre dia MANUAL. A validacao da interface
        # continua existindo para fornecer mensagens amigaveis antes do INSERT.
        Db-Exec @"
BEGIN IMMEDIATE;
DROP TRIGGER IF EXISTS trg_ocorrencias_sobreposicao_insert;
DROP TRIGGER IF EXISTS trg_ocorrencias_sobreposicao_update;
DROP TRIGGER IF EXISTS trg_ocorrencias_manual_insert;
DROP TRIGGER IF EXISTS trg_ocorrencias_manual_update;
DROP TRIGGER IF EXISTS trg_escala_dias_manual_contra_ocorrencia_insert;
DROP TRIGGER IF EXISTS trg_escala_dias_manual_contra_ocorrencia_update;
DROP TRIGGER IF EXISTS trg_escala_servidores_reativacao_definitiva;
CREATE TRIGGER trg_ocorrencias_sobreposicao_insert
BEFORE INSERT ON ocorrencias
WHEN NEW.situacao='ATIVA' AND EXISTS(
    SELECT 1 FROM ocorrencias o
     WHERE o.situacao='ATIVA'
       AND o.servidor_id=NEW.servidor_id
       AND substr(o.data_inicial,1,10)<=substr(NEW.data_final,1,10)
       AND substr(o.data_final,1,10)>=substr(NEW.data_inicial,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Ja existe uma ocorrencia ativa sobreposta para este servidor.');
END;
CREATE TRIGGER trg_ocorrencias_sobreposicao_update
BEFORE UPDATE OF setor_id,servidor_id,data_inicial,data_final,situacao ON ocorrencias
WHEN NEW.situacao='ATIVA' AND EXISTS(
    SELECT 1 FROM ocorrencias o
     WHERE o.id<>OLD.id
       AND o.situacao='ATIVA'
       AND o.servidor_id=NEW.servidor_id
       AND substr(o.data_inicial,1,10)<=substr(NEW.data_final,1,10)
       AND substr(o.data_final,1,10)>=substr(NEW.data_inicial,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Ja existe uma ocorrencia ativa sobreposta para este servidor.');
END;
CREATE TRIGGER trg_ocorrencias_manual_insert
BEFORE INSERT ON ocorrencias
WHEN NEW.situacao='ATIVA'
  AND EXISTS(SELECT 1 FROM tipos_ocorrencia tt WHERE tt.id=NEW.tipo_id AND tt.gera_escala=1 AND COALESCE(tt.sigla,'')<>'')
  AND EXISTS(
    SELECT 1 FROM escala_dias ed
    JOIN escala_servidores es ON es.id=ed.escala_servidor_id
    WHERE ed.origem='MANUAL'
      AND es.ativo=1
      AND es.servidor_id=NEW.servidor_id
      AND substr(ed.data,1,10) BETWEEN substr(NEW.data_inicial,1,10) AND substr(NEW.data_final,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Existem lancamentos manuais na escala dentro do periodo da ocorrencia.');
END;
CREATE TRIGGER trg_ocorrencias_manual_update
BEFORE UPDATE OF setor_id,servidor_id,tipo_id,data_inicial,data_final,situacao ON ocorrencias
WHEN NEW.situacao='ATIVA'
  AND EXISTS(SELECT 1 FROM tipos_ocorrencia tt WHERE tt.id=NEW.tipo_id AND tt.gera_escala=1 AND COALESCE(tt.sigla,'')<>'')
  AND EXISTS(
    SELECT 1 FROM escala_dias ed
    JOIN escala_servidores es ON es.id=ed.escala_servidor_id
    WHERE ed.origem='MANUAL'
      AND es.ativo=1
      AND es.servidor_id=NEW.servidor_id
      AND substr(ed.data,1,10) BETWEEN substr(NEW.data_inicial,1,10) AND substr(NEW.data_final,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Existem lancamentos manuais na escala dentro do periodo da ocorrencia.');
END;
CREATE TRIGGER trg_escala_dias_manual_contra_ocorrencia_insert
BEFORE INSERT ON escala_dias
WHEN NEW.origem='MANUAL' AND EXISTS(
    SELECT 1 FROM escala_servidores es
    JOIN ocorrencias o ON o.servidor_id=es.servidor_id
    JOIN tipos_ocorrencia tt ON tt.id=o.tipo_id
    WHERE es.id=NEW.escala_servidor_id
      AND o.situacao='ATIVA'
      AND tt.gera_escala=1 AND COALESCE(tt.sigla,'')<>''
      AND substr(NEW.data,1,10) BETWEEN substr(o.data_inicial,1,10) AND substr(o.data_final,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Este dia pertence a uma ocorrencia ativa e nao pode receber lancamento manual.');
END;
CREATE TRIGGER trg_escala_dias_manual_contra_ocorrencia_update
BEFORE UPDATE OF data,origem ON escala_dias
WHEN NEW.origem='MANUAL' AND EXISTS(
    SELECT 1 FROM escala_servidores es
    JOIN ocorrencias o ON o.servidor_id=es.servidor_id
    JOIN tipos_ocorrencia tt ON tt.id=o.tipo_id
    WHERE es.id=NEW.escala_servidor_id
      AND o.situacao='ATIVA'
      AND tt.gera_escala=1 AND COALESCE(tt.sigla,'')<>''
      AND substr(NEW.data,1,10) BETWEEN substr(o.data_inicial,1,10) AND substr(o.data_final,1,10)
)
BEGIN
    SELECT RAISE(ABORT,'Este dia pertence a uma ocorrencia ativa e nao pode receber lancamento manual.');
END;
CREATE TRIGGER trg_escala_servidores_reativacao_definitiva
BEFORE UPDATE OF ativo ON escala_servidores
WHEN NEW.ativo=1 AND OLD.ativo=0 AND EXISTS(
    SELECT 1 FROM escala_vagas v
    WHERE v.escala_servidor_id_origem=OLD.id AND v.ocorrencia_id IS NOT NULL AND v.ativo=1
)
BEGIN
    SELECT RAISE(ABORT,'Servidor retirado por ocorrencia definitiva. Edite ou exclua a ocorrencia para reativa-lo.');
END;
COMMIT;
"@
    }

    # Qualquer leitura feita durante as migracoes pode ter carregado o cache
    # antes de uma alteracao direta na tabela configuracoes. Forca recarga limpa.
    Clear-ConfigCache
}

function Sql-Q {
    param([object]$Value)
    if ($null -eq $Value) { return 'NULL' }
    $s = [string]$Value
    return "'" + $s.Replace("'", "''") + "'"
}

function Sql-Int {
    param(
        [object]$Value,
        [string]$Nome = 'ID'
    )
    try {
        if($null -eq $Value -or $Value -eq [DBNull]::Value){ throw 'valor nulo' }
        $texto=([string]$Value).Trim()
        if($texto -notmatch '^-?\d+$'){ throw 'formato invalido' }
        $n=[int64]$texto
        return $n.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        throw ("Valor numerico invalido para {0}: {1}" -f $Nome,[string]$Value)
    }
}

function ConvertFrom-DbDateOnly {
    param([object]$Value)
    if($null -eq $Value -or $Value -eq [DBNull]::Value){ throw 'Data vazia no banco.' }
    $text=([string]$Value).Trim()
    if([string]::IsNullOrWhiteSpace($text)){ throw 'Data vazia no banco.' }

    # Primeiro usa apenas a parte de calendario do ISO, ignorando hora, Z ou offset.
    if($text -match '^(\d{4})-(\d{2})-(\d{2})'){
        $iso=('{0}-{1}-{2}' -f $matches[1],$matches[2],$matches[3])
        return [datetime]::ParseExact($iso,'yyyy-MM-dd',[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::None)
    }
    if($text -match '^(\d{2})/(\d{2})/(\d{4})'){
        $br=('{0}/{1}/{2}' -f $matches[1],$matches[2],$matches[3])
        return [datetime]::ParseExact($br,'dd/MM/yyyy',[System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'),[System.Globalization.DateTimeStyles]::None)
    }
    $tmp=[datetime]::MinValue
    if([datetime]::TryParse($text,[System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'),[System.Globalization.DateTimeStyles]::NoCurrentDateDefault,[ref]$tmp)){ return $tmp.Date }
    if([datetime]::TryParse($text,[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::NoCurrentDateDefault,[ref]$tmp)){ return $tmp.Date }
    throw ('Data invalida no banco: ' + $text)
}

function Set-ComboDataSource {
    # Troca a fonte de dados de um combo com seguranca, usando um BindingSource
    # como intermediario. Ligar um ComboBox DIRETO numa DataTable (mesmo
    # zerando tudo antes) ainda pode disparar "Nao e possivel ligar ao novo
    # membro de exibicao" em certas condicoes (tabela vazia, primeira vinculacao
    # do combo, etc.). Passar por um BindingSource evita essa classe inteira de
    # erro, porque desacopla o ComboBox da tabela bruta.
    # V1.0.14.22.3 - A tentativa anterior (so trocar a ordem ValueMember antes
    # de DisplayMember, V1.0.14.22.2) nao resolveu o erro na inicializacao com
    # o combo de Setor. O BindingSource resolveu de fato.
    param([System.Windows.Forms.ComboBox]$Combo,$DataSource,[string]$DisplayMember,[string]$ValueMember,$SelectedValue=$null)
    $Combo.DataSource = $null
    $Combo.DisplayMember = ''
    $Combo.ValueMember = ''
    $bs = New-Object System.Windows.Forms.BindingSource
    $bs.DataSource = $DataSource
    $Combo.DataSource = $bs
    $Combo.ValueMember = $ValueMember
    $Combo.DisplayMember = $DisplayMember
    if($null -ne $SelectedValue){$Combo.SelectedValue=$SelectedValue}
}

function Get-ComboSelectedInt {
    # V1.0.14.70-G1 - leitura segura de ComboBox vinculado.
    # Durante DataBinding, SelectedValue pode ser temporariamente um DataRowView;
    # nesse instante nao se deve tentar converter o objeto diretamente para Int32.
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [int]$Default = 0
    )
    if($null -eq $Combo){ return $Default }
    try {
        $v=$Combo.SelectedValue
        if($null -eq $v -or $v -eq [DBNull]::Value){ return $Default }
        if($v -is [System.Data.DataRowView]){
            $vm=[string]$Combo.ValueMember
            if(-not [string]::IsNullOrWhiteSpace($vm)){
                try {
                    $cell=$v.Row[$vm]
                    if($null -ne $cell -and $cell -ne [DBNull]::Value){ return [int]$cell }
                } catch { return $Default }
            }
            return $Default
        }
        return [int]$v
    } catch {
        return $Default
    }
}

function Db-Scalar {
    param([string]$Sql)
    $t = Db-Query $Sql
    if ($null -eq $t -or $t.Rows.Count -eq 0) { return $null }
    return $t.Rows[0][0]
}

function Show-Error {
    param([string]$Message)
    Write-Log ('ERRO: ' + $Message)
    [System.Windows.Forms.MessageBox]::Show($Message, 'Sistema de Escala', 'OK', 'Error') | Out-Null
}

function Show-Info {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show($Message, 'Sistema de Escala', 'OK', 'Information') | Out-Null
}

function Confirm-Action {
    param([string]$Message)
    return ([System.Windows.Forms.MessageBox]::Show($Message, 'Sistema de Escala', 'YesNo', 'Question') -eq 'Yes')
}

function New-Button {
    param([string]$Text, [int]$Width = 120)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Width = $Width
    $b.Height = 34
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.BackColor = [System.Drawing.Color]::FromArgb(248,250,252)
    $b.ForeColor = [System.Drawing.Color]::FromArgb(27,50,73)
    $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(181,194,207)
    $b.FlatAppearance.BorderSize = 1
    $b.Font = New-Object System.Drawing.Font('Segoe UI Semibold',9)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Margin = New-Object System.Windows.Forms.Padding(5,8,0,5)
    return $b
}


function Set-PrimaryButton {
    param([System.Windows.Forms.Button]$Button)
    if($null -eq $Button){return}
    $Button.BackColor=[System.Drawing.Color]::FromArgb(31,78,121)
    $Button.ForeColor=[System.Drawing.Color]::White
    $Button.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(31,78,121)
}

function Set-FormTheme {
    param([System.Windows.Forms.Form]$Form)
    if($null -eq $Form){return}
    $Form.BackColor=[System.Drawing.Color]::White
    $Form.Font=New-Object System.Drawing.Font('Segoe UI',9)
    $Form.AutoScaleMode='Dpi'
}

function New-ToolbarLabel {
    param([string]$Text, [int]$Width = 70)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Width = $Width
    $l.Height = 32
    $l.TextAlign = 'MiddleLeft'
    $l.Margin = New-Object System.Windows.Forms.Padding(5,9,3,0)
    return $l
}

function New-GroupLabel {
    # Pequeno "chip" colorido (ex.: "SERVIDORES", "REORDENAR") que abre uma
    # linha de botoes relacionados na tela Escala, para organizar visualmente.
    param([string]$Text)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.AutoSize = $true
    $l.Font = New-Object System.Drawing.Font('Segoe UI Semibold',7.5)
    $l.ForeColor = [System.Drawing.Color]::White
    $l.BackColor = [System.Drawing.Color]::FromArgb(90,105,124)
    $l.Padding = New-Object System.Windows.Forms.Padding(9,4,9,4)
    $l.Margin = New-Object System.Windows.Forms.Padding(0,18,10,5)
    $l.TextAlign = 'MiddleCenter'
    return $l
}

function Set-GridStyle {
    param([System.Windows.Forms.DataGridView]$Grid)
    $prop=$Grid.GetType().GetProperty('DoubleBuffered',[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
    if($null -ne $prop){$prop.SetValue($Grid,$true,$null)}
    $Grid.Dock = 'Fill'
    $Grid.BackgroundColor = [System.Drawing.Color]::White
    $Grid.BorderStyle = 'None'
    $Grid.CellBorderStyle = 'SingleHorizontal'
    $Grid.GridColor = [System.Drawing.Color]::FromArgb(226,232,240)
    $Grid.AllowUserToAddRows = $false
    $Grid.AllowUserToDeleteRows = $false
    $Grid.AllowUserToResizeRows = $false
    $Grid.AllowUserToResizeColumns = $true
    $Grid.ScrollBars = 'Both'
    $Grid.AutoSizeColumnsMode = 'None'
    $Grid.ColumnHeadersHeightSizeMode = 'EnableResizing'
    $Grid.RowHeadersVisible = $false
    $Grid.SelectionMode = 'FullRowSelect'
    $Grid.MultiSelect = $false
    $Grid.AutoSizeRowsMode = 'AllCells'
    $Grid.RowTemplate.Height = 30
    $Grid.Add_DataBindingComplete({
        foreach($col in $this.Columns){
            if($col.Visible){
                $w=$col.Width
                $col.AutoSizeMode='None'
                $col.Resizable='True'
                if($w -lt 42){$col.Width=42}else{$col.Width=$w}
            }
        }
    })
    $Grid.DefaultCellStyle.Font = New-Object System.Drawing.Font('Segoe UI',9)
    $Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::White
    $Grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(248,250,252)
    $Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(219,234,254)
    $Grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::FromArgb(15,23,42)
    $Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(27,50,73)
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $Grid.ColumnHeadersDefaultCellStyle.Font = $script:FontSemibold9
    $Grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(27,50,73)
    $Grid.EnableHeadersVisualStyles = $false
    $Grid.ColumnHeadersHeight = 40
    $Grid.ReadOnly = $true
}

function Get-GridId {
    param([System.Windows.Forms.DataGridView]$Grid, [string]$ColumnName = 'id')
    if ($Grid.SelectedRows.Count -eq 0) { return 0 }
    try { return [int]$Grid.SelectedRows[0].Cells[$ColumnName].Value } catch { return 0 }
}

function Load-SiglaCache {
    $script:SiglaCache = @{}
    $t = Db-Query "SELECT sigla, cor_fundo, cor_fonte, descricao FROM siglas WHERE ativo=1 ORDER BY sigla;"
    foreach ($r in $t.Rows) {
        $script:SiglaCache[[string]$r['sigla']] = @{
            Fundo=[string]$r['cor_fundo']; Fonte=[string]$r['cor_fonte']; Descricao=[string]$r['descricao']
        }
    }
}

function Color-FromHex {
    param([string]$Hex, [System.Drawing.Color]$Default)
    try {
        if ([string]::IsNullOrWhiteSpace($Hex)) { return $Default }
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    } catch { return $Default }
}

function Color-ToHex {
    param([System.Drawing.Color]$Color)
    try {
        return ('#{0:X2}{1:X2}{2:X2}' -f $Color.R,$Color.G,$Color.B)
    } catch { return '#000000' }
}

function Get-ContrastColor {
    param([System.Drawing.Color]$Color)
    try {
        $lum = (0.299 * $Color.R) + (0.587 * $Color.G) + (0.114 * $Color.B)
        if($lum -lt 145){return [System.Drawing.Color]::White}
        return [System.Drawing.Color]::Black
    } catch { return [System.Drawing.Color]::Black }
}

function Refresh-SetorCombos {
    $sel=0
    $sel=Get-ComboSelectedInt $script:cboSetorEscala 0
    $t = Db-Query "SELECT id,nome FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=0 AND COALESCE(especial,0)=0 ORDER BY nome;"
    Set-ComboDataSource $script:cboSetorEscala $t.Copy() 'nome' 'id'
    if($sel -gt 0){$script:cboSetorEscala.SelectedValue=$sel}
    Refresh-SubSetorEscalaCombo
}

function Get-SelectedPrincipalSetorId {
    return (Get-ComboSelectedInt $script:cboSetorEscala 0)
}

function Get-SelectedSubSetorId {
    return (Get-ComboSelectedInt $script:cboSubSetorEscala 0)
}

function Refresh-SubSetorEscalaCombo {
    if($null -eq $script:cboSubSetorEscala){return}
    $sid=Get-SelectedPrincipalSetorId
    $sel=Get-ComboSelectedInt $script:cboSubSetorEscala 0
    if($sid -le 0){$script:cboSubSetorEscala.DataSource=$null;return}
    $t=Db-Query ("SELECT 0 AS id,'(sem Sub_Setor)' AS nome UNION ALL SELECT id,nome FROM sub_setores WHERE ativo=1 AND setor_id={0} ORDER BY id;" -f $sid)
    Set-ComboDataSource $script:cboSubSetorEscala $t 'nome' 'id'
    if($sel -gt 0){$script:cboSubSetorEscala.SelectedValue=$sel}else{$script:cboSubSetorEscala.SelectedValue=0}
}

function Ensure-SubSetorScaleSector {
    param([int]$SetorId,[int]$SubSetorId)
    if($SetorId -le 0 -or $SubSetorId -le 0){return $SetorId}
    $q=Db-Query ("SELECT ss.id,ss.nome,ss.possui_escala,ss.setor_escala_id,COALESCE(ss.leitos,0) AS sub_leitos,se.nome AS setor_nome,se.chefia,se.coren_chefia FROM sub_setores ss JOIN setores se ON se.id=ss.setor_id WHERE ss.id={0} AND ss.setor_id={1};" -f $SubSetorId,$SetorId)
    if($q.Rows.Count -eq 0){return $SetorId}
    $r=$q.Rows[0]
    if([int]$r['possui_escala'] -ne 1){return $SetorId}
    if($r['setor_escala_id'] -ne [DBNull]::Value -and [string]$r['setor_escala_id']){
        $existing=[int]$r['setor_escala_id']
        if([int](Db-Scalar ("SELECT COUNT(*) FROM setores WHERE id={0};" -f $existing)) -gt 0){return $existing}
    }
    $found=Db-Scalar ("SELECT id FROM setores WHERE COALESCE(unidade_escala,0)=1 AND setor_pai_id={0} AND sub_setor_origem_id={1} LIMIT 1;" -f $SetorId,$SubSetorId)
    if($found){$eid=[int]$found}else{
        $nome=("{0} / {1}" -f ([string]$r['setor_nome']),([string]$r['nome'])).Trim()
        $leitos=0;if($r['sub_leitos'] -ne [DBNull]::Value -and [string]$r['sub_leitos']){$leitos=[int]$r['sub_leitos']}
        Db-Exec ("INSERT INTO setores(nome,total_leitos,chefia,coren_chefia,ativo,tipo_setor,especial,setor_pai_id,sub_setor_origem_id,unidade_escala) VALUES({0},{1},{2},{3},1,'ASSISTENCIAL',0,{4},{5},1);" -f (Sql-Q $nome),$leitos,(Sql-Q ([string]$r['chefia'])),(Sql-Q ([string]$r['coren_chefia'])),$SetorId,$SubSetorId)
        $eid=[int](Db-Scalar ("SELECT id FROM setores WHERE COALESCE(unidade_escala,0)=1 AND setor_pai_id={0} AND sub_setor_origem_id={1} ORDER BY id DESC LIMIT 1;" -f $SetorId,$SubSetorId))
    }
    Db-Exec ("UPDATE sub_setores SET setor_escala_id={0} WHERE id={1};" -f $eid,$SubSetorId)
    return $eid
}

function Refresh-OcorrenciaSubSetorCombo {
    try{
        if($null -eq $script:cboOcSubSetor){return}
        $principal=Get-ComboSelectedInt $script:cboOcSetor 0
        $dt=New-Object System.Data.DataTable
        [void]$dt.Columns.Add('id',[int]);[void]$dt.Columns.Add('nome',[string])
        $r=$dt.NewRow();$r['id']=-1;$r['nome']='Todos os Sub_Setores';[void]$dt.Rows.Add($r)
        if($principal -gt 0){
            $r=$dt.NewRow();$r['id']=0;$r['nome']='(sem Sub_Setor)';[void]$dt.Rows.Add($r)
            $subs=Db-Query ("SELECT id,nome FROM sub_setores WHERE ativo=1 AND setor_id={0} ORDER BY nome;" -f $principal)
            foreach($x in $subs.Rows){$r=$dt.NewRow();$r['id']=[int]$x['id'];$r['nome']=[string]$x['nome'];[void]$dt.Rows.Add($r)}
        }
        Set-ComboDataSource $script:cboOcSubSetor $dt 'nome' 'id' -1
    }catch{Write-Log ('Falha ao carregar Sub_Setores de ocorrencia: '+$_.Exception.Message)}
}

function Refresh-OcorrenciaFilterCombos {
    try {
        if ($null -ne $script:cboOcSetor) {
            $sets = Db-Query "SELECT 0 AS id, 'Todos os setores' AS nome UNION ALL SELECT id, nome FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=0 AND COALESCE(especial,0)=0 ORDER BY nome;"
            Set-ComboDataSource $script:cboOcSetor $sets 'nome' 'id' '0'
        }
        Refresh-OcorrenciaSubSetorCombo
        if ($null -ne $script:cboOcTipo) {
            $tipos = Db-Query "SELECT 0 AS id, 'Todos os tipos' AS nome UNION ALL SELECT id, nome FROM tipos_ocorrencia WHERE ativo=1 AND UPPER(nome)<>'ESCALA VAGA' ORDER BY nome;"
            Set-ComboDataSource $script:cboOcTipo $tipos 'nome' 'id' '0'
        }
    } catch { Write-Log ('Falha ao carregar filtros de ocorrencia: ' + $_.Exception.Message) }
}

function Get-OcorrenciaContextClause {
    param([string]$Alias='se')
    $principal=0;$sub=-1
    $principal=Get-ComboSelectedInt $script:cboOcSetor 0
    $sub=Get-ComboSelectedInt $script:cboOcSubSetor -1
    if($principal -le 0){return ''}
    $c=(" AND COALESCE({0}.setor_pai_id,{0}.id)={1}" -f $Alias,$principal)
    if($sub -gt 0){$c+=(" AND COALESCE({0}.sub_setor_origem_id,0)={1}" -f $Alias,$sub)}
    elseif($sub -eq 0){$c+=(" AND COALESCE({0}.unidade_escala,0)=0" -f $Alias)}
    return $c
}

function Get-OcorrenciaExactEffectiveSetorId {
    $principal=0;$sub=-1
    $principal=Get-ComboSelectedInt $script:cboOcSetor 0
    $sub=Get-ComboSelectedInt $script:cboOcSubSetor -1
    if($principal -le 0 -or $sub -lt 0){return 0}
    if($sub -eq 0){return $principal}
    $v=Db-Scalar ("SELECT COALESCE(setor_escala_id,0) FROM sub_setores WHERE id={0} AND setor_id={1};" -f $sub,$principal)
    if($v -and [int]$v -gt 0){return [int]$v}
    $v=Db-Scalar ("SELECT id FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=1 AND setor_pai_id={0} AND sub_setor_origem_id={1} LIMIT 1;" -f $principal,$sub)
    if($v){return [int]$v}
    return 0
}

function Load-OcorrenciaServidores {
    try{
        if($null -eq $script:gridOcServidores){return}
        $principal=Get-ComboSelectedInt $script:cboOcSetor 0
        $mes=Get-ComboSelectedInt $script:cboOcMes 0
        $ano=Get-ComboSelectedInt $script:cboOcAno 0
        if($principal -le 0 -or $mes -le 0 -or $ano -le 0){
            $script:gridOcServidores.DataSource=$null
            if($null -ne $script:lblOcSrvInfo){$script:lblOcSrvInfo.Text='Selecione Setor, Sub_Setor, Mes e Ano para listar os servidores da escala.'}
            return
        }
        $clause=Get-OcorrenciaContextClause 'se'
        # V1.0.14.26 - Adicionado se.ativo=1: os demais pontos de consulta que
        # cruzam escala_servidores/escala_vagas com setores (conflito de
        # inclusao, disponibilidade para lote, etc.) ja exigiam o setor ativo;
        # esta lista de servidores para lancar Ocorrencia era o unico ponto
        # que faltava essa checagem.
        $q="SELECT DISTINCT s.id,s.cp AS CP,s.nome AS Servidor,COALESCE(s.funcao,'') AS Funcao,COALESCE(h.descricao,'') AS Bloco,e.setor_id AS _SetorEfetivoId FROM escalas e JOIN setores se ON se.id=e.setor_id JOIN escala_servidores es ON es.escala_id=e.id AND es.ativo=1 JOIN servidores s ON s.id=es.servidor_id LEFT JOIN horarios h ON h.id=es.horario_id WHERE e.ano=$ano AND e.mes=$mes AND se.ativo=1 $clause ORDER BY s.nome;"
        $t=Db-Query $q
        $script:gridOcServidores.DataSource=$t
        if($script:gridOcServidores.Columns.Contains('id')){$script:gridOcServidores.Columns['id'].Visible=$false}
        if($script:gridOcServidores.Columns.Contains('_SetorEfetivoId')){$script:gridOcServidores.Columns['_SetorEfetivoId'].Visible=$false}
        if($script:gridOcServidores.Columns.Contains('Servidor')){$script:gridOcServidores.Columns['Servidor'].AutoSizeMode='Fill'}
        if($script:gridOcServidores.Columns.Contains('Bloco')){$script:gridOcServidores.Columns['Bloco'].Width=360}
        if($script:gridOcServidores.Columns.Contains('CP')){$script:gridOcServidores.Columns['CP'].Width=75}
        $script:gridOcServidores.ClearSelection()
        if($null -ne $script:lblOcSrvInfo){$script:lblOcSrvInfo.Text=('{0} servidor(es) cadastrado(s) nesta escala. Selecione um servidor e clique em + NOVA OCORRENCIA.' -f $t.Rows.Count)}
    }catch{Show-Error $_.Exception.Message}
}

function Load-Servidores {
    try {
        $termo = $script:txtBuscaServidor.Text.Trim()
        $where = 'ativo=1'
        if ($termo) {
            # Mesma regra da Lotacao em Lote: varios termos separados por virgula;
            # numero = CP ou Coren exato; texto = parte do nome (sem diferenciar maiusculas).
            $tokens = @($termo -split ',' | ForEach-Object {$_.Trim()} | Where-Object {$_ -ne ''} | Sort-Object -Unique)
            $conds = @()
            foreach ($t in $tokens) {
                if ($t -match '^\d+$') {
                    $conds += ("(cp={0} OR coren={0})" -f (Sql-Q $t))
                } else {
                    $conds += ("nome LIKE {0}" -f (Sql-Q ('%'+$t+'%')))
                }
            }
            if ($conds.Count -gt 0) { $where += ' AND (' + ($conds -join ' OR ') + ')' }
        }
        $script:gridServidores.DataSource = Db-Query "SELECT id, cp AS CP, nome AS Nome, funcao AS Funcao, tipo_vinculo AS Vinculo, coren AS Coren, sub_funcao AS Sub_Funcao, (CASE WHEN coren_dispensado=1 THEN 'Sim' ELSE 'Nao' END) AS Coren_Dispensado FROM servidores WHERE $where ORDER BY nome;"
        if ($script:gridServidores.Columns.Contains('id')) { $script:gridServidores.Columns['id'].Visible = $false }
        if ($script:gridServidores.Columns.Contains('Nome')) { $script:gridServidores.Columns['Nome'].AutoSizeMode = 'Fill' }
        $script:lblServidorCount.Text = ('{0} servidor(es)' -f $script:gridServidores.Rows.Count)
    } catch { Show-Error $_.Exception.Message }
}

function Delete-ServidoresSelecionados {
    # Exclusao em lote (varias linhas selecionadas de uma vez). Segue o mesmo
    # padrao seguro usado em Setores/Tipos de Ocorrencia: se o servidor ja foi
    # usado em alguma escala/ocorrencia, so DESATIVA (historico intacto);
    # se nunca foi usado, exclui de verdade.
    try {
        if($null -eq $script:gridServidores.SelectedRows -or $script:gridServidores.SelectedRows.Count -eq 0){
            Show-Info 'Selecione um ou mais servidores na lista (Ctrl+clique ou Shift+clique para varios).'
            return
        }
        $ids=New-Object System.Collections.ArrayList
        foreach($row in $script:gridServidores.SelectedRows){
            try{$rid=[int]$row.Cells['id'].Value}catch{$rid=0}
            if($rid -gt 0){[void]$ids.Add($rid)}
        }
        if($ids.Count -eq 0){Show-Info 'Selecione um ou mais servidores na lista.';return}

        $desativar=New-Object System.Collections.ArrayList
        $excluir=New-Object System.Collections.ArrayList
        foreach($id in $ids){
            $idSql=Sql-Int $id 'servidor_id';$nome=[string](Db-Scalar "SELECT nome FROM servidores WHERE id=$idSql;")
            $emUso=[int](Db-Scalar "SELECT (SELECT COUNT(*) FROM escala_servidores WHERE servidor_id=$idSql)+(SELECT COUNT(*) FROM ocorrencias WHERE servidor_id=$idSql);")
            if($emUso -gt 0){[void]$desativar.Add(@{Id=$id;Nome=$nome})}else{[void]$excluir.Add(@{Id=$id;Nome=$nome})}
        }

        $msg="Voce selecionou {0} servidor(es)." -f $ids.Count
        if($excluir.Count -gt 0){$msg+="`r`n`r`n{0} sera(ao) EXCLUIDO(S) definitivamente (nunca foram usados em nenhuma escala/ocorrencia):`r`n- " -f $excluir.Count;$msg+=(($excluir | ForEach-Object {$_.Nome}) -join "`r`n- ")}
        if($desativar.Count -gt 0){$msg+="`r`n`r`n{0} sera(ao) apenas DESATIVADO(S) (ja usado(s) em escala/ocorrencia; historico continua intacto):`r`n- " -f $desativar.Count;$msg+=(($desativar | ForEach-Object {$_.Nome}) -join "`r`n- ")}
        $msg+="`r`n`r`nContinuar?"
        if(-not (Confirm-Action $msg)){return}

        foreach($d in $desativar){$idSql=Sql-Int $d.Id 'servidor_id';Db-Exec "UPDATE servidores SET ativo=0 WHERE id=$idSql;"}
        foreach($e in $excluir){$idSql=Sql-Int $e.Id 'servidor_id';Db-Exec "DELETE FROM servidores WHERE id=$idSql;"}
        Show-Info ("Concluido: {0} excluido(s), {1} desativado(s)." -f $excluir.Count,$desativar.Count)
        Load-Servidores
    } catch { Show-Error $_.Exception.Message }
}

function Show-CadastroServidoresLoteDialog {
    # Cadastro em lote: cola varias linhas de uma vez (ex.: direto do Excel,
    # colunas separadas por TAB, ou digitadas separando por ; ) e cadastra
    # todos os servidores validos numa tacada so.
    try {
        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text='Cadastrar servidores em lote'
        $f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(920,620);$f.FormBorderStyle='Sizable';$f.MinimumSize=New-Object System.Drawing.Size(760,480)

        $lInfo=New-Object System.Windows.Forms.Label
        $lInfo.Text="Cole uma linha por servidor (direto do Excel funciona: colunas separadas por TAB). Tambem aceita ponto e virgula.`r`nOrdem das colunas: CP;Nome;Funcao;Tipo de Vinculo;Coren;Sub_Funcao;Dispensa_Coren;Motivo_Dispensa`r`nCP e Nome sao obrigatorios. Os demais podem ficar em branco.`r`nDispensa_Coren: preencha S (ou SIM) para servidor ENF/TE/AE readaptado que nao precisa apresentar Coren - nesse caso o Coren pode ficar em branco. Motivo_Dispensa e opcional (ex.: Readaptacao funcional)."
        $lInfo.Location=New-Object System.Drawing.Point(20,15);$lInfo.Size=New-Object System.Drawing.Size(860,68);$lInfo.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
        $lInfo.Anchor='Top,Left,Right'
        $f.Controls.Add($lInfo)

        $tbCola=New-Object System.Windows.Forms.TextBox
        $tbCola.Multiline=$true;$tbCola.ScrollBars='Both';$tbCola.WordWrap=$false
        $tbCola.Location=New-Object System.Drawing.Point(20,88);$tbCola.Size=New-Object System.Drawing.Size(860,127)
        $tbCola.Anchor='Top,Left,Right'
        $tbCola.Text="123;Fulano de Tal;ENF;CTR;123456`r`n456;Ciclana da Silva;TE;;789012`r`n789;Beltrano Readaptado;TE;;;;S;Readaptacao funcional"
        $f.Controls.Add($tbCola)

        $btnPrever=New-Button 'PROCESSAR / PREVER' 175;$btnPrever.Location=New-Object System.Drawing.Point(20,225);$btnPrever.Anchor='Top,Left';$f.Controls.Add($btnPrever)
        $lblResumo=New-Object System.Windows.Forms.Label;$lblResumo.Location=New-Object System.Drawing.Point(20,264);$lblResumo.Size=New-Object System.Drawing.Size(860,40);$lblResumo.Anchor='Top,Left,Right';$f.Controls.Add($lblResumo)

        $grid=New-Object System.Windows.Forms.DataGridView
        Set-GridStyle $grid
        $grid.Location=New-Object System.Drawing.Point(20,312);$grid.Size=New-Object System.Drawing.Size(860,220);$grid.Anchor='Top,Bottom,Left,Right'
        $grid.Dock='None'
        $f.Controls.Add($grid)

        $script:LoteServidoresValidos=New-Object System.Collections.ArrayList
        $script:LoteProblemas=New-Object System.Collections.ArrayList

        $processar={
            $script:LoteServidoresValidos.Clear()
            $script:LoteProblemas.Clear()
            $problemas=$script:LoteProblemas
            $linhas=$tbCola.Text -split "`r`n|`n"
            $tabela=New-Object System.Data.DataTable
            foreach($col in @('Linha','CP','Nome','Funcao','Vinculo','Coren','Sub_Funcao','Dispensa','Motivo_Dispensa','Situacao')){[void]$tabela.Columns.Add($col,[string])}
            $qtdOk=0;$qtdPulados=0
            $corensNoLote=@{}
            $cpsNoLote=@{}
            foreach($linha in $linhas){
                if([string]::IsNullOrWhiteSpace($linha)){continue}
                $sep=$(if($linha.Contains("`t")){"`t"}else{';'})
                $partes=$linha.Split($sep)
                $cp=$(if($partes.Length -ge 1){$partes[0].Trim()}else{''})
                $nome=$(if($partes.Length -ge 2){$partes[1].Trim()}else{''})
                $funcao=$(if($partes.Length -ge 3){$partes[2].Trim()}else{''})
                $vinculo=$(if($partes.Length -ge 4){$partes[3].Trim()}else{''})
                $coren=$(if($partes.Length -ge 5){$partes[4].Trim()}else{''})
                $subFuncao=$(if($partes.Length -ge 6){$partes[5].Trim()}else{''})
                $dispensaTxt=$(if($partes.Length -ge 7){$partes[6].Trim()}else{''})
                $motivoDispensa=$(if($partes.Length -ge 8){$partes[7].Trim()}else{''})
                $dispensa = @('S','SIM','1','X') -contains $dispensaTxt.ToUpperInvariant()
                $dispensaTxtGrid = $(if($dispensa){'Sim'}else{'Nao'})
                $situacao=''
                $numLinha=$tabela.Rows.Count+1
                $exigeCoren = @('ENF','TE','AE') -contains $funcao.ToUpperInvariant()
                if(-not $cp -or -not $nome){
                    $faltando=@();if(-not $cp){$faltando+='CP'};if(-not $nome){$faltando+='Nome'}
                    $situacao=('PULADO: falta {0}' -f ($faltando -join ' e '))
                    [void]$problemas.Add(("Linha {0}: falta {1} (nao da para identificar o servidor)." -f $numLinha,($faltando -join ' e ')))
                } elseif($exigeCoren -and -not $coren -and -not $dispensa){
                    $situacao=('PULADO: falta Coren (obrigatorio para {0})' -f $funcao)
                    [void]$problemas.Add(("Linha {0} (CP {1}, {2}): Coren e obrigatorio para o cargo {3} (ENF/TE/AE). Se for readaptado, preencha Dispensa_Coren com S." -f $numLinha,$cp,$nome,$funcao))
                } elseif($coren -and $coren -ne '***' -and $coren -match '^0+$'){
                    $situacao='PULADO: Coren invalido (somente zeros)'
                    [void]$problemas.Add(("Linha {0} (CP {1}, {2}): o Coren {3} nao e valido (nao pode ser somente zeros). Se o cargo nao exige Coren, use ***." -f $numLinha,$cp,$nome,$coren))
                } else {
                    $donoCp=Db-Scalar ("SELECT nome FROM servidores WHERE cp={0};" -f (Sql-Q $cp))
                    if($donoCp){
                        $situacao=('PULADO: CP ja cadastrado ({0})' -f $donoCp)
                        [void]$problemas.Add(("Linha {0} (CP {1}, {2}): este CP ja pertence a '{3}' no cadastro." -f $numLinha,$cp,$nome,$donoCp))
                    } elseif($cpsNoLote.ContainsKey($cp)){
                        $situacao=('PULADO: CP repetido no lote (tambem na linha {0})' -f $cpsNoLote[$cp])
                        [void]$problemas.Add(("Linha {0} (CP {1}, {2}): este CP tambem aparece na linha {3} deste mesmo lote colado." -f $numLinha,$cp,$nome,$cpsNoLote[$cp]))
                    } elseif($coren -and $coren -ne '***' -and (Db-Scalar ("SELECT nome||' - CP '||cp FROM servidores WHERE TRIM(coren)={0};" -f (Sql-Q $coren)))){
                        $donoCoren=Db-Scalar ("SELECT nome||' - CP '||cp FROM servidores WHERE TRIM(coren)={0};" -f (Sql-Q $coren))
                        $situacao=('PULADO: Coren ja usado ({0})' -f $donoCoren)
                        [void]$problemas.Add(("Linha {0} (CP {1}, {2}): o Coren {3} ja pertence a '{4}' no cadastro." -f $numLinha,$cp,$nome,$coren,$donoCoren))
                    } elseif($coren -and $coren -ne '***' -and $corensNoLote.ContainsKey($coren)){
                        $situacao=('PULADO: Coren repetido no lote (tambem na linha {0})' -f $corensNoLote[$coren])
                        [void]$problemas.Add(("Linha {0} (CP {1}, {2}): o Coren {3} tambem aparece na linha {4} deste mesmo lote colado." -f $numLinha,$cp,$nome,$coren,$corensNoLote[$coren]))
                    } else {
                        $situacao='OK, sera cadastrado'
                        $cpsNoLote[$cp]=$numLinha
                        if($coren -and $coren -ne '***'){$corensNoLote[$coren]=$numLinha}
                        [void]$script:LoteServidoresValidos.Add([pscustomobject]@{Cp=$cp;Nome=$nome;Funcao=$funcao;Vinculo=$vinculo;Coren=$coren;SubFuncao=$subFuncao;Dispensa=$dispensa;MotivoDispensa=$motivoDispensa})
                    }
                }
                if($situacao -eq 'OK, sera cadastrado'){$qtdOk++}else{$qtdPulados++}
                [void]$tabela.Rows.Add($numLinha,$cp,$nome,$funcao,$vinculo,$coren,$subFuncao,$dispensaTxtGrid,$motivoDispensa,$situacao)
            }
            $grid.DataSource=$tabela
            if($grid.Columns.Contains('Nome')){$grid.Columns['Nome'].AutoSizeMode='Fill'}
            foreach($lin in $grid.Rows){
                $sit=[string]$lin.Cells['Situacao'].Value
                if($sit.StartsWith('PULADO')){
                    $lin.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(253,226,226)
                    $lin.DefaultCellStyle.ForeColor=[System.Drawing.Color]::FromArgb(153,27,27)
                } elseif($sit -eq 'OK, sera cadastrado'){
                    $lin.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(220,245,225)
                }
            }
            if($grid.Columns.Contains('Situacao')){$grid.Columns['Situacao'].Width=280}
            if($grid.Columns.Contains('Motivo_Dispensa')){$grid.Columns['Motivo_Dispensa'].Width=160}
            $lblResumo.Text="$qtdOk pronto(s) para cadastrar; $qtdPulados linha(s) com problema (em vermelho na tabela; passe o mouse ou veja a coluna Situacao para o motivo)."
            $lblResumo.ForeColor=$(if($qtdPulados -gt 0){[System.Drawing.Color]::FromArgb(180,83,9)}else{[System.Drawing.Color]::FromArgb(21,128,61)})
        }
        $btnPrever.Add_Click($processar)
        & $processar

        $btnSalvar=New-Button 'CADASTRAR TODOS OS VALIDOS' 240;Set-PrimaryButton $btnSalvar;$btnSalvar.Location=New-Object System.Drawing.Point(430,540);$btnSalvar.Anchor='Bottom,Left'
        $btnFechar=New-Button 'FECHAR' 120;$btnFechar.Location=New-Object System.Drawing.Point(680,540);$btnFechar.Anchor='Bottom,Left';$btnFechar.DialogResult='Cancel'
        $btnSalvar.Add_Click({
            & $processar
            if($script:LoteServidoresValidos.Count -eq 0){
                $msg='Nenhum servidor valido para cadastrar.'
                if($script:LoteProblemas.Count -gt 0){$msg+="`r`n`r`nProblemas encontrados:`r`n- " + (($script:LoteProblemas | Select-Object -First 15) -join "`r`n- ")}
                Show-Info $msg
                return
            }
            $msgConfirma="Cadastrar {0} servidor(es) novo(s)?" -f $script:LoteServidoresValidos.Count
            if($script:LoteProblemas.Count -gt 0){
                $msgConfirma+="`r`n`r`n{0} linha(s) NAO serao cadastradas por causa de:`r`n- " -f $script:LoteProblemas.Count
                $msgConfirma+=(($script:LoteProblemas | Select-Object -First 15) -join "`r`n- ")
                if($script:LoteProblemas.Count -gt 15){$msgConfirma+=("`r`n... e mais {0} problema(s)." -f ($script:LoteProblemas.Count-15))}
            }
            if(-not (Confirm-Action $msgConfirma)){return}
            try{
                $sql=New-Object System.Text.StringBuilder;[void]$sql.AppendLine('BEGIN;')
                foreach($s in $script:LoteServidoresValidos){
                    [void]$sql.AppendLine(("INSERT INTO servidores(cp,nome,funcao,tipo_vinculo,coren,sub_funcao,coren_dispensado,motivo_dispensa_coren) VALUES ({0},{1},{2},{3},{4},{5},{6},{7});" -f (Sql-Q $s.Cp),(Sql-Q $s.Nome),(Sql-Q $s.Funcao),(Sql-Q $s.Vinculo),(Sql-Q $s.Coren),(Sql-Q $s.SubFuncao),$(if($s.Dispensa){1}else{0}),(Sql-Q $s.MotivoDispensa)))
                }
                [void]$sql.AppendLine('COMMIT;')
                Db-Exec $sql.ToString()
                Show-Info ("{0} servidor(es) cadastrado(s) com sucesso." -f $script:LoteServidoresValidos.Count)
                Load-Servidores
                Load-Readaptados
                $f.DialogResult='OK';$f.Close()
            }catch{Show-Error $_.Exception.Message}
        })
        $f.Controls.Add($btnSalvar);$f.Controls.Add($btnFechar)
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch { Show-Error $_.Exception.Message }
}

function Show-ServidorDialog {
    param([int]$Id = 0,$Owner=$null)
    try {
        $data = $null
        if ($Id -gt 0) {
            $idSql=Sql-Int $Id 'servidor_id';$t = Db-Query "SELECT * FROM servidores WHERE id=$idSql;"
            if ($t.Rows.Count -eq 0) { return }
            $data = $t.Rows[0]
        }
        $f = New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text = $(if($Id -gt 0){'Editar servidor'}else{'Novo servidor'})
        $f.StartPosition = 'CenterParent'; $f.ClientSize = New-Object System.Drawing.Size(580,480); $f.FormBorderStyle='FixedDialog'; $f.MaximizeBox=$false
        $labels = @('CP','Nome','Funcao','Tipo de Vinculo','Coren','Sub_Funcao')
        $boxes = @{}
        for($i=0;$i -lt $labels.Count;$i++){
            $l=New-Object System.Windows.Forms.Label; $l.Text=$labels[$i]; $l.Location=New-Object System.Drawing.Point(25,(28+$i*50)); $l.Size=New-Object System.Drawing.Size(120,22); $f.Controls.Add($l)
            $tb=New-Object System.Windows.Forms.TextBox; $tb.Location=New-Object System.Drawing.Point(150,(25+$i*50)); $tb.Size=New-Object System.Drawing.Size(390,25); $f.Controls.Add($tb); $boxes[$labels[$i]]=$tb
        }
        # V1.0.14.23 - dispensa de Coren (ex.: readaptacao funcional): quando marcado,
        # a exigencia de Coren para ENF/TE/AE deixa de bloquear este servidor.
        $chkDispensa=New-Object System.Windows.Forms.CheckBox
        $chkDispensa.Text='Coren dispensado (readaptado - nao exigir Coren para este servidor)'
        $chkDispensa.Location=New-Object System.Drawing.Point(25,332);$chkDispensa.Size=New-Object System.Drawing.Size(520,24);$chkDispensa.AutoSize=$false
        $f.Controls.Add($chkDispensa)
        $lMotivo=New-Object System.Windows.Forms.Label; $lMotivo.Text='Motivo'; $lMotivo.Location=New-Object System.Drawing.Point(25,368); $lMotivo.Size=New-Object System.Drawing.Size(120,22); $f.Controls.Add($lMotivo)
        $tbMotivo=New-Object System.Windows.Forms.TextBox; $tbMotivo.Location=New-Object System.Drawing.Point(150,365); $tbMotivo.Size=New-Object System.Drawing.Size(390,25); $tbMotivo.Enabled=$false; $f.Controls.Add($tbMotivo)
        $chkDispensa.Add_CheckedChanged({ $tbMotivo.Enabled = $chkDispensa.Checked })
        if($data){
            $boxes['CP'].Text=[string]$data['cp']; $boxes['Nome'].Text=[string]$data['nome']; $boxes['Funcao'].Text=[string]$data['funcao']; $boxes['Tipo de Vinculo'].Text=[string]$data['tipo_vinculo']; $boxes['Coren'].Text=[string]$data['coren']; $boxes['Sub_Funcao'].Text=[string]$data['sub_funcao']
            $chkDispensa.Checked = ([string]$data['coren_dispensado'] -eq '1')
            $tbMotivo.Text = [string]$data['motivo_dispensa_coren']
            $tbMotivo.Enabled = $chkDispensa.Checked
        }
        $ok=New-Button 'SALVAR' 120; $ok.Location=New-Object System.Drawing.Point(285,410)
        $cancel=New-Button 'CANCELAR' 120; $cancel.Location=New-Object System.Drawing.Point(420,410); $cancel.DialogResult='Cancel'
        $ok.Add_Click({
            try {
                $cp=$boxes['CP'].Text.Trim(); $nome=$boxes['Nome'].Text.Trim(); $coren=$boxes['Coren'].Text.Trim()
                $funcaoTxt=$boxes['Funcao'].Text.Trim()
                $dispensado = $(if($chkDispensa.Checked){1}else{0})
                $motivo = $tbMotivo.Text.Trim()
                if(-not $cp -or -not $nome){ Show-Info 'Informe CP e Nome.'; return }
                if((@('ENF','TE','AE') -contains $funcaoTxt.ToUpperInvariant()) -and -not $coren -and -not $chkDispensa.Checked){
                    Show-Info 'Informe o Coren: obrigatorio para Enfermeiro/a (ENF), Tecnico de Enfermagem (TE) e Auxiliar de Enfermagem (AE). Se o servidor foi readaptado e nao precisa mais de Coren, marque "Coren dispensado".'
                    return
                }
                if($coren -and $coren -ne '***' -and $coren -match '^0+$'){
                    Show-Info 'Coren invalido: nao pode ser somente zeros (ex.: 00000). Se o cargo nao exige Coren, use *** no lugar de um numero.'
                    return
                }
                if($coren -and $coren -ne '***'){
                    $dupCp=Db-Scalar ("SELECT cp FROM servidores WHERE TRIM(coren)={0} AND id<>{1} LIMIT 1;" -f (Sql-Q $coren),$(if($Id -gt 0){$Id}else{0}))
                    if($dupCp){ Show-Info ("Ja existe um servidor com este Coren (CP {0}). O Coren nao pode se repetir." -f $dupCp); return }
                }
                if($Id -gt 0){
                    Db-Exec ("UPDATE servidores SET cp={0},nome={1},funcao={2},tipo_vinculo={3},coren={4},sub_funcao={5},coren_dispensado={6},motivo_dispensa_coren={7} WHERE id={8};" -f (Sql-Q $cp),(Sql-Q $nome),(Sql-Q ($boxes['Funcao'].Text.Trim())),(Sql-Q ($boxes['Tipo de Vinculo'].Text.Trim())),(Sql-Q $coren),(Sql-Q ($boxes['Sub_Funcao'].Text.Trim())),$dispensado,(Sql-Q $motivo),$Id)
                } else {
                    Db-Exec ("INSERT INTO servidores(cp,nome,funcao,tipo_vinculo,coren,sub_funcao,coren_dispensado,motivo_dispensa_coren) VALUES ({0},{1},{2},{3},{4},{5},{6},{7});" -f (Sql-Q $cp),(Sql-Q $nome),(Sql-Q ($boxes['Funcao'].Text.Trim())),(Sql-Q ($boxes['Tipo de Vinculo'].Text.Trim())),(Sql-Q $coren),(Sql-Q ($boxes['Sub_Funcao'].Text.Trim())),$dispensado,(Sql-Q $motivo))
                }
                $f.DialogResult='OK'; $f.Close()
            } catch { Show-Error $_.Exception.Message }
        })
        $f.Controls.Add($ok);$f.Controls.Add($cancel);$f.AcceptButton=$ok;$f.CancelButton=$cancel
        $dlgOwner=$(if($null -ne $Owner){$Owner}else{$script:MainForm})
        $dlgResult=$f.ShowDialog($dlgOwner);$f.Dispose();if($dlgResult -eq 'OK'){ Load-Servidores; Load-Readaptados }
    } catch { Show-Error $_.Exception.Message }
}

function Load-Readaptados {
    # V1.0.14.23 - Aba "Readaptados (sem Coren)": lista todos os servidores ativos
    # de cargo ENF/TE/AE (os unicos onde a regra da V1.0.14.21.18 exige Coren),
    # mostrando quem ja esta com a dispensa marcada e quem ainda nao.
    try {
        $termo = $script:txtBuscaReadapt.Text.Trim()
        $where = "ativo=1 AND UPPER(TRIM(funcao)) IN ('ENF','TE','AE')"
        if ($termo) {
            $tokens = @($termo -split ',' | ForEach-Object {$_.Trim()} | Where-Object {$_ -ne ''} | Sort-Object -Unique)
            $conds = @()
            foreach ($t in $tokens) {
                if ($t -match '^\d+$') { $conds += ("(cp={0} OR coren={0})" -f (Sql-Q $t)) }
                else { $conds += ("nome LIKE {0}" -f (Sql-Q ('%'+$t+'%'))) }
            }
            if ($conds.Count -gt 0) { $where += ' AND (' + ($conds -join ' OR ') + ')' }
        }
        $script:gridReadaptados.DataSource = Db-Query ("SELECT id, cp AS CP, nome AS Nome, funcao AS Funcao, coren AS Coren, (CASE WHEN coren_dispensado=1 THEN 'Sim' ELSE 'Nao' END) AS Dispensado, motivo_dispensa_coren AS Motivo FROM servidores WHERE $where ORDER BY coren_dispensado DESC, nome;")
        if ($script:gridReadaptados.Columns.Contains('id')) { $script:gridReadaptados.Columns['id'].Visible = $false }
        if ($script:gridReadaptados.Columns.Contains('Nome')) { $script:gridReadaptados.Columns['Nome'].AutoSizeMode = 'Fill' }
        if ($script:gridReadaptados.Columns.Contains('Motivo')) { $script:gridReadaptados.Columns['Motivo'].Width = 260 }
        foreach($lin in $script:gridReadaptados.Rows){
            if([string]$lin.Cells['Dispensado'].Value -eq 'Sim'){
                $lin.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(220,245,225)
            }
        }
        $qtdDisp=[int](Db-Scalar "SELECT COUNT(*) FROM servidores WHERE ativo=1 AND UPPER(TRIM(funcao)) IN ('ENF','TE','AE') AND coren_dispensado=1;")
        $script:lblReadaptCount.Text = ('{0} servidor(es) ENF/TE/AE nesta lista; {1} com Coren dispensado.' -f $script:gridReadaptados.Rows.Count,$qtdDisp)
    } catch { Show-Error $_.Exception.Message }
}

function Show-MotivoDispensaDialog {
    param([string]$MotivoAtual='')
    $resultado = $null
    $f=New-Object System.Windows.Forms.Form
    Set-FormTheme $f
    $f.Text='Motivo da dispensa de Coren'
    $f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(460,180);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false
    $l=New-Object System.Windows.Forms.Label;$l.Text='Motivo (opcional, ex.: Readaptacao funcional):';$l.Location=New-Object System.Drawing.Point(20,20);$l.Size=New-Object System.Drawing.Size(420,22);$f.Controls.Add($l)
    $tb=New-Object System.Windows.Forms.TextBox;$tb.Location=New-Object System.Drawing.Point(20,46);$tb.Size=New-Object System.Drawing.Size(420,25);$tb.Text=$MotivoAtual;$f.Controls.Add($tb)
    $ok=New-Button 'CONFIRMAR' 140;Set-PrimaryButton $ok;$ok.Location=New-Object System.Drawing.Point(140,110)
    $cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(290,110);$cancel.DialogResult='Cancel'
    $ok.Add_Click({ $f.DialogResult='OK';$f.Close() })
    $f.Controls.Add($ok);$f.Controls.Add($cancel);$f.AcceptButton=$ok;$f.CancelButton=$cancel
    $dlgResult=$f.ShowDialog($script:MainForm);$valor=$tb.Text.Trim();$f.Dispose();if($dlgResult -eq 'OK'){ return $valor }
    return $null
}

function Set-DispensaCorenSelecionados {
    param([bool]$Dispensar)
    try {
        if($null -eq $script:gridReadaptados.SelectedRows -or $script:gridReadaptados.SelectedRows.Count -eq 0){
            Show-Info 'Selecione um ou mais servidores na lista (Ctrl+clique ou Shift+clique para varios).'
            return
        }
        $ids=New-Object System.Collections.ArrayList
        $nomes=New-Object System.Collections.ArrayList
        foreach($row in $script:gridReadaptados.SelectedRows){
            try{$rid=[int]$row.Cells['id'].Value}catch{$rid=0}
            if($rid -gt 0){[void]$ids.Add($rid);[void]$nomes.Add([string]$row.Cells['Nome'].Value)}
        }
        if($ids.Count -eq 0){return}
        if($Dispensar){
            $msg = "Marcar Coren como DISPENSADO para {0} servidor(es)?`r`n`r`n- {1}`r`n`r`nEsses servidores poderao ficar sem Coren cadastrado (ex.: readaptacao funcional)." -f $ids.Count,($nomes -join "`r`n- ")
            if(-not (Confirm-Action $msg)){return}
            $motivo = Show-MotivoDispensaDialog ''
            if($null -eq $motivo){return}
            $sbDisp=New-Object System.Text.StringBuilder;[void]$sbDisp.AppendLine('BEGIN IMMEDIATE;');foreach($id in $ids){[void]$sbDisp.AppendLine(("UPDATE servidores SET coren_dispensado=1, motivo_dispensa_coren={0} WHERE id={1};" -f (Sql-Q $motivo),$id))};[void]$sbDisp.AppendLine('COMMIT;');Db-Exec $sbDisp.ToString()
            Write-Log ("Coren dispensado marcado para: " + ($nomes -join ', '))
        } else {
            $msg = "Remover a dispensa de Coren de {0} servidor(es)?`r`n`r`n- {1}`r`n`r`nA partir de agora, se o cargo for ENF/TE/AE, o Coren volta a ser obrigatorio para eles." -f $ids.Count,($nomes -join "`r`n- ")
            if(-not (Confirm-Action $msg)){return}
            $sbDisp=New-Object System.Text.StringBuilder;[void]$sbDisp.AppendLine('BEGIN IMMEDIATE;');foreach($id in $ids){[void]$sbDisp.AppendLine(("UPDATE servidores SET coren_dispensado=0, motivo_dispensa_coren=NULL WHERE id={0};" -f $id))};[void]$sbDisp.AppendLine('COMMIT;');Db-Exec $sbDisp.ToString()
            Write-Log ("Coren dispensado removido para: " + ($nomes -join ', '))
        }
        Load-Readaptados; Load-Servidores
    } catch { Show-Error $_.Exception.Message }
}

function Delete-Setor {
    try {
        $id=Get-GridId $script:gridSetores
        if($id -le 0){Show-Info 'Selecione um Setor Principal.';return}
        $nome=[string](Db-Scalar "SELECT nome FROM setores WHERE id=$id;")
        $filhosIds=@()
        $fq=Db-Query "SELECT id FROM setores WHERE COALESCE(unidade_escala,0)=1 AND setor_pai_id=$id;"
        foreach($fr in $fq.Rows){$filhosIds+=[int]$fr['id']}
        $idsTodos=@($id)+$filhosIds
        $idsTxt=($idsTodos -join ',')
        $qtdEscalas=[int](Db-Scalar "SELECT COUNT(*) FROM escalas WHERE setor_id IN ($idsTxt);")
        $qtdOc=[int](Db-Scalar "SELECT COUNT(*) FROM ocorrencias WHERE setor_id IN ($idsTxt);")
        $qtdSub=[int](Db-Scalar "SELECT COUNT(*) FROM sub_setores WHERE setor_id=$id;")
        if($qtdEscalas -gt 0 -or $qtdOc -gt 0){
            $msg="O Setor '$nome' ja tem $qtdEscalas escala(s) e $qtdOc ocorrencia(s) cadastradas (incluindo Sub_Setores). Ele sera apenas DESATIVADO (some das listas e combos, mas o historico e as impressoes ja geradas continuam intactos). Continuar?"
            if(-not (Confirm-Action $msg)){return}
            Db-Exec "BEGIN IMMEDIATE; UPDATE setores SET ativo=0 WHERE id IN ($idsTxt); UPDATE sub_setores SET ativo=0 WHERE setor_id=$id; COMMIT;"
        } else {
            $msg="Excluir definitivamente o Setor '$nome'"
            if($qtdSub -gt 0){$msg+=" e seus $qtdSub Sub_Setor(es)"}
            $msg+="? Esta acao nao pode ser desfeita."
            if(-not (Confirm-Action $msg)){return}
            Db-Exec "BEGIN IMMEDIATE; DELETE FROM assinaturas WHERE setor_id IN ($idsTxt); DELETE FROM sub_setores WHERE setor_id=$id; DELETE FROM setores WHERE id IN ($idsTxt); COMMIT;"
        }
        Load-Setores;Refresh-SetorCombos;Refresh-OcorrenciaFilterCombos
    } catch { Show-Error $_.Exception.Message }
}

function Delete-SubSetor {
    try {
        $id=Get-GridId $script:gridSubSetores
        if($id -le 0){Show-Info 'Selecione um Sub_Setor.';return}
        $idSql=Sql-Int $id 'sub_setor_id'
        $r=Db-Query "SELECT nome,setor_escala_id FROM sub_setores WHERE id=$idSql;"
        if($r.Rows.Count -eq 0){return}
        $nome=[string]$r.Rows[0]['nome']
        $unidadeId=$(if($r.Rows[0]['setor_escala_id'] -ne [DBNull]::Value){[int]$r.Rows[0]['setor_escala_id']}else{0})
        $unidadeIdSql=$(if($unidadeId -gt 0){Sql-Int $unidadeId 'setor_id'}else{'0'})
        $qtdEscalas=0;$qtdOc=0
        if($unidadeId -gt 0){
            $qtdEscalas=[int](Db-Scalar "SELECT COUNT(*) FROM escalas WHERE setor_id=$unidadeIdSql;")
            $qtdOc=[int](Db-Scalar "SELECT COUNT(*) FROM ocorrencias WHERE setor_id=$unidadeIdSql;")
        }
        if($qtdEscalas -gt 0 -or $qtdOc -gt 0){
            if(-not (Confirm-Action "O Sub_Setor '$nome' ja tem $qtdEscalas escala(s) e $qtdOc ocorrencia(s) cadastradas. Ele sera apenas DESATIVADO (o historico continua intacto). Continuar?")){return}
            $sqlSub="BEGIN IMMEDIATE; UPDATE sub_setores SET ativo=0 WHERE id=$idSql;";if($unidadeId -gt 0){$sqlSub+=" UPDATE setores SET ativo=0 WHERE id=$unidadeIdSql;"};$sqlSub+=' COMMIT;';Db-Exec $sqlSub
        } else {
            if(-not (Confirm-Action "Excluir definitivamente o Sub_Setor '$nome'? Esta acao nao pode ser desfeita.")){return}
            $sqlSub='BEGIN IMMEDIATE;';if($unidadeId -gt 0){$sqlSub+=" DELETE FROM assinaturas WHERE setor_id=$unidadeIdSql; DELETE FROM setores WHERE id=$unidadeIdSql;"};$sqlSub+=" DELETE FROM sub_setores WHERE id=$idSql; COMMIT;";Db-Exec $sqlSub
        }
        Load-SubSetores;Refresh-SetorCombos;Refresh-OcorrenciaFilterCombos
    } catch { Show-Error $_.Exception.Message }
}

function Load-Setores {
    try {
        $script:gridSetores.DataSource = Db-Query "SELECT id,nome AS Setor,total_leitos AS Leitos,chefia AS Chefia,coren_chefia AS Coren_Chefia FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=0 AND COALESCE(especial,0)=0 ORDER BY nome;"
        if($script:gridSetores.Columns.Contains('id')){$script:gridSetores.Columns['id'].Visible=$false}
        if($script:gridSetores.Columns.Contains('Setor')){$script:gridSetores.Columns['Setor'].AutoSizeMode='Fill'}
        Load-SubSetores
    } catch { Show-Error $_.Exception.Message }
}

function Load-SubSetores {
    try{
        if($null -eq $script:gridSubSetores){return}
        $sid=Get-GridId $script:gridSetores
        if($sid -le 0){$script:gridSubSetores.DataSource=$null;return}
        $script:gridSubSetores.DataSource=Db-Query ("SELECT id,nome AS Sub_Setor,COALESCE(leitos,0) AS Leitos,CASE WHEN possui_escala=1 THEN 'SIM' ELSE 'NAO' END AS Escala_Propria,CASE WHEN ativo=1 THEN 'SIM' ELSE 'NAO' END AS Ativo FROM sub_setores WHERE setor_id={0} ORDER BY nome;" -f $sid)
        if($script:gridSubSetores.Columns.Contains('id')){$script:gridSubSetores.Columns['id'].Visible=$false}
        if($script:gridSubSetores.Columns.Contains('Sub_Setor')){$script:gridSubSetores.Columns['Sub_Setor'].AutoSizeMode='Fill'}
    }catch{Show-Error $_.Exception.Message}
}

function Show-SetorDialog {
    param([int]$Id = 0)
    $data=$null
    if($Id -gt 0){$t=Db-Query "SELECT * FROM setores WHERE id=$Id AND COALESCE(unidade_escala,0)=0;";if($t.Rows.Count){$data=$t.Rows[0]}}
    $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=$(if($Id){'Editar Setor Principal'}else{'Novo Setor Principal'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(560,330);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false
    $fields=@('Nome','Total de Leitos','Chefia','Coren Chefia');$boxes=@{}
    for($i=0;$i -lt $fields.Count;$i++){$l=New-Object System.Windows.Forms.Label;$l.Text=$fields[$i];$l.Location=[System.Drawing.Point]::new(25,(30+$i*50));$l.Size=New-Object System.Drawing.Size(120,22);$f.Controls.Add($l);$tb=New-Object System.Windows.Forms.TextBox;$tb.Location=[System.Drawing.Point]::new(150,(27+$i*50));$tb.Size=New-Object System.Drawing.Size(370,25);$f.Controls.Add($tb);$boxes[$fields[$i]]=$tb}
    if($data){$boxes['Nome'].Text=[string]$data['nome'];$boxes['Total de Leitos'].Text=[string]$data['total_leitos'];$boxes['Chefia'].Text=[string]$data['chefia'];$boxes['Coren Chefia'].Text=[string]$data['coren_chefia']}
    $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(270,235);$cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(405,235);$cancel.DialogResult='Cancel'
    $ok.Add_Click({try{$nome=$boxes['Nome'].Text.Trim();if(-not $nome){Show-Info 'Informe o nome do setor.';return};$leitos=0;[int]::TryParse($boxes['Total de Leitos'].Text,[ref]$leitos)|Out-Null;if($Id){Db-Exec ("UPDATE setores SET nome={0},total_leitos={1},chefia={2},coren_chefia={3} WHERE id={4};" -f (Sql-Q $nome),$leitos,(Sql-Q ($boxes['Chefia'].Text.Trim())),(Sql-Q ($boxes['Coren Chefia'].Text.Trim())),$Id);Db-Exec ("UPDATE setores SET nome=(SELECT p.nome||' / '||ss.nome FROM setores p JOIN sub_setores ss ON ss.setor_id=p.id WHERE p.id={0} AND ss.id=setores.sub_setor_origem_id),chefia={2},coren_chefia={3} WHERE COALESCE(unidade_escala,0)=1 AND setor_pai_id={0};" -f $Id,$leitos,(Sql-Q ($boxes['Chefia'].Text.Trim())),(Sql-Q ($boxes['Coren Chefia'].Text.Trim())))}else{Db-Exec ("INSERT INTO setores(nome,total_leitos,chefia,coren_chefia,tipo_setor,especial,unidade_escala) VALUES ({0},{1},{2},{3},'ASSISTENCIAL',0,0);" -f (Sql-Q $nome),$leitos,(Sql-Q ($boxes['Chefia'].Text.Trim())),(Sql-Q ($boxes['Coren Chefia'].Text.Trim())))};$f.DialogResult='OK';$f.Close()}catch{Show-Error $_.Exception.Message}})
    $f.Controls.Add($ok);$f.Controls.Add($cancel)
    $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq 'OK'){Load-Setores;Refresh-SetorCombos;Refresh-OcorrenciaFilterCombos}
}

function Show-SubSetorDialog {
    param([int]$Id=0,[int]$SetorId=0)
    try{
        if($SetorId -le 0 -and $Id -gt 0){$SetorId=[int](Db-Scalar ("SELECT setor_id FROM sub_setores WHERE id={0};" -f $Id))}
        if($SetorId -le 0){Show-Info 'Selecione primeiro o Setor Principal.';return}
        $setNome=[string](Db-Scalar ("SELECT nome FROM setores WHERE id={0};" -f $SetorId))
        $data=$null;if($Id -gt 0){$t=Db-Query ("SELECT * FROM sub_setores WHERE id={0};" -f $Id);if($t.Rows.Count){$data=$t.Rows[0]}}
        $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=$(if($Id){'Editar Sub_Setor'}else{'Novo Sub_Setor'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(590,340);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false
        $l0=New-Object System.Windows.Forms.Label;$l0.Text='Setor Principal';$l0.Location=[Drawing.Point]::new(25,30);$l0.Size=[Drawing.Size]::new(130,22);$f.Controls.Add($l0)
        $tbSet=New-Object System.Windows.Forms.TextBox;$tbSet.Location=[Drawing.Point]::new(175,27);$tbSet.Size=[Drawing.Size]::new(365,25);$tbSet.Text=$setNome;$tbSet.ReadOnly=$true;$f.Controls.Add($tbSet)
        $l1=New-Object System.Windows.Forms.Label;$l1.Text='Nome do Sub_Setor';$l1.Location=[Drawing.Point]::new(25,80);$l1.Size=[Drawing.Size]::new(140,22);$f.Controls.Add($l1)
        $tbNome=New-Object System.Windows.Forms.TextBox;$tbNome.Location=[Drawing.Point]::new(175,77);$tbNome.Size=[Drawing.Size]::new(365,25);$f.Controls.Add($tbNome)
        $l2=New-Object System.Windows.Forms.Label;$l2.Text='Numero de Leitos';$l2.Location=[Drawing.Point]::new(25,130);$l2.Size=[Drawing.Size]::new(140,22);$f.Controls.Add($l2)
        $tbLeitos=New-Object System.Windows.Forms.TextBox;$tbLeitos.Location=[Drawing.Point]::new(175,127);$tbLeitos.Size=[Drawing.Size]::new(120,25);$f.Controls.Add($tbLeitos)
        $chk=New-Object System.Windows.Forms.CheckBox;$chk.Text='Possui Escala de Servico propria';$chk.Location=[Drawing.Point]::new(175,172);$chk.Size=[Drawing.Size]::new(300,26);$chk.Checked=$true;$f.Controls.Add($chk)
        $info=New-Object System.Windows.Forms.Label;$info.Text='Os leitos do Sub_Setor sao usados no cabecalho da sua escala e na pre-visualizacao.';$info.Location=[Drawing.Point]::new(175,205);$info.Size=[Drawing.Size]::new(365,38);$info.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$f.Controls.Add($info)
        if($data){$tbNome.Text=[string]$data['nome'];$tbLeitos.Text=[string]$data['leitos'];$chk.Checked=([int]$data['possui_escala'] -eq 1)}
        $ok=New-Button 'SALVAR' 120;$ok.Location=[Drawing.Point]::new(285,255);$cancel=New-Button 'CANCELAR' 120;$cancel.Location=[Drawing.Point]::new(420,255);$cancel.DialogResult='Cancel'
        $ok.Add_Click({
            try{
                $nome=$tbNome.Text.Trim();if(-not $nome){Show-Info 'Informe o nome do Sub_Setor.';return}
                $leitos=0;if($tbLeitos.Text.Trim() -and -not [int]::TryParse($tbLeitos.Text.Trim(),[ref]$leitos)){Show-Info 'Informe um numero de leitos valido.';return}
                if($leitos -lt 0){Show-Info 'O numero de leitos nao pode ser negativo.';return}
                $poss=$(if($chk.Checked){1}else{0})
                if($Id -gt 0){Db-Exec ("UPDATE sub_setores SET nome={0},leitos={1},possui_escala={2},ativo=1 WHERE id={3};" -f (Sql-Q $nome),$leitos,$poss,$Id)}
                else{Db-Exec ("INSERT INTO sub_setores(setor_id,nome,leitos,possui_escala,ativo) VALUES({0},{1},{2},{3},1);" -f $SetorId,(Sql-Q $nome),$leitos,$poss);$Id=[int](Db-Scalar ("SELECT id FROM sub_setores WHERE setor_id={0} AND nome={1} ORDER BY id DESC LIMIT 1;" -f $SetorId,(Sql-Q $nome)))}
                if($poss -eq 1){$unit=Ensure-SubSetorScaleSector $SetorId $Id;Db-Exec ("UPDATE setores SET nome={0},total_leitos={1} WHERE id={2};" -f (Sql-Q (("{0} / {1}" -f $setNome,$nome))),$leitos,$unit)}
                $f.DialogResult='OK';$f.Close()
            }catch{Show-Error $_.Exception.Message}
        })
        $f.Controls.Add($ok);$f.Controls.Add($cancel)
        $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){Load-SubSetores;Refresh-SetorCombos;Refresh-OcorrenciaFilterCombos}
    }catch{Show-Error $_.Exception.Message}
}

function Load-Siglas {
    try {
        $script:gridSiglas.DataSource = Db-Query "SELECT id, sigla AS Sigla, descricao AS Descricao, cor_fundo AS Fundo, cor_fonte AS Fonte, sigla AS Previa FROM siglas WHERE ativo=1 ORDER BY sigla;"
        if($script:gridSiglas.Columns.Contains('id')){$script:gridSiglas.Columns['id'].Visible=$false}
        if($script:gridSiglas.Columns.Contains('Descricao')){
            $script:gridSiglas.Columns['Descricao'].AutoSizeMode='Fill'
            $script:gridSiglas.Columns['Descricao'].MinimumWidth=260
        }
        if($script:gridSiglas.Columns.Contains('Sigla')){$script:gridSiglas.Columns['Sigla'].Width=82}
        if($script:gridSiglas.Columns.Contains('Fundo')){
            $script:gridSiglas.Columns['Fundo'].Width=135
            $script:gridSiglas.Columns['Fundo'].HeaderText='Cor do Fundo'
        }
        if($script:gridSiglas.Columns.Contains('Fonte')){
            $script:gridSiglas.Columns['Fonte'].Width=135
            $script:gridSiglas.Columns['Fonte'].HeaderText='Cor da Fonte'
        }
        if($script:gridSiglas.Columns.Contains('Previa')){
            $script:gridSiglas.Columns['Previa'].Width=105
            $script:gridSiglas.Columns['Previa'].HeaderText='Previa'
        }

        foreach($row in $script:gridSiglas.Rows){
            $fundoHex=[string]$row.Cells['Fundo'].Value
            $fonteHex=[string]$row.Cells['Fonte'].Value
            $fundo = Color-FromHex $fundoHex ([System.Drawing.Color]::White)
            $fonte = Color-FromHex $fonteHex ([System.Drawing.Color]::Black)

            # A coluna Fundo mostra o proprio codigo sobre a cor cadastrada.
            $row.Cells['Fundo'].Style.BackColor=$fundo
            $row.Cells['Fundo'].Style.ForeColor=Get-ContrastColor $fundo
            $row.Cells['Fundo'].Style.SelectionBackColor=$fundo
            $row.Cells['Fundo'].Style.SelectionForeColor=Get-ContrastColor $fundo
            $row.Cells['Fundo'].Style.Alignment='MiddleCenter'
            $row.Cells['Fundo'].ToolTipText=('Cor de fundo: {0}' -f $fundoHex)

            # A coluna Fonte tambem usa a propria cor cadastrada como amostra.
            $row.Cells['Fonte'].Style.BackColor=$fonte
            $row.Cells['Fonte'].Style.ForeColor=Get-ContrastColor $fonte
            $row.Cells['Fonte'].Style.SelectionBackColor=$fonte
            $row.Cells['Fonte'].Style.SelectionForeColor=Get-ContrastColor $fonte
            $row.Cells['Fonte'].Style.Alignment='MiddleCenter'
            $row.Cells['Fonte'].ToolTipText=('Cor da fonte: {0}' -f $fonteHex)

            # Previa real: fundo + fonte exatamente como aparecera na escala.
            $row.Cells['Previa'].Style.BackColor=$fundo
            $row.Cells['Previa'].Style.ForeColor=$fonte
            $row.Cells['Previa'].Style.SelectionBackColor=$fundo
            $row.Cells['Previa'].Style.SelectionForeColor=$fonte
            $row.Cells['Previa'].Style.Alignment='MiddleCenter'
            $row.Cells['Previa'].Style.Font=$script:FontSemibold9
            $row.Cells['Previa'].ToolTipText='Previa da sigla na escala'

            # Mantem a propria coluna Sigla neutra para facilitar leitura/listagem.
            $row.Cells['Sigla'].Style.Alignment='MiddleCenter'
            $row.Cells['Sigla'].Style.Font=$script:FontSemibold9
        }
        Load-SiglaCache
    } catch { Show-Error $_.Exception.Message }
}


function Remove-SiglaSelecionada {
    try{
        $id=Get-GridId $script:gridSiglas
        if(-not $id){
            Show-Info 'Selecione uma sigla para excluir.'
            return
        }

        $t=Db-Query "SELECT id,sigla,descricao FROM siglas WHERE id=$id AND ativo=1;"
        if($t.Rows.Count -eq 0){
            Show-Info 'A sigla selecionada nao existe mais ou ja foi removida.'
            Load-Siglas
            return
        }

        $sg=([string]$t.Rows[0]['sigla']).Trim().ToUpperInvariant()
        $desc=[string]$t.Rows[0]['descricao']

        # Siglas que fazem parte de regras estruturais do sistema.
        # Excluir qualquer uma delas poderia quebrar calendario automatico,
        # ocorrencias oficiais ou regras especiais de jornada.
        $protegidas=@('FF','FS','PF','PT','FER','AT')
        if($sg -in $protegidas){
            Show-Info ("A sigla '{0}' e estrutural do sistema e nao pode ser excluida.`r`n`r`nEla participa de regras automaticas da Escala." -f $sg)
            return
        }

        # Nao permitir exclusao fisica se houver uso historico ou funcional.
        # escala_dias guarda a sigla como texto, portanto apagar o cadastro
        # faria escalas antigas perderem legenda/cor/descritivo.
        $qDias=[int](Db-Scalar ("SELECT COUNT(*) FROM escala_dias WHERE UPPER(TRIM(COALESCE(sigla,'')))={0};" -f (Sql-Q $sg)))
        $qTipos=[int](Db-Scalar ("SELECT COUNT(*) FROM tipos_ocorrencia WHERE UPPER(TRIM(COALESCE(sigla,'')))={0};" -f (Sql-Q $sg)))

        if($qDias -gt 0 -or $qTipos -gt 0){
            $motivos=@()
            if($qDias -gt 0){$motivos+=("{0} lancamento(s) em escala_dias" -f $qDias)}
            if($qTipos -gt 0){$motivos+=("{0} tipo(s) de ocorrencia" -f $qTipos)}

            Show-Info (
                "A sigla '{0} - {1}' esta em uso e NAO sera excluida.`r`n`r`nUso encontrado:`r`n- {2}`r`n`r`nIsso protege escalas antigas, ocorrencias, cores e legenda de impressao." -f
                $sg,$desc,($motivos -join "`r`n- ")
            )
            return
        }

        if(-not (Confirm-Action ("Excluir definitivamente a sigla abaixo?`r`n`r`n{0} - {1}`r`n`r`nEla nao esta em uso nas escalas nem em tipos de ocorrencia." -f $sg,$desc))){
            return
        }

        if(-not (Confirm-Action ("CONFIRMACAO FINAL`r`n`r`nExcluir a sigla '{0}'?`r`n`r`nAntes da exclusao sera criado um backup obrigatorio do banco." -f $sg))){
            return
        }

        # Nenhuma exclusao destrutiva e feita sem backup valido.
        $backup=Backup-Database -Silencioso -Obrigatorio
        if([string]::IsNullOrWhiteSpace([string]$backup)){
            throw 'O backup obrigatorio nao foi criado. A sigla nao foi excluida.'
        }

        # Limpa a sigla da lista de menu rapido, se estiver presente.
        $quick=Get-ConfigValueAllowEmpty 'menu_siglas_rapidas' ''
        $quickNovo=@(
            ([string]$quick -split '[,;]') |
            ForEach-Object {$_.Trim().ToUpperInvariant()} |
            Where-Object {$_ -and $_ -ne $sg} |
            Select-Object -Unique
        ) -join ','

        $sql=@"
BEGIN IMMEDIATE;
DELETE FROM siglas
WHERE id=$id
  AND UPPER(TRIM(sigla))=$(Sql-Q $sg);

UPDATE configuracoes
SET valor=$(Sql-Q $quickNovo)
WHERE chave='menu_siglas_rapidas';
COMMIT;
"@
        Db-Exec $sql

        $restante=[int](Db-Scalar ("SELECT COUNT(*) FROM siglas WHERE id={0};" -f $id))
        if($restante -ne 0){
            throw 'A exclusao nao foi confirmada pelo banco.'
        }

        Clear-ConfigCache
        Load-Siglas
        if($null -ne $script:txtSiglasRapidas){
            $script:txtSiglasRapidas.Text=$quickNovo
        }

        Write-Log ("Sigla excluida com seguranca: {0} - {1}. Backup: {2}" -f $sg,$desc,$backup)
        Show-Info ("Sigla excluida com sucesso:`r`n`r`n{0} - {1}`r`n`r`nBackup criado antes da exclusao:`r`n{2}" -f $sg,$desc,$backup)
    }catch{
        # V1.0.14.77 - Removido o ROLLBACK vestigial: Db-Exec abre/fecha uma conexao NOVA a cada chamada,
        # entao a transacao com falha ja foi desfeita quando a conexao anterior fechou (comportamento padrao do
        # SQLite). Um ROLLBACK aqui rodaria numa conexao SEM transacao ativa e podia falhar, mascarando este erro.
        Show-Error $_.Exception.Message
    }
}

function Show-SiglaDialog {
    param([int]$Id=0)
    try{
        $data=$null
        if($Id){
            $t=Db-Query "SELECT * FROM siglas WHERE id=$Id;"
            if($t.Rows.Count){$data=$t.Rows[0]}
        }

        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text=$(if($Id){'Editar sigla'}else{'Nova sigla'})
        $f.StartPosition='CenterParent'
        $f.ClientSize=New-Object System.Drawing.Size(680,430)
        $f.FormBorderStyle='FixedDialog'
        $f.MaximizeBox=$false
        $f.MinimizeBox=$false

        $title=New-Object System.Windows.Forms.Label
        $title.Text='Configuracao visual da sigla'
        $title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12)
        $title.Location=[Drawing.Point]::new(24,18)
        $title.AutoSize=$true
        $f.Controls.Add($title)

        $info=New-Object System.Windows.Forms.Label
        $info.Text='Escolha as cores pela paleta. O codigo hexadecimal e salvo automaticamente para uso na tela e na impressao.'
        $info.Location=[Drawing.Point]::new(24,48)
        $info.Size=[Drawing.Size]::new(620,38)
        $info.ForeColor=[Drawing.Color]::FromArgb(71,85,105)
        $f.Controls.Add($info)

        $lSigla=New-Object System.Windows.Forms.Label
        $lSigla.Text='Sigla'
        $lSigla.Location=[Drawing.Point]::new(25,98)
        $lSigla.Size=[Drawing.Size]::new(120,22)
        $f.Controls.Add($lSigla)
        $tbSigla=New-Object System.Windows.Forms.TextBox
        $tbSigla.Location=[Drawing.Point]::new(165,95)
        $tbSigla.Size=[Drawing.Size]::new(130,26)
        $tbSigla.CharacterCasing='Upper'
        $f.Controls.Add($tbSigla)

        $lDesc=New-Object System.Windows.Forms.Label
        $lDesc.Text='Descricao'
        $lDesc.Location=[Drawing.Point]::new(25,140)
        $lDesc.Size=[Drawing.Size]::new(120,22)
        $f.Controls.Add($lDesc)
        $tbDesc=New-Object System.Windows.Forms.TextBox
        $tbDesc.Location=[Drawing.Point]::new(165,137)
        $tbDesc.Size=[Drawing.Size]::new(470,26)
        $f.Controls.Add($tbDesc)

        $lFundo=New-Object System.Windows.Forms.Label
        $lFundo.Text='Cor do Fundo'
        $lFundo.Location=[Drawing.Point]::new(25,191)
        $lFundo.Size=[Drawing.Size]::new(120,22)
        $f.Controls.Add($lFundo)

        $swFundo=New-Object System.Windows.Forms.Label
        $swFundo.Location=[Drawing.Point]::new(165,182)
        $swFundo.Size=[Drawing.Size]::new(54,34)
        $swFundo.BorderStyle='FixedSingle'
        $f.Controls.Add($swFundo)

        $tbFundo=New-Object System.Windows.Forms.TextBox
        $tbFundo.Location=[Drawing.Point]::new(230,187)
        $tbFundo.Size=[Drawing.Size]::new(120,26)
        $tbFundo.ReadOnly=$true
        $tbFundo.TextAlign='Center'
        $f.Controls.Add($tbFundo)

        $btnFundo=New-Button 'ESCOLHER COR' 145
        $btnFundo.Location=[Drawing.Point]::new(365,181)
        $f.Controls.Add($btnFundo)

        $lFonte=New-Object System.Windows.Forms.Label
        $lFonte.Text='Cor da Fonte'
        $lFonte.Location=[Drawing.Point]::new(25,240)
        $lFonte.Size=[Drawing.Size]::new(120,22)
        $f.Controls.Add($lFonte)

        $swFonte=New-Object System.Windows.Forms.Label
        $swFonte.Location=[Drawing.Point]::new(165,231)
        $swFonte.Size=[Drawing.Size]::new(54,34)
        $swFonte.BorderStyle='FixedSingle'
        $f.Controls.Add($swFonte)

        $tbFonte=New-Object System.Windows.Forms.TextBox
        $tbFonte.Location=[Drawing.Point]::new(230,236)
        $tbFonte.Size=[Drawing.Size]::new(120,26)
        $tbFonte.ReadOnly=$true
        $tbFonte.TextAlign='Center'
        $f.Controls.Add($tbFonte)

        $btnFonte=New-Button 'ESCOLHER COR' 145
        $btnFonte.Location=[Drawing.Point]::new(365,230)
        $f.Controls.Add($btnFonte)

        $lPrev=New-Object System.Windows.Forms.Label
        $lPrev.Text='Previa'
        $lPrev.Location=[Drawing.Point]::new(25,292)
        $lPrev.Size=[Drawing.Size]::new(120,22)
        $f.Controls.Add($lPrev)

        $prev=New-Object System.Windows.Forms.Label
        $prev.Location=[Drawing.Point]::new(165,278)
        $prev.Size=[Drawing.Size]::new(185,48)
        $prev.BorderStyle='FixedSingle'
        $prev.TextAlign='MiddleCenter'
        $prev.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12)
        $f.Controls.Add($prev)

        $btnPadrao=New-Button 'PRETO / BRANCO' 145
        $btnPadrao.Location=[Drawing.Point]::new(365,282)
        $f.Controls.Add($btnPadrao)

        $fundoHex=$(if($data -and $data['cor_fundo']){[string]$data['cor_fundo']}else{'#000000'})
        $fonteHex=$(if($data -and $data['cor_fonte']){[string]$data['cor_fonte']}else{'#FFFFFF'})
        if($data){
            $tbSigla.Text=[string]$data['sigla']
            $tbDesc.Text=[string]$data['descricao']
        }
        $tbFundo.Text=$fundoHex
        $tbFonte.Text=$fonteHex

        $updatePreview={
            $bg=Color-FromHex $tbFundo.Text ([Drawing.Color]::Black)
            $fg=Color-FromHex $tbFonte.Text ([Drawing.Color]::White)
            $swFundo.BackColor=$bg
            $swFonte.BackColor=$fg
            $swFundo.ForeColor=Get-ContrastColor $bg
            $swFonte.ForeColor=Get-ContrastColor $fg
            $prev.BackColor=$bg
            $prev.ForeColor=$fg
            $txt=$tbSigla.Text.Trim().ToUpper()
            if(-not $txt){$txt='SIGLA'}
            $prev.Text=$txt
        }

        $btnFundo.Add_Click({
            try{
                $cd=New-Object System.Windows.Forms.ColorDialog
                $cd.FullOpen=$true
                $cd.AnyColor=$true
                $cd.Color=Color-FromHex $tbFundo.Text ([Drawing.Color]::Black)
                if($cd.ShowDialog($f)-eq[System.Windows.Forms.DialogResult]::OK){
                    $tbFundo.Text=Color-ToHex $cd.Color
                    & $updatePreview
                }
                $cd.Dispose()
            }catch{Show-Error $_.Exception.Message}
        })
        $btnFonte.Add_Click({
            try{
                $cd=New-Object System.Windows.Forms.ColorDialog
                $cd.FullOpen=$true
                $cd.AnyColor=$true
                $cd.Color=Color-FromHex $tbFonte.Text ([Drawing.Color]::White)
                if($cd.ShowDialog($f)-eq[System.Windows.Forms.DialogResult]::OK){
                    $tbFonte.Text=Color-ToHex $cd.Color
                    & $updatePreview
                }
                $cd.Dispose()
            }catch{Show-Error $_.Exception.Message}
        })
        $btnPadrao.Add_Click({
            $tbFundo.Text='#000000'
            $tbFonte.Text='#FFFFFF'
            & $updatePreview
        })
        $tbSigla.Add_TextChanged({& $updatePreview})
        & $updatePreview

        $ok=New-Button 'SALVAR' 125
        $ok.Location=[Drawing.Point]::new(365,345)
        $cancel=New-Button 'CANCELAR' 125
        $cancel.Location=[Drawing.Point]::new(510,345)
        $cancel.DialogResult='Cancel'

        $ok.Add_Click({
            try{
                $sg=$tbSigla.Text.Trim().ToUpper()
                $desc=$tbDesc.Text.Trim()
                if(-not $sg -or -not $desc){Show-Info 'Informe a Sigla e a Descricao.';return}
                if($sg.Length -gt 12){Show-Info 'A sigla deve ter no maximo 12 caracteres.';return}
                $fundo=$tbFundo.Text.Trim()
                $fonte=$tbFonte.Text.Trim()
                # As cores vieram do ColorDialog; a conversao abaixo tambem valida qualquer valor restaurado do banco.
                $null=Color-FromHex $fundo ([Drawing.Color]::Black)
                $null=Color-FromHex $fonte ([Drawing.Color]::White)
                if($Id){
                    Db-Exec ("UPDATE siglas SET sigla={0},descricao={1},cor_fundo={2},cor_fonte={3} WHERE id={4};" -f (Sql-Q $sg),(Sql-Q $desc),(Sql-Q $fundo),(Sql-Q $fonte),$Id)
                }else{
                    Db-Exec ("INSERT INTO siglas(sigla,descricao,cor_fundo,cor_fonte) VALUES ({0},{1},{2},{3});" -f (Sql-Q $sg),(Sql-Q $desc),(Sql-Q $fundo),(Sql-Q $fonte))
                }
                $f.DialogResult='OK'
                $f.Close()
            }catch{
                if($_.Exception.Message -match 'UNIQUE'){
                    Show-Info 'Ja existe uma sigla com esse codigo.'
                }else{
                    Show-Error $_.Exception.Message
                }
            }
        })
        $f.Controls.Add($ok)
        $f.Controls.Add($cancel)

        $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){
            Load-Siglas
            Load-Escala
        }
    }catch{Show-Error $_.Exception.Message}
}

function Load-Horarios {
    try {
        $t = Db-Query "SELECT id, ordem AS Ordem, nome AS Nome, periodo AS Periodo, descricao AS Cabecalho, CASE WHEN COALESCE(auto_calendario_08h,0)=1 THEN 'SIM' ELSE 'NAO' END AS Calendario_08h, CASE WHEN ativo=1 THEN 'SIM' ELSE 'NAO' END AS Ativo FROM horarios ORDER BY ordem,nome;"
        $script:gridHorarios.DataSource = $t
        if($script:gridHorarios.Columns.Contains('id')){$script:gridHorarios.Columns['id'].Visible=$false}
        if($script:gridHorarios.Columns.Contains('Ordem')){$script:gridHorarios.Columns['Ordem'].Width=70}
        if($script:gridHorarios.Columns.Contains('Nome')){
            $script:gridHorarios.Columns['Nome'].Width=230
            $script:gridHorarios.Columns['Nome'].DefaultCellStyle.WrapMode='True'
        }
        if($script:gridHorarios.Columns.Contains('Periodo')){$script:gridHorarios.Columns['Periodo'].Width=90}
        if($script:gridHorarios.Columns.Contains('Cabecalho')){
            $script:gridHorarios.Columns['Cabecalho'].AutoSizeMode='Fill'
            $script:gridHorarios.Columns['Cabecalho'].MinimumWidth=420
            $script:gridHorarios.Columns['Cabecalho'].DefaultCellStyle.WrapMode='True'
        }
        if($script:gridHorarios.Columns.Contains('Calendario_08h')){$script:gridHorarios.Columns['Calendario_08h'].HeaderText='Auto 08h';$script:gridHorarios.Columns['Calendario_08h'].Width=85}
        if($script:gridHorarios.Columns.Contains('Ativo')){$script:gridHorarios.Columns['Ativo'].Width=70}
        $script:gridHorarios.AutoSizeRowsMode='AllCells'
        if($null -ne $script:lblHorarioCount){$script:lblHorarioCount.Text=('{0} horario(s) cadastrado(s)' -f $script:gridHorarios.Rows.Count)}
    } catch { Show-Error $_.Exception.Message }
}

function Show-HorarioDialog {
    param([int]$Id=0,[int]$CopiarDe=0)
    try {
        $data=$null
        $origemId=$(if($Id -gt 0){$Id}else{$CopiarDe})
        if($origemId -gt 0){$t=Db-Query "SELECT * FROM horarios WHERE id=$origemId;";if($t.Rows.Count){$data=$t.Rows[0]}}

        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text=$(if($Id -gt 0){'Editar horario'}elseif($CopiarDe -gt 0){'Duplicar horario'}else{'Novo horario'})
        $f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(790,470);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false;$f.AutoScaleMode='Dpi'

        $lNome=New-Object System.Windows.Forms.Label;$lNome.Text='Nome do bloco';$lNome.Location=New-Object System.Drawing.Point(22,28);$lNome.Size=New-Object System.Drawing.Size(140,22);$f.Controls.Add($lNome)
        $tbNome=New-Object System.Windows.Forms.TextBox;$tbNome.Location=New-Object System.Drawing.Point(170,25);$tbNome.Size=New-Object System.Drawing.Size(575,25);$f.Controls.Add($tbNome)

        $lPer=New-Object System.Windows.Forms.Label;$lPer.Text='Periodo';$lPer.Location=New-Object System.Drawing.Point(22,73);$lPer.Size=New-Object System.Drawing.Size(140,22);$f.Controls.Add($lPer)
        $cbPer=New-Object System.Windows.Forms.ComboBox;$cbPer.Location=New-Object System.Drawing.Point(170,70);$cbPer.Size=New-Object System.Drawing.Size(180,26);$cbPer.DropDownStyle='DropDownList';[void]$cbPer.Items.AddRange(@('M - Matutino','V - Vespertino','D - Diurno','N - Noturno','INT - Integral'));$cbPer.SelectedIndex=0;$f.Controls.Add($cbPer)

        $lOrd=New-Object System.Windows.Forms.Label;$lOrd.Text='Ordem de impressao';$lOrd.Location=New-Object System.Drawing.Point(390,73);$lOrd.Size=New-Object System.Drawing.Size(145,22);$f.Controls.Add($lOrd)
        $numOrd=New-Object System.Windows.Forms.NumericUpDown;$numOrd.Location=New-Object System.Drawing.Point(545,70);$numOrd.Size=New-Object System.Drawing.Size(90,25);$numOrd.Minimum=1;$numOrd.Maximum=999;$numOrd.Value=1;$f.Controls.Add($numOrd)
        $chkAt=New-Object System.Windows.Forms.CheckBox;$chkAt.Text='Ativo';$chkAt.Location=New-Object System.Drawing.Point(655,72);$chkAt.Size=New-Object System.Drawing.Size(90,24);$chkAt.Checked=$true;$f.Controls.Add($chkAt)
        $chkAuto08=New-Object System.Windows.Forms.CheckBox;$chkAuto08.Text='Jornada 08h: aplicar automaticamente FF/PF nos eventos e FS aos sabados/domingos';$chkAuto08.Location=New-Object System.Drawing.Point(170,108);$chkAuto08.Size=New-Object System.Drawing.Size(575,26);$chkAuto08.Checked=$false;$f.Controls.Add($chkAuto08)
        $tipAuto08=New-Object System.Windows.Forms.ToolTip;$tipAuto08.SetToolTip($chkAuto08,'Use este marcador explicito para jornadas administrativas de 08h. O sistema nao depende mais da palavra 08H no nome/cabecalho.')

        $lDesc=New-Object System.Windows.Forms.Label;$lDesc.Text='Cabecalho completo que aparecera na escala/impressao';$lDesc.Location=New-Object System.Drawing.Point(22,145);$lDesc.Size=New-Object System.Drawing.Size(400,22);$f.Controls.Add($lDesc)
        $tbDesc=New-Object System.Windows.Forms.TextBox;$tbDesc.Location=New-Object System.Drawing.Point(22,170);$tbDesc.Size=New-Object System.Drawing.Size(723,95);$tbDesc.Multiline=$true;$tbDesc.ScrollBars='Vertical';$f.Controls.Add($tbDesc)
        $lDescInfo=New-Object System.Windows.Forms.Label;$lDescInfo.Text='Se o bloco tiver paridade (PAR/IMPAR), escreva a palavra aqui dentro do cabecalho (ex.: "FS IMPAR"). O sistema usa essa palavra para calcular os dias e sempre a mantem correta mes a mes.';$lDescInfo.Location=New-Object System.Drawing.Point(22,268);$lDescInfo.Size=New-Object System.Drawing.Size(723,38);$lDescInfo.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105);$f.Controls.Add($lDescInfo)

        $grp=New-Object System.Windows.Forms.GroupBox;$grp.Text='Previa do cabecalho';$grp.Location=New-Object System.Drawing.Point(22,308);$grp.Size=New-Object System.Drawing.Size(723,75);$f.Controls.Add($grp)
        $lblPrev=New-Object System.Windows.Forms.Label;$lblPrev.Dock='Fill';$lblPrev.TextAlign='MiddleCenter';$lblPrev.Font=$script:FontSemibold9;$lblPrev.BackColor=[System.Drawing.Color]::FromArgb(225,225,225);$grp.Controls.Add($lblPrev)
        $updatePreview={ $lblPrev.Text=$(if([string]::IsNullOrWhiteSpace($tbDesc.Text)){'Digite o cabecalho completo acima.'}else{$tbDesc.Text}) }
        $tbDesc.Add_TextChanged($updatePreview)

        if($data){
            $tbNome.Text=[string]$data['nome'];$tbDesc.Text=[string]$data['descricao']
            $per=[string]$data['periodo'];for($i=0;$i -lt $cbPer.Items.Count;$i++){if(([string]$cbPer.Items[$i]).StartsWith($per+' ')-or ([string]$cbPer.Items[$i]).StartsWith($per+' -')){$cbPer.SelectedIndex=$i;break}}
            if([int]$data['ordem'] -gt 0){$numOrd.Value=[int]$data['ordem']}
            $chkAt.Checked=([string]$data['ativo'] -ne '0')
            try{$chkAuto08.Checked=([int]$data['auto_calendario_08h'] -eq 1)}catch{$chkAuto08.Checked=$false}
            if($CopiarDe -gt 0){$tbNome.Text=$tbNome.Text+' - COPIA';$tbDesc.Text=$tbDesc.Text+' - COPIA';$chkAt.Checked=$true}
        } else {
            $next=Db-Scalar "SELECT COALESCE(MAX(ordem),0)+1 FROM horarios;";if($next){$numOrd.Value=[int]$next}
        }
        & $updatePreview

        $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(480,405);Set-PrimaryButton $ok
        $cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(615,405);$cancel.DialogResult='Cancel'
        $ok.Add_Click({
            try{
                $nome=$tbNome.Text.Trim();$desc=$tbDesc.Text.Trim();if(-not $nome -or -not $desc){Show-Info 'Informe o Nome do bloco e o Cabecalho completo.';return}
                $perText=[string]$cbPer.SelectedItem;$per=$perText.Split(' ')[0].Trim()
                $ord=[int]$numOrd.Value;$ativo=$(if($chkAt.Checked){1}else{0});$auto08=$(if($chkAuto08.Checked){1}else{0})
                if($Id -gt 0){
                    Db-Exec ("UPDATE horarios SET nome={0},periodo={1},descricao={2},ordem={3},ativo={4},auto_calendario_08h={5} WHERE id={6};" -f (Sql-Q $nome),(Sql-Q $per),(Sql-Q $desc),$ord,$ativo,$auto08,$Id)
                } else {
                    Db-Exec ("INSERT INTO horarios(nome,periodo,descricao,ativo,ordem,auto_calendario_08h) VALUES ({0},{1},{2},{3},{4},{5});" -f (Sql-Q $nome),(Sql-Q $per),(Sql-Q $desc),$ativo,$ord,$auto08)
                }
                $f.DialogResult='OK';$f.Close()
            }catch{Show-Error $_.Exception.Message}
        })
        $f.Controls.Add($ok);$f.Controls.Add($cancel);$ok.BringToFront();$cancel.BringToFront();$f.AcceptButton=$ok;$f.CancelButton=$cancel
        $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){Load-Horarios;Load-Escala}
    } catch { Show-Error $_.Exception.Message }
}

function Toggle-HorarioAtivo {
    $id=Get-GridId $script:gridHorarios
    if($id -le 0){Show-Info 'Selecione um horario.';return}
    try{
        $at=Db-Scalar "SELECT ativo FROM horarios WHERE id=$id;"
        $novo=$(if([int]$at -eq 1){0}else{1})
        # V1.0.14.18 - Desativar um horario que ja esta em uso em alguma escala
        # ativa (servidores ou Escala Vaga vinculados) fazia o bloco sumir
        # silenciosamente das listas de + SERVIDOR / ESCALA VAGA / CONFIGURAR
        # BLOCOS, sem nenhum aviso. Agora confirma antes, informando quantas
        # escalas usam esse horario.
        if($novo -eq 0){
            $usoServ=[int](Db-Scalar "SELECT COUNT(DISTINCT es.escala_id) FROM escala_servidores es WHERE es.horario_id=$id AND es.ativo=1;")
            $usoVaga=[int](Db-Scalar "SELECT COUNT(DISTINCT v.escala_id) FROM escala_vagas v WHERE v.horario_id=$id AND v.ativo=1;")
            if($usoServ -gt 0 -or $usoVaga -gt 0){
                $qtdEscalas=[int](Db-Scalar ("SELECT COUNT(DISTINCT escala_id) FROM (SELECT escala_id FROM escala_servidores WHERE horario_id={0} AND ativo=1 UNION SELECT escala_id FROM escala_vagas WHERE horario_id={0} AND ativo=1);" -f $id))
                $msg=('Este horario esta em uso em {0} escala(s) mensal(is) (servidores e/ou Escala Vaga vinculados). Desativar impede incluir NOVOS servidores/vagas nele, mas nao remove quem ja esta la. Deseja continuar?' -f $qtdEscalas)
                if(-not (Confirm-Action $msg)){return}
            }
        }
        Db-Exec "UPDATE horarios SET ativo=$novo WHERE id=$id;"
        Load-Horarios
    }catch{Show-Error $_.Exception.Message}
}

function Duplicar-Horario {
    $id=Get-GridId $script:gridHorarios
    if($id -le 0){Show-Info 'Selecione o horario que deseja duplicar.';return}
    Show-HorarioDialog 0 $id
}

function Get-SelectedSetorId {
    try{
        $principal=Get-SelectedPrincipalSetorId
        $sub=Get-SelectedSubSetorId
        if($principal -le 0){return 0}
        if($sub -gt 0){return [int](Ensure-SubSetorScaleSector $principal $sub)}
        return $principal
    }catch{return 0}
}

function Get-ScaleId {
    $sid=Get-SelectedSetorId;if($sid -le 0){return 0};$ano=[int]$script:numAno.Value;$mes=[int]$script:cboMes.SelectedValue
    $v=Db-Scalar "SELECT id FROM escalas WHERE setor_id=$sid AND ano=$ano AND mes=$mes;"
    if($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)){return 0};return [int]$v
}

function Create-CurrentScale {
    try {
        $sid=Get-SelectedSetorId
        if($sid -le 0){
            Show-Info 'PASSO 1: selecione primeiro o Setor e, quando houver, o Sub_Setor.'
            $tabs.SelectedTab=$tabSet
            return
        }

        $horAtivos=[int](Db-Scalar "SELECT COUNT(*) FROM horarios WHERE ativo=1;")
        if($horAtivos -le 0){
            Show-Info 'PASSO 2: cadastre pelo menos um Horario antes de criar a escala mensal.'
            $tabs.SelectedTab=$tabHor
            return
        }

        $ano=[int]$script:numAno.Value
        $mes=[int]$script:cboMes.SelectedValue
        $existente=[int](Get-ScaleId)
        if($existente -gt 0){
            $script:CurrentScaleId=$existente
            Load-Escala
            if((Get-ScaleBlockCount $existente) -le 0){
                Show-Info 'A escala deste mes ja existe. Agora configure os blocos de horario antes de incluir servidores.'
                Show-ScaleBlocksManager
            } else {
                Show-Info 'Esta escala ja existe e foi carregada.'
            }
            return
        }

        $s=Db-Query "SELECT chefia,total_leitos FROM setores WHERE id=$sid;"
        $chef=''
        $leit=0
        if($s.Rows.Count){
            $chef=[string]$s.Rows[0]['chefia']
            if($s.Rows[0]['total_leitos'] -ne [DBNull]::Value){$leit=[int]$s.Rows[0]['total_leitos']}
        }

        # V1.0.14.36 - decide a copia ANTES de criar a escala e depois grava
        # escala + blocos + servidores em uma unica transacao. Uma falha no meio
        # nao deixa mais um mes parcialmente criado.
        $prev=Db-Scalar "SELECT id FROM escalas WHERE setor_id=$sid AND (ano<$ano OR (ano=$ano AND mes<$mes)) ORDER BY ano DESC,mes DESC LIMIT 1;"
        $copiar=$false
        if($prev){
            $modoCopia=(Get-ConfigValue 'criar_mes_copiar_anterior' 'PERGUNTAR').ToUpperInvariant()
            if($modoCopia -eq 'SIM'){$copiar=$true}
            elseif($modoCopia -eq 'PERGUNTAR'){
                $copiar=Confirm-Action 'Deseja copiar os blocos de horario e os servidores da escala anterior? Ocorrencias e dias nao serao copiados.'
            }
        }

        $sqlCreate=New-Object System.Text.StringBuilder
        [void]$sqlCreate.AppendLine('BEGIN IMMEDIATE;')
        [void]$sqlCreate.AppendLine(("INSERT INTO escalas(setor_id,ano,mes,chefia,total_leitos) VALUES ({0},{1},{2},{3},{4});" -f $sid,$ano,$mes,(Sql-Q $chef),$leit))
        if($prev -and $copiar){
            $newExpr=("(SELECT id FROM escalas WHERE setor_id={0} AND ano={1} AND mes={2})" -f $sid,$ano,$mes)
            [void]$sqlCreate.AppendLine(("INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem) SELECT {0},horario_id,ordem FROM escala_blocos_ordem WHERE escala_id={1};" -f $newExpr,[int]$prev))
            [void]$sqlCreate.AppendLine(("INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem) SELECT {0},x.horario_id,COALESCE(h.ordem,x.horario_id) FROM (SELECT horario_id FROM escala_servidores WHERE escala_id={1} AND ativo=1 AND horario_id IS NOT NULL UNION SELECT horario_id FROM escala_vagas WHERE escala_id={1} AND ativo=1 AND horario_id IS NOT NULL) x JOIN horarios h ON h.id=x.horario_id;" -f $newExpr,[int]$prev))
            [void]$sqlCreate.AppendLine(("INSERT OR IGNORE INTO escala_servidores(escala_id,servidor_id,horario_id,ordem) SELECT {0},es.servidor_id,es.horario_id,es.ordem FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id={1} AND es.ativo=1 AND s.ativo=1;" -f $newExpr,[int]$prev))
        }
        [void]$sqlCreate.AppendLine('COMMIT;')
        Db-Exec $sqlCreate.ToString()

        $newId=[int](Get-ScaleId)
        if($newId -le 0){throw 'A escala mensal nao foi localizada apos a gravacao.'}
        $script:CurrentScaleId=$newId

        $ignorados=0
        if($prev -and $copiar){
            $elegiveis=[int](Db-Scalar ("SELECT COUNT(*) FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id={0} AND es.ativo=1 AND s.ativo=1;" -f [int]$prev))
            $copiados=[int](Db-Scalar ("SELECT COUNT(*) FROM escala_servidores WHERE escala_id={0} AND ativo=1;" -f $newId))
            $ignorados=[math]::Max(0,$elegiveis-$copiados)
            if($ignorados -gt 0){
                Write-Log ("Copia de mes: {0} servidor(es) nao foram copiados por regra de unicidade/lotacao no mesmo mes." -f $ignorados)
            }
        }

        Write-Log "Escala criada: setor=$sid ano=$ano mes=$mes fluxo_guiado=1"
        Load-Escala

        if((Get-ScaleBlockCount $newId) -le 0){
            Show-Info 'PASSO 3 concluido. Agora configure os BLOCOS DE HORARIO desta escala antes de incluir servidores.'
            Show-ScaleBlocksManager
        } else {
            $msg='Escala criada. Os blocos do mes anterior foram carregados. Confira os blocos antes de continuar.'
            if($ignorados -gt 0){$msg += ("`r`n`r`nATENCAO: {0} servidor(es) do mes anterior nao foram copiados porque ja existe lotacao conflitante no mes atual." -f $ignorados)}
            Show-Info $msg
        }
    } catch {
        Write-Log ('Falha ao criar escala mensal: ' + $_.Exception.Message)
        Show-Error $_.Exception.Message
    }
}

function Get-TextSha256 {
    param([string]$Text)
    $sha=[System.Security.Cryptography.SHA256]::Create()
    try{
        $bytes=[System.Text.Encoding]::UTF8.GetBytes($(if($null -eq $Text){''}else{$Text}))
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    }finally{$sha.Dispose()}
}

function Get-OccurrenceSyncSignature {
    param([int]$ScaleId)
    if($ScaleId -le 0){return ''}
    $st=Db-Query "SELECT setor_id,ano,mes FROM escalas WHERE id=$ScaleId;"
    if($st.Rows.Count -eq 0){return ''}
    $sid=[int]$st.Rows[0]['setor_id'];$ano=[int]$st.Rows[0]['ano'];$mes=[int]$st.Rows[0]['mes']
    $first=(Get-Date -Year $ano -Month $mes -Day 1).ToString('yyyy-MM-dd')
    $last=(Get-Date -Year $ano -Month $mes -Day 1).AddMonths(1).AddDays(-1).ToString('yyyy-MM-dd')
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("S|$ScaleId|$sid|$first|$last")
    $src=Db-Query @"
SELECT o.id,o.setor_id,o.servidor_id,o.tipo_id,o.data_inicial,o.data_final,o.situacao,COALESCE(o.texto_escala,'') AS texto_escala,
       COALESCE(t.sigla,'') AS sigla,t.gera_escala,es.id AS esid
FROM ocorrencias o
JOIN tipos_ocorrencia t ON t.id=o.tipo_id
JOIN escala_servidores es ON es.servidor_id=o.servidor_id AND es.escala_id=$ScaleId AND es.ativo=1
WHERE o.situacao='ATIVA' AND t.gera_escala=1 AND COALESCE(t.sigla,'')<>''
  AND substr(o.data_final,1,10)>='$first' AND substr(o.data_inicial,1,10)<='$last'
ORDER BY o.id,es.id;
"@
    foreach($r in $src.Rows){[void]$sb.AppendLine(('O|{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}|{10}' -f $r['id'],$r['setor_id'],$r['servidor_id'],$r['tipo_id'],$r['data_inicial'],$r['data_final'],$r['situacao'],$r['texto_escala'],$r['sigla'],$r['gera_escala'],$r['esid']))}
    $dst=Db-Query "SELECT ed.escala_servidor_id,ed.data,COALESCE(ed.sigla,'') AS sigla,COALESCE(ed.texto,'') AS texto,COALESCE(ed.ocorrencia_id,0) AS ocorrencia_id FROM escala_dias ed JOIN escala_servidores es ON es.id=ed.escala_servidor_id WHERE es.escala_id=$ScaleId AND ed.origem='OCORRENCIA' AND ed.data BETWEEN '$first' AND '$last' ORDER BY ed.escala_servidor_id,ed.data;"
    foreach($r in $dst.Rows){[void]$sb.AppendLine(('D|{0}|{1}|{2}|{3}|{4}' -f $r['escala_servidor_id'],$r['data'],$r['sigla'],$r['texto'],$r['ocorrencia_id']))}
    return Get-TextSha256 $sb.ToString()
}

function Get-Calendar08hSyncSignature {
    param([int]$ScaleId)
    if($ScaleId -le 0){return ''}
    $esc=Db-Query "SELECT ano,mes FROM escalas WHERE id=$ScaleId;"
    if($esc.Rows.Count -eq 0){return ''}
    $ano=[int]$esc.Rows[0]['ano'];$mes=[int]$esc.Rows[0]['mes']
    $autoFFPF=Get-ConfigBool '08h_auto_ff_pf' $true
    $autoFS=Get-ConfigBool '08h_auto_fs' $true
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.AppendLine(('C|{0}|{1}|{2}|{3}|{4}' -f $ScaleId,$ano,$mes,$autoFFPF,$autoFS))
    $eventos=Db-Query ("SELECT data,COALESCE(tipo,'FERIADO') AS tipo,COALESCE(descricao,'') AS descricao FROM feriados WHERE data LIKE {0} ORDER BY data;" -f (Sql-Q ('{0}-{1:00}-%' -f $ano,$mes)))
    foreach($r in $eventos.Rows){[void]$sb.AppendLine(('F|{0}|{1}|{2}' -f $r['data'],$r['tipo'],$r['descricao']))}
    $sv=Db-Query "SELECT es.id AS esid,COALESCE(h.auto_calendario_08h,0) AS auto08,h.ativo FROM escala_servidores es JOIN horarios h ON h.id=es.horario_id WHERE es.escala_id=$ScaleId AND es.ativo=1 ORDER BY es.id;"
    foreach($r in $sv.Rows){[void]$sb.AppendLine(('H|{0}|{1}|{2}' -f $r['esid'],$r['auto08'],$r['ativo']))}
    $dst=Db-Query "SELECT ed.escala_servidor_id,ed.data,COALESCE(ed.sigla,'') AS sigla,ed.origem FROM escala_dias ed JOIN escala_servidores es ON es.id=ed.escala_servidor_id WHERE es.escala_id=$ScaleId AND ed.origem IN ('CALENDARIO_FERIADO','CALENDARIO_PF','CALENDARIO_FS_08H') ORDER BY ed.escala_servidor_id,ed.data,ed.origem;"
    foreach($r in $dst.Rows){[void]$sb.AppendLine(('A|{0}|{1}|{2}|{3}' -f $r['escala_servidor_id'],$r['data'],$r['sigla'],$r['origem']))}
    # V1.0.14.37 - o calendario automatico so ocupa dias LIVRES. Portanto a assinatura precisa enxergar
    # tambem as linhas MANUAL/OCORRENCIA dos servidores 08h: quando uma delas some (dia limpo, ocorrencia
    # excluida ou encurtada), o dia volta a ficar livre e FS/FF/PF precisam ser regenerados.
    $ocup=Db-Query "SELECT ed.escala_servidor_id,ed.data,ed.origem FROM escala_dias ed JOIN escala_servidores es ON es.id=ed.escala_servidor_id JOIN horarios h ON h.id=es.horario_id WHERE es.escala_id=$ScaleId AND es.ativo=1 AND COALESCE(h.auto_calendario_08h,0)=1 AND ed.origem NOT IN ('CALENDARIO_FERIADO','CALENDARIO_PF','CALENDARIO_FS_08H') ORDER BY ed.escala_servidor_id,ed.data,ed.origem;"
    foreach($r in $ocup.Rows){[void]$sb.AppendLine(('P|{0}|{1}|{2}' -f $r['escala_servidor_id'],$r['data'],$r['origem']))}
    return Get-TextSha256 $sb.ToString()
}

function Ensure-OccurrenceSyncForScale {
    param([int]$ScaleId,[switch]$Force)
    if($ScaleId -le 0){return $false}
    try{
        $sig=Get-OccurrenceSyncSignature $ScaleId
        $key=[string]$ScaleId
        if((-not $Force) -and $script:SyncSignatureOcc.ContainsKey($key) -and [string]$script:SyncSignatureOcc[$key] -eq $sig){return $true}
        $ok=[bool](Sync-OccurrencesForScale $ScaleId)
        if($ok){$script:SyncSignatureOcc[$key]=Get-OccurrenceSyncSignature $ScaleId}
        return $ok
    }catch{Write-Log ('Falha ao verificar necessidade de sync de ocorrencias: '+$_.Exception.Message);return $false}
}

function Ensure-Calendar08hSyncForScale {
    param([int]$ScaleId,[switch]$Force)
    if($ScaleId -le 0){return $false}
    try{
        $sig=Get-Calendar08hSyncSignature $ScaleId
        $key=[string]$ScaleId
        if((-not $Force) -and $script:SyncSignatureCal.ContainsKey($key) -and [string]$script:SyncSignatureCal[$key] -eq $sig){return $true}
        $ok=[bool](Sync-Calendario08hForScale $ScaleId)
        if($ok){$script:SyncSignatureCal[$key]=Get-Calendar08hSyncSignature $ScaleId}
        return $ok
    }catch{Write-Log ('Falha ao verificar necessidade de sync do calendario 08h: '+$_.Exception.Message);return $false}
}

function Sync-OccurrencesForScale {
    param([int]$ScaleId)
    if($ScaleId -le 0){return $false}
    $sw=[System.Diagnostics.Stopwatch]::StartNew()
    $ok=$false
    try {
        $st=Db-Query "SELECT setor_id,ano,mes FROM escalas WHERE id=$ScaleId;"
        if($st.Rows.Count -eq 0){
            Write-Log ("Falha sincronizacao em lote: escala nao encontrada id={0}" -f $ScaleId)
            return $false
        }
        $sid=[int]$st.Rows[0]['setor_id'];$ano=[int]$st.Rows[0]['ano'];$mes=[int]$st.Rows[0]['mes']
        $first=(Get-Date -Year $ano -Month $mes -Day 1).ToString('yyyy-MM-dd')
        $last=(Get-Date -Year $ano -Month $mes -Day 1).AddMonths(1).AddDays(-1).ToString('yyyy-MM-dd')

        # Sincronizacao em lote numa unica conexao/transacao.
        $sql=@"
BEGIN IMMEDIATE;
DELETE FROM escala_dias
 WHERE origem='OCORRENCIA'
   AND escala_servidor_id IN (
       SELECT id FROM escala_servidores WHERE escala_id=$ScaleId AND ativo=1
   )
   AND data BETWEEN '$first' AND '$last';

WITH RECURSIVE occ_days(esid, ocorrencia_id, sigla, texto, dia, fim) AS (
    SELECT es.id,
           o.id,
           t.sigla,
           COALESCE(NULLIF(o.texto_escala,''),t.sigla),
           CASE WHEN substr(o.data_inicial,1,10) < '$first' THEN '$first' ELSE substr(o.data_inicial,1,10) END,
           CASE WHEN substr(o.data_final,1,10) > '$last' THEN '$last' ELSE substr(o.data_final,1,10) END
      FROM ocorrencias o
      JOIN tipos_ocorrencia t ON t.id=o.tipo_id
      JOIN escala_servidores es
        ON es.servidor_id=o.servidor_id
       AND es.escala_id=$ScaleId
       AND es.ativo=1
     WHERE o.situacao='ATIVA'
       AND t.gera_escala=1
       AND COALESCE(t.sigla,'')<>''
       AND substr(o.data_final,1,10)>='$first'
       AND substr(o.data_inicial,1,10)<='$last'
    UNION ALL
    SELECT esid,ocorrencia_id,sigla,texto,date(dia,'+1 day'),fim
      FROM occ_days
     WHERE dia < fim
)
INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem,ocorrencia_id)
SELECT esid,dia,sigla,texto,'OCORRENCIA',ocorrencia_id
  FROM occ_days
 WHERE dia<=fim
ON CONFLICT(escala_servidor_id,data) DO UPDATE SET
    sigla=excluded.sigla,
    texto=excluded.texto,
    origem='OCORRENCIA',
    ocorrencia_id=excluded.ocorrencia_id,
    atualizado_em=CURRENT_TIMESTAMP
WHERE escala_dias.origem<>'MANUAL';
COMMIT;
"@
        Db-Exec $sql
        $ok=$true
        return $true
    } catch {
        Write-Log ('Falha sincronizacao em lote: '+$_.Exception.Message)
        return $false
    } finally {
        $sw.Stop();Write-Log (("Sync ocorrencias escala={0}: {1} ms; sucesso={2}" -f $ScaleId,$sw.ElapsedMilliseconds,$ok))
    }
}

function Get-FuncaoExibicao {
    param([string]$Funcao,[string]$Vinculo,[string]$SubFuncao)
    $partes=New-Object System.Collections.ArrayList
    foreach($valor in @($Funcao,$Vinculo,$SubFuncao)){
        if([string]::IsNullOrWhiteSpace([string]$valor)){continue}
        $texto=([string]$valor).Trim().ToUpperInvariant()
        foreach($pedaco in ($texto -split '[/\-]')){
            $item=$pedaco.Trim()
            if([string]::IsNullOrWhiteSpace($item)){continue}
            $existe=$false
            foreach($atual in $partes){if(([string]$atual).ToUpperInvariant() -eq $item){$existe=$true;break}}
            if(-not $existe){[void]$partes.Add($item)}
        }
    }
    return ($partes -join '/')
}

function Format-CorenText {
    param([object]$Value)
    $v=([string]$Value).Trim()
    if([string]::IsNullOrWhiteSpace($v)){return ''}
    if($v.ToUpperInvariant().StartsWith('COREN')){return $v}
    return ('COREN ' + $v)
}

function Get-HorarioVisualMeta {
    param([string]$Periodo,[string]$Nome,[string]$Descricao,[string]$Regra)
    $p=([string]$Periodo).Trim().ToUpperInvariant()
    $txt=((([string]$Nome)+' '+([string]$Descricao)+' '+([string]$Regra))).ToUpperInvariant()
    $txt=$txt.Replace('Í','I').Replace('Á','A').Replace('À','A').Replace('Â','A').Replace('Ã','A').Replace('É','E').Replace('Ê','E').Replace('Ó','O').Replace('Ô','O').Replace('Õ','O').Replace('Ú','U').Replace('Ç','C')
    $par=''
    if($txt -match '\bIMPAR\b'){$par='IMPAR'}elseif($txt -match '\bPAR\b'){$par='PAR'}
    $ehMV=($p -in @('M','V') -or $txt -match '\bMATUTINO\b' -or $txt -match '\bVESPERTINO\b')
    $ehDN=($p -in @('D','N') -or $txt -match '\bDIURNO\b' -or $txt -match '\bNOTURNO\b')
    return [pscustomobject]@{Periodo=$p;Paridade=$par;EhMV=$ehMV;EhDN=$ehDN}
}

function Get-HorarioDayVisual {
    # A paridade PAR/IMPAR precisa refletir o giro CONTINUO do 12x36 (dia 1,
    # 2, 3... sem parar), nao o dia-do-mes (que reinicia todo mes e desalinha
    # sempre que o mes anterior tem 31 dias). Por isso usa-se uma contagem de
    # dias corridos desde uma data fixa de referencia, que nunca reinicia -
    # assim o mesmo cadastro de Horario funciona certo em qualquer mes, para
    # sempre, sem precisar duplicar horario nem ajustar nada manualmente.
    param([object]$Meta,[datetime]$Data,[bool]$MaskDN,[bool]$MaskMV,[bool]$AutoPTMV)
    $mask=$false;$autoPT=$false
    if($null -eq $Meta -or [string]::IsNullOrWhiteSpace([string]$Meta.Paridade)){
        return [pscustomobject]@{Mask=$false;AutoPT=$false}
    }
    $diaPar=((Get-DiasCorridosParidade $Data) % 2) -eq 0
    $bate=$(if([string]$Meta.Paridade -eq 'PAR'){$diaPar}else{-not $diaPar})
    $fds=($Data.DayOfWeek -eq [System.DayOfWeek]::Saturday -or $Data.DayOfWeek -eq [System.DayOfWeek]::Sunday)
    if([bool]$Meta.EhDN -and $MaskDN -and $bate){$mask=$true}
    elseif([bool]$Meta.EhMV -and $MaskMV -and $fds -and $bate){$mask=$true;if($AutoPTMV){$autoPT=$true}}
    return [pscustomobject]@{Mask=$mask;AutoPT=$autoPT}
}

function Get-DiasCorridosParidade {
    # Numero de dias corridos desde uma data fixa de referencia (nao tem
    # nenhum significado especial, so precisa ser fixa e nunca mudar).
    param([datetime]$Data)
    return [int]($Data.Date - [datetime]'2000-01-01').Days
}

function Get-PalavraParidadeDoMes {
    # O cadastro do Horario tem uma paridade FIXA (baseada em dias corridos,
    # nunca precisa trocar - ver Get-HorarioDayVisual). Mas a PALAVRA exibida
    # no cabecalho (PAR ou IMPAR) precisa bater com o numero do dia realmente
    # pintado NESTE mes especifico, para nao parecer inconsistente pra quem
    # olha a tela (ex.: cabecalho escrito "PAR" com o dia 01 destacado, que
    # visualmente parece impar). O dia 1 de qualquer mes e sempre um numero
    # impar; entao so verifica se o dia 1 bate com a paridade fixa do bloco:
    # se bater, os dias destacados neste mes sao os IMPARES; senao, sao os PARES.
    param([object]$Meta,[int]$Ano,[int]$Mes)
    if($null -eq $Meta -or [string]::IsNullOrWhiteSpace([string]$Meta.Paridade)){return ''}
    $dia1=Get-Date -Year $Ano -Month $Mes -Day 1
    $dia1CorridoPar=((Get-DiasCorridosParidade $dia1) % 2) -eq 0
    $bateDia1=$(if([string]$Meta.Paridade -eq 'PAR'){$dia1CorridoPar}else{-not $dia1CorridoPar})
    return $(if($bateDia1){'IMPAR'}else{'PAR'})
}

function Get-CabecalhoAjustadoParidade {
    # Troca, so para exibicao, a palavra PAR/IMPAR gravada no cabecalho do
    # Horario pela palavra que realmente descreve os dias destacados NESTE
    # mes. O cadastro em si (banco de dados) nunca e alterado.
    param([string]$Texto,[object]$Meta,[int]$Ano,[int]$Mes)
    if([string]::IsNullOrWhiteSpace($Texto) -or $null -eq $Meta -or [string]::IsNullOrWhiteSpace([string]$Meta.Paridade)){return $Texto}
    $palavraCorreta=Get-PalavraParidadeDoMes $Meta $Ano $Mes
    if([string]::IsNullOrWhiteSpace($palavraCorreta) -or $palavraCorreta -eq [string]$Meta.Paridade){return $Texto}
    # so troca a palavra oposta a correta (evita mexer em outras ocorrencias de "PAR" no texto, tipo "PARIDADE")
    $palavraAtual=[string]$Meta.Paridade
    return ($Texto -replace ('\b' + $palavraAtual + '\b'),$palavraCorreta)
}

function Set-GridRangeVisual {
    param(
        [System.Windows.Forms.DataGridViewRow]$Row,
        [int]$DiaInicial,
        [int]$DiaFinal,
        [string]$Texto,
        [System.Drawing.Color]$BackColor = ([System.Drawing.Color]::FromArgb(238,238,238)),
        [System.Drawing.Color]$ForeColor = ([System.Drawing.Color]::Black)
    )
    if($null -eq $Row){return}
    if($DiaInicial -lt 1){$DiaInicial=1}
    if($DiaFinal -lt $DiaInicial){return}
    $meio=[int][Math]::Floor(($DiaInicial+$DiaFinal)/2)
    for($d=$DiaInicial;$d -le $DiaFinal;$d++){
        $cn=('D{0:00}' -f $d)
        if(-not $Row.DataGridView.Columns.Contains($cn)){continue}
        $cell=$Row.Cells[$cn]
        $cell.Value=$(if($d -eq $meio){$Texto}else{''})
        $cell.ToolTipText=$Texto
        $cell.Style.BackColor=$BackColor
        $cell.Style.ForeColor=$ForeColor
        $cell.Style.Alignment='MiddleCenter'
        $cell.Style.WrapMode='True'
        # Metadados usados pelo CellPainting para simular uma unica celula mesclada.
        $cell.Tag=[pscustomobject]@{
            EscalaRange=$true
            Inicio=$DiaInicial
            Fim=$DiaFinal
            Meio=$meio
            Texto=$Texto
            BackArgb=$BackColor.ToArgb()
            ForeArgb=$ForeColor.ToArgb()
        }
    }
    if($Texto -eq 'ESCALA VAGA' -and $Row.Height -lt 34){$Row.Height=34}
}

function Sync-Calendario08hForScale {
    param([int]$ScaleId)
    if($ScaleId -le 0){ return $false }
    try {
        $autoFFPF=Get-ConfigBool '08h_auto_ff_pf' $true
        $autoFS=Get-ConfigBool '08h_auto_fs' $true
        $esc=Db-Query "SELECT ano,mes FROM escalas WHERE id=$ScaleId;"
        if($esc.Rows.Count -eq 0){ Write-Log ("Falha calendario 08h: escala nao encontrada id={0}" -f $ScaleId); return $false }
        $ano=[int]$esc.Rows[0]['ano'];$mes=[int]$esc.Rows[0]['mes']
        $eventos=Db-Query ("SELECT data,COALESCE(tipo,'FERIADO') AS tipo,descricao FROM feriados WHERE data LIKE {0} ORDER BY data;" -f (Sql-Q ('{0}-{1:00}-%' -f $ano,$mes)))
        $servidores08=Db-Query ("SELECT es.id AS esid FROM escala_servidores es JOIN horarios h ON h.id=es.horario_id WHERE es.escala_id={0} AND es.ativo=1 AND h.ativo=1 AND COALESCE(h.auto_calendario_08h,0)=1;" -f $ScaleId)

        $sql=New-Object System.Text.StringBuilder
        [void]$sql.AppendLine('BEGIN IMMEDIATE;')
        # Sempre limpa os lancamentos automaticos antigos. Assim, ao DESMARCAR
        # as opcoes 08h, FF/PF/FS gerados anteriormente tambem sao removidos.
        [void]$sql.AppendLine(("DELETE FROM escala_dias WHERE escala_servidor_id IN (SELECT id FROM escala_servidores WHERE escala_id={0}) AND origem IN ('CALENDARIO_FERIADO','CALENDARIO_PF','CALENDARIO_FS_08H');" -f $ScaleId))

        foreach($sv in $servidores08.Rows){
            $esid=[int]$sv['esid']
            if($autoFFPF){
                foreach($ev in $eventos.Rows){
                    $data=[string]$ev['data'];$tipo=([string]$ev['tipo']).Trim().ToUpperInvariant();$desc=[string]$ev['descricao']
                    $sig=$(if($tipo -eq 'PONTO_FACULTATIVO'){'PF'}else{'FF'})
                    $origem=$(if($tipo -eq 'PONTO_FACULTATIVO'){'CALENDARIO_PF'}else{'CALENDARIO_FERIADO'})
                    if([string]::IsNullOrWhiteSpace($desc)){$desc=$(if($sig -eq 'PF'){'Ponto Facultativo'}else{'Feriado'})}
                    [void]$sql.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) SELECT {0},{1},{2},{3},{4} WHERE NOT EXISTS(SELECT 1 FROM escala_dias WHERE escala_servidor_id={0} AND data={1});" -f $esid,(Sql-Q $data),(Sql-Q $sig),(Sql-Q $desc),(Sql-Q $origem)))
                }
            }
            if($autoFS){
                $diasMes=[datetime]::DaysInMonth($ano,$mes)
                for($d=1;$d -le $diasMes;$d++){
                    $dt=Get-Date -Year $ano -Month $mes -Day $d
                    if($dt.DayOfWeek -ne 'Saturday' -and $dt.DayOfWeek -ne 'Sunday'){ continue }
                    $data=$dt.ToString('yyyy-MM-dd')
                    [void]$sql.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) SELECT {0},{1},'FS','Folga Semana','CALENDARIO_FS_08H' WHERE NOT EXISTS(SELECT 1 FROM escala_dias WHERE escala_servidor_id={0} AND data={1});" -f $esid,(Sql-Q $data)))
                }
            }
        }
        [void]$sql.AppendLine('COMMIT;')
        Db-Exec $sql.ToString()
        Write-Log ("Calendario 08h sincronizado: escala={0}; servidores08h={1}; eventos={2}; autoFFPF={3}; autoFS={4}" -f $ScaleId,$servidores08.Rows.Count,$eventos.Rows.Count,$autoFFPF,$autoFS)
        return $true
    } catch {
        Write-Log ('Falha ao sincronizar FS/FF/PF automaticos de 08h: ' + $_.Exception.Message)
        return $false
    }
}


# Garante uma ordem especifica dos blocos para cada escala mensal.
# A ordem global de horarios continua servindo apenas como valor padrao.
function Sync-ScaleBlockOrder {
    param([int]$ScaleId)
    if($ScaleId -le 0){return $true}
    try{
        $missing=[int](Db-Scalar (@"
SELECT COUNT(*) FROM (
    SELECT horario_id FROM escala_servidores WHERE escala_id=$ScaleId AND ativo=1 AND horario_id IS NOT NULL
    UNION
    SELECT horario_id FROM escala_vagas WHERE escala_id=$ScaleId AND ativo=1 AND horario_id IS NOT NULL
) u
WHERE NOT EXISTS(SELECT 1 FROM escala_blocos_ordem bo WHERE bo.escala_id=$ScaleId AND bo.horario_id=u.horario_id);
"@))
        if($missing -le 0){return $true}
        Db-Exec @"
INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem)
SELECT $ScaleId,u.horario_id,COALESCE(h.ordem,u.horario_id)
FROM (
    SELECT horario_id FROM escala_servidores WHERE escala_id=$ScaleId AND ativo=1 AND horario_id IS NOT NULL
    UNION
    SELECT horario_id FROM escala_vagas WHERE escala_id=$ScaleId AND ativo=1 AND horario_id IS NOT NULL
) u
JOIN horarios h ON h.id=u.horario_id;
"@
        return $true
    }catch{
        Write-Log ('Falha ao sincronizar ordem dos blocos: ' + $_.Exception.Message)
        return $false
    }
}

function Get-CurrentBlockHorarioId {
    try{
        $g=$script:gridEscala
        if($null -eq $g -or $null -eq $g.CurrentRow){return 0}
        if([string]$g.CurrentRow.Cells['_TIPO'].Value -ne 'BLOCO'){return 0}
        return [int]$g.CurrentRow.Cells['_HORARIO_ID'].Value
    }catch{return 0}
}

function Select-BlockRowByHorarioId {
    param([int]$HorarioId)
    if($HorarioId -le 0 -or $null -eq $script:gridEscala){return}
    foreach($r in $script:gridEscala.Rows){
        if([string]$r.Cells['_TIPO'].Value -eq 'BLOCO' -and [int]$r.Cells['_HORARIO_ID'].Value -eq $HorarioId){
            $script:gridEscala.ClearSelection()
            $script:gridEscala.CurrentCell=$r.Cells['Servidor']
            $r.Cells['Servidor'].Selected=$true
            $script:gridEscala.FirstDisplayedScrollingRowIndex=$r.Index
            break
        }
    }
}

function Move-CurrentScaleBlock {
    param([ValidateSet('UP','DOWN','FIRST','LAST')][string]$Mode)
    try{
        $scaleId=[int]$script:CurrentScaleId
        if($scaleId -le 0){Show-Info 'Carregue primeiro uma escala mensal.';return}
        $hid=Get-CurrentBlockHorarioId
        if($hid -le 0){Show-Info 'Clique primeiro no cabecalho cinza do bloco de horario que deseja mover.';return}

        $syncBlocosOk=[bool](Sync-ScaleBlockOrder $scaleId)
        if(-not $syncBlocosOk){
            Show-Error 'Nao foi possivel sincronizar a ordem dos blocos. A movimentacao foi cancelada para evitar uma ordem inconsistente. Consulte Logs\Sistema_Escala.log.'
            return
        }
        $t=Db-Query ("
SELECT bo.horario_id
FROM escala_blocos_ordem bo
WHERE bo.escala_id={0}
ORDER BY bo.ordem,bo.horario_id;" -f $scaleId)

        $ids=@()
        foreach($r in $t.Rows){$ids += [int]$r['horario_id']}
        $ids=@($ids)
        if($ids.Count -le 1){Show-Info 'Esta escala possui apenas um bloco de horario para ordenar.';return}
        $idx=-1
        for($i=0;$i -lt $ids.Count;$i++){if([int]$ids[$i] -eq $hid){$idx=$i;break}}
        if($idx -lt 0){Show-Info 'Nao foi possivel localizar o bloco selecionado na ordem da escala.';return}

        switch($Mode){
            'UP' {
                if($idx -eq 0){Show-Info 'Este bloco ja e o primeiro da escala.';return}
                $tmp=$ids[$idx-1];$ids[$idx-1]=$ids[$idx];$ids[$idx]=$tmp
            }
            'DOWN' {
                if($idx -ge ($ids.Count-1)){Show-Info 'Este bloco ja e o ultimo da escala.';return}
                $tmp=$ids[$idx+1];$ids[$idx+1]=$ids[$idx];$ids[$idx]=$tmp
            }
            'FIRST' {
                if($idx -eq 0){return}
                $list=New-Object System.Collections.ArrayList
                [void]$list.Add($hid)
                for($i=0;$i -lt $ids.Count;$i++){if($i -ne $idx){[void]$list.Add([int]$ids[$i])}}
                $ids=@($list)
            }
            'LAST' {
                if($idx -eq ($ids.Count-1)){return}
                $list=New-Object System.Collections.ArrayList
                for($i=0;$i -lt $ids.Count;$i++){if($i -ne $idx){[void]$list.Add([int]$ids[$i])}}
                [void]$list.Add($hid)
                $ids=@($list)
            }
        }

        $sb=New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('BEGIN IMMEDIATE;')
        for($i=0;$i -lt $ids.Count;$i++){
            $ord=($i+1)*10
            [void]$sb.AppendLine(("UPDATE escala_blocos_ordem SET ordem={0} WHERE escala_id={1} AND horario_id={2};" -f $ord,$scaleId,[int]$ids[$i]))
        }
        [void]$sb.AppendLine('COMMIT;')
        Db-Exec $sb.ToString()
        Write-Log ("Ordem de blocos alterada: escala={0} horario={1} modo={2}" -f $scaleId,$hid,$Mode)
        Load-Escala
        Select-BlockRowByHorarioId $hid
    }catch{
        Show-Error $_.Exception.Message
    }
}

# V1.0.14.13 - Reposicionar servidores DENTRO do proprio bloco de horario,
# assim como SUBIR/DESCER BLOCO faz para os blocos. Nao move o servidor para
# outro bloco, so muda a ordem de exibicao entre os colegas do mesmo horario
# (por exemplo, para deixar ENF antes de TE, ou na ordem que preferir).
function Get-CurrentServidorContext {
    # Usa o mesmo criterio robusto do botao + SERVIDOR: prioriza as celulas
    # realmente selecionadas na tela (SelectedCells) e cai para CurrentRow
    # apenas se nao houver nenhuma celula marcada.
    $g=$script:gridEscala
    if($null -eq $g){return $null}
    $linha=$null
    if($g.SelectedCells.Count -gt 0){$linha=$g.SelectedCells[0].OwningRow}
    elseif($null -ne $g.CurrentRow){$linha=$g.CurrentRow}
    if($null -eq $linha){return $null}
    try{
        if([string]$linha.Cells['_TIPO'].Value -ne 'SERVIDOR'){return $null}
        return [pscustomobject]@{
            EsId=[int]$linha.Cells['_ID'].Value
            HorarioId=[int]$linha.Cells['_HORARIO_ID'].Value
        }
    }catch{return $null}
}

function Select-ServidorRowByEsId {
    param([int]$EsId)
    if($EsId -le 0 -or $null -eq $script:gridEscala){return}
    foreach($r in $script:gridEscala.Rows){
        if([string]$r.Cells['_TIPO'].Value -eq 'SERVIDOR' -and [int]$r.Cells['_ID'].Value -eq $EsId){
            $script:gridEscala.ClearSelection()
            $script:gridEscala.CurrentCell=$r.Cells['Servidor']
            $r.Cells['Servidor'].Selected=$true
            $script:gridEscala.FirstDisplayedScrollingRowIndex=$r.Index
            break
        }
    }
}

function Move-CurrentScaleServidor {
    param([ValidateSet('UP','DOWN')][string]$Mode)
    try{
        $scaleId=[int]$script:CurrentScaleId
        if($scaleId -le 0){Show-Info 'Carregue primeiro uma escala mensal.';return}
        $ctx=Get-CurrentServidorContext
        if($null -eq $ctx -or $ctx.EsId -le 0){Show-Info 'Clique primeiro em uma linha de servidor (nao o cabecalho do bloco) para reordenar.';return}

        # Mesma ordem usada na tela e na impressao dentro do bloco: ordem, depois nome.
        $t=Db-Query ("SELECT es.id AS esid FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id={0} AND es.horario_id={1} AND es.ativo=1 ORDER BY es.ordem,s.nome;" -f $scaleId,$ctx.HorarioId)
        $ids=@()
        foreach($r in $t.Rows){$ids += [int]$r['esid']}
        $ids=@($ids)
        if($ids.Count -le 1){Show-Info 'Este bloco possui apenas um servidor - nao ha o que reordenar.';return}
        $idx=-1
        for($i=0;$i -lt $ids.Count;$i++){if([int]$ids[$i] -eq $ctx.EsId){$idx=$i;break}}
        if($idx -lt 0){Show-Info 'Nao foi possivel localizar o servidor selecionado na ordem do bloco.';return}

        switch($Mode){
            'UP' {
                if($idx -eq 0){Show-Info 'Este servidor ja e o primeiro do bloco.';return}
                $tmp=$ids[$idx-1];$ids[$idx-1]=$ids[$idx];$ids[$idx]=$tmp
            }
            'DOWN' {
                if($idx -ge ($ids.Count-1)){Show-Info 'Este servidor ja e o ultimo do bloco.';return}
                $tmp=$ids[$idx+1];$ids[$idx+1]=$ids[$idx];$ids[$idx]=$tmp
            }
        }

        $sb=New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('BEGIN IMMEDIATE;')
        for($i=0;$i -lt $ids.Count;$i++){
            $ord=($i+1)*10
            [void]$sb.AppendLine(("UPDATE escala_servidores SET ordem={0} WHERE id={1};" -f $ord,[int]$ids[$i]))
        }
        [void]$sb.AppendLine('COMMIT;')
        Db-Exec $sb.ToString()
        Write-Log ("Ordem de servidor alterada dentro do bloco: escala={0} horario={1} esid={2} modo={3}" -f $scaleId,$ctx.HorarioId,$ctx.EsId,$Mode)
        Load-Escala
        Select-ServidorRowByEsId $ctx.EsId
    }catch{
        Show-Error $_.Exception.Message
    }
}

# V1.0.14.15 - Ordena automaticamente TODOS os blocos da escala carregada pela
# prioridade de cargo configurada em Configuracoes > Qtd / Contagem (ex.:
# ENF,TE,AE). Dentro de cada bloco, quem tiver o cargo configurado primeiro
# fica no topo; cargos fora da lista vao para o final, em ordem alfabetica de
# cargo e depois de nome. Nao move ninguem de bloco, so reordena dentro dele -
# complementa o SUBIR/DESCER SERVIDOR para ajustes pontuais depois.
function Sort-CurrentScaleByFuncao {
    try{
        $scaleId=[int]$script:CurrentScaleId
        if($scaleId -le 0){Show-Info 'Carregue primeiro uma escala mensal.';return}

        $listaTexto=Get-ConfigValue 'ordem_cargos' 'ENF,TE,AE'
        $ordemCargos=@($listaTexto -split ',' | ForEach-Object{$_.Trim().ToUpperInvariant()} | Where-Object{$_ -ne ''})
        if($ordemCargos.Count -eq 0){Show-Info 'Configure a ordem dos cargos em Configuracoes > Qtd / Contagem antes de usar esta opcao.';return}

        $t=Db-Query ("SELECT es.id AS esid,es.horario_id,COALESCE(s.funcao,'') AS funcao,s.nome FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id={0} AND es.ativo=1;" -f $scaleId)
        if($t.Rows.Count -eq 0){Show-Info 'Esta escala nao possui servidores para ordenar.';return}
        if(-not (Confirm-Action ('Reordenar todos os servidores desta escala dentro de cada bloco, seguindo a prioridade: ' + ($ordemCargos -join ', ') + ' (demais cargos ao final)? Esta acao nao move ninguem para outro bloco, so muda a ordem de exibicao.'))){return}

        $porBloco=@{}
        foreach($r in $t.Rows){
            $hid=[int]$r['horario_id']
            if(-not $porBloco.ContainsKey($hid)){$porBloco[$hid]=New-Object System.Collections.ArrayList}
            $fRaw=([string]$r['funcao']).Trim().ToUpperInvariant()
            $prio=9999
            for($i=0;$i -lt $ordemCargos.Count;$i++){if($ordemCargos[$i] -eq $fRaw){$prio=$i;break}}
            [void]$porBloco[$hid].Add([pscustomobject]@{EsId=[int]$r['esid'];Prioridade=$prio;Funcao=$fRaw;Nome=[string]$r['nome']})
        }

        $sb=New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('BEGIN IMMEDIATE;')
        foreach($hid in $porBloco.Keys){
            $ordenados=@($porBloco[$hid] | Sort-Object Prioridade,Funcao,Nome)
            for($i=0;$i -lt $ordenados.Count;$i++){
                $ord=($i+1)*10
                [void]$sb.AppendLine(("UPDATE escala_servidores SET ordem={0} WHERE id={1};" -f $ord,$ordenados[$i].EsId))
            }
        }
        [void]$sb.AppendLine('COMMIT;')
        Db-Exec $sb.ToString()
        Write-Log ("Escala ordenada por cargo: escala={0} ordem={1} blocos={2}" -f $scaleId,($ordemCargos -join ','),$porBloco.Count)
        Load-Escala
        Show-Info ('Servidores reordenados dentro de cada bloco pela prioridade: ' + ($ordemCargos -join ', ') + ' (demais cargos ao final).')
    }catch{
        Show-Error $_.Exception.Message
    }
}


# ---------------- FLUXO GUIADO ----------------
# Estas rotinas sao acionadas apenas quando o usuario pede o Assistente ou configura os blocos.
# Nada do fluxo guiado e executado durante a inicializacao do programa.

function Get-ScaleBlockCount {
    param([int]$ScaleId=0)
    try {
        if($ScaleId -le 0){$ScaleId=[int](Get-ScaleId)}
        if($ScaleId -le 0){return 0}
        $v=Db-Scalar "SELECT COUNT(*) FROM escala_blocos_ordem WHERE escala_id=$ScaleId;"
        if($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)){return 0}
        return [int]$v
    } catch {
        return 0
    }
}

function Show-ScaleBlocksManager {
    try {
        $scaleId=[int](Get-ScaleId)
        if($scaleId -le 0){
            Show-Info 'PASSO 3: crie ou carregue primeiro a escala do mes.'
            return
        }
        $scaleIdSql=Sql-Int $scaleId 'escala_id'
        $script:CurrentScaleId=$scaleId

        $ctxTxt='Escala mensal'
        $anoCtx=[int]$script:numAno.Value
        $mesCtx=[int]$script:cboMes.SelectedValue
        $setCtx=''
        $setCtx=[string]$script:cboSetorEscala.Text
        $subCtx=''
        $subCtx=[string]$script:cboSubSetorEscala.Text
        if($subCtx -and $subCtx -ne '(sem Sub_Setor)'){$setCtx=$setCtx+' / '+$subCtx}
        if($setCtx){$ctxTxt=('{0} - {1:00}/{2}' -f $setCtx,$mesCtx,$anoCtx)}

        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text='Configurar Blocos de Horario'
        $f.StartPosition='CenterParent'
        $f.ClientSize=New-Object System.Drawing.Size(1280,700)
        $f.MinimumSize=New-Object System.Drawing.Size(1100,620)

        $title=New-Object System.Windows.Forms.Label
        $title.Text=('PASSO 4 - BLOCOS DE HORARIO | '+$ctxTxt)
        $title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12)
        $title.Location=New-Object System.Drawing.Point(18,16)
        $title.Size=New-Object System.Drawing.Size(1225,28)
        $f.Controls.Add($title)

        $info=New-Object System.Windows.Forms.Label
        $info.Text='Escolha os blocos que pertencem a este mes. Depois inclua os servidores. Retirar um bloco usado por servidor ou Escala Vaga e bloqueado.'
        $info.Location=New-Object System.Drawing.Point(18,48)
        $info.Size=New-Object System.Drawing.Size(1225,40)
        $info.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
        $f.Controls.Add($info)

        $la=New-Object System.Windows.Forms.Label
        $la.Text='Horarios disponiveis'
        $la.Location=New-Object System.Drawing.Point(18,95)
        $la.Size=New-Object System.Drawing.Size(500,24)
        $la.Font=$script:FontSemibold9
        $f.Controls.Add($la)

        $lc=New-Object System.Windows.Forms.Label
        $lc.Text='Blocos desta escala (ordem)'
        $lc.Location=New-Object System.Drawing.Point(710,95)
        $lc.Size=New-Object System.Drawing.Size(540,24)
        $lc.Font=$script:FontSemibold9
        $f.Controls.Add($lc)

        $gA=New-Object System.Windows.Forms.DataGridView
        Set-GridStyle $gA
        $gA.Location=New-Object System.Drawing.Point(18,122)
        $gA.Size=New-Object System.Drawing.Size(500,420)
        $gA.Anchor='Top,Bottom,Left'
        $gA.SelectionMode='FullRowSelect'
        $gA.MultiSelect=$false
        $f.Controls.Add($gA)

        $gC=New-Object System.Windows.Forms.DataGridView
        Set-GridStyle $gC
        $gC.Location=New-Object System.Drawing.Point(710,122)
        $gC.Size=New-Object System.Drawing.Size(540,420)
        $gC.Anchor='Top,Bottom,Left,Right'
        $gC.SelectionMode='FullRowSelect'
        $gC.MultiSelect=$false
        $f.Controls.Add($gC)

        # V1.0.14.33 - O espaco central entre as grades foi ampliado junto com a janela,
        # mantendo os botoes totalmente visiveis e dando mais area para Bloco/Cabecalho.
        $bAdd=New-Button 'ADICIONAR >>' 155
        $bAdd.Location=New-Object System.Drawing.Point(535,295)
        $f.Controls.Add($bAdd)

        $bRem=New-Button '<< RETIRAR' 155
        $bRem.Location=New-Object System.Drawing.Point(535,345)
        $f.Controls.Add($bRem)

        $bUp=New-Button 'SUBIR' 100
        $bUp.Location=New-Object System.Drawing.Point(710,560)
        $bUp.Anchor='Bottom,Left'
        $f.Controls.Add($bUp)

        $bDown=New-Button 'DESCER' 100
        $bDown.Location=New-Object System.Drawing.Point(820,560)
        $bDown.Anchor='Bottom,Left'
        $f.Controls.Add($bDown)

        $bCopy=New-Button 'COPIAR BLOCOS DO MES ANTERIOR' 245
        $bCopy.Location=New-Object System.Drawing.Point(18,560)
        $bCopy.Anchor='Bottom,Left'
        $f.Controls.Add($bCopy)

        $bClose=New-Button 'CONCLUIR' 120
        Set-PrimaryButton $bClose
        $bClose.Location=New-Object System.Drawing.Point(1130,610)
        $bClose.Anchor='Bottom,Right'
        $f.Controls.Add($bClose)

        $reload={
            try {
                $a=Db-Query "SELECT h.id,h.nome AS Bloco,h.periodo AS Periodo,COALESCE(h.descricao,'') AS Cabecalho FROM horarios h WHERE h.ativo=1 AND NOT EXISTS(SELECT 1 FROM escala_blocos_ordem bo WHERE bo.escala_id=$scaleIdSql AND bo.horario_id=h.id) ORDER BY h.ordem,h.nome;"
                $c=Db-Query "SELECT h.id,bo.ordem AS Ordem,h.nome AS Bloco,h.periodo AS Periodo,COALESCE(h.descricao,'') AS Cabecalho FROM escala_blocos_ordem bo JOIN horarios h ON h.id=bo.horario_id WHERE bo.escala_id=$scaleIdSql AND h.ativo=1 ORDER BY bo.ordem,h.nome;"
                $gA.DataSource=$a
                $gC.DataSource=$c
                foreach($g in @($gA,$gC)){
                    if($g.Columns.Contains('id')){$g.Columns['id'].Visible=$false}
                    if($g.Columns.Contains('Bloco')){
                        $g.Columns['Bloco'].Width=185
                        $g.Columns['Bloco'].DefaultCellStyle.WrapMode='True'
                    }
                    if($g.Columns.Contains('Periodo')){$g.Columns['Periodo'].Width=80}
                    if($g.Columns.Contains('Cabecalho')){
                        $g.Columns['Cabecalho'].AutoSizeMode='Fill'
                        $g.Columns['Cabecalho'].MinimumWidth=230
                        $g.Columns['Cabecalho'].DefaultCellStyle.WrapMode='True'
                    }
                    $g.AutoSizeRowsMode='AllCells'
                }
                if($gC.Columns.Contains('Ordem')){$gC.Columns['Ordem'].Width=60}
            } catch {
                Show-Error $_.Exception.Message
            }
        }

        $reordena={
            param([string]$modo)
            try {
                if($null -eq $gC.CurrentRow){return}
                $hid=[int]$gC.CurrentRow.Cells['id'].Value
                $ids=New-Object System.Collections.ArrayList
                foreach($rr in $gC.Rows){
                    if(-not $rr.IsNewRow){[void]$ids.Add([int]$rr.Cells['id'].Value)}
                }
                $idx=$ids.IndexOf($hid)
                if($idx -lt 0){return}
                if($modo -eq 'UP'){
                    if($idx -eq 0){return}
                    $tmp=$ids[$idx-1];$ids[$idx-1]=$ids[$idx];$ids[$idx]=$tmp
                } else {
                    if($idx -ge ($ids.Count-1)){return}
                    $tmp=$ids[$idx+1];$ids[$idx+1]=$ids[$idx];$ids[$idx]=$tmp
                }
                $sb=New-Object System.Text.StringBuilder
                [void]$sb.AppendLine('BEGIN IMMEDIATE;')
                for($i=0;$i -lt $ids.Count;$i++){
                    $hidSql=Sql-Int ([int]$ids[$i]) 'horario_id'
                    [void]$sb.AppendLine(("UPDATE escala_blocos_ordem SET ordem={0} WHERE escala_id={1} AND horario_id={2};" -f (($i+1)*10),$scaleIdSql,$hidSql))
                }
                [void]$sb.AppendLine('COMMIT;')
                Db-Exec $sb.ToString()
                & $reload
            } catch {
                Show-Error $_.Exception.Message
            }
        }

        $bAdd.Add_Click({
            try {
                if($null -eq $gA.CurrentRow){Show-Info 'Selecione um horario disponivel.';return}
                $hid=[int]$gA.CurrentRow.Cells['id'].Value
                $hidSql=Sql-Int $hid 'horario_id'
                $ord=Db-Scalar "SELECT COALESCE(MAX(ordem),0)+10 FROM escala_blocos_ordem WHERE escala_id=$scaleIdSql;"
                if($null -eq $ord){$ord=10}
                Db-Exec "INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem) VALUES ($scaleIdSql,$hidSql,$([int]$ord));"
                & $reload
            } catch {
                Show-Error $_.Exception.Message
            }
        })

        $bRem.Add_Click({
            try {
                if($null -eq $gC.CurrentRow){Show-Info 'Selecione um bloco desta escala.';return}
                $hid=[int]$gC.CurrentRow.Cells['id'].Value
                $hidSql=Sql-Int $hid 'horario_id'
                $usos=Db-Scalar "SELECT (SELECT COUNT(*) FROM escala_servidores WHERE escala_id=$scaleIdSql AND horario_id=$hidSql AND ativo=1)+(SELECT COUNT(*) FROM escala_vagas WHERE escala_id=$scaleIdSql AND horario_id=$hidSql AND ativo=1);"
                if($null -ne $usos -and [int]$usos -gt 0){
                    Show-Info 'Este bloco possui servidores ou Escala Vaga. Remova ou mova esses registros antes de retirar o bloco.'
                    return
                }
                if(Confirm-Action 'Retirar este bloco desta escala mensal? O cadastro geral do horario nao sera excluido.'){
                    Db-Exec "DELETE FROM escala_blocos_ordem WHERE escala_id=$scaleIdSql AND horario_id=$hidSql;"
                    & $reload
                }
            } catch {
                Show-Error $_.Exception.Message
            }
        })

        $bUp.Add_Click({& $reordena 'UP'})
        $bDown.Add_Click({& $reordena 'DOWN'})

        $bCopy.Add_Click({
            try {
                $sid=Get-SelectedSetorId
                $sidSql=Sql-Int $sid 'setor_id'
                $ano=[int]$script:numAno.Value
                $mes=[int]$script:cboMes.SelectedValue
                $prev=Db-Scalar "SELECT id FROM escalas WHERE setor_id=$sidSql AND id<>$scaleIdSql AND (ano<$ano OR (ano=$ano AND mes<$mes)) ORDER BY ano DESC,mes DESC LIMIT 1;"
                if($null -eq $prev -or [int]$prev -le 0){
                    Show-Info 'Nao existe escala anterior deste setor para copiar os blocos.'
                    return
                }
                $prevId=[int]$prev
                $prevIdSql=Sql-Int $prevId 'escala_anterior_id'
                Db-Exec "INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem) SELECT $scaleIdSql,horario_id,ordem FROM escala_blocos_ordem WHERE escala_id=$prevIdSql;"
                Db-Exec "INSERT OR IGNORE INTO escala_blocos_ordem(escala_id,horario_id,ordem) SELECT $scaleIdSql,x.horario_id,COALESCE(h.ordem,x.horario_id) FROM (SELECT horario_id FROM escala_servidores WHERE escala_id=$prevIdSql AND ativo=1 AND horario_id IS NOT NULL UNION SELECT horario_id FROM escala_vagas WHERE escala_id=$prevIdSql AND ativo=1 AND horario_id IS NOT NULL) x JOIN horarios h ON h.id=x.horario_id;"
                & $reload
            } catch {
                Show-Error $_.Exception.Message
            }
        })

        $bClose.Add_Click({$f.Close()})
        & $reload
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
        Load-Escala
    } catch {
        Show-Error $_.Exception.Message
    }
}

function Show-WorkflowAssistant {
    try {
        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text='Assistente - Escala Mensal'
        $f.StartPosition='CenterParent'
        $f.ClientSize=New-Object System.Drawing.Size(930,670)
        $f.MinimumSize=New-Object System.Drawing.Size(860,620)

        $title=New-Object System.Windows.Forms.Label
        $title.Text='ASSISTENTE PASSO A PASSO'
        $title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',15)
        $title.Location=New-Object System.Drawing.Point(22,18)
        $title.Size=New-Object System.Drawing.Size(850,32)
        $f.Controls.Add($title)

        $sub=New-Object System.Windows.Forms.Label
        $sub.Text='O sistema libera as etapas na ordem correta. Se uma etapa estiver pendente, conclua-a antes de avancar.'
        $sub.Location=New-Object System.Drawing.Point(24,56)
        $sub.Size=New-Object System.Drawing.Size(850,38)
        $sub.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
        $f.Controls.Add($sub)

        $steps=@(
            '1. SETOR / SUB_SETOR - cadastrar e selecionar o local da escala',
            '2. HORARIOS - cadastrar a biblioteca de horarios',
            '3. CRIAR MES - criar ou carregar a escala mensal',
            '4. BLOCOS DO MES - escolher e ordenar os blocos de horario',
            '5. SERVIDORES - incluir individualmente ou por Lotacao em Lote',
            '6. PREENCHIMENTO - Calendario, siglas, Ferias/Atestados e Escala Vaga',
            '7. CONFERIR / IMPRIMIR - abrir a pre-visualizacao'
        )
        $actions=@('ABRIR SETORES','ABRIR HORARIOS','CRIAR / CARREGAR','CONFIGURAR BLOCOS','LOTACAO EM LOTE','IR PARA ESCALA','PRE-VISUALIZAR')
        $status=New-Object System.Collections.ArrayList
        $buttons=New-Object System.Collections.ArrayList

        for($i=0;$i -lt $steps.Count;$i++){
            $y=105+($i*67)
            $lab=New-Object System.Windows.Forms.Label
            $lab.Text=$steps[$i]
            $lab.Location=New-Object System.Drawing.Point(25,$y)
            $lab.Size=New-Object System.Drawing.Size(600,26)
            $lab.Font=$script:FontSemibold9
            $f.Controls.Add($lab)

            $st=New-Object System.Windows.Forms.Label
            $st.Location=New-Object System.Drawing.Point(25,($y+28))
            $st.Size=New-Object System.Drawing.Size(600,25)
            $st.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
            $f.Controls.Add($st)
            [void]$status.Add($st)

            $bt=New-Button $actions[$i] 190
            $bt.Location=New-Object System.Drawing.Point(690,($y+5))
            $f.Controls.Add($bt)
            [void]$buttons.Add($bt)
        }

        $ctx=New-Object System.Windows.Forms.Label
        $ctx.Location=New-Object System.Drawing.Point(25,585)
        $ctx.Size=New-Object System.Drawing.Size(660,28)
        $ctx.Font=$script:FontSemibold9
        $ctx.ForeColor=[System.Drawing.Color]::FromArgb(30,64,90)
        $f.Controls.Add($ctx)

        $btnAtualizar=New-Button 'ATUALIZAR STATUS' 150
        $btnAtualizar.Location=New-Object System.Drawing.Point(590,615)
        $btnAtualizar.Anchor='Bottom,Right'
        $f.Controls.Add($btnAtualizar)

        $close=New-Button 'FECHAR' 120
        $close.Location=New-Object System.Drawing.Point(760,615)
        $close.Anchor='Bottom,Right'
        $close.Add_Click({$f.Close()})
        $f.Controls.Add($close)

        $refresh={
            try {
                $principal=[int](Get-SelectedPrincipalSetorId)
                $hcnt=0
                $v=Db-Scalar "SELECT COUNT(*) FROM horarios WHERE ativo=1;"
                if($null -ne $v){$hcnt=[int]$v}
                $scaleId=[int](Get-ScaleId)
                if($scaleId -gt 0){$script:CurrentScaleId=$scaleId}
                $bcnt=0
                $scnt=0
                $vcnt=0
                if($scaleId -gt 0){
                    $scaleIdSql=Sql-Int $scaleId 'escala_id'
                    $bcnt=[int](Get-ScaleBlockCount $scaleId)
                    $v=Db-Scalar "SELECT COUNT(*) FROM escala_servidores WHERE escala_id=$scaleIdSql AND ativo=1;"
                    if($null -ne $v){$scnt=[int]$v}
                    $v=Db-Scalar "SELECT COUNT(*) FROM escala_vagas WHERE escala_id=$scaleIdSql AND ativo=1;"
                    if($null -ne $v){$vcnt=[int]$v}
                }

                $status[0].Text=$(if($principal -gt 0){'OK - Setor selecionado.'}else{'PENDENTE - selecione ou cadastre um Setor.'})
                $status[1].Text=$(if($hcnt -gt 0){("OK - {0} horario(s) ativo(s)." -f $hcnt)}else{'PENDENTE - cadastre pelo menos um Horario.'})
                $status[2].Text=$(if($scaleId -gt 0){'OK - escala mensal criada/carregada.'}else{'PENDENTE - crie a escala deste mes.'})
                $status[3].Text=$(if($bcnt -gt 0){("OK - {0} bloco(s) configurado(s)." -f $bcnt)}else{'PENDENTE - configure os blocos deste mes.'})
                $status[4].Text=$(if($scnt -gt 0){("OK - {0} servidor(es) incluido(s)." -f $scnt)}else{'PENDENTE - inclua os servidores nos blocos.'})
                $status[5].Text='ROTINA - use apenas o que for necessario no mes.'
                $status[6].Text=$(if(($scnt+$vcnt) -gt 0){'PRONTO - ha conteudo para conferir.'}else{'AGUARDE - inclua servidor ou Escala Vaga.'})

                $buttons[0].Enabled=$true
                $buttons[1].Enabled=($principal -gt 0)
                $buttons[2].Enabled=($principal -gt 0 -and $hcnt -gt 0)
                $buttons[3].Enabled=($scaleId -gt 0)
                $buttons[4].Enabled=($scaleId -gt 0 -and $bcnt -gt 0)
                $buttons[5].Enabled=($scaleId -gt 0 -and $bcnt -gt 0)
                $buttons[6].Enabled=($scaleId -gt 0 -and ($scnt+$vcnt) -gt 0)

                $setTxt=''
                $setTxt=[string]$script:cboSetorEscala.Text
                $subTxt=''
                $subTxt=[string]$script:cboSubSetorEscala.Text
                if($subTxt -and $subTxt -eq '(sem Sub_Setor)'){$subTxt=''}
                $mesTxt=0
                $mesTxt=Get-ComboSelectedInt $script:cboMes 0
                $anoTxt=0
                $anoTxt=[int]$script:numAno.Value
                $ctx.Text=('Contexto atual: {0}{1} | {2:00}/{3}' -f $setTxt,$(if($subTxt){' / '+$subTxt}else{''}),$mesTxt,$anoTxt)
            } catch {
                Show-Error $_.Exception.Message
            }
        }

        $buttons[0].Add_Click({$tabs.SelectedTab=$tabSet;$f.Close()})
        $buttons[1].Add_Click({$tabs.SelectedTab=$tabHor;$f.Close()})
        $buttons[2].Add_Click({
            if((Get-ScaleId) -gt 0){Load-Escala}else{Create-CurrentScale}
            & $refresh
        })
        $buttons[3].Add_Click({Show-ScaleBlocksManager;& $refresh})
        $buttons[4].Add_Click({Show-LotacaoLoteEscalaDialog;& $refresh})
        $buttons[5].Add_Click({$tabs.SelectedTab=$tabEsc;$f.Close()})
        $buttons[6].Add_Click({Show-ScalePreview;& $refresh})
        $btnAtualizar.Add_Click({& $refresh})

        & $refresh
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch {
        Show-Error $_.Exception.Message
    }
}



# V1.0.14.20 - Chave visual de cargo usada para aproximar cada ESCALA VAGA
# do ultimo servidor do mesmo cargo no bloco. Mantem TE e AE separados para
# posicionamento, embora a contagem configurada possa continuar agrupando TE/AE.
function Get-CargoChaveEscala {
    param([string]$Funcao)
    $f=([string]$Funcao).Trim().ToUpperInvariant()
    $f=$f.Replace('.','').Replace('-','').Replace('/','').Replace(' ','')
    if([string]::IsNullOrWhiteSpace($f)){return 'SEM_CARGO'}
    if($f -match 'AUX' -or $f -match '^AE'){return 'AE'}
    if($f -match 'TEC' -or $f -match '^TE'){return 'TE'}
    if($f -match 'ENFERMEIR' -or $f -match '^ENF'){return 'ENF'}
    return $f
}

function Add-EscalaVagaGridRow {
    param(
        $Grid,
        $Vaga,
        [int]$HorarioId,
        [int]$Ano,
        [int]$Mes,
        [hashtable]$CntVaga
    )
    $grp=Get-QtdGrupo ([string]$Vaga['funcao'])
    $qtd=$CntVaga[$grp]
    $CntVaga[$grp]=[int]$CntVaga[$grp]+1
    $ix=$Grid.Rows.Add()
    $vr=$Grid.Rows[$ix]
    $vr.Cells['_TIPO'].Value='VAGA'
    $vr.Cells['_VAGA_ID'].Value=[string]$Vaga['vagaid']
    $vr.Cells['_HORARIO_ID'].Value=$HorarioId
    $vr.Cells['Qtd'].Value=$qtd
    $vr.Cells['Servidor'].Value=[string]$Vaga['descricao']
    $vr.Cells['CP'].Value='***'
    $vr.Cells['Funcao'].Value=[string]$Vaga['funcao']
    $vr.Cells['Coren'].Value='***'
    $vr.DefaultCellStyle.Font=$script:FontSemibold9
    $vr.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(247,247,239)
    $vi=ConvertFrom-DbDateOnly $Vaga['data_inicial']
    $vf=ConvertFrom-DbDateOnly $Vaga['data_final']
    $mf=Get-Date -Year $Ano -Month $Mes -Day 1
    $ml=$mf.AddMonths(1).AddDays(-1)
    if($vi -lt $mf){$vi=$mf}
    if($vf -gt $ml){$vf=$ml}
    if($vf -ge $mf -and $vi -le $ml){
        Set-GridRangeVisual $vr $vi.Day $vf.Day 'ESCALA VAGA' ([System.Drawing.Color]::FromArgb(242,242,235)) ([System.Drawing.Color]::Black)
    }
}

function Add-EscalaVagaPreviewRow {
    param(
        [System.Text.StringBuilder]$Sb,
        $Vaga,
        [hashtable]$CntVaga,
        [datetime]$MonthFirst,
        [datetime]$MonthLast,
        [int]$Dias,
        $Cfg
    )
    $grp=Get-QtdGrupo ([string]$Vaga['funcao'])
    $qtd=$CntVaga[$grp]
    $CntVaga[$grp]=[int]$CntVaga[$grp]+1
    [void]$Sb.AppendLine('<tr class="server-row">')
    $qtdClass='qty'
    if($null -ne $Cfg -and [bool]$Cfg.qtdDestaqueVaga -and (Test-QtdPrintHighlightRow ([string]$Vaga['funcao']) ([string]$Vaga['funcao']) $Cfg)){$qtdClass+=' qtd-destaque'}
    [void]$Sb.AppendLine(('<td class="{0}">{1}</td>' -f $qtdClass,$qtd))
    [void]$Sb.AppendLine(('<td class="vaga-name">{0}</td>' -f (Html-E $Vaga['descricao'])))
    [void]$Sb.AppendLine('<td class="cp">***</td>')
    [void]$Sb.AppendLine(('<td class="role">{0}</td>' -f (Html-E $Vaga['funcao'])))
    [void]$Sb.AppendLine('<td class="coren">***</td>')
    $vi=ConvertFrom-DbDateOnly $Vaga['data_inicial']
    $vf=ConvertFrom-DbDateOnly $Vaga['data_final']
    if($vi -lt $MonthFirst){$vi=$MonthFirst}
    if($vf -gt $MonthLast){$vf=$MonthLast}
    $d=1
    while($d -le $Dias){
        if($d -eq $vi.Day){
            $span=$vf.Day-$vi.Day+1
            [void]$Sb.AppendLine(('<td class="range" colspan="{0}">ESCALA VAGA</td>' -f $span))
            $d=$vf.Day+1
            continue
        }
        [void]$Sb.AppendLine('<td class="day"></td>')
        $d++
    }
    [void]$Sb.AppendLine('</tr>')
}

function Load-Escala {
    $swLoad=[System.Diagnostics.Stopwatch]::StartNew()
    $grid=$script:gridEscala
    try {
        if($null -ne $grid){$grid.SuspendLayout()}
        Load-SiglaCache
        if($null -ne $script:txtBuscaEscala -and $script:txtBuscaEscala.Text){$script:txtBuscaEscala.Text=''}
        $grid.DataSource=$null;$grid.Columns.Clear();$grid.Rows.Clear()
        $sid=Get-SelectedSetorId
        if($sid -le 0){
            if($null -ne $script:pEscVazio){
                $script:lblVazioTitulo.Text='Selecione um Setor'
                $script:lblVazioSub.Text='Escolha o Setor (e o Sub_Setor, se houver) no topo da tela para comecar.'
                $script:btnVazioAcao.Visible=$false
                $script:pEscVazio.Visible=$true;$script:pEscVazio.BringToFront()
            }
            return
        }
        $ano=[int]$script:numAno.Value;$mes=[int]$script:cboMes.SelectedValue
        $scaleId=Get-ScaleId;$script:CurrentScaleId=$scaleId
        $script:lblEscalaStatus.Text = $(if($scaleId){'Escala carregada'}else{'Escala ainda nao criada para este mes'})

        # A tela da Escala passa a seguir a mesma logica da impressao:
        # blocos de horario visiveis e sem coluna Horario por servidor.
        $cols=@(
            @{N='_ID';H='ID';W=1},@{N='_TIPO';H='TIPO';W=1},@{N='_VAGA_ID';H='VAGA';W=1},@{N='_HORARIO_ID';H='HID';W=1},
            @{N='Qtd';H='Qtd';W=48},@{N='Servidor';H='Servidor';W=330},@{N='CP';H='CP';W=70},@{N='Funcao';H='Funcao';W=95},@{N='Coren';H='Coren';W=92}
        )
        foreach($c in $cols){
            $col=New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $col.Name=$c.N;$col.HeaderText=$c.H;$col.Width=$c.W;$col.SortMode='NotSortable'
            if($c.N -like '_*'){$col.Visible=$false}
            $grid.Columns.Add($col)|Out-Null
        }
        foreach($n in @('Qtd','Servidor','CP','Funcao','Coren')){if($grid.Columns.Contains($n)){$grid.Columns[$n].Frozen=$true}}
        $grid.Columns['Qtd'].DefaultCellStyle.Alignment='MiddleCenter'
        $grid.Columns['CP'].DefaultCellStyle.Alignment='MiddleCenter'
        $grid.Columns['Funcao'].DefaultCellStyle.Alignment='MiddleCenter'
        $grid.Columns['Coren'].DefaultCellStyle.Alignment='MiddleCenter'

        $days=[datetime]::DaysInMonth($ano,$mes);$dow=@('DO','SE','TE','QA','QI','SX','SA');$dateByDay=@{}
        $feriadosMes=@{};$fmes=Db-Query ("SELECT data,descricao FROM feriados WHERE data LIKE {0};" -f (Sql-Q ('{0}-{1:00}-%' -f $ano,$mes)));foreach($fr in $fmes.Rows){$feriadosMes[[string]$fr['data']]=[string]$fr['descricao']}
        $destFds=Get-ConfigBool 'calendario_destacar_fds' $true;$destFer=Get-ConfigBool 'calendario_destacar_feriados' $true
        $faixaMap=Get-FaixaTiposAtivos
        for($d=1;$d -le $days;$d++){
            $dt=Get-Date -Year $ano -Month $mes -Day $d
            $dateByDay[$d]=$dt
            $col=New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $col.Name=('D{0:00}' -f $d)
            $col.HeaderText=('{0:00}{1}{2}' -f $d,[Environment]::NewLine,$dow[[int]$dt.DayOfWeek])
            $col.Width=54;$col.SortMode='NotSortable';$col.HeaderCell.Style.Alignment='MiddleCenter';$col.DefaultCellStyle.Alignment='MiddleCenter';$col.DefaultCellStyle.WrapMode='True'
            $isWeek=($dt.DayOfWeek -eq 'Saturday' -or $dt.DayOfWeek -eq 'Sunday');$dateKey=$dt.ToString('yyyy-MM-dd');$isHoliday=$feriadosMes.ContainsKey($dateKey)
            if($isHoliday -and $destFer){$col.HeaderCell.Style.BackColor=[System.Drawing.Color]::FromArgb(215,193,106);$col.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(255,249,218);$col.ToolTipText=$feriadosMes[$dateKey]}
            elseif($isWeek -and $destFds){$col.HeaderCell.Style.BackColor=[System.Drawing.Color]::FromArgb(92,105,117);$col.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(246,247,249)}
            $grid.Columns.Add($col)|Out-Null
        }
        Apply-ScaleDayColumnWidth $grid $days
        if($scaleId -le 0){
            if($null -ne $script:pEscVazio){
                $nomeMes=$script:cboMes.Text
                $script:lblVazioTitulo.Text=('Nenhuma escala criada para {0}/{1}' -f $nomeMes,$ano)
                $script:lblVazioSub.Text='Clique em CRIAR MES para comecar (voce podera copiar os blocos e servidores do mes anterior).'
                $script:btnVazioAcao.Visible=$true
                $script:pEscVazio.Visible=$true;$script:pEscVazio.BringToFront()
            }
            return
        }
        if($null -ne $script:pEscVazio){$script:pEscVazio.Visible=$false}
        $scaleIdSql=Sql-Int $scaleId 'escala_id'
        $syncOccOk=[bool](Ensure-OccurrenceSyncForScale $scaleId)
        $syncCalOk=[bool](Ensure-Calendar08hSyncForScale $scaleId)
        if((-not $syncOccOk) -or (-not $syncCalOk)){
            Write-Log ("ALERTA Load-Escala: sincronizacao incompleta escala={0}; ocorrencias={1}; calendario08h={2}" -f $scaleId,$syncOccOk,$syncCalOk)
            Show-Info 'A escala foi carregada, mas uma sincronizacao automatica falhou. Os dados podem estar desatualizados. Consulte Logs\Sistema_Escala.log antes de imprimir.'
        }

        $syncBlocosOk=[bool](Sync-ScaleBlockOrder $scaleId)
        if(-not $syncBlocosOk){
            Write-Log ("ALERTA Load-Escala: falha ao sincronizar ordem dos blocos, escala={0}" -f $scaleId)
            Show-Info 'A escala foi carregada, mas a ordem dos blocos nao pode ser sincronizada. A grade usara a ordem disponivel; nao imprima antes de corrigir o erro registrado no log.'
        }
        $a=Db-Query "SELECT es.id AS esid,s.cp,s.nome,s.funcao,s.tipo_vinculo,s.sub_funcao,COALESCE(s.coren,'') AS coren,COALESCE(h.id,0) AS horario_id,COALESCE(h.nome,'') AS horario_nome,COALESCE(h.periodo,'') AS horario_periodo,COALESCE(h.regra,'') AS horario_regra,COALESCE(h.descricao,'SEM HORARIO DEFINIDO') AS horario,COALESCE(ebo.ordem,h.ordem,999999) AS horario_ordem,es.ordem FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id LEFT JOIN horarios h ON h.id=es.horario_id LEFT JOIN escala_blocos_ordem ebo ON ebo.escala_id=es.escala_id AND ebo.horario_id=es.horario_id WHERE es.escala_id=$scaleIdSql AND es.ativo=1 ORDER BY COALESCE(ebo.ordem,h.ordem,999999),es.ordem,s.nome;"
        $vagas=Db-Query "SELECT v.id AS vagaid,v.horario_id,COALESCE(h.nome,'') AS horario_nome,COALESCE(h.periodo,'') AS horario_periodo,COALESCE(h.regra,'') AS horario_regra,h.descricao AS horario,COALESCE(ebo.ordem,h.ordem,999999) AS horario_ordem,v.descricao,v.funcao,v.data_inicial,v.data_final,v.ordem FROM escala_vagas v JOIN horarios h ON h.id=v.horario_id LEFT JOIN escala_blocos_ordem ebo ON ebo.escala_id=v.escala_id AND ebo.horario_id=v.horario_id WHERE v.escala_id=$scaleIdSql AND v.ativo=1 ORDER BY COALESCE(ebo.ordem,h.ordem,999999),v.ordem,v.id;"
        $blocosCfg=Db-Query "SELECT h.id AS horario_id,h.nome AS horario_nome,h.periodo AS horario_periodo,COALESCE(h.regra,'') AS horario_regra,COALESCE(h.descricao,'SEM HORARIO DEFINIDO') AS horario,bo.ordem AS horario_ordem FROM escala_blocos_ordem bo JOIN horarios h ON h.id=bo.horario_id WHERE bo.escala_id=$scaleIdSql AND h.ativo=1 ORDER BY bo.ordem,h.nome;"

        $serverGroups=@{};$vagaGroups=@{};$blockInfo=@{}
        # Inclui tambem os blocos configurados que ainda nao possuem servidor ou vaga.
        # A verificacao de tipo evita qualquer erro de propriedade Rows durante a inicializacao.
        if($null -ne $blocosCfg -and $blocosCfg -is [System.Data.DataTable]){
            foreach($b in $blocosCfg.Rows){
                $hid=[int]$b['horario_id']
                $blockInfo[$hid]=@{
                    Descricao=[string]$b['horario']
                    Ordem=[int]$b['horario_ordem']
                    Nome=[string]$b['horario_nome']
                    Periodo=[string]$b['horario_periodo']
                    Regra=[string]$b['horario_regra']
                }
            }
        }
        foreach($r in $a.Rows){
            $hid=[int]$r['horario_id'];if(-not $serverGroups.ContainsKey($hid)){$serverGroups[$hid]=New-Object System.Collections.ArrayList};[void]$serverGroups[$hid].Add($r)
            if(-not $blockInfo.ContainsKey($hid)){$blockInfo[$hid]=@{Descricao=[string]$r['horario'];Ordem=[int]$r['horario_ordem'];Nome=[string]$r['horario_nome'];Periodo=[string]$r['horario_periodo'];Regra=[string]$r['horario_regra']}}
        }
        foreach($v in $vagas.Rows){
            $hid=[int]$v['horario_id'];if(-not $vagaGroups.ContainsKey($hid)){$vagaGroups[$hid]=New-Object System.Collections.ArrayList};[void]$vagaGroups[$hid].Add($v)
            if(-not $blockInfo.ContainsKey($hid)){$blockInfo[$hid]=@{Descricao=[string]$v['horario'];Ordem=[int]$v['horario_ordem'];Nome=[string]$v['horario_nome'];Periodo=[string]$v['horario_periodo'];Regra=[string]$v['horario_regra']}}
        }
        $blockList=@()
        foreach($hid in $blockInfo.Keys){$blockList += [pscustomobject]@{Id=[int]$hid;Ordem=[int]$blockInfo[$hid].Ordem;Descricao=[string]$blockInfo[$hid].Descricao}}
        $blockList=@($blockList | Sort-Object Ordem,Id)
        $maskDN=Get-ConfigBool 'mascara_dn_paridade' $true
        $maskMV=Get-ConfigBool 'mascara_mv_fds_paridade' $true
        $autoPtMV=Get-ConfigBool 'mv_pt_automatico' $true
        $maskGray=[System.Drawing.Color]::FromArgb(224,224,224)

        $rowById=@{}
        $qtdReset=Get-ConfigBool 'qtd_reiniciar_bloco' $true
        $cntGlobal=@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}
        foreach($bl in $blockList){
            $hid=[int]$bl.Id;$desc=[string]$bl.Descricao
            $bi=$blockInfo[$hid]
            $hmeta=Get-HorarioVisualMeta ([string]$bi.Periodo) ([string]$bi.Nome) ([string]$bi.Descricao) ([string]$bi.Regra)
            $desc=Get-CabecalhoAjustadoParidade $desc $hmeta $ano $mes
            # V1.0.14.36 - a mascara depende apenas do bloco e do dia, nao do
            # servidor. Calcula uma vez por bloco e reaproveita em todas as linhas.
            $visualByDay=@{}
            for($vd=1;$vd -le $days;$vd++){$visualByDay[$vd]=Get-HorarioDayVisual $hmeta $dateByDay[$vd] $maskDN $maskMV $autoPtMV}
            $ix=$grid.Rows.Add();$br=$grid.Rows[$ix]
            $br.Cells['_TIPO'].Value='BLOCO';$br.Cells['_HORARIO_ID'].Value=$hid;$br.Cells['Servidor'].Value=$desc
            $br.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(215,219,223)
            $br.DefaultCellStyle.ForeColor=[System.Drawing.Color]::FromArgb(20,30,40)
            $br.DefaultCellStyle.Font=$script:FontSemibold9
            $br.DefaultCellStyle.SelectionBackColor=[System.Drawing.Color]::FromArgb(195,201,207)
            $br.DefaultCellStyle.SelectionForeColor=[System.Drawing.Color]::FromArgb(20,30,40)
            $densLinha=(Get-ConfigValue 'interface_densidade' 'NORMAL').ToUpperInvariant();$br.Height=$(if($densLinha -eq 'COMPACTA'){23}elseif($densLinha -eq 'CONFORTAVEL'){33}else{27});$br.ReadOnly=$true
            foreach($c in $br.Cells){$c.Style.BackColor=$br.DefaultCellStyle.BackColor}

            $cnt=$(if($qtdReset){@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}}else{$cntGlobal})
            # V1.0.14.20 - As vagas deixam de ficar todas no rodape do bloco.
            # Cada cargo e encaixado logo abaixo do ULTIMO servidor do mesmo cargo.
            # Vagas cujo cargo nao possui servidor no bloco permanecem ao final.
            $cntVaga=@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}
            $ultimoServidorCargo=@{}
            $vagasRenderizadas=@{}
            if($serverGroups.ContainsKey($hid)){
                foreach($sr in $serverGroups[$hid]){
                    $ultimoServidorCargo[(Get-CargoChaveEscala ([string]$sr['funcao']))]=[int]$sr['esid']
                }
                foreach($r in $serverGroups[$hid]){
                    $grp=Get-QtdGrupo ([string]$r['funcao']);$qtd=$cnt[$grp];$cnt[$grp]=[int]$cnt[$grp]+1
                    $ix=$grid.Rows.Add();$gr=$grid.Rows[$ix]
                    $gr.Cells['_TIPO'].Value='SERVIDOR';$gr.Cells['_ID'].Value=[string]$r['esid'];$gr.Cells['_HORARIO_ID'].Value=$hid
                    $gr.Cells['Qtd'].Value=$qtd;$gr.Cells['CP'].Value=[string]$r['cp'];$gr.Cells['Servidor'].Value=[string]$r['nome']
                    $gr.Cells['Funcao'].Value=Get-FuncaoExibicao ([string]$r['funcao']) ([string]$r['tipo_vinculo']) ([string]$r['sub_funcao'])
                    $gr.Cells['Coren'].Value=[string]$r['coren']
                    # Mascara visual de paridade conforme o cabecalho do bloco.
                    # D/N: paridade em todos os dias. M/V: paridade somente aos sabados e domingos.
                    for($d=1;$d -le $days;$d++){
                        $vis=$visualByDay[$d]
                        if($vis.Mask){
                            $vc=$gr.Cells[('D{0:00}' -f $d)];$vc.Style.BackColor=$maskGray;$vc.Style.ForeColor=[System.Drawing.Color]::Black
                            if($vis.AutoPT){$vc.Value='PT';$vc.ToolTipText='PT automatico - FDS conforme paridade do cabecalho do horario';$vc.Style.Font=$script:FontSemibold9}
                        }
                    }
                    $rowById[[int]$r['esid']]=$gr

                    $cargoAtual=Get-CargoChaveEscala ([string]$r['funcao'])
                    if($vagaGroups.ContainsKey($hid) -and $ultimoServidorCargo.ContainsKey($cargoAtual) -and [int]$ultimoServidorCargo[$cargoAtual] -eq [int]$r['esid']){
                        foreach($v in $vagaGroups[$hid]){
                            if((Get-CargoChaveEscala ([string]$v['funcao'])) -ne $cargoAtual){continue}
                            Add-EscalaVagaGridRow $grid $v $hid $ano $mes $cntVaga
                            $vagasRenderizadas[[string]$v['vagaid']]=$true
                        }
                    }
                }
            }
            if(-not $qtdReset){$cntGlobal=$cnt}

            if($vagaGroups.ContainsKey($hid)){
                foreach($v in $vagaGroups[$hid]){
                    if($vagasRenderizadas.ContainsKey([string]$v['vagaid'])){continue}
                    Add-EscalaVagaGridRow $grid $v $hid $ano $mes $cntVaga
                    $vagasRenderizadas[[string]$v['vagaid']]=$true
                }
            }
        }

        $dd=Db-Query "SELECT escala_servidor_id,data,sigla,texto,origem,ocorrencia_id FROM escala_dias WHERE escala_servidor_id IN (SELECT id FROM escala_servidores WHERE escala_id=$scaleIdSql AND ativo=1);"
        foreach($r in $dd.Rows){
            $esid=[int]$r['escala_servidor_id'];if(-not $rowById.ContainsKey($esid)){continue}
            try{$dt=ConvertFrom-DbDateOnly $r['data']}catch{Write-Log ('Data invalida ignorada em escala_dias, esid='+$esid+': '+[string]$r['data']+' - '+$_.Exception.Message);continue};$cn=('D{0:00}' -f $dt.Day);$sg=[string]$r['sigla'];$txt=[string]$r['texto'];$display=$(if($sg){$sg}else{$txt});$cell=$rowById[$esid].Cells[$cn]
            $cell.Value=$display;$cell.ToolTipText=$txt
            if($sg -and $script:SiglaCache.ContainsKey($sg)){$cfg=$script:SiglaCache[$sg];$cell.Style.BackColor=Color-FromHex $cfg.Fundo ([System.Drawing.Color]::White);$cell.Style.ForeColor=Color-FromHex $cfg.Fonte ([System.Drawing.Color]::Black);$cell.Style.Font=$script:FontSemibold9}
        }

        # Faixas visuais da tela: identifica diretamente as siglas gravadas na escala
        # que estao marcadas como "faixa continua" (Configuracoes > Ocorrencias).
        foreach($pair in $rowById.GetEnumerator()){
            $gr=$pair.Value
            $d=1
            while($d -le $days){
                $cn=('D{0:00}' -f $d)
                $valor=([string]$gr.Cells[$cn].Value).Trim().ToUpperInvariant()
                if($faixaMap.ContainsKey($valor)){
                    $inicio=$d;$fim=$d
                    while(($fim+1) -le $days){
                        $prox=('D{0:00}' -f ($fim+1))
                        $pv=([string]$gr.Cells[$prox].Value).Trim().ToUpperInvariant()
                        if($pv -ne $valor){break}
                        $fim++
                    }
                    $dur=$fim-$inicio+1
                    $fi=$faixaMap[$valor]
                    if($dur -ge $fi.Dias){
                        Set-GridRangeVisual $gr $inicio $fim $fi.Texto (Color-FromHex $fi.Fundo ([System.Drawing.Color]::FromArgb(238,238,238))) (Color-FromHex $fi.Fonte ([System.Drawing.Color]::Black))
                    }
                    $d=$fim+1
                    continue
                }
                $d++
            }
        }
        # Por fim, aplica as faixas diretamente das Ocorrencias oficiais.
        # Esta camada tem prioridade sobre a leitura de escala_dias e garante que
        # data inicial/final da aba Ocorrencias seja exatamente a faixa mostrada.
        $mf=Get-Date -Year $ano -Month $mes -Day 1;$ml=$mf.AddMonths(1).AddDays(-1)
        $oficiais=Db-Query "SELECT es.id AS esid,t.nome AS tipo,COALESCE(t.sigla,'') AS sigla,COALESCE(NULLIF(TRIM(t.faixa_texto),''),t.nome) AS faixa_texto,COALESCE(t.faixa_dias_minimo,1) AS faixa_dias_minimo,COALESCE(NULLIF(TRIM(t.faixa_cor_fundo),''),'#EEEEEE') AS faixa_cor_fundo,COALESCE(NULLIF(TRIM(t.faixa_cor_fonte),''),'#000000') AS faixa_cor_fonte,o.data_inicial,o.data_final FROM ocorrencias o JOIN tipos_ocorrencia t ON t.id=o.tipo_id JOIN escala_servidores es ON es.servidor_id=o.servidor_id AND es.escala_id=$scaleIdSql AND es.ativo=1 WHERE o.situacao='ATIVA' AND t.ativo=1 AND t.faixa_ativa=1 AND o.data_final >= $(Sql-Q ($mf.ToString('yyyy-MM-dd'))) AND o.data_inicial <= $(Sql-Q ($ml.ToString('yyyy-MM-dd')));"
        foreach($o in $oficiais.Rows){
            $esid=[int]$o['esid'];if(-not $rowById.ContainsKey($esid)){continue}
            try{$ini=ConvertFrom-DbDateOnly $o['data_inicial'];$fim=ConvertFrom-DbDateOnly $o['data_final']}catch{Write-Log ('Periodo invalido ignorado em ocorrencia da tela, esid='+$esid+': '+$_.Exception.Message);continue}
            $durTotalOf=($fim-$ini).Days+1   # V1.0.14.45 - igual a impressao: conta o periodo INTEIRO da ocorrencia
            if($ini -lt $mf){$ini=$mf};if($fim -gt $ml){$fim=$ml};if($fim -lt $ini){continue}
            $diasMinOf=[Math]::Max(1,[int]$o['faixa_dias_minimo'])
            if($durTotalOf -ge $diasMinOf){
                # A ocorrencia oficial usa diretamente as propriedades do TIPO, sem depender da sigla.
                # Assim qualquer tipo marcado como faixa pode ter texto/cores proprios, mesmo sem sigla.
                $textoOf=[string]$o['faixa_texto']
                $bgOf=Color-FromHex (Get-SafeHexColor ([string]$o['faixa_cor_fundo']) '#EEEEEE') ([System.Drawing.Color]::FromArgb(238,238,238))
                $fgOf=Color-FromHex (Get-SafeHexColor ([string]$o['faixa_cor_fonte']) '#000000') ([System.Drawing.Color]::Black)
                Set-GridRangeVisual $rowById[$esid] $ini.Day $fim.Day $textoOf $bgOf $fgOf
            }
        }

        $script:lblEscalaStatus.Text = ('{0} servidor(es) | {1} escala(s) vaga(s) - {2:00}/{3}' -f $a.Rows.Count,$vagas.Rows.Count,$mes,$ano)
    } catch { Show-Error $_.Exception.Message }
    finally {
        if($null -ne $grid){$grid.ResumeLayout($true)}
        $swLoad.Stop();Write-Log ("Load-Escala: $($swLoad.ElapsedMilliseconds) ms")
    }
    Update-ScaleInterfaceInfo

}

function Show-UndoBar {
    param([string]$Message,[hashtable]$UndoData)
    if($null -eq $script:pUndoBar){return}
    $script:LastUndo=$UndoData
    $script:lblUndoMsg.Text=$Message
    $script:pUndoBar.Visible=$true;$script:pUndoBar.BringToFront()
    $script:tmrUndo.Stop();$script:tmrUndo.Start()
}

function Invoke-LastUndo {
    if($null -eq $script:LastUndo){return}
    $u=$script:LastUndo;$script:LastUndo=$null
    $script:tmrUndo.Stop();$script:pUndoBar.Visible=$false
    try{
        if($u.Type -eq 'REMOVE_SERVIDOR'){
            $d=$u.Data
            # V1.0.14.34 - restaura servidor e dias na MESMA conexao/transacao.
            # Nao usa last_insert_rowid(), pois Db-Exec/Db-Scalar abrem conexoes diferentes.
            $sbUndo=New-Object System.Text.StringBuilder
            [void]$sbUndo.AppendLine('BEGIN IMMEDIATE;')
            [void]$sbUndo.AppendLine(("INSERT INTO escala_servidores(escala_id,servidor_id,horario_id,ordem,ativo) VALUES ({0},{1},{2},{3},1) ON CONFLICT(escala_id,servidor_id) DO UPDATE SET horario_id=excluded.horario_id,ordem=excluded.ordem,ativo=1;" -f $d.EscalaId,$d.ServidorId,$d.HorarioId,$d.Ordem))
            foreach($dia in $d.Dias){
                $occUndo=$(if($dia.OcorrenciaId){[string][int]$dia.OcorrenciaId}else{'NULL'})
                [void]$sbUndo.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem,ocorrencia_id) SELECT es.id,{0},{1},{2},{3},{4} FROM escala_servidores es WHERE es.escala_id={5} AND es.servidor_id={6} AND es.ativo=1 LIMIT 1 ON CONFLICT(escala_servidor_id,data) DO UPDATE SET sigla=excluded.sigla,texto=excluded.texto,origem=excluded.origem,ocorrencia_id=excluded.ocorrencia_id,atualizado_em=CURRENT_TIMESTAMP;" -f (Sql-Q $dia.Data),(Sql-Q $dia.Sigla),(Sql-Q $dia.Texto),(Sql-Q $dia.Origem),$occUndo,$d.EscalaId,$d.ServidorId))
            }
            [void]$sbUndo.AppendLine('COMMIT;')
            Db-Exec $sbUndo.ToString()
            $undoOk=[int](Db-Scalar ("SELECT COUNT(*) FROM escala_servidores WHERE escala_id={0} AND servidor_id={1} AND ativo=1;" -f $d.EscalaId,$d.ServidorId))
            if($undoOk -le 0){throw 'A restauracao do servidor nao foi confirmada no banco de dados.'}
            Load-Escala
            Show-Info 'Servidor restaurado na escala.'
        } elseif($u.Type -eq 'DELETE_DIAS'){
            $d=$u.Data
            # Restaura todo o conjunto em uma unica transacao. Antes cada linha
            # usava uma conexao/commit separado e uma falha podia deixar undo parcial.
            $sbUndoDias=New-Object System.Text.StringBuilder
            [void]$sbUndoDias.AppendLine('BEGIN IMMEDIATE;')
            foreach($m in $d.Manual){
                # V1.0.14.38 - FS/FF/PF automaticos (CALENDARIO_*) se regeneram sozinhos; nao viram MANUAL.
                if([string]$m.Origem -like 'CALENDARIO*'){continue}
                [void]$sbUndoDias.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) VALUES ({0},{1},{2},{3},'MANUAL') ON CONFLICT(escala_servidor_id,data) DO UPDATE SET sigla=excluded.sigla,texto=excluded.texto,origem=excluded.origem;" -f $m.EsId,(Sql-Q $m.Data),(Sql-Q $m.Sigla),(Sql-Q $m.Texto)))
            }
            foreach($o in $d.Ocorrencias){
                [void]$sbUndoDias.AppendLine(("INSERT INTO ocorrencias(setor_id,servidor_id,tipo_id,data_inicial,data_final,detalhamento,documento,situacao,origem,texto_escala) VALUES ({0},{1},{2},{3},{4},{5},{6},{7},{8},{9});" -f $o.SetorId,$o.ServidorId,$o.TipoId,(Sql-Q $o.DataInicial),(Sql-Q $o.DataFinal),(Sql-Q $o.Detalhamento),(Sql-Q $o.Documento),(Sql-Q $o.Situacao),(Sql-Q $o.Origem),(Sql-Q $o.TextoEscala)))
            }
            [void]$sbUndoDias.AppendLine('COMMIT;')
            Db-Exec $sbUndoDias.ToString()
            if($d.Ocorrencias.Count -gt 0 -and $script:CurrentScaleId -gt 0){
                $undoSyncOk=[bool](Ensure-OccurrenceSyncForScale $script:CurrentScaleId -Force)
                if(-not $undoSyncOk){Show-Info 'Os dados foram restaurados, mas a sincronizacao das ocorrencias falhou. Consulte o log antes de imprimir.'}
            }
            Load-Escala;Load-Ocorrencias
            Show-Info 'Exclusao desfeita.'
        }
    }catch{Show-Error $_.Exception.Message}
}

function Delete-SelectedScaleDays {
    try {
        $g=$script:gridEscala
        if($null -eq $g -or $g.SelectedCells.Count -eq 0){Show-Info 'Selecione uma ou mais celulas de dias na escala. Use Ctrl ou Shift para selecionar varias.';return}
        $manual=New-Object System.Collections.ArrayList
        $occIds=New-Object 'System.Collections.Generic.HashSet[int]'
        $seen=New-Object 'System.Collections.Generic.HashSet[string]'
        $targets=New-Object System.Collections.ArrayList
        foreach($cell in $g.SelectedCells){
            if($cell.RowIndex -lt 0 -or $cell.ColumnIndex -lt 0){continue}
            $colName=$g.Columns[$cell.ColumnIndex].Name
            if($colName -notmatch '^D\d\d$'){continue}
            $row=$g.Rows[$cell.RowIndex];$tipo=[string]$row.Cells['_TIPO'].Value
            if($tipo -ne 'SERVIDOR'){continue}
            $esid=0;$esid=[int]$row.Cells['_ID'].Value;if($esid -le 0){continue}
            $dia=[int]$colName.Substring(1)
            $dt=Get-Date -Year ([int]$script:numAno.Value) -Month ([int]$script:cboMes.SelectedValue) -Day $dia
            $ds=$dt.ToString('yyyy-MM-dd');$key=('{0}|{1}' -f $esid,$ds)
            if($seen.Add($key)){[void]$targets.Add([pscustomobject]@{EsId=$esid;Data=$ds;Key=$key})}
        }
        if($targets.Count -gt 0){
            # Uma unica leitura para todas as celulas selecionadas. A versao anterior
            # abria uma conexao SQLite por celula, ficando lenta em selecoes grandes.
            $clauses=New-Object System.Collections.ArrayList
            foreach($tgt in $targets){[void]$clauses.Add(("(escala_servidor_id={0} AND data={1})" -f $tgt.EsId,(Sql-Q $tgt.Data)))}
            $q=Db-Query ("SELECT escala_servidor_id,data,origem,COALESCE(ocorrencia_id,0) AS ocorrencia_id,sigla,texto FROM escala_dias WHERE " + ($clauses -join ' OR ') + ';')
            foreach($r in $q.Rows){
                $esid=[int]$r['escala_servidor_id'];$ds=[string]$r['data'];$orig=[string]$r['origem'];$oid=[int]$r['ocorrencia_id']
                if($orig -eq 'OCORRENCIA' -and $oid -gt 0){[void]$occIds.Add($oid)}
                else{[void]$manual.Add([pscustomobject]@{EsId=$esid;Data=$ds;Sigla=[string]$r['sigla'];Texto=[string]$r['texto'];Origem=$orig})}
            }
        }
        if($manual.Count -eq 0 -and $occIds.Count -eq 0){Show-Info 'Nenhuma sigla/lancamento foi encontrada nas celulas selecionadas.';return}
        if($occIds.Count -gt 0){
            $idsCheck=($occIds -join ',')
            $qDef=[int](Db-Scalar "SELECT COUNT(*) FROM escala_vagas WHERE ocorrencia_id IN ($idsCheck) AND ativo=1;")
            if($qDef -gt 0){Show-Info 'A selecao inclui uma ocorrencia definitiva. Para preservar o vinculo com a Escala Vaga e reativar o servidor corretamente, exclua essa ocorrencia pela aba Ocorrencias.';return}
        }
        $msg="Excluir os lancamentos selecionados?`r`n`r`nLancamentos manuais/dias: $($manual.Count)"
        if($occIds.Count -gt 0){
            $msg+="`r`nOcorrencias vinculadas: $($occIds.Count)`r`n`r`nIMPORTANTE: para manter a sincronizacao, qualquer ocorrencia atingida sera excluida INTEIRA (por exemplo, todas as Ferias daquele periodo)."
        }
        if(-not(Confirm-Action $msg)){return}

        # Backup para o "Desfazer": ocorrencias inteiras (todas as colunas) e os
        # lancamentos manuais atingidos, para poder recriar tudo se for engano.
        $ocorrenciasBackup=New-Object System.Collections.ArrayList
        if($occIds.Count -gt 0){
            $idsTxt=($occIds -join ',')
            $oq=Db-Query "SELECT setor_id,servidor_id,tipo_id,data_inicial,data_final,detalhamento,documento,situacao,origem,texto_escala FROM ocorrencias WHERE id IN ($idsTxt);"
            foreach($or in $oq.Rows){[void]$ocorrenciasBackup.Add([pscustomobject]@{SetorId=[int]$or['setor_id'];ServidorId=[int]$or['servidor_id'];TipoId=[int]$or['tipo_id'];DataInicial=[string]$or['data_inicial'];DataFinal=[string]$or['data_final'];Detalhamento=[string]$or['detalhamento'];Documento=[string]$or['documento'];Situacao=[string]$or['situacao'];Origem=[string]$or['origem'];TextoEscala=[string]$or['texto_escala']})}
        }
        $manualBackup=New-Object System.Collections.ArrayList
        foreach($m in $manual){[void]$manualBackup.Add([pscustomobject]@{EsId=$m.EsId;Data=$m.Data;Sigla=$m.Sigla;Texto=$m.Texto;Origem=$m.Origem})}

        $sql=New-Object System.Text.StringBuilder;[void]$sql.AppendLine('BEGIN;')
        foreach($m in $manual){[void]$sql.AppendLine(("DELETE FROM escala_dias WHERE escala_servidor_id={0} AND data={1} AND origem<>'OCORRENCIA';" -f $m.EsId,(Sql-Q $m.Data)))}
        foreach($oid in $occIds){[void]$sql.AppendLine(("DELETE FROM escala_dias WHERE ocorrencia_id={0}; DELETE FROM ocorrencias WHERE id={0};" -f $oid))}
        [void]$sql.AppendLine('COMMIT;');Db-Exec $sql.ToString()
        Load-Escala;Load-Ocorrencias
        Show-UndoBar ("Exclusao concluida: {0} dia(s) manual(is), {1} ocorrencia(s)" -f $manual.Count,$occIds.Count) @{Type='DELETE_DIAS';Data=@{Manual=$manualBackup;Ocorrencias=$ocorrenciasBackup}}
    } catch { Show-Error $_.Exception.Message }
}


# Retorna as celulas de dias selecionadas que pertencem a linhas de servidores.
# Cada alvo carrega o ID da escala_servidor, a data e a propria celula da grade.
function Get-SelectedScaleDayTargets {
    param([System.Windows.Forms.DataGridView]$Grid)
    $result=New-Object System.Collections.ArrayList
    if($null -eq $Grid){return $result}
    $seen=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($cell in $Grid.SelectedCells){
        if($cell.RowIndex -lt 0 -or $cell.ColumnIndex -lt 0){continue}
        $colName=$Grid.Columns[$cell.ColumnIndex].Name
        if($colName -notmatch '^D\d\d$'){continue}
        $row=$Grid.Rows[$cell.RowIndex]
        if([string]$row.Cells['_TIPO'].Value -ne 'SERVIDOR'){continue}
        $esid=0;$esid=[int]$row.Cells['_ID'].Value;if($esid -le 0){continue}
        $dia=[int]$colName.Substring(1)
        $dt=Get-Date -Year ([int]$script:numAno.Value) -Month ([int]$script:cboMes.SelectedValue) -Day $dia
        $ds=$dt.ToString('yyyy-MM-dd')
        $key=('{0}|{1}' -f $esid,$ds)
        if(-not $seen.Add($key)){continue}
        [void]$result.Add([pscustomobject]@{EsId=$esid;Data=$ds;Cell=$cell})
    }
    return $result
}

# Aplica uma sigla rapida em todas as celulas de dias selecionadas.
# Usa uma unica transacao e atualiza a grade sem recarregar toda a escala.
function Get-SiglaDateRuleError {
    # V1.0.14.35 - regra unica para FF/PF/FS em qualquer caminho de lancamento
    # manual. Retorna texto vazio quando a sigla pode ser aplicada nessa data.
    param([string]$Sigla,[datetime]$Date,[hashtable]$FeriadoTipoMap=$null)
    $sig=([string]$Sigla).Trim().ToUpperInvariant()
    if($sig -notin @('FF','PF','FS')){return ''}
    $ds=$Date.ToString('yyyy-MM-dd')
    if($sig -eq 'FS'){
        if($Date.DayOfWeek -ne [System.DayOfWeek]::Saturday -and $Date.DayOfWeek -ne [System.DayOfWeek]::Sunday){
            return 'FS (Folga Semana) so pode ser aplicado aos sabados e domingos.'
        }
        return ''
    }
    $tipo=''
    if($null -ne $FeriadoTipoMap -and $FeriadoTipoMap.ContainsKey($ds)){
        $tipo=[string]$FeriadoTipoMap[$ds]
    }else{
        $v=Db-Scalar ("SELECT COALESCE(tipo,'FERIADO') FROM feriados WHERE data={0} LIMIT 1;" -f (Sql-Q $ds))
        if($null -ne $v){$tipo=[string]$v}
    }
    $tipo=$tipo.Trim().ToUpperInvariant()
    if($sig -eq 'FF' -and $tipo -ne 'FERIADO'){
        return 'FF (Folga Feriado) so pode ser aplicado em um dia cadastrado como Feriado no Calendario.'
    }
    if($sig -eq 'PF' -and $tipo -ne 'PONTO_FACULTATIVO'){
        return 'PF (Ponto Facultativo) so pode ser aplicado em um dia cadastrado como Ponto Facultativo no Calendario.'
    }
    return ''
}

function Apply-QuickSiglaToSelection {
    param([string]$Sigla)
    try{
        $sw=[System.Diagnostics.Stopwatch]::StartNew()
        $sig=([string]$Sigla).Trim().ToUpperInvariant()
        if([string]::IsNullOrWhiteSpace($sig)){return}
        if($sig -in @('FER','AT')){Show-Info 'FERIAS e ATESTADO devem ser registrados pela aba Ocorrencias.';return}
        if($script:SiglaCache.Count -eq 0){Load-SiglaCache}
        if(-not $script:SiglaCache.ContainsKey($sig)){Show-Info ('Sigla nao encontrada ou inativa: ' + $sig);return}
        $targets=@(Get-SelectedScaleDayTargets $script:gridEscala)
        if($targets.Count -eq 0){Show-Info 'Selecione uma ou mais celulas de dias de um servidor.';return}

        # Descobre em uma unica consulta quais alvos estao protegidos por Ocorrencia.
        $whereParts=New-Object System.Collections.ArrayList
        foreach($t in $targets){[void]$whereParts.Add(('(escala_servidor_id={0} AND data={1})' -f $t.EsId,(Sql-Q $t.Data)))}
        $blockedSet=New-Object 'System.Collections.Generic.HashSet[string]'
        if($whereParts.Count -gt 0){
            $q=Db-Query ('SELECT escala_servidor_id,data FROM escala_dias WHERE origem=''OCORRENCIA'' AND (' + ($whereParts -join ' OR ') + ');')
            foreach($r in $q.Rows){[void]$blockedSet.Add(('{0}|{1}' -f [int]$r['escala_servidor_id'],[string]$r['data']))}
        }
        # V1.0.14.37 - pre-verifica tambem direto na tabela de ocorrencias (mesma regra do gatilho:
        # so tipos que geram escala). Assim nenhum dia protegido chega ao INSERT e o lote nao aborta.
        try{
            $esIdsQ=@($targets | ForEach-Object{[int]$_.EsId} | Sort-Object -Unique)
            $dMinQ=(@($targets | ForEach-Object{[string]$_.Data} | Sort-Object)[0])
            $dMaxQ=(@($targets | ForEach-Object{[string]$_.Data} | Sort-Object)[-1])
            $qOc=Db-Query (("SELECT es.id AS esid,substr(o.data_inicial,1,10) AS di,substr(o.data_final,1,10) AS df FROM ocorrencias o JOIN tipos_ocorrencia tq ON tq.id=o.tipo_id JOIN escala_servidores es ON es.servidor_id=o.servidor_id WHERE o.situacao='ATIVA' AND tq.gera_escala=1 AND COALESCE(tq.sigla,'')<>'' AND es.id IN ({0}) AND substr(o.data_final,1,10)>={1} AND substr(o.data_inicial,1,10)<={2};") -f ($esIdsQ -join ','),(Sql-Q $dMinQ),(Sql-Q $dMaxQ))
            foreach($ro in $qOc.Rows){
                foreach($tg in $targets){
                    if([int]$tg.EsId -eq [int]$ro['esid'] -and [string]::CompareOrdinal([string]$tg.Data,[string]$ro['di']) -ge 0 -and [string]::CompareOrdinal([string]$tg.Data,[string]$ro['df']) -le 0){
                        [void]$blockedSet.Add(('{0}|{1}' -f [int]$tg.EsId,[string]$tg.Data))
                    }
                }
            }
        }catch{Write-Log ('Pre-verificacao de ocorrencias no menu rapido falhou: '+$_.Exception.Message)}

        # V1.0.14.35 - FF/PF/FS usam a mesma funcao de regra do editor do dia
        # e do Calendario. O mapa de feriados e pre-carregado aqui para nao consultar
        # o SQLite repetidamente quando varias celulas/servidores sao selecionados.
        $regraMotivo=@{
            'FF'='FF (Folga Feriado) so pode ser aplicado em um dia cadastrado como Feriado no Calendario.'
            'PF'='PF (Ponto Facultativo) so pode ser aplicado em um dia cadastrado como Ponto Facultativo no Calendario.'
            'FS'='FS (Folga Semana) so pode ser aplicado aos sabados e domingos.'
        }
        $feriadoMap=@{}
        if($sig -eq 'FF' -or $sig -eq 'PF'){
            $datasUnicas=@($targets | Select-Object -ExpandProperty Data -Unique)
            if($datasUnicas.Count -gt 0){
                $inClause=(($datasUnicas | ForEach-Object{Sql-Q $_}) -join ',')
                $fq=Db-Query ("SELECT data,COALESCE(tipo,'FERIADO') AS tipo FROM feriados WHERE data IN ($inClause);")
                foreach($fr in $fq.Rows){$feriadoMap[[string]$fr['data']]=[string]$fr['tipo']}
            }
        }

        $cfg=$script:SiglaCache[$sig]
        $desc=[string]$cfg.Descricao
        $sql=New-Object System.Text.StringBuilder
        [void]$sql.AppendLine('BEGIN;')
        $applied=New-Object System.Collections.ArrayList
        $blocked=0
        $blockedRegra=0
        foreach($t in $targets){
            $key=('{0}|{1}' -f $t.EsId,$t.Data)
            if($blockedSet.Contains($key)){$blocked++;continue}
            if($sig -in @('FF','PF','FS')){
                $dtRegra=[datetime]::ParseExact($t.Data,'yyyy-MM-dd',[System.Globalization.CultureInfo]::InvariantCulture)
                $erroRegra=Get-SiglaDateRuleError $sig $dtRegra $feriadoMap
                if(-not [string]::IsNullOrWhiteSpace([string]$erroRegra)){$blockedRegra++;continue}
            }
            [void]$sql.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) VALUES ({0},{1},{2},{3},'MANUAL') ON CONFLICT(escala_servidor_id,data) DO UPDATE SET sigla=excluded.sigla,texto=excluded.texto,origem='MANUAL',ocorrencia_id=NULL,atualizado_em=CURRENT_TIMESTAMP WHERE escala_dias.origem<>'OCORRENCIA';" -f $t.EsId,(Sql-Q $t.Data),(Sql-Q $sig),(Sql-Q $desc)))
            [void]$applied.Add($t)
        }
        [void]$sql.AppendLine('COMMIT;')
        if($applied.Count -gt 0){Db-Exec $sql.ToString()}

        # Atualizacao local da grade: evita o custo de Load-Escala a cada sigla.
        $bg=Color-FromHex ([string]$cfg.Fundo) ([System.Drawing.Color]::White)
        $fg=Color-FromHex ([string]$cfg.Fonte) ([System.Drawing.Color]::Black)
        foreach($t in $applied){
            $t.Cell.Tag=$null
            $t.Cell.Value=$sig
            $t.Cell.ToolTipText=$desc
            $t.Cell.Style.BackColor=$bg
            $t.Cell.Style.ForeColor=$fg
            $t.Cell.Style.Font=$script:FontSemibold9
            $t.Cell.Style.Alignment='MiddleCenter'
        }
        $sw.Stop()
        $msg=('{0} aplicado em {1} dia(s)' -f $sig,$applied.Count)
        if($blocked -gt 0){$msg+=(' | {0} protegido(s) por Ocorrencia' -f $blocked)}
        if($blockedRegra -gt 0){$msg+=(' | {0} ignorado(s) por regra' -f $blockedRegra)}
        $script:lblEscalaStatus.Text=$msg
        Write-Log ("Menu rapido: sigla=$sig aplicados=$($applied.Count) bloqueados=$blocked ignorados_regra=$blockedRegra tempo=$($sw.ElapsedMilliseconds)ms")
        if($applied.Count -eq 0 -and $blockedRegra -gt 0 -and $blocked -eq 0){
            $motivo=$(if($regraMotivo.ContainsKey($sig)){$regraMotivo[$sig]}else{'Este dia nao atende a regra da sigla.'})
            Show-Info $motivo
        } elseif($applied.Count -eq 0 -and $blocked -gt 0){Show-Info 'Todos os dias selecionados estao protegidos por Ocorrencias. Edite a ocorrencia na aba Ocorrencias.'}
    }catch{Show-Error $_.Exception.Message}
}

# Abre o editor completo da celula atual para texto livre ou siglas fora do menu rapido.
function Open-CurrentDayEditor {
    try{
        $g=$script:gridEscala
        if($null -eq $g -or $null -eq $g.CurrentCell){return}
        $cell=$g.CurrentCell
        if($cell.RowIndex -lt 0 -or $cell.ColumnIndex -lt 0){return}
        $row=$g.Rows[$cell.RowIndex]
        if([string]$row.Cells['_TIPO'].Value -ne 'SERVIDOR'){return}
        $name=$g.Columns[$cell.ColumnIndex].Name
        if($name -notmatch '^D\d\d$'){return}
        $esid=[int]$row.Cells['_ID'].Value
        $day=[int]$name.Substring(1)
        $dt=Get-Date -Year ([int]$script:numAno.Value) -Month ([int]$script:cboMes.SelectedValue) -Day $day
        Show-DiaDialog $esid $dt
    }catch{Show-Error $_.Exception.Message}
}

# Inclusao local em lote. Esta rotina pertence somente a Escala Mensal e nao consulta o Gerenciamento Geral.
function Show-LotacaoLoteEscalaDialog {
    param([int]$HorarioIdPreSelecionado=0)
    if($script:CurrentScaleId -le 0){Show-Info 'PASSO 3: crie ou carregue a escala do mes primeiro.';return}
    if((Get-ScaleBlockCount $script:CurrentScaleId) -le 0){Show-Info 'PASSO 4: configure primeiro os blocos de horario desta escala.';Show-ScaleBlocksManager;return}
    $scale=Db-Query ("SELECT e.ano,e.mes,se.nome AS setor FROM escalas e JOIN setores se ON se.id=e.setor_id WHERE e.id={0};" -f $script:CurrentScaleId)
    if($scale.Rows.Count -eq 0){Show-Info 'Nao foi possivel identificar a escala atual.';return}
    $sr=$scale.Rows[0]
    # V1.0.14.21.10 - guarda ano/mes uma unica vez para a consulta da lista em lote.
    # Evita subconsultas repetidas para cada servidor e preserva exatamente a mesma regra de exclusao mensal.
    $anoLote=[int]$sr['ano'];$mesLote=[int]$sr['mes']
    $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text='Lotacao em Lote - Escala Mensal';$f.StartPosition='CenterParent';$f.ClientSize=[Drawing.Size]::new(1000,760);$f.MinimumSize=[Drawing.Size]::new(880,680)

    $title=New-Object System.Windows.Forms.Label;$title.Text=('Escala: {0} - {1:00}/{2}' -f ([string]$sr['setor']),([int]$sr['mes']),([int]$sr['ano']));$title.Location=[Drawing.Point]::new(20,16);$title.Size=[Drawing.Size]::new(930,26);$title.Font=$script:FontSemibold9;$f.Controls.Add($title)
    $help=New-Object System.Windows.Forms.Label;$help.Text='Selecione varios servidores e um bloco. A inclusao vale somente para esta escala mensal. Para corrigir dados de um servidor filtrado, selecione a linha e use EDITAR SERVIDOR (ou duplo clique). Um servidor ja escalado em outro Setor/Sub_Setor neste mesmo mes nao aparece na lista.';$help.Location=[Drawing.Point]::new(20,45);$help.Size=[Drawing.Size]::new(930,38);$help.ForeColor=[Drawing.Color]::FromArgb(70,85,100);$f.Controls.Add($help)

    $labBusca=New-Object System.Windows.Forms.Label;$labBusca.Text='Pesquisar CP(s) / Nome(s) / Coren';$labBusca.Location=[Drawing.Point]::new(20,91);$labBusca.Size=[Drawing.Size]::new(220,22);$f.Controls.Add($labBusca)
    $txt=New-Object System.Windows.Forms.TextBox;$txt.Location=[Drawing.Point]::new(245,88);$txt.Size=[Drawing.Size]::new(320,26);$f.Controls.Add($txt)
    $tipBusca=New-Object System.Windows.Forms.ToolTip;$tipBusca.SetToolTip($txt,'Use virgula para varios termos. Numeros = CP/Coren exato. Textos = parte do nome. Ex.: 311, 787, Ana Maria, Adalberto.')
    $btnPesq=New-Button 'PESQUISAR' 110;$btnPesq.Location=[Drawing.Point]::new(575,86);$f.Controls.Add($btnPesq)
    $btnTodos=New-Button 'SELECIONAR TODOS' 145;$btnTodos.Location=[Drawing.Point]::new(695,86);$f.Controls.Add($btnTodos)
    $btnLimpar=New-Button 'LIMPAR SELECAO' 135;$btnLimpar.Location=[Drawing.Point]::new(850,86);$f.Controls.Add($btnLimpar)

    $grid=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $grid;$grid.Location=[Drawing.Point]::new(20,128);$grid.Size=[Drawing.Size]::new(950,390);$grid.Anchor='Top,Bottom,Left,Right';$grid.SelectionMode='FullRowSelect';$grid.MultiSelect=$true;$grid.ReadOnly=$true;$grid.AllowUserToAddRows=$false;
    # V1.0.14.21.10 - nesta lista podem existir centenas de servidores.
    # AutoSizeRowsMode=AllCells mede todas as linhas antes de mostrar a janela e era uma das maiores causas da demora.
    # Altura fixa afeta somente esta grade visual, nao altera dados nem a grade principal da Escala.
    $grid.AutoSizeRowsMode='None';$grid.RowTemplate.Height=23;$f.Controls.Add($grid)
    $lbl=New-Object System.Windows.Forms.Label;$lbl.Location=[Drawing.Point]::new(20,526);$lbl.Size=[Drawing.Size]::new(610,24);$lbl.Anchor='Bottom,Left';$f.Controls.Add($lbl)
    # V1.0.14.32 - permite corrigir individualmente o cadastro de qualquer
    # servidor exibido/filtrado sem sair do fluxo de inclusao em lote.
    $btnEditarSrvLote=New-Button 'EDITAR SERVIDOR' 155;$btnEditarSrvLote.Location=[Drawing.Point]::new(815,522);$btnEditarSrvLote.Anchor='Bottom,Right';$f.Controls.Add($btnEditarSrvLote)
    $tipEditarSrvLote=New-Object System.Windows.Forms.ToolTip;$tipEditarSrvLote.SetToolTip($btnEditarSrvLote,'Edita somente o servidor da linha atual. Depois a lista e atualizada mantendo o filtro digitado.')


    $labH=New-Object System.Windows.Forms.Label;$labH.Text='Bloco / Horario';$labH.Location=[Drawing.Point]::new(20,565);$labH.Size=[Drawing.Size]::new(110,22);$labH.Anchor='Bottom,Left';$f.Controls.Add($labH)
    $cbH=New-Object System.Windows.Forms.ComboBox;$cbH.Location=[Drawing.Point]::new(135,562);$cbH.Size=[Drawing.Size]::new(500,26);$cbH.Anchor='Bottom,Left,Right';$cbH.DropDownStyle='DropDownList';$hh=Db-Query "SELECT h.id,h.descricao FROM escala_blocos_ordem bo JOIN horarios h ON h.id=bo.horario_id WHERE bo.escala_id=$script:CurrentScaleId AND h.ativo=1 ORDER BY bo.ordem,h.nome;";$bsTmp3=New-Object System.Windows.Forms.BindingSource;$bsTmp3.DataSource=$hh;$cbH.DataSource=$bsTmp3;$cbH.ValueMember='id';$cbH.DisplayMember='descricao';$f.Controls.Add($cbH)

    # V1.0.14.21.12 - opcao de lancar a mesma ocorrencia (ex.: "AVERIGUAR
    # SITUACAO JUNTO AO RH") para todos os servidores incluidos neste lote de
    # uma vez, em vez de abrir Nova Ocorrencia um por um. So cria a ocorrencia
    # para quem realmente entrou na escala (nao para quem foi ignorado por
    # conflito). Nao mexe na logica de inclusao na escala em si.
    $chkOcLote=New-Object System.Windows.Forms.CheckBox;$chkOcLote.Text='Tambem lancar uma ocorrencia para todos os incluidos neste lote';$chkOcLote.Location=[Drawing.Point]::new(20,600);$chkOcLote.Size=[Drawing.Size]::new(560,24);$chkOcLote.Anchor='Bottom,Left';$f.Controls.Add($chkOcLote)

    $labTipoLote=New-Object System.Windows.Forms.Label;$labTipoLote.Text='Tipo';$labTipoLote.Location=[Drawing.Point]::new(20,634);$labTipoLote.Size=[Drawing.Size]::new(40,22);$labTipoLote.Anchor='Bottom,Left';$f.Controls.Add($labTipoLote)
    $cbTipoLote=New-Object System.Windows.Forms.ComboBox;$cbTipoLote.Location=[Drawing.Point]::new(65,631);$cbTipoLote.Size=[Drawing.Size]::new(320,26);$cbTipoLote.Anchor='Bottom,Left';$cbTipoLote.DropDownStyle='DropDownList'
    $tpLote=Db-Query "SELECT id,nome || CASE WHEN COALESCE(sigla,'')<>'' THEN ' ['||sigla||']' ELSE '' END AS item FROM tipos_ocorrencia WHERE ativo=1 AND UPPER(nome)<>'ESCALA VAGA' ORDER BY nome;"
    $bsTmpLote=New-Object System.Windows.Forms.BindingSource;$bsTmpLote.DataSource=$tpLote;$cbTipoLote.DataSource=$bsTmpLote;$cbTipoLote.ValueMember='id';$cbTipoLote.DisplayMember='item'
    $f.Controls.Add($cbTipoLote)
    $labIniLote=New-Object System.Windows.Forms.Label;$labIniLote.Text='De';$labIniLote.Location=[Drawing.Point]::new(400,634);$labIniLote.Size=[Drawing.Size]::new(28,22);$labIniLote.Anchor='Bottom,Left';$f.Controls.Add($labIniLote)
    $dtIniLote=New-Object System.Windows.Forms.DateTimePicker;$dtIniLote.Location=[Drawing.Point]::new(430,631);$dtIniLote.Size=[Drawing.Size]::new(115,26);$dtIniLote.Format='Short';$dtIniLote.Anchor='Bottom,Left';$f.Controls.Add($dtIniLote)
    $labFimLote=New-Object System.Windows.Forms.Label;$labFimLote.Text='Ate';$labFimLote.Location=[Drawing.Point]::new(555,634);$labFimLote.Size=[Drawing.Size]::new(28,22);$labFimLote.Anchor='Bottom,Left';$f.Controls.Add($labFimLote)
    $dtFimLote=New-Object System.Windows.Forms.DateTimePicker;$dtFimLote.Location=[Drawing.Point]::new(585,631);$dtFimLote.Size=[Drawing.Size]::new(115,26);$dtFimLote.Format='Short';$dtFimLote.Anchor='Bottom,Left';$f.Controls.Add($dtFimLote)
    $dtIniLote.Value=Get-Date -Year $anoLote -Month $mesLote -Day 1
    $dtFimLote.Value=(Get-Date -Year $anoLote -Month $mesLote -Day 1).AddMonths(1).AddDays(-1)
    $tipOcLote=New-Object System.Windows.Forms.ToolTip;$tipOcLote.SetToolTip($chkOcLote,'Cria ocorrencias para os servidores incluidos. Tipo e De/Ate abaixo sao o padrao; use OCORRENCIA POR SERVIDOR para ajustar Tipo e/ou datas de quem precisar.')

    # V1.0.14.21.15 - ajustes individuais da ocorrencia opcional em lote.
    # O mapa fica guardado no Tag do formulario principal para permanecer acessivel
    # tambem aos eventos da janela filha. Isso evita que closures aninhadas recebam
    # uma referencia nula e elimina o erro "Nao e possivel indexar em uma matriz nula".
    # Chave = servidor_id (string). Cada ajuste pode ter TipoId, TipoTexto, Ini e Fim.
    $periodosIndividuais=@{}
    $estadoOcLote=New-Object PSObject -Property @{ Periodos=$periodosIndividuais; IncluirAposPersonalizacao=$false }
    $f.Tag=$estadoOcLote

    $btnDatasInd=New-Button 'OCORRENCIA POR SERVIDOR...' 220
    $btnDatasInd.Location=[Drawing.Point]::new(730,628)
    $btnDatasInd.Anchor='Bottom,Right'
    $btnDatasInd.Enabled=$false
    $f.Controls.Add($btnDatasInd)
    $tipOcLote.SetToolTip($btnDatasInd,'Permite definir Tipo e datas De/Ate diferentes para cada servidor selecionado. Quem nao for personalizado continua usando o Tipo e periodo padrao desta tela.')

    $atualizaTextoDatasInd={
        $qtdPers=0
        $mapPers=$null
        $mapPers=$f.Tag.Periodos
        if($null -ne $mapPers){
            foreach($k in @($mapPers.Keys)){
                if($mapPers.ContainsKey($k)){$qtdPers++}
            }
        }
        if($qtdPers -gt 0){$btnDatasInd.Text=('OCORRENCIA POR SERVIDOR ({0})...' -f $qtdPers)}
        else{$btnDatasInd.Text='OCORRENCIA POR SERVIDOR...'}
    }

    $chkOcLote.Add_CheckedChanged({
        $hab=[bool]$chkOcLote.Checked
        $cbTipoLote.Enabled=$hab
        $dtIniLote.Enabled=$hab
        $dtFimLote.Enabled=$hab
        $btnDatasInd.Enabled=$hab
    }.GetNewClosure())
    # Inicialmente a opcao de ocorrencia vem desmarcada.
    $cbTipoLote.Enabled=$false;$dtIniLote.Enabled=$false;$dtFimLote.Enabled=$false

    $btnDatasInd.Add_Click({
        try{
            $selecionados=@()
            foreach($r in $grid.SelectedRows){
                $sid=[int]$r.Cells['id'].Value
                if($sid -gt 0){
                    $selecionados+=New-Object PSObject -Property @{
                        id=$sid
                        CP=[string]$r.Cells['CP'].Value
                        Nome=[string]$r.Cells['Nome'].Value
                    }
                }
            }
            $selecionados=@($selecionados | Sort-Object Nome -Unique)
            if($selecionados.Count -eq 0){
                Show-Info 'Selecione primeiro os servidores na lista. Depois clique em OCORRENCIA POR SERVIDOR.'
                return
            }

            $fp=New-Object System.Windows.Forms.Form
            Set-FormTheme $fp
            $fp.Text='Ocorrencia individual por servidor - lote'
            $fp.StartPosition='CenterParent'
            $fp.ClientSize=[Drawing.Size]::new(920,620)
            $fp.MinimumSize=[Drawing.Size]::new(840,580)
            # Compartilha explicitamente o mesmo estado da janela principal.
            $fp.Tag=$f.Tag

            $lp=New-Object System.Windows.Forms.Label
            $lp.Text='Cada servidor usa o Tipo e periodo padrao do lote, salvo quando voce personalizar. Ajuste Tipo/De/Ate e use APLICAR A ESTE SERVIDOR. Ao terminar, voce pode incluir todos os selecionados diretamente nesta janela.'
            $lp.Location=[Drawing.Point]::new(20,18)
            $lp.Size=[Drawing.Size]::new(870,42)
            $lp.ForeColor=[Drawing.Color]::FromArgb(70,85,100)
            $fp.Controls.Add($lp)

            $gp=New-Object System.Windows.Forms.DataGridView
            Set-GridStyle $gp
            $gp.Location=[Drawing.Point]::new(20,68)
            $gp.Size=[Drawing.Size]::new(880,350)
            $gp.Anchor='Top,Bottom,Left,Right'
            $gp.SelectionMode='FullRowSelect'
            $gp.MultiSelect=$false
            $gp.ReadOnly=$true
            $gp.AllowUserToAddRows=$false
            $gp.AutoGenerateColumns=$false
            $gp.AutoSizeRowsMode='None'
            $gp.RowTemplate.Height=23

            $colId=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colId.Name='id';$colId.DataPropertyName='id';$colId.Visible=$false;[void]$gp.Columns.Add($colId)
            $colCp=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colCp.Name='CP';$colCp.HeaderText='CP';$colCp.DataPropertyName='CP';$colCp.Width=80;[void]$gp.Columns.Add($colCp)
            $colNome=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colNome.Name='Nome';$colNome.HeaderText='Servidor';$colNome.DataPropertyName='Nome';$colNome.AutoSizeMode='Fill';$colNome.MinimumWidth=250;[void]$gp.Columns.Add($colNome)
            $colTipo=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colTipo.Name='Tipo';$colTipo.HeaderText='Tipo';$colTipo.DataPropertyName='Tipo';$colTipo.Width=210;[void]$gp.Columns.Add($colTipo)
            $colDe=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colDe.Name='De';$colDe.HeaderText='De';$colDe.DataPropertyName='De';$colDe.Width=100;[void]$gp.Columns.Add($colDe)
            $colAte=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colAte.Name='Ate';$colAte.HeaderText='Ate';$colAte.DataPropertyName='Ate';$colAte.Width=100;[void]$gp.Columns.Add($colAte)
            $colModo=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$colModo.Name='Modo';$colModo.HeaderText='Periodo';$colModo.DataPropertyName='Modo';$colModo.Width=105;[void]$gp.Columns.Add($colModo)
            $fp.Controls.Add($gp)

            $dtp=New-Object System.Data.DataTable
            [void]$dtp.Columns.Add('id',[int])
            [void]$dtp.Columns.Add('CP',[string])
            [void]$dtp.Columns.Add('Nome',[string])
            [void]$dtp.Columns.Add('Tipo',[string])
            [void]$dtp.Columns.Add('De',[string])
            [void]$dtp.Columns.Add('Ate',[string])
            [void]$dtp.Columns.Add('Modo',[string])

            foreach($sv in $selecionados){
                $rw=$dtp.NewRow()
                $rw['id']=[int]$sv.id;$rw['CP']=[string]$sv.CP;$rw['Nome']=[string]$sv.Nome
                $ch=[string]$sv.id
                $mapInd=$null;$mapInd=$fp.Tag.Periodos
                if($null -ne $mapInd -and $mapInd.ContainsKey($ch)){
                    $pp=$mapInd[$ch]
                    $rw['Tipo']=if($null -ne $pp.TipoTexto -and [string]$pp.TipoTexto -ne ''){[string]$pp.TipoTexto}else{[string]$cbTipoLote.Text}
                    $rw['De']=([datetime]$pp.Ini).ToString('dd/MM/yyyy')
                    $rw['Ate']=([datetime]$pp.Fim).ToString('dd/MM/yyyy')
                    $rw['Modo']='INDIVIDUAL'
                } else {
                    $rw['Tipo']=[string]$cbTipoLote.Text
                    $rw['De']=$dtIniLote.Value.Date.ToString('dd/MM/yyyy')
                    $rw['Ate']=$dtFimLote.Value.Date.ToString('dd/MM/yyyy')
                    $rw['Modo']='PADRAO'
                }
                $dtp.Rows.Add($rw)
            }
            $gp.DataSource=$dtp

            $labPer=New-Object System.Windows.Forms.Label;$labPer.Text='Ocorrencia do servidor selecionado';$labPer.Location=[Drawing.Point]::new(20,438);$labPer.Size=[Drawing.Size]::new(260,22);$labPer.Anchor='Bottom,Left';$fp.Controls.Add($labPer)

            $labTipoInd=New-Object System.Windows.Forms.Label;$labTipoInd.Text='Tipo';$labTipoInd.Location=[Drawing.Point]::new(20,471);$labTipoInd.Size=[Drawing.Size]::new(35,22);$labTipoInd.Anchor='Bottom,Left';$fp.Controls.Add($labTipoInd)
            $cbTipoInd=New-Object System.Windows.Forms.ComboBox;$cbTipoInd.Location=[Drawing.Point]::new(60,468);$cbTipoInd.Size=[Drawing.Size]::new(300,26);$cbTipoInd.DropDownStyle='DropDownList';$cbTipoInd.Anchor='Bottom,Left'
            $bsTipoInd=New-Object System.Windows.Forms.BindingSource;$bsTipoInd.DataSource=$tpLote;$cbTipoInd.DataSource=$bsTipoInd;$cbTipoInd.ValueMember='id';$cbTipoInd.DisplayMember='item';$fp.Controls.Add($cbTipoInd)

            $labDe=New-Object System.Windows.Forms.Label;$labDe.Text='De';$labDe.Location=[Drawing.Point]::new(380,471);$labDe.Size=[Drawing.Size]::new(25,22);$labDe.Anchor='Bottom,Left';$fp.Controls.Add($labDe)
            $dti=New-Object System.Windows.Forms.DateTimePicker;$dti.Location=[Drawing.Point]::new(410,468);$dti.Size=[Drawing.Size]::new(120,26);$dti.Format='Short';$dti.Anchor='Bottom,Left';$fp.Controls.Add($dti)
            $labAt=New-Object System.Windows.Forms.Label;$labAt.Text='Ate';$labAt.Location=[Drawing.Point]::new(545,471);$labAt.Size=[Drawing.Size]::new(28,22);$labAt.Anchor='Bottom,Left';$fp.Controls.Add($labAt)
            $dtf=New-Object System.Windows.Forms.DateTimePicker;$dtf.Location=[Drawing.Point]::new(578,468);$dtf.Size=[Drawing.Size]::new(120,26);$dtf.Format='Short';$dtf.Anchor='Bottom,Left';$fp.Controls.Add($dtf)

            $btnAplicar=New-Button 'APLICAR A ESTE SERVIDOR' 205;$btnAplicar.Location=[Drawing.Point]::new(20,515);$btnAplicar.Anchor='Bottom,Left';Set-PrimaryButton $btnAplicar;$fp.Controls.Add($btnAplicar)
            $btnPadrao=New-Button 'USAR PADRAO DO LOTE' 185;$btnPadrao.Location=[Drawing.Point]::new(235,515);$btnPadrao.Anchor='Bottom,Left';$fp.Controls.Add($btnPadrao)

            # V1.0.14.21.17 - fluxo mais claro: o usuario pode voltar para a tela
            # anterior ou concluir tudo diretamente desta janela.
            $btnFecharPer=New-Button 'SALVAR AJUSTES E VOLTAR' 200
            $btnFecharPer.Location=[Drawing.Point]::new(430,565)
            $btnFecharPer.Anchor='Bottom,Right'
            $fp.Controls.Add($btnFecharPer)

            $btnIncluirDireto=New-Button 'INCLUIR SELECIONADOS NA ESCALA' 260
            $btnIncluirDireto.Location=[Drawing.Point]::new(640,565)
            $btnIncluirDireto.Anchor='Bottom,Right'
            Set-PrimaryButton $btnIncluirDireto
            $fp.Controls.Add($btnIncluirDireto)

            $selecionaTipoIndividual={
                param([int]$tipoAlvo)
                if($tipoAlvo -le 0){return}
                for($ix=0;$ix -lt $cbTipoInd.Items.Count;$ix++){
                    $idItem=0
                    try{$idItem=[int]$cbTipoInd.Items[$ix]['id']}catch{
                        $idItem=[int]$cbTipoInd.Items[$ix].Row['id']
                    }
                    if($idItem -eq $tipoAlvo){$cbTipoInd.SelectedIndex=$ix;break}
                }
            }

            $carregaLinhaPeriodo={
                if($null -eq $gp.CurrentRow){return}
                $sid=[string][int]$gp.CurrentRow.Cells['id'].Value
                $mapInd=$null;$mapInd=$fp.Tag.Periodos
                if($null -ne $mapInd -and $mapInd.ContainsKey($sid)){
                    $pp=$mapInd[$sid]
                    & $selecionaTipoIndividual ([int]$pp.TipoId)
                    $dti.Value=[datetime]$pp.Ini
                    $dtf.Value=[datetime]$pp.Fim
                } else {
                    $tlId=Get-ComboSelectedInt $cbTipoLote 0;if($tlId -gt 0){& $selecionaTipoIndividual $tlId}
                    $dti.Value=$dtIniLote.Value.Date
                    $dtf.Value=$dtFimLote.Value.Date
                }
            }
            $gp.Add_SelectionChanged($carregaLinhaPeriodo)

            $btnAplicar.Add_Click({
                try{
                    if($null -eq $gp.CurrentRow){Show-Info 'Selecione um servidor na lista.';return}
                    if($dtf.Value.Date -lt $dti.Value.Date){Show-Info 'A data Ate nao pode ser anterior a De.';return}
                    $tipoIndId=Get-ComboSelectedInt $cbTipoInd 0
                    if($tipoIndId -le 0){Show-Info 'Selecione o Tipo da ocorrencia para este servidor.';return}
                    $sid=[string][int]$gp.CurrentRow.Cells['id'].Value
                    $mapInd=$null;$mapInd=$fp.Tag.Periodos
                    if($null -eq $mapInd){
                        $mapInd=@{}
                        if($null -eq $fp.Tag){$fp.Tag=New-Object PSObject -Property @{Periodos=$mapInd}}else{$fp.Tag.Periodos=$mapInd}
                        if($null -ne $f.Tag){$f.Tag.Periodos=$mapInd}
                    }
                    $mapInd[$sid]=New-Object PSObject -Property @{TipoId=$tipoIndId;TipoTexto=[string]$cbTipoInd.Text;Ini=$dti.Value.Date;Fim=$dtf.Value.Date}
                    $gp.CurrentRow.Cells['Tipo'].Value=[string]$cbTipoInd.Text
                    $gp.CurrentRow.Cells['De'].Value=$dti.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Ate'].Value=$dtf.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Modo'].Value='INDIVIDUAL'
                }catch{Show-Error $_.Exception.Message}
            }.GetNewClosure())

            $btnPadrao.Add_Click({
                try{
                    if($null -eq $gp.CurrentRow){Show-Info 'Selecione um servidor na lista.';return}
                    $sid=[string][int]$gp.CurrentRow.Cells['id'].Value
                    $mapInd=$null;$mapInd=$fp.Tag.Periodos
                    if($null -ne $mapInd -and $mapInd.ContainsKey($sid)){$mapInd.Remove($sid)}
                    $gp.CurrentRow.Cells['Tipo'].Value=[string]$cbTipoLote.Text
                    $gp.CurrentRow.Cells['De'].Value=$dtIniLote.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Ate'].Value=$dtFimLote.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Modo'].Value='PADRAO'
                    $tlId=Get-ComboSelectedInt $cbTipoLote 0;if($tlId -gt 0){& $selecionaTipoIndividual $tlId}
                    $dti.Value=$dtIniLote.Value.Date;$dtf.Value=$dtFimLote.Value.Date
                }catch{Show-Error $_.Exception.Message}
            }.GetNewClosure())

            $btnIncluirDireto.Add_Click({
                try{
                    # Se o usuario alterou Tipo/De/Ate do servidor atualmente
                    # selecionado e ainda nao clicou em APLICAR, salva esse ajuste
                    # antes de iniciar a inclusao na escala.
                    if($null -eq $gp.CurrentRow){Show-Info 'Selecione um servidor na lista.';return}
                    if($dtf.Value.Date -lt $dti.Value.Date){Show-Info 'A data Ate nao pode ser anterior a De.';return}

                    $tipoIndId=0
                    $tipoIndId=Get-ComboSelectedInt $cbTipoInd 0
                    if($tipoIndId -le 0){Show-Info 'Selecione o Tipo da ocorrencia para este servidor.';return}

                    $sid=[string][int]$gp.CurrentRow.Cells['id'].Value
                    $mapInd=$null
                    $mapInd=$fp.Tag.Periodos
                    if($null -eq $mapInd){
                        $mapInd=@{}
                        if($null -eq $fp.Tag){
                            $fp.Tag=New-Object PSObject -Property @{Periodos=$mapInd;IncluirAposPersonalizacao=$false}
                        } else {
                            $fp.Tag.Periodos=$mapInd
                        }
                        if($null -ne $f.Tag){$f.Tag.Periodos=$mapInd}
                    }

                    $mapInd[$sid]=New-Object PSObject -Property @{
                        TipoId=$tipoIndId
                        TipoTexto=[string]$cbTipoInd.Text
                        Ini=$dti.Value.Date
                        Fim=$dtf.Value.Date
                    }
                    $gp.CurrentRow.Cells['Tipo'].Value=[string]$cbTipoInd.Text
                    $gp.CurrentRow.Cells['De'].Value=$dti.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Ate'].Value=$dtf.Value.Date.ToString('dd/MM/yyyy')
                    $gp.CurrentRow.Cells['Modo'].Value='INDIVIDUAL'

                    # Solicita que, assim que esta janela modal fechar, a tela
                    # principal execute o mesmo botao INCLUIR SELECIONADOS que ja
                    # existia e ja estava validado.
                    $fp.Tag.IncluirAposPersonalizacao=$true
                    $f.Tag.IncluirAposPersonalizacao=$true
                    $fp.Close()
                }catch{Show-Error $_.Exception.Message}
            }.GetNewClosure())

            $btnFecharPer.Add_Click({$fp.Close()})
            $fp.Add_Shown({if($gp.Rows.Count -gt 0){$gp.Rows[0].Selected=$true;$gp.CurrentCell=$gp.Rows[0].Cells['Nome']; & $carregaLinhaPeriodo}}.GetNewClosure())
            [void]$fp.ShowDialog($f)
            $fp.Dispose()

            # Atualiza o texto do botao sem invocar scriptblock por '&'.
            $qtdPers=0
            $mapPers=$null
            $mapPers=$f.Tag.Periodos
            if($null -ne $mapPers){
                foreach($k in @($mapPers.Keys)){
                    if($mapPers.ContainsKey($k)){$qtdPers++}
                }
            }
            if($qtdPers -gt 0){$btnDatasInd.Text=('OCORRENCIA POR SERVIDOR ({0})...' -f $qtdPers)}
            else{$btnDatasInd.Text='OCORRENCIA POR SERVIDOR...'}

            # Inclusao direta solicitada pela janela individual. Procura o botao
            # ja existente na tela principal em tempo de execucao e usa exatamente
            # a rotina de inclusao que ja estava funcionando.
            $incluirAgora=$false
            $incluirAgora=[bool]$f.Tag.IncluirAposPersonalizacao
            if($incluirAgora){
                $f.Tag.IncluirAposPersonalizacao=$false
                $btnPai=$null
                foreach($ctl in $f.Controls){
                    if(($ctl -is [System.Windows.Forms.Button]) -and ([string]$ctl.Text -eq 'INCLUIR SELECIONADOS')){
                        $btnPai=$ctl
                        break
                    }
                }
                if($null -ne $btnPai){
                    $btnPai.PerformClick()
                } else {
                    Show-Info 'Os ajustes foram salvos. Clique em INCLUIR SELECIONADOS para concluir a inclusao na escala.'
                }
            }
        }catch{Show-Error $_.Exception.Message}
    }.GetNewClosure())

    $btnAdd=New-Button 'INCLUIR SELECIONADOS' 190;Set-PrimaryButton $btnAdd;$btnAdd.Location=[Drawing.Point]::new(650,676);$btnAdd.Anchor='Bottom,Right';$f.Controls.Add($btnAdd)
    $btnCancel=New-Button 'FECHAR' 110;$btnCancel.Location=[Drawing.Point]::new(850,676);$btnCancel.Anchor='Bottom,Right';$btnCancel.Add_Click({$f.Close()});$f.Controls.Add($btnCancel)

    $load={
        try{
            $f.UseWaitCursor=$true;$btnPesq.Enabled=$false;$lbl.Text='Carregando servidores...';$grid.SuspendLayout()
            $term=$txt.Text.Trim()
            # V1.0.14.21.10 - mesma regra funcional da V1.0.14.17, mas a lista de
            # servidores ja escalados no mes e montada uma unica vez e associada
            # ao cadastro. Antes a subconsulta era correlacionada e podia ser
            # repetida centenas de vezes durante a abertura da tela.
            $q=("SELECT s.id,s.cp AS CP,s.nome AS Nome,COALESCE(s.funcao,'') AS Funcao,COALESCE(s.tipo_vinculo,'') AS Vinculo,COALESCE(s.coren,'') AS Coren,COALESCE(s.sub_funcao,'') AS Sub_Funcao FROM servidores s LEFT JOIN (SELECT DISTINCT es2.servidor_id FROM escala_servidores es2 JOIN escalas e2 ON e2.id=es2.escala_id JOIN setores st2 ON st2.id=e2.setor_id WHERE es2.ativo=1 AND st2.ativo=1 AND e2.ano={0} AND e2.mes={1}) ocupados ON ocupados.servidor_id=s.id WHERE s.ativo=1 AND ocupados.servidor_id IS NULL AND NOT EXISTS(SELECT 1 FROM escala_vagas vd JOIN escala_servidores eo ON eo.id=vd.escala_servidor_id_origem WHERE vd.ativo=1 AND vd.ocorrencia_id IS NOT NULL AND eo.servidor_id=s.id AND vd.escala_id={2}) ORDER BY s.nome;" -f $anoLote,$mesLote,[int]$script:CurrentScaleId)
            $all=Db-Query $q
            $dt=$all
            $missing=@()

            if($term){
                $tokens=@($term -split ',' | ForEach-Object {$_.Trim()} | Where-Object {$_ -ne ''} | Sort-Object -Unique)
                $dt=$all.Clone()
                $found=@{}
                foreach($t in $tokens){$found[$t]=$false}

                foreach($row in $all.Rows){
                    $rowMatch=$false
                    $cp=([string]$row['CP']).Trim()
                    $coren=([string]$row['Coren']).Trim()
                    $nome=[string]$row['Nome']
                    foreach($t in $tokens){
                        $match=$false
                        if($t -match '^\d+$'){
                            # Numero: busca exata para CP ou Coren.
                            $match=($cp -eq $t -or $coren -eq $t)
                        } else {
                            # Texto: busca por parte do nome, sem diferenciar maiusculas/minusculas.
                            $match=($nome.IndexOf($t,[System.StringComparison]::CurrentCultureIgnoreCase) -ge 0)
                        }
                        if($match){$rowMatch=$true;$found[$t]=$true}
                    }
                    if($rowMatch){$dt.ImportRow($row)}
                }
                foreach($t in $tokens){if(-not $found[$t]){$missing+=$t}}
            }

            $grid.DataSource=$dt
            if($grid.Columns.Contains('id')){$grid.Columns['id'].Visible=$false}
            if($grid.Columns.Contains('Nome')){$grid.Columns['Nome'].AutoSizeMode='Fill';$grid.Columns['Nome'].MinimumWidth=260}
            # V1.0.14.21.10 - evita AutoSizeMode=AllCells, que percorre todas as
            # celulas da lista para calcular largura. Larguras continuam ajustaveis pelo mouse.
            $larguras=@{CP=72;Funcao=82;Vinculo=70;Coren=95;Sub_Funcao=115}
            foreach($n in $larguras.Keys){if($grid.Columns.Contains($n)){$grid.Columns[$n].AutoSizeMode='None';$grid.Columns[$n].Width=[int]$larguras[$n]}}

            $grid.ClearSelection()
            if($term){
                # Na pesquisa em lote, os encontrados ja ficam selecionados para agilizar a inclusao.
                foreach($r in $grid.Rows){if(-not $r.IsNewRow){$r.Selected=$true}}
            }
            $lbl.Text=('{0} servidor(es) disponivel(is) | {1} selecionado(s)' -f $grid.Rows.Count,$grid.SelectedRows.Count)
            if($term -and $missing.Count -gt 0){
                # Para cada termo nao encontrado, verifica se o servidor existe
                # no cadastro (so nao apareceu por ja estar noutra escala este
                # mes) ou se realmente nao existe cadastro nenhum com esse CP/
                # Coren/Nome, para dar um motivo especifico em vez de generico.
                $anoMesAtual=Db-Query "SELECT ano,mes FROM escalas WHERE id=$script:CurrentScaleId;"
                $anoAtual=0;$mesAtual=0
                if($anoMesAtual.Rows.Count -gt 0){$anoAtual=[int]$anoMesAtual.Rows[0]['ano'];$mesAtual=[int]$anoMesAtual.Rows[0]['mes']}
                $detalhes=@()
                foreach($t in $missing){
                    $condBusca=$(if($t -match '^\d+$'){"(cp={0} OR coren={0})" -f (Sql-Q $t)}else{"nome LIKE {0}" -f (Sql-Q ('%'+$t+'%'))})
                    $achados=Db-Query "SELECT id,cp,nome FROM servidores WHERE ativo=1 AND ($condBusca);"
                    if($achados.Rows.Count -eq 0){
                        $detalhes+=("- '$t': nao encontrado no cadastro de servidores.")
                    } else {
                        foreach($ac in $achados.Rows){
                            $svId=[int]$ac['id'];$svNome=[string]$ac['nome']
                            $ondeQ=Db-Query ("SELECT s.nome AS setor FROM escala_servidores es JOIN escalas e ON e.id=es.escala_id JOIN setores s ON s.id=e.setor_id WHERE es.servidor_id=$svId AND es.ativo=1 AND s.ativo=1 AND e.ano=$anoAtual AND e.mes=$mesAtual LIMIT 1;")
                            if($ondeQ.Rows.Count -gt 0){
                                $detalhes+=("- '$t' ($svNome): ja escalado(a) em '$($ondeQ.Rows[0]['setor'])' neste mes.")
                            } else {
                                $detalhes+=("- '$t' ($svNome): encontrado no cadastro, mas nao apareceu na lista (confira se ja esta nesta mesma escala).")
                            }
                        }
                    }
                }
                Show-Info ("Alguns termos nao entraram na lista:`r`n`r`n" + ($detalhes -join "`r`n"))
            }
        }catch{Show-Error $_.Exception.Message}
        finally{
            $grid.ResumeLayout()
            $btnPesq.Enabled=$true;$f.UseWaitCursor=$false
        }
    }
    $updateSel={$lbl.Text=('{0} servidor(es) disponivel(is) | {1} selecionado(s)' -f $grid.Rows.Count,$grid.SelectedRows.Count)}
    $grid.Add_SelectionChanged($updateSel)

    # V1.0.14.32 - edicao individual do servidor filtrado dentro da propria
    # Lotacao em Lote. Reutiliza Show-ServidorDialog para nao duplicar regras
    # de CP, Coren, readaptacao e demais validacoes do cadastro oficial.
    $editarServidorLote={
        try{
            if($null -eq $grid.CurrentRow -or $grid.CurrentRow.IsNewRow){Show-Info 'Selecione um servidor na lista para editar.';return}
            $sidEdit=0;$sidEdit=[int]$grid.CurrentRow.Cells['id'].Value
            if($sidEdit -le 0){Show-Info 'Nao foi possivel identificar o servidor da linha atual.';return}
            Show-ServidorDialog $sidEdit $f
            & $load
        }catch{Show-Error $_.Exception.Message}
    }.GetNewClosure()
    $btnEditarSrvLote.Add_Click($editarServidorLote)
    $grid.Add_CellDoubleClick({param($s,$e);if($e.RowIndex -ge 0){& $editarServidorLote}}.GetNewClosure())

    $btnPesq.Add_Click($load);$txt.Add_KeyDown({param($s,$e);if($e.KeyCode -eq 'Enter'){& $load;$e.SuppressKeyPress=$true}})
    $btnTodos.Add_Click({$grid.ClearSelection();foreach($r in $grid.Rows){if(-not $r.IsNewRow){$r.Selected=$true}};& $updateSel})
    $btnLimpar.Add_Click({$grid.ClearSelection();& $updateSel})
    $btnAdd.Add_Click({
        try{
            $ids=@()
            foreach($r in $grid.SelectedRows){$id=[int]$r.Cells['id'].Value;if($id -gt 0){$ids+=$id}}
            $ids=@($ids | Sort-Object -Unique)
            if($ids.Count -eq 0){Show-Info 'Selecione pelo menos um servidor na lista.';return}
            $hid=[int]$cbH.SelectedValue;if($hid -le 0){Show-Info 'Selecione o bloco de horario.';return}

            # V1.0.14.17 - checagem de seguranca por servidor: mesmo com a lista
            # ja filtrada, confere de novo antes de gravar (por exemplo, se a
            # janela ficou aberta enquanto outra tela escalou o mesmo servidor
            # em outro Setor/Sub_Setor). Quem estiver em conflito e ignorado,
            # e o total e informado ao final, sem bloquear os demais.
            $conflitantes=Db-Query ("SELECT DISTINCT es2.servidor_id FROM escala_servidores es2 JOIN escalas e2 ON e2.id=es2.escala_id JOIN setores st2 ON st2.id=e2.setor_id WHERE es2.ativo=1 AND st2.ativo=1 AND e2.ano=(SELECT ano FROM escalas WHERE id={0}) AND e2.mes=(SELECT mes FROM escalas WHERE id={0});" -f $script:CurrentScaleId)
            $conflitoSet=New-Object 'System.Collections.Generic.HashSet[int]'
            foreach($cr in $conflitantes.Rows){[void]$conflitoSet.Add([int]$cr['servidor_id'])}
            $idsValidos=@($ids | Where-Object{-not $conflitoSet.Contains($_)})
            $idsIgnorados=$ids.Count-$idsValidos.Count
            if($idsValidos.Count -eq 0){Show-Info 'Todos os servidores selecionados ja estao escalados em outro Setor/Sub_Setor neste mesmo mes.';return}

            # V1.0.14.35 - quando houver ocorrencia opcional, valida TODO o
            # conjunto antes de inserir qualquer servidor. Assim um erro de Tipo,
            # periodo, sobreposicao ou lancamento MANUAL nao deixa lotacao parcial.
            $ocorrenciasPreparadas=New-Object System.Collections.ArrayList
            $qtdPersonalizados=0
            $tipoLoteId=0
            $setorIdReal=0
            if($chkOcLote.Checked){
                $tipoLoteId=[int]$cbTipoLote.SelectedValue
                if($tipoLoteId -le 0){Show-Info 'Selecione o Tipo da ocorrencia em lote, ou desmarque a opcao.';return}
                if($dtFimLote.Value.Date -lt $dtIniLote.Value.Date){Show-Info 'A data "Ate" da ocorrencia em lote nao pode ser anterior a "De".';return}
                $setorIdReal=[int](Db-Scalar "SELECT setor_id FROM escalas WHERE id=$script:CurrentScaleId;")
                if($setorIdReal -le 0){Show-Info 'Nao foi possivel identificar o Setor/Sub_Setor desta escala.';return}

                foreach($sid in $idsValidos){
                    $tipoServidorId=$tipoLoteId
                    $iniDt=$dtIniLote.Value.Date
                    $fimDt=$dtFimLote.Value.Date
                    $chSid=[string]$sid
                    $mapIndPrincipal=$null;$mapIndPrincipal=$f.Tag.Periodos
                    if($null -ne $mapIndPrincipal -and $mapIndPrincipal.ContainsKey($chSid)){
                        $pp=$mapIndPrincipal[$chSid]
                        if([int]$pp.TipoId -gt 0){$tipoServidorId=[int]$pp.TipoId}
                        $iniDt=([datetime]$pp.Ini).Date
                        $fimDt=([datetime]$pp.Fim).Date
                        $qtdPersonalizados++
                    }
                    $nomeValidacao='';$nomeValidacao=[string](Db-Scalar ("SELECT nome FROM servidores WHERE id={0};" -f $sid))
                    if([string]::IsNullOrWhiteSpace($nomeValidacao)){$nomeValidacao=('ID {0}' -f $sid)}
                    if($tipoServidorId -le 0){Show-Info ("{0}: selecione um Tipo de ocorrencia valido." -f $nomeValidacao);return}
                    if($fimDt -lt $iniDt){Show-Info ("{0}: a data Ate nao pode ser anterior a De." -f $nomeValidacao);return}
                    $erroValidacaoLote=Get-OcorrenciaValidationError $setorIdReal $sid $iniDt $fimDt 0 $tipoServidorId
                    if(-not [string]::IsNullOrWhiteSpace([string]$erroValidacaoLote)){Show-Info ('{0}: {1}' -f $nomeValidacao,$erroValidacaoLote);return}
                    [void]$ocorrenciasPreparadas.Add([pscustomobject]@{ServidorId=$sid;TipoId=$tipoServidorId;Ini=$iniDt;Fim=$fimDt})
                }
            }

            # Servidores e ocorrencias sao persistidos em uma UNICA chamada/conexao.
            # Se qualquer INSERT real falhar, nao existe COMMIT parcial.
            $sb=New-Object System.Text.StringBuilder
            [void]$sb.AppendLine('BEGIN IMMEDIATE;')
            foreach($sid in $idsValidos){
                [void]$sb.AppendLine(("INSERT INTO escala_servidores(escala_id,servidor_id,horario_id,ordem) VALUES ({0},{1},{2},(SELECT COALESCE(MAX(ordem),0)+1 FROM escala_servidores WHERE escala_id={0})) ON CONFLICT(escala_id,servidor_id) DO UPDATE SET ativo=1,horario_id=excluded.horario_id;" -f $script:CurrentScaleId,$sid,$hid))
            }
            foreach($ocp in $ocorrenciasPreparadas){
                $iniTxt=([datetime]$ocp.Ini).ToString('yyyy-MM-dd')
                $fimTxt=([datetime]$ocp.Fim).ToString('yyyy-MM-dd')
                # O EXISTS evita criar ocorrencia se um gatilho de concorrencia tiver
                # ignorado a lotacao desse servidor entre a validacao e o INSERT.
                [void]$sb.AppendLine(("INSERT INTO ocorrencias(setor_id,servidor_id,tipo_id,data_inicial,data_final,situacao,origem) SELECT {0},{1},{2},{3},{4},'ATIVA','LOTE' WHERE EXISTS(SELECT 1 FROM escala_servidores WHERE escala_id={5} AND servidor_id={1} AND ativo=1);" -f $setorIdReal,[int]$ocp.ServidorId,[int]$ocp.TipoId,(Sql-Q $iniTxt),(Sql-Q $fimTxt),$script:CurrentScaleId))
            }
            [void]$sb.AppendLine('COMMIT;')
            Write-Log ('Lotacao em lote - preparando transacao unica: escala_id={0} horario_id={1} servidores_validos=[{2}] ocorrencias={3}' -f $script:CurrentScaleId,$hid,($idsValidos -join ','),$ocorrenciasPreparadas.Count)
            Db-Exec $sb.ToString()

            # Confirma de verdade se a lotacao aconteceu; o gatilho de servidor unico
            # por mes pode usar RAISE(IGNORE), que nao gera excecao SQL.
            $idsValidosTxt=($idsValidos -join ',')
            $verif=Db-Query ("SELECT COUNT(*) AS qtd FROM escala_servidores WHERE escala_id=$script:CurrentScaleId AND servidor_id IN ($idsValidosTxt) AND ativo=1;")
            $qtdReal=[int]$verif.Rows[0]['qtd']
            if($qtdReal -lt $idsValidos.Count){
                Write-Log ('ALERTA Lotacao em lote: esperado {0} mas confirmado {1} apos transacao. SQL executado:{2}{3}' -f $idsValidos.Count,$qtdReal,"`r`n",$sb.ToString())
                Show-Error ("A gravacao nao foi confirmada como esperado (esperava {0}, confirmou {1} apos salvar).`r`n`r`nPode ter ocorrido uma inclusao concorrente em outro Setor/Sub_Setor. Recarregue e confira a lista. Os detalhes foram registrados em Logs\Sistema_Escala.log." -f $idsValidos.Count,$qtdReal)
                Load-Escala
                & $load
                return
            }

            Write-Log ('Lotacao em lote na escala mensal: escala={0} horario={1} servidores={2} ignorados_prevalidacao={3} ocorrencias={4}' -f $script:CurrentScaleId,$hid,$idsValidos.Count,$idsIgnorados,$ocorrenciasPreparadas.Count)
            $msg=('{0} servidor(es) incluido(s) no bloco selecionado.' -f $idsValidos.Count)
            if($idsIgnorados -gt 0){$msg+=(' | {0} ignorado(s): ja escalado(s) em outro Setor/Sub_Setor neste mes.' -f $idsIgnorados)}
            if($chkOcLote.Checked){
                if($qtdPersonalizados -gt 0){
                    $msg+=(' | {0} ocorrencia(s) lancada(s); {1} com ajuste individual e {2} usando o padrao do lote.' -f $ocorrenciasPreparadas.Count,$qtdPersonalizados,($ocorrenciasPreparadas.Count-$qtdPersonalizados))
                }else{
                    $msg+=(' | {0} ocorrencia(s) lancada(s) de {1:dd/MM/yyyy} a {2:dd/MM/yyyy}.' -f $ocorrenciasPreparadas.Count,$dtIniLote.Value,$dtFimLote.Value)
                }
            }

            Show-Info $msg
            Load-Escala
            & $load
        }catch{Show-Error $_.Exception.Message}
    })
    # V1.0.14.21.10 - abre a janela primeiro e carrega a lista logo depois.
    # Assim o usuario recebe resposta visual imediata; o processamento pesado nao segura a abertura do formulario.
    $timerCargaLote=New-Object System.Windows.Forms.Timer;$timerCargaLote.Interval=60
    $timerCargaLote.Add_Tick({
        $timerCargaLote.Stop()
        & $load
    }.GetNewClosure())
    $f.Add_Shown({
        if($HorarioIdPreSelecionado -gt 0){
            for($ih=0;$ih -lt $hh.Rows.Count;$ih++){
                if([int]$hh.Rows[$ih]['id'] -eq $HorarioIdPreSelecionado){$cbH.SelectedIndex=$ih;break}
            }
        }
        $lbl.Text='Carregando servidores...'
        $timerCargaLote.Start()
    }.GetNewClosure())
    [void]$f.ShowDialog($script:MainForm)
    $timerCargaLote.Stop();$timerCargaLote.Dispose();$f.Dispose()
}

function Remove-ServidorEscala {
    if($null -eq $script:gridEscala.CurrentRow){Show-Info 'Selecione um servidor na escala.';return}
    $tipo=[string]$script:gridEscala.CurrentRow.Cells['_TIPO'].Value;if($tipo -eq 'VAGA'){Show-Info 'Esta linha e uma Escala Vaga. Use o botao ESCALA VAGA para editar ou excluir.';return};if($tipo -ne 'SERVIDOR'){Show-Info 'Selecione uma linha de servidor.';return}
    try {$esid=[int]$script:gridEscala.CurrentRow.Cells['_ID'].Value} catch {$esid=0}
    if($esid -le 0){Show-Info 'Selecione um servidor na escala.';return}
    if(-not (Confirm-Action 'Remover este servidor apenas desta escala mensal?')){return}
    try{
        $srvRow=Db-Query "SELECT es.escala_id,es.servidor_id,es.horario_id,es.ordem,s.nome,COALESCE(s.funcao,'') AS funcao FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.id=$esid;"
        if($srvRow.Rows.Count -eq 0){return}
        $sr=$srvRow.Rows[0]
        $diasQ=Db-Query "SELECT data,sigla,texto,origem,ocorrencia_id FROM escala_dias WHERE escala_servidor_id=$esid;"
        $diasBackup=New-Object System.Collections.ArrayList
        foreach($dr in $diasQ.Rows){[void]$diasBackup.Add([pscustomobject]@{Data=[string]$dr['data'];Sigla=[string]$dr['sigla'];Texto=[string]$dr['texto'];Origem=[string]$dr['origem'];OcorrenciaId=$(if($dr['ocorrencia_id'] -ne [DBNull]::Value){[int]$dr['ocorrencia_id']}else{0})})}
        $nome=[string]$sr['nome']
        $funcaoSr=[string]$sr['funcao']
        $escalaIdSr=[int]$sr['escala_id']
        $horarioIdSr=0
        if($sr['horario_id'] -ne [DBNull]::Value -and -not [string]::IsNullOrWhiteSpace([string]$sr['horario_id'])){$horarioIdSr=[int]$sr['horario_id']}

        Db-Exec "DELETE FROM escala_servidores WHERE id=$esid;"
        Load-Escala
        Show-UndoBar ("Servidor removido: {0}" -f $nome) @{Type='REMOVE_SERVIDOR';Data=@{EscalaId=$escalaIdSr;ServidorId=[int]$sr['servidor_id'];HorarioId=$horarioIdSr;Ordem=[int]$sr['ordem'];Dias=$diasBackup}}

        if($horarioIdSr -gt 0 -and (Confirm-Action ("Deseja inserir uma ESCALA VAGA no lugar de '{0}'? Ja vem preenchida com o mesmo bloco de horario e funcao dele(a)." -f $nome))){
            $descPadrao=('ESCALA VAGA - {0}' -f $(if($funcaoSr){$funcaoSr}else{$nome}))
            Show-EscalaVagaDialog 0 $escalaIdSr $horarioIdSr $funcaoSr $descPadrao | Out-Null
            Load-Escala
        }
    }catch{Show-Error $_.Exception.Message}
}


function Show-EscalaVagaDialog {
    param([int]$Id=0,[int]$ScaleId=0,[int]$HorarioIdPadrao=0,[string]$FuncaoPadrao='',[string]$DescricaoPadrao='')
    $scaleId=$(if($ScaleId -gt 0){$ScaleId}else{Get-ScaleId})
    if($scaleId -le 0){Show-Info 'PASSO 3: crie ou carregue a escala do mes primeiro.';return $false}
    if((Get-ScaleBlockCount $scaleId) -le 0){Show-Info 'PASSO 4: configure primeiro os blocos de horario desta escala.';Show-ScaleBlocksManager;return $false}
    $st=Db-Query "SELECT ano,mes FROM escalas WHERE id=$scaleId;";if($st.Rows.Count -eq 0){return $false}
    $ano=[int]$st.Rows[0]['ano'];$mes=[int]$st.Rows[0]['mes'];$first=Get-Date -Year $ano -Month $mes -Day 1;$last=$first.AddMonths(1).AddDays(-1)
    $data=$null
    if($Id -gt 0){
        $t=Db-Query "SELECT * FROM escala_vagas WHERE id=$Id AND escala_id=$scaleId;";if($t.Rows.Count){$data=$t.Rows[0]}
        if($data -and $data.Table.Columns.Contains('ocorrencia_id') -and $data['ocorrencia_id'] -ne [DBNull]::Value){
            Show-Info 'Esta Escala Vaga foi criada por uma ocorrencia definitiva e e controlada por ela. Edite a ocorrencia na aba Ocorrencias para alterar a vaga com seguranca.'
            return $false
        }
    }
    $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=$(if($Id -gt 0){'Editar Escala Vaga'}else{'Nova Escala Vaga'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(760,500);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false
    $labs=@('Bloco de horario','Funcao','Descricao na escala','Data inicial','Data final','Quantidade de vagas');$ys=@(30,85,140,245,300,355)
    for($i=0;$i -lt $labs.Count;$i++){$l=New-Object System.Windows.Forms.Label;$l.Text=$labs[$i];$l.Location=New-Object System.Drawing.Point(20,$ys[$i]);$l.Size=New-Object System.Drawing.Size(130,22);$f.Controls.Add($l)}
    $cbH=New-Object System.Windows.Forms.ComboBox;$cbH.Location=New-Object System.Drawing.Point(155,27);$cbH.Size=New-Object System.Drawing.Size(565,26);$cbH.DropDownStyle='DropDownList';$hh=Db-Query "SELECT h.id,h.descricao FROM escala_blocos_ordem bo JOIN horarios h ON h.id=bo.horario_id WHERE bo.escala_id=$scaleId AND h.ativo=1 ORDER BY bo.ordem,h.nome;";$bsTmp4=New-Object System.Windows.Forms.BindingSource;$bsTmp4.DataSource=$hh;$cbH.DataSource=$bsTmp4;$cbH.ValueMember='id';$cbH.DisplayMember='descricao';$f.Controls.Add($cbH)
    $cbF=New-Object System.Windows.Forms.ComboBox;$cbF.Location=New-Object System.Drawing.Point(155,82);$cbF.Size=New-Object System.Drawing.Size(180,26);$cbF.DropDownStyle='DropDownList';foreach($x in @('TE','AE','ENF')){[void]$cbF.Items.Add($x)};$cbF.SelectedIndex=0;$f.Controls.Add($cbF)
    if($FuncaoPadrao -and $cbF.Items.Contains($FuncaoPadrao)){$cbF.SelectedItem=$FuncaoPadrao}
    $tbD=New-Object System.Windows.Forms.TextBox;$tbD.Location=New-Object System.Drawing.Point(155,137);$tbD.Size=New-Object System.Drawing.Size(565,75);$tbD.Multiline=$true;$tbD.Text=$(if($DescricaoPadrao){$DescricaoPadrao}else{'ESCALA VAGA TECNICO DE ENFERMAGEM'});$f.Controls.Add($tbD)
    $d1=New-Object System.Windows.Forms.DateTimePicker;$d1.Format='Short';$d1.Location=New-Object System.Drawing.Point(155,242);$d1.Size=New-Object System.Drawing.Size(180,26);$d1.Value=$first;$d1.MinDate=$first;$d1.MaxDate=$last;$f.Controls.Add($d1)
    $d2=New-Object System.Windows.Forms.DateTimePicker;$d2.Format='Short';$d2.Location=New-Object System.Drawing.Point(155,297);$d2.Size=New-Object System.Drawing.Size(180,26);$d2.Value=$last;$d2.MinDate=$first;$d2.MaxDate=$last;$f.Controls.Add($d2)
    $numQ=New-Object System.Windows.Forms.NumericUpDown;$numQ.Location=New-Object System.Drawing.Point(155,352);$numQ.Size=New-Object System.Drawing.Size(100,26);$numQ.Minimum=1;$numQ.Maximum=30;$numQ.Value=1;$f.Controls.Add($numQ)
    $info=New-Object System.Windows.Forms.Label;$info.Text='Cada vaga gera uma linha independente dentro do bloco. Na impressao, o periodo recebe a faixa ESCALA VAGA.';$info.Location=New-Object System.Drawing.Point(285,350);$info.Size=New-Object System.Drawing.Size(430,45);$info.ForeColor=[System.Drawing.Color]::FromArgb(70,85,100);$f.Controls.Add($info)
    if($data){
        $cbF.SelectedItem=[string]$data['funcao']
        $tbD.Text=[string]$data['descricao']
        # Carrega as datas da vaga sem depender da cultura do Windows e sempre dentro do mes da escala.
        [datetime]$iniVaga=$first
        [datetime]$fimVaga=$last
        $txtIni=[string]$data['data_inicial']
        $txtFim=[string]$data['data_final']
        [datetime]$tmpIni=$first
        [datetime]$tmpFim=$last
        if([datetime]::TryParse($txtIni,[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::AllowWhiteSpaces,[ref]$tmpIni)){$iniVaga=$tmpIni.Date}
        elseif([datetime]::TryParse($txtIni,[System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'),[System.Globalization.DateTimeStyles]::AllowWhiteSpaces,[ref]$tmpIni)){$iniVaga=$tmpIni.Date}
        if([datetime]::TryParse($txtFim,[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::AllowWhiteSpaces,[ref]$tmpFim)){$fimVaga=$tmpFim.Date}
        elseif([datetime]::TryParse($txtFim,[System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'),[System.Globalization.DateTimeStyles]::AllowWhiteSpaces,[ref]$tmpFim)){$fimVaga=$tmpFim.Date}
        if($iniVaga -lt $first){$iniVaga=$first};if($iniVaga -gt $last){$iniVaga=$last}
        if($fimVaga -lt $first){$fimVaga=$first};if($fimVaga -gt $last){$fimVaga=$last}
        if($fimVaga -lt $iniVaga){$fimVaga=$iniVaga}
        $d1.Value=$iniVaga
        $d2.Value=$fimVaga
        $numQ.Value=1
        $numQ.Enabled=$false
    }
    # V1.0.14.14 - Selecionar o bloco correto no combo. Na edicao, usa o
    # horario_id da propria vaga; na inclusao, usa o contexto vindo da tela
    # (linha selecionada na grade antes de abrir ESCALA VAGA), se houver.
    # Feito dentro do evento Shown, pelo mesmo motivo identificado no botao
    # + SERVIDOR: um combo associado a uma lista de dados so tem os itens
    # realmente disponiveis depois que a janela e exibida, nao antes.
    $alvoHorarioId=$(if($data){[int]$data['horario_id']}elseif($HorarioIdPadrao -gt 0){$HorarioIdPadrao}else{0})
    $f.Add_Shown({
        if($alvoHorarioId -gt 0){
            $alvo=[string]$alvoHorarioId
            for($ix=0; $ix -lt $cbH.Items.Count; $ix++){
                $rv=[System.Data.DataRowView]$cbH.Items[$ix]
                if([string]$rv['id'] -eq $alvo){$cbH.SelectedIndex=$ix;break}
            }
        }
    }.GetNewClosure())
    $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(465,410);$cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(600,410);$cancel.DialogResult='Cancel'
    $ok.Add_Click({try{$hid=[int]$cbH.SelectedValue;$fun=[string]$cbF.SelectedItem;$desc=$tbD.Text.Trim();$ini=$d1.Value.Date;$fim=$d2.Value.Date;if(-not $desc){Show-Info 'Informe a descricao da Escala Vaga.';return};if($fim -lt $ini){Show-Info 'A Data Final nao pode ser anterior a Data Inicial.';return};if($Id -gt 0){Db-Exec ("UPDATE escala_vagas SET horario_id={0},descricao={1},funcao={2},data_inicial={3},data_final={4} WHERE id={5};" -f $hid,(Sql-Q $desc),(Sql-Q $fun),(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fim.ToString('yyyy-MM-dd'))),$Id)}else{$q=[int]$numQ.Value;for($n=1;$n -le $q;$n++){Db-Exec ("INSERT INTO escala_vagas(escala_id,horario_id,descricao,funcao,data_inicial,data_final,ordem) VALUES ({0},{1},{2},{3},{4},{5},(SELECT COALESCE(MAX(ordem),0)+1 FROM escala_vagas WHERE escala_id={0} AND horario_id={1}));" -f $scaleId,$hid,(Sql-Q $desc),(Sql-Q $fun),(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fim.ToString('yyyy-MM-dd'))))}};$f.DialogResult='OK';$f.Close()}catch{Show-Error $_.Exception.Message}})
    $f.Controls.Add($ok);$f.Controls.Add($cancel)
    $dlgResult=$f.ShowDialog($script:MainForm);$okResult=($dlgResult -eq 'OK');$f.Dispose();return $okResult
}

function Show-EscalaVagaManager {
    param([int]$SelecionarVagaId=0,[int]$HorarioIdPadrao=0)

    # Usa exatamente o ID da escala ja carregada na grade principal.
    # Isso evita divergencia entre o que a tela mostra e o que esta janela lista.
    $idEscalaJanela=0
    $idEscalaJanela=[int]$script:CurrentScaleId
    if($idEscalaJanela -le 0){
        $idEscalaJanela=[int](Get-ScaleId)
    }
    if($idEscalaJanela -le 0){Show-Info 'PASSO 3: crie ou carregue a escala do mes primeiro.';return}
    if((Get-ScaleBlockCount $idEscalaJanela) -le 0){Show-Info 'PASSO 4: configure primeiro os blocos de horario desta escala.';Show-ScaleBlocksManager;return}

    $f=New-Object System.Windows.Forms.Form
    Set-FormTheme $f
    $f.Text='Escalas Vagas do mes'
    $f.StartPosition='CenterParent'
    $f.ClientSize=New-Object System.Drawing.Size(1040,570)
    $f.MinimumSize=New-Object System.Drawing.Size(900,500)
    $f.AutoScaleMode='Dpi'

    $top=New-Object System.Windows.Forms.FlowLayoutPanel
    $top.Dock='Top';$top.Height=58;$top.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$top.WrapContents=$false
    $f.Controls.Add($top)
    $bN=New-Button '+ NOVA VAGA' 120;$top.Controls.Add($bN)
    $bE=New-Button 'EDITAR' 95;$top.Controls.Add($bE)
    $bD=New-Button 'EXCLUIR' 95;$top.Controls.Add($bD)
    $bA=New-Button 'ATUALIZAR' 105;$top.Controls.Add($bA)
    $bC=New-Button 'FECHAR' 95;$top.Controls.Add($bC)

    $lbl=New-Object System.Windows.Forms.Label
    $lbl.Dock='Bottom';$lbl.Height=28;$lbl.Padding=New-Object System.Windows.Forms.Padding(10,5,0,0)
    $f.Controls.Add($lbl)

    $g=New-Object System.Windows.Forms.DataGridView
    Set-GridStyle $g
    $g.Dock='None'
    $g.Location=New-Object System.Drawing.Point(0,58)
    $g.Size=New-Object System.Drawing.Size(1020,445)
    $g.Anchor='Top,Bottom,Left,Right'
    $g.AutoGenerateColumns=$false
    $g.MultiSelect=$false
    $g.SelectionMode='FullRowSelect'

    $defs=@(
        @{Name='id';Header='ID';Width=1;Visible=$false},
        @{Name='Horario';Header='Horario';Width=340;Visible=$true},
        @{Name='Descricao';Header='Descricao';Width=340;Visible=$true},
        @{Name='Funcao';Header='Funcao';Width=80;Visible=$true},
        @{Name='Inicio';Header='Inicio';Width=95;Visible=$true},
        @{Name='Fim';Header='Fim';Width=95;Visible=$true},
        @{Name='Ordem';Header='Ordem';Width=65;Visible=$true}
    )
    foreach($d in $defs){
        $c=New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $c.Name=$d.Name;$c.HeaderText=$d.Header;$c.Width=$d.Width;$c.Visible=$d.Visible;$c.SortMode='NotSortable'
        if($d.Name -eq 'Descricao'){$c.AutoSizeMode='Fill';$c.MinimumWidth=260}
        [void]$g.Columns.Add($c)
    }
    $f.Controls.Add($g)

    $reload={
        try{
            $g.Rows.Clear()

            # Consulta identica a usada na grade principal para recuperar as vagas.
            $sql=("SELECT v.id AS vagaid,COALESCE(h.descricao,'SEM HORARIO DEFINIDO') AS horario,v.descricao,v.funcao,v.data_inicial,v.data_final,v.ordem,COALESCE(h.ordem,999999) AS horario_ordem FROM escala_vagas v LEFT JOIN horarios h ON h.id=v.horario_id WHERE v.escala_id={0} AND v.ativo=1 ORDER BY COALESCE(h.ordem,999999),v.ordem,v.id;" -f $idEscalaJanela)
            $t=Db-Query $sql

            # Fallback defensivo: se por qualquer motivo o ID corrente nao retornar linhas,
            # localiza novamente a escala pelo setor/ano/mes e repete a consulta.
            if($t.Rows.Count -eq 0){
                $sid=0;$ano=0;$mes=0
                $sid=[int](Get-SelectedSetorId)
                $ano=[int]$script:numAno.Value
                $mes=Get-ComboSelectedInt $script:cboMes 0
                if($sid -gt 0 -and $ano -gt 0 -and $mes -gt 0){
                    $esc=Db-Query ("SELECT id FROM escalas WHERE setor_id={0} AND ano={1} AND mes={2} LIMIT 1;" -f $sid,$ano,$mes)
                    if($esc.Rows.Count -gt 0){
                        $idAlt=[int]$esc.Rows[0]['id']
                        if($idAlt -gt 0 -and $idAlt -ne $idEscalaJanela){
                            $idEscalaJanela=$idAlt
                            $sql=("SELECT v.id AS vagaid,COALESCE(h.descricao,'SEM HORARIO DEFINIDO') AS horario,v.descricao,v.funcao,v.data_inicial,v.data_final,v.ordem,COALESCE(h.ordem,999999) AS horario_ordem FROM escala_vagas v LEFT JOIN horarios h ON h.id=v.horario_id WHERE v.escala_id={0} AND v.ativo=1 ORDER BY COALESCE(h.ordem,999999),v.ordem,v.id;" -f $idEscalaJanela)
                            $t=Db-Query $sql
                        }
                    }
                }
            }

            foreach($r in $t.Rows){
                $ini='';$fim=''
                try{$ini=(ConvertFrom-DbDateOnly $r['data_inicial']).ToString('dd/MM/yyyy')}catch{$ini=[string]$r['data_inicial']}
                try{$fim=(ConvertFrom-DbDateOnly $r['data_final']).ToString('dd/MM/yyyy')}catch{$fim=[string]$r['data_final']}
                $ix=$g.Rows.Add()
                $row=$g.Rows[$ix]
                $row.Cells[0].Value=[int]$r['vagaid']
                $row.Cells[1].Value=[string]$r['horario']
                $row.Cells[2].Value=[string]$r['descricao']
                $row.Cells[3].Value=[string]$r['funcao']
                $row.Cells[4].Value=$ini
                $row.Cells[5].Value=$fim
                $row.Cells[6].Value=[string]$r['ordem']
            }

            $q=$t.Rows.Count
            $lbl.Text=('{0} escala(s) vaga(s) cadastrada(s) neste mes.' -f $q)
            $g.Refresh()

            if($q -gt 0){
                $g.ClearSelection()
                $found=$false
                if($SelecionarVagaId -gt 0){
                    foreach($row in $g.Rows){
                        if($row.IsNewRow){continue}
                        if([int]$row.Cells[0].Value -eq $SelecionarVagaId){
                            $row.Selected=$true;$g.CurrentCell=$row.Cells[2];$found=$true;break
                        }
                    }
                }
                if(-not $found){$g.Rows[0].Selected=$true;$g.CurrentCell=$g.Rows[0].Cells[2]}
            }
        }catch{
            Show-Error ('Falha ao carregar Escalas Vagas:`r`n'+$_.Exception.Message)
        }
    }.GetNewClosure()

    & $reload
    $bN.Add_Click({if(Show-EscalaVagaDialog 0 $idEscalaJanela $HorarioIdPadrao){Load-Escala;$idEscalaJanela=[int]$script:CurrentScaleId;& $reload}})
    $bE.Add_Click({if($null -eq $g.CurrentRow -or $g.CurrentRow.IsNewRow){Show-Info 'Selecione uma vaga.';return};$id=[int]$g.CurrentRow.Cells[0].Value;if($id -le 0){Show-Info 'Selecione uma vaga valida.';return};if(Show-EscalaVagaDialog $id $idEscalaJanela){Load-Escala;& $reload}})
    $bD.Add_Click({if($null -eq $g.CurrentRow -or $g.CurrentRow.IsNewRow){Show-Info 'Selecione uma vaga.';return};$id=[int]$g.CurrentRow.Cells[0].Value;if($id -le 0){Show-Info 'Selecione uma vaga valida.';return};$oid=0;$oid=[int](Db-Scalar "SELECT COALESCE(ocorrencia_id,0) FROM escala_vagas WHERE id=$id;");if($oid -gt 0){Show-Info 'Esta Escala Vaga pertence a uma ocorrencia definitiva. Exclua a ocorrencia na aba Ocorrencias para que a vaga seja removida e o servidor reativado corretamente.';return};if(Confirm-Action 'Excluir esta Escala Vaga?'){Db-Exec "DELETE FROM escala_vagas WHERE id=$id;";Load-Escala;& $reload}})
    $bA.Add_Click({Load-Escala;$idEscalaJanela=[int]$script:CurrentScaleId;& $reload})
    $bC.Add_Click({$f.Close()})
    $g.Add_CellDoubleClick({param($sender,$e);if($e.RowIndex -lt 0){return};$row=$g.Rows[$e.RowIndex];$id=[int]$row.Cells[0].Value;if($id -gt 0 -and (Show-EscalaVagaDialog $id $idEscalaJanela)){Load-Escala;& $reload}})
    [void]$f.ShowDialog($script:MainForm)
    $f.Dispose()
}

function Show-DiaDialog {
    param([int]$EsId,[datetime]$Date)
    $ds=$Date.ToString('yyyy-MM-dd')
    $existing=Db-Query "SELECT id,sigla,texto,origem,ocorrencia_id FROM escala_dias WHERE escala_servidor_id=$EsId AND data=$(Sql-Q $ds);"
    if($existing.Rows.Count -gt 0 -and [string]$existing.Rows[0]['origem'] -eq 'OCORRENCIA'){
        Show-Info 'Este dia foi gerado por uma ocorrencia. Para manter a sincronizacao, edite ou exclua a ocorrencia na aba Ocorrencias.';return
    }
    $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=('Lancamento - {0:dd/MM/yyyy}' -f $Date);$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(620,430);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false
    $l1=New-Object System.Windows.Forms.Label;$l1.Text='Sigla (opcional)';$l1.Location=New-Object System.Drawing.Point(20,30);$l1.Size=New-Object System.Drawing.Size(120,22);$f.Controls.Add($l1)
    $cb=New-Object System.Windows.Forms.ComboBox;$cb.Location=New-Object System.Drawing.Point(145,27);$cb.Size=New-Object System.Drawing.Size(430,26);$cb.DropDownStyle='DropDownList';$sg=Db-Query "SELECT '' AS sigla, '(sem sigla / texto livre)' AS item UNION ALL SELECT sigla, sigla || ' - ' || descricao FROM siglas WHERE ativo=1 AND UPPER(sigla) NOT IN ('FER','AT') ORDER BY item;";$bsTmp5=New-Object System.Windows.Forms.BindingSource;$bsTmp5.DataSource=$sg;$cb.DataSource=$bsTmp5;$cb.ValueMember='sigla';$cb.DisplayMember='item';$f.Controls.Add($cb)
    $l2=New-Object System.Windows.Forms.Label;$l2.Text='Texto na escala';$l2.Location=New-Object System.Drawing.Point(20,80);$l2.Size=New-Object System.Drawing.Size(120,22);$f.Controls.Add($l2)
    $tb=New-Object System.Windows.Forms.TextBox;$tb.Location=New-Object System.Drawing.Point(145,77);$tb.Size=New-Object System.Drawing.Size(430,180);$tb.Multiline=$true;$tb.ScrollBars='Vertical';$f.Controls.Add($tb)
    $noteDia=New-Object System.Windows.Forms.Label;$noteDia.Text='Fluxo oficial: FERIAS e ATESTADO = aba Ocorrencias. ESCALA VAGA = botao ESCALA VAGA.';$noteDia.Location=New-Object System.Drawing.Point(20,265);$noteDia.Size=New-Object System.Drawing.Size(555,32);$noteDia.ForeColor=[System.Drawing.Color]::FromArgb(70,85,100);$f.Controls.Add($noteDia)
    if($existing.Rows.Count){$old=[string]$existing.Rows[0]['sigla'];for($i=0;$i -lt $cb.Items.Count;$i++){if([string]$cb.GetItemText($cb.Items[$i]) -like ($old+' *')){$cb.SelectedIndex=$i;break}};$tb.Text=[string]$existing.Rows[0]['texto']}
    $clear=New-Button 'LIMPAR DIA' 130;$clear.Location=New-Object System.Drawing.Point(20,330);$ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(315,330);$cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(450,330);$cancel.DialogResult='Cancel'
    $clear.Add_Click({try{Db-Exec "DELETE FROM escala_dias WHERE escala_servidor_id=$EsId AND data=$(Sql-Q $ds) AND origem<>'OCORRENCIA';";$f.DialogResult='OK';$f.Close()}catch{Show-Error $_.Exception.Message}})
    $ok.Add_Click({
        try{
            $sig=([string]$cb.SelectedValue).Trim().ToUpperInvariant();$txt=$tb.Text.Trim();$txtUpper=$txt.ToUpperInvariant()
            if($sig -in @('FER','AT')){Show-Info 'FERIAS e ATESTADO devem ser registrados somente pela aba Ocorrencias.';return}
            if($txtUpper -in @('FERIAS','FÉRIAS','ATESTADO','ESCALA VAGA')){Show-Info 'Este tipo possui fluxo proprio: FERIAS/ATESTADO pela aba Ocorrencias e ESCALA VAGA pelo botao ESCALA VAGA.';return}
            if($sig -in @('FF','PF','FS')){
                $erroRegra=Get-SiglaDateRuleError $sig $Date
                if(-not [string]::IsNullOrWhiteSpace([string]$erroRegra)){Show-Info $erroRegra;return}
            }
            if(-not $sig -and -not $txt){Db-Exec "DELETE FROM escala_dias WHERE escala_servidor_id=$EsId AND data=$(Sql-Q $ds) AND origem<>'OCORRENCIA';"}
            else{
                # Protecao em duas camadas: revalida imediatamente antes de salvar e
                # o proprio UPSERT nunca atualiza uma linha cuja origem e OCORRENCIA.
                $prot=[int](Db-Scalar "SELECT COUNT(*) FROM escala_dias WHERE escala_servidor_id=$EsId AND data=$(Sql-Q $ds) AND origem='OCORRENCIA';")
                if($prot -gt 0){Show-Info 'Este dia passou a ser controlado por uma ocorrencia. Edite a ocorrencia na aba Ocorrencias.';return}
                Db-Exec ("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) SELECT {0},{1},{2},{3},'MANUAL' WHERE NOT EXISTS(SELECT 1 FROM escala_dias WHERE escala_servidor_id={0} AND data={1} AND origem='OCORRENCIA') ON CONFLICT(escala_servidor_id,data) DO UPDATE SET sigla=excluded.sigla,texto=excluded.texto,origem='MANUAL',ocorrencia_id=NULL,atualizado_em=CURRENT_TIMESTAMP WHERE escala_dias.origem<>'OCORRENCIA';" -f $EsId,(Sql-Q $ds),(Sql-Q $sig),(Sql-Q $txt))
            }
            $f.DialogResult='OK';$f.Close()
        }catch{Show-Error $_.Exception.Message}
    })
    $f.Controls.Add($clear);$f.Controls.Add($ok);$f.Controls.Add($cancel);$dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){Load-Escala}
}

function Get-FaixaTiposAtivos {
    # Mapa SIGLA (maiuscula) -> dados visuais da faixa continua.
    # V1.0.14.41: cada tipo possui fundo/fonte proprios, independentes da aba Siglas.
    $t = Db-Query "SELECT UPPER(TRIM(sigla)) AS sigla, COALESCE(NULLIF(TRIM(faixa_texto),''),nome) AS texto, COALESCE(faixa_dias_minimo,1) AS dias, COALESCE(NULLIF(TRIM(faixa_cor_fundo),''),'#EEEEEE') AS fundo, COALESCE(NULLIF(TRIM(faixa_cor_fonte),''),'#000000') AS fonte FROM tipos_ocorrencia WHERE ativo=1 AND faixa_ativa=1 AND COALESCE(TRIM(sigla),'')<>'';"
    $map = @{}
    foreach ($r in $t.Rows) {
        $map[[string]$r['sigla']] = @{
            Texto=[string]$r['texto']
            Dias=[int]$r['dias']
            Fundo=Get-SafeHexColor ([string]$r['fundo']) '#EEEEEE'
            Fonte=Get-SafeHexColor ([string]$r['fonte']) '#000000'
        }
    }
    return $map
}

function Load-TiposOcorrencia {
    try {
        if ($null -eq $script:gridTiposOc) { return }
        $t = Db-Query "SELECT id,nome AS Nome,COALESCE(sigla,'') AS Sigla,CASE WHEN gera_escala=1 THEN 'SIM' ELSE 'NAO' END AS Gera_Escala,CASE WHEN faixa_ativa=1 THEN 'SIM' ELSE 'NAO' END AS Faixa,COALESCE(faixa_texto,'') AS Texto_Faixa,faixa_dias_minimo AS Dias_Min,COALESCE(NULLIF(TRIM(faixa_cor_fundo),''),'#EEEEEE') AS Fundo_Faixa,COALESCE(NULLIF(TRIM(faixa_cor_fonte),''),'#000000') AS Fonte_Faixa,COALESCE(NULLIF(TRIM(faixa_texto),''),nome) AS Previa_Faixa,CASE WHEN gera_vaga=1 THEN 'SIM' ELSE 'NAO' END AS Definitiva,CASE WHEN ativo=1 THEN 'SIM' ELSE 'NAO' END AS Ativo FROM tipos_ocorrencia WHERE UPPER(nome)<>'ESCALA VAGA' ORDER BY nome;"
        $script:gridTiposOc.DataSource = $t
        if ($script:gridTiposOc.Columns.Contains('id')) { $script:gridTiposOc.Columns['id'].Visible = $false }
        if ($script:gridTiposOc.Columns.Contains('Nome')) { $script:gridTiposOc.Columns['Nome'].AutoSizeMode = 'Fill' }
        if ($script:gridTiposOc.Columns.Contains('Sigla')) { $script:gridTiposOc.Columns['Sigla'].Width = 70 }
        if ($script:gridTiposOc.Columns.Contains('Gera_Escala')) { $script:gridTiposOc.Columns['Gera_Escala'].Width = 90 }
        if ($script:gridTiposOc.Columns.Contains('Faixa')) { $script:gridTiposOc.Columns['Faixa'].Width = 70 }
        if ($script:gridTiposOc.Columns.Contains('Texto_Faixa')) { $script:gridTiposOc.Columns['Texto_Faixa'].Width = 150 }
        if ($script:gridTiposOc.Columns.Contains('Dias_Min')) { $script:gridTiposOc.Columns['Dias_Min'].Width = 72 }
        if ($script:gridTiposOc.Columns.Contains('Fundo_Faixa')) { $script:gridTiposOc.Columns['Fundo_Faixa'].Width = 105; $script:gridTiposOc.Columns['Fundo_Faixa'].HeaderText='Fundo' }
        if ($script:gridTiposOc.Columns.Contains('Fonte_Faixa')) { $script:gridTiposOc.Columns['Fonte_Faixa'].Width = 105; $script:gridTiposOc.Columns['Fonte_Faixa'].HeaderText='Fonte' }
        if ($script:gridTiposOc.Columns.Contains('Previa_Faixa')) { $script:gridTiposOc.Columns['Previa_Faixa'].Width = 170; $script:gridTiposOc.Columns['Previa_Faixa'].HeaderText='Previa da Faixa' }
        if ($script:gridTiposOc.Columns.Contains('Definitiva')) { $script:gridTiposOc.Columns['Definitiva'].Width = 80 }
        if ($script:gridTiposOc.Columns.Contains('Ativo')) { $script:gridTiposOc.Columns['Ativo'].Width = 65 }
        # Mostra as proprias cores no grid, como ja acontece na aba Siglas.
        foreach($row in $script:gridTiposOc.Rows){
            $bgHex=Get-SafeHexColor ([string]$row.Cells['Fundo_Faixa'].Value) '#EEEEEE'
            $fgHex=Get-SafeHexColor ([string]$row.Cells['Fonte_Faixa'].Value) '#000000'
            $bg=Color-FromHex $bgHex ([Drawing.Color]::FromArgb(238,238,238))
            $fg=Color-FromHex $fgHex ([Drawing.Color]::Black)
            $row.Cells['Fundo_Faixa'].Style.BackColor=$bg
            $row.Cells['Fundo_Faixa'].Style.ForeColor=Get-ContrastColor $bg
            $row.Cells['Fundo_Faixa'].Style.SelectionBackColor=$bg
            $row.Cells['Fundo_Faixa'].Style.SelectionForeColor=Get-ContrastColor $bg
            $row.Cells['Fundo_Faixa'].Style.Alignment='MiddleCenter'
            $row.Cells['Fonte_Faixa'].Style.BackColor=$fg
            $row.Cells['Fonte_Faixa'].Style.ForeColor=Get-ContrastColor $fg
            $row.Cells['Fonte_Faixa'].Style.SelectionBackColor=$fg
            $row.Cells['Fonte_Faixa'].Style.SelectionForeColor=Get-ContrastColor $fg
            $row.Cells['Fonte_Faixa'].Style.Alignment='MiddleCenter'
            $row.Cells['Previa_Faixa'].Style.BackColor=$bg
            $row.Cells['Previa_Faixa'].Style.ForeColor=$fg
            $row.Cells['Previa_Faixa'].Style.SelectionBackColor=$bg
            $row.Cells['Previa_Faixa'].Style.SelectionForeColor=$fg
            $row.Cells['Previa_Faixa'].Style.Alignment='MiddleCenter'
            $row.Cells['Previa_Faixa'].Style.Font=$script:FontSemibold9
        }
    } catch { Show-Error $_.Exception.Message }
}

function Show-TipoOcorrenciaDialog {
    param([int]$Id = 0)
    try {
        $data = $null
        if ($Id -gt 0) { $q = Db-Query "SELECT * FROM tipos_ocorrencia WHERE id=$Id;"; if ($q.Rows.Count) { $data = $q.Rows[0] } }
        $f = New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text = $(if ($Id) { 'Editar tipo de ocorrencia / faixa' } else { 'Novo tipo de ocorrencia / faixa' })
        $f.StartPosition = 'CenterParent'; $f.ClientSize = New-Object System.Drawing.Size(700,720); $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false; $f.AutoScaleMode='Dpi'

        $y = 22
        $lNome = New-Object System.Windows.Forms.Label; $lNome.Text = 'Nome'; $lNome.Location = New-Object System.Drawing.Point(24,$y); $lNome.Size = New-Object System.Drawing.Size(110,24); $f.Controls.Add($lNome)
        $txtNome = New-Object System.Windows.Forms.TextBox; $txtNome.Location = New-Object System.Drawing.Point(155,$y); $txtNome.Size = New-Object System.Drawing.Size(500,27); $f.Controls.Add($txtNome); $y += 42

        $lSigla = New-Object System.Windows.Forms.Label; $lSigla.Text = 'Sigla'; $lSigla.Location = New-Object System.Drawing.Point(24,$y); $lSigla.Size = New-Object System.Drawing.Size(110,24); $f.Controls.Add($lSigla)
        $txtSigla = New-Object System.Windows.Forms.TextBox; $txtSigla.Location = New-Object System.Drawing.Point(155,$y); $txtSigla.Size = New-Object System.Drawing.Size(110,27); $f.Controls.Add($txtSigla)
        $tipSigla = New-Object System.Windows.Forms.ToolTip; $tipSigla.SetToolTip($txtSigla,'Sigla curta lancada na escala (ex.: FER, AT). A cor da FAIXA abaixo e independente da cor cadastrada para a sigla.')
        $y += 42

        $lObs = New-Object System.Windows.Forms.Label; $lObs.Text = 'Uso / Observacao'; $lObs.Location = New-Object System.Drawing.Point(24,$y); $lObs.Size = New-Object System.Drawing.Size(120,24); $f.Controls.Add($lObs)
        $txtObs = New-Object System.Windows.Forms.TextBox; $txtObs.Location = New-Object System.Drawing.Point(155,$y); $txtObs.Size = New-Object System.Drawing.Size(500,27); $f.Controls.Add($txtObs); $y += 42

        $chkGera = New-Object System.Windows.Forms.CheckBox; $chkGera.Text = 'Gera lancamento na escala'; $chkGera.Location = New-Object System.Drawing.Point(155,$y); $chkGera.Size = New-Object System.Drawing.Size(280,26); $chkGera.Checked = $true; $f.Controls.Add($chkGera)
        $chkAtivo = New-Object System.Windows.Forms.CheckBox; $chkAtivo.Text = 'Ativo'; $chkAtivo.Location = New-Object System.Drawing.Point(455,$y); $chkAtivo.Size = New-Object System.Drawing.Size(120,26); $chkAtivo.Checked = $true; $f.Controls.Add($chkAtivo); $y += 38

        $chkGeraVaga = New-Object System.Windows.Forms.CheckBox; $chkGeraVaga.Text = 'Costuma ser definitiva (sugere converter a vaga do servidor em ESCALA VAGA)'; $chkGeraVaga.Location = New-Object System.Drawing.Point(24,$y); $chkGeraVaga.Size = New-Object System.Drawing.Size(620,26); $f.Controls.Add($chkGeraVaga)
        $tipGeraVaga = New-Object System.Windows.Forms.ToolTip; $tipGeraVaga.SetToolTip($chkGeraVaga,'So define o valor inicial da caixa "Ocorrencia definitiva" ao abrir uma nova ocorrencia deste tipo. O usuario ainda pode desmarcar naquela tela.')
        $y += 40

        $sep = New-Object System.Windows.Forms.Label; $sep.Text = 'FAIXA CONTINUA NA GRADE / IMPRESSAO'; $sep.Font = New-Object System.Drawing.Font('Segoe UI Semibold',9); $sep.ForeColor = [System.Drawing.Color]::FromArgb(90,105,124); $sep.Location = New-Object System.Drawing.Point(24,$y); $sep.AutoSize = $true; $f.Controls.Add($sep); $y += 28

        $chkFaixa = New-Object System.Windows.Forms.CheckBox; $chkFaixa.Text = 'Mostrar como faixa continua (celula visual mesclada, em vez de sigla dia a dia)'; $chkFaixa.Location = New-Object System.Drawing.Point(24,$y); $chkFaixa.Size = New-Object System.Drawing.Size(600,26); $f.Controls.Add($chkFaixa); $y += 36

        $lTxtFaixa = New-Object System.Windows.Forms.Label; $lTxtFaixa.Text = 'Texto da faixa'; $lTxtFaixa.Location = New-Object System.Drawing.Point(24,$y); $lTxtFaixa.Size = New-Object System.Drawing.Size(120,24); $f.Controls.Add($lTxtFaixa)
        $txtFaixaTexto = New-Object System.Windows.Forms.TextBox; $txtFaixaTexto.Location = New-Object System.Drawing.Point(155,$y); $txtFaixaTexto.Size = New-Object System.Drawing.Size(500,27); $f.Controls.Add($txtFaixaTexto); $y += 42

        $lDiasMin = New-Object System.Windows.Forms.Label; $lDiasMin.Text = 'Dias minimos p/ virar faixa'; $lDiasMin.Location = New-Object System.Drawing.Point(24,$y); $lDiasMin.Size = New-Object System.Drawing.Size(165,24); $f.Controls.Add($lDiasMin)
        $numDiasMin = New-Object System.Windows.Forms.NumericUpDown; $numDiasMin.Location = New-Object System.Drawing.Point(195,$y); $numDiasMin.Size = New-Object System.Drawing.Size(75,27); $numDiasMin.Minimum = 1; $numDiasMin.Maximum = 31; $numDiasMin.Value = 1; $f.Controls.Add($numDiasMin)
        $tipDiasMin = New-Object System.Windows.Forms.ToolTip; $tipDiasMin.SetToolTip($numDiasMin,'Lancamentos com menos dias que este numero aparecem normalmente, dia a dia. A partir deste numero, viram uma unica faixa.')
        $y += 44

        $lCorFundo = New-Object System.Windows.Forms.Label; $lCorFundo.Text = 'Cor do fundo da faixa'; $lCorFundo.Location = New-Object System.Drawing.Point(24,$y); $lCorFundo.Size = New-Object System.Drawing.Size(145,24); $f.Controls.Add($lCorFundo)
        $swFaixaFundo=New-Object System.Windows.Forms.Label; $swFaixaFundo.Location=New-Object System.Drawing.Point(175,($y-5)); $swFaixaFundo.Size=New-Object System.Drawing.Size(52,34); $swFaixaFundo.BorderStyle='FixedSingle'; $f.Controls.Add($swFaixaFundo)
        $tbFaixaFundo=New-Object System.Windows.Forms.TextBox; $tbFaixaFundo.Location=New-Object System.Drawing.Point(238,$y); $tbFaixaFundo.Size=New-Object System.Drawing.Size(110,27); $tbFaixaFundo.ReadOnly=$true; $tbFaixaFundo.TextAlign='Center'; $f.Controls.Add($tbFaixaFundo)
        $btnFaixaFundo=New-Button 'ESCOLHER COR' 145; $btnFaixaFundo.Location=New-Object System.Drawing.Point(365,($y-5)); $f.Controls.Add($btnFaixaFundo); $y += 46

        $lCorFonte = New-Object System.Windows.Forms.Label; $lCorFonte.Text = 'Cor da fonte da faixa'; $lCorFonte.Location = New-Object System.Drawing.Point(24,$y); $lCorFonte.Size = New-Object System.Drawing.Size(145,24); $f.Controls.Add($lCorFonte)
        $swFaixaFonte=New-Object System.Windows.Forms.Label; $swFaixaFonte.Location=New-Object System.Drawing.Point(175,($y-5)); $swFaixaFonte.Size=New-Object System.Drawing.Size(52,34); $swFaixaFonte.BorderStyle='FixedSingle'; $f.Controls.Add($swFaixaFonte)
        $tbFaixaFonte=New-Object System.Windows.Forms.TextBox; $tbFaixaFonte.Location=New-Object System.Drawing.Point(238,$y); $tbFaixaFonte.Size=New-Object System.Drawing.Size(110,27); $tbFaixaFonte.ReadOnly=$true; $tbFaixaFonte.TextAlign='Center'; $f.Controls.Add($tbFaixaFonte)
        $btnFaixaFonte=New-Button 'ESCOLHER COR' 145; $btnFaixaFonte.Location=New-Object System.Drawing.Point(365,($y-5)); $f.Controls.Add($btnFaixaFonte); $y += 48

        $lPrevFaixa = New-Object System.Windows.Forms.Label; $lPrevFaixa.Text='Previa da faixa'; $lPrevFaixa.Location=New-Object System.Drawing.Point(24,$y); $lPrevFaixa.Size=New-Object System.Drawing.Size(120,24); $f.Controls.Add($lPrevFaixa)
        $prevFaixa=New-Object System.Windows.Forms.Label; $prevFaixa.Location=New-Object System.Drawing.Point(155,($y-8)); $prevFaixa.Size=New-Object System.Drawing.Size(355,42); $prevFaixa.BorderStyle='FixedSingle'; $prevFaixa.TextAlign='MiddleCenter'; $prevFaixa.Font=New-Object System.Drawing.Font('Segoe UI Semibold',10); $f.Controls.Add($prevFaixa)
        $btnFaixaPadrao=New-Button 'CINZA / PRETO' 135; $btnFaixaPadrao.Location=New-Object System.Drawing.Point(520,($y-7)); $f.Controls.Add($btnFaixaPadrao); $y += 55

        $fundoFaixaHex='#EEEEEE'; $fonteFaixaHex='#000000'
        if ($data) {
            $txtNome.Text = [string]$data['nome']; $txtSigla.Text = [string]$data['sigla']; $txtObs.Text = [string]$data['uso_observacao']
            $chkGera.Checked = ([int]$data['gera_escala'] -eq 1); $chkAtivo.Checked = ([int]$data['ativo'] -eq 1)
            $chkGeraVaga.Checked = ([int]$data['gera_vaga'] -eq 1)
            $chkFaixa.Checked = ([int]$data['faixa_ativa'] -eq 1); $txtFaixaTexto.Text = [string]$data['faixa_texto']
            $numDiasMin.Value = [decimal][int]$data['faixa_dias_minimo']
            $fundoFaixaHex=Get-SafeHexColor ([string]$data['faixa_cor_fundo']) '#EEEEEE'
            $fonteFaixaHex=Get-SafeHexColor ([string]$data['faixa_cor_fonte']) '#000000'
        }
        $tbFaixaFundo.Text=$fundoFaixaHex; $tbFaixaFonte.Text=$fonteFaixaHex

        $updateFaixaPreview={
            $bg=Color-FromHex $tbFaixaFundo.Text ([Drawing.Color]::FromArgb(238,238,238))
            $fg=Color-FromHex $tbFaixaFonte.Text ([Drawing.Color]::Black)
            $swFaixaFundo.BackColor=$bg; $swFaixaFundo.ForeColor=Get-ContrastColor $bg
            $swFaixaFonte.BackColor=$fg; $swFaixaFonte.ForeColor=Get-ContrastColor $fg
            $prevFaixa.BackColor=$bg; $prevFaixa.ForeColor=$fg
            $tx=$txtFaixaTexto.Text.Trim(); if(-not $tx){$tx=$txtNome.Text.Trim()}; if(-not $tx){$tx='TEXTO DA FAIXA'}
            $prevFaixa.Text=$tx
        }
        $btnFaixaFundo.Add_Click({
            try{$cd=New-Object System.Windows.Forms.ColorDialog;$cd.FullOpen=$true;$cd.AnyColor=$true;$cd.Color=Color-FromHex $tbFaixaFundo.Text ([Drawing.Color]::FromArgb(238,238,238));if($cd.ShowDialog($f)-eq[System.Windows.Forms.DialogResult]::OK){$tbFaixaFundo.Text=Color-ToHex $cd.Color;& $updateFaixaPreview};$cd.Dispose()}catch{Show-Error $_.Exception.Message}
        })
        $btnFaixaFonte.Add_Click({
            try{$cd=New-Object System.Windows.Forms.ColorDialog;$cd.FullOpen=$true;$cd.AnyColor=$true;$cd.Color=Color-FromHex $tbFaixaFonte.Text ([Drawing.Color]::Black);if($cd.ShowDialog($f)-eq[System.Windows.Forms.DialogResult]::OK){$tbFaixaFonte.Text=Color-ToHex $cd.Color;& $updateFaixaPreview};$cd.Dispose()}catch{Show-Error $_.Exception.Message}
        })
        $btnFaixaPadrao.Add_Click({$tbFaixaFundo.Text='#EEEEEE';$tbFaixaFonte.Text='#000000';& $updateFaixaPreview})
        $txtFaixaTexto.Add_TextChanged({& $updateFaixaPreview}); $txtNome.Add_TextChanged({& $updateFaixaPreview}); & $updateFaixaPreview

        $ok = New-Button 'SALVAR' 120; $ok.Location = New-Object System.Drawing.Point(390,$y); Set-PrimaryButton $ok
        $ok.Add_Click({
            try {
                $nome = $txtNome.Text.Trim(); if (-not $nome) { Show-Info 'Informe o nome do tipo.'; return }
                if ($nome.ToUpperInvariant() -eq 'ESCALA VAGA') { Show-Info 'Este nome e reservado pelo sistema.'; return }
                $sigla = $txtSigla.Text.Trim().ToUpperInvariant()
                $obs = $txtObs.Text.Trim()
                $gera = $(if ($chkGera.Checked) { 1 } else { 0 })
                $ativo = $(if ($chkAtivo.Checked) { 1 } else { 0 })
                $geraVaga = $(if ($chkGeraVaga.Checked) { 1 } else { 0 })
                $faixaAtiva = $(if ($chkFaixa.Checked) { 1 } else { 0 })
                $faixaTexto = $txtFaixaTexto.Text.Trim(); if (-not $faixaTexto) { $faixaTexto = $nome }
                $diasMin = [int]$numDiasMin.Value
                $faixaFundo=Get-SafeHexColor $tbFaixaFundo.Text '#EEEEEE'
                $faixaFonte=Get-SafeHexColor $tbFaixaFonte.Text '#000000'
                if ($Id -gt 0) {
                    Db-Exec ("UPDATE tipos_ocorrencia SET nome={0},sigla={1},uso_observacao={2},gera_escala={3},ativo={4},faixa_ativa={5},faixa_texto={6},faixa_dias_minimo={7},gera_vaga={8},faixa_cor_fundo={9},faixa_cor_fonte={10} WHERE id={11};" -f (Sql-Q $nome),(Sql-Q $sigla),(Sql-Q $obs),$gera,$ativo,$faixaAtiva,(Sql-Q $faixaTexto),$diasMin,$geraVaga,(Sql-Q $faixaFundo),(Sql-Q $faixaFonte),$Id)
                } else {
                    Db-Exec ("INSERT INTO tipos_ocorrencia(nome,sigla,uso_observacao,gera_escala,ativo,faixa_ativa,faixa_texto,faixa_dias_minimo,gera_vaga,faixa_cor_fundo,faixa_cor_fonte) VALUES ({0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10});" -f (Sql-Q $nome),(Sql-Q $sigla),(Sql-Q $obs),$gera,$ativo,$faixaAtiva,(Sql-Q $faixaTexto),$diasMin,$geraVaga,(Sql-Q $faixaFundo),(Sql-Q $faixaFonte))
                }
                Load-TiposOcorrencia
                $f.DialogResult = 'OK'; $f.Close()
            } catch { Show-Error $_.Exception.Message }
        })
        $cancel = New-Button 'CANCELAR' 120; $cancel.Location = New-Object System.Drawing.Point(525,$y); $cancel.Add_Click({ $f.Close() })
        $f.Controls.Add($ok); $f.Controls.Add($cancel)
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch { Show-Error $_.Exception.Message }
}

function Toggle-TipoOcorrenciaAtiva {
    try {
        $id = Get-GridId $script:gridTiposOc; if ($id -le 0) { Show-Info 'Selecione um tipo.'; return }
        $at = [int](Db-Scalar "SELECT ativo FROM tipos_ocorrencia WHERE id=$id;")
        $novo = $(if ($at -eq 1) { 0 } else { 1 })
        Db-Exec "UPDATE tipos_ocorrencia SET ativo=$novo WHERE id=$id;"
        Load-TiposOcorrencia
    } catch { Show-Error $_.Exception.Message }
}

function Delete-TipoOcorrencia {
    try {
        $id = Get-GridId $script:gridTiposOc; if ($id -le 0) { Show-Info 'Selecione um tipo.'; return }
        $idSql=Sql-Int $id 'tipo_ocorrencia_id'
        $nome = [string](Db-Scalar "SELECT nome FROM tipos_ocorrencia WHERE id=$idSql;")
        if ($nome.ToUpperInvariant() -eq 'ESCALA VAGA') { Show-Info 'Este tipo e reservado pelo sistema e nao pode ser excluido.'; return }
        $emUso = [int](Db-Scalar "SELECT COUNT(*) FROM ocorrencias WHERE tipo_id=$idSql;")
        if ($emUso -gt 0) {
            if (-not (Confirm-Action ("Este tipo ja foi usado em {0} ocorrencia(s) cadastradas. Ele sera apenas DESATIVADO (os registros existentes continuam intactos, so deixa de aparecer para novos lancamentos). Continuar?" -f $emUso))) { return }
            Db-Exec "UPDATE tipos_ocorrencia SET ativo=0 WHERE id=$idSql;"
        } else {
            if (-not (Confirm-Action 'Excluir definitivamente este tipo de ocorrencia?')) { return }
            Db-Exec "DELETE FROM tipos_ocorrencia WHERE id=$idSql;"
        }
        Load-TiposOcorrencia
    } catch { Show-Error $_.Exception.Message }
}

function Load-Ocorrencias {
    try{
        $where="o.situacao='ATIVA'"
        if($null -ne $script:txtOcBusca){
            $busca=$script:txtOcBusca.Text.Trim()
            if($busca){$q=Sql-Q ('%'+$busca+'%');$where+=" AND (s.cp LIKE $q OR s.nome LIKE $q OR o.detalhamento LIKE $q OR o.documento LIKE $q)"}
        }
        $ctxSe=(Get-OcorrenciaContextClause 'se')
        if($null -ne $script:cboOcTipo){$v=Get-ComboSelectedInt $script:cboOcTipo 0;if($v -gt 0){$where+=" AND o.tipo_id=$v"}}
        $mes=0;$ano=0
        if($null -ne $script:cboOcMes){$mes=Get-ComboSelectedInt $script:cboOcMes 0}
        if($null -ne $script:cboOcAno){$ano=Get-ComboSelectedInt $script:cboOcAno 0}
        if($mes -gt 0 -and $ano -le 0){$ano=[int]$script:numAno.Value}
        if($mes -gt 0 -and $ano -gt 0){
            $ini=Get-Date -Year $ano -Month $mes -Day 1;$fim=$ini.AddMonths(1).AddDays(-1)
            $where+=(" AND o.data_inicial<={0} AND o.data_final>={1}" -f (Sql-Q ($fim.ToString('yyyy-MM-dd'))),(Sql-Q ($ini.ToString('yyyy-MM-dd'))))
        }elseif($ano -gt 0){
            $ini=Get-Date -Year $ano -Month 1 -Day 1;$fim=Get-Date -Year $ano -Month 12 -Day 31
            $where+=(" AND o.data_inicial<={0} AND o.data_final>={1}" -f (Sql-Q ($fim.ToString('yyyy-MM-dd'))),(Sql-Q ($ini.ToString('yyyy-MM-dd'))))
        }
        # V1.0.14.37 - a ocorrencia acompanha o servidor: alem das registradas no Setor/Sub_Setor filtrado,
        # lista as que afetam servidores hoje lotados nele (na coluna Setor aparece a unidade de origem).
        if(-not [string]::IsNullOrWhiteSpace($ctxSe)){
            $ctxSe2=(Get-OcorrenciaContextClause 'se2')
            $mesEsc='';if($mes -gt 0 -and $ano -gt 0){$mesEsc=(' AND e2.ano={0} AND e2.mes={1}' -f $ano,$mes)}
            $where+=(" AND ((1=1{0}) OR EXISTS(SELECT 1 FROM escala_servidores es2 JOIN escalas e2 ON e2.id=es2.escala_id JOIN setores se2 ON se2.id=e2.setor_id WHERE es2.servidor_id=o.servidor_id AND es2.ativo=1 AND se2.ativo=1{1}{2} AND (e2.ano*100+e2.mes) BETWEEN CAST(substr(o.data_inicial,1,4)||substr(o.data_inicial,6,2) AS INTEGER) AND CAST(substr(o.data_final,1,4)||substr(o.data_final,6,2) AS INTEGER)))" -f $ctxSe,$ctxSe2,$mesEsc)
        }
        $t=Db-Query "SELECT o.id,s.cp AS CP,s.nome AS Servidor,COALESCE(sp.nome,se.nome) AS Setor,COALESCE(ss.nome,'') AS Sub_Setor,t.nome AS Tipo,t.sigla AS Sigla,strftime('%d/%m/%Y',o.data_inicial) AS Inicio,strftime('%d/%m/%Y',o.data_final) AS Fim,o.detalhamento AS Detalhamento,o.documento AS Documento,o.origem AS Origem FROM ocorrencias o JOIN servidores s ON s.id=o.servidor_id JOIN setores se ON se.id=o.setor_id LEFT JOIN setores sp ON sp.id=se.setor_pai_id LEFT JOIN sub_setores ss ON ss.id=se.sub_setor_origem_id JOIN tipos_ocorrencia t ON t.id=o.tipo_id WHERE $where ORDER BY o.data_inicial DESC,s.nome;"
        if($t.Columns.Count -eq 0){foreach($n in @('id','CP','Servidor','Setor','Sub_Setor','Tipo','Sigla','Inicio','Fim','Detalhamento','Documento','Origem')){$t.Columns.Add($n,[string])|Out-Null}}
        $script:gridOcorrencias.DataSource=$t
        if($script:gridOcorrencias.Columns.Contains('id')){$script:gridOcorrencias.Columns['id'].Visible=$false}
        if($script:gridOcorrencias.Columns.Contains('Servidor')){$script:gridOcorrencias.Columns['Servidor'].AutoSizeMode='Fill'}
        if($script:gridOcorrencias.Columns.Contains('Setor')){$script:gridOcorrencias.Columns['Setor'].Width=180}
        if($script:gridOcorrencias.Columns.Contains('Sub_Setor')){$script:gridOcorrencias.Columns['Sub_Setor'].Width=160}
        if($script:gridOcorrencias.Columns.Contains('CP')){$script:gridOcorrencias.Columns['CP'].Width=75}
        if($script:gridOcorrencias.Columns.Contains('Inicio')){$script:gridOcorrencias.Columns['Inicio'].Width=95}
        if($script:gridOcorrencias.Columns.Contains('Fim')){$script:gridOcorrencias.Columns['Fim'].Width=95}
        if($null -ne $script:lblOcCount){$script:lblOcCount.Text=$(if($script:gridOcorrencias.Rows.Count -eq 0){'0 ocorrencia(s). Ferias e Atestados devem ser cadastrados nesta aba.'}else{('{0} ocorrencia(s)' -f $script:gridOcorrencias.Rows.Count)})}
    }catch{Show-Error $_.Exception.Message}
}

function Test-TipoOcorrenciaGeraEscala {
    # V1.0.14.37 - mesma regra dos gatilhos: so tipos que GERAM escala (gera_escala=1 e sigla preenchida)
    # ocupam os dias da grade. Tipos informativos (ex.: Remanejo de Periodo/Setor) nao bloqueiam lancamentos.
    param([int]$TipoId)
    if($TipoId -le 0){return $true}
    $v=Db-Scalar ("SELECT COUNT(*) FROM tipos_ocorrencia WHERE id={0} AND gera_escala=1 AND COALESCE(sigla,'')<>'';" -f $TipoId)
    return ([int]$v -gt 0)
}

function Test-ManualConflict {
    # So bloqueia por causa de lancamento DIGITADO A MAO (origem='MANUAL').
    # As marcacoes automaticas (FS de fim de semana, FF de feriado, PF de ponto
    # facultativo) sao geradas de novo sozinhas (Sync-Calendario08hForScale), entao nao faz
    # sentido travar uma ocorrencia por causa delas.
    param([int]$SetorId,[int]$ServidorId,[datetime]$Ini,[datetime]$Fim)
    $start=Sql-Q ($Ini.ToString('yyyy-MM-dd'));$end=Sql-Q ($Fim.ToString('yyyy-MM-dd'))
    $sql="SELECT COUNT(*) FROM escala_dias ed JOIN escala_servidores es ON es.id=ed.escala_servidor_id WHERE es.servidor_id=$ServidorId AND ed.data BETWEEN $start AND $end AND ed.origem='MANUAL' AND (COALESCE(ed.sigla,'')<>'' OR COALESCE(ed.texto,'')<>'');"
    $v=Db-Scalar $sql;return ([int]$v -gt 0)
}

function Get-OcorrenciaValidationError {
    # V1.0.14.34 - uma unica regra para ocorrencia individual e ocorrencia em lote.
    # V1.0.14.37 - recebe o Tipo: conflito com lancamento MANUAL so vale para tipos que geram escala.
    # Retorna texto vazio quando o periodo pode ser gravado.
    param([int]$SetorId,[int]$ServidorId,[datetime]$Ini,[datetime]$Fim,[int]$ExcludeId=0,[int]$TipoId=0)
    if($SetorId -le 0 -or $ServidorId -le 0){return 'Setor ou servidor invalido para validar a ocorrencia.'}
    if($Fim.Date -lt $Ini.Date){return 'A Data Final nao pode ser anterior a Data Inicial.'}
    $exclude=$(if($ExcludeId -gt 0){" AND id<>$ExcludeId"}else{''})
    $ov=Db-Scalar ("SELECT COUNT(*) FROM ocorrencias WHERE situacao='ATIVA' AND servidor_id={0} AND data_inicial<={1} AND data_final>={2}{3};" -f $ServidorId,(Sql-Q ($Fim.ToString('yyyy-MM-dd'))),(Sql-Q ($Ini.ToString('yyyy-MM-dd'))),$exclude)
    if([int]$ov -gt 0){return 'Ja existe uma ocorrencia ativa deste servidor que se sobrepoe ao periodo informado. O lancamento foi bloqueado.'}
    if((Test-TipoOcorrenciaGeraEscala $TipoId) -and (Test-ManualConflict $SetorId $ServidorId $Ini $Fim)){return 'Existem lancamentos manuais na escala dentro deste periodo. Limpe esses dias antes de registrar ou alterar a ocorrencia.'}
    return ''
}

function Show-OcorrenciaDialog {
    param([int]$Id=0,[int]$PreServidorId=0,[int]$PreSetorId=0,$PreDataIni=$null,$PreDataFim=$null)
    $data=$null
    if($Id -gt 0){
        $tmp=Db-Query "SELECT * FROM ocorrencias WHERE id=$Id;"
        if($tmp.Rows.Count -eq 0){Show-Info 'Ocorrencia nao encontrada.';return}
        $data=$tmp.Rows[0]
    }

    $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f
    $f.Text=$(if($Id -gt 0){'Editar ocorrencia'}else{'Nova ocorrencia'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(790,705);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false;$f.AutoScaleMode='Dpi'

    $labels=@('Servidor','Setor Principal','Sub_Setor','Tipo','Data Inicial','Data Final','Detalhamento','Documento','Texto na Escala')
    $ys=@(25,75,125,175,225,275,325,375,425)
    for($i=0;$i -lt $labels.Count;$i++){$l=New-Object System.Windows.Forms.Label;$l.Text=$labels[$i];$l.Location=New-Object System.Drawing.Point(20,$ys[$i]);$l.Size=New-Object System.Drawing.Size(130,22);$f.Controls.Add($l)}

    $cbS=New-Object System.Windows.Forms.ComboBox;$cbS.Location=New-Object System.Drawing.Point(160,22);$cbS.Size=New-Object System.Drawing.Size(590,26);$cbS.DropDownStyle='DropDownList';$f.Controls.Add($cbS)
    $cbSet=New-Object System.Windows.Forms.ComboBox;$cbSet.Location=New-Object System.Drawing.Point(160,72);$cbSet.Size=New-Object System.Drawing.Size(590,26);$cbSet.DropDownStyle='DropDownList';$sets=Db-Query "SELECT id,nome FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=0 AND COALESCE(especial,0)=0 ORDER BY nome;";$bsTmp6=New-Object System.Windows.Forms.BindingSource;$bsTmp6.DataSource=$sets;$cbSet.DataSource=$bsTmp6;$cbSet.ValueMember='id';$cbSet.DisplayMember='nome';$f.Controls.Add($cbSet)
    $cbSub=New-Object System.Windows.Forms.ComboBox;$cbSub.Location=New-Object System.Drawing.Point(160,122);$cbSub.Size=New-Object System.Drawing.Size(590,26);$cbSub.DropDownStyle='DropDownList';$f.Controls.Add($cbSub)
    $cbT=New-Object System.Windows.Forms.ComboBox;$cbT.Location=New-Object System.Drawing.Point(160,172);$cbT.Size=New-Object System.Drawing.Size(590,26);$cbT.DropDownStyle='DropDownList';$tp=Db-Query "SELECT id, nome || CASE WHEN COALESCE(sigla,'')<>'' THEN ' [' || sigla || ']' ELSE '' END AS item FROM tipos_ocorrencia WHERE ativo=1 AND UPPER(nome)<>'ESCALA VAGA' ORDER BY nome;";$bsTmp7=New-Object System.Windows.Forms.BindingSource;$bsTmp7.DataSource=$tp;$cbT.DataSource=$bsTmp7;$cbT.ValueMember='id';$cbT.DisplayMember='item';$f.Controls.Add($cbT)
    $d1=New-Object System.Windows.Forms.DateTimePicker;$d1.Format='Short';$d1.Location=New-Object System.Drawing.Point(160,222);$d1.Size=New-Object System.Drawing.Size(180,26);$f.Controls.Add($d1)
    $d2=New-Object System.Windows.Forms.DateTimePicker;$d2.Format='Short';$d2.Location=New-Object System.Drawing.Point(160,272);$d2.Size=New-Object System.Drawing.Size(180,26);$f.Controls.Add($d2)
    $tbDet=New-Object System.Windows.Forms.TextBox;$tbDet.Location=New-Object System.Drawing.Point(160,322);$tbDet.Size=New-Object System.Drawing.Size(590,25);$f.Controls.Add($tbDet)
    $tbDoc=New-Object System.Windows.Forms.TextBox;$tbDoc.Location=New-Object System.Drawing.Point(160,372);$tbDoc.Size=New-Object System.Drawing.Size(590,25);$f.Controls.Add($tbDoc)
    $tbTxt=New-Object System.Windows.Forms.TextBox;$tbTxt.Location=New-Object System.Drawing.Point(160,422);$tbTxt.Size=New-Object System.Drawing.Size(590,60);$tbTxt.Multiline=$true;$f.Controls.Add($tbTxt)
    $noteOc=New-Object System.Windows.Forms.Label;$noteOc.Text='Os servidores sao carregados da Escala Mensal do Setor/Sub_Setor e do mes da Data Inicial. Ferias e Atestados devem ser registrados aqui.';$noteOc.Location=New-Object System.Drawing.Point(20,495);$noteOc.Size=New-Object System.Drawing.Size(730,42);$noteOc.ForeColor=[System.Drawing.Color]::FromArgb(70,85,100);$f.Controls.Add($noteOc)

    $chkDefinitiva=New-Object System.Windows.Forms.CheckBox;$chkDefinitiva.Text='Ocorrencia definitiva (o servidor sai e uma ESCALA VAGA e criada no lugar dele, a partir da Data Inicial ate o fim do mes)';$chkDefinitiva.Location=New-Object System.Drawing.Point(20,540);$chkDefinitiva.Size=New-Object System.Drawing.Size(730,32);$f.Controls.Add($chkDefinitiva)
    # V1.0.14.36 - edicao de ocorrencia definitiva reconhece o vinculo real
    # com escala_vagas, em vez de sempre abrir o checkbox desmarcado.
    if($data){
        try{$chkDefinitiva.Checked=([int](Db-Scalar "SELECT COUNT(*) FROM escala_vagas WHERE ocorrencia_id=$Id AND ativo=1;") -gt 0)}catch{$chkDefinitiva.Checked=$false}
    }

    $refreshSub={
        $principal=Get-ComboSelectedInt $cbSet 0
        $dt=New-Object System.Data.DataTable;[void]$dt.Columns.Add('id',[int]);[void]$dt.Columns.Add('nome',[string])
        $r=$dt.NewRow();$r['id']=0;$r['nome']='(sem Sub_Setor)';[void]$dt.Rows.Add($r)
        if($principal -gt 0){$subs=Db-Query ("SELECT id,nome FROM sub_setores WHERE ativo=1 AND setor_id={0} ORDER BY nome;" -f $principal);foreach($x in $subs.Rows){$r=$dt.NewRow();$r['id']=[int]$x['id'];$r['nome']=[string]$x['nome'];[void]$dt.Rows.Add($r)}}
        Set-ComboDataSource $cbSub $dt 'nome' 'id'
    }
    $refreshServers={
        $keep=Get-ComboSelectedInt $cbS 0
        if($PreServidorId -gt 0){$keep=$PreServidorId}
        $principal=Get-ComboSelectedInt $cbSet 0;$sub=Get-ComboSelectedInt $cbSub 0
        $ano=$d1.Value.Year;$mes=$d1.Value.Month;$setId=0
        if($principal -gt 0){
            if($sub -gt 0){
                $v=Db-Scalar ("SELECT COALESCE(setor_escala_id,0) FROM sub_setores WHERE id={0} AND setor_id={1};" -f $sub,$principal)
                if($v){$setId=[int]$v}
                if($setId -le 0){$v=Db-Scalar ("SELECT COALESCE(MAX(id),0) FROM setores WHERE ativo=1 AND COALESCE(unidade_escala,0)=1 AND setor_pai_id={0} AND sub_setor_origem_id={1};" -f $principal,$sub);if($v){$setId=[int]$v}}
            }else{$setId=$principal}
        }
        $sv=New-Object System.Data.DataTable
        [void]$sv.Columns.Add('id',[int])
        [void]$sv.Columns.Add('item',[string])
        if($setId -gt 0){$sv=Db-Query ("SELECT DISTINCT s.id,s.cp || ' - ' || s.nome AS item FROM escalas e JOIN escala_servidores es ON es.escala_id=e.id AND es.ativo=1 JOIN servidores s ON s.id=es.servidor_id WHERE e.setor_id={0} AND e.ano={1} AND e.mes={2} ORDER BY s.nome;" -f $setId,$ano,$mes)}
        if($keep -gt 0){
            $exists=$false
            foreach($rr in $sv.Rows){if([int]$rr['id'] -eq $keep){$exists=$true;break}}
            if(-not $exists){
                $extra=Db-Query ("SELECT id,cp || ' - ' || nome AS item FROM servidores WHERE id={0};" -f $keep)
                if($sv.Columns.Count -eq 0){$sv=$extra}elseif($extra.Rows.Count -gt 0){$nr=$sv.NewRow();$nr['id']=$extra.Rows[0]['id'];$nr['item']=$extra.Rows[0]['item'];[void]$sv.Rows.InsertAt($nr,0)}
            }
        }
        Set-ComboDataSource $cbS $sv 'item' 'id';if($keep -gt 0){$cbS.SelectedValue=$keep}
        if($sv.Rows.Count -eq 0){$noteOc.Text='Nenhum servidor foi encontrado nesta Escala Mensal para o Setor/Sub_Setor e mes informados. Inclua primeiro o servidor na aba Escala.'}else{$noteOc.Text='Servidores carregados da Escala Mensal deste Setor/Sub_Setor e mes. Ferias e Atestados devem ser registrados aqui.'}
    }

    $initialEff=0
    if($data){$initialEff=[int]$data['setor_id'];$d1.Value=ConvertFrom-DbDateOnly $data['data_inicial'];$d2.Value=ConvertFrom-DbDateOnly $data['data_final']}
    elseif($PreSetorId -gt 0){$initialEff=$PreSetorId}
    elseif((Get-OcorrenciaExactEffectiveSetorId) -gt 0){$initialEff=Get-OcorrenciaExactEffectiveSetorId}
    else{$initialEff=Get-SelectedSetorId}

    $principalInit=0;$subInit=0
    if($initialEff -gt 0){$ctx=Db-Query ("SELECT COALESCE(setor_pai_id,id) AS principal_id,COALESCE(sub_setor_origem_id,0) AS sub_id FROM setores WHERE id={0};" -f $initialEff);if($ctx.Rows.Count){$principalInit=[int]$ctx.Rows[0]['principal_id'];$subInit=[int]$ctx.Rows[0]['sub_id']}}
    if($principalInit -le 0){$principalInit=Get-ComboSelectedInt $script:cboOcSetor 0}
    if(-not $data){
        if($PreDataIni -and $PreDataFim){
            $d1.Value=$PreDataIni;$d2.Value=$PreDataFim
        } else {
            $fm=Get-ComboSelectedInt $script:cboOcMes 0;$fy=Get-ComboSelectedInt $script:cboOcAno 0
            if($fm -gt 0 -and $fy -gt 0){$d1.Value=Get-Date -Year $fy -Month $fm -Day 1;$d2.Value=$d1.Value}
        }
    }
    if($data){$tbDet.Text=[string]$data['detalhamento'];$tbDoc.Text=[string]$data['documento'];$tbTxt.Text=[string]$data['texto_escala'];$PreServidorId=[int]$data['servidor_id']}
    # As selecoes de combo (SelectedValue) so funcionam de forma confiavel depois
    # que a janela realmente existe (BindingContext pronto) - por isso ficam
    # dentro de Add_Shown, nao aqui no meio da montagem da tela.
    $atualizarDefinitivaPadrao={
        if($data){return}
        $tipoIdAtual=Get-ComboSelectedInt $cbT 0
        if($tipoIdAtual -gt 0){
            $gv=Db-Scalar "SELECT gera_vaga FROM tipos_ocorrencia WHERE id=$tipoIdAtual;"
            $chkDefinitiva.Checked=([int]$gv -eq 1)
        }
    }.GetNewClosure()
    $cbT.Add_SelectedIndexChanged($atualizarDefinitivaPadrao)
    $restaurarSelecoes={
        if($principalInit -gt 0){$cbSet.SelectedValue=$principalInit}
        & $refreshSub
        if($subInit -gt 0){$cbSub.SelectedValue=$subInit}
        if($data){$cbT.SelectedValue=[int]$data['tipo_id']}
        & $refreshServers
        & $atualizarDefinitivaPadrao
    }.GetNewClosure()
    $f.Add_Shown($restaurarSelecoes)

    $cbSet.Add_SelectedIndexChanged({& $refreshSub;& $refreshServers})
    $cbSub.Add_SelectedIndexChanged({& $refreshServers})
    $d1.Add_ValueChanged({& $refreshServers})

    $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(485,595)
    $cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(620,595);$cancel.DialogResult='Cancel'
    $ok.Add_Click({
        try{
            if($null -eq $cbS.SelectedValue){Show-Info 'Selecione um servidor cadastrado nesta escala.';return}
            $svId=[int]$cbS.SelectedValue;$principal=[int]$cbSet.SelectedValue;$sub=[int]$cbSub.SelectedValue;$typeId=[int]$cbT.SelectedValue;$ini=$d1.Value.Date;$fim=$d2.Value.Date
            if($principal -le 0){Show-Info 'Selecione o Setor Principal.';return}
            if($fim -lt $ini){Show-Info 'A Data Final nao pode ser anterior a Data Inicial.';return}
            $setId=$(if($sub -gt 0){[int](Ensure-SubSetorScaleSector $principal $sub)}else{$principal})

            # Se esta ocorrencia ja for definitiva, sua linha de servidor fica
            # inativa por desenho. Na edicao, essa linha vinculada tambem conta
            # como pertencente a escala para permitir alterar/excluir com seguranca.
            $oldLink=$null;$oldLinkId=0;$oldOriginEsId=0
            if($Id -gt 0){
                $qLink=Db-Query "SELECT id,escala_id,COALESCE(escala_servidor_id_origem,0) AS es_origem FROM escala_vagas WHERE ocorrencia_id=$Id AND ativo=1 LIMIT 1;"
                if($qLink.Rows.Count -gt 0){
                    $oldLink=$qLink.Rows[0];$oldLinkId=[int]$oldLink['id'];$oldOriginEsId=[int]$oldLink['es_origem']
                    if($oldOriginEsId -le 0 -and $data){
                        $oldOriginEsId=[int](Db-Scalar ("SELECT id FROM escala_servidores WHERE escala_id={0} AND servidor_id={1} LIMIT 1;" -f [int]$oldLink['escala_id'],[int]$data['servidor_id']))
                    }
                }
            }
            $linkAllowance=$(if($Id -gt 0){" OR EXISTS(SELECT 1 FROM escala_vagas v WHERE v.ocorrencia_id=$Id AND v.escala_servidor_id_origem=es.id)"}else{''})
            $scaleCheck=[int](Db-Scalar ("SELECT COUNT(*) FROM escalas e JOIN escala_servidores es ON es.escala_id=e.id WHERE e.setor_id={0} AND es.servidor_id={1} AND (es.ativo=1{6}) AND ((e.ano={2} AND e.mes={3}) OR (e.ano={4} AND e.mes={5}));" -f $setId,$svId,$ini.Year,$ini.Month,$fim.Year,$fim.Month,$linkAllowance))
            if($scaleCheck -le 0){
                $dicaSetor=''
                $ondeAtual=Db-Scalar ("SELECT se.nome FROM escala_servidores es JOIN escalas e ON e.id=es.escala_id JOIN setores se ON se.id=e.setor_id WHERE es.servidor_id={0} AND es.ativo=1 AND se.ativo=1 AND ((e.ano={1} AND e.mes={2}) OR (e.ano={3} AND e.mes={4})) LIMIT 1;" -f $svId,$ini.Year,$ini.Month,$fim.Year,$fim.Month)
                if($ondeAtual){$dicaSetor=("`r`n`r`nNo periodo, o servidor esta lotado em '{0}'. Selecione esse Setor/Sub_Setor no campo Setor para salvar." -f [string]$ondeAtual)}
                Show-Info ('O servidor nao esta cadastrado na Escala Mensal deste Setor/Sub_Setor no periodo informado.'+$dicaSetor);return
            }
            $tipoCheck=Db-Query "SELECT UPPER(COALESCE(nome,'')) AS nome FROM tipos_ocorrencia WHERE id=$typeId;";if($tipoCheck.Rows.Count -gt 0 -and [string]$tipoCheck.Rows[0]['nome'] -eq 'ESCALA VAGA'){Show-Info 'Escala Vaga deve ser registrada somente pelo botao ESCALA VAGA na aba Escala.';return}
            $erroValidacao=Get-OcorrenciaValidationError $setId $svId $ini $fim $Id $typeId
            if(-not [string]::IsNullOrWhiteSpace([string]$erroValidacao)){Show-Info $erroValidacao;return}
            $tpRow=Db-Query "SELECT sigla,gera_escala FROM tipos_ocorrencia WHERE id=$typeId;"
            $txt=$tbTxt.Text.Trim();if(-not $txt -and $tpRow.Rows.Count){$txt=[string]$tpRow.Rows[0]['sigla']}

            $escId=0;$esIdServidor=0;$hidVaga=0;$funcaoVaga='';$descVaga='';$fimVaga=$null
            if($chkDefinitiva.Checked){
                $scaleRow=Db-Query "SELECT id,ano,mes FROM escalas WHERE setor_id=$setId AND ano=$($ini.Year) AND mes=$($ini.Month) LIMIT 1;"
                if($scaleRow.Rows.Count -eq 0){Show-Info 'Nao foi encontrada a Escala Mensal correspondente a Data Inicial para concluir a ocorrencia definitiva.';return}
                $escId=[int]$scaleRow.Rows[0]['id'];$anoEsc=[int]$scaleRow.Rows[0]['ano'];$mesEsc=[int]$scaleRow.Rows[0]['mes']
                $fimVaga=Get-Date -Year $anoEsc -Month $mesEsc -Day ([datetime]::DaysInMonth($anoEsc,$mesEsc))
                $srvInfo=Db-Query ("SELECT es.id AS es_id,es.horario_id,es.ativo,s.funcao FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id={0} AND es.servidor_id={1} AND (es.ativo=1 OR es.id={2}) LIMIT 1;" -f $escId,$svId,$oldOriginEsId)
                if($srvInfo.Rows.Count -eq 0){Show-Info 'O servidor nao possui uma linha valida nesta Escala Mensal. A ocorrencia definitiva nao foi gravada.';return}
                if($srvInfo.Rows[0]['horario_id'] -eq [DBNull]::Value){Show-Info 'O servidor esta sem bloco de horario nesta Escala Mensal. Defina o horario antes da ocorrencia definitiva.';return}
                $esIdServidor=[int]$srvInfo.Rows[0]['es_id'];$hidVaga=[int]$srvInfo.Rows[0]['horario_id'];$funcaoVaga=[string]$srvInfo.Rows[0]['funcao']
                $descVaga=('ESCALA VAGA - {0}' -f $txt)
            }

            # Ocorrencia, vaga e ativacao/inativacao do servidor sao gravadas na
            # MESMA conexao/transacao. O vinculo explicito torna a operacao reversivel.
            $sqlSave=New-Object System.Text.StringBuilder
            [void]$sqlSave.AppendLine('BEGIN IMMEDIATE;')
            if($Id -gt 0){
                [void]$sqlSave.AppendLine(("DELETE FROM escala_dias WHERE ocorrencia_id={0};" -f $Id))
                [void]$sqlSave.AppendLine(("UPDATE ocorrencias SET setor_id={0},servidor_id={1},tipo_id={2},data_inicial={3},data_final={4},detalhamento={5},documento={6},texto_escala={7} WHERE id={8};" -f $setId,$svId,$typeId,(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fim.ToString('yyyy-MM-dd'))),(Sql-Q ($tbDet.Text.Trim())),(Sql-Q ($tbDoc.Text.Trim())),(Sql-Q $txt),$Id))

                if($oldLinkId -gt 0){
                    if($chkDefinitiva.Checked){
                        # Primeiro inativa a nova linha. Se for o mesmo servidor em outra
                        # escala do mes, isso evita violar temporariamente o gatilho de
                        # unicidade ao reativar a linha de origem antiga.
                        # V1.0.14.37 - ordem: (1) inativa a nova linha, (2) aponta a vaga para ela e SO ENTAO
                        # (3) reativa a linha antiga; o gatilho de reativacao exige que a vaga ja nao aponte para ela.
                        [void]$sqlSave.AppendLine(("UPDATE escala_servidores SET ativo=0 WHERE id={0};" -f $esIdServidor))
                        [void]$sqlSave.AppendLine(("UPDATE escala_vagas SET escala_id={0},horario_id={1},descricao={2},funcao={3},data_inicial={4},data_final={5},escala_servidor_id_origem={6},ativo=1 WHERE id={7} AND ocorrencia_id={8};" -f $escId,$hidVaga,(Sql-Q $descVaga),(Sql-Q $funcaoVaga),(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fimVaga.ToString('yyyy-MM-dd'))),$esIdServidor,$oldLinkId,$Id))
                        if($oldOriginEsId -gt 0 -and $oldOriginEsId -ne $esIdServidor){[void]$sqlSave.AppendLine(("UPDATE escala_servidores SET ativo=1 WHERE id={0};" -f $oldOriginEsId))}
                    }else{
                        [void]$sqlSave.AppendLine(("DELETE FROM escala_vagas WHERE id={0} AND ocorrencia_id={1};" -f $oldLinkId,$Id))
                        if($oldOriginEsId -gt 0){[void]$sqlSave.AppendLine(("UPDATE escala_servidores SET ativo=1 WHERE id={0};" -f $oldOriginEsId))}
                    }
                }elseif($chkDefinitiva.Checked){
                    [void]$sqlSave.AppendLine(("INSERT INTO escala_vagas(escala_id,horario_id,descricao,funcao,data_inicial,data_final,ordem,ocorrencia_id,escala_servidor_id_origem) VALUES ({0},{1},{2},{3},{4},{5},(SELECT COALESCE(MAX(ordem),0)+1 FROM escala_vagas WHERE escala_id={0} AND horario_id={1}),{6},{7});" -f $escId,$hidVaga,(Sql-Q $descVaga),(Sql-Q $funcaoVaga),(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fimVaga.ToString('yyyy-MM-dd'))),$Id,$esIdServidor))
                    [void]$sqlSave.AppendLine(("UPDATE escala_servidores SET ativo=0 WHERE id={0};" -f $esIdServidor))
                }
            } else {
                [void]$sqlSave.AppendLine(("INSERT INTO ocorrencias(setor_id,servidor_id,tipo_id,data_inicial,data_final,detalhamento,documento,situacao,origem,texto_escala) VALUES ({0},{1},{2},{3},{4},{5},{6},'ATIVA','SISTEMA',{7});" -f $setId,$svId,$typeId,(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fim.ToString('yyyy-MM-dd'))),(Sql-Q ($tbDet.Text.Trim())),(Sql-Q ($tbDoc.Text.Trim())),(Sql-Q $txt)))
                if($chkDefinitiva.Checked){
                    [void]$sqlSave.AppendLine(("INSERT INTO escala_vagas(escala_id,horario_id,descricao,funcao,data_inicial,data_final,ordem,ocorrencia_id,escala_servidor_id_origem) VALUES ({0},{1},{2},{3},{4},{5},(SELECT COALESCE(MAX(ordem),0)+1 FROM escala_vagas WHERE escala_id={0} AND horario_id={1}),last_insert_rowid(),{6});" -f $escId,$hidVaga,(Sql-Q $descVaga),(Sql-Q $funcaoVaga),(Sql-Q ($ini.ToString('yyyy-MM-dd'))),(Sql-Q ($fimVaga.ToString('yyyy-MM-dd'))),$esIdServidor))
                    [void]$sqlSave.AppendLine(("UPDATE escala_servidores SET ativo=0 WHERE id={0};" -f $esIdServidor))
                }
            }
            [void]$sqlSave.AppendLine('COMMIT;')
            Db-Exec $sqlSave.ToString()
            $f.DialogResult='OK';$f.Close()
        }catch{Write-Log ('Falha ao salvar ocorrencia: ' + $_.Exception.Message);Show-Error $_.Exception.Message}
    })
    $f.Controls.Add($ok);$f.Controls.Add($cancel)
    $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){Load-OcorrenciaServidores;Load-Ocorrencias;Load-Escala}
}

function Delete-Ocorrencia {
    $id=Get-GridId $script:gridOcorrencias;if($id -le 0){Show-Info 'Selecione uma ocorrencia.';return}
    try{
        $link=Db-Query "SELECT id,COALESCE(escala_servidor_id_origem,0) AS es_origem FROM escala_vagas WHERE ocorrencia_id=$id AND ativo=1 LIMIT 1;"
        $definitiva=($link.Rows.Count -gt 0)
        $msg=$(if($definitiva){'Excluir esta ocorrencia DEFINITIVA? A Escala Vaga vinculada sera removida e o servidor sera reativado na linha original da escala. Se ele ja estiver lotado em outra escala do mesmo mes, a operacao sera bloqueada para preservar a integridade.'}else{'Excluir esta ocorrencia? Os dias gerados por ela serao removidos da escala automaticamente.'})
        if(-not(Confirm-Action $msg)){return}
        $sb=New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('BEGIN IMMEDIATE;')
        [void]$sb.AppendLine(("DELETE FROM escala_dias WHERE ocorrencia_id={0};" -f $id))
        if($definitiva){
            $esOrig=[int]$link.Rows[0]['es_origem']
            [void]$sb.AppendLine(("DELETE FROM escala_vagas WHERE ocorrencia_id={0};" -f $id))
            if($esOrig -gt 0){[void]$sb.AppendLine(("UPDATE escala_servidores SET ativo=1 WHERE id={0};" -f $esOrig))}
        }
        [void]$sb.AppendLine(("DELETE FROM ocorrencias WHERE id={0};" -f $id))
        [void]$sb.AppendLine('COMMIT;')
        Db-Exec $sb.ToString()
        Load-Ocorrencias;Load-Escala
    }catch{Write-Log ('Falha ao excluir ocorrencia: ' + $_.Exception.Message);Show-Error $_.Exception.Message}
}


function Get-DataPascoa {
    # Algoritmo de Gauss (calendario gregoriano) para achar a data da Pascoa,
    # base para os feriados moveis (Carnaval, Sexta-feira Santa, Corpus Christi).
    param([int]$Ano)
    $a=$Ano % 19
    $b=[math]::Floor($Ano/100)
    $c=$Ano % 100
    $d=[math]::Floor($b/4)
    $e=$b % 4
    $g=[math]::Floor(($b+8)/25)
    $h2=[math]::Floor(($b-$g+1)/3)
    $h=(19*$a+$b-$d-$h2+15) % 30
    $i=[math]::Floor($c/4)
    $k=$c % 4
    $l=(32+2*$e+2*$i-$h-$k) % 7
    $m=[math]::Floor(($a+11*$h+22*$l)/451)
    $mesNum=[int][math]::Floor(($h+$l-7*$m+114)/31)
    $diaNum=[int]((($h+$l-7*$m+114) % 31)+1)
    return Get-Date -Year $Ano -Month $mesNum -Day $diaNum
}

function Get-NomeFeriadoSugerido {
    # Sugere o nome do feriado nacional para a data escolhida (fixos + moveis
    # baseados na Pascoa), para preencher a Descricao sozinho ao trocar a Data.
    param([datetime]$Data)
    $md=$Data.ToString('MM-dd')
    $fixos=@{
        '01-01'='Confraternizacao Universal'
        '04-21'='Tiradentes'
        '05-01'='Dia do Trabalho'
        '09-07'='Independencia do Brasil'
        '10-12'='Nossa Senhora Aparecida'
        '11-02'='Finados'
        '11-15'='Proclamacao da Republica'
        '11-20'='Consciencia Negra'
        '12-25'='Natal'
    }
    if($fixos.ContainsKey($md)){return $fixos[$md]}
    $pascoa=Get-DataPascoa $Data.Year
    if($Data.Date -eq $pascoa.Date){return 'Pascoa'}
    if($Data.Date -eq $pascoa.AddDays(-47).Date){return 'Carnaval'}
    if($Data.Date -eq $pascoa.AddDays(-46).Date){return 'Quarta-feira de Cinzas'}
    if($Data.Date -eq $pascoa.AddDays(-2).Date){return 'Sexta-feira Santa'}
    if($Data.Date -eq $pascoa.AddDays(60).Date){return 'Corpus Christi'}
    return ''
}

function Get-NomeMes {
    param([int]$Mes)
    $nomes=@('Janeiro','Fevereiro','Marco','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro')
    if($Mes -lt 1 -or $Mes -gt 12){return [string]$Mes}
    return $nomes[$Mes-1]
}

function Html-E {
    param([object]$Value)
    if ($null -eq $Value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-SafeHexColor {
    param([string]$Value, [string]$Default)
    if ($Value -match '^#[0-9A-Fa-f]{6}$') { return $Value }
    return $Default
}

function Get-ScalePreviewConfig {
    # Le a configuracao de impressao uma vez; usado pela pre-visualizacao unica e pela combinada.
    $cfg = @{}
    $cfg.instLinha1=Get-ConfigValueAllowEmpty 'impressao_inst_linha1' ''
    $cfg.instLinha2=Get-ConfigValueAllowEmpty 'impressao_inst_linha2' ''
    $cfg.instLinha3=Get-ConfigValueAllowEmpty 'impressao_inst_linha3' ''
    $cfg.instLinha4=Get-ConfigValueAllowEmpty 'impressao_inst_linha4' ''

    $cfg.tituloAssinaturas=Get-ConfigValueAllowEmpty 'impressao_titulo_assinaturas' ''
    $cfg.tituloLegenda=Get-ConfigValueAllowEmpty 'impressao_titulo_legenda' 'LEGENDA DAS SIGLAS'
    $cfg.tituloLegendaVisivel=Get-ConfigBool 'impressao_titulo_legenda_visivel' $true
    # Defesa adicional: se a propria caixa de Configuracoes estiver vazia nesta
    # sessao, nunca renderizar o titulo, mesmo que exista cache/default antigo.
    if($null -ne $script:txtTituloLegenda -and [string]::IsNullOrWhiteSpace([string]$script:txtTituloLegenda.Text)){
        $cfg.tituloLegendaVisivel=$false
    }
    if(-not $cfg.tituloLegendaVisivel){$cfg.tituloLegenda=''}
    $cfg.textoChefiaPadrao=Get-ConfigValue 'impressao_texto_chefia_padrao' 'CHEFIA DO SETOR'
    $cfg.margemPaginaMm=Get-ConfigDecimal 'impressao_margem_pagina_mm' 7.0 7.0 20.0
    $cfg.paddingFolhaMm=Get-ConfigDecimal 'impressao_padding_folha_mm' 5.0 0.0 15.0
    $cfg.espacoEntreSetoresMm=Get-ConfigDecimal 'impressao_espaco_entre_setores_mm' 6.0 0.0 30.0
    $cfg.assinaturaLinhasSeparadas=Get-ConfigBool 'impressao_assinatura_linhas_separadas' $true
    $cfg.showLegend=Get-ConfigBool 'impressao_legenda' $true
    $cfg.legendaOrdenarPor=Get-ConfigValue 'impressao_legenda_ordenar_por' 'DESCRICAO'
    $cfg.legendPairs=Get-ConfigInt 'impressao_legenda_pares' 2 1 3
    $cfg.legendPosition=(Get-ConfigValue 'impressao_legenda_posicao' 'DIREITA').ToUpperInvariant()
    if($cfg.legendPosition -notin @('DIREITA','ESQUERDA')){$cfg.legendPosition='DIREITA'}
    $cfg.bottomFlexDirection=$(if($cfg.legendPosition -eq 'ESQUERDA'){'row-reverse'}else{'row'})
    $cfg.legendTextAlign=$(if($cfg.legendPosition -eq 'ESQUERDA'){'left'}else{'right'})
    $cfg.legendMarginLeft=$(if($cfg.legendPosition -eq 'ESQUERDA'){'0'}else{'auto'})
    $cfg.legendMarginRight=$(if($cfg.legendPosition -eq 'ESQUERDA'){'auto'}else{'0'})
    $cfg.legendAll=Get-ConfigBool 'legenda_todas_siglas' $true
    $cfg.showSignatures=Get-ConfigBool 'impressao_assinaturas' $true
    $cfg.printFds=Get-ConfigBool 'impressao_destacar_fds' $true
    $cfg.printFer=Get-ConfigBool 'impressao_destacar_feriados' $true
    $cfg.maskDN=Get-ConfigBool 'mascara_dn_paridade' $true
    $cfg.maskMV=Get-ConfigBool 'mascara_mv_fds_paridade' $true
    $cfg.autoPtMV=Get-ConfigBool 'mv_pt_automatico' $true
    $cfg.qtdMode=Get-ConfigValue 'qtd_modo' 'ENF_TEAE'
    $cfg.qtdReset=Get-ConfigBool 'qtd_reiniciar_bloco' $true
    $cfg.qtdDestaqueAtivo=Get-ConfigBool 'impressao_qtd_destaque_ativo' $true
    $qtdDestaqueTxt=Get-ConfigValue 'impressao_qtd_destaque_grupos' 'ENF'
    $cfg.qtdDestaqueGrupos=@(
        ([string]$qtdDestaqueTxt -split '[,;]') |
        ForEach-Object {$_.Trim().ToUpperInvariant()} |
        Where-Object {$_ -in @('ENF','TEAE','OUTROS','SEQ')} |
        Select-Object -Unique
    )
    $cfg.qtdDestaqueVaga=Get-ConfigBool 'impressao_qtd_destaque_vaga' $true
    $cfg.qtdDestaqueFundo=Get-SafeHexColor (Get-ConfigValue 'impressao_qtd_destaque_fundo' '#D9D9D9') '#D9D9D9'
    $cfg.qtdDestaqueFonte=Get-SafeHexColor (Get-ConfigValue 'impressao_qtd_destaque_fonte' '#000000') '#000000'
    $cfg.FaixaMap=Get-FaixaTiposAtivos
    $cfg.legendFontPt=Get-ConfigInt 'impressao_legenda_fonte_pt' 6 5 10
    $cfg.legendSiglaMm=Get-ConfigInt 'impressao_legenda_sigla_mm' 7 5 15
    $cfg.signatureFontPt=Get-ConfigInt 'impressao_assinatura_fonte_pt' 7 5 12
    $assFonteFamiliaCfg=Get-ConfigValue 'impressao_assinatura_fonte_familia' 'Arial'
    $cfg.assinaturaFonteFamiliaCss=$(switch($assFonteFamiliaCfg){'Arial'{'Arial, Helvetica, sans-serif'};'Verdana'{'Verdana, Geneva, sans-serif'};'Tahoma'{'Tahoma, Geneva, sans-serif'};'Segoe UI'{'"Segoe UI", Arial, sans-serif'};'Times New Roman'{'"Times New Roman", Times, serif'};'Consolas'{'Consolas, "Courier New", monospace'};'Calibri'{'Calibri, Arial, sans-serif'};default{'Arial, Helvetica, sans-serif'}})
    $cfg.cabecalhoFontPt=Get-ConfigInt 'impressao_cabecalho_fonte_pt' 7 5 14
    $cabFonteFamiliaCfg=Get-ConfigValue 'impressao_cabecalho_fonte_familia' 'Arial'
    $cfg.cabecalhoFonteFamiliaCss=$(switch($cabFonteFamiliaCfg){'Arial'{'Arial, Helvetica, sans-serif'};'Verdana'{'Verdana, Geneva, sans-serif'};'Tahoma'{'Tahoma, Geneva, sans-serif'};'Segoe UI'{'"Segoe UI", Arial, sans-serif'};'Times New Roman'{'"Times New Roman", Times, serif'};'Consolas'{'Consolas, "Courier New", monospace'};'Calibri'{'Calibri, Arial, sans-serif'};default{'Arial, Helvetica, sans-serif'}})
    $fonteFamiliaCfg=Get-ConfigValue 'impressao_fonte_familia' 'Arial'
    $cfg.fonteFamiliaCss=$(switch($fonteFamiliaCfg){'Arial'{'Arial, Helvetica, sans-serif'};'Verdana'{'Verdana, Geneva, sans-serif'};'Tahoma'{'Tahoma, Geneva, sans-serif'};'Segoe UI'{'"Segoe UI", Arial, sans-serif'};'Times New Roman'{'"Times New Roman", Times, serif'};'Consolas'{'Consolas, "Courier New", monospace'};'Calibri'{'Calibri, Arial, sans-serif'};default{'Arial, Helvetica, sans-serif'}})
    $cfg.abreviarNomesFamiliaFator=$(switch($fonteFamiliaCfg){'Arial'{1.00};'Segoe UI'{1.03};'Calibri'{0.95};'Verdana'{1.20};'Tahoma'{1.10};'Times New Roman'{0.97};'Consolas'{1.35};default{1.05}})
    $gradeFontPt=Get-ConfigDecimal 'impressao_grade_fonte_pt' 5.7 4.0 10.0
    $cfg.gradeFontPtTxt=$gradeFontPt.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture)
    $cfg.blocoFontPtTxt=($gradeFontPt+0.5).ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture)
    $cfg.abreviarNomes=Get-ConfigBool 'impressao_abreviar_nomes' $true
    $cfg.gradeFontPt=$gradeFontPt
    $cfg.abreviarNomesLimiteMm=52.0   # coluna Nomes tem 55mm; reserva ~3mm de padding/borda/folga de seguranca
    return $cfg
}

function Get-ScaleDayWidthMm {
    # Largura da coluna de cada dia calculada para SEMPRE caber na folha A4
    # paisagem, mesmo em meses de 31 dias (antes era fixo 5.5mm e estourava
    # a margem em meses de 31 dias: 118mm de colunas fixas + 31x5.5mm = 288.5mm,
    # mais que os ~279mm uteis da pagina).
    # IMPORTANTE: usa as MESMAS margens configuradas em Impressao (margemPaginaMm/
    # paddingFolhaMm) para nunca perder a sincronia com o CSS e voltar a estourar.
    param([int]$Dias,[double]$MargemPaginaMm=7.0,[double]$PaddingFolhaMm=5.0)
    if ($Dias -le 0) { return 5.5 }
    $usavelMm = 297 - (2*$MargemPaginaMm) - (2*$PaddingFolhaMm) - 2   # A4 paisagem - margens de pagina - padding do .sheet - folga
    $fixasMm = 6 + 55 + 15 + 20 + 22       # qty + name + cp + role + coren (tem que bater com o CSS .scale)
    $w = ($usavelMm - $fixasMm) / [double]$Dias
    if ($w -lt 3.2) { $w = 3.2 }
    return $w
}

function Get-ScalePreviewStyleBlock {
    param($cfg,[double]$DiaWidthMm=5.5)
    $diaWidthTxt=$DiaWidthMm.ToString('0.00',[System.Globalization.CultureInfo]::InvariantCulture)
    # V1.0.14.74 - .sheet usa a MESMA largura (area util real da folha) na tela e na impressao, para a pre-visualizacao
    # nunca mostrar mais espaco do que a folha impressa realmente tem (evita nome/coluna que cabe na tela e nao no papel).
    $sheetWidthTxt=(297.0-(2*$cfg.margemPaginaMm)).ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture)
    return @"
<style>
@page { size: A4 landscape; margin: $($cfg.margemPaginaMm.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture))mm; }
* { box-sizing: border-box; }
body { font-family: $($cfg.fonteFamiliaCss); margin: 0; color: #111; background: #e9edf1; }
.toolbar { position: sticky; top: 0; z-index: 5; display: flex; gap: 10px; align-items: center; padding: 10px 14px; background: #1b3249; color: white; }
.toolbar button { padding: 8px 14px; border: 1px solid #c8d0d8; background: white; color: #111; cursor: pointer; }
.toolbar .note { font-size: 12px; opacity: .9; }
.sheet { width: ${sheetWidthTxt}mm; max-width: ${sheetWidthTxt}mm; margin: 12px auto; background: white; padding: $($cfg.paddingFolhaMm.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture))mm; }
.setor-bloco + .setor-bloco { margin-top: $($cfg.espacoEntreSetoresMm.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture))mm; }
.letterhead { display: flex; align-items: stretch; border: 1px solid #222; margin-bottom: 4px; min-height: 16mm; }
.letterhead .lh-logo-gov { flex: 0 0 auto; width: 16mm; display: flex; align-items: center; justify-content: center; padding: 1.5mm; border-right: 1px solid #222; }
.letterhead .lh-logo-gov img { width: 100%; height: auto; display: block; }
.letterhead .lh-inst { flex: 0 0 auto; width: 62mm; display: flex; align-items: center; padding: 1.5mm 2.5mm; font-size: 6.3pt; font-weight: bold; line-height: 1.3; border-right: 1px solid #222; }
.letterhead .lh-logo-hrms { flex: 0 0 auto; width: 34mm; display: flex; align-items: center; justify-content: center; padding: 1.5mm 3mm; border-right: 1px solid #222; }
.letterhead .lh-logo-hrms img { max-width: 100%; max-height: 11mm; display: block; }
.letterhead .lh-info { flex: 1 1 auto; display: grid; grid-template-columns: 1fr 1fr; }
.letterhead .lh-info div { padding: 1.5mm 2.5mm; font-size: $($cfg.cabecalhoFontPt)pt; font-family: $($cfg.cabecalhoFonteFamiliaCss); border-bottom: 1px solid #222; }
.letterhead .lh-info div:nth-child(odd) { border-right: 1px solid #222; }
.letterhead .lh-info div:nth-last-child(-n+2) { border-bottom: none; }
.letterhead .lh-info .lh-field > b, .letterhead .lh-info .lh-field > .lh-value { display: block; }
.letterhead .lh-info .lh-field > .lh-value { white-space: nowrap; }
.scale { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: $($cfg.gradeFontPtTxt)pt; }
.scale th, .scale td { border: 1px solid #222; padding: 1px; text-align: center; vertical-align: middle; line-height: 1.05; }
.scale thead th { background: #f2f2f2; color: #111; font-weight: bold; }
.scale thead th.weekend { background: #d9d9d9; }
.scale td.weekend { background: #f1f1f1; }
.scale td.parity-mask { background: #dddddd; }
.scale th.holiday, .scale td.holiday { background: #e3e3e3 !important; }
.scale .qty { width: 6mm; }
.scale td.qtd-destaque {
    background-color: $($cfg.qtdDestaqueFundo) !important;
    color: $($cfg.qtdDestaqueFonte) !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
}
.scale .name { width: 55mm; text-align: left; padding-left: 2px; white-space: nowrap; overflow: hidden; }
.scale .cp { width: 15mm; }
.scale .role { width: 20mm; }
.scale .coren { width: 22mm; }
.scale .day { width: ${diaWidthTxt}mm; min-width: ${diaWidthTxt}mm; max-width: ${diaWidthTxt}mm; font-weight: bold; overflow: hidden; white-space: nowrap; }
.scale thead .day { padding-top: 1px; padding-bottom: 1px; line-height: 1.0; }
.scale thead .day-num, .scale thead .day-dow { display: block; white-space: nowrap; overflow: hidden; text-align: center; }
.scale thead .day-num { font-size: 1em; }
.scale thead .day-dow { font-size: 0.82em; margin-top: 1px; }
.scale .block td { background: #d9d9d9; font-weight: bold; text-align: center; font-size: $($cfg.blocoFontPtTxt)pt; padding: 2px 3px; letter-spacing: .05px; }
.scale .server-row td { height: 5mm; }
.scale .range { background:#f4f4f4; font-weight:bold; text-align:center; letter-spacing:.2px; }
.scale .vaga-name { font-weight:bold; text-align:left; padding-left:2px; }
.bottom-area { display: flex; flex-direction: $($cfg.bottomFlexDirection); gap: 8mm; margin-top: 6mm; align-items: flex-start; }
.left-col { flex: 0 0 46%; min-width: 46%; padding-left: 4mm; }
.right-col { flex: 1 1 auto; }
.section-title { margin: 0 0 4mm 0; font-size: 7pt; font-weight: bold; }
.legend-title { margin-top: 0; margin-bottom: 2mm; font-size: 7pt; font-weight: bold; text-align: $($cfg.legendTextAlign); }
.legend { width: auto; margin-left: $($cfg.legendMarginLeft); margin-right: $($cfg.legendMarginRight); border-collapse: collapse; margin-top: 2px; font-size: $($cfg.legendFontPt)pt; table-layout: auto; }
.legend th, .legend td { border: 1px solid #444; padding: 1.5px 3px; }
.legend th { background: #eeeeee; text-align: center; font-weight: bold; }
.legend .sg { width: $($cfg.legendSiglaMm)mm; min-width: $($cfg.legendSiglaMm)mm; white-space: nowrap; text-align: center; font-weight: bold; }
.legend .meaning { width: auto; text-align: left; white-space: normal; padding-right: 20mm; }
.signatures { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); column-gap: 8mm; row-gap: 8mm; margin-top: 0; align-items: end; }
.signature { width: 100%; text-align: center; font-size: $($cfg.signatureFontPt)pt; font-family: $($cfg.assinaturaFonteFamiliaCss); break-inside: avoid; }
.signature .line { border-top: 1px solid #111; padding-top: 2px; min-height: 1px; }
.footer { margin-top: 4px; font-size: 5.5pt; text-align: right; color: #555; }
.empty { text-align: center; padding: 12px; border: 1px solid #222; font-size: 8pt; }
@media print {
    /*
       V1.0.14.47
       A margem de @page e aplicada a CADA folha fisica pelo mecanismo de
       impressao. Assim o topo da segunda pagina recebe a mesma area segura
       da primeira pagina, independentemente dos cabecalhos/rodapes do Chrome.
    */
    html, body {
        margin: 0 !important;
        padding: 0 !important;
        background: white !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
    .toolbar { display: none !important; }

    /* Remove apenas o espacamento de tela. Mantem o padding interno configurado. */
    .sheet {
        width: 100% !important;
        max-width: none !important;
        margin: 0 !important;
        padding: $($cfg.paddingFolhaMm.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture))mm !important;
        box-shadow: none !important;
    }

    .letterhead {
        break-inside: avoid !important;
        page-break-inside: avoid !important;
    }

    /* V1.0.14.21.9 - No combinado, o navegador deve paginar naturalmente.
       Nao forcar um novo Setor/Sub_Setor para a folha seguinte. */
    .setor-bloco {
        break-before: auto !important;
        page-break-before: auto !important;
        break-after: auto !important;
        page-break-after: auto !important;
        break-inside: auto !important;
        page-break-inside: auto !important;
    }
    .setor-bloco + .setor-bloco {
        break-before: auto !important;
        page-break-before: auto !important;
    }

    /* Se a tabela atravessar folhas, o cabecalho reaparece no topo da nova pagina. */
    .scale thead { display: table-header-group; }
    .scale tfoot { display: table-footer-group; }
    .scale tr {
        break-inside: avoid !important;
        page-break-inside: avoid !important;
    }
    .block {
        break-after: avoid !important;
        page-break-after: avoid !important;
        break-inside: avoid !important;
        page-break-inside: avoid !important;
    }
    .bottom-area {
        break-inside: avoid !important;
        page-break-inside: avoid !important;
    }
}
</style>
"@
}

function Trocar-LogoImpressao {
    # Deixa escolher um arquivo de imagem pela tela para substituir o logo
    # do cabecalho impresso (Recursos\logo_governo.* ou logo_hrms.*),
    # sem precisar mexer em pasta de arquivos manualmente. Preserva a extensao
    # do arquivo escolhido (PNG ou JPG) em vez de forcar sempre .png.
    param([string]$NomeBase)
    try {
        $ofd=New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter='Imagens (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg'
        $ofd.Title='Escolher novo logo'
        $dlgResult=$ofd.ShowDialog($script:MainForm)
        $arquivoSelecionado=$ofd.FileName
        $ofd.Dispose()
        if($dlgResult -ne 'OK'){return}
        $pastaRecursos=Join-Path $script:Root 'Recursos'
        if(-not (Test-Path $pastaRecursos)){New-Item -ItemType Directory -Path $pastaRecursos -Force | Out-Null}
        # Remove versoes antigas com outra extensao para nao ficar arquivo orfao.
        foreach($ext in @('png','jpg','jpeg')){
            $antigo=Join-Path $pastaRecursos ('{0}.{1}' -f $NomeBase,$ext)
            if(Test-Path $antigo){Remove-Item $antigo -Force -ErrorAction SilentlyContinue}
        }
        $extNova=[System.IO.Path]::GetExtension($arquivoSelecionado).TrimStart('.').ToLowerInvariant()
        if($extNova -eq 'jpeg'){$extNova='jpg'}
        $destino=Join-Path $pastaRecursos ('{0}.{1}' -f $NomeBase,$extNova)
        Copy-Item -LiteralPath $arquivoSelecionado -Destination $destino -Force
        $script:PreviewLogoCache=$null
        Show-Info 'Logo atualizado. Ele ja sera usado na proxima pre-visualizacao/impressao.'
    } catch { Show-Error $_.Exception.Message }
}

function Find-ArquivoLogo {
    # Acha o arquivo do logo aceitando qualquer extensao comum (o usuario pode
    # ter trocado por um JPG). Retorna @{Path=...; Mime=...} ou $null.
    param([string]$NomeBase)
    foreach($ext in @('png','jpg','jpeg')){
        $p=Join-Path $script:Root ('Recursos\{0}.{1}' -f $NomeBase,$ext)
        if(Test-Path $p){
            $mime=$(if($ext -eq 'png'){'image/png'}else{'image/jpeg'})
            return @{Path=$p;Mime=$mime}
        }
    }
    return $null
}

function Get-ScalePreviewLogos {
    # Le e converte os logos do cabecalho (Recursos\logo_governo.* e logo_hrms.*)
    # para data-URI base64 uma unica vez, para o HTML da pre-visualizacao ficar
    # autonomo (funciona mesmo se o arquivo .html for movido/aberto em outro lugar).
    if ($null -eq $script:PreviewLogoCache) {
        $script:PreviewLogoCache = @{ Governo=''; Hrms='' }
        try {
            $gov=Find-ArquivoLogo 'logo_governo'
            $hrms=Find-ArquivoLogo 'logo_hrms'
            if ($gov) { $script:PreviewLogoCache.Governo = "data:$($gov.Mime);base64," + [Convert]::ToBase64String([IO.File]::ReadAllBytes($gov.Path)) }
            if ($hrms) { $script:PreviewLogoCache.Hrms = "data:$($hrms.Mime);base64," + [Convert]::ToBase64String([IO.File]::ReadAllBytes($hrms.Path)) }
        } catch { Write-Log ('Falha ao carregar logos do cabecalho: ' + $_.Exception.Message) }
    }
    return $script:PreviewLogoCache
}

function Build-EscalaSheetHtml {
    # Monta o fragmento HTML (cabecalho + tabela da grade) de UMA escala/setor.
    # Nao inclui assinaturas/legenda: isso fica a cargo de Build-EscalaRodapeHtml,
    # para permitir um rodape unico compartilhado no modo combinado (varios setores).
    param($sid,$ano,$mes,$scaleId,$cfg)

    $result = @{ Html=''; Used=@{}; SyncError=$false; SyncErrorMessage='' }
    $sidSql=Sql-Int $sid 'setor_id'
    $scaleIdSql=Sql-Int $scaleId 'escala_id'
    $syncOccOk=[bool](Ensure-OccurrenceSyncForScale $scaleId)
    $syncCalOk=[bool](Ensure-Calendar08hSyncForScale $scaleId)
    if((-not $syncOccOk) -or (-not $syncCalOk)){
        $result.SyncError=$true
        $result.SyncErrorMessage=('Nao foi possivel atualizar todos os dados automaticos antes da pre-visualizacao (Ocorrencias={0}; Calendario 08h={1}). A pre-visualizacao foi bloqueada para evitar imprimir uma escala desatualizada. Consulte Logs\Sistema_Escala.log e tente novamente.' -f $syncOccOk,$syncCalOk)
        Write-Log ("PREVIEW BLOQUEADA: escala={0}; ocorrencias={1}; calendario08h={2}" -f $scaleId,$syncOccOk,$syncCalOk)
        return $result
    }

    $setT = Db-Query "SELECT se.nome AS escala_nome,se.total_leitos,se.chefia,se.coren_chefia,COALESCE(sp.nome,se.nome) AS setor_principal,COALESCE(ss.nome,'') AS sub_setor FROM setores se LEFT JOIN setores sp ON sp.id=se.setor_pai_id LEFT JOIN sub_setores ss ON ss.id=se.sub_setor_origem_id WHERE se.id=$sidSql;"
    if ($setT.Rows.Count -eq 0) { return $result }
    $set = $setT.Rows[0]
        $setorNome = [string]$set['escala_nome']
        $setorPrincipal = [string]$set['setor_principal']
        $subSetorNome = [string]$set['sub_setor']
        # V1.0.14.32 - no cabecalho impresso, quando a unidade e um Sub_Setor,
        # mostra somente o nome do Sub_Setor. O nome completo continua preservado
        # internamente para titulo do HTML, arquivo, selecao e demais regras.
        $setorCabecalho = $setorNome
        if(-not [string]::IsNullOrWhiteSpace($subSetorNome)){$setorCabecalho=$subSetorNome.Trim()}
        $leitos = [string]$set['total_leitos']
        $chefia = [string]$set['chefia']
        $corenChefia = [string]$set['coren_chefia']
        $printFds=$cfg.printFds
        $printFer=$cfg.printFer
        $maskDN=$cfg.maskDN
        $maskMV=$cfg.maskMV
        $autoPtMV=$cfg.autoPtMV
        $qtdReset=$cfg.qtdReset
        $faixaMap=$cfg.FaixaMap
        $gradeFontPtTxt=$cfg.gradeFontPtTxt
        $blocoFontPtTxt=$cfg.blocoFontPtTxt
        $holidayMap=@{};$ht=Db-Query ("SELECT data,descricao FROM feriados WHERE data LIKE {0};" -f (Sql-Q ('{0}-{1:00}-%' -f $ano,$mes)));foreach($hr in $ht.Rows){$holidayMap[[string]$hr['data']]=[string]$hr['descricao']}

        # A impressao oficial trabalha por BLOCOS DE HORARIO.
        # O horario nao e coluna do servidor: ele vira cabecalho de grupo.
        $syncBlocosOk=[bool](Sync-ScaleBlockOrder $scaleId)
        if(-not $syncBlocosOk){
            $result.SyncError=$true
            $result.SyncErrorMessage='Nao foi possivel sincronizar a ordem dos blocos antes da pre-visualizacao. A pre-visualizacao foi bloqueada para evitar imprimir uma escala com ordem inconsistente. Consulte Logs\Sistema_Escala.log.'
            Write-Log ("PREVIEW BLOQUEADA: falha na ordem dos blocos, escala={0}" -f $scaleId)
            return $result
        }
        $srv = Db-Query "SELECT es.id AS esid,s.cp,s.nome,s.funcao,s.tipo_vinculo,s.sub_funcao,COALESCE(s.coren,'') AS coren,COALESCE(h.descricao,'') AS horario,COALESCE(h.nome,'') AS horario_nome,COALESCE(h.periodo,'') AS horario_periodo,COALESCE(h.regra,'') AS horario_regra,COALESCE(h.id,0) AS horario_id,es.ordem,COALESCE(ebo.ordem,h.ordem,h.id,999999) AS bloco_ordem FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id LEFT JOIN horarios h ON h.id=es.horario_id LEFT JOIN escala_blocos_ordem ebo ON ebo.escala_id=es.escala_id AND ebo.horario_id=es.horario_id WHERE es.escala_id=$scaleIdSql AND es.ativo=1 ORDER BY CASE WHEN es.horario_id IS NULL THEN 999999 ELSE COALESCE(ebo.ordem,h.ordem,h.id) END,es.ordem,s.nome;"
        $vagas = Db-Query "SELECT v.id AS vagaid,v.horario_id,h.descricao AS horario,COALESCE(h.nome,'') AS horario_nome,COALESCE(h.periodo,'') AS horario_periodo,COALESCE(h.regra,'') AS horario_regra,v.descricao,v.funcao,v.data_inicial,v.data_final,v.ordem,COALESCE(ebo.ordem,h.ordem,h.id,999999) AS bloco_ordem FROM escala_vagas v JOIN horarios h ON h.id=v.horario_id LEFT JOIN escala_blocos_ordem ebo ON ebo.escala_id=v.escala_id AND ebo.horario_id=v.horario_id WHERE v.escala_id=$scaleIdSql AND v.ativo=1 ORDER BY COALESCE(ebo.ordem,h.ordem,h.id),v.ordem,v.id;"
        $dias = [datetime]::DaysInMonth($ano,$mes)
        $dow = @('DO','SE','TE','QA','QI','SX','SA')

        $map = @{}
        $used = @{}
        $dd = Db-Query "SELECT ed.escala_servidor_id,ed.data,ed.sigla,ed.texto,ed.ocorrencia_id,COALESCE(t.nome,'') AS tipo_ocorrencia FROM escala_dias ed LEFT JOIN ocorrencias o ON o.id=ed.ocorrencia_id LEFT JOIN tipos_ocorrencia t ON t.id=o.tipo_id WHERE ed.escala_servidor_id IN (SELECT id FROM escala_servidores WHERE escala_id=$scaleIdSql AND ativo=1);"
        foreach($r in $dd.Rows) {
            $dt = ConvertFrom-DbDateOnly $r['data']
            $key = ('{0}|{1}' -f [int]$r['escala_servidor_id'],$dt.Day)
            $map[$key] = @{
                Sigla = [string]$r['sigla']
                Texto = [string]$r['texto']
                OcorrenciaId = $(if($r['ocorrencia_id'] -eq [DBNull]::Value){0}else{[int]$r['ocorrencia_id']})
                TipoOcorrencia = [string]$r['tipo_ocorrencia']
            }
            if(-not [string]::IsNullOrWhiteSpace([string]$r['sigla'])) {
                $used[[string]$r['sigla']] = $true
            }
        }

        # Faixas de impressao: tipos marcados como "faixa continua" em
        # Configuracoes > Ocorrencias, cada um com seu texto e duracao minima.
        $rangeStart=@{}
        $monthFirst=Get-Date -Year $ano -Month $mes -Day 1;$monthLast=$monthFirst.AddMonths(1).AddDays(-1)
        $ocRanges=Db-Query "SELECT o.id,es.id AS esid,t.nome AS tipo,COALESCE(t.sigla,'') AS sigla,COALESCE(NULLIF(TRIM(t.faixa_texto),''),t.nome) AS faixa_texto,COALESCE(t.faixa_dias_minimo,1) AS faixa_dias_minimo,COALESCE(NULLIF(TRIM(t.faixa_cor_fundo),''),'#EEEEEE') AS faixa_cor_fundo,COALESCE(NULLIF(TRIM(t.faixa_cor_fonte),''),'#000000') AS faixa_cor_fonte,o.data_inicial,o.data_final FROM ocorrencias o JOIN tipos_ocorrencia t ON t.id=o.tipo_id JOIN escala_servidores es ON es.servidor_id=o.servidor_id AND es.escala_id=$scaleIdSql AND es.ativo=1 WHERE o.situacao='ATIVA' AND t.ativo=1 AND t.faixa_ativa=1 AND o.data_final >= $(Sql-Q ($monthFirst.ToString('yyyy-MM-dd'))) AND o.data_inicial <= $(Sql-Q ($monthLast.ToString('yyyy-MM-dd')));"
        foreach($o in $ocRanges.Rows){
            try{$ini=ConvertFrom-DbDateOnly $o['data_inicial'];$fim=ConvertFrom-DbDateOnly $o['data_final']}catch{Write-Log ('Periodo invalido ignorado na previa, ocorrencia='+[string]$o['id']+': '+$_.Exception.Message);continue};$dur=($fim-$ini).Days+1
            $diasMin=[int]$o['faixa_dias_minimo']
            if($dur -ge $diasMin){if($ini -lt $monthFirst){$ini=$monthFirst};if($fim -gt $monthLast){$fim=$monthLast};$key=('{0}|{1}' -f [int]$o['esid'],$ini.Day);$rangeStart[$key]=@{Fim=$fim.Day;Texto=[string]$o['faixa_texto'];Id=[int]$o['id'];Fundo=Get-SafeHexColor ([string]$o['faixa_cor_fundo']) '#EEEEEE';Fonte=Get-SafeHexColor ([string]$o['faixa_cor_fonte']) '#000000'}}
        }

        # Complementa as faixas usando o que efetivamente esta gravado nas celulas.
        # Assim uma sigla de faixa inserida manualmente tambem vira faixa e nao aparece repetida.
        foreach($sr in $srv.Rows){
            $esid=[int]$sr['esid'];$d=1
            while($d -le $dias){
                $k=('{0}|{1}' -f $esid,$d)
                $sg=''
                if($map.ContainsKey($k)){$sg=([string]$map[$k].Sigla).Trim().ToUpperInvariant()}
                if($faixaMap.ContainsKey($sg)){
                    $inicio=$d;$fim=$d
                    while(($fim+1) -le $dias){
                        $nk=('{0}|{1}' -f $esid,($fim+1));$nsg=''
                        if($map.ContainsKey($nk)){$nsg=([string]$map[$nk].Sigla).Trim().ToUpperInvariant()}
                        if($nsg -ne $sg){break};$fim++
                    }
                    $dur=$fim-$inicio+1
                    $rk=('{0}|{1}' -f $esid,$inicio)
                    # Uma faixa derivada das celulas e apenas fallback.
                    # Nunca sobrescreve a faixa oficial obtida da tabela de ocorrencias.
                    if(-not $rangeStart.ContainsKey($rk)){
                        $fi=$faixaMap[$sg]
                        if($dur -ge $fi.Dias){$rangeStart[$rk]=@{Fim=$fim;Texto=$fi.Texto;Id=0;Fundo=$fi.Fundo;Fonte=$fi.Fonte}}
                    }
                    $d=$fim+1;continue
                }
                $d++
            }
        }

        # Mantem a ordem em que os blocos aparecem na consulta e guarda a regra visual do horario.
        $groups = [ordered]@{}
        $horMetaByKey=@{}
        foreach($r in $srv.Rows) {
            $hk = [string]$r['horario']
            if([string]::IsNullOrWhiteSpace($hk)) { $hk = 'SEM HORARIO DEFINIDO' }
            if(-not $groups.Contains($hk)) {
                $groups[$hk] = New-Object System.Collections.ArrayList
                $horMetaByKey[$hk]=Get-HorarioVisualMeta ([string]$r['horario_periodo']) ([string]$r['horario_nome']) ([string]$r['horario']) ([string]$r['horario_regra'])
            }
            [void]$groups[$hk].Add($r)
        }

        $vagaGroups=@{}
        foreach($v in $vagas.Rows){$hk=[string]$v['horario'];if(-not $groups.Contains($hk)){$groups[$hk]=New-Object System.Collections.ArrayList};if(-not $horMetaByKey.ContainsKey($hk)){$horMetaByKey[$hk]=Get-HorarioVisualMeta ([string]$v['horario_periodo']) ([string]$v['horario_nome']) ([string]$v['horario']) ([string]$v['horario_regra'])};if(-not $vagaGroups.ContainsKey($hk)){$vagaGroups[$hk]=New-Object System.Collections.ArrayList};[void]$vagaGroups[$hk].Add($v)}

        # Reordena os grupos pela ordem especifica desta escala mensal.
        # Isso garante que a pre-visualizacao/impressao siga SUBIR/DESCER BLOCO da tela.
        $groupOrder=@{}
        foreach($r in $srv.Rows){$hk=[string]$r['horario'];if([string]::IsNullOrWhiteSpace($hk)){$hk='SEM HORARIO DEFINIDO'};if(-not $groupOrder.ContainsKey($hk)){$groupOrder[$hk]=[int]$r['bloco_ordem']}}
        foreach($v in $vagas.Rows){$hk=[string]$v['horario'];if(-not $groupOrder.ContainsKey($hk)){$groupOrder[$hk]=[int]$v['bloco_ordem']}}
        $groupsOrdered=[ordered]@{}
        $orderedKeys=@($groups.Keys | Sort-Object @{Expression={if($groupOrder.ContainsKey($_)){$groupOrder[$_]}else{999999}}},@{Expression={$_}})
        foreach($hk in $orderedKeys){$groupsOrdered[$hk]=$groups[$hk]}
        $groups=$groupsOrdered

        # V1.0.14.21.2 - Titulo/nome do responsavel no cabecalho pode vir da
        # propria assinatura. Prioridade: assinatura do setor atual, setor pai e GERAL.
        # Se nenhum titulo opcional foi informado, preserva GERENTE TECNICA + chefia
        # do cadastro do setor, garantindo compatibilidade com os dados existentes.
        $cabecalhoTituloResponsavel='GERENTE TECNICA'
        $cabecalhoNomeResponsavel=$chefia
        try {
            $sidPaiCab = Db-Scalar "SELECT setor_pai_id FROM setores WHERE id=$sid;"
            $idsCab=@($sid)
            if($sidPaiCab -ne $null -and $sidPaiCab -ne [System.DBNull]::Value -and [string]$sidPaiCab -ne '' -and [int]$sidPaiCab -gt 0){$idsCab += [int]$sidPaiCab}
            $idsCabTxt=($idsCab -join ',')
            $assCab=Db-Query "SELECT nome,cabecalho_titulo,setor_id,ordem FROM assinaturas WHERE ativo=1 AND NULLIF(TRIM(COALESCE(cabecalho_titulo,'')),'') IS NOT NULL AND (setor_id IN ($idsCabTxt) OR setor_id IS NULL) ORDER BY CASE WHEN setor_id=$sid THEN 0 WHEN setor_id IN ($idsCabTxt) THEN 1 WHEN setor_id IS NULL THEN 2 ELSE 3 END,ordem,nome LIMIT 1;"
            if($assCab.Rows.Count -gt 0){
                $cabecalhoTituloResponsavel=[string]$assCab.Rows[0]['cabecalho_titulo']
                $cabecalhoNomeResponsavel=[string]$assCab.Rows[0]['nome']
            }
        } catch { Write-Log ('Falha ao obter titulo configuravel do cabecalho: ' + $_.Exception.Message) }

        $sb = New-Object System.Text.StringBuilder

        $logos = Get-ScalePreviewLogos
        [void]$sb.AppendLine('<div class="setor-bloco">')
        [void]$sb.AppendLine('<div class="letterhead">')
        [void]$sb.AppendLine(('<div class="lh-logo-gov">{0}</div>' -f $(if($logos.Governo){"<img src=`"$($logos.Governo)`" alt=`"Governo\`">"}else{''})))
        $instHtml=@(
            [string]$cfg.instLinha1,
            [string]$cfg.instLinha2,
            [string]$cfg.instLinha3,
            [string]$cfg.instLinha4
        ) | Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | ForEach-Object {Html-E $_}
        $instHtml=(@($instHtml) -join '<br>')
        if(-not [string]::IsNullOrWhiteSpace($instHtml)){
            [void]$sb.AppendLine(('<div class="lh-inst">{0}</div>' -f $instHtml))
        }
        [void]$sb.AppendLine(('<div class="lh-logo-hrms">{0}</div>' -f $(if($logos.Hrms){"<img src=`"$($logos.Hrms)`" alt=`"HRMS\`">"}else{''})))
        [void]$sb.AppendLine('<div class="lh-info">')
        [void]$sb.AppendLine(('<div><b>SETOR:</b> {0}</div>' -f (Html-E $setorCabecalho)))
        [void]$sb.AppendLine(('<div><b>TOTAL DE LEITOS:</b> {0}</div>' -f (Html-E $leitos)))
        [void]$sb.AppendLine(('<div class="lh-field"><b>MES/ANO:</b><span class="lh-value">{0} / {1}</span></div>' -f (Get-NomeMes $mes),$ano))
        [void]$sb.AppendLine(('<div class="lh-field"><b>{0}:</b><span class="lh-value">{1}</span></div>' -f (Html-E $cabecalhoTituloResponsavel),(Html-E $cabecalhoNomeResponsavel)))
        [void]$sb.AppendLine('</div>')
        [void]$sb.AppendLine('</div>')

        if($srv.Rows.Count -eq 0 -and $vagas.Rows.Count -eq 0) {
            [void]$sb.AppendLine('<div class="empty">Nenhum servidor vinculado a esta escala mensal.</div>')
        } else {
            $colspan = 5 + $dias
            [void]$sb.AppendLine('<table class="scale"><thead><tr>')
            [void]$sb.AppendLine('<th class="qty">Qtd</th><th class="name">Nomes</th><th class="cp">CP</th><th class="role">Funcao</th><th class="coren">Coren</th>')
            for($d=1;$d -le $dias;$d++) {
                $dt = Get-Date -Year $ano -Month $mes -Day $d
                $isWeek = ($dt.DayOfWeek -eq 'Saturday' -or $dt.DayOfWeek -eq 'Sunday')
                $isHoliday=$holidayMap.ContainsKey($dt.ToString('yyyy-MM-dd'))
                $wc='';if($isWeek -and $printFds){$wc+=' weekend'};if($isHoliday -and $printFer){$wc+=' holiday'}
                $diaNum=('{0:00}' -f $d)
                $diaSemana=$dow[[int]$dt.DayOfWeek]
                $titleDia=$diaSemana
                if($isHoliday){$titleDia+=' - '+[string]$holidayMap[$dt.ToString('yyyy-MM-dd')]}
                [void]$sb.AppendLine(('<th class="day{0}" title="{1}"><span class="day-num">{2}</span><span class="day-dow">{3}</span></th>' -f $wc,(Html-E $titleDia),$diaNum,$diaSemana))
            }
            [void]$sb.AppendLine('</tr></thead><tbody>')

            $cnt=@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}
            foreach($hk in $groups.Keys) {
                if($qtdReset){$cnt=@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}}
                $cntVaga=@{SEQ=1;ENF=1;TEAE=1;OUTROS=1}
                $hmeta=$(if($horMetaByKey.ContainsKey($hk)){$horMetaByKey[$hk]}else{$null})
                $hkExibicao=Get-CabecalhoAjustadoParidade $hk $hmeta $ano $mes
                [void]$sb.AppendLine(('<tr class="block"><td colspan="{0}">{1}</td></tr>' -f $colspan,(Html-E $hkExibicao)))
                $ultimoServidorCargo=@{}
                $vagasRenderizadas=@{}
                foreach($sr in $groups[$hk]){
                    $ultimoServidorCargo[(Get-CargoChaveEscala ([string]$sr['funcao']))]=[int]$sr['esid']
                }
                foreach($r in $groups[$hk]) {
                    $esid = [int]$r['esid']
                    $grp=Get-QtdGrupo ([string]$r['funcao']);$qtd=$cnt[$grp];$cnt[$grp]=[int]$cnt[$grp]+1
                    [void]$sb.AppendLine('<tr class="server-row">')
                    $funcaoExibida=Get-FuncaoExibicao ([string]$r['funcao']) ([string]$r['tipo_vinculo']) ([string]$r['sub_funcao'])
                    $qtdClass='qty'
                    if(Test-QtdPrintHighlightRow ([string]$r['funcao']) $funcaoExibida $cfg){
                        $qtdClass+=' qtd-destaque'
                    }
                    [void]$sb.AppendLine(('<td class="{0}">{1}</td>' -f $qtdClass,$qtd))
                    $nomeExibido=[string]$r['nome']
                    if([bool]$cfg.abreviarNomes){$nomeExibido=Get-NomeAbreviadoImpressao $nomeExibido ([double]$cfg.gradeFontPt) ([double]$cfg.abreviarNomesFamiliaFator) ([double]$cfg.abreviarNomesLimiteMm)}
                    [void]$sb.AppendLine(('<td class="name">{0}</td>' -f (Html-E $nomeExibido)))
                    [void]$sb.AppendLine(('<td class="cp">{0}</td>' -f (Html-E $r['cp'])))
                    [void]$sb.AppendLine(('<td class="role">{0}</td>' -f (Html-E $funcaoExibida)))
                    [void]$sb.AppendLine(('<td class="coren">{0}</td>' -f (Html-E $r['coren'])))

                    $d=1
                    while($d -le $dias) {
                        $rangeKey=('{0}|{1}' -f $esid,$d)
                        if($rangeStart.ContainsKey($rangeKey)){
                            $rg=$rangeStart[$rangeKey];$span=[int]$rg.Fim-$d+1
                            [void]$sb.AppendLine(('<td class="range" colspan="{0}" style="background-color:{1};color:{2};">{3}</td>' -f $span,(Get-SafeHexColor ([string]$rg.Fundo) '#EEEEEE'),(Get-SafeHexColor ([string]$rg.Fonte) '#000000'),(Html-E $rg.Texto)))
                            $d=[int]$rg.Fim+1
                            continue
                        }
                        $dt = Get-Date -Year $ano -Month $mes -Day $d
                        $isWeek = ($dt.DayOfWeek -eq 'Saturday' -or $dt.DayOfWeek -eq 'Sunday')
                        $vis=Get-HorarioDayVisual $hmeta $dt $maskDN $maskMV $autoPtMV
                        $key = ('{0}|{1}' -f $esid,$d)
                        $display = ''
                        $tip = ''
                        $style = ''
                        if($map.ContainsKey($key)) {
                            $item = $map[$key]
                            $sg = [string]$item.Sigla
                            $tx = [string]$item.Texto
                            if(-not [string]::IsNullOrWhiteSpace($sg)) { $display = $sg } else { $display = $tx }
                            $tip = $tx
                            if(-not [string]::IsNullOrWhiteSpace($sg) -and $script:SiglaCache.ContainsKey($sg)) {
                                # IMPORTANTE: nao reutilizar $cfg aqui.
                                # $cfg e o objeto de configuracao global desta pre-visualizacao.
                                $sigCfg = $script:SiglaCache[$sg]
                                $bg = Get-SafeHexColor ([string]$sigCfg.Fundo) '#FFFFFF'
                                $fg = Get-SafeHexColor ([string]$sigCfg.Fonte) '#000000'
                                $style = (' style="background-color:{0};color:{1};"' -f $bg,$fg)
                            }
                        }
                        if([string]::IsNullOrWhiteSpace($display) -and $vis.AutoPT){
                            $display='PT';$tip='PT automatico - FDS conforme paridade do cabecalho do horario';$used['PT']=$true
                            if($script:SiglaCache.ContainsKey('PT')){$sigCfg=$script:SiglaCache['PT'];$bg=Get-SafeHexColor ([string]$sigCfg.Fundo) '#F2F2F2';$fg=Get-SafeHexColor ([string]$sigCfg.Fonte) '#000000';$style=(' style="background-color:{0};color:{1};"' -f $bg,$fg)}
                        }
                        $isHoliday=$holidayMap.ContainsKey($dt.ToString('yyyy-MM-dd'))
                        # V1.0.14.4 - Em blocos DIURNO/NOTURNO a paridade ja cobre todos os dias
                        # (nao so FDS), entao o destaque extra de FS/FF por cima da mascara so
                        # confundia a leitura. Nesses blocos, o dia so e diferenciado pela cor
                        # de paridade PAR/IMPAR do cabecalho; FS/FF ficam com a cor normal.
                        $ehBlocoDN=($null -ne $hmeta -and [bool]$hmeta.EhDN)
                        $cls='day'
                        if(-not $ehBlocoDN -and $isWeek -and $printFds){$cls+=' weekend'}
                        if($vis.Mask){$cls+=' parity-mask'}
                        if(-not $ehBlocoDN -and $isHoliday -and $printFer){$cls+=' holiday'}
                        $tt=$tip;if($isHoliday){if($tt){$tt+=' - '};$tt+=$holidayMap[$dt.ToString('yyyy-MM-dd')]}
                        [void]$sb.AppendLine(('<td class="{0}" title="{1}"{2}>{3}</td>' -f $cls,(Html-E $tt),$style,(Html-E $display)))
                        $d++
                    }
                    [void]$sb.AppendLine('</tr>')

                    $cargoAtual=Get-CargoChaveEscala ([string]$r['funcao'])
                    if($vagaGroups.ContainsKey($hk) -and $ultimoServidorCargo.ContainsKey($cargoAtual) -and [int]$ultimoServidorCargo[$cargoAtual] -eq $esid){
                        foreach($v in $vagaGroups[$hk]){
                            if((Get-CargoChaveEscala ([string]$v['funcao'])) -ne $cargoAtual){continue}
                            Add-EscalaVagaPreviewRow $sb $v $cntVaga $monthFirst $monthLast $dias $cfg
                            $vagasRenderizadas[[string]$v['vagaid']]=$true
                        }
                    }
                }
                if($vagaGroups.ContainsKey($hk)){
                    foreach($v in $vagaGroups[$hk]){
                        if($vagasRenderizadas.ContainsKey([string]$v['vagaid'])){continue}
                        Add-EscalaVagaPreviewRow $sb $v $cntVaga $monthFirst $monthLast $dias $cfg
                        $vagasRenderizadas[[string]$v['vagaid']]=$true
                    }
                }
            }
            [void]$sb.AppendLine('</tbody></table>')
        }
        [void]$sb.AppendLine('</div>')

    $result.Html = $sb.ToString()
    $result.Used = $used
    $result.SetorNome = $setorNome
    return $result
}

function Build-EscalaRodapeHtml {
    # Bloco de assinaturas + legenda de siglas, compartilhado ao final do
    # documento. No modo unico, a abrangencia parte de $sid e do seu pai.
    # No modo combinado, $assinaturaSetorIds recebe todas as unidades realmente
    # selecionadas; para cada uma delas tambem e considerado o Setor Principal.
    # Assinaturas com setor_id=NULL (GERAL) continuam aparecendo em ambos os modos.
    param($sid,$usedSiglas,$cfg,$assinaturaSetorIds=$null)
    $sb = New-Object System.Text.StringBuilder
    $showSignatures=$cfg.showSignatures
    $showLegend=$cfg.showLegend
    $legendAll=$cfg.legendAll

    $setRow = Db-Query "SELECT chefia,coren_chefia FROM setores WHERE id=$sid;"
    $chefia='';$corenChefia=''
    if($setRow.Rows.Count -gt 0){$chefia=[string]$setRow.Rows[0]['chefia'];$corenChefia=[string]$setRow.Rows[0]['coren_chefia']}

    if($showSignatures -or $showLegend){
        [void]$sb.AppendLine('<div class="bottom-area">')
    }
    if($showSignatures){
        [void]$sb.AppendLine('<div class="left-col">')
        if(-not [string]::IsNullOrWhiteSpace([string]$cfg.tituloAssinaturas)){
            [void]$sb.AppendLine(('<div class="section-title">{0}</div>' -f (Html-E $cfg.tituloAssinaturas)))
        }
        # A assinatura segue a abrangencia cadastrada. No modo unico entram a
        # unidade atual + seu pai. No combinado entram TODAS as unidades escolhidas
        # + o pai de cada uma. Isso evita perder, no rodape, a assinatura de uma
        # Gerencia/Sub_Setor que foi corretamente cadastrada apenas naquela unidade.
        $idsAbrangencia = New-Object System.Collections.ArrayList
        $basesAbrangencia = @()
        if($null -ne $assinaturaSetorIds -and @($assinaturaSetorIds).Count -gt 0){
            $basesAbrangencia = @($assinaturaSetorIds)
        } else {
            $basesAbrangencia = @($sid)
        }
        foreach($baseIdObj in $basesAbrangencia){
            $baseId=0
            try{$baseId=[int]$baseIdObj}catch{$baseId=0}
            if($baseId -le 0){continue}
            if(-not (@($idsAbrangencia) -contains $baseId)){[void]$idsAbrangencia.Add($baseId)}
            $paiIdObj=Db-Scalar "SELECT setor_pai_id FROM setores WHERE id=$baseId;"
            if($paiIdObj -ne $null -and $paiIdObj -ne [System.DBNull]::Value -and [string]$paiIdObj -ne ''){
                $paiId=[int]$paiIdObj
                if($paiId -gt 0 -and -not (@($idsAbrangencia) -contains $paiId)){[void]$idsAbrangencia.Add($paiId)}
            }
        }
        if($idsAbrangencia.Count -eq 0 -and [int]$sid -gt 0){[void]$idsAbrangencia.Add([int]$sid)}
        $idsAbrangenciaTxt = (@($idsAbrangencia | Sort-Object -Unique) -join ',')
        $ass = Db-Query "SELECT nome,cargo,coren,registro_extra,lado,ordem,espaco_acima FROM assinaturas WHERE ativo=1 AND (setor_id IN ($idsAbrangenciaTxt) OR setor_id IS NULL) ORDER BY ordem,nome;"
        [void]$sb.AppendLine('<div class="signatures">')
        if($ass.Rows.Count -gt 0) {
            foreach($a in $ass.Rows) {
                $cargoTxt = [string]$a['cargo']
                $corenTxt = $(if(-not [string]::IsNullOrWhiteSpace([string]$a['coren'])){Format-CorenText $a['coren']}else{''})
                $extraTxt = [string]$a['registro_extra']
                $linhasExtra = New-Object System.Text.StringBuilder
                if($cfg.assinaturaLinhasSeparadas){
                    if($cargoTxt){[void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $cargoTxt)))}
                    if($corenTxt){[void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $corenTxt)))}
                    if($extraTxt){[void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $extraTxt)))}
                } else {
                    $detail=$cargoTxt
                    if($corenTxt){if($detail){$detail+=' - '};$detail+=$corenTxt}
                    if($extraTxt){if($detail){$detail+=' - '};$detail+=$extraTxt}
                    if($detail){[void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $detail)))}
                }
                [void]$sb.AppendLine(('<div class="signature" style="margin-top:{0}mm"><div class="line">{1}</div>{2}</div>' -f [int]$a['espaco_acima'],(Html-E $a['nome']),$linhasExtra.ToString()))
            }
        } elseif(-not [string]::IsNullOrWhiteSpace($chefia)) {
            $linhasExtra = New-Object System.Text.StringBuilder
            $corenChefiaTxt=$(if(-not [string]::IsNullOrWhiteSpace($corenChefia)){Format-CorenText $corenChefia}else{''})
            if($cfg.assinaturaLinhasSeparadas){
                [void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $cfg.textoChefiaPadrao)))
                if($corenChefiaTxt){[void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $corenChefiaTxt)))}
            } else {
                $detail=$cfg.textoChefiaPadrao
                if($corenChefiaTxt){$detail+=(' - '+$corenChefiaTxt)}
                [void]$linhasExtra.Append(('<div>{0}</div>' -f (Html-E $detail)))
            }
            [void]$sb.AppendLine(('<div class="signature"><div class="line">{0}</div>{1}</div>' -f (Html-E $chefia),$linhasExtra.ToString()))
        } else {
            [void]$sb.AppendLine(('<div class="signature"><div class="line">&nbsp;</div><div>{0}</div></div>' -f (Html-E $cfg.textoChefiaPadrao)))
        }
        [void]$sb.AppendLine('</div>')
        [void]$sb.AppendLine('</div>')
    }

    if($showLegend){
        [void]$sb.AppendLine('<div class="right-col">')
        $ordemLeg=$(if([string]$cfg.legendaOrdenarPor -eq 'DESCRICAO'){'descricao,sigla'}else{'sigla'})
        # V1.0.14.66 - Siglas de tipos de ocorrencia que aparecem na folha mas NAO existem na tabela siglas (ex.: SA, SAAT, ASJR)
        # tambem entram na legenda (cores neutras), para toda sigla impressa ter significado.
        $keys=@($usedSiglas.Keys | Sort-Object)
        $occSql=''
        if($keys.Count -gt 0){
            $quotedKeys=@();$quotedOcc=@();foreach($k in $keys){$quotedKeys+=(Sql-Q $k);$quotedOcc+=(Sql-Q ([string]$k).Trim().ToUpperInvariant())}
            # V1.0.14.67 - comparacao normalizada (UPPER/TRIM), NOT EXISTS e uma unica linha por sigla (menor id do tipo ativo).
            $occSql=("UNION ALL SELECT t.sigla,t.nome,'#FFFFFF','#000000' FROM tipos_ocorrencia t WHERE t.ativo=1 AND t.sigla IS NOT NULL AND TRIM(t.sigla)<>'' AND UPPER(TRIM(t.sigla)) IN ({0}) AND NOT EXISTS (SELECT 1 FROM siglas s WHERE UPPER(TRIM(s.sigla))=UPPER(TRIM(t.sigla))) AND t.id=(SELECT MIN(t2.id) FROM tipos_ocorrencia t2 WHERE t2.ativo=1 AND t2.sigla IS NOT NULL AND UPPER(TRIM(t2.sigla))=UPPER(TRIM(t.sigla))) " -f ($quotedOcc -join ','))
        }
        if($legendAll){
            $legRows = Db-Query ("SELECT sigla,descricao,cor_fundo,cor_fonte FROM siglas WHERE ativo=1 {0}ORDER BY {1};" -f $occSql,$ordemLeg)
        } else {
            if($keys.Count -gt 0){$legRows=Db-Query ("SELECT sigla,descricao,cor_fundo,cor_fonte FROM siglas WHERE ativo=1 AND sigla IN ({0}) {1}ORDER BY {2};" -f ($quotedKeys -join ','),$occSql,$ordemLeg)}else{$legRows=Db-Query "SELECT sigla,descricao,cor_fundo,cor_fonte FROM siglas WHERE 1=0;"}
        }
        $legList = @($legRows.Rows)

        # V1.0.14.7 - Volta a 2 pares SIGLA/SIGNIFICADO (nao 3). O ajuste de
        # espaco desnecessario e feito no CSS (.legend com largura pelo
        # conteudo, empurrada para a direita), nao dividindo em mais colunas.
        $legPairs = [int]$cfg.legendPairs
        if($legPairs -lt 1){$legPairs=1}
        if($legPairs -gt 3){$legPairs=3}
        $legRowsCount = $(if($legList.Count -gt 0){[int][Math]::Ceiling($legList.Count / [double]$legPairs)}else{0})
        if($cfg.tituloLegendaVisivel -and -not [string]::IsNullOrWhiteSpace([string]$cfg.tituloLegenda)){
            [void]$sb.AppendLine(('<div class="legend-title">{0}</div>' -f (Html-E $cfg.tituloLegenda)))
        }
        [void]$sb.AppendLine('<table class="legend">')
        $headerCells = New-Object System.Text.StringBuilder
        for($p=0;$p -lt $legPairs;$p++){[void]$headerCells.Append('<th>SIGLA</th><th>SIGNIFICADO</th>')}
        [void]$sb.AppendLine(('<tr>{0}</tr>' -f $headerCells.ToString()))
        for($i=0; $i -lt $legRowsCount; $i++) {
            $rowCells = New-Object System.Text.StringBuilder
            for($p=0;$p -lt $legPairs;$p++){
                $idx = $p*$legRowsCount + $i
                if($idx -lt $legList.Count){
                    $item=$legList[$idx];$sg=[string]$item['sigla'];$desc=[string]$item['descricao'];$bg=Get-SafeHexColor ([string]$item['cor_fundo']) '#FFFFFF';$fg=Get-SafeHexColor ([string]$item['cor_fonte']) '#000000'
                    [void]$rowCells.Append(('<td class="sg" style="background-color:{0};color:{1};">{2}</td><td class="meaning">{3}</td>' -f $bg,$fg,(Html-E $sg),(Html-E $desc)))
                } else {
                    [void]$rowCells.Append('<td></td><td></td>')
                }
            }
            [void]$sb.AppendLine(('<tr>{0}</tr>' -f $rowCells.ToString()))
        }
        [void]$sb.AppendLine('</table></div>')
    }
    if($showSignatures -or $showLegend){[void]$sb.AppendLine('</div>')}
    [void]$sb.AppendLine(('<div class="footer">Gerado pelo Sistema de Escala DCE em {0:dd/MM/yyyy HH:mm}</div>' -f (Get-Date)))
    return $sb.ToString()
}

function Toggle-ModoAvancadoEscala {
    # Modo simples/avancado: esconde por padrao os botoes menos usados no dia
    # a dia (LOTACAO EM LOTE, EXCLUIR DIAS, ESCALA VAGA), reduzindo a poluicao
    # visual para o usuario comum. "MAIS OPCOES" revela quando precisar.
    if($null -eq $script:AdvancedEscalaControls){return}
    $mostrando=$script:AdvancedEscalaControls[0].Visible
    $novo=-not $mostrando
    foreach($ctl in $script:AdvancedEscalaControls){$ctl.Visible=$novo}
    $script:btnMaisOpcoes.Text=$(if($novo){'MENOS OPCOES <<'}else{'MAIS OPCOES >>'})
}


function ConvertTo-SearchKey {
    param([AllowNull()][string]$Text)
    if($null -eq $Text){return ''}
    $s=[string]$Text
    if([string]::IsNullOrWhiteSpace($s)){return ''}
    try{
        $norm=$s.Normalize([System.Text.NormalizationForm]::FormD)
        $sb=New-Object System.Text.StringBuilder
        foreach($ch in $norm.ToCharArray()){
            $cat=[System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
            if($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark){
                [void]$sb.Append($ch)
            }
        }
        return $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC).Trim().ToUpperInvariant()
    }catch{
        return $s.Trim().ToUpperInvariant()
    }
}

function Filter-EscalaGridByServidor {
    <#
      Busca da aba Escala:
      - somente numeros -> CP ou Coren EXATO;
      - qualquer texto -> busca PARCIAL em Servidor, Funcao, CP e Coren.
      Blocos e Escala Vaga permanecem visiveis para manter o contexto.
    #>
    param([string]$Term)

    $g=$script:gridEscala
    if($null -eq $g){return}

    $raw=([string]$Term).Trim()
    $semFiltro=[string]::IsNullOrWhiteSpace($raw)
    $somenteNumero=(-not $semFiltro -and $raw -match '^\d+$')
    $chaveTexto=$(if($somenteNumero){''}else{ConvertTo-SearchKey $raw})

    $g.ClearSelection();$g.CurrentCell=$null

    $encontrados=0

    foreach($row in $g.Rows){
        try{
            $tipo=[string]$row.Cells['_TIPO'].Value

            if($tipo -ne 'SERVIDOR'){
                $row.Visible=$true
                continue
            }

            if($semFiltro){
                $row.Visible=$true
                $encontrados++
                continue
            }

            $nome=[string]$row.Cells['Servidor'].Value
            $cp=([string]$row.Cells['CP'].Value).Trim()
            $funcao=[string]$row.Cells['Funcao'].Value
            $coren=([string]$row.Cells['Coren'].Value).Trim()

            $mostrar=$false

            if($somenteNumero){
                $cpDigitos=($cp -replace '\D','')
                $corenDigitos=($coren -replace '\D','')
                $mostrar=($cpDigitos -eq $raw -or $corenDigitos -eq $raw)
            }else{
                $nomeKey=ConvertTo-SearchKey $nome
                $cpKey=ConvertTo-SearchKey $cp
                $funcaoKey=ConvertTo-SearchKey $funcao
                $corenKey=ConvertTo-SearchKey $coren

                $mostrar=(
                    $nomeKey.Contains($chaveTexto) -or
                    $cpKey.Contains($chaveTexto) -or
                    $funcaoKey.Contains($chaveTexto) -or
                    $corenKey.Contains($chaveTexto)
                )
            }

            $row.Visible=$mostrar
            if($mostrar){$encontrados++}
        }catch{
            Write-Log ("Falha ao aplicar busca na aba Escala: " + $_.Exception.Message)
        }
    }

    if($null -ne $script:tipBuscaEscala){
        $script:tipBuscaEscala.SetToolTip(
            $script:txtBuscaEscala,
            ("Busca: Servidor, CP, Funcao e Coren.`r`nNumero = exato em CP/Coren. Texto = parte do conteudo.`r`nEncontrado(s): {0}" -f $encontrados)
        )
    }
}

function Show-ScalePreviewComChecklist {
    # Antes de abrir a pre-visualizacao, avisa sobre pendencias comuns
    # (servidor sem Coren, dia do mes sem nenhum lancamento) para o usuario
    # nao so descobrir depois de ja ter impresso/enviado.
    param($ForcarLegenda=$null)
    try {
        $sid=Get-SelectedSetorId;if($sid -le 0){Show-Info 'Selecione o setor.';return}
        $scaleId=Get-ScaleId
        if($scaleId -le 0){Show-Info 'Crie ou carregue a escala deste mes antes da pre-visualizacao.';return}
        $ano=[int]$script:numAno.Value;$mes=[int]$script:cboMes.SelectedValue
        $semCoren=[int](Db-Scalar "SELECT COUNT(*) FROM escala_servidores es JOIN servidores s ON s.id=es.servidor_id WHERE es.escala_id=$scaleId AND es.ativo=1 AND (s.coren IS NULL OR TRIM(s.coren)='');")
        $diasNoMes=[datetime]::DaysInMonth($ano,$mes)
        $first=(Get-Date -Year $ano -Month $mes -Day 1).ToString('yyyy-MM-dd')
        $last=(Get-Date -Year $ano -Month $mes -Day 1).AddMonths(1).AddDays(-1).ToString('yyyy-MM-dd')
        $diasComLancamento=[int](Db-Scalar "SELECT COUNT(DISTINCT ed.data) FROM escala_dias ed JOIN escala_servidores es ON es.id=ed.escala_servidor_id WHERE es.escala_id=$scaleId AND es.ativo=1 AND ed.data BETWEEN '$first' AND '$last' AND COALESCE(TRIM(ed.sigla),'')<>'';")
        $diasSemLancamento=$diasNoMes-$diasComLancamento
        if($semCoren -gt 0 -or $diasSemLancamento -gt 0){
            $msg="Antes de imprimir, confira:`r`n"
            if($semCoren -gt 0){$msg+="`r`n- $semCoren servidor(es) sem Coren cadastrado"}
            if($diasSemLancamento -gt 0){$msg+="`r`n- $diasSemLancamento dia(s) do mes sem nenhum lancamento em nenhum servidor"}
            $msg+="`r`n`r`nDeseja abrir a pre-visualizacao mesmo assim?"
            if(-not(Confirm-Action $msg)){return}
        }
        Show-ScalePreview $ForcarLegenda
    } catch { Show-Error $_.Exception.Message }
}

function Show-ScalePreview {
    param($ForcarLegenda=$null)
    try {
        $sid = Get-SelectedSetorId
        if ($sid -le 0) { Show-Info 'Selecione o setor.'; return }

        $ano = [int]$script:numAno.Value
        $mes = [int]$script:cboMes.SelectedValue
        $scaleId = Get-ScaleId
        if ($scaleId -le 0) {
            Show-Info 'Crie ou carregue a escala deste mes antes da pre-visualizacao.'
            return
        }

        Load-SiglaCache
        $cfg = Get-ScalePreviewConfig
        if ($null -ne $ForcarLegenda) { $cfg.showLegend = [bool]$ForcarLegenda }
        $sheet = Build-EscalaSheetHtml $sid $ano $mes $scaleId $cfg
        if($sheet.SyncError){Show-Error $sheet.SyncErrorMessage;return}
        if ([string]::IsNullOrWhiteSpace($sheet.Html)) { Show-Info 'Setor nao encontrado.'; return }
        $rodape = Build-EscalaRodapeHtml $sid $sheet.Used $cfg

        $file = New-UniquePreviewPath ([string]$sheet.SetorNome) 'PREVIA_MODELO_APROVADO' ([int]$ano) ([int]$mes)

        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('<!doctype html>')
        [void]$sb.AppendLine('<html lang="pt-BR"><head><meta charset="utf-8"><meta http-equiv="Cache-Control" content="no-store, no-cache, must-revalidate"><meta http-equiv="Pragma" content="no-cache"><meta http-equiv="Expires" content="0">')
        [void]$sb.AppendLine(('<title>Escala - {0} - {1:00}/{2}</title>' -f (Html-E $sheet.SetorNome),$mes,$ano))
        $diaWidthMm = Get-ScaleDayWidthMm ([datetime]::DaysInMonth($ano,$mes)) $cfg.margemPaginaMm $cfg.paddingFolhaMm
        [void]$sb.AppendLine((Get-ScalePreviewStyleBlock $cfg $diaWidthMm))
        [void]$sb.AppendLine('</head><body>')
        [void]$sb.AppendLine('<div class="toolbar"><button type="button" onclick="window.print()">IMPRIMIR / SALVAR PDF</button><span class="note">Pre-visualizacao oficial: blocos de horario, ocorrencias, paridade e Escala Vaga.</span></div>')
        [void]$sb.AppendLine('<div class="sheet">')
        [void]$sb.AppendLine($sheet.Html)
        [void]$sb.AppendLine($rodape)
        [void]$sb.AppendLine('</div>')
        [void]$sb.AppendLine(@'
<script>
(function(){
    // V1.0.14.73 - Rede de seguranca: garante que nenhum nome na coluna "Nomes" quebre para uma 2a linha
    // na impressao real. Mede a largura JA RENDERIZADA (fonte/zoom/impressora reais) em vez de estimar por
    // contagem de caracteres. So abrevia mais um nome do meio por vez, e so o minimo necessario para caber.
    // Primeiro nome e ultimo sobrenome NUNCA sao abreviados aqui (mesma regra do servidor).
    var PARTICULAS={'de':1,'da':1,'do':1,'dos':1,'das':1,'e':1};
    function abreviarMais(nome){
        var partes=nome.trim().split(/\s+/).filter(function(p){return p!=='';});
        if(partes.length<=2){return null;}
        for(var i=1;i<partes.length-1;i++){
            var p=partes[i];
            if(!p||PARTICULAS[p.toLowerCase()]){continue;}
            if(p.length>1 && p.slice(-1)==='.'){continue;}
            partes[i]=p.charAt(0)+'.';
            return partes.join(' ');
        }
        return null;
    }
    function ajustarNomes(){
        var celulas=document.querySelectorAll('td.name');
        for(var i=0;i<celulas.length;i++){
            var td=celulas[i];
            var tentativas=0;
            while(td.scrollWidth>td.clientWidth+1 && tentativas<15){
                var abreviado=abreviarMais(td.textContent);
                if(!abreviado){break;}
                td.textContent=abreviado;
                tentativas++;
            }
            // V1.0.14.77 - Ultimo recurso: se mesmo abreviado ao maximo o nome ainda nao couber
            // (nomes com muitas palavras + fonte grande/larga), reduz so a fonte DESSA celula, aos
            // poucos, ate caber - nunca abaixo de 70% do tamanho configurado (nunca fica ilegivel).
            if(td.scrollWidth>td.clientWidth+1){
                var basePx=parseFloat(window.getComputedStyle(td).fontSize)||10;
                var pisoPx=basePx*0.7;
                var atualPx=basePx;
                var passos=0;
                while(td.scrollWidth>td.clientWidth+1 && atualPx>pisoPx && passos<20){
                    atualPx=Math.max(pisoPx,atualPx-0.4);
                    td.style.fontSize=atualPx+'px';
                    passos++;
                }
            }
        }
    }
    function rodar(){
        ajustarNomes();
        if(document.fonts && document.fonts.ready){document.fonts.ready.then(ajustarNomes).catch(function(){});}
    }
    if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',rodar);}else{rodar();}
    window.addEventListener('beforeprint',ajustarNomes);
    window.addEventListener('resize',ajustarNomes);
})();
</script>
'@)
        [void]$sb.AppendLine('</body></html>')

        [System.IO.File]::WriteAllText($file,$sb.ToString(),[System.Text.Encoding]::UTF8)
        Write-Log ('Pre-visualizacao no modelo aprovado gerada: ' + $file)
        Cleanup-OldPreviewFiles
        Start-Process -FilePath $file
    } catch {
        Show-Error ("Falha ao gerar a pre-visualizacao:`r`n" + $_.Exception.Message)
    }
}

function Select-ScalePreviewCombinadoUnidades {
    # Permite escolher exatamente quais unidades do Setor Principal entram no
    # documento combinado. Inclui SEMPRE o proprio Setor Principal (sem Sub_Setor)
    # como opcao, alem dos Sub_Setores ativos com escala propria.
    param([int]$Principal,[int]$Ano,[int]$Mes)
    try {
        $nomePrincipal=[string](Db-Scalar "SELECT nome FROM setores WHERE id=$Principal;")
        if([string]::IsNullOrWhiteSpace($nomePrincipal)){return $null}

        $unidades=New-Object System.Collections.ArrayList

        # O Setor Principal pode possuir servidores diretamente, sem Sub_Setor.
        $scalePrincipal=[int](Db-Scalar "SELECT COALESCE((SELECT id FROM escalas WHERE setor_id=$Principal AND ano=$Ano AND mes=$Mes),0);")
        [void]$unidades.Add([pscustomobject]@{
            Rotulo=('SETOR PRINCIPAL - {0} (sem Sub_Setor){1}' -f $nomePrincipal,$(if($scalePrincipal -gt 0){'  [COM ESCALA]'}else{'  [SEM ESCALA NO MES]'}))
            SetorId=$Principal
            ScaleId=$scalePrincipal
            Tipo='PRINCIPAL'
        })

        $subs=Db-Query "SELECT id,nome FROM sub_setores WHERE ativo=1 AND setor_id=$Principal AND possui_escala=1 ORDER BY nome;"
        foreach($s in $subs.Rows){
            $subId=[int]$s['id']
            $setorId=[int](Ensure-SubSetorScaleSector $Principal $subId)
            if($setorId -le 0){continue}
            $scaleId=[int](Db-Scalar "SELECT COALESCE((SELECT id FROM escalas WHERE setor_id=$setorId AND ano=$Ano AND mes=$Mes),0);")
            $subNome=[string]$s['nome']
            [void]$unidades.Add([pscustomobject]@{
                Rotulo=('SUB_SETOR - {0}{1}' -f $subNome,$(if($scaleId -gt 0){'  [COM ESCALA]'}else{'  [SEM ESCALA NO MES]'}))
                SetorId=$setorId
                ScaleId=$scaleId
                Tipo='SUB'
            })
        }

        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text='Escolher escalas da Pre-visualizacao Combinada'
        $f.StartPosition='CenterParent'
        $f.ClientSize=New-Object System.Drawing.Size(760,540)
        $f.MinimumSize=New-Object System.Drawing.Size(700,500)
        $f.FormBorderStyle='Sizable'
        $f.MaximizeBox=$true
        $f.MinimizeBox=$false
        $f.AutoScaleMode='Dpi'

        $tit=New-Object System.Windows.Forms.Label
        $tit.Text=('Escolha o que sera combinado - {0}' -f $nomePrincipal)
        $tit.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12)
        $tit.Location=New-Object System.Drawing.Point(22,20)
        $tit.AutoSize=$true
        $f.Controls.Add($tit)

        $info=New-Object System.Windows.Forms.Label
        $info.Text=('Mes/Ano: {0:00}/{1}. O Setor Principal aparece separado dos Sub_Setores e tambem pode ser marcado quando possuir servidores proprios.' -f $Mes,$Ano)
        $info.Location=New-Object System.Drawing.Point(24,54)
        $info.Size=New-Object System.Drawing.Size(700,44)
        $info.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
        $f.Controls.Add($info)

        $clb=New-Object System.Windows.Forms.CheckedListBox
        $clb.Location=New-Object System.Drawing.Point(24,105)
        $clb.Size=New-Object System.Drawing.Size(710,300)
        $clb.Anchor='Top,Bottom,Left,Right'
        $clb.CheckOnClick=$true
        $clb.IntegralHeight=$false
        $clb.Font=New-Object System.Drawing.Font('Segoe UI',10)
        $f.Controls.Add($clb)

        for($i=0;$i -lt $unidades.Count;$i++){
            [void]$clb.Items.Add([string]$unidades[$i].Rotulo)
            if([int]$unidades[$i].ScaleId -gt 0){$clb.SetItemChecked($i,$true)}
        }

        $btnTodos=New-Object System.Windows.Forms.Button
        $btnTodos.Text='MARCAR COM ESCALA'
        $btnTodos.Location=New-Object System.Drawing.Point(24,420)
        $btnTodos.Size=New-Object System.Drawing.Size(170,34)
        $btnTodos.Anchor='Bottom,Left'
        $f.Controls.Add($btnTodos)

        $btnNenhum=New-Object System.Windows.Forms.Button
        $btnNenhum.Text='DESMARCAR TODOS'
        $btnNenhum.Location=New-Object System.Drawing.Point(202,420)
        $btnNenhum.Size=New-Object System.Drawing.Size(160,34)
        $btnNenhum.Anchor='Bottom,Left'
        $f.Controls.Add($btnNenhum)

        $btnGerar=New-Object System.Windows.Forms.Button
        $btnGerar.Text='GERAR COMBINADO'
        $btnGerar.Location=New-Object System.Drawing.Point(420,475)
        $btnGerar.Size=New-Object System.Drawing.Size(155,38)
        $btnGerar.Anchor='Bottom,Right'
        Set-PrimaryButton $btnGerar
        $f.Controls.Add($btnGerar)

        $btnCancelar=New-Object System.Windows.Forms.Button
        $btnCancelar.Text='CANCELAR'
        $btnCancelar.Location=New-Object System.Drawing.Point(583,475)
        $btnCancelar.Size=New-Object System.Drawing.Size(150,38)
        $btnCancelar.Anchor='Bottom,Right'
        $f.Controls.Add($btnCancelar)
        $f.CancelButton=$btnCancelar

        $btnTodos.Add_Click({
            for($i=0;$i -lt $unidades.Count;$i++){
                $clb.SetItemChecked($i,([int]$unidades[$i].ScaleId -gt 0))
            }
        })
        $btnNenhum.Add_Click({for($i=0;$i -lt $clb.Items.Count;$i++){$clb.SetItemChecked($i,$false)}})
        $btnCancelar.Add_Click({$f.DialogResult=[System.Windows.Forms.DialogResult]::Cancel;$f.Close()})

        $btnGerar.Add_Click({
            $sel=New-Object System.Collections.ArrayList
            foreach($idx in $clb.CheckedIndices){[void]$sel.Add($unidades[[int]$idx])}
            if($sel.Count -eq 0){Show-Info 'Marque pelo menos um Setor/Sub_Setor para gerar a pre-visualizacao combinada.';return}

            $sem=@($sel | Where-Object {[int]$_.ScaleId -le 0})
            if($sem.Count -gt 0){
                $nomes=($sem | ForEach-Object {[string]$_.Rotulo}) -join "`r`n- "
                $msg="Os itens abaixo nao possuem escala criada para $($Mes.ToString('00'))/$Ano e serao ignorados:`r`n- $nomes`r`n`r`nDeseja continuar com os demais itens marcados?"
                if(-not (Confirm-Action $msg)){return}
            }
            $validos=@($sel | Where-Object {[int]$_.ScaleId -gt 0})
            if($validos.Count -eq 0){Show-Info 'Nenhum dos itens marcados possui escala criada para este mes/ano.';return}

            $f.Tag=[object[]]$validos
            $f.DialogResult=[System.Windows.Forms.DialogResult]::OK
            $f.Close()
        })

        $res=$f.ShowDialog($script:MainForm)
        $selecionados=$null
        if($res -eq [System.Windows.Forms.DialogResult]::OK -and $null -ne $f.Tag){$selecionados=[object[]]$f.Tag}
        $f.Dispose()
        if($null -eq $selecionados){return $null}
        return $selecionados
    } catch {
        Show-Error ("Falha ao montar a selecao da pre-visualizacao combinada:`r`n"+$_.Exception.Message)
        return $null
    }
}

function Show-ScalePreviewCombinado {
    # V1.0.14.21.5 - O usuario escolhe quais unidades entram no combinado e
    # o rodape respeita as assinaturas das unidades efetivamente selecionadas.
    # Diferente da versao anterior, o Setor Principal (sem Sub_Setor) tambem
    # participa e nao e mais ignorado quando possui servidores/escala propria.
    param($ForcarLegenda=$null)
    try {
        $principal = Get-SelectedPrincipalSetorId
        if ($principal -le 0) { Show-Info 'Selecione o Setor Principal.'; return }
        $ano = [int]$script:numAno.Value
        $mes = [int]$script:cboMes.SelectedValue

        $selecionadas=@(Select-ScalePreviewCombinadoUnidades $principal $ano $mes | Where-Object { $null -ne $_ })
        if($selecionadas.Count -eq 0){return}

        Load-SiglaCache
        $cfg = Get-ScalePreviewConfig
        if ($null -ne $ForcarLegenda) { $cfg.showLegend = [bool]$ForcarLegenda }
        $usedTotal = @{}
        $sheetsHtml = New-Object System.Collections.ArrayList
        $assinaturaSetorIds = New-Object System.Collections.ArrayList

        foreach ($u in $selecionadas) {
            $setorId=[int]$u.SetorId
            $scaleId=[int]$u.ScaleId
            if($setorId -le 0 -or $scaleId -le 0){continue}
            if(-not (@($assinaturaSetorIds) -contains $setorId)){[void]$assinaturaSetorIds.Add($setorId)}
            $sheet = Build-EscalaSheetHtml $setorId $ano $mes $scaleId $cfg
            if($sheet.SyncError){Show-Error $sheet.SyncErrorMessage;return}
            if ([string]::IsNullOrWhiteSpace($sheet.Html)) { continue }
            [void]$sheetsHtml.Add($sheet.Html)
            foreach ($k in $sheet.Used.Keys) { $usedTotal[$k] = $true }
        }

        if($sheetsHtml.Count -eq 0){Show-Info 'Nenhuma das escalas selecionadas possui conteudo para a pre-visualizacao combinada.';return}

        $rodape = Build-EscalaRodapeHtml $principal $usedTotal $cfg ([object[]]$assinaturaSetorIds)
        $nomePrincipal = Db-Scalar "SELECT nome FROM setores WHERE id=$principal;"

        $file = New-UniquePreviewPath ([string]$nomePrincipal) 'COMBINADA_PREVIA' ([int]$ano) ([int]$mes)

        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('<!doctype html>')
        [void]$sb.AppendLine('<html lang="pt-BR"><head><meta charset="utf-8"><meta http-equiv="Cache-Control" content="no-store, no-cache, must-revalidate"><meta http-equiv="Pragma" content="no-cache"><meta http-equiv="Expires" content="0">')
        [void]$sb.AppendLine(('<title>Escala combinada - {0} - {1:00}/{2}</title>' -f (Html-E $nomePrincipal),$mes,$ano))
        $diaWidthMm = Get-ScaleDayWidthMm ([datetime]::DaysInMonth($ano,$mes)) $cfg.margemPaginaMm $cfg.paddingFolhaMm
        [void]$sb.AppendLine((Get-ScalePreviewStyleBlock $cfg $diaWidthMm))
        [void]$sb.AppendLine('</head><body>')
        [void]$sb.AppendLine('<div class="toolbar"><button type="button" onclick="window.print()">IMPRIMIR / SALVAR PDF</button><span class="note">Pre-visualizacao combinada: apenas os Setores/Sub_Setores escolhidos.</span></div>')
        [void]$sb.AppendLine('<div class="sheet">')
        foreach ($h in $sheetsHtml) { [void]$sb.AppendLine($h) }
        [void]$sb.AppendLine($rodape)
        [void]$sb.AppendLine('</div>')
        [void]$sb.AppendLine(@'
<script>
(function(){
    // V1.0.14.73 - Rede de seguranca: garante que nenhum nome na coluna "Nomes" quebre para uma 2a linha
    // na impressao real. Mede a largura JA RENDERIZADA (fonte/zoom/impressora reais) em vez de estimar por
    // contagem de caracteres. So abrevia mais um nome do meio por vez, e so o minimo necessario para caber.
    // Primeiro nome e ultimo sobrenome NUNCA sao abreviados aqui (mesma regra do servidor).
    var PARTICULAS={'de':1,'da':1,'do':1,'dos':1,'das':1,'e':1};
    function abreviarMais(nome){
        var partes=nome.trim().split(/\s+/).filter(function(p){return p!=='';});
        if(partes.length<=2){return null;}
        for(var i=1;i<partes.length-1;i++){
            var p=partes[i];
            if(!p||PARTICULAS[p.toLowerCase()]){continue;}
            if(p.length>1 && p.slice(-1)==='.'){continue;}
            partes[i]=p.charAt(0)+'.';
            return partes.join(' ');
        }
        return null;
    }
    function ajustarNomes(){
        var celulas=document.querySelectorAll('td.name');
        for(var i=0;i<celulas.length;i++){
            var td=celulas[i];
            var tentativas=0;
            while(td.scrollWidth>td.clientWidth+1 && tentativas<15){
                var abreviado=abreviarMais(td.textContent);
                if(!abreviado){break;}
                td.textContent=abreviado;
                tentativas++;
            }
            // V1.0.14.77 - Ultimo recurso: se mesmo abreviado ao maximo o nome ainda nao couber
            // (nomes com muitas palavras + fonte grande/larga), reduz so a fonte DESSA celula, aos
            // poucos, ate caber - nunca abaixo de 70% do tamanho configurado (nunca fica ilegivel).
            if(td.scrollWidth>td.clientWidth+1){
                var basePx=parseFloat(window.getComputedStyle(td).fontSize)||10;
                var pisoPx=basePx*0.7;
                var atualPx=basePx;
                var passos=0;
                while(td.scrollWidth>td.clientWidth+1 && atualPx>pisoPx && passos<20){
                    atualPx=Math.max(pisoPx,atualPx-0.4);
                    td.style.fontSize=atualPx+'px';
                    passos++;
                }
            }
        }
    }
    function rodar(){
        ajustarNomes();
        if(document.fonts && document.fonts.ready){document.fonts.ready.then(ajustarNomes).catch(function(){});}
    }
    if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',rodar);}else{rodar();}
    window.addEventListener('beforeprint',ajustarNomes);
    window.addEventListener('resize',ajustarNomes);
})();
</script>
'@)
        [void]$sb.AppendLine('</body></html>')

        [System.IO.File]::WriteAllText($file,$sb.ToString(),[System.Text.Encoding]::UTF8)
        Write-Log ('Pre-visualizacao combinada gerada com {0} unidade(s): {1}' -f $sheetsHtml.Count,$file)
        Cleanup-OldPreviewFiles
        Start-Process -FilePath $file
    } catch {
        Show-Error ("Falha ao gerar a pre-visualizacao combinada:`r`n" + $_.Exception.Message)
    }
}


function Get-BackupRetentionLimit {
    return Get-ConfigInt 'backup_max_arquivos' 15 1 500
}

function Get-BackupNamePattern {
    # V1.0.14.37 - padrao EXATO dos arquivos criados pelo sistema. A retencao nunca toca em outros
    # arquivos que existam na mesma pasta (principalmente na pasta adicional escolhida pelo usuario).
    param([string]$Tipo='Escala')
    if($Tipo -eq 'Seguranca'){return '^Seguranca_PRE-ZERAR_\d{8}_\d{6}(_\d{3})?\.db$'}
    return '^Escala_\d{8}_\d{6}(_\d{3})?\.db$'
}

function Remove-BackupsAntigosNoDiretorio {
    param([string]$Diretorio,[string]$Tipo='Escala')
    try {
        if([string]::IsNullOrWhiteSpace($Diretorio) -or -not (Test-Path -LiteralPath $Diretorio)){return}
        $limite=$(if($Tipo -eq 'Seguranca'){10}else{Get-BackupRetentionLimit})
        $rx=Get-BackupNamePattern $Tipo
        # O nome contem timestamp em ordem lexicografica; nao depende do LastWriteTime.
        $arquivos=@(Get-ChildItem -LiteralPath $Diretorio -File | Where-Object{$_.Name -match $rx} | Sort-Object Name -Descending)
        if($arquivos.Count -gt $limite){
            foreach($a in ($arquivos | Select-Object -Skip $limite)){
                try{Remove-Item -LiteralPath $a.FullName -Force;Write-Log ('Backup antigo removido (retencao, limite '+$limite+'): '+$a.FullName)}
                catch{Write-Log ('Falha ao remover backup antigo '+$a.FullName+': '+$_.Exception.Message)}
            }
        }
    }catch{Write-Log ('Falha na rotina de retencao de backups em '+$Diretorio+': '+$_.Exception.Message)}
}

function Initialize-BackupCopier {
    # Ajudante .NET para a pasta adicional: roda em thread de fundo com tempo limite, de modo que uma
    # pasta de rede fora do ar nao trave o fechamento do sistema. Compila uma unica vez por sessao.
    if('EscalaDCE.BackupCopier' -as [type]){return}
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using System.Threading;
using System.Collections.Generic;
namespace EscalaDCE {
    public static class BackupCopier {
        private static string Hash(string path) {
            using (SHA256 sha = SHA256.Create())
            using (FileStream fs = File.OpenRead(path)) {
                return BitConverter.ToString(sha.ComputeHash(fs));
            }
        }
        // Copia src para dstDir e confere SHA256 (origem ja foi validada por integrity_check).
        // Depois remove os excedentes que casem EXATAMENTE com o regex, mantendo os 'keep' mais recentes.
        // Retorna o caminho copiado; em erro/tempo esgotado retorna null e preenche error.
        public static string CopyAndPrune(string src, string dstDir, string regex, int keep, int timeoutMs, out string removedCsv, out string error) {
            string result = null; string err = null; string removed = "";
            bool[] abandoned = new bool[1];
            Thread t = new Thread(delegate() {
                string tmp = null;
                try {
                    if (!Directory.Exists(dstDir)) Directory.CreateDirectory(dstDir);
                    DateTime staleBefore = DateTime.UtcNow.AddHours(-1);
                    Regex tmpRx = new Regex(regex.Substring(0, regex.Length - 1) + "\\.tmp$");
                    foreach (string oldTmp in Directory.GetFiles(dstDir, "*.db.tmp")) {
                        try {
                            string oldName = Path.GetFileName(oldTmp);
                            if (tmpRx.IsMatch(oldName) && File.GetLastWriteTimeUtc(oldTmp) < staleBefore)
                                File.Delete(oldTmp);
                        } catch (Exception) { }
                    }
                    string dst = Path.Combine(dstDir, Path.GetFileName(src));
                    tmp = dst + ".tmp";
                    if (File.Exists(tmp)) File.Delete(tmp);
                    File.Copy(src, tmp, true);
                    if (abandoned[0]) { try { File.Delete(tmp); } catch (Exception) { } return; }
                    if (Hash(src) != Hash(tmp)) {
                        try { File.Delete(tmp); } catch (Exception) { }
                        throw new Exception("A copia adicional ficou com hash diferente da origem e foi descartada.");
                    }
                    if (abandoned[0]) { try { File.Delete(tmp); } catch (Exception) { } return; }
                    if (File.Exists(dst)) File.Delete(dst);
                    File.Move(tmp, dst);
                    tmp = null;
                    Regex rx = new Regex(regex);
                    List<string> names = new List<string>();
                    foreach (string f in Directory.GetFiles(dstDir)) {
                        string n = Path.GetFileName(f);
                        if (rx.IsMatch(n)) names.Add(n);
                    }
                    names.Sort(StringComparer.Ordinal);
                    names.Reverse();
                    List<string> gone = new List<string>();
                    for (int i = keep; i < names.Count; i++) {
                        if (abandoned[0]) break;
                        try { File.Delete(Path.Combine(dstDir, names[i])); gone.Add(names[i]); } catch (Exception) { }
                    }
                    removed = string.Join("|", gone.ToArray());
                    result = dst;
                } catch (Exception ex) {
                    err = ex.Message;
                    if (tmp != null) { try { File.Delete(tmp); } catch (Exception) { } }
                }
            });
            t.IsBackground = true;
            t.Start();
            if (!t.Join(timeoutMs)) {
                abandoned[0] = true;
                removedCsv = "";
                error = "Tempo esgotado (" + (timeoutMs / 1000).ToString() + "s) ao acessar a pasta adicional.";
                return null;
            }
            removedCsv = removed;
            error = err;
            return result;
        }
    }
}
'@ -ErrorAction Stop
}

function Test-SqliteIntegrityFile {
    param([string]$Path)
    if(-not (Test-Path -LiteralPath $Path)){return $false}
    try{
        $t=[WinSQLite]::Query($Path,'PRAGMA integrity_check;')
        if($null -eq $t -or $t.Rows.Count -eq 0){return $false}
        return (([string]$t.Rows[0][0]).Trim().ToLowerInvariant() -eq 'ok')
    }catch{
        Write-Log ('Falha no integrity_check de ' + $Path + ': ' + $_.Exception.Message)
        return $false
    }
}

function Backup-Database {
    # V1.0.14.36 - backup consistente. Preferencia: VACUUM INTO, que cria uma
    # copia transacional autocontida do banco mesmo com o aplicativo aberto.
    # Fallback para SQLite antigo: checkpoint OBRIGATORIO + Copy-Item. Em ambos
    # os casos a copia so e aceita depois de PRAGMA integrity_check = ok.
    # V1.0.14.37 - -Seguranca: backup antes de operacao destrutiva (ZERAR HISTORICO), com nome proprio
    # (Seguranca_PRE-ZERAR_*) e retencao separada, para nao ser apagado pelos backups de rotina.
    param([switch]$Silencioso,[switch]$Obrigatorio,[switch]$Seguranca)
    try{
        if(-not(Test-Path $script:BackupDir)){New-Item -ItemType Directory -Path $script:BackupDir -Force|Out-Null}
        $tipoBk=$(if($Seguranca){'Seguranca'}else{'Escala'})
        $prefixoBk=$(if($Seguranca){'Seguranca_PRE-ZERAR_'}else{'Escala_'})
        $dest=Join-Path $script:BackupDir ('{0}{1:yyyyMMdd_HHmmss_fff}.db' -f $prefixoBk,(Get-Date))
        $metodo='VACUUM INTO'
        try{
            Db-Exec ("VACUUM INTO {0};" -f (Sql-Q $dest))
        }catch{
            $vacErr=$_.Exception.Message
            Write-Log ('VACUUM INTO indisponivel/falhou; tentando fallback seguro: ' + $vacErr)
            $metodo='CHECKPOINT + COPY'
            if(Test-Path -LiteralPath $dest){Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue}
            $jr=''
            try{$jr=[string](Db-Scalar 'PRAGMA journal_mode;')}catch{Write-Log ('Falha ao consultar journal_mode durante backup: '+$_.Exception.Message);throw}
            if($jr.Trim().ToUpperInvariant() -eq 'WAL'){
                $ck=Db-Query 'PRAGMA wal_checkpoint(FULL);'
                if($ck.Rows.Count -eq 0){throw 'SQLite nao retornou resultado do wal_checkpoint(FULL).'}
                $busy=0;$logFrames=0;$doneFrames=0
                try{$busy=[int]$ck.Rows[0][0];$logFrames=[int]$ck.Rows[0][1];$doneFrames=[int]$ck.Rows[0][2]}catch{throw 'Resultado invalido do wal_checkpoint(FULL).'}
                if($busy -ne 0 -or $doneFrames -lt $logFrames){throw ("Checkpoint WAL incompleto (busy={0}; log={1}; checkpointed={2}). Backup por copia foi cancelado." -f $busy,$logFrames,$doneFrames)}
            }
            Copy-Item -LiteralPath $script:DbPath -Destination $dest -Force -ErrorAction Stop
        }
        if(-not (Test-Path -LiteralPath $dest)){ throw 'O arquivo de backup nao foi criado.' }
        if((Get-Item -LiteralPath $dest).Length -le 0){ throw 'O arquivo de backup foi criado vazio.' }
        if(-not (Test-SqliteIntegrityFile $dest)){
            Remove-Item -LiteralPath $dest -Force
            throw 'O backup foi criado, mas falhou no PRAGMA integrity_check e foi descartado.'
        }
        Write-Log ('Backup validado ['+$metodo+']: '+$dest)
        Remove-BackupsAntigosNoDiretorio $script:BackupDir $tipoBk

        # Segunda copia opcional, em outro disco/pasta de rede. Parte do backup local JA validado; e
        # conferida por SHA256 e executada com tempo limite (20 s) para nao travar o fechamento.
        $extraMsg=''
        $extraDir=(Get-ConfigValueAllowEmpty 'backup_diretorio_adicional' '').Trim()
        if(-not [string]::IsNullOrWhiteSpace($extraDir)){
            try{
                $localFull=[IO.Path]::GetFullPath($script:BackupDir).TrimEnd('\')
                $extraFull=[IO.Path]::GetFullPath($extraDir).TrimEnd('\')
                if($extraFull -ne $localFull){
                    Initialize-BackupCopier
                    $limiteExtra=$(if($Seguranca){10}else{Get-BackupRetentionLimit})
                    $removidosCsv='';$erroExtra=''
                    $destExtra=[EscalaDCE.BackupCopier]::CopyAndPrune($dest,$extraFull,(Get-BackupNamePattern $tipoBk),[int]$limiteExtra,20000,[ref]$removidosCsv,[ref]$erroExtra)
                    if([string]::IsNullOrWhiteSpace([string]$destExtra)){throw $(if([string]::IsNullOrWhiteSpace($erroExtra)){'Falha desconhecida ao copiar para a pasta adicional.'}else{$erroExtra})}
                    Write-Log ('Backup adicional validado (SHA256): '+$destExtra)
                    foreach($nomeRem in ([string]$removidosCsv -split '\|')){if($nomeRem){Write-Log ('Backup antigo removido na pasta adicional (retencao): '+(Join-Path $extraFull $nomeRem))}}
                    $extraMsg="`r`nCopia adicional: $destExtra"
                }
            }catch{
                Write-Log ('AVISO: backup principal foi criado, mas a copia adicional falhou: '+$_.Exception.Message)
                $extraMsg="`r`n`r`nATENCAO: o backup principal esta valido, mas a copia adicional falhou: $($_.Exception.Message)"
            }
        }
        if(-not $Silencioso){ Show-Info ("Backup criado e validado com sucesso:`r`n"+$dest+$extraMsg) }
        return $dest
    }catch{
        Write-Log ('ERRO no backup: ' + $_.Exception.Message)
        if($Obrigatorio){ throw }
        if(-not $Silencioso){ Show-Error $_.Exception.Message }
        return $null
    }
}


function Show-ResetHistoricoDialog {
    # Zera o HISTORICO de lancamentos (escalas mensais, dia a dia da grade,
    # escala_vagas, ordem de blocos por escala e ocorrencias), preservando o
    # CADASTRO (servidores, setores/sub_setores, horarios, siglas, assinaturas,
    # feriados e configuracoes). Pensado para virar a pagina sem residuo de
    # lancamentos antigos que possam conflitar com lancamentos futuros.
    try {
        $qEscalas=[int](Db-Scalar "SELECT COUNT(*) FROM escalas;")
        $qServEsc=[int](Db-Scalar "SELECT COUNT(*) FROM escala_servidores;")
        $qDias=[int](Db-Scalar "SELECT COUNT(*) FROM escala_dias;")
        $qVagas=[int](Db-Scalar "SELECT COUNT(*) FROM escala_vagas;")
        $qOc=[int](Db-Scalar "SELECT COUNT(*) FROM ocorrencias;")

        $f=New-Object System.Windows.Forms.Form
        Set-FormTheme $f
        $f.Text='Zerar historico de escalas'
        $f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(560,430);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false

        $lTitulo=New-Object System.Windows.Forms.Label
        $lTitulo.Text='ATENCAO: esta acao apaga TODO o historico de lancamentos.'
        $lTitulo.Font=New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
        $lTitulo.ForeColor=[System.Drawing.Color]::FromArgb(185,28,28)
        $lTitulo.Location=New-Object System.Drawing.Point(20,18);$lTitulo.Size=New-Object System.Drawing.Size(520,44)
        $f.Controls.Add($lTitulo)

        $lCorpo=New-Object System.Windows.Forms.Label
        $lCorpo.Text=(
            "Sera apagado (nao pode ser desfeito):`r`n" +
            "  - $qEscalas escala(s) mensal(is) cadastrada(s)`r`n" +
            "  - $qServEsc vinculo(s) de servidor na escala`r`n" +
            "  - $qDias lancamento(s) dia a dia (grade)`r`n" +
            "  - $qVagas escala(s) vaga(s)`r`n" +
            "  - $qOc ocorrencia(s) (ferias, atestados, etc.)`r`n`r`n" +
            "Sera PRESERVADO (cadastro continua intacto):`r`n" +
            "  - Servidores, Setores/Sub_Setores, Horarios, Siglas,`r`n" +
            "    Assinaturas, Feriados e Configuracoes.`r`n`r`n" +
            "Um backup automatico do banco atual sera criado antes de apagar.`r`n`r`n" +
            "Para confirmar, digite ZERAR no campo abaixo:"
        )
        $lCorpo.Location=New-Object System.Drawing.Point(20,66);$lCorpo.Size=New-Object System.Drawing.Size(520,268)
        $f.Controls.Add($lCorpo)

        $tb=New-Object System.Windows.Forms.TextBox
        $tb.Location=New-Object System.Drawing.Point(20,340);$tb.Size=New-Object System.Drawing.Size(200,26)
        $f.Controls.Add($tb)

        $ok=New-Button 'CONFIRMAR E ZERAR' 200;$ok.Location=New-Object System.Drawing.Point(240,338);$ok.Enabled=$false
        $ok.BackColor=[System.Drawing.Color]::FromArgb(220,38,38);$ok.ForeColor=[System.Drawing.Color]::White
        $cancel=New-Button 'CANCELAR' 110;$cancel.Location=New-Object System.Drawing.Point(450,338);$cancel.DialogResult='Cancel'
        $f.Controls.Add($ok);$f.Controls.Add($cancel);$f.CancelButton=$cancel

        $tb.Add_TextChanged({ $ok.Enabled = ($tb.Text.Trim().ToUpperInvariant() -eq 'ZERAR') })
        $ok.Add_Click({
            try {
                Reset-HistoricoEscalas
                $f.DialogResult='OK';$f.Close()
            } catch { Show-Error $_.Exception.Message }
        })

        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch { Show-Error $_.Exception.Message }
}

function Reset-HistoricoEscalas {
    # Backup automatico de seguranca antes de qualquer coisa, independente da
    # configuracao de backup ao sair - esta acao e destrutiva e irreversivel.
    # Se o backup falhar, NAO apaga nada.
    $backupSeguranca = Backup-Database -Silencioso -Obrigatorio -Seguranca
    Write-Log ('Backup de seguranca confirmado antes de zerar historico: ' + $backupSeguranca)
    try {
        # IMPORTANTE: a transacao inteira precisa ser enviada em UMA chamada Db-Exec.
        # Db-Exec abre uma conexao nova a cada chamada; separar BEGIN/DELETE/COMMIT
        # faria os comandos rodarem fora da mesma transacao.
        Db-Exec @"
BEGIN IMMEDIATE;
DELETE FROM escala_dias;
DELETE FROM escala_vagas;
DELETE FROM escala_blocos_ordem;
DELETE FROM escala_servidores;
DELETE FROM escalas;
DELETE FROM ocorrencias;
DELETE FROM sqlite_sequence WHERE name IN ('escalas','escala_servidores','escala_dias','escala_vagas','ocorrencias');
COMMIT;
"@
    } catch {
        Write-Log ('ERRO ao zerar historico de escalas; transacao revertida automaticamente pela conexao SQLite: ' + $_.Exception.Message)
        throw
    }
    try { Db-Exec 'VACUUM;' } catch { Write-Log ('Aviso: VACUUM apos zerar historico falhou: ' + $_.Exception.Message) }
    $script:CurrentScaleId = 0
    Write-Log 'Historico de escalas zerado pelo usuario (cadastro preservado).'
    Load-Escala
    Load-OcorrenciaServidores
    Load-Ocorrencias
    Show-Info 'Historico de escalas zerado com sucesso. O cadastro (servidores, setores, horarios, siglas, assinaturas, feriados e configuracoes) foi preservado.'
}


function Write-ConfigReadErrorOnce {
    param([string]$Chave,[string]$Mensagem,[string]$Padrao)
    $k=('{0}|{1}' -f $Chave,$Mensagem)
    if(-not $script:ConfigReadErrorsLogged.ContainsKey($k)){
        $script:ConfigReadErrorsLogged[$k]=$true
        Write-Log ("ERRO ao ler configuracao '{0}': {1}. Fallback aplicado nesta leitura: '{2}'." -f $Chave,$Mensagem,$Padrao)
    }
}

function Clear-ConfigCache {
    $script:ConfigCache=@{}
    $script:ConfigCacheLoaded=$false
}

function Refresh-ConfigCache {
    try{
        $novo=@{}
        $t=Db-Query "SELECT chave,valor FROM configuracoes;"
        foreach($r in $t.Rows){$novo[[string]$r['chave']]=[string]$r['valor']}
        $script:ConfigCache=$novo
        $script:ConfigCacheLoaded=$true
        return $true
    }catch{
        $script:ConfigCacheLoaded=$false
        Write-Log ('ERRO ao carregar cache de configuracoes: ' + $_.Exception.Message)
        throw
    }
}

function Ensure-ConfigCache {
    if(-not $script:ConfigCacheLoaded){[void](Refresh-ConfigCache)}
}

function Get-ConfigValue {
    param([string]$Chave,[string]$Padrao='')
    try {
        Ensure-ConfigCache
        if(-not $script:ConfigCache.ContainsKey($Chave)){return $Padrao}
        $v=[string]$script:ConfigCache[$Chave]
        if([string]::IsNullOrWhiteSpace($v)){return $Padrao}
        return $v
    } catch {
        Write-ConfigReadErrorOnce $Chave $_.Exception.Message $Padrao
        return $Padrao
    }
}

function Get-ConfigValueAllowEmpty {
    param([string]$Chave,[string]$Padrao='')
    try {
        Ensure-ConfigCache
        if(-not $script:ConfigCache.ContainsKey($Chave)){return $Padrao}
        $v=$script:ConfigCache[$Chave]
        if($null -eq $v -or $v -eq [System.DBNull]::Value){return $Padrao}
        return [string]$v
    } catch {
        Write-ConfigReadErrorOnce $Chave $_.Exception.Message $Padrao
        return $Padrao
    }
}

function Get-ConfigBool {
    param([string]$Chave,[bool]$Padrao=$true)
    $def=$(if($Padrao){'1'}else{'0'})
    return ((Get-ConfigValue $Chave $def) -eq '1')
}

function Set-ConfigValuesBatch {
    param([hashtable]$Valores)
    if($null -eq $Valores -or $Valores.Count -eq 0){return}
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('BEGIN IMMEDIATE;')
    foreach($k in ($Valores.Keys | Sort-Object)){
        [void]$sb.AppendLine(("INSERT INTO configuracoes(chave,valor) VALUES ({0},{1}) ON CONFLICT(chave) DO UPDATE SET valor=excluded.valor;" -f (Sql-Q ([string]$k)),(Sql-Q ([string]$Valores[$k]))))
    }
    [void]$sb.AppendLine('COMMIT;')
    Db-Exec $sb.ToString()
    if(-not $script:ConfigCacheLoaded){
        [void](Refresh-ConfigCache)
    }else{
        foreach($k in $Valores.Keys){$script:ConfigCache[[string]$k]=[string]$Valores[$k]}
    }
}

function Start-ConfigBatch {
    $script:ConfigBatch=@{}
    $script:ConfigBatchActive=$true
}

function Complete-ConfigBatch {
    $vals=$script:ConfigBatch
    $script:ConfigBatchActive=$false
    $script:ConfigBatch=@{}
    Set-ConfigValuesBatch $vals
}

function Cancel-ConfigBatch {
    $script:ConfigBatchActive=$false
    $script:ConfigBatch=@{}
}

function Set-ConfigValue {
    param([string]$Chave,[string]$Valor)
    if($script:ConfigBatchActive){
        $script:ConfigBatch[$Chave]=$Valor
        return
    }
    Set-ConfigValuesBatch @{ $Chave=$Valor }
}

function Get-ConfigInt {
    param([string]$Chave,[int]$Padrao,[int]$Min=-2147483648,[int]$Max=2147483647)
    try{$v=[int](Get-ConfigValue $Chave ([string]$Padrao));if($v -lt $Min){$v=$Min};if($v -gt $Max){$v=$Max};return $v}catch{Write-ConfigReadErrorOnce $Chave $_.Exception.Message ([string]$Padrao);return $Padrao}
}

# V1.0.14.1 - variante decimal de Get-ConfigInt, usada para o tamanho de fonte
# da grade impressa (ex.: 5.7pt), que precisa de casas decimais.
function Get-ConfigDecimal {
    param([string]$Chave,[double]$Padrao,[double]$Min=0,[double]$Max=1000)
    try{
        $texto=(Get-ConfigValue $Chave ([string]$Padrao)).Replace(',','.')
        $v=[double]::Parse($texto,[System.Globalization.CultureInfo]::InvariantCulture)
        if($v -lt $Min){$v=$Min}
        if($v -gt $Max){$v=$Max}
        return $v
    }catch{Write-ConfigReadErrorOnce $Chave $_.Exception.Message ([string]$Padrao);return $Padrao}
}

function Get-AllControlsRecursive {
    param([System.Windows.Forms.Control]$Parent)
    $list=New-Object System.Collections.ArrayList
    foreach($c in $Parent.Controls){
        [void]$list.Add($c)
        if($c.HasChildren){foreach($cc in (Get-AllControlsRecursive $c)){[void]$list.Add($cc)}}
    }
    return $list
}

function Apply-ScaleDayColumnWidth {
    param(
        [System.Windows.Forms.DataGridView]$Grid=$script:gridEscala,
        [int]$Days=0
    )
    if($null -eq $Grid){return}
    if($Days -le 0){
        $Days=@($Grid.Columns | Where-Object {$_.Name -match '^D\d{2}$'}).Count
    }
    if($Days -le 0){return}

    $mode=(Get-ConfigValue 'interface_largura_dias' 'AJUSTAR').ToUpperInvariant()
    $width=54
    if($mode -eq 'COMPACTA'){
        $width=34
    }elseif($mode -eq 'AJUSTAR'){
        # Calcula somente o espaco realmente disponivel para D01..D31.
        # As colunas fixas permanecem intactas; a largura dos dias nunca cai abaixo
        # de 20 px para ainda comportar dia/siglas curtas com a fonte compacta/normal.
        $fixed=0
        foreach($col in $Grid.Columns){
            if($col.Visible -and $col.Name -notmatch '^D\d{2}$'){$fixed += [int]$col.Width}
        }
        $available=[Math]::Max(0,([int]$Grid.ClientSize.Width - $fixed - 22))
        if($available -gt 0){
            $width=[int][Math]::Floor($available / $Days)
            if($width -lt 20){$width=20}
            if($width -gt 54){$width=54}
        }else{$width=20}
    }

    foreach($col in $Grid.Columns){
        if($col.Name -match '^D\d{2}$'){
            $col.AutoSizeMode='None'
            $col.MinimumWidth=18
            $col.Width=$width
            $col.Resizable='True'
            $col.DefaultCellStyle.Padding=New-Object System.Windows.Forms.Padding(0)
        }
    }
}

function Apply-GridPreferences {
    $dens=(Get-ConfigValue 'interface_densidade' 'NORMAL').ToUpperInvariant()
    $font=9.0;$height=30;$blockHeight=27
    if($dens -eq 'COMPACTA'){$font=8.5;$height=24;$blockHeight=23}
    elseif($dens -eq 'CONFORTAVEL'){$font=10.0;$height=36;$blockHeight=33}
    foreach($c in (Get-AllControlsRecursive $script:MainForm)){
        if($c -is [System.Windows.Forms.DataGridView]){
            $c.AllowUserToResizeColumns=$true
            $c.ScrollBars='Both'
            $c.DefaultCellStyle.Font=New-Object System.Drawing.Font('Segoe UI',$font)
            $c.RowTemplate.Height=$height
            if($c -eq $script:gridEscala -or $c.AutoSizeRowsMode -eq 'None'){
                foreach($row in $c.Rows){
                    if($c -eq $script:gridEscala -and $c.Columns.Contains('_TIPO') -and ([string]$row.Cells['_TIPO'].Value) -eq 'BLOCO'){
                        $row.Height=$blockHeight
                        $row.DefaultCellStyle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',$font)
                    }else{
                        $row.Height=$height
                    }
                }
            }
            foreach($col in $c.Columns){if($col.Visible){$col.Resizable='True'}}
        }
    }
    Apply-ScaleDayColumnWidth $script:gridEscala
}




function New-ScaleInfoCard {
    param([string]$Title,[string]$Value,[System.Drawing.Color]$Accent,[int]$Width=210)
    $p=New-Object System.Windows.Forms.Panel
    $p.Width=$Width;$p.Height=68;$p.Margin=New-Object System.Windows.Forms.Padding(6,5,6,5)
    $p.BackColor=[System.Drawing.Color]::White;$p.BorderStyle='FixedSingle'
    $bar=New-Object System.Windows.Forms.Panel;$bar.Dock='Left';$bar.Width=5;$bar.BackColor=$Accent;$p.Controls.Add($bar)
    $lt=New-Object System.Windows.Forms.Label;$lt.Text=$Title;$lt.Location=[Drawing.Point]::new(16,8);$lt.Size=[Drawing.Size]::new($Width-24,20);$lt.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$lt.Font=New-Object Drawing.Font('Segoe UI',8.5);$p.Controls.Add($lt)
    $lv=New-Object System.Windows.Forms.Label;$lv.Text=$Value;$lv.Location=[Drawing.Point]::new(16,29);$lv.Size=[Drawing.Size]::new($Width-24,30);$lv.ForeColor=[Drawing.Color]::FromArgb(15,45,75);$lv.Font=New-Object Drawing.Font('Segoe UI Semibold',15);$p.Controls.Add($lv)
    $p.Tag=$lv
    return $p
}

function Update-ScaleInterfaceInfo {
    if($null -eq $script:gridEscala){return}
    $serv=0;$vagas=0;$preenchidas=0
    foreach($r in $script:gridEscala.Rows){
        if($script:gridEscala.Columns.Contains('_TIPO')){
            $t=[string]$r.Cells['_TIPO'].Value
            if($t -eq 'SERVIDOR'){
                $serv++
                $temDia=$false
                foreach($col in $script:gridEscala.Columns){
                    if($col.Name -match '^D\d{2}$' -and -not [string]::IsNullOrWhiteSpace([string]$r.Cells[$col.Name].Value)){$temDia=$true;break}
                }
                if($temDia){$preenchidas++}
            }elseif($t -eq 'VAGA'){$vagas++}
        }
    }
    $mesTxt='-';$anoTxt='-'
    if($null -ne $script:cboMes -and $null -ne $script:cboMes.SelectedItem){$mesTxt=[string]$script:cboMes.Text}
    if($null -ne $script:numAno){$anoTxt=[string][int]$script:numAno.Value}
    if($null -ne $script:cardServValue){$script:cardServValue.Text=[string]$serv}
    if($null -ne $script:cardEscValue){$script:cardEscValue.Text=[string]$preenchidas}
    if($null -ne $script:cardVagaValue){$script:cardVagaValue.Text=[string]$vagas}
    if($null -ne $script:cardPendValue){$script:cardPendValue.Text=$(if($vagas -gt 0){[string]$vagas}else{'0'})}
    if($null -ne $script:cardMesValue){$script:cardMesValue.Text=($mesTxt + ' / ' + $anoTxt)}
    if($null -ne $script:lblLateralResumo){$script:lblLateralResumo.Text=("Servidores: {0}`r`nVagas: {1}`r`nCompetencia: {2}/{3}" -f $serv,$vagas,$mesTxt,$anoTxt)}
}

function Set-ScaleControlButtonTheme {
    param([System.Windows.Forms.Button]$Button,[System.Drawing.Color]$Back,[System.Drawing.Color]$Fore,[System.Drawing.Color]$Border)
    if($null -eq $Button){return}
    $Button.FlatStyle='Flat';$Button.FlatAppearance.BorderSize=1;$Button.FlatAppearance.BorderColor=$Border
    $Button.BackColor=$Back;$Button.ForeColor=$Fore
}

function Apply-ScaleInterfaceStyle {
    if($null -eq $script:gridEscala -or $null -eq $script:pEscToolbar){return}
    $style=(Get-ConfigValue 'interface_estilo_escala' 'DASHBOARD').ToUpperInvariant()
    if($style -notin @('ORIGINAL','MODERNA','LATERAL','GUIADA','DASHBOARD')){$style='DASHBOARD'}

    # Paineis adicionais sao somente visuais. Os controles operacionais originais permanecem ativos.
    if($null -ne $script:pEscDashboard){$script:pEscDashboard.Visible=($style -eq 'DASHBOARD')}
    if($null -ne $script:pEscLateral){$script:pEscLateral.Visible=($style -eq 'LATERAL')}
    if($null -ne $script:pEscGuided){$script:pEscGuided.Visible=($style -eq 'GUIADA')}

    $navy=[Drawing.Color]::FromArgb(25,58,88)
    $blue=[Drawing.Color]::FromArgb(18,96,173)
    $soft=[Drawing.Color]::FromArgb(246,248,250)
    $white=[Drawing.Color]::White
    $border=[Drawing.Color]::FromArgb(190,205,220)
    $script:pEscToolbar.BackColor=$soft
    $script:gridEscala.BackgroundColor=$white
    $script:gridEscala.EnableHeadersVisualStyles=$false

    # Sempre parte do visual base da V79 para que trocar de estilo nao deixe residuos de cor/borda.
    $baseBack=[Drawing.Color]::FromArgb(248,250,252);$baseFore=[Drawing.Color]::FromArgb(27,50,73);$baseBorder=[Drawing.Color]::FromArgb(181,194,207)
    foreach($bBase in @($btnCar,$btnCriar,$btnBlocos,$btnAssist,$btnOcEsc,$btnOrdenarCargo,$btnPreview,$btnPreviewCombinado,$btnCal,$script:btnMaisOpcoes)){
        Set-ScaleControlButtonTheme $bBase $baseBack $baseFore $baseBorder
    }
    foreach($bPrimary in @($btnCar,$btnAssist,$btnOcEsc,$btnPreview)){Set-PrimaryButton $bPrimary}

    switch($style){
        'ORIGINAL' {
            $script:gridEscala.ColumnHeadersDefaultCellStyle.BackColor=$navy
            $script:gridEscala.ColumnHeadersDefaultCellStyle.ForeColor=$white
            $script:gridEscala.GridColor=[Drawing.Color]::FromArgb(224,228,233)
        }
        'MODERNA' {
            $script:pEscToolbar.BackColor=[Drawing.Color]::FromArgb(248,251,255)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(20,76,126)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.ForeColor=$white
            $script:gridEscala.GridColor=[Drawing.Color]::FromArgb(214,226,238)
            Set-ScaleControlButtonTheme $btnCar $blue $white $blue
            Set-ScaleControlButtonTheme $btnCriar $white $blue $border
            Set-ScaleControlButtonTheme $btnBlocos $white $blue $border
        }
        'LATERAL' {
            $script:pEscToolbar.BackColor=$white
            $script:gridEscala.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(31,78,121)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.ForeColor=$white
            $script:gridEscala.GridColor=[Drawing.Color]::FromArgb(220,226,232)
        }
        'GUIADA' {
            $script:pEscToolbar.BackColor=[Drawing.Color]::FromArgb(250,252,255)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(28,74,112)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.ForeColor=$white
            $script:gridEscala.GridColor=[Drawing.Color]::FromArgb(215,225,235)
        }
        default {
            $script:pEscToolbar.BackColor=[Drawing.Color]::FromArgb(247,250,253)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.BackColor=[Drawing.Color]::FromArgb(20,61,96)
            $script:gridEscala.ColumnHeadersDefaultCellStyle.ForeColor=$white
            $script:gridEscala.GridColor=[Drawing.Color]::FromArgb(211,223,235)
            Set-ScaleControlButtonTheme $btnCar ([Drawing.Color]::FromArgb(14,82,145)) $white ([Drawing.Color]::FromArgb(14,82,145))
        }
    }
    Update-ScaleInterfaceInfo
    Apply-ScaleDayColumnWidth $script:gridEscala
}

function Sync-PreviewLegendaCheckbox {
    # V1.0.14.64 - Faz a caixa "Legenda" da tela Escala refletir o padrao salvo (impressao_legenda).
    if($null -ne $script:chkPreviewLegenda){
        $script:chkPreviewLegenda.Checked=[bool](Get-ConfigBool 'impressao_legenda' $true)
    }
}

function Test-ConfigValueChanged {
    # V1.0.14.63 - Compara valor atual x novo. Se os dois forem numeros, compara como numeros
    # (7 = 7.0 = 7,0); caso contrario, compara o texto exatamente. Evita falsas alteracoes na confirmacao.
    param([AllowNull()][string]$Atual,[AllowNull()][string]$Novo)
    $a=[string]$Atual;$n=[string]$Novo
    if($a -ceq $n){return $false}
    $inv=[System.Globalization.CultureInfo]::InvariantCulture
    $da=[decimal]0;$dn=[decimal]0
    $ta=$a.Trim().Replace(',','.');$tn=$n.Trim().Replace(',','.')
    if($ta -match '^-?\d+(\.\d+)?$' -and $tn -match '^-?\d+(\.\d+)?$'){
        if([decimal]::TryParse($ta,[System.Globalization.NumberStyles]::Number,$inv,[ref]$da) -and [decimal]::TryParse($tn,[System.Globalization.NumberStyles]::Number,$inv,[ref]$dn)){
            return ($da -ne $dn)
        }
    }
    return $true
}

function Get-TextWidthMm {
    # V1.0.14.74 - Estima a largura impressa de um texto (mm) usando a tabela de larguras padrao
    # Helvetica/Arial (AFM, unidades por 1000 em - a Arial do Windows e metricamente compativel com a
    # Helvetica), multiplicada por um fator de familia (Verdana/Tahoma sao mais largas; Calibri/Times New
    # Roman sao mais estreitas) e pelo tamanho de fonte configurado. E uma ESTIMATIVA (nao mede o texto de
    # verdade como o navegador faz), mas reage ao tamanho e a familia da fonte - bem mais fiel do que contar
    # caracteres. Caracteres fora da tabela (digitos, acentos incomuns, etc.) usam uma largura media (556).
    # V1.0.14.75 - CORRIGIDO ERRO DE ABERTURA: a tabela usa Dictionary[string,double] (sensivel a maiusculas),
    # NAO uma hashtable @{} do PowerShell. O @{} do PowerShell compara chaves de texto SEM diferenciar
    # maiuscula/minuscula, entao 'A' e 'a' juntas no mesmo literal @{} sao vistas como a MESMA chave e o
    # PowerShell recusa o script inteiro com "Nao sao permitidas chaves duplicadas" - foi exatamente o erro
    # que apareceu ao abrir o sistema na V1.0.14.74.
    param([string]$Texto,[double]$FontSizePt,[double]$FamiliaFator=1.0)
    if([string]::IsNullOrEmpty($Texto)){return 0.0}
    if($null -eq $script:HelveticaWidthTable){
        $tab=[System.Collections.Generic.Dictionary[string,double]]::new()
        $tab[' ']=278;$tab['!']=278;$tab['"']=355;$tab['#']=556;$tab['$']=556;$tab['%']=889;$tab['&']=667;$tab["'"]=191;$tab['(']=333;$tab[')']=333;$tab['*']=389;$tab['+']=584;$tab[',']=278;$tab['-']=333;$tab['.']=278;$tab['/']=278
        $tab['0']=556;$tab['1']=556;$tab['2']=556;$tab['3']=556;$tab['4']=556;$tab['5']=556;$tab['6']=556;$tab['7']=556;$tab['8']=556;$tab['9']=556;$tab[':']=278;$tab[';']=278;$tab['<']=584;$tab['=']=584;$tab['>']=584;$tab['?']=556;$tab['@']=1015
        $tab['A']=667;$tab['B']=667;$tab['C']=722;$tab['D']=722;$tab['E']=667;$tab['F']=611;$tab['G']=778;$tab['H']=722;$tab['I']=278;$tab['J']=500;$tab['K']=667;$tab['L']=556;$tab['M']=833;$tab['N']=722;$tab['O']=778;$tab['P']=667;$tab['Q']=778;$tab['R']=722;$tab['S']=667;$tab['T']=611;$tab['U']=722;$tab['V']=667;$tab['W']=944;$tab['X']=667;$tab['Y']=667;$tab['Z']=611
        $tab['[']=278;$tab['\']=278;$tab[']']=278;$tab['^']=469;$tab['_']=556;$tab['`']=333
        $tab['a']=556;$tab['b']=556;$tab['c']=500;$tab['d']=556;$tab['e']=556;$tab['f']=278;$tab['g']=556;$tab['h']=556;$tab['i']=222;$tab['j']=222;$tab['k']=500;$tab['l']=222;$tab['m']=833;$tab['n']=556;$tab['o']=556;$tab['p']=556;$tab['q']=556;$tab['r']=333;$tab['s']=500;$tab['t']=278;$tab['u']=556;$tab['v']=500;$tab['w']=722;$tab['x']=500;$tab['y']=500;$tab['z']=500
        $tab['{']=334;$tab['|']=260;$tab['}']=334;$tab['~']=584
        $tab['á']=556;$tab['à']=556;$tab['â']=556;$tab['ã']=556;$tab['ä']=556;$tab['Á']=667;$tab['À']=667;$tab['Â']=667;$tab['Ã']=667;$tab['Ä']=667
        $tab['é']=556;$tab['è']=556;$tab['ê']=556;$tab['ë']=556;$tab['É']=667;$tab['È']=667;$tab['Ê']=667;$tab['Ë']=667
        $tab['í']=222;$tab['ì']=222;$tab['î']=222;$tab['ï']=222;$tab['Í']=278;$tab['Ì']=278;$tab['Î']=278;$tab['Ï']=278
        $tab['ó']=556;$tab['ò']=556;$tab['ô']=556;$tab['õ']=556;$tab['ö']=556;$tab['Ó']=778;$tab['Ò']=778;$tab['Ô']=778;$tab['Õ']=778;$tab['Ö']=778
        $tab['ú']=556;$tab['ù']=556;$tab['û']=556;$tab['ü']=556;$tab['Ú']=722;$tab['Ù']=722;$tab['Û']=722;$tab['Ü']=722
        $tab['ç']=500;$tab['Ç']=722;$tab['ñ']=556;$tab['Ñ']=722
        $script:HelveticaWidthTable=$tab
    }
    $tabela=$script:HelveticaWidthTable
    $totalUnidades=0.0
    foreach($ch in $Texto.ToCharArray()){
        $c=[string]$ch
        $v=[double]0
        if($tabela.TryGetValue($c,[ref]$v)){$totalUnidades+=$v} else {$totalUnidades+=556.0}
    }
    return ($totalUnidades/1000.0) * $FontSizePt * 0.352778 * $FamiliaFator
}


function Get-NomeAbreviadoImpressao {
    # V1.0.14.74 - Abrevia nomes DO MEIO (inicial+ponto) so ate a largura ESTIMADA do texto (Get-TextWidthMm)
    # caber no limite em mm da coluna Nomes, na fonte/familia realmente configuradas. Primeiro nome e ultimo
    # sobrenome NUNCA sao abreviados. Particulas (de/da/do/dos/das/e) nunca viram inicial. Se mesmo abreviando
    # todos os nomes do meio ainda nao couber (nomes com muitas palavras), devolve o resultado mais curto
    # possivel - nunca corta o primeiro nome nem o ultimo sobrenome, e nunca lanca erro.
    param([string]$Nome,[double]$FontSizePt,[double]$FamiliaFator,[double]$LimiteMm)
    $n=([string]$Nome).Trim()
    if($LimiteMm -le 0 -or (Get-TextWidthMm $n $FontSizePt $FamiliaFator) -le $LimiteMm){return $n}
    $partes=@($n -split '\s+' | Where-Object{$_ -ne ''})
    if($partes.Count -le 2){return $n}
    $particulas=@('de','da','do','dos','das','e')
    for($i=1;$i -lt ($partes.Count-1);$i++){
        $p=$partes[$i]
        if([string]::IsNullOrEmpty($p) -or ($particulas -contains $p.ToLowerInvariant())){continue}
        if($p.Length -gt 1 -and $p.Substring($p.Length-1) -eq '.'){continue}
        $partes[$i]=$p.Substring(0,1)+'.'
        if((Get-TextWidthMm ($partes -join ' ') $FontSizePt $FamiliaFator) -le $LimiteMm){return ($partes -join ' ')}
    }
    return ($partes -join ' ')
}


function Get-ConfigFriendlyName {
    param([string]$Chave)
    $map=@{
        'impressao_legenda'='Impressao: mostrar legenda'
        'legenda_todas_siglas'='Legenda: todas as siglas'
        'impressao_assinaturas'='Impressao: mostrar assinaturas'
        'impressao_destacar_fds'='Impressao: destacar finais de semana'
        'impressao_destacar_feriados'='Impressao: destacar feriados'
        'impressao_legenda_fonte_pt'='Legenda: tamanho da fonte'
        'impressao_legenda_sigla_mm'='Legenda: largura da coluna SIGLA'
        'impressao_legenda_ordenar_por'='Legenda: ordem'
        'impressao_legenda_pares'='Legenda: quantidade de pares'
        'impressao_legenda_posicao'='Legenda: posicao'
        'impressao_assinatura_fonte_pt'='Assinaturas: tamanho da fonte'
        'impressao_cabecalho_fonte_pt'='Cabecalho: tamanho da fonte'
        'impressao_fonte_familia'='Grade: tipo de fonte'
        'impressao_grade_fonte_pt'='Grade: tamanho da fonte'
        'impressao_abreviar_nomes'='Nomes: abreviar automaticamente'
        'impressao_margem_pagina_mm'='Impressao: margem de seguranca'
        'impressao_padding_folha_mm'='Impressao: espaco interno'
        'impressao_espaco_entre_setores_mm'='Combinado: espaco entre setores'
        'impressao_titulo_legenda'='Legenda: titulo'
        'impressao_titulo_legenda_visivel'='Legenda: titulo visivel'
        'qtd_modo'='Qtd: regra da contagem'
        'qtd_reiniciar_bloco'='Qtd: reiniciar por bloco'
        'impressao_qtd_destaque_ativo'='Qtd: destaque ativo'
        'impressao_qtd_destaque_grupos'='Qtd: grupos destacados'
        'impressao_qtd_destaque_vaga'='Qtd: destacar Escala Vaga'
        'interface_densidade'='Interface: densidade'
        'interface_largura_dias'='Interface: largura das colunas de datas'
        'interface_estilo_escala'='Interface: estilo da aba Escala'
        'backup_automatico_saida'='Backup: automatico ao sair'
        'backup_max_arquivos'='Backup: quantidade mantida'
    }
    if($map.ContainsKey($Chave)){return [string]$map[$Chave]}
    return ($Chave -replace '_',' ')
}

function Confirm-ConfigBatchChanges {
    try{
        if(-not $script:ConfigBatchActive -or $null -eq $script:ConfigBatch){return $true}

        $mudancas=New-Object System.Collections.ArrayList
        foreach($k in ($script:ConfigBatch.Keys | Sort-Object)){
            $novo=[string]$script:ConfigBatch[$k]
            $atual=Get-ConfigValueAllowEmpty ([string]$k) ''
            if(Test-ConfigValueChanged ([string]$atual) $novo){
                [void]$mudancas.Add([pscustomobject]@{
                    Chave=[string]$k
                    Nome=(Get-ConfigFriendlyName ([string]$k))
                    Atual=[string]$atual
                    Novo=$novo
                })
            }
        }

        if($mudancas.Count -eq 0){
            Set-ConfigStatus 'Nenhuma alteracao para salvar' ([Drawing.Color]::FromArgb(71,85,105))
            return $true
        }

        $linhas=New-Object System.Collections.ArrayList
        $limite=[Math]::Min(14,$mudancas.Count)
        for($i=0;$i -lt $limite;$i++){
            $m=$mudancas[$i]
            $a=$(if([string]::IsNullOrEmpty($m.Atual)){'(vazio)'}else{$m.Atual})
            $n=$(if([string]::IsNullOrEmpty($m.Novo)){'(vazio)'}else{$m.Novo})
            if($a.Length -gt 28){$a=$a.Substring(0,25)+'...'}
            if($n.Length -gt 28){$n=$n.Substring(0,25)+'...'}
            [void]$linhas.Add(("{0}: {1} -> {2}" -f $m.Nome,$a,$n))
        }
        $extra=$(if($mudancas.Count -gt $limite){"`r`n... e mais {0} alteracao(oes)." -f ($mudancas.Count-$limite)}else{''})

        $msg=("CONFIRMAR ALTERACOES DAS CONFIGURACOES`r`n`r`nTotal: {0}`r`n`r`n{1}{2}`r`n`r`nSalvar estas alteracoes?" -f
            $mudancas.Count,(@($linhas)-join "`r`n"),$extra)

        return (Confirm-Action $msg)
    }catch{
        Write-Log ('Falha ao montar auditoria de configuracoes: '+$_.Exception.Message)
        return (Confirm-Action 'Nao foi possivel montar o resumo completo das alteracoes. Deseja salvar mesmo assim?')
    }
}

function Apply-PrintProfileToUI {
    param([string]$Perfil)
    try{
        $p=([string]$Perfil).Trim().ToUpperInvariant()
        if($p -eq 'PERSONALIZADO' -or [string]::IsNullOrWhiteSpace($p)){
            $script:PrintProfileUserPick=$false
            Update-PrintProfileSelection
            Set-ConfigStatus 'Perfil Personalizado: nenhum valor foi alterado' ([Drawing.Color]::FromArgb(71,85,105))
            return
        }

        switch($p){
            'OFICIAL' {
                $script:chkImpLegenda.Checked=$true
                $script:chkImpTodasSiglas.Checked=$true
                $script:chkImpAss.Checked=$true
                $script:chkImpFds.Checked=$true
                $script:chkImpFer.Checked=$true
                $script:numLegendaFonte.Value=6
                $script:numLegendaSiglaMm.Value=7
                $script:numAssinaturaFonte.Value=7
                $script:numCabecalhoFonte.Value=7
                $script:numImpGradeFonte.Value=[decimal]5.7
                $script:numMargemPagina.Value=7
                $script:numPaddingFolha.Value=5
                $script:numEspacoSetores.Value=6
                $script:chkAssLinhasSeparadas.Checked=$true
                $script:cboLegendaOrdem.SelectedIndex=0
                $script:numLegendaPares.Value=2
                $script:cboLegendaPosicao.SelectedIndex=0
                $script:cboAssFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboAssFonteFamilia.Items.IndexOf('Arial'))
                $script:cboCabFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboCabFonteFamilia.Items.IndexOf('Arial'))
                $script:cboImpFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboImpFonteFamilia.Items.IndexOf('Arial'))
            }
            'COMPACTO' {
                $script:chkImpLegenda.Checked=$true
                $script:chkImpTodasSiglas.Checked=$false
                $script:chkImpAss.Checked=$true
                $script:chkImpFds.Checked=$true
                $script:chkImpFer.Checked=$true
                $script:numLegendaFonte.Value=5
                $script:numLegendaSiglaMm.Value=6
                $script:numAssinaturaFonte.Value=6
                $script:numCabecalhoFonte.Value=6
                $script:numImpGradeFonte.Value=[decimal]5.2
                $script:numMargemPagina.Value=7
                $script:numPaddingFolha.Value=2
                $script:numEspacoSetores.Value=3
                $script:chkAssLinhasSeparadas.Checked=$false
                $script:cboLegendaOrdem.SelectedIndex=1
                $script:numLegendaPares.Value=3
                $script:cboLegendaPosicao.SelectedIndex=0
                $script:cboAssFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboAssFonteFamilia.Items.IndexOf('Arial'))
                $script:cboCabFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboCabFonteFamilia.Items.IndexOf('Arial'))
                $script:cboImpFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboImpFonteFamilia.Items.IndexOf('Arial'))
            }
            'CONFERENCIA' {
                $script:chkImpLegenda.Checked=$false
                $script:chkImpTodasSiglas.Checked=$false
                $script:chkImpAss.Checked=$false
                $script:chkImpFds.Checked=$true
                $script:chkImpFer.Checked=$true
                $script:numLegendaFonte.Value=6
                $script:numLegendaSiglaMm.Value=7
                $script:numAssinaturaFonte.Value=7
                $script:numCabecalhoFonte.Value=8
                $script:numImpGradeFonte.Value=[decimal]6.5
                $script:numMargemPagina.Value=7
                $script:numPaddingFolha.Value=4
                $script:numEspacoSetores.Value=4
                $script:chkAssLinhasSeparadas.Checked=$true
                $script:cboLegendaOrdem.SelectedIndex=0
                $script:numLegendaPares.Value=2
                $script:cboLegendaPosicao.SelectedIndex=0
                $script:cboAssFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboAssFonteFamilia.Items.IndexOf('Arial'))
                $script:cboCabFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboCabFonteFamilia.Items.IndexOf('Arial'))
                $script:cboImpFonteFamilia.SelectedIndex=[Math]::Max(0,$script:cboImpFonteFamilia.Items.IndexOf('Arial'))
            }
            default {throw ('Perfil desconhecido: '+$Perfil)}
        }

        $script:PrintProfileUserPick=$false
        Update-PrintProfileSelection
        Set-ConfigStatus ('Perfil aplicado na tela: '+$Perfil+' - clique SALVAR para confirmar') ([Drawing.Color]::FromArgb(31,78,121))
    }catch{
        $script:PrintProfileUserPick=$false
        Show-Error ('Falha ao aplicar perfil de impressao: '+$_.Exception.Message)
    }
}


function Test-PrintProfileMatchesUI {
    param([string]$Perfil)
    $p=([string]$Perfil).Trim().ToUpperInvariant()

    $leg=[bool]$script:chkImpLegenda.Checked
    $todas=[bool]$script:chkImpTodasSiglas.Checked
    $ass=[bool]$script:chkImpAss.Checked
    $fds=[bool]$script:chkImpFds.Checked
    $fer=[bool]$script:chkImpFer.Checked
    $legFonte=[int]$script:numLegendaFonte.Value
    $legSigla=[int]$script:numLegendaSiglaMm.Value
    $assFonte=[int]$script:numAssinaturaFonte.Value
    $cabFonte=[int]$script:numCabecalhoFonte.Value
    $grade=[decimal]$script:numImpGradeFonte.Value
    $marg=[decimal]$script:numMargemPagina.Value
    $pad=[decimal]$script:numPaddingFolha.Value
    $esp=[decimal]$script:numEspacoSetores.Value
    $assSep=[bool]$script:chkAssLinhasSeparadas.Checked
    $ordem=$(if($script:cboLegendaOrdem.SelectedIndex -eq 1){'SIGLA'}else{'DESCRICAO'})
    $pares=[int]$script:numLegendaPares.Value
    $pos=$(if($script:cboLegendaPosicao.SelectedIndex -eq 1){'ESQUERDA'}else{'DIREITA'})

    $af=$(if($script:cboAssFonteFamilia.SelectedItem){[string]$script:cboAssFonteFamilia.SelectedItem}else{''})
    $cf=$(if($script:cboCabFonteFamilia.SelectedItem){[string]$script:cboCabFonteFamilia.SelectedItem}else{''})
    $gf=$(if($script:cboImpFonteFamilia.SelectedItem){[string]$script:cboImpFonteFamilia.SelectedItem}else{''})

    switch($p){
        'OFICIAL' {
            return (
                $leg -and $todas -and $ass -and $fds -and $fer -and
                $legFonte -eq 6 -and $legSigla -eq 7 -and
                $assFonte -eq 7 -and $cabFonte -eq 7 -and
                [Math]::Abs([double]($grade-[decimal]5.7)) -lt 0.001 -and
                [Math]::Abs([double]($marg-[decimal]7)) -lt 0.001 -and
                [Math]::Abs([double]($pad-[decimal]5)) -lt 0.001 -and
                [Math]::Abs([double]($esp-[decimal]6)) -lt 0.001 -and
                $assSep -and $ordem -eq 'DESCRICAO' -and
                $pares -eq 2 -and $pos -eq 'DIREITA' -and
                $af -eq 'Arial' -and $cf -eq 'Arial' -and $gf -eq 'Arial'
            )
        }
        'COMPACTO' {
            return (
                $leg -and (-not $todas) -and $ass -and $fds -and $fer -and
                $legFonte -eq 5 -and $legSigla -eq 6 -and
                $assFonte -eq 6 -and $cabFonte -eq 6 -and
                [Math]::Abs([double]($grade-[decimal]5.2)) -lt 0.001 -and
                [Math]::Abs([double]($marg-[decimal]7)) -lt 0.001 -and
                [Math]::Abs([double]($pad-[decimal]2)) -lt 0.001 -and
                [Math]::Abs([double]($esp-[decimal]3)) -lt 0.001 -and
                (-not $assSep) -and $ordem -eq 'SIGLA' -and
                $pares -eq 3 -and $pos -eq 'DIREITA' -and
                $af -eq 'Arial' -and $cf -eq 'Arial' -and $gf -eq 'Arial'
            )
        }
        'CONFERENCIA' {
            return (
                (-not $leg) -and (-not $todas) -and (-not $ass) -and $fds -and $fer -and
                $legFonte -eq 6 -and $legSigla -eq 7 -and
                $assFonte -eq 7 -and $cabFonte -eq 8 -and
                [Math]::Abs([double]($grade-[decimal]6.5)) -lt 0.001 -and
                [Math]::Abs([double]($marg-[decimal]7)) -lt 0.001 -and
                [Math]::Abs([double]($pad-[decimal]4)) -lt 0.001 -and
                [Math]::Abs([double]($esp-[decimal]4)) -lt 0.001 -and
                $assSep -and $ordem -eq 'DESCRICAO' -and
                $pares -eq 2 -and $pos -eq 'DIREITA' -and
                $af -eq 'Arial' -and $cf -eq 'Arial' -and $gf -eq 'Arial'
            )
        }
    }
    return $false
}

function Get-PrintProfileFromUI {
    foreach($p in @('Oficial','Compacto','Conferencia')){
        if(Test-PrintProfileMatchesUI $p){return $p}
    }
    return 'Personalizado'
}

function Update-PrintProfileSelection {
    # V1.0.14.66 - -FromWatcher: chamada por alteracao de controle; nao sobrescreve a escolha pendente do usuario no combo.
    param([switch]$FromWatcher)
    try{
        if($null -eq $script:cboPerfilImpressao){return}
        if($FromWatcher -and $script:PrintProfileUserPick){return}
        $perfil=Get-PrintProfileFromUI
        $idx=$script:cboPerfilImpressao.Items.IndexOf($perfil)
        if($idx -ge 0 -and $script:cboPerfilImpressao.SelectedIndex -ne $idx){
            $script:cboPerfilImpressao.SelectedIndex=$idx
        }
    }catch{
        Write-Log ('Falha ao detectar perfil de impressao: '+$_.Exception.Message)
    }
}

function Get-PortableConfigKeys {
    # Somente preferencias do usuario. Nao inclui marcadores fix_*, dados,
    # caminhos locais/rede nem qualquer cadastro operacional.
    return @(
        '08h_auto_ff_pf','08h_auto_fs',
        'abrir_mes_atual','ano_padrao','atestado_faixa_dias',
        'backup_automatico_saida','backup_max_arquivos',
        'calendario_destacar_fds','calendario_destacar_feriados',
        'criar_mes_copiar_anterior',
        'impressao_assinatura_fonte_familia','impressao_assinatura_fonte_pt',
        'impressao_assinatura_linhas_separadas','impressao_assinaturas',
        'impressao_cabecalho_fonte_familia','impressao_cabecalho_fonte_pt',
        'impressao_destacar_fds','impressao_destacar_feriados',
        'impressao_espaco_entre_setores_mm','impressao_fonte_familia',
        'impressao_grade_fonte_pt','impressao_abreviar_nomes',
        'impressao_inst_linha1','impressao_inst_linha2',
        'impressao_inst_linha3','impressao_inst_linha4',
        'impressao_legenda','impressao_legenda_fonte_pt',
        'impressao_legenda_ordenar_por','impressao_legenda_pares',
        'impressao_legenda_posicao','impressao_legenda_sigla_mm',
        'impressao_margem_pagina_mm','impressao_padding_folha_mm',
        'impressao_qtd_destaque_ativo','impressao_qtd_destaque_funcoes',
        'impressao_qtd_destaque_fonte','impressao_qtd_destaque_fundo',
        'impressao_qtd_destaque_grupos','impressao_qtd_destaque_vaga',
        'impressao_texto_chefia_padrao','impressao_titulo_assinaturas',
        'impressao_titulo_legenda','impressao_titulo_legenda_visivel',
        'interface_densidade','interface_largura_dias','interface_estilo_escala','interface_tab_horarios',
        'interface_tab_ocorrencias','interface_tab_readaptados',
        'interface_tab_servidores','interface_tab_setores','interface_tab_siglas',
        'legenda_todas_siglas','mascara_dn_paridade','mascara_mv_fds_paridade',
        'menu_siglas_rapidas','mes_padrao','mv_pt_automatico','ordem_cargos',
        'qtd_modo','qtd_reiniciar_bloco',
        'texto_faixa_atestado','texto_faixa_ferias'
    )
}

function Export-ConfiguracoesJson {
    try{
        $dlg=New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Title='Exportar configuracoes do Sistema de Escala'
        $dlg.Filter='Arquivo de configuracoes (*.json)|*.json'
        $dlg.FileName=('Configuracoes_Escala_DCE_{0:yyyyMMdd_HHmm}.json' -f (Get-Date))
        $dlg.OverwritePrompt=$true

        if($dlg.ShowDialog($script:MainForm) -ne [System.Windows.Forms.DialogResult]::OK){
            $dlg.Dispose()
            return
        }
        $dest=$dlg.FileName
        $dlg.Dispose()

        $permitidas=@(Get-PortableConfigKeys)
        $permitidasSet=@{}
        foreach($k in $permitidas){$permitidasSet[$k]=$true}

        $settings=[ordered]@{}
        $tb=Db-Query "SELECT chave,valor FROM configuracoes ORDER BY chave;"
        foreach($r in $tb.Rows){
            $k=[string]$r['chave']
            if($permitidasSet.ContainsKey($k)){
                $settings[$k]=[string]$r['valor']
            }
        }

        $obj=[ordered]@{
            formato='SistemaEscalaDCE-Configuracoes'
            versao_formato=1
            sistema='Sistema de Escala DCE'
            versao_origem='V1.0.14.83-G1'
            exportado_em=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            observacao='Somente preferencias. Nao contem banco, servidores, escalas, ocorrencias, assinaturas, logos ou caminho adicional de backup.'
            configuracoes=$settings
        }

        $json=$obj | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($dest,$json,(New-Object System.Text.UTF8Encoding($true)))

        Set-ConfigStatus 'Configuracoes exportadas' ([Drawing.Color]::FromArgb(22,101,52))
        Show-Info ("Configuracoes exportadas com sucesso.`r`n`r`nArquivo:`r`n{0}`r`n`r`nO arquivo NAO contem o banco nem cadastros." -f $dest)
    }catch{
        Show-Error ('Falha ao exportar configuracoes: '+$_.Exception.Message)
    }
}

function Import-ConfiguracoesJson {
    try{
        $dlg=New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title='Importar configuracoes do Sistema de Escala'
        $dlg.Filter='Arquivo de configuracoes (*.json)|*.json'
        $dlg.Multiselect=$false
        if($dlg.ShowDialog($script:MainForm) -ne [System.Windows.Forms.DialogResult]::OK){
            $dlg.Dispose()
            return
        }
        $src=$dlg.FileName
        $dlg.Dispose()

        $json=[System.IO.File]::ReadAllText($src,[System.Text.Encoding]::UTF8)
        $obj=$json | ConvertFrom-Json

        if($null -eq $obj -or [string]$obj.formato -ne 'SistemaEscalaDCE-Configuracoes'){
            throw 'O arquivo nao e um perfil de configuracoes valido do Sistema de Escala DCE.'
        }
        if($null -eq $obj.configuracoes){
            throw 'O arquivo nao possui o bloco de configuracoes.'
        }

        $permitidas=@(Get-PortableConfigKeys)
        $permitidasSet=@{}
        foreach($k in $permitidas){$permitidasSet[$k]=$true}

        $novos=@{}
        foreach($prop in $obj.configuracoes.PSObject.Properties){
            $k=[string]$prop.Name
            if($permitidasSet.ContainsKey($k)){
                $novos[$k]=[string]$prop.Value
            }
        }
        if($novos.Count -eq 0){
            throw 'Nenhuma configuracao compativel foi encontrada no arquivo.'
        }

        $alteracoes=New-Object System.Collections.ArrayList
        foreach($k in ($novos.Keys | Sort-Object)){
            $atual=Get-ConfigValueAllowEmpty $k ''
            $novo=[string]$novos[$k]
            if(Test-ConfigValueChanged ([string]$atual) $novo){
                [void]$alteracoes.Add([pscustomobject]@{Chave=$k;Atual=[string]$atual;Novo=$novo})
            }
        }

        if($alteracoes.Count -eq 0){
            Show-Info 'O perfil importado possui os mesmos valores que ja estao configurados. Nenhuma alteracao foi necessaria.'
            return
        }

        $linhas=New-Object System.Collections.ArrayList
        $limite=[Math]::Min(12,$alteracoes.Count)
        for($i=0;$i -lt $limite;$i++){
            $a=$alteracoes[$i]
            $ant=$(if([string]::IsNullOrEmpty($a.Atual)){'(vazio)'}else{$a.Atual})
            $nv=$(if([string]::IsNullOrEmpty($a.Novo)){'(vazio)'}else{$a.Novo})
            if($ant.Length -gt 35){$ant=$ant.Substring(0,32)+'...'}
            if($nv.Length -gt 35){$nv=$nv.Substring(0,32)+'...'}
            [void]$linhas.Add(("{0}: {1} -> {2}" -f $a.Chave,$ant,$nv))
        }
        $extra=$(if($alteracoes.Count -gt $limite){"`r`n... e mais {0} alteracao(oes)." -f ($alteracoes.Count-$limite)}else{''})
        $msg=("Importar este perfil?`r`n`r`nArquivo: {0}`r`nOrigem: {1}`r`nAlteracoes: {2}`r`n`r`n{3}{4}`r`n`r`nAntes de aplicar sera criado um backup obrigatorio do banco." -f
            $src,[string]$obj.versao_origem,$alteracoes.Count,(@($linhas)-join "`r`n"),$extra)
        if(-not(Confirm-Action $msg)){return}

        $backup=Backup-Database -Silencioso -Obrigatorio
        if([string]::IsNullOrWhiteSpace([string]$backup)){
            throw 'O backup obrigatorio nao foi criado. A importacao foi cancelada.'
        }

        Set-ConfigValuesBatch $novos
        Clear-ConfigCache
        Load-ConfiguracoesUI
        Apply-MainTabVisibility
        Apply-GridPreferences
        Apply-ScaleInterfaceStyle
        Load-Escala

        Set-ConfigStatus ('Perfil importado: {0} alteracao(oes)' -f $alteracoes.Count) ([Drawing.Color]::FromArgb(22,101,52))

        Show-Info ("Perfil importado com sucesso.`r`n`r`nAlteracoes aplicadas: {0}`r`nBackup criado antes da importacao:`r`n{1}" -f $alteracoes.Count,$backup)
    }catch{
        Show-Error ('Falha ao importar configuracoes: '+$_.Exception.Message)
    }
}


function Set-ConfigStatus {
    param(
        [AllowNull()][string]$Texto,
        [System.Drawing.Color]$Cor = [System.Drawing.Color]::FromArgb(71,85,105)
    )
    if($null -ne $script:lblConfigStatus){
        $script:lblConfigStatus.Text=[string]$Texto
        $script:lblConfigStatus.ForeColor=$Cor
    }
    if($null -ne $script:LayoutConfigToolbar){
        & $script:LayoutConfigToolbar
    }
}

function Find-ConfigOption {
    param([AllowNull()][string]$Termo)
    try{
        if($null -eq $script:cfgTabs){return}

        $q=ConvertTo-SearchKey ([string]$Termo)
        if([string]::IsNullOrWhiteSpace($q)){
            Set-ConfigStatus 'Central de configuracoes' ([Drawing.Color]::FromArgb(71,85,105))
            return
        }

        $tokens=@($q -split '\s+' | Where-Object {$_})
        $achados=New-Object System.Collections.ArrayList

        foreach($tab in $script:cfgTabs.TabPages){
            $controles=@(Get-AllControlsRecursive $tab)
            $partes=New-Object System.Collections.ArrayList
            [void]$partes.Add((ConvertTo-SearchKey ([string]$tab.Text)))

            foreach($c in $controles){
                if($c.PSObject.Properties.Name -contains 'Text'){
                    $t=ConvertTo-SearchKey ([string]$c.Text)
                    if($t){[void]$partes.Add($t)}
                }
            }

            $hay=(@($partes) -join ' ')
            $ok=$true
            foreach($tok in $tokens){
                if(-not $hay.Contains($tok)){$ok=$false;break}
            }

            if($ok){
                $controleAlvo=$null
                foreach($c in $controles){
                    $ct=ConvertTo-SearchKey ([string]$c.Text)
                    if($ct -and $ct.Contains($q)){$controleAlvo=$c;break}
                }
                [void]$achados.Add([pscustomobject]@{Tab=$tab;Controle=$controleAlvo})
            }
        }

        if($achados.Count -eq 0){
            Set-ConfigStatus ('Nao encontrado: '+$Termo) ([Drawing.Color]::FromArgb(185,28,28))
            return
        }

        $primeiro=$achados[0]
        $script:cfgTabs.SelectedTab=$primeiro.Tab
        if($null -ne $primeiro.Controle){
            $primeiro.Tab.ScrollControlIntoView($primeiro.Controle)
        }

        Set-ConfigStatus (
            "Encontrado em '{0}'{1}" -f
            [string]$primeiro.Tab.Text,
            $(if($achados.Count -gt 1){" (+{0} aba(s))" -f ($achados.Count-1)}else{''})
        ) ([Drawing.Color]::FromArgb(31,78,121))
    }catch{
        Write-Log ('Falha na busca de Configuracoes: '+$_.Exception.Message)
    }
}

function Restore-ConfigCurrentSection {
    try{
        if($null -eq $script:cfgTabs -or $null -eq $script:cfgTabs.SelectedTab){return}
        $sec=[string]$script:cfgTabs.SelectedTab.Text
        if(-not(Confirm-Action ("Restaurar somente a aba '{0}' para o padrao?`r`n`r`nAs outras configuracoes nao serao alteradas." -f $sec))){return}
        $d=@{}
        switch($sec){
            'Geral / Interface' {
                $d=@{'abrir_mes_atual'='1';'mes_padrao'=([string](Get-Date).Month);'ano_padrao'=([string](Get-Date).Year);'criar_mes_copiar_anterior'='PERGUNTAR';'interface_densidade'='NORMAL';'interface_largura_dias'='AJUSTAR';'interface_estilo_escala'='DASHBOARD';'interface_tab_servidores'='1';'interface_tab_readaptados'='0';'interface_tab_ocorrencias'='1';'interface_tab_setores'='1';'interface_tab_horarios'='1';'interface_tab_siglas'='1'}
            }
            'Qtd / Contagem' {
                $d=@{'qtd_modo'='ENF_TEAE';'qtd_reiniciar_bloco'='1';'ordem_cargos'='ENF,TE,AE';'impressao_qtd_destaque_ativo'='1';'impressao_qtd_destaque_funcoes'='ENF';'impressao_qtd_destaque_grupos'='ENF';'impressao_qtd_destaque_vaga'='1';'impressao_qtd_destaque_fundo'='#D9D9D9';'impressao_qtd_destaque_fonte'='#000000'}
            }
            'Blocos / Paridade' {$d=@{'mascara_dn_paridade'='1';'mascara_mv_fds_paridade'='1';'mv_pt_automatico'='1'}}
            'Backup / Segurança' {$d=@{'backup_automatico_saida'='1';'backup_max_arquivos'='15';'backup_diretorio_adicional'=''}}
            'Siglas rápidas' {$d=@{'menu_siglas_rapidas'='FC,FF,PT,C1,C2,C3,FS,PF'}}
            'Calendário / 08h' {$d=@{'calendario_destacar_fds'='1';'calendario_destacar_feriados'='1';'08h_auto_ff_pf'='1';'08h_auto_fs'='1'}}
            'Impressão' {
                $d=@{
                    'impressao_legenda'='1'
                    'legenda_todas_siglas'='1'
                    'impressao_assinaturas'='1'
                    'impressao_destacar_fds'='1'
                    'impressao_destacar_feriados'='1'
                    'impressao_legenda_fonte_pt'='6'
                    'impressao_legenda_sigla_mm'='7'
                    'impressao_assinatura_fonte_pt'='7'
                    'impressao_assinatura_fonte_familia'='Arial'
                    'impressao_cabecalho_fonte_pt'='7'
                    'impressao_cabecalho_fonte_familia'='Arial'
                    'impressao_inst_linha1'='GOVERNO DO ESTADO DE MATO GROSSO DO SUL'
                    'impressao_inst_linha2'='SECRETARIA DE ESTADO DE SAUDE'
                    'impressao_inst_linha3'='FUNDACAO SERVICOS DE SAUDE DE MS'
                    'impressao_inst_linha4'='HOSPITAL REGIONAL DE MATO GROSSO DO SUL'
                    'impressao_titulo_assinaturas'=''
                    'impressao_titulo_legenda'='LEGENDA DAS SIGLAS'
                    'impressao_titulo_legenda_visivel'='1'
                    'impressao_texto_chefia_padrao'='CHEFIA DO SETOR'
                    'impressao_margem_pagina_mm'='7'
                    'impressao_padding_folha_mm'='5'
                    'impressao_espaco_entre_setores_mm'='6'
                    'impressao_assinatura_linhas_separadas'='1'
                    'impressao_legenda_ordenar_por'='DESCRICAO'
                    'impressao_legenda_pares'='2'
                    'impressao_legenda_posicao'='DIREITA'
                    'impressao_fonte_familia'='Arial'
                    'impressao_grade_fonte_pt'='5.7'
                    'impressao_abreviar_nomes'='1'
                }
            }
            'Ocorrências' {Show-Info 'Esta aba contem cadastros de Tipos de Ocorrencia. Para evitar apagar ou alterar cadastros, o restaurador por aba nao mexe nesses registros.';return}
            'Assinaturas' {Show-Info 'Esta aba contem cadastros de Assinaturas. Para evitar apagar ou alterar cadastros, o restaurador por aba nao mexe nesses registros.';return}
            default {Show-Info 'Nao ha padrao automatico definido para esta aba.';return}
        }
        Set-ConfigValuesBatch $d
        Load-ConfiguracoesUI;Apply-MainTabVisibility;Apply-GridPreferences;Apply-ScaleInterfaceStyle;Load-Escala
        Set-ConfigStatus ('Aba restaurada: '+$sec) ([Drawing.Color]::FromArgb(22,101,52))
        Show-Info ("Aba '{0}' restaurada para o padrao.`r`nAs demais configuracoes foram preservadas." -f $sec)
    }catch{Show-Error $_.Exception.Message}
}

function Restore-ConfigDefaults {
    if(-not(Confirm-Action 'Restaurar as configuracoes gerais para o padrao do sistema? Cadastros de servidores, setores, horarios, siglas e ocorrencias nao serao alterados.')){return}
    try{
        $defaults=@{
            'qtd_modo'='ENF_TEAE';'qtd_reiniciar_bloco'='1';'impressao_qtd_destaque_ativo'='1';'impressao_qtd_destaque_funcoes'='ENF';'impressao_qtd_destaque_grupos'='ENF';'impressao_qtd_destaque_vaga'='1';'impressao_qtd_destaque_fundo'='#D9D9D9';'impressao_qtd_destaque_fonte'='#000000';'calendario_destacar_fds'='1';'calendario_destacar_feriados'='1';
            'impressao_legenda'='1';'legenda_todas_siglas'='1';'impressao_assinaturas'='1';'impressao_destacar_fds'='1';'impressao_destacar_feriados'='1';
            'mascara_dn_paridade'='1';'mascara_mv_fds_paridade'='1';'mv_pt_automatico'='1';'08h_auto_ff_pf'='1';'08h_auto_fs'='1';
            'menu_siglas_rapidas'='FC,FF,PT,C1,C2,C3,FS,PF';'abrir_mes_atual'='1';'mes_padrao'=([string](Get-Date).Month);'ano_padrao'=([string](Get-Date).Year);
            'criar_mes_copiar_anterior'='PERGUNTAR';'interface_densidade'='NORMAL';'interface_largura_dias'='AJUSTAR';'interface_estilo_escala'='DASHBOARD';'atestado_faixa_dias'='4';'texto_faixa_ferias'='FÉRIAS';'texto_faixa_atestado'='ATESTADO';
            'interface_tab_servidores'='1';'interface_tab_readaptados'='0';'interface_tab_ocorrencias'='1';'interface_tab_setores'='1';'interface_tab_horarios'='1';'interface_tab_siglas'='1';
            'backup_automatico_saida'='1';'backup_max_arquivos'='15';'backup_diretorio_adicional'='';
            'impressao_legenda_fonte_pt'='6';'impressao_legenda_sigla_mm'='7';'impressao_legenda_pares'='2';'impressao_legenda_posicao'='DIREITA';'impressao_assinatura_fonte_pt'='7';
            'impressao_abreviar_nomes'='1';
            'impressao_inst_linha1'='GOVERNO DO ESTADO DE MATO GROSSO DO SUL';
            'impressao_inst_linha2'='SECRETARIA DE ESTADO DE SAUDE';
            'impressao_inst_linha3'='FUNDACAO SERVICOS DE SAUDE DE MS';
            'impressao_inst_linha4'='HOSPITAL REGIONAL DE MATO GROSSO DO SUL'
        }
        Set-ConfigValuesBatch $defaults
        Load-ConfiguracoesUI;Apply-GridPreferences;Apply-ScaleInterfaceStyle;Load-Escala
        Show-Info 'Configuracoes restauradas para o padrao.'
    }catch{Show-Error $_.Exception.Message}
}

function Get-QtdGrupoByMode {
    param([string]$Funcao,[string]$Modo='ENF_TEAE')
    if(([string]$Modo).ToUpperInvariant() -eq 'SEQUENCIAL'){return 'SEQ'}
    $f=([string]$Funcao).Trim().ToUpperInvariant()
    $f=$f.Replace('.','').Replace('-','').Replace('/','').Replace(' ','')
    # Auxiliar deve ser testado antes de ENF, pois AUXILIAR DE ENFERMAGEM contem ENF.
    if($f -match 'AUX' -or $f -match '^AE'){return 'TEAE'}
    if($f -match 'TEC' -or $f -match '^TE'){return 'TEAE'}
    if($f -match 'ENFERMEIR' -or $f -match '^ENF'){return 'ENF'}
    return 'OUTROS'
}

function Get-QtdGrupo {
    param([string]$Funcao)
    $modo=Get-ConfigValue 'qtd_modo' 'ENF_TEAE'
    return (Get-QtdGrupoByMode $Funcao $modo)
}

function Load-Assinaturas {
    try {
        if($null -eq $script:gridAssinaturas){return}
        $t=Db-Query "SELECT a.id,CASE WHEN a.setor_id IS NULL THEN 'GERAL' ELSE COALESCE(s.nome,'SETOR') END AS Setor,a.nome AS Nome,COALESCE(a.cargo,'') AS Cargo,COALESCE(a.coren,'') AS Coren,COALESCE(a.cabecalho_titulo,'') AS Cabecalho,a.ordem AS Ordem,a.espaco_acima AS Espaco,CASE WHEN a.ativo=1 THEN 'SIM' ELSE 'NAO' END AS Ativo FROM assinaturas a LEFT JOIN setores s ON s.id=a.setor_id ORDER BY CASE WHEN a.setor_id IS NULL THEN 0 ELSE 1 END,COALESCE(s.nome,''),a.ordem,a.nome;"
        $script:gridAssinaturas.DataSource=$t
        if($script:gridAssinaturas.Columns.Contains('id')){$script:gridAssinaturas.Columns['id'].Visible=$false}
        if($script:gridAssinaturas.Columns.Contains('Nome')){$script:gridAssinaturas.Columns['Nome'].AutoSizeMode='Fill'}
        if($script:gridAssinaturas.Columns.Contains('Cargo')){$script:gridAssinaturas.Columns['Cargo'].Width=220}
        if($script:gridAssinaturas.Columns.Contains('Setor')){$script:gridAssinaturas.Columns['Setor'].Width=170}
        if($script:gridAssinaturas.Columns.Contains('Coren')){$script:gridAssinaturas.Columns['Coren'].Width=120}
        if($script:gridAssinaturas.Columns.Contains('Cabecalho')){$script:gridAssinaturas.Columns['Cabecalho'].HeaderText='Titulo cabecalho';$script:gridAssinaturas.Columns['Cabecalho'].Width=180}
    } catch { Show-Error $_.Exception.Message }
}

function Show-AssinaturaDialog {
    param([int]$Id=0)
    try {
        $data=$null
        if($Id -gt 0){$q=Db-Query "SELECT * FROM assinaturas WHERE id=$Id;";if($q.Rows.Count){$data=$q.Rows[0]}}
        $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=$(if($Id){'Editar assinatura'}else{'Nova assinatura'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(650,650);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false;$f.MinimizeBox=$false;$f.AutoScaleMode='Dpi';$f.BackColor=[System.Drawing.Color]::White;$f.Font=New-Object System.Drawing.Font('Segoe UI',9)
        $sets=Db-Query "SELECT 0 AS id,'GERAL - TODOS OS SETORES' AS nome UNION ALL SELECT id,nome FROM setores WHERE ativo=1 ORDER BY nome;"
        $labels=@('Abrangencia','Nome','Cargo / Funcao','Coren','4a linha (opcional)','Ordem','Espaco acima')
        $y=28
        $l=New-Object System.Windows.Forms.Label;$l.Text='Abrangencia';$l.Location=New-Object System.Drawing.Point(28,$y);$l.Size=New-Object System.Drawing.Size(120,24);$f.Controls.Add($l)
        $cb=New-Object System.Windows.Forms.ComboBox;$cb.Location=New-Object System.Drawing.Point(160,$y);$cb.Size=New-Object System.Drawing.Size(430,27);$cb.DropDownStyle='DropDownList';$bsTmp8=New-Object System.Windows.Forms.BindingSource;$bsTmp8.DataSource=$sets;$cb.DataSource=$bsTmp8;$cb.ValueMember='id';$cb.DisplayMember='nome';$f.Controls.Add($cb);$y+=52
        $boxes=@{}
        foreach($item in @('Nome','Cargo / Funcao','Coren','4a linha (opcional)','Titulo no cabecalho (opcional)')){
            $l=New-Object System.Windows.Forms.Label;$l.Text=$(if($item -eq 'Titulo no cabecalho (opcional)'){'Titulo cabecalho'}else{$item});$l.Location=New-Object System.Drawing.Point(28,$y);$l.Size=New-Object System.Drawing.Size(120,24);$f.Controls.Add($l)
            $tb=New-Object System.Windows.Forms.TextBox;$tb.Location=New-Object System.Drawing.Point(160,$y);$tb.Size=New-Object System.Drawing.Size(430,27);$f.Controls.Add($tb);$boxes[$item]=$tb;$y+=48
        }
        $tip4aLinha=New-Object System.Windows.Forms.ToolTip;$tip4aLinha.SetToolTip($boxes['4a linha (opcional)'],'Qualquer outro registro que queira mostrar (CRM, RG, matricula, etc.). Fica numa linha extra, abaixo do Coren.')
        $tipCabAss=New-Object System.Windows.Forms.ToolTip;$tipCabAss.SetToolTip($boxes['Titulo no cabecalho (opcional)'],'Texto mostrado antes do nome no cabecalho da escala. Exemplos: GERENTE TECNICA, DIRETORA DE ENFERMAGEM, COORDENADORA. Se ficar vazio, o sistema mantem o cabecalho atual do setor.')
        $l=New-Object System.Windows.Forms.Label;$l.Text='Ordem';$l.Location=New-Object System.Drawing.Point(28,$y);$l.Size=New-Object System.Drawing.Size(120,24);$f.Controls.Add($l)
        $numOrd=New-Object System.Windows.Forms.NumericUpDown;$numOrd.Location=New-Object System.Drawing.Point(160,$y);$numOrd.Size=New-Object System.Drawing.Size(100,27);$numOrd.Minimum=0;$numOrd.Maximum=999;$f.Controls.Add($numOrd)
        $l2=New-Object System.Windows.Forms.Label;$l2.Text='Espaco acima';$l2.Location=New-Object System.Drawing.Point(300,$y);$l2.Size=New-Object System.Drawing.Size(110,24);$f.Controls.Add($l2)
        $numEsp=New-Object System.Windows.Forms.NumericUpDown;$numEsp.Location=New-Object System.Drawing.Point(410,$y);$numEsp.Size=New-Object System.Drawing.Size(90,27);$numEsp.Minimum=0;$numEsp.Maximum=20;$numEsp.Value=2;$f.Controls.Add($numEsp);$y+=50
        $chk=New-Object System.Windows.Forms.CheckBox;$chk.Text='Ativa';$chk.Location=New-Object System.Drawing.Point(160,$y);$chk.Size=New-Object System.Drawing.Size(120,28);$chk.Checked=$true;$f.Controls.Add($chk);$y+=44

        $grpPrev=New-Object System.Windows.Forms.GroupBox;$grpPrev.Text='Previa (mesmo formato usado em PRE-VISUALIZAR e PRE-VISUALIZAR COMBINADO)';$grpPrev.Location=New-Object System.Drawing.Point(28,$y);$grpPrev.Size=New-Object System.Drawing.Size(578,120);$f.Controls.Add($grpPrev)
        $lnhaPrev=New-Object System.Windows.Forms.Panel;$lnhaPrev.Location=New-Object System.Drawing.Point(139,28);$lnhaPrev.Size=New-Object System.Drawing.Size(300,1);$lnhaPrev.BackColor=[System.Drawing.Color]::FromArgb(17,17,17);$grpPrev.Controls.Add($lnhaPrev)
        $lblPrevNome=New-Object System.Windows.Forms.Label;$lblPrevNome.Text='(nome)';$lblPrevNome.TextAlign='TopCenter';$lblPrevNome.Location=New-Object System.Drawing.Point(139,32);$lblPrevNome.Size=New-Object System.Drawing.Size(300,22);$grpPrev.Controls.Add($lblPrevNome)
        $lblPrevResto=New-Object System.Windows.Forms.Label;$lblPrevResto.Text='';$lblPrevResto.TextAlign='TopCenter';$lblPrevResto.Location=New-Object System.Drawing.Point(139,56);$lblPrevResto.Size=New-Object System.Drawing.Size(300,60);$grpPrev.Controls.Add($lblPrevResto)
        $atualizarPreview={
            $nomeTxt=$(if($boxes['Nome'].Text.Trim()){$boxes['Nome'].Text.Trim()}else{'(nome)'})
            $lblPrevNome.Text=$nomeTxt
            $cargoTxt=$boxes['Cargo / Funcao'].Text.Trim()
            $corenTxt=$boxes['Coren'].Text.Trim();if($corenTxt){$corenTxt=Format-CorenText $corenTxt}
            $extraTxt=$boxes['4a linha (opcional)'].Text.Trim()
            $separadas=Get-ConfigBool 'impressao_assinatura_linhas_separadas' $true
            if($separadas){
                $linhas=@($cargoTxt,$corenTxt,$extraTxt) | Where-Object {$_}
                $lblPrevResto.Text=($linhas -join "`r`n")
            } else {
                $det=$cargoTxt
                if($corenTxt){if($det){$det+=' - '};$det+=$corenTxt}
                if($extraTxt){if($det){$det+=' - '};$det+=$extraTxt}
                $lblPrevResto.Text=$det
            }
        }
        foreach($campo in @('Nome','Cargo / Funcao','Coren','4a linha (opcional)')){$boxes[$campo].Add_TextChanged($atualizarPreview)}
        $y+=132
        if($data){
            $sid=0;if($data['setor_id'] -ne [DBNull]::Value){$sid=[int]$data['setor_id']};$cb.SelectedValue=$sid
            $boxes['Nome'].Text=[string]$data['nome'];$boxes['Cargo / Funcao'].Text=[string]$data['cargo'];$boxes['Coren'].Text=[string]$data['coren'];$boxes['4a linha (opcional)'].Text=[string]$data['registro_extra'];$boxes['Titulo no cabecalho (opcional)'].Text=[string]$data['cabecalho_titulo'];$numOrd.Value=[decimal][int]$data['ordem'];$numEsp.Value=[decimal][int]$data['espaco_acima'];$chk.Checked=([int]$data['ativo'] -eq 1)
        }else{$next=Db-Scalar 'SELECT COALESCE(MAX(ordem),0)+1 FROM assinaturas;';if($next){$numOrd.Value=[decimal][int]$next}}
        & $atualizarPreview
        $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(340,$y);$ok.Add_Click({
            try{
                $nome=$boxes['Nome'].Text.Trim();if(-not $nome){Show-Info 'Informe o nome da assinatura.';return}
                $sid=[int]$cb.SelectedValue;$sidSql=$(if($sid -le 0){'NULL'}else{[string]$sid});$ativo=$(if($chk.Checked){1}else{0})
                if($Id){Db-Exec ("UPDATE assinaturas SET setor_id={0},nome={1},cargo={2},coren={3},registro_extra={4},cabecalho_titulo={5},lado='AUTO',ordem={6},espaco_acima={7},ativo={8} WHERE id={9};" -f $sidSql,(Sql-Q $nome),(Sql-Q $boxes['Cargo / Funcao'].Text.Trim()),(Sql-Q $boxes['Coren'].Text.Trim()),(Sql-Q $boxes['4a linha (opcional)'].Text.Trim()),(Sql-Q $boxes['Titulo no cabecalho (opcional)'].Text.Trim()),[int]$numOrd.Value,[int]$numEsp.Value,$ativo,$Id)}
                else{Db-Exec ("INSERT INTO assinaturas(setor_id,nome,cargo,coren,registro_extra,cabecalho_titulo,lado,ordem,espaco_acima,ativo) VALUES ({0},{1},{2},{3},{4},{5},'AUTO',{6},{7},{8});" -f $sidSql,(Sql-Q $nome),(Sql-Q $boxes['Cargo / Funcao'].Text.Trim()),(Sql-Q $boxes['Coren'].Text.Trim()),(Sql-Q $boxes['4a linha (opcional)'].Text.Trim()),(Sql-Q $boxes['Titulo no cabecalho (opcional)'].Text.Trim()),[int]$numOrd.Value,[int]$numEsp.Value,$ativo)}
                Load-Assinaturas;$f.DialogResult='OK';$f.Close()
            }catch{Show-Error $_.Exception.Message}
        });$f.Controls.Add($ok)
        $cancel=New-Button 'CANCELAR' 120;$cancel.Location=New-Object System.Drawing.Point(470,$y);$cancel.Add_Click({$f.Close()});$f.Controls.Add($cancel)
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch { Show-Error $_.Exception.Message }
}

function Toggle-AssinaturaAtiva {
    try{$id=Get-GridId $script:gridAssinaturas;if($id -le 0){Show-Info 'Selecione uma assinatura.';return};$at=[int](Db-Scalar "SELECT ativo FROM assinaturas WHERE id=$id;");$novo=$(if($at -eq 1){0}else{1});Db-Exec "UPDATE assinaturas SET ativo=$novo WHERE id=$id;";Load-Assinaturas}catch{Show-Error $_.Exception.Message}
}

function Delete-Assinatura {
    try{$id=Get-GridId $script:gridAssinaturas;if($id -le 0){Show-Info 'Selecione uma assinatura.';return};if(-not(Confirm-Action 'Excluir a assinatura selecionada?')){return};Db-Exec "DELETE FROM assinaturas WHERE id=$id;";Load-Assinaturas}catch{Show-Error $_.Exception.Message}
}


# V1.0.14.30 - Abas principais configuraveis.
# TabPage.Visible nao esconde de forma confiavel uma pagina que pertence a um
# TabControl no WinForms. Por isso a colecao e reconstruida na ordem oficial,
# preservando as mesmas instancias e todos os controles/eventos ja existentes.
function Apply-MainTabVisibility {
    try {
        if($null -eq $script:tabsMain){return}

        $selected=$null
        $selected=$script:tabsMain.SelectedTab

        $ordem=New-Object System.Collections.ArrayList
        if($null -ne $script:tabEscMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabEscMain;Show=$true}))}
        if($null -ne $script:tabSrvMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabSrvMain;Show=(Get-ConfigBool 'interface_tab_servidores' $true)}))}
        if($null -ne $script:tabReadaptMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabReadaptMain;Show=(Get-ConfigBool 'interface_tab_readaptados' $false)}))}
        if($null -ne $script:tabOcMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabOcMain;Show=(Get-ConfigBool 'interface_tab_ocorrencias' $true)}))}
        if($null -ne $script:tabSetMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabSetMain;Show=(Get-ConfigBool 'interface_tab_setores' $true)}))}
        if($null -ne $script:tabHorMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabHorMain;Show=(Get-ConfigBool 'interface_tab_horarios' $true)}))}
        if($null -ne $script:tabSiglasMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabSiglasMain;Show=(Get-ConfigBool 'interface_tab_siglas' $true)}))}
        if($null -ne $script:tabConfMain){[void]$ordem.Add((New-Object PSObject -Property @{Page=$script:tabConfMain;Show=$true}))}

        $script:tabsMain.SuspendLayout()
        try{
            $script:tabsMain.TabPages.Clear()
            foreach($item in $ordem){
                if([bool]$item.Show){[void]$script:tabsMain.TabPages.Add($item.Page)}
            }
            if($null -ne $selected -and $script:tabsMain.TabPages.Contains($selected)){
                $script:tabsMain.SelectedTab=$selected
            } elseif($null -ne $script:tabEscMain -and $script:tabsMain.TabPages.Contains($script:tabEscMain)){
                $script:tabsMain.SelectedTab=$script:tabEscMain
            }
        } finally {
            $script:tabsMain.ResumeLayout()
        }
    } catch {
        Write-Log ('Falha ao aplicar visibilidade das abas: ' + $_.Exception.Message)
    }
}

function Restore-MainTabsDefaults {
    try{
        Set-ConfigValue 'interface_tab_servidores' '1'
        Set-ConfigValue 'interface_tab_readaptados' '0'
        Set-ConfigValue 'interface_tab_ocorrencias' '1'
        Set-ConfigValue 'interface_tab_setores' '1'
        Set-ConfigValue 'interface_tab_horarios' '1'
        Set-ConfigValue 'interface_tab_siglas' '1'

        if($null -ne $script:chkTabServidores){$script:chkTabServidores.Checked=$true}
        if($null -ne $script:chkTabReadaptados){$script:chkTabReadaptados.Checked=$false}
        if($null -ne $script:chkTabOcorrencias){$script:chkTabOcorrencias.Checked=$true}
        if($null -ne $script:chkTabSetores){$script:chkTabSetores.Checked=$true}
        if($null -ne $script:chkTabHorarios){$script:chkTabHorarios.Checked=$true}
        if($null -ne $script:chkTabSiglas){$script:chkTabSiglas.Checked=$true}

        Apply-MainTabVisibility
        Set-ConfigStatus 'Abas padrao restauradas' ([System.Drawing.Color]::FromArgb(22,101,52))
    }catch{Show-Error $_.Exception.Message}
}


function Set-QtdPreviewCellVisual {
    param($Label,[bool]$Destacar,[System.Drawing.Color]$Bg,[System.Drawing.Color]$Fg)
    if($null -eq $Label){return}
    if($Destacar){
        $Label.BackColor=$Bg;$Label.ForeColor=$Fg;$Label.Font=$script:FontSemibold9
    }else{
        $Label.BackColor=[Drawing.Color]::White;$Label.ForeColor=[Drawing.Color]::Black;$Label.Font=$script:FontSemibold9
    }
}

function Update-QtdPrintConfigPreview {
    $bg=Color-FromHex $(if($null -ne $script:txtQtdPrintFundo){$script:txtQtdPrintFundo.Text}else{'#D9D9D9'}) ([Drawing.Color]::FromArgb(217,217,217))
    $fg=Color-FromHex $(if($null -ne $script:txtQtdPrintFonte){$script:txtQtdPrintFonte.Text}else{'#000000'}) ([Drawing.Color]::Black)
    $ativo=$true;$ativo=[bool]$script:chkQtdPrintDestaque.Checked
    $enf=$false;$teae=$false;$outros=$false;$vaga=$false
    $enf=[bool]$script:chkQtdGrupoENF.Checked
    $teae=[bool]$script:chkQtdGrupoTEAE.Checked
    $outros=[bool]$script:chkQtdGrupoOutros.Checked
    $vaga=[bool]$script:chkQtdPrintVaga.Checked
    Set-QtdPreviewCellVisual $script:lblQtdPrevENF ($ativo -and $enf) $bg $fg
    Set-QtdPreviewCellVisual $script:lblQtdPrevTEAE ($ativo -and $teae) $bg $fg
    Set-QtdPreviewCellVisual $script:lblQtdPrevOutro ($ativo -and $outros) $bg $fg
    Set-QtdPreviewCellVisual $script:lblQtdPrevVaga ($ativo -and $vaga -and $enf) $bg $fg
    if($null -ne $script:lblQtdPrintPreview){
        $script:lblQtdPrintPreview.BackColor=$(if($ativo -and $enf){$bg}else{[Drawing.Color]::White})
        $script:lblQtdPrintPreview.ForeColor=$(if($ativo -and $enf){$fg}else{[Drawing.Color]::Black})
        $script:lblQtdPrintPreview.Text='1'
    }
}

function Test-QtdPrintHighlightGrupo {
    param([AllowNull()][string]$Funcao,$Cfg)
    if($null -eq $Cfg -or -not [bool]$Cfg.qtdDestaqueAtivo){return $false}
    # O grupo visual e independente do modo de numeracao.
    # Mesmo em SEQUENCIAL, ENF continua pertencendo ao grupo ENF,
    # TE/AE ao grupo TEAE e os demais a OUTROS.
    $grp=Get-QtdGrupoByMode ([string]$Funcao) 'ENF_TEAE'
    foreach($item in @($Cfg.qtdDestaqueGrupos)){
        if(([string]$item).Trim().ToUpperInvariant() -eq $grp){return $true}
    }
    return $false
}

function Test-QtdPrintHighlightRow {
    param([AllowNull()][string]$FuncaoBruta,[AllowNull()][string]$FuncaoExibida,$Cfg)
    # Usa exatamente o MESMO agrupamento funcional da numeracao Qtd.
    if(Test-QtdPrintHighlightGrupo $FuncaoBruta $Cfg){return $true}
    if(Test-QtdPrintHighlightGrupo $FuncaoExibida $Cfg){return $true}
    return $false
}

function Load-ConfiguracoesUI {
    try {
        Sync-PreviewLegendaCheckbox
        if($null -ne $script:cboQtdModo){
            $modo=Get-ConfigValue 'qtd_modo' 'ENF_TEAE'
            if($modo -eq 'SEQUENCIAL'){$script:cboQtdModo.SelectedIndex=1}else{$script:cboQtdModo.SelectedIndex=0}
        }
        if($null -ne $script:chkQtdReinicia){$script:chkQtdReinicia.Checked=Get-ConfigBool 'qtd_reiniciar_bloco' $true}
        if($null -ne $script:txtOrdemCargos){$script:txtOrdemCargos.Text=Get-ConfigValue 'ordem_cargos' 'ENF,TE,AE'}
        if($null -ne $script:chkQtdPrintDestaque){$script:chkQtdPrintDestaque.Checked=Get-ConfigBool 'impressao_qtd_destaque_ativo' $true}
        $qtdGruposCfg=Get-ConfigValue 'impressao_qtd_destaque_grupos' 'ENF'
        $qtdGruposAtivos=@(([string]$qtdGruposCfg -split '[,;]') | ForEach-Object {$_.Trim().ToUpperInvariant()} | Where-Object {$_})
        if($null -ne $script:chkQtdGrupoENF){$script:chkQtdGrupoENF.Checked=('ENF' -in $qtdGruposAtivos)}
        if($null -ne $script:chkQtdGrupoTEAE){$script:chkQtdGrupoTEAE.Checked=('TEAE' -in $qtdGruposAtivos)}
        if($null -ne $script:chkQtdGrupoOutros){$script:chkQtdGrupoOutros.Checked=('OUTROS' -in $qtdGruposAtivos)}
        if($null -ne $script:chkQtdPrintVaga){$script:chkQtdPrintVaga.Checked=Get-ConfigBool 'impressao_qtd_destaque_vaga' $true}
        if($null -ne $script:txtQtdPrintFundo){$script:txtQtdPrintFundo.Text=Get-ConfigValue 'impressao_qtd_destaque_fundo' '#D9D9D9'}
        if($null -ne $script:txtQtdPrintFonte){$script:txtQtdPrintFonte.Text=Get-ConfigValue 'impressao_qtd_destaque_fonte' '#000000'}
        Update-QtdPrintConfigPreview
        if($null -ne $script:chkCalFds){$script:chkCalFds.Checked=Get-ConfigBool 'calendario_destacar_fds' $true}
        if($null -ne $script:chkCalFer){$script:chkCalFer.Checked=Get-ConfigBool 'calendario_destacar_feriados' $true}
        if($null -ne $script:chkImpLegenda){$script:chkImpLegenda.Checked=Get-ConfigBool 'impressao_legenda' $true}
        if($null -ne $script:chkImpTodasSiglas){$script:chkImpTodasSiglas.Checked=Get-ConfigBool 'legenda_todas_siglas' $true}
        if($null -ne $script:chkImpAss){$script:chkImpAss.Checked=Get-ConfigBool 'impressao_assinaturas' $true}
        if($null -ne $script:chkImpFds){$script:chkImpFds.Checked=Get-ConfigBool 'impressao_destacar_fds' $true}
        if($null -ne $script:chkImpFer){$script:chkImpFer.Checked=Get-ConfigBool 'impressao_destacar_feriados' $true}
        if($null -ne $script:chkMaskDN){$script:chkMaskDN.Checked=Get-ConfigBool 'mascara_dn_paridade' $true}
        if($null -ne $script:chkMaskMV){$script:chkMaskMV.Checked=Get-ConfigBool 'mascara_mv_fds_paridade' $true}
        if($null -ne $script:chkAutoPtMV){$script:chkAutoPtMV.Checked=Get-ConfigBool 'mv_pt_automatico' $true}
        if($null -ne $script:chkAuto08FFPF){$script:chkAuto08FFPF.Checked=Get-ConfigBool '08h_auto_ff_pf' $true}
        if($null -ne $script:chkAuto08FS){$script:chkAuto08FS.Checked=Get-ConfigBool '08h_auto_fs' $true}
        if($null -ne $script:txtSiglasRapidas){$script:txtSiglasRapidas.Text=Get-ConfigValue 'menu_siglas_rapidas' 'FC,FF,PT,C1,C2,C3,FS,PF'}
        if($null -ne $script:chkAbrirMesAtual){$script:chkAbrirMesAtual.Checked=Get-ConfigBool 'abrir_mes_atual' $true}
        if($null -ne $script:numMesPadrao){$script:numMesPadrao.Value=[decimal](Get-ConfigInt 'mes_padrao' 8 1 12)}
        if($null -ne $script:numAnoPadrao){$script:numAnoPadrao.Value=[decimal](Get-ConfigInt 'ano_padrao' 2026 2024 2100)}
        if($null -ne $script:cboCopiaMesAnterior){
            $m=(Get-ConfigValue 'criar_mes_copiar_anterior' 'PERGUNTAR').ToUpperInvariant()
            if($m -eq 'SIM'){$script:cboCopiaMesAnterior.SelectedIndex=1}elseif($m -eq 'NAO'){$script:cboCopiaMesAnterior.SelectedIndex=2}else{$script:cboCopiaMesAnterior.SelectedIndex=0}
        }
        if($null -ne $script:cboDensidade){
            $d=(Get-ConfigValue 'interface_densidade' 'NORMAL').ToUpperInvariant()
            if($d -eq 'COMPACTA'){$script:cboDensidade.SelectedIndex=0}elseif($d -eq 'CONFORTAVEL'){$script:cboDensidade.SelectedIndex=2}else{$script:cboDensidade.SelectedIndex=1}
        }
        if($null -ne $script:cboLarguraDias){
            $ld=(Get-ConfigValue 'interface_largura_dias' 'AJUSTAR').ToUpperInvariant()
            if($ld -eq 'COMPACTA'){$script:cboLarguraDias.SelectedIndex=1}elseif($ld -eq 'PADRAO'){$script:cboLarguraDias.SelectedIndex=2}else{$script:cboLarguraDias.SelectedIndex=0}
        }
        if($null -ne $script:cboEstiloEscala){
            $ie=(Get-ConfigValue 'interface_estilo_escala' 'DASHBOARD').ToUpperInvariant()
            switch($ie){
                'ORIGINAL' {$script:cboEstiloEscala.SelectedIndex=0}
                'MODERNA' {$script:cboEstiloEscala.SelectedIndex=1}
                'LATERAL' {$script:cboEstiloEscala.SelectedIndex=2}
                'GUIADA' {$script:cboEstiloEscala.SelectedIndex=3}
                default {$script:cboEstiloEscala.SelectedIndex=4}
            }
        }
        if($null -ne $script:chkTabServidores){$script:chkTabServidores.Checked=Get-ConfigBool 'interface_tab_servidores' $true}
        if($null -ne $script:chkTabReadaptados){$script:chkTabReadaptados.Checked=Get-ConfigBool 'interface_tab_readaptados' $false}
        if($null -ne $script:chkTabOcorrencias){$script:chkTabOcorrencias.Checked=Get-ConfigBool 'interface_tab_ocorrencias' $true}
        if($null -ne $script:chkTabSetores){$script:chkTabSetores.Checked=Get-ConfigBool 'interface_tab_setores' $true}
        if($null -ne $script:chkTabHorarios){$script:chkTabHorarios.Checked=Get-ConfigBool 'interface_tab_horarios' $true}
        if($null -ne $script:chkTabSiglas){$script:chkTabSiglas.Checked=Get-ConfigBool 'interface_tab_siglas' $true}
        if($null -ne $script:chkBackupSaida){$script:chkBackupSaida.Checked=Get-ConfigBool 'backup_automatico_saida' $true}
        if($null -ne $script:numBackupMax){$script:numBackupMax.Value=[decimal](Get-ConfigInt 'backup_max_arquivos' 15 1 500)}
        if($null -ne $script:txtBackupAdicional){$script:txtBackupAdicional.Text=Get-ConfigValueAllowEmpty 'backup_diretorio_adicional' ''}
        if($null -ne $script:numLegendaFonte){$script:numLegendaFonte.Value=[decimal](Get-ConfigInt 'impressao_legenda_fonte_pt' 6 5 10)}
        if($null -ne $script:numLegendaSiglaMm){$script:numLegendaSiglaMm.Value=[decimal](Get-ConfigInt 'impressao_legenda_sigla_mm' 7 5 15)}
        if($null -ne $script:numAssinaturaFonte){$script:numAssinaturaFonte.Value=[decimal](Get-ConfigInt 'impressao_assinatura_fonte_pt' 7 5 12)}
        if($null -ne $script:cboAssFonteFamilia){
            $affam=Get-ConfigValue 'impressao_assinatura_fonte_familia' 'Arial'
            $affidx=$script:cboAssFonteFamilia.Items.IndexOf($affam)
            $script:cboAssFonteFamilia.SelectedIndex=$(if($affidx -ge 0){$affidx}else{0})
        }
        if($null -ne $script:numCabecalhoFonte){$script:numCabecalhoFonte.Value=[decimal](Get-ConfigInt 'impressao_cabecalho_fonte_pt' 7 5 14)}
        if($null -ne $script:txtInstLinha1){$script:txtInstLinha1.Text=Get-ConfigValueAllowEmpty 'impressao_inst_linha1' ''}
        if($null -ne $script:txtInstLinha2){$script:txtInstLinha2.Text=Get-ConfigValueAllowEmpty 'impressao_inst_linha2' ''}
        if($null -ne $script:txtInstLinha3){$script:txtInstLinha3.Text=Get-ConfigValueAllowEmpty 'impressao_inst_linha3' ''}
        if($null -ne $script:txtInstLinha4){$script:txtInstLinha4.Text=Get-ConfigValueAllowEmpty 'impressao_inst_linha4' ''}
        if($null -ne $script:txtTituloAssinaturas){$script:txtTituloAssinaturas.Text=Get-ConfigValueAllowEmpty 'impressao_titulo_assinaturas' ''}
        if($null -ne $script:txtTituloLegenda){$script:txtTituloLegenda.Text=Get-ConfigValueAllowEmpty 'impressao_titulo_legenda' 'LEGENDA DAS SIGLAS'}
        if($null -ne $script:txtTextoChefiaPadrao){$script:txtTextoChefiaPadrao.Text=Get-ConfigValue 'impressao_texto_chefia_padrao' 'CHEFIA DO SETOR'}
        if($null -ne $script:numMargemPagina){$script:numMargemPagina.Value=[decimal](Get-ConfigDecimal 'impressao_margem_pagina_mm' 7.0 7.0 20.0)}
        if($null -ne $script:numPaddingFolha){$script:numPaddingFolha.Value=[decimal](Get-ConfigDecimal 'impressao_padding_folha_mm' 5.0 0.0 15.0)}
        if($null -ne $script:numEspacoSetores){$script:numEspacoSetores.Value=[decimal](Get-ConfigDecimal 'impressao_espaco_entre_setores_mm' 6.0 0.0 30.0)}
        if($null -ne $script:chkAssLinhasSeparadas){$script:chkAssLinhasSeparadas.Checked=(Get-ConfigBool 'impressao_assinatura_linhas_separadas' $true)}
        if($null -ne $script:cboLegendaOrdem){
            $ordemAtual=Get-ConfigValue 'impressao_legenda_ordenar_por' 'DESCRICAO'
            $script:cboLegendaOrdem.SelectedIndex=$(if($ordemAtual -eq 'SIGLA'){1}else{0})
        }
        if($null -ne $script:numLegendaPares){
            $script:numLegendaPares.Value=[decimal](Get-ConfigInt 'impressao_legenda_pares' 2 1 3)
        }
        if($null -ne $script:cboLegendaPosicao){
            $posLeg=(Get-ConfigValue 'impressao_legenda_posicao' 'DIREITA').ToUpperInvariant()
            $script:cboLegendaPosicao.SelectedIndex=$(if($posLeg -eq 'ESQUERDA'){1}else{0})
        }
        if($null -ne $script:cboCabFonteFamilia){
            $cffam=Get-ConfigValue 'impressao_cabecalho_fonte_familia' 'Arial'
            $cffidx=$script:cboCabFonteFamilia.Items.IndexOf($cffam)
            $script:cboCabFonteFamilia.SelectedIndex=$(if($cffidx -ge 0){$cffidx}else{0})
        }
        if($null -ne $script:cboImpFonteFamilia){
            $ff=Get-ConfigValue 'impressao_fonte_familia' 'Arial'
            $idx=$script:cboImpFonteFamilia.Items.IndexOf($ff)
            $script:cboImpFonteFamilia.SelectedIndex=$(if($idx -ge 0){$idx}else{0})
        }
        if($null -ne $script:numImpGradeFonte){$script:numImpGradeFonte.Value=[decimal](Get-ConfigDecimal 'impressao_grade_fonte_pt' 5.7 4.0 10.0)}
        if($null -ne $script:chkAbreviarNomes){$script:chkAbreviarNomes.Checked=(Get-ConfigBool 'impressao_abreviar_nomes' $true)}
        if($null -ne $script:chkAbrirMesAtual -and $null -ne $script:numMesPadrao){$script:numMesPadrao.Enabled=-not $script:chkAbrirMesAtual.Checked;$script:numAnoPadrao.Enabled=-not $script:chkAbrirMesAtual.Checked}
        $script:PrintProfileUserPick=$false
        Update-PrintProfileSelection
        Set-ConfigStatus ('Configuracoes carregadas - Perfil: '+(Get-PrintProfileFromUI)) ([System.Drawing.Color]::FromArgb(71,85,105))
        Apply-MainTabVisibility
        Load-TiposOcorrencia
    } catch { Show-Error $_.Exception.Message }
}

function Save-ConfiguracoesUI {
    try {
        # V1.0.14.36 - todas as configuracoes desta tela sao acumuladas em memoria
        # e persistidas em UMA transacao. Ou salva tudo, ou nao salva nada.
        Start-ConfigBatch
        $modo=$(if($script:cboQtdModo.SelectedIndex -eq 1){'SEQUENCIAL'}else{'ENF_TEAE'})
        Set-ConfigValue 'qtd_modo' $modo
        Set-ConfigValue 'qtd_reiniciar_bloco' $(if($script:chkQtdReinicia.Checked){'1'}else{'0'})
        $ordemCargosTxt=($script:txtOrdemCargos.Text -replace ';',',' -replace '\s+','').Trim(',').ToUpperInvariant()
        if([string]::IsNullOrWhiteSpace($ordemCargosTxt)){$ordemCargosTxt='ENF,TE,AE'}
        Set-ConfigValue 'ordem_cargos' $ordemCargosTxt
        Set-ConfigValue 'impressao_qtd_destaque_ativo' $(if($script:chkQtdPrintDestaque.Checked){'1'}else{'0'})
        $qtdGrupos=New-Object System.Collections.ArrayList
        if($script:chkQtdGrupoENF.Checked){[void]$qtdGrupos.Add('ENF')}
        if($script:chkQtdGrupoTEAE.Checked){[void]$qtdGrupos.Add('TEAE')}
        if($script:chkQtdGrupoOutros.Checked){[void]$qtdGrupos.Add('OUTROS')}
        if($qtdGrupos.Count -eq 0 -and $script:chkQtdPrintDestaque.Checked){
            [void]$qtdGrupos.Add('ENF')
            if($null -ne $script:chkQtdGrupoENF){$script:chkQtdGrupoENF.Checked=$true}
            Update-QtdPrintConfigPreview
        }
        $qtdGruposTxt=(@($qtdGrupos) -join ',')
        $qtdFundo=Get-SafeHexColor $script:txtQtdPrintFundo.Text '#D9D9D9'
        $qtdFonte=Get-SafeHexColor $script:txtQtdPrintFonte.Text '#000000'
        $script:txtQtdPrintFundo.Text=$qtdFundo;$script:txtQtdPrintFonte.Text=$qtdFonte
        Set-ConfigValue 'impressao_qtd_destaque_grupos' $qtdGruposTxt
        Set-ConfigValue 'impressao_qtd_destaque_vaga' $(if($script:chkQtdPrintVaga.Checked){'1'}else{'0'})
        # Mantido por compatibilidade com V50-V52; a V53 usa os grupos acima.
        Set-ConfigValue 'impressao_qtd_destaque_funcoes' $(if('ENF' -in @($qtdGrupos)){'ENF'}else{''})
        Set-ConfigValue 'impressao_qtd_destaque_fundo' $qtdFundo
        Set-ConfigValue 'impressao_qtd_destaque_fonte' $qtdFonte
        Set-ConfigValue 'calendario_destacar_fds' $(if($script:chkCalFds.Checked){'1'}else{'0'})
        Set-ConfigValue 'calendario_destacar_feriados' $(if($script:chkCalFer.Checked){'1'}else{'0'})
        Set-ConfigValue 'impressao_legenda' $(if($script:chkImpLegenda.Checked){'1'}else{'0'})
        Set-ConfigValue 'legenda_todas_siglas' $(if($script:chkImpTodasSiglas.Checked){'1'}else{'0'})
        Set-ConfigValue 'impressao_assinaturas' $(if($script:chkImpAss.Checked){'1'}else{'0'})
        Set-ConfigValue 'impressao_destacar_fds' $(if($script:chkImpFds.Checked){'1'}else{'0'})
        Set-ConfigValue 'impressao_destacar_feriados' $(if($script:chkImpFer.Checked){'1'}else{'0'})
        Set-ConfigValue 'mascara_dn_paridade' $(if($script:chkMaskDN.Checked){'1'}else{'0'})
        Set-ConfigValue 'mascara_mv_fds_paridade' $(if($script:chkMaskMV.Checked){'1'}else{'0'})
        Set-ConfigValue 'mv_pt_automatico' $(if($script:chkAutoPtMV.Checked){'1'}else{'0'})
        Set-ConfigValue '08h_auto_ff_pf' $(if($script:chkAuto08FFPF.Checked){'1'}else{'0'})
        Set-ConfigValue '08h_auto_fs' $(if($script:chkAuto08FS.Checked){'1'}else{'0'})
        $quick=($script:txtSiglasRapidas.Text -replace ';',',' -replace '\s+','').Trim(',')
        if([string]::IsNullOrWhiteSpace($quick)){$quick='FC,FF,PT,C1,C2,C3,FS,PF'}
        Set-ConfigValue 'menu_siglas_rapidas' $quick
        Set-ConfigValue 'abrir_mes_atual' $(if($script:chkAbrirMesAtual.Checked){'1'}else{'0'})
        Set-ConfigValue 'mes_padrao' ([string][int]$script:numMesPadrao.Value)
        Set-ConfigValue 'ano_padrao' ([string][int]$script:numAnoPadrao.Value)
        $cop=$(if($script:cboCopiaMesAnterior.SelectedIndex -eq 1){'SIM'}elseif($script:cboCopiaMesAnterior.SelectedIndex -eq 2){'NAO'}else{'PERGUNTAR'})
        Set-ConfigValue 'criar_mes_copiar_anterior' $cop
        $dens=$(if($script:cboDensidade.SelectedIndex -eq 0){'COMPACTA'}elseif($script:cboDensidade.SelectedIndex -eq 2){'CONFORTAVEL'}else{'NORMAL'})
        Set-ConfigValue 'interface_densidade' $dens
        $largDias=$(if($script:cboLarguraDias.SelectedIndex -eq 1){'COMPACTA'}elseif($script:cboLarguraDias.SelectedIndex -eq 2){'PADRAO'}else{'AJUSTAR'})
        Set-ConfigValue 'interface_largura_dias' $largDias
        $estiloEscala=$(switch($script:cboEstiloEscala.SelectedIndex){0{'ORIGINAL'}1{'MODERNA'}2{'LATERAL'}3{'GUIADA'}default{'DASHBOARD'}})
        Set-ConfigValue 'interface_estilo_escala' $estiloEscala
        Set-ConfigValue 'interface_tab_servidores' $(if($script:chkTabServidores.Checked){'1'}else{'0'})
        Set-ConfigValue 'interface_tab_readaptados' $(if($script:chkTabReadaptados.Checked){'1'}else{'0'})
        Set-ConfigValue 'interface_tab_ocorrencias' $(if($script:chkTabOcorrencias.Checked){'1'}else{'0'})
        Set-ConfigValue 'interface_tab_setores' $(if($script:chkTabSetores.Checked){'1'}else{'0'})
        Set-ConfigValue 'interface_tab_horarios' $(if($script:chkTabHorarios.Checked){'1'}else{'0'})
        Set-ConfigValue 'interface_tab_siglas' $(if($script:chkTabSiglas.Checked){'1'}else{'0'})
        Set-ConfigValue 'backup_automatico_saida' $(if($script:chkBackupSaida.Checked){'1'}else{'0'})
        Set-ConfigValue 'backup_max_arquivos' ([string][int]$script:numBackupMax.Value)
        Set-ConfigValue 'backup_diretorio_adicional' $script:txtBackupAdicional.Text.Trim()
        Set-ConfigValue 'impressao_legenda_fonte_pt' ([string][int]$script:numLegendaFonte.Value)
        Set-ConfigValue 'impressao_legenda_sigla_mm' ([string][int]$script:numLegendaSiglaMm.Value)
        Set-ConfigValue 'impressao_assinatura_fonte_pt' ([string][int]$script:numAssinaturaFonte.Value)
        $assFonteFamilia=$(if($null -ne $script:cboAssFonteFamilia -and $null -ne $script:cboAssFonteFamilia.SelectedItem){[string]$script:cboAssFonteFamilia.SelectedItem}else{'Arial'})
        Set-ConfigValue 'impressao_assinatura_fonte_familia' $assFonteFamilia
        Set-ConfigValue 'impressao_cabecalho_fonte_pt' ([string][int]$script:numCabecalhoFonte.Value)
        $cabFonteFamilia=$(if($null -ne $script:cboCabFonteFamilia -and $null -ne $script:cboCabFonteFamilia.SelectedItem){[string]$script:cboCabFonteFamilia.SelectedItem}else{'Arial'})
        Set-ConfigValue 'impressao_cabecalho_fonte_familia' $cabFonteFamilia
        foreach($n in 1..4){
            $ctrl=Get-Variable -Name ("txtInstLinha{0}" -f $n) -Scope Script -ValueOnly
            $valorInst=([string]$ctrl.Text).Trim()
            Set-ConfigValue ("impressao_inst_linha{0}" -f $n) $valorInst
        }
        Set-ConfigValue 'impressao_titulo_assinaturas' $script:txtTituloAssinaturas.Text.Trim()
        $tLeg=$script:txtTituloLegenda.Text.Trim()
        Set-ConfigValue 'impressao_titulo_legenda' $tLeg
        Set-ConfigValue 'impressao_titulo_legenda_visivel' $(if([string]::IsNullOrWhiteSpace($tLeg)){'0'}else{'1'})
        $tChef=$script:txtTextoChefiaPadrao.Text.Trim();if(-not $tChef){$tChef='CHEFIA DO SETOR'}
        Set-ConfigValue 'impressao_texto_chefia_padrao' $tChef
        Set-ConfigValue 'impressao_margem_pagina_mm' ($script:numMargemPagina.Value.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        Set-ConfigValue 'impressao_padding_folha_mm' ($script:numPaddingFolha.Value.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        Set-ConfigValue 'impressao_espaco_entre_setores_mm' ($script:numEspacoSetores.Value.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        Set-ConfigValue 'impressao_assinatura_linhas_separadas' $(if($script:chkAssLinhasSeparadas.Checked){'1'}else{'0'})
        Set-ConfigValue 'impressao_legenda_ordenar_por' $(if($script:cboLegendaOrdem.SelectedIndex -eq 1){'SIGLA'}else{'DESCRICAO'})
        Set-ConfigValue 'impressao_legenda_pares' ([string][int]$script:numLegendaPares.Value)
        Set-ConfigValue 'impressao_legenda_posicao' $(if($script:cboLegendaPosicao.SelectedIndex -eq 1){'ESQUERDA'}else{'DIREITA'})
        $fonteFamilia=$(if($null -ne $script:cboImpFonteFamilia -and $null -ne $script:cboImpFonteFamilia.SelectedItem){[string]$script:cboImpFonteFamilia.SelectedItem}else{'Arial'})
        Set-ConfigValue 'impressao_fonte_familia' $fonteFamilia
        Set-ConfigValue 'impressao_grade_fonte_pt' ($script:numImpGradeFonte.Value.ToString('0.0',[System.Globalization.CultureInfo]::InvariantCulture))
        Set-ConfigValue 'impressao_abreviar_nomes' $(if($script:chkAbreviarNomes.Checked){'1'}else{'0'})
        if(-not (Confirm-ConfigBatchChanges)){
            Cancel-ConfigBatch
            Set-ConfigStatus 'Salvamento cancelado pelo usuario' ([Drawing.Color]::FromArgb(180,83,9))
            return
        }
        $legendaPadraoAntes=[bool](Get-ConfigBool 'impressao_legenda' $true)
        Complete-ConfigBatch
        if($legendaPadraoAntes -ne [bool](Get-ConfigBool 'impressao_legenda' $true)){Sync-PreviewLegendaCheckbox}
        Apply-MainTabVisibility
        Apply-GridPreferences
        Apply-ScaleInterfaceStyle
        Load-Escala
        $script:PrintProfileUserPick=$false
        Update-PrintProfileSelection
        Set-ConfigStatus ('Salvo em {0:HH:mm:ss} - Perfil: {1}' -f (Get-Date),(Get-PrintProfileFromUI)) ([System.Drawing.Color]::FromArgb(22,101,52))
        Show-Info 'Configuracoes salvas. As novas regras ja serao usadas na escala e na pre-visualizacao.'
    } catch {
        Cancel-ConfigBatch
        $script:PrintProfileUserPick=$false
        Update-PrintProfileSelection
        Show-Error $_.Exception.Message
    }
}

function Load-Feriados {
    try {
        $t=Db-Query "SELECT id,strftime('%d/%m/%Y',data) AS Data,CASE WHEN UPPER(COALESCE(tipo,'FERIADO'))='PONTO_FACULTATIVO' THEN 'Ponto Facultativo' ELSE 'Feriado' END AS Tipo,descricao AS Descricao FROM feriados ORDER BY data;"
        $script:gridFeriados.DataSource=$t
        if($script:gridFeriados.Columns.Contains('id')){$script:gridFeriados.Columns['id'].Visible=$false}
        if($script:gridFeriados.Columns.Contains('Data')){$script:gridFeriados.Columns['Data'].Width=110}
        if($script:gridFeriados.Columns.Contains('Tipo')){$script:gridFeriados.Columns['Tipo'].Width=150}
        if($script:gridFeriados.Columns.Contains('Descricao')){$script:gridFeriados.Columns['Descricao'].AutoSizeMode='Fill'}
    } catch { Show-Error $_.Exception.Message }
}

function Show-FeriadoDialog {
    param([int]$Id=0)
    try {
        $data=$null
        if($Id -gt 0){$t=Db-Query "SELECT * FROM feriados WHERE id=$Id;";if($t.Rows.Count){$data=$t.Rows[0]}}
        $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=$(if($data){'Editar feriado / ponto facultativo'}else{'Novo feriado / ponto facultativo'});$f.StartPosition='CenterParent';$f.ClientSize=New-Object System.Drawing.Size(610,310);$f.FormBorderStyle='FixedDialog';$f.MaximizeBox=$false;$f.AutoScaleMode='Dpi'
        $l1=New-Object System.Windows.Forms.Label;$l1.Text='Data';$l1.Location=New-Object System.Drawing.Point(25,35);$l1.Size=New-Object System.Drawing.Size(100,22);$f.Controls.Add($l1)
        $dt=New-Object System.Windows.Forms.DateTimePicker;$dt.Format='Short';$dt.Location=New-Object System.Drawing.Point(150,32);$dt.Size=New-Object System.Drawing.Size(170,26);$f.Controls.Add($dt)
        $lTipo=New-Object System.Windows.Forms.Label;$lTipo.Text='Tipo';$lTipo.Location=New-Object System.Drawing.Point(25,82);$lTipo.Size=New-Object System.Drawing.Size(100,22);$f.Controls.Add($lTipo)
        $cbTipo=New-Object System.Windows.Forms.ComboBox;$cbTipo.Location=New-Object System.Drawing.Point(150,79);$cbTipo.Size=New-Object System.Drawing.Size(260,27);$cbTipo.DropDownStyle='DropDownList';[void]$cbTipo.Items.Add('Feriado');[void]$cbTipo.Items.Add('Ponto Facultativo');$cbTipo.SelectedIndex=0;$f.Controls.Add($cbTipo)
        $l2=New-Object System.Windows.Forms.Label;$l2.Text='Descricao';$l2.Location=New-Object System.Drawing.Point(25,130);$l2.Size=New-Object System.Drawing.Size(100,22);$f.Controls.Add($l2)
        $tb=New-Object System.Windows.Forms.TextBox;$tb.Location=New-Object System.Drawing.Point(150,127);$tb.Size=New-Object System.Drawing.Size(410,26);$f.Controls.Add($tb)
        $dataOriginal=$(if($data){[string]$data['data']}else{''})
        if($data){
            $dt.Value=[datetime]::Parse([string]$data['data'])
            $cbTipo.SelectedIndex=$(if([string]$data['tipo'] -eq 'PONTO_FACULTATIVO'){1}else{0})
            $tb.Text=[string]$data['descricao']
        }
        # Sugere a descricao automaticamente conforme a Data (feriados nacionais
        # fixos e moveis). So preenche se o campo estiver vazio ou ainda tiver a
        # ultima sugestao (nao sobrescreve texto digitado/carregado do usuario).
        $ultimaSugestaoFer=$(if($data){[string]$data['descricao']}else{''})
        $dt.Add_ValueChanged({
            $sug=Get-NomeFeriadoSugerido $dt.Value.Date
            if($sug -and ([string]::IsNullOrWhiteSpace($tb.Text) -or $tb.Text -eq $ultimaSugestaoFer)){$tb.Text=$sug}
            $ultimaSugestaoFer=$sug
        })
        if(-not $data){
            $sugInicial=Get-NomeFeriadoSugerido $dt.Value.Date
            if($sugInicial){$tb.Text=$sugInicial;$ultimaSugestaoFer=$sugInicial}
        }
        $info=New-Object System.Windows.Forms.Label;$info.Text='Nos horarios de 08h: FDS gera FS, Feriado gera FF e Ponto Facultativo gera PF automaticamente.';$info.Location=New-Object System.Drawing.Point(25,172);$info.Size=New-Object System.Drawing.Size(535,40);$info.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105);$f.Controls.Add($info)
        $ok=New-Button 'SALVAR' 120;$ok.Location=New-Object System.Drawing.Point(300,225);$can=New-Button 'CANCELAR' 120;$can.Location=New-Object System.Drawing.Point(435,225);$can.DialogResult='Cancel'
        $ok.Add_Click({
            try{
                if([string]::IsNullOrWhiteSpace($tb.Text)){Show-Info 'Informe a descricao.';return}
                $tipo=$(if($cbTipo.SelectedIndex -eq 1){'PONTO_FACULTATIVO'}else{'FERIADO'})
                $novaData=$dt.Value.Date.ToString('yyyy-MM-dd')
                if($data -and $dataOriginal -ne $novaData){
                    # Editando e a data mudou: remove o registro antigo antes de gravar
                    # no novo dia (senao ficaria um registro duplicado com a data velha).
                    Db-Exec "DELETE FROM feriados WHERE id=$Id;"
                }
                Db-Exec ("INSERT INTO feriados(data,descricao,tipo) VALUES ({0},{1},{2}) ON CONFLICT(data) DO UPDATE SET descricao=excluded.descricao,tipo=excluded.tipo;" -f (Sql-Q $novaData),(Sql-Q $tb.Text.Trim()),(Sql-Q $tipo))
                $f.DialogResult='OK';$f.Close()
            }catch{Show-Error $_.Exception.Message}
        })
        $f.Controls.Add($ok);$f.Controls.Add($can)
        $dlgResult=$f.ShowDialog($script:MainForm);$f.Dispose();if($dlgResult -eq'OK'){Load-Feriados;Load-Escala}
    } catch { Show-Error $_.Exception.Message }
}

function Delete-Feriado {
    try {
        $id=Get-GridId $script:gridFeriados
        if($id -le 0){Show-Info 'Selecione um feriado.';return}
        if(-not(Confirm-Action 'Excluir o feriado/ponto facultativo selecionado?')){return}
        Db-Exec "DELETE FROM feriados WHERE id=$id;"
        Load-Feriados;Load-Escala
    } catch { Show-Error $_.Exception.Message }
}

function Show-CalendarioEscala {
    try {
        $sid=Get-SelectedSetorId
        if($sid -le 0){Show-Info 'Selecione o setor.';return}
        $ano=[int]$script:numAno.Value;$mes=[int]$script:cboMes.SelectedValue
        $setNome=[string](Db-Scalar "SELECT nome FROM setores WHERE id=$sid;")
        $scaleId=Get-ScaleId
        $esid=0;$servidorNome='Nenhum servidor selecionado'
        if($null -ne $script:gridEscala.CurrentRow -and $script:gridEscala.CurrentRow.Index -ge 0){
            $tipoLinha=[string]$script:gridEscala.CurrentRow.Cells['_TIPO'].Value
            if($tipoLinha -eq 'SERVIDOR'){
                $esid=[int]$script:gridEscala.CurrentRow.Cells['_ID'].Value
                $servidorNome=[string]$script:gridEscala.CurrentRow.Cells['Servidor'].Value
            }
        }

        $f=New-Object System.Windows.Forms.Form;Set-FormTheme $f;$f.Text=('Calendario da Escala - {0:00}/{1}' -f $mes,$ano);$f.StartPosition='CenterParent';$f.Size=New-Object System.Drawing.Size(1040,760);$f.MinimumSize=New-Object System.Drawing.Size(900,680);$f.AutoScaleMode='Dpi'
        $top=New-Object System.Windows.Forms.Panel;$top.Dock='Top';$top.Height=86;$top.BackColor=[System.Drawing.Color]::FromArgb(242,245,248);$f.Controls.Add($top)
        $title=New-Object System.Windows.Forms.Label;$title.Text=('CALENDARIO - {0} - {1:00}/{2}' -f $setNome,$mes,$ano);$title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',14);$title.Location=New-Object System.Drawing.Point(18,12);$title.AutoSize=$true;$top.Controls.Add($title)
        $srvLab=New-Object System.Windows.Forms.Label;$srvLab.Text=('Servidor para lancamento: {0}' -f $servidorNome);$srvLab.Location=New-Object System.Drawing.Point(20,48);$srvLab.AutoSize=$true;$top.Controls.Add($srvLab)

        $bottom=New-Object System.Windows.Forms.Panel;$bottom.Dock='Bottom';$bottom.Height=125;$f.Controls.Add($bottom)
        $labSg=New-Object System.Windows.Forms.Label;$labSg.Text='Sigla';$labSg.Location=New-Object System.Drawing.Point(18,18);$labSg.Size=New-Object System.Drawing.Size(50,22);$bottom.Controls.Add($labSg)
        $cbSg=New-Object System.Windows.Forms.ComboBox;$cbSg.Location=New-Object System.Drawing.Point(72,15);$cbSg.Size=New-Object System.Drawing.Size(280,26);$cbSg.DropDownStyle='DropDownList';$sgt=Db-Query "SELECT sigla, sigla || ' - ' || descricao AS item FROM siglas WHERE ativo=1 AND sigla NOT IN ('FER','AT') ORDER BY sigla;";$bsTmp9=New-Object System.Windows.Forms.BindingSource;$bsTmp9.DataSource=$sgt;$cbSg.DataSource=$bsTmp9;$cbSg.ValueMember='sigla';$cbSg.DisplayMember='item';$bottom.Controls.Add($cbSg)
        $bApply=New-Button 'APLICAR NOS DIAS SELECIONADOS' 235;$bApply.Location=New-Object System.Drawing.Point(370,8);$bottom.Controls.Add($bApply)
        $bClear=New-Button 'LIMPAR LANCAMENTOS MANUAIS' 225;$bClear.Location=New-Object System.Drawing.Point(615,8);$bottom.Controls.Add($bClear)
        $hint=New-Object System.Windows.Forms.Label;$hint.Text='Calendario = somente siglas manuais. FERIAS/ATESTADO = Ocorrencias. ESCALA VAGA = botao proprio. Ocorrencias nao sao sobrescritas nem apagadas.';$hint.Location=New-Object System.Drawing.Point(18,82);$hint.Size=New-Object System.Drawing.Size(900,28);$bottom.Controls.Add($hint)

        $side=New-Object System.Windows.Forms.FlowLayoutPanel;$side.Dock='Right';$side.Width=180;$side.FlowDirection='TopDown';$side.Padding=New-Object System.Windows.Forms.Padding(8);$side.WrapContents=$false;$f.Controls.Add($side)
        $bAllFds=New-Button 'TODOS OS FDS' 150;$side.Controls.Add($bAllFds)
        $bPar=New-Button 'FDS PARES' 150;$side.Controls.Add($bPar)
        $bImp=New-Button 'FDS IMPARES' 150;$side.Controls.Add($bImp)
        $bSelFer=New-Button 'FERIADOS' 150;$side.Controls.Add($bSelFer)
        $bSelClear=New-Button 'LIMPAR SELECAO' 150;$side.Controls.Add($bSelClear)
        $leg=New-Object System.Windows.Forms.Label;$leg.Text="FDS: cinza`r`nPAR/IMPAR: numero do dia`r`nFeriado: amarelo`r`nSelecionado: azul";$leg.Size=New-Object System.Drawing.Size(160,110);$leg.Margin=New-Object System.Windows.Forms.Padding(7,18,0,0);$side.Controls.Add($leg)

        $g=New-Object System.Windows.Forms.DataGridView;$g.Dock='Fill';$g.BackgroundColor=[System.Drawing.Color]::White;$g.BorderStyle='None';$g.AllowUserToAddRows=$false;$g.AllowUserToDeleteRows=$false;$g.AllowUserToResizeColumns=$false;$g.AllowUserToResizeRows=$false;$g.RowHeadersVisible=$false;$g.ColumnHeadersHeight=32;$g.SelectionMode='CellSelect';$g.MultiSelect=$true;$g.ReadOnly=$true;$g.DefaultCellStyle.Alignment='MiddleCenter';$g.DefaultCellStyle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',11);$g.DefaultCellStyle.WrapMode='True';$g.DefaultCellStyle.SelectionBackColor=[System.Drawing.Color]::FromArgb(160,195,230);$g.DefaultCellStyle.SelectionForeColor=[System.Drawing.Color]::Black
        $weekNames=@('DO','SE','TE','QA','QI','SX','SA')
        foreach($w in $weekNames){$c=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$c.HeaderText=$w;$c.Name=$w;$c.SortMode='NotSortable';$c.AutoSizeMode='Fill';$g.Columns.Add($c)|Out-Null}
        for($r=0;$r -lt 6;$r++){$ix=$g.Rows.Add();$g.Rows[$ix].Height=78}
        $f.Controls.Add($g);$g.BringToFront()

        $fer=@{};$ferTipo=@{};$ft=Db-Query ("SELECT data,descricao,COALESCE(tipo,'FERIADO') AS tipo FROM feriados WHERE data LIKE {0};" -f (Sql-Q ('{0}-{1:00}-%' -f $ano,$mes)))
        foreach($rr in $ft.Rows){$fer[[string]$rr['data']]=[string]$rr['descricao'];$ferTipo[[string]$rr['data']]=[string]$rr['tipo']}
        $first=Get-Date -Year $ano -Month $mes -Day 1;$days=[datetime]::DaysInMonth($ano,$mes)
        for($d=1;$d -le $days;$d++){
            $dt=Get-Date -Year $ano -Month $mes -Day $d
            $col=[int]$dt.DayOfWeek;$row=[int][Math]::Floor(($d-1+[int]$first.DayOfWeek)/7)
            $cell=$g.Rows[$row].Cells[$col]
            $isWeek=($dt.DayOfWeek -eq 'Saturday' -or $dt.DayOfWeek -eq 'Sunday')
            # Paridade calculada por dias corridos desde uma data fixa (nunca
            # reinicia a cada mes), para bater exatamente com a grade/impressao.
            $isDayEven=((Get-DiasCorridosParidade $dt) % 2) -eq 0
            $key=$dt.ToString('yyyy-MM-dd');$holiday=$fer.ContainsKey($key)
            $txt=('{0:00}' -f $d)
            if($isWeek){$txt += ("`r`nFDS {0}" -f $(if($isDayEven){'PAR'}else{'IMPAR'}))}
            if($holiday){$txt += "`r`nFERIADO"}
            $cell.Value=$txt
            $cell.Tag=[pscustomobject]@{Data=$dt;IsWeekend=$isWeek;IsDayEven=$isDayEven;Holiday=$holiday}
            if($holiday -and (Get-ConfigBool 'calendario_destacar_feriados' $true)){$cell.Style.BackColor=[System.Drawing.Color]::FromArgb(255,244,180);$cell.ToolTipText=$fer[$key]}
            elseif($isWeek -and (Get-ConfigBool 'calendario_destacar_fds' $true)){$cell.Style.BackColor=[System.Drawing.Color]::FromArgb(225,229,234)}
        }

        $selectBy={param([string]$Mode);$g.ClearSelection();foreach($row in $g.Rows){foreach($cell in $row.Cells){if($null -eq $cell.Tag){continue};$tag=$cell.Tag;$ok=$false;switch($Mode){'ALLFDS'{$ok=$tag.IsWeekend};'PAR'{$ok=($tag.IsWeekend -and $tag.IsDayEven)};'IMPAR'{$ok=($tag.IsWeekend -and (-not $tag.IsDayEven))};'FER'{$ok=$tag.Holiday}};if($ok){$cell.Selected=$true}}}}
        $bAllFds.Add_Click({& $selectBy 'ALLFDS'});$bPar.Add_Click({& $selectBy 'PAR'});$bImp.Add_Click({& $selectBy 'IMPAR'});$bSelFer.Add_Click({& $selectBy 'FER'});$bSelClear.Add_Click({$g.ClearSelection()})

        $bApply.Add_Click({
            try {
                if($scaleId -le 0 -or $esid -le 0){Show-Info 'Na aba Escala, carregue o mes e selecione primeiro a linha do servidor que recebera os lancamentos.';return}
                $sig=[string]$cbSg.SelectedValue;if([string]::IsNullOrWhiteSpace($sig)){Show-Info 'Selecione uma sigla.';return}
                if($sig -eq 'FER' -or $sig -eq 'AT'){Show-Info 'FERIAS e ATESTADO devem ser registrados na aba Ocorrencias, para manter periodo, historico e sincronizacao corretos.';return}
                $cfg=Db-Query ("SELECT descricao FROM siglas WHERE sigla={0};" -f (Sql-Q $sig));$desc=$(if($cfg.Rows.Count){[string]$cfg.Rows[0]['descricao']}else{$sig})
                $datas=New-Object 'System.Collections.Generic.List[string]'
                foreach($cell in $g.SelectedCells){if($null -eq $cell.Tag){continue};$ds=$cell.Tag.Data.ToString('yyyy-MM-dd');if(-not $datas.Contains($ds)){$datas.Add($ds)}}
                if($datas.Count -eq 0){Show-Info 'Selecione pelo menos um dia.';return}

                $datasValidas=New-Object 'System.Collections.Generic.List[string]'
                $bloqRegra=0
                $primeiroErroRegra=''
                foreach($ds in $datas){
                    $dtRegra=[datetime]::ParseExact($ds,'yyyy-MM-dd',[System.Globalization.CultureInfo]::InvariantCulture)
                    $erroRegra=Get-SiglaDateRuleError $sig $dtRegra $ferTipo
                    if(-not [string]::IsNullOrWhiteSpace([string]$erroRegra)){
                        $bloqRegra++
                        if([string]::IsNullOrWhiteSpace($primeiroErroRegra)){$primeiroErroRegra=$erroRegra}
                        continue
                    }
                    $datasValidas.Add($ds)
                }
                if($datasValidas.Count -eq 0){
                    if(-not [string]::IsNullOrWhiteSpace($primeiroErroRegra)){Show-Info $primeiroErroRegra}else{Show-Info 'Nenhum dos dias selecionados atende a regra da sigla.'}
                    return
                }

                $inList=($datasValidas | ForEach-Object {Sql-Q $_}) -join ','
                $blocked=[int](Db-Scalar "SELECT COUNT(*) FROM escala_dias WHERE escala_servidor_id=$esid AND origem='OCORRENCIA' AND data IN ($inList);")
                $sql=New-Object System.Text.StringBuilder
                [void]$sql.AppendLine('BEGIN IMMEDIATE;')
                foreach($ds in $datasValidas){
                    [void]$sql.AppendLine(("INSERT INTO escala_dias(escala_servidor_id,data,sigla,texto,origem) SELECT {0},{1},{2},{3},'MANUAL' WHERE NOT EXISTS(SELECT 1 FROM escala_dias WHERE escala_servidor_id={0} AND data={1} AND origem='OCORRENCIA') ON CONFLICT(escala_servidor_id,data) DO UPDATE SET sigla=excluded.sigla,texto=excluded.texto,origem='MANUAL',ocorrencia_id=NULL,atualizado_em=CURRENT_TIMESTAMP WHERE escala_dias.origem<>'OCORRENCIA';" -f $esid,(Sql-Q $ds),(Sql-Q $sig),(Sql-Q $desc)))
                }
                [void]$sql.AppendLine('COMMIT;')
                Db-Exec $sql.ToString()
                $done=$datasValidas.Count-$blocked
                Load-Escala
                Show-Info ("Lancamentos aplicados: {0}. Dias protegidos por ocorrencia: {1}. Dias ignorados pela regra FF/PF/FS: {2}." -f $done,$blocked,$bloqRegra)
            } catch { Show-Error $_.Exception.Message }
        })
        $bClear.Add_Click({
            try {
                if($esid -le 0){Show-Info 'Selecione primeiro um servidor na aba Escala.';return}
                if(-not(Confirm-Action 'Remover apenas os lancamentos MANUAIS dos dias selecionados? Ocorrencias serao preservadas.')){return}
                $datas=New-Object 'System.Collections.Generic.List[string]'
                foreach($cell in $g.SelectedCells){if($null -eq $cell.Tag){continue};$ds=$cell.Tag.Data.ToString('yyyy-MM-dd');if(-not $datas.Contains($ds)){$datas.Add($ds)}}
                if($datas.Count -eq 0){Show-Info 'Selecione pelo menos um dia.';return}
                $inList=($datas | ForEach-Object {Sql-Q $_}) -join ','
                Db-Exec "DELETE FROM escala_dias WHERE escala_servidor_id=$esid AND data IN ($inList) AND origem<>'OCORRENCIA';"
                Load-Escala;Show-Info ("Dias processados: {0}." -f $datas.Count)
            } catch { Show-Error $_.Exception.Message }
        })
        [void]$f.ShowDialog($script:MainForm)
        $f.Dispose()
    } catch { Show-Error $_.Exception.Message }
}

# V1.0.14.40 - PRE-FLIGHT CRITICO REAL.
try {
    [void](Assert-SqliteVersion)
    [void](Initialize-DatabaseJournalMode)
    Apply-CompatibilityFixes
    [void](Ensure-EscalaVagasForeignKeysCritical)
    $trigFaltando=@(Get-MissingIntegrityTriggers)
    if($trigFaltando.Count -gt 0){throw ('Gatilhos de integridade ausentes apos a migracao: ' + ($trigFaltando -join ', ') + '. Veja no log qual passo de compatibilidade falhou.')}
    $preIc=[string](Db-Scalar 'PRAGMA integrity_check;')
    if($preIc.Trim().ToLowerInvariant() -ne 'ok'){throw ('Banco falhou no integrity_check: '+$preIc)}
    $preFk=Db-Query 'PRAGMA foreign_key_check;'
    if($preFk.Rows.Count -gt 0){throw ("Banco possui {0} inconsistencia(s) de chave estrangeira." -f $preFk.Rows.Count)}
    Write-Log 'Pre-flight critico concluido: SQLite/journal/migracoes/integridade OK.'
} catch {
    Write-Log ('ERRO CRITICO NO PRE-FLIGHT: '+$_.Exception.ToString())
    [System.Windows.Forms.MessageBox]::Show(("O sistema nao pode abrir com seguranca.`r`n`r`nFalha no pre-flight do banco:`r`n{0}`r`n`r`nNenhuma tela de trabalho foi carregada. Consulte Logs\Sistema_Escala.log." -f $_.Exception.Message),'Sistema de Escala','OK','Error')|Out-Null
    Invoke-SafeRuntimeCleanup
    exit
}

# Fontes reutilizadas para evitar criar centenas de objetos Font a cada recarga da grade.
$script:FontSemibold9 = New-Object System.Drawing.Font('Segoe UI Semibold',9)

# ---------------- MAIN UI ----------------
$script:MainForm = New-Object System.Windows.Forms.Form
$script:MainForm.Text = 'Sistema de Escala DCE - V1.0.14.83-G1 PROFISSIONAL - FLUXO GUIADO - SQLite'
$script:MainForm.StartPosition = 'CenterScreen'
$script:MainForm.MinimumSize = New-Object System.Drawing.Size(1050,680)
$script:MainForm.Size = New-Object System.Drawing.Size(1480,900)
$script:MainForm.WindowState = 'Maximized'
$script:MainForm.Font = New-Object System.Drawing.Font('Segoe UI',9)
$script:MainForm.AutoScaleMode = 'Dpi'
$script:MainForm.BackColor = [System.Drawing.Color]::FromArgb(239,243,247)

$top=New-Object System.Windows.Forms.Panel;$top.Dock='Top';$top.Height=72;$top.BackColor=[System.Drawing.Color]::FromArgb(27,50,73);$script:MainForm.Controls.Add($top)
$title=New-Object System.Windows.Forms.Label;$title.Text='SISTEMA DE ESCALA DCE';$title.ForeColor=[System.Drawing.Color]::White;$title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',18);$title.Location=New-Object System.Drawing.Point(22,12);$title.AutoSize=$true;$top.Controls.Add($title)
$sub=New-Object System.Windows.Forms.Label;$sub.Text='Gestao de escalas | SQLite local | sem dependencia do Excel';$sub.ForeColor=[System.Drawing.Color]::FromArgb(203,213,225);$sub.Location=New-Object System.Drawing.Point(24,45);$sub.AutoSize=$true;$top.Controls.Add($sub)
$ver=New-Object System.Windows.Forms.Label;$ver.Text='V1.0.14.83-G1 FLUXO GUIADO';$ver.ForeColor=[System.Drawing.Color]::FromArgb(226,232,240);$ver.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$ver.AutoSize=$true;$ver.Anchor='Top,Right';$ver.Location=New-Object System.Drawing.Point(($script:MainForm.ClientSize.Width-310),27);$top.Controls.Add($ver)
$btnBackup=New-Button 'BACKUP' 105;$btnBackup.Anchor='Top,Right';$btnBackup.Location=New-Object System.Drawing.Point(($script:MainForm.ClientSize.Width-135),18);$btnBackup.Add_Click({Backup-Database});$top.Controls.Add($btnBackup)
$top.Add_Resize({$btnBackup.Left=$top.ClientSize.Width-$btnBackup.Width-20;$ver.Left=$btnBackup.Left-$ver.Width-24})

$tabs=New-Object System.Windows.Forms.TabControl;$tabs.Dock='Fill';$tabs.Font=New-Object System.Drawing.Font('Segoe UI Semibold',10);$tabs.DrawMode='OwnerDrawFixed';$tabs.SizeMode='Fixed';$tabs.ItemSize=New-Object System.Drawing.Size(125,36);$tabs.Padding=New-Object System.Drawing.Point(16,5);$script:MainForm.Controls.Add($tabs);$tabs.BringToFront()
$script:tabsMain=$tabs
$tabs.Add_DrawItem({param($sender,$e)
    $r=$sender.GetTabRect($e.Index);$sel=($e.Index -eq $sender.SelectedIndex)
    $bg=$(if($sel){[System.Drawing.Color]::FromArgb(27,50,73)}else{[System.Drawing.Color]::FromArgb(241,245,249)})
    $fg=$(if($sel){[System.Drawing.Color]::White}else{[System.Drawing.Color]::FromArgb(51,65,85)})
    $b=New-Object System.Drawing.SolidBrush($bg);$e.Graphics.FillRectangle($b,$r);$b.Dispose()
    [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics,$sender.TabPages[$e.Index].Text,$script:FontSemibold9,$r,$fg,[System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter)
})

# Tab Escala
$tabEsc=New-Object System.Windows.Forms.TabPage;$tabEsc.Text='Escala';$tabEsc.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabEsc)|Out-Null
$script:tabEscMain=$tabEsc
$pEsc=New-Object System.Windows.Forms.FlowLayoutPanel;$script:pEscToolbar=$pEsc;$pEsc.Dock='Top';$pEsc.AutoSize=$true;$pEsc.AutoSizeMode='GrowAndShrink';$pEsc.Padding=New-Object System.Windows.Forms.Padding(10,5,5,5);$pEsc.WrapContents=$true;$pEsc.BackColor=[System.Drawing.Color]::FromArgb(246,248,250);$tabEsc.Controls.Add($pEsc)
$pEscDivisor=New-Object System.Windows.Forms.Panel;$pEscDivisor.Dock='Top';$pEscDivisor.Height=1;$pEscDivisor.BackColor=[System.Drawing.Color]::FromArgb(214,220,227);$tabEsc.Controls.Add($pEscDivisor)
$labSet=New-ToolbarLabel 'Setor' 48;$pEsc.Controls.Add($labSet)
$script:cboSetorEscala=New-Object System.Windows.Forms.ComboBox;$script:cboSetorEscala.Width=180;$script:cboSetorEscala.DropDownStyle='DropDownList';$script:cboSetorEscala.Margin=New-Object System.Windows.Forms.Padding(0,10,8,0);$pEsc.Controls.Add($script:cboSetorEscala)
$labSubEsc=New-ToolbarLabel 'Sub_Setor' 72;$pEsc.Controls.Add($labSubEsc)
$script:cboSubSetorEscala=New-Object System.Windows.Forms.ComboBox;$script:cboSubSetorEscala.Width=180;$script:cboSubSetorEscala.DropDownStyle='DropDownList';$script:cboSubSetorEscala.Margin=New-Object System.Windows.Forms.Padding(0,10,8,0);$pEsc.Controls.Add($script:cboSubSetorEscala)
$script:cboSetorEscala.Add_SelectedValueChanged({Refresh-SubSetorEscalaCombo})
$labMes=New-ToolbarLabel 'Mes' 38;$pEsc.Controls.Add($labMes)
$script:cboMes=New-Object System.Windows.Forms.ComboBox;$script:cboMes.Width=105;$script:cboMes.DropDownStyle='DropDownList';$months=New-Object System.Data.DataTable;$months.Columns.Add('id',[string])|Out-Null;$months.Columns.Add('nome',[string])|Out-Null;$nomes=@('Janeiro','Fevereiro','Marco','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro');for($i=1;$i -le 12;$i++){$r=$months.NewRow();$r['id']=[string]$i;$r['nome']=$nomes[$i-1];$months.Rows.Add($r)};$bsTmp10=New-Object System.Windows.Forms.BindingSource;$bsTmp10.DataSource=$months;$script:cboMes.DataSource=$bsTmp10;$script:cboMes.ValueMember='id';$script:cboMes.DisplayMember='nome';$script:cboMes.Margin=New-Object System.Windows.Forms.Padding(0,10,8,0);$pEsc.Controls.Add($script:cboMes)
$labAno=New-ToolbarLabel 'Ano' 38;$pEsc.Controls.Add($labAno)
$script:numAno=New-Object System.Windows.Forms.NumericUpDown;$script:numAno.Minimum=2020;$script:numAno.Maximum=2100;$script:numAno.Value=2026;$script:numAno.Width=75;$script:numAno.Margin=New-Object System.Windows.Forms.Padding(0,10,8,0);$pEsc.Controls.Add($script:numAno)
$btnCar=New-Button 'CARREGAR' 105;Set-PrimaryButton $btnCar;$btnCar.Add_Click({Load-Escala;Load-Ocorrencias});$pEsc.Controls.Add($btnCar)
$btnCriar=New-Button 'CRIAR MES' 105;$btnCriar.Add_Click({Create-CurrentScale});$pEsc.Controls.Add($btnCriar)
$btnBlocos=New-Button 'CONFIGURAR BLOCOS' 155;$btnBlocos.Add_Click({Show-ScaleBlocksManager});$pEsc.Controls.Add($btnBlocos)
$btnAssist=New-Button 'ASSISTENTE PASSO A PASSO' 190;Set-PrimaryButton $btnAssist;$btnAssist.Add_Click({Show-WorkflowAssistant});$pEsc.Controls.Add($btnAssist);$pEsc.SetFlowBreak($btnAssist,$true)

$pEsc.Controls.Add((New-GroupLabel 'ESCALA'))
$btnOcEsc=New-Button '+ OCORRENCIA' 125;Set-PrimaryButton $btnOcEsc;$btnOcEsc.Add_Click({
    try{
        $g=$script:gridEscala
        if($null -eq $g.CurrentRow -or [string]$g.CurrentRow.Cells['_TIPO'].Value -ne 'SERVIDOR'){Show-Info 'Selecione primeiro uma linha de servidor para lancar Ferias/Atestado.';return}
        $esid=[int]$g.CurrentRow.Cells['_ID'].Value
        $svId=[int](Db-Scalar "SELECT servidor_id FROM escala_servidores WHERE id=$esid;")
        $setId=Get-SelectedSetorId
        if($svId -le 0 -or $setId -le 0){Show-Info 'Nao foi possivel identificar servidor/setor.';return}

        # Se o usuario tiver selecionado celulas de dia (colunas D01..D31) na
        # linha atual, usa o menor/maior dia selecionado como Data Inicial/Final
        # sugerida no formulario de ocorrencia, poupando digitacao manual.
        $preIni=$null;$preFim=$null
        $diasSel=New-Object System.Collections.ArrayList
        foreach($c in $g.SelectedCells){
            if($c.OwningRow -eq $g.CurrentRow -and $c.OwningColumn.Name -match '^D(\d\d)$'){[void]$diasSel.Add([int]$matches[1])}
        }
        if($diasSel.Count -gt 0){
            $ano=[int]$script:numAno.Value;$mes=[int]$script:cboMes.SelectedValue
            $diaMin=($diasSel | Measure-Object -Minimum).Minimum
            $diaMax=($diasSel | Measure-Object -Maximum).Maximum
            $preIni=Get-Date -Year $ano -Month $mes -Day $diaMin
            $preFim=Get-Date -Year $ano -Month $mes -Day $diaMax
        }

        Show-OcorrenciaDialog 0 $svId $setId $preIni $preFim
    }catch{Show-Error $_.Exception.Message}
});$pEsc.Controls.Add($btnOcEsc)
$btnOrdenarCargo=New-Button 'ORDENAR POR CARGO' 175;$btnOrdenarCargo.Add_Click({Sort-CurrentScaleByFuncao});$pEsc.Controls.Add($btnOrdenarCargo)
$btnPreview=New-Button 'PRE-VISUALIZAR' 135;Set-PrimaryButton $btnPreview;$btnPreview.Add_Click({Show-ScalePreviewComChecklist $script:chkPreviewLegenda.Checked});$pEsc.Controls.Add($btnPreview)
$btnPreviewCombinado=New-Button 'PRE-VISUALIZAR COMBINADO' 200;$btnPreviewCombinado.Add_Click({Show-ScalePreviewCombinado $script:chkPreviewLegenda.Checked});$pEsc.Controls.Add($btnPreviewCombinado)
$script:chkPreviewLegenda=New-Object System.Windows.Forms.CheckBox;$script:chkPreviewLegenda.Text='Legenda';$script:chkPreviewLegenda.AutoSize=$true;$script:chkPreviewLegenda.Checked=(Get-ConfigBool 'impressao_legenda' $true);$script:chkPreviewLegenda.Margin=New-Object System.Windows.Forms.Padding(4,14,10,0);$pEsc.Controls.Add($script:chkPreviewLegenda)
$tipPreviewLegenda=New-Object System.Windows.Forms.ToolTip;$tipPreviewLegenda.SetToolTip($script:chkPreviewLegenda,'Marca ou desmarca a tabela de legenda das siglas so nesta pre-visualizacao/impressao, sem mudar o padrao salvo em Configuracoes > Impressao. Ao salvar la um novo padrao de legenda, esta caixa acompanha.')
$btnCal=New-Button 'CALENDARIO' 110;$btnCal.Add_Click({Show-CalendarioEscala});$pEsc.Controls.Add($btnCal)
$script:btnMaisOpcoes=New-Button 'MAIS OPCOES >>' 140;$script:btnMaisOpcoes.Add_Click({Toggle-ModoAvancadoEscala});$pEsc.Controls.Add($script:btnMaisOpcoes)
$lblBusca=New-ToolbarLabel 'Buscar' 50;$lblBusca.Margin=New-Object System.Windows.Forms.Padding(14,10,3,0);$pEsc.Controls.Add($lblBusca)
$script:txtBuscaEscala=New-Object System.Windows.Forms.TextBox;$script:txtBuscaEscala.Width=170;$script:txtBuscaEscala.Margin=New-Object System.Windows.Forms.Padding(0,8,8,0);$pEsc.Controls.Add($script:txtBuscaEscala)
$script:tipBuscaEscala=New-Object System.Windows.Forms.ToolTip
$script:tipBuscaEscala.SetToolTip($script:txtBuscaEscala,'Servidor / CP / Funcao / Coren. Numero = busca exata em CP/Coren. Texto = busca por parte.')
$script:txtBuscaEscala.Add_TextChanged({Filter-EscalaGridByServidor $script:txtBuscaEscala.Text})
$lblDicaMover=New-Object System.Windows.Forms.Label;$lblDicaMover.Text='Dica: clique direito no BLOCO para adicionar servidores em lote/mover; clique direito no SERVIDOR para mover/remover; duplo clique no NOME do servidor abre o cadastro.';$lblDicaMover.AutoSize=$true;$lblDicaMover.Font=New-Object System.Drawing.Font('Segoe UI',7.5,[System.Drawing.FontStyle]::Italic);$lblDicaMover.ForeColor=[System.Drawing.Color]::FromArgb(140,148,158);$lblDicaMover.Margin=New-Object System.Windows.Forms.Padding(8,18,0,0);$pEsc.Controls.Add($lblDicaMover);$pEsc.SetFlowBreak($lblDicaMover,$true)

$script:lblGrupoAvancado=(New-GroupLabel 'AVANCADO')
$pEsc.Controls.Add($script:lblGrupoAvancado)
$script:btnLote=New-Button 'LOTACAO EM LOTE' 145;Set-PrimaryButton $script:btnLote;$script:btnLote.Add_Click({Show-LotacaoLoteEscalaDialog});$pEsc.Controls.Add($script:btnLote)
$script:btnDelDias=New-Button 'EXCLUIR DIAS' 105;$script:btnDelDias.Add_Click({Delete-SelectedScaleDays});$pEsc.Controls.Add($script:btnDelDias)
$script:btnVaga=New-Button 'ESCALA VAGA' 112;$script:btnVaga.Add_Click({
    $vid=0
    $hidCtx=0
    $linha=$null
    if($script:gridEscala.SelectedCells.Count -gt 0){$linha=$script:gridEscala.SelectedCells[0].OwningRow}
    elseif($null -ne $script:gridEscala.CurrentRow){$linha=$script:gridEscala.CurrentRow}
    if($null -ne $linha){
        $tipo=[string]$linha.Cells['_TIPO'].Value
        if($tipo -eq 'VAGA'){$vid=[int]$linha.Cells['_VAGA_ID'].Value}
        $hidCtx=[int]$linha.Cells['_HORARIO_ID'].Value
    }
    Show-EscalaVagaManager $vid $hidCtx
});$pEsc.Controls.Add($script:btnVaga);$pEsc.SetFlowBreak($script:btnVaga,$true)
$script:AdvancedEscalaControls=@($script:lblGrupoAvancado,$script:btnLote,$script:btnDelDias,$script:btnVaga)
foreach($ctl in $script:AdvancedEscalaControls){$ctl.Visible=$false}

# V1.0.14.80 - Paineis visuais opcionais da aba Escala.
$script:pEscDashboard=New-Object System.Windows.Forms.FlowLayoutPanel
$script:pEscDashboard.Dock='Top';$script:pEscDashboard.Height=80;$script:pEscDashboard.Padding=New-Object Windows.Forms.Padding(8,4,4,4);$script:pEscDashboard.WrapContents=$false;$script:pEscDashboard.BackColor=[Drawing.Color]::FromArgb(245,249,253);$script:pEscDashboard.Visible=$false
$tabEsc.Controls.Add($script:pEscDashboard)
$c1=New-ScaleInfoCard 'Total de servidores' '0' ([Drawing.Color]::FromArgb(49,130,206)) 210;$script:cardServValue=$c1.Tag;$script:pEscDashboard.Controls.Add($c1)
$c2=New-ScaleInfoCard 'Escalas preenchidas' '0' ([Drawing.Color]::FromArgb(45,160,90)) 210;$script:cardEscValue=$c2.Tag;$script:pEscDashboard.Controls.Add($c2)
$c3=New-ScaleInfoCard 'Escalas vagas' '0' ([Drawing.Color]::FromArgb(220,70,70)) 190;$script:cardVagaValue=$c3.Tag;$script:pEscDashboard.Controls.Add($c3)
$c4=New-ScaleInfoCard 'Pendencias' '0' ([Drawing.Color]::FromArgb(232,145,45)) 180;$script:cardPendValue=$c4.Tag;$script:pEscDashboard.Controls.Add($c4)
$c5=New-ScaleInfoCard 'Mes / Competencia' '-' ([Drawing.Color]::FromArgb(116,77,169)) 245;$script:cardMesValue=$c5.Tag;$script:pEscDashboard.Controls.Add($c5)

$script:pEscGuided=New-Object System.Windows.Forms.Panel;$script:pEscGuided.Dock='Top';$script:pEscGuided.Height=54;$script:pEscGuided.BackColor=[Drawing.Color]::FromArgb(248,251,255);$script:pEscGuided.Visible=$false;$tabEsc.Controls.Add($script:pEscGuided)
$gx=12
foreach($gt in @('1  SELECIONE SETOR / MES','2  CARREGUE OU CRIE O MES','3  EDITE A GRADE E CONFIRA')){
    $gl=New-Object Windows.Forms.Label;$gl.Text=$gt;$gl.Location=[Drawing.Point]::new($gx,12);$gl.Size=[Drawing.Size]::new(300,30);$gl.TextAlign='MiddleCenter';$gl.BackColor=[Drawing.Color]::White;$gl.ForeColor=[Drawing.Color]::FromArgb(18,86,150);$gl.BorderStyle='FixedSingle';$gl.Font=New-Object Drawing.Font('Segoe UI Semibold',9);$script:pEscGuided.Controls.Add($gl);$gx+=312
}

$script:pEscLateral=New-Object System.Windows.Forms.Panel;$script:pEscLateral.Dock='Right';$script:pEscLateral.Width=215;$script:pEscLateral.Padding=New-Object Windows.Forms.Padding(10);$script:pEscLateral.BackColor=[Drawing.Color]::FromArgb(248,250,252);$script:pEscLateral.Visible=$false;$tabEsc.Controls.Add($script:pEscLateral);$script:pEscLateral.BringToFront()
$ll=New-Object Windows.Forms.Label;$ll.Text='PAINEL RAPIDO';$ll.Dock='Top';$ll.Height=30;$ll.Font=New-Object Drawing.Font('Segoe UI Semibold',11);$ll.ForeColor=[Drawing.Color]::FromArgb(25,58,88);$script:pEscLateral.Controls.Add($ll)
$script:lblLateralResumo=New-Object Windows.Forms.Label;$script:lblLateralResumo.Dock='Top';$script:lblLateralResumo.Height=76;$script:lblLateralResumo.Padding=New-Object Windows.Forms.Padding(0,6,0,0);$script:lblLateralResumo.Text='Servidores: 0';$script:pEscLateral.Controls.Add($script:lblLateralResumo)
$leg=New-Object Windows.Forms.Label;$leg.Dock='Top';$leg.Height=150;$leg.Text="LEGENDA RAPIDA`r`n`r`nFS  Folga Semana`r`nFF  Folga Feriado`r`nFE  Ferias`r`nA   Atestado`r`n-   Sem escala";$leg.BackColor=[Drawing.Color]::White;$leg.BorderStyle='FixedSingle';$leg.Padding=New-Object Windows.Forms.Padding(8);$script:pEscLateral.Controls.Add($leg)
$la=New-Object Windows.Forms.Label;$la.Dock='Top';$la.Height=35;$la.Text='ACOES RAPIDAS';$la.Padding=New-Object Windows.Forms.Padding(0,12,0,0);$la.Font=New-Object Drawing.Font('Segoe UI Semibold',9);$script:pEscLateral.Controls.Add($la)
foreach($pair in @(@('OCORRENCIA',$btnOcEsc),@('PRE-VISUALIZAR',$btnPreview),@('CALENDARIO',$btnCal),@('MAIS OPCOES',$script:btnMaisOpcoes))){
    $b=New-Button $pair[0] 175;$b.Dock='Top';$b.Height=34;$b.Margin=New-Object Windows.Forms.Padding(0,4,0,0);$target=$pair[1];$b.Add_Click({$this.Tag.PerformClick()});$b.Tag=$target;$script:pEscLateral.Controls.Add($b);$b.BringToFront()
}
$script:lblEscalaStatus=New-Object System.Windows.Forms.Label;$script:lblEscalaStatus.Dock='Bottom';$script:lblEscalaStatus.Height=26;$script:lblEscalaStatus.Padding=New-Object System.Windows.Forms.Padding(10,5,0,0);$script:lblEscalaStatus.Text='';$tabEsc.Controls.Add($script:lblEscalaStatus)
$script:gridEscala=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridEscala;$script:gridEscala.AutoSizeRowsMode='None';$script:gridEscala.RowTemplate.Height=24;$script:gridEscala.SelectionMode='CellSelect';$script:gridEscala.MultiSelect=$true;$tabEsc.Controls.Add($script:gridEscala);$script:gridEscala.BringToFront()
$script:gridEscala.Add_Resize({if($null -ne (Get-Command Apply-ScaleDayColumnWidth -ErrorAction SilentlyContinue)){Apply-ScaleDayColumnWidth $script:gridEscala}})

# Estado vazio guiado: cobre a grade quando ainda nao ha setor selecionado ou
# ainda nao existe escala para o mes/ano atuais, com uma chamada de acao clara
# em vez de deixar a grade simplesmente em branco.
$script:pEscVazio=New-Object System.Windows.Forms.Panel;$script:pEscVazio.Dock='Fill';$script:pEscVazio.BackColor=[System.Drawing.Color]::White;$script:pEscVazio.Visible=$false;$tabEsc.Controls.Add($script:pEscVazio)
$script:vazioBox=New-Object System.Windows.Forms.Panel;$script:vazioBox.Size=[Drawing.Size]::new(480,170);$script:vazioBox.BackColor=[System.Drawing.Color]::White;$script:pEscVazio.Controls.Add($script:vazioBox)
$script:lblVazioTitulo=New-Object System.Windows.Forms.Label;$script:lblVazioTitulo.Font=New-Object System.Drawing.Font('Segoe UI Semibold',13);$script:lblVazioTitulo.ForeColor=[System.Drawing.Color]::FromArgb(51,65,85);$script:lblVazioTitulo.TextAlign='MiddleCenter';$script:lblVazioTitulo.Size=[Drawing.Size]::new(480,32);$script:lblVazioTitulo.Location=[Drawing.Point]::new(0,0);$script:vazioBox.Controls.Add($script:lblVazioTitulo)
$script:lblVazioSub=New-Object System.Windows.Forms.Label;$script:lblVazioSub.Font=New-Object System.Drawing.Font('Segoe UI',9.5);$script:lblVazioSub.ForeColor=[System.Drawing.Color]::FromArgb(100,116,139);$script:lblVazioSub.TextAlign='MiddleCenter';$script:lblVazioSub.Size=[Drawing.Size]::new(480,50);$script:lblVazioSub.Location=[Drawing.Point]::new(0,40);$script:vazioBox.Controls.Add($script:lblVazioSub)
$script:btnVazioAcao=New-Button 'CRIAR MES' 170;Set-PrimaryButton $script:btnVazioAcao;$script:btnVazioAcao.Height=38;$script:btnVazioAcao.Location=[Drawing.Point]::new(155,105);$script:btnVazioAcao.Add_Click({Create-CurrentScale});$script:vazioBox.Controls.Add($script:btnVazioAcao)
$script:pEscVazio.Add_Resize({
    $script:vazioBox.Left=[Math]::Max(0,[int](($script:pEscVazio.Width-$script:vazioBox.Width)/2))
    $script:vazioBox.Top=[Math]::Max(0,[int](($script:pEscVazio.Height-$script:vazioBox.Height)/2))
})

# V1.0.14.76 - Pre-declaracao exigida pelo StrictMode: cache de largura de caracteres (Get-TextWidthMm),
# usado na abreviacao de nomes da impressao (V1.0.14.74).
$script:HelveticaWidthTable=$null

# Barra de "Desfazer" generica: aparece por alguns segundos apos remover um
# servidor ou excluir dias/ocorrencias, com opcao de reverter na hora.
$script:LastUndo=$null
$script:pUndoBar=New-Object System.Windows.Forms.Panel;$script:pUndoBar.Dock='Bottom';$script:pUndoBar.Height=38;$script:pUndoBar.BackColor=[System.Drawing.Color]::FromArgb(51,65,85);$script:pUndoBar.Visible=$false;$tabEsc.Controls.Add($script:pUndoBar)
$script:lblUndoMsg=New-Object System.Windows.Forms.Label;$script:lblUndoMsg.ForeColor=[System.Drawing.Color]::White;$script:lblUndoMsg.Location=[Drawing.Point]::new(14,9);$script:lblUndoMsg.Size=[Drawing.Size]::new(760,22);$script:lblUndoMsg.Text='';$script:pUndoBar.Controls.Add($script:lblUndoMsg)
$script:lnkUndo=New-Object System.Windows.Forms.LinkLabel;$script:lnkUndo.LinkColor=[System.Drawing.Color]::FromArgb(147,197,253);$script:lnkUndo.ActiveLinkColor=[System.Drawing.Color]::White;$script:lnkUndo.Text='DESFAZER';$script:lnkUndo.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$script:lnkUndo.Location=[Drawing.Point]::new(790,9);$script:lnkUndo.AutoSize=$true;$script:pUndoBar.Controls.Add($script:lnkUndo)
$script:tmrUndo=New-Object System.Windows.Forms.Timer;$script:tmrUndo.Interval=8000
$script:tmrUndo.Add_Tick({$script:tmrUndo.Stop();$script:pUndoBar.Visible=$false;$script:LastUndo=$null})
$script:lnkUndo.Add_Click({Invoke-LastUndo})
# Desenha FERIAS/ATESTADO/ESCALA VAGA como faixa continua, sem linhas verticais internas.
$script:gridEscala.Add_CellPainting({param($sender,$e)
    if($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){return}
    $cell=$sender.Rows[$e.RowIndex].Cells[$e.ColumnIndex];$tag=$cell.Tag
    if($null -eq $tag){return}
    $isRange=$false;$isRange=[bool]$tag.EscalaRange
    if(-not $isRange){return}
    $rect=$e.CellBounds
    $back=[System.Drawing.Color]::FromArgb([int]$tag.BackArgb);$fore=[System.Drawing.Color]::FromArgb([int]$tag.ForeArgb)
    if(($e.State -band [System.Windows.Forms.DataGridViewElementStates]::Selected) -ne 0){$back=$sender.DefaultCellStyle.SelectionBackColor}
    $br=New-Object System.Drawing.SolidBrush($back);$e.Graphics.FillRectangle($br,$rect);$br.Dispose()
    $pen=New-Object System.Drawing.Pen($sender.GridColor)
    $e.Graphics.DrawLine($pen,$rect.Left,$rect.Top,$rect.Right,$rect.Top);$e.Graphics.DrawLine($pen,$rect.Left,$rect.Bottom-1,$rect.Right,$rect.Bottom-1)
    $day=0;$day=[int]$sender.Columns[$e.ColumnIndex].Name.Substring(1)
    if($day -eq [int]$tag.Inicio){$e.Graphics.DrawLine($pen,$rect.Left,$rect.Top,$rect.Left,$rect.Bottom)}
    if($day -eq [int]$tag.Fim){$e.Graphics.DrawLine($pen,$rect.Right-1,$rect.Top,$rect.Right-1,$rect.Bottom)}
    $pen.Dispose()
    $e.Handled=$true
})
# Desenha o texto da faixa DEPOIS de todas as celulas da linha, ocupando o intervalo inteiro.
# Isso evita que ATESTADO/FERIAS fiquem cortados em uma unica celula de dia.
$script:gridEscala.Add_RowPostPaint({param($sender,$e)
    if($e.RowIndex -lt 0){return}
    $row=$sender.Rows[$e.RowIndex]
    $ranges=@{}
    foreach($cell in $row.Cells){
        $tag=$cell.Tag;if($null -eq $tag){continue}
        $isRange=$false;$isRange=[bool]$tag.EscalaRange
        if(-not $isRange){continue}
        $key=('{0}|{1}|{2}' -f [int]$tag.Inicio,[int]$tag.Fim,[string]$tag.Texto)
        if(-not $ranges.ContainsKey($key)){$ranges[$key]=$tag}
    }
    foreach($tag in $ranges.Values){
        $c1=('D{0:00}' -f [int]$tag.Inicio);$c2=('D{0:00}' -f [int]$tag.Fim)
        if(-not $sender.Columns.Contains($c1) -or -not $sender.Columns.Contains($c2)){continue}
        $i1=$sender.Columns[$c1].Index;$i2=$sender.Columns[$c2].Index
        # Usa apenas as celulas atualmente visiveis do intervalo. Assim o texto continua
        # centralizado mesmo quando o usuario esta rolando horizontalmente no meio da faixa.
        $left=$null;$right=$null
        for($ci=$i1;$ci -le $i2;$ci++){
            $rr=$sender.GetCellDisplayRectangle($ci,$e.RowIndex,$true)
            if($rr.Width -le 0 -or $rr.Right -le 0 -or $rr.Left -ge $sender.ClientSize.Width){continue}
            if($null -eq $left -or $rr.Left -lt $left){$left=$rr.Left}
            if($null -eq $right -or $rr.Right -gt $right){$right=$rr.Right}
        }
        if($null -eq $left -or $null -eq $right -or $right -le $left){continue}
        $rect=New-Object System.Drawing.Rectangle([int]$left,$e.RowBounds.Top,[int]($right-$left),$e.RowBounds.Height)
        $clip=[System.Drawing.Rectangle]::Intersect($rect,$sender.ClientRectangle)
        if($clip.Width -le 2){continue}
        $fore=[System.Drawing.Color]::FromArgb([int]$tag.ForeArgb)
        [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics,[string]$tag.Texto,$row.InheritedStyle.Font,$clip,$fore,[System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::SingleLine -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis)
    }
})
# Menu rapido de siglas na propria celula da escala.
$ctxEsc=New-Object System.Windows.Forms.ContextMenuStrip
$ctxEsc.ShowImageMargin=$false;$ctxEsc.Font=New-Object System.Drawing.Font('Segoe UI',9);$ctxEsc.BackColor=[System.Drawing.Color]::White;$ctxEsc.ForeColor=[System.Drawing.Color]::FromArgb(27,50,73)
$script:gridEscala.ContextMenuStrip=$ctxEsc

# No clique direito, prepara o contexto conforme o ponto clicado:
# - cabecalho cinza do bloco: comandos para mover o bloco;
# - nome do servidor: comando para remover da escala mensal;
# - celula de dia: menu rapido de siglas, preservando selecao multipla.
$script:gridEscala.Add_CellMouseDown({param($sender,$e)
    if($e.Button -ne [System.Windows.Forms.MouseButtons]::Right -or $e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){return}
    $row=$sender.Rows[$e.RowIndex];$colName=$sender.Columns[$e.ColumnIndex].Name;$tipo=[string]$row.Cells['_TIPO'].Value
    $cell=$row.Cells[$e.ColumnIndex]

    if($tipo -eq 'BLOCO'){
        $sender.ClearSelection()
        $sender.CurrentCell=$cell
        $cell.Selected=$true
        return
    }
    if($tipo -eq 'SERVIDOR' -and $colName -eq 'Servidor'){
        $sender.ClearSelection()
        $sender.CurrentCell=$cell
        $cell.Selected=$true
        return
    }
    if($tipo -eq 'SERVIDOR' -and $colName -match '^D\d\d$'){
        if(-not $cell.Selected){$sender.ClearSelection();$cell.Selected=$true}
        $sender.CurrentCell=$cell
        return
    }
})

# Reconstroi o menu ao abrir conforme o tipo de linha/celula.
$ctxEsc.Add_Opening({param($sender,$e)
    $sender.Items.Clear()
    $g=$script:gridEscala
    if($null -eq $g -or $null -eq $g.CurrentCell){$e.Cancel=$true;return}
    $cell=$g.CurrentCell;$row=$g.Rows[$cell.RowIndex];$colName=$g.Columns[$cell.ColumnIndex].Name;$tipo=[string]$row.Cells['_TIPO'].Value

    if($tipo -eq 'BLOCO'){
        $hidBloco=0
        $hidBloco=[int]$row.Cells['_HORARIO_ID'].Value

        $title=New-Object System.Windows.Forms.ToolStripMenuItem
        $title.Text='BLOCO DE HORARIO'
        $title.Enabled=$false
        [void]$sender.Items.Add($title)
        [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $hidCapturado=$hidBloco
        # V1.0.14.32 - o bloco oferece somente o fluxo em lote. Para um unico
        # servidor, basta filtrar/selecionar apenas uma linha dentro da mesma tela.
        $miAddLote=New-Object System.Windows.Forms.ToolStripMenuItem
        $miAddLote.Text='+ Adicionar servidores em lote neste bloco'
        $miAddLote.Add_Click({Show-LotacaoLoteEscalaDialog $hidCapturado}.GetNewClosure())
        [void]$sender.Items.Add($miAddLote)

        [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $miUp=New-Object System.Windows.Forms.ToolStripMenuItem
        $miUp.Text='Subir bloco'
        $miUp.Add_Click({Move-CurrentScaleBlock 'UP'})
        [void]$sender.Items.Add($miUp)

        $miDown=New-Object System.Windows.Forms.ToolStripMenuItem
        $miDown.Text='Descer bloco'
        $miDown.Add_Click({Move-CurrentScaleBlock 'DOWN'})
        [void]$sender.Items.Add($miDown)

        [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $miFirst=New-Object System.Windows.Forms.ToolStripMenuItem
        $miFirst.Text='Mover para o primeiro'
        $miFirst.Add_Click({Move-CurrentScaleBlock 'FIRST'})
        [void]$sender.Items.Add($miFirst)

        $miLast=New-Object System.Windows.Forms.ToolStripMenuItem
        $miLast.Text='Mover para o ultimo'
        $miLast.Add_Click({Move-CurrentScaleBlock 'LAST'})
        [void]$sender.Items.Add($miLast)
        return
    }

    if($tipo -eq 'SERVIDOR' -and $colName -eq 'Servidor'){
        $title=New-Object System.Windows.Forms.ToolStripMenuItem
        $title.Text='MOVER SERVIDOR NA ESCALA'
        $title.Enabled=$false
        [void]$sender.Items.Add($title)
        [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $miUpSrv=New-Object System.Windows.Forms.ToolStripMenuItem
        $miUpSrv.Text='Subir servidor'
        $miUpSrv.Add_Click({Move-CurrentScaleServidor 'UP'})
        [void]$sender.Items.Add($miUpSrv)

        $miDownSrv=New-Object System.Windows.Forms.ToolStripMenuItem
        $miDownSrv.Text='Descer servidor'
        $miDownSrv.Add_Click({Move-CurrentScaleServidor 'DOWN'})
        [void]$sender.Items.Add($miDownSrv)

        [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $miRemSrv=New-Object System.Windows.Forms.ToolStripMenuItem
        $miRemSrv.Text='Remover da escala (- SERVIDOR)'
        $miRemSrv.Add_Click({Remove-ServidorEscala})
        [void]$sender.Items.Add($miRemSrv)
        return
    }

    if($tipo -ne 'SERVIDOR' -or $colName -notmatch '^D\d\d$'){$e.Cancel=$true;return}
    if($script:SiglaCache.Count -eq 0){Load-SiglaCache}

    $title=New-Object System.Windows.Forms.ToolStripMenuItem
    $title.Text='APLICAR SIGLA RAPIDA'
    $title.Enabled=$false
    [void]$sender.Items.Add($title)
    [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $quickText=Get-ConfigValue 'menu_siglas_rapidas' 'FC,FF,PT,C1,C2,C3,FS,PF'
    $quick=@($quickText -split '[,;]' | ForEach-Object {$_.Trim().ToUpperInvariant()} | Where-Object {$_ -and $_ -notin @('FER','AT')} | Select-Object -Unique)
    foreach($sg in $quick){
        if($sg -in @('FER','AT') -or -not $script:SiglaCache.ContainsKey($sg)){continue}
        $cfg=$script:SiglaCache[$sg]
        $mi=New-Object System.Windows.Forms.ToolStripMenuItem
        $mi.Text=('{0} - {1}' -f $sg,[string]$cfg.Descricao)
        $mi.Tag=$sg
        $mi.BackColor=Color-FromHex ([string]$cfg.Fundo) ([System.Drawing.Color]::White);$mi.ForeColor=Color-FromHex ([string]$cfg.Fonte) ([System.Drawing.Color]::Black)
        $mi.Add_Click({param($m,$ev);Apply-QuickSiglaToSelection ([string]$m.Tag)})
        [void]$sender.Items.Add($mi)
    }

    $more=New-Object System.Windows.Forms.ToolStripMenuItem
    $more.Text='Mais siglas...'
    $others=@($script:SiglaCache.Keys | Where-Object {$_ -notin $quick -and $_ -notin @('FER','AT')} | Sort-Object)
    foreach($sg in $others){
        $cfg=$script:SiglaCache[$sg]
        $mi=New-Object System.Windows.Forms.ToolStripMenuItem
        $mi.Text=('{0} - {1}' -f $sg,[string]$cfg.Descricao)
        $mi.Tag=$sg
        $mi.BackColor=Color-FromHex ([string]$cfg.Fundo) ([System.Drawing.Color]::White);$mi.ForeColor=Color-FromHex ([string]$cfg.Fonte) ([System.Drawing.Color]::Black)
        $mi.Add_Click({param($m,$ev);Apply-QuickSiglaToSelection ([string]$m.Tag)})
        [void]$more.DropDownItems.Add($mi)
    }
    if($others.Count -eq 0){$more.Enabled=$false}
    [void]$sender.Items.Add($more)
    [void]$sender.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $miEditor=New-Object System.Windows.Forms.ToolStripMenuItem
    $miEditor.Text='Editor completo / texto livre...'
    $miEditor.Add_Click({Open-CurrentDayEditor})
    [void]$sender.Items.Add($miEditor)

    $miDel=New-Object System.Windows.Forms.ToolStripMenuItem
    $miDel.Text='Excluir dias/siglas selecionados'
    $miDel.Add_Click({Delete-SelectedScaleDays})
    [void]$sender.Items.Add($miDel)
})

$script:gridEscala.Add_KeyDown({param($sender,$e);if($e.KeyCode -eq [System.Windows.Forms.Keys]::Delete){Delete-SelectedScaleDays;$e.SuppressKeyPress=$true;$e.Handled=$true}})
function Open-ServidorFromEscalaRow {
    # V1.0.14.46 - duplo clique no nome/CP/funcao/Coren do servidor (aba Escala) abre o cadastro do servidor.
    # So recarrega a escala se algum dado do servidor realmente mudou (preserva rolagem/selecao ao cancelar).
    param($Row)
    try{
        $esid=0;$esid=[int]$Row.Cells['_ID'].Value
        if($esid -le 0){return}
        $sid=[int](Db-Scalar ("SELECT COALESCE((SELECT servidor_id FROM escala_servidores WHERE id={0}),0);" -f $esid))
        if($sid -le 0){Show-Info 'Nao foi possivel identificar o servidor desta linha.';return}
        $sqlSig=("SELECT COALESCE(nome,'')||'|'||COALESCE(cp,'')||'|'||COALESCE(funcao,'')||'|'||COALESCE(tipo_vinculo,'')||'|'||COALESCE(sub_funcao,'')||'|'||COALESCE(coren,'')||'|'||COALESCE(ativo,'')||'|'||COALESCE(coren_dispensado,'') FROM servidores WHERE id={0};" -f $sid)
        $antes=[string](Db-Scalar $sqlSig)
        Show-ServidorDialog $sid $script:MainForm | Out-Null
        $depois=[string](Db-Scalar $sqlSig)
        if($antes -ne $depois){Load-Escala}
    }catch{Show-Error $_.Exception.Message}
}

$script:gridEscala.Add_CellDoubleClick({param($sender,$e);if($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0){return};$row=$script:gridEscala.Rows[$e.RowIndex];$tipo=[string]$row.Cells['_TIPO'].Value;if($tipo -eq 'BLOCO'){return};if($tipo -eq 'VAGA'){$vid=0;$vid=[int]$row.Cells['_VAGA_ID'].Value;if($vid -gt 0 -and (Show-EscalaVagaDialog $vid $script:CurrentScaleId)){Load-Escala};return};if($tipo -ne 'SERVIDOR'){return};$name=$script:gridEscala.Columns[$e.ColumnIndex].Name;if($name -notmatch '^D\d\d$'){Open-ServidorFromEscalaRow $row;return};$esid=[int]$row.Cells['_ID'].Value;$day=[int]$name.Substring(1);$dt=Get-Date -Year ([int]$script:numAno.Value) -Month ([int]$script:cboMes.SelectedValue) -Day $day;Show-DiaDialog $esid $dt})

# Tab Servidores
$tabSrv=New-Object System.Windows.Forms.TabPage;$tabSrv.Text='Servidores';$tabSrv.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabSrv)|Out-Null
$script:tabSrvMain=$tabSrv
$pSrv=New-Object System.Windows.Forms.FlowLayoutPanel;$pSrv.Dock='Top';$pSrv.Height=58;$pSrv.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$pSrv.WrapContents=$false;$pSrv.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabSrv.Controls.Add($pSrv)
$script:txtBuscaServidor=New-Object System.Windows.Forms.TextBox;$script:txtBuscaServidor.Width=300;$script:txtBuscaServidor.Margin=New-Object System.Windows.Forms.Padding(5,10,5,0);$pSrv.Controls.Add($script:txtBuscaServidor)
$tipBuscaServidor=New-Object System.Windows.Forms.ToolTip;$tipBuscaServidor.SetToolTip($script:txtBuscaServidor,'Use virgula para varios termos. Numeros = CP/Coren exato. Textos = parte do nome. Ex.: 311, 787, Ana Maria, Adalberto.')
$bPes=New-Button 'PESQUISAR' 105;$bPes.Add_Click({Load-Servidores});$pSrv.Controls.Add($bPes)
$script:txtBuscaServidor.Add_KeyDown({param($sender,$e);if($e.KeyCode -eq 'Enter'){Load-Servidores;$e.SuppressKeyPress=$true}})
$bNovo=New-Button 'NOVO' 90;$bNovo.Add_Click({Show-ServidorDialog 0});$pSrv.Controls.Add($bNovo)
$bEdit=New-Button 'EDITAR' 90;$bEdit.Add_Click({$id=Get-GridId $script:gridServidores;if($id){Show-ServidorDialog $id}else{Show-Info 'Selecione um servidor.'}});$pSrv.Controls.Add($bEdit)
$bLoteNovo=New-Button 'CADASTRAR EM LOTE' 175;$bLoteNovo.Add_Click({Show-CadastroServidoresLoteDialog});$pSrv.Controls.Add($bLoteNovo)
$bExcluirSrv=New-Button 'EXCLUIR SELECIONADOS' 195;$bExcluirSrv.Add_Click({Delete-ServidoresSelecionados});$pSrv.Controls.Add($bExcluirSrv)
$script:lblServidorCount=New-Object System.Windows.Forms.Label;$script:lblServidorCount.Dock='Bottom';$script:lblServidorCount.Height=25;$script:lblServidorCount.Padding=New-Object System.Windows.Forms.Padding(10,4,0,0);$tabSrv.Controls.Add($script:lblServidorCount)
$script:gridServidores=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridServidores;$script:gridServidores.MultiSelect=$true;$tabSrv.Controls.Add($script:gridServidores);$script:gridServidores.BringToFront();$script:gridServidores.Add_CellDoubleClick({$id=Get-GridId $script:gridServidores;if($id){Show-ServidorDialog $id}})

# Tab Readaptados (sem Coren) - V1.0.14.23
$tabReadapt=New-Object System.Windows.Forms.TabPage;$tabReadapt.Text='Readaptados';$tabReadapt.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabReadapt)|Out-Null
$script:tabReadaptMain=$tabReadapt
$pReadapt=New-Object System.Windows.Forms.FlowLayoutPanel;$pReadapt.Dock='Top';$pReadapt.Height=58;$pReadapt.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$pReadapt.WrapContents=$false;$pReadapt.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabReadapt.Controls.Add($pReadapt)
$script:txtBuscaReadapt=New-Object System.Windows.Forms.TextBox;$script:txtBuscaReadapt.Width=260;$script:txtBuscaReadapt.Margin=New-Object System.Windows.Forms.Padding(5,10,5,0);$pReadapt.Controls.Add($script:txtBuscaReadapt)
$tipBuscaReadapt=New-Object System.Windows.Forms.ToolTip;$tipBuscaReadapt.SetToolTip($script:txtBuscaReadapt,'Use virgula para varios termos. Numeros = CP/Coren exato. Textos = parte do nome.')
$bPesReadapt=New-Button 'PESQUISAR' 105;$bPesReadapt.Add_Click({Load-Readaptados});$pReadapt.Controls.Add($bPesReadapt)
$script:txtBuscaReadapt.Add_KeyDown({param($sender,$e);if($e.KeyCode -eq 'Enter'){Load-Readaptados;$e.SuppressKeyPress=$true}})
$bMarcarReadapt=New-Button 'MARCAR COREN DISPENSADO' 220;$bMarcarReadapt.Add_Click({Set-DispensaCorenSelecionados $true});$pReadapt.Controls.Add($bMarcarReadapt)
$bDesmarcarReadapt=New-Button 'DESMARCAR' 130;$bDesmarcarReadapt.Add_Click({Set-DispensaCorenSelecionados $false});$pReadapt.Controls.Add($bDesmarcarReadapt)
$bEditarReadapt=New-Button 'EDITAR SERVIDOR' 160;$bEditarReadapt.Add_Click({$id=Get-GridId $script:gridReadaptados;if($id){Show-ServidorDialog $id}else{Show-Info 'Selecione um servidor.'}});$pReadapt.Controls.Add($bEditarReadapt)
$lInfoReadapt=New-Object System.Windows.Forms.Label;$lInfoReadapt.Dock='Top';$lInfoReadapt.Height=32;$lInfoReadapt.Padding=New-Object System.Windows.Forms.Padding(10,4,10,0);$lInfoReadapt.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105)
$lInfoReadapt.Text='Lista todos os servidores ativos dos cargos ENF, TE e AE (os unicos que exigem Coren). Marque "Coren dispensado" para quem foi readaptado e nao precisa mais apresentar Coren.'
$tabReadapt.Controls.Add($lInfoReadapt)
$script:lblReadaptCount=New-Object System.Windows.Forms.Label;$script:lblReadaptCount.Dock='Bottom';$script:lblReadaptCount.Height=25;$script:lblReadaptCount.Padding=New-Object System.Windows.Forms.Padding(10,4,0,0);$tabReadapt.Controls.Add($script:lblReadaptCount)
$script:gridReadaptados=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridReadaptados;$script:gridReadaptados.MultiSelect=$true;$tabReadapt.Controls.Add($script:gridReadaptados);$script:gridReadaptados.BringToFront();$script:gridReadaptados.Add_CellDoubleClick({$id=Get-GridId $script:gridReadaptados;if($id){Show-ServidorDialog $id}})

# Tab Ocorrencias
$tabOc=New-Object System.Windows.Forms.TabPage;$tabOc.Text='Ocorrências';$tabOc.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabOc)|Out-Null
$script:tabOcMain=$tabOc
$pOcTop=New-Object System.Windows.Forms.Panel;$pOcTop.Dock='Top';$pOcTop.Height=190;$tabOc.Controls.Add($pOcTop)

$pOcFilter=New-Object System.Windows.Forms.Panel;$pOcFilter.Dock='Top';$pOcFilter.Height=108;$pOcFilter.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$pOcTop.Controls.Add($pOcFilter)
$lSet=New-Object System.Windows.Forms.Label;$lSet.Text='Setor Principal';$lSet.Location=[Drawing.Point]::new(12,10);$lSet.Size=[Drawing.Size]::new(110,20);$pOcFilter.Controls.Add($lSet)
$script:cboOcSetor=New-Object System.Windows.Forms.ComboBox;$script:cboOcSetor.Location=[Drawing.Point]::new(12,32);$script:cboOcSetor.Size=[Drawing.Size]::new(240,27);$script:cboOcSetor.DropDownStyle='DropDownList';$pOcFilter.Controls.Add($script:cboOcSetor)
$lSub=New-Object System.Windows.Forms.Label;$lSub.Text='Sub_Setor';$lSub.Location=[Drawing.Point]::new(270,10);$lSub.Size=[Drawing.Size]::new(90,20);$pOcFilter.Controls.Add($lSub)
$script:cboOcSubSetor=New-Object System.Windows.Forms.ComboBox;$script:cboOcSubSetor.Location=[Drawing.Point]::new(270,32);$script:cboOcSubSetor.Size=[Drawing.Size]::new(220,27);$script:cboOcSubSetor.DropDownStyle='DropDownList';$pOcFilter.Controls.Add($script:cboOcSubSetor)
$lMes=New-Object System.Windows.Forms.Label;$lMes.Text='Mes';$lMes.Location=[Drawing.Point]::new(508,10);$lMes.Size=[Drawing.Size]::new(55,20);$pOcFilter.Controls.Add($lMes)
$script:cboOcMes=New-Object System.Windows.Forms.ComboBox;$script:cboOcMes.Location=[Drawing.Point]::new(508,32);$script:cboOcMes.Size=[Drawing.Size]::new(135,27);$script:cboOcMes.DropDownStyle='DropDownList';$pOcFilter.Controls.Add($script:cboOcMes)
$ocMonths=New-Object System.Data.DataTable;$ocMonths.Columns.Add('id',[string])|Out-Null;$ocMonths.Columns.Add('nome',[string])|Out-Null;$r=$ocMonths.NewRow();$r['id']='0';$r['nome']='Todos';$ocMonths.Rows.Add($r);for($i=1;$i -le 12;$i++){$r=$ocMonths.NewRow();$r['id']=[string]$i;$r['nome']=$nomes[$i-1];$ocMonths.Rows.Add($r)};$bsTmp11=New-Object System.Windows.Forms.BindingSource;$bsTmp11.DataSource=$ocMonths;$script:cboOcMes.DataSource=$bsTmp11;$script:cboOcMes.ValueMember='id';$script:cboOcMes.DisplayMember='nome'
$lAno=New-Object System.Windows.Forms.Label;$lAno.Text='Ano';$lAno.Location=[Drawing.Point]::new(658,10);$lAno.Size=[Drawing.Size]::new(55,20);$pOcFilter.Controls.Add($lAno)
$script:cboOcAno=New-Object System.Windows.Forms.ComboBox;$script:cboOcAno.Location=[Drawing.Point]::new(658,32);$script:cboOcAno.Size=[Drawing.Size]::new(95,27);$script:cboOcAno.DropDownStyle='DropDownList';$pOcFilter.Controls.Add($script:cboOcAno)
$ocYears=New-Object System.Data.DataTable;$ocYears.Columns.Add('id',[string])|Out-Null;$ocYears.Columns.Add('nome',[string])|Out-Null;$r=$ocYears.NewRow();$r['id']='0';$r['nome']='Todos';$ocYears.Rows.Add($r);for($y=2024;$y -le 2035;$y++){$r=$ocYears.NewRow();$r['id']=[string]$y;$r['nome']=[string]$y;$ocYears.Rows.Add($r)};$bsTmp12=New-Object System.Windows.Forms.BindingSource;$bsTmp12.DataSource=$ocYears;$script:cboOcAno.DataSource=$bsTmp12;$script:cboOcAno.ValueMember='id';$script:cboOcAno.DisplayMember='nome'
$lTipo=New-Object System.Windows.Forms.Label;$lTipo.Text='Tipo';$lTipo.Location=[Drawing.Point]::new(770,10);$lTipo.Size=[Drawing.Size]::new(55,20);$pOcFilter.Controls.Add($lTipo)
$script:cboOcTipo=New-Object System.Windows.Forms.ComboBox;$script:cboOcTipo.Location=[Drawing.Point]::new(770,32);$script:cboOcTipo.Size=[Drawing.Size]::new(180,27);$script:cboOcTipo.DropDownStyle='DropDownList';$pOcFilter.Controls.Add($script:cboOcTipo)
$lBusca=New-Object System.Windows.Forms.Label;$lBusca.Text='Pesquisar CP / Nome / Detalhamento';$lBusca.Location=[Drawing.Point]::new(970,10);$lBusca.Size=[Drawing.Size]::new(220,20);$pOcFilter.Controls.Add($lBusca)
$script:txtOcBusca=New-Object System.Windows.Forms.TextBox;$script:txtOcBusca.Location=[Drawing.Point]::new(970,32);$script:txtOcBusca.Size=[Drawing.Size]::new(260,27);$pOcFilter.Controls.Add($script:txtOcBusca)
$bOcFiltrar=New-Button 'FILTRAR' 95;$bOcFiltrar.Location=[Drawing.Point]::new(1245,27);$bOcFiltrar.Add_Click({Load-OcorrenciaServidores;Load-Ocorrencias});$pOcFilter.Controls.Add($bOcFiltrar)
$bOcLimpar=New-Button 'LIMPAR' 95;$bOcLimpar.Location=[Drawing.Point]::new(1350,27);$bOcLimpar.Add_Click({$script:txtOcBusca.Clear();$script:cboOcSetor.SelectedValue='0';Refresh-OcorrenciaSubSetorCombo;$script:cboOcTipo.SelectedValue='0';$script:cboOcMes.SelectedValue='0';$script:cboOcAno.SelectedValue='0';Load-OcorrenciaServidores;Load-Ocorrencias});$pOcFilter.Controls.Add($bOcLimpar)
$lblOcHelp=New-Object System.Windows.Forms.Label;$lblOcHelp.Text='Selecione Setor Principal + Sub_Setor + Mes/Ano para listar os servidores ja cadastrados naquela Escala Mensal. Depois selecione um servidor e lance a ocorrencia.';$lblOcHelp.Location=[Drawing.Point]::new(12,72);$lblOcHelp.Size=[Drawing.Size]::new(1350,28);$lblOcHelp.ForeColor=[System.Drawing.Color]::FromArgb(65,80,95);$pOcFilter.Controls.Add($lblOcHelp)

$pOcActions=New-Object System.Windows.Forms.FlowLayoutPanel;$pOcActions.Dock='Bottom';$pOcActions.Height=58;$pOcActions.Padding=New-Object System.Windows.Forms.Padding(10,5,4,4);$pOcActions.WrapContents=$false;$pOcTop.Controls.Add($pOcActions)
$bOcNew=New-Button '+ NOVA OCORRENCIA' 160;Set-PrimaryButton $bOcNew;$bOcNew.Add_Click({
    if($null -eq $script:gridOcServidores -or $script:gridOcServidores.Rows.Count -eq 0){Show-Info 'Nenhum servidor na lista. Selecione Setor Principal + Sub_Setor + Mes/Ano com servidores ja cadastrados na Escala Mensal antes de lancar uma ocorrencia.';return}
    if($null -eq $script:gridOcServidores.CurrentRow){Show-Info 'Selecione um servidor na lista antes de lancar uma ocorrencia.';return}
    $sid=0;$setid=0
    $sid=[int]$script:gridOcServidores.CurrentRow.Cells['id'].Value
    $setid=[int]$script:gridOcServidores.CurrentRow.Cells['_SetorEfetivoId'].Value
    Show-OcorrenciaDialog 0 $sid $setid
});$pOcActions.Controls.Add($bOcNew)
$bOcEdit=New-Button 'EDITAR' 100;$bOcEdit.Add_Click({$id=Get-GridId $script:gridOcorrencias;if($id -gt 0){Show-OcorrenciaDialog $id}else{Show-Info 'Selecione uma ocorrencia.'}});$pOcActions.Controls.Add($bOcEdit)
$bOcDel=New-Button 'EXCLUIR' 100;$bOcDel.Add_Click({Delete-Ocorrencia});$pOcActions.Controls.Add($bOcDel)
$bOcRef=New-Button 'ATUALIZAR' 110;$bOcRef.Add_Click({Load-OcorrenciaServidores;Load-Ocorrencias});$pOcActions.Controls.Add($bOcRef)

$splitOc=New-Object System.Windows.Forms.SplitContainer;$splitOc.Dock='Fill';$splitOc.Orientation='Horizontal';$splitOc.SplitterDistance=220;$tabOc.Controls.Add($splitOc);$splitOc.BringToFront()
$script:lblOcSrvInfo=New-Object System.Windows.Forms.Label;$script:lblOcSrvInfo.Dock='Top';$script:lblOcSrvInfo.Height=30;$script:lblOcSrvInfo.Padding=New-Object System.Windows.Forms.Padding(10,5,0,0);$script:lblOcSrvInfo.Text='Servidores da Escala Mensal selecionada';$splitOc.Panel1.Controls.Add($script:lblOcSrvInfo)
$script:gridOcServidores=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridOcServidores;$script:gridOcServidores.Dock='Fill';$splitOc.Panel1.Controls.Add($script:gridOcServidores);$script:gridOcServidores.BringToFront();$script:gridOcServidores.Add_CellDoubleClick({$sid=0;$setid=0;$sid=[int]$script:gridOcServidores.CurrentRow.Cells['id'].Value;$setid=[int]$script:gridOcServidores.CurrentRow.Cells['_SetorEfetivoId'].Value;if($sid -gt 0){Show-OcorrenciaDialog 0 $sid $setid}})
$script:lblOcCount=New-Object System.Windows.Forms.Label;$script:lblOcCount.Dock='Bottom';$script:lblOcCount.Height=25;$script:lblOcCount.Padding=New-Object System.Windows.Forms.Padding(10,4,0,0);$splitOc.Panel2.Controls.Add($script:lblOcCount)
$script:gridOcorrencias=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridOcorrencias;$script:gridOcorrencias.Dock='Fill';$splitOc.Panel2.Controls.Add($script:gridOcorrencias);$script:gridOcorrencias.BringToFront();$script:gridOcorrencias.Add_CellDoubleClick({$id=Get-GridId $script:gridOcorrencias;if($id -gt 0){Show-OcorrenciaDialog $id}})
$script:txtOcBusca.Add_KeyDown({param($sender,$e);if($e.KeyCode -eq 'Enter'){Load-OcorrenciaServidores;Load-Ocorrencias;$e.SuppressKeyPress=$true}})
$script:cboOcSetor.Add_SelectedIndexChanged({Refresh-OcorrenciaSubSetorCombo;Load-OcorrenciaServidores})
$script:cboOcSubSetor.Add_SelectedIndexChanged({Load-OcorrenciaServidores})
$script:cboOcMes.Add_SelectedIndexChanged({Load-OcorrenciaServidores})
$script:cboOcAno.Add_SelectedIndexChanged({Load-OcorrenciaServidores})

# Tab Setores
$tabSet=New-Object System.Windows.Forms.TabPage;$tabSet.Text='Setores';$tabSet.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabSet)|Out-Null
$script:tabSetMain=$tabSet
$pSet=New-Object System.Windows.Forms.FlowLayoutPanel;$pSet.Dock='Top';$pSet.Height=58;$pSet.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$pSet.WrapContents=$false;$pSet.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabSet.Controls.Add($pSet)
$bSetNew=New-Button 'NOVO SETOR' 120;$bSetNew.Add_Click({Show-SetorDialog 0});$pSet.Controls.Add($bSetNew)
$bSetEd=New-Button 'EDITAR SETOR' 120;$bSetEd.Add_Click({$id=Get-GridId $script:gridSetores;if($id){Show-SetorDialog $id}else{Show-Info 'Selecione um Setor Principal.'}});$pSet.Controls.Add($bSetEd)
$bSetDel=New-Button 'EXCLUIR SETOR' 130;$bSetDel.Add_Click({Delete-Setor});$pSet.Controls.Add($bSetDel)
$bSubNew=New-Button 'NOVO SUB_SETOR' 145;$bSubNew.Add_Click({$sid=Get-GridId $script:gridSetores;Show-SubSetorDialog 0 $sid});$pSet.Controls.Add($bSubNew)
$bSubEd=New-Button 'EDITAR SUB_SETOR' 150;$bSubEd.Add_Click({$id=Get-GridId $script:gridSubSetores;if($id){Show-SubSetorDialog $id 0}else{Show-Info 'Selecione um Sub_Setor.'}});$pSet.Controls.Add($bSubEd)
$bSubDel=New-Button 'EXCLUIR SUB_SETOR' 160;$bSubDel.Add_Click({Delete-SubSetor});$pSet.Controls.Add($bSubDel)
$splitSet=New-Object System.Windows.Forms.SplitContainer;$splitSet.Dock='Fill';$splitSet.Orientation='Horizontal';$splitSet.SplitterDistance=310;$tabSet.Controls.Add($splitSet);$splitSet.BringToFront()
$script:gridSetores=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridSetores;$splitSet.Panel1.Controls.Add($script:gridSetores)
$script:gridSubSetores=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridSubSetores;$splitSet.Panel2.Controls.Add($script:gridSubSetores)
$script:gridSetores.Add_SelectionChanged({Load-SubSetores})

# Tab Horarios
$tabHor=New-Object System.Windows.Forms.TabPage;$tabHor.Text='Horários';$tabHor.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabHor)|Out-Null
$script:tabHorMain=$tabHor
$pHor=New-Object System.Windows.Forms.FlowLayoutPanel;$pHor.Dock='Top';$pHor.Height=58;$pHor.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$pHor.WrapContents=$false;$pHor.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabHor.Controls.Add($pHor)
$bHorNew=New-Button 'NOVO HORARIO' 130;$bHorNew.Add_Click({Show-HorarioDialog 0 0});$pHor.Controls.Add($bHorNew)
$bHorEd=New-Button 'EDITAR' 95;$bHorEd.Add_Click({$id=Get-GridId $script:gridHorarios;if($id){Show-HorarioDialog $id 0}else{Show-Info 'Selecione um horario.'}});$pHor.Controls.Add($bHorEd)
$bHorDup=New-Button 'DUPLICAR' 105;$bHorDup.Add_Click({Duplicar-Horario});$pHor.Controls.Add($bHorDup)
$bHorAt=New-Button 'ATIVAR / DESATIVAR' 155;$bHorAt.Add_Click({Toggle-HorarioAtivo});$pHor.Controls.Add($bHorAt)
$bHorRef=New-Button 'ATUALIZAR' 105;$bHorRef.Add_Click({Load-Horarios});$pHor.Controls.Add($bHorRef)
$script:lblHorarioCount=New-Object System.Windows.Forms.Label;$script:lblHorarioCount.Dock='Bottom';$script:lblHorarioCount.Height=25;$script:lblHorarioCount.Padding=New-Object System.Windows.Forms.Padding(10,4,0,0);$tabHor.Controls.Add($script:lblHorarioCount)
$script:gridHorarios=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridHorarios;$tabHor.Controls.Add($script:gridHorarios);$script:gridHorarios.BringToFront();$script:gridHorarios.Add_CellDoubleClick({$id=Get-GridId $script:gridHorarios;if($id){Show-HorarioDialog $id 0}})

# Tab Configuracoes
$tabCfg=New-Object System.Windows.Forms.TabPage;$tabCfg.Text='Siglas';$tabCfg.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabCfg)|Out-Null
$script:tabSiglasMain=$tabCfg
$pCfg=New-Object System.Windows.Forms.FlowLayoutPanel;$pCfg.Dock='Top';$pCfg.Height=58;$pCfg.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$pCfg.WrapContents=$false;$pCfg.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabCfg.Controls.Add($pCfg)
$bSgN=New-Button 'NOVA SIGLA' 115;$bSgN.Add_Click({Show-SiglaDialog 0});$pCfg.Controls.Add($bSgN)
$bSgE=New-Button 'EDITAR SIGLA' 120;$bSgE.Add_Click({$id=Get-GridId $script:gridSiglas;if($id){Show-SiglaDialog $id}else{Show-Info 'Selecione uma sigla.'}});$pCfg.Controls.Add($bSgE)
$bSgDel=New-Button 'EXCLUIR SIGLA' 130;$bSgDel.BackColor=[System.Drawing.Color]::FromArgb(220,38,38);$bSgDel.ForeColor=[System.Drawing.Color]::White;$bSgDel.Add_Click({Remove-SiglaSelecionada});$pCfg.Controls.Add($bSgDel)
$script:gridSiglas=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridSiglas;$tabCfg.Controls.Add($script:gridSiglas);$script:gridSiglas.BringToFront()



# Tab Configuracoes
$tabConf=New-Object System.Windows.Forms.TabPage;$tabConf.Text='Configurações';$tabConf.BackColor=[System.Drawing.Color]::White;$tabs.TabPages.Add($tabConf)|Out-Null
$script:tabConfMain=$tabConf
$pConfTop=New-Object System.Windows.Forms.FlowLayoutPanel;$pConfTop.Dock='Top';$pConfTop.Height=62;$pConfTop.Padding=New-Object System.Windows.Forms.Padding(10,7,4,4);$pConfTop.WrapContents=$true;$pConfTop.FlowDirection='LeftToRight';$pConfTop.AutoScroll=$false;$pConfTop.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$tabConf.Controls.Add($pConfTop)
$bConfSave=New-Button 'SALVAR CONFIGURACOES' 190;Set-PrimaryButton $bConfSave;$bConfSave.Add_Click({Save-ConfiguracoesUI});$pConfTop.Controls.Add($bConfSave)
$bConfReset=New-Button 'RESTAURAR PADRAO' 155;$bConfReset.Add_Click({Restore-ConfigDefaults});$pConfTop.Controls.Add($bConfReset)
$bConfResetSec=New-Button 'RESTAURAR ABA ATUAL' 175;$pConfTop.Controls.Add($bConfResetSec)
$bConfCal=New-Button 'ABRIR CALENDARIO' 155;$bConfCal.Add_Click({Show-CalendarioEscala});$pConfTop.Controls.Add($bConfCal)
$bConfBackup=New-Button 'BACKUP AGORA' 130;$bConfBackup.Add_Click({Backup-Database});$pConfTop.Controls.Add($bConfBackup)
$bConfZerar=New-Button 'ZERAR HISTORICO DE ESCALAS' 240;$bConfZerar.BackColor=[System.Drawing.Color]::FromArgb(220,38,38);$bConfZerar.ForeColor=[System.Drawing.Color]::White;$bConfZerar.Add_Click({Show-ResetHistoricoDialog});$pConfTop.Controls.Add($bConfZerar)
$lblConfigBusca=New-Object System.Windows.Forms.Label;$lblConfigBusca.Text='Buscar';$lblConfigBusca.AutoSize=$true;$lblConfigBusca.Margin=New-Object System.Windows.Forms.Padding(16,15,4,0);$pConfTop.Controls.Add($lblConfigBusca)
$script:txtConfigBusca=New-Object System.Windows.Forms.TextBox;$script:txtConfigBusca.Width=180;$script:txtConfigBusca.Margin=New-Object System.Windows.Forms.Padding(0,11,4,0);$pConfTop.Controls.Add($script:txtConfigBusca)
$script:lblConfigStatus=New-Object System.Windows.Forms.Label;$script:lblConfigStatus.Text='Central de configuracoes';$script:lblConfigStatus.AutoSize=$true;$script:lblConfigStatus.Margin=New-Object System.Windows.Forms.Padding(12,15,0,0);$script:lblConfigStatus.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105);$pConfTop.Controls.Add($script:lblConfigStatus)
$configBuscaTip=New-Object System.Windows.Forms.ToolTip
$configBuscaTip.SetToolTip($script:txtConfigBusca,'Digite por exemplo: margem, legenda, ENF, assinatura, faixa, backup, calendario ou abas.')
$script:txtConfigBusca.Add_TextChanged({Find-ConfigOption $script:txtConfigBusca.Text})

# Reflow responsivo real da barra de Configuracoes.
# O FlowLayoutPanel nem sempre quebra automaticamente de forma confiavel
# quando a janela e redimensionada com AutoScale/DPI. Por isso calculamos
# a largura real dos controles e forcamos uma quebra depois do 3o botao.
$script:LayoutConfigToolbar = {
    try{
        $painel=$pConfTop
        if($null -eq $painel -or $painel.IsDisposed){return}

        $larguraNecessaria=$painel.Padding.Left+$painel.Padding.Right+10
        foreach($ctl in $painel.Controls){
            if($ctl.Visible){
                $larguraNecessaria += $ctl.Width + $ctl.Margin.Left + $ctl.Margin.Right
            }
        }

        $duasLinhas=($painel.ClientSize.Width -lt $larguraNecessaria)

        # Forca a quebra em ponto previsivel:
        # linha 1 = Salvar / Restaurar Padrao / Restaurar Aba Atual
        # linha 2 = Calendario / Backup / Zerar Historico / Status
        $painel.SetFlowBreak($bConfResetSec,$duasLinhas)

        # O FlowLayoutPanel pode usar 2 ou 3 linhas em telas estreitas.
        # Depois do layout, calcula a altura real ocupada pelos controles.
        $painel.PerformLayout()
        $maxBottom=0
        foreach($ctl in $painel.Controls){
            if($ctl.Visible -and $ctl.Bottom -gt $maxBottom){$maxBottom=$ctl.Bottom}
        }
        $alturaAlvo=[Math]::Max(62,($maxBottom+$painel.Padding.Bottom+5))
        if([Math]::Abs($painel.Height-$alturaAlvo) -gt 2){$painel.Height=$alturaAlvo}
    }catch{
        Write-Log ('Falha no reflow da barra de Configuracoes: '+$_.Exception.Message)
    }
}
$pConfTop.Add_Resize({& $script:LayoutConfigToolbar})
& $script:LayoutConfigToolbar

$cfgTabs=New-Object System.Windows.Forms.TabControl;$cfgTabs.Dock='Fill';$cfgTabs.Multiline=$true;$cfgTabs.SizeMode='Normal';$tabConf.Controls.Add($cfgTabs);$cfgTabs.BringToFront()
$script:cfgTabs=$cfgTabs
$bConfResetSec.Add_Click({Restore-ConfigCurrentSection})
$configTip=New-Object System.Windows.Forms.ToolTip;$configTip.AutoPopDelay=9000;$configTip.InitialDelay=350;$configTip.ReshowDelay=150

# Geral / Interface
$pgGeral=New-Object System.Windows.Forms.TabPage;$pgGeral.Text='Geral / Interface';$pgGeral.BackColor=[System.Drawing.Color]::White;$pgGeral.AutoScroll=$true;$cfgTabs.TabPages.Add($pgGeral)|Out-Null
$gTitle=New-Object System.Windows.Forms.Label;$gTitle.Text='Comportamento geral da Escala Mensal';$gTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$gTitle.Location=[Drawing.Point]::new(28,24);$gTitle.AutoSize=$true;$pgGeral.Controls.Add($gTitle)
$gDesc=New-Object System.Windows.Forms.Label;$gDesc.Text='Ajustes desta pagina alteram somente a experiencia de uso. Nenhum cadastro ou lancamento e apagado.';$gDesc.Location=[Drawing.Point]::new(28,55);$gDesc.Size=[Drawing.Size]::new(900,26);$gDesc.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgGeral.Controls.Add($gDesc)
$script:chkAbrirMesAtual=New-Object System.Windows.Forms.CheckBox;$script:chkAbrirMesAtual.Text='Ao abrir o sistema, usar automaticamente o mes e ano atuais';$script:chkAbrirMesAtual.Location=[Drawing.Point]::new(32,98);$script:chkAbrirMesAtual.Size=[Drawing.Size]::new(500,28);$pgGeral.Controls.Add($script:chkAbrirMesAtual)
$lMesPad=New-Object System.Windows.Forms.Label;$lMesPad.Text='Mes padrao';$lMesPad.Location=[Drawing.Point]::new(54,143);$lMesPad.Size=[Drawing.Size]::new(100,24);$pgGeral.Controls.Add($lMesPad)
$script:numMesPadrao=New-Object System.Windows.Forms.NumericUpDown;$script:numMesPadrao.Location=[Drawing.Point]::new(160,140);$script:numMesPadrao.Size=[Drawing.Size]::new(90,27);$script:numMesPadrao.Minimum=1;$script:numMesPadrao.Maximum=12;$pgGeral.Controls.Add($script:numMesPadrao)
$lAnoPad=New-Object System.Windows.Forms.Label;$lAnoPad.Text='Ano padrao';$lAnoPad.Location=[Drawing.Point]::new(285,143);$lAnoPad.Size=[Drawing.Size]::new(100,24);$pgGeral.Controls.Add($lAnoPad)
$script:numAnoPadrao=New-Object System.Windows.Forms.NumericUpDown;$script:numAnoPadrao.Location=[Drawing.Point]::new(390,140);$script:numAnoPadrao.Size=[Drawing.Size]::new(110,27);$script:numAnoPadrao.Minimum=2024;$script:numAnoPadrao.Maximum=2100;$pgGeral.Controls.Add($script:numAnoPadrao)
$script:chkAbrirMesAtual.Add_CheckedChanged({$script:numMesPadrao.Enabled=-not $script:chkAbrirMesAtual.Checked;$script:numAnoPadrao.Enabled=-not $script:chkAbrirMesAtual.Checked})
$lCopy=New-Object System.Windows.Forms.Label;$lCopy.Text='Ao criar um novo mes e existir escala anterior';$lCopy.Location=[Drawing.Point]::new(32,198);$lCopy.Size=[Drawing.Size]::new(330,24);$pgGeral.Controls.Add($lCopy)
$script:cboCopiaMesAnterior=New-Object System.Windows.Forms.ComboBox;$script:cboCopiaMesAnterior.Location=[Drawing.Point]::new(370,195);$script:cboCopiaMesAnterior.Size=[Drawing.Size]::new(300,27);$script:cboCopiaMesAnterior.DropDownStyle='DropDownList';[void]$script:cboCopiaMesAnterior.Items.Add('Perguntar antes de copiar servidores/horarios');[void]$script:cboCopiaMesAnterior.Items.Add('Copiar automaticamente servidores/horarios');[void]$script:cboCopiaMesAnterior.Items.Add('Nao copiar automaticamente');$pgGeral.Controls.Add($script:cboCopiaMesAnterior)
$lDens=New-Object System.Windows.Forms.Label;$lDens.Text='Densidade das grades';$lDens.Location=[Drawing.Point]::new(32,253);$lDens.Size=[Drawing.Size]::new(180,24);$pgGeral.Controls.Add($lDens)
$script:cboDensidade=New-Object System.Windows.Forms.ComboBox;$script:cboDensidade.Location=[Drawing.Point]::new(220,250);$script:cboDensidade.Size=[Drawing.Size]::new(230,27);$script:cboDensidade.DropDownStyle='DropDownList';[void]$script:cboDensidade.Items.Add('Compacta - mais linhas na tela');[void]$script:cboDensidade.Items.Add('Normal - recomendado');[void]$script:cboDensidade.Items.Add('Confortavel - texto maior');$pgGeral.Controls.Add($script:cboDensidade)
$lLargDias=New-Object System.Windows.Forms.Label;$lLargDias.Text='Largura das colunas de datas';$lLargDias.Location=[Drawing.Point]::new(485,253);$lLargDias.Size=[Drawing.Size]::new(205,24);$pgGeral.Controls.Add($lLargDias)
$script:cboLarguraDias=New-Object System.Windows.Forms.ComboBox;$script:cboLarguraDias.Location=[Drawing.Point]::new(690,250);$script:cboLarguraDias.Size=[Drawing.Size]::new(300,27);$script:cboLarguraDias.DropDownStyle='DropDownList';[void]$script:cboLarguraDias.Items.Add('Ajustar a tela - mostrar o mes inteiro');[void]$script:cboLarguraDias.Items.Add('Compacta - 34 px por dia');[void]$script:cboLarguraDias.Items.Add('Padrao - 54 px por dia');$pgGeral.Controls.Add($script:cboLarguraDias)
$lEstiloEsc=New-Object System.Windows.Forms.Label;$lEstiloEsc.Text='Estilo da aba Escala';$lEstiloEsc.Location=[Drawing.Point]::new(32,305);$lEstiloEsc.Size=[Drawing.Size]::new(180,24);$pgGeral.Controls.Add($lEstiloEsc)
$script:cboEstiloEscala=New-Object System.Windows.Forms.ComboBox;$script:cboEstiloEscala.Location=[Drawing.Point]::new(220,302);$script:cboEstiloEscala.Size=[Drawing.Size]::new(470,27);$script:cboEstiloEscala.DropDownStyle='DropDownList';[void]$script:cboEstiloEscala.Items.Add('Original / V79 - interface anterior');[void]$script:cboEstiloEscala.Items.Add('1 - Classica Moderna');[void]$script:cboEstiloEscala.Items.Add('2 - Painel Lateral');[void]$script:cboEstiloEscala.Items.Add('3 - Fluxo Guiado');[void]$script:cboEstiloEscala.Items.Add('4 - Dashboard Profissional (padrao)');$pgGeral.Controls.Add($script:cboEstiloEscala)
$gInfo=New-Object System.Windows.Forms.Label;$gInfo.Text="A densidade altera fonte e altura das linhas imediatamente. A largura das datas controla somente D01..D31 na tela.`r`nO estilo muda apenas a apresentacao da aba Escala: os mesmos botoes, regras, dados e impressoes continuam sendo usados.";$gInfo.Location=[Drawing.Point]::new(32,345);$gInfo.Size=[Drawing.Size]::new(1000,60);$gInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgGeral.Controls.Add($gInfo)
# V1.0.14.30 - controle visual das abas principais.
$grpAbas=New-Object System.Windows.Forms.GroupBox;$grpAbas.Text='Abas visiveis no sistema';$grpAbas.Location=[Drawing.Point]::new(28,415);$grpAbas.Size=[Drawing.Size]::new(900,205);$pgGeral.Controls.Add($grpAbas)
$lblAbas=New-Object System.Windows.Forms.Label;$lblAbas.Text='Ocultar uma aba nao apaga dados nem desativa regras. Escala e Configuracoes ficam sempre visiveis.';$lblAbas.Location=[Drawing.Point]::new(18,28);$lblAbas.Size=[Drawing.Size]::new(850,24);$lblAbas.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$grpAbas.Controls.Add($lblAbas)

$script:chkTabServidores=New-Object System.Windows.Forms.CheckBox;$script:chkTabServidores.Text='Servidores';$script:chkTabServidores.Location=[Drawing.Point]::new(22,62);$script:chkTabServidores.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabServidores)
$script:chkTabReadaptados=New-Object System.Windows.Forms.CheckBox;$script:chkTabReadaptados.Text='Readaptados';$script:chkTabReadaptados.Location=[Drawing.Point]::new(22,94);$script:chkTabReadaptados.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabReadaptados)
$script:chkTabOcorrencias=New-Object System.Windows.Forms.CheckBox;$script:chkTabOcorrencias.Text='Ocorrencias';$script:chkTabOcorrencias.Location=[Drawing.Point]::new(225,62);$script:chkTabOcorrencias.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabOcorrencias)
$script:chkTabSetores=New-Object System.Windows.Forms.CheckBox;$script:chkTabSetores.Text='Setores';$script:chkTabSetores.Location=[Drawing.Point]::new(225,94);$script:chkTabSetores.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabSetores)
$script:chkTabHorarios=New-Object System.Windows.Forms.CheckBox;$script:chkTabHorarios.Text='Horarios';$script:chkTabHorarios.Location=[Drawing.Point]::new(430,62);$script:chkTabHorarios.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabHorarios)
$script:chkTabSiglas=New-Object System.Windows.Forms.CheckBox;$script:chkTabSiglas.Text='Siglas';$script:chkTabSiglas.Location=[Drawing.Point]::new(430,94);$script:chkTabSiglas.Size=[Drawing.Size]::new(180,26);$grpAbas.Controls.Add($script:chkTabSiglas)

$chkTabEscalaFixa=New-Object System.Windows.Forms.CheckBox;$chkTabEscalaFixa.Text='Escala (sempre visivel)';$chkTabEscalaFixa.Checked=$true;$chkTabEscalaFixa.Enabled=$false;$chkTabEscalaFixa.Location=[Drawing.Point]::new(635,62);$chkTabEscalaFixa.Size=[Drawing.Size]::new(220,26);$grpAbas.Controls.Add($chkTabEscalaFixa)
$chkTabConfigFixa=New-Object System.Windows.Forms.CheckBox;$chkTabConfigFixa.Text='Configuracoes (sempre visivel)';$chkTabConfigFixa.Checked=$true;$chkTabConfigFixa.Enabled=$false;$chkTabConfigFixa.Location=[Drawing.Point]::new(635,94);$chkTabConfigFixa.Size=[Drawing.Size]::new(240,26);$grpAbas.Controls.Add($chkTabConfigFixa)

$bRestAbas=New-Button 'RESTAURAR ABAS PADRAO' 210;$bRestAbas.Location=[Drawing.Point]::new(22,145);$bRestAbas.Add_Click({Restore-MainTabsDefaults});$grpAbas.Controls.Add($bRestAbas)
$lPadraoAbas=New-Object System.Windows.Forms.Label;$lPadraoAbas.Text='Padrao: Readaptados oculto; demais abas operacionais visiveis.';$lPadraoAbas.Location=[Drawing.Point]::new(250,151);$lPadraoAbas.Size=[Drawing.Size]::new(520,24);$lPadraoAbas.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$grpAbas.Controls.Add($lPadraoAbas)

$configTip.SetToolTip($script:chkTabReadaptados,'A funcionalidade Coren dispensado continua disponivel em Servidores > Editar, mesmo com esta aba oculta.')
$configTip.SetToolTip($script:cboCopiaMesAnterior,'Controla somente a criacao de uma nova escala mensal. Ocorrencias e dias nunca sao copiados.')

$grpPortConfig=New-Object System.Windows.Forms.GroupBox
$grpPortConfig.Text='Portabilidade das configuracoes'
$grpPortConfig.Location=[Drawing.Point]::new(28,640)
$grpPortConfig.Size=[Drawing.Size]::new(900,150)
$pgGeral.Controls.Add($grpPortConfig)

$lblPortConfig=New-Object System.Windows.Forms.Label
$lblPortConfig.Text="Salve suas preferencias em um arquivo JSON ou aplique o mesmo perfil em outro computador.`r`nNao leva banco, servidores, escalas, ocorrencias, assinaturas, logos nem o caminho adicional de backup."
$lblPortConfig.Location=[Drawing.Point]::new(18,28)
$lblPortConfig.Size=[Drawing.Size]::new(850,45)
$lblPortConfig.ForeColor=[Drawing.Color]::FromArgb(71,85,105)
$grpPortConfig.Controls.Add($lblPortConfig)

$bExportConfig=New-Button 'EXPORTAR CONFIGURACOES' 210
$bExportConfig.Location=[Drawing.Point]::new(18,88)
$bExportConfig.Add_Click({Export-ConfiguracoesJson})
$grpPortConfig.Controls.Add($bExportConfig)

$bImportConfig=New-Button 'IMPORTAR CONFIGURACOES' 210
$bImportConfig.Location=[Drawing.Point]::new(240,88)
$bImportConfig.Add_Click({Import-ConfiguracoesJson})
$grpPortConfig.Controls.Add($bImportConfig)

$lblImportSeguro=New-Object System.Windows.Forms.Label
$lblImportSeguro.Text='Na importacao, o sistema mostra o que vai mudar e cria backup obrigatorio antes de aplicar.'
$lblImportSeguro.Location=[Drawing.Point]::new(470,95)
$lblImportSeguro.Size=[Drawing.Size]::new(395,40)
$lblImportSeguro.ForeColor=[Drawing.Color]::FromArgb(22,101,52)
$grpPortConfig.Controls.Add($lblImportSeguro)

# Qtd / Contagem
$pgQtd=New-Object System.Windows.Forms.TabPage;$pgQtd.Text='Qtd / Contagem';$pgQtd.BackColor=[System.Drawing.Color]::White;$pgQtd.AutoScroll=$true;$cfgTabs.TabPages.Add($pgQtd)|Out-Null
$lQtdTitle=New-Object System.Windows.Forms.Label;$lQtdTitle.Text='Numeracao da coluna Qtd';$lQtdTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$lQtdTitle.Location=[Drawing.Point]::new(28,24);$lQtdTitle.AutoSize=$true;$pgQtd.Controls.Add($lQtdTitle)
$lQtd=New-Object System.Windows.Forms.Label;$lQtd.Text='Regra da contagem';$lQtd.Location=New-Object System.Drawing.Point(32,82);$lQtd.Size=New-Object System.Drawing.Size(170,24);$pgQtd.Controls.Add($lQtd)
$script:cboQtdModo=New-Object System.Windows.Forms.ComboBox;$script:cboQtdModo.Location=New-Object System.Drawing.Point(210,79);$script:cboQtdModo.Size=New-Object System.Drawing.Size(340,27);$script:cboQtdModo.DropDownStyle='DropDownList';[void]$script:cboQtdModo.Items.Add('ENF separado; TE + AE juntos');[void]$script:cboQtdModo.Items.Add('Sequencial unico por bloco');$pgQtd.Controls.Add($script:cboQtdModo)
$tipQtdModo=New-Object System.Windows.Forms.ToolTip;$tipQtdModo.SetToolTip($script:cboQtdModo,"ENF separado: Enfermeiros contam 1,2,3... numa sequencia propria, e Tecnicos+Auxiliares contam 1,2,3... juntos numa outra sequencia, dentro do mesmo bloco.`r`nSequencial unico: todo mundo do bloco conta junto, na ordem em que aparece: 1,2,3,4...")
$script:chkQtdReinicia=New-Object System.Windows.Forms.CheckBox;$script:chkQtdReinicia.Text='Reiniciar a contagem a cada bloco de horario';$script:chkQtdReinicia.Location=New-Object System.Drawing.Point(210,128);$script:chkQtdReinicia.Size=New-Object System.Drawing.Size(380,28);$pgQtd.Controls.Add($script:chkQtdReinicia)
$tipQtdReinicia=New-Object System.Windows.Forms.ToolTip;$tipQtdReinicia.SetToolTip($script:chkQtdReinicia,'Marcado: cada bloco (PLANTAO MATUTINO, NOTURNO etc.) recomeca a contagem do 1. Desmarcado: a contagem continua de um bloco para o outro, sem reiniciar.')
$lOrdemCargos=New-Object System.Windows.Forms.Label;$lOrdemCargos.Text='Ordem dos cargos';$lOrdemCargos.Location=New-Object System.Drawing.Point(32,172);$lOrdemCargos.Size=New-Object System.Drawing.Size(170,24);$pgQtd.Controls.Add($lOrdemCargos)
$script:txtOrdemCargos=New-Object System.Windows.Forms.TextBox;$script:txtOrdemCargos.Location=New-Object System.Drawing.Point(210,169);$script:txtOrdemCargos.Size=New-Object System.Drawing.Size(340,26);$pgQtd.Controls.Add($script:txtOrdemCargos)
$tipOrdemCargos=New-Object System.Windows.Forms.ToolTip;$tipOrdemCargos.SetToolTip($script:txtOrdemCargos,'Cargos separados por virgula, na ordem desejada. Ex.: ENF,TE,AE. Cargos que nao estiverem nesta lista ficam por ultimo, na tela e na impressao.')
$infoQtd=New-Object System.Windows.Forms.Label;$infoQtd.Text="Padrao recomendado:`r`n• ENF conta em sequencia propria; TE + AE contam juntos.`r`n• A contagem reinicia a cada bloco de horario.`r`n`r`nOrdem dos cargos: define a sequencia do botao ORDENAR POR CARGO.`r`nExemplo: ENF,TE,AE. Cargos nao listados ficam por ultimo.";$infoQtd.Location=New-Object System.Drawing.Point(32,215);$infoQtd.Size=New-Object System.Drawing.Size(980,125);$infoQtd.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgQtd.Controls.Add($infoQtd)


# Destaque da coluna Qtd na impressao
$grpQtdPrint=New-Object System.Windows.Forms.GroupBox
$grpQtdPrint.Text='Destaque da coluna Qtd na impressao'
$grpQtdPrint.Location=New-Object System.Drawing.Point(28,365)
$grpQtdPrint.Size=New-Object System.Drawing.Size(1160,270)
$pgQtd.Controls.Add($grpQtdPrint)

$script:chkQtdPrintDestaque=New-Object System.Windows.Forms.CheckBox
$script:chkQtdPrintDestaque.Text='Ativar destaque por grupo da contagem'
$script:chkQtdPrintDestaque.Location=New-Object System.Drawing.Point(20,30)
$script:chkQtdPrintDestaque.Size=New-Object System.Drawing.Size(330,28)
$grpQtdPrint.Controls.Add($script:chkQtdPrintDestaque)

$lQtdGrupos=New-Object System.Windows.Forms.Label
$lQtdGrupos.Text='Grupos que recebem destaque'
$lQtdGrupos.Location=New-Object System.Drawing.Point(20,70)
$lQtdGrupos.Size=New-Object System.Drawing.Size(210,24)
$grpQtdPrint.Controls.Add($lQtdGrupos)

$script:chkQtdGrupoENF=New-Object System.Windows.Forms.CheckBox;$script:chkQtdGrupoENF.Text='ENF';$script:chkQtdGrupoENF.Location=[Drawing.Point]::new(235,67);$script:chkQtdGrupoENF.Size=[Drawing.Size]::new(70,28);$grpQtdPrint.Controls.Add($script:chkQtdGrupoENF)
$script:chkQtdGrupoTEAE=New-Object System.Windows.Forms.CheckBox;$script:chkQtdGrupoTEAE.Text='TE / AE';$script:chkQtdGrupoTEAE.Location=[Drawing.Point]::new(315,67);$script:chkQtdGrupoTEAE.Size=[Drawing.Size]::new(95,28);$grpQtdPrint.Controls.Add($script:chkQtdGrupoTEAE)
$script:chkQtdGrupoOutros=New-Object System.Windows.Forms.CheckBox;$script:chkQtdGrupoOutros.Text='Outros';$script:chkQtdGrupoOutros.Location=[Drawing.Point]::new(420,67);$script:chkQtdGrupoOutros.Size=[Drawing.Size]::new(90,28);$grpQtdPrint.Controls.Add($script:chkQtdGrupoOutros)

$script:chkQtdPrintVaga=New-Object System.Windows.Forms.CheckBox
$script:chkQtdPrintVaga.Text='Aplicar a mesma cor tambem a Escala Vaga do grupo'
$script:chkQtdPrintVaga.Location=New-Object System.Drawing.Point(20,105)
$script:chkQtdPrintVaga.Size=New-Object System.Drawing.Size(450,28)
$grpQtdPrint.Controls.Add($script:chkQtdPrintVaga)

$lQtdPrintFundo=New-Object System.Windows.Forms.Label;$lQtdPrintFundo.Text='Fundo';$lQtdPrintFundo.Location=[Drawing.Point]::new(20,148);$lQtdPrintFundo.Size=[Drawing.Size]::new(60,24);$grpQtdPrint.Controls.Add($lQtdPrintFundo)
$script:txtQtdPrintFundo=New-Object System.Windows.Forms.TextBox;$script:txtQtdPrintFundo.Location=[Drawing.Point]::new(82,145);$script:txtQtdPrintFundo.Size=[Drawing.Size]::new(95,27);$grpQtdPrint.Controls.Add($script:txtQtdPrintFundo)
$bQtdPrintFundo=New-Button 'ESCOLHER...' 105;$bQtdPrintFundo.Location=[Drawing.Point]::new(185,142);$bQtdPrintFundo.Add_Click({try{$cd=New-Object System.Windows.Forms.ColorDialog;$cd.FullOpen=$true;$cd.AnyColor=$true;$cd.Color=Color-FromHex $script:txtQtdPrintFundo.Text ([Drawing.Color]::FromArgb(217,217,217));if($cd.ShowDialog($script:MainForm)-eq[System.Windows.Forms.DialogResult]::OK){$script:txtQtdPrintFundo.Text=Color-ToHex $cd.Color;Update-QtdPrintConfigPreview};$cd.Dispose()}catch{Show-Error $_.Exception.Message}});$grpQtdPrint.Controls.Add($bQtdPrintFundo)

$lQtdPrintFonte=New-Object System.Windows.Forms.Label;$lQtdPrintFonte.Text='Fonte';$lQtdPrintFonte.Location=[Drawing.Point]::new(315,148);$lQtdPrintFonte.Size=[Drawing.Size]::new(55,24);$grpQtdPrint.Controls.Add($lQtdPrintFonte)
$script:txtQtdPrintFonte=New-Object System.Windows.Forms.TextBox;$script:txtQtdPrintFonte.Location=[Drawing.Point]::new(372,145);$script:txtQtdPrintFonte.Size=[Drawing.Size]::new(95,27);$grpQtdPrint.Controls.Add($script:txtQtdPrintFonte)
$bQtdPrintFonte=New-Button 'ESCOLHER...' 105;$bQtdPrintFonte.Location=[Drawing.Point]::new(475,142);$bQtdPrintFonte.Add_Click({try{$cd=New-Object System.Windows.Forms.ColorDialog;$cd.FullOpen=$true;$cd.AnyColor=$true;$cd.Color=Color-FromHex $script:txtQtdPrintFonte.Text ([Drawing.Color]::Black);if($cd.ShowDialog($script:MainForm)-eq[System.Windows.Forms.DialogResult]::OK){$script:txtQtdPrintFonte.Text=Color-ToHex $cd.Color;Update-QtdPrintConfigPreview};$cd.Dispose()}catch{Show-Error $_.Exception.Message}});$grpQtdPrint.Controls.Add($bQtdPrintFonte)

$lQtdPrintInfo=New-Object System.Windows.Forms.Label;$lQtdPrintInfo.Text='O destaque segue o MESMO grupo usado na numeracao Qtd. Assim ENF, ENFERMEIRO e ENF/CTR nao ficam com numero de ENF e cor diferente.';$lQtdPrintInfo.Location=[Drawing.Point]::new(20,195);$lQtdPrintInfo.Size=[Drawing.Size]::new(590,48);$lQtdPrintInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$grpQtdPrint.Controls.Add($lQtdPrintInfo)

# Mini-preview em tempo real
$prevQtd=New-Object System.Windows.Forms.GroupBox;$prevQtd.Text='Previa em tempo real';$prevQtd.Location=[Drawing.Point]::new(640,25);$prevQtd.Size=[Drawing.Size]::new(490,215);$grpQtdPrint.Controls.Add($prevQtd)
$h1=New-Object System.Windows.Forms.Label;$h1.Text='Qtd';$h1.TextAlign='MiddleCenter';$h1.Font=$script:FontSemibold9;$h1.BorderStyle='FixedSingle';$h1.Location=[Drawing.Point]::new(18,35);$h1.Size=[Drawing.Size]::new(70,30);$prevQtd.Controls.Add($h1)
$h2=New-Object System.Windows.Forms.Label;$h2.Text='Funcao / exemplo';$h2.TextAlign='MiddleCenter';$h2.Font=$script:FontSemibold9;$h2.BorderStyle='FixedSingle';$h2.Location=[Drawing.Point]::new(87,35);$h2.Size=[Drawing.Size]::new(375,30);$prevQtd.Controls.Add($h2)
function Add-QtdPreviewRowLocal { param([int]$Y,[string]$Qtd,[string]$Texto,[string]$VarName)
    $q=New-Object System.Windows.Forms.Label;$q.Text=$Qtd;$q.TextAlign='MiddleCenter';$q.BorderStyle='FixedSingle';$q.Location=[Drawing.Point]::new(18,$Y);$q.Size=[Drawing.Size]::new(70,32);$prevQtd.Controls.Add($q);Set-Variable -Scope Script -Name $VarName -Value $q
    $t=New-Object System.Windows.Forms.Label;$t.Text=$Texto;$t.TextAlign='MiddleLeft';$t.BorderStyle='FixedSingle';$t.Location=[Drawing.Point]::new(87,$Y);$t.Size=[Drawing.Size]::new(375,32);$prevQtd.Controls.Add($t)
}
Add-QtdPreviewRowLocal 65 '1' 'ENF - Enfermeiro' 'lblQtdPrevENF'
Add-QtdPreviewRowLocal 97 '1' 'TE/AE - Tecnico ou Auxiliar' 'lblQtdPrevTEAE'
Add-QtdPreviewRowLocal 129 '1' 'OUTROS - demais funcoes' 'lblQtdPrevOutro'
Add-QtdPreviewRowLocal 161 '1' 'ESCALA VAGA - ENF' 'lblQtdPrevVaga'
$script:lblQtdPrintPreview=$script:lblQtdPrevENF

$script:chkQtdPrintDestaque.Add_CheckedChanged({Update-QtdPrintConfigPreview})
$script:chkQtdGrupoENF.Add_CheckedChanged({Update-QtdPrintConfigPreview})
$script:chkQtdGrupoTEAE.Add_CheckedChanged({Update-QtdPrintConfigPreview})
$script:chkQtdGrupoOutros.Add_CheckedChanged({Update-QtdPrintConfigPreview})
$script:chkQtdPrintVaga.Add_CheckedChanged({Update-QtdPrintConfigPreview})
$script:txtQtdPrintFundo.Add_TextChanged({Update-QtdPrintConfigPreview})
$script:txtQtdPrintFonte.Add_TextChanged({Update-QtdPrintConfigPreview})
Update-QtdPrintConfigPreview

# Blocos / Paridade
$pgBlocos=New-Object System.Windows.Forms.TabPage;$pgBlocos.Text='Blocos / Paridade';$pgBlocos.BackColor=[System.Drawing.Color]::White;$pgBlocos.AutoScroll=$true;$cfgTabs.TabPages.Add($pgBlocos)|Out-Null
$blkPanel=New-Object System.Windows.Forms.FlowLayoutPanel;$blkPanel.Dock='Fill';$blkPanel.FlowDirection='TopDown';$blkPanel.WrapContents=$false;$blkPanel.Padding=New-Object System.Windows.Forms.Padding(28,24,10,10);$pgBlocos.Controls.Add($blkPanel)
$blkTitle=New-Object System.Windows.Forms.Label;$blkTitle.Text='Regras automaticas dos blocos de horario';$blkTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$blkTitle.AutoSize=$true;$blkTitle.Margin=New-Object System.Windows.Forms.Padding(3,0,3,14);$blkPanel.Controls.Add($blkTitle)
$script:chkMaskDN=New-Object System.Windows.Forms.CheckBox;$script:chkMaskDN.Text='Diurno/Noturno PAR ou IMPAR: aplicar fundo cinza nos dias correspondentes';$script:chkMaskDN.Size=New-Object System.Drawing.Size(680,30);$blkPanel.Controls.Add($script:chkMaskDN)
$tipMaskDN=New-Object System.Windows.Forms.ToolTip;$tipMaskDN.SetToolTip($script:chkMaskDN,'Vale para blocos NOTURNO/DIURNO com regra PAR ou IMPAR cadastrada no Horario. Ex.: um bloco "NOTURNO PAR" recebe fundo cinza nos dias 02, 04, 06, 08... (todos os dias pares do mes, nao so fim de semana).')
$script:chkMaskMV=New-Object System.Windows.Forms.CheckBox;$script:chkMaskMV.Text='Matutino/Vespertino: aplicar paridade somente aos sabados e domingos';$script:chkMaskMV.Size=New-Object System.Drawing.Size(680,30);$blkPanel.Controls.Add($script:chkMaskMV)
$tipMaskMV=New-Object System.Windows.Forms.ToolTip;$tipMaskMV.SetToolTip($script:chkMaskMV,'Vale para blocos MATUTINO/VESPERTINO com regra PAR ou IMPAR cadastrada no Horario. Diferente do Diurno/Noturno, aqui a mascara cinza so aparece nos sabados e domingos que batem com a paridade, nao em todos os dias do mes.')
$script:chkAutoPtMV=New-Object System.Windows.Forms.CheckBox;$script:chkAutoPtMV.Text='Matutino/Vespertino: preencher PT automaticamente no FDS PAR/IMPAR do cabecalho';$script:chkAutoPtMV.Size=New-Object System.Drawing.Size(760,30);$blkPanel.Controls.Add($script:chkAutoPtMV)
$tipAutoPtMV=New-Object System.Windows.Forms.ToolTip;$tipAutoPtMV.SetToolTip($script:chkAutoPtMV,'Quando a celula do fim de semana com paridade correspondente estiver vazia, o sistema preenche PT (Plantao Trabalhado) sozinho, sem precisar lancar manualmente. So funciona se a mascara de paridade acima (Matutino/Vespertino) tambem estiver marcada.')
$blkInfo=New-Object System.Windows.Forms.Label;$blkInfo.Text="Regras oficiais:`r`n• Diurno/Noturno: PAR/IMPAR considera o numero do dia em todo o mes.`r`n• Matutino/Vespertino: PAR/IMPAR considera somente sabado e domingo.`r`n• A ordem dos blocos pode ser alterada na aba Escala sem mudar o cadastro de Horarios.";$blkInfo.Size=New-Object System.Drawing.Size(820,105);$blkInfo.Margin=New-Object System.Windows.Forms.Padding(3,18,3,3);$blkInfo.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105);$blkPanel.Controls.Add($blkInfo)

# Backup / Seguranca
$pgBackup=New-Object System.Windows.Forms.TabPage;$pgBackup.Text='Backup / Segurança';$pgBackup.BackColor=[System.Drawing.Color]::White;$pgBackup.AutoScroll=$true;$cfgTabs.TabPages.Add($pgBackup)|Out-Null
$bkpTitle=New-Object System.Windows.Forms.Label;$bkpTitle.Text='Protecao do banco de dados';$bkpTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$bkpTitle.Location=[Drawing.Point]::new(28,24);$bkpTitle.AutoSize=$true;$pgBackup.Controls.Add($bkpTitle)
$bkpDesc=New-Object System.Windows.Forms.Label;$bkpDesc.Text='O backup principal e criado por VACUUM INTO quando disponivel e validado com PRAGMA integrity_check. Voce pode manter uma segunda copia em outro disco ou pasta de rede.';$bkpDesc.Location=[Drawing.Point]::new(28,58);$bkpDesc.Size=[Drawing.Size]::new(930,44);$bkpDesc.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgBackup.Controls.Add($bkpDesc)
$script:chkBackupSaida=New-Object System.Windows.Forms.CheckBox;$script:chkBackupSaida.Text='Criar backup automaticamente ao fechar o sistema';$script:chkBackupSaida.Location=[Drawing.Point]::new(32,120);$script:chkBackupSaida.Size=[Drawing.Size]::new(430,28);$pgBackup.Controls.Add($script:chkBackupSaida)
$lBkpMax=New-Object System.Windows.Forms.Label;$lBkpMax.Text='Quantidade maxima de backups por pasta';$lBkpMax.Location=[Drawing.Point]::new(32,170);$lBkpMax.Size=[Drawing.Size]::new(290,24);$pgBackup.Controls.Add($lBkpMax)
$script:numBackupMax=New-Object System.Windows.Forms.NumericUpDown;$script:numBackupMax.Location=[Drawing.Point]::new(330,167);$script:numBackupMax.Size=[Drawing.Size]::new(100,27);$script:numBackupMax.Minimum=1;$script:numBackupMax.Maximum=500;$script:numBackupMax.Value=15;$pgBackup.Controls.Add($script:numBackupMax)
$lBkpExtra=New-Object System.Windows.Forms.Label;$lBkpExtra.Text='Pasta adicional (opcional)';$lBkpExtra.Location=[Drawing.Point]::new(32,225);$lBkpExtra.Size=[Drawing.Size]::new(220,24);$pgBackup.Controls.Add($lBkpExtra)
$script:txtBackupAdicional=New-Object System.Windows.Forms.TextBox;$script:txtBackupAdicional.Location=[Drawing.Point]::new(32,255);$script:txtBackupAdicional.Size=[Drawing.Size]::new(720,27);$pgBackup.Controls.Add($script:txtBackupAdicional)
$bBkpBrowse=New-Button 'ESCOLHER PASTA...' 165;$bBkpBrowse.Location=[Drawing.Point]::new(770,251);$bBkpBrowse.Add_Click({try{$fb=New-Object System.Windows.Forms.FolderBrowserDialog;$fb.Description='Escolha a pasta para a copia adicional dos backups';if(-not [string]::IsNullOrWhiteSpace($script:txtBackupAdicional.Text)){$fb.SelectedPath=$script:txtBackupAdicional.Text};$dlgResult=$fb.ShowDialog($script:MainForm);$pastaSelecionada=$fb.SelectedPath;$fb.Dispose();if($dlgResult -eq 'OK'){$script:txtBackupAdicional.Text=$pastaSelecionada}}catch{if($null -ne $fb){try{$fb.Dispose()}catch{Write-Log ('Falha ao liberar FolderBrowserDialog: ' + $_.Exception.Message)}};Show-Error $_.Exception.Message}});$pgBackup.Controls.Add($bBkpBrowse)
$bkpInfo=New-Object System.Windows.Forms.Label;$bkpInfo.Text="Recomendacao: escolha uma pasta em outro disco ou na rede institucional. O banco operacional nao e movido; somente uma copia de backup validada e enviada para esse destino.`r`nSe a pasta adicional estiver indisponivel, o backup principal continua sendo criado e a falha fica registrada no log.";$bkpInfo.Location=[Drawing.Point]::new(32,310);$bkpInfo.Size=[Drawing.Size]::new(900,78);$bkpInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgBackup.Controls.Add($bkpInfo)

# Ocorrencias
$pgOccCfg=New-Object System.Windows.Forms.TabPage;$pgOccCfg.Text='Ocorrências';$pgOccCfg.BackColor=[System.Drawing.Color]::White;$pgOccCfg.AutoScroll=$true;$cfgTabs.TabPages.Add($pgOccCfg)|Out-Null
$ocTitle=New-Object System.Windows.Forms.Label;$ocTitle.Text='Tipos de ocorrencia e faixas continuas: texto, duracao e cores individuais';$ocTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$ocTitle.Location=[Drawing.Point]::new(28,20);$ocTitle.AutoSize=$true;$pgOccCfg.Controls.Add($ocTitle)
$pOcCfgBar=New-Object System.Windows.Forms.FlowLayoutPanel;$pOcCfgBar.Location=[Drawing.Point]::new(24,56);$pOcCfgBar.Size=[Drawing.Size]::new(700,44);$pOcCfgBar.WrapContents=$false;$pgOccCfg.Controls.Add($pOcCfgBar)
$bTipoNovo=New-Button 'NOVO TIPO' 115;Set-PrimaryButton $bTipoNovo;$bTipoNovo.Add_Click({Show-TipoOcorrenciaDialog 0});$pOcCfgBar.Controls.Add($bTipoNovo)
$bTipoEditar=New-Button 'EDITAR' 105;$bTipoEditar.Add_Click({$id=Get-GridId $script:gridTiposOc;if($id){Show-TipoOcorrenciaDialog $id}else{Show-Info 'Selecione um tipo.'}});$pOcCfgBar.Controls.Add($bTipoEditar)
$bTipoAtivo=New-Button 'ATIVAR/DESATIVAR' 155;$bTipoAtivo.Add_Click({Toggle-TipoOcorrenciaAtiva});$pOcCfgBar.Controls.Add($bTipoAtivo)
$bTipoExcluir=New-Button 'EXCLUIR' 105;$bTipoExcluir.Add_Click({Delete-TipoOcorrencia});$pOcCfgBar.Controls.Add($bTipoExcluir)
$script:gridTiposOc=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridTiposOc;$script:gridTiposOc.Location=[Drawing.Point]::new(24,108);$script:gridTiposOc.Size=[Drawing.Size]::new(1120,300);$script:gridTiposOc.Anchor='Top,Left,Right';$pgOccCfg.Controls.Add($script:gridTiposOc);$script:gridTiposOc.Add_CellDoubleClick({$id=Get-GridId $script:gridTiposOc;if($id){Show-TipoOcorrenciaDialog $id}})
$ocInfo=New-Object System.Windows.Forms.Label;$ocInfo.Text="Cadastre aqui quantos tipos de ocorrencia (Ferias, Atestado, Licenca, etc.) sua unidade precisar.`r`nMarque 'Faixa continua' para usar uma unica faixa mesclada. Cada tipo pode ter TEXTO, COR DO FUNDO e COR DA FONTE proprios, aplicados na aba Escala e na impressao.`r`nExcluir um tipo ja usado apenas o desativa; os lancamentos ja feitos continuam intactos.";$ocInfo.Location=[Drawing.Point]::new(28,420);$ocInfo.Size=[Drawing.Size]::new(1060,72);$ocInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$ocInfo.Anchor='Top,Left,Right';$pgOccCfg.Controls.Add($ocInfo)

# Siglas rapidas
$pgQuick=New-Object System.Windows.Forms.TabPage;$pgQuick.Text='Siglas rápidas';$pgQuick.BackColor=[Drawing.Color]::White;$pgQuick.AutoScroll=$true;$cfgTabs.TabPages.Add($pgQuick)|Out-Null
$qTitle=New-Object System.Windows.Forms.Label;$qTitle.Text='Menu rapido das celulas da Escala';$qTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$qTitle.Location=[Drawing.Point]::new(28,24);$qTitle.AutoSize=$true;$pgQuick.Controls.Add($qTitle)
$lQuick=New-Object System.Windows.Forms.Label;$lQuick.Text='Siglas exibidas no clique direito (separe por virgula)';$lQuick.Location=[Drawing.Point]::new(32,82);$lQuick.Size=[Drawing.Size]::new(390,24);$pgQuick.Controls.Add($lQuick)
$script:txtSiglasRapidas=New-Object System.Windows.Forms.TextBox;$script:txtSiglasRapidas.Location=[Drawing.Point]::new(32,112);$script:txtSiglasRapidas.Size=[Drawing.Size]::new(620,28);$pgQuick.Controls.Add($script:txtSiglasRapidas)
$qExample=New-Object System.Windows.Forms.Label;$qExample.Text='Exemplo: FC,FF,PT,C1,C2,C3,FS,PF';$qExample.Location=[Drawing.Point]::new(32,153);$qExample.Size=[Drawing.Size]::new(500,24);$qExample.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgQuick.Controls.Add($qExample)
$qInfo=New-Object System.Windows.Forms.Label;$qInfo.Text="FER e AT nao entram no menu rapido porque Ferias e Atestados possuem fluxo oficial pela aba Ocorrencias.`r`n`r`nFF, PF e FS tem regra propria e nao aplicam em qualquer dia: FF so em dia cadastrado como Feriado (aba Calendario/08h), PF so em dia cadastrado como Ponto Facultativo, e FS so aos sabados e domingos. Fora dessas condicoes, o sistema avisa e nao lanca a sigla.";$qInfo.Location=[Drawing.Point]::new(32,205);$qInfo.Size=[Drawing.Size]::new(800,120);$qInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgQuick.Controls.Add($qInfo)

# Assinaturas
$pgAss=New-Object System.Windows.Forms.TabPage;$pgAss.Text='Assinaturas';$pgAss.BackColor=[System.Drawing.Color]::White;$pgAss.AutoScroll=$true;$cfgTabs.TabPages.Add($pgAss)|Out-Null
$assTop=New-Object System.Windows.Forms.FlowLayoutPanel;$assTop.Dock='Top';$assTop.Height=58;$assTop.Padding=New-Object System.Windows.Forms.Padding(10,4,4,4);$assTop.WrapContents=$false;$assTop.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$pgAss.Controls.Add($assTop)
$bAssNew=New-Button 'NOVA ASSINATURA' 150;Set-PrimaryButton $bAssNew;$bAssNew.Add_Click({Show-AssinaturaDialog 0});$assTop.Controls.Add($bAssNew)
$bAssEd=New-Button 'EDITAR' 95;$bAssEd.Add_Click({$id=Get-GridId $script:gridAssinaturas;if($id){Show-AssinaturaDialog $id}else{Show-Info 'Selecione uma assinatura.'}});$assTop.Controls.Add($bAssEd)
$bAssAt=New-Button 'ATIVAR / DESATIVAR' 160;$bAssAt.Add_Click({Toggle-AssinaturaAtiva});$assTop.Controls.Add($bAssAt)
$bAssDel=New-Button 'EXCLUIR' 95;$bAssDel.Add_Click({Delete-Assinatura});$assTop.Controls.Add($bAssDel)
$bAssRef=New-Button 'ATUALIZAR' 105;$bAssRef.Add_Click({Load-Assinaturas});$assTop.Controls.Add($bAssRef)
$assInfo=New-Object System.Windows.Forms.Label;$assInfo.Dock='Bottom';$assInfo.Height=42;$assInfo.Padding=New-Object System.Windows.Forms.Padding(12,5,0,0);$assInfo.Text='Na impressao, as assinaturas sao organizadas automaticamente em pares: 2 por linha. Se houver numero impar, a ultima fica a esquerda.';$assInfo.ForeColor=[System.Drawing.Color]::FromArgb(71,85,105);$pgAss.Controls.Add($assInfo)
$script:gridAssinaturas=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridAssinaturas;$pgAss.Controls.Add($script:gridAssinaturas);$script:gridAssinaturas.BringToFront();$script:gridAssinaturas.Add_CellDoubleClick({$id=Get-GridId $script:gridAssinaturas;if($id){Show-AssinaturaDialog $id}})

# Calendario / 08h
$pgCal=New-Object System.Windows.Forms.TabPage;$pgCal.Text='Calendário / 08h';$pgCal.BackColor=[System.Drawing.Color]::White;$pgCal.AutoScroll=$true;$cfgTabs.TabPages.Add($pgCal)|Out-Null
$calTop=New-Object System.Windows.Forms.FlowLayoutPanel;$calTop.Dock='Top';$calTop.Height=150;$calTop.Padding=New-Object System.Windows.Forms.Padding(18,10,5,5);$calTop.FlowDirection='TopDown';$calTop.WrapContents=$true;$pgCal.Controls.Add($calTop)
$script:chkCalFds=New-Object System.Windows.Forms.CheckBox;$script:chkCalFds.Text='Destacar sabados e domingos na tela da escala';$script:chkCalFds.Size=New-Object System.Drawing.Size(380,28);$calTop.Controls.Add($script:chkCalFds)
$tipCalFds=New-Object System.Windows.Forms.ToolTip;$tipCalFds.SetToolTip($script:chkCalFds,'So afeta a cor de fundo na tela; nao muda nenhum lancamento.')
$script:chkCalFer=New-Object System.Windows.Forms.CheckBox;$script:chkCalFer.Text='Destacar feriados na tela e no calendario';$script:chkCalFer.Size=New-Object System.Drawing.Size(380,28);$calTop.Controls.Add($script:chkCalFer)
$tipCalFer=New-Object System.Windows.Forms.ToolTip;$tipCalFer.SetToolTip($script:chkCalFer,'So afeta a cor de fundo na tela; nao muda nenhum lancamento. Cadastre os feriados com o botao + FERIADO / PF abaixo.')
$script:chkAuto08FFPF=New-Object System.Windows.Forms.CheckBox;$script:chkAuto08FFPF.Text='Horario 08h: preencher FF em feriado e PF em ponto facultativo automaticamente';$script:chkAuto08FFPF.Size=New-Object System.Drawing.Size(590,28);$calTop.Controls.Add($script:chkAuto08FFPF)
$tipAuto08FFPF=New-Object System.Windows.Forms.ToolTip;$tipAuto08FFPF.SetToolTip($script:chkAuto08FFPF,'Aplica apenas aos blocos marcados como "Jornada 08h" no cadastro de Horarios. Neles, dias cadastrados como Feriado recebem FF e dias de Ponto Facultativo recebem PF automaticamente, respeitando lancamentos manuais e Ocorrencias oficiais.')
$script:chkAuto08FS=New-Object System.Windows.Forms.CheckBox;$script:chkAuto08FS.Text='Horario 08h: preencher FS automaticamente aos sabados e domingos';$script:chkAuto08FS.Size=New-Object System.Drawing.Size(550,28);$calTop.Controls.Add($script:chkAuto08FS)
$tipAuto08FS=New-Object System.Windows.Forms.ToolTip;$tipAuto08FS.SetToolTip($script:chkAuto08FS,'Aplica apenas aos blocos marcados como "Jornada 08h" no cadastro de Horarios. Sabados e domingos livres recebem FS automaticamente, sem precisar lancar manualmente.')
$bFerNew=New-Button '+ FERIADO / PF' 145;$bFerNew.Add_Click({Show-FeriadoDialog});$calTop.Controls.Add($bFerNew)
$bFerEd=New-Button 'EDITAR' 105;$bFerEd.Add_Click({$id=Get-GridId $script:gridFeriados;if($id){Show-FeriadoDialog $id}else{Show-Info 'Selecione um feriado/ponto facultativo.'}});$calTop.Controls.Add($bFerEd)
$bFerDel=New-Button 'EXCLUIR DATA' 130;$bFerDel.Add_Click({Delete-Feriado});$calTop.Controls.Add($bFerDel)
$bFerOpen=New-Button 'ABRIR CALENDARIO' 145;$bFerOpen.Add_Click({Show-CalendarioEscala});$calTop.Controls.Add($bFerOpen)
$script:gridFeriados=New-Object System.Windows.Forms.DataGridView;Set-GridStyle $script:gridFeriados;$pgCal.Controls.Add($script:gridFeriados);$script:gridFeriados.BringToFront()
$script:gridFeriados.Add_CellDoubleClick({$id=Get-GridId $script:gridFeriados;if($id){Show-FeriadoDialog $id}})

# Impressao
$pgImp=New-Object System.Windows.Forms.TabPage;$pgImp.Text='Impressão';$pgImp.BackColor=[System.Drawing.Color]::White;$pgImp.AutoScroll=$true;$cfgTabs.TabPages.Add($pgImp)|Out-Null
$impTitle=New-Object System.Windows.Forms.Label;$impTitle.Text='Configuracao da pre-visualizacao e impressao';$impTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',12);$impTitle.Location=[Drawing.Point]::new(28,24);$impTitle.AutoSize=$true;$pgImp.Controls.Add($impTitle)

$grpPerfilImp=New-Object System.Windows.Forms.GroupBox
$grpPerfilImp.Text='Perfis de impressao'
$grpPerfilImp.Location=[Drawing.Point]::new(640,20)
$grpPerfilImp.Size=[Drawing.Size]::new(540,350)
$pgImp.Controls.Add($grpPerfilImp)

$lPerfilImp=New-Object System.Windows.Forms.Label
$lPerfilImp.Text='Perfil'
$lPerfilImp.Location=[Drawing.Point]::new(22,34)
$lPerfilImp.Size=[Drawing.Size]::new(80,26)
$grpPerfilImp.Controls.Add($lPerfilImp)

$script:cboPerfilImpressao=New-Object System.Windows.Forms.ComboBox
$script:cboPerfilImpressao.DropDownStyle='DropDownList'
$script:cboPerfilImpressao.Location=[Drawing.Point]::new(110,31)
$script:cboPerfilImpressao.Size=[Drawing.Size]::new(250,28)
[void]$script:cboPerfilImpressao.Items.AddRange(@('Oficial','Compacto','Conferencia','Personalizado'))
$script:cboPerfilImpressao.SelectedIndex=3 # Personalizado ate Load-ConfiguracoesUI detectar o perfil real
$script:PrintProfileUserPick=$false
$script:cboPerfilImpressao.Add_SelectionChangeCommitted({$script:PrintProfileUserPick=$true})
$grpPerfilImp.Controls.Add($script:cboPerfilImpressao)

$bAplicarPerfilImp=New-Button 'APLICAR PERFIL' 150
$bAplicarPerfilImp.Location=[Drawing.Point]::new(110,76)
$bAplicarPerfilImp.Add_Click({
    if($script:cboPerfilImpressao.SelectedItem){
        Apply-PrintProfileToUI ([string]$script:cboPerfilImpressao.SelectedItem)
    }
})
$grpPerfilImp.Controls.Add($bAplicarPerfilImp)

$lPerfilInfo=New-Object System.Windows.Forms.Label
$lPerfilInfo.Text="OFICIAL - configuracao equilibrada para a escala final.`r`nCOMPACTO - reduz fontes e espacamentos; usa somente as siglas utilizadas.`r`nCONFERENCIA - grade maior, sem legenda e sem assinaturas.`r`nPERSONALIZADO - mantem os valores definidos manualmente.`r`n`r`nIMPORTANTE: aplicar um perfil altera somente os controles desta tela. Para gravar no sistema, clique SALVAR CONFIGURACOES."
$lPerfilInfo.Location=[Drawing.Point]::new(22,122)
$lPerfilInfo.Size=[Drawing.Size]::new(490,205)
$lPerfilInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105)
$lPerfilInfo.BackColor=[Drawing.Color]::FromArgb(248,250,252)
$lPerfilInfo.BorderStyle='FixedSingle'
$lPerfilInfo.Padding=New-Object System.Windows.Forms.Padding(10,8,10,8)
$lPerfilInfo.AutoSize=$false
$lPerfilInfo.TextAlign='TopLeft'
$grpPerfilImp.Controls.Add($lPerfilInfo)


$script:chkImpLegenda=New-Object System.Windows.Forms.CheckBox;$script:chkImpLegenda.Text='Mostrar legenda das siglas';$script:chkImpLegenda.Location=[Drawing.Point]::new(32,76);$script:chkImpLegenda.Size=[Drawing.Size]::new(560,26);$pgImp.Controls.Add($script:chkImpLegenda)
$tipImpLegenda=New-Object System.Windows.Forms.ToolTip;$tipImpLegenda.SetToolTip($script:chkImpLegenda,'Mostra a tabela SIGLA/SIGNIFICADO no canto inferior direito da folha impressa.')

$script:chkImpTodasSiglas=New-Object System.Windows.Forms.CheckBox;$script:chkImpTodasSiglas.Text='Na legenda, mostrar todas as siglas ativas (desmarcado = somente usadas)';$script:chkImpTodasSiglas.Location=[Drawing.Point]::new(32,110);$script:chkImpTodasSiglas.Size=[Drawing.Size]::new(600,26);$pgImp.Controls.Add($script:chkImpTodasSiglas)
$tipImpTodasSiglas=New-Object System.Windows.Forms.ToolTip;$tipImpTodasSiglas.SetToolTip($script:chkImpTodasSiglas,'Marcado: a legenda sempre traz todas as siglas cadastradas e ativas (aba Siglas), mesmo as que nao aparecem nesta escala. Desmarcado: so entram na legenda as siglas que realmente foram usadas nesta escala mensal.')

$script:chkImpAss=New-Object System.Windows.Forms.CheckBox;$script:chkImpAss.Text='Mostrar assinaturas';$script:chkImpAss.Location=[Drawing.Point]::new(32,144);$script:chkImpAss.Size=[Drawing.Size]::new(560,26);$pgImp.Controls.Add($script:chkImpAss)
$tipImpAss=New-Object System.Windows.Forms.ToolTip;$tipImpAss.SetToolTip($script:chkImpAss,'Mostra o bloco de assinaturas cadastrado na aba Assinaturas, no canto inferior esquerdo da folha impressa.')

$script:chkImpFds=New-Object System.Windows.Forms.CheckBox;$script:chkImpFds.Text='Destacar finais de semana na impressao';$script:chkImpFds.Location=[Drawing.Point]::new(32,178);$script:chkImpFds.Size=[Drawing.Size]::new(560,26);$pgImp.Controls.Add($script:chkImpFds)
$tipImpFds=New-Object System.Windows.Forms.ToolTip;$tipImpFds.SetToolTip($script:chkImpFds,'Aplica um fundo cinza claro nas colunas de sabado e domingo. Nos blocos DIURNO/NOTURNO com paridade, este destaque nao aparece: la o dia so e diferenciado pela cor de paridade PAR/IMPAR do cabecalho.')

$script:chkImpFer=New-Object System.Windows.Forms.CheckBox;$script:chkImpFer.Text='Destacar feriados na impressao';$script:chkImpFer.Location=[Drawing.Point]::new(32,212);$script:chkImpFer.Size=[Drawing.Size]::new(560,26);$pgImp.Controls.Add($script:chkImpFer)
$tipImpFer=New-Object System.Windows.Forms.ToolTip;$tipImpFer.SetToolTip($script:chkImpFer,'Aplica um fundo cinza nas colunas de dias cadastrados como Feriado (aba Calendario/08h). Nos blocos DIURNO/NOTURNO com paridade, este destaque nao aparece: la o dia so e diferenciado pela cor de paridade PAR/IMPAR do cabecalho.')

$lFontesTitle=New-Object System.Windows.Forms.Label;$lFontesTitle.Text='FONTES E TAMANHOS';$lFontesTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lFontesTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lFontesTitle.Location=[Drawing.Point]::new(32,256);$lFontesTitle.AutoSize=$true;$pgImp.Controls.Add($lFontesTitle)

$lLegFont=New-Object System.Windows.Forms.Label;$lLegFont.Text='Fonte da legenda (pt)';$lLegFont.Location=[Drawing.Point]::new(32,292);$lLegFont.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lLegFont)
$script:numLegendaFonte=New-Object System.Windows.Forms.NumericUpDown;$script:numLegendaFonte.Location=[Drawing.Point]::new(320,289);$script:numLegendaFonte.Size=[Drawing.Size]::new(90,27);$script:numLegendaFonte.Minimum=5;$script:numLegendaFonte.Maximum=10;$pgImp.Controls.Add($script:numLegendaFonte)
$tipLegFont=New-Object System.Windows.Forms.ToolTip;$tipLegFont.SetToolTip($script:numLegendaFonte,'Tamanho do texto na tabela SIGLA/SIGNIFICADO impressa. Independente da fonte da grade principal.')

$lSgWidth=New-Object System.Windows.Forms.Label;$lSgWidth.Text='Largura da coluna SIGLA (mm)';$lSgWidth.Location=[Drawing.Point]::new(32,330);$lSgWidth.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lSgWidth)
$script:numLegendaSiglaMm=New-Object System.Windows.Forms.NumericUpDown;$script:numLegendaSiglaMm.Location=[Drawing.Point]::new(320,327);$script:numLegendaSiglaMm.Size=[Drawing.Size]::new(90,27);$script:numLegendaSiglaMm.Minimum=5;$script:numLegendaSiglaMm.Maximum=15;$pgImp.Controls.Add($script:numLegendaSiglaMm)
$tipSgWidth=New-Object System.Windows.Forms.ToolTip;$tipSgWidth.SetToolTip($script:numLegendaSiglaMm,'Largura so da primeira coluna da legenda (onde fica a sigla, ex.: "FS"). A coluna de significado ao lado se ajusta sozinha ao texto.')

$lAssFont=New-Object System.Windows.Forms.Label;$lAssFont.Text='Fonte das assinaturas (pt)';$lAssFont.Location=[Drawing.Point]::new(32,368);$lAssFont.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lAssFont)
$script:numAssinaturaFonte=New-Object System.Windows.Forms.NumericUpDown;$script:numAssinaturaFonte.Location=[Drawing.Point]::new(320,365);$script:numAssinaturaFonte.Size=[Drawing.Size]::new(90,27);$script:numAssinaturaFonte.Minimum=5;$script:numAssinaturaFonte.Maximum=12;$pgImp.Controls.Add($script:numAssinaturaFonte)
$tipAssFont=New-Object System.Windows.Forms.ToolTip;$tipAssFont.SetToolTip($script:numAssinaturaFonte,'Tamanho do nome e cargo abaixo de cada linha de assinatura, no canto inferior esquerdo da folha.')

$lAssFontFam=New-Object System.Windows.Forms.Label;$lAssFontFam.Text='Tipo de fonte das assinaturas';$lAssFontFam.Location=[Drawing.Point]::new(32,406);$lAssFontFam.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lAssFontFam)
$script:cboAssFonteFamilia=New-Object System.Windows.Forms.ComboBox;$script:cboAssFonteFamilia.DropDownStyle='DropDownList';$script:cboAssFonteFamilia.Location=[Drawing.Point]::new(320,403);$script:cboAssFonteFamilia.Size=[Drawing.Size]::new(230,27)
[void]$script:cboAssFonteFamilia.Items.AddRange(@('Arial','Calibri','Verdana','Tahoma','Segoe UI','Times New Roman','Consolas'))
$pgImp.Controls.Add($script:cboAssFonteFamilia)
$tipAssFontFam=New-Object System.Windows.Forms.ToolTip;$tipAssFontFam.SetToolTip($script:cboAssFonteFamilia,'Fonte usada so no nome/cargo das assinaturas, independente da fonte da grade principal.')

$lImpFonte=New-Object System.Windows.Forms.Label;$lImpFonte.Text='Fonte do impresso (nomes/siglas/dias)';$lImpFonte.Location=[Drawing.Point]::new(32,444);$lImpFonte.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lImpFonte)
$script:cboImpFonteFamilia=New-Object System.Windows.Forms.ComboBox;$script:cboImpFonteFamilia.DropDownStyle='DropDownList';$script:cboImpFonteFamilia.Location=[Drawing.Point]::new(320,441);$script:cboImpFonteFamilia.Size=[Drawing.Size]::new(230,27)
[void]$script:cboImpFonteFamilia.Items.AddRange(@('Arial','Calibri','Verdana','Tahoma','Segoe UI','Times New Roman','Consolas'))
$pgImp.Controls.Add($script:cboImpFonteFamilia)
$tipImpFonteFamilia=New-Object System.Windows.Forms.ToolTip;$tipImpFonteFamilia.SetToolTip($script:cboImpFonteFamilia,'Vale para toda a grade impressa (nomes, siglas e dias). A legenda e as assinaturas continuam em Arial, com seu proprio tamanho de fonte configurado ao lado.')

$lImpGradeFonte=New-Object System.Windows.Forms.Label;$lImpGradeFonte.Text='Tamanho da fonte da grade (pt)';$lImpGradeFonte.Location=[Drawing.Point]::new(32,482);$lImpGradeFonte.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lImpGradeFonte)
$script:numImpGradeFonte=New-Object System.Windows.Forms.NumericUpDown;$script:numImpGradeFonte.Location=[Drawing.Point]::new(320,479);$script:numImpGradeFonte.Size=[Drawing.Size]::new(90,27);$script:numImpGradeFonte.Minimum=4.0;$script:numImpGradeFonte.Maximum=10.0;$script:numImpGradeFonte.DecimalPlaces=1;$script:numImpGradeFonte.Increment=0.1;$pgImp.Controls.Add($script:numImpGradeFonte)
$tipImpGradeFonte=New-Object System.Windows.Forms.ToolTip;$tipImpGradeFonte.SetToolTip($script:numImpGradeFonte,'Maximo de 10pt de proposito: a largura da coluna de cada dia e calculada automaticamente para caber na folha A4 (varia com o numero de dias do mes e com as margens configuradas). Acima de 10pt as siglas de 2 letras (FS, PT, C1...) correm risco de ficar cortadas na impressao.')

$lCabFont=New-Object System.Windows.Forms.Label;$lCabFont.Text='Fonte do cabecalho (pt)';$lCabFont.Location=[Drawing.Point]::new(32,520);$lCabFont.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lCabFont)
$script:numCabecalhoFonte=New-Object System.Windows.Forms.NumericUpDown;$script:numCabecalhoFonte.Location=[Drawing.Point]::new(320,517);$script:numCabecalhoFonte.Size=[Drawing.Size]::new(90,27);$script:numCabecalhoFonte.Minimum=5;$script:numCabecalhoFonte.Maximum=14;$pgImp.Controls.Add($script:numCabecalhoFonte)
$tipCabFont=New-Object System.Windows.Forms.ToolTip;$tipCabFont.SetToolTip($script:numCabecalhoFonte,'Tamanho do texto no quadro SETOR / TOTAL DE LEITOS / MES-ANO / GERENTE TECNICA, no topo da folha impressa.')

$lCabFontFam=New-Object System.Windows.Forms.Label;$lCabFontFam.Text='Tipo de fonte do cabecalho';$lCabFontFam.Location=[Drawing.Point]::new(32,558);$lCabFontFam.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lCabFontFam)
$script:cboCabFonteFamilia=New-Object System.Windows.Forms.ComboBox;$script:cboCabFonteFamilia.DropDownStyle='DropDownList';$script:cboCabFonteFamilia.Location=[Drawing.Point]::new(320,555);$script:cboCabFonteFamilia.Size=[Drawing.Size]::new(230,27)
[void]$script:cboCabFonteFamilia.Items.AddRange(@('Arial','Calibri','Verdana','Tahoma','Segoe UI','Times New Roman','Consolas'))
$pgImp.Controls.Add($script:cboCabFonteFamilia)
$tipCabFontFam=New-Object System.Windows.Forms.ToolTip;$tipCabFontFam.SetToolTip($script:cboCabFonteFamilia,'Fonte usada so no quadro SETOR/LEITOS/MES/GERENTE, independente da fonte da grade principal.')

$impNote=New-Object System.Windows.Forms.Label;$impNote.Text="Modelo A4 paisagem. A legenda fica a direita e as assinaturas em pares a esquerda.`r`nOs controles numericos permitem ajustar a compactacao sem alterar o codigo.`r`nA fonte e o tamanho da grade valem para os nomes, siglas e dias da escala impressa.";$impNote.Location=[Drawing.Point]::new(32,596);$impNote.Size=[Drawing.Size]::new(850,60);$impNote.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgImp.Controls.Add($impNote)

$lInstTitle=New-Object System.Windows.Forms.Label;$lInstTitle.Text='CABECALHO INSTITUCIONAL DA IMPRESSAO';$lInstTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lInstTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lInstTitle.Location=[Drawing.Point]::new(32,676);$lInstTitle.AutoSize=$true;$pgImp.Controls.Add($lInstTitle)

$lInst1=New-Object System.Windows.Forms.Label;$lInst1.Text='Linha 1';$lInst1.Location=[Drawing.Point]::new(32,712);$lInst1.Size=[Drawing.Size]::new(90,24);$pgImp.Controls.Add($lInst1)
$script:txtInstLinha1=New-Object System.Windows.Forms.TextBox;$script:txtInstLinha1.Location=[Drawing.Point]::new(130,709);$script:txtInstLinha1.Size=[Drawing.Size]::new(560,25);$pgImp.Controls.Add($script:txtInstLinha1)

$lInst2=New-Object System.Windows.Forms.Label;$lInst2.Text='Linha 2';$lInst2.Location=[Drawing.Point]::new(32,746);$lInst2.Size=[Drawing.Size]::new(90,24);$pgImp.Controls.Add($lInst2)
$script:txtInstLinha2=New-Object System.Windows.Forms.TextBox;$script:txtInstLinha2.Location=[Drawing.Point]::new(130,743);$script:txtInstLinha2.Size=[Drawing.Size]::new(560,25);$pgImp.Controls.Add($script:txtInstLinha2)

$lInst3=New-Object System.Windows.Forms.Label;$lInst3.Text='Linha 3';$lInst3.Location=[Drawing.Point]::new(32,780);$lInst3.Size=[Drawing.Size]::new(90,24);$pgImp.Controls.Add($lInst3)
$script:txtInstLinha3=New-Object System.Windows.Forms.TextBox;$script:txtInstLinha3.Location=[Drawing.Point]::new(130,777);$script:txtInstLinha3.Size=[Drawing.Size]::new(560,25);$pgImp.Controls.Add($script:txtInstLinha3)

$lInst4=New-Object System.Windows.Forms.Label;$lInst4.Text='Linha 4';$lInst4.Location=[Drawing.Point]::new(32,814);$lInst4.Size=[Drawing.Size]::new(90,24);$pgImp.Controls.Add($lInst4)
$script:txtInstLinha4=New-Object System.Windows.Forms.TextBox;$script:txtInstLinha4.Location=[Drawing.Point]::new(130,811);$script:txtInstLinha4.Size=[Drawing.Size]::new(560,25);$pgImp.Controls.Add($script:txtInstLinha4)

$bTrocarLogoGov=New-Button 'TROCAR LOGO GOVERNO' 190;$bTrocarLogoGov.Location=[Drawing.Point]::new(32,850);$bTrocarLogoGov.Add_Click({Trocar-LogoImpressao 'logo_governo'});$pgImp.Controls.Add($bTrocarLogoGov)
$bTrocarLogoHrms=New-Button 'TROCAR LOGO HRMS' 190;$bTrocarLogoHrms.Location=[Drawing.Point]::new(232,850);$bTrocarLogoHrms.Add_Click({Trocar-LogoImpressao 'logo_hrms'});$pgImp.Controls.Add($bTrocarLogoHrms)
$lLogoInfo=New-Object System.Windows.Forms.Label;$lLogoInfo.Text='Aceita PNG ou JPG. O arquivo escolhido substitui o logo atual (Recursos\logo_governo.png / logo_hrms.png).';$lLogoInfo.Location=[Drawing.Point]::new(32,886);$lLogoInfo.Size=[Drawing.Size]::new(700,22);$lLogoInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgImp.Controls.Add($lLogoInfo)

$lTextosTitle=New-Object System.Windows.Forms.Label;$lTextosTitle.Text='TEXTOS FIXOS DA IMPRESSAO';$lTextosTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lTextosTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lTextosTitle.Location=[Drawing.Point]::new(32,928);$lTextosTitle.AutoSize=$true;$pgImp.Controls.Add($lTextosTitle)

$lTitAss=New-Object System.Windows.Forms.Label;$lTitAss.Text='Titulo do bloco de assinaturas';$lTitAss.Location=[Drawing.Point]::new(32,964);$lTitAss.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lTitAss)
$script:txtTituloAssinaturas=New-Object System.Windows.Forms.TextBox;$script:txtTituloAssinaturas.Location=[Drawing.Point]::new(320,961);$script:txtTituloAssinaturas.Size=[Drawing.Size]::new(280,25);$pgImp.Controls.Add($script:txtTituloAssinaturas)

$lTitLeg=New-Object System.Windows.Forms.Label;$lTitLeg.Text='Titulo da legenda de siglas';$lTitLeg.Location=[Drawing.Point]::new(32,998);$lTitLeg.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lTitLeg)
$script:txtTituloLegenda=New-Object System.Windows.Forms.TextBox;$script:txtTituloLegenda.Location=[Drawing.Point]::new(320,995);$script:txtTituloLegenda.Size=[Drawing.Size]::new(280,25);$pgImp.Controls.Add($script:txtTituloLegenda)

$lTxtChefia=New-Object System.Windows.Forms.Label;$lTxtChefia.Text='Texto padrao sem assinatura cadastrada';$lTxtChefia.Location=[Drawing.Point]::new(32,1032);$lTxtChefia.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lTxtChefia)
$script:txtTextoChefiaPadrao=New-Object System.Windows.Forms.TextBox;$script:txtTextoChefiaPadrao.Location=[Drawing.Point]::new(320,1029);$script:txtTextoChefiaPadrao.Size=[Drawing.Size]::new(280,25);$pgImp.Controls.Add($script:txtTextoChefiaPadrao)
$tipTxtChefia=New-Object System.Windows.Forms.ToolTip;$tipTxtChefia.SetToolTip($script:txtTextoChefiaPadrao,'Usado so quando o setor nao tem nenhuma Assinatura cadastrada (aba Assinaturas) nem Chefia preenchida no cadastro do Setor.')

$lMargensTitle=New-Object System.Windows.Forms.Label;$lMargensTitle.Text='MARGENS DA IMPRESSAO (AVANCADO)';$lMargensTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lMargensTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lMargensTitle.Location=[Drawing.Point]::new(32,1074);$lMargensTitle.AutoSize=$true;$pgImp.Controls.Add($lMargensTitle)

$lMargPag=New-Object System.Windows.Forms.Label;$lMargPag.Text='Margem de seguranca A4 (mm)';$lMargPag.Location=[Drawing.Point]::new(32,1110);$lMargPag.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lMargPag)
$script:numMargemPagina=New-Object System.Windows.Forms.NumericUpDown;$script:numMargemPagina.Location=[Drawing.Point]::new(320,1107);$script:numMargemPagina.Size=[Drawing.Size]::new(90,27);$script:numMargemPagina.Minimum=7;$script:numMargemPagina.Maximum=20;$script:numMargemPagina.DecimalPlaces=1;$script:numMargemPagina.Increment=0.5;$pgImp.Controls.Add($script:numMargemPagina)
$lMargSeg=New-Object System.Windows.Forms.Label;$lMargSeg.Text='Minimo de 7 mm em todos os lados e em todas as paginas impressas.';$lMargSeg.ForeColor=[System.Drawing.Color]::FromArgb(180,83,9);$lMargSeg.Location=[Drawing.Point]::new(430,1110);$lMargSeg.Size=[Drawing.Size]::new(700,24);$pgImp.Controls.Add($lMargSeg)

$lPadFolha=New-Object System.Windows.Forms.Label;$lPadFolha.Text='Espaco interno da folha (mm)';$lPadFolha.Location=[Drawing.Point]::new(32,1148);$lPadFolha.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lPadFolha)
$script:numPaddingFolha=New-Object System.Windows.Forms.NumericUpDown;$script:numPaddingFolha.Location=[Drawing.Point]::new(320,1145);$script:numPaddingFolha.Size=[Drawing.Size]::new(90,27);$script:numPaddingFolha.Minimum=0;$script:numPaddingFolha.Maximum=15;$script:numPaddingFolha.DecimalPlaces=1;$script:numPaddingFolha.Increment=0.5;$pgImp.Controls.Add($script:numPaddingFolha)
$lEspSetores=New-Object System.Windows.Forms.Label;$lEspSetores.Text='Espaco entre setores no combinado (mm)';$lEspSetores.Location=[Drawing.Point]::new(32,1182);$lEspSetores.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lEspSetores)
$script:numEspacoSetores=New-Object System.Windows.Forms.NumericUpDown;$script:numEspacoSetores.Location=[Drawing.Point]::new(320,1179);$script:numEspacoSetores.Size=[Drawing.Size]::new(90,27);$script:numEspacoSetores.Minimum=0;$script:numEspacoSetores.Maximum=30;$script:numEspacoSetores.DecimalPlaces=1;$script:numEspacoSetores.Increment=0.5;$pgImp.Controls.Add($script:numEspacoSetores)
$tipEspSetores=New-Object System.Windows.Forms.ToolTip;$tipEspSetores.SetToolTip($script:numEspacoSetores,'Vale so para PRE-VISUALIZAR COMBINADO: espaco entre o fim de um setor e o inicio do proximo (cada setor ja comeca em pagina nova).')
$lMargInfo=New-Object System.Windows.Forms.Label;$lMargInfo.Text="Cuidado: aumentar demais estas margens reduz o espaco disponivel para as colunas de dia,`r`nque ja se ajustam sozinhas para caber em qualquer mes. So mexa aqui se souber o que esta fazendo.";$lMargInfo.Location=[Drawing.Point]::new(32,1214);$lMargInfo.Size=[Drawing.Size]::new(600,54);$lMargInfo.ForeColor=[Drawing.Color]::FromArgb(180,83,9);$pgImp.Controls.Add($lMargInfo)

$lLegendaOrdemTitle=New-Object System.Windows.Forms.Label;$lLegendaOrdemTitle.Text='ORDEM DA LEGENDA DAS SIGLAS';$lLegendaOrdemTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lLegendaOrdemTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lLegendaOrdemTitle.Location=[Drawing.Point]::new(32,1272);$lLegendaOrdemTitle.AutoSize=$true;$pgImp.Controls.Add($lLegendaOrdemTitle)
$lLegendaOrdem=New-Object System.Windows.Forms.Label;$lLegendaOrdem.Text='Ordenar a legenda por';$lLegendaOrdem.Location=[Drawing.Point]::new(32,1308);$lLegendaOrdem.Size=[Drawing.Size]::new(260,24);$pgImp.Controls.Add($lLegendaOrdem)
$script:cboLegendaOrdem=New-Object System.Windows.Forms.ComboBox;$script:cboLegendaOrdem.DropDownStyle='DropDownList';$script:cboLegendaOrdem.Location=[Drawing.Point]::new(320,1305);$script:cboLegendaOrdem.Size=[Drawing.Size]::new(280,27)
[void]$script:cboLegendaOrdem.Items.Add('Descricao (agrupa "Folga...", "Plantao...", etc. juntos)')
[void]$script:cboLegendaOrdem.Items.Add('Sigla (ordem alfabetica AT, C1, C2...)')
$pgImp.Controls.Add($script:cboLegendaOrdem)
$lLegendaOrdemInfo=New-Object System.Windows.Forms.Label;$lLegendaOrdemInfo.Text='Por Descricao, siglas parecidas (ex.: Folga Feriado, Folga Matutino, Folga Semana) ficam uma embaixo da outra na legenda impressa.';$lLegendaOrdemInfo.Location=[Drawing.Point]::new(32,1344);$lLegendaOrdemInfo.Size=[Drawing.Size]::new(555,62);$lLegendaOrdemInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105);$pgImp.Controls.Add($lLegendaOrdemInfo)

$grpLegendaAv=New-Object System.Windows.Forms.GroupBox
$grpLegendaAv.Text='Layout avancado da legenda'
$grpLegendaAv.Location=[Drawing.Point]::new(640,1248)
$grpLegendaAv.Size=[Drawing.Size]::new(540,270)
$pgImp.Controls.Add($grpLegendaAv)

$lLegPares=New-Object System.Windows.Forms.Label
$lLegPares.Text='Pares SIGLA / SIGNIFICADO'
$lLegPares.Location=[Drawing.Point]::new(22,38)
$lLegPares.Size=[Drawing.Size]::new(255,26)
$grpLegendaAv.Controls.Add($lLegPares)

$script:numLegendaPares=New-Object System.Windows.Forms.NumericUpDown
$script:numLegendaPares.Location=[Drawing.Point]::new(300,35)
$script:numLegendaPares.Size=[Drawing.Size]::new(90,28)
$script:numLegendaPares.Minimum=1
$script:numLegendaPares.Maximum=3
$script:numLegendaPares.Value=2
$grpLegendaAv.Controls.Add($script:numLegendaPares)

$lLegPos=New-Object System.Windows.Forms.Label
$lLegPos.Text='Posicao do bloco'
$lLegPos.Location=[Drawing.Point]::new(22,84)
$lLegPos.Size=[Drawing.Size]::new(210,26)
$grpLegendaAv.Controls.Add($lLegPos)

$script:cboLegendaPosicao=New-Object System.Windows.Forms.ComboBox
$script:cboLegendaPosicao.DropDownStyle='DropDownList'
$script:cboLegendaPosicao.Location=[Drawing.Point]::new(240,81)
$script:cboLegendaPosicao.Size=[Drawing.Size]::new(210,28)
[void]$script:cboLegendaPosicao.Items.AddRange(@('Direita','Esquerda'))
$script:cboLegendaPosicao.SelectedIndex=0
$grpLegendaAv.Controls.Add($script:cboLegendaPosicao)

$lLegAvInfo=New-Object System.Windows.Forms.Label
$lLegAvInfo.Text="1 par  - legenda mais estreita e mais alta.`r`n2 pares - formato equilibrado (padrao).`r`n3 pares - legenda mais larga e mais baixa.`r`n`r`nA posicao define em qual lado da area inferior da folha a legenda sera exibida."
$lLegAvInfo.Location=[Drawing.Point]::new(22,132)
$lLegAvInfo.Size=[Drawing.Size]::new(490,125)
$lLegAvInfo.ForeColor=[Drawing.Color]::FromArgb(71,85,105)
$lLegAvInfo.BackColor=[Drawing.Color]::FromArgb(248,250,252)
$lLegAvInfo.BorderStyle='FixedSingle'
$lLegAvInfo.Padding=New-Object System.Windows.Forms.Padding(10,8,10,8)
$grpLegendaAv.Controls.Add($lLegAvInfo)


$lAssFormatoTitle=New-Object System.Windows.Forms.Label;$lAssFormatoTitle.Text='FORMATO DAS ASSINATURAS';$lAssFormatoTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lAssFormatoTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lAssFormatoTitle.Location=[Drawing.Point]::new(32,1530);$lAssFormatoTitle.AutoSize=$true;$pgImp.Controls.Add($lAssFormatoTitle)
$script:chkAssLinhasSeparadas=New-Object System.Windows.Forms.CheckBox;$script:chkAssLinhasSeparadas.Text='Nome, Cargo e Coren em linhas separadas (desmarcado = Cargo e Coren juntos numa linha so)';$script:chkAssLinhasSeparadas.Location=[Drawing.Point]::new(32,1566);$script:chkAssLinhasSeparadas.Size=[Drawing.Size]::new(700,26);$pgImp.Controls.Add($script:chkAssLinhasSeparadas)
$tipAssLinhas=New-Object System.Windows.Forms.ToolTip;$tipAssLinhas.SetToolTip($script:chkAssLinhasSeparadas,'Marcado: Nome / Cargo / Coren, cada um na sua linha. Desmarcado: Nome / Cargo - Coren juntos.')

$lAbreviarTitle=New-Object System.Windows.Forms.Label;$lAbreviarTitle.Text='NOMES NA IMPRESSAO';$lAbreviarTitle.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9);$lAbreviarTitle.ForeColor=[System.Drawing.Color]::FromArgb(90,105,124);$lAbreviarTitle.Location=[Drawing.Point]::new(32,1614);$lAbreviarTitle.AutoSize=$true;$pgImp.Controls.Add($lAbreviarTitle)
$script:chkAbreviarNomes=New-Object System.Windows.Forms.CheckBox;$script:chkAbreviarNomes.Text='Abreviar automaticamente nomes muito longos na impressao';$script:chkAbreviarNomes.Location=[Drawing.Point]::new(32,1646);$script:chkAbreviarNomes.Size=[Drawing.Size]::new(560,26);$pgImp.Controls.Add($script:chkAbreviarNomes)
$tipAbreviarNomes=New-Object System.Windows.Forms.ToolTip;$tipAbreviarNomes.SetToolTip($script:chkAbreviarNomes,'So encurta nomes DO MEIO (ex.: Fabiane Ortiz de Araujo de Lima -> Fabiane O. de Araujo de Lima). O primeiro nome e o ultimo sobrenome sempre ficam por extenso. O limite e calculado sozinho a partir da largura real da coluna Nomes e do tamanho/tipo de fonte configurados acima - nao precisa ajustar nada. Nao afeta as assinaturas.')
$lAbreviarInfo=New-Object System.Windows.Forms.Label;$lAbreviarInfo.Text='O limite e calculado automaticamente pela largura da coluna Nomes e pela fonte configurada acima (Fonte do impresso). Aumentar a fonte abrevia mais nomes; diminuir abrevia menos.';$lAbreviarInfo.ForeColor=[System.Drawing.Color]::FromArgb(100,100,100);$lAbreviarInfo.Location=[Drawing.Point]::new(32,1678);$lAbreviarInfo.Size=[Drawing.Size]::new(700,40);$pgImp.Controls.Add($lAbreviarInfo)


# V1.0.14.65 - Perfil de impressao acompanha os controles em tempo real.
# O proprio combo de Perfil NAO entra na lista para evitar recursao.
$script:PrintProfileWatchControls=@(
    $script:chkImpLegenda,$script:chkImpTodasSiglas,$script:chkImpAss,$script:chkImpFds,$script:chkImpFer,
    $script:numLegendaFonte,$script:numLegendaSiglaMm,$script:numAssinaturaFonte,$script:numCabecalhoFonte,
    $script:numImpGradeFonte,$script:numMargemPagina,$script:numPaddingFolha,$script:numEspacoSetores,
    $script:chkAssLinhasSeparadas,$script:cboLegendaOrdem,$script:numLegendaPares,$script:cboLegendaPosicao,
    $script:cboAssFonteFamilia,$script:cboCabFonteFamilia,$script:cboImpFonteFamilia
)
foreach($ctlPerfil in @($script:PrintProfileWatchControls)){
    if($null -eq $ctlPerfil){continue}
    if($ctlPerfil -is [System.Windows.Forms.CheckBox]){
        $ctlPerfil.Add_CheckedChanged({Update-PrintProfileSelection -FromWatcher})
    }elseif($ctlPerfil -is [System.Windows.Forms.NumericUpDown]){
        $ctlPerfil.Add_ValueChanged({Update-PrintProfileSelection -FromWatcher})
    }elseif($ctlPerfil -is [System.Windows.Forms.ComboBox]){
        $ctlPerfil.Add_SelectedIndexChanged({Update-PrintProfileSelection -FromWatcher})
    }
}


# Cada sub-aba de Configuracoes ganha seu proprio botao SALVAR, fixo no rodape,
# alem do "SALVAR CONFIGURACOES" no topo (que ja salva tudo de qualquer aba).
# E o mesmo Save-ConfiguracoesUI: nao existe "salvar so esta aba", salva tudo.
foreach ($pgConf in $cfgTabs.TabPages) {
    $pRodapeConf = New-Object System.Windows.Forms.Panel
    $pRodapeConf.Dock = 'Bottom'; $pRodapeConf.Height = 46
    $pRodapeConf.BackColor = [System.Drawing.Color]::FromArgb(248,250,252)
    $pgConf.Controls.Add($pRodapeConf)
    $bRodapeSalvar = New-Button 'SALVAR' 120
    Set-PrimaryButton $bRodapeSalvar
    $bRodapeSalvar.Location = [Drawing.Point]::new(20,6)
    $bRodapeSalvar.Add_Click({ Save-ConfiguracoesUI })
    $pRodapeConf.Controls.Add($bRodapeSalvar)
}


# Startup
# V1.0.14.22 - Toda a inicializacao que mexe em combos (Refresh-SetorCombos,
# Refresh-OcorrenciaFilterCombos, selecionar Mes/Ano, etc.) precisa rodar
# DEPOIS que a janela principal existe de verdade (BindingContext pronto),
# senao o WinForms pode falhar com "Nao e possivel ligar ao novo membro de
# exibicao" logo na abertura do sistema - mesma causa raiz ja corrigida em
# telas especificas (Nova Ocorrencia, Lotacao em Lote), agora tambem aqui.
# V1.0.14.22.1 - Cada etapa roda no seu proprio try/catch: se uma etapa
# falhar, as demais continuam executando (antes, uma falha em qualquer ponto
# interrompia tudo, deixando Setor/Sub_Setor e outros combos vazios). O log
# registra exatamente qual etapa e linha falhou, para diagnostico.
function Invoke-StartupStep {
    param([string]$Nome,[scriptblock]$Acao)
    try {
        & $Acao
    } catch {
        $linha=$(if($_.InvocationInfo){$_.InvocationInfo.ScriptLineNumber}else{'?'})
        $script:StartupErrors += ("{0} (linha {1}): {2}" -f $Nome,$linha,$_.Exception.Message)
        Write-Log ("Falha na etapa de inicializacao '{0}' (linha {1}): {2}" -f $Nome,$linha,$_.Exception.Message)
    }
}
$script:StartupErrors=New-Object System.Collections.ArrayList
foreach($cfMsg in @($script:CompatFailures)){[void]$script:StartupErrors.Add([string]$cfMsg)}
$script:StartupAbort=$false
# V1.0.14.22 - Esconde o console preto (janela do PowerShell) assim que a
# tela principal do sistema aparece. Fica visivel ATE esse ponto de proposito:
# se algo falhar bem no comeco da inicializacao (antes da tela aparecer), o
# console continua visivel com a mensagem de erro, que ja nos ajudou varias
# vezes a diagnosticar problemas (ver Logs\Sistema_Escala.log tambem). So
# depois que a janela principal esta confirmadamente na tela e que o console
# e escondido, sem fechar o processo (ainda roda por baixo, so nao aparece).
try {
    Add-Type -Name ConsoleWin -Namespace EscalaDCE -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@ -ErrorAction Stop
} catch { Write-Log ('Nao foi possivel preparar a rotina de esconder o console: ' + $_.Exception.Message) }

function Hide-ConsoleWindow {
    try {
        $h = [EscalaDCE.ConsoleWin]::GetConsoleWindow()
        if ($h -ne [IntPtr]::Zero) { [void][EscalaDCE.ConsoleWin]::ShowWindow($h, 0) }
    } catch { Write-Log ('Falha ao esconder a janela de console: ' + $_.Exception.Message) }
}

$script:MainForm.Add_Shown({
    Hide-ConsoleWindow
    # SQLite, journal e migracoes criticas ja foram validados antes da MainForm.
    Invoke-StartupStep 'Cache de Configuracoes' { [void](Refresh-ConfigCache) }
    Invoke-StartupStep 'Combos de Setor' { Refresh-SetorCombos }
    Invoke-StartupStep 'Combos de Ocorrencia' { Refresh-OcorrenciaFilterCombos }
    Invoke-StartupStep 'Configuracoes' { Load-ConfiguracoesUI }
    Invoke-StartupStep 'Mes/Ano padrao' {
        $usarAtual=Get-ConfigBool 'abrir_mes_atual' $true
        if($usarAtual){$agora=Get-Date;$mesIni=$agora.Month;$anoIni=$agora.Year}else{$mesIni=Get-ConfigInt 'mes_padrao' 8 1 12;$anoIni=Get-ConfigInt 'ano_padrao' 2026 2024 2100}
        $script:cboMes.SelectedValue=[string]$mesIni
        $script:numAno.Value=$anoIni
        $script:cboOcMes.SelectedValue=[string]$mesIni;$script:cboOcAno.SelectedValue=[string]$anoIni
    }
    Invoke-StartupStep 'Lista de Servidores' { Load-Servidores }
    Invoke-StartupStep 'Lista de Readaptados' { Load-Readaptados }
    Invoke-StartupStep 'Lista de Setores' { Load-Setores }
    Invoke-StartupStep 'Lista de Horarios' { Load-Horarios }
    Invoke-StartupStep 'Lista de Siglas' { Load-Siglas }
    Invoke-StartupStep 'Lista de Assinaturas' { Load-Assinaturas }
    Invoke-StartupStep 'Preferencias da grade' { Apply-GridPreferences }
    Invoke-StartupStep 'Interface da aba Escala' { Apply-ScaleInterfaceStyle }
    Invoke-StartupStep 'Lista de Feriados' { Load-Feriados }
    Invoke-StartupStep 'Escala do mes' { Load-Escala }
    Invoke-StartupStep 'Servidores de Ocorrencia' { Load-OcorrenciaServidores }
    Invoke-StartupStep 'Lista de Ocorrencias' { Load-Ocorrencias }
    if($script:StartupErrors.Count -gt 0){
        Show-Error ("Alguns itens falharam ao carregar na abertura (o restante do sistema continua funcionando):`r`n`r`n" + ($script:StartupErrors -join "`r`n"))
    } else {
        Write-Log 'Sistema iniciado - base estavel com fluxo guiado disponivel.'
    }
})

$script:MainForm.Add_FormClosing({
    try {
        if((-not $script:StartupAbort) -and (Get-ConfigBool 'backup_automatico_saida' $true)){ Backup-Database -Silencioso }
    } catch { Write-Log ('Falha no backup automatico de saida: ' + $_.Exception.Message) }
})

try {
    [System.Windows.Forms.Application]::Run($script:MainForm)
} finally {
    Invoke-SafeRuntimeCleanup
}
