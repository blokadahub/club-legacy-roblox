# CL-27 — Etapa 02.5: composição, contraste e foco

Base: Etapa 02, `feat/cl27-mega-match-lobby`. Continuação na branch existente `feat/cl27-visual-polish-025`, PR #23. Não altera a main nem os PRs anteriores.

## Problemas corrigidos

O primeiro polimento aplicava um gradiente escuro também ao cartão selecionado, que usava textos escuros. Como UIGradient multiplica a cor de fundo, a superfície clara não era preservada. Agora os cartões não selecionados usam uma base branca com o gradiente grafite; o selecionado desliga esse gradiente e recebe superfície clara e texto escuro. Táticas, titulares e reservas usam a mesma hierarquia.

O contorno também perdia a seleção ao receber MouseLeave/SelectionLost. A seleção da tática agora é independente do foco transitório; mouse e gamepad mantêm estados separados, sem criar conexões durante a interação. A opção de alto contraste passa a alcançar os textos secundários dos componentes táticos. São verificações de cores declaradas e callbacks; não certificam a renderização.

## Comparação por região

| Referência / região | Alteração |
| --- | --- |
| 1 — editor | Cartões grafite com seleção clara; função, comportamento e posição preservados; fases/abas mantêm o estado visual após hover |
| 2 — topo | Abas transparentes com régua somente na aba ativa; áreas de toque e rolagem preservadas |
| 2 — banco | Cinco cartões com condição física ligada aos dados do elenco, hierarquia de nome/posição e seleção clara; selecionar reserva remove destaque de titular e vice-versa |
| 2 — campo | Retirada a placa retangular opaca atrás do campo; três bordas seguem o trapézio, mantendo o túnel exposto. Sem alterar âncoras, formação, colisões ou projeção |
| 2 — ficha / rodapé | Régua discreta na ficha e gradiente localizado para leitura das ações; dados e botões continuam funcionais |
| 2 — corredor | Seis juntas de piso sem sombra dinâmica; painéis mais escuros no fundo. 65 descritores arquitetônicos, abaixo do teto existente de 70 |
| 2 — personagem | Mesmo pipeline R15, enquadramento e cópia da conta; nenhum personagem ou emissor adicional |
| 3 — resultados | Referência futura. Nenhuma tela de vitória, placar ou resultado implementado |

O texto de indisponibilidade passa a informar “Simulação de partidas — Em desenvolvimento”. Etapas de engenharia não precisam aparecer na navegação do jogador.

## Integridade

Continuam intactos: estado tático, validação/transações dos 16 atletas, introdução, menu principal, túnel antigo, Arena, áudio, pipeline de aparência, Scene como dono da câmera/iluminação e workflows. Os 22 atletas continuam no clube. Persistência somente na sessão.

As juntas ficam após a área do técnico; a face inferior toca o piso, sem faces coplanares, e não atravessam o perímetro do corredor. Quatro emissores, dois em qualidade baixa, e uma cópia R15 continuam sendo os limites. Não há promessa de FPS.

## Validação desta retomada

- Executor local indisponível: não foi possível compilar localmente, abrir Studio/Player ou reler o TXT anexado. As três imagens recebidas foram revistas diretamente; escopo mantido a partir da conversa e do PR existente.
- A nova suíte `tools/visual-polish.spec.luau` verifica contraste calculado das cores, seleção persistente, foco combinado mouse/gamepad, estado das abas e condição física derivada do elenco.
- As suítes de App e cenário verificam encaixe das novas barras nas oito resoluções existentes, posição/descarte das juntas e o mesmo teto de geometria/luzes.
- Runner existente inclui a nova suíte. Nenhum workflow foi alterado.
- Os resultados do CI serão registrados na descrição do PR após executar o commit. Não se reutiliza o resultado antigo como evidência desta revisão.

## Arquivos desta revisão

- `src/client/Screens/TacticsControls.luau`
- `src/client/Screens/Tactics.luau`
- `src/client/Screens/TacticsPitch.luau`
- `src/client/Screens/MatchLobby.luau`
- `src/client/Screens/MatchLobbyPitch.luau`
- `src/client/Environments/MatchLobbyLayout.luau`
- `src/client/Environments/MatchLobbyScene.luau`
- `tools/visual-polish.spec.luau`
- `tools/run-runtime-smoke.py`
- `tools/match-lobby-app.spec.luau`
- `tools/match-lobby-scene.spec.luau`
- Este relatório, README, CL27_PLAN e CL27_PROGRESS.

## Aceite dentro do Roblox — pendente

1. Executar o artefato da branch em Play; capturar editor/lobby em 1600×900 e Android paisagem, sem tratar mockups como evidência.
2. Comparar as regiões acima: perspectiva, proporções, nome/função dos cartões, reserva selecionada, corpo inteiro e profundidade do corredor.
3. Conferir cores em qualidade baixa/alta, alto contraste e movimento reduzido. A leitura sobre um cenário real não pode ser certificada por cálculo de cores isolado.
4. Trocar/confirmar/cancelar escalação; voltar ao editor e conferir os mesmos atletas. Percorrer onze titulares e cinco reservas com toque/gamepad físicos.
5. Entrar/sair vinte vezes; medir memória e FPS em aparelho identificado e verificar ausência de rigs/conexões remanescentes.
6. Revalidar introdução, menu original, Arena e áudio.

**PR em rascunho. Sem captura Roblox, aprovação visual definitiva, merge, publicação ou Etapa 03.**
