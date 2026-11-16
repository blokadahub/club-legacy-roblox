# CL-27 — editor de táticas, etapa 1

Base inspecionada: `main` em `ad0fd15f285b09fdde5e336e8d45ca3fdaf72e48`.
Branch: `feat/cl27-mega-tactics-editor`. Nenhum merge ou publicação Roblox faz parte desta entrega.

## Composição e interação

A referência 1 orienta a hierarquia: marca original e título no topo; identificação da tática ativa; predefinição clara e controles à esquerda; duas fases acima do campo escuro em perspectiva à direita; cartões de posição, função e comportamento; vantagens e riscos abaixo; ação verde de salvar e cancelar junto à base. Preto, grafite, branco e verde moderado. O fundo usa luzes gráficas estáticas discretas. Não utiliza logotipos ou imagens extraídos das referências.

As abas **Equipe** e **Atleta** dividem a coluna de controles. Tocar em um cartão abre as instruções daquele atleta. A formação avança entre alternativas compatíveis com o elenco; funções e comportamentos são filtrados por posição. Predefinições e seletores categóricos avançam ciclicamente; amplitude e altura da linha têm incremento e decremento de 5, limitados a 10–90.

O campo e seus onze cartões são construídos uma única vez por visita. Interações atualizam propriedades. Apenas mudanças entre fases animam por 0,18 s; trocar formação reposiciona imediatamente, evitando cruzamento de cartões. Movimento reduzido aplica o estado final diretamente. Não há animação contínua, bola, simulação ou loop por frame neste editor.

O canvas do App continua 1600×900 e proporcional à área segura. Controles crescem em telas pequenas; as listas rolam verticalmente. O campo usa ampliação uniforme abaixo de escala 0,65 e rolagem em dois eixos: preserva as proporções e a leitura, mas requer arrastar para examinar todo o campo em dispositivos compactos. Os controles novos de ação/fase/abas/Elenco/decremento têm alvo mínimo calculado de 44 px; cartões ampliados têm pelo menos 59,8 px de altura. O rodapé existente do App não foi redesenhado.

O editor solicita `LandscapeSensor` enquanto está aberto e restaura a orientação anterior ao sair. A navegação direcional usa relações espaciais entre cartões, rotas de saída para os controles e revelação automática do item focado na rolagem. Mouse/toque usam `Activated`; todas as conexões da tela passam pelo `Scope` e respeitam o bloqueio da Central/transição.

## Estrutura e contratos

| Camada | Arquivos | Responsabilidade |
| --- | --- | --- |
| Catálogo | `src/shared/TacticsCatalog.luau` | IDs, cinco formações, posições compatíveis, funções, comportamentos e predefinições |
| Regras | `src/shared/TacticsModel.luau` | Matching de atletas, validação, cópia, indicadores e intenções normalizadas |
| Estado | `src/shared/TacticsSession.luau` | Rascunho independente e confirmação atômica em `state.tacticalPlan.active` |
| Layout | `src/client/Screens/TacticsLayout.luau` | Distribuição dos cartões, limites e espaçamento em pixels, sem alterar dados |
| Campo | `src/client/Screens/TacticsPitch.luau` | Instâncias reutilizadas, estilos, atualização e movimento entre fases |
| Controles | `src/client/Screens/TacticsControls.luau` | Primitivas locais apoiadas em UI e Scope; foco/rolagem |
| Tela | `src/client/Screens/Tactics.luau` | `(root, ctx)` existente, composição e ligação entre controles e sessão |

`TacticsModel.Configuration` exporta o contrato versionado. Os campos são `version`, `formationId`, `presetId`, `buildUp`, `pressure`, `mentality`, `width`, `line` e `positions`. Cada entrada de `positions[slotId]` contém `playerId`, `roleId` e `behaviorId`. Exemplo de ID de posição: `gk`, `lb`, `rcb`, `dm`, `lam`, `st`; ID de formação usa hífen ASCII, como `4-2-3-1`. Rótulos em português são independentes dos IDs.

Os IDs de atleta são os já existentes em Data; não são índices da lista nem IDs de conta Roblox. Os avatares da conta continuam sob `AvatarAppearance` e não foram substituídos.

`Model.resolve(config, "with_ball" | "without_ball")` retorna uma tabela por `slotId`, contendo `playerId`, `x`, `y`, `row`, `roleId`, `behaviorId`, `pressIntensity`, `tempo`, `support` e `risk`. Coordenadas de domínio são normalizadas: próprio gol em `y=1`, ataque em direção a `y=0`. Nenhuma dependência Roblox ou pixel entra nesse cálculo.

