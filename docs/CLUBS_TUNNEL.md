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

`Scene.luau` aceita o modo `Tunnel`: instancia a arquitetura local, controla sua câmera com o controlador existente do CL 27 e aplica a iluminação do corredor sem que `TunnelScene` assuma `Workspace.CurrentCamera` ou `Lighting`. O túnel mantém FOV de 54 graus e câmera fixa. Ao sair, geometria, emissores, resposta do piso e partículas são destruídos; a atmosfera e a névoa do controlador principal são restauradas. A calibração de iluminação abaixo foi feita sobre a arquitetura existente, sem alterar seus descritores nem a câmera.

`App.luau` monta o modo `Tunnel` apenas em Clubs e não desenha a antiga seleção de clubes nem os rodapés nessa rota. A antiga tela de seleção não foi apagada do código, permitindo reaproveitamento futuro, mas não é acessada pelo botão Clubs nesta versão.

`TransitionFX.luau` reutiliza o símbolo existente: durante a transição o CL está no véu de carregamento, e após 2,5 s ele passa para uma camada totalmente transparente, sem bloquear toques. Não são criados símbolos concorrentes.

## Testes e limites

O GitHub Actions verifica sintaxe Luau, módulos e estados de tela, temporização, navegação, entrada e saída da cena, controle de qualidade, limpeza de recursos e compilação Rojo para `.rbxlx`.

Isso **não** comprova fidelidade visual, consumo de bateria ou FPS no Android. Baixe o artefato de compilação, abra o `.rbxlx` no Studio, dê **Play**, entre em Clubs e confirme a imagem, o indicador persistente, a resposta do botão de voltar e o retorno ao lobby. Não é necessário publicar para testar no Studio. Teste também em qualidade Baixa.

A integração foi elaborada em `feat/cl27-clubs-cinematic-tunnel-2026-11-03` a partir de um backup intocado `backup/cl27-before-clubs-tunnel-2026-11-03`. A publicação Roblox continua exclusivamente manual.

## Correção de iluminação, resposta dos materiais e névoa — 03/11/2026

Base desta correção: `main` em `3ba99ace613431c18753cdcb44803bcea69ceeea`, preservada em `backup/pre-tunnel-lighting-20261103-3ba99ac`. Trabalho em `fix/tunnel-lighting-reflections-fog`, sem merge ou publicação automática. O experimento original do PR #7 continua separado; esta correção atinge os módulos efetivamente usados por Clubs na versão atual do jogo.

### Diagnóstico das duas imagens

Na captura `1000159291.jpg`, o núcleo dos neons é legível, mas o piso central está praticamente preto e as estruturas laterais perdem definição. Na inspiração `1000159289.jpg`, a área arquitetônica útil exclui as barras pretas laterais (aproximadamente x=140–1138); existem faixas suaves de luz refletida e uma massa atmosférica ao fundo. A posição da câmera e a arquitetura foram preservadas conforme solicitado, mesmo havendo diferenças de composição entre as imagens.

Uma amostra normalizada do piso (x=25–75%, y=70–90% da área útil), sem os indicadores inferiores, deu **97,6%** dos pixels da captura atual com luminância aproximada ≤2/255; na referência, **58,1%**. O percentil 90 foi 0,14/255 e 18,36/255, respectivamente. É uma análise dos anexos recebidos, não uma medição do resultado novo nem fotometria física.

Problemas encontrados no código:

- Ambient `(8,11,20)`, exposição `-0.32` e emissores fracos deixavam poucos valores visíveis nos materiais escuros.
- O passe genérico de qualidade de `Scene:ApplySettings` desligava todos os PointLight em Baixa. Também substituía seus alcances por um fallback de 12 studs, mesmo quando o módulo do túnel solicitava outro valor. A falha em Baixa foi reproduzida no harness antes da correção.
- O `Atmosphere` do controlador permanecia em Lighting com densidade zero. A presença desse objeto interfere na névoa clássica por distância; apenas zerar Density não é uma estratégia suficiente.
- A versão integrada não tinha névoa localizada. O material Neon, sozinho, não fornece reflexão dinâmica no piso ou luz adequada nas peças adjacentes.

### Iluminação e resposta das superfícies

