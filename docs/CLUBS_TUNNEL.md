# CL 27 — Túnel cinematográfico na rota Clubs

Este documento descreve a integração do cenário do [experimento do PR #7](https://github.com/blokadahub/club-legacy-roblox/pull/7) à experiência principal, sem executar o bootstrap experimental.

## Comportamento

1. No lobby, selecionar **Clubs** e acionar o botão verde principal.
2. O carregamento CL já existente aparece durante **2,5 segundos**, com o fundo levemente escurecido.
3. A rota `Clubs` monta **CinematicTunnel** dentro de `Workspace.CL27_CenarioLocal`, na cena cliente. O HUD de seleção de clubes existente fica oculto nessa rota.
4. Ao concluir a transição, a camada escura desaparece. O mesmo indicador **CL** continua animado **por tempo indefinido**, na parte inferior central, sem impedir o uso de comandos.
5. Na parte superior esquerda há somente o controle discreto **‹** para retornar, em `CL27_TunnelBack` (54 × 54 px reais, não escalados pelo canvas). No teclado ou controle, **B** também volta.
6. Ao sair, a cena libera as peças e luzes do túnel, desativa o CL persistente e retorna à iluminação e ao ambiente usuais do jogo.

**O indicador é uma apresentação visual contínua, não uma operação de rede ou um carregamento real sem fim.** Ele não deve bloquear a interação nem cobrir o cenário com um véu permanente.

## Arquitetura e arquivos

- `src/client/Environments/TunnelGeometry.luau`
- `src/client/Environments/TunnelLighting.luau`
- `src/client/Environments/TunnelCamera.luau`
- `src/client/Environments/TunnelScene.luau`

Esses quatro módulos foram reutilizados do PR #7. **Não** foram copiados `Tunnel.client.luau`, `NoCharacter.server.luau` nem o projeto independente de visualização: evitar dois bootstraps, câmeras e efeitos disputando os mesmos serviços é requisito da integração.

`Scene.luau` passa a aceitar o modo `Tunnel`: instancia a arquitetura local, controla sua câmera com o controlador existente do CL 27 e aplica a iluminação do corredor sem que `TunnelScene` assuma `Workspace.CurrentCamera` ou `Lighting`. O túnel tem distância de névoa 74–168 studs, FOV de 54 graus e câmera fixa. Ao sair, a geometria é destruída e o estado anterior de fog é restaurado. Qualidades: Baixa=238 partes/12 luzes, Média=334/20 e Alta=366/36, sujeitas à plataforma e às opções do jogo.

`App.luau` monta o modo `Tunnel` apenas em Clubs e não desenha a antiga seleção de clubes nem os rodapés nessa rota. A antiga tela de seleção não foi apagada do código, permitindo reaproveitamento futuro, mas não é acessada pelo botão Clubs nesta versão.

`TransitionFX.luau` reutiliza o símbolo existente: durante a transição o CL está no véu de carregamento, e após 2,5 s ele passa para uma camada totalmente transparente, sem bloquear toques. Não são criados símbolos concorrentes.

## Testes e limites

O GitHub Actions verifica sintaxe Luau, módulos e estados de tela, temporização, navegação, entrada e saída da cena, controle de qualidade, limpeza de recursos e compilação Rojo para `.rbxlx`.

Isso **não** comprova fidelidade visual, consumo de bateria ou FPS no Android. Faça a publicação manual, entre em Clubs e confirme a imagem, o indicador persistente, a resposta do botão de voltar e o retorno ao lobby. Teste também em qualidade Baixa.

A integração foi elaborada em `feat/cl27-clubs-cinematic-tunnel-2026-11-03` a partir de um backup intocado `backup/cl27-before-clubs-tunnel-2026-11-03`. A publicação Roblox continua exclusivamente manual.
