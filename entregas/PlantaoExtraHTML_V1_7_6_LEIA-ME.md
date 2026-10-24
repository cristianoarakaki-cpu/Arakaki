# Plantão Extra HTML — V1.7.6

## Grade vazia ao abrir: causa e correção

A Central Geral não possui o painel `listaServidores`, usado apenas pelo modo Registro Atual. A inicialização chamava `renderLista()` sem verificar a existência desse painel. O erro de JavaScript interrompia o restante da abertura antes de desenhar a grade central.

“Limpar filtros” chamava a renderização da grade novamente e, por isso, os registros apareciam. As datas preenchidas não eram a causa desse erro.

Agora `renderLista()` retorna normalmente quando seu painel não existe. A Central Geral continua sua inicialização e já mostra os registros com o intervalo preenchido.

O teste anterior usava um DOM simulado que criava todos os elementos pedidos, inclusive o painel ausente. Isso ocultou o defeito. Nesta revisão, reproduzi a estrutura condicional real em Chromium, incluindo a ausência do painel, e confirmei tanto a falha anterior quanto a abertura corrigida.

## Alterações para reduzir a demora no Access

- Resultados das buscas auxiliares por servidor/campo são reaproveitados durante a geração. O mesmo servidor em vários dias não exige repetir a mesma busca de matrícula, nome ou cargo.
- Metadados de campos encontrados nas tabelas são reaproveitados, preservando a descoberta dinâmica e a ordem dos candidatos.
- A conexão DAO das buscas auxiliares é reutilizada durante a geração e liberada ao concluir ou falhar.
- A barra de status informa a leitura dos registros. Um `DoEvents` controlado, no máximo a cada 150 ms quando há progresso entre registros, permite que o Access processe mensagens de interface.
- Uma guarda impede iniciar outra geração deste módulo durante esse processamento.
- Os caches são limpos na saída e não permanecem entre gerações, para que mudanças de cadastro sejam lidas na próxima exportação.

As consultas SQL e a leitura por `dbOpenSnapshot` foram preservadas. Não há alteração, inclusão ou exclusão de registros na base.

**Limite:** essas mudanças reduzem trabalho repetido e permitem atualizar a interface entre etapas. Uma consulta DAO individual ou acesso a arquivo/rede ainda pode levar tempo. Não foi medido o tempo no Access do computador de trabalho; não há promessa de eliminação completa de qualquer pausa.

## Como atualizar

1. Faça backup do banco/front-end e do módulo atual.
2. Abra o editor VBA (`Alt+F11`) e o módulo **modPlantaoExtraHTML**.
3. Abra o TXT deste pacote e substitua todo o conteúdo do módulo existente, usando `Ctrl+A` e colar. Não é necessário excluir o módulo.
4. Execute **Depurar > Compilar**, salve e gere um HTML novo.
5. Abra o arquivo novo: os HTMLs antigos já gerados continuam com o JavaScript anterior.

O BAS completo também está disponível para importação. Para atualizar o módulo existente, prefira o TXT. Os arquivos VBA usam Windows-1252/ANSI e CRLF.

As chamadas permanecem:

```vb
modPlantaoExtraHTML.AbrirCentralImpressao Me
modPlantaoExtraHTML.GerarDoFormulario Me
modPlantaoExtraHTML.GerarCentralPorPeriodo Me, dataInicio, dataFim
```

Datas inicial/final continuam preenchidas: iguais para data específica e registro atual; com os limites escolhidos para intervalo. Setor e Nome/CP múltiplos continuam funcionando. Para voltar à versão anterior, reponha o conteúdo do módulo salvo no backup.

## Verificações realizadas

**Chromium real, com páginas montadas a partir das concatenações e dos condicionais do VBA e dados fictícios:**

1. V1.7.5: reproduzido erro por painel ausente, grade inicial vazia e aparecimento após limpar filtros.
2. V1.7.6: primeira abertura da Central Geral mostra três registros no intervalo de 21 a 25/10, preserva os dois campos e não gera erro de JavaScript.
3. Filtros de Setor e Nome/CP, seleção de visíveis e agrupamento por Setor+Data preservados.
4. O botão Imprimir chama `window.print` sem erro; a impressão física/PDF não foi executada.
5. Limpar filtros funciona sem apagar a seleção de servidores.
6. Data específica abre com o registro correspondente e as duas datas preenchidas.
7. Registro atual mantém sua lista e a folha principal.
8. Período vazio abre sem erro de elemento inexistente.

**Verificações estáticas do VBA:**

- Os 47 procedimentos anteriores permanecem; quatro auxiliares foram acrescentadas.
- Nomes e assinaturas públicas preservados.
- Instruções de construção SQL e chamadas de abertura por `dbOpenSnapshot` preservadas.
- Inicialização/limpeza de caches e guarda de reentrância conferidas no código.
- Literais VBA, exportação do BAS, Windows-1252 e CRLF conferidos.

A montagem do HTML nos testes interpreta as concatenações e condicionais relevantes; ela não executa a consulta DAO nem equivale à execução do VBA no Access. Este ambiente não executa Microsoft Access. A compilação e os testes de desempenho no Access precisam da conferência local. A V1.7.6 só deve ser considerada a nova base estável depois desse teste prático.

A pasta `Validacao` contém resultados, testes de navegador e páginas com dados fictícios. Não é necessário executar esses arquivos para usar o módulo. As páginas de teste não contêm informações da base do usuário.
