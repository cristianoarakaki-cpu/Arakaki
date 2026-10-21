# Lançamentos: interface compacta HIST-R4

O painel de filtros e ações passa de 285 para 178 pixels de altura. Os filtros ocupam três linhas mais próximas, com largura máxima de 500 pixels. A divisão inicial destina 45% da largura à lista, preservando os limites mínimos já existentes.

Uma barra ToolStrip substitui as três fileiras de botões. Pendências, Limpar filtros e Novo servidor ficam na barra; os menus Formulários, Relatórios e Exclusão agrupam as demais ações. O overflow nativo mantém os comandos acessíveis quando a barra não comporta todos. Os eventos existentes permanecem ligados aos mesmos identificadores dos controles, incluindo contagens de pendências, excluídos e selecionados para exclusão. Confirmações de exclusão existentes são preservadas.

Validação: análise sintática sem erros, Base.ps1 com 108 verificações aprovadas e Identidade.ps1 com oito verificações aprovadas. Revisão das referências dos controles e diff sem problemas de espaços, considerando CRLF. WinForms não está disponível no executor Linux; aparência, menus e escala de tela precisam de validação no Windows. Esta versão inclui as melhorias de conferência de nomes da HIST-R3.
