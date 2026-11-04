# CL 27 — progresso verificável

## Boas-vindas e seleção inicial do lobby — 04/11/2026

- Base: main `8d40d4bbe6d5288a438aa882b6f814f6a9dcc479`; branch `fix/cl27-welcome-lobby-selection`.
- Auditoria 1, composição: examinadas as duas imagens recebidas. Título verde ampliado de 88 para 118 unidades, marca branca CL Sports/CL 27 recuperada acima, botão central e apoio afastados do título; facetas mais escuras. Identidade própria preservada. Esta comparação é por referência/código, sem captura Roblox nova.
- START e a ação central do lobby agora usam `UI.capsule`: mesma cor, círculo X, texto, borda e `OuterGlowSweep` de 78 segmentos. O dono controla o efeito pelo loop já existente e o descarta; nenhum loop ou conexão adicional. O contorno do START usa dimensões locais para evitar escala duplicada por UIScale.
- `homeFocus=1` no App e fallback do HUD: Notícias do CL aparece branca, com conteúdo NOTÍCIAS DO CL e ação Ver notícias. O foco do controle acompanha essa seleção após a abertura; voltar ao lobby preserva a escolha feita na sessão.
- Auditoria 2, estados: abertura completa, espera no START, prontidão temporariamente perdida, saída, tentativa após erro, movimento reduzido e descarte passaram. Em cinco proporções (incluindo 854×393 e 393×854), verificadas área mínima de toque 112×48 px, legenda/X legíveis, espaço entre ícone e texto, contorno dentro da cápsula e brilho localizado em movimento. Tempos/áudio continuam sob a mesma timeline.
- Auditoria 3, integridade: Luau oficial 0.745 aprovou as 43 fontes; 653 verificações de dados; smoke com 519 montagens/381 callbacks/240 asserções; 5.910 asserções de estados e 1.278 da abertura. Rojo 7.7.1 gerou XML com as 43 fontes idênticas; `git diff --check` aprovado. Avisos de falhas simuladas são esperados nos testes negativos.
- Pendente: aparência, fontes, toque/controle, áudio e desempenho reais no Roblox Studio/Player, indisponíveis neste ambiente. Nenhuma publicação Roblox foi executada.

## Revisão da abertura — PR #11

- PR #11 existente e em rascunho confirmado pelo site do GitHub; branch remota e checkout coincidiam em 7eae2e3 antes das correções. O CI anterior 41754409795 foi consultado e estava em Success. Nenhum PR adicional criado.
- Auditoria 1: quadros da referência reexaminados. Corrigidos círculo isolado fora do centro, traços recortados pelo CanvasGroup e revelação com duas camadas pretas acumuladas. Sete facetas / 14 peças, câmera independente e identidade própria preservadas. Render real ainda não avaliado.
- Auditoria 2: áudio deixa de ser descartado no primeiro IsLoaded=false. Pré-carregamento paralelo com até duas tentativas limitadas a três segundos cada, retry após 0,35 s e pedido pendente por até dois segundos desde o marco absoluto. Loaded, preload e polling recuperam uma vez; evento posterior/expiração/destruição impedem reprodução fora de fase. Sem espera global ou sons substitutos.
- Mantidos 6,30 s / 16,60 s / START+0,50 s. Cargas normais tardias não deslocam a timeline: teste com todos os efeitos atrasados em 200 ms conclui em 23,80 s com START em 17,80 s e saída de seis segundos. Perda transitória de prontidão após boas-vindas não rebobina a animação; START revalida o estado no clique.
- Auditoria 3: falhas reproduzidas por testes antes das respectivas correções. Suíte de abertura ampliada de 616 para 836 asserções, incluindo preload suspenso/timeout, retry, recuperação até 1,9 s, expiração e callbacks duplicados. Nenhuma asserção de falha removida para encobrir defeitos.
- Regressão: 43 fontes Luau, 653 verificações de dados, smoke 519 montagens/381 callbacks/240 asserções, 5.907 asserções de estados/Clubs; Rojo 7.7.1 e XML com fontes idênticas. Catálogo API: 424 referências, zero erros. Resultado correspondente ao commit e CI da revisão na entrega.
- Música continua silenciosa até a revelação completa; teste cobre Loaded antecipado e CompleteIntro duplicado. Indicador CL permanece único, transparente e sem Cover inicial. App, Soundtrack, TransitionFX, Scene, túnel, iluminação, névoa, controles e workflows foram preservados nesta revisão.
- A consulta do CI usa as páginas normais do GitHub; não foi necessário resolver o 403 da API nem alterar a rede. Sem merge ou publicação Roblox.
- Pendente de Studio/Player: composição e animação renderizadas, audição/conteúdo/duração/permissão dos três assets, toque/gamepad e desempenho reais. Testes com stubs não aprovam esses itens. Detalhes em docs/CINEMATIC_INTRO.md.

