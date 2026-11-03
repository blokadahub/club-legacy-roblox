# Etapa 2 — auditoria de animações e estados

Executada em 03/11/2026, depois do encerramento da etapa 1 em `AUDIT_1_VISUAL.md` e antes da etapa 3.

## Alcance e limite obrigatório

Foram revisados os módulos reais `App`, `Scope`, `UI`, `Rig`, `Scene`, `Squad`, `Clubs` e `Kits`, incluindo chamadas de navegação das demais telas. A análise cobre fases inicial/intermediária/final previstas pelo código, interrupções, filas, bloqueio de entradas e descarte. Foram executados testes no compilador e runtime oficiais Luau.

**Não existe execução Roblox Studio/Player disponível. Não foram gravados vídeos, renderizados quadros nem realizada inspeção visual quadro a quadro.** Easing observado, continuidade perceptual, flicker, cortes, sobreposição durante movimento e FPS continuam pendentes de captura real. Os testes descritos abaixo usam doubles de serviços/objetos, relógio virtual e propriedades em memória; não certificam APIs, renderização ou desempenho Roblox.

## Revisão das fases e continuidade

| Animação | Início, meio e fim previstos | Interrupção e descarte |
| --- | --- | --- |
| Navegação entre telas | Wipe visível, transparência do grupo 1→0 em 0,22s Quart Out; página original permanece até a cobertura. Então renderiza destino e troca cena; wipe 0→1 em 0,36s. Entrada liberada ao final. | Uma navegação ocupada guarda somente a última rota pendente. A próxima transição começa após concluir a atual. Destruição cancela delays/tweens e ignora chamadas posteriores ao handle. |
| Movimento reduzido | Mesma ordem de estados com cobertura de 0,06s e saída de 0,08s; rerender não aplica fade. | Câmera perde drift e rig perde respiração; troca de cor e iluminação usam duração zero. As microinterações de cor dos botões permanecem discretas. |
| Rerender da mesma tela | Novo CanvasGroup começa em transparência 0,22 e chega a 0 em 0,18s; não desloca coordenadas. | Scope anterior é destruído antes do novo conteúdo. O estado de clubes/uniformes permanece na tabela central. |
| Seleção de atleta | Nome, overall, atributos e bordas atualizam no mesmo callback. Retrato começa em ImageTransparency0,35 e chega a0 em0,22s; faixa lateral muda transparência em0,28s. | Reconstrói somente o corpo da ficha e destrói anterior, mantendo campo e reservas imóveis. Tweens são limitados pelo scope e pela duração; trocar de tela cancela os restantes. |
| Botões | Cor e transparência chegam ao destaque em0,14s e retornam ao valor-base ao sair/perder foco. | Um tween novo cancela o anterior no mesmo objeto; parte do valor atual, sem reiniciar uma posição. Foco do controle foi adiado até liberar a página. |
| Uniformes dos atores | As cores do uniforme atual interpolam para a paleta selecionada em0,24s Quart Out. O nome do uniforme acompanha a seleção. | Troca rápida cancela tween anterior por parte, preservando o valor interpolado atual. Assinatura de clube/paleta impede reinício no rerender. Destroying cancela os tweens das partes. |
| Iluminação entre cenas | Alvos próprios para interior/treinamento/arena em0,32s Sine InOut; geometria é trocada sob wipe. | Cancela os tweens anteriores antes de iniciar nova iluminação. Destruição restaura propriedades anteriores e remove efeitos criados. |
| Câmera | Scriptable, lookAt e FOV compensado pela altura do canvas; drift senoidal limitado a0,065stud horizontal e0,027vertical. Delta de tempo limitado a0,1 evita grande avanço de fase após pausa. | Snapshot por câmera antes da primeira alteração. Troca de CurrentCamera restaura a anterior; destruir restaura a atual e desconecta RenderStepped. |
| Personagens | Poses fixam os Motor6D; respiração usa seno contínuo, amplitude angular pequena de0,007rad, sem tracks ou assets externos. | Movimento reduzido aplica delta nulo. Modelos destruídos limpam juntas e tweens; a cena remove referências dos atores ao trocar ambiente. |

Os tempos acima são valores de implementação. Não representam durações medidas em gravação real. A interpolação numérica do harness é linear para observar estados intermediários; a curva Quart/Sine real não foi reproduzida nem julgada visualmente.

## Defeitos encontrados e correções verificáveis