A projeção trapezoidal usa `Pitch.project`. O layout aplica espaçamento mínimo apenas aos cartões: não sobrescreve as âncoras do domínio. Isso permite ligar um futuro motor 2D aos dados confirmados, sem reaproveitar posições de GUI como se fossem coordenadas da simulação.

## Regras implementadas

- Cinco alternativas: as quatro exigidas mais a antiga 3–5–2. Cada uma contém exatamente onze slots.
- O matching bipartido considera posições principais e compatibilidades explicitamente catalogadas. Tenta manter atribuições anteriores. `available=false` exclui o atleta; os dados existentes não têm lesões/suspensões simuladas.
- Elenco atual de 22 atletas preservado. O 5–4–1 usa três zagueiros reais desse elenco, incluindo um antigo reserva. Forma inválida não altera parcialmente o rascunho.
- Sem repetição de atletas, slots extras, papéis impossíveis, comportamentos incompatíveis, IDs duplicados no elenco, valores não finitos ou fora dos intervalos.
- Construção: equilibrada (`tempo=.5`, `support=.5`), passe curto (`.3`, `.85`) e direta (`.85`, `.3`). Também ajusta avanço das linhas ofensivas.
- Pressão: baixa (`intensity=.25`), média (`.5`) ou alta (`.85`), com ajuste explícito do bloco sem bola.
- Mentalidade: cautelosa (`risk=.25`), equilibrada (`.5`) ou ofensiva (`.8`); altera o avanço coletivo.
- Amplitude altera a ocupação horizontal. Altura da linha altera avanço coletivo. Funções e comportamentos possuem coeficientes próprios de avanço, abertura e pressão.
- Sem bola, o bloco fica mais compacto; com bola, funções definem apoios e ocupação ofensiva. O goleiro permanece perto de sua área, com avanço específico na função líbero.
- Indicadores são consequências determinísticas das escolhas: passe curto/pressão na saída; construção direta/risco de perder posse; pressão alta/exigência física; linha alta/espaço atrás; amplitude/distância entre apoios; mentalidade/transição; laterais ofensivos/cobertura. Não são probabilidades, notas de qualidade ou resultados esportivos.

## Estado, migração e preservação

A primeira abertura importa a formação legada e, se presentes, os antigos valores de `state.tactics`; registra uma configuração ativa válida. Depois, `Session.new` clona a ativa para um rascunho local. Salvar valida novamente e substitui a ativa por uma cópia independente. Cancelar recria o rascunho; sair descarta-o. Alternar a fase é apenas uma preferência de visualização e não torna a tática pendente.

`state.formation` e `Data.formations` continuam intactos para consumidores legados. A tela Elenco passa a usar a configuração confirmada quando existir; mantém os índices originais para perfis e distribui titulares/reservas pelos IDs corretos. Sem configuração nova válida, conserva a apresentação anterior.

`App` recebeu somente a exceção de fundo de Táticas e o rótulo específico do rodapé. A tela administra seus próprios controles e orientação. `Pitch.draw` ganhou uma paleta opcional; a aparência antiga é o padrão. Não houve mudança no bootstrap, mapeamento Rojo, servidor, UI compartilhada, Scope, Scene, introdução, túnel, HomeHUD, arena, avatares, áudio ou workflows.

O validador de sintaxe recebeu `errors="replace"` apenas ao decodificar a saída do compilador: o Luau pode cortar strings UTF-8 ao imprimir o disassembly. Os arquivos continuam sendo lidos como UTF-8 estrito e o código de saída continua decidindo falhas; nenhuma falha de compilação é ignorada.

## Verificação automatizada

Ferramentas oficiais: Luau **0.745** e Rojo **7.7.1**, com os mesmos SHA256 fixados no workflow atual. Comandos executáveis no README. A nova suíte `tools/tactics.spec.luau` é carregada pelo runner de smoke já executado no Actions; nenhum workflow precisou mudar.

| Verificação | Resultado local |
| --- | --- |
| Integridade, require, rotas e compilação sintática | 57 fontes, 15 rotas, aprovadas |
| Dados existentes | 653 verificações aprovadas |
| Smoke de interfaces existentes | 529 montagens, 401 callbacks, 200 asserções aprovadas |
| Táticas | 110.072 asserções aprovadas |
| App / navegação / dispositivos | 6.076 asserções aprovadas |
| Introdução cinematográfica | 2.034 asserções aprovadas |
| Arena de Treino | 365.840 asserções aprovadas |
| Rojo / XML | Arquivo construído; 57 fontes idênticas, um bootstrap cliente e um servidor |
| `git diff --check` | Aprovado |

