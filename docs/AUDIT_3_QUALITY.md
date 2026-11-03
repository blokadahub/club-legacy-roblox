# Etapa 3 — auditoria definitiva de qualidade

Executada em 03/11/2026 por agente separado da integração principal, **depois do encerramento documentado das etapas 1 e 2**. As etapas anteriores não foram substituídas ou reabertas; as correções abaixo foram revalidadas nesta terceira etapa.

## Alcance da revisão

Foram lidas as 15 rotas, seus 14 módulos de tela, `Pitch`, `ManagementUI`, `App`, `UI`, `Scope`, `Scene`, `Rig`, tema/dados, bootstraps, mapeamento Rojo, workflows e documentação de evidências. Foram executados o compilador/runtime oficiais Luau, Rojo, actionlint, comparação das fontes no XML e catálogo API Roblox.

**Não houve execução de Roblox Studio/Player, renderização das telas, gravação de vídeo, inspeção real quadro a quadro, controle físico ou medição de FPS.** Esta revisão aprova somente os aspectos de fontes, dados, estados e integração que puderam ser verificados. Não certifica acabamento visual idêntico às referências, ausência de problemas no motor Roblox ou qualidade AAA observada.

## Os 17 itens da revisão solicitada

| Item | Verificação concreta e resultado | Limite que permanece |
| --- | --- | --- |
| 1. Fidelidade às cinco referências | Mantidas as coordenadas regionais registradas na etapa 1; corrigido branco da opção selecionada de Home, escala dos retratos e aplicação de cores dos gradientes. | Comparação do resultado com imagens renderizadas permanece pendente. |
| 2. Dois cenários de menu | Interior e Training usam construtores Workspace, câmeras, materiais e iluminação distintos; Home compartilha somente navegação. O telão continua atrás do atleta. | Luz, reflexos, céu, gramado e oclusão precisam ser vistos em Studio. |
| 3. Personagens 3D | R15 possui 15 segmentos, root, Humanoid, Motor6D, detalhes e uniforme original. A máquina de estados foi desativada para o rig somente de apresentação; pose continua dirigida por C0. | Aparência, execução das juntas e sombras exigem motor real. |
| 4. Gerenciamento do elenco | Campo, banco e ficha permanecem simultâneos. Seleção do reserva 22 substitui retrato/ficha no harness. Duas linhas do banco agora cabem integralmente na janela. | Fontes pequenas, nitidez e navegação física do controle não foram observadas. |
| 5. Perspectiva do campo | Uma mesma projeção trapezoidal posiciona gramado, linhas e cartões. Formações foram reordenadas por atleta: lados direito/esquerdo e atacante central passam em testes de domínio. | O resultado perceptual em resoluções distintas depende de captura. |
| 6. Cartões de jogadores | Retratos mantêm câmera frontal e pose própria; distância reduzida de 7,7 para 4,4 stud para enquadramento de cabeça/ombros. Overall, nome e condição continuam visíveis por geometria. | Nenhuma qualidade facial/textual foi certificada visualmente. |
| 7. Seleção de clubes | Filtros de país/liga, lados, nomes, escudos, estrelas, atributos e comparação exercitados; composição simétrica preservada. | Reflexos e luminosidade final dependem de render. |
| 8. Seleção de uniformes | Troca atualiza paleta dos atores e previews; confirmação de ambos exigida. Personalização agora invalida confirmação antiga ao alterar uniforme. Previews receberam folga horizontal e ações foram afastadas do rodapé. | Textura/forma aparente das camisas e transição de cor só podem ser julgadas em execução. |
| 9. Gradientes e cores | Corrigida multiplicação de UIGradient por BackgroundColor3 escuro nas aplicações cromáticas. Branco neutraliza a multiplicação; a sombra de Home, que usa gradiente apenas de transparência, conserva grafite. Contraste de textos comuns foi reforçado quando configurado. | Valores de cor não equivalem a avaliação de cor composta no render. |
| 10. Navegação | 15 rotas montadas; histórico, fila, Central, entrada bloqueada e descarte revalidados. Rerender da mesma rota preserva foco equivalente do controle e posição de três listas. Hint de Enter foi retirado porque não havia ativação explícita por essa tecla. | Movimento nativo do foco entre objetos e toque real precisam de Studio/dispositivo. |
| 11. Responsividade | Canvas 1600×900 ajustado à área disponível; FOV acompanha sua altura. Corrigidas bordas inferiores de Calendário/Uniformes e corte da segunda linha de reservas. | Leitura em celular, portrait, insets de hardware e telas pequenas não foi aprovada. |
| 12. Animações | Repetidos testes de fase, bloqueio, último pedido, cancelamento, câmera substituída, descarte e movimento reduzido da etapa 2. Novas correções não alteraram a ordem de cobertura/troca/saída. | Nenhuma captura quadro a quadro ou curva de easing real foi inspecionada. |
| 13. Integridade Luau | 25 fontes compiladas pelo Luau 0.745; dados e harnesses aprovados. Nenhum módulo de produto vazio ou pseudocódigo. | Compilação sintática não é typecheck com definições completas do Roblox nem execução do cliente. |
| 14. Dependências Rojo | Rojo 7.7.1 gera DataModel com serviços e um bootstrap por lado; XML contém as 25 fontes exatamente iguais às fontes locais. Sem require de asset numérico externo. | O arquivo precisa ser aberto e executado em Studio. |
| 15. Publicação Roblox |Actions validado; build independente, artefato e Open Cloud manual com segredo/IDs por configuração e confirmação de destino. Removida execução duplicada do smoke no CI. Nenhuma publicação foi disparada. | Destino e credencial Roblox não confirmados; publicação fica para fluxo manual autorizado. |
| 16. Regressões de correções anteriores | Regressões cobrem seleção do último atleta, scroll/foco, filtro vazio, plano por atleta, confirmação de uniforme, calendário 2027, lados da formação e callbacks descartados. Todos os checks pertinentes foram repetidos após as últimas alterações. | Stubs não descobrem toda incompatibilidade de propriedade/serviço/render. |
| 17. Performance mensurável | Inspecionados modelos locais, descarte de scopes, efeitos removidos, registro de delays, rig passivo e níveis de qualidade. Não existe loop de reconstrução de UI por frame; RenderStepped anima câmera e atores. | Sem medição de FPS, memória, drawcalls, hitch de construção ou MicroProfiler; nenhum ganho numérico ou 60 FPS é afirmado. |

