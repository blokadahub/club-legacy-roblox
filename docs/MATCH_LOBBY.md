# CL-27 — lobby pré-partida, etapa 02

Base: `feat/cl27-mega-tactics-editor`, commit `6b353c2c2858052cf6b3f83ddd751a7a01fc26c9`, PR #21 aberto/em rascunho na inspeção. Branch desta entrega: `feat/cl27-mega-match-lobby`. O PR deve apontar para a branch da etapa 1 para isolar a alteração. **Não realizar merge, publicar no Roblox ou iniciar a etapa 03.**

## O que funciona

Central → **Pré-partida** abre o novo ambiente. Abas levam a Elenco, Táticas e Configurações; Instruções abre orientação desta etapa. Pré-partida retorna da ficha ou orienta a seleção. Central e Voltar continuam funcionais.

- Onze titulares correspondem a `state.tacticalPlan.active`. Cartões mostram nome abreviado, função e posição; a ficha inclui comportamento e atributos do atleta fictício. O avatar à direita identifica o usuário como técnico, sem nota/nível esportivo inventado.
- Cinco reservas inscritos aparecem com nome, posição e condição física dos dados existentes. Escolher um reserva permite substituir sua inscrição por alguém não relacionado ou propor sua entrada em um slot compatível.
- Escolher um titular permite propor sua troca por um reserva compatível. A ficha possui seletor para percorrer os onze titulares. Propor não grava; o campo/banco refletem o rascunho e o aviso de pendência.
- **Confirmar escalação** revalida tudo e grava o rascunho na sessão; **Cancelar alterações** restaura a lista inicial/última confirmação. Sair descarta o rascunho. Fechar a ficha apenas abandona a seleção de candidato, sem realizar a proposta.
- Após confirmar, o estado está pronto para consumo futuro. Não há motor, partida, adversário simulado, resultado, matchmaking, chat ou vitória automática. “Partidas disponíveis na Etapa 03” é informação, não um botão inerte.

## Dados, inscrição e integração

`TacticsModel`/`TacticsCatalog`/`TacticsSession` da etapa 1 continuam sendo o contrato tático. Nova operação `TacticsModel.replacePlayer` valida o plano de origem, compatibilidade e disponibilidade do jogador, rejeita um titular já escalado e valida uma cópia antes de trocar `positions`. Não altera `roleId` ou `behaviorId` do slot.

`MatchLobbyModel.new(state, roster)` inicializa o plano pelo contrato existente quando necessário e cria:

| Valor | Dono / significado |
| --- | --- |
| `state.tacticalPlan.active` | Única configuração tática confirmada |
| `session.tactic` / `session.benchIds` | Rascunho desta visita, cópias independentes |
| `session.base` / `session.baseBench` | Base para cancelar e detectar edição concorrente |
| `state.matchPreparation.benchIds` | Cinco IDs registrados na última confirmação |
| `state.matchPreparation.receipt` | Cópia de verificação da tática/banco confirmados; não é outra tática ativa |
| `state.matchPreparation.clubId` | Clube ao qual a confirmação pertence |

Regras: exatamente onze titulares válidos, cinco reservas elegíveis, sem repetição entre grupos, posições conhecidas, `available ~= false`, IDs existentes e distintos. Os IDs do domínio não são índices do array nem UserIds Roblox. O elenco global de 22 não é alterado. Uma lista global com exatamente 16 elegíveis funciona; quinze não são preenchidos com nomes artificiais.

Ao reabrir depois de editar táticas, a reconciliação preserva inscrições ainda válidas, retira novos titulares do banco e preenche vagas em ordem estável de ID, priorizando um goleiro entre candidatos. Essa reconciliação é apenas rascunho até confirmar. O preenchimento inicial não é uma avaliação de qualidade da equipe; todas as cinco vagas podem ser alteradas pelo usuário.

`session:swap(slotId, benchIndex)` troca os IDs no rascunho após validação integral. `session:register(index, playerId)` aceita somente jogador elegível fora dos inscritos. `session:confirm()` rejeita uma tática/clube que mudou desde a abertura, evitando sobrescrever edição concorrente; valida e grava tática e inscrições sem yield entre as operações.

