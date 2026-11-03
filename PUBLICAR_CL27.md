# Publicar o CL 27 no Roblox — procedimento seguro

Este guia usa **GitHub Actions + Rojo + Roblox Open Cloud**, sem exigir que o computador fique conectado durante a publicação. O jogo publicado é a versão compilada do `default.project.json` da branch `main`.

**Estado:** o workflow de compilação já passou, mas ainda é necessária a configuração privada da experiência e da chave Roblox. A compilação não comprova o resultado visual no Roblox Studio.

## 1. Escolher o destino correto

Use preferencialmente uma **experiência privada de testes** para a primeira publicação. Não presuma que os IDs da versão antiga do Club Legacy sejam os corretos.

1. O destino autorizado para substituir o conteúdo anterior da Backrooms é **Universe ID `9749365367`**, **Place ID `86256105108811`**. São valores públicos já configurados no workflow e confirmados pelo proprietário.
2. Abra [Creator Dashboard](https://create.roblox.com/dashboard/creations) na conta proprietária e confirme visualmente que esse par identifica a experiência desejada.
3. Abra a experiência, vá à área **Places** e confirme o Place ID mostrado no painel.
4. O workflow agora consulta a API Roblox para validar que o Place ID pertence ao Universe ID antes de publicar. A publicação ficará bloqueada caso a relação não seja confirmada.

## 2. Criar uma chave Open Cloud restrita

1. No [Creator Dashboard](https://create.roblox.com/dashboard/credentials), abra **API Keys** e crie uma chave específica para publicar o CL 27.
2. Restrinja o acesso à experiência escolhida e conceda somente a permissão de publicação de lugares: **universe-places:write** (API `universe-places`, operação **Write**).
3. Copie a chave e guarde-a diretamente no GitHub. **Não envie o valor por chat, issues, commits ou arquivos do repositório.**
4. Observe quaisquer configurações de expiração e segurança da chave para que sejam compatíveis com o GitHub Actions.

## 3. Configurar o GitHub

1. Abra [Settings → Environments](https://github.com/blokadahub/club-legacy-roblox/settings/environments) do repositório.
2. Crie ou abra o ambiente de publicação chamado **`roblox-production`** (escrita exata).
3. Os identificadores não precisam ser adicionados como variáveis: estão fixados no workflow após autorização para substituir a Backrooms.
4. Na seção **Environment secrets**, adicione `ROBLOX_API_KEY` com a chave criada no Creator Dashboard. Alternativamente, use um Repository secret com esse nome.
5. Se desejar, configure aprovação manual e restrição da branch `main` nas regras de proteção do ambiente.

**Atenção:** o workflow está intencionalmente vinculado à experiência Backrooms autorizada. Para mudar o destino, altere os dois IDs no workflow após nova confirmação. Nunca coloque a chave `ROBLOX_API_KEY` nos arquivos do repositório.

## 4. Compilar sem publicar

1. Abra [GitHub Actions](https://github.com/blokadahub/club-legacy-roblox/actions).
2. Selecione o workflow **CL 27 | Publicação manual Roblox**.
3. Clique em **Run workflow**, escolha a branch `main` e mantenha **`publicar` desmarcado**.
4. O workflow deve compilar `club-legacy.rbxlx` e gerar o artefato `club-legacy-rbxlx`.
5. Abra a execução e confirme o sucesso da compilação e o artefato gerado.

## 5. Publicar no Roblox

Faça esta etapa somente depois de verificar os IDs e saber qual experiência será substituída.

1. No mesmo workflow, clique novamente em **Run workflow**.
2. Selecione `main`.
3. Marque **`publicar`**.
4. Em **`confirmar_place_id`**, digite **`86256105108811`** (o Place ID confirmado).
5. Execute. O job de compilação deve terminar antes do job de publicação. Se houver aprovação do ambiente, revise e aprove.
6. No log da publicação e no resumo do job, procure o **número da versão devolvido pelo Roblox** (`versionNumber`). Sem essa confirmação, não considere a publicação concluída.
7. Confira a versão no [Creator Dashboard](https://create.roblox.com/dashboard/creations) e teste a experiência no Roblox.

**Atenção:** publicar uma versão atualiza o conteúdo do lugar; isso **não torna automaticamente uma experiência privada pública**. A visibilidade é gerenciada separadamente no Creator Dashboard.

## 6. Se houver erro

| Mensagem ou situação | Providência |
| --- | --- |
| `ROBLOX_API_KEY` ausente | Adicione o secret ao ambiente `roblox-production` ou ao repositório. |
| Universe ID ou Place ID divergente | Confira a relação no Creator Dashboard; o workflow impede publicar quando a API Roblox reporta Universe diferente. |
| Confirmação divergente | Digite exatamente `86256105108811`. |
| Erro 401 | Revise validade e permissão `universe-places:write` da chave. |
| Erro 403 | Revise permissões do proprietário e autorização da experiência. |
| Erro 404 ou 409 | Confirme que o Place ID pertence ao Universe ID informado. |
| Falha nos testes do build | Não publique: corrija o código ou configuração e execute outra compilação. |
| Build aprovado, UI visualmente ruim | Corrija no código e publique uma nova versão após testar. O build não mede fidelidade visual. |

**Nenhuma publicação é automática em pushes.** O workflow requer ação manual e confirmação exata do destino. Não adicione IDs fixos, tokens ou chaves aos arquivos versionados.

Fontes oficiais: [Roblox — publicação de lugares](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) · [GitHub — environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) · [GitHub — secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).
