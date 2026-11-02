# CL 27 — Interface independente para Roblox

UI/UX nativa em Luau, com identidade própria em grafite, lima e marfim. As referências fornecidas orientaram a hierarquia, a composição cinematográfica, os painéis esportivos e a navegação. Não há logotipos, fotografias, escudos de clubes reais ou dependências de catálogo.

O Club Legacy continua em `src/` e `default.project.json`, sem alterações. Não é necessário movê-lo nem duplicá-lo em `Jogo-Original`. CL 27 possui ponto de entrada, dados e mapeamento próprios em `cl27.project.json`; nenhum script do jogo original é executado nesse projeto.

## Integração

Na raiz do repositório, com Rojo 7.7.1:

```sh
rojo build cl27.project.json --output cl27.rbxlx
```

Abra o arquivo gerado no Roblox Studio e use **Play**. Para sincronizar com o plugin Rojo, execute `rojo serve cl27.project.json` e conecte o plugin no Studio ao servidor acessível. O ambiente de nuvem não estabelece automaticamente conexão com um Studio no seu computador. Use o arquivo `.rbxlx` quando não houver conectividade.

Use este projeto em um place separado durante a integração. O workflow de publicação do Club Legacy foi preservado e não publica CL 27. Nenhuma chave Roblox, API Open Cloud ou DataStore é necessária para esta interface.

## Conteúdo implementado

| Tela | Interações |
| --- | --- |
| Início | Apresentação 3D, central e atalhos de elenco, táticas e identidade |
| Visão geral | Próxima partida, notícias, orçamento e objetivos |
| Elenco | 18 atletas, filtros, atributos, seleção e apresentação 3D |
| Táticas | Campo visual, três formações, mentalidade e trocas sem duplicar titulares |
| Calendário | Julho–setembro de 2027, dias selecionáveis, agenda e resultados editoriais |
| Transferências | 12 perfis, pesquisa, filtros, favoritos e propostas em rascunho |
| Finanças | Orçamento, salários, gráficos e categorias de receitas/despesas |
| Desenvolvimento | Planos individuais e comparação de atributos e potencial |
| Competições | Classificação, estatísticas e acesso aos confrontos |
| Personalização | Escudos geométricos, três uniformes e paletas refletidas no atleta 3D |
| Configurações | Movimento reduzido, qualidade 3D, texto, áudio e controles |

Tudo está em português brasileiro. Dados e resultados são fictícios e determinísticos; escolhas permanecem apenas na sessão e são reiniciadas ao sair. Não há simulação de partidas, contratação real, progressão automática, rede ou persistência de carreira.

Mouse/toque usam botões e rolagem nativos. Arraste o atleta para girar. **Q/E** alternam telas e **Backspace** retorna; no controle, **LB/RB**, **A** e **B**. O menu padrão Roblox continua usando **Esc**.

## Organização e desempenho

- `Main.client.luau`: estado, roteamento, histórico limitado, adaptação de tela e entrada.
- `Components/`: UI reutilizável, estúdio 3D e áudio local opcional.
- `Animations/Scope.luau`: eventos e tweens vinculados ao tempo de vida da tela.
- `Screens/`: as 11 telas; `Config/Theme.luau`: identidade visual.
- `Data/Career.luau`: elenco, mercado, calendário, liga e finanças.
- `Assets/KitDetails.luau`: emblemas e números geométricos para o ViewportFrame.

Só a tela ativa mantém instâncias e conexões. Os personagens são modelos Roblox geométricos originais em `WorldModel`, com câmera própria, enquadramento, iluminação e movimento sutil. Não dependem de `SurfaceGui` dentro do viewport. Qualidade Alta atualiza movimentos em até 60 Hz; Equilibrada limita a 30 Hz e Econômica desativa a atualização contínua. Isso não garante a taxa de quadros do dispositivo. O áudio usa um som curto nativo do cliente; indisponibilidade de carregamento é indicada nas configurações, sem impedir a navegação.

## Validação reproduzível

Linux x86_64, com Bash, Python 3, curl, unzip e sha256sum:

```sh
bash CL-27/Tools/install.sh /tmp/cl27-tools
python3 CL-27/Tests/validate.py --tools /tmp/cl27-tools
```

O instalador fixa Luau 0.745 e Rojo 7.7.1 com TLS e SHA-256. O runner compila a sintaxe, testa coerência dos dados, callbacks das 11 telas e limpeza das animações, compila os dois projetos e confere os scripts no artefato. Os testes de telas e TweenService usam doubles explícitos; não executam o motor Roblox. O workflow `CL 27 | Validar interface independente` executa as mesmas verificações e disponibiliza `cl27-studio`, sem publicar experiências.

**Validação pendente no Studio:** enquadramento e renderização 3D, transições visuais, áudio disponível no cliente, seleção real por gamepad, safe areas, texto ampliado, celular em retrato/paisagem e perfil de FPS/memória em dispositivos reais. Não foi possível executar Roblox Studio neste ambiente Linux; qualidade visual e 60 FPS ainda não foram homologados.
