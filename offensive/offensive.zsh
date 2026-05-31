# dotfiles-Kali/offensive/offensive.zsh  ->  ~/.config/zsh/offensive.zsh
# The OFFENSIVE role layer. Loaded AFTER the Kali os layer, BEFORE local.
# Kali-only — never promoted to Core, never present on a dev box.
#
# DESIGN RULE: this file is WORKFLOW + WORKSPACE plumbing only. Real engagement
# data lives under $ENGAGEMENTS_DIR (default ~/engagements), which is OUTSIDE
# this repo and blocked by .gitignore. Nothing here writes into the repo, and
# nothing here is an attack — it just organizes where your tools' output goes.
[[ $- == *i* ]] || return 0

: "${ENGAGEMENTS_DIR:=$HOME/engagements}"
export ENGAGEMENTS_DIR
KALI_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/kali"
export KALI_TEMPLATES="${XDG_CONFIG_HOME:-$HOME/.config}/kali/templates"
_ENG_FILE="$KALI_STATE/current"
mkdir -p "$KALI_STATE" "$ENGAGEMENTS_DIR" 2>/dev/null

# ── current-engagement tracking ───────────────────────────────────────────────
eng() {                       # print the active engagement
  [[ -f "$_ENG_FILE" ]] && cat "$_ENG_FILE" || echo "no active engagement (seteng <name>)"
}
engs() { command ls -1 "$ENGAGEMENTS_DIR" 2>/dev/null; }   # list all engagements
seteng() {                    # mark an existing engagement active
  [[ -z "$1" ]] && { echo "usage: seteng <name>"; return 1; }
  local d="$ENGAGEMENTS_DIR/$1"
  [[ -d "$d" ]] || { echo "no such engagement: $d  (create: newengagement $1)"; return 1; }
  echo "$d" > "$_ENG_FILE"; echo "active -> $d"
}
cde() {                       # cd into the active engagement (optional subdir)
  [[ -f "$_ENG_FILE" ]] || { echo "no active engagement"; return 1; }
  cd "$(cat "$_ENG_FILE")${1:+/$1}"
}

# ── newengagement — scaffold the standard methodology tree ────────────────────
# Builds a clean per-engagement workspace and makes it active. Every tree gets
# its own '*' .gitignore so engagement data can NEVER be committed anywhere.
newengagement() {
  [[ -z "$1" ]] && { echo "usage: newengagement <client-or-codename>"; return 1; }
  local name="$1" root="$ENGAGEMENTS_DIR/$1"
  [[ -e "$root" ]] && { echo "already exists: $root"; return 1; }
  mkdir -p "$root"/{recon/{nmap,web,dns,smb},loot,creds,evidence,exploits,notes,report}
  printf '*\n!.gitignore\n' > "$root/.gitignore"
  if [[ -d "$KALI_TEMPLATES" ]]; then
    sed "s/__NAME__/$name/g; s/__DATE__/$(date +%F)/g" "$KALI_TEMPLATES/scope.md"      > "$root/scope.md"  2>/dev/null
    sed "s/__NAME__/$name/g; s/__DATE__/$(date +%F)/g" "$KALI_TEMPLATES/engagement.md" > "$root/README.md" 2>/dev/null
    cp "$KALI_TEMPLATES/finding.md" "$root/report/finding-template.md" 2>/dev/null
  fi
  : > "$root/notes/notes.md"
  echo "$root" > "$_ENG_FILE"
  echo "scaffolded + active -> $root"
  command -v eza >/dev/null && eza --tree --level=2 "$root" || find "$root" -maxdepth 2
}

# ── note — timestamped capture into the active engagement notebook ────────────
note() {
  [[ -f "$_ENG_FILE" ]] || { echo "no active engagement"; return 1; }
  local nb; nb="$(cat "$_ENG_FILE")/notes/notes.md"
  if [[ -z "$*" ]]; then ${EDITOR:-nvim} "$nb"; return; fi
  printf '\n## %s\n%s\n' "$(date '+%F %T')" "$*" >> "$nb"
  echo "noted -> $nb"
}

# ── lhost — interface IPs you'd drop into a listener / callback ────────────────
# Just reads `ip addr`. tun*/vpn sort to the top since that's usually the one
# you want for a lab/VPN engagement.
lhost() {
  ip -4 -o addr show 2>/dev/null | awk '$2!="lo"{print $2"\t"$4}' | sort -r
}

# ── www — quick file-transfer HTTP server from $PWD (prints your IPs first) ────
www() {
  local port="${1:-8000}"
  echo "serving $PWD on :$port"; lhost
  python3 -m http.server "$port"
}

# keep the Kali toolset current
alias toolup='sudo apt-get update && sudo apt-get full-upgrade -y'
