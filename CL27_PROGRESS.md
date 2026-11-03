# CL 27 — progresso verificável

## Ciclo 1 — inspeção e arquitetura

- [x] Repositório identificado pela conexão GitHub; main e duas branches examinadas.
- [x] Cinco anexos reabertos individualmente; análise regional em preparação.
- [x] Arquitetura e contratos registrados em CL27_PLAN.md.
- [x] Ausência de scripts/workflows na main confirmada pela árvore GitHub.
- [x] Base UI, dados e navegação.
- [x] Cenas Workspace e personagens R15.
- [x] Quinze interfaces e interações.
- [x] Compilação Rojo e verificações de integridade.
- [x] Auditoria 1: composição por fontes e reprojeção; validação visual por capturas pendente.
- [x] Auditoria 2: código, fases e estados; captura quadro a quadro pendente.
- [x] Auditoria 3: qualidade, contratos e integridade; validação visual no Studio pendente.
- [x] Registro na main e build do GitHub Actions aprovado; artefato disponibilizado.

## Limitações observadas

O acesso de rede do shell exigiu permissão de rede por comando; após aplicá-la, clone/fetch e downloads oficiais funcionaram. O conector GitHub também está disponível. Studio/Player e capturador Roblox indisponíveis. Não houve render, captura quadro a quadro ou medição de FPS. A experiência Roblox de destino não foi confirmada; nenhuma publicação será executada.

## Ciclo 2 — implementação integrada

- 25 fontes de produto Luau, um bootstrap cliente e um servidor; módulos vazios não usados.
- 15 rotas: dois menus, Visão Geral, Elenco, Táticas, Atribuições, Calendário, Transferências, Finanças, Desenvolvimento, Competições, Personalização, Configurações, Clubes e Uniformes.
- Quatro cenas Workspace (Interior, Training, Arena, Kits), com iluminação, câmera, arquitetura e atletas procedurais R15 originais. ViewportFrame reservado a retratos/preview.
- 8 clubes, 22 atletas, 3 formações e 24 uniformes; seleções compartilhadas e persistentes durante a sessão.
- Qualidade Alta/Média/Baixa, movimento reduzido, contraste reforçado, dicas, paleta e ambiente preferido conectados a comportamentos reais.
- Navegação central, histórico e descarte de scopes; animações Quart de seleção/uniformes e transição cromática.
- Infra reconstruída a partir do fluxo Rojo anterior; retirados os IDs fixos antigos. Publicação somente manual, destino configurado e confirmado.

## Ciclo 3 — verificações executadas antes das auditorias finais

- Luau oficial **0.745**: compilação sintática das **25 fontes** aprovada.
- Rojo **7.7.1**: `club-legacy.rbxlx` gerado; comparação XML aprovou as **25 fontes sem alteração**, serviços e bootstraps.
- Runtime Luau: **637 verificações de dados** aprovadas. Inclui uniformes, formações, atributos, pontuação, ordem da tabela, resultados agregados e balanço de gols.
- Harness de integração com APIs substituídas: **538 montagens, 382 callbacks, 191 asserções** aprovados. Usa fontes reais de UI/Rig/Scope/telas, mas não executa motor Roblox, física ou renderização. Não substitui teste em Studio.
- **actionlint 1.7.12**: workflows `build.yml` e `publish.yml` aprovados.
- Catálogo API Roblox: **296 referências estáticas de classes/enums**, nenhum nome inexistente após substituir `GothamLight` por `Gotham`. Esse problema não era detectado pelos stubs; o limite está documentado.
- Binários Luau/Rojo/actionlint baixados de releases oficiais e SHA256 conferidos. Ferramentas locais em `/tmp/cl27-tools` (não versionadas).

## Auditoria 1 — encerrada antes da etapa 2

Ver [AUDIT_1_VISUAL.md](docs/AUDIT_1_VISUAL.md). As cinco referências foram reabertas. Corrigidos excesso de contexto no exterior, indicador 02/02, transparência que escondia a arena, posição/escala dos atletas, telão cortado e FOV responsivo. A reprojeção analítica final coloca telão em aproximadamente x27,82–89,44% / y17,98–60,04%, e atletas entre y24–76%. Campo, banco e ficha mantêm composição horizontal e clubes mantêm simetria.

**Limite:** isso não constitui aprovação visual por imagem do resultado. Capturas do Roblox e ajuste de materiais, tipografia física, sombras e FPS continuam pendentes do Studio.

## Auditoria 2 — encerrada antes da etapa 3

Ver [AUDIT_2_MOTION.md](docs/AUDIT_2_MOTION.md). Corrigidos passagem de comandos sob a Central, foco prematuro de controle, delays concluídos acumulados, restauração de câmeras substituídas, disputa do DPad e navegação após descarte. O teste de estados foi executado antes e depois da correção da Central, reproduzindo a falha e confirmando o bloqueio.

As fases de entrada, handoff coberto e saída, fila de última navegação, histórico, movimento reduzido e descarte foram testados com relógio virtual. Não houve vídeo ou inspeção quadro a quadro de Roblox.

