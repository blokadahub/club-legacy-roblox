# Análise da referência — 1000159289.jpg

Análise do anexo feita antes da implementação da arquitetura. A imagem foi inspecionada diretamente. Este documento registra estimativas, sem inferir medidas reais ou afirmar correspondência de render Roblox.

## Composição e perspectiva

O arquivo tem 1280 × 562 pixels, com barras pretas laterais. A região útil está aproximadamente entre x=140 e x=1138: cerca de 998 × 562, praticamente 16:9. As barras e os pequenos indicadores de interface não pertencem à arquitetura e não serão recriados.

As bases verdes convergem aproximadamente em x=740–760 / y=320–335. Outras linhas superiores sugerem x=720–760 / y=270–310; a referência contém elementos inclinados e não permite um único ajuste exato de perspectiva. O ponto focal percebido fica à direita do centro, aproximadamente 60% da largura útil. A abertura ocupa aproximadamente x=680–835 / y=210–343, com topo assimétrico e sombra do lintel.

O observador está baixo em relação ao teto, com grande área de piso no primeiro plano. A câmera parece próxima à altura dos olhos, discretamente orientada para cima. A referência admite várias combinações de escala, lente e profundidade; escolheu-se uma lente vertical de 54°, sem distorção artificial ou inclinação lateral.

## Proporções adotadas

| Parâmetro | Estimativa utilizada |
| --- | --- |
| Largura na base | 34 studs |
| Altura | 20,5 studs |
| Comprimento arquitetônico | 96 studs, z=8 até z=-88 |
| Relação largura : altura : comprimento | 1 : 0,60 : 2,82 |
| Inclinação das paredes | 8° para dentro, topo aproximadamente 2,9 studs mais estreito por lado |
| Modulação longitudinal | Oito vãos de 12 studs |
| Portal distante | z=-88,5; vão livre aproximado de 27,4 × 18,9 studs |
| Câmara de fundo | Até z=-115, com maior altura e luz indireta |
| Olho | (0; 5,2; 8), centralizado transversalmente |
| Alvo | (-16; 10; -112), orientação suave à esquerda e para cima |

A orientação desloca a convergência para a direita sem deslocar fisicamente o observador. Para 16:9, a reprojeção analítica do eixo longitudinal fica aproximadamente em x=57,4% / y=53,9%. O portal tem seu centro inferior próximo de x=57,4% / y=59,2%. Isso é uma aproximação deliberada: a referência tem convergência percebida um pouco mais à direita e abertura mais irregular. O ajuste definitivo depende da captura real no Studio. Para uma composição perfeitamente simétrica, alterar somente `CameraTarget[1]` para zero e recompilar.

## Arquitetura por região

**Esquerda:** planos grandes azul-marinho, quase pretos; diagonais espessas atravessam os vãos. A divisão dos painéis é triangular, com juntas horizontais discretas. Uma fita azul fina acompanha o encontro superior; a faixa verde inferior fica num rebaixo separado do piso. O núcleo neon é estreito e não deve iluminar toda a parede.

**Direita:** mesmo sistema estrutural com valores ferruginosos e vermelhos escuros. O teto lateral recebe uma sequência regular de retângulos âmbar alongados no sentido da profundidade. A parede alterna planos opacos, nervuras e aberturas de ventilação estreitas. Os pontos laranja próximos ao fundo são pequenos e baixos, distintos das luminárias superiores.

**Teto:** não é uma laje lisa iluminada uniformemente. Há duas faixas laterais inclinadas, travessas transversais e um vazio técnico central muito escuro. Nenhuma grade luminosa simétrica será acrescentada. A forma do portal também recorta a luz distante.

**Piso:** amplo, escuro, com variação sutil de tonalidade e juntas visíveis em perspectiva. A referência apresenta manchas de luz azul, verde e laranja muito suaves. Usam-se placas de metal escuro com `Reflectance=0.035` e iluminação real de alcance limitado. O Roblox não oferece aqui reflexos planares exatos das fitas; não há duplicatas neon sobre o piso ou simulação de espelho.

**Fundo:** o foco é uma abertura iluminada, com recuo físico e uma linha baixa verde amortecida. A névoa azul-esverdeada aumenta com a distância. Optou-se por `FogStart=74` / `FogEnd=168`: `Atmosphere` global suprimiria esses controles e poderia lavar as paredes próximas. Não se usa plano transparente empilhado, fumaça animada ou partículas pesadas. A ausência de turbulência volumétrica é uma limitação visual explícita.

## Valores e atmosfera

Sombras profundas devem dominar o primeiro plano. Azul intenso restrito ao alto esquerdo, verde nas duas bases, âmbar no alto direito e em pequenos marcadores distantes. O centro do piso não deve ficar luminoso ou saturado. O brilho usa Bloom de intensidade 0,12 e limiar 1,15, sem SunRays ou DepthOfField. O fundo tem uma lavagem turquesa orientada para baixo; o horizonte verde ilumina em direção à câmera, sem fechar o portal com um painel neon inteiro.

O anexo continua sendo a referência visual original. Não foi produzido ou apresentado um render alternativo como evidência do resultado Roblox.
