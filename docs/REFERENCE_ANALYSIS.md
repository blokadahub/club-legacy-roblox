# CL 27 — análise das cinco referências substitutas

Data: 03/11/2026. As cinco imagens anexadas foram abertas individualmente nesta execução. Esta análise usa somente essas referências; a direção anterior não foi reaproveitada.

As porcentagens descrevem posições aproximadas na imagem visível, com origem no canto superior esquerdo. Não são medições de pixels calibradas nem certificação de fidelidade final. O produto utiliza identidade CL 27, clubes, atletas, escudos e uniformes originais; marcas e fotografias das referências não devem ser copiadas.

## Imagem 1 — menu cinematográfico interno

Arquivo: `1-1000159223.jpg`, composição horizontal próxima de 16:9.

| Região | Observação e proporção aproximada | Consequência para implementação |
| --- | --- | --- |
| Superior | Marca em `(2,5%, 4%)`; indicadores discretos no extremo superior direito. Teto amplo e luminárias visíveis. | Marca compacta e branca; não cobrir o teto com uma barra opaca. |
| Esquerda | Trilho de ícones em `x≈3%`; menu textual em `x≈8%`, entre `y≈16–73%`. Uma opção usa branco mais forte e maior peso. | Navegação vertical sem cartões grandes; espaçamento regular; seleção comunicada principalmente por tipografia e linha luminosa. |
| Centro | Telão arquitetônico atrás da composição em `x≈27–88%`, `y≈18–60%`; conteúdo contextual alinhado em `x≈29%`. | Telão precisa existir no cenário e ter moldura/espessura; texto da interface não deve apagar a leitura do espaço. |
| Direita | Atleta em ação ocupa `x≈61–91%`, `y≈23–77%`. Corpo se sobrepõe à região visual do telão. | Personagem R15 deve estar fisicamente diante do telão, com pose esportiva contida e sombra no piso. |
| Inferior | Ação principal em aproximadamente `(29%, 68%)`, largura `≈17%`; comandos pequenos junto à borda inferior. | Botão retangular claro/turquesa e área inferior respirada; rodapé com baixo peso visual. |
| Fundo | Piso ocupa aproximadamente os 40% inferiores. Moldura retangular no chão, diagonais à esquerda, verticais à direita, paredes grafite e faixas claras de luz no piso. | Geometria Workspace, câmera baixa, piso elaborado com reflexão sutil, iluminação indireta e contraste entre materiais claros/escuros. |
| Profundidade | Telão recuado, atleta em plano intermediário e piso avançando até a câmera. | Não substituir por fundo preto, imagem plana ou ViewportFrame de cenário inteiro. |

Critérios para comparação: telão atrás do atleta; pés no piso; menu à esquerda legível sem caixa grande; cenário reconhecível nas regiões superior e inferior; botão abaixo do conteúdo contextual; arquitetura com perspectiva real.

## Imagem 2 — menu no centro de treinamento

Arquivo: `2-1000159222.jpg`, composição horizontal próxima de 16:9.

| Região | Observação e proporção aproximada | Consequência para implementação |
| --- | --- | --- |
| Superior | Marca pequena no mesmo canto; título contextual em `(29%, 14%)`, descrição curta abaixo. Céu claro com nuvens suaves. | Manter navegação compartilhada, com conteúdo em área aberta e tipografia branca esportiva. |
| Esquerda | Menu inicia em `x≈8%`, ocupa cerca de 23% da largura e vai de `y≈16–73%`. Edifício curvo largo atrás. | Poucos painéis; gradiente lateral discreto preserva leitura sem eliminar a arquitetura. |
| Centro | Espaço aberto e mastros; horizonte construído entre `y≈45–64%`. | Construções distantes, árvores e equipamentos esportivos devem fornecer escala e profundidade. |
| Direita | Atleta em pé, corpo inteiro, aproximadamente `x≈70–83%`, `y≈22–75%`; silhueta mais estreita e pose mais estável que na imagem 1. | Câmera e pose próprias do exterior; não reutilizar exatamente o enquadramento interno. |
| Inferior | Gramado amplo, linha de campo em perspectiva e escurecimento gradual junto ao rodapé. | Campo tridimensional com variação de faixas de corte; usar sombra/gradiente com moderação. |
| Fundo | Céu ocupa aproximadamente metade superior. Edifício amplo à esquerda e blocos baixos à direita; iluminação diurna e sombras no gramado. | Cena Workspace separada, luz natural, céu e perspectiva ampla. |
| Profundidade | Gramado próximo, atleta intermediário, construções e árvores recuadas. | A leitura de distância deve vir da geometria, oclusão e câmera. |