## Abertura cinematográfica CL 27

- Base main confirmada via fetch: 133f6a1c21691deb6e684d1467f5197f4b62b7f8, incluindo os merges dos PRs #9 e #10. Branch dedicada feat/cl27-cinematic-intro. Backup verificado em bundle externo e branch remota backup/pre-cinematic-intro-133f6a1.
- Referência acessível: ffprobe confirmou 1920×1080 / 60 FPS / 23,800454 s. Inspeção de quadros da sequência inteira e amostragem adicional nas transformações/saída. Não confundir isso com captura do resultado no Roblox.
- Implementados fundo estático de sete facetas, marca CL Sports/CL 27 própria, transformação, mensagens locais honestas, nome real do jogador, boas-vindas interativas e saída de seis segundos para o lobby existente.
- O escudo nasce antes de carregar App. O lobby é construído oculto uma vez; o mesmo indicador de TransitionFX é usado sem Cover inicial. Navegação e música ficam bloqueadas até completar a revelação. Soundtrack.create/release separa construção da reprodução e preserva as 12 faixas.
- Efeitos autorizados: 98087823124682 em 6,30 s; 101494550141867 em 16,60 s (adiado se lobby indisponível); 135910449013772 em START + 0,50 s. Com START em 17,80 s, término/música em 23,80 s. Sem avanço automático da tela START, narração ou efeito extra em 22,5 s.
- Auditoria 1 — composição por código contra a referência: enquadramento cover das facetas, conteúdo fit 1600×900, proporções da marca, posição superior e margens. START com mínimo físico 112×48 px e apoio reposicionado para não colidir. Fidelidade renderizada pendente.
- Auditoria 2 — estados/animação: relógio absoluto, eventos únicos, testes a 60/30/15/5 Hz, espera longa no START, gate de prontidão, saída completa, efeitos ordenados, música liberada uma vez, movimento reduzido e cancelamento. Sem medição de curvas perceptuais no motor.
- Auditoria 3 — integridade: 43 fontes aprovadas em sintaxe Luau 0.745; 653 verificações de dados; smoke com 519 montagens / 381 callbacks / 240 asserções; 5.907 asserções existentes de estados/Clubs; 616 asserções novas da abertura. Rojo 7.7.1 gera XML com as 43 fontes idênticas. API-Dump: 424 referências estáticas, zero erros; propriedades novas relevantes conferidas. git diff --check aprovado.
- O workflow de build inclui a nova suíte. publish.yml, IDs Roblox e módulos dos ambientes/túnel não foram alterados.
- Documentação completa de tempos, arquivos e roteiro Studio em [CINEMATIC_INTRO.md](docs/CINEMATIC_INTRO.md).
- Limites: sem Studio/Player; render, toque/gamepad reais, FPS, audição/duração/permissão dos efeitos não certificados. O teste negativo de áudio produz avisos esperados e continua funcional.
- Registro histórico da primeira entrega: API do GitHub negada pelo proxy (403), sem confirmação do CI naquele momento. Posteriormente o usuário criou o PR #11 e informou a aprovação do CI; na revisão acima a consulta funcionou pelo site do GitHub, sem reconfigurar a rede.

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

## Atualização da trilha sonora — 03/11/2026

