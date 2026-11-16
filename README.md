# CL 27 — Club Legacy 27

Projeto para **Roblox**, escrito em **Luau** e compilado com **Rojo 7.7.1**, em transformação para um simulador de técnico e administração de clubes contra IA. A primeira etapa implementa o editor tático; a segunda acrescenta o lobby pré-partida 3D, inscrição de 16 atletas e confirmação da escalação na sessão. Partidas, motor de futebol 2D, transferências reais e campeonatos ainda não estão implementados. As apresentações existentes permanecem disponíveis. Identidade, clubes, escudos, atletas e uniformes são originais, construídos com recursos nativos.

## Apresentações

1. Menu principal na galeria do legado: arquitetura interior, telão, piso, luzes e atleta no Workspace.
2. Visão Geral.
3. Elenco: onze titulares em campo de perspectiva, banco rolável e ficha selecionável.
4. Táticas: editor com 4–3–3, 4–2–3–1, 4–3–2–1, 5–4–1 e a opção legada 3–5–2; predefinições, duas fases, funções individuais, estratégias coletivas e confirmação/cancelamento.
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

## Editor de táticas — mega atualização, etapa 1

Na Central, abra **Táticas**. Selecione uma predefinição, alterne a formação e ajuste construção, pressão, mentalidade, amplitude e linha defensiva. Toque nos cartões do campo para editar função e comportamento. Os seletores de fase mostram organizações distintas; não executam uma partida.

**Salvar alterações** valida onze atletas distintos e compatíveis antes de confirmar. **Cancelar** restaura a tática ativa; sair da tela abandona alterações não salvas. A tela **Elenco** mostra os titulares confirmados, incluindo o terceiro zagueiro do 5–4–1. Tudo fica apenas na sessão atual, sem DataStore.

O canvas continua 1600×900. Controles e campo são roláveis; em telas compactas, o campo é ampliado proporcionalmente para leitura e toque, e pode ser arrastado em ambos os eixos. A navegação por controle revela o item focado. [Contrato, arquivos, testes e validação Roblox pendente](docs/TACTICS_EDITOR.md).

## Abrir e executar

**Etapa 02 — Central → Pré-partida:** confira os onze titulares da tática salva e os cinco reservas inscritos. Selecione um titular para consultar função/instrução e escolher um reserva compatível. Selecione um reserva para mudar sua inscrição ou propor sua entrada no time. **Confirmar escalação** grava os 16 na memória da sessão; **Cancelar alterações** restaura a lista. Navegar descarta propostas pendentes. Táticas e Elenco usam os mesmos titulares confirmados; o elenco global de 22 atletas é preservado.

Em celulares compactos, o campo mostra as onze posições abreviadas. Toque em **Ver titulares** e use **Outro titular** na ficha para percorrer todos, consultar funções e propor trocas com alvos maiores. Reservas, abas e ficha rolam quando necessário. O personagem da direita é uma cópia R15 da aparência da conta, identificada como técnico, separada dos atletas fictícios. Um uniforme CL-27 simples é aplicado apenas em corpos compatíveis; roupas em camadas e corpos texturizados preservam a aparência da conta.

O lobby não inicia partidas. A confirmação fica pronta para integração posterior; salvar outra tática exige confirmar a preparação novamente. [Arquitetura, arquivos, evidências e roteiro de validação Roblox](docs/MATCH_LOBBY.md). **Sem aprovação visual definitiva, merge ou publicação nesta etapa.**

Baixe `club-legacy-rbxlx` na aba **Actions**, extraia `club-legacy.rbxlx`, abra no Roblox Studio e use **Play**. A interface é montada pelo LocalScript no cliente; a visualização de edição sem Play não representa os menus.

Compilação local, com ferramentas instaladas:

```sh
python3 tools/validate.py --compiler /caminho/luau-compile
python3 tools/run-data.py --runtime /caminho/luau
python3 tools/run-runtime-smoke.py --runtime /caminho/luau
python3 tools/run-app-states.py --runtime /caminho/luau
python3 tools/run-app-states.py --runtime /caminho/luau --intro
python3 tools/run-app-states.py --runtime /caminho/luau --penalty
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
