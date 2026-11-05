# CL 27 — abertura cinematográfica

## Referência e análise

Fonte recebida: VID_20261103_214230.mp4. ffprobe confirmou **1920×1080, 60 FPS, 23,800454 s**. O vídeo está acessível. Foram examinados quadros distribuídos por todo o vídeo (1 s), com amostragem adicional de 0,2 s na transformação e 0,25 s nas mensagens/saída. Isso é análise da referência, não captura do resultado Roblox. O print recebido mostra as mesmas facetas escuras.

Composição observada: marca circular à esquerda do título inclinado, conjunto central ocupando aproximadamente metade da largura, verde vivo seguido por branco; indicador pequeno junto ao centro inferior. Após uma breve ausência da marca, o círculo reaparece sozinho, recebe um arco verde e o título entra ampliado lateralmente. O conjunto encolhe para o centro superior. Mensagens brancas centralizadas precedem duas linhas verdes pesadas e uma cápsula START. A saída remove os textos, passa pelo roxo, fica preta e revela a cena, seguida do menu. O estádio, a taça e os materiais EA da referência não são usados.

Os tempos sonoros abaixo são os marcos solicitados. Não foi confirmada a correspondência auditiva entre os assets Roblox e a gravação: o ambiente não executa Roblox nem valida suas permissões de áudio. Não há narração nem efeito adicional aos três autorizados.

## Linha do tempo implementada

Tempo relativo ao primeiro relógio do controlador. START disponível após a entrada completa, em 17,8 s; nenhuma saída automática.

| Tempo | Implementação |
| --- | --- |
| 0–1,93 s | Escudo opaco e facetas imediatamente; marca própria CL Sports / CL 27 verde, centralizada. Sem música. |
| 1,93–2,15 s | Corte preto cinematográfico exclusivo da abertura; não chama Cover. |
| 2,15–5,80 s | Marca branca e único monograma CL inferior com varredura. |
| 5,80–6,14 s | Desaparecimento rápido da marca; fundo e indicador continuam. |
| 6,14–6,60 s | Retorno do círculo sozinho no centro; deslocamento à esquerda, arco verde, rotação curta, título entrando lateralmente e escala até 1,28. |
| 6,30 s | Efeito 1: 98087823124682. |
| 7,05–7,40 s | Conjunto reduzido à escala 0,25; centro passa de y=450 a y=210 no canvas 1600×900. |
| 7,40–8,90 s | Marca pequena superior; fade entre 8,65 e 8,90 s. |
| 8,90–13,90 s | Nome de Players.LocalPlayer.Name: “está preparando sua experiência no Roblox...”. Cápsula branca “SESSÃO ROBLOX ATIVA”, informativa, sem falso modo offline. |
| 13,90–15,25 s | “Preparando os dados locais da experiência. Aguarde...” com entrada/saída por transparência. |
| 15,25–16,60 s | “Conteúdo local carregado. Tudo pronto.” quando App está pronto; caso contrário, preparação do lobby. Não afirma download nem consulta remota inexistente. |
| 16,60–17,15 s | Entrada de WELCOME / TO THE CLUB, marca pequena acima, START e apoio discreto. Efeito 2: 101494550141867. |
| 17,15–17,80 s | Final da entrada; aguarda liberação interativa do START. |
| 17,80 s em diante | Aguarda START indefinidamente. Mouse, toque e seleção por gamepad. |
| START + 0–0,50 s | Saída dos textos e da marca. |
| START + 0,50 s | Efeito 3: 135910449013772; início da passagem arroxeada. |
| START + 0,50–1,50 s | Passagem roxa curta e entrada do preto cinematográfico. |
| START + 1,50–2,90 s | Intervalo preto; lobby real já construído em segundo plano. |
| START + 2,90–6,00 s | Revelação progressiva da cena existente. |
| START + 4,25–6,00 s | HUD existente aparece gradualmente; controles ainda bloqueados. |
| START + 6,00 s | Efeitos temporários destruídos, controles liberados e exatamente uma faixa iniciada com fade. Abertura destruída. |

