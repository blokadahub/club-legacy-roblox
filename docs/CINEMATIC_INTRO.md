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
| 6,14–6,60 s | Retorno do círculo, arco verde, rotação curta, título entrando lateralmente e escala até 1,28. |
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

## Implementação e recursos

| Arquivo | Responsabilidade |
| --- | --- |
| src/client/Intro/IntroTimeline.luau | Relógio monotônico, gate de prontidão, START, eventos únicos e cancelamento. Não depende de FPS. |
| src/client/Intro/IntroController.luau | Monta escudo antes de App, prepara lobby em tarefa separada, coordena efeitos/indicador, foco, revelação e descarte. |
| src/client/Intro/IntroVisuals.luau | Marca vetorial própria, mensagens, boas-vindas, curvas Quart do TweenService avaliadas por tempo absoluto, corte e passagem final. |
| src/client/Intro/IntroBackground.luau | Sete facetas autorais / 14 WedgeParts em ViewportFrame estático, câmera própria, sem tocar câmera/Lighting globais. |
| src/client/Intro/IntroAudio.luau | Três Sounds em SoundService, pré-carregamento concorrente cancelável, volume 0,65, diagnóstico e ausência de substituição. |
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
4. Verificar permissões, TimeLength e conteúdo dos três sons no Output/Studio. Se um não carregar até seu marco, a abertura avisa e prossegue sem ele. Não alterar ordem/IDs sem verificar o conteúdo.
5. Esperar pelo menos 30 s em START; pressionar por toque, mouse e controle. Verificar que o lobby não reconstrói, música começa uma vez, navegação e carregamento de Clubs permanecem intactos.
6. Simular rede lenta, câmera substituída, movimento reduzido e destruição do ScreenGui durante espera/saída. Verificar limpeza no Explorer/Output.

Backup local: branch backup/pre-cinematic-intro-133f6a1 e bundle verificado fora do checkout. Implementação parte de main 133f6a1c21691deb6e684d1467f5197f4b62b7f8, que contém PRs #9 e #10. Não alterar publish.yml, IDs Roblox, fazer merge ou publicar a experiência.
