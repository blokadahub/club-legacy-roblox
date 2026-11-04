# CL 27 — Club Legacy 27

Apresentação interativa de futebol para **Roblox**, escrita em **Luau** e compilada com **Rojo 7.7.1**. Não contém partidas, simulação esportiva ou gameplay. Identidade, clubes, escudos, atletas e uniformes são originais, construídos com recursos nativos.

## Apresentações

1. Menu principal na galeria do legado: arquitetura interior, telão, piso, luzes e atleta no Workspace.
2. Visão Geral.
3. Elenco: onze titulares em campo de perspectiva, banco rolável e ficha selecionável.
4. Táticas: três formações e ajustes de apresentação tática.
5. Atribuições: capitão e responsabilidades.
6. Calendário: dias reais, navegação de meses e detalhes de compromissos.
7. Transferências: pesquisa, filtros, perfis e lista de observados.
8. Finanças: categorias, balanço e gráfico de períodos.
9. Desenvolvimento: seleção de atletas e planos.
10. Competições: classificação e chaveamento demonstrativos.
11. Personalização: paleta e uniforme, com personagem em ViewportFrame.
12. Configurações: qualidade, ambiente preferido, movimento reduzido, contraste e dicas.
13. **Clubs**: corredor cinematográfico 3D com carregamento CL permanente, sem véu escuro após a entrada. A seleção de clubes anterior permanece no código, mas não é exibida nesta rota.
14. Seleção de Uniformes: dois atletas no Workspace e camisas isoladas em ViewportFrame.

**Aprenda a Jogar:** o submenu tem quatro opções informativas inativas, aguardando atualização. A cena 3D de treinamento foi removida.

O túnel integrado utiliza os quatro módulos reutilizáveis do PR #7, sem o bootstrap do experimento. Consulte [a integração Clubs](docs/CLUBS_TUNNEL.md) para controles, indicador permanente, restauração e testes. O botão de voltar tem área de toque real de 54 px para Android.

Os dados e preferências permanecem apenas na sessão. A classificação do Circuito Legado reúne oito convidados de três ligas fictícias. As telas compartilham estado, seleções, navegação e animações com descarte de conexões.

## Abrir e executar

Baixe `club-legacy-rbxlx` na aba **Actions**, extraia `club-legacy.rbxlx`, abra no Roblox Studio e use **Play**. A interface é montada pelo LocalScript no cliente; a visualização de edição sem Play não representa os menus.

Compilação local, com ferramentas instaladas:

```sh
python3 tools/validate.py --compiler /caminho/luau-compile
python3 tools/run-data.py --runtime /caminho/luau
python3 tools/run-runtime-smoke.py --runtime /caminho/luau
python3 tools/run-app-states.py --runtime /caminho/luau
python3 tools/run-app-states.py --runtime /caminho/luau --intro
rojo build default.project.json --output club-legacy.rbxlx
python3 tools/validate.py --place club-legacy.rbxlx
```

Navegação: botão **Central** ou **M/Y** abre todas as seções; **B** volta. Mouse, toque e seleção de controle são suportados pelas APIs nativas. O canvas horizontal de 1600×900 se ajusta proporcionalmente à área disponível.

A entrada passa pela abertura cinematográfica CL 27, com boas-vindas e botão **START**. O lobby é preparado oculto; a playlist só é liberada depois da revelação final. Veja [a linha do tempo, arquitetura e roteiro de auditoria](docs/CINEMATIC_INTRO.md). A abertura permanece em START até a interação do jogador.

## Estrutura e publicação

`src/shared` contém dados e tema. `src/client` contém App, ciclo de vida, UI, personagens, cenários e telas. `src/server` desativa spawn jogável. Apenas um bootstrap cliente e um servidor são mapeados pelo Rojo.

O workflow `build.yml` valida Luau, dados, estrutura e XML, então disponibiliza o artefato. `publish.yml` mantém o fluxo manual Open Cloud com publicação desativada por padrão. Destino autorizado: Backrooms (`Universe ID 9749365367`, `Place ID 86256105108811`), configurado no workflow após confirmação do proprietário. Configure o secret `ROBLOX_API_KEY`, confirme o Place ID ao publicar e observe a checagem automática de correspondência com o Universe pela API Roblox. Pushes não publicam no Roblox. Veja `PUBLICAR_CL27.md`.

## Evidências e limites

Consulte [CL27_PROGRESS.md](CL27_PROGRESS.md) para testes e auditorias realmente executados, [CL27_PLAN.md](CL27_PLAN.md) para arquitetura e [análise das referências](docs/REFERENCE_ANALYSIS.md) para composição.

Este ambiente consegue compilar Luau e gerar o arquivo Roblox, mas não executa Roblox Studio/Player. Não há captura de telas do resultado, inspeção de vídeo quadro a quadro ou medição de FPS. Fidelidade visual e acabamento final precisam ser confirmados em execução pelo [roteiro Studio](tools/STUDIO_AUDIT.md). Compilação e testes com APIs substituídas não certificam renderização ou comportamento do motor Roblox.
