# Plantão Extra HTML — V1.7.7

## O que foi acrescentado

No próprio HTML, o painel **Ajustes da impressão** permite controlar separadamente:

1. **Identificação da extra:** órgão, unidade, setor e data da folha.
2. **Dados pessoais e horários:** grade de matrícula, CP, nome, carga horária, cargo e horários.
3. **Justificativa:** texto da grade de justificativas.

Os tamanhos aceitam valores de 8 a 20 px, em passos de 0,5. Os valores iniciais preservam os tamanhos de conteúdo anteriores: 12, 10,5 e 10 px, respectivamente. Cabeçalhos das grades acompanham o ajuste, com diferença proporcional para manter a hierarquia visual.

O campo **Texto do decreto / resolução no topo da folha** permite substituir a referência normativa sem abrir o editor VBA. A alteração aparece nas folhas principal e adicionais. É possível informar um decreto, uma resolução ou o texto aplicável à impressão.

As mudanças são aplicadas na hora. Os controles de ajuste não aparecem na impressão/PDF. Fontes maiores podem aumentar a altura das linhas e o número de páginas; confira a prévia antes de imprimir.

## Salvar para as próximas impressões

Após ajustar os tamanhos e o texto normativo, clique em **Salvar preferências**.

São guardados somente os três tamanhos e o texto normativo. Datas, servidores selecionados e registros da base não são salvos nessas preferências. Os ajustes ficam neste computador/perfil do navegador; não são gravados no banco Access nem enviados à internet.

Nas próximas gerações pelo Access, os ajustes salvos são carregados. Para manter o mesmo endereço local entre as gerações, o navegador passa a abrir:

`DCE_PlantaoExtra\PlantaoExtra_Visualizacao.html`

O módulo também continua criando as cópias HTML com nomes datados. A visualização fixa é atualizada a cada geração; uma aba já aberta mantém o conteúdo carregado até ser atualizada. Abrir uma cópia datada manualmente pode usar um espaço de preferências separado, conforme o navegador.

Use o **mesmo navegador/perfil** nas próximas gerações. Modo privado, limpeza dos dados do navegador, troca do caminho temporário ou bloqueio do armazenamento podem impedir a recuperação dos ajustes. O botão informa se a gravação foi confirmada ou falhou; os ajustes desta página continuam utilizáveis mesmo quando não é possível salvá-los.

**Restaurar padrão** repõe as fontes originais e o texto normativo original, removendo as preferências salvas. Alterações que não forem salvas valem apenas para a página atual.

## Instalação no Access

1. Faça backup do banco/front-end e do módulo atual.
2. Abra o editor VBA (`Alt+F11`) e o módulo existente **modPlantaoExtraHTML**.
3. Abra `modPlantaoExtraHTML.txt` e substitua todo o conteúdo do módulo com `Ctrl+A` e colar. Não é necessário excluir o módulo.
4. Execute **Depurar > Compilar**, salve e gere um HTML novo.
5. Ajuste as fontes/texto, salve as preferências e gere outra impressão pelo Access para conferir a recuperação no seu navegador.

O BAS completo está disponível como alternativa de importação. Para atualizar o módulo existente, prefira o TXT. Ambos usam Windows-1252/ANSI e CRLF.

As chamadas dos botões não mudam:

```vb
modPlantaoExtraHTML.AbrirCentralImpressao Me
modPlantaoExtraHTML.GerarDoFormulario Me
modPlantaoExtraHTML.GerarCentralPorPeriodo Me, dataInicio, dataFim
```

Datas preenchidas, filtros, seleção e agrupamento da impressão foram preservados. A correção da abertura da Central Geral, os caches de consulta e a atualização de andamento da V1.7.6 também foram mantidos. Para reverter, reponha o conteúdo do módulo salvo no backup.

## Verificações realizadas

Foram executadas **16 verificações em Chromium real**, usando HTML montado das concatenações e condicionais do VBA e exclusivamente dados fictícios. Cobriram:

- tamanhos padrão e três reguladores independentes;
- digitação de valores decimais sem o campo interromper a edição;
- alteração do texto normativo na folha principal e nas folhas adicionais;
- salvamento, abertura seguinte e reinício do navegador com perfil persistente;
- nova geração da Central com as preferências, datas e registros corretos;
- armazenamento somente das preferências, sem dados dos servidores;
- inserção segura de caracteres HTML como texto normativo;
- controles ocultos na impressão e fontes preservadas;
- geração de PDF sintético e chamada do botão Imprimir;
- restauração dos padrões, limites de fonte, preferências corrompidas e armazenamento bloqueado;
- ausência de erros JavaScript não tratados nos cenários executados.

O teste de armazenamento usou uma origem HTTP local de teste e endereço estável, sem publicação de site. **O armazenamento em `file://` no Chrome/Windows e a compilação VBA precisam de conferência no computador de trabalho.** O caminho fixo foi adotado justamente para evitar depender de compartilhamento de preferências entre nomes de arquivos locais diferentes, comportamento que varia entre navegadores.

Na revisão estática, as interfaces públicas, as funções DAO/SQL, os caches e os controles de progresso foram preservados. As cópias datadas continuam sendo gravadas; somente a abertura foi direcionada ao arquivo de visualização estável. Literais VBA, Windows-1252 e CRLF foram conferidos. Esta conferência não equivale à compilação nativa do Access, indisponível neste ambiente.

A pasta `Validacao` contém resultados e testes, além de páginas/PDF exclusivamente fictícios. Não é necessário executá-los para usar o módulo. A V1.7.7 deve ser considerada nova base estável após sua conferência prática no Access e no navegador local.
