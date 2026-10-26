#!/usr/bin/env bash
# Links every skill in skills/ into the global skill directories of each agent
# harness. Each entry is a symlink back into this repo, so editing a skill here
# (or a `git pull`) reaches every agent at once.
#
#   scripts/install.sh                 link into the default targets
#   scripts/install.sh --dry-run       show what would change
#   scripts/install.sh --uninstall     remove only the links that point here
#   scripts/install.sh --target cursor --target opencode   add optional targets
#   scripts/install.sh --list          print skills and targets, change nothing
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO/skills"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/my-skills"
SKILL_LOCK="$HOME/.agents/.skill-lock.json"

# label|directory|policy
#   always    create the directory when missing
#   ifparent  link only when the harness is installed (its parent dir exists)
DEFAULT_TARGETS=(
  "agents|$HOME/.agents/skills|always"   # Codex, Cursor, OpenCode, Gemini CLI, Amp...
  "claude|$HOME/.claude/skills|always"   # Claude Code (also read by Cursor, OpenCode, Copilot)
  "kiro|$HOME/.kiro/skills|ifparent"     # Kiro IDE and kiro-cli
)
# Opt-in only: these harnesses already read ~/.agents/skills or ~/.claude/skills,
# so linking here as well would make them load the same skill twice.
OPTIONAL_TARGETS=(
  "cursor|$HOME/.cursor/skills|ifparent"
  "opencode|$HOME/.config/opencode/skills|ifparent"
  "codex|$HOME/.codex/skills|ifparent"
  "gemini|$HOME/.gemini/skills|ifparent"
  "copilot|$HOME/.copilot/skills|ifparent"
)

mode=install
dry_run=0
extra=()

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) dry_run=1 ;;
    --uninstall) mode=uninstall ;;
    --list) mode=list ;;
    --target) shift; extra+=("${1:?--target needs a name}") ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

targets=("${DEFAULT_TARGETS[@]}")
for name in "${extra[@]+"${extra[@]}"}"; do
  found=0
  for spec in "${OPTIONAL_TARGETS[@]}" "${DEFAULT_TARGETS[@]}"; do
    if [ "${spec%%|*}" = "$name" ]; then
      targets+=("$spec"); found=1; break
    fi
  done
  [ $found = 1 ] || { echo "unknown target: $name" >&2; exit 2; }
done

run() {
  if [ $dry_run = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi
}

# A skill is any direct child of skills/ holding a SKILL.md. Names starting
# with "_" are drafts and stay out of the agents.
names=()
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -e "$skill_md" ] || continue
  name="$(basename "$(dirname "$skill_md")")"
  case "$name" in _*) continue ;; esac
  names+=("$name")
done

points_into_repo() {
  local link="$1" dest
  dest="$(readlink "$link")"
  case "$dest" in "$SKILLS_DIR"/*) return 0 ;; esac
  return 1
}

if [ $mode = list ]; then
  echo "skills (${#names[@]}):"
  printf '  %s\n' "${names[@]+"${names[@]}"}"
  echo "targets:"
  for spec in "${targets[@]}"; do
    IFS='|' read -r label dir policy <<<"$spec"
    echo "  $label -> $dir ($policy)"
  done
  exit 0
fi

backup_root="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
lock_warned=()

for spec in "${targets[@]}"; do
  IFS='|' read -r label dir policy <<<"$spec"

  if [ "$policy" = ifparent ] && [ ! -d "$(dirname "$dir")" ]; then
    echo "skip $label: $(dirname "$dir") not found (harness not installed)"
    continue
  fi

  # A whole-directory symlink into this repo would make us write links back
  # into skills/ itself. Refuse instead of polluting the working copy.
  if [ -L "$dir" ]; then
    case "$(readlink -f "$dir")" in
      "$REPO"|"$REPO"/*)
        echo "error: $dir is a symlink into this repo. Remove it and re-run." >&2
        exit 1 ;;
    esac
  fi

  echo "== $label ($dir)"

  if [ $mode = uninstall ]; then
    [ -d "$dir" ] || continue
    for entry in "$dir"/* "$dir"/.[!.]*; do
      [ -L "$entry" ] && points_into_repo "$entry" || continue
      run rm "$entry"
      echo "  removed $(basename "$entry")"
    done
    continue
  fi

  [ -d "$dir" ] || run mkdir -p "$dir"

  for name in "${names[@]+"${names[@]}"}"; do
    src="$SKILLS_DIR/$name"
    dest="$dir/$name"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      echo "  ok      $name"
      continue
    fi

    if [ -L "$dest" ]; then
      echo "  relink  $name (was -> $(readlink "$dest"))"
      run rm "$dest"
    elif [ -e "$dest" ]; then
      # A real copy, usually from `npx skills add` or a manual install. Move it
      # aside rather than deleting it, so nothing is lost.
      echo "  backup  $name -> $backup_root/$label/$name"
      run mkdir -p "$backup_root/$label"
      run mv "$dest" "$backup_root/$label/$name"
    else
      echo "  link    $name"
    fi
    run ln -s "$src" "$dest"

    if [ -f "$SKILL_LOCK" ] && grep -q "\"$name\": {" "$SKILL_LOCK"; then
      case " ${lock_warned[*]+"${lock_warned[*]}"} " in *" $name "*) ;; *) lock_warned+=("$name") ;; esac
    fi
  done

  # Drop links to skills that were renamed or removed from this repo.
  for entry in "$dir"/*; do
    if [ -L "$entry" ] && points_into_repo "$entry" && [ ! -e "$entry" ]; then
      echo "  prune   $(basename "$entry") (skill no longer in repo)"
      run rm "$entry"
    fi
  done
done

if [ ${#lock_warned[@]} -gt 0 ]; then
  cat >&2 <<EOF

warning: ${lock_warned[*]} still listed in $SKILL_LOCK (installed by 'npx skills').
'npx skills update' could rewrite those folders through the new symlinks, that
is, inside this repo. Drop them from the skills CLI with:
  npx skills remove -g ${lock_warned[*]}
then re-run scripts/install.sh to restore the links.
EOF
fi

if [ $dry_run = 0 ] && [ $mode = install ]; then
  echo
  echo "Done. Restart running agents so they reload SKILL.md files."
fi