`MatchLobbyModel.ready(state, roster)` revalida e compara a configuração atual com o recibo. Salvar tática diferente, mudar clube ou tornar alguém indisponível invalida a preparação. `MatchLobbyModel.export` retorna uma cópia `{version=1, clubId, tactic, benchIds}` somente quando pronta. A etapa 3 deverá revalidar esse contrato e definir autoridade apropriada no servidor; nenhum servidor de partidas foi criado aqui.

Elenco continua mostrando todos os jogadores do clube, com os titulares da tática confirmada. Os restantes não desaparecem por estarem fora da inscrição da partida. Não existe DataStore: tudo se perde ao encerrar a sessão.

## Composição e auditoria da referência 2

| Região | Implementação e decisão |
| --- | --- |
| Topo | Marca própria CL-27, preparação individual, clube, abas horizontais e identidade real da conta. Sem moeda, ranking ou conexões fictícias |
| Esquerda | Banco estreito em grafite semiopaco, cinco cartões alinhados, seleção discreta; rolagem quando a resolução exige |
| Centro | Escudo original de Data/UI, nome, formação confirmada e campo trapezoidal escuro. Onze instâncias de cartão reutilizadas; seleção clara e sem brilho repetitivo |
| Direita | Uma cópia R15 real no Workspace, corpo inteiro, nome de conta e identificação de técnico; ficha do atleta fictício ocupa somente esquerda/centro |
| Fundo | Corredor novo de paredes/painéis grafite, pilares metálicos, piso acetinado e profundidade arquitetônica. Luminárias quentes à direita, guia azul à esquerda, verde moderado ao piso e luz suave de rosto |
| Rodapé | Estado verdadeiro da inscrição, confirmar verde, cancelar, Central e Voltar; partida futura explicada |

`Pitch.project` e `TacticsLayout.arrange` são reutilizados sem alteração. `TacticsModel.resolve(..., "with_ball")` fornece âncoras normalizadas. O layout só separa cartões; não muda as coordenadas táticas nem finge uma simulação. As funções/instruções vêm dos slots salvos.

Canvas 1600×900, UIScale e área segura do App preservados. A câmera deste modo acompanha também deslocamentos assimétricos da área segura. Em telas compactas (escala inferior a 0,65), o campo permanece inteiro com posições abreviadas; **Ver titulares** abre uma ficha com dados completos, **Outro titular** percorre os onze, e os seletores/propostas possuem alvos maiores. Cartões minúsculos da vista geral não são alvos individuais de controle. Reservas, abas e ficha rolam; foco revela controles. Detalhes secundários do cabeçalho/rodapé são ocultados. Não converte o lobby em coluna vertical.

Foram corrigidos, durante a revisão, tamanho de toque das abas, quinta reserva desnecessariamente recortada em desktop, texto de ajuda sem espaço suficiente e campo ampliado demais em celular. Uma projeção auxiliar da árvore de GUI com fontes aproximadas orientou esses ajustes. **Não é captura Roblox nem prova de fidelidade visual**, e não representa cenário, materiais, Gotham ou iluminação reais. A aprovação definitiva depende das capturas do proprietário no motor.

## Cenário, câmera e avatar

`MatchLobbyLayout` contém 59 descritores arquitetônicos, posição do avatar e câmera `(0, 4.3, 22)` → `(0, 4.3, 0)`, FOV de referência 32°. O avatar fica à direita em `(8.4, 0.04, 0)`; escala uniforme limita altura/largura/profundidade e mantém proporções. O piso da apresentação é embutido, sem pedestal flutuante.

`MatchLobbyScene` monta a arquitetura uma vez por entrada, quatro emissores locais e um avatar. Qualidade baixa mantém dois emissores; alta admite sombra somente na luz principal. Sem texturas importadas, emissores de partículas, névoa espessa ou dezenas de personagens. Bloom do modo é 0,035.

