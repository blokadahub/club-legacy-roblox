# CL 27 — Club Legacy 27

Apresentação interativa de futebol para **Roblox**, escrita em **Luau** e compilada com **Rojo 7.7.1**. Não contém partidas, simulação esportiva ou gameplay. Identidade, clubes, escudos, atletas e uniformes são originais, construídos com recursos nativos.

## Apresentações

1. Menu principal na galeria do legado: arquitetura interior, telão, piso, luzes e atleta no Workspace.
2. Menu principal no centro de treinamento: campo, sede, céu diurno e atleta no Workspace.
3. Visão Geral.
4. Elenco: onze titulares em campo de perspectiva, banco rolável e ficha selecionável.
5. Táticas: três formações e ajustes de apresentação tática.
6. Atribuições: capitão e responsabilidades.
7. Calendário: dias reais, navegação de meses e detalhes de compromissos.
8. Transferências: pesquisa, filtros, perfis e lista de observados.
9. Finanças: categorias, balanço e gráfico de períodos.
10. Desenvolvimento: seleção de atletas e planos.
11. Competições: classificação e chaveamento demonstrativos.
12. Personalização: paleta e uniforme, com personagem em ViewportFrame.
13. Configurações: qualidade, ambiente preferido, movimento reduzido, contraste e dicas.
14. Seleção de Clubes: dois painéis simétricos, filtros e comparação de atributos.
15. Seleção de Uniformes: dois atletas no Workspace e camisas isoladas em ViewportFrame.

Os dados e preferências permanecem apenas na sessão. A classificação do Circuito Legado reúne oito convidados de três ligas fictícias. As telas compartilham estado, seleções, navegação e animações com descarte de conexões.

## Abrir e executar

Baixe `club-legacy-rbxlx` na aba **Actions**, extraia `club-legacy.rbxlx`, abra no Roblox Studio e use **Play**. A interface é montada pelo LocalScript no cliente; a visualização de edição sem Play não representa os menus.

Compilação local, com ferramentas instaladas:

```sh
python3 tools/validate.py --compiler /caminho/luau-compile
python3 tools/run-data.py --runtime /caminho/luau
python3 tools/run-runtime-smoke.py --runtime /caminho/luau
python3 tools/run-app-states.py --runtime /caminho/luau
rojo build default.project.json --output club-legacy.rbxlx
python3 tools/validate.py --place club-legacy.rbxlx
```

Navegação: botão **Central** ou **M/Y** abre todas as seções; **B** volta. Mouse, toque e seleção de controle são suportados pelas APIs nativas. O canvas horizontal de 1600×900 se ajusta proporcionalmente à área disponível.

## Estrutura e publicação

`src/shared` contém dados e tema. `src/client` contém App, ciclo de vida, UI, personagens, cenários e telas. `src/server` desativa spawn jogável. Apenas um bootstrap cliente e um servidor são mapeados pelo Rojo.

O workflow `build.yml` valida Luau, dados, estrutura e XML, então disponibiliza o artefato. `publish.yml` mantém o fluxo manual Open Cloud com publicação desativada por padrão. Configure `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` e o secret `ROBLOX_API_KEY` somente para o destino revisado; confirme o Place ID ao publicar. IDs antigos não são reutilizados e pushes não publicam no Roblox.

## Evidências e limites

Consulte [CL27_PROGRESS.md](CL27_PROGRESS.md) para testes e auditorias realmente executados, [CL27_PLAN.md](CL27_PLAN.md) para arquitetura e [análise das referências](docs/REFERENCE_ANALYSIS.md) para composição.

Este ambiente consegue compilar Luau e gerar o arquivo Roblox, mas não executa Roblox Studio/Player. Não há captura de telas do resultado, inspeção de vídeo quadro a quadro ou medição de FPS. Fidelidade visual e acabamento final precisam ser confirmados em execução pelo [roteiro Studio](tools/STUDIO_AUDIT.md). Compilação e testes com APIs substituídas não certificam renderização ou comportamento do motor Roblox.
