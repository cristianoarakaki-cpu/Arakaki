# Plantão Extra HTML — V1.7.5

O HTML agora abre com **Data inicial** e **Data final** preenchidas conforme a chamada:

- **Data específica:** a data escolhida aparece nos dois campos.
- **Intervalo de datas:** cada campo recebe seu respectivo limite.
- **Registro atual:** os dois campos recebem a `Data da Extra`; sem data válida, ficam vazios.

Os valores dos campos HTML são gravados como `yyyy-mm-dd`, formato exigido por `input type=date`. O navegador apresenta a data conforme sua configuração regional.

As datas já participam do primeiro filtro ao abrir o HTML. O intervalo é inclusivo. Setor com vários termos, Nome/CP com vários termos, seleção dos registros e agrupamento da impressão por Setor+Data foram preservados. “Limpar filtros” esvazia os dois campos de data e os filtros textuais, mantendo as seleções.

A consulta SQL/DAO continua limitada ao período originalmente solicitado. Mudar ou limpar datas no HTML filtra somente os registros já carregados; para buscar registros de outro período no banco, gere novamente a Central pelo Access.

## Substituição no Access

1. Faça uma cópia de segurança do banco/front-end e do módulo atual.
2. No editor VBA (`Alt+F11`), abra o módulo existente **modPlantaoExtraHTML**.
3. Abra `modPlantaoExtraHTML.txt`, copie todo o conteúdo e substitua o conteúdo do módulo existente com `Ctrl+A` e colar. **Não precisa excluir o módulo.**
4. Execute **Depurar > Compilar**, salve e teste novamente os botões.

As chamadas continuam iguais, sem alterar os eventos existentes:

```vb
modPlantaoExtraHTML.AbrirCentralImpressao Me
```

Essa chamada mantém as opções de data específica e intervalo. A chamada por registro atual também permanece:

```vb
modPlantaoExtraHTML.GerarDoFormulario Me
```

A chamada direta existente também foi preservada:

```vb
modPlantaoExtraHTML.GerarCentralPorPeriodo Me, dataInicio, dataFim
```

`modPlantaoExtraHTML.bas` é uma alternativa de importação. Para atualizar o módulo já existente, prefira o TXT conforme os passos acima. Ambos contêm o módulo completo em Windows-1252/ANSI com CRLF; o BAS inclui o atributo de nome usado pelo importador VBA.

Para voltar à versão anterior, reponha o conteúdo do módulo salvo no backup.

## Verificações realizadas

- Os 47 procedimentos foram preservados; somente `MontarHtmlComSelecao` e `CssDocumento` tiveram alterações de corpo.
- As três rotinas públicas de abertura/geração permaneceram idênticas, inclusive assinaturas.
- Consultas DAO/SQL, funções auxiliares, composição da impressão e APIs 32/64 bits não foram modificadas.
- Os atributos `value` dos dois inputs foram verificados em cinco cenários de datas, incluindo mudança de ano e registro sem data.
- O JavaScript foi extraído das concatenações reais do VBA e executado no Node.js com DOM simulado. Passaram nove verificações: primeira abertura, intervalo inclusivo, filtros textuais combinados, seleção, agrupamento, chamada de impressão, limpeza, limites isolados e ausência de registros.
- Literais VBA foram conferidos estaticamente. Isso **não equivale a compilar no Access**.

Este ambiente não executa Microsoft Access. A compilação VBA e a abertura real dos dois modos no navegador precisam da conferência local. Essa versão deve ser tratada como nova base estável depois do seu teste no Access.

`RESULTADO_ESTRUTURA.json` e `RESULTADO_JAVASCRIPT.txt` registram as verificações. Nenhum registro do banco foi acessado ou alterado durante o ajuste.