Com START em 17,80 s: terceiro som em **18,30 s**, revelação da cena em **20,70 s**, início de HUD em **22,05 s**, conclusão/música em **23,80 s**. Se o usuário esperar, somente a parte posterior ao START se desloca. Se o lobby/câmera não estiver pronto, a timeline fica em 16,60 s, mostra preparação e só entra nas boas-vindas quando houver prontidão. Não reinicia os efeitos anteriores. Não há som em 22,5 s.

### Áudio atrasado sem alterar o cronograma

Os tempos da tabela são marcos de solicitação. Os três assets começam o pré-carregamento em paralelo na criação do controlador. Cada tentativa tem limite de três segundos; uma segunda tentativa pode ocorrer após 0,35 s. Não há espera bloqueante nem tentativa infinita.

Se IsLoaded ainda for falso no marco, o efeito fica pendente por **até dois segundos a partir do horário absoluto previsto**. Sound.Loaded, conclusão do pré-carregamento e a amostragem de Heartbeat podem resolver o mesmo pedido, mas ele só pode tocar uma vez. Falhas de pré-carregamento não marcam o asset como permanentemente inválido: Loaded tardio ainda pode recuperá-lo. O efeito começa do início, preservando o ataque sonoro; atrasos acima de 0,15 s são informados no Output.

START encerra também o pedido pendente de boas-vindas, evitando que ele comece durante a saída. Um novo marco sonoro cancela o pedido anterior pendente e interrompe o efeito anterior, impedindo inversão e sobreposição. Após a janela, o efeito é descartado com aviso; o horário não é renovado por um frame atrasado. Ao concluir/cancelar a abertura, pedidos, conexões, tarefas e Sounds são destruídos. Não há sons substitutos. Esta tolerância recupera cargas normais, mas não garante reprodução de um asset sem permissão ou indisponível por mais tempo. A sequência visual e a liberação da música não esperam áudio.

Antes do START, uma perda temporária de prontidão posterior às boas-vindas mantém a tela visível e desativa o botão, sem rebobinar a timeline nem repetir seu som. A prontidão é conferida novamente no próprio clique.

## Implementação e recursos

### Boas-vindas — acabamento e proporções atuais

As imagens recebidas orientam a composição: marca própria branca no centro superior, título WELCOME / TO THE CLUB em GothamBlack a 111 unidades e verde 0/239/83, facetas escuras e apoio discreto abaixo do Start. A cápsula é o mesmo componente do lobby (`UI.capsule`), em `#5cff33`, com círculo X. A pedido do usuário em 05/11, o contorno anterior ao PR #14 foi restaurado integralmente: varredura branca/menta de 4,8 s por volta, trajetória interna, mesmas cores e opacidades antigas. O componente não cria loops; `IntroVisuals:Draw` dirige o efeito, respeita movimento reduzido e bloqueio, e o destrói com a abertura.

O alvo mantém mínimo físico 112×48 px, enquanto a superfície visível pode ficar em 104×30 px nos celulares compactos. O contorno antigo usa núcleo/halos de 2,25/8,4/16 unidades do canvas, com a trajetória local preservada para UIScale. Ao concluir a abertura, Notícias do CL é a única seleção branca, seu conteúdo já está visível e o controle recebe o mesmo foco, sem disparar o novo Cyber Click automaticamente. O efeito 135026594552200 é exclusivo das seleções do lobby e não altera os sons/timeline da abertura. Medidas e histórico das três etapas em [WELCOME_REFINEMENT.md](WELCOME_REFINEMENT.md). A aparência renderizada ainda requer inspeção no Roblox.