1. **Central deixava comandos passarem à página.** Antes, abrir a sobreposição não pausava o scope da página e seu Frame não era Active. InputBegan de clubes/uniformes continuava válido. O novo teste falhou em `Central menu must lock underlying header tabs`. Agora a Central pausa entradas da página, bloqueia abas por `UI.inputLocked`, usa Frame Active e restaura foco/entradas ao fechar. O teste também dispara diretamente um botão da página sob a Central e uma aba Táticas; ambos ficam bloqueados.
2. **Foco de controle era atribuído durante bloqueio.** `render()` selecionava o primeiro botão enquanto `pageScope.inputsPaused=true`; SelectionGained do destaque era suprimido. Agora o foco é definido depois da saída da transição e da liberação do scope. O render inicial continua imediato. Testes verificam foco ausente no handoff e presente ao final, além da restauração ao fechar a Central.
3. **Delays concluídos acumulavam closures de cancelamento.** Cada `Scope:Delay` adicionava uma função permanente em cleanups, mesmo após conclusão. Substituído por registro apenas das threads ativas, removidas antes do callback. Cem tarefas executadas deixam `cleanups` e registro de delays vazios; uma tarefa pendente é cancelada ao destruir.
4. **Câmera substituída não era restaurada.** Scene controlava qualquer CurrentCamera, mas só restaurava a instância salva no construtor. Corrigido com snapshots weak-key por câmera e referência ativa weak-value. O teste executa o callback real de Scene sobre duas câmeras em memória, troca a câmera, destrói a cena e verifica CameraType/FOV/CFrame originais e ausência de callback residual.
5. **DPad tinha responsabilidade dupla.** As escutas globais de Clubs/Kits trocavam a seleção com DPadLeft/Right sempre que processed=false, competindo potencialmente com foco nativo. O teste reproduziu `Controller focus movement must not cycle clubs globally`. Removidos DPad desses listeners; setas de teclado continuam alternando, controle navega foco e aciona as setas com A. Testes verificam ambos os comportamentos de estado.
6. **Handle após descarte podia iniciar transição.** `go()` não verificava o lifetime e o lock global podia permanecer durante destruição em uma transição. Agora chamadas após descarte retornam imediatamente, pendência é apagada e lock liberado. Testado destruir no começo de uma transição, avançar relógio e tentar nova navegação.

## Testes executados

- `python3 tools/run-app-states.py --runtime /tmp/cl27-tools/luau/luau`: **39 asserções aprovadas**. Executa App/Scope/UI reais, telas reais e testes isolados do callback/lifecycle real de Scene com serviços em memória. Verifica início, meio e fim das fases, último pedido pendente, histórico, Central, foco, teclado/controle, movimento reduzido, descarte e cem delays concluídos.
- `python3 tools/run-runtime-smoke.py --runtime /tmp/cl27-tools/luau/luau`: **538 montagens, 382 callbacks e 191 asserções aprovadas**, incluindo as 15 rotas e seleção de atletas, clubes e uniformes. Utiliza stubs e não renderiza.
- `python3 tools/validate.py --compiler /tmp/cl27-tools/luau/luau-compile`: **25 fontes aprovadas** pelo compilador oficial Luau0.745 e verificação de estrutura/rotas/require.
- `actionlint`1.7.12: workflows de build e publicação aprovados após inclusão dos dois harnesses no CI.
- Build com Rojo7.7.1 e comparação das fontes no XML repetidos após as correções; resultado registrado junto à execução integrada.

## Pendências para captura real

- Gravar navegação normal/reduzida, troca rápida de uniformes, seleção rápida de atletas e abertura/fechamento da Central em Roblox.
- Inspecionar quadros inicial/intermediário/final e todas as mudanças de estado: cobertura completa antes da troca de geometria, continuidade dos tons, clipping e ausência de flashes.
- Verificar se a construção síncrona dos cenários produz hitch em dispositivos móveis; medir com MicroProfiler. Nenhuma taxa de quadros foi medida nesta etapa.
- Conferir aparência da seleção nativa do controle e foco em elementos roláveis usando controle real.
- Repetir capturas nas resoluções documentadas em `tools/STUDIO_AUDIT.md` e corrigir qualquer problema reproduzível.

Etapa 2 encerrada no alcance de código/estados verificável pelo ambiente. A inspeção quadro a quadro de capturas Roblox continua explicitamente pendente; iniciar etapa 3 após este registro.
