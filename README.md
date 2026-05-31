# dotfiles-Kali

The Kali node of the dotfiles system. Unlike every other OS repo, this one
stacks **three** layers instead of two:

| Layer | Source | What it carries |
|-------|--------|-----------------|
| **Core** | vendored from `dotfiles-core` under `core/` | zsh modules, tmux, nvim, git, starship, mise, clip |
| **OS-native** | `os/kali.*` | apt, clipboard delegation, paths, tmux/git tweaks (Kali is Debian-based) |
| **Offensive (role)** | `offensive/` | engagement scaffolding + workspace workflow — **unique to this repo** |

Built for **Kali on WSL2**.

## The one rule that matters

**This is a public showcase repo. Engagement and client data never live in it.**

All engagement data lives under `~/engagements/` (outside the repo). The repo
ships only tooling, config, and empty workspace scaffolding. The paranoid
`.gitignore` is defense-in-depth, and every engagement folder `newengagement`
creates gets its own `*` gitignore. Keep it that way.

## Loader integration

The offensive layer adds one stage to the zsh loader, slotted in just before
local overrides:

```
tools → aliases → functions → fzf → bindings → plugins → op → os → offensive → local
```

`offensive/offensive.zsh` → `~/.config/zsh/offensive.zsh`. It holds workflow
helpers only (`newengagement`, `eng`/`seteng`/`cde`, `note`, `lhost`, `www`) —
no exploit code, no attack automation; just where your output goes.

## WSL2: read before you run a listener

WSL2 is NAT'd by default, so a reverse shell / handler / responder / file
server started in Kali is **not reachable from your LAN** — traffic hits the
Windows host, not Kali. Fix it with **mirrored networking** (Windows 11 22H2+):
copy `wsl/windows.wslconfig.example` to `%UserProfile%\.wslconfig`, then
`wsl.exe --shutdown` and reopen. The distro-side `wsl/wsl.conf` (systemd +
default user + interop) is installed automatically by `bootstrap.sh`.

GUI tools (Burp, BloodHound UI) work under WSLg but are smoother on the Windows
host — the default tool list is headless-first.

## Install (fresh repo lifecycle)

```sh
# 1. land these files in ~/dotfiles-Kali, then:
cd ~/dotfiles-Kali
git init -b main
git config user.name  "Your Name"
git config user.email "you@example.com"
git add . && git commit -m "Kali OS + offensive layers"

# 2. vendor Core (one time)
git subtree add --prefix=core <dotfiles-core remote> main --squash

# 3. provision + wire
./bootstrap.sh                 # full (add --no-offensive to skip heavy tools)

# 4. apply WSL config
wsl.exe --shutdown             # from a Windows terminal, then reopen Kali
# (also drop windows.wslconfig.example at %UserProfile%\.wslconfig for mirrored net)
```

Keeping Core current later is the same as every repo: from `dotfiles-core`,
`./bin/sync-core.sh dotfiles-Kali`, then `./bootstrap.sh --links-only` here.

## bootstrap flags

- `./bootstrap.sh` — apt base + offensive tools + symlinks
- `./bootstrap.sh --no-offensive` — base + symlinks, skip the heavy tool install
- `./bootstrap.sh --links-only` — just (re)create symlinks

## Engagement workflow

```sh
newengagement acme-external     # scaffold ~/engagements/acme-external + make active
eng                             # show the active engagement
cde recon/nmap                  # jump into a subdir of it
note "got creds for svc_sql"    # timestamped line into notes/notes.md
lhost                           # interface IPs for a listener / callback
```
