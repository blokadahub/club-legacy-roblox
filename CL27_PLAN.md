# CL 27 — plano técnico

## Abertura cinematográfica

O bootstrap único agora monta IntroController antes de carregar App. Timeline monotônica preserva os marcos da referência e aguarda START; o lobby existente é preparado em segundo plano com navegação e música bloqueadas. O indicador de TransitionFX é compartilhado sem Cover inicial; só após a revelação Soundtrack.create/release libera a playlist. Fundo de facetas independente, marca própria e três efeitos autorizados. Arquitetura, tempos e limites em [CINEMATIC_INTRO.md](docs/CINEMATIC_INTRO.md).

## Inspeção inicial — 03/11/2026

Repositório confirmado pela conexão GitHub: `blokadahub/club-legacy-roblox`.
Main em `c6065273d72443a5ae6a4919387430aa579d57f5`: README, gitignore e mapeamento Rojo vazio. Sem scripts, dependências ou workflows nessa branch. A branch `feat/cl27-interface` possui implementação anterior e workflows; backup preservado. As referências antigas não serão reutilizadas.

Git clone via shell falhou ao conectar ao proxy. O conector GitHub permite ler e registrar arquivos; usaremos a API de árvores/commits se necessário. Nenhum Roblox Studio/Player, Rojo ou Luau CLI foi encontrado inicialmente. Não há credencial Roblox configurada no ambiente. Consultar workflow anterior antes de reconstruir CI.

## Arquitetura

1. `ReplicatedStorage.CL27`: tema, dados fictícios coerentes, estado e seleções.
2. `StarterPlayerScripts.CL27`: App, componentes UI, Scope para descarte, módulos de telas, Scene e Rig.
3. `ServerScriptService`: desativação de spawn automático; produto sem gameplay.
4. Workspace local: interior arquitetônico com telão, piso, luzes e atleta; arena escura, túnel de Clubs e apresentação de dois uniformes. A cena legada de treinamento foi removida; a nova prévia de pênaltis é `PenaltyArena`/`Penalty`, descrita em `docs/PENALTY_PROGRESS.md` (etapa 1 apenas).
5. Canvas 1600×900 ajustado à área segura. Navegação comum por mouse, toque, teclado e seleção de controle; transição cromática azul/esmeralda/turquesa cobre trocas de cena.
6. Todos os dados de demonstração são locais à sessão. Sem economia, transferências ou partidas reais.

## Contrato de implementação

Cada tela exporta função `(root, ctx)`. Contexto: `state`, `scope`, `go(id)`, `rerender()`, `notify(text)`, `scene`. UI compartilhada: `new`, `frame`, `panel`, `text`, `button`, `line`, `gradient`, `stroke`, `badge`, `portrait`, `header`, `section`, `stat`, `bar`. Coordenadas em pixels no canvas de referência. O App desenha navegação global e rodapé. Cada scope é descartado na navegação.

IDs: HomeInterior, Overview, Squad, Tactics, Assignments, Calendar, Transfers, Finance, Development, Competitions, Customization, Settings, Clubs, Kits.

## Ciclos e validação

- Analisar cinco anexos individualmente e registrar composição por regiões.
- Implementar base comum, cenários/personagens e telas em paralelo com contratos definidos.
- Verificar integridade Rojo, require, rotas, dados e descarte de estados; compilar com Rojo 7.7.1 no Actions.
- Auditoria 1: reabrir referências, comparar geometria implementada por regiões e corrigir. Sem render Roblox, comparação permanece de composição por código.
- Auditoria 2: revisar início/meio/fim e interrupção das transições; capturar quadros somente se houver execução Roblox real.
- Auditoria 3: revisão independente, validações automatizadas e repetição após correções.
- Commit no GitHub, acompanhar build, documentar limitações e roteiro de validação Studio.

## Entrega e publicação

Gerar `club-legacy.rbxlx` com Rojo 7.7.1. CI automática somente compila/valida. Open Cloud manual, com destino em variáveis explicitamente configuradas e chave em secret; não executar nesta sessão sem destino confirmado.

## Pênaltis — etapa 1 em 04/11/2026

Prévia modular no Workspace integrada exclusivamente a Aprenda a Jogar → Arena de Treino. Medidas e câmera em PenaltyLayout, R15 estáticos em PenaltyActors, construção e bola independente em PenaltyScene; Scene mantém propriedade única da câmera e iluminação. Entrada direta sem tela intermediária e retorno ao lobby. Gameplay, física da bola e animações de cobrança aguardam autorização expressa do usuário. Estado, testes, limitações e publicação manual em [PENALTY_PROGRESS.md](docs/PENALTY_PROGRESS.md).
