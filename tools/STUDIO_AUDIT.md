# Validação visual em Roblox Studio

Este roteiro exige execução real. Compilação Rojo e análise de fontes não aprovam fidelidade visual.

1. Baixe o artefato `club-legacy-rbxlx` do Actions e abra `club-legacy.rbxlx` no Roblox Studio.
2. Execute **Play** para iniciar o LocalScript. A apresentação não cria personagem controlável.
3. Confira o Output: nenhum erro de propriedade, require, câmera ou conexão deve ocorrer.
4. Capture cada tela em 1600×900 ou 1280×720. Repita em 1920×1080, 4:3 e horizontal de celular, respeitando recortes seguros.
5. Compare as cinco referências por regiões: menu à esquerda, atleta à direita, piso e telão no interior; céu e arquitetura no exterior; campo/banco/ficha no elenco; simetria dos clubes; atletas e camisas nos uniformes.
6. Selecione todos os titulares e reservas. Compare retrato, nome, overall e atributos atualizados. Troque formação e atribuições.
7. Percorra os clubes dos dois lados, filtros e uniformes. Confira camisa, calção e meias dos atletas; confirme que o fluxo termina na apresentação e não inicia partida.
8. Percorra todas as 15 rotas por mouse, toque e controle. Volte repetidamente e confira ausência de acúmulo de cenas/conexões.
   Selecione também o último atleta nas listas de Desenvolvimento, Atribuições e Transferências; a seleção deve manter a rolagem e o foco equivalente do controle ao atualizar os detalhes. Confira as duas linhas de reservas integralmente visíveis e a confirmação invalidada ao trocar uniforme na Personalização.
9. Grave as transições com ferramenta de captura real, preferencialmente a 60 FPS. Inspecione início, meio, fim e interrupções rápidas, incluindo troca de clube e uniforme. Registre FPS da gravação separadamente do FPS do jogo.
10. Meça desempenho com Stats/MicroProfiler em hardware identificado. Registre contagem de partes, memória, FPS mediano e piores quedas. Não deduza 60 FPS do estilo das animações.
11. Ative movimento reduzido e qualidade baixa; confira legibilidade, câmera e continuidade.
12. Após cada correção, refaça as capturas das telas afetadas. Registre evidências e pendências em `CL27_PROGRESS.md`.

Publicação: configure `ROBLOX_UNIVERSE_ID` e `ROBLOX_PLACE_ID` no destino revisado, e `ROBLOX_API_KEY` como secret. O workflow manual não contém IDs antigos nem publica durante pushes. A confirmação do Place ID é exigida apenas ao escolher publicar.
