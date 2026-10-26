# Referências: como cada repo organiza e distribui skills

Análise feita em 2026-10-26 sobre os HEADs de:

- [akitaonrails/my-skills](https://github.com/akitaonrails/my-skills)
- [mattpocock/skills](https://github.com/mattpocock/skills) (v1.3.1)
- [affaan-m/ECC](https://github.com/affaan-m/ECC) (v2.2.3, pacote npm `ecc-universal`)

## Resumo

| | akita/my-skills | mattpocock/skills | affaan-m/ECC |
| --- | --- | --- | --- |
| Propósito | Skills pessoais, publicadas só como exemplo ("não reutilize verbatim") | Skills para os outros instalarem e usarem | "Sistema operacional de agentes": skills, agents, commands, hooks, rules, MCP |
| Tamanho | ~25 skills | ~27 promovidas + buckets extras | ~310 skills, 71 agents, 97 commands |
| Layout | Plano: `<skill>/SKILL.md` na raiz | Buckets: `skills/{engineering,productivity,misc,in-progress,deprecated}/<skill>` | `skills/` canônico + uma pasta por harness (`.cursor/`, `.kiro/`, `.opencode/`, `.codex/`, `.gemini/`, `.agents/`...) |
| Instalação | Symlink manual por skill em cada `skills/` de harness | Plugin nativo (Claude, Codex, Copilot), `gemini skills install`, `npx skills add` para o resto; `scripts/link-skills.sh` só para dev | Instalador Node próprio (`npx ecc-universal install --guided`), plugin `ecc@ecc`, adapters por harness com dry-run, doctor e uninstall |
| Atualização | `git pull` (symlinks) | Plugin se atualiza sozinho; `npx skills update` | Re-rodar o wizard; `ecc doctor` |
| Harnesses | Claude, Codex, opencode, Kimi, `~/.agents` | Claude, Codex, Copilot, Gemini + qualquer um via `npx skills` | Claude, Codex, Cursor, OpenCode, Gemini, Kiro, Kimi, Qwen, Zed, Copilot, Antigravity, Hermes... |
| Skills de terceiros | Vendored (cópia sem `.git`), inventário no README com procedimento de update | Não vendoriza | Não vendoriza (tudo autoral ou adaptado) |
| Metadados extras | `agents/openai.yaml` em algumas | `agents/openai.yaml` em **todas** (display name do Codex + política de invocação) | Manifests JSON (`install-modules`, `install-profiles`), schemas |
| Versionamento | Nenhum | Changesets + CHANGELOG + versão sincronizada no plugin.json | SemVer, CHANGELOG, npm |
| Regras para agentes | README | `CLAUDE.md`/`AGENTS.md` rigorosos (README por bucket, docs por skill, sem em-dash) | `AGENTS.md`, `CLAUDE.md`, `SOUL.md`, rules por linguagem |
| Validação/CI | Nenhuma (o humanizer traz o próprio validador) | `claude plugin validate`, workflows de triage/release | Testes, lint, gitleaks, CI pesado |
| Segurança | `.gitignore` bloqueia `.env`, `*token*`, `*secret*`, binários | Padrão | `.gitleaksignore`, `--ignore-scripts` no npm install, aviso de "fontes oficiais" |

## O que cada um faz bem

### akitaonrails/my-skills: simplicidade

- **Uma fonte, vários consumidores.** Cada harness mantém seu `skills/` como diretório *real*, e cada entrada é um symlink para o repo. Editar no repo afeta todos os agentes na hora.
- **Symlink por skill, não do diretório inteiro**, porque os diretórios dos harnesses também guardam coisas que não devem ir para o repo (skills de pacotes do sistema, `.system` do Codex, skills privadas).
- **Seção "Deliberadamente NÃO neste repo"** e **inventário de componentes externos** com origem e procedimento de update. É ótimo para lembrar de onde veio cada coisa.
- **Vendoring do humanizer**: copia o upstream, tira o `.git` e roda o validador do próprio pacote.
- Ponto fraco: a instalação é um loop de `ln -s` colado no README, sem detectar conflito nem desinstalar.

### mattpocock/skills: disciplina de produto

- **Buckets** separam o que é promovido do que é experimental ou aposentado, e o link script ignora `deprecated/` e `misc/`.
- **Invocação explícita**: cada skill é *user-invoked* (`disable-model-invocation: true` + `policy.allow_implicit_invocation: false` no `agents/openai.yaml`) ou *model-invoked*, e a `description` muda de tom conforme o caso (humana ou com gatilhos para o modelo).
- **Dependência entre skills** só por "chame a Skill tool com X", nunca por link `../outra-skill/ARQ.md`.
- **Distribuição via plugin** (`.claude-plugin/marketplace.json` + `plugin.json`) e `npx skills` para os harnesses sem plugin.
- O `link-skills.sh` recusa rodar se `~/.claude/skills` for um symlink para dentro do repo (evita escrever links dentro do próprio repo). Copiei essa proteção.
- Ponto fraco para uso pessoal: muita cerimônia (docs por skill, changesets, README por bucket).

### affaan-m/ECC: cobertura máxima

- **Adapter por harness**: cada destino (`scripts/lib/install-targets/*.js`) sabe traduzir skills, rules e agents para o formato nativo (ex.: rules `.md` → `.mdc` no Cursor; agents JSON e MD no Kiro).
- **Instalação segura**: preflight, dry-run, "não empilhe métodos de instalação", doctor, uninstall, perfis (`minimal`, `core`, `full`).
- Vai além de skills: hooks, MCP, steering do Kiro, commands, agents. Este repo **não** precisa disso agora.
- Ponto fraco: é enorme. Copiar o modelo dele para um repo pessoal seria excesso.

## Onde cada harness procura skills globais

Todos seguem o formato [Agent Skills](https://agentskills.io/specification): uma pasta por skill com `SKILL.md` e frontmatter `name` + `description`.

| Harness | Diretórios globais lidos | Coberto por |
| --- | --- | --- |
| Claude Code | `~/.claude/skills` | `~/.claude/skills` |
| Codex | `~/.agents/skills` (atual), `~/.codex/skills` (legado) | `~/.agents/skills` |
| Cursor | `~/.cursor/skills`, `~/.agents/skills` + compat `~/.claude/skills`, `~/.codex/skills` | `~/.agents/skills` e `~/.claude/skills` |
| OpenCode | `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` | `~/.agents/skills` e `~/.claude/skills` |
| Gemini CLI | `~/.gemini/skills`, `~/.agents/skills` | `~/.agents/skills` |
| GitHub Copilot | `~/.copilot/skills`, `~/.claude/skills` | `~/.claude/skills` |
| Kiro (IDE e CLI) | `~/.kiro/skills` | `~/.kiro/skills` |

Por isso o instalador usa só três destinos por padrão (`~/.agents/skills`, `~/.claude/skills`, `~/.kiro/skills`). Os diretórios específicos (`cursor`, `opencode`, `codex`, `gemini`, `copilot`) ficam opcionais com `--target`, porque linkar neles também faria esses harnesses carregarem a mesma skill duas vezes. Cursor e OpenCode leem tanto `~/.agents` quanto `~/.claude`. Como os dois links apontam para a mesma pasta e têm o mesmo `name`, a skill deve aparecer uma vez só; se algum dia aparecer duplicada, a saída é tirar um dos destinos.

No Kiro CLI, o agente padrão carrega `~/.kiro/skills` sozinho. Agentes customizados precisam declarar `skill://~/.kiro/skills/*/SKILL.md` em `resources`.

Fontes: [Cursor docs](https://cursor.com/docs/skills), [OpenCode docs](https://opencode.ai/docs/skills), [Kiro docs](https://kiro.dev/docs/skills/), [Kiro CLI](https://kiro.dev/docs/cli/skills/).

## O que este repo adota de cada um

| Decisão | Origem |
| --- | --- |
| Symlink por skill para os diretórios globais; `git pull` atualiza tudo | akita |
| Skills de terceiros vendorizadas sem `.git`, com inventário | akita (aqui com `vendor.sources` + `vendor.lock` e atualização por `make update` ou PR semanal) |
| Seguir o conjunto de skills de um plugin pelo `.claude-plugin/plugin.json` | matt (o manifest dele é a lista oficial das skills promovidas) |
| `.gitignore` bloqueando credenciais e binários | akita |
| Pasta `skills/` em vez de skills na raiz (raiz fica para tooling e docs) | matt |
| Proteção contra `skills/` de harness que é symlink para o repo | matt |
| `agents/openai.yaml` opcional por skill (nome no picker do Codex, política de invocação) | matt |
| Convenção de invocação (user-invoked x model-invoked) | matt |
| Instalador com dry-run, uninstall, backup em vez de apagar, destinos por harness | ECC (versão mínima, em bash) |
| Validação do frontmatter antes de instalar | ECC/matt |

Colisão de nomes: o Matt não renomeia skills que colidem com comandos nativos (`.out-of-scope/harness-name-collisions.md`) e recomenda renomear a sua cópia quando você não usa o plugin. Este repo faz isso no `vendor.sources` (`rename:code-review=mp-code-review`), e a renomeação é reaplicada a cada atualização.

Ficou de fora, por enquanto: plugin/marketplace do Claude Code, buckets, changesets, docs por skill, hooks, rules e MCP. Dá para adicionar quando o repo crescer ou quando quiser distribuir para outras pessoas.
