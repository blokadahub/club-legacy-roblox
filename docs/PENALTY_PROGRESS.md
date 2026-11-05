# CL 27 — pênaltis: progresso e continuidade

## Estado em 04/11/2026 (Fortaleza)

**Etapa 1 implementada, aguardando avaliação visual do usuário no jogo. Etapas 2 e 3 não iniciadas.**

- Repositório: `blokadahub/club-legacy-roblox`.
- Base: `main` em `1361f231e1cdff34307502e28f047361cf96ca94` (inclui o refinamento radioativo do PR #14).
- Branch independente: `feat/cl27-penalty-stage1`.
- Commit de implementação: será registrado no fechamento desta entrega; para resolver o HEAD de documentação use `git log -1` ou o HEAD do PR.
- Nenhum merge, workflow de publicação ou envio ao Roblox executado nesta sessão.
- Próxima ação: publicação manual e avaliação pelo usuário. **Não começar gameplay sem autorização expressa posterior.**

## Referência efetivamente examinada

Arquivo enviado: `VID_20261104_215653.mp4`, 1920×1080, 30 quadros/s, 27,3067 s.

Foram decodificados e inspecionados:

- Uma folha de contato do vídeo completo, amostrada a 1 quadro/s, para comparar as cobranças e os retornos de câmera.
- Os 18 quadros consecutivos iniciais (0–0,567 s, 30 quadros/s).
- Uma sequência em 7,7–8,9 s, amostrada a 10 quadros/s, para comparar reposicionamento e pose de espera.
- Cinco sequências de 30 quadros consecutivos nos intervalos 4–5, 9–10, 14–15, 19–20 e 24–25 s.

Isso é inspeção dos trechos relevantes da referência, **não revisão de cada um dos quadros do arquivo inteiro**, nem captura do jogo implementado.

Constantes observadas: cobrador à esquerda (~30% da largura), bola central (~50%, perto de 70% da altura), gol frontal central (aproximadamente metade da largura), goleiro no centro da linha; faixa escura de publicidade, guarda-corpo claro e arquibancada azul com corredores verticais. Cobrador com colete claro e roupa escura, goleiro rosa. Câmera frontal comprimida, elevada atrás do cobrador. As mudanças para o ângulo lateral, deslocamentos de corrida, defesas, círculos coloridos de mira e overlays são ações transitórias; não foram transformadas em elementos permanentes do cenário.

## Cenário e decisões técnicas

| Elemento | Implementação |
| --- | --- |
| Escala | 3 studs por metro; R15 original do projeto, cerca de 5,6 studs de altura |
| Campo | 204×315 studs; piso contínuo plano, material Grass e faixas discretas; linhas laterais/de fundo, meia-lua, áreas nas duas extremidades, círculo central e escanteios |
| Marca | 33 studs da linha do gol (11 m) |
| Baliza | Abertura interna 21,96×7,32 studs; postes circulares brancos, travessão, apoios traseiros e rede aberta simples |
| Rede | Fios estáticos sem tecido, deformação, collider ou atualização por frame; malha mais espaçada em Baixa |
| Arquibancadas | Setores traseiros com degraus reais, assentos azuis agrupados, variação de cor, escadas, corrimãos, passagem superior, painéis e continuação lateral |
| Cobrador | R15 independente, à esquerda e atrás da marca, uniforme Academy claro/escuro CL 27; frente voltada à bola |
| Goleiro | R15 independente centralizado na linha, uniforme rosa CL 27, luvas claras, joelhos flexionados e braços abertos |
| Poses | Motor6D calculados e pose consolidada antes de expor o modelo; partes ancoradas. Solas alinhadas ao piso por cantos transformados; nenhum salto, corrida ou chute |
| Câmera | Posição `(0,13.2,94)`, alvo `(0,2.1,17)`, FOV vertical de referência 16,6°; mesmo ajuste de canvas/área segura do CL 27. Sem deriva na arena |
| Luz | Dia 13h30, ambiente neutro, Bloom e raios desligados, sem Atmosphere/fog próximo ou luzes locais |

Uma reprojeção matemática da geometria e dos volumes dos personagens foi gerada e inspecionada para verificar relações espaciais e enquadramento. Não usa o renderizador Roblox, não reproduz suas sombras/materiais e não comprova aparência final.

**Orçamento contado:** 1.145 peças de arquitetura em Baixa; 1.688 em Média/Alta, além dos dois rigs e da bola. Somente o piso colide. Geometria ancorada, sem partículas, luzes locais, multidão ou loops próprios por frame. A única atualização de câmera é a já existente em `Scene`. Os números são contagens, não medições de FPS ou de tempo de carregamento no Android.

### Bola do lobby preservada

O lobby utiliza `ReplicatedStorage.CL27Assets.AcademySoccerBall`, asset `17275757538`, carregado e sanitizado pelo servidor. Quando indisponível, usa uma esfera clara com 11 painéis escuros construída em `MenuAvatar`.

Os dois construtores existentes foram exportados **sem mudar o funcionamento do lobby**. A arena cria uma instância independente com diâmetro 0,78 stud sobre a marca. Reutiliza o template sanitizado se já estiver disponível ou se chegar depois; mantém a mesma alternativa geométrica enquanto isso. O template e a bola original não são movidos, removidos ou redimensionados. Conexões de chegada do asset são desligadas ao sair. A bola da etapa 1 permanece ancorada e sem colisão.

### Navegação e restauração

`Introdução → Lobby → Aprenda a Jogar → Arena de Treino → cenário de pênaltis`.

- O submenu **Arena de Treino** foi reativado para mouse, toque e controle. Os outros três treinamentos continuam indisponíveis.
- A cápsula central de Aprenda também se chama **Arena de Treino** e representa a mesma escolha. Não há outra escolha de modo, confirmação ou Start dentro da arena.
- Entrar/sair da arena é imediato, sem tela artificial de carregamento. Mantidos o halo de seleção, o contorno animado e o verde `#5cff33` dos componentes existentes.
- Não foi criado atalho na Central, Kick Off/Jogo Rápido, Manager ou Clubs. O destino de Jogo Rápido permanece exatamente o anterior.
- HUD pequeno com retorno **‹ LOBBY** de 148×54 pixels reais, independente do canvas; botão B do controle e tecla B retornam ao lobby.
- A arena não abre a Central por M/Y. Não altera controles de personagem, não cria avatar jogável e não muda a política de spawn existente.
- `Scene` continua como único proprietário de câmera/Lighting. Ao trocar de ambiente, descarta a prévia, restaura o enquadramento e aplica a iluminação do destino; HUD e conexões são descartados pelo Scope. Ao encerrar o App, a restauração original de câmera/Lighting continua em vigor.
- Falha de construção recupera o lobby e libera os bloqueios de entrada. Reentradas não acumulam histórico da arena.

## Arquivos desta entrega

| Arquivo | Responsabilidade |
| --- | --- |
| `src/client/Environments/PenaltyLayout.luau` | Medidas, câmera, ambiente e descritores puros de geometria |
| `src/client/Environments/PenaltyActors.luau` | Dois R15, consolidação da pose e apoio dos pés |
| `src/client/Environments/PenaltyScene.luau` | Construção/descarte, perfis de detalhe e cópia independente da bola |
| `src/client/Screens/PenaltyArena.luau` | HUD e retorno ao lobby |
| `src/client/App.luau` | Rota, entrada direta, foco, saída, recuperação e exclusão do atalho na Central |
| `src/client/Scene.luau` | Integração ao controlador existente e luz diurna |
| `src/client/Rig.luau` | Duas poses estáticas adicionais; poses anteriores preservadas |
| `src/client/MenuAvatar.luau` | Exportação dos construtores de bola já existentes |
| `src/client/HomeHUD.luau`, `HomeShowcase.luau` | Restaurar opção Arena e cápsula mantendo componentes visuais |
| `tools/penalty-stubs.luau`, `penalty.spec.luau` | Verificações numéricas, poses e ciclo de vida com APIs substituídas |
| `tools/run-app-states.py`, `app-states.spec.luau`, `validate.py` | Executar nova suíte e atualizar contratos de navegação |
| `.github/workflows/build.yml` | Nova suíte incluída na compilação, sem alterar publicação |
| `CL27_PLAN.md`, `CL27_PROGRESS.md`, este documento | Estado atual e continuidade |

## Verificações locais executadas

Ferramentas oficiais: Luau **0.745** e Rojo **7.7.1**, ambos com SHA256 conferido contra os valores fixados no workflow.

| Verificação | Resultado |
| --- | --- |
| Estrutura, rotas e sintaxe Luau | 47 fontes, 15 rotas; aprovado |
| Dados e formações | 653 verificações aprovadas |
| Interfaces existentes | 519 montagens, 381 callbacks, 240 asserções aprovadas |
| Estados do App | 5.933 asserções aprovadas, incluindo entrada direta, retorno por três meios, reentrada, foco, erro simulado e toque móvel |
| Introdução | 2.003 asserções aprovadas |
| Arena | 27.237 asserções numéricas/ciclo de vida aprovadas: medidas, projeção, peças, colisões, grounding, orientação, R15, bola independente, asset tardio, descarte e iluminação |
| Rojo/XML | Experiência gerada; as 47 fontes incorporadas são idênticas às fontes locais |
| `git diff --check` | Aprovado |

Os harnesses usam Luau real com APIs substituídas e relógio virtual. A nova suíte de pose usa matrizes de transformação e testa as fontes reais, mas **não executa o motor Roblox**. Mensagens de erro no teste de falhas são injetadas deliberadamente e seguidas de asserções de recuperação.

Comandos reproduzíveis (ajuste os caminhos dos executáveis):

```bash
python3 tools/validate.py --compiler .tools/luau/luau-compile
python3 tools/run-data.py --runtime .tools/luau/luau
python3 tools/run-runtime-smoke.py --runtime .tools/luau/luau
python3 tools/run-app-states.py --runtime .tools/luau/luau
python3 tools/run-app-states.py --runtime .tools/luau/luau --intro
python3 tools/run-app-states.py --runtime .tools/luau/luau --penalty
.tools/rojo/rojo build default.project.json --output club-legacy.rbxlx
python3 tools/validate.py --place club-legacy.rbxlx
```

## Publicação manual e avaliação

O workflow de publicação existente aceita **somente `main`**. Ele não foi enfraquecido para esta entrega.

1. Abra o Pull Request da branch `feat/cl27-penalty-stage1`, revise as alterações e aguarde a compilação verde. Faça o merge **manualmente**, quando decidir publicar esta prévia.
2. Abra [CL 27 | Publicação manual Roblox](https://github.com/blokadahub/club-legacy-roblox/actions/workflows/publish.yml).
3. Em **Run workflow**, selecione `main`, marque **publicar** e preencha **confirmar_place_id** com `86256105108811`.
4. Execute manualmente e confira o sucesso do job de publicação e o `versionNumber` retornado. O destino já configurado é Universe `9749365367`, Place `86256105108811`; confira que segue sendo o CL 27 pretendido.
5. Entre em um servidor novo do jogo, conclua a introdução e siga **Aprenda a Jogar → Arena de Treino**. O cenário deve abrir diretamente.
6. Avalie no celular horizontal: gol inteiro e branco, bola visível, cobrador à esquerda com pés no gramado, goleiro central, azul das arquibancadas, marcações e iluminação clara. Use **‹ LOBBY**, entre novamente e teste também Jogo Rápido/Clubs/Configurações para conferir a restauração.
7. Informe os ajustes de cenário ou autorize expressamente a etapa 2. Até essa autorização, a bola não chuta e o goleiro não defende.

Antes de fazer merge, a compilação da branch/PR também disponibiliza `club-legacy-rbxlx` para inspeção. Apenas executar o build não publica nada.

## Limitações e continuidade obrigatória

- Não houve execução ou captura visual Roblox nesta sessão. Fidelidade de materiais/sombras, toque real, controle real, permissões do modelo e desempenho no Redmi 12 precisam de avaliação no jogo publicado.
- Assentos são grupos geométricos, sem multidão. Rede simples e estática. A câmera é fixa; o usuário avalia o enquadramento principal, sem controle de órbita nesta etapa.
- Rigs são apresentações R15 com pose consolidada e partes ancoradas. A etapa 2 deverá preparar rigs para animações, sem presumir que estes modelos estáticos já sejam controladores jogáveis.
- Gameplay, força, mira, trajetória, giro, autoridade de servidor, colisão da bola, goleiro, áudio de chute/defesa, placar e animações completas **não foram implementados**.
- Etapa 2, somente depois de autorização: manter a rota existente e os módulos de medidas; acrescentar controlador de cobrança, animações R15 e física com contrato cliente/servidor, controles e perfis medidos no dispositivo.
- Etapa 3, depois da etapa 2: auditoria de comportamento real, transições, carregamento, retorno, falhas, desempenho e refinamentos aprovados.

**Ponto de parada: fim da etapa 1.**
