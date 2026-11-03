# Etapa 1 — auditoria de fidelidade e composição

Executada em 03/11/2026, após a integração das telas e antes das auditorias 2 e 3.

## Evidência e alcance

- As cinco referências foram reabertas individualmente com `view_image` nesta etapa, além da leitura inicial registrada em `REFERENCE_ANALYSIS.md`.
- Foram examinados `App.luau`, `UI.luau`, `Theme.luau`, `Scene.luau`, `Rig.luau`, `Home.luau`, `Squad.luau`, `Pitch.luau`, `Tactics.luau`, `Assignments.luau`, `Clubs.luau`, `Kits.luau` e as coordenadas/componentes das oito telas complementares.
- A comparação abaixo verifica composição implementada, proporções numéricas, hierarquia e enquadramento calculado. Não houve execução no Roblox Studio/Player, renderização de interfaces, captura de quadros ou medição de FPS.
- Portanto, a auditoria visual por capturas reais permanece pendente. Este documento não certifica identidade visual idêntica, acabamento AAA observado ou ausência de sobreposição em runtime.

## Comparação por referência

### 1. Menu interno

| Região | Referência | Implementação e verificação |
| --- | --- | --- |
| Superior/esquerda | Marca pequena, trilho de ícones e menu textual no primeiro quarto. | Marca em `(45,42)`; trilho em `(40,153)`; menu em `x112`, largura340, passos63. Em 1600×900: menu começa em7% e termina em28,25%. Próximo da região de 8–29% observada, sem grandes cartões. |
| Centro | Contexto a partir de≈29% da largura; ação inferior central. | Conteúdo em `x480/482` (30%); título386, descrição487 e ação619 (68,8% da altura). Margem entre menu e contexto≈28 px. |
| Fundo | Telão aproximadamente x27–88%, y18–60%, arquitetura e teto visíveis. | Encontrado telão inicialmente excessivo: reprojeção x20–105%, y6,5–58,3%, com corte direito e invasão do teto. Corrigido por redução e reposicionamento do modelo; resultado calculado abaixo. |
| Direita/3D | Atleta inteiro, topo≈23%, pés≈77%, presença física no piso. | Cena Workspace, piso Marble, juntas, moldura no chão, paredes, vigas, diagonais e luzes. R15 original em pose Presentation. Câmera corrigida para topo≈24,2%, pés≈75,5% por estimativa. |
| Inferior | Botão claro/turquesa e comandos discretos. | Ação retangular282×56 em 482/619; rodapé 839–900. Há separação espacial entre ação e rodapé. |

Diferenças preservadas conscientemente: identidade CL27 original; telão azul/esmeralda, sem emblema/fotografia oficial; personagem Roblox estilizado e pose própria. Materiais, sombras, reflexão, legibilidade final e silhueta articulada ainda precisam de captura real.

### 2. Centro de treinamento

| Região | Referência | Implementação e verificação |
| --- | --- | --- |
| Superior/centro | Um bloco contextual no terço superior, deixando cenário aberto. | Encontrados dois títulos e duas descrições entre y143 e415. Corrigido para um título dinâmico em 149–219 e descrição 227–293, com identificação compacta em 120. Área entre 293 e 619 permanece livre de texto central. |
| Esquerda | Mesmo menu textual do interior. | Home compartilhado; posições do menu e trilho idênticas entre ambientes. |
| Direita/3D | Atleta inteiro, pose em pé, topo≈22%, pés≈75%. | Atleta separado em posição 5.1/2.81/0 e pose Standing; reprojeção final topo≈24,1%, pés≈75,2%, centro x≈77,5%. |
| Fundo | Céu, edifício amplo à esquerda, centro esportivo à direita, gramado em perspectiva. | Cena Training própria com sede curva segmentada, vidro, marquises, centro de desempenho, mastros, árvores, postes, campo e gol decorativo. ClockTime14.25 e iluminação diurna distinta do interior. |
| Inferior | Gramado amplo e poucos elementos. | Botão de ação compartilhado e troca de ambiente no inferior central. Número do ambiente corrigido de 01/02 para 02/02. |

Diferenças remanescentes: não foi validada a porcentagem real de céu/edifícios/gramado nem a aparência do céu nativo. A densidade arquitetônica e o contraste do texto sobre céu claro precisam de revisão em Studio. Foi aplicado contorno de texto discreto no título/descrição para ajudar a leitura, sem criar painel opaco.

### 3. Elenco, táticas e atribuições

