# Validação de exportação HIST-R12

20 de 20 rodadas aprovadas: 4600 verificações de exportação, em pt-BR, en-US, de-DE, fr-FR e es-ES, com seeds 12001 a 12020. Em cada rodada também passou o contrato Python de campos, XML, datas, XLSX e fluxo estático do VBA.

PS1 SHA-256: `7a26209f1b6ae551279788410387945320e131a8cf7b3377f04c2c352eaf7a6b`.
BAS SHA-256: `1c696728b57aaf2b61882d736d4b7324c07413a97a0294465717e838407317e9`.

Cobertura executada: parse do PS1, geração do XML com UTF-8 e datas ISO, 13 campos sem autonumeração, valores nulos, observação com Unicode/aspas/quebra de linha, CP ausente ou compartilhado por matrículas diferentes, duplicação/divergência na origem, aceites comuns e FR independentes, 15+15 com ano bissexto, exclusão de fixas/pedidos pendentes, geração XLSX anterior e preservação da base real recebida (arquivo e objetos em memória).

A base recebida foi apenas lida, não publicada nem alterada. Arquivos XML gerados durante a validação são locais e não integram a entrega pública.

Limites: as verificações do importador VBA foram estáticas. Não houve execução/compilação no Access, teste de transação no ACE/Jet, nem simulação real de dois clientes SMB. Não são apresentados como comprovados idempotência, rollback ou concorrência em Access. O roteiro de aceitação em cópia do banco está em LEIA_PRIMEIRO.md.