## Correções concretas desta etapa

1. **Reservas cortadas na segunda linha:** cartões compactos 95 px e passo 103 px somavam 198 px em janela 191 px. Agora 90 px e passo 98 px somam 188 px; o nome permanece dentro da área inicial sem exigir rolagem. Canvas continua rolável para dados futuros.
2. **Retratos pequenos pelo frustro previsto:** 7,7 stud/FOV 29° exibiam aproximadamente 4 stud verticais para uma cabeça de ≈1 stud. Distância 4,4 stud conserva cabeça e ombros com campo vertical ≈2,27 stud. É um ajuste geométrico, sem alegar observação visual.
3. **Foco e listas voltavam ao início:** `UI.keepScroll` salva e restaura posição, limitada ao conteúdo atual. App mantém ordinal de botão equivalente apenas em rerender da mesma rota. A seleção do último atleta foi exercitada tanto no harness de telas quanto no App real sob doubles; o foco e Y=500 permanecem.
4. **Formação incoerente com posição:** LD/PD estavam à esquerda, LE/PE à direita e o ATA do 4–2–3–1 fora do centro. Reordenados os mesmos pontos, preservando a geometria existente. Os 16 novos checks de domínio verificam lados, linha ofensiva e atacante central.
5. **Confirmação/plano obsoletos:** Personalização alterava uniforme sem invalidar Pronto; Desenvolvimento podia herdar a escolha de outro atleta ao entrar pela Central. Ambos corrigidos e cobertos por regressão.
6. **Coerência do conteúdo:** Home acompanha clube selecionado, Visão Geral calcula condição média pelos dados e o calendário não repete partidas de 2026 ao navegar para novembro 2027. Legenda inferior afastada do rodapé.
7. **Cor e hierarquia:** neutro branco nas aplicações cromáticas evita multiplicar tons já escuros; seleção Home preserva branco/peso e a linha turquesa. Texto de controles passa a indicar Clique/A, M/Y e B, compatíveis com as ações implementadas.
8. **Previews/rodapé dos uniformes:** FOV 34° e distância maior na alternativa dão folga horizontal para mangas; botões terminam antes do rodapé 839 px.
9. **Rig somente de apresentação:** `Humanoid.EvaluateStateMachine=false`, API gravável no catálogo fornecido, evita depender de locomoção de Humanoid para um modelo com root ancorado. Não foi medido ganho de desempenho.
10. **CI:** removida segunda execução idêntica do smoke; continuam sintaxe, dados, telas, estados, build e conferência XML.
11. **Iluminação nativa atual:** LightingStyle=Realistic e PrioritizeLightingQuality=true no DataModel inicial; qualidade média mantém Realistic sem prioridade, baixa usa Soft sem prioridade. Scene restaura ambas ao destruir. Não foi usada a propriedade Technology obsoleta/restrita. Rojo 7.7.1 e o catálogo API foram conferidos após a alteração; não há medição de ganho gráfico ou FPS.

