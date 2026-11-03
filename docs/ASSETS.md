# Ativos e identidade original

| Ativo | Implementação | Dependência |
| --- | --- | --- |
| Marca CL 27 | Tipografia e traços geométricos em `UI.logo` e SurfaceGui | Fontes nativas Roblox |
| Oito escudos | Construção geométrica, monograma e paleta em `UI.badge` | Nenhuma imagem externa |
| Vinte e quatro uniformes | Três paletas por clube; camisa, calção, meias, gola, faixa e número | Parts, materiais e SurfaceGui nativos |
| Vinte e dois atletas | Nomes, aparência, atributos e números fictícios | `Data.luau` |
| Personagens R15 | Quinze segmentos, Humanoid, Motor6D, attachments, rosto e cabelo geométricos | `Rig.luau`, sem catálogo ou animação externa |
| Galeria do legado | Piso, juntas, telão, vigas, diagonais, luzes e bola decorativa | `Scene.luau` |
| Centro de treinamento | Sede curva, centro esportivo, campo, árvores, bandeiras e gol cenográfico | `Scene.luau` |
| Arena de apresentação | Painéis cromáticos, estruturas, piso e iluminação | `Scene.luau` |
| Transição | Gradiente, diagonais, linha e marca própria | ScreenGui / CanvasGroup |

As cinco fotografias fornecidas foram usadas apenas como referência de composição. Fotografias, escudos oficiais, patrocinadores e uniformes dessas imagens não estão incorporados ao projeto. Não há `require` por asset ID, download de modelo em runtime ou dependência de biblioteca de UI.

Texturas dos materiais, céu e fontes pertencem aos recursos nativos disponibilizados pelo Roblox. A apresentação usa animação procedural e TweenService; não exige upload de animações ou imagens para abrir a experiência compilada.
