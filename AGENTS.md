# Guia para agentes neste repo

Repo de skills pessoais, instaladas globalmente por symlink. Leia o `README.md` para o fluxo de instalação.

## Estrutura

- `skills/<nome>/SKILL.md`: uma pasta por skill, sem subcategorias. Arquivos de apoio (referências, scripts) ficam dentro da pasta da skill.
- `skills/_<nome>/`: rascunhos. O instalador ignora.
- `scripts/install.sh`: cria e remove os symlinks em `~/.agents/skills`, `~/.claude/skills`, `~/.kiro/skills`.
- `scripts/validate.sh`: valida o frontmatter. Rode depois de criar ou editar qualquer `SKILL.md`.
- `vendor.sources` (à mão) + `scripts/vendor.mjs` + `vendor.lock` (gerado): skills de terceiros copiadas do upstream. `make update`, `make outdated`, `make vendored`.
- `.github/workflows/update-vendored.yml`: PR semanal com as atualizações do upstream.
- `docs/referencias.md`: comparação com os repos de referência e decisões de design.

## Regras para escrever skills

- O frontmatter precisa de `name` (igual ao nome da pasta; minúsculas, dígitos e hífen; até 64 caracteres) e `description` (até 1024 caracteres). Campos desconhecidos são ignorados pelos harnesses, mas mantenha o mínimo.
- Mantenha a skill portável: nada de instruções que só funcionem num harness. Cite Claude Code, Codex, Cursor etc. como exemplos, nunca como requisito.
- `description` define quando o modelo dispara a skill:
  - **Model-invoked** (padrão): descreva o que faz e quando usar, com gatilhos ("Use quando o usuário...").
  - **User-invoked** (só o humano chama, por `/nome`): adicione `disable-model-invocation: true` no frontmatter e crie `agents/openai.yaml` com `policy.allow_implicit_invocation: false` (Codex). A `description` vira um resumo de uma linha para humanos.
- Opcional: `agents/openai.yaml` com `interface.display_name` e `interface.short_description` para o seletor do Codex.
- Para uma skill usar outra, escreva "chame a Skill tool com `<nome>`" em vez de linkar arquivos de outra pasta (`../outra/ARQ.md`).
- Cada palavra do `SKILL.md` é lida a cada uso. Coloque detalhes longos em arquivos de referência dentro da pasta e diga quando lê-los.
- Nunca coloque credenciais, caminhos privados ou dados de clientes numa skill.

## Skills vendored

- As pastas listadas em `vendor.lock` são cópias do upstream. Não edite essas pastas nem o `vendor.lock`: o `scripts/vendor.mjs` sobrescreve tudo na próxima atualização. Para mudar o comportamento, crie outra skill com outro nome. Para mudar o que é puxado, edite `vendor.sources`.
- Renomeações (`rename:a=b`) também reescrevem as referências a `a` nos arquivos de texto da mesma fonte. Depois de adicionar uma, confira com `grep -rn` se nenhuma referência ficou para trás.
- Depois de `make update`, revise o `git diff skills/` antes de commitar. Conteúdo de terceiros pode trazer instruções inesperadas.
- As skills do Matt seguem as convenções dele (invocação, dependência por "call the Skill tool with X"). Veja `docs/referencias.md`.

## Ao adicionar, renomear ou remover uma skill

1. Rode `scripts/validate.sh`.
2. Atualize a tabela "Skills" do `README.md`.
3. Rode `scripts/install.sh` (ele remove os links de skills renomeadas ou apagadas).