Táticas cobre todas as formações e fases, extremos 10/90 de amplitude e linha, predefinições, funções/comportamentos permitidos, colisões entre pares de cartões e amostras intermediárias da troca de fase. Inclui validações negativas, IDs não contíguos, indisponibilidade do terceiro zagueiro, confirmação/cancelamento, abertura posterior, indicadores estáveis, callbacks reais dos seletores, instâncias/conexões constantes em edições repetidas e descarte.

App cobre a integração na navegação real do módulo, bloqueio pela Central, confirmação na sessão, abandono do rascunho ao sair, orientação restaurada, retorno ao lobby, foco e alvos calculados em 1600×900, 1920×1080, 2560×1080, 1024×768, 854×393, 720×360, 640×360 e 568×320. As suites usam o runtime Luau real com APIs Roblox substituídas, relógio virtual e medidas numéricas. Não são execução do motor Roblox.

Uma projeção auxiliar da árvore de GUI e medidas aproximadas de fontes ajudou a encontrar/corrigir quebra de texto nos cartões e indicadores. Foi inspeção de layout derivado do código, **não captura Roblox**, nem confirmação das métricas reais de Gotham, materiais ou renderização.

## Arquivos alterados ou acrescentados

- `AGENTS.md`, `CL27_PLAN.md`, `CL27_PROGRESS.md`, `README.md`, `docs/TACTICS_EDITOR.md`.
- `src/client/App.luau`.
- `src/client/Screens/Tactics.luau`, `TacticsControls.luau`, `TacticsLayout.luau`, `TacticsPitch.luau`, `Pitch.luau`, `Squad.luau`.
- `src/shared/TacticsCatalog.luau`, `TacticsModel.luau`, `TacticsSession.luau`.
- `tools/tactics.spec.luau`, `tools/app-states.spec.luau`, `tools/runtime-smoke.luau`, `tools/run-runtime-smoke.py`, `tools/validate.py`.

## Pendências de aceitação no Roblox

1. Abrir o artefato da branch em Studio e executar Play. Percorrer introdução → lobby → Central → Táticas; capturar cada formação nas duas fases e comparar a referência 1.
2. Confirmar tamanhos reais de fonte, cartões, contraste e bordas; rolar até os últimos controles e indicadores. Não considerar a etapa visual aprovada antes disso.
3. Testar toque em Android horizontal, arrasto nos dois eixos, mudanças de orientação e resolução, insets e barras nativas. O modo compacto exige rolagem deliberadamente.
4. Testar gamepad físico: foco visível, cruzamento campo/controles, listas roladas, ativação, B, Central e retorno; conectar controle durante a sessão.
5. Alterar função/comportamento, cancelar e reabrir; confirmar outra formação e verificar titulares/reservas em Elenco. O estado deve durar apenas até encerrar a sessão.
6. Verificar Output, interrupções de tween e uso de memória após repetidas entradas/saídas; medir desempenho em hardware identificado.
7. Conferir visualmente introdução, lobby, túnel e Arena de Treino, além da audição dos sons existentes. As regressões automatizadas não certificam renderização ou áudio.

Não há Studio/Player disponível nesta execução. Portanto a implementação e a compilação são verificadas, mas a aceitação visual e de dispositivos continua pendente. Não foi feita publicação Open Cloud.

## Próxima etapa, ainda não iniciada

Nota da branch da etapa 2: a continuação foi autorizada em 16/11/2026 e está documentada em [MATCH_LOBBY.md](MATCH_LOBBY.md). O texto abaixo registra o limite histórico da entrega #21. O editor permanece intacto; `TacticsModel.replacePlayer(config, slotId, playerId, roster)` acrescenta uma substituição validada e atômica, preservando função/comportamento do slot. A nova preparação consome o mesmo estado ativo, sem uma segunda formação confirmada.

A etapa 2 poderá ler uma cópia de `state.tacticalPlan.active`, usar `playerId`/`slotId` para formação e reservas e reutilizar `AvatarAppearance.request` para o R15 da conta. O futuro motor deverá revalidar o contrato e possuir autoridade apropriada no servidor; a configuração atual é local ao cliente. Lobby pré-partida, novos avatares de apresentação, motor 2D, adversários IA, transferências, ligas e vitória cinematográfica não foram implementados nesta etapa. Avançar exige autorização.

APIs consultadas: [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject), [ScrollingFrame](https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame), [PlayerGui](https://create.roblox.com/docs/reference/engine/classes/PlayerGui) e [ScreenOrientation](https://create.roblox.com/docs/reference/engine/enums/ScreenOrientation).