Critérios para comparação: mesmo menu da versão interna, mas exterior imediatamente distinguível; céu visível; atleta inteiro à direita; arquitetura esportiva ocupando o horizonte; gramado profundo; nenhum painel convencional dominando o centro.

## Imagem 3 — elenco, táticas e ficha do jogador

Arquivo: `3-1000159221.jpg`, composição horizontal próxima de 16:9. A distribuição horizontal é essencial.

| Região | Observação e proporção aproximada | Consequência para implementação |
| --- | --- | --- |
| Superior | Cabeçalho ocupa aproximadamente 12% da altura; marca compacta, identificação do módulo e três abas horizontais. | Abas Elenco, Táticas e Atribuições com hierarquia por peso/contraste, sem barra grande. |
| Esquerda/centro | Campo entre `x≈5–57%`, `y≈14–56%`. Trapézio com borda superior estreita e inferior larga. | Campo deve ser perspectivado; onze cartões posicionados espacialmente por formação, nunca uma lista. |
| Cartões titulares | Largura aproximada de 6% da tela e altura de 10–11%; retrato, overall no canto superior, nome curto e barra de condição. | Retratos visíveis simultaneamente; contorno fino turquesa no selecionado; nomes devem caber sem sobrepor posições vizinhas. |
| Inferior esquerda | Banco em `x≈5–57%`, `y≈61–92%`; primeira linha com seis cartões, continuação na segunda; rolagem discreta à direita. | Banco compacto, preservando a proporção do campo; área de rolagem com retratos e nomes visíveis. |
| Direita | Ficha em `x≈59–95%`, `y≈14–91%`. Retrato/nome/overall acima; faixa de forma, moral e condição; atributos e dados em duas colunas; símbolos e paginação abaixo. | Ficha persistente e densa, com hierarquia clara. Selecionar titular ou reserva atualiza todos os dados imediatamente. |
| Inferior | Comandos distribuídos horizontalmente em `y≈95%`. | Selecionar, voltar, editar e consultar perfil devem permanecer compactos. |
| Fundo | Azul profundo e esmeralda; diagonais e gradientes suaves. Painéis azul-grafite translúcidos com cantos quase retos. | Evitar cartões arredondados, bordas grossas e sombras grandes; usar transparência com contraste suficiente. |

Critérios para comparação: campo ≈52% da largura, ficha ≈36%, banco abaixo do campo; onze titulares simultâneos; nenhum empilhamento em coluna única; seleção refletida na ficha; atributos legíveis com margens consistentes.

## Imagem 4 — identidade cromática e seleção de uniformes

Arquivo: `4-1000159220.jpg`, montagem quadrada. Não é uma captura única de interface.

### Limitação da fonte

A imagem combina uma tela de identidade na metade superior, uma tela de uniformes na metade inferior e recortes de outras interfaces à direita. A área principal termina em `x≈89%`; os recortes laterais não pertencem ao mesmo layout. Há desfoque e corte de textos. Não é possível deduzir durações, curvas de animação, dimensões exatas ou todos os estados a partir dela. A montagem não deve ser reproduzida como interface quadrada: seus dois temas devem originar telas independentes em 16:9.