**Scene é o único controlador de Camera e Lighting.** Os módulos novos não escrevem nesses serviços nem instalam outro RenderStepped. Scene seleciona o perfil do ambiente, remove deriva neste modo, ajusta FOV/área segura, reconfigura iluminação ao mudar de modo e restaura câmera/Lighting originais no descarte geral. O App faz entrada curta de 0,22 s com controles bloqueados até o fim; movimento reduzido entra imediatamente. A aparência carrega em paralelo, sem prender a navegação. Falha ao construir a cena retorna ao menu.

`MatchLobbyAvatar` chama `AvatarAppearance.request(Players.LocalPlayer, ...)`, reutilizando o pipeline oficial e seu template em cache fora do Workspace. Cada apresentação recebe uma cópia independente R15. Scripts são retirados; root ancorado, partes sem colisão/toque/query; acessórios com weld válido preservados e acessórios desconectados removidos. Rosto, cabeça, mãos e características da conta permanecem. **Player.Character não é modificado.**

Em corpos compatíveis, sem WrapLayer e sem texturas corporais, aplica cores de treino do clube e uma marca CL-27 procedural na própria superfície do torso. Não substitui o R15 por blocos. Corpos texturizados e roupas em camadas mantêm a aparência da conta; o HUD informa qual apresentação foi aplicada. Não foi enviado um asset de roupa ao Roblox.

Pose esportiva contida por Motor6D/AnimationConstraint, respiração de 0,008 rad no tronco e compensação leve no pescoço. Não carrega IDs de animações externos nem executa idle potencialmente exagerado da conta. Movimento reduzido aplica pose estática e remove a conexão PreSimulation. Esta animação procedural ainda exige inspeção visual com avatares reais.

O Scope possui cancelamento do request, timer, conexão e rig. Ao sair, tudo da apresentação é destruído; somente o cache compartilhado de aparência permanece para evitar requisições repetidas. Falhas retornam mensagem e botão de nova tentativa; após 12 s sem resposta, a UI permite tentar novamente. Uma resposta tardia não ressuscita a cena. Se o rig recebido for inválido, a próxima tentativa explícita invalida o template e busca novamente. Itens parcialmente carregados geram aviso.

## Evidências executadas

Luau oficial **0.745** e Rojo **7.7.1**, com os binários de checksums fixados pelo workflow existente. [Saída resumida real dos testes locais](MATCH_LOBBY_VALIDATION.txt). Nenhuma alteração de workflow foi necessária: as novas suítes são incluídas pelos runners de smoke, App e arena já executados no CI.

| Verificação local | Resultado |
| --- | --- |
| Estrutura, requires, bootstraps e sintaxe | 63 fontes; 16 rotas; aprovado |
| Dados existentes | 653 verificações |
| Smoke | 592 montagens, 432 callbacks, 209 asserções |
| Editor tático | 110.072 asserções |
| Inscrição, trocas, estado e UI do lobby | 1.489 asserções |
| App existente / integração nova | 6.076 / 243 asserções |
| Introdução | 2.034 asserções |
| Arena / cenário e avatar novos | 365.840 / 103 asserções |
| Rojo e XML | Build válido, 63 fontes idênticas, um bootstrap cliente/servidor |
| Diff / preservação | Whitespace aprovado; arquivos protegidos abaixo idênticos à base |

Cobertura nova inclui todas as formações, todos os pares titular/reserva das inscrições iniciais, listas de 15/16/22 atletas, IDs não contíguos, posições indisponíveis, duplicações, inscrição inválida, confirmação/cancelamento, conflito de tática, exportação por cópia e retorno ao editor. A UI executa callbacks reais sem rerender do App e verifica contagem constante de instâncias/conexões em seleções repetidas.

Estados exercitados com relógio virtual: entrada/bloqueio, movimento reduzido, Central, recuperação de falha da cena, doze ciclos de navegação, oito viewports entre 568×320 e 2560×1080. Testes de cenário usam matrizes e fixtures R15, verificam conta solicitada, pés no piso, limite projetado, roupa compatível/incompatível, cache, falha/timeout/retry, callback tardio, descarte e restauração da iluminação. **Os testes substituem APIs Roblox; não executam rede de aparência, renderização ou física nativa.** Avisos de falhas injetadas são esperados nos testes negativos.

