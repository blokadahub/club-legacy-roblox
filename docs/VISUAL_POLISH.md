# CL-27 — revisão completa da Etapa 02.5

## Diagnóstico registrado antes da implementação — 17/11/2026

TXT integral e três imagens relidos. Referência 1: editor, arquivo `01-1000778387.jpg`; referência 2: lobby, `02-1000778386.jpg`; referência 3: resultados futuros, `03-1000778385.jpg`. Nenhum asset será extraído das imagens.

GitHub conferido: #21 `6b353c2`, #22 `ffb05ec`, #23 `a76a30b`, todos abertos/em rascunho. A nova branch exigida pelo TXT, `feat/cl27-mega-visual-polish`, preserva os commits de #23; o PR terá #22 como base. Não há merge na main nem publicação.

| Critério | Evidência do código atual | Decisão de implementação |
| --- | --- | --- |
| Composição | Editor reúne campo e análise num mesmo conteúdo rolável; o zoom compacto recorta parte dos onze cartões | Manter o campo completo e separar análise/seleção contextual no compacto |
| Tipografia | Gotham já é usado, mas escalas e cores estão duplicadas; cor de ação tática difere de `#5cff33` do menu | Tokens esportivos no Theme existente; sem substituir a biblioteca UI |
| Espaçamento | Controles são cartões iguais; predefinição e configuração têm pouco contraste hierárquico | Predefinição dominante, linhas editoriais e medidores nos valores numéricos |
| Contraste | #23 corrigiu a seleção escura e foco perdido | Preservar correções e testar também estados desativados/alto contraste |
| Cartões | Editor não identifica o atleta; nomes/funções no lobby têm área fixa estreita | Cartões leves com nome, posição, função e marca original do clube, sem retratos/R15 adicionais |
| Materiais / luz | Quatro emissores com dois no modo baixo; painéis são SmoothPlastic | Refinar material das placas e profundidade do fundo, sem aumentar emissores |
| Profundidade | Corredor termina em parede plana; teto/painéis já criam perspectiva | Portal técnico ao fundo dentro do limite existente de menos de 70 peças |
| Animação | Foco dos controles muda instantaneamente; ficha não possui entrada própria | Respostas curtas e canceláveis pelo Scope; movimento reduzido imediato |
| Responsividade | Alvos ampliados, mas o editor não preserva a vista geral compacta | Campo completo, ficha contextual, análise separada e testes com insets/rotação |
| Consistência | Gestão utiliza fundos azuis/turquesa e cores locais diferentes | Correções pontuais de superfícies/editoriais; preservar menu, configurações e cenas antigas |

Estes são fatos verificáveis do código e inferências de composição, não defeitos observados numa renderização Roblox. Aparência dos materiais, qualidade percebida, iluminação do rosto, sombra e desempenho permanecem pendentes do motor real.

## Contratos preservados

Sem mudanças em TacticsCatalog/Model/Session, MatchLobbyModel, dados do elenco, bootstraps ou workflows. Onze titulares e cinco reservas, estado editável/confirmado, cancelamento e persistência somente na sessão. Scene continua controlador único de câmera/iluminação. O avatar continua sendo uma cópia R15 da conta; não se altera Player.Character.

## Plano de verificação

Compilação oficial Luau 0.745, Rojo 7.7.1, dados, smoke de todas as telas, regras táticas/lobby, estados de App, abertura e Arena. Acrescentar verificações significativas para campo completo, todos os atletas acessíveis, modais, foco, feedback interrompido, cores, encaixe e orçamento geométrico. Resoluções: 1600×900, 1920×1080, 2560×1080, 1024×768, 854×393, 720×360, 640×360 e 568×320.

Não foi encontrado Studio/Player no ambiente Linux. Projeções auxiliares da árvore de GUI, se usadas para diagnóstico, não são capturas do jogo nem evidência de fidelidade.

A implementação foi validada por código e testes automatizados, mas a aprovação visual no Roblox permanece pendente.


## Implementação concluída — comparação técnica

