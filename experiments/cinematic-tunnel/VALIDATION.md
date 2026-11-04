# Evidências e pendências — 03/11/2026

## Preservação

Base `10ba3323e3e0fc400266ebcf3d495174acca1c1a`, identificada na branch main antes das alterações. Backup remoto e local `backup/pre-cinematic-tunnel-20261103-10ba332` apontam para esse commit. Desenvolvimento exclusivamente em `experiment/cinematic-tunnel`.

Os **57 arquivos originalmente versionados** foram comparados por hash Git com a base e estão preservados byte a byte. Isso inclui todo `src/`, default.project.json principal, documentação e workflows build.yml/publish.yml. A documentação de progresso deste trabalho fica neste diretório, mantendo os registros anteriores intactos. A única adição fora do experimento é `.github/workflows/cinematic-tunnel.yml`.

Antes da implementação foram lidos: AGENTS.md, CL27_PLAN.md, CL27_PROGRESS.md, default.project.json, Scene, App, Scope, HomeHUD, TransitionFX, ambos os workflows e os validadores/runners/specs existentes em tools/. A cena principal usa Workspace local, câmeras Scriptable, snapshot da iluminação e descarte de efeitos/conexões. O novo módulo mantém essas responsabilidades explícitas e independentes.

## Auditoria 1 — composição e fidelidade

O anexo foi inspecionado diretamente; as barras laterais foram separadas mentalmente da área útil 16:9. Registradas estimativas de ponto de fuga, altura de câmera, lente, dimensões, inclinação, cores, distribuição das fontes e névoa em REFERENCE_ANALYSIS.md.

Foi revisada uma projeção matemática dos descritores para conferir a silhueta, abertura, continuidade das bases, diagonais e posição das luminárias. Esse diagnóstico contém apenas polígonos, sem motor Roblox, iluminação, materiais ou névoa física. **Não é uma captura Roblox e não comprova fidelidade visual.** A base foi estendida até atrás da câmara distante para eliminar piso ausente nesse recuo. As placas triangulares complementares têm transformações com determinante positivo; o portal está aberto e não foi preenchido por um painel Neon gigante.

Limitações conhecidas: abertura mais regular que a referência, perspectiva aproximada, materiais nativos sem textura personalizada, ausência de névoa turbulenta e reflexos planares reais. O contraste e a luminosidade definitivos ainda precisam de calibração visual no Studio.

## Auditoria 2 — movimento e estados

**398 asserções** em Luau real com APIs substituídas: construção dos módulos reais e bootstrap, ausência de alterações globais por padrão, perfis Low/Medium/High, qualidade inválida, troca repetida de qualidade, estado desativado preservado, três ciclos de destruição, restauração da câmera original e de efeitos/Atmosphere/Sky, preservação de câmera tomada por outro sistema, posse exclusiva e rollback após falha de construção.

A câmera fixa e movimento reduzido mantêm zero callbacks de render. Movimento opcional cria somente um, desconectado ao desativar ou destruir. Os testes exercitam atributos reais do bootstrap e verificam que sua destruição remove callbacks e o modelo. A mudança de origem foi testada com translação numérica. Não houve captura de animação real ou certificação de suavidade no Roblox.

## Auditoria 3 — integridade e compilação

- Luau oficial **0.745**: sintaxe aprovada nas seis fontes de runtime e dois arquivos Luau de ferramentas/testes.
- Estrutura: todos os seis arquivos de runtime mapeados pelo projeto independente; require locais resolvidos; nenhum asset ID externo, HTTP de produto, música ou modelo importado.
- Geometria: **8.442 verificações de ortogonalidade** nos descritores dos três perfis, além de determinantes, tamanhos positivos, chão nivelado, alinhamento das bases, contagem de luminárias, limites de luzes/alcances e limites estruturais do corredor.
- Rojo **7.7.1**: os três perfis foram compilados para `.rbxlx`. Validação XML confere partes, transformações, cores, materiais, flags de geometria, luzes, direção, alcance, sombras, câmera serializada, integridade de referências e seis fontes incorporadas idênticas. O artefato padrão final é Medium: **334 partes / 20 luzes**.
- Catálogo API Roblox: classes, enums, propriedades críticas, descritores dinâmicos e propriedades do template conferidos. Snapshot SHA256 `0962f777e3085487e368ed019c35bdb07cd02f6659aa7212dc2ad6e24bb41efe`. É uma validação estática; não prova permissões ou execução do motor.
- Ferramentas oficiais Luau e Rojo baixadas com os SHA256 fixados no workflow principal. Python `py_compile`, Bash `-n`, **actionlint 1.7.12** no novo workflow e `git diff --check` aprovados.

Contagens:

| Perfil | Partes | Luzes locais | Com sombras locais |
| --- | ---: | ---: | ---: |
| Low | 238 | 12 | 0 |
| Medium | 334 | 20 | 0 |
| High | 366 | 36 | 10 |

Regressão do projeto principal, sem alterações em suas fontes:

- **34 fontes**: sintaxe, estrutura, rotas e require aprovados.
- **653 verificações de dados** aprovadas.
- Harness existente: **534 montagens / 388 callbacks / 241 asserções** aprovados.
- Estados do App: **231 asserções** aprovadas. A mensagem de falha simulada na troca de Settings é parte do teste de recuperação esperado.
- Rojo recompilou o projeto principal e seu validador XML confirmou as **34 fontes idênticas**.

Os harnesses usam doubles da API. Testes automatizados não validam renderização, rasterização de WedgePart, aparência de metal, reflexos, sombras perceptuais, segurança de propriedades em runtime ou FPS.

## Reproduzir as verificações

O comando de build documentado no README executa sintaxe, estrutura, testes de ciclo de vida, bake, Rojo e validação XML. Para validar também um snapshot local do catálogo, adicionar `--api-dump /caminho/API-Dump.json`. A opção não baixa arquivos ou credenciais.

Para a regressão principal:

```bash
python3 tools/validate.py --compiler /tmp/cl27-tools/luau/luau-compile
python3 tools/run-data.py --runtime /tmp/cl27-tools/luau/luau
python3 tools/run-runtime-smoke.py --runtime /tmp/cl27-tools/luau/luau
python3 tools/run-app-states.py --runtime /tmp/cl27-tools/luau/luau
/tmp/cl27-tools/rojo/rojo build default.project.json --output /tmp/cl27-main.rbxlx
python3 tools/validate.py --place /tmp/cl27-main.rbxlx
```

## Pendências de validação real

1. Abrir o artefato no Studio e dar Play. Comparar capturas 16:9 por regiões com o anexo original.
2. Inspecionar encontros dos painéis triangulares e contrafortes lateralmente; conferir costuras, faces e sombras do motor real.
3. Calibrar exposição, saturação, Bloom, fog e reflexão do piso com a qualidade gráfica fixada e registrada.
4. Conferir restauração ao excluir o bootstrap no cliente e ao usar explicitamente `Destroy()` numa integração de teste.
5. Testar viewport de Android horizontal, movimento reduzido e os três perfis; medir memória, custo das luzes, pausas de reconstrução e FPS em hardware identificado.

**Roblox Studio e Player não estavam disponíveis. Não houve render Roblox, medição de FPS ou aprovação visual. Nenhum workflow de publicação foi executado; não houve merge ou publicação no Roblox.**