`TunnelLighting.Environment` centraliza os parâmetros tanto da integração quanto da posse opcional de iluminação. Após o retorno visual de que o PR #9 estava claro demais, a calibração passou a Ambient `(34,36,40)`, OutdoorAmbient `(23,25,29)`, Brightness `1.0` e ExposureCompensation `0.02`, mantendo EnvironmentDiffuseScale `0.38` e EnvironmentSpecularScale `0.48`. O ajuste é exclusivo do modo Tunnel; a iluminação dos demais ambientes mantém seus parâmetros anteriores.

Todos os 16 segmentos verdes passam a ter luz real de curto alcance (10 studs), inclusive em Baixa. Azul superior: Brightness 1,65 / Range 17; luminárias âmbar: 2,1 / 26; marcadores distantes: 0,65 / 9. Quatro fontes de preenchimento neutro, sem sombras, usam Attachments nos travessões existentes, deslocadas 5,5 studs abaixo deles para representar luz rebatida sobre o piso e as estruturas; sua intensidade foi reduzida de 1,6 para 1,3. A fonte neutra sob o teto da câmara distante passou de 0,9 para 0,75. As cores e luzes dos neons permanecem como na correção anterior. O emissor antigo do horizonte, orientado em direção à entrada, foi retirado; sua peça e o núcleo Neon original permanecem intactos.

Os emissores têm o atributo `CL27TunnelLight`; o passe genérico do jogo os preserva. Somente duas luminárias âmbar usam sombras locais em Alta. Nenhuma fonte é animada e nenhum loop de atualização foi acrescentado.

O metal mantém material e cor, recebendo acabamento discreto: Reflectance mínimo 0,025 nas estruturas metálicas e 0,06 no piso. As peças, posições e dimensões originais continuam iguais. Como o Roblox não produz reflexões planares dessas fitas neste caminho de renderização, há um **complemento gráfico aproximado**: 24 SurfaceGui no Top das próprias placas laterais do piso, com uma faixa verde de transparência mínima 92–96%, UIGradient e queda lateral de 3,2 studs. O pico fica alinhado a x=±16,03, acompanhando a posição das fontes; não há novas placas refletoras, cópias do túnel, manchas circulares ou UI sobreposta à câmera. AlwaysOnTop=false e LightInfluence=1 mantêm o efeito sujeito à profundidade e à luz do ambiente. Não é ray tracing nem reflexão dinâmica fisicamente exata; o brilho local real é a contribuição principal.

Bloom: intensidade 0,09, Size 18 e Threshold 1,2, desativado em Baixa. Contraste 0,035, saturação -0,04 e tint neutro suave. Sem desfoque ou aumento forte de contraste.

### Névoa cinzenta localizada e não emissiva

O `Atmosphere` criado pelo controlador principal é temporariamente retirado de Lighting durante o túnel e recolocado ao sair. A névoa por distância usa cinza `(52,54,57)`, FogStart 68 e FogEnd 156. Essa base estática ficou mais discreta para não encobrir a animação localizada, preservando profundidade mesmo se o dispositivo reduzir partículas.

Além desse apoio por distância, quatro/seis ParticleEmitter ficam em Attachments da peça de fundo já existente, em z=-78, -92 e -106 (Baixa usa somente a primeira e a última camada). Usam a textura nativa `rbxasset://textures/particles/smoke_main.dds`, bordas transparentes, cor cinzenta, LightEmission=0 e LightInfluence=1. A névoa não tem luzes próprias, painéis sólidos ou material Neon.

A animação foi reforçada após o relato de aparência parada: Speed passou de 0,08–0,16 para **0,65–1,05 studs/s**, com correntes da esquerda e da direita dirigidas para o centro, pequena dispersão, Drag 0,1 e leve ascensão. A rotação tem sentidos opostos e magnitude de **2–4°/s**, em lugar de ±0,3°/s. TimeScale=1 mantém a simulação ativa. Lifetime passou de 22–26 para **14–18 segundos**, com billboards de 12–18 studs e fade suave. As taxas Low/Medium/High foram ajustadas para 0,12/0,24/0,32 por segundo; a renovação é mais frequente, mantendo o mesmo limite conservador de partículas vivas. Duas partículas iniciais por emissor iniciam o preenchimento sob a transição de 2,5 segundos. Nenhum script acompanha a câmera ou atualiza partículas por frame.

| Qualidade | Peças, inalteradas | Luzes locais | Luzes com sombras | Emissores de névoa | Limite conservador de partículas vivas* |
| --- | ---: | ---: | ---: | ---: | ---: |
| Baixa | 238 | 28 | 0 | 4 | 20 |
| Média | 334 | 32 | 0 | 6 | 42 |
| Alta | 366 | 40 | 2 | 6 | 48 |