- Fonte alterada: `src/client/Soundtrack.luau`. Removidas `Crab Rave` e `CloudNone`.
- Adicionados os 11 IDs de áudio recebidos; mantida `Shiawase`. Total: **12 faixas com IDs distintos**.
- Na lista de novas faixas, a música originalmente na posição 7 (`DESERT STAR — Empty Sky`) passou à posição 1, e `DESERT STAR — Carissa` passou à posição 7.
- Reprodução agora utiliza uma lista embaralhada por rodada, sem repetição enquanto houver faixas disponíveis e sem repetir a última entre rodadas. Áudios indisponíveis continuam sendo marcados como falhos e ignorados até reinicializar o player.
- Conferência estática local: 12 IDs únicos e ausência dos IDs removidos. Teste automatizado atualizado para verificar catálogo, posições 1/7 e ausência de repetição consecutiva. O [GitHub Actions 41664392571](https://github.com/blokadahub/club-legacy-roblox/actions/runs/41664392571) foi concluído com **sucesso**, incluindo sintaxe Luau, testes de integração e compilação Rojo. A audição dentro da experiência Roblox ainda precisa de validação, pois depende das permissões dos assets; nenhuma publicação da experiência foi executada aqui.

## Remoção do cenário de treinamento e auditoria de estruturas — 03/11/2026

- Removida `HomeTraining` da navegação, da Central, dos atalhos de retorno e das regras de transição. `Scene:_training` (gramado, gol, edifícios, árvores, postes e avatar do centro) e seus parâmetros especiais de iluminação foram retirados.
- A seção `Aprenda a Jogar` mantém as quatro opções visíveis, porém não selecionáveis e sem callback; a ação central apresenta **EM ATUALIZAÇÃO** e não abre cena. Uma eventual chamada de código a `Scene:Show("Training")` volta ao interior do lobby.
- Auditoria das fontes: `Scene:Show` elimina a cena anterior com `self.folder:ClearAllChildren()`. Outros ambientes existentes e legítimos são `Interior`, `Arena`, `Kits` e `Tunnel`. O ambiente visual `CL27_SettingsNeon` existe somente em Configurações; `CL27Assets/AcademySoccerBall` é um modelo visual em `ReplicatedStorage`, sem partida.
- Arquivos legados de interface, como `Screens/Home.luau`, `Screens/Clubs.luau` e `Screens/Pitch.luau`, permanecem como fontes no projeto; não implicam construções ocultas no Workspace. Telas alternativas podem ser acessadas pela Central, sem duplicar todos os cenários físicos.
- Limite: verificação estática do código GitHub. Instâncias adicionadas no próprio Roblox Studio, fora do repositório, não foram inspecionadas aqui.

## Correção de iluminação e névoa do túnel — 03/11/2026

- Base main `3ba99ace613431c18753cdcb44803bcea69ceeea`, backup remoto/local `backup/pre-tunnel-lighting-20261103-3ba99ac`; trabalho em `fix/tunnel-lighting-reflections-fog`. A correção foi aplicada à versão integrada em `src/client/Environments`, sem alterar o experimento antigo do PR #7.
- Corrigido um defeito reproduzido antes da alteração: o passe genérico apagava PointLight do túnel em Baixa e sobrescrevia seus alcances. Emissores próprios agora são identificados e preservados.
- Ambiente neutro mais legível, exposição corrigida, preenchimento sem sombras, luz real em todos os segmentos verdes e pós-processamento moderado. Resposta acetinada e complemento gráfico suave no próprio piso, sem novas peças ou reflexo de espelho.
- Névoa cinzenta localizada, com partículas nativas sem emissão de luz, apoiada por fog de distância. O Atmosphere do controlador é retirado/restaurado ao entrar/sair, permitindo o fog funcionar. Nenhum loop por frame foi acrescentado.
- Geometria, dimensões, paleta, neons, câmera, interface, controles e música preservados. Low/Medium/High mantêm 238/334/366 peças; usam 28/32/40 luzes, 0/0/2 sombras locais e 4/6/6 emissores de névoa, com limite conservador de 20/42/48 partículas vivas.
- Verificação: sintaxe das 38 fontes; 653 testes de dados; 519 montagens/381 callbacks/240 asserções do harness de interfaces; **5.847 asserções** de estados/iluminação/qualidade/descarte; Rojo 7.7.1 e XML com fontes idênticas; catálogo API com 390 referências sem erros. Detalhes e roteiro de inspeção em [CLUBS_TUNNEL.md](docs/CLUBS_TUNNEL.md).
- **Sem Studio/Player: a aparência corrigida, a igualdade com a imagem 2 e o desempenho no Android ainda não foram comprovados.** A captura enviada pelo usuário foi analisada; não foi produzida uma captura Roblox nova. Nenhuma publicação ou merge automático foi executado.

## Iluminação um pouco mais escura e névoa em movimento — 03/11/2026

- Ajuste solicitado após a avaliação do PR #9: exposição de 0,16 para 0,02, Brightness de 1,15 para 1,0, ambiente ligeiramente reduzido e preenchimento neutro de 1,6 para 1,3. Neons, geometria, câmera, interface e controles preservados.
- Névoa com correntes laterais opostas de 0,65–1,05 studs/s, rotação de 2–4°/s, leve ascensão, fade e renovação em 14–18 segundos. A camada estática ficou mais discreta para expor a animação. Simulação nativa, sem novos loops por frame, sem emissão de luz e com os mesmos limites de partículas/luzes/sombras.
- Base main `498da656c0d0083d0c31388ac2b8c1e43ce4edcd` preservada em `backup/pre-tunnel-dimmer-motion-20261103-498da65`; trabalho em `fix/tunnel-dimmer-moving-fog`. Testes de estados ampliados: **5.907 asserções** aprovadas nos três perfis. A animação configurada ainda requer inspeção visual no Roblox; Studio/Player indisponíveis.
