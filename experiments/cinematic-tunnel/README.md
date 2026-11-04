# CL 27 — túnel cinematográfico experimental

Projeto Rojo independente inspirado em `1000159289.jpg`. Não é importado pelo jogo principal. A geometria e as luzes são geradas por código e incorporadas ao `.rbxlx`, com câmera de apresentação. A fidelidade visual definitiva e o desempenho dependem de execução real no Roblox; não houve Studio/Player neste ambiente.

## Proteção e escopo

- Base: `main` em `10ba3323e3e0fc400266ebcf3d495174acca1c1a`.
- [Backup preservado](https://github.com/blokadahub/club-legacy-roblox/tree/backup/pre-cinematic-tunnel-20261103-10ba332).
- Desenvolvimento: `experiment/cinematic-tunnel`, sem merge automático.
- Nenhuma alteração em `src/`, no projeto Rojo principal, no lobby, personagem, sistemas, música ou nos workflows existentes. O único arquivo externo ao diretório experimental é o workflow exclusivo de compilação.
- Nenhuma publicação Roblox, upload de assets ou dependência de modelos externos. O experimento não inclui HUD, botões ou gameplay.

## Arquivos criados

```text
.github/workflows/cinematic-tunnel.yml
experiments/cinematic-tunnel/
  .gitignore
  default.project.json
  README.md
  REFERENCE_ANALYSIS.md
  VALIDATION.md
  src/
    Tunnel.client.luau
    NoCharacter.server.luau
    TunnelGeometry.luau
    TunnelScene.luau
    TunnelLighting.luau
    TunnelCamera.luau
  tools/
    install-tools.sh
    build.py
    export.luau
    test.py
    runtime.spec.luau
```

Os diretórios `.generated/` e `dist/` são gerados e ignorados pelo Git. Não editar o XML ou o modelo gerado: alterar as fontes e recompilar.

## Arquitetura e composição

Ver [análise da imagem e estimativas](REFERENCE_ANALYSIS.md). O corredor tem 34 × 20,5 × 96 studs e oito vãos. Paredes inclinadas 8° para dentro, pares de placas triangulares nativas `WedgePart`, nervuras diagonais grossas, juntas, montantes e ventilação formam as laterais. O teto possui painéis inclinados, travessas, conduítes e rebaixo técnico central. A abertura final tem pilares e lintel próprios, com uma câmara maior atrás, até z=-115.

`TunnelGeometry` produz descritores numéricos sem serviços Roblox. O bake e a construção em runtime usam os mesmos descritores. `TunnelScene` instancia um `Model` independente, permite transformação por `origin` e controla sua reconstrução/destruição. A arquitetura é decorativa, ancorada e sem colisão, toque ou consultas físicas. Uma futura integração que permita caminhar exigirá colisores simples separados.

`build.py` executa Luau real para exportar os descritores, escreve um modelo `.rbxmx`, chama Rojo e configura a referência serializada da câmera. O `.rbxlx` já contém o corredor em modo de edição. Ao dar Play, o bootstrap remove a prévia e constrói a versão local controlada pelos módulos. Não existem duas cópias da arquitetura no cliente após a inicialização.

## Luzes e materiais

- Azul frio no rebaixo superior esquerdo; verde nas bases dos dois lados.
- Oito luminárias âmbar na sanca direita e dez pequenos marcadores baixos na região distante.
- Dois emissores na câmara final: lavagem turquesa superior e horizonte verde suave, sem uma parede inteira de Neon.
- `PointLight` para fontes pontuais e fitas selecionadas; `SurfaceLight` para luminárias e fundo. Alcances entre 7 e 29 studs, brilhos entre 0,32 e 1,6. Nenhum emissor animado.
- Metal escuro nas placas e piso, concreto na base/portal e Neon apenas nos núcleos luminosos. Placas de piso com pequenas variações de cor e juntas reais; `Reflectance=0.035`, sem reflexos planares ou piso espelhado.
- Bloom 0,12 / Size 20 / Threshold 1,15; correção de cor com Contrast 0,12 e Saturation -0,08. Névoa limitada por distância, de 74 até 168 studs. A decisão de usar `Fog` está explicada na análise. Sem partículas ou atmosfera global que clareie o primeiro plano.

As fitas continuam visíveis em todas as qualidades; a quantidade de emissores reais muda. Em Low, Bloom é desativado. Sombras de luzes locais são habilitadas somente em High; a iluminação global e as sombras da arquitetura continuam configuradas.

| Perfil | Partes | Luzes | Luzes com sombras |
| --- | ---: | ---: | ---: |
| Low | 238 | 12 | 0 |
| Medium, padrão | 334 | 20 | 0 |
| High | 366 | 36 | 10 |

Contagens determinísticas, sem incluir Model, efeitos e câmeras. Não equivalem a metas ou medições de FPS. A troca de qualidade reconstrói a arquitetura uma vez, sem fazer trabalho a cada frame; pode causar uma pausa que precisa ser medida no Android. A prévia editável continua existindo no servidor da apresentação independente; o cliente a substitui localmente. Em integração futura, incluir somente os módulos reutilizáveis, sem essa prévia.

## Câmera e controles de inspeção

Posição `(0, 5.2, 8)`, alvo `(-16, 10, -112)`, FOV vertical de 54°, câmera Scriptable. O olho está centralizado na largura, com orientação suave para cima e à esquerda para deslocar a convergência à direita. O enquadramento de referência deve ser julgado em 16:9 horizontal. Outras proporções mantêm a lente vertical e mostram uma área horizontal diferente.

Padrão: câmera fixa, movimento reduzido ativado, **zero conexões RenderStepped**. O movimento opcional é um deslocamento longitudinal limitado a ±0,18 stud, em um ciclo de 100 segundos. Não desloca o cenário.

Durante Play, no Explorer do **cliente**, encontre `Players > seu jogador > PlayerScripts > CinematicTunnel > Tunnel`. Altere Attributes:

| Attribute | Valores |
| --- | --- |
| Quality | `Low`, `Medium`, `High`, com maiúsculas exatas |
| EffectsEnabled | boolean; controla luzes reais, pós-processamento e névoa, mantendo a arquitetura e seus materiais |
| Animate | `true` para solicitar deslocamento |
| ReducedMotion | `true` bloqueia deslocamento; usar `false` junto de Animate para inspecioná-lo |

Os mesmos atributos podem ser definidos no template Rojo para a próxima compilação. `--quality` prevalece sobre Quality no artefato compilado. Excluir o LocalScript do cliente durante Play executa a limpeza e restaura os recursos assumidos. **Desativar um LocalScript não é um mecanismo de descarte**: integradores devem chamar `Destroy()` explicitamente.

## Compilar e obter o arquivo

[Workflow exclusivo de compilação](https://github.com/blokadahub/club-legacy-roblox/actions/workflows/cinematic-tunnel.yml).

1. Abrir o PR e acessar o check **CL 27 | Experimento de túnel**, ou selecionar a branch experimental em Actions. O workflow executa em push e pull request; não publica no Roblox.
2. Na execução aprovada, baixar **cinematic-tunnel-rbxlx**, disponível por 14 dias. Extrair o ZIP para obter `cinematic-tunnel.rbxlx` e `counts.json`.
3. No Roblox Studio, usar **File > Open from File** e abrir o `.rbxlx`. O modelo já estará presente. Dar **Play**, em contexto de cliente, para ativar a câmera e o controle local. **Run** sem cliente não inicia o LocalScript.
4. Testar primeiro em 16:9 horizontal e qualidade gráfica manual conhecida. Capturar uma imagem sem interfaces do Studio e comparar com o anexo. Não usar Publish para este teste.

Build local, a partir da raiz do repositório, em Linux x86_64 com Python 3.10+, curl, unzip e sha256sum:

```bash
bash experiments/cinematic-tunnel/tools/install-tools.sh /tmp/cl27-tools
python3 experiments/cinematic-tunnel/tools/build.py \
  --runtime /tmp/cl27-tools/luau/luau \
  --compiler /tmp/cl27-tools/luau/luau-compile \
  --rojo /tmp/cl27-tools/rojo/rojo
```

Usa **Luau 0.745** e **Rojo 7.7.1**, oficiais, com os mesmos checksums do workflow principal. Em Windows/macOS, instalar essas versões para a plataforma e fornecer os respectivos caminhos; o bake Python usa somente a biblioteca padrão. O compilador não faz análise de tipos com definições da API Roblox.

Saída: `experiments/cinematic-tunnel/dist/cinematic-tunnel.rbxlx`. Adicionar `--quality Low` ou `--quality High` seleciona outro perfil. O comando executa testes antes da compilação e compara fontes, cores, transformações, materiais, luzes e referências no XML final.

Depois do primeiro bake também é possível executar Rojo diretamente com `experiments/cinematic-tunnel/default.project.json`, que referencia `.generated/preview.rbxmx`. Para artefatos finais, preferir sempre `build.py`: ele atualiza a prévia, sincroniza o perfil e configura a câmera serializada. `rojo serve` pode usar esse mesmo template após o bake, mas é necessário recompilar após alterar a geometria para atualizar a prévia de edição.

## Revisão e correções no Studio

| Problema observado | Ajuste nas fontes |
| --- | --- |
| Corredor estreito, teto baixo ou profundidade incorreta | Conferir primeiro a lente e proporção do viewport. Alterar dimensões e posições em `TunnelGeometry.build`; os campos Width/Height/Length documentam a escala e não recalculam automaticamente os detalhes. |
| Convergência fora da referência | Ajustar CameraTarget e FieldOfView em TunnelGeometry. Recompilar; não compensar deslocando todas as luzes. |
| Câmera de personagem ou imagem diferente durante Run | Usar Play no cliente; conferir Output e presença de Tunnel em PlayerScripts. |
| Piso excessivamente preto | Aumentar discretamente Brightness ou Ambient em TunnelLighting; conferir alcance das luminárias. Não tornar o piso Neon. |
| Imagem clara, lavada ou Bloom forte | Conferir qualidade gráfica; reduzir ExposureCompensation/Bloom em TunnelLighting. Sincronizar os valores de prévia no default.project.json. |
| Névoa esconde painéis próximos | Aumentar FogStart/FogEnd. Em integração, verificar se há Atmosphere de outro sistema ativo. |
| Fitas ou luminárias desalinhadas | Conferir os centros dos vãos e posições do rebaixo/housing no gerador; usar a prévia e inspecionar de lado. |
| Pausa ou custo alto no Android | Testar Low, manter câmera fixa e medir MicroProfiler/memória no aparelho identificado; reduzir emissores antes de remover silhuetas importantes. |

Comparar piso, abertura, teto e paredes separadamente, incluindo capturas em movimento reduzido. Inspecionar os painéis triangulares de lado para verificar costuras e encontros dos contrafortes. Registrar capturas, resolução, dispositivo, nível gráfico e mudanças antes de aprovar a aparência. Ver [evidências e pendências](VALIDATION.md).

## API e integração futura

Copiar/mapear **somente os quatro ModuleScripts** Geometry, Scene, Lighting e Camera para um namespace explícito. Não mapear o diretório `src/` experimental inteiro no CL 27: ele contém os bootstraps da apresentação independente. Manter um único bootstrap cliente no jogo principal.

```lua
local TunnelScene = require(modules.TunnelScene)
local tunnel = TunnelScene.new({
    parent = workspace,
    origin = CFrame.new(0, 0, 0),
    quality = "Medium",
}) -- somente arquitetura/luzes locais; não assume câmera nem Lighting
tunnel:ApplyQuality("Low")
tunnel:SetEffectsEnabled(false)
tunnel:Destroy() -- idempotente
```

Para uma tela cinematográfica exclusiva, passar `takeOverLighting=true, camera=true`, e opcionalmente `animate=true, reducedMotion=false`. Esses recursos têm posse exclusiva entre instâncias do túnel. A câmera anterior não é modificada; uma câmera própria é criada e restaurada ao sair. Se outro sistema substituir CurrentCamera durante a apresentação, o descarte preserva essa escolha. Os efeitos/Atmosphere/Sky anteriores são temporariamente retirados e devolvidos com identidade e valores preservados; propriedades alteradas de Lighting são restauradas. Outro controlador de iluminação não deve escrever simultaneamente nessas propriedades.

Plano de integração, sujeito a decisão posterior:

1. Aprovar capturas reais da apresentação independente e medir os três perfis no Android.
2. Introduzir os quatro módulos no mapeamento Rojo principal em PR separado, sem trocar o lobby por padrão.
3. No proprietário da rota/cena, destruir a Scene atual e seus callbacks antes de assumir câmera/iluminação do túnel. Registrar `function() tunnel:Destroy() end` no Scope da rota. No retorno, destruir o túnel e reconstruir a cena oficial com as configurações atuais.
4. Conectar qualidade e movimento reduzido às configurações existentes, sem criar outro menu. Para uma transição, a camada TransitionFX continua sob controle do App; o túnel fornece somente o ambiente.
5. Para lobby ou entrada navegável, projetar colisores/spawn em trabalho separado. Para introdução e transição de menus, manter o cenário decorativo atual. Validar interrupção de navegação, restauração e ausência de luzes/câmeras residuais.

Nenhum passo de integração foi aplicado ao CL 27 neste experimento.
