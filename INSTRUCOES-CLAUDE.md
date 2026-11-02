# Instruções para integrar o código do Claude — CL - Club Legacy

Este repositório já existe e está preparado: **https://github.com/blokadahub/club-legacy-roblox**.

## Limite de permissão

**O Claude não tem autorização nem acesso para modificar o GitHub, executar workflows, obter chaves, abrir o Creator Hub ou publicar a experiência Roblox.** Deve fornecer **somente o código completo, com os caminhos exatos dos arquivos**, para integração posterior pelo proprietário ou por outra ferramenta autorizada.

Não peça token de GitHub, chave da Roblox ou acesso ao Roblox Studio. Não inclua credenciais nos arquivos.

## Arquivos existentes

- `src/server/Main.server.luau` — substituir pelo código de servidor: carreira, calendário, partidas, dados, transferências, validações e persistência.
- `src/client/Main.client.luau` — substituir pelo LocalScript que cria a interface adequada para celular.
- `src/shared/Config.luau` — módulo de configuração pública; preservar ou ajustar conforme arquitetura.
- `default.project.json` — mapeamento Rojo 7.7.1 já existente. Atualizar somente se criar módulos/scripts adicionais.
- `.github/workflows/publish.yml` — workflow pronto para compilar e publicar manualmente. **Não recriar sem necessidade.**

Se precisar de novos módulos, informe seu conteúdo integral e destino exato (`src/server/`, `src/client/` ou `src/shared/`). Nenhum arquivo poderá ser citado sem fornecer seu conteúdo.

## Estado do projeto Roblox

O usuário descontinuou o protótipo Backrooms e decidiu **reaproveitar a mesma experiência Roblox** para o Club Legacy. IDs públicos já são usados no workflow: **Universe ID `9749365367` e Place ID `86256105108811`**. Isso é intencional; não solicite criação de uma nova experiência nem reutilize arquivos de jogabilidade do Backrooms. **Não use nenhuma chave Open Cloud em código**.

O workflow contém proteção contra scripts com o marcador `CL_SCAFFOLD_PLACEHOLDER`. Os scripts integrados não o contêm. A ausência desse marcador **não prova** que a implementação está correta, portanto compile e teste antes de publicar.

## Estado da integração

**Os scripts completos enviados pelo usuário (Arquivo 1A + 1B, Arquivo 2 e Arquivo 3) foram unidos e inseridos no GitHub.** Ainda não foram compilados nem testados no Roblox. Em novas revisões, altere somente o que estiver comprovadamente incorreto e preserve a estrutura existente.

## Entrega prioritária

Primeiro entregue uma carreira de manager que permita entrar, escolher clube, escalar time, alterar tática, simular rodadas, acompanhar tabela, contratar/vender, concluir temporada e salvar o progresso. Use dados fictícios próprios e validação de operações no servidor. Evite futebol 3D nesta primeira versão.

**Ordem de entrega sugerida:** servidor completo → cliente completo → módulos indispensáveis → ajustes em `default.project.json` → instruções de integração/testes.

Não interrompa a resposta no meio de um arquivo, não ofereça pseudocódigo e não afirme que testou a implementação sem ter executado testes. Se a resposta for longa, divida em arquivos completos, um por vez.