| Região | Antes desta revisão (a76a30b) | Depois |
| --- | --- | --- |
| Predefinição | Cartão de 144 unidades com hierarquia próxima à lista | Cartão branco de 200 no desktop, escudo original, descrição e escolha dominante; cabeçalho compacto contextual |
| Configurações | Seis cartões preenchidos com duas linhas iguais | Linhas transparentes, separadores finos, valor alinhado à direita no desktop, medidores de amplitude/linha e limites sem ação falsa |
| Campo do editor | Campo e diagnóstico num canvas ampliado com rolagem XY | Formação inteira ajustada à região disponível, sem pan, análise independente; nunca altera coordenadas de domínio |
| Atletas | Posição, função e comportamento | Nome real do elenco fictício, posição/número, função, comportamento, faixa da cor original do clube; abreviação legível e seletor amplo no celular |
| Consulta no celular | Toque em cartões ampliados fora da vista geral | Campo inteiro abre ficha com onze atletas; foco segue para instruções individuais; análise apresenta todos os textos do modelo |
| Análise | Texto sob o campo, afastado pela ampliação | Duas colunas separadas no desktop e ficha completa acessível também por gamepad; contagens vêm do modelo |
| Estado / foco | Seleção persistente, sem transição local | Contorno de 0,14 s, ficha e troca de formação de 0,16 s; cancelamento de tween anterior, respeito a movimento reduzido, bloqueio do fundo da ficha |
| Lobby | Cartões sem identidade de clube, ficha instantânea, ações sem candidato ainda habilitadas | Marca do clube, ficha com entrada finita, ação indisponível desativada, navegação de foco válida mesmo sem candidatos |
| Cabeçalhos compactos | Títulos longos em caixas fixas | Clube/formação na mesma linha, reservas em título curto, técnico identificado sem texto duplo comprimido |
| Corredor | 65 descritores, painéis plásticos, parede final plana | 69 descritores, painéis metálicos, portal de quatro peças, painel final dentro do perímetro; mesmas quatro luzes |
| Avatar | Limites 7,1 × 3,2; pés em y=0,04 e inlay com topo 0,025 | Limites 7,8 × 3,52; pés no topo real do inlay. Mesma aparência/cache/pose, sem alterar Character |
| Gestão | Superfícies azuis e faixas diagonais turquesa | Grafite, cinza metálico, filetes; as cores escolhidas na personalização continuam respeitadas |

A releitura detectou o painel final ultrapassando o fundo do corredor e uma folga de 0,015 stud entre pés e piso. A suíte nova também encontrou altura insuficiente para um controle inteiro em 568×320 com insets; o cabeçalho compacto foi reorganizado. São correções de geometria/código, sem alegação de defeito observado em renderização.

## Auditoria das demais telas

| Tela / sistema | Inspeção e decisão |
| --- | --- |
| Visão geral | Superfície neutra e metadados explicitamente demonstrativos; condição média permanece derivada do elenco |
| Elenco | Cores do componente editorial existente, alto contraste consultado na montagem; IDs e formação confirmada preservados |
| Atribuições | Painéis e cores editoriais; seis responsabilidades, seleção, rolagem e notificações preservadas |
| Calendário | Painel neutro; agenda identificada como demonstrativa; dias/seleção/rolagem inalterados |
| Transferências | Superfície neutra; indicação de relatório fictício e shortlist preservadas |
| Finanças | Painel neutro e cinza frio para série secundária; números e legenda demonstrativa preservados |
| Desenvolvimento | Cores editoriais compartilhadas; descrição esclarece plano de sessão/evolução demonstrativa; nenhuma progressão simulada adicionada |
| Competições | Painel neutro; tabela também identificada como demonstrativa, além do chaveamento |
| Personalização | Painel neutro, identidade e opções de cor/kit preservadas; nenhuma alteração nos avatares |
| Configurações | Preservadas: SettingsHUD é a interface ativa do App; o módulo Screens/Settings continua coberto pelo smoke. Não aplicar troca global de tema sobre o layout já aprovado |
| Clubes | Preservados o túnel/HUD e o módulo legado de seleção; câmera, luz, uniforme, áudio e bloqueios cobertos pelas regressões existentes |
| Uniformes | Preservados palco, comparação de kits e seleção; não substituir os materiais/cores originais dos clubes |
| HomeHUD / HomeShowcase | Preservados o menu, tipografia e efeitos existentes; fonte de referência para verde e linguagem. Menu continua em ScreenGui próprio |
| UI / Scope / Scene / TransitionFX / RadialGlow / OuterGlowSweep | Reutilizados e preservados. Não foi criada segunda biblioteca nem outro controlador de câmera/luz |

A auditoria de gestão foi de composição no código, cores, consistência e callbacks. Não é aprovação de todos os textos dessas páginas em um Android físico. Interfaces legadas de gestão ainda precisam da leitura real em tela pequena, especialmente tabelas e metadados densos; esta revisão não as reconstruiu indiscriminadamente.

## Reuso e custo

`Theme.sports` estende o Theme existente; `TacticsControls` continua usando UI/Scope. `ManagementUI.panel` usa UI.frame/UI.line. As abreviações são compartilhadas pelo layout de apresentação. Nenhuma alteração nos modelos de domínio, Data, servidor, Rojo ou workflows.