| Arquivo | Responsabilidade |
| --- | --- |
| src/client/Intro/IntroTimeline.luau | Relógio monotônico, gate de prontidão, START, eventos únicos e cancelamento. Não depende de FPS. |
| src/client/Intro/IntroController.luau | Monta escudo antes de App, prepara lobby em tarefa separada, coordena efeitos/indicador, foco, revelação e descarte. |
| src/client/Intro/IntroVisuals.luau | Marca vetorial própria, mensagens, boas-vindas, curvas Quart do TweenService avaliadas por tempo absoluto, corte e passagem final. |
| src/client/Intro/IntroBackground.luau | Sete facetas autorais / 14 WedgeParts em ViewportFrame estático, câmera própria, sem tocar câmera/Lighting globais. |
| src/client/Intro/IntroAudio.luau | Três Sounds em SoundService, pré-carregamento com repetição limitada, recuperação de pedidos pendentes, volume 0,65, diagnóstico e descarte. |
| src/client/Main.client.luau | Único bootstrap, monta Intro antes de carregar/iniciar App. |
| src/client/App.luau | Modo deferIntro, preparação oculta, IsIntroReady, RevealIntro e CompleteIntro; navegação bloqueada até concluir. |
| src/client/HomeHUD.luau | HUD nasce oculto quando solicitado; CanvasGroup permite revelar a interface já montada. |
| src/client/Soundtrack.luau | create não reproduz; release idempotente inicia a playlist. Loaded aplica fade inclusive com carregamento tardio. |
| src/client/TransitionFX.luau | Host e relógio externos opcionais para o MESMO indicador CL; Cover/Reveal e espera de 2,5 s continuam preservados. |
| tools/run-app-states.py | Opção --intro reutiliza os stubs existentes; evento Sound.Loaded acrescentado à superfície de API do harness. |
| tools/intro-stubs.luau | Superfície adicional de câmera vetorial, áudio/preload e relógio virtual para testes, sem renderização. |
| tools/intro.spec.luau | Sequência integral, gate, FPS baixo, efeitos, música tardia, cancelamento, resoluções e navegação. |
| .github/workflows/build.yml | Executa também os testes da abertura antes de construir/upload do artefato habitual. |
| README.md, CL27_PLAN.md, CL27_PROGRESS.md | Instruções, arquitetura e evidências atualizadas. |

A marca CL Sports usa monograma geométrico CL dentro de círculo nativo com SPORTS em GothamBold. CL 27 é desenhado com traços nativos inclinados; não usa emojis, glifos improvisados, imagens EA nem assets externos. A identidade é uma composição própria, não reprodução da tipografia proprietária. Facetas usam enquadramento cover; conteúdo usa fit com margens e inset. O START tem mínimo real de 112×48 px inclusive em celulares. Movimento reduzido elimina o giro, a entrada lateral e o zoom, preservando o cronograma e acesso ao lobby.

O relógio da timeline é os.clock; Heartbeat apenas solicita a amostra do instante atual. A varredura CL usa o mesmo tempo durante a abertura e retorna ao relógio normal após ela. Nenhuma sequência acumulativa de task.wait. Interpolações são calculadas por tempo absoluto com TweenService:GetValue; não há tweens pendentes de fases anteriores na abertura.

App.start com deferIntro prepara o cenário Interior uma única vez e esconde os ScreenGuis. IsIntroReady exige cenário inicial construído, câmera principal disponível e HUD vivo. CompleteIntro é idempotente e libera Soundtrack.release somente depois dos seis segundos finais. A playlist de 12 faixas, embaralhamento, proteção de repetição, volume e intervalo foram mantidos. Não há banners.

O ViewportFrame é uma exceção local e explícita solicitada para o fundo da abertura; não substitui as cenas principais Workspace. Seu custo é fixo, sem reflexos, luzes ou loops geométricos. O controlador destrói sua câmera, geometria, UI, conexões e Sounds; o indicador compartilhado volta ao App. A navegação comum, névoa/iluminação de Clubs e módulos de ambiente não são modificados.

## Revisão do PR #11

1. **Composição/fidelidade por código:** reexaminados os quadros da referência. O círculo, antes isolado à esquerda (centro x=505 no canvas), reaparece agora em x=800 e se desloca para compor a marca. Corrigido o recorte de traços pelo próprio CanvasGroup com padding transparente, preservando dimensões e posição visíveis. As sete facetas, suas cores, câmera independente e enquadramento cover permanecem. A identidade CL é própria; não se afirma equivalência com tipografia/material EA.
2. **Animações/estados:** eliminada a multiplicação de duas camadas pretas na revelação. Antes, na metade do fade a cena recebia apenas 25% da visibilidade; agora recebe 50%, com a mesma duração e uma única camada responsável. Reavaliados eventos únicos, relógio absoluto, START, espera por prontidão, perda temporária de câmera e movimento reduzido.
3. **Qualidade/integridade:** teste inicial reproduziu a perda de som quando Loaded chegava 200 ms depois. Outros testes reproduziram recorte da marca, círculo fora do centro e escurecimento duplo antes das correções. A suíte passou após corrigi-los, sem remover os testes de regressão.

