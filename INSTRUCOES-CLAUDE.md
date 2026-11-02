# Entrega dos scripts do CL - Club Legacy

Este repositorio JA existe: https://github.com/blokadahub/club-legacy-roblox

A infraestrutura esta preparada. Entregue **codigo completo**, com indicacao do caminho de cada arquivo, em vez de gerar uma segunda estrutura conflitante.

Arquivos que a implementacao principal deve substituir:

- `src/server/Main.server.luau` — Script de servidor: carreira, elenco, calendario, simulacao, transferencias, DataStore e validacao dos pedidos.
- `src/client/Main.client.luau` — LocalScript: interface completa em Roblox GUI, usando controles de toque.
- `src/shared/Config.luau` — ModuleScript opcional, para configuracoes/dados compartilhados sem segredo.

Mapeamento existente: `default.project.json`. Acrescente novos scripts e altere o mapeamento apenas se realmente precisar. Existe um workflow em `.github/workflows/publish.yml` que ja compila com Rojo 7.7.1 e publica apenas mediante autorizacao manual; NAO substitua este workflow sem necessidade.

Nao use URLs, IDs de experiencia ou chaves do Backrooms. Nao coloque segredos em arquivos. Nao afirme que testou o jogo apenas porque gerou o codigo. Entregue uma primeira temporada jogavel antes de sistemas secundarios.

IMPORTANTE: os scripts atuais contem o marcador `CL_SCAFFOLD_PLACEHOLDER`. Ao fornecer scripts definitivos, substitua inteiramente os dois arquivos e nao mantenha esse marcador. Enquanto ele existir, a etapa de publicacao falhara de proposito, como protecao contra publicar o prototipo vazio.

Use a arquitetura servidor-cliente com validacao no servidor. Se o codigo exceder o limite de resposta, forneca arquivos completos, um de cada vez, sem pseudocodigo ou trechos omitidos.
