# CL 27 — lobby cinematográfico Bayern Stadium

## Escopo e segurança

Branch de trabalho: experimento/lobby-bayern-estadio. A main e a branch backup/cl27-pre-estadio-2026-11-03 não devem ser modificadas até a inspeção visual. A experiência Roblox continua sendo a mesma.

Modelo: https://create.roblox.com/store/asset/18593817379/Bayern-Stadium

## Implementação

- O servidor usa AssetService:LoadAssetAsync e, para ativos autorizados, InsertService:LoadAsset. Remove scripts, eventos remotos e interações externas antes de parentear o modelo em Workspace.
- O carregador só habilita o estádio após identificar uma superfície de gramado confiável e gerar exatamente dez marcadores reais, em ReplicatedStorage.CL27Stadium.CameraShots.
- Os movimentos seguem oito segundos por tomada, sequência fixa, fade entre tomadas e horários diferentes. O avatar não aparece nesse modo. Os cinco botões e a soundtrack permanecem inalterados.
- Bancos e túnel são filmados apenas se forem reconhecidos no próprio modelo. Quando não forem, as tomadas mostram outras áreas do gramado, sem inventar esses locais.
- Se faltar permissão, geometria ou replicação, o lobby antigo continua operando.

## Configuração necessária no Roblox Studio

Para inserir um modelo público gratuito criado por terceiros, habilitar Game Settings / Experience Settings → Security → Allow Loading Third Party Assets. A opção é desligada por padrão e não pode ser alterada por scripts ou pelo GitHub Actions. Se o criador já autorizou o ativo individualmente, a outra API pode funcionar sem ela.

Não foi possível abrir o conteúdo 3D do asset pelo conector GitHub. Portanto, essa permissão e a geometria real ainda precisam ser testadas dentro do Roblox Studio.

## Conferência visual antes da publicação

1. Abrir a experiência no Roblox Studio e iniciar Play, com o Output visível.
2. Verificar ReplicatedStorage.CL27Stadium: Status = Ready, ShotCount = 10, PitchDetected = true. As flags BenchDetected e TunnelDetected dizem se os locais foram realmente identificados.
3. Verificar Workspace.CL27_BayernStadium e os dez marcadores Camera_01 até Camera_10.
4. Conferir se as câmeras não atravessam paredes, se o estádio está texturizado e se o desempenho móvel é aceitável.
5. Se o Status for Unavailable, ler o motivo no Output; o lobby antigo deverá aparecer.
6. Só depois da inspeção, integrar a branch experimental à main e publicar pelo workflow já existente para o mesmo Place.

## Recuperação

O backup pre-estádio aponta para o commit ca76ae3476e89f20a43b1a0c5ad21cc680dfba02. Se o experimento algum dia for publicado e falhar, restaurar essa versão estável na main e republicar a mesma experiência. Nunca excluir o backup.

## Limites da validação

Compilar Luau, executar os testes e construir o Rojo não certifica a renderização real de um asset de terceiros. As dez câmeras são calculadas pela geometria real identificada no carregamento; ângulos finais só podem ser atestados vendo o modelo no Roblox Studio.