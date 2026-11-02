# Checklist oficial — CL - Club Legacy

**Legenda:** `[x]` realizado ou configurado e confirmado no GitHub; `[ ]` não realizado ou ainda não verificado. **Configurar não equivale a testar.**

## 1. Repositório e infraestrutura

- [x] Repositório `blokadahub/club-legacy-roblox` criado na branch `main`.
- [x] Estrutura `src/server`, `src/client` e `src/shared` adicionada.
- [x] Projeto `default.project.json` criado para Rojo.
- [x] Scripts principais de servidor e cliente fornecidos pelo Claude, integrados no GitHub (aguardando testes reais).
- [x] GitHub Actions com instalação automática de Rojo 7.7.1 configurado.
- [x] Compilação `.rbxlx` e upload do artefato configurados no workflow.
- [x] Publicação manual, opt-in, desativada por padrão.
- [x] Bloqueio de publicação enquanto os scripts principais contiverem `CL_SCAFFOLD_PLACEHOLDER`.
- [x] README, orientações para o Claude e checklist publicados.
- [x] Publicação pelo workflow do repositório antigo Backrooms desativada; código antigo preservado.
- [x] Primeiro teste real do GitHub Actions concluído com sucesso (02/11/2026, execução #41525520683, commit `5c81b17`).
- [x] Código inicial do Claude (servidor, cliente e Config) entregue e integrado; ainda não homologado.
- [ ] Revisão de sintaxe, mapeamento Rojo e comunicação cliente-servidor concluída.

## 2. Roblox e publicação

- [x] Experiência Roblox antiga identificada como destino a ser reaproveitado.
- [x] Universe ID conhecido: `9749365367`.
- [x] Place ID conhecido: `86256105108811`.
- [x] IDs configurados diretamente no workflow do Club Legacy.
- [ ] Experiência renomeada para **CL - Club Legacy** no Roblox Creator Hub.
- [ ] Secret `ROBLOX_API_KEY` cadastrado neste repositório (não verificável pela integração; precisa ser feito pelo proprietário).
- [ ] Permissão Open Cloud `universe-places: Write` e acesso à experiência conferidos.
- [ ] Primeiro build real do código definitivo concluído sem erros.
- [ ] Primeira publicação manual do Club Legacy concluída.
- [ ] Abertura da experiência no aplicativo Roblox Android confirmada.
- [ ] Configuração de visibilidade e disponibilidade da experiência revisada.

## 3. Produto mínimo jogável — código inicial integrado, funcionamento ainda não comprovado

- [ ] Tela inicial, criação e carregamento de carreira.
- [ ] Escolha ou criação de clube fictício.
- [ ] Liga inicial de oito equipes e respectivos elencos.
- [ ] Jogadores com posição, idade, overall e atributos essenciais.
- [ ] Escalação de titulares e reservas.
- [ ] Formações e táticas com impacto na partida.
- [ ] Calendário coerente de ida e volta.
- [ ] Simulação das partidas de toda a rodada.
- [ ] Tabela de classificação, estatísticas e critérios de desempate.
- [ ] Mercado de transferências e validação de orçamento.
- [ ] Evolução simplificada e condição física dos atletas.
- [ ] Resumo de fim de temporada e começo da temporada seguinte.
- [ ] Salvamento e carregamento com `DataStoreService` no servidor.
- [ ] Interface totalmente utilizável em telas pequenas.
- [ ] Validação de RemoteEvents/RemoteFunctions e proteção de dados importantes no servidor.

## 4. Testes obrigatórios — ainda não realizados

- [ ] Verificar se a carreira não perde dados depois de sair e voltar.
- [ ] Verificar se não é possível gastar mais dinheiro do que o clube possui.
- [ ] Verificar se vitórias, empates, derrotas e pontos estão corretos.
- [ ] Verificar se os clubes cumprem todo o calendário.
- [ ] Verificar se jogadores são transferidos sem duplicação.
- [ ] Verificar se nenhum botão importante fica sem função.
- [ ] Testar ao menos uma temporada inteira em um dispositivo Android.
- [ ] Investigar erros nos logs do Roblox e corrigir problemas encontrados.

## 5. Recursos futuros — não exigidos na versão 0.1

- [ ] Competições adicionais, copas e acesso/rebaixamento.
- [ ] Negociações completas, contratos e empréstimos.
- [ ] Academia de base, olheiros e staff.
- [ ] Moral, lesões e potencial dinâmico avançado.
- [ ] Mudança de emprego do manager e objetivos da diretoria.
- [ ] Representação visual das partidas em campo 2D/3D.

---

**Atenção:** o Backrooms ainda pode aparecer dentro da experiência Roblox enquanto o novo jogo não for publicado. Isso não significa que o código do Club Legacy esteja incorreto; significa que a substituição no Roblox ainda não aconteceu. Este checklist deve ser revisado após cada integração e publicação.