## Auditoria 3 — encerrada

Ver [AUDIT_3_QUALITY.md](docs/AUDIT_3_QUALITY.md), com os 17 critérios solicitados. Corrigidos:

- Gradientes que multiplicavam cores sobre fundos já escuros, tornando painéis e transição quase pretos; base neutra preserva a paleta azul/esmeralda/turquesa.
- Retratos distantes e segunda linha de reservas parcialmente cortada; câmera dos retratos aproximada e cartões/banco redimensionados.
- Recorte do uniforme secundário, ações de uniformes junto ao rodapé e destaque tipográfico do menu.
- Rolagem e foco perdidos após seleção nas listas; ambos agora preservados na mesma rota.
- Posições invertidas nas formações; laterais/pontas e centroavante agora ocupam setores coerentes.
- Confirmação de uniforme mantida após personalização, plano herdado entre atletas e compromissos repetidos em 2027.
- Rótulos estáticos do clube, dica de comando sem implementação explícita e etapa duplicada no CI.
- Iluminação nativa `LightingStyle.Realistic`, prioridade de qualidade e perfis Alta/Média/Baixa com restauração do estado anterior. Máquina de estados física desativada nos Humanoids exclusivamente de apresentação.

## Verificação final após as três auditorias

- **25 fontes** compiladas pelo Luau oficial **0.745**.
- **653 verificações de dados** aprovadas, incluindo coerência das posições nas formações.
- **550 montagens, 386 callbacks e 206 asserções** no harness das telas.
- **46 asserções** de fases, fila, foco, rolagem, qualidade e descarte do App/cena.
- Rojo **7.7.1** gerou `club-legacy.rbxlx`; XML contém as **25 fontes idênticas** e os serviços/bootstraps esperados.
- Workflows aprovados pelo **actionlint 1.7.12**; nenhuma publicação executada.
- **294 referências** estáticas de classes/enums aprovadas; **30 propriedades críticas** existentes e graváveis no catálogo API consultado. Dump SHA256: `0962f777e3085487e368ed019c35bdb07cd02f6659aa7212dc2ad6e24bb41efe`.
- Integridade UTF-8, require locais, rotas, JSON e `git diff --check` conferidos.

Os harnesses executam Luau real com APIs substituídas. Não certificam render, curvas perceptuais, física, legibilidade em dispositivos ou performance Roblox.

## Pendências de ambiente e próximos passos

1. Abrir o artefato no Roblox Studio e executar **Play**. Capturar as 15 telas em 16:9, 4:3, ultralarga e celular horizontal; comparar com as cinco referências por regiões.
2. Gravar transições reais e inspecionar quadros iniciais/intermediários/finais, trocas rápidas e mudanças de estado. Ajustar materiais, contraste, sombras e cortes observados.
3. Testar toque e controle reais, incluindo listas roláveis e conexão de controle durante a sessão.
4. Medir FPS, memória e hitches no MicroProfiler em hardware identificado. **60 FPS não foi medido nem declarado.**
5. Confirmar a experiência de destino e configurar variáveis/secret para publicação manual Open Cloud quando desejado. IDs antigos não foram reutilizados.

Não restou falha reproduzível nas verificações executadas após as correções. A fidelidade visual AAA e a revisão quadro a quadro do resultado permanecem **não comprovadas**, por ausência de execução Roblox neste ambiente.

## Registro GitHub

- Implementação registrada na **main**, commit [`0d0ce9ee52d21e058a68c4cee6cbdb5d53e3e989`](https://github.com/blokadahub/club-legacy-roblox/commit/0d0ce9ee52d21e058a68c4cee6cbdb5d53e3e989), com atualização protegida pelo SHA anterior esperado. **47 arquivos** compõem a entrega.
- [GitHub Actions — execução 41556384701](https://github.com/blokadahub/club-legacy-roblox/actions/runs/41556384701): **completed / success**, em 03/11/2026 às 00:56:47 UTC. Todas as etapas passaram: download/checksum, sintaxe, dados, interações/estados, Rojo, validação XML e upload.
- Artefato **club-legacy-rbxlx**, ID `13195171375`, ZIP de **41.660 bytes**, disponível na execução acima até **17/11/2026**. Digest do ZIP informado pelo GitHub: `sha256:c8077be5d9cc5f41fdfdd57e90d6952a6bef314f5a2a1fff689f2e7198b2cd44`.
- Arquivo local `club-legacy.rbxlx`, SHA256 `260b3754c65208402df8d0aad2cc4827ef0c3bd7746747337596ec9aa1fbab02`, gerado e validado após as auditorias. O arquivo compilado é distribuído como artefato; as fontes permanecem versionadas.
- O registro posterior deste resultado altera somente este documento, com `[skip ci]`, preservando exatamente o código aprovado na execução indicada.
- **Nenhuma experiência Roblox foi publicada ou modificada nesta sessão.** O fluxo manual Open Cloud está preparado e sem IDs antigos; o destino ainda precisa ser confirmado/configurado.