| Região | Referência | Implementação e verificação |
| --- | --- | --- |
| Superior | Marca compacta, módulo e três abas horizontais. | Header comum, abas Elenco/Táticas/Atribuições, linha divisória em 105. |
| Campo | Aproximadamente52% da largura, trapézio e onze cartões. | Campo `(72,145,825,366)`:51,56% da largura e40,67% da altura. Projeção compartilhada entre 48 faixas, linhas e cartões; estreitamento superior 13% por lado. |
| Banco | Abaixo do campo, mesma largura, duas linhas compactas. | Banco `(72,563,825,251)`, rolagem 785×191; seis cartões por linha, 112×95, passo 127×103. A segunda linha pode exigir rolagem parcial, conforme altura disponível. |
| Direita | Ficha ocupa aproximadamente36%, com retrato, status e atributos. | Ficha `(945,137,592,677)`:37% da largura; folga 48px entre campo e ficha. Retrato, overall, forma/moral/condição, seis atributos, dados pessoais, técnica, estilos e paginação distribuídos horizontal/verticalmente. |
| Seleção | Atualização imediata do jogador. | Callback atualiza state.selectedPlayer, bordas de todos os cartões e reconstrói somente o corpo da ficha. A geometria principal não muda. |

Verificação de sobreposição por código: cartões titulares usam altura limitada pela menor distância entre linhas da formação; goleiro e atacantes ficam dentro da região campo; banco termina em 814, 25px antes do rodapé 839. Táticas mantém campo 827×425 à esquerda e controles 574px à direita; Atribuições usa responsabilidades, retrato e lista em três regiões.

Diferenças remanescentes: as posições representam formações próprias e não copiam a distribuição exata dos atletas da fotografia; retratos são modelos originais renderizados em ViewportFrame. A definição dos retratos pequenos, truncamento de nomes, leitura de textos 10 px e composição em resoluções menores exigem inspeção visual real.

### 4. Transição e uniformes

| Região | Referência | Implementação e verificação |
| --- | --- | --- |
| Identidade | Azul/esmeralda/turquesa, faixas diagonais e marca branca. | CanvasGroup de transição com UIGradient, quatro faixas rotacionadas −27°, linha fina e marca CL 27. A transição é separada da tela de uniformes. |
| Laterais/3D | Dois atletas inteiros nas extremidades, palco escuro. | Cena Kits Workspace com dois atletas e piso; centros calculados≈16% e84%, topo≈23,6%, pés≈76,5%. Rótulos verticais nas bordas. |
| Centro | Uniformes isolados entre os atletas, escolha e confirmação. | Duas regiões começam em490 e850; ViewportFrames de215 × 304 para conjunto selecionado e112 × 177 para alternativa. Setas, nome, indicadores e confirmação independentes. |
| Inferior | Comandos compactos; sem partida. | Retorno aos clubes e apresentação visual; nenhum sistema de partida. Atualização de cores aplicada aos modelos da cena. |

Limitação: a referência 4 é uma montagem quadrada com duas telas e recortes laterais, não um layout único. Não há base para inferir sua animação ou medidas exatas. A aparência dos uniformes geométricos e a integração dos atletas no palco só poderão ser julgadas em render real.

### 5. Seleção de clubes

| Região | Referência | Implementação e verificação |
| --- | --- | --- |
| Superior | Cabeçalho compacto, filtros de país/competição. | Header comum e filtros em 139/187/229, simétricos nos dois lados. |
| Laterais | Painéis aproximadamente x14–40% e60–87%, títulos verticais. | Mandante x220/1600=13,75%; visitante x955/1600=59,69%; ambos 425px=26,56%. Limites40,31% e86,25%. Títulos verticais externos. |
| Centro | Eixo livre com comandos discretos. | Intervalo 310px entre painéis (19,38% da tela); marca, VS, comparação e avanço aos uniformes nessa região. |
| Conteúdo | Nome, escudo, setas, estrelas, ATA/MEI/DEF e competição simultâneos. | Painéis 425×415 em y275; escudo 174px; atributos em três colunas; competição abaixo em 705–780. Contorno turquesa fino no lado ativo. |
| Fundo/profundidade | Arena escura, piso e reflexos reconhecíveis. | Encontrado backdropUI com 85% de opacidade, que ocultava quase toda a cenaWorkspace. Corrigido em Clubs para 28% de opacidade (`BackgroundTransparency=.72`); gestão conserva fundo mais opaco para leitura. |

Diferenças remanescentes: escudos geométricos são originais e não correspondem a marcas oficiais; os filtros usam clubes/competições fictícios. Reflexos, transparências compostas e equilíbrio de brilho precisam de captura real.

