# Changelog

All notable changes to **htpx** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

htpx is the source of truth for the red↔blue paired corpus; it is vendored into
`dotfiles-Kali` at `offensive/companion/` via `git subtree`. Cutting a release
here (a new top version below) tags the repo and fans the change OUT to
`dotfiles-Kali` as a `companion.lock`-bump PR — see
`.github/workflows/auto-tag.yml` and `.github/workflows/sync-fanout.yml`.

## How releasing works

Add user-visible changes under `[Unreleased]`. To cut a release, move the
`[Unreleased]` entries under a new `## [vX.Y.Z] - YYYY-MM-DD` heading and push to
`main`: `auto-tag.yml` sees the new top version, tags `vX.Y.Z`, and publishes a
GitHub Release; `sync-fanout.yml` then opens the Kali sync PR.

## [Unreleased]

### Fixed

- `sync-fanout.yml` Resolve step: the htpx clone / `ls-remote` reads are now
  authenticated with the built-in `GITHUB_TOKEN` (`contents: read`). They were
  unauthenticated, so on a private htpx the fan-out died at the first clone with
  `could not read Username for 'https://github.com'`. Auth is injected via
  `GIT_CONFIG_COUNT`/`KEY`/`VALUE` env (an `url.insteadOf` rewrite scoped to that
  step), so the token is never written to `~/.gitconfig` and can't shadow the next
  step's `actions/checkout`; `FLEET_SYNC_TOKEN` stays reserved for the cross-repo
  writes to dotfiles-Kali.
- Release + fan-out workflows hardened (PR review): `auto-tag.sh` now fails loud
  when `--release` is requested but `gh` is absent; `auto-tag.yml` cuts
  tags/releases only from the default branch; `sync-fanout.yml` resolves and
  verifies the tag exists before checkout (a bad dispatch input is a clean no-op),
  aborts the sync if `gen-views.sh` fails (no PR), and fails on ANY `core.lock`
  diff versus the base branch — not just the `core_sha` field.

## [v1.2.0] - 2026-06-30

### Added

- Release automation: `auto-tag.yml` tags + releases on a new top CHANGELOG
  version, and `sync-fanout.yml` fans the released ref out to `dotfiles-Kali` as a
  `companion.lock`-bump PR (this CHANGELOG seeds that pipeline at the current tag).

## [v1.1.0]

### Added

- Polished README landing-page hero.

## [v1.0.0]

### Added

- Initial standalone extraction of the structured red↔blue paired companion from
  `dotfiles-Kali`: `htpx` fzf browser, `gen-views.sh` source-of-truth bridge with
  `--check` drift gate, and the ATT&CK-tagged `entries/red|blue/*.md` corpus.
