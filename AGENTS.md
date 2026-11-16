# CL 27 — instruções essenciais

- Direção do produto: simulador de técnico e administração de clubes em Roblox. Etapa 1: editor de táticas. Etapa 2 autorizada: lobby pré-partida integrado, inscrição de 11 titulares e 5 reservas, avatar real R15. Partidas, resultados, transferências e campeonatos continuam fora do escopo; não publicar nem fazer merge na main.
- Linguagem de produto: português brasileiro. Ativos, clubes e atletas originais.
- Leia `CL27_PLAN.md` e `CL27_PROGRESS.md` antes de continuar; registre evidências e pendências.
- Fonte Rojo: `src/client`, `src/shared`, `src/server`. Apenas um bootstrap cliente.
- Cenas principais usam Workspace e câmera Scriptable. ViewportFrame somente para retratos e uniformes isolados.
- Canvas de referência 1600×900 com UIScale e área segura, sem converter layouts horizontais em uma coluna.
- Telas recebem `(root, ctx)`; ctx contém state, scope, go(id), rerender(), notify(text), scene. Destrua conexões e tweens pelo scope.
- Componentes compartilhados em `src/client/UI.luau`; dados em `src/shared/Data.luau`.
- Não expor segredos, reutilizar IDs antigos ou publicar sem experiência explicitamente confirmada. Compilação é independente da publicação.
- Não declarar fidelidade AAA, 60 FPS, captura Roblox ou revisão quadro a quadro sem medições/capturas reais.
- Auditorias finais em ordem: fidelidade/composição, animação/estados, qualidade/integridade. Registrar limitações com precisão.
