# Revisão de boas-vindas — três etapas

Registro histórico do PR #14. A pedido do usuário em 05/11, o contorno reforçado descrito abaixo foi desfeito: `OuterGlowSweep.luau` voltou integralmente à versão anterior, com núcleo/halos de 2,25/8,4/16 unidades do canvas e as cores/opacidades originais. O layout fino e a paleta #5cff33 continuam. Estado atual em [CINEMATIC_INTRO.md](CINEMATIC_INTRO.md).

Base: `d871018c94f975210de626ea2805ff52eec69045`, após o merge do PR #13.
Referência: imagem recebida de 1536×863. Fonte: canvas nativo Roblox 1600×900.

## Etapa 1 — verificar erros

1. A altura mínima de toque de 48 px era aplicada diretamente ao preenchimento verde. Com UIScale em celular, o desenho ficava desproporcionalmente grosso. O botão passa a ter raiz transparente e `SuperficieCapsula` independente: toque mínimo 112×48 px; superfície mínima 104×30 px.
2. O contorno tinha espessura nas unidades do canvas, portanto encolhia fisicamente junto com a tela. Núcleo e halos agora usam espessura constante em pixels: 2,4 / 9,6 / 20 px. A trajetória fica 0,6 px para fora da superfície verde, aumentando o trecho visível contra o fundo escuro. Opacidades e tons foram reforçados apenas nas cápsulas; o indicador CL mantém seu acabamento anterior.
3. O ajuste de toda a abertura descontava a barra superior e margens, encolhendo e deslocando as boas-vindas. Um canvas específico preserva a composição central em relação ao viewport inteiro; recuos horizontais continuam respeitados. As fases anteriores conservam o ajuste original.
4. As cores estavam duplicadas. `Theme.actionGreen` centraliza `#5cff33` e `actionHover` sua variação de interação. Cápsulas, X e demais CTAs primários usam essa paleta. Ações primárias deixam de aplicar transparência padrão de 52%, que apagava o verde.
5. Tweens de hover podiam competir com a troca de seção. Agora são cancelados antes de aplicar a cor da nova seção e no descarte; ações desativadas continuam cinzentas.

## Etapa 2 — medir e reconstruir a referência

Inspeção visual acompanhada de segmentação dos pixels verdes da imagem recebida. Coordenadas aproximadas da região visível, incluindo suavização/compressão:

| Região | Referência 1536×863 | Aplicação no canvas 1600×900 |
| --- | --- | --- |
| Marca superior | centro próximo de (768, 198) | marca própria CL Sports/CL 27 em (800, 207), escala 0,25 |
| WELCOME | x466–1069, y306–372; centro y339 | linha em y300, caixa de 112, centro y356 |
| TO THE CLUB | x390–1145, y402–468; centro y435 | segunda linha 100 unidades abaixo, centro y456 |
| Start | verde x703–835, y557–609; centro y583 | centro (800, 608), superfície de referência 146×52 |
| Rodapé | abaixo do botão, aproximadamente y664–724 | crédito próprio em y690 e apoio a seguir, sem colidir com o toque |
| Facetas | junção esquerda perto de 58% da altura; diagonal direita perto de 74% da largura superior | vértices revistos; sete facetas / 14 WedgeParts mantidos |

Tipografia pesada nativa, duas linhas, verde do título separado da cor dos botões e capitalização `Start` como na imagem. O círculo X foi reduzido em relação ao desenho anterior; rótulo de pelo menos 14 px físicos. O rodapé tem mínimo de 9 px e espaço próprio. Tons do fundo levemente quentes e contrastes de cada faceta substituem o cinza uniforme.

Não se promete uma cópia tipográfica exata: a família proprietária da referência não foi fornecida. `Enum.Font.GothamBlack` é mantido por compatibilidade e mapeia para Montserrat conforme a [referência oficial de Font](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/Font.yaml). Uma fonte Montserrat pública foi usada apenas para conferir medidas aproximadas offline; nenhum arquivo de fonte foi incorporado ao jogo. Medidas offline não certificam rasterização Roblox.

## Etapa 3 — revisar erros e acabamento

A imagem foi reaberta após a implementação para revisar novamente hierarquia, posição dos textos, escala da marca, cápsula, espaçamento e diagonais. A comparação executada é de referência e código, não de uma captura nova do jogo.

- Teste de centros contra as medidas da imagem: marca, duas linhas e Start dentro de tolerância de 3 px na composição de referência.
- Seis resoluções: 1536×863, 1920×1080, 854×393, 1024×768, 2560×1080 e 393×854. Verificados proporção fina, toque, legenda/X, rodapé, movimento reduzido e descarte.
- Regressão com inset superior de 58 px: a composição não encolhe nem se desloca novamente por causa da barra.
- Cada amostra da varredura é conferida em pixels físicos. Testes exigem espessura estável, percurso completo por fora da superfície e apenas uma faixa curta acesa em movimento, não um contorno inteiro piscando.
- O efeito conserva 78 amostras e ciclo de 4,8 s. Nenhum loop, callback, luz, partícula, som ou dependência externa adicional foi criado.
- Cor exata, hover/retorno, opacidade dos CTAs primários e ausência de recoloração tardia em ação desativada cobertos por testes.
- Inicialização em Notícias do CL, prontidão, tentativa após erro, foco, linha do tempo e liberação de música permanecem cobertos pela suíte existente.

### Verificação executada

- Luau 0.745: 43 fontes aprovadas.
- Dados: 653 verificações.
- Smoke: 519 montagens / 381 callbacks / 240 asserções.
- Estados: 5.915 asserções; abertura: 2.003 asserções, incluindo altura de caixa suficiente para o título.
- Rojo 7.7.1: XML válido, 43 fontes incorporadas sem alteração.
- `git diff --check`: aprovado.

Avisos nos cenários negativos de áudio/cenário são esperados. Os testes usam APIs substituídas. Studio/Player não estão disponíveis: ainda é necessário verificar rasterização tipográfica, intensidade do halo, interação real e desempenho no aparelho. Não houve nova publicação Roblox nesta revisão.