| Região/tema | Observação | Consequência para implementação |
| --- | --- | --- |
| Identidade superior | Azul no alto/esquerda; esmeralda/turquesa à direita e embaixo; marca branca central. | Tela de transição própria CL 27, com grande área vazia e marca original. |
| Geometria de identidade | Faixas largas diagonais transparentes, algumas linhas finas luminosas, cruzamentos que sugerem planos. | Camadas de UIGradient e geometrias diagonais suaves; evitar efeitos repetitivos ou excesso de brilho. |
| Uniformes: superior | Cabeçalho compacto alinhado à esquerda. | Navegação curta e coerente com a seleção de clubes. |
| Uniformes: laterais | Personagens inteiros nas extremidades, chão e sombra; rótulos verticais de mandante e visitante. | Cena 3D escura com dois atletas e enquadramento equilibrado; personagem não deve parecer dentro de cartão. |
| Uniformes: centro | Dois conjuntos entre os atletas; camisa selecionada maior, alternativa menor ao lado, setas pequenas e estado de confirmação acima. | ViewportFrame apropriado para camisas isoladas; controles independentes para mandante e visitante. |
| Uniformes: inferior | Piso escuro levemente reflexivo; comandos discretos. | Concluir com confirmação visual da apresentação; não iniciar partida. |
| Luz e cor | Preto/grafite nas bordas; turquesa/verde no fundo e seleção; branco na tipografia. | Contraste por iluminação e planos, sem painéis grandes ocultando atletas. |

Critérios para comparação: transição e seleção são telas separadas; dois atletas inteiros; uniformes ao centro; rótulos laterais; escolha atualiza camisa, calção e detalhes do personagem quando suportado; retorno funcional aos clubes.

## Imagem 5 — seleção profissional de clubes

Arquivo: `5-1000159219.jpg`, composição horizontal próxima de 16:9.

| Região | Observação e proporção aproximada | Consequência para implementação |
| --- | --- | --- |
| Superior | Cabeçalho ocupa cerca de 10% da altura. | Marca pequena, módulo e etapa com espaçamento controlado. |
| Esquerda | Coluna em `x≈14–40%`; filtros em `y≈17–30%`, painel principal em `y≈31–75%`, competição abaixo. | Mandante com filtros, clube e competição em blocos alinhados. |
| Direita | Coluna espelhada em `x≈60–87%`, com mesma altura e proporções. | Visitante equivalente em peso visual, sem painel dominante. |
| Laterais | Títulos verticais junto às bordas e fora dos painéis. | Mandante/visitante ajudam a enquadrar a arena e deixam o centro livre. |
| Centro | Eixo livre de aproximadamente 18% da largura, destinado a comandos/configuração visual. | Avançar para uniformes e controles de seleção em área clara, sem preencher o centro com outro painel grande. |
| Conteúdo dos clubes | Nome no topo; escudo grande central; setas laterais; estrelas perto de `y≈65%`; ataque/meio/defesa em três colunas. | Dados atualizam juntos ao alternar clubes fictícios; escudos originais e paleta própria. |
| Inferior | Competição e símbolo pequeno sob atributos; comandos junto à borda. | Preservar hierarquia do clube e evitar competição maior que o escudo. |
| Fundo/3D | Arena escura, parede cromática curva, piso em perspectiva e reflexos contidos. | Workspace pode fornecer chão e profundidade; interface translúcida permite reconhecer o cenário. |
| Seleção | Contorno fino turquesa e preenchimento discretamente mais claro no lado ativo. | Foco evidente por mouse, toque, teclado e controle; sem borda grossa ou arredondamento excessivo. |

Critérios para comparação: duas colunas estreitas simétricas; eixo central livre; nomes/escudos/estrelas/atributos/competição visíveis ao mesmo tempo; mudança de clube coerente; conexão com uniformes.

## Diretrizes comuns e método de validação

1. Priorizar coordenadas, proporções e silhuetas antes de materiais e efeitos. A referência deve ser reconhecível mesmo em escala de cinza.
2. Usar Workspace com câmera Scriptable nos dois menus e na apresentação dos uniformes. Reservar ViewportFrame para retratos, camisas e componentes isolados.
3. Manter base 16:9, áreas seguras e adaptação proporcional sem empilhar campo, banco e ficha em uma única coluna.
4. Usar azul profundo, grafite, esmeralda, turquesa e branco, com bordas finas e cantos mínimos. Não copiar marcas, fotos, emblemas ou uniformes oficiais.
5. Comparar futuras capturas reais por regiões: superior, esquerda, centro, direita, inferior, fundo e elementos 3D. Verificar espaços vazios e densidade além dos efeitos.
6. A análise acima é estudo de referência, não auditoria final. Sem execução e capturas Roblox reais, não declarar acabamento AAA confirmado, 60 FPS ou inspeção quadro a quadro.