Não há imagens externas, onze retratos/R15 novos, animação contínua adicional nem busca extra de aparência. O editor reutiliza onze cartões e onze linhas da ficha; apenas atualiza propriedades. Foram adicionados dois CanvasGroups para campo/contexto do editor e um para a ficha já existente do lobby. Esse custo de composição é limitado, mas seu impacto real na GPU Android não foi medido. O cenário mantém quatro emissores (dois na qualidade baixa), zero sombras de luz na baixa/média e uma na alta. Idle do avatar continua com opção de movimento reduzido e descarte.

## Evidência executada

Veja `VISUAL_POLISH_VALIDATION.txt` para comandos, versões, resultados e hash do build local. O runner existente de App inclui a nova suíte; nenhuma mudança de workflow. Testes com doubles executam o Luau real, mas não o motor Roblox.

A suíte nova percorre as oito resoluções exigidas × três combinações de insets, cinco formações e duas fases, verificando os onze cartões dentro do campo. Exercita todos os atletas da ficha compacta, texto do diagnóstico, bloqueio do fundo, salvar/cancelar, limites numéricos, restauração de foco, mudança de resolução sob bloqueio, transições interrompidas e descarte.

O avatar de teste fica numericamente entre x=0,792–0,962 e y=0,269–0,857 do quadro base; são projeções de um fixture R15, não do avatar real do proprietário. Roupas em camadas, acessórios, rig incompleto, timeout, retry, cache e callbacks tardios continuam cobertos por fixtures. Não foi emitida captura conceitual nem screenshot falso.

## Pendências objetivas para Roblox

1. Abrir o artefato do PR no Studio e executar Play; comparar menu, editor e lobby com as referências recebidas.
2. Capturar editor em 1600×900 e 568×320: predefinição, cinco formações, duas fases, funções e ficha/análise abertas. Conferir Gotham real, quebra de nomes e contraste.
3. Capturar lobby com a conta real: corpo inteiro, pés no piso, rosto/cabelo/acessórios, roupa em camadas, cinco reservas, titular/reserva selecionados e ficha. Conferir luz quente/fria sem brilho excessivo.
4. Exercitar mouse, gamepad e toque físico: alternar controle durante foco, rolar até o último item, confirmar/cancelar, abrir Central com ficha, voltar e redimensionar/rotacionar.
5. Comparar baixa/média/alta, alto contraste e movimento reduzido. Medir FPS, tempo de frame e memória em Android; não há medição local desses itens.
6. Abrir as doze telas auditadas; verificar densidade tipográfica, dados demonstrativos, seleção e retorno ao menu. Repetir introdução e Arena de Treino com áudio real.

Critérios de aparência profissional, semelhança final com as referências, materiais/rosto/sombras e desempenho ficam **pendentes** até esse exame no motor. Funcionalidade, limites geométricos e ciclos de vida passaram nas verificações automatizadas disponíveis.

A referência 3 permanece reservada à etapa futura: não há tela de vitória, partida, IA ou multiplayer neste PR. Sem merge ou publicação Roblox.

## Manifesto desta continuação

- `CL27_PROGRESS.md`
- `docs/VISUAL_POLISH.md`
- `docs/VISUAL_POLISH_VALIDATION.txt`
- `src/client/App.luau`
- `src/client/Environments/MatchLobbyLayout.luau`
- `src/client/Screens/Assignments.luau`
- `src/client/Screens/Calendar.luau`
- `src/client/Screens/Competitions.luau`
- `src/client/Screens/Customization.luau`
- `src/client/Screens/Development.luau`
- `src/client/Screens/Finance.luau`
- `src/client/Screens/ManagementUI.luau`
- `src/client/Screens/MatchLobby.luau`
- `src/client/Screens/MatchLobbyPitch.luau`
- `src/client/Screens/Overview.luau`
- `src/client/Screens/Squad.luau`
- `src/client/Screens/Tactics.luau`
- `src/client/Screens/TacticsControls.luau`
- `src/client/Screens/TacticsLayout.luau`
- `src/client/Screens/TacticsPitch.luau`
- `src/client/Screens/Transfers.luau`
- `src/shared/Theme.luau`
- `tools/match-lobby-scene.spec.luau`
- `tools/run-app-states.py`
- `tools/tactics-app.spec.luau`
- `tools/visual-polish.spec.luau`

Os commits anteriores de #23 permanecem no histórico e no diff total do novo PR. Nenhum arquivo das regras táticas/inscrição, dados, áudio ou workflow foi alterado nesta continuação.