*Soma de `ceil(Rate × Lifetime.Max) + 2` por emissor, incluindo o burst inicial. A quantidade instantânea costuma ser menor; não é medição de custo gráfico. São 24 respostas de piso em cada perfil e nenhuma parte 3D extra. As luzes e a névoa permanecem configuradas em Baixa; a visibilidade final ainda depende do renderizador e deve ser conferida no aparelho.

### Evidências e inspeção final

- Luau 0.745: 38 fontes aprovadas; Rojo 7.7.1: `.rbxlx` gerado e validado com as 38 fontes idênticas.
- Testes existentes: 653 verificações de dados; 519 montagens, 381 callbacks e 240 asserções do harness de interfaces.
- Teste ampliado dos estados reais: 5.847 asserções, incluindo os três perfis, preservação de todas as peças/cores/materiais/posições, limites de emissores/sombras/partículas, luzes ligadas em Baixa, alcance preservado, toggles, qualidade repetida sem duplicação e destruição de luzes/névoa/resposta do piso ao sair.
- Catálogo API: 390 referências estáticas sem erros; propriedades novas e métodos Emit/Clear conferidos quanto à existência e escrita/chamada pública. Snapshot SHA256 `909dc58a41c7d514447a58a4d4185c953b37b7199c075413fc148dbaff9f2681`.
- `TunnelGeometry.luau`, `TunnelCamera.luau`, App, HUDs, controles, trilha sonora e mapeamento Rojo principal preservados. `Scene.luau` mudou somente a configuração de iluminação/névoa do túnel e a proteção dos emissores.

**Não há Roblox Studio ou Player neste ambiente. Não foi possível produzir uma captura nova, aprovar a igualdade com a imagem 2, testar shaders por nível gráfico ou medir FPS no Android.** Os testes acima executam Luau real com doubles de API e não comprovam a aparência do resultado.

Inspeção necessária no Studio:

1. Baixar `club-legacy-rbxlx` da execução aprovada do workflow de build desta branch, abrir o `.rbxlx`, dar Play e entrar em Clubs pelo fluxo existente.
2. Comparar a imagem parada em 16:9 após o carregamento e após 30 segundos. Conferir piso, painéis, vigas e teto sem aumentar o brilho do monitor para compensar.
3. Testar qualidades Baixa/Média/Alta do CL 27 e níveis gráficos nativos manuais 1/5/10. No Android, registrar aparelho, resolução, nível gráfico, memória e MicroProfiler. Somente essas medições podem orientar uma afirmação de desempenho.
4. Conferir se a névoa continua cinza, sem brilho próprio, retângulos ou popping. Para inspecionar paralaxe, usar navegação de câmera do Studio em uma sessão de teste local; a câmera do produto não foi alterada.
5. Se o piso estiver claro demais, reduzir primeiro o pico da resposta complementar em `profiles.reflection` (aproximar de 1) ou desativá-la para comparar; se estiver preto, conferir que os emissores marcados continuam Enabled antes de ajustar exposição. Se a névoa estiver opaca, aproximar `profiles.fogPeak` de 1 e diminuir fogRate. Se não aparecer, verificar Output, o parent do Atmosphere e a textura nativa antes de aumentar densidade.
6. Sair de Clubs, conferir iluminação normal e ausência de emissores residuais; voltar ao túnel e verificar que a contagem não aumenta. Recompilar depois dos ajustes nas fontes.

### Ajuste após o retorno visual do PR #9

Base `498da656c0d0083d0c31388ac2b8c1e43ce4edcd`, backup `backup/pre-tunnel-dimmer-motion-20261103-498da65`; branch `fix/tunnel-dimmer-moving-fog`. A atualização reduz a exposição, o ambiente e o preenchimento neutro, mantém os neons e reforça somente a animação da névoa. Geometria, câmera e demais sistemas permanecem idênticos à base.

Os testes de estados agora verificam correntes dirigidas para dentro, TimeScale positivo, velocidade/rotação suficientes para evitar a calibração quase parada, renovação limitada e preservação dos tetos de 20/42/48 partículas nos três perfis. São **5.907 asserções** aprovadas com doubles de API; isso não prova a aparência do movimento no motor. Na próxima inspeção real, observar de 3 a 10 segundos após o carregamento e comparar o deslocamento dos detalhes da fumaça com a câmera fixa. Studio/Player e medições em Android continuam indisponíveis neste ambiente.
