# my-skills

Repositório único das minhas skills de agentes de código. Uma pasta por skill em `skills/`, cada uma com um `SKILL.md` no formato [Agent Skills](https://agentskills.io/specification). Um script cria symlinks dessas pastas nos diretórios globais de cada agente. Assim, editar uma skill aqui (ou rodar `git pull`) atualiza Claude Code, Codex, Cursor, OpenCode, Kiro, Gemini CLI e Copilot ao mesmo tempo.

## Instalar

```sh
git clone <este-repo> ~/projects/my-skills
cd ~/projects/my-skills
make dry-run    # mostra o que vai mudar
make install    # valida as skills e cria os symlinks
```

Reinicie os agentes que estiverem abertos para recarregarem as skills.

| Destino (padrão) | Agentes que leem |
| --- | --- |
| `~/.agents/skills` | Codex, Cursor, OpenCode, Gemini CLI, Amp |
| `~/.claude/skills` | Claude Code (e, por compatibilidade, Cursor, OpenCode, Copilot) |
| `~/.kiro/skills` | Kiro IDE e kiro-cli (só se `~/.kiro` existir) |

Destinos opcionais: `make install TARGETS="cursor opencode codex gemini copilot"`. Normalmente não são necessários; veja [docs/referencias.md](docs/referencias.md#onde-cada-harness-procura-skills-globais).

O instalador:

- só cria **symlinks por skill**, então os diretórios dos agentes continuam aceitando skills de outras fontes;
- move qualquer cópia real que já exista para `~/.local/state/my-skills/backups/<data>/` em vez de apagá-la;
- remove links para skills que foram renomeadas ou apagadas do repo;
- avisa quando a skill também está registrada no `npx skills` (`~/.agents/.skill-lock.json`). Nesse caso rode `npx skills remove -g <nome>` e depois `make install`. Sem isso, um `npx skills update` escreveria através do symlink, ou seja, dentro deste repo.

Outros comandos:

```sh
make list        # skills e destinos
make uninstall   # remove só os links que apontam para este repo
make validate    # checa o frontmatter de todos os SKILL.md
```

Requisitos: bash, git, Node 18+ (só para atualizar skills de terceiros).

## Skills

Lista completa com o commit de origem: `make vendored`.

| Origem | Skills |
| --- | --- |
| **Minhas** | [write-article](skills/write-article/SKILL.md): escreve artigos e posts no formato de cada plataforma (LinkedIn, blog, Medium), a partir de fontes, e termina com o humanizer. Para adicionar uma plataforma, crie `skills/write-article/platforms/<nome>.md` e liste no passo 3 do `SKILL.md` |
| [blader/humanizer](https://github.com/blader/humanizer) | [humanizer](skills/humanizer/SKILL.md): reescreve texto com cara de IA para soar como quem escreveu, sem mudar o conteúdo |
| [mattpocock/skills](https://github.com/mattpocock/skills) (as 27 do plugin `mattpocock-skills`; guia: [Skills do Matt Pocock](https://claude.ai/artifact/QuypJdJuYtGhmbbSEhTTdf)) | **Fluxo:** [setup-matt-pocock-skills](skills/setup-matt-pocock-skills/SKILL.md), [ask-matt](skills/ask-matt/SKILL.md), [grill-with-docs](skills/grill-with-docs/SKILL.md), [grill-me](skills/grill-me/SKILL.md), [grilling](skills/grilling/SKILL.md), [wayfinder](skills/wayfinder/SKILL.md), [to-spec](skills/to-spec/SKILL.md), [to-tickets](skills/to-tickets/SKILL.md), [triage](skills/triage/SKILL.md), [implement](skills/implement/SKILL.md), [implement-spec](skills/implement-spec/SKILL.md), [pr](skills/pr/SKILL.md), [retro](skills/retro/SKILL.md). **Apoio:** [tdd](skills/tdd/SKILL.md), [diagnosing-bugs](skills/diagnosing-bugs/SKILL.md), [mp-code-review](skills/mp-code-review/SKILL.md), [research](skills/research/SKILL.md), [prototype](skills/prototype/SKILL.md), [wizard](skills/wizard/SKILL.md), [to-questionnaire](skills/to-questionnaire/SKILL.md), [improve-codebase-architecture](skills/improve-codebase-architecture/SKILL.md), [domain-modeling](skills/domain-modeling/SKILL.md), [codebase-design](skills/codebase-design/SKILL.md), [handoff](skills/handoff/SKILL.md), [wait-what](skills/wait-what/SKILL.md), [teach](skills/teach/SKILL.md), [writing-for-agents](skills/writing-for-agents/SKILL.md) |

O `code-review` do Matt está instalado como **`mp-code-review`**, para não colidir com o `/code-review` nativo do Claude Code. As referências a ele dentro de `implement`, `implement-spec`, `ask-matt` e `tdd` são reescritas automaticamente a cada atualização (`rename:` no `vendor.sources`). Fora do Claude Code os comandos não têm o prefixo `mattpocock-skills:`: é só `/to-spec`, `/implement` etc.

## Criar uma skill

```sh
mkdir skills/minha-skill
$EDITOR skills/minha-skill/SKILL.md
make install
```

Frontmatter mínimo (o `name` tem que ser igual ao nome da pasta):

```markdown
---
name: minha-skill
description: O que a skill faz. Use quando o usuário pedir X, mencionar Y ou estiver fazendo Z.
---

# Minha skill

Instruções...
```

Pastas que começam com `_` (ex.: `skills/_rascunho`) são ignoradas pelo instalador. As convenções do repo estão em [AGENTS.md](AGENTS.md).

## Skills de terceiros: como atualizar

Como no [repo do Akita](https://github.com/akitaonrails/my-skills), skills de terceiros são **copiadas** para cá sem o `.git` (nada de submodule). Dois arquivos controlam isso:

- [`vendor.sources`](vendor.sources), editado à mão, diz **o que** puxar de cada repo. Pode ser uma pasta, `.` para skill na raiz, ou `@.claude-plugin/plugin.json` para todas as skills do plugin. Com o manifest, skills que o autor adicionar ou remover entram ou saem sozinhas. Também aceita `exclude:a,b` e `rename:a=b`.
- [`vendor.lock`](vendor.lock), gerado pelo script, registra o commit de origem de cada skill.

### Por comando

```sh
make outdated                         # só checa: compara o lock com o upstream (git ls-remote)
make update                           # puxa tudo, valida, reinstala os links e mostra o que mudou
make update ONLY=mattpocock/skills    # só uma fonte (ou ONLY=humanizer)
git diff skills/                      # revise
git commit -am "chore(vendor): update skills"
```

Como os agentes leem o repo pelos symlinks, o conteúdo novo vale assim que o `make update` termina. Se não gostar do diff, `git checkout -- skills vendor.lock` volta ao estado anterior.

### Automático (GitHub Action)

Depois que o repo estiver no GitHub, o workflow [`update-vendored.yml`](.github/workflows/update-vendored.yml) roda toda segunda-feira às 09:00 UTC (ou pela aba Actions → *Run workflow*). Ele abre ou atualiza um PR `vendor/update` com o diff. Faça o merge e depois rode `git pull` na máquina. Para funcionar, ative *Settings → Actions → General → Allow GitHub Actions to create and approve pull requests*.

O PR passa pela sua revisão porque o texto de uma skill vira instrução para todos os seus agentes. Atualizar sem revisar seria aceitar mudanças de prompt de terceiros às cegas.

### Adicionar outra fonte

Acrescente uma linha no `vendor.sources` e rode `make update`. Exemplos:

```
dono/repo   main  skills/uma-skill skills/outra       # pastas específicas
dono/repo   v2.0  @.claude-plugin/plugin.json exclude:x  # um plugin inteiro numa tag, menos x
dono/repo   main  simplify  rename:simplify=dono-simplify  # evita colisão com skill que você já tem
```

Duas fontes não podem gerar skills com o mesmo nome. O script recusa e pede um `rename:`.

Não edite pastas vendored: a próxima atualização sobrescreve a pasta, e `make update` recusa rodar enquanto houver mudanças não commitadas nela. Para adaptar uma skill, copie para outro nome.

O humanizer traz o próprio validador: `python3 skills/humanizer/scripts/validate-package.py`.

## Referências

Diferenças entre akitaonrails/my-skills, mattpocock/skills e affaan-m/ECC, e o que foi aproveitado de cada um: [docs/referencias.md](docs/referencias.md).
