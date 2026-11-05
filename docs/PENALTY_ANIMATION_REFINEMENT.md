# Refinamento R15 — corrida e seis defesas

## Escopo e estado — 04/11/2026

Correção autorizada após o usuário publicar e testar o PR #16. **Não é a etapa 2.** Bola estática, sem mira/potência, física de cobrança ou inteligência artificial.

- Base: `main` em `4eb70e055d9d2462f7c934f70b2a4298cf90a876`.
- Branch: `fix/cl27-natural-run-save-variants`.
- Implementação: `4bfd7fefb1acdf4605fe9c00939dbcd008daed21`; árvore `351e09982198adbce66f5803241ed0267e8cb6db`, idêntica à testada localmente.
- Pull Request: [#17](https://github.com/blokadahub/club-legacy-roblox/pull/17), aberto e sem merge.
- [CI 41956409033](https://github.com/blokadahub/club-legacy-roblox/actions/runs/41956409033): concluído com sucesso, com testes ampliados e artefato `club-legacy-rbxlx`. Commits posteriores desta entrega registram apenas o fechamento documental; consulte o HEAD no PR.
- Sem merge ou publicação automática.

## Corrida do cobrador

A flexão negativa dos cotovelos do movimento anterior contribuía para projetar os antebraços para trás. Foram corrigidos o sentido da flexão, o momento da preparação e a combinação com os ombros.

- Cotovelos são preparados antes do primeiro passo. Na janela principal da corrida, o fixture amostrado fica entre **79,01° e 90,99°** de flexão procedural, dentro do intervalo solicitado de 70–100°.
- Ombros oscilam com amplitude moderada de 14°, ligados à mesma cadência dos passos e em oposição à perna que avança. Testes usam a derivada temporal dos alvos dos pés, em vez de comparar um frame atrasado na troca de passo.
- A flexão dos cotovelos compensa a oscilação dos ombros, mantendo antebraços à frente e ligeiramente para baixo. Nos quadros auditados, a componente para a frente do antebraço foi pelo menos **0,8304** do vetor unitário; a componente vertical máxima foi **−0,1824**, ainda apontando para baixo.
- Mãos permanecem à frente dos respectivos ombros; pulsos recebem apenas pequenos ajustes. Não foi adicionada pose de punho fechado nem alterada a geometria das mãos do avatar.
- A preparação do chute abre progressivamente o braço esquerdo para equilíbrio; o direito acompanha a rotação. As poses são assimétricas e misturam-se à recuperação e à espera, sem substituir a corrida inteira por uma rotação fixa.

Esses valores descrevem o fixture e as transformações do teste; não são medições do avatar real dentro do motor Roblox.

## Catálogo de defesas

As durações abaixo são da coreografia base. O ajuste de ritmo já existente considera o tamanho das pernas do avatar.

| Comando | Duração base | Sequência corporal |
| --- | --- | --- |
| `LowLeft` — Rasteira ← | 4,15 s | Colapso lateral baixo, mãos apontadas à região inferior, perna próxima recolhida, aterrissagem de lado e recuperação com apoio do joelho |
| `LowRight` — Rasteira → | 4,05 s | Agachamento mais profundo, movimento de recolha com duas mãos, outro padrão de flexão das pernas e recuperação apoiada à frente |
| `MidSave` — Meia altura | 4,55 s | Impulso horizontal, dois braços projetados para a faixa média, pernas em tesoura, aterrissagem lateral e retomada |
| `HighSave` — Defesa alta | 3,75 s | Carga vertical, salto diagonal e alcance superior com um braço dominante, segundo braço em apoio, aterrissagem flexionada e retorno mais ereto |
| `CentralSave` — Defesa central | 1,65 s | Reação curta junto ao centro, joelhos flexionados, mãos em uma região de recepção à frente e absorção junto ao corpo; sem mergulho ou fase aérea |
| `ShuffleSave` — Passo + mergulho | 5,10 s | Dois apoios laterais prévios, novo impulso, mergulho diagonal com braço dominante e retorno com passos de reposicionamento |

Cada defesa tem seus próprios tempos, poses de ombros/cotovelos/pulsos, trajetória de raiz, pernas e recuperação. Compartilham somente interpolação, estado de prontidão e o mecanismo de apoio/retorno. Não são seis cópias da mesma trajetória com direção/velocidade alteradas. Os nomes antigos `DiveLeft` e `DiveRight` continuam como aliases internos das duas rasteiras, sem criar novas rotas.

A liberação do apoio por IK passa a ter peso contínuo durante impulso e aterrissagem. Isso evita a troca instantânea entre pernas plantadas e pose de voo. O alcance é limitado ao comprimento real da cadeia óssea, sem esticar articulações. C0/C1, acessórios, roupas e proporções não são alterados.

## Controles temporários

A faixa de prévias usa uma única linha de **48 px** no canto inferior direito, com largura de **296–334 px** conforme a tela. Os quatro alvos têm: Chute/Ver chute, defesa anterior, executar a defesa selecionada e defesa seguinte. As setas têm 44×48 px; o seletor mostra número, total e nome, por exemplo `1/6 Rasteira ←`.

As setas percorrem as seis defesas e dão a volta ao catálogo. Clicar no nome executa somente a defesa selecionada. A faixa permite avaliar todos os movimentos sem empilhar seis botões sobre o gramado. Em 320, 640 e 960 px de largura, os testes verificam que ela cabe com margem. Seleção por controle recebe vínculos explícitos entre os quatro comandos.

Durante uma prévia, os comandos de execução ficam temporariamente indisponíveis para impedir sobreposição; as setas continuam permitindo escolher a próxima defesa. A execução é liberada depois da recuperação. O retorno ao lobby e o título existentes permanecem iguais. Não foi adicionada tela de confirmação, escolha de modo ou nova navegação.

## Auditoria temporal efetivamente realizada

1. As fontes reais de movimento e retargeting foram executadas em Luau com doubles das APIs. As sequências principais foram amostradas a **60 amostras/s**, verificando posições de membros, apoio, continuidade e integridade das articulações.
2. Foram conferidos cotovelos, direção dos antebraços, mãos em relação aos ombros e oposição aos passos. Foram encontrados e corrigidos dois cruzamentos de antebraço com o volume do tronco durante as defesas.
3. A comparação de defesas mede deslocamento, altura, inclinação e alcance. Verifica especificamente mãos baixas nas duas rasteiras, alcance superior na alta, pouca translação/inclinação na central e apoio lateral anterior ao sexto mergulho.
4. Foram geradas e inspecionadas reprojeções frontal/lateral do esqueleto do fixture, com oito instantes por ação. São diagramas cinemáticos, não capturas Roblox e não mostram as roupas ou malhas reais.
5. Avatares de proporções menores/mais largas e maiores/mais estreitas, usando AnimationConstraint, foram amostrados também a **30 amostras/s** em todas as ações. Conferidos piso, comprimentos ósseos e ausência de redimensionamento.

| Ação | Instantes selecionados para inspeção da reprojeção (s) |
| --- | --- |
| Corrida/chute | 0,65; 0,80; 0,95; 1,10; 1,25; 1,40; 1,92; 2,22 |
| Rasteira esquerda | 0; 0,22; 0,45; 0,95; 1,28; 1,90; 2,78; 4,15 |
| Rasteira direita | 0; 0,18; 0,46; 0,88; 1,20; 1,82; 2,62; 4,05 |
| Meia altura | 0; 0,25; 0,48; 0,92; 1,42; 2,14; 3,00; 4,55 |
| Alta | 0; 0,24; 0,46; 0,90; 1,38; 1,76; 2,12; 3,75 |
| Central | 0; 0,16; 0,38; 0,65; 1,02; 1,30; 1,50; 1,65 |
| Passo + mergulho | 0; 0,28; 0,58; 0,86; 1,38; 1,85; 3,22; 5,10 |

Na inspeção cinemática dos alcances principais, as mãos das rasteiras ficaram aproximadamente em **0,28/0,88 stud** à esquerda e **0,47/0,82 stud** à direita. A meia altura ficou em **3,52/3,96 studs** e a alta chegou a **7,38 studs**. Esses dados conferem a separação das regiões de alcance no fixture; não representam colisões com a bola, que permanece parada.

O maior deslocamento da raiz entre amostras consecutivas de 1/60 s permaneceu **0,2604 stud**. O maior deslocamento de uma articulação/parte amostrada foi **0,4956 stud**, no pé do cobrador durante a passada. Os limites de regressão são 0,30 para raiz e 0,60 para membros; não são medições de FPS.

## Preservação e testes

Comparação byte a byte contra a base confirmou preservação integral de:

- `PenaltyLayout.luau` e `PenaltyScene.luau`: campo, gol, rede, arquibancadas e bola.
- `Scene.luau`: câmera e iluminação.
- `App.luau`: navegação existente.
- `AvatarAppearance.luau` e `MenuAvatar.luau`: carregamento/identidade dos avatares e apresentação do lobby.
- `src/server/Main.server.luau` e `default.project.json`: bootstrap, serviços e configuração da experiência.

Resultado local: **51 fontes Luau, 15 rotas; 653 verificações de dados; 519 montagens/381 callbacks/240 asserções de UI; 5.933 estados do App; 2.003 introdução; 365.840 asserções de arena**. Rojo 7.7.1 gerou a experiência; o XML contém as 51 fontes idênticas. Sintaxe pelo Luau 0.745 e `git diff --check` aprovados.

Os testes de aparência/cache, cosmético/track indisponível, API lenta, erro/retry, entrada/saída, cancelamento e retorno à espera continuam incluídos. Cada nova defesa também é executada pelo coordenador real de prévias, com bloqueio de sobreposição e recuperação antes da próxima. O seletor é testado para rótulo, ação disparada, ciclo anterior/seguinte, carregamento e tamanhos móveis.

## Arquivos e ponto de parada

- `PenaltyMotion.luau`: correção dos braços, resolução/duração das ações e integração com defesas.
- Novo `PenaltySaves.luau`: seis sequências distintas e interpolação/retorno.
- `PenaltyRig.luau`: peso contínuo de apoio/voo e limitação de alcance na transição, mantendo o retargeting existente.
- `PenaltyActors.luau`: duração por ação e estado de execução para os controles; loader preservado.
- `Screens/PenaltyArena.luau`: seletor compacto e responsivo de prévias.
- `tools/penalty.spec.luau`: auditoria dos braços, diferenças de defesa, apoio, proporções e HUD.
- Documentação: este relatório, `PENALTY_PROGRESS.md`, plano e progresso.

**Não houve execução ou captura visual do motor Roblox nesta sessão.** A revisão usa as fontes reais, matrizes e modelos de teste das APIs. A aparência dos acessórios reais, deformação de malhas, interseções em pacotes corporais não exercitados, sensação de naturalidade e desempenho no celular precisam de avaliação no jogo publicado. Nenhum resultado de doubles foi apresentado como captura ou FPS Roblox.

Depois de revisar o PR e a compilação verde, o proprietário pode publicar manualmente pelo fluxo já existente. Avaliar Ver chute e cada uma das seis defesas pelo seletor, conferir espera/recuperação e voltar ao lobby. **A etapa 2 permanece bloqueada até autorização expressa.**