## Arquivos criados e modificados

| Área | Arquivos |
| --- | --- |
| Dados / regras | Novo `src/shared/MatchLobbyModel.luau`; extensão em `src/shared/TacticsModel.luau` |
| Cena / avatar | Novos `src/client/Environments/MatchLobbyLayout.luau`, `MatchLobbyScene.luau`, `MatchLobbyAvatar.luau` |
| Interface | Novos `src/client/Screens/MatchLobby.luau`, `MatchLobbyPitch.luau` |
| Integração | `src/client/App.luau`, `src/client/Scene.luau` |
| Testes | Novos `tools/match-lobby.spec.luau`, `match-lobby-app.spec.luau`, `match-lobby-scene.spec.luau`; alterações em `run-runtime-smoke.py`, `run-app-states.py`, `runtime-smoke.luau`, `validate.py` |
| Documentação | `AGENTS.md`, `CL27_PLAN.md`, `CL27_PROGRESS.md`, `README.md`, nota histórica em `docs/TACTICS_EDITOR.md`; novos `docs/MATCH_LOBBY.md`, `MATCH_LOBBY_VALIDATION.txt` |

Preservados byte a byte: introdução, HomeHUD, túnel original, módulos da Arena/animações, AvatarAppearance, MenuAvatar, áudio, UI, Scope, tela/controles/layout do editor tático, Elenco, Data, servidor, default.project.json e workflows. Apenas App/Scene recebem integração necessária e TacticsModel ganha a operação incremental descrita antes da implementação.

## Validação obrigatória dentro do Roblox

1. Baixar o artefato `club-legacy-rbxlx` do build da nova branch; abrir em Studio e executar **Play**. Capturar introdução/menu antes de entrar pela Central → Pré-partida.
2. Capturar em 1600×900 e Android horizontal: topo, cinco reservas, formação central, avatar inteiro, fundo e rodapé. Comparar a referência 2 região por região; ajustar luz/fontes/escala somente após essa comparação. Capturar também tela compacta e ficha aberta.
3. Salvar 4–3–3, 4–2–3–1, 4–3–2–1 e 5–4–1 em Táticas; retornar e conferir os onze IDs e funções. Confirmar uma troca; abrir Elenco e Táticas, conferir o mesmo titular. Cancelar uma nova proposta e sair/reentrar: ela não pode ter sido salva.
4. Alterar cada vaga dos cinco reservas, tentar combinação incompatível/repetida e confirmar. Os demais atletas continuam disponíveis no clube. Alterar tática posteriormente deve pedir nova confirmação.
5. Testar conta real com R15 clássico, proporções diferentes e acessórios/roupas em camadas. Conferir cabeça/pés no enquadramento, welds, contato com piso, face, iluminação e ausência de mudanças no Character. Simular erro/latência de aparência; testar retry e saída durante carregamento.
6. Testar toque e arrasto, mouse e gamepad físicos. No compacto, percorrer os onze titulares na ficha; rolar banco/abas/ajuda até o fim. Verificar foco visível, ação/cancelamento, retorno e mudança de resolução enquanto a Central está aberta.
7. Alternar qualidade/movimento reduzido; entrar/sair ao menos vinte vezes. Conferir Output, rigs e conexões removidos, câmera/Lighting restaurados e ausência de crescimento contínuo de memória. Medir FPS/memória em hardware identificado; nenhum resultado de desempenho foi presumido.
8. Reabrir introdução, lobby antigo, túnel, Arena e prévias de pênaltis; conferir imagem e áudio originais. Arquivos preservados e testes não substituem esse ensaio.

Sem Studio/Player disponível nesta execução. A aprovação visual definitiva, o comportamento de serviços oficiais de aparência, toque/gamepad reais e desempenho estão pendentes. O PR permanece em rascunho para revisão. Não houve merge, publicação Open Cloud ou implementação da etapa 03.

APIs consultadas: [Model / ScaleTo e GetScale](https://create.roblox.com/docs/reference/engine/classes/Model), [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint). O restante reutiliza o pipeline e os componentes já existentes.
