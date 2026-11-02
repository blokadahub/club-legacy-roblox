# CL - Club Legacy

Projeto de simulador de carreira de treinador para Roblox.

**Estado atual:** infraestrutura de desenvolvimento preparada. Ainda nao ha um jogo jogavel; os scripts em `src/` sao marcadores temporarios para receber o codigo do Claude.

## Estrutura pronta

- `default.project.json`: mapeia os scripts para os servicos do Roblox usando Rojo.
- `src/server/Main.server.luau`: logica autoritativa no servidor (temporaria).
- `src/client/Main.client.luau`: interface do jogador (temporaria).
- `src/shared/Config.luau`: configuracao compartilhada, caso o jogo precise dela.
- `.github/workflows/publish.yml`: compilacao manual e publicacao opcional.
- `INSTRUCOES-CLAUDE.md`: especificacoes para encaixar o codigo gerado.

## Quando o Claude entregar os codigos

1. Substitua o **conteudo completo** de `src/server/Main.server.luau` pelo script de servidor.
2. Substitua o **conteudo completo** de `src/client/Main.client.luau` pelo LocalScript da interface.
3. Se a entrega contiver modulos, acrescente-os em `src/shared/` ou onde o Claude indicar e ajuste `default.project.json` quando necessario.
4. Nao cole varios scripts em um unico arquivo sem revisar o mapeamento. Cada arquivo deve ter o caminho correto.
5. Remova os marcadores `CL_SCAFFOLD_PLACEHOLDER` ao **substituir integralmente** os dois scripts. O workflow impede publicar a base temporaria por engano.
6. Nao copie os IDs nem a chave Open Cloud do projeto Backrooms.

## GitHub Actions pelo celular

Abra **Actions > CL - Club Legacy | Construir e publicar > Run workflow**. Com `publicar` desmarcado, o GitHub apenas valida e gera `club-legacy.rbxlx`, disponibilizado em Artifacts. Isso NAO garante funcionamento do jogo no Roblox; teste a experiencia depois de publicar.

Para publicar na sua **nova experiencia Club Legacy**, configure em **Settings > Secrets and variables > Actions**:

- **Repository secret**: `ROBLOX_API_KEY` (chave Open Cloud autorizada para a nova experiencia; nunca publique a chave em arquivos).
- **Repository variable**: `ROBLOX_UNIVERSE_ID` (Universe ID do Club Legacy).
- **Repository variable**: `ROBLOX_PLACE_ID` (Place ID inicial do Club Legacy).

Depois da compilacao aprovada e com os scripts definitivos, execute novamente **Run workflow** marcando `publicar`. A publicacao nao torna automaticamente a experiencia publica. Configure a visibilidade no Creator Hub, de acordo com as regras da plataforma.

**Nao ative a publicacao antes de integrar e conferir o codigo do jogo.**

## Avisos

O codigo da IA exige revisao. A compilacao Rojo verifica a estrutura, mas nao prova que transferencias, simulacoes, salvamento e interface funcionam. Use scripts de servidor para validar dinheiro, resultados e DataStoreService. A experiencia Roblox Club Legacy deve ser independente do Backrooms.