## Reprojeção analítica das correções de câmera e telão

Foi usado modelo pinhole com aspecto 16:9, base 1600×900, vertical FOV34°, `CFrame.lookAt`, topo nominal do rig em Y5.33 e pés em Y0. A transformação considera base da câmera e profundidade; não executa Roblox nem inclui a caixa articulada completa da pose, o movimento de respiração ou recortes de área segura.

| Cena | Centro horizontal nominal | Topo nominal | Pés nominais |
| --- | --- | --- | --- |
| Interior final | 78,45–79,10% | 24,19% | 75,50% |
| Training final | 77,35–77,78% | 24,08% | 75,23% |
| Kits esquerdo final | 15,51–16,19% | 23,59% | 76,54% |
| Kits direito final | 83,81–84,49% | 23,59% | 76,54% |

Antes da correção, o topo nominal dos atletas ficava em≈30–31% e os pés em≈78–80%. Foram ajustados o alvo Y2.6, FOV34 e posições X5.3/5.1/±6.1, aproximando a presença e altura das referências.

Telão final: moldura 15.7×6.5 no centro `(2.1,3.76,-5.9)`; display 15×5.8 no plano Z−5.65. Cantos projetados calculados: superior esquerdo `(27,82%,17,98%)`, superior direito `(89,44%,17,98%)`, inferior esquerdo `(28,22%,60,04%)`, inferior direito `(88,72%,60,04%)`. O telão deixa de ultrapassar a borda direita e libera o teto na previsão geométrica.

Responsividade geométrica: o agente principal também informou ao gerenciador de cena a altura ajustada do canvas (`900 × UIScale`) e compensou o FOV vertical pela relação entre a altura do viewport e essa altura ajustada: `2 × atan(tan(FOVreferência / 2) × viewportHeight / fittedHeight)`. Isso preserva a escala projetada relativa ao canvas 16:9 em telas com proporções diferentes. É uma correção analítica; não foram testadas visualmente resoluções 4:3 ou ultralargas. O deslocamento produzido por áreas seguras/insets e a seleção de controle ainda precisam de captura real.

## Telas complementares e coerência visual

Visão Geral, Calendário, Transferências, Finanças, Desenvolvimento, Competições, Personalização e Configurações usam o mesmo cabeçalho, rodapé, paleta, botões retos, espaçamentos e limites do canvas. Os layouts distribuem conteúdo por duas ou três regiões, com calendário em grade, tabela de competição, gráfico financeiro e lista/ficha de atletas. Não foram convertidos em uma única coluna. A inspeção de coordenadas não substitui teste de fontes, texto e cortes em runtime.

## Correções concretas desta etapa

1. Consolidado o contexto do menu Training em um único bloco superior, reduzindo ocupação de texto até 415 px para 293 px e liberando 122 px de cenário.
2. Corrigido indicador do segundo ambiente para 02/02.
3. Adicionado contorno discreto ao texto do contexto externo para contraste sobre o céu.
4. Ajustados alvo/FOV/posições dos atletas pelo agente principal após a análise de reprojeção.
5. Reduzido e reposicionado telão interno após identificação de corte lateral e invasão do teto.
6. Reduzida opacidade do fundo UI em Clubs para mostrar a arena real.
7. Compensado o FOV pela altura ajustada do canvas para preservar o enquadramento em proporções diferentes, ainda sem execução visual.

## Verificações executadas e pendências

- `luau-compile src/client/Screens/Home.luau`: aprovado após alteração; bytecode gerado apenas como evidência técnica temporária.
- `python3 tools/validate.py`: aprovado; 25 fontes, 15 rotas, mapeamento Rojo e requires locais. Essa chamada verifica integridade estrutural e não renderiza interfaces.
- Reprojeções numéricas executadas em Python e recalculadas após a alteração final do telão/câmeras.
- Pendente obrigatório em Studio: renderizar as cinco composições correspondentes; comparar imagens por regiões em 16:9; revisar luz, materiais, rostos, fontes, gramado, proporções finais e área segura em resoluções diferentes.
- Pendente: captura real de transições e inspeção de quadros; pertence à etapa 2 quando houver runtime. Nenhuma inspeção quadro a quadro foi realizada nesta etapa.

Etapa 1 encerrada no limite de composição verificável pelo ambiente. A validação visual por capturas continua explicitamente aberta; seguir para a etapa 2 de revisão de animação/estados, registrando sua limitação de execução.