Verificações locais da revisão: **43 fontes**, **653 verificações de dados**, smoke com **519 montagens / 381 callbacks / 240 asserções**, **5.907 asserções existentes** de estados/Clubs e **836 asserções da abertura**. A suíte adicional cobre 60/30/15/5 Hz, retries, preload realmente suspenso em coroutine, timeout/cancelamento, áudio tardio em 0,2/0,35/1,9 s, expiração, pedidos substituídos, duplicidade de notificações, readiness perdida e sequência de produção completa até 23,8 s com os três sons tardios.

O teste completo confirma que Loaded da música antes do fim não libera sua reprodução, e que CompleteIntro repetido não inicia outra faixa. O indicador é único, tem fundo transparente, não intercepta entrada e não aciona Cover durante toda a abertura. Os testes existentes cobrem navegação e os módulos reais de túnel/iluminação/névoa com APIs substituídas. Esses sistemas e o workflow de publicação não foram alterados nesta revisão.

PR existente: [#11](https://github.com/blokadahub/club-legacy-roblox/pull/11), mantido em rascunho. Atualizações seguem na mesma branch; não criar outro PR. O resultado do CI correspondente ao commit revisado é informado na entrega.

## Validação e limites

```sh
python3 tools/validate.py --compiler .tools/luau/luau-compile
python3 tools/run-data.py --runtime .tools/luau/luau
python3 tools/run-runtime-smoke.py --runtime .tools/luau/luau
python3 tools/run-app-states.py --runtime .tools/luau/luau
python3 tools/run-app-states.py --runtime .tools/luau/luau --intro
.tools/rojo/rojo build default.project.json --output club-legacy.rbxlx
python3 tools/validate.py --place club-legacy.rbxlx
```

As mensagens de falha simulada dos testes de recuperação e os avisos de áudio indisponível do teste negativo são esperados. Exigir conclusão PASS e código zero.

Sem Roblox Studio/Player nesta máquina: não houve render do resultado, audição dos três assets, confirmação de duração/permissões, captura de transições, avaliação real de toque/gamepad ou medição de FPS. A inspeção analítica de composição e os testes com stubs não substituem essas etapas. Não se declara equivalência visual final.

### Auditoria necessária no Studio

1. Abrir o artefato em Studio e usar Play. Gravar do primeiro quadro do cliente até o lobby; conferir que não há flash inicial do HUD nem música antes de concluir.
2. Conferir traços/margens da marca, recorte das facetas e legibilidade em 1920×1080, 1024×768, 2560×1080 e Android horizontal 854×393, incluindo notch. Testar também orientação vertical.
3. Comparar os marcos da tabela com captura real, em especial 1,93/2,15, transformação 5,8–7,4 e saída de seis segundos. Ajustar acabamento somente com evidência real.
4. Verificar permissões, TimeLength e conteúdo dos três sons no Output/Studio. Simular carregamento ligeiramente posterior ao marco e conferir recuperação única dentro da janela; depois testar indisponibilidade superior a dois segundos e descarte sem travamento/efeito substituto. Não alterar ordem/IDs sem verificar o conteúdo.
5. Esperar pelo menos 30 s em START; pressionar por toque, mouse e controle. Verificar que o lobby não reconstrói, música começa uma vez, navegação e carregamento de Clubs permanecem intactos.
6. Simular rede lenta, câmera substituída, movimento reduzido e destruição do ScreenGui durante espera/saída. Verificar limpeza no Explorer/Output.

Backup local: branch backup/pre-cinematic-intro-133f6a1 e bundle verificado fora do checkout. Implementação parte de main 133f6a1c21691deb6e684d1467f5197f4b62b7f8, que contém PRs #9 e #10. Não alterar publish.yml, IDs Roblox, fazer merge ou publicar a experiência.