## Evidências finais

Comandos executados após as correções:

```sh
python3 tools/validate.py --compiler /tmp/cl27-tools/luau/luau-compile
python3 tools/run-data.py --runtime /tmp/cl27-tools/luau/luau
python3 tools/run-runtime-smoke.py --runtime /tmp/cl27-tools/luau/luau
python3 tools/run-app-states.py --runtime /tmp/cl27-tools/luau/luau
/tmp/cl27-tools/rojo/rojo build default.project.json --output club-legacy.rbxlx
python3 tools/validate.py --place club-legacy.rbxlx
/tmp/cl27-tools/actionlint .github/workflows/build.yml .github/workflows/publish.yml
python3 tools/check-api.py --dump /tmp/cl27-api-dump.json
```

- Luau: 25 fontes aprovadas.
- Dados: 653 verificações aprovadas, 8 clubes, 22 atletas e 3 formações.
- Telas com serviços substituídos: 550 montagens, 386 callbacks e 206 asserções aprovados.
- App com relógio virtual: 46 asserções aprovadas.
- Rojo 7.7.1: arquivo gerado; comparação XML aprova 25 fontes sem alteração e serviços/bootstraps.
- actionlint 1.7.12: nenhum erro nos dois workflows.
- Catálogo API: 294 referências estáticas a classes/enums, 0 nomes inexistentes. SHA256 do dump: `0962f777e3085487e368ed019c35bdb07cd02f6659aa7212dc2ad6e24bb41efe`.
- Inspeção adicional do mesmo dump: 30 propriedades críticas existem, não são ReadOnly e têm WriteSecurity=None, incluindo LightingStyle/PrioritizeLightingQuality, câmeras, viewport, Humanoid/RigType/EvaluateStateMachine, Lighting, Motor6D.C0, scroll, CanvasGroup, SurfaceGui e foco. Isso não certifica todos os acessos dinâmicos ou permissões de execução.

## Pendências finais que exigem Studio

Abrir o artefato, usar Play e percorrer o roteiro em `tools/STUDIO_AUDIT.md`. Prioridades: capturar as cinco composições, verificar retratos maiores e camisas sem corte, observar juntas/poses, comparar materiais e iluminação, validar foco/scroll em controle físico e legibilidade em dispositivos menores. Gravar transições reais, inspecionar seus quadros e medir desempenho em hardware identificado.

Etapa 3 encerrada no alcance técnico verificável. Não resta falha reproduzida pelos checks desta etapa; a aprovação visual final e as medições permanecem explicitamente pendentes.
